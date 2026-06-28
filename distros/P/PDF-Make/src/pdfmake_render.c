/* pdfmake_render.c
 *
 * Render-context API stubs.
 *
 * The full software rasterizer (scanline fill, stroke flattening, AA, image
 * blitting, etc.) has not been ported into this distribution yet. The
 * companion source files for sub-systems that *are* implemented live in:
 *
 *   src/pdfmake_render_path.c    — pdfmake_path_* construction
 *   src/pdfmake_render_bezier.c  — bezier flattening
 *   src/pdfmake_render_fill.c    — fill / fill_preserve
 *   src/pdfmake_render_stroke.c  — stroke / stroke_preserve
 *   src/pdfmake_render_clip.c    — clip / reset_clip
 *
 * This file provides minimal stubs for every pdfmake_render_* symbol
 * declared in include/pdfmake_render.h that doesn't already have an
 * implementation elsewhere. The stubs:
 *
 *   - allocate / free a zero-initialised pdfmake_render_ctx_t (so create
 *     and destroy round-trip safely);
 *   - record the most-recently set graphics-state field on the context
 *     where it makes sense (so future incremental work can replace stubs
 *     one at a time without breaking calling code);
 *   - no-op for path / blit / scan operations and return a non-OK code
 *     when the signature returns pdfmake_render_err_t.
 *
 * The point of these stubs is simply to make the bundle link cleanly so
 * Perl can load Make.bundle under PERL_DL_NONLAZY=1 (which `make test`
 * sets). No live test exercises this API today; when the rasterizer
 * lands these stubs should be removed and replaced with real code.
 */

#include <stdlib.h>
#include <string.h>
#include <math.h>

#include "pdfmake_render.h"

/*============================================================================
 * Render context lifecycle
 *==========================================================================*/

static pdfmake_render_ctx_t *render_ctx_alloc(int width, int height)
{
    pdfmake_render_ctx_t *ctx = calloc(1, sizeof(*ctx));
    if (!ctx) return NULL;
    ctx->width      = width  > 0 ? width  : 0;
    ctx->height     = height > 0 ? height : 0;
    ctx->stride     = ctx->width * (int)sizeof(uint32_t);
    /* Identity CTM */
    ctx->ctm = (pdfmake_matrix_t){1.0, 0.0, 0.0, 1.0, 0.0, 0.0};
    ctx->fill_color   = (pdfmake_rgba_t){0.0, 0.0, 0.0, 1.0};
    ctx->stroke_color = (pdfmake_rgba_t){0.0, 0.0, 0.0, 1.0};
    ctx->fill_rule  = PDFMAKE_FILL_NONZERO;
    ctx->flatness   = 1.0;
    ctx->antialias  = 2;
    ctx->stroke_style.width = 1.0;
    ctx->stroke_style.cap   = PDFMAKE_CAP_BUTT;
    ctx->stroke_style.join  = PDFMAKE_JOIN_MITER;
    ctx->stroke_style.miter_limit = 10.0;
    return ctx;
}

pdfmake_render_ctx_t *pdfmake_render_create(int width, int height)
{
    pdfmake_render_ctx_t *ctx = render_ctx_alloc(width, height);
    if (!ctx) return NULL;
    if (ctx->width > 0 && ctx->height > 0) {
        ctx->pixels = calloc((size_t)ctx->width * (size_t)ctx->height,
                             sizeof(uint32_t));
        if (!ctx->pixels) {
            free(ctx);
            return NULL;
        }
        ctx->owns_buffer = 1;
    }
    return ctx;
}

pdfmake_render_ctx_t *pdfmake_render_create_with_buffer(
    uint32_t *pixels, int width, int height, int stride)
{
    pdfmake_render_ctx_t *ctx = render_ctx_alloc(width, height);
    if (!ctx) return NULL;
    ctx->pixels      = pixels;
    ctx->stride      = stride > 0 ? stride : ctx->stride;
    ctx->owns_buffer = 0;
    return ctx;
}

