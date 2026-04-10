#!/usr/bin/perl

use strictures 2;
use Test2::V0 -no_srand => 1;
use AnyEvent;
use AnyEvent::WebSocket::Client;
use JSON;
use IO::Socket::INET;

use Net::Nostr::Relay;
use Net::Nostr::Event;
use Net::Nostr::Filter;
use Net::Nostr::Message;

my $JSON = JSON->new->utf8;

sub free_port {
    my $sock = IO::Socket::INET->new(
        Listen => 1, LocalAddr => '127.0.0.1', LocalPort => 0,
    );
    my $port = $sock->sockport;
    close $sock;
    return $port;
}

# Connect to relay, wait for server-side handler registration, then run $cb->($conn).
# Returns the client connection (must be stored to prevent GC).
sub connect_to_relay {
    my ($port, $cv_or_cb) = @_;
    my $client = AnyEvent::WebSocket::Client->new;
    my $client_conn;
    $client->connect("ws://127.0.0.1:$port")->cb(sub {
        $client_conn = eval { shift->recv };
        return unless $client_conn;
        # delay to let server establish handler
        my $t; $t = AnyEvent->timer(after => 0.15, cb => sub {
            undef $t;
            $cv_or_cb->($client_conn) if ref $cv_or_cb eq 'CODE';
        });
    });
    return \$client_conn; # return ref to keep alive
}

###############################################################################
# Construction
###############################################################################

subtest 'new creates relay' => sub {
    my $relay = Net::Nostr::Relay->new(verify_signatures => 0);
    isa_ok($relay, 'Net::Nostr::Relay');
};

subtest 'stop on unstarted relay is safe' => sub {
    my $relay = Net::Nostr::Relay->new(verify_signatures => 0);
    ok(lives { $relay->stop }, 'stop does not crash');
};

###############################################################################
# Start/Stop
###############################################################################

subtest 'start accepts WebSocket connections' => sub {
    my $port = free_port();
    my $relay = Net::Nostr::Relay->new(verify_signatures => 0);
    $relay->start('127.0.0.1', $port);

    my $cv = AnyEvent->condvar;
    my $timeout = AnyEvent->timer(after => 5, cb => sub { $cv->croak("timeout") });
    my $ref = connect_to_relay($port, sub { $cv->send(1) });

    ok($cv->recv, 'client connects successfully');
    $relay->stop;
};

subtest 'stop closes all connections' => sub {
    my $port = free_port();
    my $relay = Net::Nostr::Relay->new(verify_signatures => 0);
    $relay->start('127.0.0.1', $port);

    my $cv = AnyEvent->condvar;
    my $timeout = AnyEvent->timer(after => 5, cb => sub { $cv->croak("timeout") });
    my $finish_called = 0;
    my $ref = connect_to_relay($port, sub {
        my ($conn) = @_;
        $conn->on(finish => sub { $finish_called = 1; $cv->send(1) });
        $relay->stop;
    });

    $cv->recv;
    ok($finish_called, 'client finish callback fired on stop');
};

subtest 'POD: run blocks until stop is called' => sub {
    my $port = free_port();
    my $relay = Net::Nostr::Relay->new(verify_signatures => 0);

    my $timer = AnyEvent->timer(after => 0.1, cb => sub {
        ok($relay->_guard, 'relay is running');
        $relay->stop;
    });

    $relay->run('127.0.0.1', $port);
    # run returned, meaning stop unblocked it
    ok(!$relay->_guard, 'relay stopped after stop unblocks run');
};

subtest 'stop prevents new connections' => sub {
    my $port = free_port();
    my $relay = Net::Nostr::Relay->new(verify_signatures => 0);
    $relay->start('127.0.0.1', $port);
    $relay->stop;

    my $cv = AnyEvent->condvar;
    my $timeout = AnyEvent->timer(after => 5, cb => sub { $cv->croak("timeout") });
    my $client = AnyEvent::WebSocket::Client->new;
    $client->connect("ws://127.0.0.1:$port")->cb(sub {
        my $conn = eval { shift->recv };
        $cv->send($@ ? 1 : 0);
    });

    ok($cv->recv, 'connection fails after stop');
};

###############################################################################
# EVENT handling
###############################################################################

subtest 'relay responds OK to EVENT' => sub {
    my $port = free_port();
    my $relay = Net::Nostr::Relay->new(verify_signatures => 0);
    $relay->start('127.0.0.1', $port);

    my $cv = AnyEvent->condvar;
    my $timeout = AnyEvent->timer(after => 5, cb => sub { $cv->croak("timeout") });
    my $event = Net::Nostr::Event->new(
        pubkey => 'a' x 64, kind => 1, content => 'hello',
        sig => 'b' x 128, created_at => 1000, tags => [],
    );
    my $ref = connect_to_relay($port, sub {
        my ($conn) = @_;
        $conn->on(each_message => sub {
            my ($c, $msg) = @_;
            $cv->send($msg->body);
        });

        $conn->send(Net::Nostr::Message->new(type => 'EVENT', event => $event)->serialize);
    });

    my $response = $cv->recv;
    ok(defined $response, 'got response');
    my $parsed = $JSON->decode($response);
    is($parsed->[0], 'OK', 'response type is OK');
    is($parsed->[1], $event->id, 'OK references event id');
    is($parsed->[2], JSON::true, 'event accepted');

    $relay->stop;
};

subtest 'relay stores received events' => sub {
    my $port = free_port();
    my $relay = Net::Nostr::Relay->new(verify_signatures => 0);
    $relay->start('127.0.0.1', $port);

    my $cv = AnyEvent->condvar;
    my $timeout = AnyEvent->timer(after => 5, cb => sub { $cv->croak("timeout") });
    my $ref = connect_to_relay($port, sub {
        my ($conn) = @_;
        $conn->on(each_message => sub { $cv->send() });

        my $event = Net::Nostr::Event->new(
            pubkey => 'a' x 64, kind => 1, content => 'stored',
            sig => 'b' x 128, created_at => 1000, tags => [],
        );
        $conn->send(Net::Nostr::Message->new(type => 'EVENT', event => $event)->serialize);
    });

    $cv->recv;
    my $events = $relay->events || [];
    is(scalar @$events, 1, 'relay stored one event');

    $relay->stop;
};

###############################################################################
# REQ handling
###############################################################################

subtest 'relay sends EOSE after REQ with no matching events' => sub {
    my $port = free_port();
    my $relay = Net::Nostr::Relay->new(verify_signatures => 0);
    $relay->start('127.0.0.1', $port);

    my $cv = AnyEvent->condvar;
    my $timeout = AnyEvent->timer(after => 5, cb => sub { $cv->croak("timeout") });
    my $ref = connect_to_relay($port, sub {
        my ($conn) = @_;
        $conn->on(each_message => sub {
            my ($c, $msg) = @_;
            $cv->send($msg->body);
        });

        my $filter = Net::Nostr::Filter->new(kinds => [1]);
        $conn->send(Net::Nostr::Message->new(type => 'REQ', subscription_id => 'sub1', filters => [$filter])->serialize);
    });

    my $response = $cv->recv;
    my $parsed = $JSON->decode($response);
    is($parsed->[0], 'EOSE', 'response is EOSE');
    is($parsed->[1], 'sub1', 'EOSE references subscription id');

    $relay->stop;
};

subtest 'relay sends matching stored events then EOSE' => sub {
    my $port = free_port();
    my $relay = Net::Nostr::Relay->new(verify_signatures => 0);
    $relay->start('127.0.0.1', $port);

    my @messages;
    my $cv = AnyEvent->condvar;
    my $timeout = AnyEvent->timer(after => 5, cb => sub { $cv->croak("timeout") });
    my $ref = connect_to_relay($port, sub {
        my ($conn) = @_;
        my $phase = 'store';
        $conn->on(each_message => sub {
            my ($c, $msg) = @_;
            my $parsed = $JSON->decode($msg->body);
            if ($phase eq 'store') {
                $phase = 'query';
                my $filter = Net::Nostr::Filter->new(kinds => [1]);
                $c->send(Net::Nostr::Message->new(type => 'REQ', subscription_id => 'sub1', filters => [$filter])->serialize);
            } else {
                push @messages, $parsed;
                $cv->send() if $parsed->[0] eq 'EOSE';
            }
        });

        my $event = Net::Nostr::Event->new(
            pubkey => 'a' x 64, kind => 1, content => 'test',
            sig => 'b' x 128, created_at => 1000, tags => [],
        );
        $conn->send(Net::Nostr::Message->new(type => 'EVENT', event => $event)->serialize);
    });

    $cv->recv;
    is(scalar @messages, 2, 'got EVENT + EOSE');
    is($messages[0][0], 'EVENT', 'first message is EVENT');
    is($messages[0][1], 'sub1', 'EVENT has subscription id');
    is($messages[1][0], 'EOSE', 'second message is EOSE');

    $relay->stop;
};

subtest 'relay does not send non-matching stored events' => sub {
    my $port = free_port();
    my $relay = Net::Nostr::Relay->new(verify_signatures => 0);
    $relay->start('127.0.0.1', $port);

    my @messages;
    my $cv = AnyEvent->condvar;
    my $timeout = AnyEvent->timer(after => 5, cb => sub { $cv->croak("timeout") });
    my $ref = connect_to_relay($port, sub {
        my ($conn) = @_;
        my $phase = 'store';
        $conn->on(each_message => sub {
            my ($c, $msg) = @_;
            my $parsed = $JSON->decode($msg->body);
            if ($phase eq 'store') {
                $phase = 'query';
                # query for kind 2, but stored event is kind 1
                my $filter = Net::Nostr::Filter->new(kinds => [2]);
                $c->send(Net::Nostr::Message->new(type => 'REQ', subscription_id => 'sub1', filters => [$filter])->serialize);
            } else {
                push @messages, $parsed;
                $cv->send() if $parsed->[0] eq 'EOSE';
            }
        });

        my $event = Net::Nostr::Event->new(
            pubkey => 'a' x 64, kind => 1, content => 'wrong kind',
            sig => 'b' x 128, created_at => 1000, tags => [],
        );
        $conn->send(Net::Nostr::Message->new(type => 'EVENT', event => $event)->serialize);
    });

    $cv->recv;
    is(scalar @messages, 1, 'got only EOSE');
    is($messages[0][0], 'EOSE', 'only message is EOSE');

    $relay->stop;
};

###############################################################################
# CLOSE handling
###############################################################################

subtest 'relay removes subscription on CLOSE' => sub {
    my $port = free_port();
    my $relay = Net::Nostr::Relay->new(verify_signatures => 0);
    $relay->start('127.0.0.1', $port);

    my $cv = AnyEvent->condvar;
    my $timeout = AnyEvent->timer(after => 5, cb => sub { $cv->croak("timeout") });
    my $ref = connect_to_relay($port, sub {
        my ($conn) = @_;
        $conn->on(each_message => sub {
            my ($c, $msg) = @_;
            my $parsed = $JSON->decode($msg->body);
            if ($parsed->[0] eq 'EOSE') {
                $c->send(Net::Nostr::Message->new(type => 'CLOSE', subscription_id => 'sub1')->serialize);
                my $timer; $timer = AnyEvent->timer(after => 0.1, cb => sub {
                    undef $timer;
                    $cv->send();
                });
            }
        });

        my $filter = Net::Nostr::Filter->new(kinds => [1]);
        $conn->send(Net::Nostr::Message->new(type => 'REQ', subscription_id => 'sub1', filters => [$filter])->serialize);
    });

    $cv->recv;
    my $subs = $relay->subscriptions || {};
    my $has_sub = 0;
    for my $conn_id (keys %$subs) {
        $has_sub = 1 if exists $subs->{$conn_id}{'sub1'};
    }
    ok(!$has_sub, 'subscription removed after CLOSE');

    $relay->stop;
};

###############################################################################
# Duplicate event detection
###############################################################################

subtest 'relay rejects duplicate events with OK true + duplicate: prefix' => sub {
    my $port = free_port();
    my $relay = Net::Nostr::Relay->new(verify_signatures => 0);
    $relay->start('127.0.0.1', $port);

    my @responses;
    my $cv = AnyEvent->condvar;
    my $timeout = AnyEvent->timer(after => 5, cb => sub { $cv->croak("timeout") });
    my $ref = connect_to_relay($port, sub {
        my ($conn) = @_;
        $conn->on(each_message => sub {
            my ($c, $msg) = @_;
            push @responses, $JSON->decode($msg->body);
            $cv->send() if @responses == 2;
        });

        my $event = Net::Nostr::Event->new(
            pubkey => 'a' x 64, kind => 1, content => 'dup test',
            sig => 'b' x 128, created_at => 1000, tags => [],
        );
        # send same event twice
        $conn->send(Net::Nostr::Message->new(type => 'EVENT', event => $event)->serialize);
        my $t; $t = AnyEvent->timer(after => 0.2, cb => sub {
            undef $t;
            $conn->send(Net::Nostr::Message->new(type => 'EVENT', event => $event)->serialize);
        });
    });

    $cv->recv;
    is($responses[0][0], 'OK', 'first response is OK');
    is($responses[0][2], JSON::true, 'first event accepted');
    is($responses[1][0], 'OK', 'second response is OK');
    is($responses[1][2], JSON::true, 'second event accepted (duplicate)');
    like($responses[1][3], qr/^duplicate:/, 'second OK has duplicate: prefix');

    my $events = $relay->events || [];
    is(scalar @$events, 1, 'relay stored only one event');

    $relay->stop;
};

###############################################################################
# Event validation
###############################################################################

