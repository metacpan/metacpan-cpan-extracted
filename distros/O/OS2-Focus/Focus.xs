#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <os2emx.h>

static HWND rc;

#define _HWND_DESKTOP() HWND_DESKTOP
#define _SetFocus(hwndSetFocus)						\
	(!CheckWinError(WinSetFocus(HWND_DESKTOP, hwndSetFocus)))
#define _FocusChange(hwndSetFocus, flFocusChange)			\
	(!CheckWinError(WinFocusChange(HWND_DESKTOP, hwndSetFocus,	\
					flFocusChange)))

static HWND
_QueryFocus()							\
{
  HWND rc = WinQueryFocus(HWND_DESKTOP);

  CheckWinError(rc);
  return rc;
}

static int
not_here(char *s)
{
    croak("%s not implemented on this architecture", s);
    return -1;
}

static double
constant(char *name, int len, int arg)
{
    errno = 0;
    if (strEQ(name + 0, "HWND_DESKTOP")) {	/*  removed */
#ifdef HWND_DESKTOP
	return HWND_DESKTOP;
#else
	errno = ENOENT;
	return 0;
#endif
    }
    errno = EINVAL;
    return 0;
}

MODULE = OS2::Focus		PACKAGE = OS2::Focus		PREFIX = _


double
constant(sv,arg)
PREINIT:
	STRLEN		len;
INPUT:
	SV *		sv
	char *		s = SvPV(sv, len);
	int		arg
CODE:
	RETVAL = constant(s,len,arg);
OUTPUT:
	RETVAL


BOOL
WinFocusChange(hwndDesktop, hwndSetFocus, flFocusChange)
	HWND	hwndDesktop
	HWND	hwndSetFocus
	ULONG	flFocusChange

HWND
WinQueryFocus(hwndDesktop)
	HWND	hwndDesktop

BOOL
WinSetFocus(hwndDesktop, hwndSetFocus)
	HWND	hwndDesktop
	HWND	hwndSetFocus

BOOL
_FocusChange(hwndSetFocus, flFocusChange)
	HWND	hwndSetFocus
	ULONG	flFocusChange

HWND
_QueryFocus()

BOOL
_SetFocus(hwndSetFocus)
	HWND	hwndSetFocus

HWND
_HWND_DESKTOP()
