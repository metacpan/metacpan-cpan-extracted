#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <windows.h>
#include <stdio.h>
#include <stdlib.h>
#include <ws2bth.h>
#include <BluetoothAPIs.h>
#ifdef __cplusplus
}
#endif

typedef PerlIO * InOutStream;

#define UUID_BASE_128 "00000000-0000-1000-8000-00805F9B34FB"

// Code from PyBlueZ
static void
ba2str( BTH_ADDR ba, char *addr )
{
    int i;
    unsigned char bytes[6];
    for( i=0; i<6; i++ ) {
        bytes[5-i] = (unsigned char) ((ba >> (i*8)) & 0xff);
    }
    sprintf(addr, "%02X:%02X:%02X:%02X:%02X:%02X", 
            bytes[0], bytes[1], bytes[2], bytes[3], bytes[4], bytes[5] );
}


// Code from PyBlueZ
static int 
str2uuid( const char *uuid_str, GUID *uuid ) 
{
    // Parse uuid128 standard format: 12345678-9012-3456-7890-123456789012
    int i;
    char buf[20] = { 0 };

    strncpy(buf, uuid_str, 8);
    uuid->Data1 = strtoul( buf, NULL, 16 );
    memset(buf, 0, sizeof(buf));

    strncpy(buf, uuid_str+9, 4);
    uuid->Data2 = (unsigned short) strtoul( buf, NULL, 16 );
    memset(buf, 0, sizeof(buf));
    
    strncpy(buf, uuid_str+14, 4);
    uuid->Data3 = (unsigned short) strtoul( buf, NULL, 16 );
    memset(buf, 0, sizeof(buf));

    strncpy(buf, uuid_str+19, 4);
    strncpy(buf+4, uuid_str+24, 12);
    for( i=0; i<8; i++ ) {
        char buf2[3] = { buf[2*i], buf[2*i+1], 0 };
        uuid->Data4[i] = (unsigned char)strtoul( buf2, NULL, 16 );
    }

    return 0;
}


static int
build_uuid(GUID *uuid, char *service)
{
char service_buf[37];


	if(service == NULL || strcmp(service, "0") == 0 || strlen(service) == 0) {
		// Use public browse group
		strcpy(service_buf, UUID_BASE_128);
		service_buf[4] = '1';
		service_buf[5] = '0';
		service_buf[6] = '0';
		service_buf[7] = '2';
		str2uuid(service_buf, uuid);
	}

	// 128 bit
	else if(strlen(service) == 36) {
		if(service[8] != '-' || service[13] != '-' ||
		   service[18] != '-' || service[23] != '-' ) {
			return(-1);
		}
		str2uuid(service, uuid);
	}

	// they left 0x on?
	else if(strlen(service) == 6){
		if(service[0] == '0' && service[1] == 'x' || service[1] == 'X') {
			strcpy(service_buf, UUID_BASE_128);
			service_buf[4] = service[2];
			service_buf[5] = service[3];
			service_buf[6] = service[4];
			service_buf[7] = service[5];
			str2uuid(service_buf, uuid);
		}

		else {
			return(-1);
		}
	}

	// 16 bit
	else if(strlen(service) == 4) {
		strcpy(service_buf, UUID_BASE_128);
		service_buf[4] = service[0];
		service_buf[5] = service[1];
		service_buf[6] = service[2];
		service_buf[7] = service[3];
		str2uuid(service_buf, uuid);
	}

	else {
		return(-1);
	}

	return(0);
}


MODULE = Net::Bluetooth	PACKAGE = Net::Bluetooth

void
_init()
	CODE:
	WORD wVersionRequested;
    WSADATA wsaData;

    wVersionRequested = MAKEWORD(2, 0);
    if(WSAStartup(wVersionRequested, &wsaData) != 0) {
		croak("Could not init Winsock!");
    }


void
_deinit()
	CODE:
	WSACleanup();


InOutStream
_perlfh(fd)
	int fd
	CODE:
	InOutStream fh = PerlIO_fdopen(fd, "r+");
	RETVAL = fh;

	OUTPUT:
	RETVAL 


void
_close(sock)
	int sock
	PPCODE:
	closesocket(sock);


unsigned int
_use_service_handle()
	CODE:
	// We dont use the service handle on Windows
	RETVAL = 0;

	OUTPUT:
	RETVAL 


