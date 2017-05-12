#include "socket_class.h"

sc_global_t sc_global;

INLINE void socket_class_add( socket_class_t *sc ) {
	int i;
	GLOBAL_LOCK();
	sc->id = ++sc_global.counter;
	sc->refcnt = 1;
#ifdef USE_ITHREADS
	sc->thread_id = THREAD_ID();
	sc->do_clone = TRUE;
#endif
	i = sc->id & SC_CASCADE;
#ifdef SC_DEBUG
	_debug( "add sc %lu cascade %lu\n", sc->id, i );
#endif
	sc->next = sc_global.socket[i];
	sc_global.socket[i] = sc;
	GLOBAL_UNLOCK();
}

INLINE void socket_class_free( socket_class_t *sc ) {
#ifdef SC_DEBUG
	_debug( "free sc %lu socket %d\n", sc->id, sc->sock );
#endif
	if( sc->user_data != NULL && sc->free_user_data != NULL )
		sc->free_user_data( sc->user_data );
	Socket_close( sc->sock );
	if( sc->s_domain == AF_UNIX ) {
		remove( ((struct sockaddr_un *) sc->l_addr.a)->sun_path );
	}
	Safefree( sc->buffer );
	Safefree( sc->classname );
	Safefree( sc );
}

INLINE void socket_class_rem( socket_class_t *sc ) {
	int i = sc->id & SC_CASCADE;
	socket_class_t *cc, *cp = NULL;
	GLOBAL_LOCK();
#ifdef SC_DEBUG
	_debug( "remove sc %lu\n", sc->id );
#endif
	cc = sc_global.socket[i];
	while( cc != NULL ) {
		if( cc == sc ) {
			if( cp == NULL )
				sc_global.socket[i] = cc->next;
			else
				cp->next = cc->next;
			break;
		}
		cp = cc;
		cc = cc->next;
	}
	GLOBAL_UNLOCK();
	socket_class_free( sc );
}

INLINE socket_class_t *socket_class_find( SV *sv ) {
	int i;
	socket_class_t *sc;
	u_long id;
	SV **psv;
	if( sc_global.destroyed )
		return NULL;
	if( ! SvROK( sv ) )
		return NULL;
	sv = SvRV( sv );
	if( SvTYPE( sv ) != SVt_PVHV )
		return NULL;
	psv = hv_fetch( (HV *) sv, "_sc_", 4, 0 );
	if( psv == NULL )
		return NULL;
	sv = *psv;
	if( !SvIOK( sv ) )
		return NULL;
	id = (int) SvIV( sv );
	i = id & SC_CASCADE;
	/*
#ifdef SC_DEBUG
	_debug( "search sc %d, cascade %d\n", id, cascade );
#endif
	*/
	GLOBAL_LOCK();
	for( sc = sc_global.socket[i]; sc != NULL; sc = sc->next ) {
		if( sc->id == id )
			goto found;
	}
#ifdef SC_DEBUG
	_debug( "sc %d NOT found\n", id );
#endif
found:
	GLOBAL_UNLOCK();
	return sc;
}

#ifdef _WIN32

#define ISEOL(c) ((c) == '\r' || (c) == '\n') 

INLINE void Socket_error( char *str, DWORD len, long num ) {
	char *s1;
	DWORD ret;
#ifdef SC_DEBUG
	int r1;
	r1 = _snprintf( str, len, "(%d) ", num );
	len -= r1;
	s1 = &str[r1];
#else
	s1 = str;
#endif
	ret = FormatMessage(
		FORMAT_MESSAGE_FROM_SYSTEM, 
		NULL,
		num,
		LANG_USER_DEFAULT, 
		s1,
		len,
		NULL
	);
	for( ; ret > 0, ISEOL( s1[ret - 1] ); ret -- )
		s1[ret - 1] = '\0';
}

INLINE int inet_aton( const char *cp, struct in_addr *inp ) {
	inp->s_addr = inet_addr( cp );
	return inp->s_addr == INADDR_NONE ? 0 : 1;
}

#else /* ! _WIN32 */

INLINE void Socket_error( char *str, DWORD len, long num ) {
	char *s1, *s2;
#ifdef SC_DEBUG
	int ret;
	ret = snprintf( str, len, "(%ld) ", num );
	len -= ret;
	s1 = &str[ret];
#else
	s1 = str;
#endif
	s2 = strerror( num );
	if( s2 != NULL )
		my_strncpy( s1, s2, len );
}

#endif /* ! _WIN32 */

