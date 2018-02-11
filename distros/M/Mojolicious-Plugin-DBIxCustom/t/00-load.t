#!perl -T
use 5.10.1;
use strict;
use warnings;
use Test::More;

plan tests => 3;

BEGIN {
    use_ok( 'Mojolicious::Plugin::DBIxCustom' ) || print "Bail out!\n";
    use_ok( 'Mojolicious::DBIxCustom' ) || print "Bail out!\n";
    use_ok( 'Mojolicious::DBIxCustom::Model' ) || print "Bail out!\n";
}

diag( "Testing Mojolicious::Plugin::DBIxCustom $Mojolicious::Plugin::DBIxCustom::VERSION, Perl $], $^X" );
