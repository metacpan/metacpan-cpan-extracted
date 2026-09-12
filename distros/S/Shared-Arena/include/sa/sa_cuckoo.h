#ifndef SA_CUCKOO_H
#define SA_CUCKOO_H

/* sa_cuckoo.h - a set that answers "no" exactly and "yes" probably, and can
 * forget. Perl-free.
 *
 * ---- the question the bloom filter cannot answer ---------------------------
 *
 * A bloom filter never forgets, so a set whose members EXPIRE - nonces inside a
 * replay window, sessions that end, jobs that finish - has to be rotated whole
 * rather than tidied. This one stores a short FINGERPRINT per key in one of two
 * buckets, and a fingerprint that was put somewhere can be taken out again.
 *
 * Each key hashes to a 16-bit fingerprint and a home bucket. Its other bucket
 * is derived from the home and the fingerprint ALONE, which is the part that
 * matters: a fingerprint can be moved to its other bucket without the key, so a
 * full bucket makes room by moving an occupant rather than by refusing.
 *
 * ---- one bucket is one word ------------------------------------------------
 *
 * Four 16-bit fingerprints to a bucket, and a bucket is exactly one 64-bit
 * word. That is most of the concurrency design:
 *
 *   - a check is two atomic loads and no lock;
 *   - an add into a bucket with room is one compare-and-swap, and so is a
 *     remove, so neither takes a lock either;
 *   - two processes writing one bucket lose a CAS and look again, rather than
 *     one of them overwriting the other.
 *
 * The rate follows from the width. An absent key is reported present when one
 * of the eight fingerprints in its two buckets happens to equal its own, so the
 * rate is about 8 * load / 65535: 0.011% at the 90% a filter is sized to reach
 * at its capacity, and it FALLS as keys are removed. It cannot be tuned, and
 * that is the trade - a caller who needs a different rate wants the bloom
 * filter.
 *
 * ---- any number of buckets, not only a power of two -------------------------
 *
 * The usual cuckoo filter finds the other bucket as `i XOR h(fp)`, which only
 * stays in range when the bucket count is a power of two, so a filter sized for
 * a million keys is rounded up to space for two million. Here the other bucket
 * is `(h(fp) - i) mod n`. That is its own inverse - applied twice it gives back
 * `i` - which is the only property the scheme needs, and it works for any n.
 * The home bucket comes from a multiply and a shift rather than a division, so
 * neither costs one.
 *
 * ---- moving keys without losing one -----------------------------------------
 *
 * The textbook insert kicks a victim out, puts the new key in its place, and
 * carries the victim to its other bucket, repeating. For the length of that
 * walk the victim is in NO bucket, and a check arriving then says "no" about a
 * key that was added - the one answer this structure promises never to give.
 * And when the walk runs out of steps, the victim is simply gone.
 *
 * So a relocation is PLANNED FIRST and moved LAST-FIRST. A breadth-first search
 * reads the table without changing it and finds a chain of occupants ending at
 * an empty slot. The chain is then walked back from the empty end: the last
 * occupant moves into the empty slot, which frees the slot the one before it
 * needs, and so on to the front, where the new key goes in. Every step is COPY,
 * THEN DELETE - a fingerprint is written into its new bucket before it is taken
 * out of its old one - so at every instant each key is in at least one of its
 * buckets. A search that finds no chain refuses the add, and nothing already
 * stored has moved.
 *
 * Every step is also a CAS, so a writer that changed the table since the plan
 * was read makes a step fail rather than be overwritten, and the plan is made
 * again.
 *
 * ---- the one read that copy-then-delete does not protect -------------------
 *
 * A check reads its two buckets one after the other. If a fingerprint moves
 * from the second to the first IN BETWEEN - written into the first after the
 * check read it, taken out of the second before the check reads that - the
 * check saw it in neither.
 *
 * `moves` closes it. A relocation bumps it between the copy and the delete of
 * every step, and a check that found nothing compares it before and after:
 * unchanged means no move overlapped the two reads, so the miss is exact.
 * Changed means look again. A check that keeps losing that race gives up and
 * says "probably" - which is always an allowed answer, so a "no" stays exact
 * even then. `moves` is never reset, because a counter that went back to a
 * value a reader had already seen would tell it nothing had happened.
 *
 * Only a MISS pays for the comparison. A hit is right whatever moved.
 *
 * ---- one relocator at a time, and a dead one does not count -----------------
 *
 * Relocations are serialised by one lock per filter, because two plans walking
 * through the same buckets mostly defeat each other. They only happen when both
 * of a key's buckets are full, so the lock is uncontended until the filter is
 * nearly full.
 *
 * THE LOCK IS FOR PROGRESS, NOT FOR SAFETY. Every step is a CAS against what
 * is actually there and keeps each key in at least one bucket, so two
 * relocators running at once cannot lose a key between them.
 *
 * It is a WORD HOLDING THE OWNER'S PID rather than a stripe byte, because a
 * process killed holding a stripe byte holds it for ever, and this is the only
 * lock for the whole filter: one SIGKILL at the wrong moment would refuse every
 * later add that needs room made. A waiter that has spun its budget asks
 * whether the owner is still running, and takes the lock over if it is not.
 * The worst a dead relocator leaves behind is one fingerprint copied into its
 * new bucket and not yet deleted from its old one - a key stored twice, which
 * reads as present, which it is.
 *
 * Needs sa_arena.h and sa_peer.h.
 */

