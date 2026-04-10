#!/usr/bin/perl

# NIP-09: Event Deletion Request
# https://github.com/nostr-protocol/nips/blob/master/09.md

use strictures 2;

use Test2::V0 -no_srand => 1;
use AnyEvent;
use IO::Socket::INET;

use lib 't/lib';
use TestFixtures qw(make_event);

use Net::Nostr::Event;
use Net::Nostr::Filter;
use Net::Nostr::Deletion;
use Net::Nostr::Client;
use Net::Nostr::Relay;

my $alice_pk = 'a' x 64;
my $bob_pk   = 'b' x 64;
my $event1_id = '1' x 64;
my $event2_id = '2' x 64;

###############################################################################
# Deletion request is a kind 5 event
###############################################################################

subtest 'deletion request produces kind 5 event' => sub {
    my $del = Net::Nostr::Deletion->new;
    $del->add_event($event1_id, kind => 1);
    my $event = $del->to_event(pubkey => $alice_pk);
    is($event->kind, 5, 'kind is 5');
    isa_ok($event, 'Net::Nostr::Event');
};

###############################################################################
# e tags reference events to delete
###############################################################################

subtest 'deletion request has e tags for each event' => sub {
    my $del = Net::Nostr::Deletion->new;
    $del->add_event($event1_id, kind => 1);
    $del->add_event($event2_id, kind => 1);
    my $event = $del->to_event(pubkey => $alice_pk);

    my @e_tags = grep { $_->[0] eq 'e' } @{$event->tags};
    is(scalar @e_tags, 2, 'two e tags');
    is($e_tags[0][1], $event1_id, 'first e tag');
    is($e_tags[1][1], $event2_id, 'second e tag');
};

###############################################################################
# k tags SHOULD be included for each kind being deleted
###############################################################################

subtest 'deletion request includes k tags for event kinds' => sub {
    my $del = Net::Nostr::Deletion->new;
    $del->add_event($event1_id, kind => 1);
    $del->add_event($event2_id, kind => 30023);
    my $event = $del->to_event(pubkey => $alice_pk);

    my @k_tags = grep { $_->[0] eq 'k' } @{$event->tags};
    my @kinds = sort map { $_->[1] } @k_tags;
    is(\@kinds, ['1', '30023'], 'k tags for both kinds');
};

subtest 'k tags are deduplicated' => sub {
    my $del = Net::Nostr::Deletion->new;
    $del->add_event($event1_id, kind => 1);
    $del->add_event($event2_id, kind => 1);
    my $event = $del->to_event(pubkey => $alice_pk);

    my @k_tags = grep { $_->[0] eq 'k' } @{$event->tags};
    is(scalar @k_tags, 1, 'one k tag for kind 1');
    is($k_tags[0][1], '1', 'k tag value is stringified kind');
};

###############################################################################
# a tags for addressable events
###############################################################################

subtest 'deletion request supports a tags for addressable events' => sub {
    my $del = Net::Nostr::Deletion->new;
    $del->add_address("30023:${alice_pk}:my-article", kind => 30023);
    my $event = $del->to_event(pubkey => $alice_pk);

    my @a_tags = grep { $_->[0] eq 'a' } @{$event->tags};
    is(scalar @a_tags, 1, 'one a tag');
    is($a_tags[0][1], "30023:${alice_pk}:my-article", 'a tag value');

    my @k_tags = grep { $_->[0] eq 'k' } @{$event->tags};
    is(scalar @k_tags, 1, 'k tag for addressable kind');
    is($k_tags[0][1], '30023', 'k tag value');
};

###############################################################################
# content MAY contain a reason
###############################################################################

subtest 'deletion request with reason' => sub {
    my $del = Net::Nostr::Deletion->new(reason => 'posted by accident');
    $del->add_event($event1_id, kind => 1);
    my $event = $del->to_event(pubkey => $alice_pk);
    is($event->content, 'posted by accident', 'content has reason');
};

