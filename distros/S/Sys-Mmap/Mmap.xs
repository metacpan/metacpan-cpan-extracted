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

/* Magic structure to track mmap info for proper cleanup */
typedef struct {
    void  *base_addr;  /* actual address returned by mmap() */
    size_t total_len;  /* actual length passed to mmap() (len + slop) */
} mmap_info_t;

#define MMAP_MAGIC_TYPE PERL_MAGIC_ext

static int mmap_magic_free(pTHX_ SV *sv, MAGIC *mg) {
    mmap_info_t *info = (mmap_info_t *) mg->mg_ptr;
    if (info) {
        if (info->base_addr) {
            munmap((MMAP_RETTYPE) info->base_addr, info->total_len);
            info->base_addr = NULL;
        }
        Safefree(info);
        mg->mg_ptr = NULL;
    }
    return 0;
}

static MGVTBL mmap_magic_vtbl = {
    0,                /* get */
    0,                /* set */
    0,                /* len */
    0,                /* clear */
    mmap_magic_free,  /* free */
    0,                /* copy */
    0,                /* dup */
    0                 /* local */
};

/* Find our mmap magic on an SV, or NULL if not present */
static MAGIC *find_mmap_magic(SV *sv) {
    MAGIC *mg;
    if (SvTYPE(sv) >= SVt_PVMG) {
        for (mg = SvMAGIC(sv); mg; mg = mg->mg_moremagic) {
            if (mg->mg_type == MMAP_MAGIC_TYPE && mg->mg_virtual == &mmap_magic_vtbl)
                return mg;
        }
    }
    return NULL;
}

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
	      if (off >= st.st_size) {
	          croak("mmap: offset (%"IVdf") is at or beyond end of file (size %"IVdf")", (IV)off, (IV)st.st_size);
	      }
	      len = st.st_size - off;
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
	SvLEN_set(var, 0);   /* must be 0 so Perl won't Safefree() the mmap'd pointer */
	SvPOK_only(var);

        /* Attach magic to handle munmap on cleanup */
        {
            mmap_info_t *info;
            MAGIC *mg;
            Newxz(info, 1, mmap_info_t);
            info->base_addr = (void *) addr;
            info->total_len = len + slop;
            mg = sv_magicext(var, NULL, MMAP_MAGIC_TYPE, &mmap_magic_vtbl,
                             (const char *) info, 0);
            mg->mg_flags |= MGf_LOCAL;
        }

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

        {
            MAGIC *mg = find_mmap_magic(var);
            if (mg) {
                mmap_info_t *info = (mmap_info_t *) mg->mg_ptr;
                if (munmap((MMAP_RETTYPE) info->base_addr, info->total_len) == -1) {
                    croak("munmap failed! errno %d %s\n", errno, strerror(errno));
                    return;
                }
                info->base_addr = NULL;  /* prevent double munmap in magic free */
            } else {
                /* fallback for hardwire'd or legacy variables without magic */
                /* SvLEN > 0 means this is a regular Perl string, not mmap'd */
                if (SvLEN(var) != 0) {
                    errno = EINVAL;
                    croak("munmap failed! errno %d %s\n", errno, strerror(errno));
                    return;
                }
                if (munmap((MMAP_RETTYPE) SvPVX(var), SvCUR(var)) == -1) {
                    croak("munmap failed! errno %d %s\n", errno, strerror(errno));
                    return;
                }
            }
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

        /* For tied objects: DESTROY receives the blessed reference (\$mmap_sv),
         * not the mmap'd SV itself.  Dereference to reach the actual mapping. */
        if (SvROK(var))
            var = SvRV(var);

        {
            MAGIC *mg = find_mmap_magic(var);
            if (mg) {
                mmap_info_t *info = (mmap_info_t *) mg->mg_ptr;
                if (info->base_addr) {
                    if (munmap((MMAP_RETTYPE) info->base_addr, info->total_len) == -1) {
                        croak("munmap failed! errno %d %s\n", errno, strerror(errno));
                        return;
                    }
                    info->base_addr = NULL;
                }
            } else {
                /* SvLEN > 0 means this is a regular Perl string, not mmap'd */
                if (SvLEN(var) != 0)
                    return;
                if (munmap((MMAP_RETTYPE) SvPVX(var), SvCUR(var)) == -1) {
                    croak("munmap failed! errno %d %s\n", errno, strerror(errno));
                    return;
                }
            }
        }
        SvREADONLY_off(var);
        SvPVX(var) = 0;
        SvCUR_set(var, 0);
        SvLEN_set(var, 0);
        SvOK_off(var);
        /* printf("destroy ran fine, thanks\n"); */
        ST(0) = &PL_sv_yes;
