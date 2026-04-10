#!/usr/bin/perl

# Unit tests for Net::Nostr::Channel
# Tests every code example in the POD

use strictures 2;

use Test2::V0 -no_srand => 1;

use lib 't/lib';
use TestFixtures qw(make_event);

use JSON ();
use Net::Nostr::Channel;

my $JSON = JSON->new->utf8;

my $pubkey     = 'aa' x 32;
my $other_pk   = 'bb' x 32;
my $channel_id = 'cc' x 32;
my $event_id   = 'dd' x 32;
my $relay      = 'wss://relay.example.com/';

###############################################################################
# POD SYNOPSIS examples
###############################################################################

subtest 'SYNOPSIS: create a channel' => sub {
    my $event = Net::Nostr::Channel->create(
        pubkey  => $pubkey,
        name    => 'Perl Nostr',
        about   => 'Discussion about Perl and Nostr',
        picture => 'https://example.com/perl.png',
        relays  => ['wss://relay.example.com/'],
    );
    is($event->kind, 40, 'kind 40');
    my $meta = $JSON->decode($event->content);
    is($meta->{name}, 'Perl Nostr', 'name in content');
    is($meta->{about}, 'Discussion about Perl and Nostr', 'about in content');
    is($meta->{picture}, 'https://example.com/perl.png', 'picture in content');
    is($meta->{relays}, ['wss://relay.example.com/'], 'relays in content');
};

subtest 'SYNOPSIS: set_metadata' => sub {
    my $update = Net::Nostr::Channel->set_metadata(
        pubkey     => $pubkey,
        channel_id => $channel_id,
        name       => 'Perl Nostr Chat',
        relay_url  => 'wss://relay.example.com/',
        categories => ['perl', 'nostr'],
    );
    is($update->kind, 41, 'kind 41');
    my $tags = $update->tags;
    is($tags->[0], ['e', $channel_id, 'wss://relay.example.com/', 'root'], 'root e tag');
    is($tags->[1], ['t', 'perl'], 't tag perl');
    is($tags->[2], ['t', 'nostr'], 't tag nostr');
};

subtest 'SYNOPSIS: message' => sub {
    my $msg = Net::Nostr::Channel->message(
        pubkey     => $pubkey,
        channel_id => $channel_id,
        content    => 'Hello, channel!',
        relay_url  => 'wss://relay.example.com/',
    );
    is($msg->kind, 42, 'kind 42');
    is($msg->content, 'Hello, channel!', 'content');
};

subtest 'SYNOPSIS: reply' => sub {
    my $parent = make_event(kind => 42, pubkey => $other_pk);
    my $reply = Net::Nostr::Channel->reply(
        pubkey     => $pubkey,
        channel_id => $channel_id,
        to         => $parent,
        content    => 'Welcome!',
    );
    is($reply->kind, 42, 'kind 42');
};

subtest 'SYNOPSIS: hide_message' => sub {
    my $msg = make_event(kind => 42, pubkey => $pubkey);
    my $hide = Net::Nostr::Channel->hide_message(
        pubkey     => $pubkey,
        message_id => $msg->id,
        reason     => 'spam',
    );
    is($hide->kind, 43, 'kind 43');
};

subtest 'SYNOPSIS: mute_user' => sub {
    my $mute = Net::Nostr::Channel->mute_user(
        pubkey      => $pubkey,
        user_pubkey => $other_pk,
        reason      => 'spammer',
    );
    is($mute->kind, 44, 'kind 44');
};

subtest 'SYNOPSIS: metadata_from_event' => sub {
    my $event = Net::Nostr::Channel->create(
        pubkey  => $pubkey,
        name    => 'Perl Nostr',
        about   => 'Discussion about Perl and Nostr',
        picture => 'https://example.com/perl.png',
    );
    my $meta = Net::Nostr::Channel->metadata_from_event($event);
    is($meta->{name}, 'Perl Nostr', 'name');
    is($meta->{about}, 'Discussion about Perl and Nostr', 'about');
    is($meta->{picture}, 'https://example.com/perl.png', 'picture');
};

subtest 'SYNOPSIS: channel_id' => sub {
    my $msg = Net::Nostr::Channel->message(
        pubkey     => $pubkey,
        channel_id => $channel_id,
        content    => 'test',
    );
    my $ch_id = Net::Nostr::Channel->channel_id($msg);
    is($ch_id, $channel_id, 'channel_id extracted');
};

