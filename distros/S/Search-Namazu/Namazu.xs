/*

Namazu.xs

# Copyright (C) 1999-2006 NOKUBI Takatsugu All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# 
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA
# 02111-1307, USA

$Id: Namazu.xs 268 2006-06-09 05:48:57Z knok $

*/

#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <stdio.h>
#include <namazu/libnamazu.h>
#include <namazu/codeconv.h>
#include <namazu/field.h>
#include <namazu/hlist.h>
#include <namazu/idxname.h>
#include <namazu/parser.h>
#include <namazu/re.h>
#include <namazu/search.h>
#include <namazu/util.h>
#include <namazu/wakati.h>
#ifdef __cplusplus
}
#endif

/* for old perl (< 5.004_04?) */
#if !defined(PL_na) && defined(na)
#define PL_na na
#endif
#if !defined(PL_sv_undef) && defined(sv_undef)
#define PL_sv_undef sv_undef
#endif
#if !defined(SvPV_nolen) /* for perl 5.005 */
#define SvPV_nolen(x) SvPV(x, PL_na)
#endif

#define SEARCH_NAMAZU_FIELDS 5
#define SCORE "//score"
#define SCORE_LEN strlen(SCORE)
#define DATE "//date"
#define DATE_LEN strlen(DATE)
#define RANK "//rank"
#define RANK_LEN strlen(RANK)
#define DOCID "//docid"
#define DOCID_LEN strlen(DOCID)
#define IDXID "//idxid"
#define IDXID_LEN strlen(IDXID)

static int status = 0;

AV * call_search_main_c(char *query, int maxget)
{
	AV *retar;
	NmzResult hlist;
	char result[SEARCH_NAMAZU_FIELDS][BUFSIZE];
	int i;
	status = 0;
	retar = newAV();
	hlist = nmz_search(query);
	av_extend(retar, hlist.num - 1);
	status = hlist.stat;
	for (i = 0; i < hlist.num; i ++) {
	    if (i < maxget) {
		SV *ohlist = perl_eval_pv("new Search::Namazu::Result", TRUE);
		dSP;
		nmz_get_field_data(hlist.data[i].idxid, hlist.data[i].docid, "uri", result[0]);
		nmz_get_field_data(hlist.data[i].idxid, hlist.data[i].docid, "summary", result[1]);
		nmz_get_field_data(hlist.data[i].idxid, hlist.data[i].docid, "title", result[2]);
		nmz_get_field_data(hlist.data[i].idxid, hlist.data[i].docid, "author", result[3]);
		nmz_get_field_data(hlist.data[i].idxid, hlist.data[i].docid, "size", result[4]);
		ENTER;
		SAVETMPS;
		PUSHMARK(SP);
		PUSHs(ohlist);
		PUSHs(sv_2mortal(newSViv(hlist.data[i].score)));
		PUSHs(sv_2mortal(newSVpv(result[0], strlen(result[0]))));
		PUSHs(sv_2mortal(newSViv(hlist.data[i].date)));
		PUSHs(sv_2mortal(newSViv(hlist.data[i].rank)));
		PUSHs(sv_2mortal(newSVpv(result[1], strlen(result[1]))));
		PUSHs(sv_2mortal(newSVpv(result[2], strlen(result[2]))));
		PUSHs(sv_2mortal(newSVpv(result[3], strlen(result[3]))));
		PUSHs(sv_2mortal(newSVpv(result[4], strlen(result[4]))));
		PUTBACK;
		perl_call_method("set", G_DISCARD);
		SvREFCNT_inc(ohlist);
		av_store(retar, i, ohlist);
		FREETMPS;
		LEAVE;
	    } else {
		av_store(retar, i, &PL_sv_undef);
	    }	   
	}
	nmz_free_hlist(hlist);
	return retar;
}

