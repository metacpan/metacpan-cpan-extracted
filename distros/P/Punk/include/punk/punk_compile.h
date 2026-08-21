/* punk_compile.h - Punk::App's boot compiler, in C.
 *
 * to_app calls compile(): it resolves and freezes everything the registrar
 * accumulated into the `state` hash punk_serve.h reads, and returns the PSGI
 * app. The app, the docs targets, the boot-time target resolver and the
 * nonblocking Future chain are all real closures - built here with the magic-CV
 * primitive from punk_static.h (punk_closure / punk_clos_cap), so nothing on
 * this path is Perl. lib/Punk/App.pm is documentation only.
 *
 * Must be included after punk_static.h (the closure primitive), punk_serve.h
 * (punk_serve / punk_finish_c / punk_handle_error) and punk_app.h.
 */

#ifndef PUNK_COMPILE_H
#define PUNK_COMPILE_H

/* ---- closures ------------------------------------------------------------- */

/* the PSGI app: capture [ $state ]; body is punk_serve($state, $env). */
XS_INTERNAL(pc_app_cb);
XS_INTERNAL(pc_app_cb) {
    dXSARGS;
    AV *cap = punk_clos_cap(aTHX_ cv);
    SV *state;
    if (!cap || items < 1) XSRETURN_EMPTY;
    state = *av_fetch(cap, 0, 0);
    if (!SvROK(ST(0)) || SvTYPE(SvRV(ST(0))) != SVt_PVHV)
        croak("Punk: the app takes a PSGI env hashref");
    {
        HV *st  = (HV *)SvRV(state);
        HV *env = (HV *)SvRV(ST(0));
        SV *out;
        /* A preflight is answered here, before routing: OPTIONS on a path with
         * no OPTIONS route would otherwise be the router's 405. */
        out = pco_preflight(aTHX_ st, env);
        if (!out) {
            out = punk_serve(aTHX_ st, env);
            /* and the response is decorated here rather than in an
             * after-dispatch hook, because 404s and 405s never reach one */
            pco_decorate(aTHX_ st, env, &out);
        }
        /* security headers go on outside the branch, so the preflight 204
         * carries the policy too */
        phd_decorate(aTHX_ st, env, &out);
        ST(0) = sv_2mortal(out);
    }
    XSRETURN(1);
}

/* a docs route target: capture [ $response ]; body is $response->() (the
 * matched-route call passes $c, which the thunk ignores). */
XS_INTERNAL(pc_docs_cb);
XS_INTERNAL(pc_docs_cb) {
    dXSARGS;
    AV *cap = punk_clos_cap(aTHX_ cv);
    SV *resp = cap ? *av_fetch(cap, 0, 0) : &PL_sv_undef;
    SV *out;
    int count;
    PERL_UNUSED_VAR(items);
    ENTER; SAVETMPS;
    PUSHMARK(SP); PUTBACK;
    count = call_sv(resp, G_SCALAR);
    SPAGAIN;
    out = count > 0 ? newSVsv(POPs) : newSV(0);
    PUTBACK; FREETMPS; LEAVE;
    ST(0) = sv_2mortal(out);
    XSRETURN(1);
}

/* the boot-time resolver handed to the router and api mounts: capture
 * [ $self ]; body is $self->_resolve_target($target, $what). */
XS_INTERNAL(pc_resolve_cb);
XS_INTERNAL(pc_resolve_cb) {
    dXSARGS;
    AV *cap = punk_clos_cap(aTHX_ cv);
    SV *self = cap ? *av_fetch(cap, 0, 0) : &PL_sv_undef;
    SV *argv[2], *r;
    argv[0] = items > 0 ? ST(0) : &PL_sv_undef;
    argv[1] = items > 1 ? ST(1) : &PL_sv_undef;
    r = pcx_call_meth(aTHX_ self, "_resolve_target", argv, 2, 1);
    ST(0) = r ? sv_2mortal(r) : &PL_sv_undef;
    XSRETURN(1);
}

/* ---- target resolution ---------------------------------------------------- */

/* class->can(method) with inheritance (a ->can without the call) */
static CV *pc_class_can(pTHX_ const char *class, STRLEN cl, const char *meth) {
    HV *stash = gv_stashpvn(class, cl, 0);
    GV *gv;
    if (!stash) return NULL;
    gv = gv_fetchmethod_autoload(stash, meth, 0);
    return gv ? GvCV(gv) : NULL;
}

/* $self->_resolve_target($target, $what): a coderef passes through; a
 * 'Controller#method' string resolves (loading the class if need be) to the
 * method coderef. Returns it (+1) or croaks. */
