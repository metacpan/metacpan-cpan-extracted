#!/usr/bin/perl

# NIP-17 conformance tests: Private Direct Messages

use strictures 2;

use Test2::V0 -no_srand => 1;

use lib 't/lib';
use TestFixtures qw(make_key_from_hex);

use Net::Nostr::DirectMessage;
use Net::Nostr::GiftWrap;
use Net::Nostr::Event;
use Net::Nostr::Key;
use Net::Nostr::Bech32;
use Net::Nostr::Encryption;
use JSON ();

###############################################################################
# Spec example keys (from NIP-17 examples section)
###############################################################################

my $SENDER_HEX    = Net::Nostr::Bech32::decode_nsec(
    'nsec1w8udu59ydjvedgs3yv5qccshcj8k05fh3l60k9x57asjrqdpa00qkmr89m');
my $RECIPIENT_HEX = Net::Nostr::Bech32::decode_nsec(
    'nsec12ywtkplvyq5t6twdqwwygavp5lm4fhuang89c943nf2z92eez43szvn4dt');

my $sender_key    = make_key_from_hex($SENDER_HEX);
my $recipient_key = make_key_from_hex($RECIPIENT_HEX);

my $SENDER_PUBKEY    = $sender_key->pubkey_hex;
my $RECIPIENT_PUBKEY = $recipient_key->pubkey_hex;

###############################################################################
# Spec example: decrypt NIP-17 gift wraps
###############################################################################

# Gift wrap to recipient (from spec)
my $WRAP_TO_RECIPIENT = Net::Nostr::Event->new(
    id         => '2886780f7349afc1344047524540ee716f7bdc1b64191699855662330bf235d8',
    pubkey     => '8f8a7ec43b77d25799281207e1a47f7a654755055788f7482653f9c9661c6d51',
    created_at => 1703128320,
    kind       => 1059,
    tags       => [['p', '918e2da906df4ccd12c8ac672d8335add131a4cf9d27ce42b3bb3625755f0788']],
    content    => 'AsqzdlMsG304G8h08bE67dhAR1gFTzTckUUyuvndZ8LrGCvwI4pgC3d6hyAK0Wo9gtkLqSr2rT2RyHlE5wRqbCOlQ8WvJEKwqwIJwT5PO3l2RxvGCHDbd1b1o40ZgIVwwLCfOWJ86I5upXe8K5AgpxYTOM1BD+SbgI5jOMA8tgpRoitJedVSvBZsmwAxXM7o7sbOON4MXHzOqOZpALpS2zgBDXSAaYAsTdEM4qqFeik+zTk3+L6NYuftGidqVluicwSGS2viYWr5OiJ1zrj1ERhYSGLpQnPKrqDaDi7R1KrHGFGyLgkJveY/45y0rv9aVIw9IWF11u53cf2CP7akACel2WvZdl1htEwFu/v9cFXD06fNVZjfx3OssKM/uHPE9XvZttQboAvP5UoK6lv9o3d+0GM4/3zP+yO3C0NExz1ZgFmbGFz703YJzM+zpKCOXaZyzPjADXp8qBBeVc5lmJqiCL4solZpxA1865yPigPAZcc9acSUlg23J1dptFK4n3Tl5HfSHP+oZ/QS/SHWbVFCtq7ZMQSRxLgEitfglTNz9P1CnpMwmW/Y4Gm5zdkv0JrdUVrn2UO9ARdHlPsW5ARgDmzaxnJypkfoHXNfxGGXWRk0sKLbz/ipnaQP/eFJv/ibNuSfqL6E4BnN/tHJSHYEaTQ/PdrA2i9laG3vJti3kAl5Ih87ct0w/tzYfp4SRPhEF1zzue9G/16eJEMzwmhQ5Ec7jJVcVGa4RltqnuF8unUu3iSRTQ+/MNNUkK6Mk+YuaJJs6Fjw6tRHuWi57SdKKv7GGkr0zlBUU2Dyo1MwpAqzsCcCTeQSv+8qt4wLf4uhU9Br7F/L0ZY9bFgh6iLDCdB+4iABXyZwT7Ufn762195hrSHcU4Okt0Zns9EeiBOFxnmpXEslYkYBpXw70GmymQfJlFOfoEp93QKCMS2DAEVeI51dJV1e+6t3pCSsQN69Vg6jUCsm1TMxSs2VX4BRbq562+VffchvW2BB4gMjsvHVUSRl8i5/ZSDlfzSPXcSGALLHBRzy+gn0oXXJ/447VHYZJDL3Ig8+QW5oFMgnWYhuwI5QSLEyflUrfSz+Pdwn/5eyjybXKJftePBD9Q+8NQ8zulU5sqvsMeIx/bBUx0fmOXsS3vjqCXW5IjkmSUV7q54GewZqTQBlcx+90xh/LSUxXex7UwZwRnifvyCbZ+zwNTHNb12chYeNjMV7kAIr3cGQv8vlOMM8ajyaZ5KVy7HpSXQjz4PGT2/nXbL5jKt8Lx0erGXsSsazkdoYDG3U',
    sig        => 'a3c6ce632b145c0869423c1afaff4a6d764a9b64dedaf15f170b944ead67227518a72e455567ca1c2a0d187832cecbde7ed478395ec4c95dd3e71749ed66c480',
);

