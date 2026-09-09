#ifndef PSAML_BOOT_H
#define PSAML_BOOT_H

/* Boot: the options, the three keywords, the two helpers, and what each
 * records on the application hash.
 *
 * This header builds the SURFACE. It mounts no routes, writes no cookie
 * and consumes no assertion: phase 8 reads what is recorded here and
 * mounts the four routes. The split is deliberate and it is what makes
 * this phase testable with no HTTP at all.
 *
 * State lives as keys on the application's own hash rather than in a
 * struct, which is what punk_sitemap.h and pfeed_*.h do and for the same
 * reason: the application is already the thing whose lifetime this state
 * shares, and a struct would be a second one to keep in step with it.
 *
 *   punk_saml.opts       the validated option hash
 *   punk_saml.idps       HV of name -> the provider's config
 *   punk_saml.idp_order  AV of names, in declaration order
 *   punk_saml.login      HV of path, on_login, on_error
 *   punk_saml.mount      the normalised login mount
 *   punk_saml.acs        the assertion consumer URL, at on_compile
 *   punk_saml.entity_id  the entity id, at on_compile
 *
 * Must be included after psaml_reg.h. */

#include "psaml_reg.h"
#include "psaml_error.h"
#include "psaml_idp.h"
#include "psaml_metadata.h"
#include "psaml_flow.h"
#include "psaml_request.h"

static const char *const PSAML_OPTS[] = {
    "secret", "entity_id", "prefix", "key", "cert",
    "sign_requests", "sign_metadata", "require_signed", "skew",
    "flow_ttl", "max_response", "allow_sha1", "allow_idp_initiated",
    "default_to", "name_id_format", "force_authn", "metadata",
    "metadata_refresh", "render", NULL
};

static const char *const PSAML_IDP_OPTS[] = {
    "metadata", "entity_id", "sso_url", "certs", NULL
};

static const char *const PSAML_LOGIN_OPTS[] = {
    "on_login", "on_error", NULL
};

/* ---- the options ------------------------------------------------------ */

/* Validated and normalised at the `plugin` line, with two exceptions that
 * cannot be settled until on_compile: entity_id, which defaults to the
 * metadata URL and so needs `host`, and the ACS URL, which needs `host`
 * and the login mount. `host` may be declared on either side of the
 * plugin line, so neither may be read here. */
PERL_STATIC_INLINE HV *psaml_opts(pTHX_ SV *app, SV *optsv) {
  HV *in  = psaml_is_hash(aTHX_ optsv) ? (HV *)SvRV(optsv) : NULL;
  HV *out = newHV();
  SV *v;

  psaml_check_opts(aTHX_ "option", in, PSAML_OPTS);

  /* secret. Croaks here rather than at the first login, because a plugin
   * that mints one per worker fails one login in four the moment a
   * redirect lands on a worker other than the one that started it, and
   * that failure looks like an intermittent identity-provider fault
   * rather than a missing option. Punk-Push and Punk-Challenge both paid
   * for this lesson already. A list is accepted so a key can be rotated
   * with both live. */
  v = psaml_hget(aTHX_ in, "secret");
  if (!v || !SvOK(v) || (!SvROK(v) && !SvCUR(v)))
    croak("%s: `secret` is required - it signs the flow cookie, and a "
          "secret minted per worker fails one login in four. Generate one "
          "with `punk saml key` and keep it with the application's other "
          "secrets", PSAML_WHO);
  if (psaml_is_array(aTHX_ v)) {
    AV *keys = (AV *)SvRV(v);
    if (av_len(keys) < 0)
      croak("%s: `secret` was an empty list", PSAML_WHO);
    (void)hv_stores(out, "secret", newSVsv(v));
  }
  else if (SvROK(v)) {
    croak("%s: `secret` takes a string, or a list of them to rotate",
          PSAML_WHO);
  }
  else {
    (void)hv_stores(out, "secret", newSVsv(v));
  }

  /* prefix */
  v = psaml_hget(aTHX_ in, "prefix");
  (void)hv_stores(out, "prefix",
                  (v && SvOK(v) && SvCUR(v)) ? newSVsv(v)
                                             : newSVpvs("/saml"));

  /* require_signed. The whole point of the plugin is the signature, so
   * an unrecognised word here is refused rather than defaulted: a
   * misspelling that quietly meant `either` would be a weaker check than
   * the deployer asked for, silently. */
  {
    SV *r = psaml_hget(aTHX_ in, "require_signed");
    const char *rp = "either";
    STRLEN rl = 6;
    if (r && SvOK(r)) rp = SvPV_const(r, rl);
    if (!((rl == 9 && memEQ(rp, "assertion", 9))
       || (rl == 8 && memEQ(rp, "response", 8))
       || (rl == 6 && memEQ(rp, "either", 6))
       || (rl == 4 && memEQ(rp, "both", 4))))
      croak("%s: `require_signed` takes assertion, response, either or "
            "both, not '%.*s'", PSAML_WHO, (int)rl, rp);
    (void)hv_stores(out, "require_signed", newSVpvn(rp, rl));
  }

  (void)hv_stores(out, "skew",    newSViv(psaml_opt_uv(aTHX_ in, "skew", 120)));
  (void)hv_stores(out, "flow_ttl",
                  newSViv(psaml_opt_uv(aTHX_ in, "flow_ttl", 600)));
  (void)hv_stores(out, "max_response",
                  newSViv(psaml_opt_uv(aTHX_ in, "max_response", 262144)));
  (void)hv_stores(out, "metadata_refresh",
                  newSViv(psaml_opt_uv(aTHX_ in, "metadata_refresh", 3600)));

  /* the booleans, normalised so nothing downstream reads a string */
  {
    static const char *const flags[] = {
      "sign_requests", "sign_metadata", "allow_sha1",
      "allow_idp_initiated", "force_authn", NULL
    };
    int i;
    for (i = 0; flags[i]; i++)
      (void)hv_store(out, flags[i], (I32)strlen(flags[i]),
                     newSViv(psaml_opt_bool(aTHX_ in, flags[i], 0)), 0);
    /* metadata defaults ON: an SP that does not publish its metadata has
     * to be configured by hand at the other end, every time */
    (void)hv_stores(out, "metadata",
                    newSViv(psaml_opt_bool(aTHX_ in, "metadata", 1)));
  }

  /* the pass-through strings and callbacks */
  {
    static const char *const keep[] = {
      "entity_id", "key", "cert", "default_to", "name_id_format",
      "render", NULL
    };
    int i;
    for (i = 0; keep[i]; i++) {
      SV *k = psaml_hget(aTHX_ in, keep[i]);
      if (k && SvOK(k))
        (void)hv_store(out, keep[i], (I32)strlen(keep[i]), newSVsv(k), 0);
    }
    if (!hv_exists(out, "default_to", 10))
      (void)hv_stores(out, "default_to", newSVpvs("/"));
  }

  /* An option that silently does nothing is worse than one that refuses:
   * a deployer who wrote sign_requests and got unsigned requests has been
   * told the opposite of the truth by their own configuration. */
  if (SvTRUE(*hv_fetchs(out, "sign_requests", 0)) && !hv_exists(out, "key", 3))
    croak("%s: `sign_requests` needs `key`, the SP private key in PEM",
          PSAML_WHO);
  if (SvTRUE(*hv_fetchs(out, "sign_metadata", 0))
      && !(hv_exists(out, "key", 3) && hv_exists(out, "cert", 4)))
    croak("%s: `sign_metadata` needs `key` and `cert`", PSAML_WHO);

  {
    SV *r = psaml_hget(aTHX_ out, "render");
    if (r && SvROK(r) && !psaml_is_code(aTHX_ r))
      croak("%s: `render` takes a coderef or the name of a context method",
            PSAML_WHO);
  }

  PERL_UNUSED_ARG(app);
  return out;
}

/* ---- host ------------------------------------------------------------- */

/* The declared origin, which must exist and must be https.
 *
 * The request is never consulted. The assertion consumer URL derives from
 * this and the identity provider compares it against what it was
 * configured with character for character, so a plugin that guessed the
 * host from a request header would be letting the request choose which
 * URL counts as this application.
 *
 * https because the phase-8 flow cookie carries SameSite=None, which is
 * the only value a browser sends on the cross-site POST from the
 * provider, and which browsers drop without Secure. The croak is loud
 * because the alternative is silent: a plain-http deployment boots
 * happily and then fails at every ACS with `unsolicited`, with nothing in
 * the log to say why. */