void pdfmake_render_destroy(pdfmake_render_ctx_t *ctx)
{
    if (!ctx) return;
    if (ctx->owns_buffer && ctx->pixels) free(ctx->pixels);
    if (ctx->clip_mask) free(ctx->clip_mask);
    if (ctx->stroke_style.dash_array) free(ctx->stroke_style.dash_array);
    if (ctx->gstate_stack) free(ctx->gstate_stack);
    free(ctx);
}

/*============================================================================
 * Buffer ops
 *==========================================================================*/

static uint32_t rgba_to_argb(pdfmake_rgba_t c)
{
    double a = c.a < 0 ? 0 : (c.a > 1 ? 1 : c.a);
    double r = c.r < 0 ? 0 : (c.r > 1 ? 1 : c.r);
    double g = c.g < 0 ? 0 : (c.g > 1 ? 1 : c.g);
    double b = c.b < 0 ? 0 : (c.b > 1 ? 1 : c.b);
    return ((uint32_t)(a * 255.0 + 0.5) << 24)
         | ((uint32_t)(r * 255.0 + 0.5) << 16)
         | ((uint32_t)(g * 255.0 + 0.5) << 8)
         |  (uint32_t)(b * 255.0 + 0.5);
}

void pdfmake_render_clear(pdfmake_render_ctx_t *ctx, pdfmake_rgba_t color)
{
    uint32_t packed;
    size_t total;
    size_t i;
    if (!ctx || !ctx->pixels) return;
    packed = rgba_to_argb(color);
    total = (size_t)ctx->width * (size_t)ctx->height;
    for (i = 0; i < total; i++) ctx->pixels[i] = packed;
}

uint32_t pdfmake_render_get_pixel(pdfmake_render_ctx_t *ctx, int x, int y)
{
    if (!ctx || !ctx->pixels) return 0;
    if (x < 0 || y < 0 || x >= ctx->width || y >= ctx->height) return 0;
    return ctx->pixels[(size_t)y * (size_t)ctx->width + (size_t)x];
}

/*============================================================================
 * Graphics-state stack (save / restore)
 *==========================================================================*/

pdfmake_render_err_t pdfmake_render_save(pdfmake_render_ctx_t *ctx)
{
    pdfmake_gstate_t *g;
    if (!ctx) return PDFMAKE_RENDER_ERR_NULL;
    if (ctx->gstate_depth >= ctx->gstate_max) {
        int new_max = ctx->gstate_max ? ctx->gstate_max * 2 : 8;
        pdfmake_gstate_t *grown = realloc(ctx->gstate_stack,
            (size_t)new_max * sizeof(*grown));
        if (!grown) return PDFMAKE_RENDER_ERR_MEMORY;
        ctx->gstate_stack = grown;
        ctx->gstate_max   = new_max;
    }
    g = &ctx->gstate_stack[ctx->gstate_depth++];
    g->ctm          = ctx->ctm;
    g->fill_color   = ctx->fill_color;
    g->stroke_color = ctx->stroke_color;
    g->stroke_style = ctx->stroke_style;
    g->fill_rule    = ctx->fill_rule;
    g->clip_mask    = NULL;       /* shallow snapshot only */
    g->has_clip     = ctx->has_clip;
    g->flatness     = ctx->flatness;
    return PDFMAKE_RENDER_OK;
}

pdfmake_render_err_t pdfmake_render_restore(pdfmake_render_ctx_t *ctx)
{
    pdfmake_gstate_t *g;
    if (!ctx) return PDFMAKE_RENDER_ERR_NULL;
    if (ctx->gstate_depth <= 0) return PDFMAKE_RENDER_ERR_INVALID;
    g = &ctx->gstate_stack[--ctx->gstate_depth];
    ctx->ctm          = g->ctm;
    ctx->fill_color   = g->fill_color;
    ctx->stroke_color = g->stroke_color;
    ctx->stroke_style = g->stroke_style;
    ctx->fill_rule    = g->fill_rule;
    ctx->has_clip     = g->has_clip;
    ctx->flatness     = g->flatness;
    return PDFMAKE_RENDER_OK;
}

