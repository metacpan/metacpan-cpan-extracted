/*
 * Copyright (c) 2000 Charles Ying. All rights reserved.
 * 
 * This program is free software; you can redistribute it and/or modify
 * it under the same terms as sendmail itself.
 *
 */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "intpools.h"

#include "libmilter/mfapi.h"
#include "callbacks.h"


/* Conversion for an easier interface to the milter API. */
#define MI_BOOL_CVT(mi_bool) (((mi_bool) == MI_SUCCESS) ? TRUE : FALSE)

typedef SMFICTX *Sendmail_Milter_Context;


/* Wrapper functions to do some real work. */

int milter_register(pTHX_ char *name, SV *milter_desc_ref, int flags)
{
	HV *milter_desc = (HV *)NULL;
	struct smfiDesc filter_desc;

	if (!SvROK(milter_desc_ref) &&
	    (SvTYPE(SvRV(milter_desc_ref)) != SVt_PVHV))
		croak("expected reference to hash for milter descriptor.");

	milter_desc = (HV *)SvRV(milter_desc_ref);

	register_callbacks(&filter_desc, name, milter_desc, flags);

	return smfi_register(filter_desc);
}

int milter_main(int max_interpreters, int max_requests)
{
	init_callbacks(max_interpreters, max_requests);

	return smfi_main();
}


/* Constants from libmilter/mfapi.h */

static int
not_here(char *s)
{
    croak("%s not implemented on this architecture", s);
    return -1;
}

