#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

/* Pretty straightforward routines to get and set the value
 * of PL_signal. Not supposed to be compiled on pre-5.8.1 perls.
 */

MODULE = Perl::Unsafe::Signals	PACKAGE = Perl::Unsafe::Signals	PREFIX = pus_

PROTOTYPES: DISABLE

U32
pus_push_unsafe_flag()
    CODE:
	RETVAL = PL_signals;
	PL_signals |= PERL_SIGNALS_UNSAFE_FLAG;
    OUTPUT:
	RETVAL

void
pus_pop_unsafe_flag(saved)
    U32 saved
    CODE:
	PL_signals = saved;

U32
pus_get_unsafe_flag()
    CODE:
	RETVAL = PL_signals;
    OUTPUT:
	RETVAL
