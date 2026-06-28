/*
 * pdfmake_form.c — PDF interactive forms (AcroForms)
 *
 * Implementation of PDF forms per ISO 32000-2:2020 §12.7.
 */

#include "pdfmake_form.h"
#include "pdfmake_arena.h"
#include "pdfmake_buf.h"
#include "pdfmake_content.h"
#include <string.h>
#include <stdlib.h>
#include <stdio.h>

/*============================================================================
 * Internal constants
 *==========================================================================*/

#define FORM_MAGIC 0x464F524D  /* "FORM" */

/* Default appearance for text fields */
static const char *DEFAULT_DA = "/Helv 12 Tf 0 g";

/*============================================================================
 * Form storage (associated with doc)
 *==========================================================================*/

typedef struct {
    uint32_t magic;
    pdfmake_form_t *form;
} form_storage_t;

static form_storage_t *get_or_create_storage(pdfmake_doc_t *doc)
{
    form_storage_t *storage;

    /* Use doc->form_data to store form_storage pointer directly */
    if (doc->form_data) {
        return (form_storage_t *)doc->form_data;
    }

    storage = pdfmake_arena_alloc(doc->arena, sizeof(form_storage_t));
    if (!storage) return NULL;
    
    storage->magic = FORM_MAGIC;
    storage->form = NULL;
    
    doc->form_data = storage;
    return storage;
}

/*============================================================================
 * Helper functions
 *==========================================================================*/

static pdfmake_field_t *create_field(pdfmake_doc_t *doc,
                                      pdfmake_field_type_t type,
                                      const char *name,
                                      pdfmake_rect_t rect)
{
    pdfmake_arena_t *arena = doc->arena;
    
    pdfmake_field_t *field = pdfmake_arena_alloc(arena, sizeof(pdfmake_field_t));
    if (!field) return NULL;
    
    memset(field, 0, sizeof(pdfmake_field_t));
    
    field->doc = doc;
    field->type = type;
    field->name = pdfmake_arena_strdup(arena, name);
    field->full_name = pdfmake_arena_strdup(arena, name);  /* Will be updated for nested fields */
    field->rect = rect;
    field->da = pdfmake_arena_strdup(arena, DEFAULT_DA);
    field->quadding = PDFMAKE_QUADDING_LEFT;
    
    return field;
}

static pdfmake_err_t add_field_to_form(pdfmake_form_t *form, pdfmake_field_t *field)
{
    if (!form || !field) return PDFMAKE_EINVAL;
    
    if (form->field_count >= form->field_cap) {
        size_t new_cap = form->field_cap ? form->field_cap * 2 : 8;
        pdfmake_field_t **new_fields = pdfmake_arena_alloc(form->doc->arena,
                                                           new_cap * sizeof(pdfmake_field_t *));
        if (!new_fields) return PDFMAKE_ENOMEM;
        
        if (form->fields) {
            memcpy(new_fields, form->fields, form->field_count * sizeof(pdfmake_field_t *));
        }
        form->fields = new_fields;
        form->field_cap = new_cap;
    }
    
    form->fields[form->field_count++] = field;
    return PDFMAKE_OK;
}

/*============================================================================
 * Form access
 *==========================================================================*/

pdfmake_form_t *pdfmake_doc_get_form(pdfmake_doc_t *doc)
{
    form_storage_t *storage;

    if (!doc) return NULL;

    storage = get_or_create_storage(doc);
    if (!storage) return NULL;
    
    return storage->form;
}

pdfmake_form_t *pdfmake_doc_create_form(pdfmake_doc_t *doc)
{
    form_storage_t *storage;
    pdfmake_form_t *form;

    if (!doc) return NULL;

    storage = get_or_create_storage(doc);
    if (!storage) return NULL;

    if (storage->form) return storage->form;

    form = pdfmake_arena_alloc(doc->arena, sizeof(pdfmake_form_t));
    if (!form) return NULL;
    
    memset(form, 0, sizeof(pdfmake_form_t));
    form->doc = doc;
    form->da = pdfmake_arena_strdup(doc->arena, DEFAULT_DA);
    form->need_appearances = 0;  /* We generate appearances by default */
    
    storage->form = form;
    return form;
}

/*============================================================================
 * Field iteration
 *==========================================================================*/

size_t pdfmake_form_field_count(pdfmake_form_t *form)
{
    return form ? form->field_count : 0;
}

pdfmake_field_t *pdfmake_form_field_at(pdfmake_form_t *form, size_t idx)
{
    if (!form || idx >= form->field_count) return NULL;
    return form->fields[idx];
}

pdfmake_field_t *pdfmake_form_field_by_name(pdfmake_form_t *form, const char *name)
{
    size_t i;
    pdfmake_field_t *field;

    if (!form || !name) return NULL;

    for (i = 0; i < form->field_count; i++) {
        field = form->fields[i];
        if (field->full_name && strcmp(field->full_name, name) == 0) {
            return field;
        }
        if (field->name && strcmp(field->name, name) == 0) {
            return field;
        }
    }
    return NULL;
}

/*============================================================================
 * Field builders
 *==========================================================================*/

pdfmake_field_t *pdfmake_field_text(pdfmake_doc_t *doc,
                                     const char *name,
                                     pdfmake_rect_t rect)
{
    pdfmake_field_t *field = create_field(doc, PDFMAKE_FIELD_TEXT, name, rect);
    pdfmake_form_t *form;

    if (!field) return NULL;

    /* Get or create form */
    form = pdfmake_doc_create_form(doc);
    if (form) {
        add_field_to_form(form, field);
    }
    
    return field;
}

pdfmake_field_t *pdfmake_field_checkbox(pdfmake_doc_t *doc,
                                         const char *name,
                                         pdfmake_rect_t rect,
                                         const char *on_value)
{
    pdfmake_field_t *field = create_field(doc, PDFMAKE_FIELD_BUTTON, name, rect);
    pdfmake_form_t *form;

    if (!field) return NULL;

    field->on_value = pdfmake_arena_strdup(doc->arena, on_value ? on_value : "Yes");

    form = pdfmake_doc_create_form(doc);
    if (form) {
        add_field_to_form(form, field);
    }
    
    return field;
}

pdfmake_field_t *pdfmake_field_radio_group(pdfmake_doc_t *doc,
                                            const char *name)
{
    pdfmake_rect_t empty_rect = {0, 0, 0, 0};
    pdfmake_field_t *field = create_field(doc, PDFMAKE_FIELD_BUTTON, name, empty_rect);
    pdfmake_form_t *form;

    if (!field) return NULL;

    field->flags |= PDFMAKE_FF_RADIO | PDFMAKE_FF_NOTOGGLETOOFF;

    form = pdfmake_doc_create_form(doc);
    if (form) {
        add_field_to_form(form, field);
    }
    
    return field;
}

pdfmake_field_t *pdfmake_field_add_radio_option(pdfmake_field_t *group,
                                                 pdfmake_rect_t rect,
                                                 const char *value)
{
    pdfmake_doc_t *doc;
    pdfmake_field_t *option;
    size_t parent_len;
    size_t val_len;
    char *full;
    pdfmake_field_t *last;

    if (!group || group->type != PDFMAKE_FIELD_BUTTON) return NULL;
    if (!(group->flags & PDFMAKE_FF_RADIO)) return NULL;

    doc = group->doc;

    /* Create child field for this option */
    option = pdfmake_arena_alloc(doc->arena, sizeof(pdfmake_field_t));
    if (!option) return NULL;
    
    memset(option, 0, sizeof(pdfmake_field_t));
    option->doc = doc;
    option->type = PDFMAKE_FIELD_BUTTON;
    option->rect = rect;
    option->flags = PDFMAKE_FF_RADIO;
    option->on_value = pdfmake_arena_strdup(doc->arena, value);
    option->parent = group;

    /* Build full name */
    parent_len = group->full_name ? strlen(group->full_name) : 0;
    val_len = value ? strlen(value) : 0;
    full = pdfmake_arena_alloc(doc->arena, parent_len + val_len + 2);
    if (full) {
        snprintf(full, parent_len + val_len + 2, "%s.%s",
                 group->full_name ? group->full_name : "", value ? value : "");
        option->full_name = full;
    }
    
    /* Link into group's children */
    if (!group->first_child) {
        group->first_child = option;
    } else {
        last = group->first_child;
        while (last->next_sibling) last = last->next_sibling;
        last->next_sibling = option;
    }
    
    return option;
}

pdfmake_field_t *pdfmake_field_choice(pdfmake_doc_t *doc,
                                       const char *name,
                                       pdfmake_rect_t rect,
                                       int combo)
{
    pdfmake_field_t *field = create_field(doc, PDFMAKE_FIELD_CHOICE, name, rect);
    pdfmake_form_t *form;

    if (!field) return NULL;

    if (combo) {
        field->flags |= PDFMAKE_FF_COMBO;
    }

    form = pdfmake_doc_create_form(doc);
    if (form) {
        add_field_to_form(form, field);
    }
    
    return field;
}

pdfmake_field_t *pdfmake_field_button(pdfmake_doc_t *doc,
                                       const char *name,
                                       pdfmake_rect_t rect,
                                       const char *caption)
{
    pdfmake_field_t *field = create_field(doc, PDFMAKE_FIELD_BUTTON, name, rect);
    pdfmake_form_t *form;

    if (!field) return NULL;

    field->flags |= PDFMAKE_FF_PUSHBUTTON;
    field->value = pdfmake_arena_strdup(doc->arena, caption);  /* Store caption as value */

    form = pdfmake_doc_create_form(doc);
    if (form) {
        add_field_to_form(form, field);
    }
    
    return field;
}

