#!perl -T

use Test::More tests => 2;

BEGIN {
	use_ok( 'XMLRPC::Transport::HTTP::Nginx' );
	use_ok( 'SOAP::Transport::HTTP::Nginx' );
}

diag( "Testing XMLRPC::Transport::HTTP::Nginx $XMLRPC::Transport::HTTP::Nginx::VERSION, Perl $], $^X" );
