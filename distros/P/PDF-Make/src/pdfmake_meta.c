/*
 * pdfmake_meta.c — Document Information Dictionary implementation.
 */

#include "pdfmake_meta.h"
#include "pdfmake_arena.h"
#include <stdlib.h>
#include <string.h>
#include <stdio.h>

/*----------------------------------------------------------------------------
 * PDF date formatting (§7.9.4)
 *
 * Format: D:YYYYMMDDHHmmSSOHH'mm'
 *   YYYY = 4-digit year
 *   MM   = month (01-12)
 *   DD   = day (01-31)
 *   HH   = hour (00-23)
 *   mm   = minute (00-59)
 *   SS   = second (00-59)
 *   O    = relationship to UTC: +, -, or Z
 *   HH'mm' = timezone offset (only if O is + or -)
 *--------------------------------------------------------------------------*/

char *pdfmake_format_date(time_t t, char *buf, size_t buflen) {
    struct tm local_tm;
    struct tm utc_tm;
    time_t local_epoch;
    time_t utc_epoch;
    long offset_secs;
    int offset_mins;
    int n;
    char sign;
    int off_hours;
    int off_mins;
    int n2;

    if (!buf || buflen < 24) return NULL;

#ifdef _WIN32
    localtime_s(&local_tm, &t);
#else
    localtime_r(&t, &local_tm);
#endif

    /* Get UTC time to compute offset */
#ifdef _WIN32
    gmtime_s(&utc_tm, &t);
#else
    gmtime_r(&t, &utc_tm);
#endif

    /* Compute timezone offset in minutes */
    local_epoch = mktime(&local_tm);
    utc_epoch = mktime(&utc_tm);
    offset_secs = (long)difftime(local_epoch, utc_epoch);
    offset_mins = (int)(offset_secs / 60);

    /* Format base date part */
    n = snprintf(buf, buflen, "D:%04d%02d%02d%02d%02d%02d",
                 local_tm.tm_year + 1900,
                 local_tm.tm_mon + 1,
                 local_tm.tm_mday,
                 local_tm.tm_hour,
                 local_tm.tm_min,
                 local_tm.tm_sec);

    if (n < 0 || (size_t)n >= buflen) return NULL;

    /* Append timezone */
    if (offset_mins == 0) {
        /* UTC */
        if ((size_t)n + 1 >= buflen) return NULL;
        buf[n++] = 'Z';
        buf[n] = '\0';
    } else {
        /* Offset: +HH'mm' or -HH'mm' */
        sign = (offset_mins >= 0) ? '+' : '-';
        if (offset_mins < 0) offset_mins = -offset_mins;
        off_hours = offset_mins / 60;
        off_mins = offset_mins % 60;

        n2 = snprintf(buf + n, buflen - (size_t)n, "%c%02d'%02d'",
                      sign, off_hours, off_mins);
        if (n2 < 0 || (size_t)(n + n2) >= buflen) return NULL;
    }

    return buf;
}

char *pdfmake_format_date_utc(time_t t, char *buf, size_t buflen) {
    struct tm utc_tm;
    int n;

    if (!buf || buflen < 18) return NULL;

#ifdef _WIN32
    gmtime_s(&utc_tm, &t);
#else
    gmtime_r(&t, &utc_tm);
#endif

    n = snprintf(buf, buflen, "D:%04d%02d%02d%02d%02d%02dZ",
                 utc_tm.tm_year + 1900,
                 utc_tm.tm_mon + 1,
                 utc_tm.tm_mday,
                 utc_tm.tm_hour,
                 utc_tm.tm_min,
                 utc_tm.tm_sec);

    if (n < 0 || (size_t)n >= buflen) return NULL;

    return buf;
}

/*----------------------------------------------------------------------------
 * Internal: ensure doc has an Info dictionary
 *--------------------------------------------------------------------------*/

