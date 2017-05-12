#ifndef __SOCKET_CLASS_H__
#define __SOCKET_CLASS_H__ 1

#include <EXTERN.h>
#include <perl.h>
#undef USE_SOCKETS_AS_HANDLES
#include <XSUB.h>

#include "mod_sc.h"

#include <fcntl.h>
#include <sys/stat.h>
#include <sys/timeb.h>
#include <math.h>

#ifdef _WIN32

#include <objbase.h>
#include <initguid.h>
#include <tchar.h>
#include <io.h>
/*
#include <af_irda.h>
*/

#else

#include <stdlib.h>
#include <unistd.h>

#endif

#ifdef SC_USE_BLUEZ
#include <bluetooth/bluetooth.h>
#include <bluetooth/rfcomm.h>
#include <bluetooth/l2cap.h>
#endif

#ifdef SC_USE_WS2BTH
#include <ws2bth.h>
#endif

#define __PACKAGE__ "Socket::Class"

#if defined _WIN32
#define INLINE __inline
#define EXTERN extern
#elif defined __GNUC__
#define INLINE inline
#define EXTERN extern inline
#else
#define INLINE
#define EXTERN
#endif

#ifdef SC_DEBUG
EXTERN int my_debug( const char *fmt, ... );
#define _debug my_debug
#endif

#undef BYTE
#define BYTE unsigned char
#undef WORD
#define WORD unsigned short
#undef DWORD
#define DWORD unsigned int

#undef XLONG
#undef UXLONG
#if defined __unix__
#	define XLONG long long
#	define UXLONG unsigned long long
#elif defined _WIN32
#	define XLONG __int64
#	define UXLONG unsigned __int64
#else
#	define XLONG long
#	define UXLONG unsigned long
#endif

#if defined _WIN32
typedef unsigned short			uint16_t;
typedef unsigned char			uint8_t;
typedef unsigned short			sa_family_t;
#endif

/* remove from perlio */
#undef accept
#undef bind
#undef connect
#undef endhostent
#undef endnetent
#undef endprotoent
#undef endservent
#undef gethostbyaddr
#undef gethostbyname
#undef gethostent
#undef gethostname
#undef getnetbyaddr
#undef getnetbyname
#undef getnetent
#undef getpeername
#undef getprotobyname
#undef getprotobynumber
#undef getprotoent
#undef getservbyname
#undef getservbyport
#undef getservent
#undef getsockname
#undef getsockopt
#undef inet_addr
#undef inet_ntoa
#undef listen
#undef recv
#undef recvfrom
#undef select
#undef send
#undef sendto
#undef sethostent
#undef setnetent
#undef setprotoent
#undef setservent
#undef setsockopt
#undef shutdown
#undef socket
#undef socketpair
#undef open
#undef close

#if SC_DEBUG > 1

/* memory debugger */

extern HV				*hv_dbg_mem;
extern perl_mutex		dbg_mem_lock;
extern int				dbg_lock;

void debug_init();
void debug_free();

#undef Newx
#undef Newxz
#undef Safefree
#undef Renew

#define Newx(v,n,t) { \
	char __v[41], __msg[128]; \
	if( dbg_lock ) MUTEX_LOCK( &dbg_mem_lock ); \
	(v) = ((t*) malloc( (size_t) (n) * sizeof(t) )); \
	sprintf( __v, "0x%lx", (size_t) (v) ); \
	sprintf( __msg, "0x%lx malloc(%lu * %lu) called at %s:%d", \
		(size_t) (v), (size_t) (n), sizeof(t), __FILE__, __LINE__ ); \
	_debug( "%s\n", __msg ); \
	(void) hv_store( hv_dbg_mem, \
		__v, (I32) strlen( __v ), newSVpvn( __msg, strlen( __msg ) ), 0 ); \
	if( dbg_lock ) MUTEX_UNLOCK( &dbg_mem_lock ); \
}

