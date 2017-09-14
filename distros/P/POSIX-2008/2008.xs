#ifndef _GNU_SOURCE
#define _GNU_SOURCE
#endif

#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#ifdef PERL_IMPLICIT_SYS
#undef open
#endif

#define NEED_sv_2pv_flags
#include "ppport.h"

#include <complex.h>
#include <ctype.h>
#ifdef I_DIRENT
#include <dirent.h>
#endif
#ifdef I_DLFCN
#include <dlfcn.h>
#endif
#include <errno.h>
#ifdef I_FLOAT
#include <float.h>
#endif
#ifdef I_FCNTL
#include <fcntl.h>
#endif
#include <fenv.h>
#include <fnmatch.h>
#ifdef I_INTTYPES
#include <inttypes.h>
#endif
#include <libgen.h>
#ifdef I_LIMITS
#include <limits.h>
#endif
#ifdef I_MATH
#include <math.h>
#endif
#ifndef __CYGWIN__
#include <nl_types.h>
#endif
#include <signal.h>
#ifdef I_STDLIB
#include <stdlib.h>
#endif
#ifdef I_STRING
#include <string.h>
#endif
#include <strings.h>
#ifdef I_SUNMATH
#include <sunmath.h>
#endif
#ifdef I_SYS_PARAM
#include <sys/param.h>
#endif
#ifdef I_SYS_RESOURCE
#include <sys/resource.h>
#endif
#ifdef I_SYS_STAT
#include <sys/stat.h>
#endif
#ifdef I_SYS_TYPES
#include <sys/types.h>
#endif
#include <sys/uio.h>
#ifdef I_TIME
#include <time.h>
#endif
#ifdef I_UNISTD
#include <unistd.h>
#endif
#include <utmpx.h>

#ifndef HOST_NAME_MAX
#define HOST_NAME_MAX 255
#endif

#include "const-c.inc"

typedef int SysRet;   /* returns 0 as "0 but true" */
typedef int SysRet0;  /* returns 0 as 0 */
typedef int psx_fd_t; /* checks for file handle or descriptor via typemap */

/* is*() stuff borrowed from POSIX.xs */
typedef int (*isfunc_t)(int);
typedef void (*any_dptr_t)(void *);

static XSPROTO(is_common);
static XSPROTO(is_common)
{
    dXSARGS;
    if (items != 1)
#ifdef PERL_ARGS_ASSERT_CROAK_XS_USAGE
       croak_xs_usage(cv,  "charstring");
#else
       croak("Usage: isX(charstring)");
#endif

    {
        dXSTARG;
        STRLEN  len;
        int     RETVAL;
        unsigned char *s = (unsigned char *) SvPV(ST(0), len);
        unsigned char *e = s + len;
        isfunc_t isfunc = (isfunc_t) XSANY.any_dptr;

        /* This is the real fix for RT#84680 */
        for (RETVAL = len ? 1 : 0; RETVAL && s < e; s++)
            if (!isfunc(*s))
                RETVAL = 0;
        XSprePUSH;
        PUSHi((IV)RETVAL);
    }
    XSRETURN(1);
}

static char *
_readlink50c(char *path, int *dirfd) {
  /*
   * CORE::readlink() is broken because it unnecessarily uses a fixed-size
   * result buffer. We use a dynamically growing buffer instead, leaving it
   * up to the file system how long a symlink may be.
   */
  size_t bufsize = 256;
  ssize_t linklen;
  char *buf;

  errno = 0;

  Newxc(buf, bufsize, char, char);
  if (!buf)
    return NULL;

  while (1) {
    if (dirfd == NULL)
      linklen = readlink(path, buf, bufsize);
    else
      linklen = readlinkat(*dirfd, path, buf, bufsize);

    if (linklen >= 0) {
      if ((size_t)linklen < bufsize || linklen == SSIZE_MAX) {
        buf[linklen] = '\0';
        return buf;
      }
    }
    else if (errno != ERANGE) {
      /* gnulib says, on some systems ERANGE means that bufsize is too small */
      Safefree(buf);
      return NULL;
    }

    bufsize <<= 1;

    Renew(buf, bufsize, char);
    if (buf == NULL)
      return NULL;
  }
}

static void
_free_iov(struct iovec *iov, int cnt) {
  int i;

  if (iov)
    for (i = 0; i < cnt; i++)
      if (iov[i].iov_base)
        Safefree(iov[i].iov_base);
}

static int
_readv50c(pTHX_ int fd, SV *buffers, AV *sizes, SV *offset) {
  int iovcnt, i, rv;
  struct iovec *iov;
  void *iov_base;
  /* iov_len is a size_t but it is an error if the sum of the iov_len values
     exceeds SSIZE_MAX ... Dafuq? */
  size_t iov_len, iov_sum, sv_cur;

#ifdef __CYGWIN__
  if (offset != NULL)
    return -1;
#endif
  
  for (i = 0; i < 2; i++) {
    if (SvROK(buffers)) {
      buffers = SvRV(buffers);
      if (SvTYPE(buffers) == SVt_PVAV)
        break;
      if (i == 0)
        continue;
    }
    croak("buffers is not an array reference");
  }

  iovcnt = av_len(sizes) + 1;
  if (iovcnt <= 0)
    return 0;

  Newxz(iov, iovcnt, struct iovec);
  if (!iov)
    return -1;

  for (i = 0; i < iovcnt; i++) {
    SV **size = av_fetch(sizes, i, 0);
    if (size && SvOK(*size)) {
      iov_len = SvUV(*size);
      if (iov_len) {
        Newx(iov_base, iov_len, char);
        if (!iov_base) {
          _free_iov(iov, i);
          Safefree(iov);
          return -1;
        }
        iov[i].iov_base = iov_base;
        iov[i].iov_len = iov_len;
      }
    }
  }

  if (offset == NULL)
    rv = readv(fd, iov, iovcnt);
#ifndef __CYGWIN__
  else
    rv = preadv(fd, iov, iovcnt, SvOK(offset) ? SvUV(offset) : 0);
#endif

  if (rv <= 0) {
    _free_iov(iov, iovcnt);
    Safefree(iov);
    return rv;
  }

  for (iov_sum = 0, i = 0; i < iovcnt; i++) {
    iov_base = iov[i].iov_base;
    iov_len = iov[i].iov_len;
    iov_sum += iov_len;

    if (iov_sum <= rv)
      /* current buffer filled completely */
      sv_cur = iov_len;
    else if (iov_sum - rv < iov_len)
      /* current buffer filled partly */
      sv_cur = iov_len - (iov_sum - rv);
    else {
      /* no data was read into remaining buffers */
      _free_iov(iov + i, iovcnt - i);
      Safefree(iov);
      return rv;
    }

    SV *tmp_sv = iov_len ? newSV_type(SVt_PV) : newSVpvn("", 0);

    if (!tmp_sv) {
      _free_iov(iov + i, iovcnt - i);
      Safefree(iov);
      return -1;
    }

    if (iov_len) {
      if (sv_cur != iov_len)
        Renew(iov_base, sv_cur, char);
      SvPV_set(tmp_sv, iov_base);
      SvCUR_set(tmp_sv, sv_cur);
      SvLEN_set(tmp_sv, sv_cur);
      SvPOK_only(tmp_sv);
      SvTAINTED_on(tmp_sv);
    }

    if (!av_store((AV*)buffers, i, tmp_sv))
      SvREFCNT_dec(tmp_sv);
  }

  Safefree(iov);
  return rv;
}

