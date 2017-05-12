/*
 * chocolateboy 2009-02-25
 *
 * This is a customised version of the pointer table implementation in sv.c
 *
 * tsee 2009-11-03
 *
 * - Taken from chocolateboy's B-Hooks-OP-Annotation.
 * - Added string-to-PTRV conversion using MurmurHash2.
 * - Converted to storing I32s (Class::XSAccessor indexes of the key name storage)
 *   instead of OP structures (pointers).
 * - Plenty of renaming and prefixing with CXSA_.
 */

#include "ppport.h"
#include "MurmurHashNeutral2.h"

#define CXSA_string_hash(str, len) CXSA_MurmurHashNeutral2(str, len, 12345678)

typedef struct HashTableEntry {
    struct HashTableEntry* next;
    const char* key;
    STRLEN len;
    I32 value;
} HashTableEntry;

typedef struct {
    struct HashTableEntry** array;
    UV size;
    UV items;
    NV threshold;
} HashTable;

/* STATIC I32 CXSA_HashTable_delete(HashTable* table, const char* key, STRLEN len); */
STATIC I32 CXSA_HashTable_fetch(HashTable* table, const char* key, STRLEN len);
STATIC I32 CXSA_HashTable_store(HashTable* table, const char* key, STRLEN len, I32 value);
STATIC HashTableEntry* CXSA_HashTable_find(HashTable* table, const char* key, STRLEN len);
STATIC HashTable* CXSA_HashTable_new(UV size, NV threshold);
STATIC void CXSA_HashTable_clear(HashTable* table);
STATIC void CXSA_HashTable_free(HashTable* table);
STATIC void CXSA_HashTable_grow(HashTable* table);

STATIC HashTable* CXSA_HashTable_new(UV size, NV threshold) {
    HashTable* table;

    if ((size < 2) || (size & (size - 1))) {
        croak("invalid hash table size: expected a power of 2 (>= 2), got %u", (unsigned)size);
    }

    if (!((threshold > 0) && (threshold < 1))) {
        croak("invalid threshold: expected 0.0 < threshold < 1.0, got %f", threshold);
    }

    table = (HashTable*)cxa_zmalloc(sizeof(HashTable));

    table->size = size;
    table->threshold = threshold;
    table->items = 0;

    table->array = (HashTableEntry**)cxa_zmalloc(size * sizeof(HashTableEntry*));

    return table;
}

STATIC HashTableEntry* CXSA_HashTable_find(HashTable* table, const char* key, STRLEN len) {
    HashTableEntry* entry;
    UV index = CXSA_string_hash(key, len) & (table->size - 1);

    for (entry = table->array[index]; entry; entry = entry->next) {
        if (strcmp(entry->key, key) == 0)
            break;
    }

    return entry;
}

/* currently unused */
/*
STATIC I32 CXSA_HashTable_delete(HashTable* table, const char* key, STRLEN len) {
    HashTableEntry *entry, *prev = NULL;
    UV index = CXSA_string_hash(key, len) & (table->size - 1);

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

STATIC I32 CXSA_HashTable_fetch(HashTable* table, const char* key, STRLEN len) {
    HashTableEntry const * const entry = CXSA_HashTable_find(table, key, len);
    return entry ? entry->value : -1;
}

STATIC I32 CXSA_HashTable_store(HashTable* table, const char* key, STRLEN len, I32 value) {
    I32 retval = -1;
    HashTableEntry* entry = CXSA_HashTable_find(table, key, len);

    if (entry) {
        retval = entry->value;
        entry->value = value;
    } else {
        const UV index = CXSA_string_hash(key, len) & (table->size - 1);
        entry = (HashTableEntry*)cxa_malloc(sizeof(HashTableEntry));

        entry->key = (char*)cxa_malloc( (len+1) );
        cxa_memcpy((void*)entry->key, (void*)key, len+1);
        /*Copy(key, entry->key, len+1, char);*/
        entry->len   = len;
        entry->value = value;
        entry->next  = table->array[index];

        table->array[index] = entry;
        ++(table->items);

        if (((NV)table->items / (NV)table->size) > table->threshold)
            CXSA_HashTable_grow(table);
    }

    return retval;
}

/* double the size of the array */
STATIC void CXSA_HashTable_grow(HashTable* table) {
    HashTableEntry** array = table->array;
    const UV oldsize = table->size;
    UV newsize = oldsize * 2;
    UV i;

    array = (HashTableEntry**)cxa_realloc((void*)array, sizeof(HashTableEntry*)*newsize);
    cxa_memzero(&array[oldsize], (newsize-oldsize)*sizeof(HashTableEntry*));

    /*Renew(array, newsize, HashTableEntry*);
    Zero(&array[oldsize], newsize - oldsize, HashTableEntry*);
    */
    table->size = newsize;
    table->array = array;

    for (i = 0; i < oldsize; ++i, ++array) {
        HashTableEntry **current_entry_ptr, **entry_ptr, *entry;

        if (!*array)
            continue;

        current_entry_ptr = array + oldsize;

        for (entry_ptr = array, entry = *array; entry; entry = *entry_ptr) {
            UV index = CXSA_string_hash(entry->key, entry->len) & (newsize - 1);

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

STATIC void CXSA_HashTable_clear(HashTable *table) {
    if (table && table->items) {
        HashTableEntry** const array = table->array;
        UV riter = table->size - 1;

        do {
            HashTableEntry* entry = array[riter];

            while (entry) {
                HashTableEntry* const temp = entry;
                entry = entry->next;
                if (temp->key)
                    cxa_free((void*)temp->key);
                cxa_free(temp);
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

STATIC void CXSA_HashTable_free(HashTable* table) {
    if (table) {
        CXSA_HashTable_clear(table);
        cxa_free(table->array);
        cxa_free(table);
    }
}

