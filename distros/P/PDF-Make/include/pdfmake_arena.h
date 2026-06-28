/*
 * libpdfmake — arena allocator header.
 *
 * A bump allocator with chained 64KB blocks for fast, bulk-freeable
 * allocations. One arena per document — all objects are freed together
 * when the document closes.
 *
 * Also contains the name interning table for O(1) name comparison.
 */

#ifndef PDFMAKE_ARENA_H
#define PDFMAKE_ARENA_H

#include "pdfmake_types.h"

#ifdef __cplusplus
extern "C" {
#endif

/* Default block size: 64KB. Tunable at compile time. */
#ifndef PDFMAKE_ARENA_BLOCK_SIZE
#define PDFMAKE_ARENA_BLOCK_SIZE (64 * 1024)
#endif

/* Name table initial capacity. Grows by doubling. */
#ifndef PDFMAKE_NAME_TABLE_INIT_CAP
#define PDFMAKE_NAME_TABLE_INIT_CAP 256
#endif

/* A single arena block in the chain. */
typedef struct pdfmake_arena_block {
    struct pdfmake_arena_block *next;   /* next block in chain */
    size_t                      used;   /* bytes used in this block */
    size_t                      cap;    /* total capacity */
    uint8_t                     data[1];/* C89 "struct hack": real size is cap.
                                         * Allocator over-allocates by cap-1. */
} pdfmake_arena_block_t;

/* Name entry stored in names array. */
typedef struct {
    const char *bytes;  /* arena-allocated, null-terminated */
    size_t      len;    /* byte length (excluding null) */
    uint32_t    hash;   /* cached hash for lookup */
} pdfmake_name_entry_t;

/* Hash table entry for name lookup (bytes → id). */
typedef struct {
    uint32_t hash;      /* cached hash */
    uint32_t id;        /* 1-based id into names array (0 = empty) */
} pdfmake_name_hash_entry_t;

/* Name interning table: separate hash table and names array.
 * IDs are stable indices into names array, unaffected by hash table resize. */
typedef struct {
    pdfmake_name_entry_t      *names;       /* array of interned names */
    size_t                     names_cap;   /* names array capacity */
    size_t                     names_len;   /* count of interned names */
    pdfmake_name_hash_entry_t *hash;        /* hash table (bytes → id) */
    size_t                     hash_cap;    /* hash table capacity (power of 2) */
} pdfmake_name_table_t;

/* Arena allocator with chained blocks and name interning. */
struct pdfmake_arena {
    pdfmake_arena_block_t *head;    /* first block */
    pdfmake_arena_block_t *current; /* active block for allocation */
    pdfmake_name_table_t   names;   /* interned name table */
    size_t                 total;   /* total bytes allocated across all blocks */
};

/*----------------------------------------------------------------------------
 * Arena lifecycle
 *--------------------------------------------------------------------------*/

/* Create a new arena. Returns NULL on allocation failure. */
pdfmake_arena_t *pdfmake_arena_new(void);

/* Free arena and all its blocks. Safe to pass NULL. */
void pdfmake_arena_free(pdfmake_arena_t *arena);

/* Reset arena for reuse — keeps first block, frees the rest.
 * Faster than free+new for document reuse patterns. */
void pdfmake_arena_reset(pdfmake_arena_t *arena);

/*----------------------------------------------------------------------------
 * Allocation
 *--------------------------------------------------------------------------*/

/* Allocate `size` bytes from the arena. Returns 8-byte aligned pointer.
 * Returns NULL on allocation failure. Never fails for size=0 (returns
 * valid non-NULL). */
void *pdfmake_arena_alloc(pdfmake_arena_t *arena, size_t size);

/* Allocate and zero-initialize `size` bytes. */
void *pdfmake_arena_calloc(pdfmake_arena_t *arena, size_t size);

/* Duplicate a null-terminated string into the arena. */
char *pdfmake_arena_strdup(pdfmake_arena_t *arena, const char *s);

/* Duplicate `len` bytes into the arena (not null-terminated). */
void *pdfmake_arena_memdup(pdfmake_arena_t *arena, const void *src, size_t len);

/*----------------------------------------------------------------------------
 * Name interning
 *--------------------------------------------------------------------------*/

/* Intern a name string, returning its id. Same bytes always get same id.
 * The id is valid for the lifetime of the arena. Returns 0 on failure
 * (0 is reserved as "empty" in dict keys). */
uint32_t pdfmake_arena_intern_name(pdfmake_arena_t *arena, const char *bytes, size_t len);

/* Look up interned name by id. Returns NULL if id is invalid. */
const char *pdfmake_arena_name_bytes(pdfmake_arena_t *arena, uint32_t id);

/* Get length of interned name. Returns 0 if id is invalid. */
size_t pdfmake_arena_name_len(pdfmake_arena_t *arena, uint32_t id);

#ifdef __cplusplus
}
#endif

#endif /* PDFMAKE_ARENA_H */
