/*
 * pdfmake_decode_dct.c - JPEG (DCT) decoder for image rendering
 *
 * Uses stb_image for JPEG decoding. This module provides:
 * - DCTDecode filter for PDF streams
 * - Decoding to decoded_image_t for rendering
 * - Support for CMYK JPEG (with Adobe marker)
 *
 * Note: stb_image.h must be available in include path.
 * Download from: https://github.com/nothings/stb/blob/master/stb_image.h
 *
 * Reference: PDF 32000-1:2008 §7.4.8 DCTDecode Filter
 */

/* Define this in ONE source file before including stb_image.h */
#define STB_IMAGE_IMPLEMENTATION
#define STBI_NO_FAILURE_STRINGS
#define STBI_ONLY_JPEG  /* We only need JPEG support */

/* Forward declaration - stb_image will be included if available */
#ifdef PDFMAKE_HAS_STB_IMAGE
#include "stb_image.h"
#endif

#include "pdfmake_image_render.h"
#include "pdfmake_arena.h"
#include <stdlib.h>
#include <string.h>

/*============================================================================
 * Built-in minimal JPEG decoder (fallback)
 *
 * This is a simplified decoder for baseline JPEG only.
 * For production use, link against stb_image or libjpeg.
 *==========================================================================*/

#ifndef PDFMAKE_HAS_STB_IMAGE

/* JPEG marker definitions */
#define JPEG_MARKER_SOI  0xD8
#define JPEG_MARKER_EOI  0xD9
#define JPEG_MARKER_SOF0 0xC0  /* Baseline DCT */
#define JPEG_MARKER_SOF2 0xC2  /* Progressive DCT */
#define JPEG_MARKER_DHT  0xC4  /* Huffman table */
#define JPEG_MARKER_DQT  0xDB  /* Quantization table */
#define JPEG_MARKER_DRI  0xDD  /* Restart interval */
#define JPEG_MARKER_SOS  0xDA  /* Start of scan */
#define JPEG_MARKER_APP0 0xE0  /* JFIF marker */
#define JPEG_MARKER_APP14 0xEE /* Adobe marker */
#define JPEG_MARKER_COM  0xFE  /* Comment */

typedef struct jpeg_reader {
    const uint8_t *data;
    size_t len;
    size_t pos;
    
    int width;
    int height;
    int components;
    int adobe_transform;  /* 0=unknown, 1=YCbCr, 2=YCCK */
} jpeg_reader_t;

static uint8_t jpeg_read_byte(jpeg_reader_t *r) {
    if (r->pos >= r->len) return 0;
    return r->data[r->pos++];
}

static uint16_t jpeg_read_word(jpeg_reader_t *r) {
    uint8_t hi = jpeg_read_byte(r);
    uint8_t lo = jpeg_read_byte(r);
    return (hi << 8) | lo;
}

static int jpeg_skip(jpeg_reader_t *r, size_t n) {
    if (r->pos + n > r->len) return -1;
    r->pos += n;
    return 0;
}

/*
 * Parse JPEG header to extract dimensions and component count.
 * Does NOT decode the image data.
 */
