#include "sc_ssl_mod_def.h"

mod_sc_t *mod_sc;
mod_sc_ssl_t mod_sc_ssl;

MODULE = Socket::Class::SSL	PACKAGE = Socket::Class::SSL	PREFIX = SSL_

BOOT:
{
	SV **psv;
#ifdef SC_DEBUG
	_debug( "INIT called\n" );
#endif
#if SC_DEBUG > 1
	debug_init();
#endif
	psv = hv_fetch( PL_modglobal, "Socket::Class", 13, 0 );
	if( psv == NULL )
		Perl_croak(aTHX_ "Socket::Class 2.0 or higher is required");
	mod_sc = INT2PTR( mod_sc_t *, SvIV( *psv ) );
	/*
	if( strcmp( mod_sc->sc_version, SC_VERSION ) != 0 )
		Perl_croak(aTHX_ "Socket::Class has been changed, "
			"please recompile Socket::Class::SSL");
	*/
	Copy( mod_sc, &mod_sc_ssl, 1, mod_sc_t );
	/* replace existing functions */
	mod_sc_ssl.sc_create = mod_sc_ssl_create;
	mod_sc_ssl.sc_connect = mod_sc_ssl_connect;
	mod_sc_ssl.sc_listen = mod_sc_ssl_listen;
	mod_sc_ssl.sc_accept = mod_sc_ssl_accept;
	mod_sc_ssl.sc_recv = mod_sc_ssl_recv;
	mod_sc_ssl.sc_send = mod_sc_ssl_send;
	mod_sc_ssl.sc_recvfrom = mod_sc_ssl_recvfrom;
	mod_sc_ssl.sc_sendto = mod_sc_ssl_sendto;
	mod_sc_ssl.sc_read = mod_sc_ssl_read;
	mod_sc_ssl.sc_write = mod_sc_ssl_write;
	mod_sc_ssl.sc_readline = mod_sc_ssl_readline;
	mod_sc_ssl.sc_writeln = mod_sc_ssl_writeln;
	mod_sc_ssl.sc_printf = mod_sc_ssl_printf;
	mod_sc_ssl.sc_vprintf = mod_sc_ssl_vprintf;
	mod_sc_ssl.sc_available = mod_sc_ssl_available;
	mod_sc_ssl.sc_set_userdata = mod_sc_ssl_set_userdata;
	mod_sc_ssl.sc_get_userdata = mod_sc_ssl_get_userdata;
	/* set additional functions */
	mod_sc_ssl.sc_ssl_version = XS_VERSION;
	mod_sc_ssl.sc_ssl_create_server_context = mod_sc_ssl_create_server_context;
	mod_sc_ssl.sc_ssl_create_client_context = mod_sc_ssl_create_client_context;
	mod_sc_ssl.sc_ssl_set_certificate = mod_sc_ssl_set_certificate;
	mod_sc_ssl.sc_ssl_set_private_key = mod_sc_ssl_set_private_key;
	mod_sc_ssl.sc_ssl_set_client_ca = mod_sc_ssl_set_client_ca;
	mod_sc_ssl.sc_ssl_set_verify_locations = mod_sc_ssl_set_verify_locations;
	mod_sc_ssl.sc_ssl_check_private_key = mod_sc_ssl_check_private_key;
	mod_sc_ssl.sc_ssl_enable_compatibility = mod_sc_ssl_enable_compatibility;
	mod_sc_ssl.sc_ssl_get_cipher_name = mod_sc_ssl_get_cipher_name;
	mod_sc_ssl.sc_ssl_get_cipher_version = mod_sc_ssl_get_cipher_version;
	mod_sc_ssl.sc_ssl_get_version = mod_sc_ssl_get_version;
	mod_sc_ssl.sc_ssl_starttls = mod_sc_ssl_starttls;
	mod_sc_ssl.sc_ssl_set_ssl_method = mod_sc_ssl_set_ssl_method;
	mod_sc_ssl.sc_ssl_set_cipher_list = mod_sc_ssl_set_cipher_list;
	mod_sc_ssl.sc_ssl_read_packet = mod_sc_ssl_read_packet;
	mod_sc_ssl.sc_ssl_ctx_create = mod_sc_ssl_ctx_create;
	mod_sc_ssl.sc_ssl_ctx_destroy = mod_sc_ssl_ctx_destroy;
	mod_sc_ssl.sc_ssl_ctx_create_class = mod_sc_ssl_ctx_create_class;
	mod_sc_ssl.sc_ssl_ctx_from_class = mod_sc_ssl_ctx_from_class;
	mod_sc_ssl.sc_ssl_ctx_set_ssl_method = mod_sc_ssl_ctx_set_ssl_method;
	mod_sc_ssl.sc_ssl_ctx_set_private_key = mod_sc_ssl_ctx_set_private_key;
	mod_sc_ssl.sc_ssl_ctx_set_certificate = mod_sc_ssl_ctx_set_certificate;
	mod_sc_ssl.sc_ssl_ctx_set_client_ca = mod_sc_ssl_ctx_set_client_ca;
	mod_sc_ssl.sc_ssl_ctx_set_verify_locations = mod_sc_ssl_ctx_set_verify_locations;
	mod_sc_ssl.sc_ssl_ctx_set_cipher_list = mod_sc_ssl_ctx_set_cipher_list;
	mod_sc_ssl.sc_ssl_ctx_check_private_key = mod_sc_ssl_ctx_check_private_key;
	mod_sc_ssl.sc_ssl_ctx_enable_compatibility = mod_sc_ssl_ctx_enable_compatibility;
	/* store the c module interface in the modglobal hash */
	(void) hv_store( PL_modglobal,
		"Socket::Class::SSL", 18, newSViv( PTR2IV( &mod_sc_ssl ) ), 0 );
	/* openssl initialization */
	SSL_library_init();
	SSL_load_error_strings();
	OpenSSL_add_all_algorithms();
	Zero( &sc_ssl_global, 1, sc_ssl_global_t );
	sc_ssl_global.process_id = PROCESS_ID();
#ifdef USE_ITHREADS
	MUTEX_INIT( &sc_ssl_global.thread_lock );
#endif
}

