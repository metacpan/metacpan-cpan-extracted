/*
 * This software is copyright (c) 2010 by Leon Timmermans <leont@cpan.org>.
 *
 * This is free software; you can redistribute it and/or modify it under
 * the same terms as perl itself.
 *
 */

#define PERL_NO_GET_CONTEXT
#define PERL_REENTR_API 1

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#define NEED_mg_findext
#include "ppport.h"

#include <signal.h>
#include <time.h>

#define die_sys(format) Perl_croak(aTHX_ format, strerror(errno))

typedef struct { const char* key; STRLEN key_length; clockid_t value; } map[];

static map clocks = {
	{ STR_WITH_LEN("realtime") , CLOCK_REALTIME  }
#ifdef CLOCK_MONOTONIC
	, { STR_WITH_LEN("monotonic"), CLOCK_MONOTONIC }
#endif
#ifdef CLOCK_PROCESS_CPUTIME_ID
	, { STR_WITH_LEN("process"), CLOCK_PROCESS_CPUTIME_ID }
#endif
#ifdef CLOCK_THREAD_CPUTIME_ID
	, { STR_WITH_LEN("thread"), CLOCK_THREAD_CPUTIME_ID }
#endif
#ifdef CLOCK_BOOTTIME
	, { STR_WITH_LEN("boottime"), CLOCK_BOOTTIME }
#endif

#ifdef CLOCK_REALTIME_COARSE
	, { STR_WITH_LEN("realtime_coarse"), CLOCK_REALTIME_COARSE }
#endif
#ifdef CLOCK_REALTIME_ALARM
	, { STR_WITH_LEN("realtime_alarm"), CLOCK_REALTIME_ALARM }
#endif
#ifdef CLOCK_REALTIME_PRECISE
	, { STR_WITH_LEN("realtime_precise"), CLOCK_REALTIME_PRECISE }
#endif
#if defined CLOCK_HIGHRES
	, { STR_WITH_LEN("highres"), CLOCK_HIGHRES }
#endif
#ifdef CLOCK_MONOTONIC_RAW
	, { STR_WITH_LEN("monotonic_raw"), CLOCK_MONOTONIC_RAW }
#endif
#ifdef CLOCK_MONOTONIC_COARSE
	, { STR_WITH_LEN("monotonic_coarse"), CLOCK_MONOTONIC_COARSE }
#endif
#ifdef CLOCK_MONOTONIC_PRECISE
	, { STR_WITH_LEN("monotonic_precise"), CLOCK_MONOTONIC_PRECISE }
#endif
#if defined CLOCK_PROF
	, { STR_WITH_LEN("prof"), CLOCK_PROF }
#endif
#ifdef CLOCK_UPTIME
	, { STR_WITH_LEN("uptime"), CLOCK_UPTIME }
#endif
#ifdef CLOCK_UPTIME_PRECISE
	, { STR_WITH_LEN("uptime_precise"), CLOCK_UPTIME_PRECISE }
#endif
#ifdef CLOCK_UPTIME_FAST
	, { STR_WITH_LEN("uptime_fast"), CLOCK_UPTIME_FAST }
#endif
#ifdef CLOCK_BOOTTIME_ALARM
	, { STR_WITH_LEN("boottime_alarm"), CLOCK_BOOTTIME_ALARM }
#endif
#ifdef CLOCK_VIRTUAL
	, { STR_WITH_LEN("virtual"), CLOCK_VIRTUAL }
#endif
#ifdef CLOCK_TAI
	, { STR_WITH_LEN("tai"), CLOCK_TAI }
#endif
};

static clockid_t S_get_clockid(pTHX_ SV* clock_name) {
	int i;
	STRLEN length;
	const char* clock_ptr = SvPV(clock_name, length);
	for (i = 0; i < sizeof clocks / sizeof *clocks; ++i) {
		if (clocks[i].key_length == length && strEQ(clock_ptr, clocks[i].key))
			return clocks[i].value;
	}
	Perl_croak(aTHX_ "No such timer '%s' known", SvPV_nolen(clock_name));
}
#define get_clockid(name) S_get_clockid(aTHX_ name)

#define NANO_SECONDS 1000000000

static NV timespec_to_nv(struct timespec* time) {
	return time->tv_sec + time->tv_nsec / (double)NANO_SECONDS;
}

static void nv_to_timespec(NV input, struct timespec* output) {
	output->tv_sec  = (time_t) floor(input);
	output->tv_nsec = (long) ((input - output->tv_sec) * NANO_SECONDS);
}

#if defined(SIGEV_THREAD_ID) && defined(SYS_gettid)
#include <sys/syscall.h>
#define gettid() syscall(SYS_gettid)
#ifndef sigev_notify_thread_id
#define sigev_notify_thread_id   _sigev_un._tid
#endif
#endif

