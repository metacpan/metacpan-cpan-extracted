#ifndef SA_FORMAT_H
#define SA_FORMAT_H

/* sa_format.h - what a region looks like in memory. Perl-free.
 *
 * ---- NOTHING IN HERE IS EVER A POINTER --------------------------------------
 *
 * Every reference from one part of a region to another is a BYTE OFFSET from
 * the base of the mapping. That is the single rule this file exists to enforce,
 * and it is what separates a region that can be attached from one that can only
 * be inherited.
 *
 * The sibling design in Hyperman stores `hm_bus_group *groups` and `char *data`
 * inside the shared mapping. That is correct for a fork child, which inherits
 * the mapping at the same virtual address, and wrong for everything else - a
 * process that maps the same segment at a different address reads those fields
 * as addresses in ITS OWN space and follows them into whatever is there. It
 * cannot be tested for either, because the one thing that reveals it is a
 * second mapping at a second address, which that design cannot produce.
 *
 * Here it is testable, and t/03-relocatable.t is the test: map one named region
 * twice IN ONE PROCESS, write through the first mapping, read through the
 * second. No fork, no race, and any stray pointer fails it every time.
 *
 * ---- who may share a region -------------------------------------------------
 *
 * Two processes sharing a named region must agree about its shape, and they are
 * not necessarily the same build: a 32-bit perl and a 64-bit perl can open the
 * same name. So the header carries its own dimensions - layout version, header
 * size, pointer width and an endian probe - and a process whose compiled layout
 * disagrees FAILS OPEN rather than dereferencing a shape it does not share.
 *
 * The endian probe cannot fire between two processes on one machine. It is
 * there for the case where a region is ever persisted or forwarded, and it
 * costs one comparison at attach.
 */

#include "sa/sa_atomic.h"
#include "sa/sa_time.h"

#include <string.h>

/* "SARN" read as a native word. Not a byte-order-independent spelling, because
 * the endian probe below is what answers that question. */
#define SA_MAGIC          0x4E524153u   /* 'S','A','R','N' little-endian */
/* Bumped to 2 for 0.03: the map's slot layout changed (a per-key `expires`
 * field), so a 0.02 and a 0.03 build sharing one NAMED arena would read each
 * other's map slots at the wrong stride. The layout number is checked at attach
 * exactly so that disagreement FAILS OPEN rather than silently misreading. */
#define SA_LAYOUT_VERSION 2
#define SA_ENDIAN_PROBE   0x01020304u

#define SA_ALIGN          16            /* every carved region starts here  */
#define SA_NAMELEN        32            /* including the NUL                */
#define SA_REGIONS_MAX    64            /* registry entries, sized at create */
#define SA_PEERS_MAX      256           /* processes that may register      */

/* what a registry entry is for, so a consumer can refuse a region that is not
 * the kind it expected */
#define SA_T_RAW    0u
#define SA_T_RING   1u
#define SA_T_MAP    2u
#define SA_T_BLOOM  3u
#define SA_T_HIST   4u
#define SA_T_CACHE  5u
#define SA_T_RATE   6u
#define SA_T_CMS    7u
#define SA_T_FROZEN 8u
#define SA_T_CUCKOO 9u
#define SA_T_LEASE  10u
#define SA_T_SCOREBOARD 11u

/* registry entry states. `state` is published LAST with a release store, so a
 * reader either sees a complete entry or no entry at all. */
#define SA_R_EMPTY  0u
#define SA_R_LIVE   1u

typedef struct {
    volatile uint32_t state;      /* SA_R_* - published last                */
    uint32_t          type;       /* SA_T_*                                 */
    uint64_t          off;        /* from the base of the mapping           */
    uint64_t          len;
    char              name[SA_NAMELEN];
} sa_reg;

