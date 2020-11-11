/* vi: set ft=c inde=: */

#ifndef av_count
#  define av_count(av)           (AvFILL(av) + 1)
#endif

#if HAVE_PERL_VERSION(5, 22, 0)
#  define PadnameIsNULL(pn)  (!(pn))
#else
#  define PadnameIsNULL(pn)  (!(pn) || (pn) == &PL_sv_undef)
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

static OP *newPADxVOP(I32 type, PADOFFSET padix, I32 flags, U32 private)
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

#if HAVE_PERL_VERSION(5,22,0)
#  define newLOGOP_CUSTOM(flags, first, other)  newLOGOP(OP_CUSTOM, flags, first, other)
#  define newSVOP_CUSTOM(flags, sv)             newSVOP(OP_CUSTOM, flags, sv)
#  define newUNOP_CUSTOM(flags, first)          newUNOP(OP_CUSTOM, flags, first)
#  define newBINOP_CUSTOM(flags, first, last)  newBINOP(OP_CUSTOM, flags, first, last)
#else
#  define newLOGOP_CUSTOM(flags, first, other)  S_newLOGOP_CUSTOM(aTHX_ flags, first, other)
#  define newSVOP_CUSTOM(flags, sv)             S_newSVOP_CUSTOM(aTHX_ flags, sv)
#  define newUNOP_CUSTOM(flags, first)          S_newUNOP_CUSTOM(aTHX_ flags, first)
#  define newBINOP_CUSTOM(flags, first, last)  S_newBINOP_CUSTOM(aTHX_ flags, first, last)

static OP *S_newLOGOP_CUSTOM(pTHX_ U32 flags, OP *first, OP *other)
{
  /* Parts of this code copypasted from perl 5.20.0's op.c S_new_logop()
   */
  LOGOP *logop;
  OP *o;

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

  return o;
}

static OP *S_newSVOP_CUSTOM(pTHX_ U32 flags, SV *sv)
{
  SVOP *svop;
  NewOp(1101, svop, 1, SVOP);
  svop->op_type = (OPCODE)OP_CUSTOM;
  svop->op_ppaddr = NULL; /* Because caller only overrides it anyway */
  svop->op_sv = sv;
  svop->op_next = (OP *)svop;
  svop->op_flags = 0;
  svop->op_private = 0;
  return (OP *)svop;
}

static OP *S_newUNOP_CUSTOM(pTHX_ U32 flags, OP *first)
{
  UNOP *unop;
  NewOp(1101, unop, 1, UNOP);
  unop->op_type = (OPCODE)OP_CUSTOM;
  unop->op_ppaddr = NULL; /* Because caller only overrides it anyway */
  unop->op_first = first;
  unop->op_flags = (U8)(flags | OPf_KIDS);
  unop->op_private = (U8)(1 | (flags >> 8));
  return (OP *)unop;
}

static OP *S_newBINOP_CUSTOM(pTHX_ U32 flags, OP *first, OP *last)
{
  BINOP *binop;
  NewOp(1101, binop, 1, BINOP);
  binop->op_type = (OPCODE)OP_CUSTOM;
  binop->op_ppaddr = NULL; /* Because caller only overrides it anyway */
  binop->op_first = first;
  first->op_sibling = last;
  binop->op_last = last;
  binop->op_flags = (U8)(flags | OPf_KIDS);
  binop->op_private = (U8)(2 | (flags >> 8));
  return (OP *)binop;
}
#endif