pdfmake_field_t *pdfmake_field_signature(pdfmake_doc_t *doc,
                                          const char *name,
                                          pdfmake_rect_t rect)
{
    pdfmake_field_t *field = create_field(doc, PDFMAKE_FIELD_SIGNATURE, name, rect);
    pdfmake_form_t *form;

    if (!field) return NULL;

    form = pdfmake_doc_create_form(doc);
    if (form) {
        add_field_to_form(form, field);
    }
    
    return field;
}

/*============================================================================
 * Field properties
 *==========================================================================*/

pdfmake_field_type_t pdfmake_field_type(pdfmake_field_t *field)
{
    return field ? field->type : PDFMAKE_FIELD_TEXT;
}

const char *pdfmake_field_name(pdfmake_field_t *field)
{
    return field ? field->name : NULL;
}

const char *pdfmake_field_full_name(pdfmake_field_t *field)
{
    return field ? field->full_name : NULL;
}

const char *pdfmake_field_value(pdfmake_field_t *field)
{
    return field ? field->value : NULL;
}

pdfmake_err_t pdfmake_field_set_value(pdfmake_field_t *field, const char *value)
{
    if (!field) return PDFMAKE_EINVAL;
    field->value = pdfmake_arena_strdup(field->doc->arena, value);
    return PDFMAKE_OK;
}

pdfmake_err_t pdfmake_field_set_default_value(pdfmake_field_t *field, const char *value)
{
    if (!field) return PDFMAKE_EINVAL;
    field->default_val = pdfmake_arena_strdup(field->doc->arena, value);
    return PDFMAKE_OK;
}

uint32_t pdfmake_field_flags(pdfmake_field_t *field)
{
    return field ? field->flags : 0;
}

pdfmake_err_t pdfmake_field_set_flags(pdfmake_field_t *field, uint32_t flags)
{
    if (!field) return PDFMAKE_EINVAL;
    field->flags = flags;
    return PDFMAKE_OK;
}

pdfmake_err_t pdfmake_field_add_flags(pdfmake_field_t *field, uint32_t flags)
{
    if (!field) return PDFMAKE_EINVAL;
    field->flags |= flags;
    return PDFMAKE_OK;
}

pdfmake_err_t pdfmake_field_clear_flags(pdfmake_field_t *field, uint32_t flags)
{
    if (!field) return PDFMAKE_EINVAL;
    field->flags &= ~flags;
    return PDFMAKE_OK;
}

pdfmake_err_t pdfmake_field_set_da(pdfmake_field_t *field, const char *da)
{
    if (!field) return PDFMAKE_EINVAL;
    field->da = pdfmake_arena_strdup(field->doc->arena, da);
    return PDFMAKE_OK;
}

pdfmake_err_t pdfmake_field_set_quadding(pdfmake_field_t *field, pdfmake_quadding_t q)
{
    if (!field) return PDFMAKE_EINVAL;
    field->quadding = q;
    return PDFMAKE_OK;
}

pdfmake_err_t pdfmake_field_set_max_len(pdfmake_field_t *field, int max_len)
{
    if (!field) return PDFMAKE_EINVAL;
    field->max_len = max_len;
    return PDFMAKE_OK;
}

/*============================================================================
 * Choice field options
 *==========================================================================*/

size_t pdfmake_field_option_count(pdfmake_field_t *field)
{
    return field ? field->option_count : 0;
}

const char *pdfmake_field_option_display(pdfmake_field_t *field, size_t idx)
{
    if (!field || idx >= field->option_count) return NULL;
    return field->options[idx].display;
}

const char *pdfmake_field_option_export(pdfmake_field_t *field, size_t idx)
{
    const char *exp;

    if (!field || idx >= field->option_count) return NULL;
    exp = field->options[idx].export_val;
    return exp ? exp : field->options[idx].display;
}

pdfmake_err_t pdfmake_field_add_option(pdfmake_field_t *field,
                                        const char *display,
                                        const char *export_val)
{
    if (!field || !display) return PDFMAKE_EINVAL;
    if (field->type != PDFMAKE_FIELD_CHOICE) return PDFMAKE_EINVAL;
    
    if (field->option_count >= field->option_cap) {
        size_t new_cap = field->option_cap ? field->option_cap * 2 : 8;
        pdfmake_choice_opt_t *new_opts = pdfmake_arena_alloc(field->doc->arena,
                                                             new_cap * sizeof(pdfmake_choice_opt_t));
        if (!new_opts) return PDFMAKE_ENOMEM;
        
        if (field->options) {
            memcpy(new_opts, field->options, field->option_count * sizeof(pdfmake_choice_opt_t));
        }
        field->options = new_opts;
        field->option_cap = new_cap;
    }
    
    field->options[field->option_count].display = pdfmake_arena_strdup(field->doc->arena, display);
    field->options[field->option_count].export_val = export_val ?
        pdfmake_arena_strdup(field->doc->arena, export_val) : NULL;
    field->option_count++;
    
    return PDFMAKE_OK;
}

/*============================================================================
 * Field-page association
 *==========================================================================*/

pdfmake_err_t pdfmake_page_add_field(pdfmake_page_t *page, pdfmake_field_t *field)
{
    if (!page || !field) return PDFMAKE_EINVAL;
    field->page = page;
    return PDFMAKE_OK;
}

/*============================================================================
 * Appearance generation
 *==========================================================================*/

/* Helper: create an appearance stream with BBox */
static pdfmake_obj_t create_appearance_stream(pdfmake_doc_t *doc,
                                               pdfmake_buf_t *buf,
                                               double width, double height)
{
    pdfmake_arena_t *arena = doc->arena;
    uint32_t bbox_key;
    uint32_t type_key;
    uint32_t subtype_key;
    pdfmake_obj_t bbox;
    pdfmake_obj_t stream_dict;
    uint32_t res_key;
    uint32_t font_key;
    pdfmake_obj_t res_dict;
    pdfmake_obj_t font_dict;
    pdfmake_obj_t helv_font;
    uint32_t bt_key;
    uint32_t st_key;
    uint32_t helv_num;
    uint32_t helv_key;
    
    pdfmake_obj_t stream = pdfmake_stream_new(arena);
    if (stream.kind != PDFMAKE_STREAM) return stream;
    
    pdfmake_stream_set_data(arena, &stream, buf->data, buf->len);
    
    /* Add BBox, Type, Subtype to stream dict */
    bbox_key = pdfmake_arena_intern_name(arena, "BBox", 4);
    type_key = pdfmake_arena_intern_name(arena, "Type", 4);
    subtype_key = pdfmake_arena_intern_name(arena, "Subtype", 7);
    
    bbox = pdfmake_array_new(arena);
    pdfmake_array_push(arena, &bbox, pdfmake_real(0));
    pdfmake_array_push(arena, &bbox, pdfmake_real(0));
    pdfmake_array_push(arena, &bbox, pdfmake_real(width));
    pdfmake_array_push(arena, &bbox, pdfmake_real(height));
    
    stream_dict.kind = PDFMAKE_DICT;
    stream_dict.as.dict = stream.as.stream->dict;
    
    pdfmake_dict_set(arena, &stream_dict, bbox_key, bbox);
    pdfmake_dict_set(arena, &stream_dict, type_key,
                     pdfmake_name(arena, "XObject", 7));
    pdfmake_dict_set(arena, &stream_dict, subtype_key,
                     pdfmake_name(arena, "Form", 4));

    /* /Resources with /Font /Helv for appearance text rendering */
    res_key = pdfmake_arena_intern_name(arena, "Resources", 9);
    font_key = pdfmake_arena_intern_name(arena, "Font", 4);
    res_dict = pdfmake_dict_new(arena);
    font_dict = pdfmake_dict_new(arena);
    helv_font = pdfmake_dict_new(arena);

    bt_key = pdfmake_arena_intern_name(arena, "BaseFont", 8);
    st_key = pdfmake_arena_intern_name(arena, "Subtype", 7);
    pdfmake_dict_set(arena, &helv_font, type_key,
                     pdfmake_name(arena, "Font", 4));
    pdfmake_dict_set(arena, &helv_font, st_key,
                     pdfmake_name(arena, "Type1", 5));
    pdfmake_dict_set(arena, &helv_font, bt_key,
                     pdfmake_name(arena, "Helvetica", 9));

    helv_num = pdfmake_doc_add(doc, helv_font);
    helv_key = pdfmake_arena_intern_name(arena, "Helv", 4);
    pdfmake_dict_set(arena, &font_dict, helv_key,
                     pdfmake_ref(helv_num, 0));
    pdfmake_dict_set(arena, &res_dict, font_key, font_dict);
    pdfmake_dict_set(arena, &stream_dict, res_key, res_dict);
    
    return stream;
}

