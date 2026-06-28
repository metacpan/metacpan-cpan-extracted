/*
 * pdfmake_colorspace.c - Color space conversion for image rendering
 *
 * Implements color space conversions needed for PDF image rendering:
 * - CMYK to RGB (subtractive to additive)
 * - Lab to RGB (via XYZ)
 * - Indexed to RGB (palette expansion)
 * - Decode array application
 *
 * Reference: PDF 32000-1:2008 §8.6 Colour Spaces
 */

#include "pdfmake_image_render.h"
#include "pdfmake_arena.h"
#include <stdlib.h>
#include <string.h>
#include <math.h>

/*============================================================================
 * CMYK to RGB conversion
 *
 * PDF CMYK is device-dependent. We use simple conversion:
 * R = 255 * (1 - C) * (1 - K)
 * G = 255 * (1 - M) * (1 - K)
 * B = 255 * (1 - Y) * (1 - K)
 *==========================================================================*/

void pdfmake_cmyk_to_rgb8(
    uint8_t c, uint8_t m, uint8_t y, uint8_t k,
    uint8_t *r, uint8_t *g, uint8_t *b)
{
    /* Convert from 0-255 to 0-1 */
    double cf = c / 255.0;
    double mf = m / 255.0;
    double yf = y / 255.0;
    double kf = k / 255.0;
    
    /* CMYK to RGB */
    double rf = (1.0 - cf) * (1.0 - kf);
    double gf = (1.0 - mf) * (1.0 - kf);
    double bf = (1.0 - yf) * (1.0 - kf);
    
    /* Back to 0-255 */
    *r = (uint8_t)(rf * 255.0 + 0.5);
    *g = (uint8_t)(gf * 255.0 + 0.5);
    *b = (uint8_t)(bf * 255.0 + 0.5);
}

void pdfmake_cmyk_to_rgb_f(
    double c, double m, double y, double k,
    double *r, double *g, double *b)
{
    /* Clamp inputs */
    if (c < 0.0) c = 0.0; if (c > 1.0) c = 1.0;
    if (m < 0.0) m = 0.0; if (m > 1.0) m = 1.0;
    if (y < 0.0) y = 0.0; if (y > 1.0) y = 1.0;
    if (k < 0.0) k = 0.0; if (k > 1.0) k = 1.0;
    
    *r = (1.0 - c) * (1.0 - k);
    *g = (1.0 - m) * (1.0 - k);
    *b = (1.0 - y) * (1.0 - k);
}

/*============================================================================
 * Lab to RGB conversion
 *
 * Lab -> XYZ -> sRGB
 * Using D65 illuminant.
 *==========================================================================*/

/* D65 reference white */
#define D65_X 0.95047
#define D65_Y 1.00000
#define D65_Z 1.08883

/* Lab parameters */
#define LAB_DELTA (6.0 / 29.0)
#define LAB_DELTA2 (LAB_DELTA * LAB_DELTA)
#define LAB_DELTA3 (LAB_DELTA * LAB_DELTA * LAB_DELTA)

static double lab_f_inv(double t) {
    if (t > LAB_DELTA) {
        return t * t * t;
    }
    return 3.0 * LAB_DELTA2 * (t - 4.0 / 29.0);
}

void pdfmake_lab_to_xyz(
    double L, double a, double b,
    double *x, double *y, double *z)
{
    /* L is 0-100, a and b are typically -128 to 127 */
    double fy = (L + 16.0) / 116.0;
    double fx = a / 500.0 + fy;
    double fz = fy - b / 200.0;
    
    *x = D65_X * lab_f_inv(fx);
    *y = D65_Y * lab_f_inv(fy);
    *z = D65_Z * lab_f_inv(fz);
}

static double srgb_gamma(double linear) {
    if (linear <= 0.0031308) {
        return 12.92 * linear;
    }
    return 1.055 * pow(linear, 1.0 / 2.4) - 0.055;
}

void pdfmake_xyz_to_srgb(
    double x, double y, double z,
    double *r, double *g, double *b)
{
    /* sRGB transformation matrix (D65) */
    double rlin =  3.2404542 * x - 1.5371385 * y - 0.4985314 * z;
    double glin = -0.9692660 * x + 1.8760108 * y + 0.0415560 * z;
    double blin =  0.0556434 * x - 0.2040259 * y + 1.0572252 * z;
    
    /* Apply gamma */
    *r = srgb_gamma(rlin);
    *g = srgb_gamma(glin);
    *b = srgb_gamma(blin);
    
    /* Clamp */
    if (*r < 0.0) *r = 0.0; if (*r > 1.0) *r = 1.0;
    if (*g < 0.0) *g = 0.0; if (*g > 1.0) *g = 1.0;
    if (*b < 0.0) *b = 0.0; if (*b > 1.0) *b = 1.0;
}

