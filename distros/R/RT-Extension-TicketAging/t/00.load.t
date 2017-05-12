use Test::More tests => 2;

BEGIN { require 't/utils.pl' }

use_ok( 'RT' );
RT::LoadConfig();
use_ok( 'RT::Extension::TicketAging' );

diag( "Testing RT::Extension::TicketAging $RT::Extension::TicketAging::VERSION" );

