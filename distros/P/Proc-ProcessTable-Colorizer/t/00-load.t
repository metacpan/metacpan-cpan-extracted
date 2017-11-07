#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Proc::ProcessTable::Colorizer' ) || print "Bail out!\n";
}

diag( "Testing Proc::ProcessTable::Colorizer $Proc::ProcessTable::Colorizer::VERSION, Perl $], $^X" );
