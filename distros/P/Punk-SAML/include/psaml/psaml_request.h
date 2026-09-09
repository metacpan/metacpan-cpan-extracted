#ifndef PSAML_REQUEST_H
#define PSAML_REQUEST_H

/* The AuthnRequest, the HTTP-Redirect binding, and the signature over it.
 *
 * Assembled as a string rather than built as a tree. The phase-1 parser is
 * a reader; this dist writes three small fixed documents and a general
 * serialiser would be more code than the plugin. What that needs from XML
 * is one escape, and psaml_xml.h has it.
 *
 * Must be included after psaml_b64.h, psaml_deflate.h, psaml_time.h,
 * psaml_xml.h and psaml_boot.h. */

#include "psaml_abi.h"
#include "psaml_b64.h"
#include "psaml_deflate.h"
#include "psaml_time.h"
#include "psaml_xml.h"
#include "psaml_error.h"

#define PSAML_BIND_POST \
  "urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST"
#define PSAML_SIGALG_RSA_SHA256 \
  "http://www.w3.org/2001/04/xmldsig-more#rsa-sha256"
#define PSAML_SIGALG_ECDSA_SHA256 \
  "http://www.w3.org/2001/04/xmldsig-more#ecdsa-sha256"

/* ---- the request id --------------------------------------------------- */

/* An underscore and 32 hex characters.
 *
 * The underscore is not decoration. The ID attribute is xs:ID, whose
 * lexical space is an XML Name, and an XML Name may not begin with a
 * digit. A provider that validates the schema refuses a request whose ID
 * does, and half of a random hex string starts with one, so the failure
 * would be intermittent and look like anything but this. */
PERL_STATIC_INLINE SV *psaml_request_id(pTHX) {
  static const char hex[] = "0123456789abcdef";
  SV *raw = psaml_jws(aTHX)->random_bytes(aTHX_ 16);
  SV *out;
  STRLEN n, i;
  const unsigned char *p;
  if (!raw) croak("%s: the CSPRNG failed", PSAML_WHO);
  p = (const unsigned char *)SvPVbyte(raw, n);
  out = newSVpvs("_");
  for (i = 0; i < n; i++) {
    char pair[2];
    pair[0] = hex[(p[i] >> 4) & 0xF];
    pair[1] = hex[p[i] & 0xF];
    sv_catpvn(out, pair, 2);
  }
  SvREFCNT_dec(raw);
  return out;
}

/* ---- the one URL encoder ---------------------------------------------- */

/* RFC 3986 unreserved passed through, everything else percent-encoded with
 * UPPER-case hex.
 *
 * There is exactly one of these, and that is the point rather than an
 * economy. The redirect signature is computed over the query string AS
 * SENT, so the bytes that are signed and the bytes that go out must come
 * from the same function. Encoders disagree about `~` (RFC 2396 escaped
 * it, RFC 3986 does not), about space as `+` or `%20`, and about the case
 * of the hex digits; any of those differences produces a signature the
 * provider cannot reproduce, and what it reports is "invalid signature"
 * with no indication that the disagreement is about a tilde. */
PERL_STATIC_INLINE void psaml_urlenc_cat(pTHX_ SV *out, const char *in,
                                         STRLEN n) {
  static const char hex[] = "0123456789ABCDEF";
  STRLEN i;
  for (i = 0; i < n; i++) {
    unsigned char c = (unsigned char)in[i];
    if ((c >= 'A' && c <= 'Z') || (c >= 'a' && c <= 'z')
        || (c >= '0' && c <= '9')
        || c == '-' || c == '_' || c == '.' || c == '~') {
      sv_catpvn(out, (const char *)&c, 1);
    }
    else {
      char esc[3];
      esc[0] = '%';
      esc[1] = hex[(c >> 4) & 0xF];
      esc[2] = hex[c & 0xF];
      sv_catpvn(out, esc, 3);
    }
  }
}

PERL_STATIC_INLINE SV *psaml_urlenc(pTHX_ SV *sv) {
  STRLEN n;
  const char *p = SvPVbyte(sv, n);
  SV *out = newSVpvs("");
  psaml_urlenc_cat(aTHX_ out, p, n);
  return out;
}

/* ---- the document ----------------------------------------------------- */

