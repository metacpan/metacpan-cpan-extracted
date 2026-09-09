#ifndef PSAML_ERROR_H
#define PSAML_ERROR_H

/* Every refusal in this dist throws a blessed Punk::SAML::Error with a
 * `code` and a `message`.
 *
 * The code is the interface. The route logs it, the tests assert on it,
 * the POD lists it, and an operator reading a log at two in the morning
 * matches on it. A string message is none of those things: it gets
 * reworded, and every reword breaks somebody.
 *
 * The message is for the log and never reaches the browser. A SAML
 * verifier that tells the far side WHY it refused is telling an attacker
 * which check to work on next, so the route answers with one status and
 * one code of its own, and everything below stays in the log.
 *
 * Throwing a blessed object from C is croak_sv territory, and the shim
 * for it is in psaml_compat.h with the reason it is written the way it
 * is. t/00-load.t throws one on purpose so the shim is exercised on
 * every perl the suite runs on, rather than first being reached inside a
 * phase-6 check on a smoker. */

#include "psaml_compat.h"

/* The codes. Every one of these is documented in Punk::SAML::Error's POD
 * and asserted somewhere in t/. Add here and there together, never one
 * without the other.
 *
 * They are strings rather than an enum because the code crosses into
 * Perl, where an integer would have to be translated back, and the
 * translation table would be a third place to keep in step. */
#define PSAML_E_XML_PARSE        "xml_parse"
#define PSAML_E_XML_SHAPE        "xml_shape"
#define PSAML_E_BAD_BASE64       "bad_base64"
#define PSAML_E_BAD_DATETIME     "bad_datetime"
#define PSAML_E_NO_SIGNATURE     "no_signature"
#define PSAML_E_BAD_SIGNATURE    "bad_signature"
#define PSAML_E_BAD_DIGEST       "bad_digest"
#define PSAML_E_ALG_REFUSED      "alg_refused"
#define PSAML_E_UNKNOWN_ISSUER   "unknown_issuer"
#define PSAML_E_NO_KEY           "no_key"
#define PSAML_E_EXPIRED          "expired"
#define PSAML_E_NOT_YET_VALID    "not_yet_valid"
#define PSAML_E_BAD_AUDIENCE     "bad_audience"
#define PSAML_E_BAD_DESTINATION  "bad_destination"
#define PSAML_E_BAD_IN_RESPONSE  "bad_in_response_to"
#define PSAML_E_REPLAY           "replay"
#define PSAML_E_UNSOLICITED      "unsolicited"
#define PSAML_E_ENCRYPTED        "encrypted_assertion"
#define PSAML_E_STATUS           "status"
#define PSAML_E_CONFIG           "config"

/* Builds the exception object: a blessed hashref with code and message.
 * Returns a mortal, because the only thing done with it is throwing it
 * and a leak on the throw path is a leak per failed login. */
PERL_STATIC_INLINE SV *psaml_error_new(pTHX_ const char *code, SV *message) {
  HV *hv = newHV();
  SV *rv;
  (void)hv_stores(hv, "code", newSVpv(code, 0));
  (void)hv_stores(hv, "message", message ? message : newSVpvs(""));
  rv = sv_2mortal(newRV_noinc((SV *)hv));
  sv_bless(rv, gv_stashpvs("Punk::SAML::Error", GV_ADD));
  return rv;
}

/* Throws. Never returns. The message is built here rather than by the
 * caller so that a caller with nothing to add can pass NULL and still
 * get an object with the right code. */
static void psaml_throw(pTHX_ const char *code, const char *fmt, ...) {
  SV *msg = newSVpvs("");
  if (fmt) {
    va_list args;
    va_start(args, fmt);
    sv_vcatpvf(msg, fmt, &args);
    va_end(args);
  }
  else {
    sv_setpv(msg, code);
  }
  croak_sv(psaml_error_new(aTHX_ code, msg));
}

#endif /* PSAML_ERROR_H */
