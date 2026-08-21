MODULE = Punk        PACKAGE = Punk::App

PROTOTYPES: DISABLE

# The registrar surface, in C (punk_app.h). The app is a blessed hash the DSL
# keywords push into; these methods are XSUBs. The boot orchestration that
# drives the other subsystems (compile, the config loader, target/context
# resolution) stays Perl in Punk::App.pm.

SV *
new(class, ...)
        SV *class
    CODE:
    {
        HV *h = newHV();
        HV *hooks = newHV();
        SV *rc, *router;
        int i;
        for (i = 1; i + 1 < items; i += 2) {
            STRLEN kl; const char *k = SvPV_const(ST(i), kl);
            if (kl == 6 && memEQ(k, K_CALLER, 6))
                (void)hv_stores(h, K_CALLER, newSVsv(ST(i + 1)));
        }
        if (!hv_exists(h, K_CALLER, 6)) (void)hv_stores(h, K_CALLER, newSV(0));
        rc = sv_2mortal(newSVpvs(PK_ROUTER));
        router = pcx_call_meth(aTHX_ rc, "new", NULL, 0, 1);
        (void)hv_stores(h, K_ROUTER, router ? router : newSV(0));
        (void)hv_stores(h, K_MOUNTS,     newRV_noinc((SV *)newAV()));
        (void)hv_stores(h, K_VIEWS,      newRV_noinc((SV *)newAV()));
        (void)hv_stores(h, K_DATABASES,  newRV_noinc((SV *)newHV()));
        (void)hv_stores(h, K_MODELS,     newRV_noinc((SV *)newAV()));
        (void)hv_stores(hooks, K_BEFORE_R, newRV_noinc((SV *)newAV()));
        (void)hv_stores(hooks, K_BEFORE_D, newRV_noinc((SV *)newAV()));
        (void)hv_stores(hooks, K_AFTER_D,  newRV_noinc((SV *)newAV()));
        (void)hv_stores(h, K_HOOKS,      newRV_noinc((SV *)hooks));
        (void)hv_stores(h, K_MIDDLEWARE, newRV_noinc((SV *)newAV()));
        (void)hv_stores(h, K_HELPERS,    newRV_noinc((SV *)newHV()));
        (void)hv_stores(h, K_ON_ERROR,   newSV(0));
        (void)hv_stores(h, K_COMPILED,   newSViv(0));
        RETVAL = sv_bless(newRV_noinc((SV *)h), gv_stashsv(class, GV_ADD));
    }
    OUTPUT:
        RETVAL

SV *
caller_class(self)
        SV *self
    CODE:
    {
        SV *c = app_get(aTHX_ app_hv(aTHX_ self), K_CALLER);
        RETVAL = c ? newSVsv(c) : &PL_sv_undef;
    }
    OUTPUT:
        RETVAL

SV *
config_object(self)
        SV *self
    CODE:
    {
        SV *c = app_get(aTHX_ app_hv(aTHX_ self), K_CONFIG);
        RETVAL = c ? newSVsv(c) : &PL_sv_undef;
    }
    OUTPUT:
        RETVAL

# route($method, $path, $target, $guards, $opts?): $self->{router}->add(...)
# plus, for a `validate` option, a record in validate_routes for
# compile_extras to compile once at boot. Unknown option keys croak. Chains.
SV *
route(self, method, path, target, guards = &PL_sv_undef, opts = &PL_sv_undef)
        SV *self
        SV *method
        SV *path
        SV *target
        SV *guards
        SV *opts
    CODE:
    {
        HV *h = app_hv(aTHX_ self);
        SV *router = app_get(aTHX_ h, K_ROUTER);
        SV *argv[8], *r;
        /* the one-hashref form: post '/x' => { cb => ..., max_body => N }.
         * Split here rather than in the keyword layer, because scoped verbs
         * ($scope->post) reach this same method (xs/scope.xs) and get it for
         * free. Everything below is untouched by which spelling was used. */
        {
            SV *wm = sv_2mortal(newSVpvs("route "));
            sv_catsv(wm, method);
            pk_spec_split(aTHX_ SvPV_nolen(wm), path, &target, &opts);
        }
        if (SvOK(opts)) {
            HV *oh; HE *he; SV **vp;
            if (!(SvROK(opts) && SvTYPE(SvRV(opts)) == SVt_PVHV))
                croak("Punk: route options must be a hashref");
            oh = (HV *)SvRV(opts);
            hv_iterinit(oh);
            while ((he = hv_iternext(oh))) {
                STRLEN kl; const char *k = HePV(he, kl);
                if (!strEQ(k, K_VALIDATE) && !strEQ(k, K_COMPRESS)
                    && !strEQ(k, K_MAX_BODY) && !strEQ(k, K_SITEMAP)
                    && !strEQ(k, K_ETAG) && !strEQ(k, K_IDEMPOTENT))
                    croak("Punk: unknown route option '%s'", k);
            }
            /* max_body: this route's ceiling on CONTENT_LENGTH, overriding
             * the app-wide keyword. 0 means "do not check here", which is
             * legitimate - unlike the server's ceiling, this one is policy
             * and not the memory backstop. Recorded now, stamped onto the
             * compiled record at to_app (the ws/sse/compress pattern). */
            vp = hv_fetchs(oh, K_MAX_BODY, 0);
            if (vp && *vp && SvOK(*vp)) {
                HV *rec = newHV();
                (void)hv_stores(rec, K_METHOD,   newSVsv(method));
                (void)hv_stores(rec, K_PATH,     newSVsv(path));
                (void)hv_stores(rec, K_MAX_BODY, newSViv(SvIV(*vp)));
                av_push(app_av(aTHX_ h, K_MAXBODY_ROUTES),
                        newRV_noinc((SV *)rec));
            }
            /* compress => 0 opts this route out of the server's response
             * compression. Recorded now, stamped onto the compiled record
             * at to_app (the ws/sse pattern), and spelled on the way out as
             * `Content-Encoding: identity` - a plain response header, which
             * is the documented contract Hyperman honours and any other
             * PSGI server could. There is no compress => 1: compressing is
             * the server's default answer for a route that says nothing. */
            vp = hv_fetchs(oh, K_COMPRESS, 0);
            if (vp && *vp && !SvTRUE(*vp)) {
                HV *rec = newHV();
                (void)hv_stores(rec, K_METHOD, newSVsv(method));
                (void)hv_stores(rec, K_PATH,   newSVsv(path));
                av_push(app_av(aTHX_ h, K_NOCOMPRESS_ROUTES),
                        newRV_noinc((SV *)rec));
            }
            /* sitemap => 0 keeps this route out of Punk::Plugin::Sitemap's
             * generated sitemap.xml, and disallows it in robots.txt.
             *
             * sitemap => 1 is the other direction and is NOT the opt-in half
             * of a pair: inclusion is already the default for a route that
             * says nothing. It overrides an exclusion the plugin inferred -
             * in practice a guard, because a scope guard may be an
             * authentication check or may be an ordinary filter, and Punk
             * cannot read its intent. The plugin assumes the first, which is
             * the safe direction, and this is how an application says the
             * page is public anyway. */
            vp = hv_fetchs(oh, K_SITEMAP, 0);
            if (vp && *vp && SvOK(*vp)) {
                HV *rec = newHV();
                (void)hv_stores(rec, K_METHOD,  newSVsv(method));
                (void)hv_stores(rec, K_PATH,    newSVsv(path));
                (void)hv_stores(rec, K_SITEMAP, newSViv(SvTRUE(*vp) ? 1 : 0));
                av_push(app_av(aTHX_ h, K_SITEMAP_ROUTES),
                        newRV_noinc((SV *)rec));
            }
            /* etag: the conditional-GET validator for this route, inert
             * unless Punk::Plugin::ConditionalGet is registered - the
             * `sitemap` arrangement, and for the same reason: the option
             * belongs to the route, and only the application knows whether
             * it wants the behaviour at all.
             *
             * A coderef is the STRONG validator: it is called before the
             * handler and what it returns identifies the entity, so an
             * unchanged one answers 304 without the handler running. The
             * body ETag (`etag => 1`) is phase 2 and croaks here rather
             * than being accepted and quietly doing nothing - an option
             * that looks like it worked is worse than one that failed. */
            vp = hv_fetchs(oh, K_ETAG, 0);
            if (vp && *vp && SvOK(*vp)) {
                HV *rec;
                int is_cv = (SvROK(*vp) && SvTYPE(SvRV(*vp)) == SVt_PVCV);
                if (!is_cv && SvROK(*vp))
                    croak("Punk: etag on %s %s takes a coderef (the strong "
                          "validator) or 1 (the body ETag), not a %s",
                          SvPV_nolen(method), SvPV_nolen(path),
                          sv_reftype(SvRV(*vp), 0));
                /* etag => 0 is "no", which is what a route says by saying
                 * nothing: recorded as absent rather than as a third state */
                if (!is_cv && !SvTRUE(*vp)) goto etag_done;
                rec = newHV();
                (void)hv_stores(rec, K_METHOD, newSVsv(method));
                (void)hv_stores(rec, K_PATH,   newSVsv(path));
                (void)hv_stores(rec, K_ETAG,
                                is_cv ? newSVsv(*vp) : newSViv(1));
                av_push(app_av(aTHX_ h, K_ETAG_ROUTES),
                        newRV_noinc((SV *)rec));
                etag_done: ;
            }
            /* idempotent: honour an Idempotency-Key on this route, inert
             * unless Punk::Plugin::Idempotency is registered - the `sitemap`
             * and `etag` arrangement. Opt in per route because a key
             * honoured on every POST means a cache write on every POST, and
             * most POSTs do not need one. */
            vp = hv_fetchs(oh, K_IDEMPOTENT, 0);
            if (vp && *vp && SvOK(*vp) && SvTRUE(*vp)) {
                HV *rec = newHV();
                (void)hv_stores(rec, K_METHOD, newSVsv(method));
                (void)hv_stores(rec, K_PATH,   newSVsv(path));
                av_push(app_av(aTHX_ h, K_IDEM_ROUTES),
                        newRV_noinc((SV *)rec));
            }
            vp = hv_fetchs(oh, K_VALIDATE, 0);
            if (vp && *vp && SvOK(*vp)) {
                HV *rec = newHV();
                (void)hv_stores(rec, K_METHOD,   newSVsv(method));
                (void)hv_stores(rec, K_PATH,     newSVsv(path));
                (void)hv_stores(rec, K_VALIDATE, newSVsv(*vp));
                av_push(app_av(aTHX_ h, K_VALIDATE_ROUTES),
                        newRV_noinc((SV *)rec));
            }
        }
        argv[0] = sv_2mortal(newSVpvs(K_METHOD)); argv[1] = method;
        argv[2] = sv_2mortal(newSVpvs(K_PATH));   argv[3] = path;
        argv[4] = sv_2mortal(newSVpvs(K_TARGET)); argv[5] = target;
        argv[6] = sv_2mortal(newSVpvs(K_GUARDS));
        argv[7] = SvOK(guards) ? guards
                               : sv_2mortal(newRV_noinc((SV *)newAV()));
        r = pcx_call_meth(aTHX_ router ? router : &PL_sv_undef, "add", argv, 8, 1);
        if (r) SvREFCNT_dec(r);
        RETVAL = newSVsv(self);
    }
    OUTPUT:
        RETVAL