subtest 'spec example: unwrap gift wrap to recipient reveals DM' => sub {
    my ($rumor, $sender_pubkey) = Net::Nostr::GiftWrap->unwrap(
        event         => $WRAP_TO_RECIPIENT,
        recipient_key => $recipient_key,
    );

    is($sender_pubkey, $SENDER_PUBKEY, 'sender identified from seal');
    is($rumor->pubkey, $SENDER_PUBKEY, 'rumor pubkey is sender');
    is($rumor->kind, 14, 'rumor is kind 14 (chat message)');
    is($rumor->content, 'Hola, que tal?', 'message content matches spec');
};

###############################################################################
# Kind 14: Chat message
###############################################################################

subtest 'kind 14 chat message structure' => sub {
    my $msg = Net::Nostr::DirectMessage->create(
        sender_pubkey => $SENDER_PUBKEY,
        content       => 'Hello!',
        recipients    => [$RECIPIENT_PUBKEY],
    );

    is($msg->kind, 14, 'kind is 14');
    is($msg->content, 'Hello!', 'content is plain text');
    is($msg->pubkey, $SENDER_PUBKEY, 'pubkey is sender');
    ok(defined $msg->id, 'id is set');
    ok(defined $msg->created_at, 'created_at is set');
    ok(!defined $msg->sig, 'message is unsigned (rumor)');

    my @p_tags = grep { $_->[0] eq 'p' } @{$msg->tags};
    is(scalar @p_tags, 1, 'one p-tag for recipient');
    is($p_tags[0][1], $RECIPIENT_PUBKEY, 'p-tag is recipient pubkey');
};

subtest 'chat message MUST NOT be signed' => sub {
    my $msg = Net::Nostr::DirectMessage->create(
        sender_pubkey => $SENDER_PUBKEY,
        content       => 'test',
        recipients    => [$RECIPIENT_PUBKEY],
    );

    ok(!defined $msg->sig, 'message is unsigned');
};

subtest 'content MUST be plain text' => sub {
    my $msg = Net::Nostr::DirectMessage->create(
        sender_pubkey => $SENDER_PUBKEY,
        content       => 'plain text message with <html> and "quotes"',
        recipients    => [$RECIPIENT_PUBKEY],
    );

    is($msg->content, 'plain text message with <html> and "quotes"',
        'content preserved as-is');
};

###############################################################################
# Multiple recipients
###############################################################################

subtest 'multiple p-tags for multiple recipients' => sub {
    my $other_pubkey = 'b' x 64;
    my $msg = Net::Nostr::DirectMessage->create(
        sender_pubkey => $SENDER_PUBKEY,
        content       => 'group message',
        recipients    => [$RECIPIENT_PUBKEY, $other_pubkey],
    );

    my @p_tags = grep { $_->[0] eq 'p' } @{$msg->tags};
    is(scalar @p_tags, 2, 'two p-tags');
    is($p_tags[0][1], $RECIPIENT_PUBKEY, 'first recipient');
    is($p_tags[1][1], $other_pubkey, 'second recipient');
};

###############################################################################
# Reply: e tag denotes parent message
###############################################################################

subtest 'e tag for reply to parent message' => sub {
    my $parent_id = 'c' x 64;
    my $msg = Net::Nostr::DirectMessage->create(
        sender_pubkey => $SENDER_PUBKEY,
        content       => 'reply',
        recipients    => [$RECIPIENT_PUBKEY],
        reply_to      => $parent_id,
    );

    my @e_tags = grep { $_->[0] eq 'e' } @{$msg->tags};
    is(scalar @e_tags, 1, 'one e-tag');
    is($e_tags[0][1], $parent_id, 'e-tag references parent');
};

###############################################################################
# Subject tag: chat room topic
###############################################################################

subtest 'optional subject tag for conversation topic' => sub {
    my $msg = Net::Nostr::DirectMessage->create(
        sender_pubkey => $SENDER_PUBKEY,
        content       => 'hello',
        recipients    => [$RECIPIENT_PUBKEY],
        subject       => 'Party tonight',
    );

    my @subject_tags = grep { $_->[0] eq 'subject' } @{$msg->tags};
    is(scalar @subject_tags, 1, 'one subject tag');
    is($subject_tags[0][1], 'Party tonight', 'subject value');
};

subtest 'subject is optional' => sub {
    my $msg = Net::Nostr::DirectMessage->create(
        sender_pubkey => $SENDER_PUBKEY,
        content       => 'hello',
        recipients    => [$RECIPIENT_PUBKEY],
    );

    my @subject_tags = grep { $_->[0] eq 'subject' } @{$msg->tags};
    is(scalar @subject_tags, 0, 'no subject tag when omitted');
};

###############################################################################
# q tags MAY be used for citing events
###############################################################################

subtest 'q tags MAY cite events' => sub {
    my $cited_id = 'd' x 64;
    my $msg = Net::Nostr::DirectMessage->create(
        sender_pubkey => $SENDER_PUBKEY,
        content       => 'check this out',
        recipients    => [$RECIPIENT_PUBKEY],
        quotes        => [[$cited_id, 'wss://relay.example.com', 'e' x 64]],
    );

    my @q_tags = grep { $_->[0] eq 'q' } @{$msg->tags};
    is(scalar @q_tags, 1, 'one q-tag');
    is($q_tags[0][1], $cited_id, 'q-tag event id');
    is($q_tags[0][2], 'wss://relay.example.com', 'q-tag relay');
    is($q_tags[0][3], 'e' x 64, 'q-tag pubkey');
};

