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
#if defined(I_UNISTD) || defined(_WIN32)
#include <unistd.h>
#endif
#ifdef PSX2008_HAS_UTMPX_H
#include <utmpx.h>
#endif

#if defined(__linux__) && defined(PSX2008_HAS_OPENAT2)
#include <sys/syscall.h>
#include <linux/openat2.h>
#endif

#include "const-c.inc"

#ifdef I64TYPE
#define INT_MAX_TYPE I64TYPE
#define UINT_MAX_TYPE U64TYPE
#else
#define INT_MAX_TYPE I32TYPE
#define UINT_MAX_TYPE U32TYPE
#endif

#if PERL_VERSION_GE(5,8,5)
# define psx_looks_like_number(sv) looks_like_number(sv)
#else
# define psx_looks_like_number(sv)                      \
  (                                                     \
    (SvPOK(sv) || SvPOKp(sv))                           \
    ? looks_like_number(sv)                             \
    : (SvFLAGS(sv) & (SVf_NOK|SVp_NOK|SVf_IOK|SVp_IOK)) \
  )
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

#if defined(PSX2008_HAS_SCALBLN)
#define PSX2008_SCALBN(x, n) scalbln(x, n)
#elif defined(PSX2008_HAS_SCALBN)
#define PSX2008_SCALBN(x, n) scalbn(x, n)
#endif

#if defined(AT_FDCWD) ||                   \
  defined(PSX2008_HAS_CHDIR) ||            \
  defined(PSX2008_HAS_CHMOD) ||            \
  defined(PSX2008_HAS_CHOWN) ||            \
  defined(PSX2008_HAS_FDATASYNC) ||        \
  defined(PSX2008_HAS_FDOPEN) ||           \
  defined(PSX2008_HAS_FDOPENDIR) ||        \
  defined(PSX2008_HAS_FSYNC) ||            \
  defined(PSX2008_HAS_FUTIMENS) ||         \
  defined(PSX2008_HAS_ISATTY) ||           \
  defined(PSX2008_HAS_POSIX_FADVISE) ||    \
  defined(PSX2008_HAS_POSIX_FALLOCATE) ||  \
  defined(PSX2008_HAS_PTSNAME) ||          \
  defined(PSX2008_HAS_READ) ||             \
  defined(PSX2008_HAS_STAT) ||             \
  defined(PSX2008_HAS_TRUNCATE) ||         \
  defined(PSX2008_HAS_TTYNAME) ||          \
  defined(PSX2008_HAS_WRITE)
#define PSX2008_NEED_PSX_FILENO
#endif

#define RETURN_COMPLEX(z) { \
    EXTEND(SP, 2);          \
    mPUSHn(creal(z));       \
    mPUSHn(cimag(z));       \
}

typedef IV SysRet; /* returns -1 as undef, 0 as "0 but true", other unchanged */
typedef IV SysRet0; /* returns -1 as undef, other unchanged */
typedef IV SysRetTrue; /* returns 0 as "0 but true", undef otherwise */
typedef int psx_fd_t; /* checks for file handle or descriptor via typemap */

/* Round up l to the next multiple of PERL_STRLEN_ROUNDUP_QUANTUM even if it
 * already is a multiple so that we always have room for a trailing '\0'. +1
 * does the trick. */
#define TopUpLEN(l) ((l)+1 < (l) ? (croak_memory_wrap(),0) : PERL_STRLEN_ROUNDUP((l)+1))

/* Treat omitted and explicitly undef arguments as if intended by the caller
 * to avoid annoying "uninitialized" warnings. */
#define SvUNDEF_purposely(sv) (!(sv) || (sv) == &PL_sv_undef)

#define SvNEGATIVE(sv) _psx_sv_negative(aTHX_ sv)

#if IVSIZE < Off_t_size
#define SvOFFt(sv) ((Off_t)SvNV(sv))
#else
#define SvOFFt(sv) ((Off_t)SvIV(sv))
#endif

#if IVSIZE < Size_t_size
#define SvSIZEt(sv) ((Size_t)SvNV(sv))
#else
#define SvSIZEt(sv) ((Size_t)SvUV(sv))
#endif

#define SvSTRLEN(sv) (IVSIZE < sizeof(STRLEN) ? (STRLEN)SvNV(sv) : (STRLEN)SvUV(sv))

/* From perldoc perlguts. */
#if PERL_VERSION_GE(5,18,0)
# define SvTRULYREADONLY(sv) SvREADONLY(sv)
#else
# define SvTRULYREADONLY(sv) (SvREADONLY(sv) && !SvIsCOW(sv))
#endif

static int
_psx_sv_negative(pTHX_ SV *sv)
{
  if (!sv)
    return 0;
  SvGETMAGIC(sv);
  if (!SvOK(sv))
    return 0;
  if (SvIOK(sv))
    return !SvIsUV(sv) && SvIVX(sv) < 0;
  if (SvNOK(sv))
    return SvNVX(sv) < 0;
  if (SvPOK(sv))
    return (psx_looks_like_number(sv) & IS_NUMBER_NEG) != 0;
  return 0;
}

/* strnlen() shamelessly plagiarized from dietlibc (https://www.fefe.de/) */
#if !defined(PSX2008_HAS_STRNLEN)
static STRLEN
strnlen(const char *s, STRLEN maxlen)
{
  const char *n = memchr(s, 0, maxlen);
  if (!n)
    n = s + maxlen;
  return n - s;
}
#endif

/* _fmt_uint() shamelessly plagiarized from libowfat (https://www.fefe.de/) */
static UV
_fmt_uint(char *dest, UINT_MAX_TYPE u)
{
  UV len, len2;
  UINT_MAX_TYPE tmp;
  /* count digits */
  for (len=1, tmp=u; tmp>9; ++len)
    tmp /= 10;
  if (dest)
    for (tmp=u, dest+=len, len2=len+1; --len2; tmp/=10)
      *--dest = (char)((tmp%10)+'0');
  return len;
}

