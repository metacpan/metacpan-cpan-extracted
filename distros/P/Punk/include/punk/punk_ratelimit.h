#ifndef PUNK_RATELIMIT_H
#define PUNK_RATELIMIT_H

/* The rate_limit policy, in C. `rate_limit` (a Punk::App method, forwarded
 * from the keyword) captures a rule's config into a magic-CV closure and
 * pushes it onto the before_dispatch chain; the closure body, prl_check_cb,
 * runs on every matching request with no Perl frame of its own - it reads the
 * env, builds the key, calls Hyperman's shared arena through the ABI
 * (punk_hm), and either short-circuits with a 429 or returns nothing.
 *
 * Requires punk_context.h (pcx_av / PCX_ENV), punk_app.h (app_hash / hooks),
 * punk_static.h (punk_closure / punk_clos_cap) and punk_wsconn.h (punk_hm) -
 * all included before this file in Punk.xs.
 *
 * Fails open: with no Hyperman >= ABI v3 under the app, ratelimit_hit is
 * absent and every request is allowed. */

#include <ctype.h>
#include <time.h>
#include <string.h>

/* Capture slots for a rule (an AV owned by the closure). */
#define PRL_LIMIT   0    /* IV: requests per window (<= 0 unlimited)   */
#define PRL_WINDOW  1    /* IV: window seconds                          */
#define PRL_BY      2    /* IV: 0 ip, 1 header, 2 coderef               */
#define PRL_ENVKEY  3    /* PV: env key for header mode (e.g. HTTP_...) */
#define PRL_FOR     4    /* PV: path prefix, or "" for all              */
#define PRL_TAG     5    /* PV: counter namespace                       */
#define PRL_BYFN    6    /* SV: the coderef for by-mode 2, else undef   */

/* the most of a header or coderef id that becomes part of the counter key */
#define PRL_ID_MAX  256

/* The before_dispatch body for one rule. ST(0) is $c; a reference return
 * short-circuits the request (punk_dispatch.h), so a 429 answers here. */
