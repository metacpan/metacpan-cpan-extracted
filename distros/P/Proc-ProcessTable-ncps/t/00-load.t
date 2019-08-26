#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Proc::ProcessTable::ncps' ) || print "Bail out!\n";
}

diag( "Testing Proc::ProcessTable::ncps $Proc::ProcessTable::ncps::VERSION, Perl $], $^X" );