PERL_STATIC_INLINE SV *psaml_host(pTHX_ SV *app) {
  SV *host = psaml_can(aTHX_ app, "host")
           ? sv_2mortal(psaml_call(aTHX_ app, "host", NULL, 0)) : NULL;
  STRLEN hl = 0;
  const char *hp;
  if (!host || !SvOK(host) || !SvCUR(host))
    croak("%s: this application has no `host`. The assertion consumer URL "
          "derives from it and the identity provider compares that URL "
          "character for character, so it cannot be guessed from a "
          "request", PSAML_WHO);
  hp = SvPV_const(host, hl);
  if (!(hl > 8 && memEQ(hp, "https://", 8)))
    croak("%s: `host` must be https, not '%.*s'. The flow cookie is "
          "SameSite=None, which is the only value sent on the cross-site "
          "POST from the provider, and which browsers drop without "
          "Secure. Over http every login fails at the ACS as "
          "`unsolicited`", PSAML_WHO, (int)hl, hp);
  return host;
}

/* An origin and a path joined with exactly one slash between them. */
PERL_STATIC_INLINE SV *psaml_join_url(pTHX_ SV *base, const char *path) {
  STRLEN bl;
  const char *bp = SvPV_const(base, bl);
  SV *out;
  while (bl && bp[bl - 1] == '/') bl--;
  out = newSVpvn(bp, bl);
  if (*path != '/') sv_catpvs(out, "/");
  sv_catpv(out, path);
  return out;
}

/* The login mount, normalised: a leading slash, no trailing one. The
 * recorded value and the routes phase 8 mounts must be the same string,
 * so there is one place that decides what it looks like. */
PERL_STATIC_INLINE SV *psaml_mount_path(pTHX_ SV *path) {
  STRLEN pl;
  const char *pp;
  SV *out;
  if (!path || !SvOK(path) || !SvCUR(path))
    croak("%s: saml_login needs a path to mount under", PSAML_WHO);
  pp = SvPV_const(path, pl);
  while (pl > 1 && pp[pl - 1] == '/') pl--;
  out = newSVpvs("");
  if (*pp != '/') sv_catpvs(out, "/");
  sv_catpvn(out, pp, pl);
  return out;
}

/* ---- saml_idp --------------------------------------------------------- */

XS_INTERNAL(psaml_kw_idp);
XS_INTERNAL(psaml_kw_idp) {
  dXSARGS;
  SV *app = psaml_cap_slot(aTHX_ cv, 0);
  HV *cfg, *in;
  HV *idps;
  AV *order;
  SV *name, *conf;
  SV *meta, *ent, *sso, *certs;
  STRLEN nl;
  const char *np;

  if (!app) { PERL_UNUSED_VAR(ax); XSRETURN_EMPTY; }
  if (items < 1 || !SvOK(ST(0)) || SvROK(ST(0)))
    croak("%s: saml_idp takes a name and a hashref", PSAML_WHO);
  name = ST(0);
  np = SvPV_const(name, nl);
  if (items < 2 || !psaml_is_hash(aTHX_ ST(1)))
    croak("%s: saml_idp '%.*s' needs a hashref of settings",
          PSAML_WHO, (int)nl, np);
  in = (HV *)SvRV(ST(1));
  psaml_check_opts(aTHX_ "saml_idp setting", in, PSAML_IDP_OPTS);

  meta  = psaml_hget(aTHX_ in, "metadata");
  ent   = psaml_hget(aTHX_ in, "entity_id");
  sso   = psaml_hget(aTHX_ in, "sso_url");
  certs = psaml_hget(aTHX_ in, "certs");

  /* The two forms are exclusive and giving both croaks, rather than
   * letting one silently win. Which one won would decide which key
   * verifies the assertion, and a deployer who supplied both believes
   * whichever they wrote last. */
  if (meta && SvOK(meta) && (ent || sso || certs))
    croak("%s: saml_idp '%.*s' gives both `metadata` and the explicit "
          "entity_id/sso_url/certs. They are exclusive: one of them would "
          "decide which key verifies an assertion, and it would not be "
          "obvious which", PSAML_WHO, (int)nl, np);
  if (!(meta && SvOK(meta))) {
    if (!(ent && SvOK(ent)) || !(sso && SvOK(sso)) || !certs)
      croak("%s: saml_idp '%.*s' needs either `metadata`, or all three of "
            "`entity_id`, `sso_url` and `certs`", PSAML_WHO, (int)nl, np);
  }

  idps  = (HV *)SvRV(psaml_app_hash(aTHX_ app, PSAML_K_IDPS));
  order = (AV *)SvRV(psaml_app_array(aTHX_ app, PSAML_K_IDPORDER));

  if (hv_exists(idps, np, (I32)nl))
    croak("%s: saml_idp '%.*s' is declared twice. Two providers under one "
          "name is a configuration nobody meant", PSAML_WHO, (int)nl, np);

  cfg = newHV();
  (void)hv_stores(cfg, "name", newSVsv(name));
  if (meta && SvOK(meta)) (void)hv_stores(cfg, "metadata", newSVsv(meta));
  if (ent && SvOK(ent))   (void)hv_stores(cfg, "entity_id", newSVsv(ent));
  if (sso && SvOK(sso))   (void)hv_stores(cfg, "sso_url", newSVsv(sso));
  if (certs) {
    /* normalised to an arrayref here, so phase 7 reads one shape */
    if (psaml_is_array(aTHX_ certs)) {
      (void)hv_stores(cfg, "certs", newSVsv(certs));
    }
    else if (SvROK(certs)) {
      croak("%s: saml_idp '%.*s': `certs` takes a PEM or an arrayref of "
            "them", PSAML_WHO, (int)nl, np);
    }
    else {
      AV *av = newAV();
      av_push(av, newSVsv(certs));
      (void)hv_stores(cfg, "certs", newRV_noinc((SV *)av));
    }
  }
  conf = newRV_noinc((SV *)cfg);
  (void)hv_store(idps, np, (I32)nl, conf, 0);
  av_push(order, newSVsv(name));

  /* Nothing is fetched here. `metadata` is a URL and this is the plugin
   * line: a network call at compile time would make an application that
   * cannot boot when the provider is briefly down. Phase 7 fetches at
   * on_compile. */
  XSRETURN_EMPTY;
}

/* ---- saml_login ------------------------------------------------------- */

XS_INTERNAL(psaml_kw_login);
XS_INTERNAL(psaml_kw_login) {
  dXSARGS;
  SV *app = psaml_cap_slot(aTHX_ cv, 0);
  HV *in, *rec;
  SV *on_login, *on_error, *mount;

  if (!app) { PERL_UNUSED_VAR(ax); XSRETURN_EMPTY; }

  /* Declared once. Any number of providers live under one mount, and a
   * second mount would mean two ACS URLs, only one of which any given
   * provider was configured with. */
  if (psaml_app_get(aTHX_ app, PSAML_K_LOGIN))
    croak("%s: saml_login is declared twice. One application has one login "
          "mount; every saml_idp lives under it", PSAML_WHO);

  if (items < 1)
    croak("%s: saml_login takes a path and a hashref", PSAML_WHO);
  mount = psaml_mount_path(aTHX_ ST(0));
  if (items < 2 || !psaml_is_hash(aTHX_ ST(1))) {
    SvREFCNT_dec(mount);
    croak("%s: saml_login needs a hashref with `on_login`", PSAML_WHO);
  }
  in = (HV *)SvRV(ST(1));
  psaml_check_opts(aTHX_ "saml_login setting", in, PSAML_LOGIN_OPTS);

  on_login = psaml_hget(aTHX_ in, "on_login");
  if (!psaml_is_code(aTHX_ on_login)) {
    SvREFCNT_dec(mount);
    croak("%s: saml_login needs `on_login`, a coderef called with the "
          "context and the verified identity", PSAML_WHO);
  }
  on_error = psaml_hget(aTHX_ in, "on_error");
  if (on_error && SvOK(on_error) && !psaml_is_code(aTHX_ on_error)) {
    SvREFCNT_dec(mount);
    croak("%s: saml_login's `on_error` takes a coderef", PSAML_WHO);
  }

  rec = newHV();
  (void)hv_stores(rec, "path", SvREFCNT_inc_simple_NN(mount));
  (void)hv_stores(rec, "on_login", newSVsv(on_login));
  if (on_error && SvOK(on_error))
    (void)hv_stores(rec, "on_error", newSVsv(on_error));

  psaml_app_set(aTHX_ app, PSAML_K_LOGIN, newRV_noinc((SV *)rec));
  psaml_app_set(aTHX_ app, PSAML_K_MOUNT, mount);

  /* No routes here. Phase 8 mounts them at on_compile, where `host` is
   * certainly declared and the ACS URL can be computed once. */
  XSRETURN_EMPTY;
}

