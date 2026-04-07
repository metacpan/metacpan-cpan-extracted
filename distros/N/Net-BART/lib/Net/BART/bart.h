/*
 * bart.h - Balanced Routing Tables (BART) implementation in C
 *
 * A multibit trie with fixed 8-bit strides for fast IPv4/IPv6
 * longest-prefix-match lookups.
 */

#ifndef BART_H
#define BART_H

#include <stdint.h>
#include <stdlib.h>
#include <string.h>

/* ---- BitSet256 ---- */

typedef struct {
    uint64_t w[4];
} bitset256_t;

static inline void bs256_init(bitset256_t *b) {
    b->w[0] = b->w[1] = b->w[2] = b->w[3] = 0;
}

static inline void bs256_set(bitset256_t *b, int bit) {
    b->w[bit >> 6] |= (1ULL << (bit & 63));
}

static inline void bs256_clear(bitset256_t *b, int bit) {
    b->w[bit >> 6] &= ~(1ULL << (bit & 63));
}

static inline int bs256_test(const bitset256_t *b, int bit) {
    return (b->w[bit >> 6] & (1ULL << (bit & 63))) ? 1 : 0;
}

static inline int bs256_is_empty(const bitset256_t *b) {
    return !(b->w[0] | b->w[1] | b->w[2] | b->w[3]);
}

static inline int popcount64(uint64_t x) {
#if defined(__GNUC__) || defined(__clang__)
    return __builtin_popcountll(x);
#else
    x = x - ((x >> 1) & 0x5555555555555555ULL);
    x = (x & 0x3333333333333333ULL) + ((x >> 2) & 0x3333333333333333ULL);
    return (int)(((x + (x >> 4)) & 0x0F0F0F0F0F0F0F0FULL) * 0x0101010101010101ULL >> 56);
#endif
}

/* Rank: count of set bits in positions 0..idx (inclusive) */
static inline int bs256_rank(const bitset256_t *b, int idx) {
    int word = idx >> 6;
    int bit = idx & 63;
    int count = 0;

    switch (word) {
        case 3: count += popcount64(b->w[2]); /* fallthrough */
        case 2: count += popcount64(b->w[1]); /* fallthrough */
        case 1: count += popcount64(b->w[0]); /* fallthrough */
        case 0: break;
    }

    uint64_t mask = (bit == 63) ? ~0ULL : ((1ULL << (bit + 1)) - 1);
    count += popcount64(b->w[word] & mask);
    return count;
}

static inline int bitlen64(uint64_t x) {
#if defined(__GNUC__) || defined(__clang__)
    return x ? (64 - __builtin_clzll(x)) : 0;
#else
    if (!x) return 0;
    int n = 0;
    if (x >> 32) { n += 32; x >>= 32; }
    if (x >> 16) { n += 16; x >>= 16; }
    if (x >> 8)  { n += 8;  x >>= 8;  }
    if (x >> 4)  { n += 4;  x >>= 4;  }
    if (x >> 2)  { n += 2;  x >>= 2;  }
    if (x >> 1)  { n += 1;  x >>= 1;  }
    return n + (int)x;
#endif
}

/* IntersectionTop: highest set bit in (a AND b), or -1 */
static inline int bs256_intersection_top(const bitset256_t *a, const bitset256_t *b) {
    uint64_t w;
    w = a->w[3] & b->w[3]; if (w) return 192 + bitlen64(w) - 1;
    w = a->w[2] & b->w[2]; if (w) return 128 + bitlen64(w) - 1;
    w = a->w[1] & b->w[1]; if (w) return  64 + bitlen64(w) - 1;
    w = a->w[0] & b->w[0]; if (w) return       bitlen64(w) - 1;
    return -1;
}

static inline int bs256_intersects(const bitset256_t *a, const bitset256_t *b) {
    return ((a->w[0] & b->w[0]) | (a->w[1] & b->w[1]) |
            (a->w[2] & b->w[2]) | (a->w[3] & b->w[3])) ? 1 : 0;
}

/* ---- ART index mapping ---- */

