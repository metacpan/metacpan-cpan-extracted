/* punk_app.h - the Punk::App registrar, in C.
 *
 * The application object is a blessed hash (the DSL keywords and plugins push
 * into its slots at boot); new and the registrar methods - route, under, api,
 * docs, static, mount, websocket, views, database, model_class, hook,
 * middleware, on_error, helper, plugin - are XSUBs (xs/app.xs). The boot-time
 * orchestration that drives the other XS subsystems (compile, the config
 * loader, target/context resolution) stays Perl in Punk::App, since it is a
 * sequence of require / subsystem ->compile calls.
 *
 * Must be included after punk_context.h (for pcx_call_meth).
 */

#ifndef PUNK_APP_H
#define PUNK_APP_H

static HV *app_hv(pTHX_ SV *self) {
    /*
     # uncoverable branch true
     # uncoverable condition left count:1 class:ignore_covered_err
     # uncoverable condition left count:2 class:ignore_covered_err */
    if (!SvROK(self) || SvTYPE(SvRV(self)) != SVt_PVHV)
        croak("Punk::App: not an application object"); /* # uncoverable statement */
    return (HV *)SvRV(self);
}

static SV *app_get(pTHX_ HV *h, const char *k) {
    SV **e = hv_fetch(h, k, (I32)strlen(k), 0);
    return (e && *e) ? *e : NULL; /* # uncoverable condition right count:2 class:ignore_covered_err */
}

/* the AV in slot k, creating an empty one if absent */
static AV *app_av(pTHX_ HV *h, const char *k) {
    SV *v = app_get(aTHX_ h, k);
    /*
     # uncoverable condition right count:2 class:ignore_covered_err
     # uncoverable condition right count:3 class:ignore_covered_err */
    if (v && SvROK(v) && SvTYPE(SvRV(v)) == SVt_PVAV) return (AV *)SvRV(v);
    {
        AV *a = newAV();
        (void)hv_store(h, k, (I32)strlen(k), newRV_noinc((SV *)a), 0);
        return a;
    }
}

/* the HV in slot k, creating an empty one if absent */
static HV *app_hash(pTHX_ HV *h, const char *k) {
    SV *v = app_get(aTHX_ h, k);
    /*
     # uncoverable condition right count:2 class:ignore_covered_err
     # uncoverable condition right count:3 class:ignore_covered_err */
    if (v && SvROK(v) && SvTYPE(SvRV(v)) == SVt_PVHV) return (HV *)SvRV(v);
    {
        HV *n = newHV();
        (void)hv_store(h, k, (I32)strlen(k), newRV_noinc((SV *)n), 0);
        return n;
    }
}

/* A deep copy of plain data: unblessed hash and array references are copied
 * through, everything else (scalars, blessed objects, coderefs) by newSVsv.
 * For the read-back accessors - a plugin must not be able to edit the
 * application's configuration through a nested hash the shallow copy shared. */
static SV *app_deep_copy(pTHX_ SV *sv) {
    /*
     # uncoverable condition right count:1 class:ignore_covered_err
     # uncoverable condition right count:3 class:ignore_covered_err */
    if (sv && SvROK(sv) && !SvOBJECT(SvRV(sv))) {
        SV *t = SvRV(sv);
        if (SvTYPE(t) == SVt_PVHV) {
            HV *src = (HV *)t, *dst = newHV();
            HE *e;
            hv_iterinit(src);
            while ((e = hv_iternext(src)))
                (void)hv_store_ent(dst, hv_iterkeysv(e),
                                   app_deep_copy(aTHX_ hv_iterval(src, e)), 0);
            return newRV_noinc((SV *)dst);
        }
        if (SvTYPE(t) == SVt_PVAV) {
            AV *src = (AV *)t, *dst = newAV();
            SSize_t i, n = av_len(src) + 1;
            for (i = 0; i < n; i++) {
                SV **x = av_fetch(src, i, 0);
                /*
                 # uncoverable condition right count:1 class:ignore_covered_err
                 # uncoverable condition right count:2 class:ignore_covered_err */
                av_push(dst, app_deep_copy(aTHX_ (x && *x) ? *x : &PL_sv_undef));
            }
            return newRV_noinc((SV *)dst);
        }
    }
    return newSVsv(sv ? sv : &PL_sv_undef); /* # uncoverable condition left count:1 class:ignore_covered_err */
}

