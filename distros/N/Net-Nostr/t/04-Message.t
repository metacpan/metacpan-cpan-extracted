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

subtest 'NEG-OPEN rejects odd-length neg_msg' => sub {
    my $filter = Net::Nostr::Filter->new(kinds => [1]);
    like(
        dies {
            Net::Nostr::Message->new(
                type            => 'NEG-OPEN',
                subscription_id => 'neg1',
                filter          => $filter,
                neg_msg         => 'a',
            );
        },
        qr/even-length hex/i,
        'odd-length NEG-OPEN neg_msg rejected'
    );
};

subtest 'NEG-MSG rejects odd-length neg_msg' => sub {
    like(
        dies {
            Net::Nostr::Message->new(
                type            => 'NEG-MSG',
                subscription_id => 'neg1',
                neg_msg         => 'a',
            );
        },
        qr/even-length hex/i,
        'odd-length NEG-MSG neg_msg rejected'
    );
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

###############################################################################
# COUNT message (NIP-45)
###############################################################################

subtest 'POD: COUNT response parse' => sub {
    my $msg = Net::Nostr::Message->parse('["COUNT","q1",{"count":42}]');
    is $msg->count, 42, 'count parsed from POD example';
};

subtest 'NOTICE constructor requires message' => sub {
    like(
        dies { Net::Nostr::Message->new(type => 'NOTICE') },
        qr/message is required for NOTICE/,
        'NOTICE without message croaks'
    );
};

###############################################################################
# EOSE subscription_id - relay-to-client, must accept any subscription_id
###############################################################################

subtest 'EOSE accepts any subscription_id' => sub {
    ok(lives { Net::Nostr::Message->new(type => 'EOSE', subscription_id => '', ) },
        'EOSE accepts empty subscription_id');
    ok(lives { Net::Nostr::Message->new(type => 'EOSE', subscription_id => 'x' x 65) },
        'EOSE accepts subscription_id > 64 chars');
    ok(lives { Net::Nostr::Message->new(type => 'EOSE', subscription_id => 'sub1') },
        'EOSE accepts valid subscription_id');
};

###############################################################################
# CLOSED subscription_id - relay-to-client, must accept any subscription_id
# (echoes back whatever the client sent, even if invalid)
###############################################################################

subtest 'CLOSED accepts any subscription_id' => sub {
    ok(lives { Net::Nostr::Message->new(type => 'CLOSED', subscription_id => '', message => 'bye') },
        'CLOSED accepts empty subscription_id');
    ok(lives { Net::Nostr::Message->new(type => 'CLOSED', subscription_id => 'x' x 65, message => 'bye') },
        'CLOSED accepts subscription_id > 64 chars');
    ok(lives { Net::Nostr::Message->new(type => 'CLOSED', subscription_id => 'sub1', message => 'bye') },
        'CLOSED accepts valid subscription_id');
};

###############################################################################
# OK event_id validation
###############################################################################

subtest 'OK requires event_id' => sub {
    like(
        dies { Net::Nostr::Message->new(type => 'OK', accepted => 1, message => '') },
        qr/event_id is required/,
        'OK without event_id croaks'
    );
};

subtest 'parse() OK rejects malformed event_id from wire' => sub {
    my $raw = JSON->new->utf8->encode(['OK', 'not-hex', JSON::true, '']);
    like(
        dies { Net::Nostr::Message->parse($raw) },
        qr/event_id must be 64-char lowercase hex/,
        'OK with bad event_id rejected on parse'
    );
};

subtest 'parse() OK accepts valid event_id from wire' => sub {
    my $raw = JSON->new->utf8->encode(['OK', 'aa' x 32, JSON::true, '']);
    my $msg;
    ok(lives { $msg = Net::Nostr::Message->parse($raw) }, 'OK with valid event_id accepted');
    is($msg->event_id, 'aa' x 32, 'event_id parsed correctly');
};

subtest 'new() rejects unknown arguments' => sub {
    like(
        dies { Net::Nostr::Message->new(type => 'NOTICE', message => 'hi', bogus => 'value') },
        qr/unknown.+bogus/i,
        'unknown argument rejected'
    );
};

###############################################################################
# parse() rejects EVENT with missing required event fields (from_wire)
###############################################################################

subtest 'parse() EVENT rejects missing event id' => sub {
    my $h = $EVENT->to_hash;
    delete $h->{id};
    my $raw = JSON->new->utf8->encode(['EVENT', 'sub1', $h]);
    like(dies { Net::Nostr::Message->parse($raw) }, qr/id is required/, 'missing id rejected');
};

subtest 'parse() EVENT rejects missing created_at' => sub {
    my $h = $EVENT->to_hash;
    delete $h->{created_at};
    my $raw = JSON->new->utf8->encode(['EVENT', 'sub1', $h]);
    like(dies { Net::Nostr::Message->parse($raw) }, qr/created_at is required/, 'missing created_at rejected');
};

subtest 'parse() EVENT rejects missing tags' => sub {
    my $h = $EVENT->to_hash;
    delete $h->{tags};
    my $raw = JSON->new->utf8->encode(['EVENT', 'sub1', $h]);
    like(dies { Net::Nostr::Message->parse($raw) }, qr/tags is required/, 'missing tags rejected');
};

subtest 'parse() EVENT rejects missing sig' => sub {
    my $h = $EVENT->to_hash;
    delete $h->{sig};
    my $raw = JSON->new->utf8->encode(['EVENT', 'sub1', $h]);
    like(dies { Net::Nostr::Message->parse($raw) }, qr/sig is required/, 'missing sig rejected');
};

subtest 'parse() client EVENT rejects missing event fields' => sub {
    my $h = $EVENT->to_hash;
    delete $h->{id};
    my $raw = JSON->new->utf8->encode(['EVENT', $h]);
    like(dies { Net::Nostr::Message->parse($raw) }, qr/id is required/, 'client EVENT missing id rejected');
};

subtest 'parse() AUTH event rejects missing event fields' => sub {
    my $h = $EVENT->to_hash;
    $h->{kind} = 22242;
    # recompute the id since we changed kind; but the point is that removing
    # a field is what we're testing
    delete $h->{sig};
    my $raw = JSON->new->utf8->encode(['AUTH', $h]);
    like(dies { Net::Nostr::Message->parse($raw) }, qr/sig is required/, 'AUTH event missing sig rejected');
};

###############################################################################
# parse() rejects non-object payloads with protocol-specific errors
###############################################################################

subtest 'parse() EVENT rejects non-object event (relay-to-client)' => sub {
    my $raw = JSON->new->utf8->encode(['EVENT', 'sub1', 'not-a-hash']);
    like(dies { Net::Nostr::Message->parse($raw) },
        qr/EVENT event element must be a JSON object/,
        'string event payload rejected with protocol error');
};

subtest 'parse() EVENT rejects non-object event (client-to-relay)' => sub {
    my $raw = JSON->new->utf8->encode(['EVENT', 42]);
    like(dies { Net::Nostr::Message->parse($raw) },
        qr/EVENT event element must be a JSON object/,
        'numeric event payload rejected with protocol error');
};

subtest 'parse() EVENT rejects array event payload' => sub {
    my $raw = JSON->new->utf8->encode(['EVENT', 'sub1', [1,2,3]]);
    like(dies { Net::Nostr::Message->parse($raw) },
        qr/EVENT event element must be a JSON object/,
        'array event payload rejected with protocol error');
};

subtest 'parse() REQ rejects non-object filter' => sub {
    my $raw = JSON->new->utf8->encode(['REQ', 'sub1', 'not-a-hash']);
    like(dies { Net::Nostr::Message->parse($raw) },
        qr/REQ filter element must be a JSON object/,
        'string filter rejected with protocol error');
};

subtest 'parse() REQ rejects array filter' => sub {
    my $raw = JSON->new->utf8->encode(['REQ', 'sub1', [1,2,3]]);
    like(dies { Net::Nostr::Message->parse($raw) },
        qr/REQ filter element must be a JSON object/,
        'array filter rejected with protocol error');
};

subtest 'parse() COUNT rejects non-object filter' => sub {
    my $raw = JSON->new->utf8->encode(['COUNT', 'sub1', 'not-a-hash']);
    like(dies { Net::Nostr::Message->parse($raw) },
        qr/COUNT filter element must be a JSON object/,
        'string filter rejected with protocol error');
};

###############################################################################
# Constructor validates field types/formats
###############################################################################

subtest 'new() OK validates event_id format' => sub {
    like(
        dies { Net::Nostr::Message->new(type => 'OK', event_id => 'not-hex', accepted => 1, message => '') },
        qr/event_id must be 64-char lowercase hex/,
        'OK rejects malformed event_id in constructor'
    );
    like(
        dies { Net::Nostr::Message->new(type => 'OK', event_id => 'AA' x 32, accepted => 1, message => '') },
        qr/event_id must be 64-char lowercase hex/,
        'OK rejects uppercase hex event_id'
    );
    like(
        dies { Net::Nostr::Message->new(type => 'OK', event_id => 'aa' x 16, accepted => 1, message => '') },
        qr/event_id must be 64-char lowercase hex/,
        'OK rejects short event_id'
    );
    ok(
        lives { Net::Nostr::Message->new(type => 'OK', event_id => 'aa' x 32, accepted => 1, message => '') },
        'OK accepts valid event_id in constructor'
    );
};

subtest 'new() EVENT requires Net::Nostr::Event object' => sub {
    like(
        dies { Net::Nostr::Message->new(type => 'EVENT', event => { id => 'fake' }) },
        qr/event must be a Net::Nostr::Event/,
        'EVENT rejects hashref'
    );
    like(
        dies { Net::Nostr::Message->new(type => 'EVENT', event => 'string') },
        qr/event must be a Net::Nostr::Event/,
        'EVENT rejects string'
    );
    ok(
        lives { Net::Nostr::Message->new(type => 'EVENT', event => $EVENT) },
        'EVENT accepts Net::Nostr::Event object'
    );
};

subtest 'new() AUTH requires Net::Nostr::Event object for event path' => sub {
    like(
        dies { Net::Nostr::Message->new(type => 'AUTH', event => { kind => 22242 }) },
        qr/event must be a Net::Nostr::Event/,
        'AUTH rejects hashref event'
    );
    like(
        dies { Net::Nostr::Message->new(type => 'AUTH', event => 'string') },
        qr/event must be a Net::Nostr::Event/,
        'AUTH rejects string event'
    );
};

subtest 'new() NOTICE rejects non-scalar message' => sub {
    like(
        dies { Net::Nostr::Message->new(type => 'NOTICE', message => ['array']) },
        qr/message must be a string/,
        'NOTICE rejects arrayref message'
    );
    like(
        dies { Net::Nostr::Message->new(type => 'NOTICE', message => { hash => 1 }) },
        qr/message must be a string/,
        'NOTICE rejects hashref message'
    );
};

subtest 'new() EOSE requires defined subscription_id' => sub {
    like(
        dies { Net::Nostr::Message->new(type => 'EOSE') },
        qr/subscription_id is required/,
        'EOSE requires subscription_id'
    );
};

subtest 'new() CLOSED requires defined subscription_id and message' => sub {
    like(
        dies { Net::Nostr::Message->new(type => 'CLOSED', message => 'bye') },
        qr/subscription_id is required/,
        'CLOSED requires subscription_id'
    );
    like(
        dies { Net::Nostr::Message->new(type => 'CLOSED', subscription_id => 'sub1') },
        qr/message is required/,
        'CLOSED requires message'
    );
};

subtest 'new() AUTH challenge rejects non-scalar' => sub {
    like(
        dies { Net::Nostr::Message->new(type => 'AUTH', challenge => ['array']) },
        qr/challenge must be a string/,
        'AUTH rejects arrayref challenge'
    );
    like(
        dies { Net::Nostr::Message->new(type => 'AUTH', challenge => { hash => 1 }) },
        qr/challenge must be a string/,
        'AUTH rejects hashref challenge'
    );
};

subtest 'new() OK rejects non-scalar message' => sub {
    like(
        dies { Net::Nostr::Message->new(type => 'OK', event_id => 'aa' x 32, accepted => 1, message => ['array']) },
        qr/message must be a string/,
        'OK rejects arrayref message'
    );
};

###############################################################################
# parse() validates non-ref scalars for string fields
###############################################################################

subtest 'parse() NOTICE rejects non-scalar message' => sub {
    my $raw = JSON->new->utf8->encode(['NOTICE', { nested => 1 }]);
    like(dies { Net::Nostr::Message->parse($raw) },
        qr/NOTICE message must be a string/,
        'NOTICE rejects object message');
    $raw = JSON->new->utf8->encode(['NOTICE', [1, 2]]);
    like(dies { Net::Nostr::Message->parse($raw) },
        qr/NOTICE message must be a string/,
        'NOTICE rejects array message');
};

subtest 'parse() EOSE rejects non-scalar subscription_id' => sub {
    my $raw = JSON->new->utf8->encode(['EOSE', { nested => 1 }]);
    like(dies { Net::Nostr::Message->parse($raw) },
        qr/EOSE subscription_id must be a string/,
        'EOSE rejects object subscription_id');
};

subtest 'parse() CLOSED rejects non-scalar fields' => sub {
    my $raw = JSON->new->utf8->encode(['CLOSED', ['arr'], 'msg']);
    like(dies { Net::Nostr::Message->parse($raw) },
        qr/CLOSED subscription_id must be a string/,
        'CLOSED rejects non-scalar subscription_id');
    $raw = JSON->new->utf8->encode(['CLOSED', 'sub1', { obj => 1 }]);
    like(dies { Net::Nostr::Message->parse($raw) },
        qr/CLOSED message must be a string/,
        'CLOSED rejects non-scalar message');
};

subtest 'parse() OK rejects non-scalar message' => sub {
    my $raw = JSON->new->utf8->encode(['OK', 'aa' x 32, JSON::true, [1,2]]);
    like(dies { Net::Nostr::Message->parse($raw) },
        qr/OK message must be a string/,
        'OK rejects array message');
};

subtest 'parse() AUTH rejects non-scalar challenge' => sub {
    my $raw = JSON->new->utf8->encode(['AUTH', [1,2,3]]);
    like(dies { Net::Nostr::Message->parse($raw) },
        qr/AUTH challenge must be a string/,
        'AUTH rejects array challenge');
};

subtest 'parse() REQ rejects non-scalar subscription_id' => sub {
    my $raw = JSON->new->utf8->encode(['REQ', ['arr'], {}]);
    like(dies { Net::Nostr::Message->parse($raw) },
        qr/subscription_id must be a non-empty string/,
        'REQ rejects non-scalar subscription_id');
};

subtest 'parse() CLOSE rejects non-scalar subscription_id' => sub {
    my $raw = JSON->new->utf8->encode(['CLOSE', { obj => 1 }]);
    like(dies { Net::Nostr::Message->parse($raw) },
        qr/subscription_id must be a non-empty string/,
        'CLOSE rejects non-scalar subscription_id');
};

subtest 'parse() EVENT rejects non-scalar subscription_id' => sub {
    my $raw = JSON->new->utf8->encode(['EVENT', [1], $EVENT->to_hash]);
    like(dies { Net::Nostr::Message->parse($raw) },
        qr/EVENT subscription_id must be a string/,
        'EVENT rejects non-scalar subscription_id');
};

subtest 'parse() COUNT rejects non-scalar subscription_id' => sub {
    my $raw = JSON->new->utf8->encode(['COUNT', { obj => 1 }, { count => 5 }]);
    like(dies { Net::Nostr::Message->parse($raw) },
        qr/subscription_id must be a non-empty string/,
        'COUNT rejects non-scalar subscription_id');
};

###############################################################################
# COUNT count field validation
###############################################################################

subtest 'new() COUNT validates count is a non-negative integer' => sub {
    ok(lives {
        Net::Nostr::Message->new(type => 'COUNT', subscription_id => 'q1', count => 0)
    }, 'count 0 accepted');
    ok(lives {
        Net::Nostr::Message->new(type => 'COUNT', subscription_id => 'q1', count => 42)
    }, 'count 42 accepted');
    ok(lives {
        Net::Nostr::Message->new(type => 'COUNT', subscription_id => 'q1', count => 93412452)
    }, 'large count accepted (spec example)');
    like(dies {
        Net::Nostr::Message->new(type => 'COUNT', subscription_id => 'q1', count => -1)
    }, qr/count must be a non-negative integer/, 'negative count rejected');
    like(dies {
        Net::Nostr::Message->new(type => 'COUNT', subscription_id => 'q1', count => 'abc')
    }, qr/count must be a non-negative integer/, 'string count rejected');
    like(dies {
        Net::Nostr::Message->new(type => 'COUNT', subscription_id => 'q1', count => 3.5)
    }, qr/count must be a non-negative integer/, 'float count rejected');
    like(dies {
        Net::Nostr::Message->new(type => 'COUNT', subscription_id => 'q1', count => [42])
    }, qr/count must be a non-negative integer/, 'arrayref count rejected');
    like(dies {
        Net::Nostr::Message->new(type => 'COUNT', subscription_id => 'q1', count => {})
    }, qr/count must be a non-negative integer/, 'hashref count rejected');
};

subtest 'parse() COUNT rejects non-integer count from wire' => sub {
    my $raw = JSON->new->utf8->encode(['COUNT', 'q1', { count => 'abc' }]);
    like(dies { Net::Nostr::Message->parse($raw) },
        qr/count must be a non-negative integer/,
        'string count from wire rejected');
    $raw = JSON->new->utf8->encode(['COUNT', 'q1', { count => -1 }]);
    like(dies { Net::Nostr::Message->parse($raw) },
        qr/count must be a non-negative integer/,
        'negative count from wire rejected');
    $raw = JSON->new->utf8->encode(['COUNT', 'q1', { count => 3.5 }]);
    like(dies { Net::Nostr::Message->parse($raw) },
        qr/count must be a non-negative integer/,
        'float count from wire rejected');
    $raw = JSON->new->utf8->encode(['COUNT', 'q1', { count => [5] }]);
    like(dies { Net::Nostr::Message->parse($raw) },
        qr/count must be a non-negative integer/,
        'array count from wire rejected');
};

subtest 'parse() COUNT accepts valid integer counts from wire' => sub {
    my $raw = JSON->new->utf8->encode(['COUNT', 'q1', { count => 0 }]);
    my $msg = Net::Nostr::Message->parse($raw);
    is $msg->count, 0, 'zero count accepted';

    $raw = JSON->new->utf8->encode(['COUNT', 'q1', { count => 93412452 }]);
    $msg = Net::Nostr::Message->parse($raw);
    is $msg->count, 93412452, 'large count accepted (NIP-45 spec example)';
};

###############################################################################
# NEG-ERR neg_limit field validation
###############################################################################

subtest 'new() NEG-ERR validates neg_limit is a non-negative integer' => sub {
    ok(lives {
        Net::Nostr::Message->new(
            type => 'NEG-ERR', subscription_id => 'x',
            message => 'blocked: too big', neg_limit => 100000,
        )
    }, 'neg_limit 100000 accepted');
    ok(lives {
        Net::Nostr::Message->new(
            type => 'NEG-ERR', subscription_id => 'x',
            message => 'blocked: too big', neg_limit => 0,
        )
    }, 'neg_limit 0 accepted');
    like(dies {
        Net::Nostr::Message->new(
            type => 'NEG-ERR', subscription_id => 'x',
            message => 'blocked: too big', neg_limit => -1,
        )
    }, qr/neg_limit must be a non-negative integer/, 'negative neg_limit rejected');
    like(dies {
        Net::Nostr::Message->new(
            type => 'NEG-ERR', subscription_id => 'x',
            message => 'blocked: too big', neg_limit => 'abc',
        )
    }, qr/neg_limit must be a non-negative integer/, 'string neg_limit rejected');
    like(dies {
        Net::Nostr::Message->new(
            type => 'NEG-ERR', subscription_id => 'x',
            message => 'blocked: too big', neg_limit => 3.5,
        )
    }, qr/neg_limit must be a non-negative integer/, 'float neg_limit rejected');
    like(dies {
        Net::Nostr::Message->new(
            type => 'NEG-ERR', subscription_id => 'x',
            message => 'blocked: too big', neg_limit => [100],
        )
    }, qr/neg_limit must be a non-negative integer/, 'arrayref neg_limit rejected');
};

subtest 'parse() NEG-ERR rejects non-integer neg_limit from wire' => sub {
    my $raw = JSON->new->utf8->encode(['NEG-ERR', 'x', 'blocked: too big', 'abc']);
    like(dies { Net::Nostr::Message->parse($raw) },
        qr/neg_limit must be a non-negative integer/,
        'string neg_limit from wire rejected');
    $raw = JSON->new->utf8->encode(['NEG-ERR', 'x', 'blocked: too big', -5]);
    like(dies { Net::Nostr::Message->parse($raw) },
        qr/neg_limit must be a non-negative integer/,
        'negative neg_limit from wire rejected');
    $raw = JSON->new->utf8->encode(['NEG-ERR', 'x', 'blocked: too big', [100]]);
    like(dies { Net::Nostr::Message->parse($raw) },
        qr/neg_limit must be a non-negative integer/,
        'array neg_limit from wire rejected');
};

subtest 'parse() NEG-ERR accepts valid neg_limit from wire' => sub {
    my $raw = JSON->new->utf8->encode(['NEG-ERR', 'x', 'blocked: too big', 100000]);
    my $msg = Net::Nostr::Message->parse($raw);
    is $msg->neg_limit, 100000, 'neg_limit 100000 parsed';
};

subtest 'POD: NEG-ERR neg_limit parse' => sub {
    my $msg = Net::Nostr::Message->parse('["NEG-ERR","x","blocked: too big",100000]');
    is $msg->neg_limit, 100000, 'neg_limit parsed from POD example';
};

###############################################################################
# new() REQ and COUNT reject non-Filter elements in filters array
###############################################################################

subtest 'new() REQ rejects non-Filter filter elements' => sub {
    like dies {
        Net::Nostr::Message->new(
            type => 'REQ', subscription_id => 'sub1',
            filters => [{ kinds => [1] }],
        )
    }, qr/filter.*Net::Nostr::Filter/i, 'hashref filter rejected';
    like dies {
        Net::Nostr::Message->new(
            type => 'REQ', subscription_id => 'sub1',
            filters => ['not a filter'],
        )
    }, qr/filter.*Net::Nostr::Filter/i, 'string filter rejected';
    like dies {
        Net::Nostr::Message->new(
            type => 'REQ', subscription_id => 'sub1',
            filters => [undef],
        )
    }, qr/filter.*Net::Nostr::Filter/i, 'undef filter rejected';
};

subtest 'new() COUNT rejects non-Filter filter elements' => sub {
    like dies {
        Net::Nostr::Message->new(
            type => 'COUNT', subscription_id => 'sub1',
            filters => [{ kinds => [1] }],
        )
    }, qr/filter.*Net::Nostr::Filter/i, 'hashref filter rejected';
    like dies {
        Net::Nostr::Message->new(
            type => 'COUNT', subscription_id => 'sub1',
            filters => [Net::Nostr::Filter->new(kinds => [1]), 'bad'],
        )
    }, qr/filter.*Net::Nostr::Filter/i, 'mixed valid and invalid rejected';
};

###############################################################################
# new() rejects mutually-exclusive arguments
###############################################################################

subtest 'new() AUTH rejects both event and challenge' => sub {
    like dies {
        Net::Nostr::Message->new(
            type      => 'AUTH',
            event     => Net::Nostr::Event->new(
                id => 'a' x 64, pubkey => 'b' x 64, kind => 22242,
                created_at => 1, content => '', tags => [], sig => 'c' x 128,
            ),
            challenge => 'test-challenge',
        )
    }, qr/mutually exclusive/i, 'event + challenge rejected';
};

subtest 'new() COUNT rejects both count and filters' => sub {
    like dies {
        Net::Nostr::Message->new(
            type            => 'COUNT',
            subscription_id => 'sub1',
            count           => 42,
            filters         => [Net::Nostr::Filter->new(kinds => [1])],
        )
    }, qr/mutually exclusive/i, 'count + filters rejected';
};

done_testing;
