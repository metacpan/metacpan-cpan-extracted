#ifndef SA_RING_H
#define SA_RING_H

/* sa_ring.h - a multi-producer record ring, as a tenant of an arena region.
 * Perl-free.
 *
 * ---- fixed slots, and why not a byte ring -----------------------------------
 *
 * Records are variable length and a record may span several slots. What it may
 * NOT do is float: slot N is always at `slots_off + (N % nslots) * slot_size`,
 * arithmetic on a sequence number and nothing else.
 *
 * That is the property a byte-addressed ring gives up, and giving it up costs
 * more than it saves. In a byte ring, record N's offset is
 * `offset(N-1) + len(N-1)`, so a consumer competing for the next record must
 * first READ a length header that may be mid-write or already lapped, and then
 * advance a SHARED cursor based on what it read. A torn or stale read moves
 * that cursor to an offset in the middle of a record, and every other consumer
 * follows it there. Repairing that needs a self-validating header, a
 * forward-scan resynchronisation that only ever runs in the case nobody tests,
 * and gap accounting in bytes instead of messages.
 *
 * What a byte ring buys is storage proportional to the real message size. That
 * is a tuning property. Claim correctness is a design property. So: fixed
 * slots, and a record that does not fit takes more of them.
 *
 * ---- a record spans slots, and the head is the commit point -----------------
 *
 * A record too big for one slot reserves several with ONE fetch_add, so the
 * claim is still a single atomic and the slot address is still arithmetic.
 *
 * The parts are then published in REVERSE ORDER, head last. That is what makes
 * a spanned record atomic to a reader: holding a committed head is proof that
 * every continuation behind it is already committed, so the reader gathers the
 * tail by arithmetic and a lap re-check, and never waits a second time. Publish
 * the head first and a reader can hold a valid head whose body has not been
 * written yet, which is a hole in the middle of a record rather than between
 * two of them.
 *
 * A record may span at most half the ring, so it can never lap itself while it
 * is being written. Larger than that is REFUSED, never truncated - a truncated
 * record is a lie the reader cannot detect, since it arrives with the right
 * sequence, the right topic and a body that silently is not what was sent.
 *
 * ---- TWO sequence words, because one is not enough --------------------------
 *
 * The obvious protocol is one word per slot: zero it, write the body, then
 * release-store the sequence, and have the reader check that sequence before
 * and after it copies. That is wrong, and the way it is wrong is worth writing
 * down because it looks right and it passes every gentle test.
 *
 * Two publishers a full lap apart share a slot. A takes sequence 1000 and is
 * preempted mid-write. B takes 1256, writes its record into the same slot and
 * commits. A then wakes, finishes writing ITS body over B's, and commits 1000.
 * A reader asking for 1000 now sees 1000 before its copy and 1000 after it, and
 * delivers a body that is half A's and half B's. The check passed because the
 * final value is simply whoever stored last, which says nothing about who
 * touched the bytes in between.
 *
 * So a slot carries the sequence TWICE. `begin` is stored before the body,
 * `end` after it:
 *
 *   publisher   begin = N ... body ... end = N
 *   reader      end == N ?  copy  ?  begin still == N ?
 *
 * In the interleaving above the slot ends with begin=1256 and end=1000, and
 * both readers are told the truth: the one asking for 1000 sees begin moved on
 * and calls it LAPPED, and the one asking for 1256 sees end behind and waits.
 * A false LAPPED is possible - a writer that starts just after a clean read
 * finishes - and that is the right direction to be wrong in: a counted loss,
 * never a corrupt delivery.
 *
 * Three answers, and they are not two:
 *
 *   OK       this slot holds N, whole
 *   PENDING  the slot has not reached N yet: a publisher is mid-write
 *   LAPPED   the ring moved past N: it is gone
 *
 * Conflating PENDING and LAPPED turns "wait a moment" into "give up and count a
 * loss", which silently drops live records under load.
 *
 * Sequence 0 is never used, so a cursor that has never moved cannot be mistaken
 * for one sitting on a written slot.
 *
 * ---- overflow is drop-oldest, and it is counted -----------------------------
 *
 * A publisher never blocks and never fails because a reader is slow: it
 * overwrites the oldest slot. A reader that has been overtaken discovers it by
 * arithmetic, jumps to the oldest sequence still present, and adds what it
 * skipped to its own gap count. Loss is a number a caller can read, never a
 * silence.
 *
 * `lapped` counts SLOTS, not records, and the two are the same number only in
 * a ring where every record fits one slot. A spanned record that is overwritten
 * costs one `lapped` per slot it occupied, because by the time a reader finds
 * the hole the header that said how many slots there were is gone with it.
 * Counting records instead would mean guessing, and a count that guesses is
 * worse than one that is merely in different units.
 *
 * Needs sa_arena.h.
 */

#include "sa/sa_arena.h"
#include "sa/sa_peer.h"
#include "sa/sa_wake.h"

#define SA_RING_MAGIC 0x474E4952u    /* 'R','I','N','G' little-endian */

/* Read results. */
#define SA_READ_OK      0
#define SA_READ_PENDING 1
#define SA_READ_LAPPED  2

/* Publish results. */
#define SA_PUB_OK       1
#define SA_PUB_NORING   0
#define SA_PUB_OVERSIZE (-1)

/* Slot flags. */
#define SA_SF_HEAD      0x1u    /* the first (or only) part of a record   */
#define SA_SF_CONT      0x2u    /* a continuation                          */
#define SA_SF_ABANDONED 0x4u    /* a tombstone: the publisher died         */

