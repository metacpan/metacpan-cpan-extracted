MODULE = Punk::OpenTelemetry    PACKAGE = Punk::OpenTelemetry::Meter

PROTOTYPES: DISABLE

SV *
new(class, ...)
        SV *class
    CODE:
    {
        otel_meter *m = otel_meter_new(aTHX);
        int i;
        for (i = 1; i + 1 < items; i += 2) {
            const char *k = SvPV_nolen(ST(i));
            SV *v = ST(i + 1);
            if      (strEQ(k, "scope_name"))    m->scope_name    = newSVsv(v);
            else if (strEQ(k, "scope_version")) m->scope_version = newSVsv(v);
            else if (strEQ(k, "temporality"))
                m->temporality = strEQ(SvPV_nolen(v), "delta")
                               ? OTEL_TEMP_DELTA : OTEL_TEMP_CUMULATIVE;
            else if (strEQ(k, "resource")
                     && SvROK(v) && SvTYPE(SvRV(v)) == SVt_PVHV) {
                HV *src = (HV *)SvRV(v);
                HE *he;
                hv_iterinit(src);
                while ((he = hv_iternext(src)))
                    (void)hv_store_ent(m->resource, hv_iterkeysv(he),
                                       newSVsv(HeVAL(he)), 0);
            }
        }
        RETVAL = sv_bless(newRV_noinc(newSViv(PTR2IV(m))),
                          gv_stashpv("Punk::OpenTelemetry::Meter", GV_ADD));
    }
    OUTPUT:
        RETVAL

void
DESTROY(self)
        SV *self
    CODE:
        if (SvROK(self) && SvIOK(SvRV(self)))
            otel_meter_free(aTHX_ INT2PTR(otel_meter *, SvIV(SvRV(self))));

# view(match => 'http.*', name => ..., aggregation => 'drop'|'sum'|
#      'last_value'|'histogram'|'exponential', keys => [...], bounds => [...])
#
# Dropping attribute KEYS is the primary tool against cardinality, and is
# worth reaching for before the hard cap has to do its job.
IV
view(self, ...)
        SV *self
    CODE:
    {
        otel_meter *m = INT2PTR(otel_meter *, SvIV(SvRV(self)));
        otel_view *v;
        int i;
        if (m->nviews >= OTEL_MAX_VIEWS) XSRETURN_IV(0);
        v = &m->views[m->nviews];
        Zero(v, 1, otel_view);
        v->aggregation = -1;
        for (i = 1; i + 1 < items; i += 2) {
            const char *k = SvPV_nolen(ST(i));
            SV *val = ST(i + 1);
            if      (strEQ(k, "match")) v->match = newSVsv(val);
            else if (strEQ(k, "name"))  v->name  = newSVsv(val);
            else if (strEQ(k, "aggregation")) {
                const char *a = SvPV_nolen(val);
                v->aggregation = strEQ(a, "drop")        ? OTEL_AGG_DROP
                               : strEQ(a, "sum")         ? OTEL_AGG_SUM
                               : strEQ(a, "last_value")  ? OTEL_AGG_LASTVALUE
                               : strEQ(a, "exponential") ? OTEL_AGG_EXPO
                               : OTEL_AGG_HISTOGRAM;
            }
            else if (strEQ(k, "keys")
                     && SvROK(val) && SvTYPE(SvRV(val)) == SVt_PVAV) {
                AV *av = (AV *)SvRV(val);
                SSize_t j, n = av_len(av) + 1;
                v->keys = newHV();
                v->has_keys = 1;
                for (j = 0; j < n; j++) {
                    SV **e = av_fetch(av, j, 0);
                    if (e && *e) (void)hv_store_ent(v->keys, *e, newSViv(1), 0);
                }
            }
            else if (strEQ(k, "bounds")
                     && SvROK(val) && SvTYPE(SvRV(val)) == SVt_PVAV) {
                AV *av = (AV *)SvRV(val);
                SSize_t j, n = av_len(av) + 1;
                if (n > OTEL_MAX_BOUNDS) n = OTEL_MAX_BOUNDS;
                for (j = 0; j < n; j++) {
                    SV **e = av_fetch(av, j, 0);
                    v->bounds[j] = (e && *e) ? SvNV(*e) : 0;
                }
                v->nbounds = (int)n;
            }
        }
        if (!v->match) v->match = newSVpvs("*");
        m->nviews++;
        RETVAL = 1;
    }
    OUTPUT:
        RETVAL

# record($name, $kind, $value, \%attributes, $span)
#
# $kind: 1 counter, 2 updowncounter, 3 histogram, 4 gauge.
# $span is optional and is what makes an exemplar possible: the default
# filter is trace_based, so with no sampled span there is no exemplar, an
# exemplar pointing at a trace nobody recorded being a pointer to nothing.
void
record(self, name, kind, value, attrs = &PL_sv_undef, span = &PL_sv_undef)
        SV *self
        SV *name
        IV kind
        double value
        SV *attrs
        SV *span
    CODE:
    {
        otel_meter *m = INT2PTR(otel_meter *, SvIV(SvRV(self)));
        otel_instrument *in;
        HV *a = (SvROK(attrs) && SvTYPE(SvRV(attrs)) == SVt_PVHV)
                ? (HV *)SvRV(attrs) : NULL;
        otel_span *sp = (SvROK(span) && SvIOK(SvRV(span)) && SvIV(SvRV(span)))
                ? INT2PTR(otel_span *, SvIV(SvRV(span))) : NULL;
        otel_meter_check_fork(aTHX_ m);
        in = otel_meter_instrument(aTHX_ m, name, (int)kind, NULL, NULL);
        a = otel_view_filter(aTHX_ m, name, a);
        otel_instr_record(aTHX_ in, value, a, sp);
    }

