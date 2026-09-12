# Shared::Arena::Cuckoo - a set that answers "no" exactly, "yes" probably, and
# can forget.

MODULE = Shared::Arena    PACKAGE = Shared::Arena    PREFIX = sar_

# $arena->cuckoo($name, capacity => N)
#
# Sized from how many keys it should hold. There is no rate to ask for: the
# fingerprint width fixes it, and a caller who needs another wants the bloom
# filter.
SV *
sar_cuckoo(self, name, ...)
        SV *self
        SV *name
    PREINIT:
        sa_region *arena;
        sa_reg *e;
        sa_cuckoo *c;
        const char *nm;
        STRLEN nlen;
        UV capacity = 10000;
        uint64_t buckets;
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
            if (strEQ(o, "capacity")) capacity = SvUV(ST(i + 1));
        }
        buckets = sa_cuckoo_buckets((uint64_t)capacity);

        e = sa_carve(arena, nm, (size_t)nlen, sa_cuckoo_bytes(buckets),
                     SA_T_CUCKOO, &err);
        if (!e) croak("Shared::Arena: the filter '%s' %s", nm, sa_strerror(err));

        c = sa_cuckoo_bind(arena, e, buckets, (uint64_t)capacity, &err);
        if (!c) croak("Shared::Arena: the filter '%s' %s", nm, sa_strerror(err));

        obj = newSV(0);
        sv_setref_pv(obj, "Shared::Arena::Cuckoo", (void *)c);
        sv_magicext(SvRV(obj), SvRV(self), PERL_MAGIC_ext, NULL, NULL, 0);
        SvREFCNT_inc(SvRV(self));
        RETVAL = obj;
    OUTPUT:
        RETVAL

MODULE = Shared::Arena    PACKAGE = Shared::Arena::Cuckoo    PREFIX = sack_

# 1 when the key is stored, 0 when there is no room for it. Every call stores a
# copy: a key added twice needs removing twice.
int
sack_add(self, key)
        SV *self
        SV *key
    PREINIT:
        sa_cuckoo *c;
        const char *k;
        STRLEN klen;
    CODE:
        c = SA_SELF(sa_cuckoo, self);
        if (!c) croak("Shared::Arena::Cuckoo: this filter is released");
        k = SvPV(key, klen);
        RETVAL = sa_cuckoo_add(c, k, (uint32_t)klen);
    OUTPUT:
        RETVAL

# A false answer is exact. A true one is probably right.
int
sack_check(self, key)
        SV *self
        SV *key
    PREINIT:
        sa_cuckoo *c;
        const char *k;
        STRLEN klen;
    CODE:
        c = SA_SELF(sa_cuckoo, self);
        if (!c) croak("Shared::Arena::Cuckoo: this filter is released");
        k = SvPV(key, klen);
        RETVAL = sa_cuckoo_check(c, k, (uint32_t)klen);
    OUTPUT:
        RETVAL

# 1 when a copy was found and taken out. Only for keys that were added: a key
# never added can take another key's copy with it.
int
sack_remove(self, key)
        SV *self
        SV *key
    PREINIT:
        sa_cuckoo *c;
        const char *k;
        STRLEN klen;
    CODE:
        c = SA_SELF(sa_cuckoo, self);
        if (!c) croak("Shared::Arena::Cuckoo: this filter is released");
        k = SvPV(key, klen);
        RETVAL = sa_cuckoo_remove(c, k, (uint32_t)klen);
    OUTPUT:
        RETVAL

void
sack_reset(self)
        SV *self
    PREINIT:
        sa_cuckoo *c;
    CODE:
        c = SA_SELF(sa_cuckoo, self);
        if (!c) croak("Shared::Arena::Cuckoo: this filter is released");
        sa_cuckoo_reset(c);

UV
sack_count(self)
        SV *self
    PREINIT:
        sa_cuckoo *c;
    CODE:
        c = SA_SELF(sa_cuckoo, self);
        if (!c) croak("Shared::Arena::Cuckoo: this filter is released");
#if SA_HAVE_ATOMICS
        RETVAL = (UV)sa_at_load64_acq(&c->hdr->count);
#else
        RETVAL = 0;
#endif
    OUTPUT:
        RETVAL

