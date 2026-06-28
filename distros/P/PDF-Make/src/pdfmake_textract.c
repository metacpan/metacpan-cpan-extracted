/*
 * pdfmake_textract.c — Text extraction with coordinates.
 *
 * Pipeline: interpreter → visitor → raw glyphs → words → lines → blocks
 *
 * §9.4 Text objects, §9.10 Extraction of text content
 */

#include "pdfmake_textract.h"
#include "pdfmake_font.h"
#include "pdfmake_interpreter.h"
#include "pdfmake_cmap.h"
#include "pdfmake_reader.h"
#include "pdfmake_parser.h"
#include "pdfmake_buf.h"
#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <math.h>

/*============================================================================
 * WinAnsi encoding → Unicode mapping (§D.1)
 *==========================================================================*/

/* Bytes 0x00–0x7F map to U+0000–U+007F (ASCII).
 * Bytes 0x80–0x9F have special mappings.
 * Bytes 0xA0–0xFF map to U+00A0–U+00FF (Latin-1 supplement).
 */
static const uint32_t winansi_0x80[32] = {
    0x20AC, /* 0x80: Euro sign */
    0xFFFD, /* 0x81: undefined */
    0x201A, /* 0x82: single low-9 quotation mark */
    0x0192, /* 0x83: latin small f with hook */
    0x201E, /* 0x84: double low-9 quotation mark */
    0x2026, /* 0x85: horizontal ellipsis */
    0x2020, /* 0x86: dagger */
    0x2021, /* 0x87: double dagger */
    0x02C6, /* 0x88: modifier letter circumflex accent */
    0x2030, /* 0x89: per mille sign */
    0x0160, /* 0x8A: latin capital S with caron */
    0x2039, /* 0x8B: single left-pointing angle quotation */
    0x0152, /* 0x8C: latin capital ligature OE */
    0xFFFD, /* 0x8D: undefined */
    0x017D, /* 0x8E: latin capital Z with caron */
    0xFFFD, /* 0x8F: undefined */
    0xFFFD, /* 0x90: undefined */
    0x2018, /* 0x91: left single quotation mark */
    0x2019, /* 0x92: right single quotation mark */
    0x201C, /* 0x93: left double quotation mark */
    0x201D, /* 0x94: right double quotation mark */
    0x2022, /* 0x95: bullet */
    0x2013, /* 0x96: en dash */
    0x2014, /* 0x97: em dash */
    0x02DC, /* 0x98: small tilde */
    0x2122, /* 0x99: trade mark sign */
    0x0161, /* 0x9A: latin small s with caron */
    0x203A, /* 0x9B: single right-pointing angle quotation */
    0x0153, /* 0x9C: latin small ligature oe */
    0xFFFD, /* 0x9D: undefined */
    0x017E, /* 0x9E: latin small z with caron */
    0x0178, /* 0x9F: latin capital Y with diaeresis */
};

uint32_t pdfmake_winansi_to_unicode(uint8_t byte) {
    if (byte < 0x80) return (uint32_t)byte;
    if (byte < 0xA0) return winansi_0x80[byte - 0x80];
    return (uint32_t)byte; /* 0xA0–0xFF: same as Unicode */
}

/*============================================================================
 * Result management
 *==========================================================================*/

pdfmake_textract_options_t pdfmake_textract_default_options(void) {
    pdfmake_textract_options_t opts;
    opts.word_gap_factor = 0.3;
    opts.line_tolerance = 0.5;
    opts.block_leading = 1.5;
    opts.include_invisible = 1;
    return opts;
}

pdfmake_textract_result_t *pdfmake_textract_new(pdfmake_arena_t *arena) {
    pdfmake_textract_result_t *r = calloc(1, sizeof(*r));
    if (r) {
        r->arena = arena;
        r->include_invisible = 1;    /* default: include OCR text */
        r->current_mcid = -1;        /* Phase 12: no active MCID */
    }
    return r;
}

static void free_words(pdfmake_text_word_t *words, size_t len) {
    size_t i;
    for (i = 0; i < len; i++) {
        free(words[i].glyphs);
    }
    free(words);
}

static void free_lines(pdfmake_text_line_t *lines, size_t len) {
    size_t i;
    for (i = 0; i < len; i++) {
        free_words(lines[i].words, lines[i].len);
    }
    free(lines);
}

void pdfmake_textract_free(pdfmake_textract_result_t *result) {
    size_t i;
    if (!result) return;
    for (i = 0; i < result->len; i++) {
        free_lines(result->blocks[i].lines, result->blocks[i].len);
    }
    free(result->blocks);
    free(result->raw_glyphs);
    free(result->font_cache);
    free(result->struct_map);
    free(result);
}

void pdfmake_textract_set_reader(pdfmake_textract_result_t *result,
                                  struct pdfmake_reader *reader) {
    if (!result) return;
    result->reader = reader;
}

/*============================================================================
 * Font resolution cache
 *
 * Lazily resolves per-font metadata (ToUnicode CMap, Type0/CID flag, Std14 ID)
 * on first use. Subsequent glyphs from the same font dict hit the cache.
 *==========================================================================*/

static pdfmake_resolved_font_t *font_cache_find(
    pdfmake_textract_result_t *r, pdfmake_obj_t *font_dict)
{
    size_t i;
    for (i = 0; i < r->font_cache_len; i++) {
        if (r->font_cache[i].font_dict == font_dict) return &r->font_cache[i];
    }
    return NULL;
}

static pdfmake_resolved_font_t *font_cache_add(
    pdfmake_textract_result_t *r, pdfmake_obj_t *font_dict)
{
    pdfmake_resolved_font_t *slot;
    if (r->font_cache_len >= r->font_cache_cap) {
        size_t new_cap = r->font_cache_cap == 0 ? 4 : r->font_cache_cap * 2;
        pdfmake_resolved_font_t *n = realloc(
            r->font_cache, new_cap * sizeof(*n));
        if (!n) return NULL;
        r->font_cache = n;
        r->font_cache_cap = new_cap;
    }
    slot = &r->font_cache[r->font_cache_len++];
    memset(slot, 0, sizeof(*slot));
    slot->font_dict = font_dict;
    slot->std14_id = -1;
    return slot;
}

/* Resolve the ToUnicode CMap for a font dict. Returns NULL if not present
 * or if resolution fails. Caches the result (including NULL) per-font. */
static pdfmake_cmap_t *resolve_to_unicode(pdfmake_textract_result_t *r,
                                           pdfmake_resolved_font_t *rf)
{
    uint32_t key;
    pdfmake_obj_t *tu;
    pdfmake_buf_t buf;
    pdfmake_err_t err;
    if (rf->to_unicode_tried) return rf->to_unicode;
    rf->to_unicode_tried = 1;

    if (!r->reader || !rf->font_dict || !r->arena) return NULL;

    key = pdfmake_arena_intern_name(r->arena, "ToUnicode", 9);
    tu = pdfmake_dict_get(rf->font_dict, key);
    if (!tu || tu->kind != PDFMAKE_REF) return NULL;

    pdfmake_buf_init(&buf);
    err = pdfmake_reader_resolve_stream(
        r->reader, tu->as.ref.num, tu->as.ref.gen, &buf);
    if (err != PDFMAKE_OK || buf.len == 0) {
        pdfmake_buf_free(&buf);
        return NULL;
    }

    rf->to_unicode = pdfmake_cmap_parse(r->arena, buf.data, buf.len);
    pdfmake_buf_free(&buf);
    return rf->to_unicode;
}

/* Resolve /Widths or /W for the font, plus font descriptor metrics. */
static void resolve_widths(pdfmake_textract_result_t *r,
                            pdfmake_resolved_font_t *rf)
{
    if (rf->widths_resolved) return;
    rf->widths_resolved = 1;

    if (!rf->font_dict || !r->arena) {
        pdfmake_font_widths_init(&rf->widths);
        return;
    }

    if (rf->is_cid) {
        pdfmake_font_widths_from_cid(r->arena, rf->font_dict, &rf->widths);
    } else {
        pdfmake_font_widths_from_simple(r->arena, rf->font_dict, &rf->widths);
    }

    /* Phase 6: overlay with TTF metrics from /FontFile2 if present.
     * For simple fonts this requires the resolved /Encoding first; callers
     * arrange the sequence in resolve_font(). */
    if (r->reader) {
        const uint32_t *byte_to_uni = NULL;
        if (!rf->is_cid && rf->encoding_resolved) {
            byte_to_uni = rf->encoding.map;
        }
        pdfmake_font_widths_enhance_with_ttf(
            r->arena,
            (struct pdfmake_reader *)r->reader,
            rf->font_dict,
            rf->is_cid,
            byte_to_uni,
            &rf->widths);
    }
}

/* Resolve the /Encoding entry for a simple font. Populates rf->encoding.
 * Std14 fonts without an explicit /Encoding default to WinAnsi in practice;
 * other Type1 fonts default to StandardEncoding. */
static void resolve_encoding(pdfmake_textract_result_t *r,
                              pdfmake_resolved_font_t *rf)
{
    uint32_t enc_key;
    pdfmake_obj_t *enc_obj;
    pdfmake_obj_t *resolved;
    const pdfmake_std14_data_t *d;
    if (rf->encoding_resolved) return;
    rf->encoding_resolved = 1;

    if (!rf->font_dict || !r->arena) {
        pdfmake_font_encoding_init_winansi(&rf->encoding);
        return;
    }

    enc_key = pdfmake_arena_intern_name(r->arena, "Encoding", 8);
    enc_obj = pdfmake_dict_get(rf->font_dict, enc_key);

    /* Resolve indirect reference if needed */
    if (enc_obj && enc_obj->kind == PDFMAKE_REF && r->reader) {
        /* We need to resolve the ref through the parser; expose a tiny helper */
        /* For now, the parser returns the concrete obj via the reader's parser */
        resolved = pdfmake_parser_resolve(
            ((pdfmake_reader_t *)r->reader)->parser, enc_obj->as.ref);
        if (resolved) enc_obj = resolved;
    }

    if (enc_obj) {
        pdfmake_font_encoding_from_dict(r->arena, enc_obj, &rf->encoding);
    } else {
        /* No /Encoding: pick a sane default based on Std14 kind */
        if (rf->std14_id >= 0) {
            /* Symbol and ZapfDingbats have their own encoding */
            d = pdfmake_std14_get((pdfmake_std14_id_t)rf->std14_id);
            if (d && d->name) {
                if (strcmp(d->name, "Symbol") == 0)
                    pdfmake_font_encoding_init_symbol(&rf->encoding);
                else if (strcmp(d->name, "ZapfDingbats") == 0)
                    pdfmake_font_encoding_init_zapfdingbats(&rf->encoding);
                else
                    pdfmake_font_encoding_init_standard(&rf->encoding);
            } else {
                pdfmake_font_encoding_init_standard(&rf->encoding);
            }
        } else {
            /* Non-Std14 with no /Encoding: StandardEncoding per §9.6.5 */
            pdfmake_font_encoding_init_standard(&rf->encoding);
        }
    }
}

/* If `obj` is an indirect reference, resolve it through the reader's
 * parser; otherwise return it unchanged. Returns NULL only when an
 * attempted resolve failed — direct NULL/DICT/etc. inputs pass through. */
static PDFMAKE_INLINE pdfmake_obj_t *
textract_follow_ref(pdfmake_textract_result_t *r, pdfmake_obj_t *obj)
{
    if (obj && obj->kind == PDFMAKE_REF && r->reader) {
        pdfmake_reader_t *rd = (pdfmake_reader_t *)r->reader;
        if (rd->parser) return pdfmake_parser_resolve(rd->parser, obj->as.ref);
    }
    return obj;
}