subtest 'deletion request without reason has empty content' => sub {
    my $del = Net::Nostr::Deletion->new;
    $del->add_event($event1_id, kind => 1);
    my $event = $del->to_event(pubkey => $alice_pk);
    is($event->content, '', 'content is empty');
};

###############################################################################
# Parse from existing kind 5 event
###############################################################################

subtest 'from_event parses a kind 5 event' => sub {
    my $event = make_event(
        pubkey => $alice_pk, kind => 5,
        content => 'these posts were published by accident',
        tags => [
            ['e', $event1_id],
            ['e', $event2_id],
            ['a', "30023:${alice_pk}:my-article"],
            ['k', '1'],
            ['k', '30023'],
        ],
    );
    my $del = Net::Nostr::Deletion->from_event($event);
    is($del->event_ids, [$event1_id, $event2_id], 'event ids');
    is($del->addresses, ["30023:${alice_pk}:my-article"], 'addresses');
    is($del->reason, 'these posts were published by accident', 'reason');
};

subtest 'from_event croaks on non-kind-5 event' => sub {
    my $event = make_event(pubkey => $alice_pk, kind => 1, content => 'hello');
    ok(dies { Net::Nostr::Deletion->from_event($event) }, 'croaks on kind 1');
};

###############################################################################
# applies_to checks pubkey match
###############################################################################

subtest 'applies_to returns true when pubkeys match' => sub {
    my $target = make_event(id => $event1_id, pubkey => $alice_pk, kind => 1, content => 'hello');
    my $del_event = make_event(
        pubkey => $alice_pk, kind => 5, content => '',
        tags => [['e', $event1_id], ['k', '1']],
    );
    my $del = Net::Nostr::Deletion->from_event($del_event);
    ok($del->applies_to($target, $alice_pk), 'applies when pubkeys match and event referenced');
};

subtest 'applies_to returns false when pubkeys differ' => sub {
    my $target = make_event(id => $event1_id, pubkey => $bob_pk, kind => 1, content => 'hello');
    my $del_event = make_event(
        pubkey => $alice_pk, kind => 5, content => '',
        tags => [['e', $event1_id], ['k', '1']],
    );
    my $del = Net::Nostr::Deletion->from_event($del_event);
    ok(!$del->applies_to($target, $alice_pk), 'does not apply when target pubkey differs from deletion pubkey');
};

subtest 'applies_to returns false when event not referenced' => sub {
    my $target = make_event(id => $event2_id, pubkey => $alice_pk, kind => 1, content => 'hello');
    my $del_event = make_event(
        pubkey => $alice_pk, kind => 5, content => '',
        tags => [['e', $event1_id], ['k', '1']],
    );
    my $del = Net::Nostr::Deletion->from_event($del_event);
    ok(!$del->applies_to($target, $alice_pk), 'does not apply when event not referenced');
};

###############################################################################
# Validation
###############################################################################

subtest 'add_event croaks without kind' => sub {
    my $del = Net::Nostr::Deletion->new;
    ok(dies { $del->add_event($event1_id) }, 'croaks without kind');
};

subtest 'add_event rejects invalid event_id' => sub {
    my $del = Net::Nostr::Deletion->new;
    ok(dies { $del->add_event('not-hex', kind => 1) }, 'rejects non-hex');
    ok(dies { $del->add_event('abcd1234', kind => 1) }, 'rejects too short');
    ok(dies { $del->add_event('A' x 64, kind => 1) }, 'rejects uppercase');
    ok(dies { $del->add_event('g' x 64, kind => 1) }, 'rejects non-hex chars');
    like(dies { $del->add_event('xyz', kind => 1) }, qr/64-char lowercase hex/, 'error message');
};

subtest 'add_address croaks without kind' => sub {
    my $del = Net::Nostr::Deletion->new;
    ok(dies { $del->add_address("30023:${alice_pk}:test") }, 'croaks without kind');
};

###############################################################################
# Round-trip: Deletion -> Event -> Deletion
###############################################################################

