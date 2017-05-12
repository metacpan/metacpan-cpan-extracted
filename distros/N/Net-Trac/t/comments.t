use warnings; 
use strict;

use Test::More;

unless (`which trac-admin`) { plan skip_all => 'You need trac installed to run the tests'; }
plan tests => 28;

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
ok($ticket->create(summary => 'Summary #1'));

can_ok($ticket, 'load');
ok($ticket->load(1));
like($ticket->state->{'summary'}, qr/Summary #1/);
like($ticket->summary, qr/Summary #1/, "The summary looks correct");

can_ok($ticket => 'update');
ok($ticket->update( comment => 'I like moose.' ), "Creating comment about moose.");
is(@{$ticket->history->entries}, 2, "Got 2 history entries.");
like($ticket->history->entries->[1]->content, qr/I like moose./, "The comment looks correct.");

can_ok($ticket => 'comment');
sleep(1); # trac can't accept two updates within 1 second on the same ticket.
ok($ticket->comment( 'I like fish.' ), "Creating comment about fish.");

can_ok( $ticket => 'comments' );
is(@{$ticket->comments}, 2, "Got two comments.");
like($ticket->comments->[1]->content, qr/fish/, "The comment looks correct.");
like($ticket->comments->[0]->content, qr/moose/, "The previous comment looks correct.");
sleep(1);
ok($ticket->update( summary => 'Summary #1 updated' ), "Updating summary.");
like($ticket->summary, qr/Summary #1 updated/, "The summary looks correct");
is(@{$ticket->history->entries}, 4, "Got 4 history entries");
is(@{$ticket->comments}, 2, "Only two comments");

