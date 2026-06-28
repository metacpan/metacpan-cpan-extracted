/*
 * pdfmake_image.c — Image embedding: JPEG passthrough, PNG decode+re-encode, raw raster.
 *
 * §8.9 Images, §7.4.8 DCTDecode, §7.4.4 FlateDecode + predictor
 */

#include "pdfmake_image.h"
#include "pdfmake_page.h"
#include "pdfmake_arena.h"
#include "pdfmake_buf.h"
#include "pdfmake_filter.h"
#include "pdfmake_writer.h"
#include "pdfmake_internal.h"
#include <stdlib.h>
#include <string.h>

/* ── JPEG header parser ──────────────────────────────────────────────────── */

/* JPEG markers */
#define JPEG_SOI  0xFFD8
#define JPEG_SOF0 0xFFC0  /* Baseline DCT */
#define JPEG_SOF1 0xFFC1  /* Extended sequential DCT */
#define JPEG_SOF2 0xFFC2  /* Progressive DCT */
#define JPEG_EOI  0xFFD9

static int jpeg_parse_header(const uint8_t *data, size_t len,
                             uint32_t *width, uint32_t *height,
                             uint8_t *components, uint8_t *bpc)
{
    size_t pos;
    uint8_t marker;
    uint16_t seg_len;
    if (len < 2 || data[0] != 0xFF || data[1] != 0xD8)
        return 0; /* Not a JPEG */

    pos = 2;
    while (pos + 4 <= len) {
        if (data[pos] != 0xFF) return 0;

        marker = data[pos + 1];
        pos += 2;

        /* Markers without payload */
        if (marker == 0x00 || marker == 0x01 || (marker >= 0xD0 && marker <= 0xD7))
            continue;

        if (marker == 0xD9) break; /* EOI */

        if (pos + 2 > len) return 0;
        seg_len = ((uint16_t)data[pos] << 8) | data[pos + 1];
        if (seg_len < 2) return 0;

        /* SOF0, SOF1, SOF2 — Start of Frame */
        if (marker == 0xC0 || marker == 0xC1 || marker == 0xC2) {
            if (pos + seg_len > len || seg_len < 8) return 0;
            *bpc        = data[pos + 2];
            *height     = ((uint32_t)data[pos + 3] << 8) | data[pos + 4];
            *width      = ((uint32_t)data[pos + 5] << 8) | data[pos + 6];
            *components = data[pos + 7];
            return 1;
        }

        pos += seg_len;
    }
    return 0; /* No SOF found */
}

pdfmake_image_t *pdfmake_image_from_jpeg(pdfmake_doc_t *doc,
                                          const uint8_t *bytes, size_t len)
{
    uint32_t w, h;
    uint8_t comp, bpc;
    pdfmake_image_t *img;
    (void)doc; /* doc not needed for JPEG passthrough */
    if (!bytes || len < 4) return NULL;

    if (!jpeg_parse_header(bytes, len, &w, &h, &comp, &bpc))
        return NULL;

    img = calloc(1, sizeof(pdfmake_image_t));
    if (!img) return NULL;

    img->format = PDFMAKE_IMAGE_JPEG;
    img->width = w;
    img->height = h;
    img->bits_per_component = bpc;
    img->components = comp;
    img->has_alpha = 0;

    switch (comp) {
        case 1: img->colorspace = PDFMAKE_IMAGE_GRAY; break;
        case 3: img->colorspace = PDFMAKE_IMAGE_RGB;  break;
        case 4: img->colorspace = PDFMAKE_IMAGE_CMYK; break;
        default: free(img); return NULL;
    }

    /* DCTDecode passthrough: store the raw JPEG bytes */
    img->data = malloc(len);
    if (!img->data) { free(img); return NULL; }
    memcpy(img->data, bytes, len);
    img->data_len = len;

    return img;
}

/* ── PNG parser ──────────────────────────────────────────────────────────── */

/* PNG magic: 137 80 78 71 13 10 26 10 */
static const uint8_t PNG_SIG[8] = {137, 80, 78, 71, 13, 10, 26, 10};