/* For Type0/CID fonts, derive writing mode and default vertical advance:
 *   - /Encoding: name ending in "-V" → vertical; a CMap stream with
 *     /WMode 1 overrides (§9.7.5.2).
 *   - When vertical, /DescendantFonts[0]/DW2 = [v_origin_y v_advance]
 *     replaces the -1000 spec default for default_v_advance. */
static void
resolve_cid_font_modes(pdfmake_textract_result_t *r,
                       pdfmake_obj_t *font_dict,
                       pdfmake_resolved_font_t *rf)
{
    uint32_t enc_key;
    pdfmake_obj_t *enc;
    const char *nm;
    size_t ln;
    pdfmake_dict_t *sd;
    pdfmake_obj_t sd_obj;
    uint32_t wm_key;
    pdfmake_obj_t *wm;
    uint32_t df_key;
    pdfmake_obj_t *df;
    pdfmake_obj_t *desc;
    uint32_t dw2_key;
    pdfmake_obj_t *dw2;
    pdfmake_obj_t *a;

    enc_key = pdfmake_arena_intern_name(r->arena, "Encoding", 8);
    enc = textract_follow_ref(r, pdfmake_dict_get(font_dict, enc_key));

    if (enc && enc->kind == PDFMAKE_NAME) {
        nm = pdfmake_get_name_bytes(r->arena, enc);
        ln = nm ? strlen(nm) : 0;
        if (ln >= 2 && nm[ln - 2] == '-' &&
            (nm[ln - 1] == 'V' || nm[ln - 1] == 'v')) {
            rf->wmode = 1;
        }
    } else if (enc && enc->kind == PDFMAKE_STREAM) {
        sd = pdfmake_stream_dict(enc);
        if (sd) {
            sd_obj.kind = PDFMAKE_DICT;
            sd_obj.as.dict = sd;
            wm_key = pdfmake_arena_intern_name(r->arena, "WMode", 5);
            wm = pdfmake_dict_get(&sd_obj, wm_key);
            if (wm && wm->kind == PDFMAKE_INT && wm->as.i == 1) rf->wmode = 1;
        }
    }
    if (!rf->wmode) return;

    df_key = pdfmake_arena_intern_name(r->arena, "DescendantFonts", 15);
    df = textract_follow_ref(r, pdfmake_dict_get(font_dict, df_key));
    if (!df || df->kind != PDFMAKE_ARRAY || pdfmake_array_len(df) == 0) return;

    desc = textract_follow_ref(r, pdfmake_array_get(df, 0));
    if (!desc || desc->kind != PDFMAKE_DICT) return;

    dw2_key = pdfmake_arena_intern_name(r->arena, "DW2", 3);
    dw2 = pdfmake_dict_get(desc, dw2_key);
    if (dw2 && dw2->kind == PDFMAKE_ARRAY && pdfmake_array_len(dw2) >= 2) {
        a = pdfmake_array_get(dw2, 1);
        if (a) rf->default_v_advance = (int16_t)pdfmake_get_number(a);
    }
}

/* Resolve the font dict into a cached resolved_font. NULL if dict is NULL. */
static pdfmake_resolved_font_t *resolve_font(
    pdfmake_textract_result_t *r, pdfmake_obj_t *font_dict)
{
    pdfmake_resolved_font_t *rf;
    uint32_t bf_key;
    pdfmake_obj_t *bf;
    const char *name;
    uint32_t sub_key;
    pdfmake_obj_t *sub;
    const char *st;
    if (!font_dict || !r->arena) return NULL;

    /* Follow indirect references — resources often hold refs, not inline dicts */
    font_dict = textract_follow_ref(r, font_dict);
    if (!font_dict || font_dict->kind != PDFMAKE_DICT) return NULL;

    rf = font_cache_find(r, font_dict);
    if (rf) return rf;
    rf = font_cache_add(r, font_dict);
    if (!rf) return NULL;

    /* Std14 lookup */
    bf_key = pdfmake_arena_intern_name(r->arena, "BaseFont", 8);
    bf = pdfmake_dict_get(font_dict, bf_key);
    if (bf && bf->kind == PDFMAKE_NAME) {
        name = pdfmake_get_name_bytes(r->arena, bf);
        if (name) rf->std14_id = pdfmake_std14_lookup(name);
    }

    /* Type0/CID detection */
    sub_key = pdfmake_arena_intern_name(r->arena, "Subtype", 7);
    sub = pdfmake_dict_get(font_dict, sub_key);
    if (sub && sub->kind == PDFMAKE_NAME) {
        st = pdfmake_get_name_bytes(r->arena, sub);
        if (st && strcmp(st, "Type0") == 0) rf->is_cid = 1;
    }

    /* Phase 14: writing mode + default vertical advance (Type0 only). */
    rf->wmode = 0;
    rf->default_v_advance = -1000;  /* spec default for vertical */
    if (rf->is_cid) resolve_cid_font_modes(r, font_dict, rf);

    /* Resolve /Encoding for simple fonts only; CID fonts use ToUnicode */
    if (!rf->is_cid) resolve_encoding(r, rf);

    /* Resolve widths + descriptor metrics for all non-Std14 fonts */
    if (rf->std14_id < 0) resolve_widths(r, rf);

    return rf;
}

/*============================================================================
 * Raw glyph collection
 *==========================================================================*/

static int result_push_glyph(pdfmake_textract_result_t *r,
                              const pdfmake_text_glyph_t *g) {
    if (r->raw_len >= r->raw_cap) {
        size_t new_cap = r->raw_cap == 0 ? 64 : r->raw_cap * 2;
        pdfmake_text_glyph_t *new_arr = realloc(r->raw_glyphs,
            new_cap * sizeof(pdfmake_text_glyph_t));
        if (!new_arr) return 0;
        r->raw_glyphs = new_arr;
        r->raw_cap = new_cap;
    }
    r->raw_glyphs[r->raw_len++] = *g;
    return 1;
}

/*============================================================================
 * Visitor: on_text_show callback
 *
 * Called for each Tj/TJ/' /" operator. Decodes bytes, computes glyph
 * positions in user space, emits raw glyphs.
 *==========================================================================*/

/* Legacy: resolve the Standard 14 font ID from the graphics state font dict.
 * Superseded by resolve_font() + font cache. Kept for potential reuse. */
__attribute__((unused))
static int resolve_std14(const pdfmake_gstate_t *gs, pdfmake_arena_t *arena) {
    uint32_t basefont_key;
    pdfmake_obj_t *basefont;
    const char *name;
    if (!gs->font || !arena) return -1;
    if (gs->font->kind != PDFMAKE_DICT) return -1;

    /* Look up /BaseFont in the font dictionary */
    basefont_key = pdfmake_arena_intern_name(arena, "BaseFont", 8);
    basefont = pdfmake_dict_get(gs->font, basefont_key);
    if (!basefont || basefont->kind != PDFMAKE_NAME) return -1;

    name = pdfmake_get_name_bytes(arena, basefont);
    if (!name) return -1;

    return pdfmake_std14_lookup(name);
}

/* Horizontal + vertical advance for a glyph, plus a reliability flag that
 * feeds the downstream word-boundary heuristic. */
typedef struct {
    double horizontal;  /* x-advance in text space (Tj/TJ direction) */
    double vertical;    /* y-advance magnitude for vertical writing */
    int    reliable;    /* 1 iff horizontal came from real font metrics */
} textract_advance_t;

/* Map one character code to its Unicode codepoint(s). Returns the count
 * (always ≥ 1). Ligature-style ToUnicode mappings may yield several
 * codepoints (e.g. "ﬁ" → U+0066 U+0069); uni_list must hold at least
 * PDFMAKE_CMAP_MAX_UNI entries. On failure we emit U+FFFD. */
static PDFMAKE_INLINE size_t
textract_code_to_unicode(const pdfmake_resolved_font_t *rf,
                         pdfmake_cmap_t *to_uni,
                         int is_cid, uint32_t code,
                         uint32_t *uni_list)
{
    if (to_uni) {
        size_t cnt = 0;
        if (pdfmake_cmap_lookup(to_uni, code, uni_list, &cnt) && cnt > 0) {
            return cnt;
        }
        uni_list[0] = 0xFFFD;
        return 1;
    }
    if (!is_cid && rf && rf->encoding_resolved) {
        uint32_t cp = rf->encoding.map[code & 0xFF];
        uni_list[0] = cp ? cp : 0xFFFD;
        return 1;
    }
    if (!is_cid) {
        uni_list[0] = pdfmake_winansi_to_unicode((uint8_t)code);
        return 1;
    }
    /* CID fallback: use the raw code. */
    uni_list[0] = code;
    return 1;
}

/* Compute the glyph advance (both horizontal and vertical) in text-space
 * units, trying /Widths first, then Std14 AFM, then a 0.5-em / 0.25-em
 * placeholder. Vertical advance prefers the font's default_v_advance
 * (CIDFont DW2) when available. */
static PDFMAKE_INLINE textract_advance_t
textract_glyph_advance(const pdfmake_resolved_font_t *rf,
                       int std14_id, int is_cid,
                       uint32_t code, uint32_t unicode,
                       double font_size)
{
    textract_advance_t adv = { 0.0, 0.0, 0 };

    int16_t w1000 = 0;
    if (rf && rf->widths_resolved) {
        w1000 = pdfmake_font_widths_lookup(&rf->widths, code);
    }
    if (w1000 > 0) {
        adv.horizontal = (double)w1000 / 1000.0 * font_size;
        adv.reliable = 1;
    } else if (std14_id >= 0 && !is_cid) {
        int w = pdfmake_std14_width((pdfmake_std14_id_t)std14_id, unicode);
        if (w > 0) {
            adv.horizontal = (double)w / 1000.0 * font_size;
            adv.reliable = 1;
        } else {
            adv.horizontal = 0.25 * font_size;
        }
    } else {
        adv.horizontal = 0.5 * font_size;
    }

    /* Default vertical advance falls back to horizontal magnitude. CJK
     * fonts with DW2/W2 override this via rf->default_v_advance (negative
     * because vertical flow is downward in text space). */
    adv.vertical = adv.horizontal;
    if (rf) {
        double mag = (double)(rf->default_v_advance < 0
            ? -rf->default_v_advance : rf->default_v_advance);
        if (mag > 0) adv.vertical = mag / 1000.0 * font_size;
    }
    return adv;
}

/* Transform a text-space point through the text matrix and CTM to final
 * user/device coordinates. */
static PDFMAKE_INLINE void
textract_text_to_device(const double *tm, const double *ctm,
                        double gx, double gy, double *fx, double *fy)
{
    double ux = tm[0] * gx + tm[2] * gy + tm[4];
    double uy = tm[1] * gx + tm[3] * gy + tm[5];
    *fx = ctm[0] * ux + ctm[2] * uy + ctm[4];
    *fy = ctm[1] * ux + ctm[3] * uy + ctm[5];
}

