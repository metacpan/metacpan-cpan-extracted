#!/usr/bin/perl

# NIP-28: Public Chat
# https://github.com/nostr-protocol/nips/blob/master/28.md

use strictures 2;

use Test2::V0 -no_srand => 1;
use JSON;

use lib 't/lib';
use TestFixtures qw(make_event);

use Net::Nostr::Event;
use Net::Nostr::Channel;

my $JSON = JSON->new->utf8;

my $alice_pk   = 'a' x 64;
my $bob_pk     = 'b' x 64;
my $carol_pk   = 'c' x 64;
my $channel_id = '1' x 64;
my $msg_id     = '2' x 64;

###############################################################################
# Kind 40: Create channel
###############################################################################

subtest 'create produces kind 40 event' => sub {
    my $event = Net::Nostr::Channel->create(
        pubkey => $alice_pk,
        name   => 'Demo Channel',
    );
    is($event->kind, 40, 'kind is 40');
    isa_ok($event, 'Net::Nostr::Event');
};

subtest 'create content is JSON with metadata' => sub {
    my $event = Net::Nostr::Channel->create(
        pubkey  => $alice_pk,
        name    => 'Demo Channel',
        about   => 'A test channel.',
        picture => 'https://placekitten.com/200/200',
        relays  => ['wss://nos.lol', 'wss://nostr.mom'],
    );

    my $meta = $JSON->decode($event->content);
    is($meta->{name}, 'Demo Channel', 'name in content');
    is($meta->{about}, 'A test channel.', 'about in content');
    is($meta->{picture}, 'https://placekitten.com/200/200', 'picture in content');
    is($meta->{relays}, ['wss://nos.lol', 'wss://nostr.mom'], 'relays in content');
};

subtest 'create with only name' => sub {
    my $event = Net::Nostr::Channel->create(
        pubkey => $alice_pk,
        name   => 'Minimal Channel',
    );

    my $meta = $JSON->decode($event->content);
    is($meta->{name}, 'Minimal Channel', 'name present');
    ok(!exists $meta->{about}, 'about not present');
    ok(!exists $meta->{picture}, 'picture not present');
    ok(!exists $meta->{relays}, 'relays not present');
};

subtest 'create with additional metadata fields (MAY)' => sub {
    my $event = Net::Nostr::Channel->create(
        pubkey   => $alice_pk,
        name     => 'Demo',
        metadata => { rules => 'be nice', language => 'en' },
    );

    my $meta = $JSON->decode($event->content);
    is($meta->{name}, 'Demo', 'name present');
    is($meta->{rules}, 'be nice', 'extra field: rules');
    is($meta->{language}, 'en', 'extra field: language');
};

subtest 'create has no tags' => sub {
    my $event = Net::Nostr::Channel->create(
        pubkey => $alice_pk,
        name   => 'Demo',
    );
    is($event->tags, [], 'no tags on channel create');
};

subtest 'create croaks without name' => sub {
    ok(dies { Net::Nostr::Channel->create(pubkey => $alice_pk) },
        'croaks without name');
};

subtest 'create croaks without pubkey' => sub {
    ok(dies { Net::Nostr::Channel->create(name => 'Demo') },
        'croaks without pubkey');
};

subtest 'create passes extra args to Event' => sub {
    my $event = Net::Nostr::Channel->create(
        pubkey     => $alice_pk,
        name       => 'Demo',
        created_at => 1700000000,
    );
    is($event->created_at, 1700000000, 'created_at passed through');
};

###############################################################################
# Kind 41: Set channel metadata
###############################################################################

subtest 'set_metadata produces kind 41 event' => sub {
    my $event = Net::Nostr::Channel->set_metadata(
        pubkey     => $alice_pk,
        channel_id => $channel_id,
        name       => 'Updated Name',
    );
    is($event->kind, 41, 'kind is 41');
};

subtest 'set_metadata has e tag with root marker per NIP-10' => sub {
    my $event = Net::Nostr::Channel->set_metadata(
        pubkey     => $alice_pk,
        channel_id => $channel_id,
        name       => 'Updated',
        relay_url  => 'wss://relay.example.com/',
    );

    my @e_tags = grep { $_->[0] eq 'e' } @{$event->tags};
    is(scalar @e_tags, 1, 'one e tag');
    is($e_tags[0][1], $channel_id, 'e tag references channel');
    is($e_tags[0][2], 'wss://relay.example.com/', 'relay URL');
    is($e_tags[0][3], 'root', 'root marker');
};

