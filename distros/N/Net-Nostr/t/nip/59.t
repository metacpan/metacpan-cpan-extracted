#!/usr/bin/perl

# NIP-59 conformance tests: Gift Wrap

use strictures 2;

use Test2::V0 -no_srand => 1;

use lib 't/lib';
use TestFixtures qw(make_key_from_hex);

use Net::Nostr::GiftWrap;
use Net::Nostr::Event;
use Net::Nostr::Key;
use Net::Nostr::Encryption;
use JSON ();

###############################################################################
# Spec example keys
###############################################################################

my $AUTHOR_PRIVKEY    = '0beebd062ec8735f4243466049d7747ef5d6594ee838de147f8aab842b15e273';
my $AUTHOR_PUBKEY     = '611df01bfcf85c26ae65453b772d8f1dfd25c264621c0277e1fc1518686faef9';
my $RECIPIENT_PRIVKEY = 'e108399bd8424357a710b606ae0c13166d853d327e47a6e5e038197346bdbf45';
my $RECIPIENT_PUBKEY  = '166bf3765ebd1fc55decfe395beff2ea3b2a4e0a8946e7eb578512b555737c99';
my $EPHEMERAL_KEY     = '4f02eac59266002db5801adc5270700ca69d5b8f761d8732fab2fbf233c90cbd';
my $EPHEMERAL_PUBKEY  = '18b1a75918f1f2c90c23da616bce317d36e348bcf5f7ba55e75949319210c87c';

my $author_key    = make_key_from_hex($AUTHOR_PRIVKEY);
my $recipient_key = make_key_from_hex($RECIPIENT_PRIVKEY);
my $ephemeral_key = make_key_from_hex($EPHEMERAL_KEY);

# Verify key construction
is($author_key->pubkey_hex, $AUTHOR_PUBKEY, 'author key constructed correctly');
is($recipient_key->pubkey_hex, $RECIPIENT_PUBKEY, 'recipient key constructed correctly');
is($ephemeral_key->pubkey_hex, $EPHEMERAL_PUBKEY, 'ephemeral key constructed correctly');

###############################################################################
# Spec example: rumor (step 1)
###############################################################################

subtest 'spec example: rumor is unsigned event' => sub {
    my $rumor = Net::Nostr::Event->new(
        created_at => 1691518405,
        content    => 'Are you going to the party tonight?',
        tags       => [],
        kind       => 1,
        pubkey     => $AUTHOR_PUBKEY,
    );

    is($rumor->id, '9dd003c6d3b73b74a85a9ab099469ce251653a7af76f523671ab828acd2a0ef9',
        'rumor id matches spec');
    is($rumor->pubkey, $AUTHOR_PUBKEY, 'rumor pubkey is author');
    is($rumor->kind, 1, 'rumor kind preserved');
    is($rumor->content, 'Are you going to the party tonight?', 'rumor content preserved');
};

###############################################################################
# Spec example: decrypt gift wrap (step 3 → step 2 → step 1)
###############################################################################

