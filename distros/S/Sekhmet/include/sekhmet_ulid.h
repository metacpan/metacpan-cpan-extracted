#ifndef SEKHMET_ULID_H
#define SEKHMET_ULID_H

/*
 * sekhmet_ulid.h - ULID generation, encoding, decoding, conversion
 *
 * Binary ULID layout (16 bytes, big-endian):
 *   Bytes 0-5:   48-bit Unix epoch milliseconds
 *   Bytes 6-15:  80-bit cryptographic randomness
 *
 * Crockford base32 encoding (26 chars):
 *   Chars 0-9:   timestamp  (48 bits, first char uses only 3 bits)
 *   Chars 10-25: randomness (80 bits)
 *
 * Depends on horus_core.h for:
 *   horus_unix_epoch_ms(), horus_random_bytes(),
 *   horus_crockford_encode(), horus_crockford_decode()
 */

#include <string.h>
#include <stdint.h>

/* ── Monotonic state ────────────────────────────────────────────── */

typedef struct {
    uint64_t      last_ms;
    unsigned char last_rand[10]; /* 80 bits of randomness */
} sekhmet_monotonic_state_t;

/* ── Timestamp helpers ──────────────────────────────────────────── */

static inline void sekhmet_pack_timestamp(unsigned char *out, uint64_t ms) {
    out[0] = (unsigned char)((ms >> 40) & 0xFF);
    out[1] = (unsigned char)((ms >> 32) & 0xFF);
    out[2] = (unsigned char)((ms >> 24) & 0xFF);
    out[3] = (unsigned char)((ms >> 16) & 0xFF);
    out[4] = (unsigned char)((ms >> 8)  & 0xFF);
    out[5] = (unsigned char)(ms & 0xFF);
}

static inline uint64_t sekhmet_unpack_timestamp(const unsigned char *ulid) {
    return ((uint64_t)ulid[0] << 40)
         | ((uint64_t)ulid[1] << 32)
         | ((uint64_t)ulid[2] << 24)
         | ((uint64_t)ulid[3] << 16)
         | ((uint64_t)ulid[4] << 8)
         | (uint64_t)ulid[5];
}

/* ── Generate ULID (random mode) ───────────────────────────────── */

static inline void sekhmet_ulid_generate(unsigned char *out) {
    uint64_t ms = horus_unix_epoch_ms();
    sekhmet_pack_timestamp(out, ms);
    horus_random_bytes(out + 6, 10);
}

/* ── Generate ULID (monotonic mode) ────────────────────────────── */

static inline void sekhmet_ulid_monotonic(unsigned char *out,
                                           sekhmet_monotonic_state_t *state) {
    uint64_t ms = horus_unix_epoch_ms();
    sekhmet_pack_timestamp(out, ms);

    if (ms == state->last_ms) {
        /* Same millisecond: increment 80-bit random (big-endian) */
        int i, carry = 1;
        for (i = 9; i >= 0 && carry; i--) {
            int val = (int)state->last_rand[i] + carry;
            state->last_rand[i] = (unsigned char)(val & 0xFF);
            carry = val >> 8;
        }
        if (carry) {
            /* Overflow of 2^80 — reseed (practically impossible) */
            horus_random_bytes(state->last_rand, 10);
        }
        memcpy(out + 6, state->last_rand, 10);
    } else {
        /* New millisecond: fresh random */
        horus_random_bytes(out + 6, 10);
        state->last_ms = ms;
        memcpy(state->last_rand, out + 6, 10);
    }
}

/* ── Encode binary ULID to 26-char Crockford string ────────────── */

static inline void sekhmet_ulid_encode(char *dst, const unsigned char *ulid) {
    horus_crockford_encode(dst, ulid);
}

/* ── Decode 26-char Crockford string to binary ULID ────────────── */

static inline int sekhmet_ulid_decode(unsigned char *dst,
                                       const char *src, int len) {
    if (len != 26) return 0;
    return horus_crockford_decode(dst, src, len) == 16;
}

/* ── Extract timestamp as epoch seconds (double) ───────────────── */

static inline double sekhmet_ulid_time(const unsigned char *ulid) {
    uint64_t ms = sekhmet_unpack_timestamp(ulid);
    return (double)ms / 1000.0;
}

/* ── Extract timestamp as epoch milliseconds ───────────────────── */

static inline uint64_t sekhmet_ulid_time_ms(const unsigned char *ulid) {
    return sekhmet_unpack_timestamp(ulid);
}

/* ── ULID → UUID string conversion ─────────────────────────────── *
 *
 * ULID:   [48-bit ts][80-bit random]
 * UUIDv7: [48-bit ts][4-bit ver=7][12-bit rand_a][2-bit var=10][62-bit rand_b]
 *
 * We stamp version=7 and variant=RFC4122 into the binary, then format
 * as a standard UUID hyphenated string.
 */

