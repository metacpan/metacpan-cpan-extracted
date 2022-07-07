/* vi: set ft=xs : */
#define PERL_NO_GET_CONTEXT

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "object_pad.h"
#include "class.h"
#include "field.h"

#undef register_field_attribute

#include "perl-backcompat.c.inc"
#include "perl-additions.c.inc"
#include "force_list_keeping_pushmark.c.inc"
#include "optree-additions.c.inc"
#include "make_argcheck_ops.c.inc"
#include "newOP_CUSTOM.c.inc"

#if HAVE_PERL_VERSION(5,36,0)
#  define HAVE_OP_WEAKEN
#endif

#define need_PLparser()  ObjectPad__need_PLparser(aTHX)
void ObjectPad__need_PLparser(pTHX); /* in Object/Pad.xs */

FieldMeta *ObjectPad_mop_create_field(pTHX_ SV *fieldname, ClassMeta *classmeta)
{
  FieldMeta *fieldmeta;
  Newx(fieldmeta, 1, FieldMeta);

  assert(classmeta->next_fieldix > -1);

  fieldmeta->name = SvREFCNT_inc(fieldname);
  fieldmeta->class = classmeta;
  fieldmeta->fieldix = classmeta->next_fieldix;
  fieldmeta->defaultsv = NULL;
  fieldmeta->defaultexpr = NULL;
  fieldmeta->paramname = NULL;

  fieldmeta->hooks = NULL;

  return fieldmeta;
}

SV *ObjectPad_mop_field_get_name(pTHX_ FieldMeta *fieldmeta)
{
  return fieldmeta->name;
}

char ObjectPad_mop_field_get_sigil(pTHX_ FieldMeta *fieldmeta)
{
  return (SvPVX(fieldmeta->name))[0];
}

#define mop_field_set_param(fieldmeta, paramname)  S_mop_field_set_param(aTHX_ fieldmeta, paramname)
static void S_mop_field_set_param(pTHX_ FieldMeta *fieldmeta, SV *paramname)
{
  ClassMeta *classmeta = fieldmeta->class;

  if(!classmeta->parammap)
    classmeta->parammap = newHV();

  HV *parammap = classmeta->parammap;

  HE *he;
  if((he = hv_fetch_ent(parammap, paramname, 0, 0))) {
    ParamMeta *colliding_parammeta = (ParamMeta *)HeVAL(he);
    if(colliding_parammeta->field->class != classmeta)
      croak("Already have a named constructor parameter called '%" SVf "' inherited from %" SVf,
        SVfARG(paramname), SVfARG(colliding_parammeta->field->class->name));
    else
      croak("Already have a named constructor parameter called '%" SVf "'", SVfARG(paramname));
  }

  ParamMeta *parammeta;
  Newx(parammeta, 1, struct ParamMeta);

  parammeta->name = SvREFCNT_inc(paramname);
  parammeta->field = fieldmeta;
  parammeta->fieldix = fieldmeta->fieldix;

  fieldmeta->paramname = SvREFCNT_inc(paramname);

  hv_store_ent(parammap, paramname, (SV *)parammeta, 0);
}

SV *ObjectPad_mop_field_get_default_sv(pTHX_ FieldMeta *fieldmeta)
{
  return fieldmeta->defaultsv;
}

void ObjectPad_mop_field_set_default_sv(pTHX_ FieldMeta *fieldmeta, SV *sv)
{
  if(fieldmeta->defaultsv)
    SvREFCNT_dec(fieldmeta->defaultsv);

  fieldmeta->defaultsv = sv;
}

typedef struct FieldAttributeRegistration FieldAttributeRegistration;

struct FieldAttributeRegistration {
  FieldAttributeRegistration *next;

  const char *name;
  STRLEN permit_hintkeylen;

  const struct FieldHookFuncs *funcs;
  void *funcdata;
};

static FieldAttributeRegistration *fieldattrs = NULL;

static void register_field_attribute(const char *name, const struct FieldHookFuncs *funcs, void *funcdata)
{
  FieldAttributeRegistration *reg;
  Newx(reg, 1, struct FieldAttributeRegistration);

  reg->name     = name;
  reg->funcs    = funcs;
  reg->funcdata = funcdata;

  if(funcs->permit_hintkey)
    reg->permit_hintkeylen = strlen(funcs->permit_hintkey);
  else
    reg->permit_hintkeylen = 0;

  reg->next = fieldattrs;
  fieldattrs = reg;
}

