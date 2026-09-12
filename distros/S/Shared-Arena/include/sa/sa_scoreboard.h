#ifndef SA_SCOREBOARD_H
#define SA_SCOREBOARD_H

/* sa_scoreboard.h - one row per worker, published live. Perl-free.
 *
 * ---- the contention model, inverted -----------------------------------------
 *
 * Every other shared table here has many writers to one structure, and pays a
 * stripe lock to keep them from tearing each other's writes. A scoreboard is
 * the opposite: each worker owns ONE row and is the only writer to it, and a
 * reader - a status endpoint, a supervisor - reads every row in one pass.
 *
 * So there is no write contention at all. A worker updating its own row takes
 * no lock, because nobody else writes that row; the only lock in the whole
 * tenant is the one taken once to CLAIM a row, which happens at worker start.
 *
 * This is Apache's scoreboard, for a fork-shared pool: a live per-worker view -
 * in-flight requests, total served, bytes, what each worker is doing right now -
 * that the supervisor reads directly out of memory instead of collecting over a
 * pipe or a stats socket per worker.
 *
 * ---- a coherent snapshot, with a seqlock and no lock -------------------------
 *
 * A reader wants a row's fields together: the in-flight count and the status
 * line as they were at one instant, not the count from before an update and the
 * string from after. The single writer bumps a version odd before it touches
 * the row and even after, and the reader reads the version either side and
 * retries if it moved - the ring's two-word discipline, but with exactly one
 * writer so no stripe lock is needed.
 *
 * ---- a dead worker's row is reclaimed, not leaked ---------------------------
 *
 * A row records its owner's pid. A worker that dies leaves its row occupied and
 * stale; the next worker that starts and needs a row reclaims one whose owner is
 * gone, resets it, and takes it over. A reader shows a dead worker's row as not
 * alive rather than as current, and a worker that died MID-UPDATE - version
 * stuck odd - is read as stale after a bounded retry rather than spun on for
 * ever. The bound is the same reasoning as everywhere: a writer holds a row odd
 * for a few stores, so any longer means it died holding it.
 *
 * ---- the schema ------------------------------------------------------------
 *
 * The gauge fields are named once, by whoever creates the board, so every row
 * has the same columns and a reader gets them back by name. A later attacher
 * either names the same fields or inherits them; a different set is refused, the
 * way every tenant refuses a shape it does not share.
 *
 * Needs sa_arena.h and sa_peer.h (for sa_pid_alive / sa_getpid).
 */

#include "sa/sa_arena.h"
#include "sa/sa_peer.h"

#define SA_SB_MAGIC 0x44524253u    /* 'S','B','R','D' little-endian */

#define SA_SB_SLOTS_MAX 4096       /* workers a board can hold          */
#define SA_SB_FIELDS    8          /* named gauges per row              */
#define SA_SB_NAME      16         /* a field name, including the NUL    */
#define SA_SB_STATUS    64         /* the free-text status line         */
#define SA_SB_RETRY     1000       /* seqlock retries before "stale"    */

#define SA_SB_EMPTY 0u
#define SA_SB_LIVE  1u

typedef struct {
    volatile uint32_t state;      /* SA_SB_EMPTY / SA_SB_LIVE               */
    volatile uint32_t version;    /* odd while the owner is writing         */
    volatile uint64_t pid;        /* the owner                              */
    volatile uint64_t epoch;      /* bumped on every (re)claim: an identity */
    volatile uint64_t updated;    /* ms wall clock of the last write        */
    volatile uint64_t gauges[SA_SB_FIELDS];
    volatile uint32_t statuslen;
    char              status[SA_SB_STATUS];
} sa_sb_slot;

typedef struct {
    volatile uint32_t magic;      /* published LAST at init                 */
    uint32_t          nslots;
    uint32_t          nfields;
    uint32_t          pad;
    uint64_t          slots_off;  /* from the BOARD's base                  */
    char              fields[SA_SB_FIELDS][SA_SB_NAME];  /* the schema       */
    volatile unsigned char locks[SA_LOCK_STRIPES];       /* claim only       */
} sa_sb_hdr;

#ifndef SA_SB_FWD
#define SA_SB_FWD
typedef struct sa_sb sa_sb;
#endif

/* The process-local handle. `mine` is the index of the row this process
 * claimed, or -1; `epoch` is the identity of that claim, so a stale handle
 * cannot write a row a later worker now owns. */
