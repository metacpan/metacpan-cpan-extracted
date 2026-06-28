/*
 * pdfmake_image_render.h - Image rendering types and API for Chandra
 *
 * Extends pdfmake_image.h with rendering-specific types and functions
 * for decoding and compositing images onto a render context.
 *
 * Reference: PDF 32000-1:2008
 * - §8.9 Images
 * - §8.6 Colour Spaces
 * - §11.6.6 Soft Masks
 */

#ifndef PDFMAKE_IMAGE_RENDER_H
#define PDFMAKE_IMAGE_RENDER_H

#include "pdfmake_types.h"

#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

/*
 * Forward declarations
 */
#ifndef PDFMAKE_RENDER_CTX_T_DEFINED
#define PDFMAKE_RENDER_CTX_T_DEFINED
typedef struct pdfmake_render_ctx pdfmake_render_ctx_t;
#endif
#ifndef PDFMAKE_ARENA_T_DEFINED
#define PDFMAKE_ARENA_T_DEFINED
typedef struct pdfmake_arena pdfmake_arena_t;
#endif

/*============================================================================
 * Error codes
 *==========================================================================*/

typedef enum {
    PDFMAKE_IMGR_OK = 0,
    PDFMAKE_IMGR_ERR_NULL,
    PDFMAKE_IMGR_ERR_MEMORY,
    PDFMAKE_IMGR_ERR_INVALID,
    PDFMAKE_IMGR_ERR_UNSUPPORTED,
    PDFMAKE_IMGR_ERR_DECODE_FAILED,
    PDFMAKE_IMGR_ERR_COLORSPACE,
} pdfmake_imgr_err_t;

/*============================================================================
 * Color spaces for rendering
 *==========================================================================*/

typedef enum {
    PDFMAKE_RCS_GRAY = 1,       /* 1 component */
    PDFMAKE_RCS_RGB = 3,        /* 3 components */
    PDFMAKE_RCS_CMYK = 4,       /* 4 components */
    PDFMAKE_RCS_INDEXED = 5,    /* Palette-based */
    PDFMAKE_RCS_LAB = 6,        /* CIE Lab */
} pdfmake_render_cs_t;

/*============================================================================
 * Scaling/interpolation modes
 *==========================================================================*/

typedef enum {
    PDFMAKE_INTERP_NEAREST = 0, /* Nearest neighbor - fast */
    PDFMAKE_INTERP_BILINEAR,    /* Bilinear - smooth */
    PDFMAKE_INTERP_BICUBIC,     /* Bicubic - high quality */
} pdfmake_interp_mode_t;

/*============================================================================
 * Decoded image for rendering
 *==========================================================================*/

typedef struct pdfmake_decoded_image {
    /* Dimensions */
    int width;
    int height;
    int bits_per_component;     /* Typically 8 after decode */
    int components;             /* 1, 3, or 4 */
    
    /* Color space */
    pdfmake_render_cs_t colorspace;
    
    /* Pixel data (row-major, top to bottom) */
    uint8_t *pixels;
    size_t pixels_len;
    size_t row_stride;
    
    /* Alpha channel (separate soft mask) */
    uint8_t *alpha;
    size_t alpha_len;
    
    /* Pre-converted RGBA for fast blitting */
    uint32_t *rgba;
    size_t rgba_len;
    
    /* Palette for indexed images */
    uint8_t *palette;           /* RGB triplets */
    size_t palette_entries;
    
    /* Decode array [Dmin0, Dmax0, Dmin1, Dmax1, ...] */
    double *decode;
    size_t decode_len;
    
    /* Matte color for pre-multiplied alpha */
    double *matte;
    
    /* Flags */
    uint8_t interpolate;        /* Use interpolation when scaling */
    uint8_t has_alpha;          /* Has alpha channel */
    uint8_t premultiplied;      /* Alpha is premultiplied */
    
    /* Memory ownership */
    pdfmake_arena_t *arena;
    uint8_t owns_data;
} pdfmake_decoded_image_t;

/*============================================================================
 * API - Decoded image creation
 *==========================================================================*/

/*
 * Create a decoded image structure.
 */
pdfmake_decoded_image_t *pdfmake_decoded_image_create(
    pdfmake_arena_t *arena);

/*
 * Create with dimensions and allocate pixel buffer.
 */
