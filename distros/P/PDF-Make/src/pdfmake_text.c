/*
 * pdfmake_text.c - Text rendering engine
 *
 * Renders text by converting glyph outlines to paths and filling/stroking
 * using the path rasterizer.
 *
 * Text state management follows PDF spec §9.3
 */

#include "pdfmake_text.h"
#include "pdfmake_font.h"
#include "pdfmake_render.h"
#include "pdfmake_arena.h"
#include <string.h>
#include <math.h>

/*============================================================================
 * Text State Management
 *==========================================================================*/

void pdfmake_text_state_init(pdfmake_text_state_t *ts)
{
    if (!ts) return;
    
    memset(ts, 0, sizeof(*ts));
    
    /* Default values per PDF spec */
    ts->font = NULL;
    ts->font_size = 0.0;
    ts->char_spacing = 0.0;
    ts->word_spacing = 0.0;
    ts->horiz_scale = 1.0;    /* 100% */
    ts->leading = 0.0;
    ts->text_rise = 0.0;
    ts->render_mode = PDFMAKE_TEXT_FILL;
    
    /* Identity text matrix */
    ts->tm[0] = 1.0; ts->tm[1] = 0.0;
    ts->tm[2] = 0.0; ts->tm[3] = 1.0;
    ts->tm[4] = 0.0; ts->tm[5] = 0.0;
    
    /* Identity line matrix */
    ts->tlm[0] = 1.0; ts->tlm[1] = 0.0;
    ts->tlm[2] = 0.0; ts->tlm[3] = 1.0;
    ts->tlm[4] = 0.0; ts->tlm[5] = 0.0;
    
    ts->cache = NULL;
}

void pdfmake_text_state_reset(pdfmake_text_state_t *ts)
{
    pdfmake_glyph_cache_t *cache = ts ? ts->cache : NULL;
    pdfmake_text_state_init(ts);
    if (ts) ts->cache = cache;
}

pdfmake_text_err_t pdfmake_text_set_font(
    pdfmake_text_state_t *ts,
    pdfmake_font_t *font,
    double size,
    pdfmake_arena_t *arena)
{
    if (!ts || !font) return PDFMAKE_TEXT_ERR_NULL;
    
    ts->font = font;
    ts->font_size = size;
    
    /* Create or reuse glyph cache */
    if (!ts->cache || ts->cache->glyph_count == 0) {
        ts->cache = pdfmake_glyph_cache_create(font, arena);
        if (!ts->cache) return PDFMAKE_TEXT_ERR_MEMORY;
    }
    
    return PDFMAKE_TEXT_OK;
}

void pdfmake_text_set_matrix(pdfmake_text_state_t *ts,
                              double a, double b, double c, double d,
                              double e, double f)
{
    if (!ts) return;
    
    ts->tm[0] = a; ts->tm[1] = b;
    ts->tm[2] = c; ts->tm[3] = d;
    ts->tm[4] = e; ts->tm[5] = f;
    
    /* Also set line matrix (Tm sets both) */
    ts->tlm[0] = a; ts->tlm[1] = b;
    ts->tlm[2] = c; ts->tlm[3] = d;
    ts->tlm[4] = e; ts->tlm[5] = f;
}

void pdfmake_text_next_line(pdfmake_text_state_t *ts)
{
    if (!ts) return;
    
    /* T* is equivalent to: 0 -TL Td */
    pdfmake_text_move(ts, 0, -ts->leading);
}

void pdfmake_text_move(pdfmake_text_state_t *ts, double tx, double ty)
{
    double e, f;
    if (!ts) return;
    
    /* Translate line matrix: Tlm' = [1 0 0 1 tx ty] * Tlm */
    e = ts->tlm[4] + tx * ts->tlm[0] + ty * ts->tlm[2];
    f = ts->tlm[5] + tx * ts->tlm[1] + ty * ts->tlm[3];
    
    ts->tlm[4] = e;
    ts->tlm[5] = f;
    
    /* Reset text matrix to line matrix */
    memcpy(ts->tm, ts->tlm, sizeof(ts->tm));
}

/*============================================================================
 * Matrix Utilities
 *==========================================================================*/

