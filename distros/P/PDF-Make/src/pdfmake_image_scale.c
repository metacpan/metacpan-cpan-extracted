/*
 * pdfmake_image_scale.c - Image scaling algorithms
 *
 * Implements interpolation methods for scaling images:
 * - Nearest neighbor: Fast, no interpolation
 * - Bilinear: Smooth, good for scaling up
 * - Bicubic: High quality, good for scaling down
 *
 * Reference: PDF 32000-1:2008 §8.9.5.3 Image Interpolation
 */

#include "pdfmake_image_render.h"
#include "pdfmake_arena.h"
#include <stdlib.h>
#include <string.h>
#include <math.h>

/*============================================================================
 * Nearest neighbor scaling
 *==========================================================================*/

static void scale_nearest_gray(
    const uint8_t *src, int src_w, int src_h,
    uint8_t *dst, int dst_w, int dst_h)
{
    double x_ratio = (double)src_w / dst_w;
    double y_ratio = (double)src_h / dst_h;
    int x, y, src_x, src_y;
    const uint8_t *src_row;
    uint8_t *dst_row;
    
    for (y = 0; y < dst_h; y++) {
        src_y = (int)(y * y_ratio);
        if (src_y >= src_h) src_y = src_h - 1;
        
        src_row = src + src_y * src_w;
        dst_row = dst + y * dst_w;
        
        for (x = 0; x < dst_w; x++) {
            src_x = (int)(x * x_ratio);
            if (src_x >= src_w) src_x = src_w - 1;
            
            dst_row[x] = src_row[src_x];
        }
    }
}

static void scale_nearest_rgb(
    const uint8_t *src, int src_w, int src_h,
    uint8_t *dst, int dst_w, int dst_h)
{
    double x_ratio = (double)src_w / dst_w;
    double y_ratio = (double)src_h / dst_h;
    int src_stride = src_w * 3;
    int dst_stride = dst_w * 3;
    int x, y, src_x, src_y;
    const uint8_t *src_row;
    uint8_t *dst_row;
    
    for (y = 0; y < dst_h; y++) {
        src_y = (int)(y * y_ratio);
        if (src_y >= src_h) src_y = src_h - 1;
        
        src_row = src + src_y * src_stride;
        dst_row = dst + y * dst_stride;
        
        for (x = 0; x < dst_w; x++) {
            src_x = (int)(x * x_ratio);
            if (src_x >= src_w) src_x = src_w - 1;
            
            dst_row[x * 3 + 0] = src_row[src_x * 3 + 0];
            dst_row[x * 3 + 1] = src_row[src_x * 3 + 1];
            dst_row[x * 3 + 2] = src_row[src_x * 3 + 2];
        }
    }
}

static void scale_nearest_rgba32(
    const uint32_t *src, int src_w, int src_h,
    uint32_t *dst, int dst_w, int dst_h)
{
    double x_ratio = (double)src_w / dst_w;
    double y_ratio = (double)src_h / dst_h;
    int x, y, src_x, src_y;
    const uint32_t *src_row;
    uint32_t *dst_row;
    
    for (y = 0; y < dst_h; y++) {
        src_y = (int)(y * y_ratio);
        if (src_y >= src_h) src_y = src_h - 1;
        
        src_row = src + src_y * src_w;
        dst_row = dst + y * dst_w;
        
        for (x = 0; x < dst_w; x++) {
            src_x = (int)(x * x_ratio);
            if (src_x >= src_w) src_x = src_w - 1;
            
            dst_row[x] = src_row[src_x];
        }
    }
}

/*============================================================================
 * Bilinear interpolation
 *==========================================================================*/

static PDFMAKE_INLINE uint8_t bilinear_sample_gray(
    const uint8_t *src, int src_w, int src_h,
    double fx, double fy)
{
    int x0 = (int)fx;
    int y0 = (int)fy;
    int x1 = x0 + 1;
    int y1 = y0 + 1;
    double tx, ty;
    double p00, p10, p01, p11;
    double top, bot, val;
    
    if (x0 < 0) x0 = 0;
    if (y0 < 0) y0 = 0;
    if (x1 >= src_w) x1 = src_w - 1;
    if (y1 >= src_h) y1 = src_h - 1;
    
    tx = fx - x0;
    ty = fy - y0;
    
    p00 = src[y0 * src_w + x0];
    p10 = src[y0 * src_w + x1];
    p01 = src[y1 * src_w + x0];
    p11 = src[y1 * src_w + x1];
    
    top = p00 + tx * (p10 - p00);
    bot = p01 + tx * (p11 - p01);
    val = top + ty * (bot - top);
    
    return (uint8_t)(val + 0.5);
}

static void scale_bilinear_gray(
    const uint8_t *src, int src_w, int src_h,
    uint8_t *dst, int dst_w, int dst_h)
{
    double x_ratio = (double)(src_w - 1) / (dst_w - 1);
    double y_ratio = (double)(src_h - 1) / (dst_h - 1);
    int x, y;
    double fx, fy;
    uint8_t *dst_row;
    
    if (dst_w == 1) x_ratio = 0;
    if (dst_h == 1) y_ratio = 0;
    
    for (y = 0; y < dst_h; y++) {
        fy = y * y_ratio;
        dst_row = dst + y * dst_w;
        
        for (x = 0; x < dst_w; x++) {
            fx = x * x_ratio;
            dst_row[x] = bilinear_sample_gray(src, src_w, src_h, fx, fy);
        }
    }
}

static void scale_bilinear_rgb(
    const uint8_t *src, int src_w, int src_h,
    uint8_t *dst, int dst_w, int dst_h)
{
    double x_ratio = (double)(src_w - 1) / (dst_w - 1);
    double y_ratio = (double)(src_h - 1) / (dst_h - 1);
    int src_stride = src_w * 3;
    int dst_stride = dst_w * 3;
    int x, y, c;
    int x0, x1, y0, y1;
    double fx, fy, tx, ty;
    double p00, p10, p01, p11;
    double top, bot, val;
    uint8_t *dst_row;
    
    if (dst_w == 1) x_ratio = 0;
    if (dst_h == 1) y_ratio = 0;
    
    for (y = 0; y < dst_h; y++) {
        fy = y * y_ratio;
        y0 = (int)fy;
        y1 = y0 + 1;
        if (y0 < 0) y0 = 0;
        if (y1 >= src_h) y1 = src_h - 1;
        ty = fy - (int)fy;
        
        dst_row = dst + y * dst_stride;
        
        for (x = 0; x < dst_w; x++) {
            fx = x * x_ratio;
            x0 = (int)fx;
            x1 = x0 + 1;
            if (x0 < 0) x0 = 0;
            if (x1 >= src_w) x1 = src_w - 1;
            tx = fx - (int)fx;
            
            for (c = 0; c < 3; c++) {
                p00 = src[y0 * src_stride + x0 * 3 + c];
                p10 = src[y0 * src_stride + x1 * 3 + c];
                p01 = src[y1 * src_stride + x0 * 3 + c];
                p11 = src[y1 * src_stride + x1 * 3 + c];
                
                top = p00 + tx * (p10 - p00);
                bot = p01 + tx * (p11 - p01);
                val = top + ty * (bot - top);
                
                dst_row[x * 3 + c] = (uint8_t)(val + 0.5);
            }
        }
    }
}

