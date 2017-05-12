#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Mojolicious::Plugin::MultiConfig' ) || print "Bail out!\n";
}

diag( "Testing Mojolicious::Plugin::MultiConfig $Mojolicious::Plugin::MultiConfig::VERSION, Perl $], $^X" );
