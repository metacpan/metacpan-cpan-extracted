#ifndef SA_MAP_H
#define SA_MAP_H

/* sa_map.h - where the memory comes from, and how a second process reaches it.
 * Perl-free.
 *
 * ---- two ways in, one structure ---------------------------------------------
 *
 *   ANONYMOUS   mmap(MAP_SHARED|MAP_ANONYMOUS) before a fork, inherited. The
 *               simple case. No name, no cleanup, gone when the last process
 *               exits.
 *   NAMED       shm_open + ftruncate + mmap on POSIX, CreateFileMapping backed
 *               by the pagefile on Windows. A process that is not a fork
 *               descendant can attach, which is the whole reason the offsets
 *               rule in sa_format.h exists.
 *
 * ---- the create race, which is not hypothetical ----------------------------
 *
 * A freshly ftruncate'd segment reads as zeros. Two processes racing to create
 * the same name both end up with a valid mapping, and the loser of O_EXCL maps
 * a segment whose header the winner has not finished writing.
 *
 * So the winner writes the whole header and stores `magic` LAST with a release
 * store, and the loser spins bounded on `magic` and then validates. It is the
 * same commit discipline a record uses one layer up: everything, then one word,
 * released. A loser that times out fails open rather than guessing.
 *
 * ---- lifetime, and why destroy is explicit ---------------------------------
 *
 * shm_unlink removes the NAME, not the mapping - existing mappings stay valid
 * until their last user unmaps. A creator that crashes therefore leaves the
 * segment behind, which is a feature (a restarting server reattaches to a live
 * region and its readers never noticed) and a leak (nothing removes a name
 * nobody will open again). There is no way to have one without the other, so
 * destroy is a deliberate call and the POD says who is expected to make it.
 */

#include "sa/sa_format.h"

#include <stdlib.h>
#include <string.h>

#ifdef _WIN32
#  include <windows.h>
#else
#  include <sys/types.h>
#  include <sys/mman.h>
#  include <sys/stat.h>
#  include <fcntl.h>
#  include <unistd.h>
#  include <errno.h>
#endif


/* ---- WAITING FOR A HEADER SOMEBODY ELSE IS STILL PUBLISHING ----------------
 *
 * Every structure in this dist commits the same way: write the body, then store
 * one magic word with a release. A process that finds the magic unset has to
 * wait for it, and this is the one place that wait is implemented.
 *
 * BOUNDED BY TIME, not by turns. A spin count is the wrong quantity in both
 * directions: two hundred thousand iterations is under a millisecond on a fast
 * machine, so a creator that was merely descheduled gets abandoned, and it is
 * also a core burned solid while waiting. This sleeps between looks and gives
 * up when the time is gone. The iteration backstop is only there so a clock
 * stepped backwards cannot turn a bounded wait into an unbounded one. */
static int sa_wait_magic32(volatile uint32_t *p, uint32_t want) {
    uint64_t deadline = sa_now_us() + SA_CREATE_WAIT_US;
    long backstop = 0;
    while (sa_at_load32_acq(p) != want) {
        if (++backstop > 1000000L) return 0;
        if (sa_now_us() >= deadline) return 0;
        sa_stall(SA_CREATE_POLL_US);
    }
    return 1;
}

#define SA_SRC_ANON  0
#define SA_SRC_NAMED 1

/* The process-local half of a region. NONE of this is in the mapping: `base`
 * in particular is this process's address for it, which is exactly the thing
 * that must never be written into shared memory. */
typedef struct sa_map {
    void     *base;
    uint64_t  len;
    int       src;
#ifdef _WIN32
    HANDLE    mh;
#else
    char     *name;      /* strdup'd, for destroy; NULL when anonymous */
#endif
} sa_map;

/* ---- the platform half ----------------------------------------------------
 *
 * Three primitives, one shape: reserve `len` bytes of shared memory, tell the
 * caller whether it was freshly created (so it knows whether to write the
 * header or wait for one), and hand back the base.
 */

#ifdef _WIN32

