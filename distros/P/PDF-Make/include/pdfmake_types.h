/*
 * libpdfmake — shared type definitions.
 *
 * Phase 01: error enum + opaque doc forward declaration.
 * Phase 02: tagged-union pdfmake_obj_t, arena allocator, all PDF primitive
 *           kinds. See the "phase 02: primitive types" marker below for
 *           the drop-in point.
 */

#ifndef PDFMAKE_TYPES_H
#define PDFMAKE_TYPES_H

#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

/* Portable "inline" keyword: present in C99 but not in C89.
 * Map to compiler-specific extensions where available; otherwise
 * fall back to `static` (which still works, just loses the hint). */
#ifndef PDFMAKE_INLINE
#  if defined(__cplusplus) || (defined(__STDC_VERSION__) && __STDC_VERSION__ >= 199901L)
#    define PDFMAKE_INLINE inline
#  elif defined(__GNUC__) || defined(__clang__)
#    define PDFMAKE_INLINE __inline__
#  elif defined(_MSC_VER)
#    define PDFMAKE_INLINE __inline
#  else
#    define PDFMAKE_INLINE /* nothing */
#  endif
#endif

/* Portable va_copy: standardised in C99. Pre-C99 compilers usually expose
 * the same primitive under __va_copy (or, in practice, simple assignment
 * works on most ABIs). Mirror what perl.h does. */
#ifndef PDFMAKE_VA_COPY
#  if (defined(__STDC_VERSION__) && __STDC_VERSION__ >= 199901L) || \
      defined(__cplusplus)
#    define PDFMAKE_VA_COPY(dst, src) va_copy((dst), (src))
#  elif defined(__va_copy)
#    define PDFMAKE_VA_COPY(dst, src) __va_copy((dst), (src))
#  elif defined(__GNUC__) || defined(__clang__)
#    define PDFMAKE_VA_COPY(dst, src) __builtin_va_copy((dst), (src))
#  else
#    define PDFMAKE_VA_COPY(dst, src) ((dst) = (src))
#  endif
#endif

/* Error codes returned from libpdfmake entry points.
 * Additional codes are appended in later phases; never renumber. */
typedef enum {
    PDFMAKE_OK      = 0,
    PDFMAKE_ENOMEM  = 1,
    PDFMAKE_EINVAL  = 2,
    PDFMAKE_EIO     = 3
} pdfmake_err_t;

/* Opaque document handle. Defined in pdfmake_doc.h. */
#ifndef PDFMAKE_DOC_T_DEFINED
#define PDFMAKE_DOC_T_DEFINED
typedef struct pdfmake_doc pdfmake_doc_t;
#endif

/*============================================================================
 * Phase 02: PDF primitive types (§7.3)
 *===========================================================================*/

/* PDF object kinds — one per §7.3 type.
 * Never renumber; wire protocol and type checks depend on stable values. */
typedef enum {
    PDFMAKE_NULL    = 0,   /* §7.3.9 */
    PDFMAKE_BOOL    = 1,   /* §7.3.2 */
    PDFMAKE_INT     = 2,   /* §7.3.3 integer */
    PDFMAKE_REAL    = 3,   /* §7.3.3 real */
    PDFMAKE_NAME    = 4,   /* §7.3.5 */
    PDFMAKE_STR     = 5,   /* §7.3.4 literal or hex string */
    PDFMAKE_ARRAY   = 6,   /* §7.3.6 */
    PDFMAKE_DICT    = 7,   /* §7.3.7 */
    PDFMAKE_STREAM  = 8,   /* §7.3.8 */
    PDFMAKE_REF     = 9    /* §7.3.10 indirect reference */
} pdfmake_kind_t;

/* Indirect object reference: "N G R" in PDF syntax. */
typedef struct {
    uint32_t num;   /* object number */
    uint16_t gen;   /* generation number */
} pdfmake_ref_t;

/* Interned name: integer id mapped to bytes via arena name table.
 * Equality is integer compare — no strcmp in hot paths. */
typedef struct {
    uint32_t id;    /* index into arena name table */
} pdfmake_name_t;

