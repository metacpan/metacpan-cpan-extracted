/*
 * pdfmake_font_glyph.c - Glyph outline caching and loading
 *
 * Manages glyph outline extraction from TrueType and CFF fonts.
 * Caches loaded outlines for efficient text rendering.
 */

#include "pdfmake_text.h"
#include "pdfmake_font.h"
#include "pdfmake_render.h"
#include "pdfmake_arena.h"
#include "pdfmake_internal.h"
#include <string.h>
#include <stdlib.h>

/*============================================================================
 * Glyph Cache Management
 *==========================================================================*/

pdfmake_glyph_cache_t *pdfmake_glyph_cache_create(
    pdfmake_font_t *font,
    pdfmake_arena_t *arena)
{
    pdfmake_glyph_cache_t *cache;
    size_t glyph_count;

    if (!font || !arena) return NULL;
    
    cache = pdfmake_arena_alloc(arena, 
        sizeof(pdfmake_glyph_cache_t));
    if (!cache) return NULL;
    
    /* Get glyph count from font */
    glyph_count = 0;
    if (font->type == PDFMAKE_FONT_TRUETYPE || 
        font->type == PDFMAKE_FONT_CID_TRUETYPE) {
        if (font->ttf) {
            glyph_count = font->ttf->num_glyphs;
        }
    } else {
        /* Standard 14 fonts - use 256 as max char code */
        glyph_count = 256;
    }
    
    if (glyph_count == 0) {
        glyph_count = 256; /* Fallback */
    }
    
    cache->glyph_count = glyph_count;
    cache->loaded_count = 0;
    cache->arena = arena;
    
    /* Allocate glyph array */
    cache->glyphs = pdfmake_arena_alloc(arena, 
        glyph_count * sizeof(pdfmake_glyph_outline_t));
    if (!cache->glyphs) return NULL;
    
    /* Initialize all glyphs as unloaded */
    memset(cache->glyphs, 0, glyph_count * sizeof(pdfmake_glyph_outline_t));
    
    return cache;
}

void pdfmake_glyph_cache_free(pdfmake_glyph_cache_t *cache)
{
    size_t i;
    /* If using arena, paths are freed with arena */
    /* This is mainly for non-arena cleanup */
    if (!cache) return;
    
    if (cache->glyphs && !cache->arena) {
        for (i = 0; i < cache->glyph_count; i++) {
            if (cache->glyphs[i].path) {
                pdfmake_path_destroy(cache->glyphs[i].path);
            }
        }
        free(cache->glyphs);
    }
}

pdfmake_glyph_outline_t *pdfmake_glyph_get(
    pdfmake_glyph_cache_t *cache,
    pdfmake_font_t *font,
    uint16_t glyph_id)
{
    pdfmake_glyph_outline_t *outline;

    if (!cache || !font) return NULL;
    if (glyph_id >= cache->glyph_count) return NULL;
    
    outline = &cache->glyphs[glyph_id];
    
    /* Load if not already loaded */
    if (!outline->loaded) {
        pdfmake_text_err_t err = pdfmake_glyph_load(cache, font, glyph_id);
        if (err != PDFMAKE_TEXT_OK) {
            /* Mark as loaded but empty to avoid repeated attempts */
            outline->loaded = 1;
            outline->path = NULL;
        }
    }
    
    return outline;
}

pdfmake_text_err_t pdfmake_glyph_load(
    pdfmake_glyph_cache_t *cache,
    pdfmake_font_t *font,
    uint16_t glyph_id)
{
    pdfmake_glyph_outline_t *outline;
    pdfmake_text_err_t err;

    if (!cache || !font) return PDFMAKE_TEXT_ERR_NULL;
    if (glyph_id >= cache->glyph_count) return PDFMAKE_TEXT_ERR_GLYPH_NOT_FOUND;
    
    outline = &cache->glyphs[glyph_id];
    
    /* Already loaded? */
    if (outline->loaded) return PDFMAKE_TEXT_OK;
    
    outline->glyph_id = glyph_id;
    
    /* Load based on font type */
    switch (font->type) {
        case PDFMAKE_FONT_TRUETYPE:
        case PDFMAKE_FONT_CID_TRUETYPE:
            err = pdfmake_ttf_load_glyph(outline, font, glyph_id, cache->arena);
            break;
            
        case PDFMAKE_FONT_TYPE1:
            /* Standard 14 fonts don't have glyph outlines in data */
            /* Would need substitution font - return empty for now */
            outline->loaded = 1;
            outline->path = NULL;
            outline->advance_width = pdfmake_std14_width(font->std14_id, glyph_id);
            err = PDFMAKE_TEXT_OK;
            break;
            
        default:
            err = PDFMAKE_TEXT_ERR_UNSUPPORTED;
            break;
    }
    
    if (err == PDFMAKE_TEXT_OK) {
        outline->loaded = 1;
        cache->loaded_count++;
    }
    
    return err;
}

