# Shared::Arena::Histogram - a distribution every process adds to at once.

MODULE = Shared::Arena    PACKAGE = Shared::Arena    PREFIX = sar_

# $arena->histogram($name, max => N, sigbits => 4)
SV *
sar_histogram(self, name, ...)
        SV *self
        SV *name
    PREINIT:
        sa_region *arena;
        sa_reg *e;
        sa_hist *h;
        const char *nm;
        STRLEN nlen;
        UV maxv = 3600000000UL;   /* an hour in microseconds */
        UV sig  = 4;
        int err = SA_E_OK;
        I32 i;
        SV *obj;
    CODE:
        arena = SA_SELF(sa_region, self);
        if (!arena || !arena->map.base)
            croak("Shared::Arena: this region is released");
        nm = SvPV(name, nlen);
        for (i = 2; i + 1 < items; i += 2) {
            const char *o = SvPV_nolen(ST(i));
            if      (strEQ(o, "max"))     maxv = SvUV(ST(i + 1));
            else if (strEQ(o, "sigbits")) sig  = SvUV(ST(i + 1));
        }
        if (!maxv) croak("Shared::Arena: a histogram needs a max above zero");
        if (sig < SA_HIST_MIN_SIG || sig > SA_HIST_MAX_SIG)
            croak("Shared::Arena: sigbits must be between %d and %d",
                  SA_HIST_MIN_SIG, SA_HIST_MAX_SIG);

        e = sa_carve(arena, nm, (size_t)nlen,
                     sa_hist_bytes((uint64_t)maxv, (uint32_t)sig),
                     SA_T_HIST, &err);
        if (!e) croak("Shared::Arena: the histogram '%s' %s", nm,
                      sa_strerror(err));

        h = sa_hist_bind(arena, e, (uint64_t)maxv, (uint32_t)sig, &err);
        if (!h) croak("Shared::Arena: the histogram '%s' %s", nm,
                      sa_strerror(err));

        obj = newSV(0);
        sv_setref_pv(obj, "Shared::Arena::Histogram", (void *)h);
        sv_magicext(SvRV(obj), SvRV(self), PERL_MAGIC_ext, NULL, NULL, 0);
        SvREFCNT_inc(SvRV(self));
        RETVAL = obj;
    OUTPUT:
        RETVAL

MODULE = Shared::Arena    PACKAGE = Shared::Arena::Histogram    PREFIX = sah_

void
sah_record(self, value, ...)
        SV *self
        UV value
    PREINIT:
        sa_hist *h;
        UV n = 1;
    CODE:
        h = SA_SELF(sa_hist, self);
        if (!h) croak("Shared::Arena::Histogram: this histogram is released");
        if (items > 2) n = SvUV(ST(2));
        sa_hist_record(h, (uint64_t)value, (uint64_t)n);

# The value at a quantile, as the TOP of the bucket it falls in - so it never
# claims the service was faster than it was.
UV
sah_quantile(self, q)
        SV *self
        double q
    PREINIT:
        sa_hist *h;
    CODE:
        h = SA_SELF(sa_hist, self);
        if (!h) croak("Shared::Arena::Histogram: this histogram is released");
        RETVAL = (UV)sa_hist_quantile(h, q);
    OUTPUT:
        RETVAL

UV
sah_count(self)
        SV *self
    PREINIT:
        sa_hist *h;
    CODE:
        h = SA_SELF(sa_hist, self);
        if (!h) croak("Shared::Arena::Histogram: this histogram is released");
        RETVAL = (UV)sa_at_load64_acq(&h->hdr->count);
    OUTPUT:
        RETVAL

void
sah_reset(self)
        SV *self
    PREINIT:
        sa_hist *h;
    CODE:
        h = SA_SELF(sa_hist, self);
        if (!h) croak("Shared::Arena::Histogram: this histogram is released");
        sa_hist_reset(h);

# The error bound: the largest fraction by which a recorded value and what this
# reports back can differ. A runtime answer, because it follows from sigbits.
double
sah_error(self)
        SV *self
    PREINIT:
        sa_hist *h;
    CODE:
        h = SA_SELF(sa_hist, self);
        if (!h) croak("Shared::Arena::Histogram: this histogram is released");
        RETVAL = 1.0 / (double)(1ULL << h->sigbits);
    OUTPUT:
        RETVAL

# count / sum / min / max / mean / over / buckets / sigbits
#
# `over` is values above the ceiling. They are counted apart and NOT clamped
# into the top bucket: clamping would let a flood of enormous values look like
# a busy top bucket, and every quantile would read plausibly and be wrong.
void
sah_stats(self)
        SV *self
    PREINIT:
        sa_hist *h;
        uint64_t c, s, mn;
    PPCODE:
        h = SA_SELF(sa_hist, self);
        if (!h) croak("Shared::Arena::Histogram: this histogram is released");
        c  = sa_at_load64_acq(&h->hdr->count);
        s  = sa_at_load64_acq(&h->hdr->sum);
        mn = sa_at_load64_acq(&h->hdr->min);
        EXTEND(SP, 16);
        mPUSHp("count", 5);   mPUSHu((UV)c);
        mPUSHp("sum", 3);     mPUSHu((UV)s);
        mPUSHp("min", 3);     mPUSHu((UV)(c ? mn : 0));
        mPUSHp("max", 3);     mPUSHu((UV)sa_at_load64_acq(&h->hdr->max));
        mPUSHp("mean", 4);    mPUSHn(c ? (double)s / (double)c : 0.0);
        mPUSHp("over", 4);    mPUSHu((UV)sa_at_load64_acq(&h->hdr->over));
        mPUSHp("buckets", 7); mPUSHu((UV)h->nbuckets);
        mPUSHp("sigbits", 7); mPUSHu((UV)h->sigbits);

# The non-empty buckets, as ([low, high, count], ...). For drawing one, or for
# handing to something that wants the shape rather than a number.
void
sah_buckets(self)
        SV *self
    PREINIT:
        sa_hist *h;
        uint64_t i;
    PPCODE:
        h = SA_SELF(sa_hist, self);
        if (!h) croak("Shared::Arena::Histogram: this histogram is released");
        for (i = 0; i < h->nbuckets; i++) {
            uint64_t n = sa_at_load64_acq(&h->buckets[i]);
            AV *av;
            if (!n) continue;
            av = newAV();
            av_push(av, newSVuv((UV)sa_hist_low(i, h->sigbits)));
            av_push(av, newSVuv((UV)sa_hist_high(i, h->sigbits)));
            av_push(av, newSVuv((UV)n));
            mXPUSHs(newRV_noinc((SV *)av));
        }

void
sah_DESTROY(self)
        SV *self
    PREINIT:
        sa_hist *h;
    CODE:
        h = SA_SELF(sa_hist, self);
        if (h) { sa_hist_free(h); sv_setiv(SvRV(self), 0); }