static SV *pc_resolve_target(pTHX_ SV *self, SV *target, SV *whatsv) {
    HV *h = app_hv(aTHX_ self);
    const char *what = SvOK(whatsv) ? SvPV_nolen(whatsv) : K_TARGET;
    const char *ts, *method;
    STRLEN tl, metl, i, cll;
    const char *hash = NULL;
    SV *classsv, *caller, *ns;
    STRLEN cl2; const char *classname;
    CV *cvp;

    if (SvROK(target) && SvTYPE(SvRV(target)) == SVt_PVCV)
        return newSVsv(target);
    if (!SvOK(target))
        croak("Punk: %s must be a coderef or 'Controller#method', got undef",
              what);
    ts = SvPV_const(target, tl);
    for (i = tl; i > 0; i--) if (ts[i - 1] == '#') { hash = ts + i - 1; break; }
    method = hash ? hash + 1 : NULL;
    metl = hash ? (STRLEN)(ts + tl - method) : 0;
    if (hash && metl)
        for (i = 0; i < metl; i++)
            if (!isWORDCHAR(method[i])) { hash = NULL; break; }
    if (!hash || !metl)
        croak("Punk: %s must be a coderef or 'Controller#method', got '%s'",
              what, ts);

    cll = (STRLEN)(hash - ts);
    classsv = newSVpvn(ts, cll);
    sv_2mortal(classsv);
    caller = app_get(aTHX_ h, K_CALLER);
    ns = sv_2mortal(newSVpvf("%s" PK_NS_CONTROLLER, caller ? SvPV_nolen(caller) : ""));
    if (!(cll >= SvCUR(ns) && memEQ(ts, SvPVX(ns), SvCUR(ns)))) {
        SV *full = newSVsv(ns);
        sv_catsv(full, classsv);
        classsv = sv_2mortal(full);
    }
    classname = SvPV_const(classsv, cl2);
    {
        SV *methsv = sv_2mortal(newSVpvn(method, metl));
        const char *methname = SvPV_nolen(methsv);
        cvp = pc_class_can(aTHX_ classname, cl2, methname);
        if (!cvp) {
            SV *req = sv_2mortal(newSVpvf("require %s; 1;", classname));
            eval_sv(req, G_SCALAR | G_EVAL);
            if (SvTRUE(ERRSV)) {
                HV *st2 = gv_stashpvn(classname, cl2, 0);
                if (!(st2 && HvUSEDKEYS(st2)))
                    croak("Punk: %s names '%s' but %s does not load: %s",
                          what, ts, classname, SvPV_nolen(ERRSV));
            }
            cvp = pc_class_can(aTHX_ classname, cl2, methname);
        }
        if (!cvp)
            croak("Punk: %s names '%s' but %s has no method '%s'",
                  what, ts, classname, methname);
    }
    return newRV_inc((SV *)cvp);
}

/* ---- context class -------------------------------------------------------- */

/* Build (once) the caller's ::_Context subclass of Punk::Context and install
 * the registered helpers as methods on it. Returns the class name (+1). */
static SV *pc_context_class(pTHX_ SV *self) {
    HV *h = app_hv(aTHX_ self);
    SV *caller = app_get(aTHX_ h, K_CALLER);
    SV *classsv = newSVpvf("%s" PK_SFX_CONTEXT, caller ? SvPV_nolen(caller) : "");
    STRLEN cl; const char *class = SvPV_const(classsv, cl);
    SV **defd = hv_fetchs(h, K_CTX_DEFINED, 0);
    HV *helpers; AV *keys; SSize_t i, n;

    if (!(defd && *defd && SvTRUE(*defd))) {
        SV *isaname = sv_2mortal(newSVpvf("%s::ISA", class));
        AV *isa = get_av(SvPV_nolen(isaname), GV_ADD);
        av_push(isa, newSVpvs(PK_CONTEXT));
        (void)hv_stores(h, K_CTX_DEFINED, newSViv(1));
    }
    helpers = app_hash(aTHX_ h, K_HELPERS);
    keys = app_sorted_keys(aTHX_ helpers);
    n = av_len(keys) + 1;
    for (i = 0; i < n; i++) {
        SV **kp = av_fetch(keys, i, 0);
        STRLEN kl; const char *k = SvPV_const(*kp, kl);
        SV **rec = hv_fetch(helpers, k, (I32)kl, 0);
        SV **code = (rec && *rec && SvROK(*rec))
                    ? hv_fetchs((HV *)SvRV(*rec), K_CODE, 0) : NULL;
        if (code && *code) {
            SV *gvname = sv_2mortal(newSVpvf("%s::%s", class, k));
            GV *gv = gv_fetchsv(gvname, GV_ADD, SVt_PVCV);
            sv_setsv((SV *)gv, *code);       /* *{class::name} = $code */
        }
    }
    return classsv;
}

/* ---- models --------------------------------------------------------------- */

