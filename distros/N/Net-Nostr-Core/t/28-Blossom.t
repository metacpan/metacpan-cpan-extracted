#!/usr/bin/perl

# Unit tests for Net::Nostr::Blossom
# Tests every code example in the POD

use strictures 2;

use Test2::V0 -no_srand => 1;
use Digest::SHA qw(sha256_hex);

use Net::Nostr::Blossom;
use Net::Nostr::Event;

my $pubkey = '781208004e09102d7da3b7345e64fd193cd1bc3fce8fdae6008d77f9cabcd036';

sub server_list_event {
    my ($tags) = @_;
    return Net::Nostr::Event->new(
        pubkey  => $pubkey,
        kind    => 10063,
        content => '',
        tags    => $tags,
    );
}

###############################################################################
# SYNOPSIS examples
###############################################################################

subtest 'SYNOPSIS: build a server list' => sub {
    my $bl = Net::Nostr::Blossom->new(
        servers => [
            'https://blossom.self.hosted',
            'https://cdn.blossom.cloud',
        ],
    );

    is([$bl->servers], [
        'https://blossom.self.hosted',
        'https://cdn.blossom.cloud',
    ], 'servers are ordered');
    is($bl->primary_server, 'https://blossom.self.hosted', 'primary server');
};

subtest 'SYNOPSIS: create event for publishing' => sub {
    my $bl = Net::Nostr::Blossom->new(
        servers => [
            'https://blossom.self.hosted',
            'https://cdn.blossom.cloud',
        ],
    );

    my $event = $bl->to_event(pubkey => $pubkey);
    is($event->kind, 10063, 'kind 10063');
    is($event->content, '', 'content is empty');
};

subtest 'SYNOPSIS: parse from event' => sub {
    my $event = server_list_event([
        ['server', 'https://blossom.self.hosted'],
        ['server', 'https://cdn.blossom.cloud'],
    ]);

    my $bl = Net::Nostr::Blossom->from_event($event);
    is([$bl->servers], [
        'https://blossom.self.hosted',
        'https://cdn.blossom.cloud',
    ], 'server tags parsed in order');
};

subtest 'SYNOPSIS: extract hash from URL' => sub {
    my $hash = 'a' x 64;
    my ($h, $ext) = Net::Nostr::Blossom->extract_hash(
        "https://old-server.com/$hash.png"
    );

    is($h, $hash, 'hash extracted');
    is($ext, 'png', 'extension extracted');
};

subtest 'SYNOPSIS: generate fallback URLs' => sub {
    my $hash = 'a' x 64;
    my $bl = Net::Nostr::Blossom->new(
        servers => [
            'https://blossom.self.hosted',
            'https://cdn.blossom.cloud',
        ],
    );

    my @urls = $bl->fallback_urls("https://dead-server.com/$hash.png");
    is(\@urls, [
        "https://blossom.self.hosted/$hash.png",
        "https://cdn.blossom.cloud/$hash.png",
    ], 'fallback URLs preserve server order');
};

subtest 'SYNOPSIS: verify downloaded content' => sub {
    my $data = 'file contents';
    my $expected_hash = sha256_hex($data);
    ok(Net::Nostr::Blossom->verify_sha256($data, $expected_hash), 'hash matches');
};

###############################################################################
# Constructor and accessors
###############################################################################

subtest 'new() rejects unknown arguments' => sub {
    like(
        dies { Net::Nostr::Blossom->new(bogus => 'value') },
        qr/unknown.+bogus/i,
        'unknown argument rejected'
    );
};

subtest 'new() requires servers to be an arrayref when provided' => sub {
    like(
        dies { Net::Nostr::Blossom->new(servers => 'https://example.com') },
        qr/servers must be an arrayref/i,
        'non-array servers rejected'
    );
};

subtest 'constructor copies server input and preserves duplicates' => sub {
    my $servers = [
        'https://blossom.example.com',
        'https://blossom.example.com',
        'https://cdn.example.com/path',
    ];
    my $bl = Net::Nostr::Blossom->new(servers => $servers);

    $servers->[0] = 'https://mutated.example.com';

    is([$bl->servers], [
        'https://blossom.example.com',
        'https://blossom.example.com',
        'https://cdn.example.com/path',
    ], 'constructor preserves order and duplicates without sharing input');
};

