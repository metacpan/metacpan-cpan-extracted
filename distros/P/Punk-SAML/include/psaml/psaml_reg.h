#ifndef PSAML_REG_H
#define PSAML_REG_H

/* The registrar surface: how this plugin reaches Punk.
 *
 * Punk is reached by ordinary method dispatch, not through a C table.
 * pk_abi.h is an observer interface with no install_kw, so there is
 * nothing to consume from Punk through ExtUtils::Depends and the
 * Makefile.PL does not load it. This is the same choice Punk-Feed and
 * Punk-Challenge made, for the same reason.
 *
 * NO STRUCTS ON THE APP. Every piece of state this plugin keeps - the
 * option hash, the providers, the ACS URL, the mount - is a key on the
 * application HV, exactly as punk_sitemap.h and pfeed_*.h keep theirs.
 * A struct hung off the app would need a free hook, would need to
 * survive a fork, and would be invisible to anything that dumps the
 * application; three problems bought for nothing.
 *
 * The only aggregates in this dist are the closure capture in
 * psaml_clos.h and the per-document frx_doc *, which lives exactly as
 * long as one verification. */

#include "psaml_compat.h"
#include "psaml_clos.h"

/* The keys this plugin owns on the application hash. Namespaced, because
 * the application hash belongs to the application and every plugin is a
 * guest on it. */
#define PSAML_K_OPTS     "punk_saml.opts"
#define PSAML_K_IDPS     "punk_saml.idps"
#define PSAML_K_IDPORDER "punk_saml.idp_order"
#define PSAML_K_LOGIN    "punk_saml.login"
#define PSAML_K_ACS      "punk_saml.acs"
#define PSAML_K_MOUNT    "punk_saml.mount"
#define PSAML_K_ENTITY   "punk_saml.entity_id"
#define PSAML_K_INSTALLED "punk_saml.installed"

/* The application hash behind $app. Croaks rather than returning NULL:
 * every caller is inside a keyword body, and a keyword body with no
 * application is a bug in this dist, not a condition to handle. */
PERL_STATIC_INLINE HV *psaml_app_hv(pTHX_ SV *app) {
  if (!app || !SvROK(app) || SvTYPE(SvRV(app)) != SVt_PVHV)
    croak("Punk::Plugin::SAML: expected the application, got something else");
  return (HV *)SvRV(app);
}

/* Fetch one of this plugin's keys, borrowed, or NULL. */
PERL_STATIC_INLINE SV *psaml_app_get(pTHX_ SV *app, const char *key) {
  HV *hv = psaml_app_hv(aTHX_ app);
  SV **e = hv_fetch(hv, key, (I32)strlen(key), 0);
  return (e && *e && SvOK(*e)) ? *e : NULL;
}

/* Store one, taking ownership of val. */
PERL_STATIC_INLINE void psaml_app_set(pTHX_ SV *app, const char *key, SV *val) {
  HV *hv = psaml_app_hv(aTHX_ app);
  if (!hv_store(hv, key, (I32)strlen(key), val, 0))
    SvREFCNT_dec(val);
}

/* This plugin's key as a hashref, created on first use. Returns the RV,
 * borrowed. */
PERL_STATIC_INLINE SV *psaml_app_hash(pTHX_ SV *app, const char *key) {
  SV *v = psaml_app_get(aTHX_ app, key);
  if (v && SvROK(v) && SvTYPE(SvRV(v)) == SVt_PVHV) return v;
  v = newRV_noinc((SV *)newHV());
  psaml_app_set(aTHX_ app, key, v);
  return v;
}

/* The same for an arrayref. */
PERL_STATIC_INLINE SV *psaml_app_array(pTHX_ SV *app, const char *key) {
  SV *v = psaml_app_get(aTHX_ app, key);
  if (v && SvROK(v) && SvTYPE(SvRV(v)) == SVt_PVAV) return v;
  v = newRV_noinc((SV *)newAV());
  psaml_app_set(aTHX_ app, key, v);
  return v;
}