subtest 'relay rejects event with bad id format' => sub {
    my $port = free_port();
    my $relay = Net::Nostr::Relay->new(verify_signatures => 0);
    $relay->start('127.0.0.1', $port);

    my $cv = AnyEvent->condvar;
    my $timeout = AnyEvent->timer(after => 5, cb => sub { $cv->croak("timeout") });
    my $ref = connect_to_relay($port, sub {
        my ($conn) = @_;
        $conn->on(each_message => sub {
            my ($c, $msg) = @_;
            $cv->send($msg->body);
        });

        # send raw JSON with bad id (not 64-char hex)
        my $raw = $JSON->encode(['EVENT', {
            id => 'not-valid-hex', pubkey => 'a' x 64, kind => 1,
            content => 'bad', sig => 'b' x 128, created_at => 1000, tags => [],
        }]);
        $conn->send($raw);
    });

    my $response = $cv->recv;
    my $parsed = $JSON->decode($response);
    is($parsed->[0], 'OK', 'response is OK');
    is($parsed->[2], JSON::false, 'event rejected');
    like($parsed->[3], qr/^invalid:/, 'rejection has invalid: prefix');

    $relay->stop;
};

subtest 'relay rejects event with wrong id (hash mismatch)' => sub {
    my $port = free_port();
    my $relay = Net::Nostr::Relay->new(verify_signatures => 0);
    $relay->start('127.0.0.1', $port);

    my $cv = AnyEvent->condvar;
    my $timeout = AnyEvent->timer(after => 5, cb => sub { $cv->croak("timeout") });
    my $ref = connect_to_relay($port, sub {
        my ($conn) = @_;
        $conn->on(each_message => sub {
            my ($c, $msg) = @_;
            $cv->send($msg->body);
        });

        # event with valid-format id that doesn't match content hash
        my $event = Net::Nostr::Event->new(
            pubkey => 'a' x 64, kind => 1, content => 'test',
            sig => 'b' x 128, created_at => 1000, tags => [],
            id => 'c' x 64,  # wrong id
        );
        $conn->send(Net::Nostr::Message->new(type => 'EVENT', event => $event)->serialize);
    });

    my $response = $cv->recv;
    my $parsed = $JSON->decode($response);
    is($parsed->[0], 'OK', 'response is OK');
    is($parsed->[1], 'c' x 64, 'OK references the submitted id');
    is($parsed->[2], JSON::false, 'event rejected');
    like($parsed->[3], qr/^invalid:/, 'rejection has invalid: prefix');

    $relay->stop;
};

###############################################################################
# Multi-filter subscriptions
###############################################################################

subtest 'REQ with multiple filters matches on any filter' => sub {
    my $port = free_port();
    my $relay = Net::Nostr::Relay->new(verify_signatures => 0);
    $relay->start('127.0.0.1', $port);

    my @messages;
    my $cv = AnyEvent->condvar;
    my $timeout = AnyEvent->timer(after => 5, cb => sub { $cv->croak("timeout") });
    my $ref = connect_to_relay($port, sub {
        my ($conn) = @_;
        my $phase = 'store';
        $conn->on(each_message => sub {
            my ($c, $msg) = @_;
            my $parsed = $JSON->decode($msg->body);
            if ($phase eq 'store') {
                $phase = 'query';
                # subscribe with two filters: kind 2 OR kind 1
                my $f1 = Net::Nostr::Filter->new(kinds => [2]);
                my $f2 = Net::Nostr::Filter->new(kinds => [1]);
                $c->send(Net::Nostr::Message->new(type => 'REQ', subscription_id => 'multi', filters => [$f1, $f2])->serialize);
            } else {
                push @messages, $parsed;
                $cv->send() if $parsed->[0] eq 'EOSE';
            }
        });

        # store a kind 1 event (matches second filter only)
        my $event = Net::Nostr::Event->new(
            pubkey => 'a' x 64, kind => 1, content => 'multi-filter test',
            sig => 'b' x 128, created_at => 1000, tags => [],
        );
        $conn->send(Net::Nostr::Message->new(type => 'EVENT', event => $event)->serialize);
    });

    $cv->recv;
    is(scalar @messages, 2, 'got EVENT + EOSE');
    is($messages[0][0], 'EVENT', 'first message is EVENT');
    is($messages[1][0], 'EOSE', 'second message is EOSE');

    $relay->stop;
};

subtest 'broadcast matches against all filters in subscription' => sub {
    my $port = free_port();
    my $relay = Net::Nostr::Relay->new(verify_signatures => 0);
    $relay->start('127.0.0.1', $port);

    my @live_events;
    my $sub_cv = AnyEvent->condvar;
    my $sub_timeout = AnyEvent->timer(after => 5, cb => sub { $sub_cv->croak("timeout") });
    my $ref1 = connect_to_relay($port, sub {
        my ($conn) = @_;
        $conn->on(each_message => sub {
            my ($c, $msg) = @_;
            my $parsed = $JSON->decode($msg->body);
            if ($parsed->[0] eq 'EOSE') {
                $sub_cv->send();
            } elsif ($parsed->[0] eq 'EVENT') {
                push @live_events, $parsed;
            }
        });
        # subscribe with filter for kind 2 OR kind 3
        my $f1 = Net::Nostr::Filter->new(kinds => [2]);
        my $f2 = Net::Nostr::Filter->new(kinds => [3]);
        $conn->send(Net::Nostr::Message->new(type => 'REQ', subscription_id => 'multi', filters => [$f1, $f2])->serialize);
    });
    $sub_cv->recv;

    # publish a kind 3 event (matches second filter)
    my $cv = AnyEvent->condvar;
    my $timeout = AnyEvent->timer(after => 5, cb => sub { $cv->croak("timeout") });
    my $ref2 = connect_to_relay($port, sub {
        my ($conn) = @_;
        $conn->on(each_message => sub {
            my $timer; $timer = AnyEvent->timer(after => 0.2, cb => sub {
                undef $timer;
                $cv->send();
            });
        });

        my $event = Net::Nostr::Event->new(
            pubkey => 'a' x 64, kind => 3, content => 'multi broadcast',
            sig => 'b' x 128, created_at => 2000, tags => [],
        );
        $conn->send(Net::Nostr::Message->new(type => 'EVENT', event => $event)->serialize);
    });
    $cv->recv;

    is(scalar @live_events, 1, 'subscriber received event matching second filter');

    $relay->stop;
};

###############################################################################
# Broadcast
###############################################################################

subtest 'broadcast sends event to matching subscribers only' => sub {
    my $port = free_port();
    my $relay = Net::Nostr::Relay->new(verify_signatures => 0);
    $relay->start('127.0.0.1', $port);

    my $setup_cv = AnyEvent->condvar;
    $setup_cv->begin; $setup_cv->begin;
    my $setup_timeout = AnyEvent->timer(after => 5, cb => sub { $setup_cv->croak("timeout") });

    my @client1_msgs;
    my @client2_msgs;

    # Client 1: subscribes to kind 1
    my $ref1 = connect_to_relay($port, sub {
        my ($conn) = @_;
        $conn->on(each_message => sub {
            my ($c, $msg) = @_;
            my $parsed = $JSON->decode($msg->body);
            if ($parsed->[0] eq 'EOSE') {
                $setup_cv->end;
            } elsif ($parsed->[0] eq 'EVENT') {
                push @client1_msgs, $parsed;
            }
        });
        my $filter = Net::Nostr::Filter->new(kinds => [1]);
        $conn->send(Net::Nostr::Message->new(type => 'REQ', subscription_id => 'sub-kind1', filters => [$filter])->serialize);
    });

    # Client 2: subscribes to kind 2
    my $ref2 = connect_to_relay($port, sub {
        my ($conn) = @_;
        $conn->on(each_message => sub {
            my ($c, $msg) = @_;
            my $parsed = $JSON->decode($msg->body);
            if ($parsed->[0] eq 'EOSE') {
                $setup_cv->end;
            } elsif ($parsed->[0] eq 'EVENT') {
                push @client2_msgs, $parsed;
            }
        });
        my $filter = Net::Nostr::Filter->new(kinds => [2]);
        $conn->send(Net::Nostr::Message->new(type => 'REQ', subscription_id => 'sub-kind2', filters => [$filter])->serialize);
    });

    $setup_cv->recv;

    # Broadcast a kind 1 event
    my $event = Net::Nostr::Event->new(
        pubkey => 'a' x 64, kind => 1, content => 'broadcast test',
        sig => 'b' x 128, created_at => 1000, tags => [],
    );
    $relay->broadcast($event);

    # Give time for messages to arrive
    my $cv = AnyEvent->condvar;
    my $timer; $timer = AnyEvent->timer(after => 0.3, cb => sub {
        undef $timer;
        $cv->send;
    });
    $cv->recv;

    is(scalar @client1_msgs, 1, 'client 1 (kind 1) received the event');
    is(scalar @client2_msgs, 0, 'client 2 (kind 2) did not receive the event');

    $relay->stop;
};

###############################################################################
# Live subscription (new events forwarded to active subscribers)
###############################################################################

subtest 'new events are forwarded to active subscribers' => sub {
    my $port = free_port();
    my $relay = Net::Nostr::Relay->new(verify_signatures => 0);
    $relay->start('127.0.0.1', $port);

    my @live_events;

    # subscriber sets up subscription
    my $sub_cv = AnyEvent->condvar;
    my $sub_timeout = AnyEvent->timer(after => 5, cb => sub { $sub_cv->croak("timeout") });
    my $ref1 = connect_to_relay($port, sub {
        my ($conn) = @_;
        $conn->on(each_message => sub {
            my ($c, $msg) = @_;
            my $parsed = $JSON->decode($msg->body);
            if ($parsed->[0] eq 'EOSE') {
                $sub_cv->send();
            } elsif ($parsed->[0] eq 'EVENT') {
                push @live_events, $parsed;
            }
        });
        my $filter = Net::Nostr::Filter->new(kinds => [1]);
        $conn->send(Net::Nostr::Message->new(type => 'REQ', subscription_id => 'live', filters => [$filter])->serialize);
    });
    $sub_cv->recv;

    # publisher sends an event
    my $cv = AnyEvent->condvar;
    my $timeout = AnyEvent->timer(after => 5, cb => sub { $cv->croak("timeout") });
    my $ref2 = connect_to_relay($port, sub {
        my ($conn) = @_;
        $conn->on(each_message => sub {
            my ($c, $msg) = @_;
            # wait for OK then give subscriber time to receive
            my $timer; $timer = AnyEvent->timer(after => 0.2, cb => sub {
                undef $timer;
                $cv->send();
            });
        });

        my $event = Net::Nostr::Event->new(
            pubkey => 'a' x 64, kind => 1, content => 'live event',
            sig => 'b' x 128, created_at => 2000, tags => [],
        );
        $conn->send(Net::Nostr::Message->new(type => 'EVENT', event => $event)->serialize);
    });
    $cv->recv;

    is(scalar @live_events, 1, 'subscriber received live event');
    is($live_events[0][0], 'EVENT', 'message type is EVENT');

    $relay->stop;
};

###############################################################################
# POD examples: accessor methods
###############################################################################

subtest 'POD: events accessor returns stored events' => sub {
    my $port = free_port();
    my $relay = Net::Nostr::Relay->new(verify_signatures => 0);
    $relay->start('127.0.0.1', $port);

    my $cv = AnyEvent->condvar;
    my $timeout = AnyEvent->timer(after => 5, cb => sub { $cv->croak("timeout") });

    my $ref = connect_to_relay($port, sub {
        my ($conn) = @_;
        $conn->on(each_message => sub {
            my ($c, $msg) = @_;
            my $parsed = $JSON->decode($msg->body);
            $cv->send if $parsed->[0] eq 'OK';
        });
        my $event = Net::Nostr::Event->new(
            pubkey => 'a' x 64, kind => 1, content => 'stored',
            sig => 'b' x 128, created_at => 1000, tags => [],
        );
        $conn->send(Net::Nostr::Message->new(type => 'EVENT', event => $event)->serialize);
    });
    $cv->recv;

    my $events = $relay->events;
    is(ref($events), 'ARRAY', 'events returns arrayref');
    is(scalar @$events, 1, 'one event stored');
    is($events->[0]->content, 'stored', 'event content matches');

    $relay->stop;
};

subtest 'POD: connections and subscriptions accessors' => sub {
    my $port = free_port();
    my $relay = Net::Nostr::Relay->new(verify_signatures => 0);
    $relay->start('127.0.0.1', $port);

    my $cv = AnyEvent->condvar;
    my $timeout = AnyEvent->timer(after => 5, cb => sub { $cv->croak("timeout") });

    my $ref = connect_to_relay($port, sub {
        my ($conn) = @_;
        $conn->on(each_message => sub {
            my ($c, $msg) = @_;
            my $parsed = $JSON->decode($msg->body);
            $cv->send if $parsed->[0] eq 'EOSE';
        });
        my $filter = Net::Nostr::Filter->new(kinds => [1]);
        $conn->send(Net::Nostr::Message->new(type => 'REQ', subscription_id => 'test-sub', filters => [$filter])->serialize);
    });
    $cv->recv;

    my $conns = $relay->connections;
    is(ref($conns), 'HASH', 'connections returns hashref');
    ok(scalar keys %$conns >= 1, 'at least one connection');

    my $subs = $relay->subscriptions;
    is(ref($subs), 'HASH', 'subscriptions returns hashref');
    my @all_sub_ids;
    for my $conn_id (keys %$subs) {
        push @all_sub_ids, keys %{$subs->{$conn_id}};
    }
    ok((grep { $_ eq 'test-sub' } @all_sub_ids), 'test-sub subscription found');

    $relay->stop;
};

###############################################################################
# Encapsulation: returned state is a snapshot, not a live reference
###############################################################################

subtest 'connections returns a snapshot, not the internal hash' => sub {
    my $port = free_port();
    my $relay = Net::Nostr::Relay->new(verify_signatures => 0);
    $relay->start('127.0.0.1', $port);

    my $cv = AnyEvent->condvar;
    my $timeout = AnyEvent->timer(after => 5, cb => sub { $cv->croak("timeout") });

    my $ref = connect_to_relay($port, sub {
        my ($conn) = @_;
        $conn->on(each_message => sub {});
        my $t; $t = AnyEvent->timer(after => 0.1, cb => sub { undef $t; $cv->send });
    });
    $cv->recv;

    my $conns = $relay->connections;
    ok(scalar keys %$conns >= 1, 'has connections');

    # Mutate the returned hash — should not affect the relay
    %$conns = ();
    my $conns2 = $relay->connections;
    ok(scalar keys %$conns2 >= 1, 'relay connections unaffected by mutation');

    $relay->stop;
};