XS_INTERNAL(prl_check_cb);
XS_INTERNAL(prl_check_cb) {
    dXSARGS;
    AV *cap = punk_clos_cap(aTHX_ cv);
    SV *c;
    IV  limit, window, by;
    STRLEN elen, flen, tlen, idlen = 0;
    const char *envkey, *forp, *tag, *id = NULL;
    SV *idsv = NULL, *keysv;
    AV *cav;
    SV **e;
    HV *env;
    const hm_abi *A;
    IV rem = 0, reset = 0;
    int ok;

    if (!cap || items < 1) XSRETURN_EMPTY;
    c = ST(0);

    limit  = SvIV(*av_fetch(cap, PRL_LIMIT,  0));
    window = SvIV(*av_fetch(cap, PRL_WINDOW, 0));
    by     = SvIV(*av_fetch(cap, PRL_BY,     0));
    envkey = SvPV(*av_fetch(cap, PRL_ENVKEY, 0), elen);
    forp   = SvPV(*av_fetch(cap, PRL_FOR,    0), flen);
    tag    = SvPV(*av_fetch(cap, PRL_TAG,    0), tlen);

    cav = pcx_av(aTHX_ c);
    e   = cav ? av_fetch(cav, PCX_ENV, 0) : NULL;
    if (!(e && *e && SvROK(*e) && SvTYPE(SvRV(*e)) == SVt_PVHV)) XSRETURN_EMPTY;
    env = (HV *)SvRV(*e);

    /* `for` prefix: only paths under it are limited by this rule */
    if (flen) {
        SV **p = hv_fetchs(env, "PATH_INFO", 0);
        STRLEN plen = 0;
        const char *path = (p && *p && SvOK(*p)) ? SvPV(*p, plen) : "";
        if (plen < flen || memcmp(path, forp, flen) != 0) XSRETURN_EMPTY;
    }

    /* the caller's identity for this rule */
    if (by == 2) {                                  /* coderef */
        SV **fp = av_fetch(cap, PRL_BYFN, 0);
        int count;
        ENTER; SAVETMPS;
        PUSHMARK(SP);
        XPUSHs(c);
        PUTBACK;
        count = call_sv(fp && *fp ? *fp : &PL_sv_undef, G_SCALAR);
        SPAGAIN;
        idsv = count > 0 ? newSVsv(POPs) : NULL;
        PUTBACK; FREETMPS; LEAVE;
        if (!idsv || !SvOK(idsv)) { SvREFCNT_dec(idsv); XSRETURN_EMPTY; }
        id = SvPV(idsv, idlen);
    } else {                                        /* ip (0) or header (1) */
        SV **ev = (by == 1) ? hv_fetch(env, envkey, (I32)elen, 0)
                            : hv_fetchs(env, "REMOTE_ADDR", 0);
        /* A header rule with no header falls back to the address: a client
         * that simply omits the header is still one client, and a rule that
         * limited nothing for it was no limit at all. */
        if (by == 1 && !(ev && *ev && SvOK(*ev) && SvCUR(*ev)))
            ev = hv_fetchs(env, "REMOTE_ADDR", 0);
        if (!(ev && *ev && SvOK(*ev))) XSRETURN_EMPTY;
        id = SvPV(*ev, idlen);
    }
    if (!idlen) { SvREFCNT_dec(idsv); XSRETURN_EMPTY; }
    /* an id is a key in a shared table, not a place to put a header's worth
     * of bytes per request */
    if (idlen > PRL_ID_MAX) idlen = PRL_ID_MAX;

    /* key = "rl\0" tag "\0" id - NUL-joined so rules and ids never collide */
    keysv = sv_2mortal(newSVpvs("rl"));
    sv_catpvn(keysv, "\0", 1);
    sv_catpvn(keysv, tag, tlen);
    sv_catpvn(keysv, "\0", 1);
    sv_catpvn(keysv, id, idlen);
    SvREFCNT_dec(idsv);

    /* resolved: punk_hm's environment check is a scan of every variable,
     * per request, and the answer cannot change once the table is found */
    A = punk_hm_resolved(aTHX);
    if (!(A && A->ratelimit_hit)) XSRETURN_EMPTY;    /* fail open */
    {
        STRLEN klen;
        const char *kp = SvPV(keysv, klen);
        ok = A->ratelimit_hit(kp, klen, limit, window, &rem, &reset);
    }
    if (ok) XSRETURN_EMPTY;                          /* within the limit */

    /* over: answer 429 with Retry-After and the X-RateLimit-* headers */
    {
        long now   = (long)time(NULL);
        long retry = (long)reset - now;
        AV *hdr  = newAV();
        AV *body = newAV();
        AV *resp = newAV();
        if (retry < 0) retry = 0;
        av_push(hdr, newSVpvs("Content-Type"));
        av_push(hdr, newSVpvs("application/problem+json"));
        av_push(hdr, newSVpvs("Retry-After"));
        av_push(hdr, newSViv(retry));
        av_push(hdr, newSVpvs("X-RateLimit-Limit"));
        av_push(hdr, newSViv(limit));
        av_push(hdr, newSVpvs("X-RateLimit-Remaining"));
        av_push(hdr, newSViv(0));
        av_push(hdr, newSVpvs("X-RateLimit-Reset"));
        av_push(hdr, newSViv(reset));
        av_push(body, newSVpvs(
            "{\"type\":\"about:blank\",\"title\":\"Too Many Requests\","
            "\"status\":429,\"detail\":\"rate limit exceeded\"}"));
        av_push(resp, newSViv(429));
        av_push(resp, newRV_noinc((SV *)hdr));
        av_push(resp, newRV_noinc((SV *)body));
        ST(0) = sv_2mortal(newRV_noinc((SV *)resp));
        XSRETURN(1);
    }
}

