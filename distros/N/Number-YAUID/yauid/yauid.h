//
//  yauid.h
//  yauid
//
//  Created by Alexander Borisov on 22.07.14.
//  Copyright (c) 2014 Alexander Borisov. All rights reserved.
//

#ifndef yauid_yauid_h
#define yauid_yauid_h

#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <sys/file.h>
#include <unistd.h>

#if defined(__x86_64__) || defined(__ppc64__) || defined(_WIN64)
#define ENVIRONMENT64
#else
#define ENVIRONMENT32
#endif

// limits
#ifndef LIMIT_MIN_NODE_ID
#define LIMIT_MIN_NODE_ID    1L
#endif

#ifndef BIT_LIMIT
#define BIT_LIMIT           64L
#endif

#ifndef BIT_LIMIT_TIMESTAMP
#define BIT_LIMIT_TIMESTAMP 33L
#endif

#ifndef BIT_LIMIT_NODE
#define BIT_LIMIT_NODE      14L
#endif

#define BIT_LIMIT_INC       (BIT_LIMIT - (BIT_LIMIT_TIMESTAMP + BIT_LIMIT_NODE))

#define NUMBER_LIMIT           ((1L << BIT_LIMIT_INC) - 1)
#define NUMBER_LIMIT_NODE      ((1L << BIT_LIMIT_NODE) - 1)
#define NUMBER_LIMIT_TIMESTAMP ((1L << BIT_LIMIT_TIMESTAMP) - 1)

// 64 bit
typedef uint64_t hkey_t;

enum yauid_status {
    YAUID_OK                    = 0,
    YAUID_ERROR_CREATE_KEY_FILE = 1,
    YAUID_ERROR_OPEN_LOCK_FILE  = 2,
    YAUID_ERROR_KEYS_ENDED      = 3,
    YAUID_ERROR_FILE_NODE_ID    = 4,
    YAUID_ERROR_FILE_NODE_MEM   = 5,
    YAUID_ERROR_FILE_NODE_EXT   = 6,
    YAUID_ERROR_FILE_LOCK       = 7,
    YAUID_ERROR_LONG_NODE_ID    = 8,
    YAUID_ERROR_SHORT_NODE_ID   = 9,
    YAUID_ERROR_READ_KEY        = 10,
    YAUID_ERROR_FILE_SEEK       = 11,
    YAUID_ERROR_WRITE_KEY       = 12,
    YAUID_ERROR_FLUSH_KEY       = 13,
    YAUID_ERROR_TRY_COUNT_KEY   = 14,
    YAUID_ERROR_CREATE_OBJECT   = 15
};

struct yauid {
    int           i_lockfile;
    const char*   c_lockfile;
    FILE*         h_lockfile;
    unsigned long node_id;
    
    unsigned int try_count;
    useconds_t sleep_usec;
    
    enum yauid_status error;
    void *ext_value;
}
typedef yauid;

struct yauid_period_key {
    hkey_t min;
    hkey_t max;
};

yauid * yauid_init(const char *filepath_key, const char *filepath_node_id);
void yauid_destroy(yauid* yaobj);

hkey_t yauid_get_key(yauid* yaobj);
hkey_t yauid_get_key_once(yauid* yaobj);

void yauid_set_node_id(yauid* yaobj, unsigned long node_id);
void yauid_set_sleep_usec(yauid* yaobj, useconds_t sleep_usec);
void yauid_set_try_count(yauid* yaobj, unsigned int try_count);

unsigned long yauid_get_timestamp(hkey_t key);
unsigned long yauid_get_node_id(hkey_t key);
unsigned long yauid_get_inc_id(hkey_t key);

unsigned long long int yauid_get_max_inc();
unsigned long long int yauid_get_max_node_id();
unsigned long long int yauid_get_max_timestamp();

// "2014-07-12 04:23:12" => 1405124592
time_t yauid_datetime_to_timestamp(const char *datetime);
void yauid_get_period_key_by_timestamp(time_t from_timestamp,
                                       time_t to_timestamp,
                                       unsigned long long int from_node_id,
                                       unsigned long long int to_node_id,
                                       struct yauid_period_key *pkey);

void yauid_get_period_key_by_datetime(const char *from_datetime,
                                      const char *to_datetime,
                                      unsigned long long int from_node_id,
                                      unsigned long long int to_node_id,
                                      struct yauid_period_key *pkey);

char * yauid_get_error_text_by_code(enum yauid_status error);

#endif


