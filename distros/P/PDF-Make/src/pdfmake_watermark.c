/*
 * pdfmake_watermark.c — Watermarks and stamps implementation.
 *
 * Implements watermark and stamp functionality for PDF pages.
 */

#include "pdfmake_watermark.h"
#include "pdfmake_content.h"
#include "pdfmake_buf.h"
#include "pdfmake_arena.h"
#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <math.h>
#include <time.h>

#ifndef M_PI
#define M_PI 3.14159265358979323846
#endif

/* Helper for appending strings to buffer */
static void pdfmake_buf_append_str(pdfmake_buf_t *buf, const char *s)
{
    pdfmake_buf_append_cstr(buf, s);
}

/*----------------------------------------------------------------------------
 * Approximate character widths for Standard 14 fonts (simplified)
 * Real implementation would use AFM data
 *--------------------------------------------------------------------------*/

/* Average character width as fraction of font size for common fonts */
static double get_char_width_factor(const char *font_name)
{
    if (!font_name) return 0.5;
    
    /* Courier is fixed-width */
    if (strstr(font_name, "Courier")) {
        return 0.6;  /* Fixed width */
    }
    
    /* Helvetica/Arial style */
    if (strstr(font_name, "Helvetica") || strstr(font_name, "Arial")) {
        return 0.52;
    }
    
    /* Times/serif style */
    if (strstr(font_name, "Times")) {
        return 0.45;
    }
    
    /* Default */
    return 0.5;
}

/*----------------------------------------------------------------------------
 * Default options initialization
 *--------------------------------------------------------------------------*/

void pdfmake_watermark_opts_init(pdfmake_watermark_opts_t *opts)
{
    if (!opts) return;
    
    memset(opts, 0, sizeof(*opts));
    opts->position = PDFMAKE_WM_POS_CENTER;
    opts->rotation = 0.0;
    opts->opacity = 0.3;
    opts->scale = 1.0;
    opts->x_offset = 0.0;
    opts->y_offset = 0.0;
    opts->as_overlay = 0;  /* Behind content by default */
    
    opts->font_name = "Helvetica-Bold";
    opts->font_size = 72.0;
    opts->color[0] = 0.7;  /* Light gray */
    opts->color[1] = 0.7;
    opts->color[2] = 0.7;
    
    opts->tile_spacing_x = 150.0;
    opts->tile_spacing_y = 150.0;
}

void pdfmake_stamp_opts_init(pdfmake_stamp_opts_t *opts)
{
    if (!opts) return;
    
    memset(opts, 0, sizeof(*opts));
    opts->position = PDFMAKE_WM_POS_BOTTOM_CENTER;
    opts->margin_x = 36.0;  /* Half inch */
    opts->margin_y = 36.0;
    opts->font_name = "Helvetica";
    opts->font_size = 10.0;
    opts->color[0] = 0.0;  /* Black */
    opts->color[1] = 0.0;
    opts->color[2] = 0.0;
}

/*----------------------------------------------------------------------------
 * Text metrics
 *--------------------------------------------------------------------------*/

double pdfmake_text_width_approx(const char *text, const char *font_name,
                                  double font_size)
{
    double factor;
    size_t len;

    if (!text) return 0.0;
    
    factor = get_char_width_factor(font_name);
    len = strlen(text);
    
    return len * font_size * factor;
}

/*----------------------------------------------------------------------------
 * Watermark creation
 *--------------------------------------------------------------------------*/

pdfmake_watermark_t *pdfmake_watermark_text(pdfmake_doc_t *doc,
                                             const char *text,
                                             const pdfmake_watermark_opts_t *opts)
{
    pdfmake_watermark_t *wm;

    (void)doc;
    if (!text) return NULL;
    
    wm = calloc(1, sizeof(pdfmake_watermark_t));
    if (!wm) return NULL;
    
    wm->type = PDFMAKE_WM_TYPE_TEXT;
    
    /* Copy options */
    if (opts) {
        wm->opts = *opts;
    } else {
        pdfmake_watermark_opts_init(&wm->opts);
    }
    
    /* Copy text */
    wm->data.text.text = strdup(text);
    if (!wm->data.text.text) {
        free(wm);
        return NULL;
    }
    
    /* Calculate text dimensions */
    wm->data.text.text_width = pdfmake_text_width_approx(
        text, wm->opts.font_name, wm->opts.font_size);
    wm->data.text.text_height = wm->opts.font_size;
    
    return wm;
}

