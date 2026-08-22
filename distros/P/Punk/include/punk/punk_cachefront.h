#ifndef PUNK_CACHEFRONT_H
#define PUNK_CACHEFRONT_H

#include <string.h>
#ifndef WIN32
#  include <sys/select.h>
#endif

/* A cached undef is a VALUE, not a miss.
 *
 * If compute() stores nothing when the code returns undef, an expensive
 * lookup that legitimately finds nothing is repeated on every single request
 * - which is exactly the traffic pattern a cache exists to stop, and the case
 * people hit when they cache "does this user exist".
 *
 * So undef is stored as a marker no caller can produce by accident: a NUL, a
 * byte no text carries, and a tag. get() turns it back into undef and nothing
 * above can tell the difference. */
#define PKC_UNDEF      "\0PunkCache\0undef\0"
#define PKC_UNDEF_LEN  (sizeof(PKC_UNDEF) - 1)

/* The payload that means "drop everything", distinct from any real key by the
 * same trick. */
#define PKC_CLEAR      "\0PunkCache\0clear\0"
#define PKC_CLEAR_LEN  (sizeof(PKC_CLEAR) - 1)

#define PKC_KEY_MAX    4096
#define PKC_LOCK_WAIT  5.0        /* the default single-flight budget */

/* Which store this is, decided once at construction. GENERIC means "reach it
 * through call_method", which is every backend but the two shipped ones. */
#define PKC_K_GENERIC  0
#define PKC_K_MEMORY   1
#define PKC_K_FILE     2

/* The single-flight seam a backend offers, probed once at construction rather
 * than on every compute: `can` three times per cached miss is three method
 * resolutions to answer a question whose answer cannot change for a store
 * that is already built. */
#define PKC_CAN_LOCK      1
#define PKC_CAN_UNLOCK    2
#define PKC_CAN_LOCKWAIT  4
#define PKC_CAN_SWEEP     8

/* THE MEMORY TIER.
 *
 * A file hit is 7.2us and 6.2us of that is the `open` syscall - measured, in
 * plan_punk_cache/phase-6-xs-front.md. Nothing around the syscall is worth
 * tuning, so the only way a hit gets faster is not to open the file, and a
 * per-worker memory cache in front does exactly that.
 *
 * It is the byte-budgeted LRU from punk_cache.h, held HERE rather than
 * wrapped in a backend of its own, so that any store gets it - including a
 * Redis one nobody has written yet - and so that the rule below can live next
 * to the is_shared it depends on.
 *
 * WHAT IT COSTS, WHICH COMES FIRST. A tier turns a shared store from
 * instantly consistent across the pool into eventually consistent, bounded by
 * tier_ttl and the bus. That is why it is opt-in, and why `shared` below
 * means "shared AND untiered": a tiered store must publish and subscribe like
 * any unshared one, or worker A writes and workers B through H go on serving
 * their own copies.
 *
 * TIER_TTL IS NOT OPTIONAL, and not only for staleness. punk_cachefile.h
 * evicts coldest-first by st_atime, and a tier absorbs exactly the reads that
 * would keep a hot key's atime fresh - so without a ceiling the sweep evicts
 * the hottest entries FIRST. A ceiling means a hot key is re-read from disk
 * at least that often, which keeps the eviction signal alive and bounds
 * staleness when the bus drops a message. One ceiling, two jobs. */
#define PKC_TIER_TTL      5.0     /* seconds, the default ceiling */
/* One value may not take more than this share of the tier. punk_cache_set
 * refuses only what cannot fit the WHOLE budget, so without this a 50MB page
 * is admitted to a 64M tier and flushes the entire hot set on its way in. */
#define PKC_TIER_MAX_SHARE 8

typedef struct {
    SV  *backend;             /* the store, owned */
    SV  *name;                /* the invalidation topic, owned; NULL if none */
    SV  *origin;              /* this process's token, owned, minted lazily */
    IV   origin_pid;          /* the pid it was minted in */
    int  kind;
    int  shared;              /* is_shared AND untiered - see above */
    int  caps;
    UV   sent, received;

    punk_cache *tier;         /* the memory tier, or NULL */
    double      tier_ttl;     /* the ceiling, seconds */
    size_t      tier_max_entry;
} punk_cachefront;

static UV PKC_ORIGIN_SEQ = 0;

static punk_cachefront *pkc_of(pTHX_ SV *self) {
    if (!(self && SvROK(self) && SvIOK(SvRV(self)) && SvIV(SvRV(self))))
        croak("Punk::Cache: not a cache handle");
    return INT2PTR(punk_cachefront *, SvIV(SvRV(self)));
}

/* ---- sizes ---------------------------------------------------------------
 *
 * 512M / 2G / 1024 - because everybody writes it the first way, and a cache
 * configured in bare bytes by hand is a cache configured wrong by an order of
 * magnitude. 0 when it is not a size at all, which is a boot croak rather
 * than a silently enormous or silently tiny budget. */
static int pkc_bytes(pTHX_ SV *v, NV *out) {
    STRLEN len;
    const char *s, *p, *end;
    NV n = 0.0, mult = 1.0, frac = 0.1;
    int digits = 0;

    if (!(v && SvOK(v))) return 0;
    s = SvPV_const(v, len);
    p = s; end = s + len;

    /* a plain byte count, taken as it stands */
    while (p < end && isDIGIT(*p)) p++;
    if (p > s && p == end) {
        for (p = s, n = 0.0; p < end; p++) n = n * 10.0 + (NV)(*p - '0');
        *out = n;
        return 1;
    }

    p = s;
    while (p < end && isSPACE(*p)) p++;
    while (p < end && isDIGIT(*p)) { n = n * 10.0 + (NV)(*p - '0'); p++; digits++; }
    if (!digits) return 0;
    if (p < end && *p == '.') {
        p++;
        digits = 0;
        while (p < end && isDIGIT(*p)) { n += frac * (NV)(*p - '0'); frac /= 10.0; p++; digits++; }
        if (!digits) return 0;              /* a trailing dot is not a number */
    }
    while (p < end && isSPACE(*p)) p++;
    if (p < end) {
        switch (*p) {
            case 'K': case 'k': mult = 1024.0;                    p++; break;
            case 'M': case 'm': mult = 1024.0 * 1024.0;           p++; break;
            case 'G': case 'g': mult = 1024.0 * 1024.0 * 1024.0;  p++; break;
            default: break;
        }
    }
    if (p < end && *p == 'B') p++;           /* 512MB, as people write it */
    while (p < end && isSPACE(*p)) p++;
    if (p != end) return 0;

    *out = Perl_floor(n * mult);
    return 1;
}

