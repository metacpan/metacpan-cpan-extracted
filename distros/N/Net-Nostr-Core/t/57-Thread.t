#!/usr/bin/perl

use strictures 2;

use Test2::V0 -no_srand => 1;

use lib 't/lib';
use TestFixtures qw(make_event);

use Net::Nostr::Thread;
use Net::Nostr::Event;

my $alice_pk  = 'a' x 64;
my $bob_pk    = 'b' x 64;
my $carol_pk  = 'c' x 64;
my $root_id   = '1' x 64;
my $reply_id  = '2' x 64;
my $mention_id = '4' x 64;

###############################################################################
# Constructor
###############################################################################

subtest 'new() defaults mentions to empty arrayref' => sub {
    my $t = Net::Nostr::Thread->new(root_id => $root_id);
    is $t->mentions, [], 'mentions defaults to []';
};

subtest 'new() accepts all documented fields' => sub {
    my $t = Net::Nostr::Thread->new(
        root_id      => $root_id,
        root_relay   => 'wss://r1.com/',
        root_pubkey  => $alice_pk,
        reply_id     => $reply_id,
        reply_relay  => 'wss://r2.com/',
        reply_pubkey => $bob_pk,
        mentions     => [$mention_id],
    );
    is $t->root_id,      $root_id,         'root_id';
    is $t->root_relay,   'wss://r1.com/',  'root_relay';
    is $t->root_pubkey,  $alice_pk,        'root_pubkey';
    is $t->reply_id,     $reply_id,        'reply_id';
    is $t->reply_relay,  'wss://r2.com/',  'reply_relay';
    is $t->reply_pubkey, $bob_pk,          'reply_pubkey';
    is $t->mentions,     [$mention_id],    'mentions';
};

subtest 'new() without root_id or reply_id' => sub {
    my $t = Net::Nostr::Thread->new;
    is $t->root_id,  undef, 'root_id undef';
    is $t->reply_id, undef, 'reply_id undef';
};

subtest 'new() rejects unknown arguments' => sub {
    like(
        dies { Net::Nostr::Thread->new(root_id => $root_id, bogus => 1) },
        qr/unknown.+bogus/i,
        'unknown argument rejected'
    );
};

subtest 'new() validates root_id hex format' => sub {
    like(dies { Net::Nostr::Thread->new(root_id => 'xyz') },
        qr/root_id must be 64-char lowercase hex/, 'non-hex rejected');
    like(dies { Net::Nostr::Thread->new(root_id => 'AA' x 32) },
        qr/root_id must be 64-char lowercase hex/, 'uppercase rejected');
    like(dies { Net::Nostr::Thread->new(root_id => 'a' x 63) },
        qr/root_id must be 64-char lowercase hex/, 'too short rejected');
};

subtest 'new() validates reply_id hex format' => sub {
    like(dies { Net::Nostr::Thread->new(reply_id => 'xyz') },
        qr/reply_id must be 64-char lowercase hex/, 'non-hex rejected');
    like(dies { Net::Nostr::Thread->new(reply_id => 'a' x 65) },
        qr/reply_id must be 64-char lowercase hex/, 'too long rejected');
};

###############################################################################
# reply()
###############################################################################

subtest 'reply() requires to, pubkey, content' => sub {
    my $root = make_event(id => $root_id, pubkey => $alice_pk, kind => 1, content => 'root');
    like(dies { Net::Nostr::Thread->reply(pubkey => $bob_pk, content => 'x') },
        qr/requires 'to'/, 'missing to');
    like(dies { Net::Nostr::Thread->reply(to => $root, content => 'x') },
        qr/requires 'pubkey'/, 'missing pubkey');
    like(dies { Net::Nostr::Thread->reply(to => $root, pubkey => $bob_pk) },
        qr/requires 'content'/, 'missing content');
};

subtest 'reply() rejects non-kind-1 events' => sub {
    for my $kind (0, 3, 7, 30023) {
        my $event = make_event(pubkey => $alice_pk, kind => $kind, content => '');
        like(
            dies { Net::Nostr::Thread->reply(to => $event, pubkey => $bob_pk, content => 'x') },
            qr/kind 1 replies must only reply to kind 1/,
            "kind $kind rejected"
        );
    }
};