subtest 'SYNOPSIS: hide_from_event' => sub {
    my $hide = Net::Nostr::Channel->hide_message(
        pubkey     => $pubkey,
        message_id => $event_id,
        reason     => 'off-topic',
    );
    my $info = Net::Nostr::Channel->hide_from_event($hide);
    is($info->{message_id}, $event_id, 'message_id');
    is($info->{reason}, 'off-topic', 'reason');
};

subtest 'SYNOPSIS: mute_from_event' => sub {
    my $mute = Net::Nostr::Channel->mute_user(
        pubkey      => $pubkey,
        user_pubkey => $other_pk,
        reason      => 'posting spam',
    );
    my $info = Net::Nostr::Channel->mute_from_event($mute);
    is($info->{pubkey}, $other_pk, 'pubkey');
    is($info->{reason}, 'posting spam', 'reason');
};

###############################################################################
# create()
###############################################################################

subtest 'create: required args' => sub {
    like(dies { Net::Nostr::Channel->create(name => 'x') },
        qr/requires 'pubkey'/, 'dies without pubkey');
    like(dies { Net::Nostr::Channel->create(pubkey => $pubkey) },
        qr/requires 'name'/, 'dies without name');
};

subtest 'create: minimal' => sub {
    my $event = Net::Nostr::Channel->create(
        pubkey => $pubkey,
        name   => 'My Channel',
    );
    is($event->kind, 40, 'kind 40');
    is($event->tags, [], 'empty tags');
    is($event->pubkey, $pubkey, 'pubkey');
    my $meta = $JSON->decode($event->content);
    is($meta->{name}, 'My Channel', 'name in JSON');
    ok(!exists $meta->{about}, 'no about');
    ok(!exists $meta->{picture}, 'no picture');
    ok(!exists $meta->{relays}, 'no relays');
};

subtest 'create: all optional fields' => sub {
    my $event = Net::Nostr::Channel->create(
        pubkey  => $pubkey,
        name    => 'Full',
        about   => 'A full channel',
        picture => 'https://example.com/pic.png',
        relays  => ['wss://r1.com', 'wss://r2.com'],
    );
    my $meta = $JSON->decode($event->content);
    is($meta->{about}, 'A full channel', 'about');
    is($meta->{picture}, 'https://example.com/pic.png', 'picture');
    is($meta->{relays}, ['wss://r1.com', 'wss://r2.com'], 'relays');
};

subtest 'create: metadata hash merges into content' => sub {
    my $event = Net::Nostr::Channel->create(
        pubkey   => $pubkey,
        name     => 'Rules',
        metadata => { rules => 'Be nice', language => 'en' },
    );
    my $meta = $JSON->decode($event->content);
    is($meta->{name}, 'Rules', 'name preserved');
    is($meta->{rules}, 'Be nice', 'custom rules field');
    is($meta->{language}, 'en', 'custom language field');
};

###############################################################################
# set_metadata()
###############################################################################

subtest 'set_metadata: required args' => sub {
    like(dies { Net::Nostr::Channel->set_metadata(channel_id => $channel_id) },
        qr/requires 'pubkey'/, 'dies without pubkey');
    like(dies { Net::Nostr::Channel->set_metadata(pubkey => $pubkey) },
        qr/requires 'channel_id'/, 'dies without channel_id');
};

subtest 'set_metadata: bad channel_id' => sub {
    like(dies { Net::Nostr::Channel->set_metadata(
        pubkey => $pubkey, channel_id => 'ZZZZ') },
        qr/64-char lowercase hex/, 'rejects non-hex');
    like(dies { Net::Nostr::Channel->set_metadata(
        pubkey => $pubkey, channel_id => 'aa' x 31) },
        qr/64-char lowercase hex/, 'rejects short hex');
    like(dies { Net::Nostr::Channel->set_metadata(
        pubkey => $pubkey, channel_id => 'AA' x 32) },
        qr/64-char lowercase hex/, 'rejects uppercase hex');
};

subtest 'set_metadata: minimal' => sub {
    my $event = Net::Nostr::Channel->set_metadata(
        pubkey     => $pubkey,
        channel_id => $channel_id,
    );
    is($event->kind, 41, 'kind 41');
    my $tags = $event->tags;
    is($tags->[0], ['e', $channel_id, '', 'root'], 'root e tag with empty relay_url');
    is(scalar @$tags, 1, 'only root tag');
    my $meta = $JSON->decode($event->content);
    is($meta, {}, 'empty metadata');
};

