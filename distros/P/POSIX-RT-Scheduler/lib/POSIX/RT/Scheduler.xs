#if defined linux
#	ifndef _GNU_SOURCE
#		define _GNU_SOURCE
#	endif
#	define GNU_STRERROR_R
#endif

#include <sched.h>

#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

static void get_sys_error(char* buffer, size_t buffer_size) {
#ifdef _GNU_SOURCE
	const char* message = strerror_r(errno, buffer, buffer_size);
	if (message != buffer) {
		memcpy(buffer, message, buffer_size -1);
		buffer[buffer_size] = '\0';
	}
#else
	strerror_r(errno, buffer, buffer_size);
#endif
}

static void S_die_sys(pTHX_ const char* format) {
	char buffer[128];
	get_sys_error(buffer, sizeof buffer);
	Perl_croak(aTHX_ format, buffer);
}
#define die_sys(format) S_die_sys(aTHX_ format)

#define add_entry(name, value) STMT_START { \
	hv_stores(scheds, name, newSViv(value)); \
	av_store(names, value, newSVpvs(name));\
	} STMT_END

#define identifiers_key "POSIX::RT::Scheduler::identifiers"
#define names_key "POSIX::RT::Scheduler::names"

static int S_get_policy(pTHX_ SV* name) {
	HV* policies = (HV*)*hv_fetchs(PL_modglobal, names_key, 0);
	HE* ret = hv_fetch_ent(policies, name, 0, 0);
	if (ret == NULL)
		Perl_croak(aTHX_ "");
	return SvIV(HeVAL(ret));
}
#define get_policy(name) S_get_policy(aTHX_ name)
static SV* S_get_name(pTHX_ int policy) {
	AV* names = (AV*)*hv_fetchs(PL_modglobal, names_key, 0);
	SV** ret = av_fetch(names, policy, 0);
	if (ret == NULL || *ret == NULL)
		Perl_croak(aTHX_ "");
	return *ret;
}
#define get_name(policy) S_get_name(aTHX_ policy)

#if defined(USE_ITHREADS) && defined(_POSIX_THREAD_PRIORITY_SCHEDULING) && _POSIX_THREAD_PRIORITY_SCHEDULING >= 0
#define THREAD_SCHED
static pthread_t* S_get_pthread(pTHX_ SV* thread_handle) {
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
	return ret;
}
#define get_pthread(handle) S_get_pthread(aTHX_ handle)
#endif

MODULE = POSIX::RT::Scheduler				PACKAGE = POSIX::RT::Scheduler

BOOT: 
	{
		HV* scheds = newHV();
		AV* names = newAV();
		add_entry("other", SCHED_OTHER);
#ifdef SCHED_BATCH
		add_entry("batch", SCHED_BATCH);
#endif
#ifdef SCHED_IDLE
		add_entry("idle", SCHED_IDLE);
#endif
#ifdef SCHED_FIFO
		add_entry("fifo", SCHED_FIFO);
#endif
#ifdef SCHED_RR
		add_entry("rr", SCHED_RR);
#endif
		hv_stores(PL_modglobal, identifiers_key, (SV*)scheds);
		hv_stores(PL_modglobal, names_key, (SV*)names);
	}


SV*
sched_getscheduler(pid)
	SV* pid;
	PREINIT:
		int ret;
		HV* scheds;
	CODE:
		ret = sched_getscheduler(SvIV(pid));
		if (ret == -1) 
			die_sys("Couldn't get scheduler: %s");
	RETVAL = get_name(ret);
	OUTPUT:
		RETVAL

SV*
sched_setscheduler(pid, policy, arg = 0)
	SV* pid;
	SV* policy;
	int arg;
	PREINIT:
		int ret, real_policy;
		struct sched_param param;
	CODE:
		real_policy = get_policy(policy);
		param.sched_priority = arg;
#ifdef THREAD_SCHED
		if (SvOK(pid) && SvROK(pid) && sv_derived_from(pid, "threads"))
			ret = pthread_setschedparam(*get_pthread(pid), real_policy, &param);
		else
#endif
			ret = sched_setscheduler(SvIV(pid), real_policy, &param);
		if (ret == -1)
			die_sys("Could not set scheduler: %s");
	else if (SvROK(pid))
	if (ret == -1) 
		die_sys("Couldn't set scheduler: %s");
	RETVAL = 
#ifdef linux
		(ret == 0) ? sv_2mortal(newSVpvs("0 but true")) : 
#endif
		get_name(ret);
	OUTPUT:
		RETVAL

IV
sched_getpriority(pid)
	int pid;
	PREINIT:
		struct sched_param param;
	CODE:
		{
			sched_getparam(pid, &param);
			RETVAL = param.sched_priority;
		}
	OUTPUT:
		RETVAL

void
sched_setpriority(pid, priority)
	SV* pid;
	int priority;
	PREINIT:
		int ret;
		struct sched_param param;
	CODE:
		param.sched_priority = priority;
		if (!SvOK(pid))
			Perl_croak(aTHX_ "pid is undefined");
#ifdef THREAD_SCHED
		if (SvROK(pid) && sv_derived_from(pid, "threads"))
			ret = pthread_setschedprio(*get_pthread(pid), priority);
		else
#endif
			ret = sched_setparam(SvIV(pid), &param);
		if (ret == -1) 
			die_sys("Couldn't set scheduler priority: %s");

void
sched_priority_range(policy)
	SV* policy;
	PREINIT:
		int real_policy;
	PPCODE:
	real_policy = get_policy(policy);
	mXPUSHi(sched_get_priority_min(real_policy));
	mXPUSHi(sched_get_priority_max(real_policy));
	PUTBACK;

void
sched_yield()
	CODE:
	sched_yield();
