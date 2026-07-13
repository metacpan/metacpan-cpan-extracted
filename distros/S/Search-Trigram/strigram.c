#include "strigram.h"
#include <stdlib.h>
#include <string.h>

/* --- Internal types --- */

typedef struct {
    uint32_t  trigram;
    uint32_t *doc_ids;
    uint32_t  count;
    uint32_t  cap;
} posting_t;

typedef struct {
    uint32_t  doc_id;
    char     *text;
    uint32_t  text_len;
    uint32_t  tcount;   /* unique trigrams in this doc */
    int       deleted;
} doc_entry_t;

struct strigram_s {
    posting_t   *postings;
    uint32_t     posting_count;
    uint32_t     posting_cap;

    doc_entry_t *docs;
    uint32_t     doc_count;
    uint32_t     doc_cap;
    uint32_t     next_id;
    uint32_t     live_count;

    /* Epoch-based match accumulator: avoids per-search calloc */
    uint32_t     search_epoch;
    uint32_t    *match_epoch;
    uint32_t    *match_count_buf;
    uint32_t     match_cap;
};

/* --- Trigram extraction --- */

static uint8_t lc_byte(uint8_t c) {
    return (c >= 'A' && c <= 'Z') ? (uint8_t)(c + 32) : c;
}

/* Build a lowercased, space-padded copy: " text " */
static uint8_t *build_padded(const char *text, uint32_t len) {
    uint8_t  *buf;
    uint32_t  j;
    buf = (uint8_t *)malloc(len + 2);
    if (!buf) return NULL;
    buf[0] = ' ';
    for (j = 0; j < len; j++) buf[j + 1] = lc_byte((uint8_t)text[j]);
    buf[len + 1] = ' ';
    return buf;
}

/* Extract trigrams from text: plen=len+2, ntg=len (one per byte). */
static uint32_t *extract_trigrams(const char *text, uint32_t len, uint32_t *out_count) {
    uint32_t  ntg = len;   /* plen-2 == len */
    uint8_t  *buf;
    uint32_t *tgs;
    uint32_t  i;

    if (ntg == 0) { *out_count = 0; return NULL; }

    buf = build_padded(text, len);
    if (!buf) { *out_count = 0; return NULL; }

    tgs = (uint32_t *)malloc(ntg * sizeof(uint32_t));
    if (!tgs) { free(buf); *out_count = 0; return NULL; }

    for (i = 0; i < ntg; i++)
        tgs[i] = ((uint32_t)buf[i] << 16) | ((uint32_t)buf[i+1] << 8) | (uint32_t)buf[i+2];

    free(buf);
    *out_count = ntg;
    return tgs;
}

static int cmp_u32(const void *a, const void *b) {
    uint32_t x = *(const uint32_t *)a;
    uint32_t y = *(const uint32_t *)b;
    return (x > y) - (x < y);
}

static uint32_t sort_unique(uint32_t *arr, uint32_t n) {
    uint32_t w, i;
    if (n == 0) return 0;
    qsort(arr, (size_t)n, sizeof(uint32_t), cmp_u32);
    w = 1;
    for (i = 1; i < n; i++) {
        if (arr[i] != arr[i - 1]) arr[w++] = arr[i];
    }
    return w;
}

/* --- Posting list management --- */

static uint32_t posting_find(const strigram_t *idx, uint32_t trigram) {
    uint32_t lo = 0, hi = idx->posting_count;
    while (lo < hi) {
        uint32_t mid = lo + (hi - lo) / 2;
        if      (idx->postings[mid].trigram < trigram) lo = mid + 1;
        else if (idx->postings[mid].trigram > trigram) hi = mid;
        else return mid;
    }
    return UINT32_MAX;
}

