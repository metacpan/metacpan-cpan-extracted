/* vi: set ft=xs : */
#define PERL_NO_GET_CONTEXT

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "perl-backcompat.c.inc"
#include "perl-additions.c.inc"
#include "force_list_keeping_pushmark.c.inc"
#include "optree-additions.c.inc"
#include "make_argcheck_ops.c.inc"
#include "newOP_CUSTOM.c.inc"
#include "OP_HELEMEXISTSOR.c.inc"

#include "object_pad.h"
#include "class.h"
#include "field.h"

#undef register_field_attribute

#if HAVE_PERL_VERSION(5,36,0)
#  define HAVE_OP_WEAKEN
#endif

#define need_PLparser()  ObjectPad__need_PLparser(aTHX)
void ObjectPad__need_PLparser(pTHX); /* in Object/Pad.xs */

FieldMeta *ObjectPad_mop_create_field(pTHX_ SV *fieldname, FIELDOFFSET fieldix, ClassMeta *classmeta)
{
  FieldMeta *fieldmeta;
  Newx(fieldmeta, 1, FieldMeta);

  assert(fieldix > -1);

  *fieldmeta = (FieldMeta){
    LINNET_INIT(LINNET_VAL_FIELDMETA)
    .name      = SvREFCNT_inc(fieldname),
    .is_direct = true,
    .class     = classmeta,
    .fieldix   = fieldix,
  };

  return fieldmeta;
}

ClassMeta *ObjectPad_mop_field_get_class(pTHX_ FieldMeta *fieldmeta)
{
  return fieldmeta->class;
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

  check_colliding_param(classmeta, paramname);

  ParamMeta *parammeta;
  Newx(parammeta, 1, struct ParamMeta);

  *parammeta = (struct ParamMeta){
    LINNET_INIT(LINNET_VAL_PARAMMETA)
    .name  = SvREFCNT_inc(paramname),
    .class = classmeta,
    .type  = PARAM_FIELD,
    .field.fieldmeta = fieldmeta,
    .field.fieldix   = fieldmeta->fieldix,
  };

  fieldmeta->paramname = SvREFCNT_inc(paramname);

  hv_store_ent(classmeta->parammap, paramname, (SV *)parammeta, 0);
}

SV *ObjectPad_mop_field_get_default_sv(pTHX_ FieldMeta *fieldmeta)
{
  if(!fieldmeta->defaultexpr)
    return NULL;

  OP *o = fieldmeta->defaultexpr;

  switch(mop_field_get_sigil(fieldmeta)) {
    case '$':
      break;

    case '@':
      if(o->op_type != OP_RV2AV)
        return NULL;
      o = cUNOPo->op_first;
      break;

    case '%':
      if(o->op_type != OP_RV2HV)
        return NULL;
      o = cUNOPo->op_first;
      break;
  }

  if(o->op_type != OP_CUSTOM || o->op_ppaddr != PL_ppaddr[OP_CONST])
    return NULL;

  return cSVOPo_sv;
}

void ObjectPad_mop_field_set_default_sv(pTHX_ FieldMeta *fieldmeta, SV *sv)
{
  if(fieldmeta->defaultexpr)
    op_free(fieldmeta->defaultexpr);

  /* An OP_CONST whose op_type is OP_CUSTOM. This way we avoid the opchecker
   * and finalizer doing bad things to our defaultsv SV by setting it
   * SvREADONLY_on() */
  OP *valueop = newSVOP_CUSTOM(PL_ppaddr[OP_CONST], 0, sv);

  switch(mop_field_get_sigil(fieldmeta)) {
    case '$':
      fieldmeta->defaultexpr = valueop;
      break;

    case '@':
      assert(SvROK(sv) && SvTYPE(SvRV(sv)) == SVt_PVAV);
      fieldmeta->defaultexpr = newUNOP(OP_RV2AV, 0, valueop);
      break;

    case '%':
      assert(SvROK(sv) && SvTYPE(SvRV(sv)) == SVt_PVHV);
      fieldmeta->defaultexpr = newUNOP(OP_RV2HV, 0, valueop);
      break;
  }
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

  *reg = (struct FieldAttributeRegistration){
    .name     = name,
    .funcs    = funcs,
    .funcdata = funcdata,
  };

  if(funcs->permit_hintkey)
    reg->permit_hintkeylen = strlen(funcs->permit_hintkey);
  else
    reg->permit_hintkeylen = 0;

  reg->next = fieldattrs;
  fieldattrs = reg;
}

