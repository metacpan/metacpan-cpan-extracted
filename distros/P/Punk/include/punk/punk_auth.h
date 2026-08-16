/* punk_auth.h - the authentication battery's request path, in C.
 *
 * The `auth` keyword freezes a config on the app; auth_guard() returns a
 * guard coderef for `under`. The guard's common case - "is anyone signed
 * in" - runs entirely here: one session load, one hash fetch. Role and
 * verified checks need the user row, so they fall through to
 * Punk::Auth::_guard_check, which loads it through the model (and the
 * await seam, so both database backends work).
 *
 * Denial negotiates: a client whose Accept asks for text/html is redirected
 * to the login page with ?to=<path> (relative return-to); anything else gets
 * a 401 in the house error shape. on_denied overrides with '403', '404' (the
 * queue_admin do-not-confirm-it-exists option) or a coderef.
 *
 * Include after punk_session.h (ps_load, ps_cfg_str, ps_stash), punk_csrf.h,
 * punk_accept.h (the Accept parser) and punk_static.h (punk_closure).
 */

#ifndef PUNK_AUTH_H
#define PUNK_AUTH_H

/* the app's frozen auth config, from a context - the pcf_cfg shape */
static HV *pauth_cfg(pTHX_ SV *c) {
    SV *app = pcx_get(aTHX_ pcx_av(aTHX_ c), PCX_APP);
    SV **s;
    if (!(app && SvROK(app) && SvTYPE(SvRV(app)) == SVt_PVHV)) return NULL;
    s = hv_fetchs((HV *)SvRV(app), K_AUTH, 0);
    return (s && *s && SvROK(*s) && SvTYPE(SvRV(*s)) == SVt_PVHV)
        ? (HV *)SvRV(*s) : NULL;
}

/* the signed-in user id from the session, or NULL. Returns +1. */
static SV *pauth_session_id(pTHX_ SV *c, HV *cfg) {
    STRLEN kl;
    const char *key = ps_cfg_str(aTHX_ cfg, "session_key", "user_id", &kl);
    SV *sess = ps_load(aTHX_ c);
    SV *out = NULL;
    if (sess && SvROK(sess) && SvTYPE(SvRV(sess)) == SVt_PVHV) {
        SV **e = hv_fetch((HV *)SvRV(sess), key, (I32)kl, 0);
        if (e && *e && SvOK(*e)) out = newSVsv(*e);
    }
    if (sess) SvREFCNT_dec(sess);
    return out;
}

/* percent-encode a path for the ?to= value - unreserved chars and '/' pass */
static SV *pauth_escape(pTHX_ const char *s, STRLEN len) {
    static const char hex[] = "0123456789ABCDEF";
    SV *out = newSVpvs("");
    STRLEN i;
    for (i = 0; i < len; i++) {
        unsigned char ch = (unsigned char)s[i];
        if ((ch >= 'A' && ch <= 'Z') || (ch >= 'a' && ch <= 'z')
            || (ch >= '0' && ch <= '9') || ch == '-' || ch == '_'
            || ch == '.' || ch == '~' || ch == '/')
            sv_catpvn(out, (const char *)&s[i], 1);
        else {
            char e[3] = { '%', hex[ch >> 4], hex[ch & 15] };
            sv_catpvn(out, e, 3);
        }
    }
    return out;
}

/* a small finished triplet: status + type + body (+1) */
static SV *pauth_triplet(pTHX_ IV status, const char *type,
                         const char *body, STRLEN blen) {
    AV *hdr = newAV(), *b = newAV(), *resp = newAV();
    av_push(hdr, newSVpvs("Content-Type"));
    av_push(hdr, newSVpv(type, 0));
    av_push(hdr, newSVpvs("Content-Length"));
    av_push(hdr, newSViv((IV)blen));
    av_push(b, newSVpvn(body, blen));
    av_push(resp, newSViv(status));
    av_push(resp, newRV_noinc((SV *)hdr));
    av_push(resp, newRV_noinc((SV *)b));
    return newRV_noinc((SV *)resp);
}

#define PAUTH_401_BODY "{\"errors\":[{\"message\":\"Unauthorized\"}]}"
#define PAUTH_403_BODY "{\"errors\":[{\"message\":\"Forbidden\"}]}"
#define PAUTH_404_BODY "{\"errors\":[{\"message\":\"Not Found\"}]}"