subtest 'reply() returns a kind 1 Event' => sub {
    my $root = make_event(id => $root_id, pubkey => $alice_pk, kind => 1, content => 'root');
    my $reply = Net::Nostr::Thread->reply(to => $root, pubkey => $bob_pk, content => 'hi');
    isa_ok $reply, 'Net::Nostr::Event';
    is $reply->kind, 1, 'kind 1';
    is $reply->pubkey, $bob_pk, 'pubkey';
    is $reply->content, 'hi', 'content';
};

subtest 'reply() direct to root: single root marker, no reply marker' => sub {
    my $root = make_event(id => $root_id, pubkey => $alice_pk, kind => 1, content => 'root');
    my $reply = Net::Nostr::Thread->reply(to => $root, pubkey => $bob_pk, content => 'x');

    my @e_tags = grep { $_->[0] eq 'e' } @{$reply->tags};
    is scalar @e_tags, 1, 'one e tag';
    is $e_tags[0][1], $root_id, 'references root';
    is $e_tags[0][3], 'root', 'marker is root';
    is $e_tags[0][4], $alice_pk, 'root author pubkey';
};

subtest 'reply() to a reply: root + reply markers' => sub {
    my $mid = make_event(
        id => $reply_id, pubkey => $bob_pk, kind => 1, content => 'mid',
        tags => [['e', $root_id, '', 'root', $alice_pk]],
    );
    my $deep = Net::Nostr::Thread->reply(to => $mid, pubkey => $carol_pk, content => 'x');

    my @e_tags = grep { $_->[0] eq 'e' } @{$deep->tags};
    is scalar @e_tags, 2, 'two e tags';
    is $e_tags[0][3], 'root', 'first is root';
    is $e_tags[0][1], $root_id, 'root id preserved';
    is $e_tags[1][3], 'reply', 'second is reply';
    is $e_tags[1][1], $reply_id, 'reply is direct parent';
};

subtest 'reply() relay_url passed to reply e tag' => sub {
    my $root = make_event(id => $root_id, pubkey => $alice_pk, kind => 1, content => 'root');
    my $reply = Net::Nostr::Thread->reply(
        to => $root, pubkey => $bob_pk, content => 'x',
        relay_url => 'wss://my-relay.com/',
    );

    my @e_tags = grep { $_->[0] eq 'e' } @{$reply->tags};
    is $e_tags[0][2], 'wss://my-relay.com/', 'relay URL in e tag';
};

subtest 'reply() passes extra args to Event' => sub {
    my $root = make_event(id => $root_id, pubkey => $alice_pk, kind => 1, content => 'root');
    my $reply = Net::Nostr::Thread->reply(
        to => $root, pubkey => $bob_pk, content => 'x',
        created_at => 1700000000,
    );
    is $reply->created_at, 1700000000, 'created_at passed through';
};

subtest 'reply() p tags: parent author + parent p tags, deduped, no self' => sub {
    my $parent = make_event(
        id => $reply_id, pubkey => $bob_pk, kind => 1, content => 'mid',
        tags => [
            ['e', $root_id, '', 'root', $alice_pk],
            ['p', $alice_pk],
            ['p', $carol_pk],
            ['p', $alice_pk],  # duplicate
        ],
    );
    my $reply = Net::Nostr::Thread->reply(to => $parent, pubkey => $carol_pk, content => 'x');

    my @p_pks = map { $_->[1] } grep { $_->[0] eq 'p' } @{$reply->tags};
    # bob (parent author) + alice (from p tags), but NOT carol (self)
    ok((grep { $_ eq $bob_pk } @p_pks), 'parent author included');
    ok((grep { $_ eq $alice_pk } @p_pks), 'alice from p tags');
    ok(!(grep { $_ eq $carol_pk } @p_pks), 'self excluded');
    # no duplicates
    my %seen;
    my @dups = grep { $seen{$_}++ } @p_pks;
    is scalar @dups, 0, 'no duplicate p tags';
};