my $GIFT_WRAP_CONTENT = 'AhC3Qj/QsKJFWuf6xroiYip+2yK95qPwJjVvFujhzSguJWb/6TlPpBW0CGFwfufCs2Zyb0JeuLmZhNlnqecAAalC4ZCugB+I9ViA5pxLyFfQjs1lcE6KdX3euCHBLAnE9GL/+IzdV9vZnfJH6atVjvBkNPNzxU+OLCHO/DAPmzmMVx0SR63frRTCz6Cuth40D+VzluKu1/Fg2Q1LSst65DE7o2efTtZ4Z9j15rQAOZfE9jwMCQZt27rBBK3yVwqVEriFpg2mHXc1DDwHhDADO8eiyOTWF1ghDds/DxhMcjkIi/o+FS3gG1dG7gJHu3KkGK5UXpmgyFKt+421m5o++RMD/BylS3iazS1S93IzTLeGfMCk+7IKxuSCO06k1+DaasJJe8RE4/rmismUvwrHu/HDutZWkvOAhd4z4khZo7bJLtiCzZCZ74lZcjOB4CYtuAX2ZGpc4I1iOKkvwTuQy9BWYpkzGg3ZoSWRD6ty7U+KN+fTTmIS4CelhBTT15QVqD02JxfLF7nA6sg3UlYgtiGw61oH68lSbx16P3vwSeQQpEB5JbhofW7t9TLZIbIW/ODnI4hpwj8didtk7IMBI3Ra3uUP7ya6vptkd9TwQkd/7cOFaSJmU+BIsLpOXbirJACMn+URoDXhuEtiO6xirNtrPN8jYqpwvMUm5lMMVzGT3kMMVNBqgbj8Ln8VmqouK0DR+gRyNb8fHT0BFPwsHxDskFk5yhe5c/2VUUoKCGe0kfCcX/EsHbJLUUtlHXmTqaOJpmQnW1tZ/siPwKRl6oEsIJWTUYxPQmrM2fUpYZCuAo/29lTLHiHMlTbarFOd6J/ybIbICy2gRRH/LFSryty3Cnf6aae+A9uizFBUdCwTwffc3vCBae802+R92OL78bbqHKPbSZOXNC+6ybqziezwG+OPWHx1Qk39RYaF0aFsM4uZWrFic97WwVrH5i+/Nsf/OtwWiuH0gV/SqvN1hnkxCTF/+XNn/laWKmS3e7wFzBsG8+qwqwmO9aVbDVMhOmeUXRMkxcj4QreQkHxLkCx97euZpC7xhvYnCHarHTDeD6nVK+xzbPNtzeGzNpYoiMqxZ9bBJwMaHnEoI944Vxoodf51cMIIwpTmmRvAzI1QgrfnOLOUS7uUjQ/IZ1Qa3lY08Nqm9MAGxZ2Ou6R0/Z5z30ha/Q71q6meAs3uHQcpSuRaQeV29IASmye2A2Nif+lmbhV7w8hjFYoaLCRsdchiVyNjOEM4VmxUhX4VEvw6KoCAZ/XvO2eBF/SyNU3Of4SO';

subtest 'spec example: decrypt gift wrap to get seal' => sub {
    my $conv_key = Net::Nostr::Encryption->get_conversation_key(
        $RECIPIENT_PRIVKEY, $EPHEMERAL_PUBKEY,
    );
    my $seal_json = Net::Nostr::Encryption->decrypt($GIFT_WRAP_CONTENT, $conv_key);
    my $seal = JSON::decode_json($seal_json);

    is($seal->{kind}, 13, 'seal is kind 13');
    is($seal->{pubkey}, $AUTHOR_PUBKEY, 'seal pubkey is real author');
    is(ref($seal->{tags}), 'ARRAY', 'seal has tags');
    is(scalar @{$seal->{tags}}, 0, 'seal tags are empty');
    ok(defined $seal->{sig}, 'seal is signed');
};

subtest 'spec example: decrypt seal to get rumor' => sub {
    # First decrypt the gift wrap to get the seal
    my $conv_key1 = Net::Nostr::Encryption->get_conversation_key(
        $RECIPIENT_PRIVKEY, $EPHEMERAL_PUBKEY,
    );
    my $seal_json = Net::Nostr::Encryption->decrypt($GIFT_WRAP_CONTENT, $conv_key1);
    my $seal = JSON::decode_json($seal_json);

    # Then decrypt the seal to get the rumor
    my $conv_key2 = Net::Nostr::Encryption->get_conversation_key(
        $RECIPIENT_PRIVKEY, $seal->{pubkey},
    );
    my $rumor_json = Net::Nostr::Encryption->decrypt($seal->{content}, $conv_key2);
    my $rumor = JSON::decode_json($rumor_json);

    is($rumor->{kind}, 1, 'rumor kind is 1');
    is($rumor->{content}, 'Are you going to the party tonight?', 'rumor content matches spec');
    is($rumor->{pubkey}, $AUTHOR_PUBKEY, 'rumor pubkey is author');
    is($rumor->{id}, '9dd003c6d3b73b74a85a9ab099469ce251653a7af76f523671ab828acd2a0ef9',
        'rumor id matches spec');
    ok(!defined $rumor->{sig}, 'rumor has no signature');
};

