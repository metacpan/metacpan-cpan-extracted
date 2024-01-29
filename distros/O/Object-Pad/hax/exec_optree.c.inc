/* vi: set ft=c : */

#define exec_optree_list(o)  S_exec_optree_list(aTHX_ o)
static AV *S_exec_optree_list(pTHX_ OP *o)
{
  dSP;

  ENTER;
  SAVETMPS;

  SAVEVPTR(PL_op);

  PL_op = LINKLIST(o);
  o->op_next = NULL;

  PUSHMARK(SP);

  CALLRUNOPS(aTHX);

  SPAGAIN;
  I32 nargs = SP - PL_stack_base - TOPMARK;

  AV *ret = NULL;

  if(nargs) {
    SV **argsvs = SP - nargs + 1;
    ret = newAV_alloc_x(nargs);

    for(I32 i = 0; i < nargs; i++) {
      av_store_simple(ret, i, newSVsv(argsvs[i]));
    }
  }

  FREETMPS;
  LEAVE;

  return ret;
}
