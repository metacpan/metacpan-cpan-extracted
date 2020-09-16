/*  You may distribute under the terms of either the GNU General Public License
 *  or the Artistic License (the same terms as Perl itself)
 *
 *  (C) Paul Evans, 2019-2020 -- leonerd@leonerd.org.uk
 */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "XSParseSublike.h"

#ifdef HAVE_DMD_HELPER
#  include "DMD_helper.h"
#endif

#ifndef wrap_keyword_plugin
#  include "wrap_keyword_plugin.c.inc"
#endif

#define HAVE_PERL_VERSION(R, V, S) \
    (PERL_REVISION > (R) || (PERL_REVISION == (R) && (PERL_VERSION > (V) || (PERL_VERSION == (V) && (PERL_SUBVERSION >= (S))))))

#if HAVE_PERL_VERSION(5, 26, 0)
#  define HAVE_PARSE_SUBSIGNATURE
#  define HAVE_OP_ARGCHECK
#endif

#include "perl-additions.c.inc"

#include "perl-backcompat.c.inc"

#include "lexer-additions.c.inc"

/********************************
 * Some handy utility functions *
 ********************************/

#if HAVE_PERL_VERSION(5, 22, 0)
#  define HAVE_UNOP_AUX
#endif

#ifndef HAVE_UNOP_AUX
typedef struct {
  UNOP baseop;
  IV   iv;
} UNOP_with_IV;

#define newUNOP_with_IV(type, flags, first, iv)  S_newUNOP_with_IV(aTHX_ type, flags, first, iv)
static OP *S_newUNOP_with_IV(pTHX_ I32 type, I32 flags, OP *first, IV iv)
{
  /* Cargoculted from perl's op.c:Perl_newUNOP()
   */
  UNOP_with_IV *op = PerlMemShared_malloc(sizeof(UNOP_with_IV) * 1);
  NewOp(1101, op, 1, UNOP_with_IV);

  if(!first)
    first = newOP(OP_STUB, 0);
  UNOP *unop = (UNOP *)op;
  unop->op_type = (OPCODE)type;
  unop->op_first = first;
  unop->op_ppaddr = NULL;
  unop->op_flags = (U8)flags | OPf_KIDS;
  unop->op_private = (U8)(1 | (flags >> 8));

  op->iv = iv;

  return (OP *)op;
}
#endif

#define newMETHOD_REDIR_OP(rclass, methname, flags)  S_newMETHOD_REDIR_OP(aTHX_ rclass, methname, flags)
static OP *S_newMETHOD_REDIR_OP(pTHX_ SV *rclass, SV *methname, I32 flags)
{
#if HAVE_PERL_VERSION(5, 22, 0)
  OP *op = newMETHOP_named(OP_METHOD_REDIR, flags, methname);
#  ifdef USE_ITHREADS
  {
    /* cargoculted from S_op_relocate_sv() */
    PADOFFSET ix = pad_alloc(OP_CONST, SVf_READONLY);
    PAD_SETSV(ix, rclass);
    cMETHOPx(op)->op_rclass_targ = ix;
  }
#  else
  cMETHOPx(op)->op_rclass_sv = rclass;
#  endif
#else
  OP *op = newUNOP(OP_METHOD, flags,
    newSVOP(OP_CONST, 0, newSVpvf("%" SVf "::%" SVf, rclass, methname)));
#endif

  return op;
}

#define import_pragma(pragma, arg)  S_import_pragma(aTHX_ pragma, arg)
static void S_import_pragma(pTHX_ const char *pragma, const char *arg)
{
  dSP;
  bool unimport = FALSE;

  if(pragma[0] == '-') {
    unimport = TRUE;
    pragma++;
  }

  SAVETMPS;

  EXTEND(SP, 2);
  PUSHMARK(SP);
  mPUSHp(pragma, strlen(pragma));
  if(arg)
    mPUSHp(arg, strlen(arg));
  PUTBACK;

  call_method(unimport ? "unimport" : "import", G_VOID);

  FREETMPS;
}

#define ensure_module_version(module, version)  S_ensure_module_version(aTHX_ module, version)
static void S_ensure_module_version(pTHX_ SV *module, SV *version)
{
  dSP;

  ENTER;

  PUSHMARK(SP);
  PUSHs(module);
  PUSHs(version);
  PUTBACK;

  call_method("VERSION", G_VOID);

  LEAVE;
}

#define fetch_superclass_method_pv(stash, pv, len, level)  S_fetch_superclass_method_pv(aTHX_ stash, pv, len, level)
static CV *S_fetch_superclass_method_pv(pTHX_ HV *stash, const char *pv, STRLEN len, U32 level)
{
#if HAVE_PERL_VERSION(5, 18, 0)
  GV *gv = gv_fetchmeth_pvn(stash, pv, len, level, GV_SUPER);
#else
  SV *superclassname = newSVpvf("%*s::SUPER", HvNAMELEN_get(stash), HvNAME_get(stash));
  if(HvNAMEUTF8(stash))
    SvUTF8_on(superclassname);
  SAVEFREESV(superclassname);

  HV *superstash = gv_stashsv(superclassname, GV_ADD);
  GV *gv = gv_fetchmeth_pvn(superstash, pv, len, level, 0);
#endif

  if(!gv)
    return NULL;
  return GvCV(gv);
}

#define get_class_isa(stash)  S_get_class_isa(aTHX_ stash)
static AV *S_get_class_isa(pTHX_ HV *stash)
{
  GV **gvp = (GV **)hv_fetchs(stash, "ISA", 0);
  if(!gvp || !GvAV(*gvp))
    croak("Expected %s to have a @ISA list", HvNAME(stash));

  return GvAV(*gvp);
}

#define find_cop_for_lvintro(padix, o, copp)  S_find_cop_for_lvintro(aTHX_ padix, o, copp)
static COP *S_find_cop_for_lvintro(pTHX_ PADOFFSET padix, OP *o, COP **copp)
{
  for( ; o; o = OpSIBLING(o)) {
    if(OP_CLASS(o) == OA_COP) {
      *copp = (COP *)o;
    }
    else if(o->op_type == OP_PADSV && o->op_targ == padix && o->op_private & OPpLVAL_INTRO) {
      return *copp;
    }
    else if(o->op_flags & OPf_KIDS) {
      COP *ret = find_cop_for_lvintro(padix, cUNOPx(o)->op_first, copp);
      if(ret)
        return ret;
    }
  }

  return NULL;
}

#define make_croak_op(message)  S_make_croak_op(aTHX_ message)
static OP *S_make_croak_op(pTHX_ const char *message)
{
  SV *sv = newSVpvn(message, strlen(message));

#if HAVE_PERL_VERSION(5, 22, 0)
  sv_catpvs(sv, " at %s line %d.\n");
  /* die sprintf($message, (caller)[1,2]) */
  return op_convert_list(OP_DIE, 0,
    op_convert_list(OP_SPRINTF, 0,
      op_append_list(OP_LIST,
        newSVOP(OP_CONST, 0, sv),
        newSLICEOP(0,
          op_append_list(OP_LIST,
            newSVOP(OP_CONST, 0, newSViv(1)),
            newSVOP(OP_CONST, 0, newSViv(2))),
          newOP(OP_CALLER, 0)))));
#else
  /* For some reason I can't work out, the above tree isn't correct. Attempts
   * to correct it still make OP_SPRINTF crash with "Out of memory!". For now
   * lets just avoid the sprintf
   */
  sv_catpvs(sv, "\n");
  return newLISTOP(OP_DIE, 0, newOP(OP_PUSHMARK, 0),
    newSVOP(OP_CONST, 0, sv));
#endif
}