void pdfmake_text_combined_matrix(
    pdfmake_text_state_t *ts,
    pdfmake_render_ctx_t *ctx,
    double out[6])
{
    double ctm[6];
    if (!ts || !out) return;
    
    /* Get CTM from render context */
    ctm[0] = 1; ctm[1] = 0;
    ctm[2] = 0; ctm[3] = 1;
    ctm[4] = 0; ctm[5] = 0;
    if (ctx) {
        ctm[0] = ctx->ctm.a; ctm[1] = ctx->ctm.b;
        ctm[2] = ctx->ctm.c; ctm[3] = ctx->ctm.d;
        ctm[4] = ctx->ctm.e; ctm[5] = ctx->ctm.f;
    }
    
    /* Combined = Tm * CTM */
    out[0] = ts->tm[0] * ctm[0] + ts->tm[1] * ctm[2];
    out[1] = ts->tm[0] * ctm[1] + ts->tm[1] * ctm[3];
    out[2] = ts->tm[2] * ctm[0] + ts->tm[3] * ctm[2];
    out[3] = ts->tm[2] * ctm[1] + ts->tm[3] * ctm[3];
    out[4] = ts->tm[4] * ctm[0] + ts->tm[5] * ctm[2] + ctm[4];
    out[5] = ts->tm[4] * ctm[1] + ts->tm[5] * ctm[3] + ctm[5];
}

/*
 * Build glyph rendering matrix.
 * Transforms from glyph space (font units) to device space.
 */
static void build_glyph_matrix(
    pdfmake_text_state_t *ts,
    pdfmake_render_ctx_t *ctx,
    double out[6])
{
    int units_per_em;
    double scale;
    double hscale;
    double gm[6];
    double tm_gm[6];
    double ctm[6];
    if (!ts || !out) return;
    
    /* Get units per em from font */
    units_per_em = 1000;
    if (ts->font) {
        if (ts->font->type == PDFMAKE_FONT_TRUETYPE ||
            ts->font->type == PDFMAKE_FONT_CID_TRUETYPE) {
            if (ts->font->ttf) {
                units_per_em = ts->font->ttf->units_per_em;
            }
        }
    }
    
    /* Scale factor: font_size / units_per_em */
    scale = ts->font_size / units_per_em;
    
    /* Apply horizontal scaling */
    hscale = ts->horiz_scale;
    
    /* Glyph matrix = [scale*hscale 0 0 scale 0 rise] * Tm * CTM */
    gm[0] = scale * hscale;
    gm[1] = 0;
    gm[2] = 0;
    gm[3] = scale;
    gm[4] = 0;
    gm[5] = ts->text_rise;
    
    /* Multiply by text matrix */
    tm_gm[0] = gm[0] * ts->tm[0] + gm[1] * ts->tm[2];
    tm_gm[1] = gm[0] * ts->tm[1] + gm[1] * ts->tm[3];
    tm_gm[2] = gm[2] * ts->tm[0] + gm[3] * ts->tm[2];
    tm_gm[3] = gm[2] * ts->tm[1] + gm[3] * ts->tm[3];
    tm_gm[4] = gm[4] * ts->tm[0] + gm[5] * ts->tm[2] + ts->tm[4];
    tm_gm[5] = gm[4] * ts->tm[1] + gm[5] * ts->tm[3] + ts->tm[5];
    
    /* Multiply by CTM */
    ctm[0] = 1; ctm[1] = 0;
    ctm[2] = 0; ctm[3] = 1;
    ctm[4] = 0; ctm[5] = 0;
    if (ctx) {
        ctm[0] = ctx->ctm.a; ctm[1] = ctx->ctm.b;
        ctm[2] = ctx->ctm.c; ctm[3] = ctx->ctm.d;
        ctm[4] = ctx->ctm.e; ctm[5] = ctx->ctm.f;
    }

    out[0] = tm_gm[0] * ctm[0] + tm_gm[1] * ctm[2];
    out[1] = tm_gm[0] * ctm[1] + tm_gm[1] * ctm[3];
    out[2] = tm_gm[2] * ctm[0] + tm_gm[3] * ctm[2];
    out[3] = tm_gm[2] * ctm[1] + tm_gm[3] * ctm[3];
    out[4] = tm_gm[4] * ctm[0] + tm_gm[5] * ctm[2] + ctm[4];
    out[5] = tm_gm[4] * ctm[1] + tm_gm[5] * ctm[3] + ctm[5];
}

