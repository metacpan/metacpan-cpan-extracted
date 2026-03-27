#ifndef SLUG_TRANSFORM_H
#define SLUG_TRANSFORM_H

/*
 * slug_transform.h — Core slug generation algorithm
 *
 * Pure C, no Perl dependencies.
 * Single-pass streaming: decode UTF-8 → transliterate → lowercase →
 * emit alphanumeric or collapse to separator.
 */

#include <string.h>
#include "slug_utf8.h"
#include "slug_unicode.h"

/* ── Options ──────────────────────────────────────────────────── */

typedef struct {
    const char *separator;     /* separator string (default "-") */
    int         sep_len;       /* cached strlen(separator) */
    int         max_length;    /* 0 = unlimited */
    int         lowercase;     /* 1 = force lowercase */
    int         transliterate; /* 1 = unicode->ascii */
    int         trim_sep;      /* 1 = trim leading/trailing sep */
} slug_opts_t;

#define SLUG_OPTS_DEFAULT { "-", 1, 0, 1, 1, 1 }

/* ── ASCII helpers ────────────────────────────────────────────── */

static inline int slug_is_alnum(unsigned char c) {
    return (c >= 'a' && c <= 'z') ||
           (c >= 'A' && c <= 'Z') ||
           (c >= '0' && c <= '9');
}

static inline unsigned char slug_tolower(unsigned char c) {
    return (c >= 'A' && c <= 'Z') ? (c + 32) : c;
}

/* ── Emit helpers ─────────────────────────────────────────────── */

/* Emit a character, respecting max_length. Returns 1 if max exceeded. */
static inline int slug_emit_char(char *out, int *pos, int max, unsigned char c) {
    if (max > 0 && *pos >= max) return 1;
    out[(*pos)++] = c;
    return 0;
}

/* Emit a separator, collapsing consecutive. Returns 1 if max exceeded. */
static inline int slug_emit_sep(char *out, int *pos, int max,
                                 const slug_opts_t *opts, int *prev_sep) {
    int i;
    if (*prev_sep) return 0; /* already have trailing sep */
    if (max > 0 && *pos + opts->sep_len > max) return 1;
    for (i = 0; i < opts->sep_len; i++) {
        out[(*pos)++] = opts->separator[i];
    }
    *prev_sep = 1;
    return 0;
}

/* ── Emit a transliterated/ASCII string into the slug ─────────── */

static inline int slug_emit_ascii_str(char *out, int *pos, int max,
                                       const char *str, int str_len,
                                       const slug_opts_t *opts,
                                       int *prev_sep) {
    int i;
    for (i = 0; i < str_len; i++) {
        unsigned char c = (unsigned char)str[i];
        if (slug_is_alnum(c)) {
            if (opts->lowercase)
                c = slug_tolower(c);
            *prev_sep = 0;
            if (slug_emit_char(out, pos, max, c)) return 1;
        } else {
            /* Non-alnum in replacement → separator */
            if (slug_emit_sep(out, pos, max, opts, prev_sep)) return 1;
        }
    }
    return 0;
}

/* ── Core slug generator ──────────────────────────────────────── */

/*
 * Generate a URL slug from UTF-8 input.
 *
 * Returns: length of output slug (not including NUL terminator).
 * Output is always NUL-terminated if output_size > 0.
 */
static inline int slug_generate(const char *input, int input_len,
                                 char *output, int output_size,
                                 const slug_opts_t *opts) {
    const unsigned char *p = (const unsigned char *)input;
    const unsigned char *end = p + input_len;
    int pos = 0;
    int prev_sep = opts->trim_sep ? 1 : 0;  /* start as sep=1 → trims leading */
    int max = opts->max_length;

    if (max <= 0 || max >= output_size)
        max = output_size - 1;

    while (p < end) {
        unsigned char byte = *p;

        /* Fast path: ASCII */
        if (byte < 0x80) {
            if (slug_is_alnum(byte)) {
                unsigned char c = opts->lowercase ? slug_tolower(byte) : byte;
                prev_sep = 0;
                if (slug_emit_char(output, &pos, max, c)) break;
            } else {
                /* Non-alnum ASCII → separator */
                if (slug_emit_sep(output, &pos, max, opts, &prev_sep)) break;
            }
            p++;
        } else {
            /* Multi-byte UTF-8 */
            uint32_t cp = slug_utf8_decode(&p, end);

            if (opts->transliterate) {
                const char *repl = slug_transliterate(cp);
                if (repl != NULL) {
                    int rlen = (int)strlen(repl);
                    if (rlen > 0) {
                        if (slug_emit_ascii_str(output, &pos, max, repl, rlen,
                                                opts, &prev_sep))
                            break;
                    }
                    /* rlen == 0 → drop (soft sign, hard sign, etc.) */
                } else {
                    /* No mapping → emit separator (drop the char) */
                    if (slug_emit_sep(output, &pos, max, opts, &prev_sep)) break;
                }
            } else {
                /* No transliteration → emit separator for non-ASCII */
                if (slug_emit_sep(output, &pos, max, opts, &prev_sep)) break;
            }
        }
    }

    /* Trim trailing separator */
    if (opts->trim_sep && pos > 0 && prev_sep) {
        pos -= opts->sep_len;
        if (pos < 0) pos = 0;
    }

    if (output_size > 0)
        output[pos] = '\0';

    return pos;
}

/* ── Transliterate-only mode (no slugification) ───────────────── */

/*
 * Transliterate Unicode to ASCII without slugifying.
 * Preserves spaces, punctuation, and case.
 *
 * Returns: length of output (not including NUL terminator).
 */
static inline int slug_transliterate_str(const char *input, int input_len,
                                          char *output, int output_size) {
    const unsigned char *p = (const unsigned char *)input;
    const unsigned char *end = p + input_len;
    int pos = 0;
    int max = output_size - 1;

    while (p < end && pos < max) {
        unsigned char byte = *p;

        /* ASCII passthrough */
        if (byte < 0x80) {
            output[pos++] = (char)byte;
            p++;
        } else {
            uint32_t cp = slug_utf8_decode(&p, end);
            const char *repl = slug_transliterate(cp);
            if (repl != NULL) {
                int rlen = (int)strlen(repl);
                int i;
                for (i = 0; i < rlen && pos < max; i++) {
                    output[pos++] = repl[i];
                }
            }
            /* No mapping → drop */
        }
    }

    if (output_size > 0)
        output[pos] = '\0';

    return pos;
}

#endif /* SLUG_TRANSFORM_H */
