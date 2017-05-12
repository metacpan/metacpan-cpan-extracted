/*
**
** Copyright (C) 2009 by Carnegie Mellon University
**
** This program is free software; you can redistribute it and/or modify
** it under the terms of the GNU General Public License, as published by
** the Free Software Foundation, under the terms pursuant to Version 2,
** June 1991.
**
** This program is distributed in the hope that it will be useful, but
** WITHOUT ANY WARRANTY; without even the implied warranty of
** MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General
** Public License for more details.
**
*/

#ifdef __cplusplus
extern "C" {
#endif

#ifdef _CYGWIN
#include <windows.h>
#endif

#ifdef _WIN32
#include <windows.h>
#endif

#define PERLIO_NOT_STDIO 0

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#define NEED_PL_signals 1
#define NEED_sv_2pv_nolen 1
#include "ppport.h"

#include <time.h>
#include <string.h>
#include <ncap.h>

#ifdef _CYGWIN
#include <Win32-Extensions.h>
#endif

typedef struct ncap     *Net__Ncap__ncap;
typedef struct ncap_msg *Net__Ncap__ncap_msg;

typedef struct ncap     ncap;
typedef struct ncap_msg ncap_msg;

#include <signal.h>
#include <assert.h>

#ifdef __cplusplus
}
#endif

static ncap_t ncap_collector;
static int alarmflag = 0;
static volatile sig_atomic_t sigflag = 0;

/* wrapper for callback function */

SV *callback_fn;

static void
callback_wrapper(ncap *nc, void *obj, ncap_msg *msg, const char *label) {

    ncap_msg *inner;

    dSP;

    ENTER;
    SAVETMPS;

    // push args onto stack
    PUSHMARK(sp);
    if (msg == NULL)
        XPUSHs(&PL_sv_undef);
    else {
        // since these are statically allocated, peel off local copies
        inner = (ncap_msg *)savepvn((char *)msg, sizeof(*msg));
        inner->payload = savepvn(inner->payload, inner->paylen);
        XPUSHs(sv_2mortal(sv_setref_pv(
            newSV(0), "Net::Ncap::ncap_msg", (char *)inner
        ))); 
    }
    if (label != NULL)
        XPUSHs( sv_2mortal(newSVpvn(label, strlen(label))) );
    PUTBACK;

    // invoke perl function
    call_sv(callback_fn, G_DISCARD);

    // clean up
    FREETMPS;
    LEAVE;
}

/* time util */

static void
filltime(struct timespec *t) {
#ifdef CLOCK_REALTIME
    (void) clock_gettime(CLOCK_REALTIME, t);
#else
    struct timeval tv;
    (void) gettimeofday(&tv, NULL);
    t->tv_sec = tv.tv_sec;
    t->tv_nsec = tv.tv_usec * 1000;
#endif
}

/* signal handler wrapping */

void
signal_handler(int signum) {
    sigflag = signum;
    if (sigflag == SIGALRM)
        alarmflag = 0;
    if (ncap_collector != NULL)
        ncap_collector->stop(ncap_collector);
}

static void
set_sig(int sig, struct sigaction *new, struct sigaction *old) {
    if (sigaction(sig, NULL, old) < 0) {
        perror("sigaction");
        exit(1);
    }
    if (old->sa_handler != SIG_IGN) {
        if (sigaction(sig, new, NULL) < 0) {
            perror("sigaction");
            exit(1);
        }
    }
}

static void
init_sig(struct sigaction *sa, void *handler, int single) {
    sigemptyset(&sa->sa_mask);
    sa->sa_handler = handler;
    if (single)
        sa->sa_flags = SA_RESETHAND;
    else
        sa->sa_flags = SA_RESTART;
}

