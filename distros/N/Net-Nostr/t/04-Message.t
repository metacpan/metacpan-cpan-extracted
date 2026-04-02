#!/usr/bin/perl

use strictures 2;

use Test2::V0 -no_srand => 1;
use JSON;

use lib 't/lib';
use TestFixtures qw(%FIATJAF_EVENT);

use Net::Nostr::Event;
use Net::Nostr::Filter;
use Net::Nostr::Message;

my $EVENT = Net::Nostr::Event->new(%FIATJAF_EVENT);

###############################################################################
# Client-to-relay: EVENT
###############################################################################

subtest 'event_msg() produces ["EVENT", <event hash>]' => sub {
    my $json = Net::Nostr::Message->new(type => 'EVENT', event => $EVENT)->serialize;
    my $decoded = JSON::decode_json($json);
    is($decoded->[0], 'EVENT', 'first element is EVENT');
    is(ref($decoded->[1]), 'HASH', 'second element is event object');
    is($decoded->[1]{id}, $EVENT->id, 'event id');
    is($decoded->[1]{pubkey}, $EVENT->pubkey, 'event pubkey');
    is($decoded->[1]{created_at}, $EVENT->created_at, 'event created_at');
    is($decoded->[1]{kind}, $EVENT->kind, 'event kind');
    is($decoded->[1]{tags}, $EVENT->tags, 'event tags');
    is($decoded->[1]{content}, $EVENT->content, 'event content');
    is($decoded->[1]{sig}, $EVENT->sig, 'event sig');
    is(scalar keys %{$decoded->[1]}, 7, 'event has exactly 7 fields');
    is(scalar @$decoded, 2, 'message has exactly 2 elements');
};

###############################################################################
# Client-to-relay: REQ
###############################################################################

subtest 'req_msg() with one filter' => sub {
    my $filter = Net::Nostr::Filter->new(kinds => [1], limit => 10);
    my $json = Net::Nostr::Message->new(type => 'REQ', subscription_id => 'sub1', filters => [$filter])->serialize;
    my $decoded = JSON::decode_json($json);
    is($decoded->[0], 'REQ', 'first element is REQ');
    is($decoded->[1], 'sub1', 'subscription id');
    is(ref($decoded->[2]), 'HASH', 'third element is filter');
    is($decoded->[2]{kinds}, [1], 'filter kinds');
    is($decoded->[2]{limit}, 10, 'filter limit');
    is(scalar @$decoded, 3, 'message has 3 elements');
};

subtest 'req_msg() with multiple filters' => sub {
    my $f1 = Net::Nostr::Filter->new(kinds => [1]);
    my $f2 = Net::Nostr::Filter->new(kinds => [0], authors => ['aa' x 32]);
    my $json = Net::Nostr::Message->new(type => 'REQ', subscription_id => 'sub2', filters => [$f1, $f2])->serialize;
    my $decoded = JSON::decode_json($json);
    is($decoded->[0], 'REQ', 'first element is REQ');
    is($decoded->[1], 'sub2', 'subscription id');
    is($decoded->[2]{kinds}, [1], 'first filter');
    is($decoded->[3]{kinds}, [0], 'second filter');
    is($decoded->[3]{authors}, ['aa' x 32], 'second filter authors');
    is(scalar @$decoded, 4, 'message has 4 elements');
};

subtest 'req_msg() with filter containing tag filters' => sub {
    my $f = Net::Nostr::Filter->new('#e' => ['aa' x 32], kinds => [1]);
    my $json = Net::Nostr::Message->new(type => 'REQ', subscription_id => 'sub3', filters => [$f])->serialize;
    my $decoded = JSON::decode_json($json);
    is($decoded->[2]{'#e'}, ['aa' x 32], 'tag filter in message');
};