subtest 'subscriptions returns a snapshot, not the internal hash' => sub {
    my $port = free_port();
    my $relay = Net::Nostr::Relay->new(verify_signatures => 0);
    $relay->start('127.0.0.1', $port);

    my $cv = AnyEvent->condvar;
    my $timeout = AnyEvent->timer(after => 5, cb => sub { $cv->croak("timeout") });

    my $ref = connect_to_relay($port, sub {
        my ($conn) = @_;
        $conn->on(each_message => sub {
            my ($c, $msg) = @_;
            my $parsed = $JSON->decode($msg->body);
            $cv->send if $parsed->[0] eq 'EOSE';
        });
        my $filter = Net::Nostr::Filter->new(kinds => [1]);
        $conn->send(Net::Nostr::Message->new(type => 'REQ', subscription_id => 'snap-test', filters => [$filter])->serialize);
    });
    $cv->recv;

    my $subs = $relay->subscriptions;
    my $outer_keys = scalar keys %$subs;
    ok($outer_keys >= 1, 'has subscriptions');

    # Mutate the returned outer hash — should not affect the relay
    %$subs = ();
    my $subs2 = $relay->subscriptions;
    is(scalar keys %$subs2, $outer_keys, 'relay subscriptions unaffected by outer mutation');

    # Mutate a returned inner hash — should not affect the relay
    my ($conn_id) = keys %$subs2;
    my $inner = $subs2->{$conn_id};
    delete $inner->{'snap-test'};
    my $subs3 = $relay->subscriptions;
    ok(exists $subs3->{$conn_id}{'snap-test'}, 'relay subscriptions unaffected by inner mutation');

    $relay->stop;
};

subtest 'authenticated_pubkeys returns a deep snapshot' => sub {
    my $relay = Net::Nostr::Relay->new(verify_signatures => 0);
    # Manually seed internal auth state for testing
    $relay->{_authenticated} = { 'conn1' => { 'a' x 64 => 1 } };

    my $auth = $relay->authenticated_pubkeys;
    is(ref $auth, 'HASH', 'returns hashref');
    ok(exists $auth->{'conn1'}, 'has conn1');
    ok(exists $auth->{'conn1'}{'a' x 64}, 'has pubkey');

    # Mutate outer hash
    delete $auth->{'conn1'};
    my $auth2 = $relay->authenticated_pubkeys;
    ok(exists $auth2->{'conn1'}, 'outer mutation does not affect relay');

    # Mutate inner hash
    delete $auth2->{'conn1'}{'a' x 64};
    my $auth3 = $relay->authenticated_pubkeys;
    ok(exists $auth3->{'conn1'}{'a' x 64}, 'inner mutation does not affect relay');
};

###############################################################################
# AUTH (NIP-42)
###############################################################################

subtest 'relay sends AUTH challenge on new connection' => sub {
    my $port = free_port();
    my $relay = Net::Nostr::Relay->new(verify_signatures => 0);
    $relay->start('127.0.0.1', $port);

    my $cv = AnyEvent->condvar;
    my $timeout = AnyEvent->timer(after => 5, cb => sub { $cv->croak("timeout") });
    my $ws_client = AnyEvent::WebSocket::Client->new;
    my $conn_ref;
    $ws_client->connect("ws://127.0.0.1:$port")->cb(sub {
        my $conn = eval { shift->recv };
        return unless $conn;
        $conn_ref = $conn;
        $conn->on(each_message => sub {
            my ($c, $msg) = @_;
            $cv->send($msg->body);
        });
    });

    my $response = $cv->recv;
    my $parsed = $JSON->decode($response);
    is $parsed->[0], 'AUTH', 'first message is AUTH';
    ok defined($parsed->[1]) && length($parsed->[1]) > 0, 'challenge is non-empty string';

    $relay->stop;
};

subtest 'relay rejects kind 22242 via EVENT (must use AUTH)' => sub {
    my $port = free_port();
    my $relay = Net::Nostr::Relay->new(verify_signatures => 0);
    $relay->start('127.0.0.1', $port);

    my $cv = AnyEvent->condvar;
    my $timeout = AnyEvent->timer(after => 5, cb => sub { $cv->croak("timeout") });
    my $ref = connect_to_relay($port, sub {
        my ($conn) = @_;
        $conn->on(each_message => sub {
            my ($c, $msg) = @_;
            my $parsed = $JSON->decode($msg->body);
            $cv->send($parsed) if $parsed->[0] eq 'OK';
        });

        my $event = Net::Nostr::Event->new(
            pubkey => 'a' x 64, kind => 22242, content => '',
            sig => 'b' x 128, created_at => time(), tags => [],
        );
        $conn->send(Net::Nostr::Message->new(type => 'EVENT', event => $event)->serialize);
    });

    my $parsed = $cv->recv;
    is $parsed->[2], JSON::false, 'kind 22242 via EVENT rejected';
    like $parsed->[3], qr/auth events/, 'rejection message mentions auth';

    is scalar @{$relay->events || []}, 0, 'kind 22242 not stored';

    $relay->stop;
};

subtest 'authenticated_pubkeys accessor' => sub {
    my $relay = Net::Nostr::Relay->new(verify_signatures => 0);
    my $auth = $relay->authenticated_pubkeys;
    is ref($auth), 'HASH', 'returns hashref';
};

subtest 'relay_url accessor' => sub {
    my $relay = Net::Nostr::Relay->new(relay_url => 'wss://relay.example.com/');
    is $relay->relay_url, 'wss://relay.example.com/', 'relay_url stored';

    my $relay2 = Net::Nostr::Relay->new;
    ok !defined($relay2->relay_url), 'relay_url defaults to undef';
};

###############################################################################
# NIP-11: Relay Information Document
###############################################################################

subtest 'relay_info accessor' => sub {
    use Net::Nostr::RelayInfo;
    my $info = Net::Nostr::RelayInfo->new(name => 'Test');
    my $relay = Net::Nostr::Relay->new(relay_info => $info);
    isa_ok($relay->relay_info, 'Net::Nostr::RelayInfo');
    is($relay->relay_info->name, 'Test', 'relay_info name');
};

subtest 'relay_info defaults to undef' => sub {
    my $relay = Net::Nostr::Relay->new;
    ok(!defined($relay->relay_info), 'relay_info defaults to undef');
};

subtest 'relay with relay_info serves NIP-11 document' => sub {
    use Net::Nostr::RelayInfo;
    use AnyEvent::Handle;
    use AnyEvent::Socket qw(tcp_connect);

    my $port = free_port();
    my $relay = Net::Nostr::Relay->new(
        verify_signatures => 0,
        relay_info => Net::Nostr::RelayInfo->new(
            name    => 'Unit Test Relay',
            version => '0.0.1',
        ),
    );
    $relay->start('127.0.0.1', $port);

    my $cv = AnyEvent->condvar;
    my $timeout = AnyEvent->timer(after => 5, cb => sub { $cv->croak("timeout") });

    tcp_connect '127.0.0.1', $port, sub {
        my ($fh) = @_ or return $cv->croak("connect failed: $!");
        my $response = '';
        my $hdl; $hdl = AnyEvent::Handle->new(
            fh       => $fh,
            on_error => sub { undef $hdl; $cv->send($response) },
            on_eof   => sub { undef $hdl; $cv->send($response) },
            on_read  => sub { $response .= $_[0]->rbuf; $_[0]->rbuf = '' },
        );
        $hdl->push_write(
            "GET / HTTP/1.1\r\n" .
            "Host: 127.0.0.1:$port\r\n" .
            "Accept: application/nostr+json\r\n" .
            "Connection: close\r\n\r\n"
        );
    };

    my $resp = $cv->recv;
    like($resp, qr{HTTP/1\.1 200 OK}, 'status 200');
    like($resp, qr{application/nostr\+json}, 'content-type');
    like($resp, qr{Access-Control-Allow-Origin}, 'CORS header');

    my ($body) = $resp =~ /\r\n\r\n(.+)/s;
    my $doc = $JSON->decode($body);
    is($doc->{name}, 'Unit Test Relay', 'name in response');
    is($doc->{version}, '0.0.1', 'version in response');

    $relay->stop;
};

subtest 'relay with relay_info still accepts WebSocket' => sub {
    use Net::Nostr::RelayInfo;

    my $port = free_port();
    my $relay = Net::Nostr::Relay->new(
        verify_signatures => 0,
        relay_info => Net::Nostr::RelayInfo->new(name => 'Test'),
    );
    $relay->start('127.0.0.1', $port);

    my $cv = AnyEvent->condvar;
    my $timeout = AnyEvent->timer(after => 5, cb => sub { $cv->croak("timeout") });
    my $ref = connect_to_relay($port, sub { $cv->send('connected') });

    is($cv->recv, 'connected', 'WebSocket connects with relay_info set');
    $relay->stop;
};

###############################################################################
# Per-filter limit semantics (NIP-01)
###############################################################################

subtest 'REQ limit applies per filter, not globally' => sub {
    my $port = free_port();
    my $relay = Net::Nostr::Relay->new(verify_signatures => 0);
    $relay->start('127.0.0.1', $port);

    # Store 3 kind-1 events and 3 kind-2 events
    my @stored_ok;
    my $store_cv = AnyEvent->condvar;
    my $store_timeout = AnyEvent->timer(after => 5, cb => sub { $store_cv->croak("timeout") });
    my $ref = connect_to_relay($port, sub {
        my ($conn) = @_;
        $conn->on(each_message => sub {
            my ($c, $msg) = @_;
            my $parsed = $JSON->decode($msg->body);
            push @stored_ok, $parsed if $parsed->[0] eq 'OK';
            $store_cv->send() if @stored_ok == 6;
        });

        for my $i (1..3) {
            my $e1 = Net::Nostr::Event->new(
                pubkey => 'a' x 64, kind => 1, content => "k1-$i",
                sig => 'b' x 128, created_at => 1000 + $i, tags => [],
            );
            $conn->send(Net::Nostr::Message->new(type => 'EVENT', event => $e1)->serialize);
            my $e2 = Net::Nostr::Event->new(
                pubkey => 'a' x 64, kind => 2, content => "k2-$i",
                sig => 'b' x 128, created_at => 2000 + $i, tags => [],
            );
            $conn->send(Net::Nostr::Message->new(type => 'EVENT', event => $e2)->serialize);
        }
    });
    $store_cv->recv;

    # Query with two filters: kind 1 limit 1, kind 2 limit 3
    # The old bug would take min(1,3)=1 globally, returning only 1 event.
    # Correct: 1 kind-1 event + 3 kind-2 events = 4 total.
    my @query_msgs;
    my $query_cv = AnyEvent->condvar;
    my $query_timeout = AnyEvent->timer(after => 5, cb => sub { $query_cv->croak("timeout") });
    my $ref2 = connect_to_relay($port, sub {
        my ($conn) = @_;
        $conn->on(each_message => sub {
            my ($c, $msg) = @_;
            my $parsed = $JSON->decode($msg->body);
            push @query_msgs, $parsed;
            $query_cv->send() if $parsed->[0] eq 'EOSE';
        });

        my $f1 = Net::Nostr::Filter->new(kinds => [1], limit => 1);
        my $f2 = Net::Nostr::Filter->new(kinds => [2], limit => 3);
        $conn->send(Net::Nostr::Message->new(type => 'REQ', subscription_id => 'lim', filters => [$f1, $f2])->serialize);
    });
    $query_cv->recv;

    my @events = grep { $_->[0] eq 'EVENT' } @query_msgs;
    is(scalar @events, 4, 'per-filter limits: 1 + 3 = 4 events returned');

    my @kinds = map { $_->[2]{kind} } @events;
    is(scalar(grep { $_ == 1 } @kinds), 1, 'exactly 1 kind-1 event (limit 1)');
    is(scalar(grep { $_ == 2 } @kinds), 3, 'exactly 3 kind-2 events (limit 3)');

    $relay->stop;
};

subtest 'REQ deduplicates events matching multiple filters' => sub {
    my $port = free_port();
    my $relay = Net::Nostr::Relay->new(verify_signatures => 0);
    $relay->start('127.0.0.1', $port);

    # Store one kind-1 event from author 'aa...'
    my $store_cv = AnyEvent->condvar;
    my $store_timeout = AnyEvent->timer(after => 5, cb => sub { $store_cv->croak("timeout") });
    my $ref = connect_to_relay($port, sub {
        my ($conn) = @_;
        $conn->on(each_message => sub {
            my ($c, $msg) = @_;
            my $parsed = $JSON->decode($msg->body);
            $store_cv->send() if $parsed->[0] eq 'OK';
        });

        my $e = Net::Nostr::Event->new(
            pubkey => 'a' x 64, kind => 1, content => 'dedup test',
            sig => 'b' x 128, created_at => 1000, tags => [],
        );
        $conn->send(Net::Nostr::Message->new(type => 'EVENT', event => $e)->serialize);
    });
    $store_cv->recv;

    # Query with two filters that both match the same event
    my @query_msgs;
    my $query_cv = AnyEvent->condvar;
    my $query_timeout = AnyEvent->timer(after => 5, cb => sub { $query_cv->croak("timeout") });
    my $ref2 = connect_to_relay($port, sub {
        my ($conn) = @_;
        $conn->on(each_message => sub {
            my ($c, $msg) = @_;
            my $parsed = $JSON->decode($msg->body);
            push @query_msgs, $parsed;
            $query_cv->send() if $parsed->[0] eq 'EOSE';
        });

        my $f1 = Net::Nostr::Filter->new(kinds => [1]);
        my $f2 = Net::Nostr::Filter->new(authors => ['a' x 64]);
        $conn->send(Net::Nostr::Message->new(type => 'REQ', subscription_id => 'dup', filters => [$f1, $f2])->serialize);
    });
    $query_cv->recv;

    my @events = grep { $_->[0] eq 'EVENT' } @query_msgs;
    is(scalar @events, 1, 'duplicate event sent only once');

    $relay->stop;
};

