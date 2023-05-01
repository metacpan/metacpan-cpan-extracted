#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "perlio.h"
#include "perliol.h"

#include "eol.h"
#include "fill.h"
#include "write.h"

IV
PerlIOEOL_pushed(pTHX_ PerlIO *f, const char *mode, SV *arg, PerlIO_funcs *tab)
{
    PerlIOEOL *s = PerlIOSelf(f, PerlIOEOL);
    char *p, *eol_w = NULL, *eol_r = NULL;
    STRLEN len;

    if (PerlIOBase(PerlIONext(f))->flags & PERLIO_F_UTF8) {
        PerlIOBase(f)->flags |= PERLIO_F_UTF8;
    }
    else {
        PerlIOBase(f)->flags &= ~PERLIO_F_UTF8;
    }

    s->name = NULL;
    s->read.cr = s->write.cr = 0;
    s->read.seen = s->write.seen = 0;

    p = SvPV(arg, len);
    if (len) {
        char *end = p + len;
        Newz('e', eol_r, len + 1, char);
        Copy(p, eol_r, len, char);

        p = eol_r; end = p + len;
        for (; p < end; p++) {
            *p = toLOWER(*p);
            if ((*p == '-') && (eol_w == NULL)) {
                *p = '\0';
                eol_w = p+1;
            }
        }
    }
    else {
        Perl_die(aTHX_ "Must pass CRLF, CR, LF or Native to :eol().");
    }

    if (eol_w == NULL) { eol_w = eol_r; }

    EOL_AssignEOL( eol_r, s->read );
    EOL_AssignEOL( eol_w, s->write );

    Safefree( eol_r );

    return PerlIOBuf_pushed(aTHX_ f, mode, arg, tab);
}

STDCHAR *
PerlIOEOL_get_base(pTHX_ PerlIO *f)
{
    PerlIOBuf *b = PerlIOSelf(f, PerlIOBuf);
    if (!b->buf) {
        PerlIOEOL *s = PerlIOSelf(f, PerlIOEOL);

	if (!b->bufsiz)
	    b->bufsiz = 4096;

	b->buf = Newz( 'B', b->buf, b->bufsiz * ( (s->read.eol == EOL_CRLF) ? 2 : 1 ), STDCHAR );

	if (!b->buf) {
	    b->buf = (STDCHAR *) & b->oneword;
	    b->bufsiz = sizeof(b->oneword);
	}
	b->ptr = b->buf;
	b->end = b->ptr;
    }
    return b->buf;
}

void
PerlIOEOL_clearerr(pTHX_ PerlIO *f)
{
    PerlIOEOL *s;

    if (PerlIOValid(f)) {
        s = PerlIOSelf(f, PerlIOEOL);
        if (PerlIOBase(f)->flags & PERLIO_F_EOF) {
            s->read.cr = s->write.cr = 0;
            s->read.seen = s->write.seen = 0;
        }
    }

    PerlIOBase_clearerr(aTHX_ f);
}

SSize_t
PerlIOEOL_write(pTHX_ PerlIO *f, const void *vbuf, Size_t count)
{
    PerlIOEOL *s = PerlIOSelf(f, PerlIOEOL);
    const STDCHAR *i, *start = vbuf, *end = vbuf;

    end += (unsigned int)count;

    EOL_StartUpdate( s->write );

    if (!(PerlIOBase(f)->flags & PERLIO_F_CANWRITE)) { return 0; }

    EOL_Dispatch( s->write, WriteWithCR, WriteWithLF, WriteWithCRLF );

    if (start >= end) { return count; }

    return ( (start + PerlIOBuf_write(aTHX_ f, start, end - start)) - (STDCHAR*)vbuf );
}

