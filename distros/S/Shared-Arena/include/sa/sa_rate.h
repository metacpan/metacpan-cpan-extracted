#ifndef SA_RATE_H
#define SA_RATE_H

/* sa_rate.h - a token bucket per key, shared by every process. Perl-free.
 *
 * ---- the problem this exists for --------------------------------------------
 *
 * A limit of 100/min enforced in a pre-forked pool is not a limit of 100/min.
 * Each worker keeps its own counter, so the real limit is workers x 100/min,
 * and the number moves when the pool is resized. The sibling implementation in
 * Hyperman says the same thing in its own words, and the dist before that put
 * the counters in a FILE to escape it - which buys correctness back at the
 * price of a syscall on every request.
 *
 * The state belongs in memory every worker already shares. That is this.
 *
 * ---- a token bucket, not a fixed window -------------------------------------
 *
 * A fixed window is the obvious implementation and it has a hole in it: the
 * window boundary. A caller limited to 100 per minute can spend 100 at 11:59:59
 * and 100 more at 12:00:00, which is 200 requests in one second and is exactly
 * what the limit was written to prevent. The bug is invisible in testing
 * because it needs the clock to be in a particular place.
 *
 * A bucket has no boundary to stand on. It holds up to `limit` tokens, refills
 * continuously at `limit` per `window`, and a request takes one. Sustained rate
 * and burst size become two numbers a caller can set independently, which is
 * what a caller actually wants: 100/min with a burst of 100 is a different
 * policy from 100/min with a burst of 10, and a window cannot express either.
 *
 * ---- the whole bucket is ONE WORD, and that is the design -------------------
 *
 * Tokens and the moment they were last refilled are packed into one uint64:
 *
 *     bits 63..32   tokens, in units of 1/1024 of a token
 *     bits 31..0    when they were counted, in milliseconds
 *
 * So a hit is a compare-and-swap, and the limiter needs no lock on its hot
 * path at all. That matters for more than speed. Hyperman's takes a striped
 * spinlock per hit and FAILS OPEN when the spin is exhausted - which means
 * that under exactly the load a rate limiter exists for, it quietly stops
 * limiting. This cannot do that: a CAS either wins or is retried, and the
 * retries are counted rather than being a silent hole.
 *
 * It is also why a crash cannot corrupt it. A process that dies mid-update has
 * either landed its CAS or not; there is no half-written bucket to find,
 * nothing to repair, and no need for the peer table that the ring depends on.
 * Of every structure in this dist, this is the one whose crash story is "there
 * is nothing to say".
 *
 * THE TIMESTAMP WRAPS, deliberately. Thirty-two bits of milliseconds is 49.7
 * days, and the elapsed time is a SIGNED difference, which is correct across a
 * wrap for any interval up to half of that. A key idle for longer than 24.9
 * days measures short and so refills slower than it should, once, for one hit.
 * That is the direction to be wrong in, and the alternative is a wider field
 * that makes every bucket bigger to fix a case that ends in one extra allowed
 * request.
 *
 * Signed, not unsigned, because a caller's clock reading can be BEHIND the
 * timestamp another process already stored, and unsigned subtraction reads
 * that as forty-nine days of refill. See sa_rate_refill.
 *
 * ---- when the table is full --------------------------------------------------
 *
 * Open addressing, and no free list - the arena has no free anywhere and this
 * is not the structure to invent one in. A slot is reclaimable when its bucket
 * is FULL, because a full bucket is indistinguishable from a key that has never
 * been seen: both allow the next `limit` requests. So an idle key's slot is
 * handed to a new key with nothing lost, and the table drains itself with no
 * sweep and no timer.
 *
 * When every slot holds a bucket that is NOT full - the table is genuinely
 * over capacity - a new key takes over its home slot, which resets a live
 * bucket. THAT LEAKS LOOSER, NEVER TIGHTER: the victim gets more requests than
 * it should, never fewer, so an over-full table cannot turn into an outage.
 * Size the table above the peak count of distinct keys in a window, and read
 * `evicted` to find out whether you did.
 *
 * Needs sa_arena.h.
 */

