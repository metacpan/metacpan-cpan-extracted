#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Mojolicious::Command::generate::DBIxCustomModel' ) || print "Bail out!\n";
}

diag( "Testing Mojolicious::Command::generate::DBIxCustomModel $Mojolicious::Command::generate::DBIxCustomModel::VERSION, Perl $], $^X" );