/* Load every ${ns}*.pm across @INC; push the bare names onto out. */
static void pc_discover_namespace(pTHX_ SV *ns_sv, AV *out) {
    STRLEN nsl; const char *nss = SvPV_const(ns_sv, nsl);
    SV *rel = sv_2mortal(newSVpvn(nss, nsl));
    HV *seen = (HV *)sv_2mortal((SV *)newHV());
    AV *inc = GvAV(PL_incgv);
    SSize_t i, n;
    char *rp; STRLEN j, rl;

    /* rel = ns; s/::\z//; s{::}{/}g */
    if (SvCUR(rel) >= 2) {
        rp = SvPVX(rel);
        if (rp[SvCUR(rel) - 1] == ':' && rp[SvCUR(rel) - 2] == ':')
            SvCUR_set(rel, SvCUR(rel) - 2);
    }
    rp = SvPVX(rel); rl = SvCUR(rel);
    {
        SV *slashed = sv_2mortal(newSVpvs(""));
        for (j = 0; j < rl; j++) {
            if (rp[j] == ':' && j + 1 < rl && rp[j + 1] == ':') {
                sv_catpvs(slashed, "/"); j++;
            }
            else sv_catpvn(slashed, rp + j, 1);
        }
        rel = slashed;
    }

    n = inc ? av_len(inc) + 1 : 0;
    for (i = 0; i < n; i++) {
        SV **ip = av_fetch(inc, i, 0);
        SV *dir; DIR *dh; Direntry_t *de; AV *ents; SSize_t ei, en;
        if (!ip || !*ip || SvROK(*ip) || !SvOK(*ip)) continue;
        dir = sv_2mortal(newSVsv(*ip));
        sv_catpvs(dir, "/"); sv_catsv(dir, rel);
        dh = PerlDir_open(SvPV_nolen(dir));
        if (!dh) continue;
        ents = (AV *)sv_2mortal((SV *)newAV());
        while ((de = PerlDir_read(dh))) av_push(ents, newSVpv(de->d_name, 0));
        PerlDir_close(dh);
        en = av_len(ents) + 1;
        if (en > 1) sortsv(AvARRAY(ents), (STRLEN)en, Perl_sv_cmp);
        for (ei = 0; ei < en; ei++) {
            SV **ep = av_fetch(ents, ei, 0);
            STRLEN el; const char *es = SvPV_const(*ep, el);
            STRLEN b; int ok;
            SV *name, *class;
            if (el <= 3 || !(es[el-3]=='.' && es[el-2]=='p' && es[el-1]=='m'))
                continue;
            ok = el - 3 > 0;
            for (b = 0; b < el - 3; b++) if (!isWORDCHAR(es[b])) { ok = 0; break; }
            if (!ok) continue;
            name  = sv_2mortal(newSVpvn(es, el - 3));
            class = sv_2mortal(newSVsv(ns_sv)); sv_catsv(class, name);
            if (hv_exists_ent(seen, class, 0)) continue;
            (void)hv_store_ent(seen, class, PUNK_SET_TRUE, 0);
            if (!pc_class_can(aTHX_ SvPVX(class), SvCUR(class),
                              "_punk_model_meta")) {
                /* by module name, not by the path the scan found: a
                 * path-form require of "lib/..." is @INC-searched too and
                 * misses when the entry that held the file is relative */
                SV *req = sv_2mortal(newSVpvf("require %s; 1;",
                                              SvPV_nolen(class)));
                eval_sv(req, G_SCALAR | G_EVAL);
                if (SvTRUE(ERRSV))
                    croak("Punk: model %s failed to load: %s",
                          SvPV_nolen(class), SvPV_nolen(ERRSV));
            }
            av_push(out, newSVsv(name));
        }
    }
}

/* Resolve the registered + auto-discovered model names to classes, checking
 * each is a Punk::Model with a table. Fills $self->{models_compiled}. */
