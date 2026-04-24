#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <ctype.h>
#include <stdlib.h>
#include <string.h>
#include <stdio.h>

typedef struct {
    const char *text;
    STRLEN len;
    STRLEN pos;
} brace_parser_t;

typedef struct {
    int pretty;
    int canonical;
    int indent;
} brace_encode_opts_t;

static int is_ident_start_char(char c) {
    return (c == '_') || (c >= 'A' && c <= 'Z') || (c >= 'a' && c <= 'z');
}

static int is_ident_char(char c) {
    return is_ident_start_char(c) || (c >= '0' && c <= '9') || c == '-';
}

static void bp_skip_ws(brace_parser_t *p) {
    while (p->pos < p->len) {
        char ch = p->text[p->pos];
        if (ch == ' ' || ch == '\t' || ch == '\n' || ch == '\r') {
            p->pos++;
            continue;
        }
        break;
    }
}

static char bp_peek(brace_parser_t *p) {
    if (p->pos >= p->len) {
        return '\0';
    }
    return p->text[p->pos];
}

static void bp_throw(const char *msg) {
    croak("%s", msg);
}

static void bp_expect(brace_parser_t *p, char expected) {
    char got = bp_peek(p);
    if (!got || got != expected) {
        char msg[64];
        snprintf(msg, sizeof(msg), "Expected '%c'", expected);
        bp_throw(msg);
    }
    p->pos++;
}

static int bp_consume_literal(brace_parser_t *p, const char *literal) {
    STRLEN litlen = (STRLEN)strlen(literal);
    if (p->pos + litlen > p->len) {
        return 0;
    }
    if (strncmp(p->text + p->pos, literal, litlen) != 0) {
        return 0;
    }

    if (p->pos + litlen < p->len) {
        char next = p->text[p->pos + litlen];
        if (is_ident_char(next)) {
            return 0;
        }
    }

    p->pos += litlen;
    return 1;
}

static SV *bp_parse_value(brace_parser_t *p);

static int is_numeric_token(const char *s, STRLEN n) {
    STRLEN i = 0;
    int has_digit = 0;

    if (i < n && (s[i] == '+' || s[i] == '-')) {
        i++;
    }

    while (i < n && isdigit((unsigned char)s[i])) {
        has_digit = 1;
        i++;
    }

    if (i < n && s[i] == '.') {
        i++;
        while (i < n && isdigit((unsigned char)s[i])) {
            has_digit = 1;
            i++;
        }
    }

    if (!has_digit) {
        return 0;
    }

    if (i < n && (s[i] == 'e' || s[i] == 'E')) {
        i++;
        if (i < n && (s[i] == '+' || s[i] == '-')) {
            i++;
        }
        if (i >= n || !isdigit((unsigned char)s[i])) {
            return 0;
        }
        while (i < n && isdigit((unsigned char)s[i])) {
            i++;
        }
    }

    return i == n;
}

static SV *bp_parse_number(brace_parser_t *p) {
    STRLEN start = p->pos;

    if (bp_peek(p) == '-') {
        p->pos++;
    }

    if (!isdigit((unsigned char)bp_peek(p))) {
        bp_throw("Invalid number");
    }

    if (bp_peek(p) == '0') {
        p->pos++;
    } else {
        while (isdigit((unsigned char)bp_peek(p))) {
            p->pos++;
        }
    }

    if (bp_peek(p) == '.') {
        p->pos++;
        if (!isdigit((unsigned char)bp_peek(p))) {
            bp_throw("Invalid number");
        }
        while (isdigit((unsigned char)bp_peek(p))) {
            p->pos++;
        }
    }

    if (bp_peek(p) == 'e' || bp_peek(p) == 'E') {
        p->pos++;
        if (bp_peek(p) == '+' || bp_peek(p) == '-') {
            p->pos++;
        }
        if (!isdigit((unsigned char)bp_peek(p))) {
            bp_throw("Invalid number");
        }
        while (isdigit((unsigned char)bp_peek(p))) {
            p->pos++;
        }
    }

    STRLEN n = p->pos - start;
    SV *token = newSVpvn(p->text + start, n);
    const char *s = SvPV_nolen(token);

    if (memchr(s, '.', n) || memchr(s, 'e', n) || memchr(s, 'E', n)) {
        NV nv = SvNV(token);
        SvREFCNT_dec(token);
        return newSVnv(nv);
    }

    IV iv = SvIV(token);
    SvREFCNT_dec(token);
    return newSViv(iv);
}

static SV *bp_parse_string(brace_parser_t *p) {
    bp_expect(p, '"');

    SV *out = newSVpvn("", 0);

    while (p->pos < p->len) {
        char ch = p->text[p->pos++];

        if (ch == '"') {
            return out;
        }

        if (ch == '\\') {
            if (p->pos >= p->len) {
                SvREFCNT_dec(out);
                bp_throw("Unexpected end of input in string escape");
            }

            char esc = p->text[p->pos++];
            switch (esc) {
                case '"': sv_catpvn(out, "\"", 1); break;
                case '\\': sv_catpvn(out, "\\", 1); break;
                case '/': sv_catpvn(out, "/", 1); break;
                case 'n': sv_catpvn(out, "\n", 1); break;
                case 'r': sv_catpvn(out, "\r", 1); break;
                case 't': sv_catpvn(out, "\t", 1); break;
                case 'f': sv_catpvn(out, "\f", 1); break;
                case 'b': {
                    char bs = '\b';
                    sv_catpvn(out, &bs, 1);
                    break;
                }
                case 'u': {
                    if (p->pos + 4 > p->len) {
                        SvREFCNT_dec(out);
                        bp_throw("Invalid unicode escape");
                    }
                    char hexbuf[5];
                    memcpy(hexbuf, p->text + p->pos, 4);
                    hexbuf[4] = '\0';
                    p->pos += 4;
                    unsigned long uv = strtoul(hexbuf, NULL, 16);
                    if (uv <= 0x7F) {
                        char c = (char)uv;
                        sv_catpvn(out, &c, 1);
                    } else {
                        char tmp[UTF8_MAXBYTES + 1];
                        UV len = uvchr_to_utf8((U8*)tmp, (UV)uv) - (U8*)tmp;
                        sv_catpvn(out, tmp, (STRLEN)len);
                    }
                    break;
                }
                default:
                    SvREFCNT_dec(out);
                    bp_throw("Unknown escape sequence");
            }
            continue;
        }

        sv_catpvn(out, &ch, 1);
    }

    SvREFCNT_dec(out);
    bp_throw("Unterminated string");
    return &PL_sv_undef;
}

static SV *bp_parse_key(brace_parser_t *p) {
    char ch = bp_peek(p);
    if (ch == '"') {
        return bp_parse_string(p);
    }

    if (!is_ident_start_char(ch)) {
        bp_throw("Expected object key");
    }

    STRLEN start = p->pos;
    p->pos++;
    while (is_ident_char(bp_peek(p))) {
        p->pos++;
    }

    return newSVpvn(p->text + start, p->pos - start);
}

static int sv_cmp_qsort(const void *a, const void *b) {
    SV *sa = *(SV**)a;
    SV *sb = *(SV**)b;
    STRLEN na, nb;
    const char *pa = SvPV(sa, na);
    const char *pb = SvPV(sb, nb);
    STRLEN n = na < nb ? na : nb;
    int c = memcmp(pa, pb, n);
    if (c != 0) return c;
    if (na < nb) return -1;
    if (na > nb) return 1;
    return 0;
}

static AV *hv_sorted_keys(HV *hv) {
    I32 count = hv_iterinit(hv);
    SV **arr = (SV**)safemalloc(sizeof(SV*) * (count > 0 ? count : 1));
    I32 idx = 0;
    HE *he;

    while ((he = hv_iternext(hv)) != NULL) {
        SV *k = hv_iterkeysv(he);
        arr[idx++] = newSVsv(k);
    }

    if (idx > 1) {
        qsort(arr, (size_t)idx, sizeof(SV*), sv_cmp_qsort);
    }

    AV *av = newAV();
    for (I32 i = 0; i < idx; i++) {
        av_push(av, arr[i]);
    }

    safefree(arr);
    return av;
}

static int sv_is_identifier_key(SV *key) {
    STRLEN n;
    const char *s = SvPV(key, n);
    if (n == 0 || !is_ident_start_char(s[0])) {
        return 0;
    }
    for (STRLEN i = 1; i < n; i++) {
        if (!is_ident_char(s[i])) {
            return 0;
        }
    }
    return 1;
}

