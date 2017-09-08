#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 7;

BEGIN {
    use_ok( 'TIGR::HmmTools' ) || print "Bail out!\n";
    use_ok( 'TIGR::Foundation' ) || print "Bail out!\n";
    use_ok( 'TIGR::FASTA::Grammar' ) || print "Bail out!\n";
    use_ok( 'TIGR::FASTA::Iterator' ) || print "Bail out!\n";
    use_ok( 'TIGR::FASTA::Reader' ) || print "Bail out!\n";
    use_ok( 'TIGR::FASTA::Record' ) || print "Bail out!\n";
    use_ok( 'TIGR::FASTA::Writer' ) || print "Bail out!\n";
}

diag( "Testing TIGR::HmmTools $TIGR::HmmTools::VERSION, Perl $], $^X" );
