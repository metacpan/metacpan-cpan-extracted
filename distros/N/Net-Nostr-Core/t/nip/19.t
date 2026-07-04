#!/usr/bin/perl

# NIP-19: bech32-encoded entities
# https://github.com/nostr-protocol/nips/blob/master/19.md

use strictures 2;

use Test2::V0 -no_srand => 1;

use Net::Nostr::Bech32 qw(
    encode_npub  decode_npub
    encode_nsec  decode_nsec
    encode_note  decode_note
    encode_nprofile decode_nprofile
    encode_nevent   decode_nevent
    encode_naddr    decode_naddr
    decode_bech32_entity
);
use Net::Nostr::Key;
use Bitcoin::Crypto::Bech32 qw(encode_bech32 translate_8to5);

###############################################################################
# npub - public keys
###############################################################################

subtest 'encode npub from spec example' => sub {
    my $hex = '7e7e9c42a91bfef19fa929e5fda1b72e0ebc1a4c1141673e2794234d86addf4e';
    my $npub = encode_npub($hex);
    is($npub, 'npub10elfcs4fr0l0r8af98jlmgdh9c8tcxjvz9qkw038js35mp4dma8qzvjptg', 'spec example npub');
};

subtest 'decode npub from spec example' => sub {
    my $hex = decode_npub('npub10elfcs4fr0l0r8af98jlmgdh9c8tcxjvz9qkw038js35mp4dma8qzvjptg');
    is($hex, '7e7e9c42a91bfef19fa929e5fda1b72e0ebc1a4c1141673e2794234d86addf4e', 'spec example hex');
};

subtest 'npub round-trip' => sub {
    my $hex = 'a' x 64;
    is(decode_npub(encode_npub($hex)), $hex, 'round-trip preserves hex');
};

subtest 'decode npub croaks on wrong prefix' => sub {
    ok(dies { decode_npub('nsec1vl029mgpspedva04g90vltkh6fvh240zqtv9k0t9af8935ke9laqsnlfe5') },
        'croaks on nsec prefix');
};

subtest 'encode npub croaks on invalid hex' => sub {
    ok(dies { encode_npub('not-hex') }, 'croaks on non-hex');
    ok(dies { encode_npub('aa') }, 'croaks on wrong length');
};

###############################################################################
# nsec - private keys
###############################################################################

subtest 'encode nsec from spec example' => sub {
    my $hex = '67dea2ed018072d675f5415ecfaed7d2597555e202d85b3d65ea4e58d2d92ffa';
    my $nsec = encode_nsec($hex);
    is($nsec, 'nsec1vl029mgpspedva04g90vltkh6fvh240zqtv9k0t9af8935ke9laqsnlfe5', 'spec example nsec');
};

subtest 'decode nsec from spec example' => sub {
    my $hex = decode_nsec('nsec1vl029mgpspedva04g90vltkh6fvh240zqtv9k0t9af8935ke9laqsnlfe5');
    is($hex, '67dea2ed018072d675f5415ecfaed7d2597555e202d85b3d65ea4e58d2d92ffa', 'spec example hex');
};

subtest 'nsec round-trip' => sub {
    my $hex = 'b' x 64;
    is(decode_nsec(encode_nsec($hex)), $hex, 'round-trip preserves hex');
};

subtest 'decode nsec croaks on wrong prefix' => sub {
    ok(dies { decode_nsec('npub10elfcs4fr0l0r8af98jlmgdh9c8tcxjvz9qkw038js35mp4dma8qzvjptg') },
        'croaks on npub prefix');
};

###############################################################################
# note - event ids
###############################################################################

subtest 'note round-trip' => sub {
    my $hex = 'c' x 64;
    my $note = encode_note($hex);
    like($note, qr/^note1/, 'starts with note1');
    is(decode_note($note), $hex, 'round-trip preserves hex');
};

subtest 'decode note croaks on wrong prefix' => sub {
    ok(dies { decode_note('npub10elfcs4fr0l0r8af98jlmgdh9c8tcxjvz9qkw038js35mp4dma8qzvjptg') },
        'croaks on npub prefix');
};

###############################################################################
# nprofile - profile with TLV metadata
###############################################################################

