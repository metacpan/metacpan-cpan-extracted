#!perl -T

use Test::More tests => 1;

use lib qw( t t/lib lib ../lib );
BEGIN {
	use_ok( 'Package::Data::Inheritable' );
}

diag( "Testing Package::Data::Inheritable $Package::Data::Inheritable::VERSION, Perl $], $^X" );
