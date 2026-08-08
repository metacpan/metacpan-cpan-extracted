#ifndef SG_ABI_H
#define SG_ABI_H

/* Shared C ABI between Search::Trigram (the provider) and consumers such as
 * Punk, whose markdown mount indexes a documentation tree at boot and answers
 * search requests without a Perl frame between the dispatcher and the index.
 * It is resolved at RUNTIME via Search::Trigram::_abi_ptr - a DBI-style
 * function-pointer table - so there is no link-time symbol coupling and each
 * dist builds and upgrades independently. A consumer reaches the header
 * through ExtUtils::Depends, or vendors a copy pinned at SG_ABI_VERSION, and
 * checks abi_version at boot; a mismatch means "fall back to the Perl-visible
 * methods", never a crash.
 *
 * The table only ever grows at the end; SG_ABI_VERSION bumps on any append,
 * and a consumer requires abi_version >= the version it was written against,
 * treating a later table as a superset it uses a prefix of.
 *
 * Version history:
 *   1 - index_of, add, optimize, doc_count, search
 *
 * Note that only index_of takes pTHX_. The rest of the index is plain C that
 * never touches an SV, and threading the interpreter through calls that have
 * no use for it would be cargo cult.
 *
 * Perl headers (EXTERN.h / perl.h / XSUB.h) must be included before this file
 * so SV and pTHX are defined. */

/* MSVC < 2010 lacks <stdint.h>; match strigram.h's fallback so a consumer
 * that has only this header still compiles there. */
#if defined(_MSC_VER) && _MSC_VER < 1600
  typedef unsigned int uint32_t;
#else
#  include <stdint.h>
#endif

#define SG_ABI_VERSION 1

/* One search result. `text` is BORROWED from the index and stays valid only
 * until the next mutation of that index (add, remove, clear, free). Copy it
 * if you intend to keep it. */
typedef struct sg_abi_hit {
    uint32_t    doc_id;
    float       score;
    const char *text;
    uint32_t    text_len;
} sg_abi_hit;

typedef struct sg_abi {
    int abi_version;                          /* == SG_ABI_VERSION */

    /* The opaque index behind a blessed Search::Trigram object (what
     * Search::Trigram->new returns). Returns NULL for anything that is not
     * one rather than croaking, so it is safe to probe with on a fall-back
     * path.
     *
     * The index belongs to the object: it stays valid while that SV is alive
     * and the caller does not free it. Hold a reference to the OBJECT.
     *
     * There is deliberately no constructor or destructor in this table. A
     * consumer that allocated an index here would have to free it here too,
     * and pairing a malloc in one shared object with a free in another is a
     * good way to find out that each can carry its own heap. Let the Perl
     * object own the lifetime; it already does it correctly. */
    void *(*index_of)(pTHX_ SV *obj_sv);

    /* Index a document. `text` is copied into the index, so the caller may
     * free or reuse its buffer immediately. Returns the new document id,
     * which is what search reports hits against. */
    uint32_t (*add)(void *idx, const char *text, uint32_t len);

    /* Compact the postings after a batch of adds. Optional but worth doing
     * once when a build phase finishes and the index turns read-only. */
    void (*optimize)(void *idx);

    uint32_t (*doc_count)(const void *idx);

    /* Search, writing at most max_hits results into the caller's array and
     * returning how many were written. `limit` is the ranking cut-off asked
     * of the index; max_hits is the hard capacity of `hits`. Passing a stack
     * array is the expected use, which is why nothing is allocated here and
     * there is no result-freeing entry to pair with. */
    uint32_t (*search)(void *idx, const char *q, uint32_t qlen,
                       uint32_t limit, sg_abi_hit *hits, uint32_t max_hits);
} sg_abi;

#endif /* SG_ABI_H */
