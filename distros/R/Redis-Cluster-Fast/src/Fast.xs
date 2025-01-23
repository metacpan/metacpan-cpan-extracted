#ifdef __cplusplus
extern "C" {
#endif

#define PERL_NO_GET_CONTEXT /* we want efficiency */
#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <time.h>
#include "hiredis_cluster/adapters/libevent.h"
#include "hiredis_cluster/hircluster.h"

#ifdef __cplusplus
} /* extern "C" */
#endif

#define NEED_newRV_noinc
#define NEED_my_strlcpy
#include "ppport.h"

#define ONE_SECOND_TO_MICRO 1000000
#define NANO_SECOND_TO_MICRO 1000

#define MIN_ATTEMPT_TO_GET_RESULT 2

#define DEBUG_MSG(fmt, ...) \
    if (self->debug) {                                                  \
        fprintf(stderr, "[%d][%d][%s:%d:%s]: ", getpid(), getppid(), __FILE__, __LINE__, __func__);  \
        fprintf(stderr, fmt, __VA_ARGS__);                              \
        fprintf(stderr, "\n");                                          \
    }

#define DEBUG_EVENT_BASE() \
    if (self->debug) {                                                  \
        event_base_dump_events(self->cluster_event_base, stderr);       \
    }

typedef struct redis_cluster_fast_reply_s {
    SV *result;
    SV *error;
} redis_cluster_fast_reply_t;

typedef struct cmd_reply_context_s {
    void *self;
    SV *result;
    SV *error;
    int done;
} cmd_reply_context_t;

typedef struct cmd_reply_context_pipeline_s {
    void *self;
    SV *result;
    SV *error;
    SV *cb;
} cmd_reply_context_pipeline_t;

typedef struct redis_cluster_fast_s {
    redisClusterAsyncContext *acc;
    struct event_base *cluster_event_base;
    char *hostnames;
    int debug;
    int max_retry;
    int use_cluster_slots;
    int event_ready;
    struct timeval connect_timeout;
    struct timeval command_timeout;
    int64_t discovery_timeout_usec;
    pid_t pid;
    int64_t pipeline_callback_remain;
} redis_cluster_fast_t, *Redis__Cluster__Fast;

int64_t get_usec_timestamp(void) {
    struct timespec ts;
    int status;
    status = clock_gettime(CLOCK_MONOTONIC, &ts);
    if (status < 0) {
        return -1;
    }
    return (int64_t) ts.tv_sec * ONE_SECOND_TO_MICRO + (int64_t) (ts.tv_nsec / NANO_SECOND_TO_MICRO);
}

static redis_cluster_fast_reply_t
Redis__Cluster__Fast_decode_reply(pTHX_ Redis__Cluster__Fast self, redisReply *reply) {
    redis_cluster_fast_reply_t res = {NULL, NULL};

    switch (reply->type) {
        case REDIS_REPLY_ERROR:
            res.error = newSVpvn(reply->str, reply->len);
            break;

        case REDIS_REPLY_BIGNUM:
        case REDIS_REPLY_DOUBLE:
        case REDIS_REPLY_STATUS:
        case REDIS_REPLY_STRING:
        case REDIS_REPLY_VERB:
            res.result = newSVpvn(reply->str, reply->len);
            break;

        case REDIS_REPLY_INTEGER:
        case REDIS_REPLY_BOOL:
            res.result = newSViv(reply->integer);
            break;
        case REDIS_REPLY_NIL:
            res.result = &PL_sv_undef;
            break;

        case REDIS_REPLY_MAP:
        case REDIS_REPLY_SET:
        case REDIS_REPLY_ATTR: {
            size_t i;
            char *key;
            HV *hv = newHV();

            res.result = newRV_noinc((SV *) hv);

            for (i = 0; i < reply->elements; i++) {
                if (i % 2 == 0) {
                    key = reply->element[i]->str;
                } else {
                    redis_cluster_fast_reply_t elem = {NULL, NULL};
                    elem = Redis__Cluster__Fast_decode_reply(aTHX_ self, reply->element[i]);
                    if (elem.result) {
                        hv_store(hv, key, strlen(key), SvREFCNT_inc(elem.result), 0);
                    } else {
                        hv_store(hv, key, strlen(key), newSV(0), 0);
                    }
                    if (elem.error && !res.error) {
                        res.error = elem.error;
                    }
                }
            }
            break;
        }

        case REDIS_REPLY_PUSH:
        case REDIS_REPLY_ARRAY: {
            AV *av = newAV();
            size_t i;
            res.result = newRV_noinc((SV *) av);

            for (i = 0; i < reply->elements; i++) {
                redis_cluster_fast_reply_t elem = {NULL, NULL};
                elem = Redis__Cluster__Fast_decode_reply(aTHX_ self, reply->element[i]);
                if (elem.result) {
                    av_push(av, elem.result);
                } else {
                    av_push(av, newSV(0));
                }
                if (elem.error && !res.error) {
                    res.error = elem.error;
                }
            }
            break;
        }
    }

    return res;
}