static UV
_fmt_neg_int(char *dest, INT_MAX_TYPE i)
{
  if (dest)
    *dest++ = '-';
  return _fmt_uint(dest, (UINT_MAX_TYPE)(-(i+1))+1) + 1;
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
#define PUSH_INT_OR_PV(int_val) STMT_START {                \
    SV *_piop_tmp_sv;                                       \
    CLANG_DIAG_IGNORE_STMT(-Wtautological-compare);         \
    GCC_DIAG_IGNORE_STMT(-Wtype-limits);                    \
    if ((int_val) < 0) {                                    \
      if ((int_val) >= IV_MIN)                              \
        _piop_tmp_sv = newSViv(int_val);                    \
      else {                                                \
        char _piop_buf[24];                                 \
        UV _piop_len = _fmt_neg_int(_piop_buf, (int_val));  \
        _piop_tmp_sv = newSVpvn(_piop_buf, _piop_len);      \
      }                                                     \
    }                                                       \
    else if ((int_val) <= UV_MAX)                           \
      _piop_tmp_sv = newSVuv(int_val);                      \
    else {                                                  \
      char _piop_buf[24];                                   \
      UV _piop_len = _fmt_uint(_piop_buf, (int_val));       \
      _piop_tmp_sv = newSVpvn(_piop_buf, _piop_len);        \
    }                                                       \
    GCC_DIAG_RESTORE_STMT;                                  \
    CLANG_DIAG_RESTORE_STMT;                                \
    mPUSHs(_piop_tmp_sv);                                   \
  } STMT_END

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
#elif defined PSX2008_HAS_ST_ATIMENSEC
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
        PUSHs(boolSV(rv == 0));                 \
        break;                                  \
      case G_LIST:                              \
        if (rv == 0) {                          \
          EXTEND(SP, 16);                       \
          SP = _push_stat_buf(aTHX_ SP, &buf);  \
        }                                       \
    }                                           \
} STMT_END

