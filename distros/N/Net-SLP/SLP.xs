// SLP.xs

// XS file for Net::SLP
// Author: Mike McCauley (mikem@open.com.au)
// Copyright (C) 2004 Mike McCauley
// $Id: SLP.xs,v 1.3 2007/06/20 22:46:15 mikem Exp mikem $

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <slp.h>
#define SLP_FALSE 0
#define SLP_TRUE 1
#include "const-c.inc"

// Callback when a URL is available from SLPFindSrvs
// cookie is a perl closure, which is expected to be called
SLPBoolean
slp_url_callback_glue(SLPHandle hSLP,
    const char* pcSrvURL,
    unsigned short sLifetime,
    SLPError errCode,
    void *pvCookie)
{
    dSP;
    int        count;
    SLPBoolean result;

    if (pvCookie == NULL)
        croak ("Net::SLP: slp_url_callback_glue called without a callback function.\n");
    ENTER;
    SAVETMPS;

    PUSHMARK(sp);
    if (pcSrvURL)
        XPUSHs(sv_2mortal(newSVpv(pcSrvURL, 0)));
    else
        XPUSHs(sv_2mortal(newSVsv(&PL_sv_undef))); // Nothing there
      
    XPUSHs(sv_2mortal(newSViv(sLifetime)));
    XPUSHs(sv_2mortal(newSViv(errCode)));
    PUTBACK;
    count = call_sv(pvCookie, G_SCALAR);
    SPAGAIN;
    if (count != 1)
        croak ("Net::SLP: slp_url_callback_glue callback did not return a scalar.\n");
    // The return code from the closure is important
    // Returning SLP_TRUE asks for more data. SLP_FALSE means no more data please
    result = POPi;
    PUTBACK;
    FREETMPS;
    LEAVE;

    return result;
}

// Callback when a service type is available from SLPFindSrvTypes
// cookie is a perl closure, which is expected to be called
SLPBoolean
slp_srvtype_callback_glue(SLPHandle hSLP,
    const char* pcSrvTypes,
    SLPError errCode,
    void *pvCookie)
{
    dSP;
    int        count;
    SLPBoolean result;

    if (pvCookie == NULL)
        croak ("Net::SLP: slp_srvtype_callback_glue called without a callback function.\n");
    ENTER;
    SAVETMPS;

    PUSHMARK(sp);
    if (pcSrvTypes)
        XPUSHs(sv_2mortal(newSVpv(pcSrvTypes, 0)));
    else
        XPUSHs(sv_2mortal(newSVsv(&PL_sv_undef))); // Nothing there
    XPUSHs(sv_2mortal(newSViv(errCode)));
    PUTBACK;
    count = call_sv(pvCookie, G_SCALAR);
    SPAGAIN;
    if (count != 1)
        croak ("Net::SLP: slp_srvtype_callback_glue callback did not return a scalar.\n");
    // The return code from the closure is important
    // Returning SLP_TRUE asks for more data. SLP_FALSE means no more data please
    result = POPi;
    PUTBACK;
    FREETMPS;
    LEAVE;

    return result;
}

// Callback when a service type is available from SLPFindAttrs
// cookie is a perl closure, which is expected to be called
SLPBoolean
slp_attr_callback_glue(SLPHandle hSLP,
    const char* pcAttrList,
    SLPError errCode,
    void *pvCookie)
{
    dSP;
    int        count;
    SLPBoolean result = SLP_TRUE;

    if (pvCookie == NULL)
        croak ("Net::SLP: slp_attr_callback_glue called without a callback function.\n");
    ENTER;
    SAVETMPS;

    PUSHMARK(sp);
    if (pcAttrList)
        XPUSHs(sv_2mortal(newSVpv(pcAttrList, 0)));
    else
        XPUSHs(sv_2mortal(newSVsv(&PL_sv_undef))); // Nothing there
    XPUSHs(sv_2mortal(newSViv(errCode)));
    PUTBACK;
    count = call_sv(pvCookie, G_SCALAR);
    SPAGAIN;
    PUTBACK;
    FREETMPS;
    LEAVE;

    return result;
}