/* An IV where one is big enough, an NV where it is not: 2G overflows a 32-bit
 * IV, and a budget that silently wrapped would be worse than no budget. */
static SV *pkc_bytes_sv(pTHX_ NV n) {
    if (n >= 0.0 && n <= (NV)UV_MAX) return newSVuv((UV)n);
    return newSVnv(n);
}

/* ---- keys ----------------------------------------------------------------
 *
 * A key is bytes with a length limit. The rules live HERE so every backend
 * inherits the same ones rather than each inventing its own - which is how
 * two backends end up disagreeing about what is storable, and how an
 * application developed against one breaks on the other.
 *
 * The limit is counted in BYTES, which is what the message and the
 * documentation say. Counting characters would let a wide-character key past
 * a check the file store then cannot honour - its header holds 4096 bytes of
 * key - so such a key would write successfully and never read back. */
static const char *pkc_key(pTHX_ SV *key, STRLEN *len) {
    const char *k;
    if (!(key && SvOK(key)))  croak("Punk::Cache: a key must be defined");
    k = SvPV_const(key, *len);
    if (!*len)                croak("Punk::Cache: a key must not be empty");
    if (*len > PKC_KEY_MAX)   croak("Punk::Cache: a key is limited to %d bytes",
                                    PKC_KEY_MAX);
    return k;
}

static int pkc_is_undef_marker(pTHX_ SV *v) {
    STRLEN l;
    const char *p;
    if (!(v && SvOK(v))) return 0;
    p = SvPV_const(v, l);
    return l == PKC_UNDEF_LEN && memEQ(p, PKC_UNDEF, PKC_UNDEF_LEN);
}

/* ---- the backend, reached the fast way where it is known ------------------ */

static punk_cache *pkc_mem(pTHX_ punk_cachefront *f) {
    return INT2PTR(punk_cache *, SvIV(SvRV(f->backend)));
}
static punk_cachefile *pkc_file(pTHX_ punk_cachefront *f) {
    return INT2PTR(punk_cachefile *, SvIV(SvRV(f->backend)));
}

/* Every one of these takes the key as an SV and reads its bytes HERE, at the
 * point of use, rather than being handed a pointer taken earlier.
 *
 * That is not fussiness. A backend written in Perl receives the key as an
 * alias in @_ and a compute callback can hold the caller's own variable;
 * either can assign to it, which reallocates the SV's buffer. A char* taken
 * before the call and used after it would then be reading freed memory - and
 * the read would be a plausible-looking key, so the failure would be a wrong
 * answer rather than a crash. An SvPV is a load and a flag test; it is not
 * worth being clever about. */

/* The stored bytes (+1), or NULL for absent OR expired - a caller does not
 * need to know which.
 *
 * `expiry`, when not NULL, is filled with the entry's own absolute expiry so
 * the tier can be populated with it rather than with a fresh one. Only the
 * file store carries an expiry a reader can see; for everything else it stays
 * 0 and the tier falls back to its ceiling, which is the safe direction. */
static SV *pkc_be_get(pTHX_ punk_cachefront *f, SV *key, double *expiry) {
    STRLEN kl;
    const char *k;
    if (expiry) *expiry = 0.0;
    switch (f->kind) {
        case PKC_K_MEMORY: {
            uint32_t vlen = 0;
            const char *v;
            k = SvPV_const(key, kl);
            v = punk_cache_get(aTHX_ pkc_mem(aTHX_ f), k, (uint32_t)kl,
                               pc_now(aTHX), &vlen);
            return v ? newSVpvn(v, vlen) : NULL;
        }
        case PKC_K_FILE:
            k = SvPV_const(key, kl);
            return punk_cachefile_get_sv(aTHX_ pkc_file(aTHX_ f), k,
                                         (uint32_t)kl, expiry);
        default: {
            SV *r = pcx_call_meth(aTHX_ f->backend, "get", &key, 1, 1);
            if (r && !SvOK(r)) { SvREFCNT_dec(r); return NULL; }
            return r;
        }
    }
}

/* ---- the tier ------------------------------------------------------------- */

/* Drop one key from the tier. Used on a local write and on a received
 * invalidation, and a no-op on a store without one. */
static void pkc_tier_drop(pTHX_ punk_cachefront *f, SV *key) {
    STRLEN kl;
    const char *k;
    if (!f->tier) return;
    k = SvPV_const(key, kl);
    (void)punk_cache_delete(aTHX_ f->tier, k, (uint32_t)kl);
}

/* Put a value the backend just gave us into the tier.
 *
 * The expiry is the STORE's, capped by the ceiling - never one counted fresh
 * from now, which would let the tier outlive the entry it is standing in for.
 * An entry with no expiry of its own gets the ceiling, which is why a store
 * that cannot report one degrades to short-lived tier entries rather than to
 * permanent ones. */
static void pkc_tier_put(pTHX_ punk_cachefront *f, SV *key, SV *value,
                         double expiry) {
    STRLEN kl, vl;
    const char *k, *v;
    double now, ceiling;

    if (!f->tier) return;
    v = SvPV_const(value, vl);
    /* One value may not flush the hot set on its way in. */
    if (vl > f->tier_max_entry) return;

    k = SvPV_const(key, kl);
    now = pc_now(aTHX);
    ceiling = now + f->tier_ttl;
    if (expiry > 0.0 && expiry < ceiling) ceiling = expiry;
    (void)punk_cache_set(aTHX_ f->tier, k, (uint32_t)kl, v, (uint32_t)vl,
                         ceiling);
}

