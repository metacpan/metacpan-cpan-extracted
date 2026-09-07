#ifndef PCHAL_RULES_H
#define PCHAL_RULES_H

/* The `challenge` keyword, and the hook that enforces what it recorded.
 *
 *     challenge for    => '/api',                        # path prefix; default '/'
 *               always => 1,                             # every request without a clearance
 *               after  => { limit => 60, window => 60 }, # or: past this rate
 *               bits   => 18,                            # this rule's difficulty
 *               tag    => 'api';                         # counter namespace for `after`
 *
 * Recorded on the application as `challenge_rules`, an AV of hashes in
 * declaration order, each with every key present:
 *
 *     for      the prefix, rooted, no trailing slash
 *     always   1 or 0
 *     limit    IV, or undef under `always`
 *     window   IV, or undef under `always`
 *     bits     IV, or undef for "the plugin's default when the rule runs"
 *     tag      the counter namespace; defaults to `for`
 *
 * `bits` is left undef rather than resolved here because the rule may be
 * declared above the `plugin` line that sets the default, and a rule that
 * froze 16 because it ran first would ignore a `bits => 18` that followed.
 * The hook resolves it at the request.
 *
 * ONE before_dispatch hook for all rules, which walks them in declaration
 * order and stops at the first that applies to the path. The plugin's own
 * routes and every `exempt` prefix are skipped first. Static mounts never
 * reach before_dispatch at all, which is what you want: nobody should solve
 * a puzzle to fetch a stylesheet.
 *
 * For a request under a rule: a valid clearance at or above the rule's
 * bits continues; `always` answers with the challenge; `after` counts it
 * through $c->rate_hit("challenge:$tag:$subject", $limit, $window) - within
 * the limit continues, past it answers with the challenge. That third step
 * is the whole reason for the plugin: a rate limit that degrades to a cost
 * rather than a refusal.
 *
 * rate_hit is reached as a METHOD, not through a C table, so a test can
 * stand in its own counter after the application has compiled.
 *
 * Must be included after pchal_answer.h.
 */

static const char *const PCHAL_RULE_OPTS[] = {
    "for", "always", "after", "bits", "tag", NULL
};

/* pchal_routes.h's, run from the compile callback below: the verify route
 * onto csrf's exempt list. Declared here because the routes come after the
 * rules in the include order. */
static void pchal_csrf_exempt(pTHX_ SV *app, HV *opts);

static const char *const PCHAL_AFTER_OPTS[] = { "limit", "window", NULL };

/* ---- the keyword ------------------------------------------------------------ */