static uint32_t posting_find_insert(strigram_t *idx, uint32_t trigram) {
    uint32_t lo = 0, hi = idx->posting_count;
    while (lo < hi) {
        uint32_t mid = lo + (hi - lo) / 2;
        if      (idx->postings[mid].trigram < trigram) lo = mid + 1;
        else if (idx->postings[mid].trigram > trigram) hi = mid;
        else return mid;
    }
    if (idx->posting_count >= idx->posting_cap) {
        uint32_t  new_cap = idx->posting_cap ? idx->posting_cap * 2 : 256;
        posting_t *np     = (posting_t *)realloc(idx->postings,
                                                  new_cap * sizeof(posting_t));
        if (!np) return UINT32_MAX;
        idx->postings    = np;
        idx->posting_cap = new_cap;
    }
    if (lo < idx->posting_count) {
        memmove(idx->postings + lo + 1,
                idx->postings + lo,
                (idx->posting_count - lo) * sizeof(posting_t));
    }
    idx->postings[lo].trigram  = trigram;
    idx->postings[lo].doc_ids  = NULL;
    idx->postings[lo].count    = 0;
    idx->postings[lo].cap      = 0;
    idx->posting_count++;
    return lo;
}

static int posting_append_doc(posting_t *p, uint32_t doc_id) {
    if (p->count >= p->cap) {
        uint32_t  new_cap = p->cap ? p->cap * 2 : 4;
        uint32_t *np      = (uint32_t *)realloc(p->doc_ids,
                                                 new_cap * sizeof(uint32_t));
        if (!np) return 0;
        p->doc_ids = np;
        p->cap     = new_cap;
    }
    p->doc_ids[p->count++] = doc_id;
    return 1;
}

/* --- Lifecycle --- */

strigram_t *strigram_new(void) {
    return (strigram_t *)calloc(1, sizeof(strigram_t));
}

void strigram_clear(strigram_t *idx) {
    uint32_t i;
    if (!idx) return;
    for (i = 0; i < idx->doc_count; i++)
        free(idx->docs[i].text);
    idx->doc_count  = 0;
    idx->live_count = 0;
    idx->next_id    = 0;
    for (i = 0; i < idx->posting_count; i++)
        free(idx->postings[i].doc_ids);
    idx->posting_count = 0;
    /* Reset epoch so all cached match slots appear stale */
    idx->search_epoch = 0;
}

void strigram_free(strigram_t *idx) {
    if (!idx) return;
    strigram_clear(idx);
    free(idx->docs);
    free(idx->postings);
    free(idx->match_epoch);
    free(idx->match_count_buf);
    free(idx);
}

/* --- Indexing --- */

uint32_t strigram_add(strigram_t *idx, const char *text, uint32_t len) {
    uint32_t     doc_id, ntg, utg, i;
    doc_entry_t *doc;
    uint32_t    *tgs;

    if (idx->doc_count >= idx->doc_cap) {
        uint32_t     new_cap = idx->doc_cap ? idx->doc_cap * 2 : 64;
        doc_entry_t *np      = (doc_entry_t *)realloc(idx->docs,
                                                       new_cap * sizeof(doc_entry_t));
        if (!np) return UINT32_MAX;
        idx->docs    = np;
        idx->doc_cap = new_cap;
    }

    doc_id        = idx->next_id++;
    doc           = &idx->docs[idx->doc_count++];
    doc->doc_id   = doc_id;
    doc->text     = (char *)malloc(len + 1);
    if (!doc->text) { idx->doc_count--; idx->next_id--; return UINT32_MAX; }
    memcpy(doc->text, text, len);
    doc->text[len] = '\0';
    doc->text_len  = len;
    doc->deleted   = 0;

    tgs = extract_trigrams(text, len, &ntg);
    utg = 0;
    if (tgs) {
        utg = sort_unique(tgs, ntg);
        for (i = 0; i < utg; i++) {
            uint32_t pi = posting_find_insert(idx, tgs[i]);
            if (pi != UINT32_MAX)
                posting_append_doc(&idx->postings[pi], doc_id);
        }
        free(tgs);
    }
    doc->tcount = utg;
    idx->live_count++;
    return doc_id;
}

