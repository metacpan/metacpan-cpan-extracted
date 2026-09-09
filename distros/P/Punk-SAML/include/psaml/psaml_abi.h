#ifndef PSAML_ABI_H
#define PSAML_ABI_H

/* Resolvers for the three house C ABIs Punk::SAML builds on:
 *   frx_abi   (File::Raw::XML - the tree, by_id, the canonical form)
 *   jws_abi   (Crypt::JWS - signatures, digests, HMAC, CSPRNG, ct-eq,
 *              and the public key out of an X.509 certificate)
 *   fetch_abi (Fetch - the metadata request)
 *
 * Each is resolved lazily through the house _abi_ptr consumer pattern
 * and version-checked. All three are hard prerequisites, so a failure to
 * resolve is a boot-environment error and croaks by name.
 *
 * Punk itself is NOT here: pk_abi.h is an observer table with no
 * install_kw, so there is nothing to consume from it, and Punk is
 * reached by ordinary method dispatch the way Punk-Feed and
 * Punk-Challenge reach it. */

#include "frx_abi.h"
#include "jws_abi.h"
#include "fetch_abi.h"

/* The versions whose members this dist actually calls.
 *
 * These are compared with >=, never ==, and never against the installed
 * header's own constant. The table is append-only, so a provider newer
 * than this dist is always safe; an equality check would turn every
 * append into a breaking change for a consumer already shipped. And
 * comparing against the installed FRX_ABI_VERSION / JWS_ABI_VERSION
 * would mean that merely compiling against a newer provider raised the
 * runtime floor of code that touches nothing new in it.
 *
 * They are named constants rather than literals at the call sites so
 * that these numbers and the floors in Makefile.PL are two statements of
 * one fact, and can be checked against each other:
 *
 *   PSAML_FRX_NEED   2  parse, root, kind, ns, local, attr_value, find,
 *                       by_id, text, c14n, doc_free, and version 2's SV
 *                       bridge: doc_to_sv, doc_from_sv, node_from_sv,
 *                       node_to_sv. The bridge is what lets Response,
 *                       Signature and IdP hand a document or a verified
 *                       node to Perl, which is what makes them usable
 *                       with no application booted - and `punk saml
 *                       verify` against a saved Response is the reason
 *                       that requirement exists. File::Raw::XML 0.03 is
 *                       the first release with it; Punk 0.46 already
 *                       requires that release for the same four entries.
 *   PSAML_JWS_NEED   3  verify, sign, sha256, hmac_sha256, ct_eq,
 *                       random_bytes, key_from_pem, key_from_x509_der
 *   PSAML_FETCH_NEED 1  request
 *
 * Raise one only when a member from a later version is first called, and
 * raise the matching Makefile.PL floor in the same commit. */
#define PSAML_FRX_NEED   2
#define PSAML_JWS_NEED   3
#define PSAML_FETCH_NEED 1

/* A RESOLVER RUNS PERL. Each one below calls eval_pv for the require and
 * call_pv for the provider's _abi_ptr, and Perl code reallocates the
 * argument stack. So a resolver must never be called between an EXTEND
 * and its matching PUSH, and never with a local SP held across it: the
 * SP is stale the moment the call returns, and pushing through it writes
 * into freed memory. Resolve into a local first, SPAGAIN, then push.
 *
 * This is only a hazard on the first call, since each resolver caches.
 * That is what makes it worth writing down: it will not reproduce on the
 * second run of the same process, and a test that resolves before the
 * code under test will hide it entirely. */

static const frx_abi   *PSAML_FRX   = NULL;
static const jws_abi   *PSAML_JWS   = NULL;
static const fetch_abi *PSAML_FETCH = NULL;

static IV psaml_call_abi_ptr(pTHX_ const char *require_stmt, const char *fn) {
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

static const frx_abi *psaml_frx(pTHX) {
  if (!PSAML_FRX) {
    IV p = psaml_call_abi_ptr(aTHX_ "require File::Raw::XML;",
                              "File::Raw::XML::_abi_ptr");
    const frx_abi *a = p ? INT2PTR(const frx_abi *, p) : NULL;
    if (a && a->abi_version >= PSAML_FRX_NEED) PSAML_FRX = a;
  }
  if (!PSAML_FRX)
    croak("Punk::SAML: File::Raw::XML with a compatible C ABI is required "
          "(frx_abi version %d or newer)", PSAML_FRX_NEED);
  return PSAML_FRX;
}

static const jws_abi *psaml_jws(pTHX) {
  if (!PSAML_JWS) {
    IV p = psaml_call_abi_ptr(aTHX_ "require Crypt::JWS;",
                              "Crypt::JWS::_abi_ptr");
    const jws_abi *a = p ? INT2PTR(const jws_abi *, p) : NULL;
    if (a && a->version >= PSAML_JWS_NEED) PSAML_JWS = a;
  }
  if (!PSAML_JWS)
    croak("Punk::SAML: Crypt::JWS with a compatible C ABI is required "
          "(jws_abi version %d or newer, for key_from_x509_der)",
          PSAML_JWS_NEED);
  return PSAML_JWS;
}

static const fetch_abi *psaml_fetch(pTHX) {
  if (!PSAML_FETCH) {
    IV p = psaml_call_abi_ptr(aTHX_ "require Fetch;", "Fetch::_abi_ptr");
    const fetch_abi *a = p ? INT2PTR(const fetch_abi *, p) : NULL;
    if (a && a->abi_version >= PSAML_FETCH_NEED) PSAML_FETCH = a;
  }
  if (!PSAML_FETCH)
    croak("Punk::SAML: Fetch with a compatible C ABI is required "
          "(fetch_abi version %d or newer)", PSAML_FETCH_NEED);
  return PSAML_FETCH;
}

#endif /* PSAML_ABI_H */
