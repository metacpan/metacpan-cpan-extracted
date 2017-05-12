#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Term::Spinner::Lite' ) || print "Bail out!\n";
}

diag( "Testing Term::Spinner::Lite $Term::Spinner::Lite::VERSION, Perl $], $^X" );
