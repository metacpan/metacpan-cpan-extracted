/* vi: set ft=xs : */
#define PERL_NO_GET_CONTEXT

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "object_pad.h"
#include "class.h"
#include "slot.h"

#undef register_class_attribute

#include "perl-backcompat.c.inc"
#include "sv_setrv.c.inc"

#include "perl-additions.c.inc"
#include "force_list_keeping_pushmark.c.inc"
#include "optree-additions.c.inc"
#include "newOP_CUSTOM.c.inc"

/* Empty MGVTBL simply for locating instance slots AV */
static MGVTBL vtbl_slotsav = {};

typedef struct ClassAttributeRegistration ClassAttributeRegistration;

struct ClassAttributeRegistration {
  ClassAttributeRegistration *next;

  const char *name;
  STRLEN permit_hintkeylen;

  const struct ClassHookFuncs *funcs;
};

static ClassAttributeRegistration *classattrs = NULL;

static void register_class_attribute(const char *name, const struct ClassHookFuncs *funcs)
{
  ClassAttributeRegistration *reg;
  Newx(reg, 1, struct ClassAttributeRegistration);

  reg->name = name;
  reg->funcs = funcs;

  if(funcs->permit_hintkey)
    reg->permit_hintkeylen = strlen(funcs->permit_hintkey);
  else
    reg->permit_hintkeylen = 0;

  reg->next  = classattrs;
  classattrs = reg;
}

void ObjectPad_register_class_attribute(pTHX_ const char *name, const struct ClassHookFuncs *funcs)
{
  if(funcs->ver < 50)
    croak("Mismatch in third-party class attribute ABI version field: module wants %d, we require >= 50\n",
        funcs->ver);
  if(funcs->ver > OBJECTPAD_ABIVERSION)
    croak("Mismatch in third-party class attribute ABI version field: attribute supplies %d, module wants %d\n",
        funcs->ver, OBJECTPAD_ABIVERSION);

  if(!name || !(name[0] >= 'A' && name[0] <= 'Z'))
    croak("Third-party class attribute names must begin with a capital letter");

  if(!funcs->permit_hintkey)
    croak("Third-party class attributes require a permit hinthash key");

  register_class_attribute(name, funcs);
}

void ObjectPad_mop_class_apply_attribute(pTHX_ ClassMeta *classmeta, const char *name, SV *value)
{
  HV *hints = GvHV(PL_hintgv);

  if(value && (!SvPOK(value) || !SvCUR(value)))
    value = NULL;

  ClassAttributeRegistration *reg;
  for(reg = classattrs; reg; reg = reg->next) {
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
        if(!(*reg->funcs->apply)(aTHX_ classmeta, value, &hookdata))
          return;
      }
      else {
        /* ABIVERSION_MINOR 50 apply did not have hookdata_ptr */
        bool (*apply)(pTHX_ ClassMeta *, SV *) = (void *)(reg->funcs->apply);
        if(!(*apply)(aTHX_ classmeta, value))
          return;
      }
    }

    if(!classmeta->hooks)
      classmeta->hooks = newAV();

    struct ClassHook *hook;
    Newx(hook, 1, struct ClassHook);

    hook->funcs = reg->funcs;
    hook->hookdata = hookdata;

    av_push(classmeta->hooks, (SV *)hook);

    if(value && value != hookdata)
      SvREFCNT_dec(value);

    return;
  }

  croak("Unrecognised class attribute :%s", name);
}

/* TODO: get attribute */

#define get_classmeta_for(self)  S_get_classmeta_for(aTHX_ self)
static ClassMeta *S_get_classmeta_for(pTHX_ SV *self)
{
  HV *selfstash = SvSTASH(SvRV(self));
  GV **gvp = (GV **)hv_fetchs(selfstash, "META", 0);
  if(!gvp)
    croak("Unable to find ClassMeta for %" SVf, SVfARG(HvNAME(selfstash)));

  return NUM2PTR(ClassMeta *, SvUV(SvRV(GvSV(*gvp))));
}

#define make_instance_slots(classmeta, slotsav, roleoffset)  S_make_instance_slots(aTHX_ classmeta, slotsav, roleoffset)
static void S_make_instance_slots(pTHX_ const ClassMeta *classmeta, AV *slotsav, SLOTOFFSET roleoffset)
{
  assert(classmeta->type == METATYPE_ROLE || roleoffset == 0);

  if(classmeta->start_slotix) {
    /* Superclass actually has some slots */
    assert(classmeta->type == METATYPE_CLASS);
    assert(classmeta->cls.supermeta->sealed);

    make_instance_slots(classmeta->cls.supermeta, slotsav, 0);
  }

  AV *slots = classmeta->direct_slots;
  I32 nslots = av_count(slots);

  av_extend(slotsav, classmeta->next_slotix - 1 + roleoffset);

  I32 i;
  for(i = 0; i < nslots; i++) {
    SlotMeta *slotmeta = (SlotMeta *)AvARRAY(slots)[i];
    char sigil = SvPV_nolen(slotmeta->name)[0];

    assert(av_count(slotsav) == slotmeta->slotix + roleoffset);

    switch(sigil) {
      case '$':
        av_push(slotsav, newSV(0));
        break;

      case '@':
        av_push(slotsav, newRV_noinc((SV *)newAV()));
        break;

      case '%':
        av_push(slotsav, newRV_noinc((SV *)newHV()));
        break;

      default:
        croak("ARGH: not sure how to handle a slot sigil %c\n", sigil);
    }
  }

  if(classmeta->type == METATYPE_CLASS) {
    U32 nroles;
    RoleEmbedding **embeddings = mop_class_get_direct_roles(classmeta, &nroles);

    assert(classmeta->type == METATYPE_CLASS || nroles == 0);

    for(i = 0; i < nroles; i++) {
      RoleEmbedding *embedding = embeddings[i];
      ClassMeta *rolemeta = embedding->rolemeta;

      assert(rolemeta->sealed);

      make_instance_slots(rolemeta, slotsav, embedding->offset);
    }
  }
}

SV *ObjectPad_get_obj_slotsav(pTHX_ SV *self, enum ReprType repr, bool create)
{
  SV *rv = SvRV(self);

  switch(repr) {
    case REPR_NATIVE:
      if(SvTYPE(rv) != SVt_PVAV)
        croak("Not an ARRAY reference");

      return rv;

    case REPR_HASH:
    case_REPR_HASH:
    {
      if(SvTYPE(rv) != SVt_PVHV)
        croak("Not a HASH reference");
      SV **slotssvp = hv_fetchs((HV *)rv, "Object::Pad/slots", create);
      if(create && !SvOK(*slotssvp))
        sv_setrv_noinc(*slotssvp, (SV *)newAV());

      /* A method invoked during a superclass constructor of a classic perl
       * class might encounter $self without slots. If this is the case we'll
       * have to create the slots now
       *   https://rt.cpan.org/Ticket/Display.html?id=132263
       */
      if(!slotssvp) {
        struct ClassMeta *classmeta = get_classmeta_for(self);
        AV *slotsav = newAV();

        make_instance_slots(classmeta, slotsav, 0);

        slotssvp = hv_fetchs((HV *)rv, "Object::Pad/slots", TRUE);
        sv_setrv_noinc(*slotssvp, (SV *)slotsav);
      }
      if(!SvROK(*slotssvp) || SvTYPE(SvRV(*slotssvp)) != SVt_PVAV)
        croak("Expected $self->{\"Object::Pad/slots\"} to be an ARRAY reference");
      return SvRV(*slotssvp);
    }

    case REPR_MAGIC:
    case_REPR_MAGIC:
    {
      MAGIC *mg = mg_findext(rv, PERL_MAGIC_ext, &vtbl_slotsav);
      if(!mg && create)
        mg = sv_magicext(rv, (SV *)newAV(), PERL_MAGIC_ext, &vtbl_slotsav, NULL, 0);
      if(!mg)
        croak("Expected to find slots AV magic extension");
      return mg->mg_obj;
    }

    case REPR_AUTOSELECT:
      if(SvTYPE(rv) == SVt_PVHV)
        goto case_REPR_HASH;
      goto case_REPR_MAGIC;
  }

  croak("ARGH unhandled repr type");
}