static double
constant_SMFIF_A(char *name, int len, int arg)
{
    if (7 + 2 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[7 + 2]) {
    case 'H':
	if (strEQ(name + 7, "DDHDRS")) {	/* SMFIF_A removed */
#ifdef SMFIF_ADDHDRS
	    return SMFIF_ADDHDRS;
#else
	    goto not_there;
#endif
	}
    case 'R':
	if (strEQ(name + 7, "DDRCPT")) {	/* SMFIF_A removed */
#ifdef SMFIF_ADDRCPT
	    return SMFIF_ADDRCPT;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_SMFIF_C(char *name, int len, int arg)
{
    if (7 + 2 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[7 + 2]) {
    case 'B':
	if (strEQ(name + 7, "HGBODY")) {	/* SMFIF_C removed */
#ifdef SMFIF_CHGBODY
	    return SMFIF_CHGBODY;
#else
	    goto not_there;
#endif
	}
    case 'H':
	if (strEQ(name + 7, "HGHDRS")) {	/* SMFIF_C removed */
#ifdef SMFIF_CHGHDRS
	    return SMFIF_CHGHDRS;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_SMFIF(char *name, int len, int arg)
{
    if (5 + 1 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[5 + 1]) {
    case 'A':
	if (!strnEQ(name + 5,"_", 1))
	    break;
	return constant_SMFIF_A(name, len, arg);
    case 'C':
	if (!strnEQ(name + 5,"_", 1))
	    break;
	return constant_SMFIF_C(name, len, arg);
    case 'D':
	if (strEQ(name + 5, "_DELRCPT")) {	/* SMFIF removed */
#ifdef SMFIF_DELRCPT
	    return SMFIF_DELRCPT;
#else
	    goto not_there;
#endif
	}
    case 'M':
	if (strEQ(name + 5, "_MODBODY")) {	/* SMFIF removed */
#ifdef SMFIF_MODBODY
	    return SMFIF_MODBODY;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_SMFI_V(char *name, int len, int arg)
{
    switch (name[6 + 0]) {
    case '1':
	if (strEQ(name + 6, "1_ACTS")) {	/* SMFI_V removed */
#ifdef SMFI_V1_ACTS
	    return SMFI_V1_ACTS;
#else
	    goto not_there;
#endif
	}
    case '2':
	if (strEQ(name + 6, "2_ACTS")) {	/* SMFI_V removed */
#ifdef SMFI_V2_ACTS
	    return SMFI_V2_ACTS;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_SMFI_(char *name, int len, int arg)
{
    switch (name[5 + 0]) {
    case 'C':
	if (strEQ(name + 5, "CURR_ACTS")) {	/* SMFI_ removed */
#ifdef SMFI_CURR_ACTS
	    return SMFI_CURR_ACTS;
#else
	    goto not_there;
#endif
	}
    case 'V':
	return constant_SMFI_V(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_SMFIS(char *name, int len, int arg)
{
    if (5 + 1 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[5 + 1]) {
    case 'A':
	if (strEQ(name + 5, "_ACCEPT")) {	/* SMFIS removed */
#ifdef SMFIS_ACCEPT
	    return SMFIS_ACCEPT;
#else
	    goto not_there;
#endif
	}
    case 'C':
	if (strEQ(name + 5, "_CONTINUE")) {	/* SMFIS removed */
#ifdef SMFIS_CONTINUE
	    return SMFIS_CONTINUE;
#else
	    goto not_there;
#endif
	}
    case 'D':
	if (strEQ(name + 5, "_DISCARD")) {	/* SMFIS removed */
#ifdef SMFIS_DISCARD
	    return SMFIS_DISCARD;
#else
	    goto not_there;
#endif
	}
    case 'R':
	if (strEQ(name + 5, "_REJECT")) {	/* SMFIS removed */
#ifdef SMFIS_REJECT
	    return SMFIS_REJECT;
#else
	    goto not_there;
#endif
	}
    case 'T':
	if (strEQ(name + 5, "_TEMPFAIL")) {	/* SMFIS removed */
#ifdef SMFIS_TEMPFAIL
	    return SMFIS_TEMPFAIL;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant(char *name, int len, int arg)
{
    errno = 0;
    if (0 + 4 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[0 + 4]) {
    case 'F':
	if (!strnEQ(name + 0,"SMFI", 4))
	    break;
	return constant_SMFIF(name, len, arg);
    case 'S':
	if (!strnEQ(name + 0,"SMFI", 4))
	    break;
	return constant_SMFIS(name, len, arg);
    case '_':
	if (!strnEQ(name + 0,"SMFI", 4))
	    break;
	return constant_SMFI_(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}


MODULE = Sendmail::Milter  PACKAGE = Sendmail::Milter  PREFIX = smfi_

PROTOTYPES:	DISABLE

double
constant(sv,arg)
    PREINIT:
	STRLEN		len;
    INPUT:
	SV *		sv
	char *		s = SvPV(sv, len);
	int		arg
    CODE:
	RETVAL = constant(s,len,arg);
    OUTPUT:
	RETVAL

bool
smfi_register(name, milter_desc_ref, flags=0)
	char*		name;
	SV*		milter_desc_ref;
	int		flags;
    CODE:
	RETVAL = MI_BOOL_CVT(milter_register(aTHX_ name, milter_desc_ref,
						flags));
    OUTPUT:
	RETVAL

bool
smfi_main(max_interpreters=0, max_requests=0)
	int		max_interpreters;
	int		max_requests;
    CODE:
	RETVAL = MI_BOOL_CVT(milter_main(max_interpreters, max_requests));
    OUTPUT:
	RETVAL

bool
smfi_setdbg(dbg)
	int		dbg;
    CODE:
	RETVAL = MI_BOOL_CVT(smfi_setdbg(dbg));
    OUTPUT:
	RETVAL

bool
smfi_setconn(conn)
	char*		conn;
    CODE:
	RETVAL = MI_BOOL_CVT(smfi_setconn(conn));
    OUTPUT:
	RETVAL

bool
smfi_settimeout(timeout)
	int		timeout;
    CODE:
	RETVAL = MI_BOOL_CVT(smfi_settimeout(timeout));
    OUTPUT:
	RETVAL

int
test_intpools(max_interp, max_requests, i_max, j_max, callback)
	int		max_interp;
	int		max_requests;
	int		i_max;
	int		j_max;
	SV*		callback;
    CODE:
	RETVAL = test_intpools(aTHX_ max_interp, max_requests, i_max, j_max,
				     callback);
    OUTPUT:
	RETVAL


MODULE = Sendmail::Milter  PACKAGE = Sendmail::Milter::Context  PREFIX = smfi_

char *
smfi_getsymval(Sendmail_Milter_Context ctx, char* symname)

bool
smfi_setreply(ctx, rcode, xcode, message)
	Sendmail_Milter_Context	ctx;
	char*		rcode;
	char*		xcode;
	char*		message;
    CODE:
	RETVAL = MI_BOOL_CVT(smfi_setreply(ctx, rcode, xcode, message));
    OUTPUT:
	RETVAL

bool
smfi_addheader(ctx, headerf, headerv)
	Sendmail_Milter_Context	ctx;
	char*		headerf;
	char*		headerv;
    CODE:
	RETVAL = MI_BOOL_CVT(smfi_addheader(ctx, headerf, headerv));
    OUTPUT:
	RETVAL

bool
smfi_chgheader(ctx, headerf, index, headerv)
	Sendmail_Milter_Context	ctx;
	char*		headerf;
	int		index;
	char*		headerv;
    CODE:
	RETVAL = MI_BOOL_CVT(smfi_chgheader(ctx, headerf, index, headerv));
    OUTPUT:
	RETVAL

bool
smfi_addrcpt(ctx, rcpt)
	Sendmail_Milter_Context	ctx;
	char*		rcpt;
    CODE:
	RETVAL = MI_BOOL_CVT(smfi_addrcpt(ctx, rcpt));
    OUTPUT:
	RETVAL

bool
smfi_delrcpt(ctx, rcpt)
	Sendmail_Milter_Context	ctx;
	char*		rcpt;
    CODE:
	RETVAL = MI_BOOL_CVT(smfi_delrcpt(ctx, rcpt));
    OUTPUT:
	RETVAL

bool
smfi_replacebody(ctx, body_data)
	Sendmail_Milter_Context	ctx;
	SV*		body_data;
    PREINIT:
	u_char *bodyp;
	int len;
    CODE:
	bodyp = SvPV(body_data, len);
	RETVAL = MI_BOOL_CVT(smfi_replacebody(ctx, bodyp, len));;
    OUTPUT:
	RETVAL

bool
smfi_setpriv(ctx, data)
	Sendmail_Milter_Context	ctx;
	SV*		data;
    CODE:
	if (SvTRUE(data))
		RETVAL = MI_BOOL_CVT(smfi_setpriv(ctx, (void *)newSVsv(data)));
	else
		RETVAL = MI_BOOL_CVT(smfi_setpriv(ctx, NULL));
    OUTPUT:
	RETVAL

SV *
smfi_getpriv(ctx)
	Sendmail_Milter_Context	ctx;
    CODE:
	RETVAL = (SV *) smfi_getpriv(ctx);
    OUTPUT:
	RETVAL
