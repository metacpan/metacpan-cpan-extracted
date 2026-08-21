/* punk_health.h - /healthz and /readyz, and the distinction between them.
 *
 * Every deployment target asks for a probe endpoint, so every application
 * writes one, and the version it writes is a route that returns 200 without
 * checking anything. That answers "is the process up", which the TCP connect
 * already answered, and it keeps answering 200 while the database is gone.
 *
 * LIVENESS IS NOT READINESS, AND THIS IS THE WHOLE PLUGIN.
 *
 * /healthz (liveness) asks: is this process wedged? It MUST NOT check a
 * dependency. Failing a liveness probe gets the worker KILLED AND RESTARTED,
 * which does not fix the database and removes capacity at the moment of
 * maximum load. A restart loop across every worker, caused by one dependency
 * being slow, is the outage this separation exists to prevent. So the
 * liveness handler here runs no checks at all - not "runs the cheap ones",
 * none - and that is enforced by construction: it does not have the check
 * list.
 *
 * /readyz (readiness) asks: should this worker be sent traffic right now?
 * That is where dependencies belong. Failing it takes the worker out of the
 * pool without killing it, and it goes back in when the dependency returns.
 *
 * WHAT CANNOT BE PROMISED.
 *
 * A budget bounds the checks, and a budget is not a timeout: nothing here can
 * interrupt a check that has already blocked in the driver. Punk runs on a
 * single-threaded event loop, so a check that blocks blocks the worker, and
 * SIGALRM inside a request would be a worse cure than the disease. What the
 * budget does is refuse to START a check once the time is spent, and answer
 * unready. A check that can hang must carry its own driver-level timeout, and
 * the documentation says so rather than implying otherwise.
 *
 * The answer is cached for `ttl` seconds, which is what stops a probe every
 * 100ms becoming load. That cache is per worker and stamped with the pid, so
 * a forked worker never serves the answer its parent computed.
 *
 * Must be included after punk_context.h (pcx_call_meth), punk_app.h (app_hv,
 * app_get), punk_response.h (punk_triplet) and punk_static.h (punk_closure).
 */

#ifndef PUNK_HEALTH_H
#define PUNK_HEALTH_H

#define PH_DEFAULT_TTL     1.0
#define PH_DEFAULT_BUDGET  2.0

/* Append a JSON string literal, escaped. Health output contains check names
 * and error messages, and an error message is whatever a driver said - which
 * is neither trusted nor known to be JSON-safe. */
static void ph_json_str(pTHX_ SV *out, const char *s, STRLEN len) {
    STRLEN i;
    sv_catpvs(out, "\"");
    for (i = 0; i < len; i++) {
        unsigned char ch = (unsigned char)s[i];
        switch (ch) {
            case '"':  sv_catpvs(out, "\\\""); break;
            case '\\': sv_catpvs(out, "\\\\"); break;
            case '\n': sv_catpvs(out, "\\n");  break;
            case '\r': sv_catpvs(out, "\\r");  break;
            case '\t': sv_catpvs(out, "\\t");  break;
            default:
                if (ch < 0x20) sv_catpvf(out, "\\u%04x", (unsigned)ch);
                else           sv_catpvn(out, (const char *)&ch, 1);
        }
    }
    sv_catpvs(out, "\"");
}

/* now(), as a double. */
static double ph_now(pTHX) {
    dSP; double t = 0.0;
    int count;
    ENTER; SAVETMPS; PUSHMARK(SP); PUTBACK;
    count = call_pv("Time::HiRes::time", G_SCALAR | G_EVAL);
    SPAGAIN;
    /* POPPED ONCE, into an SV*, before SvNV touches it. SvNV is a macro that
     * mentions its argument more than once, so SvNV(POPs) pops repeatedly and
     * reads the value off the wrong slot - `PL_valid_types_NVX` on a
     * DEBUGGING perl, silent nonsense everywhere else. */
    if (count > 0) {
        SV *sv = POPs;
        if (!SvTRUE(ERRSV)) t = SvNV(sv);
    }
    PUTBACK; FREETMPS; LEAVE;
    return t;
}

/* Run one check coderef. Returns 1 ready, 0 not, and fills `why` (mortal, may
 * stay NULL) with the reason when it is not.
 *
 * A check that DIES is not ready, and the exception is the reason. A check
 * that returns false is not ready with no reason. Both are ordinary answers
 * rather than errors: a readiness probe exists to be told no. */