subtest 'reply() self-reply has no p tags' => sub {
    my $root = make_event(id => $root_id, pubkey => $alice_pk, kind => 1, content => 'root');
    my $reply = Net::Nostr::Thread->reply(to => $root, pubkey => $alice_pk, content => 'x');

    my @p_tags = grep { $_->[0] eq 'p' } @{$reply->tags};
    is scalar @p_tags, 0, 'no p tags when replying to self';
};

###############################################################################
# quote()
###############################################################################

subtest 'quote() requires event, pubkey, content' => sub {
    my $ev = make_event(pubkey => $alice_pk, kind => 1, content => 'hello');
    like(dies { Net::Nostr::Thread->quote(pubkey => $bob_pk, content => 'x') },
        qr/requires 'event'/, 'missing event');
    like(dies { Net::Nostr::Thread->quote(event => $ev, content => 'x') },
        qr/requires 'pubkey'/, 'missing pubkey');
    like(dies { Net::Nostr::Thread->quote(event => $ev, pubkey => $bob_pk) },
        qr/requires 'content'/, 'missing content');
};

subtest 'quote() creates q tag with event id, relay, and author pubkey' => sub {
    my $ev = make_event(id => $root_id, pubkey => $alice_pk, kind => 1, content => 'hello');
    my $qt = Net::Nostr::Thread->quote(
        event => $ev, pubkey => $bob_pk, content => 'wow',
        relay_url => 'wss://relay.com/',
    );

    isa_ok $qt, 'Net::Nostr::Event';
    is $qt->kind, 1, 'kind 1';
    my @q_tags = grep { $_->[0] eq 'q' } @{$qt->tags};
    is scalar @q_tags, 1, 'one q tag';
    is $q_tags[0][1], $root_id, 'event id';
    is $q_tags[0][2], 'wss://relay.com/', 'relay url';
    is $q_tags[0][3], $alice_pk, 'author pubkey';
};

subtest 'quote() relay_url defaults to empty string' => sub {
    my $ev = make_event(id => $root_id, pubkey => $alice_pk, kind => 1, content => 'hello');
    my $qt = Net::Nostr::Thread->quote(event => $ev, pubkey => $bob_pk, content => 'wow');

    my @q_tags = grep { $_->[0] eq 'q' } @{$qt->tags};
    is $q_tags[0][2], '', 'relay URL empty by default';
};

subtest 'quote() adds author as p tag' => sub {
    my $ev = make_event(id => $root_id, pubkey => $alice_pk, kind => 1, content => 'hello');
    my $qt = Net::Nostr::Thread->quote(event => $ev, pubkey => $bob_pk, content => 'wow');

    my @p_tags = grep { $_->[0] eq 'p' } @{$qt->tags};
    is scalar @p_tags, 1, 'one p tag';
    is $p_tags[0][1], $alice_pk, 'author pubkey';
};

subtest 'quote() does not add p tag when quoting self' => sub {
    my $ev = make_event(id => $root_id, pubkey => $alice_pk, kind => 1, content => 'hello');
    my $qt = Net::Nostr::Thread->quote(event => $ev, pubkey => $alice_pk, content => 'self-quote');

    my @p_tags = grep { $_->[0] eq 'p' } @{$qt->tags};
    is scalar @p_tags, 0, 'no p tag when quoting self';
};

###############################################################################
# from_event() - marked e tags
###############################################################################

subtest 'from_event() parses root-only marked e tag' => sub {
    my $ev = make_event(
        pubkey => $bob_pk, kind => 1, content => 'reply',
        tags => [['e', $root_id, 'wss://r.com/', 'root', $alice_pk]],
    );
    my $t = Net::Nostr::Thread->from_event($ev);
    is $t->root_id, $root_id, 'root id';
    is $t->root_relay, 'wss://r.com/', 'root relay';
    is $t->root_pubkey, $alice_pk, 'root pubkey';
    is $t->reply_id, undef, 'no reply id';
};

