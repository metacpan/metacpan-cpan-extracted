#!perl -T

use strict;
use warnings;
use Test::More tests => 1;
use lib '.';

BEGIN {
    use_ok( 'Statistics::Distribution::Generator' );
}

diag( "Testing Statistics::Distribution::Generator $Statistics::Distribution::Generator::VERSION, Perl $], $^X" );