void replyCallback(redisClusterAsyncContext *cc, void *r, void *privdata) {
    dTHX;

    cmd_reply_context_t *reply_t;
    Redis__Cluster__Fast self;
    redisReply *reply;

    reply_t = (cmd_reply_context_t *) privdata;
    self = (Redis__Cluster__Fast) reply_t->self;
    DEBUG_MSG("replycb %s", "start");

    reply = (redisReply *) r;
    if (reply) {
        redis_cluster_fast_reply_t res;
        res = Redis__Cluster__Fast_decode_reply(aTHX_ self, reply);
        reply_t->result = res.result;
        reply_t->error = res.error;
    } else {
        DEBUG_MSG("error: err=%d errstr=%s", cc->err, cc->errstr);
        reply_t->error = newSVpvf("%s", cc->errstr);
    }

    reply_t->done = 1;
}

void replyCallbackPipeline(redisClusterAsyncContext *cc, void *r, void *privdata) {
    dTHX;

    cmd_reply_context_pipeline_t *reply_pipeline_t;
    Redis__Cluster__Fast self;
    redisReply *reply;

    reply_pipeline_t = (cmd_reply_context_pipeline_t *) privdata;
    self = (Redis__Cluster__Fast) reply_pipeline_t->self;
    DEBUG_MSG("replycb pipeline %s", "start");

    reply = (redisReply *) r;
    if (reply) {
        redis_cluster_fast_reply_t res;
        res = Redis__Cluster__Fast_decode_reply(aTHX_ self, reply);
        reply_pipeline_t->result = res.result;
        reply_pipeline_t->error = res.error;
    } else {
        DEBUG_MSG("error: err=%d errstr=%s", cc->err, cc->errstr);
        reply_pipeline_t->error = newSVpvf("%s", cc->errstr);
    }

    {
        dSP;

        ENTER;
        SAVETMPS;

        PUSHMARK(SP);
        EXTEND(SP, 2);
        PUSHs(reply_pipeline_t->result ? sv_2mortal(reply_pipeline_t->result) : &PL_sv_undef);
        PUSHs(reply_pipeline_t->error ? sv_2mortal(reply_pipeline_t->error) : &PL_sv_undef);
        PUTBACK;

        call_sv(reply_pipeline_t->cb, G_DISCARD);

        FREETMPS;
        LEAVE;
    }

    SvREFCNT_dec(reply_pipeline_t->cb);
    Safefree(reply_pipeline_t);

    self->pipeline_callback_remain--;
    DEBUG_MSG("pipeline callback remain: %ld", self->pipeline_callback_remain);
}

void eventCallback(const redisClusterContext *cc, int event, void *privdata) {
    Redis__Cluster__Fast self = (Redis__Cluster__Fast) privdata;
    DEBUG_MSG("event: %d", event);
    if (event == HIRCLUSTER_EVENT_READY) {
        self->event_ready = 1;
    }
}

