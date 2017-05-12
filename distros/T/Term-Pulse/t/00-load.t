#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Term::Pulse' );
}

diag( "Testing Term::Pulse $Term::Pulse::VERSION, Perl $], $^X" );
