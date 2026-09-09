#ifndef PSAML_METADATA_H
#define PSAML_METADATA_H

/* SP metadata out, and the fetch that brings IdP metadata in.
 *
 * The reading is psaml_idp.h and it takes bytes. This file is the thin
 * layer that gets the bytes: a URL through the fetch table, or a path off
 * disk. Keeping them apart is what lets every refusal in the reader be a
 * string in t/.
 *
 * Must be included after psaml_idp.h. */

#include "psaml_idp.h"
#include "psaml_request.h"

/* The specification's media type, not application/xml.
 *
 * Punk 0.46 gives $c->xml, which serialises a document and sends
 * application/xml. That is the right serialiser and the wrong media type:
 * SAML metadata is application/samlmetadata+xml, most consumers accept
 * either, and the ones that do not are exactly the strict deployments
 * this matters to. So the route sets the header itself. */
#define PSAML_CT_METADATA "application/samlmetadata+xml"

/* ---- SP metadata, written ---------------------------------------------- */

/* The document an operator pastes into a provider's setup screen, or
 * points the provider at.
 *
 * Assembled by string with the six-case escape, as everything this dist
 * writes is. `acs_url` is the ONE URL phase 4 computed at on_compile, and
 * it is passed in rather than derived here, so this is not a fourth
 * place that could disagree about what this application's ACS is. */
PERL_STATIC_INLINE SV *psaml_sp_metadata(pTHX_ SV *entity_id, SV *acs_url,
                                         SV *cert, SV *name_id_format,
                                         int authn_requests_signed,
                                         int want_assertions_signed) {
  SV *out = newSVpvs(
    "<md:EntityDescriptor"
    " xmlns:md=\"" PSAML_NS_METADATA "\""
    " xmlns:ds=\"" PSAML_NS_DSIG "\"");
  psaml_cat_attr(aTHX_ out, "entityID", entity_id);
  sv_catpvs(out, "><md:SPSSODescriptor AuthnRequestsSigned=\"");
  sv_catpv(out, authn_requests_signed ? "true" : "false");
  sv_catpvs(out, "\" WantAssertionsSigned=\"");
  sv_catpv(out, want_assertions_signed ? "true" : "false");
  sv_catpvs(out, "\" protocolSupportEnumeration=\"" PSAML_NS_PROTOCOL "\">");

  /* only when there is one: a KeyDescriptor with no certificate in it is
   * a document a provider will reject, and an empty element is worse
   * than an absent one */
  if (cert && SvOK(cert) && SvCUR(cert)) {
    /* the PEM armour and its newlines are stripped: what goes in the
     * document is the base64 of the DER and nothing else, which is what
     * <ds:X509Certificate> means */
    STRLEN n;
    const char *p = SvPVbyte(cert, n);
    const char *b, *e;
    static const char BEG[] = "-----BEGIN CERTIFICATE-----";
    static const char END[] = "-----END CERTIFICATE-----";
    b = ninstr((char *)p, (char *)p + n,
               (char *)BEG, (char *)BEG + sizeof BEG - 1);
    e = b ? ninstr((char *)b, (char *)p + n,
                   (char *)END, (char *)END + sizeof END - 1) : NULL;
    if (b && e) {
      STRLEN i;
      b += sizeof BEG - 1;
      sv_catpvs(out, "<md:KeyDescriptor use=\"signing\"><ds:KeyInfo>"
                     "<ds:X509Data><ds:X509Certificate>");
      for (i = 0; b + i < e; i++) {
        char c = b[i];
        if (c != '\n' && c != '\r' && c != ' ' && c != '\t')
          sv_catpvn(out, &c, 1);
      }
      sv_catpvs(out, "</ds:X509Certificate></ds:X509Data></ds:KeyInfo>"
                     "</md:KeyDescriptor>");
    }
  }

  if (name_id_format && SvOK(name_id_format) && SvCUR(name_id_format)) {
    sv_catpvs(out, "<md:NameIDFormat>");
    psaml_cat_escaped(aTHX_ out, name_id_format);
    sv_catpvs(out, "</md:NameIDFormat>");
  }

  sv_catpvs(out, "<md:AssertionConsumerService index=\"0\" isDefault=\"true\""
                 " Binding=\"" PSAML_BIND_POST "\"");
  psaml_cat_attr(aTHX_ out, "Location", acs_url);
  sv_catpvs(out, "/></md:SPSSODescriptor></md:EntityDescriptor>");
  return out;
}

/* ---- sign_metadata ----------------------------------------------------- */

