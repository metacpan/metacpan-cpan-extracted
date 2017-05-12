#ifndef _cxsa_memory_h_
#define _cxsa_memory_h_

#include "EXTERN.h"
/* for the STRLEN typedef, for better or for worse */
#include "perl.h"

void* _cxa_realloc(void *ptr, STRLEN size);
void* _cxa_malloc(STRLEN size);
void* _cxa_zmalloc(STRLEN size);
void _cxa_free(void *ptr);
void* _cxa_memcpy(void *dest, void *src, STRLEN size);

void* _cxa_realloc(void *ptr, STRLEN size) {
    return realloc(ptr, size);
}

void* _cxa_malloc(STRLEN size) {
    return malloc(size);
}

void* _cxa_zmalloc(STRLEN size) {
    return calloc(1, size);
}

void _cxa_free(void *ptr) {
    free(ptr);
}

void* _cxa_memcpy(void *dest, void *src, STRLEN size) {
    return memcpy(dest, src, size);
}

void* _cxa_memzero(void *ptr, STRLEN size) {
    return memset(ptr, 0, size);
}

/* these macros are really what you should be calling: */

#define cxa_free(ptr) _cxa_free(ptr)
#define cxa_realloc(ptr, size) _cxa_realloc(ptr, size)
#define cxa_malloc(size) _cxa_malloc(size)
#define cxa_zmalloc(size) _cxa_zmalloc(size)
#define cxa_memcpy(dest, src, size) _cxa_memcpy(dest, src, size)
#define cxa_memzero(ptr, size) _cxa_memzero(ptr, size)

/* TODO: A function call on every memory operation seems expensive.
 *       Right now, it's not so bad and benchmarks show no harm done.
 *       The hit should really only matter during global destruction and
 *       BEGIN{} when accessors are set up.
 */

#endif