ncap_result_e
collect_sigwrap(ncap_t ncap, int polling, int timeout,
                ncap_callback_t callback, void *obj) {

    struct timespec cbstart;
    struct sigaction new_hup, new_int, new_term, new_alrm;
    struct sigaction old_hup, old_int, old_term, old_alrm;
    init_sig(&new_hup,  signal_handler, 1);
    init_sig(&new_int,  signal_handler, 1);
    init_sig(&new_term, signal_handler, 1);
    if (timeout)
        init_sig(&new_alrm, signal_handler, 0);
    else
        init_sig(&new_alrm, SIG_DFL, 0);

    ncap_result_e rv;
    ncap_collector = ncap;

    filltime(&cbstart);

    set_sig(SIGHUP,  &new_hup,  &old_hup);
    set_sig(SIGINT,  &new_int,  &old_int);
    set_sig(SIGTERM, &new_term, &old_term);
    set_sig(SIGALRM, &new_alrm, &old_alrm);

    if (timeout) {
        alarm(timeout);
        alarmflag = 1;
    }

    do {
        sigflag = 0;
        rv = ncap->collect(ncap, polling,
                          (ncap_callback_t)callback_wrapper, obj);
        if (sigflag == SIGALRM && !alarmflag) {
            unsigned seconds;
            time_t gap;

            callback_wrapper(ncap, obj, NULL, NULL);

            gap = (((cbstart.tv_sec + (timeout / 2)) / timeout) + 1) * timeout;
            assert(gap > cbstart.tv_sec);
            seconds = gap - cbstart.tv_sec;
            alarm(seconds);
            alarmflag = 1;
        }
    } while (sigflag == SIGALRM);

    set_sig(SIGHUP,  &old_hup,  &new_hup);
    set_sig(SIGINT,  &old_int,  &new_int);
    set_sig(SIGTERM, &old_term, &new_term);
    set_sig(SIGALRM, &old_alrm, &new_alrm);

    if (sigflag != 0)
        raise(sigflag);

    ncap_collector = NULL;

    return rv;
}


MODULE = Net::Ncap              PACKAGE = Net::Ncap::ncap       PREFIX = ncap_

Net::Ncap::ncap
ncap_new(CLASS, maxmsg)
    char *CLASS
    int maxmsg
    PROTOTYPE: $
    CODE:
    RETVAL = (Net__Ncap__ncap)ncap_create(maxmsg);
    OUTPUT:
    RETVAL

char *
ncap_errstr(THIS)
        Net::Ncap::ncap THIS
    PROTOTYPE: $
    CODE:
        RETVAL = THIS->errstr;
    OUTPUT:
        RETVAL

SV *
ncap_add_if(THIS, name, bpf, promisc, vlans, nvlan)
        Net::Ncap::ncap THIS
        const char *name
        const char *bpf
        int     promisc
        int     *vlans
        int     nvlan
    PROTOTYPE: $;$;$;$;$;$
    CODE:
    int fdes;
    ST(0) = sv_newmortal();
    if (THIS->add_if(THIS, name, bpf, promisc, vlans, nvlan, &fdes) == ncap_success)
        sv_setnv(ST(0), fdes);

SV *
ncap_drop_if(THIS, fdes)
        Net::Ncap::ncap THIS
    int fdes
    PROTOTYPE: $;$
    CODE:
    ST(0) = sv_newmortal();
    if (THIS->drop_if(THIS, fdes) == ncap_success)
        sv_setnv(ST(0), 1);

SV *
ncap_add_nf(THIS, fdes, label)
        Net::Ncap::ncap THIS
    PerlIO *fdes
    const char *label
    PROTOTYPE: $;$;$
    CODE:
    ST(0) = sv_newmortal();
        if (THIS->add_nf(THIS, PerlIO_fileno(fdes), label) == ncap_success)
        sv_setnv(ST(0), 1);

SV *
ncap_drop_nf(THIS, fdes)
        Net::Ncap::ncap THIS
    PerlIO *fdes
    PROTOTYPE: $;$
    CODE:
    ST(0) = sv_newmortal();
    if (THIS->drop_nf(THIS, PerlIO_fileno(fdes)) == ncap_success)
        sv_setnv(ST(0), 1);

SV *
ncap_add_pf(THIS, fp, label)
        Net::Ncap::ncap THIS
    FILE *fp
    const char *label
    PROTOTYPE: $;$;$
    CODE:
    ST(0) = sv_newmortal();
        if (THIS->add_pf(THIS, fp, label) == ncap_success)
        sv_setnv(ST(0), 1);

SV *
ncap_drop_pf(THIS, fp)
        Net::Ncap::ncap THIS
    FILE *fp
    PROTOTYPE: $;$
    CODE:
    ST(0) = sv_newmortal();
    if (THIS->drop_pf(THIS, fp) == ncap_success)
        sv_setnv(ST(0), 1);

SV *
ncap_add_dg(THIS, fdes, label)
        Net::Ncap::ncap THIS
    PerlIO *fdes
    const char *label
    PROTOTYPE: $;$;$
    CODE:
    ST(0) = sv_newmortal();
        if (THIS->add_dg(THIS, PerlIO_fileno(fdes), label) == ncap_success)
        sv_setnv(ST(0), 1);