typedef struct {
    /* TWO sequence words, and one is not enough - see the comment above.
     * `begin` says which record is being written into this slot, `end` says
     * which one finished. A reader is only holding a whole record when both
     * say the sequence it asked for. */
    volatile uint64_t begin;  /* written FIRST, release                   */
    volatile uint64_t end;    /* written LAST, release: the commit        */
    volatile uint64_t claim;  /* (peer << 32) | epoch. Unused until the
                               * peer table lands; it is in the layout now
                               * so adding crash attribution is not a
                               * layout change.                           */
    uint32_t tlen;            /* topic bytes  (head only)                 */
    uint32_t dlen;            /* data bytes IN THIS SLOT                  */
    uint32_t total;           /* data bytes in the whole record (head)    */
    uint32_t flags;           /* SA_SF_*                                  */
    uint16_t part;            /* 0-based                                  */
    uint16_t parts;           /* how many slots this record spans         */
    uint32_t pad;
    char     bytes[1];        /* topic then data, slot_size in total      */
} sa_slot;

/* ---- A QUEUE GROUP: ONE CURSOR, IN THE MAPPING ----------------------------
 *
 * A cursor object is process-local, so every reader holding one sees every
 * record. That is fanout, and it is the right default - but it is only half of
 * what a worker pool needs. The other half is a queue: each record delivered to
 * exactly ONE member, so N workers share the work rather than all doing it.
 *
 * THE DIFFERENCE IS WHERE THE CURSOR LIVES, and nothing else. A group's cursor
 * is in the ring's own region, so every process advancing it advances the same
 * word, and whoever wins the compare-and-swap owns that record.
 *
 * The load balancing falls out of the claim and needs no scheduler: a worker
 * busy with the last record is not in the claim loop, so it is not claiming,
 * so the free ones take the next. A lost race costs a CAS and a retry.
 *
 * CAS AND NOT FETCH-ADD, for the same reason the reservation uses one. A
 * fetch-add on a shared cursor cannot be taken back: a claimer that adds and
 * then finds it overshot the last published sequence has ALREADY moved the
 * cursor past sequences nobody has written, and those records are skipped
 * forever with nothing counted, because nothing noticed.
 *
 * ---- AT MOST ONCE, and it is a data-loss decision -------------------------
 *
 * A worker that claims a record and then dies loses it. The claim moved the
 * shared cursor and there is nothing left that says which record was in flight
 * or who had it.
 *
 * That is deliberate and it is the same answer the sibling design in Hyperman
 * gives: making it at-least-once means recording the claimant with every claim
 * and having a survivor prove it dead and re-claim, which is a queue rather
 * than a cursor and belongs in its own tenant. Choosing wrongly here is a
 * data-loss bug rather than a slow path, so it is stated beside the feature.
 *
 * ---- bound to a topic ------------------------------------------------------
 *
 * A group advances past everything, and delivers only what matches its topic.
 * Records of other topics are counted in `skipped` rather than delivered.
 * Groups do not consume from each other: each has its own cursor, so a record
 * can go to one member of every group that wants it.
 */
#define SA_GROUPS_MAX   64
#define SA_GROUP_NAME   32
#define SA_GROUP_TOPIC  32

/* EMPTY -> CLAIMING -> LIVE. The middle state is what stops a scanner reading
 * a name that is still being written: the CAS out of EMPTY is exclusive, and
 * LIVE is published last with a release. */
#define SA_G_EMPTY    0u
#define SA_G_CLAIMING 1u
#define SA_G_LIVE     2u

typedef struct {
    volatile uint32_t state;       /* SA_G_* - published LAST               */
    uint32_t          tlen;        /* bound topic length, 0 = every topic   */
    volatile uint64_t cursor;      /* THE SHARED POSITION                   */
    volatile uint64_t delivered;
    volatile uint64_t lapped;      /* records gone before anybody claimed   */
    volatile uint64_t skipped;     /* advanced past: another topic's        */
    char              name[SA_GROUP_NAME];
    char              topic[SA_GROUP_TOPIC];
} sa_group;

typedef struct {
    volatile uint32_t magic;      /* published LAST at init               */
    uint32_t          slot_size;
    uint64_t          nslots;
    uint64_t          slots_off;  /* from the RING's base, not the arena's */
    uint64_t          groups_off; /* the queue-group table, likewise      */
    uint32_t          ngroups;
    uint32_t          gpad;
    volatile uint64_t seq;        /* the next sequence to hand out        */
    volatile uint64_t published;  /* records committed                    */
    volatile uint64_t oversize;   /* records refused for size             */
    volatile unsigned char locks[SA_LOCK_STRIPES];
} sa_ring_hdr;

/* The process-local handle. As everywhere in this dist, nothing here is written
 * into shared memory: `hdr` and `slots` are this process's addresses. */
#ifndef SA_RING_FWD
#define SA_RING_FWD
typedef struct sa_ring sa_ring;
#endif

struct sa_ring {
    sa_region   *arena;
    sa_ring_hdr *hdr;
    sa_group    *groups;
    char        *slots;
    uint32_t     slot_size;
    uint64_t     nslots;
    uint64_t     payload_max;   /* topic + data that fits ONE slot        */
    uint64_t     parts_max;     /* slots one record may span              */
    uint64_t     record_max;    /* topic + data across all of them        */
};

/* A reader's position. An OBJECT, deliberately: two readers in one process must
 * not consume each other's records, and a cursor kept as a file-scope static is
 * how a second reader silently becomes a thief. Its scratch is its own, sized
 * from the ring, so a cursor can never report everything as lapped because
 * somebody else's buffer was too small. */
#ifndef SA_CURSOR_FWD
#define SA_CURSOR_FWD
typedef struct sa_cursor sa_cursor;
#endif

struct sa_cursor {
    sa_ring  *ring;
    uint64_t  seq;
    uint64_t  delivered;
    uint64_t  lapped;
    uint64_t  abandoned;   /* holes left by a publisher that died           */
    uint64_t  unattributed;/* holes nobody could be blamed for              */
    char     *scratch;
    size_t    scratch_sz;

