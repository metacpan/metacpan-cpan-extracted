MODULE = PDF::Make  PACKAGE = PDF::Make::Reader
PROTOTYPES: ENABLE

pdfmake_reader_xs_t *
new(class, parser_sv)
    char *class
    SV *parser_sv
    PREINIT:
        pdfmake_parser_xs_t *parser_xs;
        IV tmp;
    CODE:
        /* Validate parser argument */
        if (!sv_isobject(parser_sv) || !sv_derived_from(parser_sv, "PDF::Make::Parser")) {
            croak("PDF::Make::Reader: argument must be a PDF::Make::Parser");
        }
        tmp = SvIV((SV*)SvRV(parser_sv));
        parser_xs = INT2PTR(pdfmake_parser_xs_t *, tmp);

        /* Ensure parser has been run */
        if (!parser_xs->parsed) {
            pdfmake_err_t err = pdfmake_parser_run(parser_xs->parser, &parser_xs->doc);
            if (err != PDFMAKE_OK) {
                croak("PDF::Make::Reader: parse failed at offset %zu: %s",
                      pdfmake_parser_erroffset(parser_xs->parser),
                      pdfmake_parser_errmsg(parser_xs->parser));
            }
            parser_xs->parsed = 1;
        }

        Newxz(RETVAL, 1, pdfmake_reader_xs_t);
        RETVAL->reader = pdfmake_reader_new(parser_xs->parser);
        if (!RETVAL->reader) {
            Safefree(RETVAL);
            croak("PDF::Make::Reader: failed to create reader");
        }
        RETVAL->parser_sv = SvREFCNT_inc(parser_sv);

        /* Initialize reader (flatten page tree) */
        pdfmake_err_t err = pdfmake_reader_init(RETVAL->reader);
        if (err != PDFMAKE_OK) {
            const char *msg = pdfmake_reader_errmsg(RETVAL->reader);
            SvREFCNT_dec(RETVAL->parser_sv);
            pdfmake_reader_free(RETVAL->reader);
            Safefree(RETVAL);
            croak("PDF::Make::Reader: init failed: %s", msg ? msg : "unknown error");
        }
    OUTPUT:
        RETVAL

size_t
page_count(self)
    pdfmake_reader_xs_t *self
    CODE:
        RETVAL = pdfmake_reader_page_count(self->reader);
    OUTPUT:
        RETVAL

pdfmake_reader_page_xs_t *
page(self, index)
    pdfmake_reader_xs_t *self
    size_t index
    PREINIT:
        pdfmake_reader_page_t *page;
    CODE:
        page = pdfmake_reader_page_at(self->reader, index);
        if (!page) {
            croak("PDF::Make::Reader: page index %zu out of range", index);
        }
        Newxz(RETVAL, 1, pdfmake_reader_page_xs_t);
        RETVAL->page = page;
        RETVAL->reader_sv = SvREFCNT_inc(ST(0));  /* Keep reader alive */
    OUTPUT:
        RETVAL

const char *
errmsg(self)
    pdfmake_reader_xs_t *self
    CODE:
        RETVAL = pdfmake_reader_errmsg(self->reader);
        if (!RETVAL) RETVAL = "";
    OUTPUT:
        RETVAL

int
is_encrypted(self)
    pdfmake_reader_xs_t *self
    CODE:
        RETVAL = pdfmake_reader_is_encrypted(self->reader);
    OUTPUT:
        RETVAL

int
is_authenticated(self)
    pdfmake_reader_xs_t *self
    CODE:
        RETVAL = pdfmake_reader_is_authenticated(self->reader);
    OUTPUT:
        RETVAL

int
set_password(self, password)
    pdfmake_reader_xs_t *self
    const char *password
    CODE:
        RETVAL = pdfmake_reader_set_password(self->reader, password);
    OUTPUT:
        RETVAL

void
DESTROY(self)
    pdfmake_reader_xs_t *self
    CODE:
        if (self->reader)
            pdfmake_reader_free(self->reader);
        if (self->parser_sv)
            SvREFCNT_dec(self->parser_sv);
        Safefree(self);


MODULE = PDF::Make  PACKAGE = PDF::Make::Reader::Page
PROTOTYPES: ENABLE

