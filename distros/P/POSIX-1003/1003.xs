#define PERL_EXT_POSIX_1003

#include "EXTERN.h"

/* We need our hands on the pure config, because CORE/perl.h makes
   some "smart" changes :(

   For now, we believe CORE/config.h for the following variables:
    I_UNISTD
    I_FCNTL
    I_POLL
    I_SYS_POLL
    I_SYS_RESOURCE
    I_ULIMIT

    HAS_FCNTL
    HAS_SETEUID
    HAS_SETREUID
    HAS_SETREGID
    HAS_SETRESGID
    HAS_SETRESUID
    HAS_GETGROUPS
    HAS_SETGROUPS
    HAS_POLL
    HAS_STRERROR
 */

#ifdef PERL_MICRO
#  include "uconfig.h"
#elif USE_CROSS_COMPILE
#  include "xconfig.h"
#else
#  include "config.h"
#endif

/* Get Perl's smartness
  
   We like only to provide setre[ug]id when it is pure, not a rewrite
   to getres[ug]id.  There are too many system dependencies/bug etc
   in these library functions to cover it up.
 */

#ifdef HAS_SETREUID
#define _HAS_SETREUID
#endif

#ifdef HAS_SETREGID
#define _HAS_SETREGID
#endif

#include "perl.h"

#ifdef _HAS_SETREUID
#undef _HAS_SETREUID
#undef HAS_SETREUID
#endif

#ifdef _HAS_SETREGID
#undef _HAS_SETREGID
#undef HAS_SETREGID
#endif

/* Now some Perl-guts
 */

#include "XSUB.h"

/* My own extensions
   Overrule via files in the "system" sub-directory of this distribution.
 */

#ifndef HAS_CONFSTR
#define HAS_CONFSTR
#endif

#ifndef HAS_ULIMIT
#define HAS_ULIMIT
#endif

#ifndef HAS_RLIMIT
#define HAS_RLIMIT
#endif

#ifndef HAS_MKNOD
#define HAS_MKNOD
#endif

#ifndef HAS_STRSIGNAL
#define HAS_STRSIGNAL
#endif

#ifndef HAS_SETUID
#define HAS_SETUID
#endif

#ifndef CACHE_UID
#if PERL_VERSION < 15 || PERL_VERSION == 15 && PERL_SUBVERSION < 8
#define CACHE_UID
#endif
#endif

#ifdef  HAS_FCNTL
#  ifndef HAS_FCNTL_OWN_EX
#  define HAS_FCNTL_OWN_EX
#  endif
#endif

#ifndef HAS_FLOCK
#define HAS_FLOCK
#endif

#ifndef HAS_LOCKF
#define HAS_LOCKF
#endif

#ifndef HAS_FTRUNCATE
#define HAS_FTRUNCATE
#endif

/*
 * work-arounds for various operating systems
 */

#include "system.c"

#ifdef I_UNISTD
#include <unistd.h>
#endif

#ifdef I_FCNTL
#include <fcntl.h>
#endif

#ifdef HAS_ULIMIT
#  ifdef  I_ULIMIT
#  define I_ULIMIT
#  endif
#  include <ulimit.h>
#endif

#ifdef I_SYS_RESOURCE
#include <sys/resource.h>
#endif

#ifdef I_POLL
#include <poll.h>
#else
#ifdef I_SYS_POLL
#include <sys/poll.h>
#endif
#endif

HV * sc_table = NULL;
HV *
fill_sysconf()
{   if(sc_table) return sc_table;

    sc_table = newHV();
#include "sysconf.c"
    return sc_table;
}

HV * cs_table = NULL;
HV *
fill_confstr()
{   if(cs_table) return cs_table;

    cs_table = newHV();
#include "confstr.c"
    return cs_table;
}

HV * pc_table = NULL;
HV *
fill_pathconf()
{   if(pc_table) return pc_table;

    pc_table = newHV();
#include "pathconf.c"
    return pc_table;
}

HV * sig_table = NULL;
HV *
fill_signals()
{   if(sig_table) return sig_table;

    sig_table = newHV();
#include "signals.c"
    return sig_table;
}

HV * pr_table = NULL;
HV *
fill_properties()
{   if(pr_table) return pr_table;

    pr_table = newHV();
#include "properties.c"
    return pr_table;
}

HV * fdio_table = NULL;
HV *
fill_fdio()
{   if(fdio_table) return fdio_table;

    fdio_table = newHV();
#include "fdio.c"
    return fdio_table;
}

