MODULE = Punk        PACKAGE = Punk::Cache::Memory

PROTOTYPES: DISABLE

# The in-memory cache store: the five contract methods over punk_cache.h.
#
# Bounded by BYTES, not entries. An entry cap does not bound the thing that
# runs out - a thousand entries of ten megabytes is ten gigabytes - and the
# whole reason this store exists is to have a bound that means something.

SV *
new(class, ...)
        SV *class
    CODE:
    {
        UV max_bytes = 64 * 1024 * 1024;      /* the documented default */
        punk_cache *c;
        int i;
        const char *cls = (SvROK(class) && SvOBJECT(SvRV(class)))
                        ? HvNAME(SvSTASH(SvRV(class))) : SvPV_nolen(class);
        for (i = 1; i + 1 < items; i += 2) {
            const char *k = SvPV_nolen(ST(i));
            if (strEQ(k, "max_bytes")) max_bytes = SvUV(ST(i + 1));
        }
        if (!max_bytes)
            croak("Punk::Cache::Memory: max_bytes must be greater than zero");
        c = punk_cache_new(aTHX_ (size_t)max_bytes);
        RETVAL = sv_bless(newRV_noinc(newSViv(PTR2IV(c))),
                          gv_stashpv(cls, GV_ADD));
    }
    OUTPUT:
        RETVAL

void
DESTROY(self)
        SV *self
    CODE:
        if (SvROK(self) && SvIOK(SvRV(self)) && SvIV(SvRV(self)))
            punk_cache_free(aTHX_ INT2PTR(punk_cache *, SvIV(SvRV(self))));

# get($key) -> the bytes, or undef
#
# Undef means absent OR expired, deliberately: a caller does not need to know
# which, and a store that distinguished them would leak its expiry policy into
# every call site.
SV *
get(self, key)
        SV *self
        SV *key
    CODE:
    {
        punk_cache *c = INT2PTR(punk_cache *, SvIV(SvRV(self)));
        STRLEN kl;
        const char *k = SvPV_const(key, kl);
        uint32_t vlen = 0;
        const char *v = punk_cache_get(aTHX_ c, k, (uint32_t)kl,
                                       pc_now(aTHX), &vlen);
        if (!v) XSRETURN_UNDEF;
        RETVAL = newSVpvn(v, vlen);
    }
    OUTPUT:
        RETVAL

# set($key, $bytes, $ttl) -> 1 stored, 0 refused
#
# $ttl is seconds; 0 means NO EXPIRY, not "expire immediately". The opposite
# reading is the sort of thing that empties a cache in production, so it is
# stated here, in the contract, and asserted in the conformance suite.
#
# A value too big for the budget is refused rather than stored: making room
# would evict everything else and still not fit.
IV
set(self, key, value, ttl = 0)
        SV *self
        SV *key
        SV *value
        NV ttl
    CODE:
    {
        punk_cache *c = INT2PTR(punk_cache *, SvIV(SvRV(self)));
        STRLEN kl, vl;
        const char *k = SvPV_const(key, kl);
        const char *v = SvPV_const(value, vl);
        double expiry = ttl > 0 ? pc_now(aTHX) + (double)ttl : 0.0;
        RETVAL = punk_cache_set(aTHX_ c, k, (uint32_t)kl, v, (uint32_t)vl,
                                expiry);
    }
    OUTPUT:
        RETVAL

IV
delete(self, key)
        SV *self
        SV *key
    CODE:
    {
        punk_cache *c = INT2PTR(punk_cache *, SvIV(SvRV(self)));
        STRLEN kl;
        const char *k = SvPV_const(key, kl);
        RETVAL = punk_cache_delete(aTHX_ c, k, (uint32_t)kl);
    }
    OUTPUT:
        RETVAL

void
clear(self)
        SV *self
    CODE:
        punk_cache_clear(aTHX_ INT2PTR(punk_cache *, SvIV(SvRV(self))));

# stats() -> hits, misses, evictions, refused, expired, bytes, entries,
#            max_bytes
#
# Cumulative for the counters, current for bytes and entries. A cache whose
# hit rate cannot be seen is a cache nobody can tune, and the eviction count
# is the only way to tell "the budget is too small" from "these keys are
# simply cold".
void
stats(self)
        SV *self
    PPCODE:
    {
        punk_cache *c = INT2PTR(punk_cache *, SvIV(SvRV(self)));
        punk_cache_check_fork(aTHX_ c);
        EXTEND(SP, 16);
        mPUSHp("hits", 4);       mPUSHu((UV)c->hits);
        mPUSHp("misses", 6);     mPUSHu((UV)c->misses);
        mPUSHp("evictions", 9);  mPUSHu((UV)c->evictions);
        mPUSHp("refused", 7);    mPUSHu((UV)c->refused);
        mPUSHp("expired", 7);    mPUSHu((UV)c->expired);
        mPUSHp("bytes", 5);      mPUSHu((UV)c->bytes);
        mPUSHp("entries", 7);    mPUSHu((UV)c->entries);
        mPUSHp("max_bytes", 9);  mPUSHu((UV)c->max_bytes);
    }