subtest 'new() rejects unknown arguments' => sub {
    like(
        dies { Net::Nostr::Relay->new(bogus => 'value') },
        qr/unknown.+bogus/i,
        'unknown argument rejected'
    );
};

###############################################################################
# Store integration
###############################################################################

subtest 'new() accepts store option' => sub {
    use Net::Nostr::RelayStore;
    my $store = Net::Nostr::RelayStore->new;
    my $relay = Net::Nostr::Relay->new(verify_signatures => 0, store => $store);
    isa_ok($relay->store, 'Net::Nostr::RelayStore');
};

subtest 'new() accepts max_events option' => sub {
    my $relay = Net::Nostr::Relay->new(verify_signatures => 0, max_events => 100);
    is $relay->store->max_events, 100, 'max_events passed to store';
};

subtest 'new() creates default store when none given' => sub {
    my $relay = Net::Nostr::Relay->new(verify_signatures => 0);
    isa_ok($relay->store, 'Net::Nostr::RelayStore');
};

###############################################################################
# inject_event
###############################################################################

subtest 'inject_event stores event visible via events accessor' => sub {
    use lib 't/lib';
    require TestFixtures;
    my $relay = Net::Nostr::Relay->new(verify_signatures => 0);
    my $e = TestFixtures::make_event(kind => 1, content => 'injected', created_at => 1000);
    $relay->inject_event($e);
    my $events = $relay->events;
    is scalar @$events, 1, 'one event stored';
    is $events->[0]->content, 'injected', 'correct event';
};

subtest 'inject_event does not broadcast' => sub {
    my $port = free_port();
    my $relay = Net::Nostr::Relay->new(verify_signatures => 0);
    $relay->start('127.0.0.1', $port);

    my @live_events;
    my $sub_cv = AnyEvent->condvar;
    my $sub_timeout = AnyEvent->timer(after => 5, cb => sub { $sub_cv->croak("timeout") });
    my $ref1 = connect_to_relay($port, sub {
        my ($conn) = @_;
        $conn->on(each_message => sub {
            my ($c, $msg) = @_;
            my $parsed = $JSON->decode($msg->body);
            if ($parsed->[0] eq 'EOSE') {
                $sub_cv->send();
            } elsif ($parsed->[0] eq 'EVENT') {
                push @live_events, $parsed;
            }
        });
        my $filter = Net::Nostr::Filter->new(kinds => [1]);
        $conn->send(Net::Nostr::Message->new(type => 'REQ', subscription_id => 'live', filters => [$filter])->serialize);
    });
    $sub_cv->recv;

    # inject_event should NOT broadcast
    require TestFixtures;
    my $e = TestFixtures::make_event(kind => 1, content => 'silent', created_at => 5000);
    $relay->inject_event($e);

    my $cv = AnyEvent->condvar;
    my $timer; $timer = AnyEvent->timer(after => 0.3, cb => sub {
        undef $timer;
        $cv->send;
    });
    $cv->recv;

    is scalar @live_events, 0, 'inject_event did not broadcast';

    # But the event is queryable
    my @query_msgs;
    my $query_cv = AnyEvent->condvar;
    my $query_timeout = AnyEvent->timer(after => 5, cb => sub { $query_cv->croak("timeout") });
    my $ref2 = connect_to_relay($port, sub {
        my ($conn) = @_;
        $conn->on(each_message => sub {
            my ($c, $msg) = @_;
            my $parsed = $JSON->decode($msg->body);
            push @query_msgs, $parsed;
            $query_cv->send() if $parsed->[0] eq 'EOSE';
        });
        my $filter = Net::Nostr::Filter->new(kinds => [1]);
        $conn->send(Net::Nostr::Message->new(type => 'REQ', subscription_id => 'q', filters => [$filter])->serialize);
    });
    $query_cv->recv;

    my @events = grep { $_->[0] eq 'EVENT' } @query_msgs;
    is scalar @events, 1, 'injected event is queryable';

    $relay->stop;
};

subtest 'events accessor returns snapshot' => sub {
    require TestFixtures;
    my $relay = Net::Nostr::Relay->new(verify_signatures => 0);
    $relay->inject_event(TestFixtures::make_event(kind => 1, content => 'a', created_at => 1000));

    my $events = $relay->events;
    push @$events, 'garbage';
    is scalar @{$relay->events}, 1, 'mutation of returned array did not affect store';
};

###############################################################################
# Store delegation: prove protocol operations use the provided Store
###############################################################################

subtest 'EVENT via protocol stores into provided Store object' => sub {
    my $store = Net::Nostr::RelayStore->new;
    my $port = free_port();
    my $relay = Net::Nostr::Relay->new(verify_signatures => 0, store => $store);
    $relay->start('127.0.0.1', $port);

    is $store->event_count, 0, 'store starts empty';

    my $cv = AnyEvent->condvar;
    my $timeout = AnyEvent->timer(after => 5, cb => sub { $cv->croak("timeout") });
    my $ref = connect_to_relay($port, sub {
        my ($conn) = @_;
        $conn->on(each_message => sub {
            my ($c, $msg) = @_;
            my $parsed = $JSON->decode($msg->body);
            $cv->send() if $parsed->[0] eq 'OK';
        });
        my $e = Net::Nostr::Event->new(
            pubkey => 'a' x 64, kind => 1, content => 'delegation-proof',
            sig => 'b' x 128, created_at => 1000, tags => [],
        );
        $conn->send(Net::Nostr::Message->new(type => 'EVENT', event => $e)->serialize);
    });
    $cv->recv;

    is $store->event_count, 1, 'protocol EVENT went into provided store';
    is $store->all_events->[0]->content, 'delegation-proof', 'correct event in store';

    $relay->stop;
};

subtest 'REQ via protocol queries the provided Store object' => sub {
    my $store = Net::Nostr::RelayStore->new;
    my $port = free_port();
    my $relay = Net::Nostr::Relay->new(verify_signatures => 0, store => $store);

    # pre-populate the store directly — if REQ returns it, the relay used our store
    require TestFixtures;
    my $e = TestFixtures::make_event(kind => 1, content => 'from-store', created_at => 1000);
    $store->store($e);

    $relay->start('127.0.0.1', $port);

    my @events;
    my $cv = AnyEvent->condvar;
    my $timeout = AnyEvent->timer(after => 5, cb => sub { $cv->croak("timeout") });
    my $ref = connect_to_relay($port, sub {
        my ($conn) = @_;
        $conn->on(each_message => sub {
            my ($c, $msg) = @_;
            my $parsed = $JSON->decode($msg->body);
            if ($parsed->[0] eq 'EVENT') {
                push @events, $parsed->[2];
            }
            $cv->send() if $parsed->[0] eq 'EOSE';
        });
        my $filter = Net::Nostr::Filter->new(kinds => [1]);
        $conn->send(Net::Nostr::Message->new(type => 'REQ', subscription_id => 'q', filters => [$filter])->serialize);
    });
    $cv->recv;

    is scalar @events, 1, 'REQ returned event from provided store';
    is $events[0]{content}, 'from-store', 'correct content from store';

    $relay->stop;
};

subtest 'COUNT via protocol counts from the provided Store object' => sub {
    my $store = Net::Nostr::RelayStore->new;
    my $port = free_port();
    my $relay = Net::Nostr::Relay->new(verify_signatures => 0, store => $store);

    require TestFixtures;
    $store->store(TestFixtures::make_event(kind => 1, content => "e$_", created_at => $_ * 1000))
        for 1..3;

    $relay->start('127.0.0.1', $port);

    my $count_result;
    my $cv = AnyEvent->condvar;
    my $timeout = AnyEvent->timer(after => 5, cb => sub { $cv->croak("timeout") });
    my $ref = connect_to_relay($port, sub {
        my ($conn) = @_;
        $conn->on(each_message => sub {
            my ($c, $msg) = @_;
            my $parsed = $JSON->decode($msg->body);
            if ($parsed->[0] eq 'COUNT') {
                $count_result = $parsed->[2]{count};
                $cv->send();
            }
        });
        my $filter = Net::Nostr::Filter->new(kinds => [1]);
        $conn->send(Net::Nostr::Message->new(type => 'COUNT', subscription_id => 'c', filters => [$filter])->serialize);
    });
    $cv->recv;

    is $count_result, 3, 'COUNT returned count from provided store';

    $relay->stop;
};

subtest 'deletion via protocol removes from the provided Store object' => sub {
    my $store = Net::Nostr::RelayStore->new;
    my $port = free_port();
    my $relay = Net::Nostr::Relay->new(verify_signatures => 0, store => $store);
    $relay->start('127.0.0.1', $port);

    # publish an event, then delete it — check the store directly
    my $cv1 = AnyEvent->condvar;
    my $timeout1 = AnyEvent->timer(after => 5, cb => sub { $cv1->croak("timeout") });
    my $event_id;
    my $ref = connect_to_relay($port, sub {
        my ($conn) = @_;
        my $ok_count = 0;
        $conn->on(each_message => sub {
            my ($c, $msg) = @_;
            my $parsed = $JSON->decode($msg->body);
            if ($parsed->[0] eq 'OK') {
                $ok_count++;
                $cv1->send() if $ok_count == 2;
            }
        });

        # publish
        my $e = Net::Nostr::Event->new(
            pubkey => 'a' x 64, kind => 1, content => 'delete-me',
            sig => 'b' x 128, created_at => 1000, tags => [],
        );
        $event_id = $e->id;
        $conn->send(Net::Nostr::Message->new(type => 'EVENT', event => $e)->serialize);

        # delete it
        my $del = Net::Nostr::Event->new(
            pubkey => 'a' x 64, kind => 5, content => '',
            sig => 'b' x 128, created_at => 2000,
            tags => [['e', $e->id]],
        );
        $conn->send(Net::Nostr::Message->new(type => 'EVENT', event => $del)->serialize);
    });
    $cv1->recv;

    is $store->get_by_id($event_id), undef, 'deleted event gone from provided store';
    # kind 5 event should still be there
    is $store->event_count, 1, 'only deletion event remains in store';

    $relay->stop;
};

###############################################################################
# max_events eviction through protocol
###############################################################################

subtest 'max_events evicts oldest via protocol flow' => sub {
    my $port = free_port();
    my $relay = Net::Nostr::Relay->new(verify_signatures => 0, max_events => 2);
    $relay->start('127.0.0.1', $port);

    my @oks;
    my $cv = AnyEvent->condvar;
    my $timeout = AnyEvent->timer(after => 5, cb => sub { $cv->croak("timeout") });
    my $ref = connect_to_relay($port, sub {
        my ($conn) = @_;
        $conn->on(each_message => sub {
            my ($c, $msg) = @_;
            my $parsed = $JSON->decode($msg->body);
            push @oks, $parsed if $parsed->[0] eq 'OK';
            $cv->send() if @oks == 3;
        });

        for my $i (1..3) {
            my $e = Net::Nostr::Event->new(
                pubkey => 'a' x 64, kind => 1, content => "e$i",
                sig => 'b' x 128, created_at => $i * 1000, tags => [],
            );
            $conn->send(Net::Nostr::Message->new(type => 'EVENT', event => $e)->serialize);
        }
    });
    $cv->recv;

    my $events = $relay->events;
    is scalar @$events, 2, 'only 2 events retained (max_events=2)';
    my @contents = map { $_->content } @$events;
    ok !(grep { $_ eq 'e1' } @contents), 'oldest event (e1) was evicted';

    $relay->stop;
};

###############################################################################
# Rate limiting
###############################################################################

###############################################################################
# event_rate_limit constructor validation
###############################################################################

subtest 'event_rate_limit rejects bad formats' => sub {
    like(
        dies { Net::Nostr::Relay->new(verify_signatures => 0, event_rate_limit => 'abc') },
        qr/event_rate_limit must be/,
        'non-numeric rejected'
    );
    like(
        dies { Net::Nostr::Relay->new(verify_signatures => 0, event_rate_limit => '0/10') },
        qr/event_rate_limit must be/,
        'zero count rejected'
    );
    like(
        dies { Net::Nostr::Relay->new(verify_signatures => 0, event_rate_limit => '10/0') },
        qr/event_rate_limit must be/,
        'zero seconds rejected'
    );
    like(
        dies { Net::Nostr::Relay->new(verify_signatures => 0, event_rate_limit => '10') },
        qr/event_rate_limit must be/,
        'missing slash rejected'
    );
    like(
        dies { Net::Nostr::Relay->new(verify_signatures => 0, event_rate_limit => '-1/5') },
        qr/event_rate_limit must be/,
        'negative count rejected'
    );
    like(
        dies { Net::Nostr::Relay->new(verify_signatures => 0, event_rate_limit => '10/60/extra') },
        qr/event_rate_limit must be/,
        'extra slash rejected'
    );
};

###############################################################################
# Rate limiting
###############################################################################

subtest 'event_rate_limit rejects when exceeded' => sub {
    my $port = free_port();
    my $relay = Net::Nostr::Relay->new(
        verify_signatures => 0,
        event_rate_limit  => '2/10',  # 2 events per 10 seconds
    );
    $relay->start('127.0.0.1', $port);

    my @responses;
    my $cv = AnyEvent->condvar;
    my $timeout = AnyEvent->timer(after => 5, cb => sub { $cv->croak("timeout") });
    my $ref = connect_to_relay($port, sub {
        my ($conn) = @_;
        $conn->on(each_message => sub {
            my ($c, $msg) = @_;
            my $parsed = $JSON->decode($msg->body);
            push @responses, $parsed if $parsed->[0] eq 'OK';
            $cv->send() if @responses == 3;
        });

        # send 3 events rapidly — third should be rate-limited
        for my $i (1..3) {
            my $e = Net::Nostr::Event->new(
                pubkey => 'a' x 64, kind => 1, content => "rate-$i",
                sig => 'b' x 128, created_at => $i * 1000, tags => [],
            );
            $conn->send(Net::Nostr::Message->new(type => 'EVENT', event => $e)->serialize);
        }
    });
    $cv->recv;

    # first 2 should be accepted
    is $responses[0][2], JSON::true, 'first event accepted';
    is $responses[1][2], JSON::true, 'second event accepted';
    # third should be rate-limited
    is $responses[2][2], JSON::false, 'third event rejected';
    like $responses[2][3], qr/^rate-limited:/, 'rejection has rate-limited: prefix';

    $relay->stop;
};