/* strip a single trailing '/' from a fresh copy of an SV's string */
static SV *app_strip_slash(pTHX_ SV *sv) {
    STRLEN l;
    const char *p = SvOK(sv) ? SvPV_const(sv, l) : ""; /* # uncoverable condition right count:1 class:ignore_covered_err */
    /*
     # uncoverable branch true
     # uncoverable condition left count:1 class:ignore_covered_err */
    if (!SvOK(sv)) l = 0;
    if (l && p[l - 1] == '/') l--; /* # uncoverable condition right count:1 class:ignore_covered_err */
    return newSVpvn(p, l);
}

/* ---- config-shape helpers (for _apply_config) ------------------------------
 * These mirror Punk::App's _pairs / _list: turning the loose YAML shapes a
 * config block may take into a uniform list to drive the registrar with. */

/* a mapping (name => opts) or a list of names / [name,opts] / {name=>opts}
 * into a mortal AV of [name, opts] pair-refs (opts defaulting to {}). */
static AV *app_pairs(pTHX_ SV *node, const char *what) {
    AV *out = (AV *)sv_2mortal((SV *)newAV());
    if (SvROK(node) && SvTYPE(SvRV(node)) == SVt_PVHV) {
        HV *h = (HV *)SvRV(node); HE *e;
        hv_iterinit(h);
        while ((e = hv_iternext(h))) {
            SV *v = hv_iterval(h, e);
            AV *pair = newAV();
            av_push(pair, newSVsv(hv_iterkeysv(e)));
            /*
             # uncoverable condition right count:1 class:ignore_covered_err
             # uncoverable condition right count:2 class:ignore_covered_err */
            av_push(pair, (v && SvOK(v)) ? newSVsv(v)
                                         : newRV_noinc((SV *)newHV()));
            av_push(out, newRV_noinc((SV *)pair));
        }
    }
    else if (SvROK(node) && SvTYPE(SvRV(node)) == SVt_PVAV) { /* # uncoverable condition right count:2 class:ignore_covered_err */
        AV *a = (AV *)SvRV(node); SSize_t i, n = av_len(a) + 1;
        for (i = 0; i < n; i++) {
            SV **ep = av_fetch(a, i, 0);
            /*
             # uncoverable condition right count:1 class:ignore_covered_err
             # uncoverable condition right count:2 class:ignore_covered_err */
            SV *el = (ep && *ep) ? *ep : &PL_sv_undef;
            AV *pair = newAV();
            if (SvROK(el) && SvTYPE(SvRV(el)) == SVt_PVAV) {
                AV *ea = (AV *)SvRV(el);
                SV **k = av_fetch(ea, 0, 0), **v = av_fetch(ea, 1, 0);
                /*
                 # uncoverable condition right count:1 class:ignore_covered_err
                 # uncoverable condition right count:2 class:ignore_covered_err */
                av_push(pair, newSVsv((k && *k) ? *k : &PL_sv_undef));
                /*
                 # uncoverable condition right count:1 class:ignore_covered_err
                 # uncoverable condition right count:2 class:ignore_covered_err
                 # uncoverable condition right count:3 class:ignore_covered_err */
                av_push(pair, (v && *v && SvOK(*v)) ? newSVsv(*v)
                                                    : newRV_noinc((SV *)newHV()));
            }
            else if (SvROK(el) && SvTYPE(SvRV(el)) == SVt_PVHV) { /* # uncoverable condition right count:2 class:ignore_covered_err */
                HV *eh = (HV *)SvRV(el); HE *he;
                hv_iterinit(eh);
                /*
                 # uncoverable branch false
                 # uncoverable condition right count:1 class:ignore_covered_err */
                if ((he = hv_iternext(eh))) {
                    SV *v = hv_iterval(eh, he);
                    av_push(pair, newSVsv(hv_iterkeysv(he)));
                    /*
                     # uncoverable condition right count:1 class:ignore_covered_err
                     # uncoverable condition right count:2 class:ignore_covered_err */
                    av_push(pair, (v && SvOK(v)) ? newSVsv(v)
                                                 : newRV_noinc((SV *)newHV()));
                }
            }
            else {
                av_push(pair, newSVsv(el));
                av_push(pair, newRV_noinc((SV *)newHV()));
            }
            av_push(out, newRV_noinc((SV *)pair));
        }
    }
    else {
        croak("Punk: the config %s block must be a mapping or a list", what);
    }
    return out;
}