/* The denial response for a failed guard (+1). opts may be NULL. */
static SV *pauth_denial(pTHX_ SV *c, HV *cfg, HV *opts) {
    SV **od = opts ? hv_fetchs(opts, "on_denied", 0) : NULL;

    if (od && *od && SvROK(*od) && SvTYPE(SvRV(*od)) == SVt_PVCV) {
        dSP; int count; SV *r = NULL;
        ENTER; SAVETMPS;
        PUSHMARK(SP); EXTEND(SP, 1); PUSHs(c); PUTBACK;
        count = call_sv(*od, G_SCALAR);
        SPAGAIN;
        if (count > 0) { SV *v = POPs; if (SvROK(v)) r = SvREFCNT_inc(v); }
        PUTBACK; FREETMPS; LEAVE;
        if (r) return r;
        /* a non-reference from on_denied falls through to the default */
    }
    else if (od && *od && SvOK(*od) && !SvROK(*od)) {
        STRLEN ol; const char *o = SvPV_const(*od, ol);
        if (ol == 3 && memEQ(o, "403", 3))
            return pauth_triplet(aTHX_ 403, "application/json",
                                 PAUTH_403_BODY, sizeof(PAUTH_403_BODY) - 1);
        if (ol == 3 && memEQ(o, "404", 3))
            return pauth_triplet(aTHX_ 404, "application/json",
                                 PAUTH_404_BODY, sizeof(PAUTH_404_BODY) - 1);
    }

    {   /* negotiate: an Accept that wants text/html gets the login redirect */
        SV *env = pcx_get(aTHX_ pcx_av(aTHX_ c), PCX_ENV);
        HV *eh = (env && SvROK(env) && SvTYPE(SvRV(env)) == SVt_PVHV)
                 ? (HV *)SvRV(env) : NULL;
        SV **ac = eh ? hv_fetchs(eh, "HTTP_ACCEPT", 0) : NULL;
        int wants_html = 0;
        if (ac && *ac && SvOK(*ac) && SvCUR(*ac)) {
            pa_range ranges[PA_RANGE_MAX];
            STRLEN al; const char *a = SvPV_const(*ac, al);
            int nr = pa_parse(a, al, ranges, PA_RANGE_MAX);
            int q = 0, order = 0;
            int spec = pa_match(aTHX_ ranges, nr, "text", 4, "html", 4,
                                &q, &order);
            wants_html = spec > 0 && q > 0;
        }
        if (wants_html) {
            STRLEN ll;
            const char *login = ps_cfg_str(aTHX_ cfg, "login_path",
                                           "/login", &ll);
            SV *loc = newSVpvn(login, ll);
            SV **pi = eh ? hv_fetchs(eh, "PATH_INFO", 0) : NULL;
            AV *hdr = newAV(), *b = newAV(), *resp = newAV();
            if (pi && *pi && SvOK(*pi) && SvCUR(*pi)
                && !(SvCUR(*pi) == ll && memEQ(SvPVX(*pi), login, ll))) {
                STRLEN pl; const char *p = SvPV_const(*pi, pl);
                SV *esc = pauth_escape(aTHX_ p, pl);
                sv_catpvs(loc, "?to=");
                sv_catsv(loc, esc);
                SvREFCNT_dec(esc);
            }
            av_push(hdr, newSVpvs("Location"));
            av_push(hdr, loc);
            av_push(hdr, newSVpvs("Content-Length"));
            av_push(hdr, newSViv(0));
            av_push(b, newSVpvs(""));
            av_push(resp, newSViv(302));
            av_push(resp, newRV_noinc((SV *)hdr));
            av_push(resp, newRV_noinc((SV *)b));
            return newRV_noinc((SV *)resp);
        }
    }
    return pauth_triplet(aTHX_ 401, "application/json",
                         PAUTH_401_BODY, sizeof(PAUTH_401_BODY) - 1);
}

/* The await seam, in C: a plain value passes through; an object with ->get
 * is a future from a nonblocking model backend - a Punk::Future goes through
 * $c->await (the loop-aware path), anything else through its own ->get.
 * Returns +1. */
static SV *pauth_await(pTHX_ SV *c, SV *v) {
    if (!(v && SvROK(v) && SvOBJECT(SvRV(v)) && pcx_can(aTHX_ v, "get")))
        return newSVsv(v ? v : &PL_sv_undef);
    if (sv_derived_from(v, "Punk::Future")) {
        SV *argv[1], *r;
        argv[0] = v;
        r = pcx_call_meth(aTHX_ c, "await", argv, 1, 1);
        return r ? r : newSV(0);
    }
    {
        SV *r = pcx_call_meth(aTHX_ v, "get", NULL, 0, 1);
        return r ? r : newSV(0);
    }
}

