MODULE = PDF::Make  PACKAGE = PDF::Make::FormPtr
PROTOTYPES: ENABLE

#===============================================================================
# Form access from document
#===============================================================================

pdfmake_form_t *
get(doc)
    pdfmake_doc_t *doc
    CODE:
        RETVAL = pdfmake_doc_get_form(doc);
        if (!RETVAL)
            XSRETURN_UNDEF;
    OUTPUT:
        RETVAL

pdfmake_form_t *
create(doc)
    pdfmake_doc_t *doc
    CODE:
        RETVAL = pdfmake_doc_create_form(doc);
        if (!RETVAL)
            croak("PDF::Make::Form::create: failed to create form");
    OUTPUT:
        RETVAL

#===============================================================================
# Form properties
#===============================================================================

void
set_need_appearances(self, need)
    pdfmake_form_t *self
    int need
    CODE:
        if (pdfmake_form_set_need_appearances(self, need) != PDFMAKE_OK)
            croak("PDF::Make::Form::set_need_appearances: failed");

size_t
field_count(self)
    pdfmake_form_t *self
    CODE:
        RETVAL = pdfmake_form_field_count(self);
    OUTPUT:
        RETVAL

pdfmake_field_t *
field_at(self, idx)
    pdfmake_form_t *self
    size_t idx
    CODE:
        RETVAL = pdfmake_form_field_at(self, idx);
        if (!RETVAL)
            XSRETURN_UNDEF;
    OUTPUT:
        RETVAL

pdfmake_field_t *
field_by_name(self, name)
    pdfmake_form_t *self
    const char *name
    CODE:
        RETVAL = pdfmake_form_field_by_name(self, name);
        if (!RETVAL)
            XSRETURN_UNDEF;
    OUTPUT:
        RETVAL

void
fields(self)
    pdfmake_form_t *self
    PPCODE:
        size_t count = pdfmake_form_field_count(self);
        for (size_t i = 0; i < count; i++) {
            pdfmake_field_t *field = pdfmake_form_field_at(self, i);
            if (field) {
                SV *sv = sv_newmortal();
                sv_setref_pv(sv, "PDF::Make::Field", field);
                XPUSHs(sv);
            }
        }

#===============================================================================
# Finalization and export
#===============================================================================

void
finalize(self)
    pdfmake_form_t *self
    CODE:
        if (pdfmake_form_finalize(self) != PDFMAKE_OK)
            croak("PDF::Make::Form::finalize: failed to finalize form");

void
flatten(self)
    pdfmake_form_t *self
    CODE:
        if (pdfmake_form_flatten(self) != PDFMAKE_OK)
            croak("PDF::Make::Form::flatten: failed to flatten form");

SV *
export_fdf(self)
    pdfmake_form_t *self
    CODE:
        pdfmake_buf_t buf;
        pdfmake_buf_init(&buf);
        if (pdfmake_form_export_fdf(self, &buf) != PDFMAKE_OK) {
            pdfmake_buf_free(&buf);
            croak("PDF::Make::Form::export_fdf: export failed");
        }
        RETVAL = newSVpvn((char *)buf.data, buf.len);
        pdfmake_buf_free(&buf);
    OUTPUT:
        RETVAL

SV *
export_xfdf(self)
    pdfmake_form_t *self
    CODE:
        pdfmake_buf_t buf;
        pdfmake_buf_init(&buf);
        if (pdfmake_form_export_xfdf(self, &buf) != PDFMAKE_OK) {
            pdfmake_buf_free(&buf);
            croak("PDF::Make::Form::export_xfdf: export failed");
        }
        RETVAL = newSVpvn((char *)buf.data, buf.len);
        pdfmake_buf_free(&buf);
    OUTPUT:
        RETVAL

void
import_fdf(self, data)
    pdfmake_form_t *self
    SV *data
    PREINIT:
        STRLEN len;
        const char *bytes;
    CODE:
        bytes = SvPV(data, len);
        if (pdfmake_form_import_fdf(self, (const uint8_t *)bytes, len) != PDFMAKE_OK)
            croak("PDF::Make::Form::import_fdf: import failed");

