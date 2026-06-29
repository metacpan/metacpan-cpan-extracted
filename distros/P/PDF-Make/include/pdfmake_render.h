/*
 * pdfmake_render.h - Path rendering types and context
 *
 * Implements PDF path construction and painting operations:
 * - Path segments: move, line, curve, close
 * - Fill with non-zero or even-odd winding rules
 * - Stroke with caps, joins, dashes
 * - Clipping
 */

#ifndef PDFMAKE_RENDER_H
#define PDFMAKE_RENDER_H

#include "pdfmake_types.h"
#include <stdint.h>
#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

/*
 * Error codes
 */

typedef enum {
    PDFMAKE_RENDER_OK = 0,
    PDFMAKE_RENDER_ERR_NULL,
    PDFMAKE_RENDER_ERR_MEMORY,
    PDFMAKE_RENDER_ERR_INVALID,
    PDFMAKE_RENDER_ERR_OVERFLOW,
    PDFMAKE_RENDER_ERR_EMPTY_PATH,
} pdfmake_render_err_t;

/*
 * Point - 2D coordinate
 */

typedef struct pdfmake_point {
    double x;
    double y;
} pdfmake_point_t;

/*
 * Path segment operations
 */

#ifndef PDFMAKE_PATH_OP_DEFINED
#define PDFMAKE_PATH_OP_DEFINED
typedef enum {
    PDFMAKE_PATH_MOVE,    /* Move to point (1 point) */
    PDFMAKE_PATH_LINE,    /* Line to point (1 point) */
    PDFMAKE_PATH_CURVE,   /* Cubic bezier (3 control points) */
    PDFMAKE_PATH_CLOSE,   /* Close subpath (0 points) */
} pdfmake_path_op_t;
#endif

/*
 * Path segment - single path operation with control points
 */

typedef struct pdfmake_path_seg {
    pdfmake_path_op_t op;
    pdfmake_point_t pts[3];  /* Up to 3 control points for curves */
} pdfmake_path_seg_t;

/*
 * Path - collection of segments forming subpaths
 */

struct pdfmake_path {
    pdfmake_path_seg_t *segs;
    size_t seg_count;
    size_t seg_cap;
    
    /* Current point for path construction */
    pdfmake_point_t current;
    int has_current;
    
    /* Start of current subpath (for close) */
    pdfmake_point_t subpath_start;
    int has_subpath;
};
#ifndef PDFMAKE_PATH_T_DEFINED
#define PDFMAKE_PATH_T_DEFINED
typedef struct pdfmake_path pdfmake_path_t;
#endif

/*
 * Line cap styles (PDF spec 8.4.3.3)
 */

typedef enum {
    PDFMAKE_CAP_BUTT = 0,     /* Square end at endpoint */
    PDFMAKE_CAP_ROUND = 1,    /* Semicircular cap */
    PDFMAKE_CAP_SQUARE = 2,   /* Square cap extending beyond endpoint */
} pdfmake_line_cap_t;

/*
 * Line join styles (PDF spec 8.4.3.4)
 */

typedef enum {
    PDFMAKE_JOIN_MITER = 0,   /* Sharp corner (with miter limit) */
    PDFMAKE_JOIN_ROUND = 1,   /* Rounded corner */
    PDFMAKE_JOIN_BEVEL = 2,   /* Beveled corner */
} pdfmake_line_join_t;

/*
 * Fill rules (PDF spec 8.5.3.3)
 */

typedef enum {
    PDFMAKE_FILL_NONZERO = 0,  /* Non-zero winding number rule */
    PDFMAKE_FILL_EVENODD = 1,  /* Even-odd rule */
} pdfmake_fill_rule_t;

/*
 * Stroke style - all stroke parameters
 */

typedef struct pdfmake_stroke_style {
    double width;
    pdfmake_line_cap_t cap;
    pdfmake_line_join_t join;
    double miter_limit;
    
    /* Dash pattern */
    double *dash_array;
    size_t dash_count;
    double dash_phase;
} pdfmake_stroke_style_t;

/*
 * Color - RGBA
 */

typedef struct pdfmake_rgba {
    double r, g, b, a;
} pdfmake_rgba_t;

/*
 * Transformation matrix - [a b c d e f]
 * 
 * | a  b  0 |    x' = ax + cy + e
 * | c  d  0 |    y' = bx + dy + f
 * | e  f  1 |
 */