PERL_STATIC_INLINE void psaml_cat_escaped(pTHX_ SV *out, SV *v) {
  STRLEN n, need;
  const char *p;
  char *dst;
  STRLEN wrote, cur;
  if (!v || !SvOK(v)) return;
  p = SvPVbyte(v, n);
  need = psaml_xml_escaped_max(n);
  cur = SvCUR(out);
  dst = SvGROW(out, cur + need + 1) + cur;
  wrote = psaml_xml_escape(dst, p, n);
  SvCUR_set(out, cur + wrote);
  *SvEND(out) = '\0';
}

PERL_STATIC_INLINE void psaml_cat_attr(pTHX_ SV *out, const char *name,
                                       SV *v) {
  sv_catpvs(out, " ");
  sv_catpv(out, name);
  sv_catpvs(out, "=\"");
  psaml_cat_escaped(aTHX_ out, v);
  sv_catpvs(out, "\"");
}

/* The AuthnRequest. `id` and `instant` are passed in rather than made
 * here, because the caller has to keep the id in the flow record and the
 * test has to be able to pin the instant. */
PERL_STATIC_INLINE SV *psaml_authn_request(pTHX_ SV *id, SV *instant,
                                           SV *destination, SV *acs_url,
                                           SV *issuer, SV *name_id_format,
                                           int force_authn) {
  SV *out = newSVpvs(
    "<samlp:AuthnRequest"
    " xmlns:samlp=\"" PSAML_NS_PROTOCOL "\""
    " xmlns:saml=\"" PSAML_NS_ASSERTION "\"");
  psaml_cat_attr(aTHX_ out, "ID", id);
  sv_catpvs(out, " Version=\"2.0\"");
  psaml_cat_attr(aTHX_ out, "IssueInstant", instant);
  /* Destination is the SSO URL as configured, copied and never derived:
   * some providers compare it against the URL they received the request
   * on and refuse a mismatch. */
  psaml_cat_attr(aTHX_ out, "Destination", destination);
  psaml_cat_attr(aTHX_ out, "AssertionConsumerServiceURL", acs_url);
  sv_catpvs(out, " ProtocolBinding=\"" PSAML_BIND_POST "\"");
  /* ForceAuthn only when true: providers differ on whether they read a
   * literal "false", and the default is what everyone tests against. */
  if (force_authn) sv_catpvs(out, " ForceAuthn=\"true\"");
  sv_catpvs(out, ">");

  sv_catpvs(out, "<saml:Issuer>");
  psaml_cat_escaped(aTHX_ out, issuer);
  sv_catpvs(out, "</saml:Issuer>");

  /* NameIDPolicy only when asked for. A policy the provider cannot
   * satisfy comes back as a Responder status and a failed login with
   * nothing useful in it; letting the provider choose is what works
   * everywhere. */
  if (name_id_format && SvOK(name_id_format) && SvCUR(name_id_format)) {
    sv_catpvs(out, "<samlp:NameIDPolicy");
    psaml_cat_attr(aTHX_ out, "Format", name_id_format);
    sv_catpvs(out, " AllowCreate=\"true\"/>");
  }

  sv_catpvs(out, "</samlp:AuthnRequest>");
  return out;
}

/* ---- the redirect binding --------------------------------------------- */

/* base64(rawdeflate(xml)), which is what SAMLRequest carries before it is
 * URL-encoded. Raw DEFLATE with NO header: not zlib, not gzip. A header is
 * the single most common reason a provider answers "invalid request" with
 * no further detail. */
PERL_STATIC_INLINE SV *psaml_deflate_b64(pTHX_ SV *xml) {
  STRLEN n, zlen, blen;
  const char *p = SvPVbyte(xml, n);
  SV *z = newSV(psaml_deflate_bound(n) + 1);
  SV *out;
  SvPOK_on(z);
  zlen = psaml_deflate_stored((unsigned char *)SvPVX(z),
                              (const unsigned char *)p, n);
  SvCUR_set(z, zlen);
  *SvEND(z) = '\0';
  out = newSV(psaml_b64_encoded_len(zlen) + 1);
  SvPOK_on(out);
  blen = psaml_b64_encode(SvPVX(out), (const unsigned char *)SvPVX(z), zlen);
  SvCUR_set(out, blen);
  *SvEND(out) = '\0';
  SvREFCNT_dec(z);
  return out;
}

