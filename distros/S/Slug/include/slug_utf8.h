#ifndef SLUG_UTF8_H
#define SLUG_UTF8_H

/*
 * slug_utf8.h — UTF-8 codepoint decoder
 *
 * Pure C, no Perl dependencies.
 * Decodes one UTF-8 codepoint at a time, advancing the pointer.
 * Invalid sequences are skipped (advance by 1 byte, return 0xFFFD).
 */

#include <stdint.h>

#define SLUG_REPLACEMENT_CHAR 0xFFFDu

/* Decode one UTF-8 codepoint from *p, advance *p past it.
 * Returns the codepoint, or SLUG_REPLACEMENT_CHAR on invalid input.
 * Guarantees forward progress: *p always advances by at least 1 byte. */
static inline uint32_t slug_utf8_decode(const unsigned char **p,
                                         const unsigned char *end) {
    const unsigned char *s = *p;
    uint32_t cp;
    int trail;

    if (s >= end) return 0;

    /* 1-byte: 0xxxxxxx */
    if (s[0] < 0x80) {
        *p = s + 1;
        return s[0];
    }
    /* 2-byte: 110xxxxx 10xxxxxx */
    else if ((s[0] & 0xE0) == 0xC0) {
        trail = 1;
        cp = s[0] & 0x1F;
    }
    /* 3-byte: 1110xxxx 10xxxxxx 10xxxxxx */
    else if ((s[0] & 0xF0) == 0xE0) {
        trail = 2;
        cp = s[0] & 0x0F;
    }
    /* 4-byte: 11110xxx 10xxxxxx 10xxxxxx 10xxxxxx */
    else if ((s[0] & 0xF8) == 0xF0) {
        trail = 3;
        cp = s[0] & 0x07;
    }
    /* Invalid lead byte */
    else {
        *p = s + 1;
        return SLUG_REPLACEMENT_CHAR;
    }

    /* Check we have enough bytes */
    if (s + 1 + trail > end) {
        *p = s + 1;
        return SLUG_REPLACEMENT_CHAR;
    }

    /* Decode continuation bytes */
    {
        int i;
        for (i = 1; i <= trail; i++) {
            if ((s[i] & 0xC0) != 0x80) {
                *p = s + 1;
                return SLUG_REPLACEMENT_CHAR;
            }
            cp = (cp << 6) | (s[i] & 0x3F);
        }
    }

    /* Overlong check */
    if ((trail == 1 && cp < 0x80) ||
        (trail == 2 && cp < 0x800) ||
        (trail == 3 && cp < 0x10000)) {
        *p = s + 1;
        return SLUG_REPLACEMENT_CHAR;
    }

    /* Surrogate check */
    if (cp >= 0xD800 && cp <= 0xDFFF) {
        *p = s + 1;
        return SLUG_REPLACEMENT_CHAR;
    }

    /* Beyond valid Unicode */
    if (cp > 0x10FFFF) {
        *p = s + 1;
        return SLUG_REPLACEMENT_CHAR;
    }

    *p = s + 1 + trail;
    return cp;
}

#endif /* SLUG_UTF8_H */
