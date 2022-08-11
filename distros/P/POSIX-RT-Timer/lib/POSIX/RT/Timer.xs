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
#ifdef CLOCK_REALTIME_COARSE
	, { STR_WITH_LEN("realtime_coarse"), CLOCK_REALTIME_COARSE }
#endif
#ifdef CLOCK_REALTIME_ALARM
	, { STR_WITH_LEN("realtime_alarm"), CLOCK_REALTIME_ALARM }
#endif
#ifdef CLOCK_MONOTONIC
	, { STR_WITH_LEN("monotonic"), CLOCK_MONOTONIC }
#elif defined CLOCK_HIGHRES
	, { STR_WITH_LEN("monotonic"), CLOCK_HIGHRES }
#endif
#ifdef CLOCK_MONOTONIC_RAW
	, { STR_WITH_LEN("monotonic_raw"), CLOCK_MONOTONIC_RAW }
#endif
#ifdef CLOCK_MONOTONIC_COARSE
	, { STR_WITH_LEN("monotonic_coarse"), CLOCK_MONOTONIC_COARSE }
#endif
#ifdef CLOCK_PROCESS_CPUTIME_ID
	, { STR_WITH_LEN("process"), CLOCK_PROCESS_CPUTIME_ID }
#elif defined CLOCK_PROF
	, { STR_WITH_LEN("process"), CLOCK_PROF }
#endif
#ifdef CLOCK_THREAD_CPUTIME_ID
	, { STR_WITH_LEN("thread"), CLOCK_THREAD_CPUTIME_ID }
#endif
#ifdef CLOCK_UPTIME
	, { STR_WITH_LEN("uptime"), CLOCK_UPTIME }
#endif
#ifdef CLOCK_BOOTTIME
	, { STR_WITH_LEN("boottime"), CLOCK_BOOTTIME }
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
	Perl_croak(aTHX_ "No such timer '%s' known", clock_name);
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

static int timer_destroy(pTHX_ SV* var, MAGIC* magic) {
	if (timer_delete(*(timer_t*)magic->mg_ptr))
		die_sys("Can't delete timer: %s");
}

static const MGVTBL timer_magic = { NULL, NULL, NULL, NULL, timer_destroy };

static MAGIC* S_get_magic(pTHX_ SV* ref, const char* funcname, const MGVTBL* vtbl) {
	SV* value;
	MAGIC* magic;
	if (!SvROK(ref) || !(value = SvRV(ref)) || !SvMAGICAL(value) || (magic = mg_findext(value, PERL_MAGIC_ext, vtbl)) == NULL)
		Perl_croak(aTHX_ "Could not %s: this variable is not a timer", funcname);
	return magic;
}
#define get_magic(ref, funcname, vtbl) S_get_magic(aTHX_ ref, funcname, vtbl)
#define get_timer(ref, funcname) (*(timer_t*)get_magic(ref, funcname, &timer_magic)->mg_ptr)

static clockid_t S_get_clock(pTHX_ SV* ref, const char* funcname) {
	SV* value;
	if (!SvROK(ref) || !(value = SvRV(ref)))
		Perl_croak(aTHX_ "Could not %s: this variable is not a clock", funcname);
	return SvUV(value);
}
#define get_clock(ref, func) S_get_clock(aTHX_ ref, func)

#if defined(SIGEV_THREAD_ID) && defined(SYS_gettid)
#include <sys/syscall.h>
#define gettid() syscall(SYS_gettid)
#ifndef sigev_notify_thread_id
#define sigev_notify_thread_id   _sigev_un._tid
#endif
#endif

static SV* S_create_clock(pTHX_ clockid_t clockid, SV* class) {
	SV *tmp, *retval;
	tmp = newSViv(clockid);
	retval = newRV_noinc(tmp);
	sv_bless(retval, gv_stashsv(class, 0));
	SvREADONLY_on(tmp);
	return retval;
}
#define create_clock(clockid, class) S_create_clock(aTHX_ clockid, class)

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

