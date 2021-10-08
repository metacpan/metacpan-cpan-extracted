/* vi: set ft=c : */

#include "op_sibling_splice.c.inc"

/* force_list_keeping_pushmark nulls out the OP_LIST itself but preserves
 * the OP_PUSHMARK inside it. This is essential or else op_contextualize()
 * will null out both of them and we lose the mark
 */
/* copypasta from core's op.c */
#define force_list_keeping_pushmark(o)  S_force_list_keeping_pushmark(aTHX_ o)
static OP *S_force_list_keeping_pushmark(pTHX_ OP *o)
{
  if(!o || o->op_type != OP_LIST) {
    OP *rest = NULL;
    if(o) {
      rest = OpSIBLING(o);
      OpLASTSIB_set(o, NULL);
    }
    o = newLISTOP(OP_LIST, 0, o, NULL);
    if(rest)
      op_sibling_splice(o, cLISTOPo->op_last, 0, rest);
  }
  op_null(o);
  return op_contextualize(o, G_LIST);
}
