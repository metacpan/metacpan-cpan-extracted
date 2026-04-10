#!/usr/bin/perl

# NIP-13: Proof of Work
# https://github.com/nostr-protocol/nips/blob/master/13.md

use strictures 2;

use Test2::V0 -no_srand => 1;
use AnyEvent;
use IO::Socket::INET;
use JSON;

use lib 't/lib';
use TestFixtures qw(make_event);

use Net::Nostr::Event;
use Net::Nostr::Key;
use Net::Nostr::Client;
use Net::Nostr::Relay;
use Net::Nostr::Message;

###############################################################################
# Difficulty calculation
###############################################################################

subtest 'difficulty is number of leading zero bits in the id' => sub {
    # From the spec: "000000000e9d97a1ab09fc381030b346cdd7a142ad57e6df0b46dc9bef6c7e2d"
    # has difficulty 36 (36 leading 0 bits)
    my $event = make_event(
        id      => '000000000e9d97a1ab09fc381030b346cdd7a142ad57e6df0b46dc9bef6c7e2d',
        pubkey  => 'a' x 64,
        kind    => 1,
        content => '',
        sig     => 'a' x 128,
    );
    is $event->difficulty, 36, 'id with 9 leading hex zeroes then 0 has 36 leading zero bits';
};

subtest 'difficulty counts partial hex digits correctly' => sub {
    # From the spec: "002f..." is "0000 0000 0010 1111..." = 10 leading zeroes
    my $event = make_event(
        id      => '002f' . ('a' x 60),
        pubkey  => 'a' x 64,
        kind    => 1,
        content => '',
        sig     => 'a' x 128,
    );
    is $event->difficulty, 10, '002f... has 10 leading zero bits';
};

subtest 'difficulty of all-zero nibble is 4 bits' => sub {
    my $event = make_event(
        id      => '0' . ('f' x 63),
        pubkey  => 'a' x 64,
        kind    => 1,
        content => '',
        sig     => 'a' x 128,
    );
    is $event->difficulty, 4, 'single leading 0 hex = 4 bits';
};

subtest 'difficulty handles hex digits 1-7 correctly' => sub {
    # 1 = 0001 -> 3 leading zero bits
    my $e1 = make_event(id => '1' . ('f' x 63), pubkey => 'a' x 64, kind => 1, content => '', sig => 'a' x 128);
    is $e1->difficulty, 3, 'leading 1 = 3 zero bits';

    # 2 = 0010 -> 2 leading zero bits
    my $e2 = make_event(id => '2' . ('f' x 63), pubkey => 'a' x 64, kind => 1, content => '', sig => 'a' x 128);
    is $e2->difficulty, 2, 'leading 2 = 2 zero bits';

    # 3 = 0011 -> 2 leading zero bits
    my $e3 = make_event(id => '3' . ('f' x 63), pubkey => 'a' x 64, kind => 1, content => '', sig => 'a' x 128);
    is $e3->difficulty, 2, 'leading 3 = 2 zero bits';

    # 4 = 0100 -> 1 leading zero bit
    my $e4 = make_event(id => '4' . ('f' x 63), pubkey => 'a' x 64, kind => 1, content => '', sig => 'a' x 128);
    is $e4->difficulty, 1, 'leading 4 = 1 zero bit';

    # 7 = 0111 -> 1 leading zero bit
    my $e7 = make_event(id => '7' . ('f' x 63), pubkey => 'a' x 64, kind => 1, content => '', sig => 'a' x 128);
    is $e7->difficulty, 1, 'leading 7 = 1 zero bit';

    # 8 = 1000 -> 0 leading zero bits
    my $e8 = make_event(id => '8' . ('f' x 63), pubkey => 'a' x 64, kind => 1, content => '', sig => 'a' x 128);
    is $e8->difficulty, 0, 'leading 8 = 0 zero bits';

    # f = 1111 -> 0 leading zero bits
    my $ef = make_event(id => 'f' . ('f' x 63), pubkey => 'a' x 64, kind => 1, content => '', sig => 'a' x 128);
    is $ef->difficulty, 0, 'leading f = 0 zero bits';
};

subtest 'difficulty with multiple leading zero bytes' => sub {
    # 0000 = 16 bits of zeros
    my $event = make_event(
        id      => '0000' . ('f' x 60),
        pubkey  => 'a' x 64,
        kind    => 1,
        content => '',
        sig     => 'a' x 128,
    );
    is $event->difficulty, 16, '0000... = 16 leading zero bits';
};

