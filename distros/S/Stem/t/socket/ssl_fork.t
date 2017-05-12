# t/socket/ssl.t

use strict ;
use lib 't/socket' ;

unless ( eval { require IO::Socket::SSL } ) {

	print "1..0 # Skip IO::Socket::SSL is not installed\n" ;
	exit ;
}


require SockFork ;

my @ssl_client_args = (
	SSL_use_cert	=> 1,
	SSL_verify_mode => 0x01,
	SSL_passwd_cb	=> sub {return "bluebell"}
) ;

my @ssl_server_args = () ;

SockFork::test( \@ssl_client_args, \@ssl_server_args ) ;

exit 0 ;
