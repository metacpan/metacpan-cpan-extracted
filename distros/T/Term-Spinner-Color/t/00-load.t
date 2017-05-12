#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Term::Spinner::Color' ) || print "Bail out!\n";
}

diag( "Testing Term::Spinner::Color $Term::Spinner::Color::VERSION, Perl $], $^X" );
