#include "sc_ssl_mod_def.h"

sc_ssl_global_t sc_ssl_global;

int mod_sc_ssl_create( char **args, int argc, sc_t **p_socket ) {
	sc_t *socket;
	int r, i, argc2 = 0, listen = 0, is_client = -1;
	char *key, *val, **args2, *ra = NULL, *rp = NULL, *la = NULL, *lp = NULL;
	char *domain = NULL, *type = NULL, *proto = NULL;
	userdata_t *ud;
	sc_ssl_ctx_t *ctx, *use_ctx = NULL;
	if( argc % 2 ) {
		mod_sc->sc_set_errno( NULL, EINVAL );
		return SC_ERROR;
	}
	Newx( args2, argc + 6, char * );
	/* read options */
	for( i = 0; i < argc; ) {
		key = args[i ++];
		val = args[i ++];
		switch( *key ) {
		case 'd':
		case 'D':
			if( my_stricmp( key, "domain" ) == 0 ) {
				domain = val;
			}
			else {
				break;
			}
			continue;
		case 'f':
		case 'F':
			if( my_stricmp( key, "family" ) == 0 ) {
				domain = val;
			}
			else {
				break;
			}
			continue;
		case 'l':
		case 'L':
			if( my_stricmp( key, "local_addr" ) == 0 ) {
				la = val;
			}
			else if( my_stricmp( key, "local_port" ) == 0 ) {
				lp = val;
			}
			else if( my_stricmp( key, "local_path" ) == 0 ) {
				la = val;
				domain = "unix";
				proto = "0";
			}
			else if( my_stricmp( key, "listen" ) == 0 ) {
				listen = atoi( val );
				is_client = FALSE;
			}
			else {
				break;
			}
			continue;
		case 'p':
		case 'P':
			if( my_stricmp( key, "proto" ) == 0 ) {
				proto = val;
			}
			else {
				break;
			}
			continue;
		case 'r':
		case 'R':
			if( my_stricmp( key, "remote_addr" ) == 0 ) {
				ra = val;
				is_client = TRUE;
			}
			else if( my_stricmp( key, "remote_port" ) == 0 ) {
				rp = val;
				is_client = TRUE;
			}
			else if( my_stricmp( key, "remote_path" ) == 0 ) {
				ra = val;
				domain = "unix";
				proto = "0";
				is_client = TRUE;
			}
			else {
				break;
			}
			continue;
		case 't':
		case 'T':
			if( my_stricmp( key, "type" ) == 0 ) {
				type = val;
			}
			else {
				break;
			}
			continue;
		}
		args2[argc2 ++] = key;
		args2[argc2 ++] = val;
	}
	if( domain != NULL ) {
		args2[argc2 ++] = "domain";
		args2[argc2 ++] = domain;
	}
	if( type != NULL ) {
		args2[argc2 ++] = "type";
		args2[argc2 ++] = type;
	}
	if( proto != NULL ) {
		args2[argc2 ++] = "proto";
		args2[argc2 ++] = proto;
	}
	r = mod_sc->sc_create( args2, argc2, &socket );
	Safefree( args2 );
	if( r != SC_OK )
		return r;
	Newxz( ud, 1, userdata_t );
	mod_sc->sc_set_userdata( socket, ud, free_userdata );
	mod_sc_ssl_ctx_create( NULL, 0, &ctx );
	r = mod_sc_ssl_ctx_set_arg( ctx, args, argc, is_client, &use_ctx );
	if( use_ctx != NULL ) {
		mod_sc_ssl_ctx_destroy( ctx );
		use_ctx->refcnt++;
		ctx = use_ctx;
	}
	ud->sc_ssl_ctx = ctx;
	if( la != NULL || lp != NULL || listen ) {
		r = mod_sc->sc_bind( socket, la, lp );
		if( r != SC_OK )
			goto error;
	}
	if( listen ) {
		r = mod_sc_ssl_listen( socket, listen );
		if( r != SC_OK )
			goto error;
	}
	else if( ra != NULL || rp != NULL ) {
		r = mod_sc_ssl_connect( socket, ra, rp, 0 );
		if( r != SC_OK )
			goto error;
	}
	(*p_socket) = socket;
	return SC_OK;
error:
	mod_sc->sc_set_error( NULL,
		mod_sc->sc_get_errno( socket ), mod_sc->sc_get_error( socket )
	);
	mod_sc->sc_destroy( socket );
	return r;
}

int mod_sc_ssl_connect(
	sc_t *socket, const char *host, const char *serv, double timeout
) {
	userdata_t *ud;
	int r, err;
	ud = (userdata_t *) mod_sc->sc_get_userdata( socket );
	r = mod_sc->sc_connect( socket, host, serv, timeout );
	if( r != SC_OK )
		return r;
	r = mod_sc_ssl_create_client_context( socket );
	if( r != SC_OK )
		return r;
	/*
	if( ud->private_key != NULL ) {
		r = mod_sc_ssl_check_private_key( socket );
		if( r != SC_OK )
			return r;
	}
	*/
	/* get new SSL state with context */
	ud->ssl = SSL_new( ud->sc_ssl_ctx->ctx );
	/* set connection to SSL state */
	SSL_set_fd( ud->ssl, (int) mod_sc->sc_get_handle( socket ) );
	/* start the handshaking */
	r = SSL_connect( ud->ssl );
	if( r <= 0 ) {
		r = SSL_get_error( ud->ssl, r );
		err = ERR_get_error();
		if( err == 0 )
			mod_sc->sc_set_error( socket, r, my_ssl_error( r ) );
		else
			mod_sc->sc_set_error( socket, err, ERR_reason_error_string( err ) );
		return SC_ERROR;
	}
	ud->sc_ssl_ctx->is_client = TRUE;
	return SC_OK;
}

int mod_sc_ssl_listen( sc_t *socket, int queue ) {
	int r;
	userdata_t *ud;
	r = mod_sc_ssl_create_server_context( socket );
	if( r != SC_OK )
		return r;
	ud = (userdata_t *) mod_sc->sc_get_userdata( socket );
	if( ud->sc_ssl_ctx->private_key == NULL ) {
		r = mod_sc_ssl_set_certificate( socket, SC_SSL_DEFAULT_CRT );
		if( r != SC_OK )
			return r;
		r = mod_sc_ssl_set_private_key( socket, SC_SSL_DEFAULT_KEY );
		if( r != SC_OK )
			return r;
	}
	/*
	r = mod_sc_ssl_check_private_key( socket );
	if( r != SC_OK )
		return r;
	*/
	ud->sc_ssl_ctx->is_client = FALSE;
	return mod_sc->sc_listen( socket, queue );
}