static int
_writev50c(pTHX_ int fd, AV *buffers, SV *offset) {
  struct iovec *iov;
  struct iovec iov_elt;
  int i, rv;

#ifdef __CYGWIN__
  if (offset != NULL)
    return -1;
#endif
  
  const int bufcnt = av_len(buffers) + 1;
  if (bufcnt <= 0)
    return 0;

  Newxc(iov, bufcnt, struct iovec, struct iovec);
  if (!iov)
    return -1;

  int iovcnt = 0;

  for (i = 0; i < bufcnt; i++) {
    SV **av_elt = av_fetch(buffers, i, 0);
    if (av_elt && SvOK(*av_elt)) {
      iov_elt.iov_base = (void*)SvPV(*av_elt, iov_elt.iov_len);
      if (iov_elt.iov_len)
        iov[iovcnt++] = iov_elt;
    }
  }

  if (iovcnt == 0)
    rv = 0;
  else if (offset == NULL) 
    rv = writev(fd, iov, iovcnt);
#ifndef __CYGWIN__
  else
    rv = pwritev(fd, iov, iovcnt, SvOK(offset) ? SvUV(offset) : 0);
#endif

  Safefree(iov);
  return rv;
}

static const char*
flags2raw(int flags) {
  int accmode = flags & O_ACCMODE;
  if (accmode == O_RDONLY)
    return "rb";
  else if (flags & O_APPEND)
    return (accmode == O_RDWR) ? "a+b" : "ab";
  else if (accmode == O_WRONLY)
    return "wb";
  else if (accmode == O_RDWR)
    return "r+b";
  else
    return "";
}

#if PERL_BCDVERSION >= 0x5008005
static int
psx_looks_like_number(pTHX_ SV *sv) {
  return looks_like_number(sv);
}
#else
static int
psx_looks_like_number(pTHX_ SV *sv) {
  if (SvPOK(sv) || SvPOKp(sv))
    return looks_like_number(sv);
  else
    return (SvFLAGS(sv) & (SVf_NOK|SVp_NOK|SVf_IOK|SVp_IOK));
}
#endif

static int
psx_fileno(pTHX_ SV *sv) {
  IO *io;
  int fn = -1;

  if (SvOK(sv)) {
    if (psx_looks_like_number(aTHX_ sv))
      fn = SvIV(sv);
    else if ((io = sv_2io(sv))) {
      if (IoIFP(io))  /* from open() or sysopen() */
        fn = PerlIO_fileno(IoIFP(io));
      else if (IoDIRP(io))  /* from opendir() */
        fn = my_dirfd(IoDIRP(io));
    }
  }

  return fn;
}

#define PACKNAME "POSIX::2008"


MODULE = POSIX::2008    PACKAGE = POSIX::2008

PROTOTYPES: ENABLE

INCLUDE: const-xs.inc
  
long
a64l(char* s);

char*
l64a(long value);

void
abort();

unsigned
alarm(unsigned seconds);

NV
atof(char *str);

int
atoi(char *str);

long
atol(char *str);

NV
atoll(char *str);

char*
basename(char *path);

#ifndef __CYGWIN__
int
catclose(nl_catd catd);

char*
catgets(nl_catd catd, int set_id, int msg_id, char *dflt);

nl_catd
catopen(char *name, int oflag);

#else
void
catclose(...);
    PPCODE:
        croak("catclose() not available");

void
catgets(...);
    PPCODE:
        croak("catgets() not available");

void
catopen(...);
    PPCODE:
        croak("catopen() not available");

#endif

clock_t
clock();

#if !defined(CLOCK_REALTIME) || \
    (defined(__FreeBSD_version)  && __FreeBSD_version  < 1000000) || \
    (defined(__NetBSD_Version__) && __NetBSD_Version__ < 800000000)

void
clock_getcpuclockid(...);
    PPCODE:
        croak("clock_getcpuclockid() not available");

#else
clockid_t
clock_getcpuclockid(pid_t pid = PerlProc_getpid());
    INIT:
        clockid_t clock_id;
    CODE:
        if (clock_getcpuclockid(pid, &clock_id) != 0)
            XSRETURN_UNDEF;
        RETVAL = clock_id;
    OUTPUT:
        RETVAL

#endif

#ifndef CLOCK_REALTIME
void
clock_getres(...);
    PPCODE:
        croak("clock_getres() not available");

void
clock_gettime(...);
    PPCODE:
        croak("clock_gettime() not available");

void
clock_settime(...);
    PPCODE:
        croak("clock_settime() not available");

#else
void
clock_getres(clockid_t clock_id = CLOCK_REALTIME);
    ALIAS:
        clock_gettime = 1
    INIT:
        int ret;
        struct timespec res;
    PPCODE:
        if (ix == 0)
            ret = clock_getres(clock_id, &res);
        else
            ret = clock_gettime(clock_id, &res);
        if (ret == 0) {
            EXTEND(SP, 2);
            mPUSHi(res.tv_sec);
            mPUSHi(res.tv_nsec);
        }

int
clock_settime(clockid_t clock_id, time_t sec, long nsec);
    INIT:
        struct timespec tp = { sec, nsec };
    CODE:
        RETVAL = clock_settime(clock_id, &tp);
        if (RETVAL)
            XSRETURN_UNDEF;
    OUTPUT:
        RETVAL

#endif

#define RETURN_NANOSLEEP_REMAIN(ret) {                      \
    if (ret == 0 || errno == EINTR) {                       \
        if (GIMME_V != G_ARRAY)                             \
            mPUSHn(remain.tv_sec + remain.tv_nsec/(NV)1e9); \
        else {                                              \
            EXTEND(SP, 2);                                  \
            mPUSHi(remain.tv_sec);                          \
            mPUSHi(remain.tv_nsec);                         \
        }                                                   \
    }                                                       \
    else if (GIMME_V != G_ARRAY)                            \
        XSRETURN_UNDEF;                                     \
}