#define make_argcheck_ops(required, optional, slurpy)  S_make_argcheck_ops(aTHX_ required, optional, slurpy)
static OP *S_make_argcheck_ops(pTHX_ int required, int optional, char slurpy)
{
#ifdef HAVE_OP_ARGCHECK
  UNOP_AUX_item *aux = (UNOP_AUX_item *)PerlMemShared_malloc(sizeof(UNOP_AUX_item) * 3);
  aux[0].iv = required;
  aux[1].iv = optional;
  aux[2].iv = slurpy;

  return op_prepend_elem(OP_LINESEQ, newSTATEOP(0, NULL, NULL),
      op_prepend_elem(OP_LINESEQ, newUNOP_AUX(OP_ARGCHECK, 0, NULL, aux), NULL));
#else
  /* Older perls lack the convenience of OP_ARGCHECK so we'll have to build an
   * optree ourselves. For now we only support required + optional, no slurpy
   *
   * This code heavily inspired by Perl_parse_subsignature() in toke.c from perl 5.24
   */

  OP *ret = NULL;

  if(required > 0) {
    /* @_ >= required or die ... */
    OP *checkop = 
      newSTATEOP(0, NULL,
        newLOGOP(OP_OR, 0,
          newBINOP(OP_GE, 0,
            /* scalar @_ */
            op_contextualize(newUNOP(OP_RV2AV, 0, newGVOP(OP_GV, 0, PL_defgv)), G_SCALAR),
            newSVOP(OP_CONST, 0, newSViv(required))),
          make_croak_op("Too few arguments for subroutine")));

    ret = op_append_list(OP_LINESEQ, ret, checkop);
  }

  {
    /* @_ <= (required+optional) or die ... */
    OP *checkop =
      newSTATEOP(0, NULL,
        newLOGOP(OP_OR, 0,
          newBINOP(OP_LE, 0,
            /* scalar @_ */
            op_contextualize(newUNOP(OP_RV2AV, 0, newGVOP(OP_GV, 0, PL_defgv)), G_SCALAR),
            newSVOP(OP_CONST, 0, newSViv(required + optional))),
          make_croak_op("Too many arguments for subroutine")));

    ret = op_append_list(OP_LINESEQ, ret, checkop);
  }

  return ret;
#endif
}

typedef void AttributeHandler(pTHX_ void *target, const char *value, void *data);

struct AttributeDefinition {
  char *attrname;
  /* TODO: int flags */
  AttributeHandler *apply;
  void *applydata;
};

/*********************************
 * Class and Slot Implementation *
 *********************************/

/* A SLOTOFFSET is an offset within the AV of an object instance */
typedef IV SLOTOFFSET;

typedef struct ClassMeta ClassMeta;

typedef struct {
  SV *name;
  ClassMeta *class;
  SV *defaultsv;
  SLOTOFFSET slotix;
} SlotMeta;

typedef struct {
  SV *name;
  ClassMeta *class;
  ClassMeta *role;   /* set if inherited from a role */
  /* We don't store the method body CV; leave that in the class stash */
} MethodMeta;

enum MetaType {
  METATYPE_CLASS,
  METATYPE_ROLE,
};

/* Metadata about a class or role */
struct ClassMeta {
  enum MetaType type;
  SV *name;
  HV *stash;
  ClassMeta *supermeta;
  AV *pending_submeta; /* NULL, or AV containing raw ClassMeta pointers to subclasses pending seal */
  AV *roles;           /* each elem is a raw pointer directly to a RoleEmbedding whose type == METATYPE_ROLE */
  bool sealed;
  SLOTOFFSET start_slotix; /* first slot index of this partial within its instance */
  SLOTOFFSET next_slotix;  /* 1 + final slot index of this partial within its instance; includes slots in roles */
  AV *slots;           /* each elem is a raw pointer directly to a SlotMeta */
  AV *methods;         /* each elem is a raw pointer directly to a MethodMeta */
  AV *requiremethods;  /* each elem is an SVt_PV giving a name */
  enum {
    REPR_NATIVE,       /* instances are in native format - blessed AV as slots */
    REPR_HASH,         /* instances are blessed HASHes; our slots live in $self->{"Object::Pad/slots"} */
    REPR_MAGIC,        /* instances store slot AV via magic; superconstructor must be foreign */

    REPR_AUTOSELECT,   /* pick one of the above depending on foreign_new and SvTYPE()==SVt_PVHV */
  } repr;
  CV *foreign_new;     /* superclass is not Object::Pad, here is the constructor */
  CV *initslots;       /* the INITSLOTS method body */
  AV *buildblocks;     /* the BUILD {} phaser blocks; each elem is a CV* directly */

  COP *tmpcop;         /* a COP to use during generated constructor */
  CV *methodscope;     /* a temporary CV used just during compilation of a `method` */
};

/* Metadata about the embedding of a role into a class */
typedef struct {
  SV *embeddingsv;
  struct ClassMeta *rolemeta;
  struct ClassMeta *classmeta;
  PADOFFSET offset;
} RoleEmbedding;

/* Special pad indexes within `method` CVs */
enum {
  PADIX_SELF = 1,
  PADIX_SLOTS = 2,

  /* for role methods */
  PADIX_EMBEDDING = 3,
};

#define embed_cv(cv, embedding)  S_embed_cv(aTHX_ cv, embedding)
static CV *S_embed_cv(pTHX_ CV *cv, RoleEmbedding *embedding)
{
  CV *embedded_cv = cv_clone(cv);

  PAD *pad1 = PadlistARRAY(CvPADLIST(embedded_cv))[1];
  PadARRAY(pad1)[PADIX_EMBEDDING] = SvREFCNT_inc(embedding->embeddingsv);

  return embedded_cv;
}

/* Empty MGVTBL simply for locating instance slots AV */
static MGVTBL vtbl_slotsav = {};

#define get_obj_slotsav(self, repr, create)  S_obj_get_slotsav(aTHX_ self, repr, create)
static SV *S_obj_get_slotsav(pTHX_ SV *self, U8 repr, bool create)
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

#define pad_add_self_slots()  S_pad_add_self_slots(aTHX)
static void S_pad_add_self_slots(pTHX)
{
  PADOFFSET padix;

  padix = pad_add_name_pvs("$self", 0, NULL, NULL);
  if(padix != PADIX_SELF)
    croak("ARGH: Expected that padix[$self] = 1");

  /* Give it a name that isn't valid as a Perl variable so it can't collide */
  padix = pad_add_name_pvs("@(Object::Pad/slots)", 0, NULL, NULL);
  if(padix != PADIX_SLOTS)
    croak("ARGH: Expected that padix[@slots] = 2");
}

static XOP xop_methstart;
static OP *pp_methstart(pTHX)
{
  SV *self = av_shift(GvAV(PL_defgv));
  bool create = PL_op->op_flags & OPf_MOD;
  bool is_role = PL_op->op_flags & OPf_SPECIAL;

  if(!SvROK(self) || !SvOBJECT(SvRV(self)))
    croak("Cannot invoke method on a non-instance");

  HV *classstash;
  SLOTOFFSET offset;
  RoleEmbedding *embedding = NULL;

  if(is_role) {
    /* Embedding info is stored in pad1; PAD_SVl() will look at CvDEPTH. We'll
     * have to grab it manually */
    PAD *pad1 = PadlistARRAY(CvPADLIST(find_runcv(0)))[1];
    embedding = (RoleEmbedding *)SvPVX(PadARRAY(pad1)[PADIX_EMBEDDING]);

    assert(embedding);

    classstash = embedding->classmeta->stash;
    offset     = embedding->offset;
  }
  else {
    classstash = CvSTASH(find_runcv(0));
    offset     = 0;
  }

  const char *stashname = HvNAME(classstash);

  if(!stashname || !sv_derived_from(self, stashname))
    croak("Cannot invoke foreign method on non-derived instance");

  save_clearsv(&PAD_SVl(PADIX_SELF));
  sv_setsv(PAD_SVl(PADIX_SELF), self);

  SV *slotsav;

  if(is_role) {
    SV *instancedata = get_obj_slotsav(self, embedding->classmeta->repr, create);

    if(create) {
      slotsav = instancedata;
      SvREFCNT_inc(slotsav);
    }
    else {
      slotsav = (SV *)newAV();
      /* MASSIVE CHEAT */
      AvARRAY(slotsav) = AvARRAY(instancedata) + offset;
      AvFILLp(slotsav) = AvFILLp(instancedata) - offset;
      AvREAL_off(slotsav);
    }
  }
  else {
    /* op_private contains the repr type so we can extract slots */
    slotsav = get_obj_slotsav(self, PL_op->op_private, create);
    SvREFCNT_inc(slotsav);
  }

  SAVESPTR(PAD_SVl(PADIX_SLOTS));
  PAD_SVl(PADIX_SLOTS) = slotsav;
  save_freesv(slotsav);

  return PL_op->op_next;
}

static OP *newMETHSTARTOP(I32 flags, U8 private)
{
  OP *op = newOP(OP_CUSTOM, flags);
  op->op_ppaddr = &pp_methstart;
  op->op_private = private;
  return op;
}