/* Generate appearance stream for text field */
static pdfmake_err_t generate_text_appearance(pdfmake_doc_t *doc,
                                               pdfmake_field_t *field,
                                               pdfmake_obj_t *ap_dict)
{
    pdfmake_arena_t *arena = doc->arena;
    double width = field->rect.x2 - field->rect.x1;
    double height = field->rect.y2 - field->rect.y1;
    pdfmake_buf_t buf;
    double x;
    double y;
    const char *p;
    pdfmake_obj_t stream;
    uint32_t stream_num;
    uint32_t n_key;
    
    /* Build appearance stream content */
    pdfmake_buf_init(&buf);
    
    /* Background and border */
    pdfmake_buf_appendf(&buf, "q\n");
    pdfmake_buf_appendf(&buf, "1 1 1 rg\n");  /* White background */
    pdfmake_buf_appendf(&buf, "0 0 %.2f %.2f re f\n", width, height);
    
    /* Text */
    if (field->value && field->value[0]) {
        pdfmake_buf_appendf(&buf, "BT\n");
        pdfmake_buf_appendf(&buf, "%s\n", field->da ? field->da : DEFAULT_DA);
        
        /* Position text with margin */
        x = 2;
        y = (height - 12) / 2 + 2;  /* Rough vertical center for 12pt */
        
        /* Apply quadding */
        if (field->quadding == PDFMAKE_QUADDING_CENTER) {
            /* Approximate center (would need font metrics for accurate) */
            x = width / 2 - strlen(field->value) * 3;
        } else if (field->quadding == PDFMAKE_QUADDING_RIGHT) {
            x = width - 2 - strlen(field->value) * 6;
        }
        
        pdfmake_buf_appendf(&buf, "%.2f %.2f Td\n", x, y);
        pdfmake_buf_append_cstr(&buf, "(");
        
        /* Escape parentheses in value */
        for (p = field->value; *p; p++) {
            if (*p == '(' || *p == ')' || *p == '\\') {
                pdfmake_buf_append_byte(&buf, '\\');
            }
            pdfmake_buf_append_byte(&buf, *p);
        }
        
        pdfmake_buf_appendf(&buf, ") Tj\n");
        pdfmake_buf_appendf(&buf, "ET\n");
    }
    
    pdfmake_buf_appendf(&buf, "Q\n");
    
    /* Create stream object using helper */
    stream = create_appearance_stream(doc, &buf, width, height);
    stream_num = pdfmake_doc_add(doc, stream);
    
    /* Set /N (normal) appearance */
    n_key = pdfmake_arena_intern_name(arena, "N", 1);
    pdfmake_dict_set(arena, ap_dict, n_key, pdfmake_ref(stream_num, 0));
    
    pdfmake_buf_free(&buf);
    return PDFMAKE_OK;
}

/* Generate appearance stream for checkbox */
static pdfmake_err_t generate_checkbox_appearance(pdfmake_doc_t *doc,
                                                   pdfmake_field_t *field,
                                                   pdfmake_obj_t *ap_dict)
{
    pdfmake_arena_t *arena = doc->arena;
    double width = field->rect.x2 - field->rect.x1;
    double height = field->rect.y2 - field->rect.y1;
    double size = (width < height ? width : height) - 2;
    uint32_t n_key;
    
    /* Create /N dict with /Yes and /Off appearances */
    pdfmake_obj_t n_dict = pdfmake_dict_new(arena);
    
    /* /Off appearance - empty box */
    {
        pdfmake_buf_t buf;
        pdfmake_obj_t stream;
        uint32_t off_num;
        uint32_t off_key;

        pdfmake_buf_init(&buf);
        pdfmake_buf_appendf(&buf, "q\n");
        pdfmake_buf_appendf(&buf, "1 1 1 rg\n");
        pdfmake_buf_appendf(&buf, "0 0 %.2f %.2f re f\n", width, height);
        pdfmake_buf_appendf(&buf, "0 0 0 RG\n");
        pdfmake_buf_appendf(&buf, "0.5 w\n");
        pdfmake_buf_appendf(&buf, "1 1 %.2f %.2f re s\n", width - 2, height - 2);
        pdfmake_buf_appendf(&buf, "Q\n");
        
        stream = create_appearance_stream(doc, &buf, width, height);
        off_num = pdfmake_doc_add(doc, stream);
        
        off_key = pdfmake_arena_intern_name(arena, "Off", 3);
        pdfmake_dict_set(arena, &n_dict, off_key, pdfmake_ref(off_num, 0));
        
        pdfmake_buf_free(&buf);
    }
    
    /* /Yes appearance - box with checkmark */
    {
        pdfmake_buf_t buf;
        double cx;
        double cy;
        pdfmake_obj_t stream;
        uint32_t yes_num;
        const char *on_name;
        uint32_t yes_key;

        pdfmake_buf_init(&buf);
        pdfmake_buf_appendf(&buf, "q\n");
        pdfmake_buf_appendf(&buf, "1 1 1 rg\n");
        pdfmake_buf_appendf(&buf, "0 0 %.2f %.2f re f\n", width, height);
        pdfmake_buf_appendf(&buf, "0 0 0 RG\n");
        pdfmake_buf_appendf(&buf, "0.5 w\n");
        pdfmake_buf_appendf(&buf, "1 1 %.2f %.2f re s\n", width - 2, height - 2);
        
        /* Draw checkmark */
        cx = width / 2;
        cy = height / 2;
        pdfmake_buf_appendf(&buf, "1 w\n");
        pdfmake_buf_appendf(&buf, "%.2f %.2f m\n", cx - size * 0.3, cy);
        pdfmake_buf_appendf(&buf, "%.2f %.2f l\n", cx - size * 0.1, cy - size * 0.25);
        pdfmake_buf_appendf(&buf, "%.2f %.2f l\n", cx + size * 0.35, cy + size * 0.3);
        pdfmake_buf_appendf(&buf, "S\n");
        pdfmake_buf_appendf(&buf, "Q\n");
        
        stream = create_appearance_stream(doc, &buf, width, height);
        yes_num = pdfmake_doc_add(doc, stream);
        
        on_name = field->on_value ? field->on_value : "Yes";
        yes_key = pdfmake_arena_intern_name(arena, on_name, strlen(on_name));
        pdfmake_dict_set(arena, &n_dict, yes_key, pdfmake_ref(yes_num, 0));
        
        pdfmake_buf_free(&buf);
    }
    
    n_key = pdfmake_arena_intern_name(arena, "N", 1);
    pdfmake_dict_set(arena, ap_dict, n_key, n_dict);
    
    return PDFMAKE_OK;
}

/* Generate appearance stream for choice (dropdown/list) */
static pdfmake_err_t generate_choice_appearance(pdfmake_doc_t *doc,
                                                  pdfmake_field_t *field,
                                                  pdfmake_obj_t *ap_dict)
{
    /* Similar to text field but shows selected value */
    return generate_text_appearance(doc, field, ap_dict);
}

/* Generate appearance stream for pushbutton */
static pdfmake_err_t generate_button_appearance(pdfmake_doc_t *doc,
                                                  pdfmake_field_t *field,
                                                  pdfmake_obj_t *ap_dict)
{
    pdfmake_arena_t *arena = doc->arena;
    double width = field->rect.x2 - field->rect.x1;
    double height = field->rect.y2 - field->rect.y1;
    pdfmake_buf_t buf;
    double x;
    double y;
    const char *p;
    pdfmake_obj_t stream;
    uint32_t stream_num;
    uint32_t n_key;

    pdfmake_buf_init(&buf);
    
    /* 3D button appearance */
    pdfmake_buf_appendf(&buf, "q\n");
    
    /* Button face */
    pdfmake_buf_appendf(&buf, "0.8 0.8 0.8 rg\n");
    pdfmake_buf_appendf(&buf, "0 0 %.2f %.2f re f\n", width, height);
    
    /* 3D border — use S (stroke) not s (close-and-stroke) to avoid diagonal */
    pdfmake_buf_appendf(&buf, "1 1 1 RG 1 w\n");
    pdfmake_buf_appendf(&buf, "0 0 m %.2f 0 l %.2f %.2f l S\n", width, width, height);
    pdfmake_buf_appendf(&buf, "0.4 0.4 0.4 RG\n");
    pdfmake_buf_appendf(&buf, "0 0 m 0 %.2f l %.2f %.2f l S\n", height, width, height);
    
    /* Caption text */
    if (field->value && field->value[0]) {
        pdfmake_buf_appendf(&buf, "BT\n");
        pdfmake_buf_appendf(&buf, "/Helv 10 Tf 0 g\n");
        
        x = width / 2 - strlen(field->value) * 2.5;
        y = height / 2 - 4;
        
        pdfmake_buf_appendf(&buf, "%.2f %.2f Td (", x, y);
        for (p = field->value; *p; p++) {
            if (*p == '(' || *p == ')' || *p == '\\') {
                pdfmake_buf_append_byte(&buf, '\\');
            }
            pdfmake_buf_append_byte(&buf, *p);
        }
        pdfmake_buf_appendf(&buf, ") Tj\nET\n");
    }
    
    pdfmake_buf_appendf(&buf, "Q\n");
    
    stream = create_appearance_stream(doc, &buf, width, height);
    stream_num = pdfmake_doc_add(doc, stream);
    
    n_key = pdfmake_arena_intern_name(arena, "N", 1);
    pdfmake_dict_set(arena, ap_dict, n_key, pdfmake_ref(stream_num, 0));
    
    pdfmake_buf_free(&buf);
    return PDFMAKE_OK;
}

pdfmake_err_t pdfmake_field_generate_appearance(pdfmake_field_t *field)
{
    pdfmake_doc_t *doc;
    pdfmake_arena_t *arena;
    pdfmake_obj_t ap_dict;
    pdfmake_err_t err;

    if (!field || !field->doc) return PDFMAKE_EINVAL;

    doc = field->doc;
    arena = doc->arena;
    
    /* Create /AP (appearance) dictionary */
    ap_dict = pdfmake_dict_new(arena);

    err = PDFMAKE_OK;
    
    switch (field->type) {
        case PDFMAKE_FIELD_TEXT:
            err = generate_text_appearance(doc, field, &ap_dict);
            break;
            
        case PDFMAKE_FIELD_BUTTON:
            if (field->flags & PDFMAKE_FF_PUSHBUTTON) {
                err = generate_button_appearance(doc, field, &ap_dict);
            } else {
                err = generate_checkbox_appearance(doc, field, &ap_dict);
            }
            break;
            
        case PDFMAKE_FIELD_CHOICE:
            err = generate_choice_appearance(doc, field, &ap_dict);
            break;
            
        case PDFMAKE_FIELD_SIGNATURE:
            /* Signature fields typically have no appearance until signed */
            break;
    }
    
    /* Store appearance dict for use during finalization */
    /* (Will be attached to widget annotation) */
    
    return err;
}