#include "sa/sa_arena.h"
#include "sa/sa_peer.h"

#define SA_CUCKOO_MAGIC 0x4B435543u  /* 'C','U','C','K' little-endian */

#define SA_CK_LANES         4        /* fingerprints to a bucket, and a word   */
#define SA_CK_FILL_PCT      90       /* how full `capacity` keys make it       */
#define SA_CK_MIN_BUCKETS   64
#define SA_CK_MAX_BUCKETS   ((uint64_t)1 << 32)  /* the multiply-shift's range */
#define SA_CK_BFS_MAX       512      /* buckets one plan may read              */
#define SA_CK_CHAIN_MAX     16       /* steps one plan may take                */
#define SA_CK_PLANS         8        /* plans before an add is refused         */
#define SA_CK_RETRIES       16       /* looks before a check says "probably"   */
#define SA_CK_LOCK_SPIN     2000
#define SA_CK_LOCK_ROUNDS   64
#define SA_CK_LOCK_STALL_US 50

typedef struct {
    volatile uint32_t magic;      /* published LAST at init                  */
    uint32_t          lanes;      /* SA_CK_LANES, so a later build cannot
                                   * misread one made by this one            */
    /* A test hook, and a FIELD rather than an #ifdef for the reason the
     * region's is: a forked child has to honour it. Zero unless a test sets
     * it. See sa_cuckoo_check for what it widens and why that has to be. */
    volatile uint32_t stall_us;
    uint32_t          spare;
    uint64_t          buckets;    /* any count, not only a power of two      */
    uint64_t          words_off;  /* from the FILTER's base                  */
    uint64_t          capacity;   /* the n it was sized for                  */
    volatile uint64_t count;      /* fingerprints stored                     */
    volatile uint64_t moves;      /* relocation steps ever taken; NEVER reset */
    volatile uint64_t kicks;      /* adds that needed room made              */
    volatile uint64_t full;       /* adds refused                            */
    volatile uint64_t owner;      /* pid holding the relocation lock, or 0   */
    volatile uint64_t recovered;  /* locks taken over from a dead owner      */
    volatile unsigned char locks[SA_LOCK_STRIPES];
} sa_cuckoo_hdr;

#ifndef SA_CUCKOO_FWD
#define SA_CUCKOO_FWD
typedef struct sa_cuckoo sa_cuckoo;
#endif

struct sa_cuckoo {
    sa_region         *arena;
    sa_cuckoo_hdr     *hdr;
    volatile uint64_t *words;
    uint64_t           buckets;
};

