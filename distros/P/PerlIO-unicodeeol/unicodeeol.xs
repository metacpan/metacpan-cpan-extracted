#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "perlio.h"
#include "perliol.h"

#include "unicodeeol.h"

IV
PerlIO_UnicodeEOL_pushed(pTHX_ PerlIO *f, const char *mode, SV *arg, PerlIO_funcs *tab)
{
    UnicodeEOL *self = PerlIOSelf(f, UnicodeEOL);
    STDCHAR *p;
    STRLEN len;
    
    if (PerlIOBase(PerlIONext(f))->flags & PERLIO_F_UTF8)
        PerlIOBase(f)->flags |= PERLIO_F_UTF8;
    else
        PerlIOBase(f)->flags &= ~PERLIO_F_UTF8;

    self->previous = 0;

    if (arg && SvPOK(arg) && SvLEN(arg))
        Perl_die(aTHX_ "unicodeeol does not take any arguments");

    return PerlIOBuf_pushed(aTHX_ f, mode, arg, tab);
}

static inline void unshift(PerlIOBuf * buf, const SSize_t count)
{
    STDCHAR *newbuf;
    const SSize_t size = buf->end - buf->ptr;
    Newx(newbuf, size + count, STDCHAR);
    Copy(buf->ptr, newbuf + count, size, STDCHAR);
    Safefree(buf->buf);
    buf->ptr = buf->buf = newbuf;
    buf->bufsiz = size + 1;
    buf->end = buf->buf + size + 1;
}

IV
PerlIO_UnicodeEOL_fill(pTHX_ PerlIO * f)
{
    IV code = PerlIOBuf_fill(aTHX_ f);
    UnicodeEOL *self = PerlIOSelf(f, UnicodeEOL);
    PerlIOBuf *b = PerlIOSelf(f, PerlIOBuf);
    bool last_was_cr = FALSE;
    bool UTF = (PerlIOBase(f)->flags & PERLIO_F_UTF8 ? TRUE : FALSE); /* cBOOL */
    unsigned char *out = b->ptr, *in = b->ptr, *end = b->end;

    if (code) return code;

    /* If the last fill ended on something guaranteed incomplete,
       like the middle of a UTF-8 codepoint, or possibly incomplete,
       specifically a \r *may* be followed by \n, so \r at the end
       of a buffer will immediatly become \n, and if the next buffer
       starts with \n, it should silently be ignored */
    switch (self->previous) {
        case '\r':
            if (*in == '\n')
                out = in = ++b->ptr;
            break;
        case 0xc2:
            if (*in == 0x85) {
                *in = '\n';
            } else {
                const SSize_t size = b->end - b->ptr;
                unshift(b, 1);
                end = b->end;
                out = b->ptr;
                *out++ = 0xc2;
                in = out;
            }
            break;
        case 0x80:
            if (*in == 0xa8 || *in == 0xa9) {
                *in = '\n';
            } else {
                unshift(b, 2);
                end = b->end;
                out = b->ptr;
                *out++ = 0xc2;
                *out++ = 0x80;
                in = out;
            }
            break;
        case 0xe2:
            if (*in == 0x80 && (in+1<end) && (*(in+1) == 0xa8 || *(in+1) == 0xa9)) {
                out = in = b->ptr += 1;
                *out = '\n';
            } else {
                unshift(b, 1);
                end = b->end;
                out = b->ptr;
                *out++ = 0xe2;
                in = out;
            }
            break;
    }
    self->previous = 0;

    while (in != end) {
        bool set_newline = FALSE;
        switch (*in) {
            case 0x0a: 
                if (last_was_cr) out--;
            case 0x0b:
            case 0x0c:
            case 0x0d:
                set_newline = TRUE;
                break;
            case 0xc2: /* 0xc2 0x85 is \u{85}, one of the \R codepoints */
                if (UTF) {
                    if (in + 1 == end) {
                        self->previous = 0xc2;
                        out--; /* Pretend we didn't see this byte */
                    } else {
                        if (*(in + 1) == 0x85) {
                            set_newline = TRUE;
                            in++;
                        } else {
                            *out++ = *in++;
                            *out = *in;
                        }
                    }
                } else {
                    *out = *in;
                }
                break;
            case 0xe2: /* 0xe2 0x80 0xa8 AND 0xe2 0x80 0xa9, \u{2028} and \u{2029} */
                if (UTF) {
                    if (in + 1 == end) {
                        self->previous = 0xe2;
                        b->end = in;
                        return 0;
                    } else if (*(in + 1) == 0x80) {
                        if (in + 2 == end) {
                            self->previous = 0x80;
                            b->end = in;
                            return 0;
                        } else {
                            if (*(in + 2) == 0xa8 || *(in + 2) == 0xa9) {
                                set_newline = TRUE;
                                in += 2;
                            } else {
                                *out++ = *in++;
                                *out++ = *in++;
                                *out = *in;
                            }
                        }
                    } else {
                        *out++ = *in++;
                        *out = *in;
                    }
                } else { /* Not UTF-8 */
                    *out = *in;
                }
            default:
                *out = *in;
                break;
        }
        if (*in == 0x0d)
            last_was_cr = TRUE;
        else
            last_was_cr = FALSE;
        if (set_newline)
            *out = '\n';
        out++, in++;
    }

    if (out != end)
        b->end = out;

    if (last_was_cr)
        self->previous = '\r';

    return 0;
}

PerlIO_funcs PerlIO_unicodeeol = {
    sizeof(PerlIO_funcs),
    "unicodeeol",
    sizeof(UnicodeEOL),
    PERLIO_K_BUFFERED | PERLIO_K_UTF8, 
    PerlIO_UnicodeEOL_pushed,
    PerlIOBuf_popped,
    PerlIOBuf_open,
    PerlIOBase_binmode,
    NULL,
    PerlIOBase_fileno,
    PerlIOBuf_dup,
    PerlIOBuf_read,
    PerlIOBuf_unread,
    PerlIOBuf_write,
    PerlIOBuf_seek,
    PerlIOBuf_tell,
    PerlIOBuf_close,
    PerlIOBuf_flush,
    PerlIO_UnicodeEOL_fill,
    PerlIOBase_eof,
    PerlIOBase_error,
    PerlIOBase_clearerr,
    PerlIOBase_setlinebuf,
    PerlIOBuf_get_base,
    PerlIOBuf_bufsiz,
    PerlIOBuf_get_ptr,
    PerlIOBuf_get_cnt,
    PerlIOBuf_set_ptrcnt
};

/* vim:set ts=8 sts=4 et: */

MODULE = PerlIO::unicodeeol            PACKAGE = PerlIO::unicodeeol

BOOT:  
#ifdef PERLIO_LAYERS
    PerlIO_define_layer(aTHX_ &PerlIO_unicodeeol);
#else
    Perl_die(aTHX_ "PerlIO layers are not supported");
#endif

