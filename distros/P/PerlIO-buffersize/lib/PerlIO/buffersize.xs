#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "perliol.h"

static IV PerlIOBufferSize_pushed(pTHX_ PerlIO *f, const char *mode, SV *arg, PerlIO_funcs *tab) {
	PerlIOBuf* buffer = PerlIOSelf(f, PerlIOBuf);
	if (!(PerlIOBase(f)->tab->kind & PERLIO_K_BUFFERED))
		Perl_warn(aTHX_ "Parent doesn't appear to be buffered, can't set buffer size");
	else if (buffer->buf)
		Perl_warn(aTHX_ "Can't set buffer size of handle that's already in use");
	else if (!arg || !SvOK(arg))
		Perl_warn(aTHX_ "No buffer size is given");
	else {
		buffer->bufsiz = SvIV(arg);
		return 0;
	}
	return -1;
}

static PerlIO* PerlIOBufferSize_open(pTHX_ PerlIO_funcs *self, PerlIO_list_t *layers, IV n, const char *mode, int fd, int imode, int perm, PerlIO *old, int narg, SV **args) {
	PerlIO_funcs * const tab = PerlIO_layer_fetch(aTHX_ layers, n - 1, NULL);
	if (tab && tab->Open) {
		PerlIO* ret = (*tab->Open)(aTHX_ tab, layers, n - 1, mode, fd, imode, perm, old, narg, args);
		if (ret && PerlIO_push(aTHX_ ret, self, mode, PerlIOArg) == NULL) {
			PerlIO_close(ret);
			return NULL;
		}
		return ret;
	}
	SETERRNO(EINVAL, LIB_INVARG);
	return NULL;
}

const PerlIO_funcs PerlIO_buffersize = {
	sizeof(PerlIO_funcs),
	"buffersize",
	0,
	0,
	PerlIOBufferSize_pushed,
	NULL,
	PerlIOBufferSize_open,
};

MODULE = PerlIO::buffersize				PACKAGE = PerlIO::socket

BOOT:
	PerlIO_define_layer(aTHX_ (PerlIO_funcs*)&PerlIO_buffersize);
