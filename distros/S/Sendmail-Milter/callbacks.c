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
#include <pthread.h>

#include "intpools.h"

#include "libmilter/mfapi.h"

/* Keys for each callback for the register callback hash */

#define KEY_CONNECT	newSVpv("connect", 0)
#define KEY_HELO	newSVpv("helo", 0)
#define KEY_ENVFROM	newSVpv("envfrom", 0)
#define KEY_ENVRCPT	newSVpv("envrcpt", 0)
#define KEY_HEADER	newSVpv("header", 0)
#define KEY_EOH		newSVpv("eoh", 0)
#define KEY_BODY	newSVpv("body", 0)
#define KEY_EOM		newSVpv("eom", 0)
#define KEY_ABORT	newSVpv("abort", 0)
#define KEY_CLOSE	newSVpv("close", 0)

/* Macro for pushing the SMFICTX * argument */

#define XPUSHs_Sendmail_Milter_Context	\
	(XPUSHs(sv_2mortal(sv_setref_iv(NEWSV(25, 0), \
		"Sendmail::Milter::Context", (IV) ctx))))

/* Global callback variable names */

#define GLOBAL_CONNECT		"Sendmail::Milter::Callbacks::_xxfi_connect"
#define GLOBAL_HELO		"Sendmail::Milter::Callbacks::_xxfi_helo"
#define GLOBAL_ENVFROM		"Sendmail::Milter::Callbacks::_xxfi_envfrom"
#define GLOBAL_ENVRCPT		"Sendmail::Milter::Callbacks::_xxfi_envrcpt"
#define GLOBAL_HEADER		"Sendmail::Milter::Callbacks::_xxfi_header"
#define GLOBAL_EOH		"Sendmail::Milter::Callbacks::_xxfi_eoh"
#define GLOBAL_BODY		"Sendmail::Milter::Callbacks::_xxfi_body"
#define GLOBAL_EOM		"Sendmail::Milter::Callbacks::_xxfi_eom"
#define GLOBAL_ABORT		"Sendmail::Milter::Callbacks::_xxfi_abort"
#define GLOBAL_CLOSE		"Sendmail::Milter::Callbacks::_xxfi_close"


/* Callback prototypes for first-level callback wrappers. */

sfsistat hook_connect(SMFICTX *, char *, _SOCK_ADDR *);
sfsistat hook_helo(SMFICTX *, char *);
sfsistat hook_envfrom(SMFICTX *, char **);
sfsistat hook_envrcpt(SMFICTX *, char **);
sfsistat hook_header(SMFICTX *, char *, char *);
sfsistat hook_eoh(SMFICTX *);
sfsistat hook_body(SMFICTX *, u_char *, size_t);
sfsistat hook_eom(SMFICTX *);
sfsistat hook_abort(SMFICTX *);
sfsistat hook_close(SMFICTX *);


/* A structure for housing callbacks and their mutexes. */

struct callback_cache_t
{
	SV *xxfi_connect;
	SV *xxfi_helo;
	SV *xxfi_envfrom;
	SV *xxfi_envrcpt;
	SV *xxfi_header;
	SV *xxfi_eoh;
	SV *xxfi_body;
	SV *xxfi_eom;
	SV *xxfi_abort;
	SV *xxfi_close;
};

typedef struct callback_cache_t callback_cache_t;


/* The Milter perl interpreter pool */

static intpool_t I_pool;


/* Routines for managing callback caches */

void
init_callback_cache(pTHX_ interp_t *interp)
{
	callback_cache_t *cache_ptr;

	if (interp->cache != NULL)
		return;

	alloc_interpreter_cache(interp, sizeof(callback_cache_t));

	cache_ptr = (callback_cache_t *)interp->cache;

	cache_ptr->xxfi_connect =	get_sv(GLOBAL_CONNECT,	FALSE);
	cache_ptr->xxfi_helo =		get_sv(GLOBAL_HELO,	FALSE);
	cache_ptr->xxfi_envfrom =	get_sv(GLOBAL_ENVFROM,	FALSE);
	cache_ptr->xxfi_envrcpt =	get_sv(GLOBAL_ENVRCPT,	FALSE);
	cache_ptr->xxfi_header =	get_sv(GLOBAL_HEADER,	FALSE);
	cache_ptr->xxfi_eoh =		get_sv(GLOBAL_EOH,	FALSE);
	cache_ptr->xxfi_body =		get_sv(GLOBAL_BODY,	FALSE);
	cache_ptr->xxfi_eom =		get_sv(GLOBAL_EOM,	FALSE);
	cache_ptr->xxfi_abort =		get_sv(GLOBAL_ABORT,	FALSE);
	cache_ptr->xxfi_close =		get_sv(GLOBAL_CLOSE,	FALSE);
}


