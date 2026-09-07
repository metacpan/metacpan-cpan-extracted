#ifndef PCHAL_ANSWER_H
#define PCHAL_ANSWER_H

/* The answer: what a request that must prove itself is told. Negotiated on
 * Accept through $c->respond_to.
 *
 * A browser (text/html) gets the interstitial: status 503, the page with
 * the puzzle in a data attribute, Cache-Control: no-store, Retry-After: 0.
 * 503 and not 403 or 429, deliberately: a search engine that trips an
 * `after` rule on a crawl should come back later, and 503 is the code that
 * says so; 403 is the code that says "drop this URL from the index".
 *
 * Anything else gets 403 with a JSON body and a header:
 *
 *     HTTP/1.1 403 Forbidden
 *     X-Challenge: v1.1725600000.16.k3x-2f.Zm9vYmFy...
 *     Content-Type: application/json
 *
 *     { "error": "challenge",
 *       "challenge": { "puzzle": "v1...", "bits": 16,
 *                      "verify": "/challenge/verify",
 *                      "header": "X-Challenge-Response" } }
 *
 * The JSON names the header and the route so a client library does not
 * have to carry them as constants. JSON is registered first, so a client
 * with no preference - no Accept, or curl's wildcard - gets the shape a
 * program can act on, and only a request that names text/html gets a page.
 *
 * `render => sub { ... }` or a context method name replaces the shipped
 * page, receiving the same values in a hashref: puzzle, bits, verify, to.
 *
 * Every outcome carries Vary: Accept, which respond_to adds.
 *
 * Must be included after pchal_gate.h and pchal_page.h.
 */

/* The five values a page needs, as a hash: the puzzle, its bits, the
 * verify route and the solver under SCRIPT_NAME, and where to go after -
 * this request's own URL, re-encoded from the decoded PATH_INFO. Mortal. */
static HV *pchal_answer_vars(pTHX_ SV *c, HV *opts, SV *puzzle, IV bits)
{
    HV *vars = newHV();
    SV *sn = pchal_env(aTHX_ c, "SCRIPT_NAME");
    SV *pi = pchal_env(aTHX_ c, "PATH_INFO");
    SV *qs = pchal_env(aTHX_ c, "QUERY_STRING");
    SV *prefix = pchal_hget(aTHX_ opts, "prefix");
    SV *ver = get_sv("Punk::Challenge::VERSION", 0);
    SV *verify, *script, *to;
    STRLEN l;
    const char *p;

    (void)sv_2mortal(newRV_noinc((SV *)vars));

    verify = newSVpvs("");
    if (sn) sv_catsv(verify, sn);
    if (prefix) sv_catsv(verify, prefix); else sv_catpvs(verify, "/challenge");
    script = newSVsv(verify);
    sv_catpvs(verify, "/verify");
    sv_catpvs(script, "/challenge.js?v=");
    if (ver && SvOK(ver)) sv_catsv(script, ver);

    to = newSVpvs("");
    if (sn) sv_catsv(to, sn);
    p = pi ? SvPV_const(pi, l) : "/";
    if (!pi) l = 1;
    if (!l) { p = "/"; l = 1; }
    /* A path beginning "//" is a scheme-relative URL to a browser, and this
     * value is where the browser is sent afterwards: the same rule
     * safe_path applies on the way back, applied on the way out. */
    if (l >= 2 && p[0] == '/' && p[1] == '/') { p = "/"; l = 1; }
    pchal_pct_cat(aTHX_ to, p, l, 1);
    if (qs && SvCUR(qs)) {
        STRLEN ql;
        const char *qp = SvPV_const(qs, ql);
        sv_catpvs(to, "?");
        pchal_query_cat(aTHX_ to, qp, ql);
    }

    (void)hv_stores(vars, "puzzle", newSVsv(puzzle));
    (void)hv_stores(vars, "bits",   newSViv(bits));
    (void)hv_stores(vars, "verify", verify);
    (void)hv_stores(vars, "script", script);
    (void)hv_stores(vars, "to",     to);
    return vars;
}

static void pchal_set_header(pTHX_ SV *c, const char *name, SV *value)
{
    SV *argv[2];
    argv[0] = sv_2mortal(newSVpv(name, 0));
    argv[1] = value;
    SvREFCNT_dec(pchal_call(aTHX_ c, "header", argv, 2));
}

