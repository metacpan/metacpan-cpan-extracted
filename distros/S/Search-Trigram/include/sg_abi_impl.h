#ifndef SG_ABI_IMPL_H
#define SG_ABI_IMPL_H

/* Search::Trigram-side implementation of the shared C ABI (sg_abi.h).
 * Included by Trigram.xs AFTER strigram.h and STRIGRAM_FROM_SV are in scope.
 * Everything here is private to this translation unit; consumers reach it
 * only through the SG_ABI table returned by Search::Trigram::_abi_ptr. */

#include "sg_abi.h"

/* Like STRIGRAM_FROM_SV but returns NULL where that would dereference
 * whatever it was handed: a consumer probing whether an SV is a usable index
 * must be able to ask without an eval. */
static void *sg_abi_index_of(pTHX_ SV *obj_sv)
{
    SV *rv;
    if (!obj_sv || !SvROK(obj_sv)) return NULL;
    if (!sv_derived_from(obj_sv, "Search::Trigram")) return NULL;
    rv = SvRV(obj_sv);
    if (!SvIOK(rv)) return NULL;
    return INT2PTR(void *, SvIV(rv));
}

static uint32_t sg_abi_add(void *idx, const char *text, uint32_t len)
{
    if (!idx || !text) return 0;
    return strigram_add((strigram_t *)idx, text, len);
}

static void sg_abi_optimize(void *idx)
{
    if (idx) strigram_optimize((strigram_t *)idx);
}

static uint32_t sg_abi_doc_count(const void *idx)
{
    if (!idx) return 0;
    return strigram_doc_count((const strigram_t *)idx);
}

/* strigram_search mallocs its result array and pairs with
 * strigram_results_free. The ABI does not expose that pairing - see the note
 * in sg_abi.h - so this copies into the caller's array and frees the
 * provider-side allocation before returning, keeping both halves of the
 * malloc/free on this side of the boundary.
 *
 * The `text` pointers copied out are borrowed from the index itself, not from
 * the result array, so they stay valid after the free. */
static uint32_t sg_abi_search(void *idx, const char *q, uint32_t qlen,
                              uint32_t limit, sg_abi_hit *hits,
                              uint32_t max_hits)
{
    strigram_result_t *results;
    uint32_t rcount = 0, n, i;

    if (!idx || !q || !hits || max_hits == 0) return 0;

    results = strigram_search((strigram_t *)idx, q, qlen, limit, &rcount);
    if (!results) return 0;

    n = rcount < max_hits ? rcount : max_hits;
    for (i = 0; i < n; i++) {
        hits[i].doc_id   = results[i].doc_id;
        hits[i].score    = results[i].score;
        hits[i].text     = results[i].text;
        hits[i].text_len = results[i].text_len;
    }
    strigram_results_free(results);
    return n;
}

static const sg_abi SG_ABI = {
    SG_ABI_VERSION,
    sg_abi_index_of,
    sg_abi_add,
    sg_abi_optimize,
    sg_abi_doc_count,
    sg_abi_search,
};

#endif /* SG_ABI_IMPL_H */
