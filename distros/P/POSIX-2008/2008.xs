#undef _GNU_SOURCE
#define _GNU_SOURCE
#define _ATFILE_SOURCE 1
#define _POSIX_C_SOURCE 200809L
#define _XOPEN_SOURCE 700
#define _FILE_OFFSET_BITS 64

#include <complex.h>
#include <dirent.h>
#include <dlfcn.h>
#include <errno.h>
#include <fcntl.h>
#include <fenv.h>
#include <fnmatch.h>
#include <libgen.h>
#include <limits.h>
#include <math.h>
#include <nl_types.h>
#include <signal.h>
#include <stdlib.h>
#include <string.h>
#include <strings.h>
#include <sys/resource.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <time.h>
#include <unistd.h>
#include <utmpx.h>

#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#define NEED_newCONSTSUB
#include "ppport.h"

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

  dTHX;

  errno = 0;

  Newx(buf, bufsize, char);
  if (!buf)
    return NULL;

  while (1) {
    if (dirfd)
      linklen = readlinkat(*dirfd, path, buf, bufsize);
    else
      linklen = readlink(path, buf, bufsize);

    if (linklen >= 0) {
      if (linklen < bufsize || linklen == SSIZE_MAX) {
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

static int
psx_looks_like_number(SV *sv) {
  dTHX;

#if PERL_BCDVERSION >= 0x5008005
    return looks_like_number(sv);
#else
  if (SvPOK(sv) || SvPOKp(sv))
    return looks_like_number(sv);
  else
    return (SvFLAGS(fh) & (SVf_NOK|SVp_NOK|SVf_IOK|SVp_IOK));
#endif
}

static int
psx_fileno(SV *sv) {
  IO *io;
  int fn = -1;

  dTHX;

  if (SvOK(sv)) {
    if (psx_looks_like_number(sv))
      fn = SvIV(sv);
    else {
      io = sv_2io(sv);
      if (IoDIRP(io))  /* from opendir() */
        fn = my_dirfd(IoDIRP(io));
      else if (IoIFP(io))  /* from open() or sysopen() */
        fn = PerlIO_fileno(IoIFP(io));
    }
  }

  return fn;
}

#define PACKNAME "POSIX::2008"


MODULE = POSIX::2008    PACKAGE = POSIX::2008

long
a64l(char* s);

char*
l64a(long value);

void
abort();

unsigned
alarm(unsigned seconds);

double
atof(char *str);

int
atoi(char *str);

long
atol(char *str);

NV
atoll(char *str);

char*
basename(char *path);

int
catclose(nl_catd catd);

char*
catgets(nl_catd catd, int set_id, int msg_id, char *dflt);

nl_catd
catopen(char *name, int oflag);

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

# if defined(__FreeBSD__) && defined(__FreeBSD_version) && __FreeBSD_version < 1101000
void
clock_nanosleep(...);
    PPCODE:
        croak("clock_nanosleep not available");

# else
void
clock_nanosleep(clockid_t clock_id, int flags, time_t sec, long nsec);
    INIT:
        const struct timespec request = { sec, nsec };
        struct timespec remain = { 0, 0 };
    PPCODE:
        errno = clock_nanosleep(clock_id, flags, &request, &remain);
        RETURN_NANOSLEEP_REMAIN(errno)

# endif

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

int
clock_settime(clockid_t clock_id, time_t sec, long nsec);
    INIT:
        struct timespec tp = { sec, nsec };
    CODE:
        if ((RETVAL = clock_settime(clock_id, &tp)))
            XSRETURN_UNDEF;
    OUTPUT:
        RETVAL

char *
confstr(int name);
    INIT:
        size_t len;
        char *buf = NULL;
    CODE:
        len = confstr(name, NULL, 0);
        if (len) {
            Newx(buf, len, char);
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

# ifdef __FreeBSD__
void
getdate(...);
    PPCODE:
        croak("getdate() not available");

void
getdate_err();
    PPCODE:
        croak("getdate_err() not available");

# else
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
    CODE:
        RETVAL = getdate_err;
    OUTPUT:
        RETVAL

# endif

void
strptime(char *s, char *format, SV *sec = &PL_sv_undef, SV *min = &PL_sv_undef, SV *hour = &PL_sv_undef, SV *mday = &PL_sv_undef, SV *mon = &PL_sv_undef, SV *year = &PL_sv_undef, SV *wday = &PL_sv_undef, SV *yday = &PL_sv_undef, SV *isdst = &PL_sv_undef);
    INIT:
        char *remainder;
        struct tm tm;
    PPCODE:
        tm.tm_sec = sec == &PL_sv_undef ? INT_MIN : SvIV(sec);
        tm.tm_min = min == &PL_sv_undef ? INT_MIN : SvIV(min);
        tm.tm_hour = hour == &PL_sv_undef ? INT_MIN : SvIV(hour);
        tm.tm_mday = mday == &PL_sv_undef ? INT_MIN : SvIV(mday);
        tm.tm_mon = mon == &PL_sv_undef ? INT_MIN : SvIV(mon);
        tm.tm_year = year == &PL_sv_undef ? INT_MIN : SvIV(year);
        tm.tm_wday = wday == &PL_sv_undef ? INT_MIN : SvIV(wday);
        tm.tm_yday = yday == &PL_sv_undef ? INT_MIN : SvIV(yday);
        tm.tm_isdst = isdst == &PL_sv_undef ? INT_MIN : SvIV(isdst);

        remainder = strptime(s, format, &tm);

        if (remainder == NULL) {
            if (GIMME != G_ARRAY)
                XSRETURN_UNDEF;
        }
        else if (GIMME != G_ARRAY)
                mPUSHi(remainder - s);
        else {
            EXTEND(SP, 9);
            PUSHs(tm.tm_sec == INT_MIN ? &PL_sv_undef : sv_2mortal(newSViv(tm.tm_sec)));
            PUSHs(tm.tm_min == INT_MIN ? &PL_sv_undef : sv_2mortal(newSViv(tm.tm_min)));
            PUSHs(tm.tm_hour == INT_MIN ? &PL_sv_undef : sv_2mortal(newSViv(tm.tm_hour)));
            PUSHs(tm.tm_mday == INT_MIN ? &PL_sv_undef : sv_2mortal(newSViv(tm.tm_mday)));
            PUSHs(tm.tm_mon == INT_MIN ? &PL_sv_undef : sv_2mortal(newSViv(tm.tm_mon)));
            PUSHs(tm.tm_year == INT_MIN ? &PL_sv_undef : sv_2mortal(newSViv(tm.tm_year)));
            PUSHs(tm.tm_wday == INT_MIN ? &PL_sv_undef : sv_2mortal(newSViv(tm.tm_wday)));
            PUSHs(tm.tm_yday == INT_MIN ? &PL_sv_undef : sv_2mortal(newSViv(tm.tm_yday)));
            PUSHs(tm.tm_isdst == INT_MIN ? &PL_sv_undef : sv_2mortal(newSViv(tm.tm_isdst)));
        }

long
gethostid();

#ifndef HOST_NAME_MAX
#define HOST_NAME_MAX 255
#endif
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

double
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


# I/O-related functions
########################

SysRet
chdir(char *path);

SysRet
chmod(char *path, mode_t mode);

SysRet
chown(char *path, uid_t owner, gid_t group);

SysRet
faccessat(psx_fd_t dirfd, char *path, int amode, int flags = 0);

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

# if defined(__FreeBSD__) && defined(__FreeBSD_version) && __FreeBSD_version < 1101000
void
fdatasync(...);
    PPCODE:
        croak("fdatasync not available");

# else
SysRet
fdatasync(psx_fd_t fd);

#endif

#define RETURN_STAT_BUF(buf) { \
    EXTEND(SP, 16);                                     \
    mPUSHu( buf.st_dev );           \
    mPUSHu( buf.st_ino );           \
    mPUSHu( buf.st_mode );          \
    mPUSHu( buf.st_nlink );         \
    mPUSHu( buf.st_uid );           \
    mPUSHu( buf.st_gid );           \
    mPUSHu( buf.st_rdev );          \
    if (sizeof(IV) < 8)                                 \
        mPUSHn( buf.st_size );      \
    else                                                \
        mPUSHi( buf.st_size );      \
    mPUSHi( buf.st_atim.tv_sec );   \
    mPUSHi( buf.st_mtim.tv_sec );   \
    mPUSHi( buf.st_ctim.tv_sec );   \
    /* actually these come before the times but we follow core stat */ \
    mPUSHi( buf.st_blksize );       \
    mPUSHi( buf.st_blocks );        \
    /* to stay compatible with pre-2008 stat we append the nanoseconds */ \
    mPUSHi( buf.st_atim.tv_nsec );  \
    mPUSHi( buf.st_mtim.tv_nsec );  \
    mPUSHi( buf.st_ctim.tv_nsec );  \
}

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
        int ret;
        struct stat buf;
    PPCODE:
        ret = ix == 0 ? lstat(path, &buf) : stat(path, &buf);
        if (ret == 0)
            RETURN_STAT_BUF(buf);

SysRet
fsync(psx_fd_t fd);

SysRet
ftruncate(psx_fd_t fd, off_t length);

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

#
# POSIX::open(), read() and write() return "0 but true" for 0, which
# is not quite what you want. We return a real 0. Since we require
# Perl 5.10 as a minimum, you can say "open(...) // die ...".
#

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

SysRet0
open(char *path, int oflag = O_RDONLY, mode_t mode = 0600);

void
openat(SV *dirfdsv, char *path, int oflag = O_RDONLY, mode_t mode = 0600);
  PREINIT:
    int got_fd, dir_fd, path_fd;
    int return_handle = 0;
    struct stat st;
    DIR *dir;
    FILE *file;
    GV *gv = NULL;
    IO *io;
    PerlIO *fp;
    SV *retvalsv;
  PPCODE:
  {
    if (!SvOK(dirfdsv))
      XSRETURN_UNDEF;

    got_fd = psx_looks_like_number(dirfdsv);
    dir_fd = psx_fileno(dirfdsv);
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
        if ((dir = fdopendir(path_fd))) {
          io = GvIOn(gv);
          IoDIRP(io) = dir;
          return_handle = 1;
        }
      }
      else if ((file = fdopen(path_fd, flags2raw(oflag)))) {
        fp = PerlIO_importFILE(file, 0);
        if (fp && do_open(gv, "+<&", 3, FALSE, 0, 0, fp))
          return_handle = 1;
      }
    }

    if (return_handle) {
      retvalsv = newRV_inc((SV*)gv);
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
write(psx_fd_t fd, SV *buf, SV *count = &PL_sv_undef);
    INIT:
        char *cbuf;
        STRLEN buf_cur, nbytes;
    CODE:
    {
      if (!SvPOK(buf))
        RETVAL = 0;
      else {
        cbuf = SvPV(buf, buf_cur);
        if (!cbuf || !buf_cur)
          RETVAL = 0;
        else {
          if (count == &PL_sv_undef)
            nbytes = buf_cur;
          else
            nbytes = SvUV(count);
          if (nbytes > buf_cur)
            nbytes = buf_cur;
          RETVAL = write(fd, cbuf, nbytes);
        }
      }
    }
    OUTPUT:
        RETVAL

SysRet0
pread(psx_fd_t fd, SV *buf, off_t file_offset, size_t nbytes, off_t buf_offset = 0);
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
      if (nbytes)
        RETVAL = pread(fd, cbuf + buf_offset, nbytes, file_offset);
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
pwrite(psx_fd_t fd, SV *buf, off_t file_offset, SV *sv_nbytes = &PL_sv_undef, off_t buf_offset = 0);
  INIT:
    STRLEN buf_cur, nbytes, max_nbytes;
    char *cbuf;
  CODE:
  {
    cbuf = SvPV(buf, buf_cur);
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
      if (sv_nbytes == &PL_sv_undef)
        nbytes = max_nbytes;
      else
        nbytes = SvUV(sv_nbytes);
      if (nbytes > max_nbytes)
        nbytes = max_nbytes;
      if (nbytes)
        RETVAL = pwrite(fd, cbuf + buf_offset, nbytes, file_offset);
      else
        RETVAL = 0;
    }
  }
  OUTPUT:
    RETVAL

char *
ptsname(int fd);

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

#
# POSIX::remove() fails to remove a symlink to a directory
# because it incorrectly re-implements remove() in Perl as
# "(-d $_[0]) ? CORE::rmdir($_[0]) : CORE::unlink($_[0])".
# POSIX requires remove() to be equivalent to unlink() for non-directories.
#
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

# ifdef UTIME_NOW
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

# else
void
futimens(...);
    PPCODE:
        croak("futimens() not available");

void
utimensat(...);
    PPCODE:
        croak("futimensat() not available");

# endif

# Integer and real number arithmetic
#####################################

int
abs(int i);

double
acos(double x);

double
acosh(double x);

double
asin(double x);

double
asinh(double x);

double
atan(double x);

double
atan2(double y, double x);

double
atanh(double x);

double
cbrt(double x);

double
ceil(double x);

double
copysign(double x, double y);

double
cos(double x);

double
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

double
erf(double x);

double
erfc(double x);

double
exp2(double x);

double
expm1(double x);

double
fdim(double x, double y);

double
floor(double x);

double
fma(double x, double y, double z);

double
fmax(double x, double y);

double
fmin(double x, double y);

double
fmod(double x, double y);

int
fpclassify(double x);

double
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

double
j0(double x);

double
j1(double x);

double
jn(int n, double x);

double
ldexp(double x, int exp);

double
lgamma(double x);

double
log1p(double x);

double
log2(double x);

double
logb(double x);

double
nearbyint(double x);

double
nextafter(double x, double y);

double
remainder(double x, double y);

double
round(double x);

double
scalbn(double x, int n);

int
signbit(double x);

double
sinh(double x);

double
tan(double x);

double
tanh(double x);

double
tgamma(double x);

double
trunc(double x);

double
y0(double x);

double
y1(double x);

double
yn(int n, double x);


# Complex arithmetic functions
###############################

double
cabs(double re, double im);
    ALIAS:
        carg = 1
        cimag = 2
        creal = 3
    INIT:
#ifdef _Complex_I
        double complex z = re + im * _Complex_I;
#else
        ;
#endif
    CODE:
#ifdef _Complex_I
        switch(ix) {
        case 0:
            RETVAL = cabs(z);
            break;
        case 1:
            RETVAL = carg(z);
            break;
        case 2:
            RETVAL = cimag(z);
            break;
        default:
            RETVAL = creal(z);
        }
#else
        PERL_UNUSED_VAR(re);
        PERL_UNUSED_VAR(im);
        PERL_UNUSED_VAR(ix);
        PERL_UNUSED_VAR(RETVAL);
        croak("Complex functions not available.");
#endif
    OUTPUT:
        RETVAL

void
cpow(double re_x, double im_x, double re_y, double im_y);
    INIT:
#ifdef _Complex_I
        double complex x = re_x + im_x * _Complex_I;
        double complex y = re_y + im_y * _Complex_I;
        double complex result = cpow(x, y);
#else
        ;
#endif
    PPCODE:
#ifdef _Complex_I
        EXTEND(SP, 2);
        mPUSHn(creal(result));
        mPUSHn(cimag(result));
#else
        PERL_UNUSED_VAR(re_x);
        PERL_UNUSED_VAR(im_x);
        PERL_UNUSED_VAR(re_y);
        PERL_UNUSED_VAR(im_y);
        croak("Complex functions not available.");
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
        cexp = 8
        clog = 9
        conj = 10
        cproj = 11
        csin = 12
        csinh = 13
        csqrt = 14
        ctan = 15
        ctanh = 16
    INIT:
#ifdef _Complex_I
        double complex z = re + im * _Complex_I;
        double complex result;
#else
        ;
#endif
    PPCODE:
#ifndef _Complex_I
        PERL_UNUSED_VAR(re);
        PERL_UNUSED_VAR(im);
        PERL_UNUSED_VAR(ix);
        croak("Complex functions not available.");
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
            result = cexp(z);
            break;
        case 9:
            result = clog(z);
            break;
        case 10:
            result = conj(z);
            break;
        case 11:
            result = cproj(z);
            break;
        case 12:
            result = csin(z);
            break;
        case 13:
            result = csinh(z);
            break;
        case 14:
            result = csqrt(z);
            break;
        case 15:
            result = ctan(z);
            break;
        default:
            result = ctanh(z);
        }
        EXTEND(SP, 2);
        mPUSHn(creal(result));
        mPUSHn(cimag(result));
#endif


BOOT:
{
    HV *stash;
    CV *cv;
    char *file = __FILE__;

    /* is*() stuff borrowed vom POSIX.xs */
#undef isalnum
    cv = newXS("POSIX::2008::isalnum", is_common, file);
    XSANY.any_dptr = (any_dptr_t) &isalnum;
#undef isalpha
    cv = newXS("POSIX::2008::isalpha", is_common, file);
    XSANY.any_dptr = (any_dptr_t) &isalpha;
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

    stash = gv_stashpv(PACKNAME, TRUE);
    newCONSTSUB(stash, "_CS_PATH",            newSViv(_CS_PATH));
#ifdef _CS_GNU_LIBC_VERSION
    newCONSTSUB(stash, "_CS_GNU_LIBC_VERSION",newSViv(_CS_GNU_LIBC_VERSION));
#endif
#ifdef _CS_GNU_LIBPTHREAD_VERSION
    newCONSTSUB(stash, "_CS_GNU_LIBPTHREAD_VERSION",
                newSViv(_CS_GNU_LIBPTHREAD_VERSION));
#endif
#ifdef AT_EACCESS
    newCONSTSUB(stash, "AT_EACCESS",          newSViv(AT_EACCESS));
#endif
#ifdef AT_EMPTY_PATH
    newCONSTSUB(stash, "AT_EMPTY_PATH",       newSViv(AT_EMPTY_PATH));
#endif
#ifdef AT_FDCWD
    newCONSTSUB(stash, "AT_FDCWD",            newSViv(AT_FDCWD));
#endif
#ifdef AT_NO_AUTOMOUNT
    newCONSTSUB(stash, "AT_NO_AUTOMOUNT",     newSViv(AT_NO_AUTOMOUNT));
#endif
#ifdef AT_REMOVEDIR
    newCONSTSUB(stash, "AT_REMOVEDIR",        newSViv(AT_REMOVEDIR));
#endif
#ifdef AT_SYMLINK_FOLLOW
    newCONSTSUB(stash, "AT_SYMLINK_FOLLOW",   newSViv(AT_SYMLINK_FOLLOW));
#endif
#ifdef AT_SYMLINK_NOFOLLOW
    newCONSTSUB(stash, "AT_SYMLINK_NOFOLLOW", newSViv(AT_SYMLINK_NOFOLLOW));
#endif
#ifdef CLOCK_REALTIME
    newCONSTSUB(stash, "CLOCK_REALTIME",      newSViv(CLOCK_REALTIME));
#endif
#ifdef CLOCK_MONOTONIC
    newCONSTSUB(stash, "CLOCK_MONOTONIC",     newSViv(CLOCK_MONOTONIC));
#endif
#ifdef CLOCK_MONOTONIC_RAW
    newCONSTSUB(stash, "CLOCK_MONOTONIC_RAW", newSViv(CLOCK_MONOTONIC_RAW));
#endif
#ifdef CLOCK_PROCESS_CPUTIME_ID
    newCONSTSUB(stash, "CLOCK_PROCESS_CPUTIME_ID",
                newSViv(CLOCK_PROCESS_CPUTIME_ID));
#endif
#ifdef CLOCK_THREAD_CPUTIME_ID
    newCONSTSUB(stash, "CLOCK_THREAD_CPUTIME_ID",
                newSViv(CLOCK_THREAD_CPUTIME_ID));
#endif
    newCONSTSUB(stash, "FNM_NOMATCH",         newSViv(FNM_NOMATCH));
    newCONSTSUB(stash, "FNM_PATHNAME",        newSViv(FNM_PATHNAME));
    newCONSTSUB(stash, "FNM_PERIOD",          newSViv(FNM_PERIOD));
    newCONSTSUB(stash, "FNM_NOESCAPE",        newSViv(FNM_NOESCAPE));
#ifdef FNM_FILE_NAME
    newCONSTSUB(stash, "FNM_FILE_NAME",       newSViv(FNM_FILE_NAME));
#endif
#ifdef FNM_LEADING_DIR
    newCONSTSUB(stash, "FNM_LEADING_DIR",     newSViv(FNM_LEADING_DIR));
#endif
#ifdef FNM_CASEFOLD
    newCONSTSUB(stash, "FNM_CASEFOLD",        newSViv(FNM_CASEFOLD));
#endif
    newCONSTSUB(stash, "FP_NAN",              newSViv(FP_NAN));
    newCONSTSUB(stash, "FP_INFINITE",         newSViv(FP_INFINITE));
    newCONSTSUB(stash, "FP_ZERO",             newSViv(FP_ZERO));
    newCONSTSUB(stash, "FP_SUBNORMAL",        newSViv(FP_SUBNORMAL));
    newCONSTSUB(stash, "FP_NORMAL",           newSViv(FP_NORMAL));
#ifdef O_CLOEXEC
    newCONSTSUB(stash, "O_CLOEXEC",           newSViv(O_CLOEXEC));
#endif
#ifdef O_DIRECTORY
    newCONSTSUB(stash, "O_DIRECTORY",         newSViv(O_DIRECTORY));
#endif
#ifdef O_EXEC
    newCONSTSUB(stash, "O_EXEC",              newSViv(O_EXEC));
#endif
#ifdef O_NOFOLLOW
    newCONSTSUB(stash, "O_NOFOLLOW",          newSViv(O_NOFOLLOW));
#endif
#ifdef O_RSYNC
    newCONSTSUB(stash, "O_RSYNC",             newSViv(O_RSYNC));
#endif
    newCONSTSUB(stash, "O_SYNC",              newSViv(O_SYNC));
#ifdef O_SEARCH
    newCONSTSUB(stash, "O_SEARCH",            newSViv(O_SEARCH));
#endif
#ifdef O_TMPFILE
    /* not POSIX but useful */
    newCONSTSUB(stash, "O_TMPFILE",           newSViv(O_TMPFILE));
#endif
#ifdef O_TTY_INIT
    newCONSTSUB(stash, "O_TTY_INIT",          newSViv(O_TTY_INIT));
#endif
    newCONSTSUB(stash, "TIMER_ABSTIME",       newSViv(TIMER_ABSTIME));
#ifdef UTIME_NOW
    newCONSTSUB(stash, "UTIME_NOW",           newSViv(UTIME_NOW));
    newCONSTSUB(stash, "UTIME_OMIT",          newSViv(UTIME_OMIT));
#endif
#ifdef RUN_LVL
    newCONSTSUB(stash, "RUN_LVL",             newSViv(RUN_LVL));
#endif
    newCONSTSUB(stash, "BOOT_TIME",           newSViv(BOOT_TIME));
    newCONSTSUB(stash, "NEW_TIME",            newSViv(NEW_TIME));
    newCONSTSUB(stash, "OLD_TIME",            newSViv(OLD_TIME));
    newCONSTSUB(stash, "DEAD_PROCESS",        newSViv(DEAD_PROCESS));
    newCONSTSUB(stash, "INIT_PROCESS",        newSViv(INIT_PROCESS));
    newCONSTSUB(stash, "LOGIN_PROCESS",       newSViv(LOGIN_PROCESS));
    newCONSTSUB(stash, "USER_PROCESS",        newSViv(USER_PROCESS));
    newCONSTSUB(stash, "RTLD_GLOBAL",         newSViv(RTLD_GLOBAL));
    newCONSTSUB(stash, "RTLD_LOCAL",          newSViv(RTLD_LOCAL));
    newCONSTSUB(stash, "RTLD_LAZY",           newSViv(RTLD_LAZY));
    newCONSTSUB(stash, "RTLD_NOW",            newSViv(RTLD_NOW));
    newCONSTSUB(stash, "ITIMER_PROF",         newSViv(ITIMER_PROF));
    newCONSTSUB(stash, "ITIMER_REAL",         newSViv(ITIMER_REAL));
    newCONSTSUB(stash, "ITIMER_VIRTUAL",      newSViv(ITIMER_VIRTUAL));
}

# vim: set ts=4 sw=4 sts=4 expandtab:
