/* pmcp_auth.h - who may call: the `auth` guards, the `oauth` resource server,
 * the RFC 9728 document, and `principal`.
 *
 * Needs: pmcp_http.h.
 *
 * Everything here fills the one guard list the POST, GET and DELETE routes
 * share (07, 09, 10), so the three can never disagree about who is let in:
 *
 *   auth   any Punk guard, or a list: a code ref or a 'Controller#method'
 *   oauth  a Punk::OAuth2::Checker guard over this resource, which answers
 *          401 with the RFC 6750 challenge naming the metadata document, and
 *          403 insufficient_scope. The claims land in stash->{auth}{oauth}
 *
 * The client's token is never sent anywhere. 12's re-entry carries it only to
 * this application's own mount.
 */

#ifndef PMCP_AUTH_H
#define PMCP_AUTH_H

#define PMCP_OAUTH_SINCE "0.08"
#define PMCP_PRM_PATH "/.well-known/oauth-protected-resource"

static const char *const PMCP_OAUTH_KEYS[] = {
    "issuer", "jwks_url", "key", "introspect", "scopes", "audience", "leeway",
    "algs", "realm", NULL
};

/* ---- the resource ---------------------------------------------------------------- */

/* This endpoint's URL: the application's `host` and the plugin's path. The
 * token's audience, so it has to be the exact URL clients use. Mortal. */
static SV *pmcp_resource_url(pTHX_ SV *app, HV *opts)
{
    SV *host = sv_2mortal(pmcp_call_method(aTHX_ app, "host", NULL, 0, G_SCALAR, NULL));
    STRLEN l;
    const char *p;
    SV *out;
    if (!host || !SvOK(host)) return NULL;
    p = SvPV_const(host, l);
    if (!((l > 8 && memEQ(p, "https://", 8)) || (l > 7 && memEQ(p, "http://", 7))))
        return NULL;
    while (l && p[l - 1] == '/') l--;
    out = sv_2mortal(newSVpvn(p, l));
    sv_catsv(out, pmcp_hget(aTHX_ opts, "path"));
    return out;
}

/* The metadata document's URL, path-suffixed (RFC 9728 3.1). Mortal. */
static SV *pmcp_prm_url(pTHX_ SV *app, HV *opts)
{
    SV *host = sv_2mortal(pmcp_call_method(aTHX_ app, "host", NULL, 0, G_SCALAR, NULL));
    STRLEN l;
    const char *p = SvPV_const(host, l);
    SV *out;
    while (l && p[l - 1] == '/') l--;
    out = sv_2mortal(newSVpvn(p, l));
    sv_catpvs(out, PMCP_PRM_PATH);
    sv_catsv(out, pmcp_hget(aTHX_ opts, "path"));
    return out;
}

/* ---- checkers ---------------------------------------------------------------------- */

/* Any of several checkers. The checker contract is $checker->($credential,
 * $c, $operationId, $scopes), the claims or false. cap = [checkers AV] */
XS_INTERNAL(pmcp_any_checker)
{
    dXSARGS;
    SV *list = pmcp_cap(aTHX_ cv, 0);
    AV *av = pmcp_is_array(list) ? (AV *)SvRV(list) : NULL;
    SSize_t i, n = av ? av_len(av) + 1 : 0;
    SV *argv[4], *got = NULL;
    int k;
    for (k = 0; k < 4; k++) argv[k] = k < items ? ST(k) : &PL_sv_undef;
    for (i = 0; i < n && !got; i++) {
        SV *err = NULL;
        SV *r = pmcp_call_sv(aTHX_ *av_fetch(av, i, 0), argv, 4, G_SCALAR, &err);
        if (!r) { SvREFCNT_dec(err); continue; }
        if (SvTRUE(r)) got = sv_2mortal(r);
        else SvREFCNT_dec(r);
    }
    SP = PL_stack_base + ax - 1;
    ST(0) = got ? got : &PL_sv_no;
    XSRETURN(1);
}

/* Introspection says nothing about audience unless the server sends `aud`,
 * and a token not issued for this resource must be refused (RFC 8707, the MCP
 * authorization rules). So the claims must carry one of the audiences.
 * cap = [checker, audiences AV] */
