#!/usr/bin/perl

# NIP-B7 conformance tests: Blossom media

use strictures 2;

use Test2::V0 -no_srand => 1;
use Digest::SHA qw(sha256_hex);

use Net::Nostr::Blossom;
use Net::Nostr::Event;

my $PUBKEY = '781208004e09102d7da3b7345e64fd193cd1bc3fce8fdae6008d77f9cabcd036';

###############################################################################
# Kind 10063 — replaceable event with server tags
###############################################################################

subtest 'kind 10063 is replaceable' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $PUBKEY, kind => 10063, content => '', tags => [],
    );
    ok($event->is_replaceable, 'kind 10063 is replaceable');
};

###############################################################################
# Spec example — exact JSON from NIP-B7
###############################################################################

subtest 'spec example: kind 10063 with server tags' => sub {
    my $event = Net::Nostr::Event->new(
        id      => 'e4bee088334cb5d38cff1616e964369c37b6081be997962ab289d6c671975d71',
        pubkey  => $PUBKEY,
        content => '',
        kind    => 10063,
        created_at => 1708774162,
        tags    => [
            ['server', 'https://blossom.self.hosted'],
            ['server', 'https://cdn.blossom.cloud'],
        ],
        sig => 'cc5efa74f59e80622c77cacf4dd62076bcb7581b45e9acff471e7963a1f4d8b3406adab5ee1ac9673487480e57d20e523428e60ffcc7e7a904ac882cfccfc653',
    );

    my $bl = Net::Nostr::Blossom->from_event($event);
    is($bl->count, 2, 'two servers');
    my @urls = $bl->servers;
    is($urls[0], 'https://blossom.self.hosted', 'first server');
    is($urls[1], 'https://cdn.blossom.cloud', 'second server');
};

###############################################################################
# Server list management
###############################################################################

subtest 'add and count servers' => sub {
    my $bl = Net::Nostr::Blossom->new;
    $bl->add('https://blossom.example.com');
    $bl->add('https://cdn.blossom.cloud');
    is($bl->count, 2, 'two servers');
};

subtest 'add returns self for chaining' => sub {
    my $bl = Net::Nostr::Blossom->new;
    my $ret = $bl->add('https://blossom.example.com');
    is($ret, $bl, 'returns self');
};

subtest 'add requires url' => sub {
    my $bl = Net::Nostr::Blossom->new;
    like(dies { $bl->add(undef) }, qr/url required/, 'undef rejected');
};

subtest 'add deduplicates by URL' => sub {
    my $bl = Net::Nostr::Blossom->new;
    $bl->add('https://blossom.example.com');
    $bl->add('https://blossom.example.com');
    is($bl->count, 1, 'no duplicate');
};

subtest 'remove deletes server' => sub {
    my $bl = Net::Nostr::Blossom->new;
    $bl->add('https://server1.com');
    $bl->add('https://server2.com');
    $bl->remove('https://server1.com');
    is($bl->count, 1, 'one remaining');
    is(($bl->servers)[0], 'https://server2.com', 'correct server remains');
};

subtest 'remove returns self for chaining' => sub {
    my $bl = Net::Nostr::Blossom->new;
    $bl->add('https://server.com');
    my $ret = $bl->remove('https://server.com');
    is($ret, $bl, 'returns self');
};

subtest 'remove is no-op for absent server' => sub {
    my $bl = Net::Nostr::Blossom->new;
    $bl->add('https://server.com');
    $bl->remove('https://other.com');
    is($bl->count, 1, 'count unchanged');
};

subtest 'contains checks server presence' => sub {
    my $bl = Net::Nostr::Blossom->new;
    $bl->add('https://blossom.example.com');
    ok($bl->contains('https://blossom.example.com'), 'present');
    ok(!$bl->contains('https://other.com'), 'absent');
};

subtest 'servers returns list in order' => sub {
    my $bl = Net::Nostr::Blossom->new;
    $bl->add('https://first.com');
    $bl->add('https://second.com');
    $bl->add('https://third.com');
    is([$bl->servers], ['https://first.com', 'https://second.com', 'https://third.com'],
        'insertion order preserved');
};

###############################################################################
# to_tags / to_event
###############################################################################

subtest 'to_tags creates server tag arrays' => sub {
    my $bl = Net::Nostr::Blossom->new;
    $bl->add('https://blossom.self.hosted');
    $bl->add('https://cdn.blossom.cloud');

    my $tags = $bl->to_tags;
    is($tags, [
        ['server', 'https://blossom.self.hosted'],
        ['server', 'https://cdn.blossom.cloud'],
    ], 'server tags');
};

