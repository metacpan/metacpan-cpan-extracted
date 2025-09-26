/*
 * Copyright (c) 2010-2011, Pieter Noordhuis <pcnoordhuis at gmail dot com>
 *
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 *   * Redistributions of source code must retain the above copyright notice,
 *     this list of conditions and the following disclaimer.
 *   * Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in the
 *     documentation and/or other materials provided with the distribution.
 *   * Neither the name of Redis nor the names of its contributors may be used
 *     to endorse or promote products derived from this software without
 *     specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */

#ifndef __HIREDIS_LIBEVENT_H__
#define __HIREDIS_LIBEVENT_H__
#include <event2/event.h>
#include "hiredis/hiredis.h"
#include "hiredis/async.h"

#define REDIS_LIBEVENT_DELETED 0x01
#define REDIS_LIBEVENT_ENTERED 0x02

typedef struct redisLibeventEvents {
    redisAsyncContext *context;
    struct event *ev_io;
    struct event *ev_timer;
    struct event_base *base;
    short flags;
    short state;
} redisLibeventEvents;

static void redisLibeventDestroy(redisLibeventEvents *e) {
    hi_free(e);
}

static void redisLibeventHandler(evutil_socket_t fd, short event, void *arg) {
    redisLibeventEvents *e = (redisLibeventEvents*)arg;
    ((void)fd);
    e->state |= REDIS_LIBEVENT_ENTERED;

    #define CHECK_DELETED() if (e->state & REDIS_LIBEVENT_DELETED) {\
        redisLibeventDestroy(e);\
        return; \
    }

    if ((event & EV_READ) && e->context && (e->state & REDIS_LIBEVENT_DELETED) == 0) {
        redisAsyncHandleRead(e->context);
        CHECK_DELETED();
    }

    if ((event & EV_WRITE) && e->context && (e->state & REDIS_LIBEVENT_DELETED) == 0) {
        redisAsyncHandleWrite(e->context);
        CHECK_DELETED();
    }

    e->state &= ~REDIS_LIBEVENT_ENTERED;
    #undef CHECK_DELETED
}

static void redisLibeventTimerHandler(evutil_socket_t fd, short event, void *arg) {
    redisLibeventEvents *e = (redisLibeventEvents*)arg;
    ((void)fd);
    ((void)event);
    e->state |= REDIS_LIBEVENT_ENTERED;

    #define CHECK_DELETED() if (e->state & REDIS_LIBEVENT_DELETED) {\
        redisLibeventDestroy(e);\
        return; \
    }

    if (e->context && (e->state & REDIS_LIBEVENT_DELETED) == 0) {
        redisAsyncHandleTimeout(e->context);
        CHECK_DELETED();
    }

    e->state &= ~REDIS_LIBEVENT_ENTERED;
    #undef CHECK_DELETED
}

static void redisLibeventUpdate(void *privdata, short flag, int isRemove) {
    redisLibeventEvents *e = (redisLibeventEvents *)privdata;

    if (isRemove) {
        if ((e->flags & flag) == 0) {
            return;
        } else {
            e->flags &= ~flag;
        }
    } else {
        if (e->flags & flag) {
            return;
        } else {
            e->flags |= flag;
        }
    }

    event_del(e->ev_io);
    event_assign(e->ev_io, e->base, e->context->c.fd, e->flags | EV_PERSIST,
                 redisLibeventHandler, privdata);
    event_priority_set(e->ev_io, 0);
    event_add(e->ev_io, NULL);
}

static void redisLibeventAddRead(void *privdata) {
    redisLibeventUpdate(privdata, EV_READ, 0);
}

static void redisLibeventDelRead(void *privdata) {
    redisLibeventUpdate(privdata, EV_READ, 1);
}

static void redisLibeventAddWrite(void *privdata) {
    redisLibeventUpdate(privdata, EV_WRITE, 0);
}

static void redisLibeventDelWrite(void *privdata) {
    redisLibeventUpdate(privdata, EV_WRITE, 1);
}

static void redisLibeventCleanup(void *privdata) {
    redisLibeventEvents *e = (redisLibeventEvents*)privdata;
    if (!e) {
        return;
    }
    if (e->ev_io) {
        event_del(e->ev_io);
        event_free(e->ev_io);
        e->ev_io = NULL;
    }
    if (e->ev_timer) {
        evtimer_del(e->ev_timer);
        event_free(e->ev_timer);
        e->ev_timer = NULL;
    }

    if (e->state & REDIS_LIBEVENT_ENTERED) {
        e->state |= REDIS_LIBEVENT_DELETED;
    } else {
        redisLibeventDestroy(e);
    }
}

static void redisLibeventSetTimeout(void *privdata, struct timeval tv) {
    redisLibeventEvents *e = (redisLibeventEvents *)privdata;
    evtimer_del(e->ev_timer);
    evtimer_add(e->ev_timer, &tv);
}

static int redisLibeventAttach(redisAsyncContext *ac, struct event_base *base) {
    redisContext *c = &(ac->c);
    redisLibeventEvents *e;

    /* Nothing should be attached when something is already attached */
    if (ac->ev.data != NULL)
        return REDIS_ERR;

    /* Create container for context and r/w events */
    e = (redisLibeventEvents*)hi_calloc(1, sizeof(*e));
    if (e == NULL)
        return REDIS_ERR;

    e->context = ac;

    /* Register functions to start/stop listening for events */
    ac->ev.addRead = redisLibeventAddRead;
    ac->ev.delRead = redisLibeventDelRead;
    ac->ev.addWrite = redisLibeventAddWrite;
    ac->ev.delWrite = redisLibeventDelWrite;
    ac->ev.cleanup = redisLibeventCleanup;
    ac->ev.scheduleTimer = redisLibeventSetTimeout;
    ac->ev.data = e;

    /* Initialize and install read/write events */
    e->ev_io = event_new(base, c->fd, EV_READ | EV_WRITE, redisLibeventHandler, e);
    event_priority_set(e->ev_io, 0);

    /* Initialize and install timer events */
    e->ev_timer = evtimer_new(base, redisLibeventTimerHandler, e);
    event_priority_set(e->ev_timer, 1);

    e->base = base;
    return REDIS_OK;
}
#endif

#ifndef __HIREDIS_CLUSTER_LIBEVENT_H__
#define __HIREDIS_CLUSTER_LIBEVENT_H__
#include "hiredis_cluster/hircluster.h"

static int redisLibeventAttach_link(redisAsyncContext *ac, void *base) {
    return redisLibeventAttach(ac, (struct event_base *)base);
}

static int redisClusterLibeventAttach(redisClusterAsyncContext *acc,
                                      struct event_base *base) {

    if (acc == NULL || base == NULL) {
        return REDIS_ERR;
    }

    acc->adapter = base;
    acc->attach_fn = redisLibeventAttach_link;

    return REDIS_OK;
}

#endif
