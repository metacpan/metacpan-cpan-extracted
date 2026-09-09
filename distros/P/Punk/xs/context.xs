MODULE = Punk        PACKAGE = Punk::Context

PROTOTYPES: DISABLE

# The per-request context, in C (punk_context.h): the whole class lives here -
# the constructor, the plain slot accessors and the methods. lib/Punk/Context.pm
# is documentation only.

# Fast per-request constructor: bless an AV with just the slots the dispatcher
# fills (env, app, match); req/res/stash/openapi stay unset (lazy).
SV *
_build(class, env, app, match)
        SV *class
        SV *env
        SV *app
        SV *match
    CODE:
    {
        AV *av = newAV();
        av_extend(av, PCX_MATCH);
        (void)av_store(av, PCX_ENV,   newSVsv(env));
        (void)av_store(av, PCX_APP,   newSVsv(app));
        (void)av_store(av, PCX_MATCH, newSVsv(match));
        RETVAL = sv_bless(newRV_noinc((SV *)av), gv_stashsv(class, GV_ADD));
    }
    OUTPUT:
        RETVAL

# ---- slot accessors ----------------------------------------------------------

# The plain read/write accessors. The ALIAS index is the position in pcx_slots
# below, not the slot number itself - keeping the mapping explicit means the
# enum in punk_context.h can be reordered without silently rewiring these.
SV *
env(self, ...)
        SV *self
    ALIAS:
        app            = 1
        _req           = 2
        _res           = 3
        stash_hv       = 4
        openapi_params = 5
        match          = 6
    CODE:
    {
        static const I32 pcx_slots[] = {
            PCX_ENV, PCX_APP, PCX_REQ, PCX_RES,
            PCX_STASH, PCX_OPENAPI, PCX_MATCH
        };
        AV *av = pcx_av(aTHX_ self);
        I32 slot = pcx_slots[ix];
        SV **e;
        if (items > 1) (void)av_store(av, slot, newSVsv(ST(1)));
        e = av_fetch(av, slot, 0);
        RETVAL = (e && *e) ? newSVsv(*e) : newSV(0);
    }
    OUTPUT:
        RETVAL

# ---- lazy sub-objects --------------------------------------------------------

SV *
req(self)
        SV *self
    CODE:
    {
        AV *av = pcx_av(aTHX_ self);
        RETVAL = newSVsv(pcx_force(aTHX_ av, PCX_REQ, "Punk::Request",
                                   pcx_get(aTHX_ av, PCX_ENV)));
    }
    OUTPUT:
        RETVAL

SV *
res(self)
        SV *self
    CODE:
    {
        AV *av = pcx_av(aTHX_ self);
        RETVAL = newSVsv(pcx_force(aTHX_ av, PCX_RES, "Punk::Response", NULL));
    }
    OUTPUT:
        RETVAL

# The outbound user agent: one Fetch per worker, shared by every request it
# serves, so the keep-alive pool and DNS state survive between them. The slot
# here only memoises the lookup for this request; punk_ua.h owns the agent and
# its pid check. Bound to the worker's loop, so a call made from a handler does
# not stop the worker answering others.
SV *
ua(self, name = NULL)
        SV *self
        SV *name
    CODE:
    {
        AV *av = pcx_av(aTHX_ self);
        STRLEN nl;
        const char *n = (name && SvOK(name)) ? SvPV_const(name, nl)
                                             : (nl = sizeof(K_DEFAULT) - 1,
                                                K_DEFAULT);
        /* Memoised per name, so a handler naming the same agent twice gets
         * one agent - and one jar, when the jar is per request. */
        SV  *memo = pcx_get(aTHX_ av, PCX_UA);
        HV  *seen;
        SV **e;
        if (memo && SvROK(memo) && SvTYPE(SvRV(memo)) == SVt_PVHV)
            seen = (HV *)SvRV(memo);
        else {
            seen = newHV();
            (void)av_store(av, PCX_UA, newRV_noinc((SV *)seen));
        }
        e = hv_fetch(seen, n, (I32)nl, 0);
        if (e && *e && SvROK(*e)) RETVAL = newSVsv(*e);
        else {
            /* +1 from pua_agent; the cache takes that reference */
            SV *u = pua_agent(aTHX_ pcx_get(aTHX_ av, PCX_APP), n, nl);
            (void)hv_store(seen, n, (I32)nl, u, 0);
            RETVAL = newSVsv(u);
        }
    }
    OUTPUT:
        RETVAL

SV *
stash(self)
        SV *self
    CODE:
    {
        AV *av = pcx_av(aTHX_ self);
        SV *s = pcx_get(aTHX_ av, PCX_STASH);
        if (!s) {
            s = newRV_noinc((SV *)newHV());
            (void)av_store(av, PCX_STASH, s);
        }
        RETVAL = newSVsv(s);
    }
    OUTPUT:
        RETVAL

SV *
openapi(self)
        SV *self
    CODE:
    {
        SV *o = pcx_get(aTHX_ pcx_av(aTHX_ self), PCX_OPENAPI);
        RETVAL = o ? newSVsv(o) : &PL_sv_undef;
    }
    OUTPUT:
        RETVAL

# Validated OpenAPI params win (path, then query), then web route captures,
# then the request (query, then form body).
SV *
param(self, name)
        SV *self
        SV *name
    CODE:
    {
        SV *v = pcx_param(aTHX_ pcx_av(aTHX_ self), name);
        RETVAL = v ? v : newSV(0);
    }
    OUTPUT:
        RETVAL

# params      -> all of them merged, in that same precedence
# params(@k)  -> just those, as a list of values in list context (undef
#                for a name no layer has) or a hashref of the ones that
#                are there in scalar context, which is the filter-hash
#                shape: my %f = %{ $c->params(qw(state queue)) };
#
# Results are written back over the argument slots, one behind the name
# being read, so no key is overwritten before it has been looked up.
void
params(self, ...)
        SV *self
    PPCODE:
    {
        AV *av = pcx_av(aTHX_ self);
        int i;
        if (items < 2) {
            ST(0) = sv_2mortal(newRV_noinc((SV *)pcx_params_merged(aTHX_ av)));
            XSRETURN(1);
        }
        if (GIMME_V == G_ARRAY) {
            for (i = 1; i < items; i++) {
                SV *v = pcx_param(aTHX_ av, ST(i));
                ST(i - 1) = sv_2mortal(v ? v : newSV(0));
            }
            XSRETURN(items - 1);
        }
        else {
            HV *out = newHV();
            for (i = 1; i < items; i++) {
                SV *v = pcx_param(aTHX_ av, ST(i));
                if (v) (void)hv_store_ent(out, ST(i), v, 0);
            }
            ST(0) = sv_2mortal(newRV_noinc((SV *)out));
            XSRETURN(1);
        }
    }

