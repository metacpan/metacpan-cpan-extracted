#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Mojolicious::Plugin::StaticShare' ) || print "Bail out!\n";
}

diag( "Testing Mojolicious::Plugin::StaticShare $Mojolicious::Plugin::StaticShare::VERSION, Perl $], $^X" );
