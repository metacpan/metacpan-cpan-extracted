use warnings; 
use strict;

use Test::More;

unless (`which trac-admin`) { plan skip_all => 'You need trac installed to run the tests'; }
plan tests => 58;


use_ok('Net::Trac::Connection');
use_ok('Net::Trac::TicketSearch');
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
my $ticket = Net::Trac::Ticket->new( connection => $trac );
isa_ok($ticket, 'Net::Trac::Ticket');

# Ticket 1
can_ok($ticket => 'create');
ok($ticket->create(summary => 'Summary #1'));
can_ok($ticket, 'load');
ok($ticket->load(1));
like($ticket->state->{'summary'}, qr/Summary #1/);
like($ticket->summary, qr/Summary #1/, "The summary looks correct");
ok($ticket->update( status => 'closed' ), "Status = closed");
is($ticket->status, 'closed', "Set status");

# Ticket 2
can_ok($ticket => 'create');
ok($ticket->create(summary => 'Summary #2', description => 'Any::Moose?'));
can_ok($ticket, 'load');
ok($ticket->load(2));
like($ticket->state->{'summary'}, qr/Summary #2/);
like($ticket->summary, qr/Summary #2/, "The summary looks correct");
like($ticket->description, qr/Any::Moose/, "The description looks correct");

# Ticket 3
can_ok($ticket => 'create');
ok($ticket->create(summary => 'Summary moose #3', description => 'Any::Moose!'));
can_ok($ticket, 'load');
ok($ticket->load(3));
like($ticket->state->{'summary'}, qr/Summary moose #3/);
like($ticket->summary, qr/Summary moose #3/, "The summary looks correct");
like($ticket->description, qr/Any::Moose/, "The description looks correct");

my $search = Net::Trac::TicketSearch->new( connection => $trac );
isa_ok( $search, 'Net::Trac::TicketSearch' );
can_ok( $search => 'query' );
ok($search->query);
is(@{$search->results}, 3, "Got two results");
isa_ok($search->results->[0], 'Net::Trac::Ticket');
isa_ok($search->results->[1], 'Net::Trac::Ticket');
isa_ok($search->results->[2], 'Net::Trac::Ticket');
is($search->results->[0]->summary, "Summary #1", "Got summary");
is($search->results->[1]->summary, "Summary #2", "Got summary");
is($search->results->[2]->summary, "Summary moose #3", "Got summary");

ok($search->query( id => 2 ));
is(@{$search->results}, 1, "Got one result");
isa_ok($search->results->[0], 'Net::Trac::Ticket');
is($search->results->[0]->summary, "Summary #2", "Got summary");

ok($search->query( summary => { contains => '#1' } ));
is(@{$search->results}, 1, "Got one result");
isa_ok($search->results->[0], 'Net::Trac::Ticket');
is($search->results->[0]->summary, "Summary #1", "Got summary");

ok($search->query( summary => { contains => ['moose', '#2'] } ));
is(@{$search->results}, 2, "Got two tickets");
isa_ok($search->results->[0], 'Net::Trac::Ticket');
isa_ok($search->results->[1], 'Net::Trac::Ticket');
is($search->results->[0]->summary, "Summary #2", "Got ticket #2");
is($search->results->[1]->summary, "Summary moose #3", "Got ticket #3");

ok($search->query( status => ['new','reopened'] ));
is(@{$search->results}, 2, "Got two results");
isa_ok($search->results->[0], 'Net::Trac::Ticket');
isa_ok($search->results->[1], 'Net::Trac::Ticket');
is($search->results->[0]->summary, "Summary #2", "Got ticket #2");
is($search->results->[1]->summary, "Summary moose #3", "Got ticket #3");