XS_INTERNAL(pmcp_aud_checker)
{
    dXSARGS;
    SV *checker = pmcp_cap(aTHX_ cv, 0), *auds = pmcp_cap(aTHX_ cv, 1);
    SV *argv[4], *r, *err = NULL, *ok = &PL_sv_no;
    int k;
    for (k = 0; k < 4; k++) argv[k] = k < items ? ST(k) : &PL_sv_undef;
    r = pmcp_call_sv(aTHX_ checker, argv, 4, G_SCALAR, &err);
    if (!r) SvREFCNT_dec(err);
    else {
        sv_2mortal(r);
        if (pmcp_is_hash(r)) {
            SV *aud = pmcp_hget(aTHX_ (HV *)SvRV(r), "aud");
            AV *want = (AV *)SvRV(auds);
            SSize_t i, j, n = av_len(want) + 1;
            for (i = 0; i < n && ok == &PL_sv_no; i++) {
                SV *w = *av_fetch(want, i, 0);
                if (aud && pmcp_is_array(aud)) {
                    AV *have = (AV *)SvRV(aud);
                    for (j = 0; j <= av_len(have); j++) {
                        SV **h = av_fetch(have, j, 0);
                        if (h && sv_eq(*h, w)) { ok = r; break; }
                    }
                }
                else if (aud && sv_eq(aud, w)) ok = r;
            }
        }
    }
    SP = PL_stack_base + ax - 1;
    ST(0) = ok;
    XSRETURN(1);
}

/* A 401 that names no scope gets the ones this endpoint needs, so a client
 * asks for them up front rather than learning them from a 403 (2025-11-25).
 * cap = [guard, scope string] */
XS_INTERNAL(pmcp_scoped_guard)
{
    dXSARGS;
    SV *guard = pmcp_cap(aTHX_ cv, 0), *scope = pmcp_cap(aTHX_ cv, 1);
    SV *c = items > 0 ? ST(0) : &PL_sv_undef;
    SV *err = NULL;
    SV *r = pmcp_call_sv(aTHX_ guard, &c, 1, G_SCALAR, &err);
    if (!r) pmcp_croak_sv(aTHX_ sv_2mortal(err));
    if (scope && SvCUR(scope) && pmcp_is_array(r) && av_len((AV *)SvRV(r)) >= 1) {
        AV *t = (AV *)SvRV(r);
        SV **st = av_fetch(t, 0, 0), **hp = av_fetch(t, 1, 0);
        if (st && SvIV(*st) == 401 && hp && pmcp_is_array(*hp)) {
            AV *h = (AV *)SvRV(*hp);
            SSize_t i;
            for (i = 0; i + 1 <= av_len(h); i += 2) {
                SV *k = *av_fetch(h, i, 0), *v = *av_fetch(h, i + 1, 0);
                if (strcasecmp(SvPV_nolen(k), "WWW-Authenticate") == 0
                    && !instr(SvPV_nolen(v), "scope=")) {
                    SV *nv = newSVsv(v);
                    sv_catpvf(nv, ", scope=\"%" SVf "\"", SVfARG(scope));
                    (void)av_store(h, i + 1, nv);
                }
            }
        }
    }
    SP = PL_stack_base + ax - 1;
    ST(0) = sv_2mortal(r);
    XSRETURN(1);
}

static SV *pmcp_list_or_one(pTHX_ SV *v)
{
    AV *av = newAV();
    if (pmcp_is_array(v)) {
        SSize_t i, n = av_len((AV *)SvRV(v)) + 1;
        for (i = 0; i < n; i++) av_push(av, newSVsv(*av_fetch((AV *)SvRV(v), i, 0)));
    }
    else if (v && SvOK(v)) av_push(av, newSVsv(v));
    return sv_2mortal(newRV_noinc((SV *)av));
}

