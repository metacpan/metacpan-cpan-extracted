MODULE = Punk::OpenTelemetry    PACKAGE = Punk::OpenTelemetry::Exporter

PROTOTYPES: DISABLE

# new(%opt): endpoint, endpoints, protocol, headers, timeout, compression,
# max_retries, ua. The object is a blessed HASH with exactly those keys plus
# `stats`, because they are part of the interface - an application reads
# $e->{protocol} and bumps $e->{stats}{dropped}.
SV *
new(class, ...)
        SV *class
    CODE:
    {
        HV *self = newHV();
        HV *args = newHV();
        SV *proto, *ua, *tmo;
        const char *cls = (SvROK(class) && SvOBJECT(SvRV(class)))
                        ? HvNAME(SvSTASH(SvRV(class))) : SvPV_nolen(class);
        int i;
        sv_2mortal((SV *)args);
        if ((items - 1) % 2)
            croak("Punk::OpenTelemetry::Exporter::new: odd number of options");
        for (i = 1; i + 1 < items; i += 2) {
            STRLEN kl;
            const char *k = SvPV_const(ST(i), kl);
            (void)hv_store(args, k, (I32)kl, newSVsv(ST(i + 1)), 0);
        }

        proto = otel_h(aTHX_ args, "protocol");
        if (!proto) proto = sv_2mortal(newSVpvs("http/protobuf"));
        {
            STRLEN pl;
            const char *pp = SvPV_const(proto, pl);
            if (!otel_exp_content_type(pp, pl))
                croak("Punk::OpenTelemetry::Exporter: unknown protocol '%s' "
                      "(http/protobuf or http/json)\n", pp);
        }

        (void)hv_stores(self, "endpoint",
            (tmo = otel_h(aTHX_ args, "endpoint")) ? newSVsv(tmo) : newSV(0));
        (void)hv_stores(self, "endpoints",
            otel_h_hv(aTHX_ args, "endpoints")
                ? newSVsv(*hv_fetchs(args, "endpoints", 0))
                : newRV_noinc((SV *)newHV()));
        (void)hv_stores(self, "protocol", newSVsv(proto));
        (void)hv_stores(self, "headers",
            otel_h_hv(aTHX_ args, "headers")
                ? newSVsv(*hv_fetchs(args, "headers", 0))
                : newRV_noinc((SV *)newHV()));
        tmo = otel_h(aTHX_ args, "timeout");
        (void)hv_stores(self, "timeout", tmo ? newSVsv(tmo) : newSViv(10));
        (void)hv_stores(self, "compression",
            (tmo = otel_h(aTHX_ args, "compression")) ? newSVsv(tmo)
                                                      : newSVpvs("none"));
        tmo = otel_h(aTHX_ args, "max_retries");
        (void)hv_stores(self, "max_retries", tmo ? newSVsv(tmo) : newSViv(5));

        {   /* what happened, so a telemetry layer can report its own losses -
             * one that cannot is asking to be trusted for no reason */
            HV *st = newHV();
            (void)hv_stores(st, "exported", newSViv(0));
            (void)hv_stores(st, "rejected", newSViv(0));
            (void)hv_stores(st, "dropped",  newSViv(0));
            (void)hv_stores(st, "failures", newSViv(0));
            (void)hv_stores(st, "retries",  newSViv(0));
            (void)hv_stores(st, "partial",  newSViv(0));
            (void)hv_stores(self, "stats", newRV_noinc((SV *)st));
        }

        ua = otel_h(aTHX_ args, "ua");
        if (ua) (void)hv_stores(self, "ua", newSVsv(ua));
        else {
            dSP; int count; SV *made = NULL;
            SV *t = otel_h(aTHX_ self, "timeout");
            /* Fetch has to be LOADED before it can be called. It is a runtime
             * prerequisite of this dist rather than a compile-time one, so
             * nothing else has necessarily pulled it in, and a caller who
             * passed no `ua` is precisely the caller who did not think about
             * the HTTP client at all. Failing here with "can't locate method
             * new via package Fetch" sends them looking for a typo. */
            eval_pv("require Fetch;", FALSE);
            SPAGAIN;
            ENTER; SAVETMPS;
            PUSHMARK(SP); EXTEND(SP, 3);
            PUSHs(sv_2mortal(newSVpvs("Fetch")));
            PUSHs(sv_2mortal(newSVpvs("timeout")));
            PUSHs(t ? t : sv_2mortal(newSViv(10)));
            PUTBACK;
            count = call_method("new", G_SCALAR | G_EVAL);
            SPAGAIN;
            if (!SvTRUE(ERRSV) && count > 0) made = newSVsv(POPs);
            else if (count > 0) (void)POPs;
            PUTBACK; FREETMPS; LEAVE;
            if (!made)
                croak("Punk::OpenTelemetry::Exporter: no `ua` given and "
                      "Fetch->new failed: %" SVf, SVfARG(ERRSV));
            (void)hv_stores(self, "ua", made);
        }

        RETVAL = sv_bless(newRV_noinc((SV *)self), gv_stashpv(cls, GV_ADD));
    }
    OUTPUT:
        RETVAL

