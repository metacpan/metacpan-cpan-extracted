/* punk_cachefile.h - the file cache store.
 *
 * WHY THIS IS THE DEFAULT.
 *
 * An in-memory store lives in one process, so under a prefork server every
 * worker keeps its own: `workers => 8` with a 512M cap is four gigabytes of
 * RSS, and every worker caches the same things separately. The filesystem is
 * already shared, so this is ONE copy for the whole pool - and it survives a
 * restart, which memory does not.
 *
 * It costs about six microseconds a hit against five nanoseconds for memory.
 * That ratio sounds decisive and is not: six microseconds is nothing beside a
 * request about to render a template or query a database.
 *
 * THE READ SHAPE, WHICH WAS MEASURED RATHER THAN GUESSED.
 *
 * One `read` for the header and key, then `pread` for the value straight into
 * the caller's buffer. Two syscalls, zero copies.
 *
 * The first design read header, key and value separately - three syscalls,
 * and at 1KB the syscalls ARE the cost, so it lost to a plain stat+read. The
 * obvious correction, one big read plus a memmove to strip the header, is
 * worse still at 1MB (41.4us against 28.6): stripping a header off a megabyte
 * means moving a megabyte, and the copy costs more than the syscall it saves.
 * plan_punk_cache/phase-0-contract.md has the table.
 *
 * THE KEY NEVER BECOMES A PATH.
 *
 * A cache key is application data and often user data: `../../etc/passwd` is a
 * valid key, so is one with a NUL, so is a four-kilobyte one. The key is
 * hashed and the hex sharded two levels deep, and the key itself is stored in
 * the header and compared on read - so a hash collision is a MISS rather than
 * a silently wrong value, which makes the hash width a performance question
 * instead of a correctness one.
 *
 * ATOMICITY.
 *
 * Write a temp file in the DESTINATION directory and rename. Same directory
 * because a cross-filesystem rename is not atomic and /tmp is very often
 * another filesystem. Rename is also why no checksum is needed: a reader
 * never sees a partial entry, so there is no torn state to detect. A crash
 * mid-write leaves a temp file, which the sweep removes.
 */

#ifndef PUNK_CACHEFILE_H
#define PUNK_CACHEFILE_H

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <fcntl.h>
#include <unistd.h>
#include <dirent.h>
#include <errno.h>
#include <sys/stat.h>
#include <sys/time.h>

#define PCF_MAGIC     0x504b4331u      /* "PKC1" */
#define PCF_PATHMAX   1024
#define PCF_HEADMAX   4352             /* header + a 4096-byte key */

/* On disk: magic, expiry, key length, value length, then key, then value.
 *
 * The expiry lives HERE and not in mtime: an expiry stamped in the file
 * survives a cache-wide default changing, and does not lose to a filesystem
 * with coarse or lazily updated timestamps. */
typedef struct {
    uint32_t magic;
    double   expiry;               /* epoch seconds; 0 = never */
    uint32_t klen;
    uint32_t vlen;
} pcf_hdr;

typedef struct {
    char    dir[PCF_PATHMAX];
    size_t  dirlen;
    size_t  max_bytes;
    double  lock_wait;             /* single-flight budget, seconds */

    /* Amortised eviction. A sweep is a full scan - 273ms for 100k entries -
     * so it must never run on a write. Instead each process counts what IT
     * has written and sweeps once that passes a slice of the budget, which
     * bounds how often the scan happens without putting it in the hot path. */
    size_t  written_since_sweep;

    uint64_t hits, misses, evictions, refused, expired;
    IV       owner_pid;
} punk_cachefile;

static double pcf_now(void) {
    struct timeval tv;
    gettimeofday(&tv, NULL);
    return (double)tv.tv_sec + (double)tv.tv_usec / 1e6;
}

/* ---- paths --------------------------------------------------------------- */

static void pcf_hex16(uint64_t h, char *out) {
    static const char *H = "0123456789abcdef";
    int i;
    for (i = 15; i >= 0; i--) { out[i] = H[h & 0xF]; h >>= 4; }
    out[16] = '\0';
}