static void scale_bilinear_rgba32(
    const uint32_t *src, int src_w, int src_h,
    uint32_t *dst, int dst_w, int dst_h)
{
    double x_ratio = (double)(src_w - 1) / (dst_w - 1);
    double y_ratio = (double)(src_h - 1) / (dst_h - 1);
    int x, y;
    int x0, x1, y0, y1;
    double fx, fy, tx, ty;
    uint32_t p00, p10, p01, p11;
    uint8_t a, r, g, b;
    double a00, a10, a01, a11, atop, abot;
    double r00, r10, r01, r11, rtop, rbot;
    double g00, g10, g01, g11, gtop, gbot;
    double b00, b10, b01, b11, btop, bbot;
    uint32_t *dst_row;
    
    if (dst_w == 1) x_ratio = 0;
    if (dst_h == 1) y_ratio = 0;
    
    for (y = 0; y < dst_h; y++) {
        fy = y * y_ratio;
        y0 = (int)fy;
        y1 = y0 + 1;
        if (y0 < 0) y0 = 0;
        if (y1 >= src_h) y1 = src_h - 1;
        ty = fy - (int)fy;
        
        dst_row = dst + y * dst_w;
        
        for (x = 0; x < dst_w; x++) {
            fx = x * x_ratio;
            x0 = (int)fx;
            x1 = x0 + 1;
            if (x0 < 0) x0 = 0;
            if (x1 >= src_w) x1 = src_w - 1;
            tx = fx - (int)fx;
            
            p00 = src[y0 * src_w + x0];
            p10 = src[y0 * src_w + x1];
            p01 = src[y1 * src_w + x0];
            p11 = src[y1 * src_w + x1];
            
            /* Interpolate each channel */
            
            /* Alpha */
            a00 = PDFMAKE_RGBA_A(p00);
            a10 = PDFMAKE_RGBA_A(p10);
            a01 = PDFMAKE_RGBA_A(p01);
            a11 = PDFMAKE_RGBA_A(p11);
            atop = a00 + tx * (a10 - a00);
            abot = a01 + tx * (a11 - a01);
            a = (uint8_t)(atop + ty * (abot - atop) + 0.5);
            
            /* Red */
            r00 = PDFMAKE_RGBA_R(p00);
            r10 = PDFMAKE_RGBA_R(p10);
            r01 = PDFMAKE_RGBA_R(p01);
            r11 = PDFMAKE_RGBA_R(p11);
            rtop = r00 + tx * (r10 - r00);
            rbot = r01 + tx * (r11 - r01);
            r = (uint8_t)(rtop + ty * (rbot - rtop) + 0.5);
            
            /* Green */
            g00 = PDFMAKE_RGBA_G(p00);
            g10 = PDFMAKE_RGBA_G(p10);
            g01 = PDFMAKE_RGBA_G(p01);
            g11 = PDFMAKE_RGBA_G(p11);
            gtop = g00 + tx * (g10 - g00);
            gbot = g01 + tx * (g11 - g01);
            g = (uint8_t)(gtop + ty * (gbot - gtop) + 0.5);
            
            /* Blue */
            b00 = PDFMAKE_RGBA_B(p00);
            b10 = PDFMAKE_RGBA_B(p10);
            b01 = PDFMAKE_RGBA_B(p01);
            b11 = PDFMAKE_RGBA_B(p11);
            btop = b00 + tx * (b10 - b00);
            bbot = b01 + tx * (b11 - b01);
            b = (uint8_t)(btop + ty * (bbot - btop) + 0.5);
            
            dst_row[x] = PDFMAKE_RGBA(r, g, b, a);
        }
    }
}

/*============================================================================
 * Bicubic interpolation (Mitchell-Netravali)
 *==========================================================================*/

/* Mitchell-Netravali coefficients (B=1/3, C=1/3) */
#define MN_B (1.0/3.0)
#define MN_C (1.0/3.0)

static double mitchell_kernel(double x) {
    x = fabs(x);
    
    if (x < 1.0) {
        return ((12.0 - 9.0*MN_B - 6.0*MN_C) * x*x*x +
                (-18.0 + 12.0*MN_B + 6.0*MN_C) * x*x +
                (6.0 - 2.0*MN_B)) / 6.0;
    } else if (x < 2.0) {
        return ((-MN_B - 6.0*MN_C) * x*x*x +
                (6.0*MN_B + 30.0*MN_C) * x*x +
                (-12.0*MN_B - 48.0*MN_C) * x +
                (8.0*MN_B + 24.0*MN_C)) / 6.0;
    }
    return 0.0;
}

