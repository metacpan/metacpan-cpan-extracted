#ifndef _MOD_SC_H_
#define _MOD_SC_H_ 1

/* don't use perl memory functions
 * to avoid false alerts like "free to wrong pool..."
 * when using threads
 */

#undef free
#undef malloc
#undef realloc
#undef calloc
#undef memcpy
#undef memmove

#undef Newx
#undef Newxz
#undef Safefree
#undef Renew
#undef Copy
#undef Move

#define Newx(v,c,t) \
	( (v) = ( (t*) malloc( (c) * sizeof(t) ) ) )

#define Newxz(v,c,t) \
	( (v) = ( (t*) calloc( (c), sizeof(t) ) ) )

#define Safefree(x) \
	if( (x) != NULL ) { free( (x) ); (x) = NULL; }

#define Renew(v,n,t) \
	( (v) = ( (t*) realloc( (void *) (v), (n) * sizeof(t) ) ) )

#define Copy(s,d,n,t) \
	( memcpy( (char *) (d), (const char *) (s), (n) * sizeof(t) ) )

#define Move(s,d,n,t) \
	( memmove( (char *) (d), (const char *) (s), (n) * sizeof(t) ) )

/* end of memory definition */

#ifdef _WIN32

#include <winsock2.h>
#include <ws2tcpip.h>

#ifndef AF_BLUETOOTH
#define AF_BLUETOOTH			32
#endif
#define BTPROTO_RFCOMM			0x0003
#define BTPROTO_L2CAP			0x0100

#define socklen_t				int

#else /* POSIX */

#include <sys/types.h>
#include <sys/socket.h>
#include <sys/un.h>
#include <netinet/in.h>
#include <netinet/tcp.h>
#include <arpa/inet.h>
#include <netdb.h>

#define SOCKET					int

#ifndef AF_BLUETOOTH
#define AF_BLUETOOTH			31
#endif
#define BTPROTO_RFCOMM			3
#define BTPROTO_L2CAP			0

#endif /* POSIX */

#ifndef SOCK_RDM
#define SOCK_RDM				4
#endif
#ifndef SOCK_SEQPACKET
#define SOCK_SEQPACKET			5
#endif
#ifndef AF_IRDA
#define AF_IRDA					26
#endif

#ifndef NI_MAXHOST
#define NI_MAXHOST				1025
#endif
#ifndef NI_MAXSERV
#define NI_MAXSERV				32
#endif

/* Socket::Class states */
#define SC_STATE_INIT			0
#define SC_STATE_BOUND			1
#define SC_STATE_LISTEN			2
#define SC_STATE_CONNECTED		3
#define SC_STATE_SHUTDOWN		4
#define SC_STATE_CLOSED			5
#define SC_STATE_ERROR			99

/* mod_sc return codes */
#define SC_OK					0
#define SC_ERROR				1

#define SOCKADDR_SIZE_MAX		128

struct st_sc_sockaddr {
	socklen_t					l;
	char						a[SOCKADDR_SIZE_MAX];
};

#define SC_ADDR_SIZE(sa)		((sa).l + sizeof(socklen_t))

struct st_sc_addrinfo {
	int							ai_flags;
	int							ai_family;
	int							ai_socktype;
	int							ai_protocol;
	size_t						ai_addrlen;
	struct sockaddr				*ai_addr;
	char						*ai_canonname;
	size_t						ai_cnamelen;
	struct st_sc_addrinfo		*ai_next;
};

typedef struct st_socket_class		sc_t;
typedef struct st_sc_sockaddr		sc_addr_t;
typedef struct st_sc_addrinfo		sc_addrinfo_t;
typedef struct st_mod_sc			mod_sc_t;