INLINE void Socket_setaddr_UNIX( my_sockaddr_t *addr, const char *path ) {
	struct sockaddr_un *a = (struct sockaddr_un *) addr->a;
	addr->l = sizeof( struct sockaddr_un );
	a->sun_family = AF_UNIX;
	if( path != NULL )
		my_strncpy( a->sun_path, path, 100 );
}

INLINE int Socket_setaddr_INET(
	socket_class_t *sc, const char *host, const char *port, int use
) {
#ifndef SC_OLDNET
	struct addrinfo aih;
	struct addrinfo *ail = NULL;
	my_sockaddr_t *addr;
	int r;
	if( sc->s_domain == AF_BLUETOOTH )
		return Socket_setaddr_BTH( sc, host, port, use );
	memset( &aih, 0, sizeof( struct addrinfo ) );
	aih.ai_family = sc->s_domain;
	aih.ai_socktype = sc->s_type;
	aih.ai_protocol = sc->s_proto;
	if( use == ADDRUSE_LISTEN ) {
		aih.ai_flags = AI_PASSIVE;
		addr = &sc->l_addr;
		if( port == NULL || *port == '\0' )
			port = "0";
	}
	else {
		addr = &sc->r_addr;
		if( port == NULL )
			port = "";
	}
	r = getaddrinfo( host, port, &aih, &ail );
	if( r != 0 ) {
#ifdef SC_DEBUG
		_debug( "Socket_setaddr_INET getaddrinfo() failed %d\n", r );
#endif
#ifndef _WIN32
		SOCK_ERROR( sc, r, gai_strerror( r ) );
#else
		SOCK_ERRNO( sc, r );
#endif /* _WIN32 */
		return r;
	}
	addr->l = (socklen_t) ail->ai_addrlen;
	memcpy( addr->a, ail->ai_addr, ail->ai_addrlen );
	freeaddrinfo( ail );
#else /* SC_OLDNET */
	my_sockaddr_t *addr;
	if( sc->s_domain == AF_BLUETOOTH )
		return Socket_setaddr_BTH( sc, host, port, use );
	GLOBAL_LOCK();
	addr = (use == ADDRUSE_LISTEN) ? &sc->l_addr : &sc->r_addr;
	if( sc->s_domain == AF_INET ) {
		struct sockaddr_in *in = (struct sockaddr_in *) addr->a;
		addr->l = sizeof(struct sockaddr_in);
		in->sin_family = AF_INET;
		if( host == NULL && use != ADDRUSE_LISTEN )
			host = "127.0.0.0";
		if( host != NULL ) {
			if( host[0] == '\0' )
				in->sin_addr.s_addr = 0;
			if( host[0] >= '0' && host[0] <= '9' )
				in->sin_addr.s_addr = inet_addr( host );
			else {
				struct hostent *he;
				if( (he = gethostbyname( host )) == NULL )
					goto error;
				in->sin_addr = *(struct in_addr*) he->h_addr;
			}
		}
		if( port != NULL ) {
			if( port[0] == '\0' )
				in->sin_port = 0;
			else if( port[0] >= '0' && port[0] <= '9' )
				in->sin_port = htons( atoi( port ) );
			else {
				struct servent *se;
				if( (se = getservbyname( port, NULL )) == NULL )
					goto error;
				in->sin_port = se->s_port;
			}
		}
	}
	else {
		struct sockaddr_in6 *in6;
		addr->l = sizeof(struct sockaddr_in6);
		in6 = (struct sockaddr_in6 *) addr->a;
		in6->sin6_family = AF_INET6;
#ifndef _WIN32
		if( host != NULL ) {
			if( (*host >= '0' && *host <= '9') ||
				(*host >= 'A' && *host <= 'F') || *host == ':'
			) {
				if( inet_pton( AF_INET6, host, &in6->sin6_addr ) != 0 ) {
#ifdef SC_DEBUG
					_debug( "inet_pton failed %d\n", Socket_errno() );
#endif
					goto error;
				}
			}
			else {
				struct hostent *he;
				if( (he = gethostbyname( host )) == NULL )
					goto error;
				if( he->h_addrtype != AF_INET6 )
					goto error;
				Copy( he->h_addr, &in6->sin6_addr, he->h_length, char );
			}
		}
		if( port != NULL ) {
			if( port[0] == '\0' )
				in6->sin6_port = 0;
			else if( port[0] >= '0' && port[0] <= '9' )
				in6->sin6_port = htons( atol( port ) );
			else {
				struct servent *se;
				se = getservbyname( port, NULL );
				if( se == NULL )
					goto error;
				in6->sin6_port = se->s_port;
			}
		}
#endif /* ! _WIN32 */
	}
	goto exit;
error:
	GLOBAL_UNLOCK();
	SOCK_ERRNOLAST( sc );
	return sc->last_errno;
exit:
	GLOBAL_UNLOCK();
#endif /* SC_OLDNET */
	return 0;
}