SV *Redis__Cluster__Fast_connect(pTHX_ Redis__Cluster__Fast self) {
    DEBUG_MSG("%s", "start connect");
    if (self->cluster_event_base && self->acc) {
        return newSVpvf("%s", "already connected");
    }

    self->pipeline_callback_remain = 0;
    self->pid = getpid();

    self->acc = redisClusterAsyncContextInit();
    if (redisClusterSetOptionAddNodes(self->acc->cc, self->hostnames) != REDIS_OK) {
        return newSVpvf("failed to add nodes: %s", self->acc->cc->errstr);
    }
    if (redisClusterSetOptionConnectTimeout(self->acc->cc, self->connect_timeout) != REDIS_OK) {
        return newSVpvf("failed to set connect timeout: %s", self->acc->cc->errstr);
    }
    if (redisClusterSetOptionTimeout(self->acc->cc, self->command_timeout) != REDIS_OK) {
        return newSVpvf("failed to set command timeout: %s", self->acc->cc->errstr);
    }
    if (redisClusterSetOptionMaxRetry(self->acc->cc, self->max_retry) != REDIS_OK) {
        return newSVpvf("%s", "failed to set max retry");
    }

    if (self->use_cluster_slots) {
        DEBUG_MSG("%s", "use cluster slots");
        if (redisClusterSetOptionRouteUseSlots(self->acc->cc) != REDIS_OK) {
            return newSVpvf("%s", "failed to set redisClusterSetOptionRouteUseSlots");
        }
    }

    self->cluster_event_base = event_base_new();
    if (redisClusterLibeventAttach(self->acc, self->cluster_event_base) != REDIS_OK) {
        return newSVpvf("%s", "failed to attach event base");
    }

    self->event_ready = 0;
    if (redisClusterSetEventCallback(self->acc->cc, eventCallback, self) != REDIS_OK) {
        return newSVpvf("%s", "failed to set event callback");
    }

    if (redisClusterAsyncConnect2(self->acc) != REDIS_OK) {
        return newSVpvf("failed to connect async: %s", self->acc->cc->errstr);
    }

    DEBUG_MSG("%s", "done connect");
    return NULL;
}

SV *Redis__Cluster__Fast_disconnect(pTHX_ Redis__Cluster__Fast self) {
    if (self->cluster_event_base == NULL && self->acc == NULL) {
        return NULL;
    }

    if (event_reinit(self->cluster_event_base) != 0) {
        return newSVpvf("%s", "event reinit failed");
    }
    redisClusterAsyncDisconnect(self->acc);

    if (event_base_dispatch(self->cluster_event_base) == -1) {
        return newSVpvf("%s", "event_base_dispatch failed after forking");
    }
    event_base_free(self->cluster_event_base);
    self->cluster_event_base = NULL;

    redisClusterAsyncFree(self->acc);
    self->acc = NULL;
    return NULL;
}

SV *Redis__Cluster__Fast_wait_until_event_ready(pTHX_ Redis__Cluster__Fast self) {
    int event_loop_error;
    int count = 0;
    int64_t timestamp_current, timeout_after;

    timestamp_current = get_usec_timestamp();
    if (timestamp_current < 0) {
        return newSVpvf("%s", "failed to get current timestamp");
    }
    timeout_after = timestamp_current + self->discovery_timeout_usec;

    DEBUG_MSG("%s", "start wait_until_event_ready");
    while (!self->event_ready) {
        DEBUG_EVENT_BASE();
        if (count >= MIN_ATTEMPT_TO_GET_RESULT) {
            timestamp_current = get_usec_timestamp();
            if (timestamp_current < 0) {
                return newSVpvf("%s", "failed to get current timestamp");
            }
            if (timestamp_current > timeout_after) {
                return newSVpvf("%s", "Timeout. The cluster discovery timeout reached.");
            }
        }

        event_loop_error = event_base_loop(self->cluster_event_base, EVLOOP_ONCE);
        if (event_loop_error == -1) {
            return newSVpvf("%s", "event_base_loop failed");
        }
        if (event_loop_error == 1) {
            return newSVpvf("%s", "Timeout. All of the given hostnames are unreachable.");
        };
        count++;
    }
    DEBUG_MSG("%s", "done wait_until_event_ready");
    return NULL;
}

cluster_node *get_node_by_random(pTHX_ Redis__Cluster__Fast self) {
    cluster_node *selected;
    cluster_node *candidate;
    int node_count;
    nodeIterator ni;

    initNodeIterator(&ni, self->acc->cc);

    /* Select a random node by reservoir sampling. */
    node_count = 1;
    if ((selected = nodeNext(&ni)) == NULL)
        return NULL;
    while ((candidate = nodeNext(&ni)) != NULL) {
        node_count++;
        if ((int) (Drand01() * node_count) == 0)
            selected = candidate;
    }
    return selected;
}