subtest 'set_metadata relay_url defaults to empty string' => sub {
    my $event = Net::Nostr::Channel->set_metadata(
        pubkey     => $alice_pk,
        channel_id => $channel_id,
        name       => 'Updated',
    );

    my @e_tags = grep { $_->[0] eq 'e' } @{$event->tags};
    is($e_tags[0][2], '', 'relay URL is empty string');
};

subtest 'set_metadata content is JSON with metadata fields' => sub {
    my $event = Net::Nostr::Channel->set_metadata(
        pubkey     => $alice_pk,
        channel_id => $channel_id,
        name       => 'Updated Demo',
        about      => 'Updating a test channel.',
        picture    => 'https://placekitten.com/201/201',
        relays     => ['wss://nos.lol'],
    );

    my $meta = $JSON->decode($event->content);
    is($meta->{name}, 'Updated Demo', 'name');
    is($meta->{about}, 'Updating a test channel.', 'about');
    is($meta->{picture}, 'https://placekitten.com/201/201', 'picture');
    is($meta->{relays}, ['wss://nos.lol'], 'relays');
};

subtest 'set_metadata supports categories via t tags' => sub {
    my $event = Net::Nostr::Channel->set_metadata(
        pubkey     => $alice_pk,
        channel_id => $channel_id,
        name       => 'Updated',
        categories => ['nostr', 'perl', 'chat'],
    );

    my @t_tags = grep { $_->[0] eq 't' } @{$event->tags};
    is(scalar @t_tags, 3, 'three t tags');
    is($t_tags[0][1], 'nostr', 'first category');
    is($t_tags[1][1], 'perl', 'second category');
    is($t_tags[2][1], 'chat', 'third category');
};

subtest 'set_metadata with additional metadata fields (MAY)' => sub {
    my $event = Net::Nostr::Channel->set_metadata(
        pubkey     => $alice_pk,
        channel_id => $channel_id,
        name       => 'Updated',
        metadata   => { rules => 'no spam', language => 'en' },
    );

    my $meta = $JSON->decode($event->content);
    is($meta->{name}, 'Updated', 'name present');
    is($meta->{rules}, 'no spam', 'extra field: rules');
    is($meta->{language}, 'en', 'extra field: language');
};

subtest 'set_metadata with only some metadata fields' => sub {
    my $event = Net::Nostr::Channel->set_metadata(
        pubkey     => $alice_pk,
        channel_id => $channel_id,
        about      => 'just updating the description',
    );

    my $meta = $JSON->decode($event->content);
    ok(!exists $meta->{name}, 'name not present');
    is($meta->{about}, 'just updating the description', 'about present');
    ok(!exists $meta->{picture}, 'picture not present');
};

subtest 'set_metadata croaks without channel_id' => sub {
    ok(dies { Net::Nostr::Channel->set_metadata(
        pubkey => $alice_pk, name => 'Updated',
    ) }, 'croaks without channel_id');
};

subtest 'set_metadata croaks without pubkey' => sub {
    ok(dies { Net::Nostr::Channel->set_metadata(
        channel_id => $channel_id, name => 'Updated',
    ) }, 'croaks without pubkey');
};

subtest 'set_metadata passes extra args to Event' => sub {
    my $event = Net::Nostr::Channel->set_metadata(
        pubkey     => $alice_pk,
        channel_id => $channel_id,
        name       => 'Updated',
        created_at => 1700000000,
    );
    is($event->created_at, 1700000000, 'created_at passed through');
};

###############################################################################
# Kind 42: Channel message (root)
###############################################################################

subtest 'message produces kind 42 event' => sub {
    my $event = Net::Nostr::Channel->message(
        pubkey     => $bob_pk,
        channel_id => $channel_id,
        content    => 'Hello, world!',
    );
    is($event->kind, 42, 'kind is 42');
    is($event->content, 'Hello, world!', 'content is message text');
};

subtest 'message has e tag with root marker pointing to channel' => sub {
    my $event = Net::Nostr::Channel->message(
        pubkey     => $bob_pk,
        channel_id => $channel_id,
        content    => 'Hello!',
        relay_url  => 'wss://relay.example.com/',
    );

    my @e_tags = grep { $_->[0] eq 'e' } @{$event->tags};
    is(scalar @e_tags, 1, 'one e tag');
    is($e_tags[0][1], $channel_id, 'references channel');
    is($e_tags[0][2], 'wss://relay.example.com/', 'relay URL');
    is($e_tags[0][3], 'root', 'root marker');
};

