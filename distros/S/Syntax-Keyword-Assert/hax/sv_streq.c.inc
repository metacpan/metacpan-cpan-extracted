/* vi: set ft=c : */
#ifndef sv_streq_flags
#  define sv_streq_flags(lhs, rhs, flags)  S_sv_streq_flags(aTHX_ lhs, rhs, flags)
static bool S_sv_streq_flags(pTHX_ SV *lhs, SV *rhs, U32 flags)
{
  if(flags & SV_GMAGIC) {
    if(lhs)
      SvGETMAGIC(lhs);
    if(rhs)
      SvGETMAGIC(rhs);
  }
  if(!lhs)
    lhs = &PL_sv_undef;
  if(!rhs)
    rhs = &PL_sv_undef;
  if(!(flags & SV_SKIP_OVERLOAD) && (SvAMAGIC(lhs) || SvAMAGIC(rhs))) {
    SV *ret = amagic_call(lhs, rhs, seq_amg, 0);
    if(ret)
      return SvTRUE(ret);
  }
  return sv_eq_flags(lhs, rhs, 0);
}
#endif
#ifndef sv_streq
#  define sv_streq(lhs, rhs)  sv_streq_flags(lhs, rhs, 0)
#endif