#include "sa/sa_arena.h"

#define SA_RATE_MAGIC 0x45544152u    /* 'R','A','T','E' little-endian */

/* Tokens are integers in units of 1/1024, so a refill of a fraction of a token
 * is not lost to truncation. A limiter of 100/min refills 1.7 tokens a second,
 * which as an integer count of tokens per millisecond is zero. */
#define SA_RATE_SCALE 1024u

/* A hit is a CAS loop. This bounds it, for the same reason every wait in this
 * dist is bounded - but reaching it is not "fail open and say nothing", it is
 * counted in `contended`, because a limiter that has stopped limiting is
 * something an operator has to be able to discover. */
#define SA_RATE_CAS_TRIES 64

/* How far an insert probes before it gives up and takes the home slot. */
#define SA_RATE_PROBE 16

typedef struct {
    volatile uint64_t keyhash;   /* 0 = empty                                */
    volatile uint64_t state;     /* (tokens_u << 32) | last_ms               */
} sa_rate_slot;

typedef struct {
    volatile uint32_t magic;      /* published LAST at init                  */
    uint32_t          pad;
    uint64_t          nslots;     /* a power of two                          */
    uint64_t          slots_off;  /* from the LIMITER's base                 */
    uint64_t          burst_u;    /* the full bucket, in 1/1024 tokens       */
    uint64_t          window_ms;  /* time to refill from empty to full       */
    volatile uint64_t allowed;
    volatile uint64_t denied;
    volatile uint64_t evicted;    /* live buckets taken over: the table is small */
    volatile uint64_t contended;  /* CAS loops that gave up and allowed      */
    volatile unsigned char locks[SA_LOCK_STRIPES];
} sa_rate_hdr;

#ifndef SA_RATE_FWD
#define SA_RATE_FWD
typedef struct sa_rate sa_rate;
#endif

struct sa_rate {
    sa_region     *arena;
    sa_rate_hdr   *hdr;
    sa_rate_slot  *slots;
    uint64_t       nslots;
    uint64_t       mask;
    uint64_t       burst_u;
    uint64_t       window_ms;
};

#define SA_RATE_TOKENS(st) ((uint64_t)((st) >> 32))
#define SA_RATE_WHEN(st)   ((uint32_t)((st) & 0xFFFFFFFFu))
#define SA_RATE_STATE(t, ms) \
    ((((uint64_t)(t)) << 32) | (uint64_t)(uint32_t)(ms))

static uint64_t sa_rate_bytes(uint64_t nslots) {
    return sa_align_up((uint64_t)sizeof(sa_rate_hdr))
         + nslots * (uint64_t)sizeof(sa_rate_slot);
}

/* Round up to a power of two, so the slot index is a mask rather than a
 * division on the hot path. */
static uint64_t sa_rate_pow2(uint64_t n) {
    uint64_t p = 64;
    if (n < 64) return 64;
    while (p < n && p < (uint64_t)1 << 40) p <<= 1;
    return p;
}

/* Milliseconds, in the same 32-bit space the slots store. */
static uint32_t sa_rate_now_ms(void) {
    return (uint32_t)(sa_now_us() / 1000u);
}