// Callback when a service is registered or deregisted with 
// SLPReg(), SLPDeReg() and SLPDelAttrs() functions.
// cookie is a perl closure, which is expected to be called
void
slp_reg_callback_glue(SLPHandle hSLP,
    SLPError errCode,
    void *pvCookie)
{
    dSP;
    int        count;
    SLPBoolean result;

    if (pvCookie == NULL)
        croak ("Net::SLP: slp_reg_callback_glue called without a callback function.\n");
    ENTER;
    SAVETMPS;
    PUSHMARK(sp);
    XPUSHs(sv_2mortal(newSViv(errCode)));
    PUTBACK;
    count = call_sv(pvCookie, G_SCALAR);
    SPAGAIN;
    if (count != 1)
        croak ("Net::SLP: slp_reg_callback_glue callback did not return a scalar.\n");
    // The return code from the closure is important
    // Returning SLP_TRUE asks for more data. SLP_FALSE means no more data please
    result = POPi;
    PUTBACK;
    FREETMPS;
    LEAVE;

    return;
}

MODULE = Net::SLP		PACKAGE = Net::SLP		

INCLUDE: const-xs.inc
PROTOTYPES: ENABLE

SLPError SLPOpen(const char *pcLang, SLPBoolean isAsync, OUT SLPHandle phSLP);

void	 SLPClose(SLPHandle  hSLP);

SLPError SLPFindSrvs(SLPHandle  handle, const char *servicetype, const char *scopelist, const char *searchfilter, SV* callback)
 CODE:
  RETVAL = SLPFindSrvs(handle, servicetype, scopelist, searchfilter, &slp_url_callback_glue, (void*)newSVsv(callback));
 OUTPUT:
  RETVAL

SLPError SLPFindSrvTypes(SLPHandle  handle, const char *namingauthority, const char *scopelist, SV* callback)
 CODE:
  RETVAL = SLPFindSrvTypes(handle, namingauthority, scopelist, &slp_srvtype_callback_glue, (void*)newSVsv(callback));
 OUTPUT:
  RETVAL

SLPError SLPFindAttrs(SLPHandle  handle, const char *srvurl, const char *scopelist, const char* attrids, SV* callback)
 CODE:
  RETVAL = SLPFindAttrs(handle, srvurl, scopelist, attrids, &slp_attr_callback_glue, (void*)newSVsv(callback));
 OUTPUT:
  RETVAL

const char *
SLPGetProperty(const char* name) 

void
SLPSetProperty(const char* name, const char* value)

SLPError 
SLPFindScopes(SLPHandle handle, OUT char *scopelist)
 CLEANUP:
  SLPFree(scopelist);

int
SLPGetRefreshInterval()

SLPError
SLPEscape(const char* unescaped, OUT char* escaped, SLPBoolean istag) 
 CLEANUP:
  SLPFree(escaped);

SLPError
SLPUnescape(const char* escaped, OUT char* unescaped, SLPBoolean istag) 
 CLEANUP:
  SLPFree(unescaped);

SLPError
SLPReg(SLPHandle handle, const char* srvurl, unsigned short lifetime, const char* srvtype, const char* attrs, SLPBoolean fresh, SV* callback)
 CODE:
  RETVAL = SLPReg(handle, srvurl, lifetime, srvtype, attrs, fresh, &slp_reg_callback_glue, (void*)newSVsv(callback));
 OUTPUT:
  RETVAL
  
SLPError
SLPDereg(SLPHandle handle, const char* srvurl, SV* callback)
 CODE:
  RETVAL = SLPDereg(handle, srvurl, &slp_reg_callback_glue, (void*)newSVsv(callback));
 OUTPUT:
  RETVAL
  
SLPError
SLPDelAttrs(SLPHandle handle, const char* srvurl, const char* attrs, SV* callback)
 CODE:
  RETVAL = SLPDelAttrs(handle, srvurl, attrs, &slp_reg_callback_glue, (void*)newSVsv(callback));
 OUTPUT:
  RETVAL
  
