# Shared::Arena::Cache - a map that evicts instead of refusing.

MODULE = Shared::Arena    PACKAGE = Shared::Arena    PREFIX = sar_

# $arena->cache($name, capacity => N, ways => 8, entry_size => N)
SV *
sar_cache(self, name, ...)
        SV *self
        SV *name
    PREINIT:
        sa_region *arena;
        sa_reg *e;
        sa_cache *c;
        const char *nm;
        STRLEN nlen;
        UV capacity = 1024, ways = 8, entry = 512;
        uint64_t nbuckets;
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
            if      (strEQ(o, "capacity"))   capacity = SvUV(ST(i + 1));
            else if (strEQ(o, "ways"))       ways     = SvUV(ST(i + 1));
            else if (strEQ(o, "entry_size")) entry    = SvUV(ST(i + 1));
        }
        if (ways < SA_CACHE_MIN_WAYS) ways = SA_CACHE_MIN_WAYS;
        if (ways > SA_CACHE_MAX_WAYS) ways = SA_CACHE_MAX_WAYS;
        if (capacity < ways) capacity = ways;
        if (sa_cache_capacity((uint32_t)entry) == 0)
            croak("Shared::Arena: entry_size %lu is smaller than an entry header",
                  (unsigned long)entry);
        nbuckets = ((uint64_t)capacity + ways - 1) / ways;

        e = sa_carve(arena, nm, (size_t)nlen,
                     sa_cache_bytes(nbuckets, (uint32_t)ways, (uint32_t)entry),
                     SA_T_CACHE, &err);
        if (!e) croak("Shared::Arena: the cache '%s' %s", nm, sa_strerror(err));

        c = sa_cache_bind(arena, e, nbuckets, (uint32_t)ways, (uint32_t)entry,
                          &err);
        if (!c) croak("Shared::Arena: the cache '%s' %s", nm, sa_strerror(err));

        obj = newSV(0);
        sv_setref_pv(obj, "Shared::Arena::Cache", (void *)c);
        sv_magicext(SvRV(obj), SvRV(self), PERL_MAGIC_ext, NULL, NULL, 0);
        SvREFCNT_inc(SvRV(self));
        RETVAL = obj;
    OUTPUT:
        RETVAL

MODULE = Shared::Arena    PACKAGE = Shared::Arena::Cache    PREFIX = sac_

# 1 when stored, -1 when the pair does not fit an entry. There is no "full":
# that is the whole difference between this and a map.
IV
sac_set(self, key, value, ...)
        SV *self
        SV *key
        SV *value
    PREINIT:
        sa_cache *c;
        const char *k, *v;
        STRLEN klen, vlen;
        UV ttl = 0;
        I32 i;
    CODE:
        c = SA_SELF(sa_cache, self);
        if (!c) croak("Shared::Arena::Cache: this cache is released");
        k = SvPV(key, klen);
        v = SvPV(value, vlen);
        for (i = 3; i + 1 < items; i += 2) {
            const char *o = SvPV_nolen(ST(i));
            /* seconds, because that is what a caller thinks in; milliseconds
             * for anybody who needs them. */
            if      (strEQ(o, "ttl"))    ttl = (UV)(SvNV(ST(i + 1)) * 1000.0);
            else if (strEQ(o, "ttl_ms")) ttl = SvUV(ST(i + 1));
        }
        RETVAL = sa_cache_set(c, k, (uint32_t)klen, v, (uint32_t)vlen,
                              (uint64_t)ttl);
    OUTPUT:
        RETVAL