subtest 'set_metadata: all optional fields' => sub {
    my $event = Net::Nostr::Channel->set_metadata(
        pubkey     => $pubkey,
        channel_id => $channel_id,
        name       => 'Updated Name',
        about      => 'New about',
        picture    => 'https://new.pic',
        relays     => ['wss://r.com'],
        relay_url  => 'wss://relay.example.com/',
        categories => ['nostr', 'perl'],
        metadata   => { rules => 'Updated rules' },
    );
    is($event->kind, 41, 'kind 41');

    my $tags = $event->tags;
    is($tags->[0], ['e', $channel_id, 'wss://relay.example.com/', 'root'], 'root e tag with relay');
    is($tags->[1], ['t', 'nostr'], 't tag nostr');
    is($tags->[2], ['t', 'perl'], 't tag perl');

    my $meta = $JSON->decode($event->content);
    is($meta->{name}, 'Updated Name', 'name');
    is($meta->{about}, 'New about', 'about');
    is($meta->{picture}, 'https://new.pic', 'picture');
    is($meta->{relays}, ['wss://r.com'], 'relays');
    is($meta->{rules}, 'Updated rules', 'custom metadata');
};

subtest 'set_metadata: POD example with categories' => sub {
    my $update = Net::Nostr::Channel->set_metadata(
        pubkey     => $pubkey,
        channel_id => $channel_id,
        name       => 'Updated Name',
        categories => ['nostr', 'perl'],
    );
    my $tags = $update->tags;
    is($tags, [
        ['e', $channel_id, '', 'root'],
        ['t', 'nostr'],
        ['t', 'perl'],
    ], 'tags match POD example');
};

###############################################################################
# message()
###############################################################################

subtest 'message: required args' => sub {
    like(dies { Net::Nostr::Channel->message(
        channel_id => $channel_id, content => 'x') },
        qr/requires 'pubkey'/, 'dies without pubkey');
    like(dies { Net::Nostr::Channel->message(
        pubkey => $pubkey, content => 'x') },
        qr/requires 'channel_id'/, 'dies without channel_id');
    like(dies { Net::Nostr::Channel->message(
        pubkey => $pubkey, channel_id => $channel_id) },
        qr/requires 'content'/, 'dies without content');
};

subtest 'message: bad channel_id' => sub {
    like(dies { Net::Nostr::Channel->message(
        pubkey => $pubkey, channel_id => 'nothex', content => 'x') },
        qr/64-char lowercase hex/, 'rejects bad hex');
};

subtest 'message: basic' => sub {
    my $msg = Net::Nostr::Channel->message(
        pubkey     => $pubkey,
        channel_id => $channel_id,
        content    => 'First message!',
    );
    is($msg->kind, 42, 'kind 42');
    is($msg->content, 'First message!', 'content');
    is($msg->tags, [['e', $channel_id, '', 'root']], 'tags: root e tag');
};

subtest 'message: with relay_url' => sub {
    my $msg = Net::Nostr::Channel->message(
        pubkey     => $pubkey,
        channel_id => $channel_id,
        content    => 'test',
        relay_url  => $relay,
    );
    is($msg->tags, [['e', $channel_id, $relay, 'root']], 'relay_url in e tag');
};

###############################################################################
# reply()
###############################################################################

subtest 'reply: required args' => sub {
    my $parent = make_event(kind => 42, pubkey => $other_pk);
    like(dies { Net::Nostr::Channel->reply(
        channel_id => $channel_id, to => $parent, content => 'x') },
        qr/requires 'pubkey'/, 'dies without pubkey');
    like(dies { Net::Nostr::Channel->reply(
        pubkey => $pubkey, to => $parent, content => 'x') },
        qr/requires 'channel_id'/, 'dies without channel_id');
    like(dies { Net::Nostr::Channel->reply(
        pubkey => $pubkey, channel_id => $channel_id, content => 'x') },
        qr/requires 'to'/, 'dies without to');
    like(dies { Net::Nostr::Channel->reply(
        pubkey => $pubkey, channel_id => $channel_id, to => $parent) },
        qr/requires 'content'/, 'dies without content');
};

