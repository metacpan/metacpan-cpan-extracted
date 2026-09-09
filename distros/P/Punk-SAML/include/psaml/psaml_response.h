#ifndef PSAML_RESPONSE_H
#define PSAML_RESPONSE_H

/* The checks, in order, and the identity.
 *
 * THE ORDER IS FIXED and it is not an optimisation: cheap before
 * expensive, structural before cryptographic, and THE SIGNATURE BEFORE
 * ANYTHING THE SIGNATURE PROTECTS IS READ. A verifier that reads the
 * Issuer to pick a key, or the Conditions to fail fast, has read
 * attacker-controlled bytes and acted on them before proving anyone sent
 * them.
 *
 * After psaml_signature.h has returned, the verified element is held in
 * ONE LOCAL and every read starts from that pointer. There is no second
 * lookup, no search from the document root, and no "find the assertion".
 *
 * Must be included after psaml_signature.h. */

#include "psaml_signature.h"
#include "psaml_time.h"
#include "psaml_request.h"

/* Everything one verification needs. Passed by pointer so the checks read
 * as a list rather than a function with fourteen arguments. */
typedef struct {
  const char *idp_name;
  const char *entity_id;      /* ours: the audience and the Issuer we expect */
  const char *idp_entity_id;  /* theirs: what Issuer must say */
  const char *acs_url;
  AV         *keys;
  IV          now;
  IV          skew;
  int         allow_sha1;
  int         allow_idp_initiated;
  const char *require_signed;
  SV         *flow_id;        /* the InResponseTo we expect, or NULL */
  SV         *seen_cb;        /* replay: a coderef, or NULL */
} psaml_checks;

/* ---- the document's lifetime ------------------------------------------ */

/* Every check below can throw, and a thrown error unwinds past any free
 * written after the call. So the document is registered for destruction
 * the moment it exists and released on the way out, which covers the
 * croak path and the return path with one mechanism.
 *
 * The exception, and it is a crash rather than a leak if it is got
 * wrong: frx_abi's doc_to_sv TAKES OWNERSHIP. A document handed to Perl
 * through it must not also be freed here, so the pointer is cleared
 * before handing it over and this destructor sees NULL. Nothing in this
 * phase does that; phase 7's operator tooling will. */
typedef struct { frx_doc *doc; } psaml_doc_guard;

static void psaml_doc_release(pTHX_ void *p) {
  psaml_doc_guard *g = (psaml_doc_guard *)p;
  if (g) {
    if (g->doc) psaml_frx(aTHX)->doc_free(aTHX_ g->doc);
    Safefree(g);
  }
}

/* ---- parsing ----------------------------------------------------------- */

/* `ID` and only `ID`.
 *
 * by_id is what the Reference check resolves through, so what is indexed
 * decides what a Reference can name. Indexing `Id` or `xml:id` as well
 * would let a signature point at an element the provider never marked,
 * and a duplicate value was already refused at parse, so this one name
 * is the whole of the index. */
static const char *const PSAML_ID_ATTRS[] = { "ID" };

PERL_STATIC_INLINE frx_doc *psaml_parse_response(pTHX_ SV *bytes,
                                                 psaml_doc_guard **guard) {
  const frx_abi *F = psaml_frx(aTHX);
  frx_opts o;
  SV *err = NULL;
  STRLEN n;
  const char *p = SvPVbyte(bytes, n);
  frx_doc *d;
  psaml_doc_guard *g;

  F->opts_init(&o);
  o.id_attrs   = PSAML_ID_ATTRS;
  o.n_id_attrs = 1;
  o.max_depth  = 100;          /* a Response is five deep; 100 is generous */

  d = F->parse(aTHX_ p, n, &o, &err);
  if (!d)
    psaml_throw(aTHX_ PSAML_E_XML_PARSE, "%s",
                err ? SvPV_nolen(err) : "the document would not parse");

  Newxz(g, 1, psaml_doc_guard);
  g->doc = d;
  SAVEDESTRUCTOR_X(psaml_doc_release, g);
  *guard = g;
  return d;
}

/* ---- small readers ---------------------------------------------------- */

PERL_STATIC_INLINE SV *psaml_node_text(pTHX_ const frx_node *n) {
  return n ? sv_2mortal(psaml_frx(aTHX)->text(aTHX_ n)) : NULL;
}

