#!/usr/bin/env perl -w
use strict;
use Test::More;
use Net::Redmine;

require 't/net_redmine_test.pl';

plan tests => 1;

my $r = new_net_redmine();

### Prepare new tickets
my ($ticket) = new_tickets($r, 1);
my $id = $ticket->id;

$ticket->destroy;

my $t2 = Net::Redmine::Ticket->load(connection => $r->connection, id => $id);

is($t2, undef, "loading a deleted ticket should return undef.");
