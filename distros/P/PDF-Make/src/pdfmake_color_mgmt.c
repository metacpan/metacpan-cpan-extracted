/*
 * pdfmake_color_mgmt.c — Color management.
 *
 * §8.6 Color Spaces, §14.11.5 Output Intents
 */

#include "pdfmake_color_mgmt.h"
#include "pdfmake_page.h"
#include "pdfmake_filter.h"
#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <math.h>

/* ── Device color space singletons ─────────────────────── */

static pdfmake_colorspace_t _cs_gray = {
    .family = PDFMAKE_CS_DEVICE_GRAY,
    .components = 1,
    .name = "DeviceGray",
    .obj_num = 0,
};

static pdfmake_colorspace_t _cs_rgb = {
    .family = PDFMAKE_CS_DEVICE_RGB,
    .components = 3,
    .name = "DeviceRGB",
    .obj_num = 0,
};

static pdfmake_colorspace_t _cs_cmyk = {
    .family = PDFMAKE_CS_DEVICE_CMYK,
    .components = 4,
    .name = "DeviceCMYK",
    .obj_num = 0,
};

pdfmake_colorspace_t *pdfmake_cs_device_gray(void) { return &_cs_gray; }
pdfmake_colorspace_t *pdfmake_cs_device_rgb(void)  { return &_cs_rgb; }
pdfmake_colorspace_t *pdfmake_cs_device_cmyk(void) { return &_cs_cmyk; }

/* ── CIE-based ─────────────────────────────────────────── */

pdfmake_colorspace_t *pdfmake_cs_cal_gray(
    pdfmake_arena_t *arena, const double wp[3],
    const double *bp, double gamma_val)
{
    pdfmake_colorspace_t *cs = calloc(1, sizeof(*cs));
    if (!cs) return NULL;
    (void)arena;
    cs->family = PDFMAKE_CS_CAL_GRAY;
    cs->components = 1;
    memcpy(cs->white_point, wp, 3 * sizeof(double));
    if (bp) memcpy(cs->black_point, bp, 3 * sizeof(double));
    cs->gamma[0] = gamma_val;
    return cs;
}

pdfmake_colorspace_t *pdfmake_cs_cal_rgb(
    pdfmake_arena_t *arena, const double wp[3],
    const double *bp, const double gamma[3], const double matrix[9])
{
    pdfmake_colorspace_t *cs = calloc(1, sizeof(*cs));
    if (!cs) return NULL;
    (void)arena;
    cs->family = PDFMAKE_CS_CAL_RGB;
    cs->components = 3;
    memcpy(cs->white_point, wp, 3 * sizeof(double));
    if (bp) memcpy(cs->black_point, bp, 3 * sizeof(double));
    memcpy(cs->gamma, gamma, 3 * sizeof(double));
    memcpy(cs->matrix, matrix, 9 * sizeof(double));
    return cs;
}

pdfmake_colorspace_t *pdfmake_cs_lab(
    pdfmake_arena_t *arena, const double wp[3],
    const double *bp, const double range[4])
{
    pdfmake_colorspace_t *cs = calloc(1, sizeof(*cs));
    if (!cs) return NULL;
    (void)arena;
    cs->family = PDFMAKE_CS_LAB;
    cs->components = 3;
    memcpy(cs->white_point, wp, 3 * sizeof(double));
    if (bp) memcpy(cs->black_point, bp, 3 * sizeof(double));
    memcpy(cs->range, range, 4 * sizeof(double));
    return cs;
}

/* ── ICC-based ─────────────────────────────────────────── */

pdfmake_colorspace_t *pdfmake_cs_icc_from_data(
    pdfmake_arena_t *arena, const uint8_t *data, size_t len, int components)
{
    pdfmake_colorspace_t *cs;
    if (!data || len == 0) return NULL;
    (void)arena;
    cs = calloc(1, sizeof(*cs));
    if (!cs) return NULL;
    cs->family = PDFMAKE_CS_ICC_BASED;
    cs->components = components;
    cs->icc_data = malloc(len);
    if (!cs->icc_data) { free(cs); return NULL; }
    memcpy(cs->icc_data, data, len);
    cs->icc_data_len = len;
    switch (components) {
        case 1: strncpy(cs->icc_alt, "DeviceGray", sizeof(cs->icc_alt)); break;
        case 3: strncpy(cs->icc_alt, "DeviceRGB", sizeof(cs->icc_alt)); break;
        case 4: strncpy(cs->icc_alt, "DeviceCMYK", sizeof(cs->icc_alt)); break;
    }
    return cs;
}