static int jpeg_parse_header(jpeg_reader_t *r) {
    r->pos = 0;
    r->adobe_transform = 0;
    
    /* Check SOI marker */
    if (jpeg_read_byte(r) != 0xFF || jpeg_read_byte(r) != JPEG_MARKER_SOI) {
        return -1;  /* Not a JPEG */
    }
    
    while (r->pos < r->len) {
        uint8_t marker;
        uint16_t seg_len;

        /* Find next marker */
        if (jpeg_read_byte(r) != 0xFF) {
            return -1;
        }

        do {
            marker = jpeg_read_byte(r);
        } while (marker == 0xFF && r->pos < r->len);

        if (marker == JPEG_MARKER_EOI) {
            break;
        }

        /* Markers without length */
        if (marker == 0 || marker == JPEG_MARKER_SOI ||
            (marker >= 0xD0 && marker <= 0xD7)) {
            continue;
        }

        /* Read segment length */
        seg_len = jpeg_read_word(r);
        if (seg_len < 2) return -1;
        seg_len -= 2;

        switch (marker) {
            case JPEG_MARKER_SOF0:
            case JPEG_MARKER_SOF2: {
                /* Frame header */
                if (seg_len < 6) return -1;
                jpeg_read_byte(r);  /* precision */
                r->height = jpeg_read_word(r);
                r->width = jpeg_read_word(r);
                r->components = jpeg_read_byte(r);
                jpeg_skip(r, seg_len - 6);
                /* Found dimensions, could stop here */
                break;
            }
            
            case JPEG_MARKER_APP14: {
                /* Adobe marker */
                if (seg_len >= 12) {
                    char sig[5];
                    int i;
                    for (i = 0; i < 5; i++) {
                        sig[i] = jpeg_read_byte(r);
                    }
                    if (memcmp(sig, "Adobe", 5) == 0) {
                        jpeg_skip(r, 6);  /* Skip version, flags */
                        r->adobe_transform = jpeg_read_byte(r);
                        jpeg_skip(r, seg_len - 12);
                    } else {
                        jpeg_skip(r, seg_len - 5);
                    }
                } else {
                    jpeg_skip(r, seg_len);
                }
                break;
            }
            
            case JPEG_MARKER_SOS:
                /* Start of scan - we've parsed enough headers */
                return 0;
            
            default:
                /* Skip unknown segment */
                jpeg_skip(r, seg_len);
                break;
        }
    }
    
    return (r->width > 0 && r->height > 0) ? 0 : -1;
}

#endif /* !PDFMAKE_HAS_STB_IMAGE */

/*============================================================================
 * Public API
 *==========================================================================*/

pdfmake_imgr_err_t pdfmake_decode_jpeg_raw(
    const uint8_t *data, size_t len,
    uint8_t **pixels_out, size_t *pixels_len,
    int *width, int *height, int *components)
{
#ifndef PDFMAKE_HAS_STB_IMAGE
    jpeg_reader_t reader;
#endif

    if (!data || !pixels_out || !width || !height || !components) {
        return PDFMAKE_IMGR_ERR_NULL;
    }
    
#ifdef PDFMAKE_HAS_STB_IMAGE
    /* Use stb_image */
    {
        int w, h, comp;
        uint8_t *pixels = stbi_load_from_memory(data, len, &w, &h, &comp, 0);

        if (!pixels) {
            return PDFMAKE_IMGR_ERR_DECODE_FAILED;
        }

        *pixels_out = pixels;
        *pixels_len = (size_t)w * h * comp;
        *width = w;
        *height = h;
        *components = comp;

        return PDFMAKE_IMGR_OK;
    }
#else
    /* Fallback: parse header only, return raw DCT data */
    reader.data = data;
    reader.len = len;
    reader.pos = 0;
    reader.width = 0;
    reader.height = 0;
    reader.components = 0;
    reader.adobe_transform = 0;

    if (jpeg_parse_header(&reader) != 0) {
        return PDFMAKE_IMGR_ERR_DECODE_FAILED;
    }
    
    /* For now, without stb_image, we can't actually decode.
     * Return an error indicating we need the library.
     * In production, you would link libjpeg or include stb_image. */
    (void)pixels_len;
    
    *width = reader.width;
    *height = reader.height;
    *components = reader.components;
    *pixels_out = NULL;
    
    return PDFMAKE_IMGR_ERR_UNSUPPORTED;
#endif
}

