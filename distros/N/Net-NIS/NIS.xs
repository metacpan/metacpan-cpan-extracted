/* -*- c -*-
**
** Filename: NIS.xs - back end for the Net::NIS package
**
** $Id$
*/

#include <sys/types.h>		/* Needed on FreeBSD */
#include <rpc/rpc.h>
#include <rpcsvc/yp_prot.h>
#include <rpcsvc/ypclnt.h>

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

/*
** The *THX_ macros seem to be 5.6 and above.
**
** Nobody should be running 5.005 any more, but still, it's not my place
** to judge.  If someone wants to, let's try to let them.
*/
#ifndef	 pTHX_
# define pTHX_
#endif	/* pTHX */

/*
** FIXME: if we ever support new YPERR_xxx values, this must be updated!
*/
#define	YPERR_MAX	YPERR_BUSY


/* Solaris doesn't define YPERR_SUCCESS */
#ifndef	YPERR_SUCCESS
#define	YPERR_SUCCESS 0
#endif	/* YPERR_SUCCESS */



/*
** Slight interface change: NIS-a2 would always return ($status, $value).
** We use the GIMME_V macro to determine if our caller wants array or
** scalar.  If array, return the same as before.  If scalar, just return
** the desired value.  Error status will always be available through the
** magic "tied" variable.
*/
#define	YP_RETURN(val)							\
		do {							\
		    if (GIMME_V == G_ARRAY)				\
			XPUSHs(sv_2mortal(newSViv(yp_status)));		\
		    if (yp_status == YPERR_SUCCESS)			\
			XPUSHs(sv_2mortal(val));			\
		    else						\
			XPUSHs(&PL_sv_undef);				\
		} while (0)



struct callbackdata
{
  SV	*results;
  int	status;
};

/* ESM: What's this?  It doesn't seem to be used, nor part of the API?? */
static int
not_here(s)
char *s;
{
    croak("%s not implemented on this architecture", s);
    return -1;
}


/* Invoked by AUTOLOAD, returns int values of the YPERR_<xxx> constants */
static double
constant(name, arg)
char *name;
int arg;
{
    errno = 0;

    if (strEQ(name, "YPERR_ACCESS"))
#ifdef YPERR_ACCESS
	return YPERR_ACCESS;
#else
	goto not_there;
#endif
    if (strEQ(name, "YPERR_BADARGS"))
#ifdef YPERR_BADARGS
	return YPERR_BADARGS;
#else
	goto not_there;
#endif
    if (strEQ(name, "YPERR_BADDB"))
#ifdef YPERR_BADDB
	return YPERR_BADDB;
#else
	goto not_there;
#endif
    if (strEQ(name, "YPERR_BUSY"))
#ifdef YPERR_BUSY
	return YPERR_BUSY;
#else
	goto not_there;
#endif
    if (strEQ(name, "YPERR_DOMAIN"))
#ifdef YPERR_DOMAIN
	return YPERR_DOMAIN;
#else
	goto not_there;
#endif
    if (strEQ(name, "YPERR_KEY"))
#ifdef YPERR_KEY
	return YPERR_KEY;
#else
	goto not_there;
#endif
    if (strEQ(name, "YPERR_MAP"))
#ifdef YPERR_MAP
	return YPERR_MAP;
#else
	goto not_there;
#endif
    if (strEQ(name, "YPERR_NODOM"))
#ifdef YPERR_NODOM
	return YPERR_NODOM;
#else
	goto not_there;
#endif
    if (strEQ(name, "YPERR_NOMORE"))
#ifdef YPERR_NOMORE
	return YPERR_NOMORE;
#else
	goto not_there;
#endif
    if (strEQ(name, "YPERR_PMAP"))
#ifdef YPERR_PMAP
	return YPERR_PMAP;
#else
	goto not_there;
#endif
    if (strEQ(name, "YPERR_RESRC"))
#ifdef YPERR_RESRC
	return YPERR_RESRC;
#else
	goto not_there;
#endif
    if (strEQ(name, "YPERR_RPC"))
#ifdef YPERR_RPC
	return YPERR_RPC;
#else
	goto not_there;
#endif
    if (strEQ(name, "YPERR_SUCCESS"))
#ifdef YPERR_SUCCESS
	return YPERR_SUCCESS;
#else
	goto not_there;
#endif
    if (strEQ(name, "YPERR_VERS"))
#ifdef YPERR_VERS
	return YPERR_VERS;
#else
	goto not_there;
#endif
    if (strEQ(name, "YPERR_YPBIND"))
#ifdef YPERR_YPBIND
	return YPERR_YPBIND;
#else
	goto not_there;
#endif
    if (strEQ(name, "YPERR_YPERR"))
#ifdef YPERR_YPERR
	return YPERR_YPERR;
#else
	goto not_there;
#endif
    if (strEQ(name, "YPERR_YPSERV"))
#ifdef YPERR_YPSERV
	return YPERR_YPSERV;
#else
	goto not_there;
#endif

    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}