/* ---- the helpers ------------------------------------------------------ */

XS_INTERNAL(psaml_help_idps);
XS_INTERNAL(psaml_help_idps) {
  dXSARGS;
  SV *app = psaml_cap_slot(aTHX_ cv, 0);
  SV *ordsv = app ? psaml_app_get(aTHX_ app, PSAML_K_IDPORDER) : NULL;
  AV *order;
  SSize_t i, n;
  PERL_UNUSED_VAR(items);
  if (!ordsv || !SvROK(ordsv)) XSRETURN_EMPTY;
  order = (AV *)SvRV(ordsv);
  n = av_len(order) + 1;
  SP -= items;
  EXTEND(SP, n);
  for (i = 0; i < n; i++) {
    SV **e = av_fetch(order, i, 0);
    PUSHs(sv_2mortal(newSVsv(e && *e ? *e : &PL_sv_undef)));
  }
  PUTBACK;
  return;
}

XS_INTERNAL(psaml_help_url);
XS_INTERNAL(psaml_help_url) {
  dXSARGS;
  SV *app = psaml_cap_slot(aTHX_ cv, 0);
  SV *mount, *idps, *out;
  STRLEN nl;
  const char *np;
  SSize_t i;

  if (!app || items < 2)
    croak("%s: saml_url takes a provider name", PSAML_WHO);
  if (!SvOK(ST(1)) || SvROK(ST(1)))
    croak("%s: saml_url takes a provider name", PSAML_WHO);
  np = SvPV_const(ST(1), nl);

  idps  = psaml_app_get(aTHX_ app, PSAML_K_IDPS);
  mount = psaml_app_get(aTHX_ app, PSAML_K_MOUNT);
  if (!mount)
    croak("%s: saml_url needs a saml_login mount", PSAML_WHO);

  /* An unknown provider croaks naming the configured ones. This is
   * called from a template, and the alternative to a croak is an anchor
   * with an href that 404s, which looks like a broken provider rather
   * than a typo in the page. */
  if (!(idps && SvROK(idps) && hv_exists((HV *)SvRV(idps), np, (I32)nl))) {
    SV *known = sv_2mortal(newSVpvs(""));
    SV *ordsv = psaml_app_get(aTHX_ app, PSAML_K_IDPORDER);
    if (ordsv && SvROK(ordsv)) {
      AV *order = (AV *)SvRV(ordsv);
      for (i = 0; i <= av_len(order); i++) {
        SV **e = av_fetch(order, i, 0);
        if (i) sv_catpvs(known, ", ");
        if (e && *e) sv_catsv(known, *e);
      }
    }
    croak("%s: no saml_idp named '%.*s' (configured: %s)", PSAML_WHO,
          (int)nl, np, SvCUR(known) ? SvPV_nolen(known) : "none");
  }

  out = newSVsv(mount);
  sv_catpvs(out, "/login/");
  sv_catpvn(out, np, nl);

  /* `to` is recorded on the query string here and goes through
   * $c->safe_path in phase 8, where it is used. It is not sanitised
   * twice: one place decides, and that place is the one that acts on it. */
  if (items > 2) {
    int j;
    int first = 1;
    for (j = 2; j + 1 < items; j += 2) {
      STRLEN kl, vl;
      const char *kp = SvPV_const(ST(j), kl);
      const char *vp = SvPV_const(ST(j + 1), vl);
      STRLEN q;
      sv_catpvs(out, "");
      sv_catpvn(out, first ? "?" : "&", 1);
      first = 0;
      sv_catpvn(out, kp, kl);
      sv_catpvs(out, "=");
      for (q = 0; q < vl; q++) {
        unsigned char c = (unsigned char)vp[q];
        if ((c >= 'A' && c <= 'Z') || (c >= 'a' && c <= 'z')
            || (c >= '0' && c <= '9') || c == '-' || c == '_'
            || c == '.' || c == '~') {
          sv_catpvn(out, (const char *)&c, 1);
        }
        else {
          char esc[4];
          my_snprintf(esc, sizeof esc, "%%%02X", c);
          sv_catpvn(out, esc, 3);
        }
      }
    }
  }

  SP -= items;
  XPUSHs(sv_2mortal(out));
  PUTBACK;
  return;
}

/* ---- the boot fetch --------------------------------------------------- */

/* Metadata bytes, from wherever the provider's `metadata` points.
 *
 * A `file:` URL or a bare path is read here; an http(s) URL goes through
 * the fetch table on an agent built with ua_new, and the future is
 * resolved BLOCKING, because this runs at on_compile, before the server
 * forks. Fetch 0.23 is the floor because it pid-stamps its loop: a loop
 * created in the parent and inherited by every worker is a hang this
 * family has already recorded once.
 *
 * A FAILURE HERE IS A CROAK, not a warning. An application whose only
 * login is SAML cannot sign anyone in without its provider, and refusing
 * to boot says so at deploy time, in the deploy log, to the person
 * deploying. A warning says it at the first login, to a user, as a 403,
 * hours later, to somebody who cannot act on it. */
/* The fetch table's map callback: shape the settled request into a
 * [status, body] pair. Must not croak, and must return a +1 SV. */
static SV *psaml_fetch_map(pTHX_ int ok, int status, AV *headers,
                           SV *body, SV *err, void *ud) {
  AV *out = newAV();
  PERL_UNUSED_ARG(headers);
  PERL_UNUSED_ARG(err);
  PERL_UNUSED_ARG(ud);
  av_push(out, newSViv(ok ? status : 0));
  av_push(out, (ok && body && SvOK(body)) ? newSVsv(body) : newSV(0));
  return newRV_noinc((SV *)out);
}

PERL_STATIC_INLINE SV *psaml_fetch_metadata(pTHX_ SV *app, SV *src,
                                            const char *idp_name) {
  STRLEN sl;
  const char *sp = SvPVbyte(src, sl);
  int is_http = (sl > 7 && memEQ(sp, "http://", 7))
             || (sl > 8 && memEQ(sp, "https://", 8));

  if (!is_http) {
    /* file:/path or a bare path */
    const char *path = sp;
    STRLEN pl = sl;
    PerlIO *fh;
    SV *out;
    if (pl > 5 && memEQ(path, "file:", 5)) { path += 5; pl -= 5; }
    {
      SV *pn = sv_2mortal(newSVpvn(path, pl));
      fh = PerlIO_open(SvPV_nolen(pn), "rb");
      if (!fh)
        croak("%s: saml_idp '%s': cannot read metadata from %s: %s",
              PSAML_WHO, idp_name, SvPV_nolen(pn), Strerror(errno));
    }
    out = newSVpvs("");
    {
      char buf[8192];
      SSize_t n;
      while ((n = PerlIO_read(fh, buf, sizeof buf)) > 0)
        sv_catpvn(out, buf, (STRLEN)n);
    }
    PerlIO_close(fh);
    return out;
  }

  {
    const fetch_abi *FE = psaml_fetch(aTHX);
    SV *kv[4];
    SV *ua, *future, *res;

    kv[0] = sv_2mortal(newSVpvs("timeout"));
    kv[1] = sv_2mortal(newSVnv(10.0));
    kv[2] = sv_2mortal(newSVpvs("tls_verify"));
    kv[3] = sv_2mortal(newSViv(1));
    ua = FE->ua_new(aTHX_ kv, 4);
    if (!ua)
      croak("%s: saml_idp '%s': could not build a user agent to fetch "
            "metadata", PSAML_WHO, idp_name);
    sv_2mortal(ua);

    /* `map` is invoked UNCONDITIONALLY by the table, with no NULL guard,
     * so it must always be passed. Passing NULL is a SEGV at the first
     * boot fetch, which is a long way from where it looks like it came
     * from. Punk-OAuth2's pox_http.h says this in a comment; this dist
     * learned it the other way. */
    future = FE->request(aTHX_ ua, "GET", SvPV_nolen(src), NULL, 0,
                         NULL, 0, 10.0, -1, psaml_fetch_map, NULL);
    if (!future)
      croak("%s: saml_idp '%s': the metadata request could not be made",
            PSAML_WHO, idp_name);
    sv_2mortal(future);

    /* resolved blocking: this is boot, there is no loop to yield to yet,
     * and the whole point is that the application does not start without
     * its provider */
    res = psaml_call(aTHX_ future, "get", NULL, 0);
    if (!res)
      croak("%s: saml_idp '%s': fetching %s produced no response",
            PSAML_WHO, idp_name, SvPV_nolen(src));
    sv_2mortal(res);

    /* the map above shaped it into [status, body] */
    {
      AV *pair;
      SV **st, **bd;
      IV status;
      if (!SvROK(res) || SvTYPE(SvRV(res)) != SVt_PVAV)
        croak("%s: saml_idp '%s': fetching %s produced no usable response",
              PSAML_WHO, idp_name, SvPV_nolen(src));
      pair = (AV *)SvRV(res);
      st = av_fetch(pair, 0, 0);
      bd = av_fetch(pair, 1, 0);
      status = (st && *st) ? SvIV(*st) : 0;
      if (status < 200 || status > 299)
        croak("%s: saml_idp '%s': fetching %s answered %" IVdf,
              PSAML_WHO, idp_name, SvPV_nolen(src), status);
      if (!bd || !*bd || !SvOK(*bd) || !SvCUR(*bd))
        croak("%s: saml_idp '%s': fetching %s answered an empty body",
              PSAML_WHO, idp_name, SvPV_nolen(src));
      PERL_UNUSED_ARG(app);
      return newSVsv(*bd);
    }
  }
}


