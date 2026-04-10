use strictures 2;
use Test2::V0 -no_srand => 1;
use AnyEvent;
use IO::Socket::INET;
use JSON;

use lib 't/lib';
use TestFixtures qw(make_event);

use Net::Nostr::Event;
use Net::Nostr::Message;
use Net::Nostr::Client;
use Net::Nostr::Relay;
use Net::Nostr::Key;

my $PK = 'a' x 64;

###############################################################################
# The tag: ["-"] — a simple tag with a single item
###############################################################################

subtest 'the "-" tag: simple tag with single item' => sub {
    my $event = make_event(
        tags => [['-']],
    );
    my @dash = grep { $_->[0] eq '-' } @{$event->tags};
    is scalar @dash, 1, 'one "-" tag';
    is scalar @{$dash[0]}, 1, 'tag has single item';
    is $dash[0][0], '-', 'tag value is "-"';
};

subtest 'the "-" tag may be added to any event kind' => sub {
    for my $kind (1, 0, 10002, 30023) {
        my $event = Net::Nostr::Event->new(
            pubkey => $PK, kind => $kind, content => '',
            tags => [['-']],
        );
        ok $event->is_protected, "kind $kind can be protected";
    }
};

###############################################################################
# Event->is_protected
###############################################################################

subtest 'is_protected returns true when "-" tag present' => sub {
    my $event = make_event(tags => [['-']]);
    ok $event->is_protected, 'event with ["-"] is protected';
};

subtest 'is_protected returns false when no "-" tag' => sub {
    my $event = make_event(tags => [['t', 'test']]);
    ok !$event->is_protected, 'event without ["-"] is not protected';
};

subtest 'is_protected with empty tags' => sub {
    my $event = make_event(tags => []);
    ok !$event->is_protected, 'empty tags is not protected';
};

subtest 'is_protected: "-" tag among other tags' => sub {
    my $event = make_event(
        tags => [['t', 'test'], ['-'], ['e', 'aa' x 32]],
    );
    ok $event->is_protected, 'protected among other tags';
};

###############################################################################
# Relay: default behavior MUST reject events with ["-"]
###############################################################################

my $port;
{
    my $sock = IO::Socket::INET->new(
        Listen    => 1,
        LocalAddr => '127.0.0.1',
        LocalPort => 0,
    );
    $port = $sock->sockport;
    close $sock;
}

subtest 'relay default: rejects protected events' => sub {
    my $relay = Net::Nostr::Relay->new(verify_signatures => 0);
    $relay->start('127.0.0.1', $port);

    my $key = Net::Nostr::Key->new;
    my $client = Net::Nostr::Client->new;
    my ($ok_accepted, $ok_message);

    $client->on(auth => sub {});
    $client->on(ok => sub {
        my ($event_id, $accepted, $message) = @_;
        $ok_accepted = $accepted;
        $ok_message  = $message;
    });
    $client->connect("ws://127.0.0.1:$port");

    my $cv = AnyEvent->condvar;
    my $w = AnyEvent->timer(after => 0.1, cb => sub { $cv->send });
    $cv->recv;

    my $event = $key->create_event(
        kind    => 1,
        tags    => [['-']],
        content => 'hello members of the secret group',
    );
    $client->publish($event);

    $cv = AnyEvent->condvar;
    $w = AnyEvent->timer(after => 0.1, cb => sub { $cv->send });
    $cv->recv;

    is $ok_accepted, 0, 'protected event rejected by default';
    is $ok_message, 'auth-required: this event may only be published by its author',
        'rejection message matches spec example';

    $client->disconnect;
    $relay->stop;
};

###############################################################################
# Relay: accepts protected event from authenticated author
###############################################################################

subtest 'relay accepts protected event from authenticated author' => sub {
    my $relay = Net::Nostr::Relay->new(verify_signatures => 0);
    $relay->start('127.0.0.1', $port);

    my $key = Net::Nostr::Key->new;
    my $client = Net::Nostr::Client->new;
    my ($got_challenge, $ok_accepted, $ok_message);

    $client->on(auth => sub { $got_challenge = $_[0] });
    $client->on(ok => sub {
        my ($event_id, $accepted, $message) = @_;
        $ok_accepted = $accepted;
        $ok_message  = $message;
    });
    $client->connect("ws://127.0.0.1:$port");

    my $cv = AnyEvent->condvar;
    my $w = AnyEvent->timer(after => 0.1, cb => sub { $cv->send });
    $cv->recv;

    # Authenticate first
    $client->authenticate($key, "ws://127.0.0.1:$port");

    $cv = AnyEvent->condvar;
    $w = AnyEvent->timer(after => 0.1, cb => sub { $cv->send });
    $cv->recv;

    is $ok_accepted, 1, 'auth accepted';

    # Now publish protected event as authenticated author
    my $event = $key->create_event(
        kind    => 1,
        tags    => [['-']],
        content => 'hello members of the secret group',
    );
    $ok_accepted = undef;
    $ok_message  = undef;
    $client->publish($event);

    $cv = AnyEvent->condvar;
    $w = AnyEvent->timer(after => 0.1, cb => sub { $cv->send });
    $cv->recv;

    is $ok_accepted, 1, 'protected event accepted from authenticated author';

    $client->disconnect;
    $relay->stop;
};

###############################################################################
# Relay: rejects protected event from different authenticated pubkey
###############################################################################