static sa_rate *sa_rate_bind(sa_region *arena, sa_reg *e, uint64_t nslots,
                             uint64_t burst_u, uint64_t window_ms, int *err)
{
#if !SA_HAVE_ATOMICS
    (void)arena; (void)e; (void)nslots; (void)burst_u; (void)window_ms;
    if (err) *err = SA_E_NOATOMICS;
    return NULL;
#else
    sa_rate *r;
    sa_rate_hdr *h;
    uint64_t hash;

    if (err) *err = SA_E_OK;
    if (!arena || !e) { if (err) *err = SA_E_NOENT; return NULL; }

    h = (sa_rate_hdr *)sa_ptr_len(arena, e->off, sizeof(sa_rate_hdr));
    if (!h) { if (err) *err = SA_E_NOENT; return NULL; }

    if (sa_at_load32_acq(&h->magic) != SA_RATE_MAGIC) {
        hash = sa_at_fnv(e->name, strlen(e->name));
        if (sa_at_lock(h->locks, hash)) {
            if (sa_at_load32_acq(&h->magic) != SA_RATE_MAGIC) {
                if (!nslots || !burst_u || !window_ms
                    || sa_rate_bytes(nslots) > e->len) {
                    sa_at_unlock(h->locks, hash);
                    if (err) *err = SA_E_FULL;
                    return NULL;
                }
                memset((void *)h, 0, (size_t)sa_rate_bytes(nslots));
                h->nslots    = nslots;
                h->slots_off = sa_align_up((uint64_t)sizeof(sa_rate_hdr));
                h->burst_u   = burst_u;
                h->window_ms = window_ms;
                sa_at_store32_rel(&h->magic, SA_RATE_MAGIC);
            }
            sa_at_unlock(h->locks, hash);
        }
        if (!sa_wait_magic32(&h->magic, SA_RATE_MAGIC)) {
            if (err) *err = SA_E_MAGIC;
            return NULL;
        }
    }

    /* A caller asking for a policy the limiter does not have would be counting
     * against somebody else's numbers. Say no, as every other tenant does. */
    if ((nslots && h->nslots != nslots)
        || (burst_u && h->burst_u != burst_u)
        || (window_ms && h->window_ms != window_ms)) {
        if (err) *err = SA_E_SHAPE;
        return NULL;
    }

    r = (sa_rate *)calloc(1, sizeof(sa_rate));
    if (!r) { if (err) *err = SA_E_NOMEM; return NULL; }
    r->arena     = arena;
    r->hdr       = h;
    r->slots     = (sa_rate_slot *)((char *)h + (size_t)h->slots_off);
    r->nslots    = h->nslots;
    r->mask      = h->nslots - 1;
    r->burst_u   = h->burst_u;
    r->window_ms = h->window_ms;
    return r;
#endif
}

static void sa_rate_free(sa_rate *r) { free(r); }

#if SA_HAVE_ATOMICS

/* What the bucket holds NOW, given what it held when it was last touched.
 *
 * ELAPSED IS SIGNED, AND THAT IS THE WHOLE OF IT.
 *
 * A caller reads the clock once and then races for the slot. In between,
 * another process can write a timestamp LATER than the one this caller is
 * holding, so `now` is behind what the slot says. Unsigned subtraction turns
 * that one millisecond into 4,294,967,295 of them, which clears any window, so
 * the bucket comes back FULL and the limiter has stopped limiting.
 *
 * That is not a corner case. Measured with three processes on one key: 88
 * backwards readings in 1.5M calls, and 88 refills to full, which is 88 million
 * tokens handed to a bucket that holds one million. Every request was allowed
 * and `denied` was zero.
 *
 * The difference is taken as int32_t instead, which is serial-number
 * arithmetic: a reading slightly behind is a small negative and means no time
 * has passed for this caller, while a genuine forward interval stays correct
 * across the field's wrap. The cost is that the longest measurable idle drops
 * from 49.7 days to 24.9, and beyond that a key measures short and refills
 * slower than it should for one hit. That is the direction to be wrong in. */
static uint64_t sa_rate_refill(const sa_rate *r, uint64_t state, uint32_t now) {
    uint64_t tokens  = SA_RATE_TOKENS(state);
    int32_t  ahead   = (int32_t)(now - SA_RATE_WHEN(state));
    uint32_t elapsed;

    if (tokens >= r->burst_u) return r->burst_u;
    if (ahead <= 0) return tokens;
    elapsed = (uint32_t)ahead;
    /* Clamped before the multiply, not after: a key idle for a month would
     * otherwise overflow the intermediate on its way to an answer that is
     * simply "full". */
    if ((uint64_t)elapsed >= r->window_ms) return r->burst_u;
    tokens += ((uint64_t)elapsed * r->burst_u) / r->window_ms;
    return tokens > r->burst_u ? r->burst_u : tokens;
}

