MODULE = Punk        PACKAGE = Punk::App

PROTOTYPES: DISABLE

# The boot compiler, in C (punk_compile.h). compile() freezes the registrar's
# accumulation into the state hash punk_serve.h reads and returns the PSGI app;
# the resolver, the docs targets, the app itself and the nonblocking Future
# chain are all real closures built with the magic-CV primitive.

SV *
_resolve_target(self, target, what = &PL_sv_undef)
        SV *self
        SV *target
        SV *what
    CODE:
        RETVAL = pc_resolve_target(aTHX_ self, target, what);
    OUTPUT:
        RETVAL

SV *
_context_class(self)
        SV *self
    CODE:
        RETVAL = pc_context_class(aTHX_ self);
    OUTPUT:
        RETVAL

SV *
_db_opts_for(self, class)
        SV *self
        SV *class
    CODE:
        RETVAL = pc_db_opts_for(aTHX_ self, class);
    OUTPUT:
        RETVAL

void
_compile_models(self)
        SV *self
    CODE:
        pc_compile_models(aTHX_ self);

SV *
_docs_routes(self, api_mounts)
        SV *self
        SV *api_mounts
    CODE:
    {
        AV *am = (SvROK(api_mounts) && SvTYPE(SvRV(api_mounts)) == SVt_PVAV)
                 ? (AV *)SvRV(api_mounts) : NULL;
        RETVAL = newRV_inc((SV *)pc_docs_routes(aTHX_ self, am));
    }
    OUTPUT:
        RETVAL

# The per-worker model instance: built on first use, cached until the pid
# changes (fork-safe).
SV *
model_instance(self, name)
        SV *self
        SV *name
    CODE:
    {
        HV *h = app_hv(aTHX_ self);
        STRLEN nl; const char *n = SvPV_const(name, nl);
        SV **regp = hv_fetchs(h, K_MODELS_C, 0);
        HV *reg, *cache; SV **classp, **cachep, **pidp, **inst;
        IV pid = (IV)PerlProc_getpid();
        if (!(regp && *regp && SvROK(*regp)))
            croak("Punk: no model registered - add database/model keywords");
        reg = (HV *)SvRV(*regp);
        classp = hv_fetch(reg, n, (I32)nl, 0);
        if (!(classp && *classp && SvOK(*classp))) {
            AV *keys = app_sorted_keys(aTHX_ reg);
            SV *have = sv_2mortal(newSVpvs("")); SSize_t i, m = av_len(keys) + 1;
            for (i = 0; i < m; i++) {
                if (i) sv_catpvs(have, ", ");
                sv_catsv(have, *av_fetch(keys, i, 0));
            }
            croak("Punk: no model '%s' registered (have: %s)", n,
                  SvPV_nolen(have));
        }
        cachep = hv_fetchs(h, K_MODEL_CACHE, 0);
        if (cachep && *cachep && SvROK(*cachep)) cache = (HV *)SvRV(*cachep);
        else {
            cache = newHV();
            (void)hv_stores(cache, K_PID, newSViv(-1));
            (void)hv_stores(h, K_MODEL_CACHE, newRV_noinc((SV *)cache));
        }
        pidp = hv_fetchs(cache, K_PID, 0);
        if (!(pidp && *pidp && SvIV(*pidp) == pid)) {
            hv_clear(cache);
            (void)hv_stores(cache, K_PID, newSViv(pid));
        }
        inst = hv_fetch(cache, n, (I32)nl, 0);
        if (inst && *inst && SvTRUE(*inst)) RETVAL = newSVsv(*inst);
        else {
            SV *opts = pc_db_opts_for(aTHX_ self, *classp);
            SV *argv[1], *obj;
            argv[0] = sv_2mortal(opts);
            obj = pcx_call_meth(aTHX_ *classp, "_instantiate", argv, 1, 1);
            (void)hv_store(cache, n, (I32)nl,
                           obj ? SvREFCNT_inc(obj) : newSV(0), 0);
            RETVAL = obj ? obj : newSV(0);
        }
    }
    OUTPUT:
        RETVAL

