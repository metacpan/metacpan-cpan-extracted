/* vi: set ft=c : */

#ifdef G_USEHINTS
#  define compilerun_sv(sv, flags)  eval_sv(sv, flags|G_USEHINTS|G_RETHROW)
#else
#  define compilerun_sv(sv, flags)  S_compilerun_sv(aTHX_ sv, flags)
static void S_compilerun_sv(pTHX_ SV *sv, U32 flags)
{
  /* We can't call eval_sv() because it doesn't preserve the caller's hints
   * or features. We'll have to emulate it and do different things
   *   https://github.com/Perl/perl5/issues/21415
   */
  OP *o = newUNOP(OP_ENTEREVAL, G_SCALAR,
    newSVOP(OP_CONST, 0, SvREFCNT_inc(sv)));
  OP *start = LINKLIST(o);
  o->op_next = NULL;
#ifdef OPpEVAL_EVALSV
  o->op_private |= OPpEVAL_EVALSV;
#endif

  SAVEFREEOP(o);

  // Now just execute the ops in the list until the end
  SAVEVPTR(PL_op);
  PL_op = start;

#ifndef OPpEVAL_EVALSV
  /* Without OPpEVAL_EVALSV we can only detect compiler errors by
   * pp_entereval() returning NULL. We'll have to manually run the optree
   * until we see that to know
   */
  while(PL_op && PL_op->op_type != OP_ENTEREVAL)
    PL_op = (*PL_op->op_ppaddr)(aTHX);
  if(PL_op)
    PL_op = (*PL_op->op_ppaddr)(aTHX); // run the OP_ENTEREVAL
  if(!PL_op)
    croak_sv(ERRSV);
#endif
  CALLRUNOPS(aTHX);

#ifdef OPpEVAL_EVALSV
  dSP;
  if(!TOPs)
    croak_sv(ERRSV);
#endif
}
#endif