#/*****************************************************************************
# * SSL_c_module()
# *****************************************************************************/
void
SSL_c_module( ... )
PPCODE:
	/* returns the c module interface */
	XSRETURN_IV( PTR2IV( &mod_sc_ssl ) );


#/*****************************************************************************
# * SSL_END()
# *****************************************************************************/

void
SSL_END( ... )
PREINIT:
	/*
	sc_ssl_ctx_t *ctx1, *ctx2;
	int i;
	*/
CODE:
	(void) items; /* avoid compiler warning */
	if( sc_ssl_global.destroyed || sc_ssl_global.process_id != PROCESS_ID() )
		return;
	sc_ssl_global.destroyed = TRUE;
#ifdef SC_DEBUG
	_debug( "END called\n" );
#endif
	/*
#ifdef USE_ITHREADS
	MUTEX_LOCK( &sc_ssl_global.thread_lock );
#endif
	for( i = 0; i <= SC_SSL_CTX_CASCADE; i++ ) {
		ctx1 = sc_ssl_global.ctx[i];
		while( ctx1 != NULL ) {
			ctx2 = ctx1->next;
			free_context( ctx1 );
			ctx1 = ctx2;
		}
		sc_ssl_global.ctx[i] = NULL;
	}
#ifdef USE_ITHREADS
	MUTEX_UNLOCK( &sc_ssl_global.thread_lock );
#endif
	*/
#ifdef USE_ITHREADS
	MUTEX_DESTROY( &sc_ssl_global.thread_lock );
#endif
#if SC_DEBUG > 1
	debug_free();
#endif


#/*****************************************************************************
# * SSL_CLONE()
# *****************************************************************************/

#ifdef USE_ITHREADS

void
SSL_CLONE( ... )
PREINIT:
	sc_ssl_ctx_t *ctx;
	int i;
PPCODE:
	(void) items; /* avoid compiler warning */
	MUTEX_LOCK( &sc_ssl_global.thread_lock );
	for( i = 0; i <= SC_SSL_CTX_CASCADE; i ++ ) {
		for( ctx = sc_ssl_global.ctx[i]; ctx != NULL; ctx = ctx->next ) {
			/*if( !ctx->dont_clone )*/
				ctx->refcnt ++;
#ifdef SC_DEBUG
			_debug( "CLONE called for ctx %d, refcnt: %d\n", ctx->id, ctx->refcnt );
#endif
		}
	}
	MUTEX_UNLOCK( &sc_ssl_global.thread_lock );

#endif


#/*****************************************************************************
# * SSL_new( this, %args )
# *****************************************************************************/

void
SSL_new( pkg, ... )
	SV *pkg;
PREINIT:
	sc_t *socket;
	int r, i, argc = 0;
	SV *sv;
	char **args, *key, *val;
PPCODE:
	Newx( args, items - 1, char * );
	/* read options */
	for( i = 1; i < items - 1; ) {
		key = SvPV_nolen( ST(i) );
		i++;
		switch( *key ) {
		case 'u':
		case 'U':
			if( my_stricmp( key, "use_ctx" ) == 0 ) {
				val = (char *) mod_sc_ssl_ctx_from_class( ST(i) );
				goto got_val;
			}
			break;
		}
		val = SvPV_nolen( ST(i) );
got_val:
		i++;
		args[argc++] = key;
		args[argc++] = val;
	}
	r = mod_sc_ssl_create( args, argc, &socket );
	Safefree( args );
	if( r != SC_OK )
		XSRETURN_EMPTY;
	/* create the class */
	r = mod_sc->sc_create_class( socket, SvPV_nolen( pkg ), &sv );
	if( r != SC_OK ) {
		mod_sc->sc_set_error( NULL,
			mod_sc->sc_get_errno( socket ), mod_sc->sc_get_error( socket ) );
		mod_sc->sc_destroy( socket );
		XSRETURN_EMPTY;
	}
	ST(0) = sv_2mortal( sv );
	XSRETURN(1);


