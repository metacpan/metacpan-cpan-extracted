/* This file is part of the Sub::Nary Perl module.
 * See http://search.cpan.org/dist/Sub::Nary/ */

#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#ifndef mPUSHi
# define mPUSHi(I) PUSHs(sv_2mortal(newSViv(I)))
#endif /* !mPUSHi */

typedef struct {
 UV k;
 NV v;
} sn_combcache;

STATIC U32 sn_hash_list = 0;

/* --- XS ------------------------------------------------------------------ */

MODULE = Sub::Nary            PACKAGE = Sub::Nary

PROTOTYPES: ENABLE

BOOT:
{
 PERL_HASH(sn_hash_list, "list", 4);
}

void
tag(SV *op)
PROTOTYPE: $
CODE:
 ST(0) = sv_2mortal(newSVuv(SvUV(SvRV(op))));
 XSRETURN(1);

void
null(SV *op)
PROTOTYPE: $
PREINIT:
 OP *o;
CODE:
 o = INT2PTR(OP *, SvUV(SvRV(op)));
 ST(0) = sv_2mortal(newSVuv(o == NULL));
 XSRETURN(1);

void
zero(SV *sv)
PROTOTYPE: $
PREINIT:
 HV *hv;
 IV res;
CODE:
 if (!SvOK(sv))
  XSRETURN_IV(1);
 if (!SvROK(sv)) {
  res = SvNOK(sv) ? SvNV(sv) == 0.0 : SvUV(sv) == 0;
  XSRETURN_IV(res);
 }
 hv = (HV *) SvRV(sv);
 res = hv_iterinit(hv) == 1 && hv_exists(hv, "0", 1);
 XSRETURN_IV(res);

void
count(SV *sv)
PROTOTYPE: $
PREINIT:
 HV *hv;
 HE *key;
 NV c = 0;
CODE:
 if (!SvOK(sv))
  XSRETURN_IV(0);
 if (!SvROK(sv))
  XSRETURN_IV(1);
 hv = (HV *) SvRV(sv);
 hv_iterinit(hv);
 while (key = hv_iternext(hv)) {
  c += SvNV(HeVAL(key));
 }
 XSRETURN_NV(c);

void
normalize(SV *sv)
PROTOTYPE: $
PREINIT:
 HV *hv, *res;
 HE *key;
 SV *val;
 NV c = 0;
CODE:
 if (!SvOK(sv))
  XSRETURN_UNDEF;
 res = newHV();
 if (!SvROK(sv)) {
  val = newSVuv(1);
  if (!hv_store_ent(res, sv, val, 0))
   SvREFCNT_dec(val);
 } else {
  hv = (HV *) SvRV(sv);
  if (!hv_iterinit(hv)) {
   val = newSVuv(1);
   if (!hv_store(res, "0", 1, val, 0))
    SvREFCNT_dec(val);
  } else {
   while (key = hv_iternext(hv)) {
    c += SvNV(HeVAL(key));
   }
   hv_iterinit(hv);
   while (key = hv_iternext(hv)) {
    val = newSVnv(SvNV(HeVAL(key)) / c);
    if (!hv_store_ent(res, HeSVKEY_force(key), val, HeHASH(key)))
     SvREFCNT_dec(val);
   }
  }
 }
 ST(0) = sv_2mortal(newRV_noinc((SV *) res));
 XSRETURN(1);

void
scale(SV *csv, SV *sv)
PROTOTYPE: $;$
PREINIT:
 HV *hv, *res;
 HE *key;
 SV *val;
 NV c = 1;
CODE:
 if (!SvOK(sv))
  XSRETURN_UNDEF;
 if (SvOK(csv))
  c = SvNV(csv);
 res = newHV();
 if (!SvROK(sv)) {
  val = newSVnv(c);
  if (!hv_store_ent(res, sv, val, 0))
   SvREFCNT_dec(val);
 } else {
  hv = (HV *) SvRV(sv);
  if (!hv_iterinit(hv)) {
   val = newSVnv(c);
   if (!hv_store(res, "0", 1, val, 0))
    SvREFCNT_dec(val);
  } else {
   hv_iterinit(hv);
   while (key = hv_iternext(hv)) {
    val = newSVnv(SvNV(HeVAL(key)) * c);
    if (!hv_store_ent(res, HeSVKEY_force(key), val, HeHASH(key)))
     SvREFCNT_dec(val);
   }
  }
 }
 ST(0) = sv_2mortal(newRV_noinc((SV *) res));
 XSRETURN(1);

