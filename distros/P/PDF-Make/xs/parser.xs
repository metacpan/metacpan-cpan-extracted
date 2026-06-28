MODULE = PDF::Make  PACKAGE = PDF::Make::Parser
PROTOTYPES: ENABLE

pdfmake_parser_xs_t *
from_bytes(class, bytes_sv, ...)
    char *class
    SV *bytes_sv
    PREINIT:
        STRLEN len;
        const char *buf;
        int i;
    CODE:
        buf = SvPV(bytes_sv, len);
        Newxz(RETVAL, 1, pdfmake_parser_xs_t);
        RETVAL->parser = pdfmake_parser_new((const uint8_t *)buf, len);
        if (!RETVAL->parser) {
            Safefree(RETVAL);
            croak("PDF::Make::Parser: failed to create parser");
        }
        RETVAL->bytes_sv = SvREFCNT_inc(bytes_sv);
        RETVAL->doc = NULL;
        RETVAL->parsed = 0;

        /* Parse keyword args: repair => 1 */
        for (i = 2; i < items - 1; i += 2) {
            const char *key = SvPV_nolen(ST(i));
            if (strEQ(key, "repair") && SvTRUE(ST(i + 1))) {
                pdfmake_parser_set_repair(RETVAL->parser, 1);
            }
        }
    OUTPUT:
        RETVAL

pdfmake_parser_xs_t *
from_file(class, path_sv, ...)
    char *class
    SV *path_sv
    PREINIT:
        const char *path;
        FILE *fp;
        long file_len;
        SV *bytes_sv;
        char *buf;
        size_t nread;
        int i;
    CODE:
        path = SvPV_nolen(path_sv);
        fp = fopen(path, "rb");
        if (!fp)
            croak("PDF::Make::Parser: cannot open '%s': %s", path, strerror(errno));

        if (fseek(fp, 0, SEEK_END) != 0) {
            fclose(fp);
            croak("PDF::Make::Parser: cannot seek '%s'", path);
        }
        file_len = ftell(fp);
        if (file_len < 0) {
            fclose(fp);
            croak("PDF::Make::Parser: cannot tell '%s'", path);
        }
        rewind(fp);

        bytes_sv = newSV(file_len);
        SvPOK_on(bytes_sv);
        SvCUR_set(bytes_sv, file_len);
        buf = SvPVX(bytes_sv);

        nread = fread(buf, 1, (size_t)file_len, fp);
        fclose(fp);
        if ((long)nread != file_len) {
            SvREFCNT_dec(bytes_sv);
            croak("PDF::Make::Parser: short read on '%s'", path);
        }

        Newxz(RETVAL, 1, pdfmake_parser_xs_t);
        RETVAL->parser = pdfmake_parser_new((const uint8_t *)buf, (size_t)file_len);
        if (!RETVAL->parser) {
            SvREFCNT_dec(bytes_sv);
            Safefree(RETVAL);
            croak("PDF::Make::Parser: failed to create parser");
        }
        RETVAL->bytes_sv = bytes_sv;  /* already has refcnt 1 from newSV */
        RETVAL->doc = NULL;
        RETVAL->parsed = 0;

        /* Parse keyword args: repair => 1 */
        for (i = 2; i < items - 1; i += 2) {
            const char *key = SvPV_nolen(ST(i));
            if (strEQ(key, "repair") && SvTRUE(ST(i + 1))) {
                pdfmake_parser_set_repair(RETVAL->parser, 1);
            }
        }
    OUTPUT:
        RETVAL

SV *
parse(self)
    pdfmake_parser_xs_t *self
    PREINIT:
        pdfmake_err_t err;
    CODE:
        if (!self->parsed) {
            err = pdfmake_parser_run(self->parser, &self->doc);
            if (err != PDFMAKE_OK) {
                croak("PDF::Make::Parser: parse failed at offset %zu: %s",
                      pdfmake_parser_erroffset(self->parser),
                      pdfmake_parser_errmsg(self->parser));
            }
            self->parsed = 1;
        }
        RETVAL = SvREFCNT_inc(ST(0));
    OUTPUT:
        RETVAL