subtest 'message relay_url defaults to empty string' => sub {
    my $event = Net::Nostr::Channel->message(
        pubkey     => $bob_pk,
        channel_id => $channel_id,
        content    => 'Hello!',
    );

    my @e_tags = grep { $_->[0] eq 'e' } @{$event->tags};
    is($e_tags[0][2], '', 'relay URL is empty string');
};

subtest 'message croaks without channel_id' => sub {
    ok(dies { Net::Nostr::Channel->message(
        pubkey => $bob_pk, content => 'Hello!',
    ) }, 'croaks without channel_id');
};

subtest 'message croaks without content' => sub {
    ok(dies { Net::Nostr::Channel->message(
        pubkey => $bob_pk, channel_id => $channel_id,
    ) }, 'croaks without content');
};

subtest 'message croaks without pubkey' => sub {
    ok(dies { Net::Nostr::Channel->message(
        channel_id => $channel_id, content => 'Hello!',
    ) }, 'croaks without pubkey');
};

subtest 'message passes extra args to Event' => sub {
    my $event = Net::Nostr::Channel->message(
        pubkey     => $bob_pk,
        channel_id => $channel_id,
        content    => 'Hello!',
        created_at => 1700000000,
    );
    is($event->created_at, 1700000000, 'created_at passed through');
};

###############################################################################
# Kind 42: Channel message (reply)
###############################################################################

subtest 'reply produces kind 42 with root and reply e tags' => sub {
    my $parent = make_event(
        id => $msg_id, pubkey => $bob_pk, kind => 42,
        content => 'original message',
        tags => [['e', $channel_id, 'wss://relay.com/', 'root']],
    );

    my $event = Net::Nostr::Channel->reply(
        pubkey     => $carol_pk,
        channel_id => $channel_id,
        to         => $parent,
        content    => 'Reply!',
        relay_url  => 'wss://relay.com/',
    );

    is($event->kind, 42, 'kind is 42');
    is($event->content, 'Reply!', 'content is reply text');

    my @e_tags = grep { $_->[0] eq 'e' } @{$event->tags};
    is(scalar @e_tags, 2, 'two e tags');
    is($e_tags[0][1], $channel_id, 'first e tag is channel (root)');
    is($e_tags[0][3], 'root', 'root marker');
    is($e_tags[1][1], $msg_id, 'second e tag is parent message (reply)');
    is($e_tags[1][3], 'reply', 'reply marker');
};

subtest 'reply includes p tag for parent author' => sub {
    my $parent = make_event(
        id => $msg_id, pubkey => $bob_pk, kind => 42,
        content => 'original',
        tags => [['e', $channel_id, '', 'root']],
    );

    my $event = Net::Nostr::Channel->reply(
        pubkey     => $carol_pk,
        channel_id => $channel_id,
        to         => $parent,
        content    => 'Reply!',
    );

    my @p_tags = grep { $_->[0] eq 'p' } @{$event->tags};
    is(scalar @p_tags, 1, 'one p tag');
    is($p_tags[0][1], $bob_pk, 'p tag references parent author');
};

subtest 'reply p tag includes relay URL per NIP-10' => sub {
    my $parent = make_event(
        id => $msg_id, pubkey => $bob_pk, kind => 42,
        content => 'original',
        tags => [['e', $channel_id, '', 'root']],
    );

    my $event = Net::Nostr::Channel->reply(
        pubkey     => $carol_pk,
        channel_id => $channel_id,
        to         => $parent,
        content    => 'Reply!',
        relay_url  => 'wss://relay.example.com/',
    );

    my @p_tags = grep { $_->[0] eq 'p' } @{$event->tags};
    is($p_tags[0][2], 'wss://relay.example.com/', 'relay URL in p tag');
};

subtest 'reply does not include self in p tags' => sub {
    my $parent = make_event(
        id => $msg_id, pubkey => $alice_pk, kind => 42,
        content => 'original',
        tags => [['e', $channel_id, '', 'root']],
    );

    my $event = Net::Nostr::Channel->reply(
        pubkey     => $alice_pk,
        channel_id => $channel_id,
        to         => $parent,
        content    => 'Self reply!',
    );

    my @p_tags = grep { $_->[0] eq 'p' } @{$event->tags};
    is(scalar @p_tags, 0, 'no p tags when replying to self');
};