pdfmake_watermark_t *pdfmake_watermark_image(pdfmake_doc_t *doc,
                                              uint32_t image_obj_num,
                                              double image_width,
                                              double image_height,
                                              const pdfmake_watermark_opts_t *opts)
{
    pdfmake_watermark_t *wm;

    (void)doc;
    if (image_obj_num == 0) return NULL;
    
    wm = calloc(1, sizeof(pdfmake_watermark_t));
    if (!wm) return NULL;
    
    wm->type = PDFMAKE_WM_TYPE_IMAGE;
    
    /* Copy options */
    if (opts) {
        wm->opts = *opts;
    } else {
        pdfmake_watermark_opts_init(&wm->opts);
    }
    
    wm->data.image.image_obj = image_obj_num;
    wm->data.image.width = image_width;
    wm->data.image.height = image_height;
    
    return wm;
}

void pdfmake_watermark_free(pdfmake_watermark_t *wm)
{
    if (!wm) return;
    
    if (wm->type == PDFMAKE_WM_TYPE_TEXT && wm->data.text.text) {
        free(wm->data.text.text);
    }
    
    free(wm);
}

/*----------------------------------------------------------------------------
 * Stamp creation
 *--------------------------------------------------------------------------*/

pdfmake_stamp_t *pdfmake_stamp_text(pdfmake_doc_t *doc,
                                     const char *format,
                                     const pdfmake_stamp_opts_t *opts)
{
    pdfmake_stamp_t *stamp;

    (void)doc;
    if (!format) return NULL;
    
    stamp = calloc(1, sizeof(pdfmake_stamp_t));
    if (!stamp) return NULL;
    
    stamp->type = PDFMAKE_WM_STAMP_TEXT;
    
    /* Copy options */
    if (opts) {
        stamp->opts = *opts;
    } else {
        pdfmake_stamp_opts_init(&stamp->opts);
    }
    
    /* Copy format string */
    stamp->data.text.format = strdup(format);
    if (!stamp->data.text.format) {
        free(stamp);
        return NULL;
    }
    
    return stamp;
}

pdfmake_stamp_t *pdfmake_stamp_bates(pdfmake_doc_t *doc,
                                      const char *prefix,
                                      int start_number,
                                      int digits,
                                      const char *suffix,
                                      const pdfmake_stamp_opts_t *opts)
{
    pdfmake_stamp_t *stamp;

    (void)doc;
    
    stamp = calloc(1, sizeof(pdfmake_stamp_t));
    if (!stamp) return NULL;
    
    stamp->type = PDFMAKE_WM_STAMP_BATES;
    
    /* Copy options */
    if (opts) {
        stamp->opts = *opts;
    } else {
        pdfmake_stamp_opts_init(&stamp->opts);
    }
    
    /* Copy strings */
    stamp->data.bates.prefix = prefix ? strdup(prefix) : strdup("");
    stamp->data.bates.suffix = suffix ? strdup(suffix) : strdup("");
    stamp->data.bates.start_number = start_number;
    stamp->data.bates.digits = digits > 0 ? digits : 6;
    stamp->data.bates.current_number = start_number;
    
    if (!stamp->data.bates.prefix || !stamp->data.bates.suffix) {
        free(stamp->data.bates.prefix);
        free(stamp->data.bates.suffix);
        free(stamp);
        return NULL;
    }
    
    return stamp;
}

void pdfmake_stamp_free(pdfmake_stamp_t *stamp)
{
    if (!stamp) return;
    
    if (stamp->type == PDFMAKE_WM_STAMP_TEXT && stamp->data.text.format) {
        free(stamp->data.text.format);
    } else if (stamp->type == PDFMAKE_WM_STAMP_BATES) {
        free(stamp->data.bates.prefix);
        free(stamp->data.bates.suffix);
    }
    
    free(stamp);
}

/*----------------------------------------------------------------------------
 * Position calculations
 *--------------------------------------------------------------------------*/