/*============================================================================
 * TrueType Glyph Loading
 *==========================================================================*/

/* TrueType glyf flags */
#define TTF_ON_CURVE        0x01
#define TTF_X_SHORT         0x02
#define TTF_Y_SHORT         0x04
#define TTF_REPEAT          0x08
#define TTF_X_SAME          0x10
#define TTF_Y_SAME          0x20

/* Composite glyph flags */
#define TTF_ARG_1_AND_2_ARE_WORDS    0x0001
#define TTF_ARGS_ARE_XY_VALUES       0x0002
#define TTF_ROUND_XY_TO_GRID         0x0004
#define TTF_WE_HAVE_A_SCALE          0x0008
#define TTF_MORE_COMPONENTS          0x0020
#define TTF_WE_HAVE_AN_X_AND_Y_SCALE 0x0040
#define TTF_WE_HAVE_A_TWO_BY_TWO     0x0080
#define TTF_WE_HAVE_INSTRUCTIONS     0x0100
#define TTF_USE_MY_METRICS           0x0200

/*
 * Get glyph data offset from loca table.
 */
static size_t get_glyph_offset(pdfmake_font_t *font, uint16_t glyph_id, 
                                size_t *out_len)
{
    pdfmake_ttf_t *ttf = font->ttf;
    const uint8_t *loca;
    size_t offset, next_offset;

    if (!ttf || glyph_id >= ttf->num_glyphs) return 0;
    
    loca = ttf->data + ttf->loca.offset;
    
    if (ttf->index_to_loc_format == 0) {
        /* Short format: offset / 2 stored as uint16 */
        offset = pdfmake_read_be16(loca + glyph_id * 2) * 2;
        next_offset = pdfmake_read_be16(loca + (glyph_id + 1) * 2) * 2;
    } else {
        /* Long format: offset stored as uint32 */
        offset = pdfmake_read_be32(loca + glyph_id * 4);
        next_offset = pdfmake_read_be32(loca + (glyph_id + 1) * 4);
    }
    
    if (out_len) {
        *out_len = next_offset - offset;
    }
    
    return offset;
}

/*
 * Convert quadratic Bezier (P0, P1, P2) to cubic (P0, C1, C2, P3).
 * C1 = P0 + 2/3 * (P1 - P0)
 * C2 = P2 + 2/3 * (P1 - P2)
 */
static void quadratic_to_cubic(
    double x0, double y0,   /* P0 - start point */
    double x1, double y1,   /* P1 - control point */
    double x2, double y2,   /* P2 - end point */
    double *cx1, double *cy1,   /* C1 - first cubic control */
    double *cx2, double *cy2)   /* C2 - second cubic control */
{
    *cx1 = x0 + (2.0/3.0) * (x1 - x0);
    *cy1 = y0 + (2.0/3.0) * (y1 - y0);
    *cx2 = x2 + (2.0/3.0) * (x1 - x2);
    *cy2 = y2 + (2.0/3.0) * (y1 - y2);
}