PERL_STATIC_INLINE int psaml_sv_is(pTHX_ SV *sv, const char *want) {
  STRLEN n;
  const char *p;
  if (!sv || !SvOK(sv)) return 0;
  p = SvPV_const(sv, n);
  return n == strlen(want) && memEQ(p, want, n);
}

PERL_STATIC_INLINE int psaml_str_is(const char *p, STRLEN n,
                                    const char *want) {
  STRLEN w = strlen(want);
  return p && n == w && memEQ(p, want, w);
}

/* An xs:dateTime attribute as epoch seconds; 0 and *have = 0 when absent,
 * a throw when present and unparseable. A timestamp we cannot read is not
 * a timestamp we may ignore: every one of them gates the login. */
PERL_STATIC_INLINE IV psaml_attr_time(pTHX_ const frx_node *n,
                                      const char *name, int *have) {
  STRLEN vl;
  const char *v = psaml_attr(aTHX_ n, name, &vl);
  IV t;
  *have = 0;
  if (!v) return 0;
  if (!psaml_time_parse(v, vl, &t))
    psaml_throw(aTHX_ PSAML_E_BAD_DATETIME,
                "%s is not an xs:dateTime this dist accepts: '%.*s'",
                name, (int)vl, v);
  *have = 1;
  return t;
}

/* ---- the identity ------------------------------------------------------ */

/* Push a value onto the arrayref at key, creating it.
 *
 * MERGED, never overwritten. A provider that sends the same Name twice is
 * not a provider making a mistake, it is how several of them send a
 * multi-valued attribute, and taking the last would silently drop a
 * group. */
PERL_STATIC_INLINE void psaml_push_attr(pTHX_ HV *into, const char *k,
                                        STRLEN kl, SV *val) {
  SV **e = hv_fetch(into, k, (I32)kl, 0);
  AV *av;
  if (e && *e && SvROK(*e) && SvTYPE(SvRV(*e)) == SVt_PVAV) {
    av = (AV *)SvRV(*e);
  }
  else {
    av = newAV();
    (void)hv_store(into, k, (I32)kl, newRV_noinc((SV *)av), 0);
  }
  av_push(av, val);
}

PERL_STATIC_INLINE void psaml_read_attributes(pTHX_ const frx_node *assertion,
                                              HV *attrs, HV *friendly) {
  const frx_abi *F = psaml_frx(aTHX);
  const frx_node *stmt = NULL;
  while ((stmt = F->find(assertion, PSAML_NS_ASSERTION,
                         "AttributeStatement", stmt)) != NULL) {
    const frx_node *at = NULL;
    while ((at = F->find(stmt, PSAML_NS_ASSERTION, "Attribute", at)) != NULL) {
      STRLEN nl, fl;
      const char *nm = psaml_attr(aTHX_ at, "Name", &nl);
      const char *fr = psaml_attr(aTHX_ at, "FriendlyName", &fl);
      const frx_node *val = NULL;
      if (!nm) continue;
      while ((val = F->find(at, PSAML_NS_ASSERTION,
                            "AttributeValue", val)) != NULL) {
        /* xsi:type is ignored and a NameID-shaped value is just its text:
         * an attribute value's type is the provider's business and the
         * application wants the string either way. An empty value is
         * kept as an empty string rather than dropped, so the count of
         * values a provider sent is the count the application sees. */
        SV *t = F->text(aTHX_ val);
        psaml_push_attr(aTHX_ attrs, nm, nl, t);
        if (fr && fl)
          psaml_push_attr(aTHX_ friendly, fr, fl,
                          newSVsv(t));
      }
    }
  }
}

/* ---- the verification -------------------------------------------------- */

/* Verify a Response and return the identity as a +1 hashref.
 *
 * `bytes` is the DECODED XML; the base64 and the size cap were phase 5's
 * psaml_decode_field, because those belong to the transport. */
