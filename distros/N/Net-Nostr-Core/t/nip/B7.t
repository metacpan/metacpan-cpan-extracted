#!/usr/bin/perl

# NIP-B7 / BUD-03 conformance tests: Blossom media server lists

use strictures 2;

use Test2::V0 -no_srand => 1;
use Digest::SHA qw(sha256_hex);

use Net::Nostr::Blossom;
use Net::Nostr::Event;

my $PUBKEY = '781208004e09102d7da3b7345e64fd193cd1bc3fce8fdae6008d77f9cabcd036';
my $AUTHOR = 'ec4425ff5e9446080d2f70440188e3ca5d6da8713db7bdeef73d0ed54d9093f0';
my $BUD_HASH = 'b1674191a88ec5cdd733e4240a81803105dc412d6c6708d53ab94fc248f4f553';

sub event_with_tags {
    my ($tags) = @_;
    return Net::Nostr::Event->new(
        pubkey  => $PUBKEY,
        kind    => 10063,
        content => '',
        tags    => $tags,
    );
}

sub malformed_event {
    my (%fields) = @_;
    return bless {
        pubkey     => $PUBKEY,
        kind       => 10063,
        content    => '',
        created_at => 1708774162,
        tags       => [],
        %fields,
    }, 'Net::Nostr::Event';
}

###############################################################################
# Kind 10063 - replaceable event with server tags
###############################################################################

subtest 'kind 10063 is replaceable' => sub {
    my $event = event_with_tags([
        ['server', 'https://blossom.self.hosted'],
    ]);
    ok($event->is_replaceable, 'kind 10063 is replaceable');
};

###############################################################################
# Spec examples
###############################################################################

subtest 'NIP-B7 example: kind 10063 with server tags' => sub {
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
    is([$bl->servers], [
        'https://blossom.self.hosted',
        'https://cdn.blossom.cloud',
    ], 'two servers in order');
    is($bl->primary_server, 'https://blossom.self.hosted', 'first server is primary');
};

subtest 'BUD-03 example: server tag order is preserved' => sub {
    my $event = event_with_tags([
        ['server', 'https://cdn.self.hosted'],
        ['server', 'https://cdn.satellite.earth'],
    ]);

    my $bl = Net::Nostr::Blossom->from_event($event);
    is([$bl->servers], [
        'https://cdn.self.hosted',
        'https://cdn.satellite.earth',
    ], 'BUD-03 reliable/trusted order preserved');
};

###############################################################################
# Server list construction and exposure
###############################################################################

subtest 'constructor accepts ordered server lists' => sub {
    my $bl = Net::Nostr::Blossom->new(
        servers => [
            'https://first.example.com',
            'http://second.example.com/base',
            'https://third.example.com/',
        ],
    );

    is([$bl->servers], [
        'https://first.example.com',
        'http://second.example.com/base',
        'https://third.example.com/',
    ], 'constructor order preserved');
};

subtest 'duplicates are preserved' => sub {
    my $bl = Net::Nostr::Blossom->new(
        servers => [
            'https://dup.example.com',
            'https://dup.example.com',
            'https://other.example.com',
        ],
    );

    is([$bl->servers], [
        'https://dup.example.com',
        'https://dup.example.com',
        'https://other.example.com',
    ], 'duplicate server tags are retained');
    is($bl->server_tags, [
        ['server', 'https://dup.example.com'],
        ['server', 'https://dup.example.com'],
        ['server', 'https://other.example.com'],
    ], 'duplicate server tags serialize');
};

subtest 'servers returns copies, not mutable internals' => sub {
    my $bl = Net::Nostr::Blossom->new(
        servers => ['https://one.example.com', 'https://two.example.com'],
    );

    my $servers = $bl->servers;
    $servers->[1] = 'https://changed.example.com';

    my @servers = $bl->servers;
    $servers[0] = 'https://changed-again.example.com';

    is([$bl->servers], [
        'https://one.example.com',
        'https://two.example.com',
    ], 'object server order is unchanged');
};