SV *
model(self, name)
        SV *self
        SV *name
    CODE:
    {
        SV *app = pcx_get(aTHX_ pcx_av(aTHX_ self), PCX_APP);
        dSP; int count;
        ENTER; SAVETMPS;
        PUSHMARK(SP); EXTEND(SP, 2);
        PUSHs(app ? app : &PL_sv_undef); PUSHs(name); PUTBACK;
        count = call_method("model_instance", G_SCALAR);
        SPAGAIN;
        RETVAL = count > 0 ? newSVsv(POPs) : &PL_sv_undef;
        PUTBACK; FREETMPS; LEAVE;
    }
    OUTPUT:
        RETVAL

# $app->render_view($self, @_)
SV *
render(self, ...)
        SV *self
    CODE:
    {
        AV *av  = pcx_av(aTHX_ self);
        SV *app = pcx_get(aTHX_ av, PCX_APP);
        int nargs = items - 1, i;
        SV **argv, *r;
        Newx(argv, nargs + 1, SV *);   /* capture args before any stack work */
        argv[0] = self;
        for (i = 0; i < nargs; i++) argv[i + 1] = ST(i + 1);
        r = pcx_call_meth(aTHX_ app ? app : &PL_sv_undef, "render_view",
                          argv, nargs + 1, 1);
        Safefree(argv);
        RETVAL = r ? r : newSV(0);
    }
    OUTPUT:
        RETVAL

# fragment($template, \%data?, %over): render with no layout, and
# `Cache-Control: private, no-store` on the finished response.
#
# A fragment is one user's data swapped into one user's page - the panel
# PDFMake-Site rendered through a private engine - and a shared cache handing
# it to the next visitor is a leak, so the header is the default and not a
# reminder. The public, cacheable partial is `render` with layout => undef and
# a Cache-Control of its own. A `layout` override here croaks: a fragment with
# a layout is a page, and the caller wanted `render`.
SV *
fragment(self, ...)
        SV *self
    CODE:
    {
        AV *av  = pcx_av(aTHX_ self);
        SV *app = pcx_get(aTHX_ av, PCX_APP);
        int nargs = items - 1, i, n = 0;
        SV **argv, *r, *lay;
        if (nargs < 1)
            croak("Punk::Context::fragment: a template name is required");
        /* ST(1) template, ST(2) data, ST(3..) overrides - every override
         * pair is checked for `layout` before anything is called */
        for (i = 3; i + 1 < items; i += 2) {
            STRLEN kl; const char *k = SvPV_const(ST(i), kl);
            if (kl == 6 && memEQ(k, "layout", 6))
                croak("Punk::Context::fragment: a fragment has no layout - "
                      "to render inside one, use render(..., layout => ...)");
        }
        /* self, template, data (undef if not given), overrides, layout, undef */
        Newx(argv, nargs + 4, SV *);
        argv[n++] = self;
        argv[n++] = ST(1);
        argv[n++] = items > 2 ? ST(2) : &PL_sv_undef;
        for (i = 3; i < items; i++) argv[n++] = ST(i);
        lay = sv_2mortal(newSVpvs("layout"));
        argv[n++] = lay;
        argv[n++] = &PL_sv_undef;
        r = pcx_call_meth(aTHX_ app ? app : &PL_sv_undef, "render_view",
                          argv, n, 1);
        Safefree(argv);
        if (!r) r = newSV(0);
        /* the header: replace an existing Cache-Control, else append one */
        if (SvROK(r) && SvTYPE(SvRV(r)) == SVt_PVAV) {
            SV **hp = av_fetch((AV *)SvRV(r), 1, 0);
            if (hp && *hp && SvROK(*hp) && SvTYPE(SvRV(*hp)) == SVt_PVAV) {
                AV *hd = (AV *)SvRV(*hp);
                SSize_t j, hn = av_len(hd) + 1;
                int found = 0;
                for (j = 0; j + 1 < hn; j += 2) {
                    SV **nm = av_fetch(hd, j, 0);
                    STRLEN nl; const char *np;
                    if (!(nm && *nm && SvOK(*nm))) continue;
                    np = SvPV_const(*nm, nl);
                    if (nl == 13 && foldEQ(np, "Cache-Control", (I32)13)) {
                        SV **vp = av_fetch(hd, j + 1, 1);
                        if (vp && *vp) sv_setpvs(*vp, "private, no-store");
                        found = 1;
                    }
                }
                if (!found) {
                    av_push(hd, newSVpvs("Cache-Control"));
                    av_push(hd, newSVpvs("private, no-store"));
                }
            }
        }
        RETVAL = r;
    }
    OUTPUT:
        RETVAL

# ---- finished responses ------------------------------------------------------

SV *
json(self, data, status = &PL_sv_undef)
        SV *self
        SV *data
        SV *status
    CODE:
    {
        AV *av  = pcx_av(aTHX_ self);
        AV *res = pcx_res_av(aTHX_ av);
        IV st = SvOK(status) ? SvIV(status) : pcx_res_status(aTHX_ res);
        SV *bytes = punk_frj(aTHX)->encode(aTHX_ data, NULL);
        if (!st) st = 200;
        RETVAL = punk_triplet(aTHX_ st,
                    sv_2mortal(newSVpvs("application/json")),
                    bytes, res ? pcx_res_headers(aTHX_ res) : NULL);
    }
    OUTPUT:
        RETVAL

# A File::Raw::XML::Document or ::Node is serialised; a string is markup the
# caller already built and goes out as it stands. Anything else is refused
# rather than stringified, which is the difference between an empty element
# and a body reading HASH(0x7f...).
SV *
xml(self, data, status = &PL_sv_undef)
        SV *self
        SV *data
        SV *status
    CODE:
    {
        AV *av  = pcx_av(aTHX_ self);
        AV *res = pcx_res_av(aTHX_ av);
        IV st = SvOK(status) ? SvIV(status) : pcx_res_status(aTHX_ res);
        SV *bytes;
        if (SvROK(data)) {
            SV *err = NULL;
            if (!punk_xml_is(aTHX_ data))
                croak("Punk: xml() takes a File::Raw::XML::Document, a "
                      "::Node, or a string of markup");
            bytes = punk_xml_bytes(aTHX_ data, &err);
            if (!bytes) croak("%s", err ? SvPV_nolen(err) : "Punk: xml");
        }
        else bytes = newSVsv(data);
        if (!st) st = 200;
        RETVAL = punk_triplet(aTHX_ st,
                    sv_2mortal(newSVpvs(PK_XML_CT)),
                    bytes, res ? pcx_res_headers(aTHX_ res) : NULL);
    }
    OUTPUT:
        RETVAL