static SV *bp_parse_tabular_value(brace_parser_t *p) {
    STRLEN start = p->pos;
    while (p->pos < p->len) {
        char c = p->text[p->pos];
        if (c == ',' || c == '\n' || c == '\r') {
            break;
        }
        p->pos++;
    }

    STRLEN end = p->pos;
    while (end > start && (p->text[end - 1] == ' ' || p->text[end - 1] == '\t')) {
        end--;
    }

    STRLEN n = end - start;
    if (is_numeric_token(p->text + start, n)) {
        SV *tmp = newSVpvn(p->text + start, n);
        SV *out;
        if (memchr(SvPV_nolen(tmp), '.', n) || memchr(SvPV_nolen(tmp), 'e', n) || memchr(SvPV_nolen(tmp), 'E', n)) {
            out = newSVnv(SvNV(tmp));
        } else {
            out = newSViv(SvIV(tmp));
        }
        SvREFCNT_dec(tmp);
        return out;
    }

    return newSVpvn(p->text + start, n);
}

static SV *bp_parse_tabular(brace_parser_t *p) {
    HV *result = newHV();

    while (p->pos < p->len) {
        bp_skip_ws(p);
        if (p->pos >= p->len) {
            break;
        }

        if (!is_ident_start_char(bp_peek(p))) {
            break;
        }

        STRLEN key_start = p->pos;
        p->pos++;
        while (is_ident_char(bp_peek(p))) {
            p->pos++;
        }
        SV *key_sv = newSVpvn(p->text + key_start, p->pos - key_start);

        bp_expect(p, '[');

        STRLEN cnt_start = p->pos;
        while (isdigit((unsigned char)bp_peek(p))) {
            p->pos++;
        }
        if (p->pos == cnt_start) {
            SvREFCNT_dec(key_sv);
            SvREFCNT_dec((SV*)result);
            bp_throw("Expected count in [...]");
        }

        SV *cnt_sv = newSVpvn(p->text + cnt_start, p->pos - cnt_start);
        IV count = SvIV(cnt_sv);
        SvREFCNT_dec(cnt_sv);

        bp_expect(p, ']');
        bp_expect(p, '{');

        AV *fields = newAV();
        while (1) {
            if (!is_ident_start_char(bp_peek(p))) {
                SvREFCNT_dec(key_sv);
                SvREFCNT_dec((SV*)fields);
                SvREFCNT_dec((SV*)result);
                bp_throw("Expected field name");
            }

            STRLEN fs = p->pos;
            p->pos++;
            while (is_ident_char(bp_peek(p))) {
                p->pos++;
            }
            av_push(fields, newSVpvn(p->text + fs, p->pos - fs));

            if (bp_peek(p) == ',') {
                p->pos++;
                continue;
            }
            break;
        }

        bp_expect(p, '}');
        bp_expect(p, ':');

        AV *rows = newAV();
        I32 nfields = av_len(fields) + 1;

        for (IV r = 0; r < count; r++) {
            while (p->pos < p->len) {
                char c = p->text[p->pos++];
                if (c == '\n') {
                    break;
                }
            }

            while (p->pos < p->len) {
                char c = p->text[p->pos];
                if (c == ' ' || c == '\t') {
                    p->pos++;
                    continue;
                }
                break;
            }

            HV *row = newHV();
            for (I32 fi = 0; fi < nfields; fi++) {
                if (fi > 0) {
                    bp_expect(p, ',');
                }

                SV **fsv = av_fetch(fields, fi, 0);
                SV *v = bp_parse_tabular_value(p);
                STRLEN kn;
                const char *k = SvPV(*fsv, kn);
                hv_store(row, k, (I32)kn, v, 0);
            }
            av_push(rows, newRV_noinc((SV*)row));
        }

        STRLEN kn;
        const char *k = SvPV(key_sv, kn);
        hv_store(result, k, (I32)kn, newRV_noinc((SV*)rows), 0);

        SvREFCNT_dec(key_sv);
        SvREFCNT_dec((SV*)fields);
    }

    return newRV_noinc((SV*)result);
}

static SV *bp_parse_array(brace_parser_t *p) {
    bp_expect(p, '[');
    bp_skip_ws(p);

    AV *array = newAV();

    if (bp_peek(p) == ']') {
        p->pos++;
        return newRV_noinc((SV*)array);
    }

    while (1) {
        SV *v = bp_parse_value(p);
        av_push(array, v);

        bp_skip_ws(p);
        if (bp_peek(p) == ',') {
            p->pos++;
            bp_skip_ws(p);
            continue;
        }
        break;
    }

    bp_skip_ws(p);
    bp_expect(p, ']');

    return newRV_noinc((SV*)array);
}

static SV *bp_parse_object(brace_parser_t *p) {
    bp_expect(p, '{');
    bp_skip_ws(p);

    HV *hash = newHV();

    if (bp_peek(p) == '}') {
        p->pos++;
        return newRV_noinc((SV*)hash);
    }

    while (1) {
        bp_skip_ws(p);
        SV *key_sv = bp_parse_key(p);

        bp_skip_ws(p);
        bp_expect(p, ':');
        bp_skip_ws(p);

        SV *value = bp_parse_value(p);

        STRLEN kn;
        const char *k = SvPV(key_sv, kn);
        hv_store(hash, k, (I32)kn, value, 0);
        SvREFCNT_dec(key_sv);

        bp_skip_ws(p);
        if (bp_peek(p) == ',') {
            p->pos++;
            continue;
        }
        break;
    }

    bp_skip_ws(p);
    bp_expect(p, '}');

    return newRV_noinc((SV*)hash);
}

static SV *bp_parse_value(brace_parser_t *p) {
    bp_skip_ws(p);

    char ch = bp_peek(p);
    if (!ch) {
        bp_throw("Unexpected end of input");
    }

    if (ch == '{') return bp_parse_object(p);
    if (ch == '[') return bp_parse_array(p);
    if (ch == '"') return bp_parse_string(p);

    if (bp_consume_literal(p, "null")) return newSV(0);
    if (bp_consume_literal(p, "true")) return newSViv(1);
    if (bp_consume_literal(p, "false")) return newSViv(0);

    if (ch == '-' || isdigit((unsigned char)ch)) {
        return bp_parse_number(p);
    }

    if (is_ident_start_char(ch)) {
        return bp_parse_tabular(p);
    }

    bp_throw("Unexpected character");
    return newSV(0);
}

static int sv_is_plain_numberish(SV *sv) {
    if (!SvOK(sv)) return 0;
    if (SvNOK(sv) || SvIOK(sv) || looks_like_number(sv)) return 1;
    return 0;
}

static void encode_quoted_string(SV *out, SV *value) {
    STRLEN n;
    const char *s = SvPV(value, n);
    sv_catpvn(out, "\"", 1);
    for (STRLEN i = 0; i < n; i++) {
        char c = s[i];
        switch (c) {
            case '\\': sv_catpvn(out, "\\\\", 2); break;
            case '"': sv_catpvn(out, "\\\"", 2); break;
            case '\n': sv_catpvn(out, "\\n", 2); break;
            case '\r': sv_catpvn(out, "\\r", 2); break;
            case '\t': sv_catpvn(out, "\\t", 2); break;
            case '\f': sv_catpvn(out, "\\f", 2); break;
            case '\b': sv_catpvn(out, "\\b", 2); break;
            default: sv_catpvn(out, &c, 1); break;
        }
    }
    sv_catpvn(out, "\"", 1);
}