MODULE = Punk        PACKAGE = Punk::Cache::File

PROTOTYPES: DISABLE

# The file cache store: the same five contract methods, on disk.
#
# One copy for the whole worker pool, because the filesystem is already
# shared - which is why this is Punk::Cache's default and the in-memory store
# is the opt-in.

SV *
new(class, ...)
        SV *class
    CODE:
    {
        UV max_bytes = 512 * 1024 * 1024;
        NV lock_wait = 5.0;
        SV *dir = NULL;
        punk_cachefile *c;
        STRLEN dl;
        const char *dp;
        int i;
        const char *cls = (SvROK(class) && SvOBJECT(SvRV(class)))
                        ? HvNAME(SvSTASH(SvRV(class))) : SvPV_nolen(class);

        for (i = 1; i + 1 < items; i += 2) {
            const char *k = SvPV_nolen(ST(i));
            if      (strEQ(k, "max_bytes")) max_bytes = SvUV(ST(i + 1));
            else if (strEQ(k, "dir"))       dir       = ST(i + 1);
            else if (strEQ(k, "lock_wait")) lock_wait = SvNV(ST(i + 1));
        }
        if (!(dir && SvOK(dir)))
            croak("Punk::Cache::File: need a `dir`");
        if (!max_bytes)
            croak("Punk::Cache::File: max_bytes must be greater than zero");

        dp = SvPV_const(dir, dl);
        /* Created and checked HERE, at construction - which is to_app - so an
         * unwritable directory is a boot failure in front of whoever deployed
         * it, not a silent miss at three in the morning. */
        if (mkdir(dp, 0700) != 0 && errno != EEXIST)
            croak("Punk::Cache::File: cannot create '%s': %s", dp,
                  strerror(errno));
        if (access(dp, W_OK | X_OK) != 0)
            croak("Punk::Cache::File: '%s' is not writable", dp);

        c = punk_cachefile_new(aTHX_ dp, dl, (size_t)max_bytes,
                               (double)lock_wait);
        if (!c) croak("Punk::Cache::File: '%s' is too long a path", dp);
        RETVAL = sv_bless(newRV_noinc(newSViv(PTR2IV(c))),
                          gv_stashpv(cls, GV_ADD));
    }
    OUTPUT:
        RETVAL

void
DESTROY(self)
        SV *self
    CODE:
        if (SvROK(self) && SvIOK(SvRV(self)) && SvIV(SvRV(self)))
            punk_cachefile_free(aTHX_
                INT2PTR(punk_cachefile *, SvIV(SvRV(self))));

SV *
get(self, key)
        SV *self
        SV *key
    CODE:
    {
        punk_cachefile *c = INT2PTR(punk_cachefile *, SvIV(SvRV(self)));
        STRLEN kl;
        const char *k = SvPV_const(key, kl);
        SV *v = punk_cachefile_get_sv(aTHX_ c, k, (uint32_t)kl, NULL);
        if (!v) XSRETURN_UNDEF;
        RETVAL = v;
    }
    OUTPUT:
        RETVAL

IV
set(self, key, value, ttl = 0)
        SV *self
        SV *key
        SV *value
        NV ttl
    CODE:
    {
        punk_cachefile *c = INT2PTR(punk_cachefile *, SvIV(SvRV(self)));
        STRLEN kl, vl;
        const char *k = SvPV_const(key, kl);
        const char *v = SvPV_const(value, vl);
        double expiry = ttl > 0 ? pcf_now() + (double)ttl : 0.0;
        RETVAL = punk_cachefile_set(aTHX_ c, k, (uint32_t)kl, v,
                                    (uint32_t)vl, expiry);
    }
    OUTPUT:
        RETVAL

IV
delete(self, key)
        SV *self
        SV *key
    CODE:
    {
        punk_cachefile *c = INT2PTR(punk_cachefile *, SvIV(SvRV(self)));
        STRLEN kl;
        const char *k = SvPV_const(key, kl);
        RETVAL = punk_cachefile_delete(aTHX_ c, k, (uint32_t)kl);
    }
    OUTPUT:
        RETVAL

