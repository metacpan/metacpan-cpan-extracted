MODULE = Punk::OpenTelemetry    PACKAGE = Punk::OpenTelemetry::Tracer

PROTOTYPES: DISABLE

# The tracer. One per process; spans are C structs and an unsampled span is
# never built at all.

SV *
new(class, ...)
        SV *class
    CODE:
    {
        otel_tracer *t = otel_tracer_new(aTHX);
        int i;
        for (i = 1; i + 1 < items; i += 2) {
            const char *k = SvPV_nolen(ST(i));
            SV *v = ST(i + 1);
            if      (strEQ(k, "scope_name"))    t->scope_name    = newSVsv(v);
            else if (strEQ(k, "scope_version")) t->scope_version = newSVsv(v);
            else if (strEQ(k, "schema_url"))    t->schema_url    = newSVsv(v);
            else if (strEQ(k, "scope_schema_url"))
                t->scope_schema_url = newSVsv(v);
            else if (strEQ(k, "resource")) {
                if (SvROK(v) && SvTYPE(SvRV(v)) == SVt_PVHV) {
                    HV *src = (HV *)SvRV(v);
                    HE *he;
                    hv_iterinit(src);
                    while ((he = hv_iternext(src)))
                        (void)hv_store_ent(t->resource, hv_iterkeysv(he),
                                           newSVsv(HeVAL(he)), 0);
                }
            }
            else if (strEQ(k, "sampler")) {
                const char *s = SvPV_nolen(v);
                int kind = strEQ(s, "always_on")  ? OTEL_SAMPLER_ALWAYS_ON
                         : strEQ(s, "always_off") ? OTEL_SAMPLER_ALWAYS_OFF
                         : OTEL_SAMPLER_PARENT_RATIO;
                otel_sampler_init(&t->sampler, kind, t->sampler.ratio);
            }
            else if (strEQ(k, "ratio"))
                otel_sampler_init(&t->sampler, t->sampler.kind, SvNV(v));
        }
        RETVAL = sv_bless(newRV_noinc(newSViv(PTR2IV(t))),
                          gv_stashpv("Punk::OpenTelemetry::Tracer", GV_ADD));
    }
    OUTPUT:
        RETVAL

void
DESTROY(self)
        SV *self
    CODE:
        if (SvROK(self) && SvIOK(SvRV(self)))
            otel_tracer_free(aTHX_ INT2PTR(otel_tracer *, SvIV(SvRV(self))));

# start($name, %opt) -> a span object, or undef when the trace is not sampled.
#
# An undef return is the SUCCESS path for an unsampled trace, not an error:
# at a 1% ratio the other 99% of requests allocate nothing, which is the whole reason
# sampling is worth having. Callers must cope with undef.
#
# Options: kind, parent (a { trace_id, span_id, sampled } hashref from an
# extracted inbound context).
SV *
start(self, name, ...)
        SV *self
        SV *name
    CODE:
    {
        otel_tracer *t = INT2PTR(otel_tracer *, SvIV(SvRV(self)));
        unsigned char ptid[16], psid[8];
        const unsigned char *ptp = NULL, *psp = NULL;
        int kind = OTEL_KIND_INTERNAL, psampled = 0, i;
        otel_span *s;

        for (i = 2; i + 1 < items; i += 2) {
            const char *k = SvPV_nolen(ST(i));
            SV *v = ST(i + 1);
            if (strEQ(k, "kind")) kind = (int)SvIV(v);
            else if (strEQ(k, "parent") && SvROK(v)
                     && SvTYPE(SvRV(v)) == SVt_PVHV) {
                HV *p = (HV *)SvRV(v);
                SV **tp = hv_fetchs(p, "trace_id", 0);
                SV **sp = hv_fetchs(p, "span_id", 0);
                SV **fl = hv_fetchs(p, "sampled", 0);
                STRLEN tl, sl;
                const char *ts, *ss;
                if (tp && *tp && sp && *sp) {
                    ts = SvPV_const(*tp, tl);
                    ss = SvPV_const(*sp, sl);
                    /* an unparseable or all-zero id is treated as ABSENT
                     * rather than as a parent: a span claiming a parent that
                     * cannot exist is worse than a root span */
                    if (otel_hex_to_bytes(ts, tl, ptid, 16)
                        && otel_hex_to_bytes(ss, sl, psid, 8)) {
                        ptp = ptid; psp = psid;
                        psampled = (fl && *fl && SvTRUE(*fl)) ? 1 : 0;
                    }
                }
            }
        }
        s = otel_tracer_start(aTHX_ t, ptp, psp, psampled, name, kind);
        if (!s) XSRETURN_UNDEF;
        RETVAL = sv_bless(newRV_noinc(newSViv(PTR2IV(s))),
                          gv_stashpv("Punk::OpenTelemetry::Span", GV_ADD));
    }
    OUTPUT:
        RETVAL

