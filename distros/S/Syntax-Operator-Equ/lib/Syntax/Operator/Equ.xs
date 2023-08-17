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

  if(test_rhs_regexp && SvRXOK(rhs)) {
    /* There isn't an API function for this so we'll have to do some 
     * PL_op and stack hackery. Stolen from
     *   https://metacpan.org/release/LEONT/Syntax-Infix-Smartmatch-0.001/source/lib/Syntax/Infix/Smartmatch.xs  */
    dSP;
    REGEXP *re = (REGEXP *)SvRV(rhs);
    PMOP *const matcher = cPMOPx(newPMOP(OP_MATCH, OPf_WANT_SCALAR | OPf_STACKED));
    PM_SETRE(matcher, ReREFCNT_inc(re));

    ENTER;
    SAVEFREEOP((OP *)matcher);
    SAVEOP();

    PL_op = (OP *)matcher;

    XPUSHs(lhs);
    PUTBACK;

    (void)PL_ppaddr[OP_MATCH](aTHX);

    SPAGAIN;
    bool result = SvTRUEx(POPs);

    LEAVE;

    return result;
  }

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
  .permit_hintkey    = "Syntax::Operator::Equ/equ",
  .ppaddr            = &pp_equ_numeric,
};

static const struct XSParseInfixHooks hooks_equ_stringy = {
  .cls               = XPI_CLS_EQUALITY,
  .wrapper_func_name = "Syntax::Operator::Equ::is_strequ",
  .permit_hintkey    = "Syntax::Operator::Equ/equ",
  .ppaddr            = &pp_equ_stringy,
};

static const struct XSParseInfixHooks hooks_eqr = {
  .cls               = XPI_CLS_MATCH_MISC,
  .wrapper_func_name = "Syntax::Operator::Eqr::is_eqr",
  .permit_hintkey    = "Syntax::Operator::Eqr/eqr",
  .ppaddr            = &pp_eqr,
};

MODULE = Syntax::Operator::Equ    PACKAGE = Syntax::Operator::Equ

BOOT:
  boot_xs_parse_infix(0.26);

  register_xs_parse_infix("===", &hooks_equ_numeric, NULL);
  register_xs_parse_infix("equ", &hooks_equ_stringy, NULL);

  register_xs_parse_infix("eqr", &hooks_eqr, NULL);