SV *
text(self, body, status = &PL_sv_undef)
        SV *self
        SV *body
        SV *status
    ALIAS:
        html = 1
    CODE:
    {
        AV *av  = pcx_av(aTHX_ self);
        AV *res = pcx_res_av(aTHX_ av);
        IV st = SvOK(status) ? SvIV(status) : pcx_res_status(aTHX_ res);
        SV *ct = sv_2mortal(ix == 1 ? newSVpvs("text/html; charset=utf-8")
                                    : newSVpvs("text/plain; charset=utf-8"));
        if (!st) st = 200;
        RETVAL = punk_triplet(aTHX_ st, ct, newSVsv(body),
                              res ? pcx_res_headers(aTHX_ res) : NULL);
    }
    OUTPUT:
        RETVAL

# safe_path($path, $fallback?): $path when it is a same-origin relative path,
# otherwise the fallback (undef by default). The guard for anything that
# redirects to a destination the request supplied - ?to=, ?return=, ?next=.
# (Do not start a line in here with the word after "#" being if/else/endif:
# xsubpp reads it as a preprocessor directive.)
SV *
safe_path(self, path, fallback = &PL_sv_undef)
        SV *self
        SV *path
        SV *fallback
    CODE:
    {
        PERL_UNUSED_VAR(self);
        RETVAL = pk_same_origin_path(aTHX_ path)
               ? newSVsv(path) : newSVsv(fallback);
    }
    OUTPUT:
        RETVAL

# $c->origin - the request's scheme and host, when that host is the
# application's canonical one or on its allowlist; the canonical origin when
# it is anything else; undef when no `host` was declared. The raw header is
# never returned (punk_host.h).
SV *
origin(self)
        SV *self
    CODE:
    {
        int st = 0;
        SV *o = pk_origin_of(aTHX_ self, &st);
        RETVAL = o ? o : newSV(0);
    }
    OUTPUT:
        RETVAL

# $c->url_for($name, %args) - the URL of a named route.
#
#     $c->url_for('book', id => 42)                 # /books/42
#     $c->url_for('book', id => 42, page => 2)      # /books/42?page=2
#     $c->url_for('book', id => 42, absolute => 1)  # https://example.com/books/42
#
# An argument naming a capture fills that segment; anything left over is the
# query string, keys sorted. `absolute` and `query` are reserved words rather
# than captures - phase 0 refuses them as route names for that reason.
#
# Every result carries the application's prefix: the path on `host` and then
# SCRIPT_NAME, which are layers rather than alternatives (a proxy strips one,
# a PSGI mount adds the other, and the browser sees both). A relative URL is
# an href resolved against a page that is already under the prefix, so it
# needs the prefix exactly as much as an absolute one does.
#
# `absolute` joins $c->origin, which is the canonical origin unless the
# request's Host is on the allowlist and is never the raw header - so a link
# built here and mailed cannot be poisoned by a crafted Host.
SV *
url_for(self, name, ...)
        SV *self
        SV *name
    CODE:
    {
        AV *av = pcx_av(aTHX_ self);
        SV *appsv = pcx_get(aTHX_ av, PCX_APP);
        HV *h, *args, *query = NULL;
        SV *namesv, *routersv, *prefix = NULL, *origin = NULL;
        HE *he;
        SV *val;
        IV absolute = 0;
        int i;

        if ((items - 2) % 2)
            croak("Punk: url_for takes a route name then key => value pairs");
        if (!SvOK(name) || !SvCUR(name))
            croak("Punk: url_for needs a route name");
        if (!(appsv && SvROK(appsv) && SvTYPE(SvRV(appsv)) == SVt_PVHV))
            croak("Punk: url_for: no application on this context");
        h = (HV *)SvRV(appsv);

        args = (HV *)sv_2mortal((SV *)newHV());
        for (i = 2; i + 1 < items; i += 2) {
            STRLEN kl;
            const char *k = SvPV_const(ST(i), kl);
            if (kl == 8 && memEQ(k, "absolute", 8)) {
                absolute = SvTRUE(ST(i + 1)) ? 1 : 0;
                continue;
            }
            if (kl == 5 && memEQ(k, "query", 5)) {
                SV *q = ST(i + 1);
                if (!(SvROK(q) && SvTYPE(SvRV(q)) == SVt_PVHV))
                    croak("Punk: url_for('%s'): `query` takes a hashref",
                          SvPV_nolen(name));
                query = (HV *)SvRV(q);
                continue;
            }
            (void)hv_store(args, k, (I32)kl, newSVsv(ST(i + 1)), 0);
        }

        namesv = app_get(aTHX_ h, K_NAMES_C);
        he = (namesv && SvROK(namesv) && SvTYPE(SvRV(namesv)) == SVt_PVHV)
             ? hv_fetch_ent((HV *)SvRV(namesv), name, 0, 0) : NULL;
        if (!he)
            croak("Punk: url_for: no route is named '%s' - a name is "
                  "declared with { name => '...' } on the route, and it is "
                  "one namespace for the whole application",
                  SvPV_nolen(name));
        val = HeVAL(he);

        routersv = app_get(aTHX_ h, K_ROUTER);
        if (!(routersv && SvROK(routersv)))
            croak("Punk: url_for: this application is not compiled");

        {   /* prefix = the path on `host`, then SCRIPT_NAME */
            SV *hp = app_get(aTHX_ h, K_HOST_PATH_C);
            SV *envsv = pcx_get(aTHX_ av, PCX_ENV);
            SV **sn = (envsv && SvROK(envsv) && SvTYPE(SvRV(envsv)) == SVt_PVHV)
                      ? hv_fetchs((HV *)SvRV(envsv), "SCRIPT_NAME", 0) : NULL;
            int have_hp = (hp && SvOK(hp) && SvCUR(hp));
            int have_sn = (sn && *sn && SvOK(*sn) && SvCUR(*sn));
            if (have_hp || have_sn) {
                prefix = sv_2mortal(newSVpvs(""));
                if (have_hp) sv_catsv(prefix, hp);
                if (have_sn) sv_catsv(prefix, *sn);
            }
        }

        if (absolute) {
            int st = 0;
            origin = pk_origin_of(aTHX_ self, &st);
            if (!origin)
                croak("Punk: url_for('%s', absolute => 1): the application "
                      "declared no `host`, and the request's Host is not "
                      "something a link may be built on - declare "
                      "host 'https://example.com'", SvPV_nolen(name));
            sv_2mortal(origin);
        }

        /* A route's entry is a record index; an API operation's is a
         * reference to [ mount prefix, parsed template ]. One table, two
         * kinds of route, and the shape says which. */
        if (SvROK(val) && SvTYPE(SvRV(val)) == SVt_PVAV) {
            AV *pair = (AV *)SvRV(val);
            SV **mp = av_fetch(pair, 0, 0);
            SV **tm = av_fetch(pair, 1, 0);
            RETVAL = pk_url_build_op(aTHX_
                        (AV *)SvRV(*tm), (mp && *mp) ? *mp : NULL,
                        args, query, prefix, origin, SvPV_nolen(name));
        }
        else
            RETVAL = pk_url_build(aTHX_ punk_router_of(aTHX_ routersv),
                                  SvIV(val), args, query, prefix, origin,
                                  SvPV_nolen(name));
    }
    OUTPUT:
        RETVAL