#if !defined(CLOCK_REALTIME) || \
    (defined(__FreeBSD_version) && __FreeBSD_version < 1101000) || \
    (defined(__NetBSD_Version__) && __NetBSD_Version__ < 700000000) || \
    defined(__OpenBSD__)

void
clock_nanosleep(...);
    PPCODE:
        croak("clock_nanosleep not available");

#else
void
clock_nanosleep(clockid_t clock_id, int flags, time_t sec, long nsec);
    INIT:
        const struct timespec request = { sec, nsec };
        struct timespec remain = { 0, 0 };
    PPCODE:
        errno = clock_nanosleep(clock_id, flags, &request, &remain);
        RETURN_NANOSLEEP_REMAIN(errno)

#endif

#ifdef HAS_NANOSLEEP
void
nanosleep(time_t sec, long nsec);
    INIT:
        struct timespec request = { sec, nsec };
        struct timespec remain = { 0, 0 };
        int ret;
    PPCODE:
        errno = 0;
        ret = nanosleep(&request, &remain);
        RETURN_NANOSLEEP_REMAIN(ret)

#else
void
nanosleep(...);
    PPCODE:
        croak("nanosleep() not available");
        
#endif

char *
confstr(int name);
    INIT:
        size_t len;
        char *buf = NULL;
    CODE:
        len = confstr(name, NULL, 0);
        if (len) {
            Newxc(buf, len, char, char);
            if (buf != NULL)
                confstr(name, buf, len);
        }
        RETVAL = buf;
    OUTPUT:
        RETVAL
    CLEANUP:
        if (buf != NULL)
            Safefree(buf);

char*
dirname(char *path);

int
dlclose(void *handle);

char *
dlerror();

void *
dlopen(char *file, int mode);

void *
dlsym(void *handle, char *name);

int
fegetround();

int
fesetround(int round);

int
ffs(int i);

int
fnmatch(char *pattern, char *string, int flags);
    CODE:
        RETVAL = fnmatch(pattern, string, flags);
        if (RETVAL && RETVAL != FNM_NOMATCH)
            XSRETURN_UNDEF;
    OUTPUT:
        RETVAL

int
killpg(pid_t pgrp, int sig);

#if defined(__FreeBSD__) || defined(__CYGWIN__)
void
getdate(...);
    PPCODE:
        croak("getdate() not available");

void
getdate_err();
    PPCODE:
        croak("getdate_err() not available");

#else
void
getdate(char *string);
    INIT:
        struct tm *tm = getdate(string);
    PPCODE:
        if (tm != NULL) {
            EXTEND(SP, 9);
            mPUSHi(tm->tm_sec);
            mPUSHi(tm->tm_min);
            mPUSHi(tm->tm_hour);
            mPUSHi(tm->tm_mday);
            mPUSHi(tm->tm_mon);
            mPUSHi(tm->tm_year);
            mPUSHi(tm->tm_wday);
            mPUSHi(tm->tm_yday);
            mPUSHi(tm->tm_isdst);
        }

int
getdate_err();
    PREINIT:
        extern int getdate_err;
    CODE:
        RETVAL = getdate_err;
    OUTPUT:
        RETVAL

#endif

void
strptime(char *s, char *format, SV *sec = NULL, SV *min = NULL, SV *hour = NULL, SV *mday = NULL, SV *mon = NULL, SV *year = NULL, SV *wday = NULL, SV *yday = NULL, SV *isdst = NULL);
    PREINIT:
        char *remainder;
        struct tm tm = { -1, -1, -1, -1, -1, INT_MIN, -1, -1, -1 };
    PPCODE:
    {
      if (sec && SvOK(sec))
        tm.tm_sec = SvIV(sec);
      if (min && SvOK(min))
        tm.tm_min = SvIV(min);
      if (hour && SvOK(hour))
        tm.tm_hour = SvIV(hour);
      if (mday && SvOK(mday))
        tm.tm_mday = SvIV(mday);
      if (mon && SvOK(mon))
        tm.tm_mon = SvIV(mon);
      if (year && SvOK(year))
        tm.tm_year = SvIV(year);
      if (wday && SvOK(wday))
        tm.tm_wday = SvIV(wday);
      if (yday && SvOK(yday))
        tm.tm_yday = SvIV(yday);
      if (isdst && SvOK(isdst))
        tm.tm_isdst = SvIV(isdst);

      remainder = strptime(s, format, &tm);

      if (remainder) {
        if (GIMME != G_ARRAY)
          mPUSHi(remainder - s);
        else {
          EXTEND(SP, 9);
          tm.tm_sec < 0  ? PUSHs(&PL_sv_undef) : mPUSHi(tm.tm_sec);
          tm.tm_min < 0  ? PUSHs(&PL_sv_undef) : mPUSHi(tm.tm_min);
          tm.tm_hour < 0 ? PUSHs(&PL_sv_undef) : mPUSHi(tm.tm_hour);
          tm.tm_mday < 0 ? PUSHs(&PL_sv_undef) : mPUSHi(tm.tm_mday);
          tm.tm_mon < 0  ? PUSHs(&PL_sv_undef) : mPUSHi(tm.tm_mon);
          tm.tm_year == INT_MIN ? PUSHs(&PL_sv_undef) : mPUSHi(tm.tm_year);
          tm.tm_wday < 0 ? PUSHs(&PL_sv_undef) : mPUSHi(tm.tm_wday);
          tm.tm_yday < 0 ? PUSHs(&PL_sv_undef) : mPUSHi(tm.tm_yday);
          mPUSHi(tm.tm_isdst);
        }
      }
    }

long
gethostid();

char *
gethostname();
    INIT:
        char name[HOST_NAME_MAX+1] = {0};
    CODE:
        if (gethostname(name, sizeof(name)) != 0)
            XSRETURN_UNDEF;
        RETVAL = name;
    OUTPUT:
        RETVAL

void
getitimer(int which);
    INIT:
        struct itimerval value;
    PPCODE:
        if (getitimer(which, &value) == 0) {
            EXTEND(SP, 4);
            mPUSHi(value.it_interval.tv_sec);
            mPUSHi(value.it_interval.tv_usec);
            mPUSHi(value.it_value.tv_sec);
            mPUSHi(value.it_value.tv_usec);
        }

