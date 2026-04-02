#!/usr/bin/perl

# NIP-10: Text Notes and Threads
# https://github.com/nostr-protocol/nips/blob/master/10.md

use strictures 2;

use Test2::V0 -no_srand => 1;

use lib 't/lib';
use TestFixtures qw(make_event);

use Net::Nostr::Event;
use Net::Nostr::Thread;

my $alice_pk = 'a' x 64;
my $bob_pk   = 'b' x 64;
my $carol_pk = 'c' x 64;
my $dave_pk  = 'd' x 64;

my $root_id  = '1' x 64;
my $reply_id = '2' x 64;
my $quote_id = '3' x 64;

###############################################################################
# kind 1 is a plaintext text note
###############################################################################

subtest 'kind 1 text note' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $alice_pk, kind => 1, content => 'hello world',
    );
    is($event->kind, 1, 'kind is 1');
    is($event->content, 'hello world', 'content is plaintext');
};

###############################################################################
# Creating replies - marked "e" tags (preferred)
###############################################################################

subtest 'direct reply to root has single "root" marker' => sub {
    my $root = make_event(id => $root_id, pubkey => $alice_pk, kind => 1, content => 'root post');

    my $reply = Net::Nostr::Thread->reply(
        to      => $root,
        pubkey  => $bob_pk,
        content => 'replying to root',
    );

    is($reply->kind, 1, 'reply is kind 1');
    is($reply->content, 'replying to root', 'content preserved');

    # Should have a single e tag with "root" marker
    my @e_tags = grep { $_->[0] eq 'e' } @{$reply->tags};
    is(scalar @e_tags, 1, 'one e tag');
    is($e_tags[0][1], $root_id, 'references root event id');
    is($e_tags[0][3], 'root', 'marker is "root"');
    is($e_tags[0][4], $alice_pk, 'pubkey of root author');
};

subtest 'reply to a reply has both "root" and "reply" markers' => sub {
    my $root = make_event(id => $root_id, pubkey => $alice_pk, kind => 1, content => 'root');

    my $mid = make_event(
        id => $reply_id, pubkey => $bob_pk, kind => 1, content => 'mid reply',
        tags => [['e', $root_id, '', 'root', $alice_pk], ['p', $alice_pk]],
    );

    my $reply = Net::Nostr::Thread->reply(
        to      => $mid,
        pubkey  => $carol_pk,
        content => 'deep reply',
    );

    my @e_tags = grep { $_->[0] eq 'e' } @{$reply->tags};
    is(scalar @e_tags, 2, 'two e tags');

    # Sorted by reply stack: root first, then direct parent
    is($e_tags[0][1], $root_id, 'first e tag is root');
    is($e_tags[0][3], 'root', 'root marker');
    is($e_tags[0][4], $alice_pk, 'root author pubkey');

    is($e_tags[1][1], $reply_id, 'second e tag is direct parent');
    is($e_tags[1][3], 'reply', 'reply marker');
    is($e_tags[1][4], $bob_pk, 'parent author pubkey');
};

subtest 'relay URL defaults to empty string in e tags' => sub {
    my $root = make_event(id => $root_id, pubkey => $alice_pk, kind => 1, content => 'root');

    my $reply = Net::Nostr::Thread->reply(
        to      => $root,
        pubkey  => $bob_pk,
        content => 'reply',
    );

    my @e_tags = grep { $_->[0] eq 'e' } @{$reply->tags};
    is($e_tags[0][2], '', 'relay URL is empty string');
};

subtest 'relay URL can be specified' => sub {
    my $root = make_event(id => $root_id, pubkey => $alice_pk, kind => 1, content => 'root');

    my $reply = Net::Nostr::Thread->reply(
        to        => $root,
        pubkey    => $bob_pk,
        content   => 'reply',
        relay_url => 'wss://relay.example.com/',
    );

    my @e_tags = grep { $_->[0] eq 'e' } @{$reply->tags};
    is($e_tags[0][2], 'wss://relay.example.com/', 'relay URL set');
};

