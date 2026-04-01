//
// Created by Denys Fisher on 07.04.2025.
//

#ifndef OA_HASH_H
#define OA_HASH_H
#ifdef __cplusplus
#include <atomic>
#define ATOMIC(type) std::atomic<type>
#else
#define ATOMIC(type) _Atomic type
#endif
#ifdef __cplusplus
extern "C" {
#endif
#include <stdint.h>
#include <string.h>
#include <stdalign.h>

#define SLOT_TYPE uint32_t
#define SLOT_SIZE sizeof(SLOT_TYPE)
#define VALUE_SIZE 32
#define VALUE_SLOTS (VALUE_SIZE / SLOT_SIZE)
#define STATIC_ASSERT(cond, msg) typedef char static_assertion_##msg[(cond) ? 1 : -1]
#define UINT32_PAIR(name, first, second)        \
typedef union {                                 \
    struct {                                    \
        uint32_t first;                         \
        uint32_t second;                        \
    };                                          \
    uint64_t storable;                          \
} name;

// fancy formula for    (n + a - 1) / a * a;
#define ALIGN_UP(n, a) \
((((size_t)(n) + ((size_t)(a) - 1)) & ~((size_t)(a) - 1)))

#define OFFSET(prev_ptr, next_ptr) \
((void *)((char *)(prev_ptr) + \
ALIGN_UP(sizeof(*(prev_ptr)), _Alignof(__typeof__(*( next_ptr ))))))

#define OFFSETA(prev_ptr, count, next_ptr) \
((void *)((char *)(prev_ptr) + \
ALIGN_UP((size_t)(count) * sizeof(*(prev_ptr)), _Alignof(__typeof__(*( next_ptr ))))))


typedef union {
    struct {
        uint32_t key_start;
        uint32_t key_size: 30;
        uint32_t status: 2; // 0 - nothing, 1 - index set, 2 - data set, 3 - commited
    };
    uint64_t storable;
} Key;

typedef enum OA_HASH_ERR {
    OA_HASH_OK = 0,
    OA_HASH_ERR_INDEX_FULL = -1,
    OA_HASH_ERR_NOT_FOUND = -2,
    OA_HASH_ERR_FAILED = -3,
    OA_HASH_ERR_KEY_TOO_LONG = -4,
    OA_HASH_ERR_DATA_FULL = -5,
    OA_HASH_ERR_INVALID_ARGUMENT = -6,
    OA_HASH_INVALD_STATE = -7,
} OA_HASH_ERR;

typedef enum STATUS {
    UNSET = 0,
    INDEX_SET = 1,
    DATA_SET = 2,
    COMMITED = 3,
    STATUS_LAST
} STATUS;

typedef struct {
    char* key;
    char value[VALUE_SIZE];
} HashEntry;

typedef struct {
    ATOMIC(uint64_t) key;
} HashIndexEntry;
STATIC_ASSERT(alignof(HashIndexEntry)%SLOT_SIZE == 0, HashIndexEntry_should_align_SLOT_SIZE);

typedef ATOMIC(uint32_t) HashDataEntry;
STATIC_ASSERT(alignof(HashDataEntry)%SLOT_SIZE == 0, HashDataEntry_should_align_SLOT_SIZE);

UINT32_PAIR(Sizes, index, data);
typedef struct {
    ATOMIC(uint64_t) sizes;
    ATOMIC(uint64_t) capacities;
    ATOMIC(uint64_t) current_update;
} HashDataSizes;
STATIC_ASSERT(alignof(HashDataSizes)%SLOT_SIZE == 0, HashDataSizes_should_align_4_bytes);

typedef struct {
    HashDataSizes*      sizes;
    HashIndexEntry*     index_entries;
    HashDataEntry*      data_entries;
} HashTable;

typedef struct {
    uint32_t probes;
    uint32_t reallocates;
} Stats;

OA_HASH_ERR    ht_init_table(HashTable* ht, Sizes capacities, void* mem);
OA_HASH_ERR    ht_copy_to_local_memory(HashTable* src, HashTable* dst);
size_t         ht_table_size(uint32_t index_len, uint32_t data_len);
OA_HASH_ERR    ht_insert(HashTable *ht, const char *key, const char value[VALUE_SIZE], Stats *stats);
OA_HASH_ERR    ht_lookup(HashTable *ht, const char *key, HashEntry *entry);
void           ht_table_fix(HashTable *ht);
void           ht_get_entry(HashTable* ht, HashIndexEntry * ht_index, HashEntry *entry);
OA_HASH_ERR    ht_copy(HashTable *dst, HashTable *src);
void           ht_clear_table(HashTable *ht);
Sizes          ht_resize_table(const HashTable* ht, uint32_t ratio);

#ifdef __cplusplus
}
#endif
#endif //OA_HASH_H