void
import_xfdf(self, data)
    pdfmake_form_t *self
    SV *data
    PREINIT:
        STRLEN len;
        const char *bytes;
    CODE:
        bytes = SvPV(data, len);
        if (pdfmake_form_import_xfdf(self, (const uint8_t *)bytes, len) != PDFMAKE_OK)
            croak("PDF::Make::Form::import_xfdf: import failed");

MODULE = PDF::Make  PACKAGE = PDF::Make::FieldPtr
PROTOTYPES: ENABLE

#===============================================================================
# Field builders
#===============================================================================

pdfmake_field_t *
text(doc, name, x, y, width, height)
    pdfmake_doc_t *doc
    const char *name
    double x
    double y
    double width
    double height
    PREINIT:
        pdfmake_rect_t rect;
    CODE:
        rect.x1 = x;
        rect.y1 = y;
        rect.x2 = x + width;
        rect.y2 = y + height;
        RETVAL = pdfmake_field_text(doc, name, rect);
        if (!RETVAL)
            croak("PDF::Make::Field::text: failed to create text field");
    OUTPUT:
        RETVAL

pdfmake_field_t *
checkbox(doc, name, x, y, width, height, on_value = "Yes")
    pdfmake_doc_t *doc
    const char *name
    double x
    double y
    double width
    double height
    const char *on_value
    PREINIT:
        pdfmake_rect_t rect;
    CODE:
        rect.x1 = x;
        rect.y1 = y;
        rect.x2 = x + width;
        rect.y2 = y + height;
        RETVAL = pdfmake_field_checkbox(doc, name, rect, on_value);
        if (!RETVAL)
            croak("PDF::Make::Field::checkbox: failed to create checkbox field");
    OUTPUT:
        RETVAL

pdfmake_field_t *
radio_group(doc, name)
    pdfmake_doc_t *doc
    const char *name
    CODE:
        RETVAL = pdfmake_field_radio_group(doc, name);
        if (!RETVAL)
            croak("PDF::Make::Field::radio_group: failed to create radio group");
    OUTPUT:
        RETVAL

pdfmake_field_t *
add_radio_option(group, x, y, width, height, value)
    pdfmake_field_t *group
    double x
    double y
    double width
    double height
    const char *value
    PREINIT:
        pdfmake_rect_t rect;
    CODE:
        rect.x1 = x;
        rect.y1 = y;
        rect.x2 = x + width;
        rect.y2 = y + height;
        RETVAL = pdfmake_field_add_radio_option(group, rect, value);
        if (!RETVAL)
            croak("PDF::Make::Field::add_radio_option: failed to add radio option");
    OUTPUT:
        RETVAL

pdfmake_field_t *
choice(doc, name, x, y, width, height, combo = 0)
    pdfmake_doc_t *doc
    const char *name
    double x
    double y
    double width
    double height
    int combo
    PREINIT:
        pdfmake_rect_t rect;
    CODE:
        rect.x1 = x;
        rect.y1 = y;
        rect.x2 = x + width;
        rect.y2 = y + height;
        RETVAL = pdfmake_field_choice(doc, name, rect, combo);
        if (!RETVAL)
            croak("PDF::Make::Field::choice: failed to create choice field");
    OUTPUT:
        RETVAL

pdfmake_field_t *
combo(doc, name, x, y, width, height)
    pdfmake_doc_t *doc
    const char *name
    double x
    double y
    double width
    double height
    PREINIT:
        pdfmake_rect_t rect;
    CODE:
        rect.x1 = x;
        rect.y1 = y;
        rect.x2 = x + width;
        rect.y2 = y + height;
        RETVAL = pdfmake_field_choice(doc, name, rect, 1);
        if (!RETVAL)
            croak("PDF::Make::Field::combo: failed to create combo field");
    OUTPUT:
        RETVAL

