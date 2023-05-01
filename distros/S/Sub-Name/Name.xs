/* Copyright (C) 2004, 2008  Matthijs van Duin.  All rights reserved.
 * Copyright (C) 2014, cPanel Inc.  All rights reserved.
 * This program is free software; you can redistribute it and/or modify
 * it under the same terms as Perl itself.
 */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#define NEED_sv_2pv_flags
#define NEED_newSVpvn_flags
#define NEED_gv_fetchpvn_flags
#define NEED_sv_catpvn_flags
#define NEED_croak_xs_usage     /* running `perl ppport.h Name.xs` suggests removing this, but don't! see RT#125158 */
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

#ifndef HvNAMELEN_get
#define HvNAMELEN_get(stash) strlen(HvNAME(stash))
#endif

#ifndef HvNAMEUTF8
#define HvNAMEUTF8(stash) 0
#endif

#ifndef GvNAMEUTF8
#ifdef GvNAME_HEK
#define GvNAMEUTF8(gv) HEK_UTF8(GvNAME_HEK(gv))
#else
#define GvNAMEUTF8(gv) 0
#endif
#endif

#ifndef SV_CATUTF8
#define SV_CATUTF8 0
#endif

#ifndef SV_CATBYTES
#define SV_CATBYTES 0
#endif

#ifndef sv_catpvn_flags
#define sv_catpvn_flags(b,n,l,f) sv_catpvn(b,n,l)
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
	int quotes_seen = 0;
	bool need_subst = FALSE;
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
			if (quotes_seen)
				need_subst = TRUE;
		}
		else if (s > nameptr && *s != '\0' && s[-1] == '\'') {
			end = s - 1;
			begin = s;
			if (quotes_seen++)
				need_subst = TRUE;
		}
	}
	s--;
	if (end) {
		SV* tmp;
		if (need_subst) {
			STRLEN length = end - nameptr + quotes_seen - (*end == '\'' ? 1 : 0);
			char* left;
			int i, j;
			tmp = sv_2mortal(newSV(length));
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
		}
		else
			stash = gv_stashpvn(nameptr, end - nameptr, GV_ADD | utf8flag);
		nameptr = begin;
		namelen -= begin - nameptr;
	}

	/* under debugger, provide information about sub location */
	if (PL_DBsub && CvGV(cv)) {
		HV* DBsub = GvHV(PL_DBsub);
		HE* old_data;

		GV* oldgv = CvGV(cv);
		HV* oldhv = GvSTASH(oldgv);
		SV* old_full_name = sv_2mortal(newSVpvn_flags(HvNAME(oldhv), HvNAMELEN_get(oldhv), HvNAMEUTF8(oldhv) ? SVf_UTF8 : 0));
		sv_catpvn(old_full_name, "::", 2);
		sv_catpvn_flags(old_full_name, GvNAME(oldgv), GvNAMELEN(oldgv), GvNAMEUTF8(oldgv) ? SV_CATUTF8 : SV_CATBYTES);

		old_data = hv_fetch_ent(DBsub, old_full_name, 0, 0);

		if (old_data && HeVAL(old_data)) {
			SV* new_full_name = sv_2mortal(newSVpvn_flags(HvNAME(stash), HvNAMELEN_get(stash), HvNAMEUTF8(stash) ? SVf_UTF8 : 0));
			sv_catpvn(new_full_name, "::", 2);
			sv_catpvn_flags(new_full_name, nameptr, s - nameptr, utf8flag ? SV_CATUTF8 : SV_CATBYTES);
			SvREFCNT_inc(HeVAL(old_data));
			if (hv_store_ent(DBsub, new_full_name, HeVAL(old_data), 0) != NULL)
				SvREFCNT_inc(HeVAL(old_data));
		}
	}

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