static void S_timer_args(pTHX_ timer_init* para, SV** begin, Size_t items) {
	int i;
	for(i = 0; i < items; i += 2) {
		const char* current;
		STRLEN curlen;
		SV *key = begin[i], *value = begin[i+1];
		current = SvPV(key, curlen);
		if (curlen == 5) {
			if (strEQ(current, "clock"))
				para->clockid = SvROK(value) ? get_clock(value, "create timer") : get_clockid(value);
			else if (strEQ(current, "value"))
				nv_to_timespec(SvNV(value), &para->itimer.it_value);
			else if (strEQ(current, "ident"))
				para->ident = SvIV(value);
			else
				goto fail;
		}
		else if (curlen == 6 && strEQ(current, "signal"))
			para->signo = (SvIOK(value) || looks_like_number(value)) ? SvIV(value) : whichsig(SvPV_nolen(value));
		else if (curlen == 8) {
			if (strEQ(current, "interval"))
				nv_to_timespec(SvNV(value), &para->itimer.it_interval);
			else if (strEQ(current, "absolute"))
				para->flags |= TIMER_ABSTIME;
			else
				goto fail;
		}
		else
			fail: Perl_croak(aTHX_ "Unknown option '%s'", current);
	}
}
#define timer_args(para, begin, items) S_timer_args(aTHX_ para, begin, items)

static SV* S_timer_instantiate(pTHX_ timer_init* para, const char* class, Size_t classlength) {
	timer_t* timer;
	struct sigevent event = { 0 };
	SV *tmp, *retval;
	MAGIC* mg;

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

	Newx(timer, 1, timer_t);

	if (timer_create(para->clockid, &event, timer) < 0) {
		Safefree(timer);
		die_sys("Couldn't create timer: %s");
	}
	if (timer_settime(*timer, para->flags, &para->itimer, NULL) < 0)
		die_sys("Couldn't set_time: %s");

	tmp = newSV(0);
	retval = sv_2mortal(sv_bless(newRV_noinc(tmp), gv_stashpvn(class, classlength, 0)));
	SvREADONLY_on(tmp);

	mg = sv_magicext(tmp, NULL, PERL_MAGIC_ext, &timer_magic, (const char*)timer, 0);
	mg->mg_len = sizeof *timer;
	return retval;
}
#define timer_instantiate(para, class, classlen) S_timer_instantiate(aTHX_ para, class, classlen)

MODULE = POSIX::RT::Timer				PACKAGE = POSIX::RT::Timer

PROTOTYPES: DISABLED

void new(class, ...)
	SV* class;
	PREINIT:
		const char* class_str;
		Size_t length;
	PPCODE:
		class_str = SvPV(class, length);
		timer_init para = { CLOCK_REALTIME, 0, 0, 0, 0};
		timer_args(&para, SP + 2, items - 1);
		PUSHs(timer_instantiate(&para, class_str, length));

UV
handle(self)
	SV* self;
	CODE:
		RETVAL = (UV)get_timer(self, "id");
	OUTPUT:
		RETVAL

void
get_timeout(self)
	SV* self;
	PREINIT:
		timer_t timer;
		struct itimerspec value;
	PPCODE:
		timer = get_timer(self, "get_timeout");
		if (timer_gettime(timer, &value) == -1)
			die_sys("Couldn't get_time: %s");
		mXPUSHn(timespec_to_nv(&value.it_value));
		if (GIMME_V == G_ARRAY)
			mXPUSHn(timespec_to_nv(&value.it_interval));

void
set_timeout(self, new_value, new_interval = 0, abstime = 0)
	SV* self;
	NV new_value;
	NV new_interval;
	IV abstime;
	PREINIT:
		timer_t timer;
		struct itimerspec new_itimer, old_itimer;
	PPCODE:
		timer = get_timer(self, "set_timeout");
		nv_to_timespec(new_value, &new_itimer.it_value);
		nv_to_timespec(new_interval, &new_itimer.it_interval);
		if (timer_settime(timer, (abstime ? TIMER_ABSTIME : 0), &new_itimer, &old_itimer) == -1)
			die_sys("Couldn't set_time: %s");
		mXPUSHn(timespec_to_nv(&old_itimer.it_value));
		if (GIMME_V == G_ARRAY)
			mXPUSHn(timespec_to_nv(&old_itimer.it_interval));

IV
get_overrun(self)
	SV* self;
	PREINIT:
		timer_t timer;
	CODE:
		timer = get_timer(self, "get_overrun");
		RETVAL = timer_getoverrun(timer);
		if (RETVAL == -1) 
			die_sys("Couldn't get_overrun: %s");
	OUTPUT:
		RETVAL

MODULE = POSIX::RT::Timer				PACKAGE = POSIX::RT::Clock

PROTOTYPES: DISABLED

SV*
new(class, ...)
	SV* class;
	PREINIT:
		clockid_t clockid;
	CODE:
		clockid = items > 1 ? get_clockid(ST(1)) : CLOCK_REALTIME;
		RETVAL = create_clock(clockid, class);
	OUTPUT:
		RETVAL