/* Call a method on $app and return the single result as a mortal, or
 * NULL when the call returned nothing.
 *
 * Returns +1 and NOT mortal: the caller owns it and frees it. Most
 * callers here want exactly that, because they call for the side effect
 * and drop the result with SvREFCNT_dec, and a mortal handed to
 * SvREFCNT_dec is freed twice - once by the caller and once when the
 * temps stack unwinds. A caller that wants a mortal says sv_2mortal at
 * its own call site.
 *
 * The value is incremented BEFORE FREETMPS, not after: a value the callee
 * mortalised is freed by that FREETMPS, so the reference has to be taken
 * while the frame is still standing. This is the lifetime bug Crypt::JWS
 * hit with a resolver-returned key. */
PERL_STATIC_INLINE SV *psaml_call(pTHX_ SV *invocant, const char *method,
                          SV **args, int nargs) {
  dSP;
  int count, i;
  SV *out = NULL;
  ENTER; SAVETMPS;
  PUSHMARK(SP);
  XPUSHs(invocant);
  for (i = 0; i < nargs; i++) XPUSHs(args[i]);
  PUTBACK;
  count = call_method(method, G_SCALAR);
  SPAGAIN;
  if (count > 0) {
    SV *r = POPs;
    if (SvOK(r)) out = SvREFCNT_inc_simple_NN(r);
  }
  PUTBACK;
  FREETMPS; LEAVE;
  return out;                        /* +1, caller owns; may be NULL */
}

/* Call a coderef, the same shape as psaml_call above.
 *
 * on_login and on_error both go through this rather than each opening
 * their own ENTER/PUSHMARK/call_sv inline. One shape, tested once: the
 * inline version of this in the ACS handed the callback a glob instead
 * of the context, and the failure surfaced as Punk trying to JSON-encode
 * a GLOB reference three frames away from the cause. */
PERL_STATIC_INLINE SV *psaml_call_cv(pTHX_ SV *code, SV **args, int nargs) {
  dSP;
  int count, i;
  SV *out = NULL;
  ENTER; SAVETMPS;
  PUSHMARK(SP);
  for (i = 0; i < nargs; i++) XPUSHs(args[i] ? args[i] : &PL_sv_undef);
  PUTBACK;
  count = call_sv(code, G_SCALAR);
  SPAGAIN;
  if (count > 0) {
    SV *r = POPs;
    if (SvOK(r)) out = SvREFCNT_inc_simple_NN(r);
  }
  PUTBACK;
  FREETMPS; LEAVE;
  return out;                        /* +1, caller owns; may be NULL */
}

/* The same, on the application object. */
#define psaml_app_call(app, method, args, n) \
        psaml_call(aTHX_ (app), (method), (args), (n))


/* ---- the owner ------------------------------------------------------- */

/* PSAML_WHO is in psaml_compat.h, where every header can see it. It is
 * install_kw's third argument and the prefix of every croak: Punk makes a
 * second install by the same owner a no-op, which is what lets `import`
 * and `register` both ask and only the first do anything. */

/* ---- calling into Punk ----------------------------------------------- */

/* Handles both an object and a bare package name: `import` runs with the
 * application's package before any object exists, and register runs with
 * the object. */
PERL_STATIC_INLINE int psaml_can(pTHX_ SV *sv, const char *method) {
  HV *stash;
  if (!sv || !SvOK(sv)) return 0;
  stash = SvROK(sv) ? SvSTASH(SvRV(sv)) : gv_stashsv(sv, 0);
  return stash && gv_fetchmethod_autoload(stash, method, FALSE) != NULL;
}

/* ---- option validation ------------------------------------------------ */

PERL_STATIC_INLINE SV *psaml_name_list(pTHX_ const char *const *known) {
  SV *out = sv_2mortal(newSVpvs(""));
  int i;
  for (i = 0; known[i]; i++) {
    if (i) sv_catpvs(out, ", ");
    sv_catpv(out, known[i]);
  }
  return out;
}

/* An unknown key croaks naming the noun, the key and what was available.
 * The alternative is a typo that configures nothing and changes no
 * behaviour, which is how `require_signd` becomes a site that checks
 * nothing and nobody finds out until an audit. */