#if defined(_POSIX_CLOCK_SELECTION) && _POSIX_CLOCK_SELECTION >= 0
static int my_clock_nanosleep(pTHX_ clockid_t clockid, int flags, const struct timespec* request, struct timespec* remain) {
	int ret;
	ret = clock_nanosleep(clockid, flags, request, remain);
	if (ret != 0) {
		errno = ret;
		if (ret != EINTR)
			die_sys("Could not sleep: %s");
	}
	return ret;
}
#endif

#define clock_nanosleep(clockid, flags, request, remain) my_clock_nanosleep(aTHX_ clockid, flags, request, remain)

#if defined(USE_ITHREADS) && defined(_POSIX_THREAD_CPUTIME) && _POSIX_THREAD_CPUTIME >= 0
static pthread_t* S_get_pthread(pTHX_ SV* thread_handle) {
	SV* tmp;
	pthread_t* ret;
	dSP;
	ENTER;
	SAVETMPS;
	PUSHMARK(SP);
	PUSHs(thread_handle);
	PUTBACK;
	call_method("_handle", G_SCALAR);
	SPAGAIN;
	tmp = POPs;
	ret = INT2PTR(pthread_t* ,SvUV(tmp));
	FREETMPS;
	LEAVE;
	return ret;
}
#define get_pthread(handle) S_get_pthread(aTHX_ handle)
#endif

#define undef &PL_sv_undef

typedef struct _timer_init {
	clockid_t clockid;
	IV signo;
	IV ident;
	struct itimerspec itimer;
	int flags;
} timer_init;

static void S_timer_init_gather(pTHX_ timer_init* result, SV** begin, size_t items) {
	int i;
	Zero(result, 1, timer_init);
	result->clockid = CLOCK_REALTIME;
	for(i = 0; i < items; i += 2) {
		const char* current;
		STRLEN curlen;
		SV *key = begin[i], *value = begin[i+1];
		current = SvPV(key, curlen);
		if (curlen == 5) {
			if (strEQ(current, "clock"))
				result->clockid = SvROK(value) ? SvUV(SvRV(value)) : get_clockid(value);
			else if (strEQ(current, "value"))
				nv_to_timespec(SvNV(value), &result->itimer.it_value);
			else if (strEQ(current, "ident"))
				result->ident = SvIV(value);
			else
				goto fail;
		}
		else if (curlen == 6 && strEQ(current, "signal"))
			result->signo = (SvIOK(value) || looks_like_number(value)) ? SvIV(value) : whichsig(SvPV_nolen(value));
		else if (curlen == 8) {
			if (strEQ(current, "interval"))
				nv_to_timespec(SvNV(value), &result->itimer.it_interval);
			else if (strEQ(current, "absolute"))
				result->flags |= TIMER_ABSTIME;
			else
				goto fail;
		}
		else
			fail: Perl_croak(aTHX_ "Unknown option '%s'", current);
	}
}
#define timer_init_gather(init, begin, items) S_timer_init_gather(aTHX_ init, begin, items)

static timer_t S_timer_new(pTHX_ timer_init* para) {
	timer_t timer;
	struct sigevent event = { 0 };

	if (para->signo < 0)
		Perl_croak(aTHX_ "No valid signal was given");

#ifdef gettid
	event.sigev_notify           = SIGEV_THREAD_ID;
	event.sigev_notify_thread_id = gettid();
#else
	event.sigev_notify           = SIGEV_SIGNAL;
#endif
	event.sigev_signo            = para->signo;
	event.sigev_value.sival_int  = para->ident;

	if (timer_create(para->clockid, &event, &timer) < 0)
		die_sys("Couldn't create timer: %s");
	if (timer_settime(timer, para->flags, &para->itimer, NULL) < 0)
		die_sys("Couldn't set_time: %s");

	return timer;
}
#define timer_new(para) S_timer_new(aTHX_ para)

void timespec_add(struct timespec* left, const struct timespec* right) {
	left->tv_sec += right->tv_sec;
	left->tv_nsec += right->tv_nsec;
	while (left->tv_nsec > 1000000000) {
		left->tv_nsec -= 1000000000;
		left->tv_sec++;
	}
}

static const struct timespec no_time = { 0, 0 };

typedef timer_t POSIX__RT__Timer;
typedef clockid_t POSIX__RT__Clock;

#define XS_unpack_clockid_t(sv) get_clockid(sv)

MODULE = POSIX::RT::Timer  PACKAGE = POSIX::RT::Timer

PROTOTYPES: DISABLED

POSIX::RT::Timer new(SV* class, timer_init args, ...)
	CODE:
		RETVAL = timer_new(&args);
	OUTPUT:
		RETVAL

UV handle(POSIX::RT::Timer timer)
	CODE:
		RETVAL = (UV)timer;
	OUTPUT:
		RETVAL