subtest 'rate limiting is per-connection' => sub {
    my $port = free_port();
    my $relay = Net::Nostr::Relay->new(
        verify_signatures => 0,
        event_rate_limit  => '1/60',  # 1 event per 60 seconds
    );
    $relay->start('127.0.0.1', $port);

    # Connection A exhausts its limit
    my @oks_a;
    my $cv_a = AnyEvent->condvar;
    my $timeout_a = AnyEvent->timer(after => 5, cb => sub { $cv_a->croak("timeout") });
    my $ref_a = connect_to_relay($port, sub {
        my ($conn) = @_;
        $conn->on(each_message => sub {
            my ($c, $msg) = @_;
            my $parsed = $JSON->decode($msg->body);
            push @oks_a, $parsed if $parsed->[0] eq 'OK';
            $cv_a->send() if @oks_a == 2;
        });
        for my $i (1..2) {
            my $e = Net::Nostr::Event->new(
                pubkey => 'a' x 64, kind => 1, content => "a-$i",
                sig => 'b' x 128, created_at => $i * 1000, tags => [],
            );
            $conn->send(Net::Nostr::Message->new(type => 'EVENT', event => $e)->serialize);
        }
    });
    $cv_a->recv;

    is $oks_a[0][2], JSON::true, 'conn A first event accepted';
    is $oks_a[1][2], JSON::false, 'conn A second event rejected (limit 1)';

    # Connection B should have its own fresh bucket
    my @oks_b;
    my $cv_b = AnyEvent->condvar;
    my $timeout_b = AnyEvent->timer(after => 5, cb => sub { $cv_b->croak("timeout") });
    my $ref_b = connect_to_relay($port, sub {
        my ($conn) = @_;
        $conn->on(each_message => sub {
            my ($c, $msg) = @_;
            my $parsed = $JSON->decode($msg->body);
            push @oks_b, $parsed if $parsed->[0] eq 'OK';
            $cv_b->send() if @oks_b == 1;
        });
        my $e = Net::Nostr::Event->new(
            pubkey => 'c' x 64, kind => 1, content => 'b-1',
            sig => 'b' x 128, created_at => 10000, tags => [],
        );
        $conn->send(Net::Nostr::Message->new(type => 'EVENT', event => $e)->serialize);
    });
    $cv_b->recv;

    is $oks_b[0][2], JSON::true, 'conn B first event accepted (independent limit)';

    $relay->stop;
};

subtest 'events setter backward compat clears and repopulates' => sub {
    require TestFixtures;
    my $relay = Net::Nostr::Relay->new(verify_signatures => 0);
    $relay->inject_event(TestFixtures::make_event(kind => 1, content => 'a', created_at => 1000));
    $relay->inject_event(TestFixtures::make_event(kind => 1, content => 'b', created_at => 2000));
    is scalar @{$relay->events}, 2, '2 events before setter';

    # clear via setter
    $relay->events([]);
    is scalar @{$relay->events}, 0, 'setter with empty array clears';

    # repopulate via setter
    my $e = TestFixtures::make_event(kind => 1, content => 'c', created_at => 3000);
    $relay->events([$e]);
    is scalar @{$relay->events}, 1, 'setter repopulates';
    is $relay->events->[0]->content, 'c', 'correct event after setter';
};

subtest 'inject_event returns 0 for duplicate' => sub {
    require TestFixtures;
    my $relay = Net::Nostr::Relay->new(verify_signatures => 0);
    my $e = TestFixtures::make_event(kind => 1, content => 'x', created_at => 1000);
    is $relay->inject_event($e), 1, 'first inject returns 1';
    is $relay->inject_event($e), 0, 'duplicate inject returns 0';
    is scalar @{$relay->events}, 1, 'still only 1 event';
};

###############################################################################
# Resource limit constructor validation
###############################################################################

subtest 'constructor validates positive integer options' => sub {
    for my $opt (qw(max_subscriptions max_filters max_content_length
                     max_event_tags max_limit default_limit
                     created_at_lower_limit created_at_upper_limit
                     max_message_length)) {
        ok dies { Net::Nostr::Relay->new(verify_signatures => 0, $opt => 0) },
            "$opt rejects 0";
        ok dies { Net::Nostr::Relay->new(verify_signatures => 0, $opt => -1) },
            "$opt rejects negative";
        ok dies { Net::Nostr::Relay->new(verify_signatures => 0, $opt => 'abc') },
            "$opt rejects non-integer";
        ok lives { Net::Nostr::Relay->new(verify_signatures => 0, $opt => 1) },
            "$opt accepts 1";
    }
};

subtest 'constructor validates on_event callback' => sub {
    ok dies { Net::Nostr::Relay->new(verify_signatures => 0, on_event => 'not_a_sub') },
        'on_event rejects non-coderef';
    ok lives { Net::Nostr::Relay->new(verify_signatures => 0, on_event => sub { 1 }) },
        'on_event accepts coderef';
};

###############################################################################
# max_subscriptions enforcement
###############################################################################

subtest 'max_subscriptions limits subscriptions per connection' => sub {
    my $port = free_port();
    my $relay = Net::Nostr::Relay->new(
        verify_signatures   => 0,
        max_subscriptions   => 2,
    );
    $relay->start('127.0.0.1', $port);

    my $cv = AnyEvent->condvar;
    my $timeout = AnyEvent->timer(after => 5, cb => sub { $cv->croak("timeout") });
    my (@eose, @closed);
    my $ref = connect_to_relay($port, sub {
        my ($conn) = @_;
        $conn->on(each_message => sub {
            my ($c, $msg) = @_;
            my $parsed = $JSON->decode($msg->body);
            push @eose, $parsed if $parsed->[0] eq 'EOSE';
            push @closed, $parsed if $parsed->[0] eq 'CLOSED';
            $cv->send if @eose + @closed >= 3;
        });

        # Create 3 subscriptions: first two should succeed, third should fail
        my $f = Net::Nostr::Filter->new(kinds => [1]);
        $conn->send($JSON->encode(['REQ', 'sub1', $f->to_hash]));
        $conn->send($JSON->encode(['REQ', 'sub2', $f->to_hash]));
        $conn->send($JSON->encode(['REQ', 'sub3', $f->to_hash]));
    });

    $cv->recv;
    is scalar @eose, 2, 'two subscriptions accepted (EOSE)';
    is scalar @closed, 1, 'third subscription rejected (CLOSED)';
    like $closed[0][2], qr/too many subscriptions/, 'CLOSED message explains reason';

    $relay->stop;
};

subtest 'max_subscriptions allows replacing existing subscription' => sub {
    my $port = free_port();
    my $relay = Net::Nostr::Relay->new(
        verify_signatures   => 0,
        max_subscriptions   => 1,
    );
    $relay->start('127.0.0.1', $port);

    my $cv = AnyEvent->condvar;
    my $timeout = AnyEvent->timer(after => 5, cb => sub { $cv->croak("timeout") });
    my @eose;
    my $ref = connect_to_relay($port, sub {
        my ($conn) = @_;
        $conn->on(each_message => sub {
            my ($c, $msg) = @_;
            my $parsed = $JSON->decode($msg->body);
            push @eose, $parsed if $parsed->[0] eq 'EOSE';
            $cv->send if @eose >= 2;
        });

        # Same sub_id twice: second should replace, not count as new
        my $f = Net::Nostr::Filter->new(kinds => [1]);
        $conn->send($JSON->encode(['REQ', 'sub1', $f->to_hash]));
        # Small delay to ensure first REQ is processed
        my $t; $t = AnyEvent->timer(after => 0.1, cb => sub {
            undef $t;
            $conn->send($JSON->encode(['REQ', 'sub1', $f->to_hash]));
        });
    });

    $cv->recv;
    is scalar @eose, 2, 'replacing existing subscription succeeds both times';

    $relay->stop;
};

###############################################################################
# max_filters enforcement
###############################################################################

subtest 'max_filters limits filters per REQ' => sub {
    my $port = free_port();
    my $relay = Net::Nostr::Relay->new(
        verify_signatures => 0,
        max_filters       => 2,
    );
    $relay->start('127.0.0.1', $port);

    my $cv = AnyEvent->condvar;
    my $timeout = AnyEvent->timer(after => 5, cb => sub { $cv->croak("timeout") });
    my @closed;
    my $ref = connect_to_relay($port, sub {
        my ($conn) = @_;
        $conn->on(each_message => sub {
            my ($c, $msg) = @_;
            my $parsed = $JSON->decode($msg->body);
            push @closed, $parsed if $parsed->[0] eq 'CLOSED';
            $cv->send if @closed >= 1;
        });

        # REQ with 3 filters should be rejected
        my $f = { kinds => [1] };
        $conn->send($JSON->encode(['REQ', 'sub1', $f, $f, $f]));
    });

    $cv->recv;
    is scalar @closed, 1, 'REQ with too many filters rejected';
    like $closed[0][2], qr/too many filters/, 'CLOSED message explains reason';

    $relay->stop;
};

subtest 'max_filters also applies to COUNT' => sub {
    my $port = free_port();
    my $relay = Net::Nostr::Relay->new(
        verify_signatures => 0,
        max_filters       => 1,
    );
    $relay->start('127.0.0.1', $port);

    my $cv = AnyEvent->condvar;
    my $timeout = AnyEvent->timer(after => 5, cb => sub { $cv->croak("timeout") });
    my @closed;
    my $ref = connect_to_relay($port, sub {
        my ($conn) = @_;
        $conn->on(each_message => sub {
            my ($c, $msg) = @_;
            my $parsed = $JSON->decode($msg->body);
            push @closed, $parsed if $parsed->[0] eq 'CLOSED';
            $cv->send if @closed >= 1;
        });

        my $f = { kinds => [1] };
        $conn->send($JSON->encode(['COUNT', 'c1', $f, $f]));
    });

    $cv->recv;
    is scalar @closed, 1, 'COUNT with too many filters rejected';

    $relay->stop;
};

###############################################################################
# max_content_length enforcement
###############################################################################

subtest 'max_content_length rejects oversized events' => sub {
    my $port = free_port();
    my $relay = Net::Nostr::Relay->new(
        verify_signatures   => 0,
        max_content_length  => 10,
    );
    $relay->start('127.0.0.1', $port);

    my $cv = AnyEvent->condvar;
    my $timeout = AnyEvent->timer(after => 5, cb => sub { $cv->croak("timeout") });
    my $ref = connect_to_relay($port, sub {
        my ($conn) = @_;
        $conn->on(each_message => sub {
            my ($c, $msg) = @_;
            my $parsed = $JSON->decode($msg->body);
            $cv->send($parsed) if $parsed->[0] eq 'OK';
        });

        my $event = Net::Nostr::Event->new(
            pubkey => 'a' x 64, kind => 1,
            content => 'x' x 11, sig => 'b' x 128,
            created_at => 1000, tags => [],
        );
        $conn->send(Net::Nostr::Message->new(type => 'EVENT', event => $event)->serialize);
    });

    my $ok = $cv->recv;
    is $ok->[2], JSON::false, 'oversized content rejected';
    like $ok->[3], qr/content too long/, 'message explains reason';

    $relay->stop;
};

subtest 'max_content_length accepts events at limit' => sub {
    my $port = free_port();
    my $relay = Net::Nostr::Relay->new(
        verify_signatures   => 0,
        max_content_length  => 10,
    );
    $relay->start('127.0.0.1', $port);

    my $cv = AnyEvent->condvar;
    my $timeout = AnyEvent->timer(after => 5, cb => sub { $cv->croak("timeout") });
    my $ref = connect_to_relay($port, sub {
        my ($conn) = @_;
        $conn->on(each_message => sub {
            my ($c, $msg) = @_;
            my $parsed = $JSON->decode($msg->body);
            $cv->send($parsed) if $parsed->[0] eq 'OK';
        });

        my $event = Net::Nostr::Event->new(
            pubkey => 'a' x 64, kind => 1,
            content => 'x' x 10, sig => 'b' x 128,
            created_at => 1000, tags => [],
        );
        $conn->send(Net::Nostr::Message->new(type => 'EVENT', event => $event)->serialize);
    });

    my $ok = $cv->recv;
    is $ok->[2], JSON::true, 'content at limit accepted';

    $relay->stop;
};

###############################################################################
# max_event_tags enforcement
###############################################################################

subtest 'max_event_tags rejects events with too many tags' => sub {
    my $port = free_port();
    my $relay = Net::Nostr::Relay->new(
        verify_signatures => 0,
        max_event_tags    => 3,
    );
    $relay->start('127.0.0.1', $port);

    my $cv = AnyEvent->condvar;
    my $timeout = AnyEvent->timer(after => 5, cb => sub { $cv->croak("timeout") });
    my $ref = connect_to_relay($port, sub {
        my ($conn) = @_;
        $conn->on(each_message => sub {
            my ($c, $msg) = @_;
            my $parsed = $JSON->decode($msg->body);
            $cv->send($parsed) if $parsed->[0] eq 'OK';
        });

        my $event = Net::Nostr::Event->new(
            pubkey => 'a' x 64, kind => 1, content => 'hi',
            sig => 'b' x 128, created_at => 1000,
            tags => [['t', 'a'], ['t', 'b'], ['t', 'c'], ['t', 'd']],
        );
        $conn->send(Net::Nostr::Message->new(type => 'EVENT', event => $event)->serialize);
    });

    my $ok = $cv->recv;
    is $ok->[2], JSON::false, '4 tags rejected when max is 3';
    like $ok->[3], qr/too many tags/, 'message explains reason';

    $relay->stop;
};

