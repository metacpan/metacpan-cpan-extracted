#define PERL_NO_GET_CONTEXT 1
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "perliol.h"

#ifndef PERL_UNUSED_ARG
# define PERL_UNUSED_ARG(x) PERL_UNUSED_VAR(x)
#endif /* !PERL_UNUSED_ARG */

#ifndef Newx
# define Newx(v,n,t) New(0,v,n,t)
#endif /* !Newx */

struct PerlIOrewindable {
	struct _PerlIO base;
	Size_t bufsize;
	Size_t filled;
	Size_t position;
	U8 *buffer;
};

static IV PerlIOrewindable_pushed(pTHX_ PerlIO *f, char const *mode, SV *arg,
	PerlIO_funcs *funcs)
{
	struct PerlIOrewindable *rw = PerlIOSelf(f, struct PerlIOrewindable);
	PERL_UNUSED_ARG(arg);
	{
		IV result = PerlIOBase_pushed(aTHX_ f, mode, NULL, funcs);
		if(result != 0) return result;
	}
	rw->bufsize = 1;
	rw->filled = 0;
	rw->position = 0;
	Newx(rw->buffer, 1, U8);
	return 0;
}

static IV PerlIOrewindable_popped(pTHX_ PerlIO *f)
{
	struct PerlIOrewindable *rw = PerlIOSelf(f, struct PerlIOrewindable);
	if(rw->position != rw->filled) {
		PerlIOBase_unread(aTHX_ PerlIONext(f),
			rw->buffer + rw->position, rw->filled - rw->position);
	}
	Safefree(rw->buffer);
	return 0;
}

static SSize_t PerlIOrewindable_read(pTHX_ PerlIO *f, void *vbuf, Size_t count)
{
	struct PerlIOrewindable *rw = PerlIOSelf(f, struct PerlIOrewindable);
	U8 *cbuf = vbuf;
	Size_t pos = rw->position;
	SSize_t done = 0;
	if(pos != rw->filled) {
		Size_t avail = rw->filled - pos;
		if(avail > count) avail = count;
		Copy(rw->buffer + pos, cbuf, avail, U8);
		pos += avail;
		cbuf += avail;
		count -= avail;
		done = avail;
	}
	if(count) {
		SSize_t avail = PerlIO_read(PerlIONext(f), cbuf, count);
		Size_t endpos;
		if(avail < 0)
			return avail;
		endpos = pos + avail;
		if(endpos > rw->bufsize) {
			Size_t bufsize = rw->bufsize;
			do {
				bufsize <<= 1;
			} while(endpos > bufsize);
			Renew(rw->buffer, bufsize, U8);
			rw->bufsize = bufsize;
		}
		Copy(cbuf, rw->buffer + pos, avail, U8);
		rw->filled = pos = endpos;
		done += avail;
	}
	rw->position = pos;
	return done;
}

static IV PerlIOrewindable_seek(pTHX_ PerlIO *f, Off_t off, int whence)
{
	struct PerlIOrewindable *rw = PerlIOSelf(f, struct PerlIOrewindable);
	switch(whence) {
		case 1: {
			off += rw->position;
		} /* fall through */
		case 0: {
			if(off < 0 || off > (Off_t)rw->filled) {
				errno = EINVAL;
				return -1;
			}
			rw->position = (Size_t)off;
			return 0;
		} break;
		default: {
			errno = EINVAL;
			return -1;
		} break;
	}
}

static Off_t PerlIOrewindable_tell(pTHX_ PerlIO *f)
{
	struct PerlIOrewindable *rw = PerlIOSelf(f, struct PerlIOrewindable);
	return rw->position;
}

static PerlIO_funcs PerlIOrewindable_funcs = {
	sizeof(PerlIO_funcs),
	"rewindable",
	sizeof(struct PerlIOrewindable),
	0,
	PerlIOrewindable_pushed,
	PerlIOrewindable_popped,
	NULL /*open*/,
	NULL /*binmode*/,
	NULL /*getarg*/,
	NULL /*fileno*/,
	NULL /*dup*/,
	PerlIOrewindable_read,
	NULL /*unread*/,
	NULL /*write*/,
	PerlIOrewindable_seek,
	PerlIOrewindable_tell,
	NULL /*close*/,
	NULL /*flush*/,
	NULL /*fill*/,
	NULL /*eof*/,
	NULL /*error*/,
	NULL /*clearerr*/,
	NULL /*setlinebuf*/,
	NULL /*get_base*/,
	NULL /*get_bufsiz*/,
	NULL /*get_ptr*/,
	NULL /*get_cnt*/,
	NULL /*set_ptrcnt*/,
};

MODULE = PerlIO::rewindable PACKAGE = PerlIO::rewindable

PROTOTYPES: DISABLE

BOOT:
	PerlIO_define_layer(aTHX_ &PerlIOrewindable_funcs);
