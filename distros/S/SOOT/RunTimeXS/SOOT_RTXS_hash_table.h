/*
 * chocolateboy 2009-02-25
 *
 * This is a customised version of the pointer table implementation in sv.c
 *
 * smueller 2009-11-03
 *
 * - Taken from chocolateboy's B-Hooks-OP-Annotation.
 * - Added string-to-PTRV conversion using MurmurHash2.
 * - Converted to storing I32s (Class::XSAccessor indexes of the key name storage)
 *   instead of OP structures (pointers).
 * - Plenty of renaming and prefixing with CXSA_.
 * 
 * smueller 2010-03-31
 *
 * - Import a copy into SOOT with renaming of the prefix to SOOT_RTXS_
 * - Split into header and implementation.
 * - TODO: Could do with a C++ification considering SOOT is already C++
 */

#ifndef _SOOT_RTXS_hash_table_h_
#define _SOOT_RTXS_hash_table_h_

#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"
#undef do_open
#undef do_close
#ifdef __cplusplus
}
#endif

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

/* I32 SOOT_RTXS_HashTable_delete(HashTable* table, const char* key, STRLEN len); */
I32 SOOT_RTXS_HashTable_fetch(HashTable* table, const char* key, STRLEN len);
I32 SOOT_RTXS_HashTable_store(HashTable* table, const char* key, STRLEN len, I32 value);
HashTableEntry* SOOT_RTXS_HashTable_find(HashTable* table, const char* key, STRLEN len);
HashTable* SOOT_RTXS_HashTable_new(UV size, NV threshold);
void SOOT_RTXS_HashTable_clear(HashTable* table);
void SOOT_RTXS_HashTable_free(HashTable* table);
void SOOT_RTXS_HashTable_grow(HashTable* table);

#endif /* ifndef _SOOT_RTXS_hash_table_h_ */

