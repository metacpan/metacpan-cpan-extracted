#ifndef SA_ARENA_H
#define SA_ARENA_H

/* sa_arena.h - the handle, the bump allocator and the name registry.
 * Perl-free.
 *
 * ---- the handle is process-local, and that is the point ---------------------
 *
 * Everything a process knows about a region that is NOT shared lives here:
 * the base address it mapped at, the length, the name it opened. A consuming
 * .so gets its own handle and shares the region, rather than getting its own
 * copy of a static and quietly sharing nothing - which is the failure this
 * design starts from.
 *
 * ---- allocation is a bump, and there is no free -----------------------------
 *
 * A sub-region is carved by advancing a high-water offset and lives as long as
 * the region does. That is a deliberate limit rather than an omission.
 *
 * A free list in shared memory is corrupted permanently by one process dying
 * between two stores, and unlike a torn record there is no way to detect it
 * afterwards or bound the damage: the next allocation hands out memory somebody
 * else is using. Nothing that wants an arena needs to release a sub-region - a
 * bus takes one for its whole life, a rate limiter takes two tables, a bloom
 * filter takes three. A caller who genuinely needs reuse can implement it
 * INSIDE its own carved region, where getting it wrong costs one feature
 * instead of the whole arena.
 *
 * ---- the registry is what makes attaching worth anything --------------------
 *
 * Without it, a second process has to be told an offset out of band, which
 * means the two builds must agree on a layout neither can check. With it, a
 * late arriver asks for "events" and is handed the offset and the length, or
 * nothing.
 */

#include "sa/sa_map.h"

#ifndef SA_REGION_FWD
#define SA_REGION_FWD
typedef struct sa_region sa_region;
#endif

struct sa_region {
    sa_map      map;
    sa_header  *hdr;        /* == map.base, cached                          */
    uint64_t    total;
    int         created;    /* did THIS process create it                   */

    /* This process's peer slot, filled lazily on first use. `peer_pid` is
     * what makes a fork child take a slot of its OWN rather than inheriting
     * its parent's, which would attribute the child's records to the wrong
     * process and make a crash unprovable. */
    int         peer_idx;
    uint32_t    peer_epoch;
    uint64_t    peer_pid;

    /* The waker table, carved like any other sub-region and found by name, so
     * a fork child resolves it without being told where it is. */
    uint64_t    wakers_off;
    uint32_t    wakers_max;
    int         waker_idx;

    /* Whether the descriptors in the waker table are the ones THIS process
     * holds, answered once with an fstat and cached here rather than in the
     * mapping - it is a fact about this process, not about the region. See the
     * identity comment in sa_wake.h. */
    int         wake_checked;
    int         wake_ok;
    uint64_t    wake_pid;
};

/* ---- carving --------------------------------------------------------------- */

/* Advance the high-water mark by `len` and return the offset, or 0 when the
 * region is full. Offset 0 is never a valid carve, because the header lives
 * there, so 0 doubles as the failure value.
 *
 * A CAS loop rather than a fetch-add: a fetch-add that overshoots has already
 * consumed the space it could not use, so a region that refuses one oversized
 * carve would go on refusing every small one after it. */
static uint64_t sa_bump(sa_region *r, uint64_t len) {
#if !SA_HAVE_ATOMICS
    (void)r; (void)len;
    return 0;
#else
    sa_header *h = r->hdr;
    uint64_t old, want;
    for (;;) {
        old  = sa_at_load64_acq(&h->brk);
        want = sa_align_up(old);
        if (want + len > h->total || want + len < want) return 0;
        if (sa_at_cas64(&h->brk, old, want + len)) return want;
    }
#endif
}