/* ---- the peer table --------------------------------------------------------
 *
 * Who is using this region, so that a hole left in a ring can be ATTRIBUTED
 * rather than merely waited on. A timeout cannot tell a publisher that died
 * from one that lost the CPU, and on a loaded machine a live publisher can be
 * away for longer than any bound worth setting.
 *
 * `epoch` is what makes a peer slot an identity rather than an index. A slot
 * reused by a later process gets a new epoch, so a claim naming (slot, epoch)
 * is recognisably stale with no syscall at all - the same job the pid in a
 * filename does for an orphaned log elsewhere in this workspace.
 *
 * `heartbeat` is the in-memory equivalent of that log's mtime. It is bumped on
 * publishes AND on drains, so a peer that is merely idle still ticks, and it
 * catches what a pid check cannot: a process that is alive but wedged passes
 * kill(0) for ever and is never coming back.
 *
 * `want` is the residual-window mitigation. A publisher raises it before it
 * reserves a sequence and lowers it after it commits, so a reader that finds a
 * hole with no usable claim - because the publisher died in the few
 * instructions between the two - can still ask whether any DEAD peer has an
 * outstanding reservation. */
#define SA_P_FREE   0u
#define SA_P_LIVE   1u
#define SA_P_REAPED 2u

typedef struct {
    volatile uint32_t state;      /* SA_P_*                                  */
    volatile uint32_t epoch;      /* bumped every time this slot is taken    */
    volatile uint64_t pid;
    volatile uint64_t heartbeat;  /* bumped on publish and on drain          */
    volatile uint64_t want;       /* reservations begun and not yet committed */
} sa_peer;

/* The region header. Its own size is recorded in it, so a build that grew the
 * struct cannot silently read an older one's registry at the wrong offset. */
typedef struct {
    volatile uint32_t magic;      /* SA_MAGIC - published LAST at create    */
    uint16_t          layout;     /* SA_LAYOUT_VERSION                      */
    uint16_t          hdr_size;   /* sizeof(sa_header)                      */
    uint32_t          endian;     /* SA_ENDIAN_PROBE                        */
    uint32_t          word;       /* sizeof(void *) - 32- and 64-bit builds
                                   * must not share a region                */
    uint64_t          total;      /* the whole mapping, in bytes            */

    volatile uint64_t brk;        /* bump high-water offset                 */
    uint64_t          reg_off;    /* offset of the sa_reg array             */
    uint32_t          reg_max;
    volatile uint32_t reg_used;   /* claimed entries, not necessarily live  */
    volatile uint32_t reg_refused;/* entries whose extent is not in the
                                   * mapping: corruption, or a writer who
                                   * should not be there                    */

    uint64_t          peers_off;  /* offset of the sa_peer array            */
    uint32_t          peers_max;
    volatile uint32_t peers_used; /* high water, not a live count           */

    /* How long a reader waits for a hole before it starts asking whether the
     * publisher is dead. A field rather than a constant so a test can shorten
     * it; the default is set at create. */
    volatile uint32_t reap_grace_us;

    /* A test hook, and deliberately a FIELD rather than an #ifdef: a forked
     * child has to honour it, and a child of a build that compiled it out
     * cannot. Zero unless a test sets it. See t/10-crash.t - the window
     * between reserving a record and committing it is a few instructions
     * wide, and a crash-safety test that races it is a test that gets marked
     * TODO and then stops meaning anything. */
    volatile uint32_t stall_us;

    volatile unsigned char locks[SA_LOCK_STRIPES];
} sa_header;

/* Round up to the carve alignment. */
static uint64_t sa_align_up(uint64_t n) {
    return (n + (SA_ALIGN - 1)) & ~(uint64_t)(SA_ALIGN - 1);
}

/* Addressing. Every access into a region goes through these two, so there is
 * one place where an offset becomes a pointer and it is never stored. */
#define SA_AT(base, off)      ((void *)((char *)(base) + (size_t)(off)))
#define SA_REGS(base, h)      ((sa_reg *)SA_AT((base), (h)->reg_off))
#define SA_PEERS(base, h)     ((sa_peer *)SA_AT((base), (h)->peers_off))