/* Build the capture and push a rule's closure onto the app's before_dispatch
 * chain. Called once, from the rate_limit XSUB. */
static void prl_install(pTHX_ SV *self, IV limit, IV window, IV by,
                        const char *envkey, STRLEN elen,
                        const char *forp, STRLEN flen,
                        const char *tag, STRLEN tlen, SV *byfn) {
    AV *cap = newAV();
    SV *closure;
    HV *hooks;
    SV **slot;

    av_extend(cap, PRL_BYFN);
    (void)av_store(cap, PRL_LIMIT,  newSViv(limit));
    (void)av_store(cap, PRL_WINDOW, newSViv(window));
    (void)av_store(cap, PRL_BY,     newSViv(by));
    (void)av_store(cap, PRL_ENVKEY, newSVpvn(envkey ? envkey : "", envkey ? elen : 0));
    (void)av_store(cap, PRL_FOR,    newSVpvn(forp ? forp : "", forp ? flen : 0));
    (void)av_store(cap, PRL_TAG,    newSVpvn(tag ? tag : "", tag ? tlen : 0));
    (void)av_store(cap, PRL_BYFN,   (by == 2 && byfn) ? newSVsv(byfn) : newSV(0));

    closure = punk_closure(aTHX_ prl_check_cb, cap);   /* takes cap; +1 coderef */
    hooks   = app_hash(aTHX_ app_hv(aTHX_ self), K_HOOKS);
    slot    = hv_fetchs(hooks, K_BEFORE_D, 0);
    if (slot && *slot && SvROK(*slot) && SvTYPE(SvRV(*slot)) == SVt_PVAV)
        av_push((AV *)SvRV(*slot), closure);           /* AV owns it now */
    else
        SvREFCNT_dec(closure);
}

/* "header:X-Api-Key" -> the env key it arrives under, as a mortal SV. */
static SV *prl_header_envkey(pTHX_ const char *bs, STRLEN bl) {
    SV *k = sv_2mortal(newSVpvs("HTTP_"));
    STRLEN j;
    for (j = 7; j < bl; j++) {
        char ch = bs[j];
        ch = (ch == '-') ? '_' : (char)toupper((unsigned char)ch);
        sv_catpvn(k, &ch, 1);
    }
    return k;
}

/* ---- boot: compile the route-level rate_limit options --------------------- */

/* The `rate_limit` route option, compiled the way `validate` is: one guard
 * closure appended to the record, running the same prl_check_cb the keyword
 * installs on before_dispatch. A route that declares nothing is untouched and
 * the whole pass costs nothing.
 *
 * The counter namespace defaults to this route's own method and path, so two
 * routes with the same budget do not spend each other's. Naming a `tag`
 * shares one deliberately, which is how three routes get one budget between
 * them:
 *
 *     my %auth = ( limit => 5, window => 60, tag => 'auth' );
 *     post '/login'    => $t, { rate_limit => \%auth };
 *     post '/register' => $t, { rate_limit => \%auth };
 *     post '/forgot'   => $t, { rate_limit => \%auth };
 */
