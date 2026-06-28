/*
 * pdfmake_render_fill.c - Scanline fill algorithm
 *
 * Implements path filling using the active edge table scanline algorithm.
 * Supports both non-zero winding number and even-odd fill rules.
 */

#include "pdfmake_render.h"
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <float.h>

#define MIN(a, b) ((a) < (b) ? (a) : (b))
#define MAX(a, b) ((a) > (b) ? (a) : (b))
#define CLAMP(x, lo, hi) ((x) < (lo) ? (lo) : ((x) > (hi) ? (hi) : (x)))

/*
 * Edge structure for scanline algorithm
 */
typedef struct fill_edge {
    int y_min;              /* Top scanline (integer) */
    int y_max;              /* Bottom scanline (integer) */
    double x;               /* Current x intersection */
    double dx;              /* Change in x per scanline (1/slope) */
    int dir;                /* Direction: +1 going up, -1 going down */
    struct fill_edge *next;
} fill_edge_t;

/*
 * Create edge from two points
 */
static fill_edge_t *create_edge(double x0, double y0, double x1, double y1) {
    fill_edge_t *edge;
    /* Skip horizontal edges */
    if (fabs(y1 - y0) < 0.5) {
        return NULL;
    }

    edge = malloc(sizeof(fill_edge_t));
    if (!edge) {
        return NULL;
    }
    
    /* Ensure y0 < y1 (edge goes from top to bottom) */
    if (y0 > y1) {
        double tmp = x0; x0 = x1; x1 = tmp;
        tmp = y0; y0 = y1; y1 = tmp;
        edge->dir = 1;   /* Original edge went up */
    } else {
        edge->dir = -1;  /* Original edge went down */
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
 * Build edge table from flattened path
 */
static fill_edge_t **build_edge_table(pdfmake_path_t *path, int y_min, int y_max, int *edge_count) {
    int height = y_max - y_min + 1;
    fill_edge_t **et = calloc(height, sizeof(fill_edge_t *));
    pdfmake_point_t current;
    pdfmake_point_t subpath_start;
    int has_current;
    size_t i;
    pdfmake_path_seg_t *seg;
    fill_edge_t *edge;
    int idx;
    if (!et) {
        return NULL;
    }
    
    *edge_count = 0;
    
    current.x = current.y = 0;
    subpath_start.x = subpath_start.y = 0;
    has_current = 0;

    for (i = 0; i < path->seg_count; i++) {
        seg = &path->segs[i];
        
        switch (seg->op) {
            case PDFMAKE_PATH_MOVE:
                current = seg->pts[0];
                subpath_start = current;
                has_current = 1;
                break;
                
            case PDFMAKE_PATH_LINE:
                if (has_current) {
                    edge = create_edge(
                        current.x, current.y,
                        seg->pts[0].x, seg->pts[0].y);
                    
                    if (edge && edge->y_min >= y_min && edge->y_min <= y_max) {
                        idx = edge->y_min - y_min;
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
                    edge = create_edge(
                        current.x, current.y,
                        subpath_start.x, subpath_start.y);
                    
                    if (edge && edge->y_min >= y_min && edge->y_min <= y_max) {
                        idx = edge->y_min - y_min;
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
                /* Curves should be flattened before fill */
                break;
        }
    }
    
    return et;
}

/*
 * Insert edge into active edge list (sorted by x)
 */
static void insert_edge_sorted(fill_edge_t **ael, fill_edge_t *edge) {
    fill_edge_t *curr;
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
 * Sort active edge list by x
 */
static void sort_ael(fill_edge_t **ael) {
    fill_edge_t *sorted;
    fill_edge_t *curr;
    fill_edge_t *next;
    if (!*ael || !(*ael)->next) {
        return;
    }
    
    /* Simple insertion sort (edges are usually nearly sorted) */
    sorted = NULL;
    curr = *ael;
    
    while (curr) {
        next = curr->next;
        insert_edge_sorted(&sorted, curr);
        curr = next;
    }
    
    *ael = sorted;
}

/*
 * Fill horizontal span
 */
static void fill_span(pdfmake_render_ctx_t *ctx, int y, int x0, int x1, uint32_t color) {
    uint32_t *row;
    int x;
    if (y < 0 || y >= ctx->height) {
        return;
    }
    
    x0 = CLAMP(x0, 0, ctx->width);
    x1 = CLAMP(x1, 0, ctx->width);
    
    row = ctx->pixels + y * ctx->width;
    
    for (x = x0; x < x1; x++) {
        if (ctx->has_clip && ctx->clip_mask) {
            if (ctx->clip_mask[y * ctx->width + x] == 0) {
                continue;  /* Clipped out */
            }
        }
        row[x] = pdfmake_color_blend(row[x], color);
    }
}

/*
 * Fill path with non-zero winding rule
 */
static void fill_nonzero(pdfmake_render_ctx_t *ctx, pdfmake_path_t *path, uint32_t color) {
    double x_min, y_min, x_max, y_max;
    int iy_min;
    int iy_max;
    int edge_count;
    fill_edge_t **et;
    fill_edge_t *ael;
    int y;
    int idx;
    fill_edge_t *edge;
    int winding;
    fill_edge_t *curr;
    int span_start;
    int span_end;
    fill_edge_t *prev;
    fill_edge_t *next;
    if (pdfmake_path_get_bounds(path, &x_min, &y_min, &x_max, &y_max) != PDFMAKE_RENDER_OK) {
        return;
    }

    iy_min = MAX((int)floor(y_min), 0);
    iy_max = MIN((int)ceil(y_max), ctx->height - 1);
    
    if (iy_min > iy_max) {
        return;
    }
    
    et = build_edge_table(path, iy_min, iy_max, &edge_count);
    if (!et) {
        return;
    }
    
    ael = NULL;  /* Active edge list */
    
    for (y = iy_min; y <= iy_max; y++) {
        idx = y - iy_min;
        
        /* Add edges starting at this scanline */
        while (et[idx]) {
            edge = et[idx];
            et[idx] = edge->next;
            insert_edge_sorted(&ael, edge);
        }
        
        /* Sort AEL by x */
        sort_ael(&ael);
        
        /* Fill spans using non-zero winding rule */
        winding = 0;
        curr = ael;
        span_start = -1;
        
        while (curr) {
            if (winding == 0 && curr->dir != 0) {
                span_start = (int)floor(curr->x);
            }
            winding += curr->dir;
            if (winding == 0 && span_start >= 0) {
                span_end = (int)ceil(curr->x);
                fill_span(ctx, y, span_start, span_end, color);
                span_start = -1;
            }
            curr = curr->next;
        }
        
        /* Remove edges ending at this scanline and update x */
        prev = NULL;
        curr = ael;
        while (curr) {
            next = curr->next;
            if (y >= curr->y_max) {
                /* Remove edge */
                if (prev) {
                    prev->next = next;
                } else {
                    ael = next;
                }
                free(curr);
            } else {
                /* Update x for next scanline */
                curr->x += curr->dx;
                prev = curr;
            }
            curr = next;
        }
    }
    
    /* Free edge table */
    free(et);
    
    /* Free remaining AEL edges */
    while (ael) {
        fill_edge_t *next = ael->next;
        free(ael);
        ael = next;
    }
}

/*
 * Fill path with even-odd rule
 */
static void fill_evenodd(pdfmake_render_ctx_t *ctx, pdfmake_path_t *path, uint32_t color) {
    double x_min, y_min, x_max, y_max;
    int iy_min;
    int iy_max;
    int edge_count;
    fill_edge_t **et;
    fill_edge_t *ael;
    int y;
    int idx;
    fill_edge_t *edge;
    int parity;
    fill_edge_t *curr;
    int span_start;
    int span_end;
    fill_edge_t *prev;
    fill_edge_t *next;
    if (pdfmake_path_get_bounds(path, &x_min, &y_min, &x_max, &y_max) != PDFMAKE_RENDER_OK) {
        return;
    }

    iy_min = MAX((int)floor(y_min), 0);
    iy_max = MIN((int)ceil(y_max), ctx->height - 1);
    
    if (iy_min > iy_max) {
        return;
    }
    
    et = build_edge_table(path, iy_min, iy_max, &edge_count);
    if (!et) {
        return;
    }
    
    ael = NULL;
    
    for (y = iy_min; y <= iy_max; y++) {
        idx = y - iy_min;
        
        /* Add edges starting at this scanline */
        while (et[idx]) {
            edge = et[idx];
            et[idx] = edge->next;
            insert_edge_sorted(&ael, edge);
        }
        
        sort_ael(&ael);
        
        /* Fill spans using even-odd rule */
        parity = 0;
        curr = ael;
        span_start = -1;
        
        while (curr) {
            if (parity == 0) {
                span_start = (int)floor(curr->x);
            }
            parity = 1 - parity;
            if (parity == 0 && span_start >= 0) {
                span_end = (int)ceil(curr->x);
                fill_span(ctx, y, span_start, span_end, color);
                span_start = -1;
            }
            curr = curr->next;
        }
        
        /* Remove edges ending at this scanline and update x */
        prev = NULL;
        curr = ael;
        while (curr) {
            next = curr->next;
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
        fill_edge_t *next = ael->next;
        free(ael);
        ael = next;
    }
}

/*
 * Fill path with specified rule
 */
pdfmake_render_err_t pdfmake_fill_path(
    pdfmake_render_ctx_t *ctx,
    pdfmake_path_t *path,
    pdfmake_fill_rule_t rule)
{
    pdfmake_path_t *flat;
    uint32_t color;
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

    color = pdfmake_color_pack(ctx->fill_color);
    
    if (rule == PDFMAKE_FILL_EVENODD) {
        fill_evenodd(ctx, flat, color);
    } else {
        fill_nonzero(ctx, flat, color);
    }
    
    pdfmake_path_destroy(flat);
    return PDFMAKE_RENDER_OK;
}

/*
 * Fill current path
 */
pdfmake_render_err_t pdfmake_render_fill(pdfmake_render_ctx_t *ctx) {
    pdfmake_render_err_t err;
    if (!ctx) {
        return PDFMAKE_RENDER_ERR_NULL;
    }

    err = pdfmake_fill_path(ctx, ctx->path, ctx->fill_rule);
    
    /* Clear path after fill */
    pdfmake_path_clear(ctx->path);
    
    return err;
}

/*
 * Fill and preserve path
 */
pdfmake_render_err_t pdfmake_render_fill_preserve(pdfmake_render_ctx_t *ctx) {
    if (!ctx) {
        return PDFMAKE_RENDER_ERR_NULL;
    }
    
    return pdfmake_fill_path(ctx, ctx->path, ctx->fill_rule);
}
