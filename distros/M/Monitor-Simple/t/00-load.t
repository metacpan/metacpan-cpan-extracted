#!perl -T

use Test::More tests => 1;

BEGIN {
    use lib './';
    use_ok( 'Monitor::Simple' );
}

diag( "Testing Monitor::Simple $Monitor::Simple::VERSION, Perl $], $^X" );
