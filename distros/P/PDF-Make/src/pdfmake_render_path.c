/*
 * pdfmake_render_path.c - Path construction and management
 *
 * Implements path creation, manipulation and destruction for 2D graphics.
 */

#include "pdfmake_render.h"
#include <stdlib.h>
#include <string.h>

#define INITIAL_SEG_CAPACITY 16

/*
 * Create a new empty path
 */
pdfmake_path_t *pdfmake_path_create(void) {
    pdfmake_path_t *path = calloc(1, sizeof(pdfmake_path_t));
    if (!path) {
        return NULL;
    }
    
    path->segs = malloc(INITIAL_SEG_CAPACITY * sizeof(pdfmake_path_seg_t));
    if (!path->segs) {
        free(path);
        return NULL;
    }
    
    path->seg_count = 0;
    path->seg_cap = INITIAL_SEG_CAPACITY;
    path->current.x = 0;
    path->current.y = 0;
    path->has_current = 0;
    path->subpath_start.x = 0;
    path->subpath_start.y = 0;
    path->has_subpath = 0;
    
    return path;
}

/*
 * Destroy a path and free all resources
 */
void pdfmake_path_destroy(pdfmake_path_t *path) {
    if (!path) {
        return;
    }
    
    free(path->segs);
    free(path);
}

/*
 * Clear all segments from a path, keeping capacity
 */
void pdfmake_path_clear(pdfmake_path_t *path) {
    if (!path) {
        return;
    }
    
    path->seg_count = 0;
    path->current.x = 0;
    path->current.y = 0;
    path->has_current = 0;
    path->subpath_start.x = 0;
    path->subpath_start.y = 0;
    path->has_subpath = 0;
}

/*
 * Ensure capacity for at least one more segment
 */
static int path_ensure_capacity(pdfmake_path_t *path) {
    if (path->seg_count >= path->seg_cap) {
        size_t new_cap = path->seg_cap * 2;
        pdfmake_path_seg_t *new_segs = realloc(path->segs,
                                                new_cap * sizeof(pdfmake_path_seg_t));
        if (!new_segs) {
            return -1;
        }
        path->segs = new_segs;
        path->seg_cap = new_cap;
    }
    return 0;
}

/*
 * Move to a new point (start new subpath)
 */
pdfmake_render_err_t pdfmake_path_move_to(pdfmake_path_t *path, double x, double y) {
    pdfmake_path_seg_t *seg;
    if (!path) {
        return PDFMAKE_RENDER_ERR_INVALID;
    }
    
    if (path_ensure_capacity(path) < 0) {
        return PDFMAKE_RENDER_ERR_MEMORY;
    }
    
    seg = &path->segs[path->seg_count++];
    seg->op = PDFMAKE_PATH_MOVE;
    seg->pts[0].x = x;
    seg->pts[0].y = y;
    
    path->current.x = x;
    path->current.y = y;
    path->has_current = 1;
    path->subpath_start.x = x;
    path->subpath_start.y = y;
    path->has_subpath = 1;
    
    return PDFMAKE_RENDER_OK;
}

/*
 * Draw a line to a point
 */
pdfmake_render_err_t pdfmake_path_line_to(pdfmake_path_t *path, double x, double y) {
    pdfmake_path_seg_t *seg;
    if (!path) {
        return PDFMAKE_RENDER_ERR_INVALID;
    }
    
    /* If no current point, treat as move_to */
    if (!path->has_current) {
        return pdfmake_path_move_to(path, x, y);
    }
    
    if (path_ensure_capacity(path) < 0) {
        return PDFMAKE_RENDER_ERR_MEMORY;
    }
    
    seg = &path->segs[path->seg_count++];
    seg->op = PDFMAKE_PATH_LINE;
    seg->pts[0].x = x;
    seg->pts[0].y = y;
    
    path->current.x = x;
    path->current.y = y;
    
    return PDFMAKE_RENDER_OK;
}

/*
 * Draw a cubic Bezier curve
 */