pdfmake_field_t *
listbox(doc, name, x, y, width, height)
    pdfmake_doc_t *doc
    const char *name
    double x
    double y
    double width
    double height
    PREINIT:
        pdfmake_rect_t rect;
    CODE:
        rect.x1 = x;
        rect.y1 = y;
        rect.x2 = x + width;
        rect.y2 = y + height;
        RETVAL = pdfmake_field_choice(doc, name, rect, 0);
        if (!RETVAL)
            croak("PDF::Make::Field::listbox: failed to create listbox field");
    OUTPUT:
        RETVAL

pdfmake_field_t *
button(doc, name, x, y, width, height, caption)
    pdfmake_doc_t *doc
    const char *name
    double x
    double y
    double width
    double height
    const char *caption
    PREINIT:
        pdfmake_rect_t rect;
    CODE:
        rect.x1 = x;
        rect.y1 = y;
        rect.x2 = x + width;
        rect.y2 = y + height;
        RETVAL = pdfmake_field_button(doc, name, rect, caption);
        if (!RETVAL)
            croak("PDF::Make::Field::button: failed to create button field");
    OUTPUT:
        RETVAL

pdfmake_field_t *
signature(doc, name, x, y, width, height)
    pdfmake_doc_t *doc
    const char *name
    double x
    double y
    double width
    double height
    PREINIT:
        pdfmake_rect_t rect;
    CODE:
        rect.x1 = x;
        rect.y1 = y;
        rect.x2 = x + width;
        rect.y2 = y + height;
        RETVAL = pdfmake_field_signature(doc, name, rect);
        if (!RETVAL)
            croak("PDF::Make::Field::signature: failed to create signature field");
    OUTPUT:
        RETVAL

#===============================================================================
# Field properties (getters)
#===============================================================================

const char *
type(self)
    pdfmake_field_t *self
    CODE:
        pdfmake_field_type_t ft = pdfmake_field_type(self);
        switch (ft) {
            case PDFMAKE_FIELD_TEXT:      RETVAL = "text"; break;
            case PDFMAKE_FIELD_BUTTON:    RETVAL = "button"; break;
            case PDFMAKE_FIELD_CHOICE:    RETVAL = "choice"; break;
            case PDFMAKE_FIELD_SIGNATURE: RETVAL = "signature"; break;
            default:                      RETVAL = "unknown"; break;
        }
    OUTPUT:
        RETVAL

const char *
name(self)
    pdfmake_field_t *self
    CODE:
        RETVAL = pdfmake_field_name(self);
        if (!RETVAL) RETVAL = "";
    OUTPUT:
        RETVAL

const char *
full_name(self)
    pdfmake_field_t *self
    CODE:
        RETVAL = pdfmake_field_full_name(self);
        if (!RETVAL) RETVAL = "";
    OUTPUT:
        RETVAL

SV *
value(self, ...)
    pdfmake_field_t *self
    CODE:
        if (items > 1) {
            const char *val = SvPV_nolen(ST(1));
            if (pdfmake_field_set_value(self, val) != PDFMAKE_OK)
                croak("PDF::Make::Field::value: failed to set value");
            RETVAL = ST(1);
            SvREFCNT_inc(RETVAL);
        } else {
            const char *val = pdfmake_field_value(self);
            RETVAL = val ? newSVpv(val, 0) : &PL_sv_undef;
        }
    OUTPUT:
        RETVAL

void
set_value(self, value)
    pdfmake_field_t *self
    const char *value
    CODE:
        if (pdfmake_field_set_value(self, value) != PDFMAKE_OK)
            croak("PDF::Make::Field::set_value: failed to set value");

void
set_default_value(self, value)
    pdfmake_field_t *self
    const char *value
    CODE:
        if (pdfmake_field_set_default_value(self, value) != PDFMAKE_OK)
            croak("PDF::Make::Field::set_default_value: failed to set default value");

#===============================================================================
# Field flags
#===============================================================================

UV
flags(self)
    pdfmake_field_t *self
    CODE:
        RETVAL = pdfmake_field_flags(self);
    OUTPUT:
        RETVAL

