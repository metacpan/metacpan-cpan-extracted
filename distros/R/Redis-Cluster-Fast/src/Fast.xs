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
#include "hiredis_cluster/adapters/libevent.h"
#include "hiredis_cluster/hircluster.h"

#ifdef __cplusplus
} /* extern "C" */
#endif

#define NEED_newSVpvn_flags
#include "ppport.h"

#define MAX_ERROR_SIZE 256
#define ONE_SECOND_TO_MICRO 1000000

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

#define DEBUG_MSG_FORCE(fmt, ...) \
    fprintf(stderr, "[%d][%d][%s:%d:%s]: ", getpid(), getppid(), __FILE__, __LINE__, __func__);  \
    fprintf(stderr, fmt, __VA_ARGS__);                              \
    fprintf(stderr, "\n");

typedef struct redis_cluster_fast_reply_s {
    SV *result;
    SV *error;
} redis_cluster_fast_reply_t;

typedef struct cmd_reply_context_s {
    void* self;
    redis_cluster_fast_reply_t ret;
    char *error;
    int done;
} cmd_reply_context_t;

typedef struct event_base_foreach_context_s {
    void *self;
    short target_event_flag;
    bool matched;
} event_base_foreach_context_t;

typedef struct redis_cluster_fast_s {
    redisClusterAsyncContext* acc;
    struct event_base* cluster_event_base;
    char* hostnames;
    int debug;
    int max_retry;
    struct timeval connect_timeout;
    struct timeval command_timeout;
    pid_t pid;
} redis_cluster_fast_t, *Redis__Cluster__Fast;

