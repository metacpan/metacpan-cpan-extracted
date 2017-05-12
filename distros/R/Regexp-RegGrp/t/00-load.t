#!perl -T

use Test::More tests => 2;

BEGIN {
    use_ok( 'Regexp::RegGrp::Data' );
    use_ok( 'Regexp::RegGrp' );
}

diag( "Testing Regexp::RegGrp $Regexp::RegGrp::VERSION, Perl $], $^X" );
