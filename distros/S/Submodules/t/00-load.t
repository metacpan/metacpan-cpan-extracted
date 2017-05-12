#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More tests => 2;
use lib 'lib';

BEGIN {
    use_ok( 'Submodules' ) || print "Bail out!\n";
    use_ok( 'Submodules::Result' ) || print "Bail out!\n";
}

diag( "Testing Submodules $Submodules::VERSION, Perl $], $^X" );
