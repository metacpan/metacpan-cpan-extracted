/* punk_ua.h - the shared outbound user agent behind $c->ua.
 *
 * One Fetch agent per worker, not one per request. An agent owns a keep-alive
 * connection pool, its DNS state and (when asked for) a cookie jar; building
 * one per request would throw all of that away and pay a fresh TCP and TLS
 * handshake every time, which is the opposite of the reason to reach for
 * Fetch. So $c->ua is a lazy accessor onto the application's agent, and the
 * context slot only memoises that lookup for the request it belongs to.
 *
 * The pid is stored beside the agent and checked on every fetch, exactly as
 * punk_dbi.h does for a database handle: an agent built before a fork would
 * otherwise have every worker sharing one set of sockets. A worker that finds
 * a foreign pid builds its own.
 *
 * The agent binds to the worker's Hyperman loop when there is one, so an
 * outbound call rides the same loop serving inbound requests and the worker
 * keeps answering while it is in flight. Outside a worker - a test, a script,
 * punk console - Hyperman->loop is undef, Fetch falls back to its own
 * standalone loop and ->get blocks. That is the same degradation $c->timer
 * already documents.
 *
 * Perl headers and punk_context.h (pcx_call_meth) must be in scope.
 */

#ifndef PUNK_UA_H
#define PUNK_UA_H

/* The config the `ua` keyword froze for one agent, or NULL when that name was
 * never declared. An undeclared default is not an error - an app that never
 * says `ua` still gets a default agent - but an undeclared NAME is, and
 * pua_shared turns this into that croak. */
static HV *pua_cfg(pTHX_ SV *app, const char *name, STRLEN nlen) {
    SV **s, **e;
    HV  *uas;
    if (!(app && SvROK(app) && SvTYPE(SvRV(app)) == SVt_PVHV)) return NULL;
    s = hv_fetchs((HV *)SvRV(app), K_UA, 0);
    if (!(s && *s && SvROK(*s) && SvTYPE(SvRV(*s)) == SVt_PVHV)) return NULL;
    uas = (HV *)SvRV(*s);
    e = hv_fetch(uas, name, (I32)nlen, 0);
    return (e && *e && SvROK(*e) && SvTYPE(SvRV(*e)) == SVt_PVHV)
        ? (HV *)SvRV(*e) : NULL;
}

/* Is this key one of Fetch's own constructor options?
 *
 * Needed to read a punk.yml `ua:` block, where a nested mapping is how a
 * second agent is named - except that `headers` is an option whose value is
 * itself a mapping. Deciding on the key rather than the value shape keeps
 * `headers: {...}` an option and anything else nested a name. */
static int pua_is_known_opt(pTHX_ const char *k, STRLEN kl) {
    static const char *opts[] = {
        "headers", "agent", "timeout", "tls_verify", "max_redirects",
        "keep_alive", "pool_size", "cookie_jar", "simple_response", NULL
    };
    int i;
    PERL_UNUSED_CONTEXT;
    for (i = 0; opts[i]; i++)
        if (strlen(opts[i]) == kl && memEQ(k, opts[i], kl)) return 1;
    return 0;
}

/* What cookie_jar was asked for. A jar belongs to the agent, so a jar on the
 * worker-shared agent is shared by every request that worker serves - which is
 * a cross-request leak the moment the cookies identify an end user rather than
 * the application itself. So the setting decides which agent a request gets:
 *
 *   PUA_JAR_NONE    no jar (default): the shared agent, as-is.
 *   PUA_JAR_REQUEST cookie_jar => 1: Fetch->clone(cookie_jar => 1) per
 *                   request. Its own jar, so cookies cannot outlive the
 *                   request that collected them, over the shared connection
 *                   pool and loop - a clone exists precisely so this costs
 *                   neither.
 *   PUA_JAR_SHARED  cookie_jar => 'shared': one jar on the shared agent, for
 *                   an upstream that authenticates THIS APPLICATION and where
 *                   a persistent session cookie is the point. Spelled out in
 *                   full so nobody arrives here by accident.
 */
#define PUA_JAR_NONE    0
#define PUA_JAR_REQUEST 1
#define PUA_JAR_SHARED  2

static int pua_jar_mode(pTHX_ HV *cfg) {
    SV **j = cfg ? hv_fetchs(cfg, "cookie_jar", 0) : NULL;
    if (!(j && *j && SvOK(*j) && SvTRUE(*j))) return PUA_JAR_NONE;
    if (SvPOK(*j)) {
        STRLEN l; const char *p = SvPV_const(*j, l);
        if (l == 6 && memEQ(p, "shared", 6)) return PUA_JAR_SHARED;
    }
    return PUA_JAR_REQUEST;
}

/* The worker's Hyperman::Loop, or NULL outside a worker.
 *
 * Deliberately does not load Hyperman. It is a prerequisite, so it is
 * installed, but that is not the same as loaded - and if it has not been
 * loaded in this process then by definition no worker loop is running here, so
 * there is nothing to bind to and requiring it would only cost a script or a
 * test the load. An unloaded Hyperman and a loaded one sitting outside a
 * worker are the same answer: no loop. */
static SV *pua_loop(pTHX) {
    SV *l;
    if (!gv_stashpvs("Hyperman", 0)) return NULL;
    l = pcx_call_meth(aTHX_ sv_2mortal(newSVpvs("Hyperman")), "loop",
                      NULL, 0, 1);
    if (l && SvOK(l)) return l;
    if (l) SvREFCNT_dec(l);
    return NULL;
}

/* Fetch->new(%cfg, loop => $loop). Returns a +1 agent, or croaks the way any
 * other boot-time misconfiguration does. */
