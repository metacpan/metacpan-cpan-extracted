/*
 * pdfmake_font_widths.c — Glyph-advance + descriptor metrics resolution.
 *
 * PDF spec references:
 *   §9.2.4  Simple font /FirstChar, /LastChar, /Widths
 *   §9.7.4.3 CID /W array (formats 1 and 2), /DW default width
 *   §9.8.1  Font descriptor /Ascent, /Descent, /CapHeight, /XHeight
 */

#include "pdfmake_font_widths.h"
#include "pdfmake_reader.h"
#include "pdfmake_parser.h"
#include "pdfmake_font.h"
#include "pdfmake_arena.h"
#include "pdfmake_buf.h"
#include <string.h>
#include <stdlib.h>
#include <stdio.h>

/*============================================================================
 * Helpers
 *==========================================================================*/

static int16_t int_of(const pdfmake_obj_t *o, int16_t fallback) {
    if (!o) return fallback;
    if (o->kind == PDFMAKE_INT)  return (int16_t)o->as.i;
    if (o->kind == PDFMAKE_REAL) return (int16_t)o->as.r;
    return fallback;
}

static int32_t int32_of(const pdfmake_obj_t *o, int32_t fallback) {
    if (!o) return fallback;
    if (o->kind == PDFMAKE_INT)  return (int32_t)o->as.i;
    if (o->kind == PDFMAKE_REAL) return (int32_t)o->as.r;
    return fallback;
}

/*============================================================================
 * Descriptor metrics
 *==========================================================================*/

static void fill_descriptor_metrics(pdfmake_arena_t *arena,
                                    pdfmake_obj_t *descriptor,
                                    pdfmake_font_widths_t *out)
{
    uint32_t ascent_k;
    uint32_t descent_k;
    uint32_t cap_k;
    uint32_t xh_k;
    uint32_t mw_k;
    pdfmake_obj_t *mw;
    if (!descriptor || descriptor->kind != PDFMAKE_DICT) return;

    ascent_k  = pdfmake_arena_intern_name(arena, "Ascent", 6);
    descent_k = pdfmake_arena_intern_name(arena, "Descent", 7);
    cap_k     = pdfmake_arena_intern_name(arena, "CapHeight", 9);
    xh_k      = pdfmake_arena_intern_name(arena, "XHeight", 7);
    mw_k      = pdfmake_arena_intern_name(arena, "MissingWidth", 12);

    out->ascent     = int_of(pdfmake_dict_get(descriptor, ascent_k),  out->ascent);
    out->descent    = int_of(pdfmake_dict_get(descriptor, descent_k), out->descent);
    out->cap_height = int_of(pdfmake_dict_get(descriptor, cap_k),     out->cap_height);
    out->x_height   = int_of(pdfmake_dict_get(descriptor, xh_k),      out->x_height);

    mw = pdfmake_dict_get(descriptor, mw_k);
    if (mw) out->default_width = int_of(mw, out->default_width);
}

/*============================================================================
 * Simple font /Widths
 *==========================================================================*/

void pdfmake_font_widths_init(pdfmake_font_widths_t *w) {
    memset(w, 0, sizeof(*w));
}

