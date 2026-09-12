#ifndef SA_ABI_IMPL_H
#define SA_ABI_IMPL_H

/* The table behind Shared::Arena::_abi_ptr. Private to this build; consumers
 * see only include/sa_abi.h and resolve the address at runtime.
 *
 * Every entry points at a core function, wrapped only where the ABI's signature
 * differs from the core's - an out parameter where the core returns a struct
 * pointer, a size_t where the core takes its own type. Nothing is IMPLEMENTED
 * here: logic in this file means a core function has the wrong shape.
 *
 * Needs sa_abi.h and every core header the entries name.
 */

/* ---- the two ends of every shared constant --------------------------------
 *
 * sa_abi.h is a PUBLIC copy of numbers the core also defines, and the two are
 * different files: an edit to one and not the other is silent, and the symptom
 * is a consumer reading a different answer from the same bytes. These make it a
 * build failure instead. The array-size trick rather than static_assert, which
 * is C11 and this dist compiles as C89. */
typedef char sa_abi_assert_map[
    (SA_MAP_HIT == SA_H_HIT && SA_MAP_MISS == SA_H_MISS
  && SA_MAP_BUSY == SA_H_BUSY) ? 1 : -1];
typedef char sa_abi_assert_pub[
    (SA_NO_RING == SA_PUB_NORING && SA_TOO_BIG == SA_PUB_OVERSIZE) ? 1 : -1];

static void sa_abi_config_init(sa_config *cfg) {
    if (!cfg) return;
    cfg->bytes   = 1024 * 1024;
    cfg->regions = SA_REGIONS_MAX;
    cfg->name    = NULL;
    cfg->nlen    = 0;
}

static sa_region *sa_abi_create(const sa_config *cfg, int *err) {
    sa_config d;
    if (!cfg) { sa_abi_config_init(&d); cfg = &d; }
    return sa_region_open(cfg->name, cfg->nlen,
                          cfg->bytes + sa_header_bytes(cfg->regions),
                          cfg->regions, 1, err);
}

static sa_region *sa_abi_attach(const char *name, size_t nlen, int *err) {
    return sa_region_open(name, nlen,
                          sa_header_bytes(SA_REGIONS_MAX),
                          SA_REGIONS_MAX, 0, err);
}

static void sa_abi_release(sa_region *r) {
    sa_wake_leave(r);
    sa_peer_leave(r);
    sa_region_release(r);
}

static int sa_abi_destroy(const char *name, size_t nlen) {
    return sa_region_destroy(name, nlen);
}

static uint64_t sa_abi_bytes(const sa_region *r) {
    return r ? r->total : 0;
}

static int sa_abi_is_creator(const sa_region *r) {
    return (r && r->created) ? 1 : 0;
}

static uint64_t sa_abi_carve(sa_region *r, const char *name, size_t nlen,
                             uint64_t bytes, uint32_t type,
                             uint64_t *out_bytes, int *err)
{
    sa_reg *e = sa_carve(r, name, nlen, bytes, type, err);
    if (!e) return 0;
    if (out_bytes) *out_bytes = e->len;
    return e->off;
}

static uint64_t sa_abi_locate(sa_region *r, const char *name, size_t nlen,
                              uint64_t *out_bytes)
{
    sa_reg *e = sa_find(r, name, nlen);
    if (!e) return 0;
    if (out_bytes) *out_bytes = e->len;
    return e->off;
}

static sa_ring *sa_abi_ring_open(sa_region *r, const char *name, size_t nlen,
                                 uint64_t slots, uint32_t slot_size, int *err)
{
    sa_reg *e;
    if (err) *err = SA_E_OK;
    e = sa_carve(r, name, nlen, sa_ring_bytes(slots, slot_size),
                 SA_T_RING, err);
    if (!e) return NULL;
    return sa_ring_bind(r, e, slots, slot_size, err);
}

static int64_t sa_abi_publish(sa_ring *r, const char *topic, uint32_t tlen,
                              const char *data, uint32_t dlen)
{
    uint64_t seq = 0;
    int rc = sa_ring_publish(r, topic, tlen, data, dlen, &seq);
    return (rc == SA_PUB_OK) ? (int64_t)seq : (int64_t)rc;
}

static uint64_t sa_abi_max_record(const sa_ring *r) {
    /* The SPANNED maximum, which is what a caller needs before it publishes,
     * and the same number the Perl surface reports. Returning the per-slot
     * capacity here instead is a disagreement between the two doors that no
     * compiler can see - the selftest caught exactly that. */
    return r ? r->record_max : 0;
}

static uint64_t sa_abi_slot_bytes(const sa_ring *r) {
    return r ? r->payload_max : 0;
}

static uint64_t sa_abi_ring_slots(const sa_ring *r) {
    return r ? r->nslots : 0;
}

static uint64_t sa_abi_ring_position(const sa_ring *r) {
#if SA_HAVE_ATOMICS
    return r ? sa_at_load64_acq(&r->hdr->seq) : 0;
#else
    (void)r;
    return 0;
#endif
}

static void sa_abi_counts(const sa_cursor *c, sa_counts *out) {
    if (!out) return;
    if (!c) { memset(out, 0, sizeof *out); return; }
    out->delivered    = c->delivered;
    out->lapped       = c->lapped;
    out->abandoned    = c->abandoned;
    out->unattributed = c->unattributed;
    out->position     = c->seq;
}

static sa_hash *sa_abi_map_open(sa_region *r, const char *name, size_t nlen,
                                uint64_t slots, uint32_t slot_size, int *err)
{
    sa_reg *e;
    if (err) *err = SA_E_OK;
    e = sa_carve(r, name, nlen, sa_hash_bytes(slots, slot_size),
                 SA_T_MAP, err);
    if (!e) return NULL;
    return sa_hash_bind(r, e, slots, slot_size, err);
}

static void sa_abi_map_counts(const sa_hash *m, sa_map_counts *out) {
    if (!out) return;
    if (!m) { memset(out, 0, sizeof *out); return; }
    out->used       = sa_at_load64_acq(&m->hdr->used);
    out->capacity   = m->nslots;
    out->tombstones = sa_at_load64_acq(&m->hdr->tombstones);
    out->busy       = sa_at_load64_acq(&m->hdr->busy);
    out->full       = sa_at_load64_acq(&m->hdr->full);
    out->expired    = sa_at_load64_acq(&m->hdr->expired);
}

static uint64_t sa_abi_map_pair_max(const sa_hash *m) {
    return m ? m->pair_max : 0;
}

static uint64_t sa_abi_map_capacity(const sa_hash *m) {
    return m ? m->nslots : 0;
}

static sa_bloom *sa_abi_bloom_open(sa_region *r, const char *name, size_t nlen,
                                   uint64_t capacity, double fp_rate,
                                   uint64_t bits, uint32_t hashes, int *err)
{
    sa_reg *e;
    uint64_t nbits = 0;
    uint32_t k = 0;

    if (err) *err = SA_E_OK;
    if (bits) {
        nbits = sa_bloom_words(bits) * 64u;
        k     = hashes ? hashes : 5;
    }
    else {
        sa_bloom_size(capacity, fp_rate, &nbits, &k);
        if (hashes) k = hashes;
    }
    if (k > SA_BLOOM_MAX_K) k = SA_BLOOM_MAX_K;

    e = sa_carve(r, name, nlen, sa_bloom_bytes(nbits), SA_T_BLOOM, err);
    if (!e) return NULL;
    {
        sa_bloom *b = sa_bloom_bind(r, e, nbits, k, err);
        if (b) b->hdr->capacity = capacity;
        return b;
    }
}

static uint64_t sa_abi_bloom_bits(const sa_bloom *b) { return b ? b->nbits : 0; }
static uint32_t sa_abi_bloom_hashes(const sa_bloom *b) { return b ? b->nhash : 0; }

