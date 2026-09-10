/* punk_filecache.h - a per-worker cache of small static files: their stat,
 * and their content.
 *
 * A static file hit is dominated by syscalls. Profiled under load, `open` was
 * 55% of the whole request, the PerlIO layer around it another 3.5%, sendfile
 * 7.7% and the close 1.2%. Holding the CONTENT removed all of it and left
 * `stat` as the last file syscall on the path, at 15%; holding the STAT
 * removes that one too, along with the sibling probes that go looking for a
 * .gz that is usually not there.
 *
 * TWO CACHES, TWO DIFFERENT BARGAINS.
 *
 *   The CONTENT cache is EXACTLY correct. It re-reads whenever the file's
 *   (dev, ino, mtime, size) changes, and it learns that from a stat the
 *   caller had to do anyway - so validating costs no syscall and it never
 *   serves bytes that disagree with the file it just looked at.
 *
 *   The STAT cache is EVENTUALLY correct, bounded by PFC_STAT_TTL (1 second
 *   by default): inside that second a change on disk is not looked for.
 *   PUNK_STATIC_STAT_TTL=0 goes back to statting every request - still with
 *   the content cache, so still without the open - which is the exactly
 *   correct configuration at most of the speed.
 *
 * WHY CONTENT AND NOT AN OPEN DESCRIPTOR. Caching the descriptor and handing
 * out `dup`s looks better: a dup is 33x cheaper than an open (0.187us against
 * 6.205us, measured) and it keeps the sendfile path. It is also wrong, in the
 * way that only shows up in production - a dup is a new descriptor onto the
 * SAME open file description, so it SHARES THE OFFSET. Two concurrent
 * requests for one file read through each other, and rewinding for one seeks
 * the other back to the start mid-body. No sequential test can see it.
 * Content has no offset, so the class goes away.
 *
 * WHY NOT fstat FOR VALIDATION. The question is "is the file at this PATH
 * still the file I read", and fstat describes the inode already held - so a
 * deploy that replaces the file leaves it reporting, truthfully and
 * uselessly, that nothing has changed. Statting the PATH catches a
 * replacement exactly, because a replacement gets a new inode.
 *
 * WHAT IT DOES NOT CACHE. Anything over PFC_MAX_FILE keeps the existing open
 * + sendfile path, which is already zero-copy and right for a large file:
 * caching a video would evict a site's whole stylesheet set to save one
 * request, and lose the kernel's own page cache doing it. A stat entry is
 * kept for any path, at any size.
 *
 * NEGATIVE ENTRIES ARE THE POINT. The precompressed sibling probe asks for
 * `style.css.br` and `style.css.gz` on every request from every browser,
 * because every browser sends Accept-Encoding, and on a site with no build
 * step neither has ever existed. Remembering they are absent is worth two
 * syscalls a request.
 *
 * It fails open everywhere: too big, unreadable, budget refused, all fall
 * back to the syscall this sits in front of.
 */

#ifndef PUNK_FILECACHE_H
#define PUNK_FILECACHE_H

/* Budgets. Deliberately small: this is a hot-asset cache, not a CDN, and the
 * memory is per worker. A site whose CSS/JS/icons do not fit in 8MB is serving
 * them from the wrong place. */
#define PFC_MAX_BYTES    (8 * 1024 * 1024)
#define PFC_MAX_FILE     (512 * 1024)
#define PFC_BUCKETS      64
#define PFC_KEY_MAX      1024      /* longer paths simply do not cache */

/* How long a stat is believed. One second, not the sixty nginx defaults to:
 * the whole cost this avoids is a syscall that takes a microsecond, so a
 * second of it is already all of the win, and the shorter the window the less
 * there is to explain to somebody who edited a file and reloaded. */
#define PFC_STAT_TTL     1.0

typedef struct pfc_entry {
    struct pfc_entry *hnext;       /* bucket chain                     */
    struct pfc_entry *prev, *next; /* recency list; head is newest     */
    uint64_t  hash;
    SV       *val;                 /* the bytes, or NULL: an entry may
                                      hold only a stat, or only the fact
                                      that there is nothing here        */
    Stat_t    st;                  /* the last stat taken of this path  */
    double    checked;             /* when st was taken                 */
    unsigned char exists;          /* 0 = a remembered absence          */
    uint32_t  klen;
    char     *key;
} pfc_entry;

