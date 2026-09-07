#ifndef PCHAL_GATE_H
#define PCHAL_GATE_H

/* The gate: what the guard, the helpers and the rule hook all do, stated
 * once. Is this request cleared at this difficulty; demand a challenge;
 * issue a puzzle for this request's subject; set the clearance cookie.
 *
 * Three of the four are the token operations over this request's subject.
 * The fourth, the answer - the negotiated 503 page or 403 JSON - is
 * pchal_answer.h's.
 *
 * Must be included after pchal_subject.h and pchal_token.h.
 */

/* The plugin's options on this app, or a croak naming the line to add. A
 * keyword may be installed by `import` alone - `use Punk::Plugin::Challenge`
 * without `plugin 'Challenge'` - so a guard can exist with nothing to guard
 * with, exactly as auth_guard can without `auth`. */
static HV *pchal_opts_of(pTHX_ SV *app)
{
    HV *h = pchal_app_hv(aTHX_ app);
    SV *o = h ? pchal_hget(aTHX_ h, "challenge_opts") : NULL;
    if (!pchal_is_hash(o))
        croak("%s: needs the plugin (add `plugin 'Challenge' => { secret => "
              "... }`)", PCHAL_WHO);
    return (HV *)SvRV(o);
}

/* A difficulty: the explicit one when there is one, else the plugin's
 * default. `explicit` is an IV SV or NULL. */
static IV pchal_bits_for(pTHX_ HV *opts, SV *explicit)
{
    SV *d;
    if (explicit && SvOK(explicit)) return SvIV(explicit);
    d = pchal_hget(aTHX_ opts, "bits");
    return d ? SvIV(d) : 16;
}

/* One cookie's value out of a Cookie header: `name=value` between
 * semicolons, spaces around either ignored. The value is not decoded - a
 * clearance is base64url and decimals and dots, none of which a jar
 * encodes. */
static int pchal_cookie_find(const char *h, STRLEN hl, const char *name,
                             STRLEN nl, const char **vp, STRLEN *vl)
{
    STRLEN i = 0;
    while (i < hl) {
        STRLEN start, end;
        while (i < hl && (h[i] == ' ' || h[i] == '\t' || h[i] == ';')) i++;
        start = i;
        while (i < hl && h[i] != ';') i++;
        end = i;
        while (end > start && (h[end - 1] == ' ' || h[end - 1] == '\t')) end--;
        if (end - start > nl + 1 && memEQ(h + start, name, nl)
            && h[start + nl] == '=') {
            *vp = h + start + nl + 1;
            *vl = end - (start + nl + 1);
            return 1;
        }
    }
    return 0;
}

/* Which check refused what, to the request log at debug. The client is told
 * nothing. Only called when something WAS presented, so a bare context in a
 * test never reaches the logger. */
static void pchal_log_refused(pTHX_ SV *c, const char *what, pchal_reason r)
{
    SV *logger, *msg;
    if (!pchal_can(aTHX_ c, "log")) return;
    logger = sv_2mortal(pchal_call(aTHX_ c, "log", NULL, 0));
    if (!(logger && SvROK(logger))) return;
    msg = sv_2mortal(newSVpvf("challenge: %s refused (%s)", what,
                              pchal_reason_str(r)));
    SvREFCNT_dec(pchal_call(aTHX_ logger, "debug", &msg, 1));
}

/* Does the request carry a valid clearance at or above `bits`? Three places
 * to carry one, cheapest and commonest first: the cookie, the X-Clearance
 * header for a client without a jar, and X-Challenge-Response carrying a
 * whole solution for a client that would rather burn CPU than keep a
 * cookie. All three grant the same thing. */