void pdfmake_watermark_calc_position(const pdfmake_watermark_t *wm,
                                      double page_width,
                                      double page_height,
                                      double *out_x,
                                      double *out_y,
                                      double *out_rotation)
{
    double content_width, content_height;

    if (!wm || !out_x || !out_y || !out_rotation) return;
    
    if (wm->type == PDFMAKE_WM_TYPE_TEXT) {
        content_width = wm->data.text.text_width * wm->opts.scale;
        content_height = wm->data.text.text_height * wm->opts.scale;
    } else {
        content_width = wm->data.image.width * wm->opts.scale;
        content_height = wm->data.image.height * wm->opts.scale;
    }
    
    *out_rotation = wm->opts.rotation;
    
    switch (wm->opts.position) {
        case PDFMAKE_WM_POS_CENTER:
            *out_x = (page_width - content_width) / 2.0;
            *out_y = (page_height - content_height) / 2.0;
            break;
            
        case PDFMAKE_WM_POS_DIAGONAL:
            /* Calculate angle to span corner to corner */
            *out_rotation = atan2(page_height, page_width) * 180.0 / M_PI;
            /* Position at center */
            *out_x = page_width / 2.0;
            *out_y = page_height / 2.0;
            break;
            
        case PDFMAKE_WM_POS_TOP_LEFT:
            *out_x = wm->opts.x_offset;
            *out_y = page_height - content_height - wm->opts.y_offset;
            break;
            
        case PDFMAKE_WM_POS_TOP_CENTER:
            *out_x = (page_width - content_width) / 2.0;
            *out_y = page_height - content_height - wm->opts.y_offset;
            break;
            
        case PDFMAKE_WM_POS_TOP_RIGHT:
            *out_x = page_width - content_width - wm->opts.x_offset;
            *out_y = page_height - content_height - wm->opts.y_offset;
            break;
            
        case PDFMAKE_WM_POS_BOTTOM_LEFT:
            *out_x = wm->opts.x_offset;
            *out_y = wm->opts.y_offset;
            break;
            
        case PDFMAKE_WM_POS_BOTTOM_CENTER:
            *out_x = (page_width - content_width) / 2.0;
            *out_y = wm->opts.y_offset;
            break;
            
        case PDFMAKE_WM_POS_BOTTOM_RIGHT:
            *out_x = page_width - content_width - wm->opts.x_offset;
            *out_y = wm->opts.y_offset;
            break;
            
        case PDFMAKE_WM_POS_LEFT_CENTER:
            *out_x = wm->opts.x_offset;
            *out_y = (page_height - content_height) / 2.0;
            break;
            
        case PDFMAKE_WM_POS_RIGHT_CENTER:
            *out_x = page_width - content_width - wm->opts.x_offset;
            *out_y = (page_height - content_height) / 2.0;
            break;
            
        case PDFMAKE_WM_POS_TILE:
        case PDFMAKE_WM_POS_CUSTOM:
        default:
            *out_x = wm->opts.x_offset;
            *out_y = wm->opts.y_offset;
            break;
    }
    
    /* Apply offsets */
    *out_x += wm->opts.x_offset;
    *out_y += wm->opts.y_offset;
}

void pdfmake_stamp_calc_position(const pdfmake_stamp_t *stamp,
                                  double page_width,
                                  double page_height,
                                  double text_width,
                                  double text_height,
                                  double *out_x,
                                  double *out_y)
{
    double margin_x, margin_y;

    if (!stamp || !out_x || !out_y) return;
    
    margin_x = stamp->opts.margin_x;
    margin_y = stamp->opts.margin_y;
    
    switch (stamp->opts.position) {
        case PDFMAKE_WM_POS_TOP_LEFT:
            *out_x = margin_x;
            *out_y = page_height - margin_y - text_height;
            break;
            
        case PDFMAKE_WM_POS_TOP_CENTER:
            *out_x = (page_width - text_width) / 2.0;
            *out_y = page_height - margin_y - text_height;
            break;
            
        case PDFMAKE_WM_POS_TOP_RIGHT:
            *out_x = page_width - margin_x - text_width;
            *out_y = page_height - margin_y - text_height;
            break;
            
        case PDFMAKE_WM_POS_BOTTOM_LEFT:
            *out_x = margin_x;
            *out_y = margin_y;
            break;
            
        case PDFMAKE_WM_POS_BOTTOM_CENTER:
            *out_x = (page_width - text_width) / 2.0;
            *out_y = margin_y;
            break;
            
        case PDFMAKE_WM_POS_BOTTOM_RIGHT:
            *out_x = page_width - margin_x - text_width;
            *out_y = margin_y;
            break;
            
        case PDFMAKE_WM_POS_CENTER:
            *out_x = (page_width - text_width) / 2.0;
            *out_y = (page_height - text_height) / 2.0;
            break;
            
        case PDFMAKE_WM_POS_LEFT_CENTER:
            *out_x = margin_x;
            *out_y = (page_height - text_height) / 2.0;
            break;
            
        case PDFMAKE_WM_POS_RIGHT_CENTER:
            *out_x = page_width - margin_x - text_width;
            *out_y = (page_height - text_height) / 2.0;
            break;
            
        default:
            *out_x = margin_x;
            *out_y = margin_y;
            break;
    }
}