subtest 'round-trip through event preserves data' => sub {
    my $del = Net::Nostr::Deletion->new(reason => 'oops');
    $del->add_event($event1_id, kind => 1);
    $del->add_event($event2_id, kind => 30023);
    $del->add_address("30023:${alice_pk}:my-article", kind => 30023);

    my $event = $del->to_event(pubkey => $alice_pk);
    my $del2 = Net::Nostr::Deletion->from_event($event);

    is($del2->event_ids, [$event1_id, $event2_id], 'event ids round-trip');
    is($del2->addresses, ["30023:${alice_pk}:my-article"], 'addresses round-trip');
    is($del2->reason, 'oops', 'reason round-trips');
};

###############################################################################
# Relay: deletion request deletes matching stored events
###############################################################################

subtest 'relay deletes stored events when receiving kind 5' => sub {
    my $port = free_port();
    my $relay = Net::Nostr::Relay->new(verify_signatures => 0);
    $relay->start('127.0.0.1', $port);

    my $note = make_event(
        pubkey => $alice_pk, kind => 1,
        content => 'delete me', sig => 'a' x 128,
    );

    my $del = Net::Nostr::Deletion->new(reason => 'oops');
    $del->add_event($note->id, kind => 1);
    my $del_event = $del->to_event(pubkey => $alice_pk, sig => 'a' x 128);

    my $client = Net::Nostr::Client->new;
    my $cv = AnyEvent->condvar;
    my $timeout = AnyEvent->timer(after => 5, cb => sub { $cv->croak("timeout") });

    my @events;
    my $ok_count = 0;

    $client->on(ok => sub {
        $ok_count++;
        if ($ok_count == 2) {
            # Both published, now query for kind 1
            $client->subscribe('q', Net::Nostr::Filter->new(kinds => [1], authors => [$alice_pk]));
        }
    });

    $client->on(event => sub {
        my ($sub_id, $event) = @_;
        push @events, $event;
    });

    $client->on(eose => sub { $cv->send });

    $client->connect("ws://127.0.0.1:$port");
    $client->publish($note);
    $client->publish($del_event);

    $cv->recv;

    is(scalar @events, 0, 'deleted event no longer returned by relay');

    $client->disconnect;
    $relay->stop;
};

subtest 'relay only deletes events with matching pubkey' => sub {
    my $port = free_port();
    my $relay = Net::Nostr::Relay->new(verify_signatures => 0);
    $relay->start('127.0.0.1', $port);

    # Bob's note
    my $bob_note = make_event(
        pubkey => $bob_pk, kind => 1,
        content => 'bob post', sig => 'a' x 128,
    );

    # Alice tries to delete Bob's note
    my $del = Net::Nostr::Deletion->new;
    $del->add_event($bob_note->id, kind => 1);
    my $del_event = $del->to_event(pubkey => $alice_pk, sig => 'a' x 128);

    my $client = Net::Nostr::Client->new;
    my $cv = AnyEvent->condvar;
    my $timeout = AnyEvent->timer(after => 5, cb => sub { $cv->croak("timeout") });

    my @events;
    my $ok_count = 0;

    $client->on(ok => sub {
        $ok_count++;
        if ($ok_count == 2) {
            $client->subscribe('q', Net::Nostr::Filter->new(kinds => [1], authors => [$bob_pk]));
        }
    });

    $client->on(event => sub {
        my ($sub_id, $event) = @_;
        push @events, $event;
    });

    $client->on(eose => sub { $cv->send });

    $client->connect("ws://127.0.0.1:$port");
    $client->publish($bob_note);
    $client->publish($del_event);

    $cv->recv;

    is(scalar @events, 1, 'bob event NOT deleted by alice');
    is($events[0]->content, 'bob post', 'bob event still intact');

    $client->disconnect;
    $relay->stop;
};

