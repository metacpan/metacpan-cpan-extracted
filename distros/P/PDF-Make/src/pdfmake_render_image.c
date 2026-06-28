/* pdfmake_render_image.c
 *
 * Stubs for the image-blitting / image-rendering API declared in
 * include/pdfmake_image_render.h. Exists so the bundle links cleanly
 * under PERL_DL_NONLAZY=1; real implementations will replace these
 * once the rasterizer lands.
 */

#include <stddef.h>
#include "pdfmake_image_render.h"

pdfmake_imgr_err_t pdfmake_render_decoded_image(
    pdfmake_render_ctx_t *ctx,
    pdfmake_decoded_image_t *img)
{
    (void)ctx; (void)img;
    return PDFMAKE_IMGR_ERR_UNSUPPORTED;
}

pdfmake_imgr_err_t pdfmake_render_decoded_image_at(
    pdfmake_render_ctx_t *ctx,
    pdfmake_decoded_image_t *img,
    double x, double y,
    double width, double height)
{
    (void)ctx; (void)img;
    (void)x; (void)y; (void)width; (void)height;
    return PDFMAKE_IMGR_ERR_UNSUPPORTED;
}

void pdfmake_render_blit_rgba(
    pdfmake_render_ctx_t *ctx,
    const uint32_t *rgba,
    int img_w, int img_h,
    int dst_x, int dst_y)
{
    (void)ctx; (void)rgba;
    (void)img_w; (void)img_h;
    (void)dst_x; (void)dst_y;
}

void pdfmake_render_blit_scaled(
    pdfmake_render_ctx_t *ctx,
    const uint32_t *rgba,
    int img_w, int img_h,
    int dst_x, int dst_y,
    int dst_w, int dst_h,
    pdfmake_interp_mode_t mode)
{
    (void)ctx; (void)rgba;
    (void)img_w; (void)img_h;
    (void)dst_x; (void)dst_y;
    (void)dst_w; (void)dst_h;
    (void)mode;
}
