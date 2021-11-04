/*  You may distribute under the terms of either the GNU General Public License
 *  or the Artistic License (the same terms as Perl itself)
 *
 *  (C) Paul Evans, 2019-2021 -- leonerd@leonerd.org.uk
 */
#define PERL_NO_GET_CONTEXT

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "XSParseKeyword.h"

#include "XSParseSublike.h"

#include "perl-backcompat.c.inc"
#include "sv_setrv.c.inc"

#ifdef HAVE_DMD_HELPER
#  include "DMD_helper.h"
#endif

#include "perl-additions.c.inc"
#include "forbid_outofblock_ops.c.inc"
#include "force_list_keeping_pushmark.c.inc"
#include "optree-additions.c.inc"
#include "newOP_CUSTOM.c.inc"

#if HAVE_PERL_VERSION(5, 26, 0)
#  define HAVE_PARSE_SUBSIGNATURE
#endif

#if HAVE_PERL_VERSION(5, 28, 0)
#  define HAVE_UNOP_AUX_PV
#endif

#include "object_pad.h"
#include "class.h"
#include "slot.h"

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

/* Empty role embedding that is applied to all invokable role methods */
static RoleEmbedding embedding_standalone = {};

void ObjectPad_extend_pad_vars(pTHX_ const ClassMeta *meta)
{
  PADOFFSET padix;

  padix = pad_add_name_pvs("$self", 0, NULL, NULL);
  if(padix != PADIX_SELF)
    croak("ARGH: Expected that padix[$self] = 1");

  /* Give it a name that isn't valid as a Perl variable so it can't collide */
  padix = pad_add_name_pvs("@(Object::Pad/slots)", 0, NULL, NULL);
  if(padix != PADIX_SLOTS)
    croak("ARGH: Expected that padix[@slots] = 2");

  if(meta->type == METATYPE_ROLE) {
    /* Don't give this a padname or Future::AsyncAwait will break it (RT137649) */
    padix = pad_add_name_pvs("", 0, NULL, NULL);
    if(padix != PADIX_EMBEDDING)
      croak("ARGH: Expected that padix[(embedding)] = 3");
  }
}

#define find_padix_for_slot(slotmeta)  S_find_padix_for_slot(aTHX_ slotmeta)
static PADOFFSET S_find_padix_for_slot(pTHX_ SlotMeta *slotmeta)
{
  const char *slotname = SvPVX(slotmeta->name);
#if HAVE_PERL_VERSION(5, 20, 0)
  const PADNAMELIST *nl = PadlistNAMES(CvPADLIST(PL_compcv));
  PADNAME **names = PadnamelistARRAY(nl);
  PADOFFSET padix;

  for(padix = 1; padix <= PadnamelistMAXNAMED(nl); padix++) {
    PADNAME *name = names[padix];

    if(!name || !PadnameLEN(name))
      continue;

    const char *pv = PadnamePV(name);
    if(!pv)
      continue;

    /* slot names are all OUTER vars. This is necessary so we don't get
     * confused by signatures params of the same name
     *   https://rt.cpan.org/Ticket/Display.html?id=134456
     */
    if(!PadnameOUTER(name))
      continue;
    if(!strEQ(pv, slotname))
      continue;

    /* TODO: for extra robustness we could compare the SV * in the pad itself */

    return padix;
  }

  return NOT_IN_PAD;
#else
  /* Before the new pad API, the best we can do is call pad_findmy_pv()
   * It won't get confused about signatures params because these perls are too
   * old for signatures anyway
   */
  return pad_findmy_pv(slotname, 0);
#endif
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
    SV *embeddingsv = PadARRAY(pad1)[PADIX_EMBEDDING];

    if(embeddingsv && embeddingsv != &PL_sv_undef &&
       (embedding = (RoleEmbedding *)SvPVX(embeddingsv))) {
      if(embedding == &embedding_standalone) {
        classstash = NULL;
        offset     = 0;
      }
      else {
        classstash = embedding->classmeta->stash;
        offset     = embedding->offset;
      }
    }
    else {
      croak("Cannot invoke a role method directly");
    }
  }
  else {
    classstash = CvSTASH(find_runcv(0));
    offset     = 0;
  }

  if(classstash) {
    if(!HvNAME(classstash) || !sv_derived_from_hv(self, classstash))
      croak("Cannot invoke foreign method on non-derived instance");
  }

  save_clearsv(&PAD_SVl(PADIX_SELF));
  sv_setsv(PAD_SVl(PADIX_SELF), self);

  SV *slotsav;

  if(is_role) {
    if(embedding == &embedding_standalone) {
      slotsav = NULL;
    }
    else {
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
  }
  else {
    /* op_private contains the repr type so we can extract slots */
    slotsav = get_obj_slotsav(self, PL_op->op_private, create);
    SvREFCNT_inc(slotsav);
  }

  if(slotsav) {
    SAVESPTR(PAD_SVl(PADIX_SLOTS));
    PAD_SVl(PADIX_SLOTS) = slotsav;
    save_freesv(slotsav);
  }

  return PL_op->op_next;
}

