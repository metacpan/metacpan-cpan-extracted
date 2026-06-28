##############################################################################
# xs/linear.xs — XS bindings for PDF linearization (Fast Web View)
##############################################################################

MODULE = PDF::Make  PACKAGE = PDF::Make::Linearization
PROTOTYPES: ENABLE

##############################################################################
# Linearization Detection
##############################################################################

int
_data_is_linearized(data_sv)
    SV *data_sv
    PREINIT:
        STRLEN len;
        const uint8_t *data;
    CODE:
        if (!SvPOK(data_sv)) {
            RETVAL = 0;
        } else {
            data = (const uint8_t *)SvPVbyte(data_sv, len);
            RETVAL = pdfmake_data_is_linearized(data, len);
        }
    OUTPUT:
        RETVAL

##############################################################################
# Document Methods
##############################################################################

MODULE = PDF::Make  PACKAGE = PDF::Make::Document
PROTOTYPES: ENABLE

int
_xs_is_linearized(doc)
    pdfmake_doc_t *doc
    CODE:
        RETVAL = pdfmake_doc_is_linearized(doc);
    OUTPUT:
        RETVAL

SV *
_xs_linear_params(doc)
    pdfmake_doc_t *doc
    PREINIT:
        pdfmake_linear_params_t params;
        pdfmake_err_t err;
        HV *hv;
    CODE:
        err = pdfmake_doc_linear_params(doc, &params);
        if (err != PDFMAKE_OK) {
            XSRETURN_UNDEF;
        }
        
        hv = newHV();
        hv_store(hv, "version", 7, newSViv(params.version), 0);
        hv_store(hv, "file_length", 11, newSVuv(params.file_length), 0);
        hv_store(hv, "hint_offset", 11, newSVuv(params.hint_offset), 0);
        hv_store(hv, "hint_length", 11, newSVuv(params.hint_length), 0);
        hv_store(hv, "first_page_obj", 14, newSVuv(params.first_page_obj), 0);
        hv_store(hv, "first_page_end", 14, newSVuv(params.first_page_end), 0);
        hv_store(hv, "page_count", 10, newSVuv(params.page_count), 0);
        hv_store(hv, "main_xref_offset", 16, newSVuv(params.main_xref_offset), 0);
        
        RETVAL = newRV_noinc((SV *)hv);
    OUTPUT:
        RETVAL

int
_xs_linearize(doc)
    pdfmake_doc_t *doc
    CODE:
        RETVAL = (pdfmake_doc_linearize(doc) == PDFMAKE_OK) ? 1 : 0;
    OUTPUT:
        RETVAL

SV *
_xs_write_linearized(doc)
    pdfmake_doc_t *doc
    PREINIT:
        pdfmake_buf_t buf;
        pdfmake_err_t err;
    CODE:
        pdfmake_buf_init(&buf);
        err = pdfmake_doc_write_linearized(doc, &buf);
        if (err != PDFMAKE_OK) {
            pdfmake_buf_free(&buf);
            croak("PDF::Make: linearized write failed: error %d", err);
        }
        RETVAL = newSVpvn((char *)pdfmake_buf_data(&buf), pdfmake_buf_len(&buf));
        pdfmake_buf_free(&buf);
    OUTPUT:
        RETVAL

int
_xs_write_linearized_to_path(doc, path)
    pdfmake_doc_t *doc
    const char *path
    CODE:
        RETVAL = (pdfmake_doc_write_linearized_to_path(doc, path) == PDFMAKE_OK) ? 1 : 0;
    OUTPUT:
        RETVAL

##############################################################################
# Stream Reader XS wrapper
##############################################################################

MODULE = PDF::Make  PACKAGE = PDF::Make::StreamReaderXS
PROTOTYPES: ENABLE

# Note: The StreamReader uses a Perl callback for fetching, so we create
# a wrapper that stores the Perl callback SV and calls it from C.

# Internal structure definition is handled in the typemap

pdfmake_stream_reader_t *
_new(class, fetch_sv)
    const char *class
    SV *fetch_sv
    PREINIT:
        SV *fetch_copy;
    CODE:
        PERL_UNUSED_VAR(class);
        
        if (!SvROK(fetch_sv) || SvTYPE(SvRV(fetch_sv)) != SVt_PVCV) {
            croak("PDF::Make::StreamReaderXS: fetch must be a code reference");
        }
        
        /* For now, return NULL - full implementation would wrap the fetch callback */
        /* This requires a trampoline function that calls back to Perl */
        RETVAL = NULL;
        croak("PDF::Make::StreamReaderXS: XS stream reader not yet fully implemented");
    OUTPUT:
        RETVAL

void
DESTROY(reader)
    pdfmake_stream_reader_t *reader
    CODE:
        if (reader) {
            pdfmake_stream_reader_free(reader);
        }

int
is_linearized(reader)
    pdfmake_stream_reader_t *reader
    CODE:
        if (!reader) {
            RETVAL = 0;
        } else {
            RETVAL = reader->is_linearized;
        }
    OUTPUT:
        RETVAL