# under($prefix, $guard?) -> a Punk::Router::Scope.
SV *
under(self, prefix, guard = &PL_sv_undef)
        SV *self
        SV *prefix
        SV *guard
    CODE:
    {
        AV *g = newAV();
        SV *argv[6];
        if (SvOK(guard)) av_push(g, newSVsv(guard));
        argv[0] = sv_2mortal(newSVpvs(K_APP));    argv[1] = self;
        argv[2] = sv_2mortal(newSVpvs(K_PREFIX)); argv[3] = prefix;
        argv[4] = sv_2mortal(newSVpvs(K_GUARDS));
        argv[5] = sv_2mortal(newRV_noinc((SV *)g));
        RETVAL = pcx_call_meth(aTHX_ sv_2mortal(newSVpvs(PK_SCOPE)),
                               "new", argv, 6, 1);
        if (!RETVAL) RETVAL = &PL_sv_undef;
    }
    OUTPUT:
        RETVAL

# websocket($path, $target, $opts?, $guards?): a GET route plus recorded opts.
SV *
websocket(self, path, target, opts = &PL_sv_undef, guards = &PL_sv_undef)
        SV *self
        SV *path
        SV *target
        SV *opts
        SV *guards
    CODE:
    {
        HV *h = app_hv(aTHX_ self);
        static const char *known[] =
            { "protocols", "max_message_size", "write_buffer_limit", K_BLOCKING };
        HV *oh;
        SV *argv[8], *r; HE *he; HV *rec;
        pk_spec_split(aTHX_ "websocket", path, &target, &opts);
        oh = (SvROK(opts) && SvTYPE(SvRV(opts)) == SVt_PVHV)
             ? (HV *)SvRV(opts) : NULL;
        if (oh) {
            hv_iterinit(oh);
            while ((he = hv_iternext(oh))) {
                STRLEN kl; const char *k = HePV(he, kl); int ok = 0, i;
                for (i = 0; i < 4; i++)
                    if (strEQ(k, known[i])) { ok = 1; break; }
                if (!ok) croak("Punk: unknown websocket option(s) %s", k);
            }
        }
        /* $self->route('GET', $path, $target, $guards || []) */
        argv[0] = sv_2mortal(newSVpvs("GET")); argv[1] = path;
        argv[2] = target;
        argv[3] = SvOK(guards) ? guards : sv_2mortal(newRV_noinc((SV *)newAV()));
        r = pcx_call_meth(aTHX_ self, "route", argv, 4, 1);
        if (r) SvREFCNT_dec(r);
        rec = newHV();
        (void)hv_stores(rec, K_PATH, newSVsv(path));
        (void)hv_stores(rec, K_OPTS,
            oh ? newRV_noinc((SV *)newHVhv(oh)) : newRV_noinc((SV *)newHV()));
        av_push(app_av(aTHX_ h, K_WS_ROUTES), newRV_noinc((SV *)rec));
        RETVAL = newSVsv(self);
    }
    OUTPUT:
        RETVAL

# sse($path, $target, $opts?, $guards?): a Server-Sent Events route - a GET
# route the dispatcher hands to Punk::SSE with the socket taken over. Chains.
SV *
sse(self, path, target, opts = &PL_sv_undef, guards = &PL_sv_undef)
        SV *self
        SV *path
        SV *target
        SV *opts
        SV *guards
    CODE:
    {
        HV *h = app_hv(aTHX_ self);
        static const char *known[] =
            { "heartbeat", "retry", "write_buffer_limit", K_BLOCKING };
        HV *oh;
        SV *argv[8], *r; HE *he; HV *rec;
        pk_spec_split(aTHX_ "sse", path, &target, &opts);
        oh = (SvROK(opts) && SvTYPE(SvRV(opts)) == SVt_PVHV)
             ? (HV *)SvRV(opts) : NULL;
        if (oh) {
            hv_iterinit(oh);
            while ((he = hv_iternext(oh))) {
                STRLEN kl; const char *k = HePV(he, kl); int ok = 0, i;
                for (i = 0; i < 4; i++)
                    if (strEQ(k, known[i])) { ok = 1; break; }
                if (!ok) croak("Punk: unknown sse option(s) %s", k);
            }
        }
        argv[0] = sv_2mortal(newSVpvs("GET")); argv[1] = path;
        argv[2] = target;
        argv[3] = SvOK(guards) ? guards : sv_2mortal(newRV_noinc((SV *)newAV()));
        r = pcx_call_meth(aTHX_ self, "route", argv, 4, 1);
        if (r) SvREFCNT_dec(r);
        rec = newHV();
        (void)hv_stores(rec, K_PATH, newSVsv(path));
        (void)hv_stores(rec, K_OPTS,
            oh ? newRV_noinc((SV *)newHVhv(oh)) : newRV_noinc((SV *)newHV()));
        av_push(app_av(aTHX_ h, K_SSE_ROUTES), newRV_noinc((SV *)rec));
        RETVAL = newSVsv(self);
    }
    OUTPUT:
        RETVAL

# cors(origins => [...], credentials => 1, ...) or cors(\%opts): freeze the
# CORS policy on the app. Bare `cors` is '*' with no credentials - right for a
# public API, and safe, since browsers refuse '*' with credentials anyway.
# Chains.
SV *
cors(self, ...)
        SV *self
    CODE:
    {
        HV *h = app_hv(aTHX_ self);
        HV *cfg = newHV();
        int i;
        if (items == 2 && SvROK(ST(1)) && SvTYPE(SvRV(ST(1))) == SVt_PVHV) {
            HE *e; HV *given = (HV *)SvRV(ST(1));
            hv_iterinit(given);
            while ((e = hv_iternext(given))) {
                STRLEN kl; const char *k = HePV(e, kl);
                (void)hv_store(cfg, k, (I32)kl,
                               newSVsv(hv_iterval(given, e)), 0);
            }
        }
        else for (i = 1; i + 1 < items; i += 2) {
            STRLEN kl; const char *k = SvPV_const(ST(i), kl);
            (void)hv_store(cfg, k, (I32)kl, newSVsv(ST(i + 1)), 0);
        }
        if (items == 2 && !SvROK(ST(1)) && !SvTRUE(ST(1))) {
            SvREFCNT_dec((SV *)cfg);
            (void)hv_delete(h, K_CORS, (I32)strlen(K_CORS), G_DISCARD);
        }
        else {
            /* Allow-Origin: * with credentials is refused by every browser,
             * and reflecting any origin with credentials is the classic
             * misconfiguration. Naming origins is the only safe spelling. */
            SV **cr = hv_fetchs(cfg, "credentials", 0);
            SV **og = hv_fetchs(cfg, "origins", 0);
            if (cr && *cr && SvTRUE(*cr)) {
                int named = og && *og && SvOK(*og);
                if (named && !SvROK(*og)) {
                    STRLEN ol; const char *o = SvPV_const(*og, ol);
                    if (ol == 1 && *o == '*') named = 0;
                }
                if (!named) {
                    SvREFCNT_dec((SV *)cfg);
                    croak("Punk: `cors credentials => 1` needs explicit "
                          "origins - a browser refuses credentials with '*', "
                          "and reflecting any origin with them lets every "
                          "site read authenticated responses");
                }
            }
            (void)hv_store(h, K_CORS, (I32)strlen(K_CORS),
                           newRV_noinc((SV *)cfg), 0);
        }
        RETVAL = newSVsv(self);
    }
    OUTPUT:
        RETVAL

# headers('Content-Security-Policy' => "default-src 'self'", ...) or
# headers(\%opts): freeze the security-header policy on the app. Bare
# `headers` is the safe default set; a header name with an undef value drops
# that default; every value else is a literal header string. Chains.
SV *
headers(self, ...)
        SV *self
    CODE:
    {
        HV *h = app_hv(aTHX_ self);
        HV *cfg = newHV();
        int i;
        if (items == 2 && SvROK(ST(1)) && SvTYPE(SvRV(ST(1))) == SVt_PVHV) {
            HE *e; HV *given = (HV *)SvRV(ST(1));
            hv_iterinit(given);
            while ((e = hv_iternext(given))) {
                STRLEN kl; const char *k = HePV(e, kl);
                (void)hv_store(cfg, k, (I32)kl,
                               newSVsv(hv_iterval(given, e)), 0);
            }
        }
        else for (i = 1; i + 1 < items; i += 2) {
            STRLEN kl; const char *k = SvPV_const(ST(i), kl);
            (void)hv_store(cfg, k, (I32)kl, newSVsv(ST(i + 1)), 0);
        }
        if (items == 2 && !SvROK(ST(1)) && !SvTRUE(ST(1))) {
            SvREFCNT_dec((SV *)cfg);
            (void)hv_delete(h, K_HEADERS, (I32)strlen(K_HEADERS), G_DISCARD);
        }
        else {
            /* a value must be a literal header string (or undef to drop a
             * default) - a reference here is always a mistake */
            HE *e;
            hv_iterinit(cfg);
            while ((e = hv_iternext(cfg))) {
                STRLEN kl; const char *k = HePV(e, kl);
                SV *v = hv_iterval(cfg, e);
                if (!kl || v == NULL) {
                    SvREFCNT_dec((SV *)cfg);
                    croak("Punk: headers needs header names as keys");
                }
                if (SvROK(v)) {
                    SV *msg = sv_2mortal(newSVpvf(
                        "Punk: headers value for '%.*s' must be a string "
                        "(or undef to drop a default), not a reference",
                        (int)kl, k));
                    SvREFCNT_dec((SV *)cfg);
                    croak("%s", SvPV_nolen(msg));
                }
            }
            (void)hv_store(h, K_HEADERS, (I32)strlen(K_HEADERS),
                           newRV_noinc((SV *)cfg), 0);
        }
        RETVAL = newSVsv(self);
    }
    OUTPUT:
        RETVAL