enum {
  APPLY_ATTRIBUTE_PARSE             = (1<<0),
  APPLY_ATTRIBUTE_USE_RUNTIME_HINTS = (1<<1),
};

static void apply_attribute(pTHX_ FieldMeta *fieldmeta, const char *name, SV *value, U8 flags)
{
  bool use_runtime_hints = flags & APPLY_ATTRIBUTE_USE_RUNTIME_HINTS;
  HV *hints = GvHV(PL_hintgv);
  COPHH *cophh = CopHINTHASH_get(PL_curcop);

  if(value && (!SvPOK(value) || !SvCUR(value)))
    value = NULL;

  FieldAttributeRegistration *reg;
  for(reg = fieldattrs; reg; reg = reg->next) {
    if(!strEQ(name, reg->name))
      continue;

    if(reg->funcs->permit_hintkey) {
      if(use_runtime_hints) {
        if(!cophh_fetch_pvn(cophh, reg->funcs->permit_hintkey, reg->permit_hintkeylen, 0, 0))
          continue;
      }
      else {
        if(!hints || !hv_fetch(hints, reg->funcs->permit_hintkey, reg->permit_hintkeylen, 0))
          continue;
      }
    }

    break;
  }

  if(!reg)
    croak("Unrecognised field attribute :%s", name);

  if((reg->funcs->flags & OBJECTPAD_FLAG_ATTR_NO_VALUE) && value)
    croak("Attribute :%s does not permit a value", name);
  if((reg->funcs->flags & OBJECTPAD_FLAG_ATTR_MUST_VALUE) && !value)
    croak("Attribute :%s requires a value", name);

  if((flags & APPLY_ATTRIBUTE_PARSE) && reg->funcs->parse)
    value = (*reg->funcs->parse)(aTHX_ fieldmeta, value, reg->funcdata);

  SV *attrdata = value;

  if(reg->funcs->apply) {
    if(!(*reg->funcs->apply)(aTHX_ fieldmeta, value, &attrdata, reg->funcdata))
      return;
  }

  if(attrdata && attrdata == value)
    SvREFCNT_inc(attrdata);

  if(!fieldmeta->hooks)
    fieldmeta->hooks = newAV();

  struct FieldHook *hook;
  Newx(hook, 1, struct FieldHook);

  *hook = (struct FieldHook){
    .funcs    = reg->funcs,
    .attrdata = attrdata,
    .funcdata = reg->funcdata,
  };

  av_push(fieldmeta->hooks, (SV *)hook);
}

void ObjectPad_mop_field_apply_attribute(pTHX_ FieldMeta *fieldmeta, const char *name, SV *value)
{
  bool runtime = !IN_PERL_COMPILETIME;
  apply_attribute(aTHX_ fieldmeta, name, value, runtime ? APPLY_ATTRIBUTE_USE_RUNTIME_HINTS : 0);
}

void ObjectPad_mop_field_parse_and_apply_attribute(pTHX_ FieldMeta *fieldmeta, const char *name, SV *value)
{
  apply_attribute(aTHX_ fieldmeta, name, value, APPLY_ATTRIBUTE_PARSE);
}

