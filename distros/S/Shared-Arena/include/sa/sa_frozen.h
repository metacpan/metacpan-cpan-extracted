#ifndef SA_FROZEN_H
#define SA_FROZEN_H

/* sa_frozen.h - a block of bytes republished in place, read by everyone at
 * once. Perl-free, and Frozen-free: this file knows nothing about what is in
 * the bytes.
 *
 * ---- what this is for -------------------------------------------------------
 *
 * Everything else in this dist stores values a caller has already flattened:
 * keys and values are opaque bytes, so a nested structure has to be serialised
 * on the way in and rebuilt on the way out. Rebuilding is the expensive half,
 * and it happens on EVERY read.
 *
 * A Frozen block is not rebuilt. It is a flat, offset-addressed structure whose
 * fields are read where they lie, so a reader looks up one key without
 * materialising the other ten thousand. That is a different shape of thing from
 * a map, and it wants a different tenant: one big value that changes rarely and
 * is read constantly, rather than many small ones that change all the time.
 *
 * Configuration, routing tables, feature flags, a compiled ruleset. The block is
 * built once by whoever has the data and read by every worker for the life of
 * the process.
 *
 * ---- publishing without stopping the readers -------------------------------
 *
 * A block cannot be edited in place. It is offset-addressed throughout, so a
 * change to one string moves everything after it, and a reader halfway through
 * such an edit would follow an offset into the middle of something else.
 *
 * So a publish never touches the block anybody is reading. The region holds
 * SEVERAL slots, and a publish writes the new block into the slot furthest from
 * use, then points `current` at it with a release store. A reader takes
 * `current` with an acquire load and reads that slot. Neither waits for the
 * other, and no reader ever sees a half-written block.
 *
 * ---- what a reader has to accept -------------------------------------------
 *
 * A view borrows the bytes where they lie. It does not copy them, which is the
 * whole reason this is faster than handing the same structure through a pipe -
 * and it means the bytes are not the reader's to keep.
 *
 * After `slots` further publishes the slot a view is reading is reused. The
 * view then reads a DIFFERENT block: still a structurally valid one, still
 * inside its own bounds, but not the one it was opened on. Every slot carries
 * the generation it was written with, so a reader can ask whether the ground
 * moved under it, and that is what `sa_frozen_fresh` is for.
 *
 * The rule that follows is short: take a view, read it, drop it. A view held
 * across a config reload is the one thing this cannot make safe, and a view
 * taken per request costs a borrow.
 *
 * ---- publishing takes the lock, and that is fine ---------------------------
 *
 * A publish copies a whole block, so it is already thousands of times the cost
 * of the compare-and-swap that would let two of them race. Two processes
 * publishing at once want serialising anyway - they disagree about what the
 * configuration is, and the answer is that one of them wins outright rather
 * than that the slots interleave.
 *
 * Reads take nothing. That is the half that had to be free.
 *
 * Needs sa_arena.h.
 */

#include "sa/sa_arena.h"

#define SA_FROZEN_MAGIC 0x5A4F5246u    /* 'F','R','O','Z' little-endian */

#define SA_FROZEN_MIN_SLOTS 2
#define SA_FROZEN_MAX_SLOTS 16

/* Written before the bytes, read after them. `gen` is what tells a reader
 * whether the slot still holds what it opened. */
typedef struct {
    volatile uint64_t len;
    volatile uint64_t gen;
} sa_frozen_slot;

typedef struct {
    volatile uint32_t magic;      /* published LAST at init                  */
    uint32_t          nslots;
    uint64_t          slot_bytes; /* the most one block may be               */
    uint64_t          slots_off;  /* from the TENANT's base                  */
    volatile uint64_t generation; /* bumped once per publish, never reused   */
    volatile uint32_t current;    /* the slot a reader should take           */
    uint32_t          pad;
    volatile uint64_t published;
    volatile uint64_t refused;    /* did not fit a slot                      */
    volatile unsigned char locks[SA_LOCK_STRIPES];
} sa_frozen_hdr;

typedef struct sa_frozen {
    sa_region      *arena;
    sa_frozen_hdr  *hdr;
    unsigned char  *slots;        /* nslots * (slot header + slot_bytes)     */
    uint32_t        nslots;
    uint64_t        slot_bytes;
} sa_frozen;

