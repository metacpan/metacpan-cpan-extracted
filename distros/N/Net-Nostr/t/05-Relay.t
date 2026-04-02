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

done_testing;