void
get_remote_devices()
	PPCODE:
	int done = 0;
	int iRet;
	int error;
	DWORD flags = 0;
	DWORD qs_len;
	HANDLE hLookup;
	char addr_buf[64];
	WSAQUERYSET *qs;
	BTH_ADDR result;
	HV *return_hash = NULL;


	qs_len = sizeof(WSAQUERYSET);
	qs = (WSAQUERYSET*) malloc(qs_len);
	ZeroMemory(qs, sizeof(WSAQUERYSET));
	qs->dwSize = sizeof(WSAQUERYSET);
	qs->dwNameSpace = NS_BTH;
	qs->lpcsaBuffer = NULL;
	

	flags |= LUP_FLUSHCACHE | LUP_RETURN_NAME | LUP_RETURN_ADDR | LUP_CONTAINERS;

	iRet = WSALookupServiceBegin(qs, flags, &hLookup);

	// return undef if error and empty hash if no devices found?
	if(iRet == SOCKET_ERROR) {
		error = WSAGetLastError();
		if(error == WSASERVICE_NOT_FOUND) {
			// No device
			WSALookupServiceEnd(hLookup);
			free(qs); 
		} 
		
		else {
			free(qs);
		}
	}

	else {
		EXTEND(sp, 1);

		while(! done) {

			if(WSALookupServiceNext(hLookup, flags, &qs_len, qs) == NO_ERROR) {
				result = ((SOCKADDR_BTH*)qs->lpcsaBuffer->RemoteAddr.lpSockaddr)->btAddr;
				ba2str(result, addr_buf);
				if(return_hash == NULL) 
					return_hash = newHV();

				if(qs->lpszServiceInstanceName == NULL || strlen(qs->lpszServiceInstanceName) == 0) {
					hv_store(return_hash, addr_buf, strlen(addr_buf), newSVpv("[unknown]", 0), 0);
				}

				else {
					hv_store(return_hash, addr_buf, strlen(addr_buf), newSVpv(qs->lpszServiceInstanceName, 0), 0);
				}
			} 
			
			else {
				error = WSAGetLastError();
			
				if(error == WSAEFAULT) {
					free(qs);
					qs = (WSAQUERYSET*) malloc(qs_len);
					ZeroMemory(qs, qs_len);
				} 

				else if(error == WSA_E_NO_MORE) {
					done = 1;
				}

				else {
					done = 1;
				}
			}
		}

		// only return if has values
		if(return_hash != NULL)
			PUSHs(sv_2mortal(newRV_inc((SV*) return_hash)));

		WSALookupServiceEnd(hLookup);
	}



