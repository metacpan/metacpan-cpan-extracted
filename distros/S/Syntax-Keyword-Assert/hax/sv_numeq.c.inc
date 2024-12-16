/* vi: set ft=c : */
#ifndef sv_numeq_flags
#  define sv_numeq_flags(lhs, rhs, flags)  S_sv_numeq_flags(aTHX_ lhs, rhs, flags)
static bool S_sv_numeq_flags(pTHX_ SV *lhs, SV *rhs, U32 flags)
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
    SV *ret = amagic_call(lhs, rhs, eq_amg, 0);
    if(ret)
      return SvTRUE(ret);
  }
  /* We'd like to call Perl_do_ncmp, except that isn't an exported API function
   * Here's a near-copy of it for num-equality testing purposes */
#ifndef HAVE_BOOL_SvIV_please_nomg
  /* Before perl 5.18, SvIV_please_nomg() was void-returning */
  SvIV_please_nomg(lhs);
  SvIV_please_nomg(rhs);
#endif
  if(
#ifdef HAVE_BOOL_SvIV_please_nomg
    SvIV_please_nomg(rhs) && SvIV_please_nomg(lhs)
#else
    SvIOK(lhs) && SvIOK(rhs)
#endif
  ) {
    /* Compare as integers */
    switch((SvUOK(lhs) ? 1 : 0) | (SvUOK(rhs) ? 2 : 0)) {
      case 0: /* IV == IV */
        return SvIVX(lhs) == SvIVX(rhs);
      case 1: /* UV == IV */
      {
        const IV riv = SvUVX(rhs);
        if(riv < 0)
          return 0;
        return (SvUVX(lhs) == riv);
      }
      case 2: /* IV == UV */
      {
        const IV liv = SvUVX(lhs);
        if(liv < 0)
          return 0;
        return (liv == SvUVX(rhs));
      }
      case 3: /* UV == UV */
        return SvUVX(lhs) == SvUVX(rhs);
    }
  }
  else {
    /* Compare NVs */
    NV const rnv = SvNV_nomg(rhs);
    NV const lnv = SvNV_nomg(lhs);
    return lnv == rnv;
  }
}
#endif
#ifndef sv_numeq
#  define sv_numeq(lhs, rhs)  sv_numeq_flags(lhs, rhs, 0)
#endif
