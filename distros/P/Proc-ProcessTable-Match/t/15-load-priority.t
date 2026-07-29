#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Proc::ProcessTable::Match::Priority' ) || print "Bail out!\n";
}

diag( "Testing Proc::ProcessTable::Match::Priority $Proc::ProcessTable::Match::Priority::VERSION, Perl $], $^X" );
