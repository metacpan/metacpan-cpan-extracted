#ifndef SA_CACHE_H
#define SA_CACHE_H

/* sa_cache.h - a shared cache, which is a map that throws something away
 * instead of saying no. Perl-free.
 *
 * ---- why this is not the map with a policy on top ---------------------------
 *
 * The map refuses when it is full, which is right for a table of things that
 * must be there and wrong for a cache. A cache must choose a victim and take
 * its place, and that choice cannot be made from Perl: picking a victim and
 * replacing it has to be one operation as far as a reader is concerned, or two
 * processes evict each other's entries and a reader sees a key that is briefly
 * neither the old value nor the new one.
 *
 * ---- set-associative, because a probe chain cannot be evicted from ----------
 *
 * An open-addressed table with one long probe chain has nowhere to put a new
 * key when it is full: the slot a victim frees is almost never the slot the new
 * key hashes to. So the table is divided into small BUCKETS of `ways` entries,
 * a key belongs to exactly one bucket, and a victim is chosen from inside it.
 * That is how a CPU cache is arranged, for the same reason.
 *
 * It also makes the work bounded. A lookup touches `ways` entries and stops; an
 * eviction considers `ways` candidates and stops. Neither degrades as the cache
 * fills, which is the failure mode of a full open-addressed table.
 *
 * The cost is that a bucket can fill while the cache as a whole has room, so a
 * hot bucket evicts sooner than a perfect cache would. With eight ways that is
 * a small effect and it buys a bounded probe; with two it would not be.
 *
 * ---- CLOCK, not LRU ---------------------------------------------------------
 *
 * True LRU reorders a list on every READ, which makes every reader a writer and
 * throws away the property that makes this worth sharing. CLOCK sets one bit on
 * a hit and sweeps a hand round the bucket at eviction time, clearing bits and
 * taking the first entry whose bit was already clear. A reader writes one bit
 * with one atomic and takes no lock.
 *
 * It approximates LRU well enough that the difference is hard to measure, and
 * it is the standard answer for exactly this reason.
 *
 * ---- expiry is lazy ---------------------------------------------------------
 *
 * An entry with a deadline is not swept when it passes; it is noticed when
 * somebody looks, and preferred as a victim when somebody needs room. Sweeping
 * would mean a process whose job is to walk the whole cache on a timer, which
 * is work nobody asked for at a moment nobody chose.
 *
 * Needs sa_arena.h.
 */

#include "sa/sa_arena.h"
#include "sa/sa_peer.h"      /* sa_getpid, for the batched counts */

#ifdef _WIN32
#  include <windows.h>
#else
#  include <sys/time.h>
#endif

#define SA_CACHE_MAGIC 0x45484341u    /* 'A','C','H','E' little-endian */

#define SA_CACHE_MIN_WAYS 1
#define SA_CACHE_MAX_WAYS 64

/* what a set answers */
#define SA_C_OK      1
#define SA_C_TOOBIG (-1)

/* what a get answers */
#define SA_C_HIT   0
#define SA_C_MISS  1
#define SA_C_BUSY  2

typedef struct {
    volatile uint32_t state;     /* 0 empty, 1 live                        */
    volatile uint32_t version;   /* odd while being written                */
    volatile uint32_t klen;
    volatile uint32_t vlen;
    volatile uint64_t tag;
    volatile uint64_t expires;   /* ms since the epoch; 0 = never          */
    volatile uint32_t used;      /* CLOCK's reference bit                  */
    uint32_t          pad;
    char              bytes[1];  /* key then value, way_size in total      */
} sa_cache_way;

typedef struct {
    volatile uint32_t magic;      /* published LAST at init                */
    uint32_t          way_size;
    uint32_t          ways;
    uint32_t          pad;
    uint64_t          nbuckets;
    uint64_t          ways_off;   /* from the CACHE's base                 */
    uint64_t          hands_off;  /* one CLOCK hand per bucket             */
    volatile uint64_t hits;
    volatile uint64_t misses;
    volatile uint64_t evictions;
    volatile uint64_t expired;    /* found dead, by a reader or a victim hunt */
    volatile uint64_t used;       /* live entries                          */
    volatile unsigned char locks[SA_LOCK_STRIPES];
} sa_cache_hdr;

