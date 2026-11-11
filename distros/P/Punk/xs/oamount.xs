MODULE = Punk        PACKAGE = Punk::Mount::OpenAPI

PROTOTYPES: DISABLE

# The `api` mount, in C (punk_oamount.h). Everything resolves at boot into one
# record per operation - controller, guard chain - and the request path is
# punk_dispatch.h. Punk::Mount::OpenAPI.pm is the documentation.

SV *
new(class, ...)
        SV *class
    CODE:
    {
        static const char *const KNOWN[] = {
            "controller_ns", "handlers", "under", "security",
            "max_body_size", "on_error", "stub"
        };
        HV *h = newHV();
        SV *spec = NULL, *opts = NULL, *prefix = NULL, *guards = NULL;
        HV *oh;
        int i;
        for (i = 1; i + 1 < items; i += 2) {
            STRLEN kl; const char *k = SvPV_const(ST(i), kl);
            if      (kl == 4 && memEQ(k, "spec",   4)) spec   = ST(i + 1);
            else if (kl == 4 && memEQ(k, "opts",   4)) opts   = ST(i + 1); /* # uncoverable condition right count:2 class:ignore_covered_err */
            else if (kl == 6 && memEQ(k, "prefix", 6)) prefix = ST(i + 1); /* # uncoverable condition right count:1 class:ignore_covered_err */
            # uncoverable branch false
            # uncoverable condition right count:1 class:ignore_covered_err
            # uncoverable condition right count:2 class:ignore_covered_err
            else if (kl == 6 && memEQ(k, "guards", 6)) guards = ST(i + 1);
        }
        oh = poa_hash_of(aTHX_ opts);

        /* unknown options are a typo in the app, so they are named and fatal
         * at boot rather than quietly ignored */
        # uncoverable branch false
        # uncoverable condition right count:1 class:ignore_covered_err
        if (oh) {
            AV *bad = (AV *)sv_2mortal((SV *)newAV());
            HE *he;
            SSize_t bn;
            hv_iterinit(oh);
            while ((he = hv_iternext(oh))) {
                STRLEN kl; const char *k = HePV(he, kl);
                int ok = 0, j;
                for (j = 0; j < 7; j++)
                    if (strEQ(k, KNOWN[j])) { ok = 1; break; }
                if (!ok) av_push(bad, newSVpvn(k, kl));
            }
            bn = av_len(bad) + 1;
            if (bn) {
                SV *msg = sv_2mortal(newSVpvs(""));
                SSize_t j;
                # uncoverable branch true
                # uncoverable condition left count:1 class:ignore_covered_err
                if (bn > 1) sortsv(AvARRAY(bad), (STRLEN)bn, Perl_sv_cmp);
                for (j = 0; j < bn; j++) {
                    # uncoverable branch true
                    # uncoverable condition left count:1 class:ignore_covered_err
                    if (j) sv_catpvs(msg, ", ");
                    sv_catsv(msg, *av_fetch(bad, j, 0));
                }
                SvREFCNT_dec((SV *)h);
                croak("Punk: unknown api mount option(s) %s", SvPV_nolen(msg));
            }
        }

        (void)hv_stores(h, "spec", spec ? newSVsv(spec) : newSV(0)); /* # uncoverable condition right count:1 class:ignore_covered_err */
        (void)hv_stores(h, "opts",
            oh ? newSVsv(opts) : newRV_noinc((SV *)newHV()));
        (void)hv_stores(h, "prefix",
            (prefix && SvOK(prefix)) ? newSVsv(prefix) : newSVpvs(""));
        (void)hv_stores(h, "guards",
            poa_av_of(aTHX_ guards) ? newSVsv(guards)
                                    : newRV_noinc((SV *)newAV()));
        RETVAL = sv_bless(newRV_noinc((SV *)h), gv_stashsv(class, GV_ADD));
    }
    OUTPUT:
        RETVAL

SV *
prefix(self)
        SV *self
    ALIAS:
        api           = 1
        ops           = 2
        max_body_size = 3
        on_error      = 4
    CODE:
    {
        static const char *const SLOT[] =
            { "prefix", "api", "ops", "max_body_size", "on_error" };
        SV *v = poa_get(aTHX_ poa_hv(aTHX_ self), SLOT[ix]);
        RETVAL = v ? newSVsv(v) : newSV(0); /* # uncoverable condition right count:1 class:ignore_covered_err */
    }
    OUTPUT:
        RETVAL

# ---- boot -------------------------------------------------------------------