void pdfmake_lab_to_rgb8(
    double L, double a, double b,
    uint8_t *r, uint8_t *g, uint8_t *bl)
{
    double x, y, z;
    double rf, gf, bf;
    
    pdfmake_lab_to_xyz(L, a, b, &x, &y, &z);
    pdfmake_xyz_to_srgb(x, y, z, &rf, &gf, &bf);
    
    *r = (uint8_t)(rf * 255.0 + 0.5);
    *g = (uint8_t)(gf * 255.0 + 0.5);
    *bl = (uint8_t)(bf * 255.0 + 0.5);
}

/*============================================================================
 * Decoded image operations
 *==========================================================================*/

pdfmake_decoded_image_t *pdfmake_decoded_image_create(pdfmake_arena_t *arena)
{
    pdfmake_decoded_image_t *img;
    
    if (arena) {
        img = pdfmake_arena_alloc(arena, sizeof(pdfmake_decoded_image_t));
    } else {
        img = malloc(sizeof(pdfmake_decoded_image_t));
    }
    
    if (!img) return NULL;
    memset(img, 0, sizeof(*img));
    
    img->bits_per_component = 8;
    img->arena = arena;
    img->owns_data = !arena;
    
    return img;
}

pdfmake_decoded_image_t *pdfmake_decoded_image_create_sized(
    int width, int height,
    pdfmake_render_cs_t colorspace,
    pdfmake_arena_t *arena)
{
    pdfmake_decoded_image_t *img = pdfmake_decoded_image_create(arena);
    if (!img) return NULL;
    
    img->width = width;
    img->height = height;
    img->colorspace = colorspace;
    
    /* Determine components */
    switch (colorspace) {
        case PDFMAKE_RCS_GRAY:    img->components = 1; break;
        case PDFMAKE_RCS_RGB:     img->components = 3; break;
        case PDFMAKE_RCS_CMYK:    img->components = 4; break;
        case PDFMAKE_RCS_INDEXED: img->components = 1; break;
        case PDFMAKE_RCS_LAB:     img->components = 3; break;
        default:                  img->components = 3; break;
    }
    
    img->row_stride = (size_t)width * img->components;
    img->pixels_len = img->row_stride * height;
    
    if (arena) {
        img->pixels = pdfmake_arena_alloc(arena, img->pixels_len);
    } else {
        img->pixels = malloc(img->pixels_len);
    }
    
    if (!img->pixels) {
        if (!arena) free(img);
        return NULL;
    }
    
    memset(img->pixels, 0, img->pixels_len);
    return img;
}

void pdfmake_decoded_image_free(pdfmake_decoded_image_t *img)
{
    if (!img) return;
    
    /* Arena-managed images don't need individual frees */
    if (img->arena) return;
    
    if (img->owns_data) {
        free(img->pixels);
        free(img->alpha);
        free(img->rgba);
        free(img->palette);
        free(img->decode);
        free(img->matte);
    }
    
    free(img);
}