HV * fcntl_table = NULL;
HV *
fill_fcntl()
{   if(fcntl_table) return fcntl_table;

    fcntl_table = newHV();
#include "fcntl.c"
    return fcntl_table;
}

HV * fsys_table = NULL;
HV *
fill_fsys()
{   if(fsys_table) return fsys_table;

    fsys_table = newHV();
#include "fsys.c"
    return fsys_table;
}

HV * ul_table = NULL;
HV *
fill_ulimit()
{   if(ul_table) return ul_table;

    ul_table = newHV();
#include "ulimit.c"
    return ul_table;
}

HV * rl_table = NULL;
HV *
fill_rlimit()
{   if(rl_table) return rl_table;

    rl_table = newHV();
#include "rlimit.c"
    return rl_table;
}

HV * poll_table = NULL;
HV *
fill_poll()
{   if(poll_table) return poll_table;

    poll_table = newHV();
#include "poll.c"
    return poll_table;
}

HV * errno_table = NULL;
HV *
fill_errno()
{   if(errno_table) return errno_table;

    errno_table = newHV();
#include "errno.c"
    return errno_table;
}

MODULE = POSIX::1003	PACKAGE = POSIX::1003::Sysconf

HV *
sysconf_table()
    PROTOTYPE:
    CODE:
	RETVAL = fill_sysconf();
    OUTPUT:
	RETVAL

MODULE = POSIX::1003	PACKAGE = POSIX::1003::Signals

HV *
signals_table()
    PROTOTYPE:
    CODE:
	RETVAL = fill_signals();
    OUTPUT:
	RETVAL

SV *
_strsignal(signr)
	int		signr;
    PROTOTYPE: $
    PREINIT:
	char 		* buf;
    CODE:
#ifdef HAS_STRSIGNAL
	buf    = strsignal(signr);
	RETVAL = buf==NULL ? &PL_sv_undef : newSVpv(buf, 0);
#else
	errno  = ENOSYS;
	RETVAL = &PL_sv_undef;
#endif
    OUTPUT:
	RETVAL

MODULE = POSIX::1003	PACKAGE = POSIX::1003::Confstr

HV *
confstr_table()
    PROTOTYPE:
    CODE:
	RETVAL = fill_confstr();
    OUTPUT:
	RETVAL

SV *
_confstr(name)
	int		name;
    PROTOTYPE: $
    PREINIT:
	char 		buf[4096];
	STRLEN		len;
    CODE:
#ifdef HAS_CONFSTR
	len    = confstr(name, buf, sizeof(buf));
	RETVAL = len==0 ? &PL_sv_undef : newSVpv(buf, len-1);
#else
	errno  = ENOSYS;
	RETVAL = &PL_sv_undef;
#endif
    OUTPUT:
	RETVAL

MODULE = POSIX::1003	PACKAGE = POSIX::1003::Pathconf

HV *
pathconf_table()
    PROTOTYPE:
    CODE:
	RETVAL = fill_pathconf();
    OUTPUT:
	RETVAL

MODULE = POSIX::1003	PACKAGE = POSIX::1003::FdIO

HV *
fdio_table()
    PROTOTYPE:
    CODE:
	RETVAL = fill_fdio();
    OUTPUT:
	RETVAL

SV *
truncfd(fd, l = 0)
        int             fd;
        off_t           l;
    PROTOTYPE: $;$
    PREINIT:
        long            result;
    CODE:
#ifdef HAS_FTRUNCATE
        result = ftruncate(fd, l);
        RETVAL = result==-1 ? &PL_sv_undef : newSViv(result);
#else
        errno  = ENOSYS;
        RETVAL = &PL_sv_undef;
#endif
    OUTPUT:
        RETVAL

MODULE = POSIX::1003	PACKAGE = POSIX::1003::FS

HV *
fsys_table()
    PROTOTYPE:
    CODE:
	RETVAL = fill_fsys();
    OUTPUT:
	RETVAL

MODULE = POSIX::1003	PACKAGE = POSIX::1003::Properties

HV *
property_table()
    PROTOTYPE:
    CODE:
	RETVAL = fill_properties();
    OUTPUT:
	RETVAL

MODULE = POSIX::1003	PACKAGE = POSIX::1003::Limit

HV *
ulimit_table()
    PROTOTYPE:
    CODE:
	RETVAL = fill_ulimit();
    OUTPUT:
	RETVAL

HV *
rlimit_table()
    PROTOTYPE:
    CODE:
	RETVAL = fill_rlimit();
    OUTPUT:
	RETVAL