subtest 'servers returns a non-mutating copy in scalar context' => sub {
    my $bl = Net::Nostr::Blossom->new(
        servers => ['https://one.example.com', 'https://two.example.com'],
    );

    my $servers = $bl->servers;
    $servers->[0] = 'https://changed.example.com';

    is([$bl->servers], [
        'https://one.example.com',
        'https://two.example.com',
    ], 'returned arrayref does not mutate object');
};

subtest 'primary_server returns undef for an empty list' => sub {
    my $bl = Net::Nostr::Blossom->new;
    is($bl->primary_server, undef, 'no primary server');
};

###############################################################################
# Event helpers
###############################################################################

subtest 'from_event POD example' => sub {
    my $event = server_list_event([
        ['server', 'https://blossom.example.com'],
    ]);

    my $bl = Net::Nostr::Blossom->from_event($event);
    is([$bl->servers], ['https://blossom.example.com'], 'one server');
};

subtest 'from_event rejects plain hashrefs' => sub {
    like(
        dies {
            Net::Nostr::Blossom->from_event({
                kind => 10063,
                tags => [['server', 'https://blossom.example.com']],
            });
        },
        qr/Net::Nostr::Event/i,
        'hashref is not accepted'
    );
};

subtest 'server_tags returns non-mutating tag arrays' => sub {
    my $bl = Net::Nostr::Blossom->new(
        servers => ['https://blossom.self.hosted', 'https://cdn.blossom.cloud'],
    );

    my $tags = $bl->server_tags;
    $tags->[0][1] = 'https://changed.example.com';

    is($bl->server_tags, [
        ['server', 'https://blossom.self.hosted'],
        ['server', 'https://cdn.blossom.cloud'],
    ], 'tag arrays are copied');
};

subtest 'to_event creates kind 10063 with ordered server tags' => sub {
    my $bl = Net::Nostr::Blossom->new(
        servers => ['https://blossom.example.com'],
    );

    my $event = $bl->to_event(pubkey => $pubkey, content => 'ignored');
    is($event->kind, 10063, 'kind 10063');
    is($event->content, '', 'empty content forced');
    is($event->tags, [
        ['server', 'https://blossom.example.com'],
    ], 'ordered server tag');
};

subtest 'to_event rejects empty server lists' => sub {
    my $bl = Net::Nostr::Blossom->new;
    like(
        dies { $bl->to_event(pubkey => $pubkey) },
        qr/at least one server/i,
        'empty server list cannot produce BUD-03 event'
    );
};

###############################################################################
# URL hash and fallback helpers
###############################################################################

subtest 'extract_hash returns undef pair when no hash exists' => sub {
    my ($hash, $ext) = Net::Nostr::Blossom->extract_hash(
        'https://server.com/not-a-hash.png'
    );

    is($hash, undef, 'no hash');
    is($ext, undef, 'no extension');
};

subtest 'fallback_urls strips server trailing slash only in generated URL' => sub {
    my $hash = 'b' x 64;
    my $bl = Net::Nostr::Blossom->new(
        servers => ['https://blossom.self.hosted/', 'https://cdn.blossom.cloud/base/'],
    );

    is([$bl->fallback_urls("https://unavailable.com/$hash.jpg")], [
        "https://blossom.self.hosted/$hash.jpg",
        "https://cdn.blossom.cloud/base/$hash.jpg",
    ], 'fallback URLs use normalized base separator');

    is([$bl->servers], [
        'https://blossom.self.hosted/',
        'https://cdn.blossom.cloud/base/',
    ], 'stored server URLs are unchanged');
};

subtest 'fallback_urls returns empty list without a hash' => sub {
    my $bl = Net::Nostr::Blossom->new(
        servers => ['https://blossom.example.com'],
    );

    is([$bl->fallback_urls('https://example.com/regular-image.png')], [],
        'no hash means no fallback URLs');
};

###############################################################################
# SHA-256 verification
###############################################################################

subtest 'verify_sha256 POD example' => sub {
    my $data = 'file contents';
    my $hash = sha256_hex($data);

    ok(Net::Nostr::Blossom->verify_sha256($data, $hash), 'valid');
    ok(!Net::Nostr::Blossom->verify_sha256('tampered', $hash), 'tampered');
};

subtest 'verify_sha256 rejects malformed expected hashes' => sub {
    like(
        dies { Net::Nostr::Blossom->verify_sha256('data', 'abc') },
        qr/expected hash must be 64-char hex/i,
        'short expected hash rejected'
    );
};

done_testing;