int mod_sc_ssl_accept( sc_t *socket, sc_t **r_client ) {
	sc_t *client;
	userdata_t *ud, *udc;
	int r, err;
	r = mod_sc->sc_accept( socket, &client );
	if( r != SC_OK )
		return SC_ERROR;
	if( client == NULL ) {
		*r_client = NULL;
		return SC_OK;
	}
	ud = (userdata_t *) mod_sc->sc_get_userdata( socket );
	Newxz( udc, 1, userdata_t );
	mod_sc->sc_set_userdata( client, udc, free_userdata );
	/* use context of listen socket */
	udc->sc_ssl_ctx = ud->sc_ssl_ctx;
	udc->sc_ssl_ctx->refcnt++;
	/* get new SSL state with context */
	udc->ssl = SSL_new( udc->sc_ssl_ctx->ctx );
	/* set connection to SSL state */
	SSL_set_fd( udc->ssl, (int) mod_sc->sc_get_handle( client ) );
	/* start the handshaking */
	r = SSL_accept( udc->ssl );
	if( r < 0 ) {
		r = SSL_get_error( ud->ssl, r );
		err = ERR_get_error();
		if( err == 0 )
			mod_sc->sc_set_error( socket, r, my_ssl_error( r ) );
		else
			mod_sc->sc_set_error( socket, err, ERR_reason_error_string( err ) );
		mod_sc->sc_destroy( client );
		return SC_ERROR;
	}
#ifdef SC_DEBUG
	_debug( "cipher name %s\n", SSL_get_cipher_name( udc->ssl ) );
	_debug( "cipher version %s\n", SSL_get_cipher_version( udc->ssl ) );
#endif
	*r_client = client;
	return SC_OK;
}

int mod_sc_ssl_recv( sc_t *socket, char *buf, int len, int flags, int *p_len ) {
	userdata_t *ud;
	int r, err, len2 = 0;
	ud = (userdata_t *) mod_sc->sc_get_userdata( socket );
	if( ud->ssl == NULL ) {
		mod_sc->sc_set_errno( socket, ENOTCONN );
		return SC_ERROR;
	}
	if( ud->rcvbuf_pos > 0 ) {
		/* read from rcvbuf */
		len2 = ud->rcvbuf_pos < len ? ud->rcvbuf_pos : len;
#ifdef SC_DEBUG
		_debug( "read %d bytes from internal buffer\n", len2 );
#endif
		Copy( ud->rcvbuf, buf, len2, char );
		if( (flags & MSG_PEEK) == 0 ) {
			ud->rcvbuf_pos -= len2;
			if( ud->rcvbuf_pos > 0 )
				Move( ud->rcvbuf + len2, ud->rcvbuf, ud->rcvbuf_pos, char );
		}
		len -= len2;
		if( len == 0 || !SSL_pending( ud->ssl ) ) {
			*p_len = len2;
			return SC_OK;
		}
	}
	if( flags & MSG_PEEK ) {
		if( ud->rcvbuf_len < len + ud->rcvbuf_pos ) {
			ud->rcvbuf_len = len + ud->rcvbuf_pos;
			Renew( ud->rcvbuf, ud->rcvbuf_len, char );
		}
#ifdef SC_DEBUG
		_debug( "read %d bytes into internal buffer\n", len );
#endif
		r = SSL_read( ud->ssl, ud->rcvbuf + ud->rcvbuf_pos, len );
	}
	else {
#ifdef SC_DEBUG
		_debug( "read %d bytes\n", len );
#endif
		r = SSL_read( ud->ssl, buf + len2, len );
	}
#ifdef SC_DEBUG
	_debug( "got %d bytes from SSL_read\n", r );
#endif
	if( r <= 0 ) {
		r = SSL_get_error( ud->ssl, r );
		if( r == SSL_ERROR_WANT_READ ) {
			*p_len = len2;
			return SC_OK;
		}
		err = ERR_get_error();
		if( err == 0 )
			mod_sc->sc_set_error( socket, r, my_ssl_error( r ) );
		else
			mod_sc->sc_set_error( socket, err, ERR_reason_error_string( err ) );
		mod_sc->sc_set_state( socket, SC_STATE_ERROR );
		return SC_ERROR;
	}
	if( flags & MSG_PEEK ) {
		Copy( ud->rcvbuf + ud->rcvbuf_pos, buf + len2, r, char );
		ud->rcvbuf_pos += r;
	}
	*p_len = len2 + r;
	return SC_OK;
}

int mod_sc_ssl_send(
	sc_t *socket, const char *buf, int len, int flags, int *p_len
) {
	userdata_t *ud;
	int r, err;
	ud = (userdata_t *) mod_sc->sc_get_userdata( socket );
	if( ud->ssl == NULL ) {
		mod_sc->sc_set_errno( socket, ENOTCONN );
		return SC_ERROR;
	}
#ifdef SC_DEBUG
	_debug( "write %d bytes\n", len );
#endif
	r = SSL_write( ud->ssl, buf, len );
#ifdef SC_DEBUG
	_debug( "wrote %d bytes\n", r );
#endif
	if( r <= 0 ) {
		r = SSL_get_error( ud->ssl, r );
		if( r == SSL_ERROR_WANT_WRITE ) {
			*p_len = 0;
			return SC_OK;
		}
		err = ERR_get_error();
		if( err == 0 )
			mod_sc->sc_set_error( socket, r, my_ssl_error( r ) );
		else
			mod_sc->sc_set_error( socket, err, ERR_reason_error_string( err ) );
		mod_sc->sc_set_state( socket, SC_STATE_ERROR );
		return SC_ERROR;
	}
	*p_len = r;
	return SC_OK;
}

int mod_sc_ssl_recvfrom(
	sc_t *sock, char *buf, int len, int flags, int *p_len
) {
	mod_sc->sc_set_error(
		sock, -9999, "recvfrom() is not available on SSL sockets" );
	return SC_ERROR;
}

int mod_sc_ssl_sendto(
	sc_t *sock, const char *buf, int len, int flags, sc_addr_t *peer,
	int *p_len
) {
	mod_sc->sc_set_error(
		sock, -9999, "sendto() is not available on SSL sockets" );
	return SC_ERROR;
}

int mod_sc_ssl_read( sc_t *socket, char *buf, int len, int *p_len ) {
	return mod_sc_ssl_recv( socket, buf, len, 0, p_len );
}

int mod_sc_ssl_write( sc_t *socket, const char *buf, int len, int *p_len ) {
	return mod_sc_ssl_send( socket, buf, len, 0, p_len );
}