static int is_tabular_encodable(HV *hv) {
    hv_iterinit(hv);
    HE *he;

    while ((he = hv_iternext(hv)) != NULL) {
        SV *key = hv_iterkeysv(he);
        if (!sv_is_identifier_key(key)) return 0;

        SV *val = hv_iterval(hv, he);
        if (!SvROK(val) || SvTYPE(SvRV(val)) != SVt_PVAV) return 0;

        AV *arr = (AV*)SvRV(val);
        I32 arr_len = av_len(arr) + 1;
        if (arr_len <= 0) return 0;

        SV **first_row_sv = av_fetch(arr, 0, 0);
        if (!first_row_sv || !SvROK(*first_row_sv) || SvTYPE(SvRV(*first_row_sv)) != SVt_PVHV) return 0;
        HV *first_row = (HV*)SvRV(*first_row_sv);

        AV *fields = hv_sorted_keys(first_row);
        I32 nfields = av_len(fields) + 1;

        for (I32 fi = 0; fi < nfields; fi++) {
            SV **f = av_fetch(fields, fi, 0);
            if (!f || !sv_is_identifier_key(*f)) {
                SvREFCNT_dec((SV*)fields);
                return 0;
            }
        }

        for (I32 ri = 0; ri < arr_len; ri++) {
            SV **row_sv = av_fetch(arr, ri, 0);
            if (!row_sv || !SvROK(*row_sv) || SvTYPE(SvRV(*row_sv)) != SVt_PVHV) {
                SvREFCNT_dec((SV*)fields);
                return 0;
            }

            HV *row = (HV*)SvRV(*row_sv);
            I32 row_count = hv_iterinit(row);
            if (row_count != nfields) {
                SvREFCNT_dec((SV*)fields);
                return 0;
            }

            for (I32 fi = 0; fi < nfields; fi++) {
                SV **f = av_fetch(fields, fi, 0);
                STRLEN fn;
                const char *fname = SvPV(*f, fn);
                SV **cell = hv_fetch(row, fname, (I32)fn, 0);
                if (!cell || !SvOK(*cell)) {
                    SvREFCNT_dec((SV*)fields);
                    return 0;
                }
                if (!sv_is_plain_numberish(*cell)) {
                    STRLEN cn;
                    const char *cs = SvPV(*cell, cn);
                    for (STRLEN ci = 0; ci < cn; ci++) {
                        if (cs[ci] == ',' || cs[ci] == '\n' || cs[ci] == '\r') {
                            SvREFCNT_dec((SV*)fields);
                            return 0;
                        }
                    }
                }
            }
        }

        SvREFCNT_dec((SV*)fields);
    }

    return 1;
}

static void encode_value_brace(SV *out, SV *value, I32 level, brace_encode_opts_t *opts);

static void append_indent(SV *out, I32 level, I32 indent) {
    I32 n = level * indent;
    for (I32 i = 0; i < n; i++) {
        sv_catpvn(out, " ", 1);
    }
}

static void encode_tabular_value(SV *out, SV *value) {
    if (!SvOK(value)) {
        return;
    }
    if (sv_is_plain_numberish(value)) {
        SV *num = newSVnv(SvNV(value));
        sv_catpv(out, SvPV_nolen(num));
        SvREFCNT_dec(num);
        return;
    }
    sv_catpv(out, SvPV_nolen(value));
}

static void encode_hash_brace(SV *out, HV *hv, I32 level, brace_encode_opts_t *opts) {
    I32 key_count = hv_iterinit(hv);
    if (key_count == 0) {
        sv_catpvn(out, "{}", 2);
        return;
    }

    if (level == 0 && is_tabular_encodable(hv)) {
        AV *keys = hv_sorted_keys(hv);
        I32 nkeys = av_len(keys) + 1;

        for (I32 ki = 0; ki < nkeys; ki++) {
            SV **ksv = av_fetch(keys, ki, 0);
            STRLEN kn;
            const char *k = SvPV(*ksv, kn);
            SV **arr_sv = hv_fetch(hv, k, (I32)kn, 0);
            AV *arr = (AV*)SvRV(*arr_sv);
            I32 arr_len = av_len(arr) + 1;

            SV **first_row_sv = av_fetch(arr, 0, 0);
            HV *first_row = (HV*)SvRV(*first_row_sv);
            AV *fields = hv_sorted_keys(first_row);
            I32 nfields = av_len(fields) + 1;

            sv_catpvf(out, "%s[%ld]{", k, (long)arr_len);
            for (I32 fi = 0; fi < nfields; fi++) {
                if (fi > 0) sv_catpvn(out, ",", 1);
                SV **fsv = av_fetch(fields, fi, 0);
                sv_catpv(out, SvPV_nolen(*fsv));
            }
            sv_catpvn(out, "}:\n", 3);

            for (I32 ri = 0; ri < arr_len; ri++) {
                SV **row_sv = av_fetch(arr, ri, 0);
                HV *row = (HV*)SvRV(*row_sv);
                sv_catpvn(out, "  ", 2);
                for (I32 fi = 0; fi < nfields; fi++) {
                    if (fi > 0) sv_catpvn(out, ",", 1);
                    SV **fsv = av_fetch(fields, fi, 0);
                    STRLEN fn;
                    const char *fname = SvPV(*fsv, fn);
                    SV **cell = hv_fetch(row, fname, (I32)fn, 0);
                    encode_tabular_value(out, *cell);
                }
                sv_catpvn(out, "\n", 1);
            }

            SvREFCNT_dec((SV*)fields);
        }

        SvREFCNT_dec((SV*)keys);
        return;
    }

    AV *keys;
    if (opts->canonical) {
        keys = hv_sorted_keys(hv);
    } else {
        keys = newAV();
        hv_iterinit(hv);
        HE *he;
        while ((he = hv_iternext(hv)) != NULL) {
            av_push(keys, newSVsv(hv_iterkeysv(he)));
        }
    }

    I32 nkeys = av_len(keys) + 1;

    if (!opts->pretty) {
        sv_catpvn(out, "{", 1);
        for (I32 i = 0; i < nkeys; i++) {
            if (i > 0) sv_catpvn(out, ", ", 2);
            SV **ksv = av_fetch(keys, i, 0);
            STRLEN kn;
            const char *k = SvPV(*ksv, kn);

            if (sv_is_identifier_key(*ksv)) {
                sv_catpvn(out, k, kn);
            } else {
                encode_quoted_string(out, *ksv);
            }
            sv_catpvn(out, ": ", 2);

            SV **v = hv_fetch(hv, k, (I32)kn, 0);
            encode_value_brace(out, *v, level + 1, opts);
        }
        sv_catpvn(out, "}", 1);
        SvREFCNT_dec((SV*)keys);
        return;
    }

    sv_catpvn(out, "{\n", 2);
    for (I32 i = 0; i < nkeys; i++) {
        if (i > 0) sv_catpvn(out, ",\n", 2);
        append_indent(out, level + 1, opts->indent);

        SV **ksv = av_fetch(keys, i, 0);
        STRLEN kn;
        const char *k = SvPV(*ksv, kn);

        if (sv_is_identifier_key(*ksv)) {
            sv_catpvn(out, k, kn);
        } else {
            encode_quoted_string(out, *ksv);
        }
        sv_catpvn(out, ": ", 2);

        SV **v = hv_fetch(hv, k, (I32)kn, 0);
        encode_value_brace(out, *v, level + 1, opts);
    }
    sv_catpvn(out, "\n", 1);
    append_indent(out, level, opts->indent);
    sv_catpvn(out, "}", 1);

    SvREFCNT_dec((SV*)keys);
}

static void encode_array_brace(SV *out, AV *av, I32 level, brace_encode_opts_t *opts) {
    I32 n = av_len(av) + 1;
    if (n <= 0) {
        sv_catpvn(out, "[]", 2);
        return;
    }

    if (!opts->pretty) {
        sv_catpvn(out, "[", 1);
        for (I32 i = 0; i < n; i++) {
            if (i > 0) sv_catpvn(out, ", ", 2);
            SV **item = av_fetch(av, i, 0);
            encode_value_brace(out, *item, level + 1, opts);
        }
        sv_catpvn(out, "]", 1);
        return;
    }

    sv_catpvn(out, "[\n", 2);
    for (I32 i = 0; i < n; i++) {
        if (i > 0) sv_catpvn(out, ",\n", 2);
        append_indent(out, level + 1, opts->indent);
        SV **item = av_fetch(av, i, 0);
        encode_value_brace(out, *item, level + 1, opts);
    }
    sv_catpvn(out, "\n", 1);
    append_indent(out, level, opts->indent);
    sv_catpvn(out, "]", 1);
}

static void encode_value_brace(SV *out, SV *value, I32 level, brace_encode_opts_t *opts) {
    if (!SvOK(value)) {
        sv_catpvn(out, "null", 4);
        return;
    }

    if (SvROK(value)) {
        SV *rv = SvRV(value);
        if (SvOBJECT(rv)) {
            bp_throw("Encoding blessed references is not supported");
        }
        if (SvTYPE(rv) == SVt_PVAV) {
            encode_array_brace(out, (AV*)rv, level, opts);
            return;
        }
        if (SvTYPE(rv) == SVt_PVHV) {
            encode_hash_brace(out, (HV*)rv, level, opts);
            return;
        }
        bp_throw("Encoding references of this type is not supported");
    }

    STRLEN n;
    const char *s = SvPV(value, n);
    if (n == 4 && strncmp(s, "true", 4) == 0) {
        sv_catpvn(out, "true", 4);
        return;
    }
    if (n == 5 && strncmp(s, "false", 5) == 0) {
        sv_catpvn(out, "false", 5);
        return;
    }

    if (sv_is_plain_numberish(value)) {
        SV *num;
        if (SvIOK(value) && !SvNOK(value)) {
            num = newSViv(SvIV(value));
        } else {
            num = newSVnv(SvNV(value));
        }
        sv_catpv(out, SvPV_nolen(num));
        SvREFCNT_dec(num);
        return;
    }

    encode_quoted_string(out, value);
}

