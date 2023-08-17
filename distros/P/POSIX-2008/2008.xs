#ifndef _GNU_SOURCE
#define _GNU_SOURCE
#endif

#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#if defined(PERL_IMPLICIT_SYS)
#undef open
#undef close
#undef stat
#undef fstat
#undef lstat
# if !defined(_WIN32) || defined(__CYGWIN__)
#undef abort
#undef access
#undef chdir
#undef fchdir
#undef chmod
#undef fchmod
#undef chown
#undef fchown
#undef fdopen
#undef getegid
#undef geteuid
#undef getgid
#undef gethostname
#undef getuid
#undef isatty
#undef killpg
#undef link
#undef mkdir
#undef read
#undef rename
#undef rmdir
#undef setgid
#undef setuid
#undef unlink
#undef write
# endif
#endif

/* ppport.h says we don't need caller_cx but a frew cpantesters report
 * "undefined symbol: caller_cx".
 */
#define NEED_caller_cx
#define NEED_croak_xs_usage
#include "ppport.h"

#include "2008.h"

#ifdef PSX2008_HAS_COMPLEX_H
#include <complex.h>
#endif
#include <ctype.h>
#ifdef I_DIRENT
#include <dirent.h>
#endif
#if defined(I_DLFCN) && defined(PSX2008_HAS_DLFCN_H)
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
#ifdef PSX2008_HAS_FNMATCH_H
#include <fnmatch.h>
#endif
#ifdef I_INTTYPES
#include <inttypes.h>
#endif
#ifdef PSX2008_HAS_LIBGEN_H
#include <libgen.h>
#endif
#ifdef I_LIMITS
#include <limits.h>
#endif
#ifdef I_NETDB
#include <netdb.h>
#endif
#ifdef I_MATH
#include <math.h>
#endif
#ifdef PSX2008_HAS_NL_TYPES_H
#include <nl_types.h>
#endif
#ifdef PSX2008_HAS_SIGNAL_H
#include <signal.h>
#endif
#ifdef I_STDLIB
#include <stdlib.h>
#endif
#ifdef I_STRING
#include <string.h>
#endif
#ifdef PSX2008_HAS_STRINGS_H
#include <strings.h>
#endif
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
#if defined(I_SYSUIO) && defined(PSX2008_HAS_SYS_UIO_H)
#include <sys/uio.h>
#endif
#ifdef I_TIME
#include <time.h>
#endif
#ifdef I_UNISTD
#include <unistd.h>
#endif
#ifdef PSX2008_HAS_UTMPX_H
#include <utmpx.h>
#endif

#if defined(__linux__) && defined(PSX2008_HAS_OPENAT2)
#include <sys/syscall.h>
#include <linux/openat2.h>
#endif

#if IVSIZE < LSEEKSIZE
#define SvOFFT(sv) SvNV(sv)
#else
#define SvOFFT(sv) SvIV(sv)
#endif

#if defined(PSX2008_HAS_SCALBLN)
#define PSX2008_SCALBN(x, n) scalbln(x, n)
#elif defined(PSX2008_HAS_SCALBN)
#define PSX2008_SCALBN(x, n) scalbn(x, n)
#endif

#if IVSIZE > LONGSIZE
# if defined(PSX2008_HAS_LLDIV)
#  define PSX2008_DIV_T lldiv_t
#  define PSX2008_DIV(numer, denom) lldiv(numer, denom)
# elif defined(PSX2008_HAS_LDIV)
#  define PSX2008_DIV_T ldiv_t
#  define PSX2008_DIV(numer, denom) ldiv(numer, denom)
# elif defined(PSX2008_HAS_DIV)
#  define PSX2008_DIV_T div_t
#  define PSX2008_DIV(numer, denom) div(numer, denom)
# endif
#elif IVSIZE > INTSIZE
# if defined(PSX2008_HAS_LDIV)
#  define PSX2008_DIV_T ldiv_t
#  define PSX2008_DIV(numer, denom) ldiv(numer, denom)
# elif defined(PSX2008_HAS_DIV)
#  define PSX2008_DIV_T div_t
#  define PSX2008_DIV(numer, denom) div(numer, denom)
# endif
#elif defined(PSX2008_HAS_DIV)
# define PSX2008_DIV_T div_t
# define PSX2008_DIV(numer, denom) div(numer, denom)
#endif

#if IVSIZE > LONGSIZE
# if defined(PSX2008_HAS_ATOLL)
#  define PSX2008_ATOI(a) atoll(a)
# elif defined(PSX2008_HAS_ATOL)
#  define PSX2008_ATOI(a) atol(a)
# elif defined(PSX2008_HAS_ATOI)
#  define PSX2008_ATOI(a) atoi(a)
# endif
# if defined(PSX2008_HAS_FFSLL)
#  define PSX2008_FFS(i) ffsll(i)
# elif defined(PSX2008_HAS_FFSL)
#  define PSX2008_FFS(i) ffsl(i)
# elif defined(PSX2008_HAS_FFS)
#  define PSX2008_FFS(i) ffs(i)
# endif
# if defined(PSX2008_HAS_LLABS)
#  define PSX2008_ABS(i) llabs(i)
# elif defined(PSX2008_HAS_LABS)
#  define PSX2008_ABS(i) labs(i)
# elif defined(PSX2008_HAS_ABS)
#  define PSX2008_ABS(i) abs(i)
# endif
#elif IVSIZE > INTSIZE
# if defined(PSX2008_HAS_ATOL)
#  define PSX2008_ATOI(a) atol(a)
# elif defined(PSX2008_HAS_ATOI)
#  define PSX2008_ATOI(a) atoi(a)
# endif
# if defined(PSX2008_HAS_FFSL)
#  define PSX2008_FFS(i) ffsl(i)
# elif defined(PSX2008_HAS_FFS)
#  define PSX2008_FFS(i) ffs(i)
# endif
# if defined(PSX2008_HAS_LABS)
#  define PSX2008_ABS(i) labs(i)
# elif defined(PSX2008_HAS_ABS)
#  define PSX2008_ABS(i) abs(i)
# endif
#else
# if defined(PSX2008_HAS_ATOI)
#  define PSX2008_ATOI(a) atoi(a)
# endif
# if defined(PSX2008_HAS_FFS)
#  define PSX2008_FFS(i) ffs(i)
# endif
# if defined(PSX2008_HAS_ABS)
#  define PSX2008_ABS(i) abs(i)
# endif
#endif

#if defined(PSX2008_HAS_LLROUND)
# define PSX2008_LROUND(x) llround(x)
# define PSX2008_LROUND_T long long
#elif defined(PSX2008_HAS_LROUND)
# define PSX2008_LROUND(x) lround(x)
# define PSX2008_LROUND_T long
#endif

#if defined(PSX2008_HAS_OPENAT) ||              \
  defined(PSX2008_HAS_CHDIR) ||                 \
  defined(PSX2008_HAS_CHMOD) ||                 \
  defined(PSX2008_HAS_CHOWN) ||                 \
  defined(PSX2008_HAS_FDATASYNC) ||             \
  defined(PSX2008_HAS_FDOPEN) ||                \
  defined(PSX2008_HAS_FDOPENDIR) ||             \
  defined(PSX2008_HAS_FSTAT) ||                 \
  defined(PSX2008_HAS_FUTIMENS) ||              \
  defined(PSX2008_HAS_FSYNC) ||                 \
  defined(PSX2008_HAS_TRUNCATE) ||              \
  defined(PSX2008_HAS_ISATTY) ||                \
  defined(PSX2008_HAS_POSIX_FADVISE) ||         \
  defined(PSX2008_HAS_POSIX_FALLOCATE) ||       \
  defined(PSX2008_HAS_READ) ||                  \
  defined(PSX2008_HAS_WRITE)
#define PSX2008_NEED_PSX_FILENO
#endif

#define RETURN_COMPLEX(z) { \
    EXTEND(SP, 2);          \
    mPUSHn(creal(z));       \
    mPUSHn(cimag(z));       \
}

#include "const-c.inc"

typedef IV SysRet;  /* returns -1 as undef, 0 as "0 but true", other unchanged */
typedef IV SysRet0; /* returns -1 as undef, other unchanged */
typedef IV SysRetTrue; /* returns 0 as "0 but true", undef otherwise */
typedef IV psx_fd_t; /* checks for file handle or descriptor via typemap */

/* Convert unsigned value to string. Shamelessly plagiarized from libowfat. */
#define FMT_UINT(uint_val, utmp_val, udest, ulen) {                     \
    UV ulen2;                                                           \
    char *ud = (char*)(udest);                                          \
    /* count digits */                                                  \
    for (ulen=1, utmp_val=(uint_val); utmp_val>9; ++ulen)               \
      utmp_val /= 10;                                                   \
    if (ud)                                                             \
      for (utmp_val=(uint_val), ud+=len, ulen2=ulen+1; --ulen2; utmp_val/=10) \
        *--ud = (char)((utmp_val%10)+'0');                              \
}

