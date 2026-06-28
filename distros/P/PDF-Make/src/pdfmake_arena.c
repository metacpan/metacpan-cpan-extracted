/*
 * libpdfmake — arena allocator implementation.
 *
 * Bump allocator with chained 64KB blocks. One arena per document.
 * Also handles name interning for O(1) name comparison.
 */

#include "pdfmake_arena.h"
#include <stdlib.h>
#include <string.h>

/*----------------------------------------------------------------------------
 * Internal helpers
 *--------------------------------------------------------------------------*/

/* Align size up to 8 bytes. */
static PDFMAKE_INLINE size_t align8(size_t size) {
    return (size + 7) & ~(size_t)7;
}

/* FNV-1a hash for name strings. */
static uint32_t fnv1a_hash(const char *bytes, size_t len) {
    uint32_t h = 2166136261u;
    size_t i;
    for (i = 0; i < len; i++) {
        h ^= (uint8_t)bytes[i];
        h *= 16777619u;
    }
    return h;
}

/* Allocate a new block with given capacity. */
static pdfmake_arena_block_t *block_new(size_t cap) {
    pdfmake_arena_block_t *b = malloc(sizeof(*b) + cap);
    if (!b) return NULL;
    b->next = NULL;
    b->used = 0;
    b->cap = cap;
    return b;
}

/* Free a block chain starting from `b`. */
static void block_chain_free(pdfmake_arena_block_t *b) {
    while (b) {
        pdfmake_arena_block_t *next = b->next;
        free(b);
        b = next;
    }
}

/*----------------------------------------------------------------------------
 * Arena lifecycle
 *--------------------------------------------------------------------------*/

pdfmake_arena_t *pdfmake_arena_new(void) {
    pdfmake_arena_t *arena = malloc(sizeof(*arena));
    if (!arena) return NULL;

    arena->head = block_new(PDFMAKE_ARENA_BLOCK_SIZE);
    if (!arena->head) {
        free(arena);
        return NULL;
    }
    arena->current = arena->head;
    arena->total = PDFMAKE_ARENA_BLOCK_SIZE;

    /* Initialize name table with separate names array and hash table. */
    arena->names.names = calloc(PDFMAKE_NAME_TABLE_INIT_CAP, sizeof(pdfmake_name_entry_t));
    arena->names.hash = calloc(PDFMAKE_NAME_TABLE_INIT_CAP, sizeof(pdfmake_name_hash_entry_t));
    if (!arena->names.names || !arena->names.hash) {
        free(arena->names.names);
        free(arena->names.hash);
        free(arena->head);
        free(arena);
        return NULL;
    }
    arena->names.names_cap = PDFMAKE_NAME_TABLE_INIT_CAP;
    arena->names.names_len = 0;
    arena->names.hash_cap = PDFMAKE_NAME_TABLE_INIT_CAP;

    return arena;
}

void pdfmake_arena_free(pdfmake_arena_t *arena) {
    if (!arena) return;
    block_chain_free(arena->head);
    free(arena->names.names);
    free(arena->names.hash);
    free(arena);
}

void pdfmake_arena_reset(pdfmake_arena_t *arena) {
    if (!arena) return;

    /* Free all blocks except the first. */
    if (arena->head && arena->head->next) {
        block_chain_free(arena->head->next);
        arena->head->next = NULL;
    }

    /* Reset first block. */
    if (arena->head) {
        arena->head->used = 0;
        arena->total = arena->head->cap;
    }
    arena->current = arena->head;

    /* Clear name table (entries point into freed blocks). */
    if (arena->names.names) {
        memset(arena->names.names, 0, arena->names.names_cap * sizeof(pdfmake_name_entry_t));
    }
    if (arena->names.hash) {
        memset(arena->names.hash, 0, arena->names.hash_cap * sizeof(pdfmake_name_hash_entry_t));
    }
    arena->names.names_len = 0;
}

/*----------------------------------------------------------------------------
 * Allocation
 *--------------------------------------------------------------------------*/

void *pdfmake_arena_alloc(pdfmake_arena_t *arena, size_t size) {
    size_t aligned;
    size_t new_cap;
    pdfmake_arena_block_t *blk;
    pdfmake_arena_block_t *new_blk;
    void *ptr;

    if (!arena) return NULL;

    aligned = align8(size);
    if (aligned == 0) aligned = 8; /* Always return valid pointer for size=0. */

    blk = arena->current;

    /* Try current block first. */
    if (blk && blk->used + aligned <= blk->cap) {
        ptr = blk->data + blk->used;
        blk->used += aligned;
        return ptr;
    }

    /* Need a new block. Size it to fit the request if larger than default. */
    new_cap = PDFMAKE_ARENA_BLOCK_SIZE;
    if (aligned > new_cap) {
        new_cap = aligned;
    }

    new_blk = block_new(new_cap);
    if (!new_blk) return NULL;

    /* Chain new block. */
    if (blk) {
        blk->next = new_blk;
    } else {
        arena->head = new_blk;
    }
    arena->current = new_blk;
    arena->total += new_cap;

    ptr = new_blk->data;
    new_blk->used = aligned;
    return ptr;
}