SV *
_ulimit(cmd, value)
	int		cmd;
	long		value;
    PROTOTYPE: $$
    PREINIT:
	long		result;
    CODE:
#ifdef HAS_ULIMIT
	result = ulimit(cmd, value);
	RETVAL = result==-1 ? &PL_sv_undef : newSViv(result);
#else
	errno  = ENOSYS;
	RETVAL = &PL_sv_undef;
#endif
    OUTPUT:
	RETVAL

#ifdef HAS_RLIMIT
#ifdef HAS_RLIMIT_64

void
_getrlimit(resource)
	int		resource;
    PROTOTYPE: $
    PREINIT:
	struct rlimit64	rlim;
	int		result;
    PPCODE:
	/* on linux, rlim64_t is a __UQUAD_TYPE */
	result = getrlimit64(resource, &rlim);
	PUSHs(sv_2mortal(newSVuv(rlim.rlim_cur)));
	PUSHs(sv_2mortal(newSVuv(rlim.rlim_max)));
	PUSHs(result==-1 ? &PL_sv_no : &PL_sv_yes);

SV *
_setrlimit(resource, cur, max)
	int		resource;
	unsigned long   cur;
	unsigned long	max;
    PROTOTYPE: $$$
    PREINIT:
	struct rlimit64	rlim;
	int		result;
    CODE:
	rlim.rlim_cur = cur;
	rlim.rlim_max = max;
	result = setrlimit64(resource, &rlim);
	RETVAL = result==-1 ? &PL_sv_no : &PL_sv_yes;
    OUTPUT:
	RETVAL

#else /* HAS_RLIMIT_64 */


void
_getrlimit(resource)
	int		resource;
    PROTOTYPE: $
    PREINIT:
	struct rlimit	rlim;
	int		result;
    PPCODE:
	/* on linux, rlim64_t is a __ULONGWORD_TYPE */
	result = getrlimit(resource, &rlim);
	PUSHs(sv_2mortal(newSVuv(rlim.rlim_cur)));
	PUSHs(sv_2mortal(newSVuv(rlim.rlim_max)));
	PUSHs(result==-1 ? &PL_sv_no : &PL_sv_yes);

SV *
_setrlimit(resource, cur, max)
	int		resource;
	unsigned long   cur;
	unsigned long	max;
    PROTOTYPE: $$$
    PREINIT:
	struct rlimit	rlim;
	int		result;
    CODE:
	rlim.rlim_cur = cur;
	rlim.rlim_max = max;
	result = setrlimit(resource, &rlim);
	RETVAL = result==-1 ? &PL_sv_no : &PL_sv_yes;
    OUTPUT:
	RETVAL

#endif /* HAS_RLIMIT_64 */
#else  /* HAS_RLIMIT */

void
_getrlimit(resource)
	int		resource;
    PROTOTYPE: $
    PPCODE:
	PUSHs(&PL_sv_undef);
	PUSHs(&PL_sv_undef);
	PUSHs(&PL_sv_no);

SV *
_setrlimit(resource, cur, max)
	int		resource;
	unsigned long   cur;
	unsigned long	max;
    PROTOTYPE: $$$
    CODE:
	RETVAL = &PL_sv_no;
    OUTPUT:
	RETVAL

#endif /* HAS_RLIMIT */


MODULE = POSIX::1003	PACKAGE = POSIX::1003::FS

#ifdef HAS_SYSMKDEV
#include <sys/mkdev.h>
#endif

dev_t
makedev(dev_t major, dev_t minor)
    PROTOTYPE: $$

dev_t
major(dev_t dev)
    PROTOTYPE: $

dev_t
minor(dev_t dev)
    PROTOTYPE: $

int
mknod(filename, mode, dev)
	char *  filename
	mode_t  mode
	dev_t   dev
    CODE:
#ifdef HAS_MKNOD
	RETVAL = mknod(filename, mode, dev);
#else
	errno  = ENOSYS;
	RETVAL = &PL_sv_undef;
#endif
    OUTPUT:
	RETVAL


MODULE = POSIX::1003	PACKAGE = POSIX::1003::Events

HV *
poll_table()
    PROTOTYPE:
    CODE:
	RETVAL = fill_poll();
    OUTPUT:
	RETVAL


HV *
_poll(handles, timeout)
	HV *	handles;
	int	timeout;
    PREINIT:
	struct pollfd * fds;
	HV            * ret;
	char          * key;
        char            key_str[8];
	int             rc;
        HE            * entry;
        I32		len;
	int		j;
    PPCODE:
#ifdef HAS_POLL
	const int nfd = hv_iterinit(handles);
	Newx(fds, nfd, struct pollfd);
	for(j=0; j < nfd; j++)
        {   entry          = hv_iternext(handles);
	    key            = hv_iterkey(entry, &len);
	    key[len]       = 0;
            fds[j].fd      = atoi(key_str);
	    fds[j].events  = SvUV(hv_iterval(handles, entry));
	    fds[j].revents = 0;    // returned events
	}
	rc = poll(fds, nfd, timeout);
        if(rc==-1)
        {   XPUSHs(&PL_sv_undef);
        }
        else
	{   ret = newHV();
            if(rc > 0)
            {   for(j=0; j < nfd; j++)
                {   if(fds[j].revents)
	            {   sprintf((char *)key_str, "%d", fds[j].fd);
                        (void)hv_store(ret, key_str, strlen(key_str), newSVuv(fds[j].revents), 0);
                    }
                }
	    }
	    XPUSHs((SV*)ret);
	}
	XSRETURN(1);
#else
	errno = ENOSYS;
        XPUSHs(&PL_sv_undef);
#endif

MODULE = POSIX::1003	PACKAGE = POSIX::1003::User

void
setuid(uid)
        uid_t           uid
    PROTOTYPE: $
    INIT:
	int		result;
    PPCODE:
#ifdef HAS_SETUID
	result  = setuid(uid);
#ifdef CACHE_UID
	PL_uid  = getuid();
	PL_euid = geteuid();
#endif
#else
	errno   = ENOSYS;
	result  = -1;
#endif
	XPUSHs(result==-1 ? &PL_sv_undef : sv_2mortal(newSViv(result)));

uid_t
getuid()
    PROTOTYPE:
    INIT:
	int		result;
    PPCODE:
#ifdef HAS_SETUID
	result = getuid();
#else
	errno  = ENOSYS;
	result = -1;
#endif
	XPUSHs(result==-1 ? &PL_sv_undef : sv_2mortal(newSViv(result)));

int
setgid(gid)
        gid_t           gid
    PROTOTYPE: $
    INIT:
	int		result;
    PPCODE:
#ifdef HAS_SETUID
	result = setgid(gid);
#else
	errno  = ENOSYS;
	result = -1;
#endif
	XPUSHs(result==-1 ? &PL_sv_undef : sv_2mortal(newSViv(result)));

gid_t
getgid()
    PROTOTYPE:
    INIT:
	int		result;
    PPCODE:
#ifdef HAS_SETUID
	result = getgid();
#ifdef CACHE_UID
	PL_gid  = getgid();
	PL_egid = getegid();
#endif
#else
	errno  = ENOSYS;
	result = -1;
#endif
	XPUSHs(result==-1 ? &PL_sv_undef : sv_2mortal(newSViv(result)));


int
seteuid(euid)
        uid_t           euid
    PROTOTYPE: $
    INIT:
	int		result;
    PPCODE:
#ifdef HAS_SETEUID
	result  = seteuid(euid);
#ifdef CACHE_UID
	PL_euid = geteuid();
#endif
#else
	errno   = ENOSYS;
	result  = -1;
#endif
	XPUSHs(result==-1 ? &PL_sv_undef : sv_2mortal(newSViv(result)));

uid_t
geteuid()
    PROTOTYPE:
    INIT:
	int		result;
    PPCODE:
#ifdef HAS_SETEUID
	result  = geteuid();
#ifdef CACHE_UID
	PL_egid = getegid();
#endif
#else
	errno   = ENOSYS;
	result  = -1;
#endif
	XPUSHs(result==-1 ? &PL_sv_undef : sv_2mortal(newSViv(result)));


int
setegid(egid)
        gid_t           egid
    PROTOTYPE: $
    INIT:
	int		result;
    PPCODE:
#ifdef HAS_SETEUID
	result = setegid(egid);
#else
	errno  = ENOSYS;
	result = -1;
#endif
	XPUSHs(result==-1 ? &PL_sv_undef : sv_2mortal(newSViv(result)));

gid_t
getegid()
    PROTOTYPE:
    INIT:
	int		result;
    PPCODE:
#ifdef HAS_SETEUID
	result = getegid();
#else
	errno  = ENOSYS;
	result = -1;
#endif
	XPUSHs(result==-1 ? &PL_sv_undef : sv_2mortal(newSViv(result)));