subtest 'from_event() parses root + reply marked e tags' => sub {
    my $ev = make_event(
        pubkey => $carol_pk, kind => 1, content => 'deep',
        tags => [
            ['e', $root_id, '', 'root', $alice_pk],
            ['e', $reply_id, 'wss://r2.com/', 'reply', $bob_pk],
        ],
    );
    my $t = Net::Nostr::Thread->from_event($ev);
    is $t->root_id, $root_id, 'root id';
    is $t->root_pubkey, $alice_pk, 'root pubkey';
    is $t->reply_id, $reply_id, 'reply id';
    is $t->reply_relay, 'wss://r2.com/', 'reply relay';
    is $t->reply_pubkey, $bob_pk, 'reply pubkey';
};

subtest 'from_event() missing relay/pubkey default to empty string' => sub {
    my $ev = make_event(
        pubkey => $bob_pk, kind => 1, content => 'reply',
        tags => [['e', $root_id, '', 'root']],
    );
    my $t = Net::Nostr::Thread->from_event($ev);
    is $t->root_relay, '', 'root relay defaults to empty';
    is $t->root_pubkey, '', 'root pubkey defaults to empty';
};

subtest 'from_event() returns undef for event with no e tags' => sub {
    my $ev = make_event(pubkey => $alice_pk, kind => 1, content => 'standalone', tags => []);
    is(Net::Nostr::Thread->from_event($ev), undef, 'undef for no e tags');
};

subtest 'from_event() returns undef for event with only non-e tags' => sub {
    my $ev = make_event(
        pubkey => $alice_pk, kind => 1, content => 'tagged',
        tags => [['p', $bob_pk], ['t', 'nostr']],
    );
    is(Net::Nostr::Thread->from_event($ev), undef, 'undef for no e tags');
};

###############################################################################
# from_event() - deprecated positional e tags
###############################################################################

subtest 'from_event() single positional e tag = root' => sub {
    my $ev = make_event(
        pubkey => $bob_pk, kind => 1, content => 'reply',
        tags => [['e', $root_id, 'wss://r.com/']],
    );
    my $t = Net::Nostr::Thread->from_event($ev);
    is $t->root_id, $root_id, 'root from single positional';
    is $t->root_relay, 'wss://r.com/', 'relay preserved';
    is $t->reply_id, undef, 'no reply';
};

subtest 'from_event() two positional e tags = root + reply' => sub {
    my $ev = make_event(
        pubkey => $carol_pk, kind => 1, content => 'deep',
        tags => [['e', $root_id, ''], ['e', $reply_id, 'wss://r2.com/']],
    );
    my $t = Net::Nostr::Thread->from_event($ev);
    is $t->root_id, $root_id, 'first is root';
    is $t->reply_id, $reply_id, 'second is reply';
    is $t->reply_relay, 'wss://r2.com/', 'reply relay';
};

subtest 'from_event() many positional e tags: first=root, last=reply, middle=mentions' => sub {
    my $mention2_id = '5' x 64;
    my $ev = make_event(
        pubkey => 'd' x 64, kind => 1, content => 'complex',
        tags => [
            ['e', $root_id, ''],
            ['e', $mention_id, ''],
            ['e', $mention2_id, ''],
            ['e', $reply_id, ''],
        ],
    );
    my $t = Net::Nostr::Thread->from_event($ev);
    is $t->root_id, $root_id, 'first is root';
    is $t->reply_id, $reply_id, 'last is reply';
    is $t->mentions, [$mention_id, $mention2_id], 'middle are mentions';
};

subtest 'from_event() single positional e tag without relay' => sub {
    my $ev = make_event(
        pubkey => $bob_pk, kind => 1, content => 'reply',
        tags => [['e', $root_id]],
    );
    my $t = Net::Nostr::Thread->from_event($ev);
    is $t->root_id, $root_id, 'root parsed';
    is $t->root_relay, '', 'relay defaults to empty';
};

###############################################################################
# from_event() round-trip with reply()
###############################################################################