/* <dir>/<h0h1>/<h2h3>/<hex>. Two shard levels, because one directory holding
 * 100k entries is slow to scan on more filesystems than not. */
static int pcf_path(punk_cachefile *c, const char *key, uint32_t klen,
                    char *out, size_t outn, int mkdirs) {
    char hex[17];
    pcf_hex16(pc_hash(key, klen), hex);
    if (mkdirs) {
        char d[PCF_PATHMAX];
        int n = snprintf(d, sizeof d, "%s/%c%c", c->dir, hex[0], hex[1]);
        if (n < 0 || (size_t)n >= sizeof d) return -1;
        if (mkdir(d, 0700) != 0 && errno != EEXIST) return -1;
        n = snprintf(d, sizeof d, "%s/%c%c/%c%c", c->dir, hex[0], hex[1],
                     hex[2], hex[3]);
        if (n < 0 || (size_t)n >= sizeof d) return -1;
        if (mkdir(d, 0700) != 0 && errno != EEXIST) return -1;
    }
    {
        int n = snprintf(out, outn, "%s/%c%c/%c%c/%s", c->dir,
                         hex[0], hex[1], hex[2], hex[3], hex);
        if (n < 0 || (size_t)n >= (int)outn) return -1;
    }
    return 0;
}

/* ---- lifecycle ----------------------------------------------------------- */

static punk_cachefile *punk_cachefile_new(pTHX_ const char *dir, size_t dirlen,
                                          size_t max_bytes, double lock_wait) {
    punk_cachefile *c;
    if (dirlen >= PCF_PATHMAX - 64) return NULL;
    Newxz(c, 1, punk_cachefile);
    memcpy(c->dir, dir, dirlen);
    c->dir[dirlen] = '\0';
    c->dirlen    = dirlen;
    c->max_bytes = max_bytes;
    c->lock_wait = lock_wait;
    c->owner_pid = (IV)PerlProc_getpid();
    return c;
}

static void punk_cachefile_free(pTHX_ punk_cachefile *c) {
    if (c) Safefree(c);
}

/* The entries are on disk and shared, so a fork changes nothing about them.
 * The COUNTERS are this process's: a child reporting its parent's hit rate is
 * reporting a number about a different process. */
static void punk_cachefile_check_fork(pTHX_ punk_cachefile *c) {
    IV me = (IV)PerlProc_getpid();
    if (c->owner_pid == me) return;
    c->hits = c->misses = c->evictions = c->refused = c->expired = 0;
    c->written_since_sweep = 0;
    c->owner_pid = me;
}

/* ---- reading ------------------------------------------------------------- */

/* The value as a new SV (+1), or NULL for absent, expired, or a collision.
 *
 * An SV rather than a malloc'd buffer the caller copies out of, because the
 * caller ALWAYS wanted an SV and the copy was pure loss: a 64K value was
 * allocated twice, copied twice and freed once on the way to a scalar that
 * could have been filled directly. On the large path the value is now pread
 * straight into the SV's own buffer, so there is no copy at all.
 *
 * `expiry`, when not NULL, is filled with the entry's own absolute expiry
 * (0 = never). A memory tier in front of this store has to hold the entry to
 * the expiry the STORE recorded rather than one counted from the moment it
 * was faulted in, or the tier serves a value the store considers gone. */