/*----------------------------------------------------------------------------
 * Format string expansion
 *--------------------------------------------------------------------------*/

char *pdfmake_stamp_expand_format(const char *format,
                                   int page_number,
                                   int total_pages,
                                   const char *filename)
{
    size_t out_size;
    char *output;
    char *dst;
    const char *src;
    char temp[64];
    time_t now;
    struct tm *tm_info;

    if (!format) return NULL;
    
    /* Calculate output size (generous estimate) */
    out_size = strlen(format) * 2 + 256;
    output = malloc(out_size);
    if (!output) return NULL;
    
    dst = output;
    src = format;
    
    now = time(NULL);
    tm_info = localtime(&now);
    
    while (*src && (size_t)(dst - output) < out_size - 64) {
        if (*src == '%' && *(src + 1)) {
            src++;
            switch (*src) {
                case 'p':  /* Current page number */
                    snprintf(temp, sizeof(temp), "%d", page_number);
                    strcpy(dst, temp);
                    dst += strlen(temp);
                    break;
                    
                case 'P':  /* Total pages */
                    snprintf(temp, sizeof(temp), "%d", total_pages);
                    strcpy(dst, temp);
                    dst += strlen(temp);
                    break;
                    
                case 'd':  /* Date YYYY-MM-DD */
                    strftime(temp, sizeof(temp), "%Y-%m-%d", tm_info);
                    strcpy(dst, temp);
                    dst += strlen(temp);
                    break;
                    
                case 't':  /* Time HH:MM */
                    strftime(temp, sizeof(temp), "%H:%M", tm_info);
                    strcpy(dst, temp);
                    dst += strlen(temp);
                    break;
                    
                case 'f':  /* Filename */
                    if (filename) {
                        strcpy(dst, filename);
                        dst += strlen(filename);
                    }
                    break;
                    
                case '%':  /* Literal % */
                    *dst++ = '%';
                    break;
                    
                default:
                    /* Unknown specifier, keep as-is */
                    *dst++ = '%';
                    *dst++ = *src;
                    break;
            }
            src++;
        } else {
            *dst++ = *src++;
        }
    }
    
    *dst = '\0';
    return output;
}

char *pdfmake_stamp_expand_bates(const char *prefix,
                                  int number,
                                  int digits,
                                  const char *suffix)
{
    size_t prefix_len = prefix ? strlen(prefix) : 0;
    size_t suffix_len = suffix ? strlen(suffix) : 0;
    char *output;
    char format[32];
    
    output = malloc(prefix_len + digits + suffix_len + 16);
    if (!output) return NULL;
    
    snprintf(format, sizeof(format), "%%s%%0%dd%%s", digits);
    snprintf(output, prefix_len + digits + suffix_len + 16, format,
             prefix ? prefix : "", number, suffix ? suffix : "");
    
    return output;
}

/*----------------------------------------------------------------------------
 * ExtGState for opacity
 *--------------------------------------------------------------------------*/

/*----------------------------------------------------------------------------
 * ExtGState for opacity
 *--------------------------------------------------------------------------*/

