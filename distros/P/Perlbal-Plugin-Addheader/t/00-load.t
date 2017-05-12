#!perl -T

use Test::More tests => 1;
use Perlbal::HTTPHeaders;

BEGIN {
	use_ok( 'Perlbal::Plugin::Addheader' );
}

diag( "Testing Perlbal::Plugin::Addheader $Perlbal::Plugin::Addheader::VERSION, Perl $], $^X" );
