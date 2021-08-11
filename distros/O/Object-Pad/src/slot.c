#define PERL_NO_GET_CONTEXT

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "object_pad.h"
#include "class.h"
#include "slot.h"

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

  slotmeta->hooks = NULL;

  return slotmeta;
}

SV *ObjectPad_mop_slot_get_name(pTHX_ SlotMeta *slotmeta)
{
  return slotmeta->name;
}

char ObjectPad_mop_slot_get_sigil(pTHX_ SlotMeta *slotmeta)
{
  return (SvPVX(slotmeta->name))[0];
}

#define mop_slot_set_param(slotmeta, paramname)  S_mop_slot_set_param(aTHX_ slotmeta, paramname)
static void S_mop_slot_set_param(pTHX_ SlotMeta *slotmeta, SV *paramname)
{
  ClassMeta *classmeta = slotmeta->class;

  if(!classmeta->parammap)
    classmeta->parammap = newHV();

  HV *parammap = classmeta->parammap;

  HE *he;
  if((he = hv_fetch_ent(parammap, paramname, 0, 0))) {
    ParamMeta *colliding_parammeta = (ParamMeta *)HeVAL(he);
    if(colliding_parammeta->slot->class != classmeta)
      croak("Already have a named constructor parameter called '%" SVf "' inherited from %" SVf,
        SVfARG(paramname), SVfARG(colliding_parammeta->slot->class->name));
    else
      croak("Already have a named constructor parameter called '%" SVf "'", SVfARG(paramname));
  }

  ParamMeta *parammeta;
  Newx(parammeta, 1, struct ParamMeta);

  parammeta->name = SvREFCNT_inc(paramname);
  parammeta->slot = slotmeta;
  parammeta->slotix = slotmeta->slotix;

  hv_store_ent(parammap, paramname, (SV *)parammeta, 0);
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

  if(value && (!SvPOK(value) || !SvCUR(value)))
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

    SV *hookdata = value;

    if(reg->funcs->apply) {
      if(reg->funcs->ver >= 51) {
        if(!(*reg->funcs->apply)(aTHX_ slotmeta, value, &hookdata))
          return;
      }
      else {
        /* ABIVERSION_MINOR 50 apply did not have hookdata_ptr */
        bool (*apply)(pTHX_ SlotMeta *, SV *) = (void *)(reg->funcs->apply);
        if(!(*apply)(aTHX_ slotmeta, value))
          return;
      }
    }

    if(!slotmeta->hooks)
      slotmeta->hooks = newAV();

    struct SlotHook *hook;
    Newx(hook, 1, struct SlotHook);

    hook->funcs = reg->funcs;
    hook->hookdata = hookdata;

    av_push(slotmeta->hooks, (SV *)hook);

    if(value && value != hookdata)
      SvREFCNT_dec(value);

    return;
  }

  croak("Unrecognised slot attribute :%s", name);
}

struct SlotHook *ObjectPad_mop_slot_get_attribute(pTHX_ SlotMeta *slotmeta, const char *name)
{
  HV *hints = GvHV(PL_hintgv);

  /* First, work out what hookfuncs the name maps to */

  SlotAttributeRegistration *reg;
  for(reg = slotattrs; reg; reg = reg->next) {
    if(!strEQ(name, reg->name))
      continue;

    if(reg->funcs->permit_hintkey &&
        (!hints || !hv_fetch(hints, reg->funcs->permit_hintkey, reg->permit_hintkeylen, 0)))
      continue;

    break;
  }

  if(!reg)
    return NULL;

  /* Now lets see if slotmeta has one */

  if(!slotmeta->hooks)
    return NULL;

  U32 hooki;
  for(hooki = 0; hooki < av_count(slotmeta->hooks); hooki++) {
    struct SlotHook *hook = (struct SlotHook *)AvARRAY(slotmeta->hooks)[hooki];

    if(hook->funcs == reg->funcs)
      return hook;
  }

  return NULL;
}

void ObjectPad_mop_slot_seal(pTHX_ SlotMeta *slotmeta)
{
  MOP_SLOT_RUN_HOOKS_NOARGS(slotmeta, seal_slot);
}

/*******************
 * Attribute hooks *
 *******************/

/* :weak */

static void slothook_weak_post_construct(pTHX_ SlotMeta *slotmeta, SV *_hookdata, SV *slot)
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
  .flags            = OBJECTPAD_FLAG_ATTR_NO_VALUE,
  .post_construct   = &slothook_weak_post_construct,
  .gen_accessor_ops = &slothook_weak_gen_accessor,
};

/* :param */

static bool slothook_param_apply(pTHX_ SlotMeta *slotmeta, SV *value, SV **hookdata_ptr)
{
  if(SvPVX(slotmeta->name)[0] != '$')
    croak("Can only add a named constructor parameter for scalar slots");

  char *paramname = value ? SvPVX(value) : NULL;

  U32 flags = 0;
  if(value && SvUTF8(value))
    flags |= SVf_UTF8;

  if(!paramname) {
    paramname = SvPVX(slotmeta->name) + 1;
    if(paramname[0] == '_')
      paramname++;
    if(SvUTF8(slotmeta->name))
      flags |= SVf_UTF8;
  }

  SV *namesv = newSVpvn_flags(paramname, strlen(paramname), flags);
  SAVEFREESV(namesv);

  mop_slot_set_param(slotmeta, namesv);

  return FALSE;
}

static struct SlotHookFuncs slothooks_param = {
  .ver   = OBJECTPAD_ABIVERSION,
  .apply = &slothook_param_apply,
};

/* :reader */

