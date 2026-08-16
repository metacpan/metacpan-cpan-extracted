/* punk_headers.h - security response headers, in C.
 *
 * The `headers` keyword freezes a pair list at boot; every response is
 * decorated on the way out of pc_app_cb - after CORS, outside the preflight
 * early-return, so the 404s and 405s that never build a context and the
 * preflight 204 itself all carry the policy. A hook cannot do that, for the
 * same reason CORS is not a hook.
 *
 * Set-if-absent: a header the response already carries - from a handler,
 * a hook, or CORS - wins over the frozen policy, case-insensitively. That
 * is what lets one route relax X-Frame-Options without a second keyword.
 *
 * Include after punk_serve.h (ps_state), punk_static.h (punk_closure) and
 * punk_cors.h (pco_headers_of).
 */

#ifndef PUNK_HEADERS_H
#define PUNK_HEADERS_H

/* The bare keyword's policy. CSP and HSTS are deliberately not here: a
 * default CSP breaks every inline script it has never seen, and HSTS is a
 * commitment to HTTPS measured in months - both are opt-in by spelling. */
static const char *const PHD_DEFAULT_K[] = {
    "X-Content-Type-Options",
    "X-Frame-Options",
    "Referrer-Policy",
};
static const char *const PHD_DEFAULT_V[] = {
    "nosniff",
    "SAMEORIGIN",
    "strict-origin-when-cross-origin",
};
#define PHD_DEFAULTS 3

/* The config entry for a default header, found the way the response scan
 * matches: case-insensitively. NULL when the config never names it. */
static SV *phd_cfg_for(pTHX_ HV *cfg, const char *name) {
    HE *e;
    STRLEN nl = strlen(name);
    hv_iterinit(cfg);
    while ((e = hv_iternext(cfg))) {
        STRLEN kl; const char *k = HePV(e, kl);
        if (kl == nl && foldEQ(k, name, (I32)nl))
            return hv_iterval(cfg, e);
    }
    return NULL;
}

/* Merge the keyword's config over the defaults, once, at to_app. Returns a
 * flat name,value AV (+1): defaults first in fixed order - overridden or
 * dropped (undef) as configured - then the extra names, sorted so the frozen
 * order is deterministic. Per request this list is only read. */
static AV *phd_compile(pTHX_ HV *cfg) {
    AV *pairs = newAV();
    int i;
    for (i = 0; i < PHD_DEFAULTS; i++) {
        SV *o = phd_cfg_for(aTHX_ cfg, PHD_DEFAULT_K[i]);
        if (o && !SvOK(o)) continue;              /* undef removes a default */
        av_push(pairs, newSVpv(PHD_DEFAULT_K[i], 0));
        av_push(pairs, o ? newSVsv(o) : newSVpv(PHD_DEFAULT_V[i], 0));
    }
    {
        AV *extras = (AV *)sv_2mortal((SV *)newAV());
        HE *e; SSize_t j, n;
        hv_iterinit(cfg);
        while ((e = hv_iternext(cfg))) {
            STRLEN kl; const char *k = HePV(e, kl);
            SV *v = hv_iterval(cfg, e);
            int d, isdflt = 0;
            for (d = 0; d < PHD_DEFAULTS; d++)
                if (kl == strlen(PHD_DEFAULT_K[d])
                    && foldEQ(k, PHD_DEFAULT_K[d], (I32)kl)) { isdflt = 1; break; }
            if (isdflt || !v || !SvOK(v)) continue;
            av_push(extras, newSVpvn(k, kl));
        }
        n = av_len(extras) + 1;
        if (n > 1) sortsv(AvARRAY(extras), (STRLEN)n, Perl_sv_cmp);
        for (j = 0; j < n; j++) {
            SV **kp = av_fetch(extras, j, 0);
            SV **vp = kp && *kp ? hv_fetch(cfg, SvPVX(*kp),
                                           (I32)SvCUR(*kp), 0) : NULL;
            if (!(vp && *vp)) continue;
            av_push(pairs, newSVsv(*kp));
            av_push(pairs, newSVsv(*vp));
        }
    }
    return pairs;
}