static inline int pfx_to_idx(int octet, int pfx_len) {
    return (octet >> (8 - pfx_len)) + (1 << pfx_len);
}

static inline int octet_to_idx(int octet) {
    return (octet >> 1) + 128;
}

/* ---- LPM Lookup Table ---- */

/* For each idx in [0..255], ancestor_tbl[idx] has idx and all its
   binary-tree ancestors set. */
static bitset256_t ancestor_tbl[256];
static int ancestor_tbl_init = 0;

static void init_ancestor_tbl(void) {
    if (ancestor_tbl_init) return;
    for (int idx = 0; idx < 256; idx++) {
        bs256_init(&ancestor_tbl[idx]);
        for (int i = idx; i > 0; i >>= 1) {
            bs256_set(&ancestor_tbl[idx], i);
        }
    }
    ancestor_tbl_init = 1;
}

/* ---- Sparse Array 256 ---- */
/* Stores up to 256 (void*) values indexed by 0..255 using popcount compression. */

typedef struct {
    bitset256_t bits;
    void **items;
    int len;
    int cap;
} sparse256_t;

static void sparse256_init(sparse256_t *s) {
    bs256_init(&s->bits);
    s->items = NULL;
    s->len = 0;
    s->cap = 0;
}

static void sparse256_free(sparse256_t *s) {
    free(s->items);
    s->items = NULL;
    s->len = s->cap = 0;
}

static inline void* sparse256_get(const sparse256_t *s, int idx) {
    if (!bs256_test(&s->bits, idx)) return NULL;
    int rank = bs256_rank(&s->bits, idx) - 1;
    return s->items[rank];
}

/* Returns 1 if new, 0 if updated. If old_val is non-NULL, stores previous value on update. */
static int sparse256_insert_ex(sparse256_t *s, int idx, void *val, void **old_val) {
    if (bs256_test(&s->bits, idx)) {
        int rank = bs256_rank(&s->bits, idx) - 1;
        if (old_val) *old_val = s->items[rank];
        s->items[rank] = val;
        return 0;
    }
    bs256_set(&s->bits, idx);
    int rank = bs256_rank(&s->bits, idx) - 1;
    /* grow if needed */
    if (s->len >= s->cap) {
        int newcap = s->cap ? s->cap * 2 : 4;
        s->items = realloc(s->items, newcap * sizeof(void*));
        s->cap = newcap;
    }
    /* shift right */
    memmove(&s->items[rank + 1], &s->items[rank], (s->len - rank) * sizeof(void*));
    s->items[rank] = val;
    s->len++;
    return 1;
}

static int sparse256_insert(sparse256_t *s, int idx, void *val) {
    return sparse256_insert_ex(s, idx, val, NULL);
}

/* Returns old value or NULL */
static void* sparse256_delete(sparse256_t *s, int idx) {
    if (!bs256_test(&s->bits, idx)) return NULL;
    int rank = bs256_rank(&s->bits, idx) - 1;
    void *old = s->items[rank];
    memmove(&s->items[rank], &s->items[rank + 1], (s->len - rank - 1) * sizeof(void*));
    s->len--;
    bs256_clear(&s->bits, idx);
    return old;
}

/* ---- BART Nodes ---- */

/* Node types */
#define NODE_BART   0
#define NODE_LEAF   1
#define NODE_FRINGE 2

typedef struct bart_node {
    sparse256_t prefixes;  /* idx -> SV* values */
    sparse256_t children;  /* octet -> node ptr */
} bart_node_t;

typedef struct leaf_node {
    uint8_t addr[16];   /* address bytes (4 for v4, 16 for v6) */
    int prefix_len;
    int addr_len;       /* 4 or 16 */
    void *value;        /* SV* */
} leaf_node_t;

typedef struct fringe_node {
    void *value;        /* SV* */
} fringe_node_t;

/* Tagged pointer: use low 2 bits for type tag (pointers are aligned) */
#define TAG_BITS 2
#define TAG_MASK 3

static inline void* tag_ptr(void *p, int tag) {
    return (void*)((uintptr_t)p | tag);
}

static inline void* untag_ptr(void *p) {
    return (void*)((uintptr_t)p & ~(uintptr_t)TAG_MASK);
}

