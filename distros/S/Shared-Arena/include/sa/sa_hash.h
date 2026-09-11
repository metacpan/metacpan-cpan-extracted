#ifndef SA_HASH_H
#define SA_HASH_H

/* sa_hash.h - a fixed-capacity map several processes share. Perl-free.
 *
 * Open addressing with linear probing, in one carved region. Readers take no
 * lock at all; writers take one of a stripe of spinlocks, so two writers
 * touching different keys almost never meet.
 *
 * ---- fixed capacity, and no growth ------------------------------------------
 *
 * The table is sized once and never rehashes. That is not a simplification to
 * be fixed later: growing a table several processes are reading means moving
 * entries other processes are mid-probe on, and the only safe ways to do that
 * are to stop the world or to keep both tables alive until every reader has
 * left. Neither belongs in something whose whole point is that a read is a hash
 * and a compare.
 *
 * So a full table REFUSES a new key. `used` and `capacity` are in the stats,
 * and a caller that reaches the ceiling wanted a bigger table.
 *
 * ---- tombstones, and what deleting costs -----------------------------------
 *
 * A deleted entry becomes a tombstone rather than empty, because an empty slot
 * stops a probe and a probe that stops early cannot find a key that was placed
 * past it. Tombstones are reused by the next insert that probes over them, but
 * they are never swept: a workload that deletes constantly will fill the table
 * with them and start refusing keys while `used` looks low. `tombstones` is in
 * the stats so that is visible rather than mysterious.
 *
 * ---- reading without a lock -------------------------------------------------
 *
 * A value is read while another process may be replacing it, so each slot
 * carries a VERSION: odd while being written, even when settled, and a reader
 * takes it before and after copying. Same discipline as the ring's two
 * sequence words and for the same reason - and, as there, a release store is
 * not enough on its own. It orders what came before it and says nothing about
 * the writes that follow, so the barriers are explicit. Getting that wrong
 * produces whole, plausible values that belong to neither the old entry nor the
 * new one, which is the hardest kind of bug to see.
 *
 * A reader that keeps losing the race gives up after a bounded number of tries
 * and counts a `busy`. It does NOT report the key as missing: absent and
 * could-not-read are different answers, and conflating them is how a caller
 * ends up believing a key was deleted when a writer was simply mid-update.
 *
 * Needs sa_arena.h.
 */

#include "sa/sa_arena.h"

#define SA_HASH_MAGIC 0x5048534Du    /* 'M','S','H','P' little-endian */

/* slot states. EMPTY stops a probe; DEAD does not. */
#define SA_H_EMPTY 0u
#define SA_H_LIVE  1u
#define SA_H_DEAD  2u

/* what a lookup answers */
#define SA_H_HIT   0
#define SA_H_MISS  1
#define SA_H_BUSY  2

/* what a store answers */
#define SA_H_OK       1
#define SA_H_FULL     0
#define SA_H_TOOBIG (-1)
#define SA_H_NOTNUM (-2)   /* incr on an entry that is not a counter */

/* How many times a reader retries a slot whose writer is mid-update before it
 * gives up and counts a busy. A writer holds a slot odd for one memcpy, so
 * this is generous by orders of magnitude; the bound exists so a writer that
 * died mid-update cannot wedge a reader for ever. */
#define SA_HASH_SPIN 10000

typedef struct {
    volatile uint32_t state;    /* SA_H_*                                   */
    volatile uint32_t version;  /* odd = being written                      */
    volatile uint32_t klen;
    volatile uint32_t vlen;
    volatile uint64_t tag;      /* the hash, so most probes skip the memcmp */
    char              bytes[1]; /* key then value, slot_size in total       */
} sa_hash_slot;

typedef struct {
    volatile uint32_t magic;      /* published LAST at init                 */
    uint32_t          slot_size;
    uint64_t          nslots;
    uint64_t          slots_off;  /* from the MAP's base                    */
    volatile uint64_t used;       /* live entries                           */
    volatile uint64_t tombstones;
    volatile uint64_t busy;       /* reads that gave up mid-update          */
    volatile uint64_t full;       /* stores refused for want of room        */
    volatile unsigned char locks[SA_LOCK_STRIPES];
} sa_hash_hdr;

typedef struct sa_hash {
    sa_region   *arena;
    sa_hash_hdr *hdr;
    char        *slots;
    uint32_t     slot_size;
    uint64_t     nslots;
    uint64_t     pair_max;    /* key + value that fits one slot */
} sa_hash;

#define SA_HSLOT_AT(m, i) \
    ((sa_hash_slot *)((m)->slots + (size_t)((i) % (m)->nslots) * (m)->slot_size))