/* Push int_val as an IV, UV or PV depending on how big the value is.
 * tmp_val must be a variable of the same type as int_val to get the
 * string conversion right. */
#define PUSH_INT_OR_PV(int_val, tmp_val) {                \
    UV len;                                               \
    char buf[24];                                         \
    if ((int_val) < 0) {                                  \
      if ((int_val) >= IV_MIN)                            \
        mPUSHi(int_val);                                  \
      else {                                              \
        buf[0] = '-';                                     \
        FMT_UINT(-(int_val), tmp_val, buf+1, len);        \
        mPUSHp(buf, len+1);                               \
      }                                                   \
    }                                                     \
    else {                                                \
      if ((int_val) <= UV_MAX)                            \
        mPUSHu(int_val);                                  \
      else {                                              \
        FMT_UINT((int_val), tmp_val, buf, len);           \
        mPUSHp(buf, len);                                 \
      }                                                   \
    }                                                     \
}

/*
 * We return decimal strings for values outside the IV_MIN..UV_MAX range.
 * Since each struct stat member has its own integer type, be it signed or
 * unsigned, we cannot use a function for the string conversion because that
 * would need a fixed type declaration. Instead we use a macro and a second
 * struct stat to apply the correct type.
 */
static SV**
_push_stat_buf(pTHX_ SV **SP, struct stat *st) {
  struct stat st_tmp;

  PUSH_INT_OR_PV(st->st_dev, st_tmp.st_dev);
  PUSH_INT_OR_PV(st->st_ino, st_tmp.st_ino);
  PUSH_INT_OR_PV(st->st_mode, st_tmp.st_mode);
  PUSH_INT_OR_PV(st->st_nlink, st_tmp.st_nlink);
  PUSH_INT_OR_PV(st->st_uid, st_tmp.st_uid);
  PUSH_INT_OR_PV(st->st_gid, st_tmp.st_gid);
  PUSH_INT_OR_PV(st->st_rdev, st_tmp.st_rdev);
  PUSH_INT_OR_PV(st->st_size, st_tmp.st_size);
  PUSH_INT_OR_PV(st->st_atime, st_tmp.st_atime);
  PUSH_INT_OR_PV(st->st_mtime, st_tmp.st_mtime);
#ifdef PSX2008_HAS_ST_CTIME
  PUSH_INT_OR_PV(st->st_ctime, st_tmp.st_ctime);
#else
  PUSHs(&PL_sv_undef);
#endif
  /* actually these come before the times but we follow core stat */
#ifdef USE_STAT_BLOCKS
  PUSH_INT_OR_PV(st->st_blksize, st_tmp.st_blksize);
  PUSH_INT_OR_PV(st->st_blocks, st_tmp.st_blocks);
#else
  PUSHs(&PL_sv_undef);
  PUSHs(&PL_sv_undef);
#endif
#if defined(PSX2008_HAS_ST_ATIM)
  PUSH_INT_OR_PV(st->st_atim.tv_nsec, st_tmp.st_atim.tv_nsec);
  PUSH_INT_OR_PV(st->st_mtim.tv_nsec, st_tmp.st_mtim.tv_nsec);
# ifdef PSX2008_HAS_ST_CTIME
  PUSH_INT_OR_PV(st->st_ctim.tv_nsec, st_tmp.st_ctim.tv_nsec);
# else
  PUSHs(&PL_sv_undef);
# endif
#elif defined PSX2008_HAS_ST_ATIMENSEC
  PUSH_INT_OR_PV(st->st_atimensec, st_tmp.st_atimensec);
  PUSH_INT_OR_PV(st->st_mtimensec, st_tmp.st_mtimensec);
# ifdef PSX2008_HAS_ST_CTIME
  PUSH_INT_OR_PV(st->st_ctimensec, st_tmp.st_ctimensec);
# else
  PUSHs(&PL_sv_undef);
# endif
#endif

  return SP;
}

#define RETURN_STAT_BUF(rv, buf) {              \
    U8 gimme = GIMME_V;                         \
    if (gimme == G_LIST) {                      \
      if (rv == 0) {                            \
        EXTEND(SP, 16);                         \
        SP = _push_stat_buf(aTHX_ SP, &buf);    \
      }                                         \
    }                                           \
    else if (gimme == G_SCALAR)                 \
      PUSHs(boolSV(rv == 0));                   \
}