static int pchal_cleared(pTHX_ SV *c, HV *opts, IV bits)
{
    SV *subject = sv_2mortal(pchal_subject_of(aTHX_ c, opts));
    SV *v;
    IV got = 0;
    pchal_reason r;

    v = pchal_env(aTHX_ c, "HTTP_COOKIE");
    if (v) {
        SV *name = pchal_hget(aTHX_ opts, "cookie");
        STRLEN hl, nl = 10, vl;
        const char *hp = SvPV_const(v, hl), *np = "_clearance", *vp;
        if (name) np = SvPV_const(name, nl);
        if (pchal_cookie_find(hp, hl, np, nl, &vp, &vl)) {
            r = pchal_clearance_verify(aTHX_ opts, subject, vp, vl, bits, 0, &got);
            if (r == PCHAL_OK) return 1;
            pchal_log_refused(aTHX_ c, "clearance cookie", r);
        }
    }

    v = pchal_env(aTHX_ c, "HTTP_X_CLEARANCE");
    if (v) {
        STRLEN vl;
        const char *vp = SvPV_const(v, vl);
        r = pchal_clearance_verify(aTHX_ opts, subject, vp, vl, bits, 0, &got);
        if (r == PCHAL_OK) return 1;
        pchal_log_refused(aTHX_ c, "X-Clearance", r);
    }

    v = pchal_env(aTHX_ c, "HTTP_X_CHALLENGE_RESPONSE");
    if (v) {
        STRLEN vl;
        const char *vp = SvPV_const(v, vl);
        r = pchal_puzzle_verify(aTHX_ opts, subject, vp, vl, bits, 0, &got);
        if (r == PCHAL_OK) return 1;
        pchal_log_refused(aTHX_ c, "X-Challenge-Response", r);
    }

    return 0;
}

/* A fresh puzzle string for this request's subject at `bits`: a new SV. */
static SV *pchal_issue(pTHX_ SV *c, HV *opts, IV bits)
{
    SV *subject = sv_2mortal(pchal_subject_of(aTHX_ c, opts));
    return pchal_puzzle_issue(aTHX_ opts, subject, bits, 0);
}

/* Set the clearance cookie for this request's subject at `bits`:
 *
 *   Set-Cookie: _clearance=v1...; Path=/; Max-Age=ttl; HttpOnly; SameSite=Lax; Secure
 *
 * Secure when the request came over https, which `proxy` also gets right.
 * Returns the value, for a body that hands it back as well: a new SV. */
static SV *pchal_clear(pTHX_ SV *c, HV *opts, IV bits)
{
    SV *subject = sv_2mortal(pchal_subject_of(aTHX_ c, opts));
    SV *value = pchal_clearance_issue(aTHX_ opts, subject, bits, 0);
    SV *name = pchal_hget(aTHX_ opts, "cookie");
    SV *scheme = pchal_env(aTHX_ c, "psgi.url_scheme");
    HV *attrs = newHV();
    SV *argv[3];
    int https = 0;

    if (scheme) {
        STRLEN sl;
        const char *sp = SvPV_const(scheme, sl);
        https = (sl == 5 && memEQ(sp, "https", 5));
    }
    (void)hv_stores(attrs, "path",     newSVpvs("/"));
    (void)hv_stores(attrs, "max_age",  newSViv(pchal_opt_iv_of(aTHX_ opts, "ttl", 3600)));
    (void)hv_stores(attrs, "httponly", newSViv(1));
    (void)hv_stores(attrs, "samesite", newSVpvs("Lax"));
    (void)hv_stores(attrs, "secure",   newSViv(https));

    argv[0] = name ? name : sv_2mortal(newSVpvs("_clearance"));
    argv[1] = value;
    argv[2] = sv_2mortal(newRV_noinc((SV *)attrs));
    SvREFCNT_dec(pchal_call(aTHX_ c, "cookie", argv, 3));
    return value;
}

/* The response that demands a challenge at `bits`: a new SV (+1). Defined
 * in pchal_answer.h, which needs the page and the closure device; declared
 * here because the guard and the helpers, which come first, call it. */
static SV *pchal_demand(pTHX_ SV *c, HV *opts, IV bits);

#endif /* PCHAL_GATE_H */
