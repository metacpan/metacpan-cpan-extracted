#include "oa_hash.h"
#include "log.h"

#include <stdlib.h>
#include <string.h>
#include <stdatomic.h>
#include <stdio.h>
#include <unistd.h>
#define NOTHING_IS_UPDATED UINT64_MAX

static SLOT_TYPE next4(size_t x)
{
    size_t n = (x + 3u) & ~(size_t)3u;
    return n / SLOT_SIZE;
}

// A simple hash function for strings
static uint32_t hash(const char *key) {
    size_t hash_val = 0;
    while (*key)
        hash_val = (hash_val << 5) + (uint8_t)*key++;
    return hash_val;
}

static HashIndexEntry* get_index(const HashTable *ht, uint32_t index) {
    return ht->index_entries + index;
}

static char* get_key(const HashTable* ht, HashIndexEntry* entry) {
    Key key = { .storable = entry->key };
    return (char *) ((uint32_t*) ht->data_entries + key.key_start);
}

static const char* get_value(const HashTable* ht, HashIndexEntry* entry) {
    Key key = { .storable = entry->key };
    return (const char*)(ht->data_entries + key.key_start + key.key_size);
}

static void set_value(const HashTable* ht, HashIndexEntry* entry, const char value[VALUE_SIZE]) {
    Key key = { .storable = entry->key };
    char* stored = (char*)(ht->data_entries + key.key_start + key.key_size);
    memcpy(stored, value, VALUE_SIZE);
}

static void commit_new_entry(HashTable *ht, HashIndexEntry* ht_index, const char *key, uint32_t key_size, const char value[VALUE_SIZE]) {
    SLOT_TYPE data_size = key_size + VALUE_SLOTS;

    Sizes sizes;
    sizes.storable = atomic_load_explicit(&ht->sizes->sizes, memory_order_acquire);
    Key key_id = {0};
    key_id.key_start = sizes.data;
    key_id.key_size = key_size;
    key_id.status = INDEX_SET;
    atomic_store_explicit(&ht_index->key, key_id.storable, memory_order_release);

    strcpy((char *) (ht->data_entries + sizes.data), key);
    memcpy(ht->data_entries + sizes.data + key_size, value, VALUE_SIZE);
    key_id.status = DATA_SET;
    atomic_store_explicit(&ht_index->key, key_id.storable, memory_order_release);

    sizes.data += data_size;
    sizes.index += 1;
    key_id.status = COMMITED;
    atomic_store_explicit(&ht->sizes->sizes, sizes.storable, memory_order_release);
    atomic_store_explicit(&ht_index->key, key_id.storable, memory_order_release);
}

void fix_entry(HashTable* ht, uint32_t entry_slot) {
    HashIndexEntry* ht_index = get_index(ht, entry_slot);
    _Static_assert(STATUS_LAST == 4, "Update case statement below if you add new status");
    int done = 0;
    while (!done) {
        Key key_id = { .storable = atomic_load_explicit(&ht_index->key, memory_order_acquire) };
        switch (key_id.status) {
            case UNSET:
                // if status unset then process died on index update
                // index update is atomic, so we can safely set it
                done = 1;
                break;
            case INDEX_SET: {
                // if index committed then process died on data update, cleanup it
                Key key = { .storable = ht_index->key };
                uint32_t slot_size = key.key_size + VALUE_SLOTS;
                uint32_t* slot = (uint32_t*) ht->data_entries + key.key_start;
                memset(slot, 0, slot_size);
                key.status = UNSET;
                key.key_start = 0;
                key.key_size = 0;
                atomic_store_explicit(&ht_index->key, key.storable, memory_order_release);
                break;
            }
            case DATA_SET: {
                // index and data was commit, need ot check if sizes were updated
                uint32_t index_size_exp = 0;
                Sizes sizes = { .storable = ht->sizes->sizes };
                Sizes capacities = { .storable = ht->sizes->capacities};
                for (uint32_t i = 0; i < capacities.index; i++) {
                    HashIndexEntry* index_entry = get_index(ht, i);
                    Key index_key = { .storable = index_entry->key };
                    if (index_key.status) {
                        index_size_exp++;
                    }
                }
                Key key = { .storable = ht_index->key };
                uint32_t data_size_exp = key.key_start + key.key_size + 1;
                sizes.index = index_size_exp;
                sizes.data = data_size_exp;
                key.status = COMMITED;
                atomic_store_explicit(&ht->sizes->sizes, sizes.storable, memory_order_release);
                atomic_store_explicit(&ht_index->key, key.storable, memory_order_release);
                break;
            }
            case COMMITED:
                // Fixed
                done = 1;
                break;
        }
    }
    atomic_store_explicit(&ht->sizes->current_update, NOTHING_IS_UPDATED, memory_order_release);
}

