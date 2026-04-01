//
// Created by Denys Fisher on 17.08.2025.
//

#ifndef SAFE_POSIX_H
#define SAFE_POSIX_H

#include "log.h"
#include <errno.h>

#define SAFE_POSIX_CALL_WITH_RES(val, call, error_code)           \
do {                                                              \
    val = (call);                                                 \
    if (val == error_code) {                                      \
        LOG_ERR("%s: %s", #call, strerror(errno));                \
        goto ERROR_BLOCK;                                         \
    }                                                             \
} while(0)

#define SAFE_POSIX_CALL(call, error_code)                         \
do {                                                              \
    int res; SAFE_POSIX_CALL_WITH_RES(res, call, error_code);     \
} while (0)

#define SAFE_PTHREAD_CALL(call)                                   \
do {                                                              \
    int res = (call);                                             \
    if (!res) {                                                   \
        LOG_ERR("%s: %s", #call, strerror(res));                  \
        goto ERROR_BLOCK;                                         \
    }                                                             \
} while (0)

#define SAFE_PTHREAD_0CALL(call)                                  \
do {                                                              \
    int res = (call);                                             \
    if (res) {                                                    \
        LOG_ERR("%s: %s", #call, strerror(res));                  \
        goto ERROR_BLOCK;                                         \
    }                                                             \
} while (0)

#endif //SAFE_POSIX_H