void strigram_remove(strigram_t *idx, uint32_t doc_id) {
    uint32_t i;
    for (i = 0; i < idx->doc_count; i++) {
        if (idx->docs[i].doc_id == doc_id && !idx->docs[i].deleted) {
            idx->docs[i].deleted = 1;
            if (idx->live_count > 0) idx->live_count--;
            return;
        }
    }
}

void strigram_optimize(strigram_t *idx) {
    uint32_t  i, pi, w;
    uint8_t  *is_del;

    if (!idx || idx->next_id == 0) return;

    is_del = (uint8_t *)calloc((size_t)idx->next_id, 1);
    if (!is_del) return;

    for (i = 0; i < idx->doc_count; i++) {
        if (idx->docs[i].deleted)
            is_del[idx->docs[i].doc_id] = 1;
    }
    for (pi = 0; pi < idx->posting_count; pi++) {
        posting_t *p = &idx->postings[pi];
        w = 0;
        for (i = 0; i < p->count; i++) {
            if (!is_del[p->doc_ids[i]])
                p->doc_ids[w++] = p->doc_ids[i];
        }
        p->count = w;
    }
    free(is_del);

    w = 0;
    for (i = 0; i < idx->doc_count; i++) {
        if (!idx->docs[i].deleted) {
            if (w != i) idx->docs[w] = idx->docs[i];
            w++;
        } else {
            free(idx->docs[i].text);
        }
    }
    idx->doc_count = w;
}

/* --- Min-heap for top-K selection --- */

typedef struct {
    uint32_t doc_idx;
    float    score;
} scored_t;

static void heap_sift_down(scored_t *h, uint32_t n, uint32_t i) {
    uint32_t s, l, r;
    scored_t tmp;
    for (;;) {
        s = i; l = 2*i+1; r = 2*i+2;
        if (l < n && h[l].score < h[s].score) s = l;
        if (r < n && h[r].score < h[s].score) s = r;
        if (s == i) break;
        tmp = h[i]; h[i] = h[s]; h[s] = tmp;
        i = s;
    }
}

/* --- Search --- */

