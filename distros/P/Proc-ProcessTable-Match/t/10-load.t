#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Proc::ProcessTable::Match::JID' ) || print "Bail out!\n";
}

diag( "Testing Proc::ProcessTable::Match::JID $Proc::ProcessTable::Match::JID::VERSION, Perl $], $^X" );
