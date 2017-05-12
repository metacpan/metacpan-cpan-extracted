#include "socket_class.h"
#include "sc_mod_def.h"

MODULE = Socket::Class		PACKAGE = Socket::Class

#/*****************************************************************************
# * BOOT()
# *****************************************************************************/

BOOT:
{
	HV *stash;
#ifdef SC_DEBUG
	_debug( "INIT called\n" );
#endif
#if SC_DEBUG > 1
	debug_init();
#endif
#ifdef _WIN32
	{
		WSADATA wsaData;
		int iResult = WSAStartup( MAKEWORD(2,2), &wsaData );
		if( iResult != NO_ERROR )
			Perl_croak( aTHX_ "Error at WSAStartup()" );
	}
#endif
	Zero( &sc_global, 1, sc_global_t );
	sc_global.process_id = PROCESS_ID();
#ifdef USE_ITHREADS
	MUTEX_INIT( &sc_global.thread_lock );
#endif
	stash = gv_stashpvn( __PACKAGE__, (I32) sizeof(__PACKAGE__), FALSE );
#ifdef SC_OLDNET
	newCONSTSUB( stash, "OLDNET", newSViv( 1 ) );
#else
	newCONSTSUB( stash, "OLDNET", newSViv( 0 ) );
#endif
#ifdef SC_HAS_BLUETOOTH
	newCONSTSUB( stash, "BLUETOOTH", newSViv( 1 ) );
	boot_Socket__Class__BT();
#else
	newCONSTSUB( stash, "BLUETOOTH", newSViv( 0 ) );
#endif
	/* store the c module interface in the modglobal hash */
	(void) hv_store( PL_modglobal,
		"Socket::Class", 13, newSViv( PTR2IV( &mod_sc ) ), 0 );
}


#/*****************************************************************************
# * c_module()
# *****************************************************************************/
void
c_module( ... )
PPCODE:
	/* returns the c module interface */
	XSRETURN_IV( PTR2IV( &mod_sc ) );


#/*****************************************************************************
# * END()
# *****************************************************************************/

void
END( ... )
PREINIT:
	socket_class_t *sc1, *sc2;
	int i;
CODE:
	(void) items; /* avoid compiler warning */
	if( sc_global.destroyed || PROCESS_ID() != sc_global.process_id )
		return;
	sc_global.destroyed = 1;
#ifdef SC_DEBUG
	_debug( "END called\n" );
#endif
	GLOBAL_LOCK();
	for( i = 0; i <= SC_CASCADE; i ++ ) {
		sc1 = sc_global.socket[i];
		while( sc1 != NULL ) {
			sc2 = sc1->next;
			socket_class_free( sc1 );
			sc1 = sc2;
		}
		sc_global.socket[i] = NULL;
	}
	GLOBAL_UNLOCK();
#ifdef USE_ITHREADS
	MUTEX_DESTROY( &sc_global.thread_lock );
#endif
#ifdef _WIN32
	WSACleanup();
#endif
#if SC_DEBUG > 1
	debug_free();
#endif


#/*****************************************************************************
# * CLONE()
# *****************************************************************************/

#ifdef USE_ITHREADS

void
CLONE( ... )
PREINIT:
	socket_class_t *sc;
	int i;
PPCODE:
	GLOBAL_LOCK();
	for( i = 0; i <= SC_CASCADE; i ++ ) {
		for( sc = sc_global.socket[i]; sc != NULL; sc = sc->next ) {
			if( sc->do_clone )
				sc->refcnt ++;
#ifdef SC_DEBUG
			_debug( "CLONE called for sc %lu refcnt: %d\n", sc->id, sc->refcnt );
#endif
		}
	}
	GLOBAL_UNLOCK();

#endif


#/*****************************************************************************
# * DESTROY( this )
# *****************************************************************************/

void
DESTROY( this, ... )
	SV *this;
PREINIT:
	socket_class_t *sc;
PPCODE:
	if( (sc = mod_sc_get_socket( this )) == NULL )
		XSRETURN_EMPTY;
#ifdef SC_DEBUG
	_debug( "DESTROY called for sc %lu refcnt: %d\n", sc->id, sc->refcnt - 1 );
#endif
#ifdef USE_ITHREADS
	if( sc->do_clone && sc->thread_id == THREAD_ID() ) {
		sc->do_clone = FALSE;
#ifdef SC_DEBUG
		_debug( "Disabled futher CLONE for sc %lu\n", sc->id );
#endif
	}
#endif
	mod_sc_refcnt_dec( sc );


#/*****************************************************************************
# * new( class )
# *****************************************************************************/

void
new( class, ... )
	SV *class;
PREINIT:
	socket_class_t *sc;
	char **args;
	int argc = 0, r, i;
	SV *sv;
PPCODE:
	Newx( args, items - 1, char * );
	/* read options */
	for( i = 1; i < items - 1; ) {
		args[argc ++] = SvPV_nolen( ST(i) );
		i ++;
		args[argc ++] = SvPV_nolen( ST(i) );
		i ++;
	}
	r = mod_sc_create( args, argc, &sc );
	Safefree( args );
	if( r != SC_OK )
		XSRETURN_EMPTY;
	/* create the class */
	r = mod_sc_create_class( sc, SvPV_nolen( class ), &sv );
	if( r != SC_OK ) {
		mod_sc_set_error( NULL, sc->last_errno, sc->last_error );
		mod_sc_destroy( sc );
		XSRETURN_EMPTY;
	}
	ST(0) = sv_2mortal( sv );
	XSRETURN(1);


#/*****************************************************************************
# * connect( this )
# *****************************************************************************/

void
connect( this, ... )
	SV *this;
PREINIT:
	socket_class_t *sc;
	const char *s1 = NULL, *s2 = NULL;
	double ms = 0;
PPCODE:
	if( (sc = mod_sc_get_socket( this )) == NULL )
		XSRETURN_EMPTY;
	switch( sc->s_domain ) {
	case AF_INET:
	case AF_INET6:
	default:
		switch( items ) {
		case 4:
		default:
			if( SvNOK( ST(3) ) || SvIOK( ST(3) ) )
				ms = SvNV( ST(3) );
		case 3:
			s1 = SvPV_nolen( ST(1) );
			s2 = SvPV_nolen( ST(2) );
			break;
		case 2:
			s1 = SvPV_nolen( ST(1) );
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
			s1 = SvPV_nolen( ST(1) );
			break;
		}
		break;
	}
	if( mod_sc_connect( sc, s1, s2, ms ) != SC_OK )
		XSRETURN_EMPTY;
	XSRETURN_YES;


#/*****************************************************************************
# * free( this )
# *****************************************************************************/

void
free( this )
	SV *this;
PREINIT:
	socket_class_t *sc;
PPCODE:
	if( (sc = mod_sc_get_socket( this )) == NULL )
		XSRETURN_EMPTY;
	mod_sc_destroy( sc );
	XSRETURN_YES;


