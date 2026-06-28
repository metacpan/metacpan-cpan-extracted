/*
 * pdfmake_render_clip.c - Clipping path support
 *
 * Implements clipping by rendering paths to an alpha mask buffer
 * that is applied during fill/stroke operations.
 */

#include "pdfmake_render.h"
#include <stdlib.h>
#include <string.h>
#include <math.h>

#define MIN(a, b) ((a) < (b) ? (a) : (b))
#define MAX(a, b) ((a) > (b) ? (a) : (b))
#define CLAMP(x, lo, hi) ((x) < (lo) ? (lo) : ((x) > (hi) ? (hi) : (x)))

/*
 * Edge structure for clip scanline
 */
typedef struct clip_edge {
    int y_min;
    int y_max;
    double x;
    double dx;
    int dir;
    struct clip_edge *next;
} clip_edge_t;

/*
 * Create clip edge
 */
static clip_edge_t *create_clip_edge(double x0, double y0, double x1, double y1) {
    clip_edge_t *edge;
    if (fabs(y1 - y0) < 0.5) {
        return NULL;
    }
    
    edge = malloc(sizeof(clip_edge_t));
    if (!edge) {
        return NULL;
    }
    
    if (y0 > y1) {
        double tmp = x0; x0 = x1; x1 = tmp;
        tmp = y0; y0 = y1; y1 = tmp;
        edge->dir = 1;
    } else {
        edge->dir = -1;
    }
    
    edge->y_min = (int)ceil(y0);
    edge->y_max = (int)floor(y1);
    
    if (edge->y_min > edge->y_max) {
        free(edge);
        return NULL;
    }
    
    edge->dx = (x1 - x0) / (y1 - y0);
    edge->x = x0 + edge->dx * (edge->y_min - y0);
    edge->next = NULL;
    
    return edge;
}

/*
 * Build edge table for clip path
 */
static clip_edge_t **build_clip_edge_table(pdfmake_path_t *path, 
    int y_min, int y_max, int *edge_count)
{
    int height = y_max - y_min + 1;
    clip_edge_t **et = calloc(height, sizeof(clip_edge_t *));
    pdfmake_point_t current;
    pdfmake_point_t subpath_start;
    int has_current;
    size_t i;
    if (!et) {
        return NULL;
    }
    
    *edge_count = 0;
    
    current.x = 0; current.y = 0;
    subpath_start.x = 0; subpath_start.y = 0;
    has_current = 0;
    
    for (i = 0; i < path->seg_count; i++) {
        pdfmake_path_seg_t *seg = &path->segs[i];
        
        switch (seg->op) {
            case PDFMAKE_PATH_MOVE:
                current = seg->pts[0];
                subpath_start = current;
                has_current = 1;
                break;
                
            case PDFMAKE_PATH_LINE:
                if (has_current) {
                    clip_edge_t *edge = create_clip_edge(
                        current.x, current.y,
                        seg->pts[0].x, seg->pts[0].y);
                    
                    if (edge && edge->y_min >= y_min && edge->y_min <= y_max) {
                        int idx = edge->y_min - y_min;
                        edge->next = et[idx];
                        et[idx] = edge;
                        (*edge_count)++;
                    } else if (edge) {
                        free(edge);
                    }
                }
                current = seg->pts[0];
                break;
                
            case PDFMAKE_PATH_CLOSE:
                if (has_current) {
                    clip_edge_t *edge = create_clip_edge(
                        current.x, current.y,
                        subpath_start.x, subpath_start.y);
                    
                    if (edge && edge->y_min >= y_min && edge->y_min <= y_max) {
                        int idx = edge->y_min - y_min;
                        edge->next = et[idx];
                        et[idx] = edge;
                        (*edge_count)++;
                    } else if (edge) {
                        free(edge);
                    }
                }
                current = subpath_start;
                break;
                
            case PDFMAKE_PATH_CURVE:
                break;
        }
    }
    
    return et;
}

/*
 * Insert edge into active list sorted by x
 */
static void insert_clip_edge_sorted(clip_edge_t **ael, clip_edge_t *edge) {
    clip_edge_t *curr;
    edge->next = NULL;
    
    if (*ael == NULL || edge->x < (*ael)->x) {
        edge->next = *ael;
        *ael = edge;
        return;
    }
    
    curr = *ael;
    while (curr->next && curr->next->x < edge->x) {
        curr = curr->next;
    }
    edge->next = curr->next;
    curr->next = edge;
}