static redis_cluster_fast_reply_t
Redis__Cluster__Fast_decode_reply(Redis__Cluster__Fast self, redisReply *reply) {
    redis_cluster_fast_reply_t res = {NULL, NULL};
    dTHX;

    switch (reply->type) {
        case REDIS_REPLY_ERROR:
            res.error = sv_2mortal(newSVpvn(reply->str, reply->len));
            break;

        case REDIS_REPLY_BIGNUM:
        case REDIS_REPLY_DOUBLE:
        case REDIS_REPLY_STATUS:
        case REDIS_REPLY_STRING:
        case REDIS_REPLY_VERB: // TODO: parse vtype (e.g. `txt`, `md`)
            res.result = sv_2mortal(newSVpvn(reply->str, reply->len));
            break;

        case REDIS_REPLY_INTEGER:
        case REDIS_REPLY_BOOL:
            res.result = sv_2mortal(newSViv(reply->integer));
            break;
        case REDIS_REPLY_NIL:
            res.result = &PL_sv_undef;
            break;

        case REDIS_REPLY_MAP:
        case REDIS_REPLY_SET:
        case REDIS_REPLY_ATTR: {
            HV *hv = newHV();
            size_t i;
            res.result = sv_2mortal(newRV_noinc((SV *) hv));

            char *key;
            for (i = 0; i < reply->elements; i++) {
                if (i % 2 == 0) {
                    key = reply->element[i]->str;
                } else {
                    redis_cluster_fast_reply_t elem = {NULL, NULL};
                    elem = Redis__Cluster__Fast_decode_reply(self, reply->element[i]);
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

        case REDIS_REPLY_PUSH: // TODO: push handler
        case REDIS_REPLY_ARRAY: {
            AV *av = newAV();
            size_t i;
            res.result = sv_2mortal(newRV_noinc((SV *) av));

            for (i = 0; i < reply->elements; i++) {
                redis_cluster_fast_reply_t elem = {NULL, NULL};
                elem = Redis__Cluster__Fast_decode_reply(self, reply->element[i]);
                if (elem.result) {
                    av_push(av, SvREFCNT_inc(elem.result));
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
    cmd_reply_context_t *reply_t;
    reply_t = (cmd_reply_context_t *) privdata;
    Redis__Cluster__Fast self = (Redis__Cluster__Fast)reply_t->self;
    DEBUG_MSG("replycb %s", "start");

    redisReply *reply = (redisReply *) r;
    if (reply) {
        reply_t->ret = Redis__Cluster__Fast_decode_reply(self, reply);
    } else {
        char *error = (char*)malloc(MAX_ERROR_SIZE);
        sprintf(error, "%s", cc->errstr);
        reply_t->error = error;
    }

    reply_t->done = 1;
    event_base_loopbreak(self->cluster_event_base);
}

/*
int eventbaseCallback(const struct event_base *base, const struct event *event, void *privdata) {
    event_base_foreach_context_t *event_info;
    event_info = (event_base_foreach_context_t *) privdata;
    Redis__Cluster__Fast self = (Redis__Cluster__Fast) event_info->self;

    int matched = event_get_events(event) & event_info->target_event_flag;
    if (matched) {
        event_info->matched = true;
        DEBUG_MSG("%s %d", "given flag found", event_info->target_event_flag);
        return 1;
    }
    return 0;
}

void wait_for_event_with_flag(Redis__Cluster__Fast self, short target_event_flag) {
    DEBUG_EVENT_BASE();
    event_base_foreach_context_t *event_info =
            (event_base_foreach_context_t *) malloc(sizeof(event_base_foreach_context_t));
    event_info->self = (void *) self;
    event_info->target_event_flag = target_event_flag;
    event_base_foreach_event(self->cluster_event_base, eventbaseCallback, event_info);
    if (event_info->matched) {
        int status = event_base_loop(self->cluster_event_base, EVLOOP_ONCE | EVLOOP_NO_EXIT_ON_EMPTY);
        DEBUG_MSG("event loop done. status %d", status);
        DEBUG_EVENT_BASE();
    } else {
        return;
    }
};
*/

void wait_for_event(Redis__Cluster__Fast self) {
    DEBUG_EVENT_BASE();
    int status = event_base_dispatch(self->cluster_event_base);
    DEBUG_MSG("event loop done. status %d", status);
    DEBUG_EVENT_BASE();
}

int Redis__Cluster__Fast_connect(Redis__Cluster__Fast self){
    DEBUG_MSG("%s", "start connect");

    self->pid = getpid();

    self->acc = redisClusterAsyncContextInit();
    redisClusterSetOptionAddNodes(self->acc->cc, self->hostnames);
    redisClusterSetOptionConnectTimeout(self->acc->cc, self->connect_timeout);
    redisClusterSetOptionTimeout(self->acc->cc, self->command_timeout);
    redisClusterSetOptionMaxRetry(self->acc->cc, self->max_retry);

    if (redisClusterConnect2(self->acc->cc) != REDIS_OK) {
        DEBUG_MSG("connect error %s", self->acc->cc->errstr);
        return 1;
    }

    struct event_config *cfg;
    cfg = event_config_new();
    event_config_set_flag(cfg, EVENT_BASE_FLAG_EPOLL_USE_CHANGELIST);
    self->cluster_event_base = event_base_new_with_config(cfg);
    redisClusterLibeventAttach(self->acc, self->cluster_event_base);

    DEBUG_MSG("%s", "done connect");
    return 0;
}

cluster_node *get_node_by_random(Redis__Cluster__Fast self) {
    uint32_t slot_num = rand() % REDIS_CLUSTER_SLOTS;
    return self->acc->cc->table[slot_num];
}

void Redis__Cluster__Fast_run_cmd(Redis__Cluster__Fast self, int argc, const char **argv, size_t *argvlen,
                                  cmd_reply_context_t *reply_t) {
    DEBUG_MSG("start: %s", *argv);
    reply_t->done = 0;
    reply_t->self = (void *) self;

    if (self->pid != getpid()) {
        DEBUG_MSG("%s", "pid changed");
        event_base_free(self->cluster_event_base);
        redisClusterAsyncFree(self->acc);
        if (Redis__Cluster__Fast_connect(self)) {
            DEBUG_MSG("%s", "failed fork");
            reply_t->error = "failed to fork";
            return;
        }
    }

    char *cmd;
    long long int len;
    len = redisFormatCommandArgv(&cmd, argc, argv, argvlen);
    if (len == -1) {
        DEBUG_MSG("error: err=%s", "memory error");
        reply_t->error = "memory allocation error";
        return;
    }

    int status = redisClusterAsyncFormattedCommand(self->acc, replyCallback, reply_t, cmd, (int) len);
    if (status != REDIS_OK) {
        if (self->acc->err == REDIS_ERR_OTHER &&
            strcmp(self->acc->errstr, "No keys in command(must have keys for redis cluster mode)") == 0) {
            DEBUG_MSG("not cluster command, fallback to CommandToNode: err=%d errstr=%s",
                      self->acc->err,
                      self->acc->errstr);

            cluster_node *node;
            node = get_node_by_random(self);

            status = redisClusterAsyncFormattedCommandToNode(self->acc, node, replyCallback, reply_t, cmd, (int) len);
            if (status != REDIS_OK) {
                DEBUG_MSG("error: err=%d errstr=%s", self->acc->err, self->acc->errstr);
                reply_t->error = strtok(self->acc->errstr, "");
                return;
            } else {
                reply_t->error = NULL;
            }
        } else {
            reply_t->error = strtok(self->acc->errstr, "");
            return;
        }
    } else {
        reply_t->error = NULL;
    }

/* TODO: support coderef arg to run a command in the background
    // handle write only
    wait_for_event_with_flag(self, EV_WRITE);
*/

    while (1) {
        wait_for_event(self);
        if (reply_t->done) {
            break;
        }
    }
}

MODULE = Redis::Cluster::Fast    PACKAGE = Redis::Cluster::Fast

PROTOTYPES: DISABLE

SV*
_new(char* cls);
PREINIT:
redis_cluster_fast_t* self;
CODE:
{
    srand((unsigned int) time(NULL));

    Newxz(self, sizeof(redis_cluster_fast_t), redis_cluster_fast_t);
    DEBUG_MSG("%s", "start new");
    ST(0) = sv_newmortal();
    sv_setref_pv(ST(0), cls, (void*)self);
    DEBUG_MSG("return %p", ST(0));
    XSRETURN(1);
}
OUTPUT:
    RETVAL

int
__set_debug(Redis::Cluster::Fast self, int val)
CODE:
{
    DEBUG_MSG("%s", "DEBUG true");
    RETVAL = self->debug = val;
}
OUTPUT:
    RETVAL

void
__set_servers(Redis::Cluster::Fast self, char* hostnames)
CODE:
{
    if (self->hostnames) {
        free(self->hostnames);
        self->hostnames = NULL;
    }

    if(hostnames) {
        self->hostnames = (char *) malloc(strlen(hostnames) + 1);
        strcpy(self->hostnames, hostnames);
        DEBUG_MSG("%s %s", "set hostnames", self->hostnames);
    }
}

void
__set_connect_timeout(Redis::Cluster::Fast self, double double_sec)
CODE:
{
    int second = (int) (double_sec);
    int micro_second = (int) (fmod(double_sec * ONE_SECOND_TO_MICRO, ONE_SECOND_TO_MICRO) + 0.999);
    struct timeval timeout = { second, micro_second };
    self->connect_timeout = timeout;
    DEBUG_MSG("connect timeout %d, %d", second, micro_second);
}

void
__set_command_timeout(Redis::Cluster::Fast self, double double_sec)
CODE:
{
    int second = (int) (double_sec);
    int micro_second = (int) (fmod(double_sec * ONE_SECOND_TO_MICRO, ONE_SECOND_TO_MICRO) + 0.999);
    struct timeval timeout = { second, micro_second };
    self->command_timeout = timeout;
    DEBUG_MSG("command timeout %d, %d", second, micro_second);
}

void
__set_max_retry(Redis::Cluster::Fast self, int max_retry)
CODE:
{
    self->max_retry = max_retry;
    DEBUG_MSG("max_retry %d", max_retry);
}

int
connect(Redis::Cluster::Fast self)
CODE:
{
    RETVAL = Redis__Cluster__Fast_connect(self);
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
CODE:
{
    if(!self->acc) {
       croak("Not connected to any server");
    }

    argc = items - 1;
    Newx(argv, sizeof(char*) * argc, char*);
    Newx(argvlen, sizeof(size_t) * argc, size_t);
    Newx(result_context, sizeof(cmd_reply_context_t), cmd_reply_context_t);

    for (i = 0; i < argc; i++) {
        if(!sv_utf8_downgrade(ST(i + 1), 1)) {
            croak("command sent is not an octet sequence in the native encoding (Latin-1). Consider using debug mode to see the command itself.");
        }
        argv[i] = SvPV(ST(i + 1), len);
        argvlen[i] = len;
    }

    DEBUG_MSG("raw_cmd : %s", *argv);

    Redis__Cluster__Fast_run_cmd(self, argc, (const char **) argv, argvlen, result_context);

    Safefree(argv);

    if (result_context->error) {
        ST(0) = &PL_sv_undef;
        ST(1) = sv_2mortal(newSVpvn(result_context->error, strlen(result_context->error)));
    } else {
        ST(0) = result_context->ret.result ?
                result_context->ret.result : &PL_sv_undef;
        ST(1) = result_context->ret.error ?
                result_context->ret.error : &PL_sv_undef ;
    }

    XSRETURN(2);
}

void
DESTROY(Redis::Cluster::Fast self)
CODE:
{
    redisClusterAsyncFree(self->acc);

    if (self->cluster_event_base) {
        DEBUG_MSG("%s", "free event_base");
        event_base_free(self->cluster_event_base);
    }

    if (self->hostnames) {
        DEBUG_MSG("%s", "free hostnames");
        free(self->hostnames);
        self->hostnames = NULL;
    }

    Safefree(self);
    DEBUG_MSG("%s", "done");
}
