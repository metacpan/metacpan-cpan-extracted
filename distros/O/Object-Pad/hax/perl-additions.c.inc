/* vi: set ft=c : */

#ifndef av_count
#  define av_count(av)           (AvFILL(av) + 1)
#endif

#if HAVE_PERL_VERSION(5, 22, 0)
#  define PadnameIsNULL(pn)  (!(pn))
#else
#  define PadnameIsNULL(pn)  (!(pn) || (pn) == &PL_sv_undef)
#endif

#ifndef hv_deletes
#  define hv_deletes(hv, skey, flags)  hv_delete((hv), ("" skey ""), (sizeof(skey) - 1), flags)
#endif

#if HAVE_PERL_VERSION(5, 22, 0)
#  define PadnameOUTER_off(pn)  (PadnameFLAGS(pn) &= ~PADNAMEt_OUTER)
#else
   /* PadnameOUTER is really the SvFAKE flag */
#  define PadnameOUTER_off(pn)  SvFAKE_off(pn)
#endif

#define save_strndup(s, l)  S_save_strndup(aTHX_ s, l)
static char *S_save_strndup(pTHX_ char *s, STRLEN l)
{
  /* savepvn doesn't put anything on the save stack, despite its name */
  char *ret = savepvn(s, l);
  SAVEFREEPV(ret);
  return ret;
}

#define sv_setrv(s, r)  S_sv_setrv(aTHX_ s, r)
static void S_sv_setrv(pTHX_ SV *sv, SV *rv)
{
  sv_setiv(sv, (IV)rv);
#if !HAVE_PERL_VERSION(5, 24, 0)
  SvIOK_off(sv);
#endif
  SvROK_on(sv);
}

#define newPADxVOP(type, padix, flags, private)  S_newPADxVOP(aTHX_ type, padix, flags, private)
static OP *S_newPADxVOP(pTHX_ I32 type, PADOFFSET padix, I32 flags, U32 private)
{
  OP *op = newOP(type, flags);
  op->op_targ = padix;
  op->op_private = private;
  return op;
}

/* Before perl 5.22 under -DDEBUGGING, various new*OP() functions throw assert
 * failures on OP_CUSTOM.
 *   https://rt.cpan.org/Ticket/Display.html?id=128562
 */

#define newOP_CUSTOM(func, flags)                   S_newOP_CUSTOM(aTHX_ func, flags)
#define newUNOP_CUSTOM(func, flags, first)          S_newUNOP_CUSTOM(aTHX_ func, flags, first)
#define newSVOP_CUSTOM(func, flags, sv)             S_newSVOP_CUSTOM(aTHX_ func, flags, sv)
#define newBINOP_CUSTOM(func, flags, first, last)   S_newBINOP_CUSTOM(aTHX_ func, flags, first, last)
#define newLOGOP_CUSTOM(func, flags, first, other)  S_newLOGOP_CUSTOM(aTHX_ func, flags, first, other)

static OP *S_newOP_CUSTOM(pTHX_ OP *(*func)(pTHX), U32 flags)
{
  OP *op = newOP(OP_CUSTOM, flags);
  op->op_ppaddr = func;
  return op;
}

static OP *S_newUNOP_CUSTOM(pTHX_ OP *(*func)(pTHX), U32 flags, OP *first)
{
  UNOP *unop;
#if HAVE_PERL_VERSION(5,22,0)
  unop = (UNOP *)newUNOP(OP_CUSTOM, flags, first);
#else
  NewOp(1101, unop, 1, UNOP);
  unop->op_type = (OPCODE)OP_CUSTOM;
  unop->op_first = first;
  unop->op_flags = (U8)(flags | OPf_KIDS);
  unop->op_private = (U8)(1 | (flags >> 8));
#endif
  unop->op_ppaddr = func;
  return (OP *)unop;
}

static OP *S_newSVOP_CUSTOM(pTHX_ OP *(*func)(pTHX), U32 flags, SV *sv)
{
  SVOP *svop;
#if HAVE_PERL_VERSION(5,22,0)
  svop = (SVOP *)newSVOP(OP_CUSTOM, flags, sv);
#else
  NewOp(1101, svop, 1, SVOP);
  svop->op_type = (OPCODE)OP_CUSTOM;
  svop->op_sv = sv;
  svop->op_next = (OP *)svop;
  svop->op_flags = 0;
  svop->op_private = 0;
#endif
  svop->op_ppaddr = func;
  return (OP *)svop;
}

static OP *S_newBINOP_CUSTOM(pTHX_ OP *(*func)(pTHX), U32 flags, OP *first, OP *last)
{
  BINOP *binop;
#if HAVE_PERL_VERSION(5,22,0)
  binop = (BINOP *)newBINOP(OP_CUSTOM, flags, first, last);
#else
  NewOp(1101, binop, 1, BINOP);
  binop->op_type = (OPCODE)OP_CUSTOM;
  binop->op_first = first;
  first->op_sibling = last;
  binop->op_last = last;
  binop->op_flags = (U8)(flags | OPf_KIDS);
  binop->op_private = (U8)(2 | (flags >> 8));
#endif
  binop->op_ppaddr = func;
  return (OP *)binop;
}