/* The read every public method goes through: the tier, then the backend, and
 * the backend's answer put into the tier on the way back. */
static SV *pkc_read(pTHX_ punk_cachefront *f, SV *key) {
    SV *v;
    double expiry = 0.0;

    if (f->tier) {
        STRLEN kl;
        const char *k = SvPV_const(key, kl);
        uint32_t vlen = 0;
        const char *hit = punk_cache_get(aTHX_ f->tier, k, (uint32_t)kl,
                                         pc_now(aTHX), &vlen);
        if (hit) return newSVpvn(hit, vlen);
    }

    v = pkc_be_get(aTHX_ f, key, f->tier ? &expiry : NULL);
    if (v) pkc_tier_put(aTHX_ f, key, v, expiry);
    return v;
}

/* What the backend said (+1): 1 stored, 0 refused for the shipped stores, and
 * whatever a custom one returns. */
static SV *pkc_be_set(pTHX_ punk_cachefront *f, SV *key, SV *value, NV ttl) {
    STRLEN kl, vl;
    const char *k, *v;
    switch (f->kind) {
        case PKC_K_MEMORY: {
            double now = pc_now(aTHX);
            k = SvPV_const(key, kl);
            v = SvPV_const(value, vl);
            return newSViv(punk_cache_set(aTHX_ pkc_mem(aTHX_ f), k,
                                          (uint32_t)kl, v, (uint32_t)vl,
                                          ttl > 0 ? now + (double)ttl : 0.0));
        }
        case PKC_K_FILE: {
            k = SvPV_const(key, kl);
            v = SvPV_const(value, vl);
            return newSViv(punk_cachefile_set(aTHX_ pkc_file(aTHX_ f), k,
                                              (uint32_t)kl, v, (uint32_t)vl,
                                              ttl > 0 ? pcf_now() + (double)ttl
                                                      : 0.0));
        }
        default: {
            SV *argv[3];
            argv[0] = key;
            argv[1] = value;
            argv[2] = sv_2mortal(newSVnv(ttl));
            return pcx_call_meth(aTHX_ f->backend, "set", argv, 3, 1);
        }
    }
}

static SV *pkc_be_delete(pTHX_ punk_cachefront *f, SV *key) {
    STRLEN kl;
    const char *k;
    switch (f->kind) {
        case PKC_K_MEMORY:
            k = SvPV_const(key, kl);
            return newSViv(punk_cache_delete(aTHX_ pkc_mem(aTHX_ f), k,
                                             (uint32_t)kl));
        case PKC_K_FILE:
            k = SvPV_const(key, kl);
            return newSViv(punk_cachefile_delete(aTHX_ pkc_file(aTHX_ f), k,
                                                 (uint32_t)kl));
        default:
            return pcx_call_meth(aTHX_ f->backend, "delete", &key, 1, 1);
    }
}

static SV *pkc_be_clear(pTHX_ punk_cachefront *f) {
    switch (f->kind) {
        case PKC_K_MEMORY:
            punk_cache_clear(aTHX_ pkc_mem(aTHX_ f));
            return NULL;                  /* the shipped stores return nothing */
        case PKC_K_FILE:
            punk_cachefile_clear(aTHX_ pkc_file(aTHX_ f));
            return NULL;
        default:
            return pcx_call_meth(aTHX_ f->backend, "clear", NULL, 0, 1);
    }
}

/* 1 to the caller that should compute, 0 to one that should look again. */
static int pkc_be_lock(pTHX_ punk_cachefront *f, SV *key) {
    if (f->kind == PKC_K_FILE) {
        STRLEN kl;
        const char *k = SvPV_const(key, kl);
        return punk_cachefile_lock(aTHX_ pkc_file(aTHX_ f), k, (uint32_t)kl);
    }
    {
        SV *r = pcx_call_meth(aTHX_ f->backend, "_lock", &key, 1, 1);
        int won = (r && SvTRUE(r)) ? 1 : 0;
        if (r) SvREFCNT_dec(r);
        return won;
    }
}

static void pkc_be_unlock(pTHX_ punk_cachefront *f, SV *key) {
    if (f->kind == PKC_K_FILE) {
        STRLEN kl;
        const char *k = SvPV_const(key, kl);
        punk_cachefile_unlock(aTHX_ pkc_file(aTHX_ f), k, (uint32_t)kl);
        return;
    }
    {
        SV *r = pcx_call_meth(aTHX_ f->backend, "_unlock", &key, 1, 0);
        if (r) SvREFCNT_dec(r);
    }
}

static double pkc_be_lock_wait(pTHX_ punk_cachefront *f) {
    if (f->kind == PKC_K_FILE) return pkc_file(aTHX_ f)->lock_wait;
    if (f->caps & PKC_CAN_LOCKWAIT) {
        SV *r = pcx_call_meth(aTHX_ f->backend, "_lock_wait", NULL, 0, 1);
        double w = (r && SvOK(r)) ? (double)SvNV(r) : PKC_LOCK_WAIT;
        if (r) SvREFCNT_dec(r);
        return w;
    }
    return PKC_LOCK_WAIT;
}

/* The backend's stats as a flat list of pairs (+1 each), in its own order. */
static AV *pkc_be_stats(pTHX_ punk_cachefront *f) {
    dSP;
    AV *out = (AV *)sv_2mortal((SV *)newAV());
    int count, i;
    ENTER; SAVETMPS;
    PUSHMARK(SP);
    EXTEND(SP, 1);
    PUSHs(f->backend);
    PUTBACK;
    count = call_method("stats", G_ARRAY);
    SPAGAIN;
    if (count > 0) {
        av_extend(out, (SSize_t)count - 1);
        for (i = count - 1; i >= 0; i--)
            (void)av_store(out, (SSize_t)i, newSVsv(POPs));
    }
    PUTBACK; FREETMPS; LEAVE;
    return out;
}