static void pc_compile_models(pTHX_ SV *self) {
    HV *h = app_hv(aTHX_ self);
    SV *caller = app_get(aTHX_ h, K_CALLER);
    SV *ns = sv_2mortal(newSVpvf("%s" PK_NS_MODEL, caller ? SvPV_nolen(caller) : ""));
    AV *names = (AV *)sv_2mortal((SV *)newAV());
    AV *models = app_av(aTHX_ h, K_MODELS);
    SV **autop = hv_fetchs(h, K_MODEL_AUTO, 0);
    SSize_t i, n = av_len(models) + 1;
    int have_named = (n > 0), autoflag;
    HV *reg;

    for (i = 0; i < n; i++) {
        SV **e = av_fetch(models, i, 0);
        if (e && *e) av_push(names, newSVsv(*e));
    }
    autoflag = (autop && *autop && SvOK(*autop)) ? (SvTRUE(*autop) ? 1 : 0)
                                                 : !have_named;
    if (autoflag) {
        HV *stash;
        STRLEN nsl2 = SvCUR(ns);
        pc_discover_namespace(aTHX_ ns, names);
        /* plus any ${ns}* already in the symbol table that isa Punk::Model -
         * gv_stashpvn wants the bare package name, so the namespace's
         * trailing '::' comes off first (with it, the lookup misses and
         * in-memory model classes were silently never discovered) */
        if (nsl2 >= 2 && SvPVX(ns)[nsl2 - 1] == ':'
                      && SvPVX(ns)[nsl2 - 2] == ':')
            nsl2 -= 2;
        stash = gv_stashpvn(SvPVX(ns), nsl2, 0);
        if (stash) {
            HE *he; AV *syms = (AV *)sv_2mortal((SV *)newAV()); SSize_t si, sn;
            hv_iterinit(stash);
            while ((he = hv_iternext(stash))) {
                STRLEN kl; const char *k = HePV(he, kl);
                if (kl >= 3 && k[kl-1] == ':' && k[kl-2] == ':')
                    av_push(syms, newSVpvn(k, kl - 2));
            }
            sn = av_len(syms) + 1;
            if (sn > 1) sortsv(AvARRAY(syms), (STRLEN)sn, Perl_sv_cmp);
            for (si = 0; si < sn; si++) {
                SV **symp = av_fetch(syms, si, 0);
                SV *class = sv_2mortal(newSVsv(ns));
                sv_catsv(class, *symp);
                if (sv_derived_from(sv_2mortal(newSVsv(class)), PK_MODEL))
                    av_push(names, newSVsv(*symp));
            }
        }
    }
    if (av_len(names) < 0) return;

    (void)pk_require_once(aTHX_ PK_MODEL, TRUE);
    reg = newHV();
    n = av_len(names) + 1;
    for (i = 0; i < n; i++) {
        SV **np = av_fetch(names, i, 0);
        STRLEN nl; const char *nm = SvPV_const(*np, nl);
        SV *class; STRLEN cl; const char *cs; SV *meta;
        if (hv_exists(reg, nm, (I32)nl)) continue;
        if (memchr(nm, ':', nl))
            class = sv_2mortal(newSVsv(*np));
        else { class = sv_2mortal(newSVsv(ns)); sv_catsv(class, *np); }
        cs = SvPV_const(class, cl);
        if (!pc_class_can(aTHX_ cs, cl, "_punk_model_meta")) {
            SV *req = sv_2mortal(newSVpvf("require %s; 1;", cs));
            eval_sv(req, G_SCALAR | G_EVAL);
            if (SvTRUE(ERRSV))
                croak("Punk: model '%s' (%s) failed to load: %s",
                      nm, cs, SvPV_nolen(ERRSV));
        }
        if (!sv_derived_from(class, PK_MODEL))
            croak("Punk: model '%s' (%s) does not use Punk::Model", nm, cs);
        meta = pcx_call_meth(aTHX_ class, "_punk_model_meta", NULL, 0, 1);
        if (!(meta && SvROK(meta) && SvTYPE(SvRV(meta)) == SVt_PVHV)) {
            if (meta) SvREFCNT_dec(meta);
            croak("Punk: model '%s' (%s) declares no table", nm, cs);
        }
        SvREFCNT_dec(meta);
        (void)hv_store(reg, nm, (I32)nl, newSVsv(class), 0);
    }
    (void)hv_stores(h, K_MODELS_C, newRV_noinc((SV *)reg));
}

/* the backend options for a model class: its selected database, or {} for the
 * (possibly unconfigured) default. */
static SV *pc_db_opts_for(pTHX_ SV *self, SV *classsv) {
    HV *h = app_hv(aTHX_ self);
    HV *dbs = app_hash(aTHX_ h, K_DATABASES);
    SV *meta = pcx_call_meth(aTHX_ classsv, "_punk_model_meta", NULL, 0, 1);
    const char *wname = K_DEFAULT; STRLEN wl = 7;
    SV **opts; SV *ret;
    if (meta && SvROK(meta) && SvTYPE(SvRV(meta)) == SVt_PVHV) {
        SV **d = hv_fetchs((HV *)SvRV(meta), "database", 0);
        if (d && *d && SvTRUE(*d)) wname = SvPV_const(*d, wl);
    }
    opts = hv_fetch(dbs, wname, (I32)wl, 0);
    if (opts && *opts && SvOK(*opts)) ret = newSVsv(*opts);
    else if (!(wl == 7 && memEQ(wname, K_DEFAULT, 7)))
        croak("Punk: model '%s' selects database '%s', which no database "
              "keyword configured", SvPV_nolen(classsv), wname);
    else ret = newRV_noinc((SV *)newHV());
    if (meta) SvREFCNT_dec(meta);
    return ret;
}

/* ---- docs (Open::API::UI) into plain GET route records -------------------- */

/* Materialise the `docs` records into GET route records (target a closure over
 * the UI's finished-triplet thunk), croaking if a docs path collides with a
 * mounted spec's operation. api_mounts is the compiled [{mount,prefix,len}]. */
