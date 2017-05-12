#!perl -T

use strict;
use warnings;

use Test::More tests => 1;

BEGIN {
 use_ok( 'Sub::Prototype::Util' );
}

diag( "Testing Sub::Prototype::Util $Sub::Prototype::Util::VERSION, Perl $], $^X" );
