#include "sekhmet.h"

/* ══════════════════════════════════════════════════════════════════
 * Custom ops - bypass XS subroutine dispatch overhead (5.14+)
 * ══════════════════════════════════════════════════════════════════ */

#if PERL_VERSION >= 14

/* ── Macro: generate ck_* check function ───────────────────────── */

#define SEKHMET_CK(name) \
static OP *sekhmet_ck_##name(pTHX_ OP *o, GV *namegv, SV *protosv) { \
    PERL_UNUSED_ARG(namegv); PERL_UNUSED_ARG(protosv); \
    o->op_ppaddr = pp_sekhmet_##name; return o; \
}

/* ── XOP descriptors ─────────────────────────────────────────────  */

static XOP sekhmet_xop_ulid, sekhmet_xop_ulid_binary,
           sekhmet_xop_ulid_monotonic, sekhmet_xop_ulid_monotonic_binary,
           sekhmet_xop_ulid_time, sekhmet_xop_ulid_time_ms,
           sekhmet_xop_ulid_to_uuid, sekhmet_xop_uuid_to_ulid,
           sekhmet_xop_ulid_compare, sekhmet_xop_ulid_validate;

/* ── pp_* : Generator ops (no args) ──────────────────────────────  */

/* ulid() → 26-char Crockford string */
static OP *pp_sekhmet_ulid(pTHX) {
    dSP;
    I32 markix = POPMARK;
    unsigned char bin[16];
    char str[27];

    sekhmet_ulid_generate(bin);
    sekhmet_ulid_encode(str, bin);
    str[26] = '\0';

    SP = PL_stack_base + markix;
    XPUSHs(sv_2mortal(newSVpvn(str, 26)));
    PUTBACK;
    return NORMAL;
}
SEKHMET_CK(ulid)

/* ulid_binary() → 16-byte raw SV */
static OP *pp_sekhmet_ulid_binary(pTHX) {
    dSP;
    I32 markix = POPMARK;
    unsigned char bin[16];

    sekhmet_ulid_generate(bin);

    SP = PL_stack_base + markix;
    XPUSHs(sv_2mortal(newSVpvn((const char *)bin, 16)));
    PUTBACK;
    return NORMAL;
}
SEKHMET_CK(ulid_binary)

/* ulid_monotonic() → 26-char Crockford string (uses MY_CXT) */
static OP *pp_sekhmet_ulid_monotonic(pTHX) {
    dSP;
    dMY_CXT;
    I32 markix = POPMARK;
    unsigned char bin[16];
    char str[27];

    sekhmet_ulid_monotonic(bin, &MY_CXT.mono_state);
    sekhmet_ulid_encode(str, bin);
    str[26] = '\0';

    SP = PL_stack_base + markix;
    XPUSHs(sv_2mortal(newSVpvn(str, 26)));
    PUTBACK;
    return NORMAL;
}
SEKHMET_CK(ulid_monotonic)

/* ulid_monotonic_binary() → 16-byte raw SV (uses MY_CXT) */
static OP *pp_sekhmet_ulid_monotonic_binary(pTHX) {
    dSP;
    dMY_CXT;
    I32 markix = POPMARK;
    unsigned char bin[16];

    sekhmet_ulid_monotonic(bin, &MY_CXT.mono_state);

    SP = PL_stack_base + markix;
    XPUSHs(sv_2mortal(newSVpvn((const char *)bin, 16)));
    PUTBACK;
    return NORMAL;
}
SEKHMET_CK(ulid_monotonic_binary)

/* ── pp_* : Utility ops (1-2 args) ───────────────────────────────  */

/* ulid_time(ulid) → NV epoch seconds */
static OP *pp_sekhmet_ulid_time(pTHX) {
    dSP;
    I32 markix = POPMARK;
    I32 ax = markix + 1;
    I32 items = SP - PL_stack_base - markix - 1;
    unsigned char bin[16];
    STRLEN in_len;
    const char *in_str;

    if (items < 1) croak("ulid_time requires 1 argument");

    in_str = SvPV(PL_stack_base[ax], in_len);

    if (in_len == 16) {
        memcpy(bin, in_str, 16);
    } else if (in_len == 26) {
        if (!sekhmet_ulid_decode(bin, in_str, 26))
            croak("Sekhmet: invalid ULID string");
    } else {
        croak("Sekhmet: ulid_time expects 16-byte binary or 26-char string");
    }

    SP = PL_stack_base + markix;
    XPUSHs(sv_2mortal(newSVnv(sekhmet_ulid_time(bin))));
    PUTBACK;
    return NORMAL;
}
SEKHMET_CK(ulid_time)

