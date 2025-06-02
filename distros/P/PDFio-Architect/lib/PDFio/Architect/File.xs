#define PERL_NO_GET_CONTEXT // we'll define thread context if necessary (faster)
#include "EXTERN.h"         // globals/constant import locations
#include "perl.h"           // Perl symbols, structures and constants definition
#include "XSUB.h"           // xsubpp functions and macros
#include <pdfio.h> // PDFIO library header for PDF manipulation
#include "architect.h"

bool
error_cb(pdfio_file_t *pdf, const char *message, void *data){
	(void)data; // This callback does not use the data pointer

	fprintf(stderr, "%s: %s\n", pdfioFileGetName(pdf), message);

	// Return true for warning messages (continue) and false for errors (stop)
	return (!strncmp(message, "WARNING:", 8));
}

MODULE = PDFio::Architect::File::_Dict  PACKAGE = PDFio::Architect::File::_Dict
PROTOTYPES: DISABLE

SV *
set(self, key, value)
	HV * self
	SV * key
	SV * value
	CODE:
		if (!SvROK(self) || SvTYPE(SvRV(self)) != SVt_PVHV) {
			croak("self must be a PDFio::Architect::File::_Dict object");
		}
		if (!SvOK(key)) {
			croak("key must be a valid string");
		}
		if (!SvOK(value)) {
			croak("value must be a valid string");
		}
		
		hv_store((HV*)SvRV(self), SvPV_nolen(key), SvCUR(key), value, 0);
		SvREFCNT_inc(value);
		SvREFCNT_inc(key);
		RETVAL = value;
	OUTPUT:
		RETVAL

SV *
get(self, key)
	HV * self
	SV * key
	CODE:
		if (!SvROK(self) || SvTYPE(SvRV(self)) != SVt_PVHV) {
			croak("self must be a PDFio::Architect::File::_Dict object");
		}
		if (!SvOK(key)) {
			croak("key must be a valid string");
		}
		
		SV **value_sv = hv_fetch((HV*)SvRV(self), SvPV_nolen(key), SvCUR(key), 0);
		if (!value_sv) {
			croak("key '%s' not found in dictionary", SvPV_nolen(key));
		}
		
		SvREFCNT_inc(*value_sv);
		RETVAL = *value_sv;
	OUTPUT:
		RETVAL

MODULE = PDFio::Architect::File::_File  PACKAGE = PDFio::Architect::File::_File
PROTOTYPES: DISABLE

MODULE = PDFio::Architect::File  PACKAGE = PDFio::Architect::File
PROTOTYPES: DISABLE

SV *
new(pkg, filename, ...)
	SV * pkg
	SV * filename
	CODE:
		STRLEN retlen;
		char * pkg_name = SvPV(pkg, retlen);
		HV *hash = newHV();
		
		SvREFCNT_inc(filename);
		hv_store(hash, "filename", 8, filename, 0);

		HV * dict_hash = newHV();

		SV *crop_box_sv = new_rect(pkg_name, retlen, 0.0, 0.0, 595.0, 842.0);
		hv_store(dict_hash, "CropBox", 8, crop_box_sv, 0);

		SV *media_box_sv = new_rect(pkg_name, retlen, 0.0, 0.0, 595.0, 842.0);
		hv_store(dict_hash, "MediaBox", 8, media_box_sv, 0);

		SV * dict = sv_bless(
			newRV_noinc((SV*)dict_hash), gv_stashpv("PDFio::Architect::File::_Dict", 1)
		);
		hv_store(hash, "dict", 4, dict, 0);

		char *filename_char = SvPV(filename, retlen);

		SvREFCNT_inc(crop_box_sv);
		SvREFCNT_inc(media_box_sv);
		
		pdfio_rect_t crop_box = rect_to_pdfio_rect(crop_box_sv);
		pdfio_rect_t media_box = rect_to_pdfio_rect(media_box_sv);

		char *tmpfilename = malloc(retlen + 4);
		sprintf(tmpfilename, "%s.tmp", filename_char);
		hv_store(hash, "tmpfilename", 11, newSVpv(tmpfilename, retlen + 4), 0);
		char * errstr;

		pdfio_file_t *pdf_file = pdfioFileCreate(tmpfilename, "2.0", &media_box, &crop_box, error_cb, errstr );
	
		SV * file = sv_bless(
			newRV_noinc(newSViv(PTR2UV(pdf_file))), gv_stashpv("PDFio::Architect::File::_File", 1)
		);
		hv_store(hash, "file", 4, file, 0);
		
		RETVAL = sv_bless(newRV_noinc((SV*)hash), gv_stashsv(newSVpvf("%s::File", pkg_name), 0));
	OUTPUT:
		RETVAL

