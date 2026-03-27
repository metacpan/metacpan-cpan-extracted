/* vi: set ft=c : */

/* Before perl 5.22 under -DDEBUGGING, various new*OP() functions throw assert
 * failures on OP_CUSTOM.
 *   https://rt.cpan.org/Ticket/Display.html?id=128562
 */

#define newOP_CUSTOM(func, flags)                    S_newOP_CUSTOM(aTHX_ func, flags)
#define newUNOP_CUSTOM(func, flags, first)           S_newUNOP_CUSTOM(aTHX_ func, flags, first)
#define newUNOP_AUX_CUSTOM(func, flags, first, aux)  S_newUNOP_AUX_CUSTOM(aTHX_ func, flags, first, aux)
#define newSVOP_CUSTOM(func, flags, sv)              S_newSVOP_CUSTOM(aTHX_ func, flags, sv)
#define newBINOP_CUSTOM(func, flags, first, last)    S_newBINOP_CUSTOM(aTHX_ func, flags, first, last)
#define newLISTOP_CUSTOM(func, flags, first, last)   S_newLISTOP_CUSTOM(aTHX_ func, flags, first, last)
#define newLOGOP_CUSTOM(func, flags, first, other)   S_newLOGOP_CUSTOM(aTHX_ func, flags, first, other)

static OP *S_newOP_CUSTOM(pTHX_ OP *(*func)(pTHX), U32 flags)
{
  OP *op = newOP(OP_CUSTOM, flags);
  op->op_ppaddr = func;
  return op;
}

static OP *S_newUNOP_CUSTOM(pTHX_ OP *(*func)(pTHX), U32 flags, OP *first)
{
  UNOP *unop;
  unop = (UNOP *)newUNOP(OP_CUSTOM, flags, first);
  unop->op_ppaddr = func;
  return (OP *)unop;
}

static OP *S_newUNOP_AUX_CUSTOM(pTHX_ OP *(*func)(pTHX), U32 flags, OP *first, UNOP_AUX_item *aux)
{
  UNOP_AUX *unop;
  unop = (UNOP_AUX *)newUNOP_AUX(OP_CUSTOM, flags, first, aux);
  unop->op_ppaddr = func;
  return (OP *)unop;
}

static OP *S_newSVOP_CUSTOM(pTHX_ OP *(*func)(pTHX), U32 flags, SV *sv)
{
  SVOP *svop;
  svop = (SVOP *)newSVOP(OP_CUSTOM, flags, sv);
  svop->op_ppaddr = func;
  return (OP *)svop;
}

static OP *S_newBINOP_CUSTOM(pTHX_ OP *(*func)(pTHX), U32 flags, OP *first, OP *last)
{
  BINOP *binop;
  binop = (BINOP *)newBINOP(OP_CUSTOM, flags, first, last);
  binop->op_ppaddr = func;
  return (OP *)binop;
}

static OP *S_newLISTOP_CUSTOM(pTHX_ OP *(*func)(pTHX), U32 flags, OP *first, OP *last)
{
  LISTOP *listop;
  listop = (LISTOP *)newLISTOP(OP_CUSTOM, flags, first, last);
  listop->op_ppaddr = func;
  return (OP *)listop;
}

static OP *S_newLOGOP_CUSTOM(pTHX_ OP *(*func)(pTHX), U32 flags, OP *first, OP *other)
{
  OP *o;
  o = newLOGOP(OP_CUSTOM, flags, first, other);

  /* the returned op is actually an UNOP that's either NULL or NOT; the real
   * logop is the op_next of it
   */
  cUNOPx(o)->op_first->op_ppaddr = func;

  return o;
}