/* one field name out of the auth config's fields map (borrowed pointer) */
static const char *pauth_field(pTHX_ HV *cfg, const char *name,
                               const char *def, STRLEN *lp) {
    SV **f = hv_fetchs(cfg, "fields", 0);
    if (f && *f && SvROK(*f) && SvTYPE(SvRV(*f)) == SVt_PVHV) {
        SV **e = hv_fetch((HV *)SvRV(*f), name, (I32)strlen(name), 0);
        if (e && *e && SvOK(*e)) return SvPV_const(*e, *lp);
    }
    *lp = strlen(def);
    return def;
}

/* the model instance behind a config option ('model' / 'token_model'),
 * croaking with the fix when the option was never given. Returns +1. */
static SV *pauth_model(pTHX_ SV *c, HV *cfg, const char *opt,
                       const char *what) {
    SV **mn = hv_fetch(cfg, opt, (I32)strlen(opt), 0);
    SV *argv[1], *m;
    if (!(mn && *mn && SvOK(*mn)))
        croak("Punk: %s needs `auth %s => ...`", what, opt);
    argv[0] = *mn;
    m = pcx_call_meth(aTHX_ c, "model", argv, 1, 1);
    if (!m)
        croak("Punk: %s could not build the %s model", what, opt);
    return m;
}

/* the rows arrayref out of a search result (borrowed), or NULL */
static AV *pauth_rows(pTHX_ SV *res) {
    SV **r;
    if (!(res && SvROK(res) && SvTYPE(SvRV(res)) == SVt_PVHV)) return NULL;
    r = hv_fetchs((HV *)SvRV(res), "rows", 0);
    return (r && *r && SvROK(*r) && SvTYPE(SvRV(*r)) == SVt_PVAV)
        ? (AV *)SvRV(*r) : NULL;
}

/* the stash's punk.auth slot, autovivified (borrowed) */
static HV *pauth_memo(pTHX_ SV *c) {
    HV *stash = ps_stash(aTHX_ pcx_av(aTHX_ c));
    SV **slot = hv_fetchs(stash, "punk.auth", 0);
    HV *pa;
    if (slot && *slot && SvROK(*slot) && SvTYPE(SvRV(*slot)) == SVt_PVHV)
        return (HV *)SvRV(*slot);
    pa = newHV();
    (void)hv_stores(stash, "punk.auth", newRV_noinc((SV *)pa));
    return pa;
}

/* The signed-in user's row, loaded once per request through the configured
 * model and memoized in the stash - the memo records "loaded, and it was
 * undef" as an undef entry, so a stale session costs one lookup, not one per
 * call. Returns +1 or NULL. */
static SV *pauth_current_user(pTHX_ SV *c, HV *cfg) {
    HV *pa = pauth_memo(aTHX_ c);
    SV **u = hv_fetchs(pa, "user", 0);
    SV *id, *user = NULL;
    if (u && *u) return SvOK(*u) ? newSVsv(*u) : NULL;

    id = pauth_session_id(aTHX_ c, cfg);
    if (id) {
        SV *m = pauth_model(aTHX_ c, cfg, "model", "current_user");
        STRLEN idl;
        const char *idf = pauth_field(aTHX_ cfg, "id", "id", &idl);
        SV *argv[2], *raw, *got;
        argv[0] = sv_2mortal(newSVpvn(idf, idl));
        argv[1] = id;
        raw = pcx_call_meth(aTHX_ m, "get", argv, 2, 1);
        SvREFCNT_dec(m);
        SvREFCNT_dec(id);
        got = pauth_await(aTHX_ c, raw ? raw : &PL_sv_undef);
        if (raw) SvREFCNT_dec(raw);
        if (got && SvROK(got) && SvTYPE(SvRV(got)) == SVt_PVHV) user = got;
        else if (got) SvREFCNT_dec(got);
    }
    (void)hv_stores(pa, "user", user ? newSVsv(user) : newSV(0));
    return user;
}

/* The role/verified half of a guard, reached only when the guard has
 * options. The roles hook may return one name, a list, or an arrayref - a
 * user can hold several roles. A required role in the rank ladder means
 * "this or better"; one outside it is orthogonal and matches exactly.
 * Returns a denial response (+1) or NULL to pass. */