#define SA_FZ_OK      0
#define SA_FZ_EMPTY (-1)          /* nothing has been published yet          */
#define SA_FZ_BIG   (-2)          /* the block does not fit a slot           */

/* One slot is its header, then the block, aligned so the block starts on the
 * arena's alignment - a structure read in place should not be read across an
 * unaligned boundary on the platforms that care. */
static uint64_t sa_frozen_stride(uint64_t slot_bytes) {
    return sa_align_up((uint64_t)sizeof(sa_frozen_slot))
         + sa_align_up(slot_bytes);
}

static uint64_t sa_frozen_bytes(uint64_t slot_bytes, uint32_t nslots) {
    return sa_align_up((uint64_t)sizeof(sa_frozen_hdr))
         + sa_frozen_stride(slot_bytes) * (uint64_t)nslots;
}

static sa_frozen_slot *sa_frozen_slot_at(sa_frozen *f, uint32_t i) {
    return (sa_frozen_slot *)(f->slots
        + (size_t)(sa_frozen_stride(f->slot_bytes) * (uint64_t)i));
}

static unsigned char *sa_frozen_body_at(sa_frozen *f, uint32_t i) {
    return (unsigned char *)sa_frozen_slot_at(f, i)
         + (size_t)sa_align_up((uint64_t)sizeof(sa_frozen_slot));
}

static sa_frozen *sa_frozen_bind(sa_region *arena, sa_reg *e,
                                 uint64_t slot_bytes, uint32_t nslots, int *err)
{
#if !SA_HAVE_ATOMICS
    (void)arena; (void)e; (void)slot_bytes; (void)nslots;
    if (err) *err = SA_E_NOATOMICS;
    return NULL;
#else
    sa_frozen *f;
    sa_frozen_hdr *h;
    uint64_t hash;

    if (err) *err = SA_E_OK;
    if (!arena || !e) { if (err) *err = SA_E_NOENT; return NULL; }

    h = (sa_frozen_hdr *)sa_ptr_len(arena, e->off, sizeof(sa_frozen_hdr));
    if (!h) { if (err) *err = SA_E_NOENT; return NULL; }

    if (sa_at_load32_acq(&h->magic) != SA_FROZEN_MAGIC) {
        hash = sa_at_fnv(e->name, strlen(e->name));
        if (sa_at_lock(h->locks, hash)) {
            if (sa_at_load32_acq(&h->magic) != SA_FROZEN_MAGIC) {
                if (!slot_bytes || nslots < SA_FROZEN_MIN_SLOTS
                    || nslots > SA_FROZEN_MAX_SLOTS
                    || sa_frozen_bytes(slot_bytes, nslots) > e->len) {
                    sa_at_unlock(h->locks, hash);
                    if (err) *err = SA_E_FULL;
                    return NULL;
                }
                memset((void *)h, 0,
                       (size_t)sa_frozen_bytes(slot_bytes, nslots));
                h->nslots     = nslots;
                h->slot_bytes = slot_bytes;
                h->slots_off  = sa_align_up((uint64_t)sizeof(sa_frozen_hdr));
                sa_at_store32_rel(&h->magic, SA_FROZEN_MAGIC);
            }
            sa_at_unlock(h->locks, hash);
        }
        if (!sa_wait_magic32(&h->magic, SA_FROZEN_MAGIC)) {
            if (err) *err = SA_E_MAGIC;
            return NULL;
        }
    }

    /* A caller asking for a shape this does not have would be reading somebody
     * else's blocks through the wrong arithmetic. Say no, as every other
     * tenant does. */
    if ((slot_bytes && h->slot_bytes != slot_bytes)
        || (nslots && h->nslots != nslots)) {
        if (err) *err = SA_E_SHAPE;
        return NULL;
    }

    f = (sa_frozen *)calloc(1, sizeof(sa_frozen));
    if (!f) { if (err) *err = SA_E_NOMEM; return NULL; }
    f->arena      = arena;
    f->hdr        = h;
    f->slots      = (unsigned char *)h + (size_t)h->slots_off;
    f->nslots     = h->nslots;
    f->slot_bytes = h->slot_bytes;
    return f;
#endif
}