static void parse_brace_encode_opts(SV *opts_sv, brace_encode_opts_t *opts) {
    opts->pretty = 0;
    opts->canonical = 0;
    opts->indent = 2;

    if (!opts_sv || !SvOK(opts_sv) || !SvROK(opts_sv) || SvTYPE(SvRV(opts_sv)) != SVt_PVHV) {
        return;
    }

    HV *hv = (HV*)SvRV(opts_sv);
    SV **v;

    v = hv_fetch(hv, "pretty", 6, 0);
    if (v) opts->pretty = SvTRUE(*v) ? 1 : 0;

    v = hv_fetch(hv, "canonical", 9, 0);
    if (v) opts->canonical = SvTRUE(*v) ? 1 : 0;

    v = hv_fetch(hv, "indent", 6, 0);
    if (v) {
        IV iv = SvIV(*v);
        opts->indent = iv > 0 ? (int)iv : 2;
    }
}

static SV *xs_decode_brace_impl(SV *text_sv) {
    STRLEN len;
    const char *text = SvPV(text_sv, len);

    brace_parser_t p;
    p.text = text;
    p.len = len;
    p.pos = 0;

    bp_skip_ws(&p);
    SV *value = bp_parse_value(&p);
    bp_skip_ws(&p);

    if (p.pos < p.len) {
        SvREFCNT_dec(value);
        bp_throw("Trailing characters after document");
    }

    return value;
}

static SV *xs_encode_brace_impl(SV *data_sv, SV *opts_sv) {
    brace_encode_opts_t opts;
    parse_brace_encode_opts(opts_sv, &opts);

    SV *out = newSVpvn("", 0);
    encode_value_brace(out, data_sv, 0, &opts);
    return out;
}

typedef struct {
    AV *lines;
    I32 pos;
    I32 max_depth;
} line_decode_ctx_t;

typedef struct {
    I32 indent;
    char delimiter;
    I32 depth;
    I32 max_depth;
    HV *seen;
    HV *priority;
} line_encode_ctx_t;

static int is_word_char(char c) {
    return (c == '_') || isalnum((unsigned char)c);
}

static SV *line_trimmed_sv(SV *in) {
    STRLEN n;
    const char *s = SvPV(in, n);
    STRLEN start = 0;
    while (start < n && (s[start] == ' ' || s[start] == '\t')) start++;
    STRLEN end = n;
    while (end > start && (s[end - 1] == ' ' || s[end - 1] == '\t')) end--;
    return newSVpvn(s + start, end - start);
}

static SV *line_ltrimmed_sv(SV *in) {
    STRLEN n;
    const char *s = SvPV(in, n);
    STRLEN start = 0;
    while (start < n && (s[start] == ' ' || s[start] == '\t')) start++;
    return newSVpvn(s + start, n - start);
}

static I32 line_depth_from_sv(SV *line) {
    STRLEN n;
    const char *s = SvPV(line, n);
    STRLEN i = 0;
    while (i < n && s[i] == ' ') i++;
    return (I32)(i / 2);
}

static AV *line_split_lines(SV *text_sv) {
    STRLEN n;
    const char *s = SvPV(text_sv, n);
    AV *lines = newAV();

    STRLEN start = 0;
    for (STRLEN i = 0; i < n; i++) {
        if (s[i] == '\n') {
            STRLEN end = i;
            if (end > start && s[end - 1] == '\r') end--;
            av_push(lines, newSVpvn(s + start, end - start));
            start = i + 1;
        }
    }
    if (start <= n) {
        av_push(lines, newSVpvn(s + start, n - start));
    }

    I32 len = av_len(lines) + 1;
    if (len > 0) {
        SV **last = av_fetch(lines, len - 1, 0);
        if (last) {
            STRLEN ln;
            const char *ls = SvPV(*last, ln);
            if (ln == 0 || (ln == 1 && (ls[0] == '\r' || ls[0] == '\n'))) {
                av_pop(lines);
            }
        }
    }
    return lines;
}

static AV *line_split_char(SV *sv, char delimiter) {
    STRLEN n;
    const char *s = SvPV(sv, n);
    AV *out = newAV();
    STRLEN start = 0;
    for (STRLEN i = 0; i < n; i++) {
        if (s[i] == delimiter) {
            av_push(out, newSVpvn(s + start, i - start));
            start = i + 1;
        }
    }
    if (start < n) {
        av_push(out, newSVpvn(s + start, n - start));
    } else if (n == 0) {
        /* keep empty -> [] behavior like Perl split on empty string */
    }
    return out;
}

static int line_is_empty_or_ws(SV *sv) {
    STRLEN n;
    const char *s = SvPV(sv, n);
    for (STRLEN i = 0; i < n; i++) {
        if (!(s[i] == ' ' || s[i] == '\t' || s[i] == '\r' || s[i] == '\n')) return 0;
    }
    return 1;
}

static int line_parse_root_array_header(SV *trimmed, IV *count, char *delim, SV **rest) {
    STRLEN n;
    const char *s = SvPV(trimmed, n);
    if (n < 4 || s[0] != '[') return 0;
    STRLEN i = 1;
    STRLEN dstart = i;
    while (i < n && isdigit((unsigned char)s[i])) i++;
    if (i == dstart) return 0;
    SV *cnt = newSVpvn(s + dstart, i - dstart);
    *count = SvIV(cnt);
    SvREFCNT_dec(cnt);

    *delim = ',';
    if (i < n && (s[i] == '\t' || s[i] == '|')) {
        *delim = s[i];
        i++;
    }
    if (i >= n || s[i] != ']') return 0;
    i++;
    while (i < n && (s[i] == ' ' || s[i] == '\t')) i++;
    if (i >= n || s[i] != ':') return 0;
    i++;
    while (i < n && (s[i] == ' ' || s[i] == '\t')) i++;
    *rest = newSVpvn(s + i, n - i);
    return 1;
}

static SV *line_parse_primitive(SV *value_sv) {
    SV *trimmed = line_trimmed_sv(value_sv);
    STRLEN n;
    const char *s = SvPV(trimmed, n);

    if (n >= 2 && s[0] == '"' && s[n - 1] == '"') {
        SV *out = newSVpvn("", 0);
        for (STRLEN i = 1; i + 1 < n; i++) {
            char c = s[i];
            if (c == '\\' && i + 2 < n) {
                char e = s[++i];
                switch (e) {
                    case '"': sv_catpvn(out, "\"", 1); break;
                    case '\\': sv_catpvn(out, "\\", 1); break;
                    case 'n': sv_catpvn(out, "\n", 1); break;
                    case 'r': sv_catpvn(out, "\r", 1); break;
                    case 't': sv_catpvn(out, "\t", 1); break;
                    default:
                        sv_catpvn(out, "\\", 1);
                        sv_catpvn(out, &e, 1);
                        break;
                }
            } else {
                sv_catpvn(out, &c, 1);
            }
        }
        SvREFCNT_dec(trimmed);
        return out;
    }

    if (n == 4 && strncmp(s, "null", 4) == 0) {
        SvREFCNT_dec(trimmed);
        return newSV(0);
    }
    if (n == 4 && strncmp(s, "true", 4) == 0) {
        SvREFCNT_dec(trimmed);
        return newSViv(1);
    }
    if (n == 5 && strncmp(s, "false", 5) == 0) {
        SvREFCNT_dec(trimmed);
        return newSViv(0);
    }

    if (is_numeric_token(s, n)) {
        STRLEN i = 0;
        if (i < n && (s[i] == '+' || s[i] == '-')) i++;
        if (i + 1 < n && s[i] == '0' && isdigit((unsigned char)s[i + 1])) {
            if (!(i + 1 < n && s[i + 1] == '.')) {
                SV *as_str = newSVsv(trimmed);
                SvREFCNT_dec(trimmed);
                return as_str;
            }
        }

        int has_float = (memchr(s, '.', n) || memchr(s, 'e', n) || memchr(s, 'E', n)) ? 1 : 0;
        if (has_float) {
            NV nv = SvNV(trimmed);
            if (nv == 0.0) {
                SvREFCNT_dec(trimmed);
                return newSViv(0);
            }
            char buf[64];
            snprintf(buf, sizeof(buf), "%.15g", (double)nv);
            SV *tmp = newSVpv(buf, 0);
            NV nn = SvNV(tmp);
            SvREFCNT_dec(tmp);
            SvREFCNT_dec(trimmed);
            if ((IV)nn == nn) return newSViv((IV)nn);
            return newSVnv(nn);
        } else {
            IV iv = SvIV(trimmed);
            SvREFCNT_dec(trimmed);
            return newSViv(iv);
        }
    }

    return trimmed;
}

