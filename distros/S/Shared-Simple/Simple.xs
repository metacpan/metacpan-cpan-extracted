#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <sys/mman.h>
#include <stdatomic.h>
#include "src/shared.h"
#include "src/log.h"

uint64_t p_time;

MODULE = Shared::Simple		PACKAGE = Shared::Simple

SV*
new(class, name, mode = SHM_OPEN_SHARED)
    SV*   class
    char* name
    int   mode
  PREINIT:
    process*           p;
    shm_control_block* blk;
    char               ctrl_name[NAME_MAX + 2];
    char               data_name[NAME_MAX + 8];
    int                rc;
  CODE:
    if (snprintf(ctrl_name, sizeof(ctrl_name), "/%s",      name) >= (int)sizeof(ctrl_name) ||
        snprintf(data_name, sizeof(data_name), "/%s_data", name) >= (int)sizeof(data_name)) {
        croak("Shared::Simple::new: name too long");
    }

    if (mode == SHM_OPEN_EXCLUSIVE) {
        /* Wipe any existing segments so we always start with a clean slate.
           Errors are ignored — the segments may not exist yet. */
        shm_unlink(ctrl_name);
        shm_unlink(data_name);
    }

    Newxz(p, 1, process);

    if (open_shared_memory(&p->cntrl_blk, ctrl_name, sizeof(shm_control_block)) != 0) {
        Safefree(p);
        croak("Shared::Simple::new: failed to open control block '%s'", ctrl_name);
    }

    blk = (shm_control_block*) p->cntrl_blk.data;
    rc  = try_lock_shm_for_init(blk, 5000);

    if (rc == 1) {
        /* won the init race — first process, set up a fresh table */
        Sizes  caps      = { .index = 64, .data = 512 };
        size_t data_size = ht_table_size(caps.index, caps.data);

        init_shared_mutex(&blk->lock);
        strncpy(blk->name, data_name, NAME_MAX - 1);
        blk->name[NAME_MAX - 1] = '\0';

        if (open_shared_memory(&p->data_blk, data_name, data_size) != 0) {
            munmap(p->cntrl_blk.data, p->cntrl_blk.size);
            Safefree(p);
            croak("Shared::Simple::new: failed to create data block '%s'", data_name);
        }
        ht_init_table(&p->table, caps, p->data_blk.data);
        /* data_size must be visible before init_state — release ordering ensures
           that any process seeing SHM_INIT_DONE also sees the correct data_size. */
        atomic_store_explicit(&blk->data_size,  (uint64_t)data_size, memory_order_release);
        atomic_store_explicit(&blk->init_state, SHM_INIT_DONE,       memory_order_release);
        LOG("create new shm %s with %llu\n", blk->name, (unsigned long long)blk->data_size);

    } else if (rc == 0) {
        /* already initialized — acquire the mutex before attaching so we
           cannot race with a concurrent reallocate() (Race 3a fix). */
        LOG("attaching to already initialized shm %s with %llu\n", blk->name, (unsigned long long)blk->data_size);
        if (shared_lock(&blk->lock) != 0) {
            munmap(p->cntrl_blk.data, p->cntrl_blk.size);
            Safefree(p);
            croak("Shared::Simple::new: failed to acquire lock for attach");
        }
        int tbl_rc = open_table_in_shm(p);
        pthread_mutex_unlock(&blk->lock);
        if (tbl_rc != 0) {
            munmap(p->cntrl_blk.data, p->cntrl_blk.size);
            Safefree(p);
            croak("Shared::Simple::new: failed to open existing data block");
        }
    } else {
        /* timeout waiting for another process to finish initializing */
        munmap(p->cntrl_blk.data, p->cntrl_blk.size);
        Safefree(p);
        croak("Shared::Simple::new: timed out waiting for shared memory initialization");
    }

    RETVAL = sv_bless(
        newRV_noinc(newSViv(PTR2IV(p))),
        gv_stashsv(class, GV_ADD)
    );
  OUTPUT:
    RETVAL

int
put(self, key, value)
    SV* self
    SV* key
    SV* value
  PREINIT:
    process*           p;
    shm_control_block* blk;
    const char*        kstr;
    STRLEN             klen;
    STRLEN             vlen;
    OA_HASH_ERR        err;
    Stats              stats;
  CODE:
    if (!SvOK(key))
        croak("Shared::Simple::put: key must be defined");
    kstr = SvPV(key, klen);
    if (klen == 0)
        croak("Shared::Simple::put: key must not be empty");
    if (!SvOK(value))
        croak("Shared::Simple::put: value must be defined");
    const char* vstr = SvPV(value, vlen);
    if (vlen == 0)
        croak("Shared::Simple::put: value must not be empty");
    if (vlen > VALUE_SIZE)
        croak("Shared::Simple::put: value must not exceed %d bytes", VALUE_SIZE);

    char val_buf[VALUE_SIZE];
    memset(val_buf, 0, VALUE_SIZE);
    memcpy(val_buf, vstr, vlen);

    p   = INT2PTR(process*, SvIV(SvRV(self)));
    blk = (shm_control_block*) p->cntrl_blk.data;
    memset(&stats, 0, sizeof(stats));

    if (shared_lock(&blk->lock) != 0)
        croak("Shared::Simple::put: failed to acquire lock");

    /* Race 3b: re-attach if another process resized the data block */
    if ((uint64_t)p->data_blk.size !=
            atomic_load_explicit(&blk->data_size, memory_order_acquire)) {
        if (open_table_in_shm(p) != 0) {
            pthread_mutex_unlock(&blk->lock);
            croak("Shared::Simple::put: failed to re-attach resized data block");
        }
    }

    err = ht_insert(&p->table, kstr, val_buf, &stats);
    if (err == OA_HASH_ERR_INDEX_FULL || err == OA_HASH_ERR_DATA_FULL) {
        Sizes new_caps = ht_resize_table(&p->table, 2);
        if (reallocate(blk, &p->data_blk, &p->table, new_caps) != 0) {
            pthread_mutex_unlock(&blk->lock);
            croak("Shared::Simple::put: failed to reallocate shared memory");
        }
        err = ht_insert(&p->table, kstr, val_buf, &stats);
    }
    pthread_mutex_unlock(&blk->lock);

    if (err != OA_HASH_OK)
        croak("Shared::Simple::put: insert failed (%d)", (int)err);
    RETVAL = 1;
  OUTPUT:
    RETVAL

