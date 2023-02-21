#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Terse::Plugin::DBI' ) || print "Bail out!\n";
}

diag( "Testing Terse::Plugin::DBI $Terse::Plugin::DBI::VERSION, Perl $], $^X" );
