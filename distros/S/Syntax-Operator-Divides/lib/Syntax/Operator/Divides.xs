/*  You may distribute under the terms of either the GNU General Public License
 *  or the Artistic License (the same terms as Perl itself)
 *
 *  (C) Paul Evans, 2016-2021 -- leonerd@leonerd.org.uk
 */
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "XSParseInfix.h"

#define HAVE_PERL_VERSION(R, V, S) \
    (PERL_REVISION > (R) || (PERL_REVISION == (R) && (PERL_VERSION > (V) || (PERL_VERSION == (V) && (PERL_SUBVERSION >= (S))))))

#include "newOP_CUSTOM.c.inc"

static OP *pp_divides(pTHX)
{
  dSP;

  (PL_ppaddr[OP_MODULO])(aTHX);

  SPAGAIN;

  if(SvTRUE(TOPs)) {
    *SP = &PL_sv_no;
  }
  else {
    *SP = &PL_sv_yes;
  }

  return NORMAL;
}

static OP *new_op_divides(pTHX_ U32 flags, OP *lhs, OP *rhs, void *hookdata)
{
  OP *ret = newBINOP_CUSTOM(&pp_divides, flags, lhs, rhs);
  ret->op_targ = pad_alloc(OP_CUSTOM, SVs_PADTMP);
  return ret;
}

static const struct XSParseInfixHooks hooks_divides = {
  .permit_hintkey = "Syntax::Operator::Divides/divides",
  .cls            = XPI_CLS_MATCH_MISC,
  .new_op         = &new_op_divides,
  .ppaddr         = &pp_divides,
};

MODULE = Syntax::Operator::Divides    PACKAGE = Syntax::Operator::Divides

BOOT:
  boot_xs_parse_infix(0);

  register_xs_parse_infix("%%", &hooks_divides, NULL);
