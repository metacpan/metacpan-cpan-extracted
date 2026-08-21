/* punk_cache.h - the in-memory cache store, bounded by BYTES.
 *
 * WHY BYTES AND NOT ENTRIES.
 *
 * The obvious LRU caps the number of entries, and LRU::Cache in this
 * workspace is exactly that: XS, O(1), and excellent. But a thousand entries
 * of ten megabytes is ten gigabytes, so an entry cap does not bound the thing
 * that runs out. A cache that promises a bound has to bound memory.
 *
 * The second reason this matters is less obvious and worse: a per-worker
 * cache is multiplied by the pool. Under `workers => 8` a 500MB cap is 4GB of
 * RSS, and every worker caches the same things separately. That is why the
 * FILE backend is Punk::Cache's default and this one is the opt-in - see
 * Punk::Cache's documentation, which spells the arithmetic out.
 *
 * THE SHAPE.
 *
 * A hash table for lookup and an intrusive doubly-linked list for recency:
 * O(1) get, O(1) set, O(1) eviction. Chained buckets rather than open
 * addressing, because deletion is a normal operation here (delete, expiry,
 * eviction) and tombstones in an open table are a slow leak.
 *
 * `bytes` is maintained INCREMENTALLY on every insert, overwrite, delete and
 * eviction. Recomputing it would make set O(n), and a budget checked
 * occasionally is not a budget. The case that gets missed is the overwrite: a
 * key replaced from 1KB by 1MB must move the total by the difference, or a
 * bounded cache quietly stops being bounded.
 *
 * Expiry is LAZY - noticed on read. A sweep on the request path is a stall
 * that grows with the cache.
 */

#ifndef PUNK_CACHE_H
#define PUNK_CACHE_H

#include <string.h>
#include <stdint.h>
#include <sys/time.h>      /* gettimeofday - expiry needs sub-second */

#define PC_BUCKETS_MIN   64
#define PC_LOAD_NUM       3        /* grow at 3/4 load */
#define PC_LOAD_DEN       4

typedef struct pc_entry {
    struct pc_entry *hnext;        /* bucket chain */
    struct pc_entry *prev, *next;  /* recency list; head is newest */
    uint64_t  hash;
    double    expiry;              /* epoch seconds; 0 = never */
    uint32_t  klen;
    uint32_t  vlen;
    char     *key;
    char     *val;
} pc_entry;

typedef struct {
    pc_entry **buckets;
    uint32_t   nbuckets;
    uint32_t   entries;

    pc_entry  *head, *tail;        /* newest .. oldest */

    size_t     bytes;              /* held, incrementally maintained */
    size_t     max_bytes;

    /* cumulative, and reset in a forked child - see punk_cache_check_fork */
    uint64_t   hits, misses, evictions, refused, expired;

    IV         owner_pid;
} punk_cache;

/* The per-entry overhead counted against the budget.
 *
 * Counting only the value would let a million one-byte keys sit under a
 * "1MB" cap while costing tens of megabytes of structs and allocator
 * headers - the budget would be honest about the payload and useless about
 * the memory, which is the failure this whole store exists to avoid. */
#define PC_ENTRY_OVERHEAD (sizeof(pc_entry) + 32)

static size_t pc_entry_cost(uint32_t klen, uint32_t vlen) {
    return PC_ENTRY_OVERHEAD + (size_t)klen + (size_t)vlen;
}

/* Wall clock, for expiry.
 *
 * The WALL clock and not a monotonic one, deliberately: a TTL is a promise
 * about calendar time ("this is good for five minutes"), and it has to survive
 * being written by one process and read by another - which a monotonic clock,
 * whose zero is arbitrary per boot, cannot do. The cost is that a large clock
 * step expires things early or late, and for a cache that is a miss rather
 * than a fault.
 *
 * Sub-second, because a one-second TTL rounded to whole seconds is either
 * zero or two. */
static double pc_now(pTHX) {
    struct timeval tv;
    PERL_UNUSED_CONTEXT;
    gettimeofday(&tv, NULL);
    return (double)tv.tv_sec + (double)tv.tv_usec / 1e6;
}

/* ---- the recency list ---------------------------------------------------- */

static void pc_unlink(punk_cache *c, pc_entry *e) {
    if (e->prev) e->prev->next = e->next; else c->head = e->next;
    if (e->next) e->next->prev = e->prev; else c->tail = e->prev;
    e->prev = e->next = NULL;
}

static void pc_push_front(punk_cache *c, pc_entry *e) {
    e->prev = NULL;
    e->next = c->head;
    if (c->head) c->head->prev = e;
    c->head = e;
    if (!c->tail) c->tail = e;
}