#/*****************************************************************************
# * SSL_connect( this, host, serv, timeout )
# *****************************************************************************/

void
SSL_connect( this, ... )
	SV *this;
PREINIT:
	sc_t *socket;
	const char *ra = NULL, *rp = NULL;
	double ms = 0;
PPCODE:
	if( (socket = mod_sc->sc_get_socket( this )) == NULL )
		XSRETURN_EMPTY;
	switch( mod_sc->sc_get_family( socket ) ) {
	case AF_INET:
	case AF_INET6:
	default:
		switch( items ) {
		case 4:
		default:
			if( SvNOK( ST(3) ) || SvIOK( ST(3) ) )
				ms = SvNV( ST(3) );
		case 3:
			ra = SvPV_nolen( ST(1) );
			rp = SvPV_nolen( ST(2) );
			break;
		case 2:
			ra = SvPV_nolen( ST(1) );
			break;
		}
		break;
	case AF_UNIX:
		switch( items ) {
		case 3:
		default:
			if( SvNOK( ST(2) ) || SvIOK( ST(2) ) )
				ms = SvNV( ST(2) );
		case 2:
			ra = SvPV_nolen( ST(1) );
			break;
		}
		break;
	}
	if( mod_sc_ssl_connect( socket, ra, rp, ms ) != SC_OK )
		XSRETURN_EMPTY;
	XSRETURN_YES;


#/*****************************************************************************
# * SSL_listen( this [, queue] )
# *****************************************************************************/

void
SSL_listen( this, queue = SOMAXCONN )
	SV *this;
	int queue;
PREINIT:
	sc_t *socket;
PPCODE:
	if( (socket = mod_sc->sc_get_socket( this )) == NULL )
		XSRETURN_EMPTY;
	if( mod_sc_ssl_listen( socket, queue ) != SC_OK )
		XSRETURN_EMPTY;
	XSRETURN_YES;


#/*****************************************************************************
# * SSL_accept( this [, pkg] )
# *****************************************************************************/

void
SSL_accept( this, pkg = NULL )
	SV *this;
	char *pkg;
PREINIT:
	sc_t *socket, *client;
	SV *sv;
PPCODE:
	if( (socket = mod_sc->sc_get_socket( this )) == NULL )
		XSRETURN_EMPTY;
	if( mod_sc_ssl_accept( socket, &client ) != SC_OK )
		XSRETURN_EMPTY;
	if( client == NULL )
		XSRETURN_NO;
	if( mod_sc->sc_create_class( client, pkg, &sv ) != SC_OK ) {
		mod_sc->sc_set_error( socket,
			mod_sc->sc_get_errno( client ), mod_sc->sc_get_error( client ) );
		mod_sc->sc_destroy( client );
		XSRETURN_EMPTY;
	}
	ST(0) = sv_2mortal( sv );
	XSRETURN(1);


#/*****************************************************************************
# * SSL_recv( this, buf, len [, flags] )
# *****************************************************************************/

void
SSL_recv( this, buf, len, flags = 0 )
	SV *this;
	SV *buf;
	unsigned int len;
	unsigned int flags;
PREINIT:
	sc_t *socket;
	userdata_t *ud;
	int rlen;
PPCODE:
	if( (socket = mod_sc->sc_get_socket( this )) == NULL )
		XSRETURN_EMPTY;
	ud = (userdata_t *) mod_sc->sc_get_userdata( socket );
	if( ud->buffer_len < (int) len ) {
		ud->buffer_len = (int) len;
		Renew( ud->buffer, len, char );
	}
	if( mod_sc_ssl_recv( socket, ud->buffer, len, flags, &rlen ) != SC_OK )
		XSRETURN_EMPTY;
	if( rlen == 0 )
		XSRETURN_NO;
	sv_setpvn_mg( buf, ud->buffer, rlen );
	XSRETURN_IV( rlen );


#/*****************************************************************************
# * SSL_send( this, buf [, flags] )
# *****************************************************************************/

void
SSL_send( this, buf, flags = 0 )
	SV *this;
	SV *buf;
	unsigned int flags;
PREINIT:
	sc_t *socket;
	const char *msg;
	STRLEN len;
	int rlen;
PPCODE:
	if( (socket = mod_sc->sc_get_socket( this )) == NULL )
		XSRETURN_EMPTY;
	msg = SvPV( buf, len );
	if( mod_sc_ssl_send( socket, msg, (int) len, flags, &rlen ) != SC_OK )
		XSRETURN_EMPTY;
	if( rlen == 0 )
		XSRETURN_NO;
	XSRETURN_IV( rlen );