int mod_sc_ssl_readline( sc_t *socket, char **p_buf, int *p_len ) {
	userdata_t *ud;
	int r, l, i, pos = 0, len = 1024;
	char *p, ch;
	ud = (userdata_t *) mod_sc->sc_get_userdata( socket );
	p = ud->buffer;
	while( TRUE ) {
		if( ud->buffer_len < (pos + len) ) {
			ud->buffer_len = (pos + len);
			Renew( ud->buffer, ud->buffer_len, char );
			p = ud->buffer + pos;
		}
		r = mod_sc_ssl_recv( socket, p, len, MSG_PEEK, &l );
		if( r != SC_OK ) {
			if( pos > 0 )
				break;
			return SC_ERROR;
		}
		if( l == 0 ) {
			/* line not complete */
			*p_buf = ud->buffer;
			*p_len = pos;
			return SC_OK;
		}
		for( i = 0; i < l; i ++, p ++ ) {
			if( *p != '\n' && *p != '\r' && *p != '\0' )
				continue;
			/* found newline */
#ifdef SC_DEBUG
			_debug( "found newline at %d + %d of %d\n", pos, i, l );
#endif
			ch = *p;
			*p = '\0';
			*p_buf = ud->buffer;
			*p_len = pos + i;
			if( ch == '\r' || ch == '\n' ) {
				if( i < (size_t) l ) {
					if( p[1] == (ch == '\r' ? '\n' : '\r') )
						i ++;
				}
				else if( l == len ) {
					r = mod_sc_ssl_recv( socket, p, 1, MSG_PEEK, &l );
					if( r == SC_OK && l == 1 &&
						*p == (ch == '\r' ? '\n' : '\r')
					) {
						mod_sc_ssl_recv( socket, p, 1, 0, &l );
					}
				}
			}
			mod_sc_ssl_recv( socket, ud->buffer + pos, i + 1, 0, &l );
			return SC_OK;
		}
		mod_sc_ssl_recv( socket, ud->buffer + pos, i, 0, &l );
		pos += i;
		if( i < len ) {
			/* line not complete.
			 * next recv could block infinitely.
			 * stop here?
			 */
			break;
		}
	}
	ud->buffer[pos] = '\0';
	(*p_buf) = ud->buffer;
	(*p_len) = pos;
	return SC_OK;
}

int mod_sc_ssl_read_packet(
	sc_t *socket, char *separator, size_t max, char **p_buf, int *p_len
) {
	userdata_t *ud;
	int r, l;
	size_t i, pos = 0, len = 1024, seplen;
	char *p, *sep;
	for( sep = separator, seplen = 0; *sep != '\0'; sep++, seplen++ );
	if( seplen == 0 ) {
		mod_sc->sc_set_errno( socket, EINVAL );
		return SC_ERROR;
	}
	sep = separator;
	if( !max )
		max = (size_t) -1;
	ud = (userdata_t *) mod_sc->sc_get_userdata( socket );
	p = ud->buffer;
	while( TRUE ) {
		if( ud->buffer_len < (int) (pos + len) ) {
			ud->buffer_len = (int) (pos + len);
			Renew( ud->buffer, ud->buffer_len, char );
			p = ud->buffer + pos;
		}
		r = mod_sc_ssl_recv( socket, p, (int) len, MSG_PEEK, &l );
		if( r != SC_OK ) {
			if( pos > 0 )
				break;
			return SC_ERROR;
		}
		if( l == 0 ) {
			/* packet not complete */
			*p_buf = ud->buffer;
			*p_len = (int) pos;
			return SC_OK;
		}
		for( i = 0; i < (size_t) l; i ++, p ++ ) {
			if( pos + i == max ) {
#ifdef SC_DEBUG
				_debug( "packet max size %u reached\n", max );
#endif
				*p = '\0';
				*p_buf = ud->buffer;
				*p_len = (int) (pos + i);
				if( i > 0 )
					mod_sc_ssl_recv( socket, ud->buffer + pos, (int) i, 0, &l );
				return SC_OK;
			}
			if( *p != *sep ) {
				sep = separator;
				continue;
			}
			sep++;
			if( *sep != '\0' )
				continue;
			/* found packet separator */
#ifdef SC_DEBUG
			_debug( "found packet separator at %d + %d of %d\n", pos, i, l );
#endif
			i++;
			*p = '\0';
			*p_buf = ud->buffer;
			*p_len = (int) (pos + i - seplen);
			mod_sc_ssl_recv( socket, ud->buffer + pos, (int) i, 0, &l );
			return SC_OK;
		}
		mod_sc_ssl_recv( socket, ud->buffer + pos, (int) i, 0, &l );
		pos += i;
		if( i < len ) {
			/* packet not complete.
			 * next recv could block infinitely.
			 * stop here?
			 */
			break;
		}
	}
	ud->buffer[pos] = '\0';
	*p_buf = ud->buffer;
	*p_len = (int) pos;
	return SC_OK;
}

int mod_sc_ssl_writeln( sc_t *socket, const char *buf, int len, int *p_len ) {
	userdata_t *ud;
	char *p;
	ud = (userdata_t *) mod_sc->sc_get_userdata( socket );
	if( len <= 0 )
		len = (int) strlen( buf );
	if( ud->buffer_len < len + 2 ) {
		ud->buffer_len = len + 2;
		Renew( ud->buffer, len, char );
	}
	p = ud->buffer;
	Copy( buf, p, len, char );
	p[len ++] = '\r';
	p[len ++] = '\n';
	return mod_sc_ssl_send( socket, p, len, 0, p_len );
}

int mod_sc_ssl_printf( sc_t *socket, const char *fmt, ... ) {
	int r;
	va_list vl;
	va_start( vl, fmt );
	r = mod_sc_ssl_vprintf( socket, fmt, vl );
	va_end( vl );
	return r;
}

