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

static char *PL_savetype_name[] = {
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
