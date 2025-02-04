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
		siginfo_t info;
	CODE:
		val = sigwaitinfo(set, &info);

		if (val < 0)
			XSRETURN_UNDEF;
		RETVAL = &info;
	OUTPUT:
		RETVAL

Signal::Info sigtimedwait(sigset_t* set, struct timespec timeout)
	PREINIT:
		int val;
		siginfo_t info;
	CODE:
		val = sigtimedwait(set, &info, &timeout);

		if (val < 0)
			XSRETURN_UNDEF;
		RETVAL = &info;
	OUTPUT:
		RETVAL

bool sigqueue(int pid, signo_t signo, int number = 0)
	PREINIT:
		int ret;
		union sigval number_val;
	CODE:
		number_val.sival_int = number;
		ret = sigqueue(pid, signo, number_val);
		RETVAL = ret == 0;
	OUTPUT:
		RETVAL