# Move an ended span onto the export queue.
void
enqueue(self, span)
        SV *self
        SV *span
    CODE:
    {
        otel_tracer *t = INT2PTR(otel_tracer *, SvIV(SvRV(self)));
        otel_span *s;
        if (!(SvROK(span) && SvIOK(SvRV(span)))) XSRETURN_EMPTY;
        s = INT2PTR(otel_span *, SvIV(SvRV(span)));
        otel_span_end(aTHX_ s);
        otel_tracer_enqueue(aTHX_ t, s);
        t->ended++;
        /* the queue owns it now; blank the handle so DESTROY cannot free it
         * a second time */
        sv_setiv(SvRV(span), 0);
    }

# Up to $max queued spans as an OTLP payload, or undef when there is nothing
# to send - which is the common case and must not allocate.
SV *
drain(self, max = OTEL_BATCH_MAX)
        SV *self
        int max
    CODE:
    {
        otel_tracer *t = INT2PTR(otel_tracer *, SvIV(SvRV(self)));
        SV *p = otel_tracer_drain(aTHX_ t, max > 0 ? max : OTEL_BATCH_MAX);
        if (!p) XSRETURN_UNDEF;
        RETVAL = p;
    }
    OUTPUT:
        RETVAL

IV
queued(self)
        SV *self
    CODE:
    {
        otel_tracer *t = INT2PTR(otel_tracer *, SvIV(SvRV(self)));
        /* honest across a fork: a child inherited the struct but owns none
         * of those spans, and reporting the parent's count would be a lie
         * a reader would act on */
        otel_tracer_check_fork(aTHX_ t);
        RETVAL = t->qcount;
    }
    OUTPUT:
        RETVAL

# Set one resource attribute after construction. The reason this exists is
# service.instance.id: the resource is normally built at boot, in the parent,
# and a prefork worker MUST NOT export under the same instance id as its
# siblings - a collector seeing several contradictory cumulative series under
# one identity resolves it wrongly and invisibly. A worker refreshes it from
# the post-fork hook.
SV *
resource_attr(self, key, value)
        SV *self
        SV *key
        SV *value
    CODE:
    {
        otel_tracer *t = INT2PTR(otel_tracer *, SvIV(SvRV(self)));
        (void)hv_store_ent(t->resource, key, newSVsv(value), 0);
        RETVAL = newSVsv(self);
    }
    OUTPUT:
        RETVAL

# started, ended, dropped (queue overflow), sampled_out, queued
void
stats(self)
        SV *self
    PPCODE:
    {
        otel_tracer *t = INT2PTR(otel_tracer *, SvIV(SvRV(self)));
        otel_tracer_check_fork(aTHX_ t);
        EXTEND(SP, 10);
        mPUSHp("started", 7);      mPUSHi(t->started);
        mPUSHp("ended", 5);        mPUSHi(t->ended);
        mPUSHp("dropped", 7);      mPUSHi(t->dropped_queue);
        mPUSHp("sampled_out", 11); mPUSHi(t->sampled_out);
        mPUSHp("queued", 6);       mPUSHi(t->qcount);
    }

MODULE = Punk::OpenTelemetry    PACKAGE = Punk::OpenTelemetry::Span

PROTOTYPES: DISABLE

# A span handle. Every method tolerates a span whose tracer has already taken
# it, so a caller that ends twice or annotates after ending gets a no-op
# rather than a crash.

#define OTEL_SPAN_OF(sv) \
    ((SvROK(sv) && SvIOK(SvRV(sv)) && SvIV(SvRV(sv))) \
        ? INT2PTR(otel_span *, SvIV(SvRV(sv))) : NULL)

