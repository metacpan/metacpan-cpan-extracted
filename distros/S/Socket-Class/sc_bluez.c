#include "sc_bluez.h"

#include <bluetooth/hci.h>
#include <bluetooth/hci_lib.h>
#include <bluetooth/sdp.h>
#include <bluetooth/sdp_lib.h>


int bt_device_list( bdaddr_t *r_addr, int r_addr_max ) {
	inquiry_info *ii = NULL;
	int num_rsp;
	int dev_id, sock;
	int i;
	
	dev_id = hci_get_route( NULL );
	sock = hci_open_dev( dev_id );
	if( dev_id < 0 || sock < 0 ) {
		_debug( "local adapter error %d %d\n", dev_id, sock );
		return SOCKET_ERROR;
	}
	Newx( ii, r_addr_max, inquiry_info );
	num_rsp = hci_inquiry( dev_id, 8, r_addr_max, NULL, &ii, 0 );
	if( num_rsp < 0 ) {
		_debug( "hci_inquiry error %d\n", num_rsp );
		free( ii );
		return SOCKET_ERROR;
	}
	
	for( i = 0; i < num_rsp; i ++ )
		Copy( &(ii+i)->bdaddr, &r_addr[i], 1, bdaddr_t );
	
	Safefree( ii );
	close( sock );
	
	return num_rsp;
}

int bt_device_name( bdaddr_t *addr, char *name, int name_len ) {
	int dev_id, sock, r;
	dev_id = hci_get_route( NULL );
	sock = hci_open_dev( dev_id );
	if( dev_id < 0 || sock < 0 ) {
		_debug( "local adapter error %d %d\n", dev_id, sock );
		return SOCKET_ERROR;
	}
	//memset( name, 0, name_len );
	if( addr == NULL ) {
		r = hci_read_local_name( sock, name_len, name, 0 );
	}
	else {
		r = hci_read_remote_name( sock, addr, name_len, name, 0 );
	}
	close( sock );
	return r == SOCKET_ERROR ? SOCKET_ERROR : strlen( name );
}

int bt_service_list( bdaddr_t *addr ) {
	sdp_session_t *session = NULL;
	sdp_list_t *rsp_list = NULL;
	int r;
	// connect to the SDP server running on the remote machine
	session = sdp_connect( BDADDR_ANY, addr, SDP_RETRY_IF_BUSY );
	r = sdp_service_search_req( session, NULL, 256, &rsp_list );
	_debug( "bt_service_list %u %d\n", session, r );
	sdp_close( session );
}

int bt_setaddr( my_thread_var_t *tv, const char *p1, const char *p2, int use ) {
	return 0;
}
