#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <stdlib.h>
#ifdef __cplusplus
}
#endif
#include <sys/mman.h>
#include <unistd.h>

#ifndef MMAP_RETTYPE
#ifndef _POSIX_C_SOURCE
#define _POSIX_C_SOURCE 199309
#endif
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
        if (strEQ(name, "MAP_LOCKED"))
#ifdef MAP_LOCKED
            return MAP_LOCKED;
#else
            goto not_there;
#endif
        if (strEQ(name, "MAP_NORESERVE"))
#ifdef MAP_NORESERVE
            return MAP_NORESERVE;
#else
            goto not_there;
#endif
	if (strEQ(name, "MAP_POPULATE"))
#ifdef MAP_POPULATE
	return MAP_POPULATE; 
#else
	goto not_there;
#endif
        if (strEQ(name, "MAP_HUGETLB"))
#ifdef MAP_HUGETLB
            return MAP_HUGETLB;
#else
            goto not_there;
#endif
        if (strEQ(name, "MAP_HUGE_2MB"))
#ifdef MAP_HUGE_2MB
            return MAP_HUGE_2MB;
#else
            goto not_there;
#endif
        if (strEQ(name, "MAP_HUGE_1GB"))
#ifdef MAP_HUGE_1GB
            return MAP_HUGE_1GB;
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

static size_t pagesize = 0;


#if _FILE_OFFSET_BITS > 32
#define get_off(a) (atoll(a))
#else
#define get_off(a) (atoi(a))
#endif


MODULE = Sys::Mmap		PACKAGE = Sys::Mmap


double
constant(name,arg)
	char *		name
	int		arg

SV *
hardwire(var, addr, len)
        SV *            var
	IV	addr
	size_t		len
    PROTOTYPE: $$$
    CODE:
	ST(0) = &PL_sv_undef;
	SvUPGRADE(var, SVt_PV);
	SvPVX(var) = (char *) addr;
	SvCUR_set(var, len);
	SvLEN_set(var, 0);
	SvPOK_only(var);
        /*printf("ok, that var is now stuck at addr %lx\n", addr);*/
        ST(0) = &PL_sv_yes;



SV *
mmap(var, len, prot, flags, fh = 0, off_string)
	SV *		var
	size_t		len
	int		prot
	int		flags
	FILE *		fh
    SV *  off_string
	int		fd = NO_INIT
	MMAP_RETTYPE	addr = NO_INIT
	off_t		slop = NO_INIT
    off_t off = NO_INIT
    PROTOTYPE: $$$$*;$
    CODE:

    if(!SvTRUE(off_string)) {
        off = 0;
    }
    else {
        off = get_off(SvPVbyte_nolen(off_string));
    }
    
    if(off < 0) {
        croak("mmap: Cannot operate on a negative offset (%s) ", SvPVbyte_nolen(off_string));
    }
    
	ST(0) = &PL_sv_undef;
        if(flags&MAP_ANON) {
          fd = -1;
          if (!len)  {
              /* i WANT to return undef and set $! but perlxs and perlxstut dont tell me how... waa! */
              croak("mmap: MAP_ANON specified, but no length specified. cannot infer length from file");
          }
        } else {
	  fd = fileno(fh);
          if (fd < 0) {
              croak("mmap: file not open or does not have associated fileno");
          }
	  if (!len) {
	      struct stat st;
	      if (fstat(fd, &st) == -1) {
                  croak("mmap: no len provided, fstat failed, unable to infer length");
              }
	      len = st.st_size;
	  }
        }

	if (pagesize == 0) {
	      pagesize = getpagesize();
	}

    slop = (size_t) off % pagesize;

	addr = mmap(0, len + slop, prot, flags, fd, off - slop);
	if (addr == MAP_FAILED) {
            croak("mmap: mmap call failed: errno: %d errmsg: %s ", errno, strerror(errno));
        }
#if PERL_VERSION >= 20

        if (SvIsCOW(var)) {
            sv_force_normal_flags(var, 0);
        }
#endif

	SvUPGRADE(var, SVt_PV);
	if (!(prot & PROT_WRITE))
	    SvREADONLY_on(var);

        /* would sv_usepvn() be cleaner/better/different? would still try to realloc... */
	SvPVX(var) = (char *) addr + slop;
	SvCUR_set(var, len);
	SvLEN_set(var, slop);
	SvPOK_only(var);
        ST(0) = sv_2mortal(newSVnv((IV) addr));

SV *
munmap(var)
	SV *	var
    PROTOTYPE: $
    CODE:
	ST(0) = &PL_sv_undef;
        /* XXX refrain from dumping core if this var wasnt previously mmap'd */
	if(!SvOK(var)) { /* Detect if variable is undef */
            croak("undef variable not unmappable");
            return;
	}
        if(SvTYPE(var) < SVt_PV || SvTYPE(var) > SVt_PVMG) {
           croak("variable is not a string, type is: %d", SvTYPE(var));
            return;
        }

        if (munmap((MMAP_RETTYPE) SvPVX(var) - SvLEN(var), SvCUR(var) + SvLEN(var)) == -1) {
            croak("munmap failed! errno %d %s\n", errno, strerror(errno));
            return;
        }
        SvREADONLY_off(var);
        SvPVX(var) = 0;
        SvCUR_set(var, 0);
        SvLEN_set(var, 0);
        SvOK_off(var);
        ST(0) = &PL_sv_yes;

void
DESTROY(var) 
    SV *     var
    PROTOTYPE: $
    CODE:
        /* XXX refrain from dumping core if this var wasnt previously mmap'd*/
        if (munmap((MMAP_RETTYPE) SvPVX(var), SvCUR(var)) == -1) {
            croak("munmap failed! errno %d %s\n", errno, strerror(errno));
            return;
        }
        SvREADONLY_off(var);
        SvPVX(var) = 0;
        SvCUR_set(var, 0);
        SvLEN_set(var, 0);
        SvOK_off(var);
        /* printf("destroy ran fine, thanks\n"); */
        ST(0) = &PL_sv_yes;