###############################################################################
# Kind 15: File message
###############################################################################

subtest 'kind 15 file message structure' => sub {
    my $msg = Net::Nostr::DirectMessage->create_file(
        sender_pubkey        => $SENDER_PUBKEY,
        content              => 'https://example.com/encrypted-file.bin',
        recipients           => [$RECIPIENT_PUBKEY],
        file_type            => 'image/jpeg',
        encryption_algorithm => 'aes-gcm',
        decryption_key       => 'abc123',
        decryption_nonce     => 'def456',
        x                    => 'f' x 64,
    );

    is($msg->kind, 15, 'kind is 15');
    is($msg->content, 'https://example.com/encrypted-file.bin', 'content is file URL');
    ok(!defined $msg->sig, 'file message is unsigned');

    my %tags;
    for my $tag (@{$msg->tags}) {
        $tags{$tag->[0]} = $tag->[1];
    }
    is($tags{'file-type'}, 'image/jpeg', 'file-type tag');
    is($tags{'encryption-algorithm'}, 'aes-gcm', 'encryption-algorithm tag');
    is($tags{'decryption-key'}, 'abc123', 'decryption-key tag');
    is($tags{'decryption-nonce'}, 'def456', 'decryption-nonce tag');
    is($tags{x}, 'f' x 64, 'x tag (SHA-256 of encrypted file)');
};

subtest 'kind 15 optional file tags' => sub {
    my $msg = Net::Nostr::DirectMessage->create_file(
        sender_pubkey        => $SENDER_PUBKEY,
        content              => 'https://example.com/file.bin',
        recipients           => [$RECIPIENT_PUBKEY],
        file_type            => 'image/png',
        encryption_algorithm => 'aes-gcm',
        decryption_key       => 'key',
        decryption_nonce     => 'nonce',
        x                    => 'a' x 64,
        ox                   => 'b' x 64,
        size                 => '1024',
        dim                  => '800x600',
        blurhash             => 'LEHV6nWB2yk8',
        thumb                => 'https://example.com/thumb.bin',
        fallback             => ['https://backup.example.com/file.bin'],
    );

    my %tags;
    for my $tag (@{$msg->tags}) {
        push @{$tags{$tag->[0]}}, $tag->[1];
    }
    is($tags{ox}[0], 'b' x 64, 'ox tag');
    is($tags{size}[0], '1024', 'size tag');
    is($tags{dim}[0], '800x600', 'dim tag');
    is($tags{blurhash}[0], 'LEHV6nWB2yk8', 'blurhash tag');
    is($tags{thumb}[0], 'https://example.com/thumb.bin', 'thumb tag');
    is($tags{fallback}[0], 'https://backup.example.com/file.bin', 'fallback tag');
};

###############################################################################
# Encrypting: seal and gift wrap to each recipient + sender
###############################################################################

subtest 'wrap_for_recipients wraps for each recipient and sender' => sub {
    my $msg = Net::Nostr::DirectMessage->create(
        sender_pubkey => $sender_key->pubkey_hex,
        content       => 'group msg',
        recipients    => [$RECIPIENT_PUBKEY],
    );

    my @wraps = Net::Nostr::DirectMessage->wrap_for_recipients(
        rumor      => $msg,
        sender_key => $sender_key,
    );

    is(scalar @wraps, 2, 'two wraps: one for recipient, one for sender');

    # All are kind 1059
    for my $w (@wraps) {
        is($w->kind, 1059, 'wrap is kind 1059');
    }

    # Find wrap for recipient (p-tag matches recipient)
    my ($to_recipient) = grep {
        my @p = grep { $_->[0] eq 'p' } @{$_->tags};
        @p && $p[0][1] eq $RECIPIENT_PUBKEY;
    } @wraps;
    ok(defined $to_recipient, 'found wrap for recipient');

    # Find wrap for sender
    my ($to_sender) = grep {
        my @p = grep { $_->[0] eq 'p' } @{$_->tags};
        @p && $p[0][1] eq $SENDER_PUBKEY;
    } @wraps;
    ok(defined $to_sender, 'found wrap for sender');
};

###############################################################################
# Clients MUST verify seal pubkey matches rumor pubkey
###############################################################################

subtest 'receive verifies seal pubkey matches rumor pubkey' => sub {
    my $msg = Net::Nostr::DirectMessage->create(
        sender_pubkey => $sender_key->pubkey_hex,
        content       => 'hello',
        recipients    => [$RECIPIENT_PUBKEY],
    );

    my $wrap = Net::Nostr::GiftWrap->seal_and_wrap(
        rumor            => $msg,
        sender_key       => $sender_key,
        recipient_pubkey => $RECIPIENT_PUBKEY,
    );

    my $rumor = Net::Nostr::DirectMessage->receive(
        event         => $wrap,
        recipient_key => $recipient_key,
    );

    is($rumor->content, 'hello', 'message received');
    is($rumor->pubkey, $SENDER_PUBKEY, 'sender verified');
};

###############################################################################
# Kind 10050: DM relay list
###############################################################################

subtest 'kind 10050 DM relay list' => sub {
    my $rl = Net::Nostr::DirectMessage->create_relay_list(
        pubkey => $SENDER_PUBKEY,
        relays => ['wss://inbox.nostr.wine', 'wss://myrelay.nostr1.com'],
    );

    is($rl->kind, 10050, 'kind is 10050');
    is($rl->content, '', 'content is empty');
    is($rl->pubkey, $SENDER_PUBKEY, 'pubkey set');

    my @relay_tags = grep { $_->[0] eq 'relay' } @{$rl->tags};
    is(scalar @relay_tags, 2, 'two relay tags');
    is($relay_tags[0][1], 'wss://inbox.nostr.wine', 'first relay');
    is($relay_tags[1][1], 'wss://myrelay.nostr1.com', 'second relay');
};