typedef struct pdfmake_matrix {
    double a, b, c, d, e, f;
} pdfmake_matrix_t;

/*
 * Render context - maintains graphics state and output buffer
 */

#ifndef PDFMAKE_RENDER_CTX_T_DEFINED
#define PDFMAKE_RENDER_CTX_T_DEFINED
typedef struct pdfmake_render_ctx pdfmake_render_ctx_t;
#endif

struct pdfmake_render_ctx {
    /* Output buffer (RGBA, 8 bits per channel) */
    uint32_t *pixels;
    int width;
    int height;
    int stride;         /* Bytes per row */
    int owns_buffer;    /* 1 if we allocated pixels */
    
    /* Current graphics state */
    pdfmake_matrix_t ctm;           /* Current transformation matrix */
    pdfmake_rgba_t fill_color;
    pdfmake_rgba_t stroke_color;
    pdfmake_stroke_style_t stroke_style;
    pdfmake_fill_rule_t fill_rule;
    
    /* Clip mask (8-bit alpha, same dimensions as pixels) */
    uint8_t *clip_mask;
    int has_clip;
    
    /* Current path being constructed */
    pdfmake_path_t *path;
    
    /* Graphics state stack for save/restore */
    struct pdfmake_gstate *gstate_stack;
    int gstate_depth;
    int gstate_max;
    
    /* Flatness tolerance for curve flattening */
    double flatness;
    
    /* Anti-aliasing (0 = off, 1-4 = supersample level) */
    int antialias;
};

/*
 * Saved graphics state
 */

typedef struct pdfmake_gstate {
    pdfmake_matrix_t ctm;
    pdfmake_rgba_t fill_color;
    pdfmake_rgba_t stroke_color;
    pdfmake_stroke_style_t stroke_style;
    pdfmake_fill_rule_t fill_rule;
    uint8_t *clip_mask;
    int has_clip;
    double flatness;
} pdfmake_gstate_t;

/*
 * Edge for scanline algorithm
 */

typedef struct pdfmake_edge {
    double y_min;           /* Top of edge */
    double y_max;           /* Bottom of edge */
    double x_at_ymin;       /* X at y_min */
    double slope;           /* dx/dy */
    int direction;          /* +1 going up, -1 going down */
    struct pdfmake_edge *next;
} pdfmake_edge_t;

/*
 * Active edge list for scanline fill
 */

typedef struct pdfmake_ael {
    pdfmake_edge_t *edges;
    int count;
    int capacity;
} pdfmake_ael_t;

/*
 * =============================================================
 * Render Context Functions (pdfmake_render.c)
 * =============================================================
 */

/* Create render context with new buffer */
pdfmake_render_ctx_t *pdfmake_render_create(int width, int height);

/* Create render context with external buffer */
pdfmake_render_ctx_t *pdfmake_render_create_with_buffer(
    uint32_t *pixels, int width, int height, int stride);

/* Destroy render context */
void pdfmake_render_destroy(pdfmake_render_ctx_t *ctx);

/* Clear buffer to color */
void pdfmake_render_clear(pdfmake_render_ctx_t *ctx, pdfmake_rgba_t color);

/* Save/restore graphics state */
pdfmake_render_err_t pdfmake_render_save(pdfmake_render_ctx_t *ctx);
pdfmake_render_err_t pdfmake_render_restore(pdfmake_render_ctx_t *ctx);

/* Set colors */
void pdfmake_render_set_fill_color(pdfmake_render_ctx_t *ctx,
    double r, double g, double b, double a);
void pdfmake_render_set_stroke_color(pdfmake_render_ctx_t *ctx,
    double r, double g, double b, double a);

/* Set stroke style */
void pdfmake_render_set_line_width(pdfmake_render_ctx_t *ctx, double width);
void pdfmake_render_set_line_cap(pdfmake_render_ctx_t *ctx, pdfmake_line_cap_t cap);
void pdfmake_render_set_line_join(pdfmake_render_ctx_t *ctx, pdfmake_line_join_t join);
void pdfmake_render_set_miter_limit(pdfmake_render_ctx_t *ctx, double limit);
pdfmake_render_err_t pdfmake_render_set_dash(pdfmake_render_ctx_t *ctx,
    double *array, size_t count, double phase);