subtest 'req_msg() validates subscription_id' => sub {
    my $f = Net::Nostr::Filter->new(kinds => [1]);
    ok(dies { Net::Nostr::Message->new(type => 'REQ', subscription_id => '', filters => [$f])->serialize }, 'empty subscription id rejected');
    ok(dies { Net::Nostr::Message->new(type => 'REQ', subscription_id => 'x' x 65, filters => [$f])->serialize }, 'subscription id > 64 chars rejected');
    ok(lives { Net::Nostr::Message->new(type => 'REQ', subscription_id => 'x' x 64, filters => [$f])->serialize }, 'subscription id of 64 chars accepted');
    ok(lives { Net::Nostr::Message->new(type => 'REQ', subscription_id => 'a', filters => [$f])->serialize }, 'single char subscription id accepted');
};

subtest 'req_msg() requires at least one filter' => sub {
    ok(dies { Net::Nostr::Message->new(type => 'REQ', subscription_id => 'sub1', filters => [])->serialize }, 'no filters rejected');
};

###############################################################################
# Client-to-relay: CLOSE
###############################################################################

subtest 'close_msg() produces ["CLOSE", <subscription_id>]' => sub {
    my $json = Net::Nostr::Message->new(type => 'CLOSE', subscription_id => 'sub1')->serialize;
    my $decoded = JSON::decode_json($json);
    is($decoded->[0], 'CLOSE', 'first element is CLOSE');
    is($decoded->[1], 'sub1', 'subscription id');
    is(scalar @$decoded, 2, 'message has exactly 2 elements');
};

subtest 'close_msg() validates subscription_id' => sub {
    ok(dies { Net::Nostr::Message->new(type => 'CLOSE', subscription_id => '')->serialize }, 'empty subscription id rejected');
    ok(dies { Net::Nostr::Message->new(type => 'CLOSE', subscription_id => 'x' x 65)->serialize }, 'subscription id > 64 chars rejected');
    ok(lives { Net::Nostr::Message->new(type => 'CLOSE', subscription_id => 'x' x 64)->serialize }, 'subscription id of 64 chars accepted');
};

###############################################################################
# Relay-to-client: OK, EVENT, EOSE (already tested via round-trip)
###############################################################################

subtest 'notice_msg() produces ["NOTICE", <message>]' => sub {
    my $json = Net::Nostr::Message->new(type => 'NOTICE', message => 'hello world')->serialize;
    my $decoded = JSON::decode_json($json);
    is($decoded->[0], 'NOTICE', 'first element is NOTICE');
    is($decoded->[1], 'hello world', 'message');
    is(scalar @$decoded, 2, 'message has exactly 2 elements');
};

subtest 'closed_msg() produces ["CLOSED", <sub_id>, <message>]' => sub {
    my $json = Net::Nostr::Message->new(type => 'CLOSED', subscription_id => 'sub1', message => 'error: shutting down')->serialize;
    my $decoded = JSON::decode_json($json);
    is($decoded->[0], 'CLOSED', 'first element is CLOSED');
    is($decoded->[1], 'sub1', 'subscription id');
    is($decoded->[2], 'error: shutting down', 'message');
    is(scalar @$decoded, 3, 'message has exactly 3 elements');
};

###############################################################################
# croak in public functions
###############################################################################

subtest 'public functions croak on bad input' => sub {
    my $f = Net::Nostr::Filter->new(kinds => [1]);
    # croak sets the error location to the caller, not the callee
    like(dies { Net::Nostr::Message->new(type => 'REQ', subscription_id => '', filters => [$f])->serialize },
        qr/at \Q${\__FILE__}\E/, 'req_msg croaks from caller perspective');
    like(dies { Net::Nostr::Message->new(type => 'CLOSE', subscription_id => '')->serialize },
        qr/at \Q${\__FILE__}\E/, 'close_msg croaks from caller perspective');
    like(dies { Net::Nostr::Message->parse('not json') },
        qr/at \Q${\__FILE__}\E/, 'parse croaks from caller perspective');
    like(dies { Net::Nostr::Message->parse('[]') },
        qr/at \Q${\__FILE__}\E/, 'parse (empty array) croaks from caller perspective');
};

###############################################################################
# Parsing relay messages
###############################################################################