    /* The hole this cursor is stuck on, so the escalation in sa_ring_tombstone
     * is paid once per hole rather than once per drain. Sequence 0 is never
     * used, so it doubles as "not stuck". */
    uint64_t  hole_seq;
    uint64_t  hole_next_us;
    int       hole_counted;
};

#define SA_SLOT_AT(r, n) \
    ((sa_slot *)((r)->slots + (size_t)((n) % (r)->nslots) * (r)->slot_size))

/* The bytes a slot can carry beside its header. `bytes[1]` is declared inside
 * the struct, so it is already counted once - subtracting sizeof and adding it
 * back is what makes the arithmetic exact rather than one byte pessimistic. */
static uint64_t sa_ring_capacity(uint32_t slot_size) {
    uint64_t hdr = (uint64_t)sizeof(sa_slot) - 1;
    return slot_size > hdr ? (uint64_t)slot_size - hdr : 0;
}

/* How many slots a record of this size needs, or 0 when it cannot be carried.
 *
 * The head holds the topic and as much data as then fits; every continuation
 * holds data alone. A topic too big for one slot on its own is refused, because
 * splitting the topic would mean a reader could not tell what a record was
 * about until it had gathered all of it. */
static uint64_t sa_ring_parts_for(const sa_ring *r, uint32_t tlen,
                                  uint32_t dlen) {
    uint64_t cap = r->payload_max, first, rest;
    if ((uint64_t)tlen >= cap) return 0;
    first = cap - (uint64_t)tlen;
    if ((uint64_t)dlen <= first) return 1;
    rest = (uint64_t)dlen - first;
    return 1 + (rest + cap - 1) / cap;
}

/* The queue-group table is a FIXED size and always present, which costs about
 * five kilobytes against a ring that is measured in megabytes. Sizing it per
 * ring would put a third number in every carve, in the geometry check, and in
 * both doors, to save nothing anybody would notice. */
static uint64_t sa_ring_groups_bytes(void) {
    return sa_align_up((uint64_t)SA_GROUPS_MAX * (uint64_t)sizeof(sa_group));
}

/* How much region a ring of this shape needs. */
static uint64_t sa_ring_bytes(uint64_t nslots, uint32_t slot_size) {
    return sa_align_up((uint64_t)sizeof(sa_ring_hdr))
         + sa_ring_groups_bytes()
         + nslots * (uint64_t)slot_size;
}

/* Attach this process to a ring living in a carved region, initialising it if
 * nobody has yet. Returns NULL and sets *err on refusal.
 *
 * The init race is the arena's create race one level down and takes the same
 * answer: whoever finds magic unset writes the whole header and stores magic
 * last, and everybody else spins bounded and then validates. */
