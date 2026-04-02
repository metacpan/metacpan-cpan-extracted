#!/usr/bin/perl

use strictures 2;

use Test2::V0 -no_srand => 1;
use AnyEvent;
use IO::Socket::INET;

use Net::Nostr::Client;
use Net::Nostr::Relay;
use Net::Nostr::Event;
use Net::Nostr::Filter;
use Net::Nostr::Key;

sub free_port {
    my $sock = IO::Socket::INET->new(
        Listen => 1, LocalAddr => '127.0.0.1', LocalPort => 0,
    );
    my $port = $sock->sockport;
    close $sock;
    return $port;
}

sub make_event {
    my (%override) = @_;
    Net::Nostr::Event->new(
        pubkey     => 'a' x 64,
        kind       => 1,
        content    => 'test',
        sig        => 'a' x 128,
        created_at => 1000,
        tags       => [],
        %override,
    );
}

###############################################################################
# Construction
###############################################################################

subtest 'new creates a client' => sub {
    my $client = Net::Nostr::Client->new;
    isa_ok($client, 'Net::Nostr::Client');
};

###############################################################################
# Connect and disconnect
###############################################################################

subtest 'connect blocks and returns self' => sub {
    my $port = free_port();
    my $relay = Net::Nostr::Relay->new(verify_signatures => 0);
    $relay->start('127.0.0.1', $port);

    my $client = Net::Nostr::Client->new;
    my $ret = $client->connect("ws://127.0.0.1:$port");
    is($ret, $client, 'connect returns self');
    ok($client->is_connected, 'client reports connected');

    $client->disconnect;
    ok(!$client->is_connected, 'client reports disconnected after disconnect');

    $relay->stop;
};

subtest 'connect with callback (async)' => sub {
    my $port = free_port();
    my $relay = Net::Nostr::Relay->new(verify_signatures => 0);
    $relay->start('127.0.0.1', $port);

    my $client = Net::Nostr::Client->new;
    my $cv = AnyEvent->condvar;
    my $timeout = AnyEvent->timer(after => 5, cb => sub { $cv->croak("timeout") });

    $client->connect("ws://127.0.0.1:$port", sub {
        ok($client->is_connected, 'connected in callback');
        $cv->send;
    });

    $cv->recv;

    $client->disconnect;
    $relay->stop;
};

###############################################################################
# Publish (EVENT) and receive OK
###############################################################################

subtest 'publish sends EVENT and receives OK via callback' => sub {
    my $port = free_port();
    my $relay = Net::Nostr::Relay->new(verify_signatures => 0);
    $relay->start('127.0.0.1', $port);

    my $client = Net::Nostr::Client->new;
    my $event = make_event(content => 'publish test');

    my $cv = AnyEvent->condvar;
    my $timeout = AnyEvent->timer(after => 5, cb => sub { $cv->croak("timeout") });

    my @ok_received;
    $client->on(ok => sub {
        my ($event_id, $accepted, $message) = @_;
        push @ok_received, { event_id => $event_id, accepted => $accepted, message => $message };
        $cv->send;
    });

    $client->connect("ws://127.0.0.1:$port");
    $client->publish($event);

    $cv->recv;

    is(scalar @ok_received, 1, 'received one OK');
    is($ok_received[0]{event_id}, $event->id, 'OK has correct event_id');
    is($ok_received[0]{accepted}, 1, 'event was accepted');

    $client->disconnect;
    $relay->stop;
};

###############################################################################
# Subscribe (REQ) and receive events + EOSE
###############################################################################

subtest 'subscribe receives stored events then EOSE' => sub {
    my $port = free_port();
    my $relay = Net::Nostr::Relay->new(verify_signatures => 0);
    $relay->start('127.0.0.1', $port);

    my $client = Net::Nostr::Client->new;
    my $event = make_event(content => 'stored event');

    my $cv = AnyEvent->condvar;
    my $timeout = AnyEvent->timer(after => 5, cb => sub { $cv->croak("timeout") });

    my @events_received;
    my @eose_received;

    $client->on(ok => sub {
        my $filter = Net::Nostr::Filter->new(kinds => [1]);
        $client->subscribe('sub1', $filter);
    });

    $client->on(event => sub {
        my ($sub_id, $event) = @_;
        push @events_received, { sub_id => $sub_id, event => $event };
    });

    $client->on(eose => sub {
        my ($sub_id) = @_;
        push @eose_received, $sub_id;
        $cv->send;
    });

    $client->connect("ws://127.0.0.1:$port");
    $client->publish($event);

    $cv->recv;

    is(scalar @events_received, 1, 'received one event');
    is($events_received[0]{sub_id}, 'sub1', 'event has correct subscription_id');
    is($events_received[0]{event}->content, 'stored event', 'event content matches');
    is(\@eose_received, ['sub1'], 'received EOSE for sub1');

    $client->disconnect;
    $relay->stop;
};

