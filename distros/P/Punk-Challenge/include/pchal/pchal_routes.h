#ifndef PCHAL_ROUTES_H
#define PCHAL_ROUTES_H

/* The two routes, under `prefix`:
 *
 *     GET  <prefix>/challenge.js   the solver; immutable for a year, and the
 *                                  page references it with ?v=VERSION
 *     POST <prefix>/verify         a solution in; a clearance out
 *
 * There is no GET page route. The interstitial is rendered by the hook or
 * the guard that demanded it, with the puzzle already in it, so the browser
 * makes one request and gets a page it can start solving. A redirect to a
 * challenge page would cost a round trip and would need the original URL
 * carried in a query string, which is the open-redirect shape every plugin
 * in this family has had to defend once already.
 *
 * verify accepts a form (solution, to) or JSON ({ "solution": "..." }),
 * decided by Content-Type. On success, the clearance cookie, and then a
 * form is a 303 to safe_path(to, '/') - safe_path and nothing else, because
 * `to` came from the page, the page's `to` came from the request URL, and
 * the request URL came from whoever wrote the link - and JSON is a 200 with
 * { "clearance": "v1..." } for a client that will present it as a header.
 * On failure, a fresh challenge: the same answer a rule gives, so a browser
 * whose form fell back gets the page again and a program gets the JSON. A
 * wrong solution costs the client a new solve, not a lockout: there is no
 * counter of failures, because a failure is already the client's CPU
 * wasted.
 *
 * CSRF. The route is a POST without a session and it changes nothing but
 * its own cookie, so it is not a CSRF target and `csrf` must not check it.
 * Measured: `csrf` keeps its exempt list as an array on the application's
 * csrf configuration, and that configuration is there at on_compile
 * whichever side of the `plugin` line the `csrf` keyword sat on, so the
 * plugin adds its own prefix and nobody has to.
 *
 * The solver script is read once at register, beside page.html, and served
 * from memory.
 *
 * Must be included after pchal_answer.h.
 */

#define PCHAL_VERIFY_MAX_BODY 4096

/* ---- the asset -------------------------------------------------------------- */

/* The script's bytes, or a croak naming the path. A new SV. */
static SV *pchal_script_load(pTHX)
{
    SV **pm = hv_fetchs(GvHV(PL_incgv), "Punk/Challenge.pm", 0);
    SV *path, *out;
    FILE *fh;
    size_t got;
    char buf[8192];

    if (!(pm && *pm && SvOK(*pm)))
        croak("%s: cannot find Punk/Challenge.pm in %%INC to locate "
              "challenge.js", PCHAL_WHO);
    path = sv_2mortal(newSVsv(*pm));
    {
        STRLEN pl;
        const char *pp = SvPV_const(path, pl);
        if (pl >= 12 && memEQ(pp + pl - 12, "Challenge.pm", 12))
            SvCUR_set(path, pl - 12);
    }
    sv_catpvs(path, "Plugin/Challenge/challenge.js");

    fh = fopen(SvPV_nolen(path), "rb");
    if (!fh)
        croak("%s: cannot read the solver %" SVf ": %s", PCHAL_WHO,
              SVfARG(path), Strerror(errno));
    out = newSVpvs("");
    while ((got = fread(buf, 1, sizeof buf, fh)) > 0) {
        sv_catpvn(out, buf, got);
        if (SvCUR(out) > PCHAL_PAGE_MAX) {
            fclose(fh);
            SvREFCNT_dec(out);
            croak("%s: %" SVf " is larger than a script has any reason to be",
                  PCHAL_WHO, SVfARG(path));
        }
    }
    fclose(fh);
    return out;
}

