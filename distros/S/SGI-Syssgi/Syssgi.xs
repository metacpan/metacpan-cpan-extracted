#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "sgi-syssgi.h"

static int
not_here(s)
char *s;
{
    croak("%s not implemented on this architecture", s);
    return -1;
}

static char *
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
	if (strEQ(name, "NVRAM_INITSTATE"))
#ifdef NVRAM_INITSTATE
	    return NVRAM_INITSTATE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "NVRAM_PATH"))
#ifdef NVRAM_PATH
	    return NVRAM_PATH;
#else
	    goto not_there;
#endif
	if (strEQ(name, "NVRAM_SHOWCONFIG"))
#ifdef NVRAM_SHOWCONFIG
	    return NVRAM_SHOWCONFIG;
#else
	    goto not_there;
#endif
	if (strEQ(name, "NVRAM_SWAP"))
#ifdef NVRAM_SWAP
	    return NVRAM_SWAP;
#else
	    goto not_there;
#endif
	if (strEQ(name, "NVRAM_VERBOSE"))
#ifdef NVRAM_VERBOSE
	    return NVRAM_VERBOSE;
#else
	    goto not_there;
#endif
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


MODULE = SGI::Syssgi		PACKAGE = SGI::Syssgi		
PROTOTYPES: Enable

char *
_SGI_SYSID()

char *
_SGI_RDNAME(process_id)
	int 		process_id
	
char *
_SGI_GETNVRAM(prom_variable)
	char 		*prom_variable

int
_SGI_SETLED(led_state)
	int		led_state

int
_SGI_SETNVRAM(prom_variable,prom_value)
	char 		*prom_variable
	char 		*prom_value
	
int
_SGI_SSYNC()

int
_SGI_BDFLUSHCNT(kern_write_delay)
	unsigned int	kern_write_delay

int
_SGI_SET_AUTOPWRON(power_on)
	double 		power_on
	
int
_SGI_GETTIMETRIM()

int
_SGI_SETTIMETRIM(timetrim_value)
	int 	timetrim_value