/* ulid_time_ms(ulid) → IV epoch milliseconds */
static OP *pp_sekhmet_ulid_time_ms(pTHX) {
    dSP;
    I32 markix = POPMARK;
    I32 ax = markix + 1;
    I32 items = SP - PL_stack_base - markix - 1;
    unsigned char bin[16];
    STRLEN in_len;
    const char *in_str;

    if (items < 1) croak("ulid_time_ms requires 1 argument");

    in_str = SvPV(PL_stack_base[ax], in_len);

    if (in_len == 16) {
        memcpy(bin, in_str, 16);
    } else if (in_len == 26) {
        if (!sekhmet_ulid_decode(bin, in_str, 26))
            croak("Sekhmet: invalid ULID string");
    } else {
        croak("Sekhmet: ulid_time_ms expects 16-byte binary or 26-char string");
    }

    SP = PL_stack_base + markix;
    {
        uint64_t ms = sekhmet_ulid_time_ms(bin);
        /* Use NV for large ms values that exceed IV range on 32-bit */
        if (ms > (uint64_t)IV_MAX)
            XPUSHs(sv_2mortal(newSVnv((NV)ms)));
        else
            XPUSHs(sv_2mortal(newSViv((IV)ms)));
    }
    PUTBACK;
    return NORMAL;
}
SEKHMET_CK(ulid_time_ms)

/* ulid_to_uuid(ulid) → UUID string */
static OP *pp_sekhmet_ulid_to_uuid(pTHX) {
    dSP;
    I32 markix = POPMARK;
    I32 ax = markix + 1;
    I32 items = SP - PL_stack_base - markix - 1;
    unsigned char bin[16];
    char uuid_str[37];
    STRLEN in_len;
    const char *in_str;

    if (items < 1) croak("ulid_to_uuid requires 1 argument");

    in_str = SvPV(PL_stack_base[ax], in_len);

    if (in_len == 16) {
        memcpy(bin, in_str, 16);
    } else if (in_len == 26) {
        if (!sekhmet_ulid_decode(bin, in_str, 26))
            croak("Sekhmet: invalid ULID string");
    } else {
        croak("Sekhmet: ulid_to_uuid expects 16-byte binary or 26-char string");
    }

    sekhmet_ulid_to_uuid_str(uuid_str, bin);
    uuid_str[36] = '\0';

    SP = PL_stack_base + markix;
    XPUSHs(sv_2mortal(newSVpvn(uuid_str, 36)));
    PUTBACK;
    return NORMAL;
}
SEKHMET_CK(ulid_to_uuid)

/* uuid_to_ulid(uuid_string) → 26-char ULID */
static OP *pp_sekhmet_uuid_to_ulid(pTHX) {
    dSP;
    I32 markix = POPMARK;
    I32 ax = markix + 1;
    I32 items = SP - PL_stack_base - markix - 1;
    unsigned char bin[16];
    char str[27];
    STRLEN in_len;
    const char *in_str;

    if (items < 1) croak("uuid_to_ulid requires 1 argument");

    in_str = SvPV(PL_stack_base[ax], in_len);

    if (!sekhmet_uuid_to_ulid_bin(bin, in_str, (int)in_len))
        croak("Sekhmet: cannot parse UUID string");

    sekhmet_ulid_encode(str, bin);
    str[26] = '\0';

    SP = PL_stack_base + markix;
    XPUSHs(sv_2mortal(newSVpvn(str, 26)));
    PUTBACK;
    return NORMAL;
}
SEKHMET_CK(uuid_to_ulid)

/* ulid_compare(a, b) → -1/0/1 */
static OP *pp_sekhmet_ulid_compare(pTHX) {
    dSP;
    I32 markix = POPMARK;
    I32 ax = markix + 1;
    I32 items = SP - PL_stack_base - markix - 1;
    unsigned char a[16], b[16];
    STRLEN a_len, b_len;
    const char *a_str, *b_str;
    int cmp;

    if (items < 2) croak("ulid_compare requires 2 arguments");

    a_str = SvPV(PL_stack_base[ax], a_len);
    b_str = SvPV(PL_stack_base[ax + 1], b_len);

    /* Decode first ULID */
    if (a_len == 16) memcpy(a, a_str, 16);
    else if (a_len == 26) {
        if (!sekhmet_ulid_decode(a, a_str, 26))
            croak("Sekhmet: invalid first ULID");
    } else croak("Sekhmet: ulid_compare expects 16-byte binary or 26-char string");

    /* Decode second ULID */
    if (b_len == 16) memcpy(b, b_str, 16);
    else if (b_len == 26) {
        if (!sekhmet_ulid_decode(b, b_str, 26))
            croak("Sekhmet: invalid second ULID");
    } else croak("Sekhmet: ulid_compare expects 16-byte binary or 26-char string");

    cmp = sekhmet_ulid_compare(a, b);

    SP = PL_stack_base + markix;
    XPUSHs(sv_2mortal(newSViv((cmp < 0) ? -1 : (cmp > 0) ? 1 : 0)));
    PUTBACK;
    return NORMAL;
}
SEKHMET_CK(ulid_compare)