subtest 'reply: bad channel_id' => sub {
    my $parent = make_event(kind => 42, pubkey => $other_pk);
    like(dies { Net::Nostr::Channel->reply(
        pubkey => $pubkey, channel_id => 'bad', to => $parent, content => 'x') },
        qr/64-char lowercase hex/, 'rejects bad channel_id');
};

subtest 'reply: basic with p tag' => sub {
    my $parent = make_event(kind => 42, pubkey => $other_pk);
    my $reply = Net::Nostr::Channel->reply(
        pubkey     => $pubkey,
        channel_id => $channel_id,
        to         => $parent,
        content    => 'I agree!',
    );
    is($reply->kind, 42, 'kind 42');
    is($reply->content, 'I agree!', 'content');
    my $tags = $reply->tags;
    is($tags->[0], ['e', $channel_id, '', 'root'], 'root e tag');
    is($tags->[1], ['e', $parent->id, '', 'reply'], 'reply e tag');
    is($tags->[2], ['p', $parent->pubkey, ''], 'p tag for parent author');
    is(scalar @$tags, 3, 'three tags total');
};

subtest 'reply: POD example tags structure' => sub {
    my $msg = make_event(kind => 42, pubkey => $other_pk);
    my $reply = Net::Nostr::Channel->reply(
        pubkey     => $pubkey,
        channel_id => $channel_id,
        to         => $msg,
        content    => 'I agree!',
    );
    my $tags = $reply->tags;
    is($tags, [
        ['e', $channel_id, '', 'root'],
        ['e', $msg->id, '', 'reply'],
        ['p', $msg->pubkey, ''],
    ], 'tags match POD example');
};

subtest 'reply: with relay_url' => sub {
    my $parent = make_event(kind => 42, pubkey => $other_pk);
    my $reply = Net::Nostr::Channel->reply(
        pubkey     => $pubkey,
        channel_id => $channel_id,
        to         => $parent,
        content    => 'test',
        relay_url  => $relay,
    );
    my $tags = $reply->tags;
    is($tags->[0][2], $relay, 'relay in root tag');
    is($tags->[1][2], $relay, 'relay in reply tag');
    is($tags->[2][2], $relay, 'relay in p tag');
};

subtest 'reply: to self omits p tag' => sub {
    my $parent = make_event(kind => 42, pubkey => $pubkey);
    my $reply = Net::Nostr::Channel->reply(
        pubkey     => $pubkey,
        channel_id => $channel_id,
        to         => $parent,
        content    => 'Replying to myself',
    );
    my $tags = $reply->tags;
    is(scalar @$tags, 2, 'only two tags (no p tag)');
    is($tags->[0], ['e', $channel_id, '', 'root'], 'root e tag');
    is($tags->[1], ['e', $parent->id, '', 'reply'], 'reply e tag');
};

###############################################################################
# hide_message()
###############################################################################

subtest 'hide_message: required args' => sub {
    like(dies { Net::Nostr::Channel->hide_message(message_id => $event_id) },
        qr/requires 'pubkey'/, 'dies without pubkey');
    like(dies { Net::Nostr::Channel->hide_message(pubkey => $pubkey) },
        qr/requires 'message_id'/, 'dies without message_id');
};

subtest 'hide_message: bad message_id' => sub {
    like(dies { Net::Nostr::Channel->hide_message(
        pubkey => $pubkey, message_id => 'nothex') },
        qr/64-char lowercase hex/, 'rejects bad hex');
    like(dies { Net::Nostr::Channel->hide_message(
        pubkey => $pubkey, message_id => 'AA' x 32) },
        qr/64-char lowercase hex/, 'rejects uppercase hex');
};

subtest 'hide_message: without reason' => sub {
    my $hide = Net::Nostr::Channel->hide_message(
        pubkey     => $pubkey,
        message_id => $event_id,
    );
    is($hide->kind, 43, 'kind 43');
    is($hide->content, '', 'empty content without reason');
    is($hide->tags, [['e', $event_id]], 'e tag with message_id');
};

subtest 'hide_message: with reason (POD example)' => sub {
    my $hide = Net::Nostr::Channel->hide_message(
        pubkey     => $pubkey,
        message_id => $event_id,
        reason     => 'off-topic',
    );
    is($hide->kind, 43, 'kind 43');
    my $parsed = $JSON->decode($hide->content);
    is($parsed, { reason => 'off-topic' }, 'reason in JSON content');
    is($hide->tags, [['e', $event_id]], 'e tag');
};

