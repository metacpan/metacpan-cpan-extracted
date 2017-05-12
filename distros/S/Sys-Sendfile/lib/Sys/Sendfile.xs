/*
 * This software is copyright (c) 2008, 2009 by Leon Timmermans <leont@cpan.org>.
 *
 * This is free software; you can redistribute it and/or modify it under
 * the same terms as perl itself.
 *
 */

#if defined linux || defined solaris || (defined (__SVR4) && defined (__sun))
#define OS_LINUX
#elif defined __FreeBSD__ || defined __FreeBSD_kernel__
#define OS_BSD
#elif defined __APPLE__
#define OS_X
#elif defined _WIN32
#define OS_WIN32
#else
#define OS_FALLBACK
#endif

#if defined OS_LINUX
#include <sys/sendfile.h>
#elif defined OS_BSD || defined OS_X
#include <sys/types.h>
#include <sys/socket.h>
#include <sys/uio.h>
#elif defined OS_WIN32
#include <windows.h>
#ifndef _MSC_VER
#include <mswsock.h>
#endif
#else
#include <sys/mman.h>
#endif

#ifndef _MSC_VER
#include <unistd.h>
#ifndef MAP_FILE
#define MAP_FILE 0
#endif
#endif

#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#define PERL_VERSION_ATLEAST(a,b,c)                        \
    (PERL_VERSION > (b)                                    \
     || (PERL_VERSION == (b) && PERL_SUBVERSION >= (c)))

#if defined(USE_SOCKETS_AS_HANDLES) || PERL_VERSION_ATLEAST(5,17,5)
#  define TO_SOCKET(x) _get_osfhandle(x)
#else
#  define TO_SOCKET(x) (x)
#endif /* USE_SOCKETS_AS_HANDLES */

MODULE = Sys::Sendfile				PACKAGE = Sys::Sendfile

SV*
sendfile(out, in, count = 0, offset = &PL_sv_undef)
	int out = PerlIO_fileno(IoOFP(sv_2io(ST(0))));
	int in  = PerlIO_fileno(IoIFP(sv_2io(ST(1))));
	size_t count;
	SV* offset;
	PROTOTYPE: **@
	CODE:
	{
	Off_t real_offset = SvOK(offset) ? SvUV(offset) : (off_t)lseek(in, 0, SEEK_CUR);
#if defined OS_LINUX
	if (count == 0) {
		struct stat info;
		if (fstat(in, &info) == -1)
			XSRETURN_EMPTY;
		count = info.st_size - real_offset;
	}
	{
		ssize_t success = sendfile(out, in, &real_offset, count);
		if (success == -1)
			XSRETURN_EMPTY;
		else
			XSRETURN_IV(success);
	}
#elif defined OS_BSD
	off_t bytes;
	int ret = sendfile(in, out, real_offset, count, NULL, &bytes, 0);
	if (ret == -1 && bytes == 0 && ! (errno == EAGAIN || errno == EINTR))
		XSRETURN_EMPTY;
	else
		XSRETURN_IV(bytes);
#elif defined OS_X
	off_t bytes = count;
	int ret = sendfile(in, out, real_offset, &bytes, NULL, 0);
	if (ret == -1 && bytes == 0 && ! (errno == EAGAIN || errno == EINTR))
		XSRETURN_EMPTY;
	else
		XSRETURN_IV(bytes);
#elif defined OS_WIN32
	HANDLE hFile = TO_SOCKET(in);
	int ret;
	if (SvOK(offset))
		SetFilePointer(hFile, real_offset, NULL, FILE_BEGIN);
	ret = TransmitFile(TO_SOCKET(out), hFile, (DWORD)count, 0, NULL, NULL, 0);
	if (!ret)
		XSRETURN_EMPTY;
	else
		XSRETURN_IV(count);
#else
	void* buffer;
	int ret;
	if (count == 0) {
		struct stat info;
		if (fstat(in, &info) == -1)
			XSRETURN_EMPTY;
		count = info.st_size - real_offset;
	}
	buffer = mmap(NULL, count, PROT_READ, MAP_SHARED | MAP_FILE, in, real_offset);
	if (buffer == MAP_FAILED)
		XSRETURN_EMPTY;
	ret = write(out, buffer, count);
	if (ret == -1)
		XSRETURN_EMPTY;
	else
		XSRETURN_IV(ret);
#endif
	}
