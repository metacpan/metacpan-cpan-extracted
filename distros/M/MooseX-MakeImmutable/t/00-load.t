#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'MooseX::MakeImmutable' );
}

diag( "Testing MooseX::MakeImmutable $MooseX::MakeImmutable::VERSION, Perl $], $^X" );