void run_cmd_impl(pTHX_ Redis__Cluster__Fast self, int argc, const char **argv, size_t *argvlen,
                  cmd_reply_context_t *reply_t) {
    int status, event_loop_error;
    DEBUG_MSG("start: %s", *argv);

    status = redisClusterAsyncCommandArgv(self->acc, replyCallback, reply_t, argc, argv, argvlen);
    if (status != REDIS_OK) {
        if (self->acc->err == REDIS_ERR_OTHER &&
            strcmp(self->acc->errstr, "No keys in command(must have keys for redis cluster mode)") == 0) {
            cluster_node *node;

            DEBUG_MSG("not cluster command, fallback to CommandToNode: err=%d errstr=%s",
                      self->acc->err,
                      self->acc->errstr);

            node = get_node_by_random(aTHX_ self);
            if (node == NULL) {
                reply_t->error = newSVpvf("%s", "No node found");
                return;
            }

            status = redisClusterAsyncCommandArgvToNode(self->acc, node, replyCallback, reply_t, argc, argv, argvlen);
            if (status != REDIS_OK) {
                DEBUG_MSG("error: err=%d errstr=%s", self->acc->err, self->acc->errstr);
                reply_t->error = newSVpvf("%s", self->acc->errstr);
                return;
            }
        } else {
            DEBUG_MSG("error: err=%d errstr=%s", self->acc->err, self->acc->errstr);
            reply_t->error = newSVpvf("%s", self->acc->errstr);
            return;
        }
    }

    while (!reply_t->done) {
        DEBUG_EVENT_BASE();
        event_loop_error = event_base_loop(self->cluster_event_base, EVLOOP_ONCE);
        if (event_loop_error != 0) {
            reply_t->error = newSVpvf("%s %d", "event_base_loop failed", event_loop_error);
            break;
        }
    }
}

void run_cmd_impl_pipeline(pTHX_ Redis__Cluster__Fast self, int argc, const char **argv, size_t *argvlen,
                  cmd_reply_context_t *reply_t, SV *cb) {
    int status;

    /* In pipeline mode, the callback are executed later, so it is necessary to create a dedicated reply context.
       This context is freed when the callback is executed. */
    cmd_reply_context_pipeline_t *reply_pipeline_t;
    Newx(reply_pipeline_t, sizeof(cmd_reply_context_pipeline_t), cmd_reply_context_pipeline_t);

    reply_pipeline_t->self = (void *) self;
    reply_pipeline_t->result = NULL;
    reply_pipeline_t->error = NULL;
    reply_pipeline_t->cb = SvREFCNT_inc(cb);

    DEBUG_MSG("start pipeline: %s", *argv);

    status = redisClusterAsyncCommandArgv(self->acc, replyCallbackPipeline, reply_pipeline_t, argc, argv, argvlen);
    if (status != REDIS_OK) {
        if (self->acc->err == REDIS_ERR_OTHER &&
            strcmp(self->acc->errstr, "No keys in command(must have keys for redis cluster mode)") == 0) {
            cluster_node *node;

            DEBUG_MSG("not cluster command, fallback to CommandToNode: err=%d errstr=%s",
                      self->acc->err,
                      self->acc->errstr);

            node = get_node_by_random(aTHX_ self);
            if (node == NULL) {
                reply_t->error = newSVpvf("%s", "No node found");
                return;
            }

            status = redisClusterAsyncCommandArgvToNode(self->acc, node, replyCallbackPipeline, reply_pipeline_t, argc, argv, argvlen);
            if (status != REDIS_OK) {
                DEBUG_MSG("error: err=%d errstr=%s", self->acc->err, self->acc->errstr);
                reply_t->error = newSVpvf("%s", self->acc->errstr);
                return;
            }
        } else {
            DEBUG_MSG("error: err=%d errstr=%s", self->acc->err, self->acc->errstr);
            reply_t->error = newSVpvf("%s", self->acc->errstr);
            return;
        }
    }

    self->pipeline_callback_remain++;
    DEBUG_MSG("pipeline callback remain: %ld", self->pipeline_callback_remain);
}