# Collect everything as an OTLP metrics payload, or undef when nothing has
# been recorded. Under DELTA the accumulators reset and the next interval
# starts now; under CUMULATIVE they do not, and each series keeps its original
# start timestamp - which is the whole distinction and what a backend notices
# when it is wrong.
SV *
collect(self)
        SV *self
    CODE:
    {
        otel_meter *m = INT2PTR(otel_meter *, SvIV(SvRV(self)));
        otel_meter_check_fork(aTHX_ m);
        RETVAL = otel_meter_collect(aTHX_ m);
        if (!RETVAL) XSRETURN_UNDEF;
    }
    OUTPUT:
        RETVAL

# conflicts: streams that ended up with the same name but a different unit,
# kind or aggregation. A backend resolves that silently, by storing whichever
# arrived last, so it is counted here and reported rather than ignored.
IV
conflicts(self)
        SV *self
    CODE:
    {
        otel_meter *m = INT2PTR(otel_meter *, SvIV(SvRV(self)));
        RETVAL = m->conflicts;
    }
    OUTPUT:
        RETVAL

# (instruments, series, overflow) - overflow being attribute sets past the
# cardinality cap, which is the number that says a metric has stopped being
# useful before memory says it more loudly.
void
stats(self)
        SV *self
    PPCODE:
    {
        otel_meter *m = INT2PTR(otel_meter *, SvIV(SvRV(self)));
        otel_instrument *in;
        IV ni = 0, ns = 0, ov = 0;
        for (in = m->instruments; in; in = in->next) {
            ni++;
            ns += in->npoints;
            ov += in->overflow;
        }
        EXTEND(SP, 6);
        mPUSHp("instruments", 11); mPUSHi(ni);
        mPUSHp("series", 6);       mPUSHi(ns);
        mPUSHp("overflow", 8);     mPUSHi(ov);
    }

MODULE = Punk::OpenTelemetry    PACKAGE = Punk::OpenTelemetry::Expo

PROTOTYPES: DISABLE

# The exponential histogram, reachable directly. It is the one piece of
# numeric code here where being slightly wrong produces a plausible number
# rather than an obvious failure, so the tests drive it as property tests
# rather than through a metric that happens to look right.

SV *
new(class, scale = 20)
        SV *class
        int scale
    CODE:
    {
        otel_expo *h;
        Newxz(h, 1, otel_expo);
        otel_expo_init(h, scale);
        RETVAL = sv_bless(newRV_noinc(newSViv(PTR2IV(h))),
                          gv_stashpv("Punk::OpenTelemetry::Expo", GV_ADD));
    }
    OUTPUT:
        RETVAL

void
DESTROY(self)
        SV *self
    CODE:
        if (SvROK(self) && SvIOK(SvRV(self)))
            Safefree(INT2PTR(otel_expo *, SvIV(SvRV(self))));

void
record(self, v)
        SV *self
        double v
    CODE:
        otel_expo_record(INT2PTR(otel_expo *, SvIV(SvRV(self))), v);

void
downscale(self, by)
        SV *self
        int by
    CODE:
        otel_expo_downscale(INT2PTR(otel_expo *, SvIV(SvRV(self))), by);

void
merge(self, other)
        SV *self
        SV *other
    CODE:
        otel_expo_merge(INT2PTR(otel_expo *, SvIV(SvRV(self))),
                        INT2PTR(otel_expo *, SvIV(SvRV(other))));

# (count, sum, scale, zero_count, total, pos_len, neg_len, pos_offset)
#
# `total` is every bucket plus the zeros: the invariant a downscale or a merge
# must never change. A downscale that loses a count is a silently wrong
# percentile, which is the worst thing a histogram can be - it still looks
# like data.
void
state(self)
        SV *self
    PPCODE:
    {
        otel_expo *h = INT2PTR(otel_expo *, SvIV(SvRV(self)));
        EXTEND(SP, 16);
        mPUSHp("count", 5);      mPUSHi(h->count);
        mPUSHp("sum", 3);        mPUSHn(h->sum);
        mPUSHp("scale", 5);      mPUSHi(h->scale);
        mPUSHp("zero_count", 10);mPUSHi(h->zero_count);
        mPUSHp("total", 5);      mPUSHi(otel_expo_total(h));
        mPUSHp("pos_len", 7);    mPUSHi(h->pos.len);
        mPUSHp("neg_len", 7);    mPUSHi(h->neg.len);
        mPUSHp("pos_offset", 10);mPUSHi(h->pos.offset);
    }