pdfmake_render_err_t pdfmake_path_curve_to(pdfmake_path_t *path,
    double x1, double y1, double x2, double y2, double x3, double y3)
{
    pdfmake_path_seg_t *seg;
    if (!path) {
        return PDFMAKE_RENDER_ERR_INVALID;
    }
    
    /* If no current point, move to first control point */
    if (!path->has_current) {
        pdfmake_render_err_t err = pdfmake_path_move_to(path, x1, y1);
        if (err != PDFMAKE_RENDER_OK) {
            return err;
        }
    }
    
    if (path_ensure_capacity(path) < 0) {
        return PDFMAKE_RENDER_ERR_MEMORY;
    }
    
    seg = &path->segs[path->seg_count++];
    seg->op = PDFMAKE_PATH_CURVE;
    seg->pts[0].x = x1;
    seg->pts[0].y = y1;
    seg->pts[1].x = x2;
    seg->pts[1].y = y2;
    seg->pts[2].x = x3;
    seg->pts[2].y = y3;
    
    path->current.x = x3;
    path->current.y = y3;
    
    return PDFMAKE_RENDER_OK;
}

/*
 * Close current subpath
 */
pdfmake_render_err_t pdfmake_path_close(pdfmake_path_t *path) {
    pdfmake_path_seg_t *seg;
    if (!path) {
        return PDFMAKE_RENDER_ERR_INVALID;
    }
    
    if (!path->has_subpath) {
        return PDFMAKE_RENDER_OK;  /* No subpath to close */
    }
    
    if (path_ensure_capacity(path) < 0) {
        return PDFMAKE_RENDER_ERR_MEMORY;
    }
    
    seg = &path->segs[path->seg_count++];
    seg->op = PDFMAKE_PATH_CLOSE;
    
    path->current = path->subpath_start;
    
    return PDFMAKE_RENDER_OK;
}

/*
 * Add a rectangle to the path
 */
pdfmake_render_err_t pdfmake_path_rect(pdfmake_path_t *path,
    double x, double y, double w, double h)
{
    pdfmake_render_err_t err;
    
    err = pdfmake_path_move_to(path, x, y);
    if (err != PDFMAKE_RENDER_OK) return err;
    
    err = pdfmake_path_line_to(path, x + w, y);
    if (err != PDFMAKE_RENDER_OK) return err;
    
    err = pdfmake_path_line_to(path, x + w, y + h);
    if (err != PDFMAKE_RENDER_OK) return err;
    
    err = pdfmake_path_line_to(path, x, y + h);
    if (err != PDFMAKE_RENDER_OK) return err;
    
    return pdfmake_path_close(path);
}

/*
 * Check if path is empty
 */
int pdfmake_path_is_empty(pdfmake_path_t *path) {
    return !path || path->seg_count == 0;
}

/*
 * Get path bounding box
 */
pdfmake_render_err_t pdfmake_path_get_bounds(pdfmake_path_t *path,
    double *min_x, double *min_y, double *max_x, double *max_y)
{
    double x_min, y_min;
    double x_max, y_max;
    size_t i;
    int j;

    if (!path || path->seg_count == 0) {
        return PDFMAKE_RENDER_ERR_INVALID;
    }
    
    x_min = 1e308; y_min = 1e308;
    x_max = -1e308; y_max = -1e308;
    
    for (i = 0; i < path->seg_count; i++) {
        pdfmake_path_seg_t *seg = &path->segs[i];
        int n_pts = 0;
        
        switch (seg->op) {
            case PDFMAKE_PATH_MOVE:
            case PDFMAKE_PATH_LINE:
                n_pts = 1;
                break;
            case PDFMAKE_PATH_CURVE:
                n_pts = 3;
                break;
            case PDFMAKE_PATH_CLOSE:
                n_pts = 0;
                break;
        }
        
        for (j = 0; j < n_pts; j++) {
            if (seg->pts[j].x < x_min) x_min = seg->pts[j].x;
            if (seg->pts[j].y < y_min) y_min = seg->pts[j].y;
            if (seg->pts[j].x > x_max) x_max = seg->pts[j].x;
            if (seg->pts[j].y > y_max) y_max = seg->pts[j].y;
        }
    }
    
    if (min_x) *min_x = x_min;
    if (min_y) *min_y = y_min;
    if (max_x) *max_x = x_max;
    if (max_y) *max_y = y_max;
    
    return PDFMAKE_RENDER_OK;
}