subtest 'kind 10050 uses relay tags (not r tags)' => sub {
    my $rl = Net::Nostr::DirectMessage->create_relay_list(
        pubkey => $SENDER_PUBKEY,
        relays => ['wss://relay.example.com'],
    );

    is($rl->tags->[0][0], 'relay', 'tag name is "relay" not "r"');
};

subtest 'kind 10050 is replaceable' => sub {
    my $rl = Net::Nostr::DirectMessage->create_relay_list(
        pubkey => $SENDER_PUBKEY,
        relays => ['wss://relay.example.com'],
    );

    ok($rl->is_replaceable, 'kind 10050 is replaceable');
};

subtest 'kind 10050 spec example' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey  => $SENDER_PUBKEY,
        kind    => 10050,
        content => '',
        tags    => [
            ['relay', 'wss://inbox.nostr.wine'],
            ['relay', 'wss://myrelay.nostr1.com'],
        ],
    );

    is($event->kind, 10050, 'kind matches spec');
    is($event->content, '', 'content empty per spec');
    my @relay_tags = grep { $_->[0] eq 'relay' } @{$event->tags};
    is(scalar @relay_tags, 2, 'two relay tags as in spec example');
};

###############################################################################
# Chat rooms: pubkey + p-tags defines the room
###############################################################################

subtest 'chat room identity from pubkey + p-tags' => sub {
    my $other_pubkey = 'b' x 64;
    my $msg = Net::Nostr::DirectMessage->create(
        sender_pubkey => $SENDER_PUBKEY,
        content       => 'hello',
        recipients    => [$RECIPIENT_PUBKEY, $other_pubkey],
    );

    my @members = Net::Nostr::DirectMessage->chat_members($msg);
    # Room members = sender + all p-tagged pubkeys
    is(scalar @members, 3, 'three members in room');
    ok((grep { $_ eq $SENDER_PUBKEY } @members), 'sender is a member');
    ok((grep { $_ eq $RECIPIENT_PUBKEY } @members), 'recipient is a member');
    ok((grep { $_ eq $other_pubkey } @members), 'other is a member');
};

###############################################################################
# Disappearing messages: MAY set expiration on gift wrap
###############################################################################

subtest 'MAY create disappearing messages with expiration' => sub {
    my $msg = Net::Nostr::DirectMessage->create(
        sender_pubkey => $sender_key->pubkey_hex,
        content       => 'self-destruct',
        recipients    => [$RECIPIENT_PUBKEY],
    );

    my @wraps = Net::Nostr::DirectMessage->wrap_for_recipients(
        rumor      => $msg,
        sender_key => $sender_key,
        expiration => time() + 3600,
    );

    for my $w (@wraps) {
        my @exp = grep { $_->[0] eq 'expiration' } @{$w->tags};
        is(scalar @exp, 1, 'wrap has expiration tag');
    }
};

subtest 'MAY omit sender wrap for disappearing messages' => sub {
    my $msg = Net::Nostr::DirectMessage->create(
        sender_pubkey => $sender_key->pubkey_hex,
        content       => 'no copy for me',
        recipients    => [$RECIPIENT_PUBKEY],
    );

    my @wraps = Net::Nostr::DirectMessage->wrap_for_recipients(
        rumor        => $msg,
        sender_key   => $sender_key,
        skip_sender  => 1,
    );

    is(scalar @wraps, 1, 'only one wrap (recipient only)');
    my @p_tags = grep { $_->[0] eq 'p' } @{$wraps[0]->tags};
    is($p_tags[0][1], $RECIPIENT_PUBKEY, 'wrap is for recipient');
};

###############################################################################
# Encryption MUST use latest NIP-44
###############################################################################

subtest 'round-trip: create, wrap, unwrap' => sub {
    my $msg = Net::Nostr::DirectMessage->create(
        sender_pubkey => $sender_key->pubkey_hex,
        content       => 'secret message',
        recipients    => [$RECIPIENT_PUBKEY],
        subject       => 'Test',
    );

    my @wraps = Net::Nostr::DirectMessage->wrap_for_recipients(
        rumor      => $msg,
        sender_key => $sender_key,
    );

    # Recipient unwraps
    my ($to_recipient) = grep {
        my @p = grep { $_->[0] eq 'p' } @{$_->tags};
        @p && $p[0][1] eq $RECIPIENT_PUBKEY;
    } @wraps;

    my $received = Net::Nostr::DirectMessage->receive(
        event         => $to_recipient,
        recipient_key => $recipient_key,
    );

    is($received->kind, 14, 'kind 14');
    is($received->content, 'secret message', 'content preserved');
    is($received->pubkey, $SENDER_PUBKEY, 'sender identified');

    my @subject = grep { $_->[0] eq 'subject' } @{$received->tags};
    is($subject[0][1], 'Test', 'subject preserved');
};

###############################################################################
# Spec example: decrypt second gift wrap (to sender)
###############################################################################