#define embed_cv(cv, embedding)  S_embed_cv(aTHX_ cv, embedding)
static CV *S_embed_cv(pTHX_ CV *cv, RoleEmbedding *embedding)
{
  assert(cv);
  assert(CvOUTSIDE(cv));

  CV *embedded_cv = cv_clone(cv);
  SV *embeddingsv = embedding->embeddingsv;

  assert(SvTYPE(embeddingsv) == SVt_PV && SvLEN(embeddingsv) >= sizeof(RoleEmbedding));

  PAD *pad1 = PadlistARRAY(CvPADLIST(embedded_cv))[1];
  PadARRAY(pad1)[PADIX_EMBEDDING] = SvREFCNT_inc(embeddingsv);

  return embedded_cv;
}

RoleEmbedding **ObjectPad_mop_class_get_direct_roles(pTHX_ const ClassMeta *meta, U32 *nroles)
{
  assert(meta->type == METATYPE_CLASS);
  AV *roles = meta->cls.direct_roles;
  *nroles = av_count(roles);
  return (RoleEmbedding **)AvARRAY(roles);
}

RoleEmbedding **ObjectPad_mop_class_get_all_roles(pTHX_ const ClassMeta *meta, U32 *nroles)
{
  assert(meta->type == METATYPE_CLASS);
  AV *roles = meta->cls.embedded_roles;
  *nroles = av_count(roles);
  return (RoleEmbedding **)AvARRAY(roles);
}

MethodMeta *ObjectPad_mop_class_add_method(pTHX_ ClassMeta *meta, SV *methodname)
{
  AV *methods = meta->direct_methods;

  if(meta->sealed)
    croak("Cannot add a new method to an already-sealed class");

  if(!methodname || !SvOK(methodname) || !SvCUR(methodname))
    croak("methodname must not be undefined or empty");

  U32 i;
  for(i = 0; i < av_count(methods); i++) {
    MethodMeta *methodmeta = (MethodMeta *)AvARRAY(methods)[i];
    if(sv_eq(methodmeta->name, methodname)) {
      if(methodmeta->role)
        croak("Method '%" SVf "' clashes with the one provided by role %" SVf,
          SVfARG(methodname), SVfARG(methodmeta->role->name));
      else
        croak("Cannot add another method named %" SVf, methodname);
    }
  }

  MethodMeta *methodmeta;
  Newx(methodmeta, 1, MethodMeta);

  methodmeta->name = SvREFCNT_inc(methodname);
  methodmeta->class = meta;
  methodmeta->role = NULL;

  av_push(methods, (SV *)methodmeta);

  return methodmeta;
}

SlotMeta *ObjectPad_mop_class_add_slot(pTHX_ ClassMeta *meta, SV *slotname)
{
  AV *slots = meta->direct_slots;

  if(meta->sealed)
    croak("Cannot add a new slot to an already-sealed class");

  if(!slotname || !SvOK(slotname) || !SvCUR(slotname))
    croak("slotname must not be undefined or empty");

  switch(SvPV_nolen(slotname)[0]) {
    case '$':
    case '@':
    case '%':
      break;

    default:
      croak("slotname must begin with a sigil");
  }

  U32 i;
  for(i = 0; i < av_count(slots); i++) {
    SlotMeta *slotmeta = (SlotMeta *)AvARRAY(slots)[i];
    if(SvCUR(slotmeta->name) < 2)
      continue;

    if(sv_eq(slotmeta->name, slotname))
      croak("Cannot add another slot named %" SVf, slotname);
  }

  SlotMeta *slotmeta = mop_create_slot(slotname, meta);

  av_push(slots, (SV *)slotmeta);
  meta->next_slotix++;

  MOP_CLASS_RUN_HOOKS(meta, post_add_slot, slotmeta);

  return slotmeta;
}

void ObjectPad_mop_class_add_BUILD(pTHX_ ClassMeta *meta, CV *cv)
{
  if(meta->sealed)
    croak("Cannot add a BUILD block to an already-sealed class");
  if(meta->strict_params)
    croak("Cannot add a BUILD block to a class with :strict(params)");

  if(!meta->buildblocks)
    meta->buildblocks = newAV();

  av_push(meta->buildblocks, (SV *)cv);
}

void ObjectPad_mop_class_add_ADJUST(pTHX_ ClassMeta *meta, CV *cv)
{
  if(meta->sealed)
    croak("Cannot add an ADJUST block to an already-sealed class");
  if(!meta->adjustblocks)
    meta->adjustblocks = newAV();

  AdjustBlock *block;
  Newx(block, 1, struct AdjustBlock);

  block->is_adjustparams = false;
  block->cv = cv;

  av_push(meta->adjustblocks, (SV *)block);
}

void ObjectPad_mop_class_add_ADJUSTPARAMS(pTHX_ ClassMeta *meta, CV *cv)
{
  if(meta->sealed)
    croak("Cannot add an ADJUSTPARAMS block to an already-sealed class");
  if(!meta->adjustblocks)
    meta->adjustblocks = newAV();

  AdjustBlock *block;
  Newx(block, 1, struct AdjustBlock);

  block->is_adjustparams = true;
  block->cv = cv;

  meta->has_adjustparams = true;

  av_push(meta->adjustblocks, (SV *)block);
}

#define mop_class_implements_role(meta, rolemeta)  S_mop_class_implements_role(aTHX_ meta, rolemeta)
static bool S_mop_class_implements_role(pTHX_ ClassMeta *meta, ClassMeta *rolemeta)
{
  U32 i, n;
  switch(meta->type) {
    case METATYPE_CLASS: {
      RoleEmbedding **embeddings = mop_class_get_all_roles(meta, &n);
      for(i = 0; i < n; i++)
        if(embeddings[i]->rolemeta == rolemeta)
          return true;

      break;
    }

    case METATYPE_ROLE: {
      ClassMeta **roles = (ClassMeta **)AvARRAY(meta->role.superroles);
      U32 n = av_count(meta->role.superroles);
      /* TODO: this isn't super-efficient in deep cross-linked heirarchies */
      for(i = 0; i < n; i++) {
        if(roles[i] == rolemeta)
          return true;
        if(mop_class_implements_role(roles[i], rolemeta))
          return true;
      }
      break;
    }
  }

  return false;
}

