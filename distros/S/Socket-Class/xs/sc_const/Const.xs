#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>

#include <mod_sc.h>

enum export_item_type {
	ITEM_LONG,
	ITEM_CODE,
};

typedef struct st_export_item {
	const char						*name;
	enum export_item_type			type;
	union {
		const char					*function;
		long						value;
	} w;
} export_item_t;

const export_item_t export_items[] = {
	{ "AF_BLUETOOTH", ITEM_LONG, (const char *) AF_BLUETOOTH },
	{ "AF_INET", ITEM_LONG, (const char *) AF_INET },
	{ "AF_INET6", ITEM_LONG, (const char *) 23 },
	{ "AF_UNIX", ITEM_LONG, (const char *) AF_UNIX },
	{ "AF_UNSPEC", ITEM_LONG, (const char *) AF_UNSPEC },
	{ "AI_PASSIVE", ITEM_LONG, (const char *) 0x0001 },
	{ "AI_CANONNAME", ITEM_LONG, (const char *) 0x0002 },
	{ "AI_NUMERICHOST", ITEM_LONG, (const char *) 0x0004 },
	{ "AI_ADDRCONFIG", ITEM_LONG, (const char *) 0x0400 },
	{ "AI_NUMERICSERV", ITEM_LONG, (const char *) 0x0400 },
	{ "BTPROTO_L2CAP", ITEM_LONG, (const char *) BTPROTO_L2CAP },
	{ "BTPROTO_RFCOMM", ITEM_LONG, (const char *) BTPROTO_RFCOMM },
#if defined _WIN32
	{ "EAI_ADDRFAMILY", ITEM_LONG, (const char *) 10047 },
	{ "EAI_AGAIN", ITEM_LONG, (const char *) 11002 },
	{ "EAI_BADFLAGS", ITEM_LONG, (const char *) 10022 },
	{ "EAI_FAIL", ITEM_LONG, (const char *) 11003 },
	{ "EAI_FAMILY", ITEM_LONG, (const char *) 10047 },
	{ "EAI_MEMORY", ITEM_LONG, (const char *) WSA_NOT_ENOUGH_MEMORY },
	{ "EAI_NODATA", ITEM_LONG, (const char *) 11004 },
	{ "EAI_NONAME", ITEM_LONG, (const char *) 11001 },
	{ "EAI_SERVICE", ITEM_LONG, (const char *) 10109 },
	{ "EAI_SOCKTYPE", ITEM_LONG, (const char *) 10044 },
	{ "EAI_SYSTEM", ITEM_LONG, (const char *) 0 },
#else /* POSIX */
	{ "EAI_ADDRFAMILY", ITEM_LONG, (const char *) -9 },
	{ "EAI_AGAIN", ITEM_LONG, (const char *) -3 },
	{ "EAI_BADFLAGS", ITEM_LONG, (const char *) -1 },
	{ "EAI_FAIL", ITEM_LONG, (const char *) -4 },
	{ "EAI_FAMILY", ITEM_LONG, (const char *) -6 },
	{ "EAI_MEMORY", ITEM_LONG, (const char *) -10 },
	{ "EAI_NODATA", ITEM_LONG, (const char *) -5 },
	{ "EAI_NONAME", ITEM_LONG, (const char *) -2 },
	{ "EAI_SERVICE", ITEM_LONG, (const char *) -8 },
	{ "EAI_SOCKTYPE", ITEM_LONG, (const char *) -7 },
	{ "EAI_SYSTEM", ITEM_LONG, (const char *) -11 },
#endif /* POSIX */
#if defined _WIN32
	{ "EINTR", ITEM_LONG, (const char *) WSAEINTR },
	{ "EACCES", ITEM_LONG, (const char *) WSAEACCES },
	{ "EFAULT", ITEM_LONG, (const char *) WSAEFAULT },
	{ "EINVAL", ITEM_LONG, (const char *) WSAEINVAL },
	{ "EMFILE", ITEM_LONG, (const char *) WSAEMFILE },
	{ "EWOULDBLOCK", ITEM_LONG, (const char *) WSAEWOULDBLOCK },
	{ "EINPROGRESS", ITEM_LONG, (const char *) WSAEINPROGRESS },
	{ "EALREADY", ITEM_LONG, (const char *) WSAEALREADY },
	{ "ENOTSOCK", ITEM_LONG, (const char *) WSAENOTSOCK },
	{ "EDESTADDRREQ", ITEM_LONG, (const char *) WSAEDESTADDRREQ },
	{ "EMSGSIZE", ITEM_LONG, (const char *) WSAEMSGSIZE },
	{ "EPROTOTYPE", ITEM_LONG, (const char *) WSAEPROTOTYPE },
	{ "ENOPROTOOPT", ITEM_LONG, (const char *) WSAENOPROTOOPT },
	{ "EPROTONOSUPPORT", ITEM_LONG, (const char *) WSAEPROTONOSUPPORT },
	{ "ESOCKTNOSUPPORT", ITEM_LONG, (const char *) WSAESOCKTNOSUPPORT },
	{ "EOPNOTSUPP", ITEM_LONG, (const char *) WSAEOPNOTSUPP },
	{ "EPFNOSUPPORT", ITEM_LONG, (const char *) WSAEPFNOSUPPORT },
	{ "EAFNOSUPPORT", ITEM_LONG, (const char *) WSAEAFNOSUPPORT },
	{ "EADDRINUSE", ITEM_LONG, (const char *) WSAEADDRINUSE },
	{ "EADDRNOTAVAIL", ITEM_LONG, (const char *) WSAEADDRNOTAVAIL },
	{ "ENETDOWN", ITEM_LONG, (const char *) WSAENETDOWN },
	{ "ENETUNREACH", ITEM_LONG, (const char *) WSAENETUNREACH },
	{ "ENETRESET", ITEM_LONG, (const char *) WSAENETRESET },
	{ "ECONNABORTED", ITEM_LONG, (const char *) WSAECONNABORTED },
	{ "ECONNRESET", ITEM_LONG, (const char *) WSAECONNRESET },
	{ "ENOBUFS", ITEM_LONG, (const char *) WSAENOBUFS },
	{ "EISCONN", ITEM_LONG, (const char *) WSAEISCONN },
	{ "ENOTCONN", ITEM_LONG, (const char *) WSAENOTCONN },
	{ "ESHUTDOWN", ITEM_LONG, (const char *) WSAESHUTDOWN },
	{ "ETIMEDOUT", ITEM_LONG, (const char *) WSAETIMEDOUT },
	{ "ECONNREFUSED", ITEM_LONG, (const char *) WSAECONNREFUSED },
	{ "EHOSTDOWN", ITEM_LONG, (const char *) WSAEHOSTDOWN },
	{ "EHOSTUNREACH", ITEM_LONG, (const char *) WSAEHOSTUNREACH },
#else /* POSIX */
	{ "EINTR", ITEM_LONG, (const char *) EINTR },
	{ "EACCES", ITEM_LONG, (const char *) EACCES },
	{ "EFAULT", ITEM_LONG, (const char *) EFAULT },
	{ "EINVAL", ITEM_LONG, (const char *) EINVAL },
	{ "EMFILE", ITEM_LONG, (const char *) EMFILE },
	{ "EWOULDBLOCK", ITEM_LONG, (const char *) EWOULDBLOCK },
	{ "EINPROGRESS", ITEM_LONG, (const char *) EINPROGRESS },
	{ "EALREADY", ITEM_LONG, (const char *) EALREADY },
	{ "ENOTSOCK", ITEM_LONG, (const char *) ENOTSOCK },
	{ "EDESTADDRREQ", ITEM_LONG, (const char *) EDESTADDRREQ },
	{ "EMSGSIZE", ITEM_LONG, (const char *) EMSGSIZE },
	{ "EPROTOTYPE", ITEM_LONG, (const char *) EPROTOTYPE },
	{ "ENOPROTOOPT", ITEM_LONG, (const char *) ENOPROTOOPT },
	{ "EPROTONOSUPPORT", ITEM_LONG, (const char *) EPROTONOSUPPORT },
	{ "ESOCKTNOSUPPORT", ITEM_LONG, (const char *) ESOCKTNOSUPPORT },
	{ "EOPNOTSUPP", ITEM_LONG, (const char *) EOPNOTSUPP },
	{ "EPFNOSUPPORT", ITEM_LONG, (const char *) EPFNOSUPPORT },
	{ "EAFNOSUPPORT", ITEM_LONG, (const char *) EAFNOSUPPORT },
	{ "EADDRINUSE", ITEM_LONG, (const char *) EADDRINUSE },
	{ "EADDRNOTAVAIL", ITEM_LONG, (const char *) EADDRNOTAVAIL },
	{ "ENETDOWN", ITEM_LONG, (const char *) ENETDOWN },
	{ "ENETUNREACH", ITEM_LONG, (const char *) ENETUNREACH },
	{ "ENETRESET", ITEM_LONG, (const char *) ENETRESET },
	{ "ECONNABORTED", ITEM_LONG, (const char *) ECONNABORTED },
	{ "ECONNRESET", ITEM_LONG, (const char *) ECONNRESET },
	{ "ENOBUFS", ITEM_LONG, (const char *) ENOBUFS },
	{ "EISCONN", ITEM_LONG, (const char *) EISCONN },
	{ "ENOTCONN", ITEM_LONG, (const char *) ENOTCONN },
	{ "ESHUTDOWN", ITEM_LONG, (const char *) ESHUTDOWN },
	{ "ETIMEDOUT", ITEM_LONG, (const char *) ETIMEDOUT },
	{ "ECONNREFUSED", ITEM_LONG, (const char *) ECONNREFUSED },
	{ "EHOSTDOWN", ITEM_LONG, (const char *) EHOSTDOWN },
	{ "EHOSTUNREACH", ITEM_LONG, (const char *) EHOSTUNREACH },
#endif /* POSIX */
	{ "IP_TOS", ITEM_LONG, (const char *) IP_TOS },
	{ "IP_TTL", ITEM_LONG, (const char *) IP_TTL },
	{ "IP_HDRINCL", ITEM_LONG, (const char *) IP_HDRINCL },
	{ "IP_OPTIONS", ITEM_LONG, (const char *) IP_OPTIONS },
	{ "IPPROTO_ICMP", ITEM_LONG, (const char *) IPPROTO_ICMP },
	{ "IPPROTO_IP", ITEM_LONG, (const char *) IPPROTO_IP },
	{ "IPPROTO_TCP", ITEM_LONG, (const char *) IPPROTO_TCP },
	{ "IPPROTO_UDP", ITEM_LONG, (const char *) IPPROTO_UDP },
	{ "MSG_DONTROUTE", ITEM_LONG, (const char *) MSG_DONTROUTE },
	{ "MSG_OOB", ITEM_LONG, (const char *) MSG_OOB },
	{ "MSG_PEEK", ITEM_LONG, (const char *) MSG_PEEK },
#if defined _WIN32 || defined __CYGWIN__
	{ "MSG_CTRUNC", ITEM_LONG, (const char *) 200 },
	{ "MSG_DONTWAIT", ITEM_LONG, (const char *) 0 },
	{ "MSG_TRUNC", ITEM_LONG, (const char *) 100 },
	{ "MSG_WAITALL", ITEM_LONG, (const char *) 0x08 },
#else
	{ "MSG_CTRUNC", ITEM_LONG, (const char *) MSG_CTRUNC },
	{ "MSG_DONTWAIT", ITEM_LONG, (const char *) MSG_DONTWAIT },
	{ "MSG_TRUNC", ITEM_LONG, (const char *) MSG_TRUNC },
	{ "MSG_WAITALL", ITEM_LONG, (const char *) MSG_WAITALL },
#endif
	{ "NI_DGRAM", ITEM_LONG, (const char *) 16 },
#if defined _WIN32 || defined __CYGWIN__
	{ "NI_NAMEREQD", ITEM_LONG, (const char *) 4 },
	{ "NI_NOFQDN", ITEM_LONG, (const char *) 1 },
	{ "NI_NUMERICHOST", ITEM_LONG, (const char *) 2 },
	{ "NI_NUMERICSERV", ITEM_LONG, (const char *) 8 },
#else
	{ "NI_NAMEREQD", ITEM_LONG, (const char *) 8 },
	{ "NI_NOFQDN", ITEM_LONG, (const char *) 4 },
	{ "NI_NUMERICHOST", ITEM_LONG, (const char *) 1 },
	{ "NI_NUMERICSERV", ITEM_LONG, (const char *) 2 },
#endif
	{ "PF_BLUETOOTH", ITEM_LONG, (const char *) AF_BLUETOOTH },
	{ "PF_INET6", ITEM_LONG, (const char *) 23 },
	{ "PF_INET", ITEM_LONG, (const char *) AF_INET },
	{ "PF_UNIX", ITEM_LONG, (const char *) AF_UNIX },
	{ "PF_UNSPEC", ITEM_LONG, (const char *) AF_UNSPEC },
	{ "SC_STATE_INIT", ITEM_LONG, (const char *) SC_STATE_INIT },
	{ "SC_STATE_BOUND", ITEM_LONG, (const char *) SC_STATE_BOUND },
	{ "SC_STATE_LISTEN", ITEM_LONG, (const char *) SC_STATE_LISTEN },
	{ "SC_STATE_CONNECTED", ITEM_LONG, (const char *) SC_STATE_CONNECTED },
	{ "SC_STATE_SHUTDOWN", ITEM_LONG, (const char *) SC_STATE_SHUTDOWN },
	{ "SC_STATE_CLOSED", ITEM_LONG, (const char *) SC_STATE_CLOSED },
	{ "SC_STATE_ERROR", ITEM_LONG, (const char *) SC_STATE_ERROR },
	{ "SD_RECEIVE", ITEM_LONG, (const char *) 0 },
	{ "SD_SEND", ITEM_LONG, (const char *) 1 },
	{ "SD_BOTH", ITEM_LONG, (const char *) 2 },
	{ "SO_DEBUG", ITEM_LONG, (const char *) SO_DEBUG },
	{ "SO_REUSEADDR", ITEM_LONG, (const char *) SO_REUSEADDR },
	{ "SO_TYPE", ITEM_LONG, (const char *) SO_TYPE },
	{ "SO_ERROR", ITEM_LONG, (const char *) SO_ERROR },
	{ "SO_DONTROUTE", ITEM_LONG, (const char *) SO_DONTROUTE },
	{ "SO_SNDBUF", ITEM_LONG, (const char *) SO_SNDBUF },
	{ "SO_RCVBUF", ITEM_LONG, (const char *) SO_RCVBUF },
	{ "SO_KEEPALIVE", ITEM_LONG, (const char *) SO_KEEPALIVE },
	{ "SO_OOBINLINE", ITEM_LONG, (const char *) SO_OOBINLINE },
	{ "SO_LINGER", ITEM_LONG, (const char *) SO_LINGER },
	{ "SO_RCVLOWAT", ITEM_LONG, (const char *) SO_RCVLOWAT },
	{ "SO_SNDLOWAT", ITEM_LONG, (const char *) SO_SNDLOWAT },
	{ "SO_RCVTIMEO", ITEM_LONG, (const char *) SO_RCVTIMEO },
	{ "SO_SNDTIMEO", ITEM_LONG, (const char *) SO_SNDTIMEO },
#if defined _WIN32 || defined __CYGWIN__
	{ "SO_ACCEPTCON", ITEM_LONG, (const char *) 0x0002 },
#else
	{ "SO_ACCEPTCON", ITEM_LONG, (const char *) 80 },
#endif
	{ "SOCK_DGRAM", ITEM_LONG, (const char *) SOCK_DGRAM },
	{ "SOCK_STREAM", ITEM_LONG, (const char *) SOCK_STREAM },
	{ "SOL_SOCKET", ITEM_LONG, (const char *) SOL_SOCKET },
	{ "SOL_IP", ITEM_LONG, (const char *) 0 },
	{ "SOL_TCP", ITEM_LONG, (const char *) 6 },
	{ "SOL_UDP", ITEM_LONG, (const char *) 17 },
	{ "SOMAXCONN", ITEM_LONG, (const char *) SOMAXCONN },
	{ "TCP_NODELAY", ITEM_LONG, (const char *) TCP_NODELAY },
	{ "getaddrinfo", ITEM_CODE, "Socket::Class::getaddrinfo" },
	{ "getnameinfo", ITEM_CODE, "Socket::Class::getnameinfo" },
};

