/*
** Perl 5 interface to tcp_wrappers libwrap.a library routines.
**
** Copyright (c) 2002, George A. Theall.
** All rights reserved.
**
** This program is free software; you can redistribute it and/or modify
** it under the same terms as Perl itself.
*/

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <tcpd.h>
#include <syslog.h>
#include <sys/socket.h>
/*
** nb: libwrap.a requires these be defined even though
**     they don't appear to be used.
*/
int allow_severity = LOG_INFO;
int deny_severity = LOG_WARNING;

typedef struct request_info Request_info;

#include "const-c.inc"

#if 0
#   define TRACE                warn
void
#ifdef CAN_PROTOTYPE
TRACE_Request(Request_info *request)
#else
TRACE_Request(request)
Request_info *request;
#endif  /* CAN_PROTOTYPE */
{
    TRACE("trace:   tracing request structure %p:\n", request);
    /* 
    SV *uv = (UV) request;
    TRACE("debug: tracing iv\n");
    sv_dump(uv);
    SV *ptr = sv_setref_pv(sv_newmortal(), Nullch, request);
    TRACE("debug: tracing ptr\n");
    sv_dump(ptr); */
    if (request->fd != -1)                      /* nb: initial value */
        TRACE("trace:     file descriptor: %i\n", request->fd);
    if (strlen(request->user))
        TRACE("trace:     user:            %s\n", eval_user(request));
    if (strcmp(request->daemon, STRING_UNKNOWN))    /* nb: initial value */
        TRACE("trace:     daemon:          %s\n", eval_daemon(request));
    if (strlen(request->pid))
        TRACE("trace:     pid:             %s\n", eval_pid(request));
    if (strlen(request->client[0].name)) {
        TRACE("trace:     client host:     %s\n", eval_hostname(&request->client[0]));
    }
    if (strlen(request->client[0].addr))
        TRACE("trace:     client addr:     %s\n", eval_hostaddr(&request->client[0]));
    if (request->client[0].sin) {
        unsigned short int port = ntohs(request->client[0].sin->sin_port);
        char *host = inet_ntoa(request->client[0].sin->sin_addr);
        TRACE("trace:     client port:     %i\n", port);
        TRACE("trace:     client address:  %s\n", host);
    }
    if (strlen(request->server[0].name))
        TRACE("trace:     server host:     %s\n", eval_hostname(&request->server[0]));
    if (strlen(request->server[0].addr))
        TRACE("trace:     server addr:     %s\n", eval_hostaddr(&request->server[0]));
    if (request->server[0].sin) {
        unsigned short int port = ntohs(request->server[0].sin->sin_port);
        char *host = inet_ntoa(request->server[0].sin->sin_addr);
        TRACE("trace:     server port:     %i\n", port);
        TRACE("trace:     server address:  %s\n", host);
    }
}
#else
#   define TRACE
#   define TRACE_Request(request)
#endif

Request_info *
#ifdef CAN_PROTOTYPE
request_update(Request_info *request, SV *sv_key, SV *sv_val)
#else
request_update(request, sv_key, sv_val)
Request_info *request;
SV *sv_key;
SV *sv_val;
#endif  /* CAN_PROTOTYPE */
{
    TRACE("trace: tracing request_update().\n");
    TRACE("trace:   updating request structure %p.\n", request);
    /* SvTYPE() returns an integer as enumerated in sv.h. */
    TRACE("trace:   key is of type %d; value %d.\n", SvTYPE(sv_key), SvTYPE(sv_val));
    if (!SvIOKp(sv_key)) {
        TRACE("trace: leaving request_update() on failure.\n");
        return NULL;
    }
    int key = SvIV(sv_key);
    switch (key) {
        case RQ_FILE:
            if (!SvIOKp(sv_val)) {
                    TRACE("trace: leaving request_update() on failure.\n");
                return NULL;
            }
            int val_int = SvIV(sv_val);
            TRACE("trace:   updating request with %i / %i.\n", key, val_int);
            request_set(request, key, val_int, 0);  /* can't fail */
            break;
        case RQ_CLIENT_SIN:
        case RQ_SERVER_SIN:
            /*
            ** nb: drop through - Perl / Socket handle a sockaddr_in
            ** structure as just another pointer.
            */
        case RQ_DAEMON:
        case RQ_CLIENT_NAME:
        case RQ_CLIENT_ADDR:
        case RQ_SERVER_NAME:
        case RQ_SERVER_ADDR:
        case RQ_USER:
            if (!SvPOKp(sv_val)) {
                TRACE("trace: leaving request_update() on failure.\n");
                return NULL;
            }
            STRLEN l;
            char *val_str = SvPV(sv_val, l);
            TRACE("trace:   updating request with %i / %s.\n", key, val_str);
            request_set(request, key, val_str, 0);
            break;
        default:
            TRACE("trace: leaving request_update() on failure.\n");
            return NULL;
    }
    TRACE("trace: leaving request_update().\n");
    return request;
}



