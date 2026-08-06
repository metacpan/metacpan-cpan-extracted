#include "stencil.h"

#include <stdlib.h>

int stencil_arena_init(stencil_arena *a, size_t initial_cap)
{
    if (initial_cap < 64)
        initial_cap = 64;
    a->base = (char *)malloc(initial_cap);
    if (!a->base)
        return 0;
    a->used = 0;
    a->cap  = initial_cap;
    return 1;
}

uint32_t stencil_arena_alloc(stencil_arena *a, size_t size, size_t align)
{
    size_t off = (a->used + (align - 1)) & ~(align - 1);
    if (STENCIL_UNLIKELY(off + size < off || off + size > (uint32_t)-2))
        return STENCIL_ARENA_NULL; /* offset space exhausted */
    if (STENCIL_UNLIKELY(off + size > a->cap)) {
        size_t ncap = a->cap;
        char  *nb;
        while (ncap < off + size)
            ncap <<= 1;
        nb = (char *)realloc(a->base, ncap);
        if (!nb)
            return STENCIL_ARENA_NULL;
        a->base = nb;
        a->cap  = ncap;
    }
    a->used = off + size;
    return (uint32_t)off;
}

void stencil_arena_finalise(stencil_arena *a)
{
    char *nb;
    if (!a->used || a->used == a->cap)
        return;
    nb = (char *)realloc(a->base, a->used);
    if (nb) {
        a->base = nb;
        a->cap  = a->used;
    }
}

void stencil_arena_free(stencil_arena *a)
{
    free(a->base);
    a->base = NULL;
    a->used = a->cap = 0;
}

uint64_t stencil_fnv1a(const char *p, size_t n)
{
    uint64_t h = 0xcbf29ce484222325ULL;
    size_t   i;
    for (i = 0; i < n; i++) {
        h ^= (uint8_t)p[i];
        h *= 0x100000001b3ULL;
    }
    return h;
}

int stencil_intern_init(stencil_intern *t)
{
    t->n_slots = 64;
    t->n_used  = 0;
    t->slots   = (stencil_intern_slot *)
        calloc(t->n_slots, sizeof(stencil_intern_slot));
    return t->slots != NULL;
}

static int intern_rehash(stencil_intern *t)
{
    uint32_t             old_n  = t->n_slots;
    stencil_intern_slot *old    = t->slots;
    uint32_t             i;
    t->n_slots <<= 1;
    t->slots = (stencil_intern_slot *)
        calloc(t->n_slots, sizeof(stencil_intern_slot));
    if (!t->slots) {
        t->slots   = old;
        t->n_slots = old_n;
        return 0;
    }
    for (i = 0; i < old_n; i++) {
        if (old[i].hash) {
            uint32_t j = (uint32_t)old[i].hash & (t->n_slots - 1);
            while (t->slots[j].hash)
                j = (j + 1) & (t->n_slots - 1);
            t->slots[j] = old[i];
        }
    }
    free(old);
    return 1;
}

uint32_t stencil_intern_get(stencil_intern *t, stencil_arena *a,
                            const char *bytes, uint32_t len)
{
    uint64_t h = stencil_fnv1a(bytes, len);
    uint32_t j;
    if (!h)
        h = 1;
    j = (uint32_t)h & (t->n_slots - 1);
    while (t->slots[j].hash) {
        if (t->slots[j].hash == h && t->slots[j].len == len
            && memcmp(stencil_arena_ptr(a, t->slots[j].off), bytes, len) == 0)
            return t->slots[j].off;
        j = (j + 1) & (t->n_slots - 1);
    }
    {
        uint32_t off = stencil_arena_alloc(a, len, 1);
        if (off == STENCIL_ARENA_NULL)
            return STENCIL_ARENA_NULL;
        memcpy(stencil_arena_ptr(a, off), bytes, len);
        t->slots[j].hash = h;
        t->slots[j].off  = off;
        t->slots[j].len  = len;
        t->n_used++;
        /* resize at 70% load */
        if (STENCIL_UNLIKELY(t->n_used * 10 >= t->n_slots * 7))
            if (!intern_rehash(t))
                return STENCIL_ARENA_NULL;
        return off;
    }
}

void stencil_intern_free(stencil_intern *t)
{
    free(t->slots);
    t->slots   = NULL;
    t->n_slots = t->n_used = 0;
}

/* ---- self test ---------------------------------------------------- */

const char *stencil_arena_selftest(void)
{
    stencil_arena  a;
    stencil_intern t;
    uint32_t       offs[512];
    int            i;

    if (!stencil_arena_init(&a, 64))
        return "arena_init failed";

    /* alignment */
    for (i = 0; i < 5; i++) {
        size_t   align = (size_t)1 << i;
        uint32_t off   = stencil_arena_alloc(&a, 3, align);
        if (off == STENCIL_ARENA_NULL)
            return "alloc failed";
        if (off & (align - 1))
            return "alloc misaligned";
    }

    /* offsets stable across growth: write a pattern per block, force
     * many reallocs, then verify every pattern survived */
    for (i = 0; i < 512; i++) {
        offs[i] = stencil_arena_alloc(&a, 97, 8);
        if (offs[i] == STENCIL_ARENA_NULL)
            return "alloc failed during growth";
        memset(stencil_arena_ptr(&a, offs[i]), i & 0xff, 97);
    }
    for (i = 0; i < 512; i++) {
        unsigned char *p = (unsigned char *)stencil_arena_ptr(&a, offs[i]);
        int j;
        for (j = 0; j < 97; j++)
            if (p[j] != (i & 0xff))
                return "pattern corrupted by growth";
    }

    /* finalise shrink-wraps */
    stencil_arena_finalise(&a);
    if (a.cap != a.used)
        return "finalise did not shrink";

    /* intern dedup */
    if (!stencil_intern_init(&t))
        return "intern_init failed";
    {
        uint32_t x = stencil_intern_get(&t, &a, "</li></ul>", 10);
        uint32_t y = stencil_intern_get(&t, &a, "</li></ul>", 10);
        uint32_t z = stencil_intern_get(&t, &a, "</li></ol>", 10);
        if (x == STENCIL_ARENA_NULL || z == STENCIL_ARENA_NULL)
            return "intern alloc failed";
        if (x != y)
            return "intern failed to dedup identical bytes";
        if (x == z)
            return "intern conflated distinct bytes";
        if (memcmp(stencil_arena_ptr(&a, x), "</li></ul>", 10) != 0)
            return "interned bytes corrupt";
    }
    /* force rehash */
    for (i = 0; i < 512; i++) {
        char buf[16];
        int  n = i;
        int  k = 0;
        buf[k++] = 'k';
        do { buf[k++] = (char)('0' + (n % 10)); n /= 10; } while (n);
        if (stencil_intern_get(&t, &a, buf, (uint32_t)k)
                == STENCIL_ARENA_NULL)
            return "intern failed during rehash";
    }
    if (stencil_intern_get(&t, &a, "</li></ul>", 10)
            != stencil_intern_get(&t, &a, "</li></ul>", 10))
        return "dedup broken after rehash";

    stencil_intern_free(&t);
    stencil_arena_free(&a);
    if (a.base || a.cap || a.used)
        return "free did not reset";
    return NULL;
}
