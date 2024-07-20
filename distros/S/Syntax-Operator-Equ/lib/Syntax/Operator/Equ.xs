/*  You may distribute under the terms of either the GNU General Public License
 *  or the Artistic License (the same terms as Perl itself)
 *
 *  (C) Paul Evans, 2016-2023 -- leonerd@leonerd.org.uk
 */
#define PERL_NO_GET_CONTEXT

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "XSParseInfix.h"

#include "sv_regexp_match.c.inc"
#include "sv_numeq.c.inc"
#include "sv_streq.c.inc"

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

  POPs;
  SETs(sv_numeq_flags(lhs, rhs, 0) ? &PL_sv_yes : &PL_sv_no);
  RETURN;
}

static bool test_stringy_equ(pTHX_ SV *lhs, SV *rhs, bool test_rhs_regexp)
{
  SvGETMAGIC(lhs);
  SvGETMAGIC(rhs);

  bool lundef = !SvOK(lhs), rundef = !SvOK(rhs);

  if(lundef || rundef) {
    return lundef && rundef;
  }

  if(test_rhs_regexp && SvRXOK(rhs))
    return sv_regexp_match(lhs, (REGEXP *)SvRV(rhs));
  else
    return sv_streq_flags(lhs, rhs, 0);
}

static OP *pp_equ_stringy(pTHX)
{
  dSP;
  dTARG;
  SV *lhs = TOPm1s, *rhs = TOPs;

  POPs;
  SETs(test_stringy_equ(aTHX_ lhs, rhs, FALSE) ? &PL_sv_yes : &PL_sv_no);
  RETURN;
}

static OP *pp_eqr(pTHX)
{
  dSP;
  dTARG;
  SV *lhs = TOPm1s, *rhs = TOPs;

  POPs;
  SETs(test_stringy_equ(aTHX_ lhs, rhs, TRUE) ? &PL_sv_yes : &PL_sv_no);
  RETURN;
}

static const struct XSParseInfixHooks hooks_equ_numeric = {
  .cls               = XPI_CLS_EQUALITY,
  .wrapper_func_name = "Syntax::Operator::Equ::is_numequ",
  .ppaddr            = &pp_equ_numeric,
};

static const struct XSParseInfixHooks hooks_equ_stringy = {
  .cls               = XPI_CLS_EQUALITY,
  .wrapper_func_name = "Syntax::Operator::Equ::is_strequ",
  .ppaddr            = &pp_equ_stringy,
};

static const struct XSParseInfixHooks hooks_eqr = {
  .cls               = XPI_CLS_MATCH_MISC,
  .wrapper_func_name = "Syntax::Operator::Eqr::is_eqr",
  .ppaddr            = &pp_eqr,
};

MODULE = Syntax::Operator::Equ    PACKAGE = Syntax::Operator::Equ

BOOT:
  boot_xs_parse_infix(0.44);

  register_xs_parse_infix("Syntax::Operator::Equ::===", &hooks_equ_numeric, NULL);
  register_xs_parse_infix("Syntax::Operator::Equ::equ", &hooks_equ_stringy, NULL);

  register_xs_parse_infix("Syntax::Operator::Eqr::eqr", &hooks_eqr, NULL);