static int find_index(HashTable *ht, const char *key, HashIndexEntry** res, Stats *stats) {
    Sizes capacites = { .storable = ht->sizes->capacities };
    uint32_t capacity = capacites.index;
    uint32_t key_hash = hash(key);
    uint32_t index = key_hash % capacity;
    uint32_t start_index = index;

    for (;;) {
        if (stats) stats->probes++;
        HashIndexEntry* ht_index = get_index(ht, index);
        Key ht_index_as_key = (Key)ht_index->key;
        if (!ht_index_as_key.status) {
            *res = ht_index;
            return index;
        }
        char *key_in_slot = get_key(ht, ht_index);
        if (strcmp(key_in_slot, key) == 0) {
            *res = ht_index;
            return index;
        }
        index = (index + 1) % capacity; // Linear probing
        if (index == start_index) {
            LOG("find_index: full circle, key='%s' capacity=%u\n", key, capacity);
            *res = 0; // Came full circle, not found
            return -1;
        }
    }
}

// PUBLIC API
OA_HASH_ERR ht_init_table(HashTable* ht, Sizes capacities, void* mem) {
    if (!mem) {
        return OA_HASH_ERR_INVALID_ARGUMENT;
    }

    ht->sizes          = (HashDataSizes*) mem;
    ht->index_entries  = OFFSET(ht->sizes, ht->index_entries);
    ht->data_entries   = OFFSETA(ht->index_entries, capacities.index, ht->data_entries);
    atomic_store_explicit(&ht->sizes->current_update, NOTHING_IS_UPDATED, memory_order_release);
    atomic_store_explicit(&ht->sizes->capacities, capacities.storable, memory_order_release);
    return OA_HASH_OK;
}

Sizes ht_resize_table(const HashTable* ht, uint32_t ratio) {
    Sizes old_capacities = { .storable = atomic_load_explicit(&ht->sizes->capacities, memory_order_acquire) };
    Sizes new_capacities = old_capacities;
    new_capacities.index *= ratio;
    if (new_capacities.data < ((Sizes) ht->sizes->sizes).data * ratio) {
        new_capacities.data = ((Sizes) ht->sizes->capacities).data * ratio;
    }
    return new_capacities;
}

void ht_table_fix(HashTable* ht) {
    if (ht->sizes->current_update != NOTHING_IS_UPDATED) {
        fix_entry(ht, (uint32_t)ht->sizes->current_update);
    }
}

OA_HASH_ERR ht_copy_to_local_memory(HashTable* src, HashTable* dst) {
    Sizes capacities = { .storable = src->sizes->capacities };
    Sizes sizes = { .storable = src->sizes->sizes };
    size_t size = ht_table_size(capacities.index, capacities.data);
    void* mem = calloc(size, 1);
    if (!mem) {
        return OA_HASH_ERR_FAILED;
    }
    OA_HASH_ERR error = ht_init_table(dst, capacities, mem);
    if (error != OA_HASH_OK) return error;
    memcpy(dst->index_entries, src->index_entries, capacities.index * sizeof(HashIndexEntry));
    memcpy(dst->data_entries, src->data_entries, sizes.data * sizeof(HashDataEntry));
    atomic_store_explicit(&dst->sizes->sizes, sizes.storable, memory_order_release);
    return OA_HASH_OK;
}

size_t ht_table_size(uint32_t index_len, uint32_t data_len) {
    size_t sizes_size = ALIGN_UP(sizeof(HashDataSizes), alignof(HashIndexEntry));
    size_t index_size = ALIGN_UP(sizeof(HashIndexEntry) * index_len, alignof(HashDataEntry));
    size_t data_size = sizeof(HashDataEntry) * data_len;
    size_t bytes = sizes_size + index_size + data_size;
    return bytes;
}