/*****************************************************************************\
**                     Whee!  Magic yp_status variable!                      *|
\*****************************************************************************/
static int yp_status;

/*
** When perl scripts read its value, e.g.:
**
**     tie %map, 'Net::NIS', $mapname
**       or die "Could not tie $mapname: $yp_status\n"
**
*/
static int yp_status_get(pTHX_ SV *sv, MAGIC *m)
{
    /*
    ** First set the numeric value (double -- int doesn't do the right thing),
    ** then set the string value.  The SvNOK_on() is copied unaltered from
    ** perl-5.6.1/mg.c, including the wonderful comment.  It makes "sv"
    ** work both as a string and as a number.
    **
    ** Note that if yp_status is 0 we use an emtpy string, so script can do:
    **
    **        $yp_status_varname and die "blah blah: $yp_..."
    **
    ** ...without worrying about "0" status being translated as "Success"
    */
    sv_setnv (sv, yp_status);
    sv_setpv (sv, yp_status == YPERR_SUCCESS ? "" : yperr_string (yp_status));

    SvNOK_on(sv);   /* what a wonderful hack! */

    return 1;
}

/*
** This seems useful only for testing: $yperr = 0 (or something else)
*/
static int yp_status_set(pTHX_ SV *sv, MAGIC *m)
{
    int new_val = SvIV(sv);

    /* Only allow setting this var to one of our supported YPERR_xxx vals */
    if (new_val < YPERR_SUCCESS || YPERR_MAX < new_val)
	croak("Value out of range");

    yp_status = new_val;

    return 1;
}

MGVTBL yp_status_accessors = {
    yp_status_get, yp_status_set,
};


/*****************************************************************************\
|*                     Callback used by yp_all()                             *|
\*****************************************************************************/

int
ypallcallback(instatus, inkey, inkeylen, inval, invallen, indata)
int     instatus;
char    *inkey;
int     inkeylen;
char    *inval;
int     invallen;
char    *indata;
{
    if (instatus == YP_TRUE)
    {
	/* Ugh.  Sometimes we get back keys (or values) with a trailing NUL. */
	if (0 < inkeylen && inkey[inkeylen - 1] == '\0')
	    --inkeylen;
	if (0 < invallen && inval[invallen - 1] == '\0')
	    --invallen;

	/* Don't allow a zero-length key -- but zero-length value ("") is OK */
	if (0 < inkeylen) {
	    hv_store((HV*)SvRV(((struct callbackdata *)indata)->results),
		             inkey, inkeylen,
		     newSVpv(inval, invallen), (U32)0);
	}
    }

    ((struct callbackdata *)indata)->status = ypprot_err(instatus);

    if (instatus < 0) return instatus;
    return 0;
}


MODULE = Net::NIS	PACKAGE = Net::NIS

 #
 # YPERR_xxx constants, enumerated above
 #
double
constant(name,arg)
	char *		name
	int		arg

int
yp_bind(domain)
  char *	domain

void
yp_unbind(domain)
  char *	domain

void
yp_get_default_domain()
  PPCODE:
  {
    char	*domain;

    yp_status = yp_get_default_domain(&domain);

    YP_RETURN(newSVpv(domain, strlen(domain)));
  }

 #
 # Looks up a key in a given map (this implements the FETCH part)
 #
void
yp_match(domain, map, key)
  char *	domain
  char *	map
  SV *		key
  PPCODE:
  {
    char	*inkey;
    STRLEN	inkeylen;
    char	*outval;
    int		outvallen = 0;

    if (SvPOK(key))
    {
	inkey = SvPV(key, inkeylen);

	yp_status = yp_match(domain, map, inkey, (int)inkeylen,
			     &outval, &outvallen);
	/* Sigh.  Sometimes we have to include the trailing NUL */
	if (yp_status == YPERR_KEY)
	    yp_status = yp_match(domain, map, inkey, (int)inkeylen+1,
				 &outval, &outvallen);

	/* Like above, sometimes we get an extra trailing NUL char */
	if (yp_status == YPERR_SUCCESS)
	    if (0 < outvallen && outval[outvallen-1] == '\0')
		--outvallen;

    }
    else
    {
	yp_status = YPERR_BADARGS;
    }

    YP_RETURN(newSVpv(outval, outvallen));
  }