subtest 'reply relay_url defaults to empty string' => sub {
    my $parent = make_event(
        id => $msg_id, pubkey => $bob_pk, kind => 42,
        content => 'msg',
        tags => [['e', $channel_id, '', 'root']],
    );

    my $event = Net::Nostr::Channel->reply(
        pubkey     => $carol_pk,
        channel_id => $channel_id,
        to         => $parent,
        content    => 'Reply!',
    );

    my @e_tags = grep { $_->[0] eq 'e' } @{$event->tags};
    is($e_tags[0][2], '', 'root relay URL empty');
    is($e_tags[1][2], '', 'reply relay URL empty');
};

subtest 'reply croaks without required params' => sub {
    my $parent = make_event(
        id => $msg_id, pubkey => $bob_pk, kind => 42,
        content => 'msg',
        tags => [['e', $channel_id, '', 'root']],
    );

    ok(dies { Net::Nostr::Channel->reply(
        channel_id => $channel_id, to => $parent, content => 'x',
    ) }, 'croaks without pubkey');
    ok(dies { Net::Nostr::Channel->reply(
        pubkey => $carol_pk, to => $parent, content => 'x',
    ) }, 'croaks without channel_id');
    ok(dies { Net::Nostr::Channel->reply(
        pubkey => $carol_pk, channel_id => $channel_id, content => 'x',
    ) }, 'croaks without to');
    ok(dies { Net::Nostr::Channel->reply(
        pubkey => $carol_pk, channel_id => $channel_id, to => $parent,
    ) }, 'croaks without content');
};

subtest 'reply passes extra args to Event' => sub {
    my $parent = make_event(
        id => $msg_id, pubkey => $bob_pk, kind => 42,
        content => 'msg',
        tags => [['e', $channel_id, '', 'root']],
    );

    my $event = Net::Nostr::Channel->reply(
        pubkey     => $carol_pk,
        channel_id => $channel_id,
        to         => $parent,
        content    => 'Reply!',
        created_at => 1700000000,
    );
    is($event->created_at, 1700000000, 'created_at passed through');
};

###############################################################################
# Kind 43: Hide message
###############################################################################

subtest 'hide_message produces kind 43 event' => sub {
    my $event = Net::Nostr::Channel->hide_message(
        pubkey     => $alice_pk,
        message_id => $msg_id,
    );
    is($event->kind, 43, 'kind is 43');
};

subtest 'hide_message has e tag pointing to message' => sub {
    my $event = Net::Nostr::Channel->hide_message(
        pubkey     => $alice_pk,
        message_id => $msg_id,
    );

    my @e_tags = grep { $_->[0] eq 'e' } @{$event->tags};
    is(scalar @e_tags, 1, 'one e tag');
    is($e_tags[0][1], $msg_id, 'e tag references message');
};

subtest 'hide_message with reason' => sub {
    my $event = Net::Nostr::Channel->hide_message(
        pubkey     => $alice_pk,
        message_id => $msg_id,
        reason     => 'spam',
    );

    my $content = $JSON->decode($event->content);
    is($content->{reason}, 'spam', 'reason in content JSON');
};

subtest 'hide_message without reason has empty content' => sub {
    my $event = Net::Nostr::Channel->hide_message(
        pubkey     => $alice_pk,
        message_id => $msg_id,
    );
    is($event->content, '', 'empty content');
};

subtest 'hide_message croaks without message_id' => sub {
    ok(dies { Net::Nostr::Channel->hide_message(
        pubkey => $alice_pk,
    ) }, 'croaks without message_id');
};

subtest 'hide_message croaks without pubkey' => sub {
    ok(dies { Net::Nostr::Channel->hide_message(
        message_id => $msg_id,
    ) }, 'croaks without pubkey');
};

subtest 'hide_message passes extra args to Event' => sub {
    my $event = Net::Nostr::Channel->hide_message(
        pubkey     => $alice_pk,
        message_id => $msg_id,
        created_at => 1700000000,
    );
    is($event->created_at, 1700000000, 'created_at passed through');
};

###############################################################################
# Kind 44: Mute user
###############################################################################

subtest 'mute_user produces kind 44 event' => sub {
    my $event = Net::Nostr::Channel->mute_user(
        pubkey      => $alice_pk,
        user_pubkey => $bob_pk,
    );
    is($event->kind, 44, 'kind is 44');
};

