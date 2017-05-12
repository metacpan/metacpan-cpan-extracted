/*
 * perl_math_int64.h - This file is in the public domain
 *
 * Author: Salvador Fandino <sfandino@yahoo.com>
 * Version: 1.0
 */

#if !defined (PERL_MATH_INT64_H_INCLUDED)
#define PERL_MATH_INT64_H_INCLUDED

#define MATH_INT64_VERSION 1

#if (defined(MATH_INT64_NATIVE_IF_AVAILABLE) && (IVSIZE == 8))
#define MATH_INT64_NATIVE 1
#endif

#if MATH_INT64_NATIVE

#define MATH_INT64_BOOT 
#define newSVi64 newSViv
#define newSVu64 newSVuv
#define SvI64 SvIV
#define SvU64 SvUV
#define SvI64OK SvIOK
#define SvU64OK SvIOK_UV

#else

extern HV *math_int64_capi_hash;                                       
extern int math_int64_capi_version;
extern SV *(*math_int64_capi_newSVi64)(pTHX_ int64_t);
extern SV *(*math_int64_capi_newSVu64)(pTHX_ uint64_t);
extern int64_t (*math_int64_capi_SvI64)(pTHX_ SV*);
extern uint64_t (*math_int64_capi_SvU64)(pTHX_ SV*);
extern int (*math_int64_capi_SvI64OK)(pTHX_ SV*);
extern int (*math_int64_capi_SvU64OK)(pTHX_ SV*);

void math_int64_boot(pTHX_ int version);

#define MATH_INT64_BOOT math_int64_boot(aTHX_ MATH_INT64_VERSION)

#define newSVi64(i64) (*math_int64_capi_newSVi64)(aTHX_ i64)
#define newSVu64(u64) (*math_int64_capi_newSVu64)(aTHX_ u64)
#define SvI64(sv) (*math_int64_capi_SvI64)(aTHX_ sv)
#define SvU64(sv) (*math_int64_capi_SvU64)(aTHX_ sv)
#define SvI64OK(sv) (*math_int64_capi_SvI64OK)(aTHX_ sv)
#define SvU64OK(sv) (*math_int64_capi_SvU64OK)(aTHX_ sv)

#endif

#endif