static void textract_on_text_show(void *ctx,
                                   const pdfmake_gstate_t *gs,
                                   const uint8_t *bytes,
                                   size_t len)
{
    pdfmake_textract_result_t *result = (pdfmake_textract_result_t *)ctx;
    double font_size;
    double char_space;
    double word_space;
    double h_scale;
    double rise;
    pdfmake_resolved_font_t *rf;
    int std14_id;
    int is_cid;
    int is_vertical;
    pdfmake_cmap_t *to_uni;
    double ascent_ratio;
    double descent_ratio;
    const pdfmake_std14_data_t *data;
    double sx;
    double sy;
    double effective_size;
    double ascent;
    double descent;
    double accum_x;
    size_t pos;
    uint32_t code;
    size_t code_width;
    uint32_t uni_list[PDFMAKE_CMAP_MAX_UNI];
    size_t uni_list_n;
    uint32_t unicode;
    textract_advance_t glyph_adv;
    double gx;
    double gy;
    double fx;
    double fy;
    double adv;
    double sub_adv;
    pdfmake_text_glyph_t g;
    double ws;
    size_t k;
    if (!gs || !bytes || len == 0) return;

    /* Phase 11: skip invisible text (Tr=3) when the caller opted out.
     * The interpreter still advances text_matrix via get_string_advance,
     * so positioning of subsequent visible glyphs stays correct. */
    if (!result->include_invisible &&
        gs->render_mode == PDFMAKE_RENDER_INVISIBLE) {
        return;
    }

    font_size = gs->font_size;
    char_space = gs->char_space;
    word_space = gs->word_space;
    h_scale = gs->h_scale / 100.0; /* Tz is percentage */
    rise = gs->rise;

    /* Resolve the font (cached per-font dict) */
    rf = resolve_font(result, gs->font);
    std14_id = rf ? rf->std14_id : -1;
    is_cid = rf ? rf->is_cid : 0;
    is_vertical = rf ? rf->wmode : 0;  /* Phase 14 */
    to_uni = rf ? resolve_to_unicode(result, rf) : NULL;

    /* Font metrics for ascent/descent.
     * Priority: Std14 AFM data → /FontDescriptor → 0.8/-0.2 fallback. */
    ascent_ratio = 0.8;
    descent_ratio = -0.2;
    if (std14_id >= 0) {
        data = pdfmake_std14_get((pdfmake_std14_id_t)std14_id);
        if (data) {
            ascent_ratio = data->metrics.ascent / 1000.0;
            descent_ratio = data->metrics.descent / 1000.0;
        }
    } else if (rf && rf->widths_resolved) {
        if (rf->widths.ascent)  ascent_ratio  = rf->widths.ascent  / 1000.0;
        if (rf->widths.descent) descent_ratio = rf->widths.descent / 1000.0;
    }
    /* Effective font sizes in user space (account for text matrix scaling).
     * sx scales horizontally (advances); sy scales vertically (ascent/descent). */
    sx = sqrt(gs->text_matrix[0] * gs->text_matrix[0] +
                     gs->text_matrix[1] * gs->text_matrix[1]);
    sy = sqrt(gs->text_matrix[2] * gs->text_matrix[2] +
                     gs->text_matrix[3] * gs->text_matrix[3]);
    if (sy == 0) sy = sx;
    effective_size = font_size * sx;
    ascent  = ascent_ratio  * font_size * sy;
    descent = descent_ratio * font_size * sy;

    /* Accumulated displacement through the string.  For horizontal text
     * (WMode 0) this is the x-offset in text space; for vertical text
     * (WMode 1) it's the y-offset (negative because glyphs flow downward). */
    accum_x = 0.0;  /* reused for both axes, name kept for symmetry */

    pos = 0;
    while (pos < len) {
        /* Extract the character code (1 or 2 bytes depending on font type).
         * CID fonts are 2-byte by default; simple fonts are 1-byte. */
        if (is_cid && pos + 1 < len) {
            code = ((uint32_t)bytes[pos] << 8) | bytes[pos + 1];
            code_width = 2;
        } else {
            code = bytes[pos];
            code_width = 1;
        }

        /* Phase 9: ligature-style mappings may yield multiple codepoints
         * for a single glyph; emit one sub-glyph per codepoint, sharing
         * the glyph's bounding box (advance split uniformly). */
        uni_list_n = textract_code_to_unicode(rf, to_uni, is_cid, code, uni_list);
        unicode = uni_list[0];

        glyph_adv = textract_glyph_advance(
            rf, std14_id, is_cid, code, unicode, font_size);

        pos += code_width;

        /* Glyph origin in text space — for horizontal writing the pen
         * travels along +x; for vertical writing it travels along -y.
         * `rise` still adjusts the cross axis. */
        gx = is_vertical ? rise    : accum_x;
        gy = is_vertical ? accum_x : rise;

        textract_text_to_device(gs->text_matrix, gs->ctm, gx, gy, &fx, &fy);

        /* Bounding box — for horizontal, extent runs along x; for vertical
         * it runs along -y (each glyph sits below the previous one). */
        adv = (is_vertical ? glyph_adv.vertical : glyph_adv.horizontal) * sx * h_scale;

        /* Phase 9: emit one glyph per decoded codepoint. */
        sub_adv = (uni_list_n > 0) ? adv / (double)uni_list_n : adv;
        for (k = 0; k < uni_list_n; k++) {
            g.unicode = uni_list[k];
            if (is_vertical) {
                /* Vertical: each sub-glyph occupies a horizontal strip whose
                 * height is sub_adv and width is effective_size (1 em). */
                double top    = fy - sub_adv * (double)k;
                double bottom = fy - sub_adv * (double)(k + 1);
                g.x0 = fx - effective_size * 0.5;
                g.x1 = fx + effective_size * 0.5;
                g.y0 = bottom;
                g.y1 = top;
            } else {
                g.x0 = fx + sub_adv * (double)k;
                g.y0 = fy + descent;
                g.x1 = fx + sub_adv * (double)(k + 1);
                g.y1 = fy + ascent;
            }
            g.advance = sub_adv;
            g.font_size = effective_size;
            g.reliable_advance = (uint8_t)glyph_adv.reliable;
            g.mcid = result->current_mcid;  /* Phase 12 */
            g.vertical = (uint8_t)is_vertical;  /* Phase 14 */

            if (!result_push_glyph(result, &g)) break;
        }

        /* Advance text position: §9.4.4. Horizontal moves along +x by the
         * glyph's horizontal advance; vertical moves along -y by the
         * vertical advance. Word-spacing only triggers on a space. */
        ws = (unicode == 0x20) ? word_space : 0.0;
        if (is_vertical) {
            accum_x -= (glyph_adv.vertical + char_space + ws) * h_scale;
        } else {
            accum_x += (glyph_adv.horizontal + char_space + ws) * h_scale;
        }
    }
}

/* Phase 8: compute the real text-space advance for a string so the
 * interpreter can keep text_matrix in sync with our glyph positions.
 * Mirrors the advance logic from textract_on_text_show. */
static double textract_get_string_advance(void *ctx,
                                           const pdfmake_gstate_t *gs,
                                           const uint8_t *bytes, size_t len)
{
    pdfmake_textract_result_t *result = (pdfmake_textract_result_t *)ctx;
    pdfmake_resolved_font_t *rf;
    int std14_id;
    int is_cid;
    int is_vertical;
    double font_size;
    double char_space;
    double word_space;
    double accum;
    size_t pos;
    uint32_t code;
    size_t code_w;
    int16_t w1000;
    double glyph_advance;
    uint32_t uni;
    int w;
    double mag;
    int is_space;
    double ws;
    if (!gs || !bytes || len == 0) return 0;

    rf = resolve_font(result, gs->font);
    std14_id = rf ? rf->std14_id : -1;
    is_cid = rf ? rf->is_cid : 0;
    is_vertical = rf ? rf->wmode : 0;
    font_size = gs->font_size;
    char_space = gs->char_space;
    word_space = gs->word_space;

    accum = 0;
    pos = 0;
    while (pos < len) {
        if (is_cid && pos + 1 < len) {
            code = ((uint32_t)bytes[pos] << 8) | bytes[pos + 1];
            code_w = 2;
        } else {
            code = bytes[pos];
            code_w = 1;
        }

        /* Lookup advance in 1/1000 em, same priority order as on_text_show */
        w1000 = 0;
        if (rf && rf->widths_resolved) {
            w1000 = pdfmake_font_widths_lookup(&rf->widths, code);
        }
        if (w1000 > 0) {
            glyph_advance = (double)w1000 / 1000.0 * font_size;
        } else if (std14_id >= 0 && !is_cid) {
            /* Resolve unicode via encoding for the Std14 lookup */
            uni = rf && rf->encoding_resolved
                         ? rf->encoding.map[code & 0xFF]
                         : (uint32_t)code;
            w = pdfmake_std14_width((pdfmake_std14_id_t)std14_id, uni);
            glyph_advance = (w > 0) ? (double)w / 1000.0 * font_size
                                    : 0.25 * font_size;
        } else {
            glyph_advance = 0.5 * font_size;
        }

        /* In vertical mode use the magnitude of /DW2 second element as the
         * advance; the sign is absorbed by the text-matrix branch in the
         * interpreter, which treats the returned value as a signed
         * displacement along -y. */
        if (is_vertical && rf) {
            mag = (double)(rf->default_v_advance < 0
                ? -rf->default_v_advance : rf->default_v_advance);
            if (mag > 0) glyph_advance = mag / 1000.0 * font_size;
        }

        /* Add spacing contributions (matches on_text_show) */
        is_space = (code == 0x20);
        ws = is_space ? word_space : 0.0;
        accum += glyph_advance + char_space + ws;

        pos += code_w;
    }
    return accum;
}

/* Phase 12: BDC / BMC — push the current MCID on entry to a marked-content
 * item. MCID comes from the /MCID integer in the properties dict (if any).
 * BMC has no properties dict so it never carries an MCID. */
static void textract_on_mc_begin(void *ctx,
                                  const pdfmake_gstate_t *gs,
                                  uint32_t tag,
                                  pdfmake_obj_t *properties)
{
    pdfmake_textract_result_t *result = (pdfmake_textract_result_t *)ctx;
    int32_t mcid = -1;
    (void)gs;
    (void)tag;
    if (!result) return;

    if (properties && properties->kind == PDFMAKE_DICT && result->arena) {
        uint32_t mcid_key = pdfmake_arena_intern_name(result->arena, "MCID", 4);
        pdfmake_obj_t *v = pdfmake_dict_get(properties, mcid_key);
        if (v && v->kind == PDFMAKE_INT) {
            mcid = (int32_t)v->as.i;
        }
    }

    if (result->mcid_depth <
        (int)(sizeof(result->mcid_stack)/sizeof(result->mcid_stack[0]))) {
        result->mcid_stack[result->mcid_depth++] = result->current_mcid;
    }
    /* Nested marked content without its own /MCID inherits the parent's. */
    if (mcid >= 0) result->current_mcid = mcid;
}

static void textract_on_mc_end(void *ctx, const pdfmake_gstate_t *gs)
{
    pdfmake_textract_result_t *result = (pdfmake_textract_result_t *)ctx;
    (void)gs;
    if (!result) return;
    if (result->mcid_depth > 0) {
        result->current_mcid = result->mcid_stack[--result->mcid_depth];
    } else {
        result->current_mcid = -1;
    }
}

/* Phase 14: report the current font's writing mode so the interpreter can
 * advance text_matrix on the right axis. */
static int textract_is_vertical(void *ctx, const pdfmake_gstate_t *gs) {
    pdfmake_textract_result_t *result = (pdfmake_textract_result_t *)ctx;
    pdfmake_resolved_font_t *rf;
    if (!result || !gs) return 0;
    rf = resolve_font(result, gs->font);
    return rf ? rf->wmode : 0;
}

pdfmake_visitor_t pdfmake_textract_visitor(pdfmake_textract_result_t *result) {
    pdfmake_visitor_t v;
    memset(&v, 0, sizeof(v));
    v.ctx = result;
    v.on_text_show = textract_on_text_show;
    v.get_string_advance = textract_get_string_advance;
    v.on_marked_content_begin = textract_on_mc_begin;
    v.on_marked_content_end   = textract_on_mc_end;
    v.is_vertical_writing = textract_is_vertical;  /* Phase 14 */
    return v;
}

