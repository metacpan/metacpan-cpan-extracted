/* punk_ws.h - the RFC 6455 frame codec.
 *
 * Transcribed from the C that Hypersonic's
 * Hypersonic::Protocol::WebSocket::Frame generates (same author, relicensed
 * Artistic 2.0 with the rest of Punk), with the strictness that a
 * server-side codec facing the public internet needs added from the start:
 *
 *   1. text payloads and close reasons are UTF-8 validated, incrementally
 *      so a multibyte character split across fragments still validates
 *      (violations close 1007);
 *   2. client frames must be masked (1002);
 *   3. control frames must be FIN and at most 125 bytes (1002);
 *   4. fragment reassembly is bounded by max_message_size, rejected from
 *      the frame header before a single byte is buffered (1009);
 *   5. writes are queued and drained, never assumed complete - a short
 *      write arms a write watcher rather than corrupting the stream.
 *
 * This header is the frame layer only: it owns no fds and no event loop.
 * punk_wsconn.h drives it.
 */

#ifndef PUNK_WS_H
#define PUNK_WS_H

/* ---- opcodes and close codes --------------------------------------------- */

#define PW_OP_CONT   0x0
#define PW_OP_TEXT   0x1
#define PW_OP_BINARY 0x2
#define PW_OP_CLOSE  0x8
#define PW_OP_PING   0x9
#define PW_OP_PONG   0xA

#define PW_CLOSE_NORMAL           1000
#define PW_CLOSE_GOING_AWAY       1001
#define PW_CLOSE_PROTOCOL_ERROR   1002
#define PW_CLOSE_UNSUPPORTED_DATA 1003
#define PW_CLOSE_NO_STATUS        1005
#define PW_CLOSE_ABNORMAL         1006
#define PW_CLOSE_INVALID_PAYLOAD  1007
#define PW_CLOSE_POLICY_VIOLATION 1008
#define PW_CLOSE_MESSAGE_TOO_BIG  1009
#define PW_CLOSE_MANDATORY_EXT    1010
#define PW_CLOSE_INTERNAL_ERROR   1011

#define PW_MAX_CONTROL 125     /* RFC 6455 5.5: control payload limit      */
#define PW_MAX_REASON  123     /* a close reason after the 2-byte code     */

/* pw_decode_frame results: > 0 is the number of bytes consumed, 0 means
 * "need more data", and these negatives are protocol failures carrying the
 * close code they must be answered with. */
#define PW_NEED_MORE  0
#define PW_E_PROTO   -1        /* -> 1002 */
#define PW_E_TOO_BIG -2        /* -> 1009 */
#define PW_E_UTF8    -3        /* -> 1007 */

typedef struct {
    unsigned char fin, rsv, opcode, masked;
    unsigned char mask_key[4];
    uint64_t      payload_len;
    const char   *payload;     /* borrowed, into the caller's buffer */
    size_t        header_size;
} pw_frame;

static int pw_is_control(unsigned char op) { return (op & 0x08) != 0; }

/* ---- incremental UTF-8 validation ----------------------------------------
 * state 0 means "at a character boundary" - the only state a message may
 * end in. Anything else is a partially seen character, carried across
 * fragments. Rejects overlongs, surrogates and > U+10FFFF. */

typedef struct { int need; uint32_t cp; int min; } pw_utf8;

static void pw_utf8_reset(pw_utf8 *u) { u->need = 0; u->cp = 0; u->min = 0; }

static int pw_utf8_ok(pw_utf8 *u) { return u->need == 0; }

/* 1 = still valid, 0 = malformed */
static int pw_utf8_step(pw_utf8 *u, const char *p, size_t n) {
    size_t i;
    for (i = 0; i < n; i++) {
        unsigned char c = (unsigned char)p[i];
        if (u->need == 0) {
            if      (c < 0x80) continue;
            else if ((c & 0xE0) == 0xC0) { u->need = 1; u->cp = c & 0x1F; u->min = 0x80; }
            else if ((c & 0xF0) == 0xE0) { u->need = 2; u->cp = c & 0x0F; u->min = 0x800; }
            else if ((c & 0xF8) == 0xF0) { u->need = 3; u->cp = c & 0x07; u->min = 0x10000; }
            else return 0;                        /* continuation or 0xF8+ */
        }
        else {
            if ((c & 0xC0) != 0x80) return 0;     /* expected a continuation */
            u->cp = (u->cp << 6) | (c & 0x3F);
            if (--u->need == 0) {
                if (u->cp < (uint32_t)u->min)                  return 0; /* overlong  */
                if (u->cp >= 0xD800 && u->cp <= 0xDFFF)        return 0; /* surrogate */
                if (u->cp > 0x10FFFF)                          return 0;
            }
        }
    }
    return 1;
}

/* One-shot validation (close reasons, single-frame text). */
static int pw_utf8_valid(const char *p, size_t n) {
    pw_utf8 u;
    pw_utf8_reset(&u);
    return pw_utf8_step(&u, p, n) && pw_utf8_ok(&u);
}

/* ---- decode --------------------------------------------------------------
 * `server` means "these frames come from a client", which is what makes
 * masking mandatory. max_msg bounds a single frame's payload, checked from
 * the header so an oversized frame is refused before it is buffered. */