static void scale_bicubic_gray(
    const uint8_t *src, int src_w, int src_h,
    uint8_t *dst, int dst_w, int dst_h)
{
    double x_ratio = (double)src_w / dst_w;
    double y_ratio = (double)src_h / dst_h;
    int dx, dy, i, j;
    int sx, sy, ix, iy;
    int val;
    double fx, fy, tx, ty;
    double sum, weight_sum, wx, wy, w;
    uint8_t *dst_row;
    
    for (dy = 0; dy < dst_h; dy++) {
        fy = (dy + 0.5) * y_ratio - 0.5;
        iy = (int)floor(fy);
        ty = fy - iy;
        
        dst_row = dst + dy * dst_w;
        
        for (dx = 0; dx < dst_w; dx++) {
            fx = (dx + 0.5) * x_ratio - 0.5;
            ix = (int)floor(fx);
            tx = fx - ix;
            
            sum = 0;
            weight_sum = 0;
            
            /* Sample 4x4 neighborhood */
            for (j = -1; j <= 2; j++) {
                sy = iy + j;
                if (sy < 0) sy = 0;
                if (sy >= src_h) sy = src_h - 1;
                
                wy = mitchell_kernel(ty - j);
                
                for (i = -1; i <= 2; i++) {
                    sx = ix + i;
                    if (sx < 0) sx = 0;
                    if (sx >= src_w) sx = src_w - 1;
                    
                    wx = mitchell_kernel(tx - i);
                    w = wx * wy;
                    
                    sum += src[sy * src_w + sx] * w;
                    weight_sum += w;
                }
            }
            
            if (weight_sum > 0) {
                val = (int)(sum / weight_sum + 0.5);
                if (val < 0) val = 0;
                if (val > 255) val = 255;
                dst_row[dx] = (uint8_t)val;
            } else {
                dst_row[dx] = 0;
            }
        }
    }
}

static void scale_bicubic_rgb(
    const uint8_t *src, int src_w, int src_h,
    uint8_t *dst, int dst_w, int dst_h)
{
    double x_ratio = (double)src_w / dst_w;
    double y_ratio = (double)src_h / dst_h;
    int src_stride = src_w * 3;
    int dst_stride = dst_w * 3;
    int dx, dy, i, j, c;
    int sx, sy, ix, iy;
    int val;
    double fx, fy, tx, ty;
    double sum[3];
    double weight_sum, wx, wy, w;
    const uint8_t *px;
    uint8_t *dst_row;
    
    for (dy = 0; dy < dst_h; dy++) {
        fy = (dy + 0.5) * y_ratio - 0.5;
        iy = (int)floor(fy);
        ty = fy - iy;
        
        dst_row = dst + dy * dst_stride;
        
        for (dx = 0; dx < dst_w; dx++) {
            fx = (dx + 0.5) * x_ratio - 0.5;
            ix = (int)floor(fx);
            tx = fx - ix;
            
            sum[0] = 0;
            sum[1] = 0;
            sum[2] = 0;
            weight_sum = 0;
            
            for (j = -1; j <= 2; j++) {
                sy = iy + j;
                if (sy < 0) sy = 0;
                if (sy >= src_h) sy = src_h - 1;
                
                wy = mitchell_kernel(ty - j);
                
                for (i = -1; i <= 2; i++) {
                    sx = ix + i;
                    if (sx < 0) sx = 0;
                    if (sx >= src_w) sx = src_w - 1;
                    
                    wx = mitchell_kernel(tx - i);
                    w = wx * wy;
                    
                    px = src + sy * src_stride + sx * 3;
                    sum[0] += px[0] * w;
                    sum[1] += px[1] * w;
                    sum[2] += px[2] * w;
                    weight_sum += w;
                }
            }
            
            for (c = 0; c < 3; c++) {
                val = 0;
                if (weight_sum > 0) {
                    val = (int)(sum[c] / weight_sum + 0.5);
                }
                if (val < 0) val = 0;
                if (val > 255) val = 255;
                dst_row[dx * 3 + c] = (uint8_t)val;
            }
        }
    }
}