# stats(): a COPY of the counters, so a caller cannot edit the live hash by
# accident - and so a snapshot taken now still reads the same later.
SV *
stats(self)
        SV *self
    CODE:
    {
        HV *h = otel_hv_of(aTHX_ self);
        HV *st = h ? otel_h_hv(aTHX_ h, "stats") : NULL;
        HV *out = newHV();
        if (st) {
            HE *e;
            hv_iterinit(st);
            while ((e = hv_iternext(st))) {
                STRLEN kl;
                const char *k = HePV(e, kl);
                (void)hv_store(out, k, (I32)kl, newSVsv(HeVAL(e)), 0);
            }
        }
        RETVAL = newRV_noinc((SV *)out);
    }
    OUTPUT:
        RETVAL

# _endpoint_for($signal): the URL to post this signal to, or undef.
SV *
_endpoint_for(self, signal)
        SV *self
        SV *signal
    CODE:
    {
        HV *h = otel_hv_of(aTHX_ self);
        SV *u = h ? otel_exp_endpoint_for(aTHX_ h, signal) : NULL;
        if (!u) XSRETURN_UNDEF;
        RETVAL = newSVsv(u);
    }
    OUTPUT:
        RETVAL

# _classify($status, $headers, $body) -> ($verdict, $detail)
#
#   ok        - accepted in full
#   partial   - accepted, but some of it was rejected. NOT a failure and NOT
#               retryable; the count has to be surfaced or data disappears
#               while every dashboard stays green.
#   retry     - a transient refusal; detail is the Retry-After seconds, if any
#   permanent - a refusal that will not improve by being repeated
void
_classify(self, status, headers = &PL_sv_undef, body = &PL_sv_undef)
        SV *self
        SV *status
        SV *headers
        SV *body
    PPCODE:
    {
        HV *h = otel_hv_of(aTHX_ self);
        IV st;
        if (!h) croak("Punk::OpenTelemetry::Exporter::_classify: not an exporter");
        if (!SvOK(status)) {                       /* transport failure */
            EXTEND(SP, 2);
            mPUSHp("retry", 5);
            PUSHs(&PL_sv_undef);
            XSRETURN(2);
        }
        st = SvIV(status);
        if (st >= 200 && st < 300) {
            SV *p = otel_exp_is_json(aTHX_ h)
                  ? otel_exp_parse_partial_json(aTHX_ body)
                  : otel_exp_parse_partial(aTHX_ body);
            if (p) {
                HV *ph = otel_hv_of(aTHX_ p);
                SV **r = ph ? hv_fetchs(ph, "rejected", 0) : NULL;
                if (r && *r && SvTRUE(*r)) {
                    EXTEND(SP, 2);
                    mPUSHp("partial", 7);
                    PUSHs(p);
                    XSRETURN(2);
                }
            }
            EXTEND(SP, 2);
            mPUSHp("ok", 2);
            PUSHs(&PL_sv_undef);
            XSRETURN(2);
        }
        if (otel_exp_retryable(st)) {
            SV *after = otel_exp_retry_after(aTHX_ headers);
            EXTEND(SP, 2);
            mPUSHp("retry", 5);
            PUSHs(after ? after : &PL_sv_undef);
            XSRETURN(2);
        }
        EXTEND(SP, 2);
        mPUSHp("permanent", 9);
        PUSHs(&PL_sv_undef);
        XSRETURN(2);
    }

# backoff($attempt, $retry_after): the delay before this attempt. Pure, so the
# policy is tested directly rather than inferred from timings.
NV
backoff(self, attempt, retry_after = &PL_sv_undef)
        SV *self
        IV attempt
        SV *retry_after
    CODE:
        PERL_UNUSED_VAR(self);
        RETVAL = otel_exp_backoff(aTHX_ attempt, retry_after);
    OUTPUT:
        RETVAL

# _retry_after($headers): exposed so the header parse is tested on its own
# rather than only through a 503.
SV *
_retry_after(headers)
        SV *headers
    CODE:
    {
        SV *v = otel_exp_retry_after(aTHX_ headers);
        if (!v) XSRETURN_UNDEF;
        RETVAL = newSVsv(v);
    }
    OUTPUT:
        RETVAL