# max_body($bytes): the app-wide ceiling on a request's declared
# CONTENT_LENGTH, overridable per route. This is POLICY, not memory
# protection - by the time Punk runs, the body is already resident in the
# server's buffer. What it buys is the parse, the guards, the handler, and
# an honest 413 instead of a mysterious success. The memory bound is the
# server's (Hyperman's own `max_body`). Chains.
SV *
max_body(self, bytes = &PL_sv_undef)
        SV *self
        SV *bytes
    CODE:
    {
        HV *h = app_hv(aTHX_ self);
        if (!SvOK(bytes))
            croak("Punk: max_body needs a byte count");
        if (SvROK(bytes))
            croak("Punk: max_body takes a byte count, not a reference");
        {
            IV n = SvIV(bytes);
            if (n < 0)
                croak("Punk: max_body must not be negative");
            (void)hv_store(h, K_MAX_BODY, (I32)strlen(K_MAX_BODY),
                           newSViv(n), 0);
        }
        RETVAL = newSVsv(self);
    }
    OUTPUT:
        RETVAL

# proxy() / proxy(trust => 1, ...) / proxy(\%opts): declare that this
# application sits behind a reverse proxy, so the real client can be
# recovered from the forwarded headers. Bare `proxy` means one hop, which is
# the common case. Unknown options croak at keyword time; the values are
# validated at to_app, where the CIDRs are parsed and 'all' is refused
# outside development. Declaring it twice croaks: a second policy silently
# replacing the first is how a staging config leaks into production. Chains.
SV *
proxy(self, ...)
        SV *self
    CODE:
    {
        HV *h = app_hv(aTHX_ self);
        HV *cfg = newHV();
        int i;
        static const char *const PP_OPTS[] = {
            "trust", "for_header", "proto_header", "host_header",
            "port_header", NULL
        };
        if (items == 2 && SvROK(ST(1)) && SvTYPE(SvRV(ST(1))) == SVt_PVHV) {
            HE *e; HV *given = (HV *)SvRV(ST(1));
            hv_iterinit(given);
            while ((e = hv_iternext(given))) {
                STRLEN kl; const char *k = HePV(e, kl);
                (void)hv_store(cfg, k, (I32)kl,
                               newSVsv(hv_iterval(given, e)), 0);
            }
        }
        else for (i = 1; i + 1 < items; i += 2) {
            STRLEN kl; const char *k = SvPV_const(ST(i), kl);
            (void)hv_store(cfg, k, (I32)kl, newSVsv(ST(i + 1)), 0);
        }

        if (items == 2 && !SvROK(ST(1)) && !SvTRUE(ST(1))) {
            SvREFCNT_dec((SV *)cfg);
            (void)hv_delete(h, K_PROXY, (I32)strlen(K_PROXY), G_DISCARD);
        }
        else {
            HE *e;
            if (hv_exists(h, K_PROXY, (I32)strlen(K_PROXY))) {
                SvREFCNT_dec((SV *)cfg);
                croak("Punk: `proxy` is already declared - one trust policy "
                      "per application, or a second one silently replaces "
                      "the first");
            }
            hv_iterinit(cfg);
            while ((e = hv_iternext(cfg))) {
                STRLEN kl; const char *k = HePV(e, kl);
                int j, known = 0;
                for (j = 0; PP_OPTS[j]; j++)
                    if (kl == strlen(PP_OPTS[j]) && memEQ(k, PP_OPTS[j], kl))
                        { known = 1; break; }
                if (!known) {
                    SV *msg = sv_2mortal(newSVpvf(
                        "Punk: proxy: unknown option '%.*s' (known: trust, "
                        "for_header, proto_header, host_header, port_header)",
                        (int)kl, k));
                    SvREFCNT_dec((SV *)cfg);
                    croak("%s", SvPV_nolen(msg));
                }
            }
            (void)hv_store(h, K_PROXY, (I32)strlen(K_PROXY),
                           newRV_noinc((SV *)cfg), 0);
        }
        RETVAL = newSVsv(self);
    }
    OUTPUT:
        RETVAL

# auth(model => 'User', ...) or auth(\%opts): freeze the authentication
# config on the app. Unknown keys croak at keyword time - a typo in an auth
# option must not become a silently-open door. `auth 0` turns it off. Chains.
SV *
auth(self, ...)
        SV *self
    CODE:
    {
        HV *h = app_hv(aTHX_ self);
        HV *cfg = newHV();
        HV *fields = newHV();
        int i;
        static const char *known[] =
            { "model", "token_model", "session_key", "login_path",
              "iterations", "roles", "rank", "fields" };
        static const char *fknown[] =
            { "id", "email", "password", "verified" };
        (void)hv_stores(cfg, "session_key", newSVpvs("user_id"));
        (void)hv_stores(cfg, "login_path",  newSVpvs("/login"));
        (void)hv_stores(fields, "id",       newSVpvs("id"));
        (void)hv_stores(fields, "email",    newSVpvs("email"));
        (void)hv_stores(fields, "password", newSVpvs("password_hash"));
        (void)hv_stores(fields, "verified", newSVpvs("verified"));
        (void)hv_stores(cfg, "fields", newRV_noinc((SV *)fields));
        if (items == 2 && SvROK(ST(1)) && SvTYPE(SvRV(ST(1))) == SVt_PVHV) {
            HE *e; HV *given = (HV *)SvRV(ST(1));
            hv_iterinit(given);
            while ((e = hv_iternext(given))) {
                STRLEN kl; const char *k = HePV(e, kl);
                (void)hv_store(cfg, k, (I32)kl,
                               newSVsv(hv_iterval(given, e)), 0);
            }
        }
        else for (i = 1; i + 1 < items; i += 2) {
            STRLEN kl; const char *k = SvPV_const(ST(i), kl);
            (void)hv_store(cfg, k, (I32)kl, newSVsv(ST(i + 1)), 0);
        }
        if (items == 2 && !SvROK(ST(1)) && !SvTRUE(ST(1))) {
            SvREFCNT_dec((SV *)cfg);
            (void)hv_delete(h, K_AUTH, (I32)strlen(K_AUTH), G_DISCARD);
        }
        else {
            HE *e;
            hv_iterinit(cfg);
            while ((e = hv_iternext(cfg))) {
                STRLEN kl; const char *k = HePV(e, kl);
                int ok = 0, j;
                for (j = 0; j < 8; j++)
                    if (strEQ(k, known[j])) { ok = 1; break; }
                if (!ok) {
                    SV *msg = sv_2mortal(newSVpvf(
                        "Punk: unknown auth option '%.*s'", (int)kl, k));
                    SvREFCNT_dec((SV *)cfg);
                    croak("%s", SvPV_nolen(msg));
                }
            }
            {   /* a fields hashref merges over the defaults */
                SV **f = hv_fetchs(cfg, "fields", 0);
                if (f && *f && SvRV(*f) != (SV *)fields) {
                    HV *merged = newHV(), *given;
                    HE *fe;
                    int j;
                    if (!(SvROK(*f) && SvTYPE(SvRV(*f)) == SVt_PVHV)) {
                        SvREFCNT_dec((SV *)cfg);
                        croak("Punk: auth fields must be a hashref");
                    }
                    given = (HV *)SvRV(*f);
                    (void)hv_stores(merged, "id",       newSVpvs("id"));
                    (void)hv_stores(merged, "email",    newSVpvs("email"));
                    (void)hv_stores(merged, "password", newSVpvs("password_hash"));
                    (void)hv_stores(merged, "verified", newSVpvs("verified"));
                    hv_iterinit(given);
                    while ((fe = hv_iternext(given))) {
                        STRLEN kl; const char *k = HePV(fe, kl);
                        int ok = 0;
                        for (j = 0; j < 4; j++)
                            if (strEQ(k, fknown[j])) { ok = 1; break; }
                        if (!ok) {
                            SV *msg = sv_2mortal(newSVpvf(
                                "Punk: unknown auth field '%.*s'",
                                (int)kl, k));
                            SvREFCNT_dec((SV *)merged);
                            SvREFCNT_dec((SV *)cfg);
                            croak("%s", SvPV_nolen(msg));
                        }
                        (void)hv_store(merged, k, (I32)kl,
                                       newSVsv(hv_iterval(given, fe)), 0);
                    }
                    (void)hv_stores(cfg, "fields",
                                    newRV_noinc((SV *)merged));
                }
            }
            {
                SV **it = hv_fetchs(cfg, "iterations", 0);
                if (it && *it && SvOK(*it) && SvIV(*it) <= 0) {
                    SvREFCNT_dec((SV *)cfg);
                    croak("Punk: auth iterations must be positive");
                }
            }
            (void)hv_store(h, K_AUTH, (I32)strlen(K_AUTH),
                           newRV_noinc((SV *)cfg), 0);
        }
        RETVAL = newSVsv(self);
    }
    OUTPUT:
        RETVAL