/* Metadata bytes into a provider's recorded configuration.
 *
 * Shared by the boot resolution and the rotation refetch below, so a
 * provider re-read mid-run ends up with exactly the configuration it
 * would have had at boot. Two code paths filling the same hash by
 * different rules would be a bug that could only appear after a key
 * rotation, which is the least observable moment there is. */
PERL_STATIC_INLINE void psaml_idp_merge(pTHX_ HV *cfg, SV *bytes, HV *opts) {
  SV *want = psaml_hget(aTHX_ cfg, "entity_id");
  SV *read = psaml_idp_from_metadata(aTHX_ bytes,
               (want && SvOK(want)) ? SvPV_nolen(want) : NULL,
               psaml_opt_bool(aTHX_ opts, "enforce_cert_validity", 0));
  HV *got = (HV *)SvRV(read);
  HE *he;
  sv_2mortal(read);
  hv_iterinit(got);
  while ((he = hv_iternext(got))) {
    STRLEN kl;
    const char *k = HePV(he, kl);
    (void)hv_store(cfg, k, (I32)kl, newSVsv(HeVAL(he)), 0);
  }
}


/* ---- the rotation refetch ---------------------------------------------- */

/* A provider that rotates its signing key signs the next assertion with a
 * certificate this application has never seen. Every login then fails
 * with `bad_signature` until somebody notices and redeploys - an outage
 * caused by the far side doing something routine that it announced only
 * in its metadata.
 *
 * So: one re-read of the metadata, on the failure, and one retry.
 *
 * ONLY for a provider configured from `metadata`. An explicit
 * entity_id/sso_url/certs trio is what the deployer typed, and this dist
 * does not overwrite it from the network.
 *
 * RATE LIMITED, and that is the security half rather than a politeness.
 * `bad_signature` is also exactly what a forged Response produces, so an
 * unlimited refetch would let anybody make this application fetch a URL
 * as fast as they can POST to the ACS. `metadata_refresh` is the floor
 * between two refetches, and the stamp is written BEFORE the fetch so a
 * provider that hangs until the timeout cannot leave the limit unset.
 *
 * PER WORKER: the stamp lives on the provider's configuration hash, of
 * which every worker holds its own copy after the fork. A deployment with
 * N workers therefore allows at most N refetches per interval. That is
 * the same bound the replay store lives with, and it is written down
 * here because it is the kind of thing that looks like a leak later.
 *
 * CROAKS on a fetch failure, so the caller must be inside a G_EVAL: a
 * provider that is down during somebody's login must produce a refused
 * login, never a 500. */
PERL_STATIC_INLINE int psaml_idp_refetch(pTHX_ SV *app, HV *opts,
                                         SV *idp_name, HV *cfg, IV now) {
  SV *meta = psaml_hget(aTHX_ cfg, "metadata");
  SV **le;
  IV every, last;
  SV *bytes;

  if (!meta || !SvOK(meta)) return 0;      /* an explicit trio */
  if (!idp_name || !SvOK(idp_name)) return 0;

  every = psaml_opt_iv(aTHX_ opts, "metadata_refresh", 3600);
  if (every <= 0) return 0;                /* turned off deliberately */

  le   = hv_fetchs(cfg, "last_refresh", 0);
  last = (le && *le && SvOK(*le)) ? SvIV(*le) : 0;
  if (last && now - last < every) return 0;

  (void)hv_stores(cfg, "last_refresh", newSViv(now));

  bytes = sv_2mortal(psaml_fetch_metadata(aTHX_ app, meta,
                                          SvPV_nolen(idp_name)));
  psaml_idp_merge(aTHX_ cfg, bytes, opts);
  return 1;
}


/* Is this failure one a key rotation would explain?
 *
 * `bad_signature` is a signature no configured key verifies, and
 * `no_key` is no configured key at all. Both are answered by reading the
 * metadata again. `bad_digest` is NOT: the signature verified and the
 * content did not match it, which is tampering, and refetching would be
 * fetching a URL on an attacker's say-so for no possible benefit. */
PERL_STATIC_INLINE int psaml_rotation_explains(pTHX_ SV *err) {
  SV *code;
  if (!err || !SvROK(err) || SvTYPE(SvRV(err)) != SVt_PVHV) return 0;
  code = psaml_hget(aTHX_ (HV *)SvRV(err), "code");
  if (!code || !SvOK(code)) return 0;
  return strEQ(SvPV_nolen(code), PSAML_E_BAD_SIGNATURE)
      || strEQ(SvPV_nolen(code), PSAML_E_NO_KEY);
}


/* ---- the routes -------------------------------------------------------- */

/* WantAssertionsSigned in the published metadata reflects what this
 * application actually requires. `response` alone is the one setting that
 * does not require a signed assertion. */
PERL_STATIC_INLINE int psaml_want_assertions_signed(pTHX_ HV *opts) {
  SV *r = psaml_hget(aTHX_ opts, "require_signed");
  return !(r && SvOK(r) && strEQ(SvPV_nolen(r), "response"));
}


/* Everything below runs per request. The four routes are mounted at
 * on_compile from the ONE mount string phase 4 recorded, so the ACS URL
 * in the AuthnRequest, in the metadata, in the Destination check and in
 * the route that receives it are four readings of one variable. */

PERL_STATIC_INLINE SV *psaml_ctx_app(pTHX_ SV *c) {
  return psaml_call(aTHX_ c, "app", NULL, 0);
}

PERL_STATIC_INLINE HV *psaml_opts_of(pTHX_ SV *app) {
  SV *o = psaml_app_get(aTHX_ app, PSAML_K_OPTS);
  if (!o || !SvROK(o)) croak("%s: the plugin is not configured", PSAML_WHO);
  return (HV *)SvRV(o);
}