static uint64_t sa_hash_capacity(uint32_t slot_size) {
    uint64_t hdr = (uint64_t)sizeof(sa_hash_slot) - 1;
    return slot_size > hdr ? (uint64_t)slot_size - hdr : 0;
}

static uint64_t sa_hash_bytes(uint64_t nslots, uint32_t slot_size) {
    return sa_align_up((uint64_t)sizeof(sa_hash_hdr))
         + nslots * (uint64_t)slot_size;
}

/* Attach to a map in a carved region, initialising it if nobody has yet. The
 * init race takes the same answer as everywhere else: whoever finds magic unset
 * writes the header and stores magic last, and the rest wait bounded. */
static sa_hash *sa_hash_bind(sa_region *arena, sa_reg *e,
                             uint64_t nslots, uint32_t slot_size, int *err)
{
#if !SA_HAVE_ATOMICS
    (void)arena; (void)e; (void)nslots; (void)slot_size;
    if (err) *err = SA_E_NOATOMICS;
    return NULL;
#else
    sa_hash *m;
    sa_hash_hdr *h;
    uint64_t hash;

    if (err) *err = SA_E_OK;
    if (!arena || !e) { if (err) *err = SA_E_NOENT; return NULL; }

    h = (sa_hash_hdr *)sa_ptr_len(arena, e->off, sizeof(sa_hash_hdr));
    if (!h) { if (err) *err = SA_E_NOENT; return NULL; }

    if (sa_at_load32_acq(&h->magic) != SA_HASH_MAGIC) {
        hash = sa_at_fnv(e->name, strlen(e->name));
        if (sa_at_lock(h->locks, hash)) {
            if (sa_at_load32_acq(&h->magic) != SA_HASH_MAGIC) {
                if (!nslots || !slot_size
                    || sa_hash_capacity(slot_size) == 0
                    || sa_hash_bytes(nslots, slot_size) > e->len) {
                    sa_at_unlock(h->locks, hash);
                    if (err) *err = SA_E_FULL;
                    return NULL;
                }
                memset((void *)h, 0, (size_t)sizeof(sa_hash_hdr));
                h->slot_size = slot_size;
                h->nslots    = nslots;
                h->slots_off = sa_align_up((uint64_t)sizeof(sa_hash_hdr));
                sa_at_store32_rel(&h->magic, SA_HASH_MAGIC);
            }
            sa_at_unlock(h->locks, hash);
        }
        if (!sa_wait_magic32(&h->magic, SA_HASH_MAGIC)) {
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

    if ((nslots && h->nslots != nslots)
        || (slot_size && h->slot_size != slot_size)) {
        if (err) *err = SA_E_NAME;
        return NULL;
    }

    m = (sa_hash *)calloc(1, sizeof(sa_hash));
    if (!m) { if (err) *err = SA_E_NOMEM; return NULL; }
    m->arena     = arena;
    m->hdr       = h;
    m->slots     = (char *)h + (size_t)h->slots_off;
    m->slot_size = h->slot_size;
    m->nslots    = h->nslots;
    m->pair_max  = sa_hash_capacity(h->slot_size);
    return m;
#endif
}

static void sa_hash_free(sa_hash *m) { free(m); }

/* ---- reading, without a lock ----------------------------------------------- */

/* Look `key` up and copy its value into `out`.
 *
 * SA_H_HIT with *vlen set, SA_H_MISS, or SA_H_BUSY when a writer held the slot
 * odd for longer than a reader was willing to wait. BUSY is deliberately not
 * MISS: telling a caller a key is absent when it is merely being rewritten is
 * how a cache turns an update into a delete.
 */
static int sa_hash_fetch(sa_hash *m, const char *key, uint32_t klen,
                         char *out, uint32_t outmax, uint32_t *vlen)
{
#if !SA_HAVE_ATOMICS
    (void)m; (void)key; (void)klen; (void)out; (void)outmax; (void)vlen;
    return SA_H_MISS;
#else
    uint64_t tag = sa_at_fnv(key, klen);
    uint64_t i, start = tag % m->nslots;

    for (i = 0; i < m->nslots; i++) {
        sa_hash_slot *s = SA_HSLOT_AT(m, start + i);
        uint32_t st = sa_at_load32_acq(&s->state);
        long spin = 0;

        if (st == SA_H_EMPTY) return SA_H_MISS;   /* a probe stops here */
        if (st == SA_H_DEAD)  continue;           /* but never here     */
        if (sa_at_load64_acq(&s->tag) != tag) continue;

        for (;;) {
            uint32_t v1 = sa_at_load32_acq(&s->version);
            uint32_t kl, vl;

            if (v1 & 1u) {                        /* mid-update: wait  */
                if (++spin >= SA_HASH_SPIN) {
                    sa_at_fetch_add64(&m->hdr->busy, 1);
                    return SA_H_BUSY;
                }
                continue;
            }

            kl = sa_at_load32_acq(&s->klen);
            vl = sa_at_load32_acq(&s->vlen);
            if (kl != klen || (uint64_t)kl + vl > m->pair_max) break;
            if (memcmp(s->bytes, key, klen) != 0) break;
            if (vl > outmax) { if (vlen) *vlen = vl; return SA_H_BUSY; }

            memcpy(out, s->bytes + kl, (size_t)vl);
            sa_at_fence_acq();

            /* Unchanged either side of the copy? If not, what is in `out` may
             * be half of one value and half of another. */
            if (sa_at_load32_acq(&s->version) != v1) {
                if (++spin >= SA_HASH_SPIN) {
                    sa_at_fetch_add64(&m->hdr->busy, 1);
                    return SA_H_BUSY;
                }
                continue;
            }
            if (vlen) *vlen = vl;
            return SA_H_HIT;
        }
        /* fell out of the seqlock loop: this slot is not our key */
    }
    return SA_H_MISS;
#endif
}

/* ---- writing, under a stripe lock ------------------------------------------ */

/* Find the slot this key belongs in, under the caller's lock. Returns the slot
 * to use, or NULL when the table is full. `*found` says whether the key was
 * already there. */
static sa_hash_slot *sa_hash_place(sa_hash *m, const char *key, uint32_t klen,
                                   uint64_t tag, int *found)
{
#if !SA_HAVE_ATOMICS
    (void)m; (void)key; (void)klen; (void)tag; (void)found;
    return NULL;
#else
    uint64_t i, start = tag % m->nslots;
    sa_hash_slot *reuse = NULL;

    *found = 0;
    for (i = 0; i < m->nslots; i++) {
        sa_hash_slot *s = SA_HSLOT_AT(m, start + i);
        uint32_t st = sa_at_load32_acq(&s->state);

        if (st == SA_H_EMPTY) return reuse ? reuse : s;
        if (st == SA_H_DEAD) {
            /* Remember the first tombstone, but keep probing: the key may be
             * live further along, and inserting a second copy of it here would
             * leave two entries that disagree. */
            if (!reuse) reuse = s;
            continue;
        }
        if (sa_at_load64_acq(&s->tag) == tag
            && s->klen == klen
            && memcmp(s->bytes, key, klen) == 0) {
            *found = 1;
            return s;
        }
    }
    return reuse;
#endif
}

static int sa_hash_store(sa_hash *m, const char *key, uint32_t klen,
                         const char *val, uint32_t vlen)
{
#if !SA_HAVE_ATOMICS
    (void)m; (void)key; (void)klen; (void)val; (void)vlen;
    return SA_H_FULL;
#else
    sa_hash_hdr *h = m->hdr;
    uint64_t tag;
    sa_hash_slot *s;
    int found = 0, rc = SA_H_OK;

    if ((uint64_t)klen + vlen > m->pair_max) return SA_H_TOOBIG;
    if (!klen) return SA_H_TOOBIG;

    tag = sa_at_fnv(key, klen);
    if (!sa_at_lock(h->locks, tag)) return SA_H_FULL;

    s = sa_hash_place(m, key, klen, tag, &found);
    if (!s) {
        sa_at_unlock(h->locks, tag);
        sa_at_fetch_add64(&h->full, 1);
        return SA_H_FULL;
    }

    /* Odd while writing, even when settled, with a barrier either side. The
     * barriers are the protocol: without the first, the bytes below can reach
     * another CPU before the odd version does, and a reader then sees new bytes
     * under an old version and calls them whole. */
    sa_at_store32_rel(&s->version, sa_at_load32_acq(&s->version) | 1u);
    sa_at_fence_rel();

    if (!found) {
        uint32_t was = sa_at_load32_acq(&s->state);
        memcpy(s->bytes, key, klen);
        s->klen = klen;
        sa_at_store64_rel(&s->tag, tag);
        if (was == SA_H_DEAD) sa_at_fetch_add64(&h->tombstones, (uint64_t)-1);
        sa_at_fetch_add64(&h->used, 1);
    }
    memcpy(s->bytes + klen, val, vlen);
    s->vlen = vlen;

    sa_at_fence_rel();
    sa_at_store32_rel(&s->version, (sa_at_load32_acq(&s->version) + 1u) | 0u);
    sa_at_store32_rel(&s->state, SA_H_LIVE);

    sa_at_unlock(h->locks, tag);
    return rc;
#endif
}

static int sa_hash_delete(sa_hash *m, const char *key, uint32_t klen)
{
#if !SA_HAVE_ATOMICS
    (void)m; (void)key; (void)klen;
    return 0;
#else
    sa_hash_hdr *h = m->hdr;
    uint64_t tag;
    sa_hash_slot *s;
    int found = 0;

    if (!klen) return 0;
    tag = sa_at_fnv(key, klen);
    if (!sa_at_lock(h->locks, tag)) return 0;

    s = sa_hash_place(m, key, klen, tag, &found);
    if (!s || !found) { sa_at_unlock(h->locks, tag); return 0; }

    /* A TOMBSTONE, not an empty slot. An empty slot stops a probe, and a probe
     * that stops early cannot find a key placed past this one. */
    sa_at_store32_rel(&s->state, SA_H_DEAD);
    sa_at_store32_rel(&s->vlen, 0);
    sa_at_fetch_add64(&h->used, (uint64_t)-1);
    sa_at_fetch_add64(&h->tombstones, 1);

    sa_at_unlock(h->locks, tag);
    return 1;
#endif
}

/* Add to a counter, creating it at `by` when it is not there.
 *
 * A counter is an entry whose value is exactly eight bytes, and this is the one
 * operation that does not go through the seqlock: the value IS a single aligned
 * word, so the add is one atomic and a reader can never see it half-written.
 * That is what makes a shared rate limiter or a request count cost the same as
 * incrementing a variable.
 *
 * An entry that exists and is not eight bytes is left alone and refused, rather
 * than reinterpreted: a caller that stored a string and then counted on it has
 * a bug, and silently overwriting it would hide the bug and the string. */
static int sa_hash_incr(sa_hash *m, const char *key, uint32_t klen,
                        int64_t by, uint64_t *now)
{
#if !SA_HAVE_ATOMICS
    (void)m; (void)key; (void)klen; (void)by; (void)now;
    return SA_H_FULL;
#else
    sa_hash_hdr *h = m->hdr;
    uint64_t tag;
    sa_hash_slot *s;
    int found = 0;

    if (!klen) return SA_H_TOOBIG;
    if ((uint64_t)klen + 8 > m->pair_max) return SA_H_TOOBIG;

    tag = sa_at_fnv(key, klen);
    if (!sa_at_lock(h->locks, tag)) return SA_H_FULL;

    s = sa_hash_place(m, key, klen, tag, &found);
    if (!s) {
        sa_at_unlock(h->locks, tag);
        sa_at_fetch_add64(&h->full, 1);
        return SA_H_FULL;
    }
    if (found && sa_at_load32_acq(&s->vlen) != 8) {
        sa_at_unlock(h->locks, tag);
        return SA_H_NOTNUM;
    }

    if (!found) {
        uint32_t was = sa_at_load32_acq(&s->state);
        uint64_t zero = 0;
        sa_at_store32_rel(&s->version, sa_at_load32_acq(&s->version) | 1u);
        sa_at_fence_rel();
        memcpy(s->bytes, key, klen);
        s->klen = klen;
        memcpy(s->bytes + klen, &zero, 8);
        s->vlen = 8;
        sa_at_store64_rel(&s->tag, tag);
        sa_at_fence_rel();
        sa_at_store32_rel(&s->version, sa_at_load32_acq(&s->version) + 1u);
        sa_at_store32_rel(&s->state, SA_H_LIVE);
        if (was == SA_H_DEAD) sa_at_fetch_add64(&h->tombstones, (uint64_t)-1);
        sa_at_fetch_add64(&h->used, 1);
    }

    /* The counter itself, aligned inside the slot only if the key length says
     * so - so it is read and written through the atomic helpers on a copy when
     * it is not. The common case, a key whose length keeps the value aligned,
     * is one instruction. */
    {
        char *p = s->bytes + s->klen;
        if (((size_t)p & 7u) == 0) {
            uint64_t v = sa_at_fetch_add64((volatile uint64_t *)p,
                                           (uint64_t)by);
            if (now) *now = v + (uint64_t)by;
        }
        else {
            uint64_t v;
            memcpy(&v, p, 8);
            v += (uint64_t)by;
            memcpy(p, &v, 8);
            if (now) *now = v;
        }
    }

    sa_at_unlock(h->locks, tag);
    return SA_H_OK;
#endif
}

#endif /* SA_HASH_H */
