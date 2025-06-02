#define PERL_NO_GET_CONTEXT // we'll define thread context if necessary (faster)
#include "EXTERN.h"         // globals/constant import locations
#include "perl.h"           // Perl symbols, structures and constants definition
#include "XSUB.h"           // xsubpp functions and macros
#include <pdfio.h> // PDFIO library header for PDF manipulation

MODULE = PDFio::Architect  PACKAGE = PDFio::Architect
PROTOTYPES: DISABLE

SV *
new(pkg, filename, ...)
	SV * pkg
	SV * filename
	CODE:
		STRLEN retlen;
		char * name = SvPV(pkg, retlen);
		size_t name_len = strlen(name);
		char *method = malloc(retlen + 10);
		sprintf(method, "%s::File::new", name);

		SV *hash;
		dSP; // initialize stack pointer

		ENTER;
		SAVETMPS;

		PUSHMARK(SP);
		SvREFCNT_inc(pkg);
		SvREFCNT_inc(filename);
		XPUSHs(pkg);
		XPUSHs(filename);
		PUTBACK;

		call_pv(method, G_SCALAR | G_EVAL);
		SPAGAIN;

		if (SvTRUE(ERRSV)) {
			LEAVE;
			PUTBACK;
			croak("%s", SvPV_nolen(ERRSV));
		}

		hash = POPs;
		SvREFCNT_inc(hash);

		PUTBACK;
		FREETMPS;
		LEAVE;

		RETVAL = hash;
	OUTPUT:
		RETVAL


