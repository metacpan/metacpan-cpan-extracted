#include "EXTERN.h"
#include "perl.h"
#include <pdfio.h> 
#include <pdfio-content.h>

SV *
new_rect(char * name, int name_len, double x1, double y1, double x2, double y2) {
		dTHX;
		dSP;
		SV * rect;

		char *rect_pkg = malloc(name_len + 7);
		sprintf(rect_pkg, "%s::Rect", name);
		SV * pkg = newSVpv(rect_pkg, strlen(rect_pkg));
		char *method = malloc(name_len + 12);
		sprintf(method, "%s::Rect::new", name);
		
		ENTER;
		SAVETMPS;

		PUSHMARK(SP);
		XPUSHs(newSVpv(rect_pkg, name_len + 7));
		XPUSHs(newSVnv(x1));
		XPUSHs(newSVnv(y1));
		XPUSHs(newSVnv(x2));
		XPUSHs(newSVnv(y2));
		PUTBACK;
		call_pv(method, G_SCALAR | G_EVAL);
		SPAGAIN;

		if (SvTRUE(ERRSV)) {
			LEAVE;
			PUTBACK;
			croak("%s", SvPV_nolen(ERRSV));
		}

		rect = POPs;
		SvREFCNT_inc(rect);
		PUTBACK;
		FREETMPS;
		LEAVE;

		return rect;
}

SV *
done_pages(AV * pages) {
	
	dTHX;
	int len = av_len(pages) + 1, i = 0;

	for (i = 0; i < len; i++) {
		dSP; 
		SV *page_sv = *av_fetch(pages, i, 0);
		HV *stash = SvSTASH(SvRV(page_sv));
		char *pkg_name = HvNAME(stash);
		int pkg_len = strlen(pkg_name);
		char *method = malloc(pkg_len + 7);
		sprintf(method, "%s::done", pkg_name);
		PUSHMARK(SP);
		SvREFCNT_inc(page_sv);
		XPUSHs(page_sv);
		PUTBACK;
		call_pv(method, G_SCALAR | G_EVAL);
		SPAGAIN;

		if (SvTRUE(ERRSV)) {
			LEAVE;
			PUTBACK;
			croak("%s", SvPV_nolen(ERRSV));
		}

		POPs;
		PUTBACK;
	}
}

pdfio_rect_t rect_to_pdfio_rect(SV * rect_sv) {
	dTHX;
	if (!SvROK(rect_sv) || SvTYPE(SvRV(rect_sv)) != SVt_PVHV) {
		croak("rect must be a PDFio::Architect::Rect object");
	}

	HV * rect_hash = (HV*)SvRV(rect_sv);
	SV *x1_sv = *hv_fetch(rect_hash, "x1", 2, 0);
	SV *y1_sv = *hv_fetch(rect_hash, "y1", 2, 0);
	SV *x2_sv = *hv_fetch(rect_hash, "x2", 2, 0);
	SV *y2_sv = *hv_fetch(rect_hash, "y2", 2, 0);

	pdfio_rect_t rect;
	rect.x1 = SvNV(x1_sv);
	rect.y1 = SvNV(y1_sv);
	rect.x2 = SvNV(x2_sv);
	rect.y2 = SvNV(y2_sv);

	return rect;
}

char * check_paper_size (char * size) {
	if (strcmp(size, "A0") == 0) {
		return "2384x3370";
	} else if (strcmp(size, "A1") == 0) {
		return "1684x2384";
	} else if (strcmp(size, "A2") == 0) {
		return "1191x1684";
	} else if (strcmp(size, "A3") == 0) {
		return "842x1191";
	} else if (strcmp(size, "A4") == 0) {
		return "595x842";
	} else if (strcmp(size, "A5") == 0) {
		return "420x595";
	} else if (strcmp(size, "A6") == 0) {
		return "298x420";
	} else if (strcmp(size, "Letter") == 0) {
		return "612x792";
	} else if (strcmp(size, "Legal") == 0) {
		return "612x1008";
	} else if (strcmp(size, "Tabloid") == 0) {
		return "792x1224";
	} else if (strcmp(size, "Executive") == 0) {
		return "522x756";
	} else if (strcmp(size, "B5") == 0) {
		return "499x709";
	} else if (strcmp(size, "B4") == 0) {
		return "709x1001";
	} else if (strcmp(size, "B3") == 0) {
		return "1001x1417";
	} else if (strcmp(size, "B2") == 0) {
		return "1417x2004";
	} else if (strcmp(size, "B1") == 0) {
		return "2004x2835";
	} else if (strcmp(size, "B0") == 0) {
		return "2835x4008";
	} else {
		return size; // assume it's already in the correct format
	}
}