###############################################################################
# mute_user()
###############################################################################

subtest 'mute_user: required args' => sub {
    like(dies { Net::Nostr::Channel->mute_user(user_pubkey => $other_pk) },
        qr/requires 'pubkey'/, 'dies without pubkey');
    like(dies { Net::Nostr::Channel->mute_user(pubkey => $pubkey) },
        qr/requires 'user_pubkey'/, 'dies without user_pubkey');
};

subtest 'mute_user: bad user_pubkey' => sub {
    like(dies { Net::Nostr::Channel->mute_user(
        pubkey => $pubkey, user_pubkey => 'nothex') },
        qr/64-char lowercase hex/, 'rejects bad hex');
    like(dies { Net::Nostr::Channel->mute_user(
        pubkey => $pubkey, user_pubkey => 'aa' x 31) },
        qr/64-char lowercase hex/, 'rejects short hex');
};

subtest 'mute_user: without reason' => sub {
    my $mute = Net::Nostr::Channel->mute_user(
        pubkey      => $pubkey,
        user_pubkey => $other_pk,
    );
    is($mute->kind, 44, 'kind 44');
    is($mute->content, '', 'empty content without reason');
    is($mute->tags, [['p', $other_pk]], 'p tag with user_pubkey');
};

subtest 'mute_user: with reason (POD example)' => sub {
    my $mute = Net::Nostr::Channel->mute_user(
        pubkey      => $pubkey,
        user_pubkey => $other_pk,
        reason      => 'posting spam',
    );
    is($mute->kind, 44, 'kind 44');
    my $parsed = $JSON->decode($mute->content);
    is($parsed, { reason => 'posting spam' }, 'reason in JSON content');
    is($mute->tags, [['p', $other_pk]], 'p tag');
};

###############################################################################
# metadata_from_event()
###############################################################################

subtest 'metadata_from_event: kind 40' => sub {
    my $event = Net::Nostr::Channel->create(
        pubkey  => $pubkey,
        name    => 'Test',
        about   => 'About text',
    );
    my $meta = Net::Nostr::Channel->metadata_from_event($event);
    is($meta->{name}, 'Test', 'name');
    is($meta->{about}, 'About text', 'about');
};

subtest 'metadata_from_event: kind 41' => sub {
    my $event = Net::Nostr::Channel->set_metadata(
        pubkey     => $pubkey,
        channel_id => $channel_id,
        name       => 'Updated',
    );
    my $meta = Net::Nostr::Channel->metadata_from_event($event);
    is($meta->{name}, 'Updated', 'name from kind 41');
};

subtest 'metadata_from_event: POD example' => sub {
    my $event = Net::Nostr::Channel->create(
        pubkey => $pubkey,
        name   => 'Test',
    );
    my $meta = Net::Nostr::Channel->metadata_from_event($event);
    is($meta->{name}, 'Test', 'name from POD');
};

subtest 'metadata_from_event: rejects wrong kind' => sub {
    my $event = make_event(kind => 1);
    like(dies { Net::Nostr::Channel->metadata_from_event($event) },
        qr/kind 40 or 41/, 'croaks for kind 1');

    my $k42 = Net::Nostr::Channel->message(
        pubkey     => $pubkey,
        channel_id => $channel_id,
        content    => 'msg',
    );
    like(dies { Net::Nostr::Channel->metadata_from_event($k42) },
        qr/kind 40 or 41/, 'croaks for kind 42');
};

###############################################################################
# channel_id()
###############################################################################

subtest 'channel_id: extracts from message' => sub {
    my $msg = Net::Nostr::Channel->message(
        pubkey     => $pubkey,
        channel_id => $channel_id,
        content    => 'test',
    );
    is(Net::Nostr::Channel->channel_id($msg), $channel_id, 'extracted');
};

subtest 'channel_id: extracts from set_metadata' => sub {
    my $event = Net::Nostr::Channel->set_metadata(
        pubkey     => $pubkey,
        channel_id => $channel_id,
    );
    is(Net::Nostr::Channel->channel_id($event), $channel_id, 'extracted');
};

