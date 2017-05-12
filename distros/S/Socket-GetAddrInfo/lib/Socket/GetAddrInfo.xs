/*  You may distribute under the terms of either the GNU General Public License
 *  or the Artistic License (the same terms as Perl itself)
 *
 *  (C) Paul Evans, 2008-2011 -- leonerd@leonerd.org.uk
 */

#include "../../socket-gai-config.h"

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#define NEED_newCONSTSUB
#define NEED_newRV_noinc
#define NEED_sv_2pv_flags
#include "../../ppport.h"

#ifdef HAS_GETADDRINFO

#include <stdlib.h>
#include <stdio.h>

#ifdef WIN32
# undef WINVER
# define WINVER          0x0501
# ifdef __GNUC__
#  define USE_W32_SOCKETS
# endif
# include <winsock2.h>
/* We need to include ws2tcpip.h to get the IPv6 definitions.
 * It will in turn include wspiapi.h.  Later versions of that
 * header in the Windows SDK generate C++ template code that
 * can't be compiled with VC6 anymore.  The _WSPIAPI_COUNTOF
 * definition below prevents wspiapi.h from generating this
 * incompatible code.
 */
# define _WSPIAPI_COUNTOF(_Array) (sizeof(_Array) / sizeof(_Array[0]))
# undef UNICODE
# include <ws2tcpip.h>
# ifndef NI_NUMERICSERV
#  error Microsoft Platform SDK (Aug. 2001) or later required.
# endif
# ifdef _MSC_VER
#  pragma comment(lib, "Ws2_32.lib")
# endif
#else
# include <sys/types.h>
# include <sys/socket.h>
# include <netdb.h>
#endif

/* These are not gni() constants; they're extensions for the perl API */
#define NIx_NOHOST   (1 << 0)
#define NIx_NOSERV   (1 << 1)

static SV *err_to_SV(pTHX_ int err)
{
  SV *ret = sv_newmortal();
  SvUPGRADE(ret, SVt_PVNV);

  if(err) {
    const char *error = gai_strerror(err);
    sv_setpv(ret, error);
  }
  else {
    sv_setpv(ret, "");
  }

  SvIV_set(ret, err); SvIOK_on(ret);

  return ret;
}