# _parse_partial($bytes) / _parse_partial_json($bytes)
SV *
_parse_partial(body)
        SV *body
    CODE:
    {
        SV *p = otel_exp_parse_partial(aTHX_ body);
        if (!p) XSRETURN_UNDEF;
        RETVAL = newSVsv(p);
    }
    OUTPUT:
        RETVAL

SV *
_parse_partial_json(body)
        SV *body
    CODE:
    {
        SV *p = otel_exp_parse_partial_json(aTHX_ body);
        if (!p) XSRETURN_UNDEF;
        RETVAL = newSVsv(p);
    }
    OUTPUT:
        RETVAL

# encode($signal, $payload): the payload as bytes for the configured protocol.
SV *
encode(self, signal, payload)
        SV *self
        SV *signal
        SV *payload
    CODE:
    {
        HV *h = otel_hv_of(aTHX_ self);
        STRLEN sl;
        const char *sp = SvOK(signal) ? SvPV_const(signal, sl) : "";
        if (!SvOK(signal)) sl = 0;
        if (!h) croak("Punk::OpenTelemetry::Exporter::encode: not an exporter");
        if (!(sl == 6 && memEQ(sp, "traces", 6)))
            croak("Punk::OpenTelemetry::Exporter: only traces are "
                  "implemented\n");
        if (!(payload && SvROK(payload) && SvTYPE(SvRV(payload)) == SVt_PVHV))
            croak("Punk::OpenTelemetry::Exporter::encode: "
                  "expected a hashref payload");
        if (otel_exp_is_json(aTHX_ h)) {
            frj_opts o;
            SV *tree;
            Zero(&o, 1, frj_opts);
            o.sort_keys = 1;      /* same reason as Encode::traces_json */
            tree = sv_2mortal(otel_json_traces_sv(aTHX_ (HV *)SvRV(payload)));
            RETVAL = otel_frj(aTHX)->encode(aTHX_ tree, &o);
        }
        else RETVAL = otel_encode_traces(aTHX_ (HV *)SvRV(payload));
    }
    OUTPUT:
        RETVAL

# _attempt($signal, $bytes): one POST. Returns the ua's future, or undef when
# no endpoint is configured for the signal.
SV *
_attempt(self, signal, bytes)
        SV *self
        SV *signal
        SV *bytes
    CODE:
    {
        HV *h = otel_hv_of(aTHX_ self);
        SV *url, *ua, *body;
        AV *hdrs;
        HV *extra;
        if (!h) croak("Punk::OpenTelemetry::Exporter::_attempt: not an exporter");
        url = otel_exp_endpoint_for(aTHX_ h, signal);
        if (!url) XSRETURN_UNDEF;
        {
            hdrs = (AV *)sv_2mortal((SV *)newAV());
            {
                SV *p = otel_h(aTHX_ h, "protocol");
                STRLEN pl;
                const char *pp = p ? SvPV_const(p, pl) : "";
                if (!p) pl = 0;
                av_push(hdrs, newSVpvs("Content-Type"));
                av_push(hdrs, newSVpv(otel_exp_content_type(pp, pl), 0));
            }
            extra = otel_h_hv(aTHX_ h, "headers");
            if (extra) {
                HE *e;
                hv_iterinit(extra);
                while ((e = hv_iternext(extra))) {
                    STRLEN kl;
                    const char *k = HePV(e, kl);
                    av_push(hdrs, newSVpvn(k, kl));
                    av_push(hdrs, newSVsv(HeVAL(e)));
                }
            }

            body = bytes;
            {   /* gzip when asked for it and IO::Compress::Gzip is there; a
                 * missing compressor sends it uncompressed rather than not at
                 * all, because telemetry that did not arrive is worse than
                 * telemetry that arrived large */
                SV *c = otel_h(aTHX_ h, "compression");
                STRLEN cl;
                const char *cp = c ? SvPV_const(c, cl) : "";
                if (c && cl == 4 && memEQ(cp, "gzip", 4)) {
                    SV *out = sv_2mortal(newSVpvs(""));
                    dSP; int count; int ok = 0;
                    eval_pv("require IO::Compress::Gzip;", FALSE);
                    SPAGAIN;
                    if (!SvTRUE(ERRSV)) {
                        ENTER; SAVETMPS;
                        PUSHMARK(SP); EXTEND(SP, 2);
                        PUSHs(sv_2mortal(newRV_inc(bytes)));
                        PUSHs(sv_2mortal(newRV_inc(out)));
                        PUTBACK;
                        count = call_pv("IO::Compress::Gzip::gzip",
                                        G_SCALAR | G_EVAL);
                        SPAGAIN;
                        /* POPs into a TEMPORARY, never straight into SvTRUE.
                         * Before perl 5.30 SvTRUE is a macro that evaluates
                         * its argument more than once, so SvTRUE(POPs) pops
                         * the stack several times and corrupts it - the crash
                         * lands later, wherever the damaged stack is next
                         * used, which is why this showed up as a SEGV after
                         * all 72 subtests had passed. */
                        if (!SvTRUE(ERRSV) && count > 0) {
                            SV *r = POPs;
                            ok = SvTRUE(r);
                        }
                        else if (count > 0) (void)POPs;
                        PUTBACK; FREETMPS; LEAVE;
                    }
                    if (ok && SvCUR(out)) {
                        body = out;
                        av_push(hdrs, newSVpvs("Content-Encoding"));
                        av_push(hdrs, newSVpvs("gzip"));
                    }
                }
            }

            ua = otel_h(aTHX_ h, "ua");
            if (!ua) croak("Punk::OpenTelemetry::Exporter::_attempt: no ua");
            {
                dSP; int count; SV *f = NULL;
                SV *t = otel_h(aTHX_ h, "timeout");
                ENTER; SAVETMPS;
                PUSHMARK(SP); EXTEND(SP, 9);
                PUSHs(ua);
                PUSHs(sv_2mortal(newSVpvs("POST")));
                PUSHs(url);
                PUSHs(sv_2mortal(newSVpvs("headers")));
                PUSHs(sv_2mortal(newRV_inc((SV *)hdrs)));
                PUSHs(sv_2mortal(newSVpvs("body")));
                PUSHs(body);
                PUSHs(sv_2mortal(newSVpvs("timeout")));
                PUSHs(t ? t : sv_2mortal(newSViv(10)));
                PUTBACK;
                count = call_method("request", G_SCALAR);
                SPAGAIN;
                if (count > 0) f = newSVsv(POPs);
                PUTBACK; FREETMPS; LEAVE;
                if (!f) XSRETURN_UNDEF;
                RETVAL = f;
            }
        }
    }
    OUTPUT:
        RETVAL

