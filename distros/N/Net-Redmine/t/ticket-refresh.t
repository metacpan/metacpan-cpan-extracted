#!/usr/bin/env perl -w
use strict;
use Test::More;
use Net::Redmine;

require 't/net_redmine_test.pl';
my $r = new_net_redmine();

plan tests => 1;

my ($ticket) = new_tickets($r, 1);
my $id = $ticket->id;

my $ticket2 = Net::Redmine::Ticket->load(connection => $r->connection, id => $id);

$ticket->description("bleh bleh bleh");
$ticket->save;

$ticket2->refresh;

is($ticket2->description, $ticket->description, "ticket content is refreshed");

