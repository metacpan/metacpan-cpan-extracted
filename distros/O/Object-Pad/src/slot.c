#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "object_pad.h"

#undef register_slot_attribute

#include "perl-backcompat.c.inc"
#include "perl-additions.c.inc"

SlotMeta *ObjectPad_mop_create_slot(pTHX_ SV *slotname, ClassMeta *classmeta)
{
  SlotMeta *slotmeta;
  Newx(slotmeta, 1, SlotMeta);

  slotmeta->name = SvREFCNT_inc(slotname);
  slotmeta->class = classmeta;
  slotmeta->slotix = classmeta->next_slotix;
  slotmeta->defaultsv = NULL;
  slotmeta->readername = slotmeta->writername = slotmeta->mutatorname = NULL;

  slotmeta->hooks = NULL;

  return slotmeta;
}

void ObjectPad_mop_slot_set_param(pTHX_ SlotMeta *slotmeta, const char *paramname)
{
  ClassMeta *classmeta = slotmeta->class;

  if(!classmeta->parammap)
    classmeta->parammap = newHV();

  HV *parammap = classmeta->parammap;

  I32 klen = strlen(paramname);
  SV **svp;
  if((svp = hv_fetch(parammap, paramname, klen, 0))) {
    SlotMeta *colliding_slotmeta = *((SlotMeta **)svp);
    if(colliding_slotmeta->class != classmeta)
      croak("Already have a named constructor parameter called '%s' inherited from %" SVf,
        paramname, SVfARG(colliding_slotmeta->class->name));
    else
      croak("Already have a named constructor parameter called '%s'", paramname);
  }

  ParamMeta *parammeta;
  Newx(parammeta, 1, struct ParamMeta);

  parammeta->name = newSVpvn(paramname, klen);
  parammeta->slot = slotmeta;
  parammeta->slotix = slotmeta->slotix;

  hv_store(parammap, paramname, klen, (SV *)parammeta, 0);
}

typedef struct SlotAttributeRegistration SlotAttributeRegistration;

struct SlotAttributeRegistration {
  SlotAttributeRegistration *next;

  const char *name;
  STRLEN permit_hintkeylen;

  const struct SlotHookFuncs *funcs;
};

static SlotAttributeRegistration *slotattrs = NULL;

static void register_slot_attribute(const char *name, const struct SlotHookFuncs *funcs)
{
  SlotAttributeRegistration *reg;
  Newx(reg, 1, struct SlotAttributeRegistration);

  reg->name = name;
  reg->funcs = funcs;

  if(funcs->permit_hintkey)
    reg->permit_hintkeylen = strlen(funcs->permit_hintkey);
  else
    reg->permit_hintkeylen = 0;

  reg->next = slotattrs;
  slotattrs = reg;
}

void ObjectPad_mop_slot_apply_attribute(pTHX_ SlotMeta *slotmeta, const char *name, SV *value)
{
  HV *hints = GvHV(PL_hintgv);

  if(!SvPOK(value) || !SvCUR(value))
    value = NULL;

  SlotAttributeRegistration *reg;
  for(reg = slotattrs; reg; reg = reg->next) {
    if(!strEQ(name, reg->name))
      continue;

    if(reg->funcs->permit_hintkey &&
       (!hints || !hv_fetch(hints, reg->funcs->permit_hintkey, reg->permit_hintkeylen, 0)))
      continue;

    if((reg->funcs->flags & OBJECTPAD_FLAG_ATTR_NO_VALUE) && value)
      croak("Attribute :%s does not permit a value", name);
    if((reg->funcs->flags & OBJECTPAD_FLAG_ATTR_MUST_VALUE) && !value)
      croak("Attribute :%s requires a value", name);

    if(reg->funcs->apply)
      if((*reg->funcs->apply)(aTHX_ slotmeta, value))
        return;

    if(!slotmeta->hooks)
      slotmeta->hooks = newAV();

    struct SlotHook *hook;
    Newx(hook, 1, struct SlotHook);

    hook->funcs = reg->funcs;
    hook->hookdata = value;

    av_push(slotmeta->hooks, (SV *)hook);

    return;
  }

  croak("Unrecognised slot attribute :%s", name);
}

/*******************
 * Attribute hooks *
 *******************/

/* :weak */

static void slothook_weak_post_initslot(pTHX_ SlotMeta *slotmeta, SV *_hookdata, SV *slot)
{
  sv_rvweaken(slot);
}

static OP *pp_weaken(pTHX)
{
  dSP;
  sv_rvweaken(POPs);
  return NORMAL;
}

static void slothook_weak_gen_accessor(pTHX_ SlotMeta *slotmeta, SV *hookdata, enum AccessorType type, struct AccessorGenerationCtx *ctx)
{
  if(type != ACCESSOR_WRITER)
    return;

  ctx->post_bodyops = op_append_list(OP_LINESEQ, ctx->post_bodyops,
    newUNOP_CUSTOM(&pp_weaken, 0, newPADxVOP(OP_PADSV, ctx->padix, 0, 0)));
}

static struct SlotHookFuncs slothooks_weak = {
  .flags = OBJECTPAD_FLAG_ATTR_NO_VALUE,
  .post_initslot = &slothook_weak_post_initslot,
  .gen_accessor_ops = &slothook_weak_gen_accessor,
};

