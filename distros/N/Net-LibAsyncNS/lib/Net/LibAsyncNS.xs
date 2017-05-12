/*  You may distribute under the terms of either the GNU General Public License
 *  or the Artistic License (the same terms as Perl itself)
 *
 *  (C) Paul Evans, 2010 -- leonerd@leonerd.org.uk
 */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <asyncns.h>

typedef asyncns_t *Net__LibAsyncNS;

typedef struct Query {
  SV *sv;
  asyncns_query_t *query;
  SV *asyncns;
  SV *userdata;
} *Net__LibAsyncNS__Query;

static Net__LibAsyncNS__Query query_from_sv(SV *sv)
{
  IV tmp = SvIV((SV*)SvRV(sv));
  return INT2PTR(Net__LibAsyncNS__Query, tmp);
}

static Net__LibAsyncNS__Query query_new(SV *asyncnssv, asyncns_t *asyncns, asyncns_query_t *q)
{
  Net__LibAsyncNS__Query query;
  SV *sv;

  Newx(query, 1, struct Query);
  query->asyncns = newRV_inc(SvRV(asyncnssv));
  query->query = q;
  query->userdata = NULL;

  sv = newSV(0);
  sv_setref_pv(sv, "Net::LibAsyncNS::Query", (void*)query);
  query->sv = sv;

  asyncns_setuserdata(asyncns, q, sv);

  return query;
}

typedef int SysRet;

/* Much of this interface code stolen^Winspired by Socket::GetAddrInfo */

static SV *gai_err_to_SV(int err)
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

  stash = gv_stashpvn("Net::LibAsyncNS::Constants", 26, TRUE);
  export = get_av("Net::LibAsyncNS::Constants::EXPORT", TRUE);

