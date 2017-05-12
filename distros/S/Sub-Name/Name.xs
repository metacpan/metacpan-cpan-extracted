/* Copyright (C) 2004, 2008  Matthijs van Duin.  All rights reserved.
 * Copyright (C) 2014, cPanel Inc.  All rights reserved.
 * This program is free software; you can redistribute it and/or modify
 * it under the same terms as Perl itself.
 */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#define NEED_sv_2pv_flags
#define NEED_gv_fetchpvn_flags
#include "ppport.h"

static MGVTBL subname_vtbl;

#ifndef PERL_MAGIC_ext
# define PERL_MAGIC_ext '~'
#endif

#ifndef SvMAGIC_set
#define SvMAGIC_set(sv, val) (SvMAGIC(sv) = (val))
#endif

#ifndef Newxz
#define Newxz(ptr, num, type)	Newz(0, ptr, num, type)
#endif

MODULE = Sub::Name  PACKAGE = Sub::Name

PROTOTYPES: DISABLE

void
subname(name, sub)
	SV *name
	SV *sub
    PREINIT:
	CV *cv = NULL;
	GV *gv;
	HV *stash = CopSTASH(PL_curcop);
	const char *s, *end = NULL, *begin = NULL;
	MAGIC *mg;
	STRLEN namelen;
	const char* nameptr = SvPV(name, namelen);
	int utf8flag = SvUTF8(name);
	int seen_quote = 0, need_subst = 0;
    PPCODE:
	if (!SvROK(sub) && SvGMAGICAL(sub))
		mg_get(sub);
	if (SvROK(sub))
		cv = (CV *) SvRV(sub);
	else if (SvTYPE(sub) == SVt_PVGV)
		cv = GvCVu(sub);
	else if (!SvOK(sub))
		croak(PL_no_usym, "a subroutine");
	else if (PL_op->op_private & HINT_STRICT_REFS)
		croak("Can't use string (\"%.32s\") as %s ref while \"strict refs\" in use",
		      SvPV_nolen(sub), "a subroutine");
	else if ((gv = gv_fetchsv(sub, FALSE, SVt_PVCV)))
		cv = GvCVu(gv);
	if (!cv)
		croak("Undefined subroutine %s", SvPV_nolen(sub));
	if (SvTYPE(cv) != SVt_PVCV && SvTYPE(cv) != SVt_PVFM)
		croak("Not a subroutine reference");

	for (s = nameptr; s <= nameptr + namelen; s++) {
		if (s > nameptr && *s == ':' && s[-1] == ':') {
			end = s - 1;
			begin = ++s;
			if (seen_quote)
				need_subst++;
		}
		else if (s > nameptr && *s != '\0' && s[-1] == '\'') {
			end = s - 1;
			begin = s;
			if (seen_quote++)
				need_subst++;
		}
	}
	s--;
	if (end) {
		SV* tmp;
		if (need_subst) {
			STRLEN length = end - nameptr + seen_quote - (*end == '\'' ? 1 : 0);
			char* left;
			int i, j;
			tmp = newSV(length);
			left = SvPVX(tmp);
			for (i = 0, j = 0; j < end - nameptr; ++i, ++j) {
				if (nameptr[j] == '\'') {
					left[i] = ':';
					left[++i] = ':';
				}
				else {
					left[i] = nameptr[j];
				}
			}
			stash = gv_stashpvn(left, length, GV_ADD | utf8flag);
			SvREFCNT_dec(tmp);
		}
		else
			stash = gv_stashpvn(nameptr, end - nameptr, GV_ADD | utf8flag);
		nameptr = begin;
		namelen -= begin - nameptr;
	}

	#ifdef PERL_VERSION < 10
	/* under debugger, provide information about sub location */
	if (PL_DBsub && CvGV(cv)) {
		HV *hv = GvHV(PL_DBsub);
		SV** old_data;

		char* new_pkg = HvNAME(stash);

		char* old_name = GvNAME( CvGV(cv) );
		char* old_pkg = HvNAME( GvSTASH(CvGV(cv)) );

		int old_len = strlen(old_name) + strlen(old_pkg);
		int new_len = namelen + strlen(new_pkg);

		char* full_name;
		Newxz(full_name, (old_len > new_len ? old_len : new_len) + 3, char);

		strcat(full_name, old_pkg);
		strcat(full_name, "::");
		strcat(full_name, old_name);

		old_data = hv_fetch(hv, full_name, strlen(full_name), 0);

		if (old_data) {
			strcpy(full_name, new_pkg);
			strcat(full_name, "::");
			strcat(full_name, nameptr);

			SvREFCNT_inc(*old_data);
			if (!hv_store(hv, full_name, strlen(full_name), *old_data, 0))
				SvREFCNT_dec(*old_data);
		}
		Safefree(full_name);
	}
	#endif

	gv = (GV *) newSV(0);
	gv_init_pvn(gv, stash, nameptr, s - nameptr, GV_ADDMULTI | utf8flag);

	mg = SvMAGIC(cv);
	while (mg && mg->mg_virtual != &subname_vtbl)
		mg = mg->mg_moremagic;
	if (!mg) {
		Newxz(mg, 1, MAGIC);
		mg->mg_moremagic = SvMAGIC(cv);
		mg->mg_type = PERL_MAGIC_ext;
		mg->mg_virtual = &subname_vtbl;
		SvMAGIC_set(cv, mg);
	}
	if (mg->mg_flags & MGf_REFCOUNTED)
		SvREFCNT_dec(mg->mg_obj);
	mg->mg_flags |= MGf_REFCOUNTED;
	mg->mg_obj = (SV *) gv;
	SvRMAGICAL_on(cv);
	CvANON_off(cv);
#ifndef CvGV_set
	CvGV(cv) = gv;
#else
	CvGV_set(cv, gv);
#endif
	PUSHs(sub);