/* Set global variables in the parent interpreter. */

void
init_callback(char *var_name, SV *parent_callback)
{
	SV *new_sv;

	new_sv = get_sv(var_name, TRUE);
	sv_setsv(new_sv, parent_callback);
}


/* Main interfaces. */

void
init_callbacks(max_interpreters, max_requests)
	int max_interpreters;
	int max_requests;
{
	init_interpreters(&I_pool, max_interpreters, max_requests);
}


SV *
get_callback(perl_desc, key)
	HV *perl_desc;
	SV *key;
{
	HE *entry;

	entry = hv_fetch_ent(perl_desc, key, 0, 0);

	if (entry == NULL)
		croak("couldn't fetch callback symbol from descriptor.");

	return newSVsv(HeVAL(entry));
}


void
register_callbacks(desc, name, my_callback_table, flags)
	struct smfiDesc		*desc;
	char			*name;
	HV			*my_callback_table;
	int			flags;
{
	memset(desc, '\0', sizeof(struct smfiDesc));

	desc->xxfi_name = strdup(name);
	desc->xxfi_version = SMFI_VERSION;
	desc->xxfi_flags = flags;

	if (hv_exists_ent(my_callback_table, KEY_CONNECT, 0))
	{
		init_callback(GLOBAL_CONNECT,
			get_callback(my_callback_table, KEY_CONNECT));

		desc->xxfi_connect =	hook_connect;
	}

	if (hv_exists_ent(my_callback_table, KEY_HELO, 0))
	{
		init_callback(GLOBAL_HELO,
			get_callback(my_callback_table, KEY_HELO));

		desc->xxfi_helo	=	hook_helo;
	}

	if (hv_exists_ent(my_callback_table, KEY_ENVFROM, 0))
	{
		init_callback(GLOBAL_ENVFROM,
			get_callback(my_callback_table, KEY_ENVFROM));

		desc->xxfi_envfrom =	hook_envfrom;
	}

	if (hv_exists_ent(my_callback_table, KEY_ENVRCPT, 0))
	{
		init_callback(GLOBAL_ENVRCPT,
			get_callback(my_callback_table, KEY_ENVRCPT));

		desc->xxfi_envrcpt =	hook_envrcpt;
	}

	if (hv_exists_ent(my_callback_table, KEY_HEADER, 0))
	{
		init_callback(GLOBAL_HEADER,
			get_callback(my_callback_table, KEY_HEADER));

		desc->xxfi_header =	hook_header;
	}

	if (hv_exists_ent(my_callback_table, KEY_EOH, 0))
	{
		init_callback(GLOBAL_EOH,
			get_callback(my_callback_table, KEY_EOH));

		desc->xxfi_eoh =	hook_eoh;
	}

	if (hv_exists_ent(my_callback_table, KEY_BODY, 0))
	{
		init_callback(GLOBAL_BODY,
			get_callback(my_callback_table, KEY_BODY));

		desc->xxfi_body =	hook_body;
	}

	if (hv_exists_ent(my_callback_table, KEY_EOM, 0))
	{
		init_callback(GLOBAL_EOM,
			get_callback(my_callback_table, KEY_EOM));

		desc->xxfi_eom =	hook_eom;
	}

	if (hv_exists_ent(my_callback_table, KEY_ABORT, 0))
	{
		init_callback(GLOBAL_ABORT,
			get_callback(my_callback_table, KEY_ABORT));

		desc->xxfi_abort =	hook_abort;
	}

	if (hv_exists_ent(my_callback_table, KEY_CLOSE, 0))
	{
		init_callback(GLOBAL_CLOSE,
			get_callback(my_callback_table, KEY_CLOSE));

		desc->xxfi_close =	hook_close;
	}
}


