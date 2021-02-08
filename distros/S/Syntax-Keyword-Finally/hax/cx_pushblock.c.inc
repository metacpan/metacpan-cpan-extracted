/* vi: set ft=c inde=: */

#ifndef cx_pushblock

#define cx_pushblock(t, gimme, sp, saveix)  S_cx_pushblock(aTHX_ t, gimme, sp, saveix)

static PERL_CONTEXT *S_cx_pushblock(pTHX_ U32 t, U8 gimme, SV **sp, I32 saveix)
{
  PERL_CONTEXT *cx;
  assert(saveix == PL_savestack_ix);

  PUSHBLOCK(cx, t, sp);
  return cx;
}

#endif
