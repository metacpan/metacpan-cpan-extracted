#!/usr/bin/perl

use strictures 2;

use Test2::V0 -no_srand => 1;

use Net::Nostr::Client;
use Net::Nostr::Event;
use Net::Nostr::Filter;
use Net::Nostr::Key;

sub make_event {
    my (%override) = @_;
    return Net::Nostr::Event->new(
        pubkey     => 'a' x 64,
        kind       => 1,
        content    => 'test',
        sig        => 'a' x 128,
        created_at => 1000,
        tags       => [],
        %override,
    );
}

subtest 'new creates a client' => sub {
    my $client = Net::Nostr::Client->new;
    isa_ok($client, 'Net::Nostr::Client');
    ok(!$client->is_connected, 'client starts disconnected');
};

subtest 'new rejects unknown arguments' => sub {
    like(
        dies { Net::Nostr::Client->new(bogus => 'value') },
        qr/unknown.+bogus/i,
        'unknown argument rejected'
    );
};

subtest 'new accepts TLS client arguments' => sub {
    my $client = Net::Nostr::Client->new(
        ssl_no_verify => 1,
        ssl_ca_file   => 't/data/ca.pem',
    );
    isa_ok($client, 'Net::Nostr::Client');
};

subtest 'on validates callback type' => sub {
    my $client = Net::Nostr::Client->new;
    like(dies { $client->on('event', 'not a sub') },
        qr/callback.*code/i, 'string callback rejected');
    ok(lives { $client->on('event', sub { }) }, 'code ref accepted');
};

subtest 'on replaces previous callback for same type' => sub {
    my $client = Net::Nostr::Client->new;
    my @calls;
    $client->on('notice', sub { push @calls, 'first' });
    $client->on('notice', sub { push @calls, 'second' });
    $client->_emit('notice', 'test');
    is \@calls, ['second'], 'second callback replaced first';
};

subtest 'connect validates callback type' => sub {
    my $client = Net::Nostr::Client->new;
    like(dies { $client->connect('ws://localhost:9999', 'not a sub') },
        qr/callback.*code/i, 'string callback rejected');
};

subtest 'protocol methods croak before connect' => sub {
    my $client = Net::Nostr::Client->new;
    my $event = make_event();
    my $filter = Net::Nostr::Filter->new(kinds => [1]);
    my $key = Net::Nostr::Key->new;

    like dies { $client->publish($event) }, qr/not connected/i, 'publish before connect dies';
    like dies { $client->subscribe('sub1', $filter) }, qr/not connected/i, 'subscribe before connect dies';
    like dies { $client->close('sub1') }, qr/not connected/i, 'close before connect dies';
    like dies { $client->count('q1', $filter) }, qr/not connected/i, 'count before connect dies';
    like dies { $client->authenticate($key, 'ws://relay.example.com') }, qr/not connected/i, 'authenticate before connect dies';
    like dies { $client->neg_open('sub1', $filter, 'ab') }, qr/not connected/i, 'neg_open before connect dies';
    like dies { $client->neg_msg('sub1', 'ab') }, qr/not connected/i, 'neg_msg before connect dies';
    like dies { $client->neg_close('sub1') }, qr/not connected/i, 'neg_close before connect dies';
};

done_testing;