#ifdef PSX2008_HAS_READLINK
static char *
_readlink50c(const char *path, IV *dirfd) {
  /*
   * CORE::readlink() is broken because it uses a fixed-size result buffer of
   * PATH_MAX bytes (the manpage explicitly advises against this). We use a
   * dynamically growing buffer instead, leaving it up to the file system how
   * long a symlink may be.
   */
  size_t bufsize = 1023; /* This should be enough in most cases to read the link in one go. */
  ssize_t linklen;
  char *buf;

  Newxc(buf, bufsize, char, char);
  if (!buf) {
    errno = ENOMEM;
    return NULL;
  }

  while (1) {
    if (dirfd == NULL)
      linklen = readlink(path, buf, bufsize);
    else {
#ifdef PSX2008_HAS_READLINKAT
      linklen = readlinkat(*dirfd, path, buf, bufsize);
#else
      errno = ENOSYS;
      linklen = -1;
#endif
    }

    if (linklen != -1) {
      if ((size_t)linklen < bufsize) {
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
    bufsize |= 1;

    Renew(buf, bufsize, char);
    if (buf == NULL) {
      errno = ENOMEM;
      return NULL;
    }
  }
}
#endif

#if defined(PSX2008_HAS_READV) || defined(PSX2008_HAS_PREADV)
static void
_free_iov(struct iovec *iov, int cnt) {
  int i;

  if (iov)
    for (i = 0; i < cnt; i++)
      if (iov[i].iov_base)
        Safefree(iov[i].iov_base);
}
#endif

#ifdef PSX2008_HAS_READV
static int
_readv50c(pTHX_ int fd, SV *buffers, AV *sizes, SV *offset_sv, SV *flags_sv) {
  int i, rv;
  struct iovec *iov;
  void *iov_base;
  /* iov_len is a size_t but it is an error if the sum of the iov_len values
     exceeds SSIZE_MAX ... Dafuq? */
  size_t iov_len, iov_sum, sv_cur;

#ifndef PSX2008_HAS_PREADV
  if (offset_sv != NULL) {
    errno = ENOSYS;
    return -1;
  }
#endif
#ifndef PSX2008_HAS_PREADV2
  if (flags_sv != 0) {
    errno = ENOSYS;
    return -1;
  }
#endif

  /* The prototype for buffers is \[@$] so that we can be called either with
     @buffers or $buffers. @buffers gives us an array reference while $buffers
     gives us a reference to a scalar (which in return is hopefully an array
     reference). In the latter case we need to resolve the argument twice to
     get the array. */
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

  Size_t iovcnt = av_count(sizes);
  if (iovcnt == 0)
    return 0;
  if (iovcnt > INT_MAX) {
    errno = EINVAL;
    return -1;
  }

  Newxz(iov, iovcnt, struct iovec);
  if (!iov) {
    errno = ENOMEM;
    return -1;
  }

  for (i = 0; i < iovcnt; i++) {
    SV **size = av_fetch(sizes, i, 0);
    if (size && SvOK(*size)) {
      iov_len = SvUV(*size);
      if (iov_len > 0) {
        Newx(iov_base, iov_len, char);
        if (!iov_base) {
          _free_iov(iov, i);
          Safefree(iov);
          errno = ENOMEM;
          return -1;
        }
        iov[i].iov_base = iov_base;
        iov[i].iov_len = iov_len;
      }
    }
  }

  if (offset_sv == NULL)
    rv = readv(fd, iov, iovcnt);
  else if (flags_sv == NULL) {
#ifdef PSX2008_HAS_PREADV
    off_t offset = SvOK(offset_sv) ? (off_t)SvOFFT(offset_sv) : 0;
    rv = preadv(fd, iov, iovcnt, offset);
#else
    rv = -1;
    errno = ENOSYS;
#endif
  }
  else {
#ifdef PSX2008_HAS_PREADV2
    off_t offset = SvOK(offset_sv) ? (off_t)SvOFFT(offset_sv) : 0;
    int flags = SvOK(flags_sv) ? (int)SvIV(flags_sv) : 0;
    rv = preadv2(fd, iov, iovcnt, offset, flags);
#else
    rv = -1;
    errno = ENOSYS;
#endif
  }

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
      errno = ENOMEM;
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
#endif

#ifdef PSX2008_HAS_WRITEV
static int
_writev50c(pTHX_ int fd, AV *buffers, SV *offset_sv, SV *flags_sv) {
  struct iovec *iov;
  char *iov_base;
  STRLEN iov_len;
  int i, rv;

#ifndef PSX2008_HAS_PWRITEV
  if (offset_sv != NULL) {
    errno = ENOSYS;
    return -1;
  }
#endif
#ifndef PSX2008_HAS_PWRITEV2
  if (flags_sv != NULL) {
    errno = ENOSYS;
    return -1;
  }
#endif
  
  Size_t bufcnt = av_count(buffers);
  if (bufcnt == 0)
    return 0;
  if (bufcnt > INT_MAX) {
    errno = EINVAL;
    return -1;
  }

  Newxc(iov, bufcnt, struct iovec, struct iovec);
  if (!iov) {
    errno = ENOMEM;
    return -1;
  }

  int iovcnt = 0;

  for (i = 0; i < bufcnt; i++) {
    SV **av_elt = av_fetch(buffers, i, 0);
    if (av_elt && SvOK(*av_elt)) {
      iov_base = SvPV(*av_elt, iov_len);
      if (iov_len > 0) {
        iov[iovcnt].iov_base = (void*)iov_base;
        iov[iovcnt].iov_len = (size_t)iov_len;
        iovcnt++;
      }
    }
  }

  if (iovcnt == 0)
    rv = 0;
  else if (offset_sv == NULL) 
    rv = writev(fd, iov, iovcnt);
  else if (flags_sv == NULL) {
#ifdef PSX2008_HAS_PWRITEV
    off_t offset = SvOK(offset_sv) ? (off_t)SvOFFT(offset_sv) : 0;
    rv = pwritev(fd, iov, iovcnt, offset);
#else
    rv = -1;
    errno = ENOSYS;
#endif
  }
  else {
#ifdef PSX2008_HAS_PWRITEV2
    off_t offset = SvOK(offset_sv) ? (off_t)SvOFFT(offset_sv) : 0;
    int flags = SvOK(flags_sv) ? (int)SvIV(flags_sv) : 0;
    rv = pwritev2(fd, iov, iovcnt, offset, flags);
#else
    rv = -1;
    errno = ENOSYS;
#endif
  }

  Safefree(iov);
  return rv;
}
#endif

#ifdef PSX2008_HAS_OPENAT
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
#endif

#if PERL_BCDVERSION >= 0x5008005
# define psx_looks_like_number(sv) looks_like_number(sv)
#else
# define psx_looks_like_number(sv) ((SvPOK(sv) || SvPOKp(sv)) ? looks_like_number(sv) : (SvFLAGS(sv) & (SVf_NOK|SVp_NOK|SVf_IOK|SVp_IOK)))
#endif

#ifdef PSX2008_NEED_PSX_FILENO
static IV
psx_fileno(pTHX_ SV *sv) {
  IO *io;
  IV fn = -1;

  if (SvOK(sv)) {
    if (psx_looks_like_number(sv))
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
#endif

#ifdef PSX2008_HAS_CLOSE
static int
psx_close(pTHX_ SV *sv) {
  IO *io;
  int rv = -1;

  if (!SvOK(sv))
    errno = EBADF;
  else if (psx_looks_like_number(sv)) {
      int fn = SvIV(sv);
      rv = close(fn);
  }
  else if ((io = sv_2io(sv))) {
    if (IoIFP(io))
      rv = PerlIO_close(IoIFP(io));
    else if (IoDIRP(io)) {
#ifdef VOID_CLOSEDIR
      errno = 0;
      PerlDir_close(IoDIRP(io));
      rv = errno ? -1 : 0;
#else
      rv = PerlDir_close(IoDIRP(io));
#endif
      IoDIRP(io) = 0;
    }
    else
      errno = EBADF;
  }
  else
    errno = EBADF;

  return rv;
}
#endif

/* Macro for isalnum, isdigit, etc.
 * Contains the fix for https://github.com/Perl/perl5/issues/11148 which was
 * "solved" by them Perl guys by cowardly removing the functions from POSIX.
 */
#define ISFUNC(isfunc) {                                          \
    STRLEN len;                                                   \
    unsigned char *s = (unsigned char *) SvPV(charstring, len);   \
    unsigned char *e = s + len;                                   \
    for (RETVAL = len ? 1 : 0; RETVAL && s < e; s++)              \
      if (!isfunc(*s))                                            \
        RETVAL = 0;                                               \
  }

#define PACKNAME "POSIX::2008"

MODULE = POSIX::2008    PACKAGE = POSIX::2008

PROTOTYPES: ENABLE

INCLUDE: const-xs.inc

#ifdef PSX2008_HAS_A64L
long
a64l(char* s);

#endif

#ifdef PSX2008_HAS_L64A
char *
l64a(long value);

#endif

#ifdef PSX2008_HAS_ABORT
void
abort();

#endif

#ifdef PSX2008_HAS_ALARM
unsigned
alarm(unsigned seconds);

#endif

#ifdef PSX2008_HAS_ATOF
NV
atof(const char *str);

#endif

#ifdef PSX2008_ATOI
IV
atoi(const char *str);
  CODE:
    RETVAL = PSX2008_ATOI(str);
  OUTPUT: 
    RETVAL

#endif

#ifdef PSX2008_HAS_BASENAME 
char *
basename(char *path);

#endif

#ifdef PSX2008_HAS_CATCLOSE
int
catclose(nl_catd catd);

#endif

#ifdef PSX2008_HAS_CATGETS
char *
catgets(nl_catd catd, int set_id, int msg_id, const char *dflt);

#endif

#ifdef PSX2008_HAS_CATOPEN
nl_catd
catopen(const char *name, int oflag);

#endif

#ifdef PSX2008_HAS_CLOCK
clock_t
clock();

#endif

#ifdef PSX2008_HAS_CLOCK_GETCPUCLOCKID
void
clock_getcpuclockid(pid_t pid=PerlProc_getpid());
    INIT:
        clockid_t clock_id;
    PPCODE:
        if (clock_getcpuclockid(pid, &clock_id) == 0)
          mPUSHi((IV)clock_id);

#endif

#ifdef PSX2008_HAS_CLOCK_GETRES
void
clock_getres(clockid_t clock_id=CLOCK_REALTIME);
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

#endif

#ifdef PSX2008_HAS_CLOCK_SETTIME
void
clock_settime(clockid_t clock_id, time_t sec, long nsec);
  INIT:
    struct timespec tp = { sec, nsec };
  PPCODE:
    if (clock_settime(clock_id, &tp) == 0)
      mPUSHp("0 but true", 10);

#endif

#define PUSH_NANOSLEEP_REMAIN {                             \
    U8 gimme = GIMME_V;                                     \
    if (gimme == G_LIST) {                                  \
      EXTEND(SP, 2);                                        \
      mPUSHi(remain.tv_sec);                                \
      mPUSHi(remain.tv_nsec);                               \
    }                                                       \
    else if (gimme == G_SCALAR)                             \
      mPUSHn(remain.tv_sec + remain.tv_nsec/(NV)1e9);       \
}

#ifdef PSX2008_HAS_CLOCK_NANOSLEEP
void
clock_nanosleep(clockid_t clock_id, int flags, time_t sec, long nsec);
  INIT:
    int rv;
    const struct timespec request = { sec, nsec };
    struct timespec remain = { 0, 0 };
  PPCODE:
    rv = clock_nanosleep(clock_id, flags, &request, &remain);
    if (rv == 0 || (errno = rv) == EINTR)
      PUSH_NANOSLEEP_REMAIN;

#endif

#ifdef PSX2008_HAS_NANOSLEEP
void
nanosleep(time_t sec, long nsec);
  INIT:
    const struct timespec request = { sec, nsec };
    struct timespec remain = { 0, 0 };
  PPCODE:
    if (nanosleep(&request, &remain) == 0 || errno == EINTR)
      PUSH_NANOSLEEP_REMAIN;

#endif

#ifdef PSX2008_HAS_CONFSTR
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

#endif

#ifdef PSX2008_HAS_DIRNAME
char *
dirname(char *path);

#endif

#ifdef PSX2008_HAS_DLCLOSE
int
dlclose(void *handle);

#endif

#ifdef PSX2008_HAS_DLERROR
char *
dlerror();

#endif

#ifdef PSX2008_HAS_DLOPEN
void *
dlopen(const char *file, int mode);

#endif

#ifdef PSX2008_HAS_DLSYM
void *
dlsym(void *handle, const char *name);

#endif

#ifdef PSX2008_HAS_FEGETROUND
int
fegetround();

#endif

#ifdef PSX2008_HAS_FESETROUND
SysRetTrue
fesetround(int rounding_mode);

#endif

#ifdef PSX2008_HAS_FECLEAREXCEPT
SysRetTrue
feclearexcept(int excepts);

#endif

#ifdef PSX2008_HAS_FERAISEEXCEPT
SysRetTrue
feraiseexcept(int excepts);

#endif

#ifdef PSX2008_HAS_FETESTEXCEPT
int
fetestexcept(int excepts);

#endif

#ifdef PSX2008_FFS
IV
ffs(IV i);
  CODE:
    RETVAL = PSX2008_FFS(i);
  OUTPUT: 
    RETVAL

#endif

#ifdef PSX2008_HAS_FNMATCH
void
fnmatch(const char *pattern, const char *string, int flags);
  INIT:
    int rv;
  PPCODE:
    rv = fnmatch(pattern, string, flags);
    if (rv == 0 || rv == FNM_NOMATCH)
      mPUSHi(rv);

#endif

#ifdef PSX2008_HAS_KILLPG
int
killpg(pid_t pgrp, int sig);

#endif

#ifdef PSX2008_HAS_GETDATE
void
getdate(const char *string);
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

#endif

#ifdef PSX2008_HAS_GETDATE_ERR
int
getdate_err();
    CODE:
        RETVAL = getdate_err;
    OUTPUT:
        RETVAL

#endif

#ifdef PSX2008_HAS_STRPTIME
void
strptime(const char *s, const char *format, SV *sec = NULL, SV *min = NULL, SV *hour = NULL, SV *mday = NULL, SV *mon = NULL, SV *year = NULL, SV *wday = NULL, SV *yday = NULL, SV *isdst = NULL);
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
        if (GIMME != G_LIST)
          mPUSHi(remainder - s);
        else {
          EXTEND(SP, 9);
          if (tm.tm_sec < 0) PUSHs(&PL_sv_undef); else mPUSHi(tm.tm_sec);
          if (tm.tm_min < 0) PUSHs(&PL_sv_undef); else mPUSHi(tm.tm_min);
          if (tm.tm_hour < 0) PUSHs(&PL_sv_undef); else mPUSHi(tm.tm_hour);
          if (tm.tm_mday < 0) PUSHs(&PL_sv_undef); else mPUSHi(tm.tm_mday);
          if (tm.tm_mon < 0) PUSHs(&PL_sv_undef); else mPUSHi(tm.tm_mon);
          if (tm.tm_year == INT_MIN) PUSHs(&PL_sv_undef); else mPUSHi(tm.tm_year);
          if (tm.tm_wday < 0) PUSHs(&PL_sv_undef); else mPUSHi(tm.tm_wday);
          if (tm.tm_yday < 0) PUSHs(&PL_sv_undef); else mPUSHi(tm.tm_yday);
          mPUSHi(tm.tm_isdst);
        }
      }
    }

#endif

#ifdef PSX2008_HAS_GETHOSTID
long
gethostid();

#endif

#ifdef PSX2008_HAS_GETHOSTNAME
void
gethostname();
  INIT:
#if !defined(MAXHOSTNAMELEN) || MAXHOSTNAMELEN < 256
    char name[256];
#else
    char name[MAXHOSTNAMELEN];
#endif
  PPCODE:
    if (gethostname(name, sizeof(name)) == 0)
      XSRETURN_PV(name);

#endif

#ifdef PSX2008_HAS_GETITIMER
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

#endif

#ifdef PSX2008_HAS_SETITIMER
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

#endif

#ifdef PSX2008_HAS_GETPRIORITY
void
getpriority(int which=PRIO_PROCESS, id_t who=0);
  INIT:
    int rv;
  PPCODE:
    errno = 0;
    rv = getpriority(which, who);
    if (rv != -1 || errno == 0)
      mPUSHi(rv);

#endif

#ifdef PSX2008_HAS_SETPRIORITY
SysRetTrue
setpriority(int prio, int which=PRIO_PROCESS, id_t who=0);
    CODE:
        RETVAL = setpriority(which, who, prio);
    OUTPUT:
        RETVAL

#endif

#ifdef PSX2008_HAS_GETSID
pid_t
getsid(pid_t pid=0);

#endif

#ifdef PSX2008_HAS_SETSID
pid_t
setsid();

#endif

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

#ifdef PSX2008_HAS_ENDUTXENT
void
endutxent();

#endif

#ifdef PSX2008_HAS_GETUTXENT
void
getutxent();
    INIT:
        struct utmpx *utxent = getutxent();
    PPCODE:
        RETURN_UTXENT;

#endif

#ifdef PSX2008_HAS_GETUTXID
void
getutxid(short ut_type, char *ut_id=NULL);
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

#endif

#ifdef PSX2008_HAS_GETUTXLINE
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

#endif

#ifdef PSX2008_HAS_SETUTXENT
void
setutxent();

#endif

#ifdef PSX2008_HAS_DRAND48
NV
drand48();

#endif

#ifdef PSX2008_HAS_ERAND48
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

#endif

#ifdef PSX2008_HAS_JRAND48
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

#endif

#ifdef PSX2008_HAS_LRAND48
long
lrand48();

#endif

#ifdef PSX2008_HAS_MRAND48
long
mrand48();

#endif

#ifdef PSX2008_HAS_NICE
void
nice(int incr);
  INIT:
    int rv;
  PPCODE:
    errno = 0;
    rv = nice(incr);
    if (rv != -1 || errno == 0)
      mPUSHi(rv);

#endif

#ifdef PSX2008_HAS_SEED48
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

#endif

#ifdef PSX2008_HAS_SRAND48
void
srand48(long seedval);

#endif

#ifdef PSX2008_HAS_RANDOM
long
random();

#endif

#ifdef PSX2008_HAS_SRANDOM
void
srandom(unsigned seed);

#endif

#ifdef PSX2008_HAS_GETEGID
gid_t
getegid();

#endif

#ifdef PSX2008_HAS_GETEUID
uid_t
geteuid();

#endif

#ifdef PSX2008_HAS_GETGID
gid_t
getgid();

#endif

#ifdef PSX2008_HAS_GETUID
uid_t
getuid();

#endif

#ifdef PSX2008_HAS_SETEGID
int
setegid(gid_t gid);

#endif

#ifdef PSX2008_HAS_SETEUID
int
seteuid(uid_t uid);

#endif

#ifdef PSX2008_HAS_SETGID
int
setgid(gid_t gid);

#endif

#ifdef PSX2008_HAS_SETREGID
int
setregid(gid_t rgid, gid_t egid);

#endif

#ifdef PSX2008_HAS_SETREUID
int
setreuid(uid_t ruid, uid_t euid);

#endif

#ifdef PSX2008_HAS_SETUID
int
setuid(uid_t uid);

#endif

#ifdef PSX2008_HAS_SIGHOLD
int
sighold(int sig);

#endif

#ifdef PSX2008_HAS_SIGIGNORE
int
sigignore(int sig);

#endif

#ifdef PSX2008_HAS_SIGPAUSE
void
sigpause(int sig);

#endif

#ifdef PSX2008_HAS_SIGRELSE
int
sigrelse(int sig);

#endif

#ifdef PSX2008_HAS_TIMER_CREATE
timer_t
timer_create(clockid_t clockid, int sig);
  PREINIT:
    struct sigevent sevp;
    timer_t timerid;
    int rv;
  CODE:
  {
    sevp.sigev_notify = SIGEV_SIGNAL;
    sevp.sigev_signo = sig;
    sevp.sigev_value.sival_int = 0;

    rv = timer_create(clockid, &sevp, &timerid);

    if (rv == 0)
      RETVAL = timerid;
    else
      RETVAL = (timer_t)0;
  }
  OUTPUT:
    RETVAL

#endif

#ifdef PSX2008_HAS_TIMER_DELETE
SysRetTrue
timer_delete(timer_t timerid);

#endif

#ifdef PSX2008_HAS_TIMER_GETOVERRUN
SysRet0
timer_getoverrun(timer_t timerid);

#endif

#ifdef PSX2008_HAS_TIMER_GETTIME
void
timer_gettime(timer_t timerid);
  PREINIT:
    struct itimerspec curr_value;
    int rv;
  PPCODE:
  {
    rv = timer_gettime(timerid, &curr_value);

    if (rv == 0) {
      EXTEND(SP, 4);
      mPUSHi(curr_value.it_interval.tv_sec);
      mPUSHi(curr_value.it_interval.tv_nsec);
      mPUSHi(curr_value.it_value.tv_sec);
      mPUSHi(curr_value.it_value.tv_nsec);
    }
  }

#endif

#ifdef PSX2008_HAS_TIMER_SETTIME
void
timer_settime(timer_t timerid, int flags, time_t interval_sec, long interval_nsec, time_t initial_sec=-1, long initial_nsec=-1);
  PREINIT:
    struct itimerspec new_value, old_value;
    int rv;
  PPCODE:
  {
    new_value.it_interval.tv_sec = interval_sec;
    new_value.it_interval.tv_nsec = interval_nsec;
    if (initial_sec < 0 || initial_nsec < 0)
      new_value.it_value = new_value.it_interval;
    else {
      new_value.it_value.tv_sec = initial_sec;
      new_value.it_value.tv_nsec = initial_nsec;
    }

    rv = timer_settime(timerid, flags, &new_value, &old_value);

    if (rv == 0) {
      EXTEND(SP, 4);
      mPUSHi(old_value.it_interval.tv_sec);
      mPUSHi(old_value.it_interval.tv_nsec);
      mPUSHi(old_value.it_value.tv_sec);
      mPUSHi(old_value.it_value.tv_nsec);
    }
  }

#endif

## I/O-related functions
########################

#ifdef PSX2008_HAS_CHDIR
SysRetTrue
chdir(SV *what);
  INIT:
    int fd;
    char *path;
  CODE: 
    if (!SvOK(what)) {
      RETVAL = -1;
      errno = ENOENT;
    }
    else if (SvPOK(what) || SvPOKp(what)) {
      path = SvPV_nolen(what);
      RETVAL = chdir(path);
    } 
    else {
      fd = psx_fileno(aTHX_ what);
#ifdef PSX2008_HAS_FCHDIR
      RETVAL = fchdir(fd);
#else
      errno = (fd < 0) ? EBADF : ENOSYS;
      RETVAL = -1;
#endif
    }
  OUTPUT:
    RETVAL

#endif

#ifdef PSX2008_HAS_CHMOD
SysRetTrue
chmod(SV *what, mode_t mode);
  INIT:
    int fd;
    char *path;
  CODE: 
    if (!SvOK(what)) {
      RETVAL = -1;
      errno = ENOENT;
    }
    else if (SvPOK(what) || SvPOKp(what)) {
      path = SvPV_nolen(what);
      RETVAL = chmod(path, mode);
    } 
    else {
      fd = psx_fileno(aTHX_ what);
#ifdef PSX2008_HAS_FCHMOD
      RETVAL = fchmod(fd, mode);
#else
      errno = (fd < 0) ? EBADF : ENOSYS;
      RETVAL = -1;
#endif
    }
  OUTPUT:
    RETVAL

#endif

#ifdef PSX2008_HAS_CHOWN
SysRetTrue
chown(SV *what, uid_t owner, gid_t group);
  INIT:
    int fd;
    char *path;
  CODE: 
    if (!SvOK(what)) {
      RETVAL = -1;
      errno = ENOENT;
    }
    else if (SvPOK(what) || SvPOKp(what)) {
      path = SvPV_nolen(what);
      RETVAL = chown(path, owner, group);
    } 
    else {
      fd = psx_fileno(aTHX_ what);
#ifdef PSX2008_HAS_FCHOWN
      RETVAL = fchown(fd, owner, group);
#else
      errno = (fd < 0) ? EBADF : ENOSYS;
      RETVAL = -1;
#endif
    }
  OUTPUT:
    RETVAL

#endif

#ifdef PSX2008_HAS_LCHOWN
SysRetTrue
lchown(const char *path, uid_t owner, gid_t group);

#endif

#ifdef PSX2008_HAS_ACCESS
SysRetTrue
access(const char *path, int mode);

#endif

#ifdef PSX2008_HAS_FDATASYNC
SysRetTrue
fdatasync(psx_fd_t fd);

#endif

#ifdef PSX2008_HAS_FSYNC
SysRetTrue
fsync(psx_fd_t fd);

#endif

#ifdef PSX2008_HAS_STAT
void
stat(SV *what);
  INIT:
    int rv = -1;
    struct stat buf;
  PPCODE:
    if (!SvOK(what))
      errno = ENOENT;
    else if (SvPOK(what) || SvPOKp(what)) {
      char *path = SvPV_nolen(what);
      rv = stat(path, &buf);
    }
    else {
#ifdef PSX2008_HAS_FSTAT
      int fd = psx_fileno(aTHX_ what);
      rv = fstat(fd, &buf);
#else
      errno = ENOSYS;
#endif
    }
    RETURN_STAT_BUF(rv, buf);

#endif

#ifdef PSX2008_HAS_LSTAT
void
lstat(const char *path);
  INIT:
    int rv;
    struct stat buf;
  PPCODE:
    rv = lstat(path, &buf);
    RETURN_STAT_BUF(rv, buf);

#endif

#ifdef PSX2008_HAS_ISATTY
int
isatty(psx_fd_t fd);

#endif

#ifdef PSX2008_HAS_ISALNUM
int
isalnum(SV *charstring)
  CODE:
    ISFUNC(isalnum)
  OUTPUT:
    RETVAL

#endif

#ifdef PSX2008_HAS_ISALPHA
int
isalpha(SV *charstring)
  CODE:
    ISFUNC(isalpha)
  OUTPUT:
    RETVAL

#endif

#ifdef PSX2008_HAS_ISASCII
int
isascii(SV *charstring)
  CODE:
    ISFUNC(isascii)
  OUTPUT:
    RETVAL

#endif

#ifdef PSX2008_HAS_ISBLANK
int
isblank(SV *charstring)
  CODE:
    ISFUNC(isblank)
  OUTPUT:
    RETVAL

#endif

#ifdef PSX2008_HAS_ISCNTRL
int
iscntrl(SV *charstring)
  CODE:
    ISFUNC(iscntrl)
  OUTPUT:
    RETVAL

#endif

#ifdef PSX2008_HAS_ISDIGIT
int
isdigit(SV *charstring)
  CODE:
    ISFUNC(isdigit)
  OUTPUT:
    RETVAL

#endif

#ifdef PSX2008_HAS_ISGRAPH
int
isgraph(SV *charstring)
  CODE:
    ISFUNC(isgraph)
  OUTPUT:
    RETVAL

#endif

#ifdef PSX2008_HAS_ISLOWER
int
islower(SV *charstring)
  CODE:
    ISFUNC(islower)
  OUTPUT:
    RETVAL

#endif

#ifdef PSX2008_HAS_ISPRINT
int
isprint(SV *charstring)
  CODE:
    ISFUNC(isprint)
  OUTPUT:
    RETVAL

#endif

#ifdef PSX2008_HAS_ISPUNCT
int
ispunct(SV *charstring)
  CODE:
    ISFUNC(ispunct)
  OUTPUT:
    RETVAL

#endif

#ifdef PSX2008_HAS_ISSPACE
int
isspace(SV *charstring)
  CODE:
    ISFUNC(isspace)
  OUTPUT:
    RETVAL

#endif

#ifdef PSX2008_HAS_ISUPPER
int
isupper(SV *charstring)
  CODE:
    ISFUNC(isupper)
  OUTPUT:
    RETVAL

#endif

#ifdef PSX2008_HAS_ISXDIGIT
int
isxdigit(SV *charstring)
  CODE:
    ISFUNC(isxdigit)
  OUTPUT:
    RETVAL

#endif

#ifdef PSX2008_HAS_LINK
SysRetTrue
link(const char *path1, const char *path2);

#endif

#ifdef PSX2008_HAS_MKDIR
SysRetTrue
mkdir(const char *path, mode_t mode=0777);

#endif

#ifdef PSX2008_HAS_MKDTEMP
char *
mkdtemp(char *template);

#endif

#ifdef PSX2008_HAS_MKFIFO
SysRetTrue
mkfifo(const char *path, mode_t mode);

#endif

#ifdef PSX2008_HAS_MKNOD
SysRetTrue
mknod(const char *path, mode_t mode, dev_t dev);

#endif

#ifdef PSX2008_HAS_MKSTEMP
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

#endif

#ifdef PSX2008_HAS_FDOPEN
FILE*
fdopen(psx_fd_t fd, const char *mode);

#endif

#ifdef PSX2008_HAS_FDOPENDIR
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
     * https://www.perlmonks.org/?node_id=1197703
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

#endif

##
## POSIX::open(), read() and write() return "0 but true" for 0, which
## is not quite what you would expect. We return a real 0.
##

SysRet0
open(const char *path, int oflag=O_RDONLY, mode_t mode=0666);

#ifdef PSX2008_HAS_CLOSE
SysRetTrue
close(SV *fd);
    CODE:
        RETVAL = psx_close(aTHX_ fd);
    OUTPUT:
        RETVAL

#endif

#ifdef PSX2008_HAS_FACCESSAT
SysRetTrue
faccessat(psx_fd_t dirfd, const char *path, int amode, int flags=0);

#endif

#ifdef PSX2008_HAS_FCHMODAT
SysRetTrue
fchmodat(psx_fd_t dirfd, const char *path, mode_t mode, int flags=0);

#endif

#ifdef PSX2008_HAS_FCHOWNAT
SysRetTrue
fchownat(psx_fd_t dirfd, const char *path, uid_t owner, gid_t group, int flags=0);

#endif

#ifdef PSX2008_HAS_FSTATAT
void
fstatat(psx_fd_t dirfd, const char *path, int flags=0);
  INIT:
    int rv;
    struct stat buf;
  PPCODE:
    rv = fstatat(dirfd, path, &buf, flags);
    RETURN_STAT_BUF(rv, buf);

#endif

#ifdef PSX2008_HAS_LINKAT
SysRetTrue
linkat(psx_fd_t olddirfd, const char *oldpath, psx_fd_t newdirfd, const char *newpath, int flags=0);

#endif

#ifdef PSX2008_HAS_MKDIRAT
SysRetTrue
mkdirat(psx_fd_t dirfd, const char *path, mode_t mode);

#endif

#ifdef PSX2008_HAS_MKFIFOAT
SysRetTrue
mkfifoat(psx_fd_t dirfd, const char *path, mode_t mode);

#endif

#ifdef PSX2008_HAS_MKNODAT
SysRetTrue
mknodat(psx_fd_t dirfd, const char *path, mode_t mode, dev_t dev);

#endif

#ifdef PSX2008_HAS_OPENAT
void
openat(SV *dirfdsv, const char *path, ...);
  ALIAS:
    openat2 = 1
  PREINIT:
    int got_fd, dir_fd, path_fd, flags;
    int return_handle = 0;
    mode_t mode;
    GV *gv = NULL;
    DIR *dirp = NULL;
    FILE *filep = NULL;
    PerlIO *pio_filep = NULL;
    struct stat st;
  PPCODE:
  {
#ifndef PSX2008_HAS_OPENAT2
    if (ix != 0) {
      errno = ENOSYS;
      XSRETURN_UNDEF;
    }
#endif
    if (!SvOK(dirfdsv)) {
      errno = EBADF;
      XSRETURN_UNDEF;
    }

    /* Allow dirfdsv to be a reference to AT_FDCWD in order to get a file
       handle instead of a file descriptor */
    if (SvROK(dirfdsv) && SvTYPE(SvRV(dirfdsv)) == SVt_IV) {
      if (SvIV(SvRV(dirfdsv)) != AT_FDCWD) {
        errno = EBADF;
        XSRETURN_UNDEF;
      }
      got_fd = 0;
      dir_fd = AT_FDCWD;
    }
    else {
      got_fd = psx_looks_like_number(dirfdsv);
      dir_fd = psx_fileno(aTHX_ dirfdsv);
      if (dir_fd < 0 && dir_fd != AT_FDCWD) {
        errno = EBADF;
        XSRETURN_UNDEF;
      }
    }

    if (ix == 0) {
      /* openat() */
      if (items > 4)
        croak_xs_usage(cv, "dirfd, path[, flags[, mode]]");
      flags = (items > 2) ? SvIV(ST(2)) : O_RDONLY;
      mode = (items > 3) ? SvIV(ST(3)) : 0666;
      path_fd = openat(dir_fd, path, flags, mode);
    }
#ifdef PSX2008_HAS_OPENAT2
    else {
      /* openat2() */
      if (items != 3)
        croak_xs_usage(cv, "dirfd, path, how");
      else {
        SV* const how_sv = ST(2);
        if (!SvROK(how_sv) || SvTYPE(SvRV(how_sv)) != SVt_PVHV)
          croak("%s::openat2: 'how' is not a HASH reference", PACKNAME);
        else {
          HV* how_hv = (HV*)SvRV(how_sv);
          SV** how_flags = hv_fetchs(how_hv, "flags", 0);
          SV** how_mode = hv_fetchs(how_hv, "mode", 0);
          SV** how_resolve = hv_fetchs(how_hv, "resolve", 0);
          struct open_how how = {
            .flags   = how_flags ? SvUV(*how_flags) : 0,
            .mode    = how_mode ? SvUV(*how_mode) : 0,
            .resolve = how_resolve ? SvUV(*how_resolve) : 0
          };
          flags = how.flags; /* needed for fdopen() below */
          path_fd = syscall(SYS_openat2, dir_fd, path, &how, sizeof(how));
        }
      }
    }
#endif

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
      if (gv) {
        if (S_ISDIR(st.st_mode)) {
          dirp = fdopendir(path_fd);
          if (dirp) {
            IO *io = GvIOn(gv);
            IoDIRP(io) = dirp;
            return_handle = 1;
          }
        }
        else {
          const char *raw = flags2raw(flags);
          filep = fdopen(path_fd, raw);
          if (filep) {
            pio_filep = PerlIO_importFILE(filep, raw);
            if (pio_filep && do_open(gv, "+<&", 3, FALSE, 0, 0, pio_filep))
              return_handle = 1;
          }
        }
      }
    }

    if (return_handle) {
      SV *retvalsv = newRV_inc((SV*)gv);
      retvalsv = sv_bless(retvalsv, GvSTASH(gv));
      mPUSHs(retvalsv);
    }
    else if (dirp)
      closedir(dirp);
    else if (pio_filep)
      PerlIO_close(pio_filep);
    else if (filep)
      fclose(filep);
    else
      close(path_fd);

    /* https://github.com/Perl/perl5/issues/9493 */
    if (gv) 
      (void) hv_delete(GvSTASH(gv), GvNAME(gv), GvNAMELEN(gv), G_DISCARD);
  }

