/* vim: set ts=2 sw=2 sts=2 expandtab:
*/

#define PACKNAME "POSIX::2008"

#ifndef _GNU_SOURCE
#define _GNU_SOURCE
#endif

#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

/* ppport.h says we don't need caller_cx but a few cpantesters report
 * "undefined symbol: caller_cx".
 */
#define NEED_caller_cx
#define NEED_croak_xs_usage
#include "ppport.h"
#include "2008.h"

#if defined(PERL_IMPLICIT_SYS)
#undef dup
#undef open
#undef close
#undef stat
#undef fstat
#undef lstat
#undef readlink
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
#undef fdopendir
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
#undef symlink
#undef unlink
#undef write
# endif
#endif

#ifdef PSX2008_HAS_COMPLEX_H
#include <complex.h>
#endif
#include <ctype.h>
#ifdef I_DIRENT
#include <dirent.h>
#endif
#ifdef PSX2008_HAS_DLFCN_H
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
#if defined(USE_QUADMATH) && defined(I_QUADMATH)
#include <quadmath.h>
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
#if defined(PSX2008_HAS_SYS_RANDOM_H) && (defined(PSX2008_HAS_GETENTROPY) || defined(PSX2008_HAS_GETRANDOM))
#include <sys/random.h>
#endif
#ifdef I_SYS_RESOURCE
#include <sys/resource.h>
#endif
#ifdef I_SYS_STAT
#include <sys/stat.h>
#endif
#ifdef PSX2008_HAS_STATVFS
#include <sys/statvfs.h>
#endif
#ifdef I_SYS_TYPES
#include <sys/types.h>
#endif
#ifdef PSX2008_HAS_SYS_UIO_H
#include <sys/uio.h>
#endif
#ifdef I_TIME
#include <time.h>
#endif
#ifdef PSX2008_HAS_UNISTD_H
#include <unistd.h>
#endif
#ifdef PSX2008_HAS_UTMPX_H
#include <utmpx.h>
#endif
#if defined(PSX2008_HAS_POLL_H)
#  include <poll.h>
#elif defined(PSX2008_HAS_SYS_POLL_H)
#  include <sys/poll.h>
#endif

#if defined(PSX2008_HAS_OPENAT2) || \
  (defined(PSX2008_HAS_GETRANDOM_SYS) && !defined(PSX2008_HAS_GETRANDOM))
#include <sys/syscall.h>
#endif

#ifdef PSX2008_HAS_OPENAT2
#include <linux/openat2.h>
#endif

#ifdef PSX2008_HAS_BCRYPTGENRANDOM
#include <windows.h>
#include <bcrypt.h>
#endif

#ifndef GETENTROPY_MAX
#define GETENTROPY_MAX 256
#endif

#if !defined(PSX2008_HAS_GETENTROPY) &&         \
  !defined(PSX2008_HAS_GETRANDOM) &&            \
  !defined(PSX2008_HAS_GETRANDOM_SYS) &&        \
  !defined(PSX2008_HAS_ARC4RANDOM_BUF) &&       \
  !defined(PSX2008_HAS_BCRYPTGENRANDOM)
# if defined(PSX2008_HAS_RNDR)
#  define _psx_cpu_rand_step_ok(buf) (__rndr(buf) == 0)
#  include <arm_acle.h>
#  include <stdint.h>
   typedef uint64_t _psx_cpu_rand_t;
# elif defined(PSX2008_HAS_RDRAND64)
#  define _psx_cpu_rand_step_ok(buf) (_rdrand64_step(buf) != 0)
#  ifdef __INTEL_COMPILER  /* https://stackoverflow.com/a/72265912 */
#   include <stdint.h>
    typedef uint64_t _psx_cpu_rand_t;
#  else
    typedef unsigned long long _psx_cpu_rand_t;
#  endif
# elif defined(PSX2008_HAS_RDRAND32)
#  define _psx_cpu_rand_step_ok(buf) (_rdrand32_step(buf) != 0)
   typedef unsigned int _psx_cpu_rand_t;
# endif
# if defined(PSX2008_HAS_RDRAND64) || defined(PSX2008_HAS_RDRAND32)
#  include <immintrin.h>
# endif
#endif

#if !defined(INFINITY) && defined(NV_INF)
#define INFINITY NV_INF
#endif

#ifndef SVf_QUOTEDPREFIX
#define SVf_QUOTEDPREFIX SVf
#endif

#ifndef PSX2008_HAS_NFDS_T
#define nfds_t unsigned long
#endif

#ifndef SSIZE_MAX
#define SSIZE_MAX (SSize_t)(~(Size_t)0 >> 1)
#endif

#if IVSIZE > LONGSIZE && defined(PSX2008_HAS_LLDIV)
#  define PSX2008_DIV_T lldiv_t
#  define PSX2008_DIV(numer, denom) lldiv(numer, denom)
#endif
#if IVSIZE > INTSIZE && !defined(PSX2008_DIV) && defined(PSX2008_HAS_LDIV)
#  define PSX2008_DIV_T ldiv_t
#  define PSX2008_DIV(numer, denom) ldiv(numer, denom)
#endif
#if !defined(PSX2008_DIV) && defined(PSX2008_HAS_DIV)
#  define PSX2008_DIV_T div_t
#  define PSX2008_DIV(numer, denom) div(numer, denom)
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

#if defined(USE_QUADMATH)
# define PSX2008_COMPLEX_T __complex128
#elif defined(PSX2008_HAS_COMPLEX_H)
# if defined(USE_LONG_DOUBLE)
#  define PSX2008_COMPLEX_T long double complex
# else
#  define PSX2008_COMPLEX_T double complex
# endif
#endif

/* __real__/__imag__ are gcc extensions but more efficient than "re + im * I".
 * Since libquadmath is gcc-specific we don't have to worry about the #else
 * branch if USE_QUADMATH is defined, do we? */

#if defined(CMPLX) && !defined(USE_LONGDOUBLE) && !defined(USE_QUADMATH)
# define COMPLEX_FROM_RE_IM(z, r, i) ( (z) = CMPLX((r), (i)) )
#elif defined(CMPLXL) && defined(USE_LONGDOUBLE)
# define COMPLEX_FROM_RE_IM(z, r, i) ( (z) = CMPLXL((r), (i)) )
#elif defined(__GNUC__)
# define COMPLEX_FROM_RE_IM(z, r, i) \
  ( (__real__ (z) = (r)), (__imag__ (z) = (i)) )
#else
# define COMPLEX_FROM_RE_IM(z, r, i) ( (z) = (r) + (i) * I )
#endif

#if defined(USE_QUADMATH)
# define RETURN_COMPLEX(z)                                      \
  STMT_START {                                                  \
    mPUSHs(newSVnv(crealq(z)));                                 \
    mPUSHs(newSVnv(cimagq(z)));                                 \
  } STMT_END
#elif defined(USE_LONGDOUBLE)
# define RETURN_COMPLEX(z)                                      \
  STMT_START {                                                  \
    mPUSHs(newSVnv(creall(z)));                                 \
    mPUSHs(newSVnv(cimagl(z)));                                 \
  } STMT_END
#else
# define RETURN_COMPLEX(z)                                      \
  STMT_START {                                                  \
    mPUSHs(newSVnv(creal(z)));                                  \
    mPUSHs(newSVnv(cimag(z)));                                  \
  } STMT_END
#endif

#if defined(AT_FDCWD) ||                   \
  defined(PSX2008_HAS_FCHDIR) ||           \
  defined(PSX2008_HAS_FCHMOD) ||           \
  defined(PSX2008_HAS_FCHOWN) ||           \
  defined(PSX2008_HAS_FDATASYNC) ||        \
  defined(PSX2008_HAS_FDOPEN) ||           \
  defined(PSX2008_HAS_FDOPENDIR) ||        \
  defined(PSX2008_HAS_FEXECVE) ||          \
  defined(PSX2008_HAS_FPATHCONF) ||        \
  defined(PSX2008_HAS_FSTAT) ||            \
  defined(PSX2008_HAS_FSTATVFS) ||         \
  defined(PSX2008_HAS_FSYNC) ||            \
  defined(PSX2008_HAS_FTRUNCATE) ||        \
  defined(PSX2008_HAS_FUTIMENS) ||         \
  defined(PSX2008_HAS_GRANTPT) ||          \
  defined(PSX2008_HAS_ISATTY) ||           \
  defined(PSX2008_HAS_POLL) ||             \
  defined(PSX2008_HAS_POSIX_FADVISE) ||    \
  defined(PSX2008_HAS_POSIX_FALLOCATE) ||  \
  defined(PSX2008_HAS_POSIX_OPENPT) ||     \
  defined(PSX2008_HAS_POLL) ||             \
  defined(PSX2008_HAS_PTSNAME) ||          \
  defined(PSX2008_HAS_READ) ||             \
  defined(PSX2008_HAS_READV) ||            \
  defined(PSX2008_HAS_PREAD) ||            \
  defined(PSX2008_HAS_PREADV) ||           \
  defined(PSX2008_HAS_PREADV2) ||          \
  defined(PSX2008_HAS_TTYNAME) ||          \
  defined(PSX2008_HAS_UNLOCKPT) ||         \
  defined(PSX2008_HAS_WRITE) ||            \
  defined(PSX2008_HAS_WRITEV) ||           \
  defined(PSX2008_HAS_PWRITE) ||           \
  defined(PSX2008_HAS_PWRITEV) ||          \
  defined(PSX2008_HAS_PWRITEV2)
#define PSX2008_NEED_PSX_FILENO
#endif

#if IVSIZE < Off_t_size
#define SvOFFt(sv) ((Off_t)SvNV(sv))
#else
#define SvOFFt(sv) ((Off_t)SvIV(sv))
#endif

#if IVSIZE < Size_t_size
#define SvSIZEt(sv) ((Size_t)SvNV(sv))
#define SvSTRLEN(sv) ((STRLEN)SvNV(sv))
#else
#define SvSIZEt(sv) ((Size_t)SvIV(sv))
#define SvSTRLEN(sv) ((STRLEN)SvIV(sv))
#endif

/* https://perldoc.perl.org/perlguts#Read-Only-Values */
#if PERL_BCDVERSION >= 0x5018000
# define SvTRULYREADONLY(sv) SvREADONLY(sv)
#else
# define SvTRULYREADONLY(sv) (SvREADONLY(sv) && !SvIsCOW(sv))
#endif

typedef IV SysRet; /* returns -1 as undef, 0 as "0 but true", other unchanged */
typedef IV SysRet0; /* returns -1 as undef, other unchanged */
typedef IV SysRetTrue; /* returns 0 as "0 but true", undef otherwise */
typedef int psx_fd_t; /* checks for file handle or descriptor via typemap */

/* https://sourceforge.net/p/mingw-w64/feature-requests/68/ */
#if defined(__MINGW32__) && defined(__STRICT_ANSI__) && !defined(USE_QUADMATH)
double __cdecl j0(double);
double __cdecl j1(double);
double __cdecl jn(int, double);
double __cdecl y0(double);
double __cdecl y1(double);
double __cdecl yn(int, double);
#endif

#define SvIsARRAY(sv) (SvROK(sv) && SvTYPE(SvRV(sv)) == SVt_PVAV)
#define SvIsNEGATIVE(sv) _psx_SvIsNEGATIVE(aTHX_ sv)

/* Treat omitted and explicitly undef arguments as if intended by the caller
 * to avoid annoying "uninitialized" warnings. */
#define SvIsUNDEF_onpurpose(sv) (!(sv) || (sv) == &PL_sv_undef)

/* Round up l to the next multiple of PERL_STRLEN_ROUNDUP_QUANTUM even if it
 * already is a multiple so that we always have room for a trailing '\0'. +1
 * does the trick. */
#define TopUpLEN(l) \
  ((l)+1 < (l) ? (croak_memory_wrap(),0) : PERL_STRLEN_ROUNDUP((l)+1))

#include "const-c.inc"

#ifdef _psx_cpu_rand_step_ok
# ifdef PSX2008_HAS_RNDR
__attribute__((target("+rng")))
# endif
PERL_STATIC_INLINE void
_cpu_rand50c(void *buf, Size_t len)
{
  /* Crypto++ says rdrand_step doesn't need a retry limit. So be it. */
  if (LIKELY(buf)) {
    _psx_cpu_rand_t *ubuf = (_psx_cpu_rand_t *)buf;
    Size_t rest = len % sizeof(_psx_cpu_rand_t);
#pragma GCC unroll 0  /* https://github.com/llvm/llvm-project/issues/42332 */
    for (len /= sizeof(_psx_cpu_rand_t); len; len--, ubuf++)
      while (! _psx_cpu_rand_step_ok(ubuf)) ;
    if (rest) {
      _psx_cpu_rand_t u;
      while (! _psx_cpu_rand_step_ok(&u)) ;
      memcpy(ubuf, &u, rest);
    }
  }
}
#endif

static unsigned
_psx_SvIsNEGATIVE(pTHX_ SV *sv)
{
  SV *tmpsv;
  if (!sv)
    return 0;
  SvGETMAGIC(sv);
  if (UNLIKELY(SvAMAGIC(sv)) && (tmpsv = AMG_CALLun(sv, numer)))
    sv = tmpsv;
  if (!SvOK(sv))
    return 0;
  if (SvIOK(sv))
    return !SvIsUV(sv) && SvIVX(sv) < 0;
  if (SvNOK(sv))
    return SvNVX(sv) < 0;
  if (SvPOK(sv))
    return !!(grok_number(SvPVX_const(sv), SvCUR(sv), NULL) & IS_NUMBER_NEG);
  return 0;
}

static int
_psx_looks_like_number(pTHX_ SV *sv)
{
  SV *tmpsv;
  SvGETMAGIC(sv);
  if (UNLIKELY(SvAMAGIC(sv)) && (tmpsv = AMG_CALLun(sv, numer)))
    sv = tmpsv;
#if PERL_BCDVERSION >= 0x5008005
  return looks_like_number(sv);
#else
  if (SvPOK(sv) || SvPOKp(sv))
    return looks_like_number(sv);
  else
    return (SvFLAGS(sv) & (SVf_NOK|SVp_NOK|SVf_IOK|SVp_IOK));
#endif
}

/* strnlen() shamelessly plagiarized from dietlibc (https://www.fefe.de/) */
static Size_t
_strnlen(const char *s, Size_t maxlen)
{
  const char *n = (const char *)memchr(s, 0, maxlen);
  if (!n)
    n = s + maxlen;
  return n - s;
}

/* _fmt_uint() shamelessly plagiarized from libowfat (https://www.fefe.de/) */
static unsigned
_fmt_uint(char *dest, UINT_MAX_TYPE u)
{
  unsigned len, len2;
  UINT_MAX_TYPE tmp;
  /* count digits */
  for (len=1, tmp=u; tmp>9; ++len)
    tmp /= 10;
  if (dest)
    for (tmp=u, dest+=len, len2=len+1; --len2; tmp/=10)
      *--dest = (char)((tmp%10)+'0');
  return len;
}

static unsigned
_fmt_neg_int(char *dest, INT_MAX_TYPE i)
{
  if (dest)
    *dest++ = '-';
  return _fmt_uint(dest, (UINT_MAX_TYPE)(-(i+1))+1) + 1;
}

static SV*
_fmt_uint_2sv(pTHX_ UINT_MAX_TYPE u)
{
  char dest[24];
  unsigned len = _fmt_uint(dest, u);
  return newSVpvn(dest, len);
}

static SV*
_fmt_neg_int_2sv(pTHX_ INT_MAX_TYPE i)
{
  char dest[24];
  unsigned len = _fmt_neg_int(dest, i);
  return newSVpvn(dest, len);
}

#ifndef CLANG_DIAG_IGNORE_STMT
# define CLANG_DIAG_IGNORE_STMT(x) NOOP
# define CLANG_DIAG_RESTORE_STMT NOOP
#endif
#ifndef GCC_DIAG_IGNORE_STMT
# define GCC_DIAG_IGNORE_STMT(x) NOOP
# define GCC_DIAG_RESTORE_STMT NOOP
#endif

/* Push int_val as an IV, UV or PV depending on how big the value is. */
#define PUSH_INT_OR_PV(int_val) STMT_START {                            \
    SV *piop_tmp_sv;                                                    \
    CLANG_DIAG_IGNORE_STMT(-Wtautological-compare);                     \
    GCC_DIAG_IGNORE_STMT(-Wtype-limits);                                \
    if ((int_val) < 0) {                                                \
      if (LIKELY((INT_MAX_TYPE)(int_val) >= (INT_MAX_TYPE)IV_MIN))      \
        piop_tmp_sv = newSViv((IV)(int_val));                           \
      else                                                              \
        piop_tmp_sv = _fmt_neg_int_2sv(aTHX_ int_val);                  \
    }                                                                   \
    else if (LIKELY((UINT_MAX_TYPE)(int_val) <= (UINT_MAX_TYPE)IV_MAX)) \
      piop_tmp_sv = newSViv((IV)(int_val));                             \
    else if ((UINT_MAX_TYPE)(int_val) <= (UINT_MAX_TYPE)UV_MAX)         \
      piop_tmp_sv = newSVuv((UV)(int_val));                             \
    else                                                                \
      piop_tmp_sv = _fmt_uint_2sv(aTHX_ int_val);                       \
    GCC_DIAG_RESTORE_STMT;                                              \
    CLANG_DIAG_RESTORE_STMT;                                            \
    mPUSHs(piop_tmp_sv);                                                \
  } STMT_END

#ifdef PSX2008_HAS_STAT
/* We return decimal strings for values outside the IV_MIN..UV_MAX range. */
static SV **
_push_stat_buf(pTHX_ SV **SP, struct stat *st)
{
  PUSH_INT_OR_PV(st->st_dev);
  PUSH_INT_OR_PV(st->st_ino);
  PUSH_INT_OR_PV(st->st_mode);
  PUSH_INT_OR_PV(st->st_nlink);
  PUSH_INT_OR_PV(st->st_uid);
  PUSH_INT_OR_PV(st->st_gid);
  PUSH_INT_OR_PV(st->st_rdev);
  PUSH_INT_OR_PV(st->st_size);
  PUSH_INT_OR_PV(st->st_atime);
  PUSH_INT_OR_PV(st->st_mtime);
#ifdef PSX2008_HAS_ST_CTIME
  PUSH_INT_OR_PV(st->st_ctime);
#else
  PUSHs(&PL_sv_undef);
#endif
  /* Actually these come before the times but we follow core stat. */
#ifdef USE_STAT_BLOCKS
  PUSH_INT_OR_PV(st->st_blksize);
  PUSH_INT_OR_PV(st->st_blocks);
#else
  PUSHs(&PL_sv_undef);
  PUSHs(&PL_sv_undef);
#endif
#if defined(PSX2008_HAS_ST_ATIM)
  PUSH_INT_OR_PV(st->st_atim.tv_nsec);
  PUSH_INT_OR_PV(st->st_mtim.tv_nsec);
# ifdef PSX2008_HAS_ST_CTIME
  PUSH_INT_OR_PV(st->st_ctim.tv_nsec);
# else
  PUSHs(&PL_sv_undef);
# endif
#elif defined(PSX2008_HAS_ST_ATIMENSEC)
  PUSH_INT_OR_PV(st->st_atimensec);
  PUSH_INT_OR_PV(st->st_mtimensec);
# ifdef PSX2008_HAS_ST_CTIME
  PUSH_INT_OR_PV(st->st_ctimensec);
# else
  PUSHs(&PL_sv_undef);
# endif
#endif

  return SP;
}

