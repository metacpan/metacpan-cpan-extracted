/* pdfmake_render_page.c
 *
 * Page-render utility implementations.
 *
 * Currently implemented:
 *   - pdfmake_render_opts_init       (real)
 *   - pdfmake_page_get_render_size   (real — MediaBox + Rotate + DPI)
 *   - pdfmake_page_render_free       (real)
 *
 * Stubbed (return PDFMAKE_ERENDER_PAGE until the rasterizer lands):
 *   - pdfmake_render_page_to_pixels
 *   - pdfmake_render_page_region
 *
 * These exist so the linker can resolve every symbol referenced from
 * xs/render_page.xs under PERL_DL_NONLAZY=1 (which `make test` sets).
 *
 * NOTE: We intentionally avoid including pdfmake_render_page.h because it
 * pulls in pdfmake_render.h and pdfmake_interpreter.h, which currently
 * declare matrix helpers with conflicting signatures. Local type
 * declarations below mirror the public header (and Make.xs forward
 * declarations) exactly so the ABI is identical.
 */

#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <stdint.h>

#include "pdfmake_types.h"
#include "pdfmake_reader.h"

/*============================================================================
 * Locally declared types — must match include/pdfmake_render_page.h
 *==========================================================================*/

#define PDFMAKE_ERENDER_PAGE   50

typedef enum {
    PDFMAKE_SCALE_NEAREST  = 0,
    PDFMAKE_SCALE_BILINEAR = 1,
    PDFMAKE_SCALE_BICUBIC  = 2,
} pdfmake_scale_mode_t;

typedef enum {
    PDFMAKE_ROTATE_0   = 0,
    PDFMAKE_ROTATE_90  = 90,
    PDFMAKE_ROTATE_180 = 180,
    PDFMAKE_ROTATE_270 = 270,
} pdfmake_rotation_t;

typedef struct pdfmake_render_opts {
    double dpi;
    double scale;
    pdfmake_scale_mode_t scale_mode;
    int antialias;
    double flatness;
    pdfmake_rotation_t rotation;
    uint32_t background;
    double clip_x, clip_y;
    double clip_width, clip_height;
    int use_clip;
    int render_text;
    int render_images;
    int render_vectors;
    int render_annotations;
    int show_text_bounds;
    int show_image_bounds;
    int show_clip_regions;
} pdfmake_render_opts_t;

typedef struct pdfmake_page_render {
    uint32_t *pixels;
    int width;
    int height;
    int stride;
    double page_width;
    double page_height;
    double effective_dpi;
    int text_objects;
    int path_objects;
    int image_objects;
    double render_time_ms;
    int error_count;
    char error_msg[256];
} pdfmake_page_render_t;

/*============================================================================
 * Options initialization
 *==========================================================================*/

void pdfmake_render_opts_init(pdfmake_render_opts_t *opts)
{
    if (!opts) return;
    memset(opts, 0, sizeof(*opts));
    opts->dpi                = 72.0;
    opts->scale              = 1.0;
    opts->scale_mode         = PDFMAKE_SCALE_BILINEAR;
    opts->antialias          = 2;
    opts->flatness           = 1.0;
    opts->rotation           = PDFMAKE_ROTATE_0;
    opts->background         = 0xFFFFFFFFu;   /* opaque white (ARGB) */
    opts->render_text        = 1;
    opts->render_images      = 1;
    opts->render_vectors     = 1;
    opts->render_annotations = 0;
}

/*============================================================================
 * Page render size — proper implementation
 *
 * Computes the on-screen pixel dimensions of a page, taking MediaBox and
 * /Rotate into account. Page width/height in PDF user space (points) are
 * converted to pixels via:
 *
 *     pixels = points * dpi / 72.0
 *
 * For 90° / 270° rotations the width and height are swapped, matching the
 * orientation a renderer would produce.
 *==========================================================================*/

