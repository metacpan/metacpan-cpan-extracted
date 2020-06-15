/*  You may distribute under the terms of either the GNU General Public License
 *  or the Artistic License (the same terms as Perl itself)
 *
 *  (C) Paul Evans, 2019-2020 -- leonerd@leonerd.org.uk
 */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "XSParseSublike.h"

#ifndef wrap_keyword_plugin
#  include "wrap_keyword_plugin.c.inc"
#endif

#define HAVE_PERL_VERSION(R, V, S) \
    (PERL_REVISION > (R) || (PERL_REVISION == (R) && (PERL_VERSION > (V) || (PERL_VERSION == (V) && (PERL_SUBVERSION >= (S))))))

#if HAVE_PERL_VERSION(5, 26, 0)
#  define HAVE_PARSE_SUBSIGNATURE
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

/*********************************
 * Class and Slot Implementation *
 *********************************/

/* A SLOTOFFSET is an offset within the AV of an object instance */
typedef IV SLOTOFFSET;

typedef struct ClassMeta ClassMeta;

typedef struct {
  SV *name;
  ClassMeta *class;
  OP *defaultop;
  SLOTOFFSET slotix;
} SlotMeta;

/* Metadata about a class */
struct ClassMeta {
  SV *name;
  HV *stash;
  bool sealed;
  SLOTOFFSET offset;   /* first slot index of this partial within its instance */
  AV *slots;           /* each AV item is a raw pointer directly to a SlotMeta */
  enum {
    REPR_NATIVE,       /* instances are in native format - blessed AV as slots */
    REPR_HASH,         /* instances are blessed HASHes; our slots live in $self->{"Object::Pad/slots"} */
    REPR_MAGIC,        /* instances store slot AV via magic; superconstructor must be foreign */

    REPR_AUTOSELECT,   /* pick one of the above depending on foreign_new and SvTYPE()==SVt_PVHV */
  } repr;
  CV *foreign_new;     /* superclass is not Object::Pad, here is the constructor */

  COP *tmpcop;         /* a COP to use during generated constructor */
  CV *methodscope;     /* a temporary CV used just during compilation of a `method` */
};

