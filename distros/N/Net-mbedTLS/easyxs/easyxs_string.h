#ifndef EASYXS_STRING_H
#define EASYXS_STRING_H 1

#include "init.h"

static inline char* _easyxs_sv_to_str (pTHX_ SV* sv, U8 is_utf8) {
    if (SvROK(sv)) _EASYXS_CROAK_STRINGIFY_REFERENCE(sv);

    char *str = is_utf8 ? SvPVutf8_nolen(sv) : SvPVbyte_nolen(sv);

    size_t len = strlen(str);
    if (len != SvCUR(sv)) {
        croak("Cannot convert scalar to C string (NUL byte detected, offset %" UVf ")", (UV) len);
    }

    return str;
}

/* ---------------------------------------------------------------------- */

#define exs_SvPVbyte_nolen(sv) _easyxs_sv_to_str(aTHX_ sv, 0)
#define exs_SvPVutf8_nolen(sv) _easyxs_sv_to_str(aTHX_ sv, 1)

#endif