typedef struct {
    pfc_entry *buckets[PFC_BUCKETS];
    pfc_entry *head, *tail;        /* newest .. oldest                 */
    uint32_t   entries;
    size_t     bytes;              /* held, incrementally maintained   */
    int        disabled;
    IV         owner_pid;
    uint64_t   hits, misses, evictions, stale, stat_hits, stat_misses;
} punk_filecache;

/* One per worker process: every mount in the process should share one memory
 * budget rather than each keeping its own. */
static punk_filecache PFC_CACHE;

/* Counting only the bytes would let a thousand tiny files - or a thousand
 * remembered absences, which carry no bytes at all - sit under an "8MB" cap
 * while costing far more in structs and allocator headers. */
#define PFC_ENTRY_OVERHEAD (sizeof(pfc_entry) + 64)

static size_t pfc_cost(uint32_t klen, UV vlen) {
    return PFC_ENTRY_OVERHEAD + (size_t)klen + (size_t)vlen;
}

/* FNV-1a. The keys are filesystem paths - short, sharing long prefixes. */
static uint64_t pfc_hash(const char *s, size_t n) {
    uint64_t h = 1469598103934665603ULL;
    size_t i;
    for (i = 0; i < n; i++) {
        h ^= (unsigned char)s[i];
        h *= 1099511628211ULL;
    }
    return h;
}

static double pfc_now(void) {
    struct timeval tv;
    gettimeofday(&tv, NULL);
    return (double)tv.tv_sec + (double)tv.tv_usec / 1e6;
}

static void pfc_unlink_lru(punk_filecache *c, pfc_entry *e) {
    if (e->prev) e->prev->next = e->next; else c->head = e->next;
    if (e->next) e->next->prev = e->prev; else c->tail = e->prev;
    e->prev = e->next = NULL;
}

static void pfc_push_front(punk_filecache *c, pfc_entry *e) {
    e->prev = NULL;
    e->next = c->head;
    if (c->head) c->head->prev = e;
    c->head = e;
    if (!c->tail) c->tail = e;
}

/* The bytes an entry is charged for: a stat-only or negative entry holds
 * none, and must not be charged as though it did. */
static UV pfc_vlen(pfc_entry *e) {
    return e->val ? (UV)SvCUR(e->val) : 0;
}

static void pfc_drop(pTHX_ punk_filecache *c, pfc_entry *e) {
    pfc_entry **pp = &c->buckets[e->hash % PFC_BUCKETS];
    while (*pp && *pp != e) pp = &(*pp)->hnext;
    if (*pp == e) *pp = e->hnext;
    pfc_unlink_lru(c, e);
    c->bytes -= pfc_cost(e->klen, pfc_vlen(e));
    if (e->val) SvREFCNT_dec(e->val);
    Safefree(e->key);
    Safefree(e);
    c->entries--;
}

/* Release just the content, keeping the entry and its stat. What happens when
 * a file changes: the bytes are wrong, the path is still worth remembering. */
static void pfc_drop_val(pTHX_ punk_filecache *c, pfc_entry *e) {
    if (!e->val) return;
    c->bytes -= (size_t)SvCUR(e->val);
    SvREFCNT_dec(e->val);
    e->val = NULL;
}

/* The escape hatches, read once.
 *
 * OPS knobs rather than app ones: the reason to want either off is how a host
 * publishes files, which is a property of the machine and not of the
 * application's source.
 *
 *   PUNK_NO_STATIC_FILE_CACHE=1   everything off, exactly the old path
 *   PUNK_STATIC_STAT_TTL=0        stat every request; keep the content cache,
 *                                 which is exactly correct on its own
 *   PUNK_STATIC_STAT_TTL=<secs>   believe a stat for that long
 */
static int pfc_enabled(void) {
    static int cached = -1;
    if (cached < 0) {
        const char *v = getenv("PUNK_NO_STATIC_FILE_CACHE");
        cached = (v && *v && *v != '0') ? 0 : 1;
    }
    return cached;
}

