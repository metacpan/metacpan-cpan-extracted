/*
 * pdfmake_cmap.c — PDF ToUnicode CMap parser implementation.
 */

#include "pdfmake_cmap.h"
#include <stdlib.h>
#include <string.h>

/*============================================================================
 * Data structures
 *==========================================================================*/

typedef struct {
    uint32_t code;
    uint8_t  uni_count;                        /* 1..PDFMAKE_CMAP_MAX_UNI */
    uint32_t uni[PDFMAKE_CMAP_MAX_UNI];
} cmap_entry_t;

typedef struct {
    uint32_t  lo;
    uint32_t  hi;
    uint32_t  start_uni;                       /* incremented per code in range */
} cmap_range_t;

struct pdfmake_cmap {
    /* Sorted single-code entries */
    cmap_entry_t *entries;
    size_t        entry_count;
    size_t        entry_cap;

    /* Sorted range entries (lo ≤ code ≤ hi, unicode = start_uni + (code - lo)) */
    cmap_range_t *ranges;
    size_t        range_count;
    size_t        range_cap;

    /* Per-range unicode override arrays (for array form of bfrange):
     * index into this pool from range->start_uni when -1 is used.
     * Simpler: we store array-form ranges as expanded entries. */

    int           code_width;    /* 1 or 2 */
    pdfmake_arena_t *arena;
};

/*============================================================================
 * Internal helpers — tokenizer
 *==========================================================================*/

typedef struct {
    const uint8_t *p;
    const uint8_t *end;
} cmap_tok_t;

static void tok_skip_ws(cmap_tok_t *t) {
    while (t->p < t->end) {
        uint8_t c = *t->p;
        if (c == ' ' || c == '\t' || c == '\r' || c == '\n' || c == '\f') {
            t->p++;
        } else if (c == '%') {
            /* Comment to end of line */
            while (t->p < t->end && *t->p != '\n' && *t->p != '\r')
                t->p++;
        } else {
            break;
        }
    }
}

static int is_hex(uint8_t c) {
    return (c >= '0' && c <= '9') || (c >= 'a' && c <= 'f') || (c >= 'A' && c <= 'F');
}

static int hex_val(uint8_t c) {
    if (c >= '0' && c <= '9') return c - '0';
    if (c >= 'a' && c <= 'f') return c - 'a' + 10;
    if (c >= 'A' && c <= 'F') return c - 'A' + 10;
    return -1;
}

/* Parse a hex string <...> into a sequence of big-endian bytes.
 * out must have at least (len/2) slots.
 * Returns number of bytes written, or -1 on error.
 * Leaves t->p pointing past the closing '>'. */
static int tok_hex_string(cmap_tok_t *t, uint8_t *out, size_t out_cap) {
    size_t written;
    int nibble_hi;
    uint8_t c;
    int v;

    tok_skip_ws(t);
    if (t->p >= t->end || *t->p != '<') return -1;
    t->p++;  /* skip '<' */

    written = 0;
    nibble_hi = -1;

    while (t->p < t->end && *t->p != '>') {
        c = *t->p++;
        if (c == ' ' || c == '\t' || c == '\r' || c == '\n') continue;
        v = hex_val(c);
        if (v < 0) return -1;
        if (nibble_hi < 0) {
            nibble_hi = v;
        } else {
            if (written >= out_cap) return -1;
            out[written++] = (uint8_t)((nibble_hi << 4) | v);
            nibble_hi = -1;
        }
    }
    /* Handle odd nibble count — pad with 0 per PDF spec */
    if (nibble_hi >= 0) {
        if (written >= out_cap) return -1;
        out[written++] = (uint8_t)(nibble_hi << 4);
    }
    if (t->p >= t->end || *t->p != '>') return -1;
    t->p++;  /* skip '>' */

    return (int)written;
}

/* Parse a hex string as a single big-endian integer (1-4 bytes).
 * Returns byte width on success, -1 on failure. */
