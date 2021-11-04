#ifndef XSHELPER_H
#define XSHELPER_H

#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

/*
    Calls $object->$methname(@args) in void context. (args may be NULL.)

    IMPORTANT: Each @args will be MORTALIZED!
*/
void xsh_call_object_method_void (pTHX_ SV* object, const char* methname, SV** args);

SV* xsh_call_object_method_scalar (pTHX_ SV* object, const char* methname, SV** args);

#define xsh_call_sv_trap_void(cbref, args, warnprefix) \
    _MY_xsh_call_sv_trap_void(aTHX_ cbref, args, warnprefix)

void _MY_xsh_call_sv_trap_void (pTHX_ SV* cbref, SV** args, const char *warnprefix);

//----------------------------------------------------------------------

/*
    Returns a boolean that indicates whether the byte string in `sv`
    matches `b`. `b` is assumed to be NUL-terminated.

    Croaks if `sv` is a reference.
*/
bool xsh_sv_streq (pTHX_ SV* sv, const char* b);

/*
    Like SvPVbyte_nolen but croaks if `sv`’s string contains a NUL byte
    or if `sv` is a reference.
*/
#define xsh_sv_to_str(sv) _MY_xsh_sv_to_str(aTHX_ sv, false)
char* _MY_xsh_sv_to_str (pTHX_ SV* sv, bool is_utf8);

/*
    Like SvPVutf8_nolen but croaks if `sv`’s string contains a NUL byte
    or if `sv` is a reference.
*/
#define xsh_sv_to_utf8_str(sv) _MY_xsh_sv_to_str(aTHX_ sv, true)

/*
    Like L<perlapi/SvUV> but croaks if `sv` isn’t a simple unsigned integer.
*/
#define xsh_sv_to_uv(sv) _MY_xsh_sv_to_uv(aTHX_ sv)
UV _MY_xsh_sv_to_uv (pTHX_ SV* sv);

/*
    Like L<perlapi/SvIV> but croaks if `sv` isn’t a simple integer.
*/
#define xsh_sv_to_iv(sv) _MY_xsh_sv_to_iv(aTHX_ sv)
IV _MY_xsh_sv_to_iv (pTHX_ SV* sv);

//----------------------------------------------------------------------

/*
    Creates a new SVRV that refers to ptr, blessed as a scalar reference.
*/
#define xsh_ptr_to_svrv(ptr, stash) \
    _MY_xsh_ptr_to_svrv(aTHX_ ptr, stash)

SV* _MY_xsh_ptr_to_svrv (pTHX_ void* ptr, HV* stash);

/*
    Extracts a pointer value from an SVRV, which we assume to be
    a scalar reference. The reverse of xsh_ptr_to_svrv().
*/
#define xsh_svrv_to_ptr(svrv) ( \
    (void *) SvUV(SvRV(svrv))   \
)

//----------------------------------------------------------------------

#define xsh_PL_package \
    HvNAME( (HV*)CopSTASH(PL_curcop) )

#endif