# auth_guard() / auth_guard(role => 'admin', verified => 1, on_denied =>
# '404'|'403'|coderef): a guard coderef for `under`. The bare form runs
# entirely in C. Croaks on unknown options.
SV *
auth_guard(self, ...)
        SV *self
    CODE:
    {
        HV *opts = newHV();
        AV *cap;
        int i;
        static const char *known[] = { "role", "verified", "on_denied" };
        if (items == 2 && SvROK(ST(1)) && SvTYPE(SvRV(ST(1))) == SVt_PVHV) {
            HE *e; HV *given = (HV *)SvRV(ST(1));
            hv_iterinit(given);
            while ((e = hv_iternext(given))) {
                STRLEN kl; const char *k = HePV(e, kl);
                (void)hv_store(opts, k, (I32)kl,
                               newSVsv(hv_iterval(given, e)), 0);
            }
        }
        else for (i = 1; i + 1 < items; i += 2) {
            STRLEN kl; const char *k = SvPV_const(ST(i), kl);
            (void)hv_store(opts, k, (I32)kl, newSVsv(ST(i + 1)), 0);
        }
        {
            HE *e;
            hv_iterinit(opts);
            while ((e = hv_iternext(opts))) {
                STRLEN kl; const char *k = HePV(e, kl);
                int ok = 0, j;
                for (j = 0; j < 3; j++)
                    if (strEQ(k, known[j])) { ok = 1; break; }
                if (!ok) {
                    SV *msg = sv_2mortal(newSVpvf(
                        "Punk: unknown auth_guard option '%.*s'",
                        (int)kl, k));
                    SvREFCNT_dec((SV *)opts);
                    croak("%s", SvPV_nolen(msg));
                }
            }
            {   /* on_denied is '403', '404' or a coderef - anything else is
                 * a typo croaking now, not a request-time surprise */
                SV **od = hv_fetchs(opts, "on_denied", 0);
                if (od && *od && SvOK(*od)) {
                    int fine = SvROK(*od)
                               && SvTYPE(SvRV(*od)) == SVt_PVCV;
                    if (!fine && !SvROK(*od)) {
                        STRLEN ol; const char *o = SvPV_const(*od, ol);
                        fine = ol == 3
                               && (memEQ(o, "403", 3) || memEQ(o, "404", 3));
                    }
                    if (!fine) {
                        SvREFCNT_dec((SV *)opts);
                        croak("Punk: auth_guard on_denied takes '403', "
                              "'404' or a coderef");
                    }
                }
            }
        }
        cap = newAV();
        av_push(cap, newSVsv(self));
        av_push(cap, newRV_noinc((SV *)opts));
        RETVAL = punk_closure(aTHX_ pauth_guard_cb, cap);
    }
    OUTPUT:
        RETVAL

# headers_scoped($prefix, \%pairs): the scope form of `headers`, reached via
# $scope->headers(...) rather than a DSL keyword. Recorded with the scope's
# accumulated prefix; to_app freezes the records longest-prefix-first, and
# the dispatcher applies them ahead of the application-wide policy for
# requests under the prefix. Chains.
SV *
headers_scoped(self, prefix, pairs)
        SV *self
        SV *prefix
        SV *pairs
    CODE:
    {
        HV *h = app_hv(aTHX_ self);
        HV *cfg = newHV();
        HV *rec;
        HE *e; HV *given;
        if (!(SvROK(pairs) && SvTYPE(SvRV(pairs)) == SVt_PVHV)) {
            SvREFCNT_dec((SV *)cfg);
            croak("Punk: headers_scoped takes a prefix and a hashref");
        }
        given = (HV *)SvRV(pairs);
        hv_iterinit(given);
        while ((e = hv_iternext(given))) {
            STRLEN kl; const char *k = HePV(e, kl);
            SV *v = hv_iterval(given, e);
            if (!kl || v == NULL) {
                SvREFCNT_dec((SV *)cfg);
                croak("Punk: headers needs header names as keys");
            }
            if (SvROK(v)) {
                SV *msg = sv_2mortal(newSVpvf(
                    "Punk: headers value for '%.*s' must be a string "
                    "(or undef to drop it here), not a reference",
                    (int)kl, k));
                SvREFCNT_dec((SV *)cfg);
                croak("%s", SvPV_nolen(msg));
            }
            (void)hv_store(cfg, k, (I32)kl, newSVsv(v), 0);
        }
        rec = newHV();
        (void)hv_stores(rec, K_PREFIX,
            SvOK(prefix) ? newSVsv(prefix) : newSVpvs(""));
        (void)hv_stores(rec, K_HEADERS, newRV_noinc((SV *)cfg));
        av_push(app_av(aTHX_ h, K_HEADERS_SCOPED), newRV_noinc((SV *)rec));
        RETVAL = newSVsv(self);
    }
    OUTPUT:
        RETVAL

# csrf(field => '_csrf', header => ..., keep => 1, ...) or csrf(\%opts):
# freeze the CSRF config on the app. The compiler installs the check and the
# mirror write-back, and croaks if there is no session for the token to live
# in. Chains.
SV *
csrf(self, ...)
        SV *self
    CODE:
    {
        HV *h = app_hv(aTHX_ self);
        HV *cfg = newHV();
        int i;
        (void)hv_stores(cfg, "field",    newSVpvs("_csrf"));
        (void)hv_stores(cfg, "header",   newSVpvs("X-CSRF-Token"));
        (void)hv_stores(cfg, "cookie",   newSVpvs("csrf"));
        (void)hv_stores(cfg, "keep",     newSViv(1));
        (void)hv_stores(cfg, "max_body", newSViv(65536));
        if (items == 2 && SvROK(ST(1)) && SvTYPE(SvRV(ST(1))) == SVt_PVHV) {
            HE *e; HV *given = (HV *)SvRV(ST(1));
            hv_iterinit(given);
            while ((e = hv_iternext(given))) {
                STRLEN kl; const char *k = HePV(e, kl);
                (void)hv_store(cfg, k, (I32)kl,
                               newSVsv(hv_iterval(given, e)), 0);
            }
        }
        else for (i = 1; i + 1 < items; i += 2) {
            STRLEN kl; const char *k = SvPV_const(ST(i), kl);
            (void)hv_store(cfg, k, (I32)kl, newSVsv(ST(i + 1)), 0);
        }
        /* `csrf 0` turns it back off */
        if (items == 2 && !SvROK(ST(1)) && !SvTRUE(ST(1))) {
            SvREFCNT_dec((SV *)cfg);
            (void)hv_delete(h, K_CSRF, (I32)strlen(K_CSRF), G_DISCARD);
        }
        else {
            (void)hv_store(h, K_CSRF, (I32)strlen(K_CSRF),
                           newRV_noinc((SV *)cfg), 0);
        }
        RETVAL = newSVsv(self);
    }
    OUTPUT:
        RETVAL

# ua(timeout => 10, ...) freezes the default agent's options; ua(name => \%opts)
# freezes a named one, the same shape `database` uses for a second database.
# Every key is passed to Fetch->new as given, so this is Fetch's own
# constructor surface and not a second vocabulary; the loop is supplied by
# punk_ua.h at build time. Purely declarative - no agent is built here, because
# one built before the fork would put every worker on the same sockets. Chains.
SV *
ua(self, ...)
        SV *self
    CODE:
    {
        HV *h   = app_hv(aTHX_ self);
        HV *uas = app_hash(aTHX_ h, K_UA);
        if (items == 3 && SvROK(ST(2)) && SvTYPE(SvRV(ST(2))) == SVt_PVHV) {
            STRLEN nl; const char *n = SvPV_const(ST(1), nl);
            (void)hv_store(uas, n, (I32)nl,
                newRV_noinc((SV *)newHVhv((HV *)SvRV(ST(2)))), 0);
        }
        else if (items == 2 && SvROK(ST(1)) && SvTYPE(SvRV(ST(1))) == SVt_PVHV) {
            (void)hv_stores(uas, K_DEFAULT,
                newRV_noinc((SV *)newHVhv((HV *)SvRV(ST(1)))));
        }
        else {
            HV *opts = newHV(); int i;
            if (!(items % 2))
                croak("Punk: ua takes a hashref, a list of pairs, or "
                      "a name and a hashref");
            for (i = 1; i + 1 < items; i += 2) {
                STRLEN kl; const char *k = SvPV_const(ST(i), kl);
                (void)hv_store(opts, k, (I32)kl, newSVsv(ST(i + 1)), 0);
            }
            (void)hv_stores(uas, K_DEFAULT, newRV_noinc((SV *)opts));
        }
        RETVAL = newSVsv(self);
    }
    OUTPUT:
        RETVAL

# session(secret => ..., expires => '7d', ...) or session(\%opts): freeze the
# session config on the app (the compiler installs the write-back hook). Chains.
SV *
session(self, ...)
        SV *self
    CODE:
    {
        HV *h = app_hv(aTHX_ self);
        HV *cfg = newHV();
        HV *given = NULL;
        int i;
        (void)hv_stores(cfg, "cookie",   newSVpvs("punk.sid"));
        (void)hv_stores(cfg, "path",     newSVpvs("/"));
        (void)hv_stores(cfg, "httponly", newSViv(1));
        (void)hv_stores(cfg, "samesite", newSVpvs("Lax"));
        if (items == 2 && SvROK(ST(1)) && SvTYPE(SvRV(ST(1))) == SVt_PVHV) {
            HE *e; given = (HV *)SvRV(ST(1));
            hv_iterinit(given);
            while ((e = hv_iternext(given))) {
                STRLEN kl; const char *k = HePV(e, kl); SV *v = hv_iterval(given, e);
                ps_check_key(aTHX_ k, kl, cfg);
                if (kl == 7 && memEQ(k, "expires", 7))
                    (void)hv_stores(cfg, "max_age", newSViv(ps_parse_duration(aTHX_ v)));
                else
                    (void)hv_store(cfg, k, (I32)kl, newSVsv(v), 0);
            }
        }
        else for (i = 1; i + 1 < items; i += 2) {
            STRLEN kl; const char *k = SvPV_const(ST(i), kl);
            ps_check_key(aTHX_ k, kl, cfg);
            if (kl == 7 && memEQ(k, "expires", 7))
                (void)hv_stores(cfg, "max_age",
                                newSViv(ps_parse_duration(aTHX_ ST(i + 1))));
            else
                (void)hv_store(cfg, k, (I32)kl, newSVsv(ST(i + 1)), 0);
        }
        /* A session cookie is only as good as the key it is signed with, and
         * an absent one used to mean an empty HMAC key: well-formed cookies
         * that round-tripped perfectly and that anyone who knew the format
         * could mint offline, carrying any user id or role the session holds.
         * Nothing about it looked wrong at runtime, which is what made it
         * worth failing on. So the keyword refuses to freeze a config it
         * cannot sign with, at boot, the way Punk::Session::_seal already
         * refused to seal one. */
        {
            SV **sp = hv_fetchs(cfg, "secret", 0);
            if (!sp || !*sp || !SvOK(*sp) || !SvCUR(*sp)) {
                SvREFCNT_dec((SV *)cfg);
                croak("Punk: `session` needs a non-empty secret - without one "
                      "the cookie is signed with an empty key and anyone can "
                      "forge it. Try `session secret => secret('session_key')"
                      "`, which fails closed when the key is missing");
            }
        }
        (void)hv_stores(h, "session", newRV_noinc((SV *)cfg));
        RETVAL = newSVsv(self);
    }
    OUTPUT:
        RETVAL