static void pc_touch(punk_cache *c, pc_entry *e) {
    if (c->head == e) return;
    pc_unlink(c, e);
    pc_push_front(c, e);
}

/* ---- the table ----------------------------------------------------------- */

/* FNV-1a 64.
 *
 * Punk's own, not Hyperman's. hm_atomic.h has the same four lines, but it is
 * INTERNAL to Hyperman - only hm_abi.h is published through EU::Depends - and
 * reaching into another dist's private header is precisely the coupling the
 * ABI pattern exists to prevent. Four lines is a cheaper price than a
 * dependency on somebody else's internals.
 *
 * Not cryptographic and not meant to be: it indexes a bucket, and the file
 * backend compares the stored key on read so a collision is a miss rather
 * than a wrong answer. */
static uint64_t pc_hash(const char *k, size_t n) {
    const unsigned char *p = (const unsigned char *)k;
    uint64_t h = 1469598103934665603ULL;
    size_t i;
    for (i = 0; i < n; i++) { h ^= p[i]; h *= 1099511628211ULL; }
    return h;
}

static void pc_table_alloc(pTHX_ punk_cache *c, uint32_t n) {
    Newxz(c->buckets, n, pc_entry *);
    c->nbuckets = n;
}

static void pc_rehash(pTHX_ punk_cache *c) {
    uint32_t old_n = c->nbuckets, i, n = old_n ? old_n * 2 : PC_BUCKETS_MIN;
    pc_entry **old = c->buckets;
    pc_table_alloc(aTHX_ c, n);
    for (i = 0; i < old_n; i++) {
        pc_entry *e = old[i];
        while (e) {
            pc_entry *nx = e->hnext;
            uint32_t b = (uint32_t)(e->hash % n);
            e->hnext = c->buckets[b];
            c->buckets[b] = e;
            e = nx;
        }
    }
    if (old) Safefree(old);
}

static pc_entry *pc_find(punk_cache *c, const char *k, uint32_t klen,
                         uint64_t h, pc_entry ***slot) {
    uint32_t b = (uint32_t)(h % c->nbuckets);
    pc_entry **pp = &c->buckets[b], *e;
    for (e = *pp; e; pp = &e->hnext, e = e->hnext) {
        if (e->hash == h && e->klen == klen && !memcmp(e->key, k, klen)) {
            if (slot) *slot = pp;
            return e;
        }
    }
    if (slot) *slot = pp;
    return NULL;
}

static void pc_free_entry(pTHX_ punk_cache *c, pc_entry *e) {
    c->bytes -= pc_entry_cost(e->klen, e->vlen);
    c->entries--;
    Safefree(e->key);
    Safefree(e->val);
    Safefree(e);
}

/* Remove an entry that is known to be in the table. */
static void pc_remove(pTHX_ punk_cache *c, pc_entry *e) {
    pc_entry **pp;
    (void)pc_find(c, e->key, e->klen, e->hash, &pp);
    if (*pp == e) *pp = e->hnext;
    pc_unlink(c, e);
    pc_free_entry(aTHX_ c, e);
}

/* ---- lifecycle ----------------------------------------------------------- */

static punk_cache *punk_cache_new(pTHX_ size_t max_bytes) {
    punk_cache *c;
    Newxz(c, 1, punk_cache);
    c->max_bytes = max_bytes;
    c->owner_pid = (IV)PerlProc_getpid();
    pc_table_alloc(aTHX_ c, PC_BUCKETS_MIN);
    return c;
}

static void punk_cache_clear(pTHX_ punk_cache *c) {
    pc_entry *e = c->head;
    while (e) {
        pc_entry *nx = e->next;
        Safefree(e->key);
        Safefree(e->val);
        Safefree(e);
        e = nx;
    }
    c->head = c->tail = NULL;
    c->entries = 0;
    c->bytes = 0;
    if (c->buckets) Zero(c->buckets, c->nbuckets, pc_entry *);
}

static void punk_cache_free(pTHX_ punk_cache *c) {
    if (!c) return;
    punk_cache_clear(aTHX_ c);
    if (c->buckets) Safefree(c->buckets);
    Safefree(c);
}

/* A worker inherits the parent's entries across a fork, and that is fine -
 * they are still correct, and re-reading them costs nothing.
 *
 * The STATISTICS are not fine. A child reporting the parent's hit count is
 * reporting a number about a process that is not this one, and an operator
 * cannot act on it. Same discipline as otel_tracer.h's owner_pid check, for
 * the same reason: a statistic that silently belongs to someone else is worse
 * than no statistic. */