static int ph_run_check(pTHX_ SV *cb, SV *c, SV **why) {
    dSP; int ok = 0, count;
    SV *err = NULL;

    ENTER; SAVETMPS;
    PUSHMARK(SP);
    EXTEND(SP, 1);
    PUSHs(c ? c : &PL_sv_undef);
    PUTBACK;
    count = call_sv(cb, G_SCALAR | G_EVAL);
    SPAGAIN;
    if (SvTRUE(ERRSV)) {
        STRLEN el; const char *ep = SvPV_const(ERRSV, el);
        while (el && (ep[el - 1] == '\n' || ep[el - 1] == '\r')) el--;
        err = newSVpvn(ep, el);
        if (count > 0) (void)POPs;
    }
    else if (count > 0) {
        SV *sv = POPs;              /* once - SvTRUE mentions it twice */
        ok = SvTRUE(sv) ? 1 : 0;
    }
    PUTBACK; FREETMPS; LEAVE;

    /* Mortalised OUTSIDE the SAVETMPS above: an SV made mortal inside it is
     * freed by the FREETMPS, and the caller would read a corpse. */
    if (err && why) *why = sv_2mortal(err);
    else if (err)   SvREFCNT_dec(err);
    return ok;
}

/* The readiness answer: 1 ready, 0 not. Appends the per-check JSON detail to
 * `detail` when it is non-NULL. */
static int ph_readiness(pTHX_ SV *app, SV *c, SV *detail) {
    HV *h = app_hv(aTHX_ app);
    SV *checks = h ? app_get(aTHX_ h, "health_checks") : NULL;
    HV *ch = (checks && SvROK(checks) && SvTYPE(SvRV(checks)) == SVt_PVHV)
             ? (HV *)SvRV(checks) : NULL;
    SV *bsv = h ? app_get(aTHX_ h, "health_budget") : NULL;
    double budget = (bsv && SvOK(bsv)) ? SvNV(bsv) : PH_DEFAULT_BUDGET;
    double started = ph_now(aTHX);
    int ready = 1, first = 1;
    HE *ent;

    if (detail) sv_catpvs(detail, "\"checks\":{");
    if (!ch) { if (detail) sv_catpvs(detail, "}"); return 1; }

    /* Sorted, so the document is stable between probes: an operator diffing
     * two answers should see what changed, not what moved. */
    {
        AV *names = (AV *)sv_2mortal((SV *)newAV());
        SSize_t i, n;
        hv_iterinit(ch);
        while ((ent = hv_iternext(ch)))
            av_push(names, newSVsv(hv_iterkeysv(ent)));
        n = av_len(names) + 1;
        sortsv(AvARRAY(names), (SSize_t)n, Perl_sv_cmp);

        for (i = 0; i < n; i++) {
            SV *name = *av_fetch(names, i, 0);
            HE *he = hv_fetch_ent(ch, name, 0, 0);
            SV *cb = he ? HeVAL(he) : NULL;
            SV *why = NULL;
            int ok;
            double t0, spent;
            STRLEN nl; const char *np = SvPV_const(name, nl);

            spent = ph_now(aTHX) - started;
            if (spent >= budget) {
                /* The budget is spent, so the remaining checks are not
                 * STARTED. This cannot rescue a check already blocked in a
                 * driver - see the header - but it stops a probe adding more
                 * of them once it is already late. */
                ready = 0;
                if (detail) {
                    if (!first) sv_catpvs(detail, ",");
                    ph_json_str(aTHX_ detail, np, nl);
                    sv_catpvs(detail, ":{\"ok\":false,\"skipped\":true,"
                                      "\"why\":\"the readiness budget was "
                                      "spent before this check was run\"}");
                    first = 0;
                }
                continue;
            }

            if (!(cb && SvROK(cb) && SvTYPE(SvRV(cb)) == SVt_PVCV)) continue;

            t0 = ph_now(aTHX);
            ok = ph_run_check(aTHX_ cb, c, &why);
            if (!ok) ready = 0;

            if (detail) {
                if (!first) sv_catpvs(detail, ",");
                ph_json_str(aTHX_ detail, np, nl);
                /* NVff and (NV), because sv_catpvf reads the width its
                 * length modifier names and a bare %f names `double` - which
                 * is not perl's NV on a long-double or quadmath build. */
                sv_catpvf(detail, ":{\"ok\":%s,\"ms\":%.2" NVff,
                          ok ? "true" : "false",
                          (NV)((ph_now(aTHX) - t0) * 1000.0));
                if (why && SvOK(why)) {
                    STRLEN wl; const char *wp = SvPV_const(why, wl);
                    sv_catpvs(detail, ",\"why\":");
                    ph_json_str(aTHX_ detail, wp, wl);
                }
                sv_catpvs(detail, "}");
                first = 0;
            }
        }
    }
    if (detail) sv_catpvs(detail, "}");
    return ready;
}

/* The `version` member, when one was configured. */
static void ph_cat_version(pTHX_ HV *h, SV *out) {
    SV *b = h ? app_get(aTHX_ h, "health_version") : NULL;
    if (b && SvOK(b) && SvCUR(b)) {
        STRLEN bl; const char *bp = SvPV_const(b, bl);
        sv_catpvs(out, ",\"version\":");
        ph_json_str(aTHX_ out, bp, bl);
    }
}

