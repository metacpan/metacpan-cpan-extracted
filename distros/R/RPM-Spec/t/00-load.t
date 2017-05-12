#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'RPM::Spec' );
}

diag( "Testing RPM::Spec $RPM::Spec::VERSION, Perl $], $^X" );
