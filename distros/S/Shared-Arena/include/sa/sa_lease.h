#ifndef SA_LEASE_H
#define SA_LEASE_H

/* sa_lease.h - one holder at a time, and a successor when it dies. Perl-free.
 *
 * ---- the problem ------------------------------------------------------------
 *
 * A pre-forked pool eventually needs exactly ONE worker to do something: run
 * the cron, warm a cache, apply migrations, own a scheduler. "The first one"
 * is not an answer, because the first one restarts. A lease is: whoever holds
 * it is the one, and when the holder stops renewing it - because it exited,
 * crashed, or wedged - a successor takes it over.
 *
 * This is the peer table's death-proof idea (sa_peer.h) turned into a feature.
 * A holder is named by its pid; a successor may take the lease when it has
 * LAPSED - the holder failed to renew before a deadline - or when the holder is
 * PROVABLY DEAD, which lets failover happen faster than the deadline when the
 * process is simply gone.
 *
 * ---- the deadline is primary, the pid check only makes it faster -----------
 *
 * The deadline is what carries correctness: a holder must renew before it
 * lapses, and one that cannot - wedged, stopped, off-CPU too long - loses the
 * lease when it lapses whether or not it is technically alive. That is the
 * right answer: a leader that cannot renew is not leading.
 *
 * The pid check only ever makes a steal happen EARLIER, never against a live
 * renewing holder: a holder that is gone is stolen from the moment a successor
 * notices, rather than after the full deadline. A recycled pid that happens to
 * be alive again just means the successor waits out the deadline instead, which
 * is the slow path, not a wrong one.
 *
 * ---- the fencing token ------------------------------------------------------
 *
 * Every acquire bumps a generation, and acquire hands it back. A holder that
 * was preempted, lost the lease to a successor, and then woke up and tried to
 * act is the classic distributed-lock hazard. So renew and release check the
 * generation: a holder carrying a stale one is told it has lost the lease, and
 * a caller that stamps its outbound writes with the fence lets the resource
 * itself reject a zombie leader's late write. See `fence`.
 *
 * ---- under the stripe lock, on purpose --------------------------------------
 *
 * Acquire, renew and release each take the slot's stripe lock. A lease changes
 * hands every few seconds at most - it is leader election, not a per-request
 * counter - so the lock costs nothing that matters and removes every
 * compare-and-swap ordering hazard the hot-path tenants have to reason about.
 *
 * A lock that cannot be taken (a process died holding the stripe, which is the
 * only way sa_at_lock fails) biases SAFE: acquire returns "not acquired" and
 * renew returns "lost", so the failure can make leadership briefly unavailable
 * but never doubly held. The deadline is the backstop that recovers it.
 *
 * Needs sa_arena.h and sa_peer.h (for sa_pid_alive / sa_getpid).
 */

#include "sa/sa_arena.h"
#include "sa/sa_peer.h"

#define SA_LEASE_MAGIC 0x5341454Cu    /* 'L','E','A','S' little-endian */

#define SA_LEASES_MAX  64
#define SA_LEASE_NAME  32

/* The lease table lives in a carved sub-region under a reserved name, so every
 * process finds it the same way and one registry entry holds all leases. */
#define SA_LEASE_TABLE_NAME "\0leases"
#define SA_LEASE_TABLE_NLEN 7

#define SA_L_EMPTY    0u
#define SA_L_CLAIMING 1u
#define SA_L_LIVE     2u

typedef struct {
    volatile uint32_t state;      /* SA_L_* - published LAST at create      */
    uint32_t          pad;
    volatile uint64_t owner;      /* holder pid; 0 = free                   */
    volatile uint64_t gen;        /* fencing token, bumped on every acquire */
    volatile uint64_t expires;    /* ms wall clock; the renew deadline      */
    volatile uint64_t acquires;   /* successful acquires, including steals   */
    volatile uint64_t steals;     /* acquires that took over another holder  */
    char              name[SA_LEASE_NAME];
} sa_lease_slot;

typedef struct {
    volatile uint32_t magic;      /* published LAST at init                 */
    uint32_t          nleases;
    uint64_t          slots_off;  /* from the TABLE's base                  */
    volatile unsigned char locks[SA_LOCK_STRIPES];
} sa_lease_hdr;

/* The process-local handle. Nothing here is in the mapping: `slot` is this
 * process's address for the shared lease, and `gen` is the fence this process
 * last acquired at. */