pdfmake_err_t pdfmake_form_set_need_appearances(pdfmake_form_t *form, int need)
{
    if (!form) return PDFMAKE_EINVAL;
    form->need_appearances = need;
    return PDFMAKE_OK;
}

/*============================================================================
 * Form finalization
 *==========================================================================*/

static pdfmake_err_t finalize_field(pdfmake_doc_t *doc, pdfmake_field_t *field)
{
    pdfmake_arena_t *arena = doc->arena;
    pdfmake_obj_t field_dict;
    uint32_t ft_key;
    const char *ft_val;
    uint32_t type_key;
    uint32_t subtype_key;
    uint32_t rect_key;
    pdfmake_obj_t rect_arr;
    uint32_t border_key;
    pdfmake_obj_t border_arr;
    uint32_t f_key;
    pdfmake_obj_t ap_dict;
    uint32_t ap_key;
    size_t i;
    
    /* Create field dictionary */
    field_dict = pdfmake_dict_new(arena);
    
    /* /FT - field type */
    ft_key = pdfmake_arena_intern_name(arena, "FT", 2);
    switch (field->type) {
        case PDFMAKE_FIELD_TEXT:      ft_val = "Tx";  break;
        case PDFMAKE_FIELD_BUTTON:    ft_val = "Btn"; break;
        case PDFMAKE_FIELD_CHOICE:    ft_val = "Ch";  break;
        case PDFMAKE_FIELD_SIGNATURE: ft_val = "Sig"; break;
        default:                      ft_val = "Tx";  break;
    }
    pdfmake_dict_set(arena, &field_dict, ft_key, pdfmake_name_cstr(arena, ft_val));
    
    /* /T - partial field name */
    if (field->name) {
        uint32_t t_key;

        t_key = pdfmake_arena_intern_name(arena, "T", 1);
        pdfmake_dict_set(arena, &field_dict, t_key,
                         pdfmake_str(arena, field->name,
                                        strlen(field->name)));
    }
    
    /* /V - value */
    if (field->value) {
        uint32_t v_key;

        v_key = pdfmake_arena_intern_name(arena, "V", 1);
        if (field->type == PDFMAKE_FIELD_BUTTON && !(field->flags & PDFMAKE_FF_PUSHBUTTON)) {
            /* Checkbox/radio: value is a name */
            pdfmake_dict_set(arena, &field_dict, v_key,
                             pdfmake_name_cstr(arena, field->value));
        } else {
            pdfmake_dict_set(arena, &field_dict, v_key,
                             pdfmake_str(arena, field->value,
                                            strlen(field->value)));
        }
    }
    
    /* /DV - default value */
    if (field->default_val) {
        uint32_t dv_key;

        dv_key = pdfmake_arena_intern_name(arena, "DV", 2);
        pdfmake_dict_set(arena, &field_dict, dv_key,
                         pdfmake_str(arena, field->default_val,
                                        strlen(field->default_val)));
    }
    
    /* /Ff - field flags */
    if (field->flags) {
        uint32_t ff_key;

        ff_key = pdfmake_arena_intern_name(arena, "Ff", 2);
        pdfmake_dict_set(arena, &field_dict, ff_key, pdfmake_int(field->flags));
    }
    
    /* /DA - default appearance */
    if (field->da) {
        uint32_t da_key;

        da_key = pdfmake_arena_intern_name(arena, "DA", 2);
        pdfmake_dict_set(arena, &field_dict, da_key,
                         pdfmake_str(arena, field->da,
                                        strlen(field->da)));
    }
    
    /* /Q - quadding */
    if (field->quadding != PDFMAKE_QUADDING_LEFT) {
        uint32_t q_key;

        q_key = pdfmake_arena_intern_name(arena, "Q", 1);
        pdfmake_dict_set(arena, &field_dict, q_key, pdfmake_int(field->quadding));
    }
    
    /* /MaxLen for text fields */
    if (field->type == PDFMAKE_FIELD_TEXT && field->max_len > 0) {
        uint32_t maxlen_key;

        maxlen_key = pdfmake_arena_intern_name(arena, "MaxLen", 6);
        pdfmake_dict_set(arena, &field_dict, maxlen_key, pdfmake_int(field->max_len));
    }
    
    /* /Opt for choice fields */
    if (field->type == PDFMAKE_FIELD_CHOICE && field->option_count > 0) {
        uint32_t opt_key;
        pdfmake_obj_t opt_arr;

        opt_key = pdfmake_arena_intern_name(arena, "Opt", 3);
        opt_arr = pdfmake_array_new(arena);

        for (i = 0; i < field->option_count; i++) {
            if (field->options[i].export_val) {
                /* [export_val, display] pair */
                pdfmake_obj_t pair;

                pair = pdfmake_array_new(arena);
                pdfmake_array_push(arena, &pair,
                                   pdfmake_str_cstr(arena, field->options[i].export_val));
                pdfmake_array_push(arena, &pair,
                                   pdfmake_str_cstr(arena, field->options[i].display));
                pdfmake_array_push(arena, &opt_arr, pair);
            } else {
                pdfmake_array_push(arena, &opt_arr,
                                   pdfmake_str_cstr(arena, field->options[i].display));
            }
        }
        pdfmake_dict_set(arena, &field_dict, opt_key, opt_arr);
    }
    
    /* Widget annotation (merged with field for simple fields) */
    /* /Type /Annot, /Subtype /Widget */
    type_key = pdfmake_arena_intern_name(arena, "Type", 4);
    subtype_key = pdfmake_arena_intern_name(arena, "Subtype", 7);
    pdfmake_dict_set(arena, &field_dict, type_key, pdfmake_name_cstr(arena, "Annot"));
    pdfmake_dict_set(arena, &field_dict, subtype_key, pdfmake_name_cstr(arena, "Widget"));
    
    /* /Rect */
    rect_key = pdfmake_arena_intern_name(arena, "Rect", 4);
    rect_arr = pdfmake_array_new(arena);
    pdfmake_array_push(arena, &rect_arr, pdfmake_real(field->rect.x1));
    pdfmake_array_push(arena, &rect_arr, pdfmake_real(field->rect.y1));
    pdfmake_array_push(arena, &rect_arr, pdfmake_real(field->rect.x2));
    pdfmake_array_push(arena, &rect_arr, pdfmake_real(field->rect.y2));
    pdfmake_dict_set(arena, &field_dict, rect_key, rect_arr);

    /* /Border [0 0 1] — thin border for interactive feedback */
    border_key = pdfmake_arena_intern_name(arena, "Border", 6);
    border_arr = pdfmake_array_new(arena);
    pdfmake_array_push(arena, &border_arr, pdfmake_int(0));
    pdfmake_array_push(arena, &border_arr, pdfmake_int(0));
    pdfmake_array_push(arena, &border_arr, pdfmake_int(1));
    pdfmake_dict_set(arena, &field_dict, border_key, border_arr);

    /* /MK — appearance characteristics (border color for text/choice fields) */
    if (field->type == PDFMAKE_FIELD_TEXT || field->type == PDFMAKE_FIELD_CHOICE) {
        uint32_t mk_key;
        pdfmake_obj_t mk;
        /* /BC [0 0 0] — border color black */
        uint32_t bc_key;
        pdfmake_obj_t bc;
        /* /BG [1 1 1] — background color white */
        uint32_t bg_key;
        pdfmake_obj_t bg;

        mk_key = pdfmake_arena_intern_name(arena, "MK", 2);
        mk = pdfmake_dict_new(arena);
        bc_key = pdfmake_arena_intern_name(arena, "BC", 2);
        bc = pdfmake_array_new(arena);
        bg_key = pdfmake_arena_intern_name(arena, "BG", 2);
        bg = pdfmake_array_new(arena);

        pdfmake_array_push(arena, &bc, pdfmake_real(0));
        pdfmake_array_push(arena, &bc, pdfmake_real(0));
        pdfmake_array_push(arena, &bc, pdfmake_real(0));
        pdfmake_dict_set(arena, &mk, bc_key, bc);
        pdfmake_array_push(arena, &bg, pdfmake_real(1));
        pdfmake_array_push(arena, &bg, pdfmake_real(1));
        pdfmake_array_push(arena, &bg, pdfmake_real(1));
        pdfmake_dict_set(arena, &mk, bg_key, bg);
        pdfmake_dict_set(arena, &field_dict, mk_key, mk);
    }

    /* /F 4 — Print flag (annotation should print) */
    f_key = pdfmake_arena_intern_name(arena, "F", 1);
    pdfmake_dict_set(arena, &field_dict, f_key, pdfmake_int(4));

    /* Generate and attach appearance */
    ap_dict = pdfmake_dict_new(arena);
    
    switch (field->type) {
        case PDFMAKE_FIELD_TEXT:
            generate_text_appearance(doc, field, &ap_dict);
            break;
        case PDFMAKE_FIELD_BUTTON:
            if (field->flags & PDFMAKE_FF_PUSHBUTTON) {
                generate_button_appearance(doc, field, &ap_dict);
            } else {
                generate_checkbox_appearance(doc, field, &ap_dict);
            }
            break;
        case PDFMAKE_FIELD_CHOICE:
            generate_choice_appearance(doc, field, &ap_dict);
            break;
        case PDFMAKE_FIELD_SIGNATURE:
            /* No appearance for unsigned signature */
            break;
    }
    
    ap_key = pdfmake_arena_intern_name(arena, "AP", 2);
    pdfmake_dict_set(arena, &field_dict, ap_key, ap_dict);
    
    /* /AS - appearance state for checkboxes */
    if (field->type == PDFMAKE_FIELD_BUTTON && !(field->flags & PDFMAKE_FF_PUSHBUTTON)) {
        uint32_t as_key;
        const char *state;

        as_key = pdfmake_arena_intern_name(arena, "AS", 2);
        state = (field->value && field->on_value &&
                             strcmp(field->value, field->on_value) == 0)
                            ? field->on_value : "Off";
        pdfmake_dict_set(arena, &field_dict, as_key, pdfmake_name_cstr(arena, state));
    }
    
    /* /P - page reference (if field is on a page) */
    if (field->page && field->page->page_num) {
        uint32_t p_key;

        p_key = pdfmake_arena_intern_name(arena, "P", 1);
        pdfmake_dict_set(arena, &field_dict, p_key,
                         pdfmake_ref(field->page->page_num, 0));
    }
    
    /* /A - button action */
    if (field->action_uri) {
        pdfmake_obj_t action;
        uint32_t s_key;
        uint32_t uri_key;
        uint32_t a_key;

        action = pdfmake_dict_new(arena);
        s_key = pdfmake_arena_intern_name(arena, "S", 1);
        pdfmake_dict_set(arena, &action, s_key,
                         pdfmake_name_cstr(arena, "URI"));
        uri_key = pdfmake_arena_intern_name(arena, "URI", 3);
        pdfmake_dict_set(arena, &action, uri_key,
                         pdfmake_str_cstr(arena, field->action_uri));
        a_key = pdfmake_arena_intern_name(arena, "A", 1);
        pdfmake_dict_set(arena, &field_dict, a_key, action);
    } else if (field->action_url) {
        pdfmake_obj_t action;
        uint32_t s_key;
        uint32_t f_key2;
        uint32_t flags_key;
        uint32_t a_key;

        action = pdfmake_dict_new(arena);
        s_key = pdfmake_arena_intern_name(arena, "S", 1);
        pdfmake_dict_set(arena, &action, s_key,
                         pdfmake_name_cstr(arena, "SubmitForm"));
        f_key2 = pdfmake_arena_intern_name(arena, "F", 1);
        pdfmake_dict_set(arena, &action, f_key2,
                         pdfmake_str_cstr(arena, field->action_url));
        /* Flags: 0 = FDF, 4 = HTML, 8 = XFDF */
        flags_key = pdfmake_arena_intern_name(arena, "Flags", 5);
        pdfmake_dict_set(arena, &action, flags_key, pdfmake_int(4));
        a_key = pdfmake_arena_intern_name(arena, "A", 1);
        pdfmake_dict_set(arena, &field_dict, a_key, action);
    } else if (field->action_reset) {
        pdfmake_obj_t action;
        uint32_t s_key;
        uint32_t a_key;

        action = pdfmake_dict_new(arena);
        s_key = pdfmake_arena_intern_name(arena, "S", 1);
        pdfmake_dict_set(arena, &action, s_key,
                         pdfmake_name_cstr(arena, "ResetForm"));
        a_key = pdfmake_arena_intern_name(arena, "A", 1);
        pdfmake_dict_set(arena, &field_dict, a_key, action);
    } else if (field->action_js) {
        pdfmake_obj_t action;
        uint32_t s_key;
        uint32_t js_key;
        uint32_t a_key;

        action = pdfmake_dict_new(arena);
        s_key = pdfmake_arena_intern_name(arena, "S", 1);
        pdfmake_dict_set(arena, &action, s_key,
                         pdfmake_name_cstr(arena, "JavaScript"));
        js_key = pdfmake_arena_intern_name(arena, "JS", 2);
        pdfmake_dict_set(arena, &action, js_key,
                         pdfmake_str_cstr(arena, field->action_js));
        a_key = pdfmake_arena_intern_name(arena, "A", 1);
        pdfmake_dict_set(arena, &field_dict, a_key, action);
    }

    /* Add field dictionary as indirect object */
    field->field_num = pdfmake_doc_add(doc, field_dict);
    field->widget_num = field->field_num;  /* Merged field+widget */
    
    /* Add to page's /Annots array if we have a page */
    if (field->page) {
        pdfmake_page_add_annot(field->page, field->widget_num);
    }
    
    return PDFMAKE_OK;
}