/* GET <mount>/metadata */
XS_INTERNAL(psaml_rt_metadata);
XS_INTERNAL(psaml_rt_metadata) {
  dXSARGS;
  SV *app = psaml_cap_slot(aTHX_ cv, 0);
  SV *c   = items > 0 ? ST(0) : NULL;
  HV *opts;
  SV *doc, *argv[2], *res;

  if (!app || !c) { PERL_UNUSED_VAR(ax); XSRETURN_EMPTY; }
  opts = psaml_opts_of(aTHX_ app);
  doc = sv_2mortal(psaml_sp_metadata(aTHX_
          psaml_app_get(aTHX_ app, PSAML_K_ENTITY),
          psaml_app_get(aTHX_ app, PSAML_K_ACS),
          psaml_hget(aTHX_ opts, "cert"),
          psaml_hget(aTHX_ opts, "name_id_format"),
          psaml_opt_bool(aTHX_ opts, "sign_requests", 0),
          psaml_want_assertions_signed(aTHX_ opts)));

  if (psaml_opt_bool(aTHX_ opts, "sign_metadata", 0)) {
    SV *id = sv_2mortal(psaml_request_id(aTHX));
    SV *withid = sv_2mortal(newSVpvs(""));
    STRLEN dl;
    const char *dp = SvPVbyte(doc, dl);
    const char *gt = (const char *)memchr(dp, ' ', dl);
    /* the ID goes on the root before it is signed, because a Reference
     * names an ID and the document as built carries none */
    sv_catpvn(withid, dp, (STRLEN)(gt - dp));
    sv_catpvs(withid, " ID=\"");
    sv_catsv(withid, id);
    sv_catpvs(withid, "\"");
    sv_catpvn(withid, gt, dl - (STRLEN)(gt - dp));
    doc = sv_2mortal(psaml_sign_document(aTHX_ withid, id,
              psaml_hget(aTHX_ opts, "key"),
              psaml_hget(aTHX_ opts, "cert")));
  }

  /* A raw PSGI triplet, because the media type here is the
   * specification's and neither $c->text nor Punk 0.46's $c->xml will
   * send it: text sends text/plain and xml sends application/xml. This
   * is the shape Punk-Feed returns, for the same reason. */
  {
    AV *resp = newAV(), *hdrs = newAV(), *body = newAV();
    av_push(hdrs, newSVpvs("Content-Type"));
    av_push(hdrs, newSVpvs(PSAML_CT_METADATA));
    av_push(hdrs, newSVpvs("Content-Length"));
    av_push(hdrs, newSViv((IV)SvCUR(doc)));
    av_push(body, newSVsv(doc));
    av_push(resp, newSViv(200));
    av_push(resp, newRV_noinc((SV *)hdrs));
    av_push(resp, newRV_noinc((SV *)body));
    res = newRV_noinc((SV *)resp);
  }
  PERL_UNUSED_VAR(argv);
  /* ST(0)/XSRETURN, never a captured SP: see the note at psaml_rt_login. */
  ST(0) = sv_2mortal(res);
  XSRETURN(1);
}

/* GET <mount>/login/:idp  and  GET <mount>/login */
XS_INTERNAL(psaml_rt_login);
XS_INTERNAL(psaml_rt_login) {
  dXSARGS;
  SV *app = psaml_cap_slot(aTHX_ cv, 0);
  SV *c   = items > 0 ? ST(0) : NULL;
  HV *opts, *idps, *rec;
  SV *name = NULL, *cfgsv, *to, *id, *instant, *xml, *url, *argv[3], *res;
  AV *records, *order;
  SV *cookie, *value, *setc;
  IV ttl, now;
  HV *cfg;

  if (!app || !c) { PERL_UNUSED_VAR(ax); XSRETURN_EMPTY; }
  opts  = psaml_opts_of(aTHX_ app);
  idps  = (HV *)SvRV(psaml_app_get(aTHX_ app, PSAML_K_IDPS));
  order = (AV *)SvRV(psaml_app_get(aTHX_ app, PSAML_K_IDPORDER));

  if (items > 1 && SvOK(ST(1)) && SvCUR(ST(1))) {
    name = ST(1);
  }
  else if (av_len(order) == 0) {
    /* exactly one provider: /login with no name is unambiguous */
    SV **e = av_fetch(order, 0, 0);
    name = (e && *e) ? *e : NULL;
  }
  if (!name) {
    /* more than one provider and none named: a 404, because guessing
     * which one the user meant is guessing which company signs them in */
    argv[0] = sv_2mortal(newSVpvs("no such login"));
    argv[1] = sv_2mortal(newSViv(404));
    res = psaml_call(aTHX_ c, "text", argv, 2);
    if (!res) XSRETURN_EMPTY;
    ST(0) = sv_2mortal(res);
    XSRETURN(1);
  }

  {
    STRLEN nl;
    const char *np = SvPV_const(name, nl);
    SV **e = hv_fetch(idps, np, (I32)nl, 0);
    if (!e || !*e || !SvROK(*e)) {
      argv[0] = sv_2mortal(newSVpvs("no such login"));
      argv[1] = sv_2mortal(newSViv(404));
      res = psaml_call(aTHX_ c, "text", argv, 2);
      if (!res) XSRETURN_EMPTY;
      ST(0) = sv_2mortal(res);
      XSRETURN(1);
    }
    cfgsv = *e;
  }
  cfg = (HV *)SvRV(cfgsv);

  /* `to` came from a link somebody wrote, so it goes through safe_path
   * before it is recorded and never after */
  {
    SV *raw;
    argv[0] = sv_2mortal(newSVpvs("to"));
    raw = sv_2mortal(psaml_call(aTHX_ c, "param", argv, 1));
    argv[0] = raw ? raw : &PL_sv_undef;
    argv[1] = psaml_hget(aTHX_ opts, "default_to");
    to = sv_2mortal(psaml_call(aTHX_ c, "safe_path", argv, 2));
    if (!to || !SvOK(to)) to = psaml_hget(aTHX_ opts, "default_to");
  }

  now = (IV)time(NULL);
  ttl = psaml_opt_iv(aTHX_ opts, "flow_ttl", 600);
  id  = sv_2mortal(psaml_request_id(aTHX));

  {
    char b[64];
    STRLEN bn = psaml_time_format(b, sizeof b, now);
    instant = sv_2mortal(newSVpvn(b, bn));
  }
  xml = sv_2mortal(psaml_authn_request(aTHX_ id, instant,
          psaml_hget(aTHX_ cfg, "sso_url"),
          psaml_app_get(aTHX_ app, PSAML_K_ACS),
          psaml_app_get(aTHX_ app, PSAML_K_ENTITY),
          psaml_hget(aTHX_ opts, "name_id_format"),
          psaml_opt_bool(aTHX_ opts, "force_authn", 0)));

  url = sv_2mortal(psaml_redirect_url(aTHX_
          psaml_hget(aTHX_ cfg, "sso_url"), xml, id,
          psaml_opt_bool(aTHX_ opts, "sign_requests", 0)
            ? psaml_hget(aTHX_ opts, "key") : NULL));

  /* the record into the cookie. Nothing is stored server side: the
   * cookie is the store and the signature is what makes it one. */
  argv[0] = sv_2mortal(newSVpvs(PSAML_FLOW_COOKIE));
  cookie  = sv_2mortal(psaml_call(aTHX_ c, "cookie", argv, 1));
  records = psaml_flow_parse(aTHX_ cookie,
              psaml_hget(aTHX_ opts, "secret"), now, ttl);
  sv_2mortal(newRV_noinc((SV *)records));

  rec = newHV();
  (void)hv_stores(rec, "id",     newSVsv(id));
  (void)hv_stores(rec, "idp",    newSVsv(name));
  (void)hv_stores(rec, "to",     newSVsv(to ? to : &PL_sv_undef));
  (void)hv_stores(rec, "issued", newSViv(now));
  psaml_flow_add(aTHX_ records, newRV_noinc((SV *)rec));

  value = sv_2mortal(psaml_flow_serialise(aTHX_ records,
                       psaml_hget(aTHX_ opts, "secret")));
  setc  = sv_2mortal(psaml_flow_cookie(aTHX_ value,
                       psaml_app_get(aTHX_ app, PSAML_K_MOUNT), ttl));
  argv[0] = sv_2mortal(newSVpvs("Set-Cookie"));
  argv[1] = setc;
  SvREFCNT_dec(psaml_call(aTHX_ c, "header", argv, 2));

  argv[0] = url;
  argv[1] = sv_2mortal(newSViv(302));
  res = psaml_call(aTHX_ c, "redirect", argv, 2);
  /* ST(0) and XSRETURN, NEVER a captured SP.
   *
   * This body calls into Perl repeatedly - param, safe_path, cookie,
   * header, redirect - and Perl code reallocates the argument stack, so
   * the `sp` dXSARGS captured at entry is stale by the time the answer is
   * pushed. ST() indexes from PL_stack_base through `ax`, which survives
   * a realloc. Getting this wrong is a SEGV, not a wrong answer, and it
   * is the second time this dist has paid for it. */
  if (!res) XSRETURN_EMPTY;
  ST(0) = sv_2mortal(res);
  XSRETURN(1);
}


/* POST <mount>/acs
 *
 * The one request in this application that is supposed to look exactly
 * like a cross-site request forgery. What protects it is not a token, it
 * is phase 6 in its entirety. */