###############################################################################
# max_limit / default_limit enforcement
###############################################################################

subtest 'max_limit caps query results' => sub {
    my $port = free_port();
    my $relay = Net::Nostr::Relay->new(
        verify_signatures => 0,
        max_limit         => 2,
    );
    # Seed 5 events
    for my $i (1..5) {
        $relay->inject_event(Net::Nostr::Event->new(
            pubkey => 'a' x 64, kind => 1, content => "e$i",
            sig => 'b' x 128, created_at => $i * 1000, tags => [],
        ));
    }
    $relay->start('127.0.0.1', $port);

    my $cv = AnyEvent->condvar;
    my $timeout = AnyEvent->timer(after => 5, cb => sub { $cv->croak("timeout") });
    my @events;
    my $ref = connect_to_relay($port, sub {
        my ($conn) = @_;
        $conn->on(each_message => sub {
            my ($c, $msg) = @_;
            my $parsed = $JSON->decode($msg->body);
            push @events, $parsed if $parsed->[0] eq 'EVENT';
            $cv->send if $parsed->[0] eq 'EOSE';
        });

        # REQ with limit=100, should be capped to max_limit=2
        $conn->send($JSON->encode(['REQ', 'sub1', { kinds => [1], limit => 100 }]));
    });

    $cv->recv;
    is scalar @events, 2, 'results capped to max_limit';

    $relay->stop;
};

subtest 'default_limit applied when no limit specified' => sub {
    my $port = free_port();
    my $relay = Net::Nostr::Relay->new(
        verify_signatures => 0,
        default_limit     => 3,
    );
    for my $i (1..5) {
        $relay->inject_event(Net::Nostr::Event->new(
            pubkey => 'a' x 64, kind => 1, content => "e$i",
            sig => 'b' x 128, created_at => $i * 1000, tags => [],
        ));
    }
    $relay->start('127.0.0.1', $port);

    my $cv = AnyEvent->condvar;
    my $timeout = AnyEvent->timer(after => 5, cb => sub { $cv->croak("timeout") });
    my @events;
    my $ref = connect_to_relay($port, sub {
        my ($conn) = @_;
        $conn->on(each_message => sub {
            my ($c, $msg) = @_;
            my $parsed = $JSON->decode($msg->body);
            push @events, $parsed if $parsed->[0] eq 'EVENT';
            $cv->send if $parsed->[0] eq 'EOSE';
        });

        # REQ without limit, should get default_limit=3
        $conn->send($JSON->encode(['REQ', 'sub1', { kinds => [1] }]));
    });

    $cv->recv;
    is scalar @events, 3, 'default_limit applied';

    $relay->stop;
};

subtest 'max_limit overrides client limit even when lower than default_limit' => sub {
    my $port = free_port();
    my $relay = Net::Nostr::Relay->new(
        verify_signatures => 0,
        default_limit     => 10,
        max_limit         => 2,
    );
    for my $i (1..5) {
        $relay->inject_event(Net::Nostr::Event->new(
            pubkey => 'a' x 64, kind => 1, content => "e$i",
            sig => 'b' x 128, created_at => $i * 1000, tags => [],
        ));
    }
    $relay->start('127.0.0.1', $port);

    my $cv = AnyEvent->condvar;
    my $timeout = AnyEvent->timer(after => 5, cb => sub { $cv->croak("timeout") });
    my @events;
    my $ref = connect_to_relay($port, sub {
        my ($conn) = @_;
        $conn->on(each_message => sub {
            my ($c, $msg) = @_;
            my $parsed = $JSON->decode($msg->body);
            push @events, $parsed if $parsed->[0] eq 'EVENT';
            $cv->send if $parsed->[0] eq 'EOSE';
        });

        # no limit set, default_limit=10 would apply, but max_limit=2 caps it
        $conn->send($JSON->encode(['REQ', 'sub1', { kinds => [1] }]));
    });

    $cv->recv;
    is scalar @events, 2, 'max_limit caps default_limit';

    $relay->stop;
};

###############################################################################
# created_at bounds enforcement
###############################################################################

subtest 'created_at_lower_limit rejects old events' => sub {
    my $port = free_port();
    my $relay = Net::Nostr::Relay->new(
        verify_signatures      => 0,
        created_at_lower_limit => 3600, # 1 hour
    );
    $relay->start('127.0.0.1', $port);

    my $cv = AnyEvent->condvar;
    my $timeout = AnyEvent->timer(after => 5, cb => sub { $cv->croak("timeout") });
    my $ref = connect_to_relay($port, sub {
        my ($conn) = @_;
        $conn->on(each_message => sub {
            my ($c, $msg) = @_;
            my $parsed = $JSON->decode($msg->body);
            $cv->send($parsed) if $parsed->[0] eq 'OK';
        });

        my $event = Net::Nostr::Event->new(
            pubkey => 'a' x 64, kind => 1, content => 'old',
            sig => 'b' x 128, created_at => 1000, tags => [],
        );
        $conn->send(Net::Nostr::Message->new(type => 'EVENT', event => $event)->serialize);
    });

    my $ok = $cv->recv;
    is $ok->[2], JSON::false, 'old event rejected';
    like $ok->[3], qr/too old/, 'message explains reason';

    $relay->stop;
};

subtest 'created_at_upper_limit rejects future events' => sub {
    my $port = free_port();
    my $relay = Net::Nostr::Relay->new(
        verify_signatures      => 0,
        created_at_upper_limit => 60, # 1 minute
    );
    $relay->start('127.0.0.1', $port);

    my $cv = AnyEvent->condvar;
    my $timeout = AnyEvent->timer(after => 5, cb => sub { $cv->croak("timeout") });
    my $ref = connect_to_relay($port, sub {
        my ($conn) = @_;
        $conn->on(each_message => sub {
            my ($c, $msg) = @_;
            my $parsed = $JSON->decode($msg->body);
            $cv->send($parsed) if $parsed->[0] eq 'OK';
        });

        my $event = Net::Nostr::Event->new(
            pubkey => 'a' x 64, kind => 1, content => 'future',
            sig => 'b' x 128, created_at => time() + 120, tags => [],
        );
        $conn->send(Net::Nostr::Message->new(type => 'EVENT', event => $event)->serialize);
    });

    my $ok = $cv->recv;
    is $ok->[2], JSON::false, 'future event rejected';
    like $ok->[3], qr/too far in the future/, 'message explains reason';

    $relay->stop;
};

subtest 'created_at_lower_limit accepts recent events' => sub {
    my $port = free_port();
    my $relay = Net::Nostr::Relay->new(
        verify_signatures      => 0,
        created_at_lower_limit => 3600,
    );
    $relay->start('127.0.0.1', $port);

    my $cv = AnyEvent->condvar;
    my $timeout = AnyEvent->timer(after => 5, cb => sub { $cv->croak("timeout") });
    my $ref = connect_to_relay($port, sub {
        my ($conn) = @_;
        $conn->on(each_message => sub {
            my ($c, $msg) = @_;
            my $parsed = $JSON->decode($msg->body);
            $cv->send($parsed) if $parsed->[0] eq 'OK';
        });

        my $event = Net::Nostr::Event->new(
            pubkey => 'a' x 64, kind => 1, content => 'recent',
            sig => 'b' x 128, created_at => time() - 60, tags => [],
        );
        $conn->send(Net::Nostr::Message->new(type => 'EVENT', event => $event)->serialize);
    });

    my $ok = $cv->recv;
    is $ok->[2], JSON::true, 'recent event accepted';

    $relay->stop;
};

###############################################################################
# max_message_length enforcement
###############################################################################

subtest 'max_message_length rejects oversized messages' => sub {
    my $port = free_port();
    my $relay = Net::Nostr::Relay->new(
        verify_signatures  => 0,
        max_message_length => 100,
    );
    $relay->start('127.0.0.1', $port);

    my $cv = AnyEvent->condvar;
    my $timeout = AnyEvent->timer(after => 5, cb => sub { $cv->croak("timeout") });
    my @notices;
    my $ref = connect_to_relay($port, sub {
        my ($conn) = @_;
        $conn->on(each_message => sub {
            my ($c, $msg) = @_;
            my $parsed = $JSON->decode($msg->body);
            push @notices, $parsed if $parsed->[0] eq 'NOTICE';
            $cv->send if @notices >= 1;
        });

        # Send a message that exceeds 100 bytes
        my $big_msg = $JSON->encode(['EVENT', {
            id => 'a' x 64, pubkey => 'b' x 64, created_at => 1000,
            kind => 1, tags => [], content => 'x' x 200, sig => 'c' x 128,
        }]);
        $conn->send($big_msg);
    });

    $cv->recv;
    is scalar @notices, 1, 'got NOTICE for oversized message';
    like $notices[0][1], qr/too large/, 'NOTICE explains reason';

    $relay->stop;
};

###############################################################################
# on_event policy callback
###############################################################################

subtest 'on_event callback can reject events' => sub {
    my $port = free_port();
    my $relay = Net::Nostr::Relay->new(
        verify_signatures => 0,
        on_event => sub {
            my ($event) = @_;
            return (0, 'blocked: spam detected') if $event->content =~ /spam/;
            return (1, '');
        },
    );
    $relay->start('127.0.0.1', $port);

    my $cv = AnyEvent->condvar;
    my $timeout = AnyEvent->timer(after => 5, cb => sub { $cv->croak("timeout") });
    my $ref = connect_to_relay($port, sub {
        my ($conn) = @_;
        $conn->on(each_message => sub {
            my ($c, $msg) = @_;
            my $parsed = $JSON->decode($msg->body);
            $cv->send($parsed) if $parsed->[0] eq 'OK';
        });

        my $event = Net::Nostr::Event->new(
            pubkey => 'a' x 64, kind => 1, content => 'this is spam',
            sig => 'b' x 128, created_at => 1000, tags => [],
        );
        $conn->send(Net::Nostr::Message->new(type => 'EVENT', event => $event)->serialize);
    });

    my $ok = $cv->recv;
    is $ok->[2], JSON::false, 'event rejected by callback';
    like $ok->[3], qr/spam detected/, 'message from callback preserved';

    $relay->stop;
};

subtest 'on_event callback accepts normal events' => sub {
    my $port = free_port();
    my $relay = Net::Nostr::Relay->new(
        verify_signatures => 0,
        on_event => sub {
            my ($event) = @_;
            return (0, 'blocked: spam') if $event->content =~ /spam/;
            return (1, '');
        },
    );
    $relay->start('127.0.0.1', $port);

    my $cv = AnyEvent->condvar;
    my $timeout = AnyEvent->timer(after => 5, cb => sub { $cv->croak("timeout") });
    my $ref = connect_to_relay($port, sub {
        my ($conn) = @_;
        $conn->on(each_message => sub {
            my ($c, $msg) = @_;
            my $parsed = $JSON->decode($msg->body);
            $cv->send($parsed) if $parsed->[0] eq 'OK';
        });

        my $event = Net::Nostr::Event->new(
            pubkey => 'a' x 64, kind => 1, content => 'hello world',
            sig => 'b' x 128, created_at => 1000, tags => [],
        );
        $conn->send(Net::Nostr::Message->new(type => 'EVENT', event => $event)->serialize);
    });

    my $ok = $cv->recv;
    is $ok->[2], JSON::true, 'normal event accepted';

    $relay->stop;
};

subtest 'on_event callback with default rejection message' => sub {
    my $port = free_port();
    my $relay = Net::Nostr::Relay->new(
        verify_signatures => 0,
        on_event => sub { return (0) },
    );
    $relay->start('127.0.0.1', $port);

    my $cv = AnyEvent->condvar;
    my $timeout = AnyEvent->timer(after => 5, cb => sub { $cv->croak("timeout") });
    my $ref = connect_to_relay($port, sub {
        my ($conn) = @_;
        $conn->on(each_message => sub {
            my ($c, $msg) = @_;
            my $parsed = $JSON->decode($msg->body);
            $cv->send($parsed) if $parsed->[0] eq 'OK';
        });

        my $event = Net::Nostr::Event->new(
            pubkey => 'a' x 64, kind => 1, content => 'test',
            sig => 'b' x 128, created_at => 1000, tags => [],
        );
        $conn->send(Net::Nostr::Message->new(type => 'EVENT', event => $event)->serialize);
    });

    my $ok = $cv->recv;
    is $ok->[2], JSON::false, 'rejected';
    like $ok->[3], qr/rejected by policy/, 'default rejection message used';

    $relay->stop;
};

###############################################################################
# Broadcast Inverted Index
###############################################################################

subtest 'broadcast: kind-filtered sub only receives matching kinds' => sub {
    my $port = free_port();
    my $relay = Net::Nostr::Relay->new(verify_signatures => 0);
    $relay->start('127.0.0.1', $port);

    my $cv = AnyEvent->condvar;
    my $timeout = AnyEvent->timer(after => 5, cb => sub { $cv->croak("timeout") });
    my @received;

    my $ref = connect_to_relay($port, sub {
        my ($conn) = @_;
        $conn->on(each_message => sub {
            my ($c, $msg) = @_;
            my $parsed = $JSON->decode($msg->body);
            if ($parsed->[0] eq 'EVENT' && $parsed->[1] eq 'kind1-only') {
                push @received, $parsed->[2];
            }
            if ($parsed->[0] eq 'OK') {
                # After second event published, check results
                my $t; $t = AnyEvent->timer(after => 0.3, cb => sub {
                    undef $t;
                    $cv->send;
                });
            }
        });

        # Subscribe to kind 1 only
        my $filter = Net::Nostr::Filter->new(kinds => [1]);
        $conn->send(Net::Nostr::Message->new(
            type => 'REQ', subscription_id => 'kind1-only',
            filters => [$filter],
        )->serialize);

        # Wait for EOSE, then publish kind 1 and kind 2
        my $t; $t = AnyEvent->timer(after => 0.3, cb => sub {
            undef $t;
            my $e1 = Net::Nostr::Event->new(
                pubkey => 'a' x 64, kind => 1, content => 'kind1 event',
                sig => 'b' x 128, created_at => 1000, tags => [],
            );
            $conn->send(Net::Nostr::Message->new(type => 'EVENT', event => $e1)->serialize);

            my $t2; $t2 = AnyEvent->timer(after => 0.2, cb => sub {
                undef $t2;
                my $e2 = Net::Nostr::Event->new(
                    pubkey => 'a' x 64, kind => 2, content => 'kind2 event',
                    sig => 'b' x 128, created_at => 1001, tags => [],
                );
                $conn->send(Net::Nostr::Message->new(type => 'EVENT', event => $e2)->serialize);
            });
        });
    });

    $cv->recv;
    is(scalar @received, 1, 'received exactly 1 broadcast');
    is($received[0]{content}, 'kind1 event', 'only kind 1 event received');

    $relay->stop;
};