void
setitimer(int which, time_t int_sec, int int_usec, time_t val_sec, int val_usec);
    INIT:
        struct itimerval value = { {int_sec, int_usec}, {val_sec, val_usec} };
        struct itimerval ovalue;
    PPCODE:
        if (setitimer(which, &value, &ovalue) == 0) {
            EXTEND(SP, 4);
            mPUSHi(ovalue.it_interval.tv_sec);
            mPUSHi(ovalue.it_interval.tv_usec);
            mPUSHi(ovalue.it_value.tv_sec);
            mPUSHi(ovalue.it_value.tv_usec);
        }

int
getpriority(int which = PRIO_PROCESS, id_t who = 0);
    CODE:
        errno = 0;
        RETVAL = getpriority(which, who);
        if (RETVAL == -1 && errno != 0)
            XSRETURN_UNDEF;
    OUTPUT:
        RETVAL

SysRet
setpriority(int value, int which = PRIO_PROCESS, id_t who = 0);
    CODE:
        RETVAL = setpriority(which, who, value);
    OUTPUT:
        RETVAL

pid_t
getsid(pid_t pid = 0);

#define RETURN_UTXENT {                                     \
    if (utxent != NULL) {                                   \
        EXTEND(SP, 7);                                      \
        PUSHs(sv_2mortal(newSVpv(utxent->ut_user, 0)));     \
        PUSHs(sv_2mortal(newSVpv(utxent->ut_id, 0)));       \
        PUSHs(sv_2mortal(newSVpv(utxent->ut_line, 0)));     \
        mPUSHi(utxent->ut_pid);                             \
        mPUSHi(utxent->ut_type);                            \
        mPUSHi(utxent->ut_tv.tv_sec);                       \
        mPUSHi(utxent->ut_tv.tv_usec);                      \
    }                                                       \
}

void
endutxent();

void
getutxent();
    INIT:
        struct utmpx *utxent = getutxent();
    PPCODE:
        RETURN_UTXENT;

void
getutxid(short ut_type, char *ut_id = NULL);
    INIT:
        struct utmpx *utxent;
        struct utmpx utxent_req = {0};
    PPCODE:
        utxent_req.ut_type = ut_type;
        if (ut_id != NULL) {
            strncpy(utxent_req.ut_id, ut_id, sizeof(utxent_req.ut_id)-1);
        }
        utxent = getutxline(&utxent_req);
        RETURN_UTXENT;

void
getutxline(char *ut_line);
    INIT:
        struct utmpx *utxent;
        struct utmpx utxent_req = {0};
    PPCODE:
        if (ut_line != NULL) {
            strncpy(utxent_req.ut_line, ut_line, sizeof(utxent_req.ut_line)-1);
            utxent = getutxline(&utxent_req);
            RETURN_UTXENT;
        }

void
setutxent();

NV
drand48();

void
erand48(unsigned short X0, unsigned short X1, unsigned short X2);
    INIT:
        unsigned short xsubi[3] = { X0, X1, X2 };
        double result = erand48(xsubi);
    PPCODE:
        EXTEND(SP, 4);
        mPUSHn(result);
        mPUSHu(xsubi[0]);
        mPUSHu(xsubi[1]);
        mPUSHu(xsubi[2]);

void
jrand48(unsigned short X0, unsigned short X1, unsigned short X2);
    ALIAS:
        nrand48 = 1
    INIT:
        unsigned short xsubi[3] = { X0, X1, X2 };
        long result = ix == 0 ? jrand48(xsubi) : nrand48(xsubi);
    PPCODE:
        EXTEND(SP, 4);
        mPUSHi(result);
        mPUSHu(xsubi[0]);
        mPUSHu(xsubi[1]);
        mPUSHu(xsubi[2]);

long
lrand48();

long
mrand48();

int
nice(int incr);
    CODE:
        errno = 0;
        RETVAL = nice(incr);
    OUTPUT:
        RETVAL

void
seed48(unsigned short seed1, unsigned short seed2, unsigned short seed3);
    INIT:
        unsigned short *old;
        unsigned short seed16v[3] = { seed1, seed2, seed3 };
    PPCODE:
        old = seed48(seed16v);
        EXTEND(SP, 3);
        mPUSHu(old[0]);
        mPUSHu(old[1]);
        mPUSHu(old[2]);

void
srand48(long seedval);

long
random();

void
srandom(unsigned seed);

gid_t
getegid();

uid_t
geteuid();

gid_t
getgid();

uid_t
getuid();

int
setegid(gid_t gid);

int
seteuid(uid_t uid);

int
setgid(gid_t gid);

int
setregid(gid_t rgid, gid_t egid);

int
setreuid(uid_t ruid, uid_t euid);

int
setuid(uid_t uid);

int
sighold(int sig);

int
sigignore(int sig);

int
sigpause(int sig);

int
sigrelse(int sig);


## I/O-related functions
########################

SysRet
chdir(char *path);

SysRet
chmod(char *path, mode_t mode);

SysRet
chown(char *path, uid_t owner, gid_t group);

SysRet
lchown(char *path, uid_t owner, gid_t group);

#ifdef HAS_ACCESS
SysRet
access(char *path, int mode);

SysRet
faccessat(psx_fd_t dirfd, char *path, int amode, int flags = 0);

#else
void
access(...);
  PPCODE:
    croak("access() not available");

void
faccessat(...);
  PPCODE:
    croak("faccessat() not available");

#endif

SysRet
fchdir(psx_fd_t dirfd);

SysRet
fchmod(psx_fd_t fd, mode_t mode);

SysRet
fchmodat(psx_fd_t dirfd, char *path, mode_t mode, int flags = 0);

SysRet
fchown(psx_fd_t fd, uid_t owner, gid_t group);

SysRet
fchownat(psx_fd_t dirfd, char *path, uid_t owner, gid_t group, int flags = 0);

#if !defined(HAS_FSYNC) || (defined(__FreeBSD_version) && __FreeBSD_version < 1101000)
void
fdatasync(...);
    PPCODE:
        croak("fdatasync not available");

#else
SysRet
fdatasync(psx_fd_t fd);

#endif

