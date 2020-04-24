/* vi: set ft=c inde=: */

#ifndef av_count
#  define av_count(av)           (av_top_index(av) + 1)
#endif

#define save_strndup(s, l)  S_save_strndup(aTHX_ s, l)
static char *S_save_strndup(pTHX_ char *s, STRLEN l)
{
  /* savepvn doesn't put anything on the save stack, despite its name */
  char *ret = savepvn(s, l);
  SAVEFREEPV(ret);
  return ret;
}

#define sv_setrv(s, r)  S_sv_setrv(aTHX_ s, r)
static void S_sv_setrv(pTHX_ SV *sv, SV *rv)
{
  sv_setiv(sv, (IV)rv);
#if !HAVE_PERL_VERSION(5, 24, 0)
  SvIOK_off(sv);
#endif
  SvROK_on(sv);
}

static OP *newPADxVOP(I32 type, PADOFFSET padix, I32 flags, U32 private)
{
  OP *op = newOP(type, flags);
  op->op_targ = padix;
  op->op_private = private;
  return op;
}
