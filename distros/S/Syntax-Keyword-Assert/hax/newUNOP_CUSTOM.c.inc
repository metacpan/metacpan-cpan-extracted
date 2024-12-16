/* Before perl 5.22 under -DDEBUGGING, various new*OP() functions throw assert
 * failures on OP_CUSTOM.
 *   https://rt.cpan.org/Ticket/Display.html?id=128562
 */

#define newUNOP_CUSTOM(func, flags, first) S_newUNOP_CUSTOM(aTHX_ func, flags, first)
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