static OP *S_newLOGOP_CUSTOM(pTHX_ OP *(*func)(pTHX), U32 flags, OP *first, OP *other)
{
  OP *o;
#if HAVE_PERL_VERSION(5,22,0)
  o = newLOGOP(OP_CUSTOM, flags, first, other);
#else
  /* Parts of this code copypasted from perl 5.20.0's op.c S_new_logop()
   */
  LOGOP *logop;

  first = op_contextualize(first, G_SCALAR);

  NewOp(1101, logop, 1, LOGOP);

  logop->op_type = (OPCODE)OP_CUSTOM;
  logop->op_ppaddr = NULL; /* Because caller only overrides it anyway */
  logop->op_first = first;
  logop->op_flags = (U8)(flags | OPf_KIDS);
  logop->op_other = LINKLIST(other);
  /* logop->op_private has nothing interesting for OP_CUSTOM */

  /* Link in postfix order */
  logop->op_next = LINKLIST(first);
  first->op_next = (OP *)logop;
  first->op_sibling = other;

  /* No CHECKOP for OP_CUSTOM */
  o = newUNOP(OP_NULL, 0, (OP *)logop);
  other->op_next = o;
#endif

  /* the returned op is actually an UNOP that's either NULL or NOT; the real
   * logop is the op_next of it
   */
  cUNOPx(o)->op_first->op_ppaddr = func;

  return o;
}

static char *PL_savetype_name[] PERL_UNUSED_DECL = {
  /* These have been present since 5.16 */
  [SAVEt_ADELETE]             = "ADELETE",
  [SAVEt_AELEM]               = "AELEM",
  [SAVEt_ALLOC]               = "ALLOC",
  [SAVEt_APTR]                = "APTR",
  [SAVEt_AV]                  = "AV",
  [SAVEt_BOOL]                = "BOOL",
  [SAVEt_CLEARSV]             = "CLEARSV",
  [SAVEt_COMPILE_WARNINGS]    = "COMPILE_WARNINGS",
  [SAVEt_COMPPAD]             = "COMPPAD",
  [SAVEt_DELETE]              = "DELETE",
  [SAVEt_DESTRUCTOR]          = "DESTRUCTOR",
  [SAVEt_DESTRUCTOR_X]        = "DESTRUCTOR_X",
  [SAVEt_FREECOPHH]           = "FREECOPHH",
  [SAVEt_FREEOP]              = "FREEOP",
  [SAVEt_FREEPV]              = "FREEPV",
  [SAVEt_FREESV]              = "FREESV",
  [SAVEt_GENERIC_PVREF]       = "GENERIC_PVREF",
  [SAVEt_GENERIC_SVREF]       = "GENERIC_SVREF",
  [SAVEt_GP]                  = "GP",
  [SAVEt_GVSV]                = "GVSV",
  [SAVEt_HELEM]               = "HELEM",
  [SAVEt_HINTS]               = "HINTS",
  [SAVEt_HPTR]                = "HPTR",
  [SAVEt_HV]                  = "HV",
  [SAVEt_I16]                 = "I16",
  [SAVEt_I32]                 = "I32",
  [SAVEt_I32_SMALL]           = "I32_SMALL",
  [SAVEt_I8]                  = "I8",
  [SAVEt_INT]                 = "INT",
  [SAVEt_INT_SMALL]           = "INT_SMALL",
  [SAVEt_ITEM]                = "ITEM",
  [SAVEt_IV]                  = "IV",
  [SAVEt_LONG]                = "LONG",
  [SAVEt_MORTALIZESV]         = "MORTALIZESV",
  [SAVEt_NSTAB]               = "NSTAB",
  [SAVEt_OP]                  = "OP",
  [SAVEt_PADSV_AND_MORTALIZE] = "PADSV_AND_MORTALIZE",
  [SAVEt_PARSER]              = "PARSER",
  [SAVEt_PPTR]                = "PPTR",
  [SAVEt_REGCONTEXT]          = "REGCONTEXT",
  [SAVEt_SAVESWITCHSTACK]     = "SAVESWITCHSTACK",
  [SAVEt_SET_SVFLAGS]         = "SET_SVFLAGS",
  [SAVEt_SHARED_PVREF]        = "SHARED_PVREF",
  [SAVEt_SPTR]                = "SPTR",
  [SAVEt_STACK_POS]           = "STACK_POS",
  [SAVEt_SVREF]               = "SVREF",
  [SAVEt_SV]                  = "SV",
  [SAVEt_VPTR]                = "VPTR",

#if HAVE_PERL_VERSION(5,18,0)
  [SAVEt_CLEARPADRANGE]       = "CLEARPADRANGE",
  [SAVEt_GVSLOT]              = "GVSLOT",
#endif

#if HAVE_PERL_VERSION(5,20,0)
  [SAVEt_READONLY_OFF]        = "READONLY_OFF",
  [SAVEt_STRLEN]              = "STRLEN",
#endif

#if HAVE_PERL_VERSION(5,22,0)
  [SAVEt_FREEPADNAME]         = "FREEPADNAME",
#endif

#if HAVE_PERL_VERSION(5,24,0)
  [SAVEt_TMPSFLOOR]           = "TMPSFLOOR",
#endif

#if HAVE_PERL_VERSION(5,34,0)
  [SAVEt_STRLEN_SMALL]        = "STRLEN_SMALL",
  [SAVEt_HINTS_HH]            = "HINTS_HH",
#endif
};