strigram_result_t *strigram_search(strigram_t *idx,
                                   const char *query, uint32_t qlen,
                                   uint32_t    limit,
                                   uint32_t   *result_count)
{
    uint32_t           ntg, qtcount, i;
    uint32_t          *tgs;
    scored_t          *scored;
    strigram_result_t *results;
    uint32_t           heap_n, nresults;

    *result_count = 0;
    if (!idx || limit == 0) return NULL;

    tgs = extract_trigrams(query, qlen, &ntg);
    qtcount = 0;
    if (tgs) {
        qtcount = sort_unique(tgs, ntg);
    }
    if (qtcount == 0 || idx->live_count == 0) {
        free(tgs);
        return NULL;
    }

    /* Grow epoch arrays to cover next_id without per-search zeroing */
    if (idx->next_id > idx->match_cap) {
        uint32_t  new_cap = idx->next_id + (idx->next_id >> 1) + 16;
        uint32_t *ne      = (uint32_t *)realloc(idx->match_epoch,
                                                  new_cap * sizeof(uint32_t));
        uint32_t *nc      = (uint32_t *)realloc(idx->match_count_buf,
                                                  new_cap * sizeof(uint32_t));
        if (!ne || !nc) {
            if (ne) idx->match_epoch     = ne;
            if (nc) idx->match_count_buf = nc;
            free(tgs);
            return NULL;
        }
        /* Zero new epoch slots so they appear stale */
        memset(ne + idx->match_cap, 0,
               (new_cap - idx->match_cap) * sizeof(uint32_t));
        idx->match_epoch     = ne;
        idx->match_count_buf = nc;
        idx->match_cap       = new_cap;
    }

    /* Advance epoch; on wrap, zero all slots and restart from 1 */
    if (++idx->search_epoch == 0) {
        memset(idx->match_epoch, 0, idx->match_cap * sizeof(uint32_t));
        idx->search_epoch = 1;
    }

    /* Accumulate match counts — lazy-init per slot on first touch */
    for (i = 0; i < qtcount; i++) {
        uint32_t pi = posting_find(idx, tgs[i]);
        if (pi != UINT32_MAX) {
            posting_t *p = &idx->postings[pi];
            uint32_t j;
            for (j = 0; j < p->count; j++) {
                uint32_t did = p->doc_ids[j];
                if (idx->match_epoch[did] != idx->search_epoch) {
                    idx->match_epoch[did]     = idx->search_epoch;
                    idx->match_count_buf[did] = 0;
                }
                idx->match_count_buf[did]++;
            }
        }
    }
    free(tgs);

    /* Top-K selection with min-heap: O(n log limit) vs O(n log n) */
    scored = (scored_t *)malloc(limit * sizeof(scored_t));
    if (!scored) return NULL;
    heap_n = 0;

    for (i = 0; i < idx->doc_count; i++) {
        doc_entry_t *d = &idx->docs[i];
        uint32_t mc;
        float score;
        if (d->deleted) continue;
        if (idx->match_epoch[d->doc_id] != idx->search_epoch) continue;
        mc = idx->match_count_buf[d->doc_id];
        if (mc == 0) continue;
        score = (float)(2 * mc) /
                (float)(qtcount + (d->tcount ? d->tcount : 1));
        if (heap_n < limit) {
            scored[heap_n].doc_idx = i;
            scored[heap_n].score   = score;
            heap_n++;
            if (heap_n == limit) {
                /* Build min-heap in-place */
                int k;
                for (k = (int)(heap_n >> 1) - 1; k >= 0; k--)
                    heap_sift_down(scored, heap_n, (uint32_t)k);
            }
        } else if (score > scored[0].score) {
            scored[0].doc_idx = i;
            scored[0].score   = score;
            heap_sift_down(scored, heap_n, 0);
        }
    }

    if (heap_n == 0) { free(scored); return NULL; }

    /* When fewer results than limit, the inline heapify inside the loop
     * never fired (it only triggers at heap_n == limit).  Build the heap
     * now so the heap-sort below produces a correctly ordered output. */
    if (heap_n < limit) {
        int k;
        for (k = (int)(heap_n >> 1) - 1; k >= 0; k--)
            heap_sift_down(scored, heap_n, (uint32_t)k);
    }

    /* Min-heap sort: each iteration extracts the minimum to the end,
     * leaving scored[0..nresults-1] in descending order (max at [0]). */
    nresults = heap_n;
    {
        uint32_t rem = nresults;
        while (rem > 1) {
            scored_t tmp = scored[0]; scored[0] = scored[rem-1]; scored[rem-1] = tmp;
            rem--;
            heap_sift_down(scored, rem, 0);
        }
    }

    results = (strigram_result_t *)malloc(nresults * sizeof(strigram_result_t));
    if (!results) { free(scored); return NULL; }

    for (i = 0; i < nresults; i++) {
        doc_entry_t *d = &idx->docs[scored[i].doc_idx];
        results[i].doc_id   = d->doc_id;
        results[i].score    = scored[i].score;
        results[i].text     = d->text;
        results[i].text_len = d->text_len;
    }
    free(scored);

    *result_count = nresults;
    return results;
}

void strigram_results_free(strigram_result_t *results) {
    free(results);
}

/* --- Stats --- */

uint32_t strigram_doc_count(const strigram_t *idx) {
    return idx ? idx->live_count : 0;
}

uint32_t strigram_trigram_count(const strigram_t *idx) {
    return idx ? idx->posting_count : 0;
}