void
clear(self)
        SV *self
    CODE:
        punk_cachefile_clear(aTHX_
            INT2PTR(punk_cachefile *, SvIV(SvRV(self))));

void
stats(self)
        SV *self
    PPCODE:
    {
        punk_cachefile *c = INT2PTR(punk_cachefile *, SvIV(SvRV(self)));
        uint64_t bytes = 0, entries = 0;
        punk_cachefile_check_fork(aTHX_ c);
        punk_cachefile_usage(c, &bytes, &entries);
        EXTEND(SP, 16);
        mPUSHp("hits", 4);       mPUSHu((UV)c->hits);
        mPUSHp("misses", 6);     mPUSHu((UV)c->misses);
        mPUSHp("evictions", 9);  mPUSHu((UV)c->evictions);
        mPUSHp("refused", 7);    mPUSHu((UV)c->refused);
        mPUSHp("expired", 7);    mPUSHu((UV)c->expired);
        mPUSHp("bytes", 5);      mPUSHu((UV)bytes);
        mPUSHp("entries", 7);    mPUSHu((UV)entries);
        mPUSHp("max_bytes", 9);  mPUSHu((UV)c->max_bytes);
    }

# The single-flight seam, used by Punk::Cache::compute.
#
# _lock returns 1 to the caller that should compute and 0 to one that should
# look again. A loser NEVER blocks here: waiting is the caller's business, and
# it gives up and computes rather than hanging on a lock whose holder may have
# died.
IV
_lock(self, key)
        SV *self
        SV *key
    CODE:
    {
        punk_cachefile *c = INT2PTR(punk_cachefile *, SvIV(SvRV(self)));
        STRLEN kl;
        const char *k = SvPV_const(key, kl);
        RETVAL = punk_cachefile_lock(aTHX_ c, k, (uint32_t)kl);
    }
    OUTPUT:
        RETVAL

void
_unlock(self, key)
        SV *self
        SV *key
    CODE:
    {
        punk_cachefile *c = INT2PTR(punk_cachefile *, SvIV(SvRV(self)));
        STRLEN kl;
        const char *k = SvPV_const(key, kl);
        punk_cachefile_unlock(aTHX_ c, k, (uint32_t)kl);
    }

NV
_lock_wait(self)
        SV *self
    CODE:
    {
        /* a braced block with a temporary: `RETVAL = INT2PTR(...)->field;`
         * as a bare one-liner mis-parses in xsubpp */
        punk_cachefile *c = INT2PTR(punk_cachefile *, SvIV(SvRV(self)));
        RETVAL = c->lock_wait;
    }
    OUTPUT:
        RETVAL

# Force the reconciling sweep. Normally amortised onto writes; exposed so a
# test can assert the budget without waiting for the threshold.
void
_sweep(self)
        SV *self
    CODE:
        pcf_sweep(aTHX_ INT2PTR(punk_cachefile *, SvIV(SvRV(self))));

MODULE = Punk        PACKAGE = Punk::Cache

PROTOTYPES: DISABLE

# The front end over a backend: punk_cachefront.h holds the whole of it, and
# its header comment says why this tier is worth being C.
#
# A hit on either shipped store lands in punk_cache.h / punk_cachefile.h with
# no method dispatch at all; any other backend is reached through call_method
# exactly as it always was, because pluggability is the point of the tier.

# new($spec, %opt)
#
# $spec is `memory`, `file`, a class name, or a ready-made backend object.
# The options go to the backend, less `name`, which is ours: it is the
# invalidation topic, and a store without one invalidates locally.
SV *
new(class, ...)
        SV *class
    CODE:
    {
        AV *args = (AV *)sv_2mortal((SV *)newAV());
        int i;
        /* The arguments are copied off the stack BEFORE anything below can
         * call Perl: a require or a backend constructor may reallocate the
         * value stack, and ST() would then be reading freed memory. */
        for (i = 1; i < items; i++) av_push(args, newSVsv(ST(i)));
        RETVAL = pkc_new(aTHX_ class, args);
    }
    OUTPUT:
        RETVAL

void
DESTROY(self)
        SV *self
    CODE:
        if (SvROK(self) && SvIOK(SvRV(self)) && SvIV(SvRV(self))) {
            pkc_free(aTHX_ INT2PTR(punk_cachefront *, SvIV(SvRV(self))));
            sv_setiv(SvRV(self), 0);
        }