subtest 'channel_id: returns undef without root e tag' => sub {
    my $event = make_event(kind => 1, tags => []);
    is(Net::Nostr::Channel->channel_id($event), undef, 'undef for no root tag');
};

subtest 'channel_id: ignores non-root e tags' => sub {
    my $event = make_event(kind => 42, tags => [
        ['e', $event_id, '', 'reply'],
    ]);
    is(Net::Nostr::Channel->channel_id($event), undef, 'undef for reply-only tag');
};

subtest 'channel_id: POD example' => sub {
    my $msg = Net::Nostr::Channel->message(
        pubkey     => $pubkey,
        channel_id => $channel_id,
        content    => 'test',
    );
    my $ch_id = Net::Nostr::Channel->channel_id($msg);
    is($ch_id, $channel_id, 'POD example');
};

###############################################################################
# hide_from_event()
###############################################################################

subtest 'hide_from_event: with reason' => sub {
    my $hide = Net::Nostr::Channel->hide_message(
        pubkey     => $pubkey,
        message_id => $event_id,
        reason     => 'spam',
    );
    my $info = Net::Nostr::Channel->hide_from_event($hide);
    is($info->{message_id}, $event_id, 'message_id');
    is($info->{reason}, 'spam', 'reason');
};

subtest 'hide_from_event: without reason' => sub {
    my $hide = Net::Nostr::Channel->hide_message(
        pubkey     => $pubkey,
        message_id => $event_id,
    );
    my $info = Net::Nostr::Channel->hide_from_event($hide);
    is($info->{message_id}, $event_id, 'message_id');
    is($info->{reason}, undef, 'reason is undef');
};

subtest 'hide_from_event: POD example' => sub {
    my $hide = Net::Nostr::Channel->hide_message(
        pubkey     => $pubkey,
        message_id => $event_id,
        reason     => 'off-topic',
    );
    my $info = Net::Nostr::Channel->hide_from_event($hide);
    is($info->{message_id}, $event_id, 'message_id');
    is($info->{reason}, 'off-topic', 'reason');
};

subtest 'hide_from_event: rejects wrong kind' => sub {
    my $event = make_event(kind => 1);
    like(dies { Net::Nostr::Channel->hide_from_event($event) },
        qr/kind 43/, 'croaks for wrong kind');

    my $k44 = Net::Nostr::Channel->mute_user(
        pubkey      => $pubkey,
        user_pubkey => $other_pk,
    );
    like(dies { Net::Nostr::Channel->hide_from_event($k44) },
        qr/kind 43/, 'croaks for kind 44');
};

###############################################################################
# mute_from_event()
###############################################################################

subtest 'mute_from_event: with reason' => sub {
    my $mute = Net::Nostr::Channel->mute_user(
        pubkey      => $pubkey,
        user_pubkey => $other_pk,
        reason      => 'spammer',
    );
    my $info = Net::Nostr::Channel->mute_from_event($mute);
    is($info->{pubkey}, $other_pk, 'pubkey');
    is($info->{reason}, 'spammer', 'reason');
};

subtest 'mute_from_event: without reason' => sub {
    my $mute = Net::Nostr::Channel->mute_user(
        pubkey      => $pubkey,
        user_pubkey => $other_pk,
    );
    my $info = Net::Nostr::Channel->mute_from_event($mute);
    is($info->{pubkey}, $other_pk, 'pubkey');
    is($info->{reason}, undef, 'reason is undef');
};

subtest 'mute_from_event: POD example' => sub {
    my $mute = Net::Nostr::Channel->mute_user(
        pubkey      => $pubkey,
        user_pubkey => $other_pk,
        reason      => 'posting spam',
    );
    my $info = Net::Nostr::Channel->mute_from_event($mute);
    is($info->{pubkey}, $other_pk, 'pubkey');
    is($info->{reason}, 'posting spam', 'reason');
};

subtest 'mute_from_event: rejects wrong kind' => sub {
    my $event = make_event(kind => 1);
    like(dies { Net::Nostr::Channel->mute_from_event($event) },
        qr/kind 44/, 'croaks for wrong kind');

    my $k43 = Net::Nostr::Channel->hide_message(
        pubkey     => $pubkey,
        message_id => $event_id,
    );
    like(dies { Net::Nostr::Channel->mute_from_event($k43) },
        qr/kind 44/, 'croaks for kind 43');
};

done_testing;