int pdfmake_font_widths_from_simple(
    pdfmake_arena_t       *arena,
    pdfmake_obj_t         *font_dict,
    pdfmake_font_widths_t *out)
{
    uint32_t first_k;
    uint32_t last_k;
    uint32_t widths_k;
    uint32_t fd_k;
    pdfmake_obj_t *fd;
    pdfmake_obj_t *first;
    pdfmake_obj_t *last;
    pdfmake_obj_t *widths;
    int32_t fc;
    int32_t lc;
    size_t n;
    size_t have;
    int16_t *table;
    size_t i;

    pdfmake_font_widths_init(out);
    if (!font_dict || font_dict->kind != PDFMAKE_DICT || !arena) return -1;

    first_k   = pdfmake_arena_intern_name(arena, "FirstChar", 9);
    last_k    = pdfmake_arena_intern_name(arena, "LastChar",  8);
    widths_k  = pdfmake_arena_intern_name(arena, "Widths",    6);
    fd_k      = pdfmake_arena_intern_name(arena, "FontDescriptor", 14);

    /* Always pull descriptor metrics even if /Widths is absent */
    fd = pdfmake_dict_get(font_dict, fd_k);
    if (fd && fd->kind == PDFMAKE_DICT) {
        fill_descriptor_metrics(arena, fd, out);
    }

    first  = pdfmake_dict_get(font_dict, first_k);
    last   = pdfmake_dict_get(font_dict, last_k);
    widths = pdfmake_dict_get(font_dict, widths_k);

    if (!first || !last || !widths) return -1;
    if (widths->kind != PDFMAKE_ARRAY) return -1;

    fc = int32_of(first, -1);
    lc = int32_of(last,  -1);
    if (fc < 0 || lc < fc || fc > 0xFFFF || lc > 0xFFFF) return -1;

    n = (size_t)(lc - fc + 1);
    have = pdfmake_array_len(widths);
    if (have < n) n = have;

    table = pdfmake_arena_alloc(arena, n * sizeof(int16_t));
    if (!table) return -1;

    for (i = 0; i < n; i++) {
        pdfmake_obj_t *w = pdfmake_array_get(widths, i);
        table[i] = int_of(w, 0);
    }

    out->table      = table;
    out->first_char = (uint16_t)fc;
    out->last_char  = (uint16_t)(fc + n - 1);
    return 0;
}

/*============================================================================
 * CID font /W array
 *
 * Two entry formats, mixed freely in one array:
 *   1. first [ w1 w2 w3 ... ]     codes first..first+n-1 have widths wi
 *   2. first last w               codes first..last all have width w
 *==========================================================================*/

static int add_range(pdfmake_arena_t *arena,
                      pdfmake_width_range_t **list, size_t *count, size_t *cap,
                      uint32_t lo, uint32_t hi, int16_t w)
{
    pdfmake_width_range_t *r;
    if (*count >= *cap) {
        size_t new_cap = *cap ? *cap * 2 : 16;
        pdfmake_width_range_t *n = pdfmake_arena_alloc(
            arena, new_cap * sizeof(pdfmake_width_range_t));
        if (!n) return -1;
        if (*list && *count > 0) {
            memcpy(n, *list, *count * sizeof(pdfmake_width_range_t));
        }
        *list = n;
        *cap = new_cap;
    }
    r = &(*list)[(*count)++];
    r->lo = lo;
    r->hi = hi;
    r->width = w;
    return 0;
}

static int range_cmp(const void *a, const void *b) {
    const pdfmake_width_range_t *ra = a;
    const pdfmake_width_range_t *rb = b;
    if (ra->lo < rb->lo) return -1;
    if (ra->lo > rb->lo) return  1;
    return 0;
}

static int parse_w_array(pdfmake_arena_t *arena,
                          pdfmake_obj_t *w_arr,
                          pdfmake_font_widths_t *out)
{
    pdfmake_width_range_t *list;
    size_t count, cap;
    size_t n;
    size_t i;
    if (!w_arr || w_arr->kind != PDFMAKE_ARRAY) return -1;

    list = NULL;
    count = 0; cap = 0;
    n = pdfmake_array_len(w_arr);

    i = 0;
    while (i < n) {
        pdfmake_obj_t *first = pdfmake_array_get(w_arr, i++);
        int32_t fc = int32_of(first, -1);
        pdfmake_obj_t *next;
        if (fc < 0 || i >= n) break;

        next = pdfmake_array_get(w_arr, i);
        if (!next) break;

        if (next->kind == PDFMAKE_ARRAY) {
            /* Format 1: first [ w w w ... ] */
            size_t m = pdfmake_array_len(next);
            size_t j;
            /* Expand as consecutive single-code ranges for uniform lookup.
             * Could compress runs of equal widths, but not worth the complexity. */
            for (j = 0; j < m; j++) {
                int16_t w = int_of(pdfmake_array_get(next, j), 0);
                if (add_range(arena, &list, &count, &cap,
                              (uint32_t)(fc + j), (uint32_t)(fc + j), w) < 0) {
                    return -1;
                }
            }
            i++;
        } else {
            /* Format 2: first last w */
            int32_t lc = int32_of(next, fc);
            int16_t w;
            if (lc < fc) lc = fc;
            if (i + 1 >= n) break;
            w = int_of(pdfmake_array_get(w_arr, i + 1), 0);
            if (add_range(arena, &list, &count, &cap,
                          (uint32_t)fc, (uint32_t)lc, w) < 0) {
                return -1;
            }
            i += 2;
        }
    }

    if (count > 1) qsort(list, count, sizeof(*list), range_cmp);
    out->ranges = list;
    out->range_count = count;
    return 0;
}