/* Special pad indexes within `method` CVs */
enum {
  PADIX_SELF = 1,
  PADIX_SLOTS = 2,
};

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
       * invoke INITSLOTS now to create it.
       *   https://rt.cpan.org/Ticket/Display.html?id=132263
       */
      if(!slotssvp) {
        dSP;

        ENTER;
        EXTEND(SP, 1);
        PUSHMARK(SP);
        mPUSHs(newSVsv(self));
        PUTBACK;

        call_method("INITSLOTS", G_VOID);

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

static XOP xop_methstart;
static OP *pp_methstart(pTHX)
{
  SV *self = av_shift(GvAV(PL_defgv));
  HV *classstash = CvSTASH(find_runcv(0));
  bool create = PL_op->op_flags & OPf_MOD;

  if(!SvROK(self) || !SvOBJECT(SvRV(self)))
    croak("Cannot invoke method on a non-instance");

  if(!sv_derived_from(self, HvNAME(classstash)))
    croak("Cannot invoke foreign method on non-derived instance");

  save_clearsv(&PAD_SVl(PADIX_SELF));
  sv_setsv(PAD_SVl(PADIX_SELF), self);

  /* op_private contains the repr type so we can extract slots */
  SV *slotsav = get_obj_slotsav(self, PL_op->op_private, create);

  SAVESPTR(PAD_SVl(PADIX_SLOTS));
  PAD_SVl(PADIX_SLOTS) = SvREFCNT_inc(slotsav);
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

  PADOFFSET padix = pad_add_name_pvs("$self", 0, NULL, NULL);
  if(padix != PADIX_SELF)
    croak("ARGH: Expected that padix[$self] = 1");

  padix = pad_add_name_pvs("@(Object::Pad/slots)", 0, NULL, NULL);
  if(padix != PADIX_SLOTS)
    croak("ARGH: Expected that padix[@slots] = 2");

  U8 repr = meta->repr;
  if(repr == REPR_AUTOSELECT && !meta->foreign_new)
    repr = REPR_NATIVE;

  ops = op_append_list(OP_LINESEQ, ops,
    newMETHSTARTOP(OPf_MOD, repr)
  );

  intro_my();

  /* TODO: Icky horrible implementation; if our slotoffset > 0 then
   * we must be a subclass
   */
  if(meta->offset) {
    AV *isa = get_class_isa(meta->stash);
    SV *superclass = AvARRAY(isa)[0];

    CopLINE_set(PL_curcop, __LINE__);

    ops = op_append_list(OP_LINESEQ, ops,
      newSTATEOP(0, NULL, NULL));

    /* Build an OP_ENTERSUB for  $self->SUPER::INITSLOTS() */
    OP *op = NULL;
    op = op_append_list(OP_LIST, op,
      newPADxVOP(OP_PADSV, PADIX_SELF, 0, 0));
    op = op_append_list(OP_LIST, op,
      newMETHOD_REDIR_OP(superclass, newSVpvn_share("INITSLOTS", 9, 0), 0));

    ops = op_append_list(OP_LINESEQ, ops,
      op_convert_list(OP_ENTERSUB, OPf_WANT_VOID|OPf_STACKED, op));
  }

  /* TODO: If in some sort of debug mode: insert equivalent of
   *   if((av_count(self)) != offset)
   *     croak("ARGH: Expected self to have %d slots by now\n", offset);
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
          /* push ..., undef */
          if(slotmeta->defaultop)
            op = slotmeta->defaultop;
          else
            op = newOP(OP_UNDEF, 0);
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
  }

  SvREFCNT_inc(PL_compcv);
  ops = block_end(save_ix, ops);

  /* newATTRSUB will capture PL_curstash */
  SAVESPTR(PL_curstash);
  PL_curstash = meta->stash;

  newATTRSUB(floor_ix, newSVOP(OP_CONST, 0, newSVpvf("%" SVf "::INITSLOTS", meta->name)),
    NULL, NULL, ops);

  LEAVE;
}