int mod_sc_ssl_vprintf( sc_t *socket, const char *fmt, va_list vl ) {
	const char *s, *s2;
	char *tmp;
	int isbig, size = (int) strlen( fmt ) + 64, r;
	va_list vlc;
#if defined (va_copy)
	va_copy( vlc, vl );
#elif defined (__va_copy)
	__va_copy( vlc, vl );
#else
	vlc = vl;
#endif
	for( s = fmt; *s != '\0'; s ++ ) {
		if( *s != '%' )
			continue;
		s ++;
		if( *s == '%' )
			continue;
		for( ; *s < 'a' || *s > 'z'; s ++ ) {
			if( *s == '\0' )
				goto finish;
		}
		isbig = 0;
again:
		switch( *s ) {
		case 'l':
			isbig = 1;
			s ++;
			goto again;
		case 'c':
		case 'C':
			va_arg( vlc, int );
			size += 4;
			break;
		case 'd':
		case 'i':
		case 'u':
		case 'o':
		case 'x':
		case 'X':
			if( isbig ) {
				va_arg( vlc, XLONG );
				size += sizeof( XLONG ) / 2 * 5 + 1;
			}
			else {
				va_arg( vlc, long );
				size += sizeof( long ) / 2 * 5 + 1;
			}
			break;
		case 'a':
		case 'A':
		case 'e':
		case 'E':
		case 'f':
		case 'g':
		case 'G':
			if( isbig ) {
				va_arg( vlc, long double );
				size += 128;
			}
			else {
				va_arg( vlc, double );
				size += 64;
			}
			break;
		case 's':
		case 'S':
			s2 = va_arg( vlc, const char * );
			size += (int) strlen( s2 );
			break;
		case 'p':
			s2 = va_arg( vlc, const void * );
			size += sizeof( void * ) / 2 * 5;
			break;
		}
	}
finish:
	va_end( vlc );
#ifdef SC_DEBUG
	_debug( "vprintf size %u\n", size );
#endif
	Newx( tmp, size, char );
#ifdef _WIN32
	size = _vsnprintf( tmp, size, fmt, vl );
#else
	size = vsnprintf( tmp, size, fmt, vl );
#endif
#ifdef SC_DEBUG
	_debug( "vprintf size %u\n", size );
#endif
	r = mod_sc_ssl_send( socket, tmp, size, 0, &size );
	Safefree( tmp );
	return r;
}

int mod_sc_ssl_available( sc_t *socket, int *p_len ) {
	userdata_t *ud = (userdata_t *) mod_sc->sc_get_userdata( socket );
	if( ud->ssl == NULL ) {
		mod_sc->sc_set_errno( socket, ENOTCONN );
		return SC_ERROR;
	}
	*p_len = SSL_pending( ud->ssl );
	return SC_OK;
}

void mod_sc_ssl_set_userdata( sc_t *socket, void *p, void (*free) (void *p) ) {
	userdata_t *ud = (userdata_t *) mod_sc->sc_get_userdata( socket );
	ud->user_data = p;
	ud->free_user_data = free;
}

void *mod_sc_ssl_get_userdata( sc_t *socket ) {
	userdata_t *ud = (userdata_t *) mod_sc->sc_get_userdata( socket );
	return ud->user_data;
}

int mod_sc_ssl_set_private_key( sc_t *socket, const char *pk ) {
	userdata_t *ud = (userdata_t *) mod_sc->sc_get_userdata( socket );
	sc_ssl_ctx_t *ctx = ud->sc_ssl_ctx;
	ctx->socket = socket;
	return mod_sc_ssl_ctx_set_private_key( ctx, pk );
}

int mod_sc_ssl_set_certificate( sc_t *socket, const char *crt ) {
	userdata_t *ud = (userdata_t *) mod_sc->sc_get_userdata( socket );
	sc_ssl_ctx_t *ctx = ud->sc_ssl_ctx;
	ctx->socket = socket;
	return mod_sc_ssl_ctx_set_certificate( ctx, crt );
}

int mod_sc_ssl_set_client_ca( sc_t *socket, const char *str ) {
	userdata_t *ud = (userdata_t *) mod_sc->sc_get_userdata( socket );
	sc_ssl_ctx_t *ctx = ud->sc_ssl_ctx;
	ctx->socket = socket;
	return mod_sc_ssl_ctx_set_client_ca( ctx, str );
}

int mod_sc_ssl_set_verify_locations(
	sc_t *socket, const char *cafile, const char *capath
) {
	userdata_t *ud = (userdata_t *) mod_sc->sc_get_userdata( socket );
	sc_ssl_ctx_t *ctx = ud->sc_ssl_ctx;
	ctx->socket = socket;
	return mod_sc_ssl_ctx_set_verify_locations( ctx, cafile, capath );
}

int mod_sc_ssl_shutdown( sc_t *socket ) {
	userdata_t *ud;
	int r, err;
	ud = (userdata_t *) mod_sc->sc_get_userdata( socket );
	if( ud->ssl != NULL ) {
		r = SSL_shutdown( ud->ssl );
		if( r <= 0 ) {
			r = SSL_get_error( ud->ssl, r );
			err = ERR_get_error();
			if( err == 0 )
				mod_sc->sc_set_error( socket, r, my_ssl_error( r ) );
			else
				mod_sc->sc_set_error( socket, err, ERR_reason_error_string( err ) );
			return SC_ERROR;
		}
	}
	return SC_OK;
}

int mod_sc_ssl_create_client_context( sc_t *socket ) {
	userdata_t *ud = (userdata_t *) mod_sc->sc_get_userdata( socket );
	sc_ssl_ctx_t *ctx = ud->sc_ssl_ctx;
	if( ud->ssl != NULL ) {
		mod_sc->sc_close( socket );
		SSL_free( ud->ssl );
		ud->ssl = NULL;
	}
	ctx->socket = socket;
	return mod_sc_ssl_ctx_init_client( ctx );
}

int mod_sc_ssl_create_server_context( sc_t *socket ) {
	userdata_t *ud = (userdata_t *) mod_sc->sc_get_userdata( socket );
	sc_ssl_ctx_t *ctx = ud->sc_ssl_ctx;
	if( ud->ssl != NULL ) {
		mod_sc->sc_close( socket );
		SSL_free( ud->ssl );
		ud->ssl = NULL;
	}
	ctx->socket = socket;
	return mod_sc_ssl_ctx_init_server( ctx );
}


int mod_sc_ssl_check_private_key( sc_t *socket ) {
	userdata_t *ud = (userdata_t *) mod_sc->sc_get_userdata( socket );
	sc_ssl_ctx_t *ctx = ud->sc_ssl_ctx;
	ctx->socket = socket;
	return mod_sc_ssl_ctx_check_private_key( ctx );
}

int mod_sc_ssl_enable_compatibility( sc_t *socket ) {
	userdata_t *ud = (userdata_t *) mod_sc->sc_get_userdata( socket );
	sc_ssl_ctx_t *ctx = ud->sc_ssl_ctx;
	ctx->socket = socket;
	return mod_sc_ssl_ctx_enable_compatibility( ctx );
}

const char *mod_sc_ssl_get_cipher_name( sc_t *socket ) {
	userdata_t *ud;
	ud = (userdata_t *) mod_sc->sc_get_userdata( socket );
	if( ud->ssl == NULL )
		return NULL;
	return SSL_get_cipher_name( ud->ssl );
}

const char *mod_sc_ssl_get_cipher_version( sc_t *socket ) {
	userdata_t *ud;
	ud = (userdata_t *) mod_sc->sc_get_userdata( socket );
	if( ud->ssl == NULL )
		return NULL;
	return SSL_get_cipher_version( ud->ssl );
}

