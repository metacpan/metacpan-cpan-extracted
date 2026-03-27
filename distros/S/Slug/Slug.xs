#include "slug.h"

/* ── Helper: allocate output buffer scaled to input ───────────── */

/* Transliteration can expand (e.g. ß→ss, Æ→AE) so allow 4x growth */
#define SLUG_BUF_SCALE 4

/* ══════════════════════════════════════════════════════════════════
 * Custom ops - bypass XS subroutine dispatch overhead (5.14+)
 * ══════════════════════════════════════════════════════════════════ */

#if PERL_VERSION >= 14

/* ── Macro: generate ck_* check function ─────────────────────── */

#define SLUG_CK(name) \
static OP *slug_ck_##name(pTHX_ OP *o, GV *namegv, SV *protosv) { \
    PERL_UNUSED_ARG(namegv); PERL_UNUSED_ARG(protosv); \
    o->op_ppaddr = pp_slug_##name; return o; \
}

/* ── XOP descriptors ──────────────────────────────────────────── */

static XOP slug_xop_slug, slug_xop_slug_ascii, slug_xop_slug_custom;

/* ── pp_slug: slug($str) or slug($str, $sep) ─────────────────── */

static OP *pp_slug_slug(pTHX) {
    dSP;
    I32 markix = POPMARK;
    I32 ax = markix + 1;
    I32 items = (I32)(SP - PL_stack_base) - markix - 1;
    STRLEN len;
    const char *str;
    const char *sep = "-";
    int sep_len = 1;
    char *buf;
    int out_len;
    SV *result;
    int buf_size;
    slug_opts_t opts = SLUG_OPTS_DEFAULT;

    if (items < 1) croak("slug() requires at least 1 argument");

    str = SvPVutf8(PL_stack_base[ax], len);
    if (items >= 2 && SvOK(PL_stack_base[ax + 1])) {
        STRLEN slen;
        sep = SvPV(PL_stack_base[ax + 1], slen);
        sep_len = (int)slen;
    }

    opts.separator = sep;
    opts.sep_len = sep_len;

    buf_size = (int)(len * SLUG_BUF_SCALE) + sep_len + 1;
    result = newSV(buf_size);
    buf = SvPVX(result);

    out_len = slug_generate(str, (int)len, buf, buf_size, &opts);

    SvCUR_set(result, out_len);
    SvPOK_on(result);

    SP = PL_stack_base + markix;
    mXPUSHs(result);
    PUTBACK;
    return NORMAL;
}
SLUG_CK(slug)

/* ── pp_slug_ascii: slug_ascii($str) ──────────────────────────── */

static OP *pp_slug_slug_ascii(pTHX) {
    dSP;
    I32 markix = POPMARK;
    I32 ax = markix + 1;
    I32 items = (I32)(SP - PL_stack_base) - markix - 1;
    STRLEN len;
    const char *str;
    char *buf;
    int out_len;
    SV *result;
    int buf_size;

    if (items < 1) croak("slug_ascii() requires 1 argument");

    str = SvPVutf8(PL_stack_base[ax], len);

    buf_size = (int)(len * SLUG_BUF_SCALE) + 1;
    result = newSV(buf_size);
    buf = SvPVX(result);

    out_len = slug_transliterate_str(str, (int)len, buf, buf_size);

    SvCUR_set(result, out_len);
    SvPOK_on(result);

    SP = PL_stack_base + markix;
    mXPUSHs(result);
    PUTBACK;
    return NORMAL;
}
SLUG_CK(slug_ascii)

/* ── pp_slug_custom: slug_custom($str, \%opts) ────────────────── */

static OP *pp_slug_slug_custom(pTHX) {
    dSP;
    I32 markix = POPMARK;
    I32 ax = markix + 1;
    I32 items = (I32)(SP - PL_stack_base) - markix - 1;
    STRLEN len;
    const char *str;
    char *buf;
    int out_len;
    SV *result;
    int buf_size;
    slug_opts_t opts = SLUG_OPTS_DEFAULT;
    SV **svp;
    HV *hv;

    if (items < 1) croak("slug_custom() requires at least 1 argument");

    str = SvPVutf8(PL_stack_base[ax], len);

    if (items >= 2 && SvOK(PL_stack_base[ax + 1])) {
        if (!SvROK(PL_stack_base[ax + 1]) ||
            SvTYPE(SvRV(PL_stack_base[ax + 1])) != SVt_PVHV)
            croak("slug_custom() second argument must be a hash reference");

        hv = (HV *)SvRV(PL_stack_base[ax + 1]);

        svp = hv_fetchs(hv, "separator", 0);
        if (svp && SvOK(*svp)) {
            STRLEN slen;
            opts.separator = SvPV(*svp, slen);
            opts.sep_len = (int)slen;
        }
        svp = hv_fetchs(hv, "max_length", 0);
        if (svp && SvOK(*svp)) opts.max_length = SvIV(*svp);
        svp = hv_fetchs(hv, "lowercase", 0);
        if (svp && SvOK(*svp)) opts.lowercase = SvIV(*svp);
        svp = hv_fetchs(hv, "transliterate", 0);
        if (svp && SvOK(*svp)) opts.transliterate = SvIV(*svp);
        svp = hv_fetchs(hv, "trim_separator", 0);
        if (svp && SvOK(*svp)) opts.trim_sep = SvIV(*svp);
    }

    buf_size = (int)(len * SLUG_BUF_SCALE) + opts.sep_len + 1;
    result = newSV(buf_size);
    buf = SvPVX(result);

    out_len = slug_generate(str, (int)len, buf, buf_size, &opts);

    SvCUR_set(result, out_len);
    SvPOK_on(result);

    SP = PL_stack_base + markix;
    mXPUSHs(result);
    PUTBACK;
    return NORMAL;
}
SLUG_CK(slug_custom)

