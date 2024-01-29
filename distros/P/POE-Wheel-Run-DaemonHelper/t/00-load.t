#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'POE::Wheel::Run::DaemonHelper' ) || print "Bail out!\n";
}

diag( "Testing POE::Wheel::Run::DaemonHelper $POE::Wheel::Run::DaemonHelper::VERSION, Perl $], $^X" );