/*============================================================================
 * Aggregation: raw glyphs → words → lines → blocks
 *==========================================================================*/

/* qsort() has no ctx param — use a file-static pointer for column info
 * during the sort. pdfmake_textract_aggregate is single-threaded so this
 * is safe. */
static const double *g_sort_column_splits = NULL;
static int           g_sort_column_count  = 0;

static int glyph_column(const pdfmake_text_glyph_t *g) {
    int col = 0;
    int i;
    for (i = 0; i < g_sort_column_count; i++) {
        if (g->x0 >= g_sort_column_splits[i]) col++;
        else break;
    }
    return col;
}

/* Compare glyphs by column, then y descending, then x ascending. */
static int cmp_glyph_position(const void *a, const void *b) {
    const pdfmake_text_glyph_t *ga = (const pdfmake_text_glyph_t *)a;
    const pdfmake_text_glyph_t *gb = (const pdfmake_text_glyph_t *)b;
    double col_tol;
    double dx_cx;
    double dy2;
    int ca;
    int cb;
    double dy;
    double dx;

    /* Phase 14: vertical glyphs sort right-to-left, top-to-bottom so
     * reading order matches CJK conventions. */
    if (ga->vertical && gb->vertical) {
        /* Group into columns by x (tolerance = font size).  Right-most
         * column comes first. */
        col_tol = ga->font_size * 0.5;
        dx_cx = gb->x0 - ga->x0;
        if (fabs(dx_cx) > col_tol) {
            return dx_cx > 0 ? -1 : 1;   /* larger x first */
        }
        /* Same column: higher y first (top-to-bottom). */
        dy2 = gb->y0 - ga->y0;
        if (dy2 < 0) return -1;
        if (dy2 > 0) return 1;
        return 0;
    }
    /* If one is vertical and the other horizontal, emit vertical last so
     * the horizontal reading order isn't interleaved.  (Truly mixed pages
     * are rare; the user can filter per glyph->vertical if they need to.) */
    if (ga->vertical != gb->vertical) {
        return ga->vertical ? 1 : -1;
    }

    /* Phase 10: columns first so column 1 flows fully before column 2 */
    if (g_sort_column_count > 0) {
        ca = glyph_column(ga);
        cb = glyph_column(gb);
        if (ca != cb) return ca - cb;
    }

    /* Group by baseline (y0): higher y first (PDF y increases upward) */
    dy = gb->y0 - ga->y0;
    if (fabs(dy) > ga->font_size * 0.3) {
        return dy > 0 ? 1 : -1;
    }
    /* Same line: left to right */
    dx = ga->x0 - gb->x0;
    if (dx < 0) return -1;
    if (dx > 0) return 1;
    return 0;
}

/* Detect column splits via largest-gap analysis on x0 values.
 *
 * Algorithm: take all unique-ish glyph x0 values, sort them, look for
 * contiguous runs where no glyph starts. The widest such run in the page
 * interior (not at extremes) is a likely gutter; split at its midpoint.
 * Recurse on each half to find multi-column layouts up to 8 total columns.
 *
 * Thresholds:
 *   - min gutter width: 20pt (so we don't split on letter spacing)
 *   - gutter must be in middle 70% of x-range (not at margins)
 *   - only split if the two sides each contain ≥ 4 glyphs
 */
/* Histogram bin size for column-gutter detection, in user-space points */
#define COLUMN_BIN_SIZE 5.0

static void detect_column_splits_in_range(
    const pdfmake_text_glyph_t *glyphs, size_t n,
    double x_lo, double x_hi,
    double *out_splits, int *out_count, int max_count)
{
    size_t n_bins;
    uint32_t *hist;
    size_t i;
    uint32_t max_cnt;
    uint32_t empty_thr;
    size_t safe_lo_bin;
    size_t safe_hi_bin;
    size_t best_run;
    size_t best_start;
    size_t cur_run;
    size_t cur_start;
    size_t mid;
    size_t min_gutter_bins;
    size_t active_left;
    size_t active_right;
    if (*out_count >= max_count) return;
    if (x_hi - x_lo < 100) return;

    n_bins = (size_t)((x_hi - x_lo) / COLUMN_BIN_SIZE) + 1;
    if (n_bins < 16 || n_bins > 10000) return;

    hist = calloc(n_bins, sizeof(uint32_t));
    if (!hist) return;

    /* Populate histogram by glyph bbox coverage (not just x0) */
    for (i = 0; i < n; i++) {
        const pdfmake_text_glyph_t *g = &glyphs[i];
        double a;
        double b;
        size_t ba;
        size_t bb;
        if (g->x1 < x_lo || g->x0 > x_hi) continue;
        a = g->x0 > x_lo ? g->x0 : x_lo;
        b = g->x1 < x_hi ? g->x1 : x_hi;
        if (b <= a) continue;
        ba = (size_t)((a - x_lo) / COLUMN_BIN_SIZE);
        bb = (size_t)((b - x_lo) / COLUMN_BIN_SIZE);
        if (bb >= n_bins) bb = n_bins - 1;
        {
            size_t k;
            for (k = ba; k <= bb; k++) hist[k]++;
        }
    }

    max_cnt = 0;
    for (i = 0; i < n_bins; i++)
        if (hist[i] > max_cnt) max_cnt = hist[i];
    if (max_cnt < 4) { free(hist); return; }

    /* "Near-empty" = less than 15% of peak density. Higher than 2% because
     * full-width headers/footers contribute thin residual occupancy across
     * the gutter, and we don't want those to mask real column gaps. */
    empty_thr = max_cnt / 6 + 1;

    /* Only consider gutters whose midpoint is in the middle 70% of range */
    safe_lo_bin = n_bins * 15 / 100;
    safe_hi_bin = n_bins * 85 / 100;

    best_run = 0;
    best_start = 0;
    cur_run = 0;
    cur_start = 0;
    for (i = 0; i < n_bins; i++) {
        if (hist[i] < empty_thr) {
            if (cur_run == 0) cur_start = i;
            cur_run++;
        } else {
            if (cur_run > best_run) {
                mid = cur_start + cur_run / 2;
                if (mid >= safe_lo_bin && mid <= safe_hi_bin) {
                    best_run = cur_run;
                    best_start = cur_start;
                }
            }
            cur_run = 0;
        }
    }
    if (cur_run > best_run) {
        mid = cur_start + cur_run / 2;
        if (mid >= safe_lo_bin && mid <= safe_hi_bin) {
            best_run = cur_run;
            best_start = cur_start;
        }
    }

    min_gutter_bins = (size_t)(20.0 / COLUMN_BIN_SIZE);  /* 20pt */
    if (best_run >= min_gutter_bins) {
        active_left = 0;
        active_right = 0;
        for (i = 0; i < best_start; i++)
            if (hist[i] >= empty_thr) active_left++;
        for (i = best_start + best_run; i < n_bins; i++)
            if (hist[i] >= empty_thr) active_right++;
        if (active_left >= 4 && active_right >= 4) {
            double mid_x = x_lo + (best_start + best_run / 2.0) * COLUMN_BIN_SIZE;

            int pos = *out_count;
            while (pos > 0 && out_splits[pos - 1] > mid_x) {
                out_splits[pos] = out_splits[pos - 1]; pos--;
            }
            out_splits[pos] = mid_x;
            (*out_count)++;

            free(hist);
            /* Recurse into each half to find further column splits */
            detect_column_splits_in_range(glyphs, n,
                x_lo, mid_x, out_splits, out_count, max_count);
            detect_column_splits_in_range(glyphs, n,
                mid_x, x_hi, out_splits, out_count, max_count);
            return;
        }
    }

    free(hist);
}

static void detect_column_splits(pdfmake_textract_result_t *result) {
    double x_lo;
    double x_hi;
    size_t i;
    result->column_split_count = 0;
    if (result->raw_len < 16) return;

    x_lo = 1e18;
    x_hi = -1e18;
    for (i = 0; i < result->raw_len; i++) {
        if (result->raw_glyphs[i].x0 < x_lo) x_lo = result->raw_glyphs[i].x0;
        if (result->raw_glyphs[i].x1 > x_hi) x_hi = result->raw_glyphs[i].x1;
    }
    if (x_hi - x_lo < 100) return;

    detect_column_splits_in_range(result->raw_glyphs, result->raw_len,
        x_lo, x_hi, result->column_splits, &result->column_split_count,
        (int)(sizeof(result->column_splits) / sizeof(double)));
}

static void update_bbox_from_glyph(double *x0, double *y0, double *x1, double *y1,
                                    const pdfmake_text_glyph_t *g) {
    if (g->x0 < *x0) *x0 = g->x0;
    if (g->y0 < *y0) *y0 = g->y0;
    if (g->x1 > *x1) *x1 = g->x1;
    if (g->y1 > *y1) *y1 = g->y1;
}

static int word_push_glyph(pdfmake_text_word_t *w, const pdfmake_text_glyph_t *g) {
    if (w->len >= w->cap) {
        size_t new_cap = w->cap == 0 ? 8 : w->cap * 2;
        pdfmake_text_glyph_t *arr = realloc(w->glyphs, new_cap * sizeof(*arr));
        if (!arr) return 0;
        w->glyphs = arr;
        w->cap = new_cap;
    }
    w->glyphs[w->len++] = *g;
    return 1;
}

static int line_push_word(pdfmake_text_line_t *l, const pdfmake_text_word_t *w) {
    if (l->len >= l->cap) {
        size_t new_cap = l->cap == 0 ? 8 : l->cap * 2;
        pdfmake_text_word_t *arr = realloc(l->words, new_cap * sizeof(*arr));
        if (!arr) return 0;
        l->words = arr;
        l->cap = new_cap;
    }
    l->words[l->len++] = *w;
    return 1;
}

static int block_push_line(pdfmake_text_block_t *b, const pdfmake_text_line_t *l) {
    if (b->len >= b->cap) {
        size_t new_cap = b->cap == 0 ? 8 : b->cap * 2;
        pdfmake_text_line_t *arr = realloc(b->lines, new_cap * sizeof(*arr));
        if (!arr) return 0;
        b->lines = arr;
        b->cap = new_cap;
    }
    b->lines[b->len++] = *l;
    return 1;
}

static int result_push_block(pdfmake_textract_result_t *r, const pdfmake_text_block_t *b) {
    if (r->len >= r->cap) {
        size_t new_cap = r->cap == 0 ? 4 : r->cap * 2;
        pdfmake_text_block_t *arr = realloc(r->blocks, new_cap * sizeof(*arr));
        if (!arr) return 0;
        r->blocks = arr;
        r->cap = new_cap;
    }
    r->blocks[r->len++] = *b;
    return 1;
}