# $c->host_allowed - true when the request's Host is one the application
# declared: the canonical host, or a match on the allowlist. The signal an
# application needs to refuse an unknown host rather than answer for it.
IV
host_allowed(self)
        SV *self
    CODE:
    {
        int st = 0;
        SV *o = pk_origin_of(aTHX_ self, &st);
        if (o) SvREFCNT_dec(o);
        RETVAL = st > 0 ? 1 : 0;
    }
    OUTPUT:
        RETVAL

# $c->asset('/static/app.css') - the content-addressed URL for a file under
# a static mount: '/static/app.9f3a1c2b0d4e5f60.css', which serves with a
# year and `immutable` because that URL cannot come to mean anything else.
# A URL under no static mount, under one with fingerprinting off, or naming
# a file that cannot be read comes back exactly as it went in - the page
# still works, it just revalidates.
SV *
asset(self, url)
        SV *self
        SV *url
    CODE:
    {
        AV *av  = pcx_av(aTHX_ self);
        SV *app = pcx_get(aTHX_ av, PCX_APP);
        SV *out = NULL;
        if (app && SvROK(app) && SvTYPE(SvRV(app)) == SVt_PVHV) {
            SV *mp = app_get(aTHX_ (HV *)SvRV(app), K_MOUNTS_C);
            if (mp && SvROK(mp) && SvTYPE(SvRV(mp)) == SVt_PVAV)
                out = pa_asset_for(aTHX_ (AV *)SvRV(mp), url);
        }
        RETVAL = out ? out : newSVsv(url);
    }
    OUTPUT:
        RETVAL

SV *
redirect(self, url, status = &PL_sv_undef)
        SV *self
        SV *url
        SV *status
    CODE:
    {
        AV *av   = pcx_av(aTHX_ self);
        AV *res  = pcx_res_av(aTHX_ av);
        AV *rh   = res ? pcx_res_headers(aTHX_ res) : NULL;
        AV *hdr  = newAV();
        AV *body = newAV();
        AV *resp = newAV();
        IV st = SvOK(status) ? SvIV(status) : 302;
        av_push(hdr, newSVpvs("Location"));
        av_push(hdr, newSVsv(url));
        av_push(hdr, newSVpvs("Content-Length"));
        av_push(hdr, newSViv(0));
        if (rh) {
            SSize_t i, n = av_len(rh) + 1;
            for (i = 0; i < n; i++) {
                SV **e = av_fetch(rh, i, 0);
                av_push(hdr, e && *e ? newSVsv(*e) : newSV(0));
            }
        }
        av_push(body, newSVpvs(""));
        av_extend(resp, 2);
        av_push(resp, newSViv(st));
        av_push(resp, newRV_noinc((SV *)hdr));
        av_push(resp, newRV_noinc((SV *)body));
        RETVAL = newRV_noinc((SV *)resp);
    }
    OUTPUT:
        RETVAL

SV *
not_found(self)
        SV *self
    CODE:
        PERL_UNUSED_VAR(self);
        RETVAL = punk_triplet(aTHX_ 404,
                    sv_2mortal(newSVpvs("application/json")),
                    newSVpvs("{\"errors\":[{\"message\":\"Not Found\"}]}"),
                    NULL);
    OUTPUT:
        RETVAL

