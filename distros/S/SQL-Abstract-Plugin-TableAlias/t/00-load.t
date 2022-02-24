#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'SQL::Abstract::Plugin::TableAlias' ) || print "Bail out!\n";
}

diag( "Testing SQL::Abstract::Plugin::TableAlias $SQL::Abstract::Plugin::TableAlias::VERSION, Perl $], $^X" );