UV
handle(self)
	SV* self;
	CODE:
		RETVAL = (UV)get_clock(self, "id");
	OUTPUT:
		RETVAL

#if defined(_POSIX_CPUTIME) && _POSIX_CPUTIME >= 0
SV*
get_cpuclock(class, pid = undef)
	SV* class;
	SV* pid;
	PREINIT:
		clockid_t clockid;
	CODE:
		if (SvOK(pid) && SvROK(pid) && sv_derived_from(pid, "threads")) {
#if defined(USE_ITHREADS) && defined(_POSIX_THREAD_CPUTIME) && _POSIX_THREAD_CPUTIME >= 0
			pthread_t* handle = get_pthread(pid);
			if (pthread_getcpuclockid(*handle, &clockid) != 0)
				die_sys("Could not get cpuclock");
#else
			Perl_croak(aTHX_ "Can't get CPU time for threads");
#endif
		}
		else {
			if (clock_getcpuclockid(SvOK(pid) ? SvIV(pid) : 0, &clockid) != 0)
				die_sys("Could not get cpuclock");
		}
		
		RETVAL = create_clock(clockid, class);
	OUTPUT:
		RETVAL

#endif

void
get_clocks(class)
	SV* class;
	PREINIT:
		size_t i;
		const size_t max = sizeof clocks / sizeof *clocks;
	PPCODE:
		for (i = 0; i < max; ++i)
			mXPUSHp(clocks[i].key, clocks[i].key_length);
		XSRETURN(max);

NV
get_time(self)
	SV* self;
	PREINIT:
		clockid_t clockid;
		struct timespec time;
	CODE:
		clockid = get_clock(self, "get_time");
		if (clock_gettime(clockid, &time) == -1)
			die_sys("Couldn't get time: %s");
		RETVAL = timespec_to_nv(&time);
	OUTPUT:
		RETVAL

void
set_time(self, frac_time)
	SV* self;
	NV frac_time;
	PREINIT:
		clockid_t clockid;
		struct timespec time;
	CODE:
		clockid = get_clock(self, "set_time");
		nv_to_timespec(frac_time, &time);
		if (clock_settime(clockid, &time) == -1)
			die_sys("Couldn't set time: %s");

NV
get_resolution(self)
	SV* self;
	PREINIT:
		clockid_t clockid;
		struct timespec time;
	CODE:
		clockid = get_clock(self, "get_resolution");
		if (clock_getres(clockid, &time) == -1)
			die_sys("Couldn't get resolution: %s");
		RETVAL = timespec_to_nv(&time);
	OUTPUT:
		RETVAL

void
timer(self, ...)
	SV* self;
	PPCODE:
		timer_init para = { CLOCK_REALTIME, 0, 0, 0, 0};
		timer_args(&para, SP + 2, items - 1);
		para.clockid = get_clock(self, "timer");
		PUSHs(timer_instantiate(&para, "POSIX::RT::Timer", 16));

#if defined(_POSIX_CLOCK_SELECTION) && _POSIX_CLOCK_SELECTION >= 0
NV
sleep(self, frac_time, abstime = 0)
	SV* self;
	NV frac_time;
	int abstime;
	PREINIT:
		clockid_t clockid;
		struct timespec sleep_time, remain_time;
		int flags;
	CODE:
		clockid = get_clock(self, "sleep");
		flags = abstime ? TIMER_ABSTIME : 0;
		nv_to_timespec(frac_time, &sleep_time);

		if (clock_nanosleep(clockid, flags, &sleep_time, &remain_time) == EINTR)
			RETVAL = abstime ? frac_time : timespec_to_nv(&remain_time);
		else 
			RETVAL = 0;
	OUTPUT:
		RETVAL

NV
sleep_deeply(self, frac_time, abstime = 0)
	SV* self;
	NV frac_time;
	int abstime;
	PREINIT:
		clockid_t clockid;
		struct timespec sleep_time;
		NV real_time;
	CODE:
		clockid = get_clock(self, "sleep_deeply");
		if (abstime)
			nv_to_timespec(frac_time, &sleep_time);
		else {
			if (clock_gettime(clockid, &sleep_time) == -1)
				die_sys("Couldn't get time: %s");
			nv_to_timespec(timespec_to_nv(&sleep_time) + frac_time, &sleep_time);
		}
		while (clock_nanosleep(clockid, TIMER_ABSTIME, &sleep_time, NULL) == EINTR);
		RETVAL = 0;
	OUTPUT:
		RETVAL

#endif