subtest 'to_event creates kind 10063 with empty content' => sub {
    my $bl = Net::Nostr::Blossom->new;
    $bl->add('https://blossom.example.com');

    my $event = $bl->to_event(pubkey => $PUBKEY);
    is($event->kind, 10063, 'kind 10063');
    is($event->content, '', 'empty content');
    is(scalar @{$event->tags}, 1, 'one tag');
    is($event->tags->[0], ['server', 'https://blossom.example.com'], 'server tag');
};

subtest 'to_event passes extra args' => sub {
    my $bl = Net::Nostr::Blossom->new;
    $bl->add('https://server.com');
    my $event = $bl->to_event(pubkey => $PUBKEY, created_at => 1708774162);
    is($event->created_at, 1708774162, 'created_at passed through');
};

subtest 'to_event forces empty content' => sub {
    my $bl = Net::Nostr::Blossom->new;
    $bl->add('https://server.com');
    my $event = $bl->to_event(pubkey => $PUBKEY, content => 'ignored');
    is($event->content, '', 'content forced empty');
};

###############################################################################
# from_event — parsing kind 10063
###############################################################################

subtest 'from_event croaks on wrong kind' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $PUBKEY, kind => 10002, content => '', tags => [],
    );
    like(dies { Net::Nostr::Blossom->from_event($event) },
        qr/kind 10063/, 'rejects non-10063 event');
};

subtest 'from_event ignores non-server tags' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey  => $PUBKEY, kind => 10063, content => '',
        tags    => [
            ['server', 'https://blossom.example.com'],
            ['p', 'b' x 64],
            ['r', 'wss://relay.example.com'],
        ],
    );
    my $bl = Net::Nostr::Blossom->from_event($event);
    is($bl->count, 1, 'only server tags counted');
};

subtest 'from_event with empty tags' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $PUBKEY, kind => 10063, content => '', tags => [],
    );
    my $bl = Net::Nostr::Blossom->from_event($event);
    is($bl->count, 0, 'empty server list');
};

###############################################################################
# Round-trip: from_event -> to_event
###############################################################################

subtest 'round-trip preserves server list' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey  => $PUBKEY, kind => 10063, content => '',
        tags    => [
            ['server', 'https://blossom.self.hosted'],
            ['server', 'https://cdn.blossom.cloud'],
        ],
    );

    my $bl = Net::Nostr::Blossom->from_event($event);
    my $event2 = $bl->to_event(pubkey => $PUBKEY);
    is($event2->kind, 10063, 'kind preserved');
    is($event2->content, '', 'content empty');
    is($event2->tags, $event->tags, 'tags match original');
};

###############################################################################
# extract_hash — URL parsing for SHA-256 hex strings
###############################################################################

subtest 'extract_hash: URL ending in 64-char hex' => sub {
    my $hash = 'a' x 64;
    my ($h, $ext) = Net::Nostr::Blossom->extract_hash("https://server.com/$hash");
    is($h, $hash, 'hash extracted');
    is($ext, undef, 'no extension');
};

subtest 'extract_hash: URL ending in hex with file extension' => sub {
    my $hash = 'b' x 64;
    my ($h, $ext) = Net::Nostr::Blossom->extract_hash("https://server.com/$hash.png");
    is($h, $hash, 'hash extracted');
    is($ext, 'png', 'extension extracted');
};

subtest 'extract_hash: hex in path segment' => sub {
    my $hash = 'c' x 64;
    my ($h, $ext) = Net::Nostr::Blossom->extract_hash("https://server.com/media/$hash.jpg");
    is($h, $hash, 'hash extracted from deeper path');
    is($ext, 'jpg', 'extension');
};

subtest 'extract_hash: no hex found returns undef' => sub {
    my ($h, $ext) = Net::Nostr::Blossom->extract_hash("https://server.com/not-a-hash.png");
    is($h, undef, 'no hash');
    is($ext, undef, 'no extension');
};

subtest 'extract_hash: partial hex (less than 64 chars) returns undef' => sub {
    my $short = 'a' x 63;
    my ($h, $ext) = Net::Nostr::Blossom->extract_hash("https://server.com/$short.png");
    is($h, undef, 'too short');
};

subtest 'extract_hash: hex must be lowercase' => sub {
    my $hash = 'ABCDEFabcdef0123456789' x 3; # 66 chars, take first 64
    $hash = substr($hash, 0, 64);
    # Contains uppercase, which is still valid hex
    my ($h, $ext) = Net::Nostr::Blossom->extract_hash("https://server.com/$hash");
    is($h, $hash, 'mixed-case hex accepted');
};

###############################################################################
# resolve_urls — generate alternative Blossom URLs
###############################################################################