const char *mod_sc_ssl_get_version( sc_t *socket ) {
	userdata_t *ud;
	ud = (userdata_t *) mod_sc->sc_get_userdata( socket );
	if( ud->ssl == NULL )
		return NULL;
	return SSL_get_version( ud->ssl );
}

int mod_sc_ssl_starttls( sc_t *socket, char **args, int argc ) {
	int r, err, blocking;
	userdata_t *ud = (userdata_t *) mod_sc->sc_get_userdata( socket );
	sc_ssl_ctx_t *ctx, *use_ctx = NULL;
	if( ud == NULL ) {
		Newxz( ud, 1, userdata_t );
		mod_sc->sc_set_userdata( socket, ud, free_userdata );
		mod_sc_ssl_ctx_create( NULL, 0, &ud->sc_ssl_ctx );
	}
	mod_sc->sc_get_blocking( socket, &blocking );
	if( !blocking )
		mod_sc->sc_set_blocking( socket, 1 );
	ctx = ud->sc_ssl_ctx;
	r = mod_sc_ssl_ctx_set_arg( ctx, args, argc, TRUE, &use_ctx );
	if( r != SC_OK )
		goto exit;
	if( use_ctx != NULL ) {
		mod_sc_ssl_ctx_destroy( ctx );
		use_ctx->refcnt++;
		ud->sc_ssl_ctx = ctx = use_ctx;
	}
	ud->ssl = SSL_new( ctx->ctx );
	SSL_set_fd( ud->ssl, (int) mod_sc->sc_get_handle( socket ) );
	if( ctx->is_client ) {
		SSL_set_connect_state( ud->ssl );
	}
	else {
		/* start the handshaking */
		r = SSL_accept( ud->ssl );
		if( r < 0 ) {
			r = SSL_get_error( ud->ssl, r );
			if( (err = ERR_get_error()) == 0 ) {
				mod_sc->sc_set_error( socket, r, my_ssl_error( r ) );
			}
			else {
				mod_sc->sc_set_error(
					socket, err, ERR_reason_error_string( err ) );
			}
			r = SC_ERROR;
			goto exit;
		}
	}
	r = SC_OK;
exit:
	if( !blocking )
		mod_sc->sc_set_blocking( socket, 0 );
	return r;
}

int mod_sc_ssl_set_ssl_method( sc_t *socket, const char *name ) {
	userdata_t *ud = (userdata_t *) mod_sc->sc_get_userdata( socket );
	sc_ssl_ctx_t *ctx = ud->sc_ssl_ctx;
	ctx->socket = socket;
	return mod_sc_ssl_ctx_set_ssl_method( ctx, name );
}

int mod_sc_ssl_set_cipher_list( sc_t *socket, const char *str ) {
	userdata_t *ud = (userdata_t *) mod_sc->sc_get_userdata( socket );
	sc_ssl_ctx_t *ctx = ud->sc_ssl_ctx;
	ctx->socket = socket;
	return mod_sc_ssl_ctx_set_cipher_list( ctx, str );
}

/* ssl context */

int mod_sc_ssl_ctx_create( char **args, int argc, sc_ssl_ctx_t **p_ctx ) {
	int r;
	sc_ssl_ctx_t *ctx;
	Newxz( ctx, 1, sc_ssl_ctx_t );
	if( argc > 0 ) {
		r = mod_sc_ssl_ctx_set_arg( ctx, args, argc, TRUE, NULL );
		if( r != SC_OK ) {
			Safefree( ctx );
			return r;
		}
	}
	ctx->refcnt = 1;
#ifdef USE_ITHREADS
	MUTEX_LOCK( &sc_ssl_global.thread_lock );
#endif
	ctx->id = ++sc_ssl_global.counter;
	r = ctx->id & SC_SSL_CTX_CASCADE;
	ctx->next = sc_ssl_global.ctx[r];
	sc_ssl_global.ctx[r] = ctx;
#ifdef USE_ITHREADS
	MUTEX_UNLOCK( &sc_ssl_global.thread_lock );
#endif
#ifdef SC_DEBUG
	_debug( "created ctx %d, refcnt %d\n", ctx->id, ctx->refcnt );
#endif
	(*p_ctx) = ctx;
	return SC_OK;
}

int mod_sc_ssl_ctx_destroy( sc_ssl_ctx_t *ctx ) {
#ifdef SC_DEBUG
	_debug( "destroy ctx %d, refcnt %d\n", ctx->id, ctx->refcnt );
#endif
	if( --ctx->refcnt > 0 )
		return SC_OK;
	if( remove_context( ctx ) == SC_OK ) {
		free_context( ctx );
		return SC_OK;
	}
	mod_sc->sc_set_error( NULL, -9999, "Invalid context" );
	return SC_ERROR;
}

int mod_sc_ssl_ctx_create_class( sc_ssl_ctx_t *ctx, SV **psv ) {
	HV *hv;
	SV *sv;
	/*
	if( !ctx->thread_id )
		ctx->thread_id = THREAD_ID();
	*/
	hv = gv_stashpvn( "Socket::Class::SSL::CTX", 23, FALSE );
	if( hv == NULL ) {
		mod_sc->sc_set_error(
			NULL, -9999, "Invalid package Socket::Class::SSL::CTX" );
		return SC_ERROR;
	}
	sv = sv_2mortal( (SV *) newSViv( (IV) ctx->id ) );
#ifdef SC_DEBUG
	_debug( "bless ctx %d with Socket::Class::SSL::CTX\n", ctx->id );
#endif
	*psv = sv_bless( newRV( sv ), hv );
	return SC_OK;
}

sc_ssl_ctx_t *mod_sc_ssl_ctx_from_class( SV *sv ) {
	int id, i;
	sc_ssl_ctx_t *ctx;
	if( !SvROK( sv ) )
		return NULL;
	sv = SvRV( sv );
	if( !SvIOK( sv ) )
		return NULL;
	id = (int) SvIV( sv );
	i = id & SC_SSL_CTX_CASCADE;
#ifdef USE_ITHREADS
	if( !sc_ssl_global.destroyed )
		MUTEX_LOCK( &sc_ssl_global.thread_lock );
#endif
	for( ctx = sc_ssl_global.ctx[i]; ctx != NULL; ctx = ctx->next ) {
		if( ctx->id == id )
			goto found;
	}
#ifdef SC_DEBUG
	_debug( "ctx %d NOT found\n", id );
#endif
found:
#ifdef USE_ITHREADS
	if( !sc_ssl_global.destroyed )
		MUTEX_UNLOCK( &sc_ssl_global.thread_lock );
#endif
	return ctx;
}

