#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Mojolicious::Plugin::EDumper' ) || print "Bail out!\n";
}

diag( "Testing Mojolicious::Plugin::EDumper $Mojolicious::Plugin::EDumper::VERSION, Perl $], $^X" );
