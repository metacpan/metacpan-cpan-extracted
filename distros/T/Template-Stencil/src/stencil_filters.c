/* utf8_to_uvchr_buf is 5.16; ask ppport.h (included from stencil.h) to
 * emit its back-compat implementation into this TU, the only user. */
#define NEED_utf8_to_uvchr_buf

#include "stencil.h"

void stencil_filt_case(pTHX_ SV *in, SV *out, int to_upper)
{
    STRLEN      len;
    const char *p = SvPV(in, len);

    if (!SvUTF8(in)) {
        char  *w;
        STRLEN i;
        SvUPGRADE(out, SVt_PV);
        SvGROW(out, len + 1);
        w = SvPVX(out);
        if (to_upper) {
            for (i = 0; i < len; i++) {
                char c = p[i];
                w[i] = (c >= 'a' && c <= 'z') ? (char)(c - 32) : c;
            }
        } else {
            for (i = 0; i < len; i++) {
                char c = p[i];
                w[i] = (c >= 'A' && c <= 'Z') ? (char)(c + 32) : c;
            }
        }
        w[len] = '\0';
        SvCUR_set(out, len);
        SvPOK_only(out);
        SvUTF8_off(out);
        return;
    }

    {
        /* to_uni_upper/lower write the full (possibly multi-char)
         * mapping as UTF-8 into a scratch buffer */
        const U8 *s   = (const U8 *)p;
        const U8 *end = s + len;
        STRLEN    used = 0;
        U8        tmp[UTF8_MAXBYTES_CASE + 1];
        SvUPGRADE(out, SVt_PV);
        SvGROW(out, len + UTF8_MAXBYTES_CASE + 1);
        while (s < end) {
            STRLEN clen, tlen;
            UV     uv = utf8_to_uvchr_buf(s, end, &clen);
            if (to_upper)
                (void)to_uni_upper(uv, tmp, &tlen);
            else
                (void)to_uni_lower(uv, tmp, &tlen);
            if (SvLEN(out) < used + tlen + 1)
                SvGROW(out, (used + tlen + 1) * 2);
            memcpy(SvPVX(out) + used, tmp, tlen);
            used += tlen;
            s += clen ? clen : 1;
        }
        SvPVX(out)[used] = '\0';
        SvCUR_set(out, used);
        SvPOK_only(out);
        SvUTF8_on(out);
    }
}

void stencil_filt_trim(pTHX_ SV *in, SV *out)
{
    STRLEN      len;
    const char *p = SvPV(in, len);
    const char *e = p + len;
    while (p < e && isSPACE(*p))
        p++;
    while (e > p && isSPACE(e[-1]))
        e--;
    sv_setpvn(out, p, (STRLEN)(e - p));
    if (SvUTF8(in))
        SvUTF8_on(out);
    else
        SvUTF8_off(out);
}

void stencil_filt_html(pTHX_ SV *in, SV *out)
{
    STRLEN      len;
    const char *p = SvPV(in, len);
    stencil_buf b;

    /* attach the buffer machinery to the scratch SV so the escaper's
     * reserve/grow reuses its allocation */
    SvUPGRADE(out, SVt_PV);
    SvGROW(out, len + 32);
    SvPOK_only(out);
    b.sv   = out;
    b.cur  = SvPVX(out);
    b.end  = SvPVX(out) + SvLEN(out) - 1;
    b.utf8 = 0;
#ifdef PERL_IMPLICIT_CONTEXT
    b.perl = aTHX;
#endif
    stencil_dispatch.escape(&b, p, len);
    (void)stencil_buf_done(&b);
    if (SvUTF8(in))
        SvUTF8_on(out);
    else
        SvUTF8_off(out);
}

void stencil_filt_uri(pTHX_ SV *in, SV *out)
{
    static const char hex[] = "0123456789ABCDEF";
    STRLEN      len, i;
    const char *p = SvPV(in, len);
    char       *w;

    SvUPGRADE(out, SVt_PV);
    SvGROW(out, len * 3 + 1);
    SvPOK_only(out);
    /* latin-1-repped high bytes are UTF-8 encoded before percent
     * escaping, so %-sequences are always UTF-8 regardless of the
     * input SV's internal form */
    SvGROW(out, len * 6 + 1);
    w = SvPVX(out);
    for (i = 0; i < len; i++) {
        unsigned char c = (unsigned char)p[i];
        if ((c >= 'A' && c <= 'Z') || (c >= 'a' && c <= 'z')
            || (c >= '0' && c <= '9') || c == '-' || c == '.'
            || c == '_' || c == '~') {
            *w++ = (char)c;
        } else if (c >= 0x80 && !SvUTF8(in)) {
            unsigned char u1 = (unsigned char)(0xC0 | (c >> 6));
            unsigned char u2 = (unsigned char)(0x80 | (c & 0x3F));
            *w++ = '%'; *w++ = hex[u1 >> 4]; *w++ = hex[u1 & 0xF];
            *w++ = '%'; *w++ = hex[u2 >> 4]; *w++ = hex[u2 & 0xF];
        } else {
            *w++ = '%';
            *w++ = hex[c >> 4];
            *w++ = hex[c & 0xF];
        }
    }
    *w = '\0';
    SvCUR_set(out, (STRLEN)(w - SvPVX(out)));
    SvUTF8_off(out); /* pure ASCII by construction */
}