typedef struct sa_cache {
    sa_region     *arena;
    sa_cache_hdr  *hdr;
    char          *ways;
    volatile uint32_t *hands;
    uint32_t       way_size;
    uint32_t       nways;
    uint64_t       nbuckets;
    uint64_t       pair_max;
    /* Counted in this process and published in batches: see sa_cache_count. */
    uint64_t       pend_pid;
    uint32_t       pend_hits;
    uint32_t       pend_misses;
} sa_cache;

#define SA_CWAY_AT(c, b, w) \
    ((sa_cache_way *)((c)->ways + \
        ((size_t)((b) * (c)->nways + (w))) * (c)->way_size))

static uint64_t sa_cache_capacity(uint32_t way_size) {
    uint64_t hdr = (uint64_t)sizeof(sa_cache_way) - 1;
    return way_size > hdr ? (uint64_t)way_size - hdr : 0;
}

static uint64_t sa_cache_bytes(uint64_t nbuckets, uint32_t nways,
                               uint32_t way_size) {
    return sa_align_up((uint64_t)sizeof(sa_cache_hdr))
         + sa_align_up(nbuckets * nways * (uint64_t)way_size)
         + sa_align_up(nbuckets * 4u);
}

/* sa_now_ms moved to sa_time.h, so the map's TTL and this cache read the one
 * shared wall clock rather than each keeping their own. */

static sa_cache *sa_cache_bind(sa_region *arena, sa_reg *e, uint64_t nbuckets,
                               uint32_t nways, uint32_t way_size, int *err)
{
#if !SA_HAVE_ATOMICS
    (void)arena; (void)e; (void)nbuckets; (void)nways; (void)way_size;
    if (err) *err = SA_E_NOATOMICS;
    return NULL;
#else
    sa_cache *c;
    sa_cache_hdr *h;
    uint64_t hash;

    if (err) *err = SA_E_OK;
    if (!arena || !e) { if (err) *err = SA_E_NOENT; return NULL; }

    h = (sa_cache_hdr *)sa_ptr_len(arena, e->off, sizeof(sa_cache_hdr));
    if (!h) { if (err) *err = SA_E_NOENT; return NULL; }

    if (sa_at_load32_acq(&h->magic) != SA_CACHE_MAGIC) {
        hash = sa_at_fnv(e->name, strlen(e->name));
        if (sa_at_lock(h->locks, hash)) {
            if (sa_at_load32_acq(&h->magic) != SA_CACHE_MAGIC) {
                if (!nbuckets || !nways || sa_cache_capacity(way_size) == 0
                    || sa_cache_bytes(nbuckets, nways, way_size) > e->len) {
                    sa_at_unlock(h->locks, hash);
                    if (err) *err = SA_E_FULL;
                    return NULL;
                }
                memset((void *)h, 0,
                       (size_t)sa_cache_bytes(nbuckets, nways, way_size));
                h->way_size  = way_size;
                h->ways      = nways;
                h->nbuckets  = nbuckets;
                h->ways_off  = sa_align_up((uint64_t)sizeof(sa_cache_hdr));
                h->hands_off = h->ways_off
                             + sa_align_up(nbuckets * nways * (uint64_t)way_size);
                sa_at_store32_rel(&h->magic, SA_CACHE_MAGIC);
            }
            sa_at_unlock(h->locks, hash);
        }
        if (!sa_wait_magic32(&h->magic, SA_CACHE_MAGIC)) {
            if (err) *err = SA_E_MAGIC;
            return NULL;
        }
    }

    /* THE GEOMETRY IN THE HEADER IS ALSO SOMEBODY ELSE'S NUMBER.
     *
     * The branch above only checks a size when this process is the one doing
     * the INITIALISING. A process that finds the magic already set reads the
     * shape out of the shared header and believed it, so a header claiming
     * four billion slots put every later read past the end of the mapping.
     * sa_reg_ok makes `len` trustworthy; this makes the shape trustworthy. */

    if ((nbuckets && h->nbuckets != nbuckets) || (nways && h->ways != nways)
        || (way_size && h->way_size != way_size)) {
        if (err) *err = SA_E_NAME;
        return NULL;
    }

    c = (sa_cache *)calloc(1, sizeof(sa_cache));
    if (!c) { if (err) *err = SA_E_NOMEM; return NULL; }
    c->arena    = arena;
    c->hdr      = h;
    c->ways     = (char *)h + (size_t)h->ways_off;
    c->hands    = (volatile uint32_t *)((char *)h + (size_t)h->hands_off);
    c->way_size = h->way_size;
    c->nways    = h->ways;
    c->nbuckets = h->nbuckets;
    c->pair_max = sa_cache_capacity(h->way_size);
    return c;
#endif
}