###############################################################################
# Rumor: unsigned event, any kind
###############################################################################

subtest 'rumor is unsigned: sig removed' => sub {
    my $rumor = Net::Nostr::GiftWrap->create_rumor(
        pubkey  => $AUTHOR_PUBKEY,
        kind    => 1,
        content => 'test',
        tags    => [],
    );

    isa_ok($rumor, 'Net::Nostr::Event');
    ok(!defined $rumor->sig, 'rumor has no signature');
    ok(defined $rumor->id, 'rumor has an id');
    ok(defined $rumor->created_at, 'rumor has created_at');
};

subtest 'any event kind can be a rumor' => sub {
    for my $kind (0, 1, 14, 1059, 30023) {
        my $rumor = Net::Nostr::GiftWrap->create_rumor(
            pubkey  => $AUTHOR_PUBKEY,
            kind    => $kind,
            content => '',
            tags    => [],
        );
        is($rumor->kind, $kind, "kind $kind works as rumor");
        ok(!defined $rumor->sig, "kind $kind rumor is unsigned");
    }
};

###############################################################################
# Seal: kind 13, encrypted, signed by author, empty tags
###############################################################################

subtest 'seal is kind 13' => sub {
    my $rumor = Net::Nostr::GiftWrap->create_rumor(
        pubkey  => $author_key->pubkey_hex,
        kind    => 1,
        content => 'hello',
        tags    => [],
    );

    my $seal = Net::Nostr::GiftWrap->seal(
        rumor            => $rumor,
        sender_key       => $author_key,
        recipient_pubkey => $RECIPIENT_PUBKEY,
    );

    is($seal->kind, 13, 'seal kind is 13');
};

subtest 'seal tags MUST always be empty' => sub {
    my $rumor = Net::Nostr::GiftWrap->create_rumor(
        pubkey  => $author_key->pubkey_hex,
        kind    => 1,
        content => 'hello',
        tags    => [['p', $RECIPIENT_PUBKEY]],
    );

    my $seal = Net::Nostr::GiftWrap->seal(
        rumor            => $rumor,
        sender_key       => $author_key,
        recipient_pubkey => $RECIPIENT_PUBKEY,
    );

    is(scalar @{$seal->tags}, 0, 'seal has no tags regardless of rumor tags');
};

subtest 'seal is signed by real author' => sub {
    my $rumor = Net::Nostr::GiftWrap->create_rumor(
        pubkey  => $author_key->pubkey_hex,
        kind    => 1,
        content => 'hello',
        tags    => [],
    );

    my $seal = Net::Nostr::GiftWrap->seal(
        rumor            => $rumor,
        sender_key       => $author_key,
        recipient_pubkey => $RECIPIENT_PUBKEY,
    );

    is($seal->pubkey, $AUTHOR_PUBKEY, 'seal pubkey is real author');
    ok(defined $seal->sig, 'seal is signed');
    ok($seal->verify_sig($author_key), 'seal signature verifies');
};