/* fmt: sprintf with exactly one conversion, the shape fmt_check
 * (stencil_compile.c) guaranteed at template compile - so this can scan
 * blind. The format is rewritten on the way through: perl's own length
 * modifiers (IVdf and friends) are spliced in so the value passed always
 * matches the conversion's width on every platform; floats go through a
 * plain double, which is what display formatting wants. */
void stencil_filt_fmt(pTHX_ SV *in, SV *out, const char *fmt, STRLEN flen,
                      int src_utf8)
{
    char        rf[96];             /* rewritten format */
    char        obuf[640];          /* capped by STENCIL_FMT_MAXWID */
    const char *p = fmt, *end = fmt + flen;
    char       *w = rf;
    char        conv = 's';
    int         has_prec = 0;
    int         fmt_hi = 0;         /* a high-bit byte in the literals */
    int         want_utf8;
    int         olen = 0;

    while (p < end) {
        if (((unsigned char)*p) & 0x80) fmt_hi = 1;
        if (*p != '%') { *w++ = *p++; continue; }
        if (p + 1 < end && p[1] == '%') { *w++ = '%'; *w++ = '%'; p += 2; continue; }
        *w++ = *p++;                              /* '%' */
        while (p < end && (*p == '-' || *p == '+' || *p == ' '
                           || *p == '0' || *p == '#'))
            *w++ = *p++;
        while (p < end && *p >= '0' && *p <= '9')
            *w++ = *p++;
        if (p < end && *p == '.') {
            has_prec = 1;
            *w++ = *p++;
            while (p < end && *p >= '0' && *p <= '9')
                *w++ = *p++;
        }
        conv = *p++;
        switch (conv) {
        case 'd': case 'i':
            { const char *m = IVdf; while (*m) *w++ = *m++; }
            break;
        case 'o':
            { const char *m = UVof; while (*m) *w++ = *m++; }
            break;
        case 'u':
            { const char *m = UVuf; while (*m) *w++ = *m++; }
            break;
        case 'x':
            { const char *m = UVxf; while (*m) *w++ = *m++; }
            break;
        case 'X':
            { const char *m = UVXf; while (*m) *w++ = *m++; }
            break;
        default:                                  /* eEfgGs: as written */
            *w++ = conv;
            break;
        }
    }
    *w = '\0';

    want_utf8 = fmt_hi && src_utf8;
    switch (conv) {
    case 'd': case 'i':
        olen = my_snprintf(obuf, sizeof obuf, rf, SvIV(in));
        break;
    case 'o': case 'u': case 'x': case 'X':
        olen = my_snprintf(obuf, sizeof obuf, rf, SvUV(in));
        break;
    case 's': {
        const char *s;
        STRLEN      sl;
        if (SvUTF8(in) || want_utf8) {
            s = SvPVutf8(in, sl);
            want_utf8 = 1;
        }
        else s = SvPV(in, sl);
        olen = my_snprintf(obuf, sizeof obuf, rf, s);
        if (want_utf8 && has_prec) {
            /* a byte-counted precision may have cut the final UTF-8
             * sequence short; strip a trailing incomplete sequence */
            size_t ol = (size_t)(olen < 0 ? 0 : olen);
            size_t st;
            if (ol >= sizeof obuf) ol = strlen(obuf);
            st = ol;
            while (st > 0 && (((unsigned char)obuf[st - 1]) & 0xC0) == 0x80)
                st--;
            if (st > 0 && (((unsigned char)obuf[st - 1]) & 0x80)
                && (size_t)UTF8SKIP(&obuf[st - 1]) != ol - (st - 1)) {
                obuf[st - 1] = '\0';
                olen = (int)(st - 1);
            }
        }
        break;
    }
    default:                                      /* eEfgG */
        /* snprintf, not my_snprintf: on a quadmath perl my_snprintf hands any
         * format that is one bare float spec ("%.2f") to quadmath_snprintf
         * and reads an __float128 from the varargs, so passing a double there
         * panics ("quadmath_snprintf failed") or prints rubbish. Splicing in
         * NVff to match would only move the problem, since the same perl
         * routes "$%.2Qf" - a spec with literal text around it - to vsnprintf,
         * which has no Q modifier. A double and a plain format are well
         * defined everywhere, and display formatting is what this is for. */
        olen = snprintf(obuf, sizeof obuf, rf, (double)SvNV(in));
        break;
    }

    if (olen < 0) olen = 0;
    if ((size_t)olen >= sizeof obuf) olen = (int)(sizeof obuf) - 1;
    sv_setpvn(out, obuf, (STRLEN)olen);
    if (want_utf8) SvUTF8_on(out);
    else           SvUTF8_off(out);
}