static SV *pua_build(pTHX_ SV *app, const char *name, STRLEN nlen) {
    HV  *cfg;
    SV  *loop;
    SV **argv;
    SV  *agent;
    int  n = 0, cap;
    HE  *e;

    /* Loaded on first use rather than at boot: an application that never
     * reaches for $c->ua should not pay for the agent's dependencies. */
    if (!gv_stashpvs("Fetch", 0)) {
        if (!pk_require_once(aTHX_ "Fetch", FALSE))
            croak("Punk: $c->ua needs Fetch: %s", SvPV_nolen(ERRSV));
    }

    cfg  = pua_cfg(aTHX_ app, name, nlen);
    loop = pua_loop(aTHX);

    cap = (cfg ? (int)HvUSEDKEYS(cfg) * 2 : 0) + 4;
    Newx(argv, cap, SV *);
    if (cfg) {
        int mode = pua_jar_mode(aTHX_ cfg);
        hv_iterinit(cfg);
        while ((e = hv_iternext(cfg))) {
            STRLEN kl;
            const char *k = HePV(e, kl);
            /* cookie_jar never reaches the shared agent verbatim: in
             * per-request mode the jar belongs to the clone, and 'shared' is
             * Punk's spelling, not one Fetch knows. */
            if (kl == 10 && memEQ(k, "cookie_jar", 10)) {
                if (mode == PUA_JAR_SHARED) {
                    argv[n++] = sv_2mortal(newSVpvs("cookie_jar"));
                    argv[n++] = sv_2mortal(newSViv(1));
                }
                continue;
            }
            argv[n++] = sv_2mortal(newSVpvn(k, kl));
            argv[n++] = sv_2mortal(newSVsv(hv_iterval(cfg, e)));
        }
    }
    if (loop) {
        argv[n++] = sv_2mortal(newSVpvs("loop"));
        argv[n++] = sv_2mortal(loop);          /* pua_loop handed us +1 */
    }
    agent = pcx_call_meth(aTHX_ sv_2mortal(newSVpvs("Fetch")), "new",
                          argv, n, 1);
    Safefree(argv);
    if (!(agent && SvROK(agent)))
        croak("Punk: $c->ua could not build a Fetch agent");
    return agent;
}

/* This worker's shared agent for one name, built on first use in it. Borrowed
 * - the app holds the reference. Each name gets its own agent, so two
 * upstreams do not share a pool, a timeout or a set of default headers. */
static SV *pua_shared(pTHX_ SV *app, const char *name, STRLEN nlen) {
    HV  *h, *cache, *box;
    SV **slot, **pid, **a;

    if (!(app && SvROK(app) && SvTYPE(SvRV(app)) == SVt_PVHV))
        croak("Punk: $c->ua needs the compiled application");
    h = (HV *)SvRV(app);

    /* A name that was never declared is a mistake worth naming, unlike the
     * default, which an application is entitled never to configure. */
    if (!(nlen == sizeof(K_DEFAULT) - 1 && memEQ(name, K_DEFAULT, nlen))
        && !pua_cfg(aTHX_ app, name, nlen))
        croak("Punk: $c->ua('%.*s') is not a configured agent; declare it "
              "with `ua %.*s => { ... }`", (int)nlen, name, (int)nlen, name);

    slot = hv_fetchs(h, K_UA_AGENT, 0);
    if (slot && *slot && SvROK(*slot) && SvTYPE(SvRV(*slot)) == SVt_PVHV)
        cache = (HV *)SvRV(*slot);
    else {
        cache = newHV();
        (void)hv_stores(h, K_UA_AGENT, newRV_noinc((SV *)cache));
    }

    slot = hv_fetch(cache, name, (I32)nlen, 0);
    if (slot && *slot && SvROK(*slot) && SvTYPE(SvRV(*slot)) == SVt_PVHV) {
        box = (HV *)SvRV(*slot);
        pid = hv_fetchs(box, "pid", 0);
        if (pid && *pid && SvOK(*pid)
            && SvIV(*pid) == (IV)PerlProc_getpid()) {
            a = hv_fetchs(box, "agent", 0);
            if (a && *a && SvROK(*a)) return *a;
        }
        /* a foreign pid: this worker was forked from whoever built that one,
         * so drop it rather than share its sockets */
    }

    box = newHV();
    (void)hv_stores(box, "agent", pua_build(aTHX_ app, name, nlen));
    (void)hv_stores(box, "pid",   newSViv((IV)PerlProc_getpid()));
    (void)hv_store(cache, name, (I32)nlen, newRV_noinc((SV *)box), 0);
    a = hv_fetchs(box, "agent", 0);
    return (a && *a) ? *a : &PL_sv_undef;
}

/* The agent this request should use, +1 to the caller.
 *
 * With a per-request jar that is a clone of the shared one: its own jar, over
 * the shared connection pool and loop, so isolation costs neither. Otherwise
 * it is the shared agent itself. Either way the context memoises it, so a
 * handler calling $c->ua twice gets one agent and one jar. */
static SV *pua_agent(pTHX_ SV *app, const char *name, STRLEN nlen) {
    SV *shared = pua_shared(aTHX_ app, name, nlen);
    SV *clone;
    SV *argv[2];

    if (pua_jar_mode(aTHX_ pua_cfg(aTHX_ app, name, nlen)) != PUA_JAR_REQUEST)
        return SvREFCNT_inc(shared);

    argv[0] = sv_2mortal(newSVpvs("cookie_jar"));
    argv[1] = sv_2mortal(newSViv(1));
    clone = pcx_call_meth(aTHX_ shared, "clone", argv, 2, 1);
    if (!(clone && SvROK(clone)))
        croak("Punk: $c->ua could not clone the agent for this request "
              "(Fetch 0.11 or later is needed for a per-request cookie jar)");
    return clone;
}

#endif /* PUNK_UA_H */