static SV *punk_cachefile_get_sv(pTHX_ punk_cachefile *c, const char *key,
                                 uint32_t klen, double *expiry) {
    char path[PCF_PATHMAX];
    char head[PCF_HEADMAX];
    pcf_hdr h;
    int fd;
    ssize_t n;
    SV *sv;

    punk_cachefile_check_fork(aTHX_ c);
    if (pcf_path(c, key, klen, path, sizeof path, 0) != 0) {
        c->misses++;
        return NULL;
    }
    fd = open(path, O_RDONLY);
    if (fd < 0) { c->misses++; return NULL; }

    n = read(fd, head, sizeof head);
    if (n < (ssize_t)sizeof h) { close(fd); c->misses++; return NULL; }
    memcpy(&h, head, sizeof h);

    if (h.magic != PCF_MAGIC || h.klen != klen
        || (size_t)n < sizeof h + h.klen) {
        close(fd); c->misses++; return NULL;
    }
    /* The stored key decides it. A hash collision is a MISS, never a wrong
     * value handed back as if it were the right one. */
    if (memcmp(head + sizeof h, key, klen)) {
        close(fd); c->misses++; return NULL;
    }
    if (h.expiry && h.expiry <= pcf_now()) {
        close(fd);
        unlink(path);                    /* lazy expiry, noticed on the read */
        c->expired++;
        c->misses++;
        return NULL;
    }

    if (expiry) *expiry = h.expiry;

    if ((size_t)n >= sizeof h + h.klen + h.vlen) {
        /* a small entry arrived whole in the first read */
        sv = newSVpvn(head + sizeof h + h.klen, h.vlen);
    }
    else {
        /* pread straight into the scalar: no copy, and no memmove to strip a
         * header off a megabyte */
        ssize_t got;
        sv = newSV(h.vlen + 1);
        SvPOK_only(sv);
        got = pread(fd, SvPVX(sv), h.vlen, (off_t)(sizeof h + h.klen));
        if (got != (ssize_t)h.vlen) {
            close(fd); SvREFCNT_dec(sv); c->misses++; return NULL;
        }
        SvCUR_set(sv, (STRLEN)h.vlen);
        *SvEND(sv) = '\0';
    }
    close(fd);
    c->hits++;
    return sv;
}

/* ---- eviction ------------------------------------------------------------ */

typedef struct { char path[PCF_PATHMAX]; double atime; off_t size; } pcf_ent;

/* Walk the cache, dropping expired entries and orphaned temp files, and
 * evicting the coldest until the budget is met.
 *
 * A full scan, deliberately kept OFF the write path: 273ms for 100k entries
 * is not something a request may pay, and it grows with the cache. */
static void pcf_sweep(pTHX_ punk_cachefile *c) {
    pcf_ent *ents = NULL;
    size_t n = 0, cap = 0;
    uint64_t total = 0;
    char l1[PCF_PATHMAX];
    DIR *d1;
    struct dirent *e1;
    double now = pcf_now();

    d1 = opendir(c->dir);
    if (!d1) return;
    while ((e1 = readdir(d1))) {
        DIR *d2;
        struct dirent *e2;
        if (e1->d_name[0] == '.') continue;
        if (snprintf(l1, sizeof l1, "%s/%s", c->dir, e1->d_name) < 0) continue;
        d2 = opendir(l1);
        if (!d2) continue;
        while ((e2 = readdir(d2))) {
            char l2[PCF_PATHMAX];
            DIR *d3;
            struct dirent *e3;
            if (e2->d_name[0] == '.') continue;
            if (snprintf(l2, sizeof l2, "%s/%s", l1, e2->d_name) < 0) continue;
            d3 = opendir(l2);
            if (!d3) continue;
            while ((e3 = readdir(d3))) {
                char p[PCF_PATHMAX];
                struct stat st;
                if (e3->d_name[0] == '.') continue;
                if (snprintf(p, sizeof p, "%s/%s", l2, e3->d_name) < 0)
                    continue;
                if (stat(p, &st) != 0 || !S_ISREG(st.st_mode)) continue;

                /* an orphan from a writer that died between create and
                 * rename, or a lock whose holder never came back */
                if (strstr(e3->d_name, ".tmp") || strstr(e3->d_name, ".lock")) {
                    if (now - (double)st.st_mtime > 60.0) unlink(p);
                    continue;
                }
                /* expired entries go now rather than waiting to be read */
                {
                    int fd = open(p, O_RDONLY);
                    pcf_hdr h;
                    if (fd >= 0) {
                        ssize_t got = read(fd, &h, sizeof h);
                        close(fd);
                        if (got == (ssize_t)sizeof h && h.magic == PCF_MAGIC
                            && h.expiry && h.expiry <= now) {
                            unlink(p);
                            c->expired++;
                            continue;
                        }
                    }
                }
                if (n == cap) {
                    cap = cap ? cap * 2 : 256;
                    Renew(ents, cap, pcf_ent);
                }
                strncpy(ents[n].path, p, PCF_PATHMAX - 1);
                ents[n].path[PCF_PATHMAX - 1] = '\0';
                ents[n].atime = (double)st.st_atime;
                ents[n].size  = st.st_size;
                total += (uint64_t)st.st_size;
                n++;
            }
            closedir(d3);
        }
        closedir(d2);
    }
    closedir(d1);

    /* Evict coldest-first until the budget is met. A selection pass rather
     * than a sort: eviction is rare and n can be large, and repeatedly
     * picking the minimum costs less than ordering everything when only a
     * few need to go. */
    while (total > c->max_bytes && n > 0) {
        size_t i, oldest = 0;
        for (i = 1; i < n; i++)
            if (ents[i].atime < ents[oldest].atime) oldest = i;
        unlink(ents[oldest].path);
        total -= (uint64_t)ents[oldest].size;
        c->evictions++;
        ents[oldest] = ents[n - 1];
        n--;
    }
    if (ents) Safefree(ents);
    c->written_since_sweep = 0;
}