static int tok_hex_int(cmap_tok_t *t, uint32_t *out_value) {
    uint8_t buf[8];
    int n;
    uint32_t v;
    int i;

    n = tok_hex_string(t, buf, sizeof(buf));
    if (n < 0 || n > 4) return -1;
    v = 0;
    for (i = 0; i < n; i++) {
        v = (v << 8) | buf[i];
    }
    *out_value = v;
    return n;
}

/* Parse a hex string as a sequence of BE16 Unicode code units.
 * Handles surrogate pairs → codepoint collapse.
 * Returns count of codepoints (≤ PDFMAKE_CMAP_MAX_UNI), -1 on error. */
static int tok_hex_unicode(cmap_tok_t *t, uint32_t *out, size_t out_cap) {
    uint8_t buf[32];
    int n;
    size_t written;
    int i;
    uint16_t hi;
    uint32_t cp;
    uint16_t lo;

    n = tok_hex_string(t, buf, sizeof(buf));
    if (n < 0 || (n % 2) != 0) return -1;

    written = 0;
    i = 0;
    while (i + 1 < n) {
        hi = ((uint16_t)buf[i] << 8) | buf[i + 1];
        i += 2;
        cp = hi;

        /* Surrogate pair? */
        if (hi >= 0xD800 && hi <= 0xDBFF && i + 1 < n) {
            lo = ((uint16_t)buf[i] << 8) | buf[i + 1];
            if (lo >= 0xDC00 && lo <= 0xDFFF) {
                cp = 0x10000 + ((hi - 0xD800) << 10) + (lo - 0xDC00);
                i += 2;
            }
        }

        if (written >= out_cap) return -1;
        out[written++] = cp;
    }
    return (int)written;
}

/* Parse an integer count (e.g. "42 beginbfchar"). */
static int tok_int(cmap_tok_t *t, long *out) {
    const uint8_t *start;
    int negative;
    long v;
    int any;

    tok_skip_ws(t);
    start = t->p;
    negative = 0;
    if (t->p < t->end && (*t->p == '-' || *t->p == '+')) {
        if (*t->p == '-') negative = 1;
        t->p++;
    }
    v = 0;
    any = 0;
    while (t->p < t->end && *t->p >= '0' && *t->p <= '9') {
        v = v * 10 + (*t->p - '0');
        t->p++;
        any = 1;
    }
    if (!any) { t->p = start; return -1; }
    *out = negative ? -v : v;
    return 0;
}

/* Check if upcoming tokens are a keyword (followed by delimiter). Advances
 * the tokenizer past the keyword on match; leaves position unchanged otherwise. */
static int tok_match_keyword(cmap_tok_t *t, const char *kw) {
    const uint8_t *save;
    size_t kwlen;
    uint8_t c;

    save = t->p;
    tok_skip_ws(t);
    kwlen = strlen(kw);
    if ((size_t)(t->end - t->p) < kwlen) { t->p = save; return 0; }
    if (memcmp(t->p, kw, kwlen) != 0) { t->p = save; return 0; }
    /* Must be followed by delimiter */
    if (t->p + kwlen < t->end) {
        c = t->p[kwlen];
        if (!(c == ' ' || c == '\t' || c == '\r' || c == '\n' ||
              c == '<' || c == '[' || c == '/' || c == '%')) {
            t->p = save;
            return 0;
        }
    }
    t->p += kwlen;
    return 1;
}

/*============================================================================
 * CMap population
 *==========================================================================*/

static int cmap_reserve_entries(pdfmake_cmap_t *cm, size_t need) {
    size_t new_cap;
    cmap_entry_t *n;

    if (need <= cm->entry_cap) return 0;
    new_cap = cm->entry_cap ? cm->entry_cap : 64;
    while (new_cap < need) new_cap *= 2;
    n = realloc(cm->entries, new_cap * sizeof(cmap_entry_t));
    if (!n) return -1;
    cm->entries = n;
    cm->entry_cap = new_cap;
    return 0;
}

static int cmap_reserve_ranges(pdfmake_cmap_t *cm, size_t need) {
    size_t new_cap;
    cmap_range_t *n;

    if (need <= cm->range_cap) return 0;
    new_cap = cm->range_cap ? cm->range_cap : 16;
    while (new_cap < need) new_cap *= 2;
    n = realloc(cm->ranges, new_cap * sizeof(cmap_range_t));
    if (!n) return -1;
    cm->ranges = n;
    cm->range_cap = new_cap;
    return 0;
}