/* Where a key lives: its fingerprint and both of its buckets. */
typedef struct {
    uint64_t i1;
    uint64_t i2;
    uint16_t fp;
} sa_ck_key;

/* Enough buckets that `capacity` keys fill SA_CK_FILL_PCT of the slots. Past
 * that there is still room - a cuckoo filter of four-slot buckets reaches about
 * 95% before the search starts failing - but it is room the caller did not ask
 * for, and the rate quoted for a filter is the rate at its capacity. */
static uint64_t sa_cuckoo_buckets(uint64_t capacity) {
    uint64_t per = (uint64_t)SA_CK_LANES * SA_CK_FILL_PCT;
    uint64_t b;
    if (capacity < 1) capacity = 1;
    if (capacity > SA_CK_MAX_BUCKETS * 3u) capacity = SA_CK_MAX_BUCKETS * 3u;
    b = (capacity * 100u + per - 1u) / per;
    if (b < SA_CK_MIN_BUCKETS) b = SA_CK_MIN_BUCKETS;
    if (b > SA_CK_MAX_BUCKETS) b = SA_CK_MAX_BUCKETS;
    return b;
}

static uint64_t sa_cuckoo_bytes(uint64_t buckets) {
    return sa_align_up((uint64_t)sizeof(sa_cuckoo_hdr)) + buckets * 8u;
}

/* The finalising mix, applied to the key's hash so the fingerprint and the
 * bucket come from well-mixed bits, and to the fingerprint to find the other
 * bucket. */
static uint64_t sa_ck_mix(uint64_t h) {
    h ^= h >> 33;
    h *= 0xff51afd7ed558ccdULL;
    h ^= h >> 33;
    h *= 0xc4ceb9fe1a85ec53ULL;
    h ^= h >> 33;
    return h;
}

/* The top 32 bits of h, scaled into [0, n). A multiply and a shift, and exact
 * for any n up to 2^32. */
static uint64_t sa_ck_range(uint64_t h, uint64_t n) {
    return ((h >> 32) * n) >> 32;
}

/* The other bucket. Depends on the bucket and the fingerprint and nothing
 * else, which is what lets a fingerprint move without its key. */
static uint64_t sa_ck_alt(uint64_t i, uint16_t fp, uint64_t n) {
    uint64_t h = sa_ck_range(sa_ck_mix((uint64_t)fp), n);
    return h >= i ? h - i : h + n - i;
}

/* Zero is an empty lane, so no fingerprint may be zero. */
static void sa_ck_hash(const sa_cuckoo *c, const char *key, uint32_t klen,
                       sa_ck_key *k)
{
    uint64_t h = sa_ck_mix(sa_at_fnv(key, (size_t)klen));
    k->fp = (uint16_t)(h & 0xFFFFu);
    if (!k->fp) k->fp = 1;
    k->i1 = sa_ck_range(h, c->buckets);
    k->i2 = sa_ck_alt(k->i1, k->fp, c->buckets);
}

#define SA_CK_LANE(w, l) ((uint16_t)(((w) >> ((l) * 16)) & 0xFFFFu))

static int sa_ck_has(uint64_t w, uint16_t fp) {
    return SA_CK_LANE(w, 0) == fp || SA_CK_LANE(w, 1) == fp
        || SA_CK_LANE(w, 2) == fp || SA_CK_LANE(w, 3) == fp;
}