UV
page_count(reader)
    pdfmake_stream_reader_t *reader
    CODE:
        if (!reader) {
            RETVAL = 0;
        } else {
            RETVAL = pdfmake_stream_reader_page_count(reader);
        }
    OUTPUT:
        RETVAL

int
page_available(reader, page_num)
    pdfmake_stream_reader_t *reader
    int page_num
    CODE:
        if (!reader) {
            RETVAL = 0;
        } else {
            RETVAL = pdfmake_stream_reader_page_available(reader, page_num);
        }
    OUTPUT:
        RETVAL

SV *
params(reader)
    pdfmake_stream_reader_t *reader
    PREINIT:
        HV *hv;
    CODE:
        if (!reader) {
            XSRETURN_UNDEF;
        }
        
        hv = newHV();
        hv_store(hv, "version", 7, newSViv(reader->params.version), 0);
        hv_store(hv, "file_length", 11, newSVuv(reader->params.file_length), 0);
        hv_store(hv, "hint_offset", 11, newSVuv(reader->params.hint_offset), 0);
        hv_store(hv, "hint_length", 11, newSVuv(reader->params.hint_length), 0);
        hv_store(hv, "first_page_obj", 14, newSVuv(reader->params.first_page_obj), 0);
        hv_store(hv, "first_page_end", 14, newSVuv(reader->params.first_page_end), 0);
        hv_store(hv, "page_count", 10, newSVuv(reader->params.page_count), 0);
        hv_store(hv, "main_xref_offset", 16, newSVuv(reader->params.main_xref_offset), 0);
        
        RETVAL = newRV_noinc((SV *)hv);
    OUTPUT:
        RETVAL

void
page_range(reader, page_num)
    pdfmake_stream_reader_t *reader
    int page_num
    PREINIT:
        size_t offset = 0;
        size_t length = 0;
        pdfmake_err_t err;
    PPCODE:
        if (!reader) {
            XSRETURN_EMPTY;
        }
        
        err = pdfmake_stream_reader_page_range(reader, page_num, &offset, &length);
        if (err != PDFMAKE_OK) {
            XSRETURN_EMPTY;
        }
        
        EXTEND(SP, 2);
        PUSHs(sv_2mortal(newSVuv(offset)));
        PUSHs(sv_2mortal(newSVuv(length)));

##############################################################################
# Linearization Context (low-level API)
##############################################################################

MODULE = PDF::Make  PACKAGE = PDF::Make::LinearContext
PROTOTYPES: ENABLE

pdfmake_linear_t *
_new(class, doc)
    const char *class
    pdfmake_doc_t *doc
    CODE:
        PERL_UNUSED_VAR(class);
        RETVAL = pdfmake_linear_new(doc);
        if (!RETVAL) {
            croak("PDF::Make::LinearContext: failed to create context");
        }
    OUTPUT:
        RETVAL

void
DESTROY(lin)
    pdfmake_linear_t *lin
    CODE:
        if (lin) {
            pdfmake_linear_free(lin);
        }

int
analyze(lin)
    pdfmake_linear_t *lin
    CODE:
        if (!lin) {
            RETVAL = 0;
        } else {
            RETVAL = (pdfmake_linear_analyze(lin) == PDFMAKE_OK) ? 1 : 0;
        }
    OUTPUT:
        RETVAL

int
build_hints(lin)
    pdfmake_linear_t *lin
    CODE:
        if (!lin) {
            RETVAL = 0;
        } else {
            RETVAL = (pdfmake_linear_build_hints(lin) == PDFMAKE_OK) ? 1 : 0;
        }
    OUTPUT:
        RETVAL

SV *
write(lin)
    pdfmake_linear_t *lin
    PREINIT:
        pdfmake_buf_t buf;
        pdfmake_err_t err;
    CODE:
        if (!lin) {
            croak("PDF::Make::LinearContext: NULL context");
        }
        
        pdfmake_buf_init(&buf);
        err = pdfmake_linear_write(lin, &buf);
        if (err != PDFMAKE_OK) {
            pdfmake_buf_free(&buf);
            croak("PDF::Make::LinearContext: write failed: error %d", err);
        }
        
        RETVAL = newSVpvn((char *)pdfmake_buf_data(&buf), pdfmake_buf_len(&buf));
        pdfmake_buf_free(&buf);
    OUTPUT:
        RETVAL

UV
page_count(lin)
    pdfmake_linear_t *lin
    CODE:
        if (!lin) {
            RETVAL = 0;
        } else {
            RETVAL = lin->params.page_count;
        }
    OUTPUT:
        RETVAL

UV
shared_object_count(lin)
    pdfmake_linear_t *lin
    CODE:
        if (!lin) {
            RETVAL = 0;
        } else {
            RETVAL = lin->shared_count;
        }
    OUTPUT:
        RETVAL