static sa_hist *sa_abi_hist_open(sa_region *r, const char *name, size_t nlen,
                                 uint64_t max_value, uint32_t sigbits,
                                 int *err)
{
    sa_reg *e;
    if (err) *err = SA_E_OK;
    if (!sigbits) sigbits = 4;
    e = sa_carve(r, name, nlen, sa_hist_bytes(max_value, sigbits),
                 SA_T_HIST, err);
    if (!e) return NULL;
    return sa_hist_bind(r, e, max_value, sigbits, err);
}

static void sa_abi_hist_counts(const sa_hist *h, sa_hist_counts *out) {
    if (!out) return;
    if (!h) { memset(out, 0, sizeof *out); return; }
    out->count    = sa_at_load64_acq(&h->hdr->count);
    out->sum      = sa_at_load64_acq(&h->hdr->sum);
    out->min      = out->count ? sa_at_load64_acq(&h->hdr->min) : 0;
    out->max      = sa_at_load64_acq(&h->hdr->max);
    out->over     = sa_at_load64_acq(&h->hdr->over);
    out->nbuckets = h->nbuckets;
    out->sigbits  = h->sigbits;
}

static uint64_t sa_abi_hist_low(const sa_hist *h, uint64_t i) {
    return (h && i < h->nbuckets) ? sa_hist_low(i, h->sigbits) : 0;
}
static uint64_t sa_abi_hist_high(const sa_hist *h, uint64_t i) {
    return (h && i < h->nbuckets) ? sa_hist_high(i, h->sigbits) : 0;
}
static uint64_t sa_abi_hist_count(const sa_hist *h, uint64_t i) {
    return (h && i < h->nbuckets) ? sa_at_load64_acq(&h->buckets[i]) : 0;
}

static sa_cache *sa_abi_cache_open(sa_region *r, const char *name, size_t nlen,
                                   uint64_t capacity, uint32_t ways,
                                   uint32_t entry_size, int *err)
{
    sa_reg *e;
    uint64_t nbuckets;
    if (err) *err = SA_E_OK;
    if (!ways) ways = 8;
    if (ways > SA_CACHE_MAX_WAYS) ways = SA_CACHE_MAX_WAYS;
    if (capacity < ways) capacity = ways;
    nbuckets = (capacity + ways - 1) / ways;
    e = sa_carve(r, name, nlen, sa_cache_bytes(nbuckets, ways, entry_size),
                 SA_T_CACHE, err);
    if (!e) return NULL;
    return sa_cache_bind(r, e, nbuckets, ways, entry_size, err);
}

static void sa_abi_cache_counts(sa_cache *c, sa_cache_counts *out) {
    if (!out) return;
    if (!c) { memset(out, 0, sizeof *out); return; }
    sa_cache_flush(c);        /* this process's own counts, exactly */
    out->hits      = sa_at_load64_acq(&c->hdr->hits);
    out->misses    = sa_at_load64_acq(&c->hdr->misses);
    out->evictions = sa_at_load64_acq(&c->hdr->evictions);
    out->expired   = sa_at_load64_acq(&c->hdr->expired);
    out->live      = sa_cache_live(c);
    out->capacity  = c->nbuckets * c->nways;
    out->ways      = c->nways;
}

static uint64_t sa_abi_cache_pair_max(const sa_cache *c) {
    return c ? c->pair_max : 0;
}

/* ---- the rate limiter ------------------------------------------------------
 *
 * The Perl surface scales `limit` into 1/1024ths and rounds `slots` up to a
 * power of two; a C consumer must get the same limiter for the same numbers,
 * so the conversion lives here rather than in either caller. */
static sa_rate *sa_abi_rate_open(sa_region *r, const char *name, size_t nlen,
                                 uint64_t limit, uint64_t window_ms,
                                 uint64_t slots, int *err)
{
    sa_reg *e;
    uint64_t nslots, burst_u;

    if (err) *err = SA_E_OK;
    if (!limit) limit = 1;
    if (limit > 0x3FFFFFu) limit = 0x3FFFFFu;
    if (!window_ms) window_ms = 60000;
    burst_u = limit * SA_RATE_SCALE;
    nslots  = sa_rate_pow2(slots ? slots : 4096);

    e = sa_carve(r, name, nlen, sa_rate_bytes(nslots), SA_T_RATE, err);
    if (!e) return NULL;
    return sa_rate_bind(r, e, nslots, burst_u, window_ms, err);
}

/* Whole requests in, whole requests out: the 1/1024ths are this dist's
 * business and not a consumer's. */
static int sa_abi_rate_allow(sa_rate *rl, const char *key, uint32_t klen,
                             uint64_t cost, uint64_t *left, uint64_t *retry_ms)
{
    uint64_t l = 0;
    int ok;
    if (!rl) { if (left) *left = 0; if (retry_ms) *retry_ms = 0; return 1; }
    if (!cost) cost = 1;
    ok = sa_rate_take(rl, key, klen, cost * SA_RATE_SCALE, 0, &l, retry_ms);
    if (left) *left = l / SA_RATE_SCALE;
    return ok;
}

static int sa_abi_rate_peek(sa_rate *rl, const char *key, uint32_t klen,
                            uint64_t *left, uint64_t *retry_ms)
{
    uint64_t l = 0;
    int ok;
    if (!rl) { if (left) *left = 0; if (retry_ms) *retry_ms = 0; return 1; }
    ok = sa_rate_take(rl, key, klen, SA_RATE_SCALE, 1, &l, retry_ms);
    if (left) *left = l / SA_RATE_SCALE;
    return ok;
}

static uint64_t sa_abi_rate_slots(const sa_rate *rl) {
    return rl ? rl->nslots : 0;
}

static uint64_t sa_abi_rate_used(sa_rate *rl) {
    return rl ? sa_rate_used(rl) : 0;
}

/* ---- the count-min sketch --------------------------------------------------
 *
 * The Perl surface rounds the width up to a power of two and derives the shape
 * from error and confidence; a C consumer must get the same sketch for the
 * same numbers, so the conversion lives here rather than in either caller. */
static sa_cms *sa_abi_cms_open(sa_region *r, const char *name, size_t nlen,
                               double error, double confidence,
                               uint32_t rows, uint64_t width, int *err)
{
    sa_reg *e;
    uint32_t d = 0;
    uint64_t w = 0;

    if (err) *err = SA_E_OK;
    if (rows || width) {
        d = rows ? rows : 5;
        w = sa_cms_pow2(width ? width : 2048);
        if (d > SA_CMS_MAX_ROWS) d = SA_CMS_MAX_ROWS;
    }
    else {
        sa_cms_size(error, confidence, &d, &w);
    }

    e = sa_carve(r, name, nlen, sa_cms_bytes(d, w), SA_T_CMS, err);
    if (!e) return NULL;
    return sa_cms_bind(r, e, d, w, err);
}

static uint64_t sa_abi_cms_total(sa_cms *s) {
    return s ? sa_at_load64_acq(&s->hdr->total) : 0;
}
static uint32_t sa_abi_cms_rows(const sa_cms *s)  { return s ? s->rows  : 0; }
static uint64_t sa_abi_cms_width(const sa_cms *s) { return s ? s->width : 0; }

/* ---- the cuckoo filter ------------------------------------------------------
 *
 * Capacity is the one number either surface takes, and both turn it into
 * buckets through sa_cuckoo_buckets, so a C consumer and a Perl one naming the
 * same capacity get the same filter and can attach to each other's. */
static sa_cuckoo *sa_abi_cuckoo_open(sa_region *r, const char *name,
                                     size_t nlen, uint64_t capacity, int *err)
{
    sa_reg *e;
    uint64_t b;

    if (err) *err = SA_E_OK;
    b = sa_cuckoo_buckets(capacity);
    e = sa_carve(r, name, nlen, sa_cuckoo_bytes(b), SA_T_CUCKOO, err);
    if (!e) return NULL;
    return sa_cuckoo_bind(r, e, b, capacity, err);
}

