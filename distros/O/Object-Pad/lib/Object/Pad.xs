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
#  define WANT_DMD_API_044
#  include "DMD_helper.h"
#endif

#include "perl-additions.c.inc"
#include "lexer-additions.c.inc"
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

#ifdef HAVE_UNOP_AUX
#  define METHSTART_CONTAINS_FIELD_BINDINGS

/* We'll reserve the top two bits of a UV for storing the `type` value for a
 * fieldpad operation; the remainder stores the fieldix itself */
#  define UVBITS (UVSIZE*8)
#  define FIELDIX_TYPE_SHIFT  (UVBITS-2)
#  define FIELDIX_MASK        ((1LL<<FIELDIX_TYPE_SHIFT)-1)
#endif

#include "object_pad.h"
#include "class.h"
#include "field.h"

#define warn_deprecated(...)  Perl_ck_warner(aTHX_ packWARN(WARN_DEPRECATED), __VA_ARGS__)

typedef void MethodAttributeHandler(pTHX_ MethodMeta *meta, const char *value, void *data);

struct MethodAttributeDefinition {
  char *attrname;
  /* TODO: int flags */
  MethodAttributeHandler *apply;
  void *applydata;
};

/**********************************
 * Class and Field Implementation *
 **********************************/

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

#define find_padix_for_field(fieldmeta)  S_find_padix_for_field(aTHX_ fieldmeta)
static PADOFFSET S_find_padix_for_field(pTHX_ FieldMeta *fieldmeta)
{
  const char *fieldname = SvPVX(fieldmeta->name);
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

    /* field names are all OUTER vars. This is necessary so we don't get
     * confused by signatures params of the same name
     *   https://rt.cpan.org/Ticket/Display.html?id=134456
     */
    if(!PadnameOUTER(name))
      continue;
    if(!strEQ(pv, fieldname))
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
  return pad_findmy_pv(fieldname, 0);
#endif
}

#define bind_field_to_pad(sv, fieldix, private, padix)  S_bind_field_to_pad(aTHX_ sv, fieldix, private, padix)
static void S_bind_field_to_pad(pTHX_ SV *sv, FIELDOFFSET fieldix, U8 private, PADOFFSET padix)
{
  SV *val;
  switch(private) {
    case OPpFIELDPAD_SV:
      val = sv;
      break;
    case OPpFIELDPAD_AV:
      if(!SvROK(sv) || SvTYPE(val = SvRV(sv)) != SVt_PVAV)
        croak("ARGH: expected to find an ARRAY reference at field index %ld", (long int)fieldix);
      break;
    case OPpFIELDPAD_HV:
      if(!SvROK(sv) || SvTYPE(val = SvRV(sv)) != SVt_PVHV)
        croak("ARGH: expected to find a HASH reference at field index %ld", (long int)fieldix);
      break;
    default:
      croak("ARGH: unsure what to do with this field type");
  }

  SAVESPTR(PAD_SVl(padix));
  PAD_SVl(padix) = SvREFCNT_inc(val);
  save_freesv(val);
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
  FIELDOFFSET offset;
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

  AV *backingav;

  if(is_role) {
    if(embedding == &embedding_standalone) {
      backingav = NULL;
    }
    else {
      SV *instancedata = get_obj_backingav(self, embedding->classmeta->repr, create);

      if(create) {
        backingav = (AV *)instancedata;
        SvREFCNT_inc((SV *)backingav);
      }
      else {
        backingav = newAV();
        /* MASSIVE CHEAT */
        AvARRAY(backingav) = AvARRAY(instancedata) + offset;
        AvFILLp(backingav) = AvFILLp(instancedata) - offset;
        AvREAL_off(backingav);
      }
    }
  }
  else {
    /* op_private contains the repr type so we can extract backing */
    backingav = (AV *)get_obj_backingav(self, PL_op->op_private, create);
    SvREFCNT_inc(backingav);
  }

  if(backingav) {
    SAVESPTR(PAD_SVl(PADIX_SLOTS));
    PAD_SVl(PADIX_SLOTS) = (SV *)backingav;
    save_freesv((SV *)backingav);
  }

#ifdef METHSTART_CONTAINS_FIELD_BINDINGS
  UNOP_AUX_item *aux = cUNOP_AUX->op_aux;
  if(aux) {
    U32 fieldcount  = (aux++)->uv;
    U32 max_fieldix = (aux++)->uv;
    SV **fieldsvs = AvARRAY(backingav);

    if(max_fieldix > av_top_index(backingav))
      croak("ARGH: instance does not have a field at index %ld", (long int)max_fieldix);

    while(fieldcount) {
      PADOFFSET padix   = (aux++)->uv;
      UV        fieldix = (aux++)->uv;

      U8 private = fieldix >> FIELDIX_TYPE_SHIFT;
      fieldix &= FIELDIX_MASK;

      bind_field_to_pad(fieldsvs[fieldix], fieldix, private, padix);

      fieldcount--;
    }
  }
#endif

  return PL_op->op_next;
}

OP *ObjectPad_newMETHSTARTOP(pTHX_ U32 flags)
{
#ifdef METHSTART_CONTAINS_FIELD_BINDINGS
  /* We know we're on 5.22 or above, so no worries about assert failures */
  OP *op = newUNOP_AUX(OP_CUSTOM, flags, NULL, NULL);
  op->op_ppaddr = &pp_methstart;
#else
  OP *op = newOP_CUSTOM(&pp_methstart, flags);
#endif
  op->op_private = (U8)(flags >> 8);
  return op;
}

static XOP xop_commonmethstart;
static OP *pp_commonmethstart(pTHX)
{
  SV *self = av_shift(GvAV(PL_defgv));

  if(SvROK(self))
    /* TODO: Should handle this somehow */
    croak("Cannot invoke common method on an instance");

  save_clearsv(&PAD_SVl(PADIX_SELF));
  sv_setsv(PAD_SVl(PADIX_SELF), self);

  return PL_op->op_next;
}

OP *ObjectPad_newCOMMONMETHSTARTOP(pTHX_ U32 flags)
{
  OP *op = newOP_CUSTOM(&pp_commonmethstart, flags);
  op->op_private = (U8)(flags >> 8);
  return op;
}