pdfmake_colorspace_t *pdfmake_cs_icc_from_path(
    pdfmake_arena_t *arena, const char *path, int components)
{
    FILE *fp = fopen(path, "rb");
    long len;
    uint8_t *buf;
    pdfmake_colorspace_t *cs;
    if (!fp) return NULL;
    fseek(fp, 0, SEEK_END);
    len = ftell(fp);
    if (len < 0) { fclose(fp); return NULL; }
    rewind(fp);
    buf = malloc((size_t)len);
    if (!buf) { fclose(fp); return NULL; }
    fread(buf, 1, (size_t)len, fp);
    fclose(fp);
    cs = pdfmake_cs_icc_from_data(arena, buf, (size_t)len, components);
    free(buf);
    return cs;
}

/* Minimal sRGB ICC profile (D65 white point, 2.2 gamma).
 * We use CalRGB as a fallback since embedding a real ICC profile
 * would require a 3KB+ binary blob. */
pdfmake_colorspace_t *pdfmake_cs_srgb(pdfmake_arena_t *arena) {
    double wp[3] = {0.9505, 1.0, 1.089};
    double gamma[3] = {2.2, 2.2, 2.2};
    double matrix[9] = {
        0.4124, 0.2126, 0.0193,
        0.3576, 0.7152, 0.1192,
        0.1805, 0.0722, 0.9505
    };
    return pdfmake_cs_cal_rgb(arena, wp, NULL, gamma, matrix);
}

/* ── Separation ────────────────────────────────────────── */

pdfmake_colorspace_t *pdfmake_cs_separation(
    pdfmake_arena_t *arena, const char *spot_name,
    double c, double m, double y, double k)
{
    pdfmake_colorspace_t *cs;
    (void)arena;
    cs = calloc(1, sizeof(*cs));
    if (!cs) return NULL;
    cs->family = PDFMAKE_CS_SEPARATION;
    cs->components = 1;
    strncpy(cs->name, spot_name, sizeof(cs->name) - 1);
    cs->tint_cmyk[0] = c;
    cs->tint_cmyk[1] = m;
    cs->tint_cmyk[2] = y;
    cs->tint_cmyk[3] = k;
    return cs;
}

/* ── Indexed ───────────────────────────────────────────── */

pdfmake_colorspace_t *pdfmake_cs_indexed(
    pdfmake_arena_t *arena, pdfmake_colorspace_t *base,
    int max_index, const uint8_t *palette, size_t palette_len)
{
    pdfmake_colorspace_t *cs;
    (void)arena;
    cs = calloc(1, sizeof(*cs));
    if (!cs) return NULL;
    cs->family = PDFMAKE_CS_INDEXED;
    cs->components = 1;
    cs->base = base;
    cs->max_index = max_index;
    cs->palette = malloc(palette_len);
    if (!cs->palette) { free(cs); return NULL; }
    memcpy(cs->palette, palette, palette_len);
    cs->palette_len = palette_len;
    return cs;
}

/* ── Writing ───────────────────────────────────────────── */

