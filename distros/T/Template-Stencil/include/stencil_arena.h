#ifndef STENCIL_ARENA_H
#define STENCIL_ARENA_H

/* Bump arena: one growable block owning everything a compiled template
 * needs, freed in a single call. All internal references are OFFSETS,
 * not pointers, so realloc during compile never invalidates anything;
 * pointers are materialised only against the final base. */

typedef struct stencil_arena {
    char   *base;   /* single realloc'd block */
    size_t  used;
    size_t  cap;
} stencil_arena;

#define STENCIL_ARENA_NULL ((uint32_t)-1)
#define stencil_arena_ptr(a, off) ((void *)((a)->base + (off)))

int      stencil_arena_init(stencil_arena *a, size_t initial_cap);
/* align must be a power of two; returns STENCIL_ARENA_NULL on OOM */
uint32_t stencil_arena_alloc(stencil_arena *a, size_t size, size_t align);
void     stencil_arena_finalise(stencil_arena *a);  /* shrink-wrap */
void     stencil_arena_free(stencil_arena *a);

/* Compile-time-only intern table for literal dedup: maps (bytes, len)
 * to an arena offset; identical byte runs share storage. Lives outside
 * the arena and is freed after compile. */

typedef struct stencil_intern_slot {
    uint64_t hash;   /* 0 = empty (fnv result 0 is bumped to 1) */
    uint32_t off;
    uint32_t len;
} stencil_intern_slot;

typedef struct stencil_intern {
    stencil_intern_slot *slots;
    uint32_t             n_slots; /* power of two */
    uint32_t             n_used;
} stencil_intern;

int      stencil_intern_init(stencil_intern *t);
/* returns arena offset of the interned bytes; STENCIL_ARENA_NULL on OOM */
uint32_t stencil_intern_get(stencil_intern *t, stencil_arena *a,
                            const char *bytes, uint32_t len);
void     stencil_intern_free(stencil_intern *t);

uint64_t stencil_fnv1a(const char *p, size_t n);

/* C-side self test; returns NULL on success or a static error string. */
const char *stencil_arena_selftest(void);

#endif /* STENCIL_ARENA_H */