#define RETURN_STAT_BUF(rv, buf) STMT_START {   \
    switch (GIMME_V) {                          \
      case G_SCALAR:                            \
        PUSHs(boolSV((rv) == 0));               \
        break;                                  \
      case G_LIST:                              \
        if ((rv) == 0) {                        \
          EXTEND(SP, 16);                       \
          SP = _push_stat_buf(aTHX_ SP, &buf);  \
        }                                       \
    }                                           \
} STMT_END
#endif

#ifdef PSX2008_HAS_STATVFS
static SV **
_push_statvfs_buf(pTHX_ SV **SP, struct statvfs *st)
{
  PUSH_INT_OR_PV(st->f_bsize);
  PUSH_INT_OR_PV(st->f_frsize);
  PUSH_INT_OR_PV(st->f_blocks);
  PUSH_INT_OR_PV(st->f_bfree);
  PUSH_INT_OR_PV(st->f_bavail);
  PUSH_INT_OR_PV(st->f_files);
  PUSH_INT_OR_PV(st->f_ffree);
  PUSH_INT_OR_PV(st->f_favail);
  PUSH_INT_OR_PV(st->f_fsid);
  PUSH_INT_OR_PV(st->f_flag);
  PUSH_INT_OR_PV(st->f_namemax);

  return SP;
}

#define RETURN_STATVFS_BUF(rv, buf) STMT_START {        \
    switch (GIMME_V) {                                  \
      case G_SCALAR:                                    \
        PUSHs(boolSV(rv == 0));                         \
        break;                                          \
      case G_LIST:                                      \
        if (rv == 0) {                                  \
          EXTEND(SP, 11);                               \
          SP = _push_statvfs_buf(aTHX_ SP, &buf);       \
        }                                               \
    }                                                   \
} STMT_END
#endif

#ifdef PSX2008_NEED_PSX_FILENO
static int
_psx_fileno_nomg(pTHX_ SV *sv)
{
  IO *io;
  int fn = -1;

  /* On Solaris, AT_FDCWD is 0xffd19553 (4291925331), so don't do any integer
   * range checks, just cast the SvIV to int and may the --force be with you.
   * https://github.com/python/cpython/issues/60169
   */
  if (SvOK(sv)) {
    if (_psx_looks_like_number(aTHX_ sv))
      fn = (int)SvIV(sv);
    else if ((io = sv_2io(sv))) {
      /* Magic part taken from Perl 5.8.9's pp_fileno. */
      const MAGIC *mg = SvTIED_mg((SV*)io, PERL_MAGIC_tiedscalar);
      if (mg) {
        dSP;
        PUSHMARK(SP);
        XPUSHs(SvTIED_obj((SV*)io, mg));
        PUTBACK;
        ENTER;
        call_method("FILENO", G_SCALAR);
        LEAVE;
        SPAGAIN;
        fn = (int)POPi;
        PUTBACK;
      }
      else if (IoIFP(io))  /* from open() or sysopen() */
        fn = PerlIO_fileno(IoIFP(io));
      else if (IoDIRP(io)) {  /* from opendir() */
#if defined(HAS_DIRFD) || defined(HAS_DIR_DD_FD)
        fn = my_dirfd(IoDIRP(io));
#endif
      }
    }
  }

  return fn;
}

PERL_STATIC_INLINE int
_psx_fileno(pTHX_ SV *sv)
{
  SvGETMAGIC(sv);
  return _psx_fileno_nomg(aTHX_ sv);
}
#endif

#if defined(PSX2008_HAS_EXECVEAT) || defined(PSX2008_HAS_FEXECVE)
/* We don't check for '\0' or '=' within args or env. Not our business. */
static void
_execve50c(pTHX_ int fd, const char *path, AV *args, SV *envsv, int flags)
{
  Size_t argc, n;
  char **argv, **envp;
  char *empty_env[] = { NULL };
  HV *envhv = NULL;

# ifndef PSX2008_HAS_EXECVEAT
  if (path) { SETERRNO(ENOSYS, SS$_UNSUPPORTED); return; }
# endif
# ifndef PSX2008_HAS_FEXECVE
  if (!path) { SETERRNO(ENOSYS, SS$_UNSUPPORTED); return; }
# endif

  if (!SvIsUNDEF_onpurpose(envsv)) {
    SvGETMAGIC(envsv);
    if (SvROK(envsv) && SvTYPE(SvRV(envsv)) == SVt_PVHV)
      envhv = (HV*)SvRV(envsv);
    else {
      const char *func = path ? "execveat" : "fexecve";
      croak("%s::%s: 'env' is not a HASH reference: %" SVf_QUOTEDPREFIX,
            PACKNAME, func, SVfARG(envsv));
    }
  }

  /* Allocate memory for argv pointers; +1 for terminating NULL pointer. */
  argc = av_count(args);
  if (argc+1 == 0)
    --argc;
  if (((argc+1)*sizeof(char*))/sizeof(char*) != (argc+1))
    goto TheZohan;
  argv = (char**)safemalloc((argc+1)*sizeof(char*));
  if (!argv)
    goto TheZohan;
  SAVEFREEPV(argv);
  argv[argc] = NULL;

  /* Build argv string array from args array ref. */
  for (n = 0; n < argc; n++) {
    SV **argsv;
    argv[n] = NULL;
    argsv = av_fetch(args, n, 0);
    if (!argsv)
      argv[n] = (char*)""; /* This is what Perl's exec() does for placeholders. */
    else {
      STRLEN cur;
      (void)SvPV(*argsv, cur);
      if (LIKELY(cur+1)) {
        /* +1 for final '\0' to be on the safe side. */
        argv[n] = SvGROW(*argsv, cur+1);
        argv[n][cur] = '\0';
      }
      else
        goto TheZohan;
    }
  }

  if (!envhv) {
    extern char **environ;
    envp = environ ? environ : empty_env;
  }
  else {
    Size_t envc;
    /* Count envhv keys. */
    if (!SvMAGICAL(envhv))
      envc = HvUSEDKEYS(envhv);
    else {
      /* HvUSEDKEYS() doesn't work for magic hashes (e.g. DB_File). */
      hv_iterinit(envhv);
      for (envc = 0; hv_iternext(envhv) && envc+1; envc++) {}
    }
    if (envc+1 == 0)
      --envc;
    if (((envc+1)*sizeof(char*))/sizeof(char*) != (envc+1))
      goto TheZohan;
    envp = (char**)safemalloc((envc+1)*sizeof(char*));
    if (!envp)
      goto TheZohan;
    SAVEFREEPV(envp);
    envp[envc] = NULL;

    /* Build envp ("key=value") string array from envhv hash ref. Iterate at
     * most envc times (envhv could be changed in another thread). */
    hv_iterinit(envhv);
    for (n = 0; n < envc; n++) {
      I32 klen;
      char *env_key;
      SV *valsv;
      envp[n] = NULL;
      valsv = hv_iternextsv(envhv, &env_key, &klen);
      if (!valsv) /* envhv shrunk along the way. */
        break;
      else {
        char *env_ent;
        STRLEN env_val_len;
        /* klen < 0 means "utf8". klen == I32_MIN cannot happen because
         * hash keys cannot be longer than I32_MAX, so -klen is safe. */
        const STRLEN env_key_len = (klen < 0) ? -klen : klen;
        const char *env_val = SvPV_const(valsv, env_val_len);

        STRLEN env_ent_len = env_key_len + env_val_len;
        if (UNLIKELY(env_ent_len < env_key_len))
          goto TheZohan;
        env_ent_len += 2; /* +2 for '=' and terminating NUL byte. */
        if (UNLIKELY(env_ent_len < 2))
          goto TheZohan;

        envp[n] = env_ent = (char*)safemalloc(env_ent_len);
        if (!env_ent)
          goto TheZohan;
        SAVEFREEPV(env_ent);
        env_ent[env_key_len] = '=';
        env_ent[env_ent_len-1] = '\0';
        Copy(env_key, env_ent, env_key_len, char);
        Copy(env_val, env_ent+env_key_len+1, env_val_len, char);
      }
    }
  }

  PERL_FLUSHALL_FOR_CHILD;

  /* These ifdefs only serve to silence dumb compilers who don't realize that
   * the returns at the top mean that this code is never reached. */
  if (path) {
# ifdef PSX2008_HAS_EXECVEAT
    execveat(fd, path, (char *const *)argv, (char *const *)envp, flags);
# else
    SETERRNO(ENOSYS, SS$_UNSUPPORTED);
# endif
  }
  else {
# ifdef PSX2008_HAS_FEXECVE
    fexecve(fd, (char *const *)argv, (char *const *)envp);
# else
    SETERRNO(ENOSYS, SS$_UNSUPPORTED);
# endif
  }
  return;

 TheZohan:
  SETERRNO(E2BIG, SS$_BUFFEROVF);
}
#endif

#ifndef PSX2008_HAS_PPOLL
struct psx_ppollspec;
#else
struct psx_ppollspec {
  sigset_t *sigmask;       /* sigmask argument for ppoll(). */
  struct timespec *tmo_p;  /* tmo_p argument for ppoll(). */
};
#endif

#if defined(PSX2008_HAS_POLL) || defined(PSX2008_HAS_PPOLL)
static int
_poll50c(pTHX_ SV *pollfds, int timeout, const struct psx_ppollspec *ppspec)
{
  int rv;
  Size_t i, nfds = 0;
  AV *pollfds_av = NULL;
  /* Assume fds may be NULL if nfds is 0. POSIX is mute about this matter. */
  struct pollfd *fds = NULL;

  if (LIKELY(!!pollfds)) {
    SvGETMAGIC(pollfds);
    if (LIKELY(SvOK(pollfds))) {
      if (!SvIsARRAY(pollfds)) {
        const char *func = ppspec ? "ppoll" : "poll";
        croak("%s::%s: pollfds is not an ARRAY reference: %" SVf_QUOTEDPREFIX,
              PACKNAME, func, SVfARG(pollfds));
      }
      pollfds_av = (AV*)SvRV(pollfds);
      nfds = av_count(pollfds_av);
    }
  }

  /* poll() expects nfds_t, av_count() returns Size_t, av_fetch() expects
   * SSize_t, so we'll accept only the smallest of these. */
  if (UNLIKELY((nfds_t)nfds != nfds || nfds > SSIZE_MAX)) {
    SETERRNO(EINVAL, LIB_INVARG);
    return -1;
  }
  if (UNLIKELY((nfds*sizeof(*fds))/sizeof(*fds) != nfds)) {
    SETERRNO(EINVAL, LIB_INVARG);
    return -1;
  }
  if (LIKELY(nfds)) {
    SV **pollfd;
    fds = (struct pollfd *)safemalloc(nfds*sizeof(*fds));
    if (!fds) {
      SETERRNO(ENOMEM, SS$_INSFMEM);
      return -1;
    }
    SAVEFREEPV(fds);
    for (i = 0; i < nfds; i++) {
      /* No-op defaults for undef and placeholders. */
      const struct pollfd initfd = {.fd=-1, .events=0, .revents=0};
      fds[i] = initfd;
      pollfd = av_fetch(pollfds_av, i, 0);
      if (!pollfd)
        continue;
      SvGETMAGIC(*pollfd);
      if (!SvOK(*pollfd))
        continue;
      if (!SvIsARRAY(*pollfd)) {
        const char *func = ppspec ? "ppoll" : "poll";
        croak("%s::%s: pollfds[%" IVdf
              "] is not an ARRAY reference: %" SVf_QUOTEDPREFIX,
              PACKNAME, func, (IV)i, SVfARG(*pollfd));
      }
      else {
        AV *pollfd_av = (AV*)SvRV(*pollfd);
        SV **pollfd_fd = av_fetch(pollfd_av, 0, 0);
        if (pollfd_fd) {
          fds[i].fd = _psx_fileno(aTHX_ *pollfd_fd);
          if (fds[i].fd >= 0) {
            SV **pollfd_events = av_fetch(pollfd_av, 1, 0);
            if (pollfd_events)
              fds[i].events = (short)(SvIV(*pollfd_events) & PERL_USHORT_MAX);
          }
        }
      }
    }
  }

#ifndef PSX2008_HAS_PPOLL
  rv = poll(fds, nfds, timeout);
#else
  rv = ppspec
    ? ppoll(fds, nfds, ppspec->tmo_p, ppspec->sigmask)
    : poll(fds, nfds, timeout);
#endif

  if (rv > 0) {
    for (i = 0; i < nfds; i++) {
      SV **pollfd = av_fetch(pollfds_av, i, 0);
      /* Paranoid safeguards against threads messing with pollfds_av. */
      if (!pollfd)
        continue;
      SvGETMAGIC(*pollfd);
      if (!SvIsARRAY(*pollfd))
        continue;
      else {
        AV *pollfd_av = (AV*)SvRV(*pollfd);
        /* Prevent sign-extension of revents to IV to avoid phantom flags. */
        SV *revents = newSViv((unsigned short)fds[i].revents);
        if (!av_store(pollfd_av, 2, revents)) {
          if (LIKELY(SvMAGICAL(pollfd_av)))
            mg_set(revents);
          SvREFCNT_dec_NN(revents);
        }
      }
    }
  }

  return rv;
}
#endif

#ifdef PSX2008_HAS_READLINK
static SV *
_readlink50c(pTHX_ const char *path, const int *const dirfdp)
{
  /*
   * CORE::readlink() is broken because it uses a fixed-size result buffer of
   * PATH_MAX bytes (the manpage explicitly advises against this). We use a
   * dynamically growing buffer instead, leaving it up to the file system how
   * long a symlink may be.
   */
  Size_t bufsize;
  SSize_t rv;
  char *buf;
  SV *ret_sv;

  /* If available, we use readlinkat() with AT_FDCWD instead of readlink() to
   * avoid a branch in the loop. */
#ifdef PSX2008_HAS_READLINKAT
  /* Cast AT_FDCWD to int to cope with Solaris 0xffd19553 artwork.
   * https://github.com/python/cpython/issues/60169 */
  const int dirfd = dirfdp ? *dirfdp : (int)AT_FDCWD;
#else
  if (dirfdp) {
    SETERRNO(ENOSYS, SS$_UNSUPPORTED);
    return NULL;
  }
#endif

  buf = NULL;  /* Makes saferealloc() act like safemalloc() the first time. */
  for (bufsize = 255; ; bufsize = (bufsize << 1) | 1) {
    char *new_buf = (char*)saferealloc(buf, bufsize);
    if (!new_buf) {
      SETERRNO(ENOMEM, SS$_INSFMEM);
      goto FuckTheSkullOfGoogle;
    }
    buf = new_buf;

#ifdef PSX2008_HAS_READLINKAT
    rv = readlinkat(dirfd, path, buf, bufsize);
#else
    rv = readlink(path, buf, bufsize);
#endif

    if (rv == -1) {
      /* gnulib says on some systems ERANGE means bufsize is too small. The
       * "LIKELY" massively tightens the loop. No clue why. */
      if (LIKELY(errno != ERANGE))
        goto FuckTheSkullOfGoogle;
    }
    else if ((Size_t)rv < bufsize)
      break;
    if (bufsize+1 == 0)
      goto MicrosoftMustDie;
  }

  buf[(Size_t)rv] = '\0';
#if PERL_BCDVERSION >= 0x5035010
  ret_sv = newSV_type_mortal(SVt_PV);
#else
  ret_sv = sv_2mortal(newSV_type(SVt_PV));
#endif
  /* Put SvPOK_only() first to allow the compiler to merge it with
   * SvTEMP_on() which is the last thing newSV_type_mortal() does. */
  SvPOK_only(ret_sv);
  SvPV_set(ret_sv, buf);
  SvCUR_set(ret_sv, (Size_t)rv);
  SvLEN_set(ret_sv, bufsize);
  SvTAINTED_on(ret_sv);
  return ret_sv;

 MicrosoftMustDie:
  SETERRNO(ENAMETOOLONG, RMS$_SYN);
 FuckTheSkullOfGoogle:
  Safefree(buf);
  return NULL;
}
#endif

#if defined(PSX2008_HAS_READV) || defined(PSX2008_HAS_PREADV)   \
  || defined(PSX2008_HAS_PREADV2)
static void
_free_iov(pTHX_ struct iovec *iov, Size_t cnt) {
  if (iov) {
    Size_t i;
    const struct iovec zero_iovec = {0};
    for (i = 0; i < cnt; i++) {
      Safefree(iov[i].iov_base);
      iov[i] = zero_iovec;
    }
  }
}

/* We only use this function for an undef value. Non-undefs need special
 * treatment (see prepare_SV_for_RV() in sv.h). */
void
_upgrade_undef_sv2av(pTHX_ SV *sv)
{
  ASSUME(!SvOK(sv));

#if PERL_BCDVERSION >= 0x5035004
  sv_setrv_noinc(sv, (SV*)newAV());
#else
  /* Since Perl 5.12 (5.11.0 to be precise), references are SVt_IV (and SVt_RV
   * is just an alias), but before that, SVt_RV was a separate type and
   * DEBUGGING perl whines 'Assertion ((svtype)((sv)->sv_flags & 0xff)) >=
   * SVt_RV failed.' */
# if PERL_BCDVERSION >= 0x5011000
  sv_upgrade(sv, SVt_IV);
# else
  sv_upgrade(sv, SVt_RV);
# endif
  SvOK_off(sv);
  SvRV_set(sv, (SV*)newAV());
  SvROK_on(sv);
#endif
}

