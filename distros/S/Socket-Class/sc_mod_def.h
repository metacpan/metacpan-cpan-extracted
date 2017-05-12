#include "mod_sc.h"

int mod_sc_create_class( sc_t *socket, const char *pkg, SV **psv );
int mod_sc_create( char **args, int argc, sc_t **p_sc );
void mod_sc_destroy( sc_t *socket );
sc_t *mod_sc_get_socket( SV *sv );
int mod_sc_connect(
	sc_t *sock, const char *host, const char *serv, double timeout
);
int mod_sc_close( sc_t *sock );
int mod_sc_shutdown( sc_t *sock, int how );
int mod_sc_bind( sc_t *sock, const char *host, const char *serv );
int mod_sc_listen( sc_t *sock, int queue );
int mod_sc_accept( sc_t *sock, sc_t **client );
int mod_sc_recv( sc_t *sock, char *buf, int len, int flags, int *p_len );
int mod_sc_send( sc_t *sock, const char *buf, int len, int flags, int *p_len );
int mod_sc_recvfrom( sc_t *sock, char *buf, int len, int flags, int *p_len );
int mod_sc_sendto(
	sc_t *sock, const char *buf, int len, int flags, sc_addr_t *peer,
	int *p_len
);
int mod_sc_read( sc_t *sock, char *buf, int len, int *p_len );
int mod_sc_write( sc_t *sock, const char *buf, int len, int *p_len );
int mod_sc_writeln( sc_t *sock, const char *buf, int len, int *p_len );
int mod_sc_printf( sc_t *sock, const char *fmt, ... );
int mod_sc_vprintf( sc_t *sock, const char *fmt, va_list vl );
int mod_sc_readline( sc_t *sock, char **p_buf, int *p_len );
int mod_sc_read_packet(
	sc_t *sock, char *separator, size_t max, char **p_buf, int *p_len
);
int mod_sc_available( sc_t *sock, int *p_len );
int mod_sc_pack_addr(
	sc_t *sock, const char *host, const char *serv, sc_addr_t *addr );
int mod_sc_unpack_addr(
	sc_t *sock, sc_addr_t *addr, char *host, int *host_len,
	char *serv, int *serv_len
);
int mod_sc_gethostbyaddr(
	sc_t *sock, sc_addr_t *addr, char *host, int *host_len
);
int mod_sc_gethostbyname(
	sc_t *sock, const char *name, char *addr, int *addr_len
);
#ifndef SC_OLDNET
void my_addrinfo_set( const sc_addrinfo_t *src, struct addrinfo **res );
void my_addrinfo_get( const struct addrinfo *src, sc_addrinfo_t **res );
void my_addrinfo_free( struct addrinfo *res );
#endif
int mod_sc_getaddrinfo(
	sc_t *sock, const char *node, const char *service,
	const sc_addrinfo_t *hints, sc_addrinfo_t **res
);
void mod_sc_freeaddrinfo( sc_addrinfo_t *res );
int mod_sc_getnameinfo(
	sc_t *sock, sc_addr_t *addr, char *host, int host_len,
	char *serv, int serv_len, int flags
);
int mod_sc_getnameinfo(
	sc_t *sock, sc_addr_t *addr, char *host, int host_len,
	char *serv, int serv_len, int flags
);
int mod_sc_set_blocking( sc_t *sock, int mode );
int mod_sc_get_blocking( sc_t *sock, int *mode );
int mod_sc_set_reuseaddr( sc_t *sock, int mode );
int mod_sc_get_reuseaddr( sc_t *sock, int *mode );
int mod_sc_set_broadcast( sc_t *sock, int mode );
int mod_sc_get_broadcast( sc_t *sock, int *mode );
int mod_sc_set_rcvbuf_size( sc_t *sock, int size );
int mod_sc_get_rcvbuf_size( sc_t *sock, int *size );
int mod_sc_set_sndbuf_size( sc_t *sock, int size );
int mod_sc_get_sndbuf_size( sc_t *sock, int *size );
int mod_sc_set_tcp_nodelay( sc_t *sock, int mode );
int mod_sc_get_tcp_nodelay( sc_t *sock, int *mode );
int mod_sc_setsockopt(
	sc_t *sock, int level, int optname, const void *optval, socklen_t optlen
);
int mod_sc_getsockopt(
	sc_t *sock, int level, int optname, void *optval, socklen_t *optlen
);
int mod_sc_is_readable( sc_t *sock, double timeout, int *readable );
int mod_sc_is_writable( sc_t *sock, double timeout, int *writable );
int mod_sc_select(
	sc_t *sock, int *read, int *write, int *except, double timeout
);
void mod_sc_sleep( double ms );
SOCKET mod_sc_get_handle( sc_t *sock );
int mod_sc_get_state( sc_t *sock );
int mod_sc_local_addr( sc_t *sock, sc_addr_t *addr );
int mod_sc_remote_addr( sc_t *sock, sc_addr_t *addr );
int mod_sc_get_family( sc_t *sock );
int mod_sc_get_proto( sc_t *sock );
int mod_sc_get_type( sc_t *sock );
int mod_sc_to_string( sc_t *sock, char *str, size_t *size );
int mod_sc_get_errno( sc_t *socket );
const char *mod_sc_get_error( sc_t *socket );
void mod_sc_set_errno( sc_t *sock, int code );
void mod_sc_set_error( sc_t *sock, int code, const char *fmt, ... );
int mod_sc_refcnt_inc( sc_t *socket );
int mod_sc_refcnt_dec( sc_t *socket );

extern const mod_sc_t mod_sc;