#endif

#ifdef PSX2008_HAS_READLINK
char *
readlink(const char *path);
    CODE:
        RETVAL = _readlink50c(path, NULL);
    OUTPUT:
        RETVAL
    CLEANUP:
        if (RETVAL != NULL)
            Safefree(RETVAL);

#endif

#ifdef PSX2008_HAS_READLINKAT
char *
readlinkat(psx_fd_t dirfd, const char *path);
    CODE:
        RETVAL = _readlink50c(path, &dirfd);
    OUTPUT:
        RETVAL
    CLEANUP:
        if (RETVAL != NULL)
          Safefree(RETVAL);

#endif

#ifdef PSX2008_HAS_REALPATH
char *
realpath(const char *path);
    CODE:
        errno = 0;
        RETVAL = realpath(path, NULL);
    OUTPUT:
        RETVAL
    CLEANUP:
        if (RETVAL != NULL)
          safesysfree(RETVAL);

#endif

#ifdef PSX2008_HAS_RENAMEAT
SysRetTrue
renameat(psx_fd_t olddirfd, const char *oldpath, psx_fd_t newdirfd, const char *newpath);

#endif

#ifdef PSX2008_HAS_SYMLINKAT
SysRetTrue
symlinkat(const char *target, psx_fd_t newdirfd, const char *linkpath);

