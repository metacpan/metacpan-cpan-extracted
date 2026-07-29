#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Proc::ProcessTable::Match::GID' ) || print "Bail out!\n";
}

diag( "Testing Proc::ProcessTable::Match::GID $Proc::ProcessTable::Match::GID::VERSION, Perl $], $^X" );
