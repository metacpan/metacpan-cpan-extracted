#include "sc_ws2bth.h"

#include <BluetoothAPIs.h>


int bt_device_list( bdaddr_t *r_addr, int r_addr_max ) {
	WSAQUERYSET search, *result;
	HANDLE res;
	int r;
	BTH_QUERY_DEVICE qd;
	BLOB blob;
	DWORD flags, size;
	BYTE buffer[1000];
	memset( &search, 0, sizeof( WSAQUERYSET ) );
	search.dwSize = sizeof( WSAQUERYSET );
	search.dwNameSpace = NS_BTH;
	/*
	blob.cbSize = sizeof( BTH_QUERY_DEVICE );
	blob.pBlobData = (BYTE *) &qd;
	search.lpBlob = &blob;
	*/
	flags = LUP_RETURN_NAME | LUP_CONTAINERS | LUP_RETURN_ADDR | LUP_FLUSHCACHE | LUP_RETURN_TYPE | LUP_RETURN_BLOB | LUP_RES_SERVICE;
	r = WSALookupServiceBegin( &search, flags, &res );
	if( r == SOCKET_ERROR ) {
		_debug( "WSALookupServiceBegin failed %d\n", r );
		return SOCKET_ERROR;
	}
	size = sizeof( buffer );
	result = (WSAQUERYSET*) buffer;
	r = WSALookupServiceNext( res, flags, &size, result );
	//r = WSALookupServiceNext( res, flags, &size, &search );
	if( r == SOCKET_ERROR ) {
		_debug( "WSALookupServiceNext failed %d\n", r );
		goto exit;
	}
	_debug( "device name [%s]\n", search.lpszServiceInstanceName );
	r = 0;
exit:
	WSALookupServiceEnd( res );
	return r;
}

int bt_device_name( bdaddr_t *addr, char *name, int name_len ) {
	return 0;
}

int bt_service_list( bdaddr_t *addr ) {
	return 0;
}

int bt_setaddr( my_thread_var_t *tv, const char *p1, const char *p2, int use ) {
	return 0;
}
