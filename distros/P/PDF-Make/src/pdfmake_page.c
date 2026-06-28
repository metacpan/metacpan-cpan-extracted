/*
 * pdfmake_page.c — Page and catalog construction.
 */

#include "pdfmake_page.h"
#include "pdfmake_ocg.h"
#include "pdfmake_attach.h"
#include "pdfmake_tag.h"
#include "pdfmake_arena.h"
#include "pdfmake_outline.h"
#include "pdfmake_form.h"
#include <stdlib.h>
#include <string.h>
#include <stdio.h>

/*----------------------------------------------------------------------------
 * Standard 14 font names (§9.6.2.2)
 *--------------------------------------------------------------------------*/

static const char *std14_names[] = {
    "Helvetica",
    "Helvetica-Bold",
    "Helvetica-Oblique",
    "Helvetica-BoldOblique",
    "Times-Roman",
    "Times-Bold",
    "Times-Italic",
    "Times-BoldItalic",
    "Courier",
    "Courier-Bold",
    "Courier-Oblique",
    "Courier-BoldOblique",
    "Symbol",
    "ZapfDingbats"
};

const char *pdfmake_std14_name(pdfmake_std14_font_t font) {
    if (font < 0 || font >= PDFMAKE_FONT_COUNT) return NULL;
    return std14_names[font];
}

int pdfmake_std14_lookup(const char *name) {
    int i;
    if (!name) return -1;
    for (i = 0; i < PDFMAKE_FONT_COUNT; i++) {
        if (strcmp(name, std14_names[i]) == 0) return i;
    }
    return -1;
}

/*----------------------------------------------------------------------------
 * Internal: grow pages array
 *--------------------------------------------------------------------------*/

static int doc_grow_pages(pdfmake_doc_t *doc) {
    size_t new_cap = doc->page_cap == 0 ? 4 : doc->page_cap * 2;
    pdfmake_page_t **new_arr = realloc(doc->pages, new_cap * sizeof(pdfmake_page_t *));
    if (!new_arr) return 0;
    doc->pages = new_arr;
    doc->page_cap = new_cap;
    return 1;
}

/*----------------------------------------------------------------------------
 * Page creation
 *--------------------------------------------------------------------------*/

pdfmake_page_t *pdfmake_doc_add_page(pdfmake_doc_t *doc, double width, double height) {
    pdfmake_page_t *page;
    if (!doc) return NULL;
    if (doc->finalized) return NULL;  /* Can't add pages after finalize */

    /* Grow pages array if needed */
    if (doc->page_count >= doc->page_cap) {
        if (!doc_grow_pages(doc)) return NULL;
    }

    /* Allocate page structure from arena */
    page = pdfmake_arena_calloc(doc->arena, sizeof(pdfmake_page_t));
    if (!page) return NULL;

    page->doc = doc;
    page->width = width;
    page->height = height;
    page->rotation = 0;
    page->font_count = 0;
    page->image_count = 0;
    page->prop_count = 0;
    page->extgstate_count = 0;
    page->redactions = NULL;
    page->redact_count = 0;
    page->redact_cap = 0;
    page->has_content = 0;
    page->contents_num = 0;

    /* The /Page dict will be created during finalize when we know the /Pages ref */
    page->page_num = 0;

    /* Add to document's page list */
    doc->pages[doc->page_count++] = page;

    return page;
}

size_t pdfmake_doc_page_count(pdfmake_doc_t *doc) {
    return doc ? doc->page_count : 0;
}

pdfmake_page_t *pdfmake_doc_get_page(pdfmake_doc_t *doc, size_t index) {
    if (!doc || index >= doc->page_count) return NULL;
    return doc->pages[index];
}

/*----------------------------------------------------------------------------
 * Page resources - fonts
 *--------------------------------------------------------------------------*/