XS_INTERNAL(psaml_rt_acs);
XS_INTERNAL(psaml_rt_acs) {
  dXSARGS;
  SV *app = psaml_cap_slot(aTHX_ cv, 0);
  SV *c   = items > 0 ? ST(0) : NULL;
  HV *opts, *idps, *login;
  AV *records;
  SV *cookie, *relay, *field, *rec = NULL, *argv[4], *res;
  SV *idp_name = NULL, *to = NULL, *flow_id = NULL;
  IV ttl, now;
  int failed = 0;
  SV *err = NULL, *identity = NULL;

  if (!app || !c) { PERL_UNUSED_VAR(ax); XSRETURN_EMPTY; }
  opts  = psaml_opts_of(aTHX_ app);
  idps  = (HV *)SvRV(psaml_app_get(aTHX_ app, PSAML_K_IDPS));
  login = (HV *)SvRV(psaml_app_get(aTHX_ app, PSAML_K_LOGIN));
  now   = (IV)time(NULL);
  ttl   = psaml_opt_iv(aTHX_ opts, "flow_ttl", 600);

  argv[0] = sv_2mortal(newSVpvs("RelayState"));
  relay   = sv_2mortal(psaml_call(aTHX_ c, "param", argv, 1));
  argv[0] = sv_2mortal(newSVpvs("SAMLResponse"));
  field   = sv_2mortal(psaml_call(aTHX_ c, "param", argv, 1));

  argv[0] = sv_2mortal(newSVpvs(PSAML_FLOW_COOKIE));
  cookie  = sv_2mortal(psaml_call(aTHX_ c, "cookie", argv, 1));
  records = psaml_flow_parse(aTHX_ cookie,
              psaml_hget(aTHX_ opts, "secret"), now, ttl);
  sv_2mortal(newRV_noinc((SV *)records));

  if (relay && SvOK(relay) && SvCUR(relay))
    rec = psaml_flow_take(aTHX_ records, relay);
  if (rec) sv_2mortal(rec);

  /* THE COOKIE IS WRITTEN BACK NOW, BEFORE ANY VERIFICATION.
   *
   * One flow, one answer, whichever way it goes. A record left in place
   * on failure would let an attacker retry a tampered assertion against
   * the same flow until something got through, and the flow record is
   * the only thing standing between an SP-initiated login and a replay. */
  {
    SV *value = sv_2mortal(psaml_flow_serialise(aTHX_ records,
                             psaml_hget(aTHX_ opts, "secret")));
    SV *setc  = sv_2mortal(psaml_flow_cookie(aTHX_ value,
                             psaml_app_get(aTHX_ app, PSAML_K_MOUNT), ttl));
    argv[0] = sv_2mortal(newSVpvs("Set-Cookie"));
    argv[1] = setc;
    SvREFCNT_dec(psaml_call(aTHX_ c, "header", argv, 2));
  }

  if (rec) {
    HV *r = (HV *)SvRV(rec);
    idp_name = psaml_hget(aTHX_ r, "idp");
    to       = psaml_hget(aTHX_ r, "to");
    flow_id  = psaml_hget(aTHX_ r, "id");
  }
  else if (psaml_opt_bool(aTHX_ opts, "allow_idp_initiated", 0)) {
    /* no record, and the deployment has decided its provider may start a
     * login. RelayState is then the provider's own and IS treated as a
     * path, which is the one place this dist reads it that way, so it
     * goes through safe_path. */
    argv[0] = relay ? relay : &PL_sv_undef;
    argv[1] = psaml_hget(aTHX_ opts, "default_to");
    to = sv_2mortal(psaml_call(aTHX_ c, "safe_path", argv, 2));
    if (av_len((AV *)SvRV(psaml_app_get(aTHX_ app, PSAML_K_IDPORDER))) == 0) {
      SV **e = av_fetch((AV *)SvRV(psaml_app_get(aTHX_ app, PSAML_K_IDPORDER)),
                        0, 0);
      idp_name = (e && *e) ? *e : NULL;
    }
  }

  /* No flow record, and the provider may not start a login: that is
   * `unsolicited`, and it is decided HERE rather than by handing the
   * verifier a Response with no provider to check it against. Calling
   * verify with no certs produces a plain croak about a missing option,
   * which is a configuration message answering a security question. */
  if (!rec && !psaml_opt_bool(aTHX_ opts, "allow_idp_initiated", 0)) {
    failed = 1;
    /* psaml_error_new already hands back a mortal; mortalising it again
     * here would free it twice. */
    err = psaml_error_new(aTHX_ PSAML_E_UNSOLICITED,
            newSVpvs("no flow record matches this RelayState, and "
                     "allow_idp_initiated is off"));
  }
  else
  {
    dSP;
    HV *cfg = NULL;
    int attempt;
    if (idp_name) {
      STRLEN nl;
      const char *np = SvPV_const(idp_name, nl);
      SV **e = hv_fetch(idps, np, (I32)nl, 0);
      if (e && *e && SvROK(*e)) cfg = (HV *)SvRV(*e);
    }

    /* Twice at most. The second attempt happens only when the first
     * failed in a way a key rotation explains AND re-reading the
     * provider's metadata actually produced something new; every other
     * failure leaves the loop on the first pass. `certs` is read off cfg
     * inside the loop, so the retry uses what the refetch just wrote. */
    for (attempt = 0; attempt < 2; attempt++) {

    if (attempt) {
      int refetched = 0;
      if (!cfg || !psaml_rotation_explains(aTHX_ err)) break;

      /* through Perl, for the G_EVAL: psaml_idp_refetch croaks when the
       * provider cannot be reached, and an unreachable provider during
       * somebody's login is a refused login, never a 500. */
      ENTER;
      SAVETMPS;
      PUSHMARK(SP);
      XPUSHs(sv_2mortal(newSVpvs("Punk::Plugin::SAML")));
      XPUSHs(app);
      XPUSHs(idp_name);
      XPUSHs(sv_2mortal(newSViv(now)));
      PUTBACK;
      {
        int count = call_method("_refetch_idp", G_SCALAR | G_EVAL);
        SPAGAIN;
        if (SvTRUE(ERRSV)) {
          /* its own line: "the login failed" and "the provider could not
           * be re-read" are two different operational problems and a
           * deployment chasing the first should not have to infer the
           * second. */
          SV *why = sv_2mortal(newSVsv(ERRSV));
          if (count > 0) (void)POPs;
          Perl_warn(aTHX_ "saml: metadata refetch failed: %s",
                    SvPV_nolen(why));
        }
        else if (count > 0) {
          /* one POP, then the test: SvTRUE(POPs) evaluates its argument
           * more than once and would move the stack pointer with it. */
          SV *r2 = POPs;
          refetched = SvTRUE(r2) ? 1 : 0;
        }
        PUTBACK;
      }
      FREETMPS;
      LEAVE;

      if (!refetched) break;
      /* the first failure is discarded only now that there is going to be
       * a second answer to replace it */
      SvREFCNT_dec(err);
      err = NULL;
      failed = 0;
    }

    ENTER;
    SAVETMPS;
    {
      /* G_EVAL around the whole verification: every check throws a
       * blessed Punk::SAML::Error, and the route turns that into one
       * page and one log line. */
      int i;
      SV *args[24];
      int n = 0;
      PUSHMARK(SP);
      args[n++] = sv_2mortal(newSVpvs("Punk::SAML::Response"));
      args[n++] = field ? field : &PL_sv_undef;
      args[n++] = sv_2mortal(newSVpvs("entity_id"));
      args[n++] = psaml_app_get(aTHX_ app, PSAML_K_ENTITY);
      args[n++] = sv_2mortal(newSVpvs("acs_url"));
      args[n++] = psaml_app_get(aTHX_ app, PSAML_K_ACS);
      args[n++] = sv_2mortal(newSVpvs("idp"));
      args[n++] = idp_name ? idp_name : &PL_sv_undef;
      args[n++] = sv_2mortal(newSVpvs("idp_entity_id"));
      args[n++] = cfg ? psaml_hget(aTHX_ cfg, "entity_id") : &PL_sv_undef;
      args[n++] = sv_2mortal(newSVpvs("certs"));
      args[n++] = cfg ? psaml_hget(aTHX_ cfg, "certs") : &PL_sv_undef;
      args[n++] = sv_2mortal(newSVpvs("now"));
      args[n++] = sv_2mortal(newSViv(now));
      args[n++] = sv_2mortal(newSVpvs("skew"));
      args[n++] = sv_2mortal(newSViv(psaml_opt_iv(aTHX_ opts, "skew", 120)));
      args[n++] = sv_2mortal(newSVpvs("require_signed"));
      args[n++] = psaml_hget(aTHX_ opts, "require_signed");
      args[n++] = sv_2mortal(newSVpvs("allow_sha1"));
      args[n++] = sv_2mortal(newSViv(psaml_opt_bool(aTHX_ opts,
                                       "allow_sha1", 0)));
      args[n++] = sv_2mortal(newSVpvs("allow_idp_initiated"));
      args[n++] = sv_2mortal(newSViv(psaml_opt_bool(aTHX_ opts,
                                       "allow_idp_initiated", 0)));
      args[n++] = sv_2mortal(newSVpvs("in_response_to"));
      args[n++] = flow_id ? flow_id : &PL_sv_undef;
      for (i = 0; i < n; i++) XPUSHs(args[i] ? args[i] : &PL_sv_undef);
      PUTBACK;
    }
    {
      int count = call_method("_verify_field", G_SCALAR | G_EVAL);
      SPAGAIN;
      if (SvTRUE(ERRSV)) {
        failed = 1;
        /* +1 and NOT mortalised here: this is inside the ENTER/SAVETMPS
         * frame, and the FREETMPS below would free it before the failure
         * path reads its `code`. Mortalised after LEAVE instead. */
        err = newSVsv(ERRSV);
        if (count > 0) (void)POPs;
      }
      else if (count > 0) {
        SV *r2 = POPs;
        identity = SvREFCNT_inc_simple_NN(r2);
      }
      PUTBACK;
    }
    FREETMPS;
    LEAVE;
    if (identity) break;

    }  /* for attempt */

    /* mortalised out here, not inside the loop: an `err` freed at the end
     * of the first pass is one the second pass would read after it was
     * gone. */
    if (identity) sv_2mortal(identity);
    if (err) sv_2mortal(err);
  }

  /* Anything that reached here as a plain string is a bug or a
   * misconfiguration rather than a check result, and on_error is
   * documented to receive a Punk::SAML::Error. Wrap it so that contract
   * holds on every path. */
  if (failed && err && !(SvROK(err) && sv_isobject(err)))
    err = psaml_error_new(aTHX_ PSAML_E_CONFIG, newSVsv(err));
  if (!failed && !identity) {
    failed = 1;
    err = psaml_error_new(aTHX_ PSAML_E_XML_SHAPE,
            newSVpvs("the Response produced no identity"));
  }

  if (failed || !identity) {
    /* the code goes to the log with the provider; the REASON never
     * reaches the browser. A verifier that told the far side which check
     * it failed would be telling an attacker which one to work on. */
    SV *on_error = psaml_hget(aTHX_ login, "on_error");
    {
      SV *code = (err && SvROK(err) && SvTYPE(SvRV(err)) == SVt_PVHV)
               ? psaml_hget(aTHX_ (HV *)SvRV(err), "code") : NULL;
      SV *msg  = (err && SvROK(err) && SvTYPE(SvRV(err)) == SVt_PVHV)
               ? psaml_hget(aTHX_ (HV *)SvRV(err), "message") : NULL;
      SV *line = sv_2mortal(newSVpvs("saml: "));
      sv_catsv(line, code ? code : sv_2mortal(newSVpvs("error")));
      if (idp_name) { sv_catpvs(line, " idp="); sv_catsv(line, idp_name); }
      if (msg) { sv_catpvs(line, " "); sv_catsv(line, msg); }
      /* warn, not $c->log: this reaches psgi.errors on every server and
       * does not tie the plugin to a logger's signature. The CODE and the
       * provider go here; none of it reaches the browser. */
      Perl_warn(aTHX_ "%s", SvPV_nolen(line));
    }
    if (psaml_is_code(aTHX_ on_error)) {
      SV *cbargs[2];
      cbargs[0] = c;
      cbargs[1] = err;
      res = psaml_call_cv(aTHX_ on_error, cbargs, 2);
      if (!res) XSRETURN_EMPTY;
      ST(0) = sv_2mortal(res);
      XSRETURN(1);
    }
    argv[0] = sv_2mortal(newSVpvs(
        "<!doctype html><title>Sign-in failed</title>"
        "<h1>Sign-in failed</h1><p>Please try again.</p>"));
    argv[1] = sv_2mortal(newSViv(403));
    res = psaml_call(aTHX_ c, "html", argv, 2);
    if (!res) XSRETURN_EMPTY;
    ST(0) = sv_2mortal(res);
    XSRETURN(1);
  }

  /* session_rotate BEFORE on_login, because that is session fixation: the
   * session that existed before authentication must not be the one that
   * exists after. The plugin does it so no on_login body has to remember
   * to, and it is called regardless of what the session store is - the
   * cost is nothing and the day it becomes server side is the day it
   * matters. */
  if (psaml_can(aTHX_ c, "session_rotate"))
    SvREFCNT_dec(psaml_call(aTHX_ c, "session_rotate", NULL, 0));

  /* recorded for the logout 0.02 may bring, and read never */
  /* Recorded for the logout 0.02 may bring, and read never.
   *
   * $c->session takes NO arguments and hands back the session hashref;
   * storing is done into that hash. Calling it as session(key, value)
   * is a SEGV rather than an error, which is how this was found. */
  if (psaml_can(aTHX_ c, "session")) {
    SV *sess = sv_2mortal(psaml_call(aTHX_ c, "session", NULL, 0));
    if (sess && SvROK(sess) && SvTYPE(SvRV(sess)) == SVt_PVHV) {
      HV *sh = (HV *)SvRV(sess);
      HV *note = newHV();
      HV *idh = (SvROK(identity) && SvTYPE(SvRV(identity)) == SVt_PVHV)
              ? (HV *)SvRV(identity) : NULL;
      SV *v;
      if (idp_name) (void)hv_stores(note, "idp", newSVsv(idp_name));
      if (idh) {
        v = psaml_hget(aTHX_ idh, "name_id");
        if (v) (void)hv_stores(note, "name_id", newSVsv(v));
        v = psaml_hget(aTHX_ idh, "session_index");
        if (v) (void)hv_stores(note, "session_index", newSVsv(v));
      }
      (void)hv_stores(sh, "punk_saml", newRV_noinc((SV *)note));
    }
  }

  {
    SV *on_login = psaml_hget(aTHX_ login, "on_login");
    SV *cbargs[2];
    cbargs[0] = c;
    cbargs[1] = identity;
    res = psaml_call_cv(aTHX_ on_login, cbargs, 2);
  }

  /* on_login's return value is the answer when there is one; otherwise
   * the plugin redirects to where the login started */
  if (!res) {
    argv[0] = to ? to : psaml_hget(aTHX_ opts, "default_to");
    argv[1] = sv_2mortal(newSViv(303));
    res = psaml_call(aTHX_ c, "redirect", argv, 2);
  }
  if (!res) XSRETURN_EMPTY;
  ST(0) = sv_2mortal(res);
  XSRETURN(1);
}

