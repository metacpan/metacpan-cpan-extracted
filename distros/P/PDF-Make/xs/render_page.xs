MODULE = PDF::Make::RenderPage    PACKAGE = PDF::Make::RenderPage

PROTOTYPES: DISABLE

SV *
render_page(reader_sv, page_num, opts_hv = NULL)
    SV *reader_sv
    int page_num
    HV *opts_hv
PREINIT:
    pdfmake_reader_t *reader;
    pdfmake_render_opts_t opts;
    pdfmake_page_render_t result;
    pdfmake_err_t err;
CODE:
{
    if (!sv_isobject(reader_sv)) {
        croak("Expected PDF::Make::Reader object");
    }
    
    /* Get reader pointer */
    IV tmp = SvIV(SvRV(reader_sv));
    reader = INT2PTR(pdfmake_reader_t *, tmp);
    if (!reader) {
        croak("Invalid reader object");
    }
    
    /* Convert options */
    hv_to_render_opts(aTHX_ opts_hv, &opts);
    
    /* Render page */
    err = pdfmake_render_page_to_pixels(reader, page_num, &opts, &result);
    if (err != PDFMAKE_OK) {
        croak("Failed to render page %d: error %d", page_num, (int)err);
    }
    
    /* Build result hash */
    HV *rv = newHV();
    
    /* Pixels as packed binary string */
    size_t pixel_bytes = result.width * result.height * sizeof(uint32_t);
    SV *pixels_sv = newSVpvn((char *)result.pixels, pixel_bytes);
    hv_stores(rv, "pixels", pixels_sv);
    
    /* Dimensions */
    hv_stores(rv, "width", newSViv(result.width));
    hv_stores(rv, "height", newSViv(result.height));
    hv_stores(rv, "stride", newSViv(result.stride));
    
    /* Page info */
    hv_stores(rv, "page_width", newSVnv(result.page_width));
    hv_stores(rv, "page_height", newSVnv(result.page_height));
    hv_stores(rv, "effective_dpi", newSVnv(result.effective_dpi));
    
    /* Statistics */
    hv_stores(rv, "text_objects", newSViv(result.text_objects));
    hv_stores(rv, "path_objects", newSViv(result.path_objects));
    hv_stores(rv, "image_objects", newSViv(result.image_objects));
    hv_stores(rv, "render_time_ms", newSVnv(result.render_time_ms));
    hv_stores(rv, "error_count", newSViv(result.error_count));
    
    if (result.error_count > 0) {
        hv_stores(rv, "error_msg", newSVpv(result.error_msg, 0));
    }
    
    /* Free the pixel buffer */
    pdfmake_page_render_free(&result);
    
    RETVAL = newRV_noinc((SV *)rv);
}
OUTPUT:
    RETVAL

SV *
render_page_region(reader_sv, page_num, region_x, region_y, region_w, region_h, opts_hv = NULL)
    SV *reader_sv
    int page_num
    double region_x
    double region_y
    double region_w
    double region_h
    HV *opts_hv
PREINIT:
    pdfmake_reader_t *reader;
    pdfmake_render_opts_t opts;
    pdfmake_page_render_t result;
    pdfmake_err_t err;
CODE:
{
    if (!sv_isobject(reader_sv)) {
        croak("Expected PDF::Make::Reader object");
    }
    
    IV tmp = SvIV(SvRV(reader_sv));
    reader = INT2PTR(pdfmake_reader_t *, tmp);
    if (!reader) {
        croak("Invalid reader object");
    }
    
    hv_to_render_opts(aTHX_ opts_hv, &opts);
    
    err = pdfmake_render_page_region(reader, page_num,
                                     region_x, region_y, region_w, region_h,
                                     &opts, &result);
    if (err != PDFMAKE_OK) {
        croak("Failed to render page region: error %d", (int)err);
    }
    
    HV *rv = newHV();
    
    size_t pixel_bytes = result.width * result.height * sizeof(uint32_t);
    hv_stores(rv, "pixels", newSVpvn((char *)result.pixels, pixel_bytes));
    hv_stores(rv, "width", newSViv(result.width));
    hv_stores(rv, "height", newSViv(result.height));
    hv_stores(rv, "stride", newSViv(result.stride));
    hv_stores(rv, "page_width", newSVnv(result.page_width));
    hv_stores(rv, "page_height", newSVnv(result.page_height));
    hv_stores(rv, "effective_dpi", newSVnv(result.effective_dpi));
    hv_stores(rv, "render_time_ms", newSVnv(result.render_time_ms));
    
    pdfmake_page_render_free(&result);
    
    RETVAL = newRV_noinc((SV *)rv);
}
OUTPUT:
    RETVAL

void
get_page_render_size(reader_sv, page_num, dpi)
    SV *reader_sv
    int page_num
    double dpi
PREINIT:
    pdfmake_reader_t *reader;
    int width, height;
PPCODE:
{
    if (!sv_isobject(reader_sv)) {
        croak("Expected PDF::Make::Reader object");
    }
    
    IV tmp = SvIV(SvRV(reader_sv));
    reader = INT2PTR(pdfmake_reader_t *, tmp);
    if (!reader) {
        croak("Invalid reader object");
    }
    
    pdfmake_page_get_render_size(reader, page_num, dpi, &width, &height);
    
    EXTEND(SP, 2);
    PUSHs(sv_2mortal(newSViv(width)));
    PUSHs(sv_2mortal(newSViv(height)));
}

int
SCALE_NEAREST()
CODE:
    RETVAL = PDFMAKE_SCALE_NEAREST;
OUTPUT:
    RETVAL

int
SCALE_BILINEAR()
CODE:
    RETVAL = PDFMAKE_SCALE_BILINEAR;
OUTPUT:
    RETVAL

int
SCALE_BICUBIC()
CODE:
    RETVAL = PDFMAKE_SCALE_BICUBIC;
OUTPUT:
    RETVAL

int
ROTATE_0()
CODE:
    RETVAL = PDFMAKE_ROTATE_0;
OUTPUT:
    RETVAL

int
ROTATE_90()
CODE:
    RETVAL = PDFMAKE_ROTATE_90;
OUTPUT:
    RETVAL

int
ROTATE_180()
CODE:
    RETVAL = PDFMAKE_ROTATE_180;
OUTPUT:
    RETVAL

int
ROTATE_270()
CODE:
    RETVAL = PDFMAKE_ROTATE_270;
OUTPUT:
    RETVAL

BOOT:
{
    HV *stash = gv_stashpv("PDF::Make::RenderPage", GV_ADD);
    PDFMAKE_REGISTER_CONST(stash, "SCALE_NEAREST",  PDFMAKE_SCALE_NEAREST);
    PDFMAKE_REGISTER_CONST(stash, "SCALE_BILINEAR", PDFMAKE_SCALE_BILINEAR);
    PDFMAKE_REGISTER_CONST(stash, "SCALE_BICUBIC",  PDFMAKE_SCALE_BICUBIC);
    PDFMAKE_REGISTER_CONST(stash, "ROTATE_0",       PDFMAKE_ROTATE_0);
    PDFMAKE_REGISTER_CONST(stash, "ROTATE_90",      PDFMAKE_ROTATE_90);
    PDFMAKE_REGISTER_CONST(stash, "ROTATE_180",     PDFMAKE_ROTATE_180);
    PDFMAKE_REGISTER_CONST(stash, "ROTATE_270",     PDFMAKE_ROTATE_270);
}
