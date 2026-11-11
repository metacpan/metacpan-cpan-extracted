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
        # uncoverable branch true
        # uncoverable condition left count:1 class:ignore_covered_err
        # uncoverable condition left count:2 class:ignore_covered_err
        if (!SvROK(pairs) || SvTYPE(SvRV(pairs)) != SVt_PVAV)
            croak("Punk::Views::new: pairs must be an arrayref"); /* # uncoverable statement */
        ps = (AV *)SvRV(pairs);
        n = av_len(ps) + 1;
        # uncoverable branch true
        # uncoverable condition left count:1 class:ignore_covered_err
        if (n <= 0)
            croak("Punk::Views: no view engine configured - add a views keyword"); /* # uncoverable statement */
        v = pv_new(aTHX);
        for (i = 0; i < n; i++) {
            SV **e = av_fetch(ps, i, 0);
            AV *pair;
            SV **nm, **op;
            # uncoverable branch true
            # uncoverable condition left count:1 class:ignore_covered_err
            # uncoverable condition left count:2 class:ignore_covered_err
            # uncoverable condition left count:3 class:ignore_covered_err
            # uncoverable condition left count:4 class:ignore_covered_err
            if (!e || !*e || !SvROK(*e) || SvTYPE(SvRV(*e)) != SVt_PVAV) {
                pv_free(aTHX_ v); /* # uncoverable statement */
                croak("Punk::Views::new: pair %d is not an arrayref", (int)i); /* # uncoverable statement */
            }
            pair = (AV *)SvRV(*e);
            nm = av_fetch(pair, 0, 0);
            op = av_fetch(pair, 1, 0);
            # uncoverable condition right count:1 class:ignore_covered_err
            # uncoverable condition right count:2 class:ignore_covered_err
            # uncoverable condition right count:3 class:ignore_covered_err
            # uncoverable condition right count:4 class:ignore_covered_err
            pv_load_engine(aTHX_ v, (nm && *nm) ? *nm : &PL_sv_undef,
                           (op && *op) ? *op : NULL);
        }
        RETVAL = sv_setref_iv(newSV(0), SvPV_nolen(class), PTR2IV(v));
    }
    OUTPUT:
        RETVAL

# The default engine's name.
SV *
# uncoverable statement
# uncoverable subroutine
default(self)
        SV *self
    CODE:
    {
        pv_views *v = pv_of(aTHX_ self); /* # uncoverable statement */
        # uncoverable statement
        # uncoverable condition left count:1
        # uncoverable condition right count:1
        RETVAL = v->deflt ? newSVsv(v->deflt) : newSV(0);
    }
    OUTPUT:
        RETVAL

# The named (or default) engine object; unknown names croak.
SV *
# uncoverable statement class:ignore_covered_err
# uncoverable subroutine class:ignore_covered_err
engine(self, ...)
        SV *self
    CODE:
        RETVAL = newSVsv(pv_engine(aTHX_ pv_of(aTHX_ self), /* # uncoverable statement class:ignore_covered_err */
                                   items > 1 ? ST(1) : NULL));
    OUTPUT:
        RETVAL