/* ---- THE HIT AND MISS COUNTS ARE BATCHED PER PROCESS -----------------------
 *
 * A hit used to add to hdr->hits, a line every process shares, so every read
 * in every process was an atomic write to one place. Measured with K forked
 * readers on one hot key, ns per get per process at K = 1 / 2 / 4 / 8:
 *
 *     counted per hit, CLOCK bit stored per hit    56 / 140 / 189 / 530
 *     the bit stored only when it reads clear      57 / 101 / 157 / 440
 *     and the hit not counted at all               57 /  63 /  62 / 112
 *
 * So a process counts in its own handle and publishes every SA_CACHE_BATCH.
 * Its own stats are exact, because asking for them publishes first. Another
 * process's reading can trail by up to SA_CACHE_BATCH - 1 of each per process,
 * and a process that exits without releasing its handle takes that many with
 * it.
 *
 * A FORK COPIES THE PENDING COUNTS, and the parent publishes its own copy. So
 * the counts carry the pid they were made under, and a child that finds a
 * different one discards them before counting its own. sa_getpid is a cached
 * load where pthread_atfork exists to invalidate it; where it does not, the
 * check would be a syscall per read, so those builds count every hit directly
 * as before. */
#if defined(SA_HAVE_ATFORK) && !defined(_WIN32)
#  define SA_CACHE_BATCH 64u
#else
#  define SA_CACHE_BATCH 1u
#endif

/* Publish what this process has counted and not yet published. */
static void sa_cache_flush(sa_cache *c) {
#if SA_HAVE_ATOMICS
    uint64_t me;
    if (!c) return;
    me = sa_getpid();
    if (c->pend_pid != me) {
        /* inherited across a fork: the parent's, and the parent's to publish */
        c->pend_pid  = me;
        c->pend_hits = c->pend_misses = 0;
        return;
    }
    if (c->pend_hits)   sa_at_fetch_add64(&c->hdr->hits,   c->pend_hits);
    if (c->pend_misses) sa_at_fetch_add64(&c->hdr->misses, c->pend_misses);
    c->pend_hits = c->pend_misses = 0;
#else
    (void)c;
#endif
}

static void sa_cache_count(sa_cache *c, int hit) {
#if SA_HAVE_ATOMICS
#  if SA_CACHE_BATCH > 1
    uint64_t me = sa_getpid();
    uint32_t *n = hit ? &c->pend_hits : &c->pend_misses;
    if (c->pend_pid != me) {
        c->pend_pid  = me;
        c->pend_hits = c->pend_misses = 0;
    }
    if (++*n >= SA_CACHE_BATCH) {
        sa_at_fetch_add64(hit ? &c->hdr->hits : &c->hdr->misses, (uint64_t)*n);
        *n = 0;
    }
#  else
    sa_at_fetch_add64(hit ? &c->hdr->hits : &c->hdr->misses, 1);
#  endif
#else
    (void)c; (void)hit;
#endif
}