XS_INTERNAL(pchal_kw_challenge_cb);
XS_INTERNAL(pchal_kw_challenge_cb)
{
    dXSARGS;
    SV *app = pchal_cap_slot(aTHX_ cv, 0);
    HV *h = app ? pchal_app_hv(aTHX_ app) : NULL;
    HV *in, *rule;
    SV *v, *keep;
    int always = 0, has_after = 0;
    IV limit = 0, window = 0;

    if (!h) XSRETURN_EMPTY;
    if (items == 0)
        croak("%s: challenge needs `always => 1` or `after => { limit => N, "
              "window => S }`", PCHAL_WHO);

    in = pchal_args(aTHX_ "challenge", &ST(0), items);
    pchal_check_opts(aTHX_ "challenge option", in, PCHAL_RULE_OPTS);

    rule = newHV();
    (void)sv_2mortal(newRV_noinc((SV *)rule));

    {   /* for: the prefix this rule applies under */
        SV *f = pchal_opt_str(aTHX_ in, "for");
        STRLEN fl;
        const char *fp;
        keep = f ? newSVsv(f) : newSVpvs("/");
        (void)hv_stores(rule, "for", keep);
        fp = SvPV_const(keep, fl);
        while (fl > 1 && fp[fl - 1] == '/') { SvCUR_set(keep, --fl); }
        fp = SvPV_const(keep, fl);
        if (!pchal_path_ok(fp, fl))
            croak("%s: challenge `for` must be a rooted path, not '%" SVf "'",
                  PCHAL_WHO, SVfARG(keep));
    }

    v = pchal_hget(aTHX_ in, "always");
    always = (v && SvTRUE(v)) ? 1 : 0;

    v = pchal_hget(aTHX_ in, "after");
    if (v) {
        HV *after;
        if (!pchal_is_hash(v))
            croak("%s: challenge `after` must be { limit => N, window => S }",
                  PCHAL_WHO);
        after = (HV *)SvRV(v);
        pchal_check_opts(aTHX_ "after option", after, PCHAL_AFTER_OPTS);
        if (!pchal_hget(aTHX_ after, "limit"))
            croak("%s: challenge `after` needs `limit`", PCHAL_WHO);
        if (!pchal_hget(aTHX_ after, "window"))
            croak("%s: challenge `after` needs `window`", PCHAL_WHO);
        limit  = pchal_opt_iv(aTHX_ after, "limit",  0, 1, IV_MAX);
        window = pchal_opt_iv(aTHX_ after, "window", 0, 1, IV_MAX);
        has_after = 1;
    }

    /* One or the other. Both is two answers for one request; neither is a
     * rule that does nothing, which is a mistake and not a default. */
    if (always && has_after)
        croak("%s: a challenge rule has `always` or `after`, not both",
              PCHAL_WHO);
    if (!always && !has_after)
        croak("%s: a challenge rule needs `always => 1` or `after => { limit "
              "=> N, window => S }`", PCHAL_WHO);

    (void)hv_stores(rule, "always", newSViv(always));
    (void)hv_stores(rule, "limit",  has_after ? newSViv(limit)  : newSV(0));
    (void)hv_stores(rule, "window", has_after ? newSViv(window) : newSV(0));

    (void)hv_stores(rule, "bits",
                    pchal_opt_str(aTHX_ in, "bits")
                    ? newSViv(pchal_opt_iv(aTHX_ in, "bits", 0, 1, PCHAL_MAX_BITS))
                    : newSV(0));

    {   /* tag: the counter namespace for `after`; the prefix when unsaid */
        SV *t = pchal_opt_str(aTHX_ in, "tag");
        STRLEN tl, i;
        const char *tp;
        keep = t ? newSVsv(t) : newSVsv(pchal_hget(aTHX_ rule, "for"));
        (void)hv_stores(rule, "tag", keep);
        tp = SvPV_const(keep, tl);
        if (!tl)
            croak("%s: challenge `tag` must not be empty", PCHAL_WHO);
        for (i = 0; i < tl; i++) {
            unsigned char ch = (unsigned char)tp[i];
            if (ch <= 0x20 || ch == 0x7f || ch == ':')
                croak("%s: challenge `tag` must be a plain word, not '%" SVf "'",
                      PCHAL_WHO, SVfARG(keep));
        }
    }

    av_push(pchal_app_av(aTHX_ h, "challenge_rules"),
            newRV_inc((SV *)rule));
    XSRETURN_EMPTY;
}

/* ---- the hook ----------------------------------------------------------------- */

/* Is `path` at or under `prefix`? "/" is under everything; otherwise the
 * prefix itself or the prefix followed by a slash, so "/api" does not
 * cover "/apiary". */
static int pchal_under(const char *path, STRLEN pl, const char *prefix,
                       STRLEN xl)
{
    if (xl == 1 && prefix[0] == '/') return 1;
    if (pl < xl || !memEQ(path, prefix, xl)) return 0;
    return pl == xl || path[xl] == '/';
}

static int pchal_under_sv(pTHX_ const char *path, STRLEN pl, SV *prefix)
{
    STRLEN xl;
    const char *xp;
    if (!(prefix && SvOK(prefix))) return 0;
    xp = SvPV_const(prefix, xl);
    return pchal_under(path, pl, xp, xl);
}

/* ---- is there an arena to count in? --------------------------------------------
 *
 * Two checks, because the arena exists at two different times. Hyperman
 * maps it inside run(), after a `plackup`-loaded application has already
 * compiled, so nothing asked at to_app can see it; and a server that is
 * not Hyperman never maps one at all while Hyperman may still be installed
 * and loadable. So: at compile, warn when Hyperman's table cannot be found
 * (below); at the first request under an `after` rule, probe the arena
 * itself and warn once when it is not there.
 *
 * The probe: the counter answers "allowed, limit minus one" both on a
 * first hit and with no arena at all, so one call cannot tell them apart -
 * but a second hit on the same key under a limit of one is refused only
 * when something counted the first. The key is this process's own, and
 * the answer is kept per pid, so a forked worker probes its own arena. */
static int pchal_inert_warned = 0;
static UV  pchal_probe_pid = 0;
static int pchal_probe_live = 0;

