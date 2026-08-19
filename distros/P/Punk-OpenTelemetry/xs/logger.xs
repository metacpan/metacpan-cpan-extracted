MODULE = Punk::OpenTelemetry    PACKAGE = Punk::OpenTelemetry::Logs

PROTOTYPES: DISABLE

# The logs signal. Records are a COPY: the application's logs still go
# wherever they were going, and the collector gets a duplicate. A telemetry
# layer that silently redirects an operator's logs is a bad neighbour, and the
# failure mode when the collector is down would be that the logs vanish.

SV *
new(class, ...)
        SV *class
    CODE:
    {
        otel_logger *lg = otel_logger_new(aTHX);
        int i;
        for (i = 1; i + 1 < items; i += 2) {
            const char *k = SvPV_nolen(ST(i));
            SV *v = ST(i + 1);
            if      (strEQ(k, "scope_name"))    lg->scope_name    = newSVsv(v);
            else if (strEQ(k, "scope_version")) lg->scope_version = newSVsv(v);
            else if (strEQ(k, "resource")
                     && SvROK(v) && SvTYPE(SvRV(v)) == SVt_PVHV) {
                HV *src = (HV *)SvRV(v);
                HE *he;
                hv_iterinit(src);
                while ((he = hv_iternext(src)))
                    (void)hv_store_ent(lg->resource, hv_iterkeysv(he),
                                       newSVsv(HeVAL(he)), 0);
            }
        }
        RETVAL = sv_bless(newRV_noinc(newSViv(PTR2IV(lg))),
                          gv_stashpv("Punk::OpenTelemetry::Logs", GV_ADD));
    }
    OUTPUT:
        RETVAL

void
DESTROY(self)
        SV *self
    CODE:
        if (SvROK(self) && SvIOK(SvRV(self)))
            otel_logger_free(aTHX_ INT2PTR(otel_logger *, SvIV(SvRV(self))));

# emit($level, $body, \%attributes, $span)
#
# $span is what correlates the line with a trace, and is the highest-value,
# lowest-cost part of this whole signal: it is what makes somebody actually
# click from a log line into a trace.
void
emit(self, level, body, attrs = &PL_sv_undef, span = &PL_sv_undef)
        SV *self
        SV *level
        SV *body
        SV *attrs
        SV *span
    CODE:
    {
        otel_logger *lg = INT2PTR(otel_logger *, SvIV(SvRV(self)));
        HV *a = (SvROK(attrs) && SvTYPE(SvRV(attrs)) == SVt_PVHV)
                ? (HV *)SvRV(attrs) : NULL;
        otel_span *sp = (SvROK(span) && SvIOK(SvRV(span)) && SvIV(SvRV(span)))
                ? INT2PTR(otel_span *, SvIV(SvRV(span))) : NULL;
        /* the SDK's own diagnostics must never come back round through here */
        if (OTEL_INSTR.suppress) XSRETURN_EMPTY;
        otel_logger_emit(aTHX_ lg, level, body, a, sp);
    }

SV *
drain(self, max = 512)
        SV *self
        int max
    CODE:
    {
        otel_logger *lg = INT2PTR(otel_logger *, SvIV(SvRV(self)));
        SV *p = otel_logger_drain(aTHX_ lg, max > 0 ? max : 512);
        if (!p) XSRETURN_UNDEF;
        RETVAL = p;
    }
    OUTPUT:
        RETVAL

# The OTLP severity number for a Punk level. The bands are four wide and this
# picks the FIRST of each, which is what every other SDK emits and what a
# threshold written as ">= 13" compares against.
IV
severity(level)
        SV *level
    CODE:
        RETVAL = otel_sev_of(aTHX_ level);
    OUTPUT:
        RETVAL

void
stats(self)
        SV *self
    PPCODE:
    {
        otel_logger *lg = INT2PTR(otel_logger *, SvIV(SvRV(self)));
        otel_logger_check_fork(aTHX_ lg);
        EXTEND(SP, 6);
        mPUSHp("emitted", 7); mPUSHi(lg->emitted);
        mPUSHp("dropped", 7); mPUSHi(lg->dropped);
        mPUSHp("queued", 6);  mPUSHi(lg->qcount);
    }

MODULE = Punk::OpenTelemetry    PACKAGE = Punk::OpenTelemetry::Encode

PROTOTYPES: DISABLE

# The other two signals on the wire. Same two-pass encoder as the traces one.

SV *
metrics_protobuf(payload)
        SV *payload
    CODE:
    {
        if (!(payload && SvROK(payload) && SvTYPE(SvRV(payload)) == SVt_PVHV))
            croak("Punk::OpenTelemetry::Encode::metrics_protobuf: "
                  "expected a hashref payload");
        RETVAL = otel_encode_metrics(aTHX_ (HV *)SvRV(payload));
    }
    OUTPUT:
        RETVAL

SV *
logs_protobuf(payload)
        SV *payload
    CODE:
    {
        if (!(payload && SvROK(payload) && SvTYPE(SvRV(payload)) == SVt_PVHV))
            croak("Punk::OpenTelemetry::Encode::logs_protobuf: "
                  "expected a hashref payload");
        RETVAL = otel_encode_logs(aTHX_ (HV *)SvRV(payload));
    }
    OUTPUT:
        RETVAL