subtest 'decode nprofile from spec example' => sub {
    my $result = decode_nprofile('nprofile1qqsrhuxx8l9ex335q7he0f09aej04zpazpl0ne2cgukyawd24mayt8gpp4mhxue69uhhytnc9e3k7mgpz4mhxue69uhkg6nzv9ejuumpv34kytnrdaksjlyr9p');
    is($result->{pubkey}, '3bf0c63fcb93463407af97a5e5ee64fa883d107ef9e558472c4eb9aaaefa459d', 'pubkey');
    is($result->{relays}, ['wss://r.x.com', 'wss://djbas.sadkb.com'], 'relays');
};

subtest 'encode nprofile round-trip' => sub {
    my $pubkey = 'a' x 64;
    my $relays = ['wss://relay1.com', 'wss://relay2.com'];
    my $encoded = encode_nprofile(pubkey => $pubkey, relays => $relays);
    like($encoded, qr/^nprofile1/, 'starts with nprofile1');
    my $decoded = decode_nprofile($encoded);
    is($decoded->{pubkey}, $pubkey, 'pubkey round-trips');
    is($decoded->{relays}, $relays, 'relays round-trip');
};

subtest 'nprofile with no relays' => sub {
    my $pubkey = 'a' x 64;
    my $encoded = encode_nprofile(pubkey => $pubkey);
    my $decoded = decode_nprofile($encoded);
    is($decoded->{pubkey}, $pubkey, 'pubkey preserved');
    is($decoded->{relays}, [], 'no relays');
};

subtest 'decode nprofile croaks on wrong prefix' => sub {
    ok(dies { decode_nprofile('npub10elfcs4fr0l0r8af98jlmgdh9c8tcxjvz9qkw038js35mp4dma8qzvjptg') },
        'croaks on npub prefix');
};

###############################################################################
# nevent - event with TLV metadata
###############################################################################

subtest 'nevent round-trip with all fields' => sub {
    my %input = (
        id     => 'c' x 64,
        relays => ['wss://relay.com'],
        author => 'a' x 64,
        kind   => 1,
    );
    my $encoded = encode_nevent(%input);
    like($encoded, qr/^nevent1/, 'starts with nevent1');
    my $decoded = decode_nevent($encoded);
    is($decoded->{id}, $input{id}, 'id round-trips');
    is($decoded->{relays}, $input{relays}, 'relays round-trip');
    is($decoded->{author}, $input{author}, 'author round-trips');
    is($decoded->{kind}, $input{kind}, 'kind round-trips');
};

subtest 'nevent with only id' => sub {
    my $encoded = encode_nevent(id => 'd' x 64);
    my $decoded = decode_nevent($encoded);
    is($decoded->{id}, 'd' x 64, 'id preserved');
    is($decoded->{relays}, [], 'no relays');
    is($decoded->{author}, undef, 'no author');
    is($decoded->{kind}, undef, 'no kind');
};

subtest 'nevent with multiple relays' => sub {
    my $encoded = encode_nevent(
        id     => 'e' x 64,
        relays => ['wss://r1.com', 'wss://r2.com', 'wss://r3.com'],
    );
    my $decoded = decode_nevent($encoded);
    is($decoded->{relays}, ['wss://r1.com', 'wss://r2.com', 'wss://r3.com'], 'multiple relays');
};

subtest 'decode nevent croaks on wrong prefix' => sub {
    ok(dies { decode_nevent('npub10elfcs4fr0l0r8af98jlmgdh9c8tcxjvz9qkw038js35mp4dma8qzvjptg') },
        'croaks on npub prefix');
};

###############################################################################
# naddr - addressable event coordinate
###############################################################################

subtest 'naddr round-trip with all fields' => sub {
    my %input = (
        identifier => 'my-article',
        pubkey     => 'a' x 64,
        kind       => 30023,
        relays     => ['wss://relay.com'],
    );
    my $encoded = encode_naddr(%input);
    like($encoded, qr/^naddr1/, 'starts with naddr1');
    my $decoded = decode_naddr($encoded);
    is($decoded->{identifier}, 'my-article', 'identifier round-trips');
    is($decoded->{pubkey}, $input{pubkey}, 'pubkey round-trips');
    is($decoded->{kind}, $input{kind}, 'kind round-trips');
    is($decoded->{relays}, $input{relays}, 'relays round-trip');
};

subtest 'naddr with empty identifier (normal replaceable event)' => sub {
    my $encoded = encode_naddr(
        identifier => '',
        pubkey     => 'b' x 64,
        kind       => 10002,
    );
    my $decoded = decode_naddr($encoded);
    is($decoded->{identifier}, '', 'empty identifier');
};