uint32_t pdfmake_doc_get_opacity_extgstate(pdfmake_doc_t *doc, double opacity)
{
    pdfmake_arena_t *arena;
    pdfmake_obj_t gs;
    uint32_t type_k, ca_k, CA_k;

    if (!doc) return 0;
    
    /* Clamp opacity */
    if (opacity < 0.0) opacity = 0.0;
    if (opacity > 1.0) opacity = 1.0;
    
    arena = pdfmake_doc_arena(doc);
    if (!arena) return 0;

    gs = pdfmake_dict_new(arena);
    if (gs.kind != PDFMAKE_DICT) return 0;

    type_k = pdfmake_arena_intern_name(arena, "Type", 4);
    ca_k   = pdfmake_arena_intern_name(arena, "ca", 2);
    CA_k   = pdfmake_arena_intern_name(arena, "CA", 2);

    pdfmake_dict_set(arena, &gs, type_k, pdfmake_name_cstr(arena, "ExtGState"));
    pdfmake_dict_set(arena, &gs, ca_k,   pdfmake_real(opacity));
    pdfmake_dict_set(arena, &gs, CA_k,   pdfmake_real(opacity));

    return pdfmake_doc_add(doc, gs);
}

/*----------------------------------------------------------------------------
 * Content generation helpers
 *--------------------------------------------------------------------------*/

/* Escape special characters in PDF string */
static void escape_pdf_string(pdfmake_buf_t *buf, const char *text)
{
    const char *p;

    pdfmake_buf_append_byte(buf, '(');
    
    for (p = text; *p; p++) {
        switch (*p) {
            case '(':
            case ')':
            case '\\':
                pdfmake_buf_append_byte(buf, '\\');
                pdfmake_buf_append_byte(buf, *p);
                break;
            default:
                pdfmake_buf_append_byte(buf, *p);
                break;
        }
    }
    
    pdfmake_buf_append_byte(buf, ')');
}

/* Generate watermark content stream */
static pdfmake_err_t generate_watermark_content(pdfmake_watermark_t *wm,
                                                 pdfmake_page_t *page,
                                                 pdfmake_buf_t *buf,
                                                 const char *gs_name,
                                                 const char *font_name,
                                                 const char *img_name)
{
    double x, y, rotation;
    double draw_r, draw_g, draw_b;
    double spacing_x, spacing_y;
    double content_width, content_height;
    double ty, tx;
    char pos[128];
    char transform[256];
    double rad, cos_r, sin_r;
    double diag_content_width;
    char text_ops[256];
    double w, h;
    char img_ops[128];

    pdfmake_watermark_calc_position(wm, page->width, page->height,
                                     &x, &y, &rotation);

    draw_r = wm->opts.color[0];
    draw_g = wm->opts.color[1];
    draw_b = wm->opts.color[2];
    
    /* Save graphics state */
    pdfmake_buf_append_str(buf, "q\n");
    
    /* Set opacity via ExtGState */
    if (gs_name) {
        pdfmake_buf_append_str(buf, "/");
        pdfmake_buf_append_str(buf, gs_name);
        pdfmake_buf_append_str(buf, " gs\n");
    }
    
    if (wm->opts.position == PDFMAKE_WM_POS_TILE) {
        /* Tile watermark across page */
        spacing_x = wm->opts.tile_spacing_x;
        spacing_y = wm->opts.tile_spacing_y;
        
        content_width = (wm->type == PDFMAKE_WM_TYPE_TEXT) ?
            wm->data.text.text_width : wm->data.image.width;
        content_height = (wm->type == PDFMAKE_WM_TYPE_TEXT) ?
            wm->data.text.text_height : wm->data.image.height;
        
        content_width *= wm->opts.scale;
        content_height *= wm->opts.scale;
        
        for (ty = 0; ty < page->height + content_height; ty += spacing_y) {
            for (tx = 0; tx < page->width + content_width; tx += spacing_x) {
                /* Position for this tile */
                if (wm->type == PDFMAKE_WM_TYPE_TEXT) {
                    /* Text watermark */
                    snprintf(pos, sizeof(pos), 
                        "BT\n"
                        "/%.50s %.2f Tf\n"
                        "%.3f %.3f %.3f rg\n"
                        "%.2f %.2f Td\n",
                        font_name, wm->opts.font_size * wm->opts.scale,
                        draw_r, draw_g, draw_b,
                        tx, ty);
                    pdfmake_buf_append_str(buf, pos);
                    escape_pdf_string(buf, wm->data.text.text);
                    pdfmake_buf_append_str(buf, " Tj\nET\n");
                } else {
                    /* Image watermark */
                    snprintf(pos, sizeof(pos),
                        "q\n"
                        "%.2f 0 0 %.2f %.2f %.2f cm\n"
                        "/%.50s Do\n"
                        "Q\n",
                        content_width, content_height, tx, ty,
                        img_name);
                    pdfmake_buf_append_str(buf, pos);
                }
            }
        }
    } else {
        /* Single watermark */
        if (wm->opts.position == PDFMAKE_WM_POS_DIAGONAL) {
            /* For diagonal: translate to center, rotate, translate back */
            rad = rotation * M_PI / 180.0;
            cos_r = cos(rad);
            sin_r = sin(rad);
            
            snprintf(transform, sizeof(transform),
                "1 0 0 1 %.2f %.2f cm\n"
                "%.4f %.4f %.4f %.4f 0 0 cm\n",
                x, y, cos_r, sin_r, -sin_r, cos_r);
            pdfmake_buf_append_str(buf, transform);
            
            /* Offset to center text */
            diag_content_width = (wm->type == PDFMAKE_WM_TYPE_TEXT) ?
                wm->data.text.text_width * wm->opts.scale :
                wm->data.image.width * wm->opts.scale;
            
            x = -diag_content_width / 2.0;
            y = 0;
        } else if (rotation != 0.0) {
            rad = rotation * M_PI / 180.0;
            cos_r = cos(rad);
            sin_r = sin(rad);
            
            snprintf(transform, sizeof(transform),
                "1 0 0 1 %.2f %.2f cm\n"
                "%.4f %.4f %.4f %.4f 0 0 cm\n",
                x, y, cos_r, sin_r, -sin_r, cos_r);
            pdfmake_buf_append_str(buf, transform);
            x = 0;
            y = 0;
        }
        
        if (wm->type == PDFMAKE_WM_TYPE_TEXT) {
            /* Text watermark */
            snprintf(text_ops, sizeof(text_ops),
                "BT\n"
                "/%.50s %.2f Tf\n"
                "%.3f %.3f %.3f rg\n"
                "%.2f %.2f Td\n",
                font_name, wm->opts.font_size * wm->opts.scale,
                draw_r, draw_g, draw_b,
                x, y);
            pdfmake_buf_append_str(buf, text_ops);
            escape_pdf_string(buf, wm->data.text.text);
            pdfmake_buf_append_str(buf, " Tj\nET\n");
        } else {
            /* Image watermark */
            w = wm->data.image.width * wm->opts.scale;
            h = wm->data.image.height * wm->opts.scale;
            
            snprintf(img_ops, sizeof(img_ops),
                "q\n"
                "%.2f 0 0 %.2f %.2f %.2f cm\n"
                "/%.50s Do\n"
                "Q\n",
                w, h, x, y, img_name);
            pdfmake_buf_append_str(buf, img_ops);
        }
    }
    
    /* Restore graphics state */
    pdfmake_buf_append_str(buf, "Q\n");
    
    return PDFMAKE_OK;
}

