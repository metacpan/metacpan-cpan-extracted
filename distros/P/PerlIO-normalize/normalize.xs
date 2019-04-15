#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"
#include <perliol.h>
#include <string.h>

typedef enum {
  NFC,
  NFD,
  NFKC,
  NFKD,
  FCD,
  FCC,
} normalization;

typedef struct {
  PerlIOBuf buf;
  SV *data;
  normalization norm;
} PerlIOnormalize;

normalization
parse_parameters(pTHX_ SV* param)
{
  STRLEN len;
  const char* begin;
  if (param && SvOK(param)) {
    begin = SvPV(param, len);
    if (len) {
      if (strncmp(begin, "NFC", len) == 0)  { return NFC; }
      if (strncmp(begin, "NFD", len) == 0)  { return NFD; }
      if (strncmp(begin, "NFKC", len) == 0) { return NFKC; }
      if (strncmp(begin, "NFKD", len) == 0) { return NFKD; }
      if (strncmp(begin, "FCD", len) == 0)  { return FCD; }
      if (strncmp(begin, "FCC", len) == 0)  { return FCC; }
    }
  }

  Perl_croak(aTHX_ ":normalize requires an argument of NFC, NFD, NFKC, NFKD, FCD, or FCC.");
}

IV
PerlIOnormalize_pushed(pTHX_ PerlIO* f, const char* mode, SV* arg, PerlIO_funcs *tab)
{
  normalization norm = parse_parameters(aTHX_ arg);
  if (PerlIOBuf_pushed(aTHX_ f, mode, arg, tab) == 0) {
    PerlIOBase(f)->flags |= PERLIO_F_UTF8;
    PerlIOSelf(f, PerlIOnormalize)->norm = norm;
    return 0;
  }
  return -1;
}

STRLEN
do_normalize(pTHX_ normalization norm, SV *input, char **out) {
  dSP;
  SV *nf, *output;
  char *temp = NULL;
  STRLEN len = 0;

  switch(norm) {
    case NFC:  nf = newSVpvn("NFC",  3); break;
    case NFD:  nf = newSVpvn("NFD",  3); break;
    case NFKC: nf = newSVpvn("NFKC", 4); break;
    case NFKD: nf = newSVpvn("NFKD", 4); break;
    case FCD:  nf = newSVpvn("FCD",  3); break;
    case FCC:  nf = newSVpvn("FCC",  3); break;
    default: Perl_croak(aTHX_ "Unknown normalization form %d", norm); break;
  }

  ENTER;
  SAVETMPS;

  PUSHMARK(sp);
  XPUSHs(nf);
  XPUSHs(input);
  PUTBACK;

  if (call_pv("Unicode::Normalize::normalize", G_SCALAR) != 1) {
    Perl_croak(aTHX_ "normalize returned nothing");
  }
  SPAGAIN;

  output = POPs;
  if (SvPOK(output)) {
    temp = SvPVutf8(output, len);
  }

  *out = (char *)malloc(len);
  if (*out == NULL) {
    Perl_croak(aTHX_ "Could not allocate memory for return value of normalization");
  }
  memcpy(*out, temp, len);

  if (len <= 0) {
    Perl_croak(aTHX_ "normalize returned an empty string");
  }

  PUTBACK;
  FREETMPS;
  LEAVE;

  return len;
}

IV
PerlIOnormalize_fill(pTHX_ PerlIO *f)
{
  PerlIO *nx = PerlIONext(f);
  SSize_t avail;

  /* make sure we have a buffer layer */
  if (!PerlIO_fast_gets(nx)) {
    char mode[8];
    nx = PerlIO_push(aTHX_ nx, &PerlIO_perlio, PerlIO_modestr(f,mode), Nullsv);
    if (!nx) {
      Perl_croak(aTHX_ "cannot push :perlio for %p", f);
    }
  }

  avail = PerlIO_get_cnt(nx);
  if (avail <= 0) {
    avail = PerlIO_fill(nx);
    if (avail == 0) {
      avail = PerlIO_get_cnt(nx);
    } else {
      if (!PerlIO_error(nx) && PerlIO_eof(nx)) {
        avail = 0;
      }
    }
  }

  if (avail > 0) {
    PerlIOnormalize *nz = PerlIOSelf(f, PerlIOnormalize);
    STDCHAR *ptr = PerlIO_get_ptr(nx);
    SV *input;
    char *out;
    STRLEN len = 0;

    nz->buf.ptr = nz->buf.end = (STDCHAR *) NULL;
    input = newSVpvn(ptr, avail);
    SvUTF8_on(input);

    len = do_normalize(aTHX_ nz->norm, input, &out);

    nz->data = newSVpvn(out,len);
    free(out);

    nz->buf.ptr = nz->buf.buf = (STDCHAR*)SvPVX(nz->data);
    nz->buf.end = nz->buf.ptr + SvCUR(nz->data);
    PerlIOBase(f)->flags |= PERLIO_F_RDBUF;
    SvUTF8_on(nz->data);

    PerlIO_set_ptrcnt(nx, ptr+avail, 0);

    return 0;
  }
  
  if (avail == 0) {
    /* EOF reached */
    PerlIOBase(f)->flags |= PERLIO_F_EOF;
  } else {
    PerlIOBase(f)->flags |= PERLIO_F_ERROR;
    Perl_PerlIO_save_errno(aTHX_ f);
  }

  return -1;
}

IV
PerlIOnormalize_flush(pTHX_ PerlIO *f)
{
  PerlIOnormalize *nz = PerlIOSelf(f, PerlIOnormalize);

  if ((PerlIOBase(f)->flags & PERLIO_F_WRBUF) && (nz->buf.ptr > nz->buf.buf)) {
    PerlIO *nx = PerlIONext(f);
    STDCHAR *ptr = nz->buf.buf;
    Size_t avail = nz->buf.ptr - nz->buf.buf;
    SV *input;
    char *out;
    STRLEN len = 0;
    SSize_t count = 0;

    input = newSVpvn(ptr, avail);
    SvUTF8_on(input);

    len = do_normalize(aTHX_ nz->norm, input, &out);

    count = PerlIO_write(nx, out, len);
    free(out);

    if ((STRLEN)count != len) {
      return -1;
    }

    return 0;
  }
  
  return PerlIOBuf_flush(aTHX_ f);
}

PerlIO_funcs PerlIO_normalize = {
  sizeof(PerlIO_funcs),
  "normalize",
  sizeof(PerlIOnormalize),
  PERLIO_K_BUFFERED | PERLIO_K_UTF8,
  PerlIOnormalize_pushed,
  PerlIOBuf_popped,      /* IV        PerlIOnormalize_popped */
  PerlIOBuf_open,
  PerlIOBase_binmode,
  NULL,
  PerlIOBase_fileno,
  PerlIOBuf_dup,
  PerlIOBuf_read,        /* SSize_t   PerlIOnormalize_read */
  PerlIOBuf_unread,      /* SSize_t   PerlIOnormalize_unread */
  PerlIOBuf_write,       /* SSize_t   PerlIOnormalize_write */
  PerlIOBuf_seek,
  PerlIOBuf_tell,
  PerlIOBuf_close,
  PerlIOnormalize_flush,
  PerlIOnormalize_fill,
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

MODULE = PerlIO::normalize                         PACKAGE = PerlIO::normalize

PROTOTYPES: DISABLE

BOOT:
  PerlIO_define_layer(aTHX_ &PerlIO_normalize);
