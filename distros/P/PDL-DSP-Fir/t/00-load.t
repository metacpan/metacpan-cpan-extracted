#!perl

use Test::More tests => 1;

BEGIN {
    use_ok( 'PDL::DSP::Fir' ) || print "Bail out!\n";
}

diag( "Testing PDL::DSP::Fir $PDL::DSP::Fir::VERSION, Perl $], $^X" );