subtest 'relay keeps the deletion request event itself' => sub {
    my $port = free_port();
    my $relay = Net::Nostr::Relay->new(verify_signatures => 0);
    $relay->start('127.0.0.1', $port);

    my $note = make_event(
        pubkey => $alice_pk, kind => 1,
        content => 'delete me', sig => 'a' x 128,
    );

    my $del = Net::Nostr::Deletion->new;
    $del->add_event($note->id, kind => 1);
    my $del_event = $del->to_event(pubkey => $alice_pk, sig => 'a' x 128);

    my $client = Net::Nostr::Client->new;
    my $cv = AnyEvent->condvar;
    my $timeout = AnyEvent->timer(after => 5, cb => sub { $cv->croak("timeout") });

    my @events;
    my $ok_count = 0;

    $client->on(ok => sub {
        $ok_count++;
        if ($ok_count == 2) {
            # Query for kind 5 deletion requests
            $client->subscribe('q', Net::Nostr::Filter->new(kinds => [5], authors => [$alice_pk]));
        }
    });

    $client->on(event => sub {
        my ($sub_id, $event) = @_;
        push @events, $event;
    });

    $client->on(eose => sub { $cv->send });

    $client->connect("ws://127.0.0.1:$port");
    $client->publish($note);
    $client->publish($del_event);

    $cv->recv;

    is(scalar @events, 1, 'deletion request event is stored');
    is($events[0]->kind, 5, 'stored event is the deletion request');

    $client->disconnect;
    $relay->stop;
};

subtest 'relay deletes addressable events via a tag' => sub {
    my $port = free_port();
    my $relay = Net::Nostr::Relay->new(verify_signatures => 0);
    $relay->start('127.0.0.1', $port);

    my $article = make_event(
        pubkey => $alice_pk, kind => 30023,
        content => 'my article', sig => 'a' x 128,
        tags => [['d', 'my-article']],
        created_at => 1000,
    );

    my $del = Net::Nostr::Deletion->new;
    $del->add_address("30023:${alice_pk}:my-article", kind => 30023);
    my $del_event = $del->to_event(pubkey => $alice_pk, sig => 'a' x 128, created_at => 2000);

    my $client = Net::Nostr::Client->new;
    my $cv = AnyEvent->condvar;
    my $timeout = AnyEvent->timer(after => 5, cb => sub { $cv->croak("timeout") });

    my @events;
    my $ok_count = 0;

    $client->on(ok => sub {
        $ok_count++;
        if ($ok_count == 2) {
            $client->subscribe('q', Net::Nostr::Filter->new(kinds => [30023], authors => [$alice_pk]));
        }
    });

    $client->on(event => sub {
        my ($sub_id, $event) = @_;
        push @events, $event;
    });

    $client->on(eose => sub { $cv->send });

    $client->connect("ws://127.0.0.1:$port");
    $client->publish($article);
    $client->publish($del_event);

    $cv->recv;

    is(scalar @events, 0, 'addressable event deleted via a tag');

    $client->disconnect;
    $relay->stop;
};

###############################################################################
# Deletion of a deletion has no effect
###############################################################################

subtest 'deletion of a deletion request has no effect' => sub {
    my $port = free_port();
    my $relay = Net::Nostr::Relay->new(verify_signatures => 0);
    $relay->start('127.0.0.1', $port);

    # Original deletion request
    my $del1 = Net::Nostr::Deletion->new;
    $del1->add_event($event1_id, kind => 1);
    my $del1_event = $del1->to_event(pubkey => $alice_pk, sig => 'a' x 128, created_at => 1000);

    # Attempt to delete the deletion
    my $del2 = Net::Nostr::Deletion->new;
    $del2->add_event($del1_event->id, kind => 5);
    my $del2_event = $del2->to_event(pubkey => $alice_pk, sig => 'a' x 128, created_at => 2000);

    my $client = Net::Nostr::Client->new;
    my $cv = AnyEvent->condvar;
    my $timeout = AnyEvent->timer(after => 5, cb => sub { $cv->croak("timeout") });

    my @events;
    my $ok_count = 0;

    $client->on(ok => sub {
        $ok_count++;
        if ($ok_count == 2) {
            $client->subscribe('q', Net::Nostr::Filter->new(kinds => [5], authors => [$alice_pk]));
        }
    });

    $client->on(event => sub {
        my ($sub_id, $event) = @_;
        push @events, $event;
    });

    $client->on(eose => sub { $cv->send });

    $client->connect("ws://127.0.0.1:$port");
    $client->publish($del1_event);
    $client->publish($del2_event);

    $cv->recv;

    # Both deletion requests should still be stored
    is(scalar @events, 2, 'both deletion requests still stored');

    $client->disconnect;
    $relay->stop;
};