PERL_STATIC_INLINE void psaml_check_opts(pTHX_ const char *noun, HV *opts,
                                         const char *const *known) {
  HE *he;
  if (!opts) return;
  hv_iterinit(opts);
  while ((he = hv_iternext(opts))) {
    STRLEN kl;
    const char *k = HePV(he, kl);
    int i, ok = 0;
    for (i = 0; known[i]; i++)
      if (strlen(known[i]) == kl && memEQ(known[i], k, kl)) { ok = 1; break; }
    if (!ok)
      croak("%s: unknown %s '%.*s' (known: %s)", PSAML_WHO, noun,
            (int)kl, k, SvPV_nolen(psaml_name_list(aTHX_ known)));
  }
}

/* ---- installing ------------------------------------------------------- */

PERL_STATIC_INLINE void psaml_keyword(pTHX_ SV *app, const char *name,
                                      XSUBADDR_t body, AV *cap) {
  SV *argv[3];
  argv[0] = sv_2mortal(newSVpv(name, 0));
  argv[1] = sv_2mortal(psaml_closure(aTHX_ body, cap));
  argv[2] = sv_2mortal(newSVpvs(PSAML_WHO));
  SvREFCNT_dec(psaml_call(aTHX_ app, "install_kw", argv, 3));
}

PERL_STATIC_INLINE void psaml_helper(pTHX_ SV *app, const char *name,
                                     XSUBADDR_t body, AV *cap) {
  SV *argv[2];
  argv[0] = sv_2mortal(newSVpv(name, 0));
  argv[1] = sv_2mortal(psaml_closure(aTHX_ body, cap));
  SvREFCNT_dec(psaml_call(aTHX_ app, "helper", argv, 2));
}

/* A route. Written here and first CALLED in phase 8, which mounts the
 * four; nothing in phase 4 mounts anything.
 *
 * `sitemap => 0` on all of them: Punk::Plugin::Sitemap lists every GET
 * route with no capture and no guard, and /saml/metadata and
 * /saml/login are both. A login URL in a sitemap is a crawler starting
 * an authentication flow, on a schedule, for as long as the site
 * exists. */
PERL_STATIC_INLINE void psaml_route(pTHX_ SV *app, const char *method,
                                    SV *path, XSUBADDR_t body, AV *cap) {
  SV *argv[5];
  HV *o = newHV();
  (void)hv_stores(o, "sitemap", newSViv(0));
  argv[0] = sv_2mortal(newSVpv(method, 0));
  argv[1] = path;
  argv[2] = sv_2mortal(psaml_closure(aTHX_ body, cap));
  argv[3] = &PL_sv_undef;
  argv[4] = sv_2mortal(newRV_noinc((SV *)o));
  SvREFCNT_dec(psaml_call(aTHX_ app, "route", argv, 5));
}

/* The to_app seam. on_compile runs once, in registration order, after
 * every keyword has recorded and before anything is compiled, which is
 * the only moment at which `host` has certainly been declared and every
 * saml_idp has certainly been seen. Both matter here: the ACS URL
 * derives from `host`, and `saml_login` has to be able to complain that
 * no provider was declared without caring which line came first.
 *
 * The `can` guard is kept although the floor is well past 0.30, so the
 * failure is a croak naming the version rather than a method-not-found
 * from inside a closure. */
PERL_STATIC_INLINE void psaml_at_compile(pTHX_ SV *app, XSUBADDR_t body,
                                         AV *cap) {
  SV *argv[2];
  if (!psaml_can(aTHX_ app, "on_compile")) {
    SvREFCNT_dec((SV *)cap);
    croak("%s needs Punk 0.30 or newer for on_compile", PSAML_WHO);
  }
  argv[0] = sv_2mortal(psaml_closure(aTHX_ body, cap));
  argv[1] = sv_2mortal(newSVpvs(PSAML_WHO));
  SvREFCNT_dec(psaml_call(aTHX_ app, "on_compile", argv, 2));
}

#endif /* PSAML_REG_H */