/* Second-layer callbacks. These do the actual work. */

sfsistat
callback_noargs(pTHX_ SV *callback, SMFICTX *ctx)
{
	int n;
	sfsistat retval;
	dSP;
	ENTER;
	SAVETMPS;
	PUSHMARK(SP);

	XPUSHs_Sendmail_Milter_Context;

	PUTBACK;

	n = call_sv(callback, G_EVAL | G_SCALAR);

	SPAGAIN;

	/* Check the eval first. */
	if (SvTRUE(ERRSV))
	{
		POPs;
		retval = SMFIS_TEMPFAIL;
	}
	else if (n == 1)
	{
		retval = (sfsistat) POPi;
	}
	else
	{
		retval = SMFIS_CONTINUE;
	}

	PUTBACK;
	FREETMPS;
	LEAVE;

	return retval;
}

sfsistat
callback_s(pTHX_ SV *callback, SMFICTX *ctx, char *arg1)
{
	int n;
	sfsistat retval;
	dSP;
	ENTER;
	SAVETMPS;
	PUSHMARK(SP);

	XPUSHs_Sendmail_Milter_Context;
	XPUSHs(sv_2mortal(newSVpv(arg1, 0)));

	PUTBACK;

	n = call_sv(callback, G_EVAL | G_SCALAR);

	SPAGAIN;

	/* Check the eval first. */
	if (SvTRUE(ERRSV))
	{
		POPs;
		retval = SMFIS_TEMPFAIL;
	}
	else if (n == 1)
	{
		retval = (sfsistat) POPi;
	}
	else
	{
		retval = SMFIS_CONTINUE;
	}

	PUTBACK;
	FREETMPS;
	LEAVE;

	return retval;
}

sfsistat
callback_body(pTHX_ SV *callback, SMFICTX *ctx,
	            u_char *arg1, size_t arg2)
{
	int n;
	sfsistat retval;
	dSP;
	ENTER;
	SAVETMPS;
	PUSHMARK(SP);

	XPUSHs_Sendmail_Milter_Context;
	XPUSHs(sv_2mortal(newSVpvn(arg1, arg2)));
	XPUSHs(sv_2mortal(newSViv((IV) arg2)));

	PUTBACK;

	n = call_sv(callback, G_EVAL | G_SCALAR);

	SPAGAIN;

	/* Check the eval first. */
	if (SvTRUE(ERRSV))
	{
		POPs;
		retval = SMFIS_TEMPFAIL;
	}
	else if (n == 1)
	{
		retval = (sfsistat) POPi;
	}
	else
	{
		retval = SMFIS_CONTINUE;
	}

	PUTBACK;
	FREETMPS;
	LEAVE;

	return retval;
}

sfsistat
callback_argv(pTHX_ SV *callback, SMFICTX *ctx, char **arg1)
{
	int n;
	sfsistat retval;
	char **iter = arg1;
	dSP;
	ENTER;
	SAVETMPS;
	PUSHMARK(SP);

	XPUSHs_Sendmail_Milter_Context;

	while(iter != NULL)
	{
		if (*iter == NULL)
			break;

		XPUSHs(sv_2mortal(newSVpv(*iter, 0)));
		iter++;
	}

	PUTBACK;

	n = call_sv(callback, G_EVAL | G_SCALAR);

	SPAGAIN;

	/* Check the eval first. */
	if (SvTRUE(ERRSV))
	{
		POPs;
		retval = SMFIS_TEMPFAIL;
	}
	else if (n == 1)
	{
		retval = (sfsistat) POPi;
	}
	else
	{
		retval = SMFIS_CONTINUE;
	}

	PUTBACK;
	FREETMPS;
	LEAVE;

	return retval;
}

