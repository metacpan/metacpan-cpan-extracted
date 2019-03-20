#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

static volatile sig_atomic_t handles[NSIG];

static void kill_handler(int signo) {
	struct sigaction action = { 0 };
	sigaction(signo, &action, NULL);
	close(handles[signo]);
	handles[signo] = -1;
}

static void handler(int signo) {
	int fd = handles[signo];
	if (fd >= 0 && write(fd, "\x01", 1) < 0 && errno != EAGAIN)
		kill_handler(signo);
}

static void nonblock(int fd) {
	int base = fcntl(fd, F_GETFL, 0);
	fcntl(fd, F_SETFL, base | O_NONBLOCK);
}

static SV* S_io_fdopen(pTHX_ int fd, const char* classname) {
	PerlIO* pio = PerlIO_fdopen(fd, "r");
	GV* gv = newGVgen(classname);
	SV* ret = newRV_noinc((SV*)gv);
	IO* io = GvIOn(gv);
	IoTYPE(io) = '<';
	IoIFP(io) = pio;
	IoOFP(io) = pio;
	return ret;
}
#define io_fdopen(fd, classname) S_io_fdopen(aTHX_ fd, classname)

static int pipe_destroy(pTHX_ SV* sv, MAGIC* magic) {
	kill_handler(magic->mg_len);
}

static const MGVTBL pipe_magic = { NULL, NULL, NULL, NULL, pipe_destroy };

MODULE = Signal::Pipe				PACKAGE = Signal::Pipe

PROTOTYPES: DISABLED

BOOT:
	int i;
	for (i = 0; i < NSIG; ++i)
		handles[i] = -1;

SV*
selfpipe(signo);
	int signo;
PREINIT:
	int fds[2];
	struct sigaction action = {0};
CODE:
	if (handles[signo] >= 0)
		Perl_croak(aTHX_ "Self pipe already established for signal %d", signo);
	if (pipe(fds) == -1)
		Perl_croak(aTHX_ "Couldn't open a pipe: %s", Strerror(errno));
	if (fds[1] > SIG_ATOMIC_MAX)
		Perl_croak(aTHX_ "Pipe descriptor doesn't fit in a sig_atomic_t");
	nonblock(fds[0]);
	nonblock(fds[1]);
	handles[signo] = fds[1];

	action.sa_handler = handler;
	sigaction(signo, &action, NULL);

	RETVAL = io_fdopen(fds[0], "Signal::Pipe");
	sv_magicext(SvRV(RETVAL), NULL, PERL_MAGIC_ext, &pipe_magic, NULL, signo);
OUTPUT:
	RETVAL