#/*****************************************************************************
# * SSL_recvfrom( this, buf, len [, flags] )
# *****************************************************************************/

void
SSL_recvfrom( this, buf, len, flags = 0 )
	SV *this;
	SV *buf;
	unsigned int len;
	unsigned int flags;
PREINIT:
	sc_t *socket;
	userdata_t *ud;
	sc_addr_t addr;
	int r, rlen;
PPCODE:
	if( (socket = mod_sc->sc_get_socket( this )) == NULL )
		XSRETURN_EMPTY;
	ud = mod_sc->sc_get_userdata( socket );
	if( ud->buffer_len < (int) len ) {
		ud->buffer_len = (int) len;
		Renew( ud->buffer, len, char );
	}
	r = mod_sc_ssl_recvfrom( socket, ud->buffer, (int) len, flags, &rlen );
	if( r != SC_OK )
		XSRETURN_EMPTY;
	if( rlen == 0 )
		XSRETURN_NO;
	sv_setpvn_mg( buf, ud->buffer, rlen );
	mod_sc->sc_remote_addr( socket, &addr );
	ST(0) = sv_2mortal( newSVpvn( (char *) &addr, SC_ADDR_SIZE( addr ) ) );
	XSRETURN(1);


#/*****************************************************************************
# * SSL_sendto( this, buf [, to [, flags]] )
# *****************************************************************************/

void
SSL_sendto( this, buf, to = NULL, flags = 0 )
	SV *this;
	SV *buf;
	SV *to;
	unsigned int flags;
PREINIT:
	sc_t *socket;
	const char *msg;
	STRLEN len;
	sc_addr_t *peer = NULL;
	int rlen, r;
PPCODE:
	if( (socket = mod_sc->sc_get_socket( this )) == NULL )
		XSRETURN_EMPTY;
	if( to != NULL && SvPOK( to ) ) {
		peer = (sc_addr_t *) SvPVbyte( to, len );
		if( len < sizeof( int ) || len != SC_ADDR_SIZE( *peer ) ) {
			mod_sc->sc_set_error( socket, -9999, "Invalid address" );
			XSRETURN_EMPTY;
		}
	}
	msg = SvPV( buf, len );
	r = mod_sc_ssl_sendto( socket, msg, (int) len, flags, peer, &rlen );
	if( r != SC_OK )
		XSRETURN_EMPTY;
	if( rlen == 0 )
		XSRETURN_NO;
	XSRETURN_IV( rlen );


#/*****************************************************************************
# * SSL_read( this, buf, len )
# *****************************************************************************/

void
SSL_read( this, buf, len )
	SV *this;
	SV *buf;
	int len;
PREINIT:
	sc_t *socket;
	userdata_t *ud;
	int rlen;
PPCODE:
	if( (socket = mod_sc->sc_get_socket( this )) == NULL )
		XSRETURN_EMPTY;
	ud = (userdata_t *) mod_sc->sc_get_userdata( socket );
	if( ud->buffer_len < len ) {
		ud->buffer_len = len;
		Renew( ud->buffer, len, char );
	}
	if( mod_sc_ssl_read( socket, ud->buffer, len, &rlen ) != SC_OK )
		XSRETURN_EMPTY;
	if( rlen == 0 )
		XSRETURN_NO;
	sv_setpvn_mg( buf, ud->buffer, rlen );
	XSRETURN_IV( len );


#/*****************************************************************************
# * SSL_write( this, buf [, start [, length]] )
# *****************************************************************************/

void
SSL_write( this, buf, ... )
	SV *this;
	SV *buf;
PREINIT:
	sc_t *socket;
	const char *msg;
	STRLEN l1;
	int start = 0, len, max, l2;
PPCODE:
	if( (socket = mod_sc->sc_get_socket( this )) == NULL )
		XSRETURN_EMPTY;
	msg = SvPV( buf, l1 );
	max = len = (int) l1;
	if( items > 2 ) {
		start = (int) SvIV( ST(2) );
		if( start < 0 ) {
			start += max;
			if( start < 0 )
				start = 0;
		}
		else if( start >= max )
			XSRETURN_IV( 0 );
	}
	if( items > 3 ) {
		l2 = (int) SvIV( ST(3) );
		if( l2 < 0 )
			len += l2;
		else if( l2 < len )
			len = l2;
	}
	if( start + len > max )
		len = max - start;
	if( len <= 0 )
		XSRETURN_IV( 0 );
	if( mod_sc_ssl_write( socket, msg + start, len, &len ) != SC_OK )
		XSRETURN_EMPTY;
	if( len == 0 )
		XSRETURN_NO;
	XSRETURN_IV( len );


#/*****************************************************************************
# * SSL_readline( this [, separator [, maxsize]] )
# *****************************************************************************/