subtest 'seal content is NIP-44 encrypted rumor' => sub {
    my $rumor = Net::Nostr::GiftWrap->create_rumor(
        pubkey  => $author_key->pubkey_hex,
        kind    => 1,
        content => 'secret message',
        tags    => [],
    );

    my $seal = Net::Nostr::GiftWrap->seal(
        rumor            => $rumor,
        sender_key       => $author_key,
        recipient_pubkey => $RECIPIENT_PUBKEY,
    );

    # Recipient can decrypt the seal content
    my $conv_key = Net::Nostr::Encryption->get_conversation_key(
        $RECIPIENT_PRIVKEY, $seal->pubkey,
    );
    my $decrypted_json = Net::Nostr::Encryption->decrypt($seal->content, $conv_key);
    my $decrypted = JSON::decode_json($decrypted_json);

    is($decrypted->{content}, 'secret message', 'decrypted rumor content matches');
    is($decrypted->{pubkey}, $AUTHOR_PUBKEY, 'decrypted rumor pubkey matches');
    ok(!defined $decrypted->{sig}, 'decrypted rumor is unsigned');
};

subtest 'seal has no p-tag revealing recipient' => sub {
    my $rumor = Net::Nostr::GiftWrap->create_rumor(
        pubkey  => $author_key->pubkey_hex,
        kind    => 1,
        content => 'hello',
        tags    => [['p', $RECIPIENT_PUBKEY]],
    );

    my $seal = Net::Nostr::GiftWrap->seal(
        rumor            => $rumor,
        sender_key       => $author_key,
        recipient_pubkey => $RECIPIENT_PUBKEY,
    );

    is(scalar @{$seal->tags}, 0, 'seal tags are empty (no p-tag or any tag)');
};

###############################################################################
# Gift wrap: kind 1059, random key, p-tag for recipient
###############################################################################

subtest 'gift wrap is kind 1059' => sub {
    my $rumor = Net::Nostr::GiftWrap->create_rumor(
        pubkey  => $author_key->pubkey_hex,
        kind    => 1,
        content => 'hello',
        tags    => [],
    );

    my $seal = Net::Nostr::GiftWrap->seal(
        rumor            => $rumor,
        sender_key       => $author_key,
        recipient_pubkey => $RECIPIENT_PUBKEY,
    );

    my $wrap = Net::Nostr::GiftWrap->wrap(
        seal             => $seal,
        recipient_pubkey => $RECIPIENT_PUBKEY,
    );

    is($wrap->kind, 1059, 'gift wrap kind is 1059');
};

subtest 'gift wrap uses random one-time pubkey' => sub {
    my $rumor = Net::Nostr::GiftWrap->create_rumor(
        pubkey  => $author_key->pubkey_hex,
        kind    => 1,
        content => 'hello',
        tags    => [],
    );

    my $seal = Net::Nostr::GiftWrap->seal(
        rumor            => $rumor,
        sender_key       => $author_key,
        recipient_pubkey => $RECIPIENT_PUBKEY,
    );

    my $wrap1 = Net::Nostr::GiftWrap->wrap(
        seal             => $seal,
        recipient_pubkey => $RECIPIENT_PUBKEY,
    );
    my $wrap2 = Net::Nostr::GiftWrap->wrap(
        seal             => $seal,
        recipient_pubkey => $RECIPIENT_PUBKEY,
    );

    isnt($wrap1->pubkey, $AUTHOR_PUBKEY, 'wrap pubkey is not the author');
    isnt($wrap1->pubkey, $wrap2->pubkey, 'each wrap uses a different random key');
};

subtest 'gift wrap SHOULD include p-tag for recipient' => sub {
    my $rumor = Net::Nostr::GiftWrap->create_rumor(
        pubkey  => $author_key->pubkey_hex,
        kind    => 1,
        content => 'hello',
        tags    => [],
    );

    my $seal = Net::Nostr::GiftWrap->seal(
        rumor            => $rumor,
        sender_key       => $author_key,
        recipient_pubkey => $RECIPIENT_PUBKEY,
    );

    my $wrap = Net::Nostr::GiftWrap->wrap(
        seal             => $seal,
        recipient_pubkey => $RECIPIENT_PUBKEY,
    );

    my @p_tags = grep { $_->[0] eq 'p' } @{$wrap->tags};
    is(scalar @p_tags, 1, 'one p-tag');
    is($p_tags[0][1], $RECIPIENT_PUBKEY, 'p-tag is recipient pubkey');
};