static int sa_os_map(sa_map *m, const char *name, uint64_t len, int *created,
                     int may_create) {
    HANDLE mh;
    void *addr;
    DWORD hi = (DWORD)(len >> 32), lo = (DWORD)(len & 0xFFFFFFFFu);

    m->base = NULL; m->len = 0; m->mh = INVALID_HANDLE_VALUE;
    m->src = name ? SA_SRC_NAMED : SA_SRC_ANON;

    if (!may_create) {
        /* Attach only. OpenFileMapping fails rather than creating, which is
         * the whole difference between the two entries. */
        if (!name) return SA_E_NOENT;
        mh = OpenFileMappingA(FILE_MAP_ALL_ACCESS, FALSE, name);
        if (!mh) return SA_E_NOENT;
        if (created) *created = 0;
        /* THE SECTION'S SIZE WINS, exactly as it does on POSIX below.
         *
         * An attacher does not know how big the region is; the creator decided
         * that, and asking the attacher to guess is the out-of-band agreement
         * the registry exists to abolish. Mapping the caller's guess maps a
         * PREFIX, the header's own `total` then runs past the end of the view,
         * and sa_check_header correctly refuses the whole thing - so `attach`
         * failed on every region bigger than the guess, which on Windows is
         * every region, since named is the only mode there is.
         *
         * Zero means "to the end of the section", and VirtualQuery is how the
         * size comes back: there is no fstat here and the section carries no
         * length of its own that a caller can ask for. */
        len = 0;
    }
    else {
        /* INVALID_HANDLE_VALUE means pagefile-backed: no file on disk, which
         * is what a shared region wants. A NULL name gives an unnamed mapping,
         * which on Windows is inherited only by explicit handle duplication -
         * there is no fork, so the anonymous mode exists here only for a
         * single process. */
        mh = CreateFileMappingA(INVALID_HANDLE_VALUE, NULL, PAGE_READWRITE,
                                hi, lo, name);
        if (!mh) return SA_E_MAP;
        if (created) *created = (GetLastError() != ERROR_ALREADY_EXISTS);
    }

    addr = MapViewOfFile(mh, FILE_MAP_ALL_ACCESS, 0, 0, (SIZE_T)len);
    if (!addr) { CloseHandle(mh); return SA_E_MAP; }

    if (!len) {
        MEMORY_BASIC_INFORMATION mbi;
        if (!VirtualQuery(addr, &mbi, sizeof mbi)) {
            UnmapViewOfFile(addr);
            CloseHandle(mh);
            return SA_E_MAP;
        }
        len = (uint64_t)mbi.RegionSize;
    }

    m->base = addr; m->len = len; m->mh = mh;
    return SA_E_OK;
}

static void sa_os_unmap(sa_map *m) {
    if (m->base) UnmapViewOfFile(m->base);
    if (m->mh != INVALID_HANDLE_VALUE) CloseHandle(m->mh);
    m->base = NULL; m->len = 0; m->mh = INVALID_HANDLE_VALUE;
}

/* A Windows section disappears with its last handle, so there is no name to
 * unlink and nothing to leak. */
static int sa_os_destroy(const char *name) { (void)name; return SA_E_OK; }

#else

static int sa_os_map(sa_map *m, const char *name, uint64_t len, int *created,
                     int may_create) {
    void *addr;

    m->base = NULL; m->len = 0; m->name = NULL;
    m->src = name ? SA_SRC_NAMED : SA_SRC_ANON;

    if (!name) {
        if (!may_create) return SA_E_NOENT;   /* nothing to attach to */
        addr = mmap(NULL, (size_t)len, PROT_READ | PROT_WRITE,
                    MAP_SHARED | MAP_ANON, -1, 0);
        if (addr == MAP_FAILED) return SA_E_MAP;
        if (created) *created = 1;
        m->base = addr; m->len = len;
        return SA_E_OK;
    }

    {
        int fd, mine = 0;
        /* ATTACH MUST NOT CREATE. Passing O_CREAT here unconditionally is how
         * `attach` on a name nobody has ever used hands back an empty region
         * instead of saying no - and the caller then reads zeros and believes
         * them. The two entries are different questions and get different
         * flags. */
        if (may_create) {
            mine = 1;
            fd = shm_open(name, O_RDWR | O_CREAT | O_EXCL, 0600);
            if (fd < 0 && errno == EEXIST) {
                mine = 0;
                fd = shm_open(name, O_RDWR, 0600);
            }
        }
        else {
            fd = shm_open(name, O_RDWR, 0600);
        }
        if (fd < 0) return (errno == ENOENT) ? SA_E_NOENT : SA_E_MAP;

        /* Only the creator sizes it. A second process calling ftruncate on a
         * live segment would truncate it under everybody else. */
        if (mine && ftruncate(fd, (off_t)len) != 0) {
            close(fd);
            shm_unlink(name);
            return SA_E_MAP;
        }
        if (!mine) {
            /* The winner may not have got to ftruncate yet, so a zero-length
             * segment here is a race to wait out, not a refusal. */
            struct stat st;
            uint64_t deadline = sa_now_us() + SA_CREATE_WAIT_US;
            long backstop = 0;
            for (;;) {
                if (fstat(fd, &st) != 0) { close(fd); return SA_E_MAP; }
                if ((uint64_t)st.st_size >= len) break;
                /* A SLEEP, not a spin. This loop contains a SYSCALL, so a spin
                 * bound of two hundred thousand was two hundred thousand
                 * fstats - a core burned to discover the creator had not got to
                 * ftruncate yet. */
                if (++backstop > 1000000L) { close(fd); return SA_E_MAP; }
                if (sa_now_us() >= deadline) { close(fd); return SA_E_MAP; }
                sa_stall(SA_CREATE_POLL_US);
            }
            /* THE SEGMENT'S SIZE WINS, not the caller's.
             *
             * An attacher does not know how big the region is - that is the
             * creator's decision, and asking the attacher to guess it right is
             * exactly the out-of-band agreement the name registry exists to
             * abolish. So `len` is a MINIMUM here, and what gets mapped is
             * whatever is actually there. Mapping the caller's guess instead
             * maps a prefix, and the header's own `total` then runs past the
             * end of the mapping, which the validator correctly refuses. */
            len = (uint64_t)st.st_size;
        }

        addr = mmap(NULL, (size_t)len, PROT_READ | PROT_WRITE, MAP_SHARED,
                    fd, 0);
        /* The mapping keeps the segment alive, so the descriptor goes now -
         * the same reason a mapped file's fd is closed immediately. */
        close(fd);
        if (addr == MAP_FAILED) return SA_E_MAP;

        /* The name is kept only so `destroy` has something to unlink. Losing
         * it to a failed malloc would make destroy silently do nothing, which
         * is a leaked segment nobody can account for later - so the mapping is
         * refused instead. A caller that cannot allocate 32 bytes has worse
         * problems than a region it did not get. */
        m->name = (char *)malloc(strlen(name) + 1);
        if (!m->name) {
            munmap(addr, (size_t)len);
            return SA_E_NOMEM;
        }
        strcpy(m->name, name);
        if (created) *created = mine;
        m->base = addr; m->len = len;
        return SA_E_OK;
    }
}