#ifndef SA_LEASE_FWD
#define SA_LEASE_FWD
typedef struct sa_lease sa_lease;
#endif

struct sa_lease {
    sa_region     *arena;
    sa_lease_hdr  *hdr;
    sa_lease_slot *slot;
    uint64_t       gen;           /* the generation this handle holds        */
    uint64_t       hash;          /* the stripe this slot locks on           */
    uint64_t       ttl_ms;        /* this handle's default lease length      */
};

/* acquire / renew results */
#define SA_LEASE_LOST      0    /* not the holder                            */
#define SA_LEASE_HELD      1    /* the holder, lease extended                */

static uint64_t sa_lease_table_bytes(void) {
    return sa_align_up((uint64_t)sizeof(sa_lease_hdr))
         + sa_align_up((uint64_t)SA_LEASES_MAX * (uint64_t)sizeof(sa_lease_slot));
}

#define SA_LEASE_SLOTS(h) \
    ((sa_lease_slot *)((char *)(h) + (size_t)(h)->slots_off))

#if SA_HAVE_ATOMICS

/* Find the lease table region, initialising it if nobody has yet - the same
 * commit discipline as everywhere: write the header, publish magic last, and
 * everybody else waits bounded. */
static sa_lease_hdr *sa_lease_table(sa_region *arena, int *err) {
    sa_reg *e;
    sa_lease_hdr *h;
    uint64_t hash;

    if (err) *err = SA_E_OK;
    if (!arena) { if (err) *err = SA_E_NOENT; return NULL; }

    e = sa_carve(arena, SA_LEASE_TABLE_NAME, SA_LEASE_TABLE_NLEN,
                 sa_lease_table_bytes(), SA_T_LEASE, err);
    if (!e) return NULL;

    h = (sa_lease_hdr *)sa_ptr_len(arena, e->off, sizeof(sa_lease_hdr));
    if (!h) { if (err) *err = SA_E_NOENT; return NULL; }

    if (sa_at_load32_acq(&h->magic) != SA_LEASE_MAGIC) {
        hash = sa_at_fnv(SA_LEASE_TABLE_NAME, SA_LEASE_TABLE_NLEN);
        if (sa_at_lock(h->locks, hash)) {
            if (sa_at_load32_acq(&h->magic) != SA_LEASE_MAGIC) {
                if (sa_lease_table_bytes() > e->len) {
                    sa_at_unlock(h->locks, hash);
                    if (err) *err = SA_E_FULL;
                    return NULL;
                }
                memset((void *)h, 0, (size_t)sa_lease_table_bytes());
                h->nleases   = SA_LEASES_MAX;
                h->slots_off = sa_align_up((uint64_t)sizeof(sa_lease_hdr));
                sa_at_store32_rel(&h->magic, SA_LEASE_MAGIC);
            }
            sa_at_unlock(h->locks, hash);
        }
        if (!sa_wait_magic32(&h->magic, SA_LEASE_MAGIC)) {
            if (err) *err = SA_E_MAGIC;
            return NULL;
        }
    }
    return h;
}

/* Find the named lease slot, or make it. The stripe lock keyed on the name
 * stops two processes creating two slots for one name - which would be two
 * leases nobody could tell apart, each with its own holder. */
static sa_lease_slot *sa_lease_slot_for(sa_lease_hdr *h, const char *name,
                                        uint32_t nlen, int *err)
{
    sa_lease_slot *slots = SA_LEASE_SLOTS(h);
    uint64_t hash;
    uint32_t i, n;

    if (err) *err = SA_E_OK;
    if (!name || !nlen || nlen >= SA_LEASE_NAME) {
        if (err) *err = SA_E_NAME;
        return NULL;
    }
    n = h->nleases > SA_LEASES_MAX ? SA_LEASES_MAX : h->nleases;
    hash = sa_at_fnv(name, nlen);

    if (!sa_at_lock(h->locks, hash)) { if (err) *err = SA_E_FULL; return NULL; }

    for (i = 0; i < n; i++) {
        sa_lease_slot *s = &slots[i];
        if (sa_at_load32_acq(&s->state) != SA_L_LIVE) continue;
        if (strncmp(s->name, name, nlen) || s->name[nlen]) continue;
        sa_at_unlock(h->locks, hash);
        return s;
    }
    for (i = 0; i < n; i++) {
        sa_lease_slot *s = &slots[i];
        if (!sa_at_cas32(&s->state, SA_L_EMPTY, SA_L_CLAIMING)) continue;
        memset(s->name, 0, SA_LEASE_NAME);
        memcpy(s->name, name, nlen);
        sa_at_store64_rel(&s->owner, 0);
        sa_at_store64_rel(&s->gen, 0);
        sa_at_store64_rel(&s->expires, 0);
        sa_at_store64_rel(&s->acquires, 0);
        sa_at_store64_rel(&s->steals, 0);
        sa_at_store32_rel(&s->state, SA_L_LIVE);
        sa_at_unlock(h->locks, hash);
        return s;
    }
    sa_at_unlock(h->locks, hash);
    if (err) *err = SA_E_FULL;
    return NULL;
}