pdfmake_err_t pdfmake_textract_aggregate(
    pdfmake_textract_result_t *result,
    const pdfmake_textract_options_t *options)
{
    pdfmake_textract_options_t opts;
    pdfmake_text_word_t *words;
    size_t words_len;
    size_t words_cap;
    pdfmake_text_word_t cur_word;
    pdfmake_text_line_t *lines;
    size_t lines_len;
    size_t lines_cap;
    pdfmake_text_line_t cur_line;
    pdfmake_text_block_t cur_block;
    size_t i;
    if (!result || result->raw_len == 0) return PDFMAKE_OK;

    opts = options ? *options : pdfmake_textract_default_options();

    /* Phase 10: detect column splits before sorting so reading order is
     * column-major (fill column 1 top-to-bottom, then column 2, ...). */
    detect_column_splits(result);
    g_sort_column_splits = result->column_splits;
    g_sort_column_count  = result->column_split_count;

    /* Sort glyphs into reading order */
    qsort(result->raw_glyphs, result->raw_len, sizeof(pdfmake_text_glyph_t),
          cmp_glyph_position);

    /* Don't leak static pointers past this function */
    g_sort_column_splits = NULL;
    g_sort_column_count  = 0;

    /* Phase 5: Kern-aware word grouping.
     *
     * We split into a new word when ONE of:
     *   - previous glyph is a space (U+0020)
     *   - current glyph is a space                         (low priority)
     *   - baseline jumped significantly (implies new line)
     *   - horizontal gap exceeds a context-sensitive threshold
     *
     * Key insight from Phase 5: the gap threshold must be wider when the
     * previous glyph's advance is a fallback (i.e., we didn't know the real
     * width). In that case a "real-looking" Td that's actually intra-word
     * spacing (author-driven font-change mid-word in subsetted fonts) looks
     * like a big visible gap. Using ~0.9 em here keeps "Data" glued together
     * across font changes while still catching inter-word spaces.
     *
     * When we trust the advance, we use the tighter 0.3-em threshold —
     * that's what PDF typesetters use as a natural space width.
     *
     * We never split on negative or zero gaps; those come from kerning
     * overlap in TJ arrays and always represent intra-word positioning.
     */
    words = NULL;
    words_len = 0;
    words_cap = 0;

    memset(&cur_word, 0, sizeof(cur_word));
    cur_word.x0 = cur_word.y0 = 1e18;
    cur_word.x1 = cur_word.y1 = -1e18;
    cur_word.mcid = -1;

    for (i = 0; i < result->raw_len; i++) {
        pdfmake_text_glyph_t *g = &result->raw_glyphs[i];

        int new_word = 0;
        if (cur_word.len == 0) {
            new_word = 0; /* first glyph */
        } else {
            pdfmake_text_glyph_t *prev = &cur_word.glyphs[cur_word.len - 1];

            if (g->vertical) {
                /* Phase 14: vertical word — split on column change (x jump)
                 * or on a large vertical gap. */
                double col_diff = fabs(g->x0 - prev->x0);
                /* prev->y0 is the bottom; g->y1 is the top of the new glyph.
                 * In top-to-bottom flow, gap = prev->y0 - g->y1 > 0. */
                double v_gap = prev->y0 - g->y1;

                if (col_diff > g->font_size * 0.5) {
                    new_word = 1;
                }
                if (!new_word && v_gap > opts.word_gap_factor * g->font_size) {
                    new_word = 1;
                }
            } else {
                double gap = g->x0 - prev->x1;
                double baseline_diff = fabs(g->y0 - prev->y0);

                /* Rule 1: baseline change = new line = new word */
                if (baseline_diff > opts.line_tolerance * g->font_size) {
                    new_word = 1;
                }

                /* Rule 2: explicit space character = word boundary */
                if (!new_word &&
                    (prev->unicode == 0x20 || g->unicode == 0x20)) {
                    new_word = 1;
                }

                /* Rule 3: gap threshold based on advance reliability.
                 *   - Reliable advances: tight ~0.3 em threshold
                 *   - Fallback advances: generous ~0.9 em threshold
                 *   - Negative/zero gaps: never split (kerning) */
                if (!new_word && gap > 0) {
                    double threshold;
                    if (prev->reliable_advance) {
                        threshold = opts.word_gap_factor * g->font_size;
                    } else {
                        /* Unreliable widths: need a bigger gap to call it a space */
                        threshold = 0.9 * g->font_size;
                    }
                    if (gap > threshold) new_word = 1;
                }
            }
        }

        if (new_word && cur_word.len > 0) {
            /* Flush current word */
            if (words_len >= words_cap) {
                words_cap = words_cap == 0 ? 16 : words_cap * 2;
                words = realloc(words, words_cap * sizeof(*words));
                if (!words) return PDFMAKE_ENOMEM;
            }
            words[words_len++] = cur_word;
            memset(&cur_word, 0, sizeof(cur_word));
            cur_word.x0 = cur_word.y0 = 1e18;
            cur_word.x1 = cur_word.y1 = -1e18;
            cur_word.mcid = -1;
        }

        /* Skip spaces (don't include in words) */
        if (g->unicode == 0x20) continue;

        /* Phase 12: first glyph sets the word's MCID */
        if (cur_word.len == 0) cur_word.mcid = g->mcid;

        word_push_glyph(&cur_word, g);
        update_bbox_from_glyph(&cur_word.x0, &cur_word.y0,
                                &cur_word.x1, &cur_word.y1, g);
    }
    /* Flush last word */
    if (cur_word.len > 0) {
        if (words_len >= words_cap) {
            words_cap = words_cap == 0 ? 16 : words_cap * 2;
            words = realloc(words, words_cap * sizeof(*words));
        }
        if (words) words[words_len++] = cur_word;
    }

    if (words_len == 0) {
        free(words);
        return PDFMAKE_OK;
    }

    /* Phase 2: Group words into lines (same baseline) */
    lines = NULL;
    lines_len = 0;
    lines_cap = 0;

    memset(&cur_line, 0, sizeof(cur_line));
    cur_line.x0 = cur_line.y0 = 1e18;
    cur_line.x1 = cur_line.y1 = -1e18;

    for (i = 0; i < words_len; i++) {
        pdfmake_text_word_t *w = &words[i];

        /* Phase 14: detect whether this word is vertical by checking its
         * first glyph. Line grouping then compares x (column) instead of
         * baseline y. */
        int w_vertical = (w->len > 0 && w->glyphs[0].vertical);

        int new_line = 0;
        if (cur_line.len == 0) {
            cur_line.baseline_y = w->y0;
        } else {
            double ref_size = cur_line.words[0].glyphs[0].font_size;
            if (w_vertical) {
                /* Same column = same vertical line. */
                double col_diff = fabs(w->x0 - cur_line.words[0].x0);
                if (col_diff > ref_size * 0.5) new_line = 1;
            } else {
                double baseline_diff = fabs(w->y0 - cur_line.baseline_y);
                if (baseline_diff > opts.line_tolerance * ref_size) {
                    new_line = 1;
                }
            }
        }

        if (new_line && cur_line.len > 0) {
            if (lines_len >= lines_cap) {
                lines_cap = lines_cap == 0 ? 8 : lines_cap * 2;
                lines = realloc(lines, lines_cap * sizeof(*lines));
                if (!lines) { free(words); return PDFMAKE_ENOMEM; }
            }
            lines[lines_len++] = cur_line;
            memset(&cur_line, 0, sizeof(cur_line));
            cur_line.x0 = cur_line.y0 = 1e18;
            cur_line.x1 = cur_line.y1 = -1e18;
            cur_line.baseline_y = w->y0;
        }

        line_push_word(&cur_line, w);
        if (w->x0 < cur_line.x0) cur_line.x0 = w->x0;
        if (w->y0 < cur_line.y0) cur_line.y0 = w->y0;
        if (w->x1 > cur_line.x1) cur_line.x1 = w->x1;
        if (w->y1 > cur_line.y1) cur_line.y1 = w->y1;
    }
    if (cur_line.len > 0) {
        if (lines_len >= lines_cap) {
            lines_cap = lines_cap == 0 ? 8 : lines_cap * 2;
            lines = realloc(lines, lines_cap * sizeof(*lines));
        }
        if (lines) lines[lines_len++] = cur_line;
    }
    free(words); /* words are now owned by lines */

    /* Phase 3: Group lines into blocks */
    memset(&cur_block, 0, sizeof(cur_block));
    cur_block.x0 = cur_block.y0 = 1e18;
    cur_block.x1 = cur_block.y1 = -1e18;

    for (i = 0; i < lines_len; i++) {
        pdfmake_text_line_t *l = &lines[i];

        int new_block = 0;
        if (cur_block.len > 0) {
            pdfmake_text_line_t *prev = &cur_block.lines[cur_block.len - 1];
            double ref_size = prev->words[0].glyphs[0].font_size;
            int l_vertical = (l->words[0].len > 0 &&
                              l->words[0].glyphs[0].vertical);
            double gap;
            if (l_vertical) {
                /* Vertical: block boundary when columns are far apart in x. */
                gap = fabs(prev->words[0].x0 - l->words[0].x0);
            } else {
                gap = fabs(prev->baseline_y - l->baseline_y);
            }
            if (gap > opts.block_leading * ref_size) {
                new_block = 1;
            }
        }

        if (new_block && cur_block.len > 0) {
            result_push_block(result, &cur_block);
            memset(&cur_block, 0, sizeof(cur_block));
            cur_block.x0 = cur_block.y0 = 1e18;
            cur_block.x1 = cur_block.y1 = -1e18;
        }

        block_push_line(&cur_block, l);
        if (l->x0 < cur_block.x0) cur_block.x0 = l->x0;
        if (l->y0 < cur_block.y0) cur_block.y0 = l->y0;
        if (l->x1 > cur_block.x1) cur_block.x1 = l->x1;
        if (l->y1 > cur_block.y1) cur_block.y1 = l->y1;
    }
    if (cur_block.len > 0) {
        result_push_block(result, &cur_block);
    }
    free(lines); /* lines are now owned by blocks */

    return PDFMAKE_OK;
}

/*============================================================================
 * Convenience: run extraction in one call
 *==========================================================================*/

pdfmake_err_t pdfmake_textract_run(
    pdfmake_interp_t *interp,
    const uint8_t *content, size_t content_len,
    const pdfmake_textract_options_t *options,
    pdfmake_textract_result_t *result)
{
    pdfmake_visitor_t visitor;
    pdfmake_err_t err;
    if (!interp || !content || !result) return PDFMAKE_EINVAL;

    /* Propagate per-run options that the visitor needs to see during
     * interpretation (aggregate-phase options stay in `options`). */
    if (options) {
        result->include_invisible = options->include_invisible;
    }

    /* Set up visitor */
    visitor = pdfmake_textract_visitor(result);
    pdfmake_interp_set_visitor(interp, &visitor);

    /* Interpret content stream */
    err = pdfmake_interpret(interp, content, content_len);
    if (err != PDFMAKE_OK) return err;

    /* Aggregate */
    return pdfmake_textract_aggregate(result, options);
}

/*============================================================================
 * Phase 12: Structure tree resolution
 *
 * Walks a /StructTreeRoot subtree and populates result->struct_map with one
 * entry per MCID encountered, pairing it with the /S role of the nearest
 * enclosing StructElem. The resulting flat map is consulted after extraction
 * so each word can be tagged with its structure role.
 *==========================================================================*/

static int struct_map_push(pdfmake_textract_result_t *r, int32_t mcid,
                            uint32_t role_id)
{
    if (mcid < 0 || role_id == 0) return 1;
    if (r->struct_map_len >= r->struct_map_cap) {
        size_t new_cap = r->struct_map_cap == 0 ? 16 : r->struct_map_cap * 2;
        pdfmake_struct_map_entry_t *n = realloc(
            r->struct_map, new_cap * sizeof(*n));
        if (!n) return 0;
        r->struct_map = n;
        r->struct_map_cap = new_cap;
    }
    r->struct_map[r->struct_map_len].mcid = mcid;
    r->struct_map[r->struct_map_len].role_id = role_id;
    r->struct_map_len++;
    return 1;
}

/* Recursively walk a StructElem dict or its /K entry. role_id is the /S of
 * the nearest enclosing StructElem. page_dict is the target page (NULL to
 * accept all pages). */
