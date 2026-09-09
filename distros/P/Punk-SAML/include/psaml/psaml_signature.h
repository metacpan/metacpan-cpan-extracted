#ifndef PSAML_SIGNATURE_H
#define PSAML_SIGNATURE_H

/* XML-DSig, verified.
 *
 * ONE RULE, applied without exception, and everything else in this file
 * is machinery for it:
 *
 *   THE ELEMENT WHOSE CHILD THE SIGNATURE IS, IS THE ELEMENT THE
 *   SIGNATURE COVERS, IS THE ELEMENT THE IDENTITY IS READ FROM.
 *
 * The reason SAML libraries have had a decade of authentication bypasses
 * is that the signed thing and the read thing were allowed to differ. An
 * attacker takes a signed assertion for their own account, adds an
 * unsigned assertion for the administrator's, and arranges the document
 * so the verifier finds one and the reader finds the other. Every
 * published variant is that. So this file returns the verified node, the
 * caller holds it in one local, and every read below it starts from that
 * pointer. There is no second lookup and no search from the root.
 *
 * Must be included after psaml_xml.h, psaml_b64.h and psaml_error.h. */

#include "psaml_abi.h"
#include "psaml_xml.h"
#include "psaml_b64.h"
#include "psaml_error.h"

#define PSAML_C14N_EXC      "http://www.w3.org/2001/10/xml-exc-c14n#"
#define PSAML_C14N_EXC_WC   "http://www.w3.org/2001/10/xml-exc-c14n#WithComments"
#define PSAML_TR_ENVELOPED  "http://www.w3.org/2000/09/xmldsig#enveloped-signature"

#define PSAML_MAX_PREFIXES 64

/* The accepted SignatureMethods, and what each is called in jws_abi.
 *
 * There is deliberately no rsa-sha1 here, and allow_sha1 does not add
 * one. See PSAML_DIGESTS below for where that option does reach. */
typedef struct {
  const char *uri;
  const char *alg;      /* the jws algorithm name */
} psaml_sigalg_map;

static const psaml_sigalg_map PSAML_SIGALGS[] = {
  { "http://www.w3.org/2001/04/xmldsig-more#rsa-sha256",   "RS256" },
  { "http://www.w3.org/2001/04/xmldsig-more#rsa-sha384",   "RS384" },
  { "http://www.w3.org/2001/04/xmldsig-more#rsa-sha512",   "RS512" },
  { "http://www.w3.org/2001/04/xmldsig-more#ecdsa-sha256", "ES256" },
  { "http://www.w3.org/2001/04/xmldsig-more#ecdsa-sha384", "ES384" },
  { "http://www.w3.org/2001/04/xmldsig-more#ecdsa-sha512", "ES512" },
  { NULL, NULL }
};

/* DigestMethod URIs.
 *
 * SHA-256 and, under allow_sha1, SHA-1. NOT 384 or 512, and that is a
 * limitation of jws_abi rather than a decision: the table carries sha256
 * and sha1 as one-shot digests and nothing else, so this dist cannot
 * compute a SHA-384 or SHA-512 reference digest at all. They are listed
 * here so the refusal names them specifically instead of reporting an
 * unknown algorithm, and the fix is two entries appended to jws_abi.
 *
 * This bites nothing in practice: every identity provider in the field
 * digests with SHA-256, and the SignatureMethod side, which does go
 * through jws `verify`, takes all of RS/ES 256, 384 and 512 already.
 *
 * SHA-1 is reachable only on the DIGEST side. There is no rsa-sha1 in
 * PSAML_SIGALGS and allow_sha1 does not add one: JWS has no RS1, and
 * adding one so SAML can accept a signature algorithm deprecated since
 * 2011 is the wrong direction. The digest side is the less harmful of
 * the two and is where the option reaches. */
typedef struct { const char *uri; int bits; int needs_allow_sha1; } psaml_dig;

static const psaml_dig PSAML_DIGESTS[] = {
  { "http://www.w3.org/2001/04/xmlenc#sha256",       256, 0 },
  { "http://www.w3.org/2000/09/xmldsig#sha1",        160, 1 },
  { "http://www.w3.org/2001/04/xmldsig-more#sha384", 384, 0 },  /* refused */
  { "http://www.w3.org/2001/04/xmlenc#sha512",       512, 0 },  /* refused */
  { NULL, 0, 0 }
};