void
SSL_readline( this, separator = NULL, maxsize = 0 )
	SV *this;
	char *separator;
	int maxsize;
PREINIT:
	sc_t *socket;
	int rlen, r;
	char *rbuf;
PPCODE:
	if( (socket = mod_sc->sc_get_socket( this )) == NULL )
		XSRETURN_EMPTY;
	if( separator != NULL ) {
		r = mod_sc_ssl_read_packet(
			socket, separator, (size_t) maxsize, &rbuf, &rlen );
		if( r != SC_OK )
			XSRETURN_EMPTY;
	}
	else {
		if( mod_sc_ssl_readline( socket, &rbuf, &rlen ) != SC_OK )
			XSRETURN_EMPTY;
	}
	ST(0) = sv_2mortal( newSVpvn( rbuf, rlen ) );
	XSRETURN(1);


#/*****************************************************************************
# * SSL_writeline( this, buf )
# *****************************************************************************/

void
SSL_writeline( this, buf )
	SV *this;
	SV *buf;
PREINIT:
	sc_t *socket;
	const char *msg;
	STRLEN len;
	int rlen;
PPCODE:
	if( (socket = mod_sc->sc_get_socket( this )) == NULL )
		XSRETURN_EMPTY;
	msg = SvPVx( buf, len );
	if( mod_sc_ssl_writeln( socket, msg, (int) len, &rlen ) != SC_OK )
		XSRETURN_EMPTY;
	if( rlen == 0 )
		XSRETURN_NO;
	XSRETURN_IV( rlen );


#/*****************************************************************************
# * SSL_print( this )
# *****************************************************************************/

void
SSL_print( this, ... )
	SV *this;
PREINIT:
	sc_t *socket;
	const char *s1;
	char *tmp = NULL;
	STRLEN l1, len = 0, pos = 0;
	int r, rlen;
PPCODE:
	if( (socket = mod_sc->sc_get_socket( this )) == NULL )
		XSRETURN_EMPTY;
	for( r = 1; r < items; r ++ ) {
		if( ! SvOK( ST(r) ) )
			continue;
		s1 = SvPVx( ST(r), l1 );
		if( pos + l1 > len ) {
			len = pos + l1 + 64;
			Renew( tmp, len, char );
		}
		Copy( s1, tmp + pos, l1, char );
		pos += l1;
	}
	if( tmp != NULL ) {
		r = mod_sc_ssl_write( socket, tmp, (int) pos, &rlen );
		Safefree( tmp );
		if( r != SC_OK )
			XSRETURN_EMPTY;
		if( rlen == 0 )
			XSRETURN_NO;
		XSRETURN_IV( rlen );
	}


#/*****************************************************************************
# * SSL_read_packet( this, separator [, maxsize] )
# *****************************************************************************/

void
SSL_read_packet( this, separator, maxsize = 0 )
	SV *this;
	char *separator;
	int maxsize;
PREINIT:
	sc_t *socket;
	int rlen, r;
	char *rbuf;
PPCODE:
	if( (socket = mod_sc->sc_get_socket( this )) == NULL )
		XSRETURN_EMPTY;
	r = mod_sc_ssl_read_packet(
		socket, separator, (size_t) maxsize, &rbuf, &rlen );
	if( r != SC_OK )
		XSRETURN_EMPTY;
	ST(0) = sv_2mortal( newSVpvn( rbuf, rlen ) );
	XSRETURN(1);


#/*****************************************************************************
# * SSL_to_string( this )
# *****************************************************************************/

void
SSL_to_string( this )
	SV *this;
PREINIT:
	sc_t *socket;
	char tmp[1024], *s;
	size_t len = sizeof(tmp);
	userdata_t *ud;
PPCODE:
	if( (socket = mod_sc->sc_get_socket( this )) == NULL )
		XSRETURN_EMPTY;
	if( mod_sc->sc_to_string( socket, tmp, &len ) != SC_OK )
		XSRETURN_EMPTY;
	ud = (userdata_t *) mod_sc->sc_get_userdata( socket );
	s = tmp + len - 1;
	if( ud->ssl != NULL ) {
		s = my_strcpy( s, ";SSL=" );
		s = my_strcpy( s, SSL_get_version( ud->ssl ) );
	}
	*s ++ = ')';
	*s = '\0';
	ST(0) = sv_2mortal( newSVpvn( tmp, (s - tmp) ) );
	XSRETURN(1);


#/*****************************************************************************
# * SSL_set_private_key( this, private_key )
# *****************************************************************************/

void
SSL_set_private_key( this, private_key )
	SV *this;
	char *private_key;
PREINIT:
	sc_t *socket;
PPCODE:
	if( (socket = mod_sc->sc_get_socket( this )) == NULL )
		XSRETURN_EMPTY;
	if( mod_sc_ssl_set_private_key( socket, private_key ) != SC_OK )
		XSRETURN_EMPTY;
	XSRETURN_YES;