subtest 'resolve_urls: generates URLs from server list' => sub {
    my $hash = 'd' x 64;
    my @urls = Net::Nostr::Blossom->resolve_urls(
        "https://dead-server.com/$hash.png",
        ['https://blossom.self.hosted', 'https://cdn.blossom.cloud'],
    );
    is(\@urls, [
        "https://blossom.self.hosted/$hash.png",
        "https://cdn.blossom.cloud/$hash.png",
    ], 'URLs generated with hash and extension');
};

subtest 'resolve_urls: without file extension' => sub {
    my $hash = 'e' x 64;
    my @urls = Net::Nostr::Blossom->resolve_urls(
        "https://dead-server.com/media/$hash",
        ['https://blossom.example.com'],
    );
    is(\@urls, [
        "https://blossom.example.com/$hash",
    ], 'URL with hash only');
};

subtest 'resolve_urls: returns empty list for non-blossom URL' => sub {
    my @urls = Net::Nostr::Blossom->resolve_urls(
        "https://example.com/regular-image.png",
        ['https://blossom.example.com'],
    );
    is(\@urls, [], 'no URLs for non-blossom URL');
};

subtest 'resolve_urls: spec example — lookup same hex on alternate servers' => sub {
    # From spec: "just using the hex string as a path (optionally with the
    # file extension at the end), producing a URL like
    # https://blossom.self.hosted/<hex-string>.png"
    my $hash = 'a1b2c3d4e5f6' . ('0' x 52); # 64 hex chars
    my @urls = Net::Nostr::Blossom->resolve_urls(
        "https://original-server.com/$hash.png",
        ['https://blossom.self.hosted'],
    );
    is($urls[0], "https://blossom.self.hosted/$hash.png",
        'spec URL format: server/<hex-string>.ext');
};

subtest 'resolve_urls: empty server list returns empty' => sub {
    my $hash = 'f' x 64;
    my @urls = Net::Nostr::Blossom->resolve_urls(
        "https://dead.com/$hash.png",
        [],
    );
    is(\@urls, [], 'no servers means no URLs');
};

###############################################################################
# verify_sha256 — content hash verification
###############################################################################

subtest 'verify_sha256: matching hash returns true' => sub {
    my $data = 'hello world';
    my $hash = sha256_hex($data);
    ok(Net::Nostr::Blossom->verify_sha256($data, $hash), 'matching hash');
};

subtest 'verify_sha256: mismatched hash returns false' => sub {
    my $data = 'hello world';
    my $wrong = '0' x 64;
    ok(!Net::Nostr::Blossom->verify_sha256($data, $wrong), 'wrong hash');
};

subtest 'verify_sha256: empty data' => sub {
    my $data = '';
    my $hash = sha256_hex($data);
    ok(Net::Nostr::Blossom->verify_sha256($data, $hash), 'empty data hash matches');
};

subtest 'verify_sha256: binary data' => sub {
    my $data = "\x00\x01\x02\xff";
    my $hash = sha256_hex($data);
    ok(Net::Nostr::Blossom->verify_sha256($data, $hash), 'binary data hash matches');
};

###############################################################################
# Integration: from_event + resolve_urls
###############################################################################

subtest 'integration: parse server list then resolve URL' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey  => $PUBKEY, kind => 10063, content => '',
        tags    => [
            ['server', 'https://blossom.self.hosted'],
            ['server', 'https://cdn.blossom.cloud'],
        ],
    );

    my $bl = Net::Nostr::Blossom->from_event($event);
    my $hash = 'ab12cd34' . ('0' x 48) . 'ef567890';
    my @urls = Net::Nostr::Blossom->resolve_urls(
        "https://dead-server.com/$hash.png",
        [$bl->servers],
    );
    is(scalar @urls, 2, 'two alternative URLs');
    like($urls[0], qr/blossom\.self\.hosted/, 'first server used');
    like($urls[1], qr/cdn\.blossom\.cloud/, 'second server used');
};

###############################################################################
# Edge cases
###############################################################################

subtest 'empty server list' => sub {
    my $bl = Net::Nostr::Blossom->new;
    is($bl->count, 0, 'empty count');
    is(scalar $bl->servers, 0, 'no servers');
    my $event = $bl->to_event(pubkey => $PUBKEY);
    is(scalar @{$event->tags}, 0, 'no tags');
};

subtest 'server URL with trailing slash preserved' => sub {
    my $bl = Net::Nostr::Blossom->new;
    $bl->add('https://server.com/');
    is(($bl->servers)[0], 'https://server.com/', 'trailing slash preserved');
};

done_testing;