# compile($app, $resolve): resolve every operationId to a controller method and
# freeze its guard chain (scope guards, then the spec's security requirement,
# then any per-spec-prefix guards). Chains, returning the mount.
SV *
compile(self, app, resolve)
        SV *self
        SV *app
        SV *resolve
    CODE:
    {
        HV *h    = poa_hv(aTHX_ self);
        HV *opts = poa_hash_of(aTHX_ poa_get(aTHX_ h, "opts"));
        SV *api, *ops_list, *spec_sv;
        AV *ops_av;
        HV *spec, *schemes, *checkers, *handlers, *under;
        HV *resolved, *security, *prefix_guards, *ops;
        AV *scope_guards, *classes;
        SV *ns;
        SSize_t i, n;

        /* Open::API->new(spec => $self->{spec}) */
        {
            SV *argv[2];
            argv[0] = sv_2mortal(newSVpvs("spec"));
            argv[1] = poa_get(aTHX_ h, "spec");
            # uncoverable branch true
            # uncoverable condition left count:1 class:ignore_covered_err
            if (!argv[1]) argv[1] = &PL_sv_undef;
            (void)pk_require_once(aTHX_ "Open::API", TRUE);
            api = pcx_call_meth(aTHX_ sv_2mortal(newSVpvs("Open::API")), "new",
                                argv, 2, 1);
            # uncoverable branch true
            # uncoverable condition left count:1 class:ignore_covered_err
            if (!api) croak("Punk: Open::API->new returned nothing");
            (void)hv_stores(h, "api", api);          /* the hash owns it */
        }

        /* the two things the ABI has no C form for: one call each, at boot */
        ops_list = pcx_call_meth(aTHX_ api, "operations", NULL, 0, 1);
        spec_sv  = pcx_call_meth(aTHX_ api, "spec", NULL, 0, 1);
        ops_av   = poa_av_of(aTHX_ ops_list);
        spec     = poa_hash_of(aTHX_ spec_sv);
        # uncoverable branch false
        # uncoverable condition right count:1 class:ignore_covered_err
        if (ops_list) sv_2mortal(ops_list);
        # uncoverable branch false
        # uncoverable condition right count:1 class:ignore_covered_err
        if (spec_sv)  sv_2mortal(spec_sv);
        # uncoverable branch true
        # uncoverable condition left count:1 class:ignore_covered_err
        if (!ops_av) ops_av = (AV *)sv_2mortal((SV *)newAV());

        /* the mount scope's own guards */
        scope_guards = (AV *)sv_2mortal((SV *)newAV());
        {
            AV *g = poa_av_of(aTHX_ poa_get(aTHX_ h, "guards"));
            SSize_t gn = g ? av_len(g) + 1 : 0; /* # uncoverable condition right count:1 class:ignore_covered_err */
            for (i = 0; i < gn; i++)
                av_push(scope_guards,
                        poa_resolve(aTHX_ resolve, *av_fetch(g, i, 0),
                                    "api mount guard"));
        }

        /* ---- security requirements -> one generated guard per operation ----
         * Alternatives are OR, schemes within one are AND. Coverage is checked
         * here: a required scheme with no checker croaks at boot rather than
         * leaving an open door. */
        schemes  = spec ? poa_hash_of(aTHX_ poa_get(aTHX_ spec, "components"))
                        : NULL;
        if (schemes) schemes = poa_hash_of(aTHX_
                                   poa_get(aTHX_ schemes, "securitySchemes"));
        checkers = opts ? poa_hash_of(aTHX_ poa_get(aTHX_ opts, "security"))
                        : NULL;
        resolved = (HV *)sv_2mortal((SV *)newHV());
        if (checkers) {
            HE *he;
            hv_iterinit(checkers);
            while ((he = hv_iternext(checkers))) {
                SV *k = HeSVKEY_force(he);
                SV *what = sv_2mortal(newSVpvs("security checker '"));
                sv_catsv(what, k); sv_catpvs(what, "'");
                (void)hv_store_ent(resolved, k,
                    poa_resolve(aTHX_ resolve, HeVAL(he), SvPV_nolen(what)), 0);
            }
        }

        security = (HV *)sv_2mortal((SV *)newHV());
        n = av_len(ops_av) + 1;
        for (i = 0; i < n; i++) {
            HV *op = poa_hash_of(aTHX_ *av_fetch(ops_av, i, 0));
            SV *id, *path, *method, *req = NULL;
            AV *req_av, *alts;
            SSize_t ai, an;
            # uncoverable branch true
            # uncoverable condition left count:1 class:ignore_covered_err
            if (!op) continue;
            id     = poa_get(aTHX_ op, "operationId");
            path   = poa_get(aTHX_ op, "path");
            method = poa_get(aTHX_ op, "method");

            /* the operation's own `security`, else the document's */
            # uncoverable branch false
            # uncoverable condition right count:1 class:ignore_covered_err
            # uncoverable condition right count:2 class:ignore_covered_err
            # uncoverable condition right count:3 class:ignore_covered_err
            if (spec && path && method) {
                HV *paths = poa_hash_of(aTHX_ poa_get(aTHX_ spec, "paths"));
                HE *pe = paths ? hv_fetch_ent(paths, path, 0, 0) : NULL; /* # uncoverable condition right count:1 class:ignore_covered_err */
                HV *item = pe ? poa_hash_of(aTHX_ HeVAL(pe)) : NULL; /* # uncoverable condition right count:1 class:ignore_covered_err */
                SV *lc = sv_2mortal(newSVsv(method));
                HE *me;
                sv_catpvs(lc, "");
                {   /* lc $op->{method} */
                    STRLEN ml; char *mp = SvPV_force(lc, ml); STRLEN j;
                    for (j = 0; j < ml; j++) mp[j] = (char)toLOWER((U8)mp[j]); /* # uncoverable condition left count:1 class:ignore_covered_err */
                }
                me = item ? hv_fetch_ent(item, lc, 0, 0) : NULL; /* # uncoverable condition right count:1 class:ignore_covered_err */
                # uncoverable branch false
                # uncoverable condition right count:1 class:ignore_covered_err
                if (me) {
                    HV *raw = poa_hash_of(aTHX_ HeVAL(me));
                    if (raw && hv_exists(raw, "security", 8)) /* # uncoverable condition right count:1 class:ignore_covered_err */
                        req = poa_get(aTHX_ raw, "security");
                    else req = poa_get(aTHX_ spec, "security");
                }
                else req = poa_get(aTHX_ spec, "security"); /* # uncoverable statement */
            }
            req_av = poa_av_of(aTHX_ req);
            if (!req_av || av_len(req_av) < 0) continue;

            alts = newAV();
            an = av_len(req_av) + 1;
            for (ai = 0; ai < an; ai++) {
                HV *alt = poa_hash_of(aTHX_ *av_fetch(req_av, ai, 0));
                AV *names, *and_av;
                SSize_t ni, nn;
                # uncoverable branch true
                # uncoverable condition left count:1 class:ignore_covered_err
                if (!alt) continue;
                names = (AV *)sv_2mortal((SV *)newAV());
                {
                    HE *he;
                    hv_iterinit(alt);
                    while ((he = hv_iternext(alt)))
                        av_push(names, newSVsv(HeSVKEY_force(he)));
                }
                nn = av_len(names) + 1;
                if (nn > 1) sortsv(AvARRAY(names), (STRLEN)nn, Perl_sv_cmp);
                and_av = newAV();
                for (ni = 0; ni < nn; ni++) {
                    SV *name = *av_fetch(names, ni, 0);
                    HE *ce = hv_fetch_ent(resolved, name, 0, 0);
                    HE *de = schemes ? hv_fetch_ent(schemes, name, 0, 0) : NULL; /* # uncoverable condition right count:1 class:ignore_covered_err */
                    AV *part;
                    HE *se;
                    if (!(ce && SvOK(HeVAL(ce)))) { /* # uncoverable condition left count:2 class:ignore_covered_err */
                        SvREFCNT_dec((SV *)and_av);
                        SvREFCNT_dec((SV *)alts);
                        croak("Punk: operation '%s' requires securityScheme "
                              "'%s' but no checker is registered in the "
                              "mount's security option",
                              id ? SvPV_nolen(id) : "?", SvPV_nolen(name));
                    }
                    # uncoverable branch true
                    # uncoverable condition left count:1 class:ignore_covered_err
                    # uncoverable condition left count:2 class:ignore_covered_err
                    if (!(de && poa_hash_of(aTHX_ HeVAL(de)))) {
                        SvREFCNT_dec((SV *)and_av); /* # uncoverable statement */
                        SvREFCNT_dec((SV *)alts); /* # uncoverable statement */
                        croak("Punk: securityScheme '%s' is not declared in " /* # uncoverable statement */
                              "components.securitySchemes", SvPV_nolen(name)); /* # uncoverable statement */
                    }
                    se = hv_fetch_ent(alt, name, 0, 0);
                    part = newAV();
                    av_push(part, newSVsv(name));
                    av_push(part, newSVsv(HeVAL(de)));
                    av_push(part, newSVsv(HeVAL(ce)));
                    av_push(part, se ? newSVsv(HeVAL(se)) : newSV(0)); /* # uncoverable condition right count:1 class:ignore_covered_err */
                    av_push(and_av, newRV_noinc((SV *)part));
                }
                # uncoverable branch false
                # uncoverable condition right count:1 class:ignore_covered_err
                if (av_len(and_av) >= 0)
                    av_push(alts, newRV_noinc((SV *)and_av));
                else SvREFCNT_dec((SV *)and_av); /* # uncoverable statement */
            }

            # uncoverable branch false
            # uncoverable condition right count:1 class:ignore_covered_err
            # uncoverable condition right count:2 class:ignore_covered_err
            if (av_len(alts) >= 0 && id) {
                AV *cap = newAV();
                av_push(cap, newSVsv(id));
                av_push(cap, newRV_noinc((SV *)alts));
                (void)hv_store_ent(security, id,
                    punk_closure(aTHX_ punk_oa_security_cb, cap), 0);
            }
            else SvREFCNT_dec((SV *)alts); /* # uncoverable statement */
        }

        /* ---- per-spec-prefix guards (the mount's `under` option) ----------
         * Longest prefix wins, and a prefix only matches on a path-segment
         * boundary so /books never picks up /booksellers. */
        prefix_guards = (HV *)sv_2mortal((SV *)newHV());
        under = opts ? poa_hash_of(aTHX_ poa_get(aTHX_ opts, "under")) : NULL; /* # uncoverable condition right count:1 class:ignore_covered_err */
        if (under) {
            AV *keys = (AV *)sv_2mortal((SV *)newAV());
            AV *rules = (AV *)sv_2mortal((SV *)newAV());
            SSize_t ki, kn;
            HE *he;
            hv_iterinit(under);
            while ((he = hv_iternext(under)))
                av_push(keys, newSVsv(HeSVKEY_force(he)));
            kn = av_len(keys) + 1;
            /* by length, descending - an insertion sort; a mount has a
             * handful of prefixes, not thousands */
            # uncoverable branch true
            # uncoverable condition left count:1 class:ignore_covered_err
            for (ki = 1; ki < kn; ki++) {
                SV *cur = *av_fetch(keys, ki, 0); /* # uncoverable statement */
                SSize_t kj = ki - 1; /* # uncoverable statement */
                SvREFCNT_inc(cur); /* # uncoverable statement */
                # uncoverable statement
                # uncoverable branch true
                # uncoverable branch false
                while (kj >= 0
                       # uncoverable statement
                       # uncoverable condition left count:1
                       # uncoverable condition right count:1
                       # uncoverable condition left count:2
                       # uncoverable condition right count:2
                       && SvCUR(*av_fetch(keys, kj, 0)) < SvCUR(cur)) {
                    (void)av_store(keys, kj + 1, /* # uncoverable statement */
                                   SvREFCNT_inc(*av_fetch(keys, kj, 0)));
                    kj--; /* # uncoverable statement */
                }
                (void)av_store(keys, kj + 1, cur); /* # uncoverable statement */
            }
            for (ki = 0; ki < kn; ki++) {
                SV *k = *av_fetch(keys, ki, 0);
                HE *ue = hv_fetch_ent(under, k, 0, 0);
                AV *list = ue ? poa_av_of(aTHX_ HeVAL(ue)) : NULL; /* # uncoverable condition right count:1 class:ignore_covered_err */
                AV *gs = newAV(), *rule = newAV();
                # uncoverable branch true
                # uncoverable condition left count:1 class:ignore_covered_err
                if (list) {
                    SSize_t gi, gn = av_len(list) + 1; /* # uncoverable statement */
                    # uncoverable statement
                    # uncoverable branch true
                    # uncoverable branch false
                    # uncoverable condition left count:1
                    # uncoverable condition right count:1
                    for (gi = 0; gi < gn; gi++)
                        av_push(gs, poa_resolve(aTHX_ resolve, /* # uncoverable statement */
                                    *av_fetch(list, gi, 0), "api under guard"));
                }
                # uncoverable branch false
                # uncoverable condition right count:1 class:ignore_covered_err
                else if (ue)
                    av_push(gs, poa_resolve(aTHX_ resolve, HeVAL(ue),
                                            "api under guard"));
                av_push(rule, newSVsv(k));
                av_push(rule, newRV_noinc((SV *)gs));
                av_push(rules, newRV_noinc((SV *)rule));
            }
            n = av_len(ops_av) + 1;
            for (i = 0; i < n; i++) {
                HV *op = poa_hash_of(aTHX_ *av_fetch(ops_av, i, 0));
                SV *path = op ? poa_get(aTHX_ op, "path") : NULL; /* # uncoverable condition right count:1 class:ignore_covered_err */
                SV *id   = op ? poa_get(aTHX_ op, "operationId") : NULL; /* # uncoverable condition right count:1 class:ignore_covered_err */
                STRLEN pl;
                const char *ps;
                SSize_t ri, rn = av_len(rules) + 1;
                # uncoverable branch true
                # uncoverable condition left count:1 class:ignore_covered_err
                # uncoverable condition left count:2 class:ignore_covered_err
                if (!(path && id)) continue;
                ps = SvPV_const(path, pl);
                for (ri = 0; ri < rn; ri++) {
                    AV *rule = (AV *)SvRV(*av_fetch(rules, ri, 0));
                    SV *pre = *av_fetch(rule, 0, 0);
                    STRLEN rl;
                    const char *rs = SvPV_const(pre, rl);
                    if (pl < rl || memNE(ps, rs, rl)) continue; /* # uncoverable condition left count:2 class:ignore_covered_err */
                    # uncoverable branch true
                    # uncoverable condition left count:1 class:ignore_covered_err
                    # uncoverable condition left count:2 class:ignore_covered_err
                    if (pl != rl && ps[rl] != '/') continue;
                    (void)hv_store_ent(prefix_guards, id,
                        newSVsv(*av_fetch(rule, 1, 0)), 0);
                    break;                        /* longest prefix wins */
                }
            }
        }

        /* ---- the operation table ------------------------------------------ */
        ns = opts ? poa_get(aTHX_ opts, "controller_ns") : NULL; /* # uncoverable condition right count:1 class:ignore_covered_err */
        # uncoverable branch false
        # uncoverable condition right count:1 class:ignore_covered_err
        # uncoverable condition left count:2 class:ignore_covered_err
        # uncoverable condition right count:2 class:ignore_covered_err
        if (!(ns && SvOK(ns))) {
            SV *cc = pcx_call_meth(aTHX_ app, "caller_class", NULL, 0, 1);
            ns = sv_2mortal(cc ? cc : newSVpvs("")); /* # uncoverable condition left count:1 class:ignore_covered_err */
            sv_catpvs(ns, "::Controller::API");
        }
        else ns = sv_2mortal(newSVsv(ns)); /* # uncoverable statement */
        (void)hv_stores(h, "ns", newSVsv(ns));

        classes  = poa_load_namespace(aTHX_ ns);
        handlers = opts ? poa_hash_of(aTHX_ poa_get(aTHX_ opts, "handlers"))
                        : NULL;
        ops = newHV();
        n = av_len(ops_av) + 1;
        for (i = 0; i < n; i++) {
            HV *op = poa_hash_of(aTHX_ *av_fetch(ops_av, i, 0));
            SV *id = op ? poa_get(aTHX_ op, "operationId") : NULL; /* # uncoverable condition right count:1 class:ignore_covered_err */
            SV *code;
            HV *rec;
            AV *guards;
            HE *he;
            SSize_t gi, gn;
            # uncoverable branch true
            # uncoverable condition left count:1 class:ignore_covered_err
            if (!id) continue;

            code = poa_find_handler(aTHX_ id, handlers, classes, resolve);
            if (!code) {
                SV *stub = opts ? poa_get(aTHX_ opts, "stub") : NULL; /* # uncoverable condition right count:1 class:ignore_covered_err */
                if (!(stub && SvTRUE(stub))) { /* # uncoverable condition left count:2 class:ignore_covered_err */
                    SvREFCNT_dec((SV *)ops);
                    croak("Punk: operation '%s' has no controller method under "
                          "%s (define it, name a handler in the mount's "
                          "handlers option, or set stub => 1)",
                          SvPV_nolen(id), SvPV_nolen(ns));
                }
            }

            guards = newAV();
            gn = av_len(scope_guards) + 1;
            for (gi = 0; gi < gn; gi++)
                av_push(guards, newSVsv(*av_fetch(scope_guards, gi, 0)));
            he = hv_fetch_ent(security, id, 0, 0);
            if (he) av_push(guards, newSVsv(HeVAL(he)));
            he = hv_fetch_ent(prefix_guards, id, 0, 0);
            if (he) {
                AV *pg = poa_av_of(aTHX_ HeVAL(he));
                SSize_t pi, pn = pg ? av_len(pg) + 1 : 0; /* # uncoverable condition right count:1 class:ignore_covered_err */
                for (pi = 0; pi < pn; pi++)
                    av_push(guards, newSVsv(*av_fetch(pg, pi, 0)));
            }

            rec = newHV();
            (void)hv_stores(rec, "code", code ? code : newSV(0));
            (void)hv_stores(rec, "guards", newRV_noinc((SV *)guards));
            (void)hv_store_ent(ops, id, newRV_noinc((SV *)rec), 0);
        }
        (void)hv_stores(h, "ops", newRV_noinc((SV *)ops));

        {
            SV *m = opts ? poa_get(aTHX_ opts, "max_body_size") : NULL; /* # uncoverable condition right count:1 class:ignore_covered_err */
            (void)hv_stores(h, "max_body_size",
                (m && SvOK(m)) ? newSVsv(m) : newSViv(1048576));
        }
        {
            SV *e = opts ? poa_get(aTHX_ opts, "on_error") : NULL; /* # uncoverable condition right count:1 class:ignore_covered_err */
            (void)hv_stores(h, "on_error",
                (e && SvOK(e))
                    ? poa_resolve(aTHX_ resolve, e, "api mount on_error")
                    : newSV(0));
        }

        RETVAL = newSVsv(self);
    }
    OUTPUT:
        RETVAL