#define DO_CONSTANT(c) \
  newCONSTSUB(stash, #c, newSViv(c)); \
  av_push(export, newSVpv(#c, 0));

#ifdef AI_PASSIVE
  DO_CONSTANT(AI_PASSIVE)
#endif
#ifdef AI_CANONNAME
  DO_CONSTANT(AI_CANONNAME)
#endif
#ifdef AI_NUMERICHOST
  DO_CONSTANT(AI_NUMERICHOST)
#endif
#ifdef AI_NUMERICSERV
  DO_CONSTANT(AI_NUMERICSERV)
#endif

#ifdef EAI_BADFLAGS
  DO_CONSTANT(EAI_BADFLAGS)
#endif
#ifdef EAI_NONAME
  DO_CONSTANT(EAI_NONAME)
#endif
#ifdef EAI_AGAIN
  DO_CONSTANT(EAI_AGAIN)
#endif
#ifdef EAI_FAIL
  DO_CONSTANT(EAI_FAIL)
#endif
#ifdef EAI_NODATA
  DO_CONSTANT(EAI_NODATA)
#endif
#ifdef EAI_FAMILY
  DO_CONSTANT(EAI_FAMILY)
#endif
#ifdef EAI_SOCKTYPE
  DO_CONSTANT(EAI_SOCKTYPE)
#endif
#ifdef EAI_SERVICE
  DO_CONSTANT(EAI_SERVICE)
#endif
#ifdef EAI_ADDRFAMILY
  DO_CONSTANT(EAI_ADDRFAMILY)
#endif
#ifdef EAI_MEMORY
  DO_CONSTANT(EAI_MEMORY)
#endif

#ifdef NI_NUMERICHOST
  DO_CONSTANT(NI_NUMERICHOST)
#endif
#ifdef NI_NUMERICSERV
  DO_CONSTANT(NI_NUMERICSERV)
#endif
#ifdef NI_NAMEREQD
  DO_CONSTANT(NI_NAMEREQD)
#endif
#ifdef NI_DGRAM
  DO_CONSTANT(NI_DGRAM)
#endif
}

MODULE = Net::LibAsyncNS      PACKAGE = Net::LibAsyncNS::Query

void
DESTROY(q)
  Net::LibAsyncNS::Query q

  CODE:
    SvREFCNT_dec(q->asyncns);
    SvREFCNT_dec(q->userdata);
    Safefree(q);

SV *
asyncns(q)
  Net::LibAsyncNS::Query q

  CODE:
    RETVAL = SvREFCNT_inc(q->asyncns);
  OUTPUT:
    RETVAL

MODULE = Net::LibAsyncNS      PACKAGE = Net::LibAsyncNS      PREFIX = asyncns_

BOOT:
  setup_constants();

Net::LibAsyncNS
new(package, n_proc)
  int n_proc
  CODE:
    RETVAL = asyncns_new(n_proc);
  OUTPUT:
    RETVAL

void
DESTROY(self)
  Net::LibAsyncNS self
  CODE:
    asyncns_free(self);
  OUTPUT:

int
asyncns_fd(self)
  Net::LibAsyncNS self

SysRet
asyncns_wait(self, block)
  Net::LibAsyncNS self
  int block

int
asyncns_getnqueries(self)
  Net::LibAsyncNS self

SV *
getaddrinfo(self, host=&PL_sv_undef, service=&PL_sv_undef, hints=NULL)
  Net::LibAsyncNS self
  SV *host
  SV *service
  SV *hints

  PREINIT:
    char *hostname = NULL;
    char *servicename = NULL;
    STRLEN len;
    struct addrinfo hints_s = { 0 };
    asyncns_query_t *query;

  CODE:
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

    query = asyncns_getaddrinfo(self, hostname, servicename, &hints_s);

    RETVAL = newSVsv(query_new(ST(0), self, query)->sv);

  OUTPUT:
    RETVAL

void
getaddrinfo_done(self, q)
  Net::LibAsyncNS self
  Net::LibAsyncNS::Query q

  INIT:
    int err;
    struct addrinfo *res;
    struct addrinfo *res_iter;
    int n_res;

  PPCODE:
    err = asyncns_getaddrinfo_done(self, q->query, &res);

    XPUSHs(gai_err_to_SV(err));

    if(err) {
      if(err != EAI_AGAIN)
        SvREFCNT_dec(q->sv);

      XSRETURN(1);
    }

    n_res = 0;
    for(res_iter = res; res_iter; res_iter = res_iter->ai_next) {
      HV *res_hv = newHV();

      hv_store(res_hv, "family",   6, newSViv(res_iter->ai_family),   0);
      hv_store(res_hv, "socktype", 8, newSViv(res_iter->ai_socktype), 0);
      hv_store(res_hv, "protocol", 8, newSViv(res_iter->ai_protocol), 0);

      hv_store(res_hv, "addr",     4, newSVpvn((char*)res_iter->ai_addr, res_iter->ai_addrlen), 0);

      if(res_iter->ai_canonname)
        hv_store(res_hv, "canonname", 9, newSVpv(res_iter->ai_canonname, 0), 0);
      else
        hv_store(res_hv, "canonname", 9, newSV(0), 0);

      XPUSHs(sv_2mortal(newRV_noinc((SV*)res_hv)));
      n_res++;
    }

    asyncns_freeaddrinfo(res);
    SvREFCNT_dec(q->sv);

    XSRETURN(1 + n_res);

SV *
getnameinfo(self, addr, flags, wanthost, wantserv)
  Net::LibAsyncNS self
  SV *addr
  int flags
  int wanthost
  int wantserv

  PREINIT:
    char *sa;
    STRLEN addr_len;
    asyncns_query_t *query;

  CODE:
    if(!SvPOK(addr))
      croak("addr is not a string");

    addr_len = SvCUR(addr);

    /* We need to ensure the sockaddr is aligned, because a random SvPV might
     * not be due to SvOOK */
    Newx(sa, addr_len, char);
    Copy(SvPV_nolen(addr), sa, addr_len, char);
#ifdef HAVE_SOCKADDR_SA_LEN
    ((struct sockaddr *)sa)->sa_len = addr_len;
#endif

    query = asyncns_getnameinfo(self, (struct sockaddr *)sa, addr_len, flags, wanthost, wantserv);

    RETVAL = newSVsv(query_new(ST(0), self, query)->sv);

  OUTPUT:
    RETVAL

void
getnameinfo_done(self, q)
  Net::LibAsyncNS self
  Net::LibAsyncNS::Query q

  PREINIT:
    int err;
    char host[1024];
    char serv[256];

  PPCODE:
    err = asyncns_getnameinfo_done(self, q->query, host, sizeof(host), serv, sizeof(serv));

    XPUSHs(gai_err_to_SV(err));

    if(err) {
      if(err != EAI_AGAIN)
        SvREFCNT_dec(q->sv);

      XSRETURN(1);
    }

    XPUSHs(sv_2mortal(newSVpv(host, 0)));
    XPUSHs(sv_2mortal(newSVpv(serv, 0)));

    SvREFCNT_dec(q->sv);

    XSRETURN(3);

SV *
res_query(self, dname, class, type)
  Net::LibAsyncNS self
  char *dname
  int class
  int type

  PREINIT:
    asyncns_query_t *query;

  CODE:
    query = asyncns_res_query(self, dname, class, type);

    RETVAL = newSVsv(query_new(ST(0), self, query)->sv);

  OUTPUT:
    RETVAL

SV *
res_search(self, dname, class, type)
  Net::LibAsyncNS self
  char *dname
  int class
  int type

  PREINIT:
    asyncns_query_t *query;

  CODE:
    query = asyncns_res_search(self, dname, class, type);

    RETVAL = newSVsv(query_new(ST(0), self, query)->sv);

  OUTPUT:
    RETVAL

SV *
res_done(self, q)
  Net::LibAsyncNS self
  Net::LibAsyncNS::Query q

  INIT:
    int len;
    unsigned char *answer;

  PPCODE:
    len = asyncns_res_done(self, q->query, &answer);
    if(len < 0) {
      if(-len != EAGAIN)
        SvREFCNT_dec(q->sv);

      errno = -len;
      XSRETURN_UNDEF;
    }

    mXPUSHp(answer, len);
    asyncns_freeanswer(answer);

    SvREFCNT_dec(q->sv);

    XSRETURN(1);

int
isdone(self, q)
  Net::LibAsyncNS self
  Net::LibAsyncNS::Query q

  CODE:
    RETVAL = asyncns_isdone(self, q->query);
  OUTPUT:
    RETVAL

SV *
getnext(self)
  Net::LibAsyncNS self

  PREINIT:
    asyncns_query_t *query;

  CODE:
    query = asyncns_getnext(self);

    if(!query)
      XSRETURN_UNDEF;

    RETVAL = newSVsv(asyncns_getuserdata(self, query));
  OUTPUT:
    RETVAL

void
cancel(self, q)
  Net::LibAsyncNS self
  Net::LibAsyncNS::Query q

  CODE:
    asyncns_cancel(self, q->query);
    SvREFCNT_dec(q->sv);

void
setuserdata(self, q, data)
  Net::LibAsyncNS self
  Net::LibAsyncNS::Query q
  SV *data

  CODE:
    if(q->userdata)
      SvREFCNT_dec(q->userdata);
    q->userdata = newSVsv(data);

SV *
getuserdata(self, q)
  Net::LibAsyncNS self
  Net::LibAsyncNS::Query q

  CODE:
    RETVAL = newSVsv(q->userdata);
  OUTPUT:
    RETVAL
