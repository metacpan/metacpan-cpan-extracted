#!perl -T

use Test::More tests => 1;
use Perlbal::HTTPHeaders;

BEGIN {
	use_ok( 'Perlbal::Plugin::TrustHeader' );
}

diag( "Testing Perlbal::Plugin::TrustHeader $Perlbal::Plugin::TrustHeader::VERSION, Perl $], $^X" );