subtest 'difficulty of all-zero id is 256' => sub {
    my $event = make_event(
        id      => '0' x 64,
        pubkey  => 'a' x 64,
        kind    => 1,
        content => '',
        sig     => 'a' x 128,
    );
    is $event->difficulty, 256, 'all-zero id = 256 bits of difficulty';
};

###############################################################################
# Nonce tag and committed target difficulty
###############################################################################

subtest 'nonce tag structure from spec example' => sub {
    # From the spec: {"content": "It's just me mining my own business", "tags": [["nonce", "1", "21"]]}
    my $event = make_event(
        pubkey  => 'a' x 64,
        kind    => 1,
        content => "It's just me mining my own business",
        tags    => [['nonce', '1', '21']],
        sig     => 'a' x 128,
    );
    my $nonce_tag = $event->tags->[0];
    is $nonce_tag->[0], 'nonce', 'first element is "nonce"';
    is $nonce_tag->[1], '1', 'second element is the nonce counter';
    is $nonce_tag->[2], '21', 'third element is the target difficulty';
};

subtest 'committed_target_difficulty extracts target from nonce tag' => sub {
    my $event = make_event(
        pubkey  => 'a' x 64,
        kind    => 1,
        content => '',
        tags    => [['nonce', '776797', '20']],
        sig     => 'a' x 128,
    );
    is $event->committed_target_difficulty, 20, 'committed target is 20';
};

subtest 'committed_target_difficulty returns undef when no nonce tag' => sub {
    my $event = make_event(
        pubkey  => 'a' x 64,
        kind    => 1,
        content => '',
        tags    => [],
        sig     => 'a' x 128,
    );
    is $event->committed_target_difficulty, undef, 'no nonce tag = undef';
};

subtest 'committed_target_difficulty returns undef when nonce has no third entry' => sub {
    my $event = make_event(
        pubkey  => 'a' x 64,
        kind    => 1,
        content => '',
        tags    => [['nonce', '123']],
        sig     => 'a' x 128,
    );
    is $event->committed_target_difficulty, undef, 'nonce without target = undef';
};

###############################################################################
# Example mined note from the spec
###############################################################################

subtest 'spec example mined note' => sub {
    my $event = Net::Nostr::Event->new(
        id         => '000006d8c378af1779d2feebc7603a125d99eca0ccf1085959b307f64e5dd358',
        pubkey     => 'a48380f4cfcc1ad5378294fcac36439770f9c878dd880ffa94bb74ea54a6f243',
        created_at => 1651794653,
        kind       => 1,
        tags       => [['nonce', '776797', '20']],
        content    => "It's just me mining my own business",
        sig        => '284622fc0a3f4f1303455d5175f7ba962a3300d136085b9566801bc2e0699de0c7e31e44c81fb40ad9049173742e904713c3594a1da0fc5d2382a25c11aba977',
    );

    # "000006d8" in binary: 0000 0000 0000 0000 0000 0110 ...
    # That's 21 leading zero bits
    is $event->difficulty, 21, 'spec example has difficulty 21';
    is $event->committed_target_difficulty, 20, 'spec example committed target is 20';
    ok $event->difficulty >= $event->committed_target_difficulty,
        'actual difficulty meets committed target';
};

###############################################################################
# Mining
###############################################################################

subtest 'mine produces event meeting target difficulty' => sub {
    my $key = Net::Nostr::Key->new;
    my $event = $key->create_event(
        kind    => 1,
        content => 'mining test',
        tags    => [],
    );
    my $mined = $event->mine(8);
    ok $mined->difficulty >= 8, 'mined event meets target difficulty of 8';
};

subtest 'mine adds nonce tag with committed target' => sub {
    my $key = Net::Nostr::Key->new;
    my $event = $key->create_event(
        kind    => 1,
        content => 'mining nonce test',
        tags    => [],
    );
    my $mined = $event->mine(1);
    my @nonce_tags = grep { $_->[0] eq 'nonce' } @{$mined->tags};
    is scalar @nonce_tags, 1, 'exactly one nonce tag';
    is $nonce_tags[0][2], '1', 'nonce tag third entry is committed target difficulty';
    ok defined $nonce_tags[0][1], 'nonce tag has a counter value';
};

subtest 'mine preserves existing tags' => sub {
    my $key = Net::Nostr::Key->new;
    my $event = $key->create_event(
        kind    => 1,
        content => 'tagged mining',
        tags    => [['t', 'nostr'], ['p', 'b' x 64]],
    );
    my $mined = $event->mine(1);
    my @t_tags = grep { $_->[0] eq 't' } @{$mined->tags};
    my @p_tags = grep { $_->[0] eq 'p' } @{$mined->tags};
    is scalar @t_tags, 1, 'original t tag preserved';
    is scalar @p_tags, 1, 'original p tag preserved';
    is $t_tags[0][1], 'nostr', 't tag value preserved';
};

