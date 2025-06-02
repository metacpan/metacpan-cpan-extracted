#ifndef _ARCHITECT_H
#define _ARCHITECT_H
/* prototype of functions */
SV * new_rect(char *, int, double, double, double, double);
SV * done_pages(AV *);
pdfio_rect_t rect_to_pdfio_rect(SV *);
char * check_paper_size(const char *);
int render_lines_to_page(pdfio_stream_t *, AV * lines, char *, double, HV *);
AV * text_fits_in_bounding_box(char *, SV *, double, HV *, HV *);
#endif