/* The timestamp to store beside a token count.
 *
 * Never the caller's own reading when the slot already holds a later one:
 * writing a stale `now` drags the bucket's clock backwards, throwing away time
 * a competing process had already accounted for and making the next caller
 * more likely to read backwards in turn. Keep whichever is further ahead. */
static uint32_t sa_rate_stamp(uint64_t state, uint32_t now) {
    uint32_t when = SA_RATE_WHEN(state);
    return ((int32_t)(now - when) > 0) ? now : when;
}

/* The slot this key lives in, claiming or reclaiming one if it has none.
 * Returns the index, or the home slot when the table is full of live buckets.
 * `*took_over` is set when a bucket that was NOT full had to be evicted. */
static uint64_t sa_rate_slot_for(sa_rate *r, uint64_t h, uint32_t now,
                                 int *took_over)
{
    uint64_t home = h & r->mask;
    uint64_t i;

    if (took_over) *took_over = 0;

    for (i = 0; i < SA_RATE_PROBE; i++) {
        uint64_t idx = (home + i) & r->mask;
        sa_rate_slot *s = &r->slots[idx];
        uint64_t have = sa_at_load64_acq(&s->keyhash);

        if (have == h) return idx;
        if (!have) {
            /* An empty slot. Losing the race for it is not a problem: the
             * winner is either us or somebody whose key we then probe past. */
            if (sa_at_cas64(&s->keyhash, 0, h)) {
                sa_at_store64_rel(&s->state, SA_RATE_STATE(r->burst_u, now));
                return idx;
            }
            if (sa_at_load64_acq(&s->keyhash) == h) return idx;
            continue;
        }
        /* Somebody else's key. A FULL bucket is indistinguishable from a key
         * that has never been seen, so taking it over loses nothing. */
        if (sa_rate_refill(r, sa_at_load64_acq(&s->state), now) >= r->burst_u) {
            if (sa_at_cas64(&s->keyhash, have, h)) {
                sa_at_store64_rel(&s->state, SA_RATE_STATE(r->burst_u, now));
                return idx;
            }
            if (sa_at_load64_acq(&s->keyhash) == h) return idx;
        }
    }

    /* Every slot in reach holds a bucket somebody is still spending from. Take
     * the home slot, which resets ONE live bucket: the victim gets more
     * requests than it should, never fewer, so a table that is too small
     * cannot turn into an outage. */
    {
        sa_rate_slot *s = &r->slots[home];
        uint64_t have = sa_at_load64_acq(&s->keyhash);
        if (have != h) {
            if (sa_at_cas64(&s->keyhash, have, h)) {
                sa_at_store64_rel(&s->state, SA_RATE_STATE(r->burst_u, now));
                if (took_over) *took_over = 1;
            }
        }
    }
    return home;
}

/* Take `cost_u` from the key's bucket.
 *
 * Returns 1 when the request is allowed, 0 when it is not. `*left_u` is what
 * remains afterwards and `*retry_ms` how long until the bucket holds enough,
 * both filled whether the answer was yes or no, because the caller wants them
 * for its headers either way.
 *
 * `peek` takes nothing and only reports, for a caller that wants to show a
 * budget without spending one. */
