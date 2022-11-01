/* vi: set ft=c : */

struct binop_any {
  BASEOP
  OP *op_first;
  OP *op_last;
  ANY *op_any;
};

typedef struct binop_any BINOP_ANY;

#define cBINOP_ANYx(o)  ((BINOP_ANY *)o)
#define cBINOP_ANY      cBINOP_ANYx(PL_op)
#define cBINOP_ANYo     cBINOP_ANYx(o)

#ifndef OpTYPE_set
#  define OpTYPE_set(op, type)         \
    STMT_START {                       \
      op->op_type   = (OPCODE)type;    \
      op->op_ppaddr = PL_ppaddr[type]; \
    } STMT_END
#endif

#define newBINOP_ANY(type, flags, first, last, anycount)  S_newBINOP_ANY(aTHX_ type, flags, first, last, anycount)
static OP *S_newBINOP_ANY(pTHX_ I32 type, I32 flags, OP *first, OP *last, Size_t anycount)
{
  dVAR;
  BINOP_ANY *binop;
  OP *kid = first;
  NewOp(1101, binop, 1, BINOP_ANY);

  if(!first)
    first = newOP(OP_NULL, 0);

  OpTYPE_set(binop, type);
  binop->op_first = first;
  binop->op_flags = (U8)(flags | OPf_KIDS);
  if(!last) {
    last = first;
    binop->op_private = (U8)(1 | (flags >> 8));
  }
  else {
    binop->op_private = (U8)(2 | (flags >> 8));
    OpMORESIB_set(first, last);
  }

  if(!OpHAS_SIBLING(last))
    OpLASTSIB_set(last, (OP *)binop);

  binop->op_last = OpSIBLING(binop->op_first);
  if(binop->op_last)
    OpLASTSIB_set(binop->op_last, (OP *)binop);

  Newx(binop->op_any, anycount, ANY);

  return (OP *)binop;
}


#define newBINOP_ANY_CUSTOM(func, flags, first, last, anycount)  S_newBINOP_ANY_CUSTOM(aTHX_ func, flags, first, last, anycount)
static OP *S_newBINOP_ANY_CUSTOM(pTHX_ OP *(*func)(pTHX), U32 flags, OP *first, OP *last, Size_t anycount)
{
  BINOP_ANY *binop;
  binop = (BINOP_ANY *)newBINOP_ANY(OP_CUSTOM, flags, first, last, anycount);
  binop->op_ppaddr = func;
  return (OP *)binop;
}
