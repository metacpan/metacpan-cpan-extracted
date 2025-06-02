#define PERL_NO_GET_CONTEXT // we'll define thread context if necessary (faster)
#include "EXTERN.h"         // globals/constant import locations
#include "perl.h"           // Perl symbols, structures and constants definition
#include "XSUB.h"           // xsubpp functions and macros
#include <pdfio.h>
#include <pdfio-content.h>
#include "architect.h"

MODULE = PDFio::Architect::Page::_Page  PACKAGE = PDFio::Architect::Page::_Page
PROTOTYPES: DISABLE

MODULE = PDFio::Architect::Page  PACKAGE = PDFio::Architect::Page
PROTOTYPES: DISABLE

SV *
new(pkg, file, args)
	SV * pkg
	SV * file
	SV * args
	CODE:
		STRLEN retlen;
		char * pkg_name = SvPV(pkg, retlen);
		HV *hash = (HV*)SvRV(args);

		HV *self = (HV*)SvRV(file);

		SV **file_sv = hv_fetch(self, "file", 4, 0);
		if (!file_sv || !SvROK(*file_sv)) {
			croak("file not initialized");
		}
		pdfio_file_t *pdf = INT2PTR(pdfio_file_t*, SvUV(SvRV(*file_sv)));

		pdfio_dict_t *dict = pdfioDictCreate(pdf);

		HV *fonts = newHV();
		HV *dict_hash = (HV*)SvRV(*hv_fetch(self, "dict", 4, 0));
		HE *entry;
		(void)hv_iterinit(dict_hash);
		while ((entry = hv_iternext(dict_hash)) != NULL) {
			SV *key_sv = hv_iterkeysv(entry);
			SV *value_sv = hv_iterval(dict_hash, entry);
			if (SvOK(key_sv) && SvOK(value_sv)) {
				const char *key = SvPV_nolen(key_sv);
				const char *value = NULL;
				if (sv_isa(value_sv, "PDFio::Architect::Rect")) {
					pdfio_rect_t box = rect_to_pdfio_rect(value_sv);
					pdfioDictSetRect(dict, key, &box);
				} else {
					HV * value_hash = (HV*)SvRV(value_sv);
					char * font_key = SvPV_nolen(*hv_fetch(value_hash, "alias", 5, 0));
					pdfio_obj_t *pdf_font =  (pdfio_obj_t*)INT2PTR(pdfio_obj_t*, SvUV(SvRV(*hv_fetch(value_hash, "font", 4, 0))));
					pdfioPageDictAddFont(dict, key, pdf_font);
					SvREFCNT_inc(value_sv);
					hv_store(fonts, font_key, strlen(font_key), value_sv, 0);
				}
			}
		}
		hv_store(hash, "fonts", 5, newRV_noinc((SV*)fonts), 0);
		if (hv_exists(hash, "size", 4)) { 
			SV *size_sv = *hv_fetch(hash, "size", 4, 0);
			if (SvROK(size_sv) && sv_isa(size_sv, "PDFio::Architect::Rect")) {
				pdfio_rect_t size = rect_to_pdfio_rect(size_sv);
				pdfioDictSetRect(dict, "MediaBox", &size);
				pdfioDictSetRect(dict, "CropBox", &size);
				SvREFCNT_inc(size_sv);
				hv_store(hash, "size", 4, size_sv, 0);
			} else if (SvOK(size_sv) && SvPOK(size_sv)) {
				char *size_str = SvPV_nolen(size_sv);
				size_str = check_paper_size(size_str);
				int width, height;
				if (sscanf(size_str, "%dx%d", &width, &height) == 2) {
					char *base_name = strdup(pkg_name);
					char *pos = strstr(base_name, "::Page");
					if (pos) *pos = '\0';
					SV *rect = new_rect(base_name, strlen(base_name), 0, 0, width, height);
					SvREFCNT_inc(rect);
					free(base_name);
					hv_store(hash, "size", 4, rect, 0);
					pdfio_rect_t size = rect_to_pdfio_rect(rect);
					pdfioDictSetRect(dict, "MediaBox", &size);
					pdfioDictSetRect(dict, "CropBox", &size);
				} else {
					croak("Invalid size format, expected 'WxH' (e.g., '595x842')");
				}
			} else {
				croak("Invalid size parameter");
			}	
		} else {
			SV *dict = *hv_fetch(self, "dict", 4, 0);
			SV *mb = *hv_fetch((HV*)SvRV(dict), "MediaBox", 8, 0);
			SvREFCNT_inc(mb);
			hv_store(hash, "size", 4, mb, 0);
		}

		pdfio_stream_t *page = pdfioFileCreatePage(pdf, dict);

		SV * page_sv = sv_bless(
			newRV_noinc(newSViv(PTR2UV(page))), gv_stashpv("PDFio::Architect::Page::_Page", 1)
		);
		hv_store(hash, "page", 4, page_sv, 0);
		
		RETVAL = sv_bless(newRV_noinc((SV*)hash), gv_stashpv(pkg_name, 0));
	OUTPUT:
		RETVAL