/* Published before the handle goes, so a process that releases it leaves
 * nothing uncounted. */
static void sa_cache_free(sa_cache *c) {
    sa_cache_flush(c);
    free(c);
}

/* Has this entry's deadline passed? A zero deadline never does. */
static int sa_cache_dead(sa_cache_way *w, uint64_t now) {
    uint64_t e = sa_at_load64_acq(&w->expires);
    return e && e <= now;
}

/* ---- reading, without a lock ----------------------------------------------- */

static int sa_cache_get(sa_cache *c, const char *key, uint32_t klen,
                        char *out, uint32_t outmax, uint32_t *vlen)
{
#if !SA_HAVE_ATOMICS
    (void)c; (void)key; (void)klen; (void)out; (void)outmax; (void)vlen;
    return SA_C_MISS;
#else
    uint64_t tag = sa_at_fnv(key, klen);
    uint64_t b   = tag % c->nbuckets;
    uint32_t w;

    for (w = 0; w < c->nways; w++) {
        sa_cache_way *e = SA_CWAY_AT(c, b, w);
        long spin = 0;

        if (sa_at_load32_acq(&e->state) != 1) continue;
        if (sa_at_load64_acq(&e->tag) != tag) continue;

        for (;;) {
            uint32_t v1 = sa_at_load32_acq(&e->version);
            uint32_t kl, vl;
            uint64_t exp;

            if (v1 & 1u) {
                if (++spin >= SA_HASH_SPIN) return SA_C_BUSY;
                continue;
            }
            kl  = sa_at_load32_acq(&e->klen);
            vl  = sa_at_load32_acq(&e->vlen);
            exp = sa_at_load64_acq(&e->expires);
            if (kl != klen || (uint64_t)kl + vl > c->pair_max) break;
            if (memcmp(e->bytes, key, klen) != 0) break;

            /* The clock is read only when this entry has a deadline. It is
             * 11ns, and a cache that never set a ttl used to pay it on every
             * get, a miss included. */
            if (exp && exp <= sa_now_ms()) {
                /* Expired, and noticed rather than swept. It stays where it is
                 * and becomes the first thing evicted when this bucket needs
                 * room, which costs nothing until then. */
                sa_at_fetch_add64(&c->hdr->expired, 1);
                sa_cache_count(c, 0);
                return SA_C_MISS;
            }
            if (vl > outmax) { if (vlen) *vlen = vl; return SA_C_BUSY; }

            memcpy(out, e->bytes + kl, (size_t)vl);
            sa_at_fence_acq();
            if (sa_at_load32_acq(&e->version) != v1) {
                if (++spin >= SA_HASH_SPIN) return SA_C_BUSY;
                continue;
            }

            /* CLOCK's reference bit, stored only when it reads clear. Storing
             * it on every hit made every reader of a hot key write the line
             * they all load the entry from; the note above sa_cache_flush has
             * what that cost. */
            if (!sa_at_load32_acq(&e->used)) sa_at_store32_rel(&e->used, 1);
            sa_cache_count(c, 1);
            if (vlen) *vlen = vl;
            return SA_C_HIT;
        }
    }
    sa_cache_count(c, 0);
    return SA_C_MISS;
#endif
}

/* ---- choosing a victim ----------------------------------------------------- */

/* The way this key should occupy, under the caller's lock.
 *
 * In order of preference: the key itself, an empty way, an expired one, and
 * only then a victim chosen by sweeping CLOCK's hand. `*evicted` says whether
 * something live was thrown out, and `*was_dead` whether it had already
 * expired - which is not an eviction, it is a collection. */
