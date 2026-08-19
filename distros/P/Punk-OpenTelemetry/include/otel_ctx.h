/* otel_ctx.h - an extracted trace context, and the rules every parser here
 * shares.
 *
 * EVERY BYTE THESE PARSERS SEE CAME FROM THE CLIENT. A traceparent is a
 * request header, which means it is attacker-controlled input arriving on the
 * hot path of every request. So:
 *
 *   - Nothing here allocates based on a length the client supplied. Every
 *     parse is fixed-width or bounded by a constant.
 *   - Nothing here croaks. A malformed header is ABSENT, not an error: a
 *     500 because somebody sent a bad trace header would be a denial of
 *     service with extra steps.
 *   - Anything reflected back out is validated on the way OUT as well as in.
 *     That is the lesson of CVE-2026-75628 and the Punk markdown 301: bytes
 *     do not become safe by having been seen once already.
 *
 * INVALID IS ABSENT. An unparseable, wrong-length or all-zero id yields no
 * context at all rather than a partial one. A span that claims a parent which
 * cannot exist hangs off nothing for ever, in every UI; a root span is
 * correct and legible.
 */

#ifndef OTEL_CTX_H
#define OTEL_CTX_H

#include "otel_id.h"

typedef struct {
    unsigned char trace_id[16];
    unsigned char span_id[8];
    int  flags;        /* bit 0 = sampled; other bits preserved as received */
    int  valid;        /* 0 = no usable context was found */
    int  debug;        /* B3 / Jaeger debug, which IMPLIES sampled */
} otel_ctx;

static void otel_ctx_clear(otel_ctx *c) {
    Zero(c, 1, otel_ctx);
}

/* One hex nibble, or -1. */
static int otel_nib(char ch) {
    if (ch >= '0' && ch <= '9') return ch - '0';
    if (ch >= 'a' && ch <= 'f') return ch - 'a' + 10;
    if (ch >= 'A' && ch <= 'F') return ch - 'A' + 10;
    return -1;
}

/* Parse exactly `want` bytes of hex. No length is taken from the input. */
static int otel_hexn(const char *s, STRLEN len, STRLEN want,
                     unsigned char *out) {
    STRLEN i;
    if (len != want * 2) return 0;
    for (i = 0; i < want; i++) {
        int hi = otel_nib(s[i * 2]), lo = otel_nib(s[i * 2 + 1]);
        if (hi < 0 || lo < 0) return 0;
        out[i] = (unsigned char)((hi << 4) | lo);
    }
    return 1;
}

/* A trace id that may arrive 64-bit (16 hex) or 128-bit (32 hex), as B3 and
 * Jaeger both allow.
 *
 * A short id is LEFT-padded with zero bytes. The side matters and is easy to
 * get backwards: right-padding produces a well-formed id of an entirely
 * different value, which is worse than a rejection because it looks fine and
 * joins to nothing. */
static int otel_trace_id_flex(const char *s, STRLEN len, unsigned char *out) {
    if (len == 32) return otel_hexn(s, len, 16, out)
                       && !otel_all_zero(out, 16);
    if (len == 16) {
        Zero(out, 8, unsigned char);            /* the HIGH half is the pad */
        return otel_hexn(s, len, 8, out + 8)
            && !otel_all_zero(out, 16);
    }
    return 0;
}

/* Likewise a span id, which is always 8 bytes but is sometimes written short
 * by a careless sender. */
static int otel_span_id_flex(const char *s, STRLEN len, unsigned char *out) {
    if (len == 16) return otel_hexn(s, len, 8, out) && !otel_all_zero(out, 8);
    if (len > 0 && len < 16 && (len % 2) == 0) {
        STRLEN pad = 8 - len / 2;
        Zero(out, pad, unsigned char);
        return otel_hexn(s, len, len / 2, out + pad)
            && !otel_all_zero(out, 8);
    }
    return 0;
}

#endif /* OTEL_CTX_H */
