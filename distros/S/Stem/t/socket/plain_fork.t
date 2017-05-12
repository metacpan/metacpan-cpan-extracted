# t/socket/plain.t

use lib 't/socket' ;

use strict ;

use SockFork ;

my @ssl_client_args ;
my @ssl_server_args ;

SockFork::test( \@ssl_client_args, \@ssl_server_args ) ;

exit 0 ;