static int pchal_arena_live(pTHX)
{
    UV me = (UV)PerlProc_getpid();
    if (getenv("PUNK_NO_HM_ABI")) return 0;
    if (pchal_probe_pid == me) return pchal_probe_live;
    pchal_probe_pid = me;
    pchal_probe_live = 0;
    {
        SV *hm = sv_2mortal(newSVpvs("Hyperman"));
        SV *argv[3], *r;
        int i, allowed = 1;
        if (!pchal_can(aTHX_ hm, "ratelimit_hit")) return 0;
        argv[0] = sv_2mortal(newSVpvf("punk-challenge:probe:%" UVuf, me));
        argv[1] = sv_2mortal(newSViv(1));
        argv[2] = sv_2mortal(newSViv(60));
        for (i = 0; i < 2; i++) {
            r = sv_2mortal(pchal_call_first(aTHX_ hm, "ratelimit_hit", argv, 3));
            allowed = (r && SvTRUE(r)) ? 1 : 0;
        }
        pchal_probe_live = allowed ? 0 : 1;
    }
    return pchal_probe_live;
}

static void pchal_warn_inert(pTHX_ SV *names, const char *when)
{
    pchal_inert_warned = 1;
    warn("%s: the `after` rule for %" SVf " is inert: there is no shared "
         "arena to count in (%s), so it never fires. Serve under Hyperman - "
         "`plackup -s Hyperman` - for `after`; an `always` rule works on any "
         "PSGI server.\n", PCHAL_WHO, SVfARG(names), when);
}

XS_INTERNAL(pchal_hook_cb);
XS_INTERNAL(pchal_hook_cb)
{
    dXSARGS;
    SV *app = pchal_cap_slot(aTHX_ cv, 0);
    HV *h = app ? pchal_app_hv(aTHX_ app) : NULL;
    SV *c = items > 0 ? ST(0) : NULL;
    SV *rulesv = h ? pchal_hget(aTHX_ h, "challenge_rules") : NULL;
    SV *pi, *ex;
    AV *rules;
    HV *opts;
    STRLEN pl = 1;
    const char *path = "/";
    SSize_t i, n;

    if (!c || !pchal_is_array(rulesv)) XSRETURN_EMPTY;
    rules = (AV *)SvRV(rulesv);
    n = av_len(rules) + 1;
    if (!n) XSRETURN_EMPTY;
    opts = pchal_opts_of(aTHX_ app);

    pi = pchal_env(aTHX_ c, "PATH_INFO");
    if (pi) path = SvPV_const(pi, pl);
    if (!pl) { path = "/"; pl = 1; }

    /* the plugin's own routes, then every exempt prefix */
    if (pchal_under_sv(aTHX_ path, pl, pchal_hget(aTHX_ opts, "prefix")))
        XSRETURN_EMPTY;
    ex = pchal_hget(aTHX_ opts, "exempt");
    if (pchal_is_array(ex)) {
        AV *list = (AV *)SvRV(ex);
        SSize_t j, m = av_len(list) + 1;
        for (j = 0; j < m; j++) {
            SV **e = av_fetch(list, j, 0);
            if (e && *e && pchal_under_sv(aTHX_ path, pl, *e)) XSRETURN_EMPTY;
        }
    }

    for (i = 0; i < n; i++) {
        SV **e = av_fetch(rules, i, 0);
        HV *rule;
        SV *v;
        IV bits;
        if (!(e && *e && pchal_is_hash(*e))) continue;
        rule = (HV *)SvRV(*e);
        if (!pchal_under_sv(aTHX_ path, pl, pchal_hget(aTHX_ rule, "for")))
            continue;

        /* the first rule that applies decides; nothing below it is consulted */
        bits = pchal_bits_for(aTHX_ opts, pchal_hget(aTHX_ rule, "bits"));
        if (pchal_cleared(aTHX_ c, opts, bits)) XSRETURN_EMPTY;

        v = pchal_hget(aTHX_ rule, "always");
        if (!(v && SvTRUE(v))) {
            /* after: count it, and only past the limit demand */
            SV *subject = sv_2mortal(pchal_subject_of(aTHX_ c, opts));
            SV *key = sv_2mortal(newSVpvs("challenge:"));
            SV *argv[3], *ok;
            if (!pchal_inert_warned && !pchal_arena_live(aTHX)) {
                SV *names = sv_2mortal(newSVpvs("'"));
                sv_catsv(names, pchal_hget(aTHX_ rule, "for"));
                sv_catpvs(names, "'");
                pchal_warn_inert(aTHX_ names,
                                 "this server is not Hyperman, or its arena "
                                 "is not mapped");
            }
            sv_catsv(key, pchal_hget(aTHX_ rule, "tag"));
            sv_catpvs(key, ":");
            sv_catsv(key, subject);
            argv[0] = key;
            argv[1] = pchal_hget(aTHX_ rule, "limit");
            argv[2] = pchal_hget(aTHX_ rule, "window");
            ok = sv_2mortal(pchal_call_first(aTHX_ c, "rate_hit", argv, 3));
            if (ok && SvTRUE(ok)) XSRETURN_EMPTY;
        }

        ST(0) = sv_2mortal(pchal_demand(aTHX_ c, opts, bits));
        XSRETURN(1);
    }
    XSRETURN_EMPTY;
}