#/*****************************************************************************
# * close( this )
# *****************************************************************************/

void
close( this )
	SV *this;
PREINIT:
	socket_class_t *sc;
PPCODE:
	if( (sc = socket_class_find( this )) == NULL )
		XSRETURN_EMPTY;
	if( mod_sc_close( sc ) != SC_OK )
		XSRETURN_EMPTY;
	XSRETURN_YES;


#/*****************************************************************************
# * shutdown( this )
# *****************************************************************************/

void
shutdown( this, how = 0 )
	SV *this;
	int how
PREINIT:
	socket_class_t *sc;
PPCODE:
	if( (sc = socket_class_find( this )) == NULL )
		XSRETURN_EMPTY;
	if( mod_sc_shutdown( sc, how ) != SC_OK )
		XSRETURN_EMPTY;
	XSRETURN_YES;


#/*****************************************************************************
# * bind( this )
# *****************************************************************************/

void
bind( this, addr = NULL, port = NULL )
	SV *this;
	char *addr;
	char *port;
PREINIT:
	socket_class_t *sc;
PPCODE:
	if( (sc = mod_sc_get_socket( this )) == NULL )
		XSRETURN_EMPTY;
	if( mod_sc_bind( sc, addr, port ) != SC_OK )
		XSRETURN_EMPTY;
	XSRETURN_YES;


#/*****************************************************************************
# * listen( this )
# *****************************************************************************/

void
listen( this, queue = SOMAXCONN )
	SV *this;
	int queue;
PREINIT:
	socket_class_t *sc;
PPCODE:
	if( (sc = mod_sc_get_socket( this )) == NULL )
		XSRETURN_EMPTY;
	if( mod_sc_listen( sc, queue < 0 ? SOMAXCONN : queue ) != SC_OK )
		XSRETURN_EMPTY;
	XSRETURN_YES;


#/*****************************************************************************
# * accept( this )
# *****************************************************************************/

void
accept( this, pkg = NULL )
	SV *this;
	char *pkg;
PREINIT:
	socket_class_t *sc, *sc2;
	SV *sv;
PPCODE:
	if( (sc = mod_sc_get_socket( this )) == NULL )
		XSRETURN_EMPTY;
	if( mod_sc_accept( sc, &sc2 ) != SC_OK )
		XSRETURN_EMPTY;
	if( sc2 == NULL )
		XSRETURN_NO;
	if( mod_sc_create_class( sc2, pkg, &sv ) != SC_OK ) {
		mod_sc_destroy( sc2 );
		XSRETURN_EMPTY;
	}
	ST(0) = sv_2mortal( sv );
	XSRETURN(1);


#/*****************************************************************************
# * recv( this, buf, len [, flags] )
# *****************************************************************************/

void
recv( this, buf, len, flags = 0 )
	SV *this;
	SV *buf;
	unsigned int len;
	unsigned int flags;
PREINIT:
	socket_class_t *sc;
	int rlen;
PPCODE:
	if( (sc = mod_sc_get_socket( this )) == NULL )
		XSRETURN_EMPTY;
	if( sc->buffer_len < len ) {
		sc->buffer_len = len;
		Renew( sc->buffer, len, char );
	}
	if( mod_sc_recv( sc, sc->buffer, len, flags, &rlen ) != SC_OK )
		XSRETURN_EMPTY;
	if( rlen == 0 )
		XSRETURN_NO;
	sv_setpvn( buf, sc->buffer, rlen );
	XSRETURN_IV( rlen );


#/*****************************************************************************
# * send( this, buf [, flags] )
# *****************************************************************************/

void
send( this, buf, flags = 0 )
	SV *this;
	SV *buf;
	unsigned int flags;
PREINIT:
	socket_class_t *sc;
	const char *msg;
	STRLEN len;
	int rlen;
PPCODE:
	if( (sc = mod_sc_get_socket( this )) == NULL )
		XSRETURN_EMPTY;
	msg = SvPV( buf, len );
	if( mod_sc_send( sc, msg, (int) len, flags, &rlen ) != SC_OK )
		XSRETURN_EMPTY;
	if( rlen == 0 )
		XSRETURN_NO;
	XSRETURN_IV( rlen );


#/*****************************************************************************
# * recvfrom( this, buf, len [, flags] )
# *****************************************************************************/

void
recvfrom( this, buf, len, flags = 0 )
	SV *this;
	SV *buf;
	size_t len;
	unsigned int flags;
PREINIT:
	socket_class_t *sc;
	int rlen;
PPCODE:
	if( (sc = mod_sc_get_socket( this )) == NULL )
		XSRETURN_EMPTY;
	if( sc->buffer_len < len ) {
		sc->buffer_len = len;
		Renew( sc->buffer, len, char );
	}
	if( mod_sc_recvfrom( sc, sc->buffer, (int) len, flags, &rlen ) != SC_OK )
		XSRETURN_EMPTY;
	if( rlen == 0 )
		XSRETURN_NO;
	sv_setpvn( buf, sc->buffer, rlen );
	ST(0) = sv_2mortal( newSVpvn(
		(char *) &sc->r_addr, SC_ADDR_SIZE( sc->r_addr ) ) );
	XSRETURN(1);


#/*****************************************************************************
# * sendto( this, buf [, to [, flags]] )
# *****************************************************************************/

void
sendto( this, buf, to = NULL, flags = 0 )
	SV *this;
	SV *buf;
	SV *to;
	unsigned int flags;
PREINIT:
	socket_class_t *sc;
	const char *msg;
	STRLEN len;
	sc_addr_t *peer = NULL;
	int rlen;
PPCODE:
	if( (sc = mod_sc_get_socket( this )) == NULL )
		XSRETURN_EMPTY;
	if( to != NULL && SvPOK( to ) ) {
		peer = (my_sockaddr_t *) SvPVbyte( to, len );
		if( len < sizeof( int ) || len != SC_ADDR_SIZE(*peer) ) {
			my_snprintf_(
				sc->last_error, sizeof( sc->last_error ),
				"Invalid address"
			);
			XSRETURN_EMPTY;
		}
	}
	msg = SvPV( buf, len );
	if( mod_sc_sendto( sc, msg, (int) len, flags, peer, &rlen ) != SC_OK )
		XSRETURN_EMPTY;
	if( rlen == 0 )
		XSRETURN_NO;
	XSRETURN_IV( rlen );


#/*****************************************************************************
# * read( this, buf, len )
# *****************************************************************************/

void
read( this, buf, len )
	SV *this;
	SV *buf;
	unsigned int len;
PREINIT:
	socket_class_t *sc;
	int rlen;
