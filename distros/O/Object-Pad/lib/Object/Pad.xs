/*  You may distribute under the terms of either the GNU General Public License
 *  or the Artistic License (the same terms as Perl itself)
 *
 *  (C) Paul Evans, 2019 -- leonerd@leonerd.org.uk
 */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#ifndef av_top_index
#define av_top_index(av)       AvFILL(av)
#endif

/* Not real API but this avoids so many off-by-one errors */
#ifndef av_count
#define av_count(av)           (av_top_index(av) + 1)
#endif

#ifndef block_end
#define block_end(a,b)         Perl_block_end(aTHX_ a,b)
#endif

#ifndef block_start
#define block_start(a)         Perl_block_start(aTHX_ a)
#endif

#ifndef intro_my
#define intro_my()             Perl_intro_my(aTHX)
#endif

#ifndef wrap_keyword_plugin
#  include "wrap_keyword_plugin.c.inc"
#endif

#define HAVE_PERL_VERSION(R, V, S) \
    (PERL_REVISION > (R) || (PERL_REVISION == (R) && (PERL_VERSION > (V) || (PERL_VERSION == (V) && (PERL_SUBVERSION >= (S))))))

#if HAVE_PERL_VERSION(5, 31, 3)
#  define HAVE_PARSE_SUBSIGNATURE
#elif HAVE_PERL_VERSION(5, 26, 0)
#  include "parse_subsignature.c.inc"
#  define HAVE_PARSE_SUBSIGNATURE
#endif

#include "lexer-additions.c.inc"

#ifndef OpSIBLING
#  define OpSIBLING(op)  (op->op_sibling)
#endif

#if HAVE_PERL_VERSION(5, 22, 0)
#  define HAVE_UNOP_AUX
#endif

#ifndef HAVE_UNOP_AUX
typedef struct {
  UNOP baseop;
  IV   iv;
} UNOP_with_IV;

#define newUNOP_with_IV(type, flags, first, iv)  MY_newUNOP_with_IV(aTHX_ type, flags, first, iv)
static OP *MY_newUNOP_with_IV(pTHX_ I32 type, I32 flags, OP *first, IV iv)
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

#define newMETHOD_REDIR_OP(rclass, methname, flags)  MY_newMETHOD_REDIR_OP(aTHX_ rclass, methname, flags)
static OP *MY_newMETHOD_REDIR_OP(pTHX_ SV *rclass, SV *methname, I32 flags)
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

#ifndef op_convert_list
#define op_convert_list(type, flags, o)  MY_op_convert_list(aTHX_ type, flags, o)
static OP *MY_op_convert_list(pTHX_ I32 type, I32 flags, OP *o)
{
  /* A minimal recreation just for our purposes */
  o->op_type = type;
  o->op_flags |= flags;
  o->op_ppaddr = PL_ppaddr[type];

  o = PL_check[type](aTHX_ o);

  return o;
}
#endif

/* A SLOTOFFSET is an offset within the AV of an object instance */
typedef IV SLOTOFFSET;

typedef struct {
  SV *name;
  OP *defaultop;
} SlotMeta;

/* Metadata about a class */
typedef struct {
  SLOTOFFSET offset;   /* first slot index of this partial within its instance */
  AV *slots;           /* each AV item is a raw pointer directly to a SlotMeta */
  enum {
    REPR_NATIVE,       /* instances are in native format - blessed AV as slots */
    REPR_FOREIGN_HASH, /* instances are blessed HASHes; our slots live in $self->{"Object::Pad/slots"} */
  } repr;
} ClassMeta;

/* The metadata on the currently-compiling class */
#ifdef MULTIPLICITY
#  define compclassmeta  \
    (*((ClassMeta **)hv_fetchs(PL_modglobal, "Object::Pad/compclassmeta", GV_ADD)))
#  define have_compclassmeta  \
    (!!hv_fetchs(PL_modglobal, "Object::Pad/compclassmeta", 0))
#else
/* without MULTIPLICITY there's only one, so we might as well just store it
 * in a static
 */
static ClassMeta *compclassmeta;
#define have_compclassmeta (!!compclassmeta)
#endif

/* Special pad indexes within `method` CVs */
enum {
  PADIX_SELF = 1,
  PADIX_SLOTS = 2,
};