/* Set fill rule */
void pdfmake_render_set_fill_rule(pdfmake_render_ctx_t *ctx, pdfmake_fill_rule_t rule);

/* Set flatness tolerance */
void pdfmake_render_set_flatness(pdfmake_render_ctx_t *ctx, double flatness);

/* Transformation matrix operations */
void pdfmake_render_set_matrix(pdfmake_render_ctx_t *ctx, pdfmake_matrix_t *m);
void pdfmake_render_concat_matrix(pdfmake_render_ctx_t *ctx, pdfmake_matrix_t *m);
void pdfmake_render_translate(pdfmake_render_ctx_t *ctx, double tx, double ty);
void pdfmake_render_scale(pdfmake_render_ctx_t *ctx, double sx, double sy);
void pdfmake_render_rotate(pdfmake_render_ctx_t *ctx, double angle);

/* Get pixel */
uint32_t pdfmake_render_get_pixel(pdfmake_render_ctx_t *ctx, int x, int y);

/*
 * =============================================================
 * Path Construction Functions (pdfmake_render_path.c)
 * =============================================================
 */

/* Create/destroy path */
pdfmake_path_t *pdfmake_path_create(void);
void pdfmake_path_destroy(pdfmake_path_t *path);
void pdfmake_path_clear(pdfmake_path_t *path);

/* Path construction */
pdfmake_render_err_t pdfmake_path_move_to(pdfmake_path_t *path, double x, double y);
pdfmake_render_err_t pdfmake_path_line_to(pdfmake_path_t *path, double x, double y);
pdfmake_render_err_t pdfmake_path_curve_to(pdfmake_path_t *path,
    double x1, double y1, double x2, double y2, double x3, double y3);
pdfmake_render_err_t pdfmake_path_close(pdfmake_path_t *path);
pdfmake_render_err_t pdfmake_path_rect(pdfmake_path_t *path,
    double x, double y, double w, double h);

/* Context path operations */
pdfmake_render_err_t pdfmake_render_move_to(pdfmake_render_ctx_t *ctx, double x, double y);
pdfmake_render_err_t pdfmake_render_line_to(pdfmake_render_ctx_t *ctx, double x, double y);
pdfmake_render_err_t pdfmake_render_curve_to(pdfmake_render_ctx_t *ctx,
    double x1, double y1, double x2, double y2, double x3, double y3);
pdfmake_render_err_t pdfmake_render_close_path(pdfmake_render_ctx_t *ctx);
pdfmake_render_err_t pdfmake_render_rect(pdfmake_render_ctx_t *ctx,
    double x, double y, double w, double h);
void pdfmake_render_new_path(pdfmake_render_ctx_t *ctx);

/* Path info */
int pdfmake_path_is_empty(pdfmake_path_t *path);
pdfmake_render_err_t pdfmake_path_get_bounds(pdfmake_path_t *path,
    double *x_min, double *y_min, double *x_max, double *y_max);

/*
 * =============================================================
 * Bezier Flattening Functions (pdfmake_render_bezier.c)
 * =============================================================
 */

/* Flatten cubic bezier to line segments */
pdfmake_render_err_t pdfmake_bezier_flatten(
    pdfmake_point_t p0, pdfmake_point_t p1,
    pdfmake_point_t p2, pdfmake_point_t p3,
    double tolerance,
    pdfmake_path_t *out);

/* Flatten entire path (curves -> lines) */
pdfmake_path_t *pdfmake_path_flatten(pdfmake_path_t *path, double tolerance);

/*
 * =============================================================
 * Fill Functions (pdfmake_render_fill.c)
 * =============================================================
 */

/* Fill current path */
pdfmake_render_err_t pdfmake_render_fill(pdfmake_render_ctx_t *ctx);

/* Fill and preserve path */
pdfmake_render_err_t pdfmake_render_fill_preserve(pdfmake_render_ctx_t *ctx);

/* Fill path with specific rule */
pdfmake_render_err_t pdfmake_fill_path(
    pdfmake_render_ctx_t *ctx,
    pdfmake_path_t *path,
    pdfmake_fill_rule_t rule);

/*
 * =============================================================
 * Stroke Functions (pdfmake_render_stroke.c)
 * =============================================================
 */