static SSize_t
_readv50c(pTHX_ int fd, SV *buffers, AV *sizes, SV *offset_sv, SV *flags_sv)
{
  SSize_t rv;
  Size_t i, iovcnt;
  struct iovec *iov;
  const char *func = flags_sv ? "preadv2" : offset_sv ? "preadv" : "readv";

  /* The prototype for buffers is \[@$] so that we can be called either with
   * @buffers or $buffers. @buffers gives us an array reference. $buffers
   * gives us a reference to a scalar (which in turn is hopefully an array
   * reference). In the latter case we need to resolve the argument twice to
   * get the array. */
  for (i = 0; i < 2; i++) {
    if (SvROK(buffers)) {
      buffers = SvRV(buffers);
      if (SvTRULYREADONLY(buffers))
        croak("%s::%s: Can't modify read-only 'buffers'", PACKNAME, func);
      if (SvTYPE(buffers) == SVt_PVAV)
        break;
      if (i == 0) {
        if (!SvOK(buffers)) /* Make plain "my $buf" an array ref. */
          _upgrade_undef_sv2av(aTHX_ buffers);
        continue;
      }
    }
    croak("%s::%s: 'buffers' is not an array or array ref", PACKNAME, func);
  }

  /* av_count() returns a Size_t but readv()'s iovcnt is an int so we check
   * for overflow. */
  iovcnt = av_count(sizes);
  if (iovcnt > PERL_INT_MAX || (iovcnt*sizeof(*iov))/sizeof(*iov) != iovcnt)
    goto failEINVAL;

  iov = (struct iovec *)safecalloc(iovcnt, sizeof(*iov));
  if (iov)
    SAVEFREEPV(iov);
  else if (iovcnt)
    goto failENOMEM;

  for (i = 0; i < iovcnt; i++) {
    Size_t iov_len;
    void *iov_base;
    SV **size = av_fetch(sizes, i, 0);
    if (!size)
      continue;
    if (UNLIKELY(SvIsNEGATIVE(*size))) { /* Performs 'get' magic. */
      _free_iov(aTHX_ iov, i);
      croak("%s::%s: Negative count: sizes[%" PSX2008_SZuf
            "] = %" SVf_QUOTEDPREFIX,
            PACKNAME, func, (PSX2008_SZuft)i, SVfARG(*size));
    }
    iov_len = SvSTRLEN(*size);
    if (!iov_len)
      continue;
    if (iov_len > SSIZE_MAX) {
      _free_iov(aTHX_ iov, i);
      goto failEINVAL;
    }
    iov_base = safemalloc(TopUpLEN(iov_len));
    if (!iov_base) {
      _free_iov(aTHX_ iov, i);
      goto failENOMEM;
    }
    iov[i].iov_base = iov_base;
    iov[i].iov_len = iov_len;
  }

  if (!offset_sv) {
#ifdef PSX2008_HAS_READV
    rv = readv(fd, iov, iovcnt);
#else
    SETERRNO(ENOSYS, SS$_UNSUPPORTED);
    rv = -1;
#endif
  }
  else if (!flags_sv) {
#ifdef PSX2008_HAS_PREADV
    Off_t offset = SvIsUNDEF_onpurpose(offset_sv) ? 0 : SvOFFt(offset_sv);
    rv = preadv(fd, iov, iovcnt, offset);
#else
    SETERRNO(ENOSYS, SS$_UNSUPPORTED);
    rv = -1;
#endif
  }
  else {
#ifdef PSX2008_HAS_PREADV2
    Off_t offset = SvIsUNDEF_onpurpose(offset_sv) ? 0 : SvOFFt(offset_sv);
    int flags = SvIsUNDEF_onpurpose(flags_sv) ? 0 : (int)SvIV(flags_sv);
    rv = preadv2(fd, iov, iovcnt, offset, flags);
#else
    SETERRNO(ENOSYS, SS$_UNSUPPORTED);
    rv = -1;
#endif
  }

  if (rv < 0) {
    _free_iov(aTHX_ iov, iovcnt);
    return rv;
  }

  av_extend((AV*)buffers, iovcnt);

  {
    SV *tmp_sv;
    Size_t pv_len, bytes_left = rv;
    for (i = 0; i < iovcnt; i++) {
      const Size_t iov_len = iov[i].iov_len;
      if (bytes_left >= iov_len)
        /* Current buffer filled completely (this includes an empty buffer). */
        pv_len = iov_len;
      else
        /* Current buffer filled partly. */
        pv_len = bytes_left;
      bytes_left -= pv_len;

      tmp_sv = newSV_type(SVt_PV);
      if (!tmp_sv) {
        _free_iov(aTHX_ iov + i, iovcnt - i);
        goto failENOMEM;
      }

      if (LIKELY(pv_len)) {
        char *iov_base = (char*)iov[i].iov_base;
        iov_base[pv_len] = '\0';
        SvPV_set(tmp_sv, iov_base);
        SvCUR_set(tmp_sv, pv_len);
        ASSUME(iov_len <= SSIZE_MAX);
        /* We allocated TopUpLEN(iov_len) bytes. */
        SvLEN_set(tmp_sv, TopUpLEN(iov_len));
        SvPOK_only(tmp_sv);
        SvTAINTED_on(tmp_sv);
      }
      else {
#if PERL_BCDVERSION >= 0x5035006
        sv_setpvn_fresh(tmp_sv, "", 0);
#else
        sv_setpvn(tmp_sv, "", 0);
#endif
      }

      if (!av_store((AV*)buffers, i, tmp_sv)) {
        if (LIKELY(SvMAGICAL(buffers)))
          mg_set(tmp_sv);
        SvREFCNT_dec_NN(tmp_sv);
      }
    }
  }

  return rv;

 failEINVAL:
  SETERRNO(EINVAL, LIB_INVARG);
  return -1;
 failENOMEM:
  SETERRNO(ENOMEM, SS$_INSFMEM);
  return -1;
}
#endif

#ifdef PSX2008_HAS_WRITEV
static int
_psx_av2iov(pTHX_ AV *buffers, struct iovec **iov_dest)
{
  Size_t i;
  struct iovec *iov;

  const Size_t iovcnt = av_count(buffers);
  /* av_count() returns a Size_t but writev()'s iovcnt is an int so we check
   * for overflow. */
  if (iovcnt > PERL_INT_MAX || (iovcnt*sizeof(*iov))/sizeof(*iov) != iovcnt) {
    SETERRNO(EINVAL, LIB_INVARG);
    return -1;
  }

  *iov_dest = iov = (struct iovec *)safecalloc(iovcnt, sizeof(*iov));
  if (iov)
    SAVEFREEPV(iov);
  else if (iovcnt) {
    SETERRNO(ENOMEM, SS$_INSFMEM);
    return -1;
  }

  for (i = 0; i < iovcnt; i++) {
    char *iov_base;
    Size_t iov_len;
    SV **av_elt = av_fetch(buffers, i, 0);
    if (!av_elt)
      continue;
    SvGETMAGIC(*av_elt);
    if (!SvIsARRAY(*av_elt))
      iov_base = SvPV(*av_elt, iov_len);
    else {
      SV **buf_pv, **buf_offset, **buf_len;
      AV *buf_av = (AV*)SvRV(*av_elt);
      const SSize_t buf_av_fill = AvFILL(buf_av);

      buf_pv = av_fetch(buf_av, 0, 0);
      if (!buf_pv)
        continue;
      iov_base = SvPV(*buf_pv, iov_len);

      buf_offset = buf_av_fill > 0 ? av_fetch(buf_av, 1, 0) : NULL;
      if (buf_offset) {
        /* Make neg 0 or SIZE_MAX (SvIsNEGATIVE is 0 or 1). */
        const STRLEN neg = ~(STRLEN)SvIsNEGATIVE(*buf_offset) + 1;
        STRLEN offset = SvSTRLEN(*buf_offset);
        offset += neg & iov_len;  /* Handle negative offset w/o a branch. */
        if (offset <= iov_len) {
          iov_len -= offset;
          iov_base += offset;
        }
        else
          croak("Offset %" SVf_QUOTEDPREFIX " outside string in "
                "buffers[%" PSX2008_SZuf "]", SVfARG(*buf_offset),
                (PSX2008_SZuft)i);
      }

      /* av_fetch() always returns non-NULL for magical arrays even if the
       * index is outside the array. That's why we have to check buf_av_fill,
       * or iov_len drops to zero if buf_len is omitted. */
      buf_len = buf_av_fill > 1 ? av_fetch(buf_av, 2, 0) : NULL;
      if (buf_len) {
        if (!SvIsNEGATIVE(*buf_len)) {
          const STRLEN b_len = SvSTRLEN(*buf_len);
          iov_len = (b_len < iov_len) ? b_len : iov_len;
        }
        else
          croak("Negative length %" SVf_QUOTEDPREFIX " in "
                "buffers[%" PSX2008_SZuf "]", SVfARG(*buf_len),
                (PSX2008_SZuft)i);
      }
    }

    iov[i].iov_base = iov_base;
    iov[i].iov_len = iov_len;
  }

  return iovcnt;
}
#endif

#if defined(PSX2008_HAS_OPENAT) || defined(PSX2008_HAS_POSIX_OPENPT)
/* Convert open() flags to POSIX "r", "a", "w" mode string. */
static const char *
_flags2raw(int flags)
{
  int accmode = flags & O_ACCMODE;
  if (accmode == O_RDONLY)
    return "rb";
#ifdef O_APPEND
  if (flags & O_APPEND)
    return (accmode == O_WRONLY) ? "ab" : "a+b";
#endif
  if (accmode == O_WRONLY)
    return "wb";
  if (accmode == O_RDWR)
    return "r+b";
  return "";
}
#endif

#if defined(PSX2008_HAS_FDOPEN) || defined(PSX2008_HAS_FDOPENDIR)
static SV *
_psx_fd_to_handle(pTHX_ int fd, const char *mode)
{
  GV *gv;
  SV *rv = NULL;
  int return_handle = 0;

  gv = newGVgen(PACKNAME);
  if (gv) {
    if (mode) {
# ifdef PSX2008_HAS_FDOPEN
      FILE *filep = fdopen(fd, mode);
      if (filep) {
        /* Should PerlIO_importFILE() fail, we have a nice little memory leak
         * since calling fclose() might irritate the caller. */
        PerlIO *pio = PerlIO_importFILE(filep, mode);
        if (pio) {
          if (do_open(gv, "+<&", 3, FALSE, 0, 0, pio))
            return_handle = 1;
          else
            PerlIO_releaseFILE(pio, filep);
        }
      }
# else
      SETERRNO(ENOSYS, SS$_UNSUPPORTED);
# endif
    }
    else {
# ifdef PSX2008_HAS_FDOPENDIR
      DIR *dirp = fdopendir(fd);
      if (dirp) {
        IO *io = GvIOn(gv);
        IoDIRP(io) = dirp;
        return_handle = 1;
      }
# else
      SETERRNO(ENOSYS, SS$_UNSUPPORTED);
# endif
    }
  }

  if (return_handle) {
    const char *io_class = mode ? "IO::File" : "IO::Dir";
    HV *io_stash = gv_stashpv(io_class, 0);
    rv = sv_bless(sv_2mortal(newRV_inc((SV*)gv)), io_stash);
  }

  /* https://github.com/Perl/perl5/issues/9493 */
  if (gv)
    (void) hv_delete(GvSTASH(gv), GvNAME(gv), GvNAMELEN(gv), G_DISCARD);

  return rv;
}
#endif

#ifdef PSX2008_HAS_CLOSE
static int
_psx_close(pTHX_ SV *sv)
{
  IO *io;
  int rv = -1;

  SvGETMAGIC(sv);
  if (!SvOK(sv))
    SETERRNO(EBADF, RMS_IFI);
  else if (_psx_looks_like_number(aTHX_ sv))
    rv = close((int)SvIV(sv));
  else if ((io = sv_2io(sv))) {
    if (IoIFP(io))
      rv = PerlIO_close(IoIFP(io));
    else if (IoDIRP(io)) {
#ifdef VOID_CLOSEDIR
      SETERRNO(0, 0);
      PerlDir_close(IoDIRP(io));
      rv = errno ? -1 : 0;
#else
      rv = PerlDir_close(IoDIRP(io));
#endif
      IoDIRP(io) = 0;
    }
    else
      SETERRNO(EBADF, RMS_IFI);
  }
  else
    SETERRNO(EBADF, RMS_IFI);

  return rv;
}
#endif

#ifdef PSX2008_HAS_OPENAT
static SV *
_openat50c(pTHX_ SV *dirfdsv,
           const char *path, int flags, mode_t mode, HV *how_hv)
{
  int dir_fd, path_fd, got_fd = 0;

#ifndef PSX2008_HAS_OPENAT2
  if (how_hv) {
    SETERRNO(ENOSYS, SS$_UNSUPPORTED);
    return NULL;
  }
#endif

  SvGETMAGIC(dirfdsv);
  if (!SvOK(dirfdsv))
    dir_fd = -1;
  else if (SvROK(dirfdsv) && SvTYPE(SvRV(dirfdsv)) <= SVt_PVMG) {
    /* Allow dirfdsv to be a reference to a scalar holding AT_FDCWD (IV/NV/PV)
     * to get a file handle instead of a file descriptor. */
    if (SvIV(SvRV(dirfdsv)) == (IV)AT_FDCWD)
      dir_fd = (int)AT_FDCWD;
    else
      dir_fd = -1;
  }
  else {
    got_fd = _psx_looks_like_number(aTHX_ dirfdsv);
    dir_fd = _psx_fileno_nomg(aTHX_ dirfdsv);
  }

  if (dir_fd == -1) {
    SETERRNO(EBADF, RMS_IFI);
    path_fd = -1;
  }
  else if (!how_hv) {  /* openat() */
    path_fd = openat(dir_fd, path, flags, mode);
  }
#ifdef PSX2008_HAS_OPENAT2
  /* openat2() */
  else {
    SV** how_flags = hv_fetchs(how_hv, "flags", 0);
    SV** how_mode = hv_fetchs(how_hv, "mode", 0);
    SV** how_resolve = hv_fetchs(how_hv, "resolve", 0);
    struct open_how how = {
      .flags   = how_flags ? SvUV(*how_flags) : 0,
      .mode    = how_mode ? SvUV(*how_mode) : 0,
      .resolve = how_resolve ? SvUV(*how_resolve) : 0
    };
    flags = (int)how.flags; /* flags needed for _psx_fd_to_handle() below. */
    path_fd = syscall(SYS_openat2, dir_fd, path, &how, sizeof(how));
  }
#endif

  if (path_fd < 0)
    return NULL;
  else if (got_fd)
    /* If we were passed a file descriptor, return a file descriptor. */
    return sv_2mortal(newSViv((IV)path_fd));
  else {
    struct stat st;
    if (fstat(path_fd, &st) != 0)
      return NULL;
    else {
      const char *raw = S_ISDIR(st.st_mode) ? NULL : _flags2raw(flags);
      return _psx_fd_to_handle(aTHX_ path_fd, raw);
    }
  }
}

#endif

/* Macro for isalnum, isdigit, etc.
 * Contains the fix for https://github.com/Perl/perl5/issues/11148 which was
 * "solved" by them Perl guys by cowardly removing the functions from POSIX.
 */
#define ISFUNC(isfunc) {                                                   \
    STRLEN len;                                                            \
    const unsigned char *s = (unsigned char *) SvPVbyte(charstring, len);  \
    const unsigned char *e = s + len;                                      \
    for (RETVAL = len ? 1 : 0; RETVAL && s < e; s++)                       \
      if (!isfunc(*s))                                                     \
        RETVAL = 0;                                                        \
  }

MODULE = POSIX::2008    PACKAGE = POSIX::2008

PROTOTYPES: ENABLE

INCLUDE: const-xs.inc

#ifdef PSX2008_HAS_ABORT
void
abort();
  PPCODE:
    /* Using PPCODE instead of an empty body avoids the (unnecessary)
     * XSRETURN_EMPTY epilog and saves quite a few bytes. */
    abort();

#endif

#ifdef PSX2008_HAS_SYNC
void
sync();
  PPCODE:
    sync();

#endif

#ifdef PSX2008_HAS_A64L
long
a64l(char *s);

#endif

#ifdef PSX2008_HAS_L64A
char *
l64a(long value);

#endif

#ifdef PSX2008_HAS_ALARM
UV
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
SysRetTrue
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
clock_getcpuclockid(pid_t pid=0);
  INIT:
    int rv;
    clockid_t clock_id;
  PPCODE:
    rv = clock_getcpuclockid(pid, &clock_id);
    if (LIKELY(rv == 0))
      PUSH_INT_OR_PV(clock_id);
    else {
      SETERRNO(rv, rv);
      PUSHs(&PL_sv_undef);
    }

#endif

#define PUSH_TIMESPEC(_tspec) STMT_START {                              \
    switch (GIMME_V) {                                                  \
      case G_SCALAR:                                                    \
        mPUSHs(newSVnv(_tspec.tv_sec + _tspec.tv_nsec/(NV)1e9));        \
        break;                                                          \
      case G_LIST:                                                      \
        EXTEND(SP, 2);                                                  \
        mPUSHs(newSViv(_tspec.tv_sec));                                 \
        mPUSHs(newSViv(_tspec.tv_nsec));                                \
    }                                                                   \
} STMT_END

#ifdef PSX2008_HAS_CLOCK_GETRES
void
clock_getres(clockid_t clock_id=CLOCK_REALTIME);
  ALIAS:
    clock_gettime = 1
  INIT:
    int rv;
    struct timespec res;
  PPCODE:
  {
    rv = (ix == 0)
      ? clock_getres(clock_id, &res)
      : clock_gettime(clock_id, &res);
    if (rv == 0)
      PUSH_TIMESPEC(res);
  }

#endif

#define LOOKS_LIKE_NV(_sv)                                                     \
(                                                                              \
  !SvIOK(_sv) &&                                                               \
  (                                                                            \
    SvNOK(_sv) ||                                                              \
    (                                                                          \
      (SvPOK(_sv) || SvPOKp(_sv))                                              \
      && (grok_number(SvPVX_const(_sv), SvCUR(_sv), NULL) & IS_NUMBER_NOT_INT) \
    )                                                                          \
  )                                                                            \
)

#define TIMESPEC_FROM_IV_nomg(_tspec, sec_sv, nsec_long) STMT_START {   \
    _tspec.tv_sec = (time_t)SvIV_nomg(sec_sv);                          \
    _tspec.tv_nsec = nsec_long;                                         \
} STMT_END

#define TIMESPEC_FROM_NV_nomg(_tspec, sec_sv) STMT_START {      \
    const NV sec_nv = SvNV_nomg(sec_sv);                        \
    _tspec.tv_sec = (time_t)sec_nv;                             \
    _tspec.tv_nsec = (sec_nv - _tspec.tv_sec)*1e9;              \
} STMT_END

#ifdef PSX2008_HAS_CLOCK_NANOSLEEP
void
clock_nanosleep(clockid_t clock_id, int flags, SV *sec, long nsec=0);
  PROTOTYPE: $$@
  INIT:
    int rv;
    struct timespec request;
    struct timespec remain = {0};
  PPCODE:
  {
    SvGETMAGIC(sec);
    if (items == 3 && LOOKS_LIKE_NV(sec))
      TIMESPEC_FROM_NV_nomg(request, sec);
    else
      TIMESPEC_FROM_IV_nomg(request, sec, nsec);
    rv = clock_nanosleep(clock_id, flags, &request, &remain);
    if (rv == 0 || (errno = rv) == EINTR)
      PUSH_TIMESPEC(remain);
  }

#endif