INLINE int Socket_setaddr_BTH(
	socket_class_t *sc, const char *host, const char *port, int use
) {
	my_sockaddr_t *addr;
	SOCKADDR_RFCOMM *rca;
	SOCKADDR_L2CAP *l2a;

	if( use == ADDRUSE_LISTEN ) {
		addr = &sc->l_addr;
	}
	else {
		addr = &sc->r_addr;
	}
	switch( sc->s_proto ) {
	case BTPROTO_RFCOMM:
#ifdef SC_DEBUG
		_debug( "using BLUETOOTH RFCOMM host %s channel %s\n", host, port );
#endif
		addr->l = sizeof( SOCKADDR_RFCOMM );
		rca = (SOCKADDR_RFCOMM *) addr->a;
		rca->bt_family = AF_BLUETOOTH;
		if( host != NULL )
			my_str2ba( host, &rca->bt_bdaddr );
		if( port != NULL )
			rca->bt_port = (uint8_t) atol( port );
		if( ! rca->bt_port )
			rca->bt_port = 1;
		break;
	case BTPROTO_L2CAP:
#ifdef SC_DEBUG
		_debug( "using BLUETOOTH L2CAP host %s psm %s\n", host, port );
#endif
		addr->l = sizeof( SOCKADDR_L2CAP );
		l2a = (SOCKADDR_L2CAP *) addr->a;
		l2a->bt_family = AF_BLUETOOTH;
		if( host != NULL )
			my_str2ba( host, &l2a->bt_bdaddr );
		if( port != NULL )
			l2a->bt_port = (uint8_t) atol( port );
		break;
#ifdef SC_HAS_BLUETOOTH
	default:
		return bt_setaddr( sc, host, port, use );
#endif
	}
	return 0;
}

INLINE int Socket_domainbyname( const char *name ) {
	if( my_stricmp( name, "INET" ) == 0 ) {
		return AF_INET;
	}
	else if( my_stricmp( name, "INET6" ) == 0 ) {
		return AF_INET6;
	}
	else if( my_stricmp( name, "UNIX" ) == 0 ) {
		return AF_UNIX;
	}
	else if( my_stricmp( name, "BTH" ) == 0 ) {
		return AF_BLUETOOTH;
	}
	else if( my_stricmp( name, "BLUETOOTH" ) == 0 ) {
		return AF_BLUETOOTH;
	}
	else if( name[0] >= '0' && name[0] <= '9' ) {
		return atoi( name );
	}
	return AF_UNSPEC;
}

INLINE int Socket_typebyname( const char *name ) {
	if( my_stricmp( name, "STREAM" ) == 0 ) {
		return SOCK_STREAM;
	}
	else if( my_stricmp( name, "DGRAM" ) == 0 ) {
		return SOCK_DGRAM;
	}
	else if( my_stricmp( name, "RAW" ) == 0 ) {
		return SOCK_RAW;
	}
	else if( name[0] >= '0' && name[0] <= '9' ) {
		return atoi( name );
	}
	return 0;
}

INLINE int Socket_protobyname( const char *name ) {
	if( my_stricmp( name, "TCP" ) == 0 ) {
		return IPPROTO_TCP;
	}
	else if( my_stricmp( name, "UDP" ) == 0 ) {
		return IPPROTO_UDP;
	}
	else if( my_stricmp( name, "ICMP" ) == 0 ) {
		return IPPROTO_ICMP;
	}
	else if( my_stricmp( name, "RFCOMM" ) == 0 ) {
		return BTPROTO_RFCOMM;
	}
	else if( my_stricmp( name, "L2CAP" ) == 0 ) {
		return BTPROTO_L2CAP;
	}
	else if( name[0] >= '0' && name[0] <= '9' ) {
		return atoi( name );
	}
	else {
		struct protoent *pe;
		pe = getprotobyname( (char *) name );
		return pe != NULL ? pe->p_proto : 0;
	}
}

