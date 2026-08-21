#ifndef POX_ABI_H
#define POX_ABI_H

/* Resolvers for the three house C ABIs Punk::OAuth2 builds on:
 * jws_abi (Crypt::JWS - signatures, digests, base64url, CSPRNG, ct-eq),
 * frj_abi (File::Raw::JSON - token and JWKS JSON), and fetch_abi (Fetch
 * - the HTTP calls). Each is resolved lazily via the house _abi_ptr
 * consumer pattern and version-checked; all three are hard prereqs, so
 * a failure is a boot-environment error. */

#include "jws_abi.h"
#include "frj_abi.h"
#include "fetch_abi.h"

static const jws_abi   *POX_JWS   = NULL;
static const frj_abi   *POX_FRJ   = NULL;
static const fetch_abi *POX_FETCH = NULL;

static IV pox_call_abi_ptr(pTHX_ const char *require_stmt, const char *fn) {
  dSP;
  int count;
  IV p = 0;
  eval_pv(require_stmt, FALSE);
  SPAGAIN;
  if (SvTRUE(ERRSV)) return 0;
  ENTER; SAVETMPS; PUSHMARK(SP); PUTBACK;
  count = call_pv(fn, G_SCALAR | G_EVAL);
  SPAGAIN;
  if (!SvTRUE(ERRSV) && count > 0) p = POPi;
  else if (count > 0)             (void)POPs;
  PUTBACK; FREETMPS; LEAVE;
  return p;
}

static const jws_abi *pox_jws(pTHX) {
  if (!POX_JWS) {
    IV p = pox_call_abi_ptr(aTHX_ "require Crypt::JWS;",
                            "Crypt::JWS::_abi_ptr");
    const jws_abi *a = p ? INT2PTR(const jws_abi *, p) : NULL;
    if (a && a->version == JWS_ABI_VERSION) POX_JWS = a;
  }
  if (!POX_JWS)
    croak("Punk::OAuth2: Crypt::JWS with a compatible C ABI is required "
          "(JWS_ABI_VERSION %d)", JWS_ABI_VERSION);
  return POX_JWS;
}

static const frj_abi *pox_frj(pTHX) {
  if (!POX_FRJ) {
    IV p = pox_call_abi_ptr(aTHX_ "require File::Raw::JSON;",
                            "File::Raw::JSON::_abi_ptr");
    const frj_abi *a = p ? INT2PTR(const frj_abi *, p) : NULL;
    if (a && a->abi_version >= FRJ_ABI_VERSION) POX_FRJ = a;
  }
  if (!POX_FRJ)
    croak("Punk::OAuth2: File::Raw::JSON with a compatible C ABI is "
          "required (FRJ_ABI_VERSION %d)", FRJ_ABI_VERSION);
  return POX_FRJ;
}

static const fetch_abi *pox_fetch(pTHX) {
  if (!POX_FETCH) {
    IV p = pox_call_abi_ptr(aTHX_ "require Fetch;", "Fetch::_abi_ptr");
    const fetch_abi *a = p ? INT2PTR(const fetch_abi *, p) : NULL;
    if (a && a->abi_version >= FETCH_ABI_VERSION) POX_FETCH = a;
  }
  if (!POX_FETCH)
    croak("Punk::OAuth2: Fetch with a compatible C ABI is required "
          "(FETCH_ABI_VERSION %d)", FETCH_ABI_VERSION);
  return POX_FETCH;
}

/* Small helpers over the jws primitives, returning mortal SVs. */

static SV *pox_b64url(pTHX_ const unsigned char *p, STRLEN n) {
  return sv_2mortal(pox_jws(aTHX)->b64url(aTHX_ p, n));
}
static SV *pox_sha256(pTHX_ const unsigned char *p, STRLEN n) {
  return sv_2mortal(pox_jws(aTHX)->sha256(aTHX_ p, n));
}
static SV *pox_random_b64(pTHX_ STRLEN n) {
  const jws_abi *J = pox_jws(aTHX);
  SV *raw = sv_2mortal(J->random_bytes(aTHX_ n));
  STRLEN rlen;
  const unsigned char *rp = (const unsigned char *)SvPVbyte(raw, rlen);
  return sv_2mortal(J->b64url(aTHX_ rp, rlen));
}
static int pox_ct_eq_sv(pTHX_ SV *a, SV *b) {
  STRLEN al, bl;
  const char *ap = SvPVbyte(a, al);
  const char *bp = SvPVbyte(b, bl);
  return pox_jws(aTHX)->ct_eq(aTHX_ (const unsigned char *)ap, al,
                              (const unsigned char *)bp, bl);
}

#endif