#ifdef PSX2008_HAS_CLOCK_SETTIME
void
clock_settime(clockid_t clock_id, SV *sec, long nsec=0);
  PROTOTYPE: $@
  INIT:
    struct timespec tp;
  PPCODE:
  {
    SvGETMAGIC(sec);
    if (items == 2 && LOOKS_LIKE_NV(sec))
      TIMESPEC_FROM_NV_nomg(tp, sec);
    else
      TIMESPEC_FROM_IV_nomg(tp, sec, nsec);
    if (clock_settime(clock_id, &tp) == 0)
      mPUSHp("0 but true", 10);
    else
      PUSHs(&PL_sv_undef);
  }

#endif

#ifdef PSX2008_HAS_NANOSLEEP
void
nanosleep(SV *sec, long nsec=0);
  PROTOTYPE: @
  INIT:
    struct timespec request;
    struct timespec remain = {0};
  PPCODE:
  {
    SvGETMAGIC(sec);
    if (items == 1 && LOOKS_LIKE_NV(sec))
      TIMESPEC_FROM_NV_nomg(request, sec);
    else
      TIMESPEC_FROM_IV_nomg(request, sec, nsec);
    if (nanosleep(&request, &remain) == 0 || errno == EINTR)
      PUSH_TIMESPEC(remain);
  }

#endif

#ifdef PSX2008_HAS_DIRNAME
char *
dirname(char *path);

#endif

#ifdef PSX2008_HAS_DLCLOSE
SysRetTrue
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
    if (LIKELY(rv == 0 || rv == FNM_NOMATCH))
      mPUSHs(newSViv(rv));
    else
      PUSHs(&PL_sv_undef);

#endif

#ifdef PSX2008_HAS_KILLPG
SysRetTrue
killpg(pid_t pgrp, int sig);

#endif

#ifdef PSX2008_HAS_RAISE
SysRetTrue
raise(int sig);

#endif

#ifdef PSX2008_HAS_GETDATE
void
getdate(const char *string);
    INIT:
        struct tm *tm = getdate(string);
    PPCODE:
        if (tm) {
            EXTEND(SP, 9);
            mPUSHs(newSViv(tm->tm_sec));
            mPUSHs(newSViv(tm->tm_min));
            mPUSHs(newSViv(tm->tm_hour));
            mPUSHs(newSViv(tm->tm_mday));
            mPUSHs(newSViv(tm->tm_mon));
            mPUSHs(newSViv(tm->tm_year));
            mPUSHs(newSViv(tm->tm_wday));
            mPUSHs(newSViv(tm->tm_yday));
            mPUSHs(newSViv(tm->tm_isdst));
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
#define TM_COUNT_MAX 11
void
strptime(const char *s, const char *format, ...);
  PROTOTYPE: $$@
  INIT:
    struct tm tm;
    char *remainder;
    Size_t i, tm_count;
    AV *tm_av = NULL;
    U8 gimme;
  PPCODE:
  {
    if (items > 2) {
      if (items > TM_COUNT_MAX + 2) {
      DumpDarkSuckerjerk:
        croak("%s::strptime: Too many arguments", PACKNAME);
      }
      SV *tm_arg = ST(2l);
      SvGETMAGIC(tm_arg);
      if (SvIsARRAY(tm_arg)) {
        if (items == 3)
          tm_av = (AV*)SvRV(tm_arg);
        else
         goto DumpDarkSuckerjerk;
      }
    }

    tm_count = tm_av ? av_count(tm_av) : (Size_t)items - 2;
    tm_count = (tm_count > TM_COUNT_MAX) ? TM_COUNT_MAX : tm_count;

    /* Gather initial values in an int array to populate tm. For lack of
     * something better we use INT_MIN to denote undef values. */
    {
      int tm_ary[] = {
        PERL_INT_MIN, PERL_INT_MIN, PERL_INT_MIN,
        PERL_INT_MIN, PERL_INT_MIN, PERL_INT_MIN,
        PERL_INT_MIN, PERL_INT_MIN, PERL_INT_MIN,
      };
#ifdef HAS_TM_TM_GMTOFF
      tm.tm_gmtoff = PERL_INT_MIN;
#endif
#ifdef HAS_TM_TM_ZONE
      tm.tm_zone   = NULL;
#endif
      for (i = 0; i < tm_count; i++) {
        SV *tm_sv;
        if (!tm_av)
          tm_sv = ST(i+2);
        else {
          SV **av_elt = av_fetch(tm_av, i, 0);
          if (!av_elt)
            continue;
          tm_sv = *av_elt;
        }
        SvGETMAGIC(tm_sv);
        if (!SvOK(tm_sv))
          continue;
        if (i < 9)
          tm_ary[i] = (int)SvIV(tm_sv);
#ifdef HAS_TM_TM_GMTOFF
        else if (i == 9)
          tm.tm_gmtoff = (long)SvIV(tm_sv);
#endif
#ifdef HAS_TM_TM_ZONE
        else if (i == 10)
          tm.tm_zone = SvPV_nolen(tm_sv);
#endif
      }
      tm.tm_sec  = tm_ary[0]; tm.tm_min  = tm_ary[1]; tm.tm_hour  = tm_ary[2];
      tm.tm_mday = tm_ary[3]; tm.tm_mon  = tm_ary[4]; tm.tm_year  = tm_ary[5];
      tm.tm_wday = tm_ary[6]; tm.tm_yday = tm_ary[7]; tm.tm_isdst = tm_ary[8];
    }

    gimme = GIMME_V;
    remainder = strptime(s, format, &tm);

    if (!remainder) {
      if (gimme != G_LIST)
        PUSHs(&PL_sv_undef);
    }
    else {
      /* Create SV array from struct tm turned into an int array. */
#ifdef HAS_TM_TM_GMTOFF
#define TM_ARY_TYPE long
#define TM_GMTOFF_VAL tm.tm_gmtoff
#else
#define TM_ARY_TYPE int
#define TM_GMTOFF_VAL PERL_INT_MIN
#endif
      const TM_ARY_TYPE tm_ary[TM_COUNT_MAX] = {
        tm.tm_sec, tm.tm_min, tm.tm_hour,
        tm.tm_mday, tm.tm_mon, tm.tm_year,
        tm.tm_wday, tm.tm_yday, tm.tm_isdst,
        TM_GMTOFF_VAL,
        PERL_INT_MIN, /* tm_zone dummy so all sv_ary SVs default to undef. */
      };
      SV *sv_ary[TM_COUNT_MAX];
      if (LIKELY(tm_av || gimme == G_LIST)) {
#pragma GCC unroll 0  /* https://github.com/llvm/llvm-project/issues/42332 */
        for (i = 0; i < TM_COUNT_MAX; i++) {
          sv_ary[i] = sv_newmortal();
          if (tm_ary[i] != PERL_INT_MIN)
            sv_setiv(sv_ary[i], (IV)tm_ary[i]);
        }
#ifdef HAS_TM_TM_ZONE
        if (LIKELY(!!tm.tm_zone))
          sv_setpv(sv_ary[10], tm.tm_zone);
#endif
      }
      /* Populate tm_av argument and/or return values from sv_ary. */
      if (tm_av) {
        av_extend(tm_av, TM_COUNT_MAX - 1);
        for (i = 0; i < TM_COUNT_MAX; i++) {
          SV *tm_sv = sv_ary[i];
          /* Increase refcount since we mortalized all SVs. */
          SvREFCNT_inc_simple_void_NN(tm_sv);
          if (!av_store((AV*)tm_av, i, tm_sv)) {
            if (LIKELY(SvMAGICAL(tm_av)))
              mg_set(tm_sv);
            SvREFCNT_dec_NN(tm_sv);
          }
        }
      }
      if (gimme == G_LIST) {
        EXTEND(SP, TM_COUNT_MAX);
        for (i = 0; i < TM_COUNT_MAX; i++)
          PUSHs(sv_ary[i]);
      }
      else
        mPUSHs(newSVuv(remainder - s));
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
#if defined(HOST_NAME_MAX) && HOST_NAME_MAX > 256
    char name[HOST_NAME_MAX];
#elif defined(MAXHOSTNAMELEN) && MAXHOSTNAMELEN > 256
    char name[MAXHOSTNAMELEN];
#else
    char name[256];
#endif
  PPCODE:
    if (LIKELY(gethostname(name, sizeof(name)) == 0))
      mPUSHp(name, _strnlen(name, sizeof(name)));
    else
      PUSHs(&PL_sv_undef);

#endif

#ifdef PSX2008_HAS_GETITIMER
void
getitimer(int which);
    INIT:
        struct itimerval value;
    PPCODE:
        if (getitimer(which, &value) == 0) {
            EXTEND(SP, 2); /* Stack already has room for 2 items. */
            mPUSHs(newSViv(value.it_interval.tv_sec));
            mPUSHs(newSViv(value.it_interval.tv_usec));
            mPUSHs(newSViv(value.it_value.tv_sec));
            mPUSHs(newSViv(value.it_value.tv_usec));
        }

#endif

#ifdef PSX2008_HAS_SETITIMER
void
setitimer(int which,                      \
          time_t int_sec, long int_usec,  \
          time_t val_sec, long val_usec);
    PROTOTYPE: $@
    INIT:
        struct itimerval value = { {int_sec, int_usec}, {val_sec, val_usec} };
        struct itimerval ovalue;
    PPCODE:
        if (setitimer(which, &value, &ovalue) == 0) {
            /* We already know the stack is long enough. */
            mPUSHs(newSViv(ovalue.it_interval.tv_sec));
            mPUSHs(newSViv(ovalue.it_interval.tv_usec));
            mPUSHs(newSViv(ovalue.it_value.tv_sec));
            mPUSHs(newSViv(ovalue.it_value.tv_usec));
        }

#endif

#ifdef PSX2008_HAS_NICE
void
nice(int incr);
  INIT:
    SETERRNO(0, 0);
  PPCODE:
  {
    int rv = nice(incr);
    if (rv != -1 || errno == 0)
      mPUSHs(newSViv(rv));
    else
      PUSHs(&PL_sv_undef);
  }

#endif

#ifdef PSX2008_HAS_GETPRIORITY
void
getpriority(int which=PRIO_PROCESS, id_t who=0);
  INIT:
    SETERRNO(0, 0);
  PPCODE:
  {
    int rv = getpriority(which, who);
    if (rv != -1 || errno == 0)
      mPUSHs(newSViv(rv));
    else
      PUSHs(&PL_sv_undef);
  }

#endif

#ifdef PSX2008_HAS_SETPRIORITY
SysRetTrue
setpriority(int prio, int which=PRIO_PROCESS, id_t who=0);

#endif

#define RETURN_UTXENT {                                                 \
    if (utxent) {                                                       \
      EXTEND(SP, 7);                                                    \
      mPUSHp(utxent->ut_user, _strnlen(utxent->ut_user, sizeof(utxent->ut_user))); \
      mPUSHp(utxent->ut_id,   _strnlen(utxent->ut_id,   sizeof(utxent->ut_id  ))); \
      mPUSHp(utxent->ut_line, _strnlen(utxent->ut_line, sizeof(utxent->ut_line))); \
      mPUSHs(newSViv(utxent->ut_pid));                                           \
      mPUSHs(newSViv(utxent->ut_type));                                          \
      mPUSHs(newSViv(utxent->ut_tv.tv_sec));                                     \
      mPUSHs(newSViv(utxent->ut_tv.tv_usec));                                    \
    }                                                                   \
}

#ifdef PSX2008_HAS_ENDUTXENT
void
endutxent();
  PPCODE:
    endutxent();

#endif

#ifdef PSX2008_HAS_GETUTXENT
void
getutxent();
  PPCODE:
  {
    struct utmpx *utxent = getutxent();
    RETURN_UTXENT;
  }

#endif

#ifdef PSX2008_HAS_GETUTXID
void
getutxid(short ut_type, SV *ut_id=NULL);
  INIT:
    struct utmpx *utxent;
    struct utmpx utxent_req = {.ut_type=ut_type};
    const Size_t ut_id_size = sizeof(utxent_req.ut_id);
  PPCODE:
  {
    if (ut_id) {
      STRLEN pvlen;
      const char *pv = SvPV_const(ut_id, pvlen);
      const STRLEN ut_id_len = ut_id_size < pvlen ? ut_id_size : pvlen;
      Copy(pv, utxent_req.ut_id, ut_id_len, char);
    }
    utxent = getutxid(&utxent_req);
    RETURN_UTXENT;
  }

#endif

#ifdef PSX2008_HAS_GETUTXLINE
void
getutxline(SV *ut_line);
  INIT:
    struct utmpx *utxent;
    struct utmpx utxent_req = {0};
    const Size_t ut_line_size = sizeof(utxent_req.ut_line);
  PPCODE:
  {
    STRLEN pvlen;
    const char *pv = SvPV_const(ut_line, pvlen);
    const STRLEN ut_line_len = ut_line_size < pvlen ? ut_line_size : pvlen;
    Copy(pv, utxent_req.ut_line, ut_line_len, char);
    utxent = getutxline(&utxent_req);
    RETURN_UTXENT;
  }

#endif

#ifdef PSX2008_HAS_SETUTXENT
void
setutxent();
  PPCODE:
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
        /* We already know the stack is long enough. */
        mPUSHs(newSVnv((NV)result));
        mPUSHs(newSVuv(xsubi[0]));
        mPUSHs(newSVuv(xsubi[1]));
        mPUSHs(newSVuv(xsubi[2]));

#endif

#ifdef PSX2008_HAS_JRAND48
void
jrand48(unsigned short X0, unsigned short X1, unsigned short X2);
    ALIAS:
        nrand48 = 1
    INIT:
        unsigned short xsubi[3] = { X0, X1, X2 };
        long result = (ix == 0) ? jrand48(xsubi) : nrand48(xsubi);
    PPCODE:
        /* We already know the stack is long enough. */
        mPUSHs(newSViv((IV)result));
        mPUSHs(newSVuv(xsubi[0]));
        mPUSHs(newSVuv(xsubi[1]));
        mPUSHs(newSVuv(xsubi[2]));

#endif

#ifdef PSX2008_HAS_LRAND48
long
lrand48();

#endif

#ifdef PSX2008_HAS_MRAND48
long
mrand48();

#endif

#ifdef PSX2008_HAS_SEED48
void
seed48(unsigned short seed1, unsigned short seed2, unsigned short seed3);
    INIT:
        unsigned short seed16v[3] = { seed1, seed2, seed3 };
        unsigned short *old = seed48(seed16v);
    PPCODE:
        /* We already know the stack is long enough. */
        mPUSHs(newSVuv(old[0]));
        mPUSHs(newSVuv(old[1]));
        mPUSHs(newSVuv(old[2]));

#endif

#ifdef PSX2008_HAS_SRAND48
void
srand48(long seedval);
  PPCODE:
    srand48(seedval);

#endif

#ifdef PSX2008_HAS_RANDOM
long
random();

#endif

#ifdef PSX2008_HAS_SRANDOM
void
srandom(unsigned seed);
  PPCODE:
    srandom(seed);

#endif


#if defined(PSX2008_HAS_GETENTROPY)
# define _psx_getentropy(buf, len) getentropy(buf, len)
#elif defined(PSX2008_HAS_GETRANDOM)
# define _psx_getrandom(buf, len) getrandom(buf, len, 0)
#elif defined(PSX2008_HAS_GETRANDOM_SYS)
# define _psx_getrandom(buf, len) syscall(SYS_getrandom, buf, len, 0)
#elif defined(PSX2008_HAS_ARC4RANDOM_BUF)
# define _psx_getentropy(buf, len) (arc4random_buf(buf, len), 0)
#elif defined(PSX2008_HAS_BCRYPTGENRANDOM)
# define _psx_getentropy(buf, len) \
  (BCryptGenRandom(NULL, buf, len, BCRYPT_USE_SYSTEM_PREFERRED_RNG) ? -1 : 0)
#elif defined(_psx_cpu_rand_step_ok)
# define _psx_getentropy(buf, len) (ASSUME(!!buf), _cpu_rand50c(buf, len), 0)
#endif

#if defined(_psx_getentropy) || defined(_psx_getrandom)
# ifdef _psx_cpu_rand_step_ok
#  define _PSX_CPURAND_SIZE sizeof(_psx_cpu_rand_t)
#  define _PSX_GETENTROPY_SVLEN_ROUNDUP(l) \
   ((l) + (_PSX_CPURAND_SIZE - ((l) % _PSX_CPURAND_SIZE)) % _PSX_CPURAND_SIZE)
# else
#  define _PSX_GETENTROPY_SVLEN_ROUNDUP(l) (l)
# endif
void
getentropy(IV length);
  PPCODE:
  {
    if (UNLIKELY(length < 0 || length > GETENTROPY_MAX)) {
      SETERRNO(EINVAL, LIB_INVARG);  /* Thus quoth POSIX. */
    MakeUndefGreatAgain:
      PUSHs(&PL_sv_undef);
    }
    else {
      STRLEN sv_len = _PSX_GETENTROPY_SVLEN_ROUNDUP(length);
      SV *bufsv = sv_2mortal(newSV(sv_len + !sv_len));
      char *cbuf = SvPVX(bufsv);
# if defined(_psx_getentropy)
      int rv = _psx_getentropy(cbuf, sv_len);
      cbuf[length] = '\0';
# else
      SSize_t rv = 0;
      Size_t grlen = length;
      while (grlen) {
        while ((rv = _psx_getrandom(cbuf, grlen)) < 0)
          if (errno != EINTR)
            goto MakeUndefGreatAgain;
        if (rv == 0 || rv > grlen) {
          SETERRNO(EIO, SS$_ABORT);
          goto MakeUndefGreatAgain;
        }
        cbuf += rv;
        grlen -= rv;
      }
      *cbuf = '\0';
# endif
      if (rv < 0)
        goto MakeUndefGreatAgain;
      else {
        SvCUR_set(bufsv, length);
        SvPOK_only(bufsv);
        SvTAINTED_on(bufsv);
        PUSHs(bufsv);
      }
    }
  }

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

#ifdef PSX2008_HAS_GETSID
pid_t
getsid(pid_t pid=0);

#endif

#ifdef PSX2008_HAS_GETRESGID
void
getresgid();
  PPCODE:
  {
    gid_t rid, eid, sid;
    int rv = getresgid(&rid, &eid, &sid);
    if (LIKELY(rv == 0)) {
      EXTEND(SP, 2); /* Stack already has room for 1 item. */
      mPUSHs(newSVuv(rid));
      mPUSHs(newSVuv(eid));
      mPUSHs(newSVuv(sid));
    }
  }

#endif

#ifdef PSX2008_HAS_GETRESUID
void
getresuid();
  PPCODE:
  {
    uid_t rid, eid, sid;
    int rv = getresuid(&rid, &eid, &sid);
    if (LIKELY(rv == 0)) {
      EXTEND(SP, 2); /* Stack already has room for 1 item. */
      mPUSHs(newSVuv(rid));
      mPUSHs(newSVuv(eid));
      mPUSHs(newSVuv(sid));
    }
  }

#endif

#ifdef PSX2008_HAS_SETEGID
SysRetTrue
setegid(gid_t gid);

#endif

#ifdef PSX2008_HAS_SETEUID
SysRetTrue
seteuid(uid_t uid);

#endif

#ifdef PSX2008_HAS_SETGID
SysRetTrue
setgid(gid_t gid);

#endif

#ifdef PSX2008_HAS_SETREGID
SysRetTrue
setregid(gid_t rgid, gid_t egid);

#endif

#ifdef PSX2008_HAS_SETRESGID
SysRetTrue
setresgid(gid_t rgid, gid_t egid, gid_t sgid);

#endif

#ifdef PSX2008_HAS_SETREUID
SysRetTrue
setreuid(uid_t ruid, uid_t euid);

#endif

#ifdef PSX2008_HAS_SETRESUID
SysRetTrue
setresuid(uid_t ruid, uid_t euid, uid_t suid);

#endif

#ifdef PSX2008_HAS_SETSID
pid_t
setsid();

#endif

#ifdef PSX2008_HAS_SETUID
SysRetTrue
setuid(uid_t uid);

#endif

#ifdef PSX2008_HAS_SIGHOLD
SysRetTrue
sighold(int sig);

#endif

#ifdef PSX2008_HAS_SIGIGNORE
SysRetTrue
sigignore(int sig);

#endif

#ifdef PSX2008_HAS_SIGPAUSE
void
sigpause(int sig);
  PPCODE:
    (void)sigpause(sig);
    PUSHs(&PL_sv_undef);

#endif

#ifdef PSX2008_HAS_SIGRELSE
SysRetTrue
sigrelse(int sig);

#endif

#ifdef PSX2008_HAS_PAUSE
void
pause();
  PPCODE:
    (void)pause();
    PUSHs(&PL_sv_undef);

#endif

#ifdef PSX2008_HAS_PSIGNAL
void
psignal(int sig, const char *msg);
  PPCODE:
    psignal(sig, msg);

#endif

#ifdef PSX2008_HAS_STRSIGNAL
char*
strsignal(int sig);

#endif

#ifdef PSX2008_HAS_TIMER_CREATE
timer_t
timer_create(clockid_t clockid, SV *sig = NULL);
  PREINIT:
    struct sigevent sevp = {0};
    timer_t timerid;
    int rv;
  CODE:
  {
    if (sig) {
      if (SIGEV_SIGNAL)
        sevp.sigev_notify = SIGEV_SIGNAL;
      SvGETMAGIC(sig);
      sevp.sigev_signo = SvIV(sig);
    }
    else if (SIGEV_NONE) {
      sevp.sigev_notify = SIGEV_NONE;
    }
    rv = timer_create(clockid, &sevp, &timerid);
    RETVAL = (rv == 0) ? timerid : (timer_t)0;
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
      EXTEND(SP, 2);
      mPUSHs(newSViv(curr_value.it_interval.tv_sec));
      mPUSHs(newSViv(curr_value.it_interval.tv_nsec));
      mPUSHs(newSViv(curr_value.it_value.tv_sec));
      mPUSHs(newSViv(curr_value.it_value.tv_nsec));
    }
  }

#endif

#ifdef PSX2008_HAS_TIMER_SETTIME
void
timer_settime(timer_t timerid, int flags,                               \
              time_t interval_sec, long interval_nsec,                  \
              time_t initial_sec=-1, long initial_nsec=-1);
  PROTOTYPE: $$@
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
      mPUSHs(newSViv(old_value.it_interval.tv_sec));
      mPUSHs(newSViv(old_value.it_interval.tv_nsec));
      mPUSHs(newSViv(old_value.it_value.tv_sec));
      mPUSHs(newSViv(old_value.it_value.tv_nsec));
    }
  }

