/* -*- C -*- */
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <mach/port.h>
#include <mach/message.h>
#include <DNSServiceDiscovery/DNSServiceDiscovery.h>

#define MY_DEBUG 0

static 
void
register_callback(
    DNSServiceRegistrationReplyErrorType errorCode,
    void *context)
{
    dSP;
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);

#if MY_DEBUG
    printf("register: %x\n", context);
#endif

    XPUSHs( (SV*) context );
    switch (errorCode) {
    case kDNSServiceDiscoveryNoError:
	XPUSHs(sv_2mortal(newSVpv("success", 0)));  	break;
    case kDNSServiceDiscoveryNameConflict:
	XPUSHs(sv_2mortal(newSVpv("inuse", 0)));  	break;
    case kDNSServiceDiscoveryInvalid:
	XPUSHs(sv_2mortal(newSVpv("invalid", 0)));  	break;
    case kDNSServiceDiscoveryAlreadyRegistered:
	XPUSHs(sv_2mortal(newSVpv("already", 0)));  	break;
    default:
	XPUSHs(sv_2mortal(newSViv(errorCode)));
    }

    PUTBACK;
    call_method("_publish_callback", G_DISCARD);
    FREETMPS;
    LEAVE;
}


char *
explain_mach (mach_msg_return_t code) {
    switch (code) {
    case MACH_RCV_IN_PROGRESS:
	return "Thread is waiting for receive.  (Internal use only.)";
    case MACH_RCV_INVALID_NAME:
	return "Bogus name for receive port/port-set.";
    case MACH_RCV_TIMED_OUT:
	return "Didn't get a message within the timeout value.";
    case MACH_RCV_TOO_LARGE:
	return "Message buffer is not large enough for inline data.";
    case MACH_RCV_INTERRUPTED:
	return "Software interrupt.";
    case MACH_RCV_PORT_CHANGED:
	return "compatibility: no longer a returned error";
    case MACH_RCV_INVALID_NOTIFY:
	return "Bogus notify port argument.";
    case MACH_RCV_INVALID_DATA:
	return "Bogus message buffer for inline data.";
    case MACH_RCV_PORT_DIED:
	return "Port/set was sent away/died during receive.";
    case MACH_RCV_IN_SET:
	return "compatibility: no longer a returned error";
    case MACH_RCV_HEADER_ERROR:
	return "Error receiving message header.  See special bits.";
    case MACH_RCV_BODY_ERROR:
	return "Error receiving message body.  See special bits.";
    case MACH_RCV_INVALID_TYPE:
	return "Invalid msg-type specification in scatter list.";
    case MACH_RCV_SCATTER_SMALL:
	return "Out-of-line overwrite region is not large enough";
    case MACH_RCV_INVALID_TRAILER:
	return "trailer type or number of trailer elements not supported";
    case MACH_RCV_IN_PROGRESS_TIMED:
	return "Waiting for receive with timeout. (Internal use only.)";
    default:
	return "buggered if I know";
    }
}

MODULE = Net::Rendezvous::Publish::Backend::Apple PACKAGE = Net::Rendezvous::Publish::Backend::Apple

dns_service_discovery_ref
xs_publish( handle, name, type, domain, host, port, txt )
SV* handle;
char *name;
char *type;
char *domain;
int port;
char *txt;
CODE:
    RETVAL = DNSServiceRegistrationCreate( name, type, domain, htons(port), txt, 
	                                   register_callback, 
					   SvREFCNT_inc( handle ) );
#if MY_DEBUG
    printf( "registered service %x\n", RETVAL );
#endif
OUTPUT: RETVAL

void
xs_stop( what )
dns_service_discovery_ref what;
CODE: 
    DNSServiceDiscoveryDeallocate( what );

void
xs_step_for( time, ... )
int time;
CODE:
{
    int i;
    for (i = 1; i < items; i++) {
	mach_msg_header_t *msg;
	mach_port_t port;
	mach_msg_return_t ret;
        /* manually unfold the TPTROBJ typemap */
	SV *arg = ST(i);
	IV tmp = SvIV((SV*)SvRV(arg));
	dns_service_discovery_ref client = INT2PTR(dns_service_discovery_ref, tmp);
	port = DNSServiceDiscoveryMachPort(client);
#if MY_DEBUG
	printf(" %d looking at client %x port %x for %d\n", i, client, port, time);
#endif
	if (!port) continue;

	/* cribbed from CoreFramework */
	msg = malloc( sizeof( mach_msg_header_t ) + 1024 );
	msg->msgh_size = sizeof( mach_msg_header_t ) + 1024;
    try_recieve:
	msg->msgh_bits = 0;
        msg->msgh_local_port = port;
        msg->msgh_remote_port = MACH_PORT_NULL;
        msg->msgh_id = 0;

	ret = mach_msg( msg, MACH_RCV_MSG|MACH_RCV_LARGE|MACH_RCV_TIMEOUT, 0, 
			msg->msgh_size, port, time, MACH_PORT_NULL ); 
	if (ret == MACH_RCV_TOO_LARGE) {
#if MY_DEBUG
	    printf( "Too small, extending buffer\n" );
#endif
	    msg->msgh_size += 1024;
	    msg = realloc( msg, msg->msgh_size );
	    goto try_recieve;
	}
	if (ret == MACH_MSG_SUCCESS) {
#if MY_DEBUG
	    printf( "Got a message\n" );
#endif
	    DNSServiceDiscovery_handleReply( msg );
	}
	else {
#if MY_DEBUG
	    printf( "  error: '%s'\n", explain_mach( ret ) );
#endif
	}
	free(msg);
    }
}