static void setup_constants(void)
{
  HV *stash;
  AV *export;

  stash = gv_stashpvn("Socket::GetAddrInfo", 19, TRUE);
  export = get_av("Socket::GetAddrInfo::EXPORT_OK", TRUE);

#define DO_CONSTANT(c) \
  newCONSTSUB(stash, #c, newSViv(c)); \
  av_push(export, newSVpv(#c, 0));

  DO_CONSTANT(AI_PASSIVE)
  DO_CONSTANT(AI_CANONNAME)
  DO_CONSTANT(AI_NUMERICHOST)

#ifdef AI_V4MAPPED
  DO_CONSTANT(AI_V4MAPPED)
#endif
#ifdef AI_ALL
  DO_CONSTANT(AI_ALL)
#endif
#ifdef AI_ADDRCONFIG
  DO_CONSTANT(AI_ADDRCONFIG)
#endif

#ifdef AI_NUMERICSERV
  DO_CONSTANT(AI_NUMERICSERV)
#endif

#ifdef AI_IDN
  DO_CONSTANT(AI_IDN)
#endif
#ifdef AI_CANONIDN
  DO_CONSTANT(AI_CANONIDN)
#endif
#ifdef AI_IDN_ALLOW_UNASSIGNED
  DO_CONSTANT(AI_IDN_ALLOW_UNASSIGNED)
#endif
#ifdef AI_IDN_USE_STD3_ASCII_RULES
  DO_CONSTANT(AI_IDN_USE_STD3_ASCII_RULES)
#endif

  DO_CONSTANT(EAI_BADFLAGS)
  DO_CONSTANT(EAI_NONAME)
  DO_CONSTANT(EAI_AGAIN)
  DO_CONSTANT(EAI_FAIL)
#ifdef EAI_NODATA
  DO_CONSTANT(EAI_NODATA)
#endif
  DO_CONSTANT(EAI_FAMILY)
  DO_CONSTANT(EAI_SOCKTYPE)
  DO_CONSTANT(EAI_SERVICE)
#ifdef EAI_ADDRFAMILY
  DO_CONSTANT(EAI_ADDRFAMILY)
#endif
  DO_CONSTANT(EAI_MEMORY)

#ifdef EAI_SYSTEM
  DO_CONSTANT(EAI_SYSTEM)
#endif
#ifdef EAI_BADHINTS
  DO_CONSTANT(EAI_BADHINTS)
#endif
#ifdef EAI_PROTOCOL
  DO_CONSTANT(EAI_PROTOCOL)
#endif

  DO_CONSTANT(NI_NUMERICHOST)
  DO_CONSTANT(NI_NUMERICSERV)
  DO_CONSTANT(NI_NAMEREQD)
  DO_CONSTANT(NI_DGRAM)

#ifdef NI_NOFQDN
  DO_CONSTANT(NI_NOFQDN)
#endif

#ifdef NI_IDN
  DO_CONSTANT(NI_IDN)
#endif
#ifdef NI_IDN_ALLOW_UNASSIGNED
  DO_CONSTANT(NI_IDN_ALLOW_UNASSIGNED)
#endif
#ifdef NI_IDN_USE_STD3_ASCII_RULES
  DO_CONSTANT(NI_IDN_USE_STD3_ASCII_RULES)
#endif

  DO_CONSTANT(NIx_NOHOST)
  DO_CONSTANT(NIx_NOSERV)
}

static void xs_getaddrinfo(pTHX_ CV *cv)
{
    dVAR;
    dXSARGS;

    SV   *host;
    SV   *service;
    SV   *hints;

    char *hostname = NULL;
    char *servicename = NULL;
    STRLEN len;
    struct addrinfo hints_s;
    struct addrinfo *res;
    struct addrinfo *res_iter;
    int err;
    int n_res;

    if(items > 3)
      croak("Usage: Socket::GetAddrInfo(host, service, hints)");

    SP -= items;

    if(items < 1)
      host = &PL_sv_undef;
    else
      host = ST(0);

    if(items < 2)
      service = &PL_sv_undef;
    else
      service = ST(1);

    if(items < 3)
      hints = NULL;
    else
      hints = ST(2);

    SvGETMAGIC(host);
    if(SvOK(host)) {
      hostname = SvPV_nomg(host, len);
      if (!len)
        hostname = NULL;
    }

    SvGETMAGIC(service);
    if(SvOK(service)) {
      servicename = SvPV_nomg(service, len);
      if (!len)
        servicename = NULL;
    }

    Zero(&hints_s, sizeof hints_s, char);
    hints_s.ai_family = PF_UNSPEC;

    if(hints && SvOK(hints)) {
      HV *hintshash;
      SV **valp;

      if(!SvROK(hints) || SvTYPE(SvRV(hints)) != SVt_PVHV)
        croak("hints is not a HASH reference");

      hintshash = (HV*)SvRV(hints);

      if((valp = hv_fetch(hintshash, "flags", 5, 0)) != NULL)
        hints_s.ai_flags = SvIV(*valp);
      if((valp = hv_fetch(hintshash, "family", 6, 0)) != NULL)
        hints_s.ai_family = SvIV(*valp);
      if((valp = hv_fetch(hintshash, "socktype", 8, 0)) != NULL)
        hints_s.ai_socktype = SvIV(*valp);
      if((valp = hv_fetch(hintshash, "protocol", 8, 0)) != NULL)
        hints_s.ai_protocol = SvIV(*valp);
    }

    err = getaddrinfo(hostname, servicename, &hints_s, &res);

    XPUSHs(err_to_SV(aTHX_ err));

    if(err)
      XSRETURN(1);

    n_res = 0;
    for(res_iter = res; res_iter; res_iter = res_iter->ai_next) {
      HV *res_hv = newHV();

      (void)hv_stores(res_hv, "family",   newSViv(res_iter->ai_family));
      (void)hv_stores(res_hv, "socktype", newSViv(res_iter->ai_socktype));
      (void)hv_stores(res_hv, "protocol", newSViv(res_iter->ai_protocol));

      (void)hv_stores(res_hv, "addr",     newSVpvn((char*)res_iter->ai_addr, res_iter->ai_addrlen));

      if(res_iter->ai_canonname)
        (void)hv_stores(res_hv, "canonname", newSVpv(res_iter->ai_canonname, 0));
      else
        (void)hv_stores(res_hv, "canonname", newSV(0));

      XPUSHs(sv_2mortal(newRV_noinc((SV*)res_hv)));
      n_res++;
    }

    freeaddrinfo(res);

    XSRETURN(1 + n_res);
}

static void xs_getnameinfo(pTHX_ CV *cv)
{
    dVAR;
    dXSARGS;

    SV  *addr;
    int  flags;
    int  xflags;

    char host[1024];
    char serv[256];
    char *sa; /* we'll cast to struct sockaddr * when necessary */
    STRLEN addr_len;
    int err;

    int want_host, want_serv;

    if(items < 1 || items > 3)
      croak("Usage: Socket::GetAddrInfo(addr, flags=0, xflags=0)");

    SP -= items;

    addr = ST(0);

    if(items < 2)
      flags = 0;
    else
      flags = SvIV(ST(1));

    if(items < 3)
      xflags = 0;
    else
      xflags = SvIV(ST(2));

    want_host = !(xflags & NIx_NOHOST);
    want_serv = !(xflags & NIx_NOSERV);

    if(!SvPOK(addr))
      croak("addr is not a string");

    addr_len = SvCUR(addr);

    /* We need to ensure the sockaddr is aligned, because a random SvPV might
     * not be due to SvOOK */
    Newx(sa, addr_len, char);
    Copy(SvPV_nolen(addr), sa, addr_len, char);
#ifdef HAS_SOCKADDR_SA_LEN
    ((struct sockaddr *)sa)->sa_len = addr_len;
#endif

    err = getnameinfo((struct sockaddr *)sa, addr_len,
      want_host ? host : NULL, want_host ? sizeof(host) : 0,
      want_serv ? serv : NULL, want_serv ? sizeof(serv) : 0,
      flags);

    Safefree(sa);

    XPUSHs(err_to_SV(aTHX_ err));

    if(err)
      XSRETURN(1);

    XPUSHs(want_host ? sv_2mortal(newSVpv(host, 0)) : &PL_sv_undef);
    XPUSHs(want_serv ? sv_2mortal(newSVpv(serv, 0)) : &PL_sv_undef);

    XSRETURN(3);
}

#endif

MODULE = Socket::GetAddrInfo  PACKAGE = Socket::GetAddrInfo

BOOT:
#ifdef HAS_GETADDRINFO
  setup_constants();
  newXS("Socket::GetAddrInfo::getaddrinfo", xs_getaddrinfo, __FILE__);
  newXS("Socket::GetAddrInfo::getnameinfo", xs_getnameinfo, __FILE__);
#endif