struct sa_sb {
    sa_region  *arena;
    sa_sb_hdr  *hdr;
    sa_sb_slot *slots;
    uint32_t    nslots;
    uint32_t    nfields;
    int         mine;
    uint64_t    epoch;
};

/* One row read out coherently, for a reader. Guarded so the identical struct in
 * sa_abi.h (which a C consumer sees WITHOUT this header) is not defined twice;
 * SA_SB_FIELDS is 8 and SA_SB_STATUS 64, matching the literals there. */
#ifndef SA_SB_READING_DEFINED
#define SA_SB_READING_DEFINED
typedef struct sa_sb_reading {
    uint64_t pid;
    uint64_t epoch;
    uint64_t updated;
    int      alive;                     /* is the owner still running        */
    uint64_t gauges[SA_SB_FIELDS];
    uint32_t statuslen;
    char     status[SA_SB_STATUS];
} sa_sb_reading;
#endif

static uint64_t sa_sb_bytes(uint32_t nslots) {
    return sa_align_up((uint64_t)sizeof(sa_sb_hdr))
         + sa_align_up((uint64_t)nslots * (uint64_t)sizeof(sa_sb_slot));
}

#define SA_SB_SLOTS(h) \
    ((sa_sb_slot *)((char *)(h) + (size_t)(h)->slots_off))

#if SA_HAVE_ATOMICS

/* The index of a named field, or -1. A small linear scan the writer does once
 * per update; a caller that cares caches it. */
static int sa_sb_field(const sa_sb *b, const char *name, uint32_t nlen) {
    uint32_t i;
    if (!name || !nlen || nlen >= SA_SB_NAME) return -1;
    for (i = 0; i < b->nfields; i++) {
        if (strncmp(b->hdr->fields[i], name, nlen) == 0
            && b->hdr->fields[i][nlen] == '\0')
            return (int)i;
    }
    return -1;
}

static sa_sb *sa_sb_bind(sa_region *arena, sa_reg *e,
                         const char *const *fields, uint32_t nfields, int *err)
{
    sa_sb *b;
    sa_sb_hdr *h;
    uint64_t hash;

    if (err) *err = SA_E_OK;
    if (!arena || !e) { if (err) *err = SA_E_NOENT; return NULL; }
    if (nfields > SA_SB_FIELDS) { if (err) *err = SA_E_NAME; return NULL; }

    h = (sa_sb_hdr *)sa_ptr_len(arena, e->off, sizeof(sa_sb_hdr));
    if (!h) { if (err) *err = SA_E_NOENT; return NULL; }

    if (sa_at_load32_acq(&h->magic) != SA_SB_MAGIC) {
        hash = sa_at_fnv(e->name, strlen(e->name));
        if (sa_at_lock(h->locks, hash)) {
            if (sa_at_load32_acq(&h->magic) != SA_SB_MAGIC) {
                uint32_t nsl = (uint32_t)((e->len - sizeof(sa_sb_hdr))
                                          / sizeof(sa_sb_slot));
                uint32_t i;
                if (nsl < 1 || sa_sb_bytes(nsl) > e->len) {
                    sa_at_unlock(h->locks, hash);
                    if (err) *err = SA_E_FULL;
                    return NULL;
                }
                if (nsl > SA_SB_SLOTS_MAX) nsl = SA_SB_SLOTS_MAX;
                memset((void *)h, 0, (size_t)sa_sb_bytes(nsl));
                h->nslots    = nsl;
                h->nfields   = nfields;
                h->slots_off = sa_align_up((uint64_t)sizeof(sa_sb_hdr));
                for (i = 0; i < nfields && fields; i++) {
                    size_t l = strlen(fields[i]);
                    if (l >= SA_SB_NAME) l = SA_SB_NAME - 1;
                    memcpy(h->fields[i], fields[i], l);
                }
                sa_at_store32_rel(&h->magic, SA_SB_MAGIC);
            }
            sa_at_unlock(h->locks, hash);
        }
        if (!sa_wait_magic32(&h->magic, SA_SB_MAGIC)) {
            if (err) *err = SA_E_MAGIC;
            return NULL;
        }
    }

    /* A caller that named fields must name the SAME ones, for the reason every
     * tenant checks its shape: two processes disagreeing about the columns is
     * worse than either failing. A caller that named none inherits them. */
    if (nfields) {
        uint32_t i;
        if (h->nfields != nfields) { if (err) *err = SA_E_SHAPE; return NULL; }
        for (i = 0; i < nfields && fields; i++) {
            if (strncmp(h->fields[i], fields[i], SA_SB_NAME) != 0) {
                if (err) *err = SA_E_SHAPE;
                return NULL;
            }
        }
    }

    b = (sa_sb *)calloc(1, sizeof(sa_sb));
    if (!b) { if (err) *err = SA_E_NOMEM; return NULL; }
    b->arena   = arena;
    b->hdr     = h;
    b->slots   = SA_SB_SLOTS(h);
    b->nslots  = h->nslots;
    b->nfields = h->nfields;
    b->mine    = -1;
    b->epoch   = 0;
    return b;
}

