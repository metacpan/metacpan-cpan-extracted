/* $Id: NIS.xs,v 1.6 1995/07/15 12:38:31 rik Exp $ */

#include <rpc/rpc.h>
#include <rpcsvc/yp_prot.h>
#include <rpcsvc/ypclnt.h>

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

struct callbackdata
{
  SV	*results;
  int	status;
};

static int
not_here(s)
char *s;
{
    croak("%s not implemented on this architecture", s);
    return -1;
}

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
    hv_store((HV*)SvRV(((struct callbackdata *)indata)->results), inkey,
      inkeylen, newSVpv(inval, invallen), (U32)0);
  }
  
  ((struct callbackdata *)indata)->status = ypprot_err(instatus);

  if (instatus < 0) return instatus;
  return 0;
}

/*
  $Net::NIS::ERR_ACCESS
  $Net::NIS::ERR_BADARGS
  $Net::NIS::ERR_BADDB
  $Net::NIS::ERR_BUSY
  $Net::NIS::ERR_DOMAIN
  $Net::NIS::ERR_KEY
  $Net::NIS::ERR_MAP
  $Net::NIS::ERR_NODOM
  $Net::NIS::ERR_PMAP
  $Net::NIS::ERR_NOMORE
  $Net::NIS::ERR_RESRC
  $Net::NIS::ERR_RPC
  $Net::NIS::ERR_YPBIND
  $Net::NIS::ERR_YPERR
  $Net::NIS::ERR_YPSERV
  $Net::NIS::ERR_VERS
*/

MODULE = Net::NIS	PACKAGE = Net::NIS

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
    int		status;

    status = yp_get_default_domain(&domain);
    XPUSHs(sv_2mortal(newSViv(status)));
    if (status == 0) XPUSHs(sv_2mortal(newSVpv(domain, strlen(domain))));
  }

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
    int		outvallen;
    int		status;
    
    if (SvPOK(key))
    {
      inkey = SvPV(key, inkeylen);

      status = yp_match(domain, map, inkey, (int)inkeylen, &outval, &outvallen);
      XPUSHs(sv_2mortal(newSViv(status)));
      if (status == 0) XPUSHs(sv_2mortal(newSVpv(outval, outvallen)));
    }
    else
    {
      XPUSHs(sv_2mortal(newSViv(YPERR_BADARGS)));
    }
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
    int		status;
    
    status = yp_first(domain, map, &outkey, &outkeylen, &outval, &outvallen);
    XPUSHs(sv_2mortal(newSViv(status)));
    if (status == 0)
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
    int		status;
    
    if (SvPOK(key))
    {
      inkey = SvPV(key, inkeylen);

      status = yp_next(domain, map, inkey, (int)inkeylen, &outkey, &outkeylen,
        &outval, &outvallen);
      XPUSHs(sv_2mortal(newSViv(status)));
      if (status == 0)
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
    int				status;

    data.results = sv_2mortal(newRV((SV *) newHV()));
    data.status = 0;
    callback.foreach = ypallcallback;
    callback.data = (char *)&data;
    XPUSHs(sv_newmortal());
    XPUSHs(sv_newmortal());
    status = yp_all(domain, map, &callback);
    sv_setnv(ST(0), data.status);
    if (status == 0 && data.status == YPERR_NOMORE)
      sv_setsv(ST(1), (SV *)data.results);
  }

void
yp_order(domain, map)
  char *	domain
  char *	map
  PPCODE:
  {
    unsigned long	order;
    int			status;

    status = yp_order(domain, map, &order);
    XPUSHs(sv_2mortal(newSViv(status)));
    if (status == 0) XPUSHs(sv_2mortal(newSViv(order)));
  }

void
yp_master(domain, map)
  char *	domain
  char *	map
  PPCODE:
  {
    char	*name;
    int		status;

    status = yp_master(domain, map, &name);
    XPUSHs(sv_2mortal(newSViv(status)));
    if (status == 0) XPUSHs(sv_2mortal(newSVpv(name, strlen(name))));
  }

char *
yperr_string(code)
  int		code

int
ypprot_err(code)
  int		code