void
set_flags(self, flags)
    pdfmake_field_t *self
    UV flags
    CODE:
        if (pdfmake_field_set_flags(self, (uint32_t)flags) != PDFMAKE_OK)
            croak("PDF::Make::Field::set_flags: failed");

void
add_flags(self, flags)
    pdfmake_field_t *self
    UV flags
    CODE:
        if (pdfmake_field_add_flags(self, (uint32_t)flags) != PDFMAKE_OK)
            croak("PDF::Make::Field::add_flags: failed");

void
clear_flags(self, flags)
    pdfmake_field_t *self
    UV flags
    CODE:
        if (pdfmake_field_clear_flags(self, (uint32_t)flags) != PDFMAKE_OK)
            croak("PDF::Make::Field::clear_flags: failed");

void
readonly(self, val = 1)
    pdfmake_field_t *self
    int val
    CODE:
        if (val)
            pdfmake_field_add_flags(self, PDFMAKE_FF_READONLY);
        else
            pdfmake_field_clear_flags(self, PDFMAKE_FF_READONLY);

void
required(self, val = 1)
    pdfmake_field_t *self
    int val
    CODE:
        if (val)
            pdfmake_field_add_flags(self, PDFMAKE_FF_REQUIRED);
        else
            pdfmake_field_clear_flags(self, PDFMAKE_FF_REQUIRED);

void
noexport(self, val = 1)
    pdfmake_field_t *self
    int val
    CODE:
        if (val)
            pdfmake_field_add_flags(self, PDFMAKE_FF_NOEXPORT);
        else
            pdfmake_field_clear_flags(self, PDFMAKE_FF_NOEXPORT);

void
multiline(self, val = 1)
    pdfmake_field_t *self
    int val
    CODE:
        if (val)
            pdfmake_field_add_flags(self, PDFMAKE_FF_MULTILINE);
        else
            pdfmake_field_clear_flags(self, PDFMAKE_FF_MULTILINE);

void
password(self, val = 1)
    pdfmake_field_t *self
    int val
    CODE:
        if (val)
            pdfmake_field_add_flags(self, PDFMAKE_FF_PASSWORD);
        else
            pdfmake_field_clear_flags(self, PDFMAKE_FF_PASSWORD);

int
is_readonly(self)
    pdfmake_field_t *self
    CODE:
        RETVAL = (pdfmake_field_flags(self) & PDFMAKE_FF_READONLY) ? 1 : 0;
    OUTPUT:
        RETVAL

int
is_required(self)
    pdfmake_field_t *self
    CODE:
        RETVAL = (pdfmake_field_flags(self) & PDFMAKE_FF_REQUIRED) ? 1 : 0;
    OUTPUT:
        RETVAL

#===============================================================================
# Appearance settings
#===============================================================================

void
set_da(self, da)
    pdfmake_field_t *self
    const char *da
    CODE:
        if (pdfmake_field_set_da(self, da) != PDFMAKE_OK)
            croak("PDF::Make::Field::set_da: failed");

void
set_quadding(self, q)
    pdfmake_field_t *self
    int q
    CODE:
        if (pdfmake_field_set_quadding(self, (pdfmake_quadding_t)q) != PDFMAKE_OK)
            croak("PDF::Make::Field::set_quadding: failed");

void
align_left(self)
    pdfmake_field_t *self
    CODE:
        pdfmake_field_set_quadding(self, PDFMAKE_QUADDING_LEFT);

void
align_center(self)
    pdfmake_field_t *self
    CODE:
        pdfmake_field_set_quadding(self, PDFMAKE_QUADDING_CENTER);

void
align_right(self)
    pdfmake_field_t *self
    CODE:
        pdfmake_field_set_quadding(self, PDFMAKE_QUADDING_RIGHT);

void
set_max_len(self, max_len)
    pdfmake_field_t *self
    int max_len
    CODE:
        if (pdfmake_field_set_max_len(self, max_len) != PDFMAKE_OK)
            croak("PDF::Make::Field::set_max_len: failed");

