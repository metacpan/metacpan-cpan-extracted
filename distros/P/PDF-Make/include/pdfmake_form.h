/*
 * pdfmake_form.h — PDF interactive forms (AcroForms)
 *
 * Provides functions to create and manipulate PDF forms per
 * ISO 32000-2:2020 §12.7.
 *
 * Reference:
 * - §12.7 Interactive Forms
 * - §12.7.4 Field Types
 * - §12.5.6.19 Widget Annotations
 * - §12.7.8 Form Data Format
 */

#ifndef PDFMAKE_FORM_H
#define PDFMAKE_FORM_H

#include "pdfmake_types.h"
#include "pdfmake_doc.h"
#include "pdfmake_page.h"
#include "pdfmake_annot.h"
#include "pdfmake_buf.h"

#ifdef __cplusplus
extern "C" {
#endif

/*============================================================================
 * Field types (§12.7.4)
 *==========================================================================*/

typedef enum {
    PDFMAKE_FIELD_TEXT,       /* /FT /Tx - text field §12.7.4.3 */
    PDFMAKE_FIELD_BUTTON,     /* /FT /Btn - button §12.7.4.2 */
    PDFMAKE_FIELD_CHOICE,     /* /FT /Ch - choice §12.7.4.4 */
    PDFMAKE_FIELD_SIGNATURE   /* /FT /Sig - signature §12.7.4.5 */
} pdfmake_field_type_t;

/*============================================================================
 * Field flags (§12.7.4)
 *==========================================================================*/

/* Common flags (all field types) */
#define PDFMAKE_FF_READONLY       (1 << 0)   /* Bit 1 */
#define PDFMAKE_FF_REQUIRED       (1 << 1)   /* Bit 2 */
#define PDFMAKE_FF_NOEXPORT       (1 << 2)   /* Bit 3 */

/* Text field flags (§12.7.4.3) */
#define PDFMAKE_FF_MULTILINE      (1 << 12)  /* Bit 13 */
#define PDFMAKE_FF_PASSWORD       (1 << 13)  /* Bit 14 */
#define PDFMAKE_FF_FILESELECT     (1 << 20)  /* Bit 21 */
#define PDFMAKE_FF_DONOTSPELLCHECK (1 << 22) /* Bit 23 */
#define PDFMAKE_FF_DONOTSCROLL    (1 << 23)  /* Bit 24 */
#define PDFMAKE_FF_COMB           (1 << 24)  /* Bit 25 */
#define PDFMAKE_FF_RICHTEXT       (1 << 25)  /* Bit 26 */

/* Button flags (§12.7.4.2) */
#define PDFMAKE_FF_NOTOGGLETOOFF  (1 << 14)  /* Bit 15 */
#define PDFMAKE_FF_RADIO          (1 << 15)  /* Bit 16 */
#define PDFMAKE_FF_PUSHBUTTON     (1 << 16)  /* Bit 17 */
#define PDFMAKE_FF_RADIOSINUNISON (1 << 25)  /* Bit 26 */

/* Choice field flags (§12.7.4.4) */
#define PDFMAKE_FF_COMBO          (1 << 17)  /* Bit 18 */
#define PDFMAKE_FF_EDIT           (1 << 18)  /* Bit 19 */
#define PDFMAKE_FF_SORT           (1 << 19)  /* Bit 20 */
#define PDFMAKE_FF_MULTISELECT    (1 << 21)  /* Bit 22 */
#define PDFMAKE_FF_COMMITONSELCHANGE (1 << 26) /* Bit 27 */

/*============================================================================
 * Quadding (text alignment)
 *==========================================================================*/

typedef enum {
    PDFMAKE_QUADDING_LEFT   = 0,
    PDFMAKE_QUADDING_CENTER = 1,
    PDFMAKE_QUADDING_RIGHT  = 2
} pdfmake_quadding_t;

/*============================================================================
 * Form and field structures
 *==========================================================================*/

typedef struct pdfmake_form pdfmake_form_t;
typedef struct pdfmake_field pdfmake_field_t;

/* Choice option */
typedef struct {
    const char *display;     /* Display text */
    const char *export_val;  /* Export value (or NULL to use display) */
} pdfmake_choice_opt_t;

/* Field structure */
struct pdfmake_field {
    pdfmake_doc_t       *doc;
    pdfmake_field_type_t type;
    
    /* Identification */
    char                *name;       /* /T - partial field name */
    char                *full_name;  /* Full field name (parent.child) */
    
    /* Value */
    char                *value;      /* /V - field value */
    char                *default_val;/* /DV - default value */
    
    /* Flags */
    uint32_t             flags;      /* /Ff - field flags */
    
    /* Appearance */
    pdfmake_rect_t       rect;       /* Widget rectangle */
    char                *da;         /* /DA - default appearance string */
    pdfmake_quadding_t   quadding;   /* /Q - text alignment */
    
    /* Choice options (for choice fields) */
    pdfmake_choice_opt_t *options;
    size_t               option_count;
    size_t               option_cap;
    
    /* Button state (for checkbox/radio) */
    char                *on_value;   /* Export value when checked */
    
    /* Text field specifics */
    int                  max_len;    /* /MaxLen - max characters */
    
    /* Hierarchy */
    pdfmake_field_t     *parent;
    pdfmake_field_t     *first_child;
    pdfmake_field_t     *next_sibling;
    
    /* Object numbers after finalization */
    uint32_t             field_num;  /* Field dictionary obj num */
    uint32_t             widget_num; /* Widget annotation obj num */
    int                  flattened;  /* 1 = content burned into page stream */
    
    /* Associated page (for widget placement) */
    pdfmake_page_t      *page;

    /* Button action */
    char                *action_url;     /* SubmitForm URL (NULL = no action) */
    char                *action_uri;     /* URI action (opens link, works in all viewers) */
    int                  action_reset;   /* 1 = ResetForm action */
    char                *action_js;      /* JavaScript action (NULL = none) */
};

/* Form structure (AcroForm dictionary) */
struct pdfmake_form {
    pdfmake_doc_t   *doc;
    
    /* Fields */
    pdfmake_field_t **fields;
    size_t           field_count;
    size_t           field_cap;
    
    /* Default resources */
    char            *da;             /* /DA - default appearance */
    uint32_t         dr_num;         /* /DR - default resources obj num */
    
    /* Form flags */
    int              need_appearances; /* /NeedAppearances */
    int              sig_flags;        /* /SigFlags */
    
    /* Calculation order */
    uint32_t        *calc_order;     /* /CO - calculation order refs */
    size_t           calc_order_count;
    
    /* Object number after finalization */
    uint32_t         form_num;
};

/*============================================================================
 * Form access
 *==========================================================================*/

/*
 * Get the document's AcroForm. Returns NULL if no form exists.
 */
pdfmake_form_t *pdfmake_doc_get_form(pdfmake_doc_t *doc);

/*
 * Create an AcroForm for the document. Returns existing form if present.
 */
pdfmake_form_t *pdfmake_doc_create_form(pdfmake_doc_t *doc);

/*============================================================================
 * Field iteration
 *==========================================================================*/

/*
 * Get number of top-level fields in the form.
 */
size_t pdfmake_form_field_count(pdfmake_form_t *form);

/*
 * Get field at index.
 */
pdfmake_field_t *pdfmake_form_field_at(pdfmake_form_t *form, size_t idx);

/*
 * Find field by full name (e.g., "person.name.first").
 */
pdfmake_field_t *pdfmake_form_field_by_name(pdfmake_form_t *form, const char *name);

/*============================================================================
 * Field builders
 *==========================================================================*/

/*
 * Create a text field.
 */
pdfmake_field_t *pdfmake_field_text(pdfmake_doc_t *doc,
                                     const char *name,
                                     pdfmake_rect_t rect);

/*
 * Create a checkbox field.
 * on_value: Export value when checked (e.g., "Yes")
 */
pdfmake_field_t *pdfmake_field_checkbox(pdfmake_doc_t *doc,
                                         const char *name,
                                         pdfmake_rect_t rect,
                                         const char *on_value);

/*
 * Create a radio button group.
 * Returns the parent field; add children with pdfmake_field_add_radio_option.
 */
pdfmake_field_t *pdfmake_field_radio_group(pdfmake_doc_t *doc,
                                            const char *name);

/*
 * Add a radio button option to a group.
 */
pdfmake_field_t *pdfmake_field_add_radio_option(pdfmake_field_t *group,
                                                 pdfmake_rect_t rect,
                                                 const char *value);

/*
 * Create a choice field (listbox or combo/dropdown).
 * combo: 1 for dropdown, 0 for listbox
 */
pdfmake_field_t *pdfmake_field_choice(pdfmake_doc_t *doc,
                                       const char *name,
                                       pdfmake_rect_t rect,
                                       int combo);

/*
 * Create a pushbutton.
 */
pdfmake_field_t *pdfmake_field_button(pdfmake_doc_t *doc,
                                       const char *name,
                                       pdfmake_rect_t rect,
                                       const char *caption);

/*
 * Create a signature field (placeholder for signing).
 */
pdfmake_field_t *pdfmake_field_signature(pdfmake_doc_t *doc,
                                          const char *name,
                                          pdfmake_rect_t rect);

/*============================================================================
 * Field properties
 *==========================================================================*/

pdfmake_field_type_t pdfmake_field_type(pdfmake_field_t *field);
const char *pdfmake_field_name(pdfmake_field_t *field);
const char *pdfmake_field_full_name(pdfmake_field_t *field);
const char *pdfmake_field_value(pdfmake_field_t *field);

pdfmake_err_t pdfmake_field_set_value(pdfmake_field_t *field, const char *value);
pdfmake_err_t pdfmake_field_set_default_value(pdfmake_field_t *field, const char *value);

uint32_t pdfmake_field_flags(pdfmake_field_t *field);
pdfmake_err_t pdfmake_field_set_flags(pdfmake_field_t *field, uint32_t flags);
pdfmake_err_t pdfmake_field_add_flags(pdfmake_field_t *field, uint32_t flags);
pdfmake_err_t pdfmake_field_clear_flags(pdfmake_field_t *field, uint32_t flags);

/*
 * Set default appearance string (font, size, color).
 * e.g., "/Helv 12 Tf 0 g"
 */
pdfmake_err_t pdfmake_field_set_da(pdfmake_field_t *field, const char *da);

/*
 * Set text alignment.
 */
pdfmake_err_t pdfmake_field_set_quadding(pdfmake_field_t *field, pdfmake_quadding_t q);

/*
 * Set maximum length for text field.
 */
pdfmake_err_t pdfmake_field_set_max_len(pdfmake_field_t *field, int max_len);

/*============================================================================
 * Choice field options
 *==========================================================================*/

size_t pdfmake_field_option_count(pdfmake_field_t *field);
const char *pdfmake_field_option_display(pdfmake_field_t *field, size_t idx);
const char *pdfmake_field_option_export(pdfmake_field_t *field, size_t idx);

/*
 * Add an option to a choice field.
 * display: Text shown in the dropdown
 * export_val: Value exported when selected (NULL to use display)
 */
pdfmake_err_t pdfmake_field_add_option(pdfmake_field_t *field,
                                        const char *display,
                                        const char *export_val);

/*============================================================================
 * Field-page association
 *==========================================================================*/

/*
 * Add a field's widget annotation to a page.
 * This must be called to make the field visible.
 */
pdfmake_err_t pdfmake_page_add_field(pdfmake_page_t *page, pdfmake_field_t *field);

/*============================================================================
 * Appearance generation
 *==========================================================================*/

/*
 * Generate appearance stream for a field based on its current value.
 * Called automatically during finalization if NeedAppearances is false.
 */
pdfmake_err_t pdfmake_field_generate_appearance(pdfmake_field_t *field);

/*
 * Set NeedAppearances flag on form.
 * If true, viewer will generate appearances (less reliable).
 * If false, we generate appearances during finalization.
 */
pdfmake_err_t pdfmake_form_set_need_appearances(pdfmake_form_t *form, int need);

/*============================================================================
 * Form finalization
 *==========================================================================*/

/*
 * Finalize form: create AcroForm dictionary, field dictionaries,
 * widget annotations, and appearance streams.
 */
pdfmake_err_t pdfmake_form_finalize(pdfmake_form_t *form);

/*============================================================================
 * Flatten
 *==========================================================================*/

/*
 * Flatten all form fields: render values into page content, remove fields.
 * After flattening, the PDF is no longer interactive.
 */
pdfmake_err_t pdfmake_form_flatten(pdfmake_form_t *form);

/*
 * Flatten a single field.
 */
pdfmake_err_t pdfmake_field_flatten(pdfmake_field_t *field);

/*============================================================================
 * Form data export/import (§12.7.8)
 *==========================================================================*/

/*
 * Export form data to FDF format.
 */
pdfmake_err_t pdfmake_form_export_fdf(pdfmake_form_t *form, pdfmake_buf_t *out);

/*
 * Export form data to XFDF (XML) format.
 */
pdfmake_err_t pdfmake_form_export_xfdf(pdfmake_form_t *form, pdfmake_buf_t *out);

/*
 * Import form data from FDF.
 */
pdfmake_err_t pdfmake_form_import_fdf(pdfmake_form_t *form,
                                       const uint8_t *data, size_t len);

/*
 * Import form data from XFDF.
 */
pdfmake_err_t pdfmake_form_import_xfdf(pdfmake_form_t *form,
                                        const uint8_t *data, size_t len);

/*============================================================================
 * Reading forms from existing PDFs
 *==========================================================================*/

/*
 * Parse AcroForm from a loaded PDF document.
 * Populates the form structure with field data from the PDF.
 */
pdfmake_err_t pdfmake_form_parse(pdfmake_form_t *form);

#ifdef __cplusplus
}
#endif

#endif /* PDFMAKE_FORM_H */