SV *
add_page(self, ...)
	SV * self
	CODE:
		if (!self || !SvROK(self) || SvTYPE(SvRV(self)) != SVt_PVHV) {
			croak("self must be a PDFio::Architect::File object");
		}
		dSP;
		
		SV * page;
		char * name = HvNAME(SvSTASH(SvRV(self)));
		name = strdup(name);
		size_t name_len = strlen(name);
		name[name_len - 4] = '\0';	
		char *page_pkg = malloc(name_len + 5);
		sprintf(page_pkg, "%sPage", name);
		SV * pkg = newSVpv(page_pkg, strlen(page_pkg));
		char *method = malloc(name_len + 10);
		sprintf(method, "%sPage::new", name);
		
		SV *args;
		if (items > 1) {
			args = ST(1);
			if (!SvROK(args) || SvTYPE(SvRV(args)) != SVt_PVHV) {
				croak("args must be an hash reference");
			}
		} else {
			args = newRV_noinc(newHV());
		}

		ENTER;
		SAVETMPS;

		PUSHMARK(SP);
		SvREFCNT_inc(pkg);
		SvREFCNT_inc(self);
		SvREFCNT_inc(args);
		XPUSHs(pkg);
		XPUSHs(self);
		XPUSHs(args);
		PUTBACK;
		call_pv(method, G_SCALAR | G_EVAL);
		SPAGAIN;

		if (SvTRUE(ERRSV)) {
			LEAVE;
			PUTBACK;
			croak("%s", SvPV_nolen(ERRSV));
		}

		page = POPs;
		SvREFCNT_inc(page);
		PUTBACK;
		FREETMPS;
		LEAVE;

		hv_store((HV*)SvRV(self), "current_page", 12, newSVsv(page), 0);
		
		RETVAL = page;
	OUTPUT:
		RETVAL

SV *
load_font(self, font_alias, font_type)
	SV * self
	SV * font_alias
	SV * font_type
	CODE:
		if (!SvROK(self) || SvTYPE(SvRV(self)) != SVt_PVHV) {
			croak("self must be a PDFio::Architect::File object");
		}
		if (!SvOK(font_type) || SvTYPE(font_type) != SVt_PV) {
			croak("font must be a valid string");
		}
		dSP; 
		SV * font;
		char * name = HvNAME(SvSTASH(SvRV(self)));
		name = strdup(name);
		size_t name_len = strlen(name);
		name[name_len - 4] = '\0';
		char *font_pkg = malloc(name_len + 6);
		sprintf(font_pkg, "%sFont", name);
		SV * pkg = newSVpv(font_pkg, strlen(font_pkg));
		char *method = malloc(name_len + 10);
		sprintf(method, "%sFont::new", name);
		
		ENTER;
		SAVETMPS;

		PUSHMARK(SP);
		SvREFCNT_inc(pkg);
		SvREFCNT_inc(self);
		SvREFCNT_inc(font_alias);
		SvREFCNT_inc(font_type);
		XPUSHs(pkg);
		XPUSHs(self);
		XPUSHs(font_alias);
		XPUSHs(font_type);
		PUTBACK;
		call_pv(method, G_SCALAR | G_EVAL);
		SPAGAIN;

		if (SvTRUE(ERRSV)) {
			LEAVE;
			PUTBACK;
			croak("%s", SvPV_nolen(ERRSV));
		}

		font = POPs;
		SvREFCNT_inc(font);
		PUTBACK;
		FREETMPS;
		LEAVE;

		SV * dict = *hv_fetch((HV*)SvRV(self), "dict", 4, 0);
		STRLEN retlen;
		char * font_char = SvPV(font_alias, retlen);
		hv_store((HV*)SvRV(dict), font_char, retlen, font, 0);
		
		SvREFCNT_inc(font);
		RETVAL = font;
	OUTPUT:
		RETVAL