static void walk_struct_node(pdfmake_textract_result_t *r,
                              pdfmake_obj_t *node,
                              uint32_t role_id,
                              pdfmake_obj_t *page_dict,
                              int depth)
{
    size_t i;
    size_t n;
    pdfmake_obj_t *item;
    uint32_t type_key;
    pdfmake_obj_t *type_v;
    const char *type_name;
    uint32_t mcid_key;
    pdfmake_obj_t *mcid_v;
    uint32_t pg_key;
    pdfmake_obj_t *pg;
    pdfmake_reader_t *rd;
    pdfmake_obj_t *resolved;
    uint32_t s_key;
    pdfmake_obj_t *s_v;
    uint32_t this_role;
    uint32_t k_key;
    pdfmake_obj_t *k;
    if (!node || depth > 32) return;

    /* Follow indirect references */
    if (node->kind == PDFMAKE_REF && r->reader) {
        pdfmake_reader_t *rd = (pdfmake_reader_t *)r->reader;
        if (!rd->parser) return;
        node = pdfmake_parser_resolve(rd->parser, node->as.ref);
        if (!node) return;
    }

    /* Integer leaf: this MCID belongs to role_id */
    if (node->kind == PDFMAKE_INT) {
        struct_map_push(r, (int32_t)node->as.i, role_id);
        return;
    }

    /* Array: recurse into each kid, keeping the current role_id */
    if (node->kind == PDFMAKE_ARRAY) {
        n = pdfmake_array_len(node);
        for (i = 0; i < n; i++) {
            item = pdfmake_array_get(node, i);
            if (item) walk_struct_node(r, item, role_id, page_dict, depth + 1);
        }
        return;
    }

    if (node->kind != PDFMAKE_DICT) return;

    /* MCR dict: { /Type /MCR, /Pg <page>, /MCID n } — ignore /Pg for now
     * since per-page extraction already limits us to one page's content. */
    type_key = pdfmake_arena_intern_name(r->arena, "Type", 4);
    type_v = pdfmake_dict_get(node, type_key);
    type_name = NULL;
    if (type_v && type_v->kind == PDFMAKE_NAME) {
        type_name = pdfmake_get_name_bytes(r->arena, type_v);
    }

    mcid_key = pdfmake_arena_intern_name(r->arena, "MCID", 4);
    mcid_v = pdfmake_dict_get(node, mcid_key);

    if (type_name && strcmp(type_name, "MCR") == 0) {
        pg_key = pdfmake_arena_intern_name(r->arena, "Pg", 2);
        pg = pdfmake_dict_get(node, pg_key);
        if (pg && page_dict && pg->kind == PDFMAKE_REF && r->reader) {
            /* Skip MCRs that target a different page */
            rd = (pdfmake_reader_t *)r->reader;
            resolved = rd->parser
                ? pdfmake_parser_resolve(rd->parser, pg->as.ref) : NULL;
            if (resolved && resolved != page_dict) return;
        }
        if (mcid_v && mcid_v->kind == PDFMAKE_INT) {
            struct_map_push(r, (int32_t)mcid_v->as.i, role_id);
        }
        return;
    }

    /* OBJR (object reference to an annotation) — no MCID, skip */
    if (type_name && strcmp(type_name, "OBJR") == 0) return;

    /* StructElem: adopt its /S as the current role, then recurse into /K */
    s_key = pdfmake_arena_intern_name(r->arena, "S", 1);
    s_v = pdfmake_dict_get(node, s_key);
    this_role = role_id;
    if (s_v && s_v->kind == PDFMAKE_NAME) this_role = s_v->as.name.id;

    /* /Pg filter: if this StructElem binds a specific page and it doesn't
     * match ours, we can still recurse — children may override /Pg. */
    k_key = pdfmake_arena_intern_name(r->arena, "K", 1);
    k = pdfmake_dict_get(node, k_key);
    if (!k) return;

    /* /K can be an integer (MCID), a dict (StructElem/MCR/OBJR), a ref, or
     * an array of any of the above. walk_struct_node handles all cases. */
    walk_struct_node(r, k, this_role, page_dict, depth + 1);
}

pdfmake_err_t pdfmake_textract_resolve_struct_tree(
    pdfmake_textract_result_t *result,
    pdfmake_obj_t             *struct_root,
    pdfmake_obj_t             *page_dict)
{
    pdfmake_reader_t *rd;
    uint32_t k_key;
    pdfmake_obj_t *k;
    if (!result) return PDFMAKE_EINVAL;
    if (!struct_root || !result->arena) return PDFMAKE_OK;  /* no-op */

    /* Follow an indirect reference to the StructTreeRoot dict */
    if (struct_root->kind == PDFMAKE_REF && result->reader) {
        rd = (pdfmake_reader_t *)result->reader;
        if (rd->parser) {
            struct_root = pdfmake_parser_resolve(rd->parser, struct_root->as.ref);
            if (!struct_root) return PDFMAKE_OK;
        }
    }
    if (struct_root->kind != PDFMAKE_DICT) return PDFMAKE_OK;

    /* Start at /K of the StructTreeRoot; role 0 means "none" (children will
     * overwrite as soon as they hit a StructElem with /S). */
    k_key = pdfmake_arena_intern_name(result->arena, "K", 1);
    k = pdfmake_dict_get(struct_root, k_key);
    if (k) walk_struct_node(result, k, 0, page_dict, 0);

    return PDFMAKE_OK;
}

uint32_t pdfmake_textract_role_for_mcid(
    const pdfmake_textract_result_t *result, int32_t mcid)
{
    size_t i;
    if (!result || mcid < 0) return 0;
    for (i = 0; i < result->struct_map_len; i++) {
        if (result->struct_map[i].mcid == mcid) {
            return result->struct_map[i].role_id;
        }
    }
    return 0;
}

/*============================================================================
 * Phase 13 — Annotation + form field text extraction
 *==========================================================================*/

/* Decode a PDF "text string" (§7.9.2) to UTF-8, arena-allocated.
 * Handles UTF-16BE (with BOM FE FF) and UTF-8-with-BOM (EF BB BF); everything
 * else is treated as PDFDocEncoding, which matches ISO-8859-1 for the ASCII
 * subset used by every real-world annotation we've seen. */
static const char *decode_pdf_text(pdfmake_arena_t *arena,
                                    const uint8_t *b, size_t n)
{
    size_t i;
    pdfmake_buf_t out;
    char *s;
    uint32_t cp;
    uint32_t lo;
    uint8_t c;
    if (!arena || !b) return NULL;

    /* UTF-16BE BOM */
    if (n >= 2 && b[0] == 0xFE && b[1] == 0xFF) {
        pdfmake_buf_init(&out);
        s = NULL;
        for (i = 2; i + 1 < n; i += 2) {
            cp = ((uint32_t)b[i] << 8) | b[i + 1];
            if (cp >= 0xD800 && cp <= 0xDBFF && i + 3 < n) {
                lo = ((uint32_t)b[i + 2] << 8) | b[i + 3];
                if (lo >= 0xDC00 && lo <= 0xDFFF) {
                    cp = 0x10000 + ((cp - 0xD800) << 10) + (lo - 0xDC00);
                    i += 2;
                }
            }
            if (cp < 0x80) {
                pdfmake_buf_append_byte(&out, (uint8_t)cp);
            } else if (cp < 0x800) {
                pdfmake_buf_append_byte(&out, 0xC0 | (cp >> 6));
                pdfmake_buf_append_byte(&out, 0x80 | (cp & 0x3F));
            } else if (cp < 0x10000) {
                pdfmake_buf_append_byte(&out, 0xE0 | (cp >> 12));
                pdfmake_buf_append_byte(&out, 0x80 | ((cp >> 6) & 0x3F));
                pdfmake_buf_append_byte(&out, 0x80 | (cp & 0x3F));
            } else {
                pdfmake_buf_append_byte(&out, 0xF0 | (cp >> 18));
                pdfmake_buf_append_byte(&out, 0x80 | ((cp >> 12) & 0x3F));
                pdfmake_buf_append_byte(&out, 0x80 | ((cp >> 6) & 0x3F));
                pdfmake_buf_append_byte(&out, 0x80 | (cp & 0x3F));
            }
        }
        s = pdfmake_arena_alloc(arena, out.len + 1);
        if (s) { memcpy(s, out.data, out.len); s[out.len] = 0; }
        pdfmake_buf_free(&out);
        return s;
    }

    /* UTF-8 with BOM (PDF 2.0) */
    if (n >= 3 && b[0] == 0xEF && b[1] == 0xBB && b[2] == 0xBF) {
        b += 3; n -= 3;
    }

    /* PDFDocEncoding → promote high-bit bytes to 2-byte UTF-8. */
    pdfmake_buf_init(&out);
    for (i = 0; i < n; i++) {
        c = b[i];
        if (c < 0x80) {
            pdfmake_buf_append_byte(&out, c);
        } else {
            pdfmake_buf_append_byte(&out, 0xC0 | (c >> 6));
            pdfmake_buf_append_byte(&out, 0x80 | (c & 0x3F));
        }
    }
    s = pdfmake_arena_alloc(arena, out.len + 1);
    if (s) { memcpy(s, out.data, out.len); s[out.len] = 0; }
    pdfmake_buf_free(&out);
    return s;
}

/* Pull a PDF text string out of a dict (resolving one level of indirection).
 * Returns NULL if the key is missing or not a string. */
static const char *dict_get_text(pdfmake_reader_t *rd,
                                  pdfmake_arena_t *arena,
                                  pdfmake_obj_t *dict,
                                  const char *name)
{
    uint32_t key;
    pdfmake_obj_t *v;
    if (!dict || dict->kind != PDFMAKE_DICT) return NULL;
    key = pdfmake_arena_intern_name(arena, name, strlen(name));
    v = pdfmake_dict_get(dict, key);
    if (v && v->kind == PDFMAKE_REF && rd && rd->parser) {
        v = pdfmake_parser_resolve(rd->parser, v->as.ref);
    }
    if (!v || v->kind != PDFMAKE_STR) return NULL;
    return decode_pdf_text(arena, v->as.str.bytes, v->as.str.len);
}

/* Resolve a dict entry that's allowed to be an indirect reference. */
static pdfmake_obj_t *dict_get_resolved(pdfmake_reader_t *rd,
                                         pdfmake_arena_t *arena,
                                         pdfmake_obj_t *dict,
                                         const char *name)
{
    uint32_t key;
    pdfmake_obj_t *v;
    if (!dict || dict->kind != PDFMAKE_DICT) return NULL;
    key = pdfmake_arena_intern_name(arena, name, strlen(name));
    v = pdfmake_dict_get(dict, key);
    if (v && v->kind == PDFMAKE_REF && rd && rd->parser) {
        v = pdfmake_parser_resolve(rd->parser, v->as.ref);
    }
    return v;
}

pdfmake_annot_text_list_t *pdfmake_annot_text_list_new(pdfmake_arena_t *arena) {
    pdfmake_annot_text_list_t *l = calloc(1, sizeof(*l));
    if (l) l->arena = arena;
    return l;
}

void pdfmake_annot_text_list_free(pdfmake_annot_text_list_t *list) {
    if (!list) return;
    free(list->items);
    free(list);
}

static int annot_list_push(pdfmake_annot_text_list_t *l,
                            const pdfmake_annot_text_t *rec)
{
    if (l->len >= l->cap) {
        size_t ncap = l->cap == 0 ? 8 : l->cap * 2;
        pdfmake_annot_text_t *n = realloc(l->items, ncap * sizeof(*n));
        if (!n) return 0;
        l->items = n; l->cap = ncap;
    }
    l->items[l->len++] = *rec;
    return 1;
}

/* Pull a 4-element numeric array (Rect / FreeText BBox) into out[4].
 * Zeros the array if the entry is missing or malformed. */