static sa_lease *sa_lease_bind(sa_region *arena, const char *name,
                               uint32_t nlen, int *err)
{
    sa_lease_hdr *h;
    sa_lease_slot *s;
    sa_lease *lh;

    h = sa_lease_table(arena, err);
    if (!h) return NULL;
    s = sa_lease_slot_for(h, name, nlen, err);
    if (!s) return NULL;

    lh = (sa_lease *)calloc(1, sizeof(sa_lease));
    if (!lh) { if (err) *err = SA_E_NOMEM; return NULL; }
    lh->arena  = arena;
    lh->hdr    = h;
    lh->slot   = s;
    lh->gen    = 0;
    lh->hash   = sa_at_fnv(name, nlen);
    lh->ttl_ms = 30000;      /* a sane default; the Perl surface overrides it */
    return lh;
}

static void sa_lease_free(sa_lease *lh) { free(lh); }

/* Take the lease, or extend it if we already hold it. Returns SA_LEASE_HELD
 * when this process now holds it, SA_LEASE_LOST when somebody else does and
 * their lease is still current.
 *
 * `*stole` (optional) is set when the acquire took over a holder that had
 * lapsed or died, rather than a free lease - which tells a caller it has just
 * become leader after a predecessor failed, not started clean. */
static int sa_lease_acquire(sa_lease *lh, uint64_t ttl_ms, int *stole)
{
    sa_lease_slot *s;
    sa_lease_hdr *h;
    uint64_t me, now, owner, exp;

    if (stole) *stole = 0;
    if (!lh) return SA_LEASE_LOST;
    s = lh->slot;
    h = lh->hdr;
    me  = sa_getpid();
    now = sa_now_ms();

    /* A wedged stripe biases safe: not acquiring can never create a second
     * holder, and the deadline recovers the lease later. */
    if (!sa_at_lock(h->locks, lh->hash)) return SA_LEASE_LOST;

    owner = sa_at_load64_acq(&s->owner);
    exp   = sa_at_load64_acq(&s->expires);

    if (owner == me) {
        /* Already ours: renew. gen is unchanged - it is still the same tenure. */
        sa_at_store64_rel(&s->expires, now + ttl_ms);
        lh->gen = sa_at_load64_acq(&s->gen);
        sa_at_unlock(h->locks, lh->hash);
        return SA_LEASE_HELD;
    }

    if (owner == 0 || now >= exp || !sa_pid_alive(owner)) {
        int taking_over = (owner != 0);
        uint64_t g = sa_at_load64_acq(&s->gen) + 1;
        sa_at_store64_rel(&s->gen, g);
        sa_at_store64_rel(&s->owner, me);
        sa_at_store64_rel(&s->expires, now + ttl_ms);
        sa_at_fetch_add64(&s->acquires, 1);
        if (taking_over) sa_at_fetch_add64(&s->steals, 1);
        lh->gen = g;
        if (stole) *stole = taking_over;
        sa_at_unlock(h->locks, lh->hash);
        return SA_LEASE_HELD;
    }

    /* A live holder whose lease is current, and it is not us. */
    sa_at_unlock(h->locks, lh->hash);
    return SA_LEASE_LOST;
}

/* Extend a lease we hold. Returns SA_LEASE_HELD when we still hold it at the
 * generation we acquired, SA_LEASE_LOST when we have been superseded - a holder
 * that lost the lease and comes back must find out, not silently keep going. */