PPCODE:
	if( (sc = mod_sc_get_socket( this )) == NULL )
		XSRETURN_EMPTY;
	if( sc->buffer_len < len ) {
		sc->buffer_len = len;
		Renew( sc->buffer, len, char );
	}
	if( mod_sc_read( sc, sc->buffer, len, &rlen ) != SC_OK )
		XSRETURN_EMPTY;
	if( rlen == 0 )
		XSRETURN_NO;
	sv_setpvn( buf, sc->buffer, rlen );
	XSRETURN_IV( rlen );


#/*****************************************************************************
# * write( this, buf [, start [, length]] )
# *****************************************************************************/

void
write( this, buf, ... )
	SV *this;
	SV *buf;
PREINIT:
	socket_class_t *sc;
	const char *msg;
	STRLEN l1;
	int start = 0, len, max, l2;
PPCODE:
	if( (sc = mod_sc_get_socket( this )) == NULL )
		XSRETURN_EMPTY;
	msg = SvPVx( buf, l1 );
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
	if( mod_sc_write( sc, msg + start, len, &len ) != SC_OK )
		XSRETURN_EMPTY;
	if( len == 0 )
		XSRETURN_NO;
	XSRETURN_IV( len );


#/*****************************************************************************
# * readline( this [, separator [, maxsize]] )
# *****************************************************************************/

void
readline( this, separator = NULL, maxsize = 0 )
	SV *this;
	char *separator;
	int maxsize;
PREINIT:
	socket_class_t *sc;
	int rlen, r;
	char *rbuf;
PPCODE:
	if( (sc = mod_sc_get_socket( this )) == NULL )
		XSRETURN_EMPTY;
	if( separator != NULL ) {
		r = mod_sc_read_packet(
			sc, separator, (size_t) maxsize, &rbuf, &rlen );
		if( r != SC_OK )
			XSRETURN_EMPTY;
	}
	else {
		if( mod_sc_readline( sc, &rbuf, &rlen ) != SC_OK )
			XSRETURN_EMPTY;
	}
	ST(0) = sv_2mortal( newSVpvn( rbuf, rlen ) );
	XSRETURN(1);


#/*****************************************************************************
# * writeline( this, buf )
# *****************************************************************************/

void
writeline( this, buf )
	SV *this;
	SV *buf;
PREINIT:
	socket_class_t *sc;
	const char *msg;
	STRLEN len;
	int rlen;
PPCODE:
	if( (sc = mod_sc_get_socket( this )) == NULL )
		XSRETURN_EMPTY;
	msg = SvPVx( buf, len );
	if( mod_sc_writeln( sc, msg, (int) len, &rlen ) != SC_OK )
		XSRETURN_EMPTY;
	if( rlen == 0 )
		XSRETURN_NO;
	XSRETURN_IV( rlen );


#/*****************************************************************************
# * print( this )
# *****************************************************************************/

void
print( this, ... )
	SV *this;
PREINIT:
	socket_class_t *sc;
	const char *s1;
	char *tmp = NULL;
	STRLEN l1, len = 0, pos = 0;
	int r, rlen;
PPCODE:
	if( (sc = mod_sc_get_socket( this )) == NULL )
		XSRETURN_EMPTY;
	for( r = 1; r < items; r ++ ) {
		if( ! SvOK( ST(r) ) )
			continue;
		s1 = SvPV( ST(r), l1 );
		if( pos + l1 > len ) {
			len = pos + l1 + 64;
			Renew( tmp, len, char );
		}
		Copy( s1, tmp + pos, l1, char );
		pos += l1;
	}
	if( tmp != NULL ) {
		r = mod_sc_write( sc, tmp, (int) pos, &rlen );
		Safefree( tmp );
		if( r != SC_OK )
			XSRETURN_EMPTY;
		if( rlen == 0 )
			XSRETURN_NO;
		XSRETURN_IV( rlen );
	}


#/*****************************************************************************
# * read_packet( this, separator [, maxsize]] )
# *****************************************************************************/

void
read_packet( this, separator, maxsize = 0 )
	SV *this;
	char *separator;
	int maxsize;
PREINIT:
	socket_class_t *sc;
	int rlen, r;
	char *rbuf;
PPCODE:
	if( (sc = mod_sc_get_socket( this )) == NULL )
		XSRETURN_EMPTY;
	r = mod_sc_read_packet( sc, separator, (size_t) maxsize, &rbuf, &rlen );
	if( r != SC_OK )
		XSRETURN_EMPTY;
	ST(0) = sv_2mortal( newSVpvn( rbuf, rlen ) );
	XSRETURN(1);


#/*****************************************************************************
# * available( this )
# *****************************************************************************/

void
available( this )
	SV *this;
PREINIT:
	socket_class_t *sc;
	int len;
PPCODE:
	if( (sc = mod_sc_get_socket( this )) == NULL )
		XSRETURN_EMPTY;
	if( mod_sc_available( sc, &len ) != SC_OK )
		XSRETURN_EMPTY;
	XSRETURN_IV( (IV) len );


#/*****************************************************************************
# * pack_addr( this, addr [, port] )
# *****************************************************************************/

void
pack_addr( this, addr, ... )
	SV *this;
	SV *addr;
PREINIT:
	socket_class_t *sc;
	my_sockaddr_t saddr;
	char *s1, *s2;
PPCODE:
	if( (sc = mod_sc_get_socket( this )) == NULL )
		XSRETURN_EMPTY;
	s1 = SvPV_nolen( addr );
	if( items > 2 )
		s2 = SvPV_nolen( ST(2) );
	else
		s2 = NULL;
	if( mod_sc_pack_addr( sc, s1, s2, &saddr ) != SC_OK )
		XSRETURN_EMPTY;
	ST(0) = sv_2mortal( newSVpvn( (char *) &saddr, SC_ADDR_SIZE(saddr) ) );
	XSRETURN(1);


#/*****************************************************************************
# * unpack_addr( this, paddr )
# *****************************************************************************/

void
unpack_addr( this, paddr )
	SV *this;
	SV *paddr;
PREINIT:
	socket_class_t *sc;
	my_sockaddr_t *saddr;
	STRLEN len;
	char addr[NI_MAXHOST], port[NI_MAXSERV];
	int addr_len = NI_MAXHOST, port_len = NI_MAXSERV, r;
PPCODE:
	if( (sc = mod_sc_get_socket( this )) == NULL )
		XSRETURN_EMPTY;
	saddr = (my_sockaddr_t *) SvPVbyte( paddr, len );
	if( len < sizeof( int ) || len != SC_ADDR_SIZE(*saddr) ) {
		my_snprintf_(
			sc->last_error, sizeof( sc->last_error ),
			"Invalid address"
		);
		XSRETURN_EMPTY;
	}
	r = mod_sc_unpack_addr( sc, saddr, addr, &addr_len, port, &port_len );
	if( r != SC_OK )
		XSRETURN_EMPTY;
	XPUSHs( sv_2mortal( newSVpvn( addr, addr_len ) ) );
	if( GIMME_V == G_ARRAY && port_len ) {
		XPUSHs( sv_2mortal( newSVpvn( port, port_len ) ) );
	}
	

