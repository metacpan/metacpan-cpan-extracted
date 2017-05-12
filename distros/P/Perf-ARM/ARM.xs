#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
}
#endif

#include <arm.h>

/*
 * NOTE: the ARM.xs file is currently just directed at HPUX 11.0
 * installations and has only been testing on that OS
 */

static int
not_here(s)
char *s;
{
    croak("%s not implemented on this architecture", s);
    return -1;
}

static double
constant(name, arg)
char *name;
int arg;
{
    errno = 0;
    switch (*name) {
    case 'A':
	break;
    case 'B':
	break;
    case 'C':
	break;
    case 'D':
	break;
    case 'E':
	break;
    case 'F':
	break;
    case 'G':
	break;
    case 'H':
	break;
    case 'I':
	break;
    case 'J':
	break;
    case 'K':
	break;
    case 'L':
	break;
    case 'M':
	break;
    case 'N':
	break;
    case 'O':
	break;
    case 'P':
	break;
    case 'Q':
	break;
    case 'R':
	break;
    case 'S':
	break;
    case 'T':
	break;
    case 'U':
	break;
    case 'V':
	break;
    case 'W':
	break;
    case 'X':
	break;
    case 'Y':
	break;
    case 'Z':
	break;
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}


MODULE = Perf::ARM		PACKAGE = Perf::ARM

double
constant(name,arg)
	char *		name
	int		arg


long
arm_init(appl_name, appl_user_id, flags, data, data_size)
	char *	appl_name
	char *	appl_user_id
	long	flags
	char *	data
	long	data_size

long
arm_getid(appl_id, tran_name, tran_detail, flags, data, data_size)
	long	appl_id
	char *	tran_name
	char *	tran_detail
	long	flags
	char *	data
	long	data_size

long
arm_start(tran_id, flags, data, data_size)
	long	tran_id
	long	flags
	char *	data
	long	data_size

long
arm_update(start_handle, flags, data, data_size)
	long	start_handle
	long	flags
	char *	data
	long	data_size

long
arm_stop(start_handle, tran_status, flags, data, data_size)
	long	start_handle
	long	tran_status
	long	flags
	char *	data
	long	data_size

long
arm_end(appl_id, flags, data, data_size)
	long	appl_id
	long	flags
	char *	data
	long	data_size