subtest 'mute_user has p tag pointing to user' => sub {
    my $event = Net::Nostr::Channel->mute_user(
        pubkey      => $alice_pk,
        user_pubkey => $bob_pk,
    );

    my @p_tags = grep { $_->[0] eq 'p' } @{$event->tags};
    is(scalar @p_tags, 1, 'one p tag');
    is($p_tags[0][1], $bob_pk, 'p tag references muted user');
};

subtest 'mute_user with reason' => sub {
    my $event = Net::Nostr::Channel->mute_user(
        pubkey      => $alice_pk,
        user_pubkey => $bob_pk,
        reason      => 'spammer',
    );

    my $content = $JSON->decode($event->content);
    is($content->{reason}, 'spammer', 'reason in content JSON');
};

subtest 'mute_user without reason has empty content' => sub {
    my $event = Net::Nostr::Channel->mute_user(
        pubkey      => $alice_pk,
        user_pubkey => $bob_pk,
    );
    is($event->content, '', 'empty content');
};

subtest 'mute_user croaks without user_pubkey' => sub {
    ok(dies { Net::Nostr::Channel->mute_user(
        pubkey => $alice_pk,
    ) }, 'croaks without user_pubkey');
};

subtest 'mute_user croaks without pubkey' => sub {
    ok(dies { Net::Nostr::Channel->mute_user(
        user_pubkey => $bob_pk,
    ) }, 'croaks without pubkey');
};

subtest 'mute_user passes extra args to Event' => sub {
    my $event = Net::Nostr::Channel->mute_user(
        pubkey      => $alice_pk,
        user_pubkey => $bob_pk,
        created_at  => 1700000000,
    );
    is($event->created_at, 1700000000, 'created_at passed through');
};

###############################################################################
# Parse channel metadata from kind 40 event
###############################################################################

subtest 'metadata_from_event parses kind 40' => sub {
    my $event = make_event(
        pubkey  => $alice_pk,
        kind    => 40,
        content => $JSON->encode({
            name    => 'Demo Channel',
            about   => 'A test channel.',
            picture => 'https://placekitten.com/200/200',
            relays  => ['wss://nos.lol', 'wss://nostr.mom'],
        }),
    );

    my $meta = Net::Nostr::Channel->metadata_from_event($event);
    is($meta->{name}, 'Demo Channel', 'name');
    is($meta->{about}, 'A test channel.', 'about');
    is($meta->{picture}, 'https://placekitten.com/200/200', 'picture');
    is($meta->{relays}, ['wss://nos.lol', 'wss://nostr.mom'], 'relays');
};

subtest 'metadata_from_event parses kind 41' => sub {
    my $event = make_event(
        pubkey  => $alice_pk,
        kind    => 41,
        content => $JSON->encode({
            name  => 'Updated Channel',
            about => 'Updated description.',
        }),
        tags => [['e', $channel_id, 'wss://relay.com/', 'root']],
    );

    my $meta = Net::Nostr::Channel->metadata_from_event($event);
    is($meta->{name}, 'Updated Channel', 'name');
    is($meta->{about}, 'Updated description.', 'about');
};

subtest 'metadata_from_event handles missing optional fields' => sub {
    my $event = make_event(
        pubkey  => $alice_pk,
        kind    => 40,
        content => $JSON->encode({ name => 'Minimal' }),
    );

    my $meta = Net::Nostr::Channel->metadata_from_event($event);
    is($meta->{name}, 'Minimal', 'name present');
    is($meta->{about}, undef, 'about is undef');
    is($meta->{picture}, undef, 'picture is undef');
    is($meta->{relays}, undef, 'relays is undef');
};

subtest 'metadata_from_event preserves extra fields' => sub {
    my $event = make_event(
        pubkey  => $alice_pk,
        kind    => 40,
        content => $JSON->encode({
            name   => 'Demo',
            custom => 'extra field',
        }),
    );

    my $meta = Net::Nostr::Channel->metadata_from_event($event);
    is($meta->{custom}, 'extra field', 'extra metadata preserved');
};

subtest 'metadata_from_event croaks on wrong kind' => sub {
    my $event = make_event(
        pubkey => $alice_pk, kind => 1, content => 'hello',
    );
    ok(dies { Net::Nostr::Channel->metadata_from_event($event) },
        'croaks on kind 1');
};

###############################################################################
# channel_id - extract channel from event
###############################################################################

subtest 'channel_id from kind 41 event' => sub {
    my $event = make_event(
        pubkey  => $alice_pk,
        kind    => 41,
        content => $JSON->encode({ name => 'Updated' }),
        tags    => [['e', $channel_id, 'wss://relay.com/', 'root']],
    );
    is(Net::Nostr::Channel->channel_id($event), $channel_id,
        'channel_id from kind 41');
};

subtest 'channel_id from kind 42 event' => sub {
    my $event = make_event(
        pubkey  => $bob_pk,
        kind    => 42,
        content => 'Hello!',
        tags    => [['e', $channel_id, 'wss://relay.com/', 'root']],
    );
    is(Net::Nostr::Channel->channel_id($event), $channel_id,
        'channel_id from kind 42');
};

subtest 'channel_id from kind 42 reply picks root not reply' => sub {
    my $reply_msg_id = '3' x 64;
    my $event = make_event(
        pubkey  => $carol_pk,
        kind    => 42,
        content => 'Reply!',
        tags    => [
            ['e', $channel_id, '', 'root'],
            ['e', $reply_msg_id, '', 'reply'],
        ],
    );
    is(Net::Nostr::Channel->channel_id($event), $channel_id,
        'channel_id picks root e tag');
};

subtest 'channel_id returns undef for event without root e tag' => sub {
    my $event = make_event(
        pubkey  => $alice_pk,
        kind    => 1,
        content => 'standalone note',
        tags    => [],
    );
    is(Net::Nostr::Channel->channel_id($event), undef,
        'undef for event without root e tag');
};

###############################################################################
# hide_from_event - parse kind 43
###############################################################################

subtest 'hide_from_event parses kind 43 with reason' => sub {
    my $event = make_event(
        pubkey  => $alice_pk,
        kind    => 43,
        content => $JSON->encode({ reason => 'spam' }),
        tags    => [['e', $msg_id]],
    );

    my $info = Net::Nostr::Channel->hide_from_event($event);
    is($info->{message_id}, $msg_id, 'message_id');
    is($info->{reason}, 'spam', 'reason');
};

subtest 'hide_from_event parses kind 43 without reason' => sub {
    my $event = make_event(
        pubkey  => $alice_pk,
        kind    => 43,
        content => '',
        tags    => [['e', $msg_id]],
    );

    my $info = Net::Nostr::Channel->hide_from_event($event);
    is($info->{message_id}, $msg_id, 'message_id');
    is($info->{reason}, undef, 'reason is undef');
};

subtest 'hide_from_event croaks on wrong kind' => sub {
    my $event = make_event(
        pubkey => $alice_pk, kind => 1, content => 'hello',
    );
    ok(dies { Net::Nostr::Channel->hide_from_event($event) },
        'croaks on kind 1');
};

###############################################################################
# mute_from_event - parse kind 44
###############################################################################

subtest 'mute_from_event parses kind 44 with reason' => sub {
    my $event = make_event(
        pubkey  => $alice_pk,
        kind    => 44,
        content => $JSON->encode({ reason => 'spammer' }),
        tags    => [['p', $bob_pk]],
    );

    my $info = Net::Nostr::Channel->mute_from_event($event);
    is($info->{pubkey}, $bob_pk, 'pubkey');
    is($info->{reason}, 'spammer', 'reason');
};

subtest 'mute_from_event parses kind 44 without reason' => sub {
    my $event = make_event(
        pubkey  => $alice_pk,
        kind    => 44,
        content => '',
        tags    => [['p', $bob_pk]],
    );

    my $info = Net::Nostr::Channel->mute_from_event($event);
    is($info->{pubkey}, $bob_pk, 'pubkey');
    is($info->{reason}, undef, 'reason is undef');
};

subtest 'mute_from_event croaks on wrong kind' => sub {
    my $event = make_event(
        pubkey => $alice_pk, kind => 1, content => 'hello',
    );
    ok(dies { Net::Nostr::Channel->mute_from_event($event) },
        'croaks on kind 1');
};

###############################################################################
# Round-trip: create -> metadata_from_event
###############################################################################

