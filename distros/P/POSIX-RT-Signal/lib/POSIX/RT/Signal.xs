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

static void S_die_sys(pTHX_ const char* format, int errnum) {
	char buffer[128];
	get_sys_error(buffer, sizeof buffer, errnum);
	Perl_croak(aTHX_ format, buffer);
}
#define die_sys(format, errnum) S_die_sys(aTHX_ format, errnum)

#define undef &PL_sv_undef

typedef int signo_t;

MODULE = POSIX::RT::Signal				PACKAGE = POSIX::RT::Signal

int sigwait(sigset_t* sigset)
	PREINIT:
		int val;
	CODE:
		val = sigwait(sigset, &RETVAL);
		if (val != 0 && GIMME_V == G_VOID && val != EAGAIN)
			die_sys("Couldn't sigwaitinfo: %s", val);
	OUTPUT:
		RETVAL

siginfo_t sigwaitinfo(sigset_t* set)
	ALIAS:
		sigtimedwait = 0
	PREINIT:
		int val;
		siginfo_t info;
	CODE:
		val = sigwaitinfo(set, &RETVAL);

		if (val <= 0) {
			if (GIMME_V == G_VOID && errno != EAGAIN)
				die_sys("Couldn't sigwaitinfo: %s", errno);
			else
				XSRETURN_UNDEF;
		}
	OUTPUT:
		RETVAL

siginfo_t sigtimedwait(sigset_t* set, struct timespec timeout)
	ALIAS:
		sigtimedwait = 0
	PREINIT:
		int val;
		siginfo_t info;
	CODE:
		val = sigtimedwait(set, &RETVAL, &timeout);

		if (val <= 0) {
			if (GIMME_V == G_VOID && errno != EAGAIN)
				die_sys("Couldn't sigwaitinfo: %s", errno);
			else
				XSRETURN_UNDEF;
		}
	OUTPUT:
		RETVAL

bool sigqueue(int pid, signo_t signo, int number = 0)
	PREINIT:
		int ret;
		union sigval number_val;
	CODE:
		number_val.sival_int = number;
		ret = sigqueue(pid, signo, number_val);
		if (ret == 0)
			RETVAL = TRUE;
		else
			die_sys("Couldn't sigqueue: %s", errno);
	OUTPUT:
		RETVAL

