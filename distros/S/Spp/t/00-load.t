#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 6;

BEGIN {
    use_ok( 'Spp' ) || print "Bail out!\n";
    use_ok( 'Spp::Tools' ) || print "Bail out!\n";
    use_ok( 'Spp::Rule' ) || print "Bail out!\n";
    use_ok( 'Spp::ValueToAtom' ) || print "Bail out!\n";
    use_ok( 'Spp::AtomToValue' ) || print "Bail out!\n";
    use_ok( 'Spp::Optimizer' ) || print "Bail out!\n";
}

diag( "Testing Spp $Spp::VERSION, Perl $], $^X" );