static double pfc_stat_ttl(void) {
    static double cached = -1.0;
    if (cached < 0.0) {
        const char *v = getenv("PUNK_STATIC_STAT_TTL");
        if (v && *v) {
            double d = atof(v);
            cached = d > 0.0 ? d : 0.0;
        }
        else cached = PFC_STAT_TTL;
    }
    return cached;
}

/* After a fork the entries are still valid - immutable bytes, and every hit
 * revalidates them - so a worker inherits a warm cache rather than starting
 * cold. Only the counters are per process. */
static void pfc_check_fork(pTHX_ punk_filecache *c) {
    IV me = (IV)PerlProc_getpid();
    PERL_UNUSED_CONTEXT;
    if (c->owner_pid == me) return;
    c->hits = c->misses = c->evictions = c->stale = 0;
    c->stat_hits = c->stat_misses = 0;
    c->owner_pid = me;
}

static pfc_entry *pfc_lookup(punk_filecache *c, const char *path, STRLEN plen,
                             uint64_t h) {
    pfc_entry *e;
    for (e = c->buckets[h % PFC_BUCKETS]; e; e = e->hnext) {
        if (e->hash != h || e->klen != (uint32_t)plen) continue;
        if (memcmp(e->key, path, plen) == 0) return e;
    }
    return NULL;
}

static pfc_entry *pfc_new(pTHX_ punk_filecache *c, const char *path,
                          STRLEN plen, uint64_t h) {
    pfc_entry *e;
    PERL_UNUSED_CONTEXT;
    while (c->bytes + pfc_cost((uint32_t)plen, 0) > PFC_MAX_BYTES && c->tail)
    {
        pfc_drop(aTHX_ c, c->tail);
        c->evictions++;
    }
    Newxz(e, 1, pfc_entry);
    Newx(e->key, plen + 1, char);
    memcpy(e->key, path, plen);
    e->key[plen] = '\0';
    e->klen  = (uint32_t)plen;
    e->hash  = h;
    e->hnext = c->buckets[h % PFC_BUCKETS];
    c->buckets[h % PFC_BUCKETS] = e;
    pfc_push_front(c, e);
    c->entries++;
    c->bytes += pfc_cost((uint32_t)plen, 0);
    return e;
}

/* Is the identity in `st` the same file as `b`? */
static int pfc_same(const Stat_t *a, const Stat_t *b) {
    return (UV)a->st_dev == (UV)b->st_dev
        && (UV)a->st_ino == (UV)b->st_ino
        && (UV)a->st_mtime == (UV)b->st_mtime
        && (UV)a->st_size == (UV)b->st_size;
}

/* stat(2), possibly from memory. 1 = *out filled and the path exists; 0 = it
 * does not exist or could not be statted, which the caller must treat exactly
 * as a failed stat.
 *
 * Within the TTL this answers without a syscall, including for a path that is
 * KNOWN ABSENT - which is what makes the precompressed-sibling probe free on
 * the sites that have no siblings.
 *
 * When it does stat and the file has changed, it releases the cached content
 * here, so everything downstream can trust that content and stat agree. */
static int pfc_stat(pTHX_ const char *path, STRLEN plen, Stat_t *out) {
    punk_filecache *c = &PFC_CACHE;
    uint64_t h;
    pfc_entry *e;
    Stat_t fresh;
    int ok;

    if (!pfc_enabled() || c->disabled || plen == 0 || plen >= PFC_KEY_MAX)
        return PerlLIO_stat(path, out) == 0 ? 1 : 0;

    pfc_check_fork(aTHX_ c);
    h = pfc_hash(path, plen);
    e = pfc_lookup(c, path, plen, h);

    if (e && (pfc_now() - e->checked) < pfc_stat_ttl()) {
        pfc_unlink_lru(c, e);
        pfc_push_front(c, e);
        c->stat_hits++;
        if (!e->exists) return 0;
        *out = e->st;
        return 1;
    }

    c->stat_misses++;
    ok = PerlLIO_stat(path, &fresh) == 0;

    if (!e) e = pfc_new(aTHX_ c, path, plen, h);
    else if (e->val && (!ok || !pfc_same(&fresh, &e->st))) {
        /* the bytes we hold are no longer this file's */
        c->stale++;
        pfc_drop_val(aTHX_ c, e);
    }
    e->checked = pfc_now();
    e->exists  = ok ? 1 : 0;
    if (ok) { e->st = fresh; *out = fresh; }
    return ok;
}