static FieldAttributeRegistration *get_active_registration(pTHX_ const char *name)
{
  COPHH *cophh = CopHINTHASH_get(PL_curcop);

  for(FieldAttributeRegistration *reg = fieldattrs; reg; reg = reg->next) {
    if(!strEQ(name, reg->name))
      continue;

    if(reg->funcs->permit_hintkey &&
        !cophh_fetch_pvn(cophh, reg->funcs->permit_hintkey, reg->permit_hintkeylen, 0, 0))
      continue;

    return reg;
  }

  return NULL;
}

struct FieldHook *ObjectPad_mop_field_get_attribute(pTHX_ FieldMeta *fieldmeta, const char *name)
{
  /* First, work out what hookfuncs the name maps to */
  FieldAttributeRegistration *reg = get_active_registration(aTHX_ name);

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
  /* First, work out what hookfuncs the name maps to */
  FieldAttributeRegistration *reg = get_active_registration(aTHX_ name);

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

    av_push(ret, newSVsv(hook->attrdata));
  }

  return ret;
}

SV *ObjectPad_get_obj_fieldsv(pTHX_ SV *self, FieldMeta *fieldmeta)
{
  SV *fieldstore;
  FIELDOFFSET fieldix;

  ClassMeta *classmeta = fieldmeta->class;

  assert(SvROK(self));
  assert(SvOBJECT(SvRV(self)));

  if(classmeta->type == METATYPE_ROLE) {
    HV *objstash = SvSTASH(SvRV(self));
    const char *key = HvNAME(objstash);
    STRLEN klen = HvNAMELEN(objstash);
    if(HvNAMEUTF8(objstash))
      klen = -klen;

    assert(key);
    SV **svp = hv_fetch(classmeta->role.applied_classes, key, klen, 0);
    if(!svp)
      croak("Cannot fetch role field value from a non-applied instance");

    RoleEmbedding *embedding = MUST_ROLEEMBEDDING(*svp);

    fieldstore = get_obj_fieldstore(self, embedding->classmeta->repr, true);
    fieldix = fieldmeta->fieldix + embedding->offset;
  }
  else {
    const char *stashname = HvNAME(classmeta->stash);

    if(!stashname || !sv_derived_from(self, stashname))
      croak("Cannot fetch field value from a non-derived instance");

    fieldstore = get_obj_fieldstore(self, classmeta->repr, true);
    fieldix = fieldmeta->fieldix;
  }

  if(fieldix > fieldstore_maxfield(fieldstore))
    croak("ARGH: instance does not have a field at index %ld", (long int)fieldix);

  SV *sv = fieldstore_fields(fieldstore)[fieldix];

  return sv;
}

static OP *pp_fieldsv(pTHX)
{
  dSP;
  FIELDOFFSET fieldix = PL_op->op_targ;
  if(PL_op->op_flags & OPf_SPECIAL) {
    RoleEmbedding *embedding = get_embedding_from_pad();

    if(embedding && embedding != &ObjectPad__embedding_standalone) {
      fieldix += embedding->offset;
    }
  }

  SV *fieldstore = PAD_SVl(PADIX_FIELDS);

  SV *fieldsv = fieldstore_fields(fieldstore)[fieldix];

  EXTEND(SP, 1);
  PUSHs(fieldsv);

  RETURN;
}

#define newFIELDSVOP(flags, fieldix)  S_newFIELDSVOP(aTHX_ flags, fieldix)
static OP *S_newFIELDSVOP(pTHX_ U32 flags, FIELDOFFSET fieldix)
{
  OP *o = newOP_CUSTOM(&pp_fieldsv, flags);
  o->op_targ = fieldix;
  return o;
}