int mod_sc_ssl_ctx_set_arg(
	sc_ssl_ctx_t *ctx, char **args, int argc, int is_client,
	sc_ssl_ctx_t **p_ctx
) {
	int r, i;
	char *key, *val, *pk = NULL, *crt = NULL, *cca = NULL, *caf = NULL;
	char *cap = NULL, *ciphlist = NULL, *sslmethod = NULL;
	sc_ssl_ctx_t *usectx = NULL;
	if( argc % 2 ) {
		mod_sc->sc_set_errno( ctx->socket, EINVAL );
		return SC_ERROR;
	}
	for( i = 0; i < argc; ) {
		key = args[i++];
		val = args[i++];
		switch( *key ) {
		case 'c':
		case 'C':
			if( my_stricmp( key, "certificate" ) == 0 ) {
				crt = val;
			}
			else if( my_stricmp( key, "cipher_list" ) == 0 ) {
				ciphlist = val;
			}
			else if( my_stricmp( key, "client_ca" ) == 0 ) {
				cca = val;
			}
			else if( my_stricmp( key, "ca_file" ) == 0 ) {
				caf = val;
			}
			else if( my_stricmp( key, "ca_path" ) == 0 ) {
				cap = val;
			}
			break;
		case 'p':
		case 'P':
			if( my_stricmp( key, "private_key" ) == 0 ) {
				pk = val;
			}
			break;
		case 's':
		case 'S':
			if( my_stricmp( key, "server" ) == 0 ) {
				is_client = *val == '\0' || *val == '0';
			}
			else if( my_stricmp( key, "ssl_method" ) == 0 ) {
				sslmethod = val;
			}
			break;
		case 'u':
		case 'U':
			if( my_stricmp( key, "use_ctx" ) == 0 ) {
				usectx = (sc_ssl_ctx_t *) val;
			}
			break;
		}
	}
	if( usectx != NULL && usectx->ctx != NULL && p_ctx != NULL ) {
#ifdef SC_DEBUG
		_debug( "use ctx %d\n", usectx->id );
#endif
		(*p_ctx) = usectx;
		return SC_OK;
	}
	ctx->is_client = is_client;
	r = mod_sc_ssl_ctx_set_ssl_method( ctx, sslmethod );
	if( r != SC_OK )
		return SC_ERROR;
	if( is_client >= 0 ) {
		if( is_client )
			r = mod_sc_ssl_ctx_init_client( ctx );
		else
			r = mod_sc_ssl_ctx_init_server( ctx );
		if( r != SC_OK )
			return r;
	}
	if( crt != NULL ) {
		r = mod_sc_ssl_ctx_set_certificate( ctx, crt );
		if( r != SC_OK )
			return r;
	}
	if( pk != NULL ) {
		r = mod_sc_ssl_ctx_set_private_key( ctx, pk );
		if( r != SC_OK )
			return r;
	}
	if( cca != NULL ) {
		r = mod_sc_ssl_ctx_set_client_ca( ctx, cca );
		if( r != SC_OK )
			return r;
	}
	if( caf != NULL || cap != NULL ) {
		r = mod_sc_ssl_ctx_set_verify_locations( ctx, caf, cap );
		if( r != SC_OK )
			return r;
	}
	if( ciphlist != NULL ) {
		r = mod_sc_ssl_ctx_set_cipher_list( ctx, ciphlist );
		if( r != SC_OK )
			return r;
	}
	return SC_OK;
}

int mod_sc_ssl_ctx_set_ssl_method( sc_ssl_ctx_t *ctx, const char *name ) {
#ifdef SC_DEBUG
	_debug( "set ssl method '%s'\n", name );
#endif
	if( name == NULL || *name == '\0' ) {
		ctx->method_id = sslv23;
	}
	else if( my_stricmp( name, "TLSV1" ) == 0 ) {
		ctx->method_id = tlsv1;
	}
	else if( my_stricmp( name, "SSLV3" ) == 0 ) {
		ctx->method_id = sslv3;
	}
	else if( my_stricmp( name, "SSLV23" ) == 0 ) {
		ctx->method_id = sslv23;
	}
	else if( my_stricmp( name, "SSLV2" ) == 0 ) {
		ctx->method_id = sslv2;
	}
	else {
		mod_sc->sc_set_error( ctx->socket, -1, "invalid ssl method: %s", name );
		return SC_ERROR;
	}
	return SC_OK;
}

int mod_sc_ssl_ctx_set_private_key( sc_ssl_ctx_t *ctx, const char *pk ) {
	int r, l = (int) strlen( pk );
	Renew( ctx->private_key, l + 1, char );
	Copy( pk, ctx->private_key, l + 1, char );
	if( ctx->ctx != NULL ) {
		/* set the private key from KeyFile */
#ifdef SC_DEBUG
		_debug( "use private key from '%s'\n", ctx->private_key );
#endif
		r = SSL_CTX_use_PrivateKey_file(
			ctx->ctx, ctx->private_key, SSL_FILETYPE_PEM );
		if( ! r ) {
			r = ERR_get_error();
			mod_sc->sc_set_error(
				ctx->socket, r, ERR_reason_error_string( r ) );
			return SC_ERROR;
		}
	}
	return SC_OK;
}

int mod_sc_ssl_ctx_set_certificate( sc_ssl_ctx_t *ctx, const char *crt ) {
	int r, l = (int) strlen( crt );
	Renew( ctx->certificate, l + 1, char );
	Copy( crt, ctx->certificate, l + 1, char );
	if( ctx->ctx != NULL ) {
		/* set the local certificate from CertFile */
#ifdef SC_DEBUG
		_debug( "use certificate from '%s'\n", ctx->certificate );
#endif
		r = SSL_CTX_use_certificate_chain_file(
			ctx->ctx, ctx->certificate );
		if( ! r ) {
			r = ERR_get_error();
			mod_sc->sc_set_error(
				ctx->socket, r, ERR_reason_error_string( r ) );
			return SC_ERROR;
		}
	}
	return SC_OK;
}

int mod_sc_ssl_ctx_set_client_ca( sc_ssl_ctx_t *ctx, const char *str ) {
	int l = (int) strlen( str );
	Renew( ctx->client_ca, l + 1, char );
	Copy( str, ctx->client_ca, l + 1, char );
	if( ctx->ctx != NULL ) {
		SSL_CTX_set_client_CA_list(
			ctx->ctx, SSL_load_client_CA_file( ctx->client_ca ) );
	}
	return SC_OK;
}