pdfmake_decoded_image_t *pdfmake_decoded_image_clone(
    pdfmake_decoded_image_t *src,
    pdfmake_arena_t *arena)
{
    pdfmake_decoded_image_t *dst;
    if (!src) return NULL;
    
    dst = pdfmake_decoded_image_create(arena);
    if (!dst) return NULL;
    
    /* Copy metadata */
    dst->width = src->width;
    dst->height = src->height;
    dst->bits_per_component = src->bits_per_component;
    dst->components = src->components;
    dst->colorspace = src->colorspace;
    dst->row_stride = src->row_stride;
    dst->interpolate = src->interpolate;
    dst->has_alpha = src->has_alpha;
    dst->premultiplied = src->premultiplied;
    
    /* Allocate and copy pixel data */
    if (src->pixels && src->pixels_len > 0) {
        dst->pixels_len = src->pixels_len;
        if (arena) {
            dst->pixels = pdfmake_arena_alloc(arena, dst->pixels_len);
        } else {
            dst->pixels = malloc(dst->pixels_len);
        }
        if (dst->pixels) {
            memcpy(dst->pixels, src->pixels, dst->pixels_len);
        }
    }
    
    /* Copy alpha */
    if (src->alpha && src->alpha_len > 0) {
        dst->alpha_len = src->alpha_len;
        if (arena) {
            dst->alpha = pdfmake_arena_alloc(arena, dst->alpha_len);
        } else {
            dst->alpha = malloc(dst->alpha_len);
        }
        if (dst->alpha) {
            memcpy(dst->alpha, src->alpha, dst->alpha_len);
        }
    }
    
    /* Copy RGBA */
    if (src->rgba && src->rgba_len > 0) {
        dst->rgba_len = src->rgba_len;
        if (arena) {
            dst->rgba = pdfmake_arena_alloc(arena, dst->rgba_len * sizeof(uint32_t));
        } else {
            dst->rgba = malloc(dst->rgba_len * sizeof(uint32_t));
        }
        if (dst->rgba) {
            memcpy(dst->rgba, src->rgba, dst->rgba_len * sizeof(uint32_t));
        }
    }
    
    /* Copy palette */
    if (src->palette && src->palette_entries > 0) {
        size_t pal_bytes;
        dst->palette_entries = src->palette_entries;
        pal_bytes = src->palette_entries * 3;
        if (arena) {
            dst->palette = pdfmake_arena_alloc(arena, pal_bytes);
        } else {
            dst->palette = malloc(pal_bytes);
        }
        if (dst->palette) {
            memcpy(dst->palette, src->palette, pal_bytes);
        }
    }
    
    /* Copy decode array */
    if (src->decode && src->decode_len > 0) {
        dst->decode_len = src->decode_len;
        if (arena) {
            dst->decode = pdfmake_arena_alloc(arena, dst->decode_len * sizeof(double));
        } else {
            dst->decode = malloc(dst->decode_len * sizeof(double));
        }
        if (dst->decode) {
            memcpy(dst->decode, src->decode, dst->decode_len * sizeof(double));
        }
    }
    
    /* Copy matte */
    if (src->matte) {
        size_t matte_bytes = src->components * sizeof(double);
        if (arena) {
            dst->matte = pdfmake_arena_alloc(arena, matte_bytes);
        } else {
            dst->matte = malloc(matte_bytes);
        }
        if (dst->matte) {
            memcpy(dst->matte, src->matte, matte_bytes);
        }
    }
    
    return dst;
}

/*============================================================================
 * Pixel access
 *==========================================================================*/

void pdfmake_decoded_image_get_pixel(
    pdfmake_decoded_image_t *img,
    int x, int y,
    uint8_t *out)
{
    uint8_t *row;
    uint8_t *px;
    int i;
    if (!img || !img->pixels || !out) return;
    if (x < 0 || x >= img->width || y < 0 || y >= img->height) return;
    
    row = img->pixels + y * img->row_stride;
    px = row + x * img->components;
    
    for (i = 0; i < img->components; i++) {
        out[i] = px[i];
    }
}

uint8_t pdfmake_decoded_image_get_alpha(
    pdfmake_decoded_image_t *img,
    int x, int y)
{
    if (!img) return 255;
    if (!img->has_alpha || !img->alpha) return 255;
    if (x < 0 || x >= img->width || y < 0 || y >= img->height) return 0;
    
    return img->alpha[y * img->width + x];
}

uint32_t pdfmake_decoded_image_get_rgba(
    pdfmake_decoded_image_t *img,
    int x, int y)
{
    uint8_t comp[4];
    uint8_t alpha;
    uint8_t r, g, b;
    if (!img) return 0;
    if (x < 0 || x >= img->width || y < 0 || y >= img->height) return 0;
    
    /* Fast path: pre-converted RGBA */
    if (img->rgba) {
        return img->rgba[y * img->width + x];
    }
    
    pdfmake_decoded_image_get_pixel(img, x, y, comp);
    alpha = pdfmake_decoded_image_get_alpha(img, x, y);
    
    switch (img->colorspace) {
        case PDFMAKE_RCS_GRAY:
            r = g = b = comp[0];
            break;
            
        case PDFMAKE_RCS_RGB:
            r = comp[0];
            g = comp[1];
            b = comp[2];
            break;
            
        case PDFMAKE_RCS_CMYK:
            pdfmake_cmyk_to_rgb8(comp[0], comp[1], comp[2], comp[3], &r, &g, &b);
            break;
            
        case PDFMAKE_RCS_LAB: {
            double L = comp[0] * 100.0 / 255.0;
            double a = comp[1] - 128.0;
            double bb = comp[2] - 128.0;
            pdfmake_lab_to_rgb8(L, a, bb, &r, &g, &b);
            break;
        }
        
        case PDFMAKE_RCS_INDEXED:
            if (img->palette && comp[0] < img->palette_entries) {
                uint8_t *pal = img->palette + comp[0] * 3;
                r = pal[0];
                g = pal[1];
                b = pal[2];
            } else {
                r = g = b = comp[0];
            }
            break;
            
        default:
            r = g = b = 128;
            break;
    }
    
    return PDFMAKE_RGBA(r, g, b, alpha);
}