/* ulid_validate(str) → 1/0 */
static OP *pp_sekhmet_ulid_validate(pTHX) {
    dSP;
    I32 markix = POPMARK;
    I32 ax = markix + 1;
    I32 items = SP - PL_stack_base - markix - 1;
    STRLEN in_len;
    const char *in_str;

    if (items < 1) croak("ulid_validate requires 1 argument");

    in_str = SvPV(PL_stack_base[ax], in_len);

    SP = PL_stack_base + markix;
    XPUSHs(sv_2mortal(newSViv(sekhmet_ulid_validate(in_str, (int)in_len))));
    PUTBACK;
    return NORMAL;
}
SEKHMET_CK(ulid_validate)

/* ── Registration macros ─────────────────────────────────────────  */

#define SEKHMET_REG_XOP(c_name, desc) \
    XopENTRY_set(&sekhmet_xop_##c_name, xop_name, "sekhmet_" #c_name); \
    XopENTRY_set(&sekhmet_xop_##c_name, xop_desc, desc); \
    Perl_custom_op_register(aTHX_ pp_sekhmet_##c_name, &sekhmet_xop_##c_name);

#define SEKHMET_REG_CK(perl_name, c_name) { \
    CV *cv = get_cv("Sekhmet::" perl_name, 0); \
    if (cv) cv_set_call_checker(cv, sekhmet_ck_##c_name, (SV *)cv); \
}

static void sekhmet_register_custom_ops(pTHX) {
    SEKHMET_REG_XOP(ulid,                  "generate ULID string")
    SEKHMET_REG_XOP(ulid_binary,           "generate ULID binary")
    SEKHMET_REG_XOP(ulid_monotonic,        "generate monotonic ULID string")
    SEKHMET_REG_XOP(ulid_monotonic_binary, "generate monotonic ULID binary")
    SEKHMET_REG_XOP(ulid_time,             "extract ULID timestamp seconds")
    SEKHMET_REG_XOP(ulid_time_ms,          "extract ULID timestamp ms")
    SEKHMET_REG_XOP(ulid_to_uuid,          "convert ULID to UUID")
    SEKHMET_REG_XOP(uuid_to_ulid,          "convert UUID to ULID")
    SEKHMET_REG_XOP(ulid_compare,          "compare two ULIDs")
    SEKHMET_REG_XOP(ulid_validate,         "validate ULID string")

    SEKHMET_REG_CK("ulid",                  ulid)
    SEKHMET_REG_CK("ulid_binary",           ulid_binary)
    SEKHMET_REG_CK("ulid_monotonic",        ulid_monotonic)
    SEKHMET_REG_CK("ulid_monotonic_binary", ulid_monotonic_binary)
    SEKHMET_REG_CK("ulid_time",             ulid_time)
    SEKHMET_REG_CK("ulid_time_ms",          ulid_time_ms)
    SEKHMET_REG_CK("ulid_to_uuid",          ulid_to_uuid)
    SEKHMET_REG_CK("uuid_to_ulid",          uuid_to_ulid)
    SEKHMET_REG_CK("ulid_compare",          ulid_compare)
    SEKHMET_REG_CK("ulid_validate",         ulid_validate)
}

#endif /* PERL_VERSION >= 14 */

/* ══════════════════════════════════════════════════════════════════
 * XS module definition - XSUBs serve as fallbacks for Perl < 5.14
 * ══════════════════════════════════════════════════════════════════ */

MODULE = Sekhmet  PACKAGE = Sekhmet

BOOT:
{
    MY_CXT_INIT;
    memset(&MY_CXT.mono_state, 0, sizeof(sekhmet_monotonic_state_t));
    horus_pool_refill();
#if PERL_VERSION >= 14
    sekhmet_register_custom_ops(aTHX);
#endif
}

#ifdef USE_ITHREADS

void
CLONE(...)
    CODE:
        MY_CXT_CLONE;
        memset(&MY_CXT.mono_state, 0, sizeof(sekhmet_monotonic_state_t));

#endif

SV *
ulid()
    CODE:
    {
        unsigned char bin[16];
        char str[27];
        sekhmet_ulid_generate(bin);
        sekhmet_ulid_encode(str, bin);
        str[26] = '\0';
        RETVAL = newSVpvn(str, 26);
    }
    OUTPUT:
        RETVAL

SV *
ulid_binary()
    CODE:
    {
        unsigned char bin[16];
        sekhmet_ulid_generate(bin);
        RETVAL = newSVpvn((const char *)bin, 16);
    }
    OUTPUT:
        RETVAL

SV *
ulid_monotonic()
    CODE:
    {
        dMY_CXT;
        unsigned char bin[16];
        char str[27];
        sekhmet_ulid_monotonic(bin, &MY_CXT.mono_state);
        sekhmet_ulid_encode(str, bin);
        str[26] = '\0';
        RETVAL = newSVpvn(str, 26);
    }
    OUTPUT:
        RETVAL

SV *
ulid_monotonic_binary()
    CODE:
    {
        dMY_CXT;
        unsigned char bin[16];
        sekhmet_ulid_monotonic(bin, &MY_CXT.mono_state);
        RETVAL = newSVpvn((const char *)bin, 16);
    }
    OUTPUT:
        RETVAL

NV
ulid_time(input)
        SV *input
    CODE:
    {
        unsigned char bin[16];
        STRLEN in_len;
        const char *in_str = SvPV(input, in_len);

        if (in_len == 16) {
            memcpy(bin, in_str, 16);
        } else if (in_len == 26) {
            if (!sekhmet_ulid_decode(bin, in_str, 26))
                croak("Sekhmet: invalid ULID string");
        } else {
            croak("Sekhmet: ulid_time expects 16-byte binary or 26-char string");
        }

        RETVAL = sekhmet_ulid_time(bin);
    }
    OUTPUT:
        RETVAL

SV *
ulid_time_ms(input)
        SV *input
    CODE:
    {
        unsigned char bin[16];
        STRLEN in_len;
        const char *in_str = SvPV(input, in_len);

        if (in_len == 16) {
            memcpy(bin, in_str, 16);
        } else if (in_len == 26) {
            if (!sekhmet_ulid_decode(bin, in_str, 26))
                croak("Sekhmet: invalid ULID string");
        } else {
            croak("Sekhmet: ulid_time_ms expects 16-byte binary or 26-char string");
        }

        {
            uint64_t ms = sekhmet_ulid_time_ms(bin);
            if (ms > (uint64_t)IV_MAX)
                RETVAL = newSVnv((NV)ms);
            else
                RETVAL = newSViv((IV)ms);
        }
    }
    OUTPUT:
        RETVAL

SV *
ulid_to_uuid(input)
        SV *input
    CODE:
    {
        unsigned char bin[16];
        char uuid_str[37];
        STRLEN in_len;
        const char *in_str = SvPV(input, in_len);

        if (in_len == 16) {
            memcpy(bin, in_str, 16);
        } else if (in_len == 26) {
            if (!sekhmet_ulid_decode(bin, in_str, 26))
                croak("Sekhmet: invalid ULID string");
        } else {
            croak("Sekhmet: ulid_to_uuid expects 16-byte binary or 26-char string");
        }

        sekhmet_ulid_to_uuid_str(uuid_str, bin);
        uuid_str[36] = '\0';
        RETVAL = newSVpvn(uuid_str, 36);
    }
    OUTPUT:
        RETVAL

SV *
uuid_to_ulid(input)
        SV *input
    CODE:
    {
        unsigned char bin[16];
        char str[27];
        STRLEN in_len;
        const char *in_str = SvPV(input, in_len);

        if (!sekhmet_uuid_to_ulid_bin(bin, in_str, (int)in_len))
            croak("Sekhmet: cannot parse UUID string");

        sekhmet_ulid_encode(str, bin);
        str[26] = '\0';
        RETVAL = newSVpvn(str, 26);
    }
    OUTPUT:
        RETVAL

int
ulid_compare(input_a, input_b)
        SV *input_a
        SV *input_b
    CODE:
    {
        unsigned char a[16], b[16];
        STRLEN a_len, b_len;
        const char *a_str = SvPV(input_a, a_len);
        const char *b_str = SvPV(input_b, b_len);
        int cmp;

        if (a_len == 16) memcpy(a, a_str, 16);
        else if (a_len == 26) {
            if (!sekhmet_ulid_decode(a, a_str, 26))
                croak("Sekhmet: invalid first ULID");
        } else croak("Sekhmet: ulid_compare expects 16-byte binary or 26-char string");

        if (b_len == 16) memcpy(b, b_str, 16);
        else if (b_len == 26) {
            if (!sekhmet_ulid_decode(b, b_str, 26))
                croak("Sekhmet: invalid second ULID");
        } else croak("Sekhmet: ulid_compare expects 16-byte binary or 26-char string");

        cmp = sekhmet_ulid_compare(a, b);
        RETVAL = (cmp < 0) ? -1 : (cmp > 0) ? 1 : 0;
    }
    OUTPUT:
        RETVAL

int
ulid_validate(input)
        SV *input
    CODE:
    {
        STRLEN in_len;
        const char *in_str = SvPV(input, in_len);
        RETVAL = sekhmet_ulid_validate(in_str, (int)in_len);
    }
    OUTPUT:
        RETVAL