#endif

#ifdef PSX2008_HAS_UNLINKAT
SysRetTrue
unlinkat(psx_fd_t dirfd, const char *path, int flags=0);

#endif

#ifdef PSX2008_HAS_UTIMENSAT
SysRetTrue
utimensat(psx_fd_t dirfd, const char *path, int flags = 0, time_t atime_sec = 0, long atime_nsec = UTIME_NOW, time_t mtime_sec = 0, long mtime_nsec = UTIME_NOW);
    INIT:
        struct timespec times[2] = { { atime_sec, atime_nsec },
                                     { mtime_sec, mtime_nsec } };
    CODE:
        RETVAL = utimensat(dirfd, path, times, flags);
    OUTPUT:
        RETVAL

#endif

#ifdef PSX2008_HAS_READ
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

#endif

#ifdef PSX2008_HAS_WRITE
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

#endif

#ifdef PSX2008_HAS_READV
SysRet0
readv(psx_fd_t fd, SV *buffers, AV *sizes);
    PROTOTYPE: $\[@$]$
    CODE:
        RETVAL = _readv50c(aTHX_ fd, buffers, sizes, NULL, NULL);
    OUTPUT:
        RETVAL

#endif

#ifdef PSX2008_HAS_PREADV
SysRet0
preadv(psx_fd_t fd, SV *buffers, AV *sizes, SV *offset=&PL_sv_undef);
  PROTOTYPE: $\[@$]$;$
  CODE:
    RETVAL = _readv50c(aTHX_ fd, buffers, sizes, offset, NULL);
  OUTPUT:
    RETVAL

