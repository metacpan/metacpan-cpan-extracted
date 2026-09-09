#ifndef PSAML_IDP_H
#define PSAML_IDP_H

/* A provider, read out of its metadata.
 *
 * THE SEAM: reading is pure and takes bytes. Fetching is a thin layer
 * over it in psaml_metadata.h. That is not tidiness. Every refusal
 * below - a POST-only endpoint, a federation file with no chosen
 * entity, a document with no usable key - is a decision that must be
 * tested, and a reader that took a URL could only be tested against a
 * network. This one is tested against strings.
 *
 * What comes back is a hashref, not an opaque struct, because
 * `punk saml idp` prints it, the tests read it, and phase 6 wants the
 * certificates as the PEM its psaml_key_from_config already reads.
 *
 * Must be included after psaml_xml.h, psaml_b64.h and psaml_error.h. */

#include "psaml_abi.h"
#include "psaml_xml.h"
#include "psaml_b64.h"
#include "psaml_error.h"
#include "psaml_response.h"

#define PSAML_BIND_REDIRECT \
  "urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect"

/* ---- certificates ------------------------------------------------------ */

/* The DER of an <ds:X509Certificate>, whose content is base64 wrapped at
 * whatever column the provider chose. psaml_b64_decode_xml is the variant
 * that tolerates the wrapping and still refuses the url alphabet. */
PERL_STATIC_INLINE SV *psaml_cert_der(pTHX_ const frx_node *certnode) {
  SV *txt = sv_2mortal(psaml_frx(aTHX)->text(aTHX_ certnode));
  STRLEN n, dl;
  const char *p = SvPVbyte(txt, n);
  SV *der = newSV(psaml_b64_decoded_max(n) + 1);
  SvPOK_on(der);
  dl = psaml_b64_decode_xml((unsigned char *)SvPVX(der), p, n);
  if (dl == (STRLEN)-1) {
    SvREFCNT_dec(der);
    return NULL;
  }
  SvCUR_set(der, dl);
  *SvEND(der) = '\0';
  return der;
}

/* PEM, wrapped at 64, from DER. The certificate is kept in the form a
 * deployer would paste and phase 6's psaml_key_from_config already
 * reads, so a certificate that came from metadata and one that came from
 * a `certs` option are the same thing downstream. */
PERL_STATIC_INLINE SV *psaml_der_to_pem(pTHX_ SV *der) {
  STRLEN n, bl, i;
  const unsigned char *p = (const unsigned char *)SvPVbyte(der, n);
  SV *b64 = sv_2mortal(newSV(psaml_b64_encoded_len(n) + 1));
  SV *out = newSVpvs("-----BEGIN CERTIFICATE-----\n");
  const char *bp;
  SvPOK_on(b64);
  bl = psaml_b64_encode(SvPVX(b64), p, n);
  SvCUR_set(b64, bl);
  bp = SvPVX(b64);
  for (i = 0; i < bl; i += 64) {
    STRLEN take = (bl - i) < 64 ? (bl - i) : 64;
    sv_catpvn(out, bp + i, take);
    sv_catpvs(out, "\n");
  }
  sv_catpvs(out, "-----END CERTIFICATE-----\n");
  return out;
}

/* The fingerprint, as hex, over the SAME DER the key was made from.
 *
 * The same bytes matters: a provider's console shows the fingerprint of
 * the certificate file, and an operator comparing what `punk saml idp`
 * prints against that console is comparing two digests of one thing or
 * discovering they are not. */
PERL_STATIC_INLINE SV *psaml_fingerprint(pTHX_ SV *der) {
  static const char hex[] = "0123456789abcdef";
  STRLEN n, i;
  const unsigned char *p = (const unsigned char *)SvPVbyte(der, n);
  SV *raw = psaml_jws(aTHX)->sha256(aTHX_ p, n);
  SV *out;
  const unsigned char *d;
  STRLEN dn;
  if (!raw) return newSVpvs("");
  sv_2mortal(raw);
  d = (const unsigned char *)SvPVbyte(raw, dn);
  out = newSVpvs("");
  for (i = 0; i < dn; i++) {
    char pair[2];
    pair[0] = hex[(d[i] >> 4) & 0xF];
    pair[1] = hex[d[i] & 0xF];
    sv_catpvn(out, pair, 2);
  }
  return out;
}

/* ---- reading ----------------------------------------------------------- */

