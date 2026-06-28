#ifndef PDFMAKE_IMAGE_H
#define PDFMAKE_IMAGE_H

#include "pdfmake_types.h"
#include "pdfmake_buf.h"
#include "pdfmake_doc.h"

#ifdef __cplusplus
extern "C" {
#endif

/* Image colour space */
typedef enum {
    PDFMAKE_IMAGE_GRAY = 0,
    PDFMAKE_IMAGE_RGB  = 1,
    PDFMAKE_IMAGE_CMYK = 2,
    PDFMAKE_IMAGE_INDEXED = 3,
} pdfmake_image_colorspace_t;

/* Image format */
typedef enum {
    PDFMAKE_IMAGE_JPEG = 0,
    PDFMAKE_IMAGE_PNG  = 1,
    PDFMAKE_IMAGE_RAW  = 2,
} pdfmake_image_format_t;

/* Image handle */
typedef struct {
    pdfmake_image_format_t     format;
    pdfmake_image_colorspace_t colorspace;
    uint32_t    width;
    uint32_t    height;
    uint8_t     bits_per_component;  /* 1, 2, 4, 8, 16 */
    uint8_t     components;          /* 1, 3, 4 */
    int         has_alpha;           /* PNG alpha channel */

    /* Stream data for the /Image XObject */
    uint8_t    *data;       /* encoded image data (owned) */
    size_t      data_len;

    /* Alpha/SMask data (PNG with alpha) */
    uint8_t    *smask_data;
    size_t      smask_len;

    /* Palette for indexed colour (PNG) */
    uint8_t    *palette;     /* RGB triplets */
    size_t      palette_len; /* number of bytes (entries * 3) */

    /* Transparency for indexed colour (PNG tRNS) */
    uint8_t    *trns;
    size_t      trns_len;

    /* Object numbers after write (0 = not yet written) */
    uint32_t    obj_num;
    uint32_t    smask_num;
} pdfmake_image_t;

/* Raw raster input description */
typedef struct {
    pdfmake_image_colorspace_t colorspace;
    uint32_t    width;
    uint32_t    height;
    uint8_t     bits_per_component;
    const uint8_t *pixels;      /* row-major, no padding */
    size_t         pixels_len;
    const uint8_t *alpha;       /* optional alpha plane (same dims, 8-bit) */
    size_t         alpha_len;
    const uint8_t *palette;     /* for indexed: RGB triplets */
    size_t         palette_len;
} pdfmake_image_raw_t;

/* ── Creation ──────────────────────────────────────────── */

/* Parse JPEG file, validate header, wrap for DCTDecode passthrough. */
pdfmake_image_t *pdfmake_image_from_jpeg(
    pdfmake_doc_t *doc, const uint8_t *bytes, size_t len);

/* Parse PNG file, decompress IDAT, re-encode for PDF embedding. */
pdfmake_image_t *pdfmake_image_from_png(
    pdfmake_doc_t *doc, const uint8_t *bytes, size_t len);

/* Wrap raw pixel data. */
pdfmake_image_t *pdfmake_image_from_raw(
    pdfmake_doc_t *doc, const pdfmake_image_raw_t *raw);

/* Auto-detect format from magic bytes and dispatch. */
pdfmake_image_t *pdfmake_image_from_bytes(
    pdfmake_doc_t *doc, const uint8_t *bytes, size_t len);

/* ── Writing ───────────────────────────────────────────── */

/* Emit /Image XObject (and /SMask if alpha). Returns obj number, 0 on error. */
uint32_t pdfmake_image_write(pdfmake_image_t *img, pdfmake_doc_t *doc);

/* ── Cleanup ───────────────────────────────────────────── */

void pdfmake_image_free(pdfmake_image_t *img);

/* ── Page integration ──────────────────────────────────── */

/* Add an image XObject to a page's resources. Returns resource index or -1. */
int pdfmake_page_add_image(pdfmake_page_t *page, const char *name, uint32_t img_obj_num);

#ifdef __cplusplus
}
#endif

#endif /* PDFMAKE_IMAGE_H */
