#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "perliol.h"
#include "ppport.h"

#ifdef WIN32

#define WORKBUF_SIZE 40

#ifndef ENABLE_VIRTUAL_TERMINAL_PROCESSING
#define ENABLE_VIRTUAL_TERMINAL_PROCESSING 0x0004
#endif

typedef struct {
  struct _PerlIO base;

  /* the CRT handle, typically 1 or 2 */
  int fd;

  /* the Win32 handle */
  HANDLE h;

  /* mode of the handle*/
  int imode;

  /* buffer containing incomplete utf8 characters
     or possible escape sequences.
   */
  U8 workbuf[WORKBUF_SIZE];
  size_t workbuf_used;

  /* used when translating utf-8 to utf-16 */
  /* expanded as needed */
  wchar_t *outbuf;
  int outbuf_size;
} PerlIOW32Con;

/* we largely ignore the flags at this point, but do propagate them
   for dup.
   This is PerlIOUnix_oflags() from perlio.c
*/
int
PerlIOW32Con_oflags(const char *mode)
{
    int oflags = -1;
    if (*mode == IoTYPE_IMPLICIT || *mode == IoTYPE_NUMERIC)
        mode++;
    switch (*mode) {
    case 'r':
        oflags = O_RDONLY;
        if (*++mode == '+') {
            oflags = O_RDWR;
            mode++;
        }
        break;

    case 'w':
        oflags = O_CREAT | O_TRUNC;
        if (*++mode == '+') {
            oflags |= O_RDWR;
            mode++;
        }
        else
            oflags |= O_WRONLY;
        break;

    case 'a':
        oflags = O_CREAT | O_APPEND;
        if (*++mode == '+') {
            oflags |= O_RDWR;
            mode++;
        }
        else
            oflags |= O_WRONLY;
        break;
    }

    /* XXX TODO: PerlIO_open() test that exercises 'rb' and 'rt'. */

    /* Unless O_BINARY is different from O_TEXT, first bit-or:ing one
     * of them in, and then bit-and-masking the other them away, won't
     * have much of an effect. */
    switch (*mode) {
    case 'b':
#if O_TEXT != O_BINARY
        oflags |= O_BINARY;
        oflags &= ~O_TEXT;
#endif
        mode++;
        break;
    case 't':
#if O_TEXT != O_BINARY
        oflags |= O_TEXT;
        oflags &= ~O_BINARY;
#endif
        mode++;
        break;
    default:
#if O_BINARY != 0
        /* bit-or:ing with zero O_BINARY would be useless. */
        /*
         * If neither "t" nor "b" was specified, open the file
         * in O_BINARY mode.
         *
         * Note that if something else than the zero byte was seen
         * here (e.g. bogus mode "rx"), just few lines later we will
         * set the errno and invalidate the flags.
         */
        oflags |= O_BINARY;
#endif
        break;
    }
    if (*mode || oflags == -1) {
        SETERRNO(EINVAL, LIB_INVARG);
        oflags = -1;
    }
    return oflags;
}


static IV
PerlIOW32Con_pushed(pTHX_ PerlIO* f, const char* mode, SV* arg,
		    PerlIO_funcs* tab) {
  PERL_UNUSED_ARG(mode);
  PERL_UNUSED_ARG(tab);

  /* FIXME: check mode? */
  /* mode is NULL on binmode? */
  if (SvOK(arg)) {
    STRLEN len;
    (void)SvPV(arg, len);
    if (len) {
      errno = EINVAL;
      return -1;
    }
  }
  PerlIOW32Con *con = PerlIOSelf(f, PerlIOW32Con);
  PerlIO *next = PerlIONext(f);
  if (next) {
    /* FIXME: flush? */
    /* otherwise it should come from open
       as with :unix, we never call down
     */
    con->fd = PerlIO_fileno(next);
  }
  con->imode = mode ? PerlIOW32Con_oflags(mode) : 0;
  con->h = (HANDLE)win32_get_osfhandle(con->fd);
  con->outbuf = NULL;
  con->outbuf_size = 0;
  
  DWORD cmode;
  if (!GetConsoleMode(con->h, &cmode)) {
    errno = ENOTTY;
    return -1;
  }

  cmode |= ENABLE_VIRTUAL_TERMINAL_PROCESSING;
  SetConsoleMode(con->h, cmode);
  PerlIOBase(f)->flags |= PERLIO_F_UTF8 | PERLIO_F_OPEN;

  return 0;
}