static void sa_abi_cuckoo_counts(sa_cuckoo *c, sa_cuckoo_counts *out) {
    if (!out) return;
    memset(out, 0, sizeof *out);
    if (!c) return;
    out->slots    = c->buckets * SA_CK_LANES;
    out->buckets  = c->buckets;
    out->capacity = c->hdr->capacity;
#if SA_HAVE_ATOMICS
    out->count     = sa_at_load64_acq(&c->hdr->count);
    out->kicks     = sa_at_load64_acq(&c->hdr->kicks);
    out->moves     = sa_at_load64_acq(&c->hdr->moves);
    out->full      = sa_at_load64_acq(&c->hdr->full);
    out->recovered = sa_at_load64_acq(&c->hdr->recovered);
#endif
}

/* ---- the lease ------------------------------------------------------------- */

static sa_lease *sa_abi_lease_open(sa_region *r, const char *name, size_t nlen,
                                   int *err)
{
    if (err) *err = SA_E_OK;
    if (!r) { if (err) *err = SA_E_NOENT; return NULL; }
#if SA_HAVE_ATOMICS
    return sa_lease_bind(r, name, (uint32_t)nlen, err);
#else
    (void)name; (void)nlen;
    if (err) *err = SA_E_NOATOMICS;
    return NULL;
#endif
}

/* sa_lease_acquire / _renew / _release / _mine / _holder / _fence and
 * sa_lease_free already match the ABI signatures exactly, so the table points
 * straight at them. */

/* ---- the scoreboard -------------------------------------------------------- */

static sa_sb *sa_abi_sb_open(sa_region *r, const char *name, size_t nlen,
                             const char *const *fields, uint32_t nfields,
                             uint32_t slots, int *err)
{
    sa_reg *e;
    uint64_t want;

    if (err) *err = SA_E_OK;
    if (!r) { if (err) *err = SA_E_NOENT; return NULL; }
#if SA_HAVE_ATOMICS
    /* `slots` of 0 inherits an existing board, the same as the Perl surface. */
    if (slots) {
        if (slots > SA_SB_SLOTS_MAX) slots = SA_SB_SLOTS_MAX;
        want = sa_sb_bytes(slots);
    }
    else if (sa_find(r, name, nlen)) {
        want = 0;
    }
    else {
        want = sa_sb_bytes(256);
    }
    e = sa_carve(r, name, nlen, want, SA_T_SCOREBOARD, err);
    if (!e) return NULL;
    return sa_sb_bind(r, e, fields, nfields, err);
#else
    (void)name; (void)nlen; (void)fields; (void)nfields; (void)slots; (void)want;
    if (err) *err = SA_E_NOATOMICS;
    return NULL;
#endif
}

/* The write side passes the row as an opaque void* in the ABI, so these cast it
 * back. sa_sb_take / sa_sb_field / sa_sb_read / sa_sb_free match directly. */
static void *sa_abi_sb_begin(sa_sb *b) {
#if SA_HAVE_ATOMICS
    return (void *)sa_sb_begin(b);
#else
    (void)b; return NULL;
#endif
}
static void sa_abi_sb_set_gauge(void *row, int idx, uint64_t v) {
#if SA_HAVE_ATOMICS
    sa_sb_set_gauge((sa_sb_slot *)row, idx, v);
#else
    (void)row; (void)idx; (void)v;
#endif
}
static void sa_abi_sb_add_gauge(void *row, int idx, int64_t by) {
#if SA_HAVE_ATOMICS
    sa_sb_add_gauge((sa_sb_slot *)row, idx, by);
#else
    (void)row; (void)idx; (void)by;
#endif
}
static void sa_abi_sb_set_status(void *row, const char *p, uint32_t n) {
#if SA_HAVE_ATOMICS
    sa_sb_set_status((sa_sb_slot *)row, p, n);
#else
    (void)row; (void)p; (void)n;
#endif
}
static void sa_abi_sb_end(sa_sb *b, void *row) {
#if SA_HAVE_ATOMICS
    sa_sb_end(b, (sa_sb_slot *)row);
#else
    (void)b; (void)row;
#endif
}
static uint64_t sa_abi_sb_slots(const sa_sb *b) { return b ? b->nslots : 0; }
static uint32_t sa_abi_sb_nfields(const sa_sb *b) { return b ? b->nfields : 0; }
static const char *sa_abi_sb_field_name(const sa_sb *b, uint32_t idx) {
    if (!b || idx >= b->nfields) return NULL;
    return b->hdr->fields[idx];
}

/* ---- queue groups ---------------------------------------------------------- */

static sa_group_h *sa_abi_group_open(sa_ring *r, const char *name, size_t nlen,
                                     const char *topic, size_t tlen,
                                     int from_start, int *err)
{
    uint64_t from = 0;
    if (err) *err = SA_E_OK;
    if (!r) { if (err) *err = SA_E_NOENT; return NULL; }
#if SA_HAVE_ATOMICS
    if (from_start) {
        uint64_t end = sa_at_load64_acq(&r->hdr->seq);
        from = (end > r->nslots) ? end - r->nslots : 1;
    }
    return sa_group_new(r, name, (uint32_t)nlen, topic, (uint32_t)tlen,
                        from, err);
#else
    (void)name; (void)nlen; (void)topic; (void)tlen; (void)from_start;
    (void)from;
    if (err) *err = SA_E_NOATOMICS;
    return NULL;
#endif
}

static int sa_abi_group_claim(sa_group_h *gh, uint64_t *seq,
                              const char **topic, uint32_t *tlen,
                              const char **data, uint32_t *dlen,
                              uint32_t *flags)
{
#if SA_HAVE_ATOMICS
    if (!gh) return SA_READ_PENDING;
    /* Claiming is proof of life, exactly as draining is: a member that only
     * ever consumes must still tick, or a publisher's hole check would judge
     * it wedged. */
    sa_peer_join(gh->ring->arena);
    sa_peer_beat(gh->ring->arena);
    {
        int rc = sa_group_claim(gh->ring, gh->g, gh->scratch, seq, topic, tlen,
                                data, dlen, flags);
        if (rc == SA_READ_OK) gh->claimed++;
        return rc;
    }
#else
    (void)gh; (void)seq; (void)topic; (void)tlen; (void)data; (void)dlen;
    (void)flags;
    return SA_READ_PENDING;
#endif
}

static uint64_t sa_abi_group_position(const sa_group_h *gh) {
#if SA_HAVE_ATOMICS
    return gh ? sa_at_load64_acq(&gh->g->cursor) : 0;
#else
    (void)gh;
    return 0;
#endif
}

static void sa_abi_group_counts(const sa_group_h *gh, sa_group_counts *out) {
    if (!out) return;
    if (!gh) { memset(out, 0, sizeof *out); return; }
#if SA_HAVE_ATOMICS
    out->position  = sa_at_load64_acq(&gh->g->cursor);
    out->delivered = sa_at_load64_acq(&gh->g->delivered);
    out->lapped    = sa_at_load64_acq(&gh->g->lapped);
    out->skipped   = sa_at_load64_acq(&gh->g->skipped);
#else
    memset(out, 0, sizeof *out);
#endif
    out->mine = gh->claimed;
}