SV *
done(self)
	SV * self
	CODE:
		SV *page_sv = *hv_fetch((HV*)SvRV(self), "page", 4, 0);
		if (!SvROK(page_sv)) {
			croak("page not initialized");
		}
		pdfio_stream_t *page = INT2PTR(pdfio_stream_t*, SvUV(SvRV(page_sv)));

		if (page) {
			pdfioStreamClose(page);
		}

		hv_delete((HV*)SvRV(self), "page", 4, 0);
		RETVAL = newSViv(1);
	OUTPUT:
		RETVAL

SV *
add_text(self, args)
	SV * self
	HV * args
	CODE:
		SV *page_sv = *hv_fetch((HV*)SvRV(self), "page", 4, 0);
		if (!SvROK(page_sv)) {
			croak("page not initialized");
		}
		pdfio_stream_t *page = INT2PTR(pdfio_stream_t*, SvUV(SvRV(page_sv)));

		SV *text_sv = *hv_fetch(args, "text", 4, 0);
		if (!text_sv || !SvOK(text_sv)) {
			croak("text parameter is required");
		}

		const char *text = SvPV_nolen(text_sv);

		if (!hv_exists(args, "bounding", 8)) {
			croak("bounding parameter is required");
		}
		
		HV *bounding_sv = (HV*)SvRV(*hv_fetch(args, "bounding", 8, 0));
		HV *size_sv = (HV*)SvRV(*hv_fetch((HV*)SvRV(self), "size", 4, 0));

		HV * fonts = (HV*)SvRV(*hv_fetch((HV*)SvRV(self), "fonts", 5, 0));
		STRLEN font_retlen;
		char *font_name;
		if (hv_exists(args, "font", 4)) {
			font_name = SvPV(*hv_fetch(args, "alias", 5, 0), font_retlen);
		} else {
			font_name = "F1";
			font_retlen = 2;
		}
		HV * font_class = (HV*)SvRV(newSVsv(*hv_fetch(fonts, font_name, font_retlen, 0)));
		SV *font_sv = *hv_fetch(font_class, "font", 4, 0);

		double font_size = SvNV(*hv_fetch(args, "size", 4, 0));

		AV * lines = text_fits_in_bounding_box(text, font_sv, font_size, bounding_sv, size_sv);
		if (!(av_len(lines) + 1)) {
			croak("Text does not fit in the bounding box");
		}
		render_lines_to_page(page, lines, font_name, font_size, bounding_sv);

		pdfioContentSave(page);
		SvREFCNT_inc(self);
		RETVAL = self;
	OUTPUT:
		RETVAL

SV *
width(self)
	SV * self
	CODE:
		SV *size_sv = *hv_fetch((HV*)SvRV(self), "size", 4, 0);
		if (!SvROK(size_sv) || !sv_isa(size_sv, "PDFio::Architect::Rect")) {
			croak("size must be a PDFio::Architect::Rect object");
		}
	
		RETVAL = newSVsv(*hv_fetch((HV*)SvRV(size_sv), "x2", 2, 0));
	OUTPUT:
		RETVAL

SV *
height(self)
	SV * self
	CODE:
		SV *size_sv = *hv_fetch((HV*)SvRV(self), "size", 4, 0);
		if (!SvROK(size_sv) || !sv_isa(size_sv, "PDFio::Architect::Rect")) {
			croak("size must be a PDFio::Architect::Rect object");
		}
		RETVAL = newSVsv(*hv_fetch((HV*)SvRV(size_sv), "y2", 2, 0));
	OUTPUT:
		RETVAL
