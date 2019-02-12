#ifndef __APPLE__
#error platform not supported
#endif

#include <sys/types.h>
#include <sys/socket.h>
#include <sys/uio.h>

#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

/*
 * The funky setting of in and out at the top is to get the fileno's of the
 * inputted Perl handles.
 * This allows us to input globs, or IO::Handle-like objects, or anything else
 * that we can get a fileno from.
 */

MODULE = Sys::Sendfile::OSX    PACKAGE = Sys::Sendfile::OSX::handle

SV *
sendfile(in, out, count = 0, offset = 0)
		int    in  = PerlIO_fileno(IoIFP(sv_2io(ST(0))));
		int    out = PerlIO_fileno(IoOFP(sv_2io(ST(1))));
		size_t count;
		size_t offset;
	CODE:
		off_t bytes = count;
		off_t off = offset;

		int ret = sendfile(in, out, off, &bytes, NULL, 0);

		if ((ret == -1) && (bytes == 0) && (errno != EINTR) && (errno != EAGAIN))
			XSRETURN_EMPTY;

		XSRETURN_IV(bytes);
