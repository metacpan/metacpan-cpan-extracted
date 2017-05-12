#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Mojolicious::Plugin::RoutesAuthDBI' ) || print "Bail out!\n";
}

diag( "Testing Mojolicious::Plugin::RoutesAuthDBI $Mojolicious::Plugin::RoutesAuthDBI::VERSION, Perl $], $^X" );