void
sdp_search(addr, service, name)
	char *addr
	char *service
	char *name
	PPCODE:
	char *addrstr = NULL;
	char *uuidstr = "0";
	char localAddressBuf[32];
	DWORD qs_len;
	WSAQUERYSET *qs;
	DWORD flags;
	HANDLE h;
	GUID uuid;
	SOCKADDR_BTH sa;
	int sa_len = sizeof(sa);
	int local_fd = 0;
	int done = 0;
	int proto;
	int port;
	int error;
	HV *return_hash = NULL;

	EXTEND(sp, 1);
	// this prolly doesnt need to be malloced
	// inquiry data structure
	qs_len = sizeof(WSAQUERYSET);
	qs = (WSAQUERYSET*) malloc(qs_len);

	flags = LUP_FLUSHCACHE | LUP_RETURN_ALL;

	ZeroMemory(qs, qs_len);
	qs->dwSize = sizeof(WSAQUERYSET);
	qs->dwNameSpace = NS_BTH;
	// ignored for queries?
	qs->dwNumberOfCsAddrs = 0;

	if(_stricmp(addr, "localhost") == 0 || _stricmp(addr, "local") == 0 ) {
			memset(&sa, 0, sizeof(sa));
			local_fd = socket(AF_BTH, SOCK_STREAM, BTHPROTO_RFCOMM);
			if(local_fd < 1) {
				free(qs);
				XSRETURN_UNDEF;
			}

			sa.addressFamily = AF_BTH;
			sa.port = BT_PORT_ANY;
			if(bind(local_fd,(LPSOCKADDR)&sa,sa_len) != NO_ERROR) {
				free(qs);
				close(local_fd);
				XSRETURN_UNDEF;
			}
                                                                                                                         
			if(getsockname(local_fd, (LPSOCKADDR)&sa, &sa_len) != NO_ERROR) {
				free(qs);
				close(local_fd);
				XSRETURN_UNDEF;
			}

			ba2str(sa.btAddr, localAddressBuf);
			qs->lpszContext = (LPSTR) localAddressBuf;
			close(local_fd);
	}

	else {
		qs->lpszContext = (LPSTR) addr;
	}


	memset(&uuid, 0, sizeof(uuid));
	if(build_uuid(&uuid, service) != 0) {
		free(qs);
		XSRETURN_UNDEF;
	}

	qs->lpServiceClassId = &uuid;

	if(WSALookupServiceBegin(qs, flags, &h) == SOCKET_ERROR) {
		free(qs);
		XSRETURN_UNDEF;
	}

	else {
		// iterate through the inquiry results
		while(! done) {
			if(WSALookupServiceNext(h, flags, &qs_len, qs) == NO_ERROR) {
				return_hash = newHV();

				// If name is valid, then compare names.
				if(name && strlen(name) > 0) {
					if(qs->lpszServiceInstanceName && strlen(qs->lpszServiceInstanceName) > 0) {
						if(_stricmp(name, qs->lpszServiceInstanceName) == 0) {
							hv_store(return_hash, "SERVICE_NAME", strlen("SERVICE_NAME"),
			                         newSVpv(qs->lpszServiceInstanceName, 0), 0);
						}

						else {
							continue;
						}
					}

					else {
						continue;
					}
				}

				else if(qs->lpszServiceInstanceName && strlen(qs->lpszServiceInstanceName) > 0) {
					hv_store(return_hash, "SERVICE_NAME", strlen("SERVICE_NAME"), newSVpv(qs->lpszServiceInstanceName, 0), 0);
				}

				if(qs->lpszComment && strlen(qs->lpszComment) > 0) {
					hv_store(return_hash, "SERVICE_DESC", strlen("SERVICE_DESC"), newSVpv(qs->lpszComment, 0), 0);
				}

				// set protocol and port
				proto = qs->lpcsaBuffer->iProtocol;
				port = ((SOCKADDR_BTH*)qs->lpcsaBuffer->RemoteAddr.lpSockaddr)->port;

				if(proto == BTHPROTO_RFCOMM) {
					if(port) {
						hv_store(return_hash, "RFCOMM", strlen("RFCOMM"), newSViv(port), 0);
					}
				} 
				
				else if(proto == BTHPROTO_L2CAP) {
					if(port) {
						hv_store(return_hash, "L2CAP", strlen("L2CAP"), newSViv(port), 0);
					}
				} 
				
				else {
					if(port) {
						hv_store(return_hash, "UNKNOWN", strlen("UNKNOWN"), newSViv(port), 0);
					}
				}


				// qs->lpBlob->pBlobData and qs->lpBlob->cbSize give access to the raw service records
			
				PUSHs(sv_2mortal(newRV_inc((SV*) return_hash)));
			} 
				
			else {
				error = WSAGetLastError();
						
				if(error == WSAEFAULT) {;
					free(qs);
					qs = (WSAQUERYSET*) malloc(qs_len);
				} 
			
				else if(error == WSA_E_NO_MORE) {
					done = 1;
				} 
			
				else {
					done = 1; 
				}
			}
		}
	}

	WSALookupServiceEnd(h);
	free(qs);

 