/* Pick the EntityDescriptor to read.
 *
 * A federation file is an EntitiesDescriptor holding many, and which one
 * this application talks to is not something the file can say. Without
 * `want`, the croak LISTS the ids found, because that is the message an
 * operator can act on in one step rather than one that sends them back
 * to the file with a text editor. */
PERL_STATIC_INLINE const frx_node *psaml_pick_entity(pTHX_ const frx_node *root,
                                                     const char *want) {
  const frx_abi *F = psaml_frx(aTHX);
  STRLEN ll;
  const char *lo = F->local(root, &ll);

  if (psaml_str_is(lo, ll, "EntityDescriptor")) {
    if (want && *want) {
      STRLEN el;
      const char *e = psaml_attr(aTHX_ root, "entityID", &el);
      if (!psaml_str_is(e, el, want))
        psaml_throw(aTHX_ PSAML_E_CONFIG,
                    "this metadata describes '%.*s', not the configured "
                    "entity_id '%s'", (int)(e ? el : 0), e ? e : "", want);
    }
    return root;
  }
  if (!psaml_str_is(lo, ll, "EntitiesDescriptor"))
    psaml_throw(aTHX_ PSAML_E_CONFIG,
                "the metadata root is neither EntityDescriptor nor "
                "EntitiesDescriptor");

  {
    const frx_node *e = NULL;
    SV *found = sv_2mortal(newSVpvs(""));
    int n = 0;
    while ((e = F->find(root, PSAML_NS_METADATA, "EntityDescriptor",
                        e)) != NULL) {
      STRLEN il;
      const char *id = psaml_attr(aTHX_ e, "entityID", &il);
      if (want && *want && psaml_str_is(id, il, want)) return e;
      if (n++) sv_catpvs(found, ", ");
      if (id) sv_catpvn(found, id, il);
    }
    if (want && *want)
      psaml_throw(aTHX_ PSAML_E_CONFIG,
                  "no entity '%s' in this federation metadata (found: %s)",
                  want, SvCUR(found) ? SvPV_nolen(found) : "none");
    psaml_throw(aTHX_ PSAML_E_CONFIG,
                "this is federation metadata describing %d entities; name "
                "the one to use with entity_id (found: %s)", n,
                SvCUR(found) ? SvPV_nolen(found) : "none");
  }
  return NULL;
}