void
DESTROY(self)
        SV *self
    CODE:
    {
        otel_span *s = OTEL_SPAN_OF(self);
        if (s) otel_span_free(aTHX_ s);
    }

SV *
attr(self, key, value)
        SV *self
        SV *key
        SV *value
    CODE:
    {
        otel_span *s = OTEL_SPAN_OF(self);
        if (s) otel_span_attr(aTHX_ s, key, value);
        RETVAL = newSVsv(self);        /* chainable */
    }
    OUTPUT:
        RETVAL

SV *
event(self, name, attrs = &PL_sv_undef)
        SV *self
        SV *name
        SV *attrs
    CODE:
    {
        otel_span *s = OTEL_SPAN_OF(self);
        HV *a = (SvROK(attrs) && SvTYPE(SvRV(attrs)) == SVt_PVHV)
                ? (HV *)SvRV(attrs) : NULL;
        if (s) otel_span_event(aTHX_ s, name, a);
        RETVAL = newSVsv(self);
    }
    OUTPUT:
        RETVAL

SV *
link(self, trace_id, span_id, attrs = &PL_sv_undef)
        SV *self
        SV *trace_id
        SV *span_id
        SV *attrs
    CODE:
    {
        otel_span *s = OTEL_SPAN_OF(self);
        unsigned char tid[16], sid[8];
        STRLEN tl, sl;
        const char *ts = SvPV_const(trace_id, tl);
        const char *ss = SvPV_const(span_id, sl);
        HV *a = (SvROK(attrs) && SvTYPE(SvRV(attrs)) == SVt_PVHV)
                ? (HV *)SvRV(attrs) : NULL;
        if (s && otel_hex_to_bytes(ts, tl, tid, 16)
              && otel_hex_to_bytes(ss, sl, sid, 8))
            otel_span_link(aTHX_ s, tid, sid, a);
        RETVAL = newSVsv(self);
    }
    OUTPUT:
        RETVAL

# status($code, $message). Only the application may set OK; instrumentation
# sets ERROR or leaves it UNSET, because a layer with no opinion about whether
# an operation succeeded must not claim one.
SV *
status(self, code, message = &PL_sv_undef)
        SV *self
        IV code
        SV *message
    CODE:
    {
        otel_span *s = OTEL_SPAN_OF(self);
        if (s) {
            s->status_code = (int)code;
            if (s->status_message) SvREFCNT_dec(s->status_message);
            s->status_message = SvOK(message) ? newSVsv(message) : NULL;
        }
        RETVAL = newSVsv(self);
    }
    OUTPUT:
        RETVAL

void
end(self)
        SV *self
    CODE:
    {
        otel_span *s = OTEL_SPAN_OF(self);
        if (s) otel_span_end(aTHX_ s);
    }

SV *
trace_id(self)
        SV *self
    CODE:
    {
        otel_span *s = OTEL_SPAN_OF(self);
        char hex[32];
        if (!s) XSRETURN_UNDEF;
        otel_bytes_to_hex(s->trace_id, 16, hex);
        RETVAL = newSVpvn(hex, 32);
    }
    OUTPUT:
        RETVAL

SV *
span_id(self)
        SV *self
    CODE:
    {
        otel_span *s = OTEL_SPAN_OF(self);
        char hex[16];
        if (!s) XSRETURN_UNDEF;
        otel_bytes_to_hex(s->span_id, 8, hex);
        RETVAL = newSVpvn(hex, 16);
    }
    OUTPUT:
        RETVAL

# The span as the payload shape the encoders take, without queueing it.
SV *
to_hash(self)
        SV *self
    CODE:
    {
        otel_span *s = OTEL_SPAN_OF(self);
        if (!s) XSRETURN_UNDEF;
        RETVAL = otel_span_to_hv(aTHX_ s);
    }
    OUTPUT:
        RETVAL

void
counts(self)
        SV *self
    PPCODE:
    {
        otel_span *s = OTEL_SPAN_OF(self);
        if (!s) XSRETURN_EMPTY;
        EXTEND(SP, 6);
        mPUSHi((IV)HvUSEDKEYS(s->attrs)); mPUSHi(s->dropped_attrs);
        mPUSHi(s->n_events);              mPUSHi(s->dropped_events);
        mPUSHi(s->n_links);               mPUSHi(s->dropped_links);
    }