static pdfmake_obj_t *ensure_info_dict(pdfmake_doc_t *doc) {
    pdfmake_arena_t *arena;
    pdfmake_obj_t info;
    uint32_t num;
    if (!doc) return NULL;

    /* If we already have an Info object, return its dict */
    if (doc->info_num != 0) {
        pdfmake_obj_t *obj = pdfmake_doc_get(doc, doc->info_num);
        if (obj && obj->kind == PDFMAKE_DICT) {
            return obj;
        }
    }

    /* Create a new Info dictionary */
    arena = pdfmake_doc_arena(doc);
    info = pdfmake_dict_new(arena);
    if (info.kind != PDFMAKE_DICT) return NULL;

    /* Add to document as indirect object */
    num = pdfmake_doc_add(doc, info);
    if (num == 0) return NULL;

    /* Set as Info reference in trailer */
    pdfmake_doc_set_info(doc, num, 0);

    /* Return pointer to the dict in the indirect object table */
    return pdfmake_doc_get(doc, num);
}

/*----------------------------------------------------------------------------
 * Generic metadata set/get
 *--------------------------------------------------------------------------*/

pdfmake_err_t pdfmake_meta_set(pdfmake_doc_t *doc, const char *key, const char *value) {
    pdfmake_obj_t *info;
    pdfmake_arena_t *arena;
    uint32_t key_id;
    pdfmake_obj_t val;

    if (!doc || !key) return PDFMAKE_EINVAL;

    info = ensure_info_dict(doc);
    if (!info) return PDFMAKE_ENOMEM;

    arena = pdfmake_doc_arena(doc);

    /* Intern the key name */
    key_id = pdfmake_arena_intern_name(arena, key, strlen(key));
    if (key_id == 0) return PDFMAKE_ENOMEM;

    /* Create string value (or null if value is NULL) */
    if (value) {
        val = pdfmake_str_cstr(arena, value);
        if (val.kind != PDFMAKE_STR) return PDFMAKE_ENOMEM;
    } else {
        val = pdfmake_null();
    }

    /* Set in dict */
    if (!pdfmake_dict_set(arena, info, key_id, val)) {
        return PDFMAKE_ENOMEM;
    }

    return PDFMAKE_OK;
}

const char *pdfmake_meta_get(pdfmake_doc_t *doc, const char *key) {
    pdfmake_obj_t *info;
    pdfmake_arena_t *arena;
    uint32_t key_id;
    pdfmake_obj_t *val;
    size_t len;
    const uint8_t *bytes;

    if (!doc || !key || doc->info_num == 0) return NULL;

    info = pdfmake_doc_get(doc, doc->info_num);
    if (!info || info->kind != PDFMAKE_DICT) return NULL;

    arena = pdfmake_doc_arena(doc);

    /* Intern the key name to look it up */
    key_id = pdfmake_arena_intern_name(arena, key, strlen(key));
    if (key_id == 0) return NULL;

    val = pdfmake_dict_get(info, key_id);
    if (!val || val->kind != PDFMAKE_STR) return NULL;

    /* Return the string bytes (null-terminated by str_cstr) */
    bytes = pdfmake_get_str_bytes(val, &len);
    (void)len;
    return (const char *)bytes;
}

/*----------------------------------------------------------------------------
 * Date field setters
 *--------------------------------------------------------------------------*/

pdfmake_err_t pdfmake_meta_set_creation_date(pdfmake_doc_t *doc, time_t t) {
    char buf[32];
    if (!pdfmake_format_date(t, buf, sizeof(buf))) {
        return PDFMAKE_EINVAL;
    }
    return pdfmake_meta_set(doc, PDFMAKE_META_CREATION_DATE, buf);
}

pdfmake_err_t pdfmake_meta_set_mod_date(pdfmake_doc_t *doc, time_t t) {
    char buf[32];
    if (!pdfmake_format_date(t, buf, sizeof(buf))) {
        return PDFMAKE_EINVAL;
    }
    return pdfmake_meta_set(doc, PDFMAKE_META_MOD_DATE, buf);
}

/*----------------------------------------------------------------------------
 * Trapped field (name value)
 *--------------------------------------------------------------------------*/

