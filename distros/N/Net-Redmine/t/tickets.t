#!/usr/bin/env perl -w
use strict;
use Test::More;
use Net::Redmine;
use DateTime;

require 't/net_redmine_test.pl';
my $r = new_net_redmine();

plan tests => 5;

note "Testing about Net::Redmine::Ticket class";

my $subject = "Testing Net::Redmine $$ " . time;

note "The newly created ticket id should looks sane";
my $ticket = Net::Redmine::Ticket->create(
    connection => $r->connection,
    subject => $subject,
    description => "testing. testing. testing."
);
like $ticket->id, qr/^\d+$/;

$ticket->refresh;
# Given that this test doesn't run overnight.
is $ticket->created_at->ymd, DateTime->now->ymd;

note "Loading ticket content.";
my $ticket2 = Net::Redmine::Ticket->load(
    connection => $r->connection,
    id => $ticket->id
);

is($ticket2->id, $ticket->id);
is($ticket2->subject, $ticket->subject);
is($ticket2->description, $ticket->description);