pdfmake_err_t pdfmake_form_finalize(pdfmake_form_t *form)
{
    pdfmake_doc_t *doc;
    pdfmake_arena_t *arena;
    int live_fields;
    size_t i;
    pdfmake_field_t *f;
    pdfmake_err_t err;
    pdfmake_obj_t acroform;
    uint32_t fields_key;
    pdfmake_obj_t fields_arr;
    pdfmake_obj_t dr;
    pdfmake_obj_t font_dict;
    pdfmake_obj_t helv;
    uint32_t type_key;
    uint32_t subtype_key;
    uint32_t basefont_key;
    uint32_t helv_num;
    uint32_t helv_key;
    uint32_t font_key;
    uint32_t dr_key;

    if (!form || !form->doc) return PDFMAKE_EINVAL;
    if (form->form_num) return PDFMAKE_OK;  /* Already finalized */

    doc = form->doc;
    arena = doc->arena;
    
    /* Finalize non-flattened fields */
    live_fields = 0;
    for (i = 0; i < form->field_count; i++) {
        f = form->fields[i];
        if (f->flattened) continue;
        err = finalize_field(doc, f);
        if (err != PDFMAKE_OK) return err;
        if (f->field_num) live_fields++;
    }

    /* If all fields were flattened, don't emit AcroForm at all */
    if (live_fields == 0) return PDFMAKE_OK;

    /* Create AcroForm dictionary */
    acroform = pdfmake_dict_new(arena);
    
    /* /Fields array */
    fields_key = pdfmake_arena_intern_name(arena, "Fields", 6);
    fields_arr = pdfmake_array_new(arena);
    
    for (i = 0; i < form->field_count; i++) {
        if (form->fields[i]->field_num) {
            pdfmake_array_push(arena, &fields_arr,
                               pdfmake_ref(form->fields[i]->field_num, 0));
        }
    }
    pdfmake_dict_set(arena, &acroform, fields_key, fields_arr);
    
    /* /DA - default appearance */
    if (form->da) {
        uint32_t da_key;

        da_key = pdfmake_arena_intern_name(arena, "DA", 2);
        pdfmake_dict_set(arena, &acroform, da_key,
                         pdfmake_str(arena, form->da,
                                        strlen(form->da)));
    }
    
    /* /NeedAppearances */
    if (form->need_appearances) {
        uint32_t na_key;

        na_key = pdfmake_arena_intern_name(arena, "NeedAppearances", 15);
        pdfmake_dict_set(arena, &acroform, na_key, pdfmake_bool(1));
    }
    
    /* /DR - default resources (font for Helv) */
    dr = pdfmake_dict_new(arena);
    font_dict = pdfmake_dict_new(arena);
    
    /* /Helv -> Helvetica */
    helv = pdfmake_dict_new(arena);
    type_key = pdfmake_arena_intern_name(arena, "Type", 4);
    subtype_key = pdfmake_arena_intern_name(arena, "Subtype", 7);
    basefont_key = pdfmake_arena_intern_name(arena, "BaseFont", 8);
    
    pdfmake_dict_set(arena, &helv, type_key, pdfmake_name_cstr(arena, "Font"));
    pdfmake_dict_set(arena, &helv, subtype_key, pdfmake_name_cstr(arena, "Type1"));
    pdfmake_dict_set(arena, &helv, basefont_key, pdfmake_name_cstr(arena, "Helvetica"));
    
    helv_num = pdfmake_doc_add(doc, helv);
    
    helv_key = pdfmake_arena_intern_name(arena, "Helv", 4);
    pdfmake_dict_set(arena, &font_dict, helv_key, pdfmake_ref(helv_num, 0));
    
    font_key = pdfmake_arena_intern_name(arena, "Font", 4);
    pdfmake_dict_set(arena, &dr, font_key, font_dict);
    
    dr_key = pdfmake_arena_intern_name(arena, "DR", 2);
    pdfmake_dict_set(arena, &acroform, dr_key, dr);
    
    /* Add AcroForm to document */
    form->form_num = pdfmake_doc_add(doc, acroform);
    
    return PDFMAKE_OK;
}

/*============================================================================
 * Flatten
 *==========================================================================*/

