#ifndef SA_WAKE_H
#define SA_WAKE_H

/* sa_wake.h - telling a reader there is something to read. Perl-free.
 *
 * ---- a pipe, and why not something newer ------------------------------------
 *
 * Each process that wants to be woken owns a pipe. A publisher writes one byte
 * into it; the reader has the read end in its event loop and drains it. eventfd
 * is Linux-only and saves exactly one descriptor, which is not a trade worth
 * making for a dist that has to work on the BSDs and macOS as well.
 *
 * The pipes are created BEFORE the fork, so the descriptor NUMBERS are the same
 * in every process and can therefore live in shared memory as plain ints. That
 * is also the limit of this mechanism: a process that attached to a named
 * region inherited nothing, so it has no pipe and no way to be given one.
 * `sa_wake_fd` answers -1 there and the caller polls instead. Saying so is
 * better than shipping a named FIFO nobody asked for.
 *
 * ---- one poke, however many publishers ------------------------------------
 *
 * A busy ring would otherwise cost a write(2) per record. Each waker carries a
 * `pending` flag, and ONLY the publisher that flips it from 0 to 1 writes a
 * byte; everybody else has nothing to do, because a wakeup already in flight
 * will find their record too. A reader clears the flag when it has drained.
 *
 * ---- the ordering that actually carries weight -----------------------------
 *
 * THE POKE FOLLOWS THE COMMIT. A publisher writes its record, commits it, and
 * only then wakes anybody. Poke first and a reader wakes, finds a slot that is
 * still being written, and goes back to sleep - and nothing will wake it again
 * until the NEXT publish, which on a quiet ring may be a long time. So a wakeup
 * from this ring always means there is something to read. t/12-wake.t holds a
 * publisher inside its commit with the stall hook to prove it, because the
 * window is nanoseconds wide otherwise and a test that races it proves nothing.
 *
 * A reader should still drain the pipe, then clear `pending`, then read the
 * ring, and sa_wake_drained does the first two in that order. It is the
 * conservative order rather than a load-bearing one HERE: because the reader
 * reads the ring last, a byte swallowed early still belongs to a record it is
 * about to find. The order matters in designs where the ring is read before the
 * pipe is drained, and keeping it costs nothing - but the honest statement is
 * that this dist's correctness rests on the poke following the commit, and a
 * comment claiming otherwise would be describing somebody else's code.
 *
 * Needs sa_arena.h.
 */

#include "sa/sa_arena.h"

#ifndef _WIN32
#  include <unistd.h>
#  include <fcntl.h>
#  include <errno.h>
#  include <sys/types.h>
#  include <sys/stat.h>
#endif

#define SA_WAKERS_MAX 64

/* The waker table lives in a carved sub-region under a reserved name, so every
 * process finds it the same way it finds anything else and nothing has to be
 * passed out of band. */
#define SA_WAKERS_NAME "\0wakers"
#define SA_WAKERS_NLEN 7

typedef struct {
    volatile uint32_t pending;  /* 1 = a wakeup is already in flight       */
    volatile uint32_t live;     /* 0 = this slot belongs to nobody         */
    volatile uint64_t owner;    /* the pid that took it                    */
    int               rfd;
    int               wfd;
} sa_waker;

/* ---- A DESCRIPTOR NUMBER IS PROCESS-LOCAL STATE ----------------------------
 *
 * `rfd` and `wfd` above are ints in shared memory, and this dist's first rule
 * says nothing in a region may be a pointer. A descriptor number is the same
 * kind of thing as an address: it means something only inside the process that
 * opened it. Fork children inherit the table AND the descriptors, so the
 * numbers agree there - which is exactly what makes the bug invisible in every
 * test that only forks.
 *
 * A process that ATTACHED BY NAME inherited nothing. Its fd 7 is its own fd 7:
 * a log, a socket, the harness's TAP stream. Before this header carried an
 * identity, an attached publisher's `sa_wake_poke` wrote a byte into whatever
 * that was. Demonstrated: a \001 in an unrelated file, no error anywhere.
 *
 * So the table records what the pipes ARE - the device and inode of slot 0's
 * read end, which are global identifiers rather than local ones - and every
 * process checks ONCE, with one fstat, whether the descriptors in the table are
 * the ones it actually holds. A process that fails the check does not poke and
 * does not claim a slot; it polls, which is exactly what the POD already
 * promises an attached process gets.
 *
 * The check is per process rather than per poke because it is a syscall, and
 * the answer cannot change: a process either inherited these pipes or it did
 * not. `sa_wake_leave` is the only thing that resets it.
 */
