/*
 * pdfmake_font.c - Font management implementation
 *
 * Implements Standard 14 font constructor, TrueType font loading,
 * width calculations, and PDF output.
 */

#include "pdfmake_font.h"
#include "pdfmake_arena.h"
#include <string.h>
#include <stdlib.h>
#include <strings.h>

/*============================================================================
 * Standard 14 font constructor
 *==========================================================================*/

pdfmake_font_t *pdfmake_font_standard14(pdfmake_arena_t *arena, const char *base_font) {
    int id;
    const pdfmake_std14_data_t *data;
    pdfmake_font_t *font;

    if (!arena || !base_font) return NULL;

    /* Look up by name */
    id = pdfmake_std14_lookup(base_font);
    if (id < 0) return NULL;

    data = pdfmake_std14_get(id);
    if (!data) return NULL;

    font = pdfmake_arena_alloc(arena, sizeof(pdfmake_font_t));
    if (!font) return NULL;
    memset(font, 0, sizeof(pdfmake_font_t));

    font->arena = arena;
    font->type = PDFMAKE_FONT_TYPE1;
    font->std14_id = id;
    font->base_font = data->name;
    font->metrics = data->metrics;
    font->ttf = NULL;

    return font;
}

/*============================================================================
 * Font destructor
 *==========================================================================*/

void pdfmake_font_free(pdfmake_font_t *font) {
    /* Fonts are arena-allocated, nothing to free */
    (void)font;
}

/*============================================================================
 * Width calculations
 *==========================================================================*/

double pdfmake_font_advance(const pdfmake_font_t *font, uint32_t codepoint, double font_size) {
    int width_units = 0;

    if (!font) return 0;

    switch (font->type) {
        case PDFMAKE_FONT_TYPE1:
            /* Standard 14 font - use std14 width table */
            width_units = pdfmake_std14_width(font->std14_id, codepoint);
            break;

        case PDFMAKE_FONT_TRUETYPE:
        case PDFMAKE_FONT_CID_TRUETYPE:
            /* TrueType font - lookup in TTF */
            if (font->ttf) {
                uint16_t glyph = pdfmake_ttf_cmap_lookup(font->ttf, codepoint);
                width_units = pdfmake_ttf_glyph_advance(font->ttf, glyph);
            }
            break;
    }

    /* Convert from 1/1000 em to PDF points */
    return (width_units * font_size) / 1000.0;
}

double pdfmake_font_string_width(const pdfmake_font_t *font, const char *utf8, 
                                  size_t len, double font_size) {
    double total = 0;
    const uint8_t *p;
    const uint8_t *end;

    if (!font || !utf8) return 0;

    p = (const uint8_t *)utf8;
    end = p + len;

    while (p < end) {
        uint32_t cp;
        
        /* Decode UTF-8 */
        if ((*p & 0x80) == 0) {
            cp = *p++;
        } else if ((*p & 0xE0) == 0xC0) {
            if (p + 1 >= end) break;
            cp = (*p++ & 0x1F) << 6;
            cp |= (*p++ & 0x3F);
        } else if ((*p & 0xF0) == 0xE0) {
            if (p + 2 >= end) break;
            cp = (*p++ & 0x0F) << 12;
            cp |= (*p++ & 0x3F) << 6;
            cp |= (*p++ & 0x3F);
        } else if ((*p & 0xF8) == 0xF0) {
            if (p + 3 >= end) break;
            cp = (*p++ & 0x07) << 18;
            cp |= (*p++ & 0x3F) << 12;
            cp |= (*p++ & 0x3F) << 6;
            cp |= (*p++ & 0x3F);
        } else {
            /* Invalid UTF-8, skip byte */
            p++;
            continue;
        }
        
        total += pdfmake_font_advance(font, cp, font_size);
    }
    
    return total;
}

const pdfmake_font_metrics_t *pdfmake_font_metrics(const pdfmake_font_t *font) {
    if (!font) return NULL;
    return &font->metrics;
}

/*============================================================================
 * TrueType font creation
 *==========================================================================*/

pdfmake_font_t *pdfmake_font_from_ttf(pdfmake_arena_t *arena, 
                                       const uint8_t *ttf_bytes, size_t len) {
    pdfmake_ttf_t *ttf;
    pdfmake_font_t *font;
    int upm;
    pdfmake_font_metrics_t *m;

    if (!arena || !ttf_bytes || len == 0) return NULL;

    ttf = pdfmake_ttf_parse(arena, ttf_bytes, len);
    if (!ttf) return NULL;

    font = pdfmake_arena_alloc(arena, sizeof(pdfmake_font_t));
    if (!font) return NULL;
    memset(font, 0, sizeof(pdfmake_font_t));

    font->arena = arena;
    font->type = PDFMAKE_FONT_TRUETYPE;
    font->std14_id = -1;
    font->ttf = ttf;

    /* Derive metrics from TTF */
    upm = ttf->units_per_em > 0 ? ttf->units_per_em : 1000;
    m = &font->metrics;

    m->ascent = (ttf->ascender * 1000) / upm;
    m->descent = (ttf->descender * 1000) / upm;
    
    if (ttf->has_os2) {
        m->cap_height = ttf->s_cap_height > 0 ? (ttf->s_cap_height * 1000) / upm : m->ascent;
        m->x_height = ttf->s_x_height > 0 ? (ttf->s_x_height * 1000) / upm : m->cap_height * 7 / 10;
    } else {
        m->cap_height = m->ascent;
        m->x_height = m->cap_height * 7 / 10;
    }
    
    m->stem_v = 80;
    m->stem_h = 80;
    m->bbox[0] = (ttf->x_min * 1000) / upm;
    m->bbox[1] = (ttf->y_min * 1000) / upm;
    m->bbox[2] = (ttf->x_max * 1000) / upm;
    m->bbox[3] = (ttf->y_max * 1000) / upm;
    m->flags = PDFMAKE_FONT_FLAG_NONSYMBOLIC;
    
    return font;
}