#define Newxz(v,n,t) { \
	char __v[41], __msg[128]; \
	if( dbg_lock ) MUTEX_LOCK( &dbg_mem_lock ); \
	(v) = ((t*) calloc( (size_t) (n), sizeof(t) )); \
	sprintf( __v, "0x%lx", (size_t) (v) ); \
	sprintf( __msg, "0x%lx calloc(%lu * %lu) called at %s:%d", \
		(size_t) (v), (size_t) (n), sizeof(t), __FILE__, __LINE__ ); \
	_debug( "%s\n", __msg ); \
	(void) hv_store( hv_dbg_mem, \
		__v, (I32) strlen( __v ), newSVpvn( __msg, strlen( __msg ) ), 0 ); \
	if( dbg_lock ) MUTEX_UNLOCK( &dbg_mem_lock ); \
}

#define Safefree(x) { \
	char __v[41]; \
	if( dbg_lock ) MUTEX_LOCK( &dbg_mem_lock ); \
	if( (x) != NULL ) { \
		sprintf( __v, "0x%lx", (size_t) (x) ); \
		_debug( "0x%lx free() called at %s:%d\n", \
			(size_t) (x), __FILE__, __LINE__ ); \
		(void) hv_delete( hv_dbg_mem, __v, (I32) strlen( __v ), G_DISCARD ); \
		free( (x) ); (x) = NULL; \
	} \
	if( dbg_lock ) MUTEX_UNLOCK( &dbg_mem_lock ); \
}

#define Renew(v,n,t) { \
	register void *__p = (v); \
	char __v[41], __msg[128]; \
	if( dbg_lock ) MUTEX_LOCK( &dbg_mem_lock ); \
	sprintf( __v, "0x%lx", (size_t) (v) ); \
	(void) hv_delete( hv_dbg_mem, __v, (I32) strlen( __v ), G_DISCARD ); \
	(v) = ((t*) realloc( __p, (size_t) (n) * sizeof(t) )); \
	sprintf( __v, "0x%lx", (size_t) (v) ); \
	sprintf( __msg, "0x%lx realloc(0x%lx, %lu * %lu) called at %s:%d", \
		(size_t) (v), (size_t) __p, (size_t) (n), sizeof(t), \
		__FILE__, __LINE__ ); \
	_debug( "%s\n", __msg ); \
	(void) hv_store( hv_dbg_mem, \
		__v, (I32) strlen( __v ), newSVpvn( __msg, strlen( __msg ) ), 0 ); \
	if( dbg_lock ) MUTEX_UNLOCK( &dbg_mem_lock ); \
}

#endif /* SC_DEBUG > 1 */


#ifdef USE_ITHREADS
#ifdef _WIN32
#define THREAD_ID()		(unsigned long) GetCurrentThreadId()
#else
#define THREAD_ID()		(unsigned long) pthread_self()
#endif
#endif /* USE_ITHREADS */

#ifdef _WIN32
//#include <process.h>
#define PROCESS_ID()	(unsigned int) GetCurrentProcessId()
#else
#define PROCESS_ID()	(unsigned int) getpid()
#endif

#ifdef _WIN32

#define EWOULDBLOCK				WSAEWOULDBLOCK
#define ECONNRESET				WSAECONNRESET
#define EINPROGRESS				WSAEINPROGRESS
#define ETIMEDOUT				WSAETIMEDOUT
#define EADDRNOTAVAIL			WSAEADDRNOTAVAIL

struct sockaddr_un {
	sa_family_t					sun_family;				/* AF_UNIX */
	char						sun_path[108];			/* pathname */
};

#if defined SC_OLDNET && _MSC_VER <= 1200
struct in6_addr {
	uint8_t						s6_addr[16];
};
#endif

#else /* POSIX */

#define SOCKET_ERROR			-1
#define INVALID_SOCKET			-1
#define ESOCKETBROKEN			1111

#ifndef AF_INET6
#define AF_INET6				23
#define SC_OLDNET				1
struct in6_addr {
	uint8_t						s6_addr[16];
};
struct sockaddr_in6 {
	sa_family_t					sin6_family;		/* AF_INET6 */
	in_port_t					sin6_port;		/* Port number. */
	uint32_t					sin6_flowinfo;	/* Traffic class and flow inf. */
	struct in6_addr				sin6_addr;		/* IPv6 address. */
	uint32_t					sin6_scope_id;	/* Set of interfaces for a scope. */
};
#endif /* ! AF_INET6 */

#endif /* POSIX */

#undef MAX
#define MAX(x,y) ( (x) < (y) ? (y) : (x) )
#undef MIN
#define MIN(x,y) ( (x) < (y) ? (x) : (y) )