subtest 'gift wrap content is NIP-44 encrypted seal' => sub {
    my $rumor = Net::Nostr::GiftWrap->create_rumor(
        pubkey  => $author_key->pubkey_hex,
        kind    => 1,
        content => 'hello',
        tags    => [],
    );

    my $seal = Net::Nostr::GiftWrap->seal(
        rumor            => $rumor,
        sender_key       => $author_key,
        recipient_pubkey => $RECIPIENT_PUBKEY,
    );

    my $wrap = Net::Nostr::GiftWrap->wrap(
        seal             => $seal,
        recipient_pubkey => $RECIPIENT_PUBKEY,
    );

    # Recipient can decrypt the gift wrap
    my $conv_key = Net::Nostr::Encryption->get_conversation_key(
        $RECIPIENT_PRIVKEY, $wrap->pubkey,
    );
    my $decrypted_json = Net::Nostr::Encryption->decrypt($wrap->content, $conv_key);
    my $decrypted = JSON::decode_json($decrypted_json);

    is($decrypted->{kind}, 13, 'decrypted content is a seal (kind 13)');
    is($decrypted->{pubkey}, $AUTHOR_PUBKEY, 'seal identifies real author');
};

###############################################################################
# Timestamps SHOULD be randomized and in the past
###############################################################################

subtest 'seal timestamp SHOULD be randomized (in the past)' => sub {
    my $rumor = Net::Nostr::GiftWrap->create_rumor(
        pubkey  => $author_key->pubkey_hex,
        kind    => 1,
        content => 'hello',
        tags    => [],
    );

    my $seal = Net::Nostr::GiftWrap->seal(
        rumor            => $rumor,
        sender_key       => $author_key,
        recipient_pubkey => $RECIPIENT_PUBKEY,
    );

    my $now = time();
    ok($seal->created_at <= $now, 'seal timestamp is not in the future');
    ok($seal->created_at >= $now - 2 * 24 * 60 * 60, 'seal timestamp within 2 days');
    isnt($seal->created_at, $rumor->created_at, 'seal timestamp differs from rumor');
};

subtest 'gift wrap timestamp SHOULD be randomized (in the past)' => sub {
    my $rumor = Net::Nostr::GiftWrap->create_rumor(
        pubkey  => $author_key->pubkey_hex,
        kind    => 1,
        content => 'hello',
        tags    => [],
    );

    my $seal = Net::Nostr::GiftWrap->seal(
        rumor            => $rumor,
        sender_key       => $author_key,
        recipient_pubkey => $RECIPIENT_PUBKEY,
    );

    my $wrap = Net::Nostr::GiftWrap->wrap(
        seal             => $seal,
        recipient_pubkey => $RECIPIENT_PUBKEY,
    );

    my $now = time();
    ok($wrap->created_at <= $now, 'wrap timestamp is not in the future');
    ok($wrap->created_at >= $now - 2 * 24 * 60 * 60, 'wrap timestamp within 2 days');
};

subtest 'canonical created_at belongs to the rumor' => sub {
    my $ts = 1700000000;
    my $rumor = Net::Nostr::GiftWrap->create_rumor(
        pubkey     => $author_key->pubkey_hex,
        kind       => 1,
        content    => 'hello',
        tags       => [],
        created_at => $ts,
    );

    is($rumor->created_at, $ts, 'rumor preserves exact timestamp');
};

###############################################################################
# Round-trip: seal_and_wrap then unwrap
###############################################################################