#define gen_field_init_op(fieldmeta)  S_gen_field_init_op(aTHX_ fieldmeta)
static OP *S_gen_field_init_op(pTHX_ FieldMeta *fieldmeta)
{
  ClassMeta *classmeta = fieldmeta->class;
  U8 opf_special_if_role = (classmeta->type == METATYPE_ROLE) ? OPf_SPECIAL : 0;

  char sigil = SvPV_nolen(fieldmeta->name)[0];
  OP *op = NULL;

  switch(sigil) {
    case '$':
    {
      OP *valueop = NULL;

      if(fieldmeta->defaultexpr) {
        valueop = fieldmeta->defaultexpr;
      }

      if(fieldmeta->paramname) {
        SV *paramname = fieldmeta->paramname;

        if(!valueop)
          valueop = newop_croak_from_constructor(
            newSVpvf("Required parameter '%" SVf "' is missing for %" SVf " constructor",
              SVfARG(paramname), SVfARG(classmeta->name)));

        OP *helemop =
          newBINOP(OP_HELEM, 0,
            newPADxVOP(OP_PADHV, OPf_REF, PADIX_PARAMS),
            newSVOP(OP_CONST, 0, SvREFCNT_inc(paramname)));

        if(fieldmeta->def_if_undef)
          /* delete $params{$paramname} // valueop */
          valueop = newLOGOP(OP_DOR, 0, newUNOP(OP_DELETE, 0, helemop), valueop);
        else if(fieldmeta->def_if_false)
          /* delete $params{$paramname} || valueop */
          valueop = newLOGOP(OP_OR, 0, newUNOP(OP_DELETE, 0, helemop), valueop);
        else
          /* Equivalent of
           *   exists $params{$paramname} ? delete $params{$paramname} : valueop; */
          valueop = newHELEMEXISTSOROP(OPpHELEMEXISTSOR_DELETE << 8, helemop, valueop);
      }

      if(valueop) {
        op = newBINOP(OP_SASSIGN, 0,
          valueop,
          /* $fields[$idx] */
          newFIELDSVOP(OPf_MOD | opf_special_if_role, fieldmeta->fieldix));

        /* Can't just
         *   MOP_FIELD_RUN_HOOKS(fieldmeta, gen_valueassert_op, ...)
         * because of collecting up the return values
         */
        U32 hooki;
        for(hooki = 0; fieldmeta->hooks && hooki < av_count(fieldmeta->hooks); hooki++) {
          struct FieldHook *h = (struct FieldHook *)AvARRAY(fieldmeta->hooks)[hooki];         \
          if(!h->funcs->gen_valueassert_op)
            continue;

          OP *assertop = (*h->funcs->gen_valueassert_op)(aTHX_ fieldmeta, h->attrdata, h->funcdata,
            newFIELDSVOP(opf_special_if_role, fieldmeta->fieldix));

          if(!assertop)
            continue;

          op = op_append_elem(OP_LINESEQ, op,
            assertop);
        }
      }

      break;
    }
    case '@':
    case '%':
    {
      OP *valueop = NULL;
      U16 coerceop = (sigil == '%') ? OP_RV2HV : OP_RV2AV;

      if(fieldmeta->defaultexpr) {
        valueop = fieldmeta->defaultexpr;
      }

      if(valueop) {
        /* $fields[$idx]->@* or ->%* */
        OP *lhs = force_list_keeping_pushmark(newUNOP(coerceop, OPf_MOD|OPf_REF,
                    newFIELDSVOP(opf_special_if_role, fieldmeta->fieldix)));

        op = newBINOP(OP_AASSIGN, 0,
            force_list_keeping_pushmark(valueop),
            lhs);
      }
      break;
    }

    default:
      croak("ARGH: not sure how to handle a field sigil %c\n", sigil);
  }

  return op;
}

void ObjectPad_mop_field_seal(pTHX_ FieldMeta *fieldmeta)
{
  MOP_FIELD_RUN_HOOKS_NOARGS(fieldmeta, seal);

  need_PLparser();

  ClassMeta *classmeta = fieldmeta->class;

  OP *lines = classmeta->initfields_lines;

  /* TODO: grab a COP at the initexpr time */
  lines = op_append_elem(OP_LINESEQ, lines, newSTATEOP(0, NULL, NULL));
  lines = op_append_elem(OP_LINESEQ, lines, gen_field_init_op(fieldmeta));

  classmeta->initfields_lines = lines;
}