/* A finished triplet: status, type, one extra header, body. +1. */
static SV *pchal_triplet(pTHX_ IV status, const char *type, const char *hname,
                         const char *hvalue, SV *body)
{
    AV *hdr = newAV(), *b = newAV(), *resp = newAV();
    av_push(hdr, newSVpvs("Content-Type"));
    av_push(hdr, newSVpv(type, 0));
    av_push(hdr, newSVpvs("Content-Length"));
    av_push(hdr, newSViv((IV)SvCUR(body)));
    if (hname) {
        av_push(hdr, newSVpv(hname, 0));
        av_push(hdr, newSVpv(hvalue, 0));
    }
    av_push(b, newSVsv(body));
    av_push(resp, newSViv(status));
    av_push(resp, newRV_noinc((SV *)hdr));
    av_push(resp, newRV_noinc((SV *)b));
    return newRV_noinc((SV *)resp);
}

XS_INTERNAL(pchal_asset_cb);
XS_INTERNAL(pchal_asset_cb)
{
    dXSARGS;
    SV *app = pchal_cap_slot(aTHX_ cv, 0);
    HV *h = app ? pchal_app_hv(aTHX_ app) : NULL;
    SV *js = h ? pchal_hget(aTHX_ h, "challenge_js") : NULL;
    PERL_UNUSED_VAR(items);
    if (!js) croak("%s: the solver was not loaded at register", PCHAL_WHO);
    ST(0) = sv_2mortal(pchal_triplet(aTHX_ 200,
                                     "application/javascript; charset=utf-8",
                                     "Cache-Control",
                                     "public, max-age=31536000, immutable",
                                     js));
    XSRETURN(1);
}

/* ---- verify ------------------------------------------------------------------ */

/* Does this request's Content-Type say JSON? */
static int pchal_is_json_body(pTHX_ SV *c)
{
    SV *ct = pchal_env(aTHX_ c, "CONTENT_TYPE");
    STRLEN l;
    const char *p;
    if (!ct) return 0;
    p = SvPV_const(ct, l);
    return l >= 16 && ibcmp(p, "application/json", 16) == 0;
}

XS_INTERNAL(pchal_verify_cb);
XS_INTERNAL(pchal_verify_cb)
{
    dXSARGS;
    SV *app = pchal_cap_slot(aTHX_ cv, 0);
    SV *c = items > 0 ? ST(0) : NULL;
    HV *opts;
    SV *subject, *solution = NULL, *to = NULL, *r;
    int json;
    IV got = 0;
    pchal_reason reason = PCHAL_SHAPE;

    if (!c) XSRETURN_EMPTY;
    opts = pchal_opts_of(aTHX_ app);
    json = pchal_is_json_body(aTHX_ c);

    if (json) {
        /* $c->req->json, under an eval: the body is the network's */
        SV *req = sv_2mortal(pchal_call(aTHX_ c, "req", NULL, 0));
        int failed = 0;
        SV *data = req && SvROK(req)
                 ? pchal_try(aTHX_ req, "json", NULL, 0, &failed) : NULL;
        if (data) {
            sv_2mortal(data);
            if (pchal_is_hash(data))
                solution = pchal_hget(aTHX_ (HV *)SvRV(data), "solution");
        }
    }
    else {
        SV *name = sv_2mortal(newSVpvs("solution"));
        SV *tname = sv_2mortal(newSVpvs("to"));
        solution = sv_2mortal(pchal_call(aTHX_ c, "param", &name, 1));
        to = sv_2mortal(pchal_call(aTHX_ c, "param", &tname, 1));
    }

    subject = sv_2mortal(pchal_subject_of(aTHX_ c, opts));
    if (solution && SvOK(solution) && !SvROK(solution)) {
        STRLEN sl;
        const char *sp = SvPV_const(solution, sl);
        reason = pchal_puzzle_verify(aTHX_ opts, subject, sp, sl, 1, 0, &got);
    }

    if (reason != PCHAL_OK) {
        pchal_log_refused(aTHX_ c, "verify", reason);
        ST(0) = sv_2mortal(pchal_demand(aTHX_ c, opts,
                                        pchal_bits_for(aTHX_ opts, NULL)));
        XSRETURN(1);
    }

    {
        SV *value = sv_2mortal(pchal_clear(aTHX_ c, opts, got));
        if (json) {
            HV *body = newHV();
            SV *argv[2];
            (void)hv_stores(body, "clearance", newSVsv(value));
            argv[0] = sv_2mortal(newRV_noinc((SV *)body));
            argv[1] = sv_2mortal(newSViv(200));
            r = pchal_call(aTHX_ c, "json", argv, 2);
        }
        else {
            SV *argv[2];
            SV *safe;
            argv[0] = (to && SvOK(to)) ? to : &PL_sv_undef;
            argv[1] = sv_2mortal(newSVpvs("/"));
            safe = sv_2mortal(pchal_call(aTHX_ c, "safe_path", argv, 2));
            argv[0] = safe;
            argv[1] = sv_2mortal(newSViv(303));
            r = pchal_call(aTHX_ c, "redirect", argv, 2);
        }
    }
    ST(0) = sv_2mortal(r);
    XSRETURN(1);
}