static sa_cuckoo *sa_cuckoo_bind(sa_region *arena, sa_reg *e,
                                 uint64_t buckets, uint64_t capacity, int *err)
{
#if !SA_HAVE_ATOMICS
    (void)arena; (void)e; (void)buckets; (void)capacity;
    if (err) *err = SA_E_NOATOMICS;
    return NULL;
#else
    sa_cuckoo *c;
    sa_cuckoo_hdr *h;
    uint64_t hash;

    if (err) *err = SA_E_OK;
    if (!arena || !e) { if (err) *err = SA_E_NOENT; return NULL; }

    h = (sa_cuckoo_hdr *)sa_ptr_len(arena, e->off, sizeof(sa_cuckoo_hdr));
    if (!h) { if (err) *err = SA_E_NOENT; return NULL; }

    if (sa_at_load32_acq(&h->magic) != SA_CUCKOO_MAGIC) {
        hash = sa_at_fnv(e->name, strlen(e->name));
        if (sa_at_lock(h->locks, hash)) {
            if (sa_at_load32_acq(&h->magic) != SA_CUCKOO_MAGIC) {
                if (!buckets || sa_cuckoo_bytes(buckets) > e->len) {
                    sa_at_unlock(h->locks, hash);
                    if (err) *err = SA_E_FULL;
                    return NULL;
                }
                memset((void *)h, 0, (size_t)sa_cuckoo_bytes(buckets));
                h->lanes     = SA_CK_LANES;
                h->buckets   = buckets;
                h->words_off = sa_align_up((uint64_t)sizeof(sa_cuckoo_hdr));
                h->capacity  = capacity;
                sa_at_store32_rel(&h->magic, SA_CUCKOO_MAGIC);
            }
            sa_at_unlock(h->locks, hash);
        }
        if (!sa_wait_magic32(&h->magic, SA_CUCKOO_MAGIC)) {
            if (err) *err = SA_E_MAGIC;
            return NULL;
        }
    }

    /* THE GEOMETRY IN THE HEADER IS ALSO SOMEBODY ELSE'S NUMBER.
     *
     * A process that finds the magic already set reads the shape out of the
     * shared header, and a header claiming more buckets than the entry holds
     * would put every later read past the end of the mapping. So the shape is
     * checked against the entry's length whoever initialised it, and against
     * what this caller asked for. */
    if (h->lanes != SA_CK_LANES || !h->buckets
        || h->buckets > SA_CK_MAX_BUCKETS
        || h->words_off != sa_align_up((uint64_t)sizeof(sa_cuckoo_hdr))
        || sa_cuckoo_bytes(h->buckets) > e->len
        || (buckets && h->buckets != buckets)) {
        if (err) *err = SA_E_SHAPE;
        return NULL;
    }

    c = (sa_cuckoo *)calloc(1, sizeof(sa_cuckoo));
    if (!c) { if (err) *err = SA_E_NOMEM; return NULL; }
    c->arena   = arena;
    c->hdr     = h;
    c->words   = (volatile uint64_t *)((char *)h + (size_t)h->words_off);
    c->buckets = h->buckets;
    return c;
#endif
}

static void sa_cuckoo_free(sa_cuckoo *c) { free(c); }

#if SA_HAVE_ATOMICS

/* Put one copy of fp into any empty lane. 1 if it went in, 0 if the bucket is
 * full. A lost CAS means another writer changed some lane of this word, so it
 * is read again rather than given up on - bounded, like every wait here. */
static int sa_ck_put(volatile uint64_t *word, uint16_t fp) {
    long spin;
    for (spin = 0; spin < SA_SPIN_MAX; spin++) {
        uint64_t w = sa_at_load64_acq(word);
        int l;
        for (l = 0; l < SA_CK_LANES; l++)
            if (!SA_CK_LANE(w, l)) break;
        if (l == SA_CK_LANES) return 0;
        if (sa_at_cas64(word, w, w | ((uint64_t)fp << (l * 16)))) return 1;
    }
    return 0;
}

/* Take one copy of fp out of whichever lane holds it. Copies of one
 * fingerprint in one bucket are interchangeable - same fingerprint, same
 * bucket, so the same other bucket - which is why any lane will do. */
static int sa_ck_take(volatile uint64_t *word, uint16_t fp) {
    long spin;
    for (spin = 0; spin < SA_SPIN_MAX; spin++) {
        uint64_t w = sa_at_load64_acq(word);
        int l;
        for (l = 0; l < SA_CK_LANES; l++)
            if (SA_CK_LANE(w, l) == fp) break;
        if (l == SA_CK_LANES) return 0;
        if (sa_at_cas64(word, w, w & ~((uint64_t)0xFFFFu << (l * 16))))
            return 1;
    }
    return 0;
}