subtest 'spec example: unwrap gift wrap to sender reveals same DM' => sub {
    my $wrap_to_sender = Net::Nostr::Event->new(
        id         => '162b0611a1911cfcb30f8a5502792b346e535a45658b3a31ae5c178465509721',
        pubkey     => '626be2af274b29ea4816ad672ee452b7cf96bbb4836815a55699ae402183f512',
        created_at => 1702711587,
        kind       => 1059,
        tags       => [['p', '44900586091b284416a0c001f677f9c49f7639a55c3f1e2ec130a8e1a7998e1b']],
        content    => 'AsTClTzr0gzXXji7uye5UB6LYrx3HDjWGdkNaBS6BAX9CpHa+Vvtt5oI2xJrmWLen+Fo2NBOFazvl285Gb3HSM82gVycrzx1HUAaQDUG6HI7XBEGqBhQMUNwNMiN2dnilBMFC3Yc8ehCJT/gkbiNKOpwd2rFibMFRMDKai2mq2lBtPJF18oszKOjA+XlOJV8JRbmcAanTbEK5nA/GnG3eGUiUzhiYBoHomj3vztYYxc0QYHOx0WxiHY8dsC6jPsXC7f6k4P+Hv5ZiyTfzvjkSJOckel1lZuE5SfeZ0nduqTlxREGeBJ8amOykgEIKdH2VZBZB+qtOMc7ez9dz4wffGwBDA7912NFS2dPBr6txHNxBUkDZKFbuD5wijvonZDvfWq43tZspO4NutSokZB99uEiRH8NAUdGTiNb25m9JcDhVfdmABqTg5fIwwTwlem5aXIy8b66lmqqz2LBzJtnJDu36bDwkILph3kmvaKPD8qJXmPQ4yGpxIbYSTCohgt2/I0TKJNmqNvSN+IVoUuC7ZOfUV9lOV8Ri0AMfSr2YsdZ9ofV5o82ClZWlWiSWZwy6ypa7CuT1PEGHzywB4CZ5ucpO60Z7hnBQxHLiAQIO/QhiBp1rmrdQZFN6PUEjFDloykoeHe345Yqy9Ke95HIKUCS9yJurD+nZjjgOxZjoFCsB1hQAwINTIS3FbYOibZnQwv8PXvcSOqVZxC9U0+WuagK7IwxzhGZY3vLRrX01oujiRrevB4xbW7Oxi/Agp7CQGlJXCgmRE8Rhm+Vj2s+wc/4VLNZRHDcwtfejogjrjdi8p6nfUyqoQRRPARzRGUnnCbh+LqhigT6gQf3sVilnydMRScEc0/YYNLWnaw9nbyBa7wFBAiGbJwO40k39wj+xT6HTSbSUgFZzopxroO3f/o4+ubx2+IL3fkev22mEN38+dFmYF3zE+hpE7jVxrJpC3EP9PLoFgFPKCuctMnjXmeHoiGs756N5r1Mm1ffZu4H19MSuALJlxQR7VXE/LzxRXDuaB2u9days/6muP6gbGX1ASxbJd/ou8+viHmSC/ioHzNjItVCPaJjDyc6bv+gs1NPCt0qZ69G+JmgHW/PsMMeL4n5bh74g0fJSHqiI9ewEmOG/8bedSREv2XXtKV39STxPweceIOh0k23s3N6+wvuSUAJE7u1LkDo14cobtZ/MCw/QhimYPd1u5HnEJvRhPxz0nVPz0QqL/YQeOkAYk7uzgeb2yPzJ6DBtnTnGDkglekhVzQBFRJdk740LEj6swkJ',
        sig        => 'c94e74533b482aa8eeeb54ae72a5303e0b21f62909ca43c8ef06b0357412d6f8a92f96e1a205102753777fd25321a58fba3fb384eee114bd53ce6c06a1c22bab',
    );

    # The sender's p-tag pubkey should be the sender's own pubkey
    my @p_tags = grep { $_->[0] eq 'p' } @{$wrap_to_sender->tags};
    is($p_tags[0][1], $SENDER_PUBKEY, 'p-tag is sender pubkey (self-copy)');

    my ($rumor, $seal_pubkey) = Net::Nostr::GiftWrap->unwrap(
        event         => $wrap_to_sender,
        recipient_key => $sender_key,
    );

    is($seal_pubkey, $SENDER_PUBKEY, 'sender identified from seal');
    is($rumor->pubkey, $SENDER_PUBKEY, 'rumor pubkey is sender');
    is($rumor->kind, 14, 'rumor is kind 14');
    is($rumor->content, 'Hola, que tal?', 'same message content');
};

###############################################################################
# Kind 7 reactions MAY be sent to encrypted chat
###############################################################################

subtest 'kind 7 reaction MAY be sent to encrypted chat' => sub {
    my $reaction = Net::Nostr::GiftWrap->create_rumor(
        pubkey  => $sender_key->pubkey_hex,
        kind    => 7,
        content => '+',
        tags    => [
            ['p', $RECIPIENT_PUBKEY],
            ['e', 'a' x 64],
        ],
    );

    is($reaction->kind, 7, 'reaction is kind 7');
    ok(!defined $reaction->sig, 'reaction is unsigned rumor');

    my $wrap = Net::Nostr::GiftWrap->seal_and_wrap(
        rumor            => $reaction,
        sender_key       => $sender_key,
        recipient_pubkey => $RECIPIENT_PUBKEY,
    );

    my ($unwrapped, $spk) = Net::Nostr::GiftWrap->unwrap(
        event         => $wrap,
        recipient_key => $recipient_key,
    );

    is($unwrapped->kind, 7, 'unwrapped kind 7 reaction');
    is($unwrapped->content, '+', 'reaction content preserved');
};