/* PDF string (literal or hex). Bytes are arena-allocated. */
typedef struct {
    const uint8_t *bytes;   /* raw bytes (not null-terminated) */
    uint32_t       len;     /* byte count */
    uint8_t        hex;     /* 1 = hex string, 0 = literal string */
} pdfmake_string_t;

/* Forward declarations for composites. */
typedef struct pdfmake_array  pdfmake_array_t;
typedef struct pdfmake_dict   pdfmake_dict_t;
typedef struct pdfmake_stream pdfmake_stream_t;

/* Tagged union for any PDF object (§7.3).
 * Size: 24 bytes — kind (4) + padding (4) + union (16).
 * Inline ints/reals for cache friendliness; composites are pointers. */
typedef struct pdfmake_obj {
    pdfmake_kind_t kind;
    union {
        int                 b;      /* PDFMAKE_BOOL */
        int64_t             i;      /* PDFMAKE_INT */
        double              r;      /* PDFMAKE_REAL */
        pdfmake_name_t      name;   /* PDFMAKE_NAME */
        pdfmake_string_t    str;    /* PDFMAKE_STRING */
        pdfmake_array_t    *arr;    /* PDFMAKE_ARRAY */
        pdfmake_dict_t     *dict;   /* PDFMAKE_DICT */
        pdfmake_stream_t   *stream; /* PDFMAKE_STREAM */
        pdfmake_ref_t       ref;    /* PDFMAKE_REF */
    } as;
} pdfmake_obj_t;

/* Dynamic array of PDF objects. Grows on push, amortized O(1). */
struct pdfmake_array {
    pdfmake_obj_t *items;   /* arena-allocated */
    uint32_t       len;     /* current count */
    uint32_t       cap;     /* allocated slots */
};

/* Dictionary entry for open-addressing hash. */
typedef struct {
    uint32_t      key;      /* name id (0 = empty slot) */
    pdfmake_obj_t value;
    uint32_t      order;    /* insertion order for deterministic iteration */
    uint8_t       deleted;  /* tombstone flag */
} pdfmake_dict_entry_t;

/* Dictionary: open-addressing hash keyed by interned name id.
 * Maintains insertion order for iteration (PDF readers expect /Type first). */
struct pdfmake_dict {
    pdfmake_dict_entry_t *entries;  /* arena-allocated hash table */
    uint32_t              cap;      /* hash table capacity (power of 2) */
    uint32_t              len;      /* live entry count */
    uint32_t              tombstones; /* deleted entry count */
    uint32_t              next_order; /* next insertion order value */
};

/* Stream: dictionary + raw bytes. Filter decoding deferred to phase 07. */
struct pdfmake_stream {
    pdfmake_dict_t *dict;       /* stream dictionary (pointer, not inline) */
    const uint8_t  *raw;        /* raw (possibly encoded) bytes */
    uint32_t        raw_len;    /* byte count */
    uint8_t         filtered;   /* 1 = already decoded, 0 = raw */
};

/* Dictionary iterator for insertion-order traversal. */
typedef struct {
    pdfmake_obj_t *dict_obj;     /* dict being iterated */
    uint32_t       index;        /* current order index */
    uint32_t       current_key;  /* current entry's name id */
    pdfmake_obj_t *current_value;/* pointer to current entry's value */
} pdfmake_dict_iter_t;

/*============================================================================
 * Phase 02: Arena allocator forward declaration
 *===========================================================================*/

/* Forward declaration — full definition in pdfmake_arena.h */
#ifndef PDFMAKE_ARENA_T_DEFINED
#define PDFMAKE_ARENA_T_DEFINED
typedef struct pdfmake_arena pdfmake_arena_t;
#endif

/*============================================================================
 * Phase 02: Function declarations
 *===========================================================================*/