static inline int ptr_tag(void *p) {
    return (int)((uintptr_t)p & TAG_MASK);
}

/* ---- BART Node operations ---- */

static bart_node_t* bart_node_new(void) {
    bart_node_t *n = calloc(1, sizeof(bart_node_t));
    sparse256_init(&n->prefixes);
    sparse256_init(&n->children);
    return n;
}

static leaf_node_t* leaf_node_new(const uint8_t *addr, int addr_len, int prefix_len, void *value) {
    leaf_node_t *l = malloc(sizeof(leaf_node_t));
    memset(l->addr, 0, 16);
    memcpy(l->addr, addr, addr_len);
    l->prefix_len = prefix_len;
    l->addr_len = addr_len;
    l->value = value;
    return l;
}

static fringe_node_t* fringe_node_new(void *value) {
    fringe_node_t *f = malloc(sizeof(fringe_node_t));
    f->value = value;
    return f;
}

static inline int bart_node_is_empty(const bart_node_t *n) {
    return n->prefixes.len == 0 && n->children.len == 0;
}

/* LPM at a single node for a given octet */
static inline void* bart_node_lpm(const bart_node_t *n, int octet, int *found) {
    int idx = octet_to_idx(octet);
    int top = bs256_intersection_top(&n->prefixes.bits, &ancestor_tbl[idx]);
    if (top >= 0) {
        *found = 1;
        return sparse256_get(&n->prefixes, top);
    }
    *found = 0;
    return NULL;
}

/* LPM test (any match?) */
static inline int bart_node_lpm_test(const bart_node_t *n, int octet) {
    int idx = octet_to_idx(octet);
    return bs256_intersects(&n->prefixes.bits, &ancestor_tbl[idx]);
}

/* ---- Leaf containment check ---- */

static int leaf_contains_ip(const leaf_node_t *leaf, const uint8_t *ip) {
    int full_bytes = leaf->prefix_len >> 3;
    int remaining = leaf->prefix_len & 7;
    if (memcmp(leaf->addr, ip, full_bytes) != 0) return 0;
    if (remaining) {
        uint8_t mask = (0xFF << (8 - remaining)) & 0xFF;
        if ((leaf->addr[full_bytes] & mask) != (ip[full_bytes] & mask)) return 0;
    }
    return 1;
}

static int leaf_matches_prefix(const leaf_node_t *leaf, const uint8_t *addr, int prefix_len) {
    if (leaf->prefix_len != prefix_len) return 0;
    int full_bytes = prefix_len >> 3;
    if (memcmp(leaf->addr, addr, full_bytes) != 0) return 0;
    int remaining = prefix_len & 7;
    if (remaining) {
        uint8_t mask = (0xFF << (8 - remaining)) & 0xFF;
        if ((leaf->addr[full_bytes] & mask) != (addr[full_bytes] & mask)) return 0;
    }
    return 1;
}

/* ---- BART Table ---- */

typedef struct {
    bart_node_t *root4;
    bart_node_t *root6;
    int size4;
    int size6;
} bart_table_t;

static bart_table_t* bart_table_new(void) {
    init_ancestor_tbl();
    bart_table_t *t = malloc(sizeof(bart_table_t));
    t->root4 = bart_node_new();
    t->root6 = bart_node_new();
    t->size4 = 0;
    t->size6 = 0;
    return t;
}

/* Forward declarations for recursive free */
static void bart_node_free_recursive(bart_node_t *node);

static void bart_node_free_recursive(bart_node_t *node) {
    if (!node) return;
    /* Free children */
    for (int i = 0; i < node->children.len; i++) {
        void *tagged = node->children.items[i];
        int tag = ptr_tag(tagged);
        void *ptr = untag_ptr(tagged);
        if (tag == NODE_BART) {
            bart_node_free_recursive((bart_node_t*)ptr);
        } else {
            free(ptr); /* leaf or fringe */
        }
    }
    /* Note: prefix values (SV*) are freed by Perl via reference counting */
    sparse256_free(&node->prefixes);
    sparse256_free(&node->children);
    free(node);
}