static int line_parse_object_header(SV *trimmed, SV **key, SV **bracket, SV **fields, SV **rest) {
    STRLEN n;
    const char *s = SvPV(trimmed, n);
    STRLEN i = 0;
    if (i >= n || !is_word_char(s[i])) return 0;
    STRLEN kstart = i;
    while (i < n && is_word_char(s[i])) i++;
    *key = newSVpvn(s + kstart, i - kstart);

    *bracket = &PL_sv_undef;
    *fields = &PL_sv_undef;

    if (i < n && s[i] == '[') {
        STRLEN bs = i;
        i++;
        while (i < n && s[i] != ']') i++;
        if (i >= n) return 0;
        i++;
        *bracket = newSVpvn(s + bs, i - bs);
    }

    if (i < n && s[i] == '{') {
        STRLEN fs = i;
        i++;
        while (i < n && s[i] != '}') i++;
        if (i >= n) return 0;
        i++;
        *fields = newSVpvn(s + fs, i - fs);
    }

    while (i < n && (s[i] == ' ' || s[i] == '\t')) i++;
    if (i >= n || s[i] != ':') return 0;
    i++;
    while (i < n && (s[i] == ' ' || s[i] == '\t')) i++;
    *rest = newSVpvn(s + i, n - i);
    return 1;
}

static SV *line_decode_object(line_decode_ctx_t *ctx, I32 target_depth);
static SV *line_decode_array_value(line_decode_ctx_t *ctx, SV *bracket, SV *fields, SV *rest);

static SV *line_decode_object(line_decode_ctx_t *ctx, I32 target_depth) {
    if (target_depth > ctx->max_depth) {
        croak("Maximum nesting depth exceeded (max: %ld)", (long)ctx->max_depth);
    }

    HV *obj = newHV();
    I32 total = av_len(ctx->lines) + 1;
    while (ctx->pos < total) {
        SV **linep = av_fetch(ctx->lines, ctx->pos, 0);
        if (!linep) { ctx->pos++; continue; }
        if (line_is_empty_or_ws(*linep)) { ctx->pos++; continue; }

        I32 depth = line_depth_from_sv(*linep);
        if (depth < target_depth) break;
        if (depth > target_depth + 1) { ctx->pos++; continue; }
        if (depth > target_depth) break;

        ctx->pos++;
        SV *trim = line_ltrimmed_sv(*linep);
        SV *key = &PL_sv_undef, *br = &PL_sv_undef, *fs = &PL_sv_undef, *rest = &PL_sv_undef;
        int ok = line_parse_object_header(trim, &key, &br, &fs, &rest);
        SvREFCNT_dec(trim);
        if (!ok) {
            if (key != &PL_sv_undef) SvREFCNT_dec(key);
            continue;
        }

        SV *value;
        if (br != &PL_sv_undef) {
            value = line_decode_array_value(ctx, br, fs, rest);
        } else {
            if (SvCUR(rest) == 0) {
                value = line_decode_object(ctx, target_depth + 1);
            } else {
                value = line_parse_primitive(rest);
            }
        }

        STRLEN kn;
        const char *ks = SvPV(key, kn);
        hv_store(obj, ks, (I32)kn, value, 0);

        SvREFCNT_dec(key);
        if (br != &PL_sv_undef) SvREFCNT_dec(br);
        if (fs != &PL_sv_undef) SvREFCNT_dec(fs);
        SvREFCNT_dec(rest);
    }
    return newRV_noinc((SV*)obj);
}

static int line_parse_bracket_info(SV *bracket, IV *count, char *delimiter) {
    STRLEN n;
    const char *s = SvPV(bracket, n);
    if (n < 3 || s[0] != '[') return 0;
    STRLEN i = 1;
    STRLEN start = i;
    while (i < n && isdigit((unsigned char)s[i])) i++;
    if (i == start) return 0;
    SV *cnt = newSVpvn(s + start, i - start);
    *count = SvIV(cnt);
    SvREFCNT_dec(cnt);
    *delimiter = ',';
    if (i < n && (s[i] == '\t' || s[i] == '|')) {
        *delimiter = s[i];
        i++;
    }
    if (i >= n || s[i] != ']') return 0;
    return 1;
}

static SV *line_decode_array_value(line_decode_ctx_t *ctx, SV *bracket, SV *fields, SV *rest) {
    IV count = 0;
    char delimiter = ',';
    if (!line_parse_bracket_info(bracket, &count, &delimiter)) {
        return newRV_noinc((SV*)newAV());
    }

    if (fields != &PL_sv_undef) {
        STRLEN fn;
        const char *fs = SvPV(fields, fn);
        if (fn < 2) return newRV_noinc((SV*)newAV());
        SV *fields_inner = newSVpvn(fs + 1, fn - 2);
        AV *field_names = line_split_char(fields_inner, delimiter);
        SvREFCNT_dec(fields_inner);

        AV *rows = newAV();
        I32 total = av_len(ctx->lines) + 1;
        while (ctx->pos < total) {
            SV **linep = av_fetch(ctx->lines, ctx->pos, 0);
            if (!linep) { ctx->pos++; continue; }
            if (line_is_empty_or_ws(*linep)) { ctx->pos++; continue; }

            I32 depth = line_depth_from_sv(*linep);
            if (depth <= 0) break;

            SV *trim = line_ltrimmed_sv(*linep);
            STRLEN tn; const char *ts = SvPV(trim, tn);
            if (tn >= 1 && ts[0] == '-') {
                SvREFCNT_dec(trim);
                break;
            }

            ctx->pos++;
            AV *vals = line_split_char(trim, delimiter);
            HV *row = newHV();

            I32 nf = av_len(field_names) + 1;
            I32 nv = av_len(vals) + 1;
            for (I32 i = 0; i < nf && i < nv; i++) {
                SV **f = av_fetch(field_names, i, 0);
                SV **v = av_fetch(vals, i, 0);
                SV *pv = line_parse_primitive(*v);
                STRLEN klen; const char *k = SvPV(*f, klen);
                hv_store(row, k, (I32)klen, pv, 0);
            }

            av_push(rows, newRV_noinc((SV*)row));
            SvREFCNT_dec((SV*)vals);
            SvREFCNT_dec(trim);
        }

        SvREFCNT_dec((SV*)field_names);
        return newRV_noinc((SV*)rows);
    }

    int has_list = 0;
    I32 peek = ctx->pos;
    I32 total = av_len(ctx->lines) + 1;
    while (peek < total) {
        SV **linep = av_fetch(ctx->lines, peek, 0);
        if (!linep) { peek++; continue; }
        if (line_is_empty_or_ws(*linep)) { peek++; continue; }
        I32 d = line_depth_from_sv(*linep);
        if (d <= 0) break;
        SV *trim = line_ltrimmed_sv(*linep);
        STRLEN tn; const char *ts = SvPV(trim, tn);
        if (tn >= 1 && ts[0] == '-') has_list = 1;
        SvREFCNT_dec(trim);
        break;
    }

    if (has_list) {
        AV *items = newAV();
        while (ctx->pos < total) {
            SV **linep = av_fetch(ctx->lines, ctx->pos, 0);
            if (!linep) { ctx->pos++; continue; }
            if (line_is_empty_or_ws(*linep)) { ctx->pos++; continue; }

            I32 depth = line_depth_from_sv(*linep);
            if (depth <= 0) break;
            SV *trim = line_ltrimmed_sv(*linep);
            STRLEN tn; const char *ts = SvPV(trim, tn);

            if (!(tn >= 2 && ts[0] == '-' && ts[1] == ' ')) {
                SvREFCNT_dec(trim);
                break;
            }
            ctx->pos++;
            SV *item_content = newSVpvn(ts + 2, tn - 2);
            SV *item_trim = line_trimmed_sv(item_content);
            SvREFCNT_dec(item_content);

            SV *key = &PL_sv_undef, *br = &PL_sv_undef, *fs = &PL_sv_undef, *restv = &PL_sv_undef;
            if (line_parse_object_header(item_trim, &key, &br, &fs, &restv) && br == &PL_sv_undef) {
                HV *item = newHV();
                SV *first_val;
                if (SvCUR(restv) == 0) {
                    first_val = line_decode_object(ctx, depth + 2);
                } else {
                    first_val = line_parse_primitive(restv);
                }
                STRLEN kn; const char *ks = SvPV(key, kn);
                hv_store(item, ks, (I32)kn, first_val, 0);

                while (ctx->pos < total) {
                    SV **nextp = av_fetch(ctx->lines, ctx->pos, 0);
                    if (!nextp) { ctx->pos++; continue; }
                    if (line_is_empty_or_ws(*nextp)) { ctx->pos++; continue; }
                    I32 nd = line_depth_from_sv(*nextp);
                    if (nd < depth + 1 || nd > depth + 1) break;
                    SV *ntrim = line_ltrimmed_sv(*nextp);
                    STRLEN nn; const char *ns = SvPV(ntrim, nn);
                    if (nn >= 1 && ns[0] == '-') { SvREFCNT_dec(ntrim); break; }

                    SV *k2 = &PL_sv_undef, *b2 = &PL_sv_undef, *f2 = &PL_sv_undef, *r2 = &PL_sv_undef;
                    if (!line_parse_object_header(ntrim, &k2, &b2, &f2, &r2) || b2 != &PL_sv_undef) {
                        if (k2 != &PL_sv_undef) SvREFCNT_dec(k2);
                        SvREFCNT_dec(ntrim);
                        break;
                    }
                    ctx->pos++;
                    SV *pv = line_parse_primitive(r2);
                    STRLEN k2n; const char *k2s = SvPV(k2, k2n);
                    hv_store(item, k2s, (I32)k2n, pv, 0);
                    SvREFCNT_dec(k2);
                    SvREFCNT_dec(r2);
                    SvREFCNT_dec(ntrim);
                }

                av_push(items, newRV_noinc((SV*)item));
                SvREFCNT_dec(key);
                SvREFCNT_dec(restv);
            } else {
                SV *pv = line_parse_primitive(item_trim);
                av_push(items, pv);
                if (key != &PL_sv_undef) SvREFCNT_dec(key);
                if (restv != &PL_sv_undef) SvREFCNT_dec(restv);
            }
            SvREFCNT_dec(item_trim);
        }
        return newRV_noinc((SV*)items);
    }

    AV *vals = line_split_char(rest, delimiter);
    AV *out = newAV();
    I32 nv = av_len(vals) + 1;
    for (I32 i = 0; i < nv; i++) {
        SV **v = av_fetch(vals, i, 0);
        av_push(out, line_parse_primitive(*v));
    }
    SvREFCNT_dec((SV*)vals);
    return newRV_noinc((SV*)out);
}