/* ---- AN OFFSET IS NOT ENOUGH: A STRUCTURE HAS A LENGTH --------------------
 *
 * sa_ptr answers whether the START of something is inside the mapping, which
 * is not the question a caller about to read a structure is asking. Every
 * tenant used to bind with it and then check its own size against the registry
 * entry's `len` - a number that comes OUT OF THE SHARED SEGMENT, so anybody
 * who can write to the segment chooses it.
 *
 * Measured: a process that knew only the name rewrote one registry entry to
 * `off = total - 64, len = 1GB`, and the next process to bind that ring wrote
 * about twenty-one kilobytes past the end of its own mapping. SIGSEGV, and the
 * POD at the time promised that "a reader will not follow a length past the
 * end of a mapping". t/30-bounds.t is that PoC.
 *
 * This is the check that makes the promise true. The comparison is written as
 * `off > total - len` rather than `off + len > total` BECAUSE THE ADDITION CAN
 * WRAP: with a 64-bit len chosen by an attacker, `off + len` is small again and
 * the guard passes the very case it exists to refuse.
 *
 * The lower bound keeps a carve off the header, the registry and the peer
 * table, which is where a hostile entry would point to make a tenant's memset
 * eat the arena's own bookkeeping. */
static void *sa_ptr_len(sa_region *r, uint64_t off, uint64_t len) {
    uint64_t floor;
    if (!r || !r->map.base || !r->hdr) return NULL;
    floor = r->hdr->peers_off
          + (uint64_t)r->hdr->peers_max * (uint64_t)sizeof(sa_peer);
    if (off < floor)      return NULL;
    if (len > r->total)   return NULL;
    if (off > r->total - len) return NULL;
    return SA_AT(r->map.base, off);
}

/* Does this registry entry describe bytes that are actually in the mapping?
 *
 * Checked where an entry is READ rather than in each of the seven tenants that
 * use one, so a tenant added later cannot forget it. An entry that fails is
 * treated as not live: a name that does not resolve, rather than a pointer
 * into somebody else's memory. */
static int sa_reg_ok(sa_region *r, const sa_reg *e) {
    return e && sa_ptr_len(r, e->off, e->len) != NULL;
}

/* The registry entry for a name, or NULL.
 *
 * Only entries whose `state` has been published are visible, so a carve that is
 * still being filled in is invisible rather than half-readable. */
static sa_reg *sa_find(sa_region *r, const char *name, size_t nlen) {
#if !SA_HAVE_ATOMICS
    (void)r; (void)name; (void)nlen;
    return NULL;
#else
    sa_header *h = r->hdr;
    sa_reg *regs = SA_REGS(r->map.base, h);
    uint32_t used, i;

    if (!name || !nlen || nlen >= SA_NAMELEN) return NULL;
    used = sa_at_load32_acq(&h->reg_used);
    if (used > h->reg_max) used = h->reg_max;

    for (i = 0; i < used; i++) {
        if (sa_at_load32_acq(&regs[i].state) != SA_R_LIVE) continue;
        if (strncmp(regs[i].name, name, nlen) == 0 && regs[i].name[nlen] == '\0') {
            /* AN ENTRY WHOSE EXTENT IS NOT IN THE MAPPING IS NOT AN ENTRY, so
             * it is skipped exactly as a non-live one is - not treated as a
             * fatal answer for the name.
             *
             * Returning NULL here instead looks safer and is worse twice over:
             * the name becomes permanently unresolvable, AND sa_carve, finding
             * nothing, carves a SECOND entry under the same name. One bad word
             * in the registry would shadow a working region for the life of the
             * arena. Skipping means the bad entry describes nothing anybody
             * will dereference, and a good entry for that name still wins.
             *
             * It is counted, because a refused entry means either corruption or
             * somebody writing to the segment who should not be, and a fallback
             * that says nothing is how that goes unnoticed. */
            if (!sa_reg_ok(r, &regs[i])) {
                sa_at_fetch_add32(&h->reg_refused, 1);
                continue;
            }
            return &regs[i];
        }
    }
    return NULL;
#endif
}

/* Carve a named sub-region, or return the existing one with that name.
 *
 * Returning the existing one rather than refusing is what lets every process
 * run the same setup code: whoever gets there first creates it, everybody else
 * finds it, and no caller has to know which it was. The type and length are
 * checked against what is already there, because two processes disagreeing
 * about the shape of a region is worse than either of them failing.
 *
 * Writes *err and returns NULL on refusal. Never croaks: the reader is C.
 */