UV
sack_slots(self)
        SV *self
    PREINIT:
        sa_cuckoo *c;
    CODE:
        c = SA_SELF(sa_cuckoo, self);
        if (!c) croak("Shared::Arena::Cuckoo: this filter is released");
        RETVAL = (UV)(c->buckets * SA_CK_LANES);
    OUTPUT:
        RETVAL

# capacity / slots / buckets / bytes / count / load / fp_rate / kicks / moves /
# full / recovered
#
# `load` is the number to watch: the filter refuses adds somewhere past 0.95,
# and `fp_rate` is what the current load makes the chance of a wrong "yes".
void
sack_stats(self)
        SV *self
    PREINIT:
        sa_cuckoo *c;
        uint64_t slots, count;
        double load;
    PPCODE:
        c = SA_SELF(sa_cuckoo, self);
        if (!c) croak("Shared::Arena::Cuckoo: this filter is released");
        slots = c->buckets * SA_CK_LANES;
#if SA_HAVE_ATOMICS
        count = sa_at_load64_acq(&c->hdr->count);
#else
        count = 0;
#endif
        load = slots ? (double)count / (double)slots : 0.0;
        EXTEND(SP, 22);
        mPUSHp("capacity", 8);  mPUSHu((UV)c->hdr->capacity);
        mPUSHp("slots", 5);     mPUSHu((UV)slots);
        mPUSHp("buckets", 7);   mPUSHu((UV)c->buckets);
        mPUSHp("bytes", 5);     mPUSHu((UV)sa_cuckoo_bytes(c->buckets));
        mPUSHp("count", 5);     mPUSHu((UV)count);
        mPUSHp("load", 4);      mPUSHn(load);
        /* Eight fingerprints are compared per check, each matching a random
         * one with probability 1/65535. */
        mPUSHp("fp_rate", 7);   mPUSHn(8.0 * load / 65535.0);
#if SA_HAVE_ATOMICS
        mPUSHp("kicks", 5);     mPUSHu((UV)sa_at_load64_acq(&c->hdr->kicks));
        mPUSHp("moves", 5);     mPUSHu((UV)sa_at_load64_acq(&c->hdr->moves));
        mPUSHp("full", 4);      mPUSHu((UV)sa_at_load64_acq(&c->hdr->full));
        mPUSHp("recovered", 9); mPUSHu((UV)sa_at_load64_acq(&c->hdr->recovered));
#endif

# The pid the relocation lock names, and with an argument, sets it. A test
# hook: it is how t/32-cuckoo.t makes a lock holder that has died, without
# having to kill one at exactly the wrong instant.
UV
sack__owner(self, ...)
        SV *self
    PREINIT:
        sa_cuckoo *c;
    CODE:
        c = SA_SELF(sa_cuckoo, self);
        if (!c) croak("Shared::Arena::Cuckoo: this filter is released");
#if SA_HAVE_ATOMICS
        if (items > 1) sa_at_store64_rel(&c->hdr->owner, (uint64_t)SvUV(ST(1)));
        RETVAL = (UV)sa_at_load64_acq(&c->hdr->owner);
#else
        RETVAL = 0;
#endif
    OUTPUT:
        RETVAL

# Microseconds every check that misses its first bucket sleeps before reading
# its second. A test hook: the window it holds open is otherwise a few
# instructions wide, and a test that races it passes whether or not the filter
# protects it. Shared by every process on the filter, and zero unless set.
UV
sack__stall(self, ...)
        SV *self
    PREINIT:
        sa_cuckoo *c;
    CODE:
        c = SA_SELF(sa_cuckoo, self);
        if (!c) croak("Shared::Arena::Cuckoo: this filter is released");
#if SA_HAVE_ATOMICS
        if (items > 1)
            sa_at_store32_rel(&c->hdr->stall_us, (uint32_t)SvUV(ST(1)));
        RETVAL = (UV)sa_at_load32_acq(&c->hdr->stall_us);
#else
        RETVAL = 0;
#endif
    OUTPUT:
        RETVAL

void
sack_DESTROY(self)
        SV *self
    PREINIT:
        sa_cuckoo *c;
    CODE:
        c = SA_SELF(sa_cuckoo, self);
        if (c) { sa_cuckoo_free(c); sv_setiv(SvRV(self), 0); }
