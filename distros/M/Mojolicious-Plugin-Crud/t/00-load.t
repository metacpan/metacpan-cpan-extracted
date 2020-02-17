#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Mojolicious::Plugin::Crud' ) || print "Bail out!\n";
}

diag( "Testing Mojolicious::Plugin::Crud $Mojolicious::Plugin::Crud::VERSION, Perl $], $^X" );