#endif

 ## I/O-related functions
 ########################

#ifdef PSX2008_HAS_CHDIR
SysRetTrue
chdir(SV *what);
  CODE:
    SvGETMAGIC(what);
    if (!SvOK(what)) {
      SETERRNO(ENOENT, RMS$_DNF);
      RETVAL = -1;
    }
    else if (SvPOK(what)) {
      const char *path = SvPV_nomg_const_nolen(what);
      RETVAL = chdir(path);
    }
    else {
#ifdef PSX2008_HAS_FCHDIR
      int fd = _psx_fileno_nomg(aTHX_ what);
      RETVAL = fchdir(fd);
#else
      SETERRNO(ENOSYS, SS$_UNSUPPORTED);
      RETVAL = -1;
#endif
    }
  OUTPUT:
    RETVAL

#endif

#ifdef PSX2008_HAS_CHMOD
SysRetTrue
chmod(SV *what, mode_t mode);
  CODE:
    SvGETMAGIC(what);
    if (!SvOK(what)) {
      SETERRNO(ENOENT, RMS$_FNF);
      RETVAL = -1;
    }
    else if (SvPOK(what)) {
      const char *path = SvPV_nomg_const_nolen(what);
      RETVAL = chmod(path, mode);
    }
    else {
#ifdef PSX2008_HAS_FCHMOD
      int fd = _psx_fileno_nomg(aTHX_ what);
      RETVAL = fchmod(fd, mode);
#else
      SETERRNO(ENOSYS, SS$_UNSUPPORTED);
      RETVAL = -1;
#endif
    }
  OUTPUT:
    RETVAL

#endif

#ifdef PSX2008_HAS_CHOWN
SysRetTrue
chown(SV *what, uid_t owner, gid_t group);
  CODE:
    SvGETMAGIC(what);
    if (!SvOK(what)) {
      SETERRNO(ENOENT, RMS$_FNF);
      RETVAL = -1;
    }
    else if (SvPOK(what)) {
      const char *path = SvPV_nomg_const_nolen(what);
      RETVAL = chown(path, owner, group);
    }
    else {
#ifdef PSX2008_HAS_FCHOWN
      int fd = _psx_fileno_nomg(aTHX_ what);
      RETVAL = fchown(fd, owner, group);
#else
      SETERRNO(ENOSYS, SS$_UNSUPPORTED);
      RETVAL = -1;
#endif
    }
  OUTPUT:
    RETVAL

#endif

#ifdef PSX2008_HAS_CONFSTR
void
confstr(int name);
  INIT:
    SETERRNO(0, 0);
  PPCODE:
  {
    Size_t len = confstr(name, NULL, 0);
    if (!len && errno)
      PUSHs(&PL_sv_undef);
    else {
      SV *bufsv = sv_2mortal(newSV(len + !len));
      char *cbuf = SvPVX(bufsv);

      (void)confstr(name, cbuf, len);
      cbuf[len] = '\0';

      SvCUR_set(bufsv, len - !!len);
      SvPOK_only(bufsv);
      SvTAINTED_on(bufsv);
      PUSHs(bufsv);
    }
  }

#endif

#ifdef PSX2008_HAS_PATHCONF
void
pathconf(SV *what, int name);
  PPCODE:
  {
    long rv = -1;
    SvGETMAGIC(what);
    SETERRNO(0, 0); /* SvGETMAGIC() might have set errno. */
    if (UNLIKELY(!SvOK(what)))
      SETERRNO(ENOENT, RMS_FNF);
    else if (SvPOK(what)) {
      const char *path = SvPV_nomg_const_nolen(what);
      rv = pathconf(path, name);
    }
    else {
#ifdef PSX2008_HAS_FPATHCONF
      int fd = _psx_fileno_nomg(aTHX_ what);
      SETERRNO(0, 0); /* _psx_fileno() might have set errno. */
      rv = fpathconf(fd, name);
#else
      SETERRNO(ENOSYS, SS$_UNSUPPORTED);
#endif
    }
    if (rv < 0 && errno != 0)
      PUSHs(&PL_sv_undef);
    else
      PUSH_INT_OR_PV(rv);
  }

#endif

#ifdef PSX2008_HAS_SYSCONF
void
sysconf(int name);
  PPCODE:
  {
    long rv;
    SETERRNO(0, 0);
    rv = sysconf(name);
    if (rv < 0 && errno != 0)
      PUSHs(&PL_sv_undef);
    else
      PUSH_INT_OR_PV(rv);
  }

#endif

