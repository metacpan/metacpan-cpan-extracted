//
// Created by Denys Fisher on 29.03.2025.
//

#ifndef SHARED_H
#define SHARED_H

#include "oa_hash.h"
#include <pthread.h>
#include <stdint.h>
#define NAME_MAX 255

typedef enum {
    SHM_UNINIT           = 0, /* kernel zero-initializes new shm objects */
    SHM_INIT_IN_PROGRESS = 1,
    SHM_INIT_DONE        = 2,
} shm_init_state;

typedef enum {
    SHM_OPEN_SHARED    = 0, /* create if absent, attach if present */
    SHM_OPEN_EXCLUSIVE = 1, /* unlink any existing segments, always create fresh */
} shm_open_mode;

/** shared memory control block representation
 * control block is used for synchronizing access to shared memory and storing its metadata
 * it is fixed size and should never be resizes or reallocated
 * init_state - initialization state machine (0=uninit, 1=in progress, 2=done)
 * data_size  - size of dynamic shared memory where hash table is stored
 * name       - file name of dynamic shared memory (without /dev/shm)
 * lock       - mutex for synchronizing access to shared memory
 */
typedef struct shm_control_block {
    ATOMIC(int)      init_state;
    ATOMIC(uint64_t) data_size;
    char name[NAME_MAX];
    pthread_mutex_t lock;
} shm_control_block;

/** shared memory chunk representation
 * data - pointer to memory
 * size - size of memory in bytes
 */
typedef struct shm_mem_chunk {
    void *data;
    size_t size;
} shm_mem_chunk;

/** the main structure representing a process working with shared memory
 * cntrl_blk - control block in shared memory
 * data_blk - data block in shared memory
 * table - hash table in shared memory
 */
typedef struct {
    shm_mem_chunk cntrl_blk;
    shm_mem_chunk data_blk;
    HashTable table;
} process;

/** opens shared memory with given name and size, creates it if not exists
 * @param mem_chunk struct shm_mem_chunk*, filled if function succeeds, otherwise remains unchanged
 * @param name string with shared memory name, must start with '/', max length NAME_MAX
 * @param mem_size size of shared memory to create, must be greater than 0
 * @return -1 if error occurred, 0 if shared memory opened successfully
 */
int open_shared_memory(shm_mem_chunk *mem_chunk, const char *name, size_t mem_size);

/** checks init_state and races to claim initialization
 *
 * @param blk pointer to shared memory control block
 * @param timeout_ms timeout in milliseconds to wait when another process is initializing
 * @return  1 — won the race (caller must initialize, then set init_state = SHM_INIT_DONE)
 *          0 — already initialized (caller should attach)
 *         -1 — timeout or unexpected state
 */
int try_lock_shm_for_init(shm_control_block *blk, uint64_t timeout_ms);
/** copies existing hash table to local memory, resizes shared memory and copies table back
 *
 * @param cntrl_blk shm_control_block* control block of shared memory
 * @param data_blk shm_mem_chunk*
 * @param new_capacities new capacities for hash table
 * @return 0 if success, -1 if error occurred
 */
int reallocate (shm_control_block* cntrl_blk, shm_mem_chunk* data_blk, HashTable* table, Sizes new_capacities);
/** maps existing sh
 *
 */
int open_table_in_shm(process *p);

int init_shared_mutex(pthread_mutex_t *mutex);

int shared_lock(pthread_mutex_t *mutex);

int init_shm_control_block(shm_control_block *blk, const char *name, size_t size);

void destroy_shm_control_block(shm_control_block *blk);

void *create_shared_memory(int fd, size_t size);

#endif //SHARED_H
