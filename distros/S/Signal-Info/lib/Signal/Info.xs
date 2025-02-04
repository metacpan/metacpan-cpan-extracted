#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

typedef siginfo_t* Signal__Info;

MODULE = Signal::Info    PACKAGE = Signal::Info    PREFIX = siginfo_

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

PROTOTYPES: DISABLED

Signal::Info new(class)
	CODE:
	RETVAL = safecalloc(1, sizeof(siginfo_t));
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