/* The SigAlg URI and the JWS algorithm for the SP key.
 *
 * Both families, because phase 2's mapping table already names both and a
 * deployer whose SP key is EC would otherwise be stuck with a plugin that
 * can only say rsa-sha256. RSA is what every provider expects and what
 * `punk saml key` will make.
 *
 * The key type is read through Crypt::JWS's Perl surface rather than the
 * C table, because jws_abi has no entry for it: the table can make a key
 * from a PEM and sign with it, but it cannot say what kind of key it got.
 * That is one extra parse per login start, which is microseconds against
 * a redirect, and the alternative is guessing from the PEM header or
 * signing twice to see which works. If this ever matters, a `key_kind`
 * entry appended to jws_abi is the fix. */
PERL_STATIC_INLINE const char *psaml_sigalg_for(pTHX_ SV *pem,
                                                const char **jws_alg) {
  const jws_abi *J = psaml_jws(aTHX);
  SV *cls = sv_2mortal(newSVpvs("Crypt::JWS::Key"));
  SV *argv[1];
  SV *keyobj, *kty;
  STRLEN n, pemlen;
  const char *p;
  const char *pemp = SvPVbyte(pem, pemlen);
  void *probe;

  /* The table's key_from_pem answers NULL rather than croaking, so the
   * refusal is checked here and reported in this dist's words. The Perl
   * call below croaks in Crypt::JWS's words, and a plugin that let a
   * dependency's message reach a deployer configuring `key` would be
   * telling them about a module they did not name. */
  probe = J->key_from_pem(aTHX_ pemp, pemlen);
  if (!probe)
    croak("%s: `key` will not parse as a PEM private key", PSAML_WHO);
  J->key_free(aTHX_ probe);

  argv[0] = pem;
  keyobj = sv_2mortal(psaml_call(aTHX_ cls, "from_pem", argv, 1));
  if (!keyobj || !SvOK(keyobj))
    croak("%s: `key` will not parse as a PEM private key", PSAML_WHO);
  kty = sv_2mortal(psaml_call(aTHX_ keyobj, "kty", NULL, 0));
  if (!kty || !SvOK(kty))
    croak("%s: could not read the type of `key`", PSAML_WHO);
  p = SvPV_const(kty, n);
  if (n == 3 && memEQ(p, "RSA", 3)) {
    *jws_alg = "RS256";
    return PSAML_SIGALG_RSA_SHA256;
  }
  if (n == 2 && memEQ(p, "EC", 2)) {
    *jws_alg = "ES256";
    return PSAML_SIGALG_ECDSA_SHA256;
  }
  croak("%s: `key` is a %.*s key; the redirect signature needs RSA or EC",
        PSAML_WHO, (int)n, p);
  return NULL;
}

/* The signed string of Bindings 3.4.4.1.
 *
 * The order is fixed by the specification and RelayState is omitted
 * ENTIRELY when there is none, rather than sent as an empty value: a
 * provider reconstructing the string follows the same rule, and an empty
 * `&RelayState=` between the other two is a different string.
 *
 * Every value is appended through the SAME encoder that builds the query,
 * and the query is built from these bytes, so what was signed and what is
 * sent cannot differ. */
PERL_STATIC_INLINE SV *psaml_signed_string(pTHX_ SV *enc_req, SV *enc_relay,
                                           SV *enc_sigalg) {
  SV *out = newSVpvs("SAMLRequest=");
  sv_catsv(out, enc_req);
  if (enc_relay) {
    sv_catpvs(out, "&RelayState=");
    sv_catsv(out, enc_relay);
  }
  sv_catpvs(out, "&SigAlg=");
  sv_catsv(out, enc_sigalg);
  return out;
}

/* The full redirect URL.
 *
 * `key_pem` is the SP private key in PEM, or NULL for an unsigned
 * request. `relay` is the flow id, and it is a flow id: the
 * return path lives in the flow record on this side, where neither the
 * provider nor an attacker can rewrite it. */