OP *ObjectPad_newMETHSTARTOP(pTHX_ U32 flags)
{
  OP *op = newOP_CUSTOM(&pp_methstart, flags);
  op->op_private = (U8)(flags >> 8);
  return op;
}

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

OP *ObjectPad_newSLOTPADOP(pTHX_ U32 flags, PADOFFSET padix, SLOTOFFSET slotix)
{
#ifdef HAVE_UNOP_AUX
  OP *op = newUNOP_AUX(OP_CUSTOM, flags, NULL, NUM2PTR(UNOP_AUX_item *, slotix));
#else
  OP *op = newUNOP_with_IV(OP_CUSTOM, flags, NULL, slotix);
#endif
  op->op_targ = padix;
  op->op_private = (U8)(flags >> 8);
  op->op_ppaddr = &pp_slotpad;

  return op;
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

XS_INTERNAL(xsub_mop_class_seal)
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

#define is_valid_ident_utf8(s)  S_is_valid_ident_utf8(aTHX_ s)
static bool S_is_valid_ident_utf8(pTHX_ const U8 *s)
{
  const U8 *e = s + strlen((char *)s);

  if(!isIDFIRST_utf8_safe(s, e))
    return false;

  s += UTF8SKIP(s);
  while(*s) {
    if(!isIDCONT_utf8_safe(s, e))
      return false;
    s += UTF8SKIP(s);
  }

  return true;
}

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

static int build_classlike(pTHX_ OP **out, XSParseKeywordPiece *args[], size_t nargs, void *hookdata)
{
  int argi = 0;

  SV *packagename = args[argi++]->sv;
  /* Grrr; XPK bug */
  if(!packagename)
    croak("Expected a class name after 'class'");

  enum MetaType type = (enum MetaType)hookdata;

  SV *packagever = args[argi++]->sv;

  SV *superclassname = NULL;

  if(args[argi++]->i) {
    /* extends */
    argi++; /* ignore the XPK_CHOICE() integer; `extends` and `isa` are synonyms */
    if(type != METATYPE_CLASS)
      croak("Only a class may extend another");

    if(superclassname)
      croak("Multiple superclasses are not currently supported");

    superclassname = args[argi++]->sv;
    if(!superclassname)
      croak("Expected a superclass name after 'isa'");

    SV *superclassver = args[argi++]->sv;

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

  int nimplements = args[argi++]->i;
  if(nimplements) {
    int i;
    for(i = 0; i < nimplements; i++) {
      argi++; /* ignore the XPK_CHOICE() integer; `implements` and `does` are synonyms */
      int nroles = args[argi++]->i;
      while(nroles--) {
        SV *rolename = args[argi++]->sv;
        if(!rolename)
          croak("Expected a role name after 'does'");

        SV *rolever = args[argi++]->sv;

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

        mop_class_add_role(meta, rolemeta);
      }
    }
  }

  if(superclassname)
    SvREFCNT_dec(superclassname);

  int nattrs = args[argi++]->i;
  if(nattrs) {
    int i;
    for(i = 0; i < nattrs; i++) {
      SV *attrname = args[argi]->attr.name;
      SV *attrval  = args[argi]->attr.value;

      mop_class_apply_attribute(meta, SvPVX(attrname), attrval);

      argi++;
    }
  }

  /* At this point XS::Parse::Keyword has parsed all it can. From here we will
   * take over to perform the odd "block or statement" behaviour of `class`
   * keywords
   */

  bool is_block;

  if(lex_consume_unichar('{')) {
    is_block = true;
    ENTER;
  }
  else if(lex_consume_unichar(';')) {
    is_block = false;
  }
  else
    croak("Expected a block or ';'");

  import_pragma("strict", NULL);
  import_pragma("warnings", NULL);
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

    if(!lex_consume_unichar('}'))
      croak("Expected }");

    mop_class_seal(meta);

    LEAVE;

    /* CARGOCULT from perl/perly.y:PACKAGE BAREWORD BAREWORD '{' */
    /* a block is a loop that happens once */
    *out = op_append_elem(OP_LINESEQ,
      newWHILEOP(0, 1, NULL, NULL, body, NULL, 0),
      newSVOP(OP_CONST, 0, &PL_sv_yes));
    return KEYWORD_PLUGIN_STMT;
  }
  else {
    SAVEDESTRUCTOR_X(&ObjectPad_mop_class_seal, meta);

    SAVEHINTS();
    compclassmeta_set(meta);

    *out = newSVOP(OP_CONST, 0, &PL_sv_yes);
    return KEYWORD_PLUGIN_STMT;
  }
}

static const struct XSParseKeywordPieceType pieces_classlike[] = {
  XPK_PACKAGENAME,
  XPK_VSTRING_OPT,
  XPK_OPTIONAL(
    XPK_CHOICE( XPK_LITERAL("extends"), XPK_LITERAL("isa") ), XPK_PACKAGENAME, XPK_VSTRING_OPT
  ),
  /* This should really a repeated (tagged?) choice of a number of things, but
   * right now there's only one thing permitted here anyway
   */
  XPK_REPEATED(
    XPK_CHOICE( XPK_LITERAL("implements"), XPK_LITERAL("does") ), XPK_COMMALIST( XPK_PACKAGENAME, XPK_VSTRING_OPT )
  ),
  XPK_ATTRIBUTES,
  {0}
};

static const struct XSParseKeywordHooks kwhooks_class = {
  .permit_hintkey = "Object::Pad/class",
  .pieces = pieces_classlike,
  .build = &build_classlike,
};
static const struct XSParseKeywordHooks kwhooks_role = {
  .permit_hintkey = "Object::Pad/role",
  .pieces = pieces_classlike,
  .build = &build_classlike,
};

static void check_has(pTHX_ void *hookdata)
{
  if(!have_compclassmeta)
    croak("Cannot 'has' outside of 'class'");

  if(compclassmeta->role_is_invokable)
    croak("Cannot add slot data to an invokable role");
}

static int build_has(pTHX_ OP **out, XSParseKeywordPiece *args[], size_t nargs, void *hookdata)
{
  int argi = 0;

  SV *name = args[argi++]->sv;
  char sigil = SvPV_nolen(name)[0];

  SlotMeta *slotmeta = mop_class_add_slot(compclassmeta, name);
  SvREFCNT_dec(name);

  int nattrs = args[argi++]->i;
  if(nattrs) {
    SV *slotmetasv = newSV(0);
    sv_setref_uv(slotmetasv, "Object::Pad::MOP::Slot", PTR2UV(slotmeta));
    SAVEFREESV(slotmetasv);

    while(argi < (nattrs+2)) {
      SV *attrname = args[argi]->attr.name;
      SV *attrval  = args[argi]->attr.value;

      mop_slot_apply_attribute(slotmeta, SvPVX(attrname), attrval);

      argi++;
    }
  }

  /* It would be nice to just yield some OP to represent the has slot here
   * and let normal parsing of normal scalar assignment accept it. But we can't
   * because scalar assignment tries to peephole far too deply into us and
   * everything breaks... :/
   */
  switch(args[argi++]->i) {
    case -1:
      /* no expr */
      break;

    case 0:
    {
      OP *op = args[argi++]->op;

      slotmeta->defaultsv = newSV(0);

      /* An OP_CONST whose op_type is OP_CUSTOM.
       * This way we avoid the opchecker and finalizer doing bad things to our
       * defaultsv SV by setting it SvREADONLY_on().
       */
      OP *slotop = newSVOP_CUSTOM(PL_ppaddr[OP_CONST], 0, SvREFCNT_inc(slotmeta->defaultsv));

      OP *lhs, *rhs;

      switch(sigil) {
        case '$':
          *out = newBINOP(OP_SASSIGN, 0, op_contextualize(op, G_SCALAR), slotop);
          break;

        case '@':
          sv_setrv_noinc(slotmeta->defaultsv, (SV *)newAV());
          lhs = newUNOP(OP_RV2AV, OPf_MOD|OPf_REF, slotop);
          goto slot_array_hash_common;

        case '%':
          sv_setrv_noinc(slotmeta->defaultsv, (SV *)newHV());
          lhs = newUNOP(OP_RV2HV, OPf_MOD|OPf_REF, slotop);
          goto slot_array_hash_common;

slot_array_hash_common:
          rhs = op_contextualize(op, G_LIST);
          *out = newBINOP(OP_AASSIGN, 0,
            force_list_keeping_pushmark(rhs),
            force_list_keeping_pushmark(lhs));
          break;
      }
    }
    break;

    case 1:
    {
      OP *op = args[argi++]->op;
      U8 want = 0;

      forbid_outofblock_ops(op, "a slot initialiser block");

      switch(sigil) {
        case '$':
          want = G_SCALAR;
          break;
        case '@':
        case '%':
          want = G_LIST;
          break;
      }

      slotmeta->defaultexpr = op_contextualize(op_scope(op), want);
    }
    break;
  }

  mop_slot_seal(slotmeta);

  return KEYWORD_PLUGIN_STMT;
}

static void setup_parse_has_initexpr(pTHX_ void *hookdata)
{
  CV *was_compcv = PL_compcv;

  resume_compcv_and_save(&compclassmeta->initslots_compcv);

  /* Set up this new block as if the current compiler context were its scope */

  if(CvOUTSIDE(PL_compcv))
    SvREFCNT_dec(CvOUTSIDE(PL_compcv));

  CvOUTSIDE(PL_compcv)     = (CV *)SvREFCNT_inc(was_compcv);
  CvOUTSIDE_SEQ(PL_compcv) = PL_cop_seqmax;
}

static const struct XSParseKeywordHooks kwhooks_has = {
  .flags = XPK_FLAG_STMT|XPK_FLAG_AUTOSEMI,
  .permit_hintkey = "Object::Pad/has",

  .check = &check_has,

  .pieces = (const struct XSParseKeywordPieceType []){
    XPK_LEXVARNAME(XPK_LEXVAR_ANY),
    XPK_ATTRIBUTES,
    XPK_CHOICE(
      XPK_SEQUENCE(XPK_EQUALS, XPK_TERMEXPR),
      XPK_PREFIXED_BLOCK_ENTERLEAVE(XPK_SETUP(&setup_parse_has_initexpr)),
      {0}
    ),
    {0}
  },
  .build = &build_has,
};

/* We use the method-like keyword parser to parse phaser blocks as well as
 * methods. In order to tell what is going on, hookdata will be an integer
 * set to one of the following
 */

enum PhaserType {
  PHASER_NONE, /* A normal `method`; i.e. not a phaser */
  PHASER_BUILD,
  PHASER_ADJUST,
  PHASER_ADJUSTPARAMS,
};

static const char *phasertypename[] = {
  [PHASER_BUILD]        = "BUILD",
  [PHASER_ADJUST]       = "ADJUST",
  [PHASER_ADJUSTPARAMS] = "ADJUSTPARAMS",
};

static bool parse_permit(pTHX_ void *hookdata)
{
  if(!have_compclassmeta)
    croak("Cannot 'method' outside of 'class'");

  return true;
}

static void parse_pre_subparse(pTHX_ struct XSParseSublikeContext *ctx, void *hookdata)
{
  enum PhaserType type = PTR2UV(hookdata);
  U32 i;
  AV *slots = compclassmeta->direct_slots;
  U32 nslots = av_count(slots);

  switch(type) {
    case PHASER_NONE:
      if(ctx->name && strEQ(SvPVX(ctx->name), "BUILD"))
        croak("method BUILD is no longer supported; use a BUILD block instead");
      break;

    case PHASER_BUILD:
    case PHASER_ADJUST:
    case PHASER_ADJUSTPARAMS:
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

  extend_pad_vars(compclassmeta);

  if(compclassmeta->type == METATYPE_ROLE) {
    PAD *pad1 = PadlistARRAY(CvPADLIST(PL_compcv))[1];

    if(compclassmeta->role_is_invokable) {
      SV *sv = PadARRAY(pad1)[PADIX_EMBEDDING];
      sv_setpvn(sv, "", 0);
      SvPVX(sv) = (void *)&embedding_standalone;
    }
    else {
      SvREFCNT_dec(PadARRAY(pad1)[PADIX_EMBEDDING]);
      PadARRAY(pad1)[PADIX_EMBEDDING] = &PL_sv_undef;
    }
  }

  intro_my();
}

static void parse_pre_blockend(pTHX_ struct XSParseSublikeContext *ctx, void *hookdata)
{
  enum PhaserType type = PTR2UV(hookdata);
  PADNAMELIST *slotnames = PadlistNAMES(CvPADLIST(compclassmeta->methodscope));
  I32 nslots = av_count(compclassmeta->direct_slots);
  PADNAME **snames = PadnamelistARRAY(slotnames);
  PADNAME **padnames = PadnamelistARRAY(PadlistNAMES(CvPADLIST(PL_compcv)));
  OP *slotops = NULL;

#if HAVE_PERL_VERSION(5, 22, 0)
  U32 cop_seq_low = COP_SEQ_RANGE_LOW(padnames[PADIX_SELF]);
#endif

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
      (compclassmeta->type == METATYPE_ROLE ? OPf_SPECIAL : 0) |
      (compclassmeta->repr << 8)));

  int i;
  for(i = 0; i < nslots; i++) {
    SlotMeta *slotmeta = (SlotMeta *)AvARRAY(compclassmeta->direct_slots)[i];
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

    SLOTOFFSET slotix = slotmeta->slotix;
    PADOFFSET padix = find_padix_for_slot(slotmeta);

    if(padix == NOT_IN_PAD)
      continue;

    U8 private = 0;
    switch(SvPV_nolen(slotmeta->name)[0]) {
      case '$': private = OPpSLOTPAD_SV; break;
      case '@': private = OPpSLOTPAD_AV; break;
      case '%': private = OPpSLOTPAD_HV; break;
    }

    slotops = op_append_list(OP_LINESEQ, slotops,
      /* alias the padix from the slot */
      newSLOTPADOP(private << 8, padix, slotix));

#if HAVE_PERL_VERSION(5, 22, 0)
    /* Unshare the padname so the one in the scopeslot returns to refcount 1 */
    PADNAME *newpadname = newPADNAMEpvn(PadnamePV(slotname), PadnameLEN(slotname));
    PadnameREFCNT_dec(padnames[padix]);
    padnames[padix] = newpadname;

    /* Turn off OUTER and set a valid COP sequence range, so the lexical is
     * visible to eval(), PadWalker, perldb, etc.. */
    PadnameOUTER_off(newpadname);
    COP_SEQ_RANGE_LOW(newpadname) = cop_seq_low;
    COP_SEQ_RANGE_HIGH(newpadname) = PL_cop_seqmax;
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
      if(!PadnameOUTER(outside_pn))
        PadnameOUTER_off(pn);
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
      if(ctx->cv && ctx->name)
        mop_class_add_method(compclassmeta, ctx->name);
      break;

    case PHASER_BUILD:
      mop_class_add_BUILD(compclassmeta, ctx->cv); /* steal CV */
      break;

    case PHASER_ADJUST:
      mop_class_add_ADJUST(compclassmeta, ctx->cv); /* steal CV */
      break;

    case PHASER_ADJUSTPARAMS:
      mop_class_add_ADJUSTPARAMS(compclassmeta, ctx->cv); /* steal CV */
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
  .permit_hintkey  = "Object::Pad/method",
  .permit          = parse_permit,
  .pre_subparse    = parse_pre_subparse,
  .filter_attr     = parse_filter_attr,
  .post_blockstart = parse_post_blockstart,
  .pre_blockend    = parse_pre_blockend,
  .post_newcv      = parse_post_newcv,
};

static struct XSParseSublikeHooks parse_phaser_hooks = {
  .skip_parts = XS_PARSE_SUBLIKE_PART_NAME|XS_PARSE_SUBLIKE_PART_ATTRS,
  /* no permit */
  .pre_subparse    = parse_pre_subparse,
  .post_blockstart = parse_post_blockstart,
  .pre_blockend    = parse_pre_blockend,
  .post_newcv      = parse_post_newcv,
};

static int parse_phaser(pTHX_ OP **out, void *hookdata)
{
  if(!have_compclassmeta)
    croak("Cannot '%s' outside of 'class'", phasertypename[PTR2UV(hookdata)]);

  lex_read_space(0);

  return xs_parse_sublike(&parse_phaser_hooks, hookdata, out);
}

static const struct XSParseKeywordHooks kwhooks_phaser = {
  .permit_hintkey = "Object::Pad/method",
  .parse = &parse_phaser,
};

static void check_requires(pTHX_ void *hookdata)
{
  if(!have_compclassmeta)
    croak("Cannot 'requires' outside of 'role'");

  if(compclassmeta->type == METATYPE_CLASS)
    croak("A class may not declare required methods");
}

static int build_requires(pTHX_ OP **out, XSParseKeywordPiece *args[], size_t nargs, void *hookdata)
{
  SV *mname = args[0]->sv;

  av_push(compclassmeta->requiremethods, mname);

  *out = newOP(OP_NULL, 0);

  return KEYWORD_PLUGIN_STMT;
}

static const struct XSParseKeywordHooks kwhooks_requires = {
  .flags = XPK_FLAG_STMT|XPK_FLAG_AUTOSEMI,
  .permit_hintkey = "Object::Pad/requires",

  .check = &check_requires,

  .pieces = (const struct XSParseKeywordPieceType []){
    XPK_IDENT,
    {0}
  },
  .build = &build_requires,
};

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

  I32 i;
  for(i = 0; i < av_count(meta->direct_slots); i++)
    ret += dump_slotmeta(aTHX_ sv, (SlotMeta *)AvARRAY(meta->direct_slots)[i]);

  ret += DMD_ANNOTATE_SV(sv, (SV *)meta->initslots, "the Object::Pad initslots CV");

  ret += DMD_ANNOTATE_SV(sv, (SV *)meta->buildblocks, "the Object::Pad BUILD blocks AV");

  ret += DMD_ANNOTATE_SV(sv, (SV *)meta->adjustblocks, "the Object::Pad ADJUST blocks AV");

  ret += DMD_ANNOTATE_SV(sv, (SV *)meta->methodscope, "the Object::Pad temporary method scope");

  switch(meta->type) {
    case METATYPE_CLASS:
      if(meta->cls.foreign_new)
        ret += DMD_ANNOTATE_SV(sv, (SV *)meta->cls.foreign_new, "the Object::Pad foreign superclass constructor CV");
      if(meta->cls.direct_roles)
        ret += DMD_ANNOTATE_SV(sv, (SV *)meta->cls.direct_roles, "the Object::Pad direct roles AV");
      break;

    case METATYPE_ROLE:
      ret += DMD_ANNOTATE_SV(sv, (SV *)meta->role.applied_classes, "the Object::Pad role applied classes HV");
      break;
  }

  return ret;
}
#endif