static void dict_get_rect(pdfmake_obj_t *dict, uint32_t key, double out[4]) {
    int i;
    pdfmake_obj_t *v;
    pdfmake_obj_t *n;
    out[0] = out[1] = out[2] = out[3] = 0;
    v = pdfmake_dict_get(dict, key);
    if (!v || v->kind != PDFMAKE_ARRAY) return;
    if (pdfmake_array_len(v) < 4) return;
    for (i = 0; i < 4; i++) {
        n = pdfmake_array_get(v, i);
        if (n) out[i] = pdfmake_get_number(n);
    }
}

/* Walk one page's /Annots array. */
static void collect_page_annots(pdfmake_reader_t *rd,
                                 pdfmake_annot_text_list_t *out,
                                 pdfmake_reader_page_t *page,
                                 size_t page_index)
{
    size_t i;
    pdfmake_arena_t *arena;
    uint32_t annots_key;
    pdfmake_obj_t *annots;
    uint32_t rect_key;
    size_t n;
    pdfmake_obj_t *a;
    uint32_t sub_key;
    pdfmake_obj_t *sub;
    const char *kind;
    const char *nm;
    const char *contents;
    const char *author;
    const char *subject;
    pdfmake_annot_text_t rec;
    if (!page || !page->page_dict) return;
    arena = rd->parser->doc->arena;

    annots_key = pdfmake_arena_intern_name(arena, "Annots", 6);
    annots = pdfmake_dict_get(page->page_dict, annots_key);
    if (annots && annots->kind == PDFMAKE_REF) {
        annots = pdfmake_parser_resolve(rd->parser, annots->as.ref);
    }
    if (!annots || annots->kind != PDFMAKE_ARRAY) return;

    rect_key = pdfmake_arena_intern_name(arena, "Rect", 4);
    n = pdfmake_array_len(annots);
    for (i = 0; i < n; i++) {
        a = pdfmake_array_get(annots, i);
        if (a && a->kind == PDFMAKE_REF) {
            a = pdfmake_parser_resolve(rd->parser, a->as.ref);
        }
        if (!a || a->kind != PDFMAKE_DICT) continue;

        /* Subtype decides the kind label; we surface every textual annot. */
        sub_key = pdfmake_arena_intern_name(arena, "Subtype", 7);
        sub = pdfmake_dict_get(a, sub_key);
        kind = "Annot";
        if (sub && sub->kind == PDFMAKE_NAME) {
            nm = pdfmake_get_name_bytes(arena, sub);
            if (nm) kind = nm;
        }

        /* Skip Link/Widget/PrinterMark etc. that never carry user text.
         * Widgets are surfaced via the AcroForm walker instead. */
        if (strcmp(kind, "Link") == 0 ||
            strcmp(kind, "Widget") == 0 ||
            strcmp(kind, "PrinterMark") == 0 ||
            strcmp(kind, "TrapNet") == 0) {
            continue;
        }

        contents = dict_get_text(rd, arena, a, "Contents");
        author   = dict_get_text(rd, arena, a, "T");
        subject  = dict_get_text(rd, arena, a, "Subj");

        /* Even with no /Contents we emit the record if there's author or
         * subject text — a Popup without Contents still tells you who
         * highlighted what. */
        if (!contents && !author && !subject) continue;

        memset(&rec, 0, sizeof(rec));
        rec.kind = pdfmake_arena_strdup(arena, kind);
        rec.page_index = page_index;
        dict_get_rect(a, rect_key, rec.rect);
        rec.text = contents ? contents : "";
        rec.author = author;
        rec.subject = subject;
        annot_list_push(out, &rec);
    }
}

/* Recursively walk /AcroForm /Fields; /Kids trees inherit qualified names
 * via dot-joining (§12.7.3.2). */
static void collect_form_fields(pdfmake_reader_t *rd,
                                 pdfmake_annot_text_list_t *out,
                                 pdfmake_obj_t *field,
                                 const char *parent_name,
                                 int depth)
{
    size_t i;
    size_t pi;
    pdfmake_arena_t *arena;
    const char *t;
    const char *full_name;
    size_t pl;
    size_t tl;
    char *buf;
    uint32_t v_key;
    pdfmake_obj_t *v;
    const char *value;
    const char *nm;
    const char *tooltip;
    pdfmake_annot_text_t rec;
    uint32_t rect_key;
    pdfmake_obj_t *p;
    uint32_t kids_key;
    pdfmake_obj_t *kids;
    size_t n;
    pdfmake_obj_t *kid;
    if (!field || depth > 32) return;
    arena = rd->parser->doc->arena;
    if (field->kind == PDFMAKE_REF) {
        field = pdfmake_parser_resolve(rd->parser, field->as.ref);
    }
    if (!field || field->kind != PDFMAKE_DICT) return;

    /* Build fully qualified name = parent.T joined with this.T */
    t = dict_get_text(rd, arena, field, "T");
    full_name = t;
    if (parent_name && t) {
        pl = strlen(parent_name);
        tl = strlen(t);
        buf = pdfmake_arena_alloc(arena, pl + 1 + tl + 1);
        if (buf) {
            memcpy(buf, parent_name, pl);
            buf[pl] = '.';
            memcpy(buf + pl + 1, t, tl);
            buf[pl + 1 + tl] = 0;
            full_name = buf;
        }
    } else if (parent_name && !t) {
        full_name = parent_name;
    }

    /* Emit a record for leaf fields that carry a /V (value).  /V can be a
     * string (text, choice) or a name (button state).  Skip anything else. */
    v_key = pdfmake_arena_intern_name(arena, "V", 1);
    v = pdfmake_dict_get(field, v_key);
    if (v && v->kind == PDFMAKE_REF) {
        v = pdfmake_parser_resolve(rd->parser, v->as.ref);
    }
    value = NULL;
    if (v) {
        if (v->kind == PDFMAKE_STR) {
            value = decode_pdf_text(arena, v->as.str.bytes, v->as.str.len);
        } else if (v->kind == PDFMAKE_NAME) {
            nm = pdfmake_get_name_bytes(arena, v);
            if (nm) value = pdfmake_arena_strdup(arena, nm);
        }
    }

    tooltip = dict_get_text(rd, arena, field, "TU");

    /* Fields may be pure intermediaries (have /Kids but no /V/T/TU).  We
     * only emit when there's something to surface. */
    if (value || tooltip) {
        memset(&rec, 0, sizeof(rec));
        rec.kind = "FormField";
        rec.page_index = (size_t)-1;   /* not page-anchored by default */
        rec.text = value ? value : "";
        rec.subject = tooltip;
        rec.field_name = full_name;

        /* If this field is a single-widget field (/Subtype /Widget) it
         * carries a /Rect; otherwise rect stays zero. */
        rect_key = pdfmake_arena_intern_name(arena, "Rect", 4);
        dict_get_rect(field, rect_key, rec.rect);

        /* /P may point at the owning page — use it to stamp page_index. */
        p = dict_get_resolved(rd, arena, field, "P");
        if (p) {
            for (pi = 0; pi < rd->page_count; pi++) {
                if (rd->pages[pi].page_dict == p) {
                    rec.page_index = pi;
                    break;
                }
            }
        }

        annot_list_push(out, &rec);
    }

    kids_key = pdfmake_arena_intern_name(arena, "Kids", 4);
    kids = pdfmake_dict_get(field, kids_key);
    if (kids && kids->kind == PDFMAKE_REF) {
        kids = pdfmake_parser_resolve(rd->parser, kids->as.ref);
    }
    if (kids && kids->kind == PDFMAKE_ARRAY) {
        n = pdfmake_array_len(kids);
        for (i = 0; i < n; i++) {
            kid = pdfmake_array_get(kids, i);
            collect_form_fields(rd, out, kid, full_name, depth + 1);
        }
    }
}

pdfmake_err_t pdfmake_textract_annotations(
    pdfmake_reader_t          *reader,
    pdfmake_annot_text_list_t *out)
{
    size_t i;
    pdfmake_arena_t *arena;
    uint32_t af_key;
    pdfmake_obj_t *af;
    uint32_t fields_key;
    pdfmake_obj_t *fields;
    size_t n;
    if (!reader || !out) return PDFMAKE_EINVAL;
    if (!reader->parser || !reader->parser->doc) return PDFMAKE_EINVAL;

    arena = reader->parser->doc->arena;

    /* Per-page /Annots */
    for (i = 0; i < reader->page_count; i++) {
        collect_page_annots(reader, out, &reader->pages[i], i);
    }

    /* Document-level /AcroForm /Fields */
    if (reader->catalog) {
        af_key = pdfmake_arena_intern_name(arena, "AcroForm", 8);
        af = pdfmake_dict_get(reader->catalog, af_key);
        if (af && af->kind == PDFMAKE_REF) {
            af = pdfmake_parser_resolve(reader->parser, af->as.ref);
        }
        if (af && af->kind == PDFMAKE_DICT) {
            fields_key = pdfmake_arena_intern_name(arena, "Fields", 6);
            fields = pdfmake_dict_get(af, fields_key);
            if (fields && fields->kind == PDFMAKE_REF) {
                fields = pdfmake_parser_resolve(reader->parser, fields->as.ref);
            }
            if (fields && fields->kind == PDFMAKE_ARRAY) {
                n = pdfmake_array_len(fields);
                for (i = 0; i < n; i++) {
                    collect_form_fields(reader, out,
                        pdfmake_array_get(fields, i), NULL, 0);
                }
            }
        }
    }

    return PDFMAKE_OK;
}

/* Forward declaration — definition appears later under UTF-8 output. */
static size_t encode_utf8(uint32_t cp, char *buf);

/*============================================================================
 * Phase 15 — Table detection
 *
 * A page's words already come out sorted into rows via the aggregator, so
 * detection reduces to finding a maximal run of contiguous rows whose
 * column x-positions align within a small tolerance.  Cells are then
 * populated by assigning each word to the column whose center it's closest
 * to, and joining the texts of any words that land in the same cell.
 *==========================================================================*/

pdfmake_textract_table_opts_t pdfmake_textract_table_default_opts(void) {
    pdfmake_textract_table_opts_t o;
    o.min_rows     = 3;
    o.min_cols     = 2;
    o.x_tolerance  = 5.0;
    o.row_tolerance = 0.5;
    return o;
}

pdfmake_textract_table_list_t *pdfmake_textract_table_list_new(pdfmake_arena_t *arena) {
    pdfmake_textract_table_list_t *l = calloc(1, sizeof(*l));
    if (l) l->arena = arena;
    return l;
}

void pdfmake_textract_table_list_free(pdfmake_textract_table_list_t *list) {
    size_t i;
    if (!list) return;
    for (i = 0; i < list->len; i++) {
        free(list->items[i].cells);
        free(list->items[i].cell_x0);
        free(list->items[i].cell_y0);
        free(list->items[i].cell_x1);
        free(list->items[i].cell_y1);
    }
    free(list->items);
    free(list);
}

/* A logical table row built from raw glyphs.  Each entry is one cell
 * (= a group of contiguous glyphs with no large x-gap between them). */
typedef struct {
    double     x0, x1;          /* cell horizontal extent */
    double     y0, y1;          /* cell vertical extent */
    char      *text;            /* arena-owned UTF-8 */
} tcell_t;

typedef struct {
    tcell_t   *cells;
    size_t     ncells;
    size_t     cap;
    double     baseline;
    double     font_size;
} trow_t;

static void trow_push(trow_t *r, const tcell_t *c) {
    if (r->ncells >= r->cap) {
        size_t nc = r->cap == 0 ? 4 : r->cap * 2;
        tcell_t *n = realloc(r->cells, nc * sizeof(*n));
        if (!n) return;
        r->cells = n; r->cap = nc;
    }
    r->cells[r->ncells++] = *c;
}

