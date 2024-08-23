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
#include "object_pad.h"

#define HAVE_PERL_VERSION(R, V, S) \
    (PERL_REVISION > (R) || (PERL_REVISION == (R) && (PERL_VERSION > (V) || (PERL_VERSION == (V) && (PERL_SUBVERSION >= (S))))))

#include "newOP_CUSTOM.c.inc"

static OP *pp_of(pTHX)
{
  dSP;
  FieldMeta *fieldmeta = (FieldMeta *)cUNOP_AUX->op_aux;
  SV *instance = POPs;

  ClassMeta *classmeta = NULL;

  SV *field = get_obj_fieldsv(instance, fieldmeta);

  /* TODO: consider if we should clone a copy of it, if not OPf_REF? */
  PUSHs(field);
  RETURN;
}

static OP *new_op_of(pTHX_ U32 flags, OP *lhs, OP *rhs, SV **parsedata, void *hookdata)
{
  OP *fieldexpr = lhs;
  OP *instanceexpr = rhs;

  if(fieldexpr->op_type != OP_PADSV)
    croak("Expected FIELD operand to 'of' expression to be a field variable");
  PADOFFSET fieldexpr_padix = fieldexpr->op_targ;

  op_free(fieldexpr);

  FieldMeta *fieldmeta = get_field_for_padix(fieldexpr_padix);
  if(!fieldmeta)
    croak("Unsure what field this expression refers to");

  return newUNOP_AUX_CUSTOM(&pp_of, flags, instanceexpr, (UNOP_AUX_item *)fieldmeta);
}

static const struct XSParseInfixHooks hooks_of = {
  .cls    = XPI_CLS_HIGH_MISC,
  .new_op = &new_op_of,
};

MODULE = Object::Pad::Operator::Of    PACKAGE = Object::Pad::Operator::Of

BOOT:
  boot_xs_parse_infix(0.44);

  register_xs_parse_infix("Object::Pad::Operator::Of::of", &hooks_of, NULL);