pdfmake_imgr_err_t pdfmake_decode_jpeg_to_image(
    const uint8_t *data, size_t len,
    pdfmake_decoded_image_t **out,
    pdfmake_arena_t *arena)
{
    int width, height, components;
    uint8_t *pixels = NULL;
    size_t pixels_len = 0;
    pdfmake_imgr_err_t err;
    pdfmake_decoded_image_t *img;

    if (!data || !out) return PDFMAKE_IMGR_ERR_NULL;

    err = pdfmake_decode_jpeg_raw(
        data, len, &pixels, &pixels_len, &width, &height, &components);

    if (err != PDFMAKE_IMGR_OK) {
        return err;
    }

    /* Create decoded image */
    img = pdfmake_decoded_image_create(arena);
    if (!img) {
        free(pixels);
        return PDFMAKE_IMGR_ERR_MEMORY;
    }
    
    img->width = width;
    img->height = height;
    img->bits_per_component = 8;
    img->components = components;
    img->row_stride = width * components;
    img->pixels = pixels;
    img->pixels_len = pixels_len;
    
    /* Set colorspace based on component count */
    switch (components) {
        case 1:
            img->colorspace = PDFMAKE_RCS_GRAY;
            break;
        case 3:
            img->colorspace = PDFMAKE_RCS_RGB;
            break;
        case 4:
            img->colorspace = PDFMAKE_RCS_CMYK;
            break;
        default:
            img->colorspace = PDFMAKE_RCS_RGB;
            break;
    }
    
    /* If using arena, we need to copy pixels to arena memory */
    if (arena) {
        uint8_t *arena_pixels = pdfmake_arena_alloc(arena, pixels_len);
        if (!arena_pixels) {
            free(pixels);
            return PDFMAKE_IMGR_ERR_MEMORY;
        }
        memcpy(arena_pixels, pixels, pixels_len);
        free(pixels);
        img->pixels = arena_pixels;
        img->owns_data = 0;
    } else {
        img->owns_data = 1;
    }
    
    *out = img;
    return PDFMAKE_IMGR_OK;
}

/*============================================================================
 * DCTDecode filter for PDF streams
 *==========================================================================*/

/*
 * Decode DCT-compressed stream data.
 * This is the filter interface for PDF stream processing.
 */
pdfmake_imgr_err_t pdfmake_dct_decode(
    const uint8_t *src, size_t src_len,
    uint8_t **dst, size_t *dst_len,
    int *width, int *height, int *components)
{
    return pdfmake_decode_jpeg_raw(src, src_len, dst, dst_len,
                                    width, height, components);
}

/*
 * Check if data starts with JPEG signature.
 */
int pdfmake_is_jpeg(const uint8_t *data, size_t len) {
    if (!data || len < 2) return 0;
    return (data[0] == 0xFF && data[1] == 0xD8);
}

/*
 * Get JPEG dimensions without full decode.
 */
int pdfmake_jpeg_get_dimensions(
    const uint8_t *data, size_t len,
    int *width, int *height, int *components)
{
#ifndef PDFMAKE_HAS_STB_IMAGE
    jpeg_reader_t reader;
#endif

    if (!data || !width || !height) return -1;
    
#ifdef PDFMAKE_HAS_STB_IMAGE
    {
        int w, h, comp;
        if (!stbi_info_from_memory(data, len, &w, &h, &comp)) {
            return -1;
        }
        *width = w;
        *height = h;
        if (components) *components = comp;
        return 0;
    }
#else
    reader.data = data;
    reader.len = len;
    reader.pos = 0;
    reader.width = 0;
    reader.height = 0;
    reader.components = 0;
    reader.adobe_transform = 0;
    if (jpeg_parse_header(&reader) != 0) {
        return -1;
    }
    *width = reader.width;
    *height = reader.height;
    if (components) *components = reader.components;
    return 0;
#endif
}

/*============================================================================
 * CMYK JPEG handling
 *
 * Some PDF JPEG streams are CMYK. Adobe uses a marker to indicate
 * the color transform:
 *   0 = No transform (CMYK)
 *   1 = YCbCr
 *   2 = YCCK (CMYK with YCbCr encoding)
 *==========================================================================*/

/*
 * Decode CMYK JPEG (inverts colors per Adobe convention).
 */
pdfmake_imgr_err_t pdfmake_decode_cmyk_jpeg(
    const uint8_t *data, size_t len,
    pdfmake_decoded_image_t **out,
    pdfmake_arena_t *arena)
{
    pdfmake_imgr_err_t err;
    pdfmake_decoded_image_t *img;

    /* First decode normally */
    err = pdfmake_decode_jpeg_to_image(data, len, out, arena);
    if (err != PDFMAKE_IMGR_OK) return err;

    img = *out;

    /* If CMYK, invert all values (Adobe convention) */
    if (img->colorspace == PDFMAKE_RCS_CMYK && img->pixels) {
        size_t i;
        for (i = 0; i < img->pixels_len; i++) {
            img->pixels[i] = 255 - img->pixels[i];
        }
    }

    return PDFMAKE_IMGR_OK;
}
