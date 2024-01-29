#define PERL_NO_GET_CONTEXT     /* we want efficiency */
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <tcl.h>
#include <tix.h>

typedef Tcl_Interp *Tcl;

MODULE = Tcl::Tk::Tkwidget::Tix	PACKAGE = Tcl::Tk::Tkwidget::Tix

PROTOTYPES: DISABLE

int
Tix_Init(interp)
	Tcl	interp
    CODE:
	RETVAL = Tix_Init(interp);
    OUTPUT:
	RETVAL
