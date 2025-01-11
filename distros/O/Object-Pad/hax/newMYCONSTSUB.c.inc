/* vi: set ft=c : */

#define newMYCONSTSUB(nameop, sv)  S_newMYCONSTSUB(aTHX_ nameop, sv)
static CV *S_newMYCONSTSUB(pTHX_ OP *nameop, SV *sv)
{
  I32 floor_ix = start_subparse(FALSE, 0);
  SvREFCNT_inc(PL_compcv);

  OP *protoop = newSVOP(OP_CONST, 0, newSVpvs(""));
  OP *body = newSVOP(OP_CONST, 0, SvREFCNT_inc(sv));
  CV *cv = newMYSUB(floor_ix, nameop, protoop, NULL, body);
  CvCONST_on(cv);

  return cv;
}

/* TODO: define a _named_pvn() variant that takes char*,STRLEN,U32 */

#define newMYCONSTSUB_named_sv(lexname, sv)  S_newMYCONSTSUB_named_sv(aTHX_ lexname, sv)
static CV *S_newMYCONSTSUB_named_sv(pTHX_ SV *lexname, SV *sv)
{
  /* Need to allocate pad name in the calling sub, before we start_subparse() */
  SV *ampname = newSVpvf("&%" SVf, SVfARG(lexname));
  SAVEFREESV(ampname);

  /* Strictly, nameop should be an OP_PADANY, but since newMYSUB() only cares
   * about o->op_targ and newPADxVOP() doesn't like OP_PADANY, we'll use an
   * OP_PADCV instead
   */
  return newMYCONSTSUB(
      newPADxVOP(OP_PADCV, 0, pad_add_name_sv(ampname, 0, NULL, NULL)),
      sv);
}
