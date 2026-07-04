use strictures 2;
use Test2::V0 -no_srand => 1;

use Net::Nostr::Key;

# --- Test vector 1 from NIP-06 spec ---

subtest 'test vector 1: 12-word mnemonic' => sub {
    my $mnemonic = 'leader monkey parrot ring guide accident before fence cannon height naive bean';
    my $key = Net::Nostr::Key->from_mnemonic($mnemonic);

    is $key->privkey_hex, '7f7ff03d123792d6ac594bfa67bf6d0c0ab55b6b1fdb6249303fe861f1ccba9a',
        'private key matches spec';
    is $key->pubkey_hex, '17162c921dc4d2518f9a101db33695df1afb56ab82f5ff3e5da6eec3ca5cd917',
        'public key matches spec';
    is $key->privkey_nsec, 'nsec10allq0gjx7fddtzef0ax00mdps9t2kmtrldkyjfs8l5xruwvh2dq0lhhkp',
        'nsec matches spec';
    is $key->pubkey_npub, 'npub1zutzeysacnf9rru6zqwmxd54mud0k44tst6l70ja5mhv8jjumytsd2x7nu',
        'npub matches spec';
};

# --- Test vector 2 from NIP-06 spec ---

subtest 'test vector 2: 24-word mnemonic' => sub {
    my $mnemonic = 'what bleak badge arrange retreat wolf trade produce cricket blur garlic valid proud rude strong choose busy staff weather area salt hollow arm fade';
    my $key = Net::Nostr::Key->from_mnemonic($mnemonic);

    is $key->privkey_hex, 'c15d739894c81a2fcfd3a2df85a0d2c0dbc47a280d092799f144d73d7ae78add',
        'private key matches spec';
    is $key->pubkey_hex, 'd41b22899549e1f3d335a31002cfd382174006e166d3e658e3a5eecdb6463573',
        'public key matches spec';
    is $key->privkey_nsec, 'nsec1c9wh8xy5eqdzln7n5t0ctgxjcrdug73gp5yj0x03gntn67h83twssdfhel',
        'nsec matches spec';
    is $key->pubkey_npub, 'npub16sdj9zv4f8sl85e45vgq9n7nsgt5qphpvmf7vk8r5hhvmdjxx4es8rq74h',
        'npub matches spec';
};

# --- BIP32 derivation path ---

subtest 'derivation path is m/44h/1237h/account/0/0' => sub {
    my $mnemonic = 'leader monkey parrot ring guide accident before fence cannon height naive bean';

    # account 0 (default)
    my $key0 = Net::Nostr::Key->from_mnemonic($mnemonic);
    is $key0->privkey_hex, '7f7ff03d123792d6ac594bfa67bf6d0c0ab55b6b1fdb6249303fe861f1ccba9a',
        'account 0 matches test vector';

    # account 1 should derive a different key
    my $key1 = Net::Nostr::Key->from_mnemonic($mnemonic, account => 1);
    isnt $key1->privkey_hex, $key0->privkey_hex, 'account 1 differs from account 0';

    # account 0 explicit should match default
    my $key0_explicit = Net::Nostr::Key->from_mnemonic($mnemonic, account => 0);
    is $key0_explicit->privkey_hex, $key0->privkey_hex, 'explicit account 0 matches default';
};

# --- Multiple accounts ---

subtest 'can derive practically infinite keys by incrementing account' => sub {
    my $mnemonic = 'leader monkey parrot ring guide accident before fence cannon height naive bean';
    my %seen;
    for my $i (0..4) {
        my $key = Net::Nostr::Key->from_mnemonic($mnemonic, account => $i);
        ok !$seen{$key->privkey_hex}, "account $i produces unique key";
        $seen{$key->privkey_hex} = 1;
    }
};

# --- generate_mnemonic ---

subtest 'generate_mnemonic returns valid mnemonic' => sub {
    my $mnemonic = Net::Nostr::Key->generate_mnemonic;
    my @words = split / /, $mnemonic;
    ok scalar @words == 12 || scalar @words == 24, 'mnemonic has 12 or 24 words';

    # should be usable for key derivation
    my $key = Net::Nostr::Key->from_mnemonic($mnemonic);
    ok $key->privkey_loaded, 'derived key has private key';
    ok length($key->privkey_hex) == 64, 'private key is 64 hex chars';
};

subtest 'generate_mnemonic with bits => 256 returns 24 words' => sub {
    my $mnemonic = Net::Nostr::Key->generate_mnemonic(bits => 256);
    my @words = split / /, $mnemonic;
    is scalar @words, 24, '256 bits produces 24-word mnemonic';
};

subtest 'generate_mnemonic with bits => 128 returns 12 words' => sub {
    my $mnemonic = Net::Nostr::Key->generate_mnemonic(bits => 128);
    my @words = split / /, $mnemonic;
    is scalar @words, 12, '128 bits produces 12-word mnemonic';
};

subtest 'generate_mnemonic produces different mnemonics each call' => sub {
    my $m1 = Net::Nostr::Key->generate_mnemonic;
    my $m2 = Net::Nostr::Key->generate_mnemonic;
    isnt $m1, $m2, 'two calls produce different mnemonics';
};

# --- from_mnemonic returns a proper Key object ---

subtest 'from_mnemonic returns a Net::Nostr::Key' => sub {
    my $mnemonic = 'leader monkey parrot ring guide accident before fence cannon height naive bean';
    my $key = Net::Nostr::Key->from_mnemonic($mnemonic);
    isa_ok $key, 'Net::Nostr::Key';
    ok $key->privkey_loaded, 'private key loaded';
    ok $key->pubkey_loaded, 'public key loaded';
};

subtest 'from_mnemonic key can sign events' => sub {
    my $mnemonic = 'leader monkey parrot ring guide accident before fence cannon height naive bean';
    my $key = Net::Nostr::Key->from_mnemonic($mnemonic);
    my $event = $key->create_event(kind => 1, content => 'from mnemonic', tags => []);
    ok $event->sig, 'event is signed';
    ok $event->verify_sig($key), 'signature verifies';
};

# --- error handling ---

subtest 'from_mnemonic croaks on invalid mnemonic' => sub {
    eval { Net::Nostr::Key->from_mnemonic('not a valid mnemonic phrase') };
    ok $@, 'croaks on invalid mnemonic';
};

done_testing;