static void sa_sb_free(sa_sb *b) { free(b); }

/* Claim a row for this process, reclaiming a dead worker's row when the board
 * is full. Returns the row index, or -1 when every row belongs to a live
 * worker. Idempotent: called again in the same process it returns the row it
 * already holds.
 *
 * The stripe lock serialises claimers - the ONE place this tenant locks - so a
 * row is never handed to two workers at once. */
static int sa_sb_take(sa_sb *b) {
    sa_sb_hdr *h;
    uint64_t me, hash;
    uint32_t i;
    int dead = -1;

    if (!b) return -1;
    if (b->mine >= 0) return b->mine;
    h  = b->hdr;
    me = sa_getpid();
    hash = sa_at_fnv("\0scoreboard-claim", 17);

    if (!sa_at_lock(h->locks, hash)) return -1;

    /* Already ours from an earlier take in this same process? */
    for (i = 0; i < b->nslots; i++) {
        sa_sb_slot *s = &b->slots[i];
        if (sa_at_load32_acq(&s->state) == SA_SB_LIVE
            && sa_at_load64_acq(&s->pid) == me) {
            b->mine  = (int)i;
            b->epoch = sa_at_load64_acq(&s->epoch);
            sa_at_unlock(h->locks, hash);
            return b->mine;
        }
    }
    /* First empty row; remember the first dead-owner row as a fallback. */
    for (i = 0; i < b->nslots; i++) {
        sa_sb_slot *s = &b->slots[i];
        uint32_t st = sa_at_load32_acq(&s->state);
        if (st == SA_SB_EMPTY) { dead = (int)i; break; }
        if (dead < 0 && !sa_pid_alive(sa_at_load64_acq(&s->pid)))
            dead = (int)i;
    }
    if (dead < 0) { sa_at_unlock(h->locks, hash); return -1; }
    {
        sa_sb_slot *s = &b->slots[dead];
        uint64_t ep = sa_at_load64_acq(&s->epoch) + 1;
        uint32_t f;
        sa_at_store32_rel(&s->version, sa_at_load32_acq(&s->version) | 1u);
        sa_at_fence_rel();
        sa_at_store64_rel(&s->pid, me);
        sa_at_store64_rel(&s->epoch, ep);
        sa_at_store64_rel(&s->updated, sa_now_ms());
        for (f = 0; f < SA_SB_FIELDS; f++) sa_at_store64_rel(&s->gauges[f], 0);
        s->statuslen = 0;
        s->status[0] = '\0';
        sa_at_fence_rel();
        sa_at_store32_rel(&s->version, (sa_at_load32_acq(&s->version) + 1u));
        sa_at_store32_rel(&s->state, SA_SB_LIVE);
        b->mine  = dead;
        b->epoch = ep;
    }
    sa_at_unlock(h->locks, hash);
    return b->mine;
}

/* Open a write to our own row: version odd, and a barrier so the stores below
 * cannot be seen before the version moves. Returns our row, or NULL if we hold
 * none or a later worker has taken ours over (a stale handle must not write).
 * The caller pairs it with sa_sb_end. Being the only writer to this row, no
 * lock is taken. */
static sa_sb_slot *sa_sb_begin(sa_sb *b) {
    sa_sb_slot *s;
    if (!b || b->mine < 0) return NULL;
    s = &b->slots[b->mine];
    if (sa_at_load64_acq(&s->pid) != sa_getpid()
        || sa_at_load64_acq(&s->epoch) != b->epoch)
        return NULL;              /* our row was reclaimed: do not write it */
    sa_at_store32_rel(&s->version, sa_at_load32_acq(&s->version) | 1u);
    sa_at_fence_rel();
    return s;
}

static void sa_sb_end(sa_sb *b, sa_sb_slot *s) {
    if (!b || !s) return;
    sa_at_store64_rel(&s->updated, sa_now_ms());
    sa_at_fence_rel();
    sa_at_store32_rel(&s->version, (sa_at_load32_acq(&s->version) + 1u));
}