pdfmake_doc_t *
document(self)
    pdfmake_parser_xs_t *self
    PREINIT:
        pdfmake_err_t err;
    CODE:
        if (!self->parsed) {
            err = pdfmake_parser_run(self->parser, &self->doc);
            if (err != PDFMAKE_OK) {
                croak("PDF::Make::Parser: parse failed at offset %zu: %s",
                      pdfmake_parser_erroffset(self->parser),
                      pdfmake_parser_errmsg(self->parser));
            }
            self->parsed = 1;
        }
        if (!self->doc)
            croak("PDF::Make::Parser: no document after parse");
        RETVAL = self->doc;
    OUTPUT:
        RETVAL

void
set_repair(self, enable)
    pdfmake_parser_xs_t *self
    int enable
    CODE:
        pdfmake_parser_set_repair(self->parser, enable);

UV
root_num(self)
    pdfmake_parser_xs_t *self
    CODE:
        RETVAL = self->parser->root_num;
    OUTPUT:
        RETVAL

UV
root_gen(self)
    pdfmake_parser_xs_t *self
    CODE:
        RETVAL = self->parser->root_gen;
    OUTPUT:
        RETVAL

UV
xref_size(self)
    pdfmake_parser_xs_t *self
    CODE:
        RETVAL = self->parser->xref_size;
    OUTPUT:
        RETVAL

SV *
resolve(self, num, gen = 0)
    pdfmake_parser_xs_t *self
    UV num
    UV gen
    PREINIT:
        pdfmake_ref_t ref;
        pdfmake_obj_t *obj;
        pdfmake_err_t err;
    CODE:
        if (!self->parsed) {
            err = pdfmake_parser_run(self->parser, &self->doc);
            if (err != PDFMAKE_OK) {
                croak("PDF::Make::Parser: parse failed at offset %zu: %s",
                      pdfmake_parser_erroffset(self->parser),
                      pdfmake_parser_errmsg(self->parser));
            }
            self->parsed = 1;
        }
        ref.num = (uint32_t)num;
        ref.gen = (uint16_t)gen;
        obj = pdfmake_parser_resolve(self->parser, ref);
        if (!obj) {
            RETVAL = &PL_sv_undef;
        } else {
            /* Return object kind for now - full conversion in later phase */
            RETVAL = newSViv(obj->kind);
        }
    OUTPUT:
        RETVAL

const char *
errmsg(self)
    pdfmake_parser_xs_t *self
    CODE:
        RETVAL = pdfmake_parser_errmsg(self->parser);
    OUTPUT:
        RETVAL

UV
erroffset(self)
    pdfmake_parser_xs_t *self
    CODE:
        RETVAL = pdfmake_parser_erroffset(self->parser);
    OUTPUT:
        RETVAL

void
DESTROY(self)
    pdfmake_parser_xs_t *self
    CODE:
        /* doc is owned by the parser - freed by pdfmake_parser_free */
        if (self->parser)
            pdfmake_parser_free(self->parser);
        if (self->bytes_sv)
            SvREFCNT_dec(self->bytes_sv);
        Safefree(self);

BOOT:
{
    HV *stash = gv_stashpv("PDF::Make::Parser", GV_ADD);
    PDFMAKE_REGISTER_INDIRECT_GETTER(stash, "root_num",
        pdfmake_parser_xs_t, parser, pdfmake_parser_t, root_num, PDFMAKE_FIELD_UV);
    PDFMAKE_REGISTER_INDIRECT_GETTER(stash, "root_gen",
        pdfmake_parser_xs_t, parser, pdfmake_parser_t, root_gen, PDFMAKE_FIELD_UV);
    PDFMAKE_REGISTER_INDIRECT_GETTER(stash, "xref_size",
        pdfmake_parser_xs_t, parser, pdfmake_parser_t, xref_size, PDFMAKE_FIELD_UV);
}
