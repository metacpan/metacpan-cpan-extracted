#ifndef SA_ABI_H
#define SA_ABI_H

/* Public C ABI for Shared::Arena (the provider) and its XS consumers.
 *
 * It is resolved at RUNTIME via Shared::Arena::_abi_ptr - a DBI-style versioned
 * function-pointer table - so there is no link-time symbol coupling and each
 * dist builds and upgrades independently. A consumer reaches this header
 * through ExtUtils::Depends, or vendors a copy pinned at SA_ABI_VERSION, and
 * checks abi_version at boot; a mismatch means "fall back", never a crash.
 *
 * The table only ever grows at the end. SA_ABI_VERSION bumps on any append, and
 * a consumer requires abi_version >= the version it was written against,
 * treating a later table as a superset it uses a prefix of.
 *
 * NOT ==. An equality check turns every provider release into a breaking change
 * for every consumer: a sibling dist in this workspace chose equality against
 * another's ABI and stopped loading everywhere the moment that provider
 * appended one member, croaking "please upgrade" at installations whose
 * provider was already newer than required.
 *
 * ---- THIS HEADER DOES NOT NEED PERL ----------------------------------------
 *
 * Nothing in the table touches an SV, so nothing takes pTHX and nothing here
 * uses a perl type. <stdint.h> and <stddef.h> are the whole dependency, and a
 * pure C program that never loads an interpreter can drive the entire thing.
 * That is not an accident of the current entries - it is the property the core
 * was written to keep, and an entry that would break it belongs in a separate
 * bridge rather than in here.
 *
 * ---- names, and a trap that has already cost this workspace a release ------
 *
 * No member is called open, close, read, write, stat, link, unlink, send, recv,
 * socket, select, time, exit, abort, malloc, free or getpid. On a perl built
 * with PERL_IMPLICIT_SYS - which every Strawberry is - XSUB.h redefines all of
 * those as function-like macros, and a member with one of those names breaks at
 * every CALL SITE while the declaration compiles cleanly. A sibling dist shipped
 * a table with a member called `close` and failed on the Strawberry smoker in
 * its own selftest. Parenthesising the call, `(A->close)(...)`, does work; not
 * using the names at all works better, and costs nothing.
 *
 * ---- ownership -------------------------------------------------------------
 *
 *   - A region, ring and cursor are each owned by whoever opened them and are
 *     freed by the matching release entry. After a release the pointer is dead;
 *     none of them are idempotent.
 *   - A ring borrows its region and a cursor borrows its ring. Release them in
 *     that order, innermost first.
 *   - A record handed to a drain callback points into the CURSOR'S OWN scratch
 *     and is valid only for the duration of that call. The next record
 *     overwrites it. Copy anything you keep.
 *   - Every string this table returns other than a record body is static.
 *
 * ---- resolving the table ---------------------------------------------------
 *
 * At BOOT, once, never per call:
 *
 *     static const sa_abi *SA = NULL;
 *
 *     BOOT:
 *     {
 *         SV *err;
 *         SV *sv = eval_pv("require Shared::Arena; Shared::Arena::_abi_ptr()", 0);
 *         err = get_sv("@", 0);
 *         if (sv && SvOK(sv) && (!err || !SvTRUE(err))) {
 *             const sa_abi *t = INT2PTR(const sa_abi *, SvUV(sv));
 *             if (t && t->abi_version >= SA_ABI_VERSION) SA = t;
 *         }
 *     }
 *
 * The VALUE eval_pv returns, not the top of the stack: eval_pv has already
 * popped what it evaluated, and reading PL_stack_sp instead finds whatever was
 * there before - which resolves to a plausible-looking pointer and a table that
 * answers nothing. And if the BOOT captured SP with dSP before calling eval_pv
 * and uses it afterwards, SPAGAIN first: eval_pv runs arbitrary Perl, which can
 * reallocate the value stack.
 *
 * A NULL SA means Shared::Arena is absent or too old, and the consumer falls
 * back to whatever it did before. It never croaks: a provider that is not there
 * is a missing optimisation, not a broken installation.
 */