/* Whether detail was asked for. */
static int ph_detail(pTHX_ HV *h) {
    SV *d = h ? app_get(aTHX_ h, "health_detail") : NULL;
    return (d && SvTRUE(d)) ? 1 : 0;
}

/* The response, ready-made. */
static SV *ph_reply(pTHX_ IV status, SV *body) {
    AV *extra = (AV *)sv_2mortal((SV *)newAV());
    /* A probe answer is never worth caching, anywhere, by anyone: a cached
     * 200 is a health check that reports the past. */
    av_push(extra, newSVpvs("Cache-Control"));
    av_push(extra, newSVpvs("no-store"));
    return punk_triplet(aTHX_ status, sv_2mortal(newSVpvs("application/json")),
                        body, extra);
}

/* ---- /healthz ---------------------------------------------------------------
 *
 * Deliberately has no access to the check list. Liveness that consults a
 * dependency is the bug this plugin exists to stop, and the way to not write
 * it is to not have the thing available. */
XS_INTERNAL(ph_live_cb);
XS_INTERNAL(ph_live_cb) {
    dXSARGS;
    AV *cap = punk_clos_cap(aTHX_ cv);
    SV *app = cap ? *av_fetch(cap, 0, 0) : NULL;
    HV *h = app ? app_hv(aTHX_ app) : NULL;
    SV *body = sv_2mortal(newSVpvs("{\"status\":\"ok\""));
    PERL_UNUSED_VAR(items);

    if (ph_detail(aTHX_ h)) ph_cat_version(aTHX_ h, body);
    sv_catpvs(body, "}");

    ST(0) = sv_2mortal(ph_reply(aTHX_ 200, newSVsv(body)));
    XSRETURN(1);
}

/* ---- /readyz --------------------------------------------------------------- */
XS_INTERNAL(ph_ready_cb);
XS_INTERNAL(ph_ready_cb) {
    dXSARGS;
    AV *cap = punk_clos_cap(aTHX_ cv);
    SV *app = cap ? *av_fetch(cap, 0, 0) : NULL;
    SV *c   = items > 0 ? ST(0) : NULL;
    HV *h   = app ? app_hv(aTHX_ app) : NULL;
    SV *tsv = h ? app_get(aTHX_ h, "health_ttl") : NULL;
    double ttl = (tsv && SvOK(tsv)) ? SvNV(tsv) : PH_DEFAULT_TTL;
    SV *cached = h ? app_get(aTHX_ h, "health_cached") : NULL;
    AV *slot = (cached && SvROK(cached) && SvTYPE(SvRV(cached)) == SVt_PVAV)
               ? (AV *)SvRV(cached) : NULL;
    double now = ph_now(aTHX);
    int detail = ph_detail(aTHX_ h);
    SV *body;
    int ready;

    /* A cached answer, if it is still fresh AND this worker computed it. The
     * pid stamp is what stops a forked worker serving its parent's verdict:
     * cheap, and the alternative is a whole pool agreeing about a dependency
     * only one of them ever contacted. */
    if (slot && ttl > 0) {
        SV **exp = av_fetch(slot, 0, 0);
        SV **pid = av_fetch(slot, 1, 0);
        SV **st  = av_fetch(slot, 2, 0);
        SV **bd  = av_fetch(slot, 3, 0);
        if (exp && *exp && pid && *pid && st && *st && bd && *bd
            && SvNV(*exp) > now && SvIV(*pid) == (IV)PerlProc_getpid()) {
            ST(0) = sv_2mortal(ph_reply(aTHX_ SvIV(*st), newSVsv(*bd)));
            XSRETURN(1);
        }
    }

    body = sv_2mortal(newSVpvs(""));
    {
        SV *det = detail ? sv_2mortal(newSVpvs("")) : NULL;
        ready = ph_readiness(aTHX_ app, c, det);
        sv_catpvf(body, "{\"status\":\"%s\"", ready ? "ok" : "unready");
        if (detail) {
            ph_cat_version(aTHX_ h, body);
            sv_catpvs(body, ",");
            sv_catsv(body, det);
        }
        sv_catpvs(body, "}");
    }

    /* 503, not 500: unready is an ordinary answer that a load balancer knows
     * how to act on, and it means "not me, right now" rather than "something
     * broke". */
    {
        IV status = ready ? 200 : 503;
        if (h && ttl > 0) {
            AV *fresh = newAV();
            av_push(fresh, newSVnv(now + ttl));
            av_push(fresh, newSViv((IV)PerlProc_getpid()));
            av_push(fresh, newSViv(status));
            av_push(fresh, newSVsv(body));
            (void)hv_stores(h, "health_cached", newRV_noinc((SV *)fresh));
        }
        ST(0) = sv_2mortal(ph_reply(aTHX_ status, newSVsv(body)));
    }
    XSRETURN(1);
}

#endif /* PUNK_HEALTH_H */
