/*
 * xs/bridge.xs
 * 
 * XS bindings for PDF::Make::App::Bridge
 * Performance-critical document operations
 */

#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"
#include "pdfmake_bridge.h"

/* Helper macros */
#define BRIDGE_FROM_SV(sv) ((pdfmake_bridge_t *)SvIV(SvRV(sv)))
#define CHECK_BRIDGE(b) if (!b) croak("Invalid bridge handle")

/* Progress callback wrapper */
static void xs_progress_callback(void *ctx, int current, int total) {
    dTHX;
    dSP;
    SV *cb = (SV *)ctx;
    
    if (!cb || !SvROK(cb)) return;
    
    ENTER;
    SAVETMPS;
    
    PUSHMARK(SP);
    XPUSHs(sv_2mortal(newSViv(current)));
    XPUSHs(sv_2mortal(newSViv(total)));
    PUTBACK;
    
    call_sv(cb, G_DISCARD);
    
    FREETMPS;
    LEAVE;
}

/* Error callback wrapper */
static void xs_error_callback(void *ctx, pdfmake_err_t err, const char *msg) {
    dTHX;
    dSP;
    SV *cb = (SV *)ctx;
    
    if (!cb || !SvROK(cb)) return;
    
    ENTER;
    SAVETMPS;
    
    PUSHMARK(SP);
    XPUSHs(sv_2mortal(newSViv(err)));
    XPUSHs(sv_2mortal(newSVpv(msg, 0)));
    PUTBACK;
    
    call_sv(cb, G_DISCARD);
    
    FREETMPS;
    LEAVE;
}


MODULE = PDF::Make::App::Bridge    PACKAGE = PDF::Make::App::Bridge::XS

PROTOTYPES: DISABLE

#
# Bridge lifecycle
#

SV *
_new(class)
    const char *class
CODE:
    pdfmake_bridge_t *bridge = pdfmake_bridge_new();
    if (!bridge) {
        croak("Failed to allocate bridge");
    }
    SV *sv = newSV(0);
    sv_setref_pv(sv, class, (void *)bridge);
    RETVAL = sv;
OUTPUT:
    RETVAL

void
DESTROY(self)
    SV *self
CODE:
    pdfmake_bridge_t *bridge = BRIDGE_FROM_SV(self);
    if (bridge) {
        pdfmake_bridge_free(bridge);
    }

#
# Document operations
#

int
_create(self)
    SV *self
CODE:
    pdfmake_bridge_t *bridge = BRIDGE_FROM_SV(self);
    CHECK_BRIDGE(bridge);
    pdfmake_err_t err = pdfmake_bridge_create(bridge);
    if (err != PDFMAKE_OK) {
        croak("Failed to create document: %s", pdfmake_err_string(err));
    }
    RETVAL = 1;
OUTPUT:
    RETVAL

int
_open(self, path, password = NULL)
    SV *self
    const char *path
    const char *password
CODE:
    pdfmake_bridge_t *bridge = BRIDGE_FROM_SV(self);
    CHECK_BRIDGE(bridge);
    pdfmake_err_t err = pdfmake_bridge_open(bridge, path, password);
    if (err != PDFMAKE_OK) {
        croak("Failed to open document: %s", pdfmake_err_string(err));
    }
    RETVAL = 1;
OUTPUT:
    RETVAL

int
_save(self, path = NULL)
    SV *self
    const char *path
CODE:
    pdfmake_bridge_t *bridge = BRIDGE_FROM_SV(self);
    CHECK_BRIDGE(bridge);
    pdfmake_err_t err = pdfmake_bridge_save(bridge, path);
    if (err != PDFMAKE_OK) {
        croak("Failed to save document: %s", pdfmake_err_string(err));
    }
    RETVAL = 1;
OUTPUT:
    RETVAL

int
_close(self)
    SV *self
CODE:
    pdfmake_bridge_t *bridge = BRIDGE_FROM_SV(self);
    CHECK_BRIDGE(bridge);
    pdfmake_err_t err = pdfmake_bridge_close(bridge);
    RETVAL = (err == PDFMAKE_OK) ? 1 : 0;
OUTPUT:
    RETVAL

#
# Query operations
#

int
_page_count(self)
    SV *self
CODE:
    pdfmake_bridge_t *bridge = BRIDGE_FROM_SV(self);
    CHECK_BRIDGE(bridge);
    RETVAL = pdfmake_bridge_page_count(bridge);