#include <stdint.h>
#include <stddef.h>

/* Version 1, and it stays 1 until the first release: the table only gets a
 * history once somebody could have compiled against an earlier one. Bumping it
 * while the dist is unreleased would claim a compatibility story that never
 * happened and tell a consumer nothing. The first append AFTER 0.01 is
 * version 2. */
#define SA_ABI_VERSION 1

/* The three handles, opaque here. The guards are shared with the private
 * headers, which define the structs in the provider build - C89 makes a
 * repeated typedef an error rather than the no-op C11 allows, so whichever
 * header arrives first writes it. */
#ifndef SA_REGION_FWD
#define SA_REGION_FWD
typedef struct sa_region sa_region;
#endif
#ifndef SA_RING_FWD
#define SA_RING_FWD
typedef struct sa_ring sa_ring;
#endif
#ifndef SA_CURSOR_FWD
#define SA_CURSOR_FWD
typedef struct sa_cursor sa_cursor;
#endif
/* The map. Spelled sa_hash here because sa_map is the mapping layer's own
 * name inside the provider; the Perl class is Shared::Arena::Map. */
#ifndef SA_HASH_FWD
#define SA_HASH_FWD
typedef struct sa_hash sa_hash;
#endif
#ifndef SA_BLOOM_FWD
#define SA_BLOOM_FWD
typedef struct sa_bloom sa_bloom;
#endif
#ifndef SA_HIST_FWD
#define SA_HIST_FWD
typedef struct sa_hist sa_hist;
#endif
#ifndef SA_CACHE_FWD
#define SA_CACHE_FWD
typedef struct sa_cache sa_cache;
#endif

/* What a publish answers. A published record's SEQUENCE is returned, and a
 * sequence is always greater than zero, so one signed value carries both the
 * outcome and the record's identity with no second argument and no ambiguity. */
#define SA_PUBLISHED(rc) ((rc) > 0)
#define SA_NO_RING        0
#define SA_TOO_BIG      (-1)

/* What a region is asked for at create. Fill it with sa_config_init and then
 * set what you need; a zeroed struct is not the same as a defaulted one. */
typedef struct sa_config {
    uint64_t    bytes;      /* usable space; the header is added to it     */
    uint32_t    regions;    /* how many sub-regions may be carved          */
    const char *name;       /* NULL for anonymous, inherited across a fork */
    size_t      nlen;
} sa_config;

/* What a cursor has seen. `lapped` and `abandoned` are counted apart because
 * they are different diagnoses: lapped means this reader is too slow or the
 * ring is too small, abandoned means a publisher died mid-record.
 * `unattributed` is a hole nobody could be blamed for - it should be zero, and
 * a non-zero one is the honest signal that this design has a gap. */
typedef struct sa_counts {
    uint64_t delivered;
    uint64_t lapped;
    uint64_t abandoned;
    uint64_t unattributed;
    uint64_t position;
} sa_counts;

/* What a map holds. `busy` is reads that gave up on an entry that was being
 * rewritten, and is NOT a count of missing keys; `full` is stores refused for
 * want of a slot. */
typedef struct sa_map_counts {
    uint64_t used;
    uint64_t capacity;
    uint64_t tombstones;
    uint64_t busy;
    uint64_t full;
} sa_map_counts;

/* What a map lookup answers. Absent and could-not-read are different answers:
 * telling a caller a key is missing when a writer was mid-update is how an
 * update becomes a delete. */
#define SA_MAP_HIT  0
#define SA_MAP_MISS 1
#define SA_MAP_BUSY 2

/* What a histogram holds. min, max and sum are exact; the buckets are not.
 * `over` is values above the ceiling, counted apart rather than clamped. */
typedef struct sa_hist_counts {
    uint64_t count;
    uint64_t sum;
    uint64_t min;
    uint64_t max;
    uint64_t over;
    uint64_t nbuckets;
    uint32_t sigbits;
} sa_hist_counts;