pdfmake_err_t pdfmake_field_flatten(pdfmake_field_t *field)
{
    pdfmake_doc_t *doc;
    pdfmake_arena_t *arena;
    pdfmake_page_t *page;
    double x;
    double y;
    double width;
    double height;
    uint8_t *old_content;
    size_t old_len;
    pdfmake_obj_t *stream_obj;
    const uint8_t *sdata;
    size_t slen;
    pdfmake_content_t *c;
    pdfmake_buf_t *buf;
    double tx;
    double ty;
    const char *p;
    double size;
    const char *on_val;
    double cx;
    double cy;
    const uint8_t *new_data;
    size_t new_len;
    pdfmake_obj_t new_stream;
    uint32_t new_num;

    if (!field) return PDFMAKE_EINVAL;
    if (!field->page) return PDFMAKE_EINVAL;  /* Field must be on a page */

    doc = field->doc;
    arena = doc->arena;
    page = field->page;
    
    /* Generate field value content for the page */
    x = field->rect.x1;
    y = field->rect.y1;
    width = field->rect.x2 - field->rect.x1;
    height = field->rect.y2 - field->rect.y1;
    
    /* Get existing content stream data */
    old_content = NULL;
    old_len = 0;

    if (page->has_content && page->contents_num > 0) {
        stream_obj = pdfmake_doc_get(doc, page->contents_num);
        if (stream_obj && stream_obj->kind == PDFMAKE_STREAM) {
            sdata = stream_obj->as.stream->raw;
            slen = stream_obj->as.stream->raw_len;
            if (sdata && slen > 0) {
                old_content = malloc(slen);
                if (old_content) {
                    memcpy(old_content, sdata, slen);
                    old_len = slen;
                }
            }
        }
    }

    /* Build new content stream with flattened field appended */
    c = pdfmake_content_new(arena);
    if (!c) { free(old_content); return PDFMAKE_ENOMEM; }

    /* Copy existing content */
    if (old_content && old_len > 0) {
        pdfmake_buf_append(&c->buf, old_content, old_len);
        pdfmake_buf_append_byte(&c->buf, '\n');
    }
    free(old_content);

    buf = &c->buf;
    
    /* Save graphics state */
    pdfmake_buf_appendf(buf, "q\n");
    
    /* Translate to field position */
    pdfmake_buf_appendf(buf, "1 0 0 1 %.4f %.4f cm\n", x, y);
    
    /* Clip to field rectangle */
    pdfmake_buf_appendf(buf, "0 0 %.4f %.4f re W n\n", width, height);
    
    /* Render based on field type */
    switch (field->type) {
        case PDFMAKE_FIELD_TEXT:
        case PDFMAKE_FIELD_CHOICE:
            /* White background */
            pdfmake_buf_appendf(buf, "1 1 1 rg 0 0 %.4f %.4f re f\n", width, height);
            
            /* Text value */
            if (field->value && field->value[0]) {
                pdfmake_buf_appendf(buf, "BT\n");
                pdfmake_buf_appendf(buf, "%s\n", field->da ? field->da : DEFAULT_DA);
                
                tx = 2;
                ty = (height - 12) / 2 + 2;
                
                if (field->quadding == PDFMAKE_QUADDING_CENTER) {
                    tx = width / 2 - strlen(field->value) * 3;
                } else if (field->quadding == PDFMAKE_QUADDING_RIGHT) {
                    tx = width - 2 - strlen(field->value) * 6;
                }
                
                pdfmake_buf_appendf(buf, "%.4f %.4f Td\n", tx, ty);
                pdfmake_buf_appendf(buf, "(");
                for (p = field->value; *p; p++) {
                    if (*p == '(' || *p == ')' || *p == '\\') {
                        pdfmake_buf_append_byte(buf, '\\');
                    }
                    pdfmake_buf_append_byte(buf, *p);
                }
                pdfmake_buf_appendf(buf, ") Tj\n");
                pdfmake_buf_appendf(buf, "ET\n");
            }
            break;
            
        case PDFMAKE_FIELD_BUTTON:
            if (field->flags & PDFMAKE_FF_PUSHBUTTON) {
                /* Pushbutton appearance */
                pdfmake_buf_appendf(buf, "0.8 0.8 0.8 rg 0 0 %.4f %.4f re f\n", width, height);
                pdfmake_buf_appendf(buf, "1 1 1 RG 1 w 0 0 m %.4f 0 l %.4f %.4f l s\n", 
                                    width, width, height);
                pdfmake_buf_appendf(buf, "0.4 0.4 0.4 RG 0 0 m 0 %.4f l %.4f %.4f l s\n", 
                                    height, width, height);
                
                if (field->value && field->value[0]) {
                    pdfmake_buf_appendf(buf, "BT /Helv 10 Tf 0 g\n");
                    tx = width / 2 - strlen(field->value) * 2.5;
                    ty = height / 2 - 4;
                    pdfmake_buf_appendf(buf, "%.4f %.4f Td (", tx, ty);
                    for (p = field->value; *p; p++) {
                        if (*p == '(' || *p == ')' || *p == '\\') {
                            pdfmake_buf_append_byte(buf, '\\');
                        }
                        pdfmake_buf_append_byte(buf, *p);
                    }
                    pdfmake_buf_appendf(buf, ") Tj ET\n");
                }
            } else {
                /* Checkbox/radio appearance */
                size = (width < height ? width : height) - 2;
                
                /* Box */
                pdfmake_buf_appendf(buf, "1 1 1 rg 0 0 %.4f %.4f re f\n", width, height);
                pdfmake_buf_appendf(buf, "0 0 0 RG 0.5 w 1 1 %.4f %.4f re s\n", 
                                    width - 2, height - 2);
                
                /* Check if selected */
                on_val = field->on_value ? field->on_value : "Yes";
                if (field->value && strcmp(field->value, "Off") != 0 &&
                    strcmp(field->value, on_val) == 0) {
                    /* Draw checkmark */
                    cx = width / 2;
                    cy = height / 2;
                    pdfmake_buf_appendf(buf, "1 w\n");
                    pdfmake_buf_appendf(buf, "%.4f %.4f m\n", cx - size * 0.3, cy);
                    pdfmake_buf_appendf(buf, "%.4f %.4f l\n", cx - size * 0.1, cy - size * 0.25);
                    pdfmake_buf_appendf(buf, "%.4f %.4f l S\n", cx + size * 0.35, cy + size * 0.3);
                }
            }
            break;
            
        case PDFMAKE_FIELD_SIGNATURE:
            /* Signature fields: just render placeholder */
            pdfmake_buf_appendf(buf, "0.9 0.9 0.9 rg 0 0 %.4f %.4f re f\n", width, height);
            pdfmake_buf_appendf(buf, "0 0 0 RG 0.5 w 0 0 %.4f %.4f re s\n", width, height);
            break;
    }
    
    /* Restore graphics state */
    pdfmake_buf_appendf(buf, "Q\n");

    /* Replace content stream */
    new_data = pdfmake_content_data(c);
    new_len = pdfmake_content_len(c);

    new_stream = pdfmake_stream_new(arena);
    pdfmake_stream_set_data(arena, &new_stream, new_data, new_len);
    new_num = pdfmake_doc_add(doc, new_stream);

    page->contents_num = new_num;
    page->has_content = 1;

    pdfmake_content_free(c);
    
    /* Mark field as flattened */
    field->widget_num = 0;
    field->field_num = 0;
    field->flattened = 1;
    
    return PDFMAKE_OK;
}

pdfmake_err_t pdfmake_form_flatten(pdfmake_form_t *form)
{
    size_t i;
    pdfmake_err_t err;

    if (!form) return PDFMAKE_EINVAL;

    for (i = 0; i < form->field_count; i++) {
        err = pdfmake_field_flatten(form->fields[i]);
        if (err != PDFMAKE_OK) return err;
    }
    
    return PDFMAKE_OK;
}

/*============================================================================
 * Form data export/import
 *==========================================================================*/

pdfmake_err_t pdfmake_form_export_fdf(pdfmake_form_t *form, pdfmake_buf_t *out)
{
    size_t i;
    pdfmake_field_t *field;
    const char *p;

    if (!form || !out) return PDFMAKE_EINVAL;
    
    /* FDF header */
    pdfmake_buf_appendf(out, "%%FDF-1.2\n");
    pdfmake_buf_appendf(out, "1 0 obj\n");
    pdfmake_buf_appendf(out, "<<\n");
    pdfmake_buf_appendf(out, "/FDF <<\n");
    pdfmake_buf_appendf(out, "/Fields [\n");
    
    /* Field values */
    for (i = 0; i < form->field_count; i++) {
        field = form->fields[i];
        if (!field->full_name) continue;
        if (field->flags & PDFMAKE_FF_NOEXPORT) continue;  /* Skip noexport fields */
        
        pdfmake_buf_appendf(out, "<< /T (%s)", field->full_name);
        
        if (field->value) {
            if (field->type == PDFMAKE_FIELD_BUTTON &&
                !(field->flags & PDFMAKE_FF_PUSHBUTTON)) {
                pdfmake_buf_appendf(out, " /V /%s", field->value);
            } else {
                pdfmake_buf_appendf(out, " /V (");
                for (p = field->value; *p; p++) {
                    if (*p == '(' || *p == ')' || *p == '\\') {
                        pdfmake_buf_append_byte(out, '\\');
                    }
                    pdfmake_buf_append_byte(out, *p);
                }
                pdfmake_buf_appendf(out, ")");
            }
        }
        
        pdfmake_buf_appendf(out, " >>\n");
    }
    
    pdfmake_buf_appendf(out, "]\n");
    pdfmake_buf_appendf(out, ">>\n");
    pdfmake_buf_appendf(out, ">>\n");
    pdfmake_buf_appendf(out, "endobj\n");
    pdfmake_buf_appendf(out, "trailer\n");
    pdfmake_buf_appendf(out, "<< /Root 1 0 R >>\n");
    pdfmake_buf_appendf(out, "%%%%EOF\n");
    
    return PDFMAKE_OK;
}

pdfmake_err_t pdfmake_form_export_xfdf(pdfmake_form_t *form, pdfmake_buf_t *out)
{
    size_t i;
    pdfmake_field_t *field;

    if (!form || !out) return PDFMAKE_EINVAL;
    
    /* XFDF header */
    pdfmake_buf_appendf(out, "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n");
    pdfmake_buf_appendf(out, "<xfdf xmlns=\"http://ns.adobe.com/xfdf/\">\n");
    pdfmake_buf_appendf(out, "<fields>\n");
    
    /* Field values */
    for (i = 0; i < form->field_count; i++) {
        field = form->fields[i];
        if (!field->full_name) continue;
        if (field->flags & PDFMAKE_FF_NOEXPORT) continue;  /* Skip noexport fields */
        
        pdfmake_buf_appendf(out, "<field name=\"%s\">\n", field->full_name);
        if (field->value) {
            pdfmake_buf_appendf(out, "<value>%s</value>\n", field->value);
        }
        pdfmake_buf_appendf(out, "</field>\n");
    }
    
    pdfmake_buf_appendf(out, "</fields>\n");
    pdfmake_buf_appendf(out, "</xfdf>\n");
    
    return PDFMAKE_OK;
}