#define embed_role(class, role)  S_embed_role(aTHX_ class, role)
static RoleEmbedding *S_embed_role(pTHX_ ClassMeta *classmeta, ClassMeta *rolemeta)
{
  U32 i;

  if(classmeta->type != METATYPE_CLASS)
    croak("Can only apply to a class");
  if(rolemeta->type != METATYPE_ROLE)
    croak("Can only apply a role to a class");

  HV *srcstash = rolemeta->stash;
  HV *dststash = classmeta->stash;

  SV *embeddingsv = newSV(sizeof(RoleEmbedding));
  assert(SvTYPE(embeddingsv) == SVt_PV && SvLEN(embeddingsv) >= sizeof(RoleEmbedding));

  RoleEmbedding *embedding = (RoleEmbedding *)SvPVX(embeddingsv);

  embedding->embeddingsv = embeddingsv;
  embedding->rolemeta    = rolemeta;
  embedding->classmeta   = classmeta;
  embedding->offset      = -1;

  av_push(classmeta->cls.embedded_roles, (SV *)embedding);
  hv_store_ent(rolemeta->role.applied_classes, classmeta->name, (SV *)embedding, 0);

  U32 nbuilds = rolemeta->buildblocks ? av_count(rolemeta->buildblocks) : 0;
  for(i = 0; i < nbuilds; i++) {
    CV *buildblock = (CV *)AvARRAY(rolemeta->buildblocks)[i];

    CV *embedded_buildblock = embed_cv(buildblock, embedding);

    if(!classmeta->buildblocks)
      classmeta->buildblocks = newAV();

    av_push(classmeta->buildblocks, (SV *)embedded_buildblock);
  }

  U32 nadjusts = rolemeta->adjustblocks ? av_count(rolemeta->adjustblocks) : 0;
  for(i = 0; i < nadjusts; i++) {
    AdjustBlock *block = (AdjustBlock *)AvARRAY(rolemeta->adjustblocks)[i];

    CV *embedded_cv = embed_cv(block->cv, embedding);

    if(block->is_adjustparams)
      mop_class_add_ADJUSTPARAMS(classmeta, embedded_cv);
    else
      mop_class_add_ADJUST(classmeta, embedded_cv);
  }

  if(rolemeta->has_adjustparams)
    classmeta->has_adjustparams = true;

  U32 nmethods = av_count(rolemeta->direct_methods);
  for(i = 0; i < nmethods; i++) {
    MethodMeta *methodmeta = (MethodMeta *)AvARRAY(rolemeta->direct_methods)[i];
    SV *mname = methodmeta->name;

    HE *he = hv_fetch_ent(srcstash, mname, 0, 0);
    if(!he || !HeVAL(he) || !GvCV((GV *)HeVAL(he)))
      croak("ARGH expected to find CODE called %" SVf " in package %" SVf,
        SVfARG(mname), SVfARG(rolemeta->name));

    {
      MethodMeta *dstmethodmeta = mop_class_add_method(classmeta, mname);
      dstmethodmeta->role = rolemeta;
    }

    GV **gvp = (GV **)hv_fetch(dststash, SvPVX(mname), SvCUR(mname), GV_ADD);
    gv_init_sv(*gvp, dststash, mname, 0);
    GvMULTI_on(*gvp);

    if(GvCV(*gvp))
      croak("Method '%" SVf "' clashes with the one provided by role %" SVf,
        SVfARG(mname), SVfARG(rolemeta->name));

    CV *newcv;
    GvCV_set(*gvp, newcv = embed_cv(GvCV((GV *)HeVAL(he)), embedding));
    CvGV_set(newcv, *gvp);
  }

  nmethods = av_count(rolemeta->requiremethods);
  for(i = 0; i < nmethods; i++) {
    av_push(classmeta->requiremethods, SvREFCNT_inc(AvARRAY(rolemeta->requiremethods)[i]));
  }

  return embedding;
}

void ObjectPad_mop_class_add_role(pTHX_ ClassMeta *dstmeta, ClassMeta *rolemeta)
{
  if(dstmeta->sealed)
    croak("Cannot add a role to an already-sealed class");
  /* Can't currently do this as it breaks t/77mop-create-role.t
  if(!rolemeta->sealed)
    croak("Cannot add a role that is not yet sealed");
   */

  if(mop_class_implements_role(dstmeta, rolemeta))
    return;

  switch(dstmeta->type) {
    case METATYPE_CLASS: {
      U32 nroles;
      if((nroles = av_count(rolemeta->role.superroles)) > 0) {
        ClassMeta **roles = (ClassMeta **)AvARRAY(rolemeta->role.superroles);
        U32 i;
        for(i = 0; i < nroles; i++)
          mop_class_add_role(dstmeta, roles[i]);
      }

      RoleEmbedding *embedding = embed_role(dstmeta, rolemeta);
      av_push(dstmeta->cls.direct_roles, (SV *)embedding);
      return;
    }

    case METATYPE_ROLE:
      av_push(dstmeta->role.superroles, (SV *)rolemeta);
      return;
  }
}

#define embed_slothook(roleh, offset)  S_embed_slothook(aTHX_ roleh, offset)
static struct SlotHook *S_embed_slothook(pTHX_ struct SlotHook *roleh, SLOTOFFSET offset)
{
  struct SlotHook *classh;
  Newx(classh, 1, struct SlotHook);

  classh->slotix   = roleh->slotix + offset;
  classh->slotmeta = roleh->slotmeta;
  classh->funcs    = roleh->funcs;
  classh->hookdata = roleh->hookdata;

  return classh;
}

#define mop_class_apply_role(embedding)  S_mop_class_apply_role(aTHX_ embedding)
static void S_mop_class_apply_role(pTHX_ RoleEmbedding *embedding)
{
  ClassMeta *classmeta = embedding->classmeta;
  ClassMeta *rolemeta  = embedding->rolemeta;

  if(classmeta->type != METATYPE_CLASS)
    croak("Can only apply to a class");
  if(rolemeta->type != METATYPE_ROLE)
    croak("Can only apply a role to a class");

  assert(embedding->offset == -1);
  embedding->offset = classmeta->next_slotix;

  if(rolemeta->parammap) {
    HV *src = rolemeta->parammap;

    if(!classmeta->parammap)
      classmeta->parammap = newHV();

    HV *dst = classmeta->parammap;

    hv_iterinit(src);

    HE *iter;
    while((iter = hv_iternext(src))) {
      STRLEN klen = HeKLEN(iter);
      void *key = HeKEY(iter);

      if(klen < 0 ? hv_exists_ent(dst, (SV *)key, HeHASH(iter))
                  : hv_exists(dst, (char *)key, klen))
        croak("Named parameter '%" SVf "' clashes with the one provided by role %" SVf,
          SVfARG(HeSVKEY_force(iter)), SVfARG(rolemeta->name));

      ParamMeta *roleparammeta = (ParamMeta *)HeVAL(iter);
      ParamMeta *classparammeta;
      Newx(classparammeta, 1, struct ParamMeta);

      classparammeta->slot = roleparammeta->slot;
      classparammeta->slotix = roleparammeta->slotix + embedding->offset;

      if(klen < 0)
        hv_store_ent(dst, HeSVKEY(iter), (SV *)classparammeta, HeHASH(iter));
      else
        hv_store(dst, HeKEY(iter), klen, (SV *)classparammeta, HeHASH(iter));
    }
  }

  if(rolemeta->slothooks_postslots) {
    if(!classmeta->slothooks_postslots)
      classmeta->slothooks_postslots = newAV();

    U32 i;
    for(i = 0; i < av_count(rolemeta->slothooks_postslots); i++) {
      struct SlotHook *roleh = (struct SlotHook *)AvARRAY(rolemeta->slothooks_postslots)[i];
      av_push(classmeta->slothooks_postslots, (SV *)embed_slothook(roleh, embedding->offset));
    }
  }

  if(rolemeta->slothooks_construct) {
    if(!classmeta->slothooks_construct)
      classmeta->slothooks_construct = newAV();

    U32 i;
    for(i = 0; i < av_count(rolemeta->slothooks_construct); i++) {
      struct SlotHook *roleh = (struct SlotHook *)AvARRAY(rolemeta->slothooks_construct)[i];
      av_push(classmeta->slothooks_construct, (SV *)embed_slothook(roleh, embedding->offset));
    }
  }

  classmeta->next_slotix += av_count(rolemeta->direct_slots);

  /* TODO: Run an APPLY block if the role has one */
}