/* Down by one, and never below zero. The count can only be driven below the
 * table's real contents by a reset racing a writer, and a count that wrapped
 * to eighteen quintillion would say so less usefully than one that stuck. */
static void sa_ck_count_down(sa_cuckoo *c) {
    long spin;
    for (spin = 0; spin < SA_SPIN_MAX; spin++) {
        uint64_t v = sa_at_load64_acq(&c->hdr->count);
        if (!v || sa_at_cas64(&c->hdr->count, v, v - 1)) return;
    }
}

/* The relocation lock: 1 if taken, 0 if it gave up. Spins, then sleeps, so a
 * holder that lost its CPU gets it back and hands over rather than every
 * waiter burning its budget while it is not scheduled. Between rounds, asks
 * whether the holder is still alive, and takes over from one that is not. */
static int sa_ck_lock(sa_cuckoo *c) {
    volatile uint64_t *o = &c->hdr->owner;
    uint64_t me = sa_getpid();
    int round;
    for (round = 0; round < SA_CK_LOCK_ROUNDS; round++) {
        uint64_t cur;
        long spin;
        for (spin = 0; spin < SA_CK_LOCK_SPIN; spin++)
            if (sa_at_load64_acq(o) == 0 && sa_at_cas64(o, 0, me)) return 1;
        /* The holder's pid is compared with our own first: another thread of
         * this process is alive by definition, and asking the kernel would
         * only say so. */
        cur = sa_at_load64_acq(o);
        if (cur && cur != me && !sa_pid_alive(cur) && sa_at_cas64(o, cur, me)) {
            sa_at_fetch_add64(&c->hdr->recovered, 1);
            return 1;
        }
        sa_stall(SA_CK_LOCK_STALL_US);
    }
    return 0;
}

/* A CAS rather than a store: a lock that was taken over from this process in
 * error - a pid another namespace cannot see, say - is somebody else's now,
 * and clearing it would free it under them. */
static void sa_ck_unlock(sa_cuckoo *c) {
    (void)sa_at_cas64(&c->hdr->owner, sa_getpid(), 0);
}

/* One node of a plan: a bucket, the node it was reached from, and the
 * fingerprint that would move from that node's bucket into this one. */
typedef struct {
    uint64_t bucket;
    int      parent;     /* -1 for one of the new key's own two buckets */
    uint16_t fp;
} sa_ck_node;

/* Does the chain ending at node n visit any bucket twice? A chain that does
 * would move a fingerprint into a slot another of its own steps is about to
 * refill, so it is not used. */
static int sa_ck_chain_ok(const sa_ck_node *q, int n) {
    uint64_t seen[SA_CK_CHAIN_MAX];
    int len = 0, i;
    for (; n >= 0; n = q[n].parent) {
        if (len == SA_CK_CHAIN_MAX) return 0;
        for (i = 0; i < len; i++)
            if (seen[i] == q[n].bucket) return 0;
        seen[len++] = q[n].bucket;
    }
    return 1;
}

/* Breadth first from the new key's two buckets, reading and never writing, to
 * the nearest bucket with an empty lane. Returns that node, or -1 when there is
 * none within SA_CK_BFS_MAX buckets - which is what "full" means here. */
static int sa_ck_plan(sa_cuckoo *c, const sa_ck_key *k, sa_ck_node *q) {
    int head, tail = 0;

    q[tail].bucket = k->i1; q[tail].parent = -1; q[tail].fp = 0; tail++;
    if (k->i2 != k->i1) {
        q[tail].bucket = k->i2; q[tail].parent = -1; q[tail].fp = 0; tail++;
    }

    for (head = 0; head < tail; head++) {
        uint64_t w = sa_at_load64_acq(&c->words[q[head].bucket]);
        int l, j;

        for (l = 0; l < SA_CK_LANES; l++)
            if (!SA_CK_LANE(w, l)) break;
        if (l < SA_CK_LANES) {
            if (sa_ck_chain_ok(q, head)) return head;
            continue;
        }

        for (l = 0; l < SA_CK_LANES && tail < SA_CK_BFS_MAX; l++) {
            uint16_t v = SA_CK_LANE(w, l);
            /* Two copies of one fingerprint go to the same place, so the
             * second would only spend the budget reading it again. */
            for (j = 0; j < l; j++)
                if (SA_CK_LANE(w, j) == v) break;
            if (j < l) continue;
            q[tail].bucket = sa_ck_alt(q[head].bucket, v, c->buckets);
            q[tail].parent = head;
            q[tail].fp     = v;
            tail++;
        }
    }
    return -1;
}