/* ---- the invalidation topic ---------------------------------------------- */

/* This process's origin token, minted on first use here and re-minted after a
 * fork - see the header comment: a token inherited from the parent is shared
 * by every worker, and a shared token makes every worker ignore every other
 * worker's invalidation. */
static SV *pkc_origin(pTHX_ punk_cachefront *f) {
    IV pid = (IV)PerlProc_getpid();
    if (!f->origin || f->origin_pid != pid) {
        struct timeval tv;
        UV salt;
        gettimeofday(&tv, NULL);
        salt = ((UV)tv.tv_sec ^ ((UV)tv.tv_usec << 8)) ^ PTR2UV(f);
        if (f->origin) SvREFCNT_dec(f->origin);
        f->origin = newSVpvf("%" UVuf ":%" IVdf ":%" UVuf,
                             ++PKC_ORIGIN_SEQ, pid, salt);
        f->origin_pid = pid;
    }
    return f->origin;
}

/* Tell the rest of the pool to drop this key.
 *
 * Best effort, and the documentation says so: the bus is bounded and drops
 * oldest under pressure, so a worker far enough behind can miss one and keep
 * a stale value. That is why a TTL should always be set - it bounds staleness
 * even when a message is lost. Invalidation makes a cache fresh quickly; TTL
 * is what makes it eventually correct.
 *
 * What travels is the KEY, never the value. Publishing values would make this
 * a replication system, and a bus slot is 2KB - a cached page would be
 * refused outright and the pool would silently diverge. */
static void pkc_publish(pTHX_ punk_cachefront *f, SV *key) {
    SV *msg;
    STRLEN kl;
    const char *k;
    if (f->shared || !f->name) return;
    k = SvPV_const(key, kl);
    msg = sv_2mortal(newSVsv(pkc_origin(aTHX_ f)));
    sv_catpvn(msg, "\0", 1);
    sv_catpvn(msg, k, kl);
    if (punk_bus_cache_publish(aTHX_ f->name, msg)) f->sent++;
}

/* The subscriber. Reached from the event loop with the published message, so
 * it talks STRAIGHT to the backend: going through delete() would publish in
 * turn and the invalidation would echo around the pool forever. */
XS_INTERNAL(pkc_inval_cb);
XS_INTERNAL(pkc_inval_cb) {
    dXSARGS;
    AV *cap = punk_clos_cap(aTHX_ cv);
    SV **slot = cap ? av_fetch(cap, 0, 0) : NULL;
    SV *weak = slot ? *slot : NULL;
    SV *msg = items > 0 ? ST(0) : NULL;
    punk_cachefront *f;
    const char *m, *o, *nul, *key;
    STRLEN ml, ol, kl;
    SV *r;

    /* The store is held weakly: a cache that has gone away must not be kept
     * alive by its own subscription, and its messages are simply dropped. */
    if (!(weak && SvROK(weak) && SvIOK(SvRV(weak)) && SvIV(SvRV(weak))))
        XSRETURN_EMPTY;
    if (!(msg && SvOK(msg))) XSRETURN_EMPTY;
    f = INT2PTR(punk_cachefront *, SvIV(SvRV(weak)));

    m = SvPV_const(msg, ml);
    nul = (const char *)memchr(m, '\0', ml);
    if (!nul) XSRETURN_EMPTY;                    /* no key: nothing to drop */

    /* Our own message. Acting on it would mean a `set` telling this very
     * store to drop the value it has just written. */
    o = SvPV_const(pkc_origin(aTHX_ f), ol);
    if (ol == (STRLEN)(nul - m) && memEQ(m, o, ol)) XSRETURN_EMPTY;

    f->received++;
    key = nul + 1;
    kl  = ml - (STRLEN)(nul - m) - 1;

    /* A TIERED store drops its own copy and STOPS. It must not reach the
     * backend: the backend is shared - a tier is only permitted in front of
     * one - so the writer has already changed the one copy there is, and for
     * the file store `delete` is `unlink`. Going further would mean every
     * worker deleting the file the writer had just written, on every write,
     * which empties the cache while looking like a tier that never hits. */
    if (f->tier) {
        if (kl == PKC_CLEAR_LEN && memEQ(key, PKC_CLEAR, PKC_CLEAR_LEN))
            punk_cache_clear(aTHX_ f->tier);
        else
            (void)punk_cache_delete(aTHX_ f->tier, key, (uint32_t)kl);
        XSRETURN_EMPTY;
    }

    if (kl == PKC_CLEAR_LEN && memEQ(key, PKC_CLEAR, PKC_CLEAR_LEN)) {
        r = pkc_be_clear(aTHX_ f);
    }
    else r = pkc_be_delete(aTHX_ f, sv_2mortal(newSVpvn(key, kl)));
    if (r) SvREFCNT_dec(r);
    XSRETURN_EMPTY;
}

/* Cross-worker invalidation.
 *
 * A SHARED store needs none: with the file backend a write is visible to
 * every worker the moment it lands, which is the same property that makes it
 * the default. An unshared one has to be told, and Punk has a bus.
 *
 * Registered HERE, which is compile time - in the parent, before the server
 * forks. That is the only moment a subscription reaches every worker; one
 * made inside a request lands in exactly one of them. */
static void pkc_wire(pTHX_ punk_cachefront *f, SV *self) {
    AV *cap;
    SV *cb, *weak;
    if (f->shared || !f->name) return;

    cap  = newAV();
    weak = newSVsv(self);
    sv_rvweaken(weak);
    av_push(cap, weak);
    cb = sv_2mortal(punk_closure(aTHX_ pkc_inval_cb, cap));
    (void)punk_bus_cache_subscribe(aTHX_ f->name, cb);
}

/* Whether a shared ring actually exists, not merely whether the ABI is
 * present: without an arena a publish reaches this process alone, and
 * reporting a connected pool would be exactly the false comfort this is meant
 * to remove. Hyperman is asked only if it is already loaded. */