# logging(level => 'debug', format => 'json', to => ...) or logging(\%opts):
# freeze the logger config on the app (level/format/to). Chains.
SV *
logging(self, ...)
        SV *self
    CODE:
    {
        HV *h = app_hv(aTHX_ self);
        HV *cfg = newHV();
        int i;
        if (items == 2 && SvROK(ST(1)) && SvTYPE(SvRV(ST(1))) == SVt_PVHV) {
            HE *e; HV *g = (HV *)SvRV(ST(1));
            hv_iterinit(g);
            while ((e = hv_iternext(g))) {
                STRLEN kl; const char *k = HePV(e, kl);
                (void)hv_store(cfg, k, (I32)kl, newSVsv(hv_iterval(g, e)), 0);
            }
        }
        else for (i = 1; i + 1 < items; i += 2) {
            STRLEN kl; const char *k = SvPV_const(ST(i), kl);
            (void)hv_store(cfg, k, (I32)kl, newSVsv(ST(i + 1)), 0);
        }
        (void)hv_stores(h, "logging", newRV_noinc((SV *)cfg));
        RETVAL = newSVsv(self);
    }
    OUTPUT:
        RETVAL

# api($spec, $opts?, $scope?) -> a Punk::Mount::OpenAPI.
SV *
api(self, spec, opts = &PL_sv_undef, scope = &PL_sv_undef)
        SV *self
        SV *spec
        SV *opts
        SV *scope
    CODE:
    {
        HV *h = app_hv(aTHX_ self);
        SV *argv[8], *mount, *pfx, *grd;
        (void)pk_require_once(aTHX_ PK_MOUNT_OA, TRUE);
        if (SvOK(scope)) {
            pfx = pcx_call_meth(aTHX_ scope, K_PREFIX, NULL, 0, 1);
            grd = pcx_call_meth(aTHX_ scope, K_GUARDS, NULL, 0, 1);
        } else { pfx = newSVpvs(""); grd = newRV_noinc((SV *)newAV()); }
        argv[0] = sv_2mortal(newSVpvs("spec"));   argv[1] = spec;
        argv[2] = sv_2mortal(newSVpvs(K_OPTS));
        argv[3] = SvOK(opts) ? opts : sv_2mortal(newRV_noinc((SV *)newHV()));
        argv[4] = sv_2mortal(newSVpvs(K_PREFIX)); argv[5] = sv_2mortal(pfx);
        argv[6] = sv_2mortal(newSVpvs(K_GUARDS)); argv[7] = sv_2mortal(grd);
        mount = pcx_call_meth(aTHX_ sv_2mortal(newSVpvs(PK_MOUNT_OA)),
                              "new", argv, 8, 1);
        av_push(app_av(aTHX_ h, K_API_MOUNTS), mount ? mount : newSV(0));
        RETVAL = mount ? newSVsv(mount) : &PL_sv_undef;
    }
    OUTPUT:
        RETVAL

# docs($path, $mount?, $opts?): record a docs UI mount. Chains.
SV *
docs(self, path, mount = &PL_sv_undef, opts = &PL_sv_undef)
        SV *self
        SV *path
        SV *mount
        SV *opts
    CODE:
    {
        HV *h = app_hv(aTHX_ self);
        HV *rec = newHV();
        /* (mount, opts) = (undef, mount) if mount is a plain hashref and !opts
         * - a blessed mount object (ref ne 'HASH') is never the opts slot */
        if (SvROK(mount) && SvTYPE(SvRV(mount)) == SVt_PVHV
            && !SvOBJECT(SvRV(mount)) && !SvOK(opts)) {
            opts = mount; mount = &PL_sv_undef;
        }
        (void)hv_stores(rec, K_PATH,  newSVsv(path));
        (void)hv_stores(rec, K_MOUNT, newSVsv(mount));
        (void)hv_stores(rec, K_OPTS,
            (SvROK(opts) && SvTYPE(SvRV(opts)) == SVt_PVHV)
                ? newRV_noinc((SV *)newHVhv((HV *)SvRV(opts)))
                : newRV_noinc((SV *)newHV()));
        av_push(app_av(aTHX_ h, K_DOCS), newRV_noinc((SV *)rec));
        RETVAL = newSVsv(self);
    }
    OUTPUT:
        RETVAL

# static($prefix, $dir, %opts): serve files. The options are the mount's
# cache policy - max_age, cache_control, fingerprint - and reach
# Punk::Static->app at compile. Chains.
SV *
static(self, prefix, dir, ...)
        SV *self
        SV *prefix
        SV *dir
    CODE:
    {
        HV *h = app_hv(aTHX_ self);
        HV *rec = newHV();
        SV *pf = app_strip_slash(aTHX_ prefix);
        HV *opts = newHV();
        int i;
        if ((items - 3) % 2)
            croak("Punk: static takes a prefix, a directory and an "
                  "even-sized option list");
        for (i = 3; i + 1 < items; i += 2) {
            STRLEN kl;
            const char *kp = SvPV_const(ST(i), kl);
            (void)hv_store(opts, kp, (I32)kl, newSVsv(ST(i + 1)), 0);
        }
        (void)hv_stores(rec, K_PREFIX, pf);
        (void)hv_stores(rec, K_LEN,    newSViv((IV)SvCUR(pf)));
        (void)hv_stores(rec, K_DIR,    newSVsv(dir));
        (void)hv_stores(rec, K_OPTS,   newRV_noinc((SV *)opts));
        av_push(app_av(aTHX_ h, K_MOUNTS), newRV_noinc((SV *)rec));
        RETVAL = newSVsv(self);
    }
    OUTPUT:
        RETVAL

# markdown($prefix, $dir, %opts): serve a directory of markdown as a
# documentation site. Rides the same mount table static does, so prefix
# dispatch and longest-prefix ordering come free; compile turns the record
# into a Punk::Mount::Markdown app. Chains.
SV *
markdown(self, prefix, dir, ...)
        SV *self
        SV *prefix
        SV *dir
    CODE:
    {
        HV *h = app_hv(aTHX_ self);
        HV *rec = newHV();
        SV *pf = app_strip_slash(aTHX_ prefix);
        HV *opts = newHV();
        int i;
        if ((items - 3) % 2)
            croak("Punk: markdown takes a prefix, a directory and "
                  "an even-sized option list");
        for (i = 3; i + 1 < items; i += 2) {
            STRLEN kl;
            const char *kp = SvPV_const(ST(i), kl);
            (void)hv_store(opts, kp, (I32)kl, newSVsv(ST(i + 1)), 0);
        }
        (void)hv_stores(rec, K_PREFIX, pf);
        (void)hv_stores(rec, K_LEN,    newSViv((IV)SvCUR(pf)));
        (void)hv_stores(rec, K_MD_DIR, newSVsv(dir));
        (void)hv_stores(rec, K_OPTS,   newRV_noinc((SV *)opts));
        av_push(app_av(aTHX_ h, K_MOUNTS), newRV_noinc((SV *)rec));
        RETVAL = newSVsv(self);
    }
    OUTPUT:
        RETVAL

# mount($prefix, $psgi_app): mount a PSGI coderef. Chains.
SV *
mount(self, prefix, app)
        SV *self
        SV *prefix
        SV *app
    CODE:
    {
        HV *h = app_hv(aTHX_ self);
        HV *rec; SV *pf;
        if (!(SvROK(app) && SvTYPE(SvRV(app)) == SVt_PVCV))
            croak("Punk: mount needs a PSGI coderef");
        rec = newHV();
        pf = app_strip_slash(aTHX_ prefix);
        (void)hv_stores(rec, K_PREFIX, pf);
        (void)hv_stores(rec, K_LEN,    newSViv((IV)SvCUR(pf)));
        (void)hv_stores(rec, K_APP,    newSVsv(app));
        av_push(app_av(aTHX_ h, K_MOUNTS), newRV_noinc((SV *)rec));
        RETVAL = newSVsv(self);
    }
    OUTPUT:
        RETVAL

# views($name, $opts?): register a view engine. Chains.
SV *
views(self, name, opts = &PL_sv_undef)
        SV *self
        SV *name
        SV *opts
    CODE:
    {
        HV *h = app_hv(aTHX_ self);
        AV *pair = newAV();
        av_push(pair, newSVsv(name));
        av_push(pair, (SvROK(opts) && SvTYPE(SvRV(opts)) == SVt_PVHV)
            ? newRV_noinc((SV *)newHVhv((HV *)SvRV(opts)))
            : newRV_noinc((SV *)newHV()));
        av_push(app_av(aTHX_ h, K_VIEWS), newRV_noinc((SV *)pair));
        RETVAL = newSVsv(self);
    }
    OUTPUT:
        RETVAL