subtest 'parse() relay EVENT message' => sub {
    my $raw = JSON->new->utf8->encode(['EVENT', 'sub1', $EVENT->to_hash]);
    my $msg = Net::Nostr::Message->parse($raw);
    is($msg->type, 'EVENT', 'type is EVENT');
    is($msg->subscription_id, 'sub1', 'subscription id');
    is(ref($msg->event), 'Net::Nostr::Event', 'event is a Net::Nostr::Event');
    is($msg->event->id, $EVENT->id, 'event id preserved');
    is($msg->event->pubkey, $EVENT->pubkey, 'event pubkey preserved');
    is($msg->event->created_at, $EVENT->created_at, 'event created_at preserved');
    is($msg->event->kind, $EVENT->kind, 'event kind preserved');
    is($msg->event->tags, $EVENT->tags, 'event tags preserved');
    is($msg->event->content, $EVENT->content, 'event content preserved');
    is($msg->event->sig, $EVENT->sig, 'event sig preserved');
};

subtest 'parse() OK message (accepted)' => sub {
    my $raw = JSON->new->utf8->encode(['OK', 'aa' x 32, JSON::true, '']);
    my $msg = Net::Nostr::Message->parse($raw);
    is($msg->type, 'OK', 'type is OK');
    is($msg->event_id, 'aa' x 32, 'event id');
    is($msg->accepted, 1, 'accepted is true');
    is($msg->message, '', 'message is empty string');
};

subtest 'parse() OK message (rejected with prefix)' => sub {
    my $raw = JSON->new->utf8->encode([
        'OK', 'bb' x 32, JSON::false, 'blocked: you are banned'
    ]);
    my $msg = Net::Nostr::Message->parse($raw);
    is($msg->type, 'OK', 'type is OK');
    is($msg->event_id, 'bb' x 32, 'event id');
    is($msg->accepted, 0, 'accepted is false');
    is($msg->message, 'blocked: you are banned', 'full message');
    is($msg->prefix, 'blocked', 'machine-readable prefix extracted');
};

subtest 'parse() OK message prefix extraction' => sub {
    my @prefixes = qw(duplicate pow blocked rate-limited invalid restricted mute error);
    for my $prefix (@prefixes) {
        my $raw = JSON->new->utf8->encode([
            'OK', 'cc' x 32, JSON::false, "$prefix: details"
        ]);
        my $msg = Net::Nostr::Message->parse($raw);
        is($msg->prefix, $prefix, "prefix '$prefix' extracted");
    }
};

subtest 'parse() OK accepted with message' => sub {
    my $raw = JSON->new->utf8->encode([
        'OK', 'aa' x 32, JSON::true, 'duplicate: already have this event'
    ]);
    my $msg = Net::Nostr::Message->parse($raw);
    is($msg->accepted, 1, 'accepted is true');
    is($msg->prefix, 'duplicate', 'prefix extracted even when accepted');
    is($msg->message, 'duplicate: already have this event', 'full message preserved');
};

subtest 'parse() EOSE message' => sub {
    my $raw = JSON->new->utf8->encode(['EOSE', 'sub1']);
    my $msg = Net::Nostr::Message->parse($raw);
    is($msg->type, 'EOSE', 'type is EOSE');
    is($msg->subscription_id, 'sub1', 'subscription id');
};

subtest 'parse() CLOSED message' => sub {
    my $raw = JSON->new->utf8->encode([
        'CLOSED', 'sub1', 'error: shutting down idle subscription'
    ]);
    my $msg = Net::Nostr::Message->parse($raw);
    is($msg->type, 'CLOSED', 'type is CLOSED');
    is($msg->subscription_id, 'sub1', 'subscription id');
    is($msg->message, 'error: shutting down idle subscription', 'full message');
    is($msg->prefix, 'error', 'machine-readable prefix extracted');
};

subtest 'parse() CLOSED message with all standard prefixes' => sub {
    my @prefixes = qw(duplicate pow blocked rate-limited invalid restricted mute error);
    for my $prefix (@prefixes) {
        my $raw = JSON->new->utf8->encode([
            'CLOSED', 'sub1', "$prefix: details"
        ]);
        my $msg = Net::Nostr::Message->parse($raw);
        is($msg->prefix, $prefix, "CLOSED prefix '$prefix' extracted");
    }
};