#define ADDRUSE_CONNECT			0
#define ADDRUSE_LISTEN			1

#ifndef SC_USE_BLUEZ
typedef struct st_bdaddr {
#ifdef _WIN32
	union {
		ULONGLONG				ull;
		uint8_t					b[6];
	};
#else
	uint8_t						b[6];
#endif
} bdaddr_t;
#endif

#ifdef _WIN32

#include <pshpack1.h>
struct st_sockaddr_bt {
    sa_family_t		bt_family;
    bdaddr_t		bt_bdaddr;		/* Bluetooth device address */
    GUID			bt_classid; 	/* [OPTIONAL] system will query SDP for port */
    ULONG			bt_port;		/* RFCOMM channel or L2CAP PSM */
} sockaddr_bt_t;
#include <poppack.h>

typedef struct st_sockaddr_bt			SOCKADDR_RFCOMM;
typedef struct st_sockaddr_bt			SOCKADDR_L2CAP;

#else /* POSIX */

struct st_sockaddr_rc {
	sa_family_t			bt_family;
	bdaddr_t			bt_bdaddr;
	uint8_t				bt_port;
};
struct st_sockaddr_l2 {
	sa_family_t			bt_family;
	unsigned short		bt_port;
	bdaddr_t			bt_bdaddr;
};
typedef struct st_sockaddr_rc	SOCKADDR_RFCOMM;
typedef struct st_sockaddr_l2	SOCKADDR_L2CAP;

#endif /* POSIX */

typedef struct st_sc_sockaddr	my_sockaddr_t;

typedef struct st_socket_class {
	struct st_socket_class		*next;
	int							id;
	int							refcnt;
	SOCKET						sock;
	int							s_domain;
	int							s_type;
	int							s_proto;
	my_sockaddr_t				l_addr, r_addr;
	char						*buffer;
	size_t						buffer_len;
	int							state;
	BYTE						non_blocking;
	struct timeval				timeout;
	char						*classname;
	size_t						classname_len;
#ifdef USE_ITHREADS
	unsigned long				thread_id;
	int							do_clone;
#endif
	long						last_errno;
	char						last_error[256];
	void						*user_data;
	void						(*free_user_data) ( void *p );
} socket_class_t;

#define SC_CASCADE				31

typedef struct st_sc_global {
	socket_class_t				*socket[SC_CASCADE + 1];
	long						last_errno;
	char						last_error[256];
	int							destroyed;
	int							counter;
#ifdef USE_ITHREADS
	perl_mutex					thread_lock;
#endif
	unsigned int				process_id;
} sc_global_t;

extern sc_global_t sc_global;

#ifdef USE_ITHREADS

#define GLOBAL_LOCK()			MUTEX_LOCK( &sc_global.thread_lock )
#define GLOBAL_UNLOCK()			MUTEX_UNLOCK( &sc_global.thread_lock )

#else

#define GLOBAL_LOCK()
#define GLOBAL_UNLOCK()

#endif

#define SOCK_ERROR(sock,code,str) \
	do { \
		(sock)->last_errno = code; \
		if( str != NULL ) { \
			my_strncpy( (sock)->last_error, str, sizeof((sock)->last_error) ); \
		} \
		else { \
			(sock)->last_error[0] = '\0'; \
		} \
	} while( 0 )

#define SOCK_ERRNO(sock,code) \
	do { \
		(sock)->last_errno = code; \
		if( code > 0 ) { \
			Socket_error( \
				(sock)->last_error, sizeof( (sock)->last_error ), \
				(sock)->last_errno \
			); \
		} \
		else { \
			(sock)->last_error[0] = '\0'; \
		} \
	} while( 0 )


#define SOCK_ERRNOLAST(sock)	SOCK_ERRNO(sock, Socket_errno())

/* cpan bug #43862: don't set $! directly */

#define GLOBAL_ERROR(code,str) \
	do { \
		sc_global.last_errno = code; \
		if( str != NULL ) { \
			my_strncpy( sc_global.last_error, str, sizeof(sc_global.last_error) ); \
			sv_setpvn( ERRSV, str, strlen( str ) ); \
		} \
		else { \
			sc_global.last_error[0] = '\0'; \
			sv_setpvn( ERRSV, "", 0 ); \
		} \
	} while( 0 )