static AV *pc_docs_routes(pTHX_ SV *self, AV *api_mounts) {
    HV *h = app_hv(aTHX_ self);
    AV *extra = (AV *)sv_2mortal((SV *)newAV());
    SV **docsp = hv_fetchs(h, K_DOCS, 0);
    AV *docs = (docsp && *docsp && SvROK(*docsp)) ? (AV *)SvRV(*docsp) : NULL;
    SSize_t i, n = docs ? av_len(docs) + 1 : 0;
    SSize_t amn = api_mounts ? av_len(api_mounts) + 1 : 0;

    for (i = 0; i < n; i++) {
        SV **rp = av_fetch(docs, i, 0);
        HV *rec = (rp && *rp && SvROK(*rp)) ? (HV *)SvRV(*rp) : NULL;
        SV *mount, *path, *opts, *api, *ui, *routes, **x;
        AV *nav, *rl; SSize_t ri, rn; int nn, k; SV **nargv;
        if (!rec) continue;
        x = hv_fetchs(rec, K_MOUNT, 0); mount = (x && *x && SvOK(*x)) ? *x : NULL;
        x = hv_fetchs(rec, K_PATH, 0);  path  = (x && *x) ? *x : &PL_sv_undef;
        x = hv_fetchs(rec, K_OPTS, 0);  opts  = (x && *x) ? *x : NULL;
        if (!mount) {
            HV *m0h; SV **mm;
            if (amn < 1)
                croak("Punk: docs needs an api mount (none registered)");
            if (amn > 1)
                croak("Punk: docs needs the mount named (several apis "
                      "are registered)");
            m0h = (HV *)SvRV(*av_fetch(api_mounts, 0, 0));
            mm = hv_fetchs(m0h, K_MOUNT, 0);
            mount = (mm && *mm) ? *mm : NULL;
        }
        if (!pk_require_once(aTHX_ PK_OA_UI, FALSE))
            croak("Punk: the docs keyword needs Open::API::UI - Open::API "
                  "0.03+ with Template::Stencil and Markdown::Simple - and "
                  "it failed to load: %s", SvPV_nolen(ERRSV));
        api = sv_2mortal(pcx_call_meth(aTHX_ mount, K_API, NULL, 0, 1));
        nav = (AV *)sv_2mortal((SV *)newAV());
        av_push(nav, newSVpvs(K_API));  av_push(nav, newSVsv(api));
        av_push(nav, newSVpvs(K_PATH)); av_push(nav, newSVsv(path));
        /* The docs UI does a double-submit: it reads the mirror cookie and
         * sends the header. Hand it the real names when csrf is on, so
         * try-it-out can write; 0 (off) when it is not. */
        av_push(nav, newSVpvs(K_CSRF));
        {
            SV **cc = hv_fetchs(h, K_CSRF, 0);
            if (cc && *cc && SvROK(*cc) && SvTYPE(SvRV(*cc)) == SVt_PVHV) {
                HV *cfg = (HV *)SvRV(*cc), *ui = newHV();
                static const char *const pass[] = { "header", "cookie", NULL };
                int pi;
                for (pi = 0; pass[pi]; pi++) {
                    SV **e = hv_fetch(cfg, pass[pi], (I32)strlen(pass[pi]), 0);
                    if (e && *e && SvOK(*e))
                        (void)hv_store(ui, pass[pi], (I32)strlen(pass[pi]),
                                       newSVsv(*e), 0);
                }
                av_push(nav, newRV_noinc((SV *)ui));
            }
            else av_push(nav, newSViv(0));
        }
        if (opts && SvROK(opts) && SvTYPE(SvRV(opts)) == SVt_PVHV) {
            HV *oh = (HV *)SvRV(opts); HE *oe;
            hv_iterinit(oh);
            while ((oe = hv_iternext(oh))) {
                av_push(nav, newSVsv(hv_iterkeysv(oe)));
                av_push(nav, newSVsv(hv_iterval(oh, oe)));
            }
        }
        nn = (int)(av_len(nav) + 1);
        Newx(nargv, nn > 0 ? nn : 1, SV *);
        for (k = 0; k < nn; k++) nargv[k] = *av_fetch(nav, k, 0);
        ui = sv_2mortal(pcx_call_meth(aTHX_ sv_2mortal(newSVpvs(PK_OA_UI)),
                                      "new", nargv, nn, 1));
        Safefree(nargv);
        routes = sv_2mortal(pcx_call_meth(aTHX_ ui, "routes", NULL, 0, 1));
        rl = (routes && SvROK(routes) && SvTYPE(SvRV(routes)) == SVt_PVAV)
             ? (AV *)SvRV(routes) : NULL;
        rn = rl ? av_len(rl) + 1 : 0;
        for (ri = 0; ri < rn; ri++) {
            SV **rr = av_fetch(rl, ri, 0);
            HV *r = (rr && *rr && SvROK(*rr)) ? (HV *)SvRV(*rr) : NULL;
            SV **rpathp, **respp; STRLEN rpl; const char *rps;
            HV *route; SV *target; AV *dcap; SSize_t mi;
            if (!r) continue;
            rpathp = hv_fetchs(r, K_PATH, 0);
            rps = SvPV_const(*rpathp, rpl);
            for (mi = 0; mi < amn; mi++) {
                HV *mh = (HV *)SvRV(*av_fetch(api_mounts, mi, 0));
                SV **pfp = hv_fetchs(mh, K_PREFIX, 0);
                SV **lp  = hv_fetchs(mh, K_LEN, 0);
                SV **mmp = hv_fetchs(mh, K_MOUNT, 0);
                STRLEN pfl; const char *pf;
                IV len = (lp && *lp) ? SvIV(*lp) : 0;
                SV *sub, *mapi, *firsthit = NULL; int mc;
                if (pfp && *pfp && SvOK(*pfp)) pf = SvPV_const(*pfp, pfl);
                else { pf = ""; pfl = 0; }
                if (!(rpl >= pfl && memEQ(rps, pf, pfl))) continue;
                sub = sv_2mortal((rpl > (STRLEN)len)
                                 ? newSVpvn(rps + len, rpl - len)
                                 : newSVpvs("/"));
                mapi = sv_2mortal(pcx_call_meth(aTHX_ (mmp && *mmp) ? *mmp
                                  : &PL_sv_undef, K_API, NULL, 0, 1));
                {
                    dSP;
                    ENTER; SAVETMPS;
                    PUSHMARK(SP); EXTEND(SP, 3);
                    PUSHs(mapi);
                    PUSHs(sv_2mortal(newSVpvs("GET")));
                    PUSHs(sub);
                    PUTBACK;
                    mc = call_method("match", G_ARRAY);
                    SPAGAIN;
                    if (mc > 0) firsthit = SvREFCNT_inc(SP[-mc + 1]);
                    SP -= mc; PUTBACK;
                    FREETMPS; LEAVE;
                }
                if (mc > 0) {
                    SV *msg = sv_2mortal(newSVpvf(
                        "Punk: docs path '%.*s' is declared by the mounted "
                        "spec", (int)rpl, rps));
                    if (firsthit && SvOK(firsthit))
                        sv_catpvf(msg, " (operation '%s')", SvPV_nolen(firsthit));
                    sv_catpvs(msg, "; choose another docs path");
                    if (firsthit) SvREFCNT_dec(firsthit);
                    croak("%s", SvPV_nolen(msg));
                }
                if (firsthit) SvREFCNT_dec(firsthit);
            }
            respp = hv_fetchs(r, K_RESPONSE, 0);
            dcap = newAV();
            av_push(dcap, newSVsv((respp && *respp) ? *respp : &PL_sv_undef));
            target = punk_closure(aTHX_ pc_docs_cb, dcap);
            route = newHV();
            (void)hv_stores(route, K_METHOD, newSVpvs("GET"));
            (void)hv_stores(route, K_PATH,   newSVsv(*rpathp));
            (void)hv_stores(route, K_TARGET, target);
            (void)hv_stores(route, K_GUARDS, newRV_noinc((SV *)newAV()));
            av_push(extra, newRV_noinc((SV *)route));
        }
    }
    return extra;
}

