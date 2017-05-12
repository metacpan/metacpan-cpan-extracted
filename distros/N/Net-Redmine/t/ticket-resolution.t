#!/usr/bin/env perl -w
use strict;
use Test::More;
use Net::Redmine;

require 't/net_redmine_test.pl';

my $r = new_net_redmine();

plan tests => 2;

my $id;
{
    my $t1 = $r->create(ticket => {subject => __FILE__ . " $$ @{[time]}",description => __FILE__ . "$$ @{[time]}"});

    is $t1->status(), "New", "The default state of a new ticket";

    $t1->status("Closed");
    $t1->save;

    $id = $t1->id;
    diag "The newly created ticket id = $id";
}

{
    my $t = Net::Redmine::Ticket->load(connection => $r->connection, id => $id);

    is $t->status(), "Closed";
}
