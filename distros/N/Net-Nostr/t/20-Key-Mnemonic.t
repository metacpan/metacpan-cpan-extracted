use strictures 2;
use Test2::V0 -no_srand => 1;

use Net::Nostr::Key;

# --- POD SYNOPSIS: mnemonic examples ---

subtest 'POD SYNOPSIS: generate_mnemonic and from_mnemonic' => sub {
    my $mnemonic = Net::Nostr::Key->generate_mnemonic;
    my $key = Net::Nostr::Key->from_mnemonic($mnemonic);
    ok $key->privkey_loaded, 'key from generated mnemonic has privkey';
    my $key1 = Net::Nostr::Key->from_mnemonic($mnemonic, account => 1);
    isnt $key->privkey_hex, $key1->privkey_hex, 'account 1 differs';
};

# --- POD from_mnemonic: basic usage ---

subtest 'POD from_mnemonic: derive key from mnemonic' => sub {
    my $mnemonic = 'leader monkey parrot ring guide accident before fence cannon height naive bean';
    my $key = Net::Nostr::Key->from_mnemonic($mnemonic);
    like $key->privkey_hex, qr/^[0-9a-f]{64}$/, 'privkey_hex is 64 hex chars';
    like $key->pubkey_npub, qr/^npub1/, 'pubkey_npub starts with npub1';
};

# --- POD from_mnemonic: account parameter ---

subtest 'POD from_mnemonic: multiple accounts' => sub {
    my $mnemonic = 'leader monkey parrot ring guide accident before fence cannon height naive bean';
    my $key0 = Net::Nostr::Key->from_mnemonic($mnemonic);
    my $key1 = Net::Nostr::Key->from_mnemonic($mnemonic, account => 1);
    isnt $key0->privkey_hex, $key1->privkey_hex, 'different accounts produce different keys';
};

# --- POD from_mnemonic: croaks on invalid ---

subtest 'POD from_mnemonic: croaks on invalid mnemonic' => sub {
    eval { Net::Nostr::Key->from_mnemonic('invalid words here') };
    ok $@, 'croaks on invalid mnemonic';
};

# --- POD generate_mnemonic: basic ---

subtest 'POD generate_mnemonic: default 12 words' => sub {
    my $mnemonic = Net::Nostr::Key->generate_mnemonic;
    my @words = split / /, $mnemonic;
    ok scalar @words == 12 || scalar @words == 24, 'produces 12 or 24 words';
};

# --- POD generate_mnemonic: bits => 256 ---

subtest 'POD generate_mnemonic: 256 bits produces 24 words' => sub {
    my $mnemonic = Net::Nostr::Key->generate_mnemonic(bits => 256);
    my @words = split / /, $mnemonic;
    is scalar @words, 24, '24 words';
};

# --- POD generate_mnemonic: round-trip ---

subtest 'POD generate_mnemonic: round-trip with from_mnemonic' => sub {
    my $mnemonic = Net::Nostr::Key->generate_mnemonic;
    my $key = Net::Nostr::Key->from_mnemonic($mnemonic);
    like $key->pubkey_npub, qr/^npub1/, 'derived key has npub';
};

done_testing;