###############################################################################
# Chat rooms: different p-tag sets = different rooms
###############################################################################

subtest 'different p-tag sets define different chat rooms' => sub {
    my $alice = 'a' x 64;
    my $bob   = 'b' x 64;
    my $carol = 'c' x 64;

    my $msg1 = Net::Nostr::DirectMessage->create(
        sender_pubkey => $SENDER_PUBKEY,
        content       => 'room 1',
        recipients    => [$alice, $bob],
    );
    my $msg2 = Net::Nostr::DirectMessage->create(
        sender_pubkey => $SENDER_PUBKEY,
        content       => 'room 2',
        recipients    => [$alice, $carol],
    );

    my @members1 = sort(Net::Nostr::DirectMessage->chat_members($msg1));
    my @members2 = sort(Net::Nostr::DirectMessage->chat_members($msg2));

    isnt(\@members1, \@members2, 'different p-tags produce different rooms');

    # Adding a member changes the room
    my $msg3 = Net::Nostr::DirectMessage->create(
        sender_pubkey => $SENDER_PUBKEY,
        content       => 'room 3',
        recipients    => [$alice, $bob, $carol],
    );
    my @members3 = sort(Net::Nostr::DirectMessage->chat_members($msg3));
    isnt(\@members1, \@members3, 'adding a p-tag creates a new room');
};

###############################################################################
# Any member can change subject
###############################################################################

subtest 'any member can change the conversation subject' => sub {
    my $msg_from_sender = Net::Nostr::DirectMessage->create(
        sender_pubkey => $SENDER_PUBKEY,
        content       => 'hello',
        recipients    => [$RECIPIENT_PUBKEY],
        subject       => 'Original topic',
    );

    my $msg_from_recipient = Net::Nostr::DirectMessage->create(
        sender_pubkey => $RECIPIENT_PUBKEY,
        content       => 'new topic!',
        recipients    => [$SENDER_PUBKEY],
        subject       => 'Changed topic',
    );

    my @subj1 = grep { $_->[0] eq 'subject' } @{$msg_from_sender->tags};
    my @subj2 = grep { $_->[0] eq 'subject' } @{$msg_from_recipient->tags};

    is($subj1[0][1], 'Original topic', 'sender sets topic');
    is($subj2[0][1], 'Changed topic', 'recipient changes topic');

    # Both messages are in the same room (same pubkey+p set, just swapped)
    # Subject not required in every message
    my $msg_no_subject = Net::Nostr::DirectMessage->create(
        sender_pubkey => $SENDER_PUBKEY,
        content       => 'no subject here',
        recipients    => [$RECIPIENT_PUBKEY],
    );
    my @subj3 = grep { $_->[0] eq 'subject' } @{$msg_no_subject->tags};
    is(scalar @subj3, 0, 'subject not required in every message');
};

###############################################################################
# MUST verify: receive rejects seal/rumor pubkey mismatch (impersonation)
###############################################################################

subtest 'receive rejects impersonation: seal pubkey != rumor pubkey' => sub {
    my $attacker_key = Net::Nostr::Key->new;

    # Create a rumor claiming to be from the real sender
    my $forged_rumor = Net::Nostr::GiftWrap->create_rumor(
        pubkey  => $SENDER_PUBKEY,  # claims to be sender
        kind    => 14,
        content => 'forged message',
        tags    => [['p', $RECIPIENT_PUBKEY]],
    );

    # But seal it with the attacker's key (seal pubkey will be attacker's)
    my $wrap = Net::Nostr::GiftWrap->seal_and_wrap(
        rumor            => $forged_rumor,
        sender_key       => $attacker_key,  # different from rumor pubkey
        recipient_pubkey => $RECIPIENT_PUBKEY,
    );

    like(dies { Net::Nostr::DirectMessage->receive(
        event         => $wrap,
        recipient_key => $recipient_key,
    ) }, qr/pubkey mismatch/, 'rejects impersonation attempt');
};

###############################################################################
# Wraps from wrap_for_recipients have randomized timestamps
###############################################################################

subtest 'wrap_for_recipients randomizes timestamps' => sub {
    my $msg = Net::Nostr::DirectMessage->create(
        sender_pubkey => $sender_key->pubkey_hex,
        content       => 'timestamp test',
        recipients    => [$RECIPIENT_PUBKEY],
    );

    my @wraps = Net::Nostr::DirectMessage->wrap_for_recipients(
        rumor      => $msg,
        sender_key => $sender_key,
    );

    my $now = time();
    my $two_days = 2 * 24 * 60 * 60;
    for my $w (@wraps) {
        ok($w->created_at <= $now, 'wrap timestamp not in future');
        ok($w->created_at >= $now - $two_days, 'wrap timestamp within 2 days');
    }
};

###############################################################################
# Gift wrap p-tag can be an alias key
###############################################################################