static const sa_abi SA_ABI = {
    SA_ABI_VERSION,

    sa_abi_config_init,
    sa_abi_create,
    sa_abi_attach,
    sa_abi_release,
    sa_abi_destroy,
    sa_strerror,
    sa_abi_bytes,
    sa_abi_is_creator,

    sa_abi_carve,
    sa_abi_locate,
    sa_ptr,

    sa_abi_ring_open,
    sa_ring_free,
    sa_abi_publish,
    sa_abi_max_record,
    sa_abi_slot_bytes,
    sa_abi_ring_slots,
    sa_abi_ring_position,

    sa_cursor_new,
    sa_cursor_free,
    sa_cursor_drain,
    sa_abi_counts,

    sa_peer_join,
    sa_peer_beat,

    /* the map */
    sa_abi_map_open,
    sa_hash_free,
    sa_hash_store,
    sa_hash_fetch,
    sa_hash_delete,
    sa_hash_incr,
    sa_abi_map_counts,
    sa_abi_map_pair_max,
    sa_abi_map_capacity,

    /* the filter */
    sa_abi_bloom_open,
    sa_bloom_free,
    sa_bloom_add,
    sa_bloom_check,
    sa_bloom_reset,
    sa_abi_bloom_bits,
    sa_abi_bloom_hashes,
    sa_bloom_popcount,
    sa_bloom_estimate,

    /* the histogram */
    sa_abi_hist_open,
    sa_hist_free,
    sa_hist_record,
    sa_hist_quantile,
    sa_hist_reset,
    sa_abi_hist_counts,
    sa_abi_hist_low,
    sa_abi_hist_high,
    sa_abi_hist_count,

    /* the cache */
    sa_abi_cache_open,
    sa_cache_free,
    sa_cache_set,
    sa_cache_get,
    sa_cache_remove,
    sa_cache_clear,
    sa_abi_cache_counts,
    sa_abi_cache_pair_max,

    /* the rate limiter */
    sa_abi_rate_open,
    sa_rate_free,
    sa_abi_rate_allow,
    sa_abi_rate_peek,
    sa_rate_reset_key,
    sa_rate_forget,
    sa_abi_rate_slots,
    sa_abi_rate_used,

    /* the count-min sketch */
    sa_abi_cms_open,
    sa_cms_free,
    sa_cms_add,
    sa_cms_estimate,
    sa_cms_reset,
    sa_abi_cms_total,
    sa_cms_error,
    sa_abi_cms_rows,
    sa_abi_cms_width,

    /* queue groups */
    sa_abi_group_open,
    sa_group_free,
    sa_abi_group_claim,
    sa_abi_group_position,
    sa_abi_group_counts,

    /* map, with a TTL */
    sa_hash_store_ttl,

    /* the cuckoo filter */
    sa_abi_cuckoo_open,
    sa_cuckoo_free,
    sa_cuckoo_add,
    sa_cuckoo_check,
    sa_cuckoo_remove,
    sa_cuckoo_reset,
    sa_abi_cuckoo_counts,

    /* the lease */
    sa_abi_lease_open,
    sa_lease_free,
    sa_lease_acquire,
    sa_lease_renew,
    sa_lease_release,
    sa_lease_mine,
    sa_lease_holder,
    sa_lease_fence,

    /* the scoreboard */
    sa_abi_sb_open,
    sa_sb_free,
    sa_sb_take,
    sa_sb_field,
    sa_abi_sb_begin,
    sa_abi_sb_set_gauge,
    sa_abi_sb_add_gauge,
    sa_abi_sb_set_status,
    sa_abi_sb_end,
    sa_sb_read,
    sa_abi_sb_slots,
    sa_abi_sb_nfields,
    sa_abi_sb_field_name
};

/* ---- the selftest ---------------------------------------------------------
 *
 * A region, a ring and a cursor driven through EVERY entry of the table, with
 * every answer checked. It exists because a table is a list of addresses and
 * nothing about compiling one proves an entry points where its declaration
 * says: a member inserted in the middle, or two entries of the same shape
 * swapped, compiles clean and answers wrong.
 *
 * Numbered steps, and the number of the first that failed comes back, so a
 * failure says WHICH. A selftest that reports only "no" sends somebody to read
 * the whole table.
 */

#define SA_STEP(n) do { *step = (n); } while (0)

typedef struct {
    int      n;
    int      bad;
    char     last[64];
    uint32_t lastlen;
    uint32_t span;      /* the length of the most recent record */
} sa_abi_seen;

static void sa_abi_selftest_rec(void *ud, uint64_t seq,
                                const char *topic, uint32_t tlen,
                                const char *data, uint32_t dlen, uint32_t flags)
{
    sa_abi_seen *s = (sa_abi_seen *)ud;
    (void)seq; (void)flags;
    s->n++;
    if (tlen != 1 || topic[0] != 't') s->bad = 1;
    s->span = dlen;
    if (dlen >= sizeof s->last) return;   /* a long one: length is enough */
    memcpy(s->last, data, dlen);
    s->lastlen = dlen;
}

/* Returns 0 when every entry answered as its declaration says, and otherwise
 * the number of the check that did not. */