#ifndef __NetBSD__
#define RETURN_STAT_BUF(buf) { \
    EXTEND(SP, 16);                \
    mPUSHu( buf.st_dev );          \
    mPUSHu( buf.st_ino );          \
    mPUSHu( buf.st_mode );         \
    mPUSHu( buf.st_nlink );        \
    mPUSHu( buf.st_uid );          \
    mPUSHu( buf.st_gid );          \
    mPUSHu( buf.st_rdev );         \
    if (sizeof(IV) < 8)            \
        mPUSHn( buf.st_size );     \
    else                           \
        mPUSHi( buf.st_size );     \
    mPUSHi( buf.st_atim.tv_sec );  \
    mPUSHi( buf.st_mtim.tv_sec );  \
    mPUSHi( buf.st_ctim.tv_sec );  \
    /* actually these come before the times but we follow core stat */ \
    mPUSHi( buf.st_blksize );      \
    mPUSHi( buf.st_blocks );       \
    /* to stay compatible with pre-2008 stat we append the nanoseconds */ \
    mPUSHi( buf.st_atim.tv_nsec ); \
    mPUSHi( buf.st_mtim.tv_nsec ); \
    mPUSHi( buf.st_ctim.tv_nsec ); \
}
#else
#define RETURN_STAT_BUF(buf) { \
    EXTEND(SP, 16);                \
    mPUSHu( buf.st_dev );          \
    mPUSHu( buf.st_ino );          \
    mPUSHu( buf.st_mode );         \
    mPUSHu( buf.st_nlink );        \
    mPUSHu( buf.st_uid );          \
    mPUSHu( buf.st_gid );          \
    mPUSHu( buf.st_rdev );         \
    if (sizeof(IV) < 8)            \
        mPUSHn( buf.st_size );     \
    else                           \
        mPUSHi( buf.st_size );     \
    mPUSHi( buf.st_atime );  \
    mPUSHi( buf.st_mtime );  \
    mPUSHi( buf.st_ctime );  \
    /* actually these come before the times but we follow core stat */ \
    mPUSHi( buf.st_blksize );      \
    mPUSHi( buf.st_blocks );       \
    /* to stay compatible with pre-2008 stat we append the nanoseconds */ \
    mPUSHi( buf.st_atimensec ); \
    mPUSHi( buf.st_mtimensec ); \
    mPUSHi( buf.st_ctimensec ); \
}
#endif

void
fstatat(psx_fd_t dirfd, char *path, int flags = 0);
    INIT:
        struct stat buf;
    PPCODE:
        if (fstatat(dirfd, path, &buf, flags) == 0)
            RETURN_STAT_BUF(buf);

void
lstat(char *path);
    ALIAS:
        stat = 1
    INIT:
        int ret = 0;
        struct stat buf;
    PPCODE:
        if (ix == 0)
#ifdef HAS_LSTAT
            ret = lstat(path, &buf);
#else
            croak("lstat() not available");
#endif
        else
            ret = stat(path, &buf);
        if (ret == 0)
            RETURN_STAT_BUF(buf);

#ifdef HAS_FSYNC
SysRet
fsync(psx_fd_t fd);

#else
void
fsync(...);
    PPCODE:
        croak("fsync() not available");

#endif

SysRet
ftruncate(psx_fd_t fd, off_t length);

int
isatty(psx_fd_t fd);

SysRet
link(char *path1, char *path2);

SysRet
linkat(psx_fd_t olddirfd, char *oldpath, psx_fd_t newdirfd, char *newpath, int flags = 0);

SysRet
mkdir(char *path, mode_t mode);

SysRet
mkdirat(psx_fd_t dirfd, char *path, mode_t mode);

char *
mkdtemp(char *template);

SysRet
mkfifo(char *path, mode_t mode);

SysRet
mkfifoat(psx_fd_t dirfd, char *path, mode_t mode);

SysRet
mknod(char *path, mode_t mode, dev_t dev);

SysRet
mknodat(psx_fd_t dirfd, char *path, mode_t mode, dev_t dev);

void
mkstemp(char *template);
    INIT:
        int fd;
    PPCODE:
        if (template != NULL) {
            fd = mkstemp(template);
            if (fd >= 0) {
                EXTEND(SP, 2);
                mPUSHi(fd);
                PUSHs(sv_2mortal(newSVpv(template, 0)));
            }
        }

FILE*
fdopen(psx_fd_t fd, char *mode);

SV*
fdopendir(psx_fd_t fd);
  INIT:
    DIR *dir;
    GV *gv;
    IO *io;
    int fd2;
  CODE:
  {
    /*
     * This dup() feels a bit hacky but otherwise if whatever we got the fd
     * from goes out of scope, the caller would be left with an invalid file
     * descriptor.
     */
    fd2 = dup(fd);
    if (fd2 < 0)
      XSRETURN_UNDEF;

    dir = fdopendir(fd2);
    if (!dir) {
      close(fd2);
      XSRETURN_UNDEF;
    }

    /*
     * I'm not exactly sure if this is the right way to create and return a
     * directory handle. This is what I extracted from pp_open_dir, the code
     * xsubpp generated for the above fdopen(), Symbol::geniosym(), and
     * http://www.perlmonks.org/?node_id=1197703
     */
    gv = newGVgen(PACKNAME);
    io = GvIOn(gv);
    IoDIRP(io) = dir;
    RETVAL = newRV_inc((SV*)gv);
    RETVAL = sv_bless(RETVAL, GvSTASH(gv));
    /* https://rt.perl.org/Public/Bug/Display.html?id=59268 */
    (void) hv_delete(GvSTASH(gv), GvNAME(gv), GvNAMELEN(gv), G_DISCARD);
  }
  OUTPUT:
    RETVAL


##
## POSIX::open(), read() and write() return "0 but true" for 0, which
## is not quite what you want. We return a real 0.
##

SysRet0
open(char *path, int oflag = O_RDONLY, mode_t mode = 0600);

void
openat(SV *dirfdsv, char *path, int oflag = O_RDONLY, mode_t mode = 0600);
  PREINIT:
    int got_fd, dir_fd, path_fd;
    int return_handle = 0;
    struct stat st;
    GV *gv = NULL;
  PPCODE:
  {
    if (!SvOK(dirfdsv))
      XSRETURN_UNDEF;

    got_fd = psx_looks_like_number(aTHX_ dirfdsv);
    dir_fd = psx_fileno(aTHX_ dirfdsv);
    if (dir_fd < 0)
      XSRETURN_UNDEF;

    path_fd = openat(dir_fd, path, oflag, mode);
    if (path_fd < 0)
      XSRETURN_UNDEF;

    /* If we were passed a file descriptor, return a file descriptor. */
    if (got_fd)
      XSRETURN_IV(path_fd);

    /* Does this fstat() limit the usefulness of openat()? I don't think so
     * because the only error that might occur is EOVERFLOW and that would be
     * really unusual.
     */
    if (fstat(path_fd, &st) == 0) {
      /* If path is a directory, return a directory handle, otherwise return a
       * file handle.
       */
      gv = newGVgen(PACKNAME);
      if (S_ISDIR(st.st_mode)) {
        DIR *dir = fdopendir(path_fd);
        if (dir) {
          IO *io = GvIOn(gv);
          IoDIRP(io) = dir;
          return_handle = 1;
        }
      }
      else {
        const char *raw = flags2raw(oflag);
        FILE *file = fdopen(path_fd, raw);
        if (file) {
          PerlIO *fp = PerlIO_importFILE(file, raw);
          if (fp && do_open(gv, "+<&", 3, FALSE, 0, 0, fp))
            return_handle = 1;
        }
      }
    }

    if (return_handle) {
      SV *retvalsv = newRV_inc((SV*)gv);
      retvalsv = sv_bless(retvalsv, GvSTASH(gv));
      mPUSHs(retvalsv);
    }
    else
      close(path_fd);

    if (gv) 
      /* https://rt.perl.org/Public/Bug/Display.html?id=59268 */
      (void) hv_delete(GvSTASH(gv), GvNAME(gv), GvNAMELEN(gv), G_DISCARD);
  }