static XOP xop_fieldpad;
static OP *pp_fieldpad(pTHX)
{
#ifdef HAVE_UNOP_AUX
  FIELDOFFSET fieldix = PTR2IV(cUNOP_AUX->op_aux);
#else
  UNOP_with_IV *op = (UNOP_with_IV *)PL_op;
  FIELDOFFSET fieldix = op->iv;
#endif
  PADOFFSET targ = PL_op->op_targ;

  if(SvTYPE(PAD_SV(PADIX_SLOTS)) != SVt_PVAV)
    croak("ARGH: expected ARRAY of slots at PADIX_SLOTS");

  AV *backingav = (AV *)PAD_SV(PADIX_SLOTS);

  if(fieldix > av_top_index(backingav))
    croak("ARGH: instance does not have a field at index %ld", (long int)fieldix);

  bind_field_to_pad(AvARRAY(backingav)[fieldix], fieldix, PL_op->op_private, targ);

  return PL_op->op_next;
}

OP *ObjectPad_newFIELDPADOP(pTHX_ U32 flags, PADOFFSET padix, FIELDOFFSET fieldix)
{
#ifdef HAVE_UNOP_AUX
  OP *op = newUNOP_AUX(OP_CUSTOM, flags, NULL, NUM2PTR(UNOP_AUX_item *, fieldix));
#else
  OP *op = newUNOP_with_IV(OP_CUSTOM, flags, NULL, fieldix);
#endif
  op->op_targ = padix;
  op->op_private = (U8)(flags >> 8);
  op->op_ppaddr = &pp_fieldpad;

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

static void inplace_trim_whitespace(SV *sv)
{
  if(!SvPOK(sv) || !SvCUR(sv))
    return;

  char *dst = SvPVX(sv);
  char *src = dst;

  while(*src && isSPACE(*src))
    src++;

  if(src > dst) {
    size_t offset = src - dst;
    Move(src, dst, SvCUR(sv) - offset, char);
    SvCUR(sv) -= offset;
  }

  src = dst + SvCUR(sv) - 1;
  while(src > dst && isSPACE(*src))
    src--;

  SvCUR(sv) = src - dst + 1;
  dst[SvCUR(sv)] = 0;
}

static void S_apply_method_common(pTHX_ MethodMeta *meta, const char *val, void *_data)
{
  meta->is_common = true;
}

static void S_apply_method_override(pTHX_ MethodMeta *meta, const char *val, void *_data)
{
  if(!meta->name)
    croak("Cannot apply :override to anonymous methods");

  GV *gv = gv_fetchmeth_sv(compclassmeta->stash, meta->name, 0, 0);
  if(gv && GvCV(gv))
    return;

  croak("Superclass does not have a method named '%" SVf "'", SVfARG(meta->name));
}

static struct MethodAttributeDefinition method_attributes[] = {
  { "common",   &S_apply_method_common,   NULL },
  { "override", &S_apply_method_override, NULL },
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
    warn_deprecated("'%s' modifier keyword is deprecated; use :isa() attribute instead", args[argi]->i ? "isa" : "extends");
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

  ClassMeta *meta = mop_create_class(type, packagename);

  if(superclassname && SvOK(superclassname))
    mop_class_set_superclass(meta, superclassname);

  int nimplements = args[argi++]->i;
  if(nimplements) {
    int i;
    for(i = 0; i < nimplements; i++) {
      warn_deprecated("'%s' modifier keyword is deprecated; use :does() attribute instead", args[argi]->i ? "does" : "implements");
      argi++; /* ignore the XPK_CHOICE() integer; `implements` and `does` are synonyms */
      int nroles = args[argi++]->i;
      while(nroles--) {
        SV *rolename = args[argi++]->sv;
        if(!rolename)
          croak("Expected a role name after 'does'");

        SV *rolever = args[argi++]->sv;

        mop_class_load_and_add_role(meta, rolename, rolever);
      }
    }
  }

  if(superclassname)
    SvREFCNT_dec(superclassname);

  int nattrs = args[argi++]->i;
  if(nattrs) {
    if(hv_fetchs(GvHV(PL_hintgv), "Object::Pad/configure(no_class_attrs)", 0))
      croak("Class/role attributes are not permitted");

    int i;
    for(i = 0; i < nattrs; i++) {
      SV *attrname = args[argi]->attr.name;
      SV *attrval  = args[argi]->attr.value;

      inplace_trim_whitespace(attrval);

      mop_class_apply_attribute(meta, SvPVX(attrname), attrval);

      argi++;
    }
  }

  if(hv_fetchs(GvHV(PL_hintgv), "Object::Pad/configure(always_strict)", 0)) {
    mop_class_apply_attribute(meta, "strict", sv_2mortal(newSVpvs("params")));
  }

  mop_class_begin(meta);

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

static void check_field(pTHX_ void *hookdata)
{
  char *kwname = hookdata;

  if(!have_compclassmeta)
    croak("Cannot '%s' outside of 'class'", kwname);

  if(compclassmeta->role_is_invokable)
    croak("Cannot add field data to an invokable role");

  if(!sv_eq(PL_curstname, compclassmeta->name))
    croak("Current package name no longer matches current class (%" SVf " vs %" SVf ")",
      PL_curstname, compclassmeta->name);
}

static int build_field(pTHX_ OP **out, XSParseKeywordPiece *args[], size_t nargs, void *hookdata)
{
  int argi = 0;

  SV *name = args[argi++]->sv;
  char sigil = SvPV_nolen(name)[0];

  FieldMeta *fieldmeta = mop_class_add_field(compclassmeta, name);
  SvREFCNT_dec(name);

  int nattrs = args[argi++]->i;
  if(nattrs) {
    if(hv_fetchs(GvHV(PL_hintgv), "Object::Pad/configure(no_field_attrs)", 0))
      croak("Field attributes are not permitted");

    SV *fieldmetasv = newSV(0);
    sv_setref_uv(fieldmetasv, "Object::Pad::MOP::Field", PTR2UV(fieldmeta));
    SAVEFREESV(fieldmetasv);

    while(argi < (nattrs+2)) {
      SV *attrname = args[argi]->attr.name;
      SV *attrval  = args[argi]->attr.value;

      inplace_trim_whitespace(attrval);

      mop_field_apply_attribute(fieldmeta, SvPVX(attrname), attrval);

      if(attrval)
        SvREFCNT_dec(attrval);

      argi++;
    }
  }

  /* It would be nice to just yield some OP to represent the has field here
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

      SV *defaultsv = newSV(0);
      mop_field_set_default_sv(fieldmeta, defaultsv);

      /* An OP_CONST whose op_type is OP_CUSTOM.
       * This way we avoid the opchecker and finalizer doing bad things to our
       * defaultsv SV by setting it SvREADONLY_on().
       */
      OP *fieldop = newSVOP_CUSTOM(PL_ppaddr[OP_CONST], 0, SvREFCNT_inc(defaultsv));

      OP *lhs, *rhs;

      switch(sigil) {
        case '$':
          *out = newBINOP(OP_SASSIGN, 0, op_contextualize(op, G_SCALAR), fieldop);
          break;

        case '@':
          sv_setrv_noinc(defaultsv, (SV *)newAV());
          lhs = newUNOP(OP_RV2AV, OPf_MOD|OPf_REF, fieldop);
          goto field_array_hash_common;

        case '%':
          sv_setrv_noinc(defaultsv, (SV *)newHV());
          lhs = newUNOP(OP_RV2HV, OPf_MOD|OPf_REF, fieldop);
          goto field_array_hash_common;

field_array_hash_common:
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

      forbid_outofblock_ops(op, "a field initialiser block");

      switch(sigil) {
        case '$':
          want = G_SCALAR;
          break;
        case '@':
        case '%':
          want = G_LIST;
          break;
      }

      fieldmeta->defaultexpr = op_contextualize(op_scope(op), want);
    }
    break;
  }

  mop_field_seal(fieldmeta);

  return KEYWORD_PLUGIN_STMT;
}

static void setup_parse_field_initexpr(pTHX_ void *hookdata)
{
  CV *was_compcv = PL_compcv;
  HV *hints = GvHV(PL_hintgv);

  if(!hints || !hv_fetchs(hints, "Object::Pad/experimental(init_expr)", 0))
    Perl_ck_warner(aTHX_ packWARN(WARN_EXPERIMENTAL),
      "field initialiser expression is experimental and may be changed or removed without notice");

  resume_compcv_and_save(&compclassmeta->initfields_compcv);

  /* Set up this new block as if the current compiler context were its scope */

  if(CvOUTSIDE(PL_compcv))
    SvREFCNT_dec(CvOUTSIDE(PL_compcv));

  CvOUTSIDE(PL_compcv)     = (CV *)SvREFCNT_inc(was_compcv);
  CvOUTSIDE_SEQ(PL_compcv) = PL_cop_seqmax;
}

static const struct XSParseKeywordHooks kwhooks_field = {
  .flags = XPK_FLAG_STMT,
  .permit_hintkey = "Object::Pad/field",

  .check = &check_field,

  .pieces = (const struct XSParseKeywordPieceType []){
    XPK_LEXVARNAME(XPK_LEXVAR_ANY),
    XPK_ATTRIBUTES,
    XPK_TAGGEDCHOICE(
      /* An optional choice of only one item; for compat. with kwhooks_has */
      XPK_PREFIXED_BLOCK_ENTERLEAVE(XPK_SETUP(&setup_parse_field_initexpr)), XPK_TAG(1)
    ),
    {0}
  },
  .build = &build_field,
};
static const struct XSParseKeywordHooks kwhooks_has = {
  .flags = XPK_FLAG_STMT,
  .permit_hintkey = "Object::Pad/has",

  .check = &check_field,

  .pieces = (const struct XSParseKeywordPieceType []){
    XPK_LEXVARNAME(XPK_LEXVAR_ANY),
    XPK_ATTRIBUTES,
    XPK_CHOICE(
      XPK_SEQUENCE(XPK_EQUALS, XPK_TERMEXPR, XPK_AUTOSEMI),
      XPK_PREFIXED_BLOCK_ENTERLEAVE(XPK_SETUP(&setup_parse_field_initexpr)),
      {0}
    ),
    {0}
  },
  .build = &build_field,
};

/* We use the method-like keyword parser to parse phaser blocks as well as
 * methods. In order to tell what is going on, hookdata will be an integer
 * set to one of the following
 */

enum PhaserType {
  PHASER_NONE, /* A normal `method`; i.e. not a phaser */
  PHASER_BUILD,
  PHASER_ADJUST,
};

static const char *phasertypename[] = {
  [PHASER_BUILD]  = "BUILD",
  [PHASER_ADJUST] = "ADJUST",
};

static bool parse_method_permit(pTHX_ void *hookdata)
{
  if(!have_compclassmeta)
    croak("Cannot 'method' outside of 'class'");

  if(!sv_eq(PL_curstname, compclassmeta->name))
    croak("Current package name no longer matches current class (%" SVf " vs %" SVf ")",
      PL_curstname, compclassmeta->name);

  return true;
}

static void parse_method_pre_subparse(pTHX_ struct XSParseSublikeContext *ctx, void *hookdata)
{
  enum PhaserType type = PTR2UV(hookdata);
  U32 i;
  AV *fields = compclassmeta->direct_fields;
  U32 nfields = av_count(fields);

  /* XS::Parse::Sublike doesn't support lexical `method $foo`, but we can hack
   * it up here
   */
  if(type == PHASER_NONE && !ctx->name &&
     lex_peek_unichar(0) == '$') {
    ctx->name = lex_scan_lexvar();
    if(!ctx->name)
      croak("Expected a lexical variable name");

    lex_read_space(0);
    hv_stores(ctx->moddata, "Object::Pad/method_varname", SvREFCNT_inc(ctx->name));

    /* XPS should set a CV name */
    ctx->actions |= XS_PARSE_SUBLIKE_ACTION_SET_CVNAME;
    /* XPS should not CVf_ANON, install a named symbol, or emit an anoncode expr */
    ctx->actions &= ~(XS_PARSE_SUBLIKE_ACTION_CVf_ANON|XS_PARSE_SUBLIKE_ACTION_INSTALL_SYMBOL|XS_PARSE_SUBLIKE_ACTION_REFGEN_ANONCODE|XS_PARSE_SUBLIKE_ACTION_RET_EXPR);
  }

  switch(type) {
    case PHASER_NONE:
      if(ctx->name && strEQ(SvPVX(ctx->name), "BUILD"))
        croak("method BUILD is no longer supported; use a BUILD block instead");
      break;

    case PHASER_BUILD:
    case PHASER_ADJUST:
      break;
  }

  if(type != PHASER_NONE)
    /* We need to fool start_subparse() into thinking this is a named function
     * so it emits a real CV and not a protosub
     */
    ctx->actions &= ~XS_PARSE_SUBLIKE_ACTION_CVf_ANON;

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

  for(i = 0; i < nfields; i++) {
    FieldMeta *fieldmeta = (FieldMeta *)AvARRAY(fields)[i];

    /* Skip the anonymous ones */
    if(SvCUR(fieldmeta->name) < 2)
      continue;

    /* Claim these are all STATE variables just to quiet the "will not stay
     * shared" warning */
    pad_add_name_sv(fieldmeta->name, padadd_STATE, NULL, NULL);
  }

  intro_my();

  MethodMeta *compmethodmeta;
  Newx(compmethodmeta, 1, MethodMeta);

  compmethodmeta->name = SvREFCNT_inc(ctx->name);
  compmethodmeta->class = NULL;
  compmethodmeta->role  = NULL;
  compmethodmeta->is_common = false;

  hv_stores(ctx->moddata, "Object::Pad/compmethodmeta", newSVuv(PTR2UV(compmethodmeta)));

  LEAVE;
}

static bool parse_method_filter_attr(pTHX_ struct XSParseSublikeContext *ctx, SV *attr, SV *val, void *hookdata)
{
  MethodMeta *compmethodmeta = NUM2PTR(MethodMeta *, SvUV(*hv_fetchs(ctx->moddata, "Object::Pad/compmethodmeta", 0)));

  struct MethodAttributeDefinition *def;
  for(def = method_attributes; def->attrname; def++) {
    if(!strEQ(SvPVX(attr), def->attrname))
      continue;

    /* TODO: We might want to wrap the CV in some sort of MethodMeta struct
     * but for now we'll just pass the XSParseSublikeContext context */
    (*def->apply)(aTHX_ compmethodmeta, SvPOK(val) ? SvPVX(val) : NULL, def->applydata);

    return true;
  }

  /* No error, just let it fall back to usual attribute handling */
  return false;
}

static void parse_method_post_blockstart(pTHX_ struct XSParseSublikeContext *ctx, void *hookdata)
{
  MethodMeta *compmethodmeta = NUM2PTR(MethodMeta *, SvUV(*hv_fetchs(ctx->moddata, "Object::Pad/compmethodmeta", 0)));

  /* Splice in the field scope CV in */
  CV *methodscope = compclassmeta->methodscope;

  if(CvANON(PL_compcv))
    CvANON_on(methodscope);

  CvOUTSIDE    (methodscope) = CvOUTSIDE    (PL_compcv);
  CvOUTSIDE_SEQ(methodscope) = CvOUTSIDE_SEQ(PL_compcv);

  CvOUTSIDE(PL_compcv) = methodscope;

  if(!compmethodmeta->is_common)
    /* instance method */
    extend_pad_vars(compclassmeta);
  else {
    /* :common method */
    PADOFFSET padix;

    padix = pad_add_name_pvs("$class", 0, NULL, NULL);
    if(padix != PADIX_SELF)
      croak("ARGH: Expected that padix[$class] = 1");
  }

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

static void parse_method_pre_blockend(pTHX_ struct XSParseSublikeContext *ctx, void *hookdata)
{
  enum PhaserType type = PTR2UV(hookdata);
  PADNAMELIST *fieldnames = PadlistNAMES(CvPADLIST(compclassmeta->methodscope));
  I32 nfields = av_count(compclassmeta->direct_fields);
  PADNAME **snames = PadnamelistARRAY(fieldnames);
  PADNAME **padnames = PadnamelistARRAY(PadlistNAMES(CvPADLIST(PL_compcv)));

  MethodMeta *compmethodmeta = NUM2PTR(MethodMeta *, SvUV(*hv_fetchs(ctx->moddata, "Object::Pad/compmethodmeta", 0)));

  /* If we have no ctx->body that means this was a bodyless method
   * declaration; a required method for a role
   */
  if(ctx->body && !compmethodmeta->is_common) {
    OP *fieldops = NULL, *methstartop;
#if HAVE_PERL_VERSION(5, 22, 0)
    U32 cop_seq_low = COP_SEQ_RANGE_LOW(padnames[PADIX_SELF]);
#endif

#ifdef METHSTART_CONTAINS_FIELD_BINDINGS
    AV *fieldmap = newAV();
    U32 fieldcount = 0, max_fieldix = 0;

    SAVEFREESV((SV *)fieldmap);
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

    fieldops = op_append_list(OP_LINESEQ, fieldops,
      newSTATEOP(0, NULL, NULL));
    fieldops = op_append_list(OP_LINESEQ, fieldops,
      (methstartop = newMETHSTARTOP(0 |
        (compclassmeta->type == METATYPE_ROLE ? OPf_SPECIAL : 0) |
        (compclassmeta->repr << 8))));

    int i;
    for(i = 0; i < nfields; i++) {
      FieldMeta *fieldmeta = (FieldMeta *)AvARRAY(compclassmeta->direct_fields)[i];
      PADNAME *fieldname = snames[i + 1];

      if(!fieldname
#if HAVE_PERL_VERSION(5, 22, 0)
        /* On perl 5.22 and above we can use PadnameREFCNT to detect which pad
         * slots are actually being used
         */
         || PadnameREFCNT(fieldname) < 2
#endif
        )
          continue;

      FIELDOFFSET fieldix = fieldmeta->fieldix;
      PADOFFSET padix = find_padix_for_field(fieldmeta);

      if(padix == NOT_IN_PAD)
        continue;

      U8 private = 0;
      switch(SvPV_nolen(fieldmeta->name)[0]) {
        case '$': private = OPpFIELDPAD_SV; break;
        case '@': private = OPpFIELDPAD_AV; break;
        case '%': private = OPpFIELDPAD_HV; break;
      }

#ifdef METHSTART_CONTAINS_FIELD_BINDINGS
      assert((fieldix & ~FIELDIX_MASK) == 0);
      av_store(fieldmap, padix, newSVuv(((UV)private << FIELDIX_TYPE_SHIFT) | fieldix));
      fieldcount++;
      if(fieldix > max_fieldix)
        max_fieldix = fieldix;
#else
      fieldops = op_append_list(OP_LINESEQ, fieldops,
        /* alias the padix from the field */
        newFIELDPADOP(private << 8, padix, fieldix));
#endif

#if HAVE_PERL_VERSION(5, 22, 0)
      /* Unshare the padname so the one in the methodscope pad returns to refcount 1 */
      PADNAME *newpadname = newPADNAMEpvn(PadnamePV(fieldname), PadnameLEN(fieldname));
      PadnameREFCNT_dec(padnames[padix]);
      padnames[padix] = newpadname;

      /* Turn off OUTER and set a valid COP sequence range, so the lexical is
       * visible to eval(), PadWalker, perldb, etc.. */
      PadnameOUTER_off(newpadname);
      COP_SEQ_RANGE_LOW(newpadname) = cop_seq_low;
      COP_SEQ_RANGE_HIGH(newpadname) = PL_cop_seqmax;
#endif
    }

#ifdef METHSTART_CONTAINS_FIELD_BINDINGS
    if(fieldcount) {
      UNOP_AUX_item *aux;
      Newx(aux, 2 + fieldcount*2, UNOP_AUX_item);
      cUNOP_AUXx(methstartop)->op_aux = aux;

      (aux++)->uv = fieldcount;
      (aux++)->uv = max_fieldix;

      for(Size_t i = 0; i < av_count(fieldmap); i++) {
        if(!AvARRAY(fieldmap)[i] || !SvOK(AvARRAY(fieldmap)[i]))
          continue;

        (aux++)->uv = i;
        (aux++)->uv = SvUV(AvARRAY(fieldmap)[i]);
      }
    }
#endif
    ctx->body = op_append_list(OP_LINESEQ, fieldops, ctx->body);
  }
  else if(ctx->body && compmethodmeta->is_common) {
    ctx->body = op_append_list(OP_LINESEQ,
      newCOMMONMETHSTARTOP(0 |
        (compclassmeta->repr << 8)),
      ctx->body);
  }

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

  if(type != PHASER_NONE)
    /* We need to remove the name now to stop newATTRSUB() from creating this
     * as a named symbol table entry
     */
    ctx->actions &= ~XS_PARSE_SUBLIKE_ACTION_INSTALL_SYMBOL;
}

static void parse_method_post_newcv(pTHX_ struct XSParseSublikeContext *ctx, void *hookdata)
{
  enum PhaserType type = PTR2UV(hookdata);

  MethodMeta *compmethodmeta;
  {
    SV *tmpsv = *hv_fetchs(ctx->moddata, "Object::Pad/compmethodmeta", 0);
    compmethodmeta = NUM2PTR(MethodMeta *, SvUV(tmpsv));
    sv_setuv(tmpsv, 0);
  }

  if(ctx->cv)
    CvMETHOD_on(ctx->cv);

  if(!ctx->cv) {
    /* This is a required method declaration for a role */
    /* TODO: This was a pretty rubbish way to detect that. We should remember it
     *   more reliably */

    /* This already checks and complains if meta->type != METATYPE_ROLE */
    mop_class_add_required_method(compclassmeta, ctx->name);
    return;
  }

  switch(type) {
    case PHASER_NONE:
      if(ctx->cv && ctx->name && (ctx->actions & XS_PARSE_SUBLIKE_ACTION_INSTALL_SYMBOL)) {
        MethodMeta *meta = mop_class_add_method(compclassmeta, ctx->name);

        meta->is_common = compmethodmeta->is_common;
      }
      break;

    case PHASER_BUILD:
      mop_class_add_BUILD(compclassmeta, ctx->cv); /* steal CV */
      break;

    case PHASER_ADJUST:
      mop_class_add_ADJUST(compclassmeta, ctx->cv); /* steal CV */
      break;
  }

  SV **varnamep;
  if((varnamep = hv_fetchs(ctx->moddata, "Object::Pad/method_varname", 0))) {
    PADOFFSET padix = pad_add_name_sv(*varnamep, 0, NULL, NULL);
    intro_my();

    SV **svp = &PAD_SVl(padix);

    if(*svp)
      SvREFCNT_dec(*svp);

    *svp = newRV_inc((SV *)ctx->cv);
    SvREADONLY_on(*svp);
  }

  if(type != PHASER_NONE)
    /* Do not generate REFGEN/ANONCODE optree, do not yield expression */
    ctx->actions &= ~(XS_PARSE_SUBLIKE_ACTION_REFGEN_ANONCODE|XS_PARSE_SUBLIKE_ACTION_RET_EXPR);

  SvREFCNT_dec(compmethodmeta->name);
  Safefree(compmethodmeta);
}

static struct XSParseSublikeHooks parse_method_hooks = {
  .flags           = XS_PARSE_SUBLIKE_FLAG_FILTERATTRS |
                     XS_PARSE_SUBLIKE_COMPAT_FLAG_DYNAMIC_ACTIONS |
                     XS_PARSE_SUBLIKE_FLAG_BODY_OPTIONAL,
  .permit_hintkey  = "Object::Pad/method",
  .permit          = parse_method_permit,
  .pre_subparse    = parse_method_pre_subparse,
  .filter_attr     = parse_method_filter_attr,
  .post_blockstart = parse_method_post_blockstart,
  .pre_blockend    = parse_method_pre_blockend,
  .post_newcv      = parse_method_post_newcv,
};

static struct XSParseSublikeHooks parse_phaser_hooks = {
  .flags           = XS_PARSE_SUBLIKE_COMPAT_FLAG_DYNAMIC_ACTIONS,
  .skip_parts      = XS_PARSE_SUBLIKE_PART_NAME|XS_PARSE_SUBLIKE_PART_ATTRS,
  /* no permit */
  .pre_subparse    = parse_method_pre_subparse,
  .post_blockstart = parse_method_post_blockstart,
  .pre_blockend    = parse_method_pre_blockend,
  .post_newcv      = parse_method_post_newcv,
};

static int parse_phaser(pTHX_ OP **out, void *hookdata)
{
  if(!have_compclassmeta)
    croak("Cannot '%s' outside of 'class'", phasertypename[PTR2UV(hookdata)]);

  lex_read_space(0);

  return xs_parse_sublike(&parse_phaser_hooks, hookdata, out);
}

static const struct XSParseKeywordHooks kwhooks_BUILD = {
  .permit_hintkey = "Object::Pad/BUILD",
  .parse = &parse_phaser,
};

static const struct XSParseKeywordHooks kwhooks_ADJUST = {
  .permit_hintkey = "Object::Pad/ADJUST",
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

  warn_deprecated("'requires' is now discouraged; use an empty 'method NAME;' declaration instead");

  mop_class_add_required_method(compclassmeta, mname);

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
static void dump_fieldmeta(pTHX_ DMDContext *ctx, FieldMeta *fieldmeta)
{
  DMD_DUMP_STRUCT(ctx, "Object::Pad/FieldMeta", fieldmeta, sizeof(FieldMeta),
    6, ((const DMDNamedField []){
      {"the name SV",          DMD_FIELD_PTR,  .ptr = fieldmeta->name},
      {"the class",            DMD_FIELD_PTR,  .ptr = fieldmeta->class},
      {"the default value SV", DMD_FIELD_PTR,  .ptr = mop_field_get_default_sv(fieldmeta)},
      /* TODO: Maybe hunt for constants in the defaultexpr optree fragment? */
      {"fieldix",              DMD_FIELD_UINT, .n   = fieldmeta->fieldix},
      {"the :param name SV",   DMD_FIELD_PTR,  .ptr = fieldmeta->paramname},
      {"the hooks AV",         DMD_FIELD_PTR,  .ptr = fieldmeta->hooks},
    })
  );
}

static void dump_methodmeta(pTHX_ DMDContext *ctx, MethodMeta *methodmeta)
{
  DMD_DUMP_STRUCT(ctx, "Object::Pad/MethodMeta", methodmeta, sizeof(MethodMeta),
    4, ((const DMDNamedField []){
      {"the name SV",     DMD_FIELD_PTR,  .ptr = methodmeta->name},
      {"the class",       DMD_FIELD_PTR,  .ptr = methodmeta->class},
      {"the origin role", DMD_FIELD_PTR,  .ptr = methodmeta->role},
      {"is_common",       DMD_FIELD_BOOL, .b   = methodmeta->is_common},
    })
  );
}

static void dump_adjustblock(pTHX_ DMDContext *ctx, AdjustBlock *adjustblock)
{
  DMD_DUMP_STRUCT(ctx, "Object::Pad/AdjustBlock", adjustblock, sizeof(AdjustBlock),
    2, ((const DMDNamedField []){
      {"the CV",          DMD_FIELD_PTR,  .ptr = adjustblock->cv},
    })
  );
}

static void dump_roleembedding(pTHX_ DMDContext *ctx, RoleEmbedding *embedding)
{
  DMD_DUMP_STRUCT(ctx, "Object::Pad/RoleEmbedding", embedding, sizeof(RoleEmbedding),
    4, ((const DMDNamedField []){
      {"the embedding SV", DMD_FIELD_PTR,  .ptr = embedding->embeddingsv},
      {"the role",         DMD_FIELD_PTR,  .ptr = embedding->rolemeta},
      {"the class",        DMD_FIELD_PTR,  .ptr = embedding->classmeta},
      {"offset",           DMD_FIELD_UINT, .n   = embedding->offset}
    })
  );
}

static void dump_classmeta(pTHX_ DMDContext *ctx, ClassMeta *classmeta)
{
  /* We'll handle the two types of classmeta by claiming two different struct
   * types
   */

#define N_COMMON_FIELDS 16
#define COMMON_FIELDS \
      {"type",                       DMD_FIELD_U8,   .n   = classmeta->type},            \
      {"repr",                       DMD_FIELD_U8,   .n   = classmeta->repr},            \
      {"sealed",                     DMD_FIELD_BOOL, .b   = classmeta->sealed},          \
      {"start_fieldix",              DMD_FIELD_UINT, .n   = classmeta->start_fieldix},   \
      {"the name SV",                DMD_FIELD_PTR,  .ptr = classmeta->name},            \
      {"the stash SV",               DMD_FIELD_PTR,  .ptr = classmeta->stash},           \
      {"the pending submeta AV",     DMD_FIELD_PTR,  .ptr = classmeta->pending_submeta}, \
      {"the hooks AV",               DMD_FIELD_PTR,  .ptr = classmeta->hooks},           \
      {"the direct fields AV",       DMD_FIELD_PTR,  .ptr = classmeta->direct_fields},   \
      {"the direct methods AV",      DMD_FIELD_PTR,  .ptr = classmeta->direct_methods},  \
      {"the param map HV",           DMD_FIELD_PTR,  .ptr = classmeta->parammap},        \
      {"the requiremethods AV",      DMD_FIELD_PTR,  .ptr = classmeta->requiremethods},  \
      {"the initfields CV",          DMD_FIELD_PTR,  .ptr = classmeta->initfields},      \
      {"the BUILD blocks AV",        DMD_FIELD_PTR,  .ptr = classmeta->buildblocks},     \
      {"the ADJUST blocks AV",       DMD_FIELD_PTR,  .ptr = classmeta->adjustblocks},    \
      {"the temporary method scope", DMD_FIELD_PTR,  .ptr = classmeta->methodscope}

  switch(classmeta->type) {
    case METATYPE_CLASS:
      DMD_DUMP_STRUCT(ctx, "Object::Pad/ClassMeta.class", classmeta, sizeof(ClassMeta),
        N_COMMON_FIELDS+5, ((const DMDNamedField []){
          COMMON_FIELDS,
          {"the supermeta",                         DMD_FIELD_PTR, .ptr = classmeta->cls.supermeta},
          {"the foreign superclass constructor CV", DMD_FIELD_PTR, .ptr = classmeta->cls.foreign_new},
          {"the foreign superclass DOES CV",        DMD_FIELD_PTR, .ptr = classmeta->cls.foreign_does},
          {"the direct roles AV",                   DMD_FIELD_PTR, .ptr = classmeta->cls.direct_roles},
          {"the embedded roles AV",                 DMD_FIELD_PTR, .ptr = classmeta->cls.embedded_roles},
        })
      );
      break;

    case METATYPE_ROLE:
      DMD_DUMP_STRUCT(ctx, "Object::Pad/ClassMeta.role", classmeta, sizeof(ClassMeta),
        N_COMMON_FIELDS+2, ((const DMDNamedField []){
          COMMON_FIELDS,
          {"the superroles AV",           DMD_FIELD_PTR, .ptr = classmeta->role.superroles},
          {"the role applied classes HV", DMD_FIELD_PTR, .ptr = classmeta->role.applied_classes},
        })
      );
      break;
  }

#undef COMMON_FIELDS

  I32 i;

  for(i = 0; i < av_count(classmeta->direct_fields); i++) {
    FieldMeta *fieldmeta = (FieldMeta *)AvARRAY(classmeta->direct_fields)[i];

    dump_fieldmeta(aTHX_ ctx, fieldmeta);
  }

  for(i = 0; i < av_count(classmeta->direct_methods); i++) {
    MethodMeta *methodmeta = (MethodMeta *)AvARRAY(classmeta->direct_methods)[i];

    dump_methodmeta(aTHX_ ctx, methodmeta);
  }

  for(i = 0; classmeta->adjustblocks && i < av_count(classmeta->adjustblocks); i++) {
    AdjustBlock *adjustblock = (AdjustBlock *)AvARRAY(classmeta->adjustblocks)[i];

    dump_adjustblock(aTHX_ ctx, adjustblock);
  }

  switch(classmeta->type) {
    case METATYPE_CLASS:
      for(i = 0; i < av_count(classmeta->cls.direct_roles); i++) {
        RoleEmbedding *embedding = (RoleEmbedding *)AvARRAY(classmeta->cls.direct_roles)[i];

        dump_roleembedding(aTHX_ ctx, embedding);
      }
      break;

    case METATYPE_ROLE:
      /* No need to dump the values of role.applied_classes because any class
       * they're applied to will have done that already */
      break;
  }
}

static int dumppackage_class(pTHX_ DMDContext *ctx, const SV *sv)
{
  int ret = 0;

  ClassMeta *meta = NUM2PTR(ClassMeta *, SvUV((SV *)sv));

  dump_classmeta(aTHX_ ctx, meta);

  ret += DMD_ANNOTATE_SV(sv, (SV *)meta, "the Object::Pad class");

  return ret;
}
#endif

/*********************
 * Custom FieldHooks *
 *********************/

struct CustomFieldHookData
{
  SV *apply_cb;
};

static bool fieldhook_custom_apply(pTHX_ FieldMeta *fieldmeta, SV *value, SV **hookdata_ptr, void *_funcdata)
{
  struct CustomFieldHookData *funcdata = _funcdata;

  SV *cb;
  if((cb = funcdata->apply_cb)) {
    dSP;
    ENTER;
    SAVETMPS;

    SV *fieldmetasv = sv_newmortal();
    sv_setref_uv(fieldmetasv, "Object::Pad::MOP::Field", PTR2UV(fieldmeta));

    PUSHMARK(SP);
    EXTEND(SP, 2);
    PUSHs(fieldmetasv);
    PUSHs(value);
    PUTBACK;

    call_sv(cb, G_SCALAR);

    SPAGAIN;
    SV *ret = POPs;
    *hookdata_ptr = SvREFCNT_inc(ret);

    FREETMPS;
    LEAVE;
  }

  return TRUE;
}

/* internal function shared by various *.c files */
void ObjectPad__need_PLparser(pTHX)
{
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
}

/* used by XSUB deconstruct_object */
#define deconstruct_object_class(av, classmeta, offset)  S_deconstruct_object_class(aTHX_ av, classmeta, offset)
static U32 S_deconstruct_object_class(pTHX_ AV *backingav, ClassMeta *classmeta, FIELDOFFSET offset)
{
  dSP;
  U32 retcount = 0;
  AV *fields = classmeta->direct_fields;
  U32 nfields = av_count(fields);

  EXTEND(SP, nfields * 2);

  FIELDOFFSET i;
  for(i = 0; i < nfields; i++) {
    FieldMeta *fieldmeta = (FieldMeta *)AvARRAY(fields)[i];

    mPUSHs(newSVpvf("%" SVf ".%" SVf,
        SVfARG(classmeta->name), SVfARG(fieldmeta->name)));

    SV *value = AvARRAY(backingav)[offset + fieldmeta->fieldix];
    switch(SvPV_nolen(fieldmeta->name)[0]) {
      case '$':
        value = newSVsv(value);
        break;

      case '@':
        value = newRV_noinc((SV *)newAVav((AV *)SvRV(value)));
        break;

      case '%':
        value = newRV_noinc((SV *)newHVhv((HV *)SvRV(value)));
        break;
    }

    mPUSHs(value);

    retcount += 2;
  }

  PUTBACK;

  return retcount;
}

/* used by XSUB ref_field */
#define ref_field_class(want_fieldname, backingav, classmeta, offset)  S_ref_field_class(aTHX_ want_fieldname, backingav, classmeta, offset)
static SV *S_ref_field_class(pTHX_ SV *want_fieldname, AV *backingav, ClassMeta *classmeta, FIELDOFFSET offset)
{
  AV *fields = classmeta->direct_fields;
  U32 nfields = av_count(fields);

  FIELDOFFSET i;
  for(i = 0; i < nfields; i++) {
    FieldMeta *fieldmeta = (FieldMeta *)AvARRAY(fields)[i];

    if(!sv_eq(want_fieldname, fieldmeta->name))
      continue;

    /* found it */
    SV *sv = AvARRAY(backingav)[offset + fieldmeta->fieldix];
    switch(SvPV_nolen(fieldmeta->name)[0]) {
      case '$':
        return newRV_inc(sv);

      case '@':
      case '%':
        return newSVsv(sv);
    }
  }

  return NULL;
}

MODULE = Object::Pad    PACKAGE = Object::Pad::MOP::Class

INCLUDE: mop-class.xsi

MODULE = Object::Pad    PACKAGE = Object::Pad::MOP::Method

INCLUDE: mop-method.xsi

MODULE = Object::Pad    PACKAGE = Object::Pad::MOP::Field

INCLUDE: mop-field.xsi

MODULE = Object::Pad    PACKAGE = Object::Pad::MOP::FieldAttr

void
register(class, name, ...)
  SV *class
  SV *name
  CODE:
  {
    PERL_UNUSED_VAR(class);
    dKWARG(2);

    {
      if(!cophh_exists_pvs(CopHINTHASH_get(PL_curcop), "Object::Pad/experimental(custom_field_attr)", 0))
        Perl_ck_warner(aTHX_ packWARN(WARN_EXPERIMENTAL),
          "Object::Pad::MOP::FieldAttr is experimental and may be changed or removed without notice");
    }

    struct FieldHookFuncs *funcs;
    Newxz(funcs, 1, struct FieldHookFuncs);

    struct CustomFieldHookData *funcdata;
    Newxz(funcdata, 1, struct CustomFieldHookData);

    funcs->ver = OBJECTPAD_ABIVERSION;

    funcs->apply = &fieldhook_custom_apply;

    static const char *args[] = {
      "permit_hintkey",
      "apply",
      NULL,
    };
    while(KWARG_NEXT(args)) {
      switch(kwarg) {
        case 0: /* permit_hintkey */
          funcs->permit_hintkey = savepv(SvPV_nolen(kwval));
          break;

        case 1: /* apply */
          funcdata->apply_cb = newSVsv(kwval);
          break;
      }
    }

    register_field_attribute(savepv(SvPV_nolen(name)), funcs, funcdata);
  }

MODULE = Object::Pad    PACKAGE = Object::Pad::MetaFunctions

SV *
metaclass(SV *obj)
  CODE:
  {
    if(!SvROK(obj) || !SvOBJECT(SvRV(obj)))
      croak("Expected an object reference to metaclass");

    HV *stash = SvSTASH(SvRV(obj));

    GV **gvp = (GV **)hv_fetchs(stash, "META", 0);
    if(!gvp)
      croak("Unable to find ClassMeta for %" HEKf, HEKfARG(HvNAME_HEK(stash)));

    RETVAL = newSVsv(GvSV(*gvp));
  }
  OUTPUT:
    RETVAL

void
deconstruct_object(SV *obj)
  PPCODE:
  {
    if(!SvROK(obj) || !SvOBJECT(SvRV(obj)))
      croak("Expected an object reference to deconstruct_object");

    ClassMeta *classmeta = mop_get_class_for_stash(SvSTASH(SvRV(obj)));

    AV *backingav = (AV *)get_obj_backingav(obj, classmeta->repr, true);

    U32 retcount = 0;

    PUSHs(sv_mortalcopy(classmeta->name));
    retcount++;

    PUTBACK;

    while(classmeta) {
      retcount += deconstruct_object_class(backingav, classmeta, 0);

      AV *roles = classmeta->cls.direct_roles;
      U32 nroles = av_count(roles);
      for(U32 i = 0; i < nroles; i++) {
        RoleEmbedding *embedding = (RoleEmbedding *)AvARRAY(roles)[i];

        retcount += deconstruct_object_class(backingav, embedding->rolemeta, embedding->offset);
      }

      classmeta = classmeta->cls.supermeta;
    }

    SPAGAIN;
    XSRETURN(retcount);
  }

SV *
ref_field(SV *fieldname, SV *obj)
  CODE:
  {
    SV *want_classname = NULL, *want_fieldname;

    if(!SvROK(obj) || !SvOBJECT(SvRV(obj)))
      croak("Expected an object reference to ref_field");

    SvGETMAGIC(fieldname);

    char *s = SvPV_nolen(fieldname);
    char *dotpos;
    if((dotpos = strchr(s, '.'))) {
      U32 flags = SvUTF8(fieldname) ? SVf_UTF8 : 0;
      want_classname = newSVpvn_flags(s, dotpos - s, flags);
      want_fieldname = newSVpvn_flags(dotpos + 1, strlen(dotpos + 1), flags);
    }
    else {
      want_fieldname = SvREFCNT_inc(fieldname);
    }

    SAVEFREESV(want_classname);
    SAVEFREESV(want_fieldname);

    ClassMeta *classmeta = mop_get_class_for_stash(SvSTASH(SvRV(obj)));

    AV *backingav = (AV *)get_obj_backingav(obj, classmeta->repr, true);

    while(classmeta) {
      if(!want_classname || sv_eq(want_classname, classmeta->name)) {
        RETVAL = ref_field_class(want_fieldname, backingav, classmeta, 0);
        if(RETVAL)
          goto done;
      }

      AV *roles = classmeta->cls.direct_roles;
      U32 nroles = av_count(roles);
      for(U32 i = 0; i < nroles; i++) {
        RoleEmbedding *embedding = (RoleEmbedding *)AvARRAY(roles)[i];

        if(!want_classname || sv_eq(want_classname, embedding->rolemeta->name)) {
          RETVAL = ref_field_class(want_fieldname, backingav, embedding->rolemeta, embedding->offset);
          if(RETVAL)
            goto done;
        }
      }

      classmeta = classmeta->cls.supermeta;
    }

    if(want_classname)
      croak("Could not find a field called %" SVf " in class %" SVf,
        SVfARG(want_fieldname), SVfARG(want_classname));
    else
      croak("Could not find a field called %" SVf " in any class",
        SVfARG(want_fieldname));
done:
    ;
  }
  OUTPUT:
    RETVAL

BOOT:
  XopENTRY_set(&xop_methstart, xop_name, "methstart");
  XopENTRY_set(&xop_methstart, xop_desc, "enter method");
#ifdef METHSTART_CONTAINS_FIELD_BINDINGS
  XopENTRY_set(&xop_methstart, xop_class, OA_UNOP_AUX);
#else
  XopENTRY_set(&xop_methstart, xop_class, OA_BASEOP);
#endif
  Perl_custom_op_register(aTHX_ &pp_methstart, &xop_methstart);

  XopENTRY_set(&xop_commonmethstart, xop_name, "commonmethstart");
  XopENTRY_set(&xop_commonmethstart, xop_desc, "enter method :common");
  XopENTRY_set(&xop_commonmethstart, xop_class, OA_BASEOP);
  Perl_custom_op_register(aTHX_ &pp_commonmethstart, &xop_commonmethstart);

  XopENTRY_set(&xop_fieldpad, xop_name, "fieldpad");
  XopENTRY_set(&xop_fieldpad, xop_desc, "fieldpad()");
#ifdef HAVE_UNOP_AUX
  XopENTRY_set(&xop_fieldpad, xop_class, OA_UNOP_AUX);
#else
  XopENTRY_set(&xop_fieldpad, xop_class, OA_UNOP); /* technically a lie */
#endif
  Perl_custom_op_register(aTHX_ &pp_fieldpad, &xop_fieldpad);

  CvLVALUE_on(get_cv("Object::Pad::MOP::Field::value", 0));
#ifdef HAVE_DMD_HELPER
  DMD_SET_PACKAGE_HELPER("Object::Pad::MOP::Class", &dumppackage_class);
#endif

  boot_xs_parse_keyword(0.22); /* XPK_AUTOSEMI */

  register_xs_parse_keyword("class", &kwhooks_class, (void *)METATYPE_CLASS);
  register_xs_parse_keyword("role",  &kwhooks_role,  (void *)METATYPE_ROLE);

  register_xs_parse_keyword("field", &kwhooks_field, "field");
  register_xs_parse_keyword("has",   &kwhooks_has,   "has");

  register_xs_parse_keyword("BUILD",        &kwhooks_BUILD, (void *)PHASER_BUILD);
  register_xs_parse_keyword("ADJUST",       &kwhooks_ADJUST, (void *)PHASER_ADJUST);
  register_xs_parse_keyword("ADJUSTPARAMS", &kwhooks_ADJUST, (void *)PHASER_ADJUST);

  register_xs_parse_keyword("requires", &kwhooks_requires, NULL);

  boot_xs_parse_sublike(0.15); /* dynamic actions */

  register_xs_parse_sublike("method", &parse_method_hooks, (void *)PHASER_NONE);

  ObjectPad__boot_classes(aTHX);
  ObjectPad__boot_fields(aTHX);