static void bart_table_free(bart_table_t *t) {
    if (!t) return;
    bart_node_free_recursive(t->root4);
    bart_node_free_recursive(t->root6);
    free(t);
}

/* ---- Insert ---- */

/* Insert: returns 1 if new, 0 if updated. old_val receives replaced value on update. */
static int bart_insert(bart_node_t *node, const uint8_t *addr, int addr_len,
                       int prefix_len, int depth, void *value, void **old_val);
static int bart_insert_fringe(bart_node_t *node, const uint8_t *addr, int addr_len,
                              int prefix_len, int depth, void *value, void **old_val);

static int bart_insert(bart_node_t *node, const uint8_t *addr, int addr_len,
                       int prefix_len, int depth, void *value, void **old_val) {
    int strides = prefix_len >> 3;
    int lastbits = prefix_len & 7;

    if (prefix_len == 0) {
        return sparse256_insert_ex(&node->prefixes, 1, value, old_val);
    }

    if (lastbits && depth == strides) {
        int idx = pfx_to_idx(addr[depth], lastbits);
        return sparse256_insert_ex(&node->prefixes, idx, value, old_val);
    }

    if (!lastbits && depth == strides - 1) {
        return bart_insert_fringe(node, addr, addr_len, prefix_len, depth, value, old_val);
    }

    /* Navigate */
    int octet = addr[depth];
    void *tagged = sparse256_get(&node->children, octet);

    if (!tagged) {
        leaf_node_t *leaf = leaf_node_new(addr, addr_len, prefix_len, value);
        sparse256_insert(&node->children, octet, tag_ptr(leaf, NODE_LEAF));
        return 1;
    }

    int tag = ptr_tag(tagged);
    void *child = untag_ptr(tagged);

    if (tag == NODE_LEAF) {
        leaf_node_t *leaf = (leaf_node_t*)child;
        if (leaf_matches_prefix(leaf, addr, prefix_len)) {
            if (old_val) *old_val = leaf->value;
            leaf->value = value;
            return 0;
        }
        bart_node_t *new_node = bart_node_new();
        bart_insert(new_node, leaf->addr, leaf->addr_len, leaf->prefix_len, depth + 1, leaf->value, NULL);
        sparse256_insert(&node->children, octet, tag_ptr(new_node, NODE_BART));
        free(leaf);
        return bart_insert(new_node, addr, addr_len, prefix_len, depth + 1, value, old_val);
    }

    if (tag == NODE_FRINGE) {
        fringe_node_t *fringe = (fringe_node_t*)child;
        if (!lastbits && depth == strides - 1) {
            if (old_val) *old_val = fringe->value;
            fringe->value = value;
            return 0;
        }
        bart_node_t *new_node = bart_node_new();
        sparse256_insert(&new_node->prefixes, 1, fringe->value);
        sparse256_insert(&node->children, octet, tag_ptr(new_node, NODE_BART));
        free(fringe);
        return bart_insert(new_node, addr, addr_len, prefix_len, depth + 1, value, old_val);
    }

    /* NODE_BART */
    return bart_insert((bart_node_t*)child, addr, addr_len, prefix_len, depth + 1, value, old_val);
}

static int bart_insert_fringe(bart_node_t *node, const uint8_t *addr, int addr_len,
                              int prefix_len, int depth, void *value, void **old_val) {
    int octet = addr[depth];
    void *tagged = sparse256_get(&node->children, octet);

    if (!tagged) {
        fringe_node_t *f = fringe_node_new(value);
        sparse256_insert(&node->children, octet, tag_ptr(f, NODE_FRINGE));
        return 1;
    }

    int tag = ptr_tag(tagged);
    void *child = untag_ptr(tagged);

    if (tag == NODE_FRINGE) {
        if (old_val) *old_val = ((fringe_node_t*)child)->value;
        ((fringe_node_t*)child)->value = value;
        return 0;
    }
    if (tag == NODE_BART) {
        return sparse256_insert_ex(&((bart_node_t*)child)->prefixes, 1, value, old_val);
    }
    if (tag == NODE_LEAF) {
        leaf_node_t *leaf = (leaf_node_t*)child;
        bart_node_t *new_node = bart_node_new();
        bart_insert(new_node, leaf->addr, leaf->addr_len, leaf->prefix_len, depth + 1, leaf->value, NULL);
        sparse256_insert(&new_node->prefixes, 1, value);
        sparse256_insert(&node->children, octet, tag_ptr(new_node, NODE_BART));
        free(leaf);
        return 1;
    }
    return 0;
}

