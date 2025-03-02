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

#ifdef HAVE_SI_BAND
#define siginfo_band(self) (self)->si_band
#else
#define siginfo_band(self) 0
#endif

#ifdef HAVE_SI_FD
#define siginfo_fd(self) (self)->si_fd
#else
#define siginfo_fd(self) 0
#endif

#ifdef HAVE_SI_TIMERID
#define siginfo_timerid(self) (self)->si_timerid
#else
#define siginfo_timerid(self) 0
#endif

#ifdef HAVE_SI_OVERRUN
#define siginfo_overrun(self) (self)->si_overrun
#else
#define siginfo_overrun(self) 0
#endif

#define siginfo_addr(self) PTR2UV((self)->si_addr)

#define siginfo_value(self) (self)->si_value.sival_int
#define siginfo_ptr(self) PTR2UV((self)->si_value.sival_ptr)

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

IV siginfo_fd(Signal::Info self)

IV siginfo_timerid(Signal::Info self)

IV siginfo_overrun(Signal::Info self)

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
#ifdef TRAP_BRKPT
	CONSTANT(TRAP_BRKPT);
	CONSTANT(TRAP_TRACE);
#endif
	CONSTANT(CLD_EXITED);
	CONSTANT(CLD_KILLED);
	CONSTANT(CLD_DUMPED);
	CONSTANT(CLD_TRAPPED);
	CONSTANT(CLD_STOPPED);
	CONSTANT(CLD_CONTINUED);
#ifdef POLL_IN
	CONSTANT(POLL_IN);
	CONSTANT(POLL_OUT);
	CONSTANT(POLL_MSG);
	CONSTANT(POLL_ERR);
	CONSTANT(POLL_PRI);
	CONSTANT(POLL_HUP);
#endif
	CONSTANT(SI_USER);
	CONSTANT(SI_QUEUE);
	CONSTANT(SI_TIMER);
#ifdef SI_ASYNCIO
	CONSTANT(SI_ASYNCIO);
#endif
#ifdef SI_MESGQ
	CONSTANT(SI_MESGQ);
#endif
