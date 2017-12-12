#!perl -T
use 5.010001;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Mojolicious::Plugin::DBIxCustom' ) || print "Bail out!\n";
}

diag( "Testing Mojolicious::Plugin::DBIxCustom $Mojolicious::Plugin::DBIxCustom::VERSION, Perl $], $^X" );