typedef struct {
    volatile uint32_t ready;    /* published LAST: the identity is readable */
    uint32_t          n;        /* how many slots were given pipes          */
    uint64_t          dev;      /* st_dev of slot 0's read end              */
    uint64_t          ino;      /* st_ino of it                             */
    uint64_t          maker;    /* the pid that called pipe(), for diagnosis */
} sa_waker_hdr;

/* The slots follow the header, aligned as everything else in a region is. */
#define SA_WAKERS_HDR_BYTES  sa_align_up((uint64_t)sizeof(sa_waker_hdr))
#define SA_WAKERS_BYTES \
    (SA_WAKERS_HDR_BYTES + (uint64_t)SA_WAKERS_MAX * sizeof(sa_waker))
#define SA_WAKER_SLOTS(hp) \
    ((sa_waker *)((char *)(hp) + (size_t)SA_WAKERS_HDR_BYTES))

/* Create `n` pipes. MUST run before the fork: the descriptors are inherited,
 * which is what makes the numbers meaningful in every process.
 *
 * Idempotent, and a failure is silent - a region with no wakers still works,
 * its readers simply have to poll. */
static int sa_wake_init(sa_region *r, uint32_t n) {
#if defined(_WIN32) || !SA_HAVE_ATOMICS
    (void)r; (void)n;
    return 0;
#else
    sa_waker_hdr *hp;
    sa_waker *w;
    uint64_t off;
    uint32_t i;
    int err = SA_E_OK;

    if (!r || !r->map.base) return 0;
    if (n < 1) n = 1;
    if (n > SA_WAKERS_MAX) n = SA_WAKERS_MAX;

    {
        sa_reg *e = sa_carve(r, SA_WAKERS_NAME, SA_WAKERS_NLEN,
                             SA_WAKERS_BYTES, SA_T_RAW, &err);
        if (!e) return 0;
        off = e->off;
    }
    hp = (sa_waker_hdr *)sa_ptr(r, off);
    if (!hp) return 0;
    w = SA_WAKER_SLOTS(hp);

    for (i = 0; i < n; i++) {
        int fds[2];
        if (sa_at_load32_acq(&w[i].live) || w[i].rfd) continue;  /* already */
        if (pipe(fds) != 0) return 0;
        /* Both ends non-blocking, so a consumer that has stopped draining
         * cannot block a publisher inside a write. */
        fcntl(fds[0], F_SETFL, fcntl(fds[0], F_GETFL, 0) | O_NONBLOCK);
        fcntl(fds[1], F_SETFL, fcntl(fds[1], F_GETFL, 0) | O_NONBLOCK);
        /* CLOSE ON EXEC. These are inherited across a fork, which is the whole
         * mechanism, and they have no business surviving an exec: a program
         * that replaces its image is not a peer of this region and would hold
         * both ends of every pipe open for as long as it ran, so a reader that
         * exits never gives its writers EPIPE. */
        fcntl(fds[0], F_SETFD, fcntl(fds[0], F_GETFD, 0) | FD_CLOEXEC);
        fcntl(fds[1], F_SETFD, fcntl(fds[1], F_GETFD, 0) | FD_CLOEXEC);
        w[i].rfd = fds[0];
        w[i].wfd = fds[1];
        sa_at_store32_rel(&w[i].pending, 0);
    }

    /* The identity, published last: until `ready` lands nobody trusts the
     * descriptors, which is the same commit discipline the region header and
     * the ring header use one and two levels up. */
    if (!sa_at_load32_acq(&hp->ready)) {
        struct stat st;
        if (w[0].rfd && fstat(w[0].rfd, &st) == 0) {
            hp->dev   = (uint64_t)st.st_dev;
            hp->ino   = (uint64_t)st.st_ino;
            hp->maker = sa_getpid();
            hp->n     = n;
            sa_at_store32_rel(&hp->ready, 1);
        }
    }

    r->wakers_off = off;
    r->wakers_max = SA_WAKERS_MAX;
    r->wake_checked = 0;          /* re-verify: we are the maker now */
    return 1;
#endif
}

