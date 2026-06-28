/*
 * pdfmake_meta.h — Document Information Dictionary (§14.3.3).
 *
 * Provides functions to set and get standard metadata fields like
 * Title, Author, Subject, Keywords, Creator, Producer, CreationDate,
 * ModDate, and Trapped.
 *
 * PDF date format (§7.9.4): D:YYYYMMDDHHmmSSOHH'mm'
 *   - YYYY = year, MM = month (01-12), DD = day (01-31)
 *   - HH = hour (00-23), mm = minute (00-59), SS = second (00-59)
 *   - O = timezone relation (+, -, Z)
 *   - HH'mm' = timezone offset hours and minutes
 */

#ifndef PDFMAKE_META_H
#define PDFMAKE_META_H

#include "pdfmake_types.h"
#include "pdfmake_doc.h"
#include <time.h>

#ifdef __cplusplus
extern "C" {
#endif

/*----------------------------------------------------------------------------
 * Standard metadata keys (§14.3.3)
 *--------------------------------------------------------------------------*/

#define PDFMAKE_META_TITLE        "Title"
#define PDFMAKE_META_AUTHOR       "Author"
#define PDFMAKE_META_SUBJECT      "Subject"
#define PDFMAKE_META_KEYWORDS     "Keywords"
#define PDFMAKE_META_CREATOR      "Creator"
#define PDFMAKE_META_PRODUCER     "Producer"
#define PDFMAKE_META_CREATION_DATE "CreationDate"
#define PDFMAKE_META_MOD_DATE     "ModDate"
#define PDFMAKE_META_TRAPPED      "Trapped"

/*----------------------------------------------------------------------------
 * PDF date formatting (§7.9.4)
 *--------------------------------------------------------------------------*/

/*
 * Format a time_t as a PDF date string: D:YYYYMMDDHHmmSSOHH'mm'
 * Uses local timezone. Buffer must be at least 24 bytes.
 * Returns pointer to buf on success, NULL on error.
 */
char *pdfmake_format_date(time_t t, char *buf, size_t buflen);

/*
 * Format a time_t as a PDF date string in UTC: D:YYYYMMDDHHMMSSZ
 * Buffer must be at least 18 bytes.
 * Returns pointer to buf on success, NULL on error.
 */
char *pdfmake_format_date_utc(time_t t, char *buf, size_t buflen);

/*----------------------------------------------------------------------------
 * Generic metadata set/get
 *--------------------------------------------------------------------------*/

/*
 * Set a metadata field on the document's /Info dictionary.
 * Creates the /Info dictionary if it doesn't exist.
 * Key should be one of the standard keys (Title, Author, etc.).
 * Value is a string; dates should use pdfmake_format_date().
 * Returns PDFMAKE_OK on success.
 */
pdfmake_err_t pdfmake_meta_set(pdfmake_doc_t *doc, const char *key, const char *value);

/*
 * Get a metadata field from the document's /Info dictionary.
 * Returns the string value, or NULL if not set or key not found.
 * The returned string is owned by the document and must not be freed.
 */
const char *pdfmake_meta_get(pdfmake_doc_t *doc, const char *key);

/*----------------------------------------------------------------------------
 * Convenience setters (string fields)
 *--------------------------------------------------------------------------*/

static PDFMAKE_INLINE pdfmake_err_t pdfmake_meta_set_title(pdfmake_doc_t *doc, const char *v) {
    return pdfmake_meta_set(doc, PDFMAKE_META_TITLE, v);
}

static PDFMAKE_INLINE pdfmake_err_t pdfmake_meta_set_author(pdfmake_doc_t *doc, const char *v) {
    return pdfmake_meta_set(doc, PDFMAKE_META_AUTHOR, v);
}

static PDFMAKE_INLINE pdfmake_err_t pdfmake_meta_set_subject(pdfmake_doc_t *doc, const char *v) {
    return pdfmake_meta_set(doc, PDFMAKE_META_SUBJECT, v);
}

static PDFMAKE_INLINE pdfmake_err_t pdfmake_meta_set_keywords(pdfmake_doc_t *doc, const char *v) {
    return pdfmake_meta_set(doc, PDFMAKE_META_KEYWORDS, v);
}

static PDFMAKE_INLINE pdfmake_err_t pdfmake_meta_set_creator(pdfmake_doc_t *doc, const char *v) {
    return pdfmake_meta_set(doc, PDFMAKE_META_CREATOR, v);
}

static PDFMAKE_INLINE pdfmake_err_t pdfmake_meta_set_producer(pdfmake_doc_t *doc, const char *v) {
    return pdfmake_meta_set(doc, PDFMAKE_META_PRODUCER, v);
}

/*----------------------------------------------------------------------------
 * Convenience setters (date fields)
 *--------------------------------------------------------------------------*/

/*
 * Set CreationDate from a time_t value.
 * Formats as PDF date string with local timezone.
 */
pdfmake_err_t pdfmake_meta_set_creation_date(pdfmake_doc_t *doc, time_t t);

/*
 * Set ModDate from a time_t value.
 * Formats as PDF date string with local timezone.
 */
pdfmake_err_t pdfmake_meta_set_mod_date(pdfmake_doc_t *doc, time_t t);

/*----------------------------------------------------------------------------
 * Convenience getters
 *--------------------------------------------------------------------------*/

static PDFMAKE_INLINE const char *pdfmake_meta_get_title(pdfmake_doc_t *doc) {
    return pdfmake_meta_get(doc, PDFMAKE_META_TITLE);
}

static PDFMAKE_INLINE const char *pdfmake_meta_get_author(pdfmake_doc_t *doc) {
    return pdfmake_meta_get(doc, PDFMAKE_META_AUTHOR);
}

static PDFMAKE_INLINE const char *pdfmake_meta_get_subject(pdfmake_doc_t *doc) {
    return pdfmake_meta_get(doc, PDFMAKE_META_SUBJECT);
}

static PDFMAKE_INLINE const char *pdfmake_meta_get_keywords(pdfmake_doc_t *doc) {
    return pdfmake_meta_get(doc, PDFMAKE_META_KEYWORDS);
}

static PDFMAKE_INLINE const char *pdfmake_meta_get_creator(pdfmake_doc_t *doc) {
    return pdfmake_meta_get(doc, PDFMAKE_META_CREATOR);
}

static PDFMAKE_INLINE const char *pdfmake_meta_get_producer(pdfmake_doc_t *doc) {
    return pdfmake_meta_get(doc, PDFMAKE_META_PRODUCER);
}

static PDFMAKE_INLINE const char *pdfmake_meta_get_creation_date(pdfmake_doc_t *doc) {
    return pdfmake_meta_get(doc, PDFMAKE_META_CREATION_DATE);
}

static PDFMAKE_INLINE const char *pdfmake_meta_get_mod_date(pdfmake_doc_t *doc) {
    return pdfmake_meta_get(doc, PDFMAKE_META_MOD_DATE);
}

/*----------------------------------------------------------------------------
 * Trapped field (name value, not string)
 *--------------------------------------------------------------------------*/

typedef enum {
    PDFMAKE_TRAPPED_UNKNOWN = 0,
    PDFMAKE_TRAPPED_TRUE    = 1,
    PDFMAKE_TRAPPED_FALSE   = 2
} pdfmake_trapped_t;

pdfmake_err_t pdfmake_meta_set_trapped(pdfmake_doc_t *doc, pdfmake_trapped_t trapped);
pdfmake_trapped_t pdfmake_meta_get_trapped(pdfmake_doc_t *doc);

/*----------------------------------------------------------------------------
 * Auto-metadata (called during write)
 *--------------------------------------------------------------------------*/

/*
 * Set Producer to "PDF-Make/VERSION" if not already set.
 * Set CreationDate to current time if not already set.
 * Set ModDate to current time.
 * Called automatically by pdfmake_doc_write().
 */
void pdfmake_meta_auto_fill(pdfmake_doc_t *doc);

#ifdef __cplusplus
}
#endif

#endif /* PDFMAKE_META_H */
