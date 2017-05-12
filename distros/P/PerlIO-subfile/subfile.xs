/* -*- c -*- */
/*    subfile.xs
 *
 *    Copyright (C) 2001-2003, Nicholas Clark
 *
 *    You may distribute this work under the terms of either the GNU General
 *    Public License or the Artistic License, as specified in perl's README
 *    file.
 *
 */
#define PERL_NO_GET_CONTEXT

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "perliol.h"

typedef struct {
  PerlIOBuf	base;
  Off_t		start;
  Off_t		end;	/* byte beyond the end. 0 will make file unbounded.  */
} PerlIOSubfile;


static IV
PerlIOSubfile_seek(pTHX_ PerlIO *f, Off_t offset, int whence)
{
  IV code;
  PerlIOSubfile *s = PerlIOSelf(f,PerlIOSubfile);
  Off_t new;

#if DEBUG_LAYERSUBFILE
  PerlIO_debug("PerlIOSubfile_seek f=%p offset=%08"UVxf" whence=%d "
	       "s->start=%08"UVxf" s->end=%08"UVxf"\n",
	       f, (UV)offset, whence, (UV)s->start, (UV)s->end);
#endif

  if (whence == SEEK_SET)
    offset = new = s->start + offset;
  else if (whence == SEEK_CUR)
    new = PerlIOBuf_tell(aTHX_ f) + offset;
  else if (whence == SEEK_END) {
    offset = new = s->end + offset;
    whence = SEEK_SET;
  } else
    return -1;


  if (new < s->start) {
#if DEBUG_LAYERSUBFILE
    PerlIO_debug("  new=%08"UVxf" whence=%d fell off start\n", (UV)new, whence);
#endif
    errno = EINVAL;
    return -1;
  }

  code = PerlIOBuf_seek(aTHX_ f, offset, whence);

#if DEBUG_LAYERSUBFILE
  PerlIO_debug("  new=%08"UVxf" whence=%d code=%d\n", (UV)new, whence,
	       (int) code);
#endif

  assert (PerlIOBuf_tell(aTHX_ f) >= s->start);
  return code;
}

static Off_t
PerlIOSubfile_tell (pTHX_ PerlIO *f)
{
  PerlIOSubfile *s = PerlIOSelf(f,PerlIOSubfile);
  Off_t real = PerlIOBuf_tell(aTHX_ f);

#if DEBUG_LAYERSUBFILE
  PerlIO_debug("PerlIOSubfile_tell f=%p real=%08"UVxf" return %08"UVxf
	       " s->start=%08"UVxf" s->end=%08"UVxf"\n",
	       f, (UV)real, (UV)(real-s->start), (UV)s->start, (UV)s->end);
#endif

  assert (real >= s->start);
  assert (s->end == 0 || (real < s->end));

  return real - s->start;
}

static IV
PerlIOSubfile_fill(pTHX_ PerlIO *f)
{
  PerlIOSubfile *s = PerlIOSelf(f,PerlIOSubfile);
  Off_t real = PerlIOBuf_tell(aTHX_ f);

#if DEBUG_LAYERSUBFILE
  PerlIO_debug("PerlIOSubfile_fill f=%p real=%08"UVxf
	       " s->start=%08"UVxf" s->end=%08"UVxf"\n",
	       f, (UV)real, (UV)s->start, (UV)s->end);
#endif

  if ((s->end == 0) || (real < s->end)) {
    PerlIOBuf *b = PerlIOSelf(f,PerlIOBuf);
    IV code = PerlIOBuf_fill(aTHX_ f);
    SSize_t avail;

#if DEBUG_LAYERSUBFILE
    PerlIO_debug("  code=%-3d avail=%08"UVxf" b->buf=%p b->end=%p\n", code,
		 (UV)(b->end - b->buf), b->buf, b->end);
#endif
    if (code)
      return code;

    avail = b->end - b->buf;
    if (s->end && ((real + avail) >= s->end)) {
      avail = s->end - real;
      b->end = b->buf + avail;
#if DEBUG_LAYERSUBFILE
    PerlIO_debug("  truncate avail=%08"UVxf" b->buf=%p b->end=%p\n", avail,
		 b->buf, b->end);
#endif
      assert (avail > 0);
    }
    return 0;
  }
  PerlIOBase(f)->flags |= PERLIO_F_EOF;
  return -1;
}

static SV *
PerlIOSubfile_getarg(pTHX_ PerlIO *f, CLONE_PARAMS *param, int flags)
{
  PerlIOSubfile *s = PerlIOSelf(f,PerlIOSubfile);
  SV *sv = newSVpvf("start=%08"UVxf",end=%08"UVxf, (UV)s->start, (UV)s->end);
  return sv ? sv : &PL_sv_undef;
}