#/*****************************************************************************
# * SSL_set_certificate( this, certificate )
# *****************************************************************************/

void
SSL_set_certificate( this, certificate )
	SV *this;
	char *certificate;
PREINIT:
	sc_t *socket;
PPCODE:
	if( (socket = mod_sc->sc_get_socket( this )) == NULL )
		XSRETURN_EMPTY;
	if( mod_sc_ssl_set_certificate( socket, certificate ) != SC_OK )
		XSRETURN_EMPTY;
	XSRETURN_YES;


#/*****************************************************************************
# * SSL_set_client_ca( this, client_ca )
# *****************************************************************************/

void
SSL_set_client_ca( this, client_ca )
	SV *this;
	char *client_ca;
PREINIT:
	sc_t *socket;
PPCODE:
	if( (socket = mod_sc->sc_get_socket( this )) == NULL )
		XSRETURN_EMPTY;
	if( mod_sc_ssl_set_client_ca( socket, client_ca ) != SC_OK )
		XSRETURN_EMPTY;
	XSRETURN_YES;


#/*****************************************************************************
# * SSL_set_verify_locations( this, ca_file [, ca_path] )
# *****************************************************************************/

void
SSL_set_verify_locations( this, ca_file, ca_path = NULL )
	SV *this;
	SV *ca_file;
	SV *ca_path;
PREINIT:
	sc_t *socket;
	char *caf, *cap;
PPCODE:
	if( (socket = mod_sc->sc_get_socket( this )) == NULL )
		XSRETURN_EMPTY;
	caf = SvPOK( ca_file ) ? SvPV_nolen( ca_file ) : NULL;
	cap = ca_path != NULL && SvPOK( ca_path ) ? SvPV_nolen( ca_path ) : NULL;
	if( mod_sc_ssl_set_verify_locations( socket, caf, cap ) != SC_OK )
		XSRETURN_EMPTY;
	XSRETURN_YES;


#/*****************************************************************************
# * SSL_create_client_context( this )
# *****************************************************************************/

void
SSL_create_client_context( this )
	SV *this;
PREINIT:
	sc_t *socket;
PPCODE:
	if( (socket = mod_sc->sc_get_socket( this )) == NULL )
		XSRETURN_EMPTY;
	if( mod_sc_ssl_create_client_context( socket ) != SC_OK )
		XSRETURN_EMPTY;
	XSRETURN_YES;


#/*****************************************************************************
# * SSL_create_server_context( this )
# *****************************************************************************/

void
SSL_create_server_context( this )
	SV *this;
PREINIT:
	sc_t *socket;
PPCODE:
	if( (socket = mod_sc->sc_get_socket( this )) == NULL )
		XSRETURN_EMPTY;
	if( mod_sc_ssl_create_server_context( socket ) != SC_OK )
		XSRETURN_EMPTY;
	XSRETURN_YES;


#/*****************************************************************************
# * SSL_check_private_key( this )
# *****************************************************************************/

void
SSL_check_private_key( this )
	SV *this;
PREINIT:
	sc_t *socket;
PPCODE:
	if( (socket = mod_sc->sc_get_socket( this )) == NULL )
		XSRETURN_EMPTY;
	if( mod_sc_ssl_check_private_key( socket ) != SC_OK )
		XSRETURN_EMPTY;
	XSRETURN_YES;


#/*****************************************************************************
# * SSL_enable_compatibility( this )
# *****************************************************************************/

void
SSL_enable_compatibility( this )
	SV *this;
PREINIT:
	sc_t *socket;
PPCODE:
	if( (socket = mod_sc->sc_get_socket( this )) == NULL )
		XSRETURN_EMPTY;
	if( mod_sc_ssl_enable_compatibility( socket ) != SC_OK )
		XSRETURN_EMPTY;
	XSRETURN_YES;


#/*****************************************************************************
# * SSL_get_cipher_name( this )
# *****************************************************************************/

void
SSL_get_cipher_name( this )
	SV *this;
PREINIT:
	sc_t *socket;
	const char *s;
PPCODE:
	if( (socket = mod_sc->sc_get_socket( this )) == NULL )
		XSRETURN_EMPTY;
	s = mod_sc_ssl_get_cipher_name( socket );
	if( s == NULL )
		XSRETURN_EMPTY;
	ST(0) = sv_2mortal( newSVpvn( s, strlen( s ) ) );
	XSRETURN_EMPTY;


#/*****************************************************************************
# * SSL_get_cipher_version( this )
# *****************************************************************************/

void
SSL_get_cipher_version( this )
	SV *this;
PREINIT:
	sc_t *socket;
	const char *s;
