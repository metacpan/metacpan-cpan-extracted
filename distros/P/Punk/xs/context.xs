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
# Set-Cookie on the response (undef value deletes). Set form chains.
SV *
cookie(self, ...)
        SV *self
    CODE:
    {
        AV *av = pcx_av(aTHX_ self);
        if (items <= 2) {                          /* read via the request */
            SV *req = pcx_force(aTHX_ av, PCX_REQ, "Punk::Request",
                                pcx_get(aTHX_ av, PCX_ENV));
            SV *argv[1], *r;
            argv[0] = items == 2 ? ST(1) : &PL_sv_undef;
            r = pcx_call_meth(aTHX_ req, "cookie", argv, 1, 1);
            RETVAL = r ? r : &PL_sv_undef;
        }
        else {                                     /* set */
            SV *name = ST(1), *value = ST(2), *ck, *res, *hargv[2], *r;
            HV *opts = (HV *)sv_2mortal((SV *)newHV());
            int i;
            for (i = 3; i + 1 < items; i += 2) {
                STRLEN kl; const char *k = SvPV_const(ST(i), kl);
                (void)hv_store(opts, k, (I32)kl, newSVsv(ST(i + 1)), 0);
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
        if (items > 1 && SvOK(ST(1))) {
            ip = SvPV_nolen(ST(1));
        } else {
            AV  *av = pcx_av(aTHX_ self);
            SV **e  = av_fetch(av, PCX_ENV, 0);
            if (e && *e && SvROK(*e) && SvTYPE(SvRV(*e)) == SVt_PVHV) {
                SV **r = hv_fetchs((HV *)SvRV(*e), "REMOTE_ADDR", 0);
                if (r && *r && SvOK(*r)) ip = SvPV_nolen(*r);
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