# respond_to(json => sub {...}, html => sub {...}, any => sub {...}):
# Accept negotiation (punk_accept.h). The most acceptable offered format's
# coderef is called with $c and its return is the response; `any` catches a
# request nothing else fits, and without it that request is a 406. A client
# that is indifferent (no Accept, or only a wildcard match) gets the format
# its own Content-Type names if that is offered, else the first registered.
# Every outcome carries Vary: Accept.
SV *
respond_to(self, ...)
        SV *self
    CODE:
    {
#define PRT_MAX 16
        AV *av = pcx_av(aTHX_ self);
        SV *cbs[PRT_MAX];
        const char *bt[PRT_MAX], *bs[PRT_MAX];
        STRLEN btl[PRT_MAX], bsl[PRT_MAX];
        int bq[PRT_MAX], bspec[PRT_MAX];
        SV *any_cb = NULL, *accept_sv = NULL, *ctype_sv = NULL;
        pa_range ranges[PA_RANGE_MAX];
        int nb = 0, nr = 0, have_accept = 0, i;
        int best = -1, best_q = 0, best_spec = -1, best_order = 0;

        if (items < 3 || !(items % 2))
            croak("Punk: respond_to takes format => coderef pairs");
        for (i = 1; i + 1 < items; i += 2) {
            STRLEN nl; const char *nm = SvPV_const(ST(i), nl);
            SV *cb = ST(i + 1);
            if (!(SvROK(cb) && SvTYPE(SvRV(cb)) == SVt_PVCV))
                croak("Punk: respond_to format '%.*s' needs a coderef",
                      (int)nl, nm);
            if (nl == 3 && memEQ(nm, "any", 3)) { any_cb = cb; continue; }
            if (nb >= PRT_MAX)
                croak("Punk: respond_to takes at most %d formats", PRT_MAX);
            if (!pa_fmt_mime(nm, nl, &bt[nb], &btl[nb], &bs[nb], &bsl[nb]))
                croak("Punk: respond_to does not know format '%.*s' - "
                      "name a full media type", (int)nl, nm);
            cbs[nb] = cb;
            nb++;
        }

        {   /* the request's Accept and Content-Type, straight off the env */
            SV *env = pcx_get(aTHX_ av, PCX_ENV);
            if (env && SvROK(env) && SvTYPE(SvRV(env)) == SVt_PVHV) {
                HV *eh = (HV *)SvRV(env);
                SV **e = hv_fetchs(eh, "HTTP_ACCEPT", 0);
                if (e && *e && SvOK(*e) && SvCUR(*e)) accept_sv = *e;
                e = hv_fetchs(eh, "CONTENT_TYPE", 0);
                if (e && *e && SvOK(*e) && SvCUR(*e)) ctype_sv = *e;
            }
        }
        if (accept_sv) {
            STRLEN al; const char *a = SvPV_const(accept_sv, al);
            nr = pa_parse(a, al, ranges, PA_RANGE_MAX);
            /* unparseable garbage is indifference, not an error */
            have_accept = nr > 0;
        }

        for (i = 0; i < nb; i++) {
            int q = 1000, order = 0, spec = 0;
            if (have_accept) {
                spec = pa_match(aTHX_ ranges, nr, bt[i], btl[i],
                                bs[i], bsl[i], &q, &order);
                if (spec < 0 || q <= 0) { bq[i] = -1; bspec[i] = -1; continue; }
            }
            bq[i] = q; bspec[i] = spec;
            if (best < 0
                || q > best_q
                || (q == best_q && spec > best_spec)
                || (q == best_q && spec == best_spec && order < best_order)) {
                best = i; best_q = q; best_spec = spec; best_order = order;
            }
        }

        /* An indifferent client (wildcard or no Accept) that itself sent one
         * of the offered types wants that type back - a JSON POST from curl
         * with no Accept should not be answered in HTML. Only a branch as
         * acceptable as the provisional winner may take over. */
        if (best >= 0 && best_spec == 0 && ctype_sv) {
            STRLEN cl; const char *cs = SvPV_const(ctype_sv, cl);
            const char *ce = (const char *)memchr(cs, ';', cl);
            STRLEN ml = ce ? (STRLEN)(ce - cs) : cl;
            const char *slash = (const char *)memchr(cs, '/', ml);
            while (ml && pa_ws(cs[ml - 1])) ml--;
            if (slash && slash > cs) {
                STRLEN tl1 = (STRLEN)(slash - cs);
                const char *s1 = slash + 1;
                STRLEN sl1 = ml > tl1 ? ml - tl1 - 1 : 0;
                for (i = 0; i < nb; i++) {
                    if (bq[i] == best_q
                        && btl[i] == tl1 && foldEQ(bt[i], cs, (I32)tl1)
                        && bsl[i] == sl1 && foldEQ(bs[i], s1, (I32)sl1)) {
                        best = i;
                        break;
                    }
                }
            }
        }

        {   /* every outcome of a negotiation varies on Accept */
            SV *res = pcx_force(aTHX_ av, PCX_RES, "Punk::Response", NULL);
            AV *rav = pcx_res_av(aTHX_ av);
            PERL_UNUSED_VAR(res);
            if (rav) pa_vary_accept(aTHX_ punk_res_headers(aTHX_ rav));
        }

        if (best < 0 && !any_cb) {
            AV *rav = pcx_res_av(aTHX_ av);
            RETVAL = punk_triplet(aTHX_ 406,
                        sv_2mortal(newSVpvs("application/json")),
                        newSVpvs("{\"errors\":[{\"message\":"
                                 "\"Not Acceptable\"}]}"),
                        rav ? punk_res_headers(aTHX_ rav) : NULL);
        }
        else {
            SV *cb = best >= 0 ? cbs[best] : any_cb;
            dSP; int count;
            ENTER; SAVETMPS;
            PUSHMARK(SP); EXTEND(SP, 1); PUSHs(self); PUTBACK;
            count = call_sv(cb, G_SCALAR);
            SPAGAIN;
            RETVAL = count > 0 ? newSVsv(POPs) : newSV(0);
            PUTBACK; FREETMPS; LEAVE;
        }
#undef PRT_MAX
    }
    OUTPUT:
        RETVAL

# ---- pending response state --------------------------------------------------

# no args -> the pending status (or undef); with args -> set it, chainable.
SV *
status(self, ...)
        SV *self
    CODE:
    {
        AV *av = pcx_av(aTHX_ self);
        if (items > 1) {
            SV *sval = ST(1);   /* capture before forcing/pushing */
            SV *res  = pcx_force(aTHX_ av, PCX_RES, "Punk::Response", NULL);
            (void)pcx_call_meth(aTHX_ res, "status", &sval, 1, 0);
            RETVAL = newSVsv(self);
        }
        else {
            AV *res = pcx_res_av(aTHX_ av);
            IV st = pcx_res_status(aTHX_ res);
            RETVAL = st ? newSViv(st) : &PL_sv_undef;
        }
    }
    OUTPUT:
        RETVAL

# header($name) -> read; header(Name => $v, ...) / no args -> set, chainable.
SV *
header(self, ...)
        SV *self
    CODE:
    {
        AV *av = pcx_av(aTHX_ self);
        int set = (items > 2 || items == 1);
        int nargs = items - 1, i;
        SV **argv, *res, *r;
        Newx(argv, nargs > 0 ? nargs : 1, SV *);   /* capture before stack work */
        for (i = 0; i < nargs; i++) argv[i] = ST(i + 1);
        res = pcx_force(aTHX_ av, PCX_RES, "Punk::Response", NULL);
        r = pcx_call_meth(aTHX_ res, "header", argv, nargs, set ? 0 : 1);
        Safefree(argv);
        if (set)   RETVAL = newSVsv(self);
        else       RETVAL = r ? r : &PL_sv_undef;
    }
    OUTPUT:
        RETVAL