static inline void sekhmet_format_uuid(char *dst, const unsigned char *uuid) {
    static const char hex[] = "0123456789abcdef";
    int i, j = 0;
    for (i = 0; i < 16; i++) {
        if (i == 4 || i == 6 || i == 8 || i == 10)
            dst[j++] = '-';
        dst[j++] = hex[(uuid[i] >> 4) & 0x0F];
        dst[j++] = hex[uuid[i] & 0x0F];
    }
}

static inline void sekhmet_ulid_to_uuid_bin(unsigned char *uuid,
                                              const unsigned char *ulid) {
    memcpy(uuid, ulid, 16);
    /* Stamp version 7: byte 6 high nibble = 0x7 */
    uuid[6] = (uuid[6] & 0x0F) | 0x70;
    /* Stamp variant RFC4122: byte 8 high 2 bits = 10 */
    uuid[8] = (uuid[8] & 0x3F) | 0x80;
}

static inline void sekhmet_ulid_to_uuid_str(char *dst,
                                              const unsigned char *ulid) {
    unsigned char uuid[16];
    sekhmet_ulid_to_uuid_bin(uuid, ulid);
    sekhmet_format_uuid(dst, uuid);
}

/* ── UUID string → ULID conversion ─────────────────────────────── *
 *
 * Parse UUID hex string, strip version/variant bits, recover ULID binary.
 */

static inline int sekhmet_parse_uuid_hex(unsigned char *out,
                                          const char *src, int len) {
    static const unsigned char hv[256] = {
        ['0'] = 0,  ['1'] = 1,  ['2'] = 2,  ['3'] = 3,
        ['4'] = 4,  ['5'] = 5,  ['6'] = 6,  ['7'] = 7,
        ['8'] = 8,  ['9'] = 9,
        ['a'] = 10, ['b'] = 11, ['c'] = 12, ['d'] = 13,
        ['e'] = 14, ['f'] = 15,
        ['A'] = 10, ['B'] = 11, ['C'] = 12, ['D'] = 13,
        ['E'] = 14, ['F'] = 15,
    };
    int i, j = 0;
    for (i = 0; i < len && j < 16; i++) {
        char c = src[i];
        if (c == '-') continue;
        if (i + 1 >= len) return 0;
        {
            char c2 = src[++i];
            /* skip hyphens in second nibble position too */
            while (c2 == '-' && i + 1 < len) c2 = src[++i];
            out[j++] = (unsigned char)((hv[(unsigned char)c] << 4)
                                      | hv[(unsigned char)c2]);
        }
    }
    return j == 16;
}

static inline int sekhmet_uuid_to_ulid_bin(unsigned char *ulid,
                                             const char *uuid_str, int len) {
    unsigned char uuid[16];
    if (!sekhmet_parse_uuid_hex(uuid, uuid_str, len))
        return 0;

    memcpy(ulid, uuid, 16);
    /* Restore original ULID random bits (clear version/variant stamps) */
    ulid[6] = (ulid[6] & 0x0F) | (uuid[6] & 0xF0);
    ulid[8] = (ulid[8] & 0x3F) | (uuid[8] & 0xC0);
    return 1;
}

/* ── Compare two binary ULIDs ──────────────────────────────────── */

static inline int sekhmet_ulid_compare(const unsigned char *a,
                                        const unsigned char *b) {
    return memcmp(a, b, 16);
}

/* ── Validate a ULID string ────────────────────────────────────── */

static inline int sekhmet_ulid_validate(const char *str, int len) {
    static const unsigned char valid[256] = {
        ['0'] = 1, ['1'] = 1, ['2'] = 1, ['3'] = 1, ['4'] = 1,
        ['5'] = 1, ['6'] = 1, ['7'] = 1, ['8'] = 1, ['9'] = 1,
        ['A'] = 1, ['B'] = 1, ['C'] = 1, ['D'] = 1, ['E'] = 1,
        ['F'] = 1, ['G'] = 1, ['H'] = 1, ['J'] = 1, ['K'] = 1,
        ['M'] = 1, ['N'] = 1, ['P'] = 1, ['Q'] = 1, ['R'] = 1,
        ['S'] = 1, ['T'] = 1, ['V'] = 1, ['W'] = 1, ['X'] = 1,
        ['Y'] = 1, ['Z'] = 1,
        ['a'] = 1, ['b'] = 1, ['c'] = 1, ['d'] = 1, ['e'] = 1,
        ['f'] = 1, ['g'] = 1, ['h'] = 1, ['j'] = 1, ['k'] = 1,
        ['m'] = 1, ['n'] = 1, ['p'] = 1, ['q'] = 1, ['r'] = 1,
        ['s'] = 1, ['t'] = 1, ['v'] = 1, ['w'] = 1, ['x'] = 1,
        ['y'] = 1, ['z'] = 1,
    };
    int i;
    if (len != 26) return 0;
    /* First char must be <= '7' (max timestamp 2^48-1 fits in 3 bits) */
    if ((unsigned char)str[0] > '7') return 0;
    for (i = 0; i < 26; i++) {
        if (!valid[(unsigned char)str[i]]) return 0;
    }
    return 1;
}

#endif /* SEKHMET_ULID_H */