/*
 * Sort active edge list
 */
static void sort_clip_ael(clip_edge_t **ael) {
    clip_edge_t *sorted;
    clip_edge_t *curr;
    if (!*ael || !(*ael)->next) {
        return;
    }
    
    sorted = NULL;
    curr = *ael;
    
    while (curr) {
        clip_edge_t *next = curr->next;
        insert_clip_edge_sorted(&sorted, curr);
        curr = next;
    }
    
    *ael = sorted;
}

/*
 * Fill mask span
 */
static void fill_mask_span(uint8_t *mask, int width, int y, int x0, int x1) {
    uint8_t *row;
    int x;
    x0 = CLAMP(x0, 0, width);
    x1 = CLAMP(x1, 0, width);
    
    row = mask + y * width;
    for (x = x0; x < x1; x++) {
        row[x] = 255;
    }
}

/*
 * Rasterize clip path to mask with non-zero winding rule
 */
static void clip_nonzero(uint8_t *mask, int width, int height,
    pdfmake_path_t *path)
{
    double x_min, y_min, x_max, y_max;
    int iy_min, iy_max;
    int edge_count;
    clip_edge_t **et;
    clip_edge_t *ael;
    int y;
    if (pdfmake_path_get_bounds(path, &x_min, &y_min, &x_max, &y_max) != PDFMAKE_RENDER_OK) {
        return;
    }
    
    iy_min = MAX((int)floor(y_min), 0);
    iy_max = MIN((int)ceil(y_max), height - 1);
    
    if (iy_min > iy_max) {
        return;
    }
    
    et = build_clip_edge_table(path, iy_min, iy_max, &edge_count);
    if (!et) {
        return;
    }
    
    ael = NULL;
    
    for (y = iy_min; y <= iy_max; y++) {
        int idx = y - iy_min;
        int winding;
        clip_edge_t *curr;
        int span_start;
        clip_edge_t *prev;
        
        while (et[idx]) {
            clip_edge_t *edge = et[idx];
            et[idx] = edge->next;
            insert_clip_edge_sorted(&ael, edge);
        }
        
        sort_clip_ael(&ael);
        
        winding = 0;
        curr = ael;
        span_start = -1;
        
        while (curr) {
            if (winding == 0 && curr->dir != 0) {
                span_start = (int)floor(curr->x);
            }
            winding += curr->dir;
            if (winding == 0 && span_start >= 0) {
                int span_end = (int)ceil(curr->x);
                fill_mask_span(mask, width, y, span_start, span_end);
                span_start = -1;
            }
            curr = curr->next;
        }
        
        prev = NULL;
        curr = ael;
        while (curr) {
            clip_edge_t *next = curr->next;
            if (y >= curr->y_max) {
                if (prev) {
                    prev->next = next;
                } else {
                    ael = next;
                }
                free(curr);
            } else {
                curr->x += curr->dx;
                prev = curr;
            }
            curr = next;
        }
    }
    
    free(et);
    
    while (ael) {
        clip_edge_t *next = ael->next;
        free(ael);
        ael = next;
    }
}

/*
 * Rasterize clip path to mask with even-odd rule
 */
static void clip_evenodd(uint8_t *mask, int width, int height,
    pdfmake_path_t *path)
{
    double x_min, y_min, x_max, y_max;
    int iy_min, iy_max;
    int edge_count;
    clip_edge_t **et;
    clip_edge_t *ael;
    int y;
    if (pdfmake_path_get_bounds(path, &x_min, &y_min, &x_max, &y_max) != PDFMAKE_RENDER_OK) {
        return;
    }
    
    iy_min = MAX((int)floor(y_min), 0);
    iy_max = MIN((int)ceil(y_max), height - 1);
    
    if (iy_min > iy_max) {
        return;
    }
    
    et = build_clip_edge_table(path, iy_min, iy_max, &edge_count);
    if (!et) {
        return;
    }
    
    ael = NULL;
    
    for (y = iy_min; y <= iy_max; y++) {
        int idx = y - iy_min;
        int parity;
        clip_edge_t *curr;
        int span_start;
        clip_edge_t *prev;
        
        while (et[idx]) {
            clip_edge_t *edge = et[idx];
            et[idx] = edge->next;
            insert_clip_edge_sorted(&ael, edge);
        }
        
        sort_clip_ael(&ael);
        
        parity = 0;
        curr = ael;
        span_start = -1;
        
        while (curr) {
            if (parity == 0) {
                span_start = (int)floor(curr->x);
            }
            parity = 1 - parity;
            if (parity == 0 && span_start >= 0) {
                int span_end = (int)ceil(curr->x);
                fill_mask_span(mask, width, y, span_start, span_end);
                span_start = -1;
            }
            curr = curr->next;
        }
        
        prev = NULL;
        curr = ael;
        while (curr) {
            clip_edge_t *next = curr->next;
            if (y >= curr->y_max) {
                if (prev) {
                    prev->next = next;
                } else {
                    ael = next;
                }
                free(curr);
            } else {
                curr->x += curr->dx;
                prev = curr;
            }
            curr = next;
        }
    }
    
    free(et);
    
    while (ael) {
        clip_edge_t *next = ael->next;
        free(ael);
        ael = next;
    }
}