void ObjectPad_mop_field_apply_attribute(pTHX_ FieldMeta *fieldmeta, const char *name, SV *value)
{
  HV *hints = GvHV(PL_hintgv);

  if(value && (!SvPOK(value) || !SvCUR(value)))
    value = NULL;

  FieldAttributeRegistration *reg;
  for(reg = fieldattrs; reg; reg = reg->next) {
    if(!strEQ(name, reg->name))
      continue;

    if(reg->funcs->permit_hintkey &&
       (!hints || !hv_fetch(hints, reg->funcs->permit_hintkey, reg->permit_hintkeylen, 0)))
      continue;

    break;
  }

  if(!reg)
    croak("Unrecognised field attribute :%s", name);

  if((reg->funcs->flags & OBJECTPAD_FLAG_ATTR_NO_VALUE) && value)
    croak("Attribute :%s does not permit a value", name);
  if((reg->funcs->flags & OBJECTPAD_FLAG_ATTR_MUST_VALUE) && !value)
    croak("Attribute :%s requires a value", name);

  SV *hookdata = value;

  if(reg->funcs->apply) {
    if(!(*reg->funcs->apply)(aTHX_ fieldmeta, value, &hookdata, reg->funcdata))
      return;
  }

  if(hookdata && hookdata == value)
    SvREFCNT_inc(hookdata);

  if(!fieldmeta->hooks)
    fieldmeta->hooks = newAV();

  struct FieldHook *hook;
  Newx(hook, 1, struct FieldHook);

  hook->funcs = reg->funcs;
  hook->hookdata = hookdata;
  hook->funcdata = reg->funcdata;

  av_push(fieldmeta->hooks, (SV *)hook);
}

struct FieldHook *ObjectPad_mop_field_get_attribute(pTHX_ FieldMeta *fieldmeta, const char *name)
{
  COPHH *cophh = CopHINTHASH_get(PL_curcop);

  /* First, work out what hookfuncs the name maps to */

  FieldAttributeRegistration *reg;
  for(reg = fieldattrs; reg; reg = reg->next) {
    if(!strEQ(name, reg->name))
      continue;

    if(reg->funcs->permit_hintkey &&
        !cophh_fetch_pvn(cophh, reg->funcs->permit_hintkey, reg->permit_hintkeylen, 0, 0))
      continue;

    break;
  }

  if(!reg)
    return NULL;

  /* Now lets see if fieldmeta has one */

  if(!fieldmeta->hooks)
    return NULL;

  U32 hooki;
  for(hooki = 0; hooki < av_count(fieldmeta->hooks); hooki++) {
    struct FieldHook *hook = (struct FieldHook *)AvARRAY(fieldmeta->hooks)[hooki];

    if(hook->funcs == reg->funcs)
      return hook;
  }

  return NULL;
}

AV *ObjectPad_mop_field_get_attribute_values(pTHX_ FieldMeta *fieldmeta, const char *name)
{
  COPHH *cophh = CopHINTHASH_get(PL_curcop);

  /* First, work out what hookfuncs the name maps to */

  FieldAttributeRegistration *reg;
  for(reg = fieldattrs; reg; reg = reg->next) {
    if(!strEQ(name, reg->name))
      continue;

    if(reg->funcs->permit_hintkey &&
        !cophh_fetch_pvn(cophh, reg->funcs->permit_hintkey, reg->permit_hintkeylen, 0, 0))
      continue;

    break;
  }

  if(!reg)
    return NULL;

  /* Now lets see if fieldmeta has one */

  if(!fieldmeta->hooks)
    return NULL;

  AV *ret = NULL;

  U32 hooki;
  for(hooki = 0; hooki < av_count(fieldmeta->hooks); hooki++) {
    struct FieldHook *hook = (struct FieldHook *)AvARRAY(fieldmeta->hooks)[hooki];

    if(hook->funcs != reg->funcs)
      continue;

    if(!ret)
      ret = newAV();

    av_push(ret, newSVsv(hook->hookdata));
  }

  return ret;
}

void ObjectPad_mop_field_seal(pTHX_ FieldMeta *fieldmeta)
{
  MOP_FIELD_RUN_HOOKS_NOARGS(fieldmeta, seal);
}

/*******************
 * Attribute hooks *
 *******************/

/* :weak */

static void fieldhook_weak_post_construct(pTHX_ FieldMeta *fieldmeta, SV *_hookdata, void *_funcdata, SV *field)
{
  sv_rvweaken(field);
}

#ifndef HAVE_OP_WEAKEN
static XOP xop_weaken;
static OP *pp_weaken(pTHX)
{
  dSP;
  sv_rvweaken(POPs);
  return NORMAL;
}
#endif