struct st_mod_sc {
	const char *sc_version; /* XS_VERSION */
	int (*sc_create) ( char **args, int argc, sc_t **socket );
	int (*sc_create_class) ( sc_t *sock, const char *pkg, SV **psv );
	void (*sc_destroy) ( sc_t *sock );
	sc_t *(*sc_get_socket) ( SV *object );
	int (*sc_connect)
		( sc_t *sock, const char *host, const char *serv, double timeout );
	int (*sc_bind) ( sc_t *sock, const char *host, const char *serv );
	int (*sc_listen) ( sc_t *sock, int queue );
	int (*sc_accept) ( sc_t *sock, sc_t **client );
	int (*sc_shutdown) ( sc_t *sock, int how );
	int (*sc_close) ( sc_t *sock );
	int (*sc_recv) ( sc_t *sock, char *buf, int len, int flags, int *p_len );
	int (*sc_send) ( sc_t *sock, const char *buf, int len, int flags, int *p_len );
	int (*sc_recvfrom) ( sc_t *sock, char *buf, int len, int flags, int *p_len );
	int (*sc_sendto) (
		sc_t *sock, const char *buf, int len, int flags, sc_addr_t *peer,
		int *p_len
	);
	int (*sc_read) ( sc_t *sock, char *buf, int len, int *p_len );
	int (*sc_write) ( sc_t *sock, const char *buf, int len, int *p_len );
	int (*sc_writeln) ( sc_t *sock, const char *buf, int len, int *p_len );
	int (*sc_printf) ( sc_t *sock, const char *fmt, ... );
	int (*sc_vprintf) ( sc_t *sock, const char *fmt, va_list vl );
	int (*sc_readline) ( sc_t *sock, char **p_buf, int *p_len );
	int (*sc_available) ( sc_t *sock, int *p_len );
	int (*sc_pack_addr) (
		sc_t *sock, const char *host, const char *serv, sc_addr_t *addr );
	int (*sc_unpack_addr) (
		sc_t *sock, sc_addr_t *addr, char *host, int *host_len,
		char *serv, int *serv_len
	);
	int (*sc_gethostbyaddr) (
		sc_t *sock, sc_addr_t *addr, char *host, int *host_len
	);
	int (*sc_gethostbyname) (
		sc_t *sock, const char *name, char *addr, int *addr_len
	);
	int (*sc_getaddrinfo) (
		sc_t *sock, const char *node, const char *service,
		const sc_addrinfo_t *hints, sc_addrinfo_t **res
	);
	void (*sc_freeaddrinfo) ( sc_addrinfo_t *res );
	int (*sc_getnameinfo) (
		sc_t *sock, sc_addr_t *addr, char *host, int host_len,
		char *serv, int serv_len, int flags
	);
	int (*sc_set_blocking) ( sc_t *sock, int mode );
	int (*sc_get_blocking) ( sc_t *sock, int *mode );
	int (*sc_set_reuseaddr) ( sc_t *sock, int mode );
	int (*sc_get_reuseaddr) ( sc_t *sock, int *mode );
	int (*sc_set_broadcast) ( sc_t *sock, int mode );
	int (*sc_get_broadcast) ( sc_t *sock, int *mode );
	int (*sc_set_rcvbuf_size) ( sc_t *sock, int size );
	int (*sc_get_rcvbuf_size) ( sc_t *sock, int *size );
	int (*sc_set_sndbuf_size) ( sc_t *sock, int size );
	int (*sc_get_sndbuf_size) ( sc_t *sock, int *size );
	int (*sc_set_tcp_nodelay) ( sc_t *sock, int mode );
	int (*sc_get_tcp_nodelay) ( sc_t *sock, int *mode );
	int (*sc_setsockopt) (
		sc_t *sock, int level, int optname, const void *optval,
		socklen_t optlen
	);
	int (*sc_getsockopt) (
		sc_t *sock, int level, int optname, void *optval, socklen_t *optlen
	);
	int (*sc_is_readable) ( sc_t *sock, double timeout, int *readable );
	int (*sc_is_writable) ( sc_t *sock, double timeout, int *writable );
	int (*sc_select) (
		sc_t *sock, int *read, int *write, int *except, double timeout
	);
	void (*sc_sleep) ( double ms );
	SOCKET (*sc_get_handle) ( sc_t *sock );
	int (*sc_get_state) ( sc_t *sock );
	void (*sc_set_state) ( sc_t *sock, int state );
	int (*sc_local_addr) ( sc_t *sock, sc_addr_t *addr );
	int (*sc_remote_addr) ( sc_t *sock, sc_addr_t *addr );
	int (*sc_get_family) ( sc_t *sock );
	int (*sc_get_proto) ( sc_t *sock );
	int (*sc_get_type) ( sc_t *sock );
	int (*sc_to_string) ( sc_t *sock, char *str, size_t *size );
	int (*sc_get_errno) ( sc_t *sock );
	const char *(*sc_get_error) ( sc_t *sock );
	void (*sc_set_errno) ( sc_t *sock, int code );
	void (*sc_set_error) ( sc_t *sock, int code, const char *fmt, ... );
	void (*sc_set_userdata) ( sc_t *sock, void *p, void (*free) (void *p) );
	void * (*sc_get_userdata) ( sc_t *sock );
	int (*sc_refcnt_dec) ( sc_t *socket );
	int (*sc_refcnt_inc) ( sc_t *socket );
	/* since version 2.3 */
	int (*sc_read_packet) (
		sc_t *socket, char *separator, size_t max, char **p_buf, int *p_len
	);
};

#endif /* _MOD_SC_H_ */