int
setreuid(ruid, euid)
        uid_t           ruid
        uid_t           euid
    PROTOTYPE: $$
    INIT:
	int		result;
    PPCODE:
#ifdef HAS_SETREUID
	result  = setreuid(ruid, euid);
#ifdef CACHE_UID
	PL_uid  = getuid();
	PL_euid = geteuid();
#endif
#else
	errno   = ENOSYS;
	result  = -1;
#endif
	XPUSHs(result==-1 ? &PL_sv_undef : sv_2mortal(newSViv(result)));

int
setregid(rgid, egid)
        gid_t           rgid
        gid_t           egid
    PROTOTYPE: $$
    INIT:
	int		result;
    PPCODE:
#ifdef HAS_SETREGID
	result = setregid(rgid, egid);
#ifdef CACHE_UID
	PL_gid  = getgid();
	PL_egid = getegid();
#endif
#else
	errno  = ENOSYS;
	result = -1;
#endif
	XPUSHs(result==-1 ? &PL_sv_undef : sv_2mortal(newSViv(result)));


int
setresuid(ruid, euid, suid)
        uid_t           ruid
        uid_t           euid
        uid_t           suid
    PROTOTYPE: $$$
    INIT:
	int		result;
    PPCODE:
#ifdef HAS_SETRESUID
	result  = setresuid(ruid, euid, suid);
#ifdef CACHE_UID
	PL_uid  = getuid();
	PL_euid = geteuid();
#endif
#else
	errno  = ENOSYS;
	result = -1;
#endif
	XPUSHs(result==-1 ? &PL_sv_undef : sv_2mortal(newSViv(result)));

void
getresuid()
    PROTOTYPE:
    INIT:
        uid_t           ruid;
        uid_t           euid;
        uid_t           suid;
	int		result;
    PPCODE:
#ifdef HAS_SETRESUID
	result = getresuid(&ruid, &euid, &suid);
	if(result==0) {
	    XPUSHs(sv_2mortal(newSVuv(ruid)));
	    XPUSHs(sv_2mortal(newSVuv(euid)));
	    XPUSHs(sv_2mortal(newSVuv(suid)));
	}
#else
	errno  = ENOSYS;
#endif


int
setresgid(rgid, egid, sgid)
        gid_t           rgid
        gid_t           egid
        gid_t           sgid
    PROTOTYPE: $$$
    INIT:
	int		result;
    PPCODE:
#ifdef HAS_SETRESGID
	result = setresgid(rgid, egid, sgid);
#ifdef CACHE_UID
	PL_gid  = getgid();
	PL_egid = getegid();
#endif
#else
	errno  = ENOSYS;
	result = -1;
#endif
	XPUSHs(result==-1 ? &PL_sv_undef : sv_2mortal(newSViv(result)));

void
getresgid()
    PROTOTYPE:
    INIT:
        gid_t           rgid;
        gid_t           egid;
        gid_t           sgid;
	int		result;
   PPCODE:
#ifdef HAS_SETRESUID
	result = getresgid(&rgid, &egid, &sgid);
	if(result==0) {
	    XPUSHs(sv_2mortal(newSVuv(rgid)));
	    XPUSHs(sv_2mortal(newSVuv(egid)));
	    XPUSHs(sv_2mortal(newSVuv(sgid)));
	}
#else
	errno  = ENOSYS;
#endif

void
getgroups()
    PROTOTYPE:
    INIT:
	gid_t	grouplist[NGROUPS_MAX+1];
	int	nr_groups;
    PPCODE:
#ifdef HAS_GETGROUPS
	nr_groups = getgroups(NGROUPS_MAX+1, grouplist);
	if(nr_groups >= 0) {
	    int nr;
	    for(nr = 0; nr < nr_groups; nr++)
	        XPUSHs(sv_2mortal(newSVuv(grouplist[nr])));
	}
#else
	errno  = ENOSYS;
#endif

void
setgroups(...)
    PROTOTYPE: @
    INIT:
	int   index;
	gid_t groups[NGROUPS_MAX];
	int   result;
    CODE:
#ifdef HAS_SETGROUPS
        for(index = 0; index < items && index < NGROUPS_MAX; index++)
	{   groups[index] = (gid_t)SvUV(ST(index));
	}
	result = setgroups(index, groups);
	XPUSHs(result==-1 ? &PL_sv_no : &PL_sv_yes);
#else
	errno  = ENOSYS;
#endif


MODULE = POSIX::1003	PACKAGE = POSIX::1003::Errno

HV *
errno_table()
    PROTOTYPE:
    CODE:
	RETVAL = fill_errno();
    OUTPUT:
	RETVAL