#ifdef PSX2008_HAS_TRUNCATE
SysRetTrue
truncate(SV *what, Off_t length);
  CODE:
    SvGETMAGIC(what);
    if (!SvOK(what)) {
      SETERRNO(ENOENT, RMS_FNF);
      RETVAL = -1;
    }
    else if (SvPOK(what)) {
      const char *path = SvPV_nomg_const_nolen(what);
      RETVAL = truncate(path, length);
    }
    else {
#ifdef PSX2008_HAS_FTRUNCATE
      int fd = _psx_fileno_nomg(aTHX_ what);
      RETVAL = ftruncate(fd, length);
#else
      SETERRNO(ENOSYS, SS$_UNSUPPORTED);
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
    SvGETMAGIC(what);
    if (!SvOK(what))
      SETERRNO(ENOENT, RMS_FNF);
    else if (SvPOK(what)) {
      const char *path = SvPV_nomg_const_nolen(what);
      rv = stat(path, &buf);
    }
    else {
#ifdef PSX2008_HAS_FSTAT
      int fd = _psx_fileno_nomg(aTHX_ what);
      rv = fstat(fd, &buf);
#else
      SETERRNO(ENOSYS, SS$_UNSUPPORTED);
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

#ifdef PSX2008_HAS_STATVFS
void
statvfs(SV *what);
  INIT:
    int rv = -1;
    struct statvfs buf;
  PPCODE:
    SvGETMAGIC(what);
    if (!SvOK(what))
      SETERRNO(ENOENT, RMS_FNF);
    else if (SvPOK(what)) {
      const char *path = SvPV_nomg_const_nolen(what);
      rv = statvfs(path, &buf);
    }
    else {
#ifdef PSX2008_HAS_FSTATVFS
      int fd = _psx_fileno_nomg(aTHX_ what);
      rv = fstatvfs(fd, &buf);
#else
      SETERRNO(ENOSYS, SS$_UNSUPPORTED);
#endif
    }
    RETURN_STATVFS_BUF(rv, buf);

#endif

#ifdef PSX2008_HAS_ISATTY
int
isatty(psx_fd_t fd);

#endif

#ifdef PSX2008_HAS_ISALNUM
int
isalnum(SV *charstring);
  CODE:
    ISFUNC(isalnum)
  OUTPUT:
    RETVAL

#endif

#ifdef PSX2008_HAS_ISALPHA
int
isalpha(SV *charstring);
  CODE:
    ISFUNC(isalpha)
  OUTPUT:
    RETVAL

#endif

#ifdef PSX2008_HAS_ISASCII
int
isascii(SV *charstring);
  CODE:
    ISFUNC(isascii)
  OUTPUT:
    RETVAL

#endif

#ifdef PSX2008_HAS_ISBLANK
int
isblank(SV *charstring);
  CODE:
    ISFUNC(isblank)
  OUTPUT:
    RETVAL

#endif

#ifdef PSX2008_HAS_ISCNTRL
int
iscntrl(SV *charstring);
  CODE:
    ISFUNC(iscntrl)
  OUTPUT:
    RETVAL

#endif

#ifdef PSX2008_HAS_ISDIGIT
int
isdigit(SV *charstring);
  CODE:
    ISFUNC(isdigit)
  OUTPUT:
    RETVAL

#endif

#ifdef PSX2008_HAS_ISGRAPH
int
isgraph(SV *charstring);
  CODE:
    ISFUNC(isgraph)
  OUTPUT:
    RETVAL

#endif

#ifdef PSX2008_HAS_ISLOWER
int
islower(SV *charstring);
  CODE:
    ISFUNC(islower)
  OUTPUT:
    RETVAL

#endif

#ifdef PSX2008_HAS_ISPRINT
int
isprint(SV *charstring);
  CODE:
    ISFUNC(isprint)
  OUTPUT:
    RETVAL

#endif

#ifdef PSX2008_HAS_ISPUNCT
int
ispunct(SV *charstring);
  CODE:
    ISFUNC(ispunct)
  OUTPUT:
    RETVAL

#endif

#ifdef PSX2008_HAS_ISSPACE
int
isspace(SV *charstring);
  CODE:
    ISFUNC(isspace)
  OUTPUT:
    RETVAL

#endif

#ifdef PSX2008_HAS_ISUPPER
int
isupper(SV *charstring);
  CODE:
    ISFUNC(isupper)
  OUTPUT:
    RETVAL

#endif

#ifdef PSX2008_HAS_ISXDIGIT
int
isxdigit(SV *charstring);
  CODE:
    ISFUNC(isxdigit)
  OUTPUT:
    RETVAL

#endif

#ifdef PSX2008_HAS_LINK
SysRetTrue
link(const char *oldpath, const char *newpath);

#endif

#ifdef PSX2008_HAS_SYMLINK
SysRetTrue
symlink(const char *target, const char *linkpath);

#endif

#ifdef PSX2008_HAS_MKDIR
SysRetTrue
mkdir(const char *path, mode_t mode=0777);

#endif

#ifdef PSX2008_HAS_MKFIFO
SysRetTrue
mkfifo(const char *path, mode_t mode);

#endif

#ifdef PSX2008_HAS_MKNOD
SysRetTrue
mknod(const char *path, mode_t mode, dev_t dev);

#endif

#ifdef PSX2008_HAS_MKDTEMP
void
mkdtemp(SV *template_sv);
  PPCODE:
  {
    STRLEN len;
    const char *ctmp = SvPV_const(template_sv, len);
    /* Copy the original template to avoid overwriting it. */
    SV *tmpsv = newSVpvn_flags(ctmp, len, SVs_TEMP);
    char *dtemp = mkdtemp(SvPVX(tmpsv));
    PUSHs(LIKELY(!!dtemp) ? tmpsv : &PL_sv_undef);
  }

#endif

#ifdef PSX2008_HAS_MKSTEMP
void
mkstemp(SV *template_sv);
  PPCODE:
  {
    STRLEN len;
    const char *ctmp = SvPV_const(template_sv, len);
    /* Copy the original template to avoid overwriting it. */
    SV *tmpsv = newSVpvn_flags(ctmp, len, SVs_TEMP);
    int fd = mkstemp(SvPVX(tmpsv));
    if (LIKELY(fd >= 0)) {
      mPUSHs(newSViv(fd));
      PUSHs(tmpsv);
    }
  }

#endif

#ifdef PSX2008_HAS_MKOSTEMP
void
mkostemp(SV *template_sv, int flags);
  PPCODE:
  {
    STRLEN len;
    const char *ctmp = SvPV_const(template_sv, len);
    /* Copy the original template to avoid overwriting it. */
    SV *tmpsv = newSVpvn_flags(ctmp, len, SVs_TEMP);
    int fd = mkostemp(SvPVX(tmpsv), flags);
    if (LIKELY(fd >= 0)) {
      mPUSHs(newSViv(fd));
      PUSHs(tmpsv);
    }
  }

#endif

#if defined(PSX2008_HAS_FDOPEN)
void
fdopen(IV fd, const char *mode);
  PPCODE:
  {
    SV *rv = NULL;
    if (UNLIKELY(fd < 0 || fd > PERL_INT_MAX))
      SETERRNO(EBADF, RMS_IFI);
    else if (UNLIKELY(!mode || !*mode))
      SETERRNO(EINVAL, LIB_INVARG);
    else
      rv = _psx_fd_to_handle(aTHX_ fd, mode);
    PUSHs(rv ? rv : &PL_sv_undef);
  }

#endif

#if defined(PSX2008_HAS_FDOPENDIR)
void
fdopendir(IV fd);
  PPCODE:
  {
    SV *rv = NULL;
    if (UNLIKELY(fd < 0 || fd > PERL_INT_MAX))
      SETERRNO(EBADF, RMS_IFI);
    else
      rv = _psx_fd_to_handle(aTHX_ fd, NULL);
    PUSHs(rv ? rv : &PL_sv_undef);
  }

#endif


 ##
 ## POSIX::open(), read() and write() return "0 but true" for 0, which
 ## is not quite what you would expect. We return a real 0.
 ##

#ifdef PSX2008_HAS_CREAT
SysRet0
creat(const char *path, mode_t mode=0666)

#endif

#ifdef PSX2008_HAS_OPEN
SysRet0
open(const char *path, int oflag=O_RDONLY, mode_t mode=0666);

#endif

#ifdef PSX2008_HAS_CLOSE
SysRetTrue
close(SV *fd);
    CODE:
        RETVAL = _psx_close(aTHX_ fd);
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
fchownat(psx_fd_t dirfd,                                                \
         const char *path, uid_t owner, gid_t group, int flags=0);

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
linkat(psx_fd_t olddirfd, const char *oldpath,                  \
       psx_fd_t newdirfd, const char *newpath, int flags=0);

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
openat(SV *dirfdsv, const char *path, int flags=O_RDONLY, mode_t mode=0666);
  PPCODE:
  {
    SV *rv = _openat50c(aTHX_ dirfdsv, path, flags, mode, NULL);
    PUSHs(rv ? rv : &PL_sv_undef);
  }

#endif

#ifdef PSX2008_HAS_OPENAT2
void
openat2(SV *dirfdsv, const char *path, HV *how);
  PPCODE:
  {
    SV *rv = _openat50c(aTHX_ dirfdsv, path, 0, 0, how);
    PUSHs(rv ? rv : &PL_sv_undef);
  }

#endif

#ifdef PSX2008_HAS_READLINK
void
readlink(const char *path);
  PPCODE:
  {
    SV *rv = _readlink50c(aTHX_ path, NULL);
    PUSHs(rv ? rv : &PL_sv_undef);
  }

#endif

#ifdef PSX2008_HAS_READLINKAT
void
readlinkat(psx_fd_t dirfd, const char *path);
  PPCODE:
  {
    SV *rv = _readlink50c(aTHX_ path, &dirfd);
    PUSHs(rv ? rv : &PL_sv_undef);
  }

#endif

#ifdef PSX2008_HAS_REALPATH
char *
realpath(const char *path);
  CODE:
    RETVAL = realpath(path, NULL);
  OUTPUT:
    RETVAL
  CLEANUP:
    free(RETVAL);

#endif

#ifdef PSX2008_HAS_RENAMEAT
SysRetTrue
renameat(psx_fd_t olddirfd, const char *oldpath,        \
         psx_fd_t newdirfd, const char *newpath);

#endif

#ifdef PSX2008_HAS_RENAMEAT2
SysRetTrue
renameat2(psx_fd_t olddirfd, const char *oldpath,                       \
          psx_fd_t newdirfd, const char *newpath, unsigned int flags=0);

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
utimensat(psx_fd_t dirfd, const char *path, int flags = 0,      \
          time_t atime_sec = 0, long atime_nsec = UTIME_NOW,    \
          time_t mtime_sec = 0, long mtime_nsec = UTIME_NOW);
    PROTOTYPE: $$;$@
    INIT:
        const struct timespec times[2] = { { atime_sec, atime_nsec },
                                           { mtime_sec, mtime_nsec } };
    CODE:
        RETVAL = utimensat(dirfd, path, times, flags);
    OUTPUT:
        RETVAL

#endif

#ifdef PSX2008_HAS_READ
void
read(psx_fd_t fd, SV *buf, SV *count);
  PREINIT:
    SSize_t rv;
    Size_t nbytes;
    char *cbuf;
  PPCODE:
  {
    if (UNLIKELY(SvIsNEGATIVE(count))) /* Performs 'get' magic. */
      croak("%s::read: Negative count: %" SVf_QUOTEDPREFIX,
            PACKNAME, SVfARG(count));
    nbytes = SvSTRLEN(count);
    nbytes = (nbytes > SSIZE_MAX) ? SSIZE_MAX : nbytes;
    if (UNLIKELY(SvTRULYREADONLY(buf))) {
      if (nbytes)
        croak("%s::read: Can't modify read-only buf", PACKNAME);
      cbuf = NULL;
    }
    else {
      if (!SvPOK(buf))
        SvPVCLEAR(buf);
      (void)SvPV_force_nomg_nolen(buf);
      /* +1 for final '\0' to be on the safe side. */
      cbuf = SvGROW(buf, nbytes+1);
    }
    rv = read(fd, cbuf, nbytes);
    if (UNLIKELY(rv < 0))
      PUSHs(&PL_sv_undef);
    else {
      if (cbuf) {
        cbuf[rv] = '\0';
        SvCUR_set(buf, rv);
        SvPOK_only(buf);
        SvTAINTED_on(buf);
        SvSETMAGIC(buf);
      }
      PUSH_INT_OR_PV(rv);
    }
  }

#endif

#ifdef PSX2008_HAS_WRITE
void
write(psx_fd_t fd, SV *buf, SV *count=NULL);
  PPCODE:
  {
    if (UNLIKELY(SvIsNEGATIVE(count))) /* Performs 'get' magic. */
      croak("%s::write: Negative count: %" SVf_QUOTEDPREFIX,
            PACKNAME, SVfARG(count));
    else {
      SSize_t rv;
      Size_t buflen;
      const char *cbuf = SvPV_const(buf, buflen);
      Size_t nbytes = buflen;
      if (!SvIsUNDEF_onpurpose(count)) {
        STRLEN ct = SvSTRLEN(count);
        nbytes = (nbytes > ct) ? ct : nbytes;
      }
      nbytes = (nbytes > SSIZE_MAX) ? SSIZE_MAX : nbytes;
      rv = write(fd, cbuf, nbytes);
      if (UNLIKELY(rv < 0))
        PUSHs(&PL_sv_undef);
      else
        PUSH_INT_OR_PV(rv);
    }
  }

#endif

#ifdef PSX2008_HAS_READV
void
readv(psx_fd_t fd, SV *buffers, AV *sizes);
  PROTOTYPE: $\[@$]$
  PPCODE:
  {
    SSize_t rv = _readv50c(aTHX_ fd, buffers, sizes, NULL, NULL);
    if (UNLIKELY(rv < 0))
      PUSHs(&PL_sv_undef);
    else
      PUSH_INT_OR_PV(rv);
  }

#endif

#ifdef PSX2008_HAS_PREADV
void
preadv(psx_fd_t fd, SV *buffers, AV *sizes, SV *offset=NULL);
  PROTOTYPE: $\[@$]$;$
  PPCODE:
  {
    SSize_t rv = _readv50c(aTHX_ fd, buffers, sizes, offset, NULL);
    if (UNLIKELY(rv < 0))
      PUSHs(&PL_sv_undef);
    else
      PUSH_INT_OR_PV(rv);
  }

#endif


#ifdef PSX2008_HAS_PREADV2
void
preadv2(psx_fd_t fd, SV *buffers, AV *sizes, SV *offset=NULL, SV *flags=NULL);
  PROTOTYPE: $\[@$]$;$$
  PPCODE:
  {
    SSize_t rv = _readv50c(aTHX_ fd, buffers, sizes, offset, flags);
    if (UNLIKELY(rv < 0))
      PUSHs(&PL_sv_undef);
    else
      PUSH_INT_OR_PV(rv);
  }

#endif

#ifdef PSX2008_HAS_WRITEV
void
writev(psx_fd_t fd, AV *buffers);
  PPCODE:
  {
    struct iovec *iov;
    int iovcnt = _psx_av2iov(aTHX_ buffers, &iov);
    SSize_t rv = LIKELY(iovcnt >= 0) ? writev(fd, iov, iovcnt) : -1;
    if (UNLIKELY(rv < 0))
      PUSHs(&PL_sv_undef);
    else
      PUSH_INT_OR_PV(rv);
  }

#endif

#ifdef PSX2008_HAS_PWRITEV
void
pwritev(psx_fd_t fd, AV *buffers, SV *offset=NULL);
  PPCODE:
  {
    struct iovec *iov;
    Off_t offs = SvIsUNDEF_onpurpose(offset) ? 0 : SvOFFt(offset);
    int iovcnt = _psx_av2iov(aTHX_ buffers, &iov);
    SSize_t rv = LIKELY(iovcnt >= 0) ? pwritev(fd, iov, iovcnt, offs) : -1;
    if (UNLIKELY(rv < 0))
      PUSHs(&PL_sv_undef);
    else
      PUSH_INT_OR_PV(rv);
  }

#endif

#ifdef PSX2008_HAS_PWRITEV2
void
pwritev2(psx_fd_t fd, AV *buffers, SV *offset=NULL, SV *flags=NULL);
  PPCODE:
  {
    struct iovec *iov;
    Off_t offs = SvIsUNDEF_onpurpose(offset) ? 0 : SvOFFt(offset);
    int i_flags = SvIsUNDEF_onpurpose(flags) ? 0 : (int)SvIV(flags);
    int iovcnt = _psx_av2iov(aTHX_ buffers, &iov);
    SSize_t rv =
      LIKELY(iovcnt >= 0) ? pwritev2(fd, iov, iovcnt, offs, i_flags) : -1;
    if (UNLIKELY(rv < 0))
      PUSHs(&PL_sv_undef);
    else
      PUSH_INT_OR_PV(rv);
  }

#endif

#ifdef PSX2008_HAS_PREAD
void
pread(psx_fd_t fd, SV *buf, SV *count, SV *offset=NULL, SV *buf_offset=NULL);
  PREINIT:
    char *cbuf;
    Off_t f_offset;
    Size_t b_offset, nbytes;
    SSize_t rv;
  PPCODE:
  {
    if (UNLIKELY(SvIsNEGATIVE(count))) /* Performs 'get' magic. */
      croak("%s::pread: Negative count: %" SVf_QUOTEDPREFIX,
            PACKNAME, SVfARG(count));

    nbytes = SvSTRLEN(count);
    if (nbytes > SSIZE_MAX)
      nbytes = SSIZE_MAX;

    if (UNLIKELY(SvTRULYREADONLY(buf))) {
      if (nbytes)
        croak("%s::pread: Can't modify read-only buf", PACKNAME);
      cbuf = NULL;
      b_offset = 0;
    }
    else {
      Size_t cbuflen, new_len;

      if (!SvPOK(buf))
        SvPVCLEAR(buf);
      (void)SvPV_force_nomg(buf, cbuflen);

      /* Ensure buf_offset results in a valid string index. */
      if (SvIsUNDEF_onpurpose(buf_offset))
        b_offset = 0;
      else {
        const int neg = SvIsNEGATIVE(buf_offset) != 0;
        b_offset = SvSTRLEN(buf_offset);
        if (neg) {
          b_offset += cbuflen;
          if (b_offset > cbuflen)
            croak("%s::pread: buf_offset %" SVf_QUOTEDPREFIX " outside string",
                  PACKNAME, SVfARG(buf_offset));
        }
      }

      new_len = b_offset + nbytes;
      if (new_len < b_offset || new_len+1 == 0) /* Overflow check. */
        croak("%s::pread: buf_offset[%" SVf_QUOTEDPREFIX
              "] + count[%" SVf_QUOTEDPREFIX "] is too big for a Perl string",
              PACKNAME, SVfARG(buf_offset), SVfARG(count));

      /* +1 for final '\0' to be on the safe side. */
      cbuf = SvGROW(buf, new_len+1);

      /* Pad buffer with zeros if b_offset is past the buffer. */
      if (b_offset > cbuflen)
        Zero(cbuf + cbuflen, b_offset - cbuflen, char);
    }

    /* Now fscking finally read teh data! */
    f_offset = SvIsUNDEF_onpurpose(offset) ? 0 : SvOFFt(offset);
    rv = pread(fd, cbuf + b_offset, nbytes, f_offset);

    if (UNLIKELY(rv < 0))
      PUSHs(&PL_sv_undef);
    else {
      if (cbuf) {
        cbuf[b_offset + rv] = '\0';
        SvCUR_set(buf, b_offset + rv);
        SvPOK_only(buf);
        SvTAINTED_on(buf);
        SvSETMAGIC(buf);
      }
      PUSH_INT_OR_PV(rv);
    }
  }

#endif

#ifdef PSX2008_HAS_PWRITE
void
pwrite(psx_fd_t fd, SV *buf,                            \
       SV *count=NULL, SV *offset=NULL, SV *buf_offset=NULL);
  PREINIT:
    Off_t f_offset;
    Size_t b_offset;
    SSize_t rv;
  PPCODE:
  {
    STRLEN svpv_len;
    const char *cbuf = SvPV_const(buf, svpv_len);
    STRLEN nbytes = svpv_len;

    /* Ensure buf_offset results in a valid string index. This is slightly
     * different from pread() because we can't allow offsets beyond the buffer
     * at all (zero is okay, though). */
    if (SvIsUNDEF_onpurpose(buf_offset))
      b_offset = 0;
    else {
      /* See _psx_av2iov() for all the magic involved. */
      const STRLEN neg = ~(STRLEN)SvIsNEGATIVE(buf_offset) + 1;
      b_offset = SvSTRLEN(buf_offset);
      b_offset += neg & nbytes;
      nbytes -= b_offset;
      if (nbytes > nbytes + b_offset)
        croak("%s::pwrite: buf_offset %" SVf_QUOTEDPREFIX " outside string",
              PACKNAME, SVfARG(buf_offset));
    }

    if (UNLIKELY(SvIsNEGATIVE(count))) /* Performs 'get' magic. */
      croak("%s::pwrite: Negative count: %" SVf_QUOTEDPREFIX,
            PACKNAME, SVfARG(count));
    if (!SvIsUNDEF_onpurpose(count)) {
      const STRLEN ct = SvSTRLEN(count);
      if (nbytes > ct)
        nbytes = ct;
    }
    if (nbytes > SSIZE_MAX)
      nbytes = SSIZE_MAX;

    f_offset = SvIsUNDEF_onpurpose(offset) ? 0 : SvOFFt(offset);
    rv = pwrite(fd, cbuf + b_offset, nbytes, f_offset);

    if (UNLIKELY(rv < 0))
      PUSHs(&PL_sv_undef);
    else
      PUSH_INT_OR_PV(rv);
  }

#endif

#ifdef PSX2008_HAS_POSIX_FADVISE
void
posix_fadvise(psx_fd_t fd, Off_t offset, Off_t len, int advice);
  PPCODE:
  {
    int rv = posix_fadvise(fd, offset, len, advice);
    if (LIKELY(rv == 0))
      mPUSHp("0 but true", 10);
    else {
      SETERRNO(rv, rv);
      PUSHs(&PL_sv_undef);
    }
  }

#endif

#ifdef PSX2008_HAS_POSIX_FALLOCATE
void
posix_fallocate(psx_fd_t fd, Off_t offset, Off_t len);
  PPCODE:
  {
    int rv = posix_fallocate(fd, offset, len);
    if (LIKELY(rv == 0))
      mPUSHp("0 but true", 10);
    else {
      SETERRNO(rv, rv);
      PUSHs(&PL_sv_undef);
    }
  }

#endif

#ifdef PSX2008_HAS_POSIX_OPENPT
void
posix_openpt(int flags=O_RDWR);
  PPCODE:
  {
    const char *raw = _flags2raw(flags);
    int fd = posix_openpt(flags);
    SV *rv = LIKELY(fd >= 0) ? _psx_fd_to_handle(aTHX_ fd, raw) : NULL;
    PUSHs(rv ? rv : &PL_sv_undef);
  }

#endif

#ifdef PSX2008_HAS_GRANTPT
SysRetTrue
grantpt(psx_fd_t fd);

#endif

#ifdef PSX2008_HAS_UNLOCKPT
SysRetTrue
unlockpt(psx_fd_t fd);

#endif

#ifdef PSX2008_HAS_PTSNAME
void
ptsname(psx_fd_t fd);
  PPCODE:
  {
# ifdef PSX2008_HAS_PTSNAME_R
    char name[MAXPATHLEN];
    int rv = ptsname_r(fd, name, sizeof(name));
    if (LIKELY(rv == 0))
      mPUSHp(name, _strnlen(name, sizeof(name)));
    else {
      /* Some implementations return -1 on error and set errno. */
      if (rv > 0) SETERRNO(rv, rv);
      PUSHs(&PL_sv_undef);
    }
# else
    char *name = ptsname(fd);
    if (LIKELY(!!name))
      mPUSHp(name, _strnlen(name, MAXPATHLEN));
    else
      PUSHs(&PL_sv_undef);
# endif
  }

#endif

#ifdef PSX2008_HAS_TTYNAME
void
ttyname(psx_fd_t fd);
  PPCODE:
  {
# ifdef PSX2008_HAS_TTYNAME_R
    char name[MAXPATHLEN];
    int rv = ttyname_r(fd, name, sizeof(name));
    if (LIKELY(rv == 0))
      mPUSHp(name, _strnlen(name, sizeof(name)));
    else {
      SETERRNO(rv, rv);
      PUSHs(&PL_sv_undef);
    }
# else
    char *name = ttyname(fd);
    if (LIKELY(!!name))
      mPUSHp(name, _strnlen(name, MAXPATHLEN));
    else
      PUSHs(&PL_sv_undef);
# endif
  }

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
 ## 'unlink $_[0] or ($!{EISDIR} or $!{EPERM}) and rmdir $_[0]'
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
    else
      PUSHs(&PL_sv_undef);

# else

# endif
#else
SysRetTrue
remove(const char *path);

#endif

#ifdef PSX2008_HAS_UNLINKAT
void
removeat(psx_fd_t dirfd, const char *path);
  PPCODE:
    if (unlinkat(dirfd, path, 0) == 0
        || (UNLINK_ISDIR_ERRNO && unlinkat(dirfd, path, AT_REMOVEDIR) == 0))
      mPUSHp("0 but true", 10);
    else
      PUSHs(&PL_sv_undef);

#endif

#ifdef PSX2008_HAS_RENAME
SysRetTrue
rename(const char *oldpath, const char *newpath);

#endif

#ifdef PSX2008_HAS_RMDIR
SysRetTrue
rmdir(const char *path);

#endif

#ifdef PSX2008_HAS_UNLINK
SysRetTrue
unlink(const char *path);

#endif

#ifdef PSX2008_HAS_FUTIMENS
SysRetTrue
futimens(psx_fd_t fd,                                           \
         time_t atime_sec = 0, long atime_nsec = UTIME_NOW,     \
         time_t mtime_sec = 0, long mtime_nsec = UTIME_NOW);
  PROTOTYPE: $@
  INIT:
    const struct timespec times[2] = { { atime_sec, atime_nsec },
                                       { mtime_sec, mtime_nsec } };
  CODE:
    RETVAL = futimens(fd, times);
  OUTPUT:
    RETVAL

#endif

#ifdef PSX2008_HAS_EXECVEAT
void
execveat(psx_fd_t dirfd, const char *path,              \
         AV *args, SV *env=NULL, int flags=0);
  PPCODE:
  {
    _execve50c(aTHX_ dirfd, path, args, env, flags);
    PUSHs(&PL_sv_undef);
  }

#endif

#ifdef PSX2008_HAS_FEXECVE
void
fexecve(psx_fd_t fd, AV *args, SV *env=NULL);
  PPCODE:
  {
    _execve50c(aTHX_ fd, NULL, args, env, 0);
    PUSHs(&PL_sv_undef);
  }

#endif

#ifdef PSX2008_HAS_POLL
void
poll(SV *pollfds, int timeout=-1);
  PPCODE:
  {
    int rv = _poll50c(aTHX_ pollfds, timeout, NULL);
    mPUSHs(newSViv(rv));
  }

#endif

#ifdef PSX2008_HAS_PPOLL
void
ppoll(SV *pollfds, SV *timeout=NULL, SV *sigmask=NULL);
  PREINIT:
    int rv;
    struct timespec tmo = {0};
    struct psx_ppollspec ppspec = {0};
  PPCODE:
  {
    /* See POSIX::sigprocmask(). Can't be wrong [TM]. */
    if (sigmask && SvOK(sigmask)) {
      if (sv_isa(sigmask, "POSIX::SigSet")) {
#if PERL_BCDVERSION >= 0x5016000
        ppspec.sigmask = (sigset_t*)SvPV_nolen(SvRV(sigmask));
#else
        IV tmp = SvIV((SV*)SvRV(sigmask));
        ppspec.sigmask = INT2PTR(sigset_t*, tmp);
#endif
      }
      else
        croak("%s::ppoll: sigmask is not a POSIX::SigSet", PACKNAME);
    }
    if (timeout) {
      SvGETMAGIC(timeout);
      if (SvOK(timeout)) {
        ppspec.tmo_p = &tmo;
        if (SvIsARRAY(timeout)) {
          SV **sec_sv, **nsec_sv;
          AV *timeout_av = (AV*)SvRV(timeout);
          sec_sv = av_fetch(timeout_av, 0, 0);
          if (sec_sv)
            tmo.tv_sec = SvIV(*sec_sv);
          nsec_sv = av_fetch(timeout_av, 1, 0);
          if (nsec_sv)
            tmo.tv_nsec = SvIV(*nsec_sv);
        }
        else if (LOOKS_LIKE_NV(timeout))
          TIMESPEC_FROM_NV_nomg(tmo, timeout);
        else
          TIMESPEC_FROM_IV_nomg(tmo, timeout, 0);
      }
    }
    rv = _poll50c(aTHX_ pollfds, 0, &ppspec);
    mPUSHs(newSViv(rv));
  }

#endif

 ## Integer and real number arithmetic
 #####################################

 ## We rely on Makefile.PL to set HAS_xxL/Q only if long double or quadmath
 ## is actually in use (i.e. USE_LONG_DOUBLE/USE_QUADMATH). For most math
 ## functions we use the existence of sqrtl/q to decide which variant to use.
 ############################################################################

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
acos(NV x);
  CODE:
# if defined(PSX2008_HAS_SQRTQ)
    RETVAL = acosq(x);
# elif defined(PSX2008_HAS_SQRTL)
    RETVAL = acosl(x);
# else
    RETVAL = acos(x);
# endif
  OUTPUT:
    RETVAL

#endif

#ifdef PSX2008_HAS_ACOSH
NV
acosh(NV x);
  CODE:
# if defined(PSX2008_HAS_SQRTQ)
    RETVAL = acoshq(x);
# elif defined(PSX2008_HAS_SQRTL)
    RETVAL = acoshl(x);
# else
    RETVAL = acosh(x);
# endif
  OUTPUT:
    RETVAL

#endif

#ifdef PSX2008_HAS_ASIN
NV
asin(NV x);
  CODE:
# if defined(PSX2008_HAS_SQRTQ)
    RETVAL = asinq(x);
# elif defined(PSX2008_HAS_SQRTL)
    RETVAL = asinl(x);
# else
    RETVAL = asin(x);
# endif
  OUTPUT:
    RETVAL

#endif

#ifdef PSX2008_HAS_ASINH
NV
asinh(NV x);
  CODE:
# if defined(PSX2008_HAS_SQRTQ)
    RETVAL = asinhq(x);
# elif defined(PSX2008_HAS_SQRTL)
    RETVAL = asinhl(x);
# else
    RETVAL = asinh(x);
# endif
  OUTPUT:
    RETVAL

#endif

#ifdef PSX2008_HAS_ATAN
NV
atan(NV x);
  CODE:
# if defined(PSX2008_HAS_SQRTQ)
    RETVAL = atanq(x);
# elif defined(PSX2008_HAS_SQRTL)
    RETVAL = atanl(x);
# else
    RETVAL = atan(x);
# endif
  OUTPUT:
    RETVAL

#endif

#ifdef PSX2008_HAS_ATAN2
NV
atan2(NV y, NV x);
  CODE:
# if defined(PSX2008_HAS_SQRTQ)
    RETVAL = atan2q(y, x);
# elif defined(PSX2008_HAS_SQRTL)
    RETVAL = atan2l(y, x);
# else
    RETVAL = atan2(y, x);
# endif
  OUTPUT:
    RETVAL

#endif

#ifdef PSX2008_HAS_ATANH
NV
atanh(NV x);
  CODE:
# if defined(PSX2008_HAS_SQRTQ)
    RETVAL = atanhq(x);
# elif defined(PSX2008_HAS_SQRTL)
    RETVAL = atanhl(x);
# else
    RETVAL = atanh(x);
# endif
  OUTPUT:
    RETVAL

#endif

#ifdef PSX2008_HAS_CBRT
NV
cbrt(NV x);
  CODE:
# if defined(PSX2008_HAS_SQRTQ)
    RETVAL = cbrtq(x);
# elif defined(PSX2008_HAS_SQRTL)
    RETVAL = cbrtl(x);
# else
    RETVAL = cbrt(x);
# endif
  OUTPUT:
    RETVAL

#endif

#ifdef PSX2008_HAS_CEIL
NV
ceil(NV x);
  CODE:
# if defined(PSX2008_HAS_SQRTQ)
    RETVAL = ceilq(x);
# elif defined(PSX2008_HAS_SQRTL)
    RETVAL = ceill(x);
# else
    RETVAL = ceil(x);
# endif
  OUTPUT:
    RETVAL

#endif

#ifdef PSX2008_HAS_COPYSIGN
NV
copysign(NV x, NV y);
  CODE:
# if defined(PSX2008_HAS_SQRTQ)
    RETVAL = copysignq(x, y);
# elif defined(PSX2008_HAS_SQRTL)
    RETVAL = copysignl(x, y);
# else
    RETVAL = copysign(x, y);
# endif
  OUTPUT:
    RETVAL

#endif

#ifdef PSX2008_HAS_COS
NV
cos(NV x);
  CODE:
# if defined(PSX2008_HAS_SQRTQ)
    RETVAL = cosq(x);
# elif defined(PSX2008_HAS_SQRTL)
    RETVAL = cosl(x);
# else
    RETVAL = cos(x);
# endif
  OUTPUT:
    RETVAL

#endif

#ifdef PSX2008_HAS_COSH
NV
cosh(NV x);
  CODE:
# if defined(PSX2008_HAS_SQRTQ)
    RETVAL = coshq(x);
# elif defined(PSX2008_HAS_SQRTL)
    RETVAL = coshl(x);
# else
    RETVAL = cosh(x);
# endif
  OUTPUT:
    RETVAL

#endif

#ifdef PSX2008_DIV
void
div(IV numer, IV denom);
  PPCODE:
  {
    PSX2008_DIV_T result = PSX2008_DIV(numer, denom);
    mPUSHs(newSViv(result.quot));
    mPUSHs(newSViv(result.rem));
  }

#endif

#ifdef PSX2008_HAS_ERF
NV
erf(NV x);
  CODE:
# if defined(PSX2008_HAS_SQRTQ)
    RETVAL = erfq(x);
# elif defined(PSX2008_HAS_SQRTL)
    RETVAL = erfl(x);
# else
    RETVAL = erf(x);
# endif
  OUTPUT:
    RETVAL

#endif

#ifdef PSX2008_HAS_ERFC
NV
erfc(NV x);
  CODE:
# if defined(PSX2008_HAS_SQRTQ)
    RETVAL = erfcq(x);
# elif defined(PSX2008_HAS_SQRTL)
    RETVAL = erfcl(x);
# else
    RETVAL = erfc(x);
# endif
  OUTPUT:
    RETVAL

#endif

#ifdef PSX2008_HAS_EXP
NV
exp(NV x);
  CODE:
# if defined(PSX2008_HAS_SQRTQ)
    RETVAL = expq(x);
# elif defined(PSX2008_HAS_SQRTL)
    RETVAL = expl(x);
# else
    RETVAL = exp(x);
# endif
  OUTPUT:
    RETVAL

#endif

#if defined(PSX2008_HAS_EXP2) && (!defined(USE_QUADMATH) || defined(PSX2008_HAS_EXP2Q))
NV
exp2(NV x);
  CODE:
# if defined(PSX2008_HAS_EXP2Q)
    RETVAL = exp2q(x);
# elif defined(PSX2008_HAS_SQRTL)
    RETVAL = exp2l(x);
# else
    RETVAL = exp2(x);
# endif
  OUTPUT:
    RETVAL

#endif

#ifdef PSX2008_HAS_EXPM1
NV
expm1(NV x);
  CODE:
# if defined(PSX2008_HAS_SQRTQ)
    RETVAL = expm1q(x);
# elif defined(PSX2008_HAS_SQRTL)
    RETVAL = expm1l(x);
# else
    RETVAL = expm1(x);
# endif
  OUTPUT:
    RETVAL

#endif

#ifdef PSX2008_HAS_FABS
NV
fabs(NV x);
  CODE:
# if defined(PSX2008_HAS_SQRTQ)
    RETVAL = fabsq(x);
# elif defined(PSX2008_HAS_SQRTL)
    RETVAL = fabsl(x);
# else
    RETVAL = fabs(x);
# endif
  OUTPUT:
    RETVAL

#endif

#ifdef PSX2008_HAS_FDIM
NV
fdim(NV x, NV y);
  CODE:
# if defined(PSX2008_HAS_SQRTQ)
    RETVAL = fdimq(x, y);
# elif defined(PSX2008_HAS_SQRTL)
    RETVAL = fdiml(x, y);
# else
    RETVAL = fdim(x, y);
# endif
  OUTPUT:
    RETVAL

#endif

#ifdef PSX2008_HAS_FLOOR
NV
floor(NV x);
  CODE:
# if defined(PSX2008_HAS_SQRTQ)
    RETVAL = floorq(x);
# elif defined(PSX2008_HAS_SQRTL)
    RETVAL = floorl(x);
# else
    RETVAL = floor(x);
# endif
  OUTPUT:
    RETVAL

#endif

#ifdef PSX2008_HAS_FMA
NV
fma(NV x, NV y, NV z);
  CODE:
# if defined(PSX2008_HAS_SQRTQ)
    RETVAL = fmaq(x, y, z);
# elif defined(PSX2008_HAS_SQRTL)
    RETVAL = fmal(x, y, z);
# else
    RETVAL = fma(x, y, z);
# endif
  OUTPUT:
    RETVAL

#endif

#ifdef PSX2008_HAS_FMAX
NV
fmax(NV x, NV y);
  CODE:
# if defined(PSX2008_HAS_SQRTQ)
    RETVAL = fmaxq(x, y);
# elif defined(PSX2008_HAS_SQRTL)
    RETVAL = fmaxl(x, y);
# else
    RETVAL = fmax(x, y);
# endif
  OUTPUT:
    RETVAL

#endif

#ifdef PSX2008_HAS_FMIN
NV
fmin(NV x, NV y);
  CODE:
# if defined(PSX2008_HAS_SQRTQ)
    RETVAL = fminq(x, y);
# elif defined(PSX2008_HAS_SQRTL)
    RETVAL = fminl(x, y);
# else
    RETVAL = fmin(x, y);
# endif
  OUTPUT:
    RETVAL

#endif

#ifdef PSX2008_HAS_FMOD
NV
fmod(NV x, NV y);
  CODE:
# if defined(PSX2008_HAS_SQRTQ)
    RETVAL = fmodq(x, y);
# elif defined(PSX2008_HAS_SQRTL)
    RETVAL = fmodl(x, y);
# else
    RETVAL = fmod(x, y);
# endif
  OUTPUT:
    RETVAL

#endif

#ifdef PSX2008_HAS_FPCLASSIFY
int
fpclassify(NV x);

#endif

#ifdef PSX2008_HAS_FREXP
void
frexp(NV x);
  PPCODE:
  {
    NV fr;
    int exp;
# if defined(PSX2008_HAS_SQRTQ)
    fr = frexpq(x, &exp);
# elif defined(PSX2008_HAS_SQRTL)
    fr = frexpl(x, &exp);
# else
    fr = frexp(x, &exp);
# endif
    mPUSHs(newSVnv(fr));
    mPUSHs(newSVnv(exp));
  }

#endif

#ifdef PSX2008_HAS_HYPOT
NV
hypot(NV x, NV y);
  CODE:
# if defined(PSX2008_HAS_SQRTQ)
    RETVAL = hypotq(x, y);
# elif defined(PSX2008_HAS_SQRTL)
    RETVAL = hypotl(x, y);
# else
    RETVAL = hypot(x, y);
# endif
  OUTPUT:
    RETVAL

#endif

#ifdef PSX2008_HAS_ILOGB
NV
ilogb(NV x);
  CODE:
# if defined(PSX2008_HAS_SQRTQ)
    RETVAL = ilogbq(x);
# elif defined(PSX2008_HAS_SQRTL)
    RETVAL = ilogbl(x);
# else
    RETVAL = ilogb(x);
# endif
  OUTPUT:
    RETVAL

#endif

#ifdef PSX2008_HAS_ISFINITE
int
isfinite(NV x);
  CODE:
# if defined(PSX2008_HAS_FINITEQ)
    RETVAL = finiteq(x);
# elif defined(PSX2008_HAS_ISFINITEL)
    RETVAL = isfinitel(x);
# else
    RETVAL = isfinite(x);
# endif
  OUTPUT:
    RETVAL

#endif

#ifdef PSX2008_HAS_ISINF
int
isinf(NV x);
  CODE:
# if defined(PSX2008_HAS_ISINFQ)
    RETVAL = isinfq(x);
# elif defined(PSX2008_HAS_ISINFL)
    RETVAL = isinfl(x);
# else
    RETVAL = isinf(x);
# endif
  OUTPUT:
    RETVAL

#endif

#ifdef PSX2008_HAS_ISNAN
int
isnan(NV x);
  CODE:
# if defined(PSX2008_HAS_ISNANQ)
    RETVAL = isnanq(x);
# elif defined(PSX2008_HAS_ISNANL)
    RETVAL = isnanl(x);
# else
    RETVAL = isnan(x);
# endif
  OUTPUT:
    RETVAL

#endif

#ifdef PSX2008_HAS_ISNORMAL
int
isnormal(NV x);

#endif

#ifdef PSX2008_HAS_ISLESS
int
isless(NV x, NV y);

#endif

#ifdef PSX2008_HAS_ISLESSEQUAL
int
islessequal(NV x, NV y);

#endif

#ifdef PSX2008_HAS_ISGREATEREQUAL
int
isgreaterequal(NV x, NV y);

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
j0(NV x);
  CODE:
# if defined(PSX2008_HAS_SQRTQ)
    RETVAL = j0q(x);
# elif defined(PSX2008_HAS_SQRTL) && !defined(__MINGW32__)
    RETVAL = j0l(x);
# else
    RETVAL = j0(x);
# endif
  OUTPUT:
    RETVAL

#endif

#ifdef PSX2008_HAS_J1
NV
j1(NV x);
  CODE:
# if defined(PSX2008_HAS_SQRTQ)
    RETVAL = j1q(x);
# elif defined(PSX2008_HAS_SQRTL) && !defined(__MINGW32__)
    RETVAL = j1l(x);
# else
    RETVAL = j1(x);
# endif
  OUTPUT:
    RETVAL

#endif

#if defined(PSX2008_HAS_JN)
NV
jn(int n, NV x);
  CODE:
# if defined(PSX2008_HAS_SQRTQ)
    RETVAL = jnq(n, x);
# elif defined(PSX2008_HAS_SQRTL) && !defined(__MINGW32__)
    RETVAL = jnl(n, x);
# else
    RETVAL = jn(n, x);
# endif
  OUTPUT:
    RETVAL

#endif

#if defined(PSX2008_HAS_LDEXP)
NV
ldexp(NV x, int exp);
  CODE:
# if defined(PSX2008_HAS_SQRTQ)
    RETVAL = ldexpq(x, exp);
# elif defined(PSX2008_HAS_SQRTL)
    RETVAL = ldexpl(x, exp);
# else
    RETVAL = ldexp(x, exp);
# endif
  OUTPUT:
    RETVAL

#endif

#ifdef PSX2008_HAS_LGAMMA
NV
lgamma(NV x);
  CODE:
# if defined(PSX2008_HAS_SQRTQ)
    RETVAL = lgammaq(x);
# elif defined(PSX2008_HAS_SQRTL)
    RETVAL = lgammal(x);
# else
    RETVAL = lgamma(x);
# endif
  OUTPUT:
    RETVAL

#endif

#ifdef PSX2008_HAS_LOG
NV
log(NV x);
  CODE:
# if defined(PSX2008_HAS_SQRTQ)
    RETVAL = logq(x);
# elif defined(PSX2008_HAS_SQRTL)
    RETVAL = logl(x);
# else
    RETVAL = log(x);
# endif
  OUTPUT:
    RETVAL

#endif

#ifdef PSX2008_HAS_LOG10
NV
log10(NV x);
  CODE:
# if defined(PSX2008_HAS_SQRTQ)
    RETVAL = log10q(x);
# elif defined(PSX2008_HAS_SQRTL)
    RETVAL = log10l(x);
# else
    RETVAL = log10(x);
# endif
  OUTPUT:
    RETVAL

#endif

#ifdef PSX2008_HAS_LOG1P
NV
log1p(NV x);
  CODE:
# if defined(PSX2008_HAS_SQRTQ)
    RETVAL = log1pq(x);
# elif defined(PSX2008_HAS_SQRTL)
    RETVAL = log1pl(x);
# else
    RETVAL = log1p(x);
# endif
  OUTPUT:
    RETVAL

#endif

#ifdef PSX2008_HAS_LOG2
NV
log2(NV x);
  CODE:
# if defined(PSX2008_HAS_SQRTQ)
    RETVAL = log2q(x);
# elif defined(PSX2008_HAS_SQRTL)
    RETVAL = log2l(x);
# else
    RETVAL = log2(x);
# endif
  OUTPUT:
    RETVAL

#endif

#if defined(PSX2008_HAS_LOGB) && (!defined(USE_QUADMATH) || defined(PSX2008_HAS_LOGBQ))
NV
logb(NV x);
  CODE:
# if defined(PSX2008_HAS_LOGBQ)
    RETVAL = logbq(x);
# elif defined(PSX2008_HAS_SQRTL)
    RETVAL = logbl(x);
# else
    RETVAL = logb(x);
# endif
  OUTPUT:
    RETVAL

#endif

#ifdef PSX2008_HAS_LRINT
void
lrint(NV x);
  PPCODE:
  {
# if defined(PSX2008_HAS_LLRINTQ)
    long long ret = llrintq(x);
# elif defined(PSX2008_HAS_LRINTQ)
    long ret = lrintq(x);
# elif defined(PSX2008_HAS_LLRINTL)
    long long ret = llrintl(x);
# elif defined(PSX2008_HAS_LRINTL)
    long ret = lrintl(x);
# elif defined(PSX2008_HAS_LLRINT)
    long long ret = llrint(x);
# else
    long ret = lrint(x);
# endif
    PUSH_INT_OR_PV(ret);
  }

#endif

#ifdef PSX2008_HAS_LROUND
void
lround(NV x);
  PPCODE:
  {
# if defined(PSX2008_HAS_LLROUNDQ)
    long long ret = llroundq(x);
# elif defined(PSX2008_HAS_LROUNDQ)
    long ret = lroundq(x);
# elif defined(PSX2008_HAS_LLROUNDL)
    long long ret = llroundl(x);
# elif defined(PSX2008_HAS_LROUNDL)
    long ret = lroundl(x);
# elif defined(PSX2008_HAS_LLROUND)
    long long ret = llround(x);
# else
    long ret = lround(x);
# endif
    PUSH_INT_OR_PV(ret);
  }

#endif

#ifdef PSX2008_HAS_NEARBYINT
NV
nearbyint(NV x);
  CODE:
# if defined(PSX2008_HAS_SQRTQ)
    RETVAL = nearbyintq(x);
# elif defined(PSX2008_HAS_SQRTL)
    RETVAL = nearbyintl(x);
# else
    RETVAL = nearbyint(x);
# endif
  OUTPUT:
    RETVAL

#endif

#ifdef PSX2008_HAS_NEXTAFTER
NV
nextafter(NV x, NV y);
  CODE:
# if defined(PSX2008_HAS_SQRTQ)
    RETVAL = nextafterq(x, y);
# elif defined(PSX2008_HAS_SQRTL)
    RETVAL = nextafterl(x, y);
# else
    RETVAL = nextafter(x, y);
# endif
  OUTPUT:
    RETVAL

#endif

#if defined(PSX2008_HAS_NEXTTOWARD) && (!defined(USE_QUADMATH) || defined(PSX2008_HAS_NEXTTOWARDQ))
NV
nexttoward(NV x, NV y);
  CODE:
# if defined(PSX2008_HAS_NEXTTOWARDQ)
    RETVAL = nexttowardq(x, y);
# elif defined(PSX2008_HAS_SQRTL)
    RETVAL = nexttowardl(x, y);
# else
    RETVAL = nexttoward(x, y);
# endif
  OUTPUT:
    RETVAL

#endif

#ifdef PSX2008_HAS_POW
NV
pow(NV x, NV y);
  CODE:
# if defined(PSX2008_HAS_SQRTQ)
    RETVAL = powq(x, y);
# elif defined(PSX2008_HAS_SQRTL)
    RETVAL = powl(x, y);
# else
    RETVAL = pow(x, y);
# endif
  OUTPUT:
    RETVAL

#endif

#ifdef PSX2008_HAS_REMAINDER
void
remainder(NV x, NV y);
  INIT:
    NV res;
  PPCODE:
  {
# if defined(PSX2008_HAS_SQRTQ)
    res = remainderq(x, y);
# elif defined(PSX2008_HAS_SQRTL)
    res = remainderl(x, y);
# else
    res = remainder(x, y);
# endif
    mPUSHs(newSVnv(res));
  }

#endif

#ifdef PSX2008_HAS_REMQUO
void
remquo(NV x, NV y);
  INIT:
    int quo;
    NV res;
  PPCODE:
  {
# if defined(PSX2008_HAS_SQRTQ)
    res = remquoq(x, y, &quo);
# elif defined(PSX2008_HAS_SQRTL)
    res = remquol(x, y, &quo);
# else
    res = remquo(x, y, &quo);
# endif
    mPUSHs(newSVnv(res));
    mPUSHs(newSViv(quo));
  }

#endif

#ifdef PSX2008_HAS_RINT
NV
rint(NV x);
  CODE:
  {
# if defined(PSX2008_HAS_SQRTQ)
    RETVAL = rintq(x);
# elif defined(PSX2008_HAS_SQRTL)
    RETVAL = rintl(x);
# else
    RETVAL = rint(x);
# endif
  }
  OUTPUT:
    RETVAL

#endif

#ifdef PSX2008_HAS_ROUND
NV
round(NV x);
  CODE:
# if defined(PSX2008_HAS_SQRTQ)
    RETVAL = roundq(x);
# elif defined(PSX2008_HAS_SQRTL)
    RETVAL = roundl(x);
# else
    RETVAL = round(x);
# endif
  OUTPUT:
    RETVAL

#endif

#ifdef PSX2008_HAS_SCALBN
NV
scalbn(NV x, IV n);
  CODE:
# if defined(PSX2008_HAS_SCALBLNQ)
    RETVAL = scalblnq(x, (long)n);
# elif defined(PSX2008_HAS_SCALBNQ)
    RETVAL = scalbnq(x, (int)n);
# elif defined(PSX2008_HAS_SCALBLNL)
    RETVAL = scalblnl(x, (long)n);
# elif defined(PSX2008_HAS_SCALBNL)
    RETVAL = scalbnl(x, (int)n);
# elif defined(PSX2008_HAS_SCALBLN)
    RETVAL = scalbln(x, (long)n);
# else
    RETVAL = scalbn(x, (int)n);
# endif
  OUTPUT:
    RETVAL

#endif

#ifdef PSX2008_HAS_SIGNBIT
NV
signbit(NV x);
  CODE:
# if defined(PSX2008_HAS_SQRTQ)
    RETVAL = signbitq(x);
# else
    RETVAL = signbit(x);
# endif
  OUTPUT:
    RETVAL

#endif

#ifdef PSX2008_HAS_SIN
NV
sin(NV x);
  CODE:
# if defined(PSX2008_HAS_SQRTQ)
    RETVAL = sinq(x);
# elif defined(PSX2008_HAS_SQRTL)
    RETVAL = sinl(x);
# else
    RETVAL = sin(x);
# endif
  OUTPUT:
    RETVAL

#endif

#ifdef PSX2008_HAS_SINH
NV
sinh(NV x);
  CODE:
# if defined(PSX2008_HAS_SQRTQ)
    RETVAL = sinhq(x);
# elif defined(PSX2008_HAS_SQRTL)
    RETVAL = sinhl(x);
# else
    RETVAL = sinh(x);
# endif
  OUTPUT:
    RETVAL

#endif

#ifdef PSX2008_HAS_SQRT
NV
sqrt(NV x);
  CODE:
# if defined(PSX2008_HAS_SQRTQ)
    RETVAL = sqrtq(x);
# elif defined(PSX2008_HAS_SQRTL)
    RETVAL = sqrtl(x);
# else
    RETVAL = sqrt(x);
# endif
  OUTPUT:
    RETVAL

#endif

#ifdef PSX2008_HAS_TAN
NV
tan(NV x);
  CODE:
# if defined(PSX2008_HAS_SQRTQ)
    RETVAL = tanq(x);
# elif defined(PSX2008_HAS_SQRTL)
    RETVAL = tanl(x);
# else
    RETVAL = tan(x);
# endif
  OUTPUT:
    RETVAL

#endif

#ifdef PSX2008_HAS_TANH
NV
tanh(NV x);
  CODE:
# if defined(PSX2008_HAS_SQRTQ)
    RETVAL = tanhq(x);
# elif defined(PSX2008_HAS_SQRTL)
    RETVAL = tanhl(x);
# else
    RETVAL = tanh(x);
# endif
  OUTPUT:
    RETVAL

#endif

#ifdef PSX2008_HAS_TGAMMA
NV
tgamma(NV x);
  CODE:
# if defined(PSX2008_HAS_SQRTQ)
    RETVAL = tgammaq(x);
# elif defined(PSX2008_HAS_SQRTL)
    RETVAL = tgammal(x);
# else
    RETVAL = tgamma(x);
# endif
  OUTPUT:
    RETVAL

#endif

#ifdef PSX2008_HAS_TRUNC
NV
trunc(NV x);
  CODE:
# if defined(PSX2008_HAS_SQRTQ)
    RETVAL = truncq(x);
# elif defined(PSX2008_HAS_SQRTL)
    RETVAL = truncl(x);
# else
    RETVAL = trunc(x);
# endif
  OUTPUT:
    RETVAL

#endif

#ifdef PSX2008_HAS_Y0
NV
y0(NV x);
  CODE:
# if defined(PSX2008_HAS_SQRTQ)
    RETVAL = y0q(x);
# elif defined(PSX2008_HAS_SQRTL) && !defined(__MINGW32__)
    RETVAL = y0l(x);
# else
    RETVAL = y0(x);
# endif
  OUTPUT:
    RETVAL

#endif

#ifdef PSX2008_HAS_Y1
NV
y1(NV x);
  CODE:
# if defined(PSX2008_HAS_SQRTQ)
    RETVAL = y1q(x);
# elif defined(PSX2008_HAS_SQRTL) && !defined(__MINGW32__)
    RETVAL = y1l(x);
# else
    RETVAL = y1(x);
# endif
  OUTPUT:
    RETVAL

#endif

#if defined(PSX2008_HAS_YN)
NV
yn(int n, NV x);
  CODE:
# if defined(PSX2008_HAS_SQRTQ)
    RETVAL = ynq(n, x);
# elif defined(PSX2008_HAS_SQRTL) && !defined(__MINGW32__)
    RETVAL = ynl(n, x);
# else
    RETVAL = yn(n, x);
# endif
  OUTPUT:
    RETVAL

#endif

 ## Complex arithmetic functions
 ###############################

#ifdef PSX2008_HAS_CABS
NV
cabs(NV re, NV im);
  INIT:
    PSX2008_COMPLEX_T z;
    COMPLEX_FROM_RE_IM(z, re, im);
  CODE:
# if defined(PSX2008_HAS_CSQRTQ)
    RETVAL = cabsq(z);
# elif defined(PSX2008_HAS_CSQRTL)
    RETVAL = cabsl(z);
# else
    RETVAL = cabs(z);
# endif
  OUTPUT:
    RETVAL

#endif

#ifdef PSX2008_HAS_CARG
NV
carg(NV re, NV im);
  INIT:
    PSX2008_COMPLEX_T z;
    COMPLEX_FROM_RE_IM(z, re, im);
  CODE:
# if defined(PSX2008_HAS_CSQRTQ)
    RETVAL = cargq(z);
# elif defined(PSX2008_HAS_CSQRTL)
    RETVAL = cargl(z);
# else
    RETVAL = carg(z);
# endif
  OUTPUT:
    RETVAL

#endif

#ifdef PSX2008_HAS_CIMAG
NV
cimag(NV re, NV im);
  INIT:
    PSX2008_COMPLEX_T z;
    COMPLEX_FROM_RE_IM(z, re, im);
  CODE:
# if defined(PSX2008_HAS_CSQRTQ)
    RETVAL = cimagq(z);
# elif defined(PSX2008_HAS_CSQRTL)
    RETVAL = cimagl(z);
# else
    RETVAL = cimag(z);
# endif
  OUTPUT:
    RETVAL

#endif

#ifdef PSX2008_HAS_CPROJ
void
cproj(NV re, NV im);
  INIT:
    PSX2008_COMPLEX_T result;
    PSX2008_COMPLEX_T z;
    COMPLEX_FROM_RE_IM(z, re, im);
  PPCODE:
# if defined(PSX2008_HAS_CSQRTQ)
    result = cprojq(z);
# elif defined(PSX2008_HAS_CSQRTL)
    result = cprojl(z);
# else
    result = cproj(z);
# endif
    RETURN_COMPLEX(result);

#endif

#ifdef PSX2008_HAS_CREAL
NV
creal(NV re, NV im);
  INIT:
    PSX2008_COMPLEX_T z;
    COMPLEX_FROM_RE_IM(z, re, im);
  CODE:
# if defined(PSX2008_HAS_CSQRTQ)
    RETVAL = crealq(z);
# elif defined(PSX2008_HAS_CSQRTL)
    RETVAL = creall(z);
# else
    RETVAL = creal(z);
# endif
  OUTPUT:
    RETVAL

#endif

#ifdef PSX2008_HAS_CEXP
void
cexp(NV re, NV im);
  INIT:
    PSX2008_COMPLEX_T result;
    PSX2008_COMPLEX_T z;
    COMPLEX_FROM_RE_IM(z, re, im);
  PPCODE:
# if defined(PSX2008_HAS_CSQRTQ)
    result = cexpq(z);
# elif defined(PSX2008_HAS_CSQRTL)
    result = cexpl(z);
# else
    result = cexp(z);
# endif
    RETURN_COMPLEX(result);

#endif

#ifdef PSX2008_HAS_CLOG
void
clog(NV re, NV im);
  INIT:
    PSX2008_COMPLEX_T result;
    PSX2008_COMPLEX_T z;
    COMPLEX_FROM_RE_IM(z, re, im);
  PPCODE:
# if defined(PSX2008_HAS_CSQRTQ)
    result = clogq(z);
# elif defined(PSX2008_HAS_CSQRTL)
    result = clogl(z);
# else
    result = clog(z);
# endif
    RETURN_COMPLEX(result);

#endif

#ifdef PSX2008_HAS_CONJ
void
conj(NV re, NV im);
  INIT:
    PSX2008_COMPLEX_T result;
    PSX2008_COMPLEX_T z;
    COMPLEX_FROM_RE_IM(z, re, im);
  PPCODE:
# if defined(PSX2008_HAS_CSQRTQ)
    result = conjq(z);
# elif defined(PSX2008_HAS_CSQRTL)
    result = conjl(z);
# else
    result = conj(z);
# endif
    RETURN_COMPLEX(result);

#endif

#ifdef PSX2008_HAS_CPOW
void
cpow(NV re_x, NV im_x, NV re_y, NV im_y);
  INIT:
    PSX2008_COMPLEX_T result;
    PSX2008_COMPLEX_T x, y;
    COMPLEX_FROM_RE_IM(x, re_x, im_x);
    COMPLEX_FROM_RE_IM(y, re_y, im_y);
  PPCODE:
# if defined(PSX2008_HAS_CSQRTQ)
    result = cpowq(x, y);
# elif defined(PSX2008_HAS_CSQRTL)
    result = cpowl(x, y);
# else
    result = cpow(x, y);
# endif
    RETURN_COMPLEX(result);

#endif

#ifdef PSX2008_HAS_CSQRT
void
csqrt(NV re, NV im);
  INIT:
    PSX2008_COMPLEX_T result;
    PSX2008_COMPLEX_T z;
    COMPLEX_FROM_RE_IM(z, re, im);
  PPCODE:
# if defined(PSX2008_HAS_CSQRTQ)
    result = csqrtq(z);
# elif defined(PSX2008_HAS_CSQRTL)
    result = csqrtl(z);
# else
    result = csqrt(z);
# endif
    RETURN_COMPLEX(result);

#endif

#ifdef PSX2008_HAS_CACOS
void
cacos(NV re, NV im);
  INIT:
    PSX2008_COMPLEX_T result;
    PSX2008_COMPLEX_T z;
    COMPLEX_FROM_RE_IM(z, re, im);
  PPCODE:
# if defined(PSX2008_HAS_CSQRTQ)
    result = cacosq(z);
# elif defined(PSX2008_HAS_CSQRTL)
    result = cacosl(z);
# else
    result = cacos(z);
# endif
    RETURN_COMPLEX(result);

#endif

#ifdef PSX2008_HAS_CACOSH
void
cacosh(NV re, NV im);
  INIT:
    PSX2008_COMPLEX_T result;
    PSX2008_COMPLEX_T z;
    COMPLEX_FROM_RE_IM(z, re, im);
  PPCODE:
# if defined(PSX2008_HAS_CSQRTQ)
    result = cacoshq(z);
# elif defined(PSX2008_HAS_CSQRTL)
    result = cacoshl(z);
# else
    result = cacosh(z);
# endif
    RETURN_COMPLEX(result);

#endif

#ifdef PSX2008_HAS_CASIN
void
casin(NV re, NV im);
  INIT:
    PSX2008_COMPLEX_T result;
    PSX2008_COMPLEX_T z;
    COMPLEX_FROM_RE_IM(z, re, im);
  PPCODE:
# if defined(PSX2008_HAS_CSQRTQ)
    result = casinq(z);
# elif defined(PSX2008_HAS_CSQRTL)
    result = casinl(z);
# else
    result = casin(z);
# endif
    RETURN_COMPLEX(result);

#endif

#ifdef PSX2008_HAS_CASINH
void
casinh(NV re, NV im);
  INIT:
    PSX2008_COMPLEX_T result;
    PSX2008_COMPLEX_T z;
    COMPLEX_FROM_RE_IM(z, re, im);
  PPCODE:
# if defined(PSX2008_HAS_CSQRTQ)
    result = casinhq(z);
# elif defined(PSX2008_HAS_CSQRTL)
    result = casinhl(z);
# else
    result = casinh(z);
# endif
    RETURN_COMPLEX(result);

#endif

#ifdef PSX2008_HAS_CATAN
void
catan(NV re, NV im);
  INIT:
    PSX2008_COMPLEX_T result;
    PSX2008_COMPLEX_T z;
    COMPLEX_FROM_RE_IM(z, re, im);
  PPCODE:
# if defined(PSX2008_HAS_CSQRTQ)
    result = catanq(z);
# elif defined(PSX2008_HAS_CSQRTL)
    result = catanl(z);
# else
    result = catan(z);
# endif
    RETURN_COMPLEX(result);

#endif

#ifdef PSX2008_HAS_CATANH
void
catanh(NV re, NV im);
  INIT:
    PSX2008_COMPLEX_T result;
    PSX2008_COMPLEX_T z;
    COMPLEX_FROM_RE_IM(z, re, im);
  PPCODE:
# if defined(PSX2008_HAS_CSQRTQ)
    result = catanhq(z);
# elif defined(PSX2008_HAS_CSQRTL)
    result = catanhl(z);
# else
    result = catanh(z);
# endif
    RETURN_COMPLEX(result);

#endif

#ifdef PSX2008_HAS_CCOS
void
ccos(NV re, NV im);
  INIT:
    PSX2008_COMPLEX_T result;
    PSX2008_COMPLEX_T z;
    COMPLEX_FROM_RE_IM(z, re, im);
  PPCODE:
# if defined(PSX2008_HAS_CSQRTQ)
    result = ccosq(z);
# elif defined(PSX2008_HAS_CSQRTL)
    result = ccosl(z);
# else
    result = ccos(z);
# endif
    RETURN_COMPLEX(result);

#endif

#ifdef PSX2008_HAS_CCOSH
void
ccosh(NV re, NV im);
  INIT:
    PSX2008_COMPLEX_T result;
    PSX2008_COMPLEX_T z;
    COMPLEX_FROM_RE_IM(z, re, im);
  PPCODE:
# if defined(PSX2008_HAS_CSQRTQ)
    result = ccoshq(z);
# elif defined(PSX2008_HAS_CSQRTL)
    result = ccoshl(z);
# else
    result = ccosh(z);
# endif
    RETURN_COMPLEX(result);

#endif

#ifdef PSX2008_HAS_CSIN
void
csin(NV re, NV im);
  INIT:
    PSX2008_COMPLEX_T result;
    PSX2008_COMPLEX_T z;
    COMPLEX_FROM_RE_IM(z, re, im);
  PPCODE:
# if defined(PSX2008_HAS_CSQRTQ)
    result = csinq(z);
# elif defined(PSX2008_HAS_CSQRTL)
    result = csinl(z);
# else
    result = csin(z);
# endif
    RETURN_COMPLEX(result);

#endif

#ifdef PSX2008_HAS_CSINH
void
csinh(NV re, NV im);
  INIT:
    PSX2008_COMPLEX_T result;
    PSX2008_COMPLEX_T z;
    COMPLEX_FROM_RE_IM(z, re, im);
  PPCODE:
# if defined(PSX2008_HAS_CSQRTQ)
    result = csinhq(z);
# elif defined(PSX2008_HAS_CSQRTL)
    result = csinhl(z);
# else
    result = csinh(z);
# endif
    RETURN_COMPLEX(result);

#endif

#ifdef PSX2008_HAS_CTAN
void
ctan(NV re, NV im);
  INIT:
    PSX2008_COMPLEX_T result;
    PSX2008_COMPLEX_T z;
    COMPLEX_FROM_RE_IM(z, re, im);
  PPCODE:
# if defined(PSX2008_HAS_CSQRTQ)
    result = ctanq(z);
# elif defined(PSX2008_HAS_CSQRTL)
    result = ctanl(z);
# else
    result = ctan(z);
# endif
    RETURN_COMPLEX(result);

#endif

#ifdef PSX2008_HAS_CTANH
void
ctanh(NV re, NV im);
  INIT:
    PSX2008_COMPLEX_T result;
    PSX2008_COMPLEX_T z;
    COMPLEX_FROM_RE_IM(z, re, im);
  PPCODE:
# if defined(PSX2008_HAS_CSQRTQ)
    result = ctanhq(z);
# elif defined(PSX2008_HAS_CSQRTL)
    result = ctanhl(z);
# else
    result = ctanh(z);
# endif
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