PERL_STATIC_INLINE void psaml_mount_routes(pTHX_ SV *app) {
  SV *mount = psaml_app_get(aTHX_ app, PSAML_K_MOUNT);
  HV *opts  = psaml_opts_of(aTHX_ app);
  AV *cap;
  SV *path;

  if (psaml_opt_bool(aTHX_ opts, "metadata", 1)) {
    cap = newAV(); av_push(cap, newSVsv(app));
    path = sv_2mortal(newSVsv(mount));
    sv_catpvs(path, "/metadata");
    psaml_route(aTHX_ app, "GET", path, psaml_rt_metadata, cap);
  }

  cap = newAV(); av_push(cap, newSVsv(app));
  path = sv_2mortal(newSVsv(mount));
  sv_catpvs(path, "/login/:idp");
  psaml_route(aTHX_ app, "GET", path, psaml_rt_login, cap);

  cap = newAV(); av_push(cap, newSVsv(app));
  path = sv_2mortal(newSVsv(mount));
  sv_catpvs(path, "/login");
  psaml_route(aTHX_ app, "GET", path, psaml_rt_login, cap);

  cap = newAV(); av_push(cap, newSVsv(app));
  path = sv_2mortal(newSVsv(mount));
  sv_catpvs(path, "/acs");
  psaml_route(aTHX_ app, "POST", path, psaml_rt_acs, cap);
}