#/*****************************************************************************
# * get_hostname( this, addr )
# *****************************************************************************/

void
get_hostname( this, addr = NULL )
	SV *this;
	SV *addr;
PREINIT:
	socket_class_t *sc;
	my_sockaddr_t *saddr, sa2;
	const char *s1 = NULL;
	STRLEN l1;
	char host[NI_MAXHOST];
	int host_len = NI_MAXHOST;
PPCODE:
	if( (sc = mod_sc_get_socket( this )) == NULL )
		XSRETURN_EMPTY;
	if( addr != NULL ) {
		s1 = SvPV( addr, l1 );
		saddr = (my_sockaddr_t *) s1;
		if( l1 <= sizeof( int ) || l1 != SC_ADDR_SIZE(*saddr) ) {
			if( mod_sc_pack_addr( sc, s1, NULL, &sa2 ) != SC_OK )
				XSRETURN_EMPTY;
			saddr = &sa2;
		}
	}
	else {
		saddr = &sc->r_addr;
	}
	if( mod_sc_gethostbyaddr( sc, saddr, host, &host_len ) != SC_OK )
		XSRETURN_EMPTY;
	ST(0) = sv_2mortal( newSVpvn( host, host_len ) );
	XSRETURN(1);


#/*****************************************************************************
# * get_hostaddr( this, name )
# *****************************************************************************/

void
get_hostaddr( this, name )
	SV *this;
	SV *name;
PREINIT:
	socket_class_t *sc;
	char addr[40];
	int addr_len = 40, r;
PPCODE:
	if( (sc = mod_sc_get_socket( this )) == NULL )
		XSRETURN_EMPTY;
	r = mod_sc_gethostbyname( sc, SvPV_nolen( name ), addr, &addr_len );
	if( r != SC_OK )
		XSRETURN_EMPTY;
	ST(0) = sv_2mortal( newSVpvn( addr, addr_len ) );
	XSRETURN(1);


#/*****************************************************************************
# * getaddrinfo( this, node, service [, family [, proto [, type [, flags ]]]] )
# *****************************************************************************/

void
getaddrinfo( ... )
PREINIT:
	socket_class_t *sc = NULL;
	int ipos = 0, r;
	sc_addrinfo_t aih;
	sc_addrinfo_t *ail = NULL, *ai;
	const char *host, *service;
	HV *hv;
	char tmp[40];
	my_sockaddr_t saddr;
PPCODE:
	if( items > 0 ) {
		if( (sc = mod_sc_get_socket( ST(0) )) != NULL ) {
			ipos ++;
		}
		else if(
			SvPOK( ST(0) ) &&
			strcmp( SvPV_nolen( ST(0) ), __PACKAGE__ ) == 0
		) {
			ipos ++;
		}
	}
	if( items - ipos < 1 )
		Perl_croak( aTHX_ "Usage: Socket::Class::getaddrinfo(node, ...)" );
	if( SvOK( ST(ipos) ) )
		host = SvPV_nolen( ST(ipos) );
	else
		host = NULL;
	ipos ++;
	if( ipos < items && SvOK( ST(ipos) ) )
		service = SvPV_nolen( ST(ipos) );
	else
		service = "";
	ipos ++;
	memset( &aih, 0, sizeof(sc_addrinfo_t) );
	if( ipos < items ) {
		if( SvIOK( ST(ipos) ) )
			aih.ai_family = (int) SvIV( ST(ipos) );
		else
			aih.ai_family = Socket_domainbyname( SvPV_nolen( ST(ipos) ) );
#ifdef SC_DEBUG
		_debug( "using family %d\n", aih.ai_family );
#endif
		ipos ++;
	}
	if( ipos < items ) {
		if( SvIOK( ST(ipos) ) )
			aih.ai_protocol = (int) SvIV( ST(ipos) );
		else
			aih.ai_protocol = Socket_protobyname( SvPV_nolen( ST(ipos) ) );
#ifdef SC_DEBUG
		_debug( "using protocol %d\n", aih.ai_protocol );
#endif
		ipos ++;
	}
	if( ipos < items ) {
		if( SvIOK( ST(ipos) ) )
			aih.ai_socktype = (int) SvIV( ST(ipos) );
		else
			aih.ai_socktype = Socket_typebyname( SvPV_nolen( ST(ipos) ) );
#ifdef SC_DEBUG
		_debug( "using socktype %d\n", aih.ai_socktype );
#endif
		ipos ++;
	}
#if defined __MVS__ && defined AI_ALL
	/* set AI_ALL on OS390 as default flag */
	if( aih.ai_family == AF_UNSPEC )
		aih.ai_flags = AI_ALL;