static void scale_bicubic_rgba32(
    const uint32_t *src, int src_w, int src_h,
    uint32_t *dst, int dst_w, int dst_h)
{
    double x_ratio = (double)src_w / dst_w;
    double y_ratio = (double)src_h / dst_h;
    int dx, dy, i, j;
    int sx, sy, ix, iy;
    int va, vr, vg, vb;
    double fx, fy, tx, ty;
    double sum_a, sum_r, sum_g, sum_b;
    double weight_sum, wx, wy, w;
    uint32_t px;
    uint8_t a, r, g, b;
    uint32_t *dst_row;
    
    for (dy = 0; dy < dst_h; dy++) {
        fy = (dy + 0.5) * y_ratio - 0.5;
        iy = (int)floor(fy);
        ty = fy - iy;
        
        dst_row = dst + dy * dst_w;
        
        for (dx = 0; dx < dst_w; dx++) {
            fx = (dx + 0.5) * x_ratio - 0.5;
            ix = (int)floor(fx);
            tx = fx - ix;
            
            sum_a = 0;
            sum_r = 0;
            sum_g = 0;
            sum_b = 0;
            weight_sum = 0;
            
            for (j = -1; j <= 2; j++) {
                sy = iy + j;
                if (sy < 0) sy = 0;
                if (sy >= src_h) sy = src_h - 1;
                
                wy = mitchell_kernel(ty - j);
                
                for (i = -1; i <= 2; i++) {
                    sx = ix + i;
                    if (sx < 0) sx = 0;
                    if (sx >= src_w) sx = src_w - 1;
                    
                    wx = mitchell_kernel(tx - i);
                    w = wx * wy;
                    
                    px = src[sy * src_w + sx];
                    sum_a += PDFMAKE_RGBA_A(px) * w;
                    sum_r += PDFMAKE_RGBA_R(px) * w;
                    sum_g += PDFMAKE_RGBA_G(px) * w;
                    sum_b += PDFMAKE_RGBA_B(px) * w;
                    weight_sum += w;
                }
            }
            
            a = 0;
            r = 0;
            g = 0;
            b = 0;
            if (weight_sum > 0) {
                va = (int)(sum_a / weight_sum + 0.5);
                vr = (int)(sum_r / weight_sum + 0.5);
                vg = (int)(sum_g / weight_sum + 0.5);
                vb = (int)(sum_b / weight_sum + 0.5);
                
                a = (uint8_t)PDFMAKE_CLAMP8(va);
                r = (uint8_t)PDFMAKE_CLAMP8(vr);
                g = (uint8_t)PDFMAKE_CLAMP8(vg);
                b = (uint8_t)PDFMAKE_CLAMP8(vb);
            }
            
            dst_row[dx] = PDFMAKE_RGBA(r, g, b, a);
        }
    }
}

/*============================================================================
 * Public API
 *==========================================================================*/

pdfmake_imgr_err_t pdfmake_decoded_image_scale(
    pdfmake_decoded_image_t *src,
    int dst_width, int dst_height,
    pdfmake_interp_mode_t mode,
    pdfmake_decoded_image_t **out,
    pdfmake_arena_t *arena)
{
    pdfmake_decoded_image_t *dst;
    
    if (!src || !out) return PDFMAKE_IMGR_ERR_NULL;
    if (!src->pixels) return PDFMAKE_IMGR_ERR_INVALID;
    if (dst_width <= 0 || dst_height <= 0) return PDFMAKE_IMGR_ERR_INVALID;
    
    /* Create destination image */
    dst = pdfmake_decoded_image_create_sized(
        dst_width, dst_height, src->colorspace, arena);
    
    if (!dst) return PDFMAKE_IMGR_ERR_MEMORY;
    
    /* Copy metadata */
    dst->bits_per_component = src->bits_per_component;
    dst->interpolate = src->interpolate;
    dst->has_alpha = src->has_alpha;
    dst->premultiplied = src->premultiplied;
    
    /* Scale based on colorspace and mode */
    if (src->components == 1) {
        /* Grayscale / indexed */
        switch (mode) {
            case PDFMAKE_INTERP_NEAREST:
                scale_nearest_gray(src->pixels, src->width, src->height,
                                   dst->pixels, dst_width, dst_height);
                break;
            case PDFMAKE_INTERP_BILINEAR:
                scale_bilinear_gray(src->pixels, src->width, src->height,
                                    dst->pixels, dst_width, dst_height);
                break;
            case PDFMAKE_INTERP_BICUBIC:
                scale_bicubic_gray(src->pixels, src->width, src->height,
                                   dst->pixels, dst_width, dst_height);
                break;
        }
    } else if (src->components == 3) {
        /* RGB */
        switch (mode) {
            case PDFMAKE_INTERP_NEAREST:
                scale_nearest_rgb(src->pixels, src->width, src->height,
                                  dst->pixels, dst_width, dst_height);
                break;
            case PDFMAKE_INTERP_BILINEAR:
                scale_bilinear_rgb(src->pixels, src->width, src->height,
                                   dst->pixels, dst_width, dst_height);
                break;
            case PDFMAKE_INTERP_BICUBIC:
                scale_bicubic_rgb(src->pixels, src->width, src->height,
                                  dst->pixels, dst_width, dst_height);
                break;
        }
    } else if (src->components == 4) {
        /* CMYK - convert to RGB first then scale? Or scale as 4-channel */
        /* For now, scale each channel independently like RGB */
        switch (mode) {
            case PDFMAKE_INTERP_NEAREST:
                scale_nearest_rgb(src->pixels, src->width, src->height,
                                  dst->pixels, dst_width, dst_height);
                /* Handle 4th channel */
                break;
            default:
                /* Just do nearest for now */
                scale_nearest_rgb(src->pixels, src->width, src->height,
                                  dst->pixels, dst_width, dst_height);
                break;
        }
    }
    
    /* Scale alpha channel if present */
    if (src->has_alpha && src->alpha) {
        dst->alpha_len = (size_t)dst_width * dst_height;
        if (arena) {
            dst->alpha = pdfmake_arena_alloc(arena, dst->alpha_len);
        } else {
            dst->alpha = malloc(dst->alpha_len);
        }
        
        if (dst->alpha) {
            switch (mode) {
                case PDFMAKE_INTERP_NEAREST:
                    scale_nearest_gray(src->alpha, src->width, src->height,
                                       dst->alpha, dst_width, dst_height);
                    break;
                case PDFMAKE_INTERP_BILINEAR:
                    scale_bilinear_gray(src->alpha, src->width, src->height,
                                        dst->alpha, dst_width, dst_height);
                    break;
                case PDFMAKE_INTERP_BICUBIC:
                    scale_bicubic_gray(src->alpha, src->width, src->height,
                                       dst->alpha, dst_width, dst_height);
                    break;
            }
        }
    }
    
    *out = dst;
    return PDFMAKE_IMGR_OK;
}