/* ---- writing ------------------------------------------------------------- */

/* Returns 1 stored, 0 refused. */
static int punk_cachefile_set(pTHX_ punk_cachefile *c, const char *key,
                              uint32_t klen, const char *val, uint32_t vlen,
                              double expiry) {
    char path[PCF_PATHMAX], tmp[PCF_PATHMAX];
    pcf_hdr h;
    int fd, ok = 0;

    punk_cachefile_check_fork(aTHX_ c);

    /* A value that cannot fit the budget even in an empty cache is refused:
     * making room would evict everything else and still not fit. */
    if ((size_t)sizeof h + klen + vlen > c->max_bytes) { c->refused++; return 0; }

    if (pcf_path(c, key, klen, path, sizeof path, 1) != 0) return 0;
    if (snprintf(tmp, sizeof tmp, "%s.tmp%ld", path,
                 (long)PerlProc_getpid()) < 0) return 0;

    fd = open(tmp, O_WRONLY | O_CREAT | O_TRUNC, 0600);
    if (fd < 0) return 0;

    h.magic = PCF_MAGIC; h.expiry = expiry; h.klen = klen; h.vlen = vlen;
    if (write(fd, &h, sizeof h) == (ssize_t)sizeof h
        && (!klen || write(fd, key, klen) == (ssize_t)klen)
        && (!vlen || write(fd, val, vlen) == (ssize_t)vlen))
        ok = 1;
    close(fd);

    if (!ok || rename(tmp, path) != 0) { unlink(tmp); return 0; }

    /* Amortised: a sweep is a full scan, so it runs once this process has
     * written a slice of the budget rather than on every set. */
    c->written_since_sweep += sizeof h + klen + vlen;
    if (c->written_since_sweep > c->max_bytes / 8)
        pcf_sweep(aTHX_ c);
    return 1;
}

static int punk_cachefile_delete(pTHX_ punk_cachefile *c, const char *key,
                                 uint32_t klen) {
    char path[PCF_PATHMAX];
    punk_cachefile_check_fork(aTHX_ c);
    if (pcf_path(c, key, klen, path, sizeof path, 0) != 0) return 0;
    return unlink(path) == 0 ? 1 : 0;
}

static void pcf_rmtree(const char *dir, int depth) {
    DIR *d = opendir(dir);
    struct dirent *e;
    if (!d) return;
    while ((e = readdir(d))) {
        char p[PCF_PATHMAX];
        struct stat st;
        if (e->d_name[0] == '.') continue;
        if (snprintf(p, sizeof p, "%s/%s", dir, e->d_name) < 0) continue;
        if (stat(p, &st) != 0) continue;
        if (S_ISDIR(st.st_mode)) {
            if (depth > 0) { pcf_rmtree(p, depth - 1); rmdir(p); }
        }
        else unlink(p);
    }
    closedir(d);
}

/* Empty the cache. Bounded to the two shard levels this store creates, so a
 * misconfigured `dir` cannot turn a clear into a recursive delete of
 * somebody's home directory. */
static void punk_cachefile_clear(pTHX_ punk_cachefile *c) {
    punk_cachefile_check_fork(aTHX_ c);
    pcf_rmtree(c->dir, 2);
    c->written_since_sweep = 0;
}