pdfmake_err_t pdfmake_form_import_fdf(pdfmake_form_t *form,
                                       const uint8_t *data, size_t len)
{
    char *buf;
    const char *p;
    const char *end;
    const char *t_pos;
    const char *v_pos;
    const char *next_field;
    char field_name[256];
    char value[1024];
    size_t i;
    int escape;
    int paren_depth;
    pdfmake_field_t *field;

    if (!form || !data || len == 0) return PDFMAKE_EINVAL;
    
    /* Copy to null-terminated buffer for strstr */
    buf = malloc(len + 1);
    if (!buf) return PDFMAKE_ENOMEM;
    memcpy(buf, data, len);
    buf[len] = '\0';
    
    /* Simple FDF parser - looks for /T (field name) and /V (value) pairs */
    p = buf;
    end = buf + len;
    
    while (p < end) {
        field_name[0] = '\0';
        value[0] = '\0';

        /* Find /T (field name) */
        t_pos = strstr(p, "/T ");
        if (!t_pos || t_pos >= end) break;
        
        t_pos += 3;  /* Skip "/T " */
        
        /* Skip whitespace */
        while (t_pos < end && (*t_pos == ' ' || *t_pos == '\n' || *t_pos == '\r'))
            t_pos++;
        
        if (t_pos >= end) break;
        
        /* Extract field name (expecting string literal or name) */
        if (*t_pos == '(') {
            /* String literal */
            i = 0;
            escape = 0;

            t_pos++;
            while (t_pos < end && i < sizeof(field_name) - 1) {
                if (escape) {
                    field_name[i++] = *t_pos;
                    escape = 0;
                } else if (*t_pos == '\\') {
                    escape = 1;
                } else if (*t_pos == ')') {
                    break;
                } else {
                    field_name[i++] = *t_pos;
                }
                t_pos++;
            }
            field_name[i] = '\0';
        } else if (*t_pos == '/') {
            /* Name object */
            i = 0;

            t_pos++;
            while (t_pos < end && i < sizeof(field_name) - 1 &&
                   *t_pos != ' ' && *t_pos != '/' && *t_pos != '>' &&
                   *t_pos != '\n' && *t_pos != '\r') {
                field_name[i++] = *t_pos++;
            }
            field_name[i] = '\0';
        }
        
        if (!field_name[0]) {
            p = t_pos;
            continue;
        }
        
        /* Look for /V (value) after the field name */
        v_pos = strstr(t_pos, "/V ");
        if (!v_pos || v_pos >= end) {
            p = t_pos;
            continue;
        }
        
        /* Make sure we haven't gone past the next field definition */
        next_field = strstr(t_pos, "/T ");
        if (next_field && next_field < v_pos) {
            p = t_pos;
            continue;
        }
        
        v_pos += 3;  /* Skip "/V " */
        
        /* Skip whitespace */
        while (v_pos < end && (*v_pos == ' ' || *v_pos == '\n' || *v_pos == '\r'))
            v_pos++;
        
        if (v_pos >= end) {
            p = t_pos;
            continue;
        }
        
        /* Extract value */
        if (*v_pos == '(') {
            /* String literal */
            i = 0;
            escape = 0;
            paren_depth = 1;

            v_pos++;
            while (v_pos < end && i < sizeof(value) - 1 && paren_depth > 0) {
                if (escape) {
                    value[i++] = *v_pos;
                    escape = 0;
                } else if (*v_pos == '\\') {
                    escape = 1;
                } else if (*v_pos == '(') {
                    paren_depth++;
                    value[i++] = *v_pos;
                } else if (*v_pos == ')') {
                    paren_depth--;
                    if (paren_depth > 0) value[i++] = *v_pos;
                } else {
                    value[i++] = *v_pos;
                }
                v_pos++;
            }
            value[i] = '\0';
        } else if (*v_pos == '/') {
            /* Name object (for checkbox/radio) */
            i = 0;

            v_pos++;
            while (v_pos < end && i < sizeof(value) - 1 &&
                   *v_pos != ' ' && *v_pos != '/' && *v_pos != '>' &&
                   *v_pos != '\n' && *v_pos != '\r') {
                value[i++] = *v_pos++;
            }
            value[i] = '\0';
        }
        
        /* Find the field and set its value */
        field = pdfmake_form_field_by_name(form, field_name);
        if (field) {
            pdfmake_field_set_value(field, value);
        }
        
        p = v_pos;
    }
    
    free(buf);
    return PDFMAKE_OK;
}

pdfmake_err_t pdfmake_form_import_xfdf(pdfmake_form_t *form,
                                        const uint8_t *data, size_t len)
{
    char *buf;
    const char *p;
    const char *end;
    const char *field_tag;
    const char *name_attr;
    char field_name[256];
    size_t i;
    const char *value_tag;
    const char *field_end;
    const char *value_end;
    char value[4096];
    const char *vp;
    int code;
    pdfmake_field_t *field;

    if (!form || !data || len == 0) return PDFMAKE_EINVAL;
    
    /* Copy to null-terminated buffer for strstr */
    buf = malloc(len + 1);
    if (!buf) return PDFMAKE_ENOMEM;
    memcpy(buf, data, len);
    buf[len] = '\0';
    
    /* Simple XFDF parser - looks for <field name="..."><value>...</value></field> */
    p = buf;
    end = buf + len;
    
    while (p < end) {
        field_name[0] = '\0';

        /* Find <field */
        field_tag = strstr(p, "<field ");
        if (!field_tag || field_tag >= end) break;
        
        field_tag += 7;  /* Skip "<field " */
        
        /* Find name attribute */
        name_attr = strstr(field_tag, "name=\"");
        if (!name_attr || name_attr >= end) {
            p = field_tag;
            continue;
        }
        
        name_attr += 6;  /* Skip 'name="' */
        
        /* Extract field name */
        i = 0;
        while (name_attr < end && *name_attr != '"' && i < sizeof(field_name) - 1) {
            /* Handle XML entities */
            if (*name_attr == '&') {
                if (strncmp(name_attr, "&amp;", 5) == 0) {
                    field_name[i++] = '&';
                    name_attr += 5;
                } else if (strncmp(name_attr, "&lt;", 4) == 0) {
                    field_name[i++] = '<';
                    name_attr += 4;
                } else if (strncmp(name_attr, "&gt;", 4) == 0) {
                    field_name[i++] = '>';
                    name_attr += 4;
                } else if (strncmp(name_attr, "&quot;", 6) == 0) {
                    field_name[i++] = '"';
                    name_attr += 6;
                } else if (strncmp(name_attr, "&apos;", 6) == 0) {
                    field_name[i++] = '\'';
                    name_attr += 6;
                } else {
                    field_name[i++] = *name_attr++;
                }
            } else {
                field_name[i++] = *name_attr++;
            }
        }
        field_name[i] = '\0';
        
        if (!field_name[0]) {
            p = name_attr;
            continue;
        }
        
        /* Find <value> tag */
        value_tag = strstr(name_attr, "<value>");
        if (!value_tag || value_tag >= end) {
            /* Check if field is empty (self-closing or no value tag) */
            field_end = strstr(name_attr, "</field>");
            if (field_end && field_end < end) {
                p = field_end + 8;
            } else {
                p = name_attr;
            }
            continue;
        }
        
        value_tag += 7;  /* Skip "<value>" */
        
        /* Find </value> */
        value_end = strstr(value_tag, "</value>");
        if (!value_end || value_end >= end) {
            p = value_tag;
            continue;
        }
        
        /* Extract value with XML entity decoding */
        value[0] = '\0';
        i = 0;
        vp = value_tag;
        while (vp < value_end && i < sizeof(value) - 1) {
            if (*vp == '&') {
                if (strncmp(vp, "&amp;", 5) == 0) {
                    value[i++] = '&';
                    vp += 5;
                } else if (strncmp(vp, "&lt;", 4) == 0) {
                    value[i++] = '<';
                    vp += 4;
                } else if (strncmp(vp, "&gt;", 4) == 0) {
                    value[i++] = '>';
                    vp += 4;
                } else if (strncmp(vp, "&quot;", 6) == 0) {
                    value[i++] = '"';
                    vp += 6;
                } else if (strncmp(vp, "&apos;", 6) == 0) {
                    value[i++] = '\'';
                    vp += 6;
                } else if (strncmp(vp, "&#", 2) == 0) {
                    /* Numeric entity */
                    vp += 2;
                    code = 0;
                    if (*vp == 'x' || *vp == 'X') {
                        vp++;
                        while (vp < value_end && *vp != ';') {
                            if (*vp >= '0' && *vp <= '9')
                                code = code * 16 + (*vp - '0');
                            else if (*vp >= 'a' && *vp <= 'f')
                                code = code * 16 + (*vp - 'a' + 10);
                            else if (*vp >= 'A' && *vp <= 'F')
                                code = code * 16 + (*vp - 'A' + 10);
                            vp++;
                        }
                    } else {
                        while (vp < value_end && *vp != ';') {
                            if (*vp >= '0' && *vp <= '9')
                                code = code * 10 + (*vp - '0');
                            vp++;
                        }
                    }
                    if (code > 0 && code < 128) value[i++] = (char)code;
                    if (vp < value_end && *vp == ';') vp++;
                } else {
                    value[i++] = *vp++;
                }
            } else {
                value[i++] = *vp++;
            }
        }
        value[i] = '\0';
        
        /* Find the field and set its value */
        field = pdfmake_form_field_by_name(form, field_name);
        if (field) {
            pdfmake_field_set_value(field, value);
        }
        
        p = value_end + 8;  /* Skip "</value>" */
    }
    
    free(buf);
    return PDFMAKE_OK;
}

