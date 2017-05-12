#!perl -T

use strict;
use warnings;

use Test::More tests => 1;

BEGIN {
 use_ok( 'Scope::Upper' );
}

diag( "Testing Scope::Upper $Scope::Upper::VERSION, Perl $], $^X" );