static SV *xs_decode_line_impl(SV *text_sv, SV *opts_sv) {
    line_decode_ctx_t ctx;
    ctx.lines = line_split_lines(text_sv);
    ctx.pos = 0;
    ctx.max_depth = 100;

    if (opts_sv && SvOK(opts_sv) && SvROK(opts_sv) && SvTYPE(SvRV(opts_sv)) == SVt_PVHV) {
        HV *hv = (HV*)SvRV(opts_sv);
        SV **md = hv_fetch(hv, "max_depth", 9, 0);
        if (md) ctx.max_depth = (I32)SvIV(*md);
    }

    AV *non_empty = newAV();
    I32 total = av_len(ctx.lines) + 1;
    for (I32 i = 0; i < total; i++) {
        SV **linep = av_fetch(ctx.lines, i, 0);
        if (!linep || line_is_empty_or_ws(*linep)) continue;
        if (line_depth_from_sv(*linep) != 0) continue;
        av_push(non_empty, newSVsv(*linep));
    }

    I32 nn = av_len(non_empty) + 1;
    if (nn <= 0) {
        SvREFCNT_dec((SV*)non_empty);
        SvREFCNT_dec((SV*)ctx.lines);
        return newRV_noinc((SV*)newHV());
    }

    SV **firstp = av_fetch(non_empty, 0, 0);
    SV *first_trim = line_trimmed_sv(*firstp);

    IV count = 0;
    char delimiter = ',';
    SV *rest = &PL_sv_undef;
    if (line_parse_root_array_header(first_trim, &count, &delimiter, &rest)) {
        if (SvCUR(rest) > 0) {
            AV *vals = line_split_char(rest, delimiter);
            AV *out = newAV();
            I32 nv = av_len(vals) + 1;
            for (I32 i = 0; i < nv; i++) {
                SV **v = av_fetch(vals, i, 0);
                av_push(out, line_parse_primitive(*v));
            }
            SvREFCNT_dec((SV*)vals);
            SvREFCNT_dec(rest);
            SvREFCNT_dec(first_trim);
            SvREFCNT_dec((SV*)non_empty);
            SvREFCNT_dec((SV*)ctx.lines);
            return newRV_noinc((SV*)out);
        }
        SvREFCNT_dec(rest);
        ctx.pos = 0;
        AV *items = newAV();
        while (ctx.pos < total) {
            SV **linep = av_fetch(ctx.lines, ctx.pos, 0);
            if (!linep || line_is_empty_or_ws(*linep)) { ctx.pos++; continue; }
            I32 d = line_depth_from_sv(*linep);
            if (d == 0) {
                SV *trim = line_ltrimmed_sv(*linep);
                STRLEN tn; const char *ts = SvPV(trim, tn);
                SvREFCNT_dec(trim);
                if (tn >= 1 && ts[0] == '[') { ctx.pos++; continue; }
            } else if (d > 0) {
                SV *trim = line_ltrimmed_sv(*linep);
                STRLEN tn; const char *ts = SvPV(trim, tn);
                if (tn >= 1 && ts[0] == '-') {
                    ctx.pos++;
                    SV *ic = newSVpvn(ts + 1, tn - 1);
                    av_push(items, line_parse_primitive(ic));
                    SvREFCNT_dec(ic);
                    SvREFCNT_dec(trim);
                    continue;
                }
                SvREFCNT_dec(trim);
            }
            ctx.pos++;
        }
        SvREFCNT_dec(first_trim);
        SvREFCNT_dec((SV*)non_empty);
        SvREFCNT_dec((SV*)ctx.lines);
        return newRV_noinc((SV*)items);
    }

    STRLEN fn; const char *fs = SvPV(first_trim, fn);
    int first_word_bracket = 0;
    for (STRLEN i = 0; i < fn; i++) {
        if (fs[i] == '[') { first_word_bracket = 1; break; }
        if (fs[i] == ':' || fs[i] == ' ') break;
    }

    SV *result;
    if (first_word_bracket) {
        ctx.pos = 0;
        result = line_decode_object(&ctx, 0);
    } else if (nn == 1 && !memchr(fs, ':', fn)) {
        result = line_parse_primitive(first_trim);
    } else {
        ctx.pos = 0;
        result = line_decode_object(&ctx, 0);
    }

    SvREFCNT_dec(first_trim);
    SvREFCNT_dec((SV*)non_empty);
    SvREFCNT_dec((SV*)ctx.lines);
    return result;
}

static int line_needs_quoting(SV *sv, char delimiter) {
    STRLEN n;
    const char *s = SvPV(sv, n);
    if (n == 0) return 1;
    if (s[0] == ' ' || s[n - 1] == ' ') return 1;
    if ((n == 4 && strncmp(s, "true", 4) == 0) ||
        (n == 5 && strncmp(s, "false", 5) == 0) ||
        (n == 4 && strncmp(s, "null", 4) == 0)) return 1;
    if (is_numeric_token(s, n)) return 1;
    if (n >= 2 && s[0] == '0' && isdigit((unsigned char)s[1])) return 1;
    for (STRLEN i = 0; i < n; i++) {
        char c = s[i];
        if (c == ':' || c == '"' || c == '\\' || c == '[' || c == ']' || c == '{' || c == '}' || c == '-' ||
            c == '\r' || c == '\n' || c == '\t' || c == delimiter) return 1;
    }
    if (s[0] == '-') return 1;
    return 0;
}

static SV *line_escape_string(SV *sv) {
    STRLEN n;
    const char *s = SvPV(sv, n);
    SV *out = newSVpvn("", 0);
    for (STRLEN i = 0; i < n; i++) {
        char c = s[i];
        switch (c) {
            case '\\': sv_catpvn(out, "\\\\", 2); break;
            case '"': sv_catpvn(out, "\\\"", 2); break;
            case '\n': sv_catpvn(out, "\\n", 2); break;
            case '\r': sv_catpvn(out, "\\r", 2); break;
            case '\t': sv_catpvn(out, "\\t", 2); break;
            default: sv_catpvn(out, &c, 1); break;
        }
    }
    return out;
}