###############################################################################
# Close subscription
###############################################################################

subtest 'close sends CLOSE message' => sub {
    my $port = free_port();
    my $relay = Net::Nostr::Relay->new(verify_signatures => 0);
    $relay->start('127.0.0.1', $port);

    my $client = Net::Nostr::Client->new;

    my $cv = AnyEvent->condvar;
    my $timeout = AnyEvent->timer(after => 5, cb => sub { $cv->croak("timeout") });

    my @eose_received;

    $client->on(eose => sub {
        my ($sub_id) = @_;
        push @eose_received, $sub_id;
        $client->close($sub_id);

        if ($sub_id eq 'sub1') {
            my $filter = Net::Nostr::Filter->new(kinds => [1]);
            $client->subscribe('sub2', $filter);
        } else {
            $cv->send;
        }
    });

    $client->connect("ws://127.0.0.1:$port");
    my $filter = Net::Nostr::Filter->new(kinds => [1]);
    $client->subscribe('sub1', $filter);

    $cv->recv;

    is(\@eose_received, ['sub1', 'sub2'], 'received EOSE for both subscriptions');

    $client->disconnect;
    $relay->stop;
};

###############################################################################
# Multiple filters in subscribe
###############################################################################

subtest 'subscribe with multiple filters' => sub {
    my $port = free_port();
    my $relay = Net::Nostr::Relay->new(verify_signatures => 0);
    $relay->start('127.0.0.1', $port);

    my $client = Net::Nostr::Client->new;
    my $e1 = make_event(kind => 1, content => 'kind 1');
    my $e2 = make_event(kind => 0, content => '{"name":"test"}');

    my $cv = AnyEvent->condvar;
    my $timeout = AnyEvent->timer(after => 5, cb => sub { $cv->croak("timeout") });

    my @events_received;
    my $ok_count = 0;

    $client->on(ok => sub {
        $ok_count++;
        if ($ok_count == 2) {
            my $f1 = Net::Nostr::Filter->new(kinds => [1]);
            my $f2 = Net::Nostr::Filter->new(kinds => [0]);
            $client->subscribe('multi', $f1, $f2);
        }
    });

    $client->on(event => sub {
        my ($sub_id, $event) = @_;
        push @events_received, $event;
    });

    $client->on(eose => sub { $cv->send });

    $client->connect("ws://127.0.0.1:$port");
    $client->publish($e1);
    $client->publish($e2);

    $cv->recv;

    is(scalar @events_received, 2, 'received both events');

    $client->disconnect;
    $relay->stop;
};

###############################################################################
# Live events (events arriving after EOSE)
###############################################################################

subtest 'receive live events after EOSE' => sub {
    my $port = free_port();
    my $relay = Net::Nostr::Relay->new(verify_signatures => 0);
    $relay->start('127.0.0.1', $port);

    my $client1 = Net::Nostr::Client->new;
    my $client2 = Net::Nostr::Client->new;

    my $cv = AnyEvent->condvar;
    my $timeout = AnyEvent->timer(after => 5, cb => sub { $cv->croak("timeout") });

    my @live_events;
    my $got_eose = 0;

    $client1->on(eose => sub {
        $got_eose = 1;
        # publish from client2 — should arrive as live event
        my $live = make_event(content => 'live!', created_at => 2000);
        $client2->publish($live);
    });

    $client1->on(event => sub {
        my ($sub_id, $event) = @_;
        if ($got_eose) {
            push @live_events, $event;
            $cv->send;
        }
    });

    $client2->on(ok => sub {});

    $client1->connect("ws://127.0.0.1:$port");
    $client2->connect("ws://127.0.0.1:$port");

    my $filter = Net::Nostr::Filter->new(kinds => [1]);
    $client1->subscribe('live-test', $filter);

    $cv->recv;

    is(scalar @live_events, 1, 'received one live event');
    is($live_events[0]->content, 'live!', 'live event content matches');

    $client1->disconnect;
    $client2->disconnect;
    $relay->stop;
};