static int sa_rate_take(sa_rate *r, const char *key, uint32_t klen,
                        uint64_t cost_u, int peek,
                        uint64_t *left_u, uint64_t *retry_ms)
{
    uint64_t h, idx, state, tokens;
    uint32_t now;
    sa_rate_slot *s;
    int took_over = 0, tries;

    if (left_u)   *left_u   = 0;
    if (retry_ms) *retry_ms = 0;
    if (!r) return 1;                      /* no limiter: allowed */

    now = sa_rate_now_ms();
    h   = sa_at_fnv(key, (size_t)klen);
    if (!h) h = 1;                         /* 0 marks an empty slot */

    idx = sa_rate_slot_for(r, h, now, &took_over);
    if (took_over) sa_at_fetch_add64(&r->hdr->evicted, 1);
    s = &r->slots[idx];

    for (tries = 0; tries < SA_RATE_CAS_TRIES; tries++) {
        state  = sa_at_load64_acq(&s->state);
        tokens = sa_rate_refill(r, state, now);

        if (tokens < cost_u) {
            /* Denied. The refill is written back so the timestamp advances and
             * the next caller does not recompute the same elapsed window from
             * scratch; losing that CAS costs nothing, because whoever won
             * wrote the same answer.
             *
             * NOT WHEN PEEKING. `remaining` is asked from a status page and
             * from a header, and a read that writes is a read two processes
             * can contend on for nothing. */
            if (!peek)
                (void)sa_at_cas64(&s->state, state,
                                  SA_RATE_STATE(tokens, sa_rate_stamp(state, now)));
            if (left_u) *left_u = tokens;
            if (retry_ms && r->burst_u)
                *retry_ms = ((cost_u - tokens) * r->window_ms + r->burst_u - 1)
                          / r->burst_u;
            if (!peek) sa_at_fetch_add64(&r->hdr->denied, 1);
            return 0;
        }

        if (peek) {
            if (left_u) *left_u = tokens;
            return 1;
        }
        if (sa_at_cas64(&s->state, state,
                        SA_RATE_STATE(tokens - cost_u, sa_rate_stamp(state, now)))) {
            if (left_u) *left_u = tokens - cost_u;
            sa_at_fetch_add64(&r->hdr->allowed, 1);
            return 1;
        }
        /* Somebody else spent from this bucket first. Read it again. */
    }

    /* FAILS OPEN, AND SAYS SO. Under contention this heavy the honest answer
     * is that the limiter did not get to decide, and an operator needs to know
     * that rather than reading a clean `denied` count and believing it. */
    sa_at_fetch_add64(&r->hdr->contended, 1);
    if (left_u) *left_u = 0;
    return 1;
}

/* Refill one key to full, for an operator lifting a limit by hand. */
static void sa_rate_reset_key(sa_rate *r, const char *key, uint32_t klen) {
    uint64_t h, idx;
    uint32_t now;
    if (!r) return;
    now = sa_rate_now_ms();
    h   = sa_at_fnv(key, (size_t)klen);
    if (!h) h = 1;
    idx = sa_rate_slot_for(r, h, now, NULL);
    sa_at_store64_rel(&r->slots[idx].state, SA_RATE_STATE(r->burst_u, now));
}

/* Give the key's slot back, so the table has room for somebody else. */
static void sa_rate_forget(sa_rate *r, const char *key, uint32_t klen) {
    uint64_t h, home, i;
    if (!r) return;
    h = sa_at_fnv(key, (size_t)klen);
    if (!h) h = 1;
    home = h & r->mask;
    for (i = 0; i < SA_RATE_PROBE; i++) {
        uint64_t idx = (home + i) & r->mask;
        if (sa_at_load64_acq(&r->slots[idx].keyhash) == h) {
            sa_at_store64_rel(&r->slots[idx].state, 0);
            sa_at_store64_rel(&r->slots[idx].keyhash, 0);
            return;
        }
    }
}

/* How many slots hold a key. Walks the table, so this is for a status page. */
static uint64_t sa_rate_used(sa_rate *r) {
    uint64_t i, n = 0;
    if (!r) return 0;
    for (i = 0; i < r->nslots; i++)
        if (sa_at_load64_acq(&r->slots[i].keyhash)) n++;
    return n;
}

#endif /* SA_HAVE_ATOMICS */

#endif /* SA_RATE_H */