/* ---- longest-prefix ordering ---------------------------------------------- */

static IV pc_len_of(pTHX_ SV *el) {
    if (SvROK(el) && SvTYPE(SvRV(el)) == SVt_PVHV) {
        SV **l = hv_fetchs((HV *)SvRV(el), K_LEN, 0);
        if (l && *l && SvOK(*l)) return SvIV(*l);
    }
    return 0;
}
static I32 pc_cmp_len_desc(pTHX_ SV *a, SV *b) {
    return (I32)(pc_len_of(aTHX_ b) - pc_len_of(aTHX_ a));
}

/* ---- the nonblocking Future chain ($ret->then(done, fail)) ---------------- *
 * capture [ $c, $on_error, $method, \@after ]; the deliver/handle-error work
 * is punk_context.h / punk_serve.h C, exactly the blocking path's. */

/* $app->env - the config's env, else PUNK_ENV, else production. Mortal. */
static SV *pc_app_env(pTHX_ SV *self) {
    dSP;
    int count;
    SV *out;
    ENTER; SAVETMPS;
    PUSHMARK(SP); EXTEND(SP, 1); PUSHs(self); PUTBACK;
    count = call_method("env", G_SCALAR);
    SPAGAIN;
    out = count > 0 ? newSVsv(POPs) : newSVpvs("production");
    PUTBACK; FREETMPS; LEAVE;
    return sv_2mortal(out);
}

static int pc_is_head(pTHX_ SV *methsv) {
    STRLEN ml; const char *m = SvOK(methsv) ? SvPV_const(methsv, ml) : "GET";
    if (!SvOK(methsv)) ml = 3;
    return (ml == 4 && memEQ(m, "HEAD", 4));
}
static AV *pc_after_of(pTHX_ SV *ref) {
    return (ref && SvROK(ref) && SvTYPE(SvRV(ref)) == SVt_PVAV)
           ? (AV *)SvRV(ref) : NULL;
}

/* A `then` callback must hand back a FUTURE, not the value it computed.
 * Future's own sequencing enforces that - "Expected __ANON__(...) to return
 * a Future" - and older releases enforce it strictly, so returning a raw
 * triplet here fails on any perl whose Future predates the relaxation.
 * Reported by CPAN Testers against 0.16 on perls 5.20, 5.22 and 5.24; it
 * passed locally only because this box's Future no longer checks.
 *
 * The wrap is conditional because the two future flavours differ on this:
 * `Future->done($v)` is a class method that mints a completed future, while
 * Punk::Future's `done` is an instance method (its class-level constructor
 * is done_future) and its own `then` accepts the value directly. So the
 * capture carries a flag set at chain time from `$ret->isa('Future')`, and
 * only that path is wrapped. Slot 4. */