###############################################################################
# Server URL validation
###############################################################################

subtest 'server URL validation accepts strict HTTP(S) base URLs' => sub {
    my @valid = (
        'https://blossom.example.com',
        'http://blossom.example.com',
        'https://blossom.example.com/base/path',
        'https://blossom.example.com/',
        'https://blossom.example.com:1',
        'https://blossom.example.com:65535',
        'https://[2001:db8::1]/blossom',
        'https://[2001:db8::1]:443/blossom',
    );

    for my $url (@valid) {
        ok(lives { Net::Nostr::Blossom->new(servers => [$url]) }, "accepted $url");
    }
};

subtest 'server URL validation rejects malformed or non-base URLs' => sub {
    my @invalid = (
        [undef, 'missing URL'],
        ['ftp://blossom.example.com', 'non-http scheme'],
        ['https:///blossom', 'missing host'],
        ['https://user@blossom.example.com', 'userinfo'],
        ['https://blossom.example.com?x=1', 'query'],
        ['https://blossom.example.com#frag', 'fragment'],
        ["https://blossom.example.com/a b", 'space'],
        ["https://blossom.example.com/\npath", 'control'],
        ['https://blossom.example.com:0', 'port 0'],
        ['https://blossom.example.com:65536', 'port 65536'],
        ['https://blossom.example.com:', 'empty port'],
        ['https://blossom.example.com:abc', 'nonnumeric port'],
    );

    for my $case (@invalid) {
        my ($url, $name) = @$case;
        like(
            dies { Net::Nostr::Blossom->new(servers => [$url]) },
            qr/server url/i,
            "$name rejected"
        );
    }
};

###############################################################################
# Event parsing and building
###############################################################################

subtest 'from_event rejects missing and wrong event values' => sub {
    like(
        dies { Net::Nostr::Blossom->from_event() },
        qr/event is required/i,
        'missing event rejected'
    );

    like(
        dies { Net::Nostr::Blossom->from_event({ kind => 10063, tags => [] }) },
        qr/Net::Nostr::Event/i,
        'plain hashref rejected'
    );
};

subtest 'from_event rejects wrong or malformed kind' => sub {
    my $wrong_kind = Net::Nostr::Event->new(
        pubkey => $PUBKEY, kind => 10002, content => '', tags => [],
    );

    like(
        dies { Net::Nostr::Blossom->from_event($wrong_kind) },
        qr/kind 10063/i,
        'wrong kind rejected'
    );

    like(
        dies { Net::Nostr::Blossom->from_event(malformed_event(kind => '10063abc')) },
        qr/kind 10063/i,
        'malformed kind rejected'
    );
};

subtest 'from_event rejects malformed tags' => sub {
    like(
        dies { Net::Nostr::Blossom->from_event(malformed_event(tags => 'bad')) },
        qr/tags must be an arrayref/i,
        'non-array tags rejected'
    );

    like(
        dies { Net::Nostr::Blossom->from_event(malformed_event(tags => ['bad'])) },
        qr/each tag must be an arrayref/i,
        'non-array tag rejected'
    );
};

subtest 'from_event extracts server tags in order and ignores other tags' => sub {
    my $event = event_with_tags([
        ['p', 'b' x 64],
        ['server', 'https://blossom.self.hosted'],
        ['r', 'wss://relay.example.com'],
        ['server', 'https://cdn.blossom.cloud'],
    ]);

    my $bl = Net::Nostr::Blossom->from_event($event);
    is([$bl->servers], [
        'https://blossom.self.hosted',
        'https://cdn.blossom.cloud',
    ], 'only server tags extracted');
};

subtest 'from_event rejects missing or invalid server tag URLs' => sub {
    like(
        dies { Net::Nostr::Blossom->from_event(event_with_tags([['server']])) },
        qr/server tag requires a URL/i,
        'missing URL rejected'
    );

    like(
        dies { Net::Nostr::Blossom->from_event(event_with_tags([['server', 'wss://relay.example.com']])) },
        qr/server url/i,
        'invalid server URL rejected'
    );
};

