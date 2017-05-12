/* $Id: Kqueue.xs,v 1.10 2005/03/14 14:17:22 godegisel Exp $ */
#define PERL_NO_GET_CONTEXT     /* we want efficiency */

#ifdef __cplusplus
extern "C" {
#endif

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#ifdef __cplusplus
}
#endif

#include <sys/types.h>
#include <sys/event.h>
#include <sys/time.h>

#include "ppport.h"

#ifndef LOOP_DEBUG
#define	LOOP_DEBUG		0
#endif

#define MY_CXT_KEY "POE::Loop::Kqueue_" XS_VERSION

#define	EVLIST_UPDATE_START	1024
#define	EVLIST_UPDATE_STEP	1024
#define	EVLIST_FETCH_START	1024
#define	EVLIST_FETCH_STEP	1024
#define	FD_READY_START		1024
#define	FD_READY_STEP		1024

#define	MODE_RD		(UV)0
#define	MODE_WR		(UV)1

#define MODE_2_FILTER(mode)	(mode == MODE_RD ? EVFILT_READ : EVFILT_WRITE)
#define MODE_2_STR(mode)	(mode == MODE_RD ? "rd" : "wr")
#define	TIMER_ID	44

#if LOOP_DEBUG > 1
static const char * FILTER_2_STRING[EVFILT_SYSCOUNT + 1] = {
	"<none>",
	"EVFILT_READ",
	"EVFILT_WRITE",
	"EVFILT_AIO",
	"EVFILT_VNODE",
	"EVFILT_PROC",
	"EVFILT_SIGNAL",
	"EVFILT_TIMER",
};
#endif

typedef struct {
	int kq;
	time_t next_time;

	bool inside_timeslice;

	struct kevent *evlist_update;
	int evlist_update_len;
	int evlist_update_alloc;

	struct kevent *evlist_fetch;
	int evlist_fetch_alloc;

	u_int *fd_ready_read;
	u_int fd_ready_read_alloc;

	u_int *fd_ready_write;
	u_int fd_ready_write_alloc;

#if LOOP_DEBUG > 1
	U32 fd_active[2];
	U32 fd_paused[2];
#endif
} my_cxt_t;

START_MY_CXT

#if LOOP_DEBUG > 2
#define	MEM_DEBUG	1
#else
#define	MEM_DEBUG	0
#endif