static int pc_ff_flag(pTHX_ AV *cap, int slot) {
    SV **wp = av_fetch(cap, slot, 0);
    return (wp && *wp && SvTRUE(*wp)) ? 1 : 0;
}

static SV *pc_ff_wrap(pTHX_ int wrap, SV *resp) {
    SV *argv[1], *f;
    if (!wrap) return resp;                            /* Punk::Future path */
    argv[0] = sv_2mortal(resp);
    f = pcx_call_meth(aTHX_ sv_2mortal(newSVpvs("Future")), "done", argv, 1, 1);
    return f ? f : newSVsv(argv[0]);
}

/* The streaming callbacks answer through the responder and have no value to
 * carry, but they are still `then` callbacks and still owe a future back. */
static SV *pc_ff_done_empty(pTHX) {
    SV *f = pcx_call_meth(aTHX_ sv_2mortal(newSVpvs("Future")), "done",
                          NULL, 0, 1);
    return f ? f : newSV(0);
}

XS_INTERNAL(pc_ff_done_cb);
XS_INTERNAL(pc_ff_done_cb) {
    dXSARGS;
    AV *cap = punk_clos_cap(aTHX_ cv);
    SV *c   = *av_fetch(cap, 0, 0);
    int hd  = pc_is_head(aTHX_ *av_fetch(cap, 2, 0));
    AV *aft = pc_after_of(aTHX_ *av_fetch(cap, 3, 0));
    SV *val = items > 0 ? ST(0) : &PL_sv_undef;
    ST(0) = sv_2mortal(pc_ff_wrap(aTHX_ pc_ff_flag(aTHX_ cap, 4),
                punk_deliver(aTHX_ c, val, hd, aft)));
    XSRETURN(1);
}

XS_INTERNAL(pc_ff_fail_cb);
XS_INTERNAL(pc_ff_fail_cb) {
    dXSARGS;
    AV *cap = punk_clos_cap(aTHX_ cv);
    SV *c   = *av_fetch(cap, 0, 0);
    SV *oe  = *av_fetch(cap, 1, 0);
    int hd  = pc_is_head(aTHX_ *av_fetch(cap, 2, 0));
    AV *aft = pc_after_of(aTHX_ *av_fetch(cap, 3, 0));
    SV *err = (items > 0 && SvOK(ST(0))) ? ST(0) : sv_2mortal(newSVpvs("failed"));
    SV *resp = punk_handle_error(aTHX_ c, err, SvOK(oe) ? oe : NULL);
    /* the same contract as the done side: a `then` callback returns a
     * future, not the value. A failure that answers with a 500 triplet is
     * still a SUCCESSFUL sequencing step - the error was handled - so this
     * wraps with done, not fail. */
    ST(0) = sv_2mortal(pc_ff_wrap(aTHX_ pc_ff_flag(aTHX_ cap, 4),
                punk_deliver(aTHX_ c, resp, hd, aft)));
    SvREFCNT_dec(resp);
    XSRETURN(1);
}

/* ---- the streaming variant: a Future behind a psgi.streaming responder ----
 *
 * A raw Future handed back as the PSGI response is a shape only Hyperman
 * understands, and anything standing between Punk and the server - the Lint
 * and AccessLog middleware plackup adds in its development default, or this
 * application's own `middleware` - dies on it. When the server advertises
 * psgi.streaming, the future rides inside the standard delayed response
 * instead: a coderef every middleware passes through, resolving to the same
 * triplet through the same deliver path. */

/* Hand `resp` to the responder - or, when the future resolved to a streaming
 * coderef of its own (an SSE body, say), hand the responder to it. */
static void pc_respond(pTHX_ SV *responder, SV *resp) {
    dSP;
    int stream = SvROK(resp) && SvTYPE(SvRV(resp)) == SVt_PVCV;
    ENTER; SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(stream ? responder : resp);
    PUTBACK;
    call_sv(stream ? resp : responder, G_VOID | G_DISCARD | G_EVAL);
    if (SvTRUE(ERRSV))
        warn("Punk: responder failed: %" SVf, SVfARG(ERRSV));
    FREETMPS; LEAVE;
}

/* cap: [c, on_error, method, after, responder] - the pc_ff_* layout plus the
 * responder the server handed the delayed response. */
XS_INTERNAL(pc_ffs_done_cb);
XS_INTERNAL(pc_ffs_done_cb) {
    dXSARGS;
    AV *cap = punk_clos_cap(aTHX_ cv);
    SV *c   = *av_fetch(cap, 0, 0);
    int hd  = pc_is_head(aTHX_ *av_fetch(cap, 2, 0));
    AV *aft = pc_after_of(aTHX_ *av_fetch(cap, 3, 0));
    SV *rsp = *av_fetch(cap, 4, 0);
    SV *val = items > 0 ? ST(0) : &PL_sv_undef;
    SV *trip = punk_deliver(aTHX_ c, val, hd, aft);
    pc_respond(aTHX_ rsp, trip);
    SvREFCNT_dec(trip);
    if (pc_ff_flag(aTHX_ cap, 5)) { ST(0) = sv_2mortal(pc_ff_done_empty(aTHX)); XSRETURN(1); }
    XSRETURN(0);
}

