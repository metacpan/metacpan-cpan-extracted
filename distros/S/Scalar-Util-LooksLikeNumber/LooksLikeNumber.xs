/* Copyright (c) 1997-2000 Graham Barr <gbarr@pobox.com>. All rights reserved.
 * This program is free software; you can redistribute it and/or
 * modify it under the same terms as Perl itself.
 */
#define PERL_NO_GET_CONTEXT /* we want efficiency */
#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>

#define NEED_sv_2pv_flags 1
#include "ppport.h"

#if PERL_BCDVERSION >= 0x5006000
#  include "multicall.h"
#endif

#ifndef CvISXSUB
#  define CvISXSUB(cv) CvXSUB(cv)
#endif

/* Some platforms have strict exports. And before 5.7.3 cxinc (or Perl_cxinc)
   was not exported. Therefore platforms like win32, VMS etc have problems
   so we redefine it here -- GMB
*/
#if PERL_BCDVERSION < 0x5007000
/* Not in 5.6.1. */
#  ifdef cxinc
#    undef cxinc
#  endif
#  define cxinc() my_cxinc(aTHX)
static I32
my_cxinc(pTHX)
{
    cxstack_max = cxstack_max * 3 / 2;
    Renew(cxstack, cxstack_max + 1, struct context); /* fencepost bug in older CXINC macros requires +1 here */
    return cxstack_ix + 1;
}
#endif

#ifndef sv_copypv
#define sv_copypv(a, b) my_sv_copypv(aTHX_ a, b)
static void
my_sv_copypv(pTHX_ SV *const dsv, SV *const ssv)
{
    STRLEN len;
    const char * const s = SvPV_const(ssv,len);
    sv_setpvn(dsv,s,len);
    if(SvUTF8(ssv))
        SvUTF8_on(dsv);
    else
        SvUTF8_off(dsv);
}
#endif

#if PERL_VERSION < 13 || (PERL_VERSION == 13 && PERL_SUBVERSION < 9)
#  define PERL_HAS_BAD_MULTICALL_REFCOUNT
#endif

#if PERL_VERSION < 14
#  define croak_no_modify() croak("%s", PL_no_modify)
#endif

enum slu_accum {
    ACC_IV,
    ACC_NV,
    ACC_SV,
};

static enum slu_accum accum_type(SV *sv) {
    if(SvAMAGIC(sv))
        return ACC_SV;

    if(SvIOK(sv) && !SvNOK(sv) && !SvUOK(sv))
        return ACC_IV;

    return ACC_NV;
}

MODULE=Scalar::Util::LooksLikeNumber       PACKAGE=Scalar::Util::LooksLikeNumber

int
looks_like_number(sv)
    SV *sv
PROTOTYPE: $
CODE:
    SV *tempsv;
    SvGETMAGIC(sv);
    if(SvAMAGIC(sv) && (tempsv = AMG_CALLun(sv, numer))) {
        sv = tempsv;
    }
#if PERL_BCDVERSION < 0x5008005
    if(SvPOK(sv) || SvPOKp(sv)) {
        RETVAL = looks_like_number(sv);
    }
    else {
        RETVAL = SvFLAGS(sv) & (SVf_NOK|SVp_NOK|SVf_IOK|SVp_IOK);
    }
#else
    RETVAL = looks_like_number(sv);
#endif
OUTPUT:
    RETVAL

BOOT:
{
}