uint32_t pdfmake_page_add_font(pdfmake_page_t *page,
                               const char *name,
                               const char *base_font) {
    pdfmake_doc_t *doc;
    pdfmake_arena_t *arena;
    pdfmake_obj_t font_dict;
    uint32_t type_key;
    uint32_t subtype_key;
    uint32_t basefont_key;
    uint32_t font_num;
    pdfmake_font_entry_t *entry;

    if (!page || !name || !base_font) return 0;
    if (page->font_count >= PDFMAKE_MAX_PAGE_FONTS) return 0;

    /* Verify it's a Standard 14 font */
    if (pdfmake_std14_lookup(base_font) < 0) return 0;

    doc = page->doc;
    arena = pdfmake_doc_arena(doc);

    /* Create /Font dictionary:
     * << /Type /Font /Subtype /Type1 /BaseFont /Helvetica >> */
    font_dict = pdfmake_dict_new(arena);
    if (font_dict.kind != PDFMAKE_DICT) return 0;

    type_key = pdfmake_arena_intern_name(arena, "Type", 4);
    subtype_key = pdfmake_arena_intern_name(arena, "Subtype", 7);
    basefont_key = pdfmake_arena_intern_name(arena, "BaseFont", 8);

    pdfmake_dict_set(arena, &font_dict, type_key, pdfmake_name_cstr(arena, "Font"));
    pdfmake_dict_set(arena, &font_dict, subtype_key, pdfmake_name_cstr(arena, "Type1"));
    pdfmake_dict_set(arena, &font_dict, basefont_key, pdfmake_name_cstr(arena, base_font));

    /* Add font dict as indirect object */
    font_num = pdfmake_doc_add(doc, font_dict);
    if (font_num == 0) return 0;

    /* Record in page's font list */
    entry = &page->fonts[page->font_count++];
    strncpy(entry->name, name, sizeof(entry->name) - 1);
    entry->name[sizeof(entry->name) - 1] = '\0';
    entry->font_num = font_num;

    return font_num;
}

uint32_t pdfmake_page_add_std14_font(pdfmake_page_t *page,
                                      const char *name,
                                      pdfmake_std14_font_t font) {
    const char *base_font = pdfmake_std14_name(font);
    if (!base_font) return 0;
    return pdfmake_page_add_font(page, name, base_font);
}

int pdfmake_page_add_extgstate(pdfmake_page_t *page,
                               const char *name,
                               uint32_t extgstate_obj_num)
{
    pdfmake_extgstate_entry_t *entry;

    if (!page || !name || extgstate_obj_num == 0) return -1;
    if (page->extgstate_count >= PDFMAKE_MAX_PAGE_EXTGSTATES) return -1;

    entry = &page->extgstates[page->extgstate_count++];
    strncpy(entry->name, name, sizeof(entry->name) - 1);
    entry->name[sizeof(entry->name) - 1] = '\0';
    entry->extgstate_num = extgstate_obj_num;

    return (int)(page->extgstate_count - 1);
}

/*----------------------------------------------------------------------------
 * Content stream
 *--------------------------------------------------------------------------*/

pdfmake_err_t pdfmake_page_set_content(pdfmake_page_t *page,
                                        const uint8_t *data,
                                        size_t len) {
    pdfmake_doc_t *doc;
    pdfmake_arena_t *arena;
    pdfmake_obj_t stream;
    uint32_t contents_num;

    if (!page || !data) return PDFMAKE_EINVAL;

    doc = page->doc;
    arena = pdfmake_doc_arena(doc);

    /* Create a stream object with the content */
    stream = pdfmake_stream_new(arena);
    if (stream.kind != PDFMAKE_STREAM) return PDFMAKE_ENOMEM;

    if (!pdfmake_stream_set_data(arena, &stream, data, len)) {
        return PDFMAKE_ENOMEM;
    }

    /* Add as indirect object */
    contents_num = pdfmake_doc_add(doc, stream);
    if (contents_num == 0) return PDFMAKE_ENOMEM;

    page->contents_num = contents_num;
    page->has_content = 1;

    return PDFMAKE_OK;
}