SysRet0
read(psx_fd_t fd, SV *buf, size_t count);
    INIT:
        char *cbuf;
    CODE:
        if (! SvPOK(buf))
          sv_setpvn(buf, "", 0);
        cbuf = SvGROW(buf, count);
        if (cbuf == NULL)
          RETVAL = -1;
        else if (count == 0)
          RETVAL = 0;
        else
          RETVAL = read(fd, cbuf, count);
        if (RETVAL >= 0) {
          SvCUR_set(buf, RETVAL);
          SvPOK_only(buf);
          SvTAINTED_on(buf);
        }
    OUTPUT:
        buf
        RETVAL

SysRet0
write(psx_fd_t fd, SV *buf, SV *count=NULL);
    INIT:
        const char *cbuf;
        STRLEN buf_cur, nbytes;
    CODE:
    {
      if (!SvPOK(buf))
        RETVAL = 0;
      else {
        cbuf = SvPV_const(buf, buf_cur);
        if (!buf_cur)
          RETVAL = 0;
        else {
          if (count == NULL || !SvOK(count))
            nbytes = buf_cur;
          else {
            nbytes = SvUV(count);
            if (nbytes > buf_cur)
              nbytes = buf_cur;
          }
          RETVAL = nbytes ? write(fd, cbuf, nbytes) : 0;
        }
      }
    }
    OUTPUT:
        RETVAL

SysRet0
readv(psx_fd_t fd, SV *buffers, AV *sizes);
    PROTOTYPE: $\[@$]$
    CODE:
        RETVAL = _readv50c(aTHX_ fd, buffers, sizes, NULL);
    OUTPUT:
        RETVAL

SysRet0
writev(psx_fd_t fd, AV *buffers);
    CODE:
        RETVAL = _writev50c(aTHX_ fd, buffers, NULL);
    OUTPUT:
        RETVAL

#if defined(__CYGWIN__) || (defined(__FreeBSD_version) &&  __FreeBSD_version < 600000)
void
preadv(...);
  PPCODE:
    croak("preadv() not available");

void
pwritev(...);
  PPCODE:
    croak("pwritev() not available");

#else
SysRet0
preadv(psx_fd_t fd, SV *buffers, AV *sizes, SV *offset=&PL_sv_undef);
  PROTOTYPE: $\[@$]@
  CODE:
    RETVAL = _readv50c(aTHX_ fd, buffers, sizes, offset);
  OUTPUT:
    RETVAL

SysRet0
pwritev(psx_fd_t fd, AV *buffers, SV *offset=&PL_sv_undef);
  CODE:
    RETVAL = _writev50c(aTHX_ fd, buffers, offset);
  OUTPUT:
    RETVAL

#endif

SysRet0
pread(psx_fd_t fd, SV *buf, size_t nbytes, SV *offset=NULL, off_t buf_offset=0);
    INIT:
      STRLEN
        buf_cur,  /* The actual string length in buf */
        buf_len,  /* The size of the string buffer in buf */
        new_len;
      char *cbuf;
    CODE:
    {
      if (! SvPOK(buf))
        sv_setpvn(buf, "", 0);
      cbuf = SvPV(buf, buf_cur);

      /* ensure buf_offset is a valid string index */
      if (buf_offset < 0) {
        buf_offset += buf_cur;
        if (buf_offset < 0) {
          warn("Offset %ld outside string", buf_offset);
          XSRETURN_UNDEF;
        }
      }

      /* must we enlarge the buffer? */
      buf_len = SvLEN(buf);
      if ((new_len = buf_offset + nbytes) > buf_len) {
        cbuf = SvGROW(buf, new_len);
        if (cbuf == NULL)
          XSRETURN_UNDEF;
      }

      /* must we pad the buffer with zeros? */
      if (buf_offset > buf_cur)
        Zero(cbuf + buf_cur, buf_offset - buf_cur, char);

      /* now fscking finally read teh data */
      if (nbytes) {
        off_t f_offset = (offset != NULL && SvOK(offset)) ? SvUV(offset) : 0;
        RETVAL = pread(fd, cbuf + buf_offset, nbytes, f_offset);
      }
      else
        RETVAL = 0;

      if (RETVAL >= 0) {
        SvCUR_set(buf, buf_offset + RETVAL);
        SvPOK_only(buf);
        SvTAINTED_on(buf);
      }
    }
    OUTPUT:
        buf
        RETVAL

SysRet0
pwrite(psx_fd_t fd, SV *buf, SV *count=NULL, SV *offset=NULL, off_t buf_offset=0);
  INIT:
    STRLEN buf_cur, i_count, max_nbytes;
    const char *cbuf;
  CODE:
  {
    cbuf = SvPV_const(buf, buf_cur);
    if (!cbuf || !buf_cur)
      RETVAL = 0;
    else {
      /* ensure buf_offset is a valid string index */
      if (buf_offset < 0)
        buf_offset += buf_cur;
      if (buf_offset < 0 || (!buf_cur && buf_offset > 0) ||
          (buf_cur && buf_offset >= buf_cur)) {
        warn("Offset %ld outside string", buf_offset);
        XSRETURN_UNDEF;
      }
      max_nbytes = buf_cur - buf_offset;
      if (count == NULL || !SvOK(count))
        i_count = max_nbytes;
      else {
        i_count = SvUV(count);
        if (i_count > max_nbytes)
          i_count = max_nbytes;
      }
      if (i_count) {
        off_t f_offset = (offset != NULL && SvOK(offset)) ? SvUV(offset) : 0;
        RETVAL = pwrite(fd, cbuf + buf_offset, i_count, f_offset);
      }
      else
        RETVAL = 0;
    }
  }
  OUTPUT:
    RETVAL

