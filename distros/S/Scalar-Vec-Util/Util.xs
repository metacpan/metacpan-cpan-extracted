/* This file is part of the Scalar::Vec::Util Perl module.
 * See http://search.cpan.org/dist/Scalar-Vec-Util/ */

#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#define __PACKAGE__     "Scalar::Vec::Util"
#define __PACKAGE_LEN__ (sizeof(__PACKAGE__)-1)

#include "bitvect.h"

STATIC size_t svu_validate_uv(pTHX_ SV *sv, const char *desc) {
#define svu_validate_uv(S, D) svu_validate_uv(aTHX_ (S), (D))
 IV i;

 if (SvOK(sv) && SvIOK(sv)) {
  if (SvIsUV(sv))
   return SvUVX(sv);
  else {
   i = SvIVX(sv);
   if (i >= 0)
    return i;
  }
 } else {
  i = SvIV(sv);
  if (i >= 0)
   return i;
 }

 croak("Invalid negative %s", desc ? desc : "integer");
 return 0;
}

STATIC char *svu_prepare_sv(pTHX_ SV *sv, size_t s, size_t l) {
#define svu_prepare_sv(S, I, L) svu_prepare_sv(aTHX_ (S), (I), (L))
 STRLEN  c;
 size_t  n = s + l, i, js, jz, k, z;
 char   *p;

 SvUPGRADE(sv, SVt_PV);

 p = SvGROW(sv, BV_SIZE(n));
 c = SvCUR(sv);

 js = (s / BITS(BV_UNIT)) * sizeof(BV_UNIT);
 k  = js + sizeof(BV_UNIT);
 for (i = c < js ? js : c; i < k; ++i)
  p[i] = 0;

 jz = ((s + l - 1) / BITS(BV_UNIT)) * sizeof(BV_UNIT);
 if (jz > js) {
  k = jz + sizeof(BV_UNIT);
  for (i = c < jz ? jz : c; i < k; ++i)
   p[i] = 0;
 }

 z = 1 + ((s + l - 1) / CHAR_BIT);
 if (c < z)
  SvCUR_set(sv, z);

 return p;
}

/* --- XS ------------------------------------------------------------------ */

MODULE = Scalar::Vec::Util              PACKAGE = Scalar::Vec::Util

PROTOTYPES: ENABLE

BOOT:
{
 HV *stash = gv_stashpvn(__PACKAGE__, __PACKAGE_LEN__, 1);
 newCONSTSUB(stash, "SVU_PP",   newSVuv(0));
 newCONSTSUB(stash, "SVU_SIZE", newSVuv(SVU_SIZE));
}

void
vfill(SV *sv, SV *ss, SV *sl, SV *sf)
PROTOTYPE: $$$$
PREINIT:
 size_t s, l;
 char f, *v;
CODE:
 l = svu_validate_uv(sl, "length");
 if (!l)
  XSRETURN(0);
 s = svu_validate_uv(ss, "offset");
 v = svu_prepare_sv(sv, s, l);
 f = SvTRUE(sf);

 bv_fill(v, s, l, f);

 XSRETURN(0);

void
vcopy(SV *sf, SV *sfs, SV *st, SV *sts, SV *sl)
PROTOTYPE: $$$$$
PREINIT:
 size_t fs, ts, l, e, lf, cf;
 char *vt, *vf;
CODE:
 l = svu_validate_uv(sl, "length");
 if (!l)
  XSRETURN(0);
 fs = svu_validate_uv(sfs, "offset");
 ts = svu_validate_uv(sts, "offset");

 SvUPGRADE(sf, SVt_PV);
 vt = svu_prepare_sv(st, ts, l);

 /* We fetch vf after upgrading st in case st == sf. */
 vf = SvPVX(sf);
 cf = SvCUR(sf) * CHAR_BIT;
 lf = fs + l;
 e  = lf > cf ? lf - cf : 0;
 l  =  l > e  ?  l - e  : 0;

 if (l) {
  if (vf == vt)
   bv_move(vf, ts, fs, l);
  else
   bv_copy(vt, ts, vf, fs, l);
 }

 if (e)
  bv_fill(vt, ts + l, e, 0);

 XSRETURN(0);

void
veq(SV *sv1, SV *ss1, SV *sv2, SV *ss2, SV *sl)
PROTOTYPE: $$$$$
PREINIT:
 size_t s1, s2, l, l1, l2, c1, c2, e1, e2, e;
 int    res = 1;
 char  *v1, *v2;
CODE:
 l = svu_validate_uv(sl, "length");
 if (!l)
  goto done;
 s1 = svu_validate_uv(ss1, "offset");
 s2 = svu_validate_uv(ss2, "offset");

 SvUPGRADE(sv1, SVt_PV);
 SvUPGRADE(sv2, SVt_PV);
 v1 = SvPVX(sv1);
 v2 = SvPVX(sv2);
 c1 = SvCUR(sv1) * CHAR_BIT;
 c2 = SvCUR(sv2) * CHAR_BIT;

 redo:
 l1 = s1 + l;
 l2 = s2 + l;
 e1 = l1 > c1 ? l1 - c1 : 0;
 e2 = l2 > c2 ? l2 - c2 : 0;
 e  = e1 > e2 ? e1 : e2;

 if (l > e) {
  size_t p = l - e;

  res = bv_eq(v1, s1, v2, s2, p);
  if (!res || e == 0)
   goto done;

  /* Bit vectors are equal up to p < l */
  s1 += p;
  s2 += p;
  l   = e;
  goto redo;
 }

 /* l <= max(e1, e2), at least one of the vectors is completely out of bounds */
 e = e1 < e2 ? e1 : e2;
 if (l > e) {
  size_t q = l - e;

  if (s1 < c1)
   res = bv_zero(v1, s1, q);
  else if (s2 < c2)
   res = bv_zero(v2, s2, q);
 }

 done:
 ST(0) = res ? &PL_sv_yes : &PL_sv_no;
 XSRETURN(1);