subtest 'broadcast: no-kind-filter sub receives all kinds' => sub {
    my $port = free_port();
    my $relay = Net::Nostr::Relay->new(verify_signatures => 0);
    $relay->start('127.0.0.1', $port);

    my $cv = AnyEvent->condvar;
    my $timeout = AnyEvent->timer(after => 5, cb => sub { $cv->croak("timeout") });
    my @received;
    my $ok_count = 0;

    my $ref = connect_to_relay($port, sub {
        my ($conn) = @_;
        $conn->on(each_message => sub {
            my ($c, $msg) = @_;
            my $parsed = $JSON->decode($msg->body);
            if ($parsed->[0] eq 'EVENT' && $parsed->[1] eq 'all-kinds') {
                push @received, $parsed->[2];
            }
            if ($parsed->[0] eq 'OK') {
                $ok_count++;
                if ($ok_count >= 2) {
                    # Both events published; wait briefly for broadcasts to arrive
                    my $t; $t = AnyEvent->timer(after => 0.3, cb => sub {
                        undef $t;
                        $cv->send;
                    });
                }
            }
        });

        # Subscribe with no kind filter
        my $filter = Net::Nostr::Filter->new(authors => ['a' x 64]);
        $conn->send(Net::Nostr::Message->new(
            type => 'REQ', subscription_id => 'all-kinds',
            filters => [$filter],
        )->serialize);

        my $t; $t = AnyEvent->timer(after => 0.3, cb => sub {
            undef $t;
            my $e1 = Net::Nostr::Event->new(
                pubkey => 'a' x 64, kind => 1, content => 'first',
                sig => 'b' x 128, created_at => 1000, tags => [],
            );
            $conn->send(Net::Nostr::Message->new(type => 'EVENT', event => $e1)->serialize);

            my $t2; $t2 = AnyEvent->timer(after => 0.2, cb => sub {
                undef $t2;
                my $e2 = Net::Nostr::Event->new(
                    pubkey => 'a' x 64, kind => 7, content => 'second',
                    sig => 'b' x 128, created_at => 1001, tags => [],
                );
                $conn->send(Net::Nostr::Message->new(type => 'EVENT', event => $e2)->serialize);
            });
        });
    });

    $cv->recv;
    is(scalar @received, 2, 'no-kind sub receives both events');

    $relay->stop;
};

subtest 'broadcast: CLOSE removes sub from index (no phantom broadcasts)' => sub {
    my $port = free_port();
    my $relay = Net::Nostr::Relay->new(verify_signatures => 0);
    $relay->start('127.0.0.1', $port);

    my $cv = AnyEvent->condvar;
    my $timeout = AnyEvent->timer(after => 5, cb => sub { $cv->croak("timeout") });
    my @received;

    my $ref = connect_to_relay($port, sub {
        my ($conn) = @_;
        $conn->on(each_message => sub {
            my ($c, $msg) = @_;
            my $parsed = $JSON->decode($msg->body);
            if ($parsed->[0] eq 'EVENT' && $parsed->[1] eq 'temp-sub') {
                push @received, $parsed->[2];
            }
        });

        # Subscribe, then immediately CLOSE
        my $filter = Net::Nostr::Filter->new(kinds => [1]);
        $conn->send(Net::Nostr::Message->new(
            type => 'REQ', subscription_id => 'temp-sub',
            filters => [$filter],
        )->serialize);

        my $t; $t = AnyEvent->timer(after => 0.2, cb => sub {
            undef $t;
            $conn->send(Net::Nostr::Message->new(
                type => 'CLOSE', subscription_id => 'temp-sub',
            )->serialize);

            # Now publish — should NOT broadcast to closed sub
            my $t2; $t2 = AnyEvent->timer(after => 0.2, cb => sub {
                undef $t2;
                my $e = Net::Nostr::Event->new(
                    pubkey => 'a' x 64, kind => 1, content => 'after close',
                    sig => 'b' x 128, created_at => 1000, tags => [],
                );
                $conn->send(Net::Nostr::Message->new(type => 'EVENT', event => $e)->serialize);

                my $t3; $t3 = AnyEvent->timer(after => 0.3, cb => sub {
                    undef $t3;
                    $cv->send;
                });
            });
        });
    });

    $cv->recv;
    is(scalar @received, 0, 'no broadcast after CLOSE');

    $relay->stop;
};

subtest 'broadcast: replacing subscription updates index' => sub {
    my $port = free_port();
    my $relay = Net::Nostr::Relay->new(verify_signatures => 0);
    $relay->start('127.0.0.1', $port);

    my $cv = AnyEvent->condvar;
    my $timeout = AnyEvent->timer(after => 5, cb => sub { $cv->croak("timeout") });
    my @received;

    my $ref = connect_to_relay($port, sub {
        my ($conn) = @_;
        $conn->on(each_message => sub {
            my ($c, $msg) = @_;
            my $parsed = $JSON->decode($msg->body);
            if ($parsed->[0] eq 'EVENT' && $parsed->[1] eq 'my-sub') {
                push @received, $parsed->[2];
            }
            if ($parsed->[0] eq 'OK') {
                my $t; $t = AnyEvent->timer(after => 0.3, cb => sub {
                    undef $t;
                    $cv->send;
                });
            }
        });

        # Subscribe to kind 1
        my $f1 = Net::Nostr::Filter->new(kinds => [1]);
        $conn->send(Net::Nostr::Message->new(
            type => 'REQ', subscription_id => 'my-sub',
            filters => [$f1],
        )->serialize);

        my $t; $t = AnyEvent->timer(after => 0.2, cb => sub {
            undef $t;
            # Replace with kind 7
            my $f2 = Net::Nostr::Filter->new(kinds => [7]);
            $conn->send(Net::Nostr::Message->new(
                type => 'REQ', subscription_id => 'my-sub',
                filters => [$f2],
            )->serialize);

            my $t2; $t2 = AnyEvent->timer(after => 0.2, cb => sub {
                undef $t2;
                # Publish kind 1 — should NOT match replaced sub
                my $e = Net::Nostr::Event->new(
                    pubkey => 'a' x 64, kind => 1, content => 'kind1 after replace',
                    sig => 'b' x 128, created_at => 1000, tags => [],
                );
                $conn->send(Net::Nostr::Message->new(type => 'EVENT', event => $e)->serialize);
            });
        });
    });

    $cv->recv;
    is(scalar @received, 0, 'old kind not broadcast after subscription replaced');

    $relay->stop;
};