void pdfmake_page_get_render_size(
    pdfmake_reader_t *reader,
    int page_num,
    double dpi,
    int *width, int *height)
{
    pdfmake_reader_page_t *page;
    double mb[4];
    double pts_w, pts_h, px_w, px_h;
    int rot, w, h;

    if (width)  *width  = 0;
    if (height) *height = 0;
    if (!reader || page_num < 0) return;
    if (dpi <= 0.0) dpi = 72.0;

    page = pdfmake_reader_page_at(reader, (size_t)page_num);
    if (!page) return;

    mb[0] = 0; mb[1] = 0; mb[2] = 0; mb[3] = 0;
    if (pdfmake_reader_page_media_box(reader, page, mb) != PDFMAKE_OK)
        return;

    pts_w = mb[2] - mb[0];
    pts_h = mb[3] - mb[1];
    if (pts_w < 0) pts_w = -pts_w;
    if (pts_h < 0) pts_h = -pts_h;

    rot = pdfmake_reader_page_rotation(reader, page);
    /* Normalize to {0, 90, 180, 270}. */
    rot = ((rot % 360) + 360) % 360;
    if (rot == 90 || rot == 270) {
        double tmp = pts_w;
        pts_w = pts_h;
        pts_h = tmp;
    }

    px_w = pts_w * dpi / 72.0;
    px_h = pts_h * dpi / 72.0;

    /* Round to nearest, clamp >= 1 when the page is non-empty. */
    w = (int)floor(px_w + 0.5);
    h = (int)floor(px_h + 0.5);
    if (pts_w > 0.0 && w < 1) w = 1;
    if (pts_h > 0.0 && h < 1) h = 1;

    if (width)  *width  = w;
    if (height) *height = h;
}

/*============================================================================
 * Page render result lifecycle
 *==========================================================================*/

void pdfmake_page_render_free(pdfmake_page_render_t *result)
{
    if (!result) return;
    if (result->pixels) {
        free(result->pixels);
        result->pixels = NULL;
    }
    result->width = 0;
    result->height = 0;
    result->stride = 0;
}

/*============================================================================
 * Page rasterization — not yet implemented
 *
 * The full rasterizer (content-stream interpreter wired to the render
 * context) has not been ported yet. These entry points return a non-OK
 * status so callers in XS land croak with a clear "error N" rather than
 * crashing or producing garbage. The bundle still links cleanly under
 * PERL_DL_NONLAZY=1.
 *==========================================================================*/

static void render_result_init_failed(pdfmake_page_render_t *result,
                                      const char *msg)
{
    if (!result) return;
    memset(result, 0, sizeof(*result));
    result->error_count = 1;
    if (msg) {
        size_t n = strlen(msg);
        if (n >= sizeof(result->error_msg))
            n = sizeof(result->error_msg) - 1;
        memcpy(result->error_msg, msg, n);
        result->error_msg[n] = '\0';
    }
}

pdfmake_err_t pdfmake_render_page_to_pixels(
    pdfmake_reader_t *reader,
    int page_num,
    const pdfmake_render_opts_t *opts,
    pdfmake_page_render_t *result)
{
    (void)reader; (void)page_num; (void)opts;
    render_result_init_failed(result,
        "pdfmake_render_page_to_pixels: rasterizer not implemented");
    return (pdfmake_err_t)PDFMAKE_ERENDER_PAGE;
}

pdfmake_err_t pdfmake_render_page_region(
    pdfmake_reader_t *reader,
    int page_num,
    double region_x, double region_y,
    double region_w, double region_h,
    const pdfmake_render_opts_t *opts,
    pdfmake_page_render_t *result)
{
    (void)reader; (void)page_num;
    (void)region_x; (void)region_y; (void)region_w; (void)region_h;
    (void)opts;
    render_result_init_failed(result,
        "pdfmake_render_page_region: rasterizer not implemented");
    return (pdfmake_err_t)PDFMAKE_ERENDER_PAGE;
}