#define dKWARG(count)      \
  U32 kwargi = count;      \
  U32 kwarg;               \
  SV *kwval;               \
  /* TODO: complain about odd number of args */

#define KWARG_NEXT(args) \
  S_kwarg_next(aTHX_ args, &kwargi, items, ax, &kwarg, &kwval)
static bool S_kwarg_next(pTHX_ const char *args[], U32 *kwargi, U32 argc, U32 ax, U32 *kwarg, SV **kwval)
{
  if(*kwargi >= argc)
    return FALSE;

  SV *argname = ST(*kwargi); (*kwargi)++;
  if(!SvOK(argname))
    croak("Expected string for next argument name, got undef");

  *kwarg = 0;
  while(args[*kwarg]) {
    if(strEQ(SvPV_nolen(argname), args[*kwarg])) {
      *kwval = ST(*kwargi); (*kwargi)++;
      return TRUE;
    }
    (*kwarg)++;
  }

  croak("Unrecognised argument name '%" SVf "'", SVfARG(argname));
}

#if HAVE_PERL_VERSION(5, 22, 0)
#  define HAVE_UNOP_AUX
#endif

#ifndef HAVE_UNOP_AUX
typedef struct UNOP_with_IV {
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
static OP *S_make_croak_op(pTHX_ SV *message)
{
#if HAVE_PERL_VERSION(5, 22, 0)
  sv_catpvs(message, " at %s line %d.\n");
  /* die sprintf($message, (caller)[1,2]) */
  return op_convert_list(OP_DIE, 0,
    op_convert_list(OP_SPRINTF, 0,
      op_append_list(OP_LIST,
        newSVOP(OP_CONST, 0, message),
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
  sv_catpvs(message, "\n");
  return newLISTOP(OP_DIE, 0, newOP(OP_PUSHMARK, 0),
    newSVOP(OP_CONST, 0, message));
#endif
}

#if HAVE_PERL_VERSION(5, 26, 0)
#  define HAVE_OP_ARGCHECK
#endif

#define make_argcheck_ops(required, optional, slurpy, subname)  S_make_argcheck_ops(aTHX_ required, optional, slurpy, subname)
static OP *S_make_argcheck_ops(pTHX_ int required, int optional, char slurpy, SV *subname)
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
    SV *message = newSVpvf("Too few arguments for subroutine '%" SVf "'", subname);
    /* @_ >= required or die ... */
    OP *checkop = 
      newSTATEOP(0, NULL,
        newLOGOP(OP_OR, 0,
          newBINOP(OP_GE, 0,
            /* scalar @_ */
            op_contextualize(newUNOP(OP_RV2AV, 0, newGVOP(OP_GV, 0, PL_defgv)), G_SCALAR),
            newSVOP(OP_CONST, 0, newSViv(required))),
          make_croak_op(message)));

    ret = op_append_list(OP_LINESEQ, ret, checkop);
  }

  {
    SV *message = newSVpvf("Too many arguments for subroutine '%" SVf "'", subname);
    /* @_ <= (required+optional) or die ... */
    OP *checkop =
      newSTATEOP(0, NULL,
        newLOGOP(OP_OR, 0,
          newBINOP(OP_LE, 0,
            /* scalar @_ */
            op_contextualize(newUNOP(OP_RV2AV, 0, newGVOP(OP_GV, 0, PL_defgv)), G_SCALAR),
            newSVOP(OP_CONST, 0, newSViv(required + optional))),
          make_croak_op(message)));

    ret = op_append_list(OP_LINESEQ, ret, checkop);
  }

  return ret;
#endif
}

#define lex_consume_unichar(c)  MY_lex_consume_unichar(aTHX_ c)
static bool MY_lex_consume_unichar(pTHX_ U32 c)
{
  if(lex_peek_unichar(0) != c)
    return FALSE;

  lex_read_unichar(0);
  return TRUE;
}