#endif

#ifdef PSX2008_HAS_PREADV2
SysRet0
preadv2(psx_fd_t fd, SV *buffers, AV *sizes, SV *offset=&PL_sv_undef, SV *flags=&PL_sv_undef);
  PROTOTYPE: $\[@$]$;$$
  CODE:
    RETVAL = _readv50c(aTHX_ fd, buffers, sizes, offset, flags);
  OUTPUT:
    RETVAL

#endif

#ifdef PSX2008_HAS_WRITEV
SysRet0
writev(psx_fd_t fd, AV *buffers);
    CODE:
        RETVAL = _writev50c(aTHX_ fd, buffers, NULL, NULL);
    OUTPUT:
        RETVAL

#endif

#ifdef PSX2008_HAS_PWRITEV
SysRet0
pwritev(psx_fd_t fd, AV *buffers, SV *offset=&PL_sv_undef);
  CODE:
    RETVAL = _writev50c(aTHX_ fd, buffers, offset, NULL);
  OUTPUT:
    RETVAL

#endif

#ifdef PSX2008_HAS_PWRITEV2
SysRet0
pwritev2(psx_fd_t fd, AV *buffers, SV *offset=&PL_sv_undef, SV *flags=&PL_sv_undef);
  CODE:
    RETVAL = _writev50c(aTHX_ fd, buffers, offset, flags);
  OUTPUT:
    RETVAL

#endif

#ifdef PSX2008_HAS_PREAD
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
          warn("Offset %lld outside string", (long long int)buf_offset);
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
        off_t f_offset = (offset != NULL && SvOK(offset)) ? (off_t)SvOFFT(offset) : 0;
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

#endif

#ifdef PSX2008_HAS_PWRITE
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
        warn("Offset %lld outside string", (long long int)buf_offset);
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
        off_t f_offset = (offset != NULL && SvOK(offset)) ? (off_t)SvOFFT(offset) : 0;
        RETVAL = pwrite(fd, cbuf + buf_offset, i_count, f_offset);
      }
      else
        RETVAL = 0;
    }
  }
  OUTPUT:
    RETVAL