subtest 'round-trip: create -> metadata_from_event' => sub {
    my $event = Net::Nostr::Channel->create(
        pubkey  => $alice_pk,
        name    => 'Round Trip',
        about   => 'Testing round-trip',
        picture => 'https://example.com/pic.png',
        relays  => ['wss://relay1.com', 'wss://relay2.com'],
    );

    my $meta = Net::Nostr::Channel->metadata_from_event($event);
    is($meta->{name}, 'Round Trip', 'name round-trips');
    is($meta->{about}, 'Testing round-trip', 'about round-trips');
    is($meta->{picture}, 'https://example.com/pic.png', 'picture round-trips');
    is($meta->{relays}, ['wss://relay1.com', 'wss://relay2.com'], 'relays round-trip');
};

subtest 'round-trip: set_metadata -> metadata_from_event' => sub {
    my $event = Net::Nostr::Channel->set_metadata(
        pubkey     => $alice_pk,
        channel_id => $channel_id,
        name       => 'Updated',
        about      => 'Updated desc',
    );

    my $meta = Net::Nostr::Channel->metadata_from_event($event);
    is($meta->{name}, 'Updated', 'name round-trips');
    is($meta->{about}, 'Updated desc', 'about round-trips');
};

subtest 'round-trip: set_metadata -> channel_id' => sub {
    my $event = Net::Nostr::Channel->set_metadata(
        pubkey     => $alice_pk,
        channel_id => $channel_id,
        name       => 'Updated',
    );

    is(Net::Nostr::Channel->channel_id($event), $channel_id,
        'channel_id round-trips from set_metadata');
};

subtest 'round-trip: message -> channel_id' => sub {
    my $event = Net::Nostr::Channel->message(
        pubkey     => $bob_pk,
        channel_id => $channel_id,
        content    => 'Hello!',
    );

    is(Net::Nostr::Channel->channel_id($event), $channel_id,
        'channel_id round-trips from message');
};

subtest 'round-trip: hide_message -> hide_from_event' => sub {
    my $event = Net::Nostr::Channel->hide_message(
        pubkey     => $alice_pk,
        message_id => $msg_id,
        reason     => 'inappropriate',
    );

    my $info = Net::Nostr::Channel->hide_from_event($event);
    is($info->{message_id}, $msg_id, 'message_id round-trips');
    is($info->{reason}, 'inappropriate', 'reason round-trips');
};

subtest 'round-trip: mute_user -> mute_from_event' => sub {
    my $event = Net::Nostr::Channel->mute_user(
        pubkey      => $alice_pk,
        user_pubkey => $bob_pk,
        reason      => 'annoying',
    );

    my $info = Net::Nostr::Channel->mute_from_event($event);
    is($info->{pubkey}, $bob_pk, 'pubkey round-trips');
    is($info->{reason}, 'annoying', 'reason round-trips');
};

###############################################################################
# Negative validation: invalid channel_id
###############################################################################

subtest 'set_metadata rejects invalid channel_id' => sub {
    like(
        dies { Net::Nostr::Channel->set_metadata(
            pubkey => 'a' x 64, channel_id => 'bad',
            name => 'test',
        ) },
        qr/channel_id must be 64-char lowercase hex/,
        'invalid channel_id rejected'
    );
};

subtest 'message rejects invalid channel_id' => sub {
    like(
        dies { Net::Nostr::Channel->message(
            pubkey => 'a' x 64, channel_id => 'bad',
            content => 'test',
        ) },
        qr/channel_id must be 64-char lowercase hex/,
        'invalid channel_id rejected'
    );
};

subtest 'reply rejects invalid channel_id' => sub {
    my $to = Net::Nostr::Event->new(pubkey => 'a' x 64, kind => 42, content => 'hi');
    like(
        dies { Net::Nostr::Channel->reply(
            pubkey => 'a' x 64, channel_id => 'bad',
            to => $to, content => 'test',
        ) },
        qr/channel_id must be 64-char lowercase hex/,
        'invalid channel_id rejected'
    );
};

subtest 'hide_message rejects invalid message_id' => sub {
    like(
        dies { Net::Nostr::Channel->hide_message(
            pubkey => 'a' x 64, message_id => 'bad',
        ) },
        qr/message_id must be 64-char lowercase hex/,
        'invalid message_id rejected'
    );
};

subtest 'mute_user rejects invalid user_pubkey' => sub {
    like(
        dies { Net::Nostr::Channel->mute_user(
            pubkey => 'a' x 64, user_pubkey => 'bad',
        ) },
        qr/user_pubkey must be 64-char lowercase hex/,
        'invalid user_pubkey rejected'
    );
};

done_testing;