void
_register_service(serverfd, proto, port, service_id, name, desc, advertise)
	int serverfd
	char *proto
	int port
	char *service_id
	char *name
	char *desc
	int advertise
	PPCODE:
	WSAQUERYSET qs;
	WSAESETSERVICEOP op;
	SOCKADDR_BTH sa;
	int sa_len = sizeof(sa);
	char *service_name = NULL;
	char *service_desc = NULL;
	char *service_class_id_str = NULL;
	CSADDR_INFO sockInfo;
	GUID uuid;


	EXTEND(sp, 1);

	memset(&qs, 0, sizeof(qs));
	memset(&sa, 0, sizeof(sa));
	memset(&sockInfo, 0, sizeof(sockInfo));
	memset(&uuid, 0, sizeof(uuid));


	op = advertise ? RNRSERVICE_REGISTER : RNRSERVICE_DELETE;

	if(getsockname(serverfd, (SOCKADDR*) &sa, &sa_len) == SOCKET_ERROR) {
		PUSHs(sv_2mortal(newSViv(1)));
		XSRETURN_IV(0);
	}

	if(build_uuid(&uuid, service_id) != 0) {
		XSRETURN_IV(0);
	}

	sockInfo.iProtocol = BTHPROTO_RFCOMM;
	sockInfo.iSocketType = SOCK_STREAM;
	sockInfo.LocalAddr.lpSockaddr = (LPSOCKADDR) &sa;
	sockInfo.LocalAddr.iSockaddrLength = sizeof(sa);
	sockInfo.RemoteAddr.lpSockaddr = (LPSOCKADDR) &sa;
	sockInfo.RemoteAddr.iSockaddrLength = sizeof(sa);

	qs.dwSize = sizeof(qs);
	qs.dwNameSpace = NS_BTH;
	qs.lpcsaBuffer = &sockInfo;
	qs.lpszServiceInstanceName = name;
	qs.lpszComment = name;
	qs.lpServiceClassId = (LPGUID) &uuid;
	qs.dwNumberOfCsAddrs = 1;

	if(WSASetService(&qs, op, 0) ==  SOCKET_ERROR) {
		PUSHs(sv_2mortal(newSViv(0)));
	}

	else {
		PUSHs(sv_2mortal(newSViv(1)));
	}



int
_stop_service(sdp_addr)
	unsigned int sdp_addr
	CODE:
	// don't do anything here since we don't use handles
	RETVAL = 0;

	OUTPUT:
	RETVAL 



int
_socket(proto)
	char *proto
	CODE:

	if(_stricmp(proto, "RFCOMM") == 0)  {
		RETVAL = socket(AF_BTH, SOCK_STREAM, BTHPROTO_RFCOMM);
	}

	else if(_stricmp(proto, "L2CAP") == 0) {
		RETVAL = socket(AF_BTH, SOCK_STREAM, BTHPROTO_L2CAP);
	}

	else {
		RETVAL = -1;
	}

	OUTPUT:
	RETVAL 


int
_connect(fd, addr, port, proto)
	int fd
	char *addr
	int port
	char *proto
	CODE:
	SOCKADDR_BTH sa;
	int sa_len = sizeof(sa);
	memset(&sa, 0, sizeof(sa));


	if(WSAStringToAddress(addr, AF_BTH, NULL, (LPSOCKADDR)&sa, &sa_len) == SOCKET_ERROR) {
		RETVAL = -1;
	}

	else {
		sa.addressFamily = AF_BTH;
		sa.port = port;
		RETVAL = connect(fd, (LPSOCKADDR)&sa, sizeof(sa));
	}


	OUTPUT:
	RETVAL 


int
_bind(fd, port, proto)
	int fd
	int port
	char *proto
	CODE:
	int status;
	SOCKADDR_BTH sa;
	int sa_len;
	
	sa_len = sizeof(sa);

	memset(&sa, 0, sa_len);

	sa.btAddr = 0;
	sa.addressFamily = AF_BTH;
	sa.port = port;
	status = bind(fd, (LPSOCKADDR)&sa, sa_len);
	if(status == NO_ERROR) {
		RETVAL = 0;
	}

	else {
		RETVAL = -1;
	}


	OUTPUT:
	RETVAL 


int
_listen(fd, backlog)
	int fd
	int backlog
	CODE:
	int status;
	status = listen(fd, backlog);
	if(status == NO_ERROR) {
		RETVAL = 0;
	}

	else {
		RETVAL = -1;
	}

	OUTPUT:
	RETVAL 


void
_accept(fd, proto)
	int fd
	char *proto
	PPCODE:
	int addr_len;
	int res;
	char addr[19];
	SOCKADDR_BTH rcaddr;


	EXTEND(sp, 2);
	addr_len = sizeof(rcaddr);
	res = accept(fd, (LPSOCKADDR)&rcaddr, &addr_len);
	if(res != INVALID_SOCKET) {
		PUSHs(sv_2mortal(newSViv(res)));
		ba2str(rcaddr.btAddr, addr);
		PUSHs(sv_2mortal(newSVpv(addr, 0)));
	}

	else {
		PUSHs(sv_2mortal(newSViv(-1)));
	}


void
_getpeername(fd, proto)
	int fd
	char *proto
	PPCODE:
	EXTEND(sp, 2);
	// not implemented for Windows yet
	PUSHs(sv_2mortal(newSVuv(0)));
	PUSHs(sv_2mortal(newSVuv(0)));
