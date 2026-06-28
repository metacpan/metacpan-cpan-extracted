/*
 * include/pdfmake_bridge.h
 * 
 * XS bridge header for PDF::Make::App::Bridge
 * Performance-critical paths for document operations
 */

#ifndef PDFMAKE_BRIDGE_H
#define PDFMAKE_BRIDGE_H

#include <stdlib.h>
#include <string.h>
#include <stdint.h>

/* Forward declaration of the opaque document handle.
 * Use a unique guard so multiple headers can declare it independently. */
#ifndef PDFMAKE_DOC_T_DEFINED
#define PDFMAKE_DOC_T_DEFINED
typedef struct pdfmake_doc pdfmake_doc_t;
#endif

/*
 * Error codes
 */
typedef enum {
    PDFMAKE_OK = 0,
    PDFMAKE_ERR_NULL_POINTER,
    PDFMAKE_ERR_INVALID_ARG,
    PDFMAKE_ERR_FILE_NOT_FOUND,
    PDFMAKE_ERR_FILE_READ,
    PDFMAKE_ERR_FILE_WRITE,
    PDFMAKE_ERR_PARSE,
    PDFMAKE_ERR_ENCRYPT,
    PDFMAKE_ERR_MEMORY,
    PDFMAKE_ERR_INTERNAL,
} pdfmake_err_t;

/*
 * Bridge state structure
 */
typedef struct pdfmake_bridge {
    pdfmake_doc_t *doc;          /* Document handle */
    char *path;                   /* Current file path */
    int modified;                 /* Dirty flag */
    int current_page;             /* Current page index */
    double zoom;                  /* Zoom level */
    
    /* Callbacks */
    void (*on_progress)(void *ctx, int current, int total);
    void (*on_error)(void *ctx, pdfmake_err_t err, const char *msg);
    void *callback_ctx;
    
} pdfmake_bridge_t;

/*
 * Bridge lifecycle
 */
pdfmake_bridge_t *pdfmake_bridge_new(void);
void pdfmake_bridge_free(pdfmake_bridge_t *b);

/*
 * Document operations
 */
pdfmake_err_t pdfmake_bridge_create(pdfmake_bridge_t *b);
pdfmake_err_t pdfmake_bridge_open(pdfmake_bridge_t *b, const char *path, const char *password);
pdfmake_err_t pdfmake_bridge_save(pdfmake_bridge_t *b, const char *path);
pdfmake_err_t pdfmake_bridge_close(pdfmake_bridge_t *b);

/*
 * Query operations
 */
int pdfmake_bridge_page_count(pdfmake_bridge_t *b);
pdfmake_err_t pdfmake_bridge_page_size(pdfmake_bridge_t *b, int page, double *width, double *height);

/*
 * Page operations
 */
pdfmake_err_t pdfmake_bridge_add_page(pdfmake_bridge_t *b, double width, double height, int index);
pdfmake_err_t pdfmake_bridge_delete_page(pdfmake_bridge_t *b, int page);

/*
 * Rendering
 */
typedef struct pdfmake_render_opts {
    double zoom;
    int format;           /* 0=PNG, 1=JPEG */
    int quality;          /* JPEG quality 0-100 */
} pdfmake_render_opts_t;

typedef struct pdfmake_render_result {
    unsigned char *data;
    size_t length;
    int width;
    int height;
} pdfmake_render_result_t;

pdfmake_err_t pdfmake_bridge_render_page(
    pdfmake_bridge_t *b,
    int page,
    pdfmake_render_opts_t *opts,
    pdfmake_render_result_t *result
);

void pdfmake_render_result_free(pdfmake_render_result_t *result);

/*
 * Callbacks
 */
void pdfmake_bridge_set_progress_callback(
    pdfmake_bridge_t *b,
    void (*cb)(void *ctx, int current, int total),
    void *ctx
);

void pdfmake_bridge_set_error_callback(
    pdfmake_bridge_t *b,
    void (*cb)(void *ctx, pdfmake_err_t err, const char *msg),
    void *ctx
);

/*
 * Error handling
 */
const char *pdfmake_err_string(pdfmake_err_t err);

#endif /* PDFMAKE_BRIDGE_H */