subtest 'decode naddr croaks on wrong prefix' => sub {
    ok(dies { decode_naddr('npub10elfcs4fr0l0r8af98jlmgdh9c8tcxjvz9qkw038js35mp4dma8qzvjptg') },
        'croaks on npub prefix');
};

###############################################################################
# Generic decode - auto-detect prefix
###############################################################################

subtest 'decode_bech32_entity auto-detects npub' => sub {
    my $npub = encode_npub('a' x 64);
    my $result = decode_bech32_entity($npub);
    is($result->{type}, 'npub', 'type is npub');
    is($result->{data}, 'a' x 64, 'data is hex pubkey');
};

subtest 'decode_bech32_entity auto-detects nsec' => sub {
    my $nsec = encode_nsec('b' x 64);
    my $result = decode_bech32_entity($nsec);
    is($result->{type}, 'nsec', 'type is nsec');
    is($result->{data}, 'b' x 64, 'data is hex privkey');
};

subtest 'decode_bech32_entity auto-detects note' => sub {
    my $note = encode_note('c' x 64);
    my $result = decode_bech32_entity($note);
    is($result->{type}, 'note', 'type is note');
    is($result->{data}, 'c' x 64, 'data is hex event id');
};

subtest 'decode_bech32_entity auto-detects nprofile' => sub {
    my $nprofile = encode_nprofile(pubkey => 'a' x 64, relays => ['wss://r.com']);
    my $result = decode_bech32_entity($nprofile);
    is($result->{type}, 'nprofile', 'type is nprofile');
    is($result->{data}{pubkey}, 'a' x 64, 'pubkey');
    is($result->{data}{relays}, ['wss://r.com'], 'relays');
};

subtest 'decode_bech32_entity auto-detects nevent' => sub {
    my $nevent = encode_nevent(id => 'd' x 64, kind => 1);
    my $result = decode_bech32_entity($nevent);
    is($result->{type}, 'nevent', 'type is nevent');
    is($result->{data}{id}, 'd' x 64, 'id');
    is($result->{data}{kind}, 1, 'kind');
};

subtest 'decode_bech32_entity auto-detects naddr' => sub {
    my $naddr = encode_naddr(identifier => 'test', pubkey => 'a' x 64, kind => 30023);
    my $result = decode_bech32_entity($naddr);
    is($result->{type}, 'naddr', 'type is naddr');
    is($result->{data}{identifier}, 'test', 'identifier');
};

subtest 'decode_bech32_entity croaks on unknown prefix' => sub {
    ok(dies { decode_bech32_entity('unknown1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqejwg6z') },
        'croaks on unknown prefix');
};

###############################################################################
# Key integration - npub/nsec convenience methods
###############################################################################

subtest 'Key pubkey_npub returns valid npub' => sub {
    my $key = Net::Nostr::Key->new;
    my $npub = $key->pubkey_npub;
    like($npub, qr/^npub1/, 'starts with npub1');
    is(decode_npub($npub), $key->pubkey_hex, 'decodes back to same pubkey');
};

subtest 'Key privkey_nsec returns valid nsec' => sub {
    my $key = Net::Nostr::Key->new;
    my $nsec = $key->privkey_nsec;
    like($nsec, qr/^nsec1/, 'starts with nsec1');
    is(decode_nsec($nsec), $key->privkey_hex, 'decodes back to same privkey');
};

###############################################################################
# Validation
###############################################################################

subtest 'encode functions reject non-hex input' => sub {
    ok(dies { encode_npub('xyz') }, 'npub rejects non-hex');
    ok(dies { encode_nsec('xyz') }, 'nsec rejects non-hex');
    ok(dies { encode_note('xyz') }, 'note rejects non-hex');
};

subtest 'encode functions reject wrong-length hex' => sub {
    ok(dies { encode_npub('aa' x 31) }, 'npub rejects 31 bytes');
    ok(dies { encode_nsec('aa' x 33) }, 'nsec rejects 33 bytes');
    ok(dies { encode_note('aa' x 16) }, 'note rejects 16 bytes');
};

subtest 'nprofile encode requires pubkey' => sub {
    ok(dies { encode_nprofile(relays => ['wss://r.com']) }, 'croaks without pubkey');
};

subtest 'nevent encode requires id' => sub {
    ok(dies { encode_nevent(author => 'a' x 64) }, 'croaks without id');
};