/* ---- Lookup (LPM) ---- */

typedef struct {
    bart_node_t *node;
    int octet;
} stack_entry_t;

static void* bart_lookup(bart_table_t *t, const uint8_t *ip, int is_ipv6, int *found) {
    bart_node_t *root = is_ipv6 ? t->root6 : t->root4;
    int max_depth = is_ipv6 ? 16 : 4;

    stack_entry_t stack[17]; /* max 16 for IPv6 + 1 */
    int sp = 0;
    bart_node_t *node = root;

    for (int depth = 0; depth < max_depth; depth++) {
        int octet = ip[depth];
        stack[sp].node = node;
        stack[sp].octet = octet;
        sp++;

        void *tagged = sparse256_get(&node->children, octet);
        if (!tagged) break;

        int tag = ptr_tag(tagged);
        void *child = untag_ptr(tagged);

        if (tag == NODE_FRINGE) {
            *found = 1;
            return ((fringe_node_t*)child)->value;
        }
        if (tag == NODE_LEAF) {
            leaf_node_t *leaf = (leaf_node_t*)child;
            if (leaf_contains_ip(leaf, ip)) {
                *found = 1;
                return leaf->value;
            }
            break;
        }
        node = (bart_node_t*)child;
    }

    /* Backtrack LPM */
    for (int i = sp - 1; i >= 0; i--) {
        int ok;
        void *val = bart_node_lpm(stack[i].node, stack[i].octet, &ok);
        if (ok) {
            *found = 1;
            return val;
        }
    }

    *found = 0;
    return NULL;
}

/* ---- Contains ---- */

static int bart_contains(bart_table_t *t, const uint8_t *ip, int is_ipv6) {
    bart_node_t *root = is_ipv6 ? t->root6 : t->root4;
    int max_depth = is_ipv6 ? 16 : 4;
    bart_node_t *node = root;

    for (int depth = 0; depth < max_depth; depth++) {
        int octet = ip[depth];
        if (bart_node_lpm_test(node, octet)) return 1;

        void *tagged = sparse256_get(&node->children, octet);
        if (!tagged) return 0;

        int tag = ptr_tag(tagged);
        void *child = untag_ptr(tagged);

        if (tag == NODE_FRINGE) return 1;
        if (tag == NODE_LEAF) return leaf_contains_ip((leaf_node_t*)child, ip);
        node = (bart_node_t*)child;
    }
    return 0;
}

/* ---- Exact match (Get) ---- */

static void* bart_get(bart_table_t *t, const uint8_t *addr, int prefix_len,
                      int is_ipv6, int *found) {
    bart_node_t *root = is_ipv6 ? t->root6 : t->root4;
    bart_node_t *node = root;

    int strides = prefix_len >> 3;
    int lastbits = prefix_len & 7;

    if (prefix_len == 0) {
        void *v = sparse256_get(&node->prefixes, 1);
        *found = (v != NULL);
        return v;
    }

    for (int depth = 0; ; depth++) {
        if (lastbits && depth == strides) {
            int idx = pfx_to_idx(addr[depth], lastbits);
            void *v = sparse256_get(&node->prefixes, idx);
            *found = (v != NULL);
            return v;
        }

        if (!lastbits && depth == strides - 1) {
            void *tagged = sparse256_get(&node->children, addr[depth]);
            if (!tagged) { *found = 0; return NULL; }
            int tag = ptr_tag(tagged);
            void *child = untag_ptr(tagged);
            if (tag == NODE_FRINGE) {
                *found = 1;
                return ((fringe_node_t*)child)->value;
            }
            if (tag == NODE_BART) {
                void *v = sparse256_get(&((bart_node_t*)child)->prefixes, 1);
                *found = (v != NULL);
                return v;
            }
            *found = 0;
            return NULL;
        }

        /* Navigate */
        void *tagged = sparse256_get(&node->children, addr[depth]);
        if (!tagged) { *found = 0; return NULL; }
        int tag = ptr_tag(tagged);
        void *child = untag_ptr(tagged);

        if (tag == NODE_LEAF) {
            if (leaf_matches_prefix((leaf_node_t*)child, addr, prefix_len)) {
                *found = 1;
                return ((leaf_node_t*)child)->value;
            }
            *found = 0;
            return NULL;
        }
        if (tag == NODE_FRINGE) { *found = 0; return NULL; }
        node = (bart_node_t*)child;
    }
}