static void fieldhook_weak_gen_accessor(pTHX_ FieldMeta *fieldmeta, SV *hookdata, void *_funcdata, enum AccessorType type, struct AccessorGenerationCtx *ctx)
{
  if(type != ACCESSOR_WRITER)
    return;

  ctx->post_bodyops = op_append_list(OP_LINESEQ, ctx->post_bodyops,
#ifdef HAVE_OP_WEAKEN
    newUNOP(OP_WEAKEN, 0,
#else
    newUNOP_CUSTOM(&pp_weaken, 0,
#endif
      newPADxVOP(OP_PADSV, 0, ctx->padix)));
}

static struct FieldHookFuncs fieldhooks_weak = {
  .flags            = OBJECTPAD_FLAG_ATTR_NO_VALUE,
  .post_construct   = &fieldhook_weak_post_construct,
  .gen_accessor_ops = &fieldhook_weak_gen_accessor,
};

/* :param */

static bool fieldhook_param_apply(pTHX_ FieldMeta *fieldmeta, SV *value, SV **hookdata_ptr, void *_funcdata)
{
  if(SvPVX(fieldmeta->name)[0] != '$')
    croak("Can only add a named constructor parameter for scalar fields");

  char *paramname = value ? SvPVX(value) : NULL;

  U32 flags = 0;
  if(value && SvUTF8(value))
    flags |= SVf_UTF8;

  if(!paramname) {
    paramname = SvPVX(fieldmeta->name) + 1;
    if(paramname[0] == '_')
      paramname++;
    if(SvUTF8(fieldmeta->name))
      flags |= SVf_UTF8;
  }

  SV *namesv = newSVpvn_flags(paramname, strlen(paramname), flags);

  mop_field_set_param(fieldmeta, namesv);

  *hookdata_ptr = namesv;
  return TRUE;
}

static struct FieldHookFuncs fieldhooks_param = {
  .ver   = OBJECTPAD_ABIVERSION,
  .apply = &fieldhook_param_apply,
};

/* :reader */

static SV *make_accessor_mnamesv(pTHX_ FieldMeta *fieldmeta, SV *mname, const char *fmt)
{
  /* if(mname && !is_valid_ident_utf8((U8 *)mname))
    croak("Invalid accessor method name");
    */

  if(mname && SvPOK(mname))
    return SvREFCNT_inc(mname);

  const char *pv;
  if(SvPVX(fieldmeta->name)[1] == '_')
    pv = SvPVX(fieldmeta->name) + 2;
  else
    pv = SvPVX(fieldmeta->name) + 1;

  mname = newSVpvf(fmt, pv);
  if(SvUTF8(fieldmeta->name))
    SvUTF8_on(mname);
  return mname;
}

static void S_generate_field_accessor_method(pTHX_ FieldMeta *fieldmeta, SV *mname, int type)
{
  ENTER;

  ClassMeta *classmeta = fieldmeta->class;
  char sigil = SvPVX(fieldmeta->name)[0];

  SV *mname_fq = newSVpvf("%" SVf "::%" SVf, classmeta->name, mname);

  if(PL_curstash != classmeta->stash) {
    /* RT141599 */
    SAVESPTR(PL_curstash);
    PL_curstash = classmeta->stash;
  }

  need_PLparser();

  I32 floor_ix = start_subparse(FALSE, 0);
  SAVEFREESV(PL_compcv);

  I32 save_ix = block_start(TRUE);

  extend_pad_vars(classmeta);

  struct AccessorGenerationCtx ctx = { 0 };

  ctx.padix = pad_add_name_sv(fieldmeta->name, 0, NULL, NULL);
  intro_my();

  OP *ops = op_append_list(OP_LINESEQ, NULL,
    newSTATEOP(0, NULL, NULL));
  ops = op_append_list(OP_LINESEQ, ops,
    newMETHSTARTOP(0 |
      (classmeta->type == METATYPE_ROLE ? OPf_SPECIAL : 0) |
      (classmeta->repr << 8)));

  int req_args = 0;
  int opt_args = 0;
  int slurpy_arg = 0;

  switch(type) {
    case ACCESSOR_WRITER:
      if(sigil == '$')
        req_args = 1;
      else
        slurpy_arg = sigil;
      break;
    case ACCESSOR_COMBINED:
      opt_args = 1;
      break;
  }

  ops = op_append_list(OP_LINESEQ, ops,
    make_argcheck_ops(req_args, opt_args, slurpy_arg, mname_fq));

  U32 flags = 0;

  switch(sigil) {
    case '$': flags = OPpFIELDPAD_SV << 8; break;
    case '@': flags = OPpFIELDPAD_AV << 8; break;
    case '%': flags = OPpFIELDPAD_HV << 8; break;
  }

  ops = op_append_list(OP_LINESEQ, ops,
    newFIELDPADOP(flags, ctx.padix, fieldmeta->fieldix));

  MOP_FIELD_RUN_HOOKS(fieldmeta, gen_accessor_ops, type, &ctx);

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

static bool fieldhook_reader_apply(pTHX_ FieldMeta *fieldmeta, SV *value, SV **hookdata_ptr, void *_funcdata)
{
  *hookdata_ptr = make_accessor_mnamesv(aTHX_ fieldmeta, value, "%s");
  return TRUE;
}

static void fieldhook_reader_seal(pTHX_ FieldMeta *fieldmeta, SV *hookdata, void *_funcdata)
{
  S_generate_field_accessor_method(aTHX_ fieldmeta, hookdata, ACCESSOR_READER);
}

static void fieldhook_gen_reader_ops(pTHX_ FieldMeta *fieldmeta, SV *hookdata, void *_funcdata, enum AccessorType type, struct AccessorGenerationCtx *ctx)
{
  if(type != ACCESSOR_READER)
    return;

  OPCODE optype = 0;

  switch(SvPVX(fieldmeta->name)[0]) {
    case '$': optype = OP_PADSV; break;
    case '@': optype = OP_PADAV; break;
    case '%': optype = OP_PADHV; break;
  }

  ctx->retop = newLISTOP(OP_RETURN, 0,
    newOP(OP_PUSHMARK, 0),
    newPADxVOP(optype, 0, ctx->padix));
}

static struct FieldHookFuncs fieldhooks_reader = {
  .ver              = OBJECTPAD_ABIVERSION,
  .apply            = &fieldhook_reader_apply,
  .seal             = &fieldhook_reader_seal,
  .gen_accessor_ops = &fieldhook_gen_reader_ops,
};

/* :writer */

static bool fieldhook_writer_apply(pTHX_ FieldMeta *fieldmeta, SV *value, SV **hookdata_ptr, void *_funcdata)
{
  *hookdata_ptr = make_accessor_mnamesv(aTHX_ fieldmeta, value, "set_%s");
  return TRUE;
}

static void fieldhook_writer_seal(pTHX_ FieldMeta *fieldmeta, SV *hookdata, void *_funcdata)
{
  S_generate_field_accessor_method(aTHX_ fieldmeta, hookdata, ACCESSOR_WRITER);
}

static void fieldhook_gen_writer_ops(pTHX_ FieldMeta *fieldmeta, SV *hookdata, void *_funcdata, enum AccessorType type, struct AccessorGenerationCtx *ctx)
{
  if(type != ACCESSOR_WRITER)
    return;

  switch(SvPVX(fieldmeta->name)[0]) {
    case '$':
      ctx->bodyop = newBINOP(OP_SASSIGN, 0,
        newOP(OP_SHIFT, 0),
        newPADxVOP(OP_PADSV, 0, ctx->padix));
      break;

    case '@':
      ctx->bodyop = newBINOP(OP_AASSIGN, 0,
        force_list_keeping_pushmark(newUNOP(OP_RV2AV, 0, newGVOP(OP_GV, 0, PL_defgv))),
        force_list_keeping_pushmark(newPADxVOP(OP_PADAV, OPf_MOD|OPf_REF, ctx->padix)));
      break;

    case '%':
      ctx->bodyop = newBINOP(OP_AASSIGN, 0,
        force_list_keeping_pushmark(newUNOP(OP_RV2AV, 0, newGVOP(OP_GV, 0, PL_defgv))),
        force_list_keeping_pushmark(newPADxVOP(OP_PADHV, OPf_MOD|OPf_REF, ctx->padix)));
      break;
  }

  ctx->retop = newLISTOP(OP_RETURN, 0,
    newOP(OP_PUSHMARK, 0),
    newPADxVOP(OP_PADSV, 0, PADIX_SELF));
}

static struct FieldHookFuncs fieldhooks_writer = {
  .ver              = OBJECTPAD_ABIVERSION,
  .apply            = &fieldhook_writer_apply,
  .seal             = &fieldhook_writer_seal,
  .gen_accessor_ops = &fieldhook_gen_writer_ops,
};

/* :mutator */

static bool fieldhook_mutator_apply(pTHX_ FieldMeta *fieldmeta, SV *value, SV **hookdata_ptr, void *_funcdata)
{
  if(SvPVX(fieldmeta->name)[0] != '$')
    /* TODO: A reader for an array or hash field should also be fine */
    croak("Can only generate accessors for scalar fields");

  *hookdata_ptr = make_accessor_mnamesv(aTHX_ fieldmeta, value, "%s");
  return TRUE;
}

static void fieldhook_mutator_seal(pTHX_ FieldMeta *fieldmeta, SV *hookdata, void *_funcdata)
{
  S_generate_field_accessor_method(aTHX_ fieldmeta, hookdata, ACCESSOR_LVALUE_MUTATOR);
}

static void fieldhook_gen_mutator_ops(pTHX_ FieldMeta *fieldmeta, SV *hookdata, void *_funcdata, enum AccessorType type, struct AccessorGenerationCtx *ctx)
{
  if(type != ACCESSOR_LVALUE_MUTATOR)
    return;

  CvLVALUE_on(PL_compcv);

  ctx->retop = newLISTOP(OP_RETURN, 0,
    newOP(OP_PUSHMARK, 0),
    newPADxVOP(OP_PADSV, 0, ctx->padix));
}

static struct FieldHookFuncs fieldhooks_mutator = {
  .ver              = OBJECTPAD_ABIVERSION,
  .apply            = &fieldhook_mutator_apply,
  .seal             = &fieldhook_mutator_seal,
  .gen_accessor_ops = &fieldhook_gen_mutator_ops,
};

/* :accessor */

static void fieldhook_accessor_seal(pTHX_ FieldMeta *fieldmeta, SV *hookdata, void *_funcdata)
{
  S_generate_field_accessor_method(aTHX_ fieldmeta, hookdata, ACCESSOR_COMBINED);
}

static void fieldhook_gen_accessor_ops(pTHX_ FieldMeta *fieldmeta, SV *hookdata, void *_funcdata, enum AccessorType type, struct AccessorGenerationCtx *ctx)
{
  if(type != ACCESSOR_COMBINED)
    return;

  /* $field = shift if @_ */
  ctx->bodyop = newLOGOP(OP_AND, 0,
    /* scalar @_ */
    op_contextualize(newUNOP(OP_RV2AV, 0, newGVOP(OP_GV, 0, PL_defgv)), G_SCALAR),
    /* $field = shift */
    newBINOP(OP_SASSIGN, 0,
      newOP(OP_SHIFT, 0),
      newPADxVOP(OP_PADSV, 0, ctx->padix)));

  ctx->retop = newLISTOP(OP_RETURN, 0,
    newOP(OP_PUSHMARK, 0),
    newPADxVOP(OP_PADSV, 0, ctx->padix));
}

static struct FieldHookFuncs fieldhooks_accessor = {
  .ver              = OBJECTPAD_ABIVERSION,
  .apply            = &fieldhook_mutator_apply, /* generate method name the same as :mutator */
  .seal             = &fieldhook_accessor_seal,
  .gen_accessor_ops = &fieldhook_gen_accessor_ops,
};

void ObjectPad_register_field_attribute(pTHX_ const char *name, const struct FieldHookFuncs *funcs, void *funcdata)
{
  if(funcs->ver < 57)
    croak("Mismatch in third-party field attribute ABI version field: module wants %d, we require >= 57\n",
        funcs->ver);
  if(funcs->ver > OBJECTPAD_ABIVERSION)
    croak("Mismatch in third-party field attribute ABI version field: attribute supplies %d, module wants %d\n",
        funcs->ver, OBJECTPAD_ABIVERSION);

  if(!name || !(name[0] >= 'A' && name[0] <= 'Z'))
    croak("Third-party field attribute names must begin with a capital letter");

  if(!funcs->permit_hintkey)
    croak("Third-party field attributes require a permit hinthash key");

  register_field_attribute(name, funcs, funcdata);
}

void ObjectPad__boot_fields(pTHX)
{
#ifndef HAVE_OP_WEAKEN
  XopENTRY_set(&xop_weaken, xop_name, "weaken");
  XopENTRY_set(&xop_weaken, xop_desc, "weaken an RV");
  XopENTRY_set(&xop_weaken, xop_class, OA_UNOP);
  Perl_custom_op_register(aTHX_ &pp_weaken, &xop_weaken);
#endif

  register_field_attribute("weak",     &fieldhooks_weak,     NULL);
  register_field_attribute("param",    &fieldhooks_param,    NULL);
  register_field_attribute("reader",   &fieldhooks_reader,   NULL);
  register_field_attribute("writer",   &fieldhooks_writer,   NULL);
  register_field_attribute("mutator",  &fieldhooks_mutator,  NULL);
  register_field_attribute("accessor", &fieldhooks_accessor, NULL);
}