#define mop_class_seal(meta)  S_mop_class_seal(aTHX_ meta)
static void S_mop_class_seal(pTHX_ ClassMeta *meta)
{
  S_generate_initslots_method(aTHX_ meta);

  meta->sealed = true;
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

static int on_free_compclassmeta(pTHX_ SV *sv, MAGIC *mg)
{
  ClassMeta *meta = (ClassMeta *)mg->mg_ptr;

  mop_class_seal(meta);
}

static MGVTBL vtbl_compclassmeta = {
  NULL, /* get */
  NULL, /* set */
  NULL, /* len */
  NULL, /* clear */
  on_free_compclassmeta,
};

#define COMPCLASSMETA_SEAL_ON_FREE (1<<0)
#define compclassmeta_set(meta, flags)  S_compclassmeta_set(aTHX_ meta, flags)
static void S_compclassmeta_set(pTHX_ ClassMeta *meta, U8 flags)
{
  SV *sv = *hv_fetchs(GvHV(PL_hintgv), "Object::Pad/compclassmeta", GV_ADD);
  sv_setiv(sv, (IV)meta);

  if(flags & COMPCLASSMETA_SEAL_ON_FREE)
    sv_magicext(sv, NULL, PERL_MAGIC_ext, &vtbl_compclassmeta, (char *)meta, 0);
}

static XS(injected_constructor);
static XS(injected_constructor)
{
  dXSARGS;
  const ClassMeta *meta = XSANY.any_ptr;
  SV *class = ST(0);
  SV *self;

  COP *prevcop = PL_curcop;
  PL_curcop = meta->tmpcop;
  CopLINE_set(PL_curcop, __LINE__);

  I32 nargs;
  {
    /* @args = $class->BUILDARGS(@_) */
    CopLINE_set(PL_curcop, __LINE__);

    ENTER;
    SAVETMPS;

    /* Splice in an extra copy of `class` so we get one there for the foreign
     * constructor */
    EXTEND(SP, 1);

    SV **args = SP - items + 2;
    PUSHMARK(args - 1);

    SV **svp;
    for(svp = SP; svp >= args; svp--)
      *(svp+1) = *svp;
    *args = class;
    SP++;
    PUTBACK;

    nargs = call_method("BUILDARGS", G_ARRAY);

    SPAGAIN;

    /* Save the returned values from destruction */
    for(svp = SP - nargs + 1; svp <= SP; svp++)
      SvREFCNT_inc(*svp);

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
      EXTEND(SP, nargs);

      SV **args = SP - nargs;
      SV **argtop = SP;
      SV **svp;

      mPUSHs(newSVsv(class));

      /* Push a copy of the args in case the (foreign) constructor mutates
       * them. We still need them for BUILDALL */
      for(svp = args + 1; svp <= argtop; svp++)
        PUSHs(*svp);
      PUTBACK;

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
     * thus INITSLOTS has already been called. Check here and set
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
    /* $self->INITSLOTS */
    CopLINE_set(PL_curcop, __LINE__);

    ENTER;
    EXTEND(SP, 1);
    PUSHMARK(SP);
    PUSHs(self);
    PUTBACK;

    call_method("INITSLOTS", G_VOID);

    LEAVE;
  }

  {
    /* $self->BUILDALL(@args) */
    CopLINE_set(PL_curcop, __LINE__);

    ENTER;
    SAVETMPS;
    SPAGAIN;

    EXTEND(SP, 1);

    SV **args = SP - nargs + 1;
    PUSHMARK(args - 1);

    /* Nudge the args up one and splice `self` in the bottom */

    SV **svp;
    for(svp = SP; svp >= args; svp--)
      sv_2mortal(*(svp+1) = *svp);
    *args = self;
    SP++;
    PUTBACK;

    call_method("BUILDALL", G_VOID);

    FREETMPS;
    LEAVE;
  }

  PL_curcop = prevcop;
  ST(0) = self;
  XSRETURN(1);
}

#define mop_create_class(name, super)  S_mop_create_class(aTHX_ name, super)
static ClassMeta *S_mop_create_class(pTHX_ SV *name, SV *superclassname)
{
  ClassMeta *meta;
  Newx(meta, 1, ClassMeta);

  meta->name = SvREFCNT_inc(name);

  meta->sealed = false;
  meta->offset = 0;
  meta->slots  = newAV();
  meta->repr   = REPR_AUTOSELECT;
  meta->foreign_new = NULL;

  meta->tmpcop = (COP *)newSTATEOP(0, NULL, NULL);
  CopFILE_set(meta->tmpcop, __FILE__);

  meta->methodscope = NULL;

  HV *stash = meta->stash = gv_stashsv(name, GV_ADD);

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
      meta->offset = supermeta->offset + av_count(supermeta->slots);
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
  }
  else {
    /* A base class */
    av_push(isa, newSVpvs("Object::Pad::UNIVERSAL"));
  }

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

#define apply_class_attribute(meta, attr)  S_apply_class_attribute(aTHX_ meta, attr)
static void S_apply_class_attribute(pTHX_ ClassMeta *meta, SV *attr)
{
  char *name = SvPV_nolen(attr);
  char *val = strchr(name, '(');

  if(val) {
    name = save_strndup(name, val - name);
    val  = save_strndup(val + 1, strlen(val) - 2);
  }

  /* TODO: Think about how to make this more easily extensible */
  if(strEQ(name, "repr")) {
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
  else
    croak("Unrecognised class attribute %" SVf, name);
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
  slotmeta->slotix = meta->offset + av_count(slots);
  slotmeta->defaultop = NULL;

  av_push(slots, (SV *)slotmeta);

  return slotmeta;
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

  U8 repr = classmeta->repr;
  if(repr == REPR_AUTOSELECT && !classmeta->foreign_new)
    repr = REPR_NATIVE;

  I32 floor_ix = start_subparse(FALSE, 0);
  SAVEFREESV(PL_compcv);

  I32 save_ix = block_start(TRUE);

  /* TODO: On perl versions 5.26+ we should generate the signature checking
   * op as well so as to check the size of @_ on invocation
   */

  OP *ops = op_append_list(OP_LINESEQ, NULL,
    newSTATEOP(0, NULL, NULL));
  ops = op_append_list(OP_LINESEQ, ops,
    newMETHSTARTOP(0, repr));

  PADOFFSET padix = pad_add_name_sv(slotmeta->name, 0, NULL, NULL);
  intro_my();

  ops = op_append_list(OP_LINESEQ, ops,
    newSLOTPADOP(0, OPpSLOTPAD_SV, padix, slotmeta->slotix));

  switch(type) {
    case ACCESSOR_LVALUE_MUTATOR:
      CvLVALUE_on(PL_compcv);
      /* fallthrough */
    case ACCESSOR_READER:
      ops = op_append_list(OP_LINESEQ, ops,
        newPADxVOP(OP_PADSV, padix, 0, 0));
      break;

    case ACCESSOR_WRITER:
      ops = op_append_list(OP_LINESEQ, ops,
        newBINOP(OP_SASSIGN, 0,
          newOP(OP_SHIFT, 0),
          newPADxVOP(OP_PADSV, padix, 0, 0)));
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

struct SlotAttribute {
  char *attrname;
  /* TODO: int flags */
  void (*apply)(pTHX_ SlotMeta *slotmeta, const char *value, void *data);
  void *applydata;
};
static struct SlotAttribute slot_attributes[] = {
  "reader",  &S_generate_slot_accessor, (void *)ACCESSOR_READER,
  "writer",  &S_generate_slot_accessor, (void *)ACCESSOR_WRITER,
  "mutator", &S_generate_slot_accessor, (void *)ACCESSOR_LVALUE_MUTATOR,
  { 0 }
};

/*******************
 * Custom Keywords *
 *******************/

static int keyword_class(pTHX_ OP **op_ptr)
{
  lex_read_space(0);

  SV *packagename = lex_scan_packagename();
  if(!packagename)
    croak("Expected 'class' to be followed by package name");

  lex_read_space(0);
  SV *packagever = lex_scan_version(PARSE_OPTIONAL);

  SV *superclassname = NULL;

  /* TODO: This grammar is quite flexible; maybe too much? */
  while(1) {
    lex_read_space(0);

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
    else
      break;
  }

  OP *attrs = NULL;
  if(lex_consume(":")) {
    attrs = lex_scan_attrs(NULL);
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

  ClassMeta *meta = mop_create_class(packagename, superclassname);

  if(superclassname)
    SvREFCNT_dec(superclassname);

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

  if(attrs) {
    /* attrs should be a list of OP_CONST ops whose first child is the
     *   pushmark, which we skip */
    OP *op;
    for(op = OpSIBLING(cLISTOPx(attrs)->op_first); op; op = OpSIBLING(op)) {
      assert(op->op_type == OP_CONST);
      SV *attr = cSVOPx(op)->op_sv;

      apply_class_attribute(meta, attr);
    }
  }

  if(is_block) {
    I32 save_ix = block_start(TRUE);
    compclassmeta_set(meta, COMPCLASSMETA_SEAL_ON_FREE);

    OP *body = parse_stmtseq(0);
    body = block_end(save_ix, body);

    if(!lex_consume("}"))
      croak("Expected }");

    LEAVE;

    /* CARGOCULT from perl/perly.y:PACKAGE BAREWORD BAREWORD '{' */
    /* a block is a loop that happens once */
    *op_ptr = newWHILEOP(0, 1, NULL, NULL, body, NULL, 0);
    return KEYWORD_PLUGIN_STMT;
  }
  else {
    SAVEHINTS();
    compclassmeta_set(meta, COMPCLASSMETA_SEAL_ON_FREE);

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

    SV *attr;
    while(attr = lex_scan_attr()) {
      lex_read_space(0);

      char *attrname = SvPV_nolen(attr);
      char *val = strchr(attrname, '(');

      if(val) {
        attrname = save_strndup(attrname, val - attrname);
        val  = save_strndup(val + 1, strlen(val) - 2);
      }

      ENTER;
      SAVETMPS;

      SAVEFREESV(attr);

      for(struct SlotAttribute *def = slot_attributes; def->attrname; def++) {
        if(!strEQ(attrname, def->attrname))
          continue;

        (*def->apply)(aTHX_ slotmeta, val, def->applydata);

        goto done;
      }

      croak("Unrecognised slot attribute :%s", attrname);

done:
      FREETMPS;
      LEAVE;

      /* Accept additional colons to prefix additional attrs */
      if(lex_peek_unichar(0) == ':') {
        lex_read_unichar(0);
        lex_read_space(0);
      }
    }
  }

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

    /* TODO: This is currently very restrictive. However, if we allow any
     * expression then the pad indexes within it will be all wrong. We'll have
     * to tread carefully.
     * It should be possible to allow somewhat more in future but for now this
     * is at least safe
     */
    if(op->op_type != OP_CONST || op->op_flags & OPf_KIDS)
      croak("Default expression for 'has %" SVf "' must be compiletime constant",
        SVfARG(name));

    slotmeta->defaultop = op;
  }

  if(lex_read_unichar(0) != ';') {
    croak("Expected default expression or end of statement");
  }

  *op_ptr = newOP(OP_NULL, 0);

  LEAVE;

  return KEYWORD_PLUGIN_STMT;
}

static bool parse_permit(pTHX)
{
  HV *hints = GvHV(PL_hintgv);

  if(!hv_fetchs(hints, "Object::Pad/method", 0))
    return false;

  if(!have_compclassmeta)
    croak("Cannot 'method' outside of 'class'");

  return true;
}

static void parse_pre_subparse(pTHX_ struct XSParseSublikeContext *ctx)
{
  U32 i;
  AV *slots = compclassmeta->slots;
  U32 nslots = av_count(slots);

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

static void parse_post_blockstart(pTHX_ struct XSParseSublikeContext *ctx)
{
  /* Splice in the slot scope CV in */
  CV *methodscope = compclassmeta->methodscope;

  if(CvANON(PL_compcv))
    CvANON_on(methodscope);

  CvOUTSIDE    (methodscope) = CvOUTSIDE    (PL_compcv);
  CvOUTSIDE_SEQ(methodscope) = CvOUTSIDE_SEQ(PL_compcv);

  CvOUTSIDE(PL_compcv) = methodscope;

  {
    PADOFFSET padix;

    padix = pad_add_name_pvs("$self", 0, NULL, NULL);
    if(padix != PADIX_SELF)
      croak("ARGH: Expected that padix[$self] = 1");

    /* Give it a name that isn't valid as a Perl variable so it can't collide */
    padix = pad_add_name_pvs("@(Object::Pad/slots)", 0, NULL, NULL);
    if(padix != PADIX_SLOTS)
      croak("ARGH: Expected that padix[@slots] = 2");

    intro_my();
  }
}

static void parse_pre_blockend(pTHX_ struct XSParseSublikeContext *ctx)
{
  SLOTOFFSET offset = compclassmeta->offset;
  PADNAMELIST *slotnames = PadlistNAMES(CvPADLIST(compclassmeta->methodscope));
  I32 nslots = av_count(compclassmeta->slots);
  PADNAME **snames = PadnamelistARRAY(slotnames);
  PADNAME **padnames = PadnamelistARRAY(PadlistNAMES(CvPADLIST(PL_compcv)));
  OP *slotops = NULL;

  U8 repr = compclassmeta->repr;
  if(repr == REPR_AUTOSELECT && !compclassmeta->foreign_new)
    repr = REPR_NATIVE;

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
      if(!strEQ(PadnamePV(pn), "$self"))
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
    newMETHSTARTOP(0, repr));

  int i;
  for(i = 0; i < nslots; i++) {
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

    SLOTOFFSET slotix = offset + i;
    PADOFFSET padix = pad_findmy_pv(PadnamePV(slotname), 0);

    U8 private;
    switch(PadnamePV(slotname)[0]) {
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
}

static void parse_post_newcv(pTHX_ struct XSParseSublikeContext *ctx)
{
  if(ctx->cv)
    CvMETHOD_on(ctx->cv);
}

static struct XSParseSublikeHooks parse_method_hooks = {
  .permit          = parse_permit,
  .pre_subparse    = parse_pre_subparse,
  .post_blockstart = parse_post_blockstart,
  .pre_blockend    = parse_pre_blockend,
  .post_newcv      = parse_post_newcv,
};

static void parse_BUILD_pre_subparse(pTHX_ struct XSParseSublikeContext *ctx)
{
  ctx->name = newSVpvs("BUILD");

  return parse_pre_subparse(aTHX_ ctx);
}

static struct XSParseSublikeHooks parse_BUILD_hooks = {
  .skip_parts = XS_PARSE_SUBLIKE_PART_NAME|XS_PARSE_SUBLIKE_PART_ATTRS,
  /* no permit */
  .pre_subparse    = parse_BUILD_pre_subparse,
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

  return xs_parse_sublike(&parse_BUILD_hooks, op_ptr);
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
    return keyword_class(aTHX_ op_ptr);

  if(kwlen == 3 && strEQ(kw, "has") &&
      hv_fetchs(hints, "Object::Pad/has", 0))
    return keyword_has(aTHX_ op_ptr);

  if(kwlen == 5 && strEQ(kw, "BUILD") &&
      hv_fetchs(hints, "Object::Pad/method", 0))
    return keyword_BUILD(aTHX_ op_ptr);

  return (*next_keyword_plugin)(aTHX_ kw, kwlen, op_ptr);
}

MODULE = Object::Pad    PACKAGE = Object::Pad

SV *
_begin_class(name, superclassname)
    SV *name
    SV *superclassname
  CODE:
  {
    ClassMeta *meta = mop_create_class(name, superclassname);

    compclassmeta_set(meta, COMPCLASSMETA_SEAL_ON_FREE);

    RETVAL = newSV(0);
    sv_setref_uv(RETVAL, "Object::Pad::MOP::Class", PTR2UV(meta));
  }
  OUTPUT:
    RETVAL

MODULE = Object::Pad    PACKAGE = Object::Pad::MOP::Class

SV *
new(class, name)
    SV *class
    SV *name
  CODE:
  {
    ClassMeta *meta = mop_create_class(sv_mortalcopy(name), NULL);

    RETVAL = newSV(0);
    sv_setref_uv(RETVAL, "Object::Pad::MOP::Class", PTR2UV(meta));
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

    if(!sv_derived_from(obj, HvNAME(meta->class->stash)))
      croak("Cannot fetch slot value from a non-derived instance");

    U8 repr = meta->class->repr;
    if(repr == REPR_AUTOSELECT && !meta->class->foreign_new)
      repr = REPR_NATIVE;
    AV *slotsav = (AV *)get_obj_slotsav(obj, repr, true);

    if(meta->slotix > av_top_index(slotsav))
      croak("ARGH: instance does not have a slot at index %d", meta->slotix);

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

  boot_xs_parse_sublike(0.08); /* hooks.omit_parts */

  register_xs_parse_sublike("method", &parse_method_hooks);