/* Are the descriptors in this table the ones THIS process holds?
 *
 * One fstat, once per process. A fork child inherited the pipes and passes; a
 * process that attached by name did not and fails, so it neither pokes nor
 * claims a slot. Failing is not an error: it is the polling mode the POD
 * already documents for an attached process. */
static int sa_wake_usable(sa_region *r) {
#if defined(_WIN32) || !SA_HAVE_ATOMICS
    (void)r;
    return 0;
#else
    sa_waker_hdr *hp;
    sa_waker *w;
    struct stat st;

    if (!r || !r->wakers_off) return 0;
    /* KEYED ON THE PID, because the handle survives a fork and the answer may
     * not: a child that closed the inherited pipes and reopened those numbers
     * as something else would otherwise keep the parent's verdict and write
     * into whatever it opened. sa_getpid is a load once it is cached. */
    if (r->wake_checked && r->wake_pid == sa_getpid()) return r->wake_ok;

    r->wake_checked = 1;
    r->wake_pid     = sa_getpid();
    r->wake_ok      = 0;

    hp = (sa_waker_hdr *)sa_ptr(r, r->wakers_off);
    if (!hp || !sa_at_load32_acq(&hp->ready)) return 0;
    w = SA_WAKER_SLOTS(hp);
    if (!w[0].rfd) return 0;
    if (fstat(w[0].rfd, &st) != 0) return 0;
    if ((uint64_t)st.st_dev != hp->dev || (uint64_t)st.st_ino != hp->ino)
        return 0;

    r->wake_ok = 1;
    return 1;
#endif
}

/* Claim a waker for this process, after the fork.
 *
 * The stale bytes are drained AS IT IS TAKEN, and that is not tidiness: a slot
 * left with a byte in its pipe by a previous owner makes the new owner's first
 * select return immediately, which looks exactly like a wakeup and hides the
 * absence of a real one. A bug that hides itself by passing the test. */
/* Find the table a parent created, for a process that did not create it. */
static int sa_wake_attach(sa_region *r) {
#if defined(_WIN32) || !SA_HAVE_ATOMICS
    (void)r;
    return 0;
#else
    sa_reg *e;
    if (!r || !r->map.base) return 0;
    if (r->wakers_off) return 1;
    e = sa_find(r, SA_WAKERS_NAME, SA_WAKERS_NLEN);
    if (!e) return 0;
    r->wakers_off = e->off;
    r->wakers_max = SA_WAKERS_MAX;
    return 1;
#endif
}

static int sa_wake_take(sa_region *r, int idx) {
#if defined(_WIN32) || !SA_HAVE_ATOMICS
    (void)r; (void)idx;
    return -1;
#else
    sa_waker_hdr *hp;
    sa_waker *w;
    uint32_t i;

    if (!sa_wake_attach(r)) return -1;
    if (!r || !r->wakers_off) return -1;
    /* Not ours to read from: see sa_wake_usable. A process that did not
     * inherit these pipes would be reading whatever its own fd of that number
     * happens to be. */
    if (!sa_wake_usable(r)) return -1;
    hp = (sa_waker_hdr *)sa_ptr(r, r->wakers_off);
    if (!hp) return -1;
    w = SA_WAKER_SLOTS(hp);

    if (idx >= 0) {
        i = (uint32_t)idx;
        if (i >= r->wakers_max) return -1;
        if (!sa_at_cas32(&w[i].live, 0, 1)) return -1;
    }
    else {
        for (i = 0; i < r->wakers_max; i++)
            if (sa_at_cas32(&w[i].live, 0, 1)) break;
        if (i >= r->wakers_max) return -1;
    }

    {
        char junk[256];
        while (read(w[i].rfd, junk, sizeof junk) > 0) { /* drain */ }
    }
    sa_at_store32_rel(&w[i].pending, 0);
    sa_at_store64_rel(&w[i].owner, sa_getpid());
    r->waker_idx = (int)i;
    return (int)i;
#endif
}