/* a scalar / arrayref / hashref (keys) into a mortal AV of names */
static AV *app_list(pTHX_ SV *node, const char *what) {
    AV *out = (AV *)sv_2mortal((SV *)newAV());
    if (!SvROK(node)) { av_push(out, newSVsv(node)); return out; }
    if (SvTYPE(SvRV(node)) == SVt_PVAV) {
        AV *a = (AV *)SvRV(node); SSize_t i, n = av_len(a) + 1;
        for (i = 0; i < n; i++) {
            SV **e = av_fetch(a, i, 0);
            /*
             # uncoverable condition right count:1 class:ignore_covered_err
             # uncoverable condition right count:2 class:ignore_covered_err */
            av_push(out, newSVsv((e && *e) ? *e : &PL_sv_undef));
        }
        return out;
    }
    if (SvTYPE(SvRV(node)) == SVt_PVHV) {
        HV *h = (HV *)SvRV(node); HE *e;
        hv_iterinit(h);
        while ((e = hv_iternext(h))) av_push(out, newSVsv(hv_iterkeysv(e)));
        return out;
    }
    croak("Punk: the config %s block must be a list", what);
    return out;
}

/* the sorted (string) keys of an HV as a mortal AV of key SVs */
static AV *app_sorted_keys(pTHX_ HV *h) {
    AV *out = (AV *)sv_2mortal((SV *)newAV());
    HE *e;
    hv_iterinit(h);
    while ((e = hv_iternext(h))) av_push(out, newSVsv(hv_iterkeysv(e)));
    sortsv(AvARRAY(out), (size_t)(av_len(out) + 1), Perl_sv_cmp);
    return out;
}

/* call $self->$meth(@$args), discarding the (chainable) return */
/* Is a config value the bare "on" form? A YAML `true` does not arrive as
 * the scalar 1: Punk::Config loads booleans as JSON::PP::Boolean objects,
 * a blessed scalar ref whose truth is an overload. So a plain truthy
 * scalar is on, a boolean object is whatever it says, and any other
 * reference - a mapping, a list - is not this form at all. */
static int app_cfg_on(pTHX_ SV *sv) {
    /*
     # uncoverable branch true
     # uncoverable condition left count:1 class:ignore_covered_err
     # uncoverable condition left count:2 class:ignore_covered_err */
    if (!sv || !SvOK(sv)) return 0;
    if (!SvROK(sv)) return SvTRUE(sv) ? 1 : 0;
    /*
     # uncoverable branch false
     # uncoverable condition right count:1 class:ignore_covered_err
     # uncoverable condition right count:2 class:ignore_covered_err */
    if (SvOBJECT(SvRV(sv)) && SvTYPE(SvRV(sv)) < SVt_PVAV)
        return SvTRUE(sv) ? 1 : 0;
    return 0; /* # uncoverable statement */
}

static void app_call_list(pTHX_ SV *self, const char *meth, AV *args) {
    SSize_t n = av_len(args) + 1, i;
    SV **argv, *r;
    Newx(argv, n > 0 ? n : 1, SV *);
    for (i = 0; i < n; i++) {
        SV **e = av_fetch(args, i, 0);
        /*
         # uncoverable condition right count:1 class:ignore_covered_err
         # uncoverable condition right count:2 class:ignore_covered_err */
        argv[i] = (e && *e) ? *e : &PL_sv_undef;
    }
    r = pcx_call_meth(aTHX_ self, meth, argv, (int)n, 0);
    /*
     # uncoverable branch true
     # uncoverable condition left count:1 class:ignore_covered_err */
    if (r) SvREFCNT_dec(r);
    Safefree(argv);
}