/*
 * Update text position after rendering a glyph.
 */
static void update_text_position(
    pdfmake_text_state_t *ts,
    double advance_width,
    int is_space)
{
    double tx;
    if (!ts) return;
    
    /* Total displacement */
    tx = advance_width;
    tx += ts->char_spacing;
    
    if (is_space) {
        tx += ts->word_spacing;
    }
    
    /* Apply horizontal scaling */
    tx *= ts->horiz_scale;
    
    /* Update text matrix: translate by tx in text space */
    ts->tm[4] += tx * ts->tm[0];
    ts->tm[5] += tx * ts->tm[1];
}

/*============================================================================
 * UTF-8 Decoding
 *==========================================================================*/

static uint32_t utf8_decode_char(const uint8_t **p, const uint8_t *end)
{
    uint8_t c;
    uint8_t c2, c3, c4;
    if (*p >= end) return 0xFFFD;
    
    c = *(*p)++;
    
    if (c < 0x80) {
        return c;
    }
    
    if ((c & 0xE0) == 0xC0) {
        if (*p >= end) return 0xFFFD;
        c2 = *(*p)++;
        if ((c2 & 0xC0) != 0x80) return 0xFFFD;
        return ((c & 0x1F) << 6) | (c2 & 0x3F);
    }
    
    if ((c & 0xF0) == 0xE0) {
        if (*p + 1 >= end) return 0xFFFD;
        c2 = *(*p)++;
        c3 = *(*p)++;
        if ((c2 & 0xC0) != 0x80 || (c3 & 0xC0) != 0x80) return 0xFFFD;
        return ((c & 0x0F) << 12) | ((c2 & 0x3F) << 6) | (c3 & 0x3F);
    }
    
    if ((c & 0xF8) == 0xF0) {
        if (*p + 2 >= end) return 0xFFFD;
        c2 = *(*p)++;
        c3 = *(*p)++;
        c4 = *(*p)++;
        if ((c2 & 0xC0) != 0x80 || (c3 & 0xC0) != 0x80 ||
            (c4 & 0xC0) != 0x80) return 0xFFFD;
        return ((c & 0x07) << 18) | ((c2 & 0x3F) << 12) |
               ((c3 & 0x3F) << 6) | (c4 & 0x3F);
    }
    
    return 0xFFFD;
}

/*============================================================================
 * Glyph Rendering
 *==========================================================================*/