static SV *pauth_check(pTHX_ SV *c, HV *cfg, HV *opts) {
    SV *user = pauth_current_user(aTHX_ c, cfg);
    SV **od;
    if (!user) return pauth_denial(aTHX_ c, cfg, opts);

    od = hv_fetchs(opts, "verified", 0);
    if (od && *od && SvTRUE(*od)) {
        STRLEN vl;
        const char *vf = pauth_field(aTHX_ cfg, "verified", "verified", &vl);
        SV **e = hv_fetch((HV *)SvRV(user), vf, (I32)vl, 0);
        if (!(e && *e && SvTRUE(*e))) {
            SvREFCNT_dec(user);
            return pauth_denial(aTHX_ c, cfg, opts);
        }
    }

    od = hv_fetchs(opts, "role", 0);
    if (od && *od && SvOK(*od)) {
        SV **rl = hv_fetchs(cfg, "roles", 0);
        SV **rk = hv_fetchs(cfg, "rank", 0);
        AV *rank = (rk && *rk && SvROK(*rk)
                    && SvTYPE(SvRV(*rk)) == SVt_PVAV)
                   ? (AV *)SvRV(*rk) : NULL;
        static const char *const DEFAULT_RANK[] =
            { "member", "admin", "owner" };
        AV *have = (AV *)sv_2mortal((SV *)newAV());
        STRLEN nl;
        const char *need = SvPV_const(*od, nl);
        SSize_t i, hn;
        IV need_idx = -1;
        int ok = 0;

        if (!(rl && *rl && SvROK(*rl) && SvTYPE(SvRV(*rl)) == SVt_PVCV)) {
            SvREFCNT_dec(user);
            croak("Punk: auth_guard role checks need "
                  "`auth roles => sub { ... }`");
        }
        {   /* the hook, in list context */
            dSP; int count, j;
            ENTER; SAVETMPS;
            PUSHMARK(SP); EXTEND(SP, 2);
            PUSHs(c); PUSHs(user); PUTBACK;
            count = call_sv(*rl, G_ARRAY);
            SPAGAIN;
            for (j = 0; j < count; j++) {
                SV *v = POPs;      /* never inside a multi-eval macro */
                (void)av_store(have, count - 1 - j, newSVsv(v));
            }
            PUTBACK; FREETMPS; LEAVE;
        }
        if (av_len(have) == 0) {   /* one return that is an arrayref: flatten */
            SV **h0 = av_fetch(have, 0, 0);
            if (h0 && *h0 && SvROK(*h0) && SvTYPE(SvRV(*h0)) == SVt_PVAV) {
                AV *inner = (AV *)SvRV(*h0);
                AV *flat = (AV *)sv_2mortal((SV *)newAV());
                SSize_t k, n2 = av_len(inner) + 1;
                for (k = 0; k < n2; k++) {
                    SV **e = av_fetch(inner, k, 0);
                    if (e && *e) av_push(flat, newSVsv(*e));
                }
                have = flat;
            }
        }

        {   /* where does the required role sit on the ladder? */
            SSize_t rn = rank ? av_len(rank) + 1
                              : (SSize_t)(sizeof(DEFAULT_RANK)
                                          / sizeof(*DEFAULT_RANK));
            for (i = 0; i < rn; i++) {
                STRLEN xl; const char *x;
                if (rank) {
                    SV **e = av_fetch(rank, i, 0);
                    if (!(e && *e && SvOK(*e))) continue;
                    x = SvPV_const(*e, xl);
                }
                else { x = DEFAULT_RANK[i]; xl = strlen(x); }
                if (xl == nl && memEQ(x, need, nl)) { need_idx = (IV)i; break; }
            }
        }
        hn = av_len(have) + 1;
        for (i = 0; i < hn && !ok; i++) {
            SV **hp = av_fetch(have, i, 0);
            STRLEN hl; const char *h;
            if (!(hp && *hp && SvOK(*hp))) continue;
            h = SvPV_const(*hp, hl);
            if (need_idx < 0) {
                /* orthogonal: exact membership */
                if (hl == nl && memEQ(h, need, nl)) ok = 1;
            }
            else {
                /* ladder: any held role at or above the requirement */
                SSize_t rn = rank ? av_len(rank) + 1
                                  : (SSize_t)(sizeof(DEFAULT_RANK)
                                              / sizeof(*DEFAULT_RANK));
                SSize_t j;
                for (j = need_idx; j < rn; j++) {
                    STRLEN xl; const char *x;
                    if (rank) {
                        SV **e = av_fetch(rank, j, 0);
                        if (!(e && *e && SvOK(*e))) continue;
                        x = SvPV_const(*e, xl);
                    }
                    else { x = DEFAULT_RANK[j]; xl = strlen(x); }
                    if (xl == hl && memEQ(x, h, hl)) { ok = 1; break; }
                }
            }
        }
        if (!ok) {
            SvREFCNT_dec(user);
            return pauth_denial(aTHX_ c, cfg, opts);
        }
        {   /* record what the guard learned */
            HV *stash = ps_stash(aTHX_ pcx_av(aTHX_ c));
            SV **a = hv_fetchs(stash, "auth", 0);
            HV *ah;
            AV *copy = newAV();
            SSize_t k, n2 = av_len(have) + 1;
            for (k = 0; k < n2; k++) {
                SV **e = av_fetch(have, k, 0);
                if (e && *e && SvOK(*e)) av_push(copy, newSVsv(*e));
            }
            if (a && *a && SvROK(*a) && SvTYPE(SvRV(*a)) == SVt_PVHV)
                ah = (HV *)SvRV(*a);
            else {
                ah = newHV();
                (void)hv_stores(stash, "auth", newRV_noinc((SV *)ah));
            }
            (void)hv_stores(ah, "roles", newRV_noinc((SV *)copy));
        }
    }

    {   /* the loaded user rides along for the handler */
        HV *stash = ps_stash(aTHX_ pcx_av(aTHX_ c));
        SV **a = hv_fetchs(stash, "auth", 0);
        HV *ah;
        if (a && *a && SvROK(*a) && SvTYPE(SvRV(*a)) == SVt_PVHV)
            ah = (HV *)SvRV(*a);
        else {
            ah = newHV();
            (void)hv_stores(stash, "auth", newRV_noinc((SV *)ah));
        }
        (void)hv_stores(ah, "user", newSVsv(user));
    }
    SvREFCNT_dec(user);
    return NULL;
}