static OP *newPADSVOP(PADOFFSET padix, I32 flags)
{
  OP *op = newOP(OP_PADSV, flags);
  op->op_targ = padix;
  return op;
}

static XOP xop_methstart;
static OP *pp_methstart(pTHX)
{
  SV *self = av_shift(GvAV(PL_defgv));
  SV *rv;
  HV *classstash = CvSTASH(find_runcv(0));

  if(!SvROK(self) || !SvOBJECT(rv = SvRV(self)))
    croak("Cannot invoke method on a non-instance");

  if(!sv_derived_from(self, HvNAME(classstash)))
    croak("Cannot invoke foreign method on non-derived instance");

  sv_setsv(PAD_SVl(PADIX_SELF), self);

  SV *slotsav;

  /* op_private contains the repr type so we can extract slots */
  switch(PL_op->op_private) {
    case REPR_NATIVE:
      if(SvTYPE(rv) != SVt_PVAV)
        croak("Not an ARRAY reference");
      slotsav = rv;
      break;

    case REPR_FOREIGN_HASH:
    {
      if(SvTYPE(rv) != SVt_PVHV)
        croak("Not a HASH reference");
      SV **slotssvp = hv_fetchs((HV *)rv, "Object::Pad/slots", 0);
      if(!slotssvp || !SvROK(*slotssvp) || SvTYPE(SvRV(*slotssvp)) != SVt_PVAV)
        croak("Expected $self->{\"Object::Pad/slots\"} to be an ARRAY reference");
      slotsav = SvRV(*slotssvp);
      break;
    }
  }

  PAD_SVl(PADIX_SLOTS) = slotsav;

  return PL_op->op_next;
}