/* Returns the bit length, 0 for an unknown or disallowed algorithm. */
PERL_STATIC_INLINE int psaml_digest_bits(const char *uri, STRLEN n,
                                         int allow_sha1) {
  int i;
  for (i = 0; PSAML_DIGESTS[i].uri; i++) {
    STRLEN ul = strlen(PSAML_DIGESTS[i].uri);
    if (n == ul && memEQ(uri, PSAML_DIGESTS[i].uri, ul)) {
      if (PSAML_DIGESTS[i].needs_allow_sha1 && !allow_sha1) return 0;
      return PSAML_DIGESTS[i].bits;
    }
  }
  return 0;
}

/* ---- small helpers over the tree -------------------------------------- */

/* An attribute compared to a literal, whole. */
PERL_STATIC_INLINE int psaml_attr_is(pTHX_ const frx_node *n,
                                     const char *name, const char *want) {
  STRLEN vl;
  const char *v = psaml_attr(aTHX_ n, name, &vl);
  STRLEN wl = strlen(want);
  return v && vl == wl && memEQ(v, want, wl);
}

/* The direct-child ds:Signature, or NULL.
 *
 * DIRECT CHILD, and that is the first of the nine rules rather than an
 * implementation convenience. A Signature inside Extensions, inside
 * Subject, or inside another assertion's Advice is not looked at, and its
 * presence does not make anything signed. A verifier that searched the
 * subtree for "a signature" is a verifier that can be handed one over a
 * different element. */
PERL_STATIC_INLINE const frx_node *psaml_sig_of(pTHX_ const frx_node *n) {
  return psaml_child(aTHX_ n, PSAML_NS_DSIG, "Signature", NULL);
}

/* Collect an InclusiveNamespaces PrefixList into a caller-owned array of
 * borrowed pointers. Returns the count.
 *
 * The list is whitespace-separated prefixes; "#default" names the default
 * namespace. The strings are cut out of the attribute value, which lives
 * in the document's arena, so they are NUL-terminated copies made here
 * because the value is one string and c14n wants separate ones. */
PERL_STATIC_INLINE int psaml_prefix_list(pTHX_ const frx_node *transform,
                                         char *buf, STRLEN buflen,
                                         const char **out, int max) {
  const frx_node *inc;
  const char *v;
  STRLEN vl, i, start;
  int n = 0;
  if (!transform) return 0;
  inc = psaml_child(aTHX_ transform, PSAML_C14N_EXC, "InclusiveNamespaces",
                    NULL);
  if (!inc) return 0;
  v = psaml_attr(aTHX_ inc, "PrefixList", &vl);
  if (!v || !vl) return 0;
  if (vl >= buflen) vl = buflen - 1;
  memcpy(buf, v, vl);
  buf[vl] = '\0';
  i = 0;
  while (i < vl && n < max) {
    while (i < vl && (buf[i] == ' ' || buf[i] == '\t'
                      || buf[i] == '\r' || buf[i] == '\n')) i++;
    if (i >= vl) break;
    start = i;
    while (i < vl && !(buf[i] == ' ' || buf[i] == '\t'
                       || buf[i] == '\r' || buf[i] == '\n')) i++;
    buf[i < vl ? i : vl] = '\0';
    out[n++] = buf + start;
    i++;
  }
  return n;
}

/* ---- the verification ------------------------------------------------- */

typedef struct {
  const frx_doc *doc;
  AV            *keys;        /* PEM certificates or public keys, as SVs */
  int            allow_sha1;
} psaml_verify_ctx;

/* A configured signing key, which is usually a CERTIFICATE.
 *
 * SAML metadata carries <ds:X509Certificate>, and what a deployer pastes
 * into `certs` is a PEM certificate, not a PUBLIC KEY block. key_from_pem
 * reads the latter and refuses the former, so this is where phase 2's
 * key_from_x509_der earns its place: try the key form first, and on
 * failure strip the PEM armour and hand the DER to the certificate entry.
 *
 * Both forms are accepted because a deployer who does have a bare public
 * key should not be told to wrap it in a certificate to satisfy us.
 * Returns NULL for anything that is neither. */
PERL_STATIC_INLINE void *psaml_key_from_config(pTHX_ SV *sv) {
  const jws_abi *J = psaml_jws(aTHX);
  STRLEN n, dl;
  const char *p = SvPVbyte(sv, n);
  const char *b, *e;
  SV *der;
  void *k;

  k = J->key_from_pem(aTHX_ p, n);
  if (k) return k;

  {
    static const char BEG[] = "-----BEGIN CERTIFICATE-----";
    static const char END[] = "-----END CERTIFICATE-----";
    b = ninstr((char *)p, (char *)p + n,
               (char *)BEG, (char *)BEG + sizeof BEG - 1);
    if (!b) return NULL;
    b += sizeof BEG - 1;
    e = ninstr((char *)b, (char *)p + n,
               (char *)END, (char *)END + sizeof END - 1);
    if (!e) return NULL;
  }

  der = sv_2mortal(newSV(psaml_b64_decoded_max((STRLEN)(e - b)) + 1));
  SvPOK_on(der);
  dl = psaml_b64_decode_xml((unsigned char *)SvPVX(der), b, (STRLEN)(e - b));
  if (dl == (STRLEN)-1) return NULL;
  SvCUR_set(der, dl);
  return J->key_from_x509_der(aTHX_
             (const unsigned char *)SvPVX(der), dl);
}