AV *
text_fits_in_bounding_box(const char * text, SV *font_sv, double size, HV * bounding_hash, HV * size_hash) {
	dTHX;
	AV * lines = newAV();
	SV *x1_sv = *hv_fetch(bounding_hash, "x1", 2, 0);
	SV *y1_sv = *hv_fetch(bounding_hash, "y1", 2, 0);
	SV *x2_sv = *hv_fetch(bounding_hash, "x2", 2, 0);
	SV *y2_sv = *hv_fetch(bounding_hash, "y2", 2, 0);

	SvREFCNT_inc(font_sv);
	pdfio_obj_t *font = (pdfio_obj_t*)INT2PTR(pdfio_obj_t*, SvUV(SvRV(font_sv)));

	double x1 = SvNV(x1_sv);
	double y1 = SvNV(y1_sv);
	double x2 = SvNV(x2_sv);
	double y2 = SvNV(y2_sv);

	double width = x2 - x1;
	double height = y2 - y1;

	if (width <= 0 || height <= 0) {
		return lines;
	}

	if (y2 > SvNV(*hv_fetch(size_hash, "y2", 2, 0)) ||
		y1 < SvNV(*hv_fetch(size_hash, "y1", 2, 0)) ||
		x2 > SvNV(*hv_fetch(size_hash, "x2", 2, 0)) ||
		x1 < SvNV(*hv_fetch(size_hash, "x1", 2, 0))) {
		return lines;
	}

	
	const char *ptr = strdup(text);
	const char *line_start = ptr;
	char *word_buf = NULL;
	size_t word_buf_size = 0;
	double cur_y = y2 - size;

	while (*ptr) {
		size_t len = strlen(ptr);
		size_t line_buf_size = len + 1;
		char *line_buf = (char *)malloc(line_buf_size);
		size_t line_buf_pos = 0;
		size_t word_start = 0;
		size_t i = 0;
		while (i <= len) {
			if (i == len || ptr[i] == ' ') {
				size_t word_len = i - word_start;
				if (word_len > 0) {
					if (word_buf_size < word_len + 1) {
						word_buf_size = word_len + 32;
						word_buf = (char *)realloc(word_buf, word_buf_size);
					}
					sprintf(word_buf, "%.*s", (int)word_len, ptr + word_start);
					size_t new_line_len = line_buf_pos + (line_buf_pos > 0 ? 1 : 0) + word_len;
					char *test_line = (char *)malloc(new_line_len + 1);
					if (line_buf_pos > 0) {
						sprintf(test_line, "%.*s %s", (int)line_buf_pos, line_buf, word_buf);
					} else {
						sprintf(test_line, "%s", word_buf);
					}
					
					double twidth = pdfioContentTextMeasure(font, test_line, 18);
		
					if (twidth <= width) {
						if (line_buf_pos > 0) {
							line_buf[line_buf_pos++] = ' ';
						}
						memcpy(line_buf + line_buf_pos, word_buf, word_len);
						line_buf_pos += word_len;
						line_buf[line_buf_pos] = '\0';			
					} else {
						
						if (line_buf_pos > 0) {
							SV *sv = newSVpv(line_buf, line_buf_pos);
							av_push(lines, sv);
							cur_y -= size;
							if (cur_y < y1 + size) {
								free(test_line);
								break;
							}
						}
						sprintf(line_buf, "%s", word_buf);
						line_buf_pos = word_len;
					}
					free(test_line);
				}
				word_start = i + 1;
			}
			i++;
		}
		

		if (line_buf_pos > 0 && cur_y >= y1) {
			SV *sv = newSVpv(line_buf, line_buf_pos);
			av_push(lines, sv);
			cur_y -= size;
		}
		free(line_buf);

		if (cur_y < y1 - size) {
			croak("text does not fit in bounding box");
		}

		ptr += len;
		line_start = ptr;
	}
	
	if (word_buf)
		free(word_buf);

	return lines;	
}

int render_lines_to_page(pdfio_stream_t *page, AV *lines, char *font_name, double size, HV * bounding_hash) {
	dTHX;

	SV *x1_sv = *hv_fetch(bounding_hash, "x1", 2, 0);
	SV *y2_sv = *hv_fetch(bounding_hash, "y2", 2, 0);
	double x1 = SvNV(x1_sv);
	double y2 = SvNV(y2_sv) - (1 * size);

	for (I32 i = 0; i <= av_len(lines); i++) {
		SV *line_sv = *av_fetch(lines, i, 0);
		char *line = SvPV_nolen(line_sv);
		pdfioContentTextBegin(page);
		pdfioContentSetTextFont(page, font_name, size);
		pdfioContentTextMoveTo(page, x1, y2 - (i * size));
		pdfioContentTextShow(page, 0, line);
		pdfioContentTextEnd(page);
	}

	return 1; 
}