PPCODE:
	if( (socket = mod_sc->sc_get_socket( this )) == NULL )
		XSRETURN_EMPTY;
	s = mod_sc_ssl_get_cipher_version( socket );
	if( s == NULL )
		XSRETURN_EMPTY;
	ST(0) = sv_2mortal( newSVpvn( s, strlen( s ) ) );
	XSRETURN_EMPTY;


#/*****************************************************************************
# * SSL_get_ssl_version( this )
# *****************************************************************************/

void
SSL_get_ssl_version( this )
	SV *this;
PREINIT:
	sc_t *socket;
	const char *s;
PPCODE:
	if( (socket = mod_sc->sc_get_socket( this )) == NULL )
		XSRETURN_EMPTY;
	s = mod_sc_ssl_get_version( socket );
	if( s == NULL )
		XSRETURN_EMPTY;
	ST(0) = sv_2mortal( newSVpvn( s, strlen( s ) ) );
	XSRETURN_EMPTY;


#/*****************************************************************************
# * SSL_starttls( pkg, this )
# *****************************************************************************/

void
SSL_starttls( pkg, this, ... )
	SV *pkg;
	SV *this;
PREINIT:
	sc_t *socket;
	SV *sv;
	char **args, *key, *val;
	int argc = 0, i, r;
PPCODE:
	if( (socket = mod_sc->sc_get_socket( this )) == NULL )
		XSRETURN_EMPTY;
	Newx( args, items - 1, char * );
	/* read options */
	for( i = 2; i < items - 1; ) {
		key = SvPV_nolen( ST(i) );
		i++;
		switch( *key ) {
		case 'u':
		case 'U':
			if( my_stricmp( key, "use_ctx" ) == 0 ) {
				val = (char *) mod_sc_ssl_ctx_from_class( ST(i) );
				goto got_val;
			}
			break;
		}
		val = SvPV_nolen( ST(i) );
got_val:
		i++;
		args[argc++] = key;
		args[argc++] = val;
	}
	r = mod_sc_ssl_starttls( socket, args, argc );
	Safefree( args );
	if( r != SC_OK )
		XSRETURN_EMPTY;
	/* create a new class */
	if( mod_sc->sc_create_class( socket, SvPV_nolen( pkg ), &sv ) != SC_OK )
		XSRETURN_EMPTY;
	ST(0) = sv_2mortal( sv );
	XSRETURN(1);


#/*****************************************************************************
# * SSL_set_ssl_method( this, name )
# *****************************************************************************/

void
SSL_set_ssl_method( this, name )
	SV *this;
	char *name;
PREINIT:
	sc_t *socket;
PPCODE:
	if( (socket = mod_sc->sc_get_socket( this )) == NULL )
		XSRETURN_EMPTY;
	if( mod_sc_ssl_set_ssl_method( socket, name ) != SC_OK )
		XSRETURN_EMPTY;
	XSRETURN_YES;


#/*****************************************************************************
# * SSL_set_cipher_list( this, str )
# *****************************************************************************/

void
SSL_set_cipher_list( this, str )
	SV *this;
	char *str;
PREINIT:
	sc_t *socket;
PPCODE:
	if( (socket = mod_sc->sc_get_socket( this )) == NULL )
		XSRETURN_EMPTY;
	if( mod_sc_ssl_set_cipher_list( socket, str ) != SC_OK )
		XSRETURN_EMPTY;
	XSRETURN_YES;


#/*############################### SSL CONTEXT ###############################*/


MODULE = Socket::Class::SSL	PACKAGE = Socket::Class::SSL::CTX	PREFIX = CTX_


#/*****************************************************************************
# * CTX_new( pkg, ... )
# *****************************************************************************/

void
CTX_new( pkg, ... )
	char *pkg;
PREINIT:
	sc_ssl_ctx_t *ctx;
	int r, i, argc = 0;
	SV *sv;
	char **args;
PPCODE:
	(void) pkg; /* unused */
	Newx( args, items - 1, char * );
	/* read options */
	for( i = 1; i < items - 1; ) {
		args[argc ++] = SvPV_nolen( ST(i) );
		i ++;
		args[argc ++] = SvPV_nolen( ST(i) );
		i ++;
	}
	r = mod_sc_ssl_ctx_create( args, argc, &ctx );
	Safefree( args );
	if( r != SC_OK )
		XSRETURN_EMPTY;
	r = mod_sc_ssl_ctx_create_class( ctx, &sv );
	if( r != SC_OK )
		XSRETURN_EMPTY;
	ST(0) = sv_2mortal( sv );
	XSRETURN(1);


#/*****************************************************************************
# * CTX_DESTROY( this, ... )
# *****************************************************************************/

void
CTX_DESTROY( this, ... )
	SV *this;
PREINIT:
	sc_ssl_ctx_t *ctx;