pdfmake_text_err_t pdfmake_render_glyph(
    pdfmake_render_ctx_t *ctx,
    pdfmake_text_state_t *ts,
    uint16_t glyph_id)
{
    pdfmake_glyph_outline_t *outline;
    double advance;
    double scaled_advance;
    int units_per_em;
    if (!ctx || !ts || !ts->font) return PDFMAKE_TEXT_ERR_NULL;
    if (!ts->cache) return PDFMAKE_TEXT_ERR_INVALID_FONT;
    
    /* Get glyph outline */
    outline = pdfmake_glyph_get(
        ts->cache, ts->font, glyph_id);
    
    if (!outline) {
        /* Unknown glyph - use .notdef (glyph 0) */
        outline = pdfmake_glyph_get(ts->cache, ts->font, 0);
    }
    
    /* Invisible mode - just update position */
    if (ts->render_mode == PDFMAKE_TEXT_INVISIBLE) {
        double inv_advance = pdfmake_text_glyph_advance(
            ts->font, glyph_id, ts->font_size);
        update_text_position(ts, inv_advance, 0);
        return PDFMAKE_TEXT_OK;
    }
    
    /* Render if we have an outline */
    if (outline && outline->path && outline->path->seg_count > 0) {
        /* Build transformation matrix */
        double glyph_matrix[6];
        pdfmake_arena_t *arena;
        pdfmake_path_t *transformed;
        int do_fill;
        int do_stroke;
        int do_clip;
        build_glyph_matrix(ts, ctx, glyph_matrix);
        
        /* Transform glyph path */
        arena = ts->cache->arena;
        transformed = pdfmake_path_transform_copy(
            outline->path, glyph_matrix, arena);
        
        if (transformed) {
            /* Apply based on render mode */
            do_fill = (ts->render_mode == PDFMAKE_TEXT_FILL ||
                          ts->render_mode == PDFMAKE_TEXT_FILL_STROKE ||
                          ts->render_mode == PDFMAKE_TEXT_FILL_CLIP ||
                          ts->render_mode == PDFMAKE_TEXT_FILL_STROKE_CLIP);
            
            do_stroke = (ts->render_mode == PDFMAKE_TEXT_STROKE ||
                            ts->render_mode == PDFMAKE_TEXT_FILL_STROKE ||
                            ts->render_mode == PDFMAKE_TEXT_STROKE_CLIP ||
                            ts->render_mode == PDFMAKE_TEXT_FILL_STROKE_CLIP);
            
            do_clip = (ts->render_mode == PDFMAKE_TEXT_FILL_CLIP ||
                          ts->render_mode == PDFMAKE_TEXT_STROKE_CLIP ||
                          ts->render_mode == PDFMAKE_TEXT_FILL_STROKE_CLIP ||
                          ts->render_mode == PDFMAKE_TEXT_CLIP);
            
            /* Fill */
            if (do_fill) {
                pdfmake_fill_path(ctx, transformed, PDFMAKE_FILL_NONZERO);
            }
            
            /* Stroke */
            if (do_stroke) {
                pdfmake_stroke_path(ctx, transformed, NULL);
            }
            
            /* Clip */
            if (do_clip) {
                pdfmake_clip_path(ctx, transformed, PDFMAKE_FILL_NONZERO);
            }
        }
    }
    
    /* Update text position */
    advance = outline ? outline->advance_width : 0;
    scaled_advance = (advance * ts->font_size);
    
    /* Get units per em */
    units_per_em = 1000;
    if (ts->font->type == PDFMAKE_FONT_TRUETYPE ||
        ts->font->type == PDFMAKE_FONT_CID_TRUETYPE) {
        if (ts->font->ttf) {
            units_per_em = ts->font->ttf->units_per_em;
        }
    }
    
    scaled_advance /= units_per_em;
    update_text_position(ts, scaled_advance, 0);
    
    return PDFMAKE_TEXT_OK;
}

/*============================================================================
 * Text String Rendering
 *==========================================================================*/

pdfmake_text_err_t pdfmake_render_text(
    pdfmake_render_ctx_t *ctx,
    pdfmake_text_state_t *ts,
    const uint8_t *text,
    size_t len)
{
    size_t i;
    if (!ctx || !ts || !text) return PDFMAKE_TEXT_ERR_NULL;
    if (!ts->font) return PDFMAKE_TEXT_ERR_INVALID_FONT;
    
    /* Process each byte as character code */
    for (i = 0; i < len; i++) {
        uint8_t charcode = text[i];
        
        /* Map char code to glyph */
        uint16_t glyph_id = pdfmake_text_char_to_glyph(ts->font, charcode);
        
        /* Check for space */
        int is_space = (charcode == 0x20);
        
        /* Render glyph */
        pdfmake_text_err_t err = pdfmake_render_glyph(ctx, ts, glyph_id);
        if (err != PDFMAKE_TEXT_OK) return err;
        
        /* Add word spacing for space character */
        if (is_space) {
            double ws = ts->word_spacing * ts->horiz_scale;
            ts->tm[4] += ws * ts->tm[0];
            ts->tm[5] += ws * ts->tm[1];
        }
    }
    
    return PDFMAKE_TEXT_OK;
}