#define GLOBAL_ERRNO(code) \
	do { \
		sc_global.last_errno = code; \
		if( code > 0 ) { \
			Socket_error( \
				sc_global.last_error, sizeof( sc_global.last_error ), \
				sc_global.last_errno \
			); \
			sv_setpvn( ERRSV, sc_global.last_error, strlen( sc_global.last_error ) ); \
		} \
		else { \
			sc_global.last_error[0] = '\0'; \
			sv_setpvn( ERRSV, "", 0 ); \
		} \
	} while( 0 )

#define GLOBAL_ERRNOLAST()		GLOBAL_ERRNO(Socket_errno())

EXTERN void socket_class_add( socket_class_t *sc );
EXTERN void socket_class_rem( socket_class_t *sc );
EXTERN void socket_class_free( socket_class_t *sc );
EXTERN socket_class_t *socket_class_find( SV *sv );

EXTERN char *my_itoa( char *str, long value, int radix );
EXTERN char *my_strncpy( char *dst, const char *src, size_t len );
EXTERN char *my_strcpy( char *dst, const char *src );
EXTERN int my_stricmp( const char *cs, const char *ct );
EXTERN int my_snprintf_( char *str, size_t size, const char *format, ... );

#ifdef _WIN32

#define Socket_close(s) \
	if( (s) != INVALID_SOCKET ) { \
		closesocket( (s) ); (s) = (SOCKET) INVALID_SOCKET; \
	}

#define Socket_errno()            WSAGetLastError()

EXTERN int inet_aton( const char *cp, struct in_addr *inp );

#else /* ! _WIN32 */

#define Socket_close(s) \
	if( (s) != INVALID_SOCKET ) { \
		close( (s) ); (s) = (SOCKET) INVALID_SOCKET; \
	}

#define Socket_errno()            errno

#endif /* ! _WIN32 */

EXTERN void Socket_setaddr_UNIX( my_sockaddr_t *addr, const char *path );
EXTERN int Socket_setaddr_INET(
	socket_class_t *sc, const char *host, const char *port, int use );
EXTERN int Socket_setaddr_BTH(
	socket_class_t *sc, const char *host, const char *port, int use );
EXTERN int Socket_setblocking( SOCKET s, int value );
EXTERN int Socket_domainbyname( const char *name );
EXTERN int Socket_typebyname( const char *name );
EXTERN int Socket_protobyname( const char *name );
EXTERN int Socket_write( socket_class_t *sc, const char *buf, int len );
EXTERN void Socket_error( char *str, DWORD len, long num );

#define IPPORT4(ip,port) \
	(BYTE) ((ip) >> 24) & 0xFF, (BYTE) ((ip) >> 16) & 0xFF, \
	(BYTE) ((ip) >> 8) & 0xFF, (BYTE) ((ip) >> 0) & 0xFF, \
	ntohs( (port) )

#define IP4(ip) \
	(BYTE) ((ip) >> 24) & 0xFF, (BYTE) ((ip) >> 16) & 0xFF, \
	(BYTE) ((ip) >> 8) & 0xFF, (BYTE) ((ip) >> 0) & 0xFF

#define IPPORT6(in6,port) \
	ntohs( (in6)[0] ), ntohs( (in6)[1] ), ntohs( (in6)[2] ), \
	ntohs( (in6)[3] ), ntohs( (in6)[4] ), ntohs( (in6)[5] ), \
	ntohs( (in6)[6] ), ntohs( (in6)[7] ), ntohs( (port) )

#define IP6(in6) \
	ntohs( (in6)[0] ), ntohs( (in6)[1] ), ntohs( (in6)[2] ), \
	ntohs( (in6)[3] ), ntohs( (in6)[4] ), ntohs( (in6)[5] ), \
	ntohs( (in6)[6] ), ntohs( (in6)[7] )


EXTERN int my_ba2str( const bdaddr_t *ba, char *str );
EXTERN int my_str2ba( const char *str, bdaddr_t *ba );

#ifdef SC_HAS_BLUETOOTH
EXTERN void boot_Socket__Class__BT();
#endif

#ifdef SC_USE_BLUEZ
#include "sc_bluez.h"
#endif

#ifdef SC_USE_WS2BTH
#include "sc_ws2bth.h"
#endif

#endif