int mod_sc_ssl_ctx_set_verify_locations(
	sc_ssl_ctx_t *ctx, const char *cafile, const char *capath
) {
	int r;
	if( cafile != NULL ) {
		r = (int) strlen( cafile );
		Renew( ctx->ca_file, r + 1, char );
		Copy( cafile, ctx->ca_file, r + 1, char );
	}
	else if( ctx->ca_file != NULL ) {
		Safefree( ctx->ca_file );
		ctx->ca_file = NULL;
	}
	if( capath != NULL ) {
		r = (int) strlen( capath );
		Newx( ctx->ca_path, r + 1, char );
		Copy( capath, ctx->ca_path, r + 1, char );
	}
	else if( ctx->ca_path != NULL ) {
		Safefree( ctx->ca_path );
		ctx->ca_path = NULL;
	}
	if( ctx->ctx != NULL ) {
		r = SSL_CTX_load_verify_locations( ctx->ctx, cafile, capath );
		if( ! r ) {
			r = ERR_get_error();
			mod_sc->sc_set_error(
				ctx->socket, r, ERR_reason_error_string( r ) );
			return SC_ERROR;
		}
	}
	return SC_OK;
}

int mod_sc_ssl_ctx_set_cipher_list( sc_ssl_ctx_t *ctx, const char *str ) {
	int l = (int) strlen( str ), r;
	Renew( ctx->cipher_list, l + 1, char );
	Copy( str, ctx->cipher_list, l + 1, char );
	if( ctx->ctx != NULL ) {
#ifdef SC_DEBUG
		_debug( "set cipher list '%s'\n", ctx->cipher_list );
#endif
		if( !SSL_CTX_set_cipher_list( ctx->ctx, ctx->cipher_list ) ) {
			r = ERR_get_error();
			mod_sc->sc_set_error(
				ctx->socket, r, ERR_reason_error_string( r ) );
			return SC_ERROR;
		}
	}
	return SC_OK;
}

int mod_sc_ssl_ctx_check_private_key( sc_ssl_ctx_t *ctx ) {
	if( ctx->ctx == NULL ) {
		mod_sc->sc_set_error( ctx->socket, -9999, "Invalid context" );
		return SC_ERROR;
	}
	/* verify private key */
	if( !SSL_CTX_check_private_key( ctx->ctx ) ) {
#ifdef SC_DEBUG
		_debug( "!!! invalid private key !!!\n" );
#endif
		mod_sc->sc_set_error( ctx->socket, -9999, "Invalid private key" );
		return SC_ERROR;
	}
	return SC_OK;
}

int mod_sc_ssl_ctx_enable_compatibility( sc_ssl_ctx_t *ctx ) {
	if( ctx->ctx == NULL ) {
		mod_sc->sc_set_error( ctx->socket, -9999, "Invalid context" );
		return SC_ERROR;
	}
	SSL_CTX_set_options( ctx->ctx, SSL_OP_ALL );
	return SC_OK;
}

int mod_sc_ssl_ctx_init_client( sc_ssl_ctx_t *ctx ) {
	int r;
	SSL_METHOD *method;
	switch( ctx->method_id ) {
	case sslv2:
		method = (SSL_METHOD *) SSLv2_client_method();
		break;
	default:
	case sslv23:
		method = (SSL_METHOD *) SSLv23_client_method();
		break;
	case sslv3:
		method = (SSL_METHOD *) SSLv3_client_method();
		break;
	case tlsv1:
		method = (SSL_METHOD *) TLSv1_client_method();
		break;
	}
	if( ctx->method != method ) {
		if( ctx->ctx != NULL )
			SSL_CTX_free( ctx->ctx );
		/* create ssl instance */
		ctx->method = method;
		/* create context */
		ctx->ctx = SSL_CTX_new( ctx->method );
		/* load verify locations */
		if( ctx->ca_file != NULL || ctx->ca_path != NULL ) {
			r = SSL_CTX_load_verify_locations(
				ctx->ctx, ctx->ca_file, ctx->ca_path );
			if( ! r )
				goto error;
		}
		if( ctx->certificate != NULL ) {
			/* set the local certificate from CertFile */
#ifdef SC_DEBUG
			_debug( "use certificate from '%s'\n", ctx->certificate );
#endif
			r = SSL_CTX_use_certificate_file(
				ctx->ctx, ctx->certificate, SSL_FILETYPE_PEM );
			if( ! r )
				goto error;
		}
		if( ctx->private_key != NULL ) {
			/* set the private key from KeyFile */
#ifdef SC_DEBUG
			_debug( "use private key from '%s'\n", ctx->private_key );
#endif
			r = SSL_CTX_use_PrivateKey_file(
				ctx->ctx, ctx->private_key, SSL_FILETYPE_PEM );
			if( ! r )
				goto error;
		}
		/* set cipher list */
		if( ctx->cipher_list != NULL ) {
#ifdef SC_DEBUG
			_debug( "set cipher list '%s'\n", ctx->cipher_list );
#endif
			if( !SSL_CTX_set_cipher_list( ctx->ctx, ctx->cipher_list ) )
				goto error;
		}
		/* set auto retry */
		SSL_CTX_set_mode( ctx->ctx, SSL_MODE_AUTO_RETRY );
	}
	return SC_OK;
error:
	r = ERR_get_error();
	mod_sc->sc_set_error( ctx->socket, r, ERR_reason_error_string( r ) );
	return SC_ERROR;
}

int mod_sc_ssl_ctx_init_server( sc_ssl_ctx_t *ctx ) {
	int r;
	SSL_METHOD *method;
	switch( ctx->method_id ) {
	case sslv2:
		method = (SSL_METHOD *) SSLv2_server_method();
		break;
	default:
	case sslv23:
		method = (SSL_METHOD *) SSLv23_server_method();
		break;
	case sslv3:
		method = (SSL_METHOD *) SSLv3_server_method();
		break;
	case tlsv1:
		method = (SSL_METHOD *) TLSv1_server_method();
		break;
	}
	if( ctx->method != method ) {
		if( ctx->ctx != NULL )
			SSL_CTX_free( ctx->ctx );
		/* create ssl instance */
		ctx->method = method;
		/* create context */
		ctx->ctx = SSL_CTX_new( ctx->method );
		/* load verify locations */
		if( ctx->ca_file != NULL || ctx->ca_path != NULL ) {
			r = SSL_CTX_load_verify_locations(
				ctx->ctx, ctx->ca_file, ctx->ca_path );
			if( ! r )
				goto error;
		}
		if( ctx->client_ca != NULL ) {
			/* set the client ca */
#ifdef SC_DEBUG
			_debug( "use client ca from '%s'\n", ctx->client_ca );
#endif
			SSL_CTX_set_client_CA_list(
				ctx->ctx, SSL_load_client_CA_file( ctx->client_ca ) );
		}
		if( ctx->certificate != NULL ) {
			/* set the local certificate from CertFile */
#ifdef SC_DEBUG
			_debug( "use certificate from '%s'\n", ctx->certificate );
#endif
			r = SSL_CTX_use_certificate_file(
				ctx->ctx, ctx->certificate, SSL_FILETYPE_PEM );
			if( ! r )
				goto error;
		}
		if( ctx->private_key != NULL ) {
			/* set the private key from KeyFile */
#ifdef SC_DEBUG
			_debug( "use private key from '%s'\n", ctx->private_key );
#endif
			r = SSL_CTX_use_PrivateKey_file(
				ctx->ctx, ctx->private_key, SSL_FILETYPE_PEM );
			if( ! r )
				goto error;
		}
		/* set cipher list */
		if( ctx->cipher_list != NULL ) {
#ifdef SC_DEBUG
			_debug( "set cipher list '%s'\n", ctx->cipher_list );
#endif
			if( !SSL_CTX_set_cipher_list( ctx->ctx, ctx->cipher_list ) )
				goto error;
		}
		/* set auto retry */
		SSL_CTX_set_mode( ctx->ctx, SSL_MODE_AUTO_RETRY );
	}
	return SC_OK;
error:
	r = ERR_get_error();
	mod_sc->sc_set_error( ctx->socket, r, ERR_reason_error_string( r ) );
	return SC_ERROR;
}