/* ---- on_compile ------------------------------------------------------- */

/* Everything that needs `host`, or needs every keyword to have run.
 *
 * saml_login with no provider is caught HERE rather than at the keyword,
 * because the two may be declared in either order and a plugin that
 * insisted on one order would be enforcing a rule the application never
 * agreed to. */
XS_INTERNAL(psaml_on_compile);
XS_INTERNAL(psaml_on_compile) {
  dXSARGS;
  SV *app = psaml_cap_slot(aTHX_ cv, 0);
  SV *login, *host, *entity, *mount, *ordsv;
  HV *opts;

  PERL_UNUSED_VAR(items);
  if (!app) { PERL_UNUSED_VAR(ax); XSRETURN_EMPTY; }

  login = psaml_app_get(aTHX_ app, PSAML_K_LOGIN);
  if (!login) XSRETURN_EMPTY;      /* the plugin without a login mount does
                                    * nothing, and that is allowed: an
                                    * application may load it to publish
                                    * metadata and nothing else */

  ordsv = psaml_app_get(aTHX_ app, PSAML_K_IDPORDER);
  if (!ordsv || !SvROK(ordsv) || av_len((AV *)SvRV(ordsv)) < 0)
    croak("%s: saml_login is declared but no saml_idp is. There is nothing "
          "to log in against", PSAML_WHO);

  host  = psaml_host(aTHX_ app);
  mount = psaml_app_get(aTHX_ app, PSAML_K_MOUNT);
  {
    STRLEN ml;
    const char *mp = SvPV_const(mount, ml);
    SV *acs = newSVsv(host);
    STRLEN al;
    const char *ap = SvPV_const(acs, al);
    while (al && ap[al - 1] == '/') al--;
    SvCUR_set(acs, al);
    sv_catpvn(acs, mp, ml);
    sv_catpvs(acs, "/acs");
    /* One variable, computed once. The AuthnRequest, the metadata, the
     * Destination check and the Recipient check all read it, and four
     * derivations of one URL is four chances for them to disagree. */
    psaml_app_set(aTHX_ app, PSAML_K_ACS, acs);
  }

  opts   = (HV *)SvRV(psaml_app_get(aTHX_ app, PSAML_K_OPTS));
  entity = psaml_hget(aTHX_ opts, "entity_id");
  if (entity && SvOK(entity)) {
    psaml_app_set(aTHX_ app, PSAML_K_ENTITY, newSVsv(entity));
  }
  else {
    /* the metadata URL, which is what an identity provider will have been
     * given to identify us by if we did not say otherwise */
    SV *pfx = psaml_hget(aTHX_ opts, "prefix");
    SV *url = psaml_join_url(aTHX_ host, SvPV_nolen(pfx));
    sv_catpvs(url, "/metadata");
    psaml_app_set(aTHX_ app, PSAML_K_ENTITY, url);
  }

  /* Every provider resolved HERE, before the fork. A `metadata` source is
   * fetched or read and run through psaml_idp_from_metadata; an explicit
   * trio is used as given. */
  {
    HV *idps  = (HV *)SvRV(psaml_app_get(aTHX_ app, PSAML_K_IDPS));
    AV *order = (AV *)SvRV(ordsv);
    SSize_t i, n = av_len(order) + 1;
    for (i = 0; i < n; i++) {
      SV **e = av_fetch(order, i, 0);
      STRLEN nl;
      const char *np;
      SV **cfge;
      HV *cfg;
      SV *meta;
      if (!e || !*e) continue;
      np = SvPV_const(*e, nl);
      cfge = hv_fetch(idps, np, (I32)nl, 0);
      if (!cfge || !*cfge || !SvROK(*cfge)) continue;
      cfg = (HV *)SvRV(*cfge);
      meta = psaml_hget(aTHX_ cfg, "metadata");
      if (meta && SvOK(meta)) {
        SV *bytes = sv_2mortal(psaml_fetch_metadata(aTHX_ app, meta, np));
        psaml_idp_merge(aTHX_ cfg, bytes, opts);
        /* No `last_refresh` is stamped here. The clock the rotation
         * refetch runs on starts at the first REFETCH, not at boot: a
         * provider that rotates its key an hour after this application
         * started should be picked up at the first failed login, not an
         * interval after one. */
        /* WantAuthnRequestsSigned, acted on. With a key, sign_requests
         * turns itself on; without one a croak naming the option, because
         * a provider that demands signed requests refuses every unsigned
         * one and every login fails. */
        if (psaml_opt_bool(aTHX_ cfg, "want_authn_requests_signed", 0)) {
          if (hv_exists(opts, "key", 3))
            (void)hv_stores(opts, "sign_requests", newSViv(1));
          else
            croak("%s: saml_idp '%.*s' publishes "
                  "WantAuthnRequestsSigned=\"true\" and this application "
                  "has no `key`. Every AuthnRequest would be refused; "
                  "configure `key` with the SP private key",
                  PSAML_WHO, (int)nl, np);
        }
      }
    }
  }

  /* The ACS is a POST with no session and no token, from another origin.
   * It is the one request in the application that is SUPPOSED to look
   * exactly like a cross-site request forgery, and csrf must not check
   * it.
   *
   * MEASURED rather than assumed, which is what the plan asked for: the
   * exempt list is an arrayref on the application hash under `csrf`, it
   * is reachable here, and matching is a prefix match. So the path is
   * added. A silent requirement would be a 403 on every login. */
  {
    SV **csrf = hv_fetchs(psaml_app_hv(aTHX_ app), "csrf", 0);
    if (csrf && *csrf && SvROK(*csrf) && SvTYPE(SvRV(*csrf)) == SVt_PVHV) {
      HV *ccfg = (HV *)SvRV(*csrf);
      SV **ex  = hv_fetchs(ccfg, "exempt", 0);
      AV *list;
      SV *acs;
      if (ex && *ex && SvROK(*ex) && SvTYPE(SvRV(*ex)) == SVt_PVAV) {
        list = (AV *)SvRV(*ex);
      }
      else {
        list = newAV();
        (void)hv_stores(ccfg, "exempt", newRV_noinc((SV *)list));
      }
      acs = newSVsv(mount);
      sv_catpvs(acs, "/acs");
      av_push(list, acs);
    }
  }

  psaml_mount_routes(aTHX_ app);
  XSRETURN_EMPTY;
}


/* ---- installing ------------------------------------------------------- */

/* The keywords, and ONLY the keywords.
 *
 * Punk makes a second install_kw by the same owner a no-op, which is what
 * lets `use Punk::Plugin::SAML` and `plugin \'SAML\'` both ask and only the
 * first do anything. That is not true of `helper`, which refuses a second
 * registration of the same name even by the same owner, nor of
 * `on_compile`, which would simply run twice. So those go in register,
 * once, and this is called from both. */
PERL_STATIC_INLINE void psaml_install_kw(pTHX_ SV *app) {
  AV *cap;
  cap = newAV(); av_push(cap, newSVsv(app));
  psaml_keyword(aTHX_ app, "saml_idp", psaml_kw_idp, cap);
  cap = newAV(); av_push(cap, newSVsv(app));
  psaml_keyword(aTHX_ app, "saml_login", psaml_kw_login, cap);
}

/* The helpers and the compile hook, from register only, and once.
 *
 * An application that says `use Punk::Plugin::SAML` and never
 * `plugin \'SAML\'` gets the keywords and no helpers, which is right: with
 * no plugin line there is no secret, no options and nothing for a helper
 * to answer from. */
PERL_STATIC_INLINE void psaml_install_rest(pTHX_ SV *app) {
  AV *cap;
  if (psaml_app_get(aTHX_ app, PSAML_K_INSTALLED)) return;
  psaml_app_set(aTHX_ app, PSAML_K_INSTALLED, newSViv(1));
  cap = newAV(); av_push(cap, newSVsv(app));
  psaml_helper(aTHX_ app, "saml_idps", psaml_help_idps, cap);
  cap = newAV(); av_push(cap, newSVsv(app));
  psaml_helper(aTHX_ app, "saml_url", psaml_help_url, cap);
  cap = newAV(); av_push(cap, newSVsv(app));
  psaml_at_compile(aTHX_ app, psaml_on_compile, cap);
}

#endif /* PSAML_BOOT_H */