subtest 'from_event rejects events with no valid server tags' => sub {
    like(
        dies { Net::Nostr::Blossom->from_event(event_with_tags([])) },
        qr/at least one server/i,
        'empty tag list rejected'
    );

    like(
        dies { Net::Nostr::Blossom->from_event(event_with_tags([['p', 'b' x 64]])) },
        qr/at least one server/i,
        'non-server-only tag list rejected'
    );
};

subtest 'to_event builds kind 10063 events with empty content and ordered server tags' => sub {
    my $bl = Net::Nostr::Blossom->new(
        servers => [
            'https://blossom.self.hosted',
            'https://cdn.blossom.cloud',
        ],
    );

    my $event = $bl->to_event(
        pubkey     => $PUBKEY,
        created_at => 1708774162,
        kind       => 1,
        content    => 'ignored',
        tags       => [['p', 'b' x 64]],
    );

    is($event->kind, 10063, 'kind forced to 10063');
    is($event->content, '', 'content forced empty');
    is($event->created_at, 1708774162, 'created_at passed through');
    is($event->tags, [
        ['server', 'https://blossom.self.hosted'],
        ['server', 'https://cdn.blossom.cloud'],
    ], 'ordered server tags');
};

subtest 'round-trip preserves server tags' => sub {
    my $event = event_with_tags([
        ['server', 'https://blossom.self.hosted'],
        ['server', 'https://cdn.blossom.cloud'],
    ]);

    my $bl = Net::Nostr::Blossom->from_event($event);
    my $event2 = $bl->to_event(pubkey => $PUBKEY);

    is($event2->kind, 10063, 'kind preserved');
    is($event2->content, '', 'content empty');
    is($event2->tags, $event->tags, 'tags match original');
};

###############################################################################
# Hash extraction
###############################################################################

subtest 'extract_hash follows BUD-03 examples' => sub {
    my @cases = (
        ["https://blossom.example.com/$BUD_HASH.pdf", $BUD_HASH, 'pdf', 'Blossom URL with extension'],
        ["https://cdn.example.com/$BUD_HASH", $BUD_HASH, undef, 'Blossom URL without extension'],
        ["https://cdn.example.com/user/$AUTHOR/media/$BUD_HASH.pdf", $BUD_HASH, 'pdf', 'last hash wins in author path'],
        ["http://media.example.com/documents/b1/67/$BUD_HASH.pdf", $BUD_HASH, 'pdf', 'nested path hash'],
    );

    for my $case (@cases) {
        my ($url, $want_hash, $want_ext, $name) = @$case;
        my ($hash, $ext) = Net::Nostr::Blossom->extract_hash($url);
        is($hash, $want_hash, "$name hash");
        is($ext, $want_ext, "$name extension");
    }
};

subtest 'extract_hash normalizes hash and preserves extension' => sub {
    my $upper = uc $BUD_HASH;
    my ($hash, $ext) = Net::Nostr::Blossom->extract_hash(
        "https://cdn.example.com/$upper.PDF?download=1"
    );

    is($hash, $BUD_HASH, 'hash lowercased');
    is($ext, 'PDF', 'extension case preserved before query');
};

subtest 'extract_hash allows extension before fragment' => sub {
    my ($hash, $ext) = Net::Nostr::Blossom->extract_hash(
        "https://cdn.example.com/$BUD_HASH.pdf#section"
    );

    is($hash, $BUD_HASH, 'hash extracted');
    is($ext, 'pdf', 'extension before fragment preserved');
};