/* ── Registration macros ──────────────────────────────────────── */

#define SLUG_REG_XOP(c_name, desc) \
    XopENTRY_set(&slug_xop_##c_name, xop_name, "slug_" #c_name); \
    XopENTRY_set(&slug_xop_##c_name, xop_desc, desc); \
    Perl_custom_op_register(aTHX_ pp_slug_##c_name, &slug_xop_##c_name);

#define SLUG_REG_CK(perl_name, c_name) { \
    CV *cv = get_cv("Slug::" perl_name, 0); \
    if (cv) cv_set_call_checker(cv, slug_ck_##c_name, (SV *)cv); \
}

static void slug_register_custom_ops(pTHX) {
    SLUG_REG_XOP(slug,       "generate URL slug")
    SLUG_REG_XOP(slug_ascii, "transliterate to ASCII")
    SLUG_REG_XOP(slug_custom,"generate slug with options")

    SLUG_REG_CK("slug",        slug)
    SLUG_REG_CK("slug_ascii",  slug_ascii)
    SLUG_REG_CK("slug_custom", slug_custom)
}

#endif /* PERL_VERSION >= 14 */

/* ══════════════════════════════════════════════════════════════════
 * XS module definition - XSUBs serve as fallbacks for Perl < 5.14
 * ══════════════════════════════════════════════════════════════════ */

MODULE = Slug  PACKAGE = Slug

PROTOTYPES: DISABLE

BOOT:
{
#if PERL_VERSION >= 14
    slug_register_custom_ops(aTHX);
#endif
}

SV *
slug(input, ...)
        SV *input
    CODE:
    {
        STRLEN len;
        const char *str = SvPVutf8(input, len);
        const char *sep = "-";
        int sep_len = 1;
        int buf_size;
        char *buf;
        int out_len;
        slug_opts_t opts = SLUG_OPTS_DEFAULT;

        if (items >= 2 && SvOK(ST(1))) {
            STRLEN slen;
            sep = SvPV(ST(1), slen);
            sep_len = (int)slen;
        }

        opts.separator = sep;
        opts.sep_len = sep_len;

        buf_size = (int)(len * SLUG_BUF_SCALE) + sep_len + 1;
        RETVAL = newSV(buf_size);
        buf = SvPVX(RETVAL);
        out_len = slug_generate(str, (int)len, buf, buf_size, &opts);
        SvCUR_set(RETVAL, out_len);
        SvPOK_on(RETVAL);
    }
    OUTPUT:
        RETVAL

SV *
slug_ascii(input)
        SV *input
    CODE:
    {
        STRLEN len;
        const char *str = SvPVutf8(input, len);
        int buf_size = (int)(len * SLUG_BUF_SCALE) + 1;
        char *buf;
        int out_len;

        RETVAL = newSV(buf_size);
        buf = SvPVX(RETVAL);
        out_len = slug_transliterate_str(str, (int)len, buf, buf_size);
        SvCUR_set(RETVAL, out_len);
        SvPOK_on(RETVAL);
    }
    OUTPUT:
        RETVAL

SV *
slug_custom(input, ...)
        SV *input
    CODE:
    {
        STRLEN len;
        const char *str = SvPVutf8(input, len);
        int buf_size;
        char *buf;
        int out_len;
        slug_opts_t opts = SLUG_OPTS_DEFAULT;

        if (items >= 2 && SvOK(ST(1))) {
            HV *hv;
            SV **svp;
            if (!SvROK(ST(1)) || SvTYPE(SvRV(ST(1))) != SVt_PVHV)
                croak("slug_custom() second argument must be a hash reference");
            hv = (HV *)SvRV(ST(1));

            svp = hv_fetchs(hv, "separator", 0);
            if (svp && SvOK(*svp)) {
                STRLEN slen;
                opts.separator = SvPV(*svp, slen);
                opts.sep_len = (int)slen;
            }
            svp = hv_fetchs(hv, "max_length", 0);
            if (svp && SvOK(*svp)) opts.max_length = SvIV(*svp);
            svp = hv_fetchs(hv, "lowercase", 0);
            if (svp && SvOK(*svp)) opts.lowercase = SvIV(*svp);
            svp = hv_fetchs(hv, "transliterate", 0);
            if (svp && SvOK(*svp)) opts.transliterate = SvIV(*svp);
            svp = hv_fetchs(hv, "trim_separator", 0);
            if (svp && SvOK(*svp)) opts.trim_sep = SvIV(*svp);
        }

        buf_size = (int)(len * SLUG_BUF_SCALE) + opts.sep_len + 1;
        RETVAL = newSV(buf_size);
        buf = SvPVX(RETVAL);
        out_len = slug_generate(str, (int)len, buf, buf_size, &opts);
        SvCUR_set(RETVAL, out_len);
        SvPOK_on(RETVAL);
    }
    OUTPUT:
        RETVAL
