#include "shared.h"
#include "safe_posix.h"

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <stdatomic.h>
#include <unistd.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <errno.h>
#include <time.h>

#define SHM_SIZE (sizeof(shm_sync_block))

#include "log.h"

static uint64_t current_time_micros() {
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return (uint64_t) ts.tv_sec * 1000000 + ts.tv_nsec / 1000;
}

int open_shared_memory(shm_mem_chunk* mem_chunk, const char *cb_name, size_t mem_size) {
    int fd = -1;
    void *mem = {0};

    if (cb_name[0] != '/') {
        LOG_ERR("name must start with '/'");
        goto ERROR_BLOCK;
    }
    if (strlen(cb_name) >= NAME_MAX) {
        LOG_ERR("name is too long");
        goto ERROR_BLOCK;
    }
    SAFE_POSIX_CALL_WITH_RES(fd, shm_open(cb_name, O_CREAT | O_RDWR , 0666), -1);
    struct stat st;
    /* Race 2 fix: also ftruncate when the file exists but is smaller than
       requested — this handles the resize (grow) case in reallocate(). */
    if (fstat(fd, &st) == 0 && st.st_size < (off_t)mem_size) {
        SAFE_POSIX_CALL(ftruncate(fd, mem_size), -1);
    }
    SAFE_POSIX_CALL_WITH_RES(mem, mmap(0, mem_size, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0), 0);
    close(fd);
    fd = -1;
    mem_chunk->data = mem;
    mem_chunk->size = mem_size;
    return 0;
ERROR_BLOCK:
    if (fd != -1) {
        close(fd);
    }
    if (mem) {
        munmap(mem, mem_size);
    }
    return -1;
}

int try_lock_shm_for_init(shm_control_block* blk, uint64_t timeout_ms) {
    if (!blk) {
        return -1;
    }

    /* Try to claim initialization: SHM_UNINIT(0) -> SHM_INIT_IN_PROGRESS(1) */
    int expected = SHM_UNINIT;
    if (atomic_compare_exchange_strong_explicit(
            &blk->init_state, &expected,
            SHM_INIT_IN_PROGRESS,
            memory_order_acq_rel, memory_order_acquire)) {
        return 1; /* won the race — caller must initialize */
    }

    /* Lost the race: spin until the winner reaches SHM_INIT_DONE or timeout */
    uint64_t deadline = current_time_micros() + timeout_ms * 1000;
    while (atomic_load_explicit(&blk->init_state, memory_order_acquire)
               == SHM_INIT_IN_PROGRESS) {
        if (current_time_micros() > deadline) {
            LOG("try_lock_shm_for_init: timed out waiting for init\n");
            return -1;
        }
    }

    return (atomic_load_explicit(&blk->init_state, memory_order_acquire)
                == SHM_INIT_DONE) ? 0 : -1;
}

int open_table_in_shm(process *pp) {
    shm_control_block* blk = pp->cntrl_blk.data;
    if (pp->data_blk.data) {
        munmap(pp->data_blk.data, pp->data_blk.size);
    }
    int res = open_shared_memory(&pp->data_blk, blk->name, blk->data_size);
    if (res) {
        LOG("init() open_shared_memory bad_ret_code %d, data block\n", res );
        goto ERROR_BLOCK;
    }
    void* data_mem = pp->data_blk.data;
    if (data_mem == NULL) {
        LOG("init() open_shared_memory, 0 link for data block\n");
        goto ERROR_BLOCK;
    }
    pp->table.sizes = (HashDataSizes*) data_mem;

    LOG("init() open existed shm, cap:{index: %u, data: %u}, sizes:{index: %u, data: %u}\n",
        ((Sizes) pp->table.sizes->capacities).index, ((Sizes) pp->table.sizes->capacities).data,
        ((Sizes) pp->table.sizes->sizes).index, ((Sizes) pp->table.sizes->sizes).data);
    pp->table.index_entries = OFFSET(pp->table.sizes, pp->table.index_entries);
    pp->table.data_entries  = OFFSETA(pp->table.index_entries, ((Sizes)pp->table.sizes->capacities).index, pp->table.data_entries);

    return 0;
ERROR_BLOCK:
    if (pp->data_blk.data) {
        munmap(pp->data_blk.data, pp->data_blk.size);
        pp->data_blk.data = 0; pp->data_blk.size = 0;
    }
    return -1;
}

int reallocate (shm_control_block* cntrl_blk, shm_mem_chunk* data_blk, HashTable* table, Sizes new_capacities) {
    int res;
    size_t mem_size = ht_table_size(new_capacities.index, new_capacities.data);
    HashTable tmp = {0};
    if  (ht_copy_to_local_memory(table, &tmp) != OA_HASH_OK) {;
        LOG("reallocate() failed to copy hash table to local memory\n");
        return -1;
    }
    ht_clear_table(table);
    munmap(data_blk->data, data_blk->size);
    data_blk->data = 0; data_blk->size = 0;
    res = open_shared_memory(data_blk, cntrl_blk->name, mem_size);
    if (res) {
        LOG("reallocate() failed to open shared memory for data block\n");
        free(tmp.sizes);
        return -2;
    }
    ht_init_table(table, new_capacities, data_blk->data);
    res = ht_copy(table, &tmp);
    if (res) {
        LOG("reallocate() failed to copy hash table to shared memory\n");
        free(tmp.sizes);
        return res;
    }
    free(tmp.sizes);

    atomic_store_explicit(&cntrl_blk->data_size, data_blk->size, memory_order_release);
    return 0;
}


int init_shared_mutex(pthread_mutex_t *mutex) {
    pthread_mutexattr_t a;
    pthread_mutexattr_init(&a);
    pthread_mutexattr_setpshared(&a, PTHREAD_PROCESS_SHARED);
#ifdef PTHREAD_MUTEX_ROBUST
    pthread_mutexattr_setrobust(&a, PTHREAD_MUTEX_ROBUST);
#endif
    int rc = pthread_mutex_init(mutex, &a);
    pthread_mutexattr_destroy(&a);
    return rc;
}

int shared_lock(pthread_mutex_t *mutex) {
    int rc = pthread_mutex_lock(mutex);
#ifdef PTHREAD_MUTEX_ROBUST
    if (rc == EOWNERDEAD) {
        // Previous owner died while holding the lock.
        // Repair shared state to a consistent point here.
        // ...
        LOG_ERR("shared_lock: EOWNERDEAD, recovering");
        // Tell the system the state is now consistent:
        pthread_mutex_consistent(mutex);
        return 0;
    }
#endif
    return rc;  // 0 on success; EAGAIN can also occur for robust mutexes
}

