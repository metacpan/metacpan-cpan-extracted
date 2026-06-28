/*
 * pdfmake_render_page.h - Page rendering pipeline
 *
 * Integrates the content stream interpreter with the render context
 * to produce rasterized page images from PDF pages.
 *
 * This is the main entry point for Chandra PDF viewer rendering.
 *
 * Reference: ISO 32000-2:2020 §8 Graphics
 */

#ifndef PDFMAKE_RENDER_PAGE_H
#define PDFMAKE_RENDER_PAGE_H

#include "pdfmake_types.h"
#include "pdfmake_render.h"
#include "pdfmake_interpreter.h"
#include "pdfmake_reader.h"

#ifdef __cplusplus
extern "C" {
#endif

/*============================================================================
 * Error codes
 *==========================================================================*/

#define PDFMAKE_ERENDER_PAGE   50   /* Page rendering error */
#define PDFMAKE_ERENDER_CONTENT 51  /* Content stream error */
#define PDFMAKE_ERENDER_RESOURCE 52 /* Resource resolution error */

/*============================================================================
 * Render options
 *==========================================================================*/

typedef enum {
    PDFMAKE_SCALE_NEAREST  = 0,   /* Nearest neighbor (fast) */
    PDFMAKE_SCALE_BILINEAR = 1,   /* Bilinear interpolation */
    PDFMAKE_SCALE_BICUBIC  = 2,   /* Bicubic interpolation (quality) */
} pdfmake_scale_mode_t;

typedef enum {
    PDFMAKE_ROTATE_0   = 0,
    PDFMAKE_ROTATE_90  = 90,
    PDFMAKE_ROTATE_180 = 180,
    PDFMAKE_ROTATE_270 = 270,
} pdfmake_rotation_t;

typedef struct pdfmake_render_opts {
    /* Resolution */
    double dpi;                     /* DPI for rendering (default 72) */
    double scale;                   /* Additional scale factor (default 1.0) */
    
    /* Quality */
    pdfmake_scale_mode_t scale_mode;  /* Image scaling mode */
    int antialias;                    /* Anti-aliasing level 0-4 */
    double flatness;                  /* Curve flattening tolerance */
    
    /* Page transform */
    pdfmake_rotation_t rotation;    /* Page rotation */
    
    /* Background */
    uint32_t background;            /* Background color (ARGB) */
    
    /* Clipping region (NULL = entire page) */
    double clip_x, clip_y;
    double clip_width, clip_height;
    int use_clip;
    
    /* Rendering flags */
    int render_text;                /* Render text (default 1) */
    int render_images;              /* Render images (default 1) */
    int render_vectors;             /* Render vector graphics (default 1) */
    int render_annotations;         /* Render annotations (default 0) */
    
    /* Debug options */
    int show_text_bounds;           /* Draw text bounding boxes */
    int show_image_bounds;          /* Draw image bounding boxes */
    int show_clip_regions;          /* Highlight clip regions */
} pdfmake_render_opts_t;

/*============================================================================
 * Page render result
 *==========================================================================*/

typedef struct pdfmake_page_render {
    /* Output pixels (ARGB format) */
    uint32_t *pixels;
    int width;
    int height;
    int stride;                     /* Bytes per row */
    
    /* Page information */
    double page_width;              /* PDF page width in points */
    double page_height;             /* PDF page height in points */
    double effective_dpi;           /* Actual DPI used */
    
    /* Statistics */
    int text_objects;               /* Number of text objects rendered */
    int path_objects;               /* Number of paths rendered */
    int image_objects;              /* Number of images rendered */
    double render_time_ms;          /* Rendering time in milliseconds */
    
    /* Error info */
    int error_count;                /* Number of non-fatal errors */
    char error_msg[256];            /* Last error message */
} pdfmake_page_render_t;

/*============================================================================
 * Render context for visitor callbacks
 *==========================================================================*/

typedef struct pdfmake_page_renderer {
    /* Core components */
    pdfmake_render_ctx_t *render;   /* Render context */
    pdfmake_interp_t *interp;       /* Content interpreter */
    pdfmake_reader_t *reader;       /* PDF reader (for resources) */
    
    /* Page being rendered */
    pdfmake_obj_t *page;
    pdfmake_obj_t *resources;
    int page_num;
    
    /* Options */
    pdfmake_render_opts_t opts;
    
    /* Page geometry */
    double media_x, media_y;
    double media_width, media_height;
    double crop_x, crop_y;
    double crop_width, crop_height;
    
    /* Transform from PDF to pixel coordinates */
    double pdf_to_pixel[6];
    
    /* Font cache */
    struct {
        uint32_t name;
        pdfmake_obj_t *font;
        /* Add decoded font metrics here */
    } font_cache[16];
    int font_cache_count;
    
    /* Image cache */
    struct {
        uint32_t name;
        pdfmake_obj_t *image;
        uint32_t *decoded_pixels;
        int width, height;
    } image_cache[32];
    int image_cache_count;
    
    /* Statistics */
    int text_count;
    int path_count;
    int image_count;
    int error_count;
    
    /* Arena for temporary allocations */
    pdfmake_arena_t *arena;
} pdfmake_page_renderer_t;

/*============================================================================
 * Options initialization
 *==========================================================================*/

/* Initialize options to defaults */
void pdfmake_render_opts_init(pdfmake_render_opts_t *opts);

/* Create options with specific DPI */
pdfmake_render_opts_t pdfmake_render_opts_dpi(double dpi);

/* Create options for thumbnail */
pdfmake_render_opts_t pdfmake_render_opts_thumbnail(int max_dim);

/* Create options for print preview */
pdfmake_render_opts_t pdfmake_render_opts_print(double dpi);

/*============================================================================
 * Page rendering
 *==========================================================================*/

/*
 * Render a page to a pixel buffer.
 *
 * pdf       - PDF document (from pdfmake_read or pdfmake_open)
 * page_num  - Page number (0-indexed)
 * opts      - Render options (NULL for defaults)
 * result    - Output result structure
 *
 * Returns PDFMAKE_OK on success.
 * Caller must free result->pixels when done.
 */
pdfmake_err_t pdfmake_render_page_to_pixels(
    pdfmake_reader_t *reader,
    int page_num,
    const pdfmake_render_opts_t *opts,
    pdfmake_page_render_t *result
);

/*
 * Render page region (for tiled rendering / lazy loading).
 *
 * region_x, region_y - Top-left of region in PDF coordinates
 * region_w, region_h - Size of region in PDF coordinates
 */
pdfmake_err_t pdfmake_render_page_region(
    pdfmake_reader_t *reader,
    int page_num,
    double region_x, double region_y,
    double region_w, double region_h,
    const pdfmake_render_opts_t *opts,
    pdfmake_page_render_t *result
);

/*
 * Free page render result (frees pixels).
 */
void pdfmake_page_render_free(pdfmake_page_render_t *result);

/*============================================================================
 * Page renderer lifecycle (for custom rendering)
 *==========================================================================*/

/*
 * Create a page renderer for rendering multiple pages.
 */
pdfmake_page_renderer_t *pdfmake_page_renderer_new(
    pdfmake_reader_t *reader,
    pdfmake_arena_t *arena
);

/*
 * Free page renderer.
 */
void pdfmake_page_renderer_free(pdfmake_page_renderer_t *renderer);

/*
 * Set render options.
 */
void pdfmake_page_renderer_set_opts(
    pdfmake_page_renderer_t *renderer,
    const pdfmake_render_opts_t *opts
);

/*
 * Render a page to the internal buffer.
 */
pdfmake_err_t pdfmake_page_renderer_render(
    pdfmake_page_renderer_t *renderer,
    int page_num
);

/*
 * Get rendered pixels (do not free, owned by renderer).
 */
const uint32_t *pdfmake_page_renderer_pixels(
    pdfmake_page_renderer_t *renderer,
    int *width, int *height
);

/*============================================================================
 * Utility functions
 *==========================================================================*/

/*
 * Get page dimensions for given DPI.
 */
void pdfmake_page_get_render_size(
    pdfmake_reader_t *reader,
    int page_num,
    double dpi,
    int *width, int *height
);

/*
 * Calculate transformation matrix from PDF to pixel coordinates.
 */
void pdfmake_page_calc_transform(
    double page_width, double page_height,
    int pixel_width, int pixel_height,
    pdfmake_rotation_t rotation,
    double matrix[6]
);

/*
 * Convert PDF point to pixel coordinate.
 */
void pdfmake_point_to_pixel(
    const double matrix[6],
    double pdf_x, double pdf_y,
    int *pixel_x, int *pixel_y
);

/*
 * Convert pixel coordinate to PDF point.
 */
void pdfmake_pixel_to_point(
    const double matrix[6],
    int pixel_x, int pixel_y,
    double *pdf_x, double *pdf_y
);

#ifdef __cplusplus
}
#endif

#endif /* PDFMAKE_RENDER_PAGE_H */