int pdfmake_font_widths_from_cid(
    pdfmake_arena_t       *arena,
    pdfmake_obj_t         *font_dict,
    pdfmake_font_widths_t *out)
{
    uint32_t desc_k;
    pdfmake_obj_t *desc_arr;
    pdfmake_obj_t *cidfont = NULL;
    uint32_t w_k;
    uint32_t dw_k;
    uint32_t fd_k;
    pdfmake_obj_t *dw;
    pdfmake_obj_t *fd;
    pdfmake_obj_t *w_arr;

    pdfmake_font_widths_init(out);
    out->default_width = 1000;   /* Per §9.7.4.3: /DW defaults to 1000 */

    if (!font_dict || font_dict->kind != PDFMAKE_DICT || !arena) return -1;

    /* For Type0 fonts, widths live on /DescendantFonts[0] */
    desc_k = pdfmake_arena_intern_name(arena, "DescendantFonts", 15);
    desc_arr = pdfmake_dict_get(font_dict, desc_k);
    if (desc_arr && desc_arr->kind == PDFMAKE_ARRAY && pdfmake_array_len(desc_arr) > 0) {
        cidfont = pdfmake_array_get(desc_arr, 0);
    }
    if (!cidfont) cidfont = font_dict;  /* Might already be the CIDFont */
    if (cidfont->kind != PDFMAKE_DICT) return -1;

    w_k  = pdfmake_arena_intern_name(arena, "W", 1);
    dw_k = pdfmake_arena_intern_name(arena, "DW", 2);
    fd_k = pdfmake_arena_intern_name(arena, "FontDescriptor", 14);

    dw = pdfmake_dict_get(cidfont, dw_k);
    if (dw) out->default_width = int_of(dw, out->default_width);

    fd = pdfmake_dict_get(cidfont, fd_k);
    if (fd && fd->kind == PDFMAKE_DICT) {
        fill_descriptor_metrics(arena, fd, out);
    }

    w_arr = pdfmake_dict_get(cidfont, w_k);
    if (w_arr) parse_w_array(arena, w_arr, out);

    return 0;
}

/*============================================================================
 * Lookup
 *==========================================================================*/

int16_t pdfmake_font_widths_lookup(const pdfmake_font_widths_t *w,
                                    uint32_t code)
{
    if (!w) return 0;

    /* Simple font table */
    if (w->table && code >= w->first_char && code <= w->last_char) {
        int16_t v = w->table[code - w->first_char];
        if (v != 0) return v;
    }

    /* CID range list — binary search */
    if (w->ranges && w->range_count > 0) {
        size_t lo = 0, hi = w->range_count;
        /* Find last range with range.lo <= code */
        while (lo < hi) {
            size_t mid = (lo + hi) / 2;
            if (w->ranges[mid].lo <= code) lo = mid + 1;
            else hi = mid;
        }
        if (lo > 0) {
            const pdfmake_width_range_t *r = &w->ranges[lo - 1];
            if (code >= r->lo && code <= r->hi) return r->width;
        }
    }

    return w->default_width;
}

