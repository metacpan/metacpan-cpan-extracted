#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'RT::Extension::TicketPDF' );
}

diag( "Testing RT::Extension::TicketPDF $RT::Extension::TicketPDF::VERSION, Perl $], $^X" );