AV * call_search_main_fields_c(char *query, int maxget, AV *fields)
{
	AV *retar;
	HV *stash;
	char **fstr;
	int *fsize;
	NmzResult hlist;
	int i;
	int flen;

	retar = newAV();
	flen = av_len(fields);
	if (flen < 0 || maxget <= 0 || query == NULL)
		return retar;
	status = 0;
	fstr = (char **) malloc(sizeof(char *) * (flen + 1));
	fsize = (int *) malloc(sizeof(int) * (flen + 1));
	for (i = 0; i <= flen; i ++) {
		SV **x;
		x = av_fetch(fields, i, 0);
		fstr[i] = SvPV_nolen(*x);
		fsize[i] = SvCUR(*x);
	}
	hlist = nmz_search(query);
	av_extend(retar, hlist.num - 1);
	status = hlist.stat;
	stash = gv_stashpv("Search::Namazu::ResultXS", 0);
	for (i = 0; i < hlist.num; i ++) {
		if (i < maxget) {
			HV *hash;
			SV *ref;
			SV *score, *date, *rank, *docid, *idxid;
			int j;
			char fcont[BUFSIZE];

			hash = newHV();
			for (j = 0; j <= flen; j ++) {
				nmz_get_field_data(hlist.data[i].idxid,
					hlist.data[i].docid,
					fstr[j], fcont);
				hv_store(hash, fstr[j], fsize[j], 
					newSVpv(fcont, strlen(fcont)), 0);
			}
			score = newSViv(hlist.data[i].score);
			date = newSViv(hlist.data[i].date);
			rank = newSViv(hlist.data[i].rank);
			docid = newSViv(hlist.data[i].docid);
			idxid = newSViv(hlist.data[i].idxid);
			hv_store(hash, SCORE, SCORE_LEN, score, 0);
			hv_store(hash, DATE, DATE_LEN, date, 0);
			hv_store(hash, RANK, RANK_LEN, rank, 0);
			hv_store(hash, DOCID, IDXID_LEN, docid, 0);
			hv_store(hash, IDXID, IDXID_LEN, idxid, 0);

			ref = newRV_inc((SV*) hash);
			sv_bless(ref, stash);
			av_store(retar, i, ref);
		} else {
			av_store(retar, i, &PL_sv_undef);
		}
	}
	nmz_free_hlist(hlist);
	free(fstr);
	free(fsize);
	return retar;
}

MODULE = Search::Namazu		PACKAGE = Search::Namazu

PROTOTYPES: DISABLE

void
call_search_main(query, maxget)
	SV *query
	int maxget

	PPCODE:
		char *qstr;
                char buffer[BUFSIZE];
		char cqstr[BUFSIZE * 2];
		AV *retar;
		int i;

		qstr = SvPV(query, PL_na);
                strncpy(buffer, qstr, BUFSIZE);
                buffer[BUFSIZE - 1] = '\0';
		nmz_codeconv_query(buffer);
		strcpy(cqstr, buffer);
		retar = call_search_main_c(cqstr, maxget);
#if ! defined(PERL_VERSION) || (PERL_VERSION == 6 && PERL_SUBVERSION == 0)
		{ /* workaround for only one result */
                        SPAGAIN;
		}
#endif /* PERL_VERSION */
		while (av_len(retar) >= 0) {
			XPUSHs(av_shift(retar));
		}
		nmz_free_internal();

SV*
call_search_main_ref(query, maxget)
	SV *query
	int maxget

	CODE:
		char *qstr;
                char buffer[BUFSIZE];
		char cqstr[BUFSIZE * 2];
		AV *retar;
		int i;

		qstr = SvPV(query, PL_na);
                strncpy(buffer, qstr, BUFSIZE);
                buffer[BUFSIZE - 1] = '\0';
                nmz_codeconv_query(buffer);
                strcpy(cqstr, buffer);
		retar = call_search_main_c(cqstr, maxget);
		nmz_free_internal();
		RETVAL = newRV_inc((SV*) retar);
	OUTPUT:
		RETVAL

SV*
call_search_main_fields(query, maxget, fieldref)
	SV *query
	int maxget
	SV *fieldref

	CODE:
		char *qstr;
                char buffer[BUFSIZE];
		char cqstr[BUFSIZE * 2];
		AV *retar;
		AV *fields;
		int i;

		fields = (AV *) SvRV(fieldref);
		qstr = SvPV(query, PL_na);
                strncpy(buffer, qstr, BUFSIZE);
                buffer[BUFSIZE - 1] = '\0';
                nmz_codeconv_query(buffer);
                strcpy(cqstr, buffer);
		retar = call_search_main_fields_c(cqstr, maxget, fields);
		nmz_free_internal();
		RETVAL = newRV_inc((SV*) retar);
	OUTPUT:
		RETVAL

int
nmz_addindex(index)
	SV *index

	PREINIT:
		char *tmp;

	CODE:
		tmp = SvPV(index, PL_na);
		RETVAL = nmz_add_index(tmp);

	OUTPUT:
		RETVAL