# database(dsn => ... | $name => \%opts): configure a database. Chains.
SV *
database(self, ...)
        SV *self
    CODE:
    {
        HV *h  = app_hv(aTHX_ self);
        HV *db = app_hash(aTHX_ h, K_DATABASES);
        if (items == 3 && SvROK(ST(2)) && SvTYPE(SvRV(ST(2))) == SVt_PVHV) {
            STRLEN nl; const char *n = SvPV_const(ST(1), nl);
            (void)hv_store(db, n, (I32)nl,
                newRV_noinc((SV *)newHVhv((HV *)SvRV(ST(2)))), 0);
        }
        else {
            HV *opts = newHV(); int i;
            for (i = 1; i + 1 < items; i += 2) {
                STRLEN kl; const char *k = SvPV_const(ST(i), kl);
                (void)hv_store(opts, k, (I32)kl, newSVsv(ST(i + 1)), 0);
            }
            (void)hv_stores(db, K_DEFAULT, newRV_noinc((SV *)opts));
        }
        RETVAL = newSVsv(self);
    }
    OUTPUT:
        RETVAL

# model_class(@names): register model names. Bare `model;` turns
# auto-discovery on explicitly - load everything under ${caller}::Model:: -
# which also survives alongside named registrations (naming a model
# normally switches auto off). Chains.
SV *
model_class(self, ...)
        SV *self
    CODE:
    {
        HV *h = app_hv(aTHX_ self);
        AV *m = app_av(aTHX_ h, K_MODELS);
        int i;
        if (items == 1)
            (void)hv_stores(h, K_MODEL_AUTO, newSViv(1));
        else
            for (i = 1; i < items; i++) av_push(m, newSVsv(ST(i)));
        RETVAL = newSVsv(self);
    }
    OUTPUT:
        RETVAL

# model_auto($on?): get/set the auto-discovery flag.
SV *
model_auto(self, on = NULL)
        SV *self
        SV *on
    CODE:
    {
        HV *h = app_hv(aTHX_ self);
        if (!on) {
            SV *v = app_get(aTHX_ h, K_MODEL_AUTO);
            RETVAL = newSViv((v && SvOK(v)) ? (SvTRUE(v) ? 1 : 0) : 1);
        }
        else {
            (void)hv_stores(h, K_MODEL_AUTO, newSViv(SvTRUE(on) ? 1 : 0));
            RETVAL = newSVsv(self);
        }
    }
    OUTPUT:
        RETVAL

# hook($name, $code): add a before/after_dispatch hook. Chains.
SV *
hook(self, name, code)
        SV *self
        SV *name
        SV *code
    CODE:
    {
        HV *h = app_hv(aTHX_ self);
        HV *hooks = app_hash(aTHX_ h, K_HOOKS);
        STRLEN nl; const char *n = SvPV_const(name, nl);
        SV **slot = hv_fetch(hooks, n, (I32)nl, 0);
        if (!(slot && *slot && SvROK(*slot) && SvTYPE(SvRV(*slot)) == SVt_PVAV))
            croak("Punk: unknown hook '%s' "
                  "(before_request, before_dispatch, after_dispatch)", n);
        av_push((AV *)SvRV(*slot), newSVsv(code));
        RETVAL = newSVsv(self);
    }
    OUTPUT:
        RETVAL

# middleware($code): add an outer PSGI wrap. Chains.
SV *
middleware(self, code)
        SV *self
        SV *code
    CODE:
        av_push(app_av(aTHX_ app_hv(aTHX_ self), K_MIDDLEWARE), newSVsv(code));
        RETVAL = newSVsv(self);
    OUTPUT:
        RETVAL

# on_error($code): set the error handler. Chains.
SV *
on_error(self, code)
        SV *self
        SV *code
    CODE:
        (void)hv_stores(app_hv(aTHX_ self), K_ON_ERROR, newSVsv(code));
        RETVAL = newSVsv(self);
    OUTPUT:
        RETVAL

# on_not_found($code): set the 404 handler - same contract as on_error, a
# reference return becomes the response. Chains.
SV *
on_not_found(self, code)
        SV *self
        SV *code
    CODE:
        (void)hv_stores(app_hv(aTHX_ self), K_ON_NOT_FOUND, newSVsv(code));
        RETVAL = newSVsv(self);
    OUTPUT:
        RETVAL

# helper($name, $code, $owner?): install a context helper. Chains.
SV *
helper(self, name, code, owner = &PL_sv_undef)
        SV *self
        SV *name
        SV *code
        SV *owner
    CODE:
    {
        HV *h = app_hv(aTHX_ self);
        HV *helpers = app_hash(aTHX_ h, K_HELPERS);
        STRLEN nl; const char *n = SvPV_const(name, nl);
        HV *ctxstash = gv_stashpvs(PK_CONTEXT, 0);
        SV **have; HV *rec;
        if (ctxstash && gv_fetchmethod_autoload(ctxstash, n, 0))
            croak("Punk: helper '%s' collides with a Punk::Context method", n);
        have = hv_fetch(helpers, n, (I32)nl, 0);
        if (have && *have && SvROK(*have)) {
            SV **o = hv_fetchs((HV *)SvRV(*have), K_OWNER, 0);
            croak("Punk: helper '%s' is registered by both %s and %s", n,
                  (o && *o) ? SvPV_nolen(*o) : "?",
                  SvOK(owner) ? SvPV_nolen(owner)
                              : CopSTASHPV(PL_curcop));
        }
        rec = newHV();
        (void)hv_stores(rec, K_CODE, newSVsv(code));
        (void)hv_stores(rec, K_OWNER,
            SvOK(owner) ? newSVsv(owner) : newSVpv(CopSTASHPV(PL_curcop), 0));
        (void)hv_store(helpers, n, (I32)nl, newRV_noinc((SV *)rec), 0);
        RETVAL = newSVsv(self);
    }
    OUTPUT:
        RETVAL

# install_kw($name, $code, $owner?): install a declaration keyword into the
# application class - the supported way for a plugin to add to the DSL, so
# nothing has to assign to a glob. Chains.
#
# The keyword is a magic CV forwarding to $code in the caller's context
# (punk_import.h). Installing the same name from the same owner twice is a
# no-op - a plugin that installs from both its import and its register is
# doing the ordinary thing - and two owners claiming one name croak, naming
# both, exactly as helper does.
SV *
install_kw(self, name, code, owner = &PL_sv_undef)
        SV *self
        SV *name
        SV *code
        SV *owner
    CODE:
    {
        HV *h = app_hv(aTHX_ self);
        HV *kws = app_hash(aTHX_ h, K_KEYWORDS);
        SV *caller = app_get(aTHX_ h, K_CALLER);
        STRLEN nl; const char *n = SvPV_const(name, nl);
        SV *own = SvOK(owner) ? owner
                : sv_2mortal(newSVpv(CopSTASHPV(PL_curcop), 0));
        SV **have; HV *rec; int done = 0;

        if (!caller || !SvOK(caller))
            croak("Punk: install_kw('%s') needs an application class", n);
        if (!nl || !SvROK(code) || SvTYPE(SvRV(code)) != SVt_PVCV)
            croak("Punk: install_kw needs a name and a code reference");
        if (pki_is_dsl(n))
            croak("Punk: keyword '%s' is part of the Punk DSL", n);

        have = hv_fetch(kws, n, (I32)nl, 0);
        if (have && *have && SvROK(*have)) {
            SV **o = hv_fetchs((HV *)SvRV(*have), K_OWNER, 0);
            if (o && *o && sv_eq(*o, own)) done = 1;      /* the same owner */
            else croak("Punk: keyword '%s' is installed by both %s and %s", n,
                       (o && *o) ? SvPV_nolen(*o) : "?", SvPV_nolen(own));
        }
        if (!done) {
            rec = newHV();
            (void)hv_stores(rec, K_CODE,  newSVsv(code));
            (void)hv_stores(rec, K_OWNER, newSVsv(own));
            (void)hv_store(kws, n, (I32)nl, newRV_noinc((SV *)rec), 0);
            pki_install_kw(aTHX_ caller, name, code);
        }
        RETVAL = newSVsv(self);
    }
    OUTPUT:
        RETVAL

# plugin($name, $opts?): load and register a plugin. Chains.
SV *
plugin(self, name, opts = &PL_sv_undef)
        SV *self
        SV *name
        SV *opts
    CODE:
    {
        STRLEN nl; const char *n = SvPV_const(name, nl);
        int plus = (nl > 0 && n[0] == '+');
        SV *classsv = plus ? newSVpvn(n + 1, nl - 1)
                           : newSVpvf("Punk::Plugin::%.*s", (int)nl, n);
        STRLEN cl; const char *class = SvPV_const(classsv, cl);
        HV *stash = gv_stashpvn(class, cl, 0);
        SV *p, *argv[2], *r;
        sv_2mortal(classsv);
        if (!(stash && gv_fetchmethod_autoload(stash, "register", 0))) {
            SV *req = sv_2mortal(newSVpvf("require %s; 1;", class));
            eval_sv(req, G_SCALAR);
            if (SvTRUE(ERRSV))
                croak("Punk: plugin '%s' (%s) failed to load: %s",
                      n, class, SvPV_nolen(ERRSV));
            stash = gv_stashpvn(class, cl, 0);
        }
        p = (stash && gv_fetchmethod_autoload(stash, "new", 0))
            ? sv_2mortal(pcx_call_meth(aTHX_ classsv, "new", NULL, 0, 1))
            : classsv;
        argv[0] = self;
        argv[1] = SvOK(opts) ? opts : sv_2mortal(newRV_noinc((SV *)newHV()));
        r = pcx_call_meth(aTHX_ p, "register", argv, 2, 1);
        if (r) SvREFCNT_dec(r);
        RETVAL = newSVsv(self);
    }
    OUTPUT:
        RETVAL