SV *
_strerror(int errnr)
    PROTOTYPE: $
    INIT:
	char * buf;
    CODE:
#ifdef HAS_STRERROR
        buf    = strerror(errnr);
        RETVAL = buf==NULL ? &PL_sv_undef : newSVpv(buf, 0);
#else
        errno  = ENOSYS;
        RETVAL = &PL_sv_undef;
#endif
    OUTPUT:
	RETVAL


MODULE = POSIX::1003	PACKAGE = POSIX::1003::Fcntl

HV *
fcntl_table()
    PROTOTYPE:
    CODE:
	RETVAL = fill_fcntl();
    OUTPUT:
	RETVAL

SV *
_fcntl(fd, function, value)
        int   fd
        SV *  function
        int   value
    PROTOTYPE: $$$
    INIT:
	int   ret;
    CODE:
#ifdef HAS_FCNTL
	if(SvOK(function))
        {   ret = fcntl(fd, SvIV(function), value);
	    RETVAL = ret==-1 ? &PL_sv_undef : newSVuv(ret);
	}
	else
	{   /* catch-all for all unsupported functions */
            errno  = ENOSYS;
            RETVAL = &PL_sv_undef;
	}
#else
        errno  = ENOSYS;
        RETVAL = &PL_sv_undef;
#endif
    OUTPUT:
	RETVAL

SV *
_lock(fd, function, param)
        int   fd
        int   function
        SV *  param
    PROTOTYPE: $$$
    INIT:
        struct flock locker;
        SV **type, **whence, **start, **len;
        HV *fl, *fs;
    CODE:
#ifdef HAS_FCNTL
        fs     = (HV *)SvRV(param);
        type   = hv_fetch(fs, "type",   4, 0);
        whence = hv_fetch(fs, "whence", 6, 0);
        start  = hv_fetch(fs, "start",  5, 0);
        len    = hv_fetch(fs, "len",    3, 0);

        locker.l_type   = SvIV(*type  );
        locker.l_whence = SvIV(*whence);
        locker.l_start  = SvIV(*start );
        locker.l_len    = SvIV(*len   );
        locker.l_pid    = 0;

        if(fcntl(fd, function, &locker)==-1)
            XSRETURN_UNDEF;

	fl = newHV();
        (void)hv_store(fl, "type",   4, newSViv(locker.l_type  ), 0);
        (void)hv_store(fl, "whence", 6, newSViv(locker.l_whence), 0);
        (void)hv_store(fl, "start",  5, newSViv(locker.l_start ), 0);
        (void)hv_store(fl, "len",    3, newSViv(locker.l_len   ), 0);

	if(function==F_GETLK)
            (void)hv_store(fl, "pid",3, newSViv(locker.l_pid   ), 0);

        RETVAL = newRV_noinc((SV *)fl);
#else
        errno  = ENOSYS;
        RETVAL = &PL_sv_undef;
#endif
    OUTPUT:
        RETVAL

void
_own_ex(function, fd, pid, type)
        int   function
        int   fd
        pid_t pid
        int   type
    PROTOTYPE: $$$$
    INIT:
    PPCODE:
#ifdef HAS_FCNTL_OWN_EX
        {   struct f_owner_ex ex;
	    ex.type  = type;
            ex.pid   = pid;

            if(fcntl(fd, function, &ex)==-1)
                return;

            XPUSHs(sv_2mortal(newSVuv(ex.type)));
            XPUSHs(sv_2mortal(newSVuv(ex.pid)));
        }
#else
        errno  = ENOSYS;
#endif

SV *
_flock(fd, function)
        int   fd
        int   function
    PROTOTYPE: $$
    INIT:
	int   ret;
    CODE:
#ifdef HAS_FLOCK
        ret    = flock(fd, function);
	RETVAL = ret==-1 ? &PL_sv_undef : newSVuv(ret);
#else
        errno  = ENOSYS;
        RETVAL = &PL_sv_undef;
#endif
    OUTPUT:
	RETVAL

SV *
_lockf(fd, function, len)
        int   fd
        int   function
	off_t len
    PROTOTYPE: $$$
    INIT:
	int   ret;
    CODE:
#ifdef HAS_LOCKF
        ret    = lockf(fd, function, len);
	RETVAL = ret==-1 ? &PL_sv_undef : newSVuv(ret);
#else
        errno  = ENOSYS;
        RETVAL = &PL_sv_undef;
#endif
    OUTPUT:
	RETVAL