subtest 'relay rejects protected event from different pubkey' => sub {
    my $relay = Net::Nostr::Relay->new(verify_signatures => 0);
    $relay->start('127.0.0.1', $port);

    my $key = Net::Nostr::Key->new;
    my $other_key = Net::Nostr::Key->new;
    my $client = Net::Nostr::Client->new;
    my ($got_challenge, $ok_accepted, $ok_message);

    $client->on(auth => sub { $got_challenge = $_[0] });
    $client->on(ok => sub {
        my ($event_id, $accepted, $message) = @_;
        $ok_accepted = $accepted;
        $ok_message  = $message;
    });
    $client->connect("ws://127.0.0.1:$port");

    my $cv = AnyEvent->condvar;
    my $w = AnyEvent->timer(after => 0.1, cb => sub { $cv->send });
    $cv->recv;

    # Authenticate as $key
    $client->authenticate($key, "ws://127.0.0.1:$port");

    $cv = AnyEvent->condvar;
    $w = AnyEvent->timer(after => 0.1, cb => sub { $cv->send });
    $cv->recv;

    is $ok_accepted, 1, 'auth accepted';

    # Try to publish protected event with a DIFFERENT key's pubkey
    my $event = $other_key->create_event(
        kind    => 1,
        tags    => [['-']],
        content => 'impersonation attempt',
    );
    $ok_accepted = undef;
    $ok_message  = undef;
    $client->publish($event);

    $cv = AnyEvent->condvar;
    $w = AnyEvent->timer(after => 0.1, cb => sub { $cv->send });
    $cv->recv;

    is $ok_accepted, 0, 'protected event from different pubkey rejected';
    like $ok_message, qr/auth-required/i, 'rejection message mentions auth-required';

    $client->disconnect;
    $relay->stop;
};

###############################################################################
# Spec example: the exact flow from NIP-70
###############################################################################

subtest 'spec example: event structure' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey     => '79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798',
        kind       => 1,
        tags       => [['-']],
        content    => 'hello members of the secret group',
        created_at => 1707409439,
    );
    ok $event->is_protected, 'spec example event is protected';
    is $event->kind, 1, 'spec example is kind 1';
    is $event->content, 'hello members of the secret group', 'spec example content';
};

subtest 'spec example: full reject-then-auth-then-accept flow' => sub {
    my $relay = Net::Nostr::Relay->new(verify_signatures => 0);
    $relay->start('127.0.0.1', $port);

    my $key = Net::Nostr::Key->new;
    my $client = Net::Nostr::Client->new;
    my ($ok_accepted, $ok_message, $ok_event_id);

    $client->on(auth => sub {});
    $client->on(ok => sub {
        my ($event_id, $accepted, $message) = @_;
        $ok_event_id = $event_id;
        $ok_accepted = $accepted;
        $ok_message  = $message;
    });
    $client->connect("ws://127.0.0.1:$port");

    my $cv = AnyEvent->condvar;
    my $w = AnyEvent->timer(after => 0.1, cb => sub { $cv->send });
    $cv->recv;

    # Step 1: send protected event — rejected (not authenticated)
    my $event = $key->create_event(
        kind    => 1,
        tags    => [['-']],
        content => 'hello members of the secret group',
    );
    $client->publish($event);

    $cv = AnyEvent->condvar;
    $w = AnyEvent->timer(after => 0.1, cb => sub { $cv->send });
    $cv->recv;

    is $ok_accepted, 0, 'first attempt: rejected';
    is $ok_event_id, $event->id, 'OK references correct event id';
    is $ok_message, 'auth-required: this event may only be published by its author',
        'rejection message matches spec';

    # Step 2: authenticate
    $ok_accepted = undef;
    $client->authenticate($key, "ws://127.0.0.1:$port");

    $cv = AnyEvent->condvar;
    $w = AnyEvent->timer(after => 0.1, cb => sub { $cv->send });
    $cv->recv;

    is $ok_accepted, 1, 'auth accepted';

    # Step 3: re-send same event — accepted
    $ok_accepted = undef;
    $ok_message  = undef;
    $client->publish($event);

    $cv = AnyEvent->condvar;
    $w = AnyEvent->timer(after => 0.1, cb => sub { $cv->send });
    $cv->recv;

    is $ok_accepted, 1, 'second attempt: accepted after auth';

    $client->disconnect;
    $relay->stop;
};

###############################################################################
# Non-protected events remain unaffected
###############################################################################

subtest 'non-protected events accepted normally' => sub {
    my $relay = Net::Nostr::Relay->new(verify_signatures => 0);
    $relay->start('127.0.0.1', $port);

    my $key = Net::Nostr::Key->new;
    my $client = Net::Nostr::Client->new;
    my ($ok_accepted, $ok_message);

    $client->on(auth => sub {});
    $client->on(ok => sub {
        my ($event_id, $accepted, $message) = @_;
        $ok_accepted = $accepted;
        $ok_message  = $message;
    });
    $client->connect("ws://127.0.0.1:$port");

    my $cv = AnyEvent->condvar;
    my $w = AnyEvent->timer(after => 0.1, cb => sub { $cv->send });
    $cv->recv;

    # Normal event without ["-"] should be accepted without auth
    my $event = $key->create_event(
        kind    => 1,
        tags    => [['t', 'test']],
        content => 'public message',
    );
    $client->publish($event);

    $cv = AnyEvent->condvar;
    $w = AnyEvent->timer(after => 0.1, cb => sub { $cv->send });
    $cv->recv;

    is $ok_accepted, 1, 'non-protected event accepted without auth';

    $client->disconnect;
    $relay->stop;
};

done_testing;