# $self->render_view($c, @args) -> the view engine's finished response.
SV *
render_view(self, ...)
        SV *self
    CODE:
    {
        HV *h = app_hv(aTHX_ self);
        SV **vc = hv_fetchs(h, K_VIEWS_C, 0);
        int nargs = items - 1, i;
        SV **argv;
        if (!(vc && *vc && SvOK(*vc)))
            croak("Punk: no view engine configured - add a views keyword");
        Newx(argv, nargs > 0 ? nargs : 1, SV *);
        for (i = 0; i < nargs; i++) argv[i] = ST(i + 1);
        RETVAL = pcx_call_meth(aTHX_ *vc, "render", argv, nargs, 1);
        Safefree(argv);
        if (!RETVAL) RETVAL = newSV(0);
    }
    OUTPUT:
        RETVAL

# $on_error->($c,$err) coerced, or the 500 default.
SV *
_handle_error(self, c, err, on_error = &PL_sv_undef)
        SV *self
        SV *c
        SV *err
        SV *on_error
    CODE:
        PERL_UNUSED_VAR(self);
        RETVAL = punk_handle_error(aTHX_ c, err, SvOK(on_error) ? on_error : NULL);
    OUTPUT:
        RETVAL

# The one Perl-shaped piece of the finish path: a handler that returned a
# Future. On a nonblocking server hand back the ->then chain (built as two
# magic-CV closures); otherwise await it and finish inline.
SV *
_finish_future(self, c, ret, on_error = &PL_sv_undef, method = &PL_sv_undef, after = &PL_sv_undef)
        SV *self
        SV *c
        SV *ret
        SV *on_error
        SV *method
        SV *after
    CODE:
    {
        AV *cav = pcx_av(aTHX_ c);
        SV *envsv = pcx_get(aTHX_ cav, PCX_ENV);
        HV *env = (envsv && SvROK(envsv)) ? (HV *)SvRV(envsv) : NULL;
        SV **nb = env ? hv_fetchs(env, "psgi.nonblocking", 0) : NULL;
        SV **st = env ? hv_fetchs(env, "psgi.streaming", 0) : NULL;
        int nonblocking = (nb && *nb && SvTRUE(*nb));
        int streaming   = (st && *st && SvTRUE(*st));
        int can_then = (SvROK(ret) && SvOBJECT(SvRV(ret))
                        && pcx_can(aTHX_ ret, "then"));
        PERL_UNUSED_VAR(self);
        if (nonblocking && can_then && streaming) {
            /* the standard delayed response: middleware between Punk and the
             * server (plackup's Lint, this app's own `middleware`) passes a
             * coderef through where a raw Future would kill the request */
            AV *cap = newAV();
            av_push(cap, newSVsv(c));
            av_push(cap, newSVsv(ret));
            av_push(cap, SvOK(on_error) ? newSVsv(on_error) : newSV(0));
            av_push(cap, newSVsv(method));
            av_push(cap, SvOK(after) ? newSVsv(after)
                                     : newRV_noinc((SV *)newAV()));
            RETVAL = punk_closure(aTHX_ pc_ffs_cb, cap);
        }
        else if (nonblocking && can_then) {
            AV *cd = newAV(), *cf = newAV();
            SV *done, *fail, *argv[2];
            int j;
            for (j = 0; j < 2; j++) {
                AV *cap = j ? cf : cd;
                av_push(cap, newSVsv(c));
                av_push(cap, SvOK(on_error) ? newSVsv(on_error) : newSV(0));
                av_push(cap, newSVsv(method));
                av_push(cap, SvOK(after) ? newSVsv(after)
                                         : newRV_noinc((SV *)newAV()));
            }
            done = sv_2mortal(punk_closure(aTHX_ pc_ff_done_cb, cd));
            fail = sv_2mortal(punk_closure(aTHX_ pc_ff_fail_cb, cf));
            argv[0] = done; argv[1] = fail;
            RETVAL = pcx_call_meth(aTHX_ ret, "then", argv, 2, 1);
            if (!RETVAL) RETVAL = &PL_sv_undef;
        }
        else {
            dSP; int count; SV *got, *resp; int died, is_head;
            AV *aft = pc_after_of(aTHX_ after);
            ENTER; SAVETMPS;
            PUSHMARK(SP); EXTEND(SP, 1); PUSHs(ret); PUTBACK;
            count = call_method("get", G_SCALAR | G_EVAL);
            SPAGAIN;
            got = count > 0 ? SvREFCNT_inc(POPs) : &PL_sv_undef;
            PUTBACK; FREETMPS; LEAVE;
            died = SvTRUE(ERRSV) ? 1 : 0;
            is_head = pc_is_head(aTHX_ method);
            resp = died ? punk_handle_error(aTHX_ c, ERRSV,
                              SvOK(on_error) ? on_error : NULL)
                        : punk_coerce(aTHX_ c, got);
            RETVAL = punk_deliver(aTHX_ c, resp, is_head, aft);
            SvREFCNT_dec(resp);
            if (got != &PL_sv_undef) SvREFCNT_dec(got);
        }
    }
    OUTPUT:
        RETVAL