static int cmap_add_entry(pdfmake_cmap_t *cm, uint32_t code,
                           const uint32_t *uni, size_t uni_count) {
    cmap_entry_t *e;
    size_t i;

    if (uni_count == 0 || uni_count > PDFMAKE_CMAP_MAX_UNI) return -1;
    if (cmap_reserve_entries(cm, cm->entry_count + 1) < 0) return -1;
    e = &cm->entries[cm->entry_count++];
    e->code = code;
    e->uni_count = (uint8_t)uni_count;
    for (i = 0; i < uni_count; i++) e->uni[i] = uni[i];
    return 0;
}

static int cmap_add_range(pdfmake_cmap_t *cm,
                           uint32_t lo, uint32_t hi, uint32_t start_uni) {
    cmap_range_t *r;

    if (hi < lo) return -1;
    if (cmap_reserve_ranges(cm, cm->range_count + 1) < 0) return -1;
    r = &cm->ranges[cm->range_count++];
    r->lo = lo;
    r->hi = hi;
    r->start_uni = start_uni;
    return 0;
}

/*============================================================================
 * Operator handlers
 *==========================================================================*/

/* Parse: N beginbfchar  (code) (uni) ... endbfchar
 * or     N begincidchar (code) (uni) ... endcidchar */
static int parse_bfchar_section(cmap_tok_t *t, pdfmake_cmap_t *cm, long count) {
    long i;
    uint32_t code;
    int code_w;
    uint32_t uni[PDFMAKE_CMAP_MAX_UNI];
    int n;

    for (i = 0; i < count; i++) {
        code_w = tok_hex_int(t, &code);
        if (code_w < 0) return -1;
        if (cm->code_width == 0 || code_w > cm->code_width)
            cm->code_width = code_w;

        n = tok_hex_unicode(t, uni, PDFMAKE_CMAP_MAX_UNI);
        if (n <= 0) return -1;

        if (cmap_add_entry(cm, code, uni, (size_t)n) < 0) return -1;
    }
    /* Skip the endbfchar/endcidchar keyword */
    if (!tok_match_keyword(t, "endbfchar") &&
        !tok_match_keyword(t, "endcidchar")) {
        return -1;
    }
    return 0;
}

/* Parse: N beginbfrange (lo) (hi) (uni) ... endbfrange
 * or     N beginbfrange (lo) (hi) [<uni1> <uni2> ...] endbfrange
 * Array form: each code in [lo..hi] maps to the corresponding array entry. */
static int parse_bfrange_section(cmap_tok_t *t, pdfmake_cmap_t *cm, long count) {
    long i;
    uint32_t lo, hi;
    int lw, hw;
    int w;
    uint32_t uni[PDFMAKE_CMAP_MAX_UNI];
    int n;
    uint32_t c;
    uint32_t u[PDFMAKE_CMAP_MAX_UNI];
    int j;
    uint32_t delta;
    uint32_t uni2[PDFMAKE_CMAP_MAX_UNI];
    int n2;

    for (i = 0; i < count; i++) {
        lw = tok_hex_int(t, &lo);
        hw = tok_hex_int(t, &hi);
        if (lw < 0 || hw < 0) return -1;
        w = lw > hw ? lw : hw;
        if (cm->code_width == 0 || w > cm->code_width) cm->code_width = w;

        tok_skip_ws(t);
        if (t->p >= t->end) return -1;

        if (*t->p == '<') {
            /* Range form: single unicode start */
            n = tok_hex_unicode(t, uni, PDFMAKE_CMAP_MAX_UNI);
            if (n <= 0) return -1;

            if (n == 1) {
                /* Simple single-codepoint range — store as compact range */
                if (cmap_add_range(cm, lo, hi, uni[0]) < 0) return -1;
            } else {
                /* Multi-codepoint sequence: only the first code uses the full
                 * sequence; subsequent codes would increment the last codepoint
                 * per the spec, but that's rarely used. Expand as entries. */
                for (c = lo; c <= hi; c++) {
                    for (j = 0; j < n; j++) u[j] = uni[j];
                    /* Increment the last codepoint */
                    delta = c - lo;
                    if (n > 0) u[n - 1] += delta;
                    if (cmap_add_entry(cm, c, u, (size_t)n) < 0) return -1;
                }
            }
        } else if (*t->p == '[') {
            /* Array form */
            t->p++;  /* skip '[' */
            for (c = lo; c <= hi; c++) {
                tok_skip_ws(t);
                if (t->p >= t->end || *t->p != '<') return -1;
                n2 = tok_hex_unicode(t, uni2, PDFMAKE_CMAP_MAX_UNI);
                if (n2 <= 0) return -1;
                if (cmap_add_entry(cm, c, uni2, (size_t)n2) < 0) return -1;
            }
            tok_skip_ws(t);
            if (t->p >= t->end || *t->p != ']') return -1;
            t->p++;  /* skip ']' */
        } else {
            return -1;
        }
    }
    if (!tok_match_keyword(t, "endbfrange") &&
        !tok_match_keyword(t, "endcidrange")) {
        return -1;
    }
    return 0;
}