/*============================================================================
 * Phase 6: Enhance widths from embedded /FontFile2 TTF data.
 *==========================================================================*/

/* Resolve /FontFile2 (or /FontFile3) stream from a font descriptor.
 * Returns the decoded stream bytes (owned by `out_buf`) on success. */
static int fetch_font_file_stream(
    struct pdfmake_reader *reader,
    pdfmake_arena_t       *arena,
    pdfmake_obj_t         *descriptor,
    pdfmake_buf_t         *out_buf)
{
    uint32_t ff2_k;
    uint32_t ff3_k;
    pdfmake_obj_t *ref;
    if (!descriptor || descriptor->kind != PDFMAKE_DICT) return -1;

    ff2_k = pdfmake_arena_intern_name(arena, "FontFile2", 9);
    ff3_k = pdfmake_arena_intern_name(arena, "FontFile3", 9);
    ref = pdfmake_dict_get(descriptor, ff2_k);
    if (!ref) ref = pdfmake_dict_get(descriptor, ff3_k);
    if (!ref || ref->kind != PDFMAKE_REF) return -1;

    return pdfmake_reader_resolve_stream(reader, ref->as.ref.num,
                                          ref->as.ref.gen, out_buf) == PDFMAKE_OK
        ? 0 : -1;
}

/* Parse /CIDToGIDMap. For /Identity (or missing), returns NULL and sets
 * is_identity=1. For a stream, returns a uint16_t[num_cids] array in arena. */
static uint16_t *resolve_cid_to_gid_map(
    pdfmake_arena_t       *arena,
    struct pdfmake_reader *reader,
    pdfmake_obj_t         *cidfont_dict,
    size_t                *out_count,
    int                   *out_is_identity)
{
    uint32_t k;
    pdfmake_obj_t *m;
    pdfmake_buf_t buf;
    size_t count;
    uint16_t *map;
    const uint8_t *d;
    size_t i;

    *out_count = 0;
    *out_is_identity = 0;

    k = pdfmake_arena_intern_name(arena, "CIDToGIDMap", 11);
    m = pdfmake_dict_get(cidfont_dict, k);
    if (!m) { *out_is_identity = 1; return NULL; }

    if (m->kind == PDFMAKE_NAME) {
        /* /Identity is the only named form */
        *out_is_identity = 1;
        return NULL;
    }

    if (m->kind != PDFMAKE_REF) return NULL;

    if (pdfmake_buf_init(&buf) != PDFMAKE_OK) return NULL;
    if (pdfmake_reader_resolve_stream(reader, m->as.ref.num, m->as.ref.gen, &buf)
        != PDFMAKE_OK) {
        pdfmake_buf_free(&buf);
        return NULL;
    }

    /* Stream is a sequence of big-endian 2-byte GIDs indexed by CID */
    count = pdfmake_buf_len(&buf) / 2;
    if (count == 0) { pdfmake_buf_free(&buf); return NULL; }

    map = pdfmake_arena_alloc(arena, count * sizeof(uint16_t));
    if (!map) { pdfmake_buf_free(&buf); return NULL; }

    d = pdfmake_buf_data(&buf);
    for (i = 0; i < count; i++) {
        map[i] = ((uint16_t)d[i * 2] << 8) | d[i * 2 + 1];
    }
    pdfmake_buf_free(&buf);
    *out_count = count;
    return map;
}

