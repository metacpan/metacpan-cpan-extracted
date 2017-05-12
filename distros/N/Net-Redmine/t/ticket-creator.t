#!/usr/bin/env perl -w
use strict;
use Test::Cukes;
use Regexp::Common;
use Regexp::Common::Email::Address;
use Net::Redmine;
require 't/net_redmine_test.pl';

my $r;
my $ticket;
my $ticket_id;

Given qr/a ticket created by the current user/ => sub {
    my $r = new_net_redmine();

    my ($ticket) = new_tickets($r, 1);
    $ticket_id = $ticket->id;

    assert $ticket_id =~ /^\d+$/;
};

When qr/the ticket object is loaded/ => sub {
    $r = new_net_redmine();
    $ticket = $r->lookup(ticket => { id => $ticket_id });

    should $ticket->id, $ticket_id;
};

Then qr/its author should be the the current user/ => sub {
    assert $ticket->author->id =~ /^\d+$/;
    assert $ticket->author->email =~ /^$RE{Email}{Address}$/;
};



runtests(<<FEATURE);
Feature: know the creator of the ticket
  The creator (author) should be able to be retrieved from a ticket object

  Scenario: retrieve creator info from ticket
    Given a ticket created by the current user
    When the ticket object is loaded
    Then its author should be the the current user
FEATURE