subtest 'gift wrap p-tag can be an alias key for receiver' => sub {
    my $alias_key = Net::Nostr::Key->new;

    my $msg = Net::Nostr::DirectMessage->create(
        sender_pubkey => $sender_key->pubkey_hex,
        content       => 'alias delivery',
        recipients    => [$RECIPIENT_PUBKEY],
    );

    # Wrap to the alias key instead of the main pubkey
    my $wrap = Net::Nostr::GiftWrap->seal_and_wrap(
        rumor            => $msg,
        sender_key       => $sender_key,
        recipient_pubkey => $alias_key->pubkey_hex,
    );

    my @p_tags = grep { $_->[0] eq 'p' } @{$wrap->tags};
    is($p_tags[0][1], $alias_key->pubkey_hex, 'p-tag is alias key');

    # Alias key can unwrap
    my ($unwrapped, $spk) = Net::Nostr::GiftWrap->unwrap(
        event         => $wrap,
        recipient_key => $alias_key,
    );
    is($unwrapped->content, 'alias delivery', 'alias key decrypts message');
};

###############################################################################
# Expiration SHOULD be on seal too (not just gift wrap)
###############################################################################

subtest 'expiration SHOULD be included on kind 13 seal as well' => sub {
    my $msg = Net::Nostr::DirectMessage->create(
        sender_pubkey => $sender_key->pubkey_hex,
        content       => 'disappearing',
        recipients    => [$RECIPIENT_PUBKEY],
    );

    my @wraps = Net::Nostr::DirectMessage->wrap_for_recipients(
        rumor      => $msg,
        sender_key => $sender_key,
        expiration => time() + 3600,
    );

    # Decrypt the gift wrap to inspect the seal directly
    my ($to_recipient) = grep {
        my @p = grep { $_->[0] eq 'p' } @{$_->tags};
        @p && $p[0][1] eq $RECIPIENT_PUBKEY;
    } @wraps;

    my $conv_key = Net::Nostr::Encryption->get_conversation_key(
        $recipient_key->privkey_hex, $to_recipient->pubkey,
    );
    my $seal_json = Net::Nostr::Encryption->decrypt($to_recipient->content, $conv_key);
    my $seal = JSON::decode_json($seal_json);

    my @seal_exp = grep { $_->[0] eq 'expiration' } @{$seal->{tags}};
    is(scalar @seal_exp, 1, 'seal has expiration tag');

    my @wrap_exp = grep { $_->[0] eq 'expiration' } @{$to_recipient->tags};
    is(scalar @wrap_exp, 1, 'gift wrap has expiration tag');
};

###############################################################################
# Kind 15: id and created_at are present
###############################################################################

subtest 'kind 15 file message has id and created_at' => sub {
    my $msg = Net::Nostr::DirectMessage->create_file(
        sender_pubkey        => $SENDER_PUBKEY,
        content              => 'https://example.com/file.bin',
        recipients           => [$RECIPIENT_PUBKEY],
        file_type            => 'image/png',
        encryption_algorithm => 'aes-gcm',
        decryption_key       => 'key123',
        decryption_nonce     => 'nonce456',
        x                    => 'a' x 64,
    );

    ok(defined $msg->id, 'file message has id');
    ok(defined $msg->created_at, 'file message has created_at');
};

###############################################################################
# Fallback: zero and multiple fallback URLs
###############################################################################

subtest 'kind 15 zero fallback URLs' => sub {
    my $msg = Net::Nostr::DirectMessage->create_file(
        sender_pubkey        => $SENDER_PUBKEY,
        content              => 'https://example.com/file.bin',
        recipients           => [$RECIPIENT_PUBKEY],
        file_type            => 'image/png',
        encryption_algorithm => 'aes-gcm',
        decryption_key       => 'key',
        decryption_nonce     => 'nonce',
        x                    => 'a' x 64,
    );

    my @fb = grep { $_->[0] eq 'fallback' } @{$msg->tags};
    is(scalar @fb, 0, 'no fallback tags when omitted');
};

subtest 'kind 15 multiple fallback URLs' => sub {
    my $msg = Net::Nostr::DirectMessage->create_file(
        sender_pubkey        => $SENDER_PUBKEY,
        content              => 'https://example.com/file.bin',
        recipients           => [$RECIPIENT_PUBKEY],
        file_type            => 'image/png',
        encryption_algorithm => 'aes-gcm',
        decryption_key       => 'key',
        decryption_nonce     => 'nonce',
        x                    => 'a' x 64,
        fallback             => [
            'https://backup1.example.com/file.bin',
            'https://backup2.example.com/file.bin',
            'https://backup3.example.com/file.bin',
        ],
    );

    my @fb = grep { $_->[0] eq 'fallback' } @{$msg->tags};
    is(scalar @fb, 3, 'three fallback tags');
    is($fb[0][1], 'https://backup1.example.com/file.bin', 'first fallback');
    is($fb[1][1], 'https://backup2.example.com/file.bin', 'second fallback');
    is($fb[2][1], 'https://backup3.example.com/file.bin', 'third fallback');
};

###############################################################################
# p-tag with optional relay-url hint
###############################################################################

subtest 'p-tag MAY include relay URL hint' => sub {
    my $msg = Net::Nostr::DirectMessage->create(
        sender_pubkey => $SENDER_PUBKEY,
        content       => 'hello',
        recipients    => [
            [$RECIPIENT_PUBKEY, 'wss://relay.example.com'],
        ],
    );

    my @p_tags = grep { $_->[0] eq 'p' } @{$msg->tags};
    is(scalar @p_tags, 1, 'one p-tag');
    is($p_tags[0][1], $RECIPIENT_PUBKEY, 'p-tag pubkey');
    is($p_tags[0][2], 'wss://relay.example.com', 'p-tag relay hint');
};

