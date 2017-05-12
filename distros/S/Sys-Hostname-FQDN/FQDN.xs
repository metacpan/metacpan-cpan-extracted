#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

/* gethostname	*/
#if !defined(_MSC_VER) && !defined(__MINGW32_VERSION)
# include <unistd.h>
#endif

/* inet_ntoa	-- use definitions from perl Socket.xs instead */
#ifndef VMS
# ifdef I_SYS_TYPES
#  include <sys/types.h>
# endif
# if !defined(ultrix) /* Avoid double definition. */
#   include <sys/socket.h>
# endif
# if defined(USE_SOCKS) && defined(I_SOCKS)
#   include <socks.h>
# endif
# ifdef MPE
#  define PF_INET AF_INET
#  define PF_UNIX AF_UNIX
#  define SOCK_RAW 3
# endif
# ifdef I_SYS_UN
#  include <sys/un.h>
# endif
/* XXX Configure test for <netinet/in_systm.h needed XXX */
# if defined(NeXT) || defined(__NeXT__)
#  include <netinet/in_systm.h>
# endif
# if defined(__sgi) && !defined(AF_LINK) && defined(PF_LINK) && PF_LINK == AF_LNK
#  undef PF_LINK
# endif
# if defined(I_NETINET_IN) || defined(__ultrix__)
#  include <netinet/in.h>
# endif
# ifdef I_NETDB
#  if !defined(ultrix)  /* Avoid double definition. */
#   include <netdb.h>
#  endif
# endif
# ifdef I_ARPA_INET
#  include <arpa/inet.h>
# endif
# ifdef I_NETINET_TCP
#  include <netinet/tcp.h>
# endif
#else
# include "sockadapt.h"
#endif		/* definitions from perl Socket.xs 5.9.3 */

/* from /usr/include/arpa/nameser.h	*/
#define NS_MAXDNAME	1025	/* maximum domain name */

#include "c_includes/alt_inet_aton.c"

MODULE = Sys::Hostname::FQDN	PACKAGE = Sys::Hostname::FQDN

PROTOTYPES: DISABLE

void
usually_short()
    PREINIT:
	SV * out;
	char local_name[NS_MAXDNAME];
    PPCODE:
	if (gethostname(local_name,NS_MAXDNAME) != 0) {
	  ST(0) = &PL_sv_undef;
	}
	else {
	  out = sv_2mortal(newSVpv(local_name,0));
	  ST(0) = out;
	}
	XSRETURN(1);

void
inet_ntoa(netaddr)
	SV * netaddr
    PREINIT:
	STRLEN len;
	SV * out;  
	union {    
	    struct in_addr * inadr;
	    char * addr;
	} naddr;
    PPCODE:
	naddr.addr = (SvPV(netaddr, len));
	out = sv_2mortal(newSVpv(inet_ntoa(*naddr.inadr),0));
	ST(0) = out;
	XSRETURN(1);

void
inet_aton(dotquad)
	SV * dotquad
    PREINIT:
	SV * out;
	STRLEN len;
	unsigned char * dq;
	union {
	    struct in_addr * inadr;
	    char * addr;
	} naddr;
	struct in_addr myaddr;
    PPCODE:
	dq = (unsigned char *)(SvPV(dotquad, len));
	inet_aton((char *)dq,&myaddr);
	out = sv_2mortal(newSVpv((char *)&myaddr.s_addr,4));
	ST(0) = out;
	XSRETURN(1);
