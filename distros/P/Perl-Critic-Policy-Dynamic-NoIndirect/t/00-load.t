#!perl -T

use strict;
use warnings;

use Test::More tests => 1;

BEGIN {
	use_ok( 'Perl::Critic::Policy::Dynamic::NoIndirect' );
}

diag( "Testing Perl::Critic::Policy::Dynamic::NoIndirect $Perl::Critic::Policy::Dynamic::NoIndirect::VERSION, Perl $], $^X" );