/* The one place this distribution CREATES an XML signature.
 *
 * Some providers refuse unsigned metadata by policy, so it exists; it is
 * not otherwise needed, and metadata is a public document.
 *
 * BE HONEST ABOUT WHAT THIS PROVES. The signer canonicalises through the
 * same frx c14n the verifier uses and signs through the same jws table,
 * so a test that signs here and verifies with psaml_signature.h proves
 * the two agree and nothing more. If the canonicalisation were wrong,
 * both halves would be wrong together and every such test would pass.
 * What proves the c14n is File::Raw::XML's transcribed W3C vectors; what
 * proves this document is a provider accepting it, which is phase 11.
 *
 * The Signature is spliced in as the first child by string assembly,
 * after the document has been canonicalised without it - which is what
 * `enveloped-signature` means and why the order here is not negotiable. */
PERL_STATIC_INLINE SV *psaml_sign_document(pTHX_ SV *xml, SV *id,
                                           SV *key_pem, SV *cert_pem) {
  const frx_abi *F = psaml_frx(aTHX);
  const jws_abi *J = psaml_jws(aTHX);
  psaml_doc_guard *guard = NULL;
  frx_doc *doc;
  const frx_node *target;
  frx_c14n c;
  SV *canon, *digest, *si, *si_canon, *sig, *out;
  const char *jws_alg = NULL;
  const char *sigalg;
  STRLEN il;
  const char *ip;

  ip = SvPVbyte(id, il);

  sigalg = psaml_sigalg_for(aTHX_ key_pem, &jws_alg);
  /* the metadata signature uses the XML-DSig spelling of the algorithm,
   * which is the same URI phase 5's redirect binding names */
  if (strEQ(jws_alg, "RS256"))
    sigalg = "http://www.w3.org/2001/04/xmldsig-more#rsa-sha256";
  else
    sigalg = "http://www.w3.org/2001/04/xmldsig-more#ecdsa-sha256";

  doc = psaml_parse_response(aTHX_ xml, &guard);
  target = F->by_id(doc, "ID", ip, il);
  if (!target)
    croak("%s: the document to sign has no element with ID '%.*s'",
          PSAML_WHO, (int)il, ip);

  Zero(&c, 1, frx_c14n);
  c.mode = FRX_C14N_EXC;
  canon = F->c14n(aTHX_ target, &c);
  if (!canon) croak("%s: the document would not canonicalise", PSAML_WHO);
  sv_2mortal(canon);

  {
    STRLEN cl;
    const unsigned char *cp = (const unsigned char *)SvPVbyte(canon, cl);
    SV *raw = J->sha256(aTHX_ cp, cl);
    STRLEN dn;
    const unsigned char *dp;
    if (!raw) croak("%s: the digest failed", PSAML_WHO);
    sv_2mortal(raw);
    dp = (const unsigned char *)SvPVbyte(raw, dn);
    digest = sv_2mortal(newSV(psaml_b64_encoded_len(dn) + 1));
    SvPOK_on(digest);
    SvCUR_set(digest, psaml_b64_encode(SvPVX(digest), dp, dn));
  }

  si = sv_2mortal(newSVpvs("<ds:SignedInfo xmlns:ds=\"" PSAML_NS_DSIG "\">"
      "<ds:CanonicalizationMethod Algorithm=\"" PSAML_C14N_EXC "\"/>"
      "<ds:SignatureMethod Algorithm=\""));
  sv_catpv(si, sigalg);
  sv_catpvs(si, "\"/><ds:Reference URI=\"#");
  sv_catpvn(si, ip, il);
  sv_catpvs(si, "\"><ds:Transforms>"
      "<ds:Transform Algorithm=\"" PSAML_TR_ENVELOPED "\"/>"
      "<ds:Transform Algorithm=\"" PSAML_C14N_EXC "\"/>"
      "</ds:Transforms>"
      "<ds:DigestMethod Algorithm=\"http://www.w3.org/2001/04/xmlenc#sha256\"/>"
      "<ds:DigestValue>");
  sv_catsv(si, digest);
  sv_catpvs(si, "</ds:DigestValue></ds:Reference></ds:SignedInfo>");

  /* SignedInfo is canonicalised ON ITS OWN, as a document, because that
   * is what the verifier will do to it */
  {
    psaml_doc_guard *g2 = NULL;
    frx_doc *d2 = psaml_parse_response(aTHX_ si, &g2);
    frx_c14n c2;
    Zero(&c2, 1, frx_c14n);
    c2.mode = FRX_C14N_EXC;
    si_canon = F->c14n(aTHX_ F->root(d2), &c2);
    if (!si_canon) croak("%s: the SignedInfo would not canonicalise",
                         PSAML_WHO);
    sv_2mortal(si_canon);
  }

  {
    STRLEN sl, pl;
    const unsigned char *sp = (const unsigned char *)SvPVbyte(si_canon, sl);
    const char *pp = SvPVbyte(key_pem, pl);
    void *k = J->key_from_pem(aTHX_ pp, pl);
    SV *raw;
    STRLEN rn;
    const unsigned char *rp;
    if (!k) croak("%s: `key` will not parse as a PEM private key", PSAML_WHO);
    raw = J->sign(aTHX_ k, jws_alg, strlen(jws_alg), sp, sl);
    J->key_free(aTHX_ k);
    if (!raw) croak("%s: signing the metadata failed", PSAML_WHO);
    sv_2mortal(raw);
    rp = (const unsigned char *)SvPVbyte(raw, rn);
    sig = sv_2mortal(newSVpvs("<ds:Signature xmlns:ds=\"" PSAML_NS_DSIG "\">"));
    sv_catsv(sig, si);
    sv_catpvs(sig, "<ds:SignatureValue>");
    {
      SV *b = sv_2mortal(newSV(psaml_b64_encoded_len(rn) + 1));
      SvPOK_on(b);
      SvCUR_set(b, psaml_b64_encode(SvPVX(b), rp, rn));
      sv_catsv(sig, b);
    }
    sv_catpvs(sig, "</ds:SignatureValue>");
    if (cert_pem && SvOK(cert_pem) && SvCUR(cert_pem)) {
      STRLEN n;
      const char *p = SvPVbyte(cert_pem, n);
      const char *b, *e;
      static const char BEG[] = "-----BEGIN CERTIFICATE-----";
      static const char END[] = "-----END CERTIFICATE-----";
      b = ninstr((char *)p, (char *)p + n,
                 (char *)BEG, (char *)BEG + sizeof BEG - 1);
      e = b ? ninstr((char *)b, (char *)p + n,
                     (char *)END, (char *)END + sizeof END - 1) : NULL;
      if (b && e) {
        STRLEN i;
        b += sizeof BEG - 1;
        sv_catpvs(sig, "<ds:KeyInfo><ds:X509Data><ds:X509Certificate>");
        for (i = 0; b + i < e; i++) {
          char ch = b[i];
          if (ch != '\n' && ch != '\r' && ch != ' ' && ch != '\t')
            sv_catpvn(sig, &ch, 1);
        }
        sv_catpvs(sig, "</ds:X509Certificate></ds:X509Data></ds:KeyInfo>");
      }
    }
    sv_catpvs(sig, "</ds:Signature>");
  }

  /* Splice it in as the first child of THE SIGNED ELEMENT, which is not
   * necessarily the root.
   *
   * The first version of this put the Signature after the first `>` in
   * the document, which is the root's start tag. That is correct for
   * metadata, where the signed element IS the root, and wrong for
   * anything nested - an Assertion inside a Response, say. The signature
   * then sat on the Response while its Reference named the Assertion,
   * and this dist's own verifier refused it with "the Reference names an
   * element other than the one the Signature is a child of", which is
   * exactly what that check is for.
   *
   * So the start tag is found by its ID attribute and the splice goes
   * after the `>` that closes it. Quoted attribute values are skipped,
   * because a `>` inside one is not the end of the tag. */
  {
    STRLEN xl;
    const char *xp = SvPVbyte(xml, xl);
    const char *end = xp + xl;
    SV *needle = sv_2mortal(newSVpvs("ID=\""));
    const char *at, *gt;
    STRLEN nl2;
    const char *np2;

    sv_catpvn(needle, ip, il);
    sv_catpvs(needle, "\"");
    np2 = SvPV_const(needle, nl2);

    at = ninstr((char *)xp, (char *)end, (char *)np2, (char *)np2 + nl2);
    if (!at)
      croak("%s: the document does not carry ID=\"%.*s\" as written",
            PSAML_WHO, (int)il, ip);

    /* forward to the `>` that closes this start tag */
    gt = at;
    while (gt < end && *gt != '>') {
      if (*gt == '"') {
        gt++;
        while (gt < end && *gt != '"') gt++;
      }
      gt++;
    }
    if (gt >= end)
      croak("%s: the element carrying ID=\"%.*s\" has no closing '>'",
            PSAML_WHO, (int)il, ip);

    out = newSVpvn(xp, (STRLEN)(gt - xp) + 1);
    sv_catsv(out, sig);
    sv_catpvn(out, gt + 1, xl - (STRLEN)(gt - xp) - 1);
  }
  return out;
}

#endif /* PSAML_METADATA_H */