###############################################################################
# Notice callback
###############################################################################

subtest 'on notice callback' => sub {
    my $client = Net::Nostr::Client->new;
    my @notices;
    $client->on(notice => sub { push @notices, $_[0] });
    ok(1, 'notice callback registered without error');
};

###############################################################################
# Error: publish before connect
###############################################################################

subtest 'publish before connect croaks' => sub {
    my $client = Net::Nostr::Client->new;
    my $event = make_event();
    ok(dies { $client->publish($event) }, 'publish before connect dies');
};

subtest 'subscribe before connect croaks' => sub {
    my $client = Net::Nostr::Client->new;
    my $filter = Net::Nostr::Filter->new(kinds => [1]);
    ok(dies { $client->subscribe('sub1', $filter) }, 'subscribe before connect dies');
};

subtest 'close before connect croaks' => sub {
    my $client = Net::Nostr::Client->new;
    ok(dies { $client->close('sub1') }, 'close before connect dies');
};

###############################################################################
# AUTH (NIP-42)
###############################################################################

subtest 'client receives AUTH challenge and stores it' => sub {
    my $port = free_port();
    my $relay = Net::Nostr::Relay->new(verify_signatures => 0);
    $relay->start('127.0.0.1', $port);

    my $client = Net::Nostr::Client->new;
    my $got_challenge;
    $client->on(auth => sub { $got_challenge = $_[0] });
    $client->connect("ws://127.0.0.1:$port");

    my $cv = AnyEvent->condvar;
    my $w = AnyEvent->timer(after => 0.1, cb => sub { $cv->send });
    $cv->recv;

    ok defined($got_challenge), 'auth callback received challenge';
    ok defined($client->challenge), 'challenge accessor returns value';
    is $client->challenge, $got_challenge, 'challenge matches callback arg';

    $client->disconnect;
    $relay->stop;
};

subtest 'authenticate sends AUTH event and receives OK' => sub {
    my $port = free_port();
    my $relay = Net::Nostr::Relay->new(verify_signatures => 0);
    $relay->start('127.0.0.1', $port);

    my $key = Net::Nostr::Key->new;
    my $client = Net::Nostr::Client->new;
    my ($auth_ok, $auth_msg);

    $client->on(auth => sub {});
    $client->on(ok => sub { $auth_ok = $_[1]; $auth_msg = $_[2] });
    $client->connect("ws://127.0.0.1:$port");

    my $cv = AnyEvent->condvar;
    my $w = AnyEvent->timer(after => 0.1, cb => sub { $cv->send });
    $cv->recv;

    $client->authenticate($key, "ws://127.0.0.1:$port");

    $cv = AnyEvent->condvar;
    $w = AnyEvent->timer(after => 0.1, cb => sub { $cv->send });
    $cv->recv;

    is $auth_ok, 1, 'authentication accepted';

    $client->disconnect;
    $relay->stop;
};

subtest 'authenticate before connect croaks' => sub {
    my $client = Net::Nostr::Client->new;
    my $key = Net::Nostr::Key->new;
    ok dies { $client->authenticate($key, 'ws://r/') }, 'authenticate before connect dies';
};

subtest 'authenticate without challenge croaks' => sub {
    my $port = free_port();
    my $relay = Net::Nostr::Relay->new(verify_signatures => 0);
    $relay->start('127.0.0.1', $port);

    my $client = Net::Nostr::Client->new;
    # Don't register auth callback, but manually clear challenge
    $client->on(auth => sub {});
    $client->connect("ws://127.0.0.1:$port");

    # Clear challenge to simulate no challenge state
    $client->challenge(undef);

    my $key = Net::Nostr::Key->new;
    ok dies { $client->authenticate($key, "ws://127.0.0.1:$port") },
        'authenticate without challenge dies';

    $client->disconnect;
    $relay->stop;
};

done_testing;