/* Sort raw glyphs by y desc, then x asc — independent of the column-split
 * based sort used by the main aggregator. */
static int cmp_glyph_row_major(const void *a, const void *b) {
    const pdfmake_text_glyph_t *ga = a;
    const pdfmake_text_glyph_t *gb = b;
    double dy;
    double tol;
    double dx;
    if (ga->vertical != gb->vertical) return ga->vertical ? 1 : -1;
    dy = gb->y0 - ga->y0;
    tol = (ga->font_size > 0 ? ga->font_size : 10.0) * 0.3;
    if (fabs(dy) > tol) return dy > 0 ? 1 : -1;
    dx = ga->x0 - gb->x0;
    if (dx < 0) return -1;
    if (dx > 0) return 1;
    return 0;
}

pdfmake_err_t pdfmake_textract_detect_tables(
    const pdfmake_textract_result_t     *result,
    const pdfmake_textract_table_opts_t *options,
    pdfmake_textract_table_list_t       *out)
{
    size_t i;
    size_t j;
    size_t k;
    size_t r;
    size_t c;
    size_t m;
    pdfmake_textract_table_opts_t opts;
    pdfmake_text_glyph_t *glyphs;
    size_t row_cap;
    size_t nrows;
    trow_t *rows;
    size_t gi;
    double ry;
    double rfs;
    size_t rend;
    size_t nc;
    trow_t *tmp;
    trow_t *rrow;
    size_t cstart;
    int split;
    double gap;
    tcell_t cell;
    pdfmake_buf_t tb;
    char utf8_tmp[4];
    size_t n;
    size_t ncols;
    int ok;
    double dx;
    size_t run;
    pdfmake_textract_table_t t;
    const trow_t *rp;
    const tcell_t *cellp;
    size_t idx;
    pdfmake_textract_table_t *nt;
    if (!result || !out) return PDFMAKE_EINVAL;
    opts = options ? *options : pdfmake_textract_table_default_opts();
    if (result->raw_len == 0) return PDFMAKE_OK;

    /* Work on a private copy of the raw glyphs so we can re-sort without
     * touching the main extraction state (which was sorted by the Phase 10
     * column-aware comparator that would split rows across columns). */
    glyphs = malloc(result->raw_len * sizeof(*glyphs));
    if (!glyphs) return PDFMAKE_ENOMEM;
    memcpy(glyphs, result->raw_glyphs, result->raw_len * sizeof(*glyphs));
    qsort(glyphs, result->raw_len, sizeof(*glyphs), cmp_glyph_row_major);

    /* 1) Cluster glyphs into rows by y.  Within a row, group consecutive
     *    glyphs into cells split on "big" horizontal gaps (≥ 1.5 em).
     *    That keeps "Apple" together while splitting it from "12" sitting
     *    at the next column origin. */
    row_cap = 64;
    nrows = 0;
    rows = calloc(row_cap, sizeof(trow_t));
    if (!rows) { free(glyphs); return PDFMAKE_ENOMEM; }

    gi = 0;
    while (gi < result->raw_len) {
        ry = glyphs[gi].y0;
        rfs = glyphs[gi].font_size > 0 ? glyphs[gi].font_size : 10.0;
        if (glyphs[gi].vertical) { gi++; continue; }

        /* Rows go until baseline jump > row_tolerance × fs. */
        rend = gi + 1;
        while (rend < result->raw_len && !glyphs[rend].vertical &&
               fabs(glyphs[rend].y0 - ry) <= rfs * opts.row_tolerance) {
            rend++;
        }

        /* Grow rows */
        if (nrows >= row_cap) {
            nc = row_cap * 2;
            tmp = realloc(rows, nc * sizeof(trow_t));
            if (!tmp) { free(rows); free(glyphs); return PDFMAKE_ENOMEM; }
            rows = tmp;
            memset(rows + row_cap, 0, (nc - row_cap) * sizeof(trow_t));
            row_cap = nc;
        }
        rrow = &rows[nrows++];
        rrow->baseline = ry;
        rrow->font_size = rfs;

        /* Walk glyphs[gi..rend-1] and split into cells on large x gaps. */
        cstart = gi;
        for (k = gi + 1; k <= rend; k++) {
            split = (k == rend);
            if (!split) {
                gap = glyphs[k].x0 - glyphs[k - 1].x1;
                if (gap > 1.5 * rfs) split = 1;
            }
            if (split) {
                /* Emit a cell from cstart..k-1 */
                memset(&cell, 0, sizeof(cell));
                pdfmake_buf_init(&tb);
                cell.x0 = glyphs[cstart].x0;
                cell.x1 = glyphs[k - 1].x1;
                cell.y0 = glyphs[cstart].y0;
                cell.y1 = glyphs[cstart].y1;
                for (j = cstart; j < k; j++) {
                    n = encode_utf8(glyphs[j].unicode, utf8_tmp);
                    if (glyphs[j].x0 < cell.x0) cell.x0 = glyphs[j].x0;
                    if (glyphs[j].x1 > cell.x1) cell.x1 = glyphs[j].x1;
                    if (glyphs[j].y0 < cell.y0) cell.y0 = glyphs[j].y0;
                    if (glyphs[j].y1 > cell.y1) cell.y1 = glyphs[j].y1;
                    for (m = 0; m < n; m++)
                        pdfmake_buf_append_byte(&tb, utf8_tmp[m]);
                }
                cell.text = pdfmake_arena_alloc(out->arena, tb.len + 1);
                if (cell.text) { memcpy(cell.text, tb.data, tb.len); cell.text[tb.len] = 0; }
                pdfmake_buf_free(&tb);
                trow_push(rrow, &cell);
                cstart = k;
            }
        }
        gi = rend;
    }

    /* 2) Find maximal runs of consecutive rows with matching column layout.
     *    "Same layout" = same cell count AND every cell-origin within
     *    opts.x_tolerance. */
    i = 0;
    while (i < nrows) {
        if (rows[i].ncells < opts.min_cols) { i++; continue; }
        ncols = rows[i].ncells;

        j = i + 1;
        while (j < nrows) {
            if (rows[j].ncells != ncols) break;
            ok = 1;
            for (c = 0; c < ncols; c++) {
                dx = rows[i].cells[c].x0 - rows[j].cells[c].x0;
                if (dx < 0) dx = -dx;
                if (dx > opts.x_tolerance) { ok = 0; break; }
            }
            if (!ok) break;
            j++;
        }

        run = j - i;
        if (run < opts.min_rows) { i = j; continue; }

        /* 3) Emit the table. */
        memset(&t, 0, sizeof(t));
        t.rows = run;
        t.cols = ncols;
        t.cells  = calloc(run * ncols, sizeof(*t.cells));
        t.cell_x0 = calloc(run * ncols, sizeof(double));
        t.cell_y0 = calloc(run * ncols, sizeof(double));
        t.cell_x1 = calloc(run * ncols, sizeof(double));
        t.cell_y1 = calloc(run * ncols, sizeof(double));
        if (!t.cells || !t.cell_x0 || !t.cell_y0 || !t.cell_x1 || !t.cell_y1) {
            free(t.cells); free(t.cell_x0); free(t.cell_y0);
            free(t.cell_x1); free(t.cell_y1);
            for (k = 0; k < nrows; k++) free(rows[k].cells);
            free(rows); free(glyphs);
            return PDFMAKE_ENOMEM;
        }

        t.x0 = t.y0 = 1e18; t.x1 = t.y1 = -1e18;
        for (r = 0; r < run; r++) {
            rp = &rows[i + r];
            for (c = 0; c < ncols; c++) {
                cellp = &rp->cells[c];
                idx = r * ncols + c;
                t.cells[idx]   = cellp->text ? cellp->text : "";
                t.cell_x0[idx] = cellp->x0;
                t.cell_y0[idx] = cellp->y0;
                t.cell_x1[idx] = cellp->x1;
                t.cell_y1[idx] = cellp->y1;
                if (cellp->x0 < t.x0) t.x0 = cellp->x0;
                if (cellp->y0 < t.y0) t.y0 = cellp->y0;
                if (cellp->x1 > t.x1) t.x1 = cellp->x1;
                if (cellp->y1 > t.y1) t.y1 = cellp->y1;
            }
        }

        if (out->len >= out->cap) {
            nc = out->cap == 0 ? 4 : out->cap * 2;
            nt = realloc(out->items, nc * sizeof(*nt));
            if (!nt) {
                free(t.cells); free(t.cell_x0); free(t.cell_y0);
                free(t.cell_x1); free(t.cell_y1);
                for (k = 0; k < nrows; k++) free(rows[k].cells);
                free(rows); free(glyphs);
                return PDFMAKE_ENOMEM;
            }
            out->items = nt; out->cap = nc;
        }
        out->items[out->len++] = t;

        i = j;
    }

    for (k = 0; k < nrows; k++) free(rows[k].cells);
    free(rows);
    free(glyphs);
    return PDFMAKE_OK;
}

/*============================================================================
 * UTF-8 output
 *==========================================================================*/

/* Encode a single Unicode codepoint to UTF-8, return bytes written */
static size_t encode_utf8(uint32_t cp, char *buf) {
    if (cp < 0x80) {
        buf[0] = (char)cp;
        return 1;
    } else if (cp < 0x800) {
        buf[0] = (char)(0xC0 | (cp >> 6));
        buf[1] = (char)(0x80 | (cp & 0x3F));
        return 2;
    } else if (cp < 0x10000) {
        buf[0] = (char)(0xE0 | (cp >> 12));
        buf[1] = (char)(0x80 | ((cp >> 6) & 0x3F));
        buf[2] = (char)(0x80 | (cp & 0x3F));
        return 3;
    } else if (cp < 0x110000) {
        buf[0] = (char)(0xF0 | (cp >> 18));
        buf[1] = (char)(0x80 | ((cp >> 12) & 0x3F));
        buf[2] = (char)(0x80 | ((cp >> 6) & 0x3F));
        buf[3] = (char)(0x80 | (cp & 0x3F));
        return 4;
    }
    return 0;
}

size_t pdfmake_textract_to_utf8(
    const pdfmake_textract_result_t *result,
    char *buf, size_t buf_cap)
{
    size_t bi;
    size_t li;
    size_t wi;
    size_t gi;
    size_t k;
    size_t written;
    const pdfmake_text_block_t *block;
    const pdfmake_text_line_t *line;
    const pdfmake_text_word_t *word;
    size_t n;
    char tmp[4];
    if (!result) return 0;

    written = 0;

    for (bi = 0; bi < result->len; bi++) {
        block = &result->blocks[bi];
        for (li = 0; li < block->len; li++) {
            line = &block->lines[li];
            for (wi = 0; wi < line->len; wi++) {
                word = &line->words[wi];
                if (wi > 0 && written < buf_cap) {
                    buf[written++] = ' '; /* space between words */
                }
                for (gi = 0; gi < word->len; gi++) {
                    n = encode_utf8(word->glyphs[gi].unicode, tmp);
                    for (k = 0; k < n && written < buf_cap; k++) {
                        buf[written++] = tmp[k];
                    }
                }
            }
            /* Newline between lines */
            if (li + 1 < block->len && written < buf_cap) {
                buf[written++] = '\n';
            }
        }
        /* Double newline between blocks */
        if (bi + 1 < result->len && written + 1 < buf_cap) {
            buf[written++] = '\n';
            buf[written++] = '\n';
        }
    }

    /* Null-terminate if room */
    if (written < buf_cap) buf[written] = '\0';

    return written;
}