/*============================================================================
 * Graphics-state setters
 *==========================================================================*/

void pdfmake_render_set_fill_color(pdfmake_render_ctx_t *ctx,
                                   double r, double g, double b, double a)
{
    if (!ctx) return;
    ctx->fill_color = (pdfmake_rgba_t){r, g, b, a};
}

void pdfmake_render_set_stroke_color(pdfmake_render_ctx_t *ctx,
                                     double r, double g, double b, double a)
{
    if (!ctx) return;
    ctx->stroke_color = (pdfmake_rgba_t){r, g, b, a};
}

void pdfmake_render_set_line_width(pdfmake_render_ctx_t *ctx, double width)
{
    if (!ctx) return;
    ctx->stroke_style.width = width;
}

void pdfmake_render_set_line_cap(pdfmake_render_ctx_t *ctx,
                                 pdfmake_line_cap_t cap)
{
    if (!ctx) return;
    ctx->stroke_style.cap = cap;
}

void pdfmake_render_set_line_join(pdfmake_render_ctx_t *ctx,
                                  pdfmake_line_join_t join)
{
    if (!ctx) return;
    ctx->stroke_style.join = join;
}

void pdfmake_render_set_miter_limit(pdfmake_render_ctx_t *ctx, double limit)
{
    if (!ctx) return;
    ctx->stroke_style.miter_limit = limit;
}

pdfmake_render_err_t pdfmake_render_set_dash(pdfmake_render_ctx_t *ctx,
                                             double *array, size_t count,
                                             double phase)
{
    if (!ctx) return PDFMAKE_RENDER_ERR_NULL;
    if (ctx->stroke_style.dash_array) {
        free(ctx->stroke_style.dash_array);
        ctx->stroke_style.dash_array = NULL;
        ctx->stroke_style.dash_count = 0;
    }
    if (array && count > 0) {
        double *copy = malloc(count * sizeof(double));
        if (!copy) return PDFMAKE_RENDER_ERR_MEMORY;
        memcpy(copy, array, count * sizeof(double));
        ctx->stroke_style.dash_array = copy;
        ctx->stroke_style.dash_count = count;
    }
    ctx->stroke_style.dash_phase = phase;
    return PDFMAKE_RENDER_OK;
}

void pdfmake_render_set_fill_rule(pdfmake_render_ctx_t *ctx,
                                  pdfmake_fill_rule_t rule)
{
    if (!ctx) return;
    ctx->fill_rule = rule;
}

void pdfmake_render_set_flatness(pdfmake_render_ctx_t *ctx, double flatness)
{
    if (!ctx) return;
    ctx->flatness = flatness > 0 ? flatness : 1.0;
}

/*============================================================================
 * Transformations
 *
 * NOTE: pdfmake_matrix_identity / multiply / transform_point / invert are
 * already provided by src/pdfmake_interpreter.c (with a different ABI —
 * double[6] arrays — declared in pdfmake_interpreter.h). We deliberately
 * do NOT redefine them here; instead the context helpers below operate
 * directly on the pdfmake_matrix_t struct fields to avoid linker
 * collisions.
 *==========================================================================*/

static pdfmake_matrix_t matrix_mul_struct(pdfmake_matrix_t a,
                                          pdfmake_matrix_t b)
{
    pdfmake_matrix_t r;
    r.a = a.a * b.a + a.b * b.c;
    r.b = a.a * b.b + a.b * b.d;
    r.c = a.c * b.a + a.d * b.c;
    r.d = a.c * b.b + a.d * b.d;
    r.e = a.e * b.a + a.f * b.c + b.e;
    r.f = a.e * b.b + a.f * b.d + b.f;
    return r;
}

void pdfmake_render_set_matrix(pdfmake_render_ctx_t *ctx, pdfmake_matrix_t *m)
{
    if (!ctx || !m) return;
    ctx->ctm = *m;
}

