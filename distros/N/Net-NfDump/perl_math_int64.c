/*
 * perl_math_int64.h - This file is in the public domain
 *
 * Author: Salvador Fandino <sfandino@yahoo.com>
 * Version: 1.2
 */

#include "EXTERN.h"
#include "perl.h"
#include "ppport.h"

#ifdef __MINGW32__
#include <stdint.h>
#endif

#ifdef _MSC_VER
#include <stdlib.h>
typedef __int64 int64_t;
typedef unsigned __int64 uint64_t;
#endif

/* you may need to add a typemap for int64_t here if it is not defined
   by default in your C header files */

HV *math_int64_capi_hash;
int math_int64_capi_version;
SV *(*math_int64_capi_newSVi64)(pTHX_ int64_t);
SV *(*math_int64_capi_newSVu64)(pTHX_ uint64_t);
int64_t (*math_int64_capi_SvI64)(pTHX_ SV*);
uint64_t (*math_int64_capi_SvU64)(pTHX_ SV*);
int (*math_int64_capi_SvI64OK)(pTHX_ SV*);
int (*math_int64_capi_SvU64OK)(pTHX_ SV*);

#define fetch_ptr(to, name)                              \
    svp = hv_fetchs(math_int64_capi_hash, name, 0);     \
    if (!svp || !*svp) Perl_croak(aTHX_ "Unable to fetch pointer for " name " function"); \
    to = INT2PTR(void *, SvIV(*svp))

void
math_int64_boot(pTHX_ int version) {
    dSP;
    SV **svp;
    eval_pv("require Math::Int64", TRUE);
    if (SvTRUE(ERRSV))
        Perl_croak(aTHX_ "Unable to load Math::Int64: %s", SvPV_nolen(ERRSV));

    math_int64_capi_hash = get_hv("Math::Int64::C_API", 0);
    if (!math_int64_capi_hash) Perl_croak(aTHX_ "Unable to load Math::Int64 C API");

    math_int64_capi_version = SvIV(*hv_fetchs(math_int64_capi_hash, "version", 1));
    if (math_int64_capi_version < version)
        Perl_croak(aTHX_ "Math::Int64 C API version mismatch, expected %d, found %d",
                   version, math_int64_capi_version);

    fetch_ptr(math_int64_capi_newSVi64, "newSVi64");
    fetch_ptr(math_int64_capi_newSVu64, "newSVu64");
    fetch_ptr(math_int64_capi_SvI64, "SvI64");
    fetch_ptr(math_int64_capi_SvU64, "SvU64");
    fetch_ptr(math_int64_capi_SvI64OK, "SvI64OK");
    fetch_ptr(math_int64_capi_SvU64OK, "SvU64OK");
}
