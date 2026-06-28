MODULE = PDF::Make  PACKAGE = PDF::Make::Structure
PROTOTYPES: ENABLE

SV *
create_tree(class, doc)
    char *class
    pdfmake_doc_t *doc
    PREINIT:
        pdfmake_struct_tree_t *tree;
        SV *sv;
    CODE:
        PERL_UNUSED_VAR(class);
        tree = pdfmake_doc_create_struct_tree(doc);
        if (!tree)
            croak("PDF::Make::Structure: failed to create structure tree");
        sv = newSV(0);
        sv_setref_pv(sv, "PDF::Make::Structure", (void *)tree);
        RETVAL = sv;
    OUTPUT:
        RETVAL

SV *
root(self)
    SV *self
    PREINIT:
        pdfmake_struct_tree_t *tree;
        SV *sv;
    CODE:
        tree = INT2PTR(pdfmake_struct_tree_t *, SvIV(SvRV(self)));
        if (!tree->root)
            croak("PDF::Make::Structure: no root element");
        sv = newSV(0);
        sv_setref_pv(sv, "PDF::Make::StructElem", (void *)tree->root);
        RETVAL = sv;
    OUTPUT:
        RETVAL

void
map_role(self, custom, standard)
    SV *self
    const char *custom
    const char *standard
    PREINIT:
        pdfmake_struct_tree_t *tree;
    CODE:
        tree = INT2PTR(pdfmake_struct_tree_t *, SvIV(SvRV(self)));
        int type = pdfmake_struct_type_lookup(standard);
        if (type < 0)
            croak("PDF::Make::Structure: unknown standard type '%s'", standard);
        pdfmake_struct_tree_map_role(tree, custom, (pdfmake_struct_type_t)type);

void
DESTROY(self)
    SV *self
    CODE:
        SvIV_set(SvRV(self), 0);


MODULE = PDF::Make  PACKAGE = PDF::Make::StructElem
PROTOTYPES: ENABLE

SV *
add_child(self, type_name, ...)
    SV *self
    const char *type_name
    PREINIT:
        pdfmake_struct_elem_t *elem, *child;
        SV *sv;
        int type;
    CODE:
        elem = INT2PTR(pdfmake_struct_elem_t *, SvIV(SvRV(self)));
        type = pdfmake_struct_type_lookup(type_name);
        if (type >= 0) {
            child = pdfmake_struct_elem_create(NULL, (pdfmake_struct_type_t)type, elem);
        } else {
            child = pdfmake_struct_elem_create_custom(NULL, type_name, elem);
        }
        if (!child)
            croak("PDF::Make::StructElem: failed to create child");
        sv = newSV(0);
        sv_setref_pv(sv, "PDF::Make::StructElem", (void *)child);
        RETVAL = sv;
    OUTPUT:
        RETVAL

const char *
type(self)
    SV *self
    PREINIT:
        pdfmake_struct_elem_t *elem;
    CODE:
        elem = INT2PTR(pdfmake_struct_elem_t *, SvIV(SvRV(self)));
        RETVAL = elem->custom_type[0] ? elem->custom_type
               : pdfmake_struct_type_name(elem->type);
    OUTPUT:
        RETVAL

void
alt_text(self, text)
    SV *self
    const char *text
    PREINIT:
        pdfmake_struct_elem_t *elem;
    CODE:
        elem = INT2PTR(pdfmake_struct_elem_t *, SvIV(SvRV(self)));
        pdfmake_struct_elem_set_alt_text(elem, text);

void
actual_text(self, text)
    SV *self
    const char *text
    PREINIT:
        pdfmake_struct_elem_t *elem;
    CODE:
        elem = INT2PTR(pdfmake_struct_elem_t *, SvIV(SvRV(self)));
        pdfmake_struct_elem_set_actual_text(elem, text);

void
lang(self, lang_str)
    SV *self
    const char *lang_str
    PREINIT:
        pdfmake_struct_elem_t *elem;
    CODE:
        elem = INT2PTR(pdfmake_struct_elem_t *, SvIV(SvRV(self)));
        pdfmake_struct_elem_set_lang(elem, lang_str);

void
add_content(self, page, mcid)
    SV *self
    pdfmake_page_t *page
    int mcid
    PREINIT:
        pdfmake_struct_elem_t *elem;
    CODE:
        elem = INT2PTR(pdfmake_struct_elem_t *, SvIV(SvRV(self)));
        pdfmake_struct_elem_add_mcr(elem, page->page_num, mcid);

UV
child_count(self)
    SV *self
    PREINIT:
        pdfmake_struct_elem_t *elem;
    CODE:
        elem = INT2PTR(pdfmake_struct_elem_t *, SvIV(SvRV(self)));
        RETVAL = elem->child_count;
    OUTPUT:
        RETVAL

SV *
child_at(self, idx)
    SV *self
    UV idx
    PREINIT:
        pdfmake_struct_elem_t *elem;
        SV *sv;
    CODE:
        elem = INT2PTR(pdfmake_struct_elem_t *, SvIV(SvRV(self)));
        if (idx >= elem->child_count)
            XSRETURN_UNDEF;
        sv = newSV(0);
        sv_setref_pv(sv, "PDF::Make::StructElem", (void *)elem->children[idx]);
        RETVAL = sv;
    OUTPUT:
        RETVAL

void
DESTROY(self)
    SV *self
    CODE:
        SvIV_set(SvRV(self), 0);
