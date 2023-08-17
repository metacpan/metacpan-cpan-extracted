#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'SQL::Inserter' ) || print "Bail out!\n";
}

diag( "Testing SQL::Inserter $SQL::Inserter::VERSION, Perl $], $^X" );
