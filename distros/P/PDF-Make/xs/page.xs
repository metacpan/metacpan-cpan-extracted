MODULE = PDF::Make  PACKAGE = PDF::Make::Page
PROTOTYPES: ENABLE

int
add_font(self, name, base_font)
    pdfmake_page_t *self
    const char *name
    const char *base_font
    CODE:
        RETVAL = pdfmake_page_add_font(self, name, base_font);
        if (RETVAL < 0)
            croak("PDF::Make::Page::add_font: failed to add font %s", name);
    OUTPUT:
        RETVAL

int
add_std14_font(self, name, font_id)
    pdfmake_page_t *self
    const char *name
    int font_id
    CODE:
        RETVAL = pdfmake_page_add_std14_font(self, name, (pdfmake_std14_font_t)font_id);
        if (RETVAL < 0)
            croak("PDF::Make::Page::add_std14_font: failed to add standard font");
    OUTPUT:
        RETVAL

void
set_content(self, content)
    pdfmake_page_t *self
    SV *content
    PREINIT:
        STRLEN len;
        const char *data;
    CODE:
        data = SvPV(content, len);
        if (pdfmake_page_set_content(self, (const uint8_t*)data, len) != PDFMAKE_OK)
            croak("PDF::Make::Page::set_content: failed to set content");

void
append_content(self, content)
    pdfmake_page_t *self
    SV *content
    PREINIT:
        STRLEN len;
        const char *data;
    CODE:
        data = SvPV(content, len);
        if (pdfmake_page_append_content(self, (const uint8_t*)data, len) != PDFMAKE_OK)
            croak("PDF::Make::Page::append_content: failed");

int
add_image(self, name, img_obj_num)
    pdfmake_page_t *self
    const char *name
    UV img_obj_num
    CODE:
        RETVAL = pdfmake_page_add_image(self, name, (uint32_t)img_obj_num);
        if (RETVAL < 0)
            croak("PDF::Make::Page::add_image: failed to add image %s", name);
    OUTPUT:
        RETVAL

void
add_annot(self, annot_obj_num)
    pdfmake_page_t *self
    UV annot_obj_num
    CODE:
        if (pdfmake_page_add_annot(self, (uint32_t)annot_obj_num) != PDFMAKE_OK)
            croak("PDF::Make::Page::add_annot: failed to add annotation %u", (unsigned)annot_obj_num);

double
width(self)
    pdfmake_page_t *self
    CODE:
        RETVAL = self->width;
    OUTPUT:
        RETVAL

double
height(self)
    pdfmake_page_t *self
    CODE:
        RETVAL = self->height;
    OUTPUT:
        RETVAL

void
DESTROY(self)
    pdfmake_page_t *self
    CODE:
        /* Page is owned by document, freed when document is freed */
        PERL_UNUSED_VAR(self);

int
add_ocg(self, name, ocg_obj_num)
    pdfmake_page_t *self
    const char *name
    UV ocg_obj_num
    CODE:
        RETVAL = pdfmake_page_add_ocg(self, name, (uint32_t)ocg_obj_num);
        if (RETVAL < 0)
            croak("PDF::Make::Page::add_ocg: failed to add OCG %s", name);
    OUTPUT:
        RETVAL

BOOT:
{
    HV *stash = gv_stashpv("PDF::Make::Page", GV_ADD);
    PDFMAKE_REGISTER_GETTER(stash, "width",  pdfmake_page_t, width,  PDFMAKE_FIELD_DOUBLE);
    PDFMAKE_REGISTER_GETTER(stash, "height", pdfmake_page_t, height, PDFMAKE_FIELD_DOUBLE);

    /* Page method dispatch (returns int, not self) */
    enum { POP_ADD_FONT, POP_ADD_STD14, POP_ADD_IMAGE, POP_ADD_OCG, POP_COUNT };
    static pdfmake_chain_entry_t page_dispatch[POP_COUNT] = {
        [POP_ADD_FONT]  = { (void*)pdfmake_page_add_font,      2, {PDFMAKE_ARG_STRING, PDFMAKE_ARG_STRING}, .ret_mode=1 },
        [POP_ADD_STD14] = { (void*)pdfmake_page_add_std14_font, 2, {PDFMAKE_ARG_STRING, PDFMAKE_ARG_INT},   1 },
        [POP_ADD_IMAGE] = { (void*)pdfmake_page_add_image,     2, {PDFMAKE_ARG_STRING, PDFMAKE_ARG_INT},    1 },
        [POP_ADD_OCG]   = { (void*)pdfmake_page_add_ocg,       2, {PDFMAKE_ARG_STRING, PDFMAKE_ARG_INT},    1 },
    };
    int page_table_id = pdfmake_chain_table_count++;
    pdfmake_chain_tables[page_table_id] = page_dispatch;

    PDFMAKE_REGISTER_CHAIN(stash, "add_font",      page_table_id, POP_ADD_FONT);
    PDFMAKE_REGISTER_CHAIN(stash, "add_std14_font", page_table_id, POP_ADD_STD14);
    PDFMAKE_REGISTER_CHAIN(stash, "add_image",     page_table_id, POP_ADD_IMAGE);
    PDFMAKE_REGISTER_CHAIN(stash, "add_ocg",       page_table_id, POP_ADD_OCG);
}