pdfmake_text_err_t pdfmake_ttf_load_glyph(
    pdfmake_glyph_outline_t *outline,
    pdfmake_font_t *font,
    uint16_t glyph_id,
    pdfmake_arena_t *arena)
{
    pdfmake_ttf_t *ttf;
    size_t glyph_len;
    size_t glyph_offset;
    const uint8_t *glyph_data;
    const uint8_t *end;
    int16_t num_contours;
    const uint8_t *p;
    pdfmake_path_t *path;
    uint16_t *end_pts;
    uint16_t i;
    uint16_t num_points;
    uint16_t inst_len;
    uint8_t *flags;
    uint8_t flag;
    uint8_t repeat;
    uint8_t j;
    int16_t *x_coords;
    int16_t *y_coords;
    int16_t x;
    int16_t y;
    int16_t dx;
    int16_t dy;
    uint16_t pt;
    int c;
    uint16_t contour_end;
    uint16_t contour_start;
    uint16_t contour_len;
    int first_on;
    uint16_t idx;
    uint16_t next_idx;
    uint16_t start_idx;
    double cx, cy;
    double nx, ny;
    double ex, ey;
    double mx, my;
    double x0, y0;
    double c1x, c1y, c2x, c2y;
    int on_curve;
    int next_on;

    if (!outline || !font || !font->ttf || !arena) {
        return PDFMAKE_TEXT_ERR_NULL;
    }
    
    ttf = font->ttf;
    
    /* Get glyph metrics first */
    outline->advance_width = pdfmake_ttf_glyph_advance(ttf, glyph_id);
    
    /* Get glyph data location */
    glyph_offset = get_glyph_offset(font, glyph_id, &glyph_len);
    
    if (glyph_len == 0) {
        /* Empty glyph (e.g., space) */
        outline->path = NULL;
        outline->x_min = outline->y_min = outline->x_max = outline->y_max = 0;
        return PDFMAKE_TEXT_OK;
    }
    
    glyph_data = ttf->data + ttf->glyf.offset + glyph_offset;
    end = glyph_data + glyph_len;
    
    /* Read glyph header */
    if (glyph_len < 10) return PDFMAKE_TEXT_ERR_PARSE_ERROR;
    
    num_contours = pdfmake_read_sbe16(glyph_data);
    outline->x_min = pdfmake_read_sbe16(glyph_data + 2);
    outline->y_min = pdfmake_read_sbe16(glyph_data + 4);
    outline->x_max = pdfmake_read_sbe16(glyph_data + 6);
    outline->y_max = pdfmake_read_sbe16(glyph_data + 8);
    
    p = glyph_data + 10;
    
    if (num_contours < 0) {
        /* Composite glyph */
        outline->composite = 1;
        /* For now, return empty path - composite handling is complex */
        outline->path = NULL;
        return PDFMAKE_TEXT_OK;
    }
    
    if (num_contours == 0) {
        /* No outlines */
        outline->path = NULL;
        return PDFMAKE_TEXT_OK;
    }
    
    /* Create path */
    path = pdfmake_path_create();
    if (!path) return PDFMAKE_TEXT_ERR_MEMORY;
    
    /* Read end points of each contour */
    if (p + num_contours * 2 > end) return PDFMAKE_TEXT_ERR_PARSE_ERROR;
    
    end_pts = pdfmake_arena_alloc(arena, num_contours * sizeof(uint16_t));
    if (!end_pts) return PDFMAKE_TEXT_ERR_MEMORY;
    
    for (i = 0; i < num_contours; i++) {
        end_pts[i] = pdfmake_read_be16(p);
        p += 2;
    }
    
    num_points = end_pts[num_contours - 1] + 1;
    
    /* Skip instructions */
    if (p + 2 > end) return PDFMAKE_TEXT_ERR_PARSE_ERROR;
    inst_len = pdfmake_read_be16(p);
    p += 2 + inst_len;
    
    if (p > end) return PDFMAKE_TEXT_ERR_PARSE_ERROR;
    
    /* Read flags */
    flags = pdfmake_arena_alloc(arena, num_points);
    if (!flags) return PDFMAKE_TEXT_ERR_MEMORY;
    
    for (i = 0; i < num_points; ) {
        if (p >= end) return PDFMAKE_TEXT_ERR_PARSE_ERROR;
        flag = *p++;
        flags[i++] = flag;
        
        if (flag & TTF_REPEAT) {
            if (p >= end) return PDFMAKE_TEXT_ERR_PARSE_ERROR;
            repeat = *p++;
            for (j = 0; j < repeat && i < num_points; j++) {
                flags[i++] = flag;
            }
        }
    }
    
    /* Read X coordinates */
    x_coords = pdfmake_arena_alloc(arena, num_points * sizeof(int16_t));
    if (!x_coords) return PDFMAKE_TEXT_ERR_MEMORY;
    
    x = 0;
    for (i = 0; i < num_points; i++) {
        flag = flags[i];
        if (flag & TTF_X_SHORT) {
            if (p >= end) return PDFMAKE_TEXT_ERR_PARSE_ERROR;
            dx = *p++;
            x += (flag & TTF_X_SAME) ? dx : -dx;
        } else if (!(flag & TTF_X_SAME)) {
            if (p + 2 > end) return PDFMAKE_TEXT_ERR_PARSE_ERROR;
            x += pdfmake_read_sbe16(p);
            p += 2;
        }
        /* else: same as previous (delta = 0) */
        x_coords[i] = x;
    }
    
    /* Read Y coordinates */
    y_coords = pdfmake_arena_alloc(arena, num_points * sizeof(int16_t));
    if (!y_coords) return PDFMAKE_TEXT_ERR_MEMORY;
    
    y = 0;
    for (i = 0; i < num_points; i++) {
        flag = flags[i];
        if (flag & TTF_Y_SHORT) {
            if (p >= end) return PDFMAKE_TEXT_ERR_PARSE_ERROR;
            dy = *p++;
            y += (flag & TTF_Y_SAME) ? dy : -dy;
        } else if (!(flag & TTF_Y_SAME)) {
            if (p + 2 > end) return PDFMAKE_TEXT_ERR_PARSE_ERROR;
            y += pdfmake_read_sbe16(p);
            p += 2;
        }
        y_coords[i] = y;
    }
    
    /* Convert points to path */
    pt = 0;
    for (c = 0; c < num_contours; c++) {
        contour_end = end_pts[c];
        contour_start = pt;
        contour_len = contour_end - contour_start + 1;
        
        if (contour_len < 2) {
            pt = contour_end + 1;
            continue;
        }
        
        /* Find first on-curve point to start */
        first_on = -1;
        for (i = 0; i < contour_len; i++) {
            if (flags[contour_start + i] & TTF_ON_CURVE) {
                first_on = i;
                break;
            }
        }
        
        if (first_on < 0) {
            /* All off-curve: insert implicit on-curve at midpoint of first two */
            mx = (x_coords[contour_start] + x_coords[contour_start + 1]) / 2.0;
            my = (y_coords[contour_start] + y_coords[contour_start + 1]) / 2.0;
            pdfmake_path_move_to(path, mx, my);
            first_on = 0;
        } else {
            start_idx = contour_start + first_on;
            pdfmake_path_move_to(path, x_coords[start_idx], y_coords[start_idx]);
        }
        
        /* Process contour points */
        for (i = 0; i < contour_len; i++) {
            idx = contour_start + ((first_on + 1 + i) % contour_len);
            next_idx = contour_start + ((first_on + 2 + i) % contour_len);
            
            cx = x_coords[idx];
            cy = y_coords[idx];
            on_curve = flags[idx] & TTF_ON_CURVE;
            
            if (on_curve) {
                pdfmake_path_line_to(path, cx, cy);
            } else {
                /* Off-curve point: quadratic Bezier control */
                nx = x_coords[next_idx];
                ny = y_coords[next_idx];
                next_on = flags[next_idx] & TTF_ON_CURVE;
                
                if (next_on) {
                    ex = nx;
                    ey = ny;
                    i++; /* Skip next point, we've used it */
                } else {
                    /* Implicit on-curve point at midpoint */
                    ex = (cx + nx) / 2.0;
                    ey = (cy + ny) / 2.0;
                }
                
                /* Get current point */
                x0 = path->current.x;
                y0 = path->current.y;
                
                /* Convert quadratic to cubic */
                quadratic_to_cubic(x0, y0, cx, cy, ex, ey, &c1x, &c1y, &c2x, &c2y);
                
                pdfmake_path_curve_to(path, c1x, c1y, c2x, c2y, ex, ey);
            }
        }
        
        pdfmake_path_close(path);
        pt = contour_end + 1;
    }
    
    outline->path = path;
    return PDFMAKE_TEXT_OK;
}