static int pkc_pool(pTHX) {
    HV *inc = GvHVn(PL_incgv);
    HV *stash;
    GV *gv;
    SV *r;
    int live;

    if (!(inc && hv_exists(inc, "Hyperman.pm", 11))) return 0;
    stash = gv_stashpvs("Hyperman", 0);
    if (!stash) return 0;
    gv = gv_fetchmethod_autoload(stash, "bus_live", FALSE);
    if (!(gv && isGV(gv) && GvCV(gv))) return 0;

    r = pcx_call_meth(aTHX_ sv_2mortal(newSVpvs("Hyperman")), "bus_live",
                      NULL, 0, 1);
    live = (r && SvTRUE(r)) ? 1 : 0;
    if (r) SvREFCNT_dec(r);
    return live;
}

/* ---- construction --------------------------------------------------------- */

/* The five methods, checked wherever the backend came from. A custom store
 * missing one fails at BOOT with the name of what is missing, rather than on
 * the first request that happens to call it. */
static void pkc_contract(pTHX_ SV *backend) {
    static const char *const M[5] = { "get", "set", "delete", "clear", "stats" };
    const char *who = (SvROK(backend) && SvOBJECT(SvRV(backend)))
                    ? HvNAME(SvSTASH(SvRV(backend)))
                    : (SvOK(backend) ? SvPV_nolen(backend) : "undef");
    int i;
    for (i = 0; i < 5; i++) {
        SV *meth = sv_2mortal(newSVpv(M[i], 0));
        SV *can  = pcx_call_meth(aTHX_ backend, "can", &meth, 1, 1);
        int ok   = (can && SvTRUE(can)) ? 1 : 0;
        if (can) SvREFCNT_dec(can);
        if (!ok)
            croak("Punk::Cache: %s is not a usable backend - "
                  "it must implement %s", who ? who : "the backend", M[i]);
    }
}

static int pkc_can(pTHX_ SV *obj, const char *meth) {
    SV *m = sv_2mortal(newSVpv(meth, 0));
    SV *r = pcx_call_meth(aTHX_ obj, "can", &m, 1, 1);
    int ok = (r && SvTRUE(r)) ? 1 : 0;
    if (r) SvREFCNT_dec(r);
    return ok;
}

/* Which of the two shipped stores this is, by EXACT class: a subclass that
 * overrides `get` in Perl must still be dispatched to, so it does not qualify
 * for the fast path even though its guts are the same struct. */
static int pkc_kind(pTHX_ SV *backend) {
    HV *stash;
    const char *n;
    if (!(SvROK(backend) && SvOBJECT(SvRV(backend)) && SvIOK(SvRV(backend))))
        return PKC_K_GENERIC;
    stash = SvSTASH(SvRV(backend));
    n = stash ? HvNAME(stash) : NULL;
    if (!n) return PKC_K_GENERIC;
    if (strEQ(n, "Punk::Cache::Memory")) return PKC_K_MEMORY;
    if (strEQ(n, "Punk::Cache::File"))   return PKC_K_FILE;
    return PKC_K_GENERIC;
}

static SV *pkc_bless(pTHX_ SV *class, punk_cachefront *f) {
    const char *cls = (SvROK(class) && SvOBJECT(SvRV(class)))
                    ? HvNAME(SvSTASH(SvRV(class)))
                    : SvPV_nolen(class);
    return sv_bless(newRV_noinc(newSViv(PTR2IV(f))),
                    gv_stashpv(cls ? cls : "Punk::Cache", GV_ADD));
}

/* The store, wrapped, contract-checked and wired to the bus. `name` is the
 * invalidation topic and may be NULL - a store nobody named cannot address a
 * topic, so it invalidates locally and says so through stats. */
static SV *pkc_wrap(pTHX_ SV *class, SV *backend, SV *name,
                    size_t tier_bytes, double tier_ttl) {
    punk_cachefront *f;
    SV *self;
    int backend_shared = 0;

    pkc_contract(aTHX_ backend);

    /* A backend may implement is_shared, returning true when every worker
     * sees the same data. Leaving it out means unshared, which is the safe
     * way round: an unnecessary invalidation costs a message, a missing one
     * serves stale data. */
    if (pkc_can(aTHX_ backend, "is_shared")) {
        SV *r = pcx_call_meth(aTHX_ backend, "is_shared", NULL, 0, 1);
        backend_shared = (r && SvTRUE(r)) ? 1 : 0;
        if (r) SvREFCNT_dec(r);
    }

    /* A tier in front of a store that is already per-process multiplies the
     * memory and buys nothing, so it is refused rather than quietly built.
     * The strictness also earns something downstream: because a tier implies
     * a shared backend, a received invalidation can drop the tier entry and
     * NEVER touch the backend, with no condition to get wrong - and getting
     * it wrong means unlinking the file another worker has just written. */
    if (tier_bytes && !backend_shared)
        croak("Punk::Cache: `memory` is a tier in front of a SHARED store, "
              "and this backend reports that it is not shared - a memory "
              "cache in front of a per-process one multiplies the footprint "
              "and caches nothing new");

    Newxz(f, 1, punk_cachefront);
    f->backend = newSVsv(backend);
    f->name    = (name && SvOK(name)) ? newSVsv(name) : NULL;
    f->kind    = pkc_kind(aTHX_ backend);

    if (tier_bytes) {
        f->tier           = punk_cache_new(aTHX_ tier_bytes);
        f->tier_ttl       = tier_ttl > 0 ? tier_ttl : PKC_TIER_TTL;
        f->tier_max_entry = tier_bytes / PKC_TIER_MAX_SHARE;
        if (!f->tier_max_entry) f->tier_max_entry = tier_bytes;
    }

    /* SHARED AND UNTIERED. A tiered store holds per-worker copies, so it
     * needs telling when a key changes exactly as an unshared one does -
     * without this the whole pool serves its own stale memory. */
    f->shared = backend_shared && !f->tier;

    if (f->kind == PKC_K_FILE)
        f->caps = PKC_CAN_LOCK | PKC_CAN_UNLOCK | PKC_CAN_LOCKWAIT;
    else if (f->kind == PKC_K_GENERIC) {
        if (pkc_can(aTHX_ backend, "_lock"))      f->caps |= PKC_CAN_LOCK;
        if (pkc_can(aTHX_ backend, "_unlock"))    f->caps |= PKC_CAN_UNLOCK;
        if (pkc_can(aTHX_ backend, "_lock_wait")) f->caps |= PKC_CAN_LOCKWAIT;
        if (pkc_can(aTHX_ backend, "_sweep"))     f->caps |= PKC_CAN_SWEEP;
    }

    self = pkc_bless(aTHX_ class, f);
    pkc_wire(aTHX_ f, self);
    return self;
}