#ifdef POSIX_FADV_NORMAL
SysRet
posix_fadvise(psx_fd_t fd, off_t offset, off_t len, int advice);
  CODE:
    errno = posix_fadvise(fd, offset, len, advice);
    RETVAL = errno ? -1 : 0;
  OUTPUT:
    RETVAL

SysRet
posix_fallocate(psx_fd_t fd, off_t offset, off_t len);
  CODE:
    errno = posix_fallocate(fd, offset, len);
    RETVAL = errno ? -1 : 0;
  OUTPUT:
    RETVAL

#else
void
posix_fadvise(...);
    PPCODE:
        croak("posix_fadvise() not available");

void
posix_fallocate(...);
    PPCODE:
        croak("posix_fallocate() not available");

#endif

char *
ptsname(int fd);

#ifdef HAS_READLINK
char *
readlink(char *path);
    CODE:
        RETVAL = _readlink50c(path, NULL);
    OUTPUT:
        RETVAL
    CLEANUP:
        if (RETVAL != NULL)
            Safefree(RETVAL);

char *
readlinkat(psx_fd_t dirfd, char *path);
    CODE:
        RETVAL = _readlink50c(path, &dirfd);
    OUTPUT:
        RETVAL
    CLEANUP:
        if (RETVAL != NULL)
            Safefree(RETVAL);

#else
void
readlink(...);
  PPCODE:
    croak("readlink() not available");

void
readlinkat(...);
  PPCODE:
    croak("readlinkat() not available");

#endif

##
## POSIX::remove() is incorrectly implemented as:
## "(-d $_[0]) ? CORE::rmdir($_[0]) : CORE::unlink($_[0])".
## POSIX requires remove() to be equivalent to unlink() for non-directories.
##
SysRet
remove(char *path);

SysRet
rename(char *old, char *new);

SysRet
renameat(psx_fd_t olddirfd, char *oldpath, psx_fd_t newdirfd, char *newpath);

SysRet
symlink(char *old, char *new);

SysRet
symlinkat(char *old, psx_fd_t newdirfd, char *new);

void
sync();

SysRet
truncate(char *path, off_t length);

SysRet
unlink(char *path);

SysRet
unlinkat(psx_fd_t dirfd, char *path, int flags = 0);

#ifdef UTIME_NOW
SysRet
futimens(psx_fd_t fd, time_t atime_sec = 0, long atime_nsec = UTIME_NOW, time_t mtime_sec = 0, long mtime_nsec = UTIME_NOW);
    INIT:
        struct timespec times[2] = { { atime_sec, atime_nsec },
                                     { mtime_sec, mtime_nsec } };
    CODE:
        RETVAL = futimens(fd, times);
    OUTPUT:
        RETVAL

SysRet
utimensat(psx_fd_t dirfd, char *path, int flags = 0, time_t atime_sec = 0, long atime_nsec = UTIME_NOW, time_t mtime_sec = 0, long mtime_nsec = UTIME_NOW);
    INIT:
        struct timespec times[2] = { { atime_sec, atime_nsec },
                                     { mtime_sec, mtime_nsec } };
    CODE:
        RETVAL = utimensat(dirfd, path, times, flags);
    OUTPUT:
        RETVAL

#else
void
futimens(...);
    PPCODE:
        croak("futimens() not available");

void
utimensat(...);
    PPCODE:
        croak("futimensat() not available");

#endif

## Integer and real number arithmetic
#####################################

int
abs(int i);

NV
acos(double x);

NV
acosh(double x);

NV
asin(double x);

NV
asinh(double x);

NV
atan(double x);

NV
atan2(double y, double x);

NV
atanh(double x);

NV
cbrt(double x);

NV
ceil(double x);

NV
copysign(double x, double y);

NV
cos(double x);

NV
cosh(double x);

void
div(int numer, int denom);
    INIT:
        div_t result;
    PPCODE:
        result = div(numer, denom);
        EXTEND(SP, 2);
        mPUSHi(result.quot);
        mPUSHi(result.rem);

void
ldiv(long numer, long denom);
    INIT:
        ldiv_t result;
    PPCODE:
        result = ldiv(numer, denom);
        EXTEND(SP, 2);
        mPUSHi(result.quot);
        mPUSHi(result.rem);

NV
erf(double x);

NV
erfc(double x);

NV
exp2(double x);

NV
expm1(double x);

NV
fdim(double x, double y);

NV
floor(double x);

#if (defined(__FreeBSD_version)  && __FreeBSD_version  < 504000) || \
    (defined(__NetBSD_Version__) && __NetBSD_Version__ < 700000000)

void
fma(...);
    PPCODE:
        croak("fma() not available");

#else
NV
fma(double x, double y, double z);

#endif

NV
fmax(double x, double y);

NV
fmin(double x, double y);

NV
fmod(double x, double y);

int
fpclassify(double x);

NV
hypot(double x, double y);

int
ilogb(double x);

int
isfinite(double x);

int
isinf(double x);

int
isnan(double x);

int
isnormal(double x);

NV
j0(double x);

NV
j1(double x);

NV
jn(int n, double x);

NV
ldexp(double x, int exp);

NV
lgamma(double x);

NV
log(double x);

NV
log10(double x);

NV
log1p(double x);

NV
log2(double x);

NV
logb(double x);

long
lround(double x);

#if (defined(__FreeBSD_version)  && __FreeBSD_version  < 503001) || \
    (defined(__NetBSD_Version__) && __NetBSD_Version__ < 800000000)
void
nearbyint(...);
    PPCODE:
        croak("nearbyint() not available");

#else
NV
nearbyint(double x);

#endif

NV
nextafter(double x, double y);

NV
remainder(double x, double y);

NV
round(double x);

NV
scalbn(double x, int n);

int
signbit(double x);

NV
sinh(double x);

NV
tan(double x);

NV
tanh(double x);

NV
tgamma(double x);

NV
trunc(double x);

NV
y0(double x);

NV
y1(double x);

NV
yn(int n, double x);


## Complex arithmetic functions
###############################

#ifdef _Complex_I
NV
cabs(double re, double im);
    INIT:
        double complex z = re + im * _Complex_I;
    CODE:
        RETVAL = cabs(z);
    OUTPUT:
        RETVAL

#else
void
cabs(...);
    PPCODE:
        croak("cabs() not available");

#endif

#if !defined(_Complex_I) || (defined(__FreeBSD_version) &&  __FreeBSD_version < 800000)
void
carg(...);
    PPCODE:
        croak("carg() not available");

void
cproj(...);
    PPCODE:
        croak("cproj() not available");

void
csqrt(...);
    PPCODE:
        croak("csqrt() not available");