sfsistat
callback_ss(pTHX_ SV *callback, SMFICTX *ctx, char *arg1, char *arg2)
{
	int n;
	sfsistat retval;
	dSP;
	ENTER;
	SAVETMPS;
	PUSHMARK(SP);

	XPUSHs_Sendmail_Milter_Context;
	XPUSHs(sv_2mortal(newSVpv(arg1, 0)));
	XPUSHs(sv_2mortal(newSVpv(arg2, 0)));

	PUTBACK;

	n = call_sv(callback, G_EVAL | G_SCALAR);

	SPAGAIN;

	/* Check the eval first. */
	if (SvTRUE(ERRSV))
	{
		POPs;
		retval = SMFIS_TEMPFAIL;
	}
	else if (n == 1)
	{
		retval = (sfsistat) POPi;
	}
	else
	{
		retval = SMFIS_CONTINUE;
	}

	PUTBACK;
	FREETMPS;
	LEAVE;

	return retval;
}

sfsistat
callback_ssockaddr(pTHX_ SV *callback, SMFICTX *ctx, char *arg1,
		   _SOCK_ADDR *arg_sa)
{
	int n;
	sfsistat retval;
	dSP;
	ENTER;
	SAVETMPS;
	PUSHMARK(SP);

	XPUSHs_Sendmail_Milter_Context;

	XPUSHs(sv_2mortal(newSVpv(arg1, 0)));

	/* A Perl sockaddr_in is all we handle right now. */
	if (arg_sa == NULL)
	{
		XPUSHs(sv_2mortal(newSVsv(&PL_sv_undef)));
	}
	else if (arg_sa->sa_family == AF_INET)
	{
		XPUSHs(sv_2mortal(newSVpvn((char *)arg_sa,
					   sizeof(_SOCK_ADDR))));
	}
	else
	{
		XPUSHs(sv_2mortal(newSVsv(&PL_sv_undef)));
	}

	PUTBACK;

	n = call_sv(callback, G_EVAL | G_SCALAR);

	SPAGAIN;

	/* Check the eval first. */
	if (SvTRUE(ERRSV))
	{
		POPs;
		retval = SMFIS_TEMPFAIL;
	}
	else if (n == 1)
	{
		retval = (sfsistat) POPi;
	}
	else
	{
		retval = SMFIS_CONTINUE;
	}

	PUTBACK;
	FREETMPS;
	LEAVE;

	return retval;
}


/* First-layer callbacks */

sfsistat
hook_connect(ctx, hostname, hostaddr)
	SMFICTX		*ctx;
	char		*hostname;
	_SOCK_ADDR	*hostaddr;
{
	interp_t *interp;
	sfsistat retval;
	SV *callback;

	if ((interp = lock_interpreter(&I_pool)) == NULL)
		croak("could not lock a new perl interpreter.");

	PERL_SET_CONTEXT(interp->perl);

	init_callback_cache(aTHX_ interp);
	callback = ((callback_cache_t *)(interp->cache))->xxfi_connect;

	retval = callback_ssockaddr(aTHX_ callback, ctx,
					  hostname, hostaddr);

	unlock_interpreter(&I_pool, interp);

	return retval;
}

sfsistat
hook_helo(ctx, helohost)
	SMFICTX		*ctx;
	char		*helohost;
{
	interp_t *interp;
	sfsistat retval;
	SV *callback;

	if ((interp = lock_interpreter(&I_pool)) == NULL)
		croak("could not lock a new perl interpreter.");

	PERL_SET_CONTEXT(interp->perl);

	init_callback_cache(aTHX_ interp);
	callback = ((callback_cache_t *)(interp->cache))->xxfi_helo;

	retval = callback_s(aTHX_ callback, ctx, helohost);

	unlock_interpreter(&I_pool, interp);

	return retval;
}

sfsistat
hook_envfrom(ctx, argv)
	SMFICTX *ctx;
	char **argv;
{
	interp_t *interp;
	sfsistat retval;
	SV *callback;

	if ((interp = lock_interpreter(&I_pool)) == NULL)
		croak("could not lock a new perl interpreter.");

	PERL_SET_CONTEXT(interp->perl);

	init_callback_cache(aTHX_ interp);
	callback = ((callback_cache_t *)(interp->cache))->xxfi_envfrom;

	retval = callback_argv(aTHX_ callback, ctx, argv);

	unlock_interpreter(&I_pool, interp);

	return retval;
}

