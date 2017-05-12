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

sigset_t* S_sv_to_sigset(pTHX_ SV* sigmask, const char* name) {
	if (!SvOK(sigmask))
		return NULL;
	if (!SvROK(sigmask) || !sv_derived_from(sigmask, "POSIX::SigSet"))
		Perl_croak(aTHX_ "%s is not of type POSIX::SigSet");
#if PERL_VERSION > 15 || PERL_VERSION == 15 && PERL_SUBVERSION > 2
	return (sigset_t *) SvPV_nolen(SvRV(sigmask));
#else
	IV tmp = SvIV((SV*)SvRV(sigmask));
	return INT2PTR(sigset_t*, tmp);
#endif
}
#define sv_to_sigset(sigmask, name) S_sv_to_sigset(aTHX_ sigmask, name)


sigset_t* S_get_sigset(pTHX_ SV* signal, const char* name) {
	if (SvROK(signal))
		return sv_to_sigset(signal, name);
	else {
		int signo = (SvIOK(signal) || looks_like_number(signal)) && SvIV(signal) ? SvIV(signal) : whichsig(SvPV_nolen(signal));
		SV* buffer = sv_2mortal(newSVpvn("", 0));
		sigset_t* ret;
		sv_grow(buffer, sizeof(sigset_t));
		ret = (sigset_t*)SvPV_nolen(buffer);
		sigemptyset(ret);
		sigaddset(ret, signo);
		return ret;
	}
}
#define get_sigset(sigmask, name) S_get_sigset(aTHX_ sigmask, name)

#define NANO_SECONDS 1000000000

static void nv_to_timespec(NV input, struct timespec* output) {
	output->tv_sec  = (time_t) floor(input);
	output->tv_nsec = (long) ((input - output->tv_sec) * NANO_SECONDS);
}

#define add_entry(name, value, type) hv_stores(ret, name, newSV##type(value))
#define add_simple(name) add_entry(#name, info.si_##name, iv)
#define undef &PL_sv_undef

MODULE = POSIX::RT::Signal				PACKAGE = POSIX::RT::Signal

IV
sigwait(set)
	SV* set;
	PREINIT:
		int val;
		int info;
	PPCODE:
		val = sigwait(get_sigset(set, "set"), &info);
		if (val == 0)
			mPUSHi(info);
		else if (GIMME_V == G_VOID && val != EAGAIN)
			die_sys("Couldn't sigwaitinfo: %s", val);
		/* Drop off returning nothing */

SV*
sigwaitinfo(set, timeout = undef)
	SV* set;
	SV* timeout;
	ALIAS:
		sigtimedwait = 0
	PREINIT:
		int val;
		siginfo_t info;
	PPCODE:
		if (SvOK(timeout)) {
			struct timespec timer;
			nv_to_timespec(SvNV(timeout), &timer);
			val = sigtimedwait(get_sigset(set, "set"), &info, &timer);
		}
		else {
			val = sigwaitinfo(get_sigset(set, "set"), &info);
		}
		if (val > 0) {
			HV* ret = newHV();
			add_simple(signo);
			add_simple(code);
			add_simple(errno);
			add_simple(pid);
			add_simple(uid);
			add_simple(status);
			add_simple(band);
#ifdef si_fd
			add_simple(fd);
#endif
			add_entry("value", info.si_value.sival_int, iv);
			add_entry("ptr", PTR2UV(info.si_value.sival_ptr), uv);
			add_entry("addr", PTR2UV(info.si_addr), uv);
			
			mPUSHs(newRV_noinc((SV*)ret));
		}
		else if (GIMME_V == G_VOID && errno != EAGAIN) {
			die_sys("Couldn't sigwaitinfo: %s", errno);
		}
		/* Drop off returning nothing */

void
sigqueue(pid, signal, number = 0)
	int pid;
	SV* signal;
	int number;
	PREINIT:
		int ret, signo;
		union sigval number_val;
	CODE:
		signo = (SvIOK(signal) || looks_like_number(signal)) && SvIV(signal) ? SvIV(signal) : whichsig(SvPV_nolen(signal));
		number_val.sival_int = number;
		ret = sigqueue(pid, signo, number_val);
		if (ret == 0)
			XSRETURN_YES;
		else
			die_sys("Couldn't sigqueue: %s", errno);