MODULE = Net::TCPwrappers	PACKAGE = Net::TCPwrappers

INCLUDE: const-xs.inc

PROTOTYPES: ENABLE

Request_info *
request_init(...)
    INIT:
        /* Make sure number of arguments is even. */
        if (items % 2 != 0) {
            errno = EINVAL;
            XSRETURN_UNDEF;
        }
    CODE:
        int i;
        errno = 0;
        TRACE("trace: tracing request_init().\n");
        TRACE("trace:   creating new request structure.\n");
        /* nb: 1st param to New() is arbitrary integer used to identify leaks. */
        New(1022, RETVAL, 1, Request_info);
        if (!RETVAL) {
            errno = ENOMEM;
            XSRETURN_UNDEF;
        }
        TRACE("trace:   initializing request structure %p.\n", RETVAL);
        request_init(RETVAL, 0);
        for (i = 1; i <= items; i+=2) {
            if (!request_update(RETVAL, ST(i-1), ST(i))) {
                TRACE("trace:   destroying request structure %p.\n", RETVAL);
                Safefree(RETVAL);
                TRACE("trace: leaving request_init() on failure.\n");
                errno = EINVAL;
                XSRETURN_UNDEF;
            }
        }
        TRACE_Request(RETVAL);
        TRACE("trace: leaving request_init().\n");
OUTPUT:
        RETVAL

Request_info *
request_set(request, ...)
        Request_info *request
    INIT:
        /* Make sure number of arguments is odd. */
        if (items % 2 == 0) {
            errno = EINVAL;
            XSRETURN_UNDEF;
        }
    CODE:
        int i;
        errno = 0;
        TRACE("trace: tracing request_set().\n");
        TRACE("trace:   creating request structure.\n");
        /* 
        ** nb: we need to copy the request structure to avoid
        **     problems when Perl does garbage collection on 
        **     the request structure passed in.
        **
        ** nb: 1st param to New() is arbitrary integer used to identify leaks.
        */
        New(1023, RETVAL, 1, Request_info);
        if (!RETVAL) {
            errno = ENOMEM;
            XSRETURN_UNDEF;
        }
        TRACE("trace:   copying request structure %p to %p.\n", request, RETVAL);
        Copy(request, RETVAL, 1, Request_info);
        for (i = 2; i <= items; i+=2) {
            if (!request_update(RETVAL, ST(i-1), ST(i))) {
                TRACE("trace: leaving request_set() on failure.\n");
                errno = EINVAL;
                XSRETURN_UNDEF;
            }
        }
        TRACE_Request(RETVAL);
        TRACE("trace: leaving request_set().\n");
OUTPUT:
        RETVAL

void
fromhost(request)
        Request_info *request
    CODE:
        TRACE("trace: tracing fromhost().\n");
        fromhost(request);
        TRACE_Request(request);
        TRACE("trace: leaving fromhost().\n");

int
hosts_access(request)
        Request_info *request
    CODE:
        TRACE("trace: tracing hosts_access().\n");
        RETVAL = hosts_access(request);
        TRACE("trace: leaving hosts_access().\n");
    OUTPUT:
        RETVAL


int
hosts_ctl(daemon, client_name, client_addr, client_user=STRING_UNKNOWN)
        char *daemon
        char *client_name
        char *client_addr
        char *client_user
    CODE:
        TRACE("trace: tracing hosts_ctl().\n");
        RETVAL = hosts_ctl(daemon, client_name, client_addr, client_user);
        TRACE("trace: leaving hosts_ctl().\n");
    OUTPUT:
        RETVAL


# nb: package name Request_infoPtr must match class name into
#     which request structure was originally blessed.
#	PREFIX=wrap_
MODULE = Net::TCPwrappers	PACKAGE = Request_infoPtr

void
DESTROY(request)
        Request_info *  request
    CODE:
        TRACE("trace: tracing DESTROY().\n");
        TRACE_Request(request);
        TRACE("trace:   destroying request structure %p.\n", request);
        Safefree(request);
        TRACE("trace: leaving DESTROY().\n");
