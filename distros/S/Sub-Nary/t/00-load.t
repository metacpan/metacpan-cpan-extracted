#!perl -T

use strict;
use warnings;
use Test::More tests => 1;

BEGIN {
	use_ok( 'Sub::Nary' );
}

diag( "Testing Sub::Nary $Sub::Nary::VERSION, Perl $], $^X" );