/*******************
 * Attribute hooks *
 *******************/

/* :weak */

static void fieldhook_weak_post_construct(pTHX_ FieldMeta *fieldmeta, SV *_attrdata, void *_funcdata, SV *field)
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

static void fieldhook_weak_gen_accessor(pTHX_ FieldMeta *fieldmeta, SV *attrdata, void *_funcdata, enum AccessorType type, struct AccessorGenerationCtx *ctx)
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

static bool fieldhook_param_apply(pTHX_ FieldMeta *fieldmeta, SV *value, SV **attrdata_ptr, void *_funcdata)
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

  *attrdata_ptr = namesv;
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
  U8 opf_special_if_role = (classmeta->type == METATYPE_ROLE ? OPf_SPECIAL : 0);
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

  PADOFFSET padix = pad_add_name_sv(fieldmeta->name, 0, NULL, NULL);
  intro_my();

  OP *ops = op_append_list(OP_LINESEQ, NULL,
    newSTATEOP(0, NULL, NULL));
  OP *methstartop;
  ops = op_append_list(OP_LINESEQ, ops,
    methstartop = newMETHSTARTOP(0 |
      opf_special_if_role |
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

  FIELDOFFSET fieldix = fieldmeta->fieldix;

  U8 private = 0;

  switch(sigil) {
    case '$': private = OPpFIELDPAD_SV; break;
    case '@': private = OPpFIELDPAD_AV; break;
    case '%': private = OPpFIELDPAD_HV; break;
  }

#ifdef METHSTART_CONTAINS_FIELD_BINDINGS
  {
    UNOP_AUX_item *aux;
    Newx(aux, 2 + 1*2, UNOP_AUX_item);
    cUNOP_AUXx(methstartop)->op_aux = aux;

    (aux++)->uv = 1;       /* fieldcount */
    (aux++)->uv = fieldix; /* max_fieldix */

    (aux++)->uv = padix;
    (aux++)->uv = ((UV)private << FIELDIX_TYPE_SHIFT) | fieldix;
  }
#else
  {
    ops = op_append_list(OP_LINESEQ, ops,
      newFIELDPADOP(private << 8 | opf_special_if_role, padix, fieldix));
  }
#endif

  /* Generate the basic ops here so the ordering doesn't matter if other
   * attributes want to modify these */

  struct AccessorGenerationCtx ctx = {
    .padix = padix,
  };

  switch(type) {
    case ACCESSOR_READER:
    {
      OPCODE optype = 0;

      switch(sigil) {
        case '$': optype = OP_PADSV; break;
        case '@': optype = OP_PADAV; break;
        case '%': optype = OP_PADHV; break;
      }

      ctx.retop = newLISTOP(OP_RETURN, 0,
        newOP(OP_PUSHMARK, 0),
        newPADxVOP(optype, 0, padix));

      break;
    }

    case ACCESSOR_WRITER:
    {
      switch(sigil) {
        case '$':
          ctx.bodyop = newBINOP(OP_SASSIGN, 0,
            newOP(OP_SHIFT, 0),
            newPADxVOP(OP_PADSV, 0, padix));
          break;

        case '@':
          ctx.bodyop = newBINOP(OP_AASSIGN, 0,
            force_list_keeping_pushmark(newUNOP(OP_RV2AV, 0, newGVOP(OP_GV, 0, PL_defgv))),
            force_list_keeping_pushmark(newPADxVOP(OP_PADAV, OPf_MOD|OPf_REF, padix)));
          break;

        case '%':
          ctx.bodyop = newBINOP(OP_AASSIGN, 0,
            force_list_keeping_pushmark(newUNOP(OP_RV2AV, 0, newGVOP(OP_GV, 0, PL_defgv))),
            force_list_keeping_pushmark(newPADxVOP(OP_PADHV, OPf_MOD|OPf_REF, padix)));
          break;
      }

      ctx.retop = newLISTOP(OP_RETURN, 0,
        newOP(OP_PUSHMARK, 0),
        newPADxVOP(OP_PADSV, 0, PADIX_SELF));

      break;
    }

    case ACCESSOR_LVALUE_MUTATOR:
    {
      assert(sigil == '$');

      CvLVALUE_on(PL_compcv);

      ctx.retop = newLISTOP(OP_RETURN, 0,
        newOP(OP_PUSHMARK, 0),
        newPADxVOP(OP_PADSV, 0, padix));

      break;
    }

    case ACCESSOR_COMBINED:
    {
      assert(sigil == '$');

      /* $field = shift if @_ */
      ctx.bodyop = newLOGOP(OP_AND, 0,
        /* scalar @_ */
        op_contextualize(newUNOP(OP_RV2AV, 0, newGVOP(OP_GV, 0, PL_defgv)), G_SCALAR),
        /* $field = shift */
        newBINOP(OP_SASSIGN, 0,
          newOP(OP_SHIFT, 0),
          newPADxVOP(OP_PADSV, 0, padix)));

      ctx.retop = newLISTOP(OP_RETURN, 0,
        newOP(OP_PUSHMARK, 0),
        newPADxVOP(OP_PADSV, 0, padix));

      break;
    }
  }

  MOP_FIELD_RUN_HOOKS(fieldmeta, gen_accessor_ops, type, &ctx);

  if(ctx.bodyop)
    ops = op_append_list(OP_LINESEQ, ops, ctx.bodyop);

  if(ctx.post_bodyops)
    ops = op_append_list(OP_LINESEQ, ops, ctx.post_bodyops);

  ops = op_append_list(OP_LINESEQ, ops, ctx.retop);

  SvREFCNT_inc(PL_compcv);
  ops = block_end(save_ix, ops);

  CV *cv = newATTRSUB(floor_ix, NULL, NULL, NULL, ops);
  CvMETHOD_on(cv);

  mop_class_add_method_cv(classmeta, mname, cv);

  LEAVE;
}

static bool fieldhook_reader_apply(pTHX_ FieldMeta *fieldmeta, SV *value, SV **attrdata_ptr, void *_funcdata)
{
  *attrdata_ptr = make_accessor_mnamesv(aTHX_ fieldmeta, value, "%s");
  return TRUE;
}

static void fieldhook_reader_seal(pTHX_ FieldMeta *fieldmeta, SV *attrdata, void *_funcdata)
{
  S_generate_field_accessor_method(aTHX_ fieldmeta, attrdata, ACCESSOR_READER);
}

static struct FieldHookFuncs fieldhooks_reader = {
  .ver   = OBJECTPAD_ABIVERSION,
  .apply = &fieldhook_reader_apply,
  .seal  = &fieldhook_reader_seal,
};

/* :writer */

static bool fieldhook_writer_apply(pTHX_ FieldMeta *fieldmeta, SV *value, SV **attrdata_ptr, void *_funcdata)
{
  *attrdata_ptr = make_accessor_mnamesv(aTHX_ fieldmeta, value, "set_%s");
  return TRUE;
}

static void fieldhook_writer_seal(pTHX_ FieldMeta *fieldmeta, SV *attrdata, void *_funcdata)
{
  S_generate_field_accessor_method(aTHX_ fieldmeta, attrdata, ACCESSOR_WRITER);
}

static struct FieldHookFuncs fieldhooks_writer = {
  .ver   = OBJECTPAD_ABIVERSION,
  .apply = &fieldhook_writer_apply,
  .seal  = &fieldhook_writer_seal,
};

/* :mutator */

static bool fieldhook_mutator_apply(pTHX_ FieldMeta *fieldmeta, SV *value, SV **attrdata_ptr, void *_funcdata)
{
  if(SvPVX(fieldmeta->name)[0] != '$')
    /* TODO: A reader for an array or hash field should also be fine */
    croak("Can only generate accessors for scalar fields");

  *attrdata_ptr = make_accessor_mnamesv(aTHX_ fieldmeta, value, "%s");
  return TRUE;
}

static void fieldhook_mutator_seal(pTHX_ FieldMeta *fieldmeta, SV *attrdata, void *_funcdata)
{
  S_generate_field_accessor_method(aTHX_ fieldmeta, attrdata, ACCESSOR_LVALUE_MUTATOR);
}

static struct FieldHookFuncs fieldhooks_mutator = {
  .ver   = OBJECTPAD_ABIVERSION,
  .apply = &fieldhook_mutator_apply,
  .seal  = &fieldhook_mutator_seal,
};

/* :accessor */

static void fieldhook_accessor_seal(pTHX_ FieldMeta *fieldmeta, SV *attrdata, void *_funcdata)
{
  S_generate_field_accessor_method(aTHX_ fieldmeta, attrdata, ACCESSOR_COMBINED);
}

static struct FieldHookFuncs fieldhooks_accessor = {
  .ver   = OBJECTPAD_ABIVERSION,
  .apply = &fieldhook_mutator_apply, /* generate method name the same as :mutator */
  .seal  = &fieldhook_accessor_seal,
};

/* :inheritable */

static bool fieldhook_inheritble_apply(pTHX_ FieldMeta *fieldmeta, SV *value, SV **attrdata_ptr, void *_funcdata)
{
  HV *hints = GvHV(PL_hintgv);
  if(!hv_fetchs(hints, "Object::Pad/experimental(inherit_field)", 0))
    Perl_ck_warner(aTHX_ packWARN(WARN_EXPERIMENTAL),
      "inheriting fields is experimental and may be changed or removed without notice");

  fieldmeta->is_inheritable = true;

  return false;
}

static struct FieldHookFuncs fieldhooks_inheritable = {
  .ver   = OBJECTPAD_ABIVERSION,
  .flags = OBJECTPAD_FLAG_ATTR_NO_VALUE,
  .apply = &fieldhook_inheritble_apply,
};

struct FieldHookFuncs_v76 {
  U32 ver;
  U32 flags;
  const char *permit_hintkey;
  bool (*apply)(pTHX_ FieldMeta *fieldmeta, SV *value, SV **attrdata_ptr, void *funcdata);
  void (*seal)(pTHX_ FieldMeta *fieldmeta, SV *attrdata, void *funcdata);
  void (*gen_accessor_ops)(pTHX_ FieldMeta *fieldmeta, SV *attrdata, void *funcdata,
          enum AccessorType type, struct AccessorGenerationCtx *ctx);
  void (*post_makefield)(pTHX_ FieldMeta *fieldmeta, SV *attrdata, void *funcdata, SV *field);
  void (*post_construct)(pTHX_ FieldMeta *fieldmeta, SV *attrdata, void *funcdata, SV *field);
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

  if(funcs->ver < OBJECTPAD_ABIVERSION) {
    const struct FieldHookFuncs_v76 *funcs_v76 = (const struct FieldHookFuncs_v76 *)funcs;

    struct FieldHookFuncs *funcs_v810;
    Newx(funcs_v810, 1, struct FieldHookFuncs);

    *funcs_v810 = (struct FieldHookFuncs){
      .ver              = OBJECTPAD_ABIVERSION,
      .flags            = funcs_v76->flags,
      .permit_hintkey   = funcs_v76->permit_hintkey,
      .apply            = funcs_v76->apply,
      .seal             = funcs_v76->seal,
      .gen_accessor_ops = funcs_v76->gen_accessor_ops,
      .post_makefield   = funcs_v76->post_makefield,
      .post_construct   = funcs_v76->post_construct,
    };

    funcs = funcs_v810;
  }

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

  // TODO: temporary name
  register_field_attribute("inheritable", &fieldhooks_inheritable, NULL);
}