INLINE int Socket_setblocking( SOCKET s, int value ) {
#ifdef _WIN32
	int r;
	u_long val = (u_long) ! value;
	r = ioctlsocket( s, FIONBIO, &val );
#ifdef SC_DEBUG
	_debug( "ioctlsocket socket %u %d %d\n", s, r, Socket_errno() );
#endif
#else
	DWORD flags;
	int r;
	flags = fcntl( s, F_GETFL );
	if( ! value )
		r = fcntl( s, F_SETFL, flags | O_NONBLOCK );
	else
		r = fcntl( s, F_SETFL, flags & (~O_NONBLOCK) );
#ifdef SC_DEBUG
	_debug( "set blocking %u from %d to %d\n", s, ! (flags & O_NONBLOCK), value );
#endif
#endif
	return r;
}

INLINE int Socket_write( socket_class_t *sc, const char *buf, int len ) {
	int r;
	r = send( sc->sock, buf, len, 0 );
	if( r == SOCKET_ERROR ) {
		switch( r = Socket_errno() ) {
		case EWOULDBLOCK:
			/* threat not as an error */
			return 0;
		default:
			SOCK_ERRNO( sc, r );
			goto error;
		}
	}
	else if( r != 0 ) {
		return r;
	}
	SOCK_ERRNO( sc, ECONNRESET );
error:
#ifdef SC_DEBUG
	_debug( "write error %u\n", sc->last_errno );
#endif
	sc->state = SC_STATE_ERROR;
	return SOCKET_ERROR;
}


INLINE int my_ba2str( const bdaddr_t *ba, char *str ) {
	register const unsigned char *b = (const unsigned char *) ba;
	return sprintf( str,
		"%2.2X:%2.2X:%2.2X:%2.2X:%2.2X:%2.2X",
		b[5], b[4], b[3], b[2], b[1], b[0]
	);
}

INLINE int my_str2ba( const char *str, bdaddr_t *ba ) {
	register unsigned char *b = (unsigned char *) ba;
	const char *ptr = (str != NULL ? str : "00:00:00:00:00:00");
	int i;
	for( i = 0; i < 6; i ++ ) {
		b[5 - i] = (uint8_t) strtol( ptr, NULL, 16 );
		if( i != 5 && ! (ptr = strchr( ptr, ':' )) )
			ptr = ":00:00:00:00:00";
		ptr ++;
	}
	return 0;
}

const char *HEXTAB = "0123456789ABCDEF";

INLINE char *my_itoa( char *str, long value, int radix ) {
    char tmp[21], *ret = tmp, neg = 0;
	if( value < 0 ) {
		value = -value;
		neg = 1;
	}
	switch( radix ) {
	case 16:
		do {
			*ret ++ = HEXTAB[value % 16];
			value /= 16;
		} while( value > 0 );
		break;
	default:
		do {
			*ret ++ = (char) ((value % radix) + '0');
			value /= radix;
		} while( value > 0 );
		if( neg )
			*ret ++ = '-';
	}
	for( ret --; ret >= tmp; *str ++ = *ret, ret -- );
	*str = '\0';
	return str;
}

INLINE char *my_strncpy( char *dst, const char *src, size_t len ) {
	register char ch;
	for( ; len > 0; len -- ) {
		if( (ch = *src ++) == '\0' ) {
			*dst = '\0';
			return dst;
		}
		*dst ++ = ch;
	}
	*dst = '\0';
	return dst;
}

INLINE char *my_strcpy( char *dst, const char *src ) {
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

INLINE int my_stricmp( const char *cs, const char *ct ) {
	register signed char res;
	while( 1 ) {
		if( (res = toupper( *cs ) - toupper( *ct ++ )) != 0 || ! *cs ++ )
			break;
	}
	return res;
}

INLINE int my_snprintf_( char *str, size_t size, const char *format, ... ) {
	va_list va;
	int r;
	va_start( va, format );
#ifdef _WIN32
	r = _vsnprintf( str, size, format, va );
#else
	r = vsnprintf( str, size, format, va );
#endif
	va_end( va );
	return r;
}


#ifdef SC_DEBUG

INLINE int my_debug( const char *fmt, ... ) {
	va_list a;
	int r;
	size_t l;
	char *tmp;
	l = strlen( fmt );
	tmp = malloc( 64 + l );
	sprintf( tmp, "[Socket::Class] [%u] %s", PROCESS_ID(), fmt );
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
	I32 retlen;
	STRLEN lval;
	_debug( "hv_dbg_mem entries %u\n", HvKEYS( hv_dbg_mem ) );
	if( HvKEYS( hv_dbg_mem ) ) {
		hv_iterinit( hv_dbg_mem );
		while( (sv_val = hv_iternextsv( hv_dbg_mem, &key, &retlen )) != NULL ) {
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