/* ---- the one-hashref route form -------------------------------------------
 *
 *     post '/upload' => { cb => 'Web::File#create', max_body => 50_000_000 };
 *
 * instead of the positional
 *
 *     post '/upload' => 'Web::File#create', { max_body => 50_000_000 };
 *
 * Both spellings are supported; this splits the first into the second at the
 * front door, so the router, the compiled records and every consumer
 * downstream see exactly what they have always seen.
 *
 * Purely additive: a hashref in the target slot was a boot croak before this
 * existed ("must be a coderef or 'Controller#method'"), so no application can
 * have been relying on the behaviour being replaced.
 *
 * `what` names the declaration for the croaks ("route POST", "websocket",
 * "sse"); `path` is only ever read for those messages. Both out-params are
 * left alone when `*target` is not a hashref.
 */
static void pk_spec_split(pTHX_ const char *what, SV *path,
                          SV **target, SV **opts) {
    HV *spec, *o;
    SV **cb;
    HE *he;

    if (!(*target && SvROK(*target) && SvTYPE(SvRV(*target)) == SVt_PVHV)) /* # uncoverable condition left count:1 class:ignore_covered_err */
        return;
    spec = (HV *)SvRV(*target);

    /*
     # uncoverable condition right count:1 class:ignore_covered_err
     # uncoverable condition right count:2 class:ignore_covered_err */
    if (opts && *opts && SvOK(*opts))
        croak("Punk: %s %s takes its options either inside the hashref or "
              "after the target, not both",
              what, SvOK(path) ? SvPV_nolen(path) : "(no path)"); /* # uncoverable condition right count:1 class:ignore_covered_err */

    cb = hv_fetchs(spec, "cb", 0);
    if (!(cb && *cb && SvOK(*cb))) /* # uncoverable condition left count:2 class:ignore_covered_err */
        croak("Punk: %s %s has options but no `cb` - a route needs a handler "
              "(a coderef or 'Controller#method')",
              what, SvOK(path) ? SvPV_nolen(path) : "(no path)"); /* # uncoverable condition right count:1 class:ignore_covered_err */

    /* Copy the remaining keys rather than deleting `cb` from the caller's
     * hashref. A spec built once and declared twice
     *
     *     my %spec = (cb => \&h, max_body => 10);
     *     get '/a' => \%spec;  post '/b' => \%spec;
     *
     * must give two working routes; mutating it would leave the second
     * without a handler, and would pass every test but that one. */
    o = newHV();
    hv_iterinit(spec);
    while ((he = hv_iternext(spec))) {
        STRLEN kl;
        const char *k = HePV(he, kl);
        if (kl == 2 && memEQ(k, "cb", 2)) continue; /* # uncoverable condition right count:2 class:ignore_covered_err */
        (void)hv_store(o, k, (I32)kl, newSVsv(hv_iterval(spec, he)), 0);
    }

    /* the target LAST: it aliases into the spec we have just finished
     * reading, and reassigning it first would be reading a freed hashref if
     * the caller held no other reference */
    *target = sv_2mortal(newSVsv(*cb));
    /*
     # uncoverable branch false
     # uncoverable condition right count:1 class:ignore_covered_err */
    if (opts) *opts = sv_2mortal(newRV_noinc((SV *)o));
    else      SvREFCNT_dec((SV *)o); /* # uncoverable statement */
}

/* "METHOD PATH" -> the compiled record, as a mortal HV.
 *
 * A route option is recorded at declaration as { method, path, ... } and
 * compiled at to_app onto the record the router built, which is the only
 * place the guards AV lives. Every option that becomes a guard needs the
 * same lookup, so it is written once; `what` names the option in the two
 * croaks, which are both "the application declared this against a route
 * that does not exist". */