#endif
	if( ipos < items ) {
		aih.ai_flags = (int) SvIV( ST(ipos) );
		ipos ++;
	}
	if( mod_sc_getaddrinfo( sc, host, service, &aih, &ail ) != SC_OK )
		XSRETURN_EMPTY;
	for( ai = ail; ai != NULL; ai = ai->ai_next ) {
		hv = (HV *) sv_2mortal( (SV *) newHV() );
		(void) hv_store( hv, "family", 6, newSViv( ai->ai_family ), 0 );
		(void) hv_store( hv, "protocol", 8, newSViv( ai->ai_protocol ), 0 );
		(void) hv_store( hv, "socktype", 8, newSViv( ai->ai_socktype ), 0 );
		saddr.l = (socklen_t) ai->ai_addrlen;
		memcpy( saddr.a, ai->ai_addr, ai->ai_addrlen );
		(void) hv_store( hv,
			"paddr", 5, newSVpvn( (char *) &saddr, SC_ADDR_SIZE(saddr) ), 0 );
		if( ai->ai_cnamelen )
			(void) hv_store( hv, "canonname", 9,
				newSVpvn( ai->ai_canonname, ai->ai_cnamelen ), 0 );
		/* familyname */
		switch( ai->ai_family ) {
		case AF_INET:
			(void) hv_store( hv, "familyname", 10, newSVpvn( "INET", 4 ), 0 );
			r = ntohl( ((struct sockaddr_in *) ai->ai_addr )->sin_addr.s_addr );
			r = sprintf( tmp, "%u.%u.%u.%u", IP4( r ) );
			(void) hv_store( hv, "addr", 4, newSVpvn( tmp, r ), 0 );
			(void) hv_store( hv, "port", 4, newSViv(
				ntohs( ((struct sockaddr_in *) ai->ai_addr )->sin_port ) ), 0 );
			break;
		case AF_INET6:
			(void) hv_store( hv, "familyname", 10, newSVpvn( "INET6", 5 ), 0 );
			r = sprintf( tmp, "%04x:%04x:%04x:%04x:%04x:%04x:%04x:%04x",
				IP6( (uint16_t *) &((struct sockaddr_in6 *) ai->ai_addr)->sin6_addr )
			);
			(void) hv_store( hv, "addr", 4, newSVpv( tmp, r ), 0 );
			(void) hv_store( hv, "port", 4, newSViv(
				ntohs( ((struct sockaddr_in6 *) ai->ai_addr)->sin6_port ) ), 0 );
			break;
		case AF_UNIX:
			(void) hv_store( hv, "familyname", 10, newSVpvn( "UNIX", 4 ), 0 );
			(void) hv_store( hv, "path", 4, newSVpv(
				((struct sockaddr_un *) ai->ai_addr)->sun_path, 0 ), 0 );
			break;
		case AF_BLUETOOTH:
			(void) hv_store( hv, "familyname", 10, newSVpvn( "BTH", 3 ), 0 );
			if( ai->ai_protocol == BTPROTO_L2CAP ) {
				r = my_ba2str(
					&((SOCKADDR_L2CAP *) ai->ai_addr)->bt_bdaddr, tmp );
				(void) hv_store( hv, "addr", 4, newSVpv( tmp, r ), 0 );
				(void) hv_store( hv, "port", 4,
					newSViv( ((SOCKADDR_L2CAP *) ai->ai_addr)->bt_port ), 0 );
			}
			break;
		}
		/* sockname */
		switch( ai->ai_socktype ) {
		case SOCK_STREAM:
			(void) hv_store( hv, "sockname", 8, newSVpvn( "STREAM", 6 ), 0 );
			break;
		case SOCK_DGRAM:
			(void) hv_store( hv, "sockname", 8, newSVpvn( "DGRAM", 5 ), 0 );
			break;
		case SOCK_RAW:
			(void) hv_store( hv, "sockname", 8, newSVpvn( "RAW", 3 ), 0 );
			break;
		case SOCK_RDM:
			(void) hv_store( hv, "sockname", 8, newSVpvn( "RDM", 3 ), 0 );
			break;
		case SOCK_SEQPACKET:
			(void) hv_store( hv, "sockname", 8, newSVpvn( "SEQPACKET", 9 ), 0 );
			break;
		}
		/* protoname */
		switch( ai->ai_family ) {
		case AF_INET:
		case AF_INET6:
			switch( ai->ai_protocol ) {
			case IPPROTO_TCP:
				(void) hv_store( hv, "protoname", 9, newSVpvn( "TCP", 3 ), 0 );
				break;
			case IPPROTO_UDP:
				(void) hv_store( hv, "protoname", 9, newSVpvn( "UDP", 3 ), 0 );
				break;
			case IPPROTO_ICMP:
				(void) hv_store( hv, "protoname", 9, newSVpvn( "ICMP", 4 ), 0 );
				break;
			}
			break;
		case AF_BLUETOOTH:
			switch( ai->ai_protocol ) {
			case BTPROTO_RFCOMM:
				(void) hv_store( hv, "protoname", 9, newSVpvn( "RFCOMM", 6 ), 0 );
				break;
			case BTPROTO_L2CAP:
				(void) hv_store( hv, "protoname", 9, newSVpvn( "L2CAP", 5 ), 0 );
				break;
			}
			break;
		}
		XPUSHs( sv_2mortal( newRV( (SV *) hv ) ) );
	}
	mod_sc_freeaddrinfo( ail );


#/*****************************************************************************
# * getnameinfo( this, addr, port, family, flags )
# *****************************************************************************/

void
getnameinfo( ... )
PREINIT:
	socket_class_t *sc = NULL;
	int ipos = 0, r, family = AF_UNSPEC, flags = 0;
	char host[NI_MAXHOST], serv[NI_MAXSERV], *addr, *port = "";
	my_sockaddr_t saddr, *psaddr;
	sc_addrinfo_t aih, *ail = NULL;
	STRLEN len;
PPCODE:
	if( items > 0 ) {
		if( (sc = mod_sc_get_socket( ST(0) )) != NULL ) {
			ipos ++;
		}
		else if(
			SvPOK( ST(0) ) &&
			strcmp( SvPV_nolen( ST(0) ), __PACKAGE__ ) == 0
		) {
			ipos ++;
		}
	}
	if( items - ipos < 1 )
		Perl_croak( aTHX_ "Usage: Socket::Class::getnameinfo(addr, ...)" );
	psaddr = (my_sockaddr_t *) SvPVbyte( ST(ipos), len );
	if( len > sizeof( int ) && len == SC_ADDR_SIZE(*psaddr) ) {
		/* packed address */
		ipos ++;
		if( ipos < items ) {
			flags = (int) SvIV( ST(ipos) );
			ipos ++;
		}
	}
	else {
		addr = SvPV_nolen( ST(ipos) );
		ipos ++;
		if( ipos < items ) {
			port = SvPV_nolen( ST(ipos) );
			ipos ++;
		}
		if( ipos < items ) {
			if( SvIOK( ST(ipos) ) )
				family = (int) SvIV( ST(ipos) );
			else
				family = Socket_domainbyname( SvPV_nolen( ST(ipos) ) );
			ipos ++;
		}
		if( ipos < items ) {
			flags = (int) SvIV( ST(ipos) );
			ipos ++;
		}
		memset( &aih, 0, sizeof( sc_addrinfo_t ) );
		aih.ai_family = family;
		if( mod_sc_getaddrinfo( sc, addr, port, &aih, &ail ) != SC_OK )
			XSRETURN_EMPTY;
		saddr.l = (socklen_t) ail->ai_addrlen;
		memcpy( saddr.a, ail->ai_addr, ail->ai_addrlen );
		mod_sc_freeaddrinfo( ail );
		psaddr = &saddr;
	}
	r = mod_sc_getnameinfo(
		sc, psaddr, host, sizeof( host ), serv, sizeof( serv ), flags );
	if( r != SC_OK )
		XSRETURN_EMPTY;
	ST(0) = sv_2mortal( newSVpvn( host, strlen( host ) ) );
	if( GIMME_V != G_ARRAY )
		XSRETURN(1);
	ST(1) = sv_2mortal( newSVpvn( serv, strlen( serv ) ) );
	XSRETURN(2);


#/*****************************************************************************
# * set_blocking( this [, bool] )
# *****************************************************************************/

void
set_blocking( this, mode = 1 )
	SV *this;
	int mode;
PREINIT:
	socket_class_t *sc;
PPCODE:
	if( (sc = mod_sc_get_socket( this )) == NULL )
		XSRETURN_EMPTY;
	if( mod_sc_set_blocking( sc, mode ) != SC_OK )
		XSRETURN_EMPTY;
	XSRETURN_YES;


#/*****************************************************************************
# * get_blocking( this )
# *****************************************************************************/

void
get_blocking( this )
	SV *this;
PREINIT:
	socket_class_t *sc;
	int mode;
PPCODE:
	if( (sc = mod_sc_get_socket( this )) == NULL )
		XSRETURN_EMPTY;
	if( mod_sc_get_blocking( sc, &mode ) != SC_OK )
		XSRETURN_EMPTY;
	XSRETURN_IV( mode );