/* `memory` and `file` are aliases for the two shipped stores. Anything else
 * is a CLASS: given in full if it contains `::`, and otherwise the short form
 * of a Punk::Cache:: backend, so `cache 'custom'` reaches Punk::Cache::Custom.
 *
 * That convention is what makes the interface pluggable rather than a fixed
 * list of two. A backend nobody here wrote is configured exactly the way the
 * shipped ones are, with no registration step to forget. */
static SV *pkc_backend_class(pTHX_ SV *spec) {
    STRLEN sl;
    const char *s = SvPV_const(spec, sl);
    SV *pkg;
    if (sl == 6 && memEQ(s, "memory", 6)) return newSVpvs("Punk::Cache::Memory");
    if (sl == 4 && memEQ(s, "file", 4))   return newSVpvs("Punk::Cache::File");
    if (memchr(s, ':', sl))               return newSVpvn(s, sl);
    pkg = newSVpvs("Punk::Cache::");
    if (sl) {
        char first = (char)toUPPER(s[0]);
        sv_catpvn(pkg, &first, 1);
        sv_catpvn(pkg, s + 1, sl - 1);
    }
    return pkg;
}

/* A backend name reaches `require`, so it is checked against the shape of a
 * package name first. Configuration is not attacker data, but a name that
 * turns into a path is the bug class this workspace keeps meeting, and the
 * check costs one pass at boot. */
static int pkc_pkg_ok(const char *p, STRLEN len) {
    STRLEN i = 0;
    if (!len) return 0;
    for (;;) {
        if (i >= len) return 0;
        if (!(isALPHA(p[i]) || p[i] == '_')) return 0;
        i++;
        while (i < len && (isALNUM(p[i]) || p[i] == '_')) i++;
        if (i == len) return 1;
        if (!(p[i] == ':' && i + 1 < len && p[i + 1] == ':')) return 0;
        i += 2;
    }
}

/* Load the backend class, telling a module that is MISSING from one that is
 * BROKEN apart: a backend whose module has a syntax error must report the
 * syntax error, not be dismissed as an unknown backend. A backend declared
 * inline - in the application file itself, or in a test - has no .pm to find,
 * and that is legitimate. */
static void pkc_load(pTHX_ SV *spec, SV *pkgsv) {
    STRLEN pl;
    const char *pkg = SvPV_const(pkgsv, pl);
    SV *file = sv_2mortal(newSVpvn("", 0));
    HV *inc;
    STRLEN i;
    SV *err;

    for (i = 0; i < pl; i++) {
        if (pkg[i] == ':' && i + 1 < pl && pkg[i + 1] == ':') {
            sv_catpvs(file, "/");
            i++;
        }
        else sv_catpvn(file, pkg + i, 1);
    }
    sv_catpvs(file, ".pm");

    /* Unconditionally, not `unless $pkg->can('new')` - that guard
     * short-circuits every time for the shipped stores, because the XS
     * supplies `new`, so the .pm - and the is_shared that decides whether
     * this store needs cross-worker invalidation - would never be loaded. */
    inc = GvHVn(PL_incgv);
    if (inc && hv_exists_ent(inc, file, 0)) return;

    eval_pv(form("require %s;", pkg), FALSE);
    if (!SvTRUE(ERRSV)) return;

    err = sv_2mortal(newSVsv(ERRSV));
    {
        STRLEN el, fl;
        const char *e = SvPV_const(err, el);
        const char *fp = SvPV_const(file, fl);
        SV *want = sv_2mortal(newSVpvs("Can't locate "));
        STRLEN wl;
        const char *wp;
        sv_catpvn(want, fp, fl);
        sv_catpvs(want, " in @INC");
        wp = SvPV_const(want, wl);
        if (!(el >= wl && memEQ(e, wp, wl)))
            croak_sv(err);          /* the module exists and is broken: THAT */
    }
    if (!pkc_can(aTHX_ pkgsv, "new"))
        /* Deliberately not the raw require error: an @INC dump buries the one
         * fact that helps, which is the class name that was looked for. */
        croak("Punk::Cache: unknown backend '%s' - %s is not installed "
              "(shipped backends: file, memory; a custom backend is loaded "
              "from Punk::Cache::<Name>)", SvPV_nolen(spec), pkg);
}

/* The options that belong to this tier rather than to the backend: `name`,
 * the invalidation topic, and `memory` / `memory_ttl`, the tier. Pulled out
 * of the option list wherever it came from, so a ready-made backend object
 * and a named class are configured the same way. */
static void pkc_own_opt(pTHX_ SV *k, SV *v, SV **name,
                        size_t *tier_bytes, double *tier_ttl, int *taken) {
    const char *ks = SvPV_nolen(k);
    *taken = 1;
    if (strEQ(ks, "name")) { *name = v; return; }
    if (strEQ(ks, "memory")) {
        NV b = 0.0;
        if (!pkc_bytes(aTHX_ v, &b) || !(b > 0.0))
            croak("Punk::Cache: memory '%s' is not a size "
                  "(try 64M, 512M, or a plain byte count)",
                  (v && SvOK(v)) ? SvPV_nolen(v) : "");
        *tier_bytes = (size_t)b;
        return;
    }
    if (strEQ(ks, "memory_ttl")) {
        NV t = (v && SvOK(v)) ? SvNV(v) : 0.0;
        if (!(t > 0.0))
            croak("Punk::Cache: memory_ttl must be greater than zero - it is "
                  "the ceiling that bounds how stale a tiered read can be, "
                  "and how long a hot entry can go unread on disk");
        *tier_ttl = (double)t;
        return;
    }
    *taken = 0;
}

