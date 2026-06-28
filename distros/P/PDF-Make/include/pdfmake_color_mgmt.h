/*
 * pdfmake_color_mgmt.h — Color management: color spaces, ICC profiles, output intents.
 *
 * §8.6 Color Spaces
 * §14.11.5 Output Intents
 */

#ifndef PDFMAKE_COLOR_MGMT_H
#define PDFMAKE_COLOR_MGMT_H

#include "pdfmake_types.h"
#include "pdfmake_doc.h"
#include "pdfmake_arena.h"

#ifdef __cplusplus
extern "C" {
#endif

/* Color space family */
typedef enum {
    PDFMAKE_CS_DEVICE_GRAY = 0,
    PDFMAKE_CS_DEVICE_RGB,
    PDFMAKE_CS_DEVICE_CMYK,
    PDFMAKE_CS_CAL_GRAY,
    PDFMAKE_CS_CAL_RGB,
    PDFMAKE_CS_LAB,
    PDFMAKE_CS_ICC_BASED,
    PDFMAKE_CS_SEPARATION,
    PDFMAKE_CS_DEVICEN,
    PDFMAKE_CS_INDEXED,
    PDFMAKE_CS_PATTERN,
} pdfmake_cs_family_t;

/* Color space */
typedef struct pdfmake_colorspace {
    pdfmake_cs_family_t family;
    int                 components;       /* 1, 3, or 4 */
    char                name[128];        /* For Separation: spot color name */
    uint32_t            obj_num;          /* Written object number */

    /* CIE-based parameters */
    double              white_point[3];
    double              black_point[3];
    double              gamma[3];
    double              matrix[9];        /* CalRGB matrix */
    double              range[4];         /* Lab: aMin, aMax, bMin, bMax */

    /* ICC profile data */
    uint8_t            *icc_data;
    size_t              icc_data_len;
    char                icc_alt[32];      /* Alternate color space name */

    /* Separation tint: CMYK values at full tint */
    double              tint_cmyk[4];

    /* Indexed */
    struct pdfmake_colorspace *base;
    uint8_t            *palette;
    size_t              palette_len;
    int                 max_index;
} pdfmake_colorspace_t;

/* Output intent type */
typedef enum {
    PDFMAKE_INTENT_GTS_PDFX = 0,
    PDFMAKE_INTENT_GTS_PDFA,
    PDFMAKE_INTENT_ISO_PDFE,
} pdfmake_output_intent_type_t;

/* ── Device color spaces (singletons) ──────────────────── */

pdfmake_colorspace_t *pdfmake_cs_device_gray(void);
pdfmake_colorspace_t *pdfmake_cs_device_rgb(void);
pdfmake_colorspace_t *pdfmake_cs_device_cmyk(void);

/* ── CIE-based ─────────────────────────────────────────── */

pdfmake_colorspace_t *pdfmake_cs_cal_gray(
    pdfmake_arena_t *arena,
    const double white_point[3],
    const double *black_point,   /* NULL for default */
    double gamma_val);

pdfmake_colorspace_t *pdfmake_cs_cal_rgb(
    pdfmake_arena_t *arena,
    const double white_point[3],
    const double *black_point,
    const double gamma[3],
    const double matrix[9]);

pdfmake_colorspace_t *pdfmake_cs_lab(
    pdfmake_arena_t *arena,
    const double white_point[3],
    const double *black_point,
    const double range[4]);

/* ── ICC-based ─────────────────────────────────────────── */

pdfmake_colorspace_t *pdfmake_cs_icc_from_data(
    pdfmake_arena_t *arena,
    const uint8_t *data, size_t len,
    int components);

pdfmake_colorspace_t *pdfmake_cs_icc_from_path(
    pdfmake_arena_t *arena,
    const char *path,
    int components);

/* Built-in sRGB profile (minimal, ~3.1KB) */
pdfmake_colorspace_t *pdfmake_cs_srgb(pdfmake_arena_t *arena);

/* ── Separation (spot colors) ──────────────────────────── */

pdfmake_colorspace_t *pdfmake_cs_separation(
    pdfmake_arena_t *arena,
    const char *name,
    double c, double m, double y, double k);  /* CMYK at full tint */

/* ── Indexed ───────────────────────────────────────────── */

pdfmake_colorspace_t *pdfmake_cs_indexed(
    pdfmake_arena_t *arena,
    pdfmake_colorspace_t *base,
    int max_index,
    const uint8_t *palette, size_t palette_len);

/* ── Writing ───────────────────────────────────────────── */

/* Write color space to document. Returns obj_num. */
uint32_t pdfmake_cs_write(pdfmake_colorspace_t *cs, pdfmake_doc_t *doc);

/* Add color space to page resources. */
int pdfmake_page_add_colorspace(pdfmake_page_t *page,
    const char *name, uint32_t cs_obj_num);

/* ── Output intents ────────────────────────────────────── */

pdfmake_err_t pdfmake_doc_set_output_intent(
    pdfmake_doc_t *doc,
    pdfmake_output_intent_type_t type,
    pdfmake_colorspace_t *dest_profile,  /* ICC profile */
    const char *condition,               /* e.g. "FOGRA39" */
    const char *info);                   /* Description */

/* ── Basic conversion ──────────────────────────────────── */

/* Simple RGB → CMYK (naive, not ICC-accurate) */
void pdfmake_rgb_to_cmyk(double r, double g, double b,
                          double *c, double *m, double *y, double *k);

/* Simple CMYK → RGB */
void pdfmake_cmyk_to_rgb(double c, double m, double y, double k,
                          double *r, double *g, double *b);

/* Gray → RGB */
void pdfmake_gray_to_rgb(double gray, double *r, double *g, double *b);

/* Hex string to RGB */
int pdfmake_hex_to_rgb(const char *hex, double *r, double *g, double *b);

/* ── Cleanup ───────────────────────────────────────────── */

void pdfmake_cs_free(pdfmake_colorspace_t *cs);

#ifdef __cplusplus
}
#endif

#endif /* PDFMAKE_COLOR_MGMT_H */