const export_item_t *export_items_end =
	export_items + (sizeof(export_items) / sizeof(export_item_t));


MODULE = Socket::Class::Const		PACKAGE = Socket::Class::Const

BOOT:
{
	sv_setpvn( get_sv( "Socket::Class::Const::VERSION", TRUE ), "bundled", 7 );
}

void
export( package, ... )
	SV *package;
PREINIT:
	int i, make_var;
	char *str, *pkg, *tmp = NULL;
	const char *s2;
	STRLEN len, pkg_len;
	HV *stash;
	SV *sv;
	const export_item_t *item;
PPCODE:
	pkg = SvPV( package, pkg_len );
	stash = gv_stashpvn( pkg, (I32) pkg_len, TRUE );
	Newx( tmp, pkg_len + 3, char );
	Copy( pkg, tmp, pkg_len, char );
	tmp[pkg_len ++] = ':';
	tmp[pkg_len ++] = ':';
	for( i = 1; i < items; i ++ ) {
		s2 = str = SvPV( ST(i), len );
		switch( *str ) {
		case ':':
			if( strcmp( str, ":all" ) == 0 ) {
				for( item = export_items; item < export_items_end; item ++ ) {
					switch( item->type ) {
					case ITEM_LONG:
						newCONSTSUB( stash,
							item->name, newSViv( (IV) item->w.value ) );
						break;
					case ITEM_CODE:
						sv = (SV *) get_cv( item->w.function, 0 );
						if( sv == NULL ) {
							s2 = item->w.function;
							goto not_found;
						}
						len = (STRLEN) strlen( item->name );
						(void) hv_store( stash, item->name, (I32) len, sv, 0 );
						break;
					}
				}
			}
			else {
				Perl_croak( aTHX_ "Invalid export tag \"%s\"", str );
			}
			continue;
		case '$':
			str ++, len --;
			make_var = 1;
			break;
		case '&':
			str ++, len --;
		default:
			make_var = 0;
			break;
		}
		for( item = export_items; item < export_items_end; item ++ ) {
			if( item->name[0] < str[0] )
				continue;
			if( item->name[0] > str[0] )
				goto not_found;
			if( strcmp( item->name, str ) != 0 )
				continue;
			switch( item->type ) {
			case ITEM_LONG:
				if( make_var ) {
					Renew( tmp, pkg_len + len + 1, char );
					Copy( str, tmp + pkg_len, len + 1, char );
					sv_setiv( get_sv( tmp, TRUE ), (IV) item->w.value );
				}
				else {
					newCONSTSUB( stash, str, newSViv( (IV) item->w.value ) );
				}
				break;
			case ITEM_CODE:
				if( make_var )
					goto not_found;
				sv = (SV *) get_cv( item->w.function, 0 );
				if( sv == NULL ) {
					s2 = item->w.function;
					goto not_found;
				}
				(void) hv_store( stash, str, (I32) len, sv, 0 );
				break;
			}
			break;
		}
	}
	if( FALSE ) {
not_found:
		Safefree( tmp );
		Perl_croak( aTHX_ "\"%s\" does not exist", s2, pkg );
	}
	Safefree( tmp );
	XSRETURN_EMPTY;