/* How much mapping a header plus its registry needs, before any carving. */
static uint64_t sa_header_bytes(uint32_t reg_max) {
    return sa_align_up((uint64_t)sizeof(sa_header))
         + sa_align_up((uint64_t)reg_max * (uint64_t)sizeof(sa_reg))
         + sa_align_up((uint64_t)SA_PEERS_MAX * (uint64_t)sizeof(sa_peer));
}

static uint64_t sa_peers_offset(uint32_t reg_max) {
    return sa_align_up((uint64_t)sizeof(sa_header))
         + sa_align_up((uint64_t)reg_max * (uint64_t)sizeof(sa_reg));
}

/* Is this mapping one of ours, and one this build can read?
 *
 * Returns an SA_E_* code. The caller fails open on anything but SA_E_OK: a
 * region whose shape we do not share is not a region we may touch, and saying
 * so costs four comparisons at attach and nothing afterwards. */
#define SA_E_OK        0
#define SA_E_MAGIC   (-1)
#define SA_E_LAYOUT  (-2)
#define SA_E_HDRSIZE (-3)
#define SA_E_ENDIAN  (-4)
#define SA_E_WORD    (-5)
#define SA_E_SHORT   (-6)
#define SA_E_NOMEM   (-7)
#define SA_E_MAP     (-8)
#define SA_E_EXISTS  (-9)
#define SA_E_NOENT  (-10)
#define SA_E_NAME   (-11)
#define SA_E_FULL   (-12)
#define SA_E_NOATOMICS (-13)
#define SA_E_SHAPE  (-14)

static const char *sa_strerror(int rc) {
    switch (rc) {
    case SA_E_OK:       return "no error";
    case SA_E_MAGIC:    return "is not a Shared::Arena region";
    case SA_E_LAYOUT:   return "was made by a build with a different layout version";
    case SA_E_HDRSIZE:  return "was made by a build whose header is a different size";
    case SA_E_ENDIAN:   return "was made on the other endianness";
    case SA_E_WORD:     return "was made by a build with a different pointer width";
    case SA_E_SHORT:    return "is shorter than a header";
    case SA_E_NOMEM:    return "could not be allocated";
    case SA_E_MAP:      return "could not be mapped";
    case SA_E_EXISTS:   return "already exists";
    case SA_E_NOENT:    return "does not exist";
    case SA_E_NAME:     return "has a name that is too long or empty";
    case SA_E_FULL:     return "has no room left";
    case SA_E_NOATOMICS:return "needs atomics this build does not have";
    case SA_E_SHAPE:    return "is already carved with a different type or size";
    default:            return "is not usable";
    }
}

static int sa_check_header(const void *base, uint64_t len) {
    const sa_header *h = (const sa_header *)base;
    if (len < (uint64_t)sizeof(sa_header))      return SA_E_SHORT;
    /* magic first: everything else is meaningless until it holds */
    if (h->magic  != SA_MAGIC)                  return SA_E_MAGIC;
    if (h->layout != SA_LAYOUT_VERSION)         return SA_E_LAYOUT;
    if (h->hdr_size != (uint16_t)sizeof(sa_header)) return SA_E_HDRSIZE;
    if (h->endian != SA_ENDIAN_PROBE)           return SA_E_ENDIAN;
    if (h->word   != (uint32_t)sizeof(void *))  return SA_E_WORD;
    if (h->total  > len)                        return SA_E_SHORT;
    if (h->reg_off + (uint64_t)h->reg_max * sizeof(sa_reg) > h->total)
        return SA_E_SHORT;
    if (h->peers_off + (uint64_t)h->peers_max * sizeof(sa_peer) > h->total)
        return SA_E_SHORT;
    return SA_E_OK;
}

#endif /* SA_FORMAT_H */