void
media_box(self)
    pdfmake_reader_page_xs_t *self
    PREINIT:
        double box[4];
        pdfmake_err_t err;
        pdfmake_parser_xs_t *parser_xs;
        IV tmp;
    PPCODE:
        /* Get reader from wrapper */
        if (!self->reader_sv) {
            croak("PDF::Make::Reader::Page: reader reference invalid");
        }
        tmp = SvIV((SV*)SvRV(self->reader_sv));
        pdfmake_reader_xs_t *reader_xs = INT2PTR(pdfmake_reader_xs_t *, tmp);

        err = pdfmake_reader_page_media_box(reader_xs->reader, self->page, box);
        if (err != PDFMAKE_OK) {
            croak("PDF::Make::Reader::Page: failed to get media_box: %s",
                  pdfmake_reader_errmsg(reader_xs->reader));
        }
        EXTEND(SP, 4);
        PUSHs(sv_2mortal(newSVnv(box[0])));
        PUSHs(sv_2mortal(newSVnv(box[1])));
        PUSHs(sv_2mortal(newSVnv(box[2])));
        PUSHs(sv_2mortal(newSVnv(box[3])));

void
crop_box(self)
    pdfmake_reader_page_xs_t *self
    PREINIT:
        double box[4];
        pdfmake_err_t err;
        IV tmp;
    PPCODE:
        if (!self->reader_sv) {
            croak("PDF::Make::Reader::Page: reader reference invalid");
        }
        tmp = SvIV((SV*)SvRV(self->reader_sv));
        pdfmake_reader_xs_t *reader_xs = INT2PTR(pdfmake_reader_xs_t *, tmp);

        err = pdfmake_reader_page_crop_box(reader_xs->reader, self->page, box);
        if (err != PDFMAKE_OK) {
            croak("PDF::Make::Reader::Page: failed to get crop_box: %s",
                  pdfmake_reader_errmsg(reader_xs->reader));
        }
        EXTEND(SP, 4);
        PUSHs(sv_2mortal(newSVnv(box[0])));
        PUSHs(sv_2mortal(newSVnv(box[1])));
        PUSHs(sv_2mortal(newSVnv(box[2])));
        PUSHs(sv_2mortal(newSVnv(box[3])));

int
rotation(self)
    pdfmake_reader_page_xs_t *self
    PREINIT:
        IV tmp;
    CODE:
        if (!self->reader_sv) {
            croak("PDF::Make::Reader::Page: reader reference invalid");
        }
        tmp = SvIV((SV*)SvRV(self->reader_sv));
        pdfmake_reader_xs_t *reader_xs = INT2PTR(pdfmake_reader_xs_t *, tmp);

        RETVAL = pdfmake_reader_page_rotation(reader_xs->reader, self->page);
    OUTPUT:
        RETVAL

SV *
content_bytes(self)
    pdfmake_reader_page_xs_t *self
    PREINIT:
        pdfmake_buf_t buf;
        pdfmake_err_t err;
        IV tmp;
    CODE:
        if (!self->reader_sv) {
            croak("PDF::Make::Reader::Page: reader reference invalid");
        }
        tmp = SvIV((SV*)SvRV(self->reader_sv));
        pdfmake_reader_xs_t *reader_xs = INT2PTR(pdfmake_reader_xs_t *, tmp);

        pdfmake_buf_init(&buf);
        err = pdfmake_reader_page_content_bytes(reader_xs->reader, self->page, &buf);
        if (err != PDFMAKE_OK) {
            pdfmake_buf_free(&buf);
            croak("PDF::Make::Reader::Page: failed to get content_bytes: %s",
                  pdfmake_reader_errmsg(reader_xs->reader));
        }

        RETVAL = newSVpvn((const char *)pdfmake_buf_data(&buf), pdfmake_buf_len(&buf));
        pdfmake_buf_free(&buf);
    OUTPUT:
        RETVAL

void
DESTROY(self)
    pdfmake_reader_page_xs_t *self
    CODE:
        /* page is owned by reader, don't free it */
        if (self->reader_sv)
            SvREFCNT_dec(self->reader_sv);
        Safefree(self);