/* :param */

static bool slothook_param_apply(pTHX_ SlotMeta *slotmeta, SV *value)
{
  if(SvPVX(slotmeta->name)[0] != '$')
    croak("Can only add a named constructor parameter for scalar slots");

  char *paramname = value ? SvPVX(value) : NULL;

  if(!paramname) {
    paramname = SvPVX(slotmeta->name) + 1;
    if(paramname[0] == '_')
      paramname++;
  }

  mop_slot_set_param(slotmeta, paramname);

  return FALSE;
}

static struct SlotHookFuncs slothooks_param = {
  .apply = &slothook_param_apply,
};

/* :reader */

static SV *make_accessor_mnamesv(pTHX_ SlotMeta *slotmeta, const char *mname, const char *fmt)
{
  if(SvPVX(slotmeta->name)[0] != '$')
    /* TODO: A reader for an array or hash slot should also be fine */
    croak("Can only generate accessors for scalar slots");

  /* if(mname && !is_valid_ident_utf8((U8 *)mname))
    croak("Invalid accessor method name");
    */

  if(mname)
    return newSVpv(mname, 0);

  if(SvPVX(slotmeta->name)[1] == '_')
    mname = SvPVX(slotmeta->name) + 2;
  else
    mname = SvPVX(slotmeta->name) + 1;

  return newSVpvf(fmt, mname);
}

static bool slothook_reader_apply(pTHX_ SlotMeta *slotmeta, SV *value)
{
  slotmeta->readername = make_accessor_mnamesv(aTHX_ slotmeta, value ? SvPVX(value) : NULL, "%s");
  return FALSE;
}

static void slothook_gen_reader_ops(pTHX_ SlotMeta *slotmeta, SV *hookdata, enum AccessorType type, struct AccessorGenerationCtx *ctx)
{
  if(type != ACCESSOR_READER)
    return;

  ctx->retop = newLISTOP(OP_RETURN, 0,
    newOP(OP_PUSHMARK, 0),
    newPADxVOP(OP_PADSV, ctx->padix, 0, 0));
}

static struct SlotHookFuncs slothooks_reader = {
  .apply = &slothook_reader_apply,
  .gen_accessor_ops = &slothook_gen_reader_ops,
};

/* :writer */

static bool slothook_writer_apply(pTHX_ SlotMeta *slotmeta, SV *value)
{
  slotmeta->writername = make_accessor_mnamesv(aTHX_ slotmeta, value ? SvPVX(value) : NULL, "set_%s");
  return FALSE;
}

static void slothook_gen_writer_ops(pTHX_ SlotMeta *slotmeta, SV *hookdata, enum AccessorType type, struct AccessorGenerationCtx *ctx)
{
  if(type != ACCESSOR_WRITER)
    return;

  ctx->bodyop = newBINOP(OP_SASSIGN, 0,
    newOP(OP_SHIFT, 0),
    newPADxVOP(OP_PADSV, ctx->padix, 0, 0));

  ctx->retop = newLISTOP(OP_RETURN, 0,
    newOP(OP_PUSHMARK, 0),
    newPADxVOP(OP_PADSV, PADIX_SELF, 0, 0));
}

static struct SlotHookFuncs slothooks_writer = {
  .apply = &slothook_writer_apply,
  .gen_accessor_ops = &slothook_gen_writer_ops,
};

/* :mutator */

static bool slothook_mutator_apply(pTHX_ SlotMeta *slotmeta, SV *value)
{
  slotmeta->mutatorname = make_accessor_mnamesv(aTHX_ slotmeta, value ? SvPVX(value) : NULL, "%s");
  return FALSE;
}

static void slothook_gen_mutator_ops(pTHX_ SlotMeta *slotmeta, SV *hookdata, enum AccessorType type, struct AccessorGenerationCtx *ctx)
{
  if(type != ACCESSOR_LVALUE_MUTATOR)
    return;

  CvLVALUE_on(PL_compcv);

  ctx->retop = newLISTOP(OP_RETURN, 0,
    newOP(OP_PUSHMARK, 0),
    newPADxVOP(OP_PADSV, ctx->padix, 0, 0));
}

static struct SlotHookFuncs slothooks_mutator = {
  .apply = &slothook_mutator_apply,
  .gen_accessor_ops = &slothook_gen_mutator_ops,
};

void ObjectPad_register_slot_attribute(pTHX_ const char *name, const struct SlotHookFuncs *funcs)
{
  if(!name || !(name[0] >= 'A' && name[0] <= 'Z'))
    croak("Third-party slot attribute names must begin with a capital letter");

  if(!funcs->permit_hintkey)
    croak("Third-party slot attributes require a permit hinthash key");

  register_slot_attribute(name, funcs);
}

void ObjectPad__boot_slots(void)
{
  register_slot_attribute("weak",    &slothooks_weak);
  register_slot_attribute("param",   &slothooks_param);
  register_slot_attribute("reader",  &slothooks_reader);
  register_slot_attribute("writer",  &slothooks_writer);
  register_slot_attribute("mutator", &slothooks_mutator);
}
