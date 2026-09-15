# Shared::Arena::HyperLogLog - how many distinct, in a few kilobytes.
#
# The third sketch. Bloom and cuckoo answer "seen it?", count-min answers "how
# often?", this answers "how many DIFFERENT?" - and an add is a lock-free max on
# one register, so eight workers hammering one sketch never conflict.

MODULE = Shared::Arena    PACKAGE = Shared::Arena    PREFIX = sar_

# $arena->hll($name, precision => 14)
#
# `precision` p gives 2^p registers: the sketch costs 2^p bytes and estimates
# within about 1.04 / sqrt(2^p) - 0.8% at the default 14, for 16 kilobytes.
# A later caller names the same precision or inherits it.
SV *
sar_hll(self, name, ...)
        SV *self
        SV *name
    PREINIT:
        sa_region *arena;
        sa_reg *e;
        sa_hll *h;
        const char *nm;
        STRLEN nlen;
        UV p = 0;                     /* 0 = not given: inherit or default   */
        uint64_t want;
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
            if (strEQ(o, "precision")) p = SvUV(ST(i + 1));
        }
        if (p && (p < SA_HLL_MIN_P || p > SA_HLL_MAX_P))
            croak("Shared::Arena: hll precision must be %d to %d, not %lu",
                  (int)SA_HLL_MIN_P, (int)SA_HLL_MAX_P, (unsigned long)p);
        /* Like the scoreboard: a caller naming no precision binds to what is
         * there, and only a fresh sketch gets the default. */
        if (p)                                  want = sa_hll_bytes((uint32_t)p);
        else if (sa_find(arena, nm, (size_t)nlen)) want = 0;
        else                                    want = sa_hll_bytes(14);

        e = sa_carve(arena, nm, (size_t)nlen, want, SA_T_HLL, &err);
        if (!e) croak("Shared::Arena: the hll '%s' %s", nm, sa_strerror(err));
#if SA_HAVE_ATOMICS
        h = sa_hll_bind(arena, e, (uint32_t)p, &err);
        if (!h) croak("Shared::Arena: the hll '%s' %s", nm, sa_strerror(err));
#else
        croak("Shared::Arena: hll needs atomics this build does not have");
#endif
        obj = newSV(0);
        sv_setref_pv(obj, "Shared::Arena::HyperLogLog", (void *)h);
        sv_magicext(SvRV(obj), SvRV(self), PERL_MAGIC_ext, NULL, NULL, 0);
        SvREFCNT_inc(SvRV(self));
        RETVAL = obj;
    OUTPUT:
        RETVAL

MODULE = Shared::Arena    PACKAGE = Shared::Arena::HyperLogLog    PREFIX = sah_

# $hll->add($key) - count a key. Adding it again changes nothing. Lock-free.
# Returns true if the sketch changed, which is a hint and not a membership
# answer: a key can leave the sketch unchanged because another key already
# raised its register.
int
sah_add(self, key)
        SV *self
        SV *key
    PREINIT:
        sa_hll *h;
        const char *k;
        STRLEN kl;
    CODE:
        h = SA_SELF(sa_hll, self);
        if (!h) croak("Shared::Arena::HyperLogLog: this sketch is released");
        k = SvPV(key, kl);
        RETVAL = sa_hll_add(h, k, (size_t)kl);
    OUTPUT:
        RETVAL

# $hll->count - the estimate of how many distinct keys have been added, across
# every process that added to this sketch.
NV
sah_count(self)
        SV *self
    PREINIT:
        sa_hll *h;
    CODE:
        h = SA_SELF(sa_hll, self);
        if (!h) croak("Shared::Arena::HyperLogLog: this sketch is released");
        RETVAL = sa_hll_count(h);
    OUTPUT:
        RETVAL

# $hll->merge($other) - fold another sketch of the same precision into this
# one, so this one then estimates the UNION of what both saw. Lock-free; the
# other is not changed. Croaks on a precision mismatch, which is a bug.
void
sah_merge(self, other)
        SV *self
        SV *other
    PREINIT:
        sa_hll *h, *o;
    CODE:
        h = SA_SELF(sa_hll, self);
        o = SA_SELF(sa_hll, other);
        if (!h || !o) croak("Shared::Arena::HyperLogLog: this sketch is released");
        if (!sa_hll_merge(h, o))
            croak("Shared::Arena::HyperLogLog: cannot merge precision %u into %u",
                  (unsigned)o->p, (unsigned)h->p);

# $hll->reset - forget everything.
void
sah_reset(self)
        SV *self
    PREINIT:
        sa_hll *h;
    CODE:
        h = SA_SELF(sa_hll, self);
        if (!h) croak("Shared::Arena::HyperLogLog: this sketch is released");
        sa_hll_reset(h);

UV
sah_precision(self)
        SV *self
    PREINIT:
        sa_hll *h;
    CODE:
        h = SA_SELF(sa_hll, self);
        if (!h) croak("Shared::Arena::HyperLogLog: this sketch is released");
        RETVAL = (UV)h->p;
    OUTPUT:
        RETVAL

# precision / registers / bytes / filled / error
#
# `filled` is how many registers are non-zero; `error` is the sketch's
# standard relative error, 1.04 / sqrt(registers), the number to quote beside
# any count.
void
sah_stats(self)
        SV *self
    PREINIT:
        sa_hll *h;
    PPCODE:
        h = SA_SELF(sa_hll, self);
        if (!h) croak("Shared::Arena::HyperLogLog: this sketch is released");
        EXTEND(SP, 10);
        mPUSHp("precision", 9); mPUSHu((UV)h->p);
        mPUSHp("registers", 9); mPUSHu((UV)h->m);
        mPUSHp("bytes", 5);     mPUSHu((UV)sa_hll_bytes(h->p));
        mPUSHp("filled", 6);    mPUSHu((UV)sa_hll_filled(h));
        mPUSHp("error", 5);     mPUSHn(1.04 / sqrt((double)h->m));

void
sah_DESTROY(self)
        SV *self
    PREINIT:
        sa_hll *h;
    CODE:
        h = SA_SELF(sa_hll, self);
        if (h) { sa_hll_free(h); sv_setiv(SvRV(self), 0); }