/* The oauth guard, built at on_compile. Croaks naming what is wrong. +1 */
static SV *pmcp_oauth_guard(pTHX_ SV *app, HV *opts, HV *o)
{
    SV *err = NULL, *v, *resource, *auds, *checker, *scopes, *guard, *argv[12], *r;
    SV *checker_class = sv_2mortal(newSVpvs("Punk::OAuth2::Checker"));
    int kinds = 0;
    AV *list;

    pmcp_check_keys(aTHX_ "oauth option", o, PMCP_OAUTH_KEYS);
    if (!pmcp_require(aTHX_ "Punk::OAuth2::Checker", &err)) {
        sv_2mortal(err);
        croak("%s: oauth needs Punk-OAuth2 %s or later, and it does not load: %" SVf,
              PMCP_WHO, PMCP_OAUTH_SINCE, SVfARG(err));
    }
    {
        SV *ver = get_sv("Punk::OAuth2::VERSION", 0);
        if (!ver || !SvOK(ver) || SvNV(ver) < 0.08)
            croak("%s: oauth needs Punk-OAuth2 %s or later, and found %s", PMCP_WHO,
                  PMCP_OAUTH_SINCE, ver && SvOK(ver) ? SvPV_nolen(ver) : "none");
    }
    resource = pmcp_resource_url(aTHX_ app, opts);
    if (!resource)
        croak("%s: oauth needs the application's `host` (https://...): the token's "
              "audience is this endpoint's URL, and the metadata document names it",
              PMCP_WHO);
    if (!pmcp_is_text(pmcp_hget(aTHX_ o, "issuer")))
        croak("%s: oauth needs `issuer`, the authorization server", PMCP_WHO);
    kinds = !!pmcp_hget(aTHX_ o, "jwks_url") + !!pmcp_hget(aTHX_ o, "key")
          + !!pmcp_hget(aTHX_ o, "introspect");
    if (kinds != 1)
        croak("%s: oauth needs exactly one of `jwks_url`, `key` or `introspect`",
              PMCP_WHO);

    v = pmcp_hget(aTHX_ o, "audience");
    auds = v ? pmcp_list_or_one(aTHX_ v) : pmcp_list_or_one(aTHX_ resource);
    if (av_len((AV *)SvRV(auds)) < 0) croak("%s: oauth `audience` is empty", PMCP_WHO);
    scopes = pmcp_list_or_one(aTHX_ pmcp_hget(aTHX_ o, "scopes"));

    list = newAV();
    if ((v = pmcp_hget(aTHX_ o, "introspect"))) {
        HV *ih;
        HE *he;
        int n = 0;
        AV *cap;
        if (!pmcp_is_hash(v)) croak("%s: oauth `introspect` must be a hash", PMCP_WHO);
        ih = (HV *)SvRV(v);
        hv_iterinit(ih);
        while ((he = hv_iternext(ih)) && n < 8) {
            argv[n++] = sv_2mortal(newSVsv(hv_iterkeysv(he)));
            argv[n++] = HeVAL(he);
        }
        r = pmcp_call_method(aTHX_ checker_class, "introspect", argv, n, G_SCALAR, &err);
        if (!r) { SvREFCNT_dec((SV *)list); pmcp_croak_sv(aTHX_ sv_2mortal(err)); }
        cap = newAV();
        av_push(cap, r);
        av_push(cap, newSVsv(auds));
        av_push(list, pmcp_closure(aTHX_ pmcp_aud_checker, cap));
    }
    else {
        SSize_t i, na = av_len((AV *)SvRV(auds)) + 1;
        for (i = 0; i < na; i++) {
            int n = 0;
            argv[n++] = sv_2mortal(newSVpvs("issuer"));
            argv[n++] = pmcp_hget(aTHX_ o, "issuer");
            argv[n++] = sv_2mortal(newSVpvs("audience"));
            argv[n++] = *av_fetch((AV *)SvRV(auds), i, 0);
            if ((v = pmcp_hget(aTHX_ o, "jwks_url"))) {
                argv[n++] = sv_2mortal(newSVpvs("jwks_url"));
                argv[n++] = v;
            }
            else {
                argv[n++] = sv_2mortal(newSVpvs("key"));
                argv[n++] = pmcp_hget(aTHX_ o, "key");
            }
            if ((v = pmcp_hget(aTHX_ o, "algs"))) {
                argv[n++] = sv_2mortal(newSVpvs("algs"));
                argv[n++] = v;
            }
            if ((v = pmcp_hget(aTHX_ o, "leeway"))) {
                argv[n++] = sv_2mortal(newSVpvs("leeway"));
                argv[n++] = v;
            }
            r = pmcp_call_method(aTHX_ checker_class, "jwt", argv, n, G_SCALAR, &err);
            if (!r) { SvREFCNT_dec((SV *)list); pmcp_croak_sv(aTHX_ sv_2mortal(err)); }
            av_push(list, r);
        }
    }
    if (av_len(list) == 0) {
        checker = sv_2mortal(newSVsv(*av_fetch(list, 0, 0)));
        SvREFCNT_dec((SV *)list);
    }
    else {
        AV *cap = newAV();
        av_push(cap, newRV_noinc((SV *)list));
        checker = sv_2mortal(pmcp_closure(aTHX_ pmcp_any_checker, cap));
    }

    {
        int n = 0;
        argv[n++] = checker;
        argv[n++] = sv_2mortal(newSVpvs("scopes"));
        argv[n++] = scopes;
        argv[n++] = sv_2mortal(newSVpvs("resource_metadata"));
        argv[n++] = pmcp_prm_url(aTHX_ app, opts);
        argv[n++] = sv_2mortal(newSVpvs("realm"));
        argv[n++] = (v = pmcp_hget(aTHX_ o, "realm")) ? v : sv_2mortal(newSVpvs("mcp"));
        guard = pmcp_call_method(aTHX_ checker_class, "guard", argv, n, G_SCALAR, &err);
        if (!guard) pmcp_croak_sv(aTHX_ sv_2mortal(err));
    }
    {
        AV *cap = newAV();
        SV *joined = newSVpvs("");
        SSize_t i, ns = av_len((AV *)SvRV(scopes)) + 1;
        for (i = 0; i < ns; i++) {
            if (i) sv_catpvs(joined, " ");
            sv_catsv(joined, *av_fetch((AV *)SvRV(scopes), i, 0));
        }
        av_push(cap, guard);
        av_push(cap, joined);
        return pmcp_closure(aTHX_ pmcp_scoped_guard, cap);
    }
}