/* Parse: N begincodespacerange <lo> <hi> ... endcodespacerange
 * We use this only to detect the maximum code width. */
static int parse_codespace_section(cmap_tok_t *t, pdfmake_cmap_t *cm, long count) {
    long i;
    uint32_t lo, hi;
    int lw, hw;
    int w;

    for (i = 0; i < count; i++) {
        lw = tok_hex_int(t, &lo);
        hw = tok_hex_int(t, &hi);
        if (lw < 0 || hw < 0) return -1;
        w = lw > hw ? lw : hw;
        if (cm->code_width == 0 || w > cm->code_width) cm->code_width = w;
    }
    if (!tok_match_keyword(t, "endcodespacerange")) return -1;
    return 0;
}

/*============================================================================
 * Sorting / lookup
 *==========================================================================*/

static int entry_cmp(const void *a, const void *b) {
    uint32_t ca = ((const cmap_entry_t *)a)->code;
    uint32_t cb = ((const cmap_entry_t *)b)->code;
    return (ca > cb) - (ca < cb);
}

static int range_cmp(const void *a, const void *b) {
    uint32_t la = ((const cmap_range_t *)a)->lo;
    uint32_t lb = ((const cmap_range_t *)b)->lo;
    return (la > lb) - (la < lb);
}

/*============================================================================
 * Public API
 *==========================================================================*/