MODULE = Object::Pad    PACKAGE = Object::Pad::MOP::Class

INCLUDE: mop-class.xsi

MODULE = Object::Pad    PACKAGE = Object::Pad::MOP::Method

INCLUDE: mop-method.xsi

MODULE = Object::Pad    PACKAGE = Object::Pad::MOP::Slot

INCLUDE: mop-slot.xsi

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
#ifdef HAVE_DMD_HELPER
  DMD_SET_PACKAGE_HELPER("Object::Pad::MOP::Class", &dumppackage_class);
#endif

  boot_xs_parse_keyword(0.10); /* XPK_OPTIONAL(XPK_CHOICE...) */

  register_xs_parse_keyword("class", &kwhooks_class, (void *)METATYPE_CLASS);
  register_xs_parse_keyword("role",  &kwhooks_role,  (void *)METATYPE_ROLE);

  register_xs_parse_keyword("has", &kwhooks_has, NULL);

  register_xs_parse_keyword("BUILD", &kwhooks_phaser, (void *)PHASER_BUILD);
  register_xs_parse_keyword("ADJUST", &kwhooks_phaser, (void *)PHASER_ADJUST);
  register_xs_parse_keyword("ADJUSTPARAMS", &kwhooks_phaser, (void *)PHASER_ADJUSTPARAMS);

  register_xs_parse_keyword("requires", &kwhooks_requires, NULL);

  boot_xs_parse_sublike(0.13); /* permit_hintkey */

  register_xs_parse_sublike("method", &parse_method_hooks, (void *)PHASER_NONE);

  ObjectPad__boot_classes();
  ObjectPad__boot_slots(aTHX);
