/*  You may distribute under the terms of either the GNU General Public License
 *  or the Artistic License (the same terms as Perl itself)
 *
 *  (C) Paul Evans, 2021-2022 -- leonerd@leonerd.org.uk
 */
#define PERL_NO_GET_CONTEXT

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "object_pad.h"

#include "perl-backcompat.c.inc"

static void trigger_gen_accessor_ops(pTHX_ FieldMeta *fieldmeta, SV *hookdata, void *_funcdata, enum AccessorType type, struct AccessorGenerationCtx *ctx)
{
  if(type != ACCESSOR_WRITER)
    return;

  OP *selfop;
  OP *callop = newLISTOP(OP_LIST, 0,
    selfop = newOP(OP_PADSV, 0), NULL);
  callop = op_append_list(OP_LIST, callop,
    newMETHOP_named(OP_METHOD_NAMED, 0, newSVpvn_share(SvPV_nolen(hookdata), SvCUR(hookdata), 0)));

  selfop->op_targ = PADIX_SELF;

  callop = op_convert_list(OP_ENTERSUB, OPf_STACKED, callop);

  ctx->post_bodyops = op_append_list(OP_LINESEQ, ctx->post_bodyops, callop);

  return;
}

static void trigger_seal(pTHX_ FieldMeta *fieldmeta, SV *hookdata, void *_funcdata)
{
  if(mop_field_get_attribute(fieldmeta, "writer"))
    return;

  warn("Applying :Trigger attribute to field %" SVf " is not useful without a :writer",
    SVfARG(mop_field_get_name(fieldmeta)));
}

static const struct FieldHookFuncs trigger_hooks = {
  .ver   = OBJECTPAD_ABIVERSION,
  .flags = OBJECTPAD_FLAG_ATTR_MUST_VALUE,
  .permit_hintkey = "Object::Pad::FieldAttr::Trigger/Trigger",

  .seal             = &trigger_seal,
  .gen_accessor_ops = &trigger_gen_accessor_ops,
};

MODULE = Object::Pad::FieldAttr::Trigger    PACKAGE = Object::Pad::FieldAttr::Trigger

BOOT:
  register_field_attribute("Trigger", &trigger_hooks, NULL);