# _sleep($secs, $cb): wait, then call back. On a loop that can time (Fetch's
# adapters) this parks; with no loop it blocks, which is the honest thing for a
# retry in a script. Returns 1 when it parked, 0 when it blocked.
IV
_sleep(self, secs, cb)
        SV *self
        NV secs
        SV *cb
    CODE:
    {
        HV *h = otel_hv_of(aTHX_ self);
        SV *ua = h ? otel_h(aTHX_ h, "ua") : NULL;
        SV *loop = NULL;
        RETVAL = 0;
        if (ua) {
            dSP; int count;
            ENTER; SAVETMPS;
            PUSHMARK(SP); EXTEND(SP, 1); PUSHs(ua); PUTBACK;
            count = call_method("loop", G_SCALAR | G_EVAL);
            SPAGAIN;
            if (!SvTRUE(ERRSV) && count > 0) { SV *l = POPs; if (SvOK(l)) loop = newSVsv(l); }
            else if (count > 0) (void)POPs;
            PUTBACK; FREETMPS; LEAVE;
        }
        if (loop) sv_2mortal(loop);
        if (loop && SvROK(loop) && SvOBJECT(SvRV(loop))
            && gv_fetchmethod_autoload(SvSTASH(SvRV(loop)), "_ft_timer", 0)) {
            dSP;
            ENTER; SAVETMPS;
            PUSHMARK(SP); EXTEND(SP, 3);
            PUSHs(loop);
            PUSHs(sv_2mortal(newSVnv(secs)));
            PUSHs(cb);
            PUTBACK;
            (void)call_method("_ft_timer", G_VOID | G_DISCARD);
            SPAGAIN; PUTBACK; FREETMPS; LEAVE;
            RETVAL = 1;
        }
        else {
            dSP;
            {   /* select undef,undef,undef,$secs - the same blocking wait */
                struct timeval tv;
                NV s = secs > 0 ? secs : 0;
                tv.tv_sec  = (long)s;
                tv.tv_usec = (long)((s - (NV)tv.tv_sec) * 1000000.0);
                PerlSock_select(0, NULL, NULL, NULL, &tv);
            }
            ENTER; SAVETMPS;
            PUSHMARK(SP); PUTBACK;
            (void)call_sv(cb, G_VOID | G_DISCARD);
            SPAGAIN; PUTBACK; FREETMPS; LEAVE;
        }
    }
    OUTPUT:
        RETVAL