pdfmake_decoded_image_t *pdfmake_decoded_image_create_sized(
    int width, int height,
    pdfmake_render_cs_t colorspace,
    pdfmake_arena_t *arena);

/*
 * Free decoded image.
 */
void pdfmake_decoded_image_free(pdfmake_decoded_image_t *img);

/*
 * Clone a decoded image.
 */
pdfmake_decoded_image_t *pdfmake_decoded_image_clone(
    pdfmake_decoded_image_t *src,
    pdfmake_arena_t *arena);

/*============================================================================
 * API - Pixel access
 *==========================================================================*/

/*
 * Get row pointer.
 */
static PDFMAKE_INLINE uint8_t *pdfmake_decoded_image_row(
    pdfmake_decoded_image_t *img, int y) {
    if (!img || !img->pixels || y < 0 || y >= img->height) return NULL;
    return img->pixels + y * img->row_stride;
}

/*
 * Get pixel components at (x, y).
 * out must have room for img->components values (0-255).
 */
void pdfmake_decoded_image_get_pixel(
    pdfmake_decoded_image_t *img,
    int x, int y,
    uint8_t *out);

/*
 * Get alpha at (x, y). Returns 255 if no alpha.
 */
uint8_t pdfmake_decoded_image_get_alpha(
    pdfmake_decoded_image_t *img,
    int x, int y);

/*
 * Get RGBA pixel (with color conversion if needed).
 */
uint32_t pdfmake_decoded_image_get_rgba(
    pdfmake_decoded_image_t *img,
    int x, int y);

/*============================================================================
 * API - Color space conversion
 *==========================================================================*/

/*
 * Convert image to RGBA for rendering.
 * Produces 32-bit ARGB values.
 */
pdfmake_imgr_err_t pdfmake_decoded_image_to_rgba(
    pdfmake_decoded_image_t *img,
    pdfmake_arena_t *arena);

/*
 * Expand indexed colorspace to RGB.
 */
pdfmake_imgr_err_t pdfmake_decoded_image_expand_indexed(
    pdfmake_decoded_image_t *img,
    pdfmake_arena_t *arena);

/*
 * Apply decode array to image data.
 */
void pdfmake_decoded_image_apply_decode(pdfmake_decoded_image_t *img);

/*============================================================================
 * API - Color conversion utilities
 *==========================================================================*/

/*
 * CMYK to RGB (0-255 scale).
 * Simple formula: R = 255 * (1-C) * (1-K), etc.
 */
void pdfmake_cmyk_to_rgb8(
    uint8_t c, uint8_t m, uint8_t y, uint8_t k,
    uint8_t *r, uint8_t *g, uint8_t *b);

/*
 * CMYK to RGB (0.0-1.0 scale).
 */
void pdfmake_cmyk_to_rgb_f(
    double c, double m, double y, double k,
    double *r, double *g, double *b);

/*
 * Lab to RGB (L: 0-100, a,b: -128 to 127).
 */
void pdfmake_lab_to_rgb8(
    double L, double a, double b,
    uint8_t *r, uint8_t *g, uint8_t *bl);

/*
 * Lab to XYZ (intermediate step).
 */
void pdfmake_lab_to_xyz(
    double L, double a, double b,
    double *x, double *y, double *z);

/*
 * XYZ to sRGB.
 */
void pdfmake_xyz_to_srgb(
    double x, double y, double z,
    double *r, double *g, double *b);

/*============================================================================
 * API - Image scaling
 *==========================================================================*/

/*
 * Scale image to new dimensions.
 */
pdfmake_imgr_err_t pdfmake_decoded_image_scale(
    pdfmake_decoded_image_t *src,
    int dst_width, int dst_height,
    pdfmake_interp_mode_t mode,
    pdfmake_decoded_image_t **out,
    pdfmake_arena_t *arena);

/*
 * Scale RGBA image (faster path when already converted).
 */
pdfmake_imgr_err_t pdfmake_rgba_scale(
    const uint32_t *src, int src_w, int src_h,
    uint32_t *dst, int dst_w, int dst_h,
    pdfmake_interp_mode_t mode);

/*============================================================================
 * API - Image rendering
 *==========================================================================*/

/*
 * Render image to render context.
 * Uses current CTM to position the image.
 * Image is defined in a 1x1 unit square.
 */
