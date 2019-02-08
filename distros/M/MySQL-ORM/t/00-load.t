#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'MySQL::ORM' ) || print "Bail out!\n";
}

diag( "Testing MySQL::ORM $MySQL::ORM::VERSION, Perl $], $^X" );