static sa_ring *sa_ring_bind(sa_region *arena, sa_reg *e,
                             uint64_t nslots, uint32_t slot_size, int *err)
{
#if !SA_HAVE_ATOMICS
    (void)arena; (void)e; (void)nslots; (void)slot_size;
    if (err) *err = SA_E_NOATOMICS;
    return NULL;
#else
    sa_ring *r;
    sa_ring_hdr *h;
    uint64_t hash;

    if (err) *err = SA_E_OK;
    if (!arena || !e) { if (err) *err = SA_E_NOENT; return NULL; }

    h = (sa_ring_hdr *)sa_ptr_len(arena, e->off, sizeof(sa_ring_hdr));
    if (!h) { if (err) *err = SA_E_NOENT; return NULL; }

    if (sa_at_load32_acq(&h->magic) != SA_RING_MAGIC) {
        /* Not initialised, or not yet. One writer wins the stripe and does it;
         * the others fall through to the wait below. */
        hash = sa_at_fnv(e->name, strlen(e->name));
        if (sa_at_lock(h->locks, hash)) {
            if (sa_at_load32_acq(&h->magic) != SA_RING_MAGIC) {
                if (!nslots || !slot_size
                    || sa_ring_capacity(slot_size) == 0
                    || sa_ring_bytes(nslots, slot_size) > e->len) {
                    sa_at_unlock(h->locks, hash);
                    if (err) *err = SA_E_FULL;
                    return NULL;
                }
                memset((void *)h, 0, (size_t)sizeof(sa_ring_hdr));
                h->slot_size = slot_size;
                h->nslots    = nslots;
                h->groups_off = sa_align_up((uint64_t)sizeof(sa_ring_hdr));
                h->ngroups    = SA_GROUPS_MAX;
                h->slots_off  = h->groups_off + sa_ring_groups_bytes();
                /* Sequence 1, not 0: a cursor that has never moved sits at 1
                 * and a slot that has never been written holds 0, so the two
                 * can never be confused for one another. */
                sa_at_store64_rel(&h->seq, 1);
                sa_at_store32_rel(&h->magic, SA_RING_MAGIC);
            }
            sa_at_unlock(h->locks, hash);
        }
        if (!sa_wait_magic32(&h->magic, SA_RING_MAGIC)) {
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
    if (sa_ring_bytes(h->nslots, h->slot_size) > e->len) {
        if (err) *err = SA_E_SHORT;
        return NULL;
    }

    /* THE GEOMETRY IN THE HEADER IS ALSO SOMEBODY ELSE'S NUMBER.
     *
     * The branch above only checks a size when this process is the one doing
     * the INITIALISING. A process that finds the magic already set reads the
     * shape out of the shared header and believed it - so a header saying it
     * had four billion slots put every later read past the end of the mapping.
     * The registry entry is bounds-checked now (sa_reg_ok), which makes `len`
     * trustworthy, so this one comparison is what makes the shape trustworthy
     * too. */

    /* A caller asking for a shape the ring does not have is a caller that will
     * misread it. Say no rather than silently handing back somebody else's
     * geometry. */
    if ((nslots && h->nslots != nslots)
        || (slot_size && h->slot_size != slot_size)) {
        if (err) *err = SA_E_NAME;
        return NULL;
    }

    r = (sa_ring *)calloc(1, sizeof(sa_ring));
    if (!r) { if (err) *err = SA_E_NOMEM; return NULL; }
    r->arena       = arena;
    r->hdr         = h;
    r->groups      = (sa_group *)((char *)h + (size_t)h->groups_off);
    r->slots       = (char *)h + (size_t)h->slots_off;
    r->slot_size   = h->slot_size;
    r->nslots      = h->nslots;
    r->payload_max = sa_ring_capacity(h->slot_size);
    /* Half the ring, so a record can never overwrite its own head while it is
     * still being written. */
    r->parts_max   = h->nslots / 2;
    if (r->parts_max < 1) r->parts_max = 1;
    r->record_max  = r->payload_max * r->parts_max;
    return r;
#endif
}

static void sa_ring_free(sa_ring *r) { free(r); }

/* ---- publishing ------------------------------------------------------------ */

/* One record into one slot.
 *
 * A record too big for a slot is REFUSED, never truncated. A truncated record
 * is a lie the reader cannot detect: it has the right sequence, the right
 * topic and a body that silently is not what was sent. Refusing gives the
 * caller something it can act on, and the count is in the ring's stats.
 */
static int sa_ring_publish(sa_ring *r, const char *topic, uint32_t tlen,
                           const char *data, uint32_t dlen, uint64_t *out_seq)
{
#if !SA_HAVE_ATOMICS
    (void)r; (void)topic; (void)tlen; (void)data; (void)dlen; (void)out_seq;
    return SA_PUB_NORING;
#else
    sa_ring_hdr *h;
    sa_slot *s;
    uint64_t seq, claim = 0, parts;

    if (!r) return SA_PUB_NORING;
    h = r->hdr;

    parts = sa_ring_parts_for(r, tlen, dlen);
    if (!parts || parts > r->parts_max) {
        sa_at_fetch_add64(&h->oversize, 1);
        return SA_PUB_OVERSIZE;
    }

    /* Register, so a hole this process leaves behind can be attributed to it.
     * Lazy rather than at bind, because a fork child must take a slot of its
     * own and the fork happens after the ring is bound. */
    sa_peer_join(r->arena);
    claim = (r->arena->peer_idx >= 0)
          ? SA_CLAIM((uint32_t)r->arena->peer_idx, r->arena->peer_epoch) : 0;

    /* Raised BEFORE the reservation and lowered after the commit, so a reader
     * can ask whether any dead peer has an unfinished record even when the
     * publisher died before it could announce which one it was. */
    if (r->arena->peer_idx >= 0)
        sa_at_fetch_add64(&SA_PEERS(r->arena->map.base,
                                    r->arena->hdr)[r->arena->peer_idx].want, 1);

    /* The reservation. ONE atomic however many slots the record needs, and
     * what it returns is this publisher's alone - no other process can be
     * handed any of these sequences. */
    seq = sa_at_fetch_add64(&h->seq, parts);

    /* IN REVERSE, HEAD LAST. A reader holding a committed head is then holding
     * proof that every continuation behind it is committed too, so it gathers
     * the tail with arithmetic and never waits twice. */
    {
        uint64_t first = r->payload_max - (uint64_t)tlen;
        uint64_t i;
        for (i = parts; i-- > 0; ) {
            uint64_t off, n;
            if (i == 0) { off = 0; n = (dlen < first) ? dlen : first; }
            else {
                off = first + (i - 1) * r->payload_max;
                n   = (uint64_t)dlen - off;
                if (n > r->payload_max) n = r->payload_max;
            }
            s = SA_SLOT_AT(r, seq + i);

            /* Claim the slot before touching the body. Any reader still working
             * on the record this slot used to hold will see `begin` has moved
             * and discard what it copied, which is the half of the protocol a
             * single word cannot do. */
            sa_at_store64_rel(&s->begin, seq + i);
            sa_at_store64_rel(&s->claim, claim);
            /* THE BARRIER IS THE PROTOCOL. Without it the body below may reach
             * another CPU before the claim above does, and a reader then sees
             * new bytes under an old sequence and calls them whole. */
            sa_at_fence_rel();

            /* The test hook, and the only reason it exists: the window between
             * taking a sequence and committing it is a few instructions wide,
             * and a crash-safety test that tries to kill a process inside it by
             * luck is a test that flakes, gets marked TODO, and stops meaning
             * anything. Zero in every ordinary build and every ordinary run. */
            if (i == 0 && r->arena->hdr->stall_us)
                sa_stall(r->arena->hdr->stall_us);

            s->tlen  = (i == 0) ? tlen : 0;
            s->dlen  = (uint32_t)n;
            s->total = dlen;
            s->flags = (i == 0) ? SA_SF_HEAD : SA_SF_CONT;
            s->part  = (uint16_t)i;
            s->parts = (uint16_t)parts;
            if (i == 0 && tlen) memcpy(s->bytes, topic, tlen);
            if (n) memcpy(s->bytes + ((i == 0) ? tlen : 0), data + off,
                          (size_t)n);

            /* The commit. Everything above lands first, and a reader that sees
             * this store sees all of it. */
            sa_at_store64_rel(&s->end, seq + i);
        }
        s = SA_SLOT_AT(r, seq);
    }
    if (r->arena->peer_idx >= 0) {
        sa_peer *me = &SA_PEERS(r->arena->map.base,
                                r->arena->hdr)[r->arena->peer_idx];
        sa_at_fetch_add64(&me->want, (uint64_t)-1);
        sa_at_fetch_add64(&me->heartbeat, 1);
    }
    sa_at_fetch_add64(&h->published, 1);
    /* Tell anybody who is asleep. Only the publisher that flips a waker's flag
     * writes a byte, so a busy ring costs one wakeup per drain cycle rather
     * than one per record. */
    sa_wake_poke(r->arena);
    if (out_seq) *out_seq = seq;
    return SA_PUB_OK;
#endif
}

/* ---- reading ---------------------------------------------------------------- */

/* Copy the record at `want` into the cursor's scratch.
 *
 * The sequence is checked BEFORE and AFTER the copy. Checking only before
 * leaves a window in which a publisher laps the ring during the memcpy and the
 * reader delivers half of one record and half of another, with a sequence that
 * says it is fine.
 */
/* Make sure the cursor's scratch can hold `n` bytes. */
static int sa_cursor_room(sa_cursor *c, size_t n) {
    char *p;
    if (n <= c->scratch_sz) return 1;
    p = (char *)realloc(c->scratch, n);
    if (!p) return 0;
    c->scratch    = p;
    c->scratch_sz = n;
    return 1;
}

static int sa_ring_read(sa_cursor *c, uint64_t want,
                        const char **topic, uint32_t *tlen,
                        const char **data, uint32_t *dlen, uint32_t *flags,
                        uint64_t *span)
{
#if !SA_HAVE_ATOMICS
    (void)c; (void)want; (void)topic; (void)tlen; (void)data; (void)dlen;
    (void)flags; (void)span;
    return SA_READ_LAPPED;
#else
    sa_ring *r = c->ring;
    sa_slot *s = SA_SLOT_AT(r, want);
    uint64_t have;
    uint32_t tl, dl, total, fl;
    uint64_t parts;

    have = sa_at_load64_acq(&s->end);
    if (have < want) return SA_READ_PENDING;
    if (have > want) return SA_READ_LAPPED;

    tl    = s->tlen;
    dl    = s->dlen;
    total = s->total;
    parts = s->parts;
    fl    = s->flags;
    if (!parts) return SA_READ_LAPPED;
    if ((uint64_t)tl + (uint64_t)dl > r->payload_max) return SA_READ_LAPPED;
    if ((uint64_t)parts > r->parts_max) return SA_READ_LAPPED;
    if ((uint64_t)tl + (uint64_t)total > r->record_max) return SA_READ_LAPPED;

    /* The scratch grows to whatever this record needs and stays grown, so a
     * ring of large records costs one allocation per cursor rather than one
     * per read - and a cursor can never report a record as lapped merely
     * because its own buffer was too small, which is what a fixed buffer
     * shared between readers does. */
    if (!sa_cursor_room(c, (size_t)tl + (size_t)total)) return SA_READ_LAPPED;

    memcpy(c->scratch, s->bytes, (size_t)tl + (size_t)dl);

    /* And the reader's half: the copy above must be complete before the check
     * below, or the check is of a slot the copy had not finished reading. */
    sa_at_fence_acq();

    /* Was anybody else writing this slot while we copied? `begin` moves the
     * moment a publisher claims the slot, so a value other than `want` means
     * the bytes in scratch may be a mixture of two records - and a mixture is
     * indistinguishable from a real record once it is delivered. */
    if (sa_at_load64_acq(&s->begin) != want) return SA_READ_LAPPED;

    /* THE TAIL, gathered by arithmetic. The head was committed last, so every
     * continuation behind it was committed before it - there is nothing to wait
     * for here, only a lap to re-check. */
    if (parts > 1) {
        uint64_t got = dl, i;
        for (i = 1; i < parts; i++) {
            sa_slot *k = SA_SLOT_AT(r, want + i);
            uint32_t kn;
            if (sa_at_load64_acq(&k->end) != want + i) return SA_READ_LAPPED;
            kn = k->dlen;
            if ((uint64_t)kn > r->payload_max) return SA_READ_LAPPED;
            if (got + kn > (uint64_t)total) return SA_READ_LAPPED;
            memcpy(c->scratch + tl + got, k->bytes, (size_t)kn);
            sa_at_fence_acq();
            if (sa_at_load64_acq(&k->begin) != want + i) return SA_READ_LAPPED;
            got += kn;
        }
        if (got != (uint64_t)total) return SA_READ_LAPPED;
        dl = total;
    }

    if (flags) *flags = fl;
    if (topic) *topic = c->scratch;
    if (tlen)  *tlen  = tl;
    if (data)  *data  = c->scratch + tl;
    if (dlen)  *dlen  = dl;
    if (span)  *span  = parts;
    return SA_READ_OK;
#endif
}

static sa_cursor *sa_cursor_new(sa_ring *r, int from_start) {
    sa_cursor *c;
    if (!r) return NULL;
    c = (sa_cursor *)calloc(1, sizeof(sa_cursor));
    if (!c) return NULL;
    c->scratch_sz = (size_t)r->payload_max;
    c->scratch    = (char *)malloc(c->scratch_sz ? c->scratch_sz : 1);
    if (!c->scratch) { free(c); return NULL; }
    c->ring = r;
#if SA_HAVE_ATOMICS
    /* From the start of what is still in the ring, or from now. "From now" is
     * the right default for a tail; "from the start" is what a test wants. */
    if (from_start) {
        uint64_t end = sa_at_load64_acq(&r->hdr->seq);
        c->seq = (end > r->nslots) ? end - r->nslots : 1;
    }
    else {
        c->seq = sa_at_load64_acq(&r->hdr->seq);
    }
#else
    (void)from_start;
    c->seq = 1;
#endif
    return c;
}

static void sa_cursor_free(sa_cursor *c) {
    if (!c) return;
    free(c->scratch);
    free(c);
}

/* Has this cursor been overtaken? If so, move it to the oldest sequence still
 * present and count everything skipped.
 *
 * `end - nslots` is the oldest sequence the ring can still hold: anything
 * before it has been overwritten by definition, whatever the slot says. */
static uint64_t sa_cursor_catchup(sa_cursor *c) {
#if !SA_HAVE_ATOMICS
    (void)c;
    return 0;
#else
    sa_ring *r = c->ring;
    uint64_t end = sa_at_load64_acq(&r->hdr->seq);
    uint64_t oldest, missed;

    if (end <= r->nslots) return 0;
    oldest = end - r->nslots;
    if (c->seq >= oldest) return 0;

    missed  = oldest - c->seq;
    c->lapped += missed;
    c->seq     = oldest;
    return missed;
#endif
}

/* ---- a hole, and who is to blame for it -------------------------------------
 *
 * A reader that finds sequence `want` uncommitted cannot simply wait, and
 * cannot simply skip. This is the escalation: cheap first, and a syscall only
 * once the cheap answers have run out.
 *
 *   1. spin      - the overwhelming case is a publisher two memcpys from done
 *   2. sleep     - the grace period, so an ordinary preemption is just a wait
 *   3. ask       - who claimed this slot, and is that process gone
 *
 * Step 3 is the one a timeout cannot do, and it is why this waits on a QUESTION
 * rather than on a clock.
 *
 * When the answer is yes, the reader does not skip the hole - it FILLS it, with
 * a well-formed record carrying SA_SF_ABANDONED. That is the move that matters:
 * every other reader, present and future, then passes the hole by READING it,
 * so no timeout is left anywhere in anybody's steady-state path. A skip would
 * have to be rediscovered, and paid for, by every cursor separately.
 *
 * Returns 1 when the hole was filled and the caller should read it again.
 */
static int sa_ring_tombstone(sa_cursor *c, uint64_t want) {
#if !SA_HAVE_ATOMICS
    (void)c; (void)want;
    return 0;
#else
    sa_ring *r = c->ring;
    sa_slot *s = SA_SLOT_AT(r, want);
    sa_region *a = r->arena;
    uint64_t claim, hb0;
    uint32_t grace;
    long spin;

    /* ---- THE ESCALATION IS PER HOLE, NOT PER VISIT -------------------------
     *
     * A drain that finds an unfilled hole stops there, so the NEXT drain
     * arrives at the same sequence - and the first version paid the whole
     * escalation again every time: two thousand spins, a sleep of the full
     * grace period, and a walk of up to 256 peers calling kill() on each. A
     * caller draining in an event loop therefore slept 250ms per turn for as
     * long as the hole lasted, which is the opposite of what a bounded wait is
     * for. It also counted `unattributed` once per VISIT, so a single hole
     * inflated the number that exists to tell you how rare this is.
     *
     * So the cursor remembers which sequence it is stuck on and when it is
     * worth asking again. The cheap check still runs every time - a record
     * that landed is picked up immediately - and only the expensive half is
     * rate-limited to once per grace period. */
    if (c->hole_seq != want) {
        c->hole_seq     = want;
        c->hole_next_us = 0;
        c->hole_counted = 0;
    }

    for (spin = 0; spin < 2000; spin++) {
        if (sa_at_load64_acq(&s->end) == want) {           /* it landed */
            c->hole_seq = 0;
            return 0;
        }
    }

    /* Asked recently, and the answer cannot have changed: the heartbeat test
     * below needs a grace period to have passed before it means anything. */
    if (c->hole_next_us && sa_now_us() < c->hole_next_us) return 0;

    claim = sa_at_load64_acq(&s->claim);
    hb0   = sa_peer_hb(a, claim);
    grace = sa_at_load32_acq(&a->hdr->reap_grace_us);

    sa_stall(grace ? grace : 1000);
    if (sa_at_load64_acq(&s->end) == want) {
        c->hole_seq = 0;
        return 0;
    }
    c->hole_next_us = sa_now_us() + (uint64_t)(grace ? grace : 1000);

    /* Re-read: a publisher may have claimed the slot during the wait, in which
     * case the claim we started from is the wrong one to judge. */
    claim = sa_at_load64_acq(&s->claim);
    if (!sa_peer_is_dead(a, claim, hb0)) {
        /* Nobody provably dead. If SOME dead peer has an uncommitted
         * reservation, this hole is very likely theirs and waiting for ever is
         * worse than counting it - but say so separately, because a non-zero
         * unattributed count means this design has a gap and the number is how
         * anybody would ever find out. Counted ONCE for this hole, however many
         * times the cursor comes back to it. */
        if (!c->hole_counted && sa_peer_any_dead_pending(a)) {
            c->unattributed++;
            c->hole_counted = 1;
        }
        return 0;
    }

    (void)sa_peer_reap(a, claim);

    /* The same protocol a real record uses, because this IS a real record. */
    sa_at_store64_rel(&s->begin, want);
    sa_at_store64_rel(&s->claim, 0);
    sa_at_fence_rel();
    s->tlen  = 0;
    s->dlen  = 0;
    s->total = 0;
    s->flags = SA_SF_HEAD | SA_SF_ABANDONED;
    s->part  = 0;
    s->parts = 1;
    sa_at_store64_rel(&s->end, want);
    c->hole_seq = 0;
    return 1;
#endif
}

#ifndef SA_REC_FN_FWD
#define SA_REC_FN_FWD
typedef void (*sa_rec_fn)(void *ud, uint64_t seq,
                          const char *topic, uint32_t tlen,
                          const char *data, uint32_t dlen, uint32_t flags);
#endif

/* Everything published since this cursor last looked, up to `max` records.
 * Returns how many were delivered.
 *
 * Stops at the first PENDING rather than waiting: an uncommitted slot means a
 * publisher is mid-write, and the caller is better off coming back than
 * blocking a whole event loop on one memcpy.
 */
static long sa_cursor_drain(sa_cursor *c, long max, sa_rec_fn cb, void *ud) {
#if !SA_HAVE_ATOMICS
    (void)c; (void)max; (void)cb; (void)ud;
    return 0;
#else
    sa_ring *r;
    uint64_t end;
    long n = 0;

    if (!c || !cb) return 0;
    r = c->ring;
    sa_cursor_catchup(c);
    end = sa_at_load64_acq(&r->hdr->seq);

    while (c->seq < end && (max <= 0 || n < max)) {
        const char *topic = NULL, *data = NULL;
        uint32_t tlen = 0, dlen = 0, flags = 0;
        uint64_t span = 1;
        int rc = sa_ring_read(c, c->seq, &topic, &tlen, &data, &dlen, &flags,
                              &span);

        if (rc == SA_READ_PENDING) {
            if (!sa_ring_tombstone(c, c->seq)) break;
            rc = sa_ring_read(c, c->seq, &topic, &tlen, &data, &dlen, &flags,
                              &span);
            if (rc != SA_READ_OK) break;
        }
        if (rc == SA_READ_LAPPED) { c->lapped++; c->seq++; continue; }
        if (flags & SA_SF_CONT) {
            /* A continuation reached on its own means its HEAD was missed -
             * a delivered record jumps the cursor past its own tail, so these
             * are only ever seen when the record they belong to was lost.
             *
             * Counted as lapped, and that is what keeps the accounting exact:
             * `lapped` is in SLOTS, a lost record cost as many slots as it
             * spanned, and skipping these silently would leave the difference
             * unexplained in every ring that carries a record bigger than a
             * slot.
             *
             * This flag, not the `seq += span` below, is what makes spanning
             * safe: a cursor advancing one slot at a time would land on every
             * continuation and skip it here, arriving at the same place. The
             * span is an optimisation. */
            c->lapped++;
            c->seq++;
            continue;
        }
        if (flags & SA_SF_ABANDONED) { c->abandoned++; c->seq++; continue; }

        cb(ud, c->seq, topic, tlen, data, dlen, flags);
        c->delivered++;
        c->seq += span;
        n++;
    }
    return n;
#endif
}

/* ---- queue groups ---------------------------------------------------------- */

/* The process-local half of a group. As everywhere in this dist, nothing here
 * is written into the mapping: `g` is this process's address for the shared
 * record, and `claimed` is this member's own tally rather than the pool's. */
#ifndef SA_GROUP_H_FWD
#define SA_GROUP_H_FWD
typedef struct sa_group_h sa_group_h;
#endif

struct sa_group_h {
    sa_ring   *ring;
    sa_group  *g;
    sa_cursor *scratch;
    uint64_t   claimed;
};

#if SA_HAVE_ATOMICS

/* Find the group of this name, or make it.
 *
 * The stripe lock covers the search and the claim, so two processes asking for
 * the same name cannot both create it - which would be two groups with one
 * name, each delivering half the work to somebody who thought they were in the
 * other. The same reasoning, and the same lock, as carving a region.
 *
 * A group that already exists is checked against the topic asked for. Two
 * callers disagreeing about which topic a group consumes is worse than either
 * of them failing, for the same reason a ring checks its geometry. */
static sa_group *sa_group_bind(sa_ring *r, const char *name, uint32_t nlen,
                               const char *topic, uint32_t tlen,
                               uint64_t from, int *err)
{
    sa_ring_hdr *h;
    uint64_t hash;
    uint32_t i, n;

    if (err) *err = SA_E_OK;
    if (!r) { if (err) *err = SA_E_NOENT; return NULL; }
    if (!name || !nlen || nlen >= SA_GROUP_NAME
        || tlen >= SA_GROUP_TOPIC) {
        if (err) *err = SA_E_NAME;
        return NULL;
    }

    h = r->hdr;
    n = h->ngroups > SA_GROUPS_MAX ? SA_GROUPS_MAX : h->ngroups;
    hash = sa_at_fnv(name, (size_t)nlen);

    if (!sa_at_lock(h->locks, hash)) { if (err) *err = SA_E_FULL; return NULL; }

    for (i = 0; i < n; i++) {
        sa_group *g = &r->groups[i];
        if (sa_at_load32_acq(&g->state) != SA_G_LIVE) continue;
        if (strncmp(g->name, name, nlen) || g->name[nlen]) continue;
        sa_at_unlock(h->locks, hash);
        if (g->tlen != tlen
            || (tlen && memcmp(g->topic, topic, tlen))) {
            if (err) *err = SA_E_SHAPE;
            return NULL;
        }
        return g;
    }

    for (i = 0; i < n; i++) {
        sa_group *g = &r->groups[i];
        if (!sa_at_cas32(&g->state, SA_G_EMPTY, SA_G_CLAIMING)) continue;
        memset(g->name, 0, SA_GROUP_NAME);
        memcpy(g->name, name, nlen);
        memset(g->topic, 0, SA_GROUP_TOPIC);
        if (tlen) memcpy(g->topic, topic, tlen);
        g->tlen = tlen;
        sa_at_store64_rel(&g->delivered, 0);
        sa_at_store64_rel(&g->lapped, 0);
        sa_at_store64_rel(&g->skipped, 0);
        /* From now, not from the beginning: a worker joining a pool wants the
         * work that arrives after it, not a replay of everything the ring still
         * happens to hold. `from` overrides it for a caller that wants one. */
        sa_at_store64_rel(&g->cursor,
                          from ? from : sa_at_load64_acq(&h->seq));
        sa_at_store32_rel(&g->state, SA_G_LIVE);
        sa_at_unlock(h->locks, hash);
        return g;
    }

    sa_at_unlock(h->locks, hash);
    if (err) *err = SA_E_FULL;
    return NULL;
}

/* The handle both doors use, so the Perl surface and the C ABI cannot differ
 * about what opening a group means. The scratch cursor is for the record
 * buffer and the hole machinery; its own position is never consulted. */
static sa_group_h *sa_group_new(sa_ring *r, const char *name, uint32_t nlen,
                                const char *topic, uint32_t tlen,
                                uint64_t from, int *err)
{
    sa_group_h *gh;
    sa_group *g = sa_group_bind(r, name, nlen, topic, tlen, from, err);
    if (!g) return NULL;
    gh = (sa_group_h *)calloc(1, sizeof(sa_group_h));
    if (!gh) { if (err) *err = SA_E_NOMEM; return NULL; }
    gh->scratch = sa_cursor_new(r, 0);
    if (!gh->scratch) { free(gh); if (err) *err = SA_E_NOMEM; return NULL; }
    gh->ring = r;
    gh->g    = g;
    return gh;
}

/* Leaving is not releasing. The group in the mapping outlives this member:
 * another worker is still claiming from that cursor, and a member that exits
 * must not take the pool's position with it. */
static void sa_group_free(sa_group_h *gh) {
    if (!gh) return;
    if (gh->scratch) sa_cursor_free(gh->scratch);
    free(gh);
}

/* Take the next record for this group, or report that there is none.
 *
 * `scratch` is a process-local cursor, used only for its buffer and for the
 * hole machinery - its own position is never consulted, because the position
 * that matters is the group's and that one is shared.
 *
 * Returns SA_READ_OK with the record filled in, or SA_READ_PENDING when there
 * is nothing to take. `*seq` is the sequence claimed.
 */
static int sa_group_claim(sa_ring *r, sa_group *g, sa_cursor *scratch,
                          uint64_t *seq, const char **topic, uint32_t *tlen,
                          const char **data, uint32_t *dlen, uint32_t *flags)
{
    sa_ring_hdr *h;
    long guard;

    if (!r || !g || !scratch) return SA_READ_PENDING;
    h = r->hdr;

    /* Bounded, because every loop in this dist is. Each turn either claims,
     * advances past something, or loses a race to somebody who did - so this
     * cannot spin without the ring moving, and the bound is only there so a
     * pathological interleaving cannot hold a worker for ever. */
    for (guard = 0; guard < 1024; guard++) {
        uint64_t cur = sa_at_load64_acq(&g->cursor);
        uint64_t end = sa_at_load64_acq(&h->seq);
        uint64_t span = 1, oldest;
        const char *tp = NULL, *dp = NULL;
        uint32_t tl = 0, dl = 0, fl = 0;
        int rc;

        if (cur >= end) return SA_READ_PENDING;      /* nothing published */

        /* Overtaken. `end - nslots` is the oldest sequence the ring can still
         * hold, whatever the slots say, so the group jumps there and counts
         * what it never saw. Losing this CAS is fine: somebody else did it. */
        oldest = (end > r->nslots) ? end - r->nslots : 1;
        if (cur < oldest) {
            if (sa_at_cas64(&g->cursor, cur, oldest))
                sa_at_fetch_add64(&g->lapped, oldest - cur);
            continue;
        }

        /* Look before claiming, because the span decides how far the cursor
         * moves and only the head knows it. */
        rc = sa_ring_read(scratch, cur, &tp, &tl, &dp, &dl, &fl, &span);

        if (rc == SA_READ_PENDING) {
            /* A hole: a publisher is mid-write, or died mid-write. The same
             * escalation the fanout door uses - and it has to be here too,
             * because a pool with no fanout reader would otherwise wait on a
             * dead process for ever. */
            if (!sa_ring_tombstone(scratch, cur)) return SA_READ_PENDING;
            continue;
        }
        if (rc == SA_READ_LAPPED || (fl & SA_SF_CONT)) {
            /* Gone, or the tail of a record whose head somebody else took.
             * Advance one and let the next turn look again. */
            if (sa_at_cas64(&g->cursor, cur, cur + 1) && rc == SA_READ_LAPPED)
                sa_at_fetch_add64(&g->lapped, 1);
            continue;
        }

        /* THE CLAIM. Exactly one process wins this, and that is the whole
         * mechanism: whoever wins owns `cur` and everybody else moves on. */
        if (!sa_at_cas64(&g->cursor, cur, cur + span)) continue;

        /* We own it - but the read above happened BEFORE the claim, and a
         * publisher may have lapped the ring in between. Read it again now
         * that it is ours; a record that went during the claim is a loss this
         * group counts rather than a body it delivers. */
        rc = sa_ring_read(scratch, cur, &tp, &tl, &dp, &dl, &fl, &span);
        if (rc != SA_READ_OK) {
            sa_at_fetch_add64(&g->lapped, 1);
            continue;
        }
        if (fl & SA_SF_ABANDONED) {
            sa_at_fetch_add64(&g->lapped, 1);
            continue;
        }

        /* Bound to a topic: advance past anything else rather than delivering
         * it. Another group with another topic has its own cursor and will see
         * this record itself. */
        if (g->tlen && (tl != g->tlen || memcmp(tp, g->topic, tl))) {
            sa_at_fetch_add64(&g->skipped, 1);
            continue;
        }

        sa_at_fetch_add64(&g->delivered, 1);
        if (seq)   *seq   = cur;
        if (topic) *topic = tp;
        if (tlen)  *tlen  = tl;
        if (data)  *data  = dp;
        if (dlen)  *dlen  = dl;
        if (flags) *flags = fl;
        return SA_READ_OK;
    }
    return SA_READ_PENDING;
}

#else /* !SA_HAVE_ATOMICS */

/* No atomics, so no group: sa_group_new is not compiled and the XS refuses to
 * make one. Releasing touches nothing shared, though, so the release is the
 * same one, here so that DESTROY and the ABI table have it in this build. */
static void sa_group_free(sa_group_h *gh) {
    if (!gh) return;
    if (gh->scratch) sa_cursor_free(gh->scratch);
    free(gh);
}

#endif /* SA_HAVE_ATOMICS */

#endif /* SA_RING_H */
