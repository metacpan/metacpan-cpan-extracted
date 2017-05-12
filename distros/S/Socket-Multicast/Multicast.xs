#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <sys/socket.h>

#ifdef WIN32
// winsock.h is for winsock <= 1.1
// #include <winsock.h>

// ws2tcpip.h is for winsock >= 2.0
#include <ws2tcpip.h>
#endif

#include "const-c.inc"

MODULE = Socket::Multicast		PACKAGE = Socket::Multicast

INCLUDE: const-xs.inc

PROTOTYPES: ENABLE

void
pack_ip_mreq(imr_multiaddr_sv, imr_interface_sv)
	SV* imr_multiaddr_sv
	SV* imr_interface_sv
	PREINIT:
	struct ip_mreq mreq;
	struct in_addr imr_multiaddr;
	struct in_addr imr_interface;
	CODE:
	{

	STRLEN addrlen;
	char * addr;
	
	// Byte load multicast address, machine order
	addr = SvPVbyte(imr_multiaddr_sv, addrlen);

	if (addrlen == sizeof(imr_multiaddr) || addrlen == 4)
		imr_multiaddr.s_addr =
	            (addr[0] & 0xFF) << 24 |
	            (addr[1] & 0xFF) << 16 |
	            (addr[2] & 0xFF) <<  8 |
	            (addr[3] & 0xFF);
	else
		croak("Bad arg length for %s, length is %d, should be %d",
		      "Socket::Multicast::pack_ip_mreq",
		      addrlen, sizeof(addr));

	// Byte load interface address, machine order
	addr = SvPVbyte(imr_interface_sv, addrlen);

	if (addrlen == sizeof(imr_interface) || addrlen == 4)
		imr_interface.s_addr =
		    (addr[0] & 0xFF) << 24 |
		    (addr[1] & 0xFF) << 16 |
		    (addr[2] & 0xFF) << 8 |
		    (addr[3] & 0xFF);
	else
		croak("Bad arg length for %s, length is %d, should be %d",
		      "Socket::Multicast::pack_ip_mreq",
		      addrlen, sizeof(addr));

	// Clear out final struct
	Zero( &mreq, sizeof mreq, char );

	// Load values into struct and convert to network order
	mreq.imr_multiaddr.s_addr = htonl(imr_multiaddr.s_addr);
	mreq.imr_interface.s_addr = htonl(imr_interface.s_addr);

	// new mortal string, return it.
	ST(0) = sv_2mortal(newSVpvn((char *)&mreq, sizeof(mreq)));
	}