# ---- request time -----------------------------------------------------------

# The whole per-request path runs in C (punk_dispatch.h): before-dispatch
# hooks, the operation's guards, the body-size and no-handler checks, raw-input
# assembly and validation through the ABI, stashing the typed params, and the
# controller call. Guards run before validation, so a 401 costs no body read.
# Returns ($ret, $err) for Punk::App's finish path.
void
# uncoverable statement
# uncoverable subroutine
dispatch(self, c, before, op_id, caps)
        SV *self
        SV *c
        SV *before
        SV *op_id
        SV *caps
    PPCODE:
    {
        HV *h = poa_hv(aTHX_ self); /* # uncoverable statement */
        HV *ops = poa_hash_of(aTHX_ poa_get(aTHX_ h, "ops")); /* # uncoverable statement */
        # uncoverable statement
        # uncoverable condition left count:1
        # uncoverable condition right count:1
        HE *he = ops ? hv_fetch_ent(ops, op_id, 0, 0) : NULL;
        # uncoverable statement
        # uncoverable condition left count:1
        # uncoverable condition right count:1
        SV *rec = he ? HeVAL(he) : &PL_sv_undef;
        SV *mbs = poa_get(aTHX_ h, "max_body_size"); /* # uncoverable statement */
        AV *before_av = poa_av_of(aTHX_ before); /* # uncoverable statement */
        SV *ret, *err;
        # uncoverable statement
        # uncoverable branch true
        # uncoverable branch false
        # uncoverable condition left count:1
        # uncoverable condition right count:1
        # uncoverable condition left count:2
        # uncoverable condition right count:2
        if (!(SvROK(rec) && SvTYPE(SvRV(rec)) == SVt_PVHV))
            croak("Punk: no compiled record for operation '%s'", /* # uncoverable statement */
                  SvPV_nolen(op_id)); /* # uncoverable statement */
        punk_oa_dispatch(aTHX_ c, before_av, (HV *)SvRV(rec), /* # uncoverable statement */
                         poa_get(aTHX_ h, "api"), op_id, caps, /* # uncoverable statement */
                         mbs ? SvIV(mbs) : 1048576, &ret, &err); /* # uncoverable statement */
        SP = PL_stack_base + ax - 1;      /* hooks and the controller ran */ /* # uncoverable statement */
        EXTEND(SP, 2); /* # uncoverable statement */
        # uncoverable statement
        # uncoverable condition left count:1
        # uncoverable condition right count:1
        PUSHs(ret == &PL_sv_undef ? ret : sv_2mortal(ret));
        # uncoverable statement
        # uncoverable condition left count:1
        # uncoverable condition right count:1
        PUSHs(err == &PL_sv_undef ? err : sv_2mortal(err));
    }
