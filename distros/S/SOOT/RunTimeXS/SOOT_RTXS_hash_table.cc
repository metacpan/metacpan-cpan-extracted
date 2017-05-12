#include "SOOT_RTXS_hash_table.h"
#include "ppport.h"
#include "MurmurHashNeutral2.h"

#define SOOT_RTXS_string_hash(str, len) SOOT_RTXS_MurmurHashNeutral2(str, len, 12345678)

HashTable* SOOT_RTXS_HashTable_new(UV size, NV threshold) {
    HashTable* table;

    if ((size < 2) || (size & (size - 1))) {
        croak("invalid hash table size: expected a power of 2 (>= 2), got %u", (unsigned)size);
    }

    if (!((threshold > 0) && (threshold < 1))) {
        croak("invalid threshold: expected 0.0 < threshold < 1.0, got %f", threshold);
    }

    Newxz(table, 1, HashTable);

    table->size = size;
    table->threshold = threshold;
    table->items = 0;

    Newxz(table->array, size, HashTableEntry*);

    return table;
}

HashTableEntry* SOOT_RTXS_HashTable_find(HashTable* table, const char* key, STRLEN len) {
    HashTableEntry* entry;
    UV index = SOOT_RTXS_string_hash(key, len) & (table->size - 1);

    for (entry = table->array[index]; entry; entry = entry->next) {
        if (strcmp(entry->key, key) == 0)
            break;
    }

    return entry;
}

/* currently unused */
/*
I32 SOOT_RTXS_HashTable_delete(HashTable* table, const char* key, STRLEN len) {
    HashTableEntry *entry, *prev = NULL;
    UV index = SOOT_RTXS_string_hash(key, len) & (table->size - 1);

    I32 retval = -1;
    for (entry = table->array[index]; entry; prev = entry, entry = entry->next) {
        if (strcmp(entry->key, key) == 0) {

            if (prev) {
                prev->next = entry->next;
            } else {
                table->array[index] = entry->next;
            }

            --(table->items);
            retval = entry->value;
            Safefree(entry->key);
            Safefree(entry);
            break;
        }
    }

    return retval;
}
*/

I32 SOOT_RTXS_HashTable_fetch(HashTable* table, const char* key, STRLEN len) {
    HashTableEntry const * const entry = SOOT_RTXS_HashTable_find(table, key, len);
    return entry ? entry->value : -1;
}

I32 SOOT_RTXS_HashTable_store(HashTable* table, const char* key, STRLEN len, I32 value) {
    I32 retval = -1;
    HashTableEntry* entry = SOOT_RTXS_HashTable_find(table, key, len);

    if (entry) {
        retval = entry->value;
        entry->value = value;
    } else {
        const UV index = SOOT_RTXS_string_hash(key, len) & (table->size - 1);
        Newx(entry, 1, HashTableEntry);

        Newx(entry->key, len+1, char);
        Copy(key, entry->key, len+1, char);
        entry->len   = len;
        entry->value = value;
        entry->next  = table->array[index];

        table->array[index] = entry;
        ++(table->items);

        if (((NV)table->items / (NV)table->size) > table->threshold)
            SOOT_RTXS_HashTable_grow(table);
    }

    return retval;
}

/* double the size of the array */
void SOOT_RTXS_HashTable_grow(HashTable* table) {
    HashTableEntry** array = table->array;
    const UV oldsize = table->size;
    UV newsize = oldsize * 2;
    UV i;

    Renew(array, newsize, HashTableEntry*);
    Zero(&array[oldsize], newsize - oldsize, HashTableEntry*);
    table->size = newsize;
    table->array = array;

    for (i = 0; i < oldsize; ++i, ++array) {
        HashTableEntry **current_entry_ptr, **entry_ptr, *entry;

        if (!*array)
            continue;

        current_entry_ptr = array + oldsize;

        for (entry_ptr = array, entry = *array; entry; entry = *entry_ptr) {
            UV index = SOOT_RTXS_string_hash(entry->key, entry->len) & (newsize - 1);

            if (index != i) {
                *entry_ptr = entry->next;
                entry->next = *current_entry_ptr;
                *current_entry_ptr = entry;
                continue;
            } else {
                entry_ptr = &entry->next;
            }
        }
    }
}

void SOOT_RTXS_HashTable_clear(HashTable *table) {
    if (table && table->items) {
        HashTableEntry** const array = table->array;
        UV riter = table->size - 1;

        do {
            HashTableEntry* entry = array[riter];

            while (entry) {
                HashTableEntry* const temp = entry;
                entry = entry->next;
                if (temp->key)
                    Safefree(temp->key);
                Safefree(temp);
            }

            /* chocolateboy 2008-01-08
             *
             * make sure we clear the array entry, so that subsequent probes fail
             */

            array[riter] = NULL;
        } while (riter--);

        table->items = 0;
    }
}

void SOOT_RTXS_HashTable_free(HashTable* table) {
    if (table) {
        SOOT_RTXS_HashTable_clear(table);
        Safefree(table);
    }
}