#if defined(PSX2008_HAS_EXECVEAT) || defined(PSX2008_HAS_FEXECVE)
/* We don't check for '\0' or '=' within args or env. Not our business. */
static void
_execve50c(pTHX_ int fd, const char *path, AV *args, SV *envsv, int flags)
{
  HV *envhv;
  Size_t argc, n;
  char **argv, **envp;
  char *empty_env[] = { NULL };
  const char *const func = path ? "execveat" : "fexecve";

# ifndef PSX2008_HAS_EXECVEAT
  if (path) { errno = ENOSYS; return; }
# endif
# ifndef PSX2008_HAS_FEXECVE
  if (!path) { errno = ENOSYS; return; }
# endif

  if (SvUNDEF_purposely(envsv))
    envhv = NULL;
  else {
    SvGETMAGIC(envsv);
    if (SvROK(envsv) && SvTYPE(SvRV(envsv)) == SVt_PVHV)
      envhv = (HV*)SvRV(envsv);
    else
      croak("%s::%s: 'env' is not a HASH reference: %" SVf,
           PACKNAME, func, SVfARG(envsv));
  }

  /* Allocate memory for argv pointers; +1 for terminating NULL pointer. */
  argc = av_count(args);
  if (UNLIKELY(argc+1 == 0))
    --argc;
  if (UNLIKELY((argc+1)*sizeof(char*)/sizeof(char*) != (argc+1)))
    goto e2big;
  argv = safemalloc((argc+1)*sizeof(char*));
  SAVEFREEPV(argv);

  /* Build argv string array from args array ref. */
  for (n = 0; n < argc; n++) {
    SV **argsv = av_fetch(args, n, 0);
    if (!argsv)
      argv[n] = "";
    else {
      STRLEN cur;
      (void)SvPV(*argsv, cur);
      if (LIKELY(cur+1)) {
        /* +1 for final '\0' to be on the safe side. */
        char *arg = SvGROW(*argsv, cur+1);
        arg[cur] = '\0';
        argv[n] = arg;
      }
      else
        goto e2big;
    }
  }
  argv[argc] = NULL;

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

    /* Allocate and zero-fill memory for envp; +1 for terminating NULL
     * pointer. */
    envp = safecalloc(envc+1, sizeof(char*));
    SAVEFREEPV(envp);

    /* Build envp ("key=value") string array from envhv hash ref. Iterate at
     * most envc times (envhv could be changed in another thread). */
    hv_iterinit(envhv);
    for (n = 0; n < envc; n++) {
      I32 klen;
      char *env_key;
      SV *valsv = hv_iternextsv(envhv, &env_key, &klen);
      if (!valsv) /* envhv shrunk along the way. */
        break;
      else {
        char *env_ent;
        STRLEN env_ent_len, env_val_len;
        /* klen < 0 means "utf8". klen == I32_MIN cannot happen because
         * hash keys cannot be longer than I32_MAX, so -klen is safe. */
        STRLEN env_key_len = klen < 0 ? -klen : klen;
        const char *env_val = SvPV_const(valsv, env_val_len);

        env_ent_len = env_key_len + env_val_len;
        if (UNLIKELY(env_ent_len < env_key_len))
          goto e2big;
        env_ent_len += 2; /* +2 for '=' and terminating NUL byte. */
        if (UNLIKELY(env_ent_len < 2))
          goto e2big;

        envp[n] = env_ent = safemalloc(env_ent_len);
        SAVEFREEPV(env_ent);
        env_ent[env_ent_len-1] = '\0';
        env_ent[env_key_len] = '=';
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
    errno = ENOSYS;
# endif
  }
  else {
# ifdef PSX2008_HAS_FEXECVE
    fexecve(fd, (char *const *)argv, (char *const *)envp);
# else
    errno = ENOSYS;
# endif
  }
  return;

 e2big:
  errno = E2BIG;
}
#endif

#ifdef PSX2008_HAS_READLINK
static SV *
_readlink50c(pTHX_ const char *path, const int *dirfdp)
{
  /*
   * CORE::readlink() is broken because it uses a fixed-size result buffer of
   * PATH_MAX bytes (the manpage explicitly advises against this). We use a
   * dynamically growing buffer instead, leaving it up to the file system how
   * long a symlink may be.
   */
  size_t bufsize = 1023; /* This should be enough in most cases to read the
                          * link in one go. */
  ssize_t rv;
  char *buf;

  /* If available, we use readlinkat() with AT_FDCWD instead of readlink() to
   * avoid a branch in the loop. */
#ifdef PSX2008_HAS_READLINKAT
  /* Cast AT_FDCWD to cope with Solaris 0xffd19553 artwork. */
  int dirfd = dirfdp ? *dirfdp : (int)AT_FDCWD;
#else
  if (dirfdp != NULL) {
    errno = ENOSYS;
    return NULL;
  }
#endif

  buf = NULL;  /* Makes saferealloc() act like safemalloc() the first time. */
  while (1) {
    buf = saferealloc(buf, bufsize);
    if (buf == NULL) {
      errno = ENOMEM;
      return NULL;
    }

#ifdef PSX2008_HAS_READLINKAT
    rv = readlinkat(dirfd, path, buf, bufsize);
#else
    rv = readlink(path, buf, bufsize);
#endif

    if (LIKELY(rv != -1)) {
      size_t linklen = (size_t)rv;
      if (UNLIKELY((STRLEN)linklen != linklen))
        goto MicrosoftMustDie;
      if (LIKELY(linklen < bufsize)) {
        buf[linklen] = '\0';
        SAVEFREEPV(buf);
        return newSVpvn_flags(buf, linklen, SVs_TEMP);
      }
    }
    else if (errno != ERANGE)
      /* gnulib says, on some systems ERANGE means that bufsize is too small */
      goto FuckTheSkullOfGoogle;

    if (UNLIKELY(bufsize+1 == 0)) {
    MicrosoftMustDie:
      errno = ENAMETOOLONG;
    FuckTheSkullOfGoogle:
      Safefree(buf);
      return NULL;
    }

    bufsize <<= 1;
    bufsize |= 1;
  }
}
#endif

#if defined(PSX2008_HAS_READV) || defined(PSX2008_HAS_PREADV)   \
  || defined(PSX2008_HAS_PREADV2)
static void
_free_iov(const struct iovec *iov, size_t cnt) {
  size_t i;
  if (iov)
    for (i = 0; i < cnt; i++)
      if (iov[i].iov_base)
        Safefree(iov[i].iov_base);
}

static ssize_t
_readv50c(pTHX_ int fd, SV *buffers, AV *sizes, SV *offset_sv, SV *flags_sv)
{
  ssize_t rv;
  Size_t i, iovcnt;
  struct iovec *iov;
  const char *func = flags_sv ? "preadv2" : offset_sv ? "preadv" : "readv";

  /* The prototype for buffers is \[@$] so that we can be called either with
   * @buffers or $buffers. @buffers gives us an array reference. $buffers
   * gives us a reference to a scalar (which in return is hopefully an array
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
        if (!SvOK(buffers)) { /* Turn plain "my $buf" into array ref. */
#if PERL_VERSION_GE(5,35,4)
          sv_setrv_noinc(buffers, (SV*)newAV());
#else
          sv_upgrade(buffers, SVt_IV);
          SvOK_off(buffers);
          SvRV_set(buffers, (SV*)newAV());
          SvROK_on(buffers);
#endif
        }
        continue;
      }
    }
    croak("%s::%s: 'buffers' is not an array or array ref", PACKNAME, func);
  }

  iovcnt = av_count(sizes);
  if (iovcnt > INT_MAX) {
    SETERRNO(EINVAL, LIB_INVARG);
    return -1;
  }

  iov = safecalloc(iovcnt, sizeof(struct iovec));
  if (!iov && iovcnt) {
    errno = ENOMEM;
    return -1;
  }
  SAVEFREEPV(iov);

  for (i = 0; i < iovcnt; i++) {
    STRLEN iov_len;
    void *iov_base;
    SV **size = av_fetch(sizes, i, 0);
    if (!size)
      continue;
    if (UNLIKELY(SvNEGATIVE(*size))) { /* Performs 'get' magic. */
      _free_iov(iov, i);
      croak("%s::%s: Can't handle negative count: sizes[%" UVuf "] = %" SVf,
            PACKNAME, func, (UV)i, SVfARG(*size));
    }
    iov_len = SvSTRLEN(*size);
    if (!iov_len)
      continue;
    if (iov_len > SSIZE_MAX) {
      _free_iov(iov, i);
      SETERRNO(EINVAL, LIB_INVARG);
      return -1;
    }
    iov_base = safemalloc(TopUpLEN(iov_len));
    if (!iov_base) {
      _free_iov(iov, i);
      errno = ENOMEM;
      return -1;
    }
    iov[i].iov_base = iov_base;
    iov[i].iov_len = (Size_t)iov_len;
  }

  if (offset_sv == NULL) {
#ifdef PSX2008_HAS_READV
    rv = readv(fd, iov, iovcnt);
#else
    rv = -1;
    errno = ENOSYS;
#endif
  }
  else if (flags_sv == NULL) {
#ifdef PSX2008_HAS_PREADV
    Off_t offset = SvUNDEF_purposely(offset_sv) ? 0 : SvOFFt(offset_sv);
    rv = preadv(fd, iov, iovcnt, offset);
#else
    rv = -1;
    errno = ENOSYS;
#endif
  }
  else {
#ifdef PSX2008_HAS_PREADV2
    Off_t offset = SvUNDEF_purposely(offset_sv) ? 0 : SvOFFt(offset_sv);
    int flags = SvUNDEF_purposely(flags_sv) ? 0 : (int)SvIV(flags_sv);
    rv = preadv2(fd, iov, iovcnt, offset, flags);
#else
    rv = -1;
    errno = ENOSYS;
#endif
  }

  if (UNLIKELY(rv == -1)) {
    _free_iov(iov, iovcnt);
    return rv;
  }

  av_extend((AV*)buffers, iovcnt);

  {
    SV *tmp_sv;
    size_t sv_len;
    size_t bytes_left = (size_t)rv;
    for (i = 0; i < iovcnt; i++) {
      size_t iov_len = iov[i].iov_len;
      if (bytes_left >= iov_len)
        /* Current buffer filled completely (this includes an empty buffer). */
        sv_len = iov_len;
      else
        /* Current buffer filled partly. */
        sv_len = bytes_left;
      bytes_left -= sv_len;

      tmp_sv = sv_len ? newSV_type(SVt_PV) : newSVpvn("", 0);
      if (!tmp_sv) {
        _free_iov(iov + i, iovcnt - i);
        errno = ENOMEM;
        return -1;
      }

      if (sv_len) {
        char *iov_base = (char*)iov[i].iov_base;
        iov_base[sv_len] = '\0';
        SvPV_set(tmp_sv, iov_base);
        SvCUR_set(tmp_sv, sv_len);
        SvLEN_set(tmp_sv, TopUpLEN(iov_len));
        SvPOK_on(tmp_sv);
        SvTAINTED_on(tmp_sv);
      }

      if (!av_store((AV*)buffers, i, tmp_sv)) {
        SvREFCNT_dec(tmp_sv);
        if (SvMAGICAL(buffers))
          mg_set(tmp_sv);
      }
    }
  }

  return rv;
}
#endif