/* What a cache holds. `hits` and `misses` are the pair a cache exists to
 * produce; `evictions` against `capacity` says whether it is big enough. */
#ifndef SA_RATE_FWD
#define SA_RATE_FWD
typedef struct sa_rate sa_rate;
#endif

#ifndef SA_CMS_FWD
#define SA_CMS_FWD
typedef struct sa_cms sa_cms;
#endif

#ifndef SA_GROUP_H_FWD
#define SA_GROUP_H_FWD
typedef struct sa_group_h sa_group_h;
#endif

/* What a queue group has got through. `delivered` is the POOL's, across every
 * member; `mine` is this process's share of it, which is the number that says
 * whether the work spread or whether one worker did all of it. */
typedef struct sa_group_counts {
    uint64_t position;
    uint64_t delivered;
    uint64_t lapped;
    uint64_t skipped;
    uint64_t mine;
} sa_group_counts;

typedef struct sa_cache_counts {
    uint64_t hits;
    uint64_t misses;
    uint64_t evictions;
    uint64_t expired;
    uint64_t live;
    uint64_t capacity;
    uint32_t ways;
} sa_cache_counts;

/* One delivered record. `topic` and `data` point into the cursor's scratch and
 * are valid only for this call. MUST NOT croak or longjmp: this is reached from
 * a drain with no Perl frame to unwind to. */
#ifndef SA_REC_FN_FWD
#define SA_REC_FN_FWD
typedef void (*sa_rec_fn)(void *ud, uint64_t seq,
                          const char *topic, uint32_t tlen,
                          const char *data, uint32_t dlen, uint32_t flags);
#endif

