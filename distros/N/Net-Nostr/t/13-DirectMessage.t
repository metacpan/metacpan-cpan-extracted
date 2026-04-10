#!/usr/bin/perl

# Unit tests for Net::Nostr::DirectMessage

use strictures 2;

use Test2::V0 -no_srand => 1;

use Net::Nostr::DirectMessage;

my $PUBKEY = 'a' x 64;
my $RECIPIENT = 'b' x 64;

###############################################################################
# create validation
###############################################################################

subtest 'create requires sender_pubkey' => sub {
    like(dies { Net::Nostr::DirectMessage->create(
        content    => 'hello',
        recipients => [$RECIPIENT],
    ) }, qr/sender_pubkey required/i, 'missing sender_pubkey');
};

subtest 'create requires content' => sub {
    like(dies { Net::Nostr::DirectMessage->create(
        sender_pubkey => $PUBKEY,
        recipients    => [$RECIPIENT],
    ) }, qr/content required/i, 'missing content');
};

subtest 'create requires recipients' => sub {
    like(dies { Net::Nostr::DirectMessage->create(
        sender_pubkey => $PUBKEY,
        content       => 'hello',
    ) }, qr/recipients required/i, 'missing recipients');
};

###############################################################################
# create_file validation
###############################################################################

subtest 'create_file requires file_type' => sub {
    like(dies { Net::Nostr::DirectMessage->create_file(
        sender_pubkey        => $PUBKEY,
        content              => 'https://example.com/file',
        recipients           => [$RECIPIENT],
        encryption_algorithm => 'aes-gcm',
        decryption_key       => 'key',
        decryption_nonce     => 'nonce',
        x                    => 'f' x 64,
    ) }, qr/file_type required/i, 'missing file_type');
};

###############################################################################
# create_relay_list validation
###############################################################################

subtest 'create_relay_list requires pubkey' => sub {
    like(dies { Net::Nostr::DirectMessage->create_relay_list(
        relays => ['wss://relay.example.com'],
    ) }, qr/pubkey required/i, 'missing pubkey');
};

subtest 'create_relay_list requires relays' => sub {
    like(dies { Net::Nostr::DirectMessage->create_relay_list(
        pubkey => $PUBKEY,
    ) }, qr/relays required/i, 'missing relays');
};

###############################################################################
# receive validation
###############################################################################

subtest 'receive requires event' => sub {
    require Net::Nostr::Key;
    my $key = Net::Nostr::Key->new;
    like(dies { Net::Nostr::DirectMessage->receive(
        recipient_key => $key,
    ) }, qr/event required/i, 'missing event');
};

subtest 'receive requires recipient_key' => sub {
    require Net::Nostr::Event;
    my $event = Net::Nostr::Event->new(
        pubkey => 'a' x 64, kind => 1059, content => '', tags => [],
    );
    like(dies { Net::Nostr::DirectMessage->receive(
        event => $event,
    ) }, qr/recipient_key required/i, 'missing recipient_key');
};

###############################################################################
# POD example: SYNOPSIS round-trip
###############################################################################

subtest 'POD SYNOPSIS example' => sub {
    require Net::Nostr::Key;
    my $sender    = Net::Nostr::Key->new;
    my $recipient = Net::Nostr::Key->new;

    my $msg = Net::Nostr::DirectMessage->create(
        sender_pubkey => $sender->pubkey_hex,
        content       => 'Hola, que tal?',
        recipients    => [$recipient->pubkey_hex],
        subject       => 'Party',
    );

    my @wraps = Net::Nostr::DirectMessage->wrap_for_recipients(
        rumor      => $msg,
        sender_key => $sender,
    );

    my $received = Net::Nostr::DirectMessage->receive(
        event         => $wraps[0],
        recipient_key => $recipient,
    );
    is($received->content, 'Hola, que tal?', 'content matches');

    my $relay_list = Net::Nostr::DirectMessage->create_relay_list(
        pubkey => $sender->pubkey_hex,
        relays => ['wss://inbox.nostr.wine', 'wss://myrelay.nostr1.com'],
    );
    is($relay_list->kind, 10050, 'relay list is kind 10050');
};

###############################################################################
# POD example: quotes
###############################################################################

subtest 'POD quotes example' => sub {
    my $cited_id     = 'd' x 64;
    my $cited_pubkey = 'e' x 64;
    my $msg = Net::Nostr::DirectMessage->create(
        sender_pubkey => $PUBKEY,
        content       => 'check this out',
        recipients    => [$RECIPIENT],
        quotes        => [[$cited_id, 'wss://relay.example.com', $cited_pubkey]],
    );

    my @q_tags = grep { $_->[0] eq 'q' } @{$msg->tags};
    is(scalar @q_tags, 1, 'one q-tag');
    is($q_tags[0][1], $cited_id, 'q-tag event id');
    is($q_tags[0][2], 'wss://relay.example.com', 'q-tag relay');
    is($q_tags[0][3], $cited_pubkey, 'q-tag pubkey');
};

###############################################################################
# POD example: wrap_for_recipients with skip_sender
###############################################################################

