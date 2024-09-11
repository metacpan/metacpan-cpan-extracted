#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'OSLV::Monitor::Backends::cgroups' ) || print "Bail out!\n";
}

diag( "Testing OSLV::Monitor::Backends::cgroups $OSLV::Monitor::Backends::cgroups::VERSION, Perl $], $^X" );
