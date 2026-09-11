#ifndef SA_PEER_H
#define SA_PEER_H

/* sa_peer.h - who is using this region, and how a reader proves one of them
 * has died. Perl-free.
 *
 * ---- the problem a timeout cannot solve -------------------------------------
 *
 * A publisher reserves a sequence and dies before committing it. Every reader
 * that reaches that sequence is now stuck: it cannot deliver a record that was
 * never written, and it must not skip one that is merely late, because a live
 * publisher on a loaded machine can lose the CPU for longer than any bound
 * worth setting. Wait too little and live records are thrown away; wait too
 * much and one dead process stalls every reader.
 *
 * A timeout picks one of those and is wrong the rest of the time. So this asks
 * a different question - not "has it been long enough" but "is that process
 * still there" - and it takes TWO answers, both of which must agree.
 *
 * ---- proof one: the process is gone ----------------------------------------
 *
 * kill(pid, 0) asks without signalling. ESRCH is the ONLY answer that means
 * gone. EPERM means the process exists and belongs to somebody else, and
 * reading "not mine" as "dead" is how a live publisher's record gets discarded.
 * Where there is no kill at all - Windows - the answer is ALIVE, conservatively,
 * which pushes the whole decision onto proof two. That is the safe direction:
 * it costs latency on one record, never data.
 *
 * ---- proof two: it has made no progress ------------------------------------
 *
 * A pid check cannot see a process that is alive but wedged - deadlocked,
 * stopped, or stuck in the kernel - and such a process passes kill(0) for ever
 * while never finishing its record. So a peer also carries a heartbeat, bumped
 * on publishes AND on drains so an idle-but-live peer still ticks, and a reader
 * requires it to have stood still for the grace period.
 *
 * Both must hold. A recycled pid therefore makes this SKIP a hole it could have
 * filled, which costs one stalled record, where the reverse would cost a live
 * one. The asymmetry is deliberate.
 *
 * ---- the epoch, which answers most cases with no syscall at all ------------
 *
 * A peer slot is reused. A claim naming slot 7 means nothing unless it also
 * says WHICH occupant of slot 7, so every claim carries the epoch, and an epoch
 * that no longer matches is a claim from a process that has already gone -
 * known dead immediately, with no kill and no waiting.
 *
 * Needs sa_arena.h.
 */

#include "sa/sa_arena.h"

#ifdef _WIN32
#  include <windows.h>
#else
#  include <signal.h>
#  include <errno.h>
#  include <unistd.h>
#  include <time.h>
#endif

/* A claim packs the peer slot and its epoch into one word, so a publisher
 * announces its identity with a single store and a reader reads it with a
 * single load. Zero is "nobody", which is what an untouched slot holds. */
#define SA_CLAIM(peer, epoch) \
    (((uint64_t)((peer) + 1) << 32) | (uint64_t)(epoch))
#define SA_CLAIM_PEER(c)   ((uint32_t)(((c) >> 32) - 1))
#define SA_CLAIM_EPOCH(c)  ((uint32_t)((c) & 0xFFFFFFFFu))

/* ---- getpid IS A SYSCALL, AND THIS IS ON THE PUBLISH PATH -------------------
 *
 * `sa_peer_join` runs on every published record, and its fast path has to know
 * which process it is before it can decide it has nothing to do. glibc cached
 * getpid until 2.25 and does not any more, so on Linux that fast path was a
 * syscall per record - in a dist whose first line is "without a syscall".
 *
 * So the pid is cached, and the cache is invalidated by the one event that can
 * make it wrong: a fork. pthread_atfork is what says so, and Makefile.PL probes
 * for it rather than assuming - where it is missing the cache is simply not
 * used and every call is the real thing, which is slower and always correct.
 */
#if defined(SA_HAVE_ATFORK) && !defined(_WIN32)
#  include <pthread.h>
static volatile uint64_t sa_pid_cache = 0;
static void sa_pid_forgot(void) { sa_pid_cache = 0; }
static int  sa_pid_armed = 0;

