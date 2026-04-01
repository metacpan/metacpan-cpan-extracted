//
// Created by Denys Fisher on 25.08.2025.
//

#ifndef LOG_H
#define LOG_H
#include <time.h>
#include <inttypes.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <pthread.h>

static int              _log_err_enabled = 0;
static pthread_once_t   _log_err_once    = PTHREAD_ONCE_INIT;

static void _log_err_init(void) {
    _log_err_enabled = getenv("SHARED_SIMPLE_DEBUG") != NULL;
}

#define LOG_ERR(fmt, ...)                                              \
    do {                                                               \
        pthread_once(&_log_err_once, _log_err_init);                  \
        if (_log_err_enabled)                                          \
            fprintf(stderr, "[ERR] %s:%d: " fmt "\n",                 \
                    __FILE__, __LINE__, ##__VA_ARGS__);                \
    } while(0)

static uint64_t __current_time_micros() {
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return (uint64_t) ts.tv_sec * 1000000 + ts.tv_nsec / 1000;
}
extern uint64_t p_time;

#define LOG_INIT()                                                            \
    do {                                                                      \
        p_time = __current_time_micros();                                     \
    } while(0)

#define LOG(fstr, ...)                                                        \
    do {                                                                      \
        pid_t pid = getpid();                                                 \
        uint64_t c_time = __current_time_micros() - p_time;                   \
        if (pid % 2 == 0) {                                                   \
            fprintf(stderr, "\t%" PRIu64 " - [%d] " fstr, c_time, pid, ##__VA_ARGS__); \
        }                                                                     \
        else {                                                                \
            fprintf(stderr, "%" PRIu64 " - [%d] " fstr, c_time, pid, ##__VA_ARGS__);   \
        }                                                                     \
    } while(0)

#endif //LOG_H