# cookie($name) reads (via the request); cookie($name => $value, %opts) sets a
# Set-Cookie on the response (undef value deletes). Set form chains. Options
# may also arrive as one trailing hashref, in either direction - which is how
# the read form takes any at all: cookie('theme', { signed => 1 }).
#
# `signed => 1` signs with the SESSION's machinery and the session's secret,
# deliberately: pk_session_sign/verify already exist, the verify is already
# constant-time, and if `secret` ever grows rotation (a list: newest signs,
# all verify) signed cookies inherit it by riding the same key path. Do not
# build a second HMAC or a second key schedule here.
SV *
cookie(self, ...)
        SV *self
    CODE:
    {
        AV *av = pcx_av(aTHX_ self);
        int read_opts = items == 3 && SvROK(ST(2))
                        && SvTYPE(SvRV(ST(2))) == SVt_PVHV;
        if (items <= 2 || read_opts) {             /* read via the request */
            SV *req = pcx_force(aTHX_ av, PCX_REQ, "Punk::Request",
                                pcx_get(aTHX_ av, PCX_ENV));
            SV *argv[1], *r;
            argv[0] = items >= 2 ? ST(1) : &PL_sv_undef;
            r = pcx_call_meth(aTHX_ req, "cookie", argv, 1, 1);
            if (read_opts && r && SvOK(r)) {
                SV **sg = hv_fetchs((HV *)SvRV(ST(2)), "signed", 0);
                if (sg && *sg && SvTRUE(*sg)) {
                    HV *scfg = ps_cfg(aTHX_ self);
                    STRLEN kl = 0;
                    const char *key = scfg
                        ? ps_cfg_str(aTHX_ scfg, "secret", "", &kl) : "";
                    STRLEN cl;
                    const char *cv2;
                    SV *payload;
                    if (!kl)
                        croak("Punk: signed cookies sign with the session's "
                              "secret - add `session secret => ...`");
                    cv2 = SvPV_const(r, cl);
                    payload = pk_session_verify(aTHX_ cv2, cl, key, kl);
                    SvREFCNT_dec(r);
                    r = NULL;
                    if (payload) {
                        /* The NAME is under the MAC. A signed value the
                         * client moved onto another cookie decodes to the
                         * wrong `name=` prefix and fails closed, like any
                         * other tamper - without this, any two signed
                         * cookies could be swapped for each other and both
                         * would verify. */
                        STRLEN pl, nl2;
                        const char *p = SvPV_const(payload, pl);
                        const char *n2 = SvPV_const(ST(1), nl2);
                        if (pl > nl2 && memEQ(p, n2, nl2) && p[nl2] == '=')
                            r = newSVpvn(p + nl2 + 1, pl - nl2 - 1);
                        SvREFCNT_dec(payload);
                    }
                }
            }
            RETVAL = r ? r : &PL_sv_undef;
        }
        else {                                     /* set */
            SV *name = ST(1), *value = ST(2), *ck, *res, *hargv[2], *r;
            HV *opts = (HV *)sv_2mortal((SV *)newHV());
            int i;
            if (items == 4 && SvROK(ST(3)) && SvTYPE(SvRV(ST(3))) == SVt_PVHV) {
                HV *oh = (HV *)SvRV(ST(3));
                HE *he;
                hv_iterinit(oh);
                while ((he = hv_iternext(oh)))
                    (void)hv_store_ent(opts, HeSVKEY_force(he),
                                       newSVsv(HeVAL(he)), 0);
            }
            else {
                for (i = 3; i + 1 < items; i += 2) {
                    STRLEN kl; const char *k = SvPV_const(ST(i), kl);
                    (void)hv_store(opts, k, (I32)kl, newSVsv(ST(i + 1)), 0);
                }
            }
            {
                SV **sg = hv_fetchs(opts, "signed", 0);
                if (sg && *sg && SvTRUE(*sg) && value && SvOK(value)) {
                    HV *scfg = ps_cfg(aTHX_ self);
                    STRLEN kl = 0;
                    const char *key = scfg
                        ? ps_cfg_str(aTHX_ scfg, "secret", "", &kl) : "";
                    SV *payload;
                    if (!kl)
                        croak("Punk: signed cookies sign with the session's "
                              "secret - add `session secret => ...`");
                    payload = sv_2mortal(newSVsv(name));
                    sv_catpvs(payload, "=");
                    sv_catsv(payload, value);
                    value = sv_2mortal(pk_session_sign(aTHX_ payload,
                                                       key, kl));
                }
            }
            ck = sv_2mortal(pk_build_cookie(aTHX_ name, value, opts));
            res = pcx_force(aTHX_ av, PCX_RES, "Punk::Response", NULL);
            hargv[0] = sv_2mortal(newSVpvs("Set-Cookie"));
            hargv[1] = ck;
            r = pcx_call_meth(aTHX_ res, "header", hargv, 2, 0);
            if (r) SvREFCNT_dec(r);
            RETVAL = newSVsv(self);
        }
    }
    OUTPUT:
        RETVAL

# upload($name): the Punk::Upload for that multipart field, via the request.
SV *
upload(self, name)
        SV *self
        SV *name
    CODE:
    {
        AV *av = pcx_av(aTHX_ self);
        SV *req = pcx_force(aTHX_ av, PCX_REQ, "Punk::Request",
                            pcx_get(aTHX_ av, PCX_ENV));
        SV *argv[1], *r;
        argv[0] = name;
        r = pcx_call_meth(aTHX_ req, "upload", argv, 1, 1);
        RETVAL = r ? r : &PL_sv_undef;
    }
    OUTPUT:
        RETVAL

# csrf_token: the live single-use token, minted into the session on first ask
# (which dirties the session, so the cookie follows). csrf_field is the hidden
# input a form needs, escaped and ready to drop into a template with `raw`.
SV *
csrf_token(self)
        SV *self
    ALIAS:
        csrf_field = 1
    CODE:
    {
        SV *tok;
        if (!pcf_cfg(aTHX_ self))
            croak("Punk: no csrf configured (add a `csrf` keyword)");
        tok = pcf_token(aTHX_ self, 1);
        if (!tok) { RETVAL = newSV(0); }
        else if (!ix) { RETVAL = newSVsv(tok); }
        else {
            HV *cfg = pcf_cfg(aTHX_ self);
            STRLEN fl;
            const char *field = ps_cfg_str(aTHX_ cfg, "field", "_csrf", &fl);
            SV *out = newSVpvs("<input type=\"hidden\" name=\"");
            pcf_attr_escape(aTHX_ out, field, fl);
            sv_catpvs(out, "\" value=\"");
            {
                STRLEN tl;
                const char *tv = SvPV_const(tok, tl);
                pcf_attr_escape(aTHX_ out, tv, tl);
            }
            sv_catpvs(out, "\">");
            RETVAL = out;
        }
    }
    OUTPUT:
        RETVAL

# session: the signed cookie-backed hashref (loaded once, written back if
# changed). session_expire logs out - empties it and deletes the cookie.
SV *
session(self)
        SV *self
    CODE:
        RETVAL = ps_load(aTHX_ self);
    OUTPUT:
        RETVAL

SV *
session_expire(self)
        SV *self
    CODE:
    {
        HV *stash = ps_stash(aTHX_ pcx_av(aTHX_ self));
        (void)hv_stores(stash, "punk.session", newRV_noinc((SV *)newHV()));
        (void)hv_stores(stash, "punk.session.expire", newSViv(1));
        RETVAL = newSVsv(self);
    }
    OUTPUT:
        RETVAL

