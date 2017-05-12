#!/usr/bin/env perl -w
use strict;
use Test::More;
use Net::Redmine;

plan skip_all => "duplicated with ticket-resolution.t";

exit;

require 't/net_redmine_test.pl';
my $r = new_net_redmine();

my @tickets = new_tickets(2);



TODO: {
    # XXX: this ticket is known to has status "Closed".
    my $id = 70;

    local $TODO = "Create a 'Closed' ticket first.";

    my $t = Net::Redmine::Ticket->load(connection => $r->connection, id => $id);

    is $t->status(), "Closed";
}