IV
PerlIOEOL_fill(pTHX_ PerlIO * f)
{
    IV code = PerlIOBuf_fill(aTHX_ f);
    PerlIOEOL *s = PerlIOSelf(f, PerlIOEOL);
    PerlIOBuf *b = PerlIOSelf(f, PerlIOBuf);
    const STDCHAR *i, *start = b->ptr, *end = b->end;
    STDCHAR *buf = NULL, *ptr = NULL;

    if (code != 0) { return code; }

    EOL_StartUpdate( s->read );
    EOL_Dispatch( s->read, FillWithCR, FillWithLF, FillWithCRLF );

    if (buf == NULL) { return 0; }

    if (i > start) {
        Move(start, ptr, i - start, STDCHAR);
        ptr += i - start;
    }

    b->ptr = b->buf;
    b->end = b->buf + (ptr - buf);

    if (buf != b->buf) {
        Copy(buf, b->buf, ptr - buf, STDCHAR);
        Safefree(buf);
    }

    return 0;
}

PerlIO *
PerlIOEOL_open(pTHX_ PerlIO_funcs *self, PerlIO_list_t *layers,
               IV n, const char *mode, int fd, int imode, int perm,
               PerlIO *old, int narg, SV **args)
{
    SV *arg = (narg > 0) ? *args : PerlIOArg;
    PerlIO *f = PerlIOBuf_open( aTHX_ self, layers, n, mode, fd, imode, perm, old, narg, args );

    if (f) {
        PerlIOEOL *s = PerlIOSelf(f, PerlIOEOL);
        s->name = (STDCHAR *)savepv( SvPV_nolen(arg) );
    }

    return f;
}

PerlIO_funcs PerlIO_eol = {
    sizeof(PerlIO_funcs),
    "eol",
    sizeof(PerlIOEOL),
    PERLIO_K_BUFFERED | PERLIO_K_UTF8,
    PerlIOEOL_pushed,
    PerlIOBuf_popped,
    PerlIOEOL_open,
    PerlIOBase_binmode,
    NULL,
    PerlIOBase_fileno,
    PerlIOBuf_dup,
    PerlIOBuf_read,
    PerlIOBuf_unread,
    PerlIOEOL_write,
    PerlIOBuf_seek,
    PerlIOBuf_tell,
    PerlIOBuf_close,
    PerlIOBuf_flush,
    PerlIOEOL_fill,
    PerlIOBase_eof,
    PerlIOBase_error,
    PerlIOEOL_clearerr,
    PerlIOBase_setlinebuf,
    PerlIOEOL_get_base,
    PerlIOBuf_bufsiz,
    PerlIOBuf_get_ptr,
    PerlIOBuf_get_cnt,
    PerlIOBuf_set_ptrcnt
};

MODULE = PerlIO::eol            PACKAGE = PerlIO::eol

BOOT:
  #ifdef PERLIO_LAYERS
        PerlIO_define_layer(aTHX_ &PerlIO_eol);
  #endif

unsigned int
eol_is_mixed(arg)
        SV  *arg
    PROTOTYPE: $
    CODE:
        STRLEN len;
        register U8 *i, *end;
        register unsigned int seen = 0;
        i = (U8*)SvPV(arg, len);
        end = i + len;
        RETVAL = 0;
        for (; i < end; i++) {
            EOL_CheckForMixedCRLF( seen, EOL_Break, EOL_Seen( seen, EOL_CR, EOL_Break ), break, ( i++ ) );
        }
    OUTPUT:
        RETVAL

char *
CR()
    PROTOTYPE:
    CODE:
        RETVAL = "\015";
    OUTPUT:
        RETVAL

char *
LF()
    PROTOTYPE:
    CODE:
        RETVAL = "\012";
    OUTPUT:
        RETVAL

char *
CRLF()
    PROTOTYPE:
    CODE:
        RETVAL = "\015\012";
    OUTPUT:
        RETVAL

char *
NATIVE()
    PROTOTYPE:
    CODE:
        RETVAL = (
            (EOL_NATIVE == EOL_CR)   ? "\015" :
            (EOL_NATIVE == EOL_LF)   ? "\012" :
            (EOL_NATIVE == EOL_CRLF) ? "\015\012" : ""
        );
    OUTPUT:
        RETVAL
