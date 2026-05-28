#!/usr/bin/env perl
# Real-mock-backed tests for SignalWire::Relay::Client receive / unreceive.
#
# Mirrors signalwire-python tests/unit/relay/test_client.py for the
# RelayClient.receive(contexts: list[str]) / unreceive(contexts: list[str])
# subscription methods. Verifies BOTH the canonical Python-shape arrayref
# call form AND the legacy slurpy form against the mock journal.

use strict;
use warnings;
use Test::More;
use FindBin ();
use lib "$FindBin::Bin/../lib";

use RelayMockTest;
use SignalWire::Relay::Client;

# ---------------------------------------------------------------------------
# receive(arrayref) — canonical Python-parity form
# ---------------------------------------------------------------------------

subtest 'receive(arrayref) sends signalwire.receive with contexts' => sub {
    my $client = RelayMockTest::client(contexts => ['default']);
    $client->connect;

    $client->receive(['ctx-a', 'ctx-b']);

    my $entries = RelayMockTest::journal_recv(method => 'signalwire.receive');
    is(scalar @$entries, 1, 'one signalwire.receive frame on wire');
    is_deeply($entries->[0]{frame}{params}{contexts}, ['ctx-a', 'ctx-b'],
              'contexts list passed verbatim');

    $client->disconnect;
};

subtest 'receive(slurpy) — backward-compat form' => sub {
    my $client = RelayMockTest::client(contexts => ['default']);
    $client->connect;

    $client->receive('only-one');

    my $entries = RelayMockTest::journal_recv(method => 'signalwire.receive');
    is(scalar @$entries, 1, 'one signalwire.receive frame on wire');
    is_deeply($entries->[0]{frame}{params}{contexts}, ['only-one'],
              'single ctx (slurpy form)');

    $client->disconnect;
};

subtest 'receive(empty arrayref) is a no-op' => sub {
    my $client = RelayMockTest::client(contexts => ['default']);
    $client->connect;

    my $before = scalar @{ RelayMockTest::journal_recv(method => 'signalwire.receive') };
    $client->receive([]);
    my $after = scalar @{ RelayMockTest::journal_recv(method => 'signalwire.receive') };
    is($after, $before, 'empty arrayref does not send a frame (Python parity)');

    $client->disconnect;
};

# ---------------------------------------------------------------------------
# unreceive(arrayref)
# ---------------------------------------------------------------------------

subtest 'unreceive(arrayref) sends signalwire.unreceive with contexts' => sub {
    my $client = RelayMockTest::client(contexts => ['default']);
    $client->connect;

    $client->unreceive(['ctx-x', 'ctx-y']);

    my $entries = RelayMockTest::journal_recv(method => 'signalwire.unreceive');
    is(scalar @$entries, 1, 'one signalwire.unreceive frame on wire');
    is_deeply($entries->[0]{frame}{params}{contexts}, ['ctx-x', 'ctx-y'],
              'contexts list passed verbatim');

    $client->disconnect;
};

subtest 'unreceive(empty arrayref) is a no-op' => sub {
    my $client = RelayMockTest::client(contexts => ['default']);
    $client->connect;

    my $before = scalar @{ RelayMockTest::journal_recv(method => 'signalwire.unreceive') };
    $client->unreceive([]);
    my $after = scalar @{ RelayMockTest::journal_recv(method => 'signalwire.unreceive') };
    is($after, $before, 'empty arrayref does not send a frame (Python parity)');

    $client->disconnect;
};

done_testing();
