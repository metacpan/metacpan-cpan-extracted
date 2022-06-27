/*  You may distribute under the terms of either the GNU General Public License
 *  or the Artistic License (the same terms as Perl itself)
 *
 *  (C) Paul Evans, 2016-2022 -- leonerd@leonerd.org.uk
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

  POPs;
  SETs(sv_streq_flags(lhs, rhs, 0) ? &PL_sv_yes : &PL_sv_no);
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