#endif

#ifdef PSX2008_HAS_POSIX_FADVISE
SysRetTrue
posix_fadvise(psx_fd_t fd, off_t offset, off_t len, int advice);
  CODE:
    errno = posix_fadvise(fd, offset, len, advice);
    RETVAL = errno ? -1 : 0;
  OUTPUT:
    RETVAL

#endif

#ifdef PSX2008_HAS_POSIX_FALLOCATE
SysRetTrue
posix_fallocate(psx_fd_t fd, off_t offset, off_t len);
  CODE:
    errno = posix_fallocate(fd, offset, len);
    RETVAL = errno ? -1 : 0;
  OUTPUT:
    RETVAL

#endif

#ifdef PSX2008_HAS_PTSNAME
char *
ptsname(int fd);
  INIT:
#ifdef PSX2008_HAS_PTSNAME_R
    int rv;
    char name[MAXPATHLEN];
#endif
  CODE:
#ifdef PSX2008_HAS_PTSNAME_R
    rv = ptsname_r(fd, name, sizeof(name));
    if (rv == 0)
      RETVAL = name;
    else {
      RETVAL = NULL;
      errno = rv;
    }
#else
    RETVAL = ptsname(fd);
#endif
  OUTPUT:
    RETVAL

#endif

#ifdef PSX2008_HAS_TTYNAME
char *
ttyname(int fd);
  INIT:
#ifdef PSX2008_HAS_TTYNAME_R
    int rv;
    char name[MAXPATHLEN];
#endif
  CODE:
#ifdef PSX2008_HAS_TTYNAME_R
    rv = ttyname_r(fd, name, sizeof(name));
    if (rv == 0)
      RETVAL = name;
    else {
      RETVAL = NULL;
      errno = rv;
    }
#else
    RETVAL = ttyname(fd);
#endif
  OUTPUT:
    RETVAL

#endif

##
## POSIX::remove() is incorrectly implemented as:
## '(-d $_[0]) ? CORE::rmdir($_[0]) : CORE::unlink($_[0])'.
##
## If $_[0] is a symlink to a directory, POSIX::remove() fails with ENOTDIR
## from rmdir() instead of removing the symlink (POSIX requires remove() to
## be equivalent to unlink() for non-directories).
##
## This could be fixed like this (correct errno check depends on OS):
## 'unlink $_[0] or ($!{EISDIR} || $!{EPERM} ? rmdir $_[0] : undef)'
##
## Or just use the actual library call like we do here.
##

#if defined(__linux__) || defined(__CYGWIN__)
#define UNLINK_ISDIR_ERRNO (errno == EISDIR)
#elif !defined(_WIN32)
#define UNLINK_ISDIR_ERRNO (errno == EISDIR || errno == EPERM)
#else
#define UNLINK_ISDIR_ERRNO (errno == EISDIR || errno == EPERM || errno == EACCES)
#endif

#if !defined(PSX2008_HAS_REMOVE) || (defined(_WIN32) && !defined(__CYGWIN__))
# if defined(PSX2008_HAS_UNLINK) && defined(PSX2008_HAS_RMDIR)
void
remove(const char *path);
  PPCODE:
    if (unlink(path) == 0 || (UNLINK_ISDIR_ERRNO && rmdir(path) == 0))
      mPUSHp("0 but true", 10);

# else

# endif
#else
SysRetTrue
remove(const char *path);

#endif

#ifdef PSX2008_HAS_RENAME
SysRetTrue
rename(const char *old, const char *new);

#endif

#ifdef PSX2008_HAS_RMDIR
SysRetTrue
rmdir(const char *path);

#endif

#ifdef PSX2008_HAS_SYMLINK
SysRetTrue
symlink(const char *target, const char *linkpath);

#endif

#ifdef PSX2008_HAS_SYNC
void
sync();

#endif

#ifdef PSX2008_HAS_TRUNCATE
SysRetTrue
truncate(SV *what, off_t length);
  INIT:
    int fd;
    char *path;
  CODE:
    if (!SvOK(what)) {
      RETVAL = -1;
      errno = ENOENT;
    }
    else if (SvPOK(what) || SvPOKp(what)) {
      path = SvPV_nolen(what);
      RETVAL = truncate(path, length);
    }
    else {
      fd = psx_fileno(aTHX_ what);
#ifdef PSX2008_HAS_FTRUNCATE
      RETVAL = ftruncate(fd, length);
#else
      errno = (fd < 0) ? EBADF : ENOSYS;
      RETVAL = -1;
#endif
    }
  OUTPUT:
    RETVAL

#endif

#ifdef PSX2008_HAS_UNLINK
SysRetTrue
unlink(const char *path);

#endif

#ifdef PSX2008_HAS_FUTIMENS
SysRetTrue
futimens(psx_fd_t fd, time_t atime_sec = 0, long atime_nsec = UTIME_NOW, time_t mtime_sec = 0, long mtime_nsec = UTIME_NOW);
  INIT:
    const struct timespec times[2] = { { atime_sec, atime_nsec },
                                       { mtime_sec, mtime_nsec } };
  CODE:
    RETVAL = futimens(fd, times);
  OUTPUT:
    RETVAL

#endif

## Integer and real number arithmetic
#####################################

#ifdef PSX2008_ABS
IV
abs(IV i)
  CODE:
    RETVAL = PSX2008_ABS(i);
  OUTPUT:
    RETVAL

#endif

#ifdef PSX2008_HAS_ACOS
NV
acos(double x);

#endif

#ifdef PSX2008_HAS_ACOSH
NV
acosh(double x);

#endif

#ifdef PSX2008_HAS_ASIN
NV
asin(double x);

#endif

#ifdef PSX2008_HAS_ASINH
NV
asinh(double x);

#endif

#ifdef PSX2008_HAS_ATAN
NV
atan(double x);

#endif

#ifdef PSX2008_HAS_ATAN2
NV
atan2(double y, double x);

#endif

#ifdef PSX2008_HAS_ATANH
NV
atanh(double x);

#endif

#ifdef PSX2008_HAS_CBRT
NV
cbrt(double x);

#endif

#ifdef PSX2008_HAS_CEIL
NV
ceil(double x);

#endif

#ifdef PSX2008_HAS_COPYSIGN
NV
copysign(double x, double y);

#endif

#ifdef PSX2008_HAS_COS
NV
cos(double x);

#endif

#ifdef PSX2008_HAS_COSH
NV
cosh(double x);

#endif

#ifdef PSX2008_DIV
void
div(IV numer, IV denom);
    INIT:
        PSX2008_DIV_T result;
    PPCODE:
        result = PSX2008_DIV(numer, denom);
        EXTEND(SP, 2);
        mPUSHi(result.quot);
        mPUSHi(result.rem);

#endif

#ifdef PSX2008_HAS_ERF
NV
erf(double x);

#endif

#ifdef PSX2008_HAS_ERFC
NV
erfc(double x);

#endif

#ifdef PSX2008_HAS_EXP
NV
exp(double x);

#endif

#ifdef PSX2008_HAS_EXP2
NV
exp2(double x);

#endif

#ifdef PSX2008_HAS_EXPM1
NV
expm1(double x);

#endif

#ifdef PSX2008_HAS_FDIM
NV
fdim(double x, double y);

#endif

#ifdef PSX2008_HAS_FLOOR
NV
floor(double x);

#endif

#ifdef PSX2008_HAS_FMA
NV
fma(double x, double y, double z);

#endif

#ifdef PSX2008_HAS_FMAX
NV
fmax(double x, double y);

#endif

#ifdef PSX2008_HAS_FMIN
NV
fmin(double x, double y);

#endif

#ifdef PSX2008_HAS_FMOD
NV
fmod(double x, double y);

#endif

#ifdef PSX2008_HAS_FPCLASSIFY

int
fpclassify(double x);

#endif

#ifdef PSX2008_HAS_HYPOT
NV
hypot(double x, double y);

#endif

#ifdef PSX2008_HAS_ILOGB
int
ilogb(double x);

#endif

#ifdef PSX2008_HAS_ISFINITE
int
isfinite(double x);

#endif

#ifdef PSX2008_HAS_ISINF
int
isinf(double x);

#endif

#ifdef PSX2008_HAS_ISNAN
int
isnan(double x);

#endif

#ifdef PSX2008_HAS_ISNORMAL
int
isnormal(double x);

#endif

#ifdef PSX2008_HAS_ISGREATEREQUAL
int
isgreaterequal(NV x, NV y);

#endif

#ifdef PSX2008_HAS_ISLESS
int
isless(NV x, NV y);

#endif

#ifdef PSX2008_HAS_ISLESSEQUAL
int
islessequal(NV x, NV y);

#endif

#ifdef PSX2008_HAS_ISLESSGREATER
int
islessgreater(NV x, NV y);

#endif

#ifdef PSX2008_HAS_ISUNORDERED
int
isunordered(NV x, NV y);

#endif

#ifdef PSX2008_HAS_J0
NV
j0(double x);

