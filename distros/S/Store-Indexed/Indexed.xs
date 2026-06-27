#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"
#include <stdint.h>

typedef struct {
    int cols;
    int max_rows;
    uint32_t *offsets; // 4-byte offsets instead of 8-byte pointers
    char *pool;        // The packed string slab
    size_t pool_size;
    size_t pool_used;
} IndexedStore;

MODULE = Store::Indexed::XS  PACKAGE = Store::Indexed::XS

PROTOTYPES: ENABLE

SV *
_new(char *class, int cols)
    CODE:
        IndexedStore *self = (IndexedStore *)malloc(sizeof(IndexedStore));
        self->cols = cols;
        self->max_rows = 1000;
        // 4 bytes per entry
        self->offsets = (uint32_t *)calloc(self->max_rows * self->cols, sizeof(uint32_t));
        self->pool_size = 1024 * 1024; // Start with 1MB arena
        self->pool = (char *)malloc(self->pool_size);
        self->pool_used = 1; // Start at 1, so 0 can mean "undef"
        self->pool[0] = '\0';
        
        SV *sv = newSV(0);
        sv_setref_pv(sv, class, (void*)self);
        RETVAL = sv;
    OUTPUT:
        RETVAL

void
_set(SV *obj, int id, int col, SV *val)
    CODE:
        IndexedStore *self = INT2PTR(IndexedStore *, SvIV(SvRV(obj)));
        if (id >= self->max_rows) {
            int old_max = self->max_rows;
            self->max_rows = id + 1000;
            self->offsets = (uint32_t *)realloc(self->offsets, self->max_rows * self->cols * sizeof(uint32_t));
            memset(self->offsets + (old_max * self->cols), 0, (self->max_rows - old_max) * self->cols * sizeof(uint32_t));
        }

        STRLEN len;
        char *str = SvPV(val, len);
        
        // Ensure pool has space (len + 1 for null terminator)
        if (self->pool_used + len + 1 > self->pool_size) {
            self->pool_size += (len + 1024);
            self->pool = (char *)realloc(self->pool, self->pool_size);
        }

        int idx = id * self->cols + col;
        self->offsets[idx] = (uint32_t)self->pool_used;
        memcpy(self->pool + self->pool_used, str, len + 1);
        self->pool_used += (len + 1);

SV *
_get(SV *obj, int id, int col)
    CODE:
        IndexedStore *self = INT2PTR(IndexedStore *, SvIV(SvRV(obj)));
        if (id < 0 || id >= self->max_rows || self->offsets[id * self->cols + col] == 0) {
            RETVAL = &PL_sv_undef;
        } else {
            uint32_t offset = self->offsets[id * self->cols + col];
            RETVAL = newSVpv(self->pool + offset, 0);
        }
    OUTPUT:
        RETVAL

bool
_exists(SV *obj, int id, int col)
    CODE:
        IndexedStore *self = INT2PTR(IndexedStore *, SvIV(SvRV(obj)));
        // Check bounds and ensure the offset is not 0 (our "empty" marker)
        if (id < 0 || id >= self->max_rows) {
            RETVAL = 0;
        } else {
            uint32_t offset = self->offsets[id * self->cols + col];
            RETVAL = (offset != 0);
        }
    OUTPUT:
        RETVAL

void
_delete(SV *obj, int id, int col)
    CODE:
        IndexedStore *self = INT2PTR(IndexedStore *, SvIV(SvRV(obj)));
        if (id >= 0 && id < self->max_rows) {
            // Simply reset the offset to 0. 
            // The memory in the pool is still there, but it is now 
            // logically unreachable and thus "deleted".
            self->offsets[id * self->cols + col] = 0;
        }

void
DESTROY(SV *obj)
    CODE:
        IndexedStore *self = INT2PTR(IndexedStore *, SvIV(SvRV(obj)));
        if (self) {
            free(self->offsets);
            free(self->pool);
            free(self);
            sv_setiv(SvRV(obj), 0);
        }