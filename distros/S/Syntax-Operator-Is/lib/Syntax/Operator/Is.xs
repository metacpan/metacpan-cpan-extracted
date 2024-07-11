/*  You may distribute under the terms of either the GNU General Public License
 *  or the Artistic License (the same terms as Perl itself)
 *
 *  (C) Paul Evans, 2024 -- leonerd@leonerd.org.uk
 */
#define PERL_NO_GET_CONTEXT

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "XSParseInfix.h"

#include "DataChecks.h"

#define HAVE_PERL_VERSION(R, V, S) \
    (PERL_REVISION > (R) || (PERL_REVISION == (R) && (PERL_VERSION > (V) || (PERL_VERSION == (V) && (PERL_SUBVERSION >= (S))))))

#include "newOP_CUSTOM.c.inc"

/* Since Data::Checks v0.06, constraint functions are strongly const-folded so
 * it is likely that the RHS of an `is` operator is a constant expression. If
 * so, we'll compile it into a pp_static_is, an UNOP_AUX which stores the
 * actual `struct DataChecks_Checker` instance stored in the aux pointer
 */

static OP *pp_dynamic_is(pTHX)
{
  dSP;
  SV *checkspec = POPs;
  SV *value = POPs;

  struct DataChecks_Checker *checker = make_checkdata(checkspec);

  PUSHs(boolSV(check_value(checker, value)));

  free_checkdata(checker);

  RETURN;
}

XOP xop_static_is;
static OP *pp_static_is(pTHX)
{
  dSP;
  SV *value = POPs;

  struct DataChecks_Checker *checker = (struct DataChecks_Checker *)cUNOP_AUX->op_aux;

  PUSHs(boolSV(check_value(checker, value)));

  RETURN;
}

static OP *new_is_op(pTHX_ U32 flags, OP *lhs, OP *rhs, SV **parsedata, void *hookdata)
{
  if(rhs->op_type != OP_CONST)
    return newBINOP_CUSTOM(&pp_dynamic_is, flags, lhs, rhs);

  SV *checkspec = cSVOPx(rhs)->op_sv;
  struct DataChecks_Checker *checker = make_checkdata(checkspec);

  return newUNOP_AUX_CUSTOM(&pp_static_is, flags, lhs, (UNOP_AUX_item *)checker);
}

static const struct XSParseInfixHooks hooks_is = {
  .cls            = XPI_CLS_MATCH_MISC,
  .permit_hintkey = "Syntax::Operator::Is/is",
  .new_op         = &new_is_op,
  .ppaddr         = &pp_dynamic_is,
};

MODULE = Syntax::Operator::Is    PACKAGE = Syntax::Operator::Is

BOOT:
  boot_xs_parse_infix(0.43);
  boot_data_checks(0.06);  /* const-folding */

  register_xs_parse_infix("Syntax::Operator::Is::is", &hooks_is, NULL);

  XopENTRY_set(&xop_static_is, xop_name, "static_is");
  XopENTRY_set(&xop_static_is, xop_desc, "is operator (with static constraint)");
  XopENTRY_set(&xop_static_is, xop_class, OA_UNOP_AUX);
  Perl_custom_op_register(aTHX_ &pp_static_is, &xop_static_is);