/* internal functions */

void free_context( sc_ssl_ctx_t *ctx ) {
	/*
#ifdef SC_DEBUG
	_debug( "free ctx %u\n", ctx );
#endif
	*/
	if( ctx->ctx != NULL )
		SSL_CTX_free( ctx->ctx );
	Safefree( ctx->private_key );
	Safefree( ctx->certificate );
	Safefree( ctx->client_ca );
	Safefree( ctx->ca_file );
	Safefree( ctx->ca_path );
	Safefree( ctx );
}

int remove_context( sc_ssl_ctx_t *ctx ) {
	sc_ssl_ctx_t *cp = NULL, *cc;
	int i;
#ifdef USE_ITHREADS
	if( !sc_ssl_global.destroyed )
		MUTEX_LOCK( &sc_ssl_global.thread_lock );
#endif
	i = ctx->id & SC_SSL_CTX_CASCADE;
	cc = sc_ssl_global.ctx[i];
	while( cc != NULL ) {
		if( cc == ctx ) {
			if( cp == NULL )
				sc_ssl_global.ctx[i] = cc->next;
			else
				cp->next = cc->next;
			ctx = NULL;
			break;
		}
		cp = cc;
		cc = cc->next;
	}
#ifdef USE_ITHREADS
	if( !sc_ssl_global.destroyed )
		MUTEX_UNLOCK( &sc_ssl_global.thread_lock );
#endif
	if( ctx == NULL )
		return SC_OK;
	return SC_ERROR;
}

void free_userdata( void *p ) {
	userdata_t *ud = (userdata_t *) p;
	sc_ssl_ctx_t *ctx = ud->sc_ssl_ctx;
	if( ud->user_data != NULL && ud->free_user_data != NULL )
		ud->free_user_data( ud->user_data );
#ifdef SC_DEBUG
	_debug( "free userdata\n" );
#endif
	if( ud->ssl != NULL )
		SSL_free( ud->ssl );
	Safefree( ud->rcvbuf );
	Safefree( ud->buffer );
	//if( !sc_ssl_global.destroyed )
		mod_sc_ssl_ctx_destroy( ctx );
	Safefree( ud );
}

const char *my_ssl_error( int code ) {
	switch( code ) {
	case SSL_ERROR_NONE:
		return "No error";
	case SSL_ERROR_SSL:
		return "SSL library error, usually a protocol error";
	case SSL_ERROR_WANT_READ:
		return "The read operation did not complete";
	case SSL_ERROR_WANT_WRITE:
		return "The write operation did not complete";
	case SSL_ERROR_SYSCALL:
		return "Some I/O error occurred";
#ifdef SSL_ERROR_ZERO_RETURN
	case SSL_ERROR_ZERO_RETURN:
		return "The TLS/SSL connection has been closed";
#endif
#ifdef SSL_ERROR_WANT_X509_LOOKUP
	case SSL_ERROR_WANT_X509_LOOKUP:
		return "The operation did not complete because an application"
			" callback has asked to be called again";
#endif
#ifdef SSL_ERROR_WANT_CONNECT
	case SSL_ERROR_WANT_CONNECT:
		return "The connect operation did not complete";
#endif
#ifdef SSL_ERROR_WANT_ACCEPT
	case SSL_ERROR_WANT_ACCEPT:
		return "The accept operation did not complete";
#endif
	default:
		return "Unknown TLS/SSL error";
	}
}

char *my_strcpy( char *dst, const char *src ) {
	register char ch;
	while( 1 ) {
		if( (ch = *src ++) == '\0' ) {
			break;
		}
		*dst ++ = ch;
	}
	*dst = '\0';
	return dst;
}

int my_stricmp( const char *cs, const char *ct ) {
	register signed char res;
	while( 1 ) {
		if( (res = toupper( *cs ) - toupper( *ct ++ )) != 0 || ! *cs ++ )
			break;
	}
	return res;
}

#ifdef SC_DEBUG

int my_debug( const char *fmt, ... ) {
	va_list a;
	int r;
	size_t l;
	char *tmp;
	l = strlen( fmt );
	tmp = malloc( 64 + l );
	sprintf( tmp, "[Socket::Class::SSL] [%u] %s", PROCESS_ID(), fmt );
	va_start( a, fmt );
	r = vfprintf( stderr, tmp, a );
	fflush( stderr );
	va_end( a );
	free( tmp );
	return r;
}

#if SC_DEBUG > 1

HV					*hv_dbg_mem = NULL;
perl_mutex			dbg_mem_lock;
int					dbg_lock = FALSE;

void debug_init() {
	_debug( "init memory debugger\n" );
	MUTEX_INIT( &dbg_mem_lock );
	hv_dbg_mem = newHV();
	SvSHARE( (SV *) hv_dbg_mem );
	dbg_lock = TRUE;
}

void debug_free() {
	SV *sv_val;
	char *key, *val;
	I32 klen;
	STRLEN lval;
	_debug( "hv_dbg_mem entries %u\n", HvKEYS( hv_dbg_mem ) );
	if( HvKEYS( hv_dbg_mem ) ) {
		hv_iterinit( hv_dbg_mem );
		while( (sv_val = hv_iternextsv( hv_dbg_mem, &key, &klen )) != NULL ) {
			val = SvPV( sv_val, lval );
			_debug( "unfreed memory from %s\n", val );
		}
	}
	sv_2mortal( (SV *) hv_dbg_mem );
	dbg_lock = FALSE;
	MUTEX_DESTROY( &dbg_mem_lock );
}

#endif /* SC_DEBUG > 1 */

#endif /* SC_DEBUG */