static void S_apply_roles(pTHX_ ClassMeta *dstmeta, ClassMeta *srcmeta)
{
  U32 nroles;
  RoleEmbedding **arr = mop_class_get_direct_roles(srcmeta, &nroles);
  U32 i;
  for(i = 0; i < nroles; i++) {
    mop_class_apply_role(arr[i]);
  }
}

static OP *pp_alias_params(pTHX)
{
  dSP;
  PADOFFSET padix = PADIX_INITSLOTS_PARAMS;

  SV *params = POPs;

  if(SvTYPE(params) != SVt_PVHV)
    RETURN;

  SAVESPTR(PAD_SVl(padix));
  PAD_SVl(padix) = SvREFCNT_inc(params);
  save_freesv(params);

  RETURN;
}

static OP *pp_croak_from_constructor(pTHX)
{
  dSP;

  /* Walk up the caller stack to find the COP of the first caller; i.e. the
   * first one that wasn't in src/class.c
   */
  I32 count = 0;
  const PERL_CONTEXT *cx;
  while((cx = caller_cx(count, NULL))) {
    const char *copfile = CopFILE(cx->blk_oldcop);
    if(!copfile|| strNE(copfile, "src/class.c")) {
      PL_curcop = cx->blk_oldcop;
      break;
    }
    count++;
  }

  croak_sv(POPs);
}

static void S_generate_initslots_method(pTHX_ ClassMeta *meta)
{
  OP *ops = NULL;
  int i;

  ENTER;

  I32 floor_ix = PL_savestack_ix;
  {
    SAVEI32(PL_subline);
    save_item(PL_subname);

    resume_compcv(&meta->initslots_compcv);
  }

  SAVEFREESV(PL_compcv);

  I32 save_ix = block_start(TRUE);

  SAVESPTR(PL_curcop);
  PL_curcop = meta->tmpcop;
  CopLINE_set(PL_curcop, __LINE__);

  ops = op_append_list(OP_LINESEQ, ops,
    newSTATEOP(0, NULL, NULL));

  /* A more optimised implementation of this method would be able to generate
   * a @self lexical and OP_REFASSIGN it, but that would only work on newer
   * perls. For now we'll take the small performance hit of RV2AV every time
   */

  enum ReprType repr = meta->repr;

  ops = op_append_list(OP_LINESEQ, ops,
    newMETHSTARTOP(0 |
      (meta->type == METATYPE_ROLE ? OPf_SPECIAL : 0) |
      (repr << 8))
  );

  ops = op_append_list(OP_LINESEQ, ops,
    newUNOP_CUSTOM(&pp_alias_params, 0,
      newOP(OP_SHIFT, OPf_SPECIAL)));

  /* TODO: Icky horrible implementation; if our slotoffset > 0 then
   * we must be a subclass
   */
  if(meta->start_slotix) {
    struct ClassMeta *supermeta = meta->cls.supermeta;

    assert(supermeta->sealed);
    assert(supermeta->initslots);

    CopLINE_set(PL_curcop, __LINE__);

    ops = op_append_list(OP_LINESEQ, ops,
      newSTATEOP(0, NULL, NULL));

    /* Build an OP_ENTERSUB for supermeta's initslots */
    OP *op = NULL;
    op = op_append_list(OP_LIST, op,
      newPADxVOP(OP_PADSV, 0, PADIX_SELF));
    op = op_append_list(OP_LIST, op,
      newPADxVOP(OP_PADHV, OPf_REF, PADIX_INITSLOTS_PARAMS));
    op = op_append_list(OP_LIST, op,
      newSVOP(OP_CONST, 0, (SV *)supermeta->initslots));

    ops = op_append_list(OP_LINESEQ, ops,
      op_convert_list(OP_ENTERSUB, OPf_WANT_VOID|OPf_STACKED, op));
  }

  AV *slots = meta->direct_slots;
  I32 nslots = av_count(slots);

  {
    for(i = 0; i < nslots; i++) {
      SlotMeta *slotmeta = (SlotMeta *)AvARRAY(slots)[i];
      char sigil = SvPV_nolen(slotmeta->name)[0];
      OP *op = NULL;

      switch(sigil) {
        case '$':
        {
          CopLINE_set(PL_curcop, __LINE__);

          OP *valueop = NULL;

          if(slotmeta->defaultexpr) {
            valueop = slotmeta->defaultexpr;
          }
          else if(slotmeta->defaultsv) {
            /* An OP_CONST whose op_type is OP_CUSTOM.
             * This way we avoid the opchecker and finalizer doing bad things
             * to our defaultsv SV by setting it SvREADONLY_on()
             */
            valueop = newSVOP_CUSTOM(PL_ppaddr[OP_CONST], 0, slotmeta->defaultsv);
          }

          if(slotmeta->paramname) {
            SV *paramname = slotmeta->paramname;

            if(!valueop)
              valueop = newUNOP_CUSTOM(&pp_croak_from_constructor, 0,
                newSVOP(OP_CONST, 0,
                  newSVpvf("Required parameter '%" SVf "' is missing for %" SVf " constructor",
                    SVfARG(paramname), SVfARG(meta->name))));

            valueop = newCONDOP(0,
              /* exists $params{$paramname} */
              newUNOP(OP_EXISTS, 0,
                newBINOP(OP_HELEM, 0,
                  newPADxVOP(OP_PADHV, OPf_REF, PADIX_INITSLOTS_PARAMS),
                  newSVOP(OP_CONST, 0, SvREFCNT_inc(paramname)))),

              /* ? delete $params{$paramname} */
              newUNOP(OP_DELETE, 0,
                newBINOP(OP_HELEM, 0,
                  newPADxVOP(OP_PADHV, OPf_REF, PADIX_INITSLOTS_PARAMS),
                  newSVOP(OP_CONST, 0, SvREFCNT_inc(paramname)))),

              /* : valueop or die */
              valueop);
          }

          if(valueop)
            op = newBINOP(OP_SASSIGN, 0,
              valueop,
              /* $slots[$idx] */
              newAELEMOP(0,
                newPADxVOP(OP_PADAV, OPf_MOD|OPf_REF, PADIX_SLOTS),
                slotmeta->slotix));
          break;
        }
        case '@':
        case '%':
        {
          CopLINE_set(PL_curcop, __LINE__);

          OP *valueop = NULL;
          U16 coerceop = (sigil == '%') ? OP_RV2HV : OP_RV2AV;

          if(slotmeta->defaultexpr) {
            valueop = slotmeta->defaultexpr;
          }
          else if(slotmeta->defaultsv) {
            valueop = newUNOP(coerceop, 0,
                newSVOP_CUSTOM(PL_ppaddr[OP_CONST], 0, slotmeta->defaultsv));
          }

          if(valueop) {
            /* $slots[$idx]->@* or ->%* */
            OP *lhs = force_list_keeping_pushmark(newUNOP(coerceop, OPf_MOD|OPf_REF,
                        newAELEMOP(0,
                          newPADxVOP(OP_PADAV, OPf_MOD|OPf_REF, PADIX_SLOTS),
                          slotmeta->slotix)));

            op = newBINOP(OP_AASSIGN, 0,
                force_list_keeping_pushmark(valueop),
                lhs);
          }
          break;
        }

        default:
          croak("ARGH: not sure how to handle a slot sigil %c\n", sigil);
      }

      if(!op)
        continue;

      /* TODO: grab a COP at the initexpr time */
      ops = op_append_list(OP_LINESEQ, ops,
        newSTATEOP(0, NULL, NULL));
      ops = op_append_list(OP_LINESEQ, ops,
        op);
    }
  }

  if(meta->type == METATYPE_CLASS) {
    U32 nroles;
    RoleEmbedding **embeddings = mop_class_get_direct_roles(meta, &nroles);

    for(i = 0; i < nroles; i++) {
      RoleEmbedding *embedding = embeddings[i];
      ClassMeta *rolemeta = embedding->rolemeta;

      if(!rolemeta->sealed)
        mop_class_seal(rolemeta);

      assert(rolemeta->sealed);
      assert(rolemeta->initslots);

      CopLINE_set(PL_curcop, __LINE__);

      ops = op_append_list(OP_LINESEQ, ops,
        newSTATEOP(0, NULL, NULL));

      OP *op = NULL;
      op = op_append_list(OP_LIST, op,
        newPADxVOP(OP_PADSV, 0, PADIX_SELF));
      op = op_append_list(OP_LIST, op,
        newPADxVOP(OP_PADHV, OPf_REF, PADIX_INITSLOTS_PARAMS));
      op = op_append_list(OP_LIST, op,
        newSVOP(OP_CONST, 0, (SV *)embed_cv(rolemeta->initslots, embedding)));

      ops = op_append_list(OP_LINESEQ, ops,
        op_convert_list(OP_ENTERSUB, OPf_WANT_VOID|OPf_STACKED, op));
    }
  }

  SvREFCNT_inc(PL_compcv);
  ops = block_end(save_ix, ops);

  /* newATTRSUB will capture PL_curstash */
  SAVESPTR(PL_curstash);
  PL_curstash = meta->stash;

  meta->initslots = newATTRSUB(floor_ix, NULL, NULL, NULL, ops);

  assert(meta->initslots);
  assert(CvOUTSIDE(meta->initslots));

  LEAVE;
}