sfsistat
hook_envrcpt(ctx, argv)
	SMFICTX *ctx;
	char **argv;
{
	interp_t *interp;
	sfsistat retval;
	SV *callback;

	if ((interp = lock_interpreter(&I_pool)) == NULL)
		croak("could not lock a new perl interpreter.");

	PERL_SET_CONTEXT(interp->perl);

	init_callback_cache(aTHX_ interp);
	callback = ((callback_cache_t *)(interp->cache))->xxfi_envrcpt;

	retval = callback_argv(aTHX_ callback, ctx, argv);

	unlock_interpreter(&I_pool, interp);

	return retval;
}

sfsistat
hook_header(ctx, headerf, headerv)
	SMFICTX *ctx;
	char *headerf;
	char *headerv;
{
	interp_t *interp;
	sfsistat retval;
	SV *callback;

	if ((interp = lock_interpreter(&I_pool)) == NULL)
		croak("could not lock a new perl interpreter.");

	PERL_SET_CONTEXT(interp->perl);

	init_callback_cache(aTHX_ interp);
	callback = ((callback_cache_t *)(interp->cache))->xxfi_header;

	retval = callback_ss(aTHX_ callback, ctx, headerf, headerv);

	unlock_interpreter(&I_pool, interp);

	return retval;
}

sfsistat
hook_eoh(ctx)
	SMFICTX *ctx;
{
	interp_t *interp;
	sfsistat retval;
	SV *callback;

	if ((interp = lock_interpreter(&I_pool)) == NULL)
		croak("could not lock a new perl interpreter.");

	PERL_SET_CONTEXT(interp->perl);

	init_callback_cache(aTHX_ interp);
	callback = ((callback_cache_t *)(interp->cache))->xxfi_eoh;

	retval = callback_noargs(aTHX_ callback, ctx);

	unlock_interpreter(&I_pool, interp);

	return retval;
}

sfsistat
hook_body(ctx, bodyp, bodylen)
	SMFICTX *ctx;
	u_char *bodyp;
	size_t bodylen;
{
	interp_t *interp;
	sfsistat retval;
	SV *callback;

	if ((interp = lock_interpreter(&I_pool)) == NULL)
		croak("could not lock a new perl interpreter.");

	PERL_SET_CONTEXT(interp->perl);

	init_callback_cache(aTHX_ interp);
	callback = ((callback_cache_t *)(interp->cache))->xxfi_body;

	retval = callback_body(aTHX_ callback, ctx, bodyp, bodylen);

	unlock_interpreter(&I_pool, interp);

	return retval;
}

sfsistat
hook_eom(ctx)
	SMFICTX *ctx;
{
	interp_t *interp;
	sfsistat retval;
	SV *callback;

	if ((interp = lock_interpreter(&I_pool)) == NULL)
		croak("could not lock a new perl interpreter.");

	PERL_SET_CONTEXT(interp->perl);

	init_callback_cache(aTHX_ interp);
	callback = ((callback_cache_t *)(interp->cache))->xxfi_eom;

	retval = callback_noargs(aTHX_ callback, ctx);

	unlock_interpreter(&I_pool, interp);

	return retval;
}

sfsistat
hook_abort(ctx)
	SMFICTX *ctx;
{
	interp_t *interp;
	sfsistat retval;
	SV *callback;

	if ((interp = lock_interpreter(&I_pool)) == NULL)
		croak("could not lock a new perl interpreter.");

	PERL_SET_CONTEXT(interp->perl);

	init_callback_cache(aTHX_ interp);
	callback = ((callback_cache_t *)(interp->cache))->xxfi_abort;

	retval = callback_noargs(aTHX_ callback, ctx);

	unlock_interpreter(&I_pool, interp);

	return retval;
}

sfsistat
hook_close(ctx)
	SMFICTX *ctx;
{
	interp_t *interp;
	sfsistat retval;
	SV *callback;

	if ((interp = lock_interpreter(&I_pool)) == NULL)
		croak("could not lock a new perl interpreter.");

	PERL_SET_CONTEXT(interp->perl);

	init_callback_cache(aTHX_ interp);
	callback = ((callback_cache_t *)(interp->cache))->xxfi_close;

	retval = callback_noargs(aTHX_ callback, ctx);

	unlock_interpreter(&I_pool, interp);

	return retval;
}

