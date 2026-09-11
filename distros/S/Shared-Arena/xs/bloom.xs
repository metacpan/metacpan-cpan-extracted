# Shared::Arena::Bloom - a set that answers "no" exactly and "yes" probably.

MODULE = Shared::Arena    PACKAGE = Shared::Arena    PREFIX = sar_

# $arena->bloom($name, capacity => N, fp_rate => 0.01)
#
# Sized from what you expect to put in it and the false-positive rate you will
# accept, because those are the numbers a caller actually has. `bits` and
# `hashes` are there for a caller who has already done the arithmetic.
SV *
sar_bloom(self, name, ...)
        SV *self
        SV *name
    PREINIT:
        sa_region *arena;
        sa_reg *e;
        sa_bloom *b;
        const char *nm;
        STRLEN nlen;
        UV capacity = 10000, bits = 0, hashes = 0;
        double fp = 0.01;
        uint64_t nbits = 0;
        uint32_t k = 0;
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
            if      (strEQ(o, "capacity")) capacity = SvUV(ST(i + 1));
            else if (strEQ(o, "fp_rate"))  fp       = SvNV(ST(i + 1));
            else if (strEQ(o, "bits"))     bits     = SvUV(ST(i + 1));
            else if (strEQ(o, "hashes"))   hashes   = SvUV(ST(i + 1));
        }
        if (bits) {
            nbits = sa_bloom_words((uint64_t)bits) * 64u;
            k     = hashes ? (uint32_t)hashes : 5;
            if (k > SA_BLOOM_MAX_K) k = SA_BLOOM_MAX_K;
        }
        else {
            sa_bloom_size((uint64_t)capacity, fp, &nbits, &k);
            if (hashes) {
                k = (uint32_t)hashes;
                if (k > SA_BLOOM_MAX_K) k = SA_BLOOM_MAX_K;
            }
        }

        e = sa_carve(arena, nm, (size_t)nlen, sa_bloom_bytes(nbits),
                     SA_T_BLOOM, &err);
        if (!e) croak("Shared::Arena: the filter '%s' %s", nm, sa_strerror(err));

        b = sa_bloom_bind(arena, e, nbits, k, &err);
        if (!b) croak("Shared::Arena: the filter '%s' %s", nm, sa_strerror(err));
        b->hdr->capacity = (uint64_t)capacity;

        obj = newSV(0);
        sv_setref_pv(obj, "Shared::Arena::Bloom", (void *)b);
        sv_magicext(SvRV(obj), SvRV(self), PERL_MAGIC_ext, NULL, NULL, 0);
        SvREFCNT_inc(SvRV(self));
        RETVAL = obj;
    OUTPUT:
        RETVAL

MODULE = Shared::Arena    PACKAGE = Shared::Arena::Bloom    PREFIX = sab_

# 1 when the key had already been added, 0 when this call added it.
#
# The answer is per BIT and not per key: two processes adding the same key at
# the same instant may both be told it was new. Harmless for a filter; not good
# enough to do a job exactly once.
int
sab_add(self, key)
        SV *self
        SV *key
    PREINIT:
        sa_bloom *b;
        const char *k;
        STRLEN klen;
    CODE:
        b = SA_SELF(sa_bloom, self);
        if (!b) croak("Shared::Arena::Bloom: this filter is released");
        k = SvPV(key, klen);
        RETVAL = sa_bloom_add(b, k, (uint32_t)klen);
    OUTPUT:
        RETVAL

# A false answer is exact. A true one is probably right.
int
sab_check(self, key)
        SV *self
        SV *key
    PREINIT:
        sa_bloom *b;
        const char *k;
        STRLEN klen;
    CODE:
        b = SA_SELF(sa_bloom, self);
        if (!b) croak("Shared::Arena::Bloom: this filter is released");
        k = SvPV(key, klen);
        RETVAL = sa_bloom_check(b, k, (uint32_t)klen);
    OUTPUT:
        RETVAL

void
sab_reset(self)
        SV *self
    PREINIT:
        sa_bloom *b;
    CODE:
        b = SA_SELF(sa_bloom, self);
        if (!b) croak("Shared::Arena::Bloom: this filter is released");
        sa_bloom_reset(b);

UV
sab_bits(self)
        SV *self
    PREINIT:
        sa_bloom *b;
    CODE:
        b = SA_SELF(sa_bloom, self);
        if (!b) croak("Shared::Arena::Bloom: this filter is released");
        RETVAL = (UV)b->nbits;
    OUTPUT:
        RETVAL

UV
sab_hashes(self)
        SV *self
    PREINIT:
        sa_bloom *b;
    CODE:
        b = SA_SELF(sa_bloom, self);
        if (!b) croak("Shared::Arena::Bloom: this filter is released");
        RETVAL = (UV)b->nhash;
    OUTPUT:
        RETVAL

# bits / hashes / set / added / seen / estimated / capacity / fill
#
# `fill` is the fraction of bits set, and it is the number that says whether the
# filter is still delivering the rate it was sized for. Counting the set bits
# walks the whole array, so this belongs on a status page and not in a loop.
void
sab_stats(self)
        SV *self
    PREINIT:
        sa_bloom *b;
        uint64_t set;
    PPCODE:
        b = SA_SELF(sa_bloom, self);
        if (!b) croak("Shared::Arena::Bloom: this filter is released");
        set = sa_bloom_popcount(b);
        EXTEND(SP, 16);
        mPUSHp("bits", 4);      mPUSHu((UV)b->nbits);
        mPUSHp("hashes", 6);    mPUSHu((UV)b->nhash);
        mPUSHp("set", 3);       mPUSHu((UV)set);
        mPUSHp("added", 5);     mPUSHu((UV)sa_at_load64_acq(&b->hdr->added));
        mPUSHp("seen", 4);      mPUSHu((UV)sa_at_load64_acq(&b->hdr->seen));
        mPUSHp("estimated", 9); mPUSHu((UV)sa_bloom_estimate(b));
        mPUSHp("capacity", 8);  mPUSHu((UV)b->hdr->capacity);
        mPUSHp("fill", 4);
        mPUSHn(b->nbits ? (double)set / (double)b->nbits : 0.0);

void
sab_DESTROY(self)
        SV *self
    PREINIT:
        sa_bloom *b;
    CODE:
        b = SA_SELF(sa_bloom, self);
        if (b) { sa_bloom_free(b); sv_setiv(SvRV(self), 0); }