pdfmake_text_err_t pdfmake_ttf_load_composite_glyph(
    pdfmake_glyph_outline_t *outline,
    pdfmake_font_t *font,
    uint16_t glyph_id,
    pdfmake_glyph_cache_t *cache,
    pdfmake_arena_t *arena)
{
    /* TODO: Implement composite glyph loading */
    /* This involves recursively loading component glyphs and applying transforms */
    (void)outline;
    (void)font;
    (void)glyph_id;
    (void)cache;
    (void)arena;
    return PDFMAKE_TEXT_ERR_UNSUPPORTED;
}

/* CFF glyph loading implemented in pdfmake_font_cff.c */

/*============================================================================
 * Path Utilities
 *==========================================================================*/

void pdfmake_path_transform(pdfmake_path_t *path, const double m[6])
{
    size_t i;
    int p;

    if (!path || !m) return;
    
    for (i = 0; i < path->seg_count; i++) {
        pdfmake_path_seg_t *seg = &path->segs[i];
        int num_pts = 0;
        
        switch (seg->op) {
            case PDFMAKE_PATH_MOVE:
            case PDFMAKE_PATH_LINE:
                num_pts = 1;
                break;
            case PDFMAKE_PATH_CURVE:
                num_pts = 3;
                break;
            case PDFMAKE_PATH_CLOSE:
                num_pts = 0;
                break;
        }
        
        for (p = 0; p < num_pts; p++) {
            double x = seg->pts[p].x;
            double y = seg->pts[p].y;
            seg->pts[p].x = m[0] * x + m[2] * y + m[4];
            seg->pts[p].y = m[1] * x + m[3] * y + m[5];
        }
    }
    
    /* Update current point */
    if (path->has_current) {
        double x = path->current.x;
        double y = path->current.y;
        path->current.x = m[0] * x + m[2] * y + m[4];
        path->current.y = m[1] * x + m[3] * y + m[5];
    }
    
    /* Update subpath start */
    if (path->has_subpath) {
        double x = path->subpath_start.x;
        double y = path->subpath_start.y;
        path->subpath_start.x = m[0] * x + m[2] * y + m[4];
        path->subpath_start.y = m[1] * x + m[3] * y + m[5];
    }
}