/* ---- installing --------------------------------------------------------------- */

static void pchal_route(pTHX_ SV *app, const char *method, SV *path,
                        XSUBADDR_t body, AV *cap, IV max_body)
{
    SV *argv[5];
    HV *o = newHV();
    (void)hv_stores(o, "sitemap", newSViv(0));
    if (max_body) (void)hv_stores(o, "max_body", newSViv(max_body));
    argv[0] = sv_2mortal(newSVpv(method, 0));
    argv[1] = path;
    argv[2] = sv_2mortal(pchal_closure(aTHX_ body, cap));
    argv[3] = &PL_sv_undef;
    argv[4] = sv_2mortal(newRV_noinc((SV *)o));
    SvREFCNT_dec(pchal_call(aTHX_ app, "route", argv, 5));
}

static void pchal_install_routes(pTHX_ SV *app, HV *opts)
{
    HV *h = pchal_app_hv(aTHX_ app);
    SV *prefix = pchal_hget(aTHX_ opts, "prefix");
    SV *assets = pchal_hget(aTHX_ opts, "assets");
    SV *path;
    AV *cap;
    if (!h) return;

    path = sv_2mortal(prefix ? newSVsv(prefix) : newSVpvs("/challenge"));
    sv_catpvs(path, "/verify");
    cap = newAV();
    av_push(cap, newSVsv(app));
    pchal_route(aTHX_ app, "POST", path, pchal_verify_cb, cap,
                PCHAL_VERIFY_MAX_BODY);

    if (assets && SvTRUE(assets)) {
        (void)hv_stores(h, "challenge_js", pchal_script_load(aTHX));
        path = sv_2mortal(prefix ? newSVsv(prefix) : newSVpvs("/challenge"));
        sv_catpvs(path, "/challenge.js");
        cap = newAV();
        av_push(cap, newSVsv(app));
        pchal_route(aTHX_ app, "GET", path, pchal_asset_cb, cap, 0);
    }
}

/* At on_compile: the prefix onto csrf's exempt list when csrf is on. The
 * entry ends in a slash because csrf matches a raw string prefix, and
 * "/challenge" alone would exempt "/challenger" too. */
static void pchal_csrf_exempt(pTHX_ SV *app, HV *opts)
{
    HV *h = pchal_app_hv(aTHX_ app);
    SV *cs = h ? pchal_hget(aTHX_ h, "csrf") : NULL;
    HV *cfg;
    AV *list;
    SV *entry;
    if (!pchal_is_hash(cs)) return;
    cfg = (HV *)SvRV(cs);
    list = pchal_app_av(aTHX_ cfg, "exempt");
    entry = newSVsv(pchal_hget(aTHX_ opts, "prefix"));
    if (!SvOK(entry)) sv_setpvs(entry, "/challenge");
    sv_catpvs(entry, "/");
    av_push(list, entry);
}

#endif /* PCHAL_ROUTES_H */