/* Walk the chain back from its empty end. Each step is copy, count, delete:
 * the fingerprint is written into its new bucket before it leaves its old one,
 * and `moves` is bumped between the two, which is what a check that misses
 * compares. 1 if the new key went in at the front. */
static int sa_ck_walk(sa_cuckoo *c, const sa_ck_node *q, int n, uint16_t fp) {
    while (q[n].parent >= 0) {
        uint64_t to   = q[n].bucket;
        uint64_t from = q[q[n].parent].bucket;
        /* Filled since the plan was read: stop, and plan again. What has
         * already moved is in its other bucket, which is a valid place. */
        if (!sa_ck_put(&c->words[to], q[n].fp)) return 0;
        sa_at_fetch_add64(&c->hdr->moves, 1);
        /* Gone from its old bucket means somebody removed it while it was in
         * both, so there is now one copy too many - and the one to give back
         * is the one just made. The step after this one finds the room the
         * remover left, or fails and plans again. */
        if (!sa_ck_take(&c->words[from], q[n].fp))
            (void)sa_ck_take(&c->words[to], q[n].fp);
        n = q[n].parent;
    }
    return sa_ck_put(&c->words[q[n].bucket], fp);
}

/* Under the lock. 2 when room had appeared by the time the lock was ours, 1
 * when keys were moved to make it, 0 when there is none to be made. */
static int sa_ck_relocate(sa_cuckoo *c, const sa_ck_key *k) {
    sa_ck_node q[SA_CK_BFS_MAX];
    int plan;
    for (plan = 0; plan < SA_CK_PLANS; plan++) {
        int n;
        if (sa_ck_put(&c->words[k->i1], k->fp)
            || sa_ck_put(&c->words[k->i2], k->fp))
            return 2;
        n = sa_ck_plan(c, k, q);
        if (n < 0) return 0;
        if (sa_ck_walk(c, q, n, k->fp)) return 1;
    }
    return 0;
}

#endif /* SA_HAVE_ATOMICS */

/* Add a key: 1 when it is stored, 0 when there is no room for it. A refusal
 * moves nothing, so every key stored before it is still exactly where a check
 * will find it.
 *
 * EVERY CALL STORES A COPY. A key added twice is in the filter twice and needs
 * removing twice, and one key can be added at most eight times - its two
 * buckets, four lanes each - because every copy of it has to live in one of
 * the same two. */
static int sa_cuckoo_add(sa_cuckoo *c, const char *key, uint32_t klen) {
#if !SA_HAVE_ATOMICS
    (void)c; (void)key; (void)klen;
    return 0;
#else
    sa_ck_key k;
    int rc = 0;

    if (!c) return 0;
    sa_ck_hash(c, key, klen, &k);

    if (sa_ck_put(&c->words[k.i1], k.fp) || sa_ck_put(&c->words[k.i2], k.fp)) {
        sa_at_fetch_add64(&c->hdr->count, 1);
        return 1;
    }

    if (sa_ck_lock(c)) {
        rc = sa_ck_relocate(c, &k);
        sa_ck_unlock(c);
    }
    if (!rc) {
        sa_at_fetch_add64(&c->hdr->full, 1);
        return 0;
    }
    if (rc == 1) sa_at_fetch_add64(&c->hdr->kicks, 1);
    sa_at_fetch_add64(&c->hdr->count, 1);
    return 1;
#endif
}