PERL_STATIC_INLINE SV *psaml_redirect_url(pTHX_ SV *sso_url, SV *xml,
                                          SV *relay, SV *key_pem) {
  SV *payload   = psaml_deflate_b64(aTHX_ xml);
  SV *enc_req   = sv_2mortal(psaml_urlenc(aTHX_ payload));
  SV *enc_relay = (relay && SvOK(relay) && SvCUR(relay))
                ? sv_2mortal(psaml_urlenc(aTHX_ relay)) : NULL;
  SV *out;
  STRLEN sl;
  const char *sp = SvPV_const(sso_url, sl);

  SvREFCNT_dec(payload);

  out = newSVpvn(sp, sl);
  /* after `?`, or after `&` when the SSO URL already carries a query,
   * which several providers' do */
  sv_catpvn(out, memchr(sp, '?', sl) ? "&" : "?", 1);
  sv_catpvs(out, "SAMLRequest=");
  sv_catsv(out, enc_req);
  if (enc_relay) {
    sv_catpvs(out, "&RelayState=");
    sv_catsv(out, enc_relay);
  }

  if (key_pem && SvOK(key_pem) && SvCUR(key_pem)) {
    const jws_abi *J = psaml_jws(aTHX);
    const char *jws_alg = NULL;
    const char *sigalg  = psaml_sigalg_for(aTHX_ key_pem, &jws_alg);
    SV *sigalg_sv  = sv_2mortal(newSVpv(sigalg, 0));
    SV *enc_sigalg = sv_2mortal(psaml_urlenc(aTHX_ sigalg_sv));
    SV *signed_str = sv_2mortal(
        psaml_signed_string(aTHX_ enc_req, enc_relay, enc_sigalg));
    STRLEN inlen, siglen, pemlen;
    const char *inp  = SvPVbyte(signed_str, inlen);
    const char *pemp = SvPVbyte(key_pem, pemlen);
    void *k = J->key_from_pem(aTHX_ pemp, pemlen);
    SV *raw;
    if (!k) croak("%s: `key` will not parse as a PEM private key",
                  PSAML_WHO);
    raw = J->sign(aTHX_ k, jws_alg, strlen(jws_alg),
                  (const unsigned char *)inp, inlen);
    J->key_free(aTHX_ k);
    if (!raw)
      croak("%s: the redirect signature failed", PSAML_WHO);
    {
      const unsigned char *rp =
          (const unsigned char *)SvPVbyte(raw, siglen);
      SV *b64 = newSV(psaml_b64_encoded_len(siglen) + 1);
      STRLEN bn;
      SvPOK_on(b64);
      bn = psaml_b64_encode(SvPVX(b64), rp, siglen);
      SvCUR_set(b64, bn);
      *SvEND(b64) = '\0';
      sv_catpvs(out, "&SigAlg=");
      sv_catsv(out, enc_sigalg);
      sv_catpvs(out, "&Signature=");
      {
        SV *enc_sig = sv_2mortal(psaml_urlenc(aTHX_ b64));
        sv_catsv(out, enc_sig);
      }
      SvREFCNT_dec(b64);
    }
    SvREFCNT_dec(raw);
  }

  return out;
}

/* ---- the inbound field ------------------------------------------------ */

/* SAMLResponse as it arrives: strict base64, decoded, with the size
 * checked BEFORE decoding.
 *
 * The cap is on the encoded field because that is the byte count an
 * attacker controls at the door; checking after decoding means the
 * allocation has already happened.
 *
 * Whitespace is the one leniency, because several providers wrap the
 * base64 at 76 columns and every other implementation accepts that. The
 * url alphabet is still refused: `-` and `_` here would mean a token from
 * somewhere else decoded to something plausible.
 *
 * No inflate. The POST binding never compresses, and a Response that
 * arrives deflated is malformed rather than clever. */
PERL_STATIC_INLINE SV *psaml_decode_field(pTHX_ SV *field, IV max_bytes) {
  STRLEN n, out_len;
  const char *p;
  SV *out;
  if (!field || !SvOK(field))
    psaml_throw(aTHX_ PSAML_E_BAD_BASE64, "the field was not sent");
  p = SvPVbyte(field, n);
  if (max_bytes > 0 && (IV)n > max_bytes)
    psaml_throw(aTHX_ PSAML_E_BAD_BASE64,
                "the encoded field is %" UVuf " bytes, over the "
                "max_response of %" IVdf, (UV)n, max_bytes);
  out = newSV(psaml_b64_decoded_max(n) + 1);
  SvPOK_on(out);
  out_len = psaml_b64_decode_xml((unsigned char *)SvPVX(out), p, n);
  if (out_len == (STRLEN)-1) {
    SvREFCNT_dec(out);
    psaml_throw(aTHX_ PSAML_E_BAD_BASE64,
                "the field is not standard base64");
  }
  SvCUR_set(out, out_len);
  *SvEND(out) = '\0';
  return out;
}

#endif /* PSAML_REQUEST_H */