#/*****************************************************************************
# * set_reuseaddr( this [, bool] )
# *****************************************************************************/

void
set_reuseaddr( this, mode = 1 )
	SV *this;
	int mode;
PREINIT:
	socket_class_t *sc;
PPCODE:
	if( (sc = mod_sc_get_socket( this )) == NULL )
		XSRETURN_EMPTY;
	if( mod_sc_set_reuseaddr( sc, mode ) != SC_OK )
		XSRETURN_EMPTY;
	XSRETURN_YES;


#/*****************************************************************************
# * get_reuseaddr( this )
# *****************************************************************************/

void
get_reuseaddr( this )
	SV *this;
PREINIT:
	socket_class_t *sc;
	int mode;
PPCODE:
	if( (sc = mod_sc_get_socket( this )) == NULL )
		XSRETURN_EMPTY;
	if( mod_sc_get_reuseaddr( sc, &mode ) != SC_OK )
		XSRETURN_EMPTY;
	XSRETURN_IV( mode );


#/*****************************************************************************
# * set_broadcast( this [, bool] )
# *****************************************************************************/

void
set_broadcast( this, mode = 1 )
	SV *this;
	int mode;
PREINIT:
	socket_class_t *sc;
PPCODE:
	if( (sc = mod_sc_get_socket( this )) == NULL )
		XSRETURN_EMPTY;
	if( mod_sc_set_broadcast( sc, mode ) != SC_OK )
		XSRETURN_EMPTY;
	XSRETURN_YES;


#/*****************************************************************************
# * get_broadcast( this )
# *****************************************************************************/

void
get_broadcast( this )
	SV *this;
PREINIT:
	socket_class_t *sc;
	int mode;
PPCODE:
	if( (sc = mod_sc_get_socket( this )) == NULL )
		XSRETURN_EMPTY;
	if( mod_sc_get_broadcast( sc, &mode ) != SC_OK )
		XSRETURN_EMPTY;
	XSRETURN_IV( mode );


#/*****************************************************************************
# * set_rcvbuf_size( this, size )
# *****************************************************************************/

void
set_rcvbuf_size( this, size )
	SV *this;
	int size;
PREINIT:
	socket_class_t *sc;
PPCODE:
	if( (sc = mod_sc_get_socket( this )) == NULL )
		XSRETURN_EMPTY;
	if( mod_sc_set_rcvbuf_size( sc, size ) != SC_OK )
		XSRETURN_EMPTY;
	XSRETURN_YES;


#/*****************************************************************************
# * get_rcvbuf_size( this )
# *****************************************************************************/

void
get_rcvbuf_size( this )
	SV *this;
PREINIT:
	socket_class_t *sc;
	int size;
PPCODE:
	if( (sc = mod_sc_get_socket( this )) == NULL )
		XSRETURN_EMPTY;
	if( mod_sc_get_rcvbuf_size( sc, &size ) != SC_OK )
		XSRETURN_EMPTY;
	XSRETURN_IV( size );


#/*****************************************************************************
# * set_sndbuf_size( this, size )
# *****************************************************************************/

void
set_sndbuf_size( this, size )
	SV *this;
	int size;
PREINIT:
	socket_class_t *sc;
PPCODE:
	if( (sc = mod_sc_get_socket( this )) == NULL )
		XSRETURN_EMPTY;
	if( mod_sc_set_sndbuf_size( sc, size ) != SC_OK )
		XSRETURN_EMPTY;
	XSRETURN_YES;


#/*****************************************************************************
# * get_sndbuf_size( this )
# *****************************************************************************/

void
get_sndbuf_size( this )
	SV *this;
PREINIT:
	socket_class_t *sc;
	int size;
PPCODE:
	if( (sc = mod_sc_get_socket( this )) == NULL )
		XSRETURN_EMPTY;
	if( mod_sc_get_sndbuf_size( sc, &size ) != SC_OK )
		XSRETURN_EMPTY;
	XSRETURN_IV( size );


#/*****************************************************************************
# * set_tcp_nodelay( this [, value] )
# *****************************************************************************/

void
set_tcp_nodelay( this, mode = 1 )
	SV *this;
	int mode;
PREINIT:
	socket_class_t *sc;
PPCODE:
	if( (sc = mod_sc_get_socket( this )) == NULL )
		XSRETURN_EMPTY;
	if( mod_sc_set_tcp_nodelay( sc, mode ) != SC_OK )
		XSRETURN_EMPTY;
	XSRETURN_YES;


#/*****************************************************************************
# * get_tcp_nodelay( this )
# *****************************************************************************/

void
get_tcp_nodelay( this )
	SV *this;
PREINIT:
	socket_class_t *sc;
	int mode;
PPCODE:
	if( (sc = mod_sc_get_socket( this )) == NULL )
		XSRETURN_EMPTY;
	if( mod_sc_get_tcp_nodelay( sc, &mode ) != SC_OK )
		XSRETURN_EMPTY;
	XSRETURN_IV( mode );


#/*****************************************************************************
# * set_option( this, level, optname, value )
# *****************************************************************************/

void
set_option( this, level, optname, value, ... )
	SV *this;
	int level;
	int optname;
	SV *value;
PREINIT:
	socket_class_t *sc;
	int r;
	STRLEN len;
	const void *val;
	char tmp[20];
PPCODE:
	if( (sc = mod_sc_get_socket( this )) == NULL )
		XSRETURN_EMPTY;
	if( SvIOK( value ) && level == SOL_SOCKET ) {
		switch( optname ) {
		case SO_LINGER:
			if( items > 4 ) {
				((struct linger *) tmp)->l_onoff = (uint16_t) SvUV( value );
				((struct linger *) tmp)->l_linger = (uint16_t) SvUV( ST(4) );
			}
			else {
				((struct linger *) tmp)->l_onoff = (uint16_t) SvUV( value );
				((struct linger *) tmp)->l_linger = 1;
			}
			val = tmp;
			len = sizeof( struct linger );
			break;
		case SO_RCVTIMEO:
		case SO_SNDTIMEO:
#ifdef _WIN32
			if( items > 4 ) {
				*((DWORD *) tmp) = (DWORD) SvUV( value ) * 1000;
				*((DWORD *) tmp) += (DWORD) (SvUV( ST(4) ) / 1000);
			}
			else {
				*((DWORD *) tmp) = (DWORD) SvUV( value );
			}
			val = tmp;
			len = sizeof( DWORD );
#else
			if( items > 4 ) {
				((struct timeval *) tmp)->tv_sec = (long) SvIV( value );
				((struct timeval *) tmp)->tv_usec = (long) SvIV( ST(4) );
			}
			else {
				r = SvIV( value );
				((struct timeval *) tmp)->tv_sec = (long) (r / 1000);
				((struct timeval *) tmp)->tv_usec = (long) (r * 1000) % 1000000;
			}
			val = tmp;
			len = sizeof( struct timeval );
#endif
			break;
		default:
			goto _chk;
		}
		goto _set;
	}