subtest 'extract_hash captures extension only at path end' => sub {
    my @cases = (
        ["https://cdn.example.com/$BUD_HASH.pdf", 'pdf', 'extension before end'],
        ["https://cdn.example.com/$BUD_HASH.pdf?x=1", 'pdf', 'extension before query'],
        ["https://cdn.example.com/$BUD_HASH.pdf#frag", 'pdf', 'extension before fragment'],
        ["https://cdn.example.com/$BUD_HASH.pdf/more", undef, 'extension before path segment ignored'],
        ["https://cdn.example.com/$BUD_HASH.pdfmore/path", undef, 'extension-like path prefix ignored'],
    );

    for my $case (@cases) {
        my ($url, $want_ext, $name) = @$case;
        my ($hash, $ext) = Net::Nostr::Blossom->extract_hash($url);
        is($hash, $BUD_HASH, "$name hash");
        is($ext, $want_ext, "$name extension");
    }
};

subtest 'extract_hash does not extract from longer hex runs' => sub {
    my @invalid = (
        'https://cdn.example.com/' . ('a' x 65),
        'https://cdn.example.com/0' . $BUD_HASH,
        'https://cdn.example.com/' . $BUD_HASH . '0',
    );

    for my $url (@invalid) {
        my ($hash, $ext) = Net::Nostr::Blossom->extract_hash($url);
        is($hash, undef, "$url has no bounded hash");
        is($ext, undef, "$url has no extension");
    }
};

subtest 'extract_hash returns the last bounded 64-char hex string' => sub {
    my $first = 'a' x 64;
    my $last  = 'b' x 64;

    my ($hash, $ext) = Net::Nostr::Blossom->extract_hash(
        "https://cdn.example.com/user/$first/media/$last.png"
    );

    is($hash, $last, 'last hash selected');
    is($ext, 'png', 'last hash extension selected');
};

subtest 'extract_hash returns undef pair when no hash exists' => sub {
    my ($hash, $ext) = Net::Nostr::Blossom->extract_hash(
        'https://cdn.example.com/media/not-a-hash.pdf'
    );

    is($hash, undef, 'no hash');
    is($ext, undef, 'no extension');
};

###############################################################################
# Fallback URL generation
###############################################################################

subtest 'fallback_urls uses ordered servers and extracted hash' => sub {
    my $bl = Net::Nostr::Blossom->new(
        servers => [
            'https://blossom.self.hosted',
            'https://cdn.blossom.cloud/base/',
        ],
    );

    is([$bl->fallback_urls("https://original.example.com/$BUD_HASH.pdf")], [
        "https://blossom.self.hosted/$BUD_HASH.pdf",
        "https://cdn.blossom.cloud/base/$BUD_HASH.pdf",
    ], 'fallback URLs preserve order and extension');
};

subtest 'fallback_urls lowercases hash and returns empty without a hash' => sub {
    my $bl = Net::Nostr::Blossom->new(
        servers => ['https://blossom.example.com'],
    );

    is([$bl->fallback_urls('https://original.example.com/' . uc($BUD_HASH) . '.pdf')], [
        "https://blossom.example.com/$BUD_HASH.pdf",
    ], 'hash normalized in fallback URL');

    is([$bl->fallback_urls('https://original.example.com/file.pdf')], [],
        'no hash returns no fallback URLs');
};

###############################################################################
# SHA-256 verification
###############################################################################

subtest 'verify_sha256 compares content to expected 64-char hash' => sub {
    my $data = "hello world";
    my $hash = sha256_hex($data);

    ok(Net::Nostr::Blossom->verify_sha256($data, $hash), 'matching hash');
    ok(!Net::Nostr::Blossom->verify_sha256($data, '0' x 64), 'mismatched hash');
    ok(Net::Nostr::Blossom->verify_sha256($data, uc $hash), 'uppercase expected hash accepted');
};

subtest 'verify_sha256 rejects invalid expected hashes' => sub {
    for my $bad (undef, 'abc', 'g' x 64, 'a' x 65) {
        like(
            dies { Net::Nostr::Blossom->verify_sha256('data', $bad) },
            qr/expected hash must be 64-char hex/i,
            'invalid expected hash rejected'
        );
    }
};

done_testing;