/* ---- the boot warning ------------------------------------------------------------ */

/* Can rate_hit reach Hyperman at all? Resolved exactly as Punk resolves it
 * - Hyperman's own table through Hyperman::_abi_ptr - and read without
 * hm_abi.h: the family's ABI rule puts `int abi_version` first in every
 * table, and that one int is all this needs. Version 3 is where the arena
 * arrived. PUNK_NO_HM_ABI, Punk's own switch for tests, forces "none" here
 * too, so what this warns about is what rate_hit will do.
 *
 * A table is not an arena: the arena is mapped inside Hyperman's run(),
 * later than this. What this settles at compile is the case with no
 * Hyperman to load; pchal_arena_live settles the rest at the first
 * request. */
static int pchal_arena_present(pTHX)
{
    static int tried = 0, present = 0;
    if (getenv("PUNK_NO_HM_ABI")) return 0;
    if (!tried) {
        dSP;
        int count;
        IV p = 0;
        tried = 1;
        ENTER; SAVETMPS;
        eval_pv("require Hyperman; 1", FALSE);
        SPAGAIN;
        if (!SvTRUE(ERRSV)) {
            PUSHMARK(SP); PUTBACK;
            count = call_pv("Hyperman::_abi_ptr", G_SCALAR | G_EVAL);
            SPAGAIN;
            if (!SvTRUE(ERRSV) && count > 0) p = POPi;
            else if (count > 0) (void)POPs;
            PUTBACK;
        }
        FREETMPS; LEAVE;
        if (p) {
            const int *v = INT2PTR(const int *, p);
            present = (*v >= 3);
        }
    }
    return present;
}

/* At to_app, at warning level, naming every `after` rule that will never
 * fire because there is no Hyperman to count in: rate_hit fails open with
 * no arena, which is the right failure for a rate limiter and a surprising
 * one for a challenge. An `always` rule works on any PSGI server; an
 * `after` rule works on Hyperman; an operator who put the site behind
 * Starman for a week should not discover the difference from the traffic
 * graph. Also the csrf exemption, which needs the same moment. */
XS_INTERNAL(pchal_compile_cb);
XS_INTERNAL(pchal_compile_cb)
{
    dXSARGS;
    SV *app = pchal_cap_slot(aTHX_ cv, 0);
    HV *h = app ? pchal_app_hv(aTHX_ app) : NULL;
    SV *rulesv = h ? pchal_hget(aTHX_ h, "challenge_rules") : NULL;
    SV *names = NULL;
    PERL_UNUSED_VAR(items);

    if (app) pchal_csrf_exempt(aTHX_ app, pchal_opts_of(aTHX_ app));

    if (pchal_is_array(rulesv)) {
        AV *rules = (AV *)SvRV(rulesv);
        SSize_t i, n = av_len(rules) + 1;
        for (i = 0; i < n; i++) {
            SV **e = av_fetch(rules, i, 0);
            SV *a;
            if (!(e && *e && pchal_is_hash(*e))) continue;
            a = pchal_hget(aTHX_ (HV *)SvRV(*e), "always");
            if (a && SvTRUE(a)) continue;
            if (!names) names = sv_2mortal(newSVpvs(""));
            else sv_catpvs(names, ", ");
            sv_catpvs(names, "'");
            sv_catsv(names, pchal_hget(aTHX_ (HV *)SvRV(*e), "for"));
            sv_catpvs(names, "'");
        }
    }
    if (names && !pchal_arena_present(aTHX))
        pchal_warn_inert(aTHX_ names, "Hyperman is not loadable here");
    XSRETURN_EMPTY;
}

#endif /* PCHAL_RULES_H */