pdfmake_err_t pdfmake_page_set_content_str(pdfmake_page_t *page,
                                            const char *content) {
    if (!content) return PDFMAKE_EINVAL;
    return pdfmake_page_set_content(page, (const uint8_t *)content, strlen(content));
}

pdfmake_err_t pdfmake_page_append_content(pdfmake_page_t *page,
                                           const uint8_t *data,
                                           size_t len)
{
    pdfmake_doc_t *doc;
    pdfmake_arena_t *arena;
    pdfmake_obj_t *existing;
    pdfmake_stream_t *stm;
    const uint8_t *old_bytes;
    size_t old_len;
    size_t cap;
    uint8_t *combined;
    size_t off;

    if (!page || !data) return PDFMAKE_EINVAL;
    if (!page->has_content || page->contents_num == 0) {
        return pdfmake_page_set_content(page, data, len);
    }

    doc = page->doc;
    arena = pdfmake_doc_arena(doc);

    /* Fetch the existing content stream so we can concatenate.  Its raw
     * bytes may be compressed (e.g. /Filter /FlateDecode imported from a
     * source PDF); we decompress before concatenating so the combined
     * stream is plain and we don't have to synthesize the filter chain. */
    existing = pdfmake_doc_get(doc, page->contents_num);
    if (!existing || existing->kind != PDFMAKE_STREAM) {
        return pdfmake_page_set_content(page, data, len);
    }

    /* Use the stream's raw bytes directly.  Pages created via
     * pdfmake_page_set_content always store plain (unfiltered) content,
     * and pdfmake_doc_import_page feeds pre-decoded bytes in through the
     * same path — so the raw pointer is the content we need, regardless
     * of how the page was built. */
    stm = existing->as.stream;
    old_bytes = stm->raw;
    old_len   = stm->raw_len;

    /* Build `<<existing>>\nq\n<<overlay>>\nQ\n` so overlay starts from a
     * clean graphics state but the existing content is preserved. */
    cap = old_len + 1 + 2 + 1 + len + 1 + 2 + 1;
    combined = pdfmake_arena_alloc(arena, cap);
    if (!combined) return PDFMAKE_ENOMEM;

    off = 0;
    memcpy(combined + off, old_bytes, old_len); off += old_len;
    if (old_len == 0 || old_bytes[old_len - 1] != '\n') combined[off++] = '\n';
    combined[off++] = 'q'; combined[off++] = '\n';
    memcpy(combined + off, data, len); off += len;
    if (len == 0 || data[len - 1] != '\n') combined[off++] = '\n';
    combined[off++] = 'Q'; combined[off++] = '\n';

    return pdfmake_page_set_content(page, combined, off);
}

/*----------------------------------------------------------------------------
 * Internal: build Resources dictionary for a page
 *--------------------------------------------------------------------------*/