/*============================================================================
 * Reading forms from existing PDFs
 *==========================================================================*/

/* Helper: get dict value by name string */
static pdfmake_obj_t *get_dict_entry(pdfmake_arena_t *arena, pdfmake_dict_t *dict, 
                                      const char *key_name)
{
    uint32_t key_id;
    size_t i;

    if (!dict || !key_name) return NULL;

    key_id = pdfmake_arena_intern_name(arena, key_name, strlen(key_name));

    for (i = 0; i < dict->cap; i++) {
        if (dict->entries[i].key == key_id && !dict->entries[i].deleted) {
            return &dict->entries[i].value;
        }
    }
    return NULL;
}

/* Helper: extract string value from obj */
static const char *get_string_value(pdfmake_obj_t *obj, char *buf, size_t buf_len)
{
    if (!obj || !buf) return NULL;
    
    if (obj->kind == PDFMAKE_STR) {
        size_t copy_len = obj->as.str.len < buf_len - 1 ? obj->as.str.len : buf_len - 1;
        memcpy(buf, obj->as.str.bytes, copy_len);
        buf[copy_len] = '\0';
        return buf;
    } else if (obj->kind == PDFMAKE_NAME) {
        /* Would need to look up name in arena - simplified for now */
        return NULL;
    }
    return NULL;
}

/* Helper: resolve indirect reference */
static pdfmake_obj_t *resolve_ref(pdfmake_doc_t *doc, pdfmake_obj_t *obj)
{
    if (!obj) return NULL;
    if (obj->kind == PDFMAKE_REF) {
        return pdfmake_doc_get(doc, obj->as.ref.num);
    }
    return obj;
}

/* Parse a single field from field dictionary */
static pdfmake_err_t parse_field_dict(pdfmake_form_t *form, pdfmake_obj_t *field_obj,
                                       pdfmake_field_t *parent)
{
    pdfmake_doc_t *doc;
    pdfmake_arena_t *arena;
    pdfmake_dict_t *dict;
    pdfmake_field_type_t type;
    pdfmake_obj_t *ft_obj;
    char name_buf[256] = "";
    pdfmake_obj_t *t_obj;
    pdfmake_rect_t rect = {0, 0, 100, 20};
    pdfmake_obj_t *rect_obj;
    pdfmake_array_t *arr;
    pdfmake_field_t *field;
    pdfmake_obj_t *v_obj;
    pdfmake_obj_t *ff_obj;
    pdfmake_obj_t *da_obj;
    pdfmake_obj_t *q_obj;
    pdfmake_obj_t *kids_obj;
    size_t i;

    if (!form || !field_obj) return PDFMAKE_EINVAL;

    doc = form->doc;
    arena = doc->arena;
    
    /* Resolve if indirect reference */
    field_obj = resolve_ref(doc, field_obj);
    if (!field_obj || field_obj->kind != PDFMAKE_DICT) return PDFMAKE_EINVAL;
    
    dict = field_obj->as.dict;
    
    /* Get field type /FT */
    type = PDFMAKE_FIELD_TEXT;  /* Default */
    ft_obj = get_dict_entry(arena, dict, "FT");
    if (ft_obj && ft_obj->kind == PDFMAKE_NAME) {
        /* Check name - this is simplified, would need name table lookup */
    }
    
    /* Get field name /T */
    t_obj = get_dict_entry(arena, dict, "T");
    get_string_value(t_obj, name_buf, sizeof(name_buf));
    
    /* Get field rect (from widget annotation or /Rect) */
    rect_obj = get_dict_entry(arena, dict, "Rect");
    if (rect_obj && rect_obj->kind == PDFMAKE_ARRAY && rect_obj->as.arr->len >= 4) {
        arr = rect_obj->as.arr;
        if (arr->items[0].kind == PDFMAKE_REAL || arr->items[0].kind == PDFMAKE_INT)
            rect.x1 = arr->items[0].kind == PDFMAKE_REAL ? arr->items[0].as.r : arr->items[0].as.i;
        if (arr->items[1].kind == PDFMAKE_REAL || arr->items[1].kind == PDFMAKE_INT)
            rect.y1 = arr->items[1].kind == PDFMAKE_REAL ? arr->items[1].as.r : arr->items[1].as.i;
        if (arr->items[2].kind == PDFMAKE_REAL || arr->items[2].kind == PDFMAKE_INT)
            rect.x2 = arr->items[2].kind == PDFMAKE_REAL ? arr->items[2].as.r : arr->items[2].as.i;
        if (arr->items[3].kind == PDFMAKE_REAL || arr->items[3].kind == PDFMAKE_INT)
            rect.y2 = arr->items[3].kind == PDFMAKE_REAL ? arr->items[3].as.r : arr->items[3].as.i;
    }
    
    /* Create field structure */
    field = create_field(doc, type, name_buf, rect);
    if (!field) return PDFMAKE_ENOMEM;
    
    /* Set parent */
    field->parent = parent;
    
    /* Get value /V */
    v_obj = get_dict_entry(arena, dict, "V");
    if (v_obj) {
        char value_buf[4096] = "";
        if (get_string_value(v_obj, value_buf, sizeof(value_buf))) {
            field->value = pdfmake_arena_strdup(arena, value_buf);
        }
    }
    
    /* Get flags /Ff */
    ff_obj = get_dict_entry(arena, dict, "Ff");
    if (ff_obj && ff_obj->kind == PDFMAKE_INT) {
        field->flags = (uint32_t)ff_obj->as.i;
    }
    
    /* Get default appearance /DA */
    da_obj = get_dict_entry(arena, dict, "DA");
    if (da_obj) {
        char da_buf[256] = "";
        if (get_string_value(da_obj, da_buf, sizeof(da_buf))) {
            field->da = pdfmake_arena_strdup(arena, da_buf);
        }
    }
    
    /* Get quadding /Q */
    q_obj = get_dict_entry(arena, dict, "Q");
    if (q_obj && q_obj->kind == PDFMAKE_INT) {
        field->quadding = (pdfmake_quadding_t)q_obj->as.i;
    }
    
    /* Add to form */
    add_field_to_form(form, field);
    
    /* Process children /Kids */
    kids_obj = get_dict_entry(arena, dict, "Kids");
    if (kids_obj) {
        kids_obj = resolve_ref(doc, kids_obj);
        if (kids_obj && kids_obj->kind == PDFMAKE_ARRAY) {
            for (i = 0; i < kids_obj->as.arr->len; i++) {
                parse_field_dict(form, &kids_obj->as.arr->items[i], field);
            }
        }
    }
    
    return PDFMAKE_OK;
}

pdfmake_err_t pdfmake_form_parse(pdfmake_form_t *form)
{
    pdfmake_doc_t *doc;
    pdfmake_arena_t *arena;
    pdfmake_obj_t *catalog;
    pdfmake_obj_t *acroform_obj;
    pdfmake_dict_t *acroform;
    pdfmake_obj_t *da_obj;
    pdfmake_obj_t *na_obj;
    pdfmake_obj_t *sf_obj;
    pdfmake_obj_t *fields_obj;
    size_t i;
    pdfmake_err_t err;

    if (!form) return PDFMAKE_EINVAL;

    doc = form->doc;
    arena = doc->arena;
    
    /* Get document catalog */
    if (doc->root_num == 0) return PDFMAKE_EINVAL;
    
    catalog = pdfmake_doc_get(doc, doc->root_num);
    if (!catalog || catalog->kind != PDFMAKE_DICT) return PDFMAKE_EINVAL;
    
    /* Get /AcroForm dictionary */
    acroform_obj = get_dict_entry(arena, catalog->as.dict, "AcroForm");
    if (!acroform_obj) return PDFMAKE_OK;  /* No form - not an error */
    
    acroform_obj = resolve_ref(doc, acroform_obj);
    if (!acroform_obj || acroform_obj->kind != PDFMAKE_DICT) return PDFMAKE_EINVAL;
    
    acroform = acroform_obj->as.dict;
    
    /* Get form-wide DA */
    da_obj = get_dict_entry(arena, acroform, "DA");
    if (da_obj) {
        char da_buf[256] = "";
        if (get_string_value(da_obj, da_buf, sizeof(da_buf))) {
            form->da = pdfmake_arena_strdup(arena, da_buf);
        }
    }
    
    /* Get NeedAppearances */
    na_obj = get_dict_entry(arena, acroform, "NeedAppearances");
    if (na_obj && na_obj->kind == PDFMAKE_BOOL) {
        form->need_appearances = na_obj->as.b;
    }
    
    /* Get SigFlags */
    sf_obj = get_dict_entry(arena, acroform, "SigFlags");
    if (sf_obj && sf_obj->kind == PDFMAKE_INT) {
        form->sig_flags = (int)sf_obj->as.i;
    }
    
    /* Parse /Fields array */
    fields_obj = get_dict_entry(arena, acroform, "Fields");
    if (!fields_obj) return PDFMAKE_OK;  /* No fields */
    
    fields_obj = resolve_ref(doc, fields_obj);
    if (!fields_obj || fields_obj->kind != PDFMAKE_ARRAY) return PDFMAKE_EINVAL;
    
    /* Parse each top-level field */
    for (i = 0; i < fields_obj->as.arr->len; i++) {
        err = parse_field_dict(form, &fields_obj->as.arr->items[i], NULL);
        if (err != PDFMAKE_OK) return err;
    }
    
    return PDFMAKE_OK;
}