pdfmake_image_t *pdfmake_image_from_png(pdfmake_doc_t *doc,
                                         const uint8_t *bytes, size_t len)
{
    size_t pos;
    uint32_t ihdr_len;
    uint32_t w;
    uint32_t h;
    uint8_t bit_depth;
    uint8_t color_type;
    uint8_t interlace;
    uint8_t components;
    int has_alpha;
    pdfmake_image_colorspace_t cs;
    pdfmake_buf_t idat_buf;
    uint8_t *palette;
    size_t palette_len;
    uint8_t *trns;
    size_t trns_len;
    uint32_t chunk_len;
    const uint8_t *chunk_type;
    const uint8_t *chunk_data;
    pdfmake_buf_t raw_buf;
    pdfmake_flate_params_t params;
    pdfmake_buf_t unfiltered;
    uint8_t *color_data;
    size_t color_len;
    uint8_t *alpha_data;
    size_t alpha_len;
    uint8_t color_comp;
    size_t row_color_bytes;
    size_t row_alpha_bytes;
    size_t src_row;
    uint32_t row;
    const uint8_t *src;
    uint8_t *cdst;
    uint8_t *adst;
    uint32_t col;
    size_t bpp;
    pdfmake_buf_t encoded;
    pdfmake_flate_params_t enc_params;
    uint8_t *smask_enc;
    size_t smask_enc_len;
    pdfmake_buf_t smask_buf;
    pdfmake_flate_params_t smask_params;
    pdfmake_image_t *img;
    (void)doc; /* doc not needed during parse — we use malloc */
    if (!bytes || len < 33) return NULL;
    if (memcmp(bytes, PNG_SIG, 8) != 0) return NULL;

    /* Parse IHDR (must be first chunk after signature) */
    pos = 8;
    ihdr_len = pdfmake_read_be32(bytes + pos);
    if (memcmp(bytes + pos + 4, "IHDR", 4) != 0 || ihdr_len != 13)
        return NULL;
    pos += 8; /* skip length + "IHDR" */

    w          = pdfmake_read_be32(bytes + pos);
    h          = pdfmake_read_be32(bytes + pos + 4);
    bit_depth  = bytes[pos + 8];
    color_type = bytes[pos + 9];
    interlace  = bytes[pos + 12];

    if (interlace != 0) return NULL; /* Adam7 not supported */
    if (bit_depth != 8 && bit_depth != 16) return NULL; /* Simplification */

    pos += ihdr_len + 4; /* skip IHDR data + CRC */

    /* Determine components and colorspace */
    has_alpha = 0;

    switch (color_type) {
        case 0: components = 1; cs = PDFMAKE_IMAGE_GRAY; break;       /* Grayscale */
        case 2: components = 3; cs = PDFMAKE_IMAGE_RGB; break;        /* RGB */
        case 3: components = 1; cs = PDFMAKE_IMAGE_INDEXED; break;    /* Indexed */
        case 4: components = 2; cs = PDFMAKE_IMAGE_GRAY; has_alpha = 1; break; /* Gray+Alpha */
        case 6: components = 4; cs = PDFMAKE_IMAGE_RGB; has_alpha = 1; break;  /* RGBA */
        default: return NULL;
    }

    /* Collect PLTE, tRNS, and all IDAT chunks */
    pdfmake_buf_init(&idat_buf);

    palette = NULL;
    palette_len = 0;
    trns = NULL;
    trns_len = 0;

    while (pos + 12 <= len) {
        chunk_len = pdfmake_read_be32(bytes + pos);
        chunk_type = bytes + pos + 4;
        chunk_data = bytes + pos + 8;

        if (pos + 12 + chunk_len > len) break;

        if (memcmp(chunk_type, "IDAT", 4) == 0) {
            pdfmake_buf_append(&idat_buf, chunk_data, chunk_len);
        }
        else if (memcmp(chunk_type, "PLTE", 4) == 0) {
            palette = malloc(chunk_len);
            if (palette) {
                memcpy(palette, chunk_data, chunk_len);
                palette_len = chunk_len;
            }
        }
        else if (memcmp(chunk_type, "tRNS", 4) == 0) {
            trns = malloc(chunk_len);
            if (trns) {
                memcpy(trns, chunk_data, chunk_len);
                trns_len = chunk_len;
            }
        }
        else if (memcmp(chunk_type, "IEND", 4) == 0) {
            break;
        }

        pos += 12 + chunk_len; /* length(4) + type(4) + data + crc(4) */
    }

    if (idat_buf.len == 0) {
        pdfmake_buf_free(&idat_buf);
        free(palette); free(trns);
        return NULL;
    }

    /* Decompress IDAT (zlib-wrapped deflate) */
    pdfmake_buf_init(&raw_buf);

    memset(&params, 0, sizeof(params));
    params.predictor = 1; /* No predictor for initial inflate */
    if (pdfmake_flate_decode(idat_buf.data, idat_buf.len, &params, &raw_buf) != PDFMAKE_OK) {
        pdfmake_buf_free(&idat_buf);
        pdfmake_buf_free(&raw_buf);
        free(palette); free(trns);
        return NULL;
    }
    pdfmake_buf_free(&idat_buf);

    /* Reverse PNG row filters */
    pdfmake_buf_init(&unfiltered);

    if (pdfmake_predictor_decode(15, components, bit_depth, w,
                                  raw_buf.data, raw_buf.len, &unfiltered) != PDFMAKE_OK) {
        pdfmake_buf_free(&raw_buf);
        pdfmake_buf_free(&unfiltered);
        free(palette); free(trns);
        return NULL;
    }
    pdfmake_buf_free(&raw_buf);

    /* Now unfiltered has raw pixel data (w * components * bpc/8) * h bytes */

    /* Separate alpha channel if present */
    color_data = NULL;
    color_len = 0;
    alpha_data = NULL;
    alpha_len = 0;

    if (has_alpha) {
        color_comp = components - 1; /* RGB=3, Gray=1 */
        row_color_bytes = (size_t)w * color_comp * (bit_depth / 8);
        row_alpha_bytes = (size_t)w * (bit_depth / 8);
        color_len = row_color_bytes * h;
        alpha_len = row_alpha_bytes * h;

        color_data = malloc(color_len);
        alpha_data = malloc(alpha_len);
        if (!color_data || !alpha_data) {
            free(color_data); free(alpha_data);
            pdfmake_buf_free(&unfiltered);
            free(palette); free(trns);
            return NULL;
        }

        src_row = (size_t)w * components * (bit_depth / 8);
        for (row = 0; row < h; row++) {
            src = unfiltered.data + row * src_row;
            cdst = color_data + row * row_color_bytes;
            adst = alpha_data + row * row_alpha_bytes;
            for (col = 0; col < w; col++) {
                bpp = bit_depth / 8;
                memcpy(cdst, src, color_comp * bpp);
                memcpy(adst, src + color_comp * bpp, bpp);
                src += components * bpp;
                cdst += color_comp * bpp;
                adst += bpp;
            }
        }
        components = color_comp;
    } else {
        color_len = unfiltered.len;
        color_data = malloc(color_len);
        if (!color_data) {
            pdfmake_buf_free(&unfiltered);
            free(palette); free(trns);
            return NULL;
        }
        memcpy(color_data, unfiltered.data, color_len);
    }
    pdfmake_buf_free(&unfiltered);

    /* Re-encode color data with FlateDecode + PNG predictor for PDF */
    pdfmake_buf_init(&encoded);
    memset(&enc_params, 0, sizeof(enc_params));
    enc_params.predictor = 15; /* PNG Optimum */
    enc_params.colors = (cs == PDFMAKE_IMAGE_INDEXED) ? 1 : components;
    enc_params.bits_per_comp = bit_depth;
    enc_params.columns = w;

    if (pdfmake_flate_encode(color_data, color_len, &enc_params, &encoded) != PDFMAKE_OK) {
        free(color_data); free(alpha_data);
        pdfmake_buf_free(&encoded);
        free(palette); free(trns);
        return NULL;
    }
    free(color_data);

    /* Re-encode alpha (SMask) */
    smask_enc = NULL;
    smask_enc_len = 0;
    if (alpha_data) {
        pdfmake_buf_init(&smask_buf);
        memset(&smask_params, 0, sizeof(smask_params));
        smask_params.predictor = 15;
        smask_params.colors = 1;
        smask_params.bits_per_comp = bit_depth;
        smask_params.columns = w;

        if (pdfmake_flate_encode(alpha_data, alpha_len, &smask_params, &smask_buf) == PDFMAKE_OK) {
            smask_enc = smask_buf.data;
            smask_enc_len = smask_buf.len;
            /* Don't free smask_buf — we're stealing .data */
        }
        free(alpha_data);
    }

    /* Build image struct */
    img = calloc(1, sizeof(pdfmake_image_t));
    if (!img) {
        pdfmake_buf_free(&encoded);
        free(smask_enc); free(palette); free(trns);
        return NULL;
    }

    img->format = PDFMAKE_IMAGE_PNG;
    img->colorspace = cs;
    img->width = w;
    img->height = h;
    img->bits_per_component = bit_depth;
    img->components = components;
    img->has_alpha = has_alpha;

    img->data = encoded.data;
    img->data_len = encoded.len;
    /* Don't free encoded — we're stealing .data */

    img->smask_data = smask_enc;
    img->smask_len = smask_enc_len;

    img->palette = palette;
    img->palette_len = palette_len;
    img->trns = trns;
    img->trns_len = trns_len;

    return img;
}

