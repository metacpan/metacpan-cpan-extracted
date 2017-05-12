#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Net::Nessus::XMLRPC' );
}

diag( "Testing Net::Nessus::XMLRPC $Net::Nessus::XMLRPC::VERSION, Perl $], $^X" );