XS_INTERNAL(pc_ffs_fail_cb);
XS_INTERNAL(pc_ffs_fail_cb) {
    dXSARGS;
    AV *cap = punk_clos_cap(aTHX_ cv);
    SV *c   = *av_fetch(cap, 0, 0);
    SV *oe  = *av_fetch(cap, 1, 0);
    int hd  = pc_is_head(aTHX_ *av_fetch(cap, 2, 0));
    AV *aft = pc_after_of(aTHX_ *av_fetch(cap, 3, 0));
    SV *rsp = *av_fetch(cap, 4, 0);
    SV *err = (items > 0 && SvOK(ST(0))) ? ST(0) : sv_2mortal(newSVpvs("failed"));
    SV *resp = punk_handle_error(aTHX_ c, err, SvOK(oe) ? oe : NULL);
    SV *trip = punk_deliver(aTHX_ c, resp, hd, aft);
    pc_respond(aTHX_ rsp, trip);
    SvREFCNT_dec(trip);
    SvREFCNT_dec(resp);
    if (pc_ff_flag(aTHX_ cap, 5)) { ST(0) = sv_2mortal(pc_ff_done_empty(aTHX)); XSRETURN(1); }
    XSRETURN(0);
}

/* The delayed response itself. cap: [c, ret, on_error, method, after];
 * called by the server (or the innermost middleware) with the responder.
 *
 * On a live Hyperman worker loop the then-chain is enough - the loop is what
 * resolves the future, and the responder fires when it does. Without one
 * (a foreign nonblocking server, a synthetic test env) nothing would ever
 * drive a pending future, so it is awaited inline - the same semantics the
 * blocking branch has always had, delivered through the responder. */
XS_INTERNAL(pc_ffs_cb);
XS_INTERNAL(pc_ffs_cb) {
    dXSARGS;
    AV *cap = punk_clos_cap(aTHX_ cv);
    SV *c   = *av_fetch(cap, 0, 0);
    SV *ret = *av_fetch(cap, 1, 0);
    SV *responder = items > 0 ? ST(0) : &PL_sv_undef;
    const hm_abi *A = punk_hm(aTHX);
    int ffs_wrap = (SvROK(ret) && sv_derived_from(ret, "Future"));
    if (A && A->cur_loop(aTHX)) {
        SV *done, *fail, *argv[2], *chained;
        AV *caps[2];
        int j;
        for (j = 0; j < 2; j++) {
            AV *icap = caps[j] = newAV();
            SV **oe = av_fetch(cap, 2, 0), **af = av_fetch(cap, 4, 0);
            av_push(icap, newSVsv(c));
            av_push(icap, (oe && SvOK(*oe)) ? newSVsv(*oe) : newSV(0));
            av_push(icap, newSVsv(*av_fetch(cap, 3, 0)));
            av_push(icap, (af && SvOK(*af)) ? newSVsv(*af)
                                            : newRV_noinc((SV *)newAV()));
            av_push(icap, newSVsv(responder));
            av_push(icap, newSViv(ffs_wrap));
        }
        done = sv_2mortal(punk_closure(aTHX_ pc_ffs_done_cb, caps[0]));
        fail = sv_2mortal(punk_closure(aTHX_ pc_ffs_fail_cb, caps[1]));
        argv[0] = done; argv[1] = fail;
        chained = pcx_call_meth(aTHX_ ret, "then", argv, 2, 1);
        /* the pending chain is held by what will resolve it */
        if (chained) SvREFCNT_dec(chained);
    }
    else {
        dSP; int count, died, hd;
        SV *got, *resp, *trip;
        SV **oe = av_fetch(cap, 2, 0);
        AV *aft = pc_after_of(aTHX_ *av_fetch(cap, 4, 0));
        ENTER; SAVETMPS;
        PUSHMARK(SP); EXTEND(SP, 1); PUSHs(ret); PUTBACK;
        count = call_method("get", G_SCALAR | G_EVAL);
        SPAGAIN;
        got = count > 0 ? SvREFCNT_inc(POPs) : &PL_sv_undef;
        PUTBACK; FREETMPS; LEAVE;
        died = SvTRUE(ERRSV) ? 1 : 0;
        hd = pc_is_head(aTHX_ *av_fetch(cap, 3, 0));
        resp = died ? punk_handle_error(aTHX_ c, ERRSV,
                          (oe && SvOK(*oe)) ? *oe : NULL)
                    : punk_coerce(aTHX_ c, got);
        trip = punk_deliver(aTHX_ c, resp, hd, aft);
        pc_respond(aTHX_ responder, trip);
        SvREFCNT_dec(trip);
        SvREFCNT_dec(resp);
        if (got != &PL_sv_undef) SvREFCNT_dec(got);
    }
    XSRETURN(0);
}

#endif /* PUNK_COMPILE_H */
