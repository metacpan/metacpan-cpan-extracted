#define _POSIX_PTHREAD_SEMANTICS
#include <signal.h>

#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#define NEED_newRV_noinc
#define NEED_sv_2pv_flags
#include "ppport.h"

static void get_sys_error(char* buffer, size_t buffer_size, int errnum) {
#ifdef HAS_STRERROR_R
#	if STRERROR_R_PROTO == REENTRANT_PROTO_B_IBW
	const char* message = strerror_r(errno, buffer, buffer_size);
	if (message != buffer)
		memcpy(buffer, message, buffer_size);
#	else
	strerror_r(errno, buffer, buffer_size);
#	endif
#else
	const char* message = strerror(errno);
	strncpy(buffer, message, buffer_size - 1);
	buffer[buffer_size - 1] = '\0';
#endif
}

#if defined(USE_ITHREADS) && (defined(__linux) || defined(__FreeBSD__))
#define THREAD_SCHED
static pthread_t S_get_pthread(pTHX_ SV* thread_handle) {
	SV* tmp;
	pthread_t* ret;
	dSP;
	PUSHMARK(SP);
	PUSHs(thread_handle);
	PUTBACK;
	call_method("_handle", G_SCALAR);
	SPAGAIN;
	tmp = POPs;
	ret = INT2PTR(pthread_t* ,SvUV(tmp));
	return *ret;
}
#define get_pthread(handle) S_get_pthread(aTHX_ handle)
#endif

#define undef &PL_sv_undef

typedef int signo_t;
typedef siginfo_t* Signal__Info;

MODULE = POSIX::RT::Signal				PACKAGE = POSIX::RT::Signal

int sigwait(sigset_t* sigset)
	PREINIT:
		int val;
	CODE:
		val = sigwait(sigset, &RETVAL);
		if (val != 0)
			XSRETURN_UNDEF;
	OUTPUT:
		RETVAL

Signal::Info sigwaitinfo(sigset_t* set)
	PREINIT:
		int val;
	CODE:
		RETVAL = safecalloc(1, sizeof(siginfo_t));
		val = sigwaitinfo(set, RETVAL);

		if (val < 0) {
			Safefree(RETVAL);
			XSRETURN_UNDEF;
		}
	OUTPUT:
		RETVAL

Signal::Info sigtimedwait(sigset_t* set, struct timespec timeout)
	PREINIT:
		int val;
	CODE:
		RETVAL = safecalloc(1, sizeof(siginfo_t));
		val = sigtimedwait(set, RETVAL, &timeout);

		if (val < 0) {
			Safefree(RETVAL);
			XSRETURN_UNDEF;
		}
	OUTPUT:
		RETVAL

bool sigqueue(SV* pid, signo_t signo, int number = 0)
	PREINIT:
		int ret;
		union sigval number_val;
	CODE:
		number_val.sival_int = number;
#ifdef THREAD_SCHED
		if (SvOK(pid) && SvROK(pid) && sv_derived_from(pid, "threads"))
			ret = pthread_sigqueue(get_pthread(pid), signo, number_val);
		else
#endif
			ret = sigqueue(SvIV(pid), signo, number_val);
		RETVAL = ret == 0;
	OUTPUT:
		RETVAL