/* The file's bytes as an SV the caller owns (+1), or NULL to say "read it
 * yourself". NULL is never "the file is missing".
 *
 * dev/ino/mtime/size are the stat the caller is serving this request from -
 * fresh, or from pfc_stat within the TTL - and are the check that the bytes
 * held belong to that same file.
 *
 * The returned SV is newSVsv of the held one, which on any perl with
 * copy-on-write strings (5.20+) is O(1) and shares the buffer until something
 * writes to it. On an older perl it is a real copy, correct and still cheaper
 * than the open it replaced. */
static SV *pfc_get(pTHX_ const char *path, STRLEN plen,
                   UV dev, UV ino, UV mtime, UV size) {
    punk_filecache *c = &PFC_CACHE;
    uint64_t h;
    pfc_entry *e;
    PerlIO *fp;
    SV *val;

    if (c->disabled || !pfc_enabled()) return NULL;
    if (plen == 0 || plen >= PFC_KEY_MAX) return NULL;
    if (size > PFC_MAX_FILE) return NULL;      /* streams, as before */
    pfc_check_fork(aTHX_ c);

    h = pfc_hash(path, plen);
    e = pfc_lookup(c, path, plen, h);
    if (e && e->val) {
        /* Is what we hold this file? A new inode is a replaced file; a changed
         * mtime or size is a rewritten one. */
        if ((UV)e->st.st_dev == dev && (UV)e->st.st_ino == ino
            && (UV)e->st.st_mtime == mtime && (UV)e->st.st_size == size) {
            pfc_unlink_lru(c, e);
            pfc_push_front(c, e);
            c->hits++;
            return newSVsv(e->val);
        }
        c->stale++;
        pfc_drop_val(aTHX_ c, e);
    }

    c->misses++;

    /* Not held: read it once, keep it, and serve from what we just read. This
     * is the only request that pays. */
    fp = PerlIO_open(path, "rb");
    if (!fp) return NULL;                       /* caller's own missing-file */

    val = newSV(size ? (STRLEN)size : 1);
    SvPOK_on(val);
    {
        STRLEN got = 0;
        while (got < (STRLEN)size) {
            SSize_t n = PerlIO_read(fp, SvPVX(val) + got, (STRLEN)size - got);
            if (n <= 0) break;
            got += (STRLEN)n;
        }
        PerlIO_close(fp);
        if (got != (STRLEN)size) {
            /* The file changed under us between the stat and the read. Do not
             * cache a half file, and do not serve one either - let the caller
             * take the ordinary path and see it for itself. */
            SvREFCNT_dec(val);
            return NULL;
        }
        SvCUR_set(val, got);
        SvPVX(val)[got] = '\0';
    }

    if (pfc_cost((uint32_t)plen, size) > PFC_MAX_BYTES)
        return val;                 /* bigger than the budget: never hold it */

    if (!e) {
        e = pfc_new(aTHX_ c, path, plen, h);
        e->checked = pfc_now();
        e->exists  = 1;
    }
    while (c->bytes + (size_t)size > PFC_MAX_BYTES && c->tail && c->tail != e) {
        pfc_drop(aTHX_ c, c->tail);
        c->evictions++;
    }
    /* the stat this content belongs to, so pfc_get can check it next time */
    e->st.st_dev   = (dev_t)dev;
    e->st.st_ino   = (ino_t)ino;
    e->st.st_mtime = (time_t)mtime;
    e->st.st_size  = (Off_t)size;
    e->val = SvREFCNT_inc(val);
    c->bytes += (size_t)size;
    return val;
}

#endif /* PUNK_FILECACHE_H */