# The compile step hands over what the `cache` keyword recorded. Separate from
# new() so the keyword's shape stays the keyword's business.
SV *
_from_spec(class, spec, opts, name = &PL_sv_undef)
        SV *class
        SV *spec
        SV *opts
        SV *name
    CODE:
    {
        AV *args = (AV *)sv_2mortal((SV *)newAV());
        av_push(args, newSVsv(spec));
        if (opts && SvROK(opts) && SvTYPE(SvRV(opts)) == SVt_PVHV) {
            HV *h = (HV *)SvRV(opts);
            HE *e;
            hv_iterinit(h);
            while ((e = hv_iternext(h))) {
                av_push(args, newSVsv(hv_iterkeysv(e)));
                av_push(args, newSVsv(HeVAL(e)));
            }
        }
        av_push(args, newSVpvs("name"));
        av_push(args, SvOK(name) ? newSVsv(name) : newSVpvs("default"));
        RETVAL = pkc_new(aTHX_ class, args);
    }
    OUTPUT:
        RETVAL

# 512M / 2G / 1024 - because everybody writes it the first way, and a cache
# configured in bare bytes by hand is a cache configured wrong by an order of
# magnitude. undef when it is not a size at all.
SV *
_bytes(v)
        SV *v
    CODE:
    {
        NV b = 0.0;
        if (!pkc_bytes(aTHX_ v, &b)) XSRETURN_UNDEF;
        RETVAL = pkc_bytes_sv(aTHX_ b);
    }
    OUTPUT:
        RETVAL

# The underlying store, for its own statistics or anything backend-specific.
SV *
backend(self)
        SV *self
    CODE:
        RETVAL = newSVsv(pkc_of(aTHX_ self)->backend);
    OUTPUT:
        RETVAL

# This process's invalidation token. Private, and exposed only so a test can
# assert the property the pool depends on: that a store forked into two
# workers does not carry one token between them - see punk_cachefront.h.
SV *
_origin(self)
        SV *self
    CODE:
        RETVAL = newSVsv(pkc_origin(aTHX_ pkc_of(aTHX_ self)));
    OUTPUT:
        RETVAL

SV *
get(self, key)
        SV *self
        SV *key
    CODE:
    {
        SV *v = pkc_get(aTHX_ pkc_of(aTHX_ self), key);
        if (!v) XSRETURN_UNDEF;
        RETVAL = v;
    }
    OUTPUT:
        RETVAL

SV *
set(self, key, value = &PL_sv_undef, ttl = 0)
        SV *self
        SV *key
        SV *value
        NV ttl
    CODE:
    {
        SV *r = pkc_set(aTHX_ pkc_of(aTHX_ self), key, value, ttl);
        if (!r) XSRETURN_UNDEF;
        RETVAL = r;
    }
    OUTPUT:
        RETVAL

SV *
delete(self, key)
        SV *self
        SV *key
    CODE:
    {
        SV *r = pkc_delete(aTHX_ pkc_of(aTHX_ self), key);
        if (!r) XSRETURN_UNDEF;
        RETVAL = r;
    }
    OUTPUT:
        RETVAL

SV *
clear(self)
        SV *self
    CODE:
    {
        SV *r = pkc_clear(aTHX_ pkc_of(aTHX_ self));
        if (!r) XSRETURN_UNDEF;
        RETVAL = r;
    }
    OUTPUT:
        RETVAL