PERL_STATIC_INLINE SV *psaml_verify_response(pTHX_ SV *bytes,
                                             psaml_checks *o) {
  const frx_abi *F = psaml_frx(aTHX);
  psaml_doc_guard *guard = NULL;
  frx_doc *doc;
  const frx_node *root, *assertion, *conds, *subject, *nameid, *authn;
  psaml_verify_ctx vctx;
  int sig_on_response = 0, sig_on_assertion = 0;
  HV *out;
  STRLEN vl;
  const char *v;

  doc = psaml_parse_response(aTHX_ bytes, &guard);

  /* ---- structure, before any cryptography --------------------------- */

  root = F->root(doc);
  {
    STRLEN nsl, ll;
    const char *ns = F->ns(root, &nsl);
    const char *lo = F->local(root, &ll);
    if (!psaml_str_is(ns, nsl, PSAML_NS_PROTOCOL)
        || !psaml_str_is(lo, ll, "Response"))
      psaml_throw(aTHX_ PSAML_E_XML_SHAPE,
                  "the root element is not samlp:Response");
  }
  if (!psaml_attr_is(aTHX_ root, "Version", "2.0"))
    psaml_throw(aTHX_ PSAML_E_XML_SHAPE, "the Response is not Version 2.0");

  /* Status, before anything else is looked at: a provider that refused
   * says so here, and the nested code plus any StatusMessage go in the
   * message because a bare `Requester` with no detail is what a provider
   * returns when the ACS URL is wrong, and that is the commonest
   * first-integration failure there is. */
  {
    const frx_node *status = psaml_only_child(aTHX_ root, PSAML_NS_PROTOCOL,
                                              "Status");
    const frx_node *code = status
      ? psaml_only_child(aTHX_ status, PSAML_NS_PROTOCOL, "StatusCode") : NULL;
    if (!code)
      psaml_throw(aTHX_ PSAML_E_XML_SHAPE, "the Response has no StatusCode");
    v = psaml_attr(aTHX_ code, "Value", &vl);
    if (!psaml_str_is(v, vl, "urn:oasis:names:tc:SAML:2.0:status:Success")) {
      const frx_node *sub = psaml_child(aTHX_ code, PSAML_NS_PROTOCOL,
                                        "StatusCode", NULL);
      const frx_node *msg = psaml_child(aTHX_ status, PSAML_NS_PROTOCOL,
                                        "StatusMessage", NULL);
      STRLEN sl = 0;
      const char *sp = sub ? psaml_attr(aTHX_ sub, "Value", &sl) : NULL;
      SV *m = msg ? psaml_node_text(aTHX_ msg) : NULL;
      psaml_throw(aTHX_ PSAML_E_STATUS,
                  "the provider returned %.*s%s%.*s%s%s",
                  (int)vl, v ? v : "",
                  sp ? " / " : "", (int)sl, sp ? sp : "",
                  m && SvCUR(m) ? ": " : "",
                  m && SvCUR(m) ? SvPV_nolen(m) : "");
    }
  }

  /* EncryptedAssertion is refused and never decrypted. XML-Enc is a
   * second cryptographic surface with its own padding-oracle history, and
   * the fix is at the other end, so the message names it. */
  if (psaml_child(aTHX_ root, PSAML_NS_ASSERTION, "EncryptedAssertion", NULL))
    psaml_throw(aTHX_ PSAML_E_ENCRYPTED,
                "this Response carries an EncryptedAssertion. Turn assertion "
                "encryption off for this application at the identity "
                "provider; the transport is already TLS");

  assertion = psaml_only_child(aTHX_ root, PSAML_NS_ASSERTION, "Assertion");
  if (!assertion)
    psaml_throw(aTHX_ PSAML_E_XML_SHAPE,
                "the Response does not carry exactly one Assertion");

  /* ---- the signatures ------------------------------------------------ */

  vctx.doc        = doc;
  vctx.keys       = o->keys;
  vctx.allow_sha1 = o->allow_sha1;

  sig_on_response  = psaml_verify_element(aTHX_ &vctx, root);
  sig_on_assertion = psaml_verify_element(aTHX_ &vctx, assertion);

  /* `either` is the default because providers differ on which they sign
   * by default and a fresh integration should not fail on that. A
   * verified signature on the Response covers the Assertion inside it:
   * the reference digest is over the whole subtree. */
  {
    const char *r = o->require_signed ? o->require_signed : "either";
    int ok = strEQ(r, "both")      ? (sig_on_response && sig_on_assertion)
           : strEQ(r, "response")  ? sig_on_response
           : strEQ(r, "assertion") ? sig_on_assertion
           : (sig_on_response || sig_on_assertion);
    if (!ok)
      psaml_throw(aTHX_ PSAML_E_NO_SIGNATURE,
                  "require_signed is '%s' and that is not satisfied "
                  "(Response %s, Assertion %s)", r,
                  sig_on_response  ? "signed" : "unsigned",
                  sig_on_assertion ? "signed" : "unsigned");
  }

  /* ---- and only now is anything read -------------------------------- */

  /* Issuer, from the verified element. When only the Response is signed,
   * its signature covers the Assertion, so the Assertion's Issuer is
   * equally proven; when only the Assertion is signed, the Response's
   * Issuer is not, and is not checked. */
  {
    const frx_node *iss = psaml_only_child(aTHX_ assertion,
                                           PSAML_NS_ASSERTION, "Issuer");
    SV *t = psaml_node_text(aTHX_ iss);
    if (!t || !psaml_sv_is(aTHX_ t, o->idp_entity_id))
      psaml_throw(aTHX_ PSAML_E_UNKNOWN_ISSUER,
                  "the Assertion's Issuer is not this provider's entity id");
  }

  /* Destination, when present, must be our ACS URL. */
  v = psaml_attr(aTHX_ root, "Destination", &vl);
  if (v && !psaml_str_is(v, vl, o->acs_url))
    psaml_throw(aTHX_ PSAML_E_BAD_DESTINATION,
                "the Response's Destination is not this application's "
                "assertion consumer URL");

  /* Conditions. skew applies on both edges, and 120 seconds is the
   * default because providers' clocks are worse than anyone expects. */
  conds = psaml_only_child(aTHX_ assertion, PSAML_NS_ASSERTION, "Conditions");
  if (conds) {
    int have;
    IV nb = psaml_attr_time(aTHX_ conds, "NotBefore", &have);
    if (have && nb > o->now + o->skew)
      psaml_throw(aTHX_ PSAML_E_NOT_YET_VALID,
                  "the Assertion is not valid until later");
    {
      IV na = psaml_attr_time(aTHX_ conds, "NotOnOrAfter", &have);
      if (have && na <= o->now - o->skew)
        psaml_throw(aTHX_ PSAML_E_EXPIRED, "the Assertion has expired");
    }
    /* the audience must name us; any one AudienceRestriction naming the
     * entity id is enough, and none of them naming it is a refusal */
    {
      const frx_node *ar = NULL;
      int found = 0, any = 0;
      while ((ar = F->find(conds, PSAML_NS_ASSERTION,
                           "AudienceRestriction", ar)) != NULL) {
        const frx_node *aud = NULL;
        any = 1;
        while ((aud = F->find(ar, PSAML_NS_ASSERTION, "Audience",
                              aud)) != NULL) {
          SV *t = psaml_node_text(aTHX_ aud);
          if (t && psaml_sv_is(aTHX_ t, o->entity_id)) { found = 1; break; }
        }
        if (found) break;
      }
      if (any && !found)
        psaml_throw(aTHX_ PSAML_E_BAD_AUDIENCE,
                    "no AudienceRestriction names this application");
    }
  }

  /* Subject: a NameID, and a bearer SubjectConfirmation whose Recipient
   * is our ACS URL and whose window has not closed. */
  subject = psaml_only_child(aTHX_ assertion, PSAML_NS_ASSERTION, "Subject");
  if (!subject)
    psaml_throw(aTHX_ PSAML_E_XML_SHAPE, "the Assertion has no single Subject");
  nameid = psaml_only_child(aTHX_ subject, PSAML_NS_ASSERTION, "NameID");
  if (!nameid)
    psaml_throw(aTHX_ PSAML_E_XML_SHAPE, "the Subject has no single NameID");

  {
    const frx_node *sc = NULL;
    const frx_node *good = NULL;
    SV *in_response_to = NULL;
    while ((sc = F->find(subject, PSAML_NS_ASSERTION,
                         "SubjectConfirmation", sc)) != NULL) {
      const frx_node *scd;
      int have;
      if (!psaml_attr_is(aTHX_ sc, "Method",
                         "urn:oasis:names:tc:SAML:2.0:cm:bearer"))
        continue;
      scd = psaml_child(aTHX_ sc, PSAML_NS_ASSERTION,
                        "SubjectConfirmationData", NULL);
      if (!scd) continue;
      v = psaml_attr(aTHX_ scd, "Recipient", &vl);
      if (v && !psaml_str_is(v, vl, o->acs_url))
        psaml_throw(aTHX_ PSAML_E_BAD_DESTINATION,
                    "the SubjectConfirmationData Recipient is not this "
                    "application's assertion consumer URL");
      {
        IV na = psaml_attr_time(aTHX_ scd, "NotOnOrAfter", &have);
        if (have && na <= o->now - o->skew)
          psaml_throw(aTHX_ PSAML_E_EXPIRED,
                      "the SubjectConfirmationData window has closed");
      }
      v = psaml_attr(aTHX_ scd, "InResponseTo", &vl);
      if (v) in_response_to = sv_2mortal(newSVpvn(v, vl));
      good = sc;
      break;
    }
    if (!good)
      psaml_throw(aTHX_ PSAML_E_XML_SHAPE,
                  "the Subject has no bearer SubjectConfirmation");

    /* InResponseTo against the flow. Both directions matter: a response
     * to a request we did not send is unsolicited, and a response naming
     * a different request is not ours. */
    if (o->flow_id && SvOK(o->flow_id)) {
      if (!in_response_to)
        psaml_throw(aTHX_ PSAML_E_BAD_IN_RESPONSE,
                    "a login was started but the Response answers nothing");
      if (!sv_eq(in_response_to, o->flow_id))
        psaml_throw(aTHX_ PSAML_E_BAD_IN_RESPONSE,
                    "the Response answers a different request");
    }
    else if (in_response_to) {
      psaml_throw(aTHX_ PSAML_E_BAD_IN_RESPONSE,
                  "the Response answers a request this application has no "
                  "record of starting");
    }
    else if (!o->allow_idp_initiated) {
      /* Off by default: an attacker who gets a victim's browser to POST a
       * valid assertion for the ATTACKER'S account signs the victim into
       * the attacker's account, and everything the victim then does is
       * visible to the attacker. */
      psaml_throw(aTHX_ PSAML_E_UNSOLICITED,
                  "this is an identity-provider-initiated login and "
                  "allow_idp_initiated is off");
    }
  }

  /* An AuthnStatement is what makes this an authentication rather than an
   * attribute query. */
  authn = psaml_child(aTHX_ assertion, PSAML_NS_ASSERTION,
                      "AuthnStatement", NULL);
  if (!authn)
    psaml_throw(aTHX_ PSAML_E_XML_SHAPE, "the Assertion has no AuthnStatement");

  /* Replay. The caller supplies the store, because whether it is shared
   * across the worker pool is the application's decision and this
   * function has no application. */
  v = psaml_attr(aTHX_ assertion, "ID", &vl);
  if (o->seen_cb && SvOK(o->seen_cb) && v) {
    dSP;
    int count;
    SV *id = sv_2mortal(newSVpvn(v, vl));
    int seen;
    ENTER; SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(id);
    PUTBACK;
    count = call_sv(o->seen_cb, G_SCALAR);
    SPAGAIN;
    seen = count > 0 ? SvTRUE(TOPs) : 0;
    if (count > 0) (void)POPs;
    PUTBACK;
    FREETMPS; LEAVE;
    if (seen)
      psaml_throw(aTHX_ PSAML_E_REPLAY,
                  "this assertion has been presented before");
  }

  /* ---- the identity, from the verified element and no other ---------- */

  out = newHV();
  (void)hv_stores(out, "idp", newSVpv(o->idp_name ? o->idp_name : "", 0));
  if (v) (void)hv_stores(out, "assertion_id", newSVpvn(v, vl));
  {
    SV *t = psaml_node_text(aTHX_ nameid);
    (void)hv_stores(out, "name_id", t ? newSVsv(t) : newSVpvs(""));
  }
  v = psaml_attr(aTHX_ nameid, "Format", &vl);
  if (v) (void)hv_stores(out, "name_id_format", newSVpvn(v, vl));
  v = psaml_attr(aTHX_ authn, "SessionIndex", &vl);
  if (v) (void)hv_stores(out, "session_index", newSVpvn(v, vl));
  {
    int have;
    IV t = psaml_attr_time(aTHX_ authn, "AuthnInstant", &have);
    if (have) (void)hv_stores(out, "authn_instant", newSViv(t));
    if (conds) {
      t = psaml_attr_time(aTHX_ conds, "NotOnOrAfter", &have);
      if (have) (void)hv_stores(out, "not_on_or_after", newSViv(t));
    }
  }
  {
    HV *attrs = newHV(), *friendly = newHV();
    psaml_read_attributes(aTHX_ assertion, attrs, friendly);
    (void)hv_stores(out, "attributes", newRV_noinc((SV *)attrs));
    (void)hv_stores(out, "friendly",   newRV_noinc((SV *)friendly));
  }
  /* the bytes as received, for an application that must keep an audit
   * record of what it accepted */
  (void)hv_stores(out, "raw", newSVsv(bytes));

  return newRV_noinc((SV *)out);
}

#endif /* PSAML_RESPONSE_H */