/* ── Raw raster ──────────────────────────────────────────────────────────── */

pdfmake_image_t *pdfmake_image_from_raw(pdfmake_doc_t *doc,
                                         const pdfmake_image_raw_t *raw)
{
    pdfmake_image_t *img;
    pdfmake_buf_t encoded;
    pdfmake_flate_params_t params;
    pdfmake_buf_t smask_buf;
    if (!doc || !raw || !raw->pixels) return NULL;

    img = calloc(1, sizeof(pdfmake_image_t));
    if (!img) return NULL;

    img->format = PDFMAKE_IMAGE_RAW;
    img->colorspace = raw->colorspace;
    img->width = raw->width;
    img->height = raw->height;
    img->bits_per_component = raw->bits_per_component;

    switch (raw->colorspace) {
        case PDFMAKE_IMAGE_GRAY:    img->components = 1; break;
        case PDFMAKE_IMAGE_RGB:     img->components = 3; break;
        case PDFMAKE_IMAGE_CMYK:    img->components = 4; break;
        case PDFMAKE_IMAGE_INDEXED: img->components = 1; break;
    }

    /* Compress with FlateDecode */
    pdfmake_buf_init(&encoded);
    memset(&params, 0, sizeof(params));
    params.predictor = 1; /* No predictor for raw */

    if (pdfmake_flate_encode(raw->pixels, raw->pixels_len, &params, &encoded) != PDFMAKE_OK) {
        free(img);
        pdfmake_buf_free(&encoded);
        return NULL;
    }

    img->data = encoded.data;
    img->data_len = encoded.len;

    /* Alpha channel */
    if (raw->alpha && raw->alpha_len > 0) {
        img->has_alpha = 1;
        pdfmake_buf_init(&smask_buf);
        if (pdfmake_flate_encode(raw->alpha, raw->alpha_len, &params, &smask_buf) == PDFMAKE_OK) {
            img->smask_data = smask_buf.data;
            img->smask_len = smask_buf.len;
        }
    }

    /* Palette */
    if (raw->palette && raw->palette_len > 0) {
        img->palette = malloc(raw->palette_len);
        if (img->palette) {
            memcpy(img->palette, raw->palette, raw->palette_len);
            img->palette_len = raw->palette_len;
        }
    }

    return img;
}