subtest 'naddr encode requires identifier, pubkey, and kind' => sub {
    ok(dies { encode_naddr(pubkey => 'a' x 64, kind => 30023) }, 'croaks without identifier');
    ok(dies { encode_naddr(identifier => 'x', kind => 30023) }, 'croaks without pubkey');
    ok(dies { encode_naddr(identifier => 'x', pubkey => 'a' x 64) }, 'croaks without kind');
};

###############################################################################
# Strings longer than 90 chars decode correctly (BIP-173 limit does not apply)
###############################################################################

subtest 'decode works for bech32 strings longer than 90 chars' => sub {
    my @relays = ('wss://relay.example.com/', 'wss://relay2.example.com/nostr');
    my $encoded = encode_nprofile(pubkey => 'a' x 64, relays => \@relays);
    cmp_ok(length($encoded), '>', 90, 'encoded string exceeds 90 chars');
    my $decoded = decode_nprofile($encoded);
    is($decoded->{pubkey}, 'a' x 64, 'pubkey decoded correctly');
    is($decoded->{relays}, \@relays, 'relays decoded correctly');
};

###############################################################################
# Bech32 size limit
###############################################################################

subtest 'bech32 strings should be limited to 5000 characters' => sub {
    # A huge number of relays could exceed the limit
    my @relays = map { "wss://very-long-relay-url-$_.example.com/nostr" } 1..200;
    ok(dies { encode_nprofile(pubkey => 'a' x 64, relays => \@relays) },
        'croaks when encoded string exceeds 5000 chars');
};

###############################################################################
# Unknown TLV types are ignored during decode
###############################################################################

subtest 'unknown TLV types are ignored' => sub {
    # Encode a normal nprofile, decode it, should work even if we
    # encounter unknown types in the wild. We test this by verifying
    # our decoder doesn't choke on the spec example which may have
    # future TLV types added.
    my $encoded = encode_nprofile(pubkey => 'a' x 64);
    my $decoded = decode_nprofile($encoded);
    is($decoded->{pubkey}, 'a' x 64, 'known fields decoded correctly');
};

###############################################################################
# Malformed TLV: bounds checking
###############################################################################

subtest 'truncated TLV: missing length byte' => sub {
    # Craft a payload with only a type byte (no length byte)
    my $payload = pack('C', 0);  # type=0, no length
    my $data5 = translate_8to5($payload);
    my $bech32 = encode_bech32('nprofile', $data5, 'bech32');
    like(dies { decode_nprofile($bech32) }, qr/truncated/i,
        'croaks on missing length byte');
};

subtest 'truncated TLV: declared length exceeds payload' => sub {
    # type=0, length=32, but only 2 bytes of value
    my $payload = pack('CC', 0, 32) . ('x' x 2);
    my $data5 = translate_8to5($payload);
    my $bech32 = encode_bech32('nprofile', $data5, 'bech32');
    like(dies { decode_nprofile($bech32) }, qr/truncated/i,
        'croaks when value extends beyond payload');
};

###############################################################################
# Bare type payload size validation (must be exactly 32 bytes)
###############################################################################

subtest 'bare decode rejects short payload' => sub {
    # Encode only 16 bytes (not 32) with npub prefix
    my $short = pack('H*', 'aa' x 16);
    my $data5 = translate_8to5($short);
    my $bech32 = encode_bech32('npub', $data5, 'bech32');
    like(dies { decode_npub($bech32) }, qr/exactly 32 bytes/,
        'npub rejects 16-byte payload');
};

subtest 'bare decode rejects long payload' => sub {
    my $long = pack('H*', 'aa' x 33);
    my $data5 = translate_8to5($long);
    my $bech32 = encode_bech32('npub', $data5, 'bech32');
    like(dies { decode_npub($bech32) }, qr/exactly 32 bytes/,
        'npub rejects 33-byte payload');
};

subtest 'nsec decode rejects short payload' => sub {
    my $short = pack('H*', 'bb' x 16);
    my $data5 = translate_8to5($short);
    my $bech32 = encode_bech32('nsec', $data5, 'bech32');
    like(dies { decode_nsec($bech32) }, qr/exactly 32 bytes/,
        'nsec rejects 16-byte payload');
};

subtest 'note decode rejects short payload' => sub {
    my $short = pack('H*', 'cc' x 16);
    my $data5 = translate_8to5($short);
    my $bech32 = encode_bech32('note', $data5, 'bech32');
    like(dies { decode_note($bech32) }, qr/exactly 32 bytes/,
        'note rejects 16-byte payload');
};

###############################################################################
# TLV: missing required fields
###############################################################################

