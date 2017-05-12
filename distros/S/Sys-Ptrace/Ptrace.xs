#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <sys/ptrace.h>

static int
not_here(char *s)
{
    croak("%s not implemented on this architecture", s);
    return -1;
}

static double
constant_PT_W(char *name, int len, int arg)
{
    if (4 + 5 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[4 + 5]) {
    case 'D':
	if (strEQ(name + 4, "RITE_D")) {	/* PT_W removed */
#ifdef PT_WRITE_D
	    return PT_WRITE_D;
#else
	    goto not_there;
#endif
	}
    case 'I':
	if (strEQ(name + 4, "RITE_I")) {	/* PT_W removed */
#ifdef PT_WRITE_I
	    return PT_WRITE_I;
#else
	    goto not_there;
#endif
	}
    case 'U':
	if (strEQ(name + 4, "RITE_U")) {	/* PT_W removed */
#ifdef PT_WRITE_U
	    return PT_WRITE_U;
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
constant_PT_GETF(char *name, int len, int arg)
{
    if (7 + 1 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[7 + 1]) {
    case 'R':
	if (strEQ(name + 7, "PREGS")) {	/* PT_GETF removed */
#ifdef PT_GETFPREGS
	    return PT_GETFPREGS;
#else
	    goto not_there;
#endif
	}
    case 'X':
	if (strEQ(name + 7, "PXREGS")) {	/* PT_GETF removed */
#ifdef PT_GETFPXREGS
	    return PT_GETFPXREGS;
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
constant_PT_G(char *name, int len, int arg)
{
    if (4 + 2 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[4 + 2]) {
    case 'F':
	if (!strnEQ(name + 4,"ET", 2))
	    break;
	return constant_PT_GETF(name, len, arg);
    case 'R':
	if (strEQ(name + 4, "ETREGS")) {	/* PT_G removed */
#ifdef PT_GETREGS
	    return PT_GETREGS;
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
constant_PT_R(char *name, int len, int arg)
{
    if (4 + 4 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[4 + 4]) {
    case 'D':
	if (strEQ(name + 4, "EAD_D")) {	/* PT_R removed */
#ifdef PT_READ_D
	    return PT_READ_D;
#else
	    goto not_there;
#endif
	}
    case 'I':
	if (strEQ(name + 4, "EAD_I")) {	/* PT_R removed */
#ifdef PT_READ_I
	    return PT_READ_I;
#else
	    goto not_there;
#endif
	}
    case 'U':
	if (strEQ(name + 4, "EAD_U")) {	/* PT_R removed */
#ifdef PT_READ_U
	    return PT_READ_U;
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
constant_PT_SETF(char *name, int len, int arg)
{
    if (7 + 1 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[7 + 1]) {
    case 'R':
	if (strEQ(name + 7, "PREGS")) {	/* PT_SETF removed */
#ifdef PT_SETFPREGS
	    return PT_SETFPREGS;
#else
	    goto not_there;
#endif
	}
    case 'X':
	if (strEQ(name + 7, "PXREGS")) {	/* PT_SETF removed */
#ifdef PT_SETFPXREGS
	    return PT_SETFPXREGS;
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
constant_PT_SE(char *name, int len, int arg)
{
    if (5 + 1 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[5 + 1]) {
    case 'F':
	if (!strnEQ(name + 5,"T", 1))
	    break;
	return constant_PT_SETF(name, len, arg);
    case 'R':
	if (strEQ(name + 5, "TREGS")) {	/* PT_SE removed */
#ifdef PT_SETREGS
	    return PT_SETREGS;
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
constant_PT_S(char *name, int len, int arg)
{
    switch (name[4 + 0]) {
    case 'E':
	return constant_PT_SE(name, len, arg);
    case 'T':
	if (strEQ(name + 4, "TEP")) {	/* PT_S removed */
#ifdef PT_STEP
	    return PT_STEP;
#else
	    goto not_there;
#endif
	}
    case 'Y':
	if (strEQ(name + 4, "YSCALL")) {	/* PT_S removed */
#ifdef PT_SYSCALL
	    return PT_SYSCALL;
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
constant(char *name, int len, int arg)
{
    errno = 0;
    if (0 + 3 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[0 + 3]) {
    case 'A':
	if (strEQ(name + 0, "PT_ATTACH")) {	/*  removed */
#ifdef PT_ATTACH
	    return PT_ATTACH;
#else
	    goto not_there;
#endif
	}
    case 'C':
	if (strEQ(name + 0, "PT_CONTINUE")) {	/*  removed */
#ifdef PT_CONTINUE
	    return PT_CONTINUE;
#else
	    goto not_there;
#endif
	}
    case 'D':
	if (strEQ(name + 0, "PT_DETACH")) {	/*  removed */
#ifdef PT_DETACH
	    return PT_DETACH;
#else
	    goto not_there;
#endif
	}
    case 'G':
	if (!strnEQ(name + 0,"PT_", 3))
	    break;
	return constant_PT_G(name, len, arg);
    case 'K':
	if (strEQ(name + 0, "PT_KILL")) {	/*  removed */
#ifdef PT_KILL
	    return PT_KILL;
#else
	    goto not_there;
#endif
	}
    case 'R':
	if (!strnEQ(name + 0,"PT_", 3))
	    break;
	return constant_PT_R(name, len, arg);
    case 'S':
	if (!strnEQ(name + 0,"PT_", 3))
	    break;
	return constant_PT_S(name, len, arg);
    case 'T':
	if (strEQ(name + 0, "PT_TRACE_ME")) {	/*  removed */
#ifdef PT_TRACE_ME
	    return PT_TRACE_ME;
#else
	    goto not_there;
#endif
	}
    case 'W':
	if (!strnEQ(name + 0,"PT_", 3))
	    break;
	return constant_PT_W(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}


MODULE = Sys::Ptrace		PACKAGE = Sys::Ptrace

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

long
_ptrace(request, pid, addr, data)
    INPUT:
	double		request
	int		pid
	size_t		addr
	size_t		data
    CODE:
	RETVAL = ptrace(request, pid, (void*) addr, (void*) data);
    OUTPUT:
	RETVAL