/* Read a provider out of metadata bytes. Returns a +1 hashref. */
PERL_STATIC_INLINE SV *psaml_idp_from_metadata(pTHX_ SV *bytes,
                                               const char *want_entity,
                                               int enforce_validity) {
  const frx_abi *F = psaml_frx(aTHX);
  psaml_doc_guard *guard = NULL;
  frx_doc *doc;
  const frx_node *root, *ent, *idpd, *kd;
  HV *out = newHV();
  SV *rv = newRV_noinc((SV *)out);
  AV *certs = newAV(), *prints = newAV(), *formats = newAV();
  STRLEN vl;
  const char *v;

  sv_2mortal(rv);
  (void)hv_stores(out, "certs",    newRV_noinc((SV *)certs));
  (void)hv_stores(out, "fingerprints", newRV_noinc((SV *)prints));
  (void)hv_stores(out, "name_id_formats", newRV_noinc((SV *)formats));

  doc = psaml_parse_response(aTHX_ bytes, &guard);
  root = F->root(doc);

  ent = psaml_pick_entity(aTHX_ root, want_entity);
  v = psaml_attr(aTHX_ ent, "entityID", &vl);
  if (!v || !vl)
    psaml_throw(aTHX_ PSAML_E_CONFIG,
                "the EntityDescriptor has no entityID");
  (void)hv_stores(out, "entity_id", newSVpvn(v, vl));

  idpd = psaml_child(aTHX_ ent, PSAML_NS_METADATA, "IDPSSODescriptor", NULL);
  if (!idpd)
    psaml_throw(aTHX_ PSAML_E_CONFIG,
                "'%.*s' publishes no IDPSSODescriptor, so it is not an "
                "identity provider", (int)vl, v);

  /* The SSO URL, from the REDIRECT binding.
   *
   * A provider offering only POST is refused here, at boot, rather than
   * at the first login: phase 5 sends by redirect, and a request sent by
   * redirect to a POST-only endpoint is an error the provider phrases
   * unhelpfully, at a user, hours later. */
  {
    const frx_node *sso = NULL;
    int saw_any = 0;
    while ((sso = F->find(idpd, PSAML_NS_METADATA,
                          "SingleSignOnService", sso)) != NULL) {
      saw_any = 1;
      if (psaml_attr_is(aTHX_ sso, "Binding", PSAML_BIND_REDIRECT)) {
        const char *loc = psaml_attr(aTHX_ sso, "Location", &vl);
        if (loc && vl) {
          (void)hv_stores(out, "sso_url", newSVpvn(loc, vl));
          break;
        }
      }
    }
    if (!hv_exists(out, "sso_url", 7))
      psaml_throw(aTHX_ PSAML_E_CONFIG,
                  saw_any
                    ? "this provider publishes no HTTP-Redirect "
                      "SingleSignOnService. This plugin sends AuthnRequests "
                      "by redirect, which is the binding every provider "
                      "supports; ask for it to be enabled"
                    : "this provider publishes no SingleSignOnService at all");
  }

  /* Every KeyDescriptor that is for signing.
   *
   * `use="signing"` OR NO `use` ATTRIBUTE. The specification says a
   * missing `use` means the key serves both purposes, and providers omit
   * it constantly; a reader that required the attribute would find no
   * keys in perfectly ordinary metadata. `use="encryption"` is not a
   * signing key and is skipped.
   *
   * All of them are kept, in order. A provider mid-rotation publishes
   * the outgoing and the incoming certificate together, and phase 6
   * tries each. */
  kd = NULL;
  while ((kd = F->find(idpd, PSAML_NS_METADATA, "KeyDescriptor",
                       kd)) != NULL) {
    const frx_node *ki, *x5d, *x5c;
    const char *u = psaml_attr(aTHX_ kd, "use", &vl);
    if (u && !psaml_str_is(u, vl, "signing")) continue;
    ki = psaml_child(aTHX_ kd, PSAML_NS_DSIG, "KeyInfo", NULL);
    if (!ki) continue;
    x5d = NULL;
    while ((x5d = F->find(ki, PSAML_NS_DSIG, "X509Data", x5d)) != NULL) {
      x5c = NULL;
      while ((x5c = F->find(x5d, PSAML_NS_DSIG, "X509Certificate",
                            x5c)) != NULL) {
        SV *der = psaml_cert_der(aTHX_ x5c);
        void *probe;
        if (!der)
          psaml_throw(aTHX_ PSAML_E_CONFIG,
                      "an X509Certificate in this metadata is not base64");
        sv_2mortal(der);
        /* proven readable here rather than at the first login: a
         * certificate that will not parse is a metadata problem and the
         * operator is standing right here */
        probe = psaml_jws(aTHX)->key_from_x509_der(aTHX_
                    (const unsigned char *)SvPVX(der), SvCUR(der));
        if (!probe)
          psaml_throw(aTHX_ PSAML_E_CONFIG,
                      "an X509Certificate in this metadata will not parse "
                      "as an X.509 certificate with an RSA or EC key");
        psaml_jws(aTHX)->key_free(aTHX_ probe);
        av_push(certs,  psaml_der_to_pem(aTHX_ der));
        av_push(prints, psaml_fingerprint(aTHX_ der));
      }
    }
  }
  if (av_len(certs) < 0)
    psaml_throw(aTHX_ PSAML_E_CONFIG,
                "this provider's metadata publishes no signing certificate. "
                "Every KeyDescriptor was use=\"encryption\", or there were "
                "none");

  /* Not enforced by default, and this is a deliberate refusal to be
   * strict: providers routinely sign with certificates that expired
   * months ago, the trust here is the configured key rather than a
   * chain, and refusing one helps nobody. The dates are printed by
   * `punk saml idp` so an operator sees a rotation coming. */
  PERL_UNUSED_VAR(enforce_validity);

  {
    const frx_node *nf = NULL;
    while ((nf = F->find(idpd, PSAML_NS_METADATA, "NameIDFormat",
                         nf)) != NULL) {
      SV *t = F->text(aTHX_ nf);
      av_push(formats, t);
    }
  }

  (void)hv_stores(out, "want_authn_requests_signed",
                  newSViv(psaml_attr_is(aTHX_ idpd,
                                        "WantAuthnRequestsSigned", "true")));

  return SvREFCNT_inc_simple_NN(rv);
}

#endif /* PSAML_IDP_H */
