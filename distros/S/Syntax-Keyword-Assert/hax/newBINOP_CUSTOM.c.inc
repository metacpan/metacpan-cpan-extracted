/* Before perl 5.22 under -DDEBUGGING, various new*OP() functions throw assert
 * failures on OP_CUSTOM.
 *   https://rt.cpan.org/Ticket/Display.html?id=128562
 *
 * Based on: https://metacpan.org/release/PEVANS/Syntax-Keyword-Try-0.31/source/hax/newOP_CUSTOM.c.inc
 */

#define newBINOP_CUSTOM(func, flags, first, last) S_newBINOP_CUSTOM(aTHX_ func, flags, first, last)
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