# session_rotate: keep the session, give it a new name.
#
# Call it at the privilege boundary - a login, an elevation - and nowhere else.
# Session fixation is the attack: somebody plants a known id in a victim's
# browser and waits for them to log in. If logging in writes the user into the
# session the attacker planted, the attacker's id is now an authenticated
# session. The cookie session is immune by accident, because its value changes
# wholesale when its contents do. A stored session is not: the id survives the
# login unless something changes it.
#
# It cannot be automatic. "Privilege changed" is application knowledge, and
# every candidate for guessing it is wrong - rotating whenever the session
# gains a key rotates on a shopping basket, rotating on every POST is a store
# write per form submission, and watching for a key named `user_id` is a
# convention nobody agreed to.
SV *
session_rotate(self)
        SV *self
    CODE:
    {
        AV *av = pcx_av(aTHX_ self);
        HV *stash = ps_stash(aTHX_ av);
        SV **idp;
        /* Load first: the contents have to survive the rotation, and a
         * handler that rotates before touching $c->session would otherwise
         * leave the write-back with no session to write. */
        SV *sess = ps_load(aTHX_ self);
        SvREFCNT_dec(sess);
        idp = hv_fetch(stash, PK_SESSION_SID, PK_SESSION_SID_LEN, 0);
        /* The old id to retire, or undef when this session is new - which is
         * the ordinary case for a login, and still marks the write-back as
         * rotating so an unchanged session is written under the new name. */
        (void)hv_store(stash, PK_SESSION_ROT, PK_SESSION_ROT_LEN,
                       (idp && *idp && SvOK(*idp)) ? newSVsv(*idp) : newSV(0),
                       0);
        (void)hv_delete(stash, PK_SESSION_SID, PK_SESSION_SID_LEN, G_DISCARD);
        RETVAL = newSVsv(self);
    }
    OUTPUT:
        RETVAL

# flash: one-request messages over the session (punk_flash.h). Any flash call
# rotates the inbound hash out of the session, so the consuming response's
# cookie no longer carries it; writes fill a fresh outbound hash the NEXT
# request will read. No args: the whole inbound hashref (the template
# hand-off). One arg: one inbound value. Pairs: set outbound, chainable.
SV *
flash(self, ...)
        SV *self
    CODE:
    {
        if (items == 1) {
            RETVAL = newRV_inc((SV *)pf_inbound(aTHX_ self));
        }
        else if (items == 2) {
            HV *in = pf_inbound(aTHX_ self);
            HE *he = hv_fetch_ent(in, ST(1), 0, 0);
            RETVAL = he ? newSVsv(HeVAL(he)) : newSV(0);
        }
        else if ((items - 1) % 2) {
            croak("Punk: flash(key => value, ...) takes pairs");
        }
        else {
            I32 i;
            HV *out;
            (void)pf_inbound(aTHX_ self);       /* rotate before writing */
            out = pf_outbound(aTHX_ self);
            for (i = 1; i + 1 < items; i += 2)
                (void)hv_store_ent(out, ST(i), newSVsv(ST(i + 1)), 0);
            RETVAL = newSVsv(self);
        }
    }
    OUTPUT:
        RETVAL

# validate: collecting request validation, all in C (punk_validate.h, on
# the JSON::Schema::Fast C ABI). With a schema, runs a validation and
# returns the Punk::Validate::Result (also stashed at punk.validation).
# With no arguments, the reader: the last Result this request produced -
# a route-level validate ran before the handler, so this is how the
# handler collects its outcome - or undef.
SV *
validate(self, schema = &PL_sv_undef, source = &PL_sv_undef)
        SV *self
        SV *schema
        SV *source
    CODE:
    {
        if (items == 1) {
            HV *stash = ps_stash(aTHX_ pcx_av(aTHX_ self));
            SV **v = hv_fetchs(stash, "punk.validation", 0);
            RETVAL = (v && *v && SvOK(*v)) ? newSVsv(*v) : newSV(0);
        }
        else {
            RETVAL = pv_validate(aTHX_ self, schema, source);
        }
    }
    OUTPUT:
        RETVAL

# flash_keep: re-arm this request's inbound flash for one more request - the
# redirect-through-a-redirect case. Chainable.
SV *
flash_keep(self)
        SV *self
    CODE:
    {
        HV *in  = pf_inbound(aTHX_ self);
        HV *out = pf_outbound(aTHX_ self);
        HE *he;
        hv_iterinit(in);
        while ((he = hv_iternext(in))) {
            (void)hv_store_ent(out, hv_iterkeysv(he),
                               newSVsv(HeVAL(he)), 0);
        }
        RETVAL = newSVsv(self);
    }
    OUTPUT:
        RETVAL

# response state the finish path folds in without forcing a response object
SV *
_status(self)
        SV *self
    CODE:
    {
        AV *res = pcx_res_av(aTHX_ pcx_av(aTHX_ self));
        SV **e = res ? av_fetch(res, PS_STATUS, 0) : NULL;
        RETVAL = (e && *e) ? newSVsv(*e) : &PL_sv_undef;
    }
    OUTPUT:
        RETVAL

SV *
_headers(self)
        SV *self
    CODE:
    {
        AV *res = pcx_res_av(aTHX_ pcx_av(aTHX_ self));
        RETVAL = res ? newRV_inc((SV *)punk_res_headers(aTHX_ res))
                     : newRV_noinc((SV *)newAV());
    }
    OUTPUT:
        RETVAL

# ---- abuse controls: Hyperman's v3 arena via the ABI (punk_hm) --------------
#
# These reach the shared denylist / rate counters Hyperman maps before it forks
# its workers. They FAIL OPEN: with no Hyperman >= ABI v3 under us (plackup, an
# older server) punk_hm() is NULL, block_ip is a no-op returning 0 and rate_hit
# reports "allowed", so rate limiting is never the reason a request is refused.

