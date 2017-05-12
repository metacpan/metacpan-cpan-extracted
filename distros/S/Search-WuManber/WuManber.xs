/*
 * WuManber.xs
 * Copyright (c) 2007-2010, Juergen Weigert, Novell Inc.
 * This module is free software. It may be used, redistributed
 * and/or modified under the same terms as Perl itself.
 *
 * see perldoc perlxstut
 * see Rolf Stiebe; Textalgoritmen WS 2005/6
 * see TR94-17_WuManber.pdf
 */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "wumanber_impl.h"


static void push_result(unsigned int idx, unsigned long offset, void *data)
{
  AV *r = (AV *)data;

  // In perl, indices run from 0..n_pat-1
  // In C, indices run from 1..n_pat

#if 1
  AV *loc = (AV *)sv_2mortal((SV *)newAV());
  av_push(loc, newSVnv(offset));
  av_push(loc, newSVnv(idx-1));
  av_push(r, newRV((SV *)loc));
#else
  av_push(r, newSVnv(offset));
  av_push(r, newSVnv(idx-1));
#endif
}

MODULE = Search::WuManber	PACKAGE = Search::WuManber
PROTOTYPES: ENABLE

#define BLOCK_SIZE 3
#define HASH1_SIZE 0x10
int
init_tables(obj)
    HV *obj

  PREINIT:
    AV* p;
    SV** pp;
    SV **svp;
    int i, n_patterns;
    unsigned char **pattern_list;
    unsigned int case_sensitive;

  INIT:
    // init PAT table
    pp = hv_fetch(obj, "patterns", 8, 0);
    if (!pp) croak("init_tables: no patterns in obj\n");

    // next test needed to avoid segv
    if (SvTYPE(SvRV(*pp)) != SVt_PVAV) croak("init_tables: patterns not an ARRAY-ref\n");
    p = (AV *)SvRV(*pp);
    n_patterns = av_len(p);
    pattern_list = (unsigned char **)calloc(sizeof(unsigned char *), n_patterns+2);

    svp = hv_fetch(obj, "case_sensitive", 14, 0); 
    if (!svp) croak("init_tables: no 'case_sensitive' in obj\n");
    case_sensitive = SvUV(*svp);

  CODE:
    i = 0;
    while (i++ <= n_patterns)
      {
        SV** ep = av_fetch(p, i-1, 0);
	STRLEN slen;
	unsigned char *e;

	// next test not really needed. perl converts almost anything to string.
	if (!SvPOK(*ep)) croak("init_tables: pattern[%d] is not a string\n", i);
	pattern_list[i] = e = (unsigned char *)SvPV(*ep, slen);

        // printf("pattern[%d] = '%s'\n", i, e);
      }
    pattern_list[i] = NULL;	// just to be sure

    struct WuManber *wm = (struct WuManber *)calloc(1, sizeof(struct WuManber));
    wm->progname = "perl(Search::WuManber)";
    prep_pat(wm, n_patterns+1, pattern_list, !case_sensitive);

    // FIXME: this needs a destructor, to free the memory bound in wm's pointers.
    (void)hv_store(obj, "wm", 2, newSVpvn((char *)wm, sizeof(*wm)), 0); 

    (void)hv_store(obj, "BLOCK_SIZE", 9, newSViv(wm->use_bs1?1:(wm->use_bs3?3:2)), 0); 
    RETVAL = 1;
  OUTPUT:
    RETVAL


SV *
find_all(obj,textsv)
    HV *obj
    SV *textsv

  PREINIT:
    AV *r;	// return value
    STRLEN text_len, n;
    unsigned char *text;
    struct WuManber *wm;
    SV **svp;

    text = (unsigned char *)SvPV(textsv, text_len);
    // warn("find_all: text='%s', text_len=%d\n", text, (unsigned int)text_len);

  INIT:
    svp = hv_fetch(obj, "wm", 2, 0); 
    if (!svp) croak("find_all: no 'wm' in obj\n");
    wm = (struct WuManber *)SvPV(*svp, n);
    if (!svp) croak("find_all: sizeof(wm)=%d, expected %d\n", (int)n, (int)sizeof(struct WuManber));
    search_init(wm, "argv[0]");

    r = (AV *)sv_2mortal((SV *)newAV());
    wm->cb = push_result;
    wm->cb_data = (void *)r;

  CODE:
    search_text(wm, text, text_len);
    RETVAL = newRV((SV *)r);
  OUTPUT:
    RETVAL