pdfmake_cmap_t *pdfmake_cmap_parse(pdfmake_arena_t *arena,
                                    const uint8_t *data, size_t len) {
    pdfmake_cmap_t *cm;
    cmap_tok_t tok;
    const uint8_t *save;
    long count;
    int rc;
    cmap_entry_t *arena_entries;
    cmap_range_t *arena_ranges;

    if (!arena || !data || len == 0) return NULL;

    cm = pdfmake_arena_alloc(arena, sizeof(*cm));
    if (!cm) return NULL;
    memset(cm, 0, sizeof(*cm));
    cm->arena = arena;

    tok.p = data;
    tok.end = data + len;

    /* Scan for operator sections; skip everything else.
     * We look for "N begin<op>" patterns. */
    while (tok.p < tok.end) {
        tok_skip_ws(&tok);
        if (tok.p >= tok.end) break;

        /* Try to parse an integer followed by a keyword */
        save = tok.p;
        if (tok_int(&tok, &count) == 0 && count > 0) {
            tok_skip_ws(&tok);
            rc = 0;
            if (tok_match_keyword(&tok, "beginbfchar") ||
                tok_match_keyword(&tok, "begincidchar")) {
                rc = parse_bfchar_section(&tok, cm, count);
            } else if (tok_match_keyword(&tok, "beginbfrange") ||
                       tok_match_keyword(&tok, "begincidrange")) {
                rc = parse_bfrange_section(&tok, cm, count);
            } else if (tok_match_keyword(&tok, "begincodespacerange")) {
                rc = parse_codespace_section(&tok, cm, count);
            } else {
                /* Not a section we care about; advance past the keyword (if any)
                 * by skipping one token so we don't loop forever. */
                while (tok.p < tok.end &&
                       *tok.p != ' ' && *tok.p != '\t' &&
                       *tok.p != '\r' && *tok.p != '\n' &&
                       *tok.p != '%') {
                    tok.p++;
                }
                continue;
            }
            if (rc != 0) {
                /* Parse error — bail out with what we have so far */
                break;
            }
        } else {
            /* Not a "N begin*" — skip one token and continue */
            tok.p = save;
            while (tok.p < tok.end &&
                   *tok.p != ' ' && *tok.p != '\t' &&
                   *tok.p != '\r' && *tok.p != '\n' &&
                   *tok.p != '%') {
                tok.p++;
            }
            if (tok.p == save) tok.p++;  /* safety: always make progress */
        }
    }

    /* Sort for binary-search lookup */
    if (cm->entry_count > 1) {
        qsort(cm->entries, cm->entry_count, sizeof(cmap_entry_t), entry_cmp);
    }
    if (cm->range_count > 1) {
        qsort(cm->ranges, cm->range_count, sizeof(cmap_range_t), range_cmp);
    }

    if (cm->code_width == 0) cm->code_width = 2;  /* default to 2-byte */

    /* Copy the heap-allocated tables into the arena so the whole CMap is
     * arena-owned and freed with the document. */
    if (cm->entry_count > 0) {
        arena_entries = pdfmake_arena_alloc(
            arena, cm->entry_count * sizeof(cmap_entry_t));
        if (arena_entries) {
            memcpy(arena_entries, cm->entries,
                   cm->entry_count * sizeof(cmap_entry_t));
            free(cm->entries);
            cm->entries = arena_entries;
            cm->entry_cap = cm->entry_count;
        }
    }
    if (cm->range_count > 0) {
        arena_ranges = pdfmake_arena_alloc(
            arena, cm->range_count * sizeof(cmap_range_t));
        if (arena_ranges) {
            memcpy(arena_ranges, cm->ranges,
                   cm->range_count * sizeof(cmap_range_t));
            free(cm->ranges);
            cm->ranges = arena_ranges;
            cm->range_cap = cm->range_count;
        }
    }

    return cm;
}

int pdfmake_cmap_lookup(const pdfmake_cmap_t *cmap,
                        uint32_t code,
                        uint32_t *out,
                        size_t   *out_count) {
    if (!cmap || !out || !out_count) return 0;

    /* Binary search single-code entries first */
    if (cmap->entry_count > 0) {
        size_t lo = 0, hi = cmap->entry_count;
        while (lo < hi) {
            size_t mid = (lo + hi) / 2;
            uint32_t mc = cmap->entries[mid].code;
            if (mc == code) {
                const cmap_entry_t *e = &cmap->entries[mid];
                size_t k;
                for (k = 0; k < e->uni_count; k++) out[k] = e->uni[k];
                *out_count = e->uni_count;
                return 1;
            }
            if (mc < code) lo = mid + 1;
            else hi = mid;
        }
    }

    /* Binary search ranges */
    if (cmap->range_count > 0) {
        size_t lo = 0, hi = cmap->range_count;
        /* Find last range with range.lo <= code */
        while (lo < hi) {
            size_t mid = (lo + hi) / 2;
            if (cmap->ranges[mid].lo <= code) lo = mid + 1;
            else hi = mid;
        }
        if (lo > 0) {
            const cmap_range_t *r = &cmap->ranges[lo - 1];
            if (code >= r->lo && code <= r->hi) {
                out[0] = r->start_uni + (code - r->lo);
                *out_count = 1;
                return 1;
            }
        }
    }

    return 0;
}

int pdfmake_cmap_code_width(const pdfmake_cmap_t *cmap) {
    return cmap ? cmap->code_width : 0;
}

size_t pdfmake_cmap_size(const pdfmake_cmap_t *cmap) {
    if (!cmap) return 0;
    return cmap->entry_count + cmap->range_count;
}