void get_timeout(POSIX::RT::Timer timer)
	PREINIT:
		struct itimerspec value;
	PPCODE:
		if (timer_gettime(timer, &value) == -1)
			die_sys("Couldn't get_time: %s");
		mXPUSHn(timespec_to_nv(&value.it_value));
		if (GIMME_V == G_ARRAY)
			mXPUSHn(timespec_to_nv(&value.it_interval));

void set_timeout(POSIX::RT::Timer timer, struct timespec new_value, struct timespec new_interval = no_time, bool abstime = FALSE)
	PREINIT:
		struct itimerspec old_itimer;
	PPCODE:
		struct itimerspec new_itimer = { new_value, new_interval };
		if (timer_settime(timer, (abstime ? TIMER_ABSTIME : 0), &new_itimer, &old_itimer) == -1)
			die_sys("Couldn't set_time: %s");
		mXPUSHn(timespec_to_nv(&old_itimer.it_value));
		if (GIMME_V == G_ARRAY)
			mXPUSHn(timespec_to_nv(&old_itimer.it_interval));

IV get_overrun(POSIX::RT::Timer timer)
	CODE:
		RETVAL = timer_getoverrun(timer);
		if (RETVAL == -1) 
			die_sys("Couldn't get_overrun: %s");
	OUTPUT:
		RETVAL

void DESTROY(POSIX::RT::Timer timer)
	CODE:
		timer_delete(timer);

MODULE = POSIX::RT::Timer				PACKAGE = POSIX::RT::Clock

PROTOTYPES: DISABLED

POSIX::RT::Clock new(SV* class, clockid_t clockid = CLOCK_REALTIME)
	CODE:
		RETVAL = clockid;
	OUTPUT:
		RETVAL

UV handle(POSIX::RT::Clock clock)
	CODE:
		RETVAL = (UV)clock;
	OUTPUT:
		RETVAL

#if defined(_POSIX_CPUTIME) && _POSIX_CPUTIME >= 0
POSIX::RT::Clock get_cpuclock(SV* class, SV* pid = undef)
	CODE:
		if (SvOK(pid) && SvROK(pid) && sv_derived_from(pid, "threads")) {
#if defined(USE_ITHREADS) && defined(_POSIX_THREAD_CPUTIME) && _POSIX_THREAD_CPUTIME >= 0
			pthread_t* handle = get_pthread(pid);
			if (pthread_getcpuclockid(*handle, &RETVAL) != 0)
				die_sys("Could not get cpuclock: %s");
#else
			Perl_croak(aTHX_ "Can't get CPU time for threads");
#endif
		}
		else {
			if (clock_getcpuclockid(SvOK(pid) ? SvIV(pid) : 0, &RETVAL) != 0)
				die_sys("Could not get cpuclock: %s");
		}
	OUTPUT:
		RETVAL

#endif

void get_clocks(...)
	PREINIT:
		size_t i;
		const size_t max = sizeof clocks / sizeof *clocks;
	PPCODE:
		for (i = 0; i < max; ++i)
			mXPUSHp(clocks[i].key, clocks[i].key_length);
		PUTBACK;

struct timespec get_time(POSIX::RT::Clock clockid)
	CODE:
		if (clock_gettime(clockid, &RETVAL) == -1)
			die_sys("Couldn't get time: %s");
	OUTPUT:
		RETVAL

void set_time(POSIX::RT::Clock clockid, struct timespec time)
	CODE:
		if (clock_settime(clockid, &time) == -1)
			die_sys("Couldn't set time: %s");

struct timespec get_resolution(POSIX::RT::Clock clockid)
	CODE:
		if (clock_getres(clockid, &RETVAL) == -1)
			die_sys("Couldn't get resolution: %s");
	OUTPUT:
		RETVAL

POSIX::RT::Timer timer(POSIX::RT::Clock clockid, timer_init args, ...)
	CODE:
		args.clockid = clockid;
		RETVAL = timer_new(&args);
	OUTPUT:
		RETVAL

#if defined(_POSIX_CLOCK_SELECTION) && _POSIX_CLOCK_SELECTION >= 0
struct timespec sleep(POSIX::RT::Clock clockid, struct timespec time, bool abstime = FALSE)
	PREINIT:
		struct timespec remain_time;
		int flags;
	CODE:
		flags = abstime ? TIMER_ABSTIME : 0;

		if (clock_nanosleep(clockid, flags, &time, &remain_time) == EINTR)
			RETVAL = abstime ? time : remain_time;
		else 
			RETVAL = no_time;
	OUTPUT:
		RETVAL

NV sleep_deeply(POSIX::RT::Clock clockid, struct timespec time, bool abstime = FALSE)
	PREINIT:
	CODE:
		if (!abstime) {
			struct timespec current_time;
			if (clock_gettime(clockid, &current_time) == -1)
				die_sys("Couldn't get time: %s");
			timespec_add(&time, &current_time);
		}
		while (clock_nanosleep(clockid, TIMER_ABSTIME, &time, NULL) == EINTR);
		RETVAL = 0;
	OUTPUT:
		RETVAL

#endif