int Redis__Cluster__Fast_wait_one_response(pTHX_ Redis__Cluster__Fast self) {
    int event_loop_error;
    int64_t callback_remain_current = self->pipeline_callback_remain;
    if (callback_remain_current <= 0) {
        return 0;
    }
    while (self->pipeline_callback_remain == callback_remain_current) {
        DEBUG_EVENT_BASE();
        event_loop_error = event_base_loop(self->cluster_event_base, EVLOOP_ONCE);
        if (event_loop_error != 0) {
            return -1;
        }
    }
    return 1;
}

int Redis__Cluster__Fast_wait_all_responses(pTHX_ Redis__Cluster__Fast self) {
    int event_loop_error;
    if (self->pipeline_callback_remain <= 0) {
        return 0;
    }
    while (self->pipeline_callback_remain > 0) {
        DEBUG_EVENT_BASE();
        event_loop_error = event_base_loop(self->cluster_event_base, EVLOOP_ONCE);
        if (event_loop_error != 0) {
            return -1;
        }
    }
    return 1;
}

void Redis__Cluster__Fast_run_cmd(pTHX_ Redis__Cluster__Fast self, int argc, const char **argv, size_t *argvlen,
                                  cmd_reply_context_t *reply_t, SV *cb) {
    reply_t->self = (void *) self;
    reply_t->result = NULL;
    reply_t->error = NULL;
    reply_t->done = 0;

    if (self->pid != getpid()) {
        DEBUG_MSG("%s", "pid changed");
        reply_t->error = Redis__Cluster__Fast_disconnect(aTHX_ self);
        if (reply_t->error) {
            return;
        }

        reply_t->error = Redis__Cluster__Fast_connect(aTHX_ self);
        if (reply_t->error) {
            return;
        }

        reply_t->error = Redis__Cluster__Fast_wait_until_event_ready(aTHX_ self);
        if (reply_t->error) {
            return;
        }
    }

    if (cb) {
        run_cmd_impl_pipeline(aTHX_ self, argc, argv, argvlen, reply_t, cb);
    } else {
        run_cmd_impl(aTHX_ self, argc, argv, argvlen, reply_t);
    }
}

MODULE = Redis::Cluster::Fast    PACKAGE = Redis::Cluster::Fast

PROTOTYPES: DISABLE

Redis::Cluster::Fast
_new(char* cls);
PREINIT:
    redis_cluster_fast_t* self;
CODE:
    Newxz(self, sizeof(redis_cluster_fast_t), redis_cluster_fast_t);
    RETVAL = self;
OUTPUT:
    RETVAL

void
__srandom(char *cls, unsigned int seed_value)
CODE:
    srandom(seed_value);

int
__set_debug(Redis::Cluster::Fast self, int val)
CODE:
    DEBUG_MSG("%s", "DEBUG true");
    RETVAL = self->debug = val;
OUTPUT:
    RETVAL

void
__set_servers(Redis::Cluster::Fast self, char* hostnames)
CODE:
    if (self->hostnames) {
        Safefree(self->hostnames);
        self->hostnames = NULL;
    }

    if (hostnames) {
        Newx(self->hostnames, strlen(hostnames) + 1, char);
        my_strlcpy(self->hostnames, hostnames, strlen(hostnames) + 1);
        DEBUG_MSG("%s %s", "set hostnames", self->hostnames);
    }

void
__set_connect_timeout(Redis::Cluster::Fast self, double double_sec)
PREINIT:
    int second, micro_second;
    struct timeval timeout;
CODE:
    second = (int) (double_sec);
    micro_second = (int) (fmod(double_sec * ONE_SECOND_TO_MICRO, ONE_SECOND_TO_MICRO) + 0.999);
    timeout.tv_sec = second;
    timeout.tv_usec = micro_second;
    self->connect_timeout = timeout;
    DEBUG_MSG("connect timeout %d, %d", second, micro_second);

void
__set_command_timeout(Redis::Cluster::Fast self, double double_sec)
PREINIT:
    int second, micro_second;
    struct timeval timeout;
CODE:
    second = (int) (double_sec);
    micro_second = (int) (fmod(double_sec * ONE_SECOND_TO_MICRO, ONE_SECOND_TO_MICRO) + 0.999);
    timeout.tv_sec = second;
    timeout.tv_usec = micro_second;
    self->command_timeout = timeout;
    DEBUG_MSG("command timeout %d, %d", second, micro_second);