void *pdfmake_arena_calloc(pdfmake_arena_t *arena, size_t size) {
    void *ptr = pdfmake_arena_alloc(arena, size);
    if (ptr && size > 0) {
        memset(ptr, 0, size);
    }
    return ptr;
}

char *pdfmake_arena_strdup(pdfmake_arena_t *arena, const char *s) {
    size_t len;
    char *dup;

    if (!s) return NULL;
    len = strlen(s);
    dup = pdfmake_arena_alloc(arena, len + 1);
    if (dup) {
        memcpy(dup, s, len + 1);
    }
    return dup;
}

void *pdfmake_arena_memdup(pdfmake_arena_t *arena, const void *src, size_t len) {
    void *dup;

    if (!src || len == 0) return NULL;
    dup = pdfmake_arena_alloc(arena, len);
    if (dup) {
        memcpy(dup, src, len);
    }
    return dup;
}

/*----------------------------------------------------------------------------
 * Name interning
 *--------------------------------------------------------------------------*/

/* Grow hash table when load factor exceeds 70%. */
static int name_hash_grow(pdfmake_arena_t *arena) {
    pdfmake_name_table_t *t = &arena->names;
    size_t new_cap = t->hash_cap * 2;
    pdfmake_name_hash_entry_t *new_hash;
    size_t i;

    new_hash = calloc(new_cap, sizeof(pdfmake_name_hash_entry_t));
    if (!new_hash) return 0;

    /* Rehash all entries from names array. */
    for (i = 0; i < t->names_len; i++) {
        uint32_t hash = t->names[i].hash;
        size_t idx = hash & (new_cap - 1);
        while (new_hash[idx].id != 0) {
            idx = (idx + 1) & (new_cap - 1);
        }
        new_hash[idx].hash = hash;
        new_hash[idx].id = (uint32_t)(i + 1);  /* 1-based id */
    }

    free(t->hash);
    t->hash = new_hash;
    t->hash_cap = new_cap;
    return 1;
}

/* Grow names array. */
static int name_array_grow(pdfmake_arena_t *arena) {
    pdfmake_name_table_t *t = &arena->names;
    size_t new_cap = t->names_cap * 2;

    pdfmake_name_entry_t *new_names = realloc(t->names, new_cap * sizeof(pdfmake_name_entry_t));
    if (!new_names) return 0;

    /* Zero the new entries. */
    memset(new_names + t->names_cap, 0, (new_cap - t->names_cap) * sizeof(pdfmake_name_entry_t));

    t->names = new_names;
    t->names_cap = new_cap;
    return 1;
}

uint32_t pdfmake_arena_intern_name(pdfmake_arena_t *arena, const char *bytes, size_t len) {
    pdfmake_name_table_t *t;
    uint32_t hash;
    size_t idx;
    char *dup;
    uint32_t new_id;

    if (!arena || !bytes) return 0;

    t = &arena->names;
    hash = fnv1a_hash(bytes, len);
    idx = hash & (t->hash_cap - 1);

    /* Probe for existing entry in hash table. */
    while (t->hash[idx].id != 0) {
        uint32_t id = t->hash[idx].id;
        pdfmake_name_entry_t *entry = &t->names[id - 1];
        if (entry->hash == hash &&
            entry->len == len &&
            memcmp(entry->bytes, bytes, len) == 0) {
            /* Found existing: return the stable id. */
            return id;
        }
        idx = (idx + 1) & (t->hash_cap - 1);
    }

    /* Not found - need to insert new name. */

    /* Grow names array if needed. */
    if (t->names_len >= t->names_cap) {
        if (!name_array_grow(arena)) return 0;
    }

    /* Grow hash table if load factor > 70%. */
    if ((t->names_len + 1) * 10 > t->hash_cap * 7) {
        if (!name_hash_grow(arena)) return 0;
        /* Recompute idx after resize. */
        idx = hash & (t->hash_cap - 1);
        while (t->hash[idx].id != 0) {
            idx = (idx + 1) & (t->hash_cap - 1);
        }
    }

    /* Copy bytes into arena. */
    dup = pdfmake_arena_alloc(arena, len + 1);
    if (!dup) return 0;
    memcpy(dup, bytes, len);
    dup[len] = '\0';

    /* Add to names array (id is 1-based). */
    new_id = (uint32_t)(t->names_len + 1);
    t->names[t->names_len].bytes = dup;
    t->names[t->names_len].len = len;
    t->names[t->names_len].hash = hash;
    t->names_len++;

    /* Add to hash table. */
    t->hash[idx].hash = hash;
    t->hash[idx].id = new_id;

    return new_id;
}

const char *pdfmake_arena_name_bytes(pdfmake_arena_t *arena, uint32_t id) {
    if (!arena || id == 0 || id > arena->names.names_len) return NULL;
    return arena->names.names[id - 1].bytes;
}

size_t pdfmake_arena_name_len(pdfmake_arena_t *arena, uint32_t id) {
    if (!arena || id == 0 || id > arena->names.names_len) return 0;
    return arena->names.names[id - 1].len;
}
