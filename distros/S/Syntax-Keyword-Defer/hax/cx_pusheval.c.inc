/* vi: set ft=c inde=: */

#ifndef cx_pusheval

#define cx_pusheval(cx, retop, n)  S_cx_pusheval(aTHX_ cx, retop, n)

static void S_cx_pusheval(pTHX_ PERL_CONTEXT *cx, OP *retop, SV *namesv)
{
  PUSHEVAL(cx, NULL);
  cx->blk_eval.retop = retop;
  if(namesv)
    cx->blk_eval.old_namesv = namesv;
}

#endif