pdfmake_imgr_err_t pdfmake_render_decoded_image(
    pdfmake_render_ctx_t *ctx,
    pdfmake_decoded_image_t *img);

/*
 * Render image at specific position and size.
 */
pdfmake_imgr_err_t pdfmake_render_decoded_image_at(
    pdfmake_render_ctx_t *ctx,
    pdfmake_decoded_image_t *img,
    double x, double y,
    double width, double height);

/*
 * Blit RGBA image to context at position.
 * No scaling, direct pixel copy with alpha blending.
 */
void pdfmake_render_blit_rgba(
    pdfmake_render_ctx_t *ctx,
    const uint32_t *rgba,
    int img_w, int img_h,
    int dst_x, int dst_y);

/*
 * Blit with scaling and alpha.
 */
void pdfmake_render_blit_scaled(
    pdfmake_render_ctx_t *ctx,
    const uint32_t *rgba,
    int img_w, int img_h,
    int dst_x, int dst_y,
    int dst_w, int dst_h,
    pdfmake_interp_mode_t mode);

/*============================================================================
 * API - Alpha compositing
 *==========================================================================*/

/*
 * Blend source over destination (Porter-Duff Source Over).
 * dst and src are ARGB packed.
 */
static PDFMAKE_INLINE uint32_t pdfmake_blend_over(uint32_t dst, uint32_t src) {
    uint32_t sa = (src >> 24) & 0xFF;
    uint32_t da, sr, sg, sb, dr, dg, db;
    uint32_t inv_sa, oa, or_val, og, ob;

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
    oa = sa + ((da * inv_sa + 127) / 255);
    or_val = sr + ((dr * inv_sa + 127) / 255);
    og = sg + ((dg * inv_sa + 127) / 255);
    ob = sb + ((db * inv_sa + 127) / 255);

    return (oa << 24) | (or_val << 16) | (og << 8) | ob;
}

/*
 * Multiply alpha into RGB (premultiply).
 */
static PDFMAKE_INLINE uint32_t pdfmake_premultiply(uint32_t rgba) {
    uint32_t a = (rgba >> 24) & 0xFF;
    uint32_t r, g, b;

    if (a == 255) return rgba;
    if (a == 0) return 0;

    r = ((rgba >> 16) & 0xFF) * a / 255;
    g = ((rgba >> 8) & 0xFF) * a / 255;
    b = (rgba & 0xFF) * a / 255;

    return (a << 24) | (r << 16) | (g << 8) | b;
}

/*============================================================================
 * API - JPEG decoding (for rendering)
 *==========================================================================*/

/*
 * Decode JPEG data to decoded image.
 * Uses stb_image internally.
 */
pdfmake_imgr_err_t pdfmake_decode_jpeg_to_image(
    const uint8_t *data, size_t len,
    pdfmake_decoded_image_t **out,
    pdfmake_arena_t *arena);

/*
 * Decode JPEG data to raw pixels.
 */
pdfmake_imgr_err_t pdfmake_decode_jpeg_raw(
    const uint8_t *data, size_t len,
    uint8_t **pixels_out, size_t *pixels_len,
    int *width, int *height, int *components);

/*============================================================================
 * Utility macros
 *==========================================================================*/

/* Pack RGBA to uint32 (ARGB format) */
#define PDFMAKE_RGBA(r, g, b, a) \
    (((uint32_t)(a) << 24) | ((uint32_t)(r) << 16) | ((uint32_t)(g) << 8) | (b))

/* Unpack components from uint32 */
#define PDFMAKE_RGBA_A(c) (((c) >> 24) & 0xFF)
#define PDFMAKE_RGBA_R(c) (((c) >> 16) & 0xFF)
#define PDFMAKE_RGBA_G(c) (((c) >> 8) & 0xFF)
#define PDFMAKE_RGBA_B(c) ((c) & 0xFF)

/* Linear interpolation */
#define PDFMAKE_LERP(a, b, t) ((a) + ((b) - (a)) * (t))

/* Clamp value to 0-255 */
#define PDFMAKE_CLAMP8(v) ((v) < 0 ? 0 : ((v) > 255 ? 255 : (v)))

/* Calculate row stride */
static PDFMAKE_INLINE size_t pdfmake_decoded_row_stride(int width, int components) {
    return (size_t)width * components;
}

#ifdef __cplusplus
}
#endif

#endif /* PDFMAKE_IMAGE_RENDER_H */