static void sa_os_unmap(sa_map *m) {
    if (m->base) munmap(m->base, (size_t)m->len);
    if (m->name) { free(m->name); m->name = NULL; }
    m->base = NULL; m->len = 0;
}

static int sa_os_destroy(const char *name) {
    if (shm_unlink(name) != 0) return (errno == ENOENT) ? SA_E_NOENT : SA_E_MAP;
    return SA_E_OK;
}

#endif /* _WIN32 */

/* ---- the portable half ----------------------------------------------------- */

/* Create or attach, and hand back a mapping whose header is valid.
 *
 * `name` NULL means anonymous. `len` is the whole region including the header;
 * it is ignored when attaching an existing named segment, whose own header
 * says how big it is.
 */
static int sa_map_open(sa_map *m, const char *name, uint64_t len,
                       uint32_t reg_max, int *created, int may_create)
{
    int rc, mine = 0;
    sa_header *h;

#if !SA_HAVE_ATOMICS
    (void)m; (void)name; (void)len; (void)reg_max; (void)created;
    (void)may_create;
    return SA_E_NOATOMICS;
#else
    rc = sa_os_map(m, name, len, &mine, may_create);
    if (rc != SA_E_OK) return rc;
    if (created) *created = mine;

    h = (sa_header *)m->base;

    if (mine) {
        /* Write everything, then publish `magic` last. Until that store lands,
         * a racing attacher sees zeros and waits. */
        memset(h, 0, (size_t)sa_header_bytes(reg_max));
        h->layout   = SA_LAYOUT_VERSION;
        h->hdr_size = (uint16_t)sizeof(sa_header);
        h->endian   = SA_ENDIAN_PROBE;
        h->word     = (uint32_t)sizeof(void *);
        h->total    = len;
        h->reg_off   = sa_align_up((uint64_t)sizeof(sa_header));
        h->reg_max   = reg_max;
        h->reg_used  = 0;
        h->peers_off = sa_peers_offset(reg_max);
        h->peers_max = SA_PEERS_MAX;
        h->peers_used = 0;
        h->stall_us  = 0;
        /* 250ms before a reader starts asking whether a hole's publisher is
         * dead. Long enough that an ordinary preemption is just a wait, short
         * enough that a real crash does not stall a tail visibly. */
        h->reap_grace_us = 250000;
        sa_at_store64_rel(&h->brk, sa_header_bytes(reg_max));
        sa_at_store32_rel(&h->magic, SA_MAGIC);
    }
    else if (!sa_wait_magic32(&h->magic, SA_MAGIC)) {
        sa_os_unmap(m);
        return SA_E_MAGIC;
    }

    rc = sa_check_header(m->base, m->len);
    if (rc != SA_E_OK) { sa_os_unmap(m); return rc; }
    return SA_E_OK;
#endif
}

static void sa_map_release(sa_map *m) {
    if (m && m->base) sa_os_unmap(m);
}

#endif /* SA_MAP_H */