SV *
ncap_drop_dg(THIS, fdes)
        Net::Ncap::ncap THIS
    PerlIO *fdes
    PROTOTYPE: $;$
    CODE:
    ST(0) = sv_newmortal();
    if (THIS->drop_dg(THIS, PerlIO_fileno(fdes)) == ncap_success)
        sv_setnv(ST(0), 1);

SV *
ncap_filter(THIS, ospec)
        Net::Ncap::ncap THIS
    const char *ospec
    PROTOTYPE: $;$
    CODE:
    ST(0) = sv_newmortal();
        if (THIS->filter((ncap *)THIS, ospec) == ncap_success)
        sv_setnv(ST(0), 1);

SV *
ncap_collect_sighandle(THIS, polling, timeout, callback, obj)
        Net::Ncap::ncap THIS
    int polling
    int timeout
    SV *callback
    SV *obj
    PROTOTYPE: $;$;$;$;$
    CODE:
    callback_fn = sv_2mortal(newSVsv(callback));
    ST(0) = sv_newmortal();
    if (collect_sigwrap((ncap_t)THIS,
                        polling,
                        timeout,
                        (ncap_callback_t)callback_wrapper,
                        obj) == ncap_success)
        sv_setnv(ST(0), 1);

SV *
ncap_collect(THIS, polling, callback, obj)
        Net::Ncap::ncap THIS
    int polling
    SV *callback
    SV *obj
    PROTOTYPE: $;$;$;$
    CODE:
    callback_fn = sv_2mortal(newSVsv(callback));
    ST(0) = sv_newmortal();
    if (THIS->collect(THIS,
                      polling,
                      (ncap_callback_t)callback_wrapper,
                      obj) == ncap_success)
        sv_setnv(ST(0), 1);

void *
ncap_stop(THIS)
        Net::Ncap::ncap THIS
    PROTOTYPE: $
    CODE:
        THIS->stop(THIS);

SV *
ncap_write(THIS, fp, msg = NULL)
        Net::Ncap::ncap THIS
    Net::Ncap::ncap_msg msg
    FILE *fp
    PROTOTYPE: $;$;$
    CODE:
    ST(0) = sv_newmortal();
        if (THIS->fwrite(THIS, msg, fp) == ncap_success)
        sv_setnv(ST(0), 1);

SV *
ncap_send(THIS, fdes, msg = NULL, flags = MSG_DONTROUTE)
        Net::Ncap::ncap THIS
    Net::Ncap::ncap_msg msg
    PerlIO *fdes
    int flags
    PROTOTYPE: $;$;$;$
    CODE:
    ST(0) = sv_newmortal();
        if (THIS->send(THIS, msg, PerlIO_fileno(fdes), flags) == ncap_success)
        sv_setnv(ST(0), 1);

void
ncap_DESTROY(THIS)
        Net::Ncap::ncap THIS
    PROTOTYPE: $
    CODE:
        THIS->destroy(THIS);


MODULE = Net::Ncap              PACKAGE = Net::Ncap::ncap_msg       PREFIX=ncap_msg_

time_t
ncap_msg_sec(THIS)
        Net::Ncap::ncap_msg THIS
    PROTOTYPE: $
    CODE:
        RETVAL = THIS->ts.tv_sec;
    OUTPUT:
        RETVAL

long int
ncap_msg_nsec(THIS)
        Net::Ncap::ncap_msg THIS
    PROTOTYPE: $
    CODE:
        RETVAL = THIS->ts.tv_nsec;
    OUTPUT:
        RETVAL

unsigned
ncap_msg_user1(THIS)
        Net::Ncap::ncap_msg THIS
    PROTOTYPE: $
    CODE:
        RETVAL = THIS->user1;
    OUTPUT:
        RETVAL

unsigned
ncap_msg_user2(THIS)
        Net::Ncap::ncap_msg THIS
    PROTOTYPE: $
    CODE:
        RETVAL = THIS->user2;
    OUTPUT:
        RETVAL

SV *
ncap_msg_nproto(THIS)
        Net::Ncap::ncap_msg THIS
    PROTOTYPE: $
    CODE:
    ST(0) = sv_newmortal();
    switch (THIS->np) {
    case ncap_ip4:
        sv_setnv(ST(0), IPPROTO_IP);
        break;
    case ncap_ip6:
        sv_setnv(ST(0), IPPROTO_IPV6);
        break;
    }