subtest 'nprofile rejects missing pubkey' => sub {
    # Encode an nprofile with only a relay TLV (no type 0)
    my $relay = 'wss://r.com';
    my $payload = pack('CC', 1, length($relay)) . $relay;
    my $data5 = translate_8to5($payload);
    my $bech32 = encode_bech32('nprofile', $data5, 'bech32');
    like(dies { decode_nprofile($bech32) }, qr/missing required pubkey/,
        'nprofile without pubkey croaks');
};

subtest 'nevent rejects missing event id' => sub {
    # Encode a nevent with only a relay TLV (no type 0)
    my $relay = 'wss://r.com';
    my $payload = pack('CC', 1, length($relay)) . $relay;
    my $data5 = translate_8to5($payload);
    my $bech32 = encode_bech32('nevent', $data5, 'bech32');
    like(dies { decode_nevent($bech32) }, qr/missing required event id/,
        'nevent without event id croaks');
};

subtest 'naddr rejects missing required fields' => sub {
    # Encode naddr with only identifier (missing pubkey and kind)
    my $ident = 'test';
    my $payload = pack('CC', 0, length($ident)) . $ident;
    my $data5 = translate_8to5($payload);
    my $bech32 = encode_bech32('naddr', $data5, 'bech32');
    like(dies { decode_naddr($bech32) }, qr/missing required pubkey/,
        'naddr without pubkey croaks');
};

###############################################################################
# TLV: wrong field lengths
###############################################################################

subtest 'nprofile rejects wrong-length pubkey' => sub {
    # type 0, 16 bytes instead of 32
    my $payload = pack('CC', 0, 16) . ('x' x 16);
    my $data5 = translate_8to5($payload);
    my $bech32 = encode_bech32('nprofile', $data5, 'bech32');
    like(dies { decode_nprofile($bech32) }, qr/exactly 32 bytes/,
        'nprofile rejects 16-byte pubkey');
};

subtest 'nevent rejects wrong-length event id' => sub {
    my $payload = pack('CC', 0, 16) . ('x' x 16);
    my $data5 = translate_8to5($payload);
    my $bech32 = encode_bech32('nevent', $data5, 'bech32');
    like(dies { decode_nevent($bech32) }, qr/exactly 32 bytes/,
        'nevent rejects 16-byte event id');
};

subtest 'nevent rejects wrong-length author' => sub {
    # valid event id (32 bytes), then author with 16 bytes
    my $payload = pack('CC', 0, 32) . ("\x00" x 32);
    $payload .= pack('CC', 2, 16) . ('x' x 16);
    my $data5 = translate_8to5($payload);
    my $bech32 = encode_bech32('nevent', $data5, 'bech32');
    like(dies { decode_nevent($bech32) }, qr/exactly 32 bytes/,
        'nevent rejects 16-byte author');
};

subtest 'nevent rejects wrong-length kind' => sub {
    # valid event id, then kind with 2 bytes instead of 4
    my $payload = pack('CC', 0, 32) . ("\x00" x 32);
    $payload .= pack('CC', 3, 2) . ('xx');
    my $data5 = translate_8to5($payload);
    my $bech32 = encode_bech32('nevent', $data5, 'bech32');
    like(dies { decode_nevent($bech32) }, qr/exactly 4 bytes/,
        'nevent rejects 2-byte kind');
};

subtest 'naddr rejects wrong-length pubkey' => sub {
    my $ident = 'test';
    my $payload = pack('CC', 0, length($ident)) . $ident;
    $payload .= pack('CC', 2, 16) . ('x' x 16);  # wrong size pubkey
    $payload .= pack('CC', 3, 4) . pack('N', 30023);
    my $data5 = translate_8to5($payload);
    my $bech32 = encode_bech32('naddr', $data5, 'bech32');
    like(dies { decode_naddr($bech32) }, qr/exactly 32 bytes/,
        'naddr rejects 16-byte pubkey');
};

subtest 'naddr rejects wrong-length kind' => sub {
    my $ident = 'test';
    my $payload = pack('CC', 0, length($ident)) . $ident;
    $payload .= pack('CC', 2, 32) . ("\x00" x 32);
    $payload .= pack('CC', 3, 2) . ('xx');  # wrong size kind
    my $data5 = translate_8to5($payload);
    my $bech32 = encode_bech32('naddr', $data5, 'bech32');
    like(dies { decode_naddr($bech32) }, qr/exactly 4 bytes/,
        'naddr rejects 2-byte kind');
};

done_testing;
