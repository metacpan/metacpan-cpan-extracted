#!perl -T
use 5.10.1;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Mojolicious::Plugin::MostTagHelpers' ) || print "Bail out!\n";
}

diag( "Testing Mojolicious::Plugin::MostTagHelpers $Mojolicious::Plugin::MostTagHelpers::VERSION, Perl $], $^X" );