/* Primitive constructors. */
pdfmake_obj_t pdfmake_null(void);
pdfmake_obj_t pdfmake_bool(int value);
pdfmake_obj_t pdfmake_int(int64_t value);
pdfmake_obj_t pdfmake_real(double value);
pdfmake_obj_t pdfmake_name(pdfmake_arena_t *arena, const char *bytes, size_t len);
pdfmake_obj_t pdfmake_name_cstr(pdfmake_arena_t *arena, const char *cstr);
pdfmake_obj_t pdfmake_str(pdfmake_arena_t *arena, const char *bytes, size_t len);
pdfmake_obj_t pdfmake_str_cstr(pdfmake_arena_t *arena, const char *cstr);
pdfmake_obj_t pdfmake_hexstr(pdfmake_arena_t *arena, const uint8_t *bytes, size_t len);
pdfmake_obj_t pdfmake_ref(uint32_t num, uint16_t gen);

/* Array operations. */
pdfmake_obj_t  pdfmake_array_new(pdfmake_arena_t *arena);
int            pdfmake_array_push(pdfmake_arena_t *arena, pdfmake_obj_t *arr, pdfmake_obj_t item);
pdfmake_obj_t *pdfmake_array_get(pdfmake_obj_t *arr, size_t index);
int            pdfmake_array_set(pdfmake_obj_t *arr, size_t index, pdfmake_obj_t item);
size_t         pdfmake_array_len(pdfmake_obj_t *arr);

/* Dict operations. */
pdfmake_obj_t  pdfmake_dict_new(pdfmake_arena_t *arena);
int            pdfmake_dict_set(pdfmake_arena_t *arena, pdfmake_obj_t *dict, uint32_t key, pdfmake_obj_t value);
pdfmake_obj_t *pdfmake_dict_get(pdfmake_obj_t *dict, uint32_t key);
int            pdfmake_dict_has(pdfmake_obj_t *dict, uint32_t key);
int            pdfmake_dict_del(pdfmake_obj_t *dict, uint32_t key);
size_t         pdfmake_dict_len(pdfmake_obj_t *dict);
void           pdfmake_dict_iter_init(pdfmake_dict_iter_t *iter, pdfmake_obj_t *dict);
int            pdfmake_dict_iter_next(pdfmake_dict_iter_t *iter);

/* Stream operations. */
pdfmake_obj_t   pdfmake_stream_new(pdfmake_arena_t *arena);
int             pdfmake_stream_set_data(pdfmake_arena_t *arena, pdfmake_obj_t *stream, const uint8_t *data, size_t len);
pdfmake_dict_t *pdfmake_stream_dict(pdfmake_obj_t *stream);

/*
 * Enable FlateDecode compression on a stream.
 * Must be called before the stream is written to the document.
 * The raw data will be compressed during output.
 * Returns 1 on success, 0 on error.
 */
int pdfmake_stream_set_flate(pdfmake_arena_t *arena, pdfmake_obj_t *stream);

/* Type predicates. */
int pdfmake_is_null(pdfmake_obj_t *obj);
int pdfmake_is_bool(pdfmake_obj_t *obj);
int pdfmake_is_int(pdfmake_obj_t *obj);
int pdfmake_is_real(pdfmake_obj_t *obj);
int pdfmake_is_numeric(pdfmake_obj_t *obj);
int pdfmake_is_name(pdfmake_obj_t *obj);
int pdfmake_is_str(pdfmake_obj_t *obj);
int pdfmake_is_array(pdfmake_obj_t *obj);
int pdfmake_is_dict(pdfmake_obj_t *obj);
int pdfmake_is_stream(pdfmake_obj_t *obj);
int pdfmake_is_ref(pdfmake_obj_t *obj);

/* Value accessors. */
int            pdfmake_get_bool(pdfmake_obj_t *obj);
int64_t        pdfmake_get_int(pdfmake_obj_t *obj);
double         pdfmake_get_real(pdfmake_obj_t *obj);
double         pdfmake_get_number(pdfmake_obj_t *obj);
const char    *pdfmake_get_name_bytes(pdfmake_arena_t *arena, pdfmake_obj_t *obj);
const uint8_t *pdfmake_get_str_bytes(pdfmake_obj_t *obj, size_t *len_out);
int            pdfmake_str_is_hex(pdfmake_obj_t *obj);

#ifdef __cplusplus
}
#endif

#endif /* PDFMAKE_TYPES_H */
