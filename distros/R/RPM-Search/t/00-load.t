#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'RPM::Search' ) || print "Bail out!\n";
}

diag( "Testing RPM::Search $RPM::Search::VERSION, Perl $], $^X" );
