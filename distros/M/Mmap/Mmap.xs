#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
}
#endif
#include <sys/mman.h>

#ifndef MMAP_RETTYPE
#define _POSIX_C_SOURCE 199309
#ifdef _POSIX_VERSION
#if _POSIX_VERSION >= 199309
#define MMAP_RETTYPE void *
#endif
#endif
#endif

#ifndef MMAP_RETTYPE
#define MMAP_RETTYPE caddr_t
#endif

#ifndef MAP_FAILED
#define MAP_FAILED ((caddr_t)-1)
#endif

static int
not_here(s)
char *s;
{
    croak("%s not implemented on this architecture", s);
    return -1;
}

static double
constant(name, arg)
char *name;
int arg;
{
    errno = 0;
    switch (*name) {
    case 'M':
	if (strEQ(name, "MAP_ANON"))
#ifdef MAP_ANON
	    return MAP_ANON;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MAP_ANONYMOUS"))
#ifdef MAP_ANONYMOUS
	    return MAP_ANONYMOUS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MAP_FILE"))
#ifdef MAP_FILE
	    return MAP_FILE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MAP_PRIVATE"))
#ifdef MAP_PRIVATE
	    return MAP_PRIVATE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MAP_SHARED"))
#ifdef MAP_SHARED
	    return MAP_SHARED;
#else
	    goto not_there;
#endif
	break;
    case 'P':
	if (strEQ(name, "PROT_EXEC"))
#ifdef PROT_EXEC
	    return PROT_EXEC;
#else
	    goto not_there;
#endif
	if (strEQ(name, "PROT_NONE"))
#ifdef PROT_NONE
	    return PROT_NONE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "PROT_READ"))
#ifdef PROT_READ
	    return PROT_READ;
#else
	    goto not_there;
#endif
	if (strEQ(name, "PROT_WRITE"))
#ifdef PROT_WRITE
	    return PROT_WRITE;
#else
	    goto not_there;
#endif
	break;
    default:
	break;	
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

MODULE = Mmap		PACKAGE = Mmap


double
constant(name,arg)
	char *		name
	int		arg

void
mmap(var, len, prot, flags, fh, off = 0)
	SV *		var
	size_t		len
	int		prot
	int		flags
	FILE *		fh
	off_t		off
	int		fd = NO_INIT
	MMAP_RETTYPE	addr = NO_INIT
    PROTOTYPE: $$$$*;$
    CODE:

	ST(0) = &sv_undef;
	fd = fileno(fh);
	if (fd < 0)
	    return;

	if (!len) {
	    struct stat st;
	    if (fstat(fd, &st) == -1)
		return;
	    len = st.st_size;
	}
	
	addr = mmap(0, len, prot, flags, fd, off);
	if (addr == MAP_FAILED)
	    return;

	SvUPGRADE(var, SVt_PV);
	if (!(prot & PROT_WRITE))
	    SvREADONLY_on(var);

	SvPVX(var) = (char *) addr;
	SvCUR_set(var, len);
	SvLEN_set(var, 0);
	SvPOK_only(var);
	ST(0) = &sv_yes;

void
munmap(var)
	SV *	var
    PROTOTYPE: $
    CODE:
	ST(0) = &sv_undef;
	if (munmap((MMAP_RETTYPE) SvPVX(var), SvCUR(var)) == -1)
	    return;
	SvREADONLY_off(var);
	SvPVX(var) = 0;
	SvCUR_set(var, 0);
	SvLEN_set(var, 0);
	SvOK_off(var);
	ST(0) = &sv_yes;
