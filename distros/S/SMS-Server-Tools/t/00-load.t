#!perl -T

use Test::More tests => 4;

BEGIN {
	use_ok( 'Log::Log4perl' );
	use_ok( 'SMS::Server::Tools' );
}

require_ok( 'Log::Log4perl' );
require_ok( 'SMS::Server::Tools' );

diag( "Testing SMS::Server::Tools $SMS::Server::Tools::VERSION, Perl $], $^X" );