#define	CACHE_ALLOC(VAR_ROOT, MACRO_ROOT, VAR_TYPE)		\
    STMT_START {						\
    	if(VAR_ROOT)						\
    		Safefree(VAR_ROOT);				\
	New(66, VAR_ROOT, MACRO_ROOT ## _START, VAR_TYPE);	\
	VAR_ROOT ## _alloc = EVLIST_UPDATE_START;		\
	if(MEM_DEBUG) warn("alloc " #VAR_ROOT ": %u\n", VAR_ROOT); \
    } STMT_END

#define	CACHE_CHECK(VAR_ROOT, MACRO_ROOT, VAR_TYPE, VAR_LEN)	\
	if(VAR_LEN >= VAR_ROOT ## _alloc)	{		\
		VAR_ROOT ## _alloc += MACRO_ROOT ## _STEP;	\
		Renew(VAR_ROOT, VAR_ROOT ## _alloc, VAR_TYPE);	\
	}

#define	CACHE_FREE(VAR_ROOT)		\
	if(VAR_ROOT)	{		\
		if(MEM_DEBUG) warn("free " #VAR_ROOT ": %u\n", VAR_ROOT); \
		Safefree(VAR_ROOT);	\
		VAR_ROOT = NULL;	\
		VAR_ROOT ## _alloc = 0;	\
	}

/* methods' names */
#define	CONST_SV_DECLARE( NAME )	static SV *sv_method_ ## NAME
#define	CONST_SV_INIT( NAME )				\
    STMT_START {					\
	sv_method_ ## NAME = newSVpv( #NAME , 0);	\
	SvREADONLY_on( sv_method_ ## NAME );		\
    } STMT_END

CONST_SV_DECLARE(_data_ses_count);
CONST_SV_DECLARE(_test_if_kernel_is_idle);
CONST_SV_DECLARE(_data_handle_enqueue_ready);
CONST_SV_DECLARE(_data_ev_dispatch_due);
CONST_SV_DECLARE(get_next_event_time);

static inline void push_event(pTHX_ uintptr_t ident, int filter,
	u_int flags, u_int fflags, intptr_t data, void *udata)
{
	dMY_CXT;
    	struct kevent *ev;

    	CACHE_CHECK(MY_CXT.evlist_update, EVLIST_UPDATE, struct kevent, MY_CXT.evlist_update_len);

	ev = &MY_CXT.evlist_update[ MY_CXT.evlist_update_len++ ];
    	EV_SET(ev, ident, filter, flags, fflags, data, udata);
}

#if LOOP_DEBUG
static void dump_event(pTHX_ struct kevent *ev)
{
	char buf[512];

	int t = ev->flags;
	buf[0] = '\0';

	if(t & EV_ADD)
		strcat(buf, "EV_ADD");
	if(t & EV_DELETE)
		strcat(buf, "EV_DELETE");
	if(t & EV_ENABLE)
		strcat(buf, "EV_ENABLE");
	if(t & EV_DISABLE)
		strcat(buf, "EV_DISABLE");
	if(t & EV_ONESHOT)
		strcat(buf, "EV_ONESHOT");
	if(t & EV_CLEAR)
		strcat(buf, "EV_CLEAR");
	if(t & EV_FLAG1)
		strcat(buf, "EV_FLAG1");
	if(t & EV_EOF)
		strcat(buf, "EV_EOF");
	if(t & EV_ERROR)
		strcat(buf, "EV_ERROR");

	warn(aTHX_ "ident=%u filter=%-14s flags=%s\n",
		ev->ident, FILTER_2_STRING[-ev->filter], buf);
	return;
}

static void dump_evlist(pTHX_ struct kevent *evlist, int len)
{
	struct kevent *ev = evlist;

	for(; len--; ev++)	{
		dump_event(aTHX_ ev);
	}

	return;
}
#endif

static inline void kevent_update(pTHX_ void)
{
	dMY_CXT;
	int rc;
	rc = kevent(MY_CXT.kq, MY_CXT.evlist_update, MY_CXT.evlist_update_len, NULL, 0, NULL);

	if(rc == -1)	{
#if LOOP_DEBUG > 1
		dump_evlist(MY_CXT.evlist_update, MY_CXT.evlist_update_len);
#endif
			croak(aTHX_ "POE::Loop::Kqueue::kevent_update failed: %s", strerror(errno));
	}

	MY_CXT.evlist_update_len = 0;
}

#if LOOP_DEBUG > 1
static inline void dump_fd(pTHX_ void)
{
	dMY_CXT;
	char buf[2][33];
	int i, j;
	for(i = 0; i < 2; i++)	{
	    U32 active = MY_CXT.fd_active[i];
	    U32 paused = MY_CXT.fd_paused[i];
	    for(j = 0; j < 32; j++)	{
	    	U32 mask = (1 << j);
	    	buf[i][j] = (active & mask)
	    		  ? 'A'
	    		  : (paused & mask) ? 'P' : '.';
	    }
	    buf[i][32] = '\0';
	}
	warn(aTHX_ "       00000000001111111111222222222233\n");
	warn(aTHX_ "       01234567890123456789012345678901\n");
	warn(aTHX_ "fd[RD]=%s\nfd[WR]=%s\n", buf[0], buf[1]);
}
#endif

static void do_timeslice(pTHX_ SV *self)
{
	dSP;
	dMY_CXT;
	int rc;
	struct timespec timeout;
	u_int fd_rd_len = 0, fd_wr_len = 0;
#if LOOP_DEBUG > 2
	warn(aTHX_ "do_timeslice\n");
#endif
	/* my $next_time = $self->get_next_event_time(); */
	if(!MY_CXT.next_time)		{
		SV *next_timeSV;

		ENTER;
		SAVETMPS;

	 	PUSHMARK(SP);
	  	XPUSHs(self);
	   	PUTBACK;

		(void)perl_call_sv(sv_method_get_next_event_time, G_SCALAR|G_METHOD);
		SPAGAIN;

		next_timeSV = POPs;
		if(SvOK(next_timeSV))	{
			MY_CXT.next_time = SvUV( next_timeSV );
#if LOOP_DEBUG > 1
			warn(aTHX_ "do_slice!!!: next_time=%u\n", MY_CXT.next_time);
#endif
		}

		FREETMPS;
		LEAVE;
	}

	if(MY_CXT.next_time)	{
		struct timeval now;
		(void)gettimeofday(&now, NULL);
#if LOOP_DEBUG > 1
		warn(aTHX_ "do_timeslice: now.sec=%u now.usec=%u\n",
			now.tv_sec, now.tv_usec);
#endif

		if(MY_CXT.next_time > now.tv_sec)	{
			timeout.tv_sec = MY_CXT.next_time - now.tv_sec;
			if(now.tv_usec)	{
				timeout.tv_sec--;
				timeout.tv_nsec = 1000000000 - now.tv_usec * 1000;
			}else	{
				timeout.tv_nsec = 0;
			}
		}else					{
			/* 
			   if timeout.tv_sec == 0 we can directly
			   call _data_ev_dispatch_due(), go to above
			   to call get_next_event_time() and so on.

			   however we fairly give a chance for other events (like I/O
			   activity) to be occured and avoid possible bottleneck.

			   maybe in the future this behaviour can be changed
			   to exclude excessive syscalls (you hate them too, yea?)
			*/

			timeout.tv_sec = 0;
			timeout.tv_nsec = 0;
		}
#if LOOP_DEBUG
		warn(aTHX_ "do_timeslice: next_time=%u now.sec=%u timeout.sec=%u timeout.nsec=%u\n",
			MY_CXT.next_time, now.tv_sec, timeout.tv_sec, timeout.tv_nsec);
#endif
	}else	{
		timeout.tv_sec = 3600; /* block almost forever. don't scare! */
		timeout.tv_nsec = 0;
#if LOOP_DEBUG
		warn(aTHX_ "do_timeslice: timeout = NULL\n");
#endif
	}

	rc = kevent(MY_CXT.kq, MY_CXT.evlist_update, MY_CXT.evlist_update_len,
		MY_CXT.evlist_fetch, MY_CXT.evlist_fetch_alloc, &timeout);

	if(rc == -1)	{
#if LOOP_DEBUG > 1
		dump_evlist(MY_CXT.evlist_update, MY_CXT.evlist_update_len);
#endif
    		croak(aTHX_ "POE::Loop::Kqueue::do_timeslice: kevent poll: kq=%i : %s",
    			MY_CXT.kq, strerror(errno) );
	}

	MY_CXT.evlist_update_len = 0;
	//MY_CXT.inside_timeslice = 1;	/* accumulate new events but do not call kevent() */

#if LOOP_DEBUG
	warn(aTHX_ "do_timeslice: rc=%i\n", rc);
#endif
#if LOOP_DEBUG > 1
	dump_fd(aTHX_);
#endif
	if(!rc)	{
	    /* kevent() returns 0 when timeout expired */
	    MY_CXT.next_time = 0;
	}else	{
    	    struct kevent *ev;

	    if(!timeout.tv_sec && !timeout.tv_nsec) /* exclude duplicate calls for the same event */
		MY_CXT.next_time = 0;

	    for(ev = MY_CXT.evlist_fetch; rc--; ev++)	{
#if LOOP_DEBUG > 4
		if(-ev->filter > EVFILT_SYSCOUNT)	/* impossible thing, really */
			warn(aTHX_ "ev: filter=%i\n", ev->filter);
		else
			warn(aTHX_ "ev: filter=%s\n", FILTER_2_STRING[-ev->filter]);
#endif
		if(ev->flags & EV_ERROR)	{
#if LOOP_DEBUG > 1
			dump_evlist(MY_CXT.evlist_update, MY_CXT.evlist_update_len);
			dump_evlist(MY_CXT.evlist_fetch, rc);
#endif
    			croak(aTHX_ "POE::Loop::Kqueue::do_timeslice: kevent update: " \
				"filter=%i ident=%u flags=0x%x: %s",
    				ev->filter, ev->ident, ev->flags, strerror(ev->data) );
		}

		switch(ev->filter)	{
		    case EVFILT_READ:
#if LOOP_DEBUG > 1
			warn(aTHX_ "ev: filter=EVFILT_READ fd=%u\n", ev->ident);
#endif
		        {
			    CACHE_CHECK(MY_CXT.fd_ready_read, FD_READY, u_int, fd_rd_len);
			    MY_CXT.fd_ready_read[fd_rd_len++] = ev->ident;
		        }
			break;
		    case EVFILT_WRITE:
#if LOOP_DEBUG > 1
			warn(aTHX_ "ev: filter=EVFILT_WRITE fd=%u\n", ev->ident);
#endif
		        {
			    CACHE_CHECK(MY_CXT.fd_ready_write, FD_READY, u_int, fd_wr_len);
			    MY_CXT.fd_ready_write[fd_wr_len++] = ev->ident;
		        }
			break;
		    default:
			croak(aTHX_ "POE::Loop::Kqueue::do_timeslice: unhandled event [ident=%u filter=%i]",
				ev->ident, ev->filter);
			break;
		} /* switch */
	    } /* for */
	} /* if */

	/* { */
	ENTER;
	SAVETMPS;

	if(fd_rd_len)	{
		u_int *p;

		/* $self->_data_handle_enqueue_ready(MODE_RD, @fd_ready_read); */

	 	PUSHMARK(SP);
		EXTEND(SP, 2 + fd_rd_len);
	  	PUSHs( self );
	  	PUSHs( sv_2mortal(newSVuv( MODE_RD )) );

	  	for(p = MY_CXT.fd_ready_read; fd_rd_len--; p++)
		  	PUSHs( sv_2mortal(newSVuv( (UV)*p )) );

	   	PUTBACK;

		(void)perl_call_sv(sv_method__data_handle_enqueue_ready, G_VOID|G_METHOD);
		SPAGAIN;
	}

	if(fd_wr_len)	{
		u_int *p;

		/* $self->_data_handle_enqueue_ready(MODE_WR, @fd_ready_write); */

	 	PUSHMARK(SP);
		EXTEND(SP, 2 + fd_wr_len);
	  	PUSHs( self );
	  	PUSHs( sv_2mortal(newSVuv( MODE_WR )) );

	  	for(p = MY_CXT.fd_ready_write; fd_wr_len--; p++)
		  	PUSHs( sv_2mortal(newSVuv( (UV)*p )) );

	   	PUTBACK;

		(void)perl_call_sv(sv_method__data_handle_enqueue_ready, G_VOID|G_METHOD);
		SPAGAIN;
	}

	/* $self->_data_ev_dispatch_due(); */

 	PUSHMARK(SP);
  	XPUSHs(self);
   	PUTBACK;

	(void)perl_call_sv(sv_method__data_ev_dispatch_due, G_VOID|G_METHOD);
	SPAGAIN;

	/* $self->_test_if_kernel_is_idle(); */

 	PUSHMARK(SP);
  	XPUSHs(self);
   	PUTBACK;

	(void)perl_call_sv(sv_method__test_if_kernel_is_idle, G_VOID|G_METHOD);
	SPAGAIN;

	/* } */
	FREETMPS;
	LEAVE;

	/*
	if(MY_CXT.evlist_update_len)
		kevent_update(aTHX);
	*/

	/*
	MY_CXT.inside_timeslice = 0;
	*/

	return;
}

MODULE = POE::Loop::Kqueue		PACKAGE = POE::Kernel

PROTOTYPES: DISABLE

BOOT:
{
	CONST_SV_INIT(_data_ses_count);
	CONST_SV_INIT(_test_if_kernel_is_idle);
	CONST_SV_INIT(_data_handle_enqueue_ready);
	CONST_SV_INIT(_data_ev_dispatch_due);
	CONST_SV_INIT(get_next_event_time);
#ifdef MY_CXT_KEY
	MY_CXT_INIT;
#endif
	memset(&MY_CXT, 0, sizeof(MY_CXT));
	MY_CXT.kq = -1;
}

#if defined(PERL_IMPLICIT_CONTEXT) && defined(MY_CXT_KEY)

void
CLONE(...)
    CODE:
	MY_CXT_CLONE;

#endif

void
loop_initialize(self)
    CODE:
    {
#if LOOP_DEBUG
	warn("loop_initialize\n");
#endif
    	if(MY_CXT.kq >= 0)
	    croak("POE::Loop::Kqueue is already initialized!");

    	MY_CXT.kq = kqueue();
    	if(MY_CXT.kq == -1)
    		croak("POE::Loop::Kqueue::loop_initialize: can not create kqueue: %s",
    			strerror(errno) );

	MY_CXT.next_time = 0;

    	/* allocate buffers */
    	CACHE_ALLOC(MY_CXT.evlist_update,  EVLIST_UPDATE, struct kevent);
	MY_CXT.evlist_update_len = 0;
   	CACHE_ALLOC(MY_CXT.evlist_fetch,   EVLIST_FETCH,  struct kevent);
    	CACHE_ALLOC(MY_CXT.fd_ready_read,  FD_READY,	  u_int);
    	CACHE_ALLOC(MY_CXT.fd_ready_write, FD_READY,	  u_int);
#if LOOP_DEBUG > 1
	MY_CXT.fd_active[0] = 0; MY_CXT.fd_active[1] = 0;
	MY_CXT.fd_paused[0] = 0; MY_CXT.fd_paused[1] = 0;
#endif
	XSRETURN_EMPTY;
    }

void
loop_finalize(self)
    CODE:
    {
#if LOOP_DEBUG
	warn("loop_finalize\n");
#endif
    	if(MY_CXT.kq >= 0)	{
		if(close(MY_CXT.kq))
			croak("POE::Loop::Kqueue::loop_finalize: close kqueue: %s",
				strerror(errno) );
    		MY_CXT.kq = -1;
    	}

    	CACHE_FREE(MY_CXT.evlist_update);
	MY_CXT.evlist_update_len = 0;
    	CACHE_FREE(MY_CXT.evlist_fetch);
    	CACHE_FREE(MY_CXT.fd_ready_read);
    	CACHE_FREE(MY_CXT.fd_ready_write);

	XSRETURN_EMPTY;
    }

void
loop_resume_time_watcher(self, next_time)
    CODE:
    {
    	u_int next_time = SvUV( ST(1) );

	MY_CXT.next_time = next_time;
#if LOOP_DEBUG
	warn("loop_resume_time_watcher:\tnext_time=%u\n", next_time);
#endif
	XSRETURN_EMPTY;
    }

void
loop_reset_time_watcher(self, next_time)
    CODE:
    {
    	u_int next_time = SvUV( ST(1) );

	MY_CXT.next_time = next_time;
#if LOOP_DEBUG
	warn("loop_reset_time_watcher:\tnext_time=%u\n", next_time);
#endif
	XSRETURN_EMPTY;
    }

void
loop_pause_time_watcher(self)
    CODE:
    {
#if LOOP_DEBUG
	warn("loop_pause_time_watcher\n");
#endif
	MY_CXT.next_time = 0;

	XSRETURN_EMPTY;
    }

void
loop_watch_filehandle(self, handle, mode)
    CODE:
    {
	u_int fd = PerlIO_fileno( IoIFP(sv_2io( ST(1) )) );
	u_int mode = SvUV( ST(2) );

	if(mode >= 2)
		croak("POE::Loop::Kqueue does not support expedited filehandles");
#if LOOP_DEBUG
	warn("loop_watch_filehandle:\t%0.2i %s\n", fd, MODE_2_STR(mode));
#endif
    	push_event(aTHX_ fd, MODE_2_FILTER(mode), EV_ADD|EV_ENABLE, 0, 0, NULL);

	if(!MY_CXT.inside_timeslice)
		kevent_update(aTHX);
#if LOOP_DEBUG > 1
        if(fd < 32)
       		MY_CXT.fd_active[mode] |= (1 << fd);
#endif
#if LOOP_DEBUG > 2
	dump_fd(aTHX_);
#endif
	XSRETURN_EMPTY;
    }

void
loop_ignore_filehandle(self, handle, mode)
    CODE:
    {
	u_int fd = PerlIO_fileno( IoIFP(sv_2io( ST(1) )) );
	u_int mode = SvUV( ST(2) );

	if(mode >= 2)
		croak("POE::Loop::Kqueue does not support expedited filehandles");
#if LOOP_DEBUG
	warn("loop_ignore_filehandle:\t%0.2i %s\n", fd, MODE_2_STR(mode));
#endif
    	push_event(aTHX_ fd, MODE_2_FILTER(mode), EV_DELETE, 0, 0, NULL);

	kevent_update(aTHX);
#if LOOP_DEBUG > 1
        if(fd < 32)	{
       		MY_CXT.fd_active[mode] &= ~(1 << fd);
       		MY_CXT.fd_paused[mode] &= ~(1 << fd);
        }
#endif
#if LOOP_DEBUG > 2
	dump_fd(aTHX_);
#endif
	XSRETURN_EMPTY;
    }

void
loop_pause_filehandle(self, handle, mode)
    CODE:
    {
	u_int fd = PerlIO_fileno( IoIFP(sv_2io( ST(1) )) );
	int mode = SvIV( ST(2) );

	if(mode == 2)
		croak("POE::Loop::Kqueue does not support expedited filehandles");
#if LOOP_DEBUG
	warn("loop_pause_filehandle:\t%0.2i %s\n", fd, MODE_2_STR(mode));
#endif
    	push_event(aTHX_ fd, MODE_2_FILTER(mode), EV_DISABLE, 0, 0, NULL); /* disable only! */

	if(!MY_CXT.inside_timeslice)
		kevent_update(aTHX);
#if LOOP_DEBUG > 1
        if(fd < 32)	{
       		MY_CXT.fd_active[mode] &= ~(1 << fd);
       		MY_CXT.fd_paused[mode] |=  (1 << fd);
        }
#endif
#if LOOP_DEBUG > 2
	dump_fd(aTHX_);
#endif
	XSRETURN_EMPTY;
    }

void
loop_resume_filehandle(self, handle, mode)
    CODE:
    {
	u_int fd = PerlIO_fileno( IoIFP(sv_2io( ST(1) )) );
	u_int mode = SvUV( ST(2) );

	if(mode >= 2)
		croak("POE::Loop::Kqueue does not support expedited filehandles");
#if LOOP_DEBUG
	warn("loop_resume_filehandle:\t%0.2i %s\n", fd, MODE_2_STR(mode));
#endif
    	push_event(aTHX_ fd, MODE_2_FILTER(mode), EV_ENABLE, 0, 0, NULL); /* enable only! */

	if(!MY_CXT.inside_timeslice)
		kevent_update(aTHX);
#if LOOP_DEBUG > 1
        if(fd < 32)	{
       		MY_CXT.fd_active[mode] |=  (1 << fd);
       		MY_CXT.fd_paused[mode] &= ~(1 << fd);
        }
#endif
#if LOOP_DEBUG > 2
	dump_fd(aTHX_);
#endif
	XSRETURN_EMPTY;
    }

void
loop_do_timeslice(self)
    CODE:
    {
	do_timeslice(aTHX_ ST(0));

	XSRETURN_EMPTY;
    }

void
loop_run(self)
    CODE:
    {
    	SV *self = ST(0);
	SV *sv_any;
#if LOOP_DEBUG
	warn("loop_run\n");
#endif
	if(MY_CXT.kq == -1)
    		croak("POE::Loop::Kqueue::loop_run: loop is not initialized!");

    	/*
	$self->loop_do_timeslice()
		while $self->_data_ses_count();
	*/
	ENTER;
	SAVETMPS;

    	DO_IT_AGAIN:

 	PUSHMARK(SP);
  	XPUSHs(self);
   	PUTBACK;

	(void)perl_call_sv(sv_method__data_ses_count, G_SCALAR|G_METHOD);
	SPAGAIN;

	sv_any = POPs;
	if(SvTRUE(sv_any))	{
		do_timeslice(aTHX_ self);
		goto DO_IT_AGAIN;
	}

	FREETMPS;
	LEAVE;

	XSRETURN_EMPTY;
    }

void
loop_halt(self)
    CODE:
    {
#if LOOP_DEBUG
	warn("loop_halt\n");
#endif
	/* reset timer */
	MY_CXT.next_time = 0;

	XSRETURN_EMPTY;
    }
