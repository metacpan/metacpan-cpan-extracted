// With gcc: GNU-C99 is OK if string.h comes first, but plain C99 isn’t.

#include "xshelper.h"

#include <string.h>

#define _CROAK_STRINGIFY_REFERENCE(sv) \
    croak("%" SVf " given where string expected!", sv)

SV* _MY_xsh_ptr_to_svrv (pTHX_ void* ptr, HV* stash) {
    SV* referent = newSVuv( PTR2UV(ptr) );
    SV* retval = newRV_noinc(referent);
    sv_bless(retval, stash);

    return retval;
}

/* ---------------------------------------------------------------------- */

bool xsh_sv_streq (pTHX_ SV* sv, const char* b) {
    if (SvROK(sv)) _CROAK_STRINGIFY_REFERENCE(sv);

    if (SvOK(sv)) {
        STRLEN alen;
        const char* a = SvPVbyte(sv, alen);

        if (NULL != memchr(a, '\0', alen)) {
            return strEQ(a, b);
        }
    }

    return false;
}

char* _MY_xsh_sv_to_str (pTHX_ SV* sv, bool is_utf8) {
    if (SvROK(sv)) _CROAK_STRINGIFY_REFERENCE(sv);

    char *str = is_utf8 ? SvPVutf8_nolen(sv) : SvPVbyte_nolen(sv);

    size_t len = strnlen(str, 1 + SvCUR(sv));
    if (len != SvCUR(sv)) {
        croak("Cannot convert scalar to C string (NUL byte detected, offset %zu)", len);
    }

    return str;
}

UV _MY_xsh_sv_to_uv (pTHX_ SV* sv) {
    if (SvROK(sv)) _CROAK_STRINGIFY_REFERENCE(sv);

    if (SvUOK(sv)) return SvUV(sv);

    UV myuv = SvUV(sv);

    SV* sv2 = newSVuv(myuv);

    if (sv_eq(sv, sv2)) return myuv;

    croak("`%" SVf "` given where unsigned integer expected!", sv);
}

IV _MY_xsh_sv_to_iv (pTHX_ SV* sv) {
    if (SvROK(sv)) _CROAK_STRINGIFY_REFERENCE(sv);

    if (SvIOK(sv)) return SvIV(sv);

    IV myiv = SvIV(sv);

    SV* sv2 = newSViv(myiv);

    if (sv_eq(sv, sv2)) return myiv;

    croak("`%" SVf "` given where integer expected!", sv);
}

/* ---------------------------------------------------------------------- */

#define _SET_ARGS(object, args) {               \
    unsigned argscount = 0;                     \
                                                \
    if (args) {                                 \
        while (args[argscount] != NULL) {       \
            argscount++;                        \
        }                                       \
    }                                           \
                                                \
    ENTER;                                      \
    SAVETMPS;                                   \
                                                \
    PUSHMARK(SP);                               \
                                                \
    EXTEND(SP, 1 + argscount);                  \
                                                \
    if (object) PUSHs( sv_mortalcopy(object) ); \
                                                \
    unsigned a=0;                               \
    while (a < argscount) mPUSHs( args[a++] );  \
                                                \
    PUTBACK;                                    \
}

void xsh_call_object_method_void (pTHX_ SV* object, const char* methname, SV** args) {
    dSP;

    _SET_ARGS(object, args);

    call_method( methname, G_DISCARD | G_VOID );

    FREETMPS;
    LEAVE;
}

SV* xsh_call_object_method_scalar (pTHX_ SV* object, const char* methname, SV** args) {
    dSP;

    _SET_ARGS(object, args);

    int got = call_method( methname, G_SCALAR );

    SPAGAIN;

    assert(got < 2);

    SV* ret = got ? SvREFCNT_inc(POPs) : NULL;

    PUTBACK;
    FREETMPS;
    LEAVE;

    return ret;
}

void _MY_xsh_call_sv_trap_void (pTHX_ SV* cbref, SV** args, const char *warnprefix) {
    dSP;

    _SET_ARGS(NULL, args);

    call_sv(cbref, G_VOID|G_DISCARD|G_EVAL);

    SV* err = ERRSV;

    if (err && SvTRUE(err)) {
        warn("%s%" SVf, warnprefix, err);
    }

    FREETMPS;
    LEAVE;
}