/* ---- the guard list ---------------------------------------------------------------- */

/* `auth` then `oauth`, resolved: the list the routes share. +1 AV ref. */
static SV *pmcp_auth_guards(pTHX_ SV *app, HV *opts)
{
    AV *out = newAV();
    SV *a = pmcp_hget(aTHX_ opts, "auth"), *o = pmcp_hget(aTHX_ opts, "oauth");
    if (a) {
        AV *g = pmcp_resolve_guards(aTHX_ app, "endpoint", sv_2mortal(newSVpvs("auth")), a);
        if (g) {
            SSize_t i, n = av_len(g) + 1;
            for (i = 0; i < n; i++) av_push(out, newSVsv(*av_fetch(g, i, 0)));
            SvREFCNT_dec((SV *)g);
        }
    }
    if (o) av_push(out, pmcp_oauth_guard(aTHX_ app, opts, (HV *)SvRV(o)));
    return newRV_noinc((SV *)out);
}

/* A guard's refusal, made readable by a browser client: its challenge header
 * exposed when the request came with an Origin. */
static void pmcp_expose_refusal(pTHX_ SV *out, int cors)
{
    if (!cors || !pmcp_is_array(out) || av_len((AV *)SvRV(out)) < 1) return;
    {
        SV **hp = av_fetch((AV *)SvRV(out), 1, 0);
        if (hp && pmcp_is_array(*hp)) {
            av_push((AV *)SvRV(*hp), newSVpvs("Access-Control-Expose-Headers"));
            av_push((AV *)SvRV(*hp), newSVpvs(PMCP_EXPOSE));
        }
    }
}

/* ---- principal ------------------------------------------------------------------------ */

/* `principal`, once a request is let in: what it returns is $c->mcp_user, and
 * through the stash copy it reaches every tool call. A die is a 500, as a die
 * in a guard is. */
