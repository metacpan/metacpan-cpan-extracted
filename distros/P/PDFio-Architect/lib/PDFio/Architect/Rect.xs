#define PERL_NO_GET_CONTEXT // we'll define thread context if necessary (faster)
#include "EXTERN.h"         // globals/constant import locations
#include "perl.h"           // Perl symbols, structures and constants definition
#include "XSUB.h"           // xsubpp functions and macros
#include <pdfio.h> // PDFIO library header for PDF manipulation

MODULE = PDFio::Architect::Rect  PACKAGE = PDFio::Architect::Rect
PROTOTYPES: DISABLE

SV *
new(pkg, x1, y1, x2, y2)
	SV * pkg
	SV * x1
	SV * y1
	SV * x2
	SV * y2
	CODE:
		STRLEN retlen;
		char * pkg_name = SvPV(pkg, retlen);
		HV *hash = newHV();
		hv_store(hash, "x1", 2, x1, 0);
		hv_store(hash, "y1", 2, y1, 0);
		hv_store(hash, "x2", 2, x2, 0);
		hv_store(hash, "y2", 2, y2, 0);
		RETVAL = sv_bless(newRV_noinc((SV*)hash), gv_stashpv(pkg_name, 0));
	OUTPUT:
		RETVAL