/*
 * Clip to path with specified fill rule
 */
pdfmake_render_err_t pdfmake_clip_path(
    pdfmake_render_ctx_t *ctx,
    pdfmake_path_t *path,
    pdfmake_fill_rule_t rule)
{
    pdfmake_path_t *flat;
    size_t mask_size;
    uint8_t *new_mask;
    if (!ctx || !path) {
        return PDFMAKE_RENDER_ERR_NULL;
    }
    
    if (pdfmake_path_is_empty(path)) {
        return PDFMAKE_RENDER_ERR_EMPTY_PATH;
    }
    
    /* Flatten curves */
    flat = pdfmake_path_flatten(path, ctx->flatness);
    if (!flat) {
        return PDFMAKE_RENDER_ERR_MEMORY;
    }
    
    mask_size = ctx->width * ctx->height;
    
    /* Allocate new mask */
    new_mask = calloc(mask_size, 1);
    if (!new_mask) {
        pdfmake_path_destroy(flat);
        return PDFMAKE_RENDER_ERR_MEMORY;
    }
    
    /* Rasterize path to mask */
    if (rule == PDFMAKE_FILL_EVENODD) {
        clip_evenodd(new_mask, ctx->width, ctx->height, flat);
    } else {
        clip_nonzero(new_mask, ctx->width, ctx->height, flat);
    }
    
    pdfmake_path_destroy(flat);
    
    /* Intersect with existing clip mask if present */
    if (ctx->has_clip && ctx->clip_mask) {
        size_t i;
        for (i = 0; i < mask_size; i++) {
            new_mask[i] = MIN(new_mask[i], ctx->clip_mask[i]);
        }
        free(ctx->clip_mask);
    }
    
    ctx->clip_mask = new_mask;
    ctx->has_clip = 1;
    
    return PDFMAKE_RENDER_OK;
}

/*
 * Clip to current path
 */
pdfmake_render_err_t pdfmake_render_clip(pdfmake_render_ctx_t *ctx) {
    pdfmake_render_err_t err;
    if (!ctx) {
        return PDFMAKE_RENDER_ERR_NULL;
    }
    
    err = pdfmake_clip_path(ctx, ctx->path, ctx->fill_rule);
    
    /* Clear path after clip */
    pdfmake_path_clear(ctx->path);
    
    return err;
}

/*
 * Reset clip to full canvas
 */
void pdfmake_render_reset_clip(pdfmake_render_ctx_t *ctx) {
    if (!ctx) {
        return;
    }
    
    if (ctx->clip_mask) {
        free(ctx->clip_mask);
        ctx->clip_mask = NULL;
    }
    ctx->has_clip = 0;
}

/*
 * Check if point is inside clip region
 */
int pdfmake_render_point_in_clip(pdfmake_render_ctx_t *ctx, int x, int y) {
    if (!ctx) {
        return 0;
    }
    
    if (!ctx->has_clip || !ctx->clip_mask) {
        return 1;  /* No clip = everything inside */
    }
    
    if (x < 0 || x >= ctx->width || y < 0 || y >= ctx->height) {
        return 0;
    }
    
    return ctx->clip_mask[y * ctx->width + x] > 0;
}

/*
 * Get clip mask value at point (0-255)
 */
int pdfmake_render_get_clip_alpha(pdfmake_render_ctx_t *ctx, int x, int y) {
    if (!ctx) {
        return 0;
    }
    
    if (!ctx->has_clip || !ctx->clip_mask) {
        return 255;
    }
    
    if (x < 0 || x >= ctx->width || y < 0 || y >= ctx->height) {
        return 0;
    }
    
    return ctx->clip_mask[y * ctx->width + x];
}
