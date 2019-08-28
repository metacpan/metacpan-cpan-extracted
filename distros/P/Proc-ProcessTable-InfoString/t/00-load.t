#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Proc::ProcessTable::InfoString' ) || print "Bail out!\n";
}

diag( "Testing Proc::ProcessTable::InfoString $Proc::ProcessTable::InfoString::VERSION, Perl $], $^X" );