###############################################################################
# "p" tags - notify participants
###############################################################################

subtest 'reply includes parent author as p tag' => sub {
    my $root = make_event(id => $root_id, pubkey => $alice_pk, kind => 1, content => 'root');

    my $reply = Net::Nostr::Thread->reply(
        to      => $root,
        pubkey  => $bob_pk,
        content => 'reply',
    );

    my @p_tags = grep { $_->[0] eq 'p' } @{$reply->tags};
    is(scalar @p_tags, 1, 'one p tag');
    is($p_tags[0][1], $alice_pk, 'p tag references root author');
};

subtest 'reply includes all of parent p tags plus parent author' => sub {
    my $parent = make_event(
        id => $reply_id, pubkey => $bob_pk, kind => 1, content => 'mid reply',
        tags => [
            ['e', $root_id, '', 'root', $alice_pk],
            ['p', $alice_pk],
            ['p', $carol_pk],
        ],
    );

    my $reply = Net::Nostr::Thread->reply(
        to      => $parent,
        pubkey  => $dave_pk,
        content => 'deep reply',
    );

    my @p_tags = grep { $_->[0] eq 'p' } @{$reply->tags};
    my @p_keys = map { $_->[1] } @p_tags;

    ok((grep { $_ eq $bob_pk } @p_keys), 'parent author included');
    ok((grep { $_ eq $alice_pk } @p_keys), 'parent p tag alice included');
    ok((grep { $_ eq $carol_pk } @p_keys), 'parent p tag carol included');
    ok(!(grep { $_ eq $dave_pk } @p_keys), 'own pubkey not included');
};

subtest 'p tags are deduplicated' => sub {
    my $parent = make_event(
        id => $reply_id, pubkey => $alice_pk, kind => 1, content => 'reply',
        tags => [
            ['e', $root_id, '', 'root', $alice_pk],
            ['p', $alice_pk],  # alice is both author and in p tags
        ],
    );

    my $reply = Net::Nostr::Thread->reply(
        to      => $parent,
        pubkey  => $bob_pk,
        content => 'deep reply',
    );

    my @p_tags = grep { $_->[0] eq 'p' } @{$reply->tags};
    is(scalar @p_tags, 1, 'alice appears only once');
    is($p_tags[0][1], $alice_pk, 'alice is the p tag');
};

###############################################################################
# "q" tags for quoting
###############################################################################

subtest 'quote creates a q tag' => sub {
    my $quoted = make_event(id => $quote_id, pubkey => $alice_pk, kind => 1, content => 'original');

    my $event = Net::Nostr::Thread->quote(
        event   => $quoted,
        pubkey  => $bob_pk,
        content => "look at this nostr:nevent1...",
    );

    is($event->kind, 1, 'kind 1');
    my @q_tags = grep { $_->[0] eq 'q' } @{$event->tags};
    is(scalar @q_tags, 1, 'one q tag');
    is($q_tags[0][1], $quote_id, 'q tag references quoted event id');
    is($q_tags[0][3], $alice_pk, 'pubkey of quoted author');
};

subtest 'quote adds author as p tag' => sub {
    my $quoted = make_event(id => $quote_id, pubkey => $alice_pk, kind => 1, content => 'original');

    my $event = Net::Nostr::Thread->quote(
        event   => $quoted,
        pubkey  => $bob_pk,
        content => 'quoting',
    );

    my @p_tags = grep { $_->[0] eq 'p' } @{$event->tags};
    ok((grep { $_->[1] eq $alice_pk } @p_tags), 'quoted author in p tags');
};

subtest 'quote relay URL defaults to empty string' => sub {
    my $quoted = make_event(id => $quote_id, pubkey => $alice_pk, kind => 1, content => 'original');

    my $event = Net::Nostr::Thread->quote(
        event   => $quoted,
        pubkey  => $bob_pk,
        content => 'quoting',
    );

    my @q_tags = grep { $_->[0] eq 'q' } @{$event->tags};
    is($q_tags[0][2], '', 'relay URL empty by default');
};

