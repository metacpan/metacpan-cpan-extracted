#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';

use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Plack::App::REST' ) || print "Bail out!\n";
}

diag( "Testing Plack::App::REST $Plack::App::REST::VERSION, Perl $], $^X" );
