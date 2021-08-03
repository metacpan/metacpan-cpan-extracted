#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "object_pad.h"

#include "perl-backcompat.c.inc"
#include "perl-additions.c.inc"

/* Empty MGVTBL simply for locating instance slots AV */
static MGVTBL vtbl_slotsav = {};

SV *ObjectPad_obj_get_slotsav(pTHX_ SV *self, enum ReprType repr, bool create)
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
        sv_setrv(*slotssvp, (SV *)newAV());

      /* A method invoked during a superclass constructor of a classic perl
       * class might encounter $self without slots. If this is the case we'll
       * invoke initslots now to create it.
       *   https://rt.cpan.org/Ticket/Display.html?id=132263
       */
      if(!slotssvp) {
        HV *selfstash = SvSTASH(SvRV(self));
        GV **gvp = (GV **)hv_fetchs(selfstash, "META", 0);
        if(!gvp)
          croak("Unable to find ClassMeta for %" SVf, SVfARG(HvNAME(selfstash)));

        struct ClassMeta *classmeta = NUM2PTR(ClassMeta *, SvUV(SvRV(GvSV(*gvp))));

        dSP;

        ENTER;
        EXTEND(SP, 1);
        PUSHMARK(SP);
        mPUSHs(newSVsv(self));
        PUTBACK;

        assert(classmeta->initslots);
        call_sv((SV *)classmeta->initslots, G_VOID);

        PUTBACK;
        LEAVE;

        slotssvp = hv_fetchs((HV *)rv, "Object::Pad/slots", 0);
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

MethodMeta *ObjectPad_mop_class_add_method(pTHX_ ClassMeta *meta, SV *methodname)
{
  AV *methods = meta->methods;

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
  AV *slots = meta->slots;

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

  return slotmeta;
}

void ObjectPad_mop_class_add_BUILD(pTHX_ ClassMeta *meta, CV *cv)
{
  if(meta->strict_params)
    croak("Cannot add a BUILD block to a class with :strict(params)");

  if(!meta->buildblocks)
    meta->buildblocks = newAV();

  av_push(meta->buildblocks, (SV *)cv);
}

void ObjectPad_mop_class_add_ADJUST(pTHX_ ClassMeta *meta, CV *cv)
{
  if(!meta->adjustblocks)
    meta->adjustblocks = newAV();

  av_push(meta->adjustblocks, (SV *)cv);
}

static bool mop_class_implements_role(ClassMeta *classmeta, ClassMeta *rolemeta)
{
  U32 i, n = av_count(classmeta->roles);
  RoleEmbedding **arr = (RoleEmbedding **)AvARRAY(classmeta->roles);
  for(i = 0; i < n; i++)
    if(arr[i]->rolemeta == rolemeta)
      return true;

  if(classmeta->supermeta && mop_class_implements_role(classmeta->supermeta, rolemeta))
    return true;

  return false;
}

void ObjectPad_mop_class_compose_role(pTHX_ ClassMeta *classmeta, ClassMeta *rolemeta)
{
  U32 i;

  if(classmeta->type != METATYPE_CLASS)
    croak("Can only apply to a class");
  if(rolemeta->type != METATYPE_ROLE)
    croak("Can only apply a role to a class");

  if(mop_class_implements_role(classmeta, rolemeta))
    return;

  HV *srcstash = rolemeta->stash;
  HV *dststash = classmeta->stash;

  SV *embeddingsv = newSV(sizeof(RoleEmbedding));
  assert(SvTYPE(embeddingsv) == SVt_PV && SvLEN(embeddingsv) >= sizeof(RoleEmbedding));

  RoleEmbedding *embedding = (RoleEmbedding *)SvPVX(embeddingsv);

  embedding->embeddingsv = embeddingsv;
  embedding->rolemeta    = rolemeta;
  embedding->classmeta   = classmeta;
  embedding->offset      = -1;

  av_push(classmeta->roles, (SV *)embedding);

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
    CV *adjustblock = (CV *)AvARRAY(rolemeta->adjustblocks)[i];

    CV *embedded_adjustblock = embed_cv(adjustblock, embedding);

    if(!classmeta->adjustblocks)
      classmeta->adjustblocks = newAV();

    av_push(classmeta->adjustblocks, (SV *)embedded_adjustblock);
  }

  U32 nmethods = av_count(rolemeta->methods);
  for(i = 0; i < nmethods; i++) {
    MethodMeta *methodmeta = (MethodMeta *)AvARRAY(rolemeta->methods)[i];
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
}

void ObjectPad_mop_class_apply_role(pTHX_ RoleEmbedding *embedding)
{
  ClassMeta *classmeta = embedding->classmeta;
  ClassMeta *rolemeta  = embedding->rolemeta;

  if(classmeta->type != METATYPE_CLASS)
    croak("Can only apply to a class");
  if(rolemeta->type != METATYPE_ROLE)
    croak("Can only apply a role to a class");

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

  classmeta->next_slotix += av_count(rolemeta->slots);

  /* TODO: Run an APPLY block if the role has one */
}

static void S_apply_roles(pTHX_ ClassMeta *dst, ClassMeta *src)
{
  U32 nroles = av_count(src->roles);
  RoleEmbedding **arr = (RoleEmbedding **)AvARRAY(src->roles);
  U32 i;
  for(i = 0; i < nroles; i++) {
    mop_class_apply_role(arr[i]);

    /* TODO: Consider how we recurse into roles */
  }
}

static void S_generate_initslots_method(pTHX_ ClassMeta *meta)
{
  OP *ops = NULL;
  int i;

  ENTER;

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

  extend_pad_vars(meta);

  intro_my();

  enum ReprType repr = meta->repr;

  ops = op_append_list(OP_LINESEQ, ops,
    newMETHSTARTOP(OPf_MOD |
      (meta->type == METATYPE_ROLE ? OPf_SPECIAL : 0) |
      (repr << 8))
  );

  /* TODO: Icky horrible implementation; if our slotoffset > 0 then
   * we must be a subclass
   */
  if(meta->start_slotix) {
    struct ClassMeta *supermeta = meta->supermeta;

    assert(supermeta->sealed);
    assert(supermeta->initslots);

    CopLINE_set(PL_curcop, __LINE__);

    ops = op_append_list(OP_LINESEQ, ops,
      newSTATEOP(0, NULL, NULL));

    /* Build an OP_ENTERSUB for supermeta's initslots */
    OP *op = NULL;
    op = op_append_list(OP_LIST, op,
      newPADxVOP(OP_PADSV, PADIX_SELF, 0, 0));
    op = op_append_list(OP_LIST, op,
      newSVOP(OP_CONST, 0, (SV *)supermeta->initslots));

    ops = op_append_list(OP_LINESEQ, ops,
      op_convert_list(OP_ENTERSUB, OPf_WANT_VOID|OPf_STACKED, op));
  }

  /* TODO: If in some sort of debug mode: insert equivalent of
   *   if((av_count(self)) != start_slotix)
   *     croak("ARGH: Expected self to have %d slots by now\n", start_slotix);
   */

  AV *slots = meta->slots;
  I32 nslots = av_count(slots);

  {
    CopLINE_set(PL_curcop, __LINE__);

    /* To make an OP_PUSH we have to build a generic OP_LIST then call
     * op_convert_list() on it later
     */
    ops = op_append_list(OP_LINESEQ, ops,
      newSTATEOP(0, NULL, NULL));

    OP *itemops = op_append_elem(OP_LIST, NULL,
      newPADxVOP(OP_PADAV, PADIX_SLOTS, OPf_MOD|OPf_REF, 0));

    for(i = 0; i < nslots; i++) {
      SlotMeta *slotmeta = (SlotMeta *)AvARRAY(slots)[i];
      char sigil = SvPV_nolen(slotmeta->name)[0];
      OP *op = NULL;

      switch(sigil) {
        case '$':
          /* push ..., $defaultsv */

          /* An OP_CONST whose op_type is OP_CUSTOM.
           * This way we avoid the opchecker and finalizer doing bad things to
           * our defaultsv SV by setting it SvREADONLY_on().
           */
          op = newSVOP_CUSTOM(PL_ppaddr[OP_CONST], 0, slotmeta->defaultsv ? slotmeta->defaultsv : &PL_sv_undef);
          break;
        case '@':
          /* push ..., [] */
          op = newLISTOP(OP_ANONLIST, OPf_SPECIAL, newOP(OP_PUSHMARK, 0), NULL);
          break;
        case '%':
          /* push ..., {} */
          op = newLISTOP(OP_ANONHASH, OPf_SPECIAL, newOP(OP_PUSHMARK, 0), NULL);
          break;

        default:
          croak("ARGV: notsure how to handle a slot sigil %c\n", sigil);
      }

      if(op) {
        op_contextualize(op, G_SCALAR);
        itemops = op_append_elem(OP_LIST, itemops, op);
      }
    }

    if(!nslots) {
      itemops = op_append_elem(OP_LIST, itemops, newOP(OP_STUB, OPf_PARENS));
    }

    ops = op_append_list(OP_LINESEQ, ops,
      op_convert_list(OP_PUSH, OPf_WANT_VOID, itemops));

    if(!itemops->op_targ) {
      /* op_convert_list ought to have allocated a pad temporary for push, but
       * it didn't. Technically only -DDEBUGGING perls will notice this,
       * because OP_PUSH in G_VOID doesn't use its targ, but it's polite to
       * provide one all the same. */
      itemops->op_targ = pad_alloc(itemops->op_type, SVs_PADTMP);
    }
  }

  AV *roles = meta->roles;
  I32 nroles = av_count(roles);

  for(i = 0; i < nroles; i++) {
    RoleEmbedding *embedding = (RoleEmbedding *)AvARRAY(roles)[i];
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
      newPADxVOP(OP_PADSV, PADIX_SELF, 0, 0));
    op = op_append_list(OP_LIST, op,
      newSVOP(OP_CONST, 0, (SV *)embed_cv(rolemeta->initslots, embedding)));

    ops = op_append_list(OP_LINESEQ, ops,
      op_convert_list(OP_ENTERSUB, OPf_WANT_VOID|OPf_STACKED, op));
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

  if(meta->supermeta && !meta->supermeta->sealed) {
    /* Must defer sealing until superclass is sealed first
     * (RT133190)
     */
    if(!meta->supermeta->pending_submeta)
      meta->supermeta->pending_submeta = newAV();
    av_push(meta->supermeta->pending_submeta, (SV *)meta);
    return;
  }

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

  HV *parammap = meta->parammap;
  if(parammap) {
    SLOTOFFSET nslots = meta->next_slotix;

    SV *requireslots = meta->requireslots = newSV((nslots + 7) / 8);
    SvPOK_on(requireslots); SvCUR_set(requireslots, (nslots + 7) / 8);

    Zero(SvPVX(requireslots), SvCUR(requireslots), char);

    hv_iterinit(parammap);

    HE *iter;
    while((iter = hv_iternext(parammap))) {
      ParamMeta *parammeta = (ParamMeta *)HeVAL(iter);
      if(parammeta->slot && parammeta->slot->defaultsv)
        continue;

      SLOTOFFSET slotix = parammeta->slotix;
      SvPVX(requireslots)[slotix / 8] |= (1 << (slotix % 8));
    }
  }

  if(meta->strict_params && meta->buildblocks)
    croak("Class %" SVf " cannot be :strict(params) because it has BUILD blocks",
      SVfARG(meta->name));

  {
    U32 slotix;
    for(slotix = 0; slotix < av_count(meta->slots); slotix++) {
      SlotMeta *slotmeta = (SlotMeta *)AvARRAY(meta->slots)[slotix];

      U32 hooki;
      for(hooki = 0; slotmeta->hooks && hooki < av_count(slotmeta->hooks); hooki++) {
        struct SlotHook *h = (struct SlotHook *)AvARRAY(slotmeta->hooks)[hooki];

        if(*h->funcs->post_initslot) {
          if(!meta->slothooks_postslots)
            meta->slothooks_postslots = newAV();

          struct SlotHook *fasth;
          Newx(fasth, 1, struct SlotHook);

          fasth->slotix   = slotix;
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
    CopLINE_set(PL_curcop, __LINE__);

    ENTER;
    SAVETMPS;

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

  bool need_initslots = true;

  if(!meta->foreign_new) {
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

      assert(meta->foreign_new);
      call_sv((SV *)meta->foreign_new, G_SCALAR);
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
     * need_initslots false if so.
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

        need_initslots = !hv_exists(MUTABLE_HV(rv), "Object::Pad/slots", 17);
        break;

      case REPR_MAGIC:
      case_REPR_MAGIC:
        /* Anything goes */

        need_initslots = !mg_findext(rv, PERL_MAGIC_ext, &vtbl_slotsav);
        break;

      case REPR_AUTOSELECT:
        if(SvTYPE(rv) == SVt_PVHV)
          goto case_REPR_HASH;
        goto case_REPR_MAGIC;
    }

    sv_2mortal(self);
  }

  if(need_initslots) {
    /* Run initslots */
    CopLINE_set(PL_curcop, __LINE__);

    ENTER;
    EXTEND(SP, 1);
    PUSHMARK(SP);
    PUSHs(self);
    PUTBACK;

    assert(meta->initslots);
    call_sv((SV *)meta->initslots, G_VOID);

    LEAVE;
  }

  AV *slotsav = (AV *)get_obj_slotsav(self, meta->repr, 0);
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
    AV *slots     = meta->slots;

    U32 i;
    for(i = 0; i < av_count(slothooks); i++) {
      struct SlotHook *h = (struct SlotHook *)AvARRAY(slothooks)[i];
      SLOTOFFSET slotix = h->slotix;
      struct SlotMeta *slotmeta = (struct SlotMeta *)AvARRAY(slots)[slotix];

      (*h->funcs->post_initslot)(aTHX_ slotmeta, h->hookdata, slotsv[slotix]);
    }
  }

  if(meta->parammap) {
    /* Assign params from parammap */
    CopLINE_set(PL_curcop, __LINE__);

    HV *parammap = meta->parammap;
    SV *missingslots = newSVsv(meta->requireslots);
    SAVEFREESV(missingslots);

    char *missingvec = SvPVX(missingslots);

    if(av_count(args) % 2)
      warn("Odd-length list passed to %" SVf " constructor", class);

    SV **argsv = AvARRAY(args);

    IV idx;
    for(idx = 0; idx < av_count(args); idx += 2) {
      SV *name  = argsv[idx];
      SV *value = argsv[idx+1];

      HE *he = hv_fetch_ent(parammap, name, 0, 0);
      if(!he && meta->strict_params) {
        PL_curcop = prevcop;
        croak("Unrecognised parameter '%" SVf "' for %" SVf " constructor",
          SVfARG(name), SVfARG(meta->name));
      }
      else if(!he)
        continue;

      ParamMeta *parammeta = (ParamMeta *)HeVAL(he);
      SLOTOFFSET slotix = parammeta->slotix;

      SV *slot = slotsv[slotix];

      sv_setsv_mg(slot, value);
      missingvec[slotix / 8] &= ~(1 << (slotix % 8));
    }

    /* missingvec should be all zeroes if no missing arguments */
    for(idx = 0; idx < SvCUR(missingslots); idx++) {
      if(!missingvec[idx])
        continue;

      /* We now have at least one missing param so we're going to throw an
       * exception. It doesn't matter if this path is a little slow.
       * Hash iteration order is effectively random, so it's arbitrary which
       * one of the missing params we'll find.
       */
      hv_iterinit(meta->parammap);

      HE *iter;
      while((iter = hv_iternext(meta->parammap))) {
        SLOTOFFSET slotix = ((ParamMeta *)HeVAL(iter))->slotix;

        if(!(missingvec[slotix / 8] & (1 << (slotix % 8))))
          continue;

        /* TODO: Consider accumulating a list of all missing param names */
        PL_curcop = prevcop;
        croak("Required parameter '%s' is missing for %" SVf " constructor",
          HePV(iter, PL_na), meta->name);
      }
    }
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
      CV *adjustblock = (CV *)AvARRAY(adjustblocks)[i];

      ENTER;
      SAVETMPS;
      SPAGAIN;

      /* No args */

      EXTEND(SP, 1);

      PUSHMARK(SP);
      PUSHs(self);
      PUTBACK;

      assert(adjustblock);
      call_sv((SV *)adjustblock, G_VOID);

      FREETMPS;
      LEAVE;
    }
  }

  if(meta->slothooks_construct) {
    CopLINE_set(PL_curcop, __LINE__);

    AV *slothooks = meta->slothooks_construct;
    AV *slots     = meta->slots;

    U32 i;
    for(i = 0; i < av_count(slothooks); i++) {
      struct SlotHook *h = (struct SlotHook *)AvARRAY(slothooks)[i];
      SLOTOFFSET slotix = h->slotix;
      struct SlotMeta *slotmeta = (struct SlotMeta *)AvARRAY(slots)[slotix];

      (*h->funcs->post_construct)(aTHX_ slotmeta, h->hookdata, slotsv[slotix]);
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
    AV *roles = meta->roles;
    I32 nroles = av_count(roles);

    if(!cv_does && meta->foreign_does)
      cv_does = meta->foreign_does;

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

    meta = meta->supermeta;
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
  ClassMeta *meta;
  Newx(meta, 1, ClassMeta);

  meta->type = type;
  meta->name = SvREFCNT_inc(name);

  HV *stash = meta->stash = gv_stashsv(name, GV_ADD);

  meta->sealed = false;
  meta->role_is_invokable = false;
  meta->strict_params = false;
  meta->start_slotix = 0;
  meta->slots   = newAV();
  meta->methods = newAV();
  meta->parammap = NULL;
  meta->requireslots = NULL;
  meta->requiremethods = newAV();
  meta->repr   = REPR_AUTOSELECT;
  meta->foreign_new = NULL;
  meta->foreign_does = NULL;
  meta->supermeta = NULL;
  meta->pending_submeta = NULL;
  meta->roles = newAV();
  meta->buildblocks = NULL;
  meta->adjustblocks = NULL;
  meta->initslots = NULL;

  meta->slothooks_postslots = NULL;
  meta->slothooks_construct = NULL;

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
      meta->foreign_new = supermeta->foreign_new;

      if(supermeta->buildblocks) {
        AV *superbuildblocks = supermeta->buildblocks;
        U32 i;

        if(!meta->buildblocks)
          meta->buildblocks = newAV();

        for(i = 0; i < av_count(superbuildblocks); i++)
          av_push(meta->buildblocks, /* no inc */ AvARRAY(superbuildblocks)[i]);
      }

      if(supermeta->adjustblocks) {
        AV *superadjustblocks = supermeta->adjustblocks;
        U32 i;

        if(!meta->adjustblocks)
          meta->adjustblocks = newAV();

        for(i = 0; i < av_count(superadjustblocks); i++)
          av_push(meta->adjustblocks, /* no inc */ AvARRAY(superadjustblocks)[i]);
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
    }
    else {
      /* A subclass of a foreign class */
      meta->foreign_new = fetch_superclass_method_pv(meta->stash, "new", 3, -1);
      if(!meta->foreign_new)
        croak("Unable to find SUPER::new for %" SVf, superclassname);

      meta->foreign_does = fetch_superclass_method_pv(meta->stash, "DOES", 4, -1);

      av_push(isa, newSVpvs("Object::Pad::UNIVERSAL"));
    }

    meta->supermeta = supermeta;
  }
  else {
    /* A base class */
    av_push(isa, newSVpvs("Object::Pad::UNIVERSAL"));
  }

  if(meta->repr == REPR_AUTOSELECT && !meta->foreign_new)
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