/* Generate stamp content stream */
static pdfmake_err_t generate_stamp_content(pdfmake_stamp_t *stamp,
                                             pdfmake_page_t *page,
                                             int page_num,
                                             int total_pages,
                                             pdfmake_buf_t *buf,
                                             const char *font_name)
{
    char *text = NULL;
    double text_width, text_height;
    double x, y;
    char ops[512];

    if (stamp->type == PDFMAKE_WM_STAMP_TEXT) {
        text = pdfmake_stamp_expand_format(stamp->data.text.format,
                                            page_num, total_pages, NULL);
    } else {
        text = pdfmake_stamp_expand_bates(stamp->data.bates.prefix,
                                           stamp->data.bates.current_number,
                                           stamp->data.bates.digits,
                                           stamp->data.bates.suffix);
        stamp->data.bates.current_number++;
    }
    
    if (!text) return PDFMAKE_ENOMEM;
    
    text_width = pdfmake_text_width_approx(text, stamp->opts.font_name,
                                                   stamp->opts.font_size);
    text_height = stamp->opts.font_size;
    
    pdfmake_stamp_calc_position(stamp, page->width, page->height,
                                 text_width, text_height, &x, &y);
    
    /* Save state, draw text, restore */
    snprintf(ops, sizeof(ops),
        "q\n"
        "BT\n"
        "/%.50s %.2f Tf\n"
        "%.3f %.3f %.3f rg\n"
        "%.2f %.2f Td\n",
        font_name, stamp->opts.font_size,
        stamp->opts.color[0], stamp->opts.color[1], stamp->opts.color[2],
        x, y);
    pdfmake_buf_append_str(buf, ops);
    escape_pdf_string(buf, text);
    pdfmake_buf_append_str(buf, " Tj\nET\nQ\n");
    
    free(text);
    return PDFMAKE_OK;
}

