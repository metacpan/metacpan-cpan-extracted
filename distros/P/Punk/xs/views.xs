MODULE = Punk        PACKAGE = Punk::Views

PROTOTYPES: DISABLE

# Punk::Views is entirely XS (punk_views.h): the object is a blessed IV-ref to
# the engine registry. lib/Punk/Views.pm is documentation only.

# new(\@pairs): [ [ Name, \%opts ], ... ]. Resolve, load and instantiate each
# engine (the boot-time Perl calls); the first is the default.
SV *
new(class, pairs)
        SV *class
        SV *pairs
    CODE:
    {
        pv_views *v;
        AV *ps;
        SSize_t i, n;
        if (!SvROK(pairs) || SvTYPE(SvRV(pairs)) != SVt_PVAV)
            croak("Punk::Views::new: pairs must be an arrayref");
        ps = (AV *)SvRV(pairs);
        n = av_len(ps) + 1;
        if (n <= 0)
            croak("Punk::Views: no view engine configured - add a views keyword");
        v = pv_new(aTHX);
        for (i = 0; i < n; i++) {
            SV **e = av_fetch(ps, i, 0);
            AV *pair;
            SV **nm, **op;
            if (!e || !*e || !SvROK(*e) || SvTYPE(SvRV(*e)) != SVt_PVAV) {
                pv_free(aTHX_ v);
                croak("Punk::Views::new: pair %d is not an arrayref", (int)i);
            }
            pair = (AV *)SvRV(*e);
            nm = av_fetch(pair, 0, 0);
            op = av_fetch(pair, 1, 0);
            pv_load_engine(aTHX_ v, (nm && *nm) ? *nm : &PL_sv_undef,
                           (op && *op) ? *op : NULL);
        }
        RETVAL = sv_setref_iv(newSV(0), SvPV_nolen(class), PTR2IV(v));
    }
    OUTPUT:
        RETVAL

# The default engine's name.
SV *
default(self)
        SV *self
    CODE:
    {
        pv_views *v = pv_of(aTHX_ self);
        RETVAL = v->deflt ? newSVsv(v->deflt) : newSV(0);
    }
    OUTPUT:
        RETVAL

# The named (or default) engine object; unknown names croak.
SV *
engine(self, ...)
        SV *self
    CODE:
        RETVAL = newSVsv(pv_engine(aTHX_ pv_of(aTHX_ self),
                                   items > 1 ? ST(1) : NULL));
    OUTPUT:
        RETVAL

# render($c, $template, \%data, %over): call the engine's render and assemble
# the PSGI triplet in C. $over: status, type, engine. Status and headers fold
# in from $c (a Punk::Context, or undef). The engine's returned bytes are
# copied into the body so Template::Stencil's reused render buffer is intact.
void
render(self, c, template, data = &PL_sv_undef, ...)
        SV *self
        SV *c
        SV *template
        SV *data
    PPCODE:
    {
        pv_views *v = pv_of(aTHX_ self);
        SV *o_status = NULL, *o_type = NULL, *o_engine = NULL;
        SV *engine, *bytes, *body, *ct;
        AV *headers, *bodyav, *resp;
        IV status = 0;
        int i;
        int have_c = (c && SvOK(c));

        for (i = 4; i + 1 < items; i += 2) {
            STRLEN kl;
            const char *k = SvPV_const(ST(i), kl);
            if      (kl == 6 && memEQ(k, "status", 6)) o_status = ST(i + 1);
            else if (kl == 4 && memEQ(k, "type", 4))   o_type   = ST(i + 1);
            else if (kl == 6 && memEQ(k, "engine", 6)) o_engine = ST(i + 1);
        }

        engine = pv_engine(aTHX_ v, o_engine);

        /* engine->render($template, $data || {}) */
        {
            dSP;
            int count;
            SV *d = SvOK(data) ? data : sv_2mortal(newRV_noinc((SV *)newHV()));
            /* Punk::Plugin::CSP: this request's nonce, so `{% csp_nonce %}`
             * resolves without the handler passing anything. A no-op unless
             * the plugin is registered for this app. */
            if (have_c) pcsp_bind_vars(aTHX_ c, d);
            ENTER; SAVETMPS;
            PUSHMARK(SP);
            EXTEND(SP, 3);
            PUSHs(engine);
            PUSHs(template);
            PUSHs(d);
            PUTBACK;
            count = call_method("render", G_SCALAR);
            SPAGAIN;
            bytes = count > 0 ? SvREFCNT_inc(POPs) : newSV(0);
            PUTBACK;
            FREETMPS; LEAVE;
        }

        /* Punk::Plugin::CSP's inline-handler check. Development only, and it
         * never touches `bytes` - a checker with authority over the response
         * is a checker that gets removed the first time it breaks a page. */
        if (have_c) pcsp_scan(aTHX_ c, template, bytes);

        /* status: override, else the context's pending status, else 200 */
        if (o_status && SvOK(o_status)) status = SvIV(o_status);
        else if (have_c) {
            dSP;
            int count;
            ENTER; SAVETMPS;
            PUSHMARK(SP);
            XPUSHs(c);
            PUTBACK;
            count = call_method("_status", G_SCALAR);
            SPAGAIN;
            if (count > 0) { SV *s = POPs; if (SvOK(s)) status = SvIV(s); }
            PUTBACK;
            FREETMPS; LEAVE;
        }
        if (!status) status = 200;

        ct = (o_type && SvOK(o_type)) ? newSVsv(o_type)
                                      : newSVpvs("text/html; charset=utf-8");

        headers = newAV();
        av_push(headers, newSVpvs("Content-Type"));
        av_push(headers, ct);
        if (have_c) {   /* fold in $c->_headers pairs */
            dSP;
            int count;
            ENTER; SAVETMPS;
            PUSHMARK(SP);
            XPUSHs(c);
            PUTBACK;
            count = call_method("_headers", G_SCALAR);
            SPAGAIN;
            if (count > 0) {
                SV *hr = POPs;
                if (SvROK(hr) && SvTYPE(SvRV(hr)) == SVt_PVAV) {
                    AV *ch = (AV *)SvRV(hr);
                    SSize_t j, hn = av_len(ch) + 1;
                    for (j = 0; j < hn; j++) {
                        SV **hp = av_fetch(ch, j, 0);
                        av_push(headers, hp && *hp ? newSVsv(*hp) : newSV(0));
                    }
                }
            }
            PUTBACK;
            FREETMPS; LEAVE;
        }

        /* copy the engine's bytes so its reused buffer is not shared */
        body = newSVsv(bytes);
        SvREFCNT_dec(bytes);
        av_push(headers, newSVpvs("Content-Length"));
        av_push(headers, newSViv((IV)SvCUR(body)));

        bodyav = newAV();
        av_push(bodyav, body);
        resp = newAV();
        av_extend(resp, 2);
        av_push(resp, newSViv(status));
        av_push(resp, newRV_noinc((SV *)headers));
        av_push(resp, newRV_noinc((SV *)bodyav));
        mXPUSHs(newRV_noinc((SV *)resp));
    }

void
DESTROY(self)
        SV *self
    CODE:
    {
        if (SvROK(self) && SvIOK(SvRV(self)))
            pv_free(aTHX_ pv_of(aTHX_ self));
    }
