
#include "socket_class.h"

MODULE = Socket::Class::BT		PACKAGE = Socket::Class

BOOT:
{
	printf( "booting bluetooth module\n" );
}

#/*****************************************************************************
# * bt_device_list()
# *****************************************************************************/

void
bt_device_list( ... )
PREINIT:
	bdaddr_t addr[256];
	int r;
	my_thread_var_t *tv;
	char tmp[20];
PPCODE:
	r = bt_device_list( addr, sizeof( addr ) / sizeof( bdaddr_t ) );
	if( r == SOCKET_ERROR ) {
		tv = items > 0 ? my_thread_var_find( ST(0) ) : NULL;
		if( tv != NULL )
			tv->last_errno = Socket_errno();
		else
			global.last_errno = Socket_errno();
		XPUSHs( &PL_sv_undef );
	}
	else {
		for( r = r - 1; r >= 0; r -- ) {
			my_ba2str( &addr[r], tmp );
			XPUSHs( newSVpvn( tmp, 17 ) );
		}
	}


#/*****************************************************************************
# * bt_device_name()
# *****************************************************************************/

void
bt_device_name( ... )
PREINIT:
	char tmp[256], *s1;
	STRLEN l1;
	int r;
	bdaddr_t addr;
	my_thread_var_t *tv;
PPCODE:
	if( items > 1 ) {
		s1 = SvPVbyte( ST(1), l1 );
		if( l1 == sizeof( bdaddr_t ) )
			r = bt_device_name( (bdaddr_t *) s1, tmp, sizeof( tmp ) - 1 );
		else {
			my_str2ba( s1, &addr );
			r = bt_device_name( &addr, tmp, sizeof( tmp ) - 1 );
		}
	}
	else {
		r = bt_device_name( NULL, tmp, sizeof( tmp ) - 1 );
	}
	if( r == SOCKET_ERROR ) {
		tv = items > 0 ? my_thread_var_find( ST(0) ) : NULL;
		if( tv != NULL )
			tv->last_errno = Socket_errno();
		else
			global.last_errno = Socket_errno();
		XPUSHs( &PL_sv_undef );
	}
	else {
		//_debug( "got name %d %s\n", r, tmp );
		XPUSHs( newSVpvn( tmp, r ) );
	}
	

#/*****************************************************************************
# * bt_service_list()
# *****************************************************************************/

void
bt_service_list( ... )
PREINIT:
	char tmp[256], *s1;
	STRLEN l1;
	int r;
	bdaddr_t addr;
	my_thread_var_t *tv;
PPCODE:
	if( items > 1 ) {
		s1 = SvPVbyte( ST(1), l1 );
		if( l1 == sizeof( bdaddr_t ) )
			r = bt_service_list( (bdaddr_t *) s1 );
		else {
			my_str2ba( s1, &addr );
			r = bt_service_list( &addr );
		}
	}
	else {
		r = bt_service_list( NULL );
	}
	if( r == SOCKET_ERROR ) {
		tv = items > 0 ? my_thread_var_find( ST(0) ) : NULL;
		if( tv != NULL )
			tv->last_errno = Socket_errno();
		else
			global.last_errno = Socket_errno();
		XPUSHs( &PL_sv_undef );
	}
	