/*----------------------------------------------------------------------------
 * Watermark application
 *--------------------------------------------------------------------------*/

pdfmake_err_t pdfmake_page_add_watermark(pdfmake_page_t *page,
                                          pdfmake_watermark_t *wm)
{
    pdfmake_doc_t *doc;
    char gs_name[32];
    char font_res_name[32];
    char img_name[32];
    const char *base_font;
    pdfmake_buf_t buf;
    const uint8_t *wm_data;
    size_t wm_len;
    const uint8_t *old_data = NULL;
    size_t old_len = 0;
    pdfmake_obj_t *old_obj;
    pdfmake_buf_t merged;

    if (!page || !wm) return PDFMAKE_EINVAL;

    /* Fully transparent watermark: no-op. */
    if (wm->opts.opacity <= 0.0) {
        return PDFMAKE_OK;
    }
    
    doc = page->doc;
    
    gs_name[0] = '\0';
    if (wm->opts.opacity < 1.0) {
        if (wm->extgstate_num == 0) {
            wm->extgstate_num = pdfmake_doc_get_opacity_extgstate(doc, wm->opts.opacity);
        }
        if (wm->extgstate_num) {
            snprintf(gs_name, sizeof(gs_name), "GS%u", wm->extgstate_num);
            pdfmake_page_add_extgstate(page, gs_name, wm->extgstate_num);
        }
    }
    
    /* Font name for text watermarks */
    strcpy(font_res_name, "F1");
    if (wm->type == PDFMAKE_WM_TYPE_TEXT) {
        /* Add font to page resources if not present */
        base_font = wm->opts.font_name ? wm->opts.font_name : "Helvetica";
        pdfmake_page_add_font(page, font_res_name, base_font);
    }
    
    /* Image name for image watermarks */
    strcpy(img_name, "WmImg0");
    if (wm->type == PDFMAKE_WM_TYPE_IMAGE) {
        snprintf(img_name, sizeof(img_name), "WmImg%u", wm->data.image.image_obj);
        pdfmake_page_add_image(page, img_name, wm->data.image.image_obj);
    }
    
    /* Generate watermark content */
    pdfmake_buf_init(&buf);
    
    generate_watermark_content(wm, page, &buf, 
                               gs_name[0] ? gs_name : NULL,
                               font_res_name, img_name);
    
    /* Merge watermark with existing page content (overlay/underlay). */
    wm_data = pdfmake_buf_data(&buf);
    wm_len = pdfmake_buf_len(&buf);

    if (page->has_content && page->contents_num) {
        old_obj = pdfmake_doc_get(doc, page->contents_num);
        if (old_obj && old_obj->kind == PDFMAKE_STREAM && old_obj->as.stream) {
            old_data = old_obj->as.stream->raw;
            old_len = old_obj->as.stream->raw_len;
        }
    }

    if (!old_data || old_len == 0) {
        pdfmake_page_set_content(page, wm_data, wm_len);
    } else {
        pdfmake_buf_init(&merged);

        if (wm->opts.as_overlay) {
            pdfmake_buf_append(&merged, old_data, old_len);
            pdfmake_buf_append_byte(&merged, '\n');
            pdfmake_buf_append(&merged, wm_data, wm_len);
        } else {
            pdfmake_buf_append(&merged, wm_data, wm_len);
            pdfmake_buf_append_byte(&merged, '\n');
            pdfmake_buf_append(&merged, old_data, old_len);
        }

        pdfmake_page_set_content(page, pdfmake_buf_data(&merged), pdfmake_buf_len(&merged));
        pdfmake_buf_free(&merged);
    }
    
    pdfmake_buf_free(&buf);
    
    return PDFMAKE_OK;
}

pdfmake_err_t pdfmake_doc_add_watermark(pdfmake_doc_t *doc,
                                         pdfmake_watermark_t *wm)
{
    size_t page_count;
    size_t i;
    pdfmake_page_t *page;
    pdfmake_err_t err;

    if (!doc || !wm) return PDFMAKE_EINVAL;
    
    page_count = pdfmake_doc_page_count(doc);
    
    for (i = 0; i < page_count; i++) {
        page = pdfmake_doc_get_page(doc, i);
        if (page) {
            err = pdfmake_page_add_watermark(page, wm);
            if (err != PDFMAKE_OK) return err;
        }
    }
    
    return PDFMAKE_OK;
}