subtest 'parse() NOTICE message' => sub {
    my $raw = JSON->new->utf8->encode(['NOTICE', 'this is a human-readable notice']);
    my $msg = Net::Nostr::Message->parse($raw);
    is($msg->type, 'NOTICE', 'type is NOTICE');
    is($msg->message, 'this is a human-readable notice', 'message');
};

###############################################################################
# parse() error handling
###############################################################################

subtest 'parse() rejects invalid JSON' => sub {
    ok(dies { Net::Nostr::Message->parse('not json') }, 'invalid JSON rejected');
};

subtest 'parse() rejects non-array JSON' => sub {
    ok(dies { Net::Nostr::Message->parse('{"type":"EVENT"}') }, 'JSON object rejected');
};

subtest 'parse() rejects empty array' => sub {
    ok(dies { Net::Nostr::Message->parse('[]') }, 'empty array rejected');
};

subtest 'parse() rejects unknown message type' => sub {
    my $raw = JSON->new->utf8->encode(['UNKNOWN', 'data']);
    ok(dies { Net::Nostr::Message->parse($raw) }, 'unknown type rejected');
};

###############################################################################
# parse() validates structure of each message type
###############################################################################

subtest 'parse() EVENT requires 3 elements' => sub {
    my $raw = JSON->new->utf8->encode(['EVENT', 'sub1']);
    ok(dies { Net::Nostr::Message->parse($raw) }, 'EVENT with 2 elements rejected');
};

subtest 'parse() OK requires 4 elements' => sub {
    my $raw = JSON->new->utf8->encode(['OK', 'aa' x 32, JSON::true]);
    ok(dies { Net::Nostr::Message->parse($raw) }, 'OK with 3 elements rejected');
};

subtest 'parse() EOSE requires 2 elements' => sub {
    my $raw = JSON->new->utf8->encode(['EOSE']);
    ok(dies { Net::Nostr::Message->parse($raw) }, 'EOSE with 1 element rejected');
};

subtest 'parse() CLOSED requires 3 elements' => sub {
    my $raw = JSON->new->utf8->encode(['CLOSED', 'sub1']);
    ok(dies { Net::Nostr::Message->parse($raw) }, 'CLOSED with 2 elements rejected');
};

subtest 'parse() NOTICE requires 2 elements' => sub {
    my $raw = JSON->new->utf8->encode(['NOTICE']);
    ok(dies { Net::Nostr::Message->parse($raw) }, 'NOTICE with 1 element rejected');
};

###############################################################################
# Round-trip: construct then parse
###############################################################################

subtest 'event_msg round-trips through parse as client EVENT' => sub {
    # Client EVENT is ["EVENT", <event>] — parse handles relay EVENT ["EVENT", <sub>, <event>]
    # so this tests construction format, not parse round-trip
    my $json = Net::Nostr::Message->new(type => 'EVENT', event => $EVENT)->serialize;
    my $decoded = JSON::decode_json($json);
    is($decoded->[0], 'EVENT', 'client EVENT constructed');
    is(scalar @$decoded, 2, 'client EVENT has 2 elements (no subscription_id)');
};

subtest 'parse preserves event id (not recalculated)' => sub {
    my $raw = JSON->new->utf8->encode(['EVENT', 'sub1', $EVENT->to_hash]);
    my $msg = Net::Nostr::Message->parse($raw);
    is($msg->event->id, $FIATJAF_EVENT{id}, 'known-good event id preserved by parse');
};

###############################################################################
# POD examples
###############################################################################

subtest 'POD: CLOSE serialize' => sub {
    my $msg = Net::Nostr::Message->new(type => 'CLOSE', subscription_id => 'x');
    is($msg->serialize, '["CLOSE","x"]', 'CLOSE serializes as ["CLOSE","x"]');
};

subtest 'POD: NOTICE parse' => sub {
    my $msg = Net::Nostr::Message->parse('["NOTICE","hello"]');
    is($msg->type, 'NOTICE', 'type is NOTICE');
    is($msg->message, 'hello', 'message is hello');
};