void
yp_first(domain, map)
  char *	domain
  char *	map
  PPCODE:
  {
    char	*outkey;
    int		outkeylen;
    char	*outval;
    int		outvallen;

    yp_status = yp_first(domain, map, &outkey, &outkeylen,
			              &outval, &outvallen);
    XPUSHs(sv_2mortal(newSViv(yp_status)));
    if (yp_status == 0)
    {
	XPUSHs(sv_2mortal(newSVpv(outkey, outkeylen)));
	XPUSHs(sv_2mortal(newSVpv(outval, outvallen)));
    }
  }

void
yp_next(domain, map, key)
  char *	domain
  char *	map
  SV *		key
  PPCODE:
  {
    char	*inkey;
    STRLEN	inkeylen;
    char	*outkey;
    int 	outkeylen;
    char	*outval;
    int		outvallen;

    if (SvPOK(key))
    {
	inkey = SvPV(key, inkeylen);

	yp_status = yp_next(domain, map, inkey, (int)inkeylen,
			    &outkey, &outkeylen, &outval, &outvallen);
	XPUSHs(sv_2mortal(newSViv(yp_status)));
	if (yp_status == 0)
	{
	    XPUSHs(sv_2mortal(newSVpv(outkey, outkeylen)));
	    XPUSHs(sv_2mortal(newSVpv(outval, outvallen)));
	}
    }
    else
    {
	XPUSHs(sv_2mortal(newSViv(YPERR_BADARGS)));
    }
  }

void
yp_all(domain, map)
  char *	domain
  char *	map
  PPCODE:
  {
    struct ypall_callback	callback;
    struct callbackdata		data;

    data.results = newRV((SV *) newHV());
    data.status = 0;
    callback.foreach = ypallcallback;
    callback.data = (char *)&data;
    yp_status = yp_all(domain, map, &callback);

    if (yp_status == YPERR_SUCCESS) {
	# Linux & Solaris see NOMORE, FreeBSD gets a plain 0
	if (data.status == YPERR_NOMORE ||
	    data.status == YPERR_SUCCESS) {
	    yp_status = YPERR_SUCCESS;
	}
	else {			/* Unexpected value in callback status block */
	    yp_status = data.status;
	}
    }

    YP_RETURN((SV*)data.results);
  }

void
yp_order(domain, map)
  char *	domain
  char *	map
  PPCODE:
  {
    unsigned long	order;

    yp_status = yp_order(domain, map, &order);
    YP_RETURN(newSViv(order));
  }

void
yp_master(domain, map)
  char *	domain
  char *	map
  PPCODE:
  {
    char	*name;

    yp_status = yp_master(domain, map, &name);
    YP_RETURN(newSVpv(name, strlen(name)));
  }

char *
yperr_string(code)
  int		code

int
ypprot_err(code)
  int		code

 #
 # Tie the magic yp_status variable.  This should be called from our .pm
 #
void
_yp_tie_status(sv)
	SV*	sv
    PREINIT:
	MAGIC *m;
    CODE:
	sv_magic(sv, NULL, '~', "Net::NIS::yp_status_variable",
		         strlen("Net::NIS::yp_status_variable"));
	m = mg_find(sv, '~');
	m->mg_virtual = &yp_status_accessors;
	SvMAGICAL_on(sv);

#ifdef	__linux

  #
  # Returns an array of all the YP map names
  #
void
yp_maplist(domain)
  char *	domain
  PREINIT:
	int		  ret;
	struct ypmaplist *ypmap = NULL;
	AV		 *retval;
  PPCODE:
  {
    ret = yp_maplist( domain, &ypmap );

    if (ret == YPERR_SUCCESS) {
      struct ypmaplist *y, *old;

      for (y=ypmap; y;) {
	// FIXME: check that y->map is not NULL?
	XPUSHs(newSVpv(y->ypml_name,strlen(y->ypml_name)));
	old = y;
	y   = y->ypml_next;
	free(old);
      }
    }
  }


#else	/* Linux */

void
yp_maplist(domain)
    char *	domain
  PPCODE:
  {
    warn("Net::NIS::yp_maplist() -- not implemented on this OS");
    XSRETURN_EMPTY;
  }

#endif