static void prl_compile_routes(pTHX_ SV *self) {
    HV *h = (HV *)SvRV(self);
    SV **rlp = hv_fetchs(h, K_RL_ROUTES, 0);
    AV *rls;
    HV *by;
    SSize_t i, n;

    if (!(rlp && *rlp && SvROK(*rlp) && SvTYPE(SvRV(*rlp)) == SVt_PVAV))
        return;
    rls = (AV *)SvRV(*rlp);
    n = av_len(rls) + 1;
    if (!n) return;
    by = pk_route_index(aTHX_ self, "rate_limit");

    for (i = 0; i < n; i++) {
        SV **rp = av_fetch(rls, i, 0);
        HV *rr, *rec, *spec;
        SV **m, **p, **sp, **x;
        SV *where;
        HE *he;
        IV limit = 60, window = 60, by_mode = 0;
        SV *byfn = NULL, *envkeysv = NULL, *tagsv;
        const char *envkey = "";
        STRLEN elen = 0;
        AV *cap;

        if (!(rp && *rp && SvROK(*rp) && SvTYPE(SvRV(*rp)) == SVt_PVHV))
            continue;
        rr = (HV *)SvRV(*rp);
        m  = hv_fetchs(rr, K_METHOD, 0);
        p  = hv_fetchs(rr, K_PATH, 0);
        sp = hv_fetchs(rr, K_RATE_LIMIT, 0);
        if (!(m && *m && p && *p && sp && *sp
              && SvROK(*sp) && SvTYPE(SvRV(*sp)) == SVt_PVHV))
            continue;
        spec = (HV *)SvRV(*sp);

        where = sv_2mortal(newSVsv(*m));
        sv_catpvs(where, " ");
        sv_catsv(where, *p);
        he = hv_fetch_ent(by, where, 0, 0);
        if (!he)
            croak("Punk: rate_limit on unknown route %s", SvPV_nolen(where));
        rec = (HV *)SvRV(HeVAL(he));

        x = hv_fetchs(spec, "limit", 0);
        if (x && *x) {
            if (!SvOK(*x) || !looks_like_number(*x))
                croak("Punk: rate_limit limit on %s is a count of requests",
                      SvPV_nolen(where));
            limit = SvIV(*x);
        }
        x = hv_fetchs(spec, "window", 0);
        if (x && *x) {
            if (!SvOK(*x) || !looks_like_number(*x) || SvIV(*x) <= 0)
                croak("Punk: rate_limit window on %s is a positive number "
                      "of seconds", SvPV_nolen(where));
            window = SvIV(*x);
        }
        x = hv_fetchs(spec, "by", 0);
        if (x && *x && SvOK(*x)) {
            if (SvROK(*x) && SvTYPE(SvRV(*x)) == SVt_PVCV) {
                by_mode = 2; byfn = *x;
            }
            else if (SvROK(*x))
                croak("Punk: rate_limit by on %s is 'ip', 'header:NAME' or "
                      "a coderef", SvPV_nolen(where));
            else {
                STRLEN bl;
                const char *bs = SvPV(*x, bl);
                if (bl > 7 && strnEQ(bs, "header:", 7)) {
                    by_mode = 1;
                    envkeysv = prl_header_envkey(aTHX_ bs, bl);
                    envkey = SvPV(envkeysv, elen);
                }
                else if (!(bl == 2 && memEQ(bs, "ip", 2)))
                    croak("Punk: rate_limit by on %s is 'ip', 'header:NAME' "
                          "or a coderef, not '%.*s'", SvPV_nolen(where),
                          (int)bl, bs);
            }
        }
        x = hv_fetchs(spec, "tag", 0);
        if (x && *x && SvOK(*x) && SvCUR(*x)) {
            tagsv = sv_2mortal(newSVsv(*x));
        }
        else {
            /* this route's own namespace, so one route's retries are not
             * charged to another with the same limit */
            tagsv = sv_2mortal(newSVpvs("route "));
            sv_catsv(tagsv, where);
        }

        cap = newAV();
        av_extend(cap, PRL_BYFN);
        (void)av_store(cap, PRL_LIMIT,  newSViv(limit));
        (void)av_store(cap, PRL_WINDOW, newSViv(window));
        (void)av_store(cap, PRL_BY,     newSViv(by_mode));
        (void)av_store(cap, PRL_ENVKEY, newSVpvn(envkey, elen));
        (void)av_store(cap, PRL_FOR,    newSVpvs(""));   /* the route is it */
        (void)av_store(cap, PRL_TAG,    newSVsv(tagsv));
        (void)av_store(cap, PRL_BYFN,
                       (by_mode == 2 && byfn) ? newSVsv(byfn) : newSV(0));
        pk_route_guard_push(aTHX_ rec,
                            punk_closure(aTHX_ prl_check_cb, cap));
    }
}

#endif /* PUNK_RATELIMIT_H */