/* The scope form of phd_compile: the keyword's pairs flattened with NO
 * default merging - a scope adds to (or, with undef, subtracts from) the
 * policy of the responses under its prefix, it does not restate the
 * application's. Names sorted so the frozen order is deterministic. */
static AV *phd_flat(pTHX_ HV *cfg) {
    AV *pairs = newAV();
    AV *names = (AV *)sv_2mortal((SV *)newAV());
    HE *e; SSize_t j, n;
    hv_iterinit(cfg);
    while ((e = hv_iternext(cfg))) {
        STRLEN kl; const char *k = HePV(e, kl);
        av_push(names, newSVpvn(k, kl));
    }
    n = av_len(names) + 1;
    if (n > 1) sortsv(AvARRAY(names), (STRLEN)n, Perl_sv_cmp);
    for (j = 0; j < n; j++) {
        SV **kp = av_fetch(names, j, 0);
        SV **vp = kp && *kp ? hv_fetch(cfg, SvPVX(*kp),
                                       (I32)SvCUR(*kp), 0) : NULL;
        if (!vp || !*vp) continue;
        av_push(pairs, newSVsv(*kp));
        av_push(pairs, newSVsv(*vp));    /* undef survives: it means drop */
    }
    return pairs;
}

/* One name into the seen set, lowercased so the set is case-insensitive.
 * A name too long for the buffer is simply never deduplicated - harmless,
 * and no real header name is 120 bytes. */
static void phd_seen_add(pTHX_ HV *seen, const char *k, STRLEN kl) {
    char buf[120];
    STRLEN i;
    if (kl > sizeof(buf)) return;
    for (i = 0; i < kl; i++) buf[i] = toLOWER(k[i]);
    (void)hv_store(seen, buf, (I32)kl, PUNK_SET_TRUE, 0);
}
static int phd_seen_has(pTHX_ HV *seen, const char *k, STRLEN kl) {
    char buf[120];
    STRLEN i;
    if (kl > sizeof(buf)) return 0;
    for (i = 0; i < kl; i++) buf[i] = toLOWER(k[i]);
    return hv_exists(seen, buf, (I32)kl);
}

/* The pair list this request's path gets: the matching scoped policies,
 * longest prefix first, then the application-wide one - first mention of a
 * name wins, and an undef mention drops the name entirely. Returns an RV
 * (+1) to the effective flat AV, or NULL when nothing applies. When no
 * scope matches this is one newSVsv of the frozen state entry. */