_chk:
	if( SvIOK( value ) ) {
		r = (int) SvIV( value );
		val = (void *) &r;
		len = sizeof( int );
	}
	else {
		val = SvPVbyte( value, len );
	}
_set:
	if( mod_sc_setsockopt( sc, level, optname, val, (socklen_t) len ) != SC_OK )
		XSRETURN_EMPTY;
	XSRETURN_YES;


#/*****************************************************************************
# * get_option( this, level, optname )
# *****************************************************************************/

void
get_option( this, level, optname )
	SV *this;
	int level;
	int optname;
PREINIT:
	socket_class_t *sc;
	char tmp[20];
	socklen_t l = sizeof( tmp );
PPCODE:
	if( (sc = mod_sc_get_socket( this )) == NULL )
		XSRETURN_EMPTY;
	l = sizeof( tmp );
	if( mod_sc_getsockopt( sc, level, optname, tmp, &l ) != SC_OK )
		XSRETURN_EMPTY;
	if( level == SOL_SOCKET ) {
		switch( optname ) {
		case SO_LINGER:
			XPUSHs( sv_2mortal(
				newSVuv( ((struct linger *) tmp)->l_onoff ) ) );
			XPUSHs( sv_2mortal(
				newSVuv( ((struct linger *) tmp)->l_linger ) ) );
			break;
		case SO_RCVTIMEO:
		case SO_SNDTIMEO:
#ifdef _WIN32
#ifdef SC_DEBUG
			_debug( "optlen %d\n", l );
#endif
			if( GIMME_V == G_ARRAY ) {
				XPUSHs( sv_2mortal(
					newSVuv( *((DWORD *) tmp) / 1000 ) ) );
				XPUSHs( sv_2mortal(
					newSVuv( (*((DWORD *) tmp) * 1000) % 1000000 ) ) );
			}
			else {
				XPUSHs( sv_2mortal( newSVuv( *((DWORD *) tmp) ) ) );
			}
#else
			if( GIMME_V == G_ARRAY ) {
				XPUSHs( sv_2mortal(
					newSViv( ((struct timeval *) tmp)->tv_sec ) ) );
				XPUSHs( sv_2mortal(
					newSViv( ((struct timeval *) tmp)->tv_usec ) ) );
			}
			else {
				XPUSHs( sv_2mortal( newSVuv(
					((struct timeval *) tmp)->tv_sec * 1000 +
					((struct timeval *) tmp)->tv_usec / 1000
				) ) );
			}
#endif
			break;
		default:
			goto _chk;
		}
		goto _set;
	}