#endif

#ifdef PSX2008_HAS_J1
NV
j1(double x);

#endif

#ifdef PSX2008_HAS_JN
NV
jn(int n, double x);

#endif

#ifdef PSX2008_HAS_LDEXP
NV
ldexp(double x, int exp);

#endif

#ifdef PSX2008_HAS_LGAMMA
NV
lgamma(double x);

#endif

#ifdef PSX2008_HAS_LOG
NV
log(double x);

#endif

#ifdef PSX2008_HAS_LOG10
NV
log10(double x);

#endif

#ifdef PSX2008_HAS_LOG1P
NV
log1p(double x);

#endif

#ifdef PSX2008_HAS_LOG2
NV
log2(double x);

#endif

#ifdef PSX2008_HAS_LOGB
NV
logb(double x);

#endif

#ifdef PSX2008_LROUND
void
lround(double x)
  INIT:
    PSX2008_LROUND_T ret, tmp;
  PPCODE:
    errno = 0;
    feclearexcept(FE_ALL_EXCEPT);
    ret = PSX2008_LROUND(x);
    if (errno == 0 && fetestexcept(FE_ALL_EXCEPT) == 0)
      PUSH_INT_OR_PV(ret, tmp);

#endif

#ifdef PSX2008_HAS_NEARBYINT
NV
nearbyint(double x);

#endif

#ifdef PSX2008_HAS_NEXTAFTER
NV
nextafter(double x, double y);

#endif

#ifdef PSX2008_HAS_NEXTTOWARD
NV
nexttoward(double x, NV y);

#endif

#ifdef PSX2008_HAS_REMAINDER
void
remainder(double x, double y);
  INIT:
    double res;
  PPCODE:
    errno = 0;
    feclearexcept(FE_ALL_EXCEPT);
    res = remainder(x, y);
    if (errno == 0 && fetestexcept(FE_ALL_EXCEPT) == 0)
      mPUSHn(res);

#endif

#ifdef PSX2008_HAS_REMQUO
void
remquo(double x, double y);
  INIT:
    int quo;
    double res;
  PPCODE:
    errno = 0;
    feclearexcept(FE_ALL_EXCEPT);
    res = remquo(x, y, &quo);
    if (errno == 0 && fetestexcept(FE_ALL_EXCEPT) == 0) {
      mPUSHn(res);
      mPUSHi(quo);
    }

#endif

#ifdef PSX2008_HAS_ROUND
NV
round(double x);

#endif

#ifdef PSX2008_SCALBN
NV
scalbn(double x, IV n);
  CODE:
    RETVAL = PSX2008_SCALBN(x, n);
  OUTPUT:
    RETVAL

#endif

#ifdef PSX2008_HAS_SIGNBIT
int
signbit(double x);

#endif

#ifdef PSX2008_HAS_SIN
NV
sin(double x);

#endif

#ifdef PSX2008_HAS_SINH
NV
sinh(double x);

#endif

#ifdef PSX2008_HAS_TAN
NV
tan(double x);

#endif

#ifdef PSX2008_HAS_TANH
NV
tanh(double x);

#endif

#ifdef PSX2008_HAS_TGAMMA
NV
tgamma(double x);

#endif

#ifdef PSX2008_HAS_TRUNC
NV
trunc(double x);

#endif

#ifdef PSX2008_HAS_Y0
NV
y0(double x);

#endif

#ifdef PSX2008_HAS_Y1
NV
y1(double x);

#endif

#ifdef PSX2008_HAS_YN
NV
yn(int n, double x);

#endif

## Complex arithmetic functions
###############################

#ifdef PSX2008_HAS_CABS
NV
cabs(double re, double im);
  INIT:
    double complex z = re + im * I;
  CODE:
    RETVAL = cabs(z);
  OUTPUT:
    RETVAL

#endif

#ifdef PSX2008_HAS_CARG
NV
carg(double re, double im);
  INIT:
    double complex z = re + im * I;
  CODE:
    RETVAL = carg(z);
  OUTPUT:
    RETVAL

#endif

#ifdef PSX2008_HAS_CIMAG
NV
cimag(double re, double im);
  INIT:
    double complex z = re + im * I;
  CODE:
    RETVAL = cimag(z);
  OUTPUT:
    RETVAL

#endif

#ifdef PSX2008_HAS_CONJ
void
conj(double re, double im);
  INIT:
    double complex z = re + im * I;
    double complex result = conj(z);
  PPCODE:
    RETURN_COMPLEX(result);

#endif

#ifdef PSX2008_HAS_CPROJ
NV
cproj(double re, double im);
  INIT:
    double complex z = re + im * I;
  CODE:
    RETVAL = cproj(z);
  OUTPUT:
    RETVAL

#endif

#ifdef PSX2008_HAS_CREAL
NV
creal(double re, double im);
  INIT:
    double complex z = re + im * I;
  CODE:
    RETVAL = creal(z);
  OUTPUT:
    RETVAL

#endif

#ifdef PSX2008_HAS_CEXP
void
cexp(double re, double im);
  INIT:
    double complex z = re + im * I;
    double complex result = cexp(z);
  PPCODE:
    RETURN_COMPLEX(result);

#endif

#ifdef PSX2008_HAS_CLOG
void
clog(double re, double im);
  INIT:
    double complex z = re + im * I;
    double complex result = clog(z);
  PPCODE:
    RETURN_COMPLEX(result);

#endif

#ifdef PSX2008_HAS_CPOW
void
cpow(double re_x, double im_x, double re_y, double im_y);
  INIT:
    double complex x = re_x + im_x * I;
    double complex y = re_y + im_y * I;
    double complex result = cpow(x, y);
  PPCODE:
    RETURN_COMPLEX(result);

#endif

#ifdef PSX2008_HAS_CSQRT
void
csqrt(double re, double im);
  INIT:
    double complex z = re + im * I;
    double complex result = csqrt(z);
  PPCODE:
    RETURN_COMPLEX(result);

#endif

#ifdef PSX2008_HAS_CACOS
void
cacos(double re, double im);
  INIT:
    double complex z = re + im * I;
    double complex result = cacos(z);
  PPCODE:
    RETURN_COMPLEX(result);

#endif

#ifdef PSX2008_HAS_CACOSH
void
cacosh(double re, double im);
  INIT:
    double complex z = re + im * I;
    double complex result = cacosh(z);
  PPCODE:
    RETURN_COMPLEX(result);

#endif

#ifdef PSX2008_HAS_CASIN
void
casin(double re, double im);
  INIT:
    double complex z = re + im * I;
    double complex result = casin(z);
  PPCODE:
    RETURN_COMPLEX(result);

#endif

#ifdef PSX2008_HAS_CASINH
void
casinh(double re, double im);
  INIT:
    double complex z = re + im * I;
    double complex result = casinh(z);
  PPCODE:
    RETURN_COMPLEX(result);

#endif

#ifdef PSX2008_HAS_CATAN
void
catan(double re, double im);
  INIT:
    double complex z = re + im * I;
    double complex result = catan(z);
  PPCODE:
    RETURN_COMPLEX(result);

#endif

#ifdef PSX2008_HAS_CATANH
void
catanh(double re, double im);
  INIT:
    double complex z = re + im * I;
    double complex result = catanh(z);
  PPCODE:
    RETURN_COMPLEX(result);

#endif

#ifdef PSX2008_HAS_CCOS
void
ccos(double re, double im);
  INIT:
    double complex z = re + im * I;
    double complex result = ccos(z);
  PPCODE:
    RETURN_COMPLEX(result);

#endif

#ifdef PSX2008_HAS_CCOSH
void
ccosh(double re, double im);
  INIT:
    double complex z = re + im * I;
    double complex result = ccosh(z);
  PPCODE:
    RETURN_COMPLEX(result);

#endif

#ifdef PSX2008_HAS_CSIN
void
csin(double re, double im);
  INIT:
    double complex z = re + im * I;
    double complex result = csin(z);
  PPCODE:
    RETURN_COMPLEX(result);

#endif

#ifdef PSX2008_HAS_CSINH
void
csinh(double re, double im);
  INIT:
    double complex z = re + im * I;
    double complex result = csinh(z);
  PPCODE:
    RETURN_COMPLEX(result);

#endif

#ifdef PSX2008_HAS_CTAN
void
ctan(double re, double im);
  INIT:
    double complex z = re + im * I;
    double complex result = ctan(z);
  PPCODE:
    RETURN_COMPLEX(result);

#endif

#ifdef PSX2008_HAS_CTANH
void
ctanh(double re, double im);
  INIT:
    double complex z = re + im * I;
    double complex result = ctanh(z);
  PPCODE:
    RETURN_COMPLEX(result);

#endif

## DESTROY is called when a file handle we created (e.g. in openat)
## is cleaned up. This is just a dummy to silence AUTOLOAD. We leave
## it up to Perl to take the necessary steps.
void
DESTROY(...);
PPCODE:

BOOT:
{
}

# vim: set ts=4 sw=4 sts=4 expandtab:
