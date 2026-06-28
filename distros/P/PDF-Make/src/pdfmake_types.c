/*
 * libpdfmake — PDF object constructors and operations.
 *
 * Constructors for all PDF primitive types: null, bool, int, real,
 * name, string, hexstring, array, dict, ref, and stream.
 */

#include "pdfmake_arena.h"
#include <stdlib.h>
#include <string.h>
#include <stdio.h>

/*----------------------------------------------------------------------------
 * Primitive constructors (inline values)
 *--------------------------------------------------------------------------*/

pdfmake_obj_t pdfmake_null(void) {
    pdfmake_obj_t obj = {0};
    obj.kind = PDFMAKE_NULL;
    return obj;
}

pdfmake_obj_t pdfmake_bool(int value) {
    pdfmake_obj_t obj = {0};
    obj.kind = PDFMAKE_BOOL;
    obj.as.i = value ? 1 : 0;
    return obj;
}

pdfmake_obj_t pdfmake_int(int64_t value) {
    pdfmake_obj_t obj = {0};
    obj.kind = PDFMAKE_INT;
    obj.as.i = value;
    return obj;
}

pdfmake_obj_t pdfmake_real(double value) {
    pdfmake_obj_t obj = {0};
    obj.kind = PDFMAKE_REAL;
    obj.as.r = value;
    return obj;
}

/*----------------------------------------------------------------------------
 * Name constructor (interned)
 *--------------------------------------------------------------------------*/

pdfmake_obj_t pdfmake_name(pdfmake_arena_t *arena, const char *bytes, size_t len) {
    pdfmake_obj_t obj = {0};
    obj.kind = PDFMAKE_NAME;

    if (!arena || !bytes) {
        obj.as.name.id = 0;
        return obj;
    }

    /* If len is 0, calculate from null-terminated string. */
    if (len == 0 && bytes[0] != '\0') {
        len = strlen(bytes);
    }

    obj.as.name.id = pdfmake_arena_intern_name(arena, bytes, len);
    return obj;
}

pdfmake_obj_t pdfmake_name_cstr(pdfmake_arena_t *arena, const char *cstr) {
    return pdfmake_name(arena, cstr, cstr ? strlen(cstr) : 0);
}

/*----------------------------------------------------------------------------
 * String constructors (arena-allocated)
 *--------------------------------------------------------------------------*/

pdfmake_obj_t pdfmake_str(pdfmake_arena_t *arena, const char *bytes, size_t len) {
    pdfmake_obj_t obj = {0};
    uint8_t *dup;
    obj.kind = PDFMAKE_STR;

    if (!arena || !bytes || len == 0) {
        obj.as.str.bytes = NULL;
        obj.as.str.len = 0;
        obj.as.str.hex = 0;
        return obj;
    }

    /* Copy bytes into arena with null terminator for C string compatibility. */
    dup = pdfmake_arena_alloc(arena, len + 1);
    if (!dup) {
        obj.as.str.bytes = NULL;
        obj.as.str.len = 0;
        obj.as.str.hex = 0;
        return obj;
    }

    memcpy(dup, bytes, len);
    dup[len] = '\0';  /* null-terminate for C string use */
    obj.as.str.bytes = dup;
    obj.as.str.len = (uint32_t)len;
    obj.as.str.hex = 0;
    return obj;
}

pdfmake_obj_t pdfmake_str_cstr(pdfmake_arena_t *arena, const char *cstr) {
    return pdfmake_str(arena, cstr, cstr ? strlen(cstr) : 0);
}

pdfmake_obj_t pdfmake_hexstr(pdfmake_arena_t *arena, const uint8_t *bytes, size_t len) {
    pdfmake_obj_t obj = pdfmake_str(arena, (const char *)bytes, len);
    obj.as.str.hex = 1;
    return obj;
}

/*----------------------------------------------------------------------------
 * Reference constructor
 *--------------------------------------------------------------------------*/

pdfmake_obj_t pdfmake_ref(uint32_t num, uint16_t gen) {
    pdfmake_obj_t obj = {0};
    obj.kind = PDFMAKE_REF;
    obj.as.ref.num = num;
    obj.as.ref.gen = gen;
    return obj;
}

/*----------------------------------------------------------------------------
 * Array operations
 *--------------------------------------------------------------------------*/

/* Initial array capacity. */
#define ARRAY_INIT_CAP 8

pdfmake_obj_t pdfmake_array_new(pdfmake_arena_t *arena) {
    pdfmake_obj_t obj = {0};
    pdfmake_array_t *arr;
    obj.kind = PDFMAKE_ARRAY;

    if (!arena) {
        obj.as.arr = NULL;
        return obj;
    }

    arr = pdfmake_arena_calloc(arena, sizeof(pdfmake_array_t));
    if (!arr) {
        obj.as.arr = NULL;
        return obj;
    }

    arr->items = pdfmake_arena_alloc(arena, ARRAY_INIT_CAP * sizeof(pdfmake_obj_t));
    if (!arr->items) {
        obj.as.arr = NULL;
        return obj;
    }

    arr->len = 0;
    arr->cap = ARRAY_INIT_CAP;
    obj.as.arr = arr;
    return obj;
}

int pdfmake_array_push(pdfmake_arena_t *arena, pdfmake_obj_t *arr_obj, pdfmake_obj_t item) {
    pdfmake_array_t *arr;
    if (!arena || !arr_obj || arr_obj->kind != PDFMAKE_ARRAY || !arr_obj->as.arr) {
        return 0;
    }

    arr = arr_obj->as.arr;

    /* Grow if needed. */
    if (arr->len >= arr->cap) {
        size_t new_cap = arr->cap * 2;
        pdfmake_obj_t *new_items = pdfmake_arena_alloc(arena, new_cap * sizeof(pdfmake_obj_t));
        if (!new_items) return 0;

        memcpy(new_items, arr->items, arr->len * sizeof(pdfmake_obj_t));
        arr->items = new_items;
        arr->cap = (uint32_t)new_cap;
    }

    arr->items[arr->len++] = item;
    return 1;
}

pdfmake_obj_t *pdfmake_array_get(pdfmake_obj_t *arr_obj, size_t index) {
    pdfmake_array_t *arr;
    if (!arr_obj || arr_obj->kind != PDFMAKE_ARRAY || !arr_obj->as.arr) {
        return NULL;
    }

    arr = arr_obj->as.arr;
    if (index >= arr->len) return NULL;

    return &arr->items[index];
}

int pdfmake_array_set(pdfmake_obj_t *arr_obj, size_t index, pdfmake_obj_t item) {
    pdfmake_array_t *arr;
    if (!arr_obj || arr_obj->kind != PDFMAKE_ARRAY || !arr_obj->as.arr) {
        return 0;
    }

    arr = arr_obj->as.arr;
    if (index >= arr->len) return 0;

    arr->items[index] = item;
    return 1;
}

size_t pdfmake_array_len(pdfmake_obj_t *arr_obj) {
    if (!arr_obj || arr_obj->kind != PDFMAKE_ARRAY || !arr_obj->as.arr) {
        return 0;
    }
    return arr_obj->as.arr->len;
}

/*----------------------------------------------------------------------------
 * Dict operations
 *--------------------------------------------------------------------------*/

/* Initial dict capacity (must be power of 2). */
#define DICT_INIT_CAP 16

/* Load factor threshold: grow when entries/cap > 70%. */
#define DICT_LOAD_FACTOR_NUM 7
#define DICT_LOAD_FACTOR_DEN 10

/* Find slot for key. Returns index, sets *found = 1 if key exists. */
static size_t dict_find_slot(pdfmake_dict_t *dict, uint32_t key, int *found) {
    size_t mask;
    size_t idx;
    size_t first_tombstone;
    size_t i;
    *found = 0;
    if (!dict->entries || dict->cap == 0) return 0;

    mask = dict->cap - 1;
    idx = key & mask;
    first_tombstone = (size_t)-1;

    for (i = 0; i < dict->cap; i++) {
        pdfmake_dict_entry_t *e = &dict->entries[idx];

        if (e->key == 0 && !e->deleted) {
            /* Empty slot. */
            if (first_tombstone != (size_t)-1) {
                return first_tombstone;
            }
            return idx;
        }

        if (e->deleted) {
            /* Tombstone. */
            if (first_tombstone == (size_t)-1) {
                first_tombstone = idx;
            }
        } else if (e->key == key) {
            /* Found existing key. */
            *found = 1;
            return idx;
        }

        idx = (idx + 1) & mask;
    }

    /* Table full (shouldn't happen with proper load factor). */
    return first_tombstone != (size_t)-1 ? first_tombstone : 0;
}

/* Grow dict hash table. */
static int dict_grow(pdfmake_arena_t *arena, pdfmake_dict_t *dict) {
    size_t new_cap = dict->cap * 2;
    pdfmake_dict_entry_t *new_entries;
    size_t mask;
    size_t i;
    if (new_cap == 0) new_cap = DICT_INIT_CAP;

    new_entries = pdfmake_arena_calloc(arena, new_cap * sizeof(pdfmake_dict_entry_t));
    if (!new_entries) return 0;

    /* Rehash all non-deleted entries. */
    mask = new_cap - 1;
    for (i = 0; i < dict->cap; i++) {
        pdfmake_dict_entry_t *e = &dict->entries[i];
        if (e->key != 0 && !e->deleted) {
            size_t idx = e->key & mask;
            while (new_entries[idx].key != 0) {
                idx = (idx + 1) & mask;
            }
            new_entries[idx] = *e;
            new_entries[idx].deleted = 0;
        }
    }

    dict->entries = new_entries;
    dict->cap = (uint32_t)new_cap;
    dict->tombstones = 0;
    return 1;
}

pdfmake_obj_t pdfmake_dict_new(pdfmake_arena_t *arena) {
    pdfmake_obj_t obj = {0};
    pdfmake_dict_t *dict;
    obj.kind = PDFMAKE_DICT;

    if (!arena) {
        obj.as.dict = NULL;
        return obj;
    }

    dict = pdfmake_arena_calloc(arena, sizeof(pdfmake_dict_t));
    if (!dict) {
        obj.as.dict = NULL;
        return obj;
    }

    dict->entries = pdfmake_arena_calloc(arena, DICT_INIT_CAP * sizeof(pdfmake_dict_entry_t));
    if (!dict->entries) {
        obj.as.dict = NULL;
        return obj;
    }

    dict->cap = DICT_INIT_CAP;
    dict->len = 0;
    dict->tombstones = 0;
    dict->next_order = 0;
    obj.as.dict = dict;
    return obj;
}

int pdfmake_dict_set(pdfmake_arena_t *arena, pdfmake_obj_t *dict_obj, uint32_t key, pdfmake_obj_t value) {
    pdfmake_dict_t *dict;
    int found;
    size_t idx;
    if (!arena || !dict_obj || dict_obj->kind != PDFMAKE_DICT || !dict_obj->as.dict || key == 0) {
        return 0;
    }

    dict = dict_obj->as.dict;

    /* Check load factor and grow if needed. */
    if ((dict->len + dict->tombstones + 1) * DICT_LOAD_FACTOR_DEN > dict->cap * DICT_LOAD_FACTOR_NUM) {
        if (!dict_grow(arena, dict)) return 0;
    }

    idx = dict_find_slot(dict, key, &found);

    if (found) {
        /* Update existing. */
        dict->entries[idx].value = value;
    } else {
        /* Insert new. */
        if (dict->entries[idx].deleted) {
            dict->tombstones--;
        }
        dict->entries[idx].key = key;
        dict->entries[idx].value = value;
        dict->entries[idx].order = dict->next_order++;
        dict->entries[idx].deleted = 0;
        dict->len++;
    }

    return 1;
}

pdfmake_obj_t *pdfmake_dict_get(pdfmake_obj_t *dict_obj, uint32_t key) {
    pdfmake_dict_t *dict;
    int found;
    size_t idx;
    if (!dict_obj || dict_obj->kind != PDFMAKE_DICT || !dict_obj->as.dict || key == 0) {
        return NULL;
    }

    dict = dict_obj->as.dict;
    idx = dict_find_slot(dict, key, &found);

    if (found) {
        return &dict->entries[idx].value;
    }
    return NULL;
}

int pdfmake_dict_has(pdfmake_obj_t *dict_obj, uint32_t key) {
    return pdfmake_dict_get(dict_obj, key) != NULL;
}