SV*
get(self, key)
    SV* self
    SV* key
  PREINIT:
    process*           p;
    shm_control_block* blk;
    const char*        kstr;
    STRLEN             klen;
    HashEntry          entry;
    OA_HASH_ERR        err;
  CODE:
    if (!SvOK(key))
        croak("Shared::Simple::get: key must be defined");
    kstr = SvPV(key, klen);
    if (klen == 0)
        croak("Shared::Simple::get: key must not be empty");

    p   = INT2PTR(process*, SvIV(SvRV(self)));
    blk = (shm_control_block*) p->cntrl_blk.data;

    if (shared_lock(&blk->lock) != 0)
        croak("Shared::Simple::get: failed to acquire lock");

    /* Race 3b: re-attach if another process resized the data block */
    if ((uint64_t)p->data_blk.size !=
            atomic_load_explicit(&blk->data_size, memory_order_acquire)) {
        if (open_table_in_shm(p) != 0) {
            pthread_mutex_unlock(&blk->lock);
            croak("Shared::Simple::get: failed to re-attach resized data block");
        }
    }

    err = ht_lookup(&p->table, kstr, &entry);
    pthread_mutex_unlock(&blk->lock);

    if (err == OA_HASH_ERR_NOT_FOUND) {
        RETVAL = newSV(0); /* undef — key not present */
    } else if (err != OA_HASH_OK) {
        croak("Shared::Simple::get: lookup failed (%d)", (int)err);
    } else {
        RETVAL = newSVpvn(entry.value, strnlen(entry.value, VALUE_SIZE));
    }
  OUTPUT:
    RETVAL

IV
get_size(self)
    SV* self
  PREINIT:
    process* p;
    Sizes    sizes;
  CODE:
    p              = INT2PTR(process*, SvIV(SvRV(self)));
    sizes.storable = atomic_load_explicit(&p->table.sizes->sizes, memory_order_acquire);
    RETVAL         = (IV)sizes.index;
  OUTPUT:
    RETVAL

SV*
get_all(self)
    SV* self
  PREINIT:
    process*           p;
    shm_control_block* blk;
    Sizes              capacities;
    HV*                result;
    uint32_t           i;
    HashEntry          entry;
  CODE:
    p   = INT2PTR(process*, SvIV(SvRV(self)));
    blk = (shm_control_block*) p->cntrl_blk.data;

    if (shared_lock(&blk->lock) != 0)
        croak("Shared::Simple::get_all: failed to acquire lock");

    if ((uint64_t)p->data_blk.size !=
            atomic_load_explicit(&blk->data_size, memory_order_acquire)) {
        if (open_table_in_shm(p) != 0) {
            pthread_mutex_unlock(&blk->lock);
            croak("Shared::Simple::get_all: failed to re-attach resized data block");
        }
    }

    result      = newHV();
    capacities.storable = atomic_load_explicit(&p->table.sizes->capacities, memory_order_acquire);

    for (i = 0; i < capacities.index; i++) {
        HashIndexEntry* idx = p->table.index_entries + i;
        Key k = { .storable = atomic_load_explicit(&idx->key, memory_order_acquire) };
        if (k.status != COMMITED)
            continue;
        ht_get_entry(&p->table, idx, &entry);
        hv_store(result,
                 entry.key, strlen(entry.key),
                 newSVpvn(entry.value, strnlen(entry.value, VALUE_SIZE)),
                 0);
    }

    pthread_mutex_unlock(&blk->lock);
    RETVAL = newRV_noinc((SV*)result);
  OUTPUT:
    RETVAL

void
DESTROY(self)
    SV* self
  PREINIT:
    process* p;
  CODE:
    p = INT2PTR(process*, SvIV(SvRV(self)));
    if (p->data_blk.data)
        munmap(p->data_blk.data, p->data_blk.size);
    if (p->cntrl_blk.data)
        munmap(p->cntrl_blk.data, p->cntrl_blk.size);
    Safefree(p);

BOOT:
{
    HV *stash = gv_stashpv("Shared::Simple", GV_ADD);
    newCONSTSUB(stash, "SHARED",    newSViv(SHM_OPEN_SHARED));
    newCONSTSUB(stash, "EXCLUSIVE", newSViv(SHM_OPEN_EXCLUSIVE));
}