/* op_private flags on SLOTPAD ops */
enum {
  OPpSLOTPAD_SV,  /* has $x */
  OPpSLOTPAD_AV,  /* has @y */
  OPpSLOTPAD_HV,  /* has %z */
};

static XOP xop_slotpad;
static OP *pp_slotpad(pTHX)
{
#ifdef HAVE_UNOP_AUX
  SLOTOFFSET slotix = PTR2IV(cUNOP_AUX->op_aux);
#else
  UNOP_with_IV *op = (UNOP_with_IV *)PL_op;
  SLOTOFFSET slotix = op->iv;
#endif
  PADOFFSET targ = PL_op->op_targ;

  if(SvTYPE(PAD_SV(PADIX_SLOTS)) != SVt_PVAV)
    croak("ARGH: expected ARRAY of slots at PADIX_SLOTS");

  AV *slotsav = (AV *)PAD_SV(PADIX_SLOTS);

  if(slotix > av_top_index(slotsav))
    croak("ARGH: instance does not have a slot at index %ld", (long int)slotix);

  SV **slots = AvARRAY(slotsav);

  SV *slot = slots[slotix];

  SV *val;
  switch(PL_op->op_private) {
    case OPpSLOTPAD_SV:
      val = slot;
      break;
    case OPpSLOTPAD_AV:
      if(!SvROK(slot) || SvTYPE(val = SvRV(slot)) != SVt_PVAV)
        croak("ARGH: expected to find an ARRAY reference at slot index %ld", (long int)slotix);
      break;
    case OPpSLOTPAD_HV:
      if(!SvROK(slot) || SvTYPE(val = SvRV(slot)) != SVt_PVHV)
        croak("ARGH: expected to find a HASH reference at slot index %ld", (long int)slotix);
      break;
    default:
      croak("ARGH: unsure what to do with this slot type");
  }

  SAVESPTR(PAD_SVl(targ));
  PAD_SVl(targ) = SvREFCNT_inc(val);
  save_freesv(val);

  return PL_op->op_next;
}

/* Just like OP_CONST except it doesn't set SvREADONLY on the target SV */
static OP *pp_sv(pTHX)
{
  dSP;
  EXTEND(SP, 1);
  PUSHs(cSVOP->op_sv);
  PUTBACK;
  return PL_op->op_next;
}

static OP *newSVOP_SV(SV *sv, I32 flags)
{
  OP *op = newSVOP_CUSTOM(flags, sv);
  op->op_ppaddr = &pp_sv;
  return op;
}

static OP *newSLOTPADOP(I32 flags, U8 private, PADOFFSET padix, SLOTOFFSET slotix)
{
#ifdef HAVE_UNOP_AUX
  OP *op = newUNOP_AUX(OP_CUSTOM, flags, NULL, NUM2PTR(UNOP_AUX_item *, slotix));
#else
  OP *op = newUNOP_with_IV(OP_CUSTOM, flags, NULL, slotix);
#endif
  op->op_targ = padix;
  op->op_private = private;
  op->op_ppaddr = &pp_slotpad;

  return op;
}