static OP *newMETHSTARTOP(U8 private)
{
  OP *op = newOP(OP_CUSTOM, 0);
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

  AV *slotsav = (AV *)PAD_SV(PADIX_SLOTS);

  if(slotix > av_top_index(slotsav))
    croak("ARGH: instance does not have a slot at index %d", slotix);

  SV **slots = AvARRAY(slotsav);

  SV *slot = slots[slotix];

  if(PAD_SV(targ))
    SvREFCNT_dec(PAD_SV(targ));

  SV *val;
  switch(PL_op->op_private) {
    case OPpSLOTPAD_SV:
      val = slot;
      break;
    case OPpSLOTPAD_AV:
      if(!SvROK(slot) || SvTYPE(val = SvRV(slot)) != SVt_PVAV)
        croak("ARGH: expected to find an ARRAY reference at slot index %d", slotix);
      break;
    case OPpSLOTPAD_HV:
      if(!SvROK(slot) || SvTYPE(val = SvRV(slot)) != SVt_PVHV)
        croak("ARGH: expected to find a HASH reference at slot index %d", slotix);
      break;
    default:
      croak("ARGH: unsure what to do with this slot type");
  }

  PAD_SVl(targ) = SvREFCNT_inc(val);

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

#define import_pragma(pragma, arg)  MY_import_pragma(aTHX_ pragma, arg)
static void MY_import_pragma(pTHX_ const char *pragma, const char *arg)
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


#define get_class_isa(stash)  MY_get_class_isa(aTHX_ stash)
static AV *MY_get_class_isa(pTHX_ HV *stash)
{
  GV **gvp = (GV **)hv_fetchs(stash, "ISA", 0);
  if(!gvp || !GvAV(*gvp))
    croak("Expected %s to have a @ISA list", HvNAME(stash));

  return GvAV(*gvp);
}

#define generate_initslots_method(meta, stash)  MY_generate_initslots_method(aTHX_ meta, stash)
static void MY_generate_initslots_method(pTHX_ ClassMeta *meta, HV *stash)
{
  OP *ops = NULL;
  int i;

  I32 floor_ix = start_subparse(FALSE, 0);
  SAVEFREESV(PL_compcv);

  I32 save_ix = block_start(TRUE);

  /* A more optimised implementation of this method would be able to generate
   * a @self lexical and OP_REFASSIGN it, but that would only work on newer
   * perls. For now we'll take the small performance hit of RV2AV every time
   */

  PADOFFSET padix = pad_add_name_pvs("$self", 0, NULL, NULL);
  if(padix != PADIX_SELF)
    croak("ARGH: Expected that padix[$self] = 1");

  ops = op_append_list(OP_LINESEQ, ops,
    /* $self = shift */
    newBINOP(OP_SASSIGN, 0, newOP(OP_SHIFT, 0), newPADSVOP(PADIX_SELF, OPf_MOD)));

  intro_my();

  /* TODO: Icky horrible implementation; if our slotoffset > 0 then
   * we must be a subclass
   */
  if(meta->offset) {
    AV *isa = get_class_isa(stash);
    SV *superclass = AvARRAY(isa)[0];

    /* Build an OP_ENTERSUB for  $self->SUPER::INITSLOTS() */
    OP *op = NULL;
    op = op_append_list(OP_LIST, op,
      newPADSVOP(PADIX_SELF, 0));
    op = op_append_list(OP_LIST, op,
      newMETHOD_REDIR_OP(superclass, newSVpvn_share("INITSLOTS", 9, 0), 0));

    ops = op_append_list(OP_LINESEQ, ops,
      op_convert_list(OP_ENTERSUB, OPf_WANT_VOID|OPf_STACKED, op));
  }

  /* TODO: If in some sort of debug mode: insert equivalent of
   *   if((av_count(self)) != offset)
   *     croak("ARGH: Expected self to have %d slots by now\n", offset);
   */

  /* To make an OP_PUSH we have to build a generic OP_LIST then call
   * op_convert_list() on it later
   */
  OP *slotsavop;
  switch(meta->repr) {
    case REPR_NATIVE:
      /* $self->@* */
      slotsavop = newUNOP(OP_RV2AV, OPf_MOD|OPf_REF, newPADSVOP(PADIX_SELF, 0));
      break;
    case REPR_FOREIGN_HASH:
      /* $self->{"Object::Pad/slots"}->@* */
      slotsavop = newUNOP(OP_RV2AV, OPf_MOD|OPf_REF,
        newBINOP(OP_HELEM, OPf_MOD,
          newUNOP(OP_RV2HV, OPf_MOD|OPf_REF, newPADSVOP(PADIX_SELF, 0)),
          newSVOP(OP_CONST, 0, newSVpvs("Object::Pad/slots"))));
      break;
  }

  AV *slots = meta->slots;
  I32 nslots = av_count(slots);

  if(nslots) {
    OP *itemops = op_append_elem(OP_LIST, NULL, slotsavop);

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

    ops = op_append_list(OP_LINESEQ, ops,
      op_convert_list(OP_PUSH, OPf_WANT_VOID, itemops));
  }

  SvREFCNT_inc(PL_compcv);
  ops = block_end(save_ix, ops);

  newATTRSUB(floor_ix, newSVOP(OP_CONST, 0, newSVpvs("INITSLOTS")),
    NULL, NULL, ops);
}

static void late_generate_initslots(pTHX_ void *p)
{
  ClassMeta *meta = p;

  generate_initslots_method(meta, PL_curstash);
}


static int keyword_class(pTHX_ OP **op_ptr)
{
  lex_read_space(0);

  SV *packagename = lex_scan_packagename();
  if(!packagename)
    croak("Expected 'class' to be followed by package name");

  SV *superclassname = NULL;
  ClassMeta *supermeta = NULL;

  // TODO: This grammar is quite flexible; maybe too much?
  while(1) {
    lex_read_space(0);

    // TODO: Maybe accept `v1.23`

    if(lex_consume("extends")) {
      if(superclassname)
        croak("Multiple superclasses are not currently supported");

      lex_read_space(0);
      superclassname = lex_scan_packagename();

      /* TODO: look for a version of that package too */

      HV *superstash = gv_stashsv(superclassname, 0);
      if(!superstash || !hv_fetchs(superstash, "new", 0)) {
        /* Try to `require` the module then attempt a second time */
        /* load_module() will modify the name argument and take ownership of it */
        load_module(PERL_LOADMOD_NOIMPORT, newSVsv(superclassname), NULL, NULL);
        superstash = gv_stashsv(superclassname, 0);
      }

      if(!superstash)
        croak("Superclass %" SVf " does not exist", superclassname);

      GV **metagvp = (GV **)hv_fetchs(superstash, "META", 0);
      if(metagvp)
        supermeta = NUM2PTR(ClassMeta *, SvUV(GvSV(*metagvp)));
    }
    else
      break;
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
  import_pragma("-indirect", ":fatal");
#ifdef HAVE_PARSE_SUBSIGNATURE
  import_pragma("experimental", "signatures");
#endif

  if(have_compclassmeta) {
    SAVEVPTR(compclassmeta);
  }

  ClassMeta *meta;
  Newx(meta, 1, ClassMeta);
  compclassmeta = meta;

  meta->offset = 0;
  meta->slots  = newAV();
  meta->repr   = REPR_NATIVE;

  /* CARGOCULT from perl/op.c:Perl_package() */
  {
    SAVEGENERICSV(PL_curstash);
    save_item(PL_curstname);

    PL_curstash = (HV *)SvREFCNT_inc(gv_stashsv(packagename, GV_ADD));
    sv_setsv(PL_curstname, packagename);

    PL_hints |= HINT_BLOCK_SCOPE;
    PL_parser->copline = NOLINE;
  }

  AV *isa;
  {
    SV *isaname = newSVpvf("%" SVf "::ISA", PL_curstname);
    SAVEFREESV(isaname);

    isa = get_av(SvPV_nolen(isaname), GV_ADD | (SvUTF8(PL_curstash) ? SVf_UTF8 : 0));
  }

  if(superclassname)
    av_push(isa, superclassname);

  if(av_count(isa) > 0) {
    if(supermeta) {
      /* A subclass of an Object::Pad class */
      meta->offset = supermeta->offset + av_count(supermeta->slots);
      meta->repr = supermeta->repr;
    }
    else {
      /* A subclass of a foreign class - presume HASH for now */
      meta->repr = REPR_FOREIGN_HASH;
    }
  }

  {
    /* Inject the constructor */
    CV *newcv;
    switch(meta->repr) {
      case REPR_NATIVE:
        newcv = get_cv("Object::Pad::__new", 0);
        break;
      case REPR_FOREIGN_HASH:
        newcv = get_cv("Object::Pad::__new_foreign_HASH", 0);
        break;
    }

    GV *gv = gv_fetchpvs("new", GV_ADD, SVt_PVCV);
    GvMULTI_on(gv);

    SvREFCNT_inc((SV *)newcv);
    GvCV_set(gv, newcv);
  }

  {
    GV **gvp = (GV **)hv_fetchs(PL_curstash, "META", GV_ADD);
    GV *gv = *gvp;
    gv_init_pvn(gv, PL_curstash, "META", 4, 0);
    GvMULTI_on(gv);

    sv_setuv(GvSVn(gv), PTR2UV(meta));
  }

  if(is_block) {
    I32 save_ix = block_start(TRUE);
    OP *body = parse_stmtseq(0);
    body = block_end(save_ix, body);

    generate_initslots_method(meta, PL_curstash);

    if(!lex_consume("}"))
      croak("Expected }");

    LEAVE;

    /* CARGOCULT from perl/perly.y:PACKAGE BAREWORD BAREWORD '{' */
    /* a block is a loop that happens once */
    *op_ptr = newWHILEOP(0, 1, NULL, NULL, body, NULL, 0);
    return KEYWORD_PLUGIN_STMT;
  }
  else {
    SAVEDESTRUCTOR_X(&late_generate_initslots, meta);

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

  AV *slots = compclassmeta->slots;

  // TODO: Check for name collisions
  SlotMeta *slotmeta;
  Newx(slotmeta, 1, SlotMeta);

  slotmeta->name = name;
  slotmeta->defaultop = NULL;

  av_push(slots, (SV *)slotmeta);

  lex_read_space(0);

  if(lex_peek_unichar(0) == '=') {
    lex_read_unichar(0);
    lex_read_space(0);

    if(SvPV_nolen(name)[0] != '$')
      croak("Can only attach a default expression to a 'has' default");

    OP *op = parse_termexpr(0);

    if(!op || PL_parser->error_count)
      return 0;

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
  return KEYWORD_PLUGIN_STMT;
}

static int keyword_method(pTHX_ OP **op_ptr)
{
  if(!have_compclassmeta)
    croak("Cannot 'method' outside of 'class'");

  lex_read_space(0);
  SV *name = lex_scan_ident();
  lex_read_space(0);

  I32 floor_ix = start_subparse(FALSE, name ? 0 : CVf_ANON);
  SAVEFREESV(PL_compcv);

  OP *attrs = NULL;
  if(lex_peek_unichar(0) == ':') {
    lex_read_unichar(0);

    attrs = lex_scan_attrs(PL_compcv);
  }

  I32 save_ix = block_start(TRUE);

  OP *slotops = NULL;
  {
    PADOFFSET padix;

    padix = pad_add_name_pvs("$self", 0, NULL, NULL);
    if(padix != PADIX_SELF)
      croak("ARGH: Expected that padix[$self] = 1");

    /* Give it a name that isn't valid as a Perl variable so it can't collide */
    padix = pad_add_name_pvs("@(Object::Pad/slots)", 0, NULL, NULL);
    if(padix != PADIX_SLOTS)
      croak("ARGH: Expected that padix[@slots] = 2");

    slotops = op_append_list(OP_LINESEQ, slotops,
      newMETHSTARTOP(compclassmeta->repr)
    );

    AV *slots = compclassmeta->slots;
    SLOTOFFSET offset = compclassmeta->offset;
    int i;
    I32 nslots = av_count(slots);
    for(i = 0; i < nslots; i++) {
      SlotMeta *slotmeta = (SlotMeta *)AvARRAY(slots)[i];
      char sigil = SvPV_nolen(slotmeta->name)[0];

      padix = pad_add_name_sv(slotmeta->name, 0, NULL, NULL);
      SLOTOFFSET slotix = offset + i;

      U8 private;
      switch(sigil) {
        case '$': private = OPpSLOTPAD_SV; break;
        case '@': private = OPpSLOTPAD_AV; break;
        case '%': private = OPpSLOTPAD_HV; break;
      }

      slotops = op_append_list(OP_LINESEQ, slotops,
        /* alias the padix from the slot */
        newSLOTPADOP(0, private, padix, slotix));
    }

    intro_my();
  }

#ifdef HAVE_PARSE_SUBSIGNATURE
  OP *sigop = NULL;
  if(lex_peek_unichar(0) == '(') {
    lex_read_unichar(0);

    sigop = parse_subsignature(0);
    lex_read_space(0);

    if(PL_parser->error_count)
      return 0;

    if(lex_peek_unichar(0) != ')')
      croak("Expected ')'");
    lex_read_unichar(0);
    lex_read_space(0);
  }
#endif

  OP *body = parse_block(0);
  SvREFCNT_inc(PL_compcv);
  body = block_end(save_ix, body);

  if(PL_parser->error_count) {
    /* parse_block() still sometimes returns a valid body even if a parse
     * error happens.
     * We need to destroy this partial body before returning a valid(ish)
     * state to the keyword hook mechanism, so it will find the error count
     * correctly
     *   See https://rt.cpan.org/Ticket/Display.html?id=130417
     */
#ifdef HAVE_PARSE_SUBSIGNATURE
    if(sigop)
      op_free(sigop);
#endif
    op_free(body);
    *op_ptr = newOP(OP_NULL, 0);
    return name ? KEYWORD_PLUGIN_STMT : KEYWORD_PLUGIN_EXPR;
  }

#ifdef HAVE_PARSE_SUBSIGNATURE
  if(sigop)
    body = op_append_list(OP_LINESEQ, sigop, body);
#endif

  body = op_append_list(OP_LINESEQ, slotops, body);

  CV *cv = newATTRSUB(floor_ix,
    name ? newSVOP(OP_CONST, 0, SvREFCNT_inc(name)) : NULL,
    NULL,
    attrs,
    body);

  if(name) {
    *op_ptr = newOP(OP_NULL, 0);

    SvREFCNT_dec(name);
    return KEYWORD_PLUGIN_STMT;
  }
  else {
    *op_ptr = newUNOP(OP_REFGEN, 0,
      newSVOP(OP_ANONCODE, 0, (SV *)cv));

    return KEYWORD_PLUGIN_EXPR;
  }
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

  if(kwlen == 6 && strEQ(kw, "method") &&
      hv_fetchs(hints, "Object::Pad/method", 0))
    return keyword_method(aTHX_ op_ptr);

  return (*next_keyword_plugin)(aTHX_ kw, kwlen, op_ptr);
}

MODULE = Object::Pad    PACKAGE = Object::Pad

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

  wrap_keyword_plugin(&my_keyword_plugin, &next_keyword_plugin);
