/*
 * This software is copyright (c) 2010 by Leon Timmermans <leont@cpan.org>.
 *
 * This is free software; you can redistribute it and/or modify it under
 * the same terms as perl itself.
 *
 */

#define PERL_NO_GET_CONTEXT
#define PERL_REENTR_API 1
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <sys/mman.h>
#include <sys/stat.h>        /* For mode constants */
#include <fcntl.h>           /* For O_* constants */
#include <string.h>

static SV* S_io_fdopen(pTHX_ int fd) {
	PerlIO* pio = PerlIO_fdopen(fd, "r");
	GV* gv = newGVgen("POSIX::RT::SharedMem");
	SV* ret = newRV_noinc((SV*)gv);
	IO* io = GvIOn(gv);
	IoTYPE(io) = '<';
	IoIFP(io) = pio;
	IoOFP(io) = pio;
	return ret;
}
#define io_fdopen(fd) S_io_fdopen(aTHX_ fd)

#define ERRBUFSIZE 128

MODULE = POSIX::RT::SharedMem				PACKAGE = POSIX::RT::SharedMem

PROTOTYPES: DISABLE

SV* _shm_open(name, flags, mode)
	const char* name;
	int flags;
	int mode;
	PREINIT:
		int ret;
	CODE:
		ret = shm_open(name, flags, mode);
		if (ret == -1)
			Perl_croak(aTHX_ "Can't open shared memory object %s: %s", name, strerror(errno));
		RETVAL = io_fdopen(ret);
	OUTPUT:
		RETVAL
		

void shared_unlink(name);
	const char* name;
	CODE:
		if (shm_unlink(name) == -1)
			Perl_croak(aTHX_ "Can't unlink shared memory '%s': %s", name, strerror(errno));