subtest 'quote relay URL can be specified' => sub {
    my $quoted = make_event(id => $quote_id, pubkey => $alice_pk, kind => 1, content => 'original');

    my $event = Net::Nostr::Thread->quote(
        event     => $quoted,
        pubkey    => $bob_pk,
        content   => 'quoting',
        relay_url => 'wss://relay.example.com/',
    );

    my @q_tags = grep { $_->[0] eq 'q' } @{$event->tags};
    is($q_tags[0][2], 'wss://relay.example.com/', 'relay URL set');
};

###############################################################################
# Parsing thread info from events
###############################################################################

subtest 'parse root from marked e tags' => sub {
    my $event = make_event(
        pubkey => $bob_pk, kind => 1, content => 'reply',
        tags => [['e', $root_id, 'wss://relay.com/', 'root', $alice_pk]],
    );

    my $thread = Net::Nostr::Thread->from_event($event);
    is($thread->root_id, $root_id, 'root id parsed');
    is($thread->root_relay, 'wss://relay.com/', 'root relay parsed');
    is($thread->root_pubkey, $alice_pk, 'root pubkey parsed');
    is($thread->reply_id, undef, 'no reply id (direct reply to root)');
};

subtest 'parse root and reply from marked e tags' => sub {
    my $event = make_event(
        pubkey => $carol_pk, kind => 1, content => 'deep reply',
        tags => [
            ['e', $root_id, '', 'root', $alice_pk],
            ['e', $reply_id, 'wss://r2.com/', 'reply', $bob_pk],
        ],
    );

    my $thread = Net::Nostr::Thread->from_event($event);
    is($thread->root_id, $root_id, 'root id');
    is($thread->reply_id, $reply_id, 'reply id');
    is($thread->reply_relay, 'wss://r2.com/', 'reply relay');
    is($thread->reply_pubkey, $bob_pk, 'reply pubkey');
};

subtest 'from_event returns undef for non-reply event' => sub {
    my $event = make_event(
        pubkey => $alice_pk, kind => 1, content => 'standalone note',
        tags => [],
    );

    my $thread = Net::Nostr::Thread->from_event($event);
    is($thread, undef, 'no thread info for standalone note');
};

###############################################################################
# Deprecated positional "e" tags
###############################################################################

subtest 'parse single positional e tag as reply-to' => sub {
    my $event = make_event(
        pubkey => $bob_pk, kind => 1, content => 'reply',
        tags => [['e', $root_id, 'wss://relay.com/']],
    );

    my $thread = Net::Nostr::Thread->from_event($event);
    is($thread->root_id, $root_id, 'single positional e tag is root');
    is($thread->reply_id, undef, 'no separate reply');
};

subtest 'parse two positional e tags as root and reply' => sub {
    my $event = make_event(
        pubkey => $carol_pk, kind => 1, content => 'deep reply',
        tags => [
            ['e', $root_id, ''],
            ['e', $reply_id, ''],
        ],
    );

    my $thread = Net::Nostr::Thread->from_event($event);
    is($thread->root_id, $root_id, 'first positional is root');
    is($thread->reply_id, $reply_id, 'second positional is reply');
};

subtest 'parse many positional e tags: first is root, last is reply, middle are mentions' => sub {
    my $mention_id = '4' x 64;

    my $event = make_event(
        pubkey => $dave_pk, kind => 1, content => 'complex reply',
        tags => [
            ['e', $root_id, ''],
            ['e', $mention_id, ''],
            ['e', $reply_id, ''],
        ],
    );

    my $thread = Net::Nostr::Thread->from_event($event);
    is($thread->root_id, $root_id, 'first is root');
    is($thread->reply_id, $reply_id, 'last is reply');
    is($thread->mentions, [$mention_id], 'middle are mentions');
};

