#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Proc::ProcessTable::Match::EGID' ) || print "Bail out!\n";
}

diag( "Testing Proc::ProcessTable::Match::EGID $Proc::ProcessTable::Match::EGID::VERSION, Perl $], $^X" );