static SV *line_encode_primitive(SV *value, char delimiter) {
    if (!SvOK(value)) return newSVpv("null", 0);

    if (sv_is_plain_numberish(value)) {
        NV nv = SvNV(value);
        if (nv == 0.0) return newSVpv("0", 0);
        if (SvIOK(value) && !SvNOK(value)) return newSViv(SvIV(value));
        char buf[64];
        snprintf(buf, sizeof(buf), "%.15g", (double)nv);
        return newSVpv(buf, 0);
    }

    if (line_needs_quoting(value, delimiter)) {
        SV *esc = line_escape_string(value);
        SV *out = newSVpv("\"", 0);
        sv_catpv(out, SvPV_nolen(esc));
        sv_catpvn(out, "\"", 1);
        SvREFCNT_dec(esc);
        return out;
    }
    return newSVsv(value);
}

static IV line_priority_rank(line_encode_ctx_t *ctx, SV *key) {
    if (!ctx->priority) return 999999;
    STRLEN n; const char *s = SvPV(key, n);
    SV **v = hv_fetch(ctx->priority, s, (I32)n, 0);
    if (!v) return 999999;
    return SvIV(*v);
}

static AV *line_sorted_keys(HV *hv, line_encode_ctx_t *ctx) {
    I32 count = hv_iterinit(hv);
    SV **arr = (SV**)safemalloc(sizeof(SV*) * (count > 0 ? count : 1));
    I32 idx = 0;
    HE *he;
    while ((he = hv_iternext(hv)) != NULL) {
        arr[idx++] = newSVsv(hv_iterkeysv(he));
    }

    for (I32 i = 0; i < idx; i++) {
        for (I32 j = i + 1; j < idx; j++) {
            IV ri = line_priority_rank(ctx, arr[i]);
            IV rj = line_priority_rank(ctx, arr[j]);
            int swap = 0;
            if (ri != rj) {
                swap = ri > rj;
            } else {
                STRLEN ni, nj;
                const char *si = SvPV(arr[i], ni);
                const char *sj = SvPV(arr[j], nj);
                STRLEN mn = ni < nj ? ni : nj;
                int c = memcmp(si, sj, mn);
                if (c == 0) c = (ni < nj) ? -1 : ((ni > nj) ? 1 : 0);
                swap = c > 0;
            }
            if (swap) {
                SV *tmp = arr[i];
                arr[i] = arr[j];
                arr[j] = tmp;
            }
        }
    }

    AV *keys = newAV();
    for (I32 i = 0; i < idx; i++) {
        av_push(keys, arr[i]);
    }
    safefree(arr);
    return keys;
}

static void line_append_line(SV *out, SV *line, int *first) {
    if (!*first) sv_catpvn(out, "\n", 1);
    *first = 0;
    sv_catpv(out, SvPV_nolen(line));
}

static SV *line_encode_value(line_encode_ctx_t *ctx, SV *value);

static SV *line_encode_array(line_encode_ctx_t *ctx, AV *arr) {
    I32 n = av_len(arr) + 1;
    int all_prims = 1;
    for (I32 i = 0; i < n; i++) {
        SV **it = av_fetch(arr, i, 0);
        if (it && SvROK(*it)) { all_prims = 0; break; }
    }

    if (all_prims) {
        SV *out = newSVpvf("[%ld", (long)n);
        if (ctx->delimiter == '\t') sv_catpvn(out, "\t", 1);
        else if (ctx->delimiter == '|') sv_catpvn(out, "|", 1);
        sv_catpvn(out, "]: ", 3);
        for (I32 i = 0; i < n; i++) {
            if (i > 0) {
                char d = ctx->delimiter;
                sv_catpvn(out, &d, 1);
            }
            SV **it = av_fetch(arr, i, 0);
            SV *p = line_encode_primitive(*it, ctx->delimiter);
            sv_catpv(out, SvPV_nolen(p));
            SvREFCNT_dec(p);
        }
        return out;
    }

    SV *out = newSVpvf("[%ld]:", (long)n);
    for (I32 i = 0; i < n; i++) {
        SV **it = av_fetch(arr, i, 0);
        SV *enc = line_encode_value(ctx, *it);
        if (SvOK(enc) && SvCUR(enc) > 0) {
            sv_catpvn(out, "\n  - ", 5);
            sv_catpv(out, SvPV_nolen(enc));
        }
        SvREFCNT_dec(enc);
    }
    return out;
}

static SV *line_encode_object_with_array(line_encode_ctx_t *ctx, const char *indent, SV *key, AV *arr) {
    I32 n = av_len(arr) + 1;
    int all_objects = (n > 0);
    for (I32 i = 0; i < n; i++) {
        SV **it = av_fetch(arr, i, 0);
        if (!it || !SvROK(*it) || SvTYPE(SvRV(*it)) != SVt_PVHV) { all_objects = 0; break; }
    }

    SV *out = newSVpvn("", 0);
    STRLEN kn; const char *ks = SvPV(key, kn);

    if (all_objects && n > 0) {
        HV *first = (HV*)SvRV(*av_fetch(arr, 0, 0));
        AV *first_keys = line_sorted_keys(first, ctx);
        I32 nk = av_len(first_keys) + 1;
        int can_tabular = 1;

        for (I32 i = 0; i < n && can_tabular; i++) {
            HV *row = (HV*)SvRV(*av_fetch(arr, i, 0));
            AV *rk = line_sorted_keys(row, ctx);
            if (av_len(rk) + 1 != nk) can_tabular = 0;
            for (I32 j = 0; j < nk && can_tabular; j++) {
                SV **a = av_fetch(first_keys, j, 0);
                SV **b = av_fetch(rk, j, 0);
                STRLEN an,bn; const char *as = SvPV(*a, an); const char *bs = SvPV(*b, bn);
                if (an != bn || memcmp(as, bs, an) != 0) can_tabular = 0;
            }
            hv_iterinit(row); HE *he;
            while ((he = hv_iternext(row)) != NULL) {
                SV *v = hv_iterval(row, he);
                if (SvROK(v)) { can_tabular = 0; break; }
            }
            SvREFCNT_dec((SV*)rk);
        }

        if (can_tabular) {
            sv_catpvf(out, "%s%s[%ld", indent, ks, (long)n);
            if (ctx->delimiter == '\t') sv_catpvn(out, "\t", 1);
            else if (ctx->delimiter == '|') sv_catpvn(out, "|", 1);
            sv_catpvn(out, "]{", 2);
            for (I32 i = 0; i < nk; i++) {
                if (i > 0) {
                    char d = ctx->delimiter;
                    sv_catpvn(out, &d, 1);
                }
                SV **f = av_fetch(first_keys, i, 0);
                sv_catpv(out, SvPV_nolen(*f));
            }
            sv_catpvn(out, "}:", 2);

            ctx->depth++;
            SV *row_indent = newSVpvn("", 0);
            for (I32 x = 0; x < ctx->depth * ctx->indent; x++) sv_catpvn(row_indent, " ", 1);
            for (I32 i = 0; i < n; i++) {
                HV *row = (HV*)SvRV(*av_fetch(arr, i, 0));
                sv_catpvn(out, "\n", 1);
                sv_catpv(out, SvPV_nolen(row_indent));
                for (I32 j = 0; j < nk; j++) {
                    if (j > 0) {
                        char d = ctx->delimiter;
                        sv_catpvn(out, &d, 1);
                    }
                    SV **f = av_fetch(first_keys, j, 0);
                    STRLEN fn; const char *fname = SvPV(*f, fn);
                    SV **v = hv_fetch(row, fname, (I32)fn, 0);
                    SV *pv = line_encode_primitive(*v, ctx->delimiter);
                    sv_catpv(out, SvPV_nolen(pv));
                    SvREFCNT_dec(pv);
                }
            }
            SvREFCNT_dec(row_indent);
            ctx->depth--;
            SvREFCNT_dec((SV*)first_keys);
            return out;
        }
        SvREFCNT_dec((SV*)first_keys);
    }

    sv_catpvf(out, "%s%s[%ld]:", indent, ks, (long)n);
    ctx->depth++;
    SV *item_indent = newSVpvn("", 0);
    for (I32 x = 0; x < ctx->depth * ctx->indent; x++) sv_catpvn(item_indent, " ", 1);
    SV *field_indent = newSVpvn("", 0);
    for (I32 x = 0; x < (ctx->depth + 1) * ctx->indent; x++) sv_catpvn(field_indent, " ", 1);

    if (all_objects && n > 0) {
        for (I32 i = 0; i < n; i++) {
            HV *row = (HV*)SvRV(*av_fetch(arr, i, 0));
            AV *keys = line_sorted_keys(row, ctx);
            I32 nk = av_len(keys) + 1;
            if (nk > 0) {
                SV **k0 = av_fetch(keys, 0, 0);
                STRLEN k0n; const char *k0s = SvPV(*k0, k0n);
                SV **v0 = hv_fetch(row, k0s, (I32)k0n, 0);
                ctx->depth++;
                SV *fv = line_encode_value(ctx, *v0);
                ctx->depth--;
                sv_catpvn(out, "\n", 1);
                sv_catpv(out, SvPV_nolen(item_indent));
                sv_catpvf(out, "- %s: %s", k0s, SvPV_nolen(fv));
                SvREFCNT_dec(fv);
                for (I32 j = 1; j < nk; j++) {
                    SV **kj = av_fetch(keys, j, 0);
                    STRLEN kjn; const char *kjs = SvPV(*kj, kjn);
                    SV **vj = hv_fetch(row, kjs, (I32)kjn, 0);
                    SV *ev = line_encode_value(ctx, *vj);
                    sv_catpvn(out, "\n", 1);
                    sv_catpv(out, SvPV_nolen(field_indent));
                    sv_catpvf(out, "%s: %s", kjs, SvPV_nolen(ev));
                    SvREFCNT_dec(ev);
                }
            } else {
                sv_catpvn(out, "\n", 1);
                sv_catpv(out, SvPV_nolen(item_indent));
                sv_catpvn(out, "-", 1);
            }
            SvREFCNT_dec((SV*)keys);
        }
    } else {
        for (I32 i = 0; i < n; i++) {
            SV **it = av_fetch(arr, i, 0);
            SV *ev = line_encode_value(ctx, *it);
            if (SvOK(ev) && SvCUR(ev) > 0) {
                sv_catpvn(out, "\n", 1);
                sv_catpv(out, SvPV_nolen(item_indent));
                sv_catpvf(out, "- %s", SvPV_nolen(ev));
            }
            SvREFCNT_dec(ev);
        }
    }

    SvREFCNT_dec(item_indent);
    SvREFCNT_dec(field_indent);
    ctx->depth--;
    return out;
}