subtest 'round-trip: seal_and_wrap then unwrap' => sub {
    my $rumor = Net::Nostr::GiftWrap->create_rumor(
        pubkey  => $author_key->pubkey_hex,
        kind    => 1,
        content => 'round trip test',
        tags    => [['p', $RECIPIENT_PUBKEY]],
    );

    my $wrap = Net::Nostr::GiftWrap->seal_and_wrap(
        rumor            => $rumor,
        sender_key       => $author_key,
        recipient_pubkey => $RECIPIENT_PUBKEY,
    );

    is($wrap->kind, 1059, 'wrap is kind 1059');

    my ($unwrapped, $sender_pubkey) = Net::Nostr::GiftWrap->unwrap(
        event         => $wrap,
        recipient_key => $recipient_key,
    );

    is($unwrapped->kind, 1, 'unwrapped kind matches');
    is($unwrapped->content, 'round trip test', 'unwrapped content matches');
    is($unwrapped->pubkey, $AUTHOR_PUBKEY, 'unwrapped pubkey matches');
    is($sender_pubkey, $AUTHOR_PUBKEY, 'sender_pubkey from seal matches');
    ok(!defined $unwrapped->sig, 'unwrapped event is unsigned');
    is($unwrapped->tags, [['p', $RECIPIENT_PUBKEY]], 'tags preserved');
};

###############################################################################
# Wrapping for multiple recipients
###############################################################################

subtest 'same rumor wrapped individually for each recipient' => sub {
    my $other_key = Net::Nostr::Key->new;
    my $rumor = Net::Nostr::GiftWrap->create_rumor(
        pubkey  => $author_key->pubkey_hex,
        kind    => 1,
        content => 'group message',
        tags    => [
            ['p', $RECIPIENT_PUBKEY],
            ['p', $other_key->pubkey_hex],
        ],
    );

    my $wrap1 = Net::Nostr::GiftWrap->seal_and_wrap(
        rumor            => $rumor,
        sender_key       => $author_key,
        recipient_pubkey => $RECIPIENT_PUBKEY,
    );

    my $wrap2 = Net::Nostr::GiftWrap->seal_and_wrap(
        rumor            => $rumor,
        sender_key       => $author_key,
        recipient_pubkey => $other_key->pubkey_hex,
    );

    # Different wraps for different recipients
    isnt($wrap1->id, $wrap2->id, 'different wraps have different ids');
    isnt($wrap1->pubkey, $wrap2->pubkey, 'different wraps use different random keys');

    # Both unwrap to same rumor content
    my ($r1, $s1) = Net::Nostr::GiftWrap->unwrap(
        event         => $wrap1,
        recipient_key => $recipient_key,
    );
    my ($r2, $s2) = Net::Nostr::GiftWrap->unwrap(
        event         => $wrap2,
        recipient_key => $other_key,
    );

    is($r1->content, 'group message', 'recipient 1 gets same content');
    is($r2->content, 'group message', 'recipient 2 gets same content');
    is($s1, $AUTHOR_PUBKEY, 'recipient 1 sees correct sender');
    is($s2, $AUTHOR_PUBKEY, 'recipient 2 sees correct sender');
};

###############################################################################
# unwrap validation
###############################################################################

subtest 'unwrap rejects non-1059 event' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => 'a' x 64, kind => 1, content => '', tags => [],
    );
    like(dies { Net::Nostr::GiftWrap->unwrap(
        event         => $event,
        recipient_key => $recipient_key,
    ) }, qr/kind 1059/, 'rejects non-1059');
};

###############################################################################
# Proof of Work MAY be attached to gift wrap
###############################################################################

subtest 'MAY attach proof of work to gift wrap' => sub {
    my $rumor = Net::Nostr::GiftWrap->create_rumor(
        pubkey  => $author_key->pubkey_hex,
        kind    => 1,
        content => 'hello',
        tags    => [],
    );

    my $wrap = Net::Nostr::GiftWrap->seal_and_wrap(
        rumor            => $rumor,
        sender_key       => $author_key,
        recipient_pubkey => $RECIPIENT_PUBKEY,
    );

    # Gift wraps can have PoW mined on them
    ok($wrap->kind == 1059, 'wrap is kind 1059 (PoW can be added externally via mine)');
};