static int sa_abi_selftest(void)
{
    const sa_abi *A = &SA_ABI;
    int stepv = 0;
    int *step = &stepv;
    int err = SA_E_OK;
    sa_config cfg;
    sa_region *r = NULL;
    sa_ring *ring = NULL;
    sa_cursor *cur = NULL;
    uint64_t off, len = 0;
    sa_counts n;
    sa_abi_seen seen;

    /* 1: the version the header promised */
    if (A->abi_version < SA_ABI_VERSION) { SA_STEP(1); goto done; }

    /* 2: defaults are a function, not a zeroed struct */
    memset(&cfg, 0xFF, sizeof cfg);
    A->config_init(&cfg);
    if (!cfg.bytes || !cfg.regions || cfg.name) { SA_STEP(2); goto done; }

    /* 3: create an anonymous region */
    cfg.bytes = 512 * 1024;
    r = A->create(&cfg, &err);
#if !SA_HAVE_ATOMICS
    /* With no atomics the table's answer is that there is no region, and it
     * must give that answer as NULL and a code, never a pointer - for attach
     * as for create. Every later check needs a region, so this is the whole of
     * the test in this build. */
    if (r || err != SA_E_NOATOMICS || !A->errstr(err)) { SA_STEP(3); goto done; }
    err = SA_E_OK;
    r = A->attach_named("sa-selftest", 11, &err);
    if (r || err != SA_E_NOATOMICS) { SA_STEP(3); goto done; }
    goto done;
#endif
    if (!r || err != SA_E_OK) { SA_STEP(3); goto done; }
    if (!A->is_creator(r)) { SA_STEP(3); goto done; }
    if (A->region_bytes(r) < cfg.bytes) { SA_STEP(3); goto done; }

    /* 4: a refusal is NULL and a code, never a crash, and errstr renders it */
    {
        int e2 = SA_E_OK;
        sa_region *bad = A->attach_named("sa-nope-nobody-made-this", 24, &e2);
        if (bad) { A->release(bad); SA_STEP(4); goto done; }
        if (e2 == SA_E_OK || !A->errstr(e2)) { SA_STEP(4); goto done; }
        if (!A->errstr(SA_E_MAGIC)) { SA_STEP(4); goto done; }
    }

    /* 5: carve, locate, and the pointer an offset resolves to */
    off = A->carve(r, "scratch", 7, 1024, SA_T_RAW, &len, &err);
    if (!off || len != 1024) { SA_STEP(5); goto done; }
    if (A->locate(r, "scratch", 7, NULL) != off) { SA_STEP(5); goto done; }
    if (A->locate(r, "absent", 6, NULL) != 0) { SA_STEP(5); goto done; }
    /* Carving the same name again finds it rather than making a second one. */
    if (A->carve(r, "scratch", 7, 1024, SA_T_RAW, NULL, &err) != off)
        { SA_STEP(5); goto done; }

    /* 6: `at` is the one place an offset becomes a pointer, and it is inside
     * the mapping rather than anywhere else */
    {
        char *p = (char *)A->at(r, off);
        if (!p) { SA_STEP(6); goto done; }
        memcpy(p, "written through the table", 25);
        if (memcmp((char *)A->at(r, off), "written through the table", 25))
            { SA_STEP(6); goto done; }
        if (A->at(r, A->region_bytes(r) + 4096)) { SA_STEP(6); goto done; }
    }

    /* 7: a ring, and its geometry as runtime answers */
    ring = A->ring_open(r, "events", 6, 32, 256, &err);
    if (!ring || err != SA_E_OK) { SA_STEP(7); goto done; }
    if (A->ring_slots(ring) != 32) { SA_STEP(7); goto done; }
    /* The spanned maximum: a record may cross up to half the ring, so it is
     * larger than one slot and smaller than the whole thing. A consumer that
     * compiled either number in would be wrong the day the ring is
     * reconfigured, which is why this is an entry and not a constant. */
    if (A->max_record(ring) <= 256) { SA_STEP(7); goto done; }
    if (A->max_record(ring) >= 32 * 256) { SA_STEP(7); goto done; }
    /* One slot carries less than its own size, because the header is in it,
     * and the spanned maximum is a multiple of that. */
    if (A->slot_bytes(ring) == 0 || A->slot_bytes(ring) >= 256)
        { SA_STEP(7); goto done; }
    if (A->max_record(ring) % A->slot_bytes(ring) != 0)
        { SA_STEP(7); goto done; }

    /* 8: publish returns the record's sequence, and refuses an oversize one */
    {
        int64_t s1 = A->publish(ring, "t", 1, "one", 3);
        int64_t s2 = A->publish(ring, "t", 1, "two", 3);
        if (!SA_PUBLISHED(s1) || !SA_PUBLISHED(s2) || s2 <= s1)
            { SA_STEP(8); goto done; }
        if (A->ring_position(ring) <= (uint64_t)s2) { SA_STEP(8); goto done; }
    }
    {
        /* A record that spans several slots is carried; one larger than the
         * ring will hold is refused, never truncated. */
        char big[4096];
        uint64_t cap = A->max_record(ring);
        memset(big, 'x', sizeof big);
        if (!SA_PUBLISHED(A->publish(ring, "t", 1, big, 600)))
            { SA_STEP(8); goto done; }
        if (cap + 1 <= sizeof big
            && A->publish(ring, "t", 1, big, (uint32_t)(cap + 1)) != SA_TOO_BIG)
            { SA_STEP(8); goto done; }
    }

    /* 9: a cursor from the start replays what the ring still holds */
    cur = A->cursor_open(ring, 1);
    if (!cur) { SA_STEP(9); goto done; }
    seen.n = 0; seen.bad = 0; seen.lastlen = 0; seen.span = 0;
    if (A->drain(cur, 0, sa_abi_selftest_rec, &seen) != 3)
        { SA_STEP(9); goto done; }
    if (seen.bad || seen.n != 3) { SA_STEP(9); goto done; }
    /* The last one was the 600-byte record, gathered from several slots and
     * handed over as one. */
    if (seen.span != 600) { SA_STEP(9); goto done; }

    /* 10: and a second drain has nothing to add */
    if (A->drain(cur, 0, sa_abi_selftest_rec, &seen) != 0)
        { SA_STEP(10); goto done; }

    /* 11: the counts, and the four kinds of outcome kept apart */
    A->counts(cur, &n);
    if (n.delivered != 3 || n.lapped != 0 || n.abandoned != 0
        || n.unattributed != 0) { SA_STEP(11); goto done; }
    if (n.position != A->ring_position(ring)) { SA_STEP(11); goto done; }

    /* 12: `max` limits a drain, and the rest is still there afterwards */
    {
        int i;
        sa_cursor *c2 = A->cursor_open(ring, 0);
        if (!c2) { SA_STEP(12); goto done; }
        for (i = 0; i < 5; i++) A->publish(ring, "t", 1, "n", 1);
        seen.n = 0; seen.bad = 0;
        if (A->drain(c2, 2, sa_abi_selftest_rec, &seen) != 2)
            { A->cursor_release(c2); SA_STEP(12); goto done; }
        if (A->drain(c2, 0, sa_abi_selftest_rec, &seen) != 3)
            { A->cursor_release(c2); SA_STEP(12); goto done; }
        A->cursor_release(c2);
    }

    /* 13: overflow is drop-oldest, counted, and never silent */
    {
        int i;
        sa_cursor *c3 = A->cursor_open(ring, 0);
        sa_counts m;
        if (!c3) { SA_STEP(13); goto done; }
        for (i = 0; i < 100; i++) A->publish(ring, "t", 1, "flood", 5);
        seen.n = 0; seen.bad = 0;
        A->drain(c3, 0, sa_abi_selftest_rec, &seen);
        A->counts(c3, &m);
        if (m.lapped == 0) { A->cursor_release(c3); SA_STEP(13); goto done; }
        if (m.delivered + m.lapped != 100)
            { A->cursor_release(c3); SA_STEP(13); goto done; }
        /* The counters must be DISTINGUISHABLE here, and this is the only
         * place in the selftest where they are: at step 11 everything but
         * `delivered` is zero, so a table that reported one counter where
         * another belongs would answer correctly by accident. Here `lapped` is
         * large and the other two must still be nothing. */
        if (m.abandoned != 0 || m.unattributed != 0)
            { A->cursor_release(c3); SA_STEP(13); goto done; }
        if (m.position != A->ring_position(ring))
            { A->cursor_release(c3); SA_STEP(13); goto done; }
        A->cursor_release(c3);
    }

    /* 14: liveness - this process is registered, and a beat moves it on */
    if (!A->join(r)) { SA_STEP(14); goto done; }
    {
        sa_peer *p = &SA_PEERS(r->map.base, r->hdr)[r->peer_idx];
        uint64_t hb = sa_at_load64_acq(&p->heartbeat);
        A->beat(r);
        if (sa_at_load64_acq(&p->heartbeat) <= hb) { SA_STEP(14); goto done; }
    }

    /* 15: the map, through the table: store, fetch, overwrite, delete, the
     * counter that is one atomic, and a full table that refuses rather than
     * growing. */
    {
        sa_hash *mp = A->map_open(r, "sel", 3, 16, 128, &err);
        char buf[128];
        uint32_t vl = 0;
        uint64_t now = 0;
        sa_map_counts mc;
        int i;

        if (!mp || err != SA_E_OK) { SA_STEP(15); goto done; }
        if (A->map_capacity(mp) != 16 || A->map_pair_max(mp) == 0)
            { A->map_release(mp); SA_STEP(15); goto done; }

        if (A->map_store(mp, "k", 1, "one", 3) != SA_H_OK)
            { A->map_release(mp); SA_STEP(15); goto done; }
        if (A->map_fetch(mp, "k", 1, buf, sizeof buf, &vl) != SA_MAP_HIT
            || vl != 3 || memcmp(buf, "one", 3))
            { A->map_release(mp); SA_STEP(15); goto done; }
        if (A->map_fetch(mp, "nope", 4, buf, sizeof buf, &vl) != SA_MAP_MISS)
            { A->map_release(mp); SA_STEP(15); goto done; }

        if (A->map_store(mp, "k", 1, "two", 3) != SA_H_OK)
            { A->map_release(mp); SA_STEP(15); goto done; }
        if (A->map_fetch(mp, "k", 1, buf, sizeof buf, &vl) != SA_MAP_HIT
            || vl != 3 || memcmp(buf, "two", 3))
            { A->map_release(mp); SA_STEP(15); goto done; }

        if (A->map_incr(mp, "c", 1, 5, &now) != SA_H_OK || now != 5)
            { A->map_release(mp); SA_STEP(15); goto done; }
        if (A->map_incr(mp, "c", 1, -2, &now) != SA_H_OK || now != 3)
            { A->map_release(mp); SA_STEP(15); goto done; }
        /* a counter is refused on an entry that is not one */
        if (A->map_incr(mp, "k", 1, 1, &now) != SA_H_NOTNUM)
            { A->map_release(mp); SA_STEP(15); goto done; }

        if (!A->map_delete(mp, "k", 1) || A->map_delete(mp, "k", 1))
            { A->map_release(mp); SA_STEP(15); goto done; }

        A->map_counts(mp, &mc);
        if (mc.capacity != 16 || mc.tombstones != 1 || mc.used != 1)
            { A->map_release(mp); SA_STEP(15); goto done; }

        /* map_store_ttl through the table: a far deadline stores and reads
         * like any other entry. The expiry itself needs a clock the selftest
         * cannot advance, so real lapsing is a Perl test's job; this proves the
         * entry points at a working function. */
        if (A->map_store_ttl(mp, "ttl", 3, "live", 4, 3600000ULL) != SA_H_OK)
            { A->map_release(mp); SA_STEP(15); goto done; }
        if (A->map_fetch(mp, "ttl", 3, buf, sizeof buf, &vl) != SA_MAP_HIT
            || vl != 4 || memcmp(buf, "live", 4))
            { A->map_release(mp); SA_STEP(15); goto done; }
        if (!A->map_delete(mp, "ttl", 3))
            { A->map_release(mp); SA_STEP(15); goto done; }

        /* fill it and check the ceiling refuses rather than growing */
        for (i = 0; i < 32; i++) {
            char kb[16];
            int n = sprintf(kb, "f%d", i);
            (void)A->map_store(mp, kb, (uint32_t)n, "x", 1);
        }
        A->map_counts(mp, &mc);
        if (mc.used > mc.capacity || mc.full == 0)
            { A->map_release(mp); SA_STEP(15); goto done; }

        A->map_release(mp);
    }

    /* 16: the filter. The guarantee that matters is one-directional, so it is
     * the one asserted: everything added must check true. A false positive is
     * allowed and cannot be asserted against; a false NEGATIVE is a bug. */
    {
        sa_bloom *bl = A->bloom_open(r, "selb", 4, 1000, 0.01, 0, 0, &err);
        int i, bad = 0;
        char kb[16];

        if (!bl || err != SA_E_OK) { SA_STEP(16); goto done; }
        if (A->bloom_bits(bl) == 0 || A->bloom_hashes(bl) == 0)
            { A->bloom_release(bl); SA_STEP(16); goto done; }
        if (A->bloom_set(bl) != 0) { A->bloom_release(bl); SA_STEP(16); goto done; }

        if (A->bloom_add(bl, "one", 3) != 0)   /* new */
            { A->bloom_release(bl); SA_STEP(16); goto done; }
        if (A->bloom_add(bl, "one", 3) != 1)   /* and now seen */
            { A->bloom_release(bl); SA_STEP(16); goto done; }
        if (!A->bloom_check(bl, "one", 3))
            { A->bloom_release(bl); SA_STEP(16); goto done; }

        for (i = 0; i < 200; i++) {
            int n = sprintf(kb, "b%d", i);
            (void)A->bloom_add(bl, kb, (uint32_t)n);
        }
        for (i = 0; i < 200; i++) {
            int n = sprintf(kb, "b%d", i);
            if (!A->bloom_check(bl, kb, (uint32_t)n)) bad++;
        }
        if (bad) { A->bloom_release(bl); SA_STEP(16); goto done; }
        if (A->bloom_set(bl) == 0 || A->bloom_estimate(bl) == 0)
            { A->bloom_release(bl); SA_STEP(16); goto done; }

        A->bloom_reset(bl);
        if (A->bloom_set(bl) != 0 || A->bloom_check(bl, "one", 3))
            { A->bloom_release(bl); SA_STEP(16); goto done; }

        A->bloom_release(bl);
    }

    /* 17: the histogram. The assertion is the BOUND, not a number: a value
     * must come back at or above itself and within the relative error the
     * scheme promises, and small values must be exact. */
    {
        sa_hist *hh = A->hist_open(r, "selh", 4, 100000, 4, &err);
        sa_hist_counts hc;
        uint64_t q;
        int i;

        if (!hh || err != SA_E_OK) { SA_STEP(17); goto done; }

        for (i = 1; i <= 1000; i++) A->hist_record(hh, (uint64_t)i, 1);
        A->hist_counts(hh, &hc);
        if (hc.count != 1000 || hc.sum != 500500) { A->hist_release(hh); SA_STEP(17); goto done; }
        if (hc.min != 1 || hc.max != 1000) { A->hist_release(hh); SA_STEP(17); goto done; }
        if (hc.over != 0 || hc.sigbits != 4) { A->hist_release(hh); SA_STEP(17); goto done; }

        /* the median, never below and never further above than 1/16 */
        q = A->hist_quantile(hh, 0.5);
        if (q < 500 || q > 500 + 500 / 16 + 1)
            { A->hist_release(hh); SA_STEP(17); goto done; }

        /* below 2^sigbits a bucket is one unit wide, so this is exact */
        if (A->hist_bucket_low(hh, 7) != 7 || A->hist_bucket_high(hh, 7) != 7)
            { A->hist_release(hh); SA_STEP(17); goto done; }
        if (A->hist_bucket_count(hh, 7) != 1)
            { A->hist_release(hh); SA_STEP(17); goto done; }

        /* past the ceiling: counted apart, and the maximum does not move */
        A->hist_record(hh, 999999999ULL, 3);
        A->hist_counts(hh, &hc);
        if (hc.over != 3 || hc.count != 1000 || hc.max != 1000)
            { A->hist_release(hh); SA_STEP(17); goto done; }

        A->hist_reset(hh);
        A->hist_counts(hh, &hc);
        if (hc.count || hc.sum || hc.over)
            { A->hist_release(hh); SA_STEP(17); goto done; }

        A->hist_release(hh);
    }

    /* 18: the cache. What separates it from the map is that it never refuses
     * for want of room, so that is what is asserted: far more keys than it
     * holds, and every set succeeding. */
    {
        sa_cache *cc = A->cache_open(r, "selc", 4, 16, 8, 128, &err);
        sa_cache_counts cn;
        char buf[128], kb[16];
        uint32_t vl = 0;
        int i, refused = 0;

        if (!cc || err != SA_E_OK) { SA_STEP(18); goto done; }
        if (A->cache_pair_max(cc) == 0) { A->cache_release(cc); SA_STEP(18); goto done; }

        if (A->cache_set(cc, "k", 1, "one", 3, 0) != SA_C_OK)
            { A->cache_release(cc); SA_STEP(18); goto done; }
        if (A->cache_get(cc, "k", 1, buf, sizeof buf, &vl) != SA_MAP_HIT
            || vl != 3 || memcmp(buf, "one", 3))
            { A->cache_release(cc); SA_STEP(18); goto done; }
        if (A->cache_get(cc, "no", 2, buf, sizeof buf, &vl) != SA_MAP_MISS)
            { A->cache_release(cc); SA_STEP(18); goto done; }

        /* an entry already past its deadline is a miss, not stale data */
        if (A->cache_set(cc, "dead", 4, "x", 1, 1) != SA_C_OK)
            { A->cache_release(cc); SA_STEP(18); goto done; }
        sa_stall(20000);
        if (A->cache_get(cc, "dead", 4, buf, sizeof buf, &vl) != SA_MAP_MISS)
            { A->cache_release(cc); SA_STEP(18); goto done; }

        /* ten times its capacity, and not one refusal */
        for (i = 0; i < 160; i++) {
            int n = sprintf(kb, "c%d", i);
            if (A->cache_set(cc, kb, (uint32_t)n, "v", 1, 0) != SA_C_OK)
                refused++;
        }
        if (refused) { A->cache_release(cc); SA_STEP(18); goto done; }

        A->cache_counts(cc, &cn);
        if (cn.evictions == 0 || cn.live > cn.capacity || cn.ways != 8)
            { A->cache_release(cc); SA_STEP(18); goto done; }
        if (cn.hits == 0 || cn.misses == 0)
            { A->cache_release(cc); SA_STEP(18); goto done; }

        if (!A->cache_remove(cc, "c159", 4))
            { A->cache_release(cc); SA_STEP(18); goto done; }
        A->cache_clear(cc);
        A->cache_counts(cc, &cn);
        if (cn.live != 0) { A->cache_release(cc); SA_STEP(18); goto done; }

        A->cache_release(cc);
    }

    /* 19: the rate limiter. A burst of three with a refill window long enough
     * that nothing comes back while this runs, so the answers are exact rather
     * than a race against the clock. */
    {
        sa_rate *rl = A->rate_open(r, "selr", 4, 3, 3600000, 64, &err);
        uint64_t left = 0, retry = 0;
        int i;

        if (!rl || err != SA_E_OK) { SA_STEP(19); goto done; }
        if (A->rate_slots(rl) < 64) { A->rate_release(rl); SA_STEP(19); goto done; }

        for (i = 0; i < 3; i++)
            if (!A->rate_allow(rl, "k", 1, 1, &left, &retry))
                { A->rate_release(rl); SA_STEP(19); goto done; }
        if (left != 0) { A->rate_release(rl); SA_STEP(19); goto done; }

        /* Spent. The fourth is refused and told when to come back. */
        if (A->rate_allow(rl, "k", 1, 1, &left, &retry))
            { A->rate_release(rl); SA_STEP(19); goto done; }
        if (retry == 0) { A->rate_release(rl); SA_STEP(19); goto done; }

        /* Another key has its own bucket, and peeking spends nothing. */
        if (!A->rate_peek(rl, "other", 5, &left, &retry))
            { A->rate_release(rl); SA_STEP(19); goto done; }
        if (left != 3) { A->rate_release(rl); SA_STEP(19); goto done; }
        if (!A->rate_allow(rl, "other", 5, 3, &left, &retry))
            { A->rate_release(rl); SA_STEP(19); goto done; }

        A->rate_reset(rl, "k", 1);
        if (!A->rate_allow(rl, "k", 1, 1, &left, &retry))
            { A->rate_release(rl); SA_STEP(19); goto done; }
        if (A->rate_used(rl) < 2) { A->rate_release(rl); SA_STEP(19); goto done; }

        A->rate_forget(rl, "k", 1);
        A->rate_release(rl);
    }

    /* 20: the count-min sketch. A cramped one on purpose - three rows of 64 -
     * so the collisions the structure exists to tolerate actually happen, and
     * the assertion is the guarantee rather than the arithmetic: never low. */
    {
        sa_cms *cm = A->cms_open(r, "selm", 4, 0.0, 0.0, 3, 64, &err);
        char kb[16];
        int i, low = 0;

        if (!cm || err != SA_E_OK) { SA_STEP(20); goto done; }
        if (A->cms_rows(cm) != 3 || A->cms_width(cm) != 64)
            { A->cms_release(cm); SA_STEP(20); goto done; }

        /* add returns what the sketch now believes, which for the first add of
         * a key in an empty sketch is exactly one. */
        if (A->cms_add(cm, "one", 3, 1) != 1)
            { A->cms_release(cm); SA_STEP(20); goto done; }
        if (A->cms_estimate(cm, "one", 3) != 1)
            { A->cms_release(cm); SA_STEP(20); goto done; }

        for (i = 0; i < 500; i++) {
            int n = sprintf(kb, "c%d", i);
            (void)A->cms_add(cm, kb, (uint32_t)n, (uint64_t)(i % 7) + 1);
        }
        /* NEVER LOW, however hard the collisions push. */
        for (i = 0; i < 500; i++) {
            int n = sprintf(kb, "c%d", i);
            if (A->cms_estimate(cm, kb, (uint32_t)n) < (uint64_t)(i % 7) + 1)
                low++;
        }
        if (low) { A->cms_release(cm); SA_STEP(20); goto done; }

        if (A->cms_total(cm) == 0) { A->cms_release(cm); SA_STEP(20); goto done; }
        if (A->cms_error(cm) == 0) { A->cms_release(cm); SA_STEP(20); goto done; }

        A->cms_reset(cm);
        if (A->cms_estimate(cm, "one", 3) != 0)
            { A->cms_release(cm); SA_STEP(20); goto done; }
        if (A->cms_total(cm) != 0) { A->cms_release(cm); SA_STEP(20); goto done; }

        A->cms_release(cm);
    }

    /* 21: queue groups. THE ASSERTION IS THE PARTITION - two handles on ONE
     * group must divide the records between them, never both get the same one.
     * A group that broadcast would pass a test of counts and fail this. */
    {
        sa_ring *gr = A->ring_open(r, "gring", 5, 64, 256, &err);
        sa_group_h *ga = NULL, *gb = NULL;
        sa_group_counts gc;
        uint64_t s1 = 0, s2 = 0, s3 = 0;
        const char *tp = NULL, *dp = NULL;
        uint32_t tl = 0, dl = 0, fl = 0;

        if (!gr || err != SA_E_OK) { SA_STEP(21); goto done; }

        ga = A->group_open(gr, "pool", 4, NULL, 0, 0, &err);
        gb = A->group_open(gr, "pool", 4, NULL, 0, 0, &err);
        if (!ga || !gb || err != SA_E_OK) {
            if (ga) A->group_release(ga);
            if (gb) A->group_release(gb);
            A->ring_release(gr); SA_STEP(21); goto done;
        }

        /* Nothing published: a group claims nothing rather than blocking. */
        if (A->group_claim(ga, &s1, &tp, &tl, &dp, &dl, &fl) == SA_READ_OK) {
            A->group_release(ga); A->group_release(gb);
            A->ring_release(gr); SA_STEP(21); goto done;
        }

        if (A->publish(gr, "t", 1, "one", 3) < 0
         || A->publish(gr, "t", 1, "two", 3) < 0) {
            A->group_release(ga); A->group_release(gb);
            A->ring_release(gr); SA_STEP(21); goto done;
        }

        if (A->group_claim(ga, &s1, &tp, &tl, &dp, &dl, &fl) != SA_READ_OK
         || A->group_claim(gb, &s2, &tp, &tl, &dp, &dl, &fl) != SA_READ_OK) {
            A->group_release(ga); A->group_release(gb);
            A->ring_release(gr); SA_STEP(21); goto done;
        }
        /* DIFFERENT records: one each, which is the whole mechanism. */
        if (s1 == s2) {
            A->group_release(ga); A->group_release(gb);
            A->ring_release(gr); SA_STEP(21); goto done;
        }
        /* And the third claim finds the queue empty. */
        if (A->group_claim(ga, &s3, &tp, &tl, &dp, &dl, &fl) == SA_READ_OK) {
            A->group_release(ga); A->group_release(gb);
            A->ring_release(gr); SA_STEP(21); goto done;
        }

        A->group_counts(ga, &gc);
        if (gc.delivered != 2 || gc.mine != 1) {   /* the pool's, and ours */
            A->group_release(ga); A->group_release(gb);
            A->ring_release(gr); SA_STEP(21); goto done;
        }
        if (A->group_position(ga) < 2) {
            A->group_release(ga); A->group_release(gb);
            A->ring_release(gr); SA_STEP(21); goto done;
        }

        /* A group bound to a topic takes only its own and advances past the
         * rest, which is what stops one pool eating another's work. */
        {
            sa_group_h *gt = A->group_open(gr, "jobs", 4, "j", 1, 0, &err);
            if (!gt) {
                A->group_release(ga); A->group_release(gb);
                A->ring_release(gr); SA_STEP(21); goto done;
            }
            (void)A->publish(gr, "x", 1, "no", 2);
            (void)A->publish(gr, "j", 1, "yes", 3);
            if (A->group_claim(gt, &s3, &tp, &tl, &dp, &dl, &fl) != SA_READ_OK
                || dl != 3 || memcmp(dp, "yes", 3)) {
                A->group_release(gt);
                A->group_release(ga); A->group_release(gb);
                A->ring_release(gr); SA_STEP(21); goto done;
            }
            A->group_counts(gt, &gc);
            if (gc.skipped != 1) {
                A->group_release(gt);
                A->group_release(ga); A->group_release(gb);
                A->ring_release(gr); SA_STEP(21); goto done;
            }
            A->group_release(gt);
        }

        A->group_release(ga);
        A->group_release(gb);
        A->ring_release(gr);
    }

    /* 22: the cuckoo filter. Filled to 200 of its 256 slots, so keys may have
     * to move to make room, and the assertion is the guarantee rather than the
     * arithmetic: nothing added and not removed ever checks 0. */
    {
        sa_cuckoo *ck = A->cuckoo_open(r, "selk", 4, 200, &err);
        sa_cuckoo_counts cc;
        char kb[16];
        int i, n, lost = 0;

        if (!ck || err != SA_E_OK) { SA_STEP(22); goto done; }
        A->cuckoo_counts(ck, &cc);
        if (cc.slots < 200 || cc.count != 0 || cc.capacity != 200)
            { A->cuckoo_release(ck); SA_STEP(22); goto done; }

        /* Empty: an exact no, and nothing to remove. */
        if (A->cuckoo_check(ck, "one", 3) || A->cuckoo_remove(ck, "one", 3))
            { A->cuckoo_release(ck); SA_STEP(22); goto done; }

        /* In, found, out, gone - with nothing else in the filter for the
         * last answer to be a coincidence with. */
        if (!A->cuckoo_add(ck, "one", 3) || !A->cuckoo_check(ck, "one", 3))
            { A->cuckoo_release(ck); SA_STEP(22); goto done; }
        if (!A->cuckoo_remove(ck, "one", 3) || A->cuckoo_check(ck, "one", 3))
            { A->cuckoo_release(ck); SA_STEP(22); goto done; }

        for (i = 0; i < 200; i++) {
            n = sprintf(kb, "k%d", i);
            if (!A->cuckoo_add(ck, kb, (uint32_t)n))
                { A->cuckoo_release(ck); SA_STEP(22); goto done; }
        }
        for (i = 0; i < 200; i++) {
            n = sprintf(kb, "k%d", i);
            if (!A->cuckoo_check(ck, kb, (uint32_t)n)) lost++;
        }
        if (lost) { A->cuckoo_release(ck); SA_STEP(22); goto done; }

        A->cuckoo_counts(ck, &cc);
        if (cc.count != 200 || cc.full != 0)
            { A->cuckoo_release(ck); SA_STEP(22); goto done; }

        A->cuckoo_reset(ck);
        A->cuckoo_counts(ck, &cc);
        if (cc.count != 0 || A->cuckoo_check(ck, "k7", 2))
            { A->cuckoo_release(ck); SA_STEP(22); goto done; }

        A->cuckoo_release(ck);
    }

    /* 23: the lease. One process cannot demonstrate handoff to itself - the
     * holder is keyed on pid, so two handles here both "hold" it - so this
     * proves the single-process semantics and every table entry, and leaves
     * cross-process stealing to a fork test. */
    {
        sa_lease *ls = A->lease_open(r, "sele", 4, &err);
        int held = 0, stole = 0;
        uint64_t f1, f2;

        if (!ls || err != SA_E_OK) { SA_STEP(23); goto done; }

        held = A->lease_acquire(ls, 30000, &stole);
        if (!held || stole) { A->lease_release_handle(ls); SA_STEP(23); goto done; }
        if (!A->lease_mine(ls)) { A->lease_release_handle(ls); SA_STEP(23); goto done; }
        if (!A->lease_holder(ls)) { A->lease_release_handle(ls); SA_STEP(23); goto done; }
        f1 = A->lease_fence(ls);
        if (!f1) { A->lease_release_handle(ls); SA_STEP(23); goto done; }

        if (!A->lease_renew(ls, 30000))
            { A->lease_release_handle(ls); SA_STEP(23); goto done; }
        if (A->lease_fence(ls) != f1)          /* renew keeps the tenure */
            { A->lease_release_handle(ls); SA_STEP(23); goto done; }

        if (!A->lease_release(ls))
            { A->lease_release_handle(ls); SA_STEP(23); goto done; }
        if (A->lease_mine(ls) || A->lease_holder(ls))
            { A->lease_release_handle(ls); SA_STEP(23); goto done; }

        /* Re-acquiring a lease we just released is a new tenure: the fence must
         * move, or a superseded holder could not be told from a current one. */
        if (!A->lease_acquire(ls, 30000, &stole))
            { A->lease_release_handle(ls); SA_STEP(23); goto done; }
        f2 = A->lease_fence(ls);
        if (f2 <= f1) { A->lease_release_handle(ls); SA_STEP(23); goto done; }

        A->lease_release(ls);
        A->lease_release_handle(ls);
    }

    /* 24: the scoreboard. One process claims a row, writes it coherently
     * through the begin/set/end trio, and reads it back - the cross-worker
     * exclusion and reclaim are a fork test's job. */
    {
        const char *flds[2];
        sa_sb *sb;
        void *row;
        sa_sb_reading rd;
        int fi_a, fi_b;

        flds[0] = "a"; flds[1] = "b";
        sb = A->sb_open(r, "sele-sb", 7, flds, 2, 8, &err);
        if (!sb || err != SA_E_OK) { SA_STEP(24); goto done; }
        if (A->sb_slots(sb) != 8 || A->sb_nfields(sb) != 2)
            { A->sb_release(sb); SA_STEP(24); goto done; }

        fi_a = A->sb_field(sb, "a", 1);
        fi_b = A->sb_field(sb, "b", 1);
        if (fi_a < 0 || fi_b < 0 || A->sb_field(sb, "nope", 4) >= 0)
            { A->sb_release(sb); SA_STEP(24); goto done; }
        if (strcmp(A->sb_field_name(sb, 0), "a")
            || strcmp(A->sb_field_name(sb, 1), "b"))
            { A->sb_release(sb); SA_STEP(24); goto done; }

        if (A->sb_take(sb) < 0) { A->sb_release(sb); SA_STEP(24); goto done; }

        row = A->sb_begin(sb);
        if (!row) { A->sb_release(sb); SA_STEP(24); goto done; }
        A->sb_set_gauge(row, fi_a, 100);
        A->sb_set_gauge(row, fi_b, 7);
        A->sb_set_status(row, "busy", 4);
        A->sb_end(sb, row);

        row = A->sb_begin(sb);
        if (row) { A->sb_add_gauge(row, fi_b, 5); A->sb_end(sb, row); }

        /* Row 0 is ours; read it back coherently. */
        if (!A->sb_read(sb, 0, &rd)) { A->sb_release(sb); SA_STEP(24); goto done; }
        if (rd.gauges[fi_a] != 100 || rd.gauges[fi_b] != 12)
            { A->sb_release(sb); SA_STEP(24); goto done; }
        if (rd.statuslen != 4 || memcmp(rd.status, "busy", 4))
            { A->sb_release(sb); SA_STEP(24); goto done; }
        if (!rd.alive)          /* the writer - us - is running */
            { A->sb_release(sb); SA_STEP(24); goto done; }

        A->sb_release(sb);
    }

done:
    if (cur)  A->cursor_release(cur);
    if (ring) A->ring_release(ring);
    if (r)    A->release(r);
    return stepv;
}

#undef SA_STEP

#endif /* SA_ABI_IMPL_H */
