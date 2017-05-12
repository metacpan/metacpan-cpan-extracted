#!perl -T

use strict;
use warnings;

use Test::More tests => 1;

BEGIN {
 use_ok( 'Regexp::Wildcards' );
}

diag( "Testing Regexp::Wildcards $Regexp::Wildcards::VERSION, Perl $], $^X" );
