/*

	liblo perl bindings

	Copyright 2005 Nicholas J. Humfrey <njh@aelius.com>

*/

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <lo/lo.h>

void xs_liblo_error(int num, const char *msg, const char *path)
{
    fprintf(stderr,"liblo server error %d in path %s: %s\n", num, path, msg);
}

int xs_liblo_handler(const char *path, const char *types,
				 lo_arg **argv, int argc, lo_message mesg,
				 void *user_data)
{
	dSP ;
	int i, result, count=0;
	SV* msgsv = sv_newmortal();
	sv_setref_pv(msgsv, "lo_message", (void*)mesg);

	ENTER;
	SAVETMPS;
	
	PUSHMARK(sp) ;
	XPUSHs((SV*)user_data);
	XPUSHs(msgsv);
	XPUSHs(sv_2mortal(newSVpv(path, 0)));
	XPUSHs(sv_2mortal(newSVpv(types, 0)));
	
	// Put parameters on the stack
	for(i=0; i<argc; i++) {
		switch(types[i]) {
			case 'i': XPUSHs(sv_2mortal(newSViv(argv[i]->i))); break;
			case 'f': XPUSHs(sv_2mortal(newSVnv(argv[i]->f))); break;
			case 's': XPUSHs(sv_2mortal(newSVpv(&argv[i]->s,0))); break;
			case 'd': XPUSHs(sv_2mortal(newSVnv(argv[i]->d))); break;
			case 'S': XPUSHs(sv_2mortal(newSVpv(&argv[i]->s,0))); break;
			case 'c': XPUSHs(sv_2mortal(newSVpv((char*)&argv[i]->c, 1))); break;
			case 'T': XPUSHs(sv_2mortal(newSVpv("True",4))); break;
			case 'F': XPUSHs(sv_2mortal(newSVpv("0False0",7))); break;
			case 'N': XPUSHs(sv_2mortal(newSVpv("0Nil0",5))); break;
			case 'I': XPUSHs(sv_2mortal(newSVpv("Infinitum",9))); break;
			default:
				fprintf(stderr, "xs_liblo_handler: Unsupported OSC type '%c'.", types[i] );
			break;
		}
	}
	
	PUTBACK ;

	// Call the perl handler (see perlcall manpage)
	count = perl_call_pv( "Net::LibLO::_method_dispatcher", G_SCALAR );
	
	SPAGAIN ;
	
	if (count != 1)
		croak("Return value should be a scaler integer.\n") ;
	
	// Get the return value off the stack
	result = POPi;
	PUTBACK;
	FREETMPS;
	LEAVE;
        
	// Return the result return by the perl sub
	return result;
}



MODULE = Net::LibLO	PACKAGE = Net::LibLO

##
## New address from host and port
##
lo_address
lo_address_new( host, port )
	const char *host
	const char *port

##
## New address from URL
##
lo_address
lo_address_new_from_url ( url )
	const char *url

##
## Return the error code for the last error
## associated with an address
##
int
lo_address_errno( address )
	lo_address	address

##
## Return the error string from the last error
## associated with an address
##
const char*
lo_address_errstr( address )
	lo_address address

##
## Return the hostname part of lo_address
##
const char*
lo_address_get_hostname( address )
	lo_address address

##
## Return the port part of lo_address
##
const char*
lo_address_get_port( address )
	lo_address address

##
## Return the URL of a lo_address
##
SV*
lo_address_get_url( address )
	lo_address address
  PREINIT:
	char *  urlstr = NULL;
  CODE:
	urlstr = lo_address_get_url( address );
	RETVAL = newSVpv( urlstr, 0 );
	free( urlstr );
  OUTPUT:
	RETVAL

##
## Free up memory used by an address
##
void
lo_address_free ( address )
	lo_address	address

##
## New blob from Perl Scalar
##
lo_blob
lo_blob_new( sv )
	SV* sv
  PREINIT:
	STRLEN  size = 0;
	char *  data = NULL;
  CODE:
  	data = SvPV( sv, size );
	RETVAL = lo_blob_new( size, data );
  OUTPUT:
	RETVAL