void
__set_max_retry(Redis::Cluster::Fast self, int max_retry)
CODE:
    self->max_retry = max_retry;
    DEBUG_MSG("max_retry %d", max_retry);

void
__set_route_use_slots(Redis::Cluster::Fast self, int use_slot)
CODE:
    self->use_cluster_slots = use_slot;

void
__set_cluster_discovery_retry_timeout(Redis::Cluster::Fast self, double double_sec)
CODE:
    self->discovery_timeout_usec = (int64_t) (double_sec * ONE_SECOND_TO_MICRO);
    DEBUG_MSG("discovery timeout %ld", self->discovery_timeout_usec);

SV*
__connect(Redis::Cluster::Fast self)
CODE:
    RETVAL = Redis__Cluster__Fast_connect(aTHX_ self);
    if (RETVAL == NULL) {
        RETVAL = &PL_sv_undef;
    }
OUTPUT:
    RETVAL

SV*
__disconnect(Redis::Cluster::Fast self)
CODE:
    RETVAL = Redis__Cluster__Fast_disconnect(aTHX_ self);
    if (RETVAL == NULL) {
        RETVAL = &PL_sv_undef;
    }
OUTPUT:
    RETVAL

SV*
__wait_until_event_ready(Redis::Cluster::Fast self)
CODE:
    RETVAL = Redis__Cluster__Fast_wait_until_event_ready(aTHX_ self);
    if (RETVAL == NULL) {
        RETVAL = &PL_sv_undef;
    }
OUTPUT:
    RETVAL

void
__std_cmd(Redis::Cluster::Fast self, ...)
PREINIT:
    cmd_reply_context_t* result_context;
    char** argv;
    size_t* argvlen;
    STRLEN len;
    int argc, i;
    SV* cb;
PPCODE:
    if (!self->acc) {
       croak("Not connected to any server");
    }

    cb = ST(items - 1);
    if (SvROK(cb) && SvTYPE(SvRV(cb)) == SVt_PVCV) {
        argc = items - 2;
    } else {
        cb = NULL;
        argc = items - 1;
    }

    Newx(argv, sizeof(char*) * argc, char*);
    Newx(argvlen, sizeof(size_t) * argc, size_t);
    Newx(result_context, sizeof(cmd_reply_context_t), cmd_reply_context_t);

    for (i = 0; i < argc; i++) {
        argv[i] = SvPV(ST(i + 1), len);
        argvlen[i] = len;
    }

    Redis__Cluster__Fast_run_cmd(aTHX_ self, argc, (const char **) argv, argvlen, result_context, cb);

    ST(0) = result_context->result ?
            sv_2mortal(result_context->result) : &PL_sv_undef;
    ST(1) = result_context->error ?
            sv_2mortal(result_context->error) : &PL_sv_undef;

    Safefree(argv);
    Safefree(argvlen);
    Safefree(result_context);

    XSRETURN(2);

int
__wait_one_response(Redis::Cluster::Fast self)
CODE:
    RETVAL = Redis__Cluster__Fast_wait_one_response(aTHX_ self);
OUTPUT:
    RETVAL

int
__wait_all_responses(Redis::Cluster::Fast self)
CODE:
    RETVAL = Redis__Cluster__Fast_wait_all_responses(aTHX_ self);
OUTPUT:
    RETVAL

void
DESTROY(Redis::Cluster::Fast self)
CODE:
    if (self->cluster_event_base) {
        DEBUG_MSG("%s", "trying to free event_base");
        if ((self->pid == getpid()) || (event_reinit(self->cluster_event_base) == 0)){
            redisClusterAsyncDisconnect(self->acc);
            if (event_base_dispatch(self->cluster_event_base) == -1) {
                warn("event_base_dispatch failed.");
            }
            event_base_free(self->cluster_event_base);
            self->cluster_event_base = NULL;
        } else {
           warn("event_reinit failed. Skip disconnecting and freeing event_base on destruction");
        }
    }

    redisClusterAsyncFree(self->acc);
    self->acc = NULL;

    if (self->hostnames) {
        DEBUG_MSG("%s", "free hostnames");
        Safefree(self->hostnames);
        self->hostnames = NULL;
    }

    DEBUG_MSG("%s", "done");
    Safefree(self);