static SV *make_accessor_mnamesv(pTHX_ SlotMeta *slotmeta, SV *mname, const char *fmt)
{
  if(SvPVX(slotmeta->name)[0] != '$')
    /* TODO: A reader for an array or hash slot should also be fine */
    croak("Can only generate accessors for scalar slots");

  /* if(mname && !is_valid_ident_utf8((U8 *)mname))
    croak("Invalid accessor method name");
    */

  if(mname && SvPOK(mname))
    return SvREFCNT_inc(mname);

  const char *pv;
  if(SvPVX(slotmeta->name)[1] == '_')
    pv = SvPVX(slotmeta->name) + 2;
  else
    pv = SvPVX(slotmeta->name) + 1;

  mname = newSVpvf(fmt, pv);
  if(SvUTF8(slotmeta->name))
    SvUTF8_on(mname);
  return mname;
}

static void S_generate_slot_accessor_method(pTHX_ SlotMeta *slotmeta, SV *mname, int type)
{
  ENTER;

  ClassMeta *classmeta = slotmeta->class;

  SV *mname_fq = newSVpvf("%" SVf "::%" SVf, classmeta->name, mname);

  I32 floor_ix = start_subparse(FALSE, 0);
  SAVEFREESV(PL_compcv);

  I32 save_ix = block_start(TRUE);

  extend_pad_vars(classmeta);

  struct AccessorGenerationCtx ctx = { 0 };

  ctx.padix = pad_add_name_sv(slotmeta->name, 0, NULL, NULL);
  intro_my();

  OP *ops = op_append_list(OP_LINESEQ, NULL,
    newSTATEOP(0, NULL, NULL));
  ops = op_append_list(OP_LINESEQ, ops,
    newMETHSTARTOP(0 |
      (classmeta->type == METATYPE_ROLE ? OPf_SPECIAL : 0) |
      (classmeta->repr << 8)));

  ops = op_append_list(OP_LINESEQ, ops,
    make_argcheck_ops((type == ACCESSOR_WRITER) ? 1 : 0, 0, 0, mname_fq));

  ops = op_append_list(OP_LINESEQ, ops,
    newSLOTPADOP(OPpSLOTPAD_SV << 8, ctx.padix, slotmeta->slotix));

  MOP_SLOT_RUN_HOOKS(slotmeta, gen_accessor_ops, type, &ctx);

  if(ctx.bodyop)
    ops = op_append_list(OP_LINESEQ, ops, ctx.bodyop);

  if(ctx.post_bodyops)
    ops = op_append_list(OP_LINESEQ, ops, ctx.post_bodyops);

  if(!ctx.retop)
    croak("Require ctx.retop");
  ops = op_append_list(OP_LINESEQ, ops, ctx.retop);

  SvREFCNT_inc(PL_compcv);
  ops = block_end(save_ix, ops);

  CV *cv = newATTRSUB(floor_ix, newSVOP(OP_CONST, 0, mname_fq), NULL, NULL, ops);
  CvMETHOD_on(cv);

  mop_class_add_method(classmeta, mname);

  LEAVE;
}

static bool slothook_reader_apply(pTHX_ SlotMeta *slotmeta, SV *value, SV **hookdata_ptr)
{
  *hookdata_ptr = make_accessor_mnamesv(aTHX_ slotmeta, value, "%s");
  return TRUE;
}

static void slothook_reader_seal(pTHX_ SlotMeta *slotmeta, SV *hookdata)
{
  S_generate_slot_accessor_method(aTHX_ slotmeta, hookdata, ACCESSOR_READER);
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
  .ver              = OBJECTPAD_ABIVERSION,
  .apply            = &slothook_reader_apply,
  .seal_slot        = &slothook_reader_seal,
  .gen_accessor_ops = &slothook_gen_reader_ops,
};

/* :writer */

static bool slothook_writer_apply(pTHX_ SlotMeta *slotmeta, SV *value, SV **hookdata_ptr)
{
  *hookdata_ptr = make_accessor_mnamesv(aTHX_ slotmeta, value, "set_%s");
  return TRUE;
}

static void slothook_writer_seal(pTHX_ SlotMeta *slotmeta, SV *hookdata)
{
  S_generate_slot_accessor_method(aTHX_ slotmeta, hookdata, ACCESSOR_WRITER);
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
  .ver              = OBJECTPAD_ABIVERSION,
  .apply            = &slothook_writer_apply,
  .seal_slot        = &slothook_writer_seal,
  .gen_accessor_ops = &slothook_gen_writer_ops,
};

/* :mutator */

static void slothook_mutator_seal(pTHX_ SlotMeta *slotmeta, SV *hookdata)
{
  S_generate_slot_accessor_method(aTHX_ slotmeta, hookdata, ACCESSOR_LVALUE_MUTATOR);
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
  .ver              = OBJECTPAD_ABIVERSION,
  .apply            = &slothook_reader_apply, /* generate method name the same as :reader */
  .seal_slot        = &slothook_mutator_seal,
  .gen_accessor_ops = &slothook_gen_mutator_ops,
};

void ObjectPad_register_slot_attribute(pTHX_ const char *name, const struct SlotHookFuncs *funcs)
{
  if(funcs->ver < 50)
    croak("Mismatch in third-party slot attribute ABI version field: module wants %d, we require >= 50\n",
        funcs->ver);
  if(funcs->ver > OBJECTPAD_ABIVERSION)
    croak("Mismatch in third-party slot attribute ABI version field: attribute supplies %d, module wants %d\n",
        funcs->ver, OBJECTPAD_ABIVERSION);

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