/* A bounded acquire that SLEEPS between attempts instead of spinning through
 * its whole budget in one go.
 *
 * sa_at_lock is a pure spin, which is right on a hot path where the holder is
 * about to finish and a sleep would cost more than the wait. It is wrong where
 * there are more contenders than there are cores: the budget burns while the
 * process actually holding the lock is not scheduled at all, and the caller is
 * refused for being unlucky rather than for anything being full.
 *
 * Found on a 32-bit perl under emulation, eight processes carving four
 * thousand regions: FOUR were refused, every run, deterministically, while the
 * same four thousand carved serially were all fine. That is not a full arena,
 * it is a spin that never got a turn.
 *
 * Still bounded, and that is not negotiable: a process that died holding a
 * stripe must not wedge everybody who comes after it. The budget is just spent
 * as a few dozen short sleeps rather than as one long burn, so the holder gets
 * a chance to run and hand it over.
 *
 * For rare operations only - carving a region, publishing a block. Anything on
 * a per-request path should use sa_at_lock and take the refusal. */
#define SA_LOCK_ROUNDS   64
#define SA_LOCK_STALL_US 50

static int sa_lock_wait(volatile unsigned char *locks, uint64_t h) {
    int round;
    for (round = 0; round < SA_LOCK_ROUNDS; round++) {
        if (sa_at_lock(locks, h)) return 1;
        sa_stall(SA_LOCK_STALL_US);
    }
    return 0;
}

static sa_reg *sa_carve(sa_region *r, const char *name, size_t nlen,
                        uint64_t len, uint32_t type, int *err)
{
#if !SA_HAVE_ATOMICS
    (void)r; (void)name; (void)nlen; (void)len; (void)type;
    if (err) *err = SA_E_NOATOMICS;
    return NULL;
#else
    sa_header *h = r->hdr;
    sa_reg *regs, *e;
    uint64_t off, hash;
    uint32_t idx;

    if (err) *err = SA_E_OK;
    if (!name || !nlen || nlen >= SA_NAMELEN) {
        if (err) *err = SA_E_NAME;
        return NULL;
    }

    hash = sa_at_fnv(name, nlen);
    /* The lock covers only the name check and the claim, so two processes
     * carving DIFFERENT names contend on a stripe at worst.
     *
     * WAITS RATHER THAN SPINS. Carving happens once per region at startup, so
     * a few microseconds of sleep costs nothing and a refusal costs a worker
     * its region. See sa_lock_wait: a pure spin refused four carves in four
     * thousand, every run, on a machine with fewer cores than carvers. */
    if (!sa_lock_wait(h->locks, hash)) {
        if (err) *err = SA_E_FULL;
        return NULL;
    }

    e = sa_find(r, name, nlen);
    if (e) {
        /* SA_E_SHAPE, not SA_E_NAME. The name is fine - it is the type or the
         * size that disagrees with what is already carved, and telling a caller
         * its name is "too long or empty" when the name is neither sends it
         * looking in the wrong place entirely. */
        int bad = (e->type != type) || (len && e->len < len);
        sa_at_unlock(h->locks, hash);
        if (bad) { if (err) *err = SA_E_SHAPE; return NULL; }
        return e;
    }

    /* THE SLOT IS CLAIMED WITH ONE ATOMIC, NOT READ AND THEN WRITTEN.
     *
     * The stripe lock above is keyed on the NAME, so it serialises two carves
     * of the same name and does nothing at all for two carves of different
     * ones - and the registry append is a resource they share. Reading
     * `reg_used` here and storing `idx + 1` twenty lines later left a window in
     * which two processes took the same index, both filled it, and the loser's
     * entry was gone with its arena space still spent. Both callers were told
     * they had succeeded.
     *
     * Measured before it was fixed: eight processes carving 4000 names between
     * them kept 3263 of them, with no refusal reported for the other 737.
     * t/04-carve-race.t is that test.
     *
     * fetch-add cannot overshoot into somebody else's entry, so `reg_used` may
     * pass `reg_max` when the registry is full and every reader already clamps
     * it - `sa_find` and `sa_regions` both do. It is never decremented: undoing
     * it would hand the same index to a caller that is still writing. */
    idx = sa_at_fetch_add32(&h->reg_used, 1);
    if (idx >= h->reg_max) {
        sa_at_unlock(h->locks, hash);
        if (err) *err = SA_E_FULL;
        return NULL;
    }

    off = sa_bump(r, len);
    if (!off) {
        sa_at_unlock(h->locks, hash);
        if (err) *err = SA_E_FULL;
        return NULL;
    }

    regs = SA_REGS(r->map.base, h);
    e = &regs[idx];
    memset(e->name, 0, SA_NAMELEN);
    memcpy(e->name, name, nlen);
    e->off  = off;
    e->len  = len;
    e->type = type;
    /* `state` is published LAST with a release store: the count already moved
     * when the index was claimed, so a concurrent reader scanning this far
     * finds an entry that is still EMPTY rather than one that is half filled.
     * A scan that sees nothing is a miss it will retry; a scan that reads a
     * half-filled entry is a wrong answer it cannot detect. */
    sa_at_store32_rel(&e->state, SA_R_LIVE);

    sa_at_unlock(h->locks, hash);
    return e;
#endif
}