/* ---- Delete ---- */

static void* bart_delete(bart_node_t *node, const uint8_t *addr,
                         int prefix_len, int depth, int *found) {
    int strides = prefix_len >> 3;
    int lastbits = prefix_len & 7;

    if (prefix_len == 0) {
        void *old = sparse256_delete(&node->prefixes, 1);
        *found = (old != NULL);
        return old;
    }

    if (lastbits && depth == strides) {
        int idx = pfx_to_idx(addr[depth], lastbits);
        void *old = sparse256_delete(&node->prefixes, idx);
        *found = (old != NULL);
        return old;
    }

    if (!lastbits && depth == strides - 1) {
        int octet = addr[depth];
        void *tagged = sparse256_get(&node->children, octet);
        if (!tagged) { *found = 0; return NULL; }
        int tag = ptr_tag(tagged);
        void *child = untag_ptr(tagged);

        if (tag == NODE_FRINGE) {
            void *val = ((fringe_node_t*)child)->value;
            sparse256_delete(&node->children, octet);
            free(child);
            *found = 1;
            return val;
        }
        if (tag == NODE_BART) {
            bart_node_t *bn = (bart_node_t*)child;
            void *old = sparse256_delete(&bn->prefixes, 1);
            if (old && bart_node_is_empty(bn)) {
                sparse256_delete(&node->children, octet);
                bart_node_free_recursive(bn);
            }
            *found = (old != NULL);
            return old;
        }
        *found = 0;
        return NULL;
    }

    /* Navigate */
    int octet = addr[depth];
    void *tagged = sparse256_get(&node->children, octet);
    if (!tagged) { *found = 0; return NULL; }
    int tag = ptr_tag(tagged);
    void *child = untag_ptr(tagged);

    if (tag == NODE_LEAF) {
        leaf_node_t *leaf = (leaf_node_t*)child;
        if (leaf_matches_prefix(leaf, addr, prefix_len)) {
            void *val = leaf->value;
            sparse256_delete(&node->children, octet);
            free(leaf);
            *found = 1;
            return val;
        }
        *found = 0;
        return NULL;
    }
    if (tag == NODE_FRINGE) { *found = 0; return NULL; }

    bart_node_t *bn = (bart_node_t*)child;
    void *val = bart_delete(bn, addr, prefix_len, depth + 1, found);
    if (*found && bart_node_is_empty(bn)) {
        sparse256_delete(&node->children, octet);
        bart_node_free_recursive(bn);
    }
    return val;
}

/* ---- IP Parsing helpers ---- */

static int parse_ipv4(const char *str, uint8_t *out) {
    int a, b, c, d;
    if (sscanf(str, "%d.%d.%d.%d", &a, &b, &c, &d) != 4)
        return 0;
    out[0] = (uint8_t)a; out[1] = (uint8_t)b;
    out[2] = (uint8_t)c; out[3] = (uint8_t)d;
    return 1;
}

static void mask_prefix(uint8_t *addr, int addr_len, int prefix_len) {
    int full = prefix_len >> 3;
    int rem = prefix_len & 7;
    if (rem && full < addr_len) {
        addr[full] &= (0xFF << (8 - rem)) & 0xFF;
        full++;
    }
    for (int i = full; i < addr_len; i++) addr[i] = 0;
}

#endif /* BART_H */