static sa_cache_way *sa_cache_place(sa_cache *c, uint64_t b, const char *key,
                                    uint32_t klen, uint64_t tag, uint64_t *now,
                                    int *found, int *evicted, int *was_dead)
{
#if !SA_HAVE_ATOMICS
    (void)c; (void)b; (void)key; (void)klen; (void)tag; (void)now;
    (void)found; (void)evicted; (void)was_dead;
    return NULL;
#else
    sa_cache_way *empty = NULL, *dead = NULL;
    uint32_t w, steps;

    *found = *evicted = *was_dead = 0;

    for (w = 0; w < c->nways; w++) {
        sa_cache_way *e = SA_CWAY_AT(c, b, w);
        if (sa_at_load32_acq(&e->state) != 1) {
            if (!empty) empty = e;
            continue;
        }
        if (sa_at_load64_acq(&e->tag) == tag
            && sa_at_load32_acq(&e->klen) == klen
            && memcmp(e->bytes, key, klen) == 0) {
            *found = 1;
            return e;
        }
        if (!dead) {
            /* `*now` is 0 until something needs it: the clock is read for the
             * first entry that has a deadline, and never for a bucket where
             * none does. */
            uint64_t exp = sa_at_load64_acq(&e->expires);
            if (exp) {
                if (!*now) *now = sa_now_ms();
                if (exp <= *now) dead = e;
            }
        }
    }

    if (empty) return empty;
    if (dead)  { *was_dead = 1; return dead; }

    /* Every way is live: sweep. Bounded at two passes, because one pass may
     * clear every bit and the second is then guaranteed to find one clear. */
    for (steps = 0; steps < c->nways * 2u; steps++) {
        uint32_t hand = sa_at_load32_acq(&c->hands[b]) % c->nways;
        sa_cache_way *e = SA_CWAY_AT(c, b, hand);
        sa_at_store32_rel(&c->hands[b], (hand + 1u) % c->nways);
        if (sa_at_load32_acq(&e->used)) {
            sa_at_store32_rel(&e->used, 0);   /* a second chance */
            continue;
        }
        *evicted = 1;
        return e;
    }

    /* Every bit was set and stayed set, which means the whole bucket was hit
     * during the sweep. Take where the hand stands rather than looping. */
    *evicted = 1;
    return SA_CWAY_AT(c, b, sa_at_load32_acq(&c->hands[b]) % c->nways);
#endif
}

static int sa_cache_set(sa_cache *c, const char *key, uint32_t klen,
                        const char *val, uint32_t vlen, uint64_t ttl_ms)
{
#if !SA_HAVE_ATOMICS
    (void)c; (void)key; (void)klen; (void)val; (void)vlen; (void)ttl_ms;
    return SA_C_TOOBIG;
#else
    sa_cache_hdr *h = c->hdr;
    uint64_t tag, b, now;
    sa_cache_way *e;
    int found = 0, evicted = 0, was_dead = 0;

    if (!klen || (uint64_t)klen + vlen > c->pair_max) return SA_C_TOOBIG;

    tag = sa_at_fnv(key, klen);
    b   = tag % c->nbuckets;
    /* Only a ttl needs the clock up front. Otherwise place reads it if it
     * meets an entry with a deadline, and a cache that never sets one never
     * reads it at all. */
    now = ttl_ms ? sa_now_ms() : 0;

    /* The lock is on the BUCKET rather than the key, because a victim hunt
     * touches every way in it. */
    if (!sa_at_lock(h->locks, b)) return SA_C_TOOBIG;

    e = sa_cache_place(c, b, key, klen, tag, &now, &found, &evicted, &was_dead);
    if (!e) { sa_at_unlock(h->locks, b); return SA_C_TOOBIG; }

    sa_at_store32_rel(&e->version, sa_at_load32_acq(&e->version) | 1u);
    sa_at_fence_rel();

    if (!found) {
        memcpy(e->bytes, key, klen);
        sa_at_store32_rel(&e->klen, klen);
        sa_at_store64_rel(&e->tag, tag);
        if (evicted)       sa_at_fetch_add64(&h->evictions, 1);
        else if (was_dead) sa_at_fetch_add64(&h->expired, 1);
        if (!evicted && !was_dead) sa_at_fetch_add64(&h->used, 1);
    }
    memcpy(e->bytes + klen, val, vlen);
    sa_at_store32_rel(&e->vlen, vlen);
    sa_at_store64_rel(&e->expires, ttl_ms ? now + ttl_ms : 0);
    /* A new entry starts with its bit clear, so it is a candidate on the next
     * sweep unless somebody reads it. Setting it here would give every write a
     * free pass and turn the policy into "evict whatever was written longest
     * ago", which is not what a cache wants. */
    sa_at_store32_rel(&e->used, 0);

    sa_at_fence_rel();
    sa_at_store32_rel(&e->version, sa_at_load32_acq(&e->version) + 1u);
    sa_at_store32_rel(&e->state, 1);

    sa_at_unlock(h->locks, b);
    return SA_C_OK;
#endif
}

