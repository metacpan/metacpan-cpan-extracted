MODULE = PDF::Make  PACKAGE = PDF::Make::Outline
PROTOTYPES: ENABLE

const char *
title(self)
    SV *self
    PREINIT:
        pdfmake_outline_item_t *item;
    CODE:
        item = INT2PTR(pdfmake_outline_item_t *, SvIV(SvRV(self)));
        RETVAL = item->title ? item->title : "";
    OUTPUT:
        RETVAL

int
is_open(self)
    SV *self
    PREINIT:
        pdfmake_outline_item_t *item;
    CODE:
        item = INT2PTR(pdfmake_outline_item_t *, SvIV(SvRV(self)));
        RETVAL = item->open;
    OUTPUT:
        RETVAL

void
set_open(self, open)
    SV *self
    int open
    PREINIT:
        pdfmake_outline_item_t *item;
    CODE:
        item = INT2PTR(pdfmake_outline_item_t *, SvIV(SvRV(self)));
        pdfmake_outline_set_open(item, open);

int
count(self)
    SV *self
    PREINIT:
        pdfmake_outline_item_t *item;
    CODE:
        item = INT2PTR(pdfmake_outline_item_t *, SvIV(SvRV(self)));
        RETVAL = item->count;
    OUTPUT:
        RETVAL

UV
dest_page(self)
    SV *self
    PREINIT:
        pdfmake_outline_item_t *item;
    CODE:
        item = INT2PTR(pdfmake_outline_item_t *, SvIV(SvRV(self)));
        RETVAL = (UV)item->dest.page_index;
    OUTPUT:
        RETVAL

SV *
add_child(self, title, page_index, dest_type = "Fit", left = 0, top = 0, zoom = 0)
    SV *self
    const char *title
    UV page_index
    const char *dest_type
    double left
    double top
    double zoom
    PREINIT:
        pdfmake_dest_t dest;
        pdfmake_outline_item_t *parent_item, *child;
        SV *sv;
    CODE:
        parent_item = INT2PTR(pdfmake_outline_item_t *, SvIV(SvRV(self)));

        if (strEQ(dest_type, "XYZ")) {
            dest = pdfmake_dest_xyz((size_t)page_index, left, top, zoom);
        }
        else if (strEQ(dest_type, "Fit")) {
            dest = pdfmake_dest_fit((size_t)page_index);
        }
        else if (strEQ(dest_type, "FitH")) {
            dest = pdfmake_dest_fith((size_t)page_index, top);
        }
        else if (strEQ(dest_type, "FitV")) {
            dest = pdfmake_dest_fitv((size_t)page_index, left);
        }
        else if (strEQ(dest_type, "FitB")) {
            dest = pdfmake_dest_fitb((size_t)page_index);
        }
        else if (strEQ(dest_type, "FitBH")) {
            dest = pdfmake_dest_fitbh((size_t)page_index, top);
        }
        else if (strEQ(dest_type, "FitBV")) {
            dest = pdfmake_dest_fitbv((size_t)page_index, left);
        }
        else {
            dest = pdfmake_dest_fit((size_t)page_index);
        }

        child = pdfmake_outline_add_child(parent_item, title, dest);
        if (!child)
            croak("PDF::Make::Outline::add_child: failed to create child");

        sv = newSV(0);
        sv_setref_pv(sv, "PDF::Make::Outline", (void *)child);
        RETVAL = sv;
    OUTPUT:
        RETVAL

void
children(self)
    SV *self
    PPCODE:
        pdfmake_outline_item_t *parent_item = INT2PTR(pdfmake_outline_item_t *, SvIV(SvRV(self)));
        pdfmake_outline_item_t *child = parent_item->first;
        while (child) {
            SV *sv = sv_newmortal();
            sv_setref_pv(sv, "PDF::Make::Outline", (void *)child);
            XPUSHs(sv);
            child = child->next;
        }

int
has_children(self)
    SV *self
    PREINIT:
        pdfmake_outline_item_t *item;
    CODE:
        item = INT2PTR(pdfmake_outline_item_t *, SvIV(SvRV(self)));
        RETVAL = (item->first != NULL);
    OUTPUT:
        RETVAL

SV *
parent(self)
    SV *self
    PREINIT:
        pdfmake_outline_item_t *item;
        SV *sv;
    CODE:
        item = INT2PTR(pdfmake_outline_item_t *, SvIV(SvRV(self)));
        if (!item->parent)
            XSRETURN_UNDEF;
        sv = newSV(0);
        sv_setref_pv(sv, "PDF::Make::Outline", (void *)item->parent);
        RETVAL = sv;
    OUTPUT:
        RETVAL

SV *
next_sibling(self)
    SV *self
    PREINIT:
        pdfmake_outline_item_t *item;
        SV *sv;
    CODE:
        item = INT2PTR(pdfmake_outline_item_t *, SvIV(SvRV(self)));
        if (!item->next)
            XSRETURN_UNDEF;
        sv = newSV(0);
        sv_setref_pv(sv, "PDF::Make::Outline", (void *)item->next);
        RETVAL = sv;
    OUTPUT:
        RETVAL

SV *
prev_sibling(self)
    SV *self
    PREINIT:
        pdfmake_outline_item_t *item;
        SV *sv;
    CODE:
        item = INT2PTR(pdfmake_outline_item_t *, SvIV(SvRV(self)));
        if (!item->prev)
            XSRETURN_UNDEF;
        sv = newSV(0);
        sv_setref_pv(sv, "PDF::Make::Outline", (void *)item->prev);
        RETVAL = sv;
    OUTPUT:
        RETVAL

void
DESTROY(self)
    SV *self
    CODE:
        /* Item is doc-owned; zero the pointer to prevent stale access */
        SvIV_set(SvRV(self), 0);