static IV
PerlIOSubfile_pushed(pTHX_ PerlIO *f, const char *mode, SV *arg,
		     PerlIO_funcs *tab)
{
  IV code = 0;
  PerlIOSubfile *s = PerlIOSelf(f,PerlIOSubfile);

  STRLEN len;	/* This is effectively also a flag: 0 means "no arguments" */
  const char *argstr;
  bool is_UV;

  if (arg && SvOK(arg)) {
    if (SvIOK(arg) && !SvPOK(arg))
      len = is_UV = 1;
    else {
      is_UV = 0;
      argstr = SvPV(arg, len);
    }
  } else {
    argstr = NULL;
    len = 0;
  }

#if DEBUG_LAYERSUBFILE
  PerlIO_debug("PerlIOSubfile_pushed f=%p %s %s fl=%08"UVxf" s=%p\n",
	       f,PerlIOBase(f)->tab->name,(mode) ? mode : "(Null)",
	       PerlIOBase(f)->flags, s);
  if (argstr) {
    if (is_UV)
      PerlIO_debug("  arg=%08"UVxf"\n", SvUV(arg));
    else
      PerlIO_debug("  len=%d argstr=%.*s\n", (int)len, (int)len, argstr);
  }
#endif

  code = PerlIOBuf_pushed(aTHX_ f,mode,&PL_sv_undef,tab);
  if (code)
    return code;

  s->start = PerlIOBuf_tell(aTHX_ f);
  s->end = 0;

  if (PerlIOBase(f)->flags & PERLIO_F_CANWRITE)
    return -1;  /* Not having any of the write stuff.  */

  if (len) {
    if (is_UV) {
      s->end = s->start + SvUV(arg);
#if DEBUG_LAYERSUBFILE
      PerlIO_debug("  end is %08"UVxf"\n", (UV)s->end);
#endif
    } else {
      const char *end = argstr + len;
      dTHX;       /* fetch context */

      while (1) {
        const char *comma = memchr (argstr, ',', end - argstr);
        STRLEN this_len = comma ? (comma - argstr) : (end - argstr);
        const char *value = memchr (argstr, '=', this_len);

#if DEBUG_LAYERSUBFILE
        PerlIO_debug("  processing len=%d argstr=%.*s value=%p\n",
                     (int)this_len, (int)this_len, argstr, value);
#endif

        if (value) { /* value points at the '=' sign.  */
          STRLEN name_len = (value - argstr);
          int save_errno = errno;
          int relative = 0;
          Off_t offset;

          value++;
          while (isSPACE(*value))
            value++;
          if (*value == '+') {
            relative = 1;
            value++;
          } else if (*value == '-') {
            relative = -1;
            value++;
          }

          if (!isDIGIT(*value)) {
            errno = EINVAL;
            return -1;
          }

          errno = 0;
          offset = Strtoul (value, (char **) &value, 0); /* Guess the base */
          if (errno)
            return -1;
          errno = save_errno;

          while (isSPACE(*value))
            value++;
          if (value != (argstr + this_len)) {
#if DEBUG_LAYERSUBFILE
            PerlIO_debug("  failing this_len=%d argstr=%p value=%p, not %p,"
                         " offset=%08"UVxf"\n", (int)this_len, argstr, value,
                         (value + this_len), (UV)offset);
#endif
            errno = EINVAL;
            return -1;
          }

          if (name_len == 5 && memEQ (argstr, "start", 5)) {
            if (relative) {
              IV code = PerlIOBuf_seek(aTHX_ f, relative * offset, SEEK_CUR);
              if (code)
                return code;
              assert (PerlIOBuf_tell(aTHX_ f) == s->start + relative * offset);
              s->start += relative * offset;
#if DEBUG_LAYERSUBFILE
              PerlIO_debug("  rel start now %08"UVxf" %08"UVxf"\n",
                           (UV)s->start, (UV)PerlIOBuf_tell(aTHX_ f));
#endif
            } else {
              IV code = PerlIOBuf_seek(aTHX_ f, offset, SEEK_SET);
              if (code)
                return code;
              assert (PerlIOBuf_tell(aTHX_ f) == offset);
              s->start = offset;
#if DEBUG_LAYERSUBFILE
              PerlIO_debug("  abs start now %08"UVxf" %08"UVxf"\n",
                           (UV)s->start, (UV)PerlIOBuf_tell(aTHX_ f));
#endif
            }
          } else if (name_len == 3 && memEQ (argstr, "end", 3)) {
            if (relative)
              s->end = s->start + relative * offset;
            else
              s->end = offset;
#if DEBUG_LAYERSUBFILE
            PerlIO_debug("  end now %08"UVxf" relative=%d\n", (UV)s->end,
                         relative);
#endif
          } else {
            Perl_warn(aTHX_
                      "perlio: layer :subfile, unregonised argument \"%.*s\"",
                      (int)this_len, argstr);
          }
        } else {
          Perl_warn(aTHX_
                    "perlio: layer :subfile, argument \"%.*s\" has no value",
                    (int)this_len, argstr);
        }
        if (!comma)
          break;
        argstr = comma + 1;
      }
    }
  }
  return 0;
}

static SSize_t
PerlIO_write_fail(pTHX_ PerlIO *f, const void *vbuf, Size_t count)
{
  return -1;
}

PerlIO_funcs PerlIO_subfile = {
 sizeof(PerlIO_funcs),
 "subfile",
 sizeof(PerlIOSubfile),
 PERLIO_K_BUFFERED,
 PerlIOSubfile_pushed,
 PerlIOBase_noop_ok,
 PerlIOBuf_open,
 PerlIOBase_binmode,
 PerlIOSubfile_getarg,
 PerlIOBase_fileno,
 PerlIOBuf_dup,
 PerlIOBuf_read,
 PerlIOBuf_unread,
 PerlIO_write_fail,
 PerlIOSubfile_seek,
 PerlIOSubfile_tell,
 PerlIOBuf_close,
 PerlIOBuf_flush,
 PerlIOSubfile_fill,
 PerlIOBase_eof,
 PerlIOBase_error,
 PerlIOBase_clearerr,
 PerlIOBase_setlinebuf,
 PerlIOBuf_get_base,
 PerlIOBuf_bufsiz,
 PerlIOBuf_get_ptr,
 PerlIOBuf_get_cnt,
 PerlIOBuf_set_ptrcnt,
};

MODULE = PerlIO::subfile		PACKAGE = PerlIO::subfile		

PROTOTYPES: DISABLE

BOOT:
	PerlIO_define_layer(aTHX_ &PerlIO_subfile);