static void S_generate_initslots_method(pTHX_ ClassMeta *meta)
{
  OP *ops = NULL;
  int i;

  ENTER;

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

  pad_add_self_slots();

  if(meta->type == METATYPE_ROLE) {
    PADOFFSET padix = pad_add_name_pvs("$(embedding)", 0, NULL, NULL);
    if(padix != PADIX_EMBEDDING)
      croak("ARGH: Expected that padix[$(embedding)] = 3");
  }

  intro_my();

  U8 repr = meta->repr;

  ops = op_append_list(OP_LINESEQ, ops,
    newMETHSTARTOP(OPf_MOD |
      (meta->type == METATYPE_ROLE ? OPf_SPECIAL : 0), repr)
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
          op = newSVOP_SV(slotmeta->defaultsv, 0);
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

  LEAVE;
}

/* The metadata on the currently-compiling class */
#define compclassmeta       S_compclassmeta(aTHX)
static ClassMeta *S_compclassmeta(pTHX)
{
  SV **svp = hv_fetchs(GvHV(PL_hintgv), "Object::Pad/compclassmeta", 0);
  if(!svp || !*svp || !SvOK(*svp))
    return NULL;
  return (ClassMeta *)SvIV(*svp);
}

#define have_compclassmeta  S_have_compclassmeta(aTHX)
static bool S_have_compclassmeta(pTHX)
{
  SV **svp = hv_fetchs(GvHV(PL_hintgv), "Object::Pad/compclassmeta", 0);
  if(!svp || !*svp)
    return false;

  if(SvOK(*svp) && SvIV(*svp))
    return true;

  return false;
}

#define compclassmeta_set(meta)  S_compclassmeta_set(aTHX_ meta)
static void S_compclassmeta_set(pTHX_ ClassMeta *meta)
{
  SV *sv = *hv_fetchs(GvHV(PL_hintgv), "Object::Pad/compclassmeta", GV_ADD);
  sv_setiv(sv, (IV)meta);
}

static XS(injected_constructor);
static XS(injected_constructor)
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

  {
    CopLINE_set(PL_curcop, __LINE__);
    ENTER;
    SAVETMPS;
    SPAGAIN;

    /* TODO: This list will be constant for any given class so we should
     * cache it in the classmeta
     */
    AV *all_buildblocks = newAV();
    SAVEFREESV(all_buildblocks);

    const ClassMeta *m;
    for(m = meta; m; m = m->supermeta) {
      int i;
      if(!m->buildblocks)
        continue;
      SV **elems = AvARRAY(m->buildblocks);

      /* These need to be pushed in reverse order */
      for(i = AvFILL(m->buildblocks); i >= 0; i--)
        av_push(all_buildblocks, SvREFCNT_inc(elems[i]));
    }

    SV **argsvs = AvARRAY(args);
    int i;
    for(i = AvFILL(all_buildblocks); i >= 0; i--) {
      CV *buildblock = (CV *)AvARRAY(all_buildblocks)[i];

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

    FREETMPS;
    LEAVE;
  }

  PL_curcop = prevcop;
  ST(0) = self;
  XSRETURN(1);
}

#define mop_create_class(type, name, super)  S_mop_create_class(aTHX_ type, name, super)
static ClassMeta *S_mop_create_class(pTHX_ enum MetaType type, SV *name, SV *superclassname)
{
  ClassMeta *meta;
  Newx(meta, 1, ClassMeta);

  meta->type = type;
  meta->name = SvREFCNT_inc(name);

  HV *stash = meta->stash = gv_stashsv(name, GV_ADD);

  meta->sealed = false;
  meta->start_slotix = 0;
  meta->slots   = newAV();
  meta->methods = newAV();
  meta->requiremethods = newAV();
  meta->repr   = REPR_AUTOSELECT;
  meta->foreign_new = NULL;
  meta->supermeta = NULL;
  meta->pending_submeta = NULL;
  meta->roles = newAV();
  meta->buildblocks = NULL;
  meta->initslots = NULL;

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

    isa = get_av(SvPV_nolen(isaname), GV_ADD | (SvUTF8(name) ? SVf_UTF8 : 0));
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
      meta->start_slotix = supermeta->next_slotix;
      meta->repr = supermeta->repr;
      meta->foreign_new = supermeta->foreign_new;
    }
    else {
      /* A subclass of a foreign class */
      meta->foreign_new = fetch_superclass_method_pv(meta->stash, "new", 3, -1);
      if(!meta->foreign_new)
        croak("Unable to find SUPER::new for %" SVf, superclassname);

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

    CV *newcv = newXS(SvPV_nolen(newname), injected_constructor, __FILE__);
    CvXSUBANY(newcv).any_ptr = meta;
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

static void S_set_class_repr(pTHX_ ClassMeta *meta, const char *val, void *_)
{
  if(!val)
    croak(":repr attribute requires a representation type specification");

  if(strEQ(val, "native")) {
    if(meta->foreign_new)
      croak("Cannot switch a subclass of a foreign superclass type to :repr(native)");
    meta->repr = REPR_NATIVE;
  }
  else if(strEQ(val, "HASH"))
    meta->repr = REPR_HASH;
  else if(strEQ(val, "magic")) {
    if(!meta->foreign_new)
      croak("Cannot switch to :repr(magic) without a foreign superclass");
    meta->repr = REPR_MAGIC;
  }
  else if(strEQ(val, "default") || strEQ(val, "autoselect"))
    meta->repr = REPR_AUTOSELECT;
  else
    croak("Unrecognised class representation type %s", val);
}

static struct AttributeDefinition class_attributes[] = {
  { "repr", (AttributeHandler *)&S_set_class_repr, NULL },
  { 0 },
};

#define mop_class_add_method(class, methodname)  S_mop_class_add_method(aTHX_ class, methodname)
static MethodMeta *S_mop_class_add_method(pTHX_ ClassMeta *meta, SV *methodname)
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

#define mop_class_add_slot(class, slotname)  S_mop_class_add_slot(aTHX_ class, slotname)
static SlotMeta *S_mop_class_add_slot(pTHX_ ClassMeta *meta, SV *slotname)
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

  SlotMeta *slotmeta;
  Newx(slotmeta, 1, SlotMeta);

  slotmeta->name = SvREFCNT_inc(slotname);
  slotmeta->class = meta;
  slotmeta->slotix = meta->next_slotix;
  slotmeta->defaultsv = newSV(0);

  av_push(slots, (SV *)slotmeta);
  meta->next_slotix++;

  return slotmeta;
}

#define mop_class_add_BUILD(class, cv)  S_mop_class_add_BUILD(aTHX_ class, cv)
static void S_mop_class_add_BUILD(pTHX_ ClassMeta *meta, CV *cv)
{
  if(!meta->buildblocks)
    meta->buildblocks = newAV();

  av_push(meta->buildblocks, (SV *)cv);
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

#define mop_class_compose_role(class, role)  S_mop_class_compose_role(aTHX_ class, role)
static void S_mop_class_compose_role(pTHX_ ClassMeta *classmeta, ClassMeta *rolemeta)
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

    GvCV_set(*gvp, embed_cv(GvCV((GV *)HeVAL(he)), embedding));
  }

  nmethods = av_count(rolemeta->requiremethods);
  for(i = 0; i < nmethods; i++) {
    av_push(classmeta->requiremethods, SvREFCNT_inc(AvARRAY(rolemeta->requiremethods)[i]));
  }
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

  embedding->offset = classmeta->next_slotix;

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

#define mop_class_seal(meta)  S_mop_class_seal(aTHX_ meta)
static void S_mop_class_seal(pTHX_ ClassMeta *meta)
{
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

static XS(xsub_mop_class_seal)
{
  dXSARGS;
  ClassMeta *meta = XSANY.any_ptr;

  PERL_UNUSED_ARG(items);

  if(!PL_parser) {
    /* We need to generate just enough of a PL_parser to keep newSTATEOP()
     * happy, otherwise it will SIGSEGV
     */
    SAVEVPTR(PL_parser);
    Newxz(PL_parser, 1, yy_parser);
    SAVEFREEPV(PL_parser);

    PL_parser->copline = NOLINE;
#if HAVE_PERL_VERSION(5, 20, 0)
    PL_parser->preambling = NOLINE;
#endif
  }

  mop_class_seal(meta);
}

enum {
  ACCESSOR,
  ACCESSOR_READER,
  ACCESSOR_WRITER,
  ACCESSOR_LVALUE_MUTATOR,
};
static void S_generate_slot_accessor(pTHX_ SlotMeta *slotmeta, const char *mname, void *_data)
{
  int type = PTR2IV(_data);

  if(SvPVX(slotmeta->name)[0] != '$')
    /* TODO: A reader for an array or hash slot should also be fine */
    croak("Can only generate accessors for scalar slots");

  ENTER;

  if(!mname) {
    if(SvPVX(slotmeta->name)[1] == '_')
      mname = SvPVX(slotmeta->name) + 2;
    else
      mname = SvPVX(slotmeta->name) + 1;

    if(type == ACCESSOR_WRITER) {
      SV *namesv = newSVpvf("set_%s", mname);
      SAVEFREESV(namesv);
      mname = SvPVX(namesv);
    }
  }

  ClassMeta *classmeta = slotmeta->class;

  I32 floor_ix = start_subparse(FALSE, 0);
  SAVEFREESV(PL_compcv);

  I32 save_ix = block_start(TRUE);

  pad_add_self_slots();

  PADOFFSET padix = pad_add_name_sv(slotmeta->name, 0, NULL, NULL);
  intro_my();

  OP *ops = op_append_list(OP_LINESEQ, NULL,
    newSTATEOP(0, NULL, NULL));
  ops = op_append_list(OP_LINESEQ, ops,
    newMETHSTARTOP(0 |
      (classmeta->type == METATYPE_ROLE ? OPf_SPECIAL : 0), classmeta->repr));

  ops = op_append_list(OP_LINESEQ, ops,
    make_argcheck_ops((type == ACCESSOR_WRITER) ? 1 : 0, 0, 0));

  ops = op_append_list(OP_LINESEQ, ops,
    newSLOTPADOP(0, OPpSLOTPAD_SV, padix, slotmeta->slotix));

  switch(type) {
    case ACCESSOR_LVALUE_MUTATOR:
      CvLVALUE_on(PL_compcv);
      /* fallthrough */
    case ACCESSOR_READER:
      ops = op_append_list(OP_LINESEQ, ops,
        newLISTOP(OP_RETURN, 0,
          newOP(OP_PUSHMARK, 0),
          newPADxVOP(OP_PADSV, padix, 0, 0)));
      break;

    case ACCESSOR_WRITER:
      ops = op_append_list(OP_LINESEQ, ops,
        newBINOP(OP_SASSIGN, 0,
          newOP(OP_SHIFT, 0),
          newPADxVOP(OP_PADSV, padix, 0, 0)));
      ops = op_append_list(OP_LINESEQ, ops,
        newLISTOP(OP_RETURN, 0,
          newOP(OP_PUSHMARK, 0),
          newPADxVOP(OP_PADSV, PADIX_SELF, 0, 0)));
      break;

    default:
      croak("TODO generate accessor type %d", type);
  }

  SvREFCNT_inc(PL_compcv);
  ops = block_end(save_ix, ops);

  CV *cv = newATTRSUB(floor_ix, newSVOP(OP_CONST, 0, newSVpvf("%" SVf "::%s", classmeta->name, mname)),
    NULL, NULL, ops);
  CvMETHOD_on(cv);

  LEAVE;
}

static struct AttributeDefinition slot_attributes[] = {
  { "reader",  (AttributeHandler *)&S_generate_slot_accessor, (void *)ACCESSOR_READER },
  { "writer",  (AttributeHandler *)&S_generate_slot_accessor, (void *)ACCESSOR_WRITER },
  { "mutator", (AttributeHandler *)&S_generate_slot_accessor, (void *)ACCESSOR_LVALUE_MUTATOR },
  { 0 }
};

static void S_check_method_override(pTHX_ struct XSParseSublikeContext *ctx, const char *val, void *_data)
{
  if(!ctx->name)
    croak("Cannot apply :override to anonymous methods");

  GV *gv = gv_fetchmeth_sv(compclassmeta->stash, ctx->name, 0, 0);
  if(gv && GvCV(gv))
    return;

  croak("Superclass does not have a method named '%" SVf "'", SVfARG(ctx->name));
}

static struct AttributeDefinition method_attributes[] = {
  { "override", (AttributeHandler *)&S_check_method_override, NULL },
  { 0 }
};

/*******************
 * Custom Keywords *
 *******************/

static int keyword_classlike(pTHX_ enum MetaType type, OP **op_ptr)
{
  lex_read_space(0);

  SV *packagename = lex_scan_packagename();
  if(!packagename)
    croak("Expected 'class' to be followed by package name");

  lex_read_space(0);
  SV *packagever = lex_scan_version(PARSE_OPTIONAL);
  lex_read_space(0);

  SV *superclassname = NULL;

  if(lex_consume("extends")) {
    if(superclassname)
      croak("Multiple superclasses are not currently supported");

    lex_read_space(0);
    superclassname = lex_scan_packagename();

    lex_read_space(0);
    SV *superclassver = lex_scan_version(PARSE_OPTIONAL);

    HV *superstash = gv_stashsv(superclassname, 0);
    if(!superstash || !hv_fetchs(superstash, "new", 0)) {
      /* Try to `require` the module then attempt a second time */
      /* load_module() will modify the name argument and take ownership of it */
      load_module(PERL_LOADMOD_NOIMPORT, newSVsv(superclassname), NULL, NULL);
      superstash = gv_stashsv(superclassname, 0);
    }

    if(!superstash)
      croak("Superclass %" SVf " does not exist", superclassname);

    if(superclassver)
      ensure_module_version(superclassname, superclassver);
  }

  ClassMeta *meta = mop_create_class(type, packagename, superclassname);

  while(1) {
    lex_read_space(0);

    if(lex_consume("implements")) {
      while(1) {
        lex_read_space(0);
        SV *rolename = lex_scan_packagename();

        lex_read_space(0);
        SV *rolever = lex_scan_version(PARSE_OPTIONAL);

        HV *rolestash = gv_stashsv(rolename, 0);
        if(!rolestash || !hv_fetchs(rolestash, "META", 0)) {
          /* Try to`require` the module then attempt a second time */
          load_module(PERL_LOADMOD_NOIMPORT, newSVsv(rolename), NULL, NULL);
          rolestash = gv_stashsv(rolename, 0);
        }

        if(!rolestash)
          croak("Role %" SVf " does not exist", SVfARG(rolename));

        if(rolever)
          ensure_module_version(rolename, rolever);

        GV **metagvp = (GV **)hv_fetchs(rolestash, "META", 0);
        ClassMeta *rolemeta = NULL;
        if(metagvp)
          rolemeta = NUM2PTR(ClassMeta *, SvUV(SvRV(GvSV(*metagvp))));

        if(!rolemeta || rolemeta->type != METATYPE_ROLE)
          croak("%" SVf " is not a role", SVfARG(rolename));

        mop_class_compose_role(meta, rolemeta);

        if(!lex_consume(","))
          break;
      }
    }

    else
      break;
  }

  if(superclassname)
    SvREFCNT_dec(superclassname);

  if(lex_consume(":")) {
    SV *attr = newSV(0), *val = newSV(0);
    SAVEFREESV(attr); SAVEFREESV(val);

    while(lex_scan_attrval_into(attr, val)) {
      lex_read_space(0);

      struct AttributeDefinition *def;
      for(def = class_attributes; def->attrname; def++) {
        if(!strEQ(SvPVX(attr), def->attrname))
          continue;

        (*def->apply)(aTHX_ meta, SvPOK(val) ? SvPVX(val) : NULL, def->applydata);

        goto done;
      }

      croak("Unrecognised class attribute :%" SVf, SVfARG(attr));

done:
      /* Accept additional colons to prefix additional attrs */
      if(lex_peek_unichar(0) == ':') {
        lex_read_unichar(0);
        lex_read_space(0);
      }
    }
  }

  bool is_block;

  if(lex_consume("{")) {
    is_block = true;
    ENTER;
  }
  else if(lex_consume(";")) {
    is_block = false;
  }
  else
    croak("Expected a block or ';'");

  import_pragma("strict", NULL);
#if HAVE_PERL_VERSION(5, 31, 9)
  import_pragma("-feature", "indirect");
#else
  import_pragma("-indirect", ":fatal");
#endif
#ifdef HAVE_PARSE_SUBSIGNATURE
  import_pragma("experimental", "signatures");
#endif

  /* CARGOCULT from perl/op.c:Perl_package() */
  {
    SAVEGENERICSV(PL_curstash);
    save_item(PL_curstname);

    PL_curstash = (HV *)SvREFCNT_inc(meta->stash);
    sv_setsv(PL_curstname, packagename);

    PL_hints |= HINT_BLOCK_SCOPE;
    PL_parser->copline = NOLINE;
  }

  if(packagever) {
    /* stolen from op.c because Perl_package_version isn't exported */
    U32 savehints = PL_hints;
    PL_hints &= ~HINT_STRICT_VARS;

    sv_setsv(GvSV(gv_fetchpvs("VERSION", GV_ADDMULTI, SVt_PV)), packagever);

    PL_hints = savehints;
  }

  if(is_block) {
    I32 save_ix = block_start(TRUE);
    compclassmeta_set(meta);

    OP *body = parse_stmtseq(0);
    body = block_end(save_ix, body);

    if(!lex_consume("}"))
      croak("Expected }");

    mop_class_seal(meta);

    LEAVE;

    /* CARGOCULT from perl/perly.y:PACKAGE BAREWORD BAREWORD '{' */
    /* a block is a loop that happens once */
    *op_ptr = newWHILEOP(0, 1, NULL, NULL, body, NULL, 0);
    return KEYWORD_PLUGIN_STMT;
  }
  else {
    SAVEDESTRUCTOR_X(&S_mop_class_seal, meta);

    SAVEHINTS();
    compclassmeta_set(meta);

    *op_ptr = newOP(OP_NULL, 0);
    return KEYWORD_PLUGIN_STMT;
  }
}

static int keyword_has(pTHX_ OP **op_ptr)
{
  if(!have_compclassmeta)
    croak("Cannot 'has' outside of 'class'");

  lex_read_space(0);
  SV *name = lex_scan_lexvar();
  if(!name)
    croak("Expected a slot name");

  ENTER;

  SlotMeta *slotmeta = mop_class_add_slot(compclassmeta, name);
  SvREFCNT_dec(name);

  lex_read_space(0);

  if(lex_peek_unichar(0) == ':') {
    lex_read_unichar(0);
    lex_read_space(0);

    SV *slotmetasv = newSV(0);
    sv_setref_uv(slotmetasv, "Object::Pad::MOP::Slot", PTR2UV(slotmeta));
    SAVEFREESV(slotmetasv);

    SV *attrname = newSV(0), *attrval = newSV(0);
    SAVEFREESV(attrname); SAVEFREESV(attrval);

    while(lex_scan_attrval_into(attrname, attrval)) {
      lex_read_space(0);

      struct AttributeDefinition *def;
      for(def = slot_attributes; def->attrname; def++) {
        if(!strEQ(SvPVX(attrname), def->attrname))
          continue;

        (*def->apply)(aTHX_ slotmeta, SvPOK(attrval) ? SvPVX(attrval) : NULL, def->applydata);

        goto done;
      }

      croak("Unrecognised slot attribute :%" SVf, SVfARG(attrname));

done:
      /* Accept additional colons to prefix additional attrs */
      if(lex_peek_unichar(0) == ':') {
        lex_read_unichar(0);
        lex_read_space(0);
      }
    }
  }

  *op_ptr = NULL;

  /* It would be nice to just yield some OP to represent the has slot here
   * and let normal parsing of normal scalar assignment accept it. But we can't
   * because scalar assignment tries to peephole far too deply into us and
   * everything breaks... :/
   */
  if(lex_peek_unichar(0) == '=') {
    lex_read_unichar(0);
    lex_read_space(0);

    if(SvPV_nolen(name)[0] != '$')
      croak("Can only attach a default expression to a 'has' default");

    OP *op = parse_termexpr(0);

    if(!op || PL_parser->error_count) {
      LEAVE;
      return 0;
    }

    *op_ptr = newBINOP(OP_SASSIGN, 0,
      op,
      newSVOP_SV(SvREFCNT_inc(slotmeta->defaultsv), 0));
  }

  if(lex_read_unichar(0) != ';') {
    croak("Expected default expression or end of statement");
  }

  if(!*op_ptr)
    *op_ptr = newOP(OP_NULL, 0);

  LEAVE;

  return KEYWORD_PLUGIN_STMT;
}

/* We use the method-like keyword parser to parse phaser blocks as well as
 * methods. In order to tell what is going on, hookdata will be an integer
 * set to one of the following
 */

enum PhaserType {
  PHASER_NONE, /* A normal `method`; i.e. not a phaser */
  PHASER_BUILD,
};

static bool parse_permit(pTHX_ void *hookdata)
{
  HV *hints = GvHV(PL_hintgv);

  if(!hv_fetchs(hints, "Object::Pad/method", 0))
    return false;

  if(!have_compclassmeta)
    croak("Cannot 'method' outside of 'class'");

  return true;
}

static void parse_pre_subparse(pTHX_ struct XSParseSublikeContext *ctx, void *hookdata)
{
  enum PhaserType type = PTR2UV(hookdata);
  U32 i;
  AV *slots = compclassmeta->slots;
  U32 nslots = av_count(slots);

  switch(type) {
    case PHASER_NONE:
      if(ctx->name && strEQ(SvPVX(ctx->name), "BUILD"))
        warn("method BUILD is discouraged; use a BUILD block instead");
      break;

    case PHASER_BUILD:
      break;
  }

  if(type != PHASER_NONE)
    /* We need to fool start_subparse() into thinking this is a named function
     * so it emits a real CV and not a protosub
     */
    ctx->name = newSVpvs("(phaser)");

  /* Save the methodscope for this subparse, in case of nested methods
   *   (RT132321)
   */
  SAVESPTR(compclassmeta->methodscope);

  /* While creating the new scope CV we need to ENTER a block so as not to
   * break any interpvars
   */
  ENTER;
  SAVESPTR(PL_comppad);
  SAVESPTR(PL_comppad_name);
  SAVESPTR(PL_curpad);

  CV *methodscope = compclassmeta->methodscope = MUTABLE_CV(newSV_type(SVt_PVCV));
  CvPADLIST(methodscope) = pad_new(padnew_SAVE);

  PL_comppad = PadlistARRAY(CvPADLIST(methodscope))[1];
  PL_comppad_name = PadlistNAMES(CvPADLIST(methodscope));
  PL_curpad  = AvARRAY(PL_comppad);

  for(i = 0; i < nslots; i++) {
    SlotMeta *slotmeta = (SlotMeta *)AvARRAY(slots)[i];

    /* Skip the anonymous ones */
    if(SvCUR(slotmeta->name) < 2)
      continue;

    /* Claim these are all STATE variables just to quiet the "will not stay
     * shared" warning */
    pad_add_name_sv(slotmeta->name, padadd_STATE, NULL, NULL);
  }

  intro_my();

  LEAVE;
}

static bool parse_filter_attr(pTHX_ struct XSParseSublikeContext *ctx, SV *attr, SV *val, void *hookdata)
{
  struct AttributeDefinition *def;
  for(def = method_attributes; def->attrname; def++) {
    if(!strEQ(SvPVX(attr), def->attrname))
      continue;

    /* TODO: We might want to wrap the CV in some sort of MethodMeta struct
     * but for now we'll just pass the XSParseSublikeContext context */
    (*def->apply)(aTHX_ ctx, SvPOK(val) ? SvPVX(val) : NULL, def->applydata);

    return true;
  }

  /* No error, just let it fall back to usual attribute handling */
  return false;
}

static void parse_post_blockstart(pTHX_ struct XSParseSublikeContext *ctx, void *hookdata)
{
  /* Splice in the slot scope CV in */
  CV *methodscope = compclassmeta->methodscope;

  if(CvANON(PL_compcv))
    CvANON_on(methodscope);

  CvOUTSIDE    (methodscope) = CvOUTSIDE    (PL_compcv);
  CvOUTSIDE_SEQ(methodscope) = CvOUTSIDE_SEQ(PL_compcv);

  CvOUTSIDE(PL_compcv) = methodscope;

  pad_add_self_slots();

  if(compclassmeta->type == METATYPE_ROLE) {
    PADOFFSET padix = pad_add_name_pvs("$(embedding)", 0, NULL, NULL);
    if(padix != PADIX_EMBEDDING)
      croak("ARGH: Expected that padix[$(embedding)] = 3");
  }

  intro_my();
}

static void parse_pre_blockend(pTHX_ struct XSParseSublikeContext *ctx, void *hookdata)
{
  enum PhaserType type = PTR2UV(hookdata);
  PADNAMELIST *slotnames = PadlistNAMES(CvPADLIST(compclassmeta->methodscope));
  I32 nslots = av_count(compclassmeta->slots);
  PADNAME **snames = PadnamelistARRAY(slotnames);
  PADNAME **padnames = PadnamelistARRAY(PadlistNAMES(CvPADLIST(PL_compcv)));
  OP *slotops = NULL;

  {
    ENTER;
    SAVEVPTR(PL_curcop);

    /* See https://rt.cpan.org/Ticket/Display.html?id=132428
     *   https://github.com/Perl/perl5/issues/17754
     */
    PADOFFSET padix;
    for(padix = PADIX_SELF + 1; padix <= PadnamelistMAX(PadlistNAMES(CvPADLIST(PL_compcv))); padix++) {
      PADNAME *pn = padnames[padix];

      if(PadnameIsNULL(pn) || !PadnameLEN(pn))
        continue;

      const char *pv = PadnamePV(pn);
      if(!pv || !strEQ(pv, "$self"))
        continue;

      COP *padcop = NULL;
      if(find_cop_for_lvintro(padix, ctx->body, &padcop))
        PL_curcop = padcop;
      warn("\"my\" variable $self masks earlier declaration in same scope");
    }

    LEAVE;
  }

  slotops = op_append_list(OP_LINESEQ, slotops,
    newSTATEOP(0, NULL, NULL));
  slotops = op_append_list(OP_LINESEQ, slotops,
    newMETHSTARTOP(0 |
      (compclassmeta->type == METATYPE_ROLE ? OPf_SPECIAL : 0), compclassmeta->repr));

  int i;
  for(i = 0; i < nslots; i++) {
    SlotMeta *slotmeta = (SlotMeta *)AvARRAY(compclassmeta->slots)[i];
    PADNAME *slotname = snames[i + 1];

    if(!slotname
#if HAVE_PERL_VERSION(5, 22, 0)
      /* On perl 5.22 and above we can use PadnameREFCNT to detect which pad
       * slots are actually being used
       */
       || PadnameREFCNT(slotname) < 2
#endif
      )
        continue;

    const char *pv = SvPVX(slotmeta->name);
    SLOTOFFSET slotix = slotmeta->slotix;
    PADOFFSET padix = pv ? pad_findmy_pv(pv, 0) : 0;

    U8 private = 0;
    switch(pv[0]) {
      case '$': private = OPpSLOTPAD_SV; break;
      case '@': private = OPpSLOTPAD_AV; break;
      case '%': private = OPpSLOTPAD_HV; break;
    }

    slotops = op_append_list(OP_LINESEQ, slotops,
      /* alias the padix from the slot */
      newSLOTPADOP(0, private, padix, slotix));

#if HAVE_PERL_VERSION(5, 22, 0)
    /* Unshare the padname so the one in the scopeslot returns to refcount 1 */
    PADNAME *newpadname = newPADNAMEpvn(PadnamePV(slotname), PadnameLEN(slotname));
    PadnameREFCNT_dec(padnames[padix]);
    padnames[padix] = newpadname;
#endif
  }

  ctx->body = op_append_list(OP_LINESEQ, slotops, ctx->body);

  compclassmeta->methodscope = NULL;

  /* Restore CvOUTSIDE(PL_compcv) back to where it should be */
  {
    CV *outside = CvOUTSIDE(PL_compcv);
    PADNAMELIST *pnl = PadlistNAMES(CvPADLIST(PL_compcv));
    PADNAMELIST *outside_pnl = PadlistNAMES(CvPADLIST(outside));

    /* Lexical captures will need their parent pad index fixing
     * Technically these only matter for CvANON because they're only used when
     * reconstructing the parent pad captures by OP_ANONCODE. But we might as
     * well be polite and fix them for all CVs
     */
    PADOFFSET padix;
    for(padix = 1; padix <= PadnamelistMAX(pnl); padix++) {
      PADNAME *pn = PadnamelistARRAY(pnl)[padix];
      if(PadnameIsNULL(pn) ||
         !PadnameOUTER(pn) ||
         !PARENT_PAD_INDEX(pn))
        continue;

      PADNAME *outside_pn = PadnamelistARRAY(outside_pnl)[PARENT_PAD_INDEX(pn)];

      PARENT_PAD_INDEX_set(pn, PARENT_PAD_INDEX(outside_pn));
    }

    CvOUTSIDE(PL_compcv)     = CvOUTSIDE(outside);
    CvOUTSIDE_SEQ(PL_compcv) = CvOUTSIDE_SEQ(outside);
  }

  if(type != PHASER_NONE) {
    /* We need to remove the name now to stop newATTRSUB() from creating this
     * as a named symbol table entry
     */
    SvREFCNT_dec(ctx->name);
    ctx->name = NULL;
  }
}

static void parse_post_newcv(pTHX_ struct XSParseSublikeContext *ctx, void *hookdata)
{
  enum PhaserType type = PTR2UV(hookdata);

  if(ctx->cv)
    CvMETHOD_on(ctx->cv);

  switch(type) {
    case PHASER_NONE:
      if(ctx->cv && ctx->name && strEQ(SvPVX(ctx->name), "BUILD"))
        /* Legacy behaviour */
        mop_class_add_BUILD(compclassmeta, (CV *)SvREFCNT_inc((SV *)ctx->cv));

      if(ctx->cv && ctx->name)
        mop_class_add_method(compclassmeta, ctx->name);
      break;

    case PHASER_BUILD:
      mop_class_add_BUILD(compclassmeta, ctx->cv); /* steal */
      break;
  }

  /* Any phaser should parse as if it was a named method. By setting a junk
   * name here we fool XS::Parse::Sublike into thinking it just parsed a named
   * method, so it emits an OP_NULL into the optree and behaves like a
   * statement
   */
  if(type != PHASER_NONE)
    ctx->name = newSVpvs("(phaser)");
}

static struct XSParseSublikeHooks parse_method_hooks = {
  .flags           = XS_PARSE_SUBLIKE_FLAG_FILTERATTRS,
  .permit          = parse_permit,
  .pre_subparse    = parse_pre_subparse,
  .filter_attr     = parse_filter_attr,
  .post_blockstart = parse_post_blockstart,
  .pre_blockend    = parse_pre_blockend,
  .post_newcv      = parse_post_newcv,
};

static struct XSParseSublikeHooks parse_BUILD_hooks = {
  .skip_parts = XS_PARSE_SUBLIKE_PART_NAME|XS_PARSE_SUBLIKE_PART_ATTRS,
  /* no permit */
  .pre_subparse    = parse_pre_subparse,
  .post_blockstart = parse_post_blockstart,
  .pre_blockend    = parse_pre_blockend,
  .post_newcv      = parse_post_newcv,
};

static int keyword_BUILD(pTHX_ OP **op_ptr)
{
  /* For now, `BUILD { ... }` just means the same as `method BUILD { ... }`
   */
  if(!have_compclassmeta)
    croak("Cannot 'BUILD' outside of 'class'");

  lex_read_space(0);

  return xs_parse_sublike(&parse_BUILD_hooks, (void *)PHASER_BUILD,
    op_ptr);
}

static int keyword_requires(pTHX_ OP **op_ptr)
{
  if(!have_compclassmeta)
    croak("Cannot 'requires' outside of 'role'");

  if(compclassmeta->type == METATYPE_CLASS)
    croak("A class may not declare required methods");

  lex_read_space(0);
  SV *mname = lex_scan_ident();
  if(!mname)
    croak("Expected a method name");

  if(lex_read_unichar(0) != ';') {
    croak("Expected end of statement");
  }

  av_push(compclassmeta->requiremethods, mname);

  *op_ptr = newOP(OP_NULL, 0);

  return KEYWORD_PLUGIN_STMT;
}

static int (*next_keyword_plugin)(pTHX_ char *, STRLEN, OP **);

static int my_keyword_plugin(pTHX_ char *kw, STRLEN kwlen, OP **op_ptr)
{
  HV *hints = GvHV(PL_hintgv);

  if((PL_parser && PL_parser->error_count) ||
     !hints)
    return (*next_keyword_plugin)(aTHX_ kw, kwlen, op_ptr);

  if(kwlen == 5 && strEQ(kw, "class") &&
      hv_fetchs(hints, "Object::Pad/class", 0))
    return keyword_classlike(aTHX_ METATYPE_CLASS, op_ptr);

  if(kwlen == 4 && strEQ(kw, "role") &&
      hv_fetchs(hints, "Object::Pad/role", 0))
    return keyword_classlike(aTHX_ METATYPE_ROLE, op_ptr);

  if(kwlen == 3 && strEQ(kw, "has") &&
      hv_fetchs(hints, "Object::Pad/has", 0))
    return keyword_has(aTHX_ op_ptr);

  if(kwlen == 5 && strEQ(kw, "BUILD") &&
      hv_fetchs(hints, "Object::Pad/method", 0))
    return keyword_BUILD(aTHX_ op_ptr);

  if(kwlen == 8 && strEQ(kw, "requires") &&
      hv_fetchs(hints, "Object::Pad/requires", 0))
    return keyword_requires(aTHX_ op_ptr);

  return (*next_keyword_plugin)(aTHX_ kw, kwlen, op_ptr);
}

#ifdef HAVE_DMD_HELPER
static int dump_slotmeta(pTHX_ const SV *sv, SlotMeta *slotmeta)
{
  int ret = 0;

  /* Some trickery to generate dynamic labels */
  const char *name = SvPVX(slotmeta->name);
  SV *label = newSV(0);

  sv_setpvf(label, "the Object::Pad slot %s name", name);
  ret += DMD_ANNOTATE_SV(sv, slotmeta->name, SvPVX(label));

  sv_setpvf(label, "the Object::Pad slot %s default value", name);
  ret += DMD_ANNOTATE_SV(sv, slotmeta->defaultsv, SvPVX(label));

  SvREFCNT_dec(label);

  return ret;
}

static int dumppackage_class(pTHX_ const SV *sv)
{
  int ret = 0;
  ClassMeta *meta = NUM2PTR(ClassMeta *, SvUV((SV *)sv));

  ret += DMD_ANNOTATE_SV(sv, meta->name, "the Object::Pad class name");
  ret += DMD_ANNOTATE_SV(sv, (SV *)meta->stash, "the Object::Pad stash");
  if(meta->pending_submeta)
    ret += DMD_ANNOTATE_SV(sv, (SV *)meta->pending_submeta, "the Object::Pad pending submeta AV");
  if(meta->roles)
    ret += DMD_ANNOTATE_SV(sv, (SV *)meta->roles, "the Object::Pad roles AV");

  I32 i;
  for(i = 0; i < av_count(meta->slots); i++)
    ret += dump_slotmeta(aTHX_ sv, (SlotMeta *)AvARRAY(meta->slots)[i]);

  if(meta->foreign_new)
    ret += DMD_ANNOTATE_SV(sv, (SV *)meta->foreign_new, "the Object::Pad foreign superclass constructor CV");

  ret += DMD_ANNOTATE_SV(sv, (SV *)meta->initslots, "the Object::Pad initslots CV");

  ret += DMD_ANNOTATE_SV(sv, (SV *)meta->buildblocks, "the Object::Pad BUILD blocks AV");

  ret += DMD_ANNOTATE_SV(sv, (SV *)meta->methodscope, "the Object::Pad temporary method scope");

  return ret;
}
#endif

MODULE = Object::Pad    PACKAGE = Object::Pad

SV *
_begin_class(name, superclassname)
    SV *name
    SV *superclassname
  CODE:
  {
    ClassMeta *meta = mop_create_class(METATYPE_CLASS, name, superclassname);

    compclassmeta_set(meta);

    RETVAL = newSV(0);
    sv_setref_uv(RETVAL, "Object::Pad::MOP::Class", PTR2UV(meta));

    CV *cv = newXS(NULL, &xsub_mop_class_seal, __FILE__);
    CvXSUBANY(cv).any_ptr = meta;

    if(!PL_unitcheckav)
      PL_unitcheckav = newAV();
    av_push(PL_unitcheckav, (SV *)cv);
  }
  OUTPUT:
    RETVAL

MODULE = Object::Pad    PACKAGE = Object::Pad::MOP::Class

SV *
new(class, name)
    SV *name
  CODE:
  {
    ClassMeta *meta = mop_create_class(METATYPE_CLASS, sv_mortalcopy(name), NULL);

    RETVAL = newSV(0);
    sv_setref_uv(RETVAL, "Object::Pad::MOP::Class", PTR2UV(meta));
  }
  OUTPUT:
    RETVAL

bool
is_class(self)
    SV *self
  ALIAS:
    is_class = METATYPE_CLASS
    is_role  = METATYPE_ROLE
  CODE:
  {
    ClassMeta *meta = NUM2PTR(ClassMeta *, SvUV(SvRV(self)));
    RETVAL = (meta->type == ix);
  }
  OUTPUT:
    RETVAL

SV *
name(self)
    SV *self
  CODE:
  {
    ClassMeta *meta = NUM2PTR(ClassMeta *, SvUV(SvRV(self)));
    RETVAL = SvREFCNT_inc(meta->name);
  }
  OUTPUT:
    RETVAL

void
superclasses(self)
    SV *self
  PPCODE:
  {
    ClassMeta *meta = NUM2PTR(ClassMeta *, SvUV(SvRV(self)));

    if(meta->supermeta) {
      PUSHs(sv_newmortal());
      sv_setref_uv(ST(0), "Object::Pad::MOP::Class", PTR2UV(meta->supermeta));
      XSRETURN(1);
    }

    XSRETURN(0);
  }

void
roles(self)
    SV *self
  PPCODE:
  {
    ClassMeta *meta = NUM2PTR(ClassMeta *, SvUV(SvRV(self)));
    U32 count = 0;

    /* TODO Consider recursion */
    U32 i;
    RoleEmbedding **arr = (RoleEmbedding **)AvARRAY(meta->roles);
    for(i = 0; i < av_count(meta->roles); i++) {
      SV *sv = sv_newmortal();
      sv_setref_uv(sv, "Object::Pad::MOP::Class", PTR2UV(arr[i]->rolemeta));
      XPUSHs(sv);
      count++;
    }

    XSRETURN(count);
  }

void
add_BUILD(self, code)
    SV *self
    CV *code
  CODE:
  {
    ClassMeta *meta = NUM2PTR(ClassMeta *, SvUV(SvRV(self)));

    mop_class_add_BUILD(meta, (CV *)SvREFCNT_inc((SV *)code));
  }

SV *
add_method(self, mname, code)
    SV *self
    SV *mname
    CV *code
  CODE:
  {
    ClassMeta *meta = NUM2PTR(ClassMeta *, SvUV(SvRV(self)));

    if(SvOK(mname) && SvPOK(mname) && strEQ(SvPVX(mname), "BUILD")) {
      warn("Adding a method called BUILD is not recommended; use ->add_BUILD directly");
      mop_class_add_BUILD(meta, (CV *)SvREFCNT_inc((SV *)code));
      XSRETURN(0);
    }

    MethodMeta *methodmeta = mop_class_add_method(meta, sv_mortalcopy(mname));

    I32 klen = SvCUR(mname);
    if(SvUTF8(mname))
      klen = -klen;

    GV **gvp = (GV **)hv_fetch(meta->stash, SvPVX(mname), klen, GV_ADD);

    gv_init_sv(*gvp, meta->stash, mname, 0);
    GvMULTI_on(*gvp);

    GvCV_set(*gvp, (CV *)SvREFCNT_inc(code));

    RETVAL = newSV(0);
    sv_setref_uv(RETVAL, "Object::Pad::MOP::Method", PTR2UV(methodmeta));
  }
  OUTPUT:
    RETVAL

void
get_own_method(self, methodname)
    SV *self
    SV *methodname
  PPCODE:
  {
    ClassMeta *meta = NUM2PTR(ClassMeta *, SvUV(SvRV(self)));

    AV *methods = meta->methods;
    U32 nmethods = av_count(methods);

    U32 i;
    for(i = 0; i < nmethods; i++) {
      MethodMeta *methodmeta = (MethodMeta *)AvARRAY(methods)[i];

      if(!sv_eq(methodmeta->name, methodname))
        continue;

      ST(0) = sv_newmortal();
      sv_setref_iv(ST(0), "Object::Pad::MOP::Method", PTR2UV(methodmeta));
      XSRETURN(1);
    }

    croak("Class %" SVf " does not have a method called '%" SVf "'",
      meta->name, methodname);
  }

SV *
add_slot(self, slotname)
    SV *self
    SV *slotname
  CODE:
  {
    ClassMeta *meta = NUM2PTR(ClassMeta *, SvUV(SvRV(self)));

    SlotMeta *slotmeta = mop_class_add_slot(meta, sv_mortalcopy(slotname));

    RETVAL = newSV(0);
    sv_setref_uv(RETVAL, "Object::Pad::MOP::Slot", PTR2UV(slotmeta));
  }
  OUTPUT:
    RETVAL

void
get_slot(self, slotname)
    SV *self
    SV *slotname
  PPCODE:
  {
    ClassMeta *meta = NUM2PTR(ClassMeta *, SvUV(SvRV(self)));

    AV *slots = meta->slots;
    U32 nslots = av_count(slots);

    SLOTOFFSET i;
    for(i = 0; i < nslots; i++) {
      SlotMeta *slotmeta = (SlotMeta *)AvARRAY(slots)[i];

      if(!sv_eq(slotmeta->name, slotname))
        continue;

      ST(0) = sv_newmortal();
      sv_setref_iv(ST(0), "Object::Pad::MOP::Slot", PTR2UV(slotmeta));
      XSRETURN(1);
    }

    croak("Class %" SVf " does not have a slot called '%" SVf "'",
      meta->name, slotname);
  }

MODULE = Object::Pad    PACKAGE = Object::Pad::MOP::Method

SV *
name(self)
    SV *self
  ALIAS:
    name  = 0
    class = 1
  CODE:
  {
    MethodMeta *meta = NUM2PTR(MethodMeta *, SvUV(SvRV(self)));
    switch(ix) {
      case 0: RETVAL = SvREFCNT_inc(meta->name); break;
      case 1:
        RETVAL = newSV(0);
        sv_setref_uv(RETVAL, "Object::Pad::MOP::Class", PTR2UV(meta->class));
        break;

      default: RETVAL = NULL;
    }
  }
  OUTPUT:
    RETVAL

MODULE = Object::Pad    PACKAGE = Object::Pad::MOP::Slot

SV *
name(self)
    SV *self
  ALIAS:
    name  = 0
    class = 1
  CODE:
  {
    SlotMeta *meta = NUM2PTR(SlotMeta *, SvUV(SvRV(self)));
    switch(ix) {
      case 0: RETVAL = SvREFCNT_inc(meta->name); break;
      case 1:
        RETVAL = newSV(0);
        sv_setref_uv(RETVAL, "Object::Pad::MOP::Class", PTR2UV(meta->class));
        break;

      default: RETVAL = NULL;
    }
  }
  OUTPUT:
    RETVAL

void
value(self, obj)
    SV *self
    SV *obj
  PPCODE:
  {
    SlotMeta *meta = NUM2PTR(SlotMeta *, SvUV(SvRV(self)));
    SV *objrv;

    if(!SvROK(obj) || !SvOBJECT(objrv = SvRV(obj)))
      croak("Cannot fetch slot value of a non-instance");

    const char *stashname = HvNAME(meta->class->stash);

    if(!stashname || !sv_derived_from(obj, stashname))
      croak("Cannot fetch slot value from a non-derived instance");

    AV *slotsav = (AV *)get_obj_slotsav(obj, meta->class->repr, true);

    if(meta->slotix > av_top_index(slotsav))
      croak("ARGH: instance does not have a slot at index %ld", (long int)meta->slotix);

    SV *value = AvARRAY(slotsav)[meta->slotix];

    /* We must prevent caller from assigning to non-scalar slots, in case
     * they break the SvTYPE of the value. We can't cancel the CvLVALUE but we
     * can yield a READONLY value in this case */
    if(SvPV_nolen(meta->name)[0] != '$') {
      value = sv_mortalcopy(value);
      SvREADONLY_on(value);
    }

    /* stack does not contribute SvREFCNT */
    ST(0) = value;
    XSRETURN(1);
  }

BOOT:
  XopENTRY_set(&xop_methstart, xop_name, "methstart");
  XopENTRY_set(&xop_methstart, xop_desc, "methstart()");
  XopENTRY_set(&xop_methstart, xop_class, OA_BASEOP);
  Perl_custom_op_register(aTHX_ &pp_methstart, &xop_methstart);

  XopENTRY_set(&xop_slotpad, xop_name, "slotpad");
  XopENTRY_set(&xop_slotpad, xop_desc, "slotpad()");
#ifdef HAVE_UNOP_AUX
  XopENTRY_set(&xop_slotpad, xop_class, OA_UNOP_AUX);
#else
  XopENTRY_set(&xop_slotpad, xop_class, OA_UNOP); /* technically a lie */
#endif
  Perl_custom_op_register(aTHX_ &pp_slotpad, &xop_slotpad);

  CvLVALUE_on(get_cv("Object::Pad::MOP::Slot::value", 0));

  wrap_keyword_plugin(&my_keyword_plugin, &next_keyword_plugin);
#ifdef HAVE_DMD_HELPER
  DMD_SET_PACKAGE_HELPER("Object::Pad::MOP::Class", &dumppackage_class);
#endif

  boot_xs_parse_sublike(0.10); /* hookdata */

  register_xs_parse_sublike("method", &parse_method_hooks, (void *)PHASER_NONE);