###############################################################################
# applies_to checks a tags for replaceable events
###############################################################################

subtest 'applies_to matches replaceable events via a tag' => sub {
    my $target = make_event(
        pubkey => $alice_pk, kind => 10000, content => 'replaceable',
        created_at => 1000,
    );
    my $del_event = make_event(
        pubkey => $alice_pk, kind => 5, content => '',
        tags => [['a', "10000:${alice_pk}:"], ['k', '10000']],
        created_at => 2000,
    );
    my $del = Net::Nostr::Deletion->from_event($del_event);
    ok($del->applies_to($target, $alice_pk), 'applies_to matches replaceable event via a tag');
};

subtest 'applies_to matches kind 0 replaceable via a tag' => sub {
    my $target = make_event(
        pubkey => $alice_pk, kind => 0, content => '{"name":"test"}',
        created_at => 1000,
    );
    my $del_event = make_event(
        pubkey => $alice_pk, kind => 5, content => '',
        tags => [['a', "0:${alice_pk}:"], ['k', '0']],
        created_at => 2000,
    );
    my $del = Net::Nostr::Deletion->from_event($del_event);
    ok($del->applies_to($target, $alice_pk), 'applies_to matches kind 0 via a tag');
};

subtest 'relay deletes replaceable events via a tag' => sub {
    my $port = free_port();
    my $relay = Net::Nostr::Relay->new(verify_signatures => 0);
    $relay->start('127.0.0.1', $port);

    my $replaceable = make_event(
        pubkey => $alice_pk, kind => 10000,
        content => 'replaceable event', sig => 'a' x 128,
        created_at => 1000,
    );

    my $del = Net::Nostr::Deletion->new;
    $del->add_address("10000:${alice_pk}:", kind => 10000);
    my $del_event = $del->to_event(pubkey => $alice_pk, sig => 'a' x 128, created_at => 2000);

    my $client = Net::Nostr::Client->new;
    my $cv = AnyEvent->condvar;
    my $timeout = AnyEvent->timer(after => 5, cb => sub { $cv->croak("timeout") });

    my @events;
    my $ok_count = 0;

    $client->on(ok => sub {
        $ok_count++;
        if ($ok_count == 2) {
            $client->subscribe('q', Net::Nostr::Filter->new(kinds => [10000], authors => [$alice_pk]));
        }
    });

    $client->on(event => sub {
        my ($sub_id, $event) = @_;
        push @events, $event;
    });

    $client->on(eose => sub { $cv->send });

    $client->connect("ws://127.0.0.1:$port");
    $client->publish($replaceable);
    $client->publish($del_event);

    $cv->recv;

    is(scalar @events, 0, 'replaceable event deleted via a tag');

    $client->disconnect;
    $relay->stop;
};

###############################################################################
# Helpers
###############################################################################

sub free_port {
    my $sock = IO::Socket::INET->new(
        Listen => 1, LocalAddr => '127.0.0.1', LocalPort => 0,
    );
    my $port = $sock->sockport;
    close $sock;
    return $port;
}

subtest 'new() rejects unknown arguments' => sub {
    like(
        dies { Net::Nostr::Deletion->new(reason => 'spam', bogus => 'value') },
        qr/unknown.+bogus/i,
        'unknown argument rejected'
    );
};

done_testing;