pdfmake_imgr_err_t pdfmake_rgba_scale(
    const uint32_t *src, int src_w, int src_h,
    uint32_t *dst, int dst_w, int dst_h,
    pdfmake_interp_mode_t mode)
{
    if (!src || !dst) return PDFMAKE_IMGR_ERR_NULL;
    if (src_w <= 0 || src_h <= 0 || dst_w <= 0 || dst_h <= 0) {
        return PDFMAKE_IMGR_ERR_INVALID;
    }
    
    switch (mode) {
        case PDFMAKE_INTERP_NEAREST:
            scale_nearest_rgba32(src, src_w, src_h, dst, dst_w, dst_h);
            break;
        case PDFMAKE_INTERP_BILINEAR:
            scale_bilinear_rgba32(src, src_w, src_h, dst, dst_w, dst_h);
            break;
        case PDFMAKE_INTERP_BICUBIC:
            scale_bicubic_rgba32(src, src_w, src_h, dst, dst_w, dst_h);
            break;
        default:
            return PDFMAKE_IMGR_ERR_INVALID;
    }
    
    return PDFMAKE_IMGR_OK;
}

/*============================================================================
 * Convenience: scale in place (allocates new buffer)
 *==========================================================================*/

pdfmake_imgr_err_t pdfmake_decoded_image_resize(
    pdfmake_decoded_image_t *img,
    int new_width, int new_height,
    pdfmake_interp_mode_t mode,
    pdfmake_arena_t *arena)
{
    pdfmake_decoded_image_t *scaled;
    pdfmake_imgr_err_t err;
    
    if (!img) return PDFMAKE_IMGR_ERR_NULL;
    
    err = pdfmake_decoded_image_scale(
        img, new_width, new_height, mode, &scaled, arena);
    
    if (err != PDFMAKE_IMGR_OK) return err;
    
    /* Swap data */
    if (!arena && img->owns_data) {
        free(img->pixels);
        free(img->alpha);
        free(img->rgba);
    }
    
    img->width = scaled->width;
    img->height = scaled->height;
    img->pixels = scaled->pixels;
    img->pixels_len = scaled->pixels_len;
    img->row_stride = scaled->row_stride;
    img->alpha = scaled->alpha;
    img->alpha_len = scaled->alpha_len;
    img->rgba = NULL;  /* Invalidate RGBA cache */
    img->rgba_len = 0;
    
    /* Free the wrapper struct only */
    if (!arena) free(scaled);
    
    return PDFMAKE_IMGR_OK;
}
