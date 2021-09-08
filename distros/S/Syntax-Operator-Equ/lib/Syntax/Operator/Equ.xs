/*  You may distribute under the terms of either the GNU General Public License
 *  or the Artistic License (the same terms as Perl itself)
 *
 *  (C) Paul Evans, 2016-2021 -- leonerd@leonerd.org.uk
 */
#define PERL_NO_GET_CONTEXT

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "XSParseInfix.h"

/* We'd like to call Perl_do_ncmp, except that isn't an exported API function
 * Here's a near-copy of it for num-equality testing purposes */
#define do_numeq(left, right)  S_do_numeq(aTHX_ left, right)
static bool S_do_numeq(pTHX_ SV *left, SV *right)
{
#ifndef HAVE_BOOL_SvIV_please_nomg
  /* Before perl 5.18, SvIV_please_nomg() was void-returning */
  SvIV_please_nomg(left);
  SvIV_please_nomg(right);
#endif

  if(
#ifdef HAVE_BOOL_SvIV_please_nomg
    SvIV_please_nomg(right) && SvIV_please_nomg(left)
#else
    SvIOK(left) && SvIOK(right)
#endif
  ) {
    /* Compare as integers */
    switch((SvUOK(left) ? 1 : 0) | (SvUOK(right) ? 2 : 0)) {
      case 0: /* IV == IV */
        return SvIVX(left) == SvIVX(right);

      case 1: /* UV == IV */
      {
        const IV riv = SvUVX(right);
        if(riv < 0)
          return 0;
        return (SvUVX(left) == riv);
      }

      case 2: /* IV == UV */
      {
        const IV liv = SvUVX(left);
        if(liv < 0)
          return 0;
        return (liv == SvUVX(right));
      }

      case 3: /* UV == UV */
        return SvUVX(left) == SvUVX(right);
    }
  }
  else {
    /* Compare NVs */
    NV const rnv = SvNV_nomg(right);
    NV const lnv = SvNV_nomg(left);

    return lnv == rnv;
  }
}

static OP *pp_equ_numeric(pTHX)
{
  dSP;
  dTARG;
  SV *lhs = TOPs, *rhs = TOPm1s;

  SvGETMAGIC(lhs);
  SvGETMAGIC(rhs);

  bool lundef = !SvOK(lhs), rundef = !SvOK(rhs);

  if(lundef || rundef) {
    POPs;
    SETs(lundef && rundef ? &PL_sv_yes : &PL_sv_no);
    RETURN;
  }

  /* Logic stolen from perl's tryAMAGICbin() macro */
  if(UNLIKELY(((SvFLAGS(lhs)|SvFLAGS(rhs)) & (SVf_ROK|SVs_GMG)) &&
      Perl_try_amagic_bin(aTHX_ eq_amg, 0))) {
    return NORMAL;
  }

  POPs;
  SETs(do_numeq(lhs, rhs) ? &PL_sv_yes : &PL_sv_no);
  RETURN;
}

static OP *pp_equ_stringy(pTHX)
{
  dSP;
  dTARG;
  SV *lhs = TOPs, *rhs = TOPm1s;

  SvGETMAGIC(lhs);
  SvGETMAGIC(rhs);

  bool lundef = !SvOK(lhs), rundef = !SvOK(rhs);

  if(lundef || rundef) {
    POPs;
    SETs(lundef && rundef ? &PL_sv_yes : &PL_sv_no);
    RETURN;
  }

  /* Logic stolen from perl's tryAMAGICbin() macro */
  if(UNLIKELY(((SvFLAGS(lhs)|SvFLAGS(rhs)) & (SVf_ROK|SVs_GMG)) &&
      Perl_try_amagic_bin(aTHX_ seq_amg, 0))) {
    return NORMAL;
  }

  POPs;
  SETs(sv_eq(lhs, rhs) ? &PL_sv_yes : &PL_sv_no);
  RETURN;
}

static const struct XSParseInfixHooks hooks_numeric = {
  .cls = XPI_CLS_EQUALITY,
  .wrapper_func_name = "Syntax::Operator::Equ::is_numequ",
  .permit_hintkey = "Syntax::Operator::Equ/equ",
  .ppaddr         = &pp_equ_numeric,
};

static const struct XSParseInfixHooks hooks_stringy = {
  .cls = XPI_CLS_EQUALITY,
  .wrapper_func_name = "Syntax::Operator::Equ::is_strequ",
  .permit_hintkey = "Syntax::Operator::Equ/equ",
  .ppaddr         = &pp_equ_stringy,
};

MODULE = Syntax::Operator::Equ    PACKAGE = Syntax::Operator::Equ

BOOT:
  boot_xs_parse_infix(0.15);

  register_xs_parse_infix("===", &hooks_numeric, NULL);
  register_xs_parse_infix("equ", &hooks_stringy, NULL);