/* This process's read end, or -1 when it has none. */
static int sa_wake_fd(sa_region *r) {
#if defined(_WIN32) || !SA_HAVE_ATOMICS
    (void)r;
    return -1;
#else
    sa_waker_hdr *hp;
    if (!r || !r->wakers_off || r->waker_idx < 0) return -1;
    if (!sa_wake_usable(r)) return -1;
    hp = (sa_waker_hdr *)sa_ptr(r, r->wakers_off);
    return hp ? SA_WAKER_SLOTS(hp)[r->waker_idx].rfd : -1;
#endif
}

/* Wake everybody but this process. Called from publish. */
static void sa_wake_poke(sa_region *r) {
#if defined(_WIN32) || !SA_HAVE_ATOMICS
    (void)r;
#else
    sa_waker_hdr *hp;
    sa_waker *w;
    uint32_t i;
    char b = 1;

    if (!sa_wake_attach(r)) return;
    /* THE CHECK THAT STOPS A STRAY WRITE. Without it, a publisher that
     * attached by name writes this byte into whatever its own descriptor of
     * that number happens to be. One fstat, once, per process. */
    if (!sa_wake_usable(r)) return;
    hp = (sa_waker_hdr *)sa_ptr(r, r->wakers_off);
    if (!hp) return;
    w = SA_WAKER_SLOTS(hp);

    for (i = 0; i < r->wakers_max; i++) {
        if ((int)i == r->waker_idx) continue;          /* not ourselves   */
        if (!sa_at_load32_acq(&w[i].live)) continue;   /* nobody there    */
        /* ONLY the caller that flips the flag writes. Everybody else has
         * nothing to do: a wakeup already in flight will find their record
         * too, and a second byte would buy nothing but a syscall. */
        if (!sa_at_cas32(&w[i].pending, 0, 1)) continue;
        {
            ssize_t rc = write(w[i].wfd, &b, 1);
            (void)rc;   /* EAGAIN on a full pipe is fine: it is already awake */
        }
    }
#endif
}

/* Drain the pipe and then clear the flag, in that order. See the header
 * comment: the other order deafens a reader. */
static void sa_wake_drained(sa_region *r) {
#if defined(_WIN32) || !SA_HAVE_ATOMICS
    (void)r;
#else
    sa_waker_hdr *hp;
    sa_waker *w;
    char junk[256];

    if (!r || !r->wakers_off || r->waker_idx < 0) return;
    if (!sa_wake_usable(r)) return;
    hp = (sa_waker_hdr *)sa_ptr(r, r->wakers_off);
    if (!hp) return;
    w = SA_WAKER_SLOTS(hp);

    while (read(w[r->waker_idx].rfd, junk, sizeof junk) > 0) { /* drain */ }
    sa_at_store32_rel(&w[r->waker_idx].pending, 0);
#endif
}

static void sa_wake_leave(sa_region *r) {
#if !defined(_WIN32) && SA_HAVE_ATOMICS
    if (r && r->wakers_off && r->waker_idx >= 0) {
        sa_waker_hdr *hp = (sa_waker_hdr *)sa_ptr(r, r->wakers_off);
        if (hp) sa_at_store32_rel(&SA_WAKER_SLOTS(hp)[r->waker_idx].live, 0);
        r->waker_idx    = -1;
        r->wake_checked = 0;
    }
#else
    (void)r;
#endif
}

#endif /* SA_WAKE_H */
