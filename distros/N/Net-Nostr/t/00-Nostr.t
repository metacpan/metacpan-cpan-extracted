#!/usr/bin/perl

use strictures 2;

use Test2::V0 -no_srand => 1;

use Net::Nostr;

subtest 'client returns a Net::Nostr::Client' => sub {
    my $client = Net::Nostr->client;
    isa_ok($client, 'Net::Nostr::Client');
};

subtest 'relay returns a Net::Nostr::Relay' => sub {
    my $relay = Net::Nostr->relay;
    isa_ok($relay, 'Net::Nostr::Relay');
};

done_testing;