pdfmake_text_err_t pdfmake_render_text_utf8(
    pdfmake_render_ctx_t *ctx,
    pdfmake_text_state_t *ts,
    const char *text,
    size_t len)
{
    const uint8_t *p;
    const uint8_t *end;
    if (!ctx || !ts || !text) return PDFMAKE_TEXT_ERR_NULL;
    if (!ts->font) return PDFMAKE_TEXT_ERR_INVALID_FONT;
    
    p = (const uint8_t *)text;
    end = p + len;
    
    while (p < end) {
        uint32_t unicode = utf8_decode_char(&p, end);
        uint16_t glyph_id;
        int is_space;
        pdfmake_text_err_t err;
        if (unicode == 0xFFFD) continue;
        
        /* Map Unicode to glyph */
        glyph_id = pdfmake_text_unicode_to_glyph(ts->font, unicode);
        
        /* Check for space */
        is_space = (unicode == 0x0020);
        
        /* Render glyph */
        err = pdfmake_render_glyph(ctx, ts, glyph_id);
        if (err != PDFMAKE_TEXT_OK) return err;
        
        /* Add word spacing for space character */
        if (is_space) {
            double ws = ts->word_spacing * ts->horiz_scale;
            ts->tm[4] += ws * ts->tm[0];
            ts->tm[5] += ws * ts->tm[1];
        }
    }
    
    return PDFMAKE_TEXT_OK;
}

pdfmake_text_err_t pdfmake_render_text_positioned(
    pdfmake_render_ctx_t *ctx,
    pdfmake_text_state_t *ts,
    const pdfmake_text_element_t *elements,
    size_t count)
{
    size_t i;
    if (!ctx || !ts || !elements) return PDFMAKE_TEXT_ERR_NULL;
    if (!ts->font) return PDFMAKE_TEXT_ERR_INVALID_FONT;
    
    for (i = 0; i < count; i++) {
        const pdfmake_text_element_t *elem = &elements[i];
        
        if (elem->type == PDFMAKE_TEXT_ELEM_STRING) {
            /* Render text string */
            pdfmake_text_err_t err = pdfmake_render_text(
                ctx, ts, elem->u.string.data, elem->u.string.len);
            if (err != PDFMAKE_TEXT_OK) return err;
        } else if (elem->type == PDFMAKE_TEXT_ELEM_ADJUST) {
            /* Position adjustment */
            /* Negative value moves right, positive moves left */
            /* Value is in 1/1000 of text space units */
            double adjust = -elem->u.adjust / 1000.0 * ts->font_size;
            adjust *= ts->horiz_scale;
            
            ts->tm[4] += adjust * ts->tm[0];
            ts->tm[5] += adjust * ts->tm[1];
        }
    }
    
    return PDFMAKE_TEXT_OK;
}

/*============================================================================
 * Convenience Functions
 *==========================================================================*/

/*
 * Render text at a specific position.
 * Sets text matrix and renders.
 */
pdfmake_text_err_t pdfmake_render_text_at(
    pdfmake_render_ctx_t *ctx,
    pdfmake_text_state_t *ts,
    double x, double y,
    const char *text,
    size_t len)
{
    if (!ctx || !ts || !text) return PDFMAKE_TEXT_ERR_NULL;
    
    /* Set text matrix to position */
    pdfmake_text_set_matrix(ts, 1, 0, 0, 1, x, y);
    
    /* Render UTF-8 text */
    return pdfmake_render_text_utf8(ctx, ts, text, len);
}

/*
 * Get text bounding box (approximate).
 * Returns the width and uses font metrics for height.
 */
void pdfmake_text_bbox(
    pdfmake_text_state_t *ts,
    const char *text,
    size_t len,
    double *out_width,
    double *out_height,
    double *out_descent)
{
    double width;
    const pdfmake_font_metrics_t *metrics;
    if (!ts || !ts->font || !text) {
        if (out_width) *out_width = 0;
        if (out_height) *out_height = 0;
        if (out_descent) *out_descent = 0;
        return;
    }
    
    /* Calculate width */
    width = pdfmake_text_string_width(ts, (const uint8_t *)text, len);
    if (out_width) *out_width = width;
    
    /* Get font metrics */
    metrics = pdfmake_font_metrics(ts->font);
    
    if (metrics) {
        double scale = ts->font_size / 1000.0;
        
        if (out_height) {
            *out_height = (metrics->ascent - metrics->descent) * scale;
        }
        if (out_descent) {
            *out_descent = metrics->descent * scale; /* Negative value */
        }
    } else {
        /* Fallback estimates */
        if (out_height) *out_height = ts->font_size;
        if (out_descent) *out_descent = -ts->font_size * 0.2;
    }
}