#===============================================================================
# Choice field options
#===============================================================================

size_t
option_count(self)
    pdfmake_field_t *self
    CODE:
        RETVAL = pdfmake_field_option_count(self);
    OUTPUT:
        RETVAL

void
add_option(self, display, export_val = NULL)
    pdfmake_field_t *self
    const char *display
    const char *export_val
    CODE:
        if (pdfmake_field_add_option(self, display, export_val) != PDFMAKE_OK)
            croak("PDF::Make::Field::add_option: failed to add option");

void
options(self)
    pdfmake_field_t *self
    PPCODE:
        size_t count = pdfmake_field_option_count(self);
        for (size_t i = 0; i < count; i++) {
            const char *display = pdfmake_field_option_display(self, i);
            const char *export_val = pdfmake_field_option_export(self, i);
            HV *opt = newHV();
            if (display)
                hv_store(opt, "display", 7, newSVpv(display, 0), 0);
            if (export_val)
                hv_store(opt, "export", 6, newSVpv(export_val, 0), 0);
            XPUSHs(sv_2mortal(newRV_noinc((SV *)opt)));
        }

#===============================================================================
# Field-page association
#===============================================================================

void
add_to_page(self, page)
    pdfmake_field_t *self
    pdfmake_page_t *page
    CODE:
        if (pdfmake_page_add_field(page, self) != PDFMAKE_OK)
            croak("PDF::Make::Field::add_to_page: failed to add field to page");

#===============================================================================
# Button actions
#===============================================================================

void
set_submit_url(self, url)
    pdfmake_field_t *self
    const char *url
    PREINIT:
        size_t len;
        char *copy;
    CODE:
        len = strlen(url);
        copy = (char *)pdfmake_arena_alloc(self->doc->arena, len + 1);
        memcpy(copy, url, len + 1);
        self->action_url = copy;

void
set_uri_action(self, uri)
    pdfmake_field_t *self
    const char *uri
    PREINIT:
        size_t len;
        char *copy;
    CODE:
        len = strlen(uri);
        copy = (char *)pdfmake_arena_alloc(self->doc->arena, len + 1);
        memcpy(copy, uri, len + 1);
        self->action_uri = copy;

void
set_reset_action(self)
    pdfmake_field_t *self
    CODE:
        self->action_reset = 1;

void
set_javascript(self, js)
    pdfmake_field_t *self
    const char *js
    PREINIT:
        size_t len;
        char *copy;
    CODE:
        len = strlen(js);
        copy = (char *)pdfmake_arena_alloc(self->doc->arena, len + 1);
        memcpy(copy, js, len + 1);
        self->action_js = copy;

#===============================================================================
# Appearance generation and flattening
#===============================================================================

void
generate_appearance(self)
    pdfmake_field_t *self
    CODE:
        if (pdfmake_field_generate_appearance(self) != PDFMAKE_OK)
            croak("PDF::Make::Field::generate_appearance: failed");

void
flatten(self)
    pdfmake_field_t *self
    CODE:
        if (pdfmake_field_flatten(self) != PDFMAKE_OK)
            croak("PDF::Make::Field::flatten: failed to flatten field");

#===============================================================================
# Field hierarchy
#===============================================================================

pdfmake_field_t *
parent(self)
    pdfmake_field_t *self
    CODE:
        RETVAL = self->parent;
        if (!RETVAL)
            XSRETURN_UNDEF;
    OUTPUT:
        RETVAL

void
children(self)
    pdfmake_field_t *self
    PPCODE:
        pdfmake_field_t *child = self->first_child;
        while (child) {
            SV *sv = sv_newmortal();
            sv_setref_pv(sv, "PDF::Make::Field", child);
            XPUSHs(sv);
            child = child->next_sibling;
        }

int
has_children(self)
    pdfmake_field_t *self
    CODE:
        RETVAL = (self->first_child != NULL);
    OUTPUT:
        RETVAL
