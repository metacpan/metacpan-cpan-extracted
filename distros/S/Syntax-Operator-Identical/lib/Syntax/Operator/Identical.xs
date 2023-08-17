/*  You may distribute under the terms of either the GNU General Public License
 *  or the Artistic License (the same terms as Perl itself)
 *
 *  (C) Paul Evans, 2022 -- leonerd@leonerd.org.uk
 */
#define PERL_NO_GET_CONTEXT

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "XSParseInfix.h"

#define HAVE_PERL_VERSION(R, V, S) \
    (PERL_REVISION > (R) || (PERL_REVISION == (R) && (PERL_VERSION > (V) || (PERL_VERSION == (V) && (PERL_SUBVERSION >= (S))))))

#if HAVE_PERL_VERSION(5, 36, 0)
#  define HAVE_SV_BOOL
#endif

#include "sv_numeq.c.inc"
#include "sv_streq.c.inc"

/* Any defined SV has atleast one of these flags */
#define SV_FLAGMASK_DEFINED  (SVf_POK|SVf_IOK|SVf_NOK|SVf_ROK)

#define sv_identical(lhs, rhs)  S_sv_identical(aTHX_ lhs, rhs)
static bool S_sv_identical(pTHX_ SV *lhs, SV *rhs)
{
  SvGETMAGIC(lhs);
  SvGETMAGIC(rhs);

  U32 lflags = SvFLAGS(lhs);
  U32 rflags = SvFLAGS(rhs);

  U32 anyflags = lflags | rflags;
  U32 allflags = lflags & rflags;

  if(!(anyflags & SV_FLAGMASK_DEFINED))
    /* both are undef */
    return TRUE;
  if(!(lflags & SV_FLAGMASK_DEFINED) || !(rflags & SV_FLAGMASK_DEFINED))
    /* atleast one is not defined */
    return FALSE;

#ifdef HAVE_SV_BOOL
   /* Boolean SVs have all of these flags */
#  define SV_FLAGS_BOOL  (SVf_POK|SVf_IOK|SVf_IsCOW|SVppv_STATIC)

  if((anyflags & SV_FLAGS_BOOL) == SV_FLAGS_BOOL) {
    /* at least one SV is likely a boolean. the test doesn't have to be
     * perfect because we're about to check properly anyway */
    bool lbool = SvIsBOOL(lhs);
    bool rbool = SvIsBOOL(rhs);

    if(lbool && rbool) {
      /* both are definitely bools */
      if(SvTRUE(lhs) ^ SvTRUE(rhs))
        return FALSE;
      else
        return TRUE;
    }

    if(lbool || rbool)
      /* one was a bool, one was not */
      return FALSE;

    /* neither was in fact a bool; no worries just fallthrough */
  }
#endif

  if(anyflags & SVf_ROK) {
    /* at least one SV is a reference */
    if(!(allflags & SVf_ROK))
      /* ... but not both */
      return FALSE;

    if(SvRV(lhs) == SvRV(rhs))
      return TRUE;
    else
      return FALSE;
  }

  /* By now we know that both SVs are defined, non-boolean, non-references.
   * This means that between them the must have atleast one of the following
   * *private* flags. */
  assert(anyflags & (SVp_IOK|SVp_NOK|SVp_POK));

  if(anyflags & (SVp_IOK|SVp_NOK))
    if(!sv_numeq_flags(lhs, rhs, 0))
      return FALSE;

  if(anyflags & (SVp_POK))
    if(!sv_streq_flags(lhs, rhs, 0))
      return FALSE;

  /* If neither of the above rejected then we're happy to be true */
  return TRUE;
}

static OP *pp_identical(pTHX)
{
  dSP;
  dTARG;
  SV *lhs = TOPs, *rhs = TOPm1s;

  bool ret = sv_identical(lhs, rhs);

  POPs;
  SETs(boolSV(ret));
  RETURN;
}

static OP *pp_notidentical(pTHX)
{
  dSP;
  dTARG;
  SV *lhs = TOPs, *rhs = TOPm1s;

  bool ret = !sv_identical(lhs, rhs);

  POPs;
  SETs(boolSV(ret));
  RETURN;
}

static const struct XSParseInfixHooks hooks_identical = {
  .cls               = XPI_CLS_EQUALITY,
  .wrapper_func_name = "Syntax::Operator::Identical::is_identical",
  .permit_hintkey    = "Syntax::Operator::Identical/identical",
  .ppaddr            = &pp_identical,
};

static const struct XSParseInfixHooks hooks_notidentical = {
  .cls               = XPI_CLS_RELATION,
  .wrapper_func_name = "Syntax::Operator::Identical::is_not_identical",
  .permit_hintkey    = "Syntax::Operator::Identical/identical",
  .ppaddr            = &pp_notidentical,
};

MODULE = Syntax::Operator::Identical    PACKAGE = Syntax::Operator::Identical

BOOT:
  boot_xs_parse_infix(0.26);

  register_xs_parse_infix("≡",   &hooks_identical, NULL);
  register_xs_parse_infix("=:=", &hooks_identical, NULL);

  register_xs_parse_infix("≢",   &hooks_notidentical, NULL);
  register_xs_parse_infix("!:=", &hooks_notidentical, NULL);

  /* TODO: Consider adding some sort of rpeep integration into XPI so we can
   *   optimise not(identical) into notidentical or vice-versa
   */