static int sa_lease_renew(sa_lease *lh, uint64_t ttl_ms)
{
    sa_lease_slot *s;
    sa_lease_hdr *h;
    uint64_t me, now;
    int rc = SA_LEASE_LOST;

    if (!lh) return SA_LEASE_LOST;
    s = lh->slot;
    h = lh->hdr;
    me  = sa_getpid();
    now = sa_now_ms();

    /* A wedged stripe biases safe: renew returns "lost", so the caller steps
     * down and the deadline hands the lease on. */
    if (!sa_at_lock(h->locks, lh->hash)) return SA_LEASE_LOST;

    if (sa_at_load64_acq(&s->owner) == me
        && sa_at_load64_acq(&s->gen) == lh->gen) {
        sa_at_store64_rel(&s->expires, now + ttl_ms);
        rc = SA_LEASE_HELD;
    }
    sa_at_unlock(h->locks, lh->hash);
    return rc;
}

/* Give the lease up, so a successor takes it at once rather than after the
 * deadline. Only the holder at the current generation can release it: a stale
 * handle releasing would free a lease somebody else now holds. */
static int sa_lease_release(sa_lease *lh)
{
    sa_lease_slot *s;
    sa_lease_hdr *h;
    uint64_t me;
    int rc = 0;

    if (!lh) return 0;
    s = lh->slot;
    h = lh->hdr;
    me = sa_getpid();

    if (!sa_at_lock(h->locks, lh->hash)) return 0;
    if (sa_at_load64_acq(&s->owner) == me
        && sa_at_load64_acq(&s->gen) == lh->gen) {
        sa_at_store64_rel(&s->owner, 0);
        sa_at_store64_rel(&s->expires, 0);
        rc = 1;
    }
    sa_at_unlock(h->locks, lh->hash);
    return rc;
}

/* The pid that effectively holds the lease right now, or 0 when it is free or
 * lapsed. Read-only and lock-free: a lapsed holder reports 0 because a
 * successor could take the lease this instant, so reporting the stale pid would
 * be a lie a caller might act on. */
static uint64_t sa_lease_holder(sa_lease *lh)
{
    sa_lease_slot *s;
    uint64_t owner, exp;
    if (!lh) return 0;
    s = lh->slot;
    owner = sa_at_load64_acq(&s->owner);
    if (!owner) return 0;
    exp = sa_at_load64_acq(&s->expires);
    if (sa_now_ms() >= exp) return 0;
    if (!sa_pid_alive(owner)) return 0;
    return owner;
}

/* Do we hold it, at the generation we last acquired, unlapsed? */
static int sa_lease_mine(sa_lease *lh)
{
    sa_lease_slot *s;
    if (!lh) return 0;
    s = lh->slot;
    if (sa_at_load64_acq(&s->owner) != sa_getpid()) return 0;
    if (sa_at_load64_acq(&s->gen) != lh->gen) return 0;
    return sa_now_ms() < sa_at_load64_acq(&s->expires);
}

static uint64_t sa_lease_fence(sa_lease *lh) { return lh ? lh->gen : 0; }

#else /* !SA_HAVE_ATOMICS */

/* No atomics: no lease. Every function is still DEFINED, because the ABI table
 * names them - a table entry cannot point at a function the build compiled out.
 * The lease FAILS CLOSED: acquire never succeeds, so a build with no atomics
 * simply has no leader election and no worker is ever told it is the one. That
 * is the safe direction - "nobody is leader" cannot make two workers both act -
 * and it matches how every other tenant degrades when it cannot use an atomic. */
static sa_lease *sa_lease_bind(sa_region *arena, const char *name,
                               uint32_t nlen, int *err) {
    (void)arena; (void)name; (void)nlen;
    if (err) *err = SA_E_NOATOMICS;
    return NULL;
}
static void sa_lease_free(sa_lease *lh) { free(lh); }
static int sa_lease_acquire(sa_lease *lh, uint64_t ttl_ms, int *stole) {
    (void)lh; (void)ttl_ms;
    if (stole) *stole = 0;
    return SA_LEASE_LOST;
}
static int sa_lease_renew(sa_lease *lh, uint64_t ttl_ms) {
    (void)lh; (void)ttl_ms; return SA_LEASE_LOST;
}
static int sa_lease_release(sa_lease *lh) { (void)lh; return 0; }
static int sa_lease_mine(sa_lease *lh) { (void)lh; return 0; }
static uint64_t sa_lease_holder(sa_lease *lh) { (void)lh; return 0; }
static uint64_t sa_lease_fence(sa_lease *lh) { return lh ? lh->gen : 0; }

#endif /* SA_HAVE_ATOMICS */

#endif /* SA_LEASE_H */