typedef struct sa_abi {
    int abi_version;                  /* consumers compare >= what they need */

    /* ---- the region -------------------------------------------------- */
    void        (*config_init)(sa_config *cfg);
    sa_region  *(*create)(const sa_config *cfg, int *err);
    /* attach_named, not `open`: see the naming note above. NULL when the name
     * does not exist - it never creates one, which is the whole difference
     * between the two entries. */
    sa_region  *(*attach_named)(const char *name, size_t nlen, int *err);
    void        (*release)(sa_region *r);
    int         (*destroy_named)(const char *name, size_t nlen);
    const char *(*errstr)(int rc);
    uint64_t    (*region_bytes)(const sa_region *r);
    int         (*is_creator)(const sa_region *r);

    /* ---- sub-regions --------------------------------------------------
     *
     * Both return the OFFSET from the region's base, or 0 - which is never a
     * valid carve, because the header lives there. `carve` returns the existing
     * region when the name is already taken, so every process can run the same
     * setup code and exactly one of them does the work. */
    uint64_t (*carve)(sa_region *r, const char *name, size_t nlen,
                      uint64_t bytes, uint32_t type, uint64_t *out_bytes,
                      int *err);
    uint64_t (*locate)(sa_region *r, const char *name, size_t nlen,
                       uint64_t *out_bytes);
    /* An offset in this process's address space. The one place an offset
     * becomes a pointer; never store the result anywhere shared. */
    void    *(*at)(sa_region *r, uint64_t off);

    /* ---- the ring ------------------------------------------------------ */
    sa_ring *(*ring_open)(sa_region *r, const char *name, size_t nlen,
                          uint64_t slots, uint32_t slot_size, int *err);
    void     (*ring_release)(sa_ring *r);
    /* The record's sequence, or SA_NO_RING / SA_TOO_BIG. A record larger than
     * a slot is REFUSED, never truncated: a truncated record is a lie the
     * reader cannot detect. */
    int64_t  (*publish)(sa_ring *r, const char *topic, uint32_t tlen,
                        const char *data, uint32_t dlen);
    /* The largest topic+data one record can carry. A RUNTIME question, and a
     * consumer that compiles the answer in is one that starts refusing records
     * the day the ring is configured differently. */
    uint64_t (*max_record)(const sa_ring *r);
    /* What ONE slot carries. max_record is this times the slots a record may
     * span, less whatever the topic takes. A caller sizing a ring needs both:
     * this one decides how many records fit, the other decides how big one may
     * be. */
    uint64_t (*slot_bytes)(const sa_ring *r);
    uint64_t (*ring_slots)(const sa_ring *r);
    uint64_t (*ring_position)(const sa_ring *r);

    /* ---- cursors -------------------------------------------------------
     *
     * A cursor is a handle and never a global: two readers sharing a position
     * would consume each other's records, and whichever asked first would get
     * everything. `from_start` replays what the ring still holds; the default
     * is to begin at now, which is what a tail wants. */
    sa_cursor *(*cursor_open)(sa_ring *r, int from_start);
    void       (*cursor_release)(sa_cursor *c);
    /* Everything since this cursor last looked, up to `max` records (0 for no
     * limit). Returns how many were delivered. Stops at a hole whose publisher
     * is still alive rather than blocking on it. */
    long       (*drain)(sa_cursor *c, long max, sa_rec_fn cb, void *ud);
    void       (*counts)(const sa_cursor *c, sa_counts *out);

    /* ---- liveness ------------------------------------------------------
     *
     * A process registers so that a record it leaves unfinished can be proven
     * abandoned rather than merely waited on. `join` is called for you by
     * publish and drain; call `beat` from a process that does neither for long
     * stretches but is still alive, or its silence will eventually look like
     * death to somebody waiting on a hole it left. */
    int  (*join)(sa_region *r);
    void (*beat)(sa_region *r);

    /* ---- the map ---------------------------------------------------------
     *
     * A fixed-capacity table, lock-free to read and stripe-locked to write.
     * It never rehashes: a full table refuses a new key, and `map_store`
     * answers 0. Overwriting an existing key always works, because it needs
     * no new slot.
     *
     * `map_fetch` copies into the caller's buffer and answers SA_MAP_*.
     * A value too long for the buffer answers BUSY with *vlen set to what it
     * would have needed, so a caller can size and retry. */
    sa_hash *(*map_open)(sa_region *r, const char *name, size_t nlen,
                         uint64_t slots, uint32_t slot_size, int *err);
    void     (*map_release)(sa_hash *m);
    int      (*map_store)(sa_hash *m, const char *key, uint32_t klen,
                          const char *val, uint32_t vlen);
    int      (*map_fetch)(sa_hash *m, const char *key, uint32_t klen,
                          char *out, uint32_t outmax, uint32_t *vlen);
    int      (*map_delete)(sa_hash *m, const char *key, uint32_t klen);
    /* A counter is a single machine word, so this is ONE atomic and never
     * goes through the version. Refuses an entry that is not a counter
     * rather than reinterpreting it. */
    int      (*map_incr)(sa_hash *m, const char *key, uint32_t klen,
                         int64_t by, uint64_t *now);
    void     (*map_counts)(const sa_hash *m, sa_map_counts *out);
    uint64_t (*map_pair_max)(const sa_hash *m);
    uint64_t (*map_capacity)(const sa_hash *m);

    /* ---- the bloom filter -------------------------------------------------
     *
     * A bit array and k hashes. No lock on either side: setting a bit is one
     * atomic OR, and two processes setting the same bit both simply set it.
     *
     * `bloom_open` sizes from an expected item count and a false-positive
     * rate; pass bits and hashes instead by giving `capacity` 0.
     *
     * `bloom_add` answers 1 when every bit was already set. That is per BIT
     * and not per key: two processes adding one key at the same instant can
     * both be told it was new. `bloom_check` answers 0 exactly and 1
     * probably. There is no delete, and there cannot be one. */
    sa_bloom *(*bloom_open)(sa_region *r, const char *name, size_t nlen,
                            uint64_t capacity, double fp_rate,
                            uint64_t bits, uint32_t hashes, int *err);
    void      (*bloom_release)(sa_bloom *b);
    int       (*bloom_add)(sa_bloom *b, const char *key, uint32_t klen);
    int       (*bloom_check)(sa_bloom *b, const char *key, uint32_t klen);
    void      (*bloom_reset)(sa_bloom *b);
    uint64_t  (*bloom_bits)(const sa_bloom *b);
    uint32_t  (*bloom_hashes)(const sa_bloom *b);
    /* O(bits/64): a status question, not a request-path one. */
    uint64_t  (*bloom_set)(sa_bloom *b);
    uint64_t  (*bloom_estimate)(sa_bloom *b);

    /* ---- the histogram -----------------------------------------------------
     *
     * Log-linear buckets: each power of two split into 2^sigbits, so the
     * relative error is at most 1/2^sigbits at every scale. Recording is one
     * atomic add and needs no merge, because every process adds to the same
     * array.
     *
     * `hist_quantile` answers with the TOP of the bucket, so it is never
     * optimistic, and it walks while values arrive rather than stopping
     * anybody. A value above the ceiling is counted in `over` and NOT clamped
     * into the top bucket, which would make every quantile read plausibly and
     * be wrong. */
    sa_hist *(*hist_open)(sa_region *r, const char *name, size_t nlen,
                          uint64_t max_value, uint32_t sigbits, int *err);
    void     (*hist_release)(sa_hist *h);
    void     (*hist_record)(sa_hist *h, uint64_t value, uint64_t times);
    uint64_t (*hist_quantile)(sa_hist *h, double q);
    void     (*hist_reset)(sa_hist *h);
    void     (*hist_counts)(const sa_hist *h, sa_hist_counts *out);
    /* the bounds of bucket i, for walking the shape */
    uint64_t (*hist_bucket_low)(const sa_hist *h, uint64_t i);
    uint64_t (*hist_bucket_high)(const sa_hist *h, uint64_t i);
    uint64_t (*hist_bucket_count)(const sa_hist *h, uint64_t i);

    /* ---- the cache ---------------------------------------------------------
     *
     * A map that evicts rather than refusing. Set-associative, so a lookup
     * touches `ways` entries and an eviction considers `ways` candidates, and
     * neither degrades as it fills.
     *
     * `cache_set` never fails for want of room: it answers SA_C_TOOBIG only
     * when the key is empty or the pair will not fit one entry. What leaves is
     * an expired entry if there is one, and otherwise the first entry CLOCK's
     * hand finds with its reference bit clear.
     *
     * `cache_get` answers SA_MAP_* and treats an expired entry as a miss.
     * `ttl_ms` of 0 means no deadline. */
    sa_cache *(*cache_open)(sa_region *r, const char *name, size_t nlen,
                            uint64_t capacity, uint32_t ways,
                            uint32_t entry_size, int *err);
    void      (*cache_release)(sa_cache *c);
    int       (*cache_set)(sa_cache *c, const char *key, uint32_t klen,
                           const char *val, uint32_t vlen, uint64_t ttl_ms);
    int       (*cache_get)(sa_cache *c, const char *key, uint32_t klen,
                           char *out, uint32_t outmax, uint32_t *vlen);
    int       (*cache_remove)(sa_cache *c, const char *key, uint32_t klen);
    void      (*cache_clear)(sa_cache *c);
    void      (*cache_counts)(sa_cache *c, sa_cache_counts *out);
    uint64_t  (*cache_pair_max)(const sa_cache *c);

    /* ---- the rate limiter -------------------------------------------------
     *
     * THE ENTRY THAT MATTERS IS `rate_allow`, and it matters that it is here
     * rather than only in Perl: a limiter is checked on the accept path, per
     * connection, and a consumer paying a method call per check would be
     * slower than the thing it replaced.
     *
     * `limit` is the burst and also what a full refill puts back; `window_ms`
     * is how long that refill takes. `cost` is in whole requests and 0 means
     * one. `left` and `retry_ms` are filled when non-NULL, whichever way the
     * answer went, because a caller wants them for its headers either way.
     *
     * FAILS OPEN, always: a NULL limiter answers 1. A limiter must never be
     * the reason a good request is refused. */
    sa_rate  *(*rate_open)(sa_region *r, const char *name, size_t nlen,
                           uint64_t limit, uint64_t window_ms,
                           uint64_t slots, int *err);
    void      (*rate_release)(sa_rate *rl);
    int       (*rate_allow)(sa_rate *rl, const char *key, uint32_t klen,
                            uint64_t cost, uint64_t *left, uint64_t *retry_ms);
    int       (*rate_peek)(sa_rate *rl, const char *key, uint32_t klen,
                           uint64_t *left, uint64_t *retry_ms);
    void      (*rate_reset)(sa_rate *rl, const char *key, uint32_t klen);
    void      (*rate_forget)(sa_rate *rl, const char *key, uint32_t klen);
    uint64_t  (*rate_slots)(const sa_rate *rl);
    uint64_t  (*rate_used)(sa_rate *rl);

    /* ---- the count-min sketch ---------------------------------------------
     *
     * `cms_add` counts and returns what the sketch now believes; `cms_estimate`
     * asks without counting. Both answer HIGH and never low, by at most
     * `cms_error` - which is a fraction of the TOTAL, not of the key, so a
     * consumer quoting an estimate without it is quoting a number with no
     * error bar.
     *
     * A NULL sketch answers 0 rather than refusing, so a consumer that could
     * not open one degrades to counting nothing. */
    sa_cms   *(*cms_open)(sa_region *r, const char *name, size_t nlen,
                          double error, double confidence,
                          uint32_t rows, uint64_t width, int *err);
    void      (*cms_release)(sa_cms *s);
    uint64_t  (*cms_add)(sa_cms *s, const char *key, uint32_t klen, uint64_t n);
    uint64_t  (*cms_estimate)(sa_cms *s, const char *key, uint32_t klen);
    void      (*cms_reset)(sa_cms *s);
    uint64_t  (*cms_total)(sa_cms *s);
    uint64_t  (*cms_error)(sa_cms *s);
    uint32_t  (*cms_rows)(const sa_cms *s);
    uint64_t  (*cms_width)(const sa_cms *s);

    /* ---- queue groups -----------------------------------------------------
     *
     * A cursor is process-local, so every reader holding one sees every record:
     * that is fanout. A GROUP's cursor lives in the ring's own region, so
     * whoever wins the compare-and-swap owns that record and no other member
     * gets it. The difference between a broadcast and a queue is where the
     * cursor lives, and nothing else.
     *
     * `group_claim` answers SA_READ_OK with the record filled in, or
     * SA_READ_PENDING when there is nothing to take. The pointers it hands back
     * are into the handle's own buffer and stay valid until the next claim on
     * THAT handle.
     *
     * AT MOST ONCE. A member that claims a record and then dies loses it: the
     * claim moved the shared cursor and nothing records who held what. That is
     * a data-loss property rather than a slow path, so a caller needing
     * at-least-once wants a durable queue and not a cursor.
     *
     * `group_open` with a NULL topic takes every record; with one, it delivers
     * only matching records and advances past the rest. `from_start` asks for
     * whatever the ring still holds rather than only what arrives next. */
    sa_group_h *(*group_open)(sa_ring *r, const char *name, size_t nlen,
                              const char *topic, size_t tlen,
                              int from_start, int *err);
    void        (*group_release)(sa_group_h *g);
    int         (*group_claim)(sa_group_h *g, uint64_t *seq,
                               const char **topic, uint32_t *tlen,
                               const char **data, uint32_t *dlen,
                               uint32_t *flags);
    uint64_t    (*group_position)(const sa_group_h *g);
    void        (*group_counts)(const sa_group_h *g, sa_group_counts *out);
} sa_abi;

#endif /* SA_ABI_H */
