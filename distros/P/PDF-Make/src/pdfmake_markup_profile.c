/*
 * pdfmake_markup_profile.c - the rules a template runs under.
 *
 * Two things a template must not be able to do, and both are decided here:
 * reach code, and turn a data value into markup. The Perl side holds no part
 * of either; see PDF::Make::Markup::Profile for why each rule exists.
 */

#include "pdfmake_markup_profile.h"
#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <ctype.h>

/*
 * {% raw value %} prints a value with no escaping, which is exactly the
 * injection the profile exists to prevent, and Template::Stencil offers no
 * way to disable it. A template that uses it is refused before it compiles.
 *
 * The scan is over the source rather than the compiled program because that
 * is the only place the construct is still visible.
 */
int pdfmake_profile_check_source(const char *src, size_t len,
                                 uint32_t *err_line,
                                 char *err, size_t errlen)
{
    size_t i = 0;
    uint32_t line = 1;

    if (!src) return 1;

    for (i = 0; i + 1 < len; i++) {
        if (src[i] == '\n') { line++; continue; }
        if (src[i] != '{' || src[i + 1] != '%') continue;

        {
            size_t j = i + 2;
            while (j < len && (src[j] == ' ' || src[j] == '\t')) j++;
            if (j + 3 > len) continue;
            if (memcmp(src + j, "raw", 3) != 0) continue;
            /* "raw" must be the whole word: {% rawtotal %} is a variable. */
            if (j + 3 < len && (isalnum((unsigned char)src[j + 3]) ||
                                src[j + 3] == '_' || src[j + 3] == '.'))
                continue;

            if (err_line) *err_line = line;
            if (err && errlen)
                snprintf(err, errlen,
                    "{%% raw %%} is not available. It prints a value without "
                    "escaping, so a name or address containing < or & would "
                    "become document structure. Values are escaped; markup "
                    "belongs in the template.");
            return 0;
        }
    }
    return 1;
}

/*
 * Formatting a template can use without being able to compute. Both of these
 * are pure functions of their input: a filter that could do anything else
 * would be a way back to code.
 */

static int numeric(const char *v, size_t len, double *out) {
    char buf[64];
    size_t n = 0, i;
    int digits = 0, dot = 0;

    while (len && isspace((unsigned char)*v)) { v++; len--; }
    while (len && isspace((unsigned char)v[len - 1])) len--;
    if (!len || len >= sizeof(buf)) return 0;

    for (i = 0; i < len; i++) {
        char c = v[i];
        if (i == 0 && (c == '-' || c == '+')) { buf[n++] = c; continue; }
        if (c == '.') { if (dot) return 0; dot = 1; buf[n++] = c; continue; }
        if (c < '0' || c > '9') return 0;
        buf[n++] = c;
        digits++;
    }
    if (!digits) return 0;
    buf[n] = '\0';
    *out = strtod(buf, NULL);
    return 1;
}

/* Group the integer part in threes, in place. */
static size_t group(char *s, size_t len) {
    size_t start = (s[0] == '-') ? 1 : 0;
    size_t digits = len - start;
    size_t commas = digits ? (digits - 1) / 3 : 0;
    size_t i, from, to;

    if (!commas) return len;

    from = len;
    to   = len + commas;
    s[to] = '\0';
    for (i = 0; from > start; ) {
        s[--to] = s[--from];
        if (++i % 3 == 0 && from > start) s[--to] = ',';
    }
    return len + commas;
}

size_t pdfmake_profile_money(const char *v, size_t len, char *out, size_t outlen)
{
    double d;
    int n;
    char *dot;
    char frac[8];
    size_t ilen, flen;

    if (!numeric(v, len, &d)) { if (outlen) out[0] = '\0'; return 0; }
    n = snprintf(out, outlen, "%.2f", d);
    if (n < 0 || (size_t)n >= outlen) { if (outlen) out[0] = '\0'; return 0; }

    /* Group the integer part only. Grouping the whole string counts from the
     * end and puts a separator in the pence: 1240.50 became 1,240,.50. */
    dot = strchr(out, '.');
    if (!dot) return group(out, (size_t)n);

    flen = strlen(dot);
    if (flen >= sizeof(frac)) return (size_t)n;
    memcpy(frac, dot, flen + 1);
    *dot = '\0';

    ilen = group(out, strlen(out));
    if (ilen + flen + 1 >= outlen) { out[0] = '\0'; return 0; }
    memcpy(out + ilen, frac, flen + 1);
    return ilen + flen;
}

size_t pdfmake_profile_number(const char *v, size_t len, char *out, size_t outlen)
{
    double d;
    int n;
    size_t ilen;
    char frac[32];

    if (!numeric(v, len, &d)) { if (outlen) out[0] = '\0'; return 0; }

    n = snprintf(out, outlen, "%.10g", d);
    if (n < 0 || (size_t)n >= outlen) { if (outlen) out[0] = '\0'; return 0; }

    {   /* split off the fraction, group the integer part, put it back */
        char *dot = strchr(out, '.');
        frac[0] = '\0';
        if (dot) {
            size_t fl = strlen(dot);
            if (fl >= sizeof(frac)) { out[0] = '\0'; return 0; }
            memcpy(frac, dot, fl + 1);
            *dot = '\0';
        }
        ilen = group(out, strlen(out));
        if (frac[0]) {
            size_t fl = strlen(frac);
            if (ilen + fl + 1 >= outlen) { out[0] = '\0'; return 0; }
            memcpy(out + ilen, frac, fl + 1);
            ilen += fl;
        }
    }
    return ilen;
}