subtest 'mine recalculates event id' => sub {
    my $key = Net::Nostr::Key->new;
    my $event = $key->create_event(
        kind    => 1,
        content => 'id recalc test',
        tags    => [],
    );
    my $orig_id = $event->id;
    my $mined = $event->mine(8);
    isnt $mined->id, $orig_id, 'mined event has different id (unless incredibly lucky)';
    # Verify the id is correctly computed
    is $mined->id, Digest::SHA::sha256_hex($mined->json_serialize),
        'mined event id matches sha256 of its serialization';
};

subtest 'mine returns new event, does not mutate original' => sub {
    my $key = Net::Nostr::Key->new;
    my $event = $key->create_event(
        kind    => 1,
        content => 'immutability test',
        tags    => [],
    );
    my $orig_id = $event->id;
    my $orig_tags = $event->tags;
    my $mined = $event->mine(1);
    is $event->id, $orig_id, 'original event id unchanged';
    is $event->tags, $orig_tags, 'original event tags unchanged';
};

subtest 'mine updates created_at during mining' => sub {
    # "It is recommended to update the created_at as well during this process"
    my $key = Net::Nostr::Key->new;
    my $event = $key->create_event(
        kind       => 1,
        content    => 'timestamp test',
        tags       => [],
        created_at => 1000000000,
    );
    is $event->created_at, 1000000000, 'original has old timestamp';
    my $mined = $event->mine(1);
    ok $mined->created_at >= time() - 5, 'mined event created_at is updated to current time';
};

subtest 'mine replaces existing nonce tag' => sub {
    my $key = Net::Nostr::Key->new;
    my $event = $key->create_event(
        kind    => 1,
        content => 'replace nonce',
        tags    => [['nonce', '0', '5']],
    );
    my $mined = $event->mine(4);
    my @nonce_tags = grep { $_->[0] eq 'nonce' } @{$mined->tags};
    is scalar @nonce_tags, 1, 'still exactly one nonce tag after re-mining';
    is $nonce_tags[0][2], '4', 'committed target updated to new target';
};

###############################################################################
# Delegated Proof of Work
###############################################################################

subtest 'PoW can be computed without a signature (delegated PoW)' => sub {
    # Since the NIP-01 note id does not commit to any signature,
    # PoW can be outsourced to PoW providers
    my $event = make_event(
        pubkey  => 'a' x 64,
        kind    => 1,
        content => 'delegated pow',
        tags    => [],
    );
    my $mined = $event->mine(8);
    ok $mined->difficulty >= 8, 'unsigned event can be mined';
    ok !defined $mined->sig, 'mined event has no signature (delegated)';
};

###############################################################################
# Relay: min_pow_difficulty
###############################################################################

sub find_port {
    my $sock = IO::Socket::INET->new(
        Listen => 1, LocalAddr => '127.0.0.1', LocalPort => 0,
    );
    my $port = $sock->sockport;
    close $sock;
    return $port;
}

subtest 'relay accepts events meeting min_pow_difficulty' => sub {
    my $port = find_port();
    my $relay = Net::Nostr::Relay->new(
        verify_signatures    => 0,
        min_pow_difficulty   => 1,
    );
    $relay->start('127.0.0.1', $port);

    my $client = Net::Nostr::Client->new;
    $client->connect("ws://127.0.0.1:$port");

    my $cv = AnyEvent->condvar;
    my ($ok_id, $ok_accepted, $ok_message);

    $client->on(ok => sub { ($ok_id, $ok_accepted, $ok_message) = @_; $cv->send });

    my $key = Net::Nostr::Key->new;
    my $event = $key->create_event(kind => 1, content => 'pow test', tags => []);
    my $mined = $event->mine(1);
    $key->sign_event($mined);
    $client->publish($mined);

    my $timer = AnyEvent->timer(after => 5, cb => sub { $cv->send });
    $cv->recv;

    ok defined $ok_id, 'received OK message';
    ok $ok_accepted, 'event with sufficient PoW accepted';

    $relay->stop;
};