void
add(...)
PROTOTYPE: @
PREINIT:
 HV *res;
 SV *cur, *val;
 HE *key, *old;
 I32 i;
CODE:
 if (!items)
  XSRETURN_UNDEF;
 res = newHV();
 for (i = 0; i < items; ++i) {
  cur = ST(i);
  if (!SvOK(cur))
   continue;
  if (!SvROK(cur)) {
   if (strEQ(SvPV_nolen(cur), "list")) {
    hv_clear(res);
    val = newSVuv(1);
    if (!hv_store(res, "list", 4, val, sn_hash_list))
     SvREFCNT_dec(val);
    break;
   } else {
    NV v = 1;
    if ((old = hv_fetch_ent(res, cur, 1, 0)) && SvOK(val = HeVAL(old)))
     v += SvNV(val);
    val = newSVnv(v);
    if (!hv_store_ent(res, cur, val, 0))
     SvREFCNT_dec(val);
    continue;
   }
  }
  cur = SvRV(cur);
  hv_iterinit((HV *) cur);
  while (key = hv_iternext((HV *) cur)) {
   SV *k = HeSVKEY_force(key);
   NV  v = SvNV(HeVAL(key));
   if ((old = hv_fetch_ent(res, k, 1, 0)) && SvOK(val = HeVAL(old)))
    v += SvNV(val);
   val = newSVnv(v);
   if (!hv_store_ent(res, k, val, 0))
    SvREFCNT_dec(val);
  }
 }
 if (!hv_iterinit(res)) {
  SvREFCNT_dec(res);
  XSRETURN_UNDEF;
 }
 ST(0) = sv_2mortal(newRV_noinc((SV *) res));
 XSRETURN(1);

void
cumulate(SV *sv, SV *nsv, SV *csv)
PROTOTYPE: $$$
PREINIT:
 HV *res;
 SV *val;
 HE *key;
 NV c0, c, a;
 UV i, n;
CODE:
 if (!SvOK(sv))
  XSRETURN_UNDEF;
 n  = SvUV(nsv);
 c0 = SvNV(csv);
 if (!n) {
  ST(0) = sv_2mortal(newSVuv(0));
  XSRETURN(1);
 }
 if (!SvROK(sv) || !c0) {
  ST(0) = sv;
  XSRETURN(1);
 }
 sv = SvRV(sv);
 if (!hv_iterinit((HV *) sv))
  XSRETURN_UNDEF;
 c = 1;
 a = c0;
 for (; n > 0; n /= 2) {
  if (n % 2)
   c *= a;
  a *= a;
 }
 c = (1 - c) / (1 - c0);
 res = newHV();
 while (key = hv_iternext((HV *) sv)) {
  SV *k = HeSVKEY_force(key);
  val = newSVnv(c * SvNV(HeVAL(key)));
  if (!hv_store_ent(res, k, val, 0))
   SvREFCNT_dec(val);
 }
 ST(0) = sv_2mortal(newRV_noinc((SV *) res));
 XSRETURN(1);

void
combine(...)
PROTOTYPE: @
PREINIT:
 HV *res[2];
 SV *cur, *val;
 SV *list1, *list2;
 SV *temp;
 HE *key, *old;
 I32 i;
 I32 n = 0, o;
 I32 j, n1, n2;
 UV shift = 0, do_shift = 0;
 sn_combcache *cache = NULL;
 I32 cachelen = 0;