/* Stroke current path */
pdfmake_render_err_t pdfmake_render_stroke(pdfmake_render_ctx_t *ctx);

/* Stroke and preserve path */
pdfmake_render_err_t pdfmake_render_stroke_preserve(pdfmake_render_ctx_t *ctx);

/* Stroke path with specific style */
pdfmake_render_err_t pdfmake_stroke_path(
    pdfmake_render_ctx_t *ctx,
    pdfmake_path_t *path,
    pdfmake_stroke_style_t *style);

/* Convert stroke to fill path (for internal use) */
pdfmake_path_t *pdfmake_stroke_to_path(
    pdfmake_path_t *path,
    pdfmake_stroke_style_t *style);

/*
 * =============================================================
 * Clipping Functions (pdfmake_render_clip.c)
 * =============================================================
 */

/* Clip to current path */
pdfmake_render_err_t pdfmake_render_clip(pdfmake_render_ctx_t *ctx);

/* Clip with specific rule */
pdfmake_render_err_t pdfmake_clip_path(
    pdfmake_render_ctx_t *ctx,
    pdfmake_path_t *path,
    pdfmake_fill_rule_t rule);

/* Reset clip to full canvas */
void pdfmake_render_reset_clip(pdfmake_render_ctx_t *ctx);

/*
 * =============================================================
 * Matrix Utilities
 * =============================================================
 */

/* Identity matrix */
pdfmake_matrix_t pdfmake_matrix_identity(void);

/* Matrix multiplication: result = a * b */
pdfmake_matrix_t pdfmake_matrix_multiply(pdfmake_matrix_t *a, pdfmake_matrix_t *b);

/* Transform point by matrix */
pdfmake_point_t pdfmake_matrix_transform_point(pdfmake_matrix_t *m, pdfmake_point_t p);

/* Invert matrix (returns 0 on success, -1 if singular) */
int pdfmake_matrix_invert(pdfmake_matrix_t *m, pdfmake_matrix_t *out);

/*
 * =============================================================
 * Color Utilities
 * =============================================================
 */

/* Pack RGBA to uint32_t (ARGB format) */
static PDFMAKE_INLINE uint32_t pdfmake_color_pack(pdfmake_rgba_t c) {
    uint8_t r = (uint8_t)(c.r * 255.0 + 0.5);
    uint8_t g = (uint8_t)(c.g * 255.0 + 0.5);
    uint8_t b = (uint8_t)(c.b * 255.0 + 0.5);
    uint8_t a = (uint8_t)(c.a * 255.0 + 0.5);
    return ((uint32_t)a << 24) | ((uint32_t)r << 16) | ((uint32_t)g << 8) | b;
}

/* Unpack uint32_t to RGBA */
static PDFMAKE_INLINE pdfmake_rgba_t pdfmake_color_unpack(uint32_t packed) {
    pdfmake_rgba_t c;
    c.a = ((packed >> 24) & 0xFF) / 255.0;
    c.r = ((packed >> 16) & 0xFF) / 255.0;
    c.g = ((packed >> 8) & 0xFF) / 255.0;
    c.b = (packed & 0xFF) / 255.0;
    return c;
}

/* Blend source over destination (Porter-Duff) */
static PDFMAKE_INLINE uint32_t pdfmake_color_blend(uint32_t dst, uint32_t src) {
    uint32_t sa = (src >> 24) & 0xFF;
    uint32_t da, sr, sg, sb, dr, dg, db;
    uint32_t inv_sa, oa, or, og, ob;

    if (sa == 0) return dst;
    if (sa == 255) return src;

    da = (dst >> 24) & 0xFF;
    sr = (src >> 16) & 0xFF;
    sg = (src >> 8) & 0xFF;
    sb = src & 0xFF;
    dr = (dst >> 16) & 0xFF;
    dg = (dst >> 8) & 0xFF;
    db = dst & 0xFF;

    inv_sa = 255 - sa;
    oa = sa + ((da * inv_sa) >> 8);
    or = sr + ((dr * inv_sa) >> 8);
    og = sg + ((dg * inv_sa) >> 8);
    ob = sb + ((db * inv_sa) >> 8);

    return (oa << 24) | (or << 16) | (og << 8) | ob;
}

#ifdef __cplusplus
}
#endif

#endif /* PDFMAKE_RENDER_H */