static HV *pk_route_index(pTHX_ SV *self, const char *what) {
    HV *h = (HV *)SvRV(self);
    SV **rop = hv_fetchs(h, K_ROUTER, 0);
    SV *recs_rv;
    AV *recs;
    HV *by;
    SSize_t ri, rn;
    /*
     # uncoverable branch true
     # uncoverable condition left count:1 class:ignore_covered_err
     # uncoverable condition left count:2 class:ignore_covered_err
     # uncoverable condition left count:3 class:ignore_covered_err */
    if (!(rop && *rop && SvOK(*rop)))
        croak("Punk: %s routes with no router", what); /* # uncoverable statement */
    recs_rv = pcx_call_meth(aTHX_ *rop, "records", NULL, 0, 1);
    /*
     # uncoverable branch true
     # uncoverable condition left count:1 class:ignore_covered_err
     # uncoverable condition left count:2 class:ignore_covered_err
     # uncoverable condition left count:3 class:ignore_covered_err */
    if (!(recs_rv && SvROK(recs_rv) && SvTYPE(SvRV(recs_rv)) == SVt_PVAV)) {
        /*
         # uncoverable statement
         # uncoverable branch true
         # uncoverable branch false
         # uncoverable condition left count:1
         # uncoverable condition right count:1 */
        if (recs_rv) SvREFCNT_dec(recs_rv);
        croak("Punk: %s routes but no compiled records", what); /* # uncoverable statement */
    }
    sv_2mortal(recs_rv);
    recs = (AV *)SvRV(recs_rv);
    by = (HV *)sv_2mortal((SV *)newHV());
    rn = av_len(recs) + 1;
    for (ri = 0; ri < rn; ri++) {
        SV **rp = av_fetch(recs, ri, 0);
        HV *rec;
        SV **m, **p, *key;
        /*
         # uncoverable branch true
         # uncoverable condition left count:1 class:ignore_covered_err
         # uncoverable condition left count:2 class:ignore_covered_err
         # uncoverable condition left count:3 class:ignore_covered_err
         # uncoverable condition left count:4 class:ignore_covered_err */
        if (!(rp && *rp && SvROK(*rp) && SvTYPE(SvRV(*rp)) == SVt_PVHV))
            continue; /* # uncoverable statement */
        rec = (HV *)SvRV(*rp);
        m = hv_fetchs(rec, K_METHOD, 0);
        p = hv_fetchs(rec, K_PATH, 0);
        /*
         # uncoverable branch true
         # uncoverable condition left count:1 class:ignore_covered_err
         # uncoverable condition left count:2 class:ignore_covered_err
         # uncoverable condition left count:3 class:ignore_covered_err
         # uncoverable condition left count:4 class:ignore_covered_err */
        if (!(m && *m && p && *p)) continue;
        key = sv_2mortal(newSVsv(*m));
        sv_catpvs(key, " ");
        sv_catsv(key, *p);
        (void)hv_store_ent(by, key, newSVsv(*rp), 0);
    }
    return by;
}

/* Append a guard closure to a compiled record's guards, vivifying the AV.
 * Takes the +1 the caller holds. */
static void pk_route_guard_push(pTHX_ HV *rec, SV *guard) {
    SV **gp = hv_fetchs(rec, K_GUARDS, 0);
    /*
     # uncoverable branch true
     # uncoverable condition left count:1 class:ignore_covered_err
     # uncoverable condition left count:2 class:ignore_covered_err
     # uncoverable condition left count:3 class:ignore_covered_err
     # uncoverable condition left count:4 class:ignore_covered_err */
    if (!(gp && *gp && SvROK(*gp) && SvTYPE(SvRV(*gp)) == SVt_PVAV)) {
        (void)hv_stores(rec, K_GUARDS, newRV_noinc((SV *)newAV())); /* # uncoverable statement */
        gp = hv_fetchs(rec, K_GUARDS, 0); /* # uncoverable statement */
    }
    av_push((AV *)SvRV(*gp), guard);
}

#endif /* PUNK_APP_H */