/*============================================================================
 * Color space conversion
 *==========================================================================*/

pdfmake_imgr_err_t pdfmake_decoded_image_expand_indexed(
    pdfmake_decoded_image_t *img,
    pdfmake_arena_t *arena)
{
    size_t new_stride;
    size_t new_len;
    uint8_t *new_pixels;
    int y;
    if (!img) return PDFMAKE_IMGR_ERR_NULL;
    if (img->colorspace != PDFMAKE_RCS_INDEXED) return PDFMAKE_IMGR_OK;
    if (!img->palette) return PDFMAKE_IMGR_ERR_INVALID;
    
    new_stride = (size_t)img->width * 3;
    new_len = new_stride * img->height;
    
    if (arena) {
        new_pixels = pdfmake_arena_alloc(arena, new_len);
    } else {
        new_pixels = malloc(new_len);
    }
    
    if (!new_pixels) return PDFMAKE_IMGR_ERR_MEMORY;
    
    /* Expand each index to RGB */
    for (y = 0; y < img->height; y++) {
        uint8_t *src_row = img->pixels + y * img->row_stride;
        uint8_t *dst_row = new_pixels + y * new_stride;
        int x;
        
        for (x = 0; x < img->width; x++) {
            uint8_t idx = src_row[x];
            
            if (idx < img->palette_entries) {
                uint8_t *pal = img->palette + idx * 3;
                dst_row[x * 3 + 0] = pal[0];
                dst_row[x * 3 + 1] = pal[1];
                dst_row[x * 3 + 2] = pal[2];
            } else {
                /* Invalid index - use black */
                dst_row[x * 3 + 0] = 0;
                dst_row[x * 3 + 1] = 0;
                dst_row[x * 3 + 2] = 0;
            }
        }
    }
    
    /* Update image */
    if (!arena && img->owns_data) {
        free(img->pixels);
    }
    
    img->pixels = new_pixels;
    img->pixels_len = new_len;
    img->row_stride = new_stride;
    img->components = 3;
    img->colorspace = PDFMAKE_RCS_RGB;
    
    return PDFMAKE_IMGR_OK;
}

pdfmake_imgr_err_t pdfmake_decoded_image_to_rgba(
    pdfmake_decoded_image_t *img,
    pdfmake_arena_t *arena)
{
    if (!img) return PDFMAKE_IMGR_ERR_NULL;
    if (!img->pixels) return PDFMAKE_IMGR_ERR_INVALID;
    
    /* Already converted */
    if (img->rgba) return PDFMAKE_IMGR_OK;
    
    /* Expand indexed first */
    if (img->colorspace == PDFMAKE_RCS_INDEXED) {
        pdfmake_imgr_err_t err = pdfmake_decoded_image_expand_indexed(img, arena);
        if (err != PDFMAKE_IMGR_OK) return err;
    }
    
    img->rgba_len = (size_t)img->width * img->height;
    
    if (arena) {
        img->rgba = pdfmake_arena_alloc(arena, img->rgba_len * sizeof(uint32_t));
    } else {
        img->rgba = malloc(img->rgba_len * sizeof(uint32_t));
    }
    
    if (!img->rgba) return PDFMAKE_IMGR_ERR_MEMORY;
    
    /* Convert each pixel */
    {
    int y;
    for (y = 0; y < img->height; y++) {
        uint8_t *row = img->pixels + y * img->row_stride;
        uint32_t *rgba_row = img->rgba + y * img->width;
        int x;
        
        for (x = 0; x < img->width; x++) {
            uint8_t *px = row + x * img->components;
            uint8_t alpha = pdfmake_decoded_image_get_alpha(img, x, y);
            uint8_t r, g, b;
            
            switch (img->colorspace) {
                case PDFMAKE_RCS_GRAY:
                    r = g = b = px[0];
                    break;
                    
                case PDFMAKE_RCS_RGB:
                    r = px[0];
                    g = px[1];
                    b = px[2];
                    break;
                    
                case PDFMAKE_RCS_CMYK:
                    pdfmake_cmyk_to_rgb8(px[0], px[1], px[2], px[3], &r, &g, &b);
                    break;
                    
                case PDFMAKE_RCS_LAB: {
                    double L = px[0] * 100.0 / 255.0;
                    double a = px[1] - 128.0;
                    double bb = px[2] - 128.0;
                    pdfmake_lab_to_rgb8(L, a, bb, &r, &g, &b);
                    break;
                }
                
                default:
                    r = g = b = 128;
                    break;
            }
            
            rgba_row[x] = PDFMAKE_RGBA(r, g, b, alpha);
        }
    }
    }
    
    return PDFMAKE_IMGR_OK;
}