##
## Return the size of a blob
##
int
lo_blob_datasize ( blob )
	lo_blob	blob

##
## Free up memory used by a blob
##
void
lo_blob_free ( blob )
	lo_blob	blob

##
## Message related XSUBs
##
lo_message
lo_message_new()

void
lo_message_free( msg )
	lo_message msg

void
lo_message_pp(msg)
	lo_message   msg

size_t
lo_message_length(msg,path)
	lo_message msg
	const char *path

void
lo_message_add_char(msg, ch)
	lo_message   msg
	char		 ch

void
lo_message_add_double(msg, d)
	lo_message   msg
	double		 d

void
lo_message_add_false(msg)
	lo_message   msg

void
lo_message_add_float(msg, f)
	lo_message   msg
	float		 f

void
lo_message_add_infinitum(msg)
	lo_message   msg

void
lo_message_add_int32(msg, i)
	lo_message   msg
	I32			 i

void
lo_message_add_nil(msg)
	lo_message   msg

void
lo_message_add_string(msg, str)
	lo_message   msg
	const char*  str

void
lo_message_add_symbol(msg, sym)
	lo_message   msg
	const char*  sym

void
lo_message_add_true(msg)
	lo_message   msg

lo_address
lo_message_get_source(msg)
	lo_message   msg

##
## New Bundle
##
lo_bundle
lo_bundle_new( sec, frac )
	int sec
	int frac
  PREINIT:
	lo_timetag tt;
  CODE:
  	tt.sec = sec;
  	tt.frac = frac;
	RETVAL = lo_bundle_new( tt );
  OUTPUT:
	RETVAL


##
## Add a message to a Bundle
##
void
lo_bundle_add_message(b, path, m)
	lo_bundle b
	const char *path
	lo_message m

##
## Get length of a Bundle
##
int
lo_bundle_length(b)
	lo_bundle b

##
## Pretty Print Bundle
##
void
lo_bundle_pp ( b )
	lo_bundle b

##
## Free Bundle
##
void
lo_bundle_free ( b )
	lo_bundle b

##
## Create a new server
##
lo_server
lo_server_new_with_proto( port, protostr )
	const char * port
	const char * protostr
  PREINIT:
	int proto = -1;
  CODE:
  
  	if (strlen(port)==0) port = NULL;
  
    if (strcmp( protostr, "udp") == 0) proto = LO_UDP;
    else if (strcmp( protostr, "unix") == 0) proto = LO_UNIX;
    else if (strcmp( protostr, "tcp") == 0) proto = LO_TCP;

	if (proto != -1) {
		RETVAL = lo_server_new_with_proto( port, proto, xs_liblo_error );
	} else {
		RETVAL = NULL;
	}
	
  OUTPUT:
	RETVAL


##
## Free up server
##
void
lo_server_free( s )
	lo_server s
	
##
## Get port of server
##
int
lo_server_get_port(s)
	lo_server s

##
## Get URL of server
##
SV*
lo_server_get_url( server )
	lo_server server
  PREINIT:
	char *  urlstr = NULL;
  CODE:
	urlstr = lo_server_get_url( server );
	RETVAL = newSVpv( urlstr, 0 );
	free( urlstr );
  OUTPUT:
	RETVAL

##
## Add method handler to server
##
lo_method
lo_server_add_method( server, path, typespec, userdata )
	lo_server server
	const char* path
	const char* typespec
	SV* userdata
  CODE:
  	RETVAL = lo_server_add_method( server, path, typespec, xs_liblo_handler, newSVsv(userdata) );
  OUTPUT:
  	RETVAL

##
## Wait for an OSC packet to arrive
##
int
lo_server_recv( server )
	lo_server	 server

##
## Wait for an OSC packet to arrive
##
int
lo_server_recv_noblock( server, timeout )
	lo_server	 server
	int			 timeout

##
## Send an OSC message
##
int
lo_send_message_from( address, from, path, message )
	lo_address	 address
	lo_server	 from
	const char*  path
	lo_message   message

##
## Send an OSC bundle
##
int
lo_send_bundle_from( address, from, bundle )
	lo_address	 address
	lo_server	 from
	lo_bundle    bundle