_chk:
#ifdef _WIN32
	if( l == sizeof( DWORD ) ) {
		/* just a try */
		XPUSHs( sv_2mortal( newSVuv( *((DWORD *) tmp) ) ) );
#else
	if( l == sizeof( int ) ) {
		/* just a try */
		XPUSHs( sv_2mortal( newSViv( *((int *) tmp) ) ) );
#endif
	}
	else {
		XPUSHs( sv_2mortal( newSVpvn( tmp, l ) ) );
	}
_set:
	{}


#/*****************************************************************************
# * set_timeout( this, ms )
# *****************************************************************************/

void
set_timeout( this, ms )
	SV *this;
	double ms;
PREINIT:
	socket_class_t *sc;
PPCODE:
	if( (sc = mod_sc_get_socket( this )) == NULL )
		XSRETURN_EMPTY;
	sc->timeout.tv_sec = (long) (ms / 1000);
	sc->timeout.tv_usec = (long) (ms * 1000) % 1000000;
	XSRETURN_YES;


#/*****************************************************************************
# * get_timeout( this )
# *****************************************************************************/

void
get_timeout( this )
	SV *this;
PREINIT:
	socket_class_t *sc;
PPCODE:
	if( (sc = mod_sc_get_socket( this )) == NULL )
		XSRETURN_EMPTY;
	XSRETURN_NV( sc->timeout.tv_sec * 1000 + sc->timeout.tv_usec / 1000 );


#/*****************************************************************************
# * is_readable( this [, timeout] )
# *****************************************************************************/

void
is_readable( this, timeout = NULL )
	SV *this;
	SV *timeout;
PREINIT:
	socket_class_t *sc;
	double ms;
	int readable;
PPCODE:
	if( (sc = mod_sc_get_socket( this )) == NULL )
		XSRETURN_EMPTY;
	ms = timeout != NULL ? SvNV( timeout ) : -1;
	if( mod_sc_is_readable( sc, ms, &readable ) != SC_OK )
		XSRETURN_EMPTY;
	ST(0) = readable ? &PL_sv_yes : &PL_sv_no;
	XSRETURN(1);


#/*****************************************************************************
# * is_writable( this [, timeout] )
# *****************************************************************************/

void
is_writable( this, timeout = NULL )
	SV *this;
	SV *timeout;
PREINIT:
	socket_class_t *sc;
	double ms;
	int writable;
PPCODE:
	if( (sc = mod_sc_get_socket( this )) == NULL )
		XSRETURN_EMPTY;
	ms = timeout != NULL ? SvNV( timeout ) : -1;
	if( mod_sc_is_writable( sc, ms, &writable ) != SC_OK )
		XSRETURN_EMPTY;
	ST(0) = writable ? &PL_sv_yes : &PL_sv_no;
	XSRETURN(1);


#/*****************************************************************************
# * select( this [, read [, write [, error [, timeout]]]] )
# *****************************************************************************/

void
select( this, read = NULL, write = NULL, except = NULL, timeout = NULL )
	SV *this;
	SV *read;
	SV *write;
	SV *except;
	SV *timeout;
PREINIT:
	socket_class_t *sc;
	int dr, dw, de, vr, vw, ve;
	double ms;
PPCODE:
	if( (sc = mod_sc_get_socket( this )) == NULL )
		XSRETURN_EMPTY;
	vr = dr = read != NULL && SvTRUE( read );
	vw = dw = write != NULL && SvTRUE( write );
	ve = de = except != NULL && SvTRUE( except );
	ms = timeout != NULL ? SvNV( timeout ) : -1;
	if( mod_sc_select( sc, &vr, &vw, &ve, ms ) != SC_OK )
		XSRETURN_EMPTY;
	if( dr && ! SvREADONLY( read ) )
		sv_setiv( read, vr );
	if( dw && ! SvREADONLY( write ) )
		sv_setiv( write, vw );
	if( de && ! SvREADONLY( except ) )
		sv_setiv( except, ve );
	XSRETURN_IV( vr + vw + ve );


#/*****************************************************************************
# * wait( this, timeout )
# *****************************************************************************/

void
wait( this, timeout )
	SV *this;
	double timeout;
PPCODE:
	if( this != NULL ) {} /* avoid compiler warning */
	mod_sc_sleep( timeout );


#/*****************************************************************************
# * handle( this )
# *****************************************************************************/

void
handle( this )
	SV *this;
PREINIT:
	socket_class_t *sc;
PPCODE:
	if( (sc = mod_sc_get_socket( this )) == NULL )
		XSRETURN_EMPTY;
	ST(0) = sv_2mortal( newSViv( sc->sock ) );
	XSRETURN( 1 );


#/*****************************************************************************
# * state( this )
# *****************************************************************************/

void
state( this )
	SV *this;
PREINIT:
	socket_class_t *sc;
PPCODE:
	if( (sc = mod_sc_get_socket( this )) == NULL )
		XSRETURN_EMPTY;
	ST(0) = sv_2mortal( newSViv( sc->state ) );
	XSRETURN( 1 );


#/*****************************************************************************
# * local_addr( this )
# *****************************************************************************/

void
local_addr( this )
	SV *this;
PREINIT:
	socket_class_t *sc;
	char host[NI_MAXHOST], serv[NI_MAXSERV];
	int r, host_len = NI_MAXHOST, serv_len = NI_MAXSERV;
PPCODE:
	if( (sc = mod_sc_get_socket( this )) == NULL )
		XSRETURN_EMPTY;
	r = mod_sc_unpack_addr( sc, &sc->l_addr, host, &host_len, serv, &serv_len );
	if( r != SC_OK )
		XSRETURN_EMPTY;
	ST(0) = sv_2mortal( newSVpvn( host, host_len ) );
	XSRETURN(1);


#/*****************************************************************************
# * local_path( this )
# *****************************************************************************/

void
local_path( this )
	SV *this;
PREINIT:
	socket_class_t *sc;
	char *s1;
PPCODE:
	if( (sc = mod_sc_get_socket( this )) == NULL )
		XSRETURN_EMPTY;
	switch( sc->s_domain ) {
	case AF_UNIX:
		s1 = ((struct sockaddr_un *) sc->l_addr.a )->sun_path;
		ST(0) = sv_2mortal( newSVpvn( s1, strlen( s1 ) ) );
		break;
	default:
		ST(0) = &PL_sv_undef;
	}
	XSRETURN(1);


#/*****************************************************************************
# * local_port( this )
# *****************************************************************************/

void
local_port( this )
	SV *this;
PREINIT:
PREINIT:
	socket_class_t *sc;
	char host[NI_MAXHOST], serv[NI_MAXSERV];
	int r, host_len = NI_MAXHOST, serv_len = NI_MAXSERV;
PPCODE:
	if( (sc = mod_sc_get_socket( this )) == NULL )
		XSRETURN_EMPTY;
	r = mod_sc_unpack_addr( sc, &sc->l_addr, host, &host_len, serv, &serv_len );
	if( r != SC_OK )
		XSRETURN_EMPTY;
	ST(0) = sv_2mortal( newSVpvn( serv, serv_len ) );
	XSRETURN(1);


#/*****************************************************************************
# * remote_addr( this )
# *****************************************************************************/

void
remote_addr( this )
	SV *this;
PREINIT:
	socket_class_t *sc;
	char host[NI_MAXHOST], serv[NI_MAXSERV];
	int r, host_len = NI_MAXHOST, serv_len = NI_MAXSERV;
PPCODE:
	if( (sc = mod_sc_get_socket( this )) == NULL )
		XSRETURN_EMPTY;
	r = mod_sc_unpack_addr( sc, &sc->r_addr, host, &host_len, serv, &serv_len );
	if( r != SC_OK )
		XSRETURN_EMPTY;
	ST(0) = sv_2mortal( newSVpvn( host, host_len ) );
	XSRETURN(1);


#/*****************************************************************************
# * remote_path( this )
# *****************************************************************************/

void
remote_path( this )
	SV *this;
PREINIT:
	socket_class_t *sc;
	char *s1;
PPCODE:
	if( (sc = socket_class_find( this )) == NULL )
		XSRETURN_EMPTY;
	switch( sc->s_domain ) {
	case AF_UNIX:
		s1 = ((struct sockaddr_un *) sc->r_addr.a )->sun_path;
		ST(0) = sv_2mortal( newSVpvn( s1, strlen( s1 ) ) );
		break;
	default:
		ST(0) = &PL_sv_undef;
	}
	XSRETURN(1);


#/*****************************************************************************
# * remote_port( this )
# *****************************************************************************/

void
remote_port( this )
	SV *this;
PREINIT:
	socket_class_t *sc;
	char host[NI_MAXHOST], serv[NI_MAXSERV];
	int r, host_len = NI_MAXHOST, serv_len = NI_MAXSERV;
PPCODE:
	if( (sc = mod_sc_get_socket( this )) == NULL )
		XSRETURN_EMPTY;
	r = mod_sc_unpack_addr( sc, &sc->r_addr, host, &host_len, serv, &serv_len );
	if( r != SC_OK )
		XSRETURN_EMPTY;
	ST(0) = sv_2mortal( newSVpvn( serv, serv_len ) );
	XSRETURN(1);


#/*****************************************************************************
# * to_string( this )
# *****************************************************************************/

void
to_string( this )
	SV *this;
PREINIT:
	socket_class_t *sc;
	char tmp[1024];
	size_t len = sizeof(tmp);
PPCODE:
	if( (sc = mod_sc_get_socket( this )) == NULL )
		XSRETURN_EMPTY;
	if( mod_sc_to_string( sc, tmp, &len ) != SC_OK )
		XSRETURN_EMPTY;
	ST(0) = sv_2mortal( newSVpvn( tmp, len ) );
	XSRETURN(1);


#/*****************************************************************************
# * is_error( this )
# *****************************************************************************/

void
is_error( this )
	SV *this;
PREINIT:
	socket_class_t *sc;
PPCODE:
	if( (sc = mod_sc_get_socket( this )) == NULL )
		XSRETURN_EMPTY;
	ST(0) = (sc->state == SC_STATE_ERROR) ? &PL_sv_yes : &PL_sv_no;
	XSRETURN(1);


#/*****************************************************************************
# * errno( this )
# *****************************************************************************/

void
errno( this )
	SV *this;
PREINIT:
	socket_class_t *sc;
PPCODE:
	sc = mod_sc_get_socket( this );
	XSRETURN_IV( mod_sc_get_errno( sc ) );


#/*****************************************************************************
# * error( this [, code] )
# *****************************************************************************/

void
error( this, code = 0 )
	SV *this;
	int code;
PREINIT:
	socket_class_t *sc;
	const char *msg;
PPCODE:
	sc = mod_sc_get_socket( this );
	if( code != 0 )
		mod_sc_set_errno( sc, code );
	msg = mod_sc_get_error( sc );
	ST(0) = sv_2mortal( newSVpvn( msg, strlen( msg ) ) );
	XSRETURN(1);
