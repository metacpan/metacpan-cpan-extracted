#define PERL_NO_GET_CONTEXT // we'll define thread context if necessary (faster)
#include "EXTERN.h"         // globals/constant import locations
#include "perl.h"           // Perl symbols, structures and constants definition
#include "XSUB.h"           // xsubpp functions and macros
#include <pdfio.h> // PDFIO library header for PDF manipulation
#include <pdfio-content.h>


MODULE = PDFio::Architect::Font::_Font  PACKAGE = PDFio::Architect::Font::_Font
PROTOTYPES: DISABLE


MODULE = PDFio::Architect::Font  PACKAGE = PDFio::Architect::Font
PROTOTYPES: DISABLE

SV *
new(pkg, file, alias, font_name)
	SV * pkg
	SV * file
	SV * alias
	SV * font_name
	CODE:
		STRLEN retlen;
		char * pkg_name = SvPV(pkg, retlen);
		HV *hash = newHV();

		HV *self = (HV*)SvRV(file);
		
		SvREFCNT_inc(font_name);
		hv_store(hash, "name", 4, font_name, 0);
		SvREFCNT_inc(alias);
		hv_store(hash, "alias", 5, alias, 0);
		SV **file_sv = hv_fetch(self, "file", 4, 0);
		if (!file_sv || !SvROK(*file_sv)) {
			croak("file not initialized");
		}
		pdfio_file_t *pdf_file = INT2PTR(pdfio_file_t*, SvUV(SvRV(*file_sv)));

		pdfio_obj_t *font = pdfioFileCreateFontObjFromBase(pdf_file, SvPV(font_name, retlen));

		SV * font_sv = sv_bless(
			newRV_noinc(newSVuv(PTR2UV(font))), gv_stashpv("PDFio::Architect::Font::_Font", 1)
		);

		hv_store(hash, "font", 4, font_sv, 0);
		SvREFCNT_inc(font_sv);

		RETVAL = sv_bless(newRV_noinc((SV*)hash), gv_stashpv(pkg_name, 0));
	OUTPUT:
		RETVAL
