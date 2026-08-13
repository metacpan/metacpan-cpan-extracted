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
        if (!(ev && *ev && SvOK(*ev))) XSRETURN_EMPTY;
        id = SvPV(*ev, idlen);
    }
    if (!idlen) { SvREFCNT_dec(idsv); XSRETURN_EMPTY; }

    /* key = "rl\0" tag "\0" id - NUL-joined so rules and ids never collide */
    keysv = sv_2mortal(newSVpvs("rl"));
    sv_catpvn(keysv, "\0", 1);
    sv_catpvn(keysv, tag, tlen);
    sv_catpvn(keysv, "\0", 1);
    sv_catpvn(keysv, id, idlen);
    SvREFCNT_dec(idsv);

    A = punk_hm(aTHX);
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

#endif /* PUNK_RATELIMIT_H */