subtest 'POD skip_sender example' => sub {
    require Net::Nostr::Key;
    my $sender    = Net::Nostr::Key->new;
    my $recipient = Net::Nostr::Key->new;

    my $msg = Net::Nostr::DirectMessage->create(
        sender_pubkey => $sender->pubkey_hex,
        content       => 'no copy for me',
        recipients    => [$recipient->pubkey_hex],
    );

    my @wraps = Net::Nostr::DirectMessage->wrap_for_recipients(
        rumor       => $msg,
        sender_key  => $sender,
        skip_sender => 1,
    );

    is(scalar @wraps, 1, 'only recipient wrap, no sender copy');
};

###############################################################################
# POD example: create_file with optional tags
###############################################################################

subtest 'POD create_file optional tags example' => sub {
    my $msg = Net::Nostr::DirectMessage->create_file(
        sender_pubkey        => $PUBKEY,
        content              => 'https://example.com/encrypted-photo.bin',
        recipients           => [$RECIPIENT],
        file_type            => 'image/jpeg',
        encryption_algorithm => 'aes-gcm',
        decryption_key       => 'abc123',
        decryption_nonce     => 'def456',
        x                    => 'f' x 64,
        ox                   => 'a' x 64,
        size                 => '2048000',
        dim                  => '1920x1080',
        blurhash             => 'LEHV6nWB2yk8',
        thumb                => 'https://example.com/thumb.bin',
        fallback             => ['https://backup.example.com/photo.bin'],
        subject              => 'Vacation photos',
    );

    is($msg->kind, 15, 'kind 15');
    my %tags;
    for my $tag (@{$msg->tags}) {
        push @{$tags{$tag->[0]}}, $tag->[1];
    }
    is($tags{ox}[0], 'a' x 64, 'ox tag');
    is($tags{size}[0], '2048000', 'size tag');
    is($tags{dim}[0], '1920x1080', 'dim tag');
    is($tags{blurhash}[0], 'LEHV6nWB2yk8', 'blurhash tag');
    is($tags{thumb}[0], 'https://example.com/thumb.bin', 'thumb tag');
    is($tags{fallback}[0], 'https://backup.example.com/photo.bin', 'fallback tag');
    is($tags{subject}[0], 'Vacation photos', 'subject tag');
};

###############################################################################
# POD example: chat_members
###############################################################################

subtest 'POD chat_members example' => sub {
    require Net::Nostr::Key;
    my $alice = Net::Nostr::Key->new;
    my $bob   = Net::Nostr::Key->new;

    my $msg = Net::Nostr::DirectMessage->create(
        sender_pubkey => $alice->pubkey_hex,
        content       => 'hello',
        recipients    => [$bob->pubkey_hex],
    );

    my @members = Net::Nostr::DirectMessage->chat_members($msg);
    is(scalar @members, 2, 'two members');
    is($members[0], $alice->pubkey_hex, 'first member is sender');
    is($members[1], $bob->pubkey_hex, 'second member is recipient');
};

###############################################################################
# POD example: receive return value
###############################################################################

subtest 'POD receive example' => sub {
    require Net::Nostr::Key;
    require Net::Nostr::GiftWrap;
    my $sender    = Net::Nostr::Key->new;
    my $recipient = Net::Nostr::Key->new;

    my $msg = Net::Nostr::DirectMessage->create(
        sender_pubkey => $sender->pubkey_hex,
        content       => 'secret message',
        recipients    => [$recipient->pubkey_hex],
        subject       => 'Test',
    );

    my $wrap = Net::Nostr::GiftWrap->seal_and_wrap(
        rumor            => $msg,
        sender_key       => $sender,
        recipient_pubkey => $recipient->pubkey_hex,
    );

    my $rumor = Net::Nostr::DirectMessage->receive(
        event         => $wrap,
        recipient_key => $recipient,
    );

    is($rumor->kind, 14, 'kind preserved');
    is($rumor->content, 'secret message', 'content preserved');
    is($rumor->pubkey, $sender->pubkey_hex, 'sender identified');
    my @subj = grep { $_->[0] eq 'subject' } @{$rumor->tags};
    is($subj[0][1], 'Test', 'subject preserved');
};

###############################################################################
# POD example: receive rejects impersonation
###############################################################################

subtest 'POD receive rejects impersonation' => sub {
    require Net::Nostr::Key;
    require Net::Nostr::GiftWrap;
    my $sender    = Net::Nostr::Key->new;
    my $attacker  = Net::Nostr::Key->new;
    my $recipient = Net::Nostr::Key->new;

    my $forged = Net::Nostr::DirectMessage->create(
        sender_pubkey => $sender->pubkey_hex,
        content       => 'forged',
        recipients    => [$recipient->pubkey_hex],
    );

    my $wrap = Net::Nostr::GiftWrap->seal_and_wrap(
        rumor            => $forged,
        sender_key       => $attacker,
        recipient_pubkey => $recipient->pubkey_hex,
    );

    like(dies { Net::Nostr::DirectMessage->receive(
        event         => $wrap,
        recipient_key => $recipient,
    ) }, qr/pubkey mismatch/, 'rejects seal/rumor pubkey mismatch');
};

done_testing;