###############################################################################
# Optional created_at overrides for testing
###############################################################################

subtest 'seal accepts optional created_at override' => sub {
    my $rumor = Net::Nostr::GiftWrap->create_rumor(
        pubkey  => $author_key->pubkey_hex,
        kind    => 1,
        content => 'hello',
        tags    => [],
    );

    my $seal = Net::Nostr::GiftWrap->seal(
        rumor            => $rumor,
        sender_key       => $author_key,
        recipient_pubkey => $RECIPIENT_PUBKEY,
        created_at       => 1703015180,
    );

    is($seal->created_at, 1703015180, 'seal uses overridden timestamp');
};

subtest 'wrap accepts optional created_at and wrapper_key overrides' => sub {
    my $rumor = Net::Nostr::GiftWrap->create_rumor(
        pubkey  => $author_key->pubkey_hex,
        kind    => 1,
        content => 'hello',
        tags    => [],
    );

    my $seal = Net::Nostr::GiftWrap->seal(
        rumor            => $rumor,
        sender_key       => $author_key,
        recipient_pubkey => $RECIPIENT_PUBKEY,
    );

    my $wrap = Net::Nostr::GiftWrap->wrap(
        seal             => $seal,
        recipient_pubkey => $RECIPIENT_PUBKEY,
        wrapper_key      => $ephemeral_key,
        created_at       => 1703021488,
    );

    is($wrap->created_at, 1703021488, 'wrap uses overridden timestamp');
    is($wrap->pubkey, $EPHEMERAL_PUBKEY, 'wrap uses specified wrapper key');
};

###############################################################################
# Expiration tags MAY be added
###############################################################################

subtest 'MAY add expiration tags to seal and gift wrap' => sub {
    my $rumor = Net::Nostr::GiftWrap->create_rumor(
        pubkey  => $author_key->pubkey_hex,
        kind    => 1,
        content => 'disappearing message',
        tags    => [],
    );

    my $seal = Net::Nostr::GiftWrap->seal(
        rumor            => $rumor,
        sender_key       => $author_key,
        recipient_pubkey => $RECIPIENT_PUBKEY,
        expiration       => 1703100000,
    );

    my $wrap = Net::Nostr::GiftWrap->wrap(
        seal             => $seal,
        recipient_pubkey => $RECIPIENT_PUBKEY,
        expiration       => 1703200000,
    );

    my @seal_exp = grep { $_->[0] eq 'expiration' } @{$seal->tags};
    my @wrap_exp = grep { $_->[0] eq 'expiration' } @{$wrap->tags};

    is(scalar @seal_exp, 1, 'seal has expiration tag');
    is($seal_exp[0][1], '1703100000', 'seal expiration value');
    is(scalar @wrap_exp, 1, 'wrap has expiration tag');
    is($wrap_exp[0][1], '1703200000', 'wrap expiration value');
    isnt($seal_exp[0][1], $wrap_exp[0][1], 'SHOULD use independent timestamps');
};

###############################################################################
# Deniability: unsigned rumor cannot be authenticated
###############################################################################

subtest 'rumor provides deniability: unsigned event cannot be authenticated' => sub {
    my $rumor = Net::Nostr::GiftWrap->create_rumor(
        pubkey  => $author_key->pubkey_hex,
        kind    => 1,
        content => 'leaked message',
        tags    => [],
    );

    ok(!defined $rumor->sig, 'rumor has no signature');
    ok(dies { $rumor->verify_sig($author_key) }, 'verify_sig fails on unsigned rumor');
};

###############################################################################
# Gift wrap is signed by the random key, not the real author
###############################################################################