static int sa_cache_remove(sa_cache *c, const char *key, uint32_t klen) {
#if !SA_HAVE_ATOMICS
    (void)c; (void)key; (void)klen;
    return 0;
#else
    uint64_t tag = sa_at_fnv(key, klen);
    uint64_t b   = tag % c->nbuckets;
    uint32_t w;
    int gone = 0;

    if (!klen) return 0;
    if (!sa_at_lock(c->hdr->locks, b)) return 0;

    for (w = 0; w < c->nways; w++) {
        sa_cache_way *e = SA_CWAY_AT(c, b, w);
        if (sa_at_load32_acq(&e->state) != 1) continue;
        if (sa_at_load64_acq(&e->tag) != tag) continue;
        if (sa_at_load32_acq(&e->klen) != klen) continue;
        if (memcmp(e->bytes, key, klen) != 0) continue;
        /* A way, unlike an open-addressed slot, can simply become empty: a
         * bucket is scanned whole, so there is no probe chain to break and no
         * tombstone to leave. */
        sa_at_store32_rel(&e->state, 0);
        sa_at_store32_rel(&e->used, 0);
        sa_at_store64_rel(&e->expires, 0);
        sa_at_fetch_add64(&c->hdr->used, (uint64_t)-1);
        gone = 1;
        break;
    }
    sa_at_unlock(c->hdr->locks, b);
    return gone;
#endif
}

/* Drop everything. */
static void sa_cache_clear(sa_cache *c) {
#if SA_HAVE_ATOMICS
    uint64_t b;
    for (b = 0; b < c->nbuckets; b++) {
        uint32_t w;
        if (!sa_at_lock(c->hdr->locks, b)) continue;
        for (w = 0; w < c->nways; w++) {
            sa_cache_way *e = SA_CWAY_AT(c, b, w);
            sa_at_store32_rel(&e->state, 0);
            sa_at_store32_rel(&e->used, 0);
            sa_at_store64_rel(&e->expires, 0);
        }
        sa_at_store32_rel(&c->hands[b], 0);
        sa_at_unlock(c->hdr->locks, b);
    }
    sa_at_store64_rel(&c->hdr->used, 0);
#else
    (void)c;
#endif
}

/* Live entries that have not expired. Walks everything, so it is a status
 * question rather than one for a request path. */
static uint64_t sa_cache_live(sa_cache *c) {
#if SA_HAVE_ATOMICS
    uint64_t b, n = 0, now = sa_now_ms();
    for (b = 0; b < c->nbuckets; b++) {
        uint32_t w;
        for (w = 0; w < c->nways; w++) {
            sa_cache_way *e = SA_CWAY_AT(c, b, w);
            if (sa_at_load32_acq(&e->state) != 1) continue;
            if (sa_cache_dead(e, now)) continue;
            n++;
        }
    }
    return n;
#else
    (void)c;
    return 0;
#endif
}

#endif /* SA_CACHE_H */