SV *
ncap_msg_tproto(THIS)
        Net::Ncap::ncap_msg THIS
    PROTOTYPE: $
    CODE:
    ST(0) = sv_newmortal();
    switch (THIS->tp) {
    case ncap_tcp:
        sv_setnv(ST(0), IPPROTO_TCP);
        break;
    case ncap_udp:
        sv_setnv(ST(0), IPPROTO_UDP);
        break;
    case ncap_icmp:
        switch (THIS->np) {
        case ncap_ip4:
            sv_setnv(ST(0), IPPROTO_ICMP);
            break;
        case ncap_ip6:
            sv_setnv(ST(0), IPPROTO_ICMPV6);
            break;
        }
        break;
    }

unsigned
ncap_msg_paylen(THIS)
        Net::Ncap::ncap_msg THIS
    PROTOTYPE: $
    CODE:
        RETVAL = THIS->paylen;
    OUTPUT:
        RETVAL

SV *
ncap_msg_payload(THIS)
        Net::Ncap::ncap_msg THIS
    PROTOTYPE: $
    CODE:
    ST(0) = newSVpvn((char *)THIS->payload, THIS->paylen);

SV *
ncap_msg_src_packed(THIS)
        Net::Ncap::ncap_msg THIS
    PROTOTYPE: $
    CODE:
    ST(0) = sv_newmortal();
    switch (THIS->np) {
    case ncap_ip4:
        sv_setpvn(ST(0), (char *)&THIS->npu.ip4.src, sizeof(THIS->npu.ip4.src));
        break;
    case ncap_ip6:
        sv_setpvn(ST(0), (char *)&THIS->npu.ip6.src, sizeof(THIS->npu.ip6.src));
        break;
    }

SV *
ncap_msg_dst_packed(THIS)
        Net::Ncap::ncap_msg THIS
    PROTOTYPE: $
    CODE:
    ST(0) = sv_newmortal();
    switch (THIS->np) {
    case ncap_ip4:
        sv_setpvn(ST(0), (char *)&THIS->npu.ip4.dst, sizeof(THIS->npu.ip4.dst));
        break;
    case ncap_ip6:
        sv_setpvn(ST(0), (char *)&THIS->npu.ip6.dst, sizeof(THIS->npu.ip6.dst));
        break;
    }

SV *
ncap_msg_type(THIS)
    Net::Ncap::ncap_msg THIS
    PROTOTYPE: $
    CODE:
    ST(0) = sv_newmortal();
    if (THIS->tp == ncap_icmp)
        sv_setnv(ST(0), THIS->tpu.icmp.type);

SV *
ncap_msg_code(THIS)
    Net::Ncap::ncap_msg THIS
    PROTOTYPE: $
    CODE:
    ST(0) = sv_newmortal();
    if (THIS->tp == ncap_icmp)
        sv_setnv(ST(0), THIS->tpu.icmp.code);

SV *
ncap_msg_offset(THIS)
    Net::Ncap::ncap_msg THIS
    PROTOTYPE: $
    CODE:
    ST(0) = sv_newmortal();
    if (THIS->tp == ncap_tcp)
        sv_setnv(ST(0), THIS->tpu.tcp.offset);

SV *
ncap_msg_flags(THIS)
    Net::Ncap::ncap_msg THIS
    PROTOTYPE: $
    CODE:
    ST(0) = sv_newmortal();
    if (THIS->tp == ncap_tcp)
        sv_setnv(ST(0), THIS->tpu.tcp.flags);

SV *
ncap_msg_sport(THIS)
    Net::Ncap::ncap_msg THIS
    PROTOTYPE: $
    CODE:
    ST(0) = sv_newmortal();
    switch (THIS->tp) {
    case ncap_tcp:
        sv_setnv(ST(0), THIS->tpu.tcp.sport);
        break;
    case ncap_udp:
        sv_setnv(ST(0), THIS->tpu.udp.sport);
        break;
    }

SV *
ncap_msg_dport(THIS)
    Net::Ncap::ncap_msg THIS
    PROTOTYPE: $
    CODE:
    ST(0) = sv_newmortal();
    switch (THIS->tp) {
    case ncap_tcp:
        sv_setnv(ST(0), THIS->tpu.tcp.dport);
        break;
    case ncap_udp:
        sv_setnv(ST(0), THIS->tpu.udp.dport);
        break;
    }

void
ncap_msg_DESTROY(THIS)
    Net::Ncap::ncap_msg THIS
    PROTOTYPE: $
    CODE:
    Safefree(THIS->payload);
    Safefree(THIS);
