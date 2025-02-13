#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

typedef siginfo_t* Signal__Info;

#define siginfo_signo(self) (self)->si_signo
#define siginfo_code(self) (self)->si_code
#define siginfo_errno(self) (self)->si_errno
#define siginfo_pid(self) (self)->si_pid
#define siginfo_uid(self) (self)->si_uid
#define siginfo_status(self) (self)->si_status
#define siginfo_band(self) (self)->si_band
#define siginfo_fd(self) (self)->si_fd
#define siginfo_timerid(self) (self)->si_timerid
#define siginfo_overrun(self) (self)->si_overrun

#define siginfo_addr(self) PTR2UV((self)->si_addr)

#define siginfo_value(self) (self)->si_value.sival_int
#define siginfo_ptr(self) PTR2UV((self)->si_value.sival_ptr)

#define timespec_new(class, value) &(value)
#define timespec_sec(self) (self)->tv_sec
#define timespec_nsec(self) (self)->tv_nsec
#define timespec_to_float(self) (self)->tv_sec + ((self)->tv_nsec / (double)1000000000)

#define CONSTANT(cons) newCONSTSUB(stash, #cons, newSVuv(cons)); av_push(export_ok, newSVpvs(#cons))

MODULE = Signal::Info    PACKAGE = Signal::Info    PREFIX = siginfo_

PROTOTYPES: DISABLED

Signal::Info new(class)
CODE:
	siginfo_t temp;
	RETVAL = &temp;
OUTPUT:
	RETVAL

IV siginfo_signo(Signal::Info self)

IV siginfo_code(Signal::Info self)

IV siginfo_errno(Signal::Info self)

IV siginfo_pid(Signal::Info self)

IV siginfo_uid(Signal::Info self)

IV siginfo_status(Signal::Info self)

IV siginfo_band(Signal::Info self)

IV siginfo_value(Signal::Info self)

UV siginfo_ptr(Signal::Info self)

UV siginfo_addr(Signal::Info self)

#ifdef si_fd
IV siginfo_fd(Signal::Info self)

#endif

#ifdef si_timerid
IV siginfo_timerid(Signal::Info self)

#endif

#ifdef si_overrun
IV siginfo_overrun(Signal::Info self)

#endif

BOOT:
	HV* stash = get_hv("Signal::Info::", FALSE);
	AV* export_ok = get_av("Signal::Info::EXPORT_OK", TRUE);

	CONSTANT(ILL_ILLOPC);
	CONSTANT(ILL_ILLOPN);
	CONSTANT(ILL_ILLADR);
	CONSTANT(ILL_ILLTRP);
	CONSTANT(ILL_PRVOPC);
	CONSTANT(ILL_PRVREG);
	CONSTANT(ILL_COPROC);
	CONSTANT(ILL_BADSTK);
	CONSTANT(FPE_INTDIV);
	CONSTANT(FPE_INTOVF);
	CONSTANT(FPE_FLTDIV);
	CONSTANT(FPE_FLTOVF);
	CONSTANT(FPE_FLTUND);
	CONSTANT(FPE_FLTRES);
	CONSTANT(FPE_FLTINV);
	CONSTANT(FPE_FLTSUB);
	CONSTANT(SEGV_MAPERR);
	CONSTANT(SEGV_ACCERR);
	CONSTANT(BUS_ADRALN);
	CONSTANT(BUS_ADRERR);
	CONSTANT(BUS_OBJERR);
	CONSTANT(TRAP_BRKPT);
	CONSTANT(TRAP_TRACE);
	CONSTANT(CLD_EXITED);
	CONSTANT(CLD_KILLED);
	CONSTANT(CLD_DUMPED);
	CONSTANT(CLD_TRAPPED);
	CONSTANT(CLD_STOPPED);
	CONSTANT(CLD_CONTINUED);
	CONSTANT(POLL_IN);
	CONSTANT(POLL_OUT);
	CONSTANT(POLL_MSG);
	CONSTANT(POLL_ERR);
	CONSTANT(POLL_PRI);
	CONSTANT(POLL_HUP);
	CONSTANT(SI_USER);
	CONSTANT(SI_QUEUE);
	CONSTANT(SI_TIMER);
	CONSTANT(SI_ASYNCIO);
	CONSTANT(SI_MESGQ);
