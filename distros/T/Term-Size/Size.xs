#ifdef __cplusplus
extern "C" {
#endif

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#ifndef _AIX
#include <sys/termios.h>
#else
#include <termios.h>
#endif

#ifdef __cplusplus
}
#endif

MODULE = Term::Size		PACKAGE = Term::Size

PROTOTYPES: DISABLE

void
chars( f = stdin )
	FILE *f;

	PREINIT:
	struct winsize w = { 0, 0, 0, 0 };

	PPCODE:
	if (ioctl(fileno(f), TIOCGWINSZ, &w) == -1)
		XSRETURN_NO;

	XPUSHs(sv_2mortal(newSViv(w.ws_col)));
	if (GIMME != G_SCALAR)
		XPUSHs(sv_2mortal(newSViv(w.ws_row)));

void
pixels( f = stdin )
	FILE *f;

	PREINIT:
	struct winsize w = { 0, 0, 0, 0 };

	PPCODE:
	if (ioctl(fileno(f), TIOCGWINSZ, &w) == -1)
		XSRETURN_NO;

	XPUSHs(sv_2mortal(newSViv(w.ws_xpixel)));
	if (GIMME != G_SCALAR)
		XPUSHs(sv_2mortal(newSViv(w.ws_ypixel)));