#ifdef PSX2008_HAS_WRITEV
static int
_psx_av2iov(pTHX_ AV *buffers, struct iovec **iov_dest)
{
  Size_t i, iovcnt;
  struct iovec *iov;

  iovcnt = av_count(buffers);
  if (iovcnt > INT_MAX) {
    SETERRNO(EINVAL, LIB_INVARG);
    return -1;
  }

  iov = safecalloc(iovcnt, sizeof(struct iovec));
  if (!iov && iovcnt) {
    errno = ENOMEM;
    return -1;
  }
  SAVEFREEPV(iov);

  for (i = 0; i < iovcnt; i++) {
    SV **av_elt = av_fetch(buffers, i, 0);
    if (av_elt) {
      STRLEN iov_len;
      iov[i].iov_base = (void*)SvPV(*av_elt, iov_len);
      iov[i].iov_len = (Size_t)iov_len;
      if (iov_len > SSIZE_MAX) {
        SETERRNO(EINVAL, LIB_INVARG);
        return -1;
      }
    }
  }

  *iov_dest = iov;
  return iovcnt;
}
#endif

#ifdef PSX2008_HAS_OPENAT
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
  SV *rv;
  GV *gv;
  int return_handle = 0;

  gv = newGVgen(PACKNAME);
  if (gv) {
    if (mode) {
# ifdef PSX2008_HAS_FDOPEN
      FILE *filep = fdopen(fd, mode);
      if (filep) {
        PerlIO *pio = PerlIO_importFILE(filep, mode);
        if (pio) {
          if (do_open(gv, "+<&", 3, FALSE, 0, 0, pio))
            return_handle = 1;
          else
            PerlIO_releaseFILE(pio, filep);
        }
      }
# else
      errno = ENOSYS;
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
      errno = ENOSYS;
# endif
    }
  }

  if (return_handle) {
    const char *io_class = mode ? "IO::File" : "IO::Dir";
    rv = newRV_inc((SV*)gv);
    rv = sv_bless(rv, gv_stashpv(io_class, 0));
    rv = sv_2mortal(rv);
  }
  else
    rv = NULL;

  /* https://github.com/Perl/perl5/issues/9493 */
  if (gv)
    (void) hv_delete(GvSTASH(gv), GvNAME(gv), GvNAMELEN(gv), G_DISCARD);

  return rv;
}
#endif