###############################################################################
# Validation
###############################################################################

subtest 'reply croaks when replying to non-kind-1 event' => sub {
    my $metadata = make_event(pubkey => $alice_pk, kind => 0, content => '{}');

    ok(dies { Net::Nostr::Thread->reply(
        to => $metadata, pubkey => $bob_pk, content => 'reply',
    ) }, 'croaks on reply to kind 0');

    my $kind7 = make_event(pubkey => $alice_pk, kind => 7, content => '+');

    ok(dies { Net::Nostr::Thread->reply(
        to => $kind7, pubkey => $bob_pk, content => 'reply',
    ) }, 'croaks on reply to kind 7');
};

subtest 'reply croaks without required params' => sub {
    my $root = make_event(id => $root_id, pubkey => $alice_pk, kind => 1, content => 'root');

    ok(dies { Net::Nostr::Thread->reply(pubkey => $bob_pk, content => 'x') }, 'croaks without to');
    ok(dies { Net::Nostr::Thread->reply(to => $root, content => 'x') }, 'croaks without pubkey');
    ok(dies { Net::Nostr::Thread->reply(to => $root, pubkey => $bob_pk) }, 'croaks without content');
};

###############################################################################
# Additional arguments pass through to Event
###############################################################################

subtest 'extra args passed to Event constructor' => sub {
    my $root = make_event(id => $root_id, pubkey => $alice_pk, kind => 1, content => 'root');

    my $reply = Net::Nostr::Thread->reply(
        to         => $root,
        pubkey     => $bob_pk,
        content    => 'reply',
        created_at => 1700000000,
    );

    is($reply->created_at, 1700000000, 'created_at passed through');
};

###############################################################################
# is_reply helper on Thread
###############################################################################

subtest 'is_reply detects whether an event is a thread reply' => sub {
    my $standalone = make_event(pubkey => $alice_pk, kind => 1, content => 'hello', tags => []);
    ok(!Net::Nostr::Thread->is_reply($standalone), 'standalone is not a reply');

    my $reply = make_event(
        pubkey => $bob_pk, kind => 1, content => 'reply',
        tags => [['e', $root_id, '', 'root', $alice_pk]],
    );
    ok(Net::Nostr::Thread->is_reply($reply), 'event with root e tag is a reply');

    my $positional = make_event(
        pubkey => $bob_pk, kind => 1, content => 'reply',
        tags => [['e', $root_id, '']],
    );
    ok(Net::Nostr::Thread->is_reply($positional), 'event with positional e tag is a reply');
};

###############################################################################
# Edge cases
###############################################################################

subtest 'replying to own post does not include self in p tags' => sub {
    my $root = make_event(id => $root_id, pubkey => $alice_pk, kind => 1, content => 'root');

    my $reply = Net::Nostr::Thread->reply(
        to      => $root,
        pubkey  => $alice_pk,
        content => 'self-reply',
    );

    my @p_tags = grep { $_->[0] eq 'p' } @{$reply->tags};
    is(scalar @p_tags, 0, 'no p tags when replying to self');
};

subtest 'e tags sorted by reply stack: root then parent' => sub {
    # Spec: e tags SHOULD be sorted by reply stack from root to direct parent
    my $parent = make_event(
        id => $reply_id, pubkey => $bob_pk, kind => 1, content => 'mid',
        tags => [['e', $root_id, '', 'root', $alice_pk], ['p', $alice_pk]],
    );

    my $reply = Net::Nostr::Thread->reply(
        to      => $parent,
        pubkey  => $carol_pk,
        content => 'deep',
    );

    my @e_tags = grep { $_->[0] eq 'e' } @{$reply->tags};
    is($e_tags[0][3], 'root', 'root comes first');
    is($e_tags[1][3], 'reply', 'reply comes second');
};

done_testing;
