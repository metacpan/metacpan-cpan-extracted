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
    if (!SvROK(self) || SvTYPE(SvRV(self)) != SVt_PVHV)
        croak("Punk::App: not an application object");
    return (HV *)SvRV(self);
}

static SV *app_get(pTHX_ HV *h, const char *k) {
    SV **e = hv_fetch(h, k, (I32)strlen(k), 0);
    return (e && *e) ? *e : NULL;
}

/* the AV in slot k, creating an empty one if absent */
static AV *app_av(pTHX_ HV *h, const char *k) {
    SV *v = app_get(aTHX_ h, k);
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
    if (v && SvROK(v) && SvTYPE(SvRV(v)) == SVt_PVHV) return (HV *)SvRV(v);
    {
        HV *n = newHV();
        (void)hv_store(h, k, (I32)strlen(k), newRV_noinc((SV *)n), 0);
        return n;
    }
}

/* strip a single trailing '/' from a fresh copy of an SV's string */
static SV *app_strip_slash(pTHX_ SV *sv) {
    STRLEN l;
    const char *p = SvOK(sv) ? SvPV_const(sv, l) : "";
    if (!SvOK(sv)) l = 0;
    if (l && p[l - 1] == '/') l--;
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
            av_push(pair, (v && SvOK(v)) ? newSVsv(v)
                                         : newRV_noinc((SV *)newHV()));
            av_push(out, newRV_noinc((SV *)pair));
        }
    }
    else if (SvROK(node) && SvTYPE(SvRV(node)) == SVt_PVAV) {
        AV *a = (AV *)SvRV(node); SSize_t i, n = av_len(a) + 1;
        for (i = 0; i < n; i++) {
            SV **ep = av_fetch(a, i, 0);
            SV *el = (ep && *ep) ? *ep : &PL_sv_undef;
            AV *pair = newAV();
            if (SvROK(el) && SvTYPE(SvRV(el)) == SVt_PVAV) {
                AV *ea = (AV *)SvRV(el);
                SV **k = av_fetch(ea, 0, 0), **v = av_fetch(ea, 1, 0);
                av_push(pair, newSVsv((k && *k) ? *k : &PL_sv_undef));
                av_push(pair, (v && *v && SvOK(*v)) ? newSVsv(*v)
                                                    : newRV_noinc((SV *)newHV()));
            }
            else if (SvROK(el) && SvTYPE(SvRV(el)) == SVt_PVHV) {
                HV *eh = (HV *)SvRV(el); HE *he;
                hv_iterinit(eh);
                if ((he = hv_iternext(eh))) {
                    SV *v = hv_iterval(eh, he);
                    av_push(pair, newSVsv(hv_iterkeysv(he)));
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
static void app_call_list(pTHX_ SV *self, const char *meth, AV *args) {
    SSize_t n = av_len(args) + 1, i;
    SV **argv, *r;
    Newx(argv, n > 0 ? n : 1, SV *);
    for (i = 0; i < n; i++) {
        SV **e = av_fetch(args, i, 0);
        argv[i] = (e && *e) ? *e : &PL_sv_undef;
    }
    r = pcx_call_meth(aTHX_ self, meth, argv, (int)n, 0);
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

    if (!(*target && SvROK(*target) && SvTYPE(SvRV(*target)) == SVt_PVHV))
        return;
    spec = (HV *)SvRV(*target);

    if (opts && *opts && SvOK(*opts))
        croak("Punk: %s %s takes its options either inside the hashref or "
              "after the target, not both",
              what, SvOK(path) ? SvPV_nolen(path) : "(no path)");

    cb = hv_fetchs(spec, "cb", 0);
    if (!(cb && *cb && SvOK(*cb)))
        croak("Punk: %s %s has options but no `cb` - a route needs a handler "
              "(a coderef or 'Controller#method')",
              what, SvOK(path) ? SvPV_nolen(path) : "(no path)");

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
        if (kl == 2 && memEQ(k, "cb", 2)) continue;
        (void)hv_store(o, k, (I32)kl, newSVsv(hv_iterval(spec, he)), 0);
    }

    /* the target LAST: it aliases into the spec we have just finished
     * reading, and reassigning it first would be reading a freed hashref if
     * the caller held no other reference */
    *target = sv_2mortal(newSVsv(*cb));
    if (opts) *opts = sv_2mortal(newRV_noinc((SV *)o));
    else      SvREFCNT_dec((SV *)o);
}

#endif /* PUNK_APP_H */