IV
PerlIOW32Con_popped(pTHX_ PerlIO *f)
{
  PerlIOW32Con * const os = PerlIOSelf(f, PerlIOW32Con);
  PERL_UNUSED_CONTEXT;
  
  if (os->outbuf) {
    PerlMemShared_free(os->outbuf);
    os->outbuf = NULL;
    os->outbuf_size = 0;
  }
  return 0;
}

static void
PerlIOW32Con_setfd(pTHX_ PerlIO *f, int fd) {
  PerlIOSelf(f, PerlIOW32Con)->fd = fd;  
}

/* largely PerlIOUnix_open() */
static PerlIO *
PerlIOW32Con_open(pTHX_ PerlIO_funcs *self, PerlIO_list_t *layers,
		  IV n, const char *mode, int fd, int imode,
		  int perm, PerlIO *f, int narg, SV **args)
{
  /* cloexec functions not visible */
  /*bool known_cloexec = 0;*/
    if (PerlIOValid(f)) {
        if (PerlIOBase(f)->tab && PerlIOBase(f)->flags & PERLIO_F_OPEN)
            (*PerlIOBase(f)->tab->Close)(aTHX_ f);
    }
    if (narg > 0) {
        if (*mode == IoTYPE_NUMERIC)
            mode++;
        else {
            imode = PerlIOW32Con_oflags(mode);
#ifdef VMS
            perm = 0777; /* preserve RMS defaults, ACL inheritance, etc. */
#else
            perm = 0666;
#endif
        }
        if (imode != -1) {
            STRLEN len;
            const char *path = SvPV_const(*args, len);
            if (!IS_SAFE_PATHNAME(path, len, "open"))
                return NULL;
            fd = _open(path, imode, perm);
            /*known_cloexec = 1;*/
        }
    }
    if (fd >= 0) {
#if 0
      /* these functions not exported or not win32? */
        if (known_cloexec)
	  Perl_setfd_inhexec_for_sysfd(aTHX_ fd);
        else
	  Perl_setfd_cloexec_or_inhexec_by_sysfdness(aTHX_ fd);
#endif
        if (*mode == IoTYPE_IMPLICIT)
            mode++;
        if (!f) {
            f = PerlIO_allocate(aTHX);
        }
        if (!PerlIOValid(f)) {
	  /* push sets the handle */
            if (!(f = PerlIO_push(aTHX_ f, self, mode, PerlIOArg))) {
                PerlLIO_close(fd);
                return NULL;
            }
        }
        PerlIOW32Con_setfd(aTHX_ f, fd);
        PerlIOBase(f)->flags |= PERLIO_F_OPEN;
        return f;
    }
    else {
        if (f) {
            NOOP;
            /*
             * FIXME: pop layers ???
             */
        }
        return NULL;
    }
}

static IV
PerlIOW32Con_fileno(pTHX_ PerlIO *f)
{
    PERL_UNUSED_CONTEXT;
    return PerlIOSelf(f, PerlIOW32Con)->fd;
}

static PerlIO *
PerlIOW32Con_dup(pTHX_ PerlIO *f, PerlIO *o, CLONE_PARAMS *param, int flags)
{
    const PerlIOW32Con * const os = PerlIOSelf(o, PerlIOW32Con);

    HANDLE h2 = NULL;
    if (!DuplicateHandle(GetCurrentProcess(), os->h,
			 GetCurrentProcess(), &h2,
			 0, FALSE, DUPLICATE_SAME_ACCESS)) {
      return NULL;
    }
    int fd = win32_open_osfhandle((intptr_t)h2, os->imode);
    PerlIO *df = PerlIOBase_dup(aTHX_ f, o, param, flags);
    if (!f) {
      return NULL;
    }
    PerlIOW32Con_setfd(aTHX_ df, fd);

    return df;
}