/* Has this key probably been added? A 0 is exact; a 1 may be a coincidence of
 * fingerprints, and is also the answer when this could not be sure - see
 * `moves` above. */
static int sa_cuckoo_check(sa_cuckoo *c, const char *key, uint32_t klen) {
#if !SA_HAVE_ATOMICS
    (void)c; (void)key; (void)klen;
    return 0;
#else
    sa_ck_key k;
    int t;

    if (!c) return 0;
    sa_ck_hash(c, key, klen, &k);

    for (t = 0; t < SA_CK_RETRIES; t++) {
        uint64_t m = sa_at_load64_acq(&c->hdr->moves);
        if (sa_ck_has(sa_at_load64_acq(&c->words[k.i1]), k.fp)) return 1;
        /* THE WINDOW, held open when a test asks. Unwidened it is a few
         * instructions, and a stress test that races it passes whether or not
         * the comparison below exists: with it removed, 70,000 relocations
         * under two readers produced no miss at all. A test that cannot fail
         * is not evidence, so t/32-cuckoo.t stalls here and relocates
         * underneath. One load of a header line this already read, and only
         * on a miss in the first bucket. */
        if (c->hdr->stall_us) sa_stall(c->hdr->stall_us);
        if (sa_ck_has(sa_at_load64_acq(&c->words[k.i2]), k.fp)) return 1;
        /* Acquire loads, so this one cannot be satisfied before the two
         * above were. */
        if (sa_at_load64_acq(&c->hdr->moves) == m) return 0;
    }
    return 1;
#endif
}

/* Remove one copy of a key: 1 when one was found and taken, 0 when none was.
 *
 * ONLY REMOVE WHAT WAS ADDED. A key never added may share its fingerprint and
 * a bucket with one that was, and removing it takes THAT key's copy - turning
 * a key that was added into one a check says "no" about. */
static int sa_cuckoo_remove(sa_cuckoo *c, const char *key, uint32_t klen) {
#if !SA_HAVE_ATOMICS
    (void)c; (void)key; (void)klen;
    return 0;
#else
    sa_ck_key k;
    int t, got = 0;

    if (!c) return 0;
    sa_ck_hash(c, key, klen, &k);

    /* The same race a check has, and the same counter: a miss is only a miss
     * if nothing moved while both buckets were being looked at. */
    for (t = 0; t < SA_CK_RETRIES && !got; t++) {
        uint64_t m = sa_at_load64_acq(&c->hdr->moves);
        if (sa_ck_take(&c->words[k.i1], k.fp)
            || sa_ck_take(&c->words[k.i2], k.fp))
            got = 1;
        else if (sa_at_load64_acq(&c->hdr->moves) == m)
            return 0;
    }

    /* Every look overlapped a move. A check can answer "probably" at this
     * point; a remove cannot answer anything but the truth, so it stops the
     * moves and looks once more. */
    if (!got) {
        if (!sa_ck_lock(c)) return 0;
        got = sa_ck_take(&c->words[k.i1], k.fp)
           || sa_ck_take(&c->words[k.i2], k.fp);
        sa_ck_unlock(c);
        if (!got) return 0;
    }

    sa_ck_count_down(c);
    return 1;
#endif
}

/* Forget everything.
 *
 * Under the relocation lock, so no plan is half walked through it. Adds and
 * removes do not take that lock, so one racing the reset may land either side
 * of it, and the count can end up describing the other side. `moves` is left
 * alone - see the note above on why it only ever goes up. */
static void sa_cuckoo_reset(sa_cuckoo *c) {
#if SA_HAVE_ATOMICS
    uint64_t i;
    if (!c || !sa_ck_lock(c)) return;
    for (i = 0; i < c->buckets; i++) sa_at_store64_rel(&c->words[i], 0);
    sa_at_store64_rel(&c->hdr->count, 0);
    sa_at_store64_rel(&c->hdr->kicks, 0);
    sa_at_store64_rel(&c->hdr->full, 0);
    sa_ck_unlock(c);
#else
    (void)c;
#endif
}

#endif /* SA_CUCKOO_H */