# The backend's own statistics, plus what only this tier knows: whether the
# pool is connected at all, and what this worker has sent and received.
# Without those an operator cannot tell a coherent pool from one where every
# worker is quietly serving its own stale copy.
void
stats(self)
        SV *self
    PPCODE:
    {
        punk_cachefront *f = pkc_of(aTHX_ self);
        AV *s = pkc_be_stats(aTHX_ f);
        SSize_t n = av_len(s) + 1, i;
        int pool = pkc_pool(aTHX);
        /* Both calls above run Perl, which can have grown - and so
         * reallocated - the value stack. SP was captured on entry, so it is
         * re-derived from ax rather than trusted. */
        SP = PL_stack_base + ax - 1;
        /* n from the backend, 8 for this tier's four pairs, 18 for the tier's
         * nine. Counted rather than estimated: a DEBUGGING perl records the
         * high-water mark an XSUB asked for and PANICS if it pushes past it,
         * so being four short is not a quiet overrun on the smokers, it is
         * `failed to extend arg stack` and a dead test file. */
        EXTEND(SP, n + 8 + 18);
        for (i = 0; i < n; i++) {
            SV *e = *av_fetch(s, i, 0);
            /* `hits` is the CACHE's, not the backend's: a read the tier
             * answered is a hit that happens to have cost nothing, and a
             * caller measuring its hit rate does not care which half of the
             * store served it. Rewritten rather than reported twice, so
             * hits + misses still equals the number of reads - `misses` needs
             * no adjusting, because a read only reaches the backend, and only
             * misses there, when the tier did not have it. */
            if (f->tier && i > 0 && (i & 1)
                && strEQ(SvPV_nolen(*av_fetch(s, i - 1, 0)), "hits")) {
                PUSHs(sv_2mortal(newSVuv(SvUV(e) + (UV)f->tier->hits)));
                continue;
            }
            PUSHs(sv_2mortal(newSVsv(e)));
        }
        mPUSHp("shared", 6);                 mPUSHi(f->shared ? 1 : 0);
        mPUSHp("pool", 4);                   mPUSHi(pool);
        mPUSHp("invalidations_sent", 18);    mPUSHu(f->sent);
        mPUSHp("invalidations_received", 22);mPUSHu(f->received);
        /* The tier's own counters, and only when there is one: a store
         * without a tier should not sprout keys that are always zero.
         *
         * `hits` and `misses` above stay the BACKEND's, so on a tiered store
         * they count the reads that got past the tier. The effective hit rate
         * is (memory_hits + hits) / (memory_hits + hits + misses) - said in
         * the POD, because a tier whose hit rate nobody can see is 64MB a
         * worker that nobody can justify. */
        if (f->tier) {
            punk_cache *t = f->tier;
            punk_cache_check_fork(aTHX_ t);
            mPUSHp("memory_hits", 11);      mPUSHu((UV)t->hits);
            mPUSHp("memory_misses", 13);    mPUSHu((UV)t->misses);
            mPUSHp("memory_evictions", 16); mPUSHu((UV)t->evictions);
            mPUSHp("memory_refused", 14);   mPUSHu((UV)t->refused);
            mPUSHp("memory_expired", 14);   mPUSHu((UV)t->expired);
            mPUSHp("memory_bytes", 12);     mPUSHu((UV)t->bytes);
            mPUSHp("memory_entries", 14);   mPUSHu((UV)t->entries);
            mPUSHp("memory_max_bytes", 16); mPUSHu((UV)t->max_bytes);
            mPUSHp("memory_ttl", 10);       mPUSHn(f->tier_ttl);
        }
    }

# The backend's reconciling sweep, forwarded. Private, and here so that the
# conformance battery can assert the byte budget through the front end on
# exactly the terms it asserts it through the store.
void
_sweep(self)
        SV *self
    CODE:
    {
        punk_cachefront *f = pkc_of(aTHX_ self);
        if (f->kind == PKC_K_FILE) pcf_sweep(aTHX_ pkc_file(aTHX_ f));
        else if (f->caps & PKC_CAN_SWEEP) {
            SV *r = pcx_call_meth(aTHX_ f->backend, "_sweep", NULL, 0, 0);
            if (r) SvREFCNT_dec(r);
        }
    }

# compute($key, $ttl, $code, %opt)
#
# Get, and on a miss run the code, store the result and return it. `json => 1`
# encodes and decodes a structure around the store.
SV *
compute(self, key, ttl, code, ...)
        SV *self
        SV *key
        NV ttl
        SV *code
    CODE:
    {
        int json = 0, i;
        SV *v;
        for (i = 4; i + 1 < items; i += 2)
            if (strEQ(SvPV_nolen(ST(i)), "json") && SvTRUE(ST(i + 1)))
                json = 1;
        v = pkc_compute(aTHX_ pkc_of(aTHX_ self), key, ttl, code, json);
        if (!v) XSRETURN_UNDEF;
        RETVAL = v;
    }
    OUTPUT:
        RETVAL

# The invalidation seam. Its own topic namespace, so a cache cannot be
# emptied by an application publishing to a name that happens to collide.

IV
_invalidate(self, name, key)
        SV *self
        SV *name
        SV *key
    CODE:
        PERL_UNUSED_VAR(self);
        RETVAL = punk_bus_cache_publish(aTHX_ name, key);
    OUTPUT:
        RETVAL

# The callback is invoked with the key to drop. It MUST NOT publish in turn -
# the subscriber talks to the backend directly - or an invalidation would
# echo around the pool forever.
IV
_on_invalidate(self, name, cb)
        SV *self
        SV *name
        SV *cb
    CODE:
        PERL_UNUSED_VAR(self);
        RETVAL = punk_bus_cache_subscribe(aTHX_ name, cb);
    OUTPUT:
        RETVAL

# Whether there is a pool to invalidate across at all.
IV
_pool_live(self = &PL_sv_undef)
        SV *self
    CODE:
        PERL_UNUSED_VAR(self);
        RETVAL = punk_bus_live(aTHX) ? 1 : 0;
    OUTPUT:
        RETVAL