static uint64_t sa_getpid(void) {
    uint64_t p = sa_pid_cache;
    if (p) return p;
    if (!sa_pid_armed) {
        sa_pid_armed = 1;
        /* The CHILD handler, and only that one: the parent's pid is unchanged
         * by a fork, so clearing it there would throw the cache away on every
         * fork for nothing. */
        (void)pthread_atfork(NULL, NULL, sa_pid_forgot);
    }
    p = (uint64_t)getpid();
    sa_pid_cache = p;
    return p;
}
#else
static uint64_t sa_getpid(void) {
#ifdef _WIN32
    return (uint64_t)GetCurrentProcessId();
#else
    return (uint64_t)getpid();
#endif
}
#endif

/* Is that process still running?
 *
 * ESRCH is the only answer that means gone. On Windows a pid that cannot be
 * opened is answered ALIVE rather than dead, because OpenProcess fails for
 * reasons that have nothing to do with the process existing, and the staleness
 * proof is the one that has to carry it there. */
static int sa_pid_alive(uint64_t pid) {
#ifdef _WIN32
    HANDLE h;
    DWORD code = 0;
    if (!pid) return 0;
    h = OpenProcess(PROCESS_QUERY_LIMITED_INFORMATION, FALSE, (DWORD)pid);
    if (!h) return 1;                       /* conservatively alive */
    if (GetExitCodeProcess(h, &code)) {
        CloseHandle(h);
        return code == STILL_ACTIVE ? 1 : 0;
    }
    CloseHandle(h);
    return 1;
#else
    if (!pid) return 0;
    if (kill((pid_t)pid, 0) == 0) return 1;
    return (errno == ESRCH) ? 0 : 1;        /* EPERM means ALIVE */
#endif
}

/* Take a peer slot for this process. Idempotent per pid: a fork child calls it
 * again and gets its OWN slot, because it is a different process and a claim
 * naming its parent would be attributed to the wrong one.
 *
 * Returns 1 when this process has a slot, 0 when the table is full - in which
 * case publishing still works and only the crash attribution is lost, which is
 * the right thing to degrade. */
static int sa_peer_join(sa_region *r) {
#if !SA_HAVE_ATOMICS
    (void)r;
    return 0;
#else
    sa_header *h;
    sa_peer *peers;
    uint64_t me = sa_getpid();
    uint32_t i;

    if (!r || !r->map.base) return 0;
    if (r->peer_pid == me && r->peer_idx >= 0) return 1;

    h     = r->hdr;
    peers = SA_PEERS(r->map.base, h);

    for (i = 0; i < h->peers_max; i++) {
        uint32_t st = sa_at_load32_acq(&peers[i].state);
        if (st == SA_P_LIVE) {
            /* Already ours from a previous join in this same process? */
            if (sa_at_load64_acq(&peers[i].pid) == me) {
                r->peer_idx   = (int)i;
                r->peer_epoch = sa_at_load32_acq(&peers[i].epoch);
                r->peer_pid   = me;
                return 1;
            }
            continue;
        }
        /* FREE or REAPED. Winning the CAS is what makes the slot ours. */
        if (!sa_at_cas32(&peers[i].state, st, SA_P_LIVE)) continue;

        sa_at_store64_rel(&peers[i].want, 0);
        sa_at_store64_rel(&peers[i].heartbeat, 1);
        sa_at_store64_rel(&peers[i].pid, me);
        /* The epoch is bumped LAST and is what a claim is validated against, so
         * a claim written by the previous occupant can never be mistaken for
         * one of ours. */
        sa_at_store32_rel(&peers[i].epoch,
                          sa_at_load32_acq(&peers[i].epoch) + 1);

        r->peer_idx   = (int)i;
        r->peer_epoch = sa_at_load32_acq(&peers[i].epoch);
        r->peer_pid   = me;
        if (i + 1 > sa_at_load32_acq(&h->peers_used))
            sa_at_store32_rel(&h->peers_used, i + 1);
        return 1;
    }
    return 0;
#endif
}

static void sa_peer_beat(sa_region *r) {
#if SA_HAVE_ATOMICS
    if (r && r->peer_idx >= 0 && r->map.base) {
        sa_peer *p = &SA_PEERS(r->map.base, r->hdr)[r->peer_idx];
        sa_at_fetch_add64(&p->heartbeat, 1);
    }
#else
    (void)r;
#endif
}