OA_HASH_ERR ht_insert(HashTable *ht, const char *key, const char value[VALUE_SIZE], Stats *stats) {
    uint64_t cur = atomic_load_explicit(&ht->sizes->current_update, memory_order_acquire);
    if (cur != NOTHING_IS_UPDATED) {
        LOG("ht_insert: invalid state, current_update=%" PRIu64 " key='%s'\n", cur, key);
        return OA_HASH_INVALD_STATE;
    }
    HashIndexEntry *ht_index = 0;
    int index = find_index(ht, key, &ht_index, stats);
    if (!ht_index) {
        LOG("ht_insert: index full, key='%s'\n", key);
        if (stats) stats->reallocates++;
        return OA_HASH_ERR_INDEX_FULL;
    }

    Key ht_index_as_key = (Key)ht_index->key;
    if (ht_index_as_key.status) {
        set_value(ht, ht_index, value);
    } else {
        uint32_t key_size = next4(strlen(key) + 1);
        uint32_t data_size = key_size + VALUE_SLOTS;
        Sizes capacities = { .storable = atomic_load_explicit(&ht->sizes->capacities, memory_order_acquire) };
        Sizes sizes       = { .storable = atomic_load_explicit(&ht->sizes->sizes,      memory_order_acquire) };
        if (capacities.data <= sizes.data + data_size) {
            LOG("ht_insert: data full, key='%s' used=%u cap=%u need=%u\n",
                key, sizes.data, capacities.data, sizes.data + data_size);
            if (stats) stats->reallocates++;
            return OA_HASH_ERR_DATA_FULL;
        }

        atomic_store_explicit(&ht->sizes->current_update, (uint64_t)index, memory_order_release);
        commit_new_entry(ht, ht_index, key, key_size, value);
        atomic_store_explicit(&ht->sizes->current_update, NOTHING_IS_UPDATED, memory_order_release);
    }
    return OA_HASH_OK;
}

OA_HASH_ERR ht_lookup(HashTable *ht, const char *key, HashEntry *entry) {
    uint64_t cur = atomic_load_explicit(&ht->sizes->current_update, memory_order_acquire);
    if (cur != NOTHING_IS_UPDATED) {
        LOG("ht_lookup: invalid state, current_update=%" PRIu64 " key='%s'\n", cur, key);
        return OA_HASH_INVALD_STATE;
    }
    HashIndexEntry *ht_index = 0;
    find_index(ht, key, &ht_index, 0);
    if (!ht_index || !((Key)ht_index->key).status) {
        return OA_HASH_ERR_NOT_FOUND;
    }

    memcpy(entry->value, get_value(ht, ht_index), VALUE_SIZE);
    entry->key = get_key(ht, ht_index);
    return OA_HASH_OK;
}

void ht_get_entry(HashTable* ht, HashIndexEntry * ht_index, HashEntry *entry) {
    memcpy(entry->value, get_value(ht, ht_index), VALUE_SIZE);
    entry->key = get_key(ht, ht_index);
}

OA_HASH_ERR ht_copy(HashTable *dst, HashTable *src) {
    if (dst->sizes->current_update != NOTHING_IS_UPDATED) {
        return OA_HASH_INVALD_STATE;
    }
    Sizes src_sizes = { .storable = src->sizes->sizes };
    Sizes dst_sizes = { .storable = dst->sizes->sizes };
    Sizes src_capacities = { .storable = src->sizes->capacities };
    Sizes dst_capacities = { .storable = dst->sizes->capacities };
    if (src_sizes.index + dst_sizes.index > dst_capacities.index) {
        return OA_HASH_ERR_INDEX_FULL;
    }
    if (src_sizes.data + dst_sizes.data > dst_capacities.data) {
        return OA_HASH_ERR_DATA_FULL;
    }
    for (size_t i = 0; i < src_capacities.index; i++) {
        HashIndexEntry* ht_index = get_index(src, i);
        if (!((Key)ht_index->key).status){
            continue;
        }
        char *key = get_key(src, ht_index);
        HashIndexEntry* ht_new_index = 0;
        find_index(dst, key, &ht_new_index,0);
        if (!ht_new_index || ((Key)ht_new_index->key).status) {
            return OA_HASH_ERR_INVALID_ARGUMENT;
        }
        *ht_new_index = *ht_index;
        dst_sizes.index += 1;
    }
    memcpy(dst->data_entries, src->data_entries, src_sizes.data * sizeof(HashDataEntry));
    dst_sizes.data += src_sizes.data;
    atomic_store_explicit(&dst->sizes->sizes, dst_sizes.storable, memory_order_release);
    return OA_HASH_OK;
}

void ht_clear_table(HashTable *ht) {
    if (!ht) {
        return;
    }
    Sizes capacities = { .storable = atomic_load_explicit(&ht->sizes->capacities, memory_order_acquire) };
    memset(ht->index_entries, 0,  capacities.index * sizeof(HashIndexEntry));
    memset(ht->data_entries, 0, capacities.data * sizeof(HashDataEntry));
    atomic_store_explicit(&ht->sizes->current_update, NOTHING_IS_UPDATED, memory_order_release);
    atomic_store_explicit(&ht->sizes->sizes, 0, memory_order_release);
}