static SV *phd_effective(pTHX_ HV *state, HV *env) {
    SV *app_sv    = ps_state(aTHX_ state, K_HEADERS);
    SV *scoped_sv = ps_state(aTHX_ state, K_HEADERS_SCOPED);
    AV *scoped, *merged;
    HV *seen;
    SSize_t i, n;
    int hits = 0;
    SV *pi;
    const char *p; STRLEN pl;

    if (app_sv && !(SvROK(app_sv) && SvTYPE(SvRV(app_sv)) == SVt_PVAV))
        app_sv = NULL;
    if (!(scoped_sv && SvROK(scoped_sv)
          && SvTYPE(SvRV(scoped_sv)) == SVt_PVAV))
        return app_sv ? newSVsv(app_sv) : NULL;

    scoped = (AV *)SvRV(scoped_sv);
    n = av_len(scoped) + 1;
    pi = pco_env(aTHX_ env, "PATH_INFO");
    p  = pi ? SvPV_const(pi, pl) : "/";
    if (!pi) pl = 1;

    merged = NULL;
    seen = NULL;
    for (i = 0; i < n; i++) {
        SV **rp = av_fetch(scoped, i, 0);
        HV *rec; SV **x; AV *pairs;
        const char *pf; STRLEN pfl;
        SSize_t j, np;
        if (!(rp && *rp && SvROK(*rp))) continue;
        rec = (HV *)SvRV(*rp);
        x = hv_fetchs(rec, K_PREFIX, 0);
        if (x && *x && SvOK(*x)) pf = SvPV_const(*x, pfl);
        else { pf = ""; pfl = 0; }
        if (!ps_under(p, pl, pf, pfl)) continue;
        x = hv_fetchs(rec, K_HEADERS, 0);
        if (!(x && *x && SvROK(*x) && SvTYPE(SvRV(*x)) == SVt_PVAV)) continue;
        pairs = (AV *)SvRV(*x);
        if (!merged) {
            merged = newAV();
            seen = (HV *)sv_2mortal((SV *)newHV());
        }
        hits++;
        np = av_len(pairs) + 1;
        for (j = 0; j + 1 < np; j += 2) {
            SV **kp = av_fetch(pairs, j, 0);
            SV **vp = av_fetch(pairs, j + 1, 0);
            STRLEN kl; const char *k;
            if (!(kp && *kp && vp && *vp)) continue;
            k = SvPV_const(*kp, kl);
            if (phd_seen_has(aTHX_ seen, k, kl)) continue;
            phd_seen_add(aTHX_ seen, k, kl);
            if (!SvOK(*vp)) continue;        /* dropped under this prefix */
            av_push(merged, newSVsv(*kp));
            av_push(merged, newSVsv(*vp));
        }
    }
    if (!hits)
        return app_sv ? newSVsv(app_sv) : NULL;
    if (app_sv) {
        AV *pairs = (AV *)SvRV(app_sv);
        SSize_t j, np = av_len(pairs) + 1;
        for (j = 0; j + 1 < np; j += 2) {
            SV **kp = av_fetch(pairs, j, 0);
            SV **vp = av_fetch(pairs, j + 1, 0);
            STRLEN kl; const char *k;
            if (!(kp && *kp && vp && *vp)) continue;
            k = SvPV_const(*kp, kl);
            if (phd_seen_has(aTHX_ seen, k, kl)) continue;
            phd_seen_add(aTHX_ seen, k, kl);
            av_push(merged, newSVsv(*kp));
            av_push(merged, newSVsv(*vp));
        }
    }
    return newRV_noinc((SV *)merged);
}

/* Push every frozen pair the response does not already carry. The scan is the
 * case-insensitive walk Punk::Response::header does; header lists are a
 * handful of pairs, so the quadratic shape is cheaper than any index. */
static void phd_add_absent(pTHX_ AV *headers, AV *pairs) {
    SSize_t i, np = av_len(pairs) + 1;
    for (i = 0; i + 1 < np; i += 2) {
        SV **kp = av_fetch(pairs, i, 0);
        SV **vp = av_fetch(pairs, i + 1, 0);
        STRLEN kl; const char *k;
        SSize_t j, nh = av_len(headers) + 1;
        int found = 0;
        if (!(kp && *kp && vp && *vp)) continue;
        k = SvPV_const(*kp, kl);
        for (j = 0; j + 1 < nh; j += 2) {
            SV **e = av_fetch(headers, j, 0);
            STRLEN el; const char *es;
            if (!(e && *e)) continue;
            es = SvPV_const(*e, el);
            if (el == kl && foldEQ(es, k, (I32)kl)) { found = 1; break; }
        }
        if (!found) {
            av_push(headers, newSVsv(*kp));
            av_push(headers, newSVsv(*vp));
        }
    }
}

/* The responder wrapper for a streaming response - the phd twin of
 * pco_responder_cb, capturing [inner, pairs] instead of a CORS grant. */