/* The html handler for respond_to: capture [app, vars]. */
XS_INTERNAL(pchal_answer_html_cb);
XS_INTERNAL(pchal_answer_html_cb)
{
    dXSARGS;
    SV *app = pchal_cap_slot(aTHX_ cv, 0);
    SV *varsrv = pchal_cap_slot(aTHX_ cv, 1);
    SV *c = items > 0 ? ST(0) : NULL;
    HV *opts, *h, *vars;
    SV *render, *page, *r;

    if (!c || !pchal_is_hash(varsrv)) XSRETURN_EMPTY;
    opts = pchal_opts_of(aTHX_ app);
    h = pchal_app_hv(aTHX_ app);
    vars = (HV *)SvRV(varsrv);

    pchal_set_header(aTHX_ c, "Cache-Control", sv_2mortal(newSVpvs("no-store")));
    pchal_set_header(aTHX_ c, "Retry-After",   sv_2mortal(newSVpvs("0")));

    render = pchal_hget(aTHX_ opts, "render");
    if (render) {
        /* the application's own page: a coderef, or a context method */
        SV *argv[2];
        argv[0] = c;
        argv[1] = varsrv;
        if (pchal_is_code(render)) r = pchal_call_code(aTHX_ render, argv, 2);
        else r = pchal_call(aTHX_ c, SvPV_nolen_const(render), &varsrv, 1);
        ST(0) = sv_2mortal(r);
        XSRETURN(1);
    }

    page = h ? pchal_hget(aTHX_ h, "challenge_page") : NULL;
    if (!page)
        croak("%s: the interstitial was not loaded at register", PCHAL_WHO);
    {
        SV *body = sv_2mortal(pchal_page_render(aTHX_ page, vars));
        SV *argv[2];
        argv[0] = body;
        argv[1] = sv_2mortal(newSViv(503));
        r = pchal_call(aTHX_ c, "html", argv, 2);
    }
    ST(0) = sv_2mortal(r);
    XSRETURN(1);
}

/* The json handler for respond_to, and the `any` fallback: capture
 * [app, vars]. */
XS_INTERNAL(pchal_answer_json_cb);
XS_INTERNAL(pchal_answer_json_cb)
{
    dXSARGS;
    SV *app = pchal_cap_slot(aTHX_ cv, 0);
    SV *varsrv = pchal_cap_slot(aTHX_ cv, 1);
    SV *c = items > 0 ? ST(0) : NULL;
    HV *vars, *body, *ch;
    SV *puzzle, *r;

    if (!c || !pchal_is_hash(varsrv)) XSRETURN_EMPTY;
    PERL_UNUSED_VAR(app);
    vars = (HV *)SvRV(varsrv);
    puzzle = pchal_hget(aTHX_ vars, "puzzle");

    pchal_set_header(aTHX_ c, "Cache-Control", sv_2mortal(newSVpvs("no-store")));
    if (puzzle) pchal_set_header(aTHX_ c, "X-Challenge", puzzle);

    ch = newHV();
    (void)hv_stores(ch, "puzzle", puzzle ? newSVsv(puzzle) : newSV(0));
    (void)hv_stores(ch, "bits",   newSVsv(pchal_hget(aTHX_ vars, "bits")));
    (void)hv_stores(ch, "verify", newSVsv(pchal_hget(aTHX_ vars, "verify")));
    (void)hv_stores(ch, "header", newSVpvs("X-Challenge-Response"));
    body = newHV();
    (void)hv_stores(body, "error",     newSVpvs("challenge"));
    (void)hv_stores(body, "challenge", newRV_noinc((SV *)ch));
    {
        SV *argv[2];
        argv[0] = sv_2mortal(newRV_noinc((SV *)body));
        argv[1] = sv_2mortal(newSViv(403));
        r = pchal_call(aTHX_ c, "json", argv, 2);
    }
    ST(0) = sv_2mortal(r);
    XSRETURN(1);
}

/* The response that demands a challenge at `bits`: a new SV (+1). */
static SV *pchal_demand(pTHX_ SV *c, HV *opts, IV bits)
{
    SV *app = pchal_cx_slot(aTHX_ c, 1);   /* the Punk::App, PCX_APP */
    SV *puzzle = sv_2mortal(pchal_issue(aTHX_ c, opts, bits));
    HV *vars = pchal_answer_vars(aTHX_ c, opts, puzzle, bits);
    SV *varsrv = sv_2mortal(newRV_inc((SV *)vars));
    SV *argv[6];
    AV *cap;

    if (!app) croak("%s: a context without its application", PCHAL_WHO);

    cap = newAV();
    av_push(cap, newSVsv(app));
    av_push(cap, newSVsv(varsrv));
    argv[0] = sv_2mortal(newSVpvs("json"));
    argv[1] = sv_2mortal(pchal_closure(aTHX_ pchal_answer_json_cb, cap));

    cap = newAV();
    av_push(cap, newSVsv(app));
    av_push(cap, newSVsv(varsrv));
    argv[2] = sv_2mortal(newSVpvs("html"));
    argv[3] = sv_2mortal(pchal_closure(aTHX_ pchal_answer_html_cb, cap));

    argv[4] = sv_2mortal(newSVpvs("any"));
    argv[5] = argv[1];

    return pchal_call(aTHX_ c, "respond_to", argv, 6);
}

#endif /* PCHAL_ANSWER_H */