PPCODE:
	if( (ctx = mod_sc_ssl_ctx_from_class( this )) == NULL )
		XSRETURN_EMPTY;
	/*
#ifdef USE_ITHREADS
	if( !ctx->dont_clone && ctx->thread_id == THREAD_ID() ) {
		ctx->dont_clone = TRUE;
#ifdef SC_DEBUG
		_debug( "disable futher CLONE for ctx %d\n", ctx->id );
#endif
	}
#endif
	*/
	mod_sc_ssl_ctx_destroy( ctx );


#/*****************************************************************************
# * CTX_set_ssl_method( this, name )
# *****************************************************************************/

void
CTX_set_ssl_method( this, name )
	SV *this;
	char *name;
PREINIT:
	sc_ssl_ctx_t *ctx;
PPCODE:
	if( (ctx = mod_sc_ssl_ctx_from_class( this )) == NULL )
		XSRETURN_EMPTY;
	if( mod_sc_ssl_ctx_set_ssl_method( ctx, name ) != SC_OK )
		XSRETURN_EMPTY;
	XSRETURN_YES;


#/*****************************************************************************
# * CTX_set_private_key( this, pk )
# *****************************************************************************/

void
CTX_set_private_key( this, pk )
	SV *this;
	char *pk;
PREINIT:
	sc_ssl_ctx_t *ctx;
PPCODE:
	if( (ctx = mod_sc_ssl_ctx_from_class( this )) == NULL )
		XSRETURN_EMPTY;
	if( mod_sc_ssl_ctx_set_private_key( ctx, pk ) != SC_OK )
		XSRETURN_EMPTY;
	XSRETURN_YES;


#/*****************************************************************************
# * CTX_set_certificate( this, crt )
# *****************************************************************************/

void
CTX_set_certificate( this, crt )
	SV *this;
	char *crt;
PREINIT:
	sc_ssl_ctx_t *ctx;
PPCODE:
	if( (ctx = mod_sc_ssl_ctx_from_class( this )) == NULL )
		XSRETURN_EMPTY;
	if( mod_sc_ssl_ctx_set_certificate( ctx, crt ) != SC_OK )
		XSRETURN_EMPTY;
	XSRETURN_YES;


#/*****************************************************************************
# * CTX_set_client_ca( this, client_ca )
# *****************************************************************************/

void
CTX_set_client_ca( this, client_ca )
	SV *this;
	char *client_ca;
PREINIT:
	sc_ssl_ctx_t *ctx;
PPCODE:
	if( (ctx = mod_sc_ssl_ctx_from_class( this )) == NULL )
		XSRETURN_EMPTY;
	if( mod_sc_ssl_ctx_set_client_ca( ctx, client_ca ) != SC_OK )
		XSRETURN_EMPTY;
	XSRETURN_YES;


#/*****************************************************************************
# * CTX_set_verify_locations( this, ca_file )
# *****************************************************************************/

void
CTX_set_verify_locations( this, ca_file, ca_path = NULL )
	SV *this;
	char *ca_file;
	char *ca_path;
PREINIT:
	sc_ssl_ctx_t *ctx;
PPCODE:
	if( (ctx = mod_sc_ssl_ctx_from_class( this )) == NULL )
		XSRETURN_EMPTY;
	if( mod_sc_ssl_ctx_set_verify_locations( ctx, ca_file, ca_path ) != SC_OK )
		XSRETURN_EMPTY;
	XSRETURN_YES;


#/*****************************************************************************
# * CTX_set_cipher_list( this, str )
# *****************************************************************************/

void
CTX_set_cipher_list( this, str )
	SV *this;
	char *str;
PREINIT:
	sc_ssl_ctx_t *ctx;
PPCODE:
	if( (ctx = mod_sc_ssl_ctx_from_class( this )) == NULL )
		XSRETURN_EMPTY;
	if( mod_sc_ssl_ctx_set_cipher_list( ctx, str ) != SC_OK )
		XSRETURN_EMPTY;
	XSRETURN_YES;


#/*****************************************************************************
# * CTX_check_private_key( this )
# *****************************************************************************/

void
CTX_check_private_key( this )
	SV *this;
PREINIT:
	sc_ssl_ctx_t *ctx;
PPCODE:
	if( (ctx = mod_sc_ssl_ctx_from_class( this )) == NULL )
		XSRETURN_EMPTY;
	if( mod_sc_ssl_ctx_check_private_key( ctx ) != SC_OK )
		XSRETURN_EMPTY;
	XSRETURN_YES;


#/*****************************************************************************
# * CTX_enable_compatibility( this )
# *****************************************************************************/

void
CTX_enable_compatibility( this )
	SV *this;
PREINIT:
	sc_ssl_ctx_t *ctx;
PPCODE:
	if( (ctx = mod_sc_ssl_ctx_from_class( this )) == NULL )
		XSRETURN_EMPTY;
	if( mod_sc_ssl_ctx_enable_compatibility( ctx ) != SC_OK )
		XSRETURN_EMPTY;
	XSRETURN_YES;