uint32_t pdfmake_cs_write(pdfmake_colorspace_t *cs, pdfmake_doc_t *doc) {
    pdfmake_arena_t *arena;
    uint32_t k;

    if (!cs || !doc) return 0;
    if (cs->obj_num) return cs->obj_num;

    arena = pdfmake_doc_arena(doc);

    switch (cs->family) {
    case PDFMAKE_CS_DEVICE_GRAY:
    case PDFMAKE_CS_DEVICE_RGB:
    case PDFMAKE_CS_DEVICE_CMYK:
        /* Device spaces are names, not objects */
        return 0;

    case PDFMAKE_CS_CAL_GRAY: {
        pdfmake_obj_t arr = pdfmake_array_new(arena);
        pdfmake_obj_t dict;
        pdfmake_obj_t wp;
        int i;
        pdfmake_array_push(arena, &arr, pdfmake_name_cstr(arena, "CalGray"));
        dict = pdfmake_dict_new(arena);
        wp = pdfmake_array_new(arena);
        for (i = 0; i < 3; i++)
            pdfmake_array_push(arena, &wp, pdfmake_real(cs->white_point[i]));
        k = pdfmake_arena_intern_name(arena, "WhitePoint", 10);
        pdfmake_dict_set(arena, &dict, k, wp);
        k = pdfmake_arena_intern_name(arena, "Gamma", 5);
        pdfmake_dict_set(arena, &dict, k, pdfmake_real(cs->gamma[0]));
        pdfmake_array_push(arena, &arr, dict);
        cs->obj_num = pdfmake_doc_add(doc, arr);
        return cs->obj_num;
    }

    case PDFMAKE_CS_CAL_RGB: {
        pdfmake_obj_t arr = pdfmake_array_new(arena);
        pdfmake_obj_t dict;
        pdfmake_obj_t wp;
        pdfmake_obj_t gm;
        pdfmake_obj_t mx;
        int i;
        pdfmake_array_push(arena, &arr, pdfmake_name_cstr(arena, "CalRGB"));
        dict = pdfmake_dict_new(arena);
        wp = pdfmake_array_new(arena);
        gm = pdfmake_array_new(arena);
        mx = pdfmake_array_new(arena);
        for (i = 0; i < 3; i++) {
            pdfmake_array_push(arena, &wp, pdfmake_real(cs->white_point[i]));
            pdfmake_array_push(arena, &gm, pdfmake_real(cs->gamma[i]));
        }
        for (i = 0; i < 9; i++)
            pdfmake_array_push(arena, &mx, pdfmake_real(cs->matrix[i]));
        k = pdfmake_arena_intern_name(arena, "WhitePoint", 10);
        pdfmake_dict_set(arena, &dict, k, wp);
        k = pdfmake_arena_intern_name(arena, "Gamma", 5);
        pdfmake_dict_set(arena, &dict, k, gm);
        k = pdfmake_arena_intern_name(arena, "Matrix", 6);
        pdfmake_dict_set(arena, &dict, k, mx);
        pdfmake_array_push(arena, &arr, dict);
        cs->obj_num = pdfmake_doc_add(doc, arr);
        return cs->obj_num;
    }

    case PDFMAKE_CS_LAB: {
        pdfmake_obj_t arr = pdfmake_array_new(arena);
        pdfmake_obj_t dict;
        pdfmake_obj_t wp;
        pdfmake_obj_t rng;
        int i;
        pdfmake_array_push(arena, &arr, pdfmake_name_cstr(arena, "Lab"));
        dict = pdfmake_dict_new(arena);
        wp = pdfmake_array_new(arena);
        rng = pdfmake_array_new(arena);
        for (i = 0; i < 3; i++)
            pdfmake_array_push(arena, &wp, pdfmake_real(cs->white_point[i]));
        for (i = 0; i < 4; i++)
            pdfmake_array_push(arena, &rng, pdfmake_real(cs->range[i]));
        k = pdfmake_arena_intern_name(arena, "WhitePoint", 10);
        pdfmake_dict_set(arena, &dict, k, wp);
        k = pdfmake_arena_intern_name(arena, "Range", 5);
        pdfmake_dict_set(arena, &dict, k, rng);
        pdfmake_array_push(arena, &arr, dict);
        cs->obj_num = pdfmake_doc_add(doc, arr);
        return cs->obj_num;
    }

    case PDFMAKE_CS_ICC_BASED: {
        /* ICC profile as stream */
        pdfmake_obj_t stream = pdfmake_stream_new(arena);
        pdfmake_obj_t dict_obj;
        uint32_t stream_num;
        pdfmake_obj_t arr;
        pdfmake_stream_set_data(arena, &stream, cs->icc_data, cs->icc_data_len);
        dict_obj.kind = PDFMAKE_DICT;
        dict_obj.as.dict = pdfmake_stream_dict(&stream);
        k = pdfmake_arena_intern_name(arena, "N", 1);
        pdfmake_dict_set(arena, &dict_obj, k, pdfmake_int(cs->components));
        if (cs->icc_alt[0]) {
            k = pdfmake_arena_intern_name(arena, "Alternate", 9);
            pdfmake_dict_set(arena, &dict_obj, k, pdfmake_name_cstr(arena, cs->icc_alt));
        }
        k = pdfmake_arena_intern_name(arena, "Length", 6);
        pdfmake_dict_set(arena, &dict_obj, k, pdfmake_int((int64_t)cs->icc_data_len));
        stream_num = pdfmake_doc_add(doc, stream);

        arr = pdfmake_array_new(arena);
        pdfmake_array_push(arena, &arr, pdfmake_name_cstr(arena, "ICCBased"));
        pdfmake_array_push(arena, &arr, pdfmake_ref(stream_num, 0));
        cs->obj_num = pdfmake_doc_add(doc, arr);
        return cs->obj_num;
    }

    case PDFMAKE_CS_SEPARATION: {
        /* [/Separation /Name /DeviceCMYK tint_fn] */
        pdfmake_obj_t arr = pdfmake_array_new(arena);
        char fn_body[128];
        pdfmake_obj_t fn_stream;
        pdfmake_obj_t fn_dict_obj;
        pdfmake_obj_t domain;
        pdfmake_obj_t range;
        int i;
        uint32_t fn_num;
        pdfmake_array_push(arena, &arr, pdfmake_name_cstr(arena, "Separation"));
        pdfmake_array_push(arena, &arr, pdfmake_name_cstr(arena, cs->name));
        pdfmake_array_push(arena, &arr, pdfmake_name_cstr(arena, "DeviceCMYK"));

        /* Type 4 PostScript calculator function: { c m y k } scaled by tint */
        snprintf(fn_body, sizeof(fn_body),
            "{ dup %g mul exch dup %g mul exch dup %g mul exch %g mul }",
            cs->tint_cmyk[0], cs->tint_cmyk[1], cs->tint_cmyk[2], cs->tint_cmyk[3]);

        fn_stream = pdfmake_stream_new(arena);
        pdfmake_stream_set_data(arena, &fn_stream,
            (const uint8_t *)fn_body, strlen(fn_body));
        fn_dict_obj.kind = PDFMAKE_DICT;
        fn_dict_obj.as.dict = pdfmake_stream_dict(&fn_stream);
        k = pdfmake_arena_intern_name(arena, "FunctionType", 12);
        pdfmake_dict_set(arena, &fn_dict_obj, k, pdfmake_int(4));
        domain = pdfmake_array_new(arena);
        pdfmake_array_push(arena, &domain, pdfmake_real(0));
        pdfmake_array_push(arena, &domain, pdfmake_real(1));
        k = pdfmake_arena_intern_name(arena, "Domain", 6);
        pdfmake_dict_set(arena, &fn_dict_obj, k, domain);
        range = pdfmake_array_new(arena);
        for (i = 0; i < 4; i++) {
            pdfmake_array_push(arena, &range, pdfmake_real(0));
            pdfmake_array_push(arena, &range, pdfmake_real(1));
        }
        k = pdfmake_arena_intern_name(arena, "Range", 5);
        pdfmake_dict_set(arena, &fn_dict_obj, k, range);
        k = pdfmake_arena_intern_name(arena, "Length", 6);
        pdfmake_dict_set(arena, &fn_dict_obj, k, pdfmake_int((int64_t)strlen(fn_body)));

        fn_num = pdfmake_doc_add(doc, fn_stream);
        pdfmake_array_push(arena, &arr, pdfmake_ref(fn_num, 0));

        cs->obj_num = pdfmake_doc_add(doc, arr);
        return cs->obj_num;
    }

    case PDFMAKE_CS_INDEXED: {
        pdfmake_obj_t arr = pdfmake_array_new(arena);
        pdfmake_array_push(arena, &arr, pdfmake_name_cstr(arena, "Indexed"));
        /* Base color space name */
        if (cs->base) {
            const char *base_name = "DeviceRGB";
            switch (cs->base->family) {
                case PDFMAKE_CS_DEVICE_GRAY: base_name = "DeviceGray"; break;
                case PDFMAKE_CS_DEVICE_RGB:  base_name = "DeviceRGB"; break;
                case PDFMAKE_CS_DEVICE_CMYK: base_name = "DeviceCMYK"; break;
                default: break;
            }
            pdfmake_array_push(arena, &arr, pdfmake_name_cstr(arena, base_name));
        } else {
            pdfmake_array_push(arena, &arr, pdfmake_name_cstr(arena, "DeviceRGB"));
        }
        pdfmake_array_push(arena, &arr, pdfmake_int(cs->max_index));
        pdfmake_array_push(arena, &arr,
            pdfmake_hexstr(arena, cs->palette, cs->palette_len));
        cs->obj_num = pdfmake_doc_add(doc, arr);
        return cs->obj_num;
    }

    default:
        return 0;
    }
}