/* Verify the direct-child signature of `parent`.
 *
 * Returns 1 when a signature is present and verifies, 0 when there is no
 * direct-child signature at all, and THROWS on a signature that is
 * present and wrong. The three outcomes are distinct because
 * `require_signed` needs to tell "unsigned" from "badly signed": the
 * first may be allowed by policy, the second never is. */
PERL_STATIC_INLINE int psaml_verify_element(pTHX_ psaml_verify_ctx *ctx,
                                            const frx_node *parent) {
  const frx_abi *F = psaml_frx(aTHX);
  const jws_abi *J = psaml_jws(aTHX);
  const frx_node *sig, *si, *cm, *sm, *ref, *trs, *t1, *t2, *dm, *dv, *sv_node;
  const char *v;
  STRLEN vl;
  int i;

  sig = psaml_sig_of(aTHX_ parent);
  if (!sig) return 0;

  si = psaml_only_child(aTHX_ sig, PSAML_NS_DSIG, "SignedInfo");
  if (!si)
    psaml_throw(aTHX_ PSAML_E_BAD_SIGNATURE,
                "the Signature has no single SignedInfo");

  /* 2: CanonicalizationMethod must be exclusive c14n */
  cm = psaml_only_child(aTHX_ si, PSAML_NS_DSIG, "CanonicalizationMethod");
  if (!cm || !(psaml_attr_is(aTHX_ cm, "Algorithm", PSAML_C14N_EXC)
            || psaml_attr_is(aTHX_ cm, "Algorithm", PSAML_C14N_EXC_WC)))
    psaml_throw(aTHX_ PSAML_E_BAD_SIGNATURE,
                "CanonicalizationMethod is not exclusive c14n");

  /* 3: SignatureMethod from the table */
  sm = psaml_only_child(aTHX_ si, PSAML_NS_DSIG, "SignatureMethod");
  if (!sm) psaml_throw(aTHX_ PSAML_E_BAD_SIGNATURE,
                       "the SignedInfo has no single SignatureMethod");
  v = psaml_attr(aTHX_ sm, "Algorithm", &vl);
  if (!v) psaml_throw(aTHX_ PSAML_E_BAD_SIGNATURE,
                      "SignatureMethod has no Algorithm");
  {
    const char *jws_alg = NULL;
    for (i = 0; PSAML_SIGALGS[i].uri; i++) {
      STRLEN ul = strlen(PSAML_SIGALGS[i].uri);
      if (vl == ul && memEQ(v, PSAML_SIGALGS[i].uri, ul)) {
        jws_alg = PSAML_SIGALGS[i].alg;
        break;
      }
    }
    if (!jws_alg)
      psaml_throw(aTHX_ PSAML_E_ALG_REFUSED,
                  "SignatureMethod '%.*s' is not accepted", (int)vl, v);

    /* 4: exactly one Reference */
    ref = psaml_only_child(aTHX_ si, PSAML_NS_DSIG, "Reference");
    if (!ref)
      psaml_throw(aTHX_ PSAML_E_BAD_SIGNATURE,
                  "the SignedInfo does not have exactly one Reference");

    /* 4 and 5: the URI is '#' plus the PARENT's ID, and the node that id
     * resolves to is the SAME POINTER as the parent.
     *
     * The pointer comparison is the whole defence. Comparing the id
     * strings would pass for a document containing a second element that
     * merely carries the same-looking id, and comparing element names
     * would pass for any assertion at all. by_id was built at parse over
     * `ID` alone and a duplicate value was refused there, so the node it
     * returns is the only one, and requiring it to BE the signature's
     * parent closes the gap between what was signed and what will be
     * read. */
    v = psaml_attr(aTHX_ ref, "URI", &vl);
    if (!v || vl < 2 || v[0] != '#')
      psaml_throw(aTHX_ PSAML_E_BAD_SIGNATURE,
                  "the Reference URI is not a same-document '#id'");
    {
      const frx_node *target = F->by_id(ctx->doc, "ID", v + 1, vl - 1);
      if (!target || target != parent)
        psaml_throw(aTHX_ PSAML_E_BAD_SIGNATURE,
                    "the Reference names an element other than the one the "
                    "Signature is a child of");
    }

    /* 5: Transforms exactly enveloped-signature then exclusive c14n */
    trs = psaml_only_child(aTHX_ ref, PSAML_NS_DSIG, "Transforms");
    if (!trs)
      psaml_throw(aTHX_ PSAML_E_BAD_SIGNATURE, "the Reference has no Transforms");
    t1 = psaml_child(aTHX_ trs, PSAML_NS_DSIG, "Transform", NULL);
    t2 = t1 ? psaml_child(aTHX_ trs, PSAML_NS_DSIG, "Transform", t1) : NULL;
    if (!t1 || !t2 || psaml_child(aTHX_ trs, PSAML_NS_DSIG, "Transform", t2))
      psaml_throw(aTHX_ PSAML_E_BAD_SIGNATURE,
                  "Transforms must be exactly enveloped-signature then "
                  "exclusive c14n");
    if (!psaml_attr_is(aTHX_ t1, "Algorithm", PSAML_TR_ENVELOPED))
      psaml_throw(aTHX_ PSAML_E_BAD_SIGNATURE,
                  "the first Transform is not enveloped-signature");
    if (!(psaml_attr_is(aTHX_ t2, "Algorithm", PSAML_C14N_EXC)
       || psaml_attr_is(aTHX_ t2, "Algorithm", PSAML_C14N_EXC_WC)))
      psaml_throw(aTHX_ PSAML_E_BAD_SIGNATURE,
                  "the second Transform is not exclusive c14n. XPath, XSLT "
                  "and base64 transforms are refused: those are what let a "
                  "signature cover something other than what it appears to");

    /* 6: DigestMethod */
    dm = psaml_only_child(aTHX_ ref, PSAML_NS_DSIG, "DigestMethod");
    if (!dm) psaml_throw(aTHX_ PSAML_E_BAD_SIGNATURE,
                         "the Reference has no single DigestMethod");
    v = psaml_attr(aTHX_ dm, "Algorithm", &vl);
    {
      int bits = v ? psaml_digest_bits(v, vl, ctx->allow_sha1) : 0;
      SV *canon, *digest, *want;
      const frx_node *without[1];
      frx_c14n c;

      if (!bits)
        psaml_throw(aTHX_ PSAML_E_ALG_REFUSED,
                    "DigestMethod '%.*s' is not accepted",
                    (int)(v ? vl : 0), v ? v : "");

      /* 7: the digest, over c14n of the PARENT with the Signature
       * excluded - which is what `enveloped-signature` means - and the
       * TRANSFORM's PrefixList. */
      {
        char pbuf[512];
        const char *prefixes[PSAML_MAX_PREFIXES];
        int np = psaml_prefix_list(aTHX_ t2, pbuf, sizeof pbuf,
                                   prefixes, PSAML_MAX_PREFIXES);
        Zero(&c, 1, frx_c14n);
        c.mode = FRX_C14N_EXC;
        c.comments = 0;
        c.prefix_list = np ? prefixes : NULL;
        c.n_prefix = np;
        without[0] = sig;
        c.without = without;
        c.n_without = 1;
        canon = F->c14n(aTHX_ parent, &c);
      }
      if (!canon)
        psaml_throw(aTHX_ PSAML_E_BAD_SIGNATURE,
                    "the signed element would not canonicalise");
      sv_2mortal(canon);
      {
        STRLEN cl;
        const unsigned char *cp =
            (const unsigned char *)SvPVbyte(canon, cl);
        digest = bits == 160 ? J->sha1(aTHX_ cp, cl)
               : bits == 256 ? J->sha256(aTHX_ cp, cl)
               : NULL;
        if (!digest)
          psaml_throw(aTHX_ PSAML_E_ALG_REFUSED,
                      "DigestMethod SHA-%d is recognised but this build "
                      "cannot compute it: jws_abi carries sha256 and sha1 "
                      "and no other one-shot digest", bits);
        sv_2mortal(digest);
      }

      dv = psaml_only_child(aTHX_ ref, PSAML_NS_DSIG, "DigestValue");
      if (!dv) psaml_throw(aTHX_ PSAML_E_BAD_SIGNATURE,
                           "the Reference has no single DigestValue");
      {
        SV *raw = sv_2mortal(F->text(aTHX_ dv));
        STRLEN rl;
        const char *rp = SvPVbyte(raw, rl);
        SV *dec = sv_2mortal(newSV(psaml_b64_decoded_max(rl) + 1));
        STRLEN dl;
        SvPOK_on(dec);
        dl = psaml_b64_decode_xml((unsigned char *)SvPVX(dec), rp, rl);
        if (dl == (STRLEN)-1)
          psaml_throw(aTHX_ PSAML_E_BAD_SIGNATURE,
                      "the DigestValue is not base64");
        SvCUR_set(dec, dl);
        want = dec;
      }
      {
        STRLEN al, bl;
        const unsigned char *ap =
            (const unsigned char *)SvPVbyte(digest, al);
        const unsigned char *bp =
            (const unsigned char *)SvPVbyte(want, bl);
        if (!J->ct_eq(aTHX_ ap, al, bp, bl))
          psaml_throw(aTHX_ PSAML_E_BAD_DIGEST,
                      "the reference digest does not match the element");
      }
    }

    /* 8: the signature, over c14n of SignedInfo with the
     * CanonicalizationMethod's OWN PrefixList.
     *
     * A DIFFERENT InclusiveNamespaces from the transform's above.
     * Confusing the two is a signature that never verifies, with nothing
     * in any log to say why, and it is the single easiest mistake to
     * make in this file: both elements are called InclusiveNamespaces,
     * both carry a PrefixList, and they sit four lines apart in the
     * document. */
    {
      char pbuf[512];
      const char *prefixes[PSAML_MAX_PREFIXES];
      int np = psaml_prefix_list(aTHX_ cm, pbuf, sizeof pbuf,
                                 prefixes, PSAML_MAX_PREFIXES);
      frx_c14n c;
      SV *canon;
      STRLEN cl, sl;
      const unsigned char *cp;
      const char *sp;
      SV *sigval, *sigraw;
      SSize_t k, nkeys;
      int ok = 0;

      Zero(&c, 1, frx_c14n);
      c.mode = FRX_C14N_EXC;
      c.comments = psaml_attr_is(aTHX_ cm, "Algorithm", PSAML_C14N_EXC_WC);
      c.prefix_list = np ? prefixes : NULL;
      c.n_prefix = np;
      canon = F->c14n(aTHX_ si, &c);
      if (!canon)
        psaml_throw(aTHX_ PSAML_E_BAD_SIGNATURE,
                    "the SignedInfo would not canonicalise");
      sv_2mortal(canon);
      cp = (const unsigned char *)SvPVbyte(canon, cl);

      sv_node = psaml_only_child(aTHX_ sig, PSAML_NS_DSIG, "SignatureValue");
      if (!sv_node)
        psaml_throw(aTHX_ PSAML_E_BAD_SIGNATURE,
                    "the Signature has no single SignatureValue");
      sigval = sv_2mortal(F->text(aTHX_ sv_node));
      sp = SvPVbyte(sigval, sl);
      sigraw = sv_2mortal(newSV(psaml_b64_decoded_max(sl) + 1));
      SvPOK_on(sigraw);
      {
        STRLEN dl = psaml_b64_decode_xml((unsigned char *)SvPVX(sigraw),
                                         sp, sl);
        if (dl == (STRLEN)-1)
          psaml_throw(aTHX_ PSAML_E_BAD_SIGNATURE,
                      "the SignatureValue is not base64");
        SvCUR_set(sigraw, dl);
      }

      /* 9: KeyInfo is NOT trusted. It is whatever the sender put there.
       * Every key tried is one the deployer configured; any one passing
       * is enough, and all failing is bad_signature. */
      nkeys = ctx->keys ? (av_len(ctx->keys) + 1) : 0;
      if (!nkeys)
        psaml_throw(aTHX_ PSAML_E_NO_KEY,
                    "no signing key is configured for this provider");
      for (k = 0; k < nkeys && !ok; k++) {
        SV **e = av_fetch(ctx->keys, k, 0);
        STRLEN pl, gl;
        const char *pp;
        const unsigned char *gp;
        void *key;
        if (!e || !*e || !SvOK(*e)) continue;
        key = psaml_key_from_config(aTHX_ *e);
        if (!key) continue;
        PERL_UNUSED_VAR(pp);
        PERL_UNUSED_VAR(pl);
        gp = (const unsigned char *)SvPVbyte(sigraw, gl);
        ok = J->verify(aTHX_ key, jws_alg, strlen(jws_alg), cp, cl, gp, gl);
        J->key_free(aTHX_ key);
      }
      if (!ok)
        psaml_throw(aTHX_ PSAML_E_BAD_SIGNATURE,
                    "no configured key verifies the signature");
    }
  }
  return 1;
}

#endif /* PSAML_SIGNATURE_H */
