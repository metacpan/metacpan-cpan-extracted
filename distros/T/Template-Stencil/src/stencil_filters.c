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