static SV *line_encode_hash(line_encode_ctx_t *ctx, HV *hv) {
    if (ctx->depth >= ctx->max_depth) {
        croak("Maximum nesting depth exceeded (max: %ld)", (long)ctx->max_depth);
    }
    SV *out = newSVpvn("", 0);
    AV *keys = line_sorted_keys(hv, ctx);
    I32 nk = av_len(keys) + 1;
    int first = 1;
    SV *indent = newSVpvn("", 0);
    for (I32 i = 0; i < ctx->depth * ctx->indent; i++) sv_catpvn(indent, " ", 1);

    for (I32 i = 0; i < nk; i++) {
        SV **k = av_fetch(keys, i, 0);
        STRLEN kn; const char *ks = SvPV(*k, kn);
        SV **v = hv_fetch(hv, ks, (I32)kn, 0);
        if (!v) continue;
        SV *val = *v;

        SV *line;
        if (SvROK(val) && SvTYPE(SvRV(val)) == SVt_PVAV) {
            line = line_encode_object_with_array(ctx, SvPV_nolen(indent), *k, (AV*)SvRV(val));
        } else if (SvROK(val) && SvTYPE(SvRV(val)) == SVt_PVHV) {
            line = newSVpvf("%s%s:", SvPV_nolen(indent), ks);
            line_append_line(out, line, &first);
            SvREFCNT_dec(line);
            ctx->depth++;
            SV *nested = line_encode_hash(ctx, (HV*)SvRV(val));
            ctx->depth--;
            line_append_line(out, nested, &first);
            SvREFCNT_dec(nested);
            continue;
        } else {
            SV *pv = line_encode_primitive(val, ctx->delimiter);
            line = newSVpvf("%s%s: %s", SvPV_nolen(indent), ks, SvPV_nolen(pv));
            SvREFCNT_dec(pv);
        }
        line_append_line(out, line, &first);
        SvREFCNT_dec(line);
    }

    SvREFCNT_dec(indent);
    SvREFCNT_dec((SV*)keys);
    return out;
}

static SV *line_encode_value(line_encode_ctx_t *ctx, SV *value) {
    if (!SvOK(value)) return newSV(0);
    if (SvROK(value)) {
        SV *rv = SvRV(value);
        char addr[32];
        snprintf(addr, sizeof(addr), "%p", (void*)rv);
        if (hv_exists(ctx->seen, addr, (I32)strlen(addr))) {
            croak("Circular reference detected");
        }
        hv_store(ctx->seen, addr, (I32)strlen(addr), newSViv(1), 0);
        if (ctx->depth > ctx->max_depth) {
            croak("Maximum nesting depth exceeded (max: %ld)", (long)ctx->max_depth);
        }
        if (SvTYPE(rv) == SVt_PVHV) return line_encode_hash(ctx, (HV*)rv);
        if (SvTYPE(rv) == SVt_PVAV) return line_encode_array(ctx, (AV*)rv);
    }
    return line_encode_primitive(value, ctx->delimiter);
}

static void line_parse_encode_opts(SV *opts_sv, line_encode_ctx_t *ctx) {
    ctx->indent = 2;
    ctx->delimiter = ',';
    ctx->depth = 0;
    ctx->max_depth = 100;
    ctx->seen = newHV();
    ctx->priority = NULL;

    if (!opts_sv || !SvOK(opts_sv) || !SvROK(opts_sv) || SvTYPE(SvRV(opts_sv)) != SVt_PVHV) return;
    HV *hv = (HV*)SvRV(opts_sv);
    SV **v;
    v = hv_fetch(hv, "indent", 6, 0); if (v) ctx->indent = SvIV(*v);
    v = hv_fetch(hv, "max_depth", 9, 0); if (v) ctx->max_depth = SvIV(*v);
    v = hv_fetch(hv, "delimiter", 9, 0);
    if (v) {
        STRLEN n; const char *s = SvPV(*v, n);
        if (n > 0) ctx->delimiter = s[0];
    }
    v = hv_fetch(hv, "column_priority", 15, 0);
    if (v && SvROK(*v) && SvTYPE(SvRV(*v)) == SVt_PVAV) {
        AV *arr = (AV*)SvRV(*v);
        ctx->priority = newHV();
        I32 n = av_len(arr) + 1;
        for (I32 i = 0; i < n; i++) {
            SV **col = av_fetch(arr, i, 0);
            if (!col) continue;
            STRLEN cn; const char *cs = SvPV(*col, cn);
            hv_store(ctx->priority, cs, (I32)cn, newSViv(i), 0);
        }
    }
}

static SV *xs_encode_line_impl(SV *data_sv, SV *opts_sv) {
    line_encode_ctx_t ctx;
    line_parse_encode_opts(opts_sv, &ctx);
    SV *out = line_encode_value(&ctx, data_sv);
    if (!SvOK(out)) out = newSVpv("", 0);
    SvREFCNT_dec((SV*)ctx.seen);
    if (ctx.priority) SvREFCNT_dec((SV*)ctx.priority);
    return out;
}

static SV *xs_validate_line_impl(SV *text_sv, SV *opts_sv) {
    int ok = 1;
    ENTER;
    SAVETMPS;
    dSP;
    PUSHMARK(SP);
    XPUSHs(text_sv);
    if (opts_sv && SvOK(opts_sv)) XPUSHs(opts_sv);
    PUTBACK;
    call_pv("TOON::XS::_xs_decode_line", G_EVAL | G_DISCARD);
    SPAGAIN;
    if (SvTRUE(ERRSV)) ok = 0;
    PUTBACK;
    FREETMPS;
    LEAVE;
    return newSViv(ok ? 1 : 0);
}

MODULE = TOON::XS    PACKAGE = TOON::XS

void
_xs_backend_init()
  CODE:
    /* no-op: ensures XS backend is loadable */

SV *
_xs_decode_brace(text)
    SV *text
  CODE:
    RETVAL = xs_decode_brace_impl(text);
  OUTPUT:
    RETVAL

SV *
_xs_encode_brace(data, opts = &PL_sv_undef)
    SV *data
    SV *opts
  CODE:
    RETVAL = xs_encode_brace_impl(data, opts);
  OUTPUT:
    RETVAL

SV *
_xs_decode_line(text, opts = &PL_sv_undef)
    SV *text
    SV *opts
  CODE:
    RETVAL = xs_decode_line_impl(text, opts);
  OUTPUT:
    RETVAL

SV *
_xs_encode_line(data, opts = &PL_sv_undef)
    SV *data
    SV *opts
  CODE:
    RETVAL = xs_encode_line_impl(data, opts);
  OUTPUT:
    RETVAL

SV *
_xs_validate_line(text, opts = &PL_sv_undef)
    SV *text
    SV *opts
  CODE:
    RETVAL = xs_validate_line_impl(text, opts);
  OUTPUT:
    RETVAL
