# Shared::Arena::Map - a fixed-capacity map several processes share.

MODULE = Shared::Arena    PACKAGE = Shared::Arena    PREFIX = sar_

# $arena->map($name, slots => N, slot_size => N) -> Shared::Arena::Map
#
# Carves the region if it is not there, binds to it if it is. Every process may
# call this with the same arguments; exactly one of them does the work.
SV *
sar_map(self, name, ...)
        SV *self
        SV *name
    PREINIT:
        sa_region *arena;
        sa_reg *e;
        sa_hash *m;
        const char *nm;
        STRLEN nlen;
        UV slots = 1024, slot_size = 256;
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
            if      (strEQ(o, "slots"))     slots     = SvUV(ST(i + 1));
            else if (strEQ(o, "slot_size")) slot_size = SvUV(ST(i + 1));
        }
        if (slots < 2) slots = 2;
        if (sa_hash_capacity((uint32_t)slot_size) == 0)
            croak("Shared::Arena: slot_size %lu is smaller than a slot header",
                  (unsigned long)slot_size);

        e = sa_carve(arena, nm, (size_t)nlen,
                     sa_hash_bytes((uint64_t)slots, (uint32_t)slot_size),
                     SA_T_MAP, &err);
        if (!e) croak("Shared::Arena: the map '%s' %s", nm, sa_strerror(err));

        m = sa_hash_bind(arena, e, (uint64_t)slots, (uint32_t)slot_size, &err);
        if (!m) croak("Shared::Arena: the map '%s' %s", nm, sa_strerror(err));

        obj = newSV(0);
        sv_setref_pv(obj, "Shared::Arena::Map", (void *)m);
        /* The map borrows the arena's mapping, so the arena must outlive it. */
        sv_magicext(SvRV(obj), SvRV(self), PERL_MAGIC_ext, NULL, NULL, 0);
        SvREFCNT_inc(SvRV(self));
        RETVAL = obj;
    OUTPUT:
        RETVAL

MODULE = Shared::Arena    PACKAGE = Shared::Arena::Map    PREFIX = sam_

# 1 stored / 0 the table is full / -1 the pair does not fit a slot.
IV
sam_store(self, key, value)
        SV *self
        SV *key
        SV *value
    PREINIT:
        sa_hash *m;
        const char *k, *v;
        STRLEN klen, vlen;
    CODE:
        m = SA_SELF(sa_hash, self);
        if (!m) croak("Shared::Arena::Map: this map is released");
        k = SvPV(key, klen);
        v = SvPV(value, vlen);
        RETVAL = sa_hash_store(m, k, (uint32_t)klen, v, (uint32_t)vlen);
    OUTPUT:
        RETVAL

# The value, or an EMPTY LIST when the key is not there.
#
# Not undef for absent: undef is a value a caller may legitimately store, and a
# door that used it to mean absent could not tell the two apart.
#
# A key that is there but could not be read - because a writer held it through
# more retries than a reader was willing to spend - is also an empty list, and
# the map's `busy` count is what says so. See the POD: a non-zero busy means a
# fetch gave up, not that a key was missing.
void
sam_fetch(self, key)
        SV *self
        SV *key
    PREINIT:
        sa_hash *m;
        const char *k;
        STRLEN klen;
        SV *out;
        uint32_t vlen = 0;
        int rc;
    PPCODE:
        m = SA_SELF(sa_hash, self);
        if (!m) croak("Shared::Arena::Map: this map is released");
        k = SvPV(key, klen);
        out = sv_2mortal(newSV((STRLEN)m->pair_max + 1));
        SvPOK_on(out);
        rc = sa_hash_fetch(m, k, (uint32_t)klen, SvPVX(out),
                           (uint32_t)m->pair_max, &vlen);
        if (rc != SA_H_HIT) XSRETURN_EMPTY;
        SvCUR_set(out, (STRLEN)vlen);
        SvPVX(out)[vlen] = '\0';
        XPUSHs(out);

int
sam_exists(self, key)
        SV *self
        SV *key
    PREINIT:
        sa_hash *m;
        const char *k;
        STRLEN klen;
        char scratch[8];
        uint32_t vlen = 0;
    CODE:
        m = SA_SELF(sa_hash, self);
        if (!m) croak("Shared::Arena::Map: this map is released");
        k = SvPV(key, klen);
        /* A zero-length buffer: a hit with a value too long to copy still
         * answers the question this asks, which is only whether it is there. */
        RETVAL = (sa_hash_fetch(m, k, (uint32_t)klen, scratch, 0, &vlen)
                  != SA_H_MISS) ? 1 : 0;
    OUTPUT:
        RETVAL