/* ── Output intent ─────────────────────────────────────── */

pdfmake_err_t pdfmake_doc_set_output_intent(
    pdfmake_doc_t *doc,
    pdfmake_output_intent_type_t type,
    pdfmake_colorspace_t *dest_profile,
    const char *condition,
    const char *info)
{
    pdfmake_arena_t *arena;
    uint32_t k;
    const char *subtype;
    pdfmake_obj_t intent;
    pdfmake_obj_t *catalog;
    pdfmake_obj_t intents_arr;

    if (!doc || !condition) return PDFMAKE_EINVAL;
    /* Must be called after finalize (catalog exists) */
    if (!doc->finalized || doc->root_num == 0) return PDFMAKE_EINVAL;

    arena = pdfmake_doc_arena(doc);

    switch (type) {
        case PDFMAKE_INTENT_GTS_PDFX: subtype = "GTS_PDFX"; break;
        case PDFMAKE_INTENT_GTS_PDFA: subtype = "GTS_PDFA1"; break;
        case PDFMAKE_INTENT_ISO_PDFE: subtype = "ISO_PDFE1"; break;
        default: subtype = "GTS_PDFX"; break;
    }

    intent = pdfmake_dict_new(arena);
    k = pdfmake_arena_intern_name(arena, "Type", 4);
    pdfmake_dict_set(arena, &intent, k, pdfmake_name_cstr(arena, "OutputIntent"));
    k = pdfmake_arena_intern_name(arena, "S", 1);
    pdfmake_dict_set(arena, &intent, k, pdfmake_name_cstr(arena, subtype));
    k = pdfmake_arena_intern_name(arena, "OutputConditionIdentifier", 25);
    pdfmake_dict_set(arena, &intent, k, pdfmake_str_cstr(arena, condition));
    if (info) {
        k = pdfmake_arena_intern_name(arena, "Info", 4);
        pdfmake_dict_set(arena, &intent, k, pdfmake_str_cstr(arena, info));
    }
    k = pdfmake_arena_intern_name(arena, "RegistryName", 12);
    pdfmake_dict_set(arena, &intent, k, pdfmake_str_cstr(arena, "http://www.color.org"));

    /* Write ICC profile if provided */
    if (dest_profile && dest_profile->family == PDFMAKE_CS_ICC_BASED) {
        uint32_t profile_num = pdfmake_cs_write(dest_profile, doc);
        if (profile_num > 0) {
            k = pdfmake_arena_intern_name(arena, "DestOutputProfile", 17);
            pdfmake_dict_set(arena, &intent, k, pdfmake_ref(profile_num, 0));
        }
    }

    /* /OutputIntents [intent] on catalog */
    catalog = pdfmake_doc_get(doc, doc->root_num);
    if (!catalog || catalog->kind != PDFMAKE_DICT) return PDFMAKE_EINVAL;

    intents_arr = pdfmake_array_new(arena);
    pdfmake_array_push(arena, &intents_arr, intent);
    k = pdfmake_arena_intern_name(arena, "OutputIntents", 13);
    pdfmake_dict_set(arena, catalog, k, intents_arr);

    return PDFMAKE_OK;
}