pdfmake_path_t *pdfmake_path_transform_copy(
    pdfmake_path_t *src,
    const double m[6],
    pdfmake_arena_t *arena)
{
    pdfmake_path_t *dst;
    size_t i;

    if (!src || !m || !arena) return NULL;
    
    /* Create new path */
    dst = pdfmake_path_create();
    if (!dst) return NULL;
    
    /* Copy and transform segments */
    for (i = 0; i < src->seg_count; i++) {
        pdfmake_path_seg_t *seg = &src->segs[i];
        
        switch (seg->op) {
            case PDFMAKE_PATH_MOVE: {
                double x = m[0] * seg->pts[0].x + m[2] * seg->pts[0].y + m[4];
                double y = m[1] * seg->pts[0].x + m[3] * seg->pts[0].y + m[5];
                pdfmake_path_move_to(dst, x, y);
                break;
            }
            case PDFMAKE_PATH_LINE: {
                double x = m[0] * seg->pts[0].x + m[2] * seg->pts[0].y + m[4];
                double y = m[1] * seg->pts[0].x + m[3] * seg->pts[0].y + m[5];
                pdfmake_path_line_to(dst, x, y);
                break;
            }
            case PDFMAKE_PATH_CURVE: {
                double x1 = m[0] * seg->pts[0].x + m[2] * seg->pts[0].y + m[4];
                double y1 = m[1] * seg->pts[0].x + m[3] * seg->pts[0].y + m[5];
                double x2 = m[0] * seg->pts[1].x + m[2] * seg->pts[1].y + m[4];
                double y2 = m[1] * seg->pts[1].x + m[3] * seg->pts[1].y + m[5];
                double x3 = m[0] * seg->pts[2].x + m[2] * seg->pts[2].y + m[4];
                double y3 = m[1] * seg->pts[2].x + m[3] * seg->pts[2].y + m[5];
                pdfmake_path_curve_to(dst, x1, y1, x2, y2, x3, y3);
                break;
            }
            case PDFMAKE_PATH_CLOSE:
                pdfmake_path_close(dst);
                break;
        }
    }
    
    return dst;
}
