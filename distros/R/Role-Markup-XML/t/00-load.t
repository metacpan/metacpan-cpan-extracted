#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Role::Markup::XML' ) || print "Bail out!\n";
}

diag( "Testing Role::Markup::XML $Role::Markup::XML::VERSION, Perl $], $^X" );