int
sam_delete(self, key)
        SV *self
        SV *key
    PREINIT:
        sa_hash *m;
        const char *k;
        STRLEN klen;
    CODE:
        m = SA_SELF(sa_hash, self);
        if (!m) croak("Shared::Arena::Map: this map is released");
        k = SvPV(key, klen);
        RETVAL = sa_hash_delete(m, k, (uint32_t)klen);
    OUTPUT:
        RETVAL

# Add to a counter, creating it at $by when it is absent. Returns the new
# value, or undef when the table is full or the entry is not a counter.
SV *
sam_incr(self, key, ...)
        SV *self
        SV *key
    PREINIT:
        sa_hash *m;
        const char *k;
        STRLEN klen;
        IV by = 1;
        uint64_t now = 0;
        int rc;
    CODE:
        m = SA_SELF(sa_hash, self);
        if (!m) croak("Shared::Arena::Map: this map is released");
        k = SvPV(key, klen);
        if (items > 2) by = SvIV(ST(2));
        rc = sa_hash_incr(m, k, (uint32_t)klen, (int64_t)by, &now);
        if (rc != SA_H_OK) XSRETURN_UNDEF;
        RETVAL = newSVuv((UV)now);
    OUTPUT:
        RETVAL

# A counter's value without changing it, or undef when it is not a counter.
SV *
sam_counter(self, key)
        SV *self
        SV *key
    PREINIT:
        sa_hash *m;
        const char *k;
        STRLEN klen;
        char buf[8];
        uint32_t vlen = 0;
        uint64_t v;
    CODE:
        m = SA_SELF(sa_hash, self);
        if (!m) croak("Shared::Arena::Map: this map is released");
        k = SvPV(key, klen);
        if (sa_hash_fetch(m, k, (uint32_t)klen, buf, 8, &vlen) != SA_H_HIT
            || vlen != 8)
            XSRETURN_UNDEF;
        memcpy(&v, buf, 8);
        RETVAL = newSVuv((UV)v);
    OUTPUT:
        RETVAL

UV
sam_max_pair(self)
        SV *self
    PREINIT:
        sa_hash *m;
    CODE:
        m = SA_SELF(sa_hash, self);
        if (!m) croak("Shared::Arena::Map: this map is released");
        RETVAL = (UV)m->pair_max;
    OUTPUT:
        RETVAL

UV
sam_capacity(self)
        SV *self
    PREINIT:
        sa_hash *m;
    CODE:
        m = SA_SELF(sa_hash, self);
        if (!m) croak("Shared::Arena::Map: this map is released");
        RETVAL = (UV)m->nslots;
    OUTPUT:
        RETVAL

# The keys, in the table's own order, which is neither insertion nor sorted.
#
# A SNAPSHOT AND NOT A LOCK: entries may be added or removed while this walks,
# so a key it returns may be gone by the time the caller looks at it, and one
# added behind the walk will not appear. It is for an operator looking at a
# table, not for iterating one that is being written.
void
sam_keys(self)
        SV *self
    PREINIT:
        sa_hash *m;
        uint64_t i;
    PPCODE:
        m = SA_SELF(sa_hash, self);
        if (!m) croak("Shared::Arena::Map: this map is released");
        for (i = 0; i < m->nslots; i++) {
            sa_hash_slot *s = SA_HSLOT_AT(m, i);
            uint32_t v1, kl;
            if (sa_at_load32_acq(&s->state) != SA_H_LIVE) continue;
            v1 = sa_at_load32_acq(&s->version);
            if (v1 & 1u) continue;              /* mid-update: skip it */
            kl = sa_at_load32_acq(&s->klen);
            if (!kl || (uint64_t)kl > m->pair_max) continue;
            {
                SV *k = newSVpvn(s->bytes, kl);
                sa_at_fence_acq();
                if (sa_at_load32_acq(&s->version) != v1) {
                    SvREFCNT_dec(k);
                    continue;
                }
                mXPUSHs(k);
            }
        }

# used / capacity / tombstones / busy / full
void
sam_stats(self)
        SV *self
    PREINIT:
        sa_hash *m;
    PPCODE:
        m = SA_SELF(sa_hash, self);
        if (!m) croak("Shared::Arena::Map: this map is released");
        EXTEND(SP, 10);
        mPUSHp("used", 4);       mPUSHu((UV)sa_at_load64_acq(&m->hdr->used));
        mPUSHp("capacity", 8);   mPUSHu((UV)m->nslots);
        mPUSHp("tombstones", 10);
        mPUSHu((UV)sa_at_load64_acq(&m->hdr->tombstones));
        mPUSHp("busy", 4);       mPUSHu((UV)sa_at_load64_acq(&m->hdr->busy));
        mPUSHp("full", 4);       mPUSHu((UV)sa_at_load64_acq(&m->hdr->full));

void
sam_DESTROY(self)
        SV *self
    PREINIT:
        sa_hash *m;
    CODE:
        m = SA_SELF(sa_hash, self);
        if (m) { sa_hash_free(m); sv_setiv(SvRV(self), 0); }