#else
NV
carg(double re, double im);
    INIT:
        double complex z = re + im * _Complex_I;
    CODE:
        RETVAL = carg(z);
    OUTPUT:
        RETVAL

void
cproj(double re, double im);
    ALIAS:
        sqrt = 1
    INIT:
        double complex z = re + im * _Complex_I;
        double complex result;
    PPCODE:
        if (ix == 0)
            result = cproj(z);
        else
            result = csqrt(z);
        EXTEND(SP, 2);
        mPUSHn(creal(result));
        mPUSHn(cimag(result));

#endif

#if !defined(_Complex_I) || (defined(__FreeBSD_version) &&  __FreeBSD_version < 503001)
void
cimag(...);
    PPCODE:
        croak("cimag() not available");

void
conj(...);
    PPCODE:
        croak("conj() not available");

void
creal(...);
    PPCODE:
        croak("creal() not available");

#else
NV
cimag(double re, double im);
    ALIAS:
        conj = 1
        creal = 2
    INIT:
        double complex z = re + im * _Complex_I;
    CODE:
        switch(ix) {
        case 0:
            RETVAL = cimag(z);
            break;
        case 1:
            RETVAL = conj(z);
            break;
        default:
            RETVAL = creal(z);
            break;
        }
    OUTPUT:
        RETVAL

#endif

#if defined(_Complex_I) && !defined(__FreeBSD__)
void
cpow(double re_x, double im_x, double re_y, double im_y);
    INIT:
        double complex x = re_x + im_x * _Complex_I;
        double complex y = re_y + im_y * _Complex_I;
        double complex result = cpow(x, y);
    PPCODE:
        EXTEND(SP, 2);
        mPUSHn(creal(result));
        mPUSHn(cimag(result));

void
clog(double re, double im);
    INIT:
        double complex z = re + im * _Complex_I;
        double complex result = clog(z);
    PPCODE:
        EXTEND(SP, 2);
        mPUSHn(creal(result));
        mPUSHn(cimag(result));

#else
void
cpow(...);
    PPCODE:
        /* https://bugs.freebsd.org/bugzilla/show_bug.cgi?id=221341 */
        croak("cpow() not available");

void
clog(...);
    PPCODE:
        /* https://bugs.freebsd.org/bugzilla/show_bug.cgi?id=221341 */
        croak("clog() not available");

#endif

#if !defined(_Complex_I) || (defined(__FreeBSD_version) &&  __FreeBSD_version < 900000)
void
cexp(...);
    PPCODE:
        croak("cexp() not available");

#else
void
cexp(double re, double im);
    INIT:
        double complex z = re + im * _Complex_I;
        double complex result = cexp(z);
    PPCODE:
        EXTEND(SP, 2);
        mPUSHn(creal(result));
        mPUSHn(cimag(result));

#endif

void
cacos(double re, double im);
    ALIAS:
        cacosh = 1
        casin = 2    
        casinh = 3
        catan = 4
        catanh = 5
        ccos = 6
        ccosh = 7
        csin = 8
        csinh = 9
        ctan = 10
        ctanh = 11
    INIT:
#if !defined(_Complex_I) || (defined(__FreeBSD_version) &&  __FreeBSD_version < 1000000)
        ;
#else
        double complex z = re + im * _Complex_I;
        double complex result;
#endif
    PPCODE:
#if !defined(_Complex_I) || (defined(__FreeBSD_version) &&  __FreeBSD_version < 1000000)
        PERL_UNUSED_VAR(re);
        PERL_UNUSED_VAR(im);
        PERL_UNUSED_VAR(ix);
        croak("Complex trigonometric functions not available");
#else
        switch(ix) {
        case 0:
            result = cacos(z);
            break;
        case 1:
            result = cacosh(z);
            break;
        case 2:
            result = casin(z);
            break;
        case 3:
            result = casinh(z);
            break;
        case 4:
            result = catan(z);
            break;
        case 5:
            result = catanh(z);
            break;
        case 6:
            result = ccos(z);
            break;
        case 7:
            result = ccosh(z);
            break;
        case 8:
            result = csin(z);
            break;
        case 9:
            result = csinh(z);
            break;
        case 10:
            result = ctan(z);
            break;
        default:
            result = ctanh(z);
        }
        EXTEND(SP, 2);
        mPUSHn(creal(result));
        mPUSHn(cimag(result));
#endif


## DESTROY is called when a file handle we created (e.g. in openat)
## is cleaned up. This is just a dummy to silence AUTOLOAD. We leave
## it up to Perl to take the necessary steps.
void
DESTROY(...);
PPCODE:


BOOT:
{
    CV *cv;
    char *file = __FILE__;

    /* is*() stuff borrowed vom POSIX.xs */
#undef isalnum
    cv = newXS("POSIX::2008::isalnum", is_common, file);
    XSANY.any_dptr = (any_dptr_t) &isalnum;
#undef isalpha
    cv = newXS("POSIX::2008::isalpha", is_common, file);
    XSANY.any_dptr = (any_dptr_t) &isalpha;
#undef isblank
    cv = newXS("POSIX::2008::isblank", is_common, file);
    XSANY.any_dptr = (any_dptr_t) &isblank;
#undef iscntrl
    cv = newXS("POSIX::2008::iscntrl", is_common, file);
    XSANY.any_dptr = (any_dptr_t) &iscntrl;
#undef isdigit
    cv = newXS("POSIX::2008::isdigit", is_common, file);
    XSANY.any_dptr = (any_dptr_t) &isdigit;
#undef isgraph
    cv = newXS("POSIX::2008::isgraph", is_common, file);
    XSANY.any_dptr = (any_dptr_t) &isgraph;
#undef islower
    cv = newXS("POSIX::2008::islower", is_common, file);
    XSANY.any_dptr = (any_dptr_t) &islower;
#undef isprint
    cv = newXS("POSIX::2008::isprint", is_common, file);
    XSANY.any_dptr = (any_dptr_t) &isprint;
#undef ispunct
    cv = newXS("POSIX::2008::ispunct", is_common, file);
    XSANY.any_dptr = (any_dptr_t) &ispunct;
#undef isspace
    cv = newXS("POSIX::2008::isspace", is_common, file);
    XSANY.any_dptr = (any_dptr_t) &isspace;
#undef isupper
    cv = newXS("POSIX::2008::isupper", is_common, file);
    XSANY.any_dptr = (any_dptr_t) &isupper;
#undef isxdigit
    cv = newXS("POSIX::2008::isxdigit", is_common, file);
    XSANY.any_dptr = (any_dptr_t) &isxdigit;
}

# vim: set ts=4 sw=4 sts=4 expandtab:
