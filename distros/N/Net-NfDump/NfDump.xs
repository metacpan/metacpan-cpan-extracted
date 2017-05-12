#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "libnf_perl/libnf_perl.h"

#include "const-c.inc"

/* #include <sys/vfs.h> */

#define MATH_INT64_NATIVE_IF_AVAILABLE 1
#include "perl_math_int64.h"

MODULE = Net::NfDump		PACKAGE = Net::NfDump

BOOT:
#ifndef MATH_INT64_NATIVE 
	MATH_INT64_BOOT;
#endif 

INCLUDE: const-xs.inc


SV * 
libnf_file_info(file)
	char * file


int 
libnf_init()


SV * 
libnf_instance_info(handle)
	int handle


int 
libnf_read_files(handle, filter, window_start, window_end, files)
	int handle
	char *filter
	int window_start
	int window_end
	SV * files


SV *
libnf_read_row(handle)
	int handle


int 
libnf_create_file(handle, filename, compressed, anonymized, ident)
	int handle 
	char *filename
	int compressed
	int anonymized
	char *ident


int 
libnf_set_fields(handle, fields)
	int handle
	SV * fields


int 
libnf_aggr_add(handle, field, flags, numbits, numbits6)
	int handle
	int field
	int flags
	int numbits 
	int numbits6


int 
libnf_listmode(handle)
	int handle


int 
libnf_compatmode(handle)
	int handle


int
libnf_copy_row(handle, src_handle)
	int handle
	int src_handle


int 
libnf_write_row(handle, arrayref)
	int handle
	SV * arrayref


void 
libnf_finish(handle)
	int handle