/* An offset into this process's address space. The one place an offset becomes
 * a pointer, and it is never stored anywhere shared. */
static void *sa_ptr(sa_region *r, uint64_t off) {
    if (!r || !r->map.base || off >= r->total) return NULL;
    return SA_AT(r->map.base, off);
}


/* ---- lifecycle -------------------------------------------------------------- */

static sa_region *sa_region_open(const char *name, size_t nlen, uint64_t len,
                                 uint32_t reg_max, int may_create, int *err)
{
    sa_region *r;
    char nbuf[SA_NAMELEN + 8];
    const char *nm = NULL;
    int rc, created = 0;

    if (err) *err = SA_E_OK;

    if (name && nlen) {
        /* A POSIX shared name must start with a slash and contain no others,
         * and macOS caps the whole thing at 31 characters including the NUL -
         * shorter than PATH_MAX by a long way and the reason a name that works
         * on Linux can fail there. Keep the caller's name inside SA_NAMELEN and
         * the slash is ours to add. */
        if (nlen >= SA_NAMELEN || memchr(name, '/', nlen)) {
            if (err) *err = SA_E_NAME;
            return NULL;
        }
        nbuf[0] = '/';
        memcpy(nbuf + 1, name, nlen);
        nbuf[nlen + 1] = '\0';
        nm = nbuf;
    }

    r = (sa_region *)calloc(1, sizeof(sa_region));
    if (!r) { if (err) *err = SA_E_NOMEM; return NULL; }
    r->peer_idx  = -1;
    r->waker_idx = -1;

    rc = sa_map_open(&r->map, nm, len, reg_max, &created, may_create);
    if (rc != SA_E_OK) {
        free(r);
        if (err) *err = rc;
        return NULL;
    }

    r->hdr     = (sa_header *)r->map.base;
    r->total   = r->hdr->total;
    r->created = created;
    return r;
}

static void sa_region_release(sa_region *r) {
    if (!r) return;
    sa_map_release(&r->map);
    free(r);
}

static int sa_region_destroy(const char *name, size_t nlen) {
    char nbuf[SA_NAMELEN + 8];
    if (!name || !nlen || nlen >= SA_NAMELEN || memchr(name, '/', nlen))
        return SA_E_NAME;
    nbuf[0] = '/';
    memcpy(nbuf + 1, name, nlen);
    nbuf[nlen + 1] = '\0';
    return sa_os_destroy(nbuf);
}

#endif /* SA_ARENA_H */