SSize_t
PerlIOW32Con_read(pTHX_ PerlIO *f, void *vbuf, Size_t count)
{
  PERL_UNUSED_ARG(f);
  PERL_UNUSED_ARG(vbuf);
  PERL_UNUSED_ARG(count);
  
  /* not implemented */
  errno = EINVAL;
  return -1;
}

SSize_t
PerlIOW32Con_write(pTHX_ PerlIO *f, const void *vbuf, Size_t count)
{
  /* FIXME: locks */
  /* FIXME: put unconsumed bytes in workbuf and use them the next time around */
  /* FIXME: handle/discard out of range UTF-8? */
  /* TODO: escape codes - might be possible with SetConsoleMode(... ENABLE_VIRTUAL_TERMINAL_PROCESSING) */

  PerlIOW32Con * const os = PerlIOSelf(f, PerlIOW32Con);
  LPCSTR in = vbuf;
  int wcount = MultiByteToWideChar(CP_UTF8, 0, in, count, os->outbuf, os->outbuf_size);
  if (wcount > os->outbuf_size) {
    /* out of space, expand and try again */
    int newsize = os->outbuf_size ? os->outbuf_size * 2 : WORKBUF_SIZE;
    if (newsize < wcount)
      newsize = wcount;
    os->outbuf = PerlMemShared_realloc(os->outbuf, newsize * sizeof(wchar_t));
    os->outbuf_size = newsize;

    wcount = MultiByteToWideChar(CP_UTF8, 0, in, count, os->outbuf, os->outbuf_size);
  }
  if (wcount > 0
      && WriteConsoleW(os->h, os->outbuf, wcount, NULL, NULL)) {
    /* assume we wrote all */
    return count;
  }
  errno = EINVAL; /* FIXME: error code */
  return -1;
}

Off_t
PerlIOW32Con_tell(pTHX_ PerlIO *f)
{
  PERL_UNUSED_ARG(f);
  errno = ESPIPE;
  return -1;
}

IV
PerlIOW32Con_seek(pTHX_ PerlIO *f, Off_t offset, int whence)
{
  PERL_UNUSED_ARG(f);
  PERL_UNUSED_ARG(offset);
  PERL_UNUSED_ARG(whence);
  errno = ESPIPE;
  return -1;
}

IV
PerlIOW32Con_close(pTHX_ PerlIO *f)
{
  /* FIXME: flush? */
  /* FIXME: error handling */
    const int fd = PerlIOSelf(f, PerlIOW32Con)->fd;
    _close(fd);

    return 0;
}

PERLIO_FUNCS_DECL(PerlIO_win32console) = {
    sizeof(PerlIO_funcs),
    "win32console",
    sizeof(PerlIOW32Con),
    PERLIO_K_RAW,
    PerlIOW32Con_pushed,
    PerlIOW32Con_popped,
    PerlIOW32Con_open,
    PerlIOBase_binmode,         /* binmode */
    NULL,
    PerlIOW32Con_fileno,
    PerlIOW32Con_dup,
    PerlIOW32Con_read,
    PerlIOBase_unread,
    PerlIOW32Con_write,
    PerlIOW32Con_seek,
    PerlIOW32Con_tell,
    PerlIOW32Con_close,
    PerlIOBase_noop_ok,         /* flush */
    PerlIOBase_noop_fail,       /* fill */
    PerlIOBase_eof,
    PerlIOBase_error,
    PerlIOBase_clearerr,
    PerlIOBase_setlinebuf,
    NULL,                       /* get_base */
    NULL,                       /* get_bufsiz */
    NULL,                       /* get_ptr */
    NULL,                       /* get_cnt */
    NULL,                       /* set_ptrcnt */
};

#endif

MODULE = PerlIO::win32console PACKAGE = PerlIO::win32console

BOOT:
#ifdef WIN32
  PerlIO_define_layer(aTHX_ (PerlIO_funcs*)&PerlIO_win32console);
#endif