/* ── Auto-detect ─────────────────────────────────────────────────────────── */

pdfmake_image_t *pdfmake_image_from_bytes(pdfmake_doc_t *doc,
                                           const uint8_t *bytes, size_t len)
{
    if (!bytes || len < 8) return NULL;

    /* JPEG: starts with FF D8 */
    if (bytes[0] == 0xFF && bytes[1] == 0xD8)
        return pdfmake_image_from_jpeg(doc, bytes, len);

    /* PNG: starts with 89 50 4E 47 */
    if (memcmp(bytes, PNG_SIG, 8) == 0)
        return pdfmake_image_from_png(doc, bytes, len);

    return NULL; /* Unknown format */
}

/* ── Write /Image XObject ────────────────────────────────────────────────── */

uint32_t pdfmake_image_write(pdfmake_image_t *img, pdfmake_doc_t *doc)
{
    pdfmake_arena_t *arena;
    pdfmake_obj_t smask_stream;
    pdfmake_obj_t smask_dict_obj;
    pdfmake_obj_t *smask_dict;
    uint32_t k;
    pdfmake_obj_t dp;
    uint32_t pred_k;
    uint32_t cols_k;
    uint32_t bpc_k;
    uint32_t col_k;
    pdfmake_obj_t img_stream;
    pdfmake_obj_t img_dict_obj;
    pdfmake_obj_t *img_dict;
    pdfmake_obj_t cs_arr;
    if (!img || !doc || !img->data) return 0;

    arena = pdfmake_doc_arena(doc);

    /* Write SMask first if present */
    if (img->has_alpha && img->smask_data) {
        smask_stream = pdfmake_stream_new(arena);
        if (smask_stream.kind != PDFMAKE_STREAM) return 0;

        pdfmake_stream_set_data(arena, &smask_stream, img->smask_data, img->smask_len);
        /* smask_data is already Flate-encoded in pdfmake_image_from_png/raw */
        if (smask_stream.as.stream) {
            smask_stream.as.stream->filtered = 1;
        }

        /* Wrap stream's dict in an obj for pdfmake_dict_set */
        smask_dict_obj.kind = PDFMAKE_DICT;
        smask_dict_obj.as.dict = pdfmake_stream_dict(&smask_stream);
        smask_dict = &smask_dict_obj;

        k = pdfmake_arena_intern_name(arena, "Type", 4);
        pdfmake_dict_set(arena, smask_dict, k, pdfmake_name_cstr(arena, "XObject"));
        k = pdfmake_arena_intern_name(arena, "Subtype", 7);
        pdfmake_dict_set(arena, smask_dict, k, pdfmake_name_cstr(arena, "Image"));
        k = pdfmake_arena_intern_name(arena, "Width", 5);
        pdfmake_dict_set(arena, smask_dict, k, pdfmake_int(img->width));
        k = pdfmake_arena_intern_name(arena, "Height", 6);
        pdfmake_dict_set(arena, smask_dict, k, pdfmake_int(img->height));
        k = pdfmake_arena_intern_name(arena, "ColorSpace", 10);
        pdfmake_dict_set(arena, smask_dict, k, pdfmake_name_cstr(arena, "DeviceGray"));
        k = pdfmake_arena_intern_name(arena, "BitsPerComponent", 16);
        pdfmake_dict_set(arena, smask_dict, k, pdfmake_int(img->bits_per_component));
        k = pdfmake_arena_intern_name(arena, "Filter", 6);
        pdfmake_dict_set(arena, smask_dict, k, pdfmake_name_cstr(arena, "FlateDecode"));

        /* DecodeParms for PNG predictor */
        if (img->format == PDFMAKE_IMAGE_PNG) {
            dp = pdfmake_dict_new(arena);
            pred_k = pdfmake_arena_intern_name(arena, "Predictor", 9);
            cols_k = pdfmake_arena_intern_name(arena, "Columns", 7);
            bpc_k = pdfmake_arena_intern_name(arena, "BitsPerComponent", 16);
            col_k = pdfmake_arena_intern_name(arena, "Colors", 6);
            pdfmake_dict_set(arena, &dp, pred_k, pdfmake_int(15));
            pdfmake_dict_set(arena, &dp, cols_k, pdfmake_int(img->width));
            pdfmake_dict_set(arena, &dp, bpc_k, pdfmake_int(img->bits_per_component));
            pdfmake_dict_set(arena, &dp, col_k, pdfmake_int(1));
            k = pdfmake_arena_intern_name(arena, "DecodeParms", 11);
            pdfmake_dict_set(arena, smask_dict, k, dp);
        }

        k = pdfmake_arena_intern_name(arena, "Length", 6);
        pdfmake_dict_set(arena, smask_dict, k, pdfmake_int((int64_t)img->smask_len));

        img->smask_num = pdfmake_doc_add(doc, smask_stream);
        if (img->smask_num == 0) return 0;
    }

    /* Build /Image XObject stream */
    img_stream = pdfmake_stream_new(arena);
    if (img_stream.kind != PDFMAKE_STREAM) return 0;

    pdfmake_stream_set_data(arena, &img_stream, img->data, img->data_len);
    /* PNG/Raw image data is already Flate-encoded before write */
    if (img_stream.as.stream && img->format != PDFMAKE_IMAGE_JPEG) {
        img_stream.as.stream->filtered = 1;
    }

    /* Wrap stream's dict in an obj for pdfmake_dict_set */
    img_dict_obj.kind = PDFMAKE_DICT;
    img_dict_obj.as.dict = pdfmake_stream_dict(&img_stream);
    img_dict = &img_dict_obj;

    k = pdfmake_arena_intern_name(arena, "Type", 4);
    pdfmake_dict_set(arena, img_dict, k, pdfmake_name_cstr(arena, "XObject"));
    k = pdfmake_arena_intern_name(arena, "Subtype", 7);
    pdfmake_dict_set(arena, img_dict, k, pdfmake_name_cstr(arena, "Image"));
    k = pdfmake_arena_intern_name(arena, "Width", 5);
    pdfmake_dict_set(arena, img_dict, k, pdfmake_int(img->width));
    k = pdfmake_arena_intern_name(arena, "Height", 6);
    pdfmake_dict_set(arena, img_dict, k, pdfmake_int(img->height));
    k = pdfmake_arena_intern_name(arena, "BitsPerComponent", 16);
    pdfmake_dict_set(arena, img_dict, k, pdfmake_int(img->bits_per_component));

    /* ColorSpace */
    k = pdfmake_arena_intern_name(arena, "ColorSpace", 10);
    switch (img->colorspace) {
        case PDFMAKE_IMAGE_GRAY:
            pdfmake_dict_set(arena, img_dict, k, pdfmake_name_cstr(arena, "DeviceGray"));
            break;
        case PDFMAKE_IMAGE_RGB:
            pdfmake_dict_set(arena, img_dict, k, pdfmake_name_cstr(arena, "DeviceRGB"));
            break;
        case PDFMAKE_IMAGE_CMYK:
            pdfmake_dict_set(arena, img_dict, k, pdfmake_name_cstr(arena, "DeviceCMYK"));
            break;
        case PDFMAKE_IMAGE_INDEXED: {
            /* [/Indexed /DeviceRGB hival <palette hex>] */
            cs_arr = pdfmake_array_new(arena);
            pdfmake_array_push(arena, &cs_arr, pdfmake_name_cstr(arena, "Indexed"));
            pdfmake_array_push(arena, &cs_arr, pdfmake_name_cstr(arena, "DeviceRGB"));
            pdfmake_array_push(arena, &cs_arr, pdfmake_int((int64_t)(img->palette_len / 3 - 1)));
            pdfmake_array_push(arena, &cs_arr,
                pdfmake_hexstr(arena, img->palette, img->palette_len));
            pdfmake_dict_set(arena, img_dict, k, cs_arr);
            break;
        }
    }

    /* Filter */
    k = pdfmake_arena_intern_name(arena, "Filter", 6);
    if (img->format == PDFMAKE_IMAGE_JPEG) {
        pdfmake_dict_set(arena, img_dict, k, pdfmake_name_cstr(arena, "DCTDecode"));
    } else {
        pdfmake_dict_set(arena, img_dict, k, pdfmake_name_cstr(arena, "FlateDecode"));

        /* DecodeParms for PNG predictor */
        if (img->format == PDFMAKE_IMAGE_PNG) {
            dp = pdfmake_dict_new(arena);
            pred_k = pdfmake_arena_intern_name(arena, "Predictor", 9);
            cols_k = pdfmake_arena_intern_name(arena, "Columns", 7);
            bpc_k = pdfmake_arena_intern_name(arena, "BitsPerComponent", 16);
            col_k = pdfmake_arena_intern_name(arena, "Colors", 6);
            pdfmake_dict_set(arena, &dp, pred_k, pdfmake_int(15));
            pdfmake_dict_set(arena, &dp, cols_k, pdfmake_int(img->width));
            pdfmake_dict_set(arena, &dp, bpc_k, pdfmake_int(img->bits_per_component));
            pdfmake_dict_set(arena, &dp, col_k, pdfmake_int(img->components));
            k = pdfmake_arena_intern_name(arena, "DecodeParms", 11);
            pdfmake_dict_set(arena, img_dict, k, dp);
        }
    }

    /* SMask reference */
    if (img->smask_num) {
        k = pdfmake_arena_intern_name(arena, "SMask", 5);
        pdfmake_dict_set(arena, img_dict, k, pdfmake_ref(img->smask_num, 0));
    }

    /* Length */
    k = pdfmake_arena_intern_name(arena, "Length", 6);
    pdfmake_dict_set(arena, img_dict, k, pdfmake_int((int64_t)img->data_len));

    img->obj_num = pdfmake_doc_add(doc, img_stream);
    return img->obj_num;
}

/* ── Cleanup ─────────────────────────────────────────────────────────────── */

void pdfmake_image_free(pdfmake_image_t *img)
{
    if (!img) return;
    free(img->data);
    free(img->smask_data);
    free(img->palette);
    free(img->trns);
    free(img);
}

/* ── Page XObject resource ───────────────────────────────────────────────── */

int pdfmake_page_add_image(pdfmake_page_t *page, const char *name, uint32_t img_obj_num)
{
    pdfmake_image_entry_t *entry;
    if (!page || !name || img_obj_num == 0) return -1;
    if (page->image_count >= PDFMAKE_MAX_PAGE_IMAGES) return -1;

    entry = &page->images[page->image_count++];
    strncpy(entry->name, name, sizeof(entry->name) - 1);
    entry->name[sizeof(entry->name) - 1] = '\0';
    entry->image_num = img_obj_num;

    return (int)(page->image_count - 1);
}