# $c->block_ip([$ip [, $ttl]]) / $c->unblock_ip([$ip])
# Denylist (or lift) an IP at the edge; $ip defaults to this request's
# REMOTE_ADDR, $ttl seconds (0 = permanent). Returns 1 if the edge arena is
# present (the change took), else 0.
IV
block_ip(self, ...)
        SV *self
    ALIAS:
        unblock_ip = 1
    CODE:
    {
        const hm_abi *A = punk_hm(aTHX);
        const char *ip = NULL;
        HV *cenv = NULL;
        {
            AV  *av = pcx_av(aTHX_ self);
            SV **e  = av_fetch(av, PCX_ENV, 0);
            if (e && *e && SvROK(*e) && SvTYPE(SvRV(*e)) == SVt_PVHV)
                cenv = (HV *)SvRV(*e);
        }
        if (items > 1 && SvOK(ST(1))) {
            ip = SvPV_nolen(ST(1));
        } else if (cenv) {
            SV **r = hv_fetchs(cenv, "REMOTE_ADDR", 0);
            if (r && *r && SvOK(*r)) ip = SvPV_nolen(*r);
        }
        /* Behind a proxy, banning the address the socket came from bans the
         * load balancer and takes the site down - and punk.peer_addr only
         * exists when a `proxy` policy resolved this request, so this cannot
         * fire on a directly-exposed app. Boot-time config cannot catch it;
         * a silent no-op would leave an operator believing they had banned
         * someone, which is worse than an error. */
        if (ix == 0 && cenv && ip && *ip) {
            SV **pa = hv_fetchs(cenv, "punk.peer_addr", 0);
            if (pa && *pa && SvOK(*pa)) {
                STRLEN pl;
                const char *peer = SvPV_const(*pa, pl);
                if (pl && strlen(ip) == pl && memEQ(ip, peer, pl))
                    croak("Punk: block_ip would denylist %s, which is the "
                          "reverse proxy this request came through, not a "
                          "client - that would take the site down. Ban the "
                          "client address ($c->req->address) instead", ip);
            }
        }
        if (!A || !A->deny_add || !ip || !*ip) {
            RETVAL = 0;
        } else if (ix == 1) {
            A->deny_remove(ip);
            RETVAL = 1;
        } else {
            long ttl = (items > 2 && SvOK(ST(2))) ? (long)SvIV(ST(2)) : 0;
            A->deny_add(ip, ttl);
            RETVAL = 1;
        }
    }
    OUTPUT:
        RETVAL

# $c->rate_hit($key, $limit, $window) -> ($ok, $remaining, $reset)
# Count one hit against the opaque $key under $limit per $window seconds.
# $limit <= 0 is unlimited. Fail-open with no arena: (1, $limit-1, next-window).
void
rate_hit(self, key, limit, window)
        SV *self
        SV *key
        IV  limit
        IV  window
    PPCODE:
    {
        const hm_abi *A = punk_hm(aTHX);
        STRLEN klen;
        const char *k = SvPV(key, klen);
        IV rem = 0, reset = 0;
        int ok;
        PERL_UNUSED_VAR(self);
        if (A && A->ratelimit_hit) {
            ok = A->ratelimit_hit(k, klen, limit, window, &rem, &reset);
        } else {
            long now = (long)time(NULL);
            long w   = window > 0 ? window : 60;
            ok    = 1;
            rem   = limit > 0 ? limit - 1 : -1;
            reset = now - (now % w) + w;
        }
        XPUSHs(sv_2mortal(newSViv(ok)));
        XPUSHs(sv_2mortal(newSViv(rem)));
        XPUSHs(sv_2mortal(newSViv(reset)));
    }

# ---- the cross-worker bus ---------------------------------------------------

# publish($topic, $payload)
#
#    1  on the ring: every worker in the pool will see it
#    0  local only - there is no pool (not under Hyperman, or a Hyperman
#       without the bus), so nobody else will
#   -1  refused: too big for a bus slot
#
# Three outcomes rather than true or false, because "the pool got it" and
# "only I got it" are different facts, and an application that cannot tell
# them apart cannot diagnose why the other workers stayed quiet.
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

# subscribe($topic, $cb, %opt)
#
# $cb is called as $cb->($topic, $payload) in this worker.
#
# `group => $name` is the only difference between the two delivery modes:
# without it every worker's subscriber sees every message (what a fanout
# wants), with it exactly one member of the named group sees each (work spread
# across the pool, with no scheduler - a busy worker simply is not there to
# claim).
#
# Register at BOOT, not per request. A subscription made inside a request
# lands in one worker and lasts as long as that process, which is the same
# class of mistake the bus exists to fix.
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

# $c->cache / $c->cache($name) - a cache store.
#
# Built once, at to_app, and shared by every request on this worker: a store
# constructed per request would be a cache that never hits.
#
# Named stores exist because a session cache and a rendered-page cache want
# different budgets and different lifetimes, and sharing one means the big
# cold thing evicts the small hot thing.
SV *
cache(self, name = NULL)
        SV *self
        SV *name
    CODE:
    {
        AV  *av  = pcx_av(aTHX_ self);
        SV  *app = pcx_get(aTHX_ av, PCX_APP);
        STRLEN nl;
        const char *n = (name && SvOK(name)) ? SvPV_const(name, nl)
                                             : (nl = sizeof(K_DEFAULT) - 1,
                                                K_DEFAULT);
        SV **slot = NULL, **built = NULL;
        if (app && SvROK(app) && SvTYPE(SvRV(app)) == SVt_PVHV)
            built = hv_fetchs((HV *)SvRV(app), "cache", 0);
        if (built && *built && SvROK(*built)
            && SvTYPE(SvRV(*built)) == SVt_PVHV)
            slot = hv_fetch((HV *)SvRV(*built), n, (I32)nl, 0);
        if (!(slot && *slot && SvOK(*slot)))
            croak("Punk: no cache named '%s' (add a `cache` keyword)", n);
        RETVAL = newSVsv(*slot);
    }
    OUTPUT:
        RETVAL

# after_response($code): run $code once this response has been handed to the
# server, off the request's own path. The queue is per request (PCX_AFTER_RES);
# `hook after_response` is the application-wide half, and both are drained
# together by punk_afterres.h. Chains.
SV *
after_response(self, code)
        SV *self
        SV *code
    CODE:
    {
        AV *av = pcx_av(aTHX_ self);
        SV *q;
        if (!(SvROK(code) && SvTYPE(SvRV(code)) == SVt_PVCV))
            croak("Punk: after_response takes a code reference");
        q = pcx_get(aTHX_ av, PCX_AFTER_RES);
        if (!(q && SvROK(q) && SvTYPE(SvRV(q)) == SVt_PVAV)) {
            q = newRV_noinc((SV *)newAV());
            if (!av_store(av, PCX_AFTER_RES, q)) {
                SvREFCNT_dec(q);
                croak("Punk: after_response could not queue");
            }
        }
        av_push((AV *)SvRV(q), newSVsv(code));
        RETVAL = newSVsv(self);
    }
    OUTPUT:
        RETVAL