subtest 'relay rejects events below min_pow_difficulty' => sub {
    my $port = find_port();
    my $relay = Net::Nostr::Relay->new(
        verify_signatures    => 0,
        min_pow_difficulty   => 32,
    );
    $relay->start('127.0.0.1', $port);

    my $client = Net::Nostr::Client->new;
    $client->connect("ws://127.0.0.1:$port");

    my $cv = AnyEvent->condvar;
    my ($ok_id, $ok_accepted, $ok_message);

    $client->on(ok => sub { ($ok_id, $ok_accepted, $ok_message) = @_; $cv->send });

    # Send an event with no PoW at all
    my $event = make_event(
        pubkey  => 'a' x 64,
        kind    => 1,
        content => 'no pow',
        tags    => [],
        sig     => 'a' x 128,
    );
    $client->publish($event);

    my $timer = AnyEvent->timer(after => 5, cb => sub { $cv->send });
    $cv->recv;

    ok defined $ok_id, 'received OK message';
    ok !$ok_accepted, 'event without PoW rejected';
    like $ok_message, qr/pow/i, 'rejection message mentions PoW';

    $relay->stop;
};

subtest 'relay rejects events where committed target is below min_pow_difficulty' => sub {
    # "if you require 40 bits to reply to your thread and see a committed target of 30,
    #  you can safely reject it even if the note has 40 bits difficulty"
    # The relay checks committed target before actual difficulty, so we don't
    # need to actually mine -- just construct an event with a low commitment.
    my $port = find_port();
    my $relay = Net::Nostr::Relay->new(
        verify_signatures    => 0,
        min_pow_difficulty   => 16,
    );
    $relay->start('127.0.0.1', $port);

    my $client = Net::Nostr::Client->new;
    $client->connect("ws://127.0.0.1:$port");

    my $cv = AnyEvent->condvar;
    my ($ok_id, $ok_accepted, $ok_message);

    $client->on(ok => sub { ($ok_id, $ok_accepted, $ok_message) = @_; $cv->send });

    # Event with nonce tag committing to only 8 bits (below the relay's 16)
    my $event = make_event(
        pubkey  => 'a' x 64,
        kind    => 1,
        content => 'low commitment',
        tags    => [['nonce', '12345', '8']],
        sig     => 'a' x 128,
    );
    $client->publish($event);

    my $timer = AnyEvent->timer(after => 5, cb => sub { $cv->send });
    $cv->recv;

    ok defined $ok_id, 'received OK message';
    ok !$ok_accepted, 'event with low committed target rejected';
    like $ok_message, qr/pow/i, 'rejection mentions PoW';

    $relay->stop;
};

subtest 'relay MAY reject events with missing difficulty commitment' => sub {
    # "clients MAY reject a note matching a target difficulty if it is missing a difficulty commitment"
    my $port = find_port();
    my $relay = Net::Nostr::Relay->new(
        verify_signatures    => 0,
        min_pow_difficulty   => 8,
    );
    $relay->start('127.0.0.1', $port);

    my $client = Net::Nostr::Client->new;
    $client->connect("ws://127.0.0.1:$port");

    my $cv = AnyEvent->condvar;
    my ($ok_id, $ok_accepted, $ok_message);

    $client->on(ok => sub { ($ok_id, $ok_accepted, $ok_message) = @_; $cv->send });

    # Event with sufficient actual difficulty but no nonce tag at all
    my $event = make_event(
        id      => '00' . ('a' x 62),  # 8 bits difficulty
        pubkey  => 'a' x 64,
        kind    => 1,
        content => 'no commitment',
        tags    => [],
        sig     => 'a' x 128,
    );
    $client->publish($event);

    my $timer = AnyEvent->timer(after => 5, cb => sub { $cv->send });
    $cv->recv;

    ok defined $ok_id, 'received OK message';
    ok !$ok_accepted, 'event without difficulty commitment rejected';

    $relay->stop;
};

subtest 'relay with no min_pow_difficulty accepts any event (default disabled)' => sub {
    my $port = find_port();
    my $relay = Net::Nostr::Relay->new(verify_signatures => 0);
    $relay->start('127.0.0.1', $port);

    my $client = Net::Nostr::Client->new;
    $client->connect("ws://127.0.0.1:$port");

    my $cv = AnyEvent->condvar;
    my ($ok_id, $ok_accepted, $ok_message);

    $client->on(ok => sub { ($ok_id, $ok_accepted, $ok_message) = @_; $cv->send });

    my $event = make_event(
        pubkey  => 'a' x 64,
        kind    => 1,
        content => 'no pow required',
        tags    => [],
        sig     => 'a' x 128,
    );
    $client->publish($event);

    my $timer = AnyEvent->timer(after => 5, cb => sub { $cv->send });
    $cv->recv;

    ok defined $ok_id, 'received OK message';
    ok $ok_accepted, 'event accepted when no min_pow_difficulty set';

    $relay->stop;
};

done_testing;