#ifdef PSX2008_NEED_PSX_FILENO
static int
_psx_fileno(pTHX_ SV *sv)
{
  IO *io;
  int fn = -1;

  /* On Solaris, AT_FDCWD is 0xffd19553 (4291925331), so don't do any integer
   * range checks, just cast the SvIV to int and may the --force be with you.
   * https://github.com/python/cpython/issues/60169
   */
  if (SvOK(sv)) {
    if (psx_looks_like_number(sv))
      fn = (int)SvIV(sv);
    else if ((io = sv_2io(sv))) {
      /* Magic part taken from Perl 5.8.9's pp_fileno. */
      MAGIC *mg = SvTIED_mg((SV*)io, PERL_MAGIC_tiedscalar);
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
#endif

#ifdef PSX2008_HAS_CLOSE
static int
_psx_close(pTHX_ SV *sv)
{
  IO *io;
  int rv = -1;

  if (!SvOK(sv))
    SETERRNO(EBADF, RMS_IFI);
  else if (psx_looks_like_number(sv))
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
  int got_fd, dir_fd, path_fd;
  struct stat st;

#ifndef PSX2008_HAS_OPENAT2
  if (how_hv != NULL) {
    errno = ENOSYS;
    return NULL;
  }
#endif

  SvGETMAGIC(dirfdsv);
  if (!SvOK(dirfdsv))
    dir_fd = -1;
  else if (SvROK(dirfdsv) && SvTYPE(SvRV(dirfdsv)) == SVt_IV) {
    /* Allow dirfdsv to be a reference to AT_FDCWD to get a file handle
     * instead of a file descriptor. */
    if (SvIV(SvRV(dirfdsv)) != (IV)AT_FDCWD)
      dir_fd = -1;
    else {
      got_fd = 0;
      dir_fd = (int)AT_FDCWD;
    }
  }
  else {
    got_fd = psx_looks_like_number(dirfdsv);
    dir_fd = _psx_fileno(aTHX_ dirfdsv);
  }

  if (dir_fd == -1) {
    SETERRNO(EBADF, RMS_IFI);
    path_fd = -1;
  }
  else if (how_hv == NULL) {  /* openat() */
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
    flags = (int)how.flags; /* Needed for _psx_fd_to_handle() below. */
    path_fd = syscall(SYS_openat2, dir_fd, path, &how, sizeof(how));
  }
#endif

  if (path_fd < 0)
    return NULL;
  else if (got_fd)
    /* If we were passed a file descriptor, return a file descriptor. */
    return sv_2mortal(newSViv((IV)path_fd));
  else if (fstat(path_fd, &st) != 0)
    return NULL;
  else {
    const char *raw = S_ISDIR(st.st_mode) ? NULL : _flags2raw(flags);
    return _psx_fd_to_handle(aTHX_ path_fd, raw);
  }
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
UV
alarm(UV seconds);

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
clock_getcpuclockid(pid_t pid=PerlProc_getpid());
  INIT:
    clockid_t clock_id;
  PPCODE:
    if (LIKELY(clock_getcpuclockid(pid, &clock_id) == 0))
      mPUSHi((IV)clock_id);
    else
      PUSHs(&PL_sv_undef);

#endif

#ifdef PSX2008_HAS_CLOCK_GETRES
void
clock_getres(clockid_t clock_id=CLOCK_REALTIME);
  ALIAS:
    clock_gettime = 1
  INIT:
    int rv;
    struct timespec res;
  PPCODE:
    if (ix == 0)
      rv = clock_getres(clock_id, &res);
    else
      rv = clock_gettime(clock_id, &res);
    if (rv == 0) {
      EXTEND(SP, 2);
      mPUSHi(res.tv_sec);
      mPUSHi(res.tv_nsec);
    }

#endif

#ifdef PSX2008_HAS_CLOCK_SETTIME
void
clock_settime(clockid_t clock_id, time_t sec, long nsec);
  PROTOTYPE: $@
  INIT:
    struct timespec tp = { sec, nsec };
  PPCODE:
    if (clock_settime(clock_id, &tp) == 0)
      mPUSHp("0 but true", 10);
    else
      PUSHs(&PL_sv_undef);

#endif

#define PUSH_NANOSLEEP_REMAIN STMT_START {                  \
    switch (GIMME_V) {                                      \
      case G_SCALAR:                                        \
        mPUSHn(remain.tv_sec + remain.tv_nsec/(NV)1e9);     \
        break;                                              \
      case G_LIST:                                          \
        EXTEND(SP, 2);                                      \
        mPUSHi(remain.tv_sec);                              \
        mPUSHi(remain.tv_nsec);                             \
    }                                                       \
} STMT_END

#ifdef PSX2008_HAS_CLOCK_NANOSLEEP
void
clock_nanosleep(clockid_t clock_id, int flags, time_t sec, long nsec);
  PROTOTYPE: $$@
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
  PROTOTYPE: @
  INIT:
    const struct timespec request = { sec, nsec };
    struct timespec remain = { 0, 0 };
  PPCODE:
    if (nanosleep(&request, &remain) == 0 || errno == EINTR)
      PUSH_NANOSLEEP_REMAIN;

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
      mPUSHi(rv);
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
strptime(const char *s, const char *format, ...);
  PROTOTYPE: $$@
  INIT:
    struct tm tm = {
      INT_MIN, INT_MIN, INT_MIN,
      INT_MIN, INT_MIN, INT_MIN,
      INT_MIN, INT_MIN, INT_MIN,
    };
    char *remainder;
    size_t i, tm_count;
    AV *tm_av = NULL;
    U8 gimme = GIMME_V;
  PPCODE:
  {
    if (items > 2) {
      SV *tm_arg = ST(2l);
      SvGETMAGIC(tm_arg);
      if (SvROK(tm_arg) && SvTYPE(SvRV(tm_arg)) == SVt_PVAV) {
        if (items == 3)
          tm_av = (AV*)SvRV(tm_arg);
        else
          croak("%s::strptime: Unexpected argument after %s", PACKNAME, "tm");
      }
      else if (items > 11)
        croak("%s::strptime: Unexpected argument after %s", PACKNAME, "isdst");
    }

    tm_count = tm_av ? av_count(tm_av) : (size_t)items - 2;
    if (tm_count > 9)
      tm_count = 9;

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
      if (SvOK(tm_sv)) {
        int tm_int = (int)SvIV(tm_sv);
        switch(i) {
          case 0: tm.tm_sec = tm_int; break;
          case 1: tm.tm_min = tm_int; break;
          case 2: tm.tm_hour = tm_int; break;
          case 3: tm.tm_mday = tm_int; break;
          case 4: tm.tm_mon = tm_int; break;
          case 5: tm.tm_year = tm_int; break;
          case 6: tm.tm_wday = tm_int; break;
          case 7: tm.tm_yday = tm_int; break;
          case 8: tm.tm_isdst = tm_int; break;
        }
      }
    }

    remainder = strptime(s, format, &tm);
    if (!remainder) {
      if (gimme == G_SCALAR)
        PUSHs(&PL_sv_undef);
    }
    else {
      if (tm_av) {
        av_extend(tm_av, 8);
        for (i = 0; i < 9; i++) {
          int tm_int;
          switch(i) {
            case 0: tm_int = tm.tm_sec; break;
            case 1: tm_int = tm.tm_min; break;
            case 2: tm_int = tm.tm_hour; break;
            case 3: tm_int = tm.tm_mday; break;
            case 4: tm_int = tm.tm_mon; break;
            case 5: tm_int = tm.tm_year; break;
            case 6: tm_int = tm.tm_wday; break;
            case 7: tm_int = tm.tm_yday; break;
            case 8: tm_int = tm.tm_isdst; break;
          }
          if (tm_int != INT_MIN) {
            SV *tm_sv = newSViv(tm_int);
            if (!av_store((AV*)tm_av, i, tm_sv)) {
              SvREFCNT_dec(tm_sv);
              if (SvMAGICAL(tm_av))
                mg_set(tm_sv);
            }
          }
        }
      }
      switch(gimme) {
        case G_SCALAR: mPUSHs(newSViv(remainder - s)); break;
        case G_LIST: {
          SV *undef = &PL_sv_undef;
          EXTEND(SP, 8);
          for (i = 0; i < 9; i++) {
            int tm_int;
            switch(i) {
              case 0: tm_int = tm.tm_sec; break;
              case 1: tm_int = tm.tm_min; break;
              case 2: tm_int = tm.tm_hour; break;
              case 3: tm_int = tm.tm_mday; break;
              case 4: tm_int = tm.tm_mon; break;
              case 5: tm_int = tm.tm_year; break;
              case 6: tm_int = tm.tm_wday; break;
              case 7: tm_int = tm.tm_yday; break;
              case 8: tm_int = tm.tm_isdst; break;
            }
            PUSHs(tm_int == INT_MIN ? undef : sv_2mortal(newSViv(tm_int)));
          }
        }
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
    if (LIKELY(gethostname(name, sizeof(name)) == 0))
      mPUSHp(name, strnlen(name, sizeof(name)));
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
            EXTEND(SP, 4);
            mPUSHi(value.it_interval.tv_sec);
            mPUSHi(value.it_interval.tv_usec);
            mPUSHi(value.it_value.tv_sec);
            mPUSHi(value.it_value.tv_usec);
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
            EXTEND(SP, 4);
            mPUSHi(ovalue.it_interval.tv_sec);
            mPUSHi(ovalue.it_interval.tv_usec);
            mPUSHi(ovalue.it_value.tv_sec);
            mPUSHi(ovalue.it_value.tv_usec);
        }

#endif

#ifdef PSX2008_HAS_NICE
void
nice(int incr);
  PREINIT:
    int rv;
  PPCODE:
  {
    SETERRNO(0, 0);
    rv = nice(incr);
    if (rv != -1 || errno == 0)
      mPUSHi(rv);
    else
      PUSHs(&PL_sv_undef);
  }

#endif

#ifdef PSX2008_HAS_GETPRIORITY
void
getpriority(int which=PRIO_PROCESS, id_t who=0);
  PREINIT:
    int rv;
  PPCODE:
  {
    SETERRNO(0, 0);
    rv = getpriority(which, who);
    if (rv != -1 || errno == 0)
      mPUSHi(rv);
    else
      PUSHs(&PL_sv_undef);
  }

#endif

#ifdef PSX2008_HAS_SETPRIORITY
SysRetTrue
setpriority(int prio, int which=PRIO_PROCESS, id_t who=0);

#endif

#ifdef PSX2008_HAS_GETSID
pid_t
getsid(pid_t pid=0);

#endif

#ifdef PSX2008_HAS_SETSID
pid_t
setsid();

#endif

#define RETURN_UTXENT {                                                 \
    if (utxent != NULL) {                                               \
      EXTEND(SP, 7);                                                    \
      mPUSHp(utxent->ut_user, strnlen(utxent->ut_user, sizeof(utxent->ut_user))); \
      mPUSHp(utxent->ut_id,   strnlen(utxent->ut_id,   sizeof(utxent->ut_id  ))); \
      mPUSHp(utxent->ut_line, strnlen(utxent->ut_line, sizeof(utxent->ut_line))); \
      mPUSHi(utxent->ut_pid);                                           \
      mPUSHi(utxent->ut_type);                                          \
      mPUSHi(utxent->ut_tv.tv_sec);                                     \
      mPUSHi(utxent->ut_tv.tv_usec);                                    \
    }                                                                   \
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
      memcpy(utxent_req.ut_id, ut_id,
             strnlen(ut_id, sizeof(utxent_req.ut_id)));
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
      memcpy(utxent_req.ut_line, ut_line,
             strnlen(ut_line, sizeof(utxent_req.ut_line)));
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

#ifdef PSX2008_HAS_SEED48
void
seed48(unsigned short seed1, unsigned short seed2, unsigned short seed3);
    INIT:
        unsigned short seed16v[3] = { seed1, seed2, seed3 };
        unsigned short *old = seed48(seed16v);
    PPCODE:
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

#ifdef PSX2008_HAS_SETREUID
SysRetTrue
setreuid(uid_t ruid, uid_t euid);

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
SysRetTrue
sigpause(int sig);

#endif

#ifdef PSX2008_HAS_SIGRELSE
SysRetTrue
sigrelse(int sig);

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
      sevp.sigev_notify = SIGEV_SIGNAL;
      sevp.sigev_signo = SvIV(sig);
    }
    else {
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
  CODE:
    SvGETMAGIC(what);
    if (!SvOK(what)) {
      errno = ENOENT;
      RETVAL = -1;
    }
    else if (SvPOK(what)) {
      const char *path = SvPV_nomg_const_nolen(what);
      RETVAL = chdir(path);
    }
    else {
#ifdef PSX2008_HAS_FCHDIR
      int fd = _psx_fileno(aTHX_ what);
      RETVAL = fchdir(fd);
#else
      errno = ENOSYS;
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
      errno = ENOENT;
      RETVAL = -1;
    }
    else if (SvPOK(what)) {
      const char *path = SvPV_nomg_const_nolen(what);
      RETVAL = chmod(path, mode);
    }
    else {
#ifdef PSX2008_HAS_FCHMOD
      int fd = _psx_fileno(aTHX_ what);
      RETVAL = fchmod(fd, mode);
#else
      errno = ENOSYS;
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
      errno = ENOENT;
      RETVAL = -1;
    }
    else if (SvPOK(what)) {
      const char *path = SvPV_nomg_const_nolen(what);
      RETVAL = chown(path, owner, group);
    }
    else {
#ifdef PSX2008_HAS_FCHOWN
      int fd = _psx_fileno(aTHX_ what);
      RETVAL = fchown(fd, owner, group);
#else
      errno = ENOSYS;
      RETVAL = -1;
#endif
    }
  OUTPUT:
    RETVAL

#endif

#ifdef PSX2008_HAS_TRUNCATE
SysRetTrue
truncate(SV *what, Off_t length);
  CODE:
    SvGETMAGIC(what);
    if (!SvOK(what)) {
      errno = ENOENT;
      RETVAL = -1;
    }
    else if (SvPOK(what)) {
      const char *path = SvPV_nomg_const_nolen(what);
      RETVAL = truncate(path, length);
    }
    else {
#ifdef PSX2008_HAS_FTRUNCATE
      int fd = _psx_fileno(aTHX_ what);
      RETVAL = ftruncate(fd, length);
#else
      errno = ENOSYS;
      RETVAL = -1;
#endif
    }
  OUTPUT:
    RETVAL

#endif

#ifdef PSX2008_HAS_PATHCONF
void
pathconf(SV *what, int name);
  INIT:
    long rv = -1;
  PPCODE:
  {
    SETERRNO(0, 0);
    SvGETMAGIC(what);
    if (!SvOK(what))
      errno = ENOENT;
    else if (SvPOK(what)) {
      const char *path = SvPV_nomg_const_nolen(what);
      rv = pathconf(path, name);
    }
    else {
#ifdef PSX2008_HAS_FPATHCONF
      int fd = _psx_fileno(aTHX_ what);
      rv = fpathconf(fd, name);
#else
      errno = ENOSYS;
#endif
    }
    if (rv == -1 && errno != 0)
      PUSHs(&PL_sv_undef);
    else
      PUSH_INT_OR_PV(rv);
  }

#endif

#ifdef PSX2008_HAS_SYSCONF
void
sysconf(int name);
  INIT:
    long rv;
  PPCODE:
  {
    SETERRNO(0, 0);
    rv = sysconf(name);
    if (rv == -1 && errno != 0)
      PUSHs(&PL_sv_undef);
    else
      PUSH_INT_OR_PV(rv);
  }

#endif

#ifdef PSX2008_HAS_CONFSTR
char *
confstr(int name);
  INIT:
    size_t len;
  CODE:
  {
    SETERRNO(0, 0);
    len = confstr(name, NULL, 0);
    if (len) {
      RETVAL = safemalloc(len);
      if (RETVAL != NULL) {
        SAVEFREEPV(RETVAL);
        confstr(name, RETVAL, len);
      }
      else
        errno = ENOMEM;
    }
    else if (errno == 0)
      RETVAL = "";
    else
      RETVAL = NULL;
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
      errno = ENOENT;
    else if (SvPOK(what)) {
      const char *path = SvPV_nomg_const_nolen(what);
      rv = stat(path, &buf);
    }
    else {
#ifdef PSX2008_HAS_FSTAT
      int fd = _psx_fileno(aTHX_ what);
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
mkdtemp(SV *template);
  PPCODE:
  {
    STRLEN len;
    const char *ctmp = SvPV_const(template, len);
    /* Copy the original template to avoid overwriting it. */
    SV *tmpsv = newSVpvn_flags(ctmp, len, SVs_TEMP);
    char *dtemp = mkdtemp(SvPVX(tmpsv));
    PUSHs(dtemp ? tmpsv : &PL_sv_undef);
  }

#endif

#ifdef PSX2008_HAS_MKSTEMP
void
mkstemp(SV *template);
  PPCODE:
  {
    STRLEN len;
    const char *ctmp = SvPV_const(template, len);
    /* Copy the original template to avoid overwriting it. */
    SV *tmpsv = newSVpvn_flags(ctmp, len, SVs_TEMP);
    int fd = mkstemp(SvPVX(tmpsv));
    if (fd >= 0) {
      EXTEND(SP, 2);
      mPUSHi(fd);
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
    if (UNLIKELY(fd < 0 || fd > INT_MAX))
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
    if (UNLIKELY(fd < 0 || fd > INT_MAX))
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
        struct timespec times[2] = { { atime_sec, atime_nsec },
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
    STRLEN nbytes;
    char *cbuf;
  PPCODE:
  {
    if (UNLIKELY(SvNEGATIVE(count))) /* Performs 'get' magic. */
      croak("%s::read: Can't handle negative count: %" SVf,
            PACKNAME, SVfARG(count));
    nbytes = SvSTRLEN(count);
    if ((Size_t)nbytes != nbytes)
      nbytes = SSIZE_MAX;
    if (UNLIKELY(SvTRULYREADONLY(buf))) {
      if (nbytes)
        croak("%s::read: Can't modify read-only buf", PACKNAME);
      cbuf = NULL;
    }
    else {
      if (nbytes+1 == 0)
        --nbytes;
      if (!SvPOK(buf))
        sv_setpvn(buf, "", 0);
      (void)SvPV_force_nolen(buf);
      /* +1 for final '\0' to be on the safe side. */
      cbuf = SvGROW(buf, nbytes+1);
    }
    rv = read(fd, cbuf, nbytes);
    if (UNLIKELY(rv == -1))
      PUSHs(&PL_sv_undef);
    else {
      Size_t nread = (Size_t)rv;
      if (cbuf) {
        cbuf[nread] = '\0';
        SvCUR_set(buf, nread);
        SvPOK_only(buf);
        SvTAINTED_on(buf);
        SvSETMAGIC(buf);
      }
      PUSH_INT_OR_PV(nread);
    }
  }

#endif

#ifdef PSX2008_HAS_WRITE
void
write(psx_fd_t fd, SV *buf, SV *count=NULL);
  PREINIT:
    STRLEN cbuflen, nbytes;
    SSize_t rv;
  PPCODE:
  {
    const char *cbuf = SvPV_const(buf, cbuflen);
    if (UNLIKELY(SvNEGATIVE(count))) /* Performs 'get' magic. */
      croak("%s::write: Can't handle negative count: %" SVf,
            PACKNAME, SVfARG(count));
    else if (SvUNDEF_purposely(count))
      nbytes = cbuflen;
    else {
      nbytes = SvSTRLEN(count);
      if (nbytes > cbuflen)
        nbytes = cbuflen;
    }
    if ((Size_t)nbytes != nbytes)
      nbytes = SSIZE_MAX;
    rv = write(fd, cbuf, nbytes);
    if (LIKELY(rv != -1))
      PUSH_INT_OR_PV((Size_t)rv);
    else
      PUSHs(&PL_sv_undef);
  }

#endif

#ifdef PSX2008_HAS_READV
void
readv(psx_fd_t fd, SV *buffers, AV *sizes);
  PROTOTYPE: $\[@$]$
  PPCODE:
  {
    SSize_t rv = _readv50c(aTHX_ fd, buffers, sizes, NULL, NULL);
    if (LIKELY(rv != -1))
      PUSH_INT_OR_PV((Size_t)rv);
    else
      PUSHs(&PL_sv_undef);
  }

#endif

#ifdef PSX2008_HAS_PREADV
void
preadv(psx_fd_t fd, SV *buffers, AV *sizes, SV *offset=&PL_sv_undef);
  PROTOTYPE: $\[@$]$;$
  PPCODE:
  {
    SSize_t rv = _readv50c(aTHX_ fd, buffers, sizes, offset, NULL);
    if (LIKELY(rv != -1))
      PUSH_INT_OR_PV((Size_t)rv);
    else
      PUSHs(&PL_sv_undef);
  }

#endif

#ifdef PSX2008_HAS_PREADV2
void
preadv2(psx_fd_t fd, SV *buffers, AV *sizes, SV *offset=&PL_sv_undef, \
        SV *flags=&PL_sv_undef);
  PROTOTYPE: $\[@$]$;$$
  PPCODE:
  {
    SSize_t rv = _readv50c(aTHX_ fd, buffers, sizes, offset, flags);
    if (LIKELY(rv != -1))
      PUSH_INT_OR_PV((Size_t)rv);
    else
      PUSHs(&PL_sv_undef);
  }

#endif

#ifdef PSX2008_HAS_WRITEV
void
writev(psx_fd_t fd, AV *buffers);
  PPCODE:
  {
    struct iovec *iov;
    int iovcnt = _psx_av2iov(aTHX_ buffers, &iov);
    ssize_t rv = LIKELY(iovcnt >= 0) ? writev(fd, iov, iovcnt) : -1;
    if (LIKELY(rv != -1))
      PUSH_INT_OR_PV((size_t)rv);
    else
      PUSHs(&PL_sv_undef);
  }

#endif

#ifdef PSX2008_HAS_PWRITEV
void
pwritev(psx_fd_t fd, AV *buffers, SV *offset=NULL);
  PPCODE:
  {
    struct iovec *iov;
    int iovcnt = _psx_av2iov(aTHX_ buffers, &iov);
    Off_t offs = SvUNDEF_purposely(offset) ? 0 : SvOFFt(offset);
    ssize_t rv = LIKELY(iovcnt >= 0) ? pwritev(fd, iov, iovcnt, offs) : -1;
    if (LIKELY(rv != -1))
      PUSH_INT_OR_PV((size_t)rv);
    else
      PUSHs(&PL_sv_undef);
  }

#endif

#ifdef PSX2008_HAS_PWRITEV2
void
pwritev2(psx_fd_t fd, AV *buffers, SV *offset=NULL, SV *flags=NULL);
  PPCODE:
  {
    struct iovec *iov;
    int iovcnt = _psx_av2iov(aTHX_ buffers, &iov);
    Off_t offs = SvUNDEF_purposely(offset) ? 0 : SvOFFt(offset);
    int i_flags = SvUNDEF_purposely(flags) ? 0 : (int)SvIV(flags);
    ssize_t rv =
      LIKELY(iovcnt >= 0) ? pwritev2(fd, iov, iovcnt, offs, i_flags) : -1;
    if (LIKELY(rv != -1))
      PUSH_INT_OR_PV((size_t)rv);
    else
      PUSHs(&PL_sv_undef);
  }

#endif

#ifdef PSX2008_HAS_PREAD
void
pread(psx_fd_t fd, SV *buf, SV *count, SV *offset=NULL, SV *buf_offset=NULL);
  PREINIT:
    Off_t f_offset;
    char *cbuf;
    STRLEN cbuflen, new_len, b_offset, nbytes;
    SSize_t rv;
  PPCODE:
  {
    if (UNLIKELY(SvNEGATIVE(count))) /* Performs 'get' magic. */
      croak("%s::pread: Can't handle negative count: %" SVf,
            PACKNAME, SVfARG(count));

    nbytes = SvSTRLEN(count);
    if ((Size_t)nbytes != nbytes)
      nbytes = SSIZE_MAX;

    if (UNLIKELY(SvTRULYREADONLY(buf))) {
      if (nbytes)
        croak("%s::pread: Can't modify read-only buf", PACKNAME);
      cbuf = NULL;
      b_offset = 0;
    }
    else {
      if (!SvPOK(buf))
        sv_setpvn(buf, "", 0);
      (void)SvPV_force(buf, cbuflen);

      /* Ensure buf_offset results in a valid string index. */
      if (SvUNDEF_purposely(buf_offset))
        b_offset = 0;
      else {
        int neg = SvNEGATIVE(buf_offset);
        b_offset = SvSTRLEN(buf_offset);
        if (neg) {
          b_offset += cbuflen;
          if (b_offset > cbuflen)
           croak("%s::pread: buf_offset %" SVf " outside string",
                 PACKNAME, SVfARG(buf_offset));
        }
      }

      new_len = b_offset + nbytes;
      if (new_len < b_offset || new_len+1 == 0)
        croak("%s::pread: buf_offset[%" SVf "] + count[%" SVf
              "] is too big for a Perl string",
              PACKNAME, SVfARG(buf_offset), SVfARG(count));

      /* +1 for final '\0' to be on the safe side. */
      cbuf = SvGROW(buf, new_len+1);

      /* Pad buffer with zeros if b_offset is past the buffer. */
      if (b_offset > cbuflen)
        Zero(cbuf + cbuflen, b_offset - cbuflen, char);
    }

    /* Now fscking finally read teh data! */
    f_offset = SvUNDEF_purposely(offset) ? 0 : SvOFFt(offset);
    rv = pread(fd, cbuf + b_offset, nbytes, f_offset);

    if (UNLIKELY(rv == -1))
      PUSHs(&PL_sv_undef);
    else {
      Size_t nread = (Size_t)rv;
      if (cbuf) {
        cbuf[b_offset + nread] = '\0';
        SvCUR_set(buf, b_offset + nread);
        SvPOK_only(buf);
        SvTAINTED_on(buf);
        SvSETMAGIC(buf);
      }
      PUSH_INT_OR_PV(nread);
    }
  }

#endif

#ifdef PSX2008_HAS_PWRITE
void
pwrite(psx_fd_t fd, SV *buf,                            \
       SV *count=NULL, SV *offset=NULL, SV *buf_offset=NULL);
  PREINIT:
    Off_t f_offset;
    const char *cbuf;
    STRLEN cbuflen, b_offset, max_nbytes, nbytes;
    SSize_t rv;
  PPCODE:
  {
    if (UNLIKELY(SvNEGATIVE(count))) /* Performs 'get' magic. */
      croak("%s::pwrite: Can't handle negative count: %" SVf,
            PACKNAME, SVfARG(count));

    cbuf = SvPV_const(buf, cbuflen);

    /* Ensure buf_offset results in a valid string index. This is slightly
     * different from pread() because we can't allow offsets beyond the buffer
     * at all (zero is okay, though). */
    if (SvUNDEF_purposely(buf_offset))
      b_offset = 0;
    else {
      int neg = SvNEGATIVE(buf_offset);
      b_offset = SvSTRLEN(buf_offset);
      if (neg)
        b_offset += cbuflen;
      if (LIKELY(b_offset) && UNLIKELY(b_offset >= cbuflen))
          croak("%s::pwrite: buf_offset %" SVf " outside string",
                PACKNAME, SVfARG(buf_offset));
    }

    max_nbytes = cbuflen - b_offset;
    nbytes = SvUNDEF_purposely(count) ? max_nbytes : SvSTRLEN(count);
    if (nbytes > max_nbytes)
      nbytes = max_nbytes;
    if ((Size_t)nbytes != nbytes)
      nbytes = SSIZE_MAX;

    f_offset = SvUNDEF_purposely(offset) ? 0 : SvOFFt(offset);
    rv = pwrite(fd, cbuf + b_offset, nbytes, f_offset);

    if (LIKELY(rv != -1))
      PUSH_INT_OR_PV((Size_t)rv);
    else
      PUSHs(&PL_sv_undef);
  }

#endif

#ifdef PSX2008_HAS_POSIX_FADVISE
SysRetTrue
posix_fadvise(psx_fd_t fd, Off_t offset, Off_t len, int advice);
  CODE:
    errno = posix_fadvise(fd, offset, len, advice);
    RETVAL = errno ? -1 : 0;
  OUTPUT:
    RETVAL

#endif

#ifdef PSX2008_HAS_POSIX_FALLOCATE
SysRetTrue
posix_fallocate(psx_fd_t fd, Off_t offset, Off_t len);
  CODE:
    errno = posix_fallocate(fd, offset, len);
    RETVAL = errno ? -1 : 0;
  OUTPUT:
    RETVAL

#endif

#ifdef PSX2008_HAS_PTSNAME
char *
ptsname(psx_fd_t fd);
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
      /* Some implementations return -1 on error and set errno. */
      if (rv > 0)
        errno = rv;
      RETVAL = NULL;
    }
#else
    RETVAL = ptsname(fd);
#endif
  OUTPUT:
    RETVAL

#endif

#ifdef PSX2008_HAS_TTYNAME
char *
ttyname(psx_fd_t fd);
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
    PSX2008_LROUND_T ret;
  PPCODE:
    SETERRNO(0, 0);
    feclearexcept(FE_ALL_EXCEPT);
    ret = PSX2008_LROUND(x);
    if (errno == 0 && fetestexcept(FE_ALL_EXCEPT) == 0)
      PUSH_INT_OR_PV(ret);
    else
      PUSHs(&PL_sv_undef);

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
    SETERRNO(0, 0);
    feclearexcept(FE_ALL_EXCEPT);
    res = remainder(x, y);
    if (errno == 0 && fetestexcept(FE_ALL_EXCEPT) == 0)
      mPUSHn(res);
    else
      PUSHs(&PL_sv_undef);

#endif

#ifdef PSX2008_HAS_REMQUO
void
remquo(double x, double y);
  INIT:
    int quo;
    double res;
  PPCODE:
    SETERRNO(0, 0);
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