static pdfmake_obj_t build_resources_dict(pdfmake_page_t *page) {
    pdfmake_doc_t *doc = page->doc;
    pdfmake_arena_t *arena = pdfmake_doc_arena(doc);
    pdfmake_obj_t resources;
    pdfmake_obj_t font_dict;
    pdfmake_obj_t xobj_dict;
    pdfmake_obj_t prop_dict;
    pdfmake_obj_t gs_dict;
    size_t i;
    uint32_t font_key;
    uint32_t xobj_key;
    uint32_t prop_key;
    uint32_t gs_key;

    resources = pdfmake_dict_new(arena);
    if (resources.kind != PDFMAKE_DICT) return resources;

    /* Build /Font subdictionary if page has fonts */
    if (page->font_count > 0) {
        font_dict = pdfmake_dict_new(arena);
        if (font_dict.kind != PDFMAKE_DICT) return font_dict;

        for (i = 0; i < page->font_count; i++) {
            pdfmake_font_entry_t *entry = &page->fonts[i];
            uint32_t key = pdfmake_arena_intern_name(arena, entry->name, strlen(entry->name));
            pdfmake_obj_t ref = pdfmake_ref(entry->font_num, 0);
            pdfmake_dict_set(arena, &font_dict, key, ref);
        }

        font_key = pdfmake_arena_intern_name(arena, "Font", 4);
        pdfmake_dict_set(arena, &resources, font_key, font_dict);
    }

    /* Build /XObject subdictionary if page has images */
    if (page->image_count > 0) {
        xobj_dict = pdfmake_dict_new(arena);
        if (xobj_dict.kind != PDFMAKE_DICT) return xobj_dict;

        for (i = 0; i < page->image_count; i++) {
            pdfmake_image_entry_t *entry = &page->images[i];
            uint32_t key = pdfmake_arena_intern_name(arena, entry->name, strlen(entry->name));
            pdfmake_obj_t ref = pdfmake_ref(entry->image_num, 0);
            pdfmake_dict_set(arena, &xobj_dict, key, ref);
        }

        xobj_key = pdfmake_arena_intern_name(arena, "XObject", 7);
        pdfmake_dict_set(arena, &resources, xobj_key, xobj_dict);
    }

    /* Build /Properties subdictionary if page has OCG references */
    if (page->prop_count > 0) {
        prop_dict = pdfmake_dict_new(arena);
        if (prop_dict.kind != PDFMAKE_DICT) return prop_dict;

        for (i = 0; i < page->prop_count; i++) {
            pdfmake_prop_entry_t *entry = &page->properties[i];
            uint32_t key = pdfmake_arena_intern_name(arena, entry->name, strlen(entry->name));
            pdfmake_obj_t ref = pdfmake_ref(entry->prop_num, 0);
            pdfmake_dict_set(arena, &prop_dict, key, ref);
        }

        prop_key = pdfmake_arena_intern_name(arena, "Properties", 10);
        pdfmake_dict_set(arena, &resources, prop_key, prop_dict);
    }

    /* Build /ExtGState subdictionary if page has graphics states */
    if (page->extgstate_count > 0) {
        gs_dict = pdfmake_dict_new(arena);
        if (gs_dict.kind != PDFMAKE_DICT) return gs_dict;

        for (i = 0; i < page->extgstate_count; i++) {
            pdfmake_extgstate_entry_t *entry = &page->extgstates[i];
            uint32_t key = pdfmake_arena_intern_name(arena, entry->name, strlen(entry->name));
            pdfmake_obj_t ref = pdfmake_ref(entry->extgstate_num, 0);
            pdfmake_dict_set(arena, &gs_dict, key, ref);
        }

        gs_key = pdfmake_arena_intern_name(arena, "ExtGState", 9);
        pdfmake_dict_set(arena, &resources, gs_key, gs_dict);
    }

    return resources;
}

/*----------------------------------------------------------------------------
 * Document finalization
 *--------------------------------------------------------------------------*/

int pdfmake_doc_is_finalized(pdfmake_doc_t *doc) {
    return doc ? doc->finalized : 0;
}