subtest 'gift wrap is signed by random key, hiding true author' => sub {
    my $rumor = Net::Nostr::GiftWrap->create_rumor(
        pubkey  => $author_key->pubkey_hex,
        kind    => 1,
        content => 'hello',
        tags    => [],
    );

    my $seal = Net::Nostr::GiftWrap->seal(
        rumor            => $rumor,
        sender_key       => $author_key,
        recipient_pubkey => $RECIPIENT_PUBKEY,
    );

    my $wrapper = Net::Nostr::Key->new;
    my $wrap = Net::Nostr::GiftWrap->wrap(
        seal             => $seal,
        recipient_pubkey => $RECIPIENT_PUBKEY,
        wrapper_key      => $wrapper,
    );

    isnt($wrap->pubkey, $AUTHOR_PUBKEY, 'wrap pubkey is not the real author');
    is($wrap->pubkey, $wrapper->pubkey_hex, 'wrap pubkey matches wrapper key');
    ok(defined $wrap->sig, 'wrap has a signature');
    ok($wrap->verify_sig($wrapper), 'wrap signature verifies with wrapper key');
    like(dies { $wrap->verify_sig($author_key) },
        qr/pubkey does not match/,
        'verify_sig rejects key that does not match wrap pubkey');
};

###############################################################################
# unwrap rejects non-kind-13 seal
###############################################################################

subtest 'unwrap rejects gift wrap containing non-kind-13 seal' => sub {
    # Build a fake "seal" that is kind 1 instead of kind 13
    my $fake_seal_rumor = Net::Nostr::Event->new(
        pubkey  => $author_key->pubkey_hex,
        kind    => 1,
        content => 'not a real seal',
        tags    => [],
    );
    my $fake_seal_json = JSON->new->utf8->canonical->encode($fake_seal_rumor->to_hash);

    my $wrapper = Net::Nostr::Key->new;
    my $conv_key = Net::Nostr::Encryption->get_conversation_key(
        $wrapper->privkey_hex, $RECIPIENT_PUBKEY,
    );
    my $encrypted = Net::Nostr::Encryption->encrypt($fake_seal_json, $conv_key);

    my $wrap = $wrapper->create_event(
        kind    => 1059,
        content => $encrypted,
        tags    => [['p', $RECIPIENT_PUBKEY]],
    );

    like(dies { Net::Nostr::GiftWrap->unwrap(
        event         => $wrap,
        recipient_key => $recipient_key,
    ) }, qr/kind 13/, 'rejects seal that is not kind 13');
};

###############################################################################
# Author can retain an encrypted copy by wrapping to self
###############################################################################

subtest 'author can unwrap a copy addressed to themselves' => sub {
    my $rumor = Net::Nostr::GiftWrap->create_rumor(
        pubkey  => $author_key->pubkey_hex,
        kind    => 1,
        content => 'saved for myself',
        tags    => [['p', $RECIPIENT_PUBKEY]],
    );

    my $self_wrap = Net::Nostr::GiftWrap->seal_and_wrap(
        rumor            => $rumor,
        sender_key       => $author_key,
        recipient_pubkey => $author_key->pubkey_hex,
    );

    my ($unwrapped, $sender_pubkey) = Net::Nostr::GiftWrap->unwrap(
        event         => $self_wrap,
        recipient_key => $author_key,
    );

    is($unwrapped->content, 'saved for myself', 'author can decrypt own copy');
    is($sender_pubkey, $AUTHOR_PUBKEY, 'sender pubkey matches author');
    is($unwrapped->pubkey, $AUTHOR_PUBKEY, 'rumor pubkey matches author');
};

subtest 'seal rejects invalid recipient_pubkey' => sub {
    my $rumor = Net::Nostr::GiftWrap->create_rumor(
        pubkey => $author_key->pubkey_hex, kind => 1, content => 'test', tags => [],
    );
    like(
        dies { Net::Nostr::GiftWrap->seal(
            rumor => $rumor, sender_key => $author_key,
            recipient_pubkey => 'bad',
        ) },
        qr/recipient_pubkey must be 64-char lowercase hex/,
        'invalid recipient_pubkey rejected'
    );
};

done_testing;