OUTPUT:
    RETVAL

void
_page_size(self, page)
    SV *self
    int page
PPCODE:
    pdfmake_bridge_t *bridge = BRIDGE_FROM_SV(self);
    CHECK_BRIDGE(bridge);
    double width, height;
    pdfmake_err_t err = pdfmake_bridge_page_size(bridge, page, &width, &height);
    if (err != PDFMAKE_OK) {
        croak("Failed to get page size: %s", pdfmake_err_string(err));
    }
    EXTEND(SP, 2);
    PUSHs(sv_2mortal(newSVnv(width)));
    PUSHs(sv_2mortal(newSVnv(height)));

#
# Page operations
#

int
_add_page(self, width, height, index = -1)
    SV *self
    double width
    double height
    int index
CODE:
    pdfmake_bridge_t *bridge = BRIDGE_FROM_SV(self);
    CHECK_BRIDGE(bridge);
    pdfmake_err_t err = pdfmake_bridge_add_page(bridge, width, height, index);
    if (err != PDFMAKE_OK) {
        croak("Failed to add page: %s", pdfmake_err_string(err));
    }
    RETVAL = 1;
OUTPUT:
    RETVAL

int
_delete_page(self, page)
    SV *self
    int page
CODE:
    pdfmake_bridge_t *bridge = BRIDGE_FROM_SV(self);
    CHECK_BRIDGE(bridge);
    pdfmake_err_t err = pdfmake_bridge_delete_page(bridge, page);
    if (err != PDFMAKE_OK) {
        croak("Failed to delete page: %s", pdfmake_err_string(err));
    }
    RETVAL = 1;
OUTPUT:
    RETVAL

#
# Rendering
#

SV *
_render_page(self, page, zoom = 1.0, format = 0)
    SV *self
    int page
    double zoom
    int format
CODE:
    pdfmake_bridge_t *bridge = BRIDGE_FROM_SV(self);
    CHECK_BRIDGE(bridge);
    
    pdfmake_render_opts_t opts = {
        .zoom = zoom,
        .format = format,
        .quality = 85
    };
    
    pdfmake_render_result_t result = {0};
    pdfmake_err_t err = pdfmake_bridge_render_page(bridge, page, &opts, &result);
    
    if (err != PDFMAKE_OK) {
        croak("Failed to render page: %s", pdfmake_err_string(err));
    }
    
    /* Return as hash ref */
    HV *hv = newHV();
    hv_store(hv, "data", 4, newSVpvn((char *)result.data, result.length), 0);
    hv_store(hv, "width", 5, newSViv(result.width), 0);
    hv_store(hv, "height", 6, newSViv(result.height), 0);
    hv_store(hv, "length", 6, newSVuv(result.length), 0);
    
    pdfmake_render_result_free(&result);
    
    RETVAL = newRV_noinc((SV *)hv);
OUTPUT:
    RETVAL

#
# Callbacks
#

void
_set_progress_callback(self, callback)
    SV *self
    SV *callback
CODE:
    pdfmake_bridge_t *bridge = BRIDGE_FROM_SV(self);
    CHECK_BRIDGE(bridge);
    
    SV *cb = newSVsv(callback);
    pdfmake_bridge_set_progress_callback(bridge, xs_progress_callback, (void *)cb);

void
_set_error_callback(self, callback)
    SV *self
    SV *callback
CODE:
    pdfmake_bridge_t *bridge = BRIDGE_FROM_SV(self);
    CHECK_BRIDGE(bridge);
    
    SV *cb = newSVsv(callback);
    pdfmake_bridge_set_error_callback(bridge, xs_error_callback, (void *)cb);

#
# State accessors
#

int
_is_modified(self)
    SV *self
CODE:
    pdfmake_bridge_t *bridge = BRIDGE_FROM_SV(self);
    CHECK_BRIDGE(bridge);
    RETVAL = bridge->modified;
OUTPUT:
    RETVAL

void
_set_modified(self, modified)
    SV *self
    int modified
CODE:
    pdfmake_bridge_t *bridge = BRIDGE_FROM_SV(self);
    CHECK_BRIDGE(bridge);
    bridge->modified = modified;

const char *
_get_path(self)
    SV *self
CODE:
    pdfmake_bridge_t *bridge = BRIDGE_FROM_SV(self);
    CHECK_BRIDGE(bridge);
    RETVAL = bridge->path;
OUTPUT:
    RETVAL