/* new($class, $spec, %opt): args[0] is the spec, the rest are the backend's
 * options, less the ones pkc_own_opt keeps. */
static SV *pkc_new(pTHX_ SV *class, AV *args) {
    SSize_t n = av_len(args) + 1, i;
    SV *spec = n > 0 ? *av_fetch(args, 0, 0) : &PL_sv_undef;
    SV *name = NULL, *pkgsv, *backend, *self;
    AV *opts;
    STRLEN pl;
    const char *pkg;
    size_t tier_bytes = 0;
    double tier_ttl = PKC_TIER_TTL;

    /* a ready-made backend object: anything with the five contract methods */
    if (SvROK(spec)) {
        for (i = 1; i + 1 < n; i += 2) {
            int taken;
            pkc_own_opt(aTHX_ *av_fetch(args, i, 0), *av_fetch(args, i + 1, 0),
                        &name, &tier_bytes, &tier_ttl, &taken);
        }
        return pkc_wrap(aTHX_ class, spec, name, tier_bytes, tier_ttl);
    }

    if (!SvOK(spec)) spec = sv_2mortal(newSVpvs("file"));
    pkgsv = sv_2mortal(pkc_backend_class(aTHX_ spec));
    pkg = SvPV_const(pkgsv, pl);
    if (!pkc_pkg_ok(pkg, pl))
        croak("Punk::Cache: '%s' is not a usable backend name",
              SvPV_nolen(spec));

    /* the options the backend gets: ours removed, and max_bytes normalised
     * from 512M / 2G into bytes */
    opts = (AV *)sv_2mortal((SV *)newAV());
    for (i = 1; i + 1 < n; i += 2) {
        SV *k = *av_fetch(args, i, 0);
        SV *v = *av_fetch(args, i + 1, 0);
        const char *ks = SvPV_nolen(k);
        int taken;
        pkc_own_opt(aTHX_ k, v, &name, &tier_bytes, &tier_ttl, &taken);
        if (taken) continue;
        if (strEQ(ks, "max_bytes")) {
            NV b = 0.0;
            if (!pkc_bytes(aTHX_ v, &b) || !(b > 0.0))
                croak("Punk::Cache: max_bytes '%s' is not a size "
                      "(try 64M, 512M, 2G, or a plain byte count)",
                      SvOK(v) ? SvPV_nolen(v) : "");
            av_push(opts, newSVsv(k));
            av_push(opts, pkc_bytes_sv(aTHX_ b));
            continue;
        }
        av_push(opts, newSVsv(k));
        av_push(opts, newSVsv(v));
    }

    pkc_load(aTHX_ spec, pkgsv);

    {
        SSize_t on = av_len(opts) + 1;
        SV **argv;
        Newx(argv, on > 0 ? on : 1, SV *);
        for (i = 0; i < on; i++) argv[i] = *av_fetch(opts, i, 0);
        backend = pcx_call_meth(aTHX_ pkgsv, "new", argv, (int)on, 1);
        Safefree(argv);
    }
    if (!(backend && SvOK(backend))) {
        if (backend) SvREFCNT_dec(backend);
        croak("Punk::Cache: %s->new returned nothing usable", pkg);
    }
    self = pkc_wrap(aTHX_ class, sv_2mortal(backend), name, tier_bytes,
                    tier_ttl);
    return self;
}

/* ---- the operations -------------------------------------------------------
 *
 * SET invalidates too, not only delete. Worker A writing a new value while B
 * through H serve the old one out of memory until it expires is the same
 * staleness bug wearing a different hat - and the one that actually bites,
 * because updating a cached thing is far commoner than deleting it. */
static SV *pkc_get(pTHX_ punk_cachefront *f, SV *key) {
    STRLEN kl;
    SV *v;
    (void)pkc_key(aTHX_ key, &kl);
    v = pkc_read(aTHX_ f, key);
    if (v && pkc_is_undef_marker(aTHX_ v)) { SvREFCNT_dec(v); return NULL; }
    return v;
}

/* A local write DROPS the tier entry rather than replacing it with the value
 * just written.
 *
 * Write-through looks better and is wrong: two workers setting the same key
 * would each fill their own tier with their own value while the shared store
 * keeps only one of them, and the origin token means a writer never acts on
 * its own invalidation - so the loser would serve a value the store does not
 * hold for as long as the entry lived. Dropping costs one backend read on the
 * next request and cannot diverge. */
static SV *pkc_set(pTHX_ punk_cachefront *f, SV *key, SV *value, NV ttl) {
    STRLEN kl;
    SV *stored = (value && SvOK(value))
               ? value : sv_2mortal(newSVpvn(PKC_UNDEF, PKC_UNDEF_LEN));
    SV *r;
    (void)pkc_key(aTHX_ key, &kl);
    pkc_tier_drop(aTHX_ f, key);
    r = pkc_be_set(aTHX_ f, key, stored, ttl);
    if (r && SvTRUE(r)) pkc_publish(aTHX_ f, key);
    return r;
}

static SV *pkc_delete(pTHX_ punk_cachefront *f, SV *key) {
    STRLEN kl;
    SV *r;
    (void)pkc_key(aTHX_ key, &kl);
    pkc_tier_drop(aTHX_ f, key);
    r = pkc_be_delete(aTHX_ f, key);
    pkc_publish(aTHX_ f, key);
    return r;
}

static SV *pkc_clear(pTHX_ punk_cachefront *f) {
    SV *r;
    if (f->tier) punk_cache_clear(aTHX_ f->tier);
    r = pkc_be_clear(aTHX_ f);
    pkc_publish(aTHX_ f, sv_2mortal(newSVpvn(PKC_CLEAR, PKC_CLEAR_LEN)));
    return r;
}