XS_INTERNAL(phd_responder_cb);
XS_INTERNAL(phd_responder_cb) {
    dXSARGS;
    AV *cap = punk_clos_cap(aTHX_ cv);
    SV *inner, *pairs_sv;
    if (!cap || items < 1) XSRETURN_EMPTY;
    inner    = *av_fetch(cap, 0, 0);
    pairs_sv = *av_fetch(cap, 1, 0);
    {
        AV *headers = pco_headers_of(aTHX_ ST(0));
        if (headers && SvROK(pairs_sv))
            phd_add_absent(aTHX_ headers, (AV *)SvRV(pairs_sv));
    }
    {
        dSP; int count; SV *r;
        ENTER; SAVETMPS;
        PUSHMARK(SP); EXTEND(SP, 1); PUSHs(ST(0)); PUTBACK;
        count = call_sv(inner, G_SCALAR);
        SPAGAIN;
        r = count > 0 ? SvREFCNT_inc(POPs) : newSV(0);
        PUTBACK; FREETMPS; LEAVE;
        ST(0) = sv_2mortal(r);
    }
    XSRETURN(1);
}

XS_INTERNAL(phd_stream_cb);
XS_INTERNAL(phd_stream_cb) {
    dXSARGS;
    AV *cap = punk_clos_cap(aTHX_ cv);
    SV *app, *pairs_sv, *wrapped;
    AV *rcap;
    if (!cap || items < 1) XSRETURN_EMPTY;
    app      = *av_fetch(cap, 0, 0);
    pairs_sv = *av_fetch(cap, 1, 0);

    rcap = newAV();
    av_push(rcap, newSVsv(ST(0)));       /* the server's responder */
    av_push(rcap, newSVsv(pairs_sv));
    wrapped = sv_2mortal(punk_closure(aTHX_ phd_responder_cb, rcap));

    {
        dSP;
        ENTER; SAVETMPS;
        PUSHMARK(SP); EXTEND(SP, 1); PUSHs(wrapped); PUTBACK;
        (void)call_sv(app, G_VOID);
        SPAGAIN;
        PUTBACK; FREETMPS; LEAVE;
    }
    XSRETURN_EMPTY;
}

/* Decorate whatever pc_app_cb is about to return - the same three shapes
 * pco_decorate handles, with the same replacements in place. */
static void phd_decorate(pTHX_ HV *state, HV *env, SV **resp) {
    SV *pairs_sv;
    AV *pairs;

    if (!(*resp && SvROK(*resp))) return;
    pairs_sv = phd_effective(aTHX_ state, env);
    if (!pairs_sv) return;
    sv_2mortal(pairs_sv);
    pairs = (AV *)SvRV(pairs_sv);
    if (av_len(pairs) < 0) return;

    if (SvTYPE(SvRV(*resp)) == SVt_PVAV) {
        AV *headers = pco_headers_of(aTHX_ *resp);
        if (headers) phd_add_absent(aTHX_ headers, pairs);
        return;
    }

    if (SvTYPE(SvRV(*resp)) == SVt_PVCV) {
        AV *cap = newAV();
        av_push(cap, newSVsv(*resp));
        av_push(cap, newSVsv(pairs_sv));
        SvREFCNT_dec(*resp);
        *resp = punk_closure(aTHX_ phd_stream_cb, cap);
        return;
    }

    if (SvOBJECT(SvRV(*resp)) && pcx_can(aTHX_ *resp, "then")) {
        dSP; int count; SV *chained = NULL;
        ENTER; SAVETMPS;
        PUSHMARK(SP); EXTEND(SP, 2);
        PUSHs(*resp);
        PUSHs(pairs_sv);
        PUTBACK;
        count = call_pv("Punk::Headers::_chain", G_SCALAR | G_EVAL);
        SPAGAIN;
        if (count > 0 && !SvTRUE(ERRSV)) chained = SvREFCNT_inc(POPs);
        else if (count > 0) (void)POPs;
        PUTBACK; FREETMPS; LEAVE;
        if (chained) { SvREFCNT_dec(*resp); *resp = chained; }
        return;
    }
}

#endif /* PUNK_HEADERS_H */
