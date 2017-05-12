#!perl 
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 3;

BEGIN {
    use_ok( 'PDL::IO::Dcm' ) || print "Dcm!\n";
    use_ok( 'PDL::IO::Dcm::Plugins::Primitive' ) || print "Primitive!\n";
    use_ok( 'PDL::IO::Dcm::Plugins::MRISiemens' ) || print "MRISiemens!\n";
}

diag( "Testing PDL::IO::Dcm $PDL::IO::Dcm::VERSION, Perl $], $^X" );