/* ---- compute --------------------------------------------------------------
 *
 * The method that matters. Offering only get/set invites every application to
 * write the same three lines by hand and to get the undef case wrong. */
static void pkc_sleep(double secs) {
#ifdef WIN32
    Sleep((DWORD)(secs * 1000.0));
#else
    struct timeval tv;
    tv.tv_sec  = (long)secs;
    tv.tv_usec = (long)((secs - (double)(long)secs) * 1000000.0);
    (void)select(0, NULL, NULL, NULL, &tv);
#endif
}

/* Bytes back into whatever the caller stored: structures go through frj, the
 * ABI Punk already consumes. The cache itself stores BYTES - that rule is
 * what keeps the backends interchangeable - so this decodes at the edge
 * rather than letting one backend hold things another cannot. */
static SV *pkc_ready(pTHX_ SV *raw, int json) {
    SV *out;
    if (pkc_is_undef_marker(aTHX_ raw)) { SvREFCNT_dec(raw); return NULL; }
    if (!json) return raw;
    {
        STRLEN l;
        const char *p = SvPV_const(raw, l);
        out = punk_frj(aTHX)->decode(aTHX_ p, l, NULL);
    }
    SvREFCNT_dec(raw);
    return out;
}

static SV *pkc_compute(pTHX_ punk_cachefront *f, SV *key, NV ttl, SV *code,
                       int json) {
    STRLEN kl;
    SV *raw, *val = NULL, *err = NULL, *store;
    int won = 0;

    if (!(code && SvROK(code) && SvTYPE(SvRV(code)) == SVt_PVCV))
        croak("Punk::Cache::compute: need a code reference");

    (void)pkc_key(aTHX_ key, &kl);
    raw = pkc_read(aTHX_ f, key);
    if (raw) return pkc_ready(aTHX_ raw, json);

    /* SINGLE-FLIGHT, where the backend offers it.
     *
     * When a hot key expires under load every worker misses at once and every
     * one of them recomputes - the moment a cache is most valuable is the
     * moment it stops helping.
     *
     * Three rules keep this from becoming a new way to hang, and they matter
     * more than the optimisation does:
     *
     *   - a loser that waits out its budget COMPUTES ANYWAY. Correctness
     *     never depends on the lock: duplicated work is a cost, a stalled
     *     request is an outage, and a request hanging because the winner died
     *     is worse than both;
     *   - a stale lock is stolen by the backend rather than obeyed, or one
     *     crash poisons a key until somebody notices;
     *   - the lock covers one compute and nothing unbounded. */
    if (f->caps & PKC_CAN_LOCK) {
        won = pkc_be_lock(aTHX_ f, key);
        if (!won) {
            double deadline = pc_now(aTHX) + pkc_be_lock_wait(aTHX_ f);
            while (pc_now(aTHX) < deadline) {
                SV *ready;
                pkc_sleep(0.002);
                ready = pkc_read(aTHX_ f, key);
                if (ready) return pkc_ready(aTHX_ ready, json);
                if (pkc_be_lock(aTHX_ f, key)) {
                    /* The holder finished or died between our read and
                     * this acquisition - and a winner WRITES before it
                     * unlocks, so if it finished, its value is visible
                     * to a re-read made while holding the lock. Look
                     * again or a herd of two computes twice. */
                    SV *again = pkc_read(aTHX_ f, key);
                    if (again) {
                        if (f->caps & PKC_CAN_UNLOCK)
                            pkc_be_unlock(aTHX_ f, key);
                        return pkc_ready(aTHX_ again, json);
                    }
                    won = 1;
                    break;
                }
            }
            /* waited it out: compute rather than hang */
        }
    }

    /* dSP HERE and not at the top: every call above can have grown - and so
     * reallocated - the value stack, and a stack pointer captured before them
     * would be pushed through into freed memory. */
    {
        dSP;
        int count;
        ENTER; SAVETMPS;
        PUSHMARK(SP);
        PUTBACK;
        count = call_sv(code, G_SCALAR | G_EVAL);
        SPAGAIN;
        if (count > 0) val = SvREFCNT_inc(POPs);
        PUTBACK;
        if (SvTRUE(ERRSV)) {
            err = newSVsv(ERRSV);
            if (val) { SvREFCNT_dec(val); val = NULL; }
        }
        FREETMPS; LEAVE;
    }

    if (!err) {
        if (!(val && SvOK(val)))
            store = sv_2mortal(newSVpvn(PKC_UNDEF, PKC_UNDEF_LEN));
        else if (json)
            store = sv_2mortal(punk_frj(aTHX)->encode(aTHX_ val, NULL));
        else
            store = val;
        {
            SV *r = pkc_be_set(aTHX_ f, key, store, ttl);
            if (r) SvREFCNT_dec(r);
        }
    }

    /* The lock is released whether the compute worked or not: holding it
     * after a failure would make one bad call block every other worker for
     * the whole wait budget. Only the holder releases it - a loser that
     * waited out its budget and computed anyway does NOT own the lock,
     * and unlinking it here would free the real winner's lock early and
     * hand a third worker the same computation. */
    if (won && (f->caps & PKC_CAN_UNLOCK)) pkc_be_unlock(aTHX_ f, key);

    if (err) {
        if (val) SvREFCNT_dec(val);
        croak_sv(sv_2mortal(err));
    }
    if (val && !SvOK(val)) { SvREFCNT_dec(val); return NULL; }
    return val;
}

static void pkc_free(pTHX_ punk_cachefront *f) {
    if (!f) return;
    if (f->tier)    punk_cache_free(aTHX_ f->tier);
    if (f->backend) SvREFCNT_dec(f->backend);
    if (f->name)    SvREFCNT_dec(f->name);
    if (f->origin)  SvREFCNT_dec(f->origin);
    Safefree(f);
}

#endif /* PUNK_CACHEFRONT_H */
