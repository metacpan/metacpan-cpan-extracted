#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'PDL::DSP::Windows' ) || print "Bail out!\n";
}

diag( "Testing PDL::DSP::Windows $PDL::DSP::Windows::VERSION, Perl $], $^X" );