int pdfmake_dict_del(pdfmake_obj_t *dict_obj, uint32_t key) {
    pdfmake_dict_t *dict;
    int found;
    size_t idx;
    if (!dict_obj || dict_obj->kind != PDFMAKE_DICT || !dict_obj->as.dict || key == 0) {
        return 0;
    }

    dict = dict_obj->as.dict;
    idx = dict_find_slot(dict, key, &found);

    if (found) {
        dict->entries[idx].deleted = 1;
        dict->entries[idx].key = 0;
        dict->len--;
        dict->tombstones++;
        return 1;
    }
    return 0;
}

size_t pdfmake_dict_len(pdfmake_obj_t *dict_obj) {
    if (!dict_obj || dict_obj->kind != PDFMAKE_DICT || !dict_obj->as.dict) {
        return 0;
    }
    return dict_obj->as.dict->len;
}

/* Iterator: return entries in insertion order. */
typedef struct {
    pdfmake_dict_t *dict;
    uint32_t        current_order;
    size_t          visited;
} pdfmake_dict_iter_state_t;

void pdfmake_dict_iter_init(pdfmake_dict_iter_t *iter, pdfmake_obj_t *dict_obj) {
    iter->dict_obj = dict_obj;
    iter->index = 0;
    iter->current_key = 0;
    iter->current_value = NULL;
}

int pdfmake_dict_iter_next(pdfmake_dict_iter_t *iter) {
    pdfmake_dict_t *dict;
    uint32_t best_order;
    size_t best_idx;
    size_t i;
    if (!iter || !iter->dict_obj || iter->dict_obj->kind != PDFMAKE_DICT || !iter->dict_obj->as.dict) {
        return 0;
    }

    dict = iter->dict_obj->as.dict;

    /* Find next entry with smallest order >= current position.
     * This is O(n²) worst case but maintains insertion order.
     * For 10k entries, consider caching sorted keys. */

    best_order = UINT32_MAX;
    best_idx = (size_t)-1;

    for (i = 0; i < dict->cap; i++) {
        pdfmake_dict_entry_t *e = &dict->entries[i];
        if (e->key != 0 && !e->deleted) {
            if (e->order >= iter->index && e->order < best_order) {
                best_order = e->order;
                best_idx = i;
            }
        }
    }

    if (best_idx == (size_t)-1) {
        return 0;
    }

    iter->current_key = dict->entries[best_idx].key;
    iter->current_value = &dict->entries[best_idx].value;
    iter->index = best_order + 1;
    return 1;
}

/*----------------------------------------------------------------------------
 * Stream operations
 *--------------------------------------------------------------------------*/

pdfmake_obj_t pdfmake_stream_new(pdfmake_arena_t *arena) {
    pdfmake_obj_t obj = {0};
    pdfmake_stream_t *stream;
    pdfmake_obj_t dict;
    obj.kind = PDFMAKE_STREAM;

    if (!arena) {
        obj.as.stream = NULL;
        return obj;
    }

    stream = pdfmake_arena_calloc(arena, sizeof(pdfmake_stream_t));
    if (!stream) {
        obj.as.stream = NULL;
        return obj;
    }

    /* Initialize the stream's dict. */
    dict = pdfmake_dict_new(arena);
    if (dict.as.dict) {
        stream->dict = dict.as.dict;
    }

    stream->raw = NULL;
    stream->raw_len = 0;
    stream->filtered = 0;

    obj.as.stream = stream;
    return obj;
}

int pdfmake_stream_set_data(pdfmake_arena_t *arena, pdfmake_obj_t *stream_obj,
                            const uint8_t *data, size_t len) {
    pdfmake_stream_t *stream;
    if (!arena || !stream_obj || stream_obj->kind != PDFMAKE_STREAM || !stream_obj->as.stream) {
        return 0;
    }

    stream = stream_obj->as.stream;

    if (data && len > 0) {
        uint8_t *dup = pdfmake_arena_memdup(arena, data, len);
        if (!dup) return 0;
        stream->raw = dup;
        stream->raw_len = (uint32_t)len;
    } else {
        stream->raw = NULL;
        stream->raw_len = 0;
    }

    return 1;
}

pdfmake_dict_t *pdfmake_stream_dict(pdfmake_obj_t *stream_obj) {
    if (!stream_obj || stream_obj->kind != PDFMAKE_STREAM || !stream_obj->as.stream) {
        return NULL;
    }
    return stream_obj->as.stream->dict;
}

int pdfmake_stream_set_flate(pdfmake_arena_t *arena, pdfmake_obj_t *stream_obj) {
    pdfmake_stream_t *stream;
    uint32_t filter_key;
    pdfmake_obj_t filter_name;
    pdfmake_obj_t dict_obj;
    if (!arena || !stream_obj || stream_obj->kind != PDFMAKE_STREAM || !stream_obj->as.stream) {
        return 0;
    }

    stream = stream_obj->as.stream;
    if (!stream->dict) return 0;

    /* Set /Filter to /FlateDecode */
    filter_key = pdfmake_arena_intern_name(arena, "Filter", 6);
    if (filter_key == 0) return 0;

    filter_name = pdfmake_name_cstr(arena, "FlateDecode");
    dict_obj.kind = PDFMAKE_DICT;
    dict_obj.as.dict = stream->dict;
    if (!pdfmake_dict_set(arena, &dict_obj, filter_key, filter_name)) {
        return 0;
    }

    /* Mark stream as needing compression (filtered=0 means raw data to encode) */
    stream->filtered = 0;
    return 1;
}

/*----------------------------------------------------------------------------
 * Type checking and accessors
 *--------------------------------------------------------------------------*/

int pdfmake_is_null(pdfmake_obj_t *obj) {
    return obj && obj->kind == PDFMAKE_NULL;
}

int pdfmake_is_bool(pdfmake_obj_t *obj) {
    return obj && obj->kind == PDFMAKE_BOOL;
}

int pdfmake_is_int(pdfmake_obj_t *obj) {
    return obj && obj->kind == PDFMAKE_INT;
}

int pdfmake_is_real(pdfmake_obj_t *obj) {
    return obj && obj->kind == PDFMAKE_REAL;
}

int pdfmake_is_numeric(pdfmake_obj_t *obj) {
    return obj && (obj->kind == PDFMAKE_INT || obj->kind == PDFMAKE_REAL);
}

int pdfmake_is_name(pdfmake_obj_t *obj) {
    return obj && obj->kind == PDFMAKE_NAME;
}

int pdfmake_is_str(pdfmake_obj_t *obj) {
    return obj && obj->kind == PDFMAKE_STR;
}

int pdfmake_is_array(pdfmake_obj_t *obj) {
    return obj && obj->kind == PDFMAKE_ARRAY;
}

int pdfmake_is_dict(pdfmake_obj_t *obj) {
    return obj && obj->kind == PDFMAKE_DICT;
}

int pdfmake_is_stream(pdfmake_obj_t *obj) {
    return obj && obj->kind == PDFMAKE_STREAM;
}

int pdfmake_is_ref(pdfmake_obj_t *obj) {
    return obj && obj->kind == PDFMAKE_REF;
}

int pdfmake_get_bool(pdfmake_obj_t *obj) {
    return (obj && obj->kind == PDFMAKE_BOOL) ? (int)obj->as.i : 0;
}

int64_t pdfmake_get_int(pdfmake_obj_t *obj) {
    if (!obj) return 0;
    if (obj->kind == PDFMAKE_INT) return obj->as.i;
    if (obj->kind == PDFMAKE_REAL) return (int64_t)obj->as.r;
    return 0;
}

double pdfmake_get_real(pdfmake_obj_t *obj) {
    if (!obj) return 0.0;
    if (obj->kind == PDFMAKE_REAL) return obj->as.r;
    if (obj->kind == PDFMAKE_INT) return (double)obj->as.i;
    return 0.0;
}

double pdfmake_get_number(pdfmake_obj_t *obj) {
    return pdfmake_get_real(obj);
}

const char *pdfmake_get_name_bytes(pdfmake_arena_t *arena, pdfmake_obj_t *obj) {
    if (!arena || !obj || obj->kind != PDFMAKE_NAME) return NULL;
    return pdfmake_arena_name_bytes(arena, obj->as.name.id);
}

const uint8_t *pdfmake_get_str_bytes(pdfmake_obj_t *obj, size_t *len_out) {
    if (!obj || obj->kind != PDFMAKE_STR) {
        if (len_out) *len_out = 0;
        return NULL;
    }
    if (len_out) *len_out = obj->as.str.len;
    return obj->as.str.bytes;
}

int pdfmake_str_is_hex(pdfmake_obj_t *obj) {
    return (obj && obj->kind == PDFMAKE_STR) ? obj->as.str.hex : 0;
}
