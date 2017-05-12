#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <os2emx.h>
#include <open_settings.h>

static has_hmq;

/* Older Perls have an extra semicolon here */
#define perl_hmq_GET_no_semi(serve)	Perl_Register_MQ(serve)

/* 0 means we are not going to serve a message loop ourselves */
#define REQUEST_HMQ	( has_hmq++ ? Perl_hmq : perl_hmq_GET_no_semi(0) )

typedef HOBJECT		HOBJECT_or_error;
typedef HWND		HWND_or_error;
typedef HBITMAP		HBITMAP_or_error;
typedef HPOINTER	HPOINTER_or_error;
typedef ULONG		ULONG_error;

/* Avoid mixing prototypes for newSViv and newSVuv if the test is wrong */
#define newSViv_uv	newSViv

static int
not_here(char *s)
{
    croak("%s not implemented on this architecture", s);
    return -1;
}

static double
constant_OPEN_P(char *name, int arg)
{
    errno = 0;
    switch (name[6 + 0]) {
    case 'A':
	if (strEQ(name + 6, "ALETTE")) {	/* OPEN_P removed */
#ifdef OPEN_PALETTE
	    return OPEN_PALETTE;
#else
	    goto not_there;
#endif
	}
    case 'R':
	if (strEQ(name + 6, "ROMPTDLG")) {	/* OPEN_P removed */
#ifdef OPEN_PROMPTDLG
	    return OPEN_PROMPTDLG;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_OPEN_S(char *name, int arg)
{
    errno = 0;
    switch (name[6 + 0]) {
    case 'E':
	if (strEQ(name + 6, "ETTINGS")) {	/* OPEN_S removed */
#ifdef OPEN_SETTINGS
	    return OPEN_SETTINGS;
#else
	    goto not_there;
#endif
	}
    case 'T':
	if (strEQ(name + 6, "TATUS")) {	/* OPEN_S removed */
#ifdef OPEN_STATUS
	    return OPEN_STATUS;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_OPEN_D(char *name, int arg)
{
    errno = 0;
    switch (name[6 + 1]) {
    case 'F':
	if (strEQ(name + 6, "EFAULT")) {	/* OPEN_D removed */
#ifdef OPEN_DEFAULT
	    return OPEN_DEFAULT;
#else
	    goto not_there;
#endif
	}
    case 'T':
	if (strEQ(name + 6, "ETAILS")) {	/* OPEN_D removed */
#ifdef OPEN_DETAILS
	    return OPEN_DETAILS;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_O(char *name, int arg)
{
    errno = 0;
    switch (name[1 + 4]) {
    case 'A':
	if (strEQ(name + 1, "PEN_AUTO")) {	/* O removed */
#ifdef OPEN_AUTO
	    return OPEN_AUTO;
#else
	    goto not_there;
#endif
	}
    case 'B':
	if (strEQ(name + 1, "PEN_BATTERY")) {	/* O removed */
#ifdef OPEN_BATTERY
	    return OPEN_BATTERY;
#else
	    goto not_there;
#endif
	}
    case 'C':
	if (strEQ(name + 1, "PEN_CONTENTS")) {	/* O removed */
#ifdef OPEN_CONTENTS
	    return OPEN_CONTENTS;
#else
	    goto not_there;
#endif
	}
    case 'D':
	if (!strnEQ(name + 1,"PEN_", 4))
	    break;
	return constant_OPEN_D(name, arg);
    case 'H':
	if (strEQ(name + 1, "PEN_HELP")) {	/* O removed */
#ifdef OPEN_HELP
	    return OPEN_HELP;
#else
	    goto not_there;
#endif
	}
    case 'P':
	if (!strnEQ(name + 1,"PEN_", 4))
	    break;
	return constant_OPEN_P(name, arg);
    case 'R':
	if (strEQ(name + 1, "PEN_RUNNING")) {	/* O removed */
#ifdef OPEN_RUNNING
	    return OPEN_RUNNING;
#else
	    goto not_there;
#endif
	}
    case 'S':
	if (!strnEQ(name + 1,"PEN_", 4))
	    break;
	return constant_OPEN_S(name, arg);
    case 'T':
	if (strEQ(name + 1, "PEN_TREE")) {	/* O removed */
#ifdef OPEN_TREE
	    return OPEN_TREE;
#else
	    goto not_there;
#endif
	}
    case 'U':
	if (strEQ(name + 1, "PEN_USER")) {	/* O removed */
#ifdef OPEN_USER
	    return OPEN_USER;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_PMERR_W(char *name, int arg)
{
    errno = 0;
    switch (name[7 + 9]) {
    case 'I':
	if (strEQ(name + 7, "PDSERVER_IS_ACTIVE")) {	/* PMERR_W removed */
#ifdef PMERR_WPDSERVER_IS_ACTIVE
	    return PMERR_WPDSERVER_IS_ACTIVE;
#else
	    goto not_there;
#endif
	}
    case 'N':
	if (strEQ(name + 7, "PDSERVER_NOT_STARTED")) {	/* PMERR_W removed */
#ifdef PMERR_WPDSERVER_NOT_STARTED
	    return PMERR_WPDSERVER_NOT_STARTED;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_PMERR_INVALID_H(char *name, int arg)
{
    errno = 0;
    switch (name[15 + 0]) {
    case 'P':
	if (strEQ(name + 15, "PTR")) {	/* PMERR_INVALID_H removed */
#ifdef PMERR_INVALID_HPTR
	    return PMERR_INVALID_HPTR;
#else
	    goto not_there;
#endif
	}
    case 'W':
	if (strEQ(name + 15, "WND")) {	/* PMERR_INVALID_H removed */
#ifdef PMERR_INVALID_HWND
	    return PMERR_INVALID_HWND;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_PMERR_INVA(char *name, int arg)
{
    errno = 0;
    switch (name[10 + 4]) {
    case 'F':
	if (strEQ(name + 10, "LID_FLAG")) {	/* PMERR_INVA removed */
#ifdef PMERR_INVALID_FLAG
	    return PMERR_INVALID_FLAG;
#else
	    goto not_there;
#endif
	}
    case 'H':
	if (!strnEQ(name + 10,"LID_", 4))
	    break;
	return constant_PMERR_INVALID_H(name, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_PMERR_I(char *name, int arg)
{
    errno = 0;
    switch (name[7 + 2]) {
    case 'A':
	if (!strnEQ(name + 7,"NV", 2))
	    break;
	return constant_PMERR_INVA(name, arg);
    case '_':
	if (strEQ(name + 7, "NV_HDC")) {	/* PMERR_I removed */
#ifdef PMERR_INV_HDC
	    return PMERR_INV_HDC;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_P(char *name, int arg)
{
    errno = 0;
    switch (name[1 + 5]) {
    case 'I':
	if (!strnEQ(name + 1,"MERR_", 5))
	    break;
	return constant_PMERR_I(name, arg);
    case 'W':
	if (!strnEQ(name + 1,"MERR_", 5))
	    break;
	return constant_PMERR_W(name, arg);
    case 'P':
	if (strEQ(name+1,"MERR_PARAMETER_OUT_OF_RANGE"))
#ifdef PMERR_PARAMETER_OUT_OF_RANGE
	    return PMERR_PARAMETER_OUT_OF_RANGE;
#else
	    goto not_there;
#endif
	    
	break;
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_SWP_NOA(char *name, int arg)
{
    errno = 0;
    switch (name[7 + 0]) {
    case 'D':
	if (strEQ(name + 7, "DJUST")) {	/* SWP_NOA removed */
#ifdef SWP_NOADJUST
	    return SWP_NOADJUST;
#else
	    goto not_there;
#endif
	}
    case 'U':
	if (strEQ(name + 7, "UTOCLOSE")) {	/* SWP_NOA removed */
#ifdef SWP_NOAUTOCLOSE
	    return SWP_NOAUTOCLOSE;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_SWP_N(char *name, int arg)
{
    errno = 0;
    switch (name[5 + 1]) {
    case 'A':
	if (!strnEQ(name + 5,"O", 1))
	    break;
	return constant_SWP_NOA(name, arg);
    case 'R':
	if (strEQ(name + 5, "OREDRAW")) {	/* SWP_N removed */
#ifdef SWP_NOREDRAW
	    return SWP_NOREDRAW;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_SWP_S(char *name, int arg)
{
    errno = 0;
    switch (name[5 + 0]) {
    case 'H':
	if (strEQ(name + 5, "HOW")) {	/* SWP_S removed */
#ifdef SWP_SHOW
	    return SWP_SHOW;
#else
	    goto not_there;
#endif
	}
    case 'I':
	if (strEQ(name + 5, "IZE")) {	/* SWP_S removed */
#ifdef SWP_SIZE
	    return SWP_SIZE;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_SWP_F(char *name, int arg)
{
    errno = 0;
    switch (name[5 + 4]) {
    case 'A':
	if (strEQ(name + 5, "OCUSACTIVATE")) {	/* SWP_F removed */
#ifdef SWP_FOCUSACTIVATE
	    return SWP_FOCUSACTIVATE;
#else
	    goto not_there;
#endif
	}
    case 'D':
	if (strEQ(name + 5, "OCUSDEACTIVATE")) {	/* SWP_F removed */
#ifdef SWP_FOCUSDEACTIVATE
	    return SWP_FOCUSDEACTIVATE;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_SWP_M(char *name, int arg)
{
    errno = 0;
    switch (name[5 + 0]) {
    case 'A':
	if (strEQ(name + 5, "AXIMIZE")) {	/* SWP_M removed */
#ifdef SWP_MAXIMIZE
	    return SWP_MAXIMIZE;
#else
	    goto not_there;
#endif
	}
    case 'I':
	if (strEQ(name + 5, "INIMIZE")) {	/* SWP_M removed */
#ifdef SWP_MINIMIZE
	    return SWP_MINIMIZE;
#else
	    goto not_there;
#endif
	}
    case 'O':
	if (strEQ(name + 5, "OVE")) {	/* SWP_M removed */
#ifdef SWP_MOVE
	    return SWP_MOVE;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_S(char *name, int arg)
{
    errno = 0;
    switch (name[1 + 3]) {
    case 'A':
	if (strEQ(name + 1, "WP_ACTIVATE")) {	/* S removed */
#ifdef SWP_ACTIVATE
	    return SWP_ACTIVATE;
#else
	    goto not_there;
#endif
	}
    case 'D':
	if (strEQ(name + 1, "WP_DEACTIVATE")) {	/* S removed */
#ifdef SWP_DEACTIVATE
	    return SWP_DEACTIVATE;
#else
	    goto not_there;
#endif
	}
    case 'E':
	if (strEQ(name + 1, "WP_EXTSTATECHANGE")) {	/* S removed */
#ifdef SWP_EXTSTATECHANGE
	    return SWP_EXTSTATECHANGE;
#else
	    goto not_there;
#endif
	}
    case 'F':
	if (!strnEQ(name + 1,"WP_", 3))
	    break;
	return constant_SWP_F(name, arg);
    case 'H':
	if (strEQ(name + 1, "WP_HIDE")) {	/* S removed */
#ifdef SWP_HIDE
	    return SWP_HIDE;
#else
	    goto not_there;
#endif
	}
    case 'M':
	if (!strnEQ(name + 1,"WP_", 3))
	    break;
	return constant_SWP_M(name, arg);
    case 'N':
	if (!strnEQ(name + 1,"WP_", 3))
	    break;
	return constant_SWP_N(name, arg);
    case 'R':
	if (strEQ(name + 1, "WP_RESTORE")) {	/* S removed */
#ifdef SWP_RESTORE
	    return SWP_RESTORE;
#else
	    goto not_there;
#endif
	}
    case 'S':
	if (!strnEQ(name + 1,"WP_", 3))
	    break;
	return constant_SWP_S(name, arg);
    case 'Z':
	if (strEQ(name + 1, "WP_ZORDER")) {	/* S removed */
#ifdef SWP_ZORDER
	    return SWP_ZORDER;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_C(char *name, int arg)
{
    errno = 0;
    switch (name[1 + 2]) {
    case 'F':
	if (strEQ(name + 1, "O_FAILIFEXISTS")) {	/* C removed */
#ifdef CO_FAILIFEXISTS
	    return CO_FAILIFEXISTS;
#else
	    goto not_there;
#endif
	}
    case 'R':
	if (strEQ(name + 1, "O_REPLACEIFEXISTS")) {	/* C removed */
#ifdef CO_REPLACEIFEXISTS
	    return CO_REPLACEIFEXISTS;
#else
	    goto not_there;
#endif
	}
    case 'U':
	if (strEQ(name + 1, "O_UPDATEIFEXISTS")) {	/* C removed */
#ifdef CO_UPDATEIFEXISTS
	    return CO_UPDATEIFEXISTS;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant(char *name, int arg)
{
    errno = 0;
    switch (name[0 + 0]) {
    case 'C':
	return constant_C(name, arg);
    case 'O':
	return constant_O(name, arg);
    case 'P':
	return constant_P(name, arg);
    case 'S':
	return constant_S(name, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

POBJCLASS
EnumObjectClasses(void)
{
    POBJCLASS ret = 0;
    ULONG c;

    if (CheckWinError(WinEnumObjectClasses (ret, &c)))
	return 0;
    New(1154, ret, c, OBJCLASS);
    if (CheckWinError(WinEnumObjectClasses (ret, &c))) {
	Safefree(ret);
	return 0;
    }
    return ret;
}

SV *
ActiveDesktopPathname(void)
{
	char	pszPathName[CCHMAXPATH + 1];

	if (CheckWinError(WinQueryActiveDesktopPathname(pszPathName,sizeof(pszPathName))))
	    return NULL;
	return newSVpv(pszPathName, 0);
}

SV *
ObjectPath(HOBJECT hobject)
{
	char	pszPathName[CCHMAXPATH + 1];

	if (CheckWinError(WinQueryObjectPath(hobject, pszPathName,sizeof(pszPathName))))
	    return Nullsv;
	return newSVpv(pszPathName, 0);
}

typedef struct {int error; SWP swp;} SWP_or_error;

SWP_or_error
WindowPos(HWND hwnd)
{
	SWP_or_error	swpe;

	swpe.error = 0;
	if (CheckWinError(WinQueryWindowPos(hwnd, &(swpe.swp))))
	    swpe.error = 1;
	return swpe;
}

#define make_hwnd(h)	(h)

MODULE = OS2::WinObject		PACKAGE = OS2::WinObject		PREFIX = Win

PROTOTYPES: enable

double
constant(name,arg)
	char *		name
	int		arg


HOBJECT_or_error
WinCopyObject(hObjectofObject, hObjectofDest, ulReserved = 0)
	HOBJECT	hObjectofObject
	HOBJECT	hObjectofDest
	ULONG	ulReserved

HOBJECT_or_error
WinCreateObject(pszClassName, pszTitle, pszSetupString, pszLocation, ulFlags)
	PCSZ	pszClassName
	PCSZ	pszTitle
	PCSZ	pszSetupString
	PCSZ	pszLocation
	ULONG	ulFlags

BOOL
WinDeregisterObjectClass(pszClassName)
	PCSZ	pszClassName

BOOL
WinDestroyObject(hObject)
	HOBJECT	hObject

BOOL
WinEnumObjectClasses(pObjClass, pulSize)
	POBJCLASS	pObjClass
	PULONG	pulSize

BOOL
WinFreeFileIcon(hptr)
	HPOINTER	hptr

BOOL
WinIsSOMDDReady()

BOOL
WinIsWPDServerReady()

HPOINTER_or_error
WinLoadFileIcon(pszFileName, fPrivate)
	PCSZ	pszFileName
	bool	fPrivate

HOBJECT_or_error
WinMoveObject(hObjectofObject, hObjectofDest, ulReserved = 0)
	HOBJECT	hObjectofObject
	HOBJECT	hObjectofDest
	ULONG	ulReserved

BOOL
WinOpenObject(hObject, ulView, fFlag)
	HOBJECT	hObject
	ULONG	ulView
	bool	fFlag

BOOL
WinQueryActiveDesktopPathname(pszPathName, ulSize)
	PSZ	pszPathName
	ULONG	ulSize

BOOL
WinQueryDesktopBkgnd(hwndDesktop, pdsk)
	HWND	hwndDesktop
	PDESKTOP	pdsk

HWND_or_error
WinQueryDesktopWindow(hab  = perl_hab_GET(), hdc = NULLHANDLE)
	HAB	hab
	HDC	hdc

HOBJECT_or_error
WinQueryObject(pszObjectID)
	PCSZ	pszObjectID

BOOL
WinQueryObjectPath(hobject, pszPathName, ulSize)
	HOBJECT	hobject
	PSZ	pszPathName
	ULONG	ulSize

HWND_or_error
WinQueryObjectWindow(hwndDesktop = HWND_DESKTOP)
	HWND	hwndDesktop

BOOL
WinQueryWindowPos(hwnd, pswp)
	HWND	hwnd
	PSWP	pswp

BOOL
WinRegisterObjectClass(pszClassName, pszModName)
	PCSZ	pszClassName
	PCSZ	pszModName

BOOL
WinReplaceObjectClass(pszOldClassName, pszNewClassName, fReplace)
	PCSZ	pszOldClassName
	PCSZ	pszNewClassName
	bool	fReplace

ULONG_error
WinRestartSOMDD(fState)
	bool	fState

ULONG_error
WinRestartWPDServer(fState)
	bool	fState

BOOL
WinRestoreWindowPos(pszAppName, pszKeyName, hwnd)
	PCSZ	pszAppName
	PCSZ	pszKeyName
	HWND	hwnd

BOOL
WinSaveObject(hObject, fAsync)
	HOBJECT	hObject
	bool	fAsync

BOOL
WinSaveWindowPos(hsvwp, pswp, cswp)
	HSAVEWP	hsvwp
	PSWP	pswp
	ULONG	cswp

HBITMAP_or_error
WinSetDesktopBkgnd(hwndDesktop, pdskNew)
	HWND	hwndDesktop
	__const__ DESKTOP *	pdskNew

BOOL
WinSetFileIcon(pszFileName, pIconInfo)
	PCSZ	pszFileName
	__const__ ICONINFO *	pIconInfo

BOOL
WinSetMultWindowPos(hab, pswp, cswp)
	HAB	hab
	__const__ SWP *	pswp
	ULONG	cswp

BOOL
WinSetObjectData(hObject, pszSetupString)
	HOBJECT	hObject
	PCSZ	pszSetupString

BOOL
WinSetWindowPos(hwnd, hwndInsertBehind, x, y, cx, cy, fl)
	HWND	hwnd
	HWND	hwndInsertBehind
	LONG	x
	LONG	y
	LONG	cx
	LONG	cy
	ULONG	fl

BOOL
WinShutdownSystem(hab = perl_hab_GET(), hmq = REQUEST_HMQ)
	HAB	hab
	HMQ	hmq

BOOL
WinStoreWindowPos(pszAppName, pszKeyName, hwnd)
	PCSZ	pszAppName
	PCSZ	pszKeyName
	HWND	hwnd

LONG
WinQuerySysValue(iSysValue, hwndDesktop = HWND_DESKTOP)
	LONG iSysValue
	HWND hwndDesktop
    C_ARGS: hwndDesktop, iSysValue

BOOL
WinSetSysValue(iSysValue, lValue, hwndDesktop = HWND_DESKTOP)
	LONG iSysValue
	LONG lValue
	HWND hwndDesktop
    C_ARGS: hwndDesktop, iSysValue, lValue

SV *
ObjectClasses()
    PPCODE:
    {
	POBJCLASS list = EnumObjectClasses();
	POBJCLASS l = list, i = list;
	int c;

	while (l) {
	    l = l[0].pNext;
	    c++;
	}
	EXTEND(SP, 2*c);
	l = list;
	while (l) {
	    PUSHs(sv_2mortal(newSVpv(l[0].pszClassName, 0)));
	    PUSHs(sv_2mortal(newSVpv(l[0].pszModName,   0)));
	    l = l[0].pNext;
	}
	Safefree(list);
    }

SV *
ActiveDesktopPathname()

SV *
ObjectPath(hobject)
	HOBJECT	hobject

MODULE = OS2::WinObject		PACKAGE = OS2::WinObject	PREFIX = make

SV *
WindowPos(hwnd)
	HWND	hwnd;
    PPCODE:
    {
	SWP_or_error swpe = WindowPos(hwnd);

	if (!swpe.error) {
	    EXTEND(SP, 9);
	    PUSHs(sv_2mortal(newSViv(swpe.swp.x)));
	    PUSHs(sv_2mortal(newSViv(swpe.swp.y)));
	    PUSHs(sv_2mortal(newSViv(swpe.swp.cx)));
	    PUSHs(sv_2mortal(newSViv(swpe.swp.cy)));
	    PUSHs(sv_2mortal(newSVuv(swpe.swp.fl)));
	    PUSHs(sv_2mortal(newSVuv(swpe.swp.hwndInsertBehind)));
	    PUSHs(sv_2mortal(newSVuv(swpe.swp.hwnd)));
	    PUSHs(sv_2mortal(newSVuv(swpe.swp.ulReserved1)));
	    PUSHs(sv_2mortal(newSVuv(swpe.swp.ulReserved2)));
	}
    }

HWND
make_hwnd(h)
	ULONG h