void ObjectPad_mop_class_seal(pTHX_ ClassMeta *meta)
{
  if(meta->sealed) /* idempotent */
    return;

  if(meta->type == METATYPE_CLASS &&
      meta->cls.supermeta && !meta->cls.supermeta->sealed) {
    /* Must defer sealing until superclass is sealed first
     * (RT133190)
     */
    ClassMeta *supermeta = meta->cls.supermeta;
    if(!supermeta->pending_submeta)
      supermeta->pending_submeta = newAV();
    av_push(supermeta->pending_submeta, (SV *)meta);
    return;
  }

  if(meta->type == METATYPE_CLASS)
    S_apply_roles(aTHX_ meta, meta);

  if(meta->type == METATYPE_CLASS) {
    U32 nmethods = av_count(meta->requiremethods);
    U32 i;
    for(i = 0; i < nmethods; i++) {
      SV *mname = AvARRAY(meta->requiremethods)[i];

      GV *gv = gv_fetchmeth_sv(meta->stash, mname, 0, 0);
      if(gv && GvCV(gv))
        continue;

      croak("Class %" SVf " does not provide a required method named '%" SVf "'",
        SVfARG(meta->name), SVfARG(mname));
    }
  }

  if(meta->strict_params && meta->buildblocks)
    croak("Class %" SVf " cannot be :strict(params) because it has BUILD blocks",
      SVfARG(meta->name));

  {
    U32 slotix;
    for(slotix = 0; slotix < av_count(meta->direct_slots); slotix++) {
      SlotMeta *slotmeta = (SlotMeta *)AvARRAY(meta->direct_slots)[slotix];

      U32 hooki;
      for(hooki = 0; slotmeta->hooks && hooki < av_count(slotmeta->hooks); hooki++) {
        struct SlotHook *h = (struct SlotHook *)AvARRAY(slotmeta->hooks)[hooki];

        if(*h->funcs->post_initslot) {
          if(!meta->slothooks_postslots)
            meta->slothooks_postslots = newAV();

          struct SlotHook *fasth;
          Newx(fasth, 1, struct SlotHook);

          fasth->slotix   = slotix;
          fasth->slotmeta = slotmeta;
          fasth->funcs    = h->funcs;
          fasth->hookdata = h->hookdata;

          av_push(meta->slothooks_postslots, (SV *)fasth);
        }

        if(*h->funcs->post_construct) {
          if(!meta->slothooks_construct)
            meta->slothooks_construct = newAV();

          struct SlotHook *fasth;
          Newx(fasth, 1, struct SlotHook);

          fasth->slotix   = slotix;
          fasth->slotmeta = slotmeta;
          fasth->funcs    = h->funcs;
          fasth->hookdata = h->hookdata;

          av_push(meta->slothooks_construct, (SV *)fasth);
        }
      }
    }
  }

  S_generate_initslots_method(aTHX_ meta);

  meta->sealed = true;

  if(meta->pending_submeta) {
    int i;
    SV **arr = AvARRAY(meta->pending_submeta);
    for(i = 0; i < av_count(meta->pending_submeta); i++) {
      ClassMeta *submeta = (ClassMeta *)arr[i];
      arr[i] = &PL_sv_undef;

      mop_class_seal(submeta);
    }

    SvREFCNT_dec(meta->pending_submeta);
    meta->pending_submeta = NULL;
  }
}

