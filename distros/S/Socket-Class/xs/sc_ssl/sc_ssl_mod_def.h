#ifndef _SC_SSL_MOD_DEF_H_
#define _SC_SSL_MOD_DEF_H_ 1

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <mod_sc.h>
#include "mod_sc_ssl.h"

#include <openssl/ssl.h>
#include <openssl/err.h>

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

#ifdef SC_DEBUG
int my_debug( const char *fmt, ... );
#define _debug my_debug
#endif

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
		free( (x) ); \
		(x) = NULL; \
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

#ifdef _WIN32
#define ECONNRESET				WSAECONNRESET
#define ENOTCONN				WSAENOTCONN
#endif

#ifndef AF_INET6
#define AF_INET6				23
#endif

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


enum ssl_method {
	sslv2,
	sslv23,
	sslv3,
	tlsv1
};

typedef struct st_userdata			userdata_t;
typedef struct st_sc_ssl_global		sc_ssl_global_t;

struct st_userdata {
	sc_ssl_ctx_t				*sc_ssl_ctx;
	SSL							*ssl;
	char						*rcvbuf;
	int							rcvbuf_len;
	int							rcvbuf_pos;
	char						*buffer;
	int							buffer_len;
	void						*user_data;
	void						(*free_user_data) ( void *p );
};


struct st_sc_ssl_ctx {
	sc_ssl_ctx_t				*next;
	int							id;
	int							refcnt;
	int							is_client;
	enum ssl_method				method_id;
	/*
#ifdef USE_ITHREADS
	int							dont_clone;
	unsigned long				thread_id;
#endif
	*/
	SSL_METHOD					*method;
	SSL_CTX						*ctx;
	sc_t						*socket;
	char						*private_key;
	char						*certificate;
	char						*client_ca;
	char						*ca_file;
	char						*ca_path;
	char						*cipher_list;
};

#define SC_SSL_CTX_CASCADE		31

struct st_sc_ssl_global {
	sc_ssl_ctx_t				*ctx[SC_SSL_CTX_CASCADE + 1];
	int							counter;
	int							destroyed;
#ifdef USE_ITHREADS
	perl_mutex					thread_lock;
#endif
	unsigned int				process_id;
};

extern mod_sc_t *mod_sc;
extern sc_ssl_global_t sc_ssl_global;

int mod_sc_ssl_create( char **args, int argc, sc_t **r_socket );
int mod_sc_ssl_connect(
	sc_t *socket, const char *host, const char *serv, double timeout
);
int mod_sc_ssl_listen( sc_t *socket, int queue );
int mod_sc_ssl_accept( sc_t *socket, sc_t **r_client );
int mod_sc_ssl_recv( sc_t *socket, char *buf, int len, int flags, int *p_len );
int mod_sc_ssl_send(
	sc_t *socket, const char *buf, int len, int flags, int *p_len
);
int mod_sc_ssl_recvfrom(
	sc_t *sock, char *buf, int len, int flags, int *p_len
);
int mod_sc_ssl_sendto(
	sc_t *sock, const char *buf, int len, int flags, sc_addr_t *peer,
	int *p_len
);
int mod_sc_ssl_read( sc_t *socket, char *buf, int len, int *p_len );
int mod_sc_ssl_write( sc_t *socket, const char *buf, int len, int *p_len );
int mod_sc_ssl_readline( sc_t *socket, char **p_buf, int *p_len );
int mod_sc_ssl_writeln( sc_t *socket, const char *buf, int len, int *p_len );
int mod_sc_ssl_printf( sc_t *socket, const char *fmt, ... );
int mod_sc_ssl_vprintf( sc_t *socket, const char *fmt, va_list vl );
int mod_sc_ssl_read_packet(
	sc_t *socket, char *separator, size_t max, char **p_buf, int *p_len
);
int mod_sc_ssl_available( sc_t *socket, int *p_len );
void mod_sc_ssl_set_userdata( sc_t *socket, void *p, void (*free) (void *p) );
void *mod_sc_ssl_get_userdata( sc_t *socket );

int mod_sc_ssl_set_certificate( sc_t *socket, const char *fn );
int mod_sc_ssl_set_private_key( sc_t *socket, const char *fn );
int mod_sc_ssl_set_client_ca( sc_t *socket, const char *fn );
int mod_sc_ssl_set_verify_locations(
	sc_t *socket, const char *cafile, const char *capath
);
int mod_sc_ssl_shutdown( sc_t *socket );
int mod_sc_ssl_create_server_context( sc_t *socket );
int mod_sc_ssl_create_client_context( sc_t *socket );
int mod_sc_ssl_check_private_key( sc_t *socket );
int mod_sc_ssl_enable_compatibility( sc_t *socket );
const char *mod_sc_ssl_get_cipher_name( sc_t *socket );
const char *mod_sc_ssl_get_cipher_version( sc_t *socket );
const char *mod_sc_ssl_get_version( sc_t *socket );
int mod_sc_ssl_starttls( sc_t *socket, char **args, int argc );
int mod_sc_ssl_set_ssl_method( sc_t *socket, const char *s );
int mod_sc_ssl_set_cipher_list( sc_t *socket, const char *s );

/* ssl context */

int mod_sc_ssl_ctx_create( char **args, int argc, sc_ssl_ctx_t **p_ctx );
int mod_sc_ssl_ctx_destroy( sc_ssl_ctx_t *ctx );
int mod_sc_ssl_ctx_create_class( sc_ssl_ctx_t *ctx, SV **psv );
sc_ssl_ctx_t *mod_sc_ssl_ctx_from_class( SV *sv );
int mod_sc_ssl_ctx_set_ssl_method( sc_ssl_ctx_t *ctx, const char *name );
int mod_sc_ssl_ctx_set_private_key( sc_ssl_ctx_t *ctx, const char *pk );
int mod_sc_ssl_ctx_set_certificate( sc_ssl_ctx_t *ctx, const char *crt );
int mod_sc_ssl_ctx_set_client_ca( sc_ssl_ctx_t *ctx, const char *str );
int mod_sc_ssl_ctx_set_verify_locations(
	sc_ssl_ctx_t *ctx, const char *cafile, const char *capath
);
int mod_sc_ssl_ctx_set_cipher_list( sc_ssl_ctx_t *ctx, const char *str );
int mod_sc_ssl_ctx_check_private_key( sc_ssl_ctx_t *ctx );
int mod_sc_ssl_ctx_enable_compatibility( sc_ssl_ctx_t *ctx );

int mod_sc_ssl_ctx_set_arg(
	sc_ssl_ctx_t *ctx, char **args, int argc, int is_client,
	sc_ssl_ctx_t **p_ctx
);
int mod_sc_ssl_ctx_init_client( sc_ssl_ctx_t *ctx );
int mod_sc_ssl_ctx_init_server( sc_ssl_ctx_t *ctx );

/* internal functions */

int remove_context( sc_ssl_ctx_t *ctx );
void free_context( sc_ssl_ctx_t *ctx );
void free_userdata( void *p );
const char *my_ssl_error( int code );

char *my_strcpy( char *dst, const char *src );
int my_stricmp( const char *cs, const char *ct );

#endif /* _SC_SSL_MOD_DEF_H_ */