int pdfmake_font_widths_enhance_with_ttf(
    pdfmake_arena_t         *arena,
    struct pdfmake_reader   *reader,
    pdfmake_obj_t           *font_dict,
    int                      is_cid,
    const uint32_t          *byte_to_unicode,
    pdfmake_font_widths_t   *out)
{
    pdfmake_obj_t *descriptor_owner;
    uint32_t fd_k;
    pdfmake_obj_t *descriptor;
    pdfmake_buf_t ttf_buf;
    pdfmake_ttf_t *ttf;

    if (!arena || !reader || !font_dict || !out) return -1;

    /* Find the font dict that owns the descriptor. For CID fonts, that's the
     * descendant CIDFont, not the Type0 wrapper. */
    descriptor_owner = font_dict;
    if (is_cid) {
        uint32_t df_k = pdfmake_arena_intern_name(arena, "DescendantFonts", 15);
        pdfmake_obj_t *df_arr = pdfmake_dict_get(font_dict, df_k);
        if (df_arr && df_arr->kind == PDFMAKE_ARRAY &&
            pdfmake_array_len(df_arr) > 0) {
            pdfmake_obj_t *cidfont = pdfmake_array_get(df_arr, 0);
            if (cidfont && cidfont->kind == PDFMAKE_DICT) {
                descriptor_owner = cidfont;
            }
        }
    }

    fd_k = pdfmake_arena_intern_name(arena, "FontDescriptor", 14);
    descriptor = pdfmake_dict_get(descriptor_owner, fd_k);
    if (!descriptor || descriptor->kind != PDFMAKE_DICT) return -1;

    if (pdfmake_buf_init(&ttf_buf) != PDFMAKE_OK) return -1;
    if (fetch_font_file_stream(reader, arena, descriptor, &ttf_buf) != 0) {
        pdfmake_buf_free(&ttf_buf);
        return -1;
    }

    ttf = pdfmake_ttf_parse(arena,
                                            pdfmake_buf_data(&ttf_buf),
                                            pdfmake_buf_len(&ttf_buf));
    /* Note: pdfmake_ttf_parse may reference the input buffer internally.
     * We must keep ttf_buf alive for the lifetime of the TTF object. */
    if (!ttf) {
        pdfmake_buf_free(&ttf_buf);
        return -1;
    }

    /* Pull better ascent/descent from OS/2 if available */
    if (ttf->has_os2 && ttf->units_per_em) {
        out->ascent  = (int16_t)((int32_t)ttf->s_typo_ascender  * 1000 / ttf->units_per_em);
        out->descent = (int16_t)((int32_t)ttf->s_typo_descender * 1000 / ttf->units_per_em);
        if (ttf->s_cap_height)
            out->cap_height = (int16_t)((int32_t)ttf->s_cap_height * 1000 / ttf->units_per_em);
        if (ttf->s_x_height)
            out->x_height = (int16_t)((int32_t)ttf->s_x_height * 1000 / ttf->units_per_em);
    } else if (ttf->units_per_em) {
        out->ascent  = (int16_t)((int32_t)ttf->ascender  * 1000 / ttf->units_per_em);
        out->descent = (int16_t)((int32_t)ttf->descender * 1000 / ttf->units_per_em);
    }

    if (is_cid) {
        /* Build a range list: CID -> advance via /CIDToGIDMap + hmtx.
         * Only populate CIDs that the map actually covers. */
        size_t cid_count = 0;
        int is_identity = 0;
        uint16_t *cidmap;
        size_t new_cap;
        pdfmake_width_range_t *merged;
        size_t out_count;
        size_t cid;

        cidmap = resolve_cid_to_gid_map(arena, reader, descriptor_owner,
                                                   &cid_count, &is_identity);

        /* For Identity mapping, treat GID == CID up to num_glyphs. */
        if (is_identity) {
            cid_count = ttf->num_glyphs;
        }
        if (!is_identity && !cidmap) {
            pdfmake_buf_free(&ttf_buf);
            return 0;   /* metrics updated, widths unchanged */
        }

        /* Append TTF-derived widths to the existing range list, where they
         * fill gaps. For simplicity, emit one range per CID — the lookup
         * code binary-searches so O(log n) either way.
         *
         * Skip CIDs already covered by the PDF's /W array (PDF values win). */
        new_cap = out->range_count + cid_count;
        merged = pdfmake_arena_alloc(
            arena, new_cap * sizeof(*merged));
        if (!merged) { pdfmake_buf_free(&ttf_buf); return 0; }

        if (out->ranges && out->range_count)
            memcpy(merged, out->ranges, out->range_count * sizeof(*merged));
        out_count = out->range_count;

        for (cid = 0; cid < cid_count; cid++) {
            uint16_t gid = is_identity ? (uint16_t)cid : cidmap[cid];
            uint16_t w;
            int covered;
            size_t j;
            if (gid == 0) continue;
            w = pdfmake_ttf_glyph_advance(ttf, gid);
            if (w == 0) continue;

            /* Check if CID is already in existing ranges */
            covered = 0;
            for (j = 0; j < out->range_count; j++) {
                if (cid >= out->ranges[j].lo && cid <= out->ranges[j].hi) {
                    covered = 1;
                    break;
                }
            }
            if (covered) continue;

            merged[out_count].lo = (uint32_t)cid;
            merged[out_count].hi = (uint32_t)cid;
            merged[out_count].width = (int16_t)w;
            out_count++;
        }

        /* Sort merged ranges for binary search */
        if (out_count > 1) {
            qsort(merged, out_count, sizeof(*merged), range_cmp);
        }
        out->ranges = merged;
        out->range_count = out_count;
    } else {
        /* Simple font: populate a 256-entry table indexed by byte code.
         * charcode -> Unicode (from /Encoding) -> GID (from TTF cmap)
         *         -> advance (from hmtx)
         *
         * Only overwrite entries that are currently 0 (unset by /Widths) —
         * PDF's declared /Widths array takes precedence. */
        int16_t *table;
        uint16_t first;
        uint16_t last;
        size_t tbl_len;
        int code;
        if (!byte_to_unicode) {
            pdfmake_buf_free(&ttf_buf);
            return 0;
        }

        table = out->table;
        first = out->first_char;
        last  = out->last_char;
        tbl_len = table ? (size_t)(last - first + 1) : 0;

        /* If no existing table, allocate full 256-entry one */
        if (!table) {
            table = pdfmake_arena_alloc(arena, 256 * sizeof(int16_t));
            if (!table) { pdfmake_buf_free(&ttf_buf); return 0; }
            memset(table, 0, 256 * sizeof(int16_t));
            first = 0;
            last  = 255;
            tbl_len = 256;
        } else if (first > 0 || last < 255) {
            /* Expand to full 256-entry so we can cover the full byte range */
            int16_t *expanded = pdfmake_arena_alloc(arena, 256 * sizeof(int16_t));
            size_t i;
            if (!expanded) { pdfmake_buf_free(&ttf_buf); return 0; }
            memset(expanded, 0, 256 * sizeof(int16_t));
            for (i = 0; i < tbl_len; i++)
                expanded[first + i] = table[i];
            table = expanded;
            first = 0;
            last  = 255;
            tbl_len = 256;
        }

        /* Fill gaps from TTF */
        for (code = 0; code < 256; code++) {
            uint32_t uni;
            uint16_t gid;
            uint16_t w;
            if (table[code] != 0) continue;       /* honour PDF /Widths */
            uni = byte_to_unicode[code];
            if (uni == 0) continue;
            gid = pdfmake_ttf_cmap_lookup(ttf, uni);
            if (gid == 0) continue;
            w = pdfmake_ttf_glyph_advance(ttf, gid);
            if (w == 0) continue;
            table[code] = (int16_t)w;
        }

        out->table = table;
        out->first_char = first;
        out->last_char  = last;
    }

    /* NB: ttf_buf backs the ttf->data pointer. Keeping it leaked-into-arena
     * isn't possible (buf uses malloc), but the TTF parse copied nothing.
     * For the simple font path we've already consumed all data via lookups,
     * so freeing here is safe.
     *
     * Actually: pdfmake_ttf_cmap_lookup walks ttf->data, so for the CID path
     * we might have read partial data if lookups happen after this function
     * returns. We therefore arena-copy the buffer first.
     *
     * Currently all TTF reads happen inside this function, so freeing is
     * safe. If that changes, hoist the memcpy-to-arena into parse above. */
    pdfmake_buf_free(&ttf_buf);
    return 0;
}