/* ── Basic conversion ──────────────────────────────────── */

void pdfmake_rgb_to_cmyk(double r, double g, double b,
                          double *c, double *m, double *y, double *k_out) {
    double k_val = 1.0 - fmax(fmax(r, g), b);
    if (k_val >= 1.0) {
        *c = 0; *m = 0; *y = 0; *k_out = 1.0;
    } else {
        *c = (1.0 - r - k_val) / (1.0 - k_val);
        *m = (1.0 - g - k_val) / (1.0 - k_val);
        *y = (1.0 - b - k_val) / (1.0 - k_val);
        *k_out = k_val;
    }
}

void pdfmake_cmyk_to_rgb(double c, double m, double y, double k,
                          double *r, double *g, double *b) {
    *r = (1.0 - c) * (1.0 - k);
    *g = (1.0 - m) * (1.0 - k);
    *b = (1.0 - y) * (1.0 - k);
}

void pdfmake_gray_to_rgb(double gray, double *r, double *g, double *b) {
    *r = *g = *b = gray;
}

int pdfmake_hex_to_rgb(const char *hex, double *r, double *g, double *b) {
    unsigned int rv, gv, bv;
    size_t len;
    if (!hex) return -1;
    if (*hex == '#') hex++;
    len = strlen(hex);
    if (len == 3) {
        if (sscanf(hex, "%1x%1x%1x", &rv, &gv, &bv) != 3) return -1;
        *r = (rv * 17) / 255.0;
        *g = (gv * 17) / 255.0;
        *b = (bv * 17) / 255.0;
    } else if (len == 6) {
        if (sscanf(hex, "%2x%2x%2x", &rv, &gv, &bv) != 3) return -1;
        *r = rv / 255.0;
        *g = gv / 255.0;
        *b = bv / 255.0;
    } else {
        return -1;
    }
    return 0;
}

/* ── Cleanup ───────────────────────────────────────────── */

void pdfmake_cs_free(pdfmake_colorspace_t *cs) {
    if (!cs) return;
    /* Don't free singletons */
    if (cs == &_cs_gray || cs == &_cs_rgb || cs == &_cs_cmyk) return;
    free(cs->icc_data);
    free(cs->palette);
    free(cs);
}