subtest 'POD: OK prefix extraction' => sub {
    my $eid = 'aa' x 32;
    my $raw = JSON->new->utf8->encode(['OK', $eid, JSON::false, 'blocked: you are banned']);
    my $msg = Net::Nostr::Message->parse($raw);
    is($msg->prefix, 'blocked', 'prefix extracted as blocked');
    is($msg->accepted, 0, 'not accepted');
};

###############################################################################
# AUTH message (NIP-42)
###############################################################################

subtest 'AUTH relay-to-client (challenge) construction and serialization' => sub {
    my $msg = Net::Nostr::Message->new(type => 'AUTH', challenge => 'test-challenge');
    is $msg->type, 'AUTH', 'type is AUTH';
    is $msg->challenge, 'test-challenge', 'challenge stored';

    my $json = $msg->serialize;
    my $decoded = JSON::decode_json($json);
    is $decoded->[0], 'AUTH', 'serialized type';
    is $decoded->[1], 'test-challenge', 'serialized challenge';
    is scalar @$decoded, 2, '2 elements';
};

subtest 'AUTH client-to-relay (event) construction and serialization' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => 'a' x 64, kind => 22242, content => '',
        tags => [['relay', 'wss://r.example.com/'], ['challenge', 'ch']],
    );
    my $msg = Net::Nostr::Message->new(type => 'AUTH', event => $event);
    is $msg->type, 'AUTH', 'type is AUTH';
    is $msg->event->kind, 22242, 'event kind';

    my $json = $msg->serialize;
    my $decoded = JSON::decode_json($json);
    is $decoded->[0], 'AUTH', 'serialized type';
    is ref($decoded->[1]), 'HASH', 'second element is event hash';
    is $decoded->[1]{kind}, 22242, 'serialized event kind';
};

subtest 'AUTH requires event or challenge' => sub {
    ok dies { Net::Nostr::Message->new(type => 'AUTH') },
        'AUTH without event or challenge croaks';
};

subtest 'parse() AUTH challenge from relay' => sub {
    my $raw = JSON->new->utf8->encode(['AUTH', 'my-challenge']);
    my $msg = Net::Nostr::Message->parse($raw);
    is $msg->type, 'AUTH', 'type is AUTH';
    is $msg->challenge, 'my-challenge', 'challenge parsed';
};

subtest 'parse() AUTH event from client' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => 'a' x 64, kind => 22242, content => '',
        sig => 'b' x 128, tags => [['relay', 'wss://r/'], ['challenge', 'c']],
    );
    my $raw = JSON->new->utf8->encode(['AUTH', $event->to_hash]);
    my $msg = Net::Nostr::Message->parse($raw);
    is $msg->type, 'AUTH', 'type is AUTH';
    is $msg->event->kind, 22242, 'event kind parsed';
};

subtest 'parse() AUTH requires 2 elements' => sub {
    my $raw = JSON->new->utf8->encode(['AUTH']);
    ok dies { Net::Nostr::Message->parse($raw) }, 'AUTH with 1 element rejected';
};

subtest 'AUTH round-trip (challenge)' => sub {
    my $msg = Net::Nostr::Message->new(type => 'AUTH', challenge => 'rt-test');
    my $parsed = Net::Nostr::Message->parse($msg->serialize);
    is $parsed->type, 'AUTH', 'type preserved';
    is $parsed->challenge, 'rt-test', 'challenge preserved';
};

subtest 'auth-required prefix extraction' => sub {
    my $raw = JSON->new->utf8->encode([
        'OK', 'dd' x 32, JSON::false, 'auth-required: please authenticate'
    ]);
    my $msg = Net::Nostr::Message->parse($raw);
    is $msg->prefix, 'auth-required', 'auth-required prefix extracted';
};

subtest 'POD: AUTH challenge parse' => sub {
    my $msg = Net::Nostr::Message->parse('["AUTH","challenge123"]');
    is $msg->challenge, 'challenge123', 'challenge parsed from POD example';
};

done_testing;