static void punk_cache_check_fork(pTHX_ punk_cache *c) {
    IV me = (IV)PerlProc_getpid();
    if (c->owner_pid == me) return;
    c->hits = c->misses = c->evictions = c->refused = c->expired = 0;
    c->owner_pid = me;
}

/* ---- get / set / delete -------------------------------------------------- */

/* The value, or NULL for absent OR expired - a caller does not need to know
 * which, and a store that distinguished them would leak its expiry policy
 * into every call site. */
static const char *punk_cache_get(pTHX_ punk_cache *c, const char *k,
                                  uint32_t klen, double now, uint32_t *vlen) {
    uint64_t h = pc_hash(k, klen);
    pc_entry *e;

    punk_cache_check_fork(aTHX_ c);
    e = pc_find(c, k, klen, h, NULL);
    if (!e) { c->misses++; return NULL; }

    if (e->expiry && e->expiry <= now) {
        pc_remove(aTHX_ c, e);       /* lazy expiry: noticed on the read */
        c->expired++;
        c->misses++;
        return NULL;
    }

    pc_touch(c, e);
    c->hits++;
    *vlen = e->vlen;
    return e->val;
}

/* Evict from the tail until the budget is met. O(1) per eviction. */
static void pc_make_room(pTHX_ punk_cache *c, size_t need) {
    while (c->tail && c->bytes + need > c->max_bytes) {
        pc_remove(aTHX_ c, c->tail);
        c->evictions++;
    }
}

/* Returns 1 stored, 0 refused.
 *
 * A value that cannot fit the budget even in an empty cache is REFUSED, not
 * stored: making room for it would evict everything else first and then still
 * be over. Counted, because silently dropping a write is the sort of thing
 * that is only ever discovered from the outside. */
static int punk_cache_set(pTHX_ punk_cache *c, const char *k, uint32_t klen,
                          const char *v, uint32_t vlen, double expiry) {
    uint64_t h = pc_hash(k, klen);
    size_t cost = pc_entry_cost(klen, vlen);
    pc_entry *e;

    punk_cache_check_fork(aTHX_ c);
    if (cost > c->max_bytes) { c->refused++; return 0; }

    e = pc_find(c, k, klen, h, NULL);
    if (e) {
        /* OVERWRITE. The total moves by the DIFFERENCE - the case that gets
         * missed, and the one that turns a bounded cache into an unbounded
         * one when a key is replaced by something much larger. */
        /* Always allocate, even for a zero-length value. NULL is how this
         * store spells ABSENT, so an empty value that allocated nothing would
         * be indistinguishable from a miss - and an empty string is a value
         * somebody deliberately cached. The length carries the emptiness. */
        char *nv;
        Newx(nv, vlen ? vlen : 1, char);
        if (vlen) Copy(v, nv, vlen, char);
        c->bytes -= pc_entry_cost(e->klen, e->vlen);
        Safefree(e->val);
        e->val    = nv;
        e->vlen   = vlen;
        e->expiry = expiry;
        c->bytes += pc_entry_cost(e->klen, e->vlen);
        pc_touch(c, e);
        pc_make_room(aTHX_ c, 0);
        return 1;
    }

    pc_make_room(aTHX_ c, cost);

    Newxz(e, 1, pc_entry);
    Newx(e->key, klen ? klen : 1, char);
    if (klen) Copy(k, e->key, klen, char);
    Newx(e->val, vlen ? vlen : 1, char);   /* never NULL: NULL means absent */
    if (vlen) Copy(v, e->val, vlen, char);
    e->hash = h; e->klen = klen; e->vlen = vlen; e->expiry = expiry;

    {
        uint32_t b = (uint32_t)(h % c->nbuckets);
        e->hnext = c->buckets[b];
        c->buckets[b] = e;
    }
    pc_push_front(c, e);
    c->entries++;
    c->bytes += cost;

    if (c->entries > c->nbuckets / PC_LOAD_DEN * PC_LOAD_NUM)
        pc_rehash(aTHX_ c);
    return 1;
}

static int punk_cache_delete(pTHX_ punk_cache *c, const char *k,
                             uint32_t klen) {
    uint64_t h = pc_hash(k, klen);
    pc_entry *e;
    punk_cache_check_fork(aTHX_ c);
    e = pc_find(c, k, klen, h, NULL);
    if (!e) return 0;
    pc_remove(aTHX_ c, e);
    return 1;
}

#endif /* PUNK_CACHE_H */
