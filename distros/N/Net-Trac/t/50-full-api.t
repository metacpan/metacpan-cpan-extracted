use Test::More;

unless (`which trac-admin`) { plan skip_all => 'You need trac installed to run the tests'; }
plan tests => 25;


use_ok('Net::Trac::Connection');
use_ok('Net::Trac::Ticket');
require 't/setup_trac.pl';


my $tr = Net::Trac::TestHarness->new();

ok($tr->start_test_server(), "The server started!");


my $trac = Net::Trac::Connection->new(
    url      => $tr->url,
    user     => 'hiro',
    password => 'yatta'
);

isa_ok( $trac, "Net::Trac::Connection" );
is($trac->url, $tr->url);
my $ticket = Net::Trac::Ticket->new( connection => $trac);
isa_ok($ticket, 'Net::Trac::Ticket');

can_ok($ticket => '_fetch_new_ticket_metadata');
ok($ticket->_fetch_new_ticket_metadata);
can_ok($ticket => 'create');
ok($ticket->create(summary => 'This product has only a moose, not a pony'));
is($ticket->id, 1);

can_ok($ticket, 'load');
ok($ticket->load(1));
like($ticket->state->{'summary'}, qr/pony/);
like($ticket->summary, qr/pony/, "The summary looks like a pony");
like($ticket->summary, qr/moose/, "The summary looks like a moose");

ok( $ticket->update( 
                        summary => 'The product does not contain a pony',
                        description => "This\nis\nmultiline" 
            
            ), "updated!");

like($ticket->summary, qr/pony/, "The summary looks like a pony");
unlike($ticket->summary, qr/moose/, "The summary does not look like a moose");

like($ticket->description, qr/This/);
like($ticket->description, qr/multiline/);
my $history = $ticket->history;
ok($history, "The ticket has some history");
isa_ok($history, 'Net::Trac::TicketHistory');
can_ok($history, 'entries');
my @entries = @{$history->entries};
my $first = shift @entries;
is ($first->category, 'Ticket');
