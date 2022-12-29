/* vi: set ft=c : */

#define newHELEMEXISTSOROP(flags, helem, other)  S_newHELEMEXISTSOROP(aTHX_ flags, helem, other)

#if defined(OPpHELEMEXISTSOR_DELETE)
/* For now this is not in any Perl release but hopefully soon; maybe in time
 * for 5.37.7
 *    https://github.com/Perl/perl5/pull/20598
 */

static OP *S_newHELEMEXISTSOROP(pTHX_ U32 flags, OP *helem, OP *other)
{
  return newLOGOP(OP_HELEMEXISTSOR, flags, helem, other);
}

#else

enum {
  OPpHELEMEXISTSOR_DELETE = (1<<7),
};

static OP *pp_helemexistsor(pTHX)
{
  dSP;
  SV *keysv = POPs;
  HV *hv = MUTABLE_HV(POPs);
  bool is_delete = PL_op->op_private & OPpHELEMEXISTSOR_DELETE;

  assert(SvTYPE(hv) == SVt_PVHV);

  bool hv_is_magical = UNLIKELY(SvMAGICAL(hv));

  SV *val = NULL;

  /* For magical HVs we have to ensure we invoke the EXISTS method first. For
   * regular HVs we can just skip this and use the "pointer or NULL" result
   * of the real hv_* functions
   */
  if(hv_is_magical && !hv_exists_ent(hv, keysv, 0))
    goto other;

  if(is_delete) {
    val = hv_delete_ent(hv, keysv, 0, 0);
  }
  else {
    HE *he = hv_fetch_ent(hv, keysv, 0, 0);
    val = he ? HeVAL(he) : NULL;

    /* A magical HV hasn't yet actually invoked the FETCH method. We must ask
     * it to do so now
     */
    if(hv_is_magical && val)
      SvGETMAGIC(val);
  }

  if(!val) {
other:
    PUTBACK;
    return cLOGOP->op_other;
  }

  PUSHs(val);
  RETURN;
}

static OP *S_newHELEMEXISTSOROP(pTHX_ U32 flags, OP *helem, OP *other)
{
  assert(helem->op_type == OP_HELEM);

  OP *o = newLOGOP_CUSTOM(&pp_helemexistsor, flags, helem, other);

  OP *hvop = cBINOPx(helem)->op_first;
  OP *keyop = OpSIBLING(hvop);

  helem->op_targ = helem->op_type;
  helem->op_type = OP_NULL;
  helem->op_ppaddr = PL_ppaddr[OP_NULL];

  /* o is actually the structural-containing OP_NULL */
  OP *real_o = cUNOPo->op_first;

  keyop->op_next = real_o;

  return o;
}

#endif
