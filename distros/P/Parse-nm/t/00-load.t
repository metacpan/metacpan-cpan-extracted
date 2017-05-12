#!perl -T

use warnings;
use strict;

use Test::More tests => 2;
use Test::NoWarnings;

BEGIN {
    use_ok( 'Parse::nm' );
}

diag( "Testing Parse::nm ".Parse::nm->VERSION.", Perl $], $^O" );