subtest 'broadcast: multiple subs on same connection with different kinds' => sub {
    my $port = free_port();
    my $relay = Net::Nostr::Relay->new(verify_signatures => 0);
    $relay->start('127.0.0.1', $port);

    my $cv = AnyEvent->condvar;
    my $timeout = AnyEvent->timer(after => 5, cb => sub { $cv->croak("timeout") });
    my %received;

    my $ref = connect_to_relay($port, sub {
        my ($conn) = @_;
        $conn->on(each_message => sub {
            my ($c, $msg) = @_;
            my $parsed = $JSON->decode($msg->body);
            if ($parsed->[0] eq 'EVENT') {
                push @{$received{$parsed->[1]}}, $parsed->[2];
            }
        });

        # Sub A: kind 1, Sub B: kind 7
        my $fA = Net::Nostr::Filter->new(kinds => [1]);
        $conn->send(Net::Nostr::Message->new(
            type => 'REQ', subscription_id => 'sub-a',
            filters => [$fA],
        )->serialize);
        my $fB = Net::Nostr::Filter->new(kinds => [7]);
        $conn->send(Net::Nostr::Message->new(
            type => 'REQ', subscription_id => 'sub-b',
            filters => [$fB],
        )->serialize);

        my $t; $t = AnyEvent->timer(after => 0.3, cb => sub {
            undef $t;
            # Publish kind 1
            my $e = Net::Nostr::Event->new(
                pubkey => 'a' x 64, kind => 1, content => 'for sub-a',
                sig => 'b' x 128, created_at => 1000, tags => [],
            );
            $conn->send(Net::Nostr::Message->new(type => 'EVENT', event => $e)->serialize);

            my $t2; $t2 = AnyEvent->timer(after => 0.3, cb => sub {
                undef $t2;
                $cv->send;
            });
        });
    });

    $cv->recv;
    is(scalar @{$received{'sub-a'} // []}, 1, 'sub-a received kind 1');
    is(scalar @{$received{'sub-b'} // []}, 0, 'sub-b did not receive kind 1');

    $relay->stop;
};

###############################################################################
# Idle Timeout
###############################################################################

subtest 'idle_timeout constructor validation' => sub {
    ok(dies { Net::Nostr::Relay->new(idle_timeout => 0) }, 'rejects zero');
    ok(dies { Net::Nostr::Relay->new(idle_timeout => -1) }, 'rejects negative');
    ok(dies { Net::Nostr::Relay->new(idle_timeout => 'abc') }, 'rejects non-numeric');
    ok(dies { Net::Nostr::Relay->new(idle_timeout => 1.5) }, 'rejects float');
    ok(lives { Net::Nostr::Relay->new(idle_timeout => 5) }, 'accepts positive integer');
};

subtest 'no idle_timeout: clients stay connected indefinitely' => sub {
    my $port = free_port();
    my $relay = Net::Nostr::Relay->new(verify_signatures => 0);
    $relay->start('127.0.0.1', $port);

    my $cv = AnyEvent->condvar;
    my $timeout = AnyEvent->timer(after => 5, cb => sub { $cv->croak("timeout") });
    my $finish_called = 0;

    my $ref = connect_to_relay($port, sub {
        my ($conn) = @_;
        $conn->on(finish => sub { $finish_called = 1 });
        # Wait 2 seconds with no activity — should NOT be disconnected
        my $t; $t = AnyEvent->timer(after => 2, cb => sub {
            undef $t;
            $cv->send($finish_called ? 'disconnected' : 'connected');
        });
    });

    my $result = $cv->recv;
    is($result, 'connected', 'no timeout by default — client stays connected');

    $relay->stop;
};

subtest 'idle_timeout disconnects idle clients' => sub {
    my $port = free_port();
    my $relay = Net::Nostr::Relay->new(
        verify_signatures => 0,
        idle_timeout => 1,
    );
    $relay->start('127.0.0.1', $port);

    my $cv = AnyEvent->condvar;
    my $timeout = AnyEvent->timer(after => 5, cb => sub { $cv->croak("timeout") });
    my $ref = connect_to_relay($port, sub {
        my ($conn) = @_;
        $conn->on(finish => sub { $cv->send('disconnected') });
        # Don't send anything — just wait to be disconnected
    });

    my $result = $cv->recv;
    is($result, 'disconnected', 'idle client was disconnected');

    $relay->stop;
};

subtest 'idle_timeout resets on activity' => sub {
    my $port = free_port();
    my $relay = Net::Nostr::Relay->new(
        verify_signatures => 0,
        idle_timeout => 2,
    );
    $relay->start('127.0.0.1', $port);

    my $cv = AnyEvent->condvar;
    my $timeout = AnyEvent->timer(after => 8, cb => sub { $cv->croak("timeout") });

    my $ref = connect_to_relay($port, sub {
        my ($conn) = @_;
        my $finish_called = 0;
        $conn->on(finish => sub { $finish_called = 1 });

        # Send a REQ after 1 second to reset the idle timer
        my $t1; $t1 = AnyEvent->timer(after => 1, cb => sub {
            undef $t1;
            my $filter = Net::Nostr::Filter->new(kinds => [1]);
            $conn->send(Net::Nostr::Message->new(
                type => 'REQ', subscription_id => 'keep-alive',
                filters => [$filter],
            )->serialize);
        });

        # Check at 2.5 seconds — should still be connected (timer was reset at 1s)
        my $t2; $t2 = AnyEvent->timer(after => 2.5, cb => sub {
            undef $t2;
            $cv->send($finish_called ? 'disconnected' : 'connected');
        });
    });

    my $result = $cv->recv;
    is($result, 'connected', 'client still connected after activity reset');

    $relay->stop;
};

subtest 'idle_timeout: cleanup on disconnect does not leak timers' => sub {
    my $port = free_port();
    my $relay = Net::Nostr::Relay->new(
        verify_signatures => 0,
        idle_timeout => 30,
    );
    $relay->start('127.0.0.1', $port);

    my $cv = AnyEvent->condvar;
    my $timeout = AnyEvent->timer(after => 5, cb => sub { $cv->croak("timeout") });

    my $ref = connect_to_relay($port, sub {
        my ($conn) = @_;
        # Client disconnects voluntarily
        $conn->close;
        my $t; $t = AnyEvent->timer(after => 0.5, cb => sub {
            undef $t;
            $cv->send;
        });
    });

    $cv->recv;
    # After client disconnect, idle timer state should be cleaned up
    my $idle_timers = $relay->_idle_timers;
    is(scalar keys %$idle_timers, 0, 'no idle timers after client disconnect');

    $relay->stop;
};

subtest 'idle_timeout: EVENT message resets timer' => sub {
    my $port = free_port();
    my $relay = Net::Nostr::Relay->new(
        verify_signatures => 0,
        idle_timeout => 2,
    );
    $relay->start('127.0.0.1', $port);

    my $cv = AnyEvent->condvar;
    my $timeout = AnyEvent->timer(after => 8, cb => sub { $cv->croak("timeout") });

    my $ref = connect_to_relay($port, sub {
        my ($conn) = @_;
        my $finish_called = 0;
        $conn->on(finish => sub { $finish_called = 1 });

        # Send an EVENT after 1 second to reset idle timer
        my $t1; $t1 = AnyEvent->timer(after => 1, cb => sub {
            undef $t1;
            my $event = Net::Nostr::Event->new(
                pubkey => 'a' x 64, kind => 1, content => 'keep alive',
                sig => 'b' x 128, created_at => 1000, tags => [],
            );
            $conn->send(Net::Nostr::Message->new(type => 'EVENT', event => $event)->serialize);
        });

        # Check at 2.5 seconds — should still be connected
        my $t2; $t2 = AnyEvent->timer(after => 2.5, cb => sub {
            undef $t2;
            $cv->send($finish_called ? 'disconnected' : 'connected');
        });
    });

    my $result = $cv->recv;
    is($result, 'connected', 'EVENT message resets idle timer');

    $relay->stop;
};

###############################################################################
# Graceful Shutdown
###############################################################################

subtest 'shutdown_timeout constructor validation' => sub {
    ok(dies { Net::Nostr::Relay->new(shutdown_timeout => 0) }, 'rejects zero');
    ok(dies { Net::Nostr::Relay->new(shutdown_timeout => -1) }, 'rejects negative');
    ok(dies { Net::Nostr::Relay->new(shutdown_timeout => 1.5) }, 'rejects float');
    ok(lives { Net::Nostr::Relay->new(shutdown_timeout => 5) }, 'accepts positive integer');
};

subtest 'graceful_stop sends NOTICE before closing' => sub {
    my $port = free_port();
    my $relay = Net::Nostr::Relay->new(
        verify_signatures => 0,
        shutdown_timeout => 2,
    );
    $relay->start('127.0.0.1', $port);

    my $cv = AnyEvent->condvar;
    my $timeout = AnyEvent->timer(after => 8, cb => sub { $cv->croak("timeout") });
    my @notices;
    my $finish_called = 0;

    my $ref = connect_to_relay($port, sub {
        my ($conn) = @_;
        $conn->on(each_message => sub {
            my ($c, $msg) = @_;
            my $parsed = $JSON->decode($msg->body);
            if ($parsed->[0] eq 'NOTICE') {
                push @notices, $parsed->[1];
            }
        });
        $conn->on(finish => sub {
            $finish_called = 1;
            $cv->send;
        });
        $relay->graceful_stop;
    });

    $cv->recv;
    ok($finish_called, 'connection closed after graceful stop');
    ok(scalar @notices >= 1, 'received shutdown NOTICE');
    like($notices[0], qr/shutting down/i, 'NOTICE mentions shutdown');

    $relay->stop;
};

subtest 'graceful_stop: new connections rejected after call' => sub {
    my $port = free_port();
    my $relay = Net::Nostr::Relay->new(
        verify_signatures => 0,
        shutdown_timeout => 3,
    );
    $relay->start('127.0.0.1', $port);

    # First connect, then graceful_stop, then try a second connection
    my $cv = AnyEvent->condvar;
    my $timeout = AnyEvent->timer(after => 8, cb => sub { $cv->croak("timeout") });

    my $ref1 = connect_to_relay($port, sub {
        my ($conn1) = @_;
        $relay->graceful_stop;

        # Try connecting after graceful_stop — guard is gone, should fail
        my $t; $t = AnyEvent->timer(after => 0.3, cb => sub {
            undef $t;
            my $client2 = AnyEvent::WebSocket::Client->new;
            $client2->connect("ws://127.0.0.1:$port")->cb(sub {
                my $conn2 = eval { shift->recv };
                if ($conn2) {
                    $cv->send('connected');
                } else {
                    $cv->send('rejected');
                }
            });
        });
    });

    my $result = $cv->recv;
    is($result, 'rejected', 'new connections rejected after graceful_stop');

    $relay->stop;
};

subtest 'graceful_stop: multiple clients all receive NOTICE' => sub {
    my $port = free_port();
    my $relay = Net::Nostr::Relay->new(
        verify_signatures => 0,
        shutdown_timeout => 2,
    );
    $relay->start('127.0.0.1', $port);

    my $cv = AnyEvent->condvar;
    my $timeout = AnyEvent->timer(after => 8, cb => sub { $cv->croak("timeout") });
    my $finish_count = 0;
    my $notice_count = 0;

    my $make_handler = sub {
        return sub {
            my ($conn) = @_;
            $conn->on(each_message => sub {
                my ($c, $msg) = @_;
                my $parsed = $JSON->decode($msg->body);
                if ($parsed->[0] eq 'NOTICE' && $parsed->[1] =~ /shutting down/i) {
                    $notice_count++;
                }
            });
            $conn->on(finish => sub {
                $finish_count++;
                $cv->send if $finish_count >= 2;
            });
        };
    };

    my $ref1 = connect_to_relay($port, $make_handler->());
    my $ref2;
    my $t; $t = AnyEvent->timer(after => 0.3, cb => sub {
        undef $t;
        $ref2 = connect_to_relay($port, sub {
            my ($conn) = @_;
            $make_handler->()->($conn);
            # Both connected, now graceful_stop
            my $t2; $t2 = AnyEvent->timer(after => 0.2, cb => sub {
                undef $t2;
                $relay->graceful_stop;
            });
        });
    });

    $cv->recv;
    is($finish_count, 2, 'both clients disconnected');
    is($notice_count, 2, 'both clients received shutdown NOTICE');

    $relay->stop;
};

subtest 'graceful_stop: default timeout is 5 seconds when unset' => sub {
    my $relay = Net::Nostr::Relay->new(verify_signatures => 0);
    is($relay->shutdown_timeout, undef, 'shutdown_timeout defaults to undef');
    # graceful_stop uses 5 when undef — just verify the accessor
};

###############################################################################
# Issue 1: Mixed-filter subscriptions must use _sub_no_kind
###############################################################################

subtest 'broadcast: mixed-filter sub (kind + no-kind) receives all matching events' => sub {
    my $port = free_port();
    my $relay = Net::Nostr::Relay->new(verify_signatures => 0);
    $relay->start('127.0.0.1', $port);

    my $pk = 'a' x 64;

    # Subscribe with two filters: one with kinds, one without (author-only).
    # A kind 7 event from $pk should match the author-only filter.
    my $cv = AnyEvent->condvar;
    my $timeout = AnyEvent->timer(after => 8, cb => sub { $cv->croak("timeout") });

    my @received;
    my $eose_count = 0;

    my $ws = AnyEvent::WebSocket::Client->new;
    my $conn_ref;
    $ws->connect("ws://127.0.0.1:$port")->cb(sub {
        my $conn = eval { shift->recv } or return;
        $conn_ref = $conn;

        $conn->on(each_message => sub {
            my ($c, $msg) = @_;
            my $parsed = $JSON->decode($msg->body);
            if ($parsed->[0] eq 'EOSE') {
                $eose_count++;
                # After EOSE, publish a kind 7 event — should match the author-only filter
                my $t; $t = AnyEvent->timer(after => 0.1, cb => sub {
                    undef $t;
                    my $event = Net::Nostr::Event->new(
                        pubkey => $pk, kind => 7, content => '+',
                        sig => 'b' x 128, created_at => 2000, tags => [],
                    );
                    $conn->send(Net::Nostr::Message->new(type => 'EVENT', event => $event)->serialize);
                });
            } elsif ($parsed->[0] eq 'EVENT' && $parsed->[1] eq 'mixed') {
                push @received, $parsed->[2];
                $cv->send;
            } elsif ($parsed->[0] eq 'OK') {
                # got OK for our published event
            }
        });

        # REQ with mixed filters: {kinds:[1]} OR {authors:[pk]}
        my $t; $t = AnyEvent->timer(after => 0.15, cb => sub {
            undef $t;
            my $req = $JSON->encode(['REQ', 'mixed',
                { kinds => [1] },
                { authors => [$pk] },
            ]);
            $conn->send($req);
        });
    });

    $cv->recv;

    is(scalar @received, 1, 'kind 7 event received via author-only filter in mixed sub');
    is($received[0]{kind}, 7, 'correct kind');

    $relay->stop;
};

###############################################################################
# Issue 3: Idle timer circular reference (weaken test)
###############################################################################

subtest 'idle_timeout: cleanup after disconnect removes timer state' => sub {
    my $port = free_port();
    my $relay = Net::Nostr::Relay->new(verify_signatures => 0, idle_timeout => 300);
    $relay->start('127.0.0.1', $port);

    my $cv = AnyEvent->condvar;
    my $timeout = AnyEvent->timer(after => 5, cb => sub { $cv->croak("timeout") });

    my $ws = AnyEvent::WebSocket::Client->new;
    $ws->connect("ws://127.0.0.1:$port")->cb(sub {
        my $conn = eval { shift->recv } or return;
        # Verify timer state was created
        my $t; $t = AnyEvent->timer(after => 0.15, cb => sub {
            undef $t;
            my $reset_count = scalar keys %{$relay->{_reset_idle} || {}};
            my $timer_count = scalar keys %{$relay->_idle_timers || {}};
            # Close the connection
            $conn->close;
            # Give server time to process the disconnect
            my $t2; $t2 = AnyEvent->timer(after => 0.3, cb => sub {
                undef $t2;
                $cv->send([$reset_count, $timer_count]);
            });
        });
    });

    my $before = $cv->recv;
    is($before->[0], 1, 'had _reset_idle entry while connected');
    is($before->[1], 1, 'had _idle_timers entry while connected');

    # After disconnect + delay, state should be cleaned up
    my $reset_idle = $relay->{_reset_idle} || {};
    is(scalar keys %$reset_idle, 0, 'no _reset_idle entries after disconnect');

    my $idle_timers = $relay->_idle_timers || {};
    is(scalar keys %$idle_timers, 0, 'no _idle_timers entries after disconnect');

    $relay->stop;
};

###############################################################################
# _relay_host_matches: URL normalization
###############################################################################

subtest '_relay_host_matches: exact match' => sub {
    ok(Net::Nostr::Relay::_relay_host_matches(
        'ws://relay.example.com', 'ws://relay.example.com'),
        'exact match');
};

subtest '_relay_host_matches: scheme case-insensitive' => sub {
    ok(Net::Nostr::Relay::_relay_host_matches(
        'WS://relay.example.com', 'ws://relay.example.com'),
        'WS vs ws');
    ok(Net::Nostr::Relay::_relay_host_matches(
        'WSS://relay.example.com', 'wss://relay.example.com'),
        'WSS vs wss');
};

subtest '_relay_host_matches: host case-insensitive' => sub {
    ok(Net::Nostr::Relay::_relay_host_matches(
        'wss://Relay.Example.COM', 'wss://relay.example.com'),
        'mixed case host');
};

subtest '_relay_host_matches: default ports' => sub {
    ok(Net::Nostr::Relay::_relay_host_matches(
        'ws://relay.example.com:80', 'ws://relay.example.com'),
        'ws explicit 80 vs implicit');
    ok(Net::Nostr::Relay::_relay_host_matches(
        'wss://relay.example.com:443', 'wss://relay.example.com'),
        'wss explicit 443 vs implicit');
    ok(!Net::Nostr::Relay::_relay_host_matches(
        'ws://relay.example.com:443', 'ws://relay.example.com'),
        'ws 443 vs implicit 80 does not match');
};

subtest '_relay_host_matches: path normalization' => sub {
    ok(Net::Nostr::Relay::_relay_host_matches(
        'wss://relay.example.com', 'wss://relay.example.com/'),
        'no path vs trailing slash');
    ok(!Net::Nostr::Relay::_relay_host_matches(
        'wss://relay.example.com/custom', 'wss://relay.example.com/'),
        'different paths do not match');
};

subtest '_relay_host_matches: mismatches' => sub {
    ok(!Net::Nostr::Relay::_relay_host_matches(
        'ws://relay.example.com', 'wss://relay.example.com'),
        'scheme mismatch');
    ok(!Net::Nostr::Relay::_relay_host_matches(
        'ws://relay.example.com', 'ws://other.example.com'),
        'host mismatch');
    ok(!Net::Nostr::Relay::_relay_host_matches(
        'ws://relay.example.com:8080', 'ws://relay.example.com:9090'),
        'port mismatch');
};

subtest '_relay_host_matches: invalid URLs return false' => sub {
    ok(!Net::Nostr::Relay::_relay_host_matches(
        'http://relay.example.com', 'ws://relay.example.com'),
        'http scheme rejected');
    ok(!Net::Nostr::Relay::_relay_host_matches(
        '', 'ws://relay.example.com'),
        'empty string rejected');
    ok(!Net::Nostr::Relay::_relay_host_matches(
        'not a url', 'ws://relay.example.com'),
        'garbage rejected');
};

subtest '_relay_host_matches: bracketed IPv6' => sub {
    ok(Net::Nostr::Relay::_relay_host_matches(
        'ws://[::1]:8080', 'ws://[::1]:8080'),
        'IPv6 loopback exact match');
    ok(Net::Nostr::Relay::_relay_host_matches(
        'wss://[2001:db8::1]', 'wss://[2001:db8::1]'),
        'IPv6 global address');
    ok(Net::Nostr::Relay::_relay_host_matches(
        'wss://[2001:DB8::1]', 'wss://[2001:db8::1]'),
        'IPv6 case-insensitive');
    ok(!Net::Nostr::Relay::_relay_host_matches(
        'ws://[::1]:8080', 'ws://[::1]:9090'),
        'IPv6 port mismatch');
    ok(!Net::Nostr::Relay::_relay_host_matches(
        'ws://[::1]', 'ws://[::2]'),
        'IPv6 address mismatch');
    ok(Net::Nostr::Relay::_relay_host_matches(
        'ws://[::1]:80', 'ws://[::1]'),
        'IPv6 default port normalization');
};

done_testing;