XS_INTERNAL(injected_constructor);
XS_INTERNAL(injected_constructor)
{
  dXSARGS;
  const ClassMeta *meta = XSANY.any_ptr;
  SV *class = ST(0);
  SV *self = NULL;

  assert(meta->type == METATYPE_CLASS);
  if(!meta->sealed)
    croak("Cannot yet invoke '%" SVf "' constructor before the class is complete", SVfARG(class));

  COP *prevcop = PL_curcop;
  PL_curcop = meta->tmpcop;
  CopLINE_set(PL_curcop, __LINE__);

  /* An AV storing the @_ args to pass to foreign constructor and all the
   * build blocks
   * This does not include $self
   */
  AV *args = newAV();
  SAVEFREESV(args);

  {
    /* @args = $class->BUILDARGS(@_) */
    ENTER;
    SAVETMPS;
    SAVEVPTR(PL_curcop);
    PL_curcop = prevcop;

    /* Splice in an extra copy of `class` so we get one there for the foreign
     * constructor */
    EXTEND(SP, 1);

    SV **argstart = SP - items + 2;
    PUSHMARK(argstart - 1);

    SV **svp;
    for(svp = SP; svp >= argstart; svp--)
      *(svp+1) = *svp;
    *argstart = class;
    SP++;
    PUTBACK;

    I32 nargs = call_method("BUILDARGS", G_ARRAY);

    SPAGAIN;

    for(svp = SP - nargs + 1; svp <= SP; svp++)
      av_push(args, SvREFCNT_inc(*svp));

    FREETMPS;
    LEAVE;
  }

  bool need_makeslots = true;

  if(!meta->cls.foreign_new) {
    HV *stash = gv_stashsv(class, 0);
    if(!stash)
      croak("Unable to find stash for class %" SVf, class);

    switch(meta->repr) {
      case REPR_NATIVE:
      case REPR_AUTOSELECT:
        CopLINE_set(PL_curcop, __LINE__);
        self = sv_2mortal(newRV_noinc((SV *)newAV()));
        sv_bless(self, stash);
        break;

      case REPR_HASH:
        CopLINE_set(PL_curcop, __LINE__);
        self = sv_2mortal(newRV_noinc((SV *)newHV()));
        sv_bless(self, stash);
        break;

      case REPR_MAGIC:
        croak("ARGH cannot use :repr(magic) without a foreign superconstructor");
        break;
    }
  }
  else {
    CopLINE_set(PL_curcop, __LINE__);

    {
      ENTER;
      SAVETMPS;

      PUSHMARK(SP);
      EXTEND(SP, 1 + AvFILL(args));

      SV **argstart = SP - AvFILL(args) - 1;
      SV **argtop = SP;
      SV **svp;

      mPUSHs(newSVsv(class));

      /* Push a copy of the args in case the (foreign) constructor mutates
       * them. We still need them for BUILDALL */
      for(svp = argstart + 1; svp <= argtop; svp++)
        PUSHs(*svp);
      PUTBACK;

      assert(meta->cls.foreign_new);
      call_sv((SV *)meta->cls.foreign_new, G_SCALAR);
      SPAGAIN;

      self = SvREFCNT_inc(POPs);

      PUTBACK;
      FREETMPS;
      LEAVE;
    }

    if(!SvROK(self) || !SvOBJECT(SvRV(self))) {
      PL_curcop = prevcop;
      croak("Expected %" SVf "->SUPER::new to return a blessed reference", class);
    }
    SV *rv = SvRV(self);

    /* It's possible a foreign superclass constructor invoked a `method` and
     * thus initslots has already been called. Check here and set
     * need_makeslots false if so.
     */

    switch(meta->repr) {
      case REPR_NATIVE:
        croak("ARGH shouldn't ever have REPR_NATIVE with foreign_new");

      case REPR_HASH:
      case_REPR_HASH:
        if(SvTYPE(rv) != SVt_PVHV) {
          PL_curcop = prevcop;
          croak("Expected %" SVf "->SUPER::new to return a blessed HASH reference", class);
        }

        need_makeslots = !hv_exists(MUTABLE_HV(rv), "Object::Pad/slots", 17);
        break;

      case REPR_MAGIC:
      case_REPR_MAGIC:
        /* Anything goes */

        need_makeslots = !mg_findext(rv, PERL_MAGIC_ext, &vtbl_slotsav);
        break;

      case REPR_AUTOSELECT:
        if(SvTYPE(rv) == SVt_PVHV)
          goto case_REPR_HASH;
        goto case_REPR_MAGIC;
    }

    sv_2mortal(self);
  }

  AV *slotsav;

  if(need_makeslots) {
    slotsav = (AV *)get_obj_slotsav(self, meta->repr, TRUE);
    make_instance_slots(meta, slotsav, 0);
  }
  else {
    slotsav = (AV *)get_obj_slotsav(self, meta->repr, FALSE);
  }

  SV **slotsv = AvARRAY(slotsav);

  if(meta->slothooks_postslots || meta->slothooks_construct) {
    /* We need to set up a fake pad so these hooks can still get PADIX_SELF / PADIX_SLOTS */

    /* This MVP is just sufficient enough to let PAD_SVl(PADIX_SELF) work */
    SAVEVPTR(PL_curpad);
    Newx(PL_curpad, 3, SV *);
    SAVEFREEPV(PL_curpad);

    PAD_SVl(PADIX_SELF)  = self;
    PAD_SVl(PADIX_SLOTS) = (SV *)slotsav;
  }

  if(meta->slothooks_postslots) {
    CopLINE_set(PL_curcop, __LINE__);

    AV *slothooks = meta->slothooks_postslots;

    U32 i;
    for(i = 0; i < av_count(slothooks); i++) {
      struct SlotHook *h = (struct SlotHook *)AvARRAY(slothooks)[i];
      SLOTOFFSET slotix = h->slotix;

      (*h->funcs->post_initslot)(aTHX_ h->slotmeta, h->hookdata, slotsv[slotix]);
    }
  }

  HV *paramhv = NULL;
  if(meta->parammap || meta->has_adjustparams) {
    paramhv = newHV();
    SAVEFREESV((SV *)paramhv);

    if(av_count(args) % 2)
      warn("Odd-length list passed to %" SVf " constructor", class);

    /* TODO: I'm sure there's an newHV_from_AV() around somewhere */
    SV **argsv = AvARRAY(args);

    IV idx;
    for(idx = 0; idx < av_count(args); idx += 2) {
      SV *name  = argsv[idx];
      SV *value = idx < av_count(args)-1 ? argsv[idx+1] : &PL_sv_undef;

      hv_store_ent(paramhv, name, SvREFCNT_inc(value), 0);
    }
  }

  {
    /* Run initslots */
    ENTER;
    SAVEVPTR(PL_curcop);
    PL_curcop = prevcop;

    EXTEND(SP, 2);
    PUSHMARK(SP);
    PUSHs(self);
    if(paramhv)
      PUSHs((SV *)paramhv);
    else
      PUSHs(&PL_sv_undef);
    PUTBACK;

    assert(meta->initslots);
    call_sv((SV *)meta->initslots, G_VOID);

    LEAVE;
  }

  if(meta->buildblocks) {
    CopLINE_set(PL_curcop, __LINE__);

    AV *buildblocks = meta->buildblocks;
    SV **argsvs = AvARRAY(args);
    int i;
    for(i = 0; i < av_count(buildblocks); i++) {
      CV *buildblock = (CV *)AvARRAY(buildblocks)[i];

      ENTER;
      SAVETMPS;
      SPAGAIN;

      EXTEND(SP, 1 + AvFILL(args));

      PUSHMARK(SP);

      PUSHs(self);

      int argi;
      for(argi = 0; argi <= AvFILL(args); argi++)
        PUSHs(argsvs[argi]);
      PUTBACK;

      assert(buildblock);
      call_sv((SV *)buildblock, G_VOID);

      FREETMPS;
      LEAVE;
    }
  }

  if(meta->adjustblocks) {
    CopLINE_set(PL_curcop, __LINE__);

    AV *adjustblocks = meta->adjustblocks;
    U32 i;
    for(i = 0; i < av_count(adjustblocks); i++) {
      AdjustBlock *block = (AdjustBlock *)AvARRAY(adjustblocks)[i];

      ENTER;
      SAVETMPS;
      SPAGAIN;

      EXTEND(SP, 1 + !!paramhv);

      PUSHMARK(SP);
      PUSHs(self);
      if(paramhv && block->is_adjustparams)
        mPUSHs(newRV_inc((SV *)paramhv));
      PUTBACK;

      assert(block->cv);
      call_sv((SV *)block->cv, G_VOID);

      FREETMPS;
      LEAVE;
    }
  }

  if(paramhv && meta->strict_params && hv_iterinit(paramhv) > 0) {
    HE *he = hv_iternext(paramhv);

    /* Concat all the param names, in no particular order
     * TODO: consider sorting them but that's quite expensive and tricky in XS */

    SV *params = newSVsv(HeSVKEY_force(he));
    SAVEFREESV(params);

    while((he = hv_iternext(paramhv)))
      sv_catpvf(params, ", %" SVf, SVfARG(HeSVKEY_force(he)));

    PL_curcop = prevcop;
    croak("Unrecognised parameters for %" SVf " constructor: %" SVf,
      SVfARG(meta->name), SVfARG(params));
  }

  if(meta->slothooks_construct) {
    CopLINE_set(PL_curcop, __LINE__);

    AV *slothooks = meta->slothooks_construct;

    U32 i;
    for(i = 0; i < av_count(slothooks); i++) {
      struct SlotHook *h = (struct SlotHook *)AvARRAY(slothooks)[i];
      SLOTOFFSET slotix = h->slotix;

      (*h->funcs->post_construct)(aTHX_ h->slotmeta, h->hookdata, slotsv[slotix]);
    }
  }

  PL_curcop = prevcop;
  ST(0) = self;
  XSRETURN(1);
}

