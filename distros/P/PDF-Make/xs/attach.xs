MODULE = PDF::Make  PACKAGE = PDF::Make::Attachment
PROTOTYPES: ENABLE

SV *
attach(class, doc, ...)
    char *class
    pdfmake_doc_t *doc
    PREINIT:
        const char *name = NULL;
        const char *filename = NULL;
        const char *mime = NULL;
        const char *desc = NULL;
        const char *path = NULL;
        SV *data_sv = NULL;
        pdfmake_attachment_t *att;
        int i;
    CODE:
        PERL_UNUSED_VAR(class);
        for (i = 2; i < items - 1; i += 2) {
            const char *key = SvPV_nolen(ST(i));
            SV *val = ST(i + 1);
            if (strEQ(key, "name"))        name = SvPV_nolen(val);
            else if (strEQ(key, "filename")) filename = SvPV_nolen(val);
            else if (strEQ(key, "mime"))    mime = SvPV_nolen(val);
            else if (strEQ(key, "description")) desc = SvPV_nolen(val);
            else if (strEQ(key, "path"))   path = SvPV_nolen(val);
            else if (strEQ(key, "data"))   data_sv = val;
        }

        if (!name)
            croak("PDF::Make::Attachment: 'name' is required");

        if (path) {
            att = pdfmake_doc_attach_file(doc, name, path);
        } else if (data_sv) {
            STRLEN len;
            const uint8_t *data = (const uint8_t *)SvPV(data_sv, len);
            att = pdfmake_doc_attach(doc, name, filename, data, len, mime, desc);
        } else {
            croak("PDF::Make::Attachment: 'path' or 'data' is required");
        }

        if (!att)
            croak("PDF::Make::Attachment: failed to attach '%s'", name);

        RETVAL = sv_newmortal();
        sv_setref_pv(RETVAL, "PDF::Make::Attachment", (void *)att);
        SvREFCNT_inc(RETVAL);
    OUTPUT:
        RETVAL

const char *
name(self)
    pdfmake_attachment_t *self
    CODE:
        RETVAL = self->name;
    OUTPUT:
        RETVAL

const char *
filename(self)
    pdfmake_attachment_t *self
    CODE:
        RETVAL = self->filename;
    OUTPUT:
        RETVAL

const char *
mime_type(self)
    pdfmake_attachment_t *self
    CODE:
        RETVAL = self->mime_type;
    OUTPUT:
        RETVAL

UV
size(self)
    pdfmake_attachment_t *self
    CODE:
        RETVAL = self->data_len;
    OUTPUT:
        RETVAL

SV *
data(self)
    pdfmake_attachment_t *self
    CODE:
        if (self->data && self->data_len > 0) {
            RETVAL = newSVpvn((const char *)self->data, self->data_len);
        } else {
            RETVAL = &PL_sv_undef;
        }
    OUTPUT:
        RETVAL

void
extract_to_file(self, path)
    pdfmake_attachment_t *self
    const char *path
    CODE:
        if (pdfmake_attachment_extract_to_file(self, path) != PDFMAKE_OK)
            croak("PDF::Make::Attachment: extract failed");

UV
write_to_doc(self, doc)
    pdfmake_attachment_t *self
    pdfmake_doc_t *doc
    CODE:
        RETVAL = pdfmake_attachment_write(self, doc);
        if (RETVAL == 0)
            croak("PDF::Make::Attachment: write failed");
    OUTPUT:
        RETVAL

void
DESTROY(self)
    pdfmake_attachment_t *self
    CODE:
        /* Attachment is owned by the document (stored in doc->attachments[]).
         * Do NOT free here — the document frees its attachments in
         * pdfmake_doc_free(). Freeing here would create a dangling pointer
         * in the doc's attachment list. */
        PERL_UNUSED_VAR(self);

BOOT:
{
    HV *stash = gv_stashpv("PDF::Make::Attachment", GV_ADD);
    PDFMAKE_REGISTER_GETTER(stash, "name",      pdfmake_attachment_t, name,      PDFMAKE_FIELD_STRING);
    PDFMAKE_REGISTER_GETTER(stash, "filename",  pdfmake_attachment_t, filename,  PDFMAKE_FIELD_STRING);
    PDFMAKE_REGISTER_GETTER(stash, "mime_type", pdfmake_attachment_t, mime_type, PDFMAKE_FIELD_STRING);
    PDFMAKE_REGISTER_GETTER(stash, "size",      pdfmake_attachment_t, data_len,  PDFMAKE_FIELD_UV);
}