CODE:
 if (!items)
  XSRETURN_UNDEF;
 res[0] = res[1] = NULL;
 for (i = 0; i < items; ++i) {
  cur = ST(i);
  if (!SvOK(cur)) 
   continue;
  if (!SvROK(cur)) {
   if (strEQ(SvPV_nolen(cur), "list")) {
    res[0] = newHV();
    n      = 0;
    val    = newSVuv(1);
    if (!hv_store(res[0], "list", 4, val, sn_hash_list))
     SvREFCNT_dec(val);
    i = items;
    if (!shift)
     do_shift = 0;
    break;
   } else {
    shift += SvUV(cur);
    do_shift = 1;
    continue;
   }
  }
  cur    = SvRV(cur);
  res[0] = newHV();
  while (key = hv_iternext((HV *) cur)) {
   val = newSVsv(HeVAL(key));
   if (!hv_store_ent(res[0], HeSVKEY_force(key), val, 0))
    SvREFCNT_dec(val);
  }
  n = 0;
  if (!shift)
   do_shift = 0;
  break;
 }
 temp = sv_2mortal(newSViv(0));
 for (++i; i < items; ++i) {
  cur = ST(i);
  if (!SvOK(cur))
   continue;
  if (!SvROK(cur)) {
   if (strEQ(SvPV_nolen(cur), "list")) {
    hv_clear(res[n]);
    val = newSVuv(1);
    if (!hv_store(res[n], "list", 4, val, sn_hash_list))
     SvREFCNT_dec(val);
    shift = 0;
    do_shift = 0;
    break;
   } else {
    shift += SvUV(cur);
    continue;
   }
  }
  cur = SvRV(cur);
  o   = 1 - n;
  if (!res[o])
   res[o] = newHV();
  else
   hv_clear(res[o]);
  list1 = hv_delete((HV *) cur, "list", 4, 0);
  n1    = hv_iterinit((HV *) cur);
  list2 = hv_delete(res[n],     "list", 4, 0);
  n2    = hv_iterinit(res[n]);
  if ((list1 && !n1) || (list2 && !n2)) {
   val = newSViv(1);
   if (!hv_store(res[o], "list", 4, val, sn_hash_list))
    SvREFCNT_dec(val);
   n = o;
   break;
  } else if (list1 || list2) {
   NV l1 = list1 ? SvNV(list1) : 0;
   NV l2 = list2 ? SvNV(list2) : 0;
   val = newSVnv(l1 + l2 - l1 * l2);
   if (!hv_store(res[o], "list", 4, val, sn_hash_list))
    SvREFCNT_dec(val);
  }
  if (n2 > cachelen) {
   Renew(cache, n2, sn_combcache);
   cachelen = n2;
  }
  j = 0;
  while (key = hv_iternext(res[n])) {
   cache[j].k = SvUV(HeSVKEY_force(key));
   cache[j].v = SvNV(HeVAL(key));
   ++j;
  }
  while (key = hv_iternext((HV *) cur)) {
   IV k = SvUV(HeSVKEY_force(key));
   NV v = SvNV(HeVAL(key));
   for (j = 0; j < n2; ++j) {
    sv_setiv(temp, k + cache[j].k);
    if ((old = hv_fetch_ent(res[o], temp, 1, 0)) && SvOK(val = HeVAL(old))) {
     val = newSVnv(SvNV(val) + v * cache[j].v);
    } else {
     val = newSVnv(v * cache[j].v);
    }
    if (!hv_store_ent(res[o], temp, val, 0))
     SvREFCNT_dec(val);
   }
  }
  n = o;
 }
 Safefree(cache);
 if (shift || do_shift) {
  if (!res[n]) {
   res[n] = newHV();
   sv_setiv(temp, shift);
   val = newSViv(1);
   if (!hv_store_ent(res[n], temp, val, 0))
    SvREFCNT_dec(val);
  } else {
   o = 1 - n;
   if (!res[o])
    res[o] = newHV();
   else
    hv_clear(res[o]);
   list1 = hv_delete(res[n], "list", 4, 0);
   hv_iterinit(res[n]);
   while (key = hv_iternext(res[n])) {
    sv_setiv(temp, SvUV(HeSVKEY_force(key)) + shift);
    val = newSVsv(HeVAL(key));
    if (!hv_store_ent(res[o], temp, val, 0))
     SvREFCNT_dec(val);
   }
   if (list1) {
    val = newSVsv(list1);
    if (!hv_store(res[o], "list", 4, val, sn_hash_list))
     SvREFCNT_dec(val);
   }
   n = o;
  }
 } else if (!res[0] && !res[1])
  XSRETURN_UNDEF;
 if (n == 1)
  SvREFCNT_dec(res[0]);
 else if (res[1]) 
  SvREFCNT_dec(res[1]);
 ST(0) = sv_2mortal(newRV_noinc((SV *) res[n]));
 XSRETURN(1);

void
scalops()
PROTOTYPE:
PREINIT:
 U32 cxt;
 int i, count = 0;
CODE:
 cxt = GIMME_V;
 if (cxt == G_SCALAR) {
  for (i = 0; i < OP_max; ++i) {
   count += (PL_opargs[i] & (OA_RETSCALAR | OA_RETINTEGER)) != 0;
  }
  EXTEND(SP, 1);
  mPUSHi(count);
  XSRETURN(1);
 } else if (cxt == G_ARRAY) {
  for (i = 0; i < OP_max; ++i) {
   if (PL_opargs[i] & (OA_RETSCALAR | OA_RETINTEGER)) {
    const char *name = PL_op_name[i];
    XPUSHs(sv_2mortal(newSVpvn_share(name, strlen(name), 0)));
    ++count;
   }
  }
  XSRETURN(count);
 }