XS_INTERNAL(injected_DOES)
{
  dXSARGS;
  const ClassMeta *meta = XSANY.any_ptr;
  SV *self = ST(0);
  SV *wantrole = ST(1);

  PERL_UNUSED_ARG(items);

  CV *cv_does = NULL;

  while(meta != NULL) {
    AV *roles = meta->type == METATYPE_CLASS ? meta->cls.direct_roles : NULL;
    I32 nroles = roles ? av_count(roles) : 0;

    if(!cv_does && meta->cls.foreign_does)
      cv_does = meta->cls.foreign_does;

    if(sv_eq(meta->name, wantrole)) {
      XSRETURN_YES;
    }

    int i;
    for(i = 0; i < nroles; i++) {
      RoleEmbedding *embedding = (RoleEmbedding *)AvARRAY(roles)[i];
      if(sv_eq(embedding->rolemeta->name, wantrole)) {
        XSRETURN_YES;
      }
    }

    meta = meta->type == METATYPE_CLASS ? meta->cls.supermeta : NULL;
  }

  if (cv_does) {
    /* return $self->DOES(@_); */
    dSP;

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    EXTEND(SP, 2);
    PUSHs(self);
    PUSHs(wantrole);
    PUTBACK;

    int count = call_sv((SV*)cv_does, G_SCALAR);

    SPAGAIN;

    bool ret = false;

    if (count)
      ret = POPi;

    FREETMPS;
    LEAVE;

    if(ret)
      XSRETURN_YES;
  }
  else {
    /* We need to also respond to Object::Pad::UNIVERSAL and UNIVERSAL */
    if(sv_derived_from_sv(self, wantrole, 0))
      XSRETURN_YES;
  }

  XSRETURN_NO;
}