# config(): with no args, the loaded config data (or undef). With args -
# a file and/or options - load Punk::Config and apply the DSL blocks now.
SV *
config(self, ...)
        SV *self
    CODE:
    {
        HV *h = app_hv(aTHX_ self);
        if (items <= 1) {
            SV *cfg = app_get(aTHX_ h, K_CONFIG);
            if (cfg && SvOK(cfg)) {
                SV *r = pcx_call_meth(aTHX_ cfg, K_CONFIG, NULL, 0, 1);
                RETVAL = r ? r : &PL_sv_undef;
            }
            else RETVAL = &PL_sv_undef;
        }
        else {
            int argc = items - 1, odd = argc % 2, i, m;
            SV **av2, *cfg, *aa[1];
            (void)pk_require_once(aTHX_ PK_CONFIG, TRUE);
            /* config $file => %opts  ==>  (file => $file, %opts) */
            m = odd ? argc + 1 : argc;
            Newx(av2, m, SV *);
            if (odd) {
                av2[0] = sv_2mortal(newSVpvs("file"));
                for (i = 1; i < items; i++) av2[i] = ST(i);
            }
            else for (i = 1; i < items; i++) av2[i - 1] = ST(i);
            cfg = pcx_call_meth(aTHX_ sv_2mortal(newSVpvs(PK_CONFIG)),
                                "load", av2, m, 1);
            Safefree(av2);
            (void)hv_stores(h, K_CONFIG, cfg ? cfg : newSV(0));
            aa[0] = cfg ? cfg : &PL_sv_undef;
            { SV *r = pcx_call_meth(aTHX_ self, "_apply_config", aa, 1, 0);
              if (r) SvREFCNT_dec(r); }
            RETVAL = newSVsv(self);
        }
    }
    OUTPUT:
        RETVAL

# secret($path): a resolved secret from the loaded config.
SV *
secret(self, path)
        SV *self
        SV *path
    CODE:
    {
        SV *cfg = app_get(aTHX_ app_hv(aTHX_ self), K_CONFIG);
        SV *argv[1], *r;
        if (!(cfg && SvOK(cfg)))
            croak("Punk: no configuration loaded (add a config keyword)");
        argv[0] = path;
        r = pcx_call_meth(aTHX_ cfg, "secret", argv, 1, 1);
        RETVAL = r ? r : &PL_sv_undef;
    }
    OUTPUT:
        RETVAL

# _apply_config($cfg): register the DSL blocks a config file carries
# (views, database, models, plugins, static), in that order.
SV *
_apply_config(self, cfg)
        SV *self
        SV *cfg
    CODE:
    {
        HV *h = app_hv(aTHX_ self);
        SV *resolved = pcx_call_meth(aTHX_ cfg, "resolved", NULL, 0, 1);
        HV *c;
        if (resolved) sv_2mortal(resolved);
        c = (resolved && SvROK(resolved) && SvTYPE(SvRV(resolved)) == SVt_PVHV)
            ? (HV *)SvRV(resolved) : NULL;
        if (c) {
            SV **vp = hv_fetchs(c, K_VIEWS, 0);
            SV **dp = hv_fetchs(c, "database", 0);
            SV **mp = hv_fetchs(c, K_MODELS, 0);
            SV **pp = hv_fetchs(c, "plugins", 0);
            SV **sp = hv_fetchs(c, "static", 0);
            SSize_t i, n;

            /* views: engine => opts, in declaration order */
            if (vp && *vp && SvTRUE(*vp)) {
                AV *pairs = app_pairs(aTHX_ *vp, K_VIEWS);
                n = av_len(pairs) + 1;
                for (i = 0; i < n; i++) {
                    SV **pr = av_fetch(pairs, i, 0);
                    app_call_list(aTHX_ self, K_VIEWS, (AV *)SvRV(*pr));
                }
            }

            /* database: one default block, or a mapping of named blocks */
            if (dp && *dp && SvTRUE(*dp)) {
                HV *db; int named = 0; HE *e;
                if (!(SvROK(*dp) && SvTYPE(SvRV(*dp)) == SVt_PVHV))
                    croak("Punk: the config database block must be a mapping");
                db = (HV *)SvRV(*dp);
                hv_iterinit(db);
                while ((e = hv_iternext(db))) {
                    SV *v = hv_iterval(db, e);
                    if (SvROK(v) && SvTYPE(SvRV(v)) == SVt_PVHV
                        && !SvOBJECT(SvRV(v))) { named = 1; break; }
                }
                if (named) {
                    AV *keys = app_sorted_keys(aTHX_ db);
                    n = av_len(keys) + 1;
                    for (i = 0; i < n; i++) {
                        SV **kp = av_fetch(keys, i, 0);
                        STRLEN kl; const char *k = SvPV_const(*kp, kl);
                        SV **vp2 = hv_fetch(db, k, (I32)kl, 0);
                        HV *opt = (vp2 && *vp2 && SvROK(*vp2)) ?
                                  (HV *)SvRV(*vp2) : NULL;
                        if (kl == 7 && memEQ(k, K_DEFAULT, 7)) {
                            AV *args = (AV *)sv_2mortal((SV *)newAV());
                            if (opt) {
                                HE *oe; hv_iterinit(opt);
                                while ((oe = hv_iternext(opt))) {
                                    av_push(args, newSVsv(hv_iterkeysv(oe)));
                                    av_push(args, newSVsv(hv_iterval(opt, oe)));
                                }
                            }
                            app_call_list(aTHX_ self, "database", args);
                        }
                        else {
                            AV *args = (AV *)sv_2mortal((SV *)newAV());
                            av_push(args, newSVsv(*kp));
                            av_push(args, newSVsv(*vp2));
                            app_call_list(aTHX_ self, "database", args);
                        }
                    }
                }
                else {
                    AV *args = (AV *)sv_2mortal((SV *)newAV());
                    HE *oe; hv_iterinit(db);
                    while ((oe = hv_iternext(db))) {
                        av_push(args, newSVsv(hv_iterkeysv(oe)));
                        av_push(args, newSVsv(hv_iterval(db, oe)));
                    }
                    app_call_list(aTHX_ self, "database", args);
                }
            }

            /* models: auto | none | [names] | { auto=>?, only=>[names] } */
            if (mp && *mp && SvOK(*mp)) {
                SV *m = *mp;
                if (SvROK(m) && SvTYPE(SvRV(m)) == SVt_PVHV
                    && !SvOBJECT(SvRV(m))) {
                    HV *mh = (HV *)SvRV(m);
                    SV **au = hv_fetchs(mh, K_AUTO, 0);
                    SV **only = hv_fetchs(mh, K_ONLY, 0);
                    if (au)
                        (void)hv_stores(h, K_MODEL_AUTO,
                                        newSViv(SvTRUE(*au) ? 1 : 0));
                    if (only && *only && SvTRUE(*only))
                        app_call_list(aTHX_ self, "model_class",
                                      app_list(aTHX_ *only, "models.only"));
                }
                else if (!SvROK(m)) {
                    STRLEN ml; const char *ms = SvPV_const(m, ml);
                    if (ml == 4 && strncasecmp(ms, K_AUTO, 4) == 0)
                        (void)hv_stores(h, K_MODEL_AUTO, newSViv(1));
                    else if (ml == 4 && strncasecmp(ms, "none", 4) == 0)
                        (void)hv_stores(h, K_MODEL_AUTO, newSViv(0));
                    else
                        app_call_list(aTHX_ self, "model_class",
                                      app_list(aTHX_ m, K_MODELS));
                }
                else {
                    app_call_list(aTHX_ self, "model_class",
                                  app_list(aTHX_ m, K_MODELS));
                }
            }

            /* plugins: name => opts */
            if (pp && *pp && SvTRUE(*pp)) {
                AV *pairs = app_pairs(aTHX_ *pp, "plugins");
                n = av_len(pairs) + 1;
                for (i = 0; i < n; i++) {
                    SV **pr = av_fetch(pairs, i, 0);
                    app_call_list(aTHX_ self, "plugin", (AV *)SvRV(*pr));
                }
            }

            /* static: url prefix => directory */
            if (sp && *sp && SvTRUE(*sp)) {
                HV *st; AV *keys;
                if (!(SvROK(*sp) && SvTYPE(SvRV(*sp)) == SVt_PVHV))
                    croak("Punk: the config static block must be a mapping "
                          "of url prefix => directory");
                st = (HV *)SvRV(*sp);
                keys = app_sorted_keys(aTHX_ st);
                n = av_len(keys) + 1;
                for (i = 0; i < n; i++) {
                    SV **kp = av_fetch(keys, i, 0);
                    STRLEN kl; const char *k = SvPV_const(*kp, kl);
                    SV **dv = hv_fetch(st, k, (I32)kl, 0);
                    AV *args = (AV *)sv_2mortal((SV *)newAV());
                    av_push(args, newSVsv(*kp));
                    av_push(args, newSVsv((dv && *dv) ? *dv : &PL_sv_undef));
                    app_call_list(aTHX_ self, "static", args);
                }
            }

            /* session: a mapping of options -> the session keyword */
            {
                SV **sess = hv_fetchs(c, "session", 0);
                if (sess && *sess && SvROK(*sess)
                    && SvTYPE(SvRV(*sess)) == SVt_PVHV) {
                    HV *sh = (HV *)SvRV(*sess); HE *e;
                    AV *args = (AV *)sv_2mortal((SV *)newAV());
                    hv_iterinit(sh);
                    while ((e = hv_iternext(sh))) {
                        av_push(args, newSVsv(hv_iterkeysv(e)));
                        av_push(args, newSVsv(hv_iterval(sh, e)));
                    }
                    app_call_list(aTHX_ self, "session", args);
                }
            }

            /* ua: a mapping of options -> the ua keyword, so an outbound
             * timeout or a base header set is deployment configuration and
             * a token can arrive as { $env: ... } like any other secret.
             * A value that is itself a mapping names a second agent, the way
             * `databases` does; a scalar is an option on the default one. */
            {
                SV **u = hv_fetchs(c, K_UA, 0);
                if (u && *u && SvROK(*u) && SvTYPE(SvRV(*u)) == SVt_PVHV) {
                    HV *uh = (HV *)SvRV(*u); HE *e;
                    AV *dflt = (AV *)sv_2mortal((SV *)newAV());
                    AV *named = (AV *)sv_2mortal((SV *)newAV());
                    hv_iterinit(uh);
                    while ((e = hv_iternext(uh))) {
                        SV *k = hv_iterkeysv(e);
                        SV *v = hv_iterval(uh, e);
                        STRLEN kl; const char *kp = SvPV_const(k, kl);
                        if (SvROK(v) && SvTYPE(SvRV(v)) == SVt_PVHV
                            && !pua_is_known_opt(aTHX_ kp, kl)) {
                            av_push(named, newSVsv(k));
                            av_push(named, newSVsv(v));
                        }
                        else {
                            av_push(dflt, newSVsv(k));
                            av_push(dflt, newSVsv(v));
                        }
                    }
                    if (av_len(dflt) >= 0)
                        app_call_list(aTHX_ self, "ua", dflt);
                    {
                        SSize_t j, nn = av_len(named) + 1;
                        for (j = 0; j + 1 < nn; j += 2) {
                            AV *one = (AV *)sv_2mortal((SV *)newAV());
                            SV **kk = av_fetch(named, j, 0);
                            SV **vv = av_fetch(named, j + 1, 0);
                            av_push(one, newSVsv(*kk));
                            av_push(one, newSVsv(*vv));
                            app_call_list(aTHX_ self, "ua", one);
                        }
                    }
                }
            }

            /* csrf: a mapping of options -> the csrf keyword. `csrf: false`
             * (or absent) leaves it off. */
            {
                SV **cs = hv_fetchs(c, K_CSRF, 0);
                if (cs && *cs && SvROK(*cs)
                    && SvTYPE(SvRV(*cs)) == SVt_PVHV) {
                    HV *ch = (HV *)SvRV(*cs); HE *e;
                    AV *args = (AV *)sv_2mortal((SV *)newAV());
                    hv_iterinit(ch);
                    while ((e = hv_iternext(ch))) {
                        av_push(args, newSVsv(hv_iterkeysv(e)));
                        av_push(args, newSVsv(hv_iterval(ch, e)));
                    }
                    app_call_list(aTHX_ self, K_CSRF, args);
                }
                else if (cs && *cs && !SvROK(*cs) && SvTRUE(*cs)) {
                    app_call_list(aTHX_ self, K_CSRF,
                                  (AV *)sv_2mortal((SV *)newAV()));
                }
            }

            /* cors: a mapping of options, or `cors: true` for the bare form */
            {
                SV **co = hv_fetchs(c, K_CORS, 0);
                if (co && *co && SvROK(*co)
                    && SvTYPE(SvRV(*co)) == SVt_PVHV) {
                    HV *oh = (HV *)SvRV(*co); HE *e;
                    AV *args = (AV *)sv_2mortal((SV *)newAV());
                    hv_iterinit(oh);
                    while ((e = hv_iternext(oh))) {
                        av_push(args, newSVsv(hv_iterkeysv(e)));
                        av_push(args, newSVsv(hv_iterval(oh, e)));
                    }
                    app_call_list(aTHX_ self, K_CORS, args);
                }
                else if (co && *co && !SvROK(*co) && SvTRUE(*co)) {
                    app_call_list(aTHX_ self, K_CORS,
                                  (AV *)sv_2mortal((SV *)newAV()));
                }
            }

            /* headers: a mapping of header names, or `headers: true` for the
             * bare default set */
            {
                SV **hd = hv_fetchs(c, K_HEADERS, 0);
                if (hd && *hd && SvROK(*hd)
                    && SvTYPE(SvRV(*hd)) == SVt_PVHV) {
                    HV *oh = (HV *)SvRV(*hd); HE *e;
                    AV *args = (AV *)sv_2mortal((SV *)newAV());
                    hv_iterinit(oh);
                    while ((e = hv_iternext(oh))) {
                        av_push(args, newSVsv(hv_iterkeysv(e)));
                        av_push(args, newSVsv(hv_iterval(oh, e)));
                    }
                    app_call_list(aTHX_ self, K_HEADERS, args);
                }
                else if (hd && *hd && !SvROK(*hd) && SvTRUE(*hd)) {
                    app_call_list(aTHX_ self, K_HEADERS,
                                  (AV *)sv_2mortal((SV *)newAV()));
                }
            }

            /* auth: a mapping of options -> the auth keyword */
            {
                SV **at = hv_fetchs(c, K_AUTH, 0);
                if (at && *at && SvROK(*at)
                    && SvTYPE(SvRV(*at)) == SVt_PVHV) {
                    HV *oh = (HV *)SvRV(*at); HE *e;
                    AV *args = (AV *)sv_2mortal((SV *)newAV());
                    hv_iterinit(oh);
                    while ((e = hv_iternext(oh))) {
                        av_push(args, newSVsv(hv_iterkeysv(e)));
                        av_push(args, newSVsv(hv_iterval(oh, e)));
                    }
                    app_call_list(aTHX_ self, K_AUTH, args);
                }
            }

            /* logging: a mapping of options -> the logging keyword */
            {
                SV **lgc = hv_fetchs(c, "logging", 0);
                if (lgc && *lgc && SvROK(*lgc) && SvTYPE(SvRV(*lgc)) == SVt_PVHV) {
                    HV *gh = (HV *)SvRV(*lgc); HE *e;
                    AV *args = (AV *)sv_2mortal((SV *)newAV());
                    hv_iterinit(gh);
                    while ((e = hv_iternext(gh))) {
                        av_push(args, newSVsv(hv_iterkeysv(e)));
                        av_push(args, newSVsv(hv_iterval(gh, e)));
                    }
                    app_call_list(aTHX_ self, "logging", args);
                }
            }
        }
        RETVAL = newSVsv(self);
    }
    OUTPUT:
        RETVAL