/* Current bytes held, for stats. A full scan, so it is asked for rather than
 * maintained - `stats` is an operator action, not a hot path. */
static void punk_cachefile_usage(punk_cachefile *c, uint64_t *bytes,
                                 uint64_t *entries) {
    char l1[PCF_PATHMAX];
    DIR *d1 = opendir(c->dir);
    struct dirent *e1;
    *bytes = *entries = 0;
    if (!d1) return;
    while ((e1 = readdir(d1))) {
        DIR *d2;
        struct dirent *e2;
        if (e1->d_name[0] == '.') continue;
        if (snprintf(l1, sizeof l1, "%s/%s", c->dir, e1->d_name) < 0) continue;
        d2 = opendir(l1);
        if (!d2) continue;
        while ((e2 = readdir(d2))) {
            char l2[PCF_PATHMAX];
            DIR *d3;
            struct dirent *e3;
            if (e2->d_name[0] == '.') continue;
            if (snprintf(l2, sizeof l2, "%s/%s", l1, e2->d_name) < 0) continue;
            d3 = opendir(l2);
            if (!d3) continue;
            while ((e3 = readdir(d3))) {
                char p[PCF_PATHMAX];
                struct stat st;
                if (e3->d_name[0] == '.') continue;
                if (strstr(e3->d_name, ".tmp") || strstr(e3->d_name, ".lock"))
                    continue;
                if (snprintf(p, sizeof p, "%s/%s", l2, e3->d_name) < 0)
                    continue;
                if (stat(p, &st) != 0 || !S_ISREG(st.st_mode)) continue;
                *bytes += (uint64_t)st.st_size;
                (*entries)++;
            }
            closedir(d3);
        }
        closedir(d2);
    }
    closedir(d1);
}

/* ---- single-flight ------------------------------------------------------- *
 *
 * When a hot key expires under load every worker misses at once and every one
 * of them recomputes - the moment a cache is most valuable is the moment it
 * stops helping.
 *
 * O_EXCL makes the winner. Three rules stop it becoming a new way to hang:
 *
 *   - a loser that waits out its budget COMPUTES ANYWAY. Correctness never
 *     depends on the lock: duplicated work is a cost, a stalled request is an
 *     outage, and a request hanging because another worker died holding the
 *     lock is the worst of the three;
 *   - a STALE lock is stolen, not respected, or one crash poisons a key until
 *     somebody notices;
 *   - the lock covers one compute and nothing unbounded.
 *
 * So it is best effort: it collapses the herd in the common case and degrades
 * to today's behaviour in every unusual one.
 */

/* 1 if this caller won and should compute; 0 if it should look again. */
static int punk_cachefile_lock(pTHX_ punk_cachefile *c, const char *key,
                               uint32_t klen) {
    char path[PCF_PATHMAX], lock[PCF_PATHMAX];
    struct stat st;
    int fd;

    if (pcf_path(c, key, klen, path, sizeof path, 1) != 0) return 1;
    if (snprintf(lock, sizeof lock, "%s.lock", path) < 0) return 1;

    fd = open(lock, O_WRONLY | O_CREAT | O_EXCL, 0600);
    if (fd >= 0) { close(fd); return 1; }        /* won */

    /* Somebody holds it. If it is older than the wait budget its holder is
     * not coming back - steal it rather than obey it. */
    if (stat(lock, &st) == 0
        && pcf_now() - (double)st.st_mtime > c->lock_wait) {
        unlink(lock);
        fd = open(lock, O_WRONLY | O_CREAT | O_EXCL, 0600);
        if (fd >= 0) { close(fd); return 1; }
    }
    return 0;
}

static void punk_cachefile_unlock(pTHX_ punk_cachefile *c, const char *key,
                                  uint32_t klen) {
    char path[PCF_PATHMAX], lock[PCF_PATHMAX];
    if (pcf_path(c, key, klen, path, sizeof path, 0) != 0) return;
    if (snprintf(lock, sizeof lock, "%s.lock", path) < 0) return;
    unlink(lock);
}

#endif /* PUNK_CACHEFILE_H */
