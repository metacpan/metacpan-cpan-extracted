#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Proc::ProcessTable::Match::EUID' ) || print "Bail out!\n";
}

diag( "Testing Proc::ProcessTable::Match::EUID $Proc::ProcessTable::Match::EUID::VERSION, Perl $], $^X" );