static void pmcp_principal_run(pTHX_ SV *c, SV *principal)
{
    SV *u, *stash;
    if (!principal) return;
    u = pmcp_call_sv(aTHX_ principal, &c, 1, G_SCALAR, NULL);
    sv_2mortal(u);
    stash = sv_2mortal(pmcp_call_method(aTHX_ c, "stash", NULL, 0, G_SCALAR, NULL));
    if (pmcp_is_hash(stash)) (void)hv_stores((HV *)SvRV(stash), "mcp.user", newSVsv(u));
}

/* ---- the RFC 9728 document -------------------------------------------------------------- */

/* GET on both well-known paths. Public by design, so any origin may read it.
 * cap = [the frozen bytes] */
XS_INTERNAL(pmcp_prm_cb)
{
    dXSARGS;
    SV *bytes = pmcp_cap(aTHX_ cv, 0);
    AV *t = newAV(), *h = newAV(), *b = newAV();
    PERL_UNUSED_VAR(items);
    av_push(h, newSVpvs("Content-Type"));
    av_push(h, newSVpvs("application/json"));
    av_push(h, newSVpvs("Cache-Control"));
    av_push(h, newSVpvs("public, max-age=3600"));
    av_push(h, newSVpvs("Access-Control-Allow-Origin"));
    av_push(h, newSVpvs("*"));
    av_push(b, newSVsv(bytes));
    av_push(t, newSViv(200));
    av_push(t, newRV_noinc((SV *)h));
    av_push(t, newRV_noinc((SV *)b));
    SP = PL_stack_base + ax - 1;
    ST(0) = sv_2mortal(newRV_noinc((SV *)t));
    XSRETURN(1);
}

static void pmcp_prm_install(pTHX_ SV *app, HV *opts)
{
    HV *o = pmcp_is_hash(pmcp_hget(aTHX_ opts, "oauth"))
          ? (HV *)SvRV(pmcp_hget(aTHX_ opts, "oauth")) : NULL;
    HV *doc;
    SV *v, *bytes, *err = NULL;
    AV *as;
    int k;
    if (!o) return;
    doc = newHV();
    (void)hv_stores(doc, "resource", newSVsv(pmcp_resource_url(aTHX_ app, opts)));
    as = newAV();
    av_push(as, newSVsv(pmcp_hget(aTHX_ o, "issuer")));
    (void)hv_stores(doc, "authorization_servers", newRV_noinc((SV *)as));
    (void)hv_stores(doc, "scopes_supported",
                    newSVsv(pmcp_list_or_one(aTHX_ pmcp_hget(aTHX_ o, "scopes"))));
    {
        AV *bm = newAV();
        av_push(bm, newSVpvs("header"));
        (void)hv_stores(doc, "bearer_methods_supported", newRV_noinc((SV *)bm));
    }
    if ((v = pmcp_hget(aTHX_ opts, "title"))) (void)hv_stores(doc, "resource_name", pmcp_str(aTHX_ v));
    if ((v = pmcp_hget(aTHX_ opts, "website")))
        (void)hv_stores(doc, "resource_documentation", pmcp_str(aTHX_ v));
    bytes = pmcp_json_trapped(aTHX_ sv_2mortal(newRV_noinc((SV *)doc)), &err);
    if (!bytes) pmcp_croak_sv(aTHX_ sv_2mortal(err));
    sv_2mortal(bytes);
    for (k = 0; k < 2; k++) {
        AV *cap = newAV();
        SV *argv[3], *r;
        SV *path = sv_2mortal(newSVpvs(PMCP_PRM_PATH));
        if (k) sv_catsv(path, pmcp_hget(aTHX_ opts, "path"));
        av_push(cap, newSVsv(bytes));
        argv[0] = sv_2mortal(newSVpvs("GET"));
        argv[1] = path;
        argv[2] = sv_2mortal(pmcp_closure(aTHX_ pmcp_prm_cb, cap));
        r = pmcp_call_method(aTHX_ app, "route", argv, 3, G_SCALAR, NULL);
        if (r) SvREFCNT_dec(r);
    }
}

#endif /* PMCP_AUTH_H */