# cache - the store, or stores, this application uses.
#
#     cache 'file', dir => '/var/cache/app';        # the default store
#     cache sessions => { backend => 'memory', max_bytes => '64M' };
#
# A NAME with a hashref declares a named store, exactly as `ua` and `views`
# do; anything else configures the default one. Named stores matter because a
# session cache and a rendered-page cache want different budgets, different
# backends and different lifetimes, and sharing one store means the big cold
# thing evicts the small hot thing.
#
# Recorded here and built at to_app, where a bad backend name, an unparseable
# max_bytes or an unwritable directory croak at BOOT. A cache that fails on
# its first miss fails at three in the morning; one that fails at boot fails
# in front of whoever deployed it.
SV *
cache(self, ...)
        SV *self
    CODE:
    {
        HV *h      = app_hv(aTHX_ self);
        HV *stores = app_hash(aTHX_ h, "cache_spec");
        AV *rec    = newAV();
        HV *opt    = newHV();
        const char *name = K_DEFAULT;
        STRLEN nlen = sizeof(K_DEFAULT) - 1;
        int i, first = 1;

        if (items >= 3 && SvROK(ST(2)) && SvTYPE(SvRV(ST(2))) == SVt_PVHV) {
            /* cache $name => \%opts */
            HV *given = (HV *)SvRV(ST(2));
            HE *e;
            name = SvPV_const(ST(1), nlen);
            hv_iterinit(given);
            while ((e = hv_iternext(given)))
                (void)hv_store_ent(opt, hv_iterkeysv(e), newSVsv(HeVAL(e)), 0);
            first = items;                      /* nothing left to scan */
        }
        else if (items >= 2) {
            /* The backend: a name, or a ready-made object. Taking a ref here
             * as well matters - the earlier form ignored one, so `cache
             * $store` recorded no backend at all and quietly built a file
             * cache instead of the object it was handed. */
            av_push(rec, newSVsv(ST(1)));
            first = 2;
        }

        for (i = first; i + 1 < items; i += 2) {
            STRLEN kl;
            const char *k = SvPV_const(ST(i), kl);
            (void)hv_store(opt, k, (I32)kl, newSVsv(ST(i + 1)), 0);
        }

        if (av_len(rec) < 0) {          /* empty: av_len is -1, not 0 */
            /* a named store names its backend inside the hashref */
            SV **b = hv_fetchs(opt, "backend", 0);
            av_push(rec, (b && *b && SvOK(*b)) ? newSVsv(*b)
                                               : newSVpvs("file"));
        }
        av_push(rec, newRV_noinc((SV *)opt));
        (void)hv_store(stores, name, (I32)nlen, newRV_noinc((SV *)rec), 0);
        RETVAL = newSVsv(self);
    }
    OUTPUT:
        RETVAL

# upload_dir($path): where a large multipart part is spilled while the request
# runs.
#
# Worth naming rather than defaulting, for two reasons that are not obvious:
# it decides the FILESYSTEM, which decides whether Punk::Upload::save is a
# rename or another whole copy of a large file; and it decides what shares a
# filesystem with attacker-controlled bytes.
SV *
upload_dir(self, path)
        SV *self
        SV *path
    CODE:
    {
        HV *h = app_hv(aTHX_ self);
        if (!SvOK(path) || !SvCUR(path))
            croak("Punk: upload_dir needs a directory");
        (void)hv_stores(h, "upload_dir", newSVsv(path));
        RETVAL = newSVsv(self);
    }
    OUTPUT:
        RETVAL

# ---- the cross-worker bus, at the application level -------------------------
#
# The same two calls the context has. They live here as well because the place
# to REGISTER a subscription is where the application is built - at boot, in
# the parent, before the server forks - and at that point there is no context
# to hang them off. A subscription made inside a request would land in one
# worker and last as long as that process, which is the fault the bus exists
# to fix.

IV
publish(self, topic, payload)
        SV *self
        SV *topic
        SV *payload
    CODE:
        PERL_UNUSED_VAR(self);
        RETVAL = punk_bus_app_publish(aTHX_ topic, payload);
    OUTPUT:
        RETVAL

IV
subscribe(self, topic, cb, ...)
        SV *self
        SV *topic
        SV *cb
    CODE:
    {
        SV *group = &PL_sv_undef;
        int i;
        PERL_UNUSED_VAR(self);
        for (i = 3; i + 1 < items; i += 2) {
            const char *k = SvPV_nolen(ST(i));
            if (strEQ(k, "group")) group = ST(i + 1);
        }
        RETVAL = punk_bus_app_subscribe(aTHX_ topic, cb, group);
    }
    OUTPUT:
        RETVAL