SV *
new_rect(pkg, x1, y1, x2, y2)
	SV * pkg
	SV * x1
	SV * y1
	SV * x2
	SV * y2
	CODE:
		STRLEN retlen;
		char * pkg_name = SvPV(pkg, retlen);
		char *pos = strstr(pkg_name, "::File");
		if (pos)
			*pos = '\0';
		RETVAL = new_rect(pkg_name, retlen, SvNV(x1), SvNV(y1), SvNV(x2), SvNV(y2));
	OUTPUT:
		RETVAL

SV *
total_pages(self)
	SV * self
	CODE:
		if (!self || !SvROK(self) || SvTYPE(SvRV(self)) != SVt_PVHV) {
			croak("self must be a PDFio::Architect::File object");
		}
		HV * self_hv = (HV*)SvRV(self);
		SV **file_sv = hv_fetch(self_hv, "file", 4, 0);
		if (!file_sv || !SvROK(*file_sv)) {
			croak("file not initialized");
		}
		pdfio_file_t *pdf_file = INT2PTR(pdfio_file_t*, SvUV(SvRV(*file_sv)));
		if (!pdf_file) {
			croak("PDF file pointer is NULL");
		}
		int total_pages = pdfioFileGetNumPages(pdf_file);
		SvREFCNT_inc(self);
		RETVAL = newSViv(total_pages);
	OUTPUT:
		RETVAL

SV *
save(self, ...)
	SV * self
	CODE:
		if (!self || !SvROK(self) || SvTYPE(SvRV(self)) != SVt_PVHV) {
			croak("self must be a PDFio::Architect::File object");
		}
		HV * self_hv = (HV*)SvRV(self);
		SV **file_sv = hv_fetch(self_hv, "file", 4, 0);
		if (!file_sv || !SvROK(*file_sv)) {
			croak("file not initialized");
		}
		
		pdfio_file_t *pdf_file = INT2PTR(pdfio_file_t*, SvUV(SvRV(*file_sv)));
		
		char *filename_char;
		if (items > 1) {
			filename_char = SvPV(ST(1), PL_na);
		} else {
			SV **filename_sv = hv_fetch(self_hv, "filename", 8, 0);
			if (!filename_sv || !SvOK(*filename_sv)) {
				croak("filename not provided and not stored in object");
			}
			filename_char = SvPV(*filename_sv, PL_na);
		}

		if (!pdf_file) {
			croak("PDF file pointer is NULL");
		}

		if (!pdfioFileClose(pdf_file)) {
			croak("Failed to save PDF file: %s", filename_char);
		}

		char *tmpfilename = SvPV(*hv_fetch(self_hv, "tmpfilename", 11, 0), PL_na);

		if (rename(tmpfilename, filename_char) != 0) {
			croak("Failed to move temporary file to destination: %s", strerror(errno));
		}

		hv_delete(self_hv, "file", 4, G_DISCARD);
		hv_delete(self_hv, "tmpfilename", 11, G_DISCARD);
		hv_delete(self_hv, "dict", 4, G_DISCARD);
		hv_delete(self_hv, "current_page", 12, G_DISCARD);

		SvREFCNT_inc(self);
		RETVAL = self;
	OUTPUT:
		RETVAL