pdfmake_err_t pdfmake_meta_set_trapped(pdfmake_doc_t *doc, pdfmake_trapped_t trapped) {
    pdfmake_obj_t *info;
    pdfmake_arena_t *arena;
    uint32_t key_id;
    const char *name_str;
    pdfmake_obj_t val;

    if (!doc) return PDFMAKE_EINVAL;

    info = ensure_info_dict(doc);
    if (!info) return PDFMAKE_ENOMEM;

    arena = pdfmake_doc_arena(doc);

    /* Intern the Trapped key */
    key_id = pdfmake_arena_intern_name(arena, PDFMAKE_META_TRAPPED, 7);
    if (key_id == 0) return PDFMAKE_ENOMEM;

    /* Create name value */
    switch (trapped) {
        case PDFMAKE_TRAPPED_TRUE:    name_str = "True"; break;
        case PDFMAKE_TRAPPED_FALSE:   name_str = "False"; break;
        default:                      name_str = "Unknown"; break;
    }

    val = pdfmake_name_cstr(arena, name_str);
    if (val.kind != PDFMAKE_NAME) return PDFMAKE_ENOMEM;

    if (!pdfmake_dict_set(arena, info, key_id, val)) {
        return PDFMAKE_ENOMEM;
    }

    return PDFMAKE_OK;
}

pdfmake_trapped_t pdfmake_meta_get_trapped(pdfmake_doc_t *doc) {
    pdfmake_obj_t *info;
    pdfmake_arena_t *arena;
    uint32_t key_id;
    pdfmake_obj_t *val;
    const char *name;

    if (!doc || doc->info_num == 0) return PDFMAKE_TRAPPED_UNKNOWN;

    info = pdfmake_doc_get(doc, doc->info_num);
    if (!info || info->kind != PDFMAKE_DICT) return PDFMAKE_TRAPPED_UNKNOWN;

    arena = pdfmake_doc_arena(doc);

    key_id = pdfmake_arena_intern_name(arena, PDFMAKE_META_TRAPPED, 7);
    if (key_id == 0) return PDFMAKE_TRAPPED_UNKNOWN;

    val = pdfmake_dict_get(info, key_id);
    if (!val || val->kind != PDFMAKE_NAME) return PDFMAKE_TRAPPED_UNKNOWN;

    name = pdfmake_get_name_bytes(arena, val);
    if (!name) return PDFMAKE_TRAPPED_UNKNOWN;

    if (strcmp(name, "True") == 0) return PDFMAKE_TRAPPED_TRUE;
    if (strcmp(name, "False") == 0) return PDFMAKE_TRAPPED_FALSE;
    return PDFMAKE_TRAPPED_UNKNOWN;
}

/*----------------------------------------------------------------------------
 * Auto-metadata (called during write)
 *--------------------------------------------------------------------------*/

/* Producer string constant */
#ifndef PDFMAKE_VERSION
#define PDFMAKE_VERSION "0.05"
#endif

void pdfmake_meta_auto_fill(pdfmake_doc_t *doc) {
    time_t now;

    if (!doc) return;

    now = time(NULL);

    /* Set Producer if not already set */
    if (!pdfmake_meta_get(doc, PDFMAKE_META_PRODUCER)) {
        pdfmake_meta_set(doc, PDFMAKE_META_PRODUCER, "PDF-Make/" PDFMAKE_VERSION);
    }

    /* Set CreationDate if not already set */
    if (!pdfmake_meta_get(doc, PDFMAKE_META_CREATION_DATE)) {
        pdfmake_meta_set_creation_date(doc, now);
    }

    /* Set ModDate if not already set.  Callers who need to refresh it
     * (e.g. after an edit) should call pdfmake_meta_set_mod_date
     * explicitly; leaving it untouched here keeps the serialized bytes
     * deterministic across multiple writes of the same doc — required
     * for the two-pass TSA signing flow where pass 1's RSA imprint must
     * match pass 2's RSA bytes. */
    if (!pdfmake_meta_get(doc, PDFMAKE_META_MOD_DATE)) {
        pdfmake_meta_set_mod_date(doc, now);
    }
}
