MODULE = PDF::Make  PACKAGE = PDF::Make::Import
PROTOTYPES: ENABLE

pdfmake_import_ctx_t *
new(class, reader_sv, doc_sv)
    char *class
    SV *reader_sv
    SV *doc_sv
    PREINIT:
        pdfmake_reader_xs_t *reader_xs;
        pdfmake_doc_t       *doc;
        IV tmp;
    CODE:
        if (!sv_isobject(reader_sv) || !sv_derived_from(reader_sv, "PDF::Make::Reader")) {
            croak("PDF::Make::Import::new: first arg must be a PDF::Make::Reader");
        }
        if (!sv_isobject(doc_sv) || !sv_derived_from(doc_sv, "PDF::Make::Document")) {
            croak("PDF::Make::Import::new: second arg must be a PDF::Make::Document");
        }
        tmp = SvIV((SV*)SvRV(reader_sv));
        reader_xs = INT2PTR(pdfmake_reader_xs_t *, tmp);
        tmp = SvIV((SV*)SvRV(doc_sv));
        doc = INT2PTR(pdfmake_doc_t *, tmp);

        RETVAL = pdfmake_import_ctx_new(reader_xs->reader, doc);
        if (!RETVAL) {
            croak("PDF::Make::Import::new: failed to allocate context");
        }
    OUTPUT:
        RETVAL

UV
import_object(self, src_num)
    pdfmake_import_ctx_t *self
    UV src_num
    CODE:
        RETVAL = pdfmake_import_object(self, (uint32_t)src_num);
    OUTPUT:
        RETVAL

IV
import_page(self, page_index)
    pdfmake_import_ctx_t *self
    UV page_index
    PREINIT:
        pdfmake_page_t *p;
    CODE:
        p = pdfmake_doc_import_page(self, (size_t)page_index);
        RETVAL = p ? 1 : 0;
    OUTPUT:
        RETVAL

UV
import_all_pages(self)
    pdfmake_import_ctx_t *self
    CODE:
        RETVAL = (UV)pdfmake_doc_import_all_pages(self);
    OUTPUT:
        RETVAL

void
DESTROY(self)
    pdfmake_import_ctx_t *self
    CODE:
        pdfmake_import_ctx_free(self);