void
nmz_sortbydate()
	CODE:
		nmz_set_sortmethod(SORT_BY_DATE);

void
nmz_sortbyscore()
	CODE:
		nmz_set_sortmethod(SORT_BY_SCORE);

void
nmz_setsortfield(field)
	SV * field
	CODE:
		nmz_set_sortfield(SvPV_nolen(field));

void
nmz_sortbyfield()
	CODE:
		nmz_set_sortmethod(SORT_BY_FIELD);

void
nmz_descendingsort()
	CODE:
		nmz_set_sortorder(DESCENDING);

void
nmz_ascendingsort()
	CODE:
		nmz_set_sortorder(ASCENDING);

int
nmz_setlang(lang)
	SV *lang

	PREINIT:
		char *tmp;

	CODE:
		tmp = SvPV(lang, PL_na);
		RETVAL = nmz_set_lang(tmp);

	OUTPUT:
		RETVAL

void
nmz_setmaxhit(max)
	int max

	CODE:
		nmz_set_maxhit(max);

int
nmz_getstatus()
	CODE:
		RETVAL = status;
	OUTPUT:
		RETVAL


MODULE = Search::Namazu	PACKAGE = Search::Namazu::ResultXS	PREFIX = res_

SV *
res_new()
	CODE:
		HV *self;
		HV *stash;
		SV *ref;

		stash = gv_stashpv("Search::Namazu::ResultXS", 0);
		self = newHV();
		ref = newRV_inc((SV*) self);
		sv_bless(ref, stash);
		RETVAL = ref;
	OUTPUT:
		RETVAL

void
res_set(self, key, val)
	      SV *self
	      SV *key
	      SV *val
	CODE:
		HV *hash;

		hash = (HV *) SvRV(self);
		hv_store(hash, SvPV_nolen(key), SvCUR(key), val, 0);

SV *
res_get(self, key)
	      SV *self
	      SV *key
	CODE:
		HV *hash;
		SV **ret;

		hash = (HV *) SvRV(self);
		ret = hv_fetch(hash, SvPV_nolen(key), SvCUR(key), 0);
		if (ret == NULL) {
			RETVAL = &PL_sv_undef;
		} else {
			RETVAL = SvREFCNT_inc(*ret);
		}
	OUTPUT:
		RETVAL

SV *
res_score(self)
	      SV *self
	CODE:
		HV *hash;
		SV **ret;

		hash = (HV *) SvRV(self);
		ret = hv_fetch(hash, SCORE, SCORE_LEN, 0);
		if (ret == NULL) {
			RETVAL = &PL_sv_undef;
		} else {
			RETVAL = SvREFCNT_inc(*ret);
		}
	OUTPUT:
		RETVAL

SV *
res_date(self)
	      SV *self
	CODE:
		HV *hash;
		SV **ret;

		hash = (HV *) SvRV(self);
		ret = hv_fetch(hash, DATE, DATE_LEN, 0);
		if (ret == NULL) {
			RETVAL = &PL_sv_undef;
		} else {
			RETVAL = SvREFCNT_inc(*ret);
		}
	OUTPUT:
		RETVAL

SV *
res_rank(self)
	      SV *self
	CODE:
		HV *hash;
		SV **ret;

		hash = (HV *) SvRV(self);
		ret = hv_fetch(hash, RANK, RANK_LEN, 0);
		if (ret == NULL) {
			RETVAL = &PL_sv_undef;
		} else {
			RETVAL = SvREFCNT_inc(*ret);
		}
	OUTPUT:
		RETVAL

SV *
res_docid(self)
	      SV *self
	CODE:
		HV *hash;
		SV **ret;

		hash = (HV *) SvRV(self);
		ret = hv_fetch(hash, DOCID, DOCID_LEN, 0);
		if (ret == NULL) {
			RETVAL = &PL_sv_undef;
		} else {
			RETVAL = SvREFCNT_inc(*ret);
		}
	OUTPUT:
		RETVAL

SV *
res_idxid(self)
	      SV *self
	CODE:
		HV *hash;
		SV **ret;

		hash = (HV *) SvRV(self);
		ret = hv_fetch(hash, IDXID, IDXID_LEN, 0);
		if (ret == NULL) {
			RETVAL = &PL_sv_undef;
		} else {
			RETVAL = SvREFCNT_inc(*ret);
		}
	OUTPUT:
		RETVAL