# The value, or an EMPTY LIST for a miss - which includes an entry whose
# deadline has passed, because a cache that returns stale data is not a cache.
void
sac_get(self, key)
        SV *self
        SV *key
    PREINIT:
        sa_cache *c;
        const char *k;
        STRLEN klen;
        SV *out;
        char buf[1024];
        uint32_t vlen = 0;
        int rc;
    PPCODE:
        c = SA_SELF(sa_cache, self);
        if (!c) croak("Shared::Arena::Cache: this cache is released");
        k = SvPV(key, klen);
        /* Onto the stack first where an entry fits, so a miss allocates
         * nothing and a hit allocates what the value needs rather than the
         * most an entry could hold, which a caller keeping the value would
         * otherwise carry for its life. */
        if (c->pair_max < sizeof buf) {
            rc = sa_cache_get(c, k, (uint32_t)klen, buf,
                              (uint32_t)c->pair_max, &vlen);
            if (rc != SA_C_HIT) XSRETURN_EMPTY;
            XPUSHs(sv_2mortal(newSVpvn(buf, (STRLEN)vlen)));
        }
        else {
            out = sv_2mortal(newSV((STRLEN)c->pair_max + 1));
            SvPOK_on(out);
            rc = sa_cache_get(c, k, (uint32_t)klen, SvPVX(out),
                              (uint32_t)c->pair_max, &vlen);
            if (rc != SA_C_HIT) XSRETURN_EMPTY;
            SvCUR_set(out, (STRLEN)vlen);
            SvPVX(out)[vlen] = '\0';
            XPUSHs(out);
        }

int
sac_remove(self, key)
        SV *self
        SV *key
    PREINIT:
        sa_cache *c;
        const char *k;
        STRLEN klen;
    CODE:
        c = SA_SELF(sa_cache, self);
        if (!c) croak("Shared::Arena::Cache: this cache is released");
        k = SvPV(key, klen);
        RETVAL = sa_cache_remove(c, k, (uint32_t)klen);
    OUTPUT:
        RETVAL

void
sac_clear(self)
        SV *self
    PREINIT:
        sa_cache *c;
    CODE:
        c = SA_SELF(sa_cache, self);
        if (!c) croak("Shared::Arena::Cache: this cache is released");
        sa_cache_clear(c);

UV
sac_capacity(self)
        SV *self
    PREINIT:
        sa_cache *c;
    CODE:
        c = SA_SELF(sa_cache, self);
        if (!c) croak("Shared::Arena::Cache: this cache is released");
        RETVAL = (UV)(c->nbuckets * c->nways);
    OUTPUT:
        RETVAL

UV
sac_max_pair(self)
        SV *self
    PREINIT:
        sa_cache *c;
    CODE:
        c = SA_SELF(sa_cache, self);
        if (!c) croak("Shared::Arena::Cache: this cache is released");
        RETVAL = (UV)c->pair_max;
    OUTPUT:
        RETVAL

# hits / misses / hit_rate / evictions / expired / live / capacity / ways
#
# The hit rate is the number a cache exists to produce. `live` walks every
# entry, so this belongs on a status page rather than in a request.
void
sac_stats(self)
        SV *self
    PREINIT:
        sa_cache *c;
        uint64_t h, m;
    PPCODE:
        c = SA_SELF(sa_cache, self);
        if (!c) croak("Shared::Arena::Cache: this cache is released");
        sa_cache_flush(c);        /* this process's own counts, exactly */
        h = sa_at_load64_acq(&c->hdr->hits);
        m = sa_at_load64_acq(&c->hdr->misses);
        EXTEND(SP, 16);
        mPUSHp("hits", 4);      mPUSHu((UV)h);
        mPUSHp("misses", 6);    mPUSHu((UV)m);
        mPUSHp("hit_rate", 8);  mPUSHn((h + m) ? (double)h / (double)(h + m) : 0.0);
        mPUSHp("evictions", 9); mPUSHu((UV)sa_at_load64_acq(&c->hdr->evictions));
        mPUSHp("expired", 7);   mPUSHu((UV)sa_at_load64_acq(&c->hdr->expired));
        mPUSHp("live", 4);      mPUSHu((UV)sa_cache_live(c));
        mPUSHp("capacity", 8);  mPUSHu((UV)(c->nbuckets * c->nways));
        mPUSHp("ways", 4);      mPUSHu((UV)c->nways);

void
sac_DESTROY(self)
        SV *self
    PREINIT:
        sa_cache *c;
    CODE:
        c = SA_SELF(sa_cache, self);
        if (c) { sa_cache_free(c); sv_setiv(SvRV(self), 0); }