void pdfmake_render_concat_matrix(pdfmake_render_ctx_t *ctx,
                                  pdfmake_matrix_t *m)
{
    if (!ctx || !m) return;
    ctx->ctm = matrix_mul_struct(*m, ctx->ctm);
}

void pdfmake_render_translate(pdfmake_render_ctx_t *ctx,
                              double tx, double ty)
{
    pdfmake_matrix_t t;
    if (!ctx) return;
    t.a = 1.0; t.b = 0.0; t.c = 0.0; t.d = 1.0; t.e = tx; t.f = ty;
    ctx->ctm = matrix_mul_struct(t, ctx->ctm);
}

void pdfmake_render_scale(pdfmake_render_ctx_t *ctx, double sx, double sy)
{
    pdfmake_matrix_t s;
    if (!ctx) return;
    s.a = sx; s.b = 0.0; s.c = 0.0; s.d = sy; s.e = 0.0; s.f = 0.0;
    ctx->ctm = matrix_mul_struct(s, ctx->ctm);
}

void pdfmake_render_rotate(pdfmake_render_ctx_t *ctx, double angle)
{
    double c, s;
    pdfmake_matrix_t r;
    if (!ctx) return;
    c = cos(angle); s = sin(angle);
    r.a = c; r.b = s; r.c = -s; r.d = c; r.e = 0.0; r.f = 0.0;
    ctx->ctm = matrix_mul_struct(r, ctx->ctm);
}

/*============================================================================
 * Context-level path helpers
 *
 * These wrap the pdfmake_path_* construction API onto the context's
 * current path. They are real, working implementations.
 *==========================================================================*/

static pdfmake_render_err_t ensure_path(pdfmake_render_ctx_t *ctx)
{
    if (!ctx) return PDFMAKE_RENDER_ERR_NULL;
    if (!ctx->path) {
        ctx->path = pdfmake_path_create();
        if (!ctx->path) return PDFMAKE_RENDER_ERR_MEMORY;
    }
    return PDFMAKE_RENDER_OK;
}

pdfmake_render_err_t pdfmake_render_move_to(pdfmake_render_ctx_t *ctx,
                                            double x, double y)
{
    pdfmake_render_err_t e = ensure_path(ctx);
    if (e != PDFMAKE_RENDER_OK) return e;
    return pdfmake_path_move_to(ctx->path, x, y);
}

pdfmake_render_err_t pdfmake_render_line_to(pdfmake_render_ctx_t *ctx,
                                            double x, double y)
{
    pdfmake_render_err_t e = ensure_path(ctx);
    if (e != PDFMAKE_RENDER_OK) return e;
    return pdfmake_path_line_to(ctx->path, x, y);
}

pdfmake_render_err_t pdfmake_render_curve_to(pdfmake_render_ctx_t *ctx,
    double x1, double y1, double x2, double y2, double x3, double y3)
{
    pdfmake_render_err_t e = ensure_path(ctx);
    if (e != PDFMAKE_RENDER_OK) return e;
    return pdfmake_path_curve_to(ctx->path, x1, y1, x2, y2, x3, y3);
}

pdfmake_render_err_t pdfmake_render_close_path(pdfmake_render_ctx_t *ctx)
{
    if (!ctx || !ctx->path) return PDFMAKE_RENDER_ERR_NULL;
    return pdfmake_path_close(ctx->path);
}

pdfmake_render_err_t pdfmake_render_rect(pdfmake_render_ctx_t *ctx,
                                         double x, double y,
                                         double w, double h)
{
    pdfmake_render_err_t e = ensure_path(ctx);
    if (e != PDFMAKE_RENDER_OK) return e;
    return pdfmake_path_rect(ctx->path, x, y, w, h);
}

void pdfmake_render_new_path(pdfmake_render_ctx_t *ctx)
{
    if (!ctx) return;
    if (ctx->path) pdfmake_path_clear(ctx->path);
}