subtest 'round-trip: reply() -> from_event() preserves thread structure' => sub {
    my $root = make_event(id => $root_id, pubkey => $alice_pk, kind => 1, content => 'root');
    my $reply_event = Net::Nostr::Thread->reply(
        to => $root, pubkey => $bob_pk, content => 'reply',
        relay_url => 'wss://relay.com/',
    );

    my $t = Net::Nostr::Thread->from_event($reply_event);
    is $t->root_id, $root_id, 'root_id round-trips';
    is $t->root_pubkey, $alice_pk, 'root_pubkey round-trips';
    is $t->reply_id, undef, 'direct reply has no reply_id';
};

subtest 'round-trip: deep reply -> from_event() preserves root and reply' => sub {
    my $mid = make_event(
        id => $reply_id, pubkey => $bob_pk, kind => 1, content => 'mid',
        tags => [['e', $root_id, '', 'root', $alice_pk]],
    );
    my $deep = Net::Nostr::Thread->reply(to => $mid, pubkey => $carol_pk, content => 'deep');

    my $t = Net::Nostr::Thread->from_event($deep);
    is $t->root_id, $root_id, 'root_id preserved';
    is $t->reply_id, $reply_id, 'reply_id preserved';
    is $t->reply_pubkey, $bob_pk, 'reply_pubkey preserved';
};

###############################################################################
# is_reply()
###############################################################################

subtest 'is_reply() returns true for events with e tags' => sub {
    my $ev = make_event(
        pubkey => $bob_pk, kind => 1, content => 'reply',
        tags => [['e', $root_id, '', 'root']],
    );
    ok(Net::Nostr::Thread->is_reply($ev), 'marked e tag detected');
};

subtest 'is_reply() returns true for positional e tags' => sub {
    my $ev = make_event(
        pubkey => $bob_pk, kind => 1, content => 'reply',
        tags => [['e', $root_id]],
    );
    ok(Net::Nostr::Thread->is_reply($ev), 'positional e tag detected');
};

subtest 'is_reply() returns false for no e tags' => sub {
    my $ev = make_event(pubkey => $alice_pk, kind => 1, content => 'hello', tags => []);
    ok(!Net::Nostr::Thread->is_reply($ev), 'not a reply');
};

subtest 'is_reply() returns false for non-e tags only' => sub {
    my $ev = make_event(
        pubkey => $alice_pk, kind => 1, content => 'hello',
        tags => [['p', $bob_pk], ['t', 'test']],
    );
    ok(!Net::Nostr::Thread->is_reply($ev), 'p and t tags are not replies');
};

###############################################################################
# Edge cases
###############################################################################

subtest 'from_event() marked tags take precedence over positional' => sub {
    # Event has both marked and unmarked e tags
    my $other_id = 'f' x 64;
    my $ev = make_event(
        pubkey => $bob_pk, kind => 1, content => 'reply',
        tags => [
            ['e', $other_id, ''],
            ['e', $root_id, '', 'root', $alice_pk],
        ],
    );
    my $t = Net::Nostr::Thread->from_event($ev);
    is $t->root_id, $root_id, 'marked root takes precedence';
};

subtest 'reply() three levels deep preserves original root' => sub {
    # root -> mid -> deep -> ultra-deep
    my $mid_id = '5' x 64;
    my $deep_id = '6' x 64;

    my $deep = make_event(
        id => $deep_id, pubkey => $carol_pk, kind => 1, content => 'deep',
        tags => [
            ['e', $root_id, '', 'root', $alice_pk],
            ['e', $mid_id, '', 'reply', $bob_pk],
        ],
    );

    my $ultra = Net::Nostr::Thread->reply(to => $deep, pubkey => 'd' x 64, content => 'ultra');
    my @e_tags = grep { $_->[0] eq 'e' } @{$ultra->tags};
    is $e_tags[0][1], $root_id, 'original root preserved';
    is $e_tags[0][3], 'root', 'root marker';
    is $e_tags[1][1], $deep_id, 'reply points to direct parent';
    is $e_tags[1][3], 'reply', 'reply marker';
};

done_testing;