/*============================================================================
 * Decode array application
 *
 * The Decode array maps raw sample values to color component values.
 * Formula: output = Dmin + (sample / max_sample) * (Dmax - Dmin)
 *==========================================================================*/

void pdfmake_decoded_image_apply_decode(pdfmake_decoded_image_t *img)
{
    if (!img || !img->pixels || !img->decode) return;
    if (img->decode_len < 2 * (size_t)img->components) return;
    
    {
    double max_sample = (1 << img->bits_per_component) - 1;
    int y;
    if (max_sample <= 0) max_sample = 255;
    
    for (y = 0; y < img->height; y++) {
        uint8_t *row = img->pixels + y * img->row_stride;
        int x;
        
        for (x = 0; x < img->width; x++) {
            uint8_t *px = row + x * img->components;
            int c;
            
            for (c = 0; c < img->components; c++) {
                double dmin = img->decode[c * 2];
                double dmax = img->decode[c * 2 + 1];
                
                double sample = px[c] / max_sample;
                double value = dmin + sample * (dmax - dmin);
                
                /* Convert back to 0-255 */
                int ival = (int)(value * 255.0 + 0.5);
                if (ival < 0) ival = 0;
                if (ival > 255) ival = 255;
                px[c] = (uint8_t)ival;
            }
        }
    }
    }
}

/*============================================================================
 * Grayscale utilities
 *==========================================================================*/

/*
 * Convert RGB image to grayscale.
 */
pdfmake_imgr_err_t pdfmake_decoded_image_to_gray(
    pdfmake_decoded_image_t *img,
    pdfmake_arena_t *arena)
{
    size_t new_stride;
    size_t new_len;
    uint8_t *new_pixels;
    int y;
    if (!img || !img->pixels) return PDFMAKE_IMGR_ERR_NULL;
    if (img->colorspace == PDFMAKE_RCS_GRAY) return PDFMAKE_IMGR_OK;
    if (img->colorspace != PDFMAKE_RCS_RGB) return PDFMAKE_IMGR_ERR_COLORSPACE;
    
    new_stride = (size_t)img->width;
    new_len = new_stride * img->height;
    
    if (arena) {
        new_pixels = pdfmake_arena_alloc(arena, new_len);
    } else {
        new_pixels = malloc(new_len);
    }
    
    if (!new_pixels) return PDFMAKE_IMGR_ERR_MEMORY;
    
    /* Convert using luminance formula */
    for (y = 0; y < img->height; y++) {
        uint8_t *src_row = img->pixels + y * img->row_stride;
        uint8_t *dst_row = new_pixels + y * new_stride;
        int x;
        
        for (x = 0; x < img->width; x++) {
            uint8_t r = src_row[x * 3 + 0];
            uint8_t g = src_row[x * 3 + 1];
            uint8_t b = src_row[x * 3 + 2];
            
            /* ITU-R BT.601 luma */
            int gray = (299 * r + 587 * g + 114 * b) / 1000;
            dst_row[x] = (uint8_t)gray;
        }
    }
    
    if (!arena && img->owns_data) {
        free(img->pixels);
    }
    
    img->pixels = new_pixels;
    img->pixels_len = new_len;
    img->row_stride = new_stride;
    img->components = 1;
    img->colorspace = PDFMAKE_RCS_GRAY;
    
    return PDFMAKE_IMGR_OK;
}

/*
 * Invert image (for masks, etc).
 */
void pdfmake_decoded_image_invert(pdfmake_decoded_image_t *img)
{
    size_t i;
    if (!img || !img->pixels) return;
    
    for (i = 0; i < img->pixels_len; i++) {
        img->pixels[i] = 255 - img->pixels[i];
    }
}