pdfmake_err_t pdfmake_doc_finalize(pdfmake_doc_t *doc) {
    pdfmake_arena_t *arena;
    uint32_t type_key;
    uint32_t kids_key;
    uint32_t count_key;
    uint32_t parent_key;
    uint32_t mediabox_key;
    uint32_t resources_key;
    uint32_t contents_key;
    uint32_t pages_key;
    pdfmake_obj_t pages_dict;
    pdfmake_obj_t kids;
    uint32_t pages_num;
    pdfmake_obj_t pages_ref;
    size_t i;
    size_t j;
    pdfmake_page_t *page;
    pdfmake_obj_t page_dict;
    pdfmake_obj_t mediabox;
    pdfmake_obj_t resources;
    pdfmake_obj_t contents_ref;
    uint32_t rotate_key;
    uint32_t page_num;
    pdfmake_obj_t *pages_obj;
    pdfmake_obj_t catalog;
    pdfmake_outline_item_t *outline;
    uint32_t outlines_num;
    uint32_t outlines_key;
    pdfmake_form_t *form;
    uint32_t acroform_key;
    uint32_t catalog_num;
    pdfmake_err_t ocerr;
    pdfmake_err_t aterr;
    pdfmake_err_t tagerr;
    pdfmake_obj_t *page_obj;
    pdfmake_obj_t annots_arr;
    uint32_t annots_key;

    if (!doc) return PDFMAKE_EINVAL;
    if (doc->finalized) return PDFMAKE_OK;  /* Already finalized */

    arena = pdfmake_doc_arena(doc);

    /* Intern common keys */
    type_key = pdfmake_arena_intern_name(arena, "Type", 4);
    kids_key = pdfmake_arena_intern_name(arena, "Kids", 4);
    count_key = pdfmake_arena_intern_name(arena, "Count", 5);
    parent_key = pdfmake_arena_intern_name(arena, "Parent", 6);
    mediabox_key = pdfmake_arena_intern_name(arena, "MediaBox", 8);
    resources_key = pdfmake_arena_intern_name(arena, "Resources", 9);
    contents_key = pdfmake_arena_intern_name(arena, "Contents", 8);
    pages_key = pdfmake_arena_intern_name(arena, "Pages", 5);

    /* Create /Pages dictionary first (we need its object number for /Parent) */
    pages_dict = pdfmake_dict_new(arena);
    if (pages_dict.kind != PDFMAKE_DICT) return PDFMAKE_ENOMEM;

    pdfmake_dict_set(arena, &pages_dict, type_key, pdfmake_name_cstr(arena, "Pages"));

    /* Placeholder Kids array - will be filled below */
    kids = pdfmake_array_new(arena);
    if (kids.kind != PDFMAKE_ARRAY) return PDFMAKE_ENOMEM;

    /* Add /Pages as indirect object */
    pages_num = pdfmake_doc_add(doc, pages_dict);
    if (pages_num == 0) return PDFMAKE_ENOMEM;
    doc->pages_num = pages_num;

    pages_ref = pdfmake_ref(pages_num, 0);

    /* Create /Page dicts for each page */
    for (i = 0; i < doc->page_count; i++) {
        page = doc->pages[i];

        page_dict = pdfmake_dict_new(arena);
        if (page_dict.kind != PDFMAKE_DICT) return PDFMAKE_ENOMEM;

        /* /Type /Page */
        pdfmake_dict_set(arena, &page_dict, type_key, pdfmake_name_cstr(arena, "Page"));

        /* /Parent -> /Pages ref */
        pdfmake_dict_set(arena, &page_dict, parent_key, pages_ref);

        /* /MediaBox [0 0 width height] */
        mediabox = pdfmake_array_new(arena);
        pdfmake_array_push(arena, &mediabox, pdfmake_int(0));
        pdfmake_array_push(arena, &mediabox, pdfmake_int(0));
        pdfmake_array_push(arena, &mediabox, pdfmake_real(page->width));
        pdfmake_array_push(arena, &mediabox, pdfmake_real(page->height));
        pdfmake_dict_set(arena, &page_dict, mediabox_key, mediabox);

        /* /Resources — imported pages carry a verbatim dict; otherwise
         * compose one from per-page resource arrays. */
        if (page->imported_resources) {
            resources.kind = PDFMAKE_DICT;
            resources.as.dict = page->imported_resources;
        } else {
            resources = build_resources_dict(page);
        }
        pdfmake_dict_set(arena, &page_dict, resources_key, resources);

        /* /Contents (if set) */
        if (page->has_content) {
            contents_ref = pdfmake_ref(page->contents_num, 0);
            pdfmake_dict_set(arena, &page_dict, contents_key, contents_ref);
        }

        /* /Rotate (if non-zero) */
        if (page->rotation != 0) {
            rotate_key = pdfmake_arena_intern_name(arena, "Rotate", 6);
            pdfmake_dict_set(arena, &page_dict, rotate_key, 
                             pdfmake_int(page->rotation));
        }

        /* Add /Page as indirect object */
        page_num = pdfmake_doc_add(doc, page_dict);
        if (page_num == 0) return PDFMAKE_ENOMEM;
        page->page_num = page_num;

        /* Add to Kids array */
        pdfmake_array_push(arena, &kids, pdfmake_ref(page_num, 0));
    }

    /* Update /Pages dict with Kids and Count */
    pages_obj = pdfmake_doc_get(doc, pages_num);
    if (!pages_obj || pages_obj->kind != PDFMAKE_DICT) return PDFMAKE_EINVAL;

    pdfmake_dict_set(arena, pages_obj, kids_key, kids);
    pdfmake_dict_set(arena, pages_obj, count_key, pdfmake_int((int64_t)doc->page_count));

    /* Create /Catalog dictionary */
    catalog = pdfmake_dict_new(arena);
    if (catalog.kind != PDFMAKE_DICT) return PDFMAKE_ENOMEM;

    pdfmake_dict_set(arena, &catalog, type_key, pdfmake_name_cstr(arena, "Catalog"));
    pdfmake_dict_set(arena, &catalog, pages_key, pages_ref);

    /* Add outline if present */
    outline = pdfmake_doc_get_outline(doc);
    if (outline) {
        outlines_num = pdfmake_outline_finalize(doc, outline);
        if (outlines_num > 0) {
            outlines_key = pdfmake_arena_intern_name(arena, "Outlines", 8);
            pdfmake_dict_set(arena, &catalog, outlines_key, pdfmake_ref(outlines_num, 0));
        }
    }

    /* Add AcroForm if present */
    form = pdfmake_doc_get_form(doc);
    if (form && form->form_num > 0) {
        acroform_key = pdfmake_arena_intern_name(arena, "AcroForm", 8);
        pdfmake_dict_set(arena, &catalog, acroform_key, pdfmake_ref(form->form_num, 0));
    }

    /* Add /Catalog as indirect object */
    catalog_num = pdfmake_doc_add(doc, catalog);
    if (catalog_num == 0) return PDFMAKE_ENOMEM;

    /* Set as document root */
    pdfmake_doc_set_root(doc, catalog_num, 0);

    /* Add /OCProperties if document has layers */
    if (doc->ocg_count > 0) {
        ocerr = pdfmake_doc_write_ocproperties(doc);
        if (ocerr != PDFMAKE_OK) return ocerr;
    }

    /* Add /Names/EmbeddedFiles if document has attachments */
    if (doc->attach_count > 0) {
        aterr = pdfmake_doc_write_attachments(doc);
        if (aterr != PDFMAKE_OK) return aterr;
    }

    /* Add structure tree if tagged */
    {
        tagerr = pdfmake_doc_write_struct_tree(doc);
        if (tagerr != PDFMAKE_OK) return tagerr;
    }

    /* Add /Annots arrays to pages that have annotations */
    for (i = 0; i < doc->page_count; i++) {
        page = doc->pages[i];
        if (page->annot_count > 0 && page->page_num > 0) {
            page_obj = pdfmake_doc_get(doc, page->page_num);
            if (page_obj && page_obj->kind == PDFMAKE_DICT) {
                annots_arr = pdfmake_array_new(arena);
                for (j = 0; j < page->annot_count; j++) {
                    pdfmake_array_push(arena, &annots_arr,
                                       pdfmake_ref(page->annots[j], 0));
                }
                annots_key = pdfmake_arena_intern_name(arena, "Annots", 6);
                pdfmake_dict_set(arena, page_obj, annots_key, annots_arr);
            }
        }
    }

    doc->finalized = 1;
    return PDFMAKE_OK;
}