subtest 'p-tag relay hint mixed with plain pubkeys' => sub {
    my $other = 'b' x 64;
    my $msg = Net::Nostr::DirectMessage->create(
        sender_pubkey => $SENDER_PUBKEY,
        content       => 'hello',
        recipients    => [
            [$RECIPIENT_PUBKEY, 'wss://relay1.example.com'],
            $other,
        ],
    );

    my @p_tags = grep { $_->[0] eq 'p' } @{$msg->tags};
    is(scalar @p_tags, 2, 'two p-tags');
    is($p_tags[0][2], 'wss://relay1.example.com', 'first has relay hint');
    is(scalar @{$p_tags[1]}, 2, 'second has no relay hint');
};

###############################################################################
# e-tag with relay URL hint (kind 14 reply)
###############################################################################

subtest 'e-tag MAY include relay URL hint for reply' => sub {
    my $parent_id = 'c' x 64;
    my $msg = Net::Nostr::DirectMessage->create(
        sender_pubkey => $SENDER_PUBKEY,
        content       => 'reply with hint',
        recipients    => [$RECIPIENT_PUBKEY],
        reply_to      => [$parent_id, 'wss://relay.example.com'],
    );

    my @e_tags = grep { $_->[0] eq 'e' } @{$msg->tags};
    is(scalar @e_tags, 1, 'one e-tag');
    is($e_tags[0][1], $parent_id, 'e-tag event id');
    is($e_tags[0][2], 'wss://relay.example.com', 'e-tag relay hint');
};

###############################################################################
# Kind 15: e-tag with "reply" marker
###############################################################################

subtest 'kind 15 e-tag with reply marker' => sub {
    my $parent_id = 'c' x 64;
    my $msg = Net::Nostr::DirectMessage->create_file(
        sender_pubkey        => $SENDER_PUBKEY,
        content              => 'https://example.com/file.bin',
        recipients           => [$RECIPIENT_PUBKEY],
        file_type            => 'image/png',
        encryption_algorithm => 'aes-gcm',
        decryption_key       => 'key',
        decryption_nonce     => 'nonce',
        x                    => 'a' x 64,
        reply_to             => [$parent_id, 'wss://relay.example.com', 'reply'],
    );

    my @e_tags = grep { $_->[0] eq 'e' } @{$msg->tags};
    is(scalar @e_tags, 1, 'one e-tag');
    is($e_tags[0][1], $parent_id, 'e-tag event id');
    is($e_tags[0][2], 'wss://relay.example.com', 'e-tag relay hint');
    is($e_tags[0][3], 'reply', 'e-tag reply marker');
};

###############################################################################
# Kind 15: subject tag
###############################################################################

subtest 'kind 15 file message with subject tag' => sub {
    my $msg = Net::Nostr::DirectMessage->create_file(
        sender_pubkey        => $SENDER_PUBKEY,
        content              => 'https://example.com/file.bin',
        recipients           => [$RECIPIENT_PUBKEY],
        file_type            => 'image/png',
        encryption_algorithm => 'aes-gcm',
        decryption_key       => 'key',
        decryption_nonce     => 'nonce',
        x                    => 'a' x 64,
        subject              => 'Vacation photos',
    );

    my @subject_tags = grep { $_->[0] eq 'subject' } @{$msg->tags};
    is(scalar @subject_tags, 1, 'one subject tag');
    is($subject_tags[0][1], 'Vacation photos', 'subject value');
};

###############################################################################
# Kind 15: p-tag with relay hint
###############################################################################

subtest 'kind 15 p-tag with relay hint' => sub {
    my $msg = Net::Nostr::DirectMessage->create_file(
        sender_pubkey        => $SENDER_PUBKEY,
        content              => 'https://example.com/file.bin',
        recipients           => [[$RECIPIENT_PUBKEY, 'wss://relay.example.com']],
        file_type            => 'image/png',
        encryption_algorithm => 'aes-gcm',
        decryption_key       => 'key',
        decryption_nonce     => 'nonce',
        x                    => 'a' x 64,
    );

    my @p_tags = grep { $_->[0] eq 'p' } @{$msg->tags};
    is($p_tags[0][1], $RECIPIENT_PUBKEY, 'p-tag pubkey');
    is($p_tags[0][2], 'wss://relay.example.com', 'p-tag relay hint');
};

subtest 'create rejects invalid recipient pubkey' => sub {
    like(
        dies { Net::Nostr::DirectMessage->create(
            sender_pubkey => 'a' x 64, recipients => ['bad'],
            content => 'test',
        ) },
        qr/recipient pubkey must be 64-char lowercase hex/,
        'invalid recipient pubkey rejected'
    );
};

subtest 'create rejects invalid reply_to' => sub {
    like(
        dies { Net::Nostr::DirectMessage->create(
            sender_pubkey => 'a' x 64,
            recipients    => ['b' x 64],
            content       => 'test',
            reply_to      => 'not-hex',
        ) },
        qr/reply_to must be 64-char lowercase hex/,
        'invalid reply_to rejected'
    );
};

subtest 'create rejects invalid quote event_id' => sub {
    like(
        dies { Net::Nostr::DirectMessage->create(
            sender_pubkey => 'a' x 64,
            recipients    => ['b' x 64],
            content       => 'test',
            quotes        => [['not-hex']],
        ) },
        qr/quote event_id must be 64-char lowercase hex/,
        'invalid quote event_id rejected'
    );
};

done_testing;