pdfmake_err_t pdfmake_doc_add_watermark_range(pdfmake_doc_t *doc,
                                               pdfmake_watermark_t *wm,
                                               int start_page,
                                               int end_page)
{
    size_t page_count;
    int i;
    pdfmake_page_t *page;
    pdfmake_err_t err;

    if (!doc || !wm) return PDFMAKE_EINVAL;
    
    page_count = pdfmake_doc_page_count(doc);
    
    if (start_page < 0) start_page = 0;
    if (end_page < 0 || (size_t)end_page >= page_count) {
        end_page = (int)page_count - 1;
    }
    
    for (i = start_page; i <= end_page; i++) {
        page = pdfmake_doc_get_page(doc, i);
        if (page) {
            err = pdfmake_page_add_watermark(page, wm);
            if (err != PDFMAKE_OK) return err;
        }
    }
    
    return PDFMAKE_OK;
}

/*----------------------------------------------------------------------------
 * Stamp application
 *--------------------------------------------------------------------------*/

pdfmake_err_t pdfmake_doc_add_stamp(pdfmake_doc_t *doc,
                                     pdfmake_stamp_t *stamp)
{
    size_t page_count;
    size_t i;
    pdfmake_page_t *page;
    char font_name[32];
    const char *base_font;
    pdfmake_buf_t buf;

    if (!doc || !stamp) return PDFMAKE_EINVAL;
    
    page_count = pdfmake_doc_page_count(doc);
    
    /* Reset Bates counter */
    if (stamp->type == PDFMAKE_WM_STAMP_BATES) {
        stamp->data.bates.current_number = stamp->data.bates.start_number;
    }
    
    for (i = 0; i < page_count; i++) {
        page = pdfmake_doc_get_page(doc, i);
        if (!page) continue;
        
        /* Add font to page */
        strcpy(font_name, "StampF1");
        base_font = stamp->opts.font_name ? stamp->opts.font_name : "Helvetica";
        pdfmake_page_add_font(page, font_name, base_font);
        
        /* Generate stamp content */
        pdfmake_buf_init(&buf);
        
        generate_stamp_content(stamp, page, (int)i + 1, (int)page_count,
                               &buf, font_name);
        
        /* Append to page content */
        /* Note: Simplified - would merge with existing content */
        pdfmake_page_set_content(page, pdfmake_buf_data(&buf), pdfmake_buf_len(&buf));
        
        pdfmake_buf_free(&buf);
    }
    
    return PDFMAKE_OK;
}

pdfmake_err_t pdfmake_doc_add_stamp_range(pdfmake_doc_t *doc,
                                           pdfmake_stamp_t *stamp,
                                           int start_page,
                                           int end_page)
{
    size_t page_count;
    int i;
    pdfmake_page_t *page;
    char font_name[32];
    const char *base_font;
    pdfmake_buf_t buf;

    if (!doc || !stamp) return PDFMAKE_EINVAL;
    
    page_count = pdfmake_doc_page_count(doc);
    
    if (start_page < 0) start_page = 0;
    if (end_page < 0 || (size_t)end_page >= page_count) {
        end_page = (int)page_count - 1;
    }
    
    /* Reset Bates counter */
    if (stamp->type == PDFMAKE_WM_STAMP_BATES) {
        stamp->data.bates.current_number = stamp->data.bates.start_number;
    }
    
    for (i = start_page; i <= end_page; i++) {
        page = pdfmake_doc_get_page(doc, i);
        if (!page) continue;
        
        /* Add font to page */
        strcpy(font_name, "StampF1");
        base_font = stamp->opts.font_name ? stamp->opts.font_name : "Helvetica";
        pdfmake_page_add_font(page, font_name, base_font);
        
        /* Generate stamp content */
        pdfmake_buf_init(&buf);
        
        generate_stamp_content(stamp, page, i + 1, (int)page_count,
                               &buf, font_name);
        
        /* Append to page content */
        pdfmake_page_set_content(page, pdfmake_buf_data(&buf), pdfmake_buf_len(&buf));
        
        pdfmake_buf_free(&buf);
    }
    
    return PDFMAKE_OK;
}