ClassMeta *ObjectPad_mop_create_class(pTHX_ enum MetaType type, SV *name, SV *superclassname)
{
  assert(
      type == METATYPE_CLASS ||
      (type == METATYPE_ROLE && !superclassname)
  );

  ClassMeta *meta;
  Newx(meta, 1, ClassMeta);

  meta->type = type;
  meta->name = SvREFCNT_inc(name);

  HV *stash = meta->stash = gv_stashsv(name, GV_ADD);

  meta->sealed = false;
  meta->role_is_invokable = false;
  meta->strict_params = false;
  meta->has_adjustparams = false;
  meta->start_slotix = 0;
  meta->hooks   = NULL;
  meta->direct_slots = newAV();
  meta->direct_methods = newAV();
  meta->parammap = NULL;
  meta->requiremethods = newAV();
  meta->repr   = REPR_AUTOSELECT;
  meta->pending_submeta = NULL;
  meta->buildblocks = NULL;
  meta->adjustblocks = NULL;
  meta->initslots = NULL;

  meta->slothooks_postslots = NULL;
  meta->slothooks_construct = NULL;

  switch(type) {
    case METATYPE_CLASS:
      meta->cls.supermeta = NULL;
      meta->cls.foreign_new = NULL;
      meta->cls.foreign_does = NULL;
      meta->cls.direct_roles = newAV();
      meta->cls.embedded_roles = newAV();
      break;

    case METATYPE_ROLE:
      meta->role.superroles = newAV();
      meta->role.applied_classes = newHV();
      break;
  }

  if(!PL_parser) {
    /* We need to generate just enough of a PL_parser to keep newSTATEOP()
     * happy, otherwise it will SIGSEGV (RT133258)
     */
    SAVEVPTR(PL_parser);
    Newxz(PL_parser, 1, yy_parser);
    SAVEFREEPV(PL_parser);

    PL_parser->copline = NOLINE;
#if HAVE_PERL_VERSION(5, 20, 0)
    PL_parser->preambling = NOLINE;
#endif
  }

  /* Prepare meta->initslots for containing a CV parsing operation */
  {
    if(!PL_compcv) {
      /* We require the initslots CV to have a CvOUTSIDE, or else cv_clone()
       * will segv when we compose role slots. Any class dynamically generated
       * by string eval() will likely not get one, because it won't inherit a
       * PL_compcv here. We'll fake it up
       *   See also  https://rt.cpan.org/Ticket/Display.html?id=137952
       */
      SAVEVPTR(PL_compcv);
      PL_compcv = find_runcv(0);

      assert(PL_compcv);
    }

    I32 floor_ix = start_subparse(FALSE, 0);

    extend_pad_vars(meta);

    /* Skip padix==3 so we're aligned again */
    if(meta->type != METATYPE_ROLE)
      pad_add_name_pvs("", 0, NULL, NULL);

    PADOFFSET padix = pad_add_name_pvs("%params", 0, NULL, NULL);
    if(padix != PADIX_INITSLOTS_PARAMS)
      croak("ARGH: Expected that padix[%%params] = 4");

    intro_my();

    suspend_compcv(&meta->initslots_compcv);

    LEAVE_SCOPE(floor_ix);
  }

  meta->tmpcop = (COP *)newSTATEOP(0, NULL, NULL);
  CopFILE_set(meta->tmpcop, __FILE__);

  meta->methodscope = NULL;

  AV *isa;
  {
    SV *isaname = newSVpvf("%" SVf "::ISA", name);
    SAVEFREESV(isaname);

    isa = get_av(SvPV_nolen(isaname), GV_ADD | (SvFLAGS(isaname) & SVf_UTF8));
  }

  if(superclassname && SvOK(superclassname)) {
    assert(type == METATYPE_CLASS);

    av_push(isa, SvREFCNT_inc(superclassname));

    ClassMeta *supermeta = NULL;

    HV *superstash = gv_stashsv(superclassname, 0);
    GV **metagvp = (GV **)hv_fetchs(superstash, "META", 0);
    if(metagvp)
      supermeta = NUM2PTR(ClassMeta *, SvUV(SvRV(GvSV(*metagvp))));

    if(supermeta) {
      /* A subclass of an Object::Pad class */
      if(supermeta->type != METATYPE_CLASS)
        croak("%" SVf " is not a class", SVfARG(superclassname));

      meta->start_slotix = supermeta->next_slotix;
      meta->repr = supermeta->repr;
      meta->cls.foreign_new = supermeta->cls.foreign_new;

      if(supermeta->buildblocks) {
        if(!meta->buildblocks)
          meta->buildblocks = newAV();

        av_push_from_av_noinc(meta->buildblocks, supermeta->buildblocks);
      }

      if(supermeta->adjustblocks) {
        if(!meta->adjustblocks)
          meta->adjustblocks = newAV();

        av_push_from_av_noinc(meta->adjustblocks, supermeta->adjustblocks);
      }

      if(supermeta->slothooks_postslots) {
        if(!meta->slothooks_postslots)
          meta->slothooks_postslots = newAV();

        av_push_from_av_noinc(meta->slothooks_postslots, supermeta->slothooks_postslots);
      }

      if(supermeta->slothooks_construct) {
        if(!meta->slothooks_construct)
          meta->slothooks_construct = newAV();

        av_push_from_av_noinc(meta->slothooks_construct, supermeta->slothooks_construct);
      }

      if(supermeta->parammap) {
        HV *old = supermeta->parammap;
        HV *new = meta->parammap = newHV();

        hv_iterinit(old);

        HE *iter;
        while((iter = hv_iternext(old))) {
          STRLEN klen = HeKLEN(iter);
          /* Don't SvREFCNT_inc() the values because they aren't really SV *s */
          /* Subclasses *DIRECTLY SHARE* their param metas because the
           * information in them is directly compatible
           */
          if(klen < 0)
            hv_store_ent(new, HeSVKEY(iter), HeVAL(iter), HeHASH(iter));
          else
            hv_store(new, HeKEY(iter), klen, HeVAL(iter), HeHASH(iter));
        }
      }

      if(supermeta->has_adjustparams)
        meta->has_adjustparams = true;

      U32 nroles;
      RoleEmbedding **embeddings = mop_class_get_all_roles(supermeta, &nroles);
      if(nroles) {
        U32 i;
        for(i = 0; i < nroles; i++) {
          RoleEmbedding *embedding = embeddings[i];
          ClassMeta *rolemeta = embedding->rolemeta;

          av_push(meta->cls.embedded_roles, (SV *)embedding);
          hv_store_ent(rolemeta->role.applied_classes, meta->name, (SV *)embedding, 0);
        }
      }
    }
    else {
      /* A subclass of a foreign class */
      meta->cls.foreign_new = fetch_superclass_method_pv(meta->stash, "new", 3, -1);
      if(!meta->cls.foreign_new)
        croak("Unable to find SUPER::new for %" SVf, superclassname);

      meta->cls.foreign_does = fetch_superclass_method_pv(meta->stash, "DOES", 4, -1);

      av_push(isa, newSVpvs("Object::Pad::UNIVERSAL"));
    }

    meta->cls.supermeta = supermeta;
  }
  else {
    /* A base class */
    av_push(isa, newSVpvs("Object::Pad::UNIVERSAL"));
  }

  if(meta->type == METATYPE_CLASS &&
      meta->repr == REPR_AUTOSELECT && !meta->cls.foreign_new)
    meta->repr = REPR_NATIVE;

  meta->next_slotix = meta->start_slotix;

  {
    /* Inject the constructor */
    SV *newname = newSVpvf("%" SVf "::new", name);
    SAVEFREESV(newname);

    CV *newcv = newXS_flags(SvPV_nolen(newname), injected_constructor, __FILE__, NULL, SvFLAGS(newname) & SVf_UTF8);
    CvXSUBANY(newcv).any_ptr = meta;
  }

  {
    SV *doesname = newSVpvf("%" SVf "::DOES", name);
    SAVEFREESV(doesname);
    CV *doescv = newXS_flags(SvPV_nolen(doesname), injected_DOES, __FILE__, NULL, SvFLAGS(doesname) & SVf_UTF8);
    CvXSUBANY(doescv).any_ptr = meta;
  }

  {
    GV **gvp = (GV **)hv_fetchs(stash, "META", GV_ADD);
    GV *gv = *gvp;
    gv_init_pvn(gv, stash, "META", 4, 0);
    GvMULTI_on(gv);

    SV *sv;
    sv_setref_uv(sv = GvSVn(gv), "Object::Pad::MOP::Class", PTR2UV(meta));

    newCONSTSUB(meta->stash, "META", sv);
  }

  return meta;
}

/*******************
 * Attribute hooks *
 *******************/

/* :repr */

static bool classhook_repr_apply(pTHX_ ClassMeta *classmeta, SV *value, SV **hookdata_ptr)
{
  char *val = SvPV_nolen(value); /* all comparisons are ASCII */

  if(strEQ(val, "native")) {
    if(classmeta->type == METATYPE_CLASS && classmeta->cls.foreign_new)
      croak("Cannot switch a subclass of a foreign superclass type to :repr(native)");
    classmeta->repr = REPR_NATIVE;
  }
  else if(strEQ(val, "HASH"))
    classmeta->repr = REPR_HASH;
  else if(strEQ(val, "magic")) {
    if(classmeta->type != METATYPE_CLASS || !classmeta->cls.foreign_new)
      croak("Cannot switch to :repr(magic) without a foreign superclass");
    classmeta->repr = REPR_MAGIC;
  }
  else if(strEQ(val, "default") || strEQ(val, "autoselect"))
    classmeta->repr = REPR_AUTOSELECT;
  else
    croak("Unrecognised class representation type %" SVf, SVfARG(value));

  return FALSE;
}

static const struct ClassHookFuncs classhooks_repr = {
  .ver   = OBJECTPAD_ABIVERSION,
  .flags = OBJECTPAD_FLAG_ATTR_MUST_VALUE,
  .apply = &classhook_repr_apply,
};

/* :compat */

static bool classhook_compat_apply(pTHX_ ClassMeta *classmeta, SV *value, SV **hookdata_ptr)
{
  if(strEQ(SvPV_nolen(value), "invokable")) {
    if(classmeta->type != METATYPE_ROLE)
      croak(":compat(invokable) only applies to a role");

    classmeta->role_is_invokable = true;
  }
  else
    croak("Unrecognised class compatibility argument %" SVf, SVfARG(value));

  return FALSE;
}

static const struct ClassHookFuncs classhooks_compat = {
  .ver   = OBJECTPAD_ABIVERSION,
  .flags = OBJECTPAD_FLAG_ATTR_MUST_VALUE,
  .apply = &classhook_compat_apply,
};

/* :strict */

static bool classhook_strict_apply(pTHX_ ClassMeta *classmeta, SV *value, SV **hookdata_ptr)
{
  if(strEQ(SvPV_nolen(value), "params"))
    classmeta->strict_params = TRUE;
  else
    croak("Unrecognised class strictness type %" SVf, SVfARG(value));

  return FALSE;
}

static const struct ClassHookFuncs classhooks_strict = {
  .ver   = OBJECTPAD_ABIVERSION,
  .flags = OBJECTPAD_FLAG_ATTR_MUST_VALUE,
  .apply = &classhook_strict_apply,
};

void ObjectPad__boot_classes(void)
{
  register_class_attribute("repr", &classhooks_repr);
  register_class_attribute("compat", &classhooks_compat);
  register_class_attribute("strict", &classhooks_strict);
}