static void sa_peer_leave(sa_region *r) {
#if SA_HAVE_ATOMICS
    if (r && r->peer_idx >= 0 && r->map.base
        && r->peer_pid == sa_getpid()) {
        sa_peer *p = &SA_PEERS(r->map.base, r->hdr)[r->peer_idx];
        sa_at_store32_rel(&p->state, SA_P_FREE);
        r->peer_idx = -1;
    }
#else
    (void)r;
#endif
}

/* THE DECISION. Is the peer named by this claim dead, and has it stopped?
 *
 * `hb0` is the heartbeat read when the wait began; the caller has already
 * waited the grace period. Returns 1 when both proofs hold and the caller may
 * fill the hole.
 */
static int sa_peer_is_dead(sa_region *r, uint64_t claim, uint64_t hb0) {
#if !SA_HAVE_ATOMICS
    (void)r; (void)claim; (void)hb0;
    return 0;
#else
    sa_peer *peers;
    uint32_t idx, epoch;

    if (!r || !r->map.base) return 0;
    if (!claim) return 0;                     /* nobody claimed it */

    idx   = SA_CLAIM_PEER(claim);
    epoch = SA_CLAIM_EPOCH(claim);
    if (idx >= r->hdr->peers_max) return 0;

    peers = SA_PEERS(r->map.base, r->hdr);

    /* The cheap proof first, and it needs no syscall: a slot whose epoch has
     * moved on belongs to a different process than the one that wrote this
     * claim, so the writer is already gone. */
    if (sa_at_load32_acq(&peers[idx].epoch) != epoch) return 1;
    if (sa_at_load32_acq(&peers[idx].state) != SA_P_LIVE) return 1;

    /* Both of the expensive ones, and BOTH must hold. */
    if (sa_at_load64_acq(&peers[idx].heartbeat) != hb0) return 0;  /* moved */
    if (sa_pid_alive(sa_at_load64_acq(&peers[idx].pid))) return 0; /* there */
    return 1;
#endif
}

/* The heartbeat of the peer a claim names, for the caller to compare later. */
static uint64_t sa_peer_hb(sa_region *r, uint64_t claim) {
#if !SA_HAVE_ATOMICS
    (void)r; (void)claim;
    return 0;
#else
    uint32_t idx;
    if (!r || !r->map.base || !claim) return 0;
    idx = SA_CLAIM_PEER(claim);
    if (idx >= r->hdr->peers_max) return 0;
    return sa_at_load64_acq(&SA_PEERS(r->map.base, r->hdr)[idx].heartbeat);
#endif
}

/* Mark a proven-dead peer reaped. Exactly one caller wins, which is what keeps
 * the accounting exact when two readers reach the same hole together. */
static int sa_peer_reap(sa_region *r, uint64_t claim) {
#if !SA_HAVE_ATOMICS
    (void)r; (void)claim;
    return 0;
#else
    uint32_t idx;
    if (!r || !r->map.base || !claim) return 0;
    idx = SA_CLAIM_PEER(claim);
    if (idx >= r->hdr->peers_max) return 0;
    return sa_at_cas32(&SA_PEERS(r->map.base, r->hdr)[idx].state,
                       SA_P_LIVE, SA_P_REAPED);
#endif
}

/* Does any DEAD peer have a reservation it never committed?
 *
 * The residual window: a publisher that died between taking a sequence and
 * announcing which peer it was leaves a hole with no usable claim. This cannot
 * say WHICH sequence such a peer was writing, only that one of them was, which
 * is enough to stop waiting for a record nobody will ever finish. */
static int sa_peer_any_dead_pending(sa_region *r) {
#if !SA_HAVE_ATOMICS
    (void)r;
    return 0;
#else
    sa_peer *peers;
    uint32_t i, used;
    if (!r || !r->map.base) return 0;
    peers = SA_PEERS(r->map.base, r->hdr);
    used  = sa_at_load32_acq(&r->hdr->peers_used);
    if (used > r->hdr->peers_max) used = r->hdr->peers_max;
    for (i = 0; i < used; i++) {
        if (sa_at_load32_acq(&peers[i].state) != SA_P_LIVE) continue;
        if (!sa_at_load64_acq(&peers[i].want)) continue;
        if (!sa_pid_alive(sa_at_load64_acq(&peers[i].pid))) return 1;
    }
    return 0;
#endif
}

#endif /* SA_PEER_H */