/* record the signed-in id in the stash's auth slot (the Open::API checker
 * convention: authenticated facts live under stash->{auth}) */
static void pauth_stash_id(pTHX_ SV *c, SV *id) {
    HV *stash = ps_stash(aTHX_ pcx_av(aTHX_ c));
    SV **a = hv_fetchs(stash, "auth", 0);
    HV *ah;
    if (a && *a && SvROK(*a) && SvTYPE(SvRV(*a)) == SVt_PVHV)
        ah = (HV *)SvRV(*a);
    else {
        ah = newHV();
        (void)hv_stores(stash, "auth", newRV_noinc((SV *)ah));
    }
    (void)hv_stores(ah, "user_id", newSVsv(id));
}

/* The guard closure: capture [ $app, \%opts ]. Body: no session id is a
 * denial; a bare guard passes on the id alone; role/verified options load
 * the user through the Perl half. */
XS_INTERNAL(pauth_guard_cb);
XS_INTERNAL(pauth_guard_cb) {
    dXSARGS;
    AV *cap = punk_clos_cap(aTHX_ cv);
    SV *app_sv, *opts_sv, *c, *id;
    HV *cfg = NULL, *opts = NULL;
    if (!cap || items < 1) XSRETURN_EMPTY;
    app_sv  = *av_fetch(cap, 0, 0);
    opts_sv = *av_fetch(cap, 1, 0);
    c = ST(0);

    if (app_sv && SvROK(app_sv) && SvTYPE(SvRV(app_sv)) == SVt_PVHV) {
        SV **s = hv_fetchs((HV *)SvRV(app_sv), K_AUTH, 0);
        if (s && *s && SvROK(*s) && SvTYPE(SvRV(*s)) == SVt_PVHV)
            cfg = (HV *)SvRV(*s);
    }
    if (!cfg)
        croak("Punk: auth_guard needs the auth keyword (add `auth ...`)");
    if (opts_sv && SvROK(opts_sv) && SvTYPE(SvRV(opts_sv)) == SVt_PVHV)
        opts = (HV *)SvRV(opts_sv);

    id = pauth_session_id(aTHX_ c, cfg);
    if (!id) {
        ST(0) = sv_2mortal(pauth_denial(aTHX_ c, cfg, opts));
        XSRETURN(1);
    }
    pauth_stash_id(aTHX_ c, id);
    SvREFCNT_dec(id);

    if (opts && HvUSEDKEYS(opts)) {
        SV *r = pauth_check(aTHX_ c, cfg, opts);
        if (r) { ST(0) = sv_2mortal(r); XSRETURN(1); }
    }
    XSRETURN_EMPTY;
}

#endif /* PUNK_AUTH_H */
