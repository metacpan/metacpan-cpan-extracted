/*  You may distribute under the terms of either the GNU General Public License
 *  or the Artistic License (the same terms as Perl itself)
 *
 *  (C) Paul Evans, 2021-2023 -- leonerd@leonerd.org.uk
 */
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "XSParseInfix.h"

#include "perl-backcompat.c.inc"
#include "newOP_CUSTOM.c.inc"
#include "OP_HELEMEXISTSOR.c.inc"

static OP *new_op_existsor(pTHX_ U32 flags, OP *lhs, OP *rhs, SV **parsedata, void *hookdata)
{
  if(!lhs || lhs->op_type != OP_HELEM)
    croak("Left operand of existsor must be a hash element access");

  op_contextualize(newHELEMEXISTSOROP(0, lhs, rhs), G_SCALAR);
}

static const struct XSParseInfixHooks hooks_existsor_low = {
  .cls            = XPI_CLS_LOGICAL_OR_LOW_MISC,
  .permit_hintkey = "Syntax::Operator::ExistsOr/existsor",
  .new_op         = &new_op_existsor,
};

static const struct XSParseInfixHooks hooks_existsor = {
  .cls            = XPI_CLS_LOGICAL_OR_MISC,
  .permit_hintkey = "Syntax::Operator::ExistsOr/existsor",
  .new_op         = &new_op_existsor,
};

MODULE = Syntax::Operator::ExistsOr    PACKAGE = Syntax::Operator::ExistsOr

BOOT:
  boot_xs_parse_infix(0.26);

  register_xs_parse_infix("existsor", &hooks_existsor_low, NULL);
  register_xs_parse_infix("\\\\",     &hooks_existsor,     NULL);