# compile(): resolve and freeze everything into the state hash and return the
# PSGI app (a magic-CV closure over the state).
SV *
compile(self)
        SV *self
    CODE:
    {
        HV *h = app_hv(aTHX_ self);
        SV *caller = app_get(aTHX_ h, K_CALLER);
        AV *rcap = newAV();
        SV *resolve, *router, *xs_router, *all_recs, *ctx, *app_cv, *state_rv;
        HV *state;
        AV *api_src = app_av(aTHX_ h, K_API_MOUNTS);
        AV *api_mounts = (AV *)sv_2mortal((SV *)newAV());
        AV *state_apims = newAV();
        AV *mounts_out = newAV();
        AV *before_out = newAV(), *after_out = newAV();
        AV *docs_extra, *mount_src, *mw;
        SSize_t i, n;
        SV **x;

        av_push(rcap, newSVsv(self));
        resolve = sv_2mortal(punk_closure(aTHX_ pc_resolve_cb, rcap));

        /* api mounts: compile each, wrap as {mount,prefix,len}, order longest */
        n = api_src ? av_len(api_src) + 1 : 0;
        for (i = 0; i < n; i++) {
            SV **mp = av_fetch(api_src, i, 0);
            SV *m = (mp && *mp) ? *mp : &PL_sv_undef;
            SV *argv[2], *pfx; HV *rec;
            argv[0] = self; argv[1] = resolve;
            { SV *r = pcx_call_meth(aTHX_ m, "compile", argv, 2, 0);
              if (r) SvREFCNT_dec(r); }
            pfx = sv_2mortal(pcx_call_meth(aTHX_ m, K_PREFIX, NULL, 0, 1));
            rec = newHV();
            (void)hv_stores(rec, K_MOUNT,  newSVsv(m));
            (void)hv_stores(rec, K_PREFIX, newSVsv(pfx));
            (void)hv_stores(rec, K_LEN,
                            newSViv(SvOK(pfx) ? (IV)SvCUR(pfx) : 0));
            av_push(api_mounts, newRV_noinc((SV *)rec));
        }
        if (av_len(api_mounts) >= 0)
            sortsv(AvARRAY(api_mounts), (STRLEN)(av_len(api_mounts) + 1),
                   pc_cmp_len_desc);

        /* router: compile with the docs routes folded in; take its records */
        docs_extra = pc_docs_routes(aTHX_ self, api_mounts);
        router = app_get(aTHX_ h, K_ROUTER);
        {
            SV *argv[2];
            argv[0] = resolve;
            argv[1] = sv_2mortal(newRV_inc((SV *)docs_extra));
            xs_router = sv_2mortal(pcx_call_meth(aTHX_ router, "compile",
                                                 argv, 2, 1));
        }
        all_recs = sv_2mortal(pcx_call_meth(aTHX_ xs_router, "records",
                                            NULL, 0, 1));
        ctx = sv_2mortal(pc_context_class(aTHX_ self));

        /* websocket routes: mark the records, check the server can upgrade */
        x = hv_fetchs(h, K_WS_ROUTES, 0);
        if (x && *x && SvROK(*x) && SvTYPE(SvRV(*x)) == SVt_PVAV) {
            AV *wsr = (AV *)SvRV(*x);
            HV *wsmap = (HV *)sv_2mortal((SV *)newHV());
            AV *recs = (all_recs && SvROK(all_recs)) ? (AV *)SvRV(all_recs) : NULL;
            SSize_t wi, wn = av_len(wsr) + 1;
            int any_blocking = 0, ok;
            (void)pk_require_once(aTHX_ PK_WEBSOCKET, TRUE);
            for (wi = 0; wi < wn; wi++) {
                HV *w = (HV *)SvRV(*av_fetch(wsr, wi, 0));
                SV **pp = hv_fetchs(w, K_PATH, 0);
                SV **op = hv_fetchs(w, K_OPTS, 0);
                if (pp && *pp)
                    (void)hv_store_ent(wsmap, *pp,
                        newSVsv(op && *op ? *op : &PL_sv_undef), 0);
                if (op && *op && SvROK(*op) && SvTYPE(SvRV(*op)) == SVt_PVHV) {
                    SV **b = hv_fetchs((HV *)SvRV(*op), K_BLOCKING, 0);
                    if (b && *b && SvTRUE(*b)) any_blocking = 1;
                }
            }
            n = recs ? av_len(recs) + 1 : 0;
            for (i = 0; i < n; i++) {
                HV *rr = (HV *)SvRV(*av_fetch(recs, i, 0));
                SV **meth = hv_fetchs(rr, K_METHOD, 0);
                SV **pth = hv_fetchs(rr, K_PATH, 0);
                HE *he;
                if (!(meth && *meth && strEQ(SvPV_nolen(*meth), "GET"))) continue;
                he = pth && *pth ? hv_fetch_ent(wsmap, *pth, 0, 0) : NULL;
                if (he) (void)hv_stores(rr, K_WS, newSVsv(HeVAL(he)));
            }
            { dSP; int c2;
              PUSHMARK(SP);
              c2 = call_pv(PK_WEBSOCKET "::_hm_available", G_SCALAR);
              SPAGAIN;
              ok = c2 > 0 ? SvTRUE(TOPs) : 0;
              if (c2 > 0) (void)POPs;
              PUTBACK; }
            if (!ok && !any_blocking)
                croak("Punk: websocket routes need Hyperman 0.11 or later "
                      "(for its detach ABI), or blocking => 1 on the route "
                      "for other PSGI servers that provide psgix.io");
        }

        /* sse routes: mark the records; the transport is chosen per request
         * (detach / psgi.streaming / blocking), so no boot capability check */
        x = hv_fetchs(h, K_SSE_ROUTES, 0);
        if (x && *x && SvROK(*x) && SvTYPE(SvRV(*x)) == SVt_PVAV) {
            AV *ssr = (AV *)SvRV(*x);
            HV *ssemap = (HV *)sv_2mortal((SV *)newHV());
            AV *recs = (all_recs && SvROK(all_recs)) ? (AV *)SvRV(all_recs) : NULL;
            SSize_t si, sn = av_len(ssr) + 1;
            for (si = 0; si < sn; si++) {
                HV *w = (HV *)SvRV(*av_fetch(ssr, si, 0));
                SV **pp = hv_fetchs(w, K_PATH, 0);
                SV **op = hv_fetchs(w, K_OPTS, 0);
                if (pp && *pp)
                    (void)hv_store_ent(ssemap, *pp,
                        newSVsv(op && *op ? *op : &PL_sv_undef), 0);
            }
            n = recs ? av_len(recs) + 1 : 0;
            for (i = 0; i < n; i++) {
                HV *rr = (HV *)SvRV(*av_fetch(recs, i, 0));
                SV **meth = hv_fetchs(rr, K_METHOD, 0);
                SV **pth = hv_fetchs(rr, K_PATH, 0);
                HE *he;
                if (!(meth && *meth && strEQ(SvPV_nolen(*meth), "GET"))) continue;
                he = pth && *pth ? hv_fetch_ent(ssemap, *pth, 0, 0) : NULL;
                if (he) (void)hv_stores(rr, K_SSE, newSVsv(HeVAL(he)));
            }
        }

        /* views */
        {
            AV *views = app_av(aTHX_ h, K_VIEWS);
            if (av_len(views) >= 0) {
                SV *argv[1], *vobj;
                (void)pk_require_once(aTHX_ PK_VIEWS, TRUE);
                argv[0] = sv_2mortal(newRV_inc((SV *)views));
                vobj = pcx_call_meth(aTHX_ sv_2mortal(newSVpvs(PK_VIEWS)),
                                     "new", argv, 1, 1);
                (void)hv_stores(h, K_VIEWS_C, vobj ? vobj : newSV(0));
            }
            else (void)hv_stores(h, K_VIEWS_C, newSV(0));
        }

        pc_compile_models(aTHX_ self);

        /* static / psgi mounts: instantiate the static apps, order longest */
        mount_src = app_av(aTHX_ h, K_MOUNTS);
        n = av_len(mount_src) + 1;
        for (i = 0; i < n; i++) {
            HV *src = (HV *)SvRV(*av_fetch(mount_src, i, 0));
            HV *m = newHVhv(src);
            SV **dir = hv_fetchs(m, K_DIR, 0);
            SV **mdir = hv_fetchs(m, K_MD_DIR, 0);
            if (dir && *dir && SvOK(*dir)) {
                SV *argv[1], *sapp;
                argv[0] = *dir;
                sapp = pcx_call_meth(aTHX_ sv_2mortal(newSVpvs(PK_STATIC)),
                                     K_APP, argv, 1, 1);
                (void)hv_stores(m, K_APP, sapp ? sapp : newSV(0));
            }
            else if (mdir && *mdir && SvOK(*mdir)) {
                /* The whole documentation site is built here, at boot: the
                 * tree is walked, every page rendered and frozen, and the
                 * search index filled. A bad template or an unreadable
                 * directory is a configuration error and fails with the rest
                 * of the configuration rather than on the first request. */
                SV *argv[3], *mapp;
                SV **op = hv_fetchs(m, K_OPTS, 0);
                argv[0] = *mdir;
                argv[1] = (op && *op) ? *op
                        : sv_2mortal(newRV_noinc((SV *)newHV()));
                argv[2] = *hv_fetchs(m, K_PREFIX, 0);
                mapp = pcx_call_meth(aTHX_ sv_2mortal(newSVpvs(PK_MOUNT_MD)),
                                     K_APP, argv, 3, 1);
                (void)hv_stores(m, K_APP, mapp ? mapp : newSV(0));
            }
            av_push(mounts_out, newRV_noinc((SV *)m));
        }
        if (av_len(mounts_out) >= 0)
            sortsv(AvARRAY(mounts_out), (STRLEN)(av_len(mounts_out) + 1),
                   pc_cmp_len_desc);

        /* before / after hooks and the app on_error, resolved to coderefs */
        {
            HV *hooks = app_hash(aTHX_ h, K_HOOKS);
            SV **bp = hv_fetchs(hooks, K_BEFORE_D, 0);
            SV **ap = hv_fetchs(hooks, K_AFTER_D, 0);
            AV *bl = (bp && *bp && SvROK(*bp)) ? (AV *)SvRV(*bp) : NULL;
            AV *al = (ap && *ap && SvROK(*ap)) ? (AV *)SvRV(*ap) : NULL;
            SV *whatb = sv_2mortal(newSVpvs("before_dispatch hook"));
            SV *whata = sv_2mortal(newSVpvs("after_dispatch hook"));
            n = bl ? av_len(bl) + 1 : 0;
            for (i = 0; i < n; i++)
                av_push(before_out,
                    pc_resolve_target(aTHX_ self, *av_fetch(bl, i, 0), whatb));
            n = al ? av_len(al) + 1 : 0;
            for (i = 0; i < n; i++)
                av_push(after_out,
                    pc_resolve_target(aTHX_ self, *av_fetch(al, i, 0), whata));

            /* The csrf check goes at the head of before_dispatch: a forged
             * request should be refused before an application hook sees it. */
            {
                SV **cc = hv_fetchs(h, K_CSRF, 0);
                if (cc && *cc && SvROK(*cc)) {
                    CV *ck = get_cv("Punk::CSRF::_check", 0);
                    if (ck) {
                        av_unshift(before_out, 1);
                        (void)av_store(before_out, 0, newRV_inc((SV *)ck));
                    }
                }
            }
        }

        /* when sessions are configured, the write-back runs last (it sees the
         * finished triplet and adds the signed Set-Cookie) */
        {
            SV **sc = hv_fetchs(h, "session", 0);
            if (sc && *sc && SvROK(*sc)) {
                CV *wb = get_cv("Punk::Session::_writeback", 0);
                if (wb) av_push(after_out, newRV_inc((SV *)wb));
            }
            /* csrf rides on the session - the token has nowhere else to live -
             * and its mirror cookie goes out after the session's own, on the
             * same response */
            {
                SV **cc = hv_fetchs(h, K_CSRF, 0);
                if (cc && *cc && SvROK(*cc)) {
                    CV *wb;
                    if (!(sc && *sc && SvROK(*sc)))
                        croak("Punk: `csrf` needs a session for the token to "
                              "live in - add a `session` keyword");
                    wb = get_cv("Punk::CSRF::_writeback", 0);
                    if (wb) av_push(after_out, newRV_inc((SV *)wb));
                }
            }
        }

        if (pcx_can(aTHX_ self, "compile_extras")) {
            SV *r = pcx_call_meth(aTHX_ self, "compile_extras", NULL, 0, 0);
            if (r) SvREFCNT_dec(r);
        }

        /* flatten the api mounts to the fields the C dispatcher reads */
        n = av_len(api_mounts) + 1;
        for (i = 0; i < n; i++) {
            HV *rec = (HV *)SvRV(*av_fetch(api_mounts, i, 0));
            SV *m = *hv_fetchs(rec, K_MOUNT, 0);
            SV *pfx = *hv_fetchs(rec, K_PREFIX, 0);
            HV *flat = newHV();
            SV *apio = pcx_call_meth(aTHX_ m, K_API, NULL, 0, 1);
            SV *opso = pcx_call_meth(aTHX_ m, K_OPS, NULL, 0, 1);
            SV *mbo  = pcx_call_meth(aTHX_ m, "max_body_size", NULL, 0, 1);
            SV *oeo  = pcx_call_meth(aTHX_ m, K_ON_ERROR, NULL, 0, 1);
            (void)hv_stores(flat, K_PREFIX,   newSVsv(pfx));
            (void)hv_stores(flat, K_API,      apio ? apio : newSV(0));
            (void)hv_stores(flat, K_OPS,      opso ? opso : newSV(0));
            (void)hv_stores(flat, K_MAX_BODY, mbo  ? mbo  : newSV(0));
            (void)hv_stores(flat, K_ON_ERROR, oeo  ? oeo  : newSV(0));
            av_push(state_apims, newRV_noinc((SV *)flat));
        }

        state = newHV();
        (void)hv_stores(state, K_ROUTER, newSVsv(xs_router));
        (void)hv_stores(state, K_RECS,   newSVsv(all_recs));
        (void)hv_stores(state, K_API_MOUNTS, newRV_noinc((SV *)state_apims));
        (void)hv_stores(state, K_MOUNTS, newRV_noinc((SV *)mounts_out));
        (void)hv_stores(state, K_CTX,    newSVsv(ctx));
        (void)hv_stores(state, K_APP,    newSVsv(self));
        (void)hv_stores(state, K_BEFORE, newRV_noinc((SV *)before_out));
        (void)hv_stores(state, K_AFTER,  newRV_noinc((SV *)after_out));
        {   /* the CORS policy, read once per request by pc_app_cb; absent
             * when the keyword was never used, so it costs one failed fetch */
            SV **co = hv_fetchs(h, K_CORS, 0);
            if (co && *co && SvROK(*co)) {
                (void)hv_stores(state, K_CORS, newSVsv(*co));
                /* Punk::CORS::_chain is the one Perl piece of the path - it
                 * chains the decoration onto a Future - and nothing else
                 * loads the file, so it is required here rather than
                 * discovered missing on the first nonblocking response. */
                if (!pk_require_once(aTHX_ "Punk::CORS", FALSE))
                    croak("Punk: cors needs Punk::CORS, which failed to "
                          "load: %s", SvPV_nolen(ERRSV));
            }
        }
        {   /* the security-header policy: the defaults and the keyword's
             * overrides merged once, so a request only walks a frozen pair
             * list; absent when the keyword was never used */
            SV **hd = hv_fetchs(h, K_HEADERS, 0);
            if (hd && *hd && SvROK(*hd)
                && SvTYPE(SvRV(*hd)) == SVt_PVHV) {
                AV *pairs = phd_compile(aTHX_ (HV *)SvRV(*hd));
                (void)hv_stores(state, K_HEADERS, newRV_noinc((SV *)pairs));
                /* Punk::Headers::_chain is the one Perl piece of the path,
                 * for the Future shape - required here, like Punk::CORS */
                if (!pk_require_once(aTHX_ "Punk::Headers", FALSE))
                    croak("Punk: headers needs Punk::Headers, which failed "
                          "to load: %s", SvPV_nolen(ERRSV));
            }
        }
        {   /* auth: the battery needs a session for the identity to live in,
             * and a roles target resolves now so a typo croaks at boot */
            SV **au = hv_fetchs(h, K_AUTH, 0);
            if (au && *au && SvROK(*au)
                && SvTYPE(SvRV(*au)) == SVt_PVHV) {
                HV *acfg = (HV *)SvRV(*au);
                SV **sc = hv_fetchs(h, "session", 0);
                SV **rl;
                if (!(sc && *sc && SvROK(*sc)))
                    croak("Punk: `auth` needs a session for the identity to "
                          "live in - add a `session` keyword");
                rl = hv_fetchs(acfg, "roles", 0);
                if (rl && *rl && SvOK(*rl) && !SvROK(*rl)) {
                    SV *what = sv_2mortal(newSVpvs("auth roles"));
                    SV *code = pc_resolve_target(aTHX_ self, *rl, what);
                    (void)hv_stores(acfg, "roles", code);
                }
                /* the Perl half: current_user and the role/verified checks */
                if (!pk_require_once(aTHX_ "Punk::Auth", FALSE))
                    croak("Punk: auth needs Punk::Auth, which failed to "
                          "load: %s", SvPV_nolen(ERRSV));
            }
        }
        {   /* scoped header policies ($scope->headers): flattened per record
             * and sorted longest-prefix-first, so a request under nested
             * scopes reads the most specific mention of a name first */
            SV **sh = hv_fetchs(h, K_HEADERS_SCOPED, 0);
            if (sh && *sh && SvROK(*sh) && SvTYPE(SvRV(*sh)) == SVt_PVAV) {
                AV *src = (AV *)SvRV(*sh);
                SSize_t si, sn = av_len(src) + 1;
                AV *outav = newAV();
                for (si = 0; si < sn; si++) {
                    SV **rp = av_fetch(src, si, 0);
                    HV *rec, *out;
                    SV **x;
                    STRLEN pfl = 0;
                    if (!(rp && *rp && SvROK(*rp))) continue;
                    rec = (HV *)SvRV(*rp);
                    out = newHV();
                    x = hv_fetchs(rec, K_PREFIX, 0);
                    if (x && *x && SvOK(*x)) (void)SvPV_const(*x, pfl);
                    (void)hv_stores(out, K_PREFIX,
                        (x && *x && SvOK(*x)) ? newSVsv(*x) : newSVpvs(""));
                    (void)hv_stores(out, K_LEN, newSViv((IV)pfl));
                    x = hv_fetchs(rec, K_HEADERS, 0);
                    if (x && *x && SvROK(*x)
                        && SvTYPE(SvRV(*x)) == SVt_PVHV)
                        (void)hv_stores(out, K_HEADERS, newRV_noinc(
                            (SV *)phd_flat(aTHX_ (HV *)SvRV(*x))));
                    av_push(outav, newRV_noinc((SV *)out));
                }
                if (av_len(outav) > 0)
                    sortsv(AvARRAY(outav), (STRLEN)(av_len(outav) + 1),
                           pc_cmp_len_desc);
                if (av_len(outav) >= 0) {
                    (void)hv_stores(state, K_HEADERS_SCOPED,
                                    newRV_noinc((SV *)outav));
                    if (!pk_require_once(aTHX_ "Punk::Headers", FALSE))
                        croak("Punk: headers needs Punk::Headers, which "
                              "failed to load: %s", SvPV_nolen(ERRSV));
                }
                else SvREFCNT_dec((SV *)outav);
            }
        }
        {
            SV **nf = hv_fetchs(h, K_ON_NOT_FOUND, 0);
            SV *on_nf = &PL_sv_undef;
            if (nf && *nf && SvOK(*nf)) {
                SV *what = sv_2mortal(newSVpvs(K_ON_NOT_FOUND));
                on_nf = sv_2mortal(pc_resolve_target(aTHX_ self, *nf, what));
            }
            (void)hv_stores(state, K_ON_NOT_FOUND, newSVsv(on_nf));
        }
        {
            SV **oe = hv_fetchs(h, K_ON_ERROR, 0);
            SV *on_err = &PL_sv_undef;
            if (oe && *oe && SvOK(*oe)) {
                SV *what = sv_2mortal(newSVpvs(K_ON_ERROR));
                on_err = sv_2mortal(pc_resolve_target(aTHX_ self, *oe, what));
            }
            (void)hv_stores(state, K_ON_ERROR, newSVsv(on_err));
        }
        PERL_UNUSED_VAR(caller);

        state_rv = sv_2mortal(newRV_noinc((SV *)state));
        {
            AV *acap = newAV();
            av_push(acap, newSVsv(state_rv));
            app_cv = punk_closure(aTHX_ pc_app_cb, acap);
        }

        /* wrap in middleware, innermost last (reverse registration order):
         * $app = $mw->($app) - a coderef call, our +1 on the old app handed in
         * and released by the call scope. */
        mw = app_av(aTHX_ h, K_MIDDLEWARE);
        for (i = av_len(mw); i >= 0; i--) {
            SV **wp = av_fetch(mw, i, 0);
            SV *wrapped; dSP; int count;
            if (!wp || !*wp) continue;
            ENTER; SAVETMPS;
            PUSHMARK(SP); EXTEND(SP, 1);
            PUSHs(sv_2mortal(app_cv));
            PUTBACK;
            count = call_sv(*wp, G_SCALAR);
            SPAGAIN;
            wrapped = count > 0 ? SvREFCNT_inc(POPs) : newSV(0);
            PUTBACK; FREETMPS; LEAVE;
            app_cv = wrapped;
        }

        { SV **cp = hv_fetchs(h, K_COMPILED, 0);
          (void)hv_stores(h, K_COMPILED,
              newSViv((cp && *cp && SvOK(*cp) ? SvIV(*cp) : 0) + 1)); }
        RETVAL = app_cv;
    }
    OUTPUT:
        RETVAL