# render($c, $template, \%data, %over): call the engine's render and assemble
# the PSGI triplet in C. $over: status, type, engine, layout. Status and headers
# fold in from $c (a Punk::Context, or undef). The engine's returned bytes are
# copied into the body so Template::Stencil's reused render buffer is intact.
#
# `layout` reaches the engine as a third argument, { wrapper => $name | undef }
# - the per-render option Template::Stencil already takes, spelled with the
# framework's word on this side and the engine's on that. It is passed only
# when given, so an engine written to the two-argument contract sees nothing
# new until a caller asks for a layout - and then ignores it, which the
# contract in Punk::Views says in so many words.
#
# An override this does not know croaks. It used to be skipped, which meant
# `layout => undef` rendered WITH the layout and told nobody - the option that
# looks like it worked is worse than the one that failed.
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
        SV *o_layout = NULL; int have_layout = 0;
        SV *engine, *bytes, *body, *ct;
        AV *headers, *bodyav, *resp;
        IV status = 0;
        int i;
        int have_c = (c && SvOK(c)); /* # uncoverable condition right count:1 class:ignore_covered_err */

        if (items > 4 && ((items - 4) & 1))
            croak("Punk::Views::render: overrides are name => value pairs "
                  "(status, type, engine, layout)");
        for (i = 4; i + 1 < items; i += 2) {
            STRLEN kl;
            const char *k = SvPV_const(ST(i), kl);
            if      (kl == 6 && memEQ(k, "status", 6)) o_status = ST(i + 1);
            else if (kl == 4 && memEQ(k, "type", 4))   o_type   = ST(i + 1); /* # uncoverable condition right count:2 class:ignore_covered_err */
            else if (kl == 6 && memEQ(k, "engine", 6)) o_engine = ST(i + 1); /* # uncoverable condition right count:1 class:ignore_covered_err */
            else if (kl == 6 && memEQ(k, "layout", 6)) { /* # uncoverable condition right count:1 class:ignore_covered_err */
                o_layout = ST(i + 1); have_layout = 1;
            }
            else
                croak("Punk::Views::render: unknown override '%.*s' "
                      "(known: status, type, engine, layout)", (int)kl, k);
        }

        engine = pv_engine(aTHX_ v, o_engine);

        /* engine->render($template, $data || {} [, { wrapper => $layout }]) */
        {
            dSP;
            int count;
            SV *d = SvOK(data) ? data : sv_2mortal(newRV_noinc((SV *)newHV()));
            SV *eo = NULL;
            if (have_layout) {
                HV *oh = newHV();
                (void)hv_stores(oh, "wrapper",
                                (o_layout && SvOK(o_layout)) ? newSVsv(o_layout)
                                                             : newSV(0));
                eo = sv_2mortal(newRV_noinc((SV *)oh));
            }
            /* Punk::Plugin::CSP: this request's nonce, so `{% csp_nonce %}`
             * resolves without the handler passing anything. A no-op unless
             * the plugin is registered for this app. */
            if (have_c) pcsp_bind_vars(aTHX_ c, d);
            /* Punk::Plugin::I18n: this request's catalogue, so
             * `{% locale.welcome %}` resolves without the handler passing
             * anything. A no-op unless the plugin is registered. */
            if (have_c) pi_bind_vars(aTHX_ c, d);
            ENTER; SAVETMPS;
            /* Named routes: this request's `url` hash, so `{% url.books %}`
             * resolves without the handler passing anything, and the prefix
             * the url_for filter reads for the length of this render. Inside
             * the ENTER because it save_items that prefix - punk_url.h says
             * why putting it back matters more than setting it. */
            if (have_c) pk_url_bind_vars(aTHX_ c, d);
            /* before_render: a plugin's chance to put something into the data
             * every template gets, after Punk's own binds so an application
             * that wants the last word still has it by passing the key. The
             * chain is absent unless somebody registered one, so the ordinary
             * render pays one hv_fetch that misses. */
            if (have_c) pv_before_render(aTHX_ c, template, d);
            /* A hook is arbitrary Perl, and every call it makes moves the
             * real stack - so the SP this scope has held since the top of
             * the function is stale. Pushing the engine call onto it writes
             * over whatever is there now, which surfaces as "Out of memory
             * during stack extend" somewhere else entirely. */
            SPAGAIN;
            PUSHMARK(SP);
            EXTEND(SP, 4);
            PUSHs(engine);
            PUSHs(template);
            PUSHs(d);
            if (eo) PUSHs(eo);
            PUTBACK;
            count = call_method("render", G_SCALAR);
            SPAGAIN;
            bytes = count > 0 ? SvREFCNT_inc(POPs) : newSV(0); /* # uncoverable condition right count:1 class:ignore_covered_err */
            PUTBACK;
            FREETMPS; LEAVE;
        }

        /* Punk::Plugin::CSP's inline-handler check. Development only, and it
         * never touches `bytes` - a checker with authority over the response
         * is a checker that gets removed the first time it breaks a page. */
        if (have_c) pcsp_scan(aTHX_ c, template, bytes);

        /* status: override, else the context's pending status, else 200 */
        if (o_status && SvOK(o_status)) status = SvIV(o_status); /* # uncoverable condition right count:2 class:ignore_covered_err */
        else if (have_c) {
            dSP;
            int count;
            ENTER; SAVETMPS;
            PUSHMARK(SP);
            XPUSHs(c);
            PUTBACK;
            count = call_method("_status", G_SCALAR);
            SPAGAIN;
            # uncoverable branch false class:ignore_covered_err
            # uncoverable condition right count:1 class:ignore_covered_err
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
            # uncoverable branch false
            # uncoverable condition right count:1 class:ignore_covered_err
            if (count > 0) {
                SV *hr = POPs;
                # uncoverable branch false
                # uncoverable condition right count:1 class:ignore_covered_err
                # uncoverable condition right count:2 class:ignore_covered_err
                if (SvROK(hr) && SvTYPE(SvRV(hr)) == SVt_PVAV) {
                    AV *ch = (AV *)SvRV(hr);
                    SSize_t j, hn = av_len(ch) + 1;
                    for (j = 0; j < hn; j++) {
                        SV **hp = av_fetch(ch, j, 0);
                        # uncoverable condition right count:1 class:ignore_covered_err
                        # uncoverable condition right count:2 class:ignore_covered_err
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

        /* SPAGAIN before the push, and it is not ceremony.
         *
         * Everything between here and the top of this XSUB - the engine's
         * render, _status, _headers, and any before_render hook - is Perl,
         * and Perl that grows the value stack REALLOCATES it. `sp` has been
         * a C pointer into the old buffer since the PPCODE prologue, so
         * pushing on it writes into freed memory and the caller gets an
         * empty list back: a handler returning nothing, which the dispatcher
         * serialises as `null` with a 200.
         *
         * It only bites when something in the middle grows the stack far
         * enough to realloc - a first render that opens a database will,
         * a second one will not - which is why it looks intermittent and is
         * not. */
        SPAGAIN;
        mXPUSHs(newRV_noinc((SV *)resp));
    }

void
DESTROY(self)
        SV *self
    CODE:
    {
        if (SvROK(self) && SvIOK(SvRV(self))) /* # uncoverable condition right count:1 class:ignore_covered_err */
            pv_free(aTHX_ pv_of(aTHX_ self));
    }