static int pw_decode_frame(const char *buf, size_t len, pw_frame *f,
                           size_t max_msg, int server) {
    unsigned char b0, b1;
    size_t need = 2, i;
    uint64_t plen;

    if (len < 2) return PW_NEED_MORE;
    b0 = (unsigned char)buf[0];
    b1 = (unsigned char)buf[1];

    f->fin    = (b0 & 0x80) ? 1 : 0;
    f->rsv    = (b0 >> 4) & 0x07;
    f->opcode = b0 & 0x0F;
    f->masked = (b1 & 0x80) ? 1 : 0;
    plen      = b1 & 0x7F;

    if (f->rsv) return PW_E_PROTO;            /* no extensions negotiated */
    if (server && !f->masked) return PW_E_PROTO;   /* fix 2 */

    /* fix 3: control frames must be FIN and short, and must not fragment */
    if (pw_is_control(f->opcode)) {
        if (!f->fin || plen > PW_MAX_CONTROL) return PW_E_PROTO;
        if (f->opcode != PW_OP_CLOSE && f->opcode != PW_OP_PING
            && f->opcode != PW_OP_PONG)
            return PW_E_PROTO;                 /* reserved control opcode */
    }
    else if (f->opcode != PW_OP_CONT && f->opcode != PW_OP_TEXT
             && f->opcode != PW_OP_BINARY) {
        return PW_E_PROTO;                     /* reserved data opcode */
    }

    if (plen == 126) {
        if (len < 4) return PW_NEED_MORE;
        plen = ((uint64_t)(unsigned char)buf[2] << 8)
             |  (uint64_t)(unsigned char)buf[3];
        need = 4;
    }
    else if (plen == 127) {
        if (len < 10) return PW_NEED_MORE;
        plen = 0;
        for (i = 0; i < 8; i++)
            plen = (plen << 8) | (uint64_t)(unsigned char)buf[2 + i];
        if (plen & ((uint64_t)1 << 63)) return PW_E_PROTO;   /* MSB set */
        need = 10;
    }

    /* fix 4: refuse from the header, before buffering anything */
    if (max_msg && plen > (uint64_t)max_msg) return PW_E_TOO_BIG;

    if (f->masked) {
        if (len < need + 4) return PW_NEED_MORE;
        for (i = 0; i < 4; i++) f->mask_key[i] = (unsigned char)buf[need + i];
        need += 4;
    }
    if (len < need + plen) return PW_NEED_MORE;

    f->payload_len = plen;
    f->header_size = need;
    f->payload     = buf + need;
    return (int)(need + plen);
}

/* Unmask in place. The caller owns the bytes (they live in its read
 * buffer), so this is the one mutation the decoder makes. */
static void pw_unmask(pw_frame *f, char *payload) {
    uint64_t i;
    if (!f->masked) return;
    for (i = 0; i < f->payload_len; i++)
        payload[i] = (char)((unsigned char)payload[i] ^ f->mask_key[i & 3]);
}

/* ---- encode --------------------------------------------------------------
 * Server frames are never masked. Returns the header size (2..10). */
static size_t pw_encode_header(char *hdr, unsigned char opcode, int fin,
                               size_t len) {
    size_t n = 0;
    hdr[n++] = (char)((fin ? 0x80 : 0x00) | (opcode & 0x0F));
    if (len < 126) {
        hdr[n++] = (char)len;
    }
    else if (len <= 0xFFFF) {
        hdr[n++] = 126;
        hdr[n++] = (char)((len >> 8) & 0xFF);
        hdr[n++] = (char)(len & 0xFF);
    }
    else {
        int i;
        hdr[n++] = 127;
        for (i = 7; i >= 0; i--)
            hdr[n++] = (char)(((uint64_t)len >> (i * 8)) & 0xFF);
    }
    return n;
}

/* The close payload: a 2-byte big-endian code, then the (clamped) reason.
 * Returns the payload length. `out` needs 2 + PW_MAX_REASON bytes. */
static size_t pw_close_payload(char *out, uint16_t code,
                               const char *reason, size_t rlen) {
    if (rlen > PW_MAX_REASON) rlen = PW_MAX_REASON;
    out[0] = (char)((code >> 8) & 0xFF);
    out[1] = (char)(code & 0xFF);
    if (rlen && reason) memcpy(out + 2, reason, rlen);
    return 2 + rlen;
}

/* A close code the peer is allowed to send (RFC 6455 7.4). */
static int pw_close_code_ok(uint16_t code) {
    if (code >= 3000 && code <= 4999) return 1;      /* registered/private */
    switch (code) {
        case PW_CLOSE_NORMAL: case PW_CLOSE_GOING_AWAY:
        case PW_CLOSE_PROTOCOL_ERROR: case PW_CLOSE_UNSUPPORTED_DATA:
        case PW_CLOSE_INVALID_PAYLOAD: case PW_CLOSE_POLICY_VIOLATION:
        case PW_CLOSE_MESSAGE_TOO_BIG: case PW_CLOSE_MANDATORY_EXT:
        case PW_CLOSE_INTERNAL_ERROR:
            return 1;
        default:
            return 0;   /* includes 1005/1006, which are never sent */
    }
}

#endif /* PUNK_WS_H */