static void sa_frozen_free(sa_frozen *f) { free(f); }

/* Put a block in the slot furthest from use and point `current` at it.
 *
 * The generation is taken INSIDE the lock and never reused, so a reader that
 * remembers one can always tell whether the slot it holds is still that
 * generation's. */
static int sa_frozen_publish(sa_frozen *f, const void *bytes, uint64_t len,
                             uint64_t *gen_out)
{
#if SA_HAVE_ATOMICS
    sa_frozen_hdr *h = f->hdr;
    uint64_t hash = (uint64_t)(uintptr_t)h;
    uint32_t next;
    uint64_t gen;
    sa_frozen_slot *s;

    if (gen_out) *gen_out = 0;
    if (len > f->slot_bytes) {
        sa_at_fetch_add64(&h->refused, 1);
        return SA_FZ_BIG;
    }
    /* Waits rather than spins: publishing is rare, and `refused` is documented
     * as meaning a block did not FIT. A refusal because a spin ran out would be
     * the same number meaning something else entirely. */
    if (!sa_lock_wait(h->locks, hash)) {
        sa_at_fetch_add64(&h->refused, 1);
        return SA_FZ_BIG;
    }

    /* The slot after the live one, which is the one no reader has been sent to
     * for the longest. */
    next = (uint32_t)((sa_at_load32_acq(&h->current) + 1u) % f->nslots);
    s    = sa_frozen_slot_at(f, next);
    gen  = sa_at_load64_acq(&h->generation) + 1u;

    /* Length first, then the bytes, then the generation, then `current`. A
     * reader that arrives partway through this sees the slot's OLD generation
     * and the old `current`, so it reads the old block - which is whole. */
    sa_at_store64_rel(&s->len, len);
    memcpy(sa_frozen_body_at(f, next), bytes, (size_t)len);
    sa_at_fence_rel();
    sa_at_store64_rel(&s->gen, gen);
    sa_at_store64_rel(&h->generation, gen);
    sa_at_store32_rel(&h->current, next);
    sa_at_fetch_add64(&h->published, 1);

    sa_at_unlock(h->locks, hash);
    if (gen_out) *gen_out = gen;
    return SA_FZ_OK;
#else
    (void)f; (void)bytes; (void)len; (void)gen_out;
    return SA_FZ_BIG;
#endif
}

/* The live block: where it is, how long, and which generation it is.
 *
 * The pointer is INTO THE ARENA and is not the caller's to free or to keep. */
static int sa_frozen_current(sa_frozen *f, const unsigned char **bytes,
                             uint64_t *len, uint64_t *gen, uint32_t *slot)
{
#if SA_HAVE_ATOMICS
    uint32_t i;
    sa_frozen_slot *s;

    if (!sa_at_load64_acq(&f->hdr->generation)) return SA_FZ_EMPTY;

    i = sa_at_load32_acq(&f->hdr->current);
    if (i >= f->nslots) return SA_FZ_EMPTY;
    s = sa_frozen_slot_at(f, i);

    sa_at_fence_acq();
    if (len)   *len   = sa_at_load64_acq(&s->len);
    if (gen)   *gen   = sa_at_load64_acq(&s->gen);
    if (slot)  *slot  = i;
    if (bytes) *bytes = sa_frozen_body_at(f, i);
    return SA_FZ_OK;
#else
    (void)f; (void)bytes; (void)len; (void)gen; (void)slot;
    return SA_FZ_EMPTY;
#endif
}

/* Whether a slot still holds the generation a reader opened it on.
 *
 * This is the whole of what a borrowed view can be told. It cannot be prevented
 * from going stale - the bytes belong to the arena - but it can always find
 * out, and a reader that checks after reading knows whether to read again. */
static int sa_frozen_fresh(sa_frozen *f, uint32_t slot, uint64_t gen) {
#if SA_HAVE_ATOMICS
    if (slot >= f->nslots) return 0;
    return sa_at_load64_acq(&sa_frozen_slot_at(f, slot)->gen) == gen;
#else
    (void)f; (void)slot; (void)gen;
    return 0;
#endif
}

#endif /* SA_FROZEN_H */