/* Between begin and end. The owner is the only writer, so these are plain
 * release stores with no lock; the seqlock the bracket maintains is what makes
 * the whole set coherent to a reader. */
static void sa_sb_set_gauge(sa_sb_slot *s, int idx, uint64_t v) {
    if (s && idx >= 0 && idx < SA_SB_FIELDS)
        sa_at_store64_rel(&s->gauges[idx], v);
}

static void sa_sb_add_gauge(sa_sb_slot *s, int idx, int64_t by) {
    if (s && idx >= 0 && idx < SA_SB_FIELDS)
        sa_at_store64_rel(&s->gauges[idx],
                          sa_at_load64_acq(&s->gauges[idx]) + (uint64_t)by);
}

static void sa_sb_set_status(sa_sb_slot *s, const char *p, uint32_t n) {
    if (!s) return;
    if (n >= SA_SB_STATUS) n = SA_SB_STATUS - 1;
    if (n && p) memcpy(s->status, p, n);
    s->status[n] = '\0';
    s->statuslen = n;
}

/* Read row `i` coherently. Returns 1 with `out` filled for a live row, 0 for an
 * empty one or one whose writer died mid-update (version stuck odd past the
 * retry bound). `out->alive` says whether the owner is still running. */
static int sa_sb_read(sa_sb *b, uint32_t i, sa_sb_reading *out) {
    sa_sb_slot *s;
    long spin;

    if (!b || !out || i >= b->nslots) return 0;
    s = &b->slots[i];
    if (sa_at_load32_acq(&s->state) != SA_SB_LIVE) return 0;

    for (spin = 0; spin < SA_SB_RETRY; spin++) {
        uint32_t v1 = sa_at_load32_acq(&s->version);
        uint32_t f, sl;
        if (v1 & 1u) continue;                 /* mid-update: wait a moment  */

        out->pid     = sa_at_load64_acq(&s->pid);
        out->epoch   = sa_at_load64_acq(&s->epoch);
        out->updated = sa_at_load64_acq(&s->updated);
        for (f = 0; f < SA_SB_FIELDS; f++)
            out->gauges[f] = sa_at_load64_acq(&s->gauges[f]);
        sl = s->statuslen;
        if (sl >= SA_SB_STATUS) sl = SA_SB_STATUS - 1;
        memcpy(out->status, s->status, sl);
        out->status[sl] = '\0';
        out->statuslen  = sl;

        sa_at_fence_acq();
        if (sa_at_load32_acq(&s->version) != v1) continue;   /* it changed */

        out->alive = sa_pid_alive(out->pid) ? 1 : 0;
        return 1;
    }
    return 0;   /* stuck odd: the owner died mid-update */
}

#else /* !SA_HAVE_ATOMICS */

/* No atomics: no scoreboard. Defined so the ABI table has something to point
 * at; inert so a build without atomics has an empty board rather than a crash.
 * A publish is a no-op and a read finds no rows, which is what a status page
 * with nothing behind it should show. */
static int sa_sb_field(const sa_sb *b, const char *name, uint32_t nlen) {
    (void)b; (void)name; (void)nlen; return -1;
}
static sa_sb *sa_sb_bind(sa_region *arena, sa_reg *e,
                         const char *const *fields, uint32_t nfields, int *err) {
    (void)arena; (void)e; (void)fields; (void)nfields;
    if (err) *err = SA_E_NOATOMICS;
    return NULL;
}
static void sa_sb_free(sa_sb *b) { free(b); }
static int sa_sb_take(sa_sb *b) { (void)b; return -1; }
static sa_sb_slot *sa_sb_begin(sa_sb *b) { (void)b; return NULL; }
static void sa_sb_end(sa_sb *b, sa_sb_slot *s) { (void)b; (void)s; }
static void sa_sb_set_gauge(sa_sb_slot *s, int idx, uint64_t v) {
    (void)s; (void)idx; (void)v;
}
static void sa_sb_add_gauge(sa_sb_slot *s, int idx, int64_t by) {
    (void)s; (void)idx; (void)by;
}
static void sa_sb_set_status(sa_sb_slot *s, const char *p, uint32_t n) {
    (void)s; (void)p; (void)n;
}
static int sa_sb_read(sa_sb *b, uint32_t i, sa_sb_reading *out) {
    (void)b; (void)i; (void)out; return 0;
}

#endif /* SA_HAVE_ATOMICS */

#endif /* SA_SCOREBOARD_H */
