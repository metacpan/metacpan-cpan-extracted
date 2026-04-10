#!/usr/bin/perl

# Unit tests for Net::Nostr::Identifier

use strictures 2;

use Test2::V0 -no_srand => 1;

use Net::Nostr::Identifier;

###############################################################################
# Constructor and accessors
###############################################################################

subtest 'new creates identifier object' => sub {
    my $ident = Net::Nostr::Identifier->new;
    isa_ok($ident, 'Net::Nostr::Identifier');
};

subtest 'base_url accessor' => sub {
    my $ident = Net::Nostr::Identifier->new(base_url => 'http://localhost:8080');
    is $ident->base_url, 'http://localhost:8080', 'base_url set';

    my $default = Net::Nostr::Identifier->new;
    is $default->base_url, undef, 'base_url defaults to undef';
};

###############################################################################
# parse
###############################################################################

subtest 'parse requires a defined identifier' => sub {
    like dies { Net::Nostr::Identifier->parse(undef) },
        qr/invalid/i, 'undef rejected';
};

subtest 'parse returns list context' => sub {
    my @result = Net::Nostr::Identifier->parse('alice@relay.example.com');
    is scalar @result, 2, 'returns two values';
    is $result[0], 'alice', 'local-part';
    is $result[1], 'relay.example.com', 'domain';
};

###############################################################################
# url
###############################################################################

subtest 'url croaks on invalid identifier' => sub {
    like dies { Net::Nostr::Identifier->url('INVALID') },
        qr/invalid/i, 'invalid identifier rejected';
};

###############################################################################
# display_name
###############################################################################

subtest 'display_name croaks on invalid identifier' => sub {
    like dies { Net::Nostr::Identifier->display_name('!!!') },
        qr/invalid/i, 'invalid identifier rejected';
};

###############################################################################
# verify required arguments
###############################################################################

subtest 'verify croaks without identifier' => sub {
    my $ident = Net::Nostr::Identifier->new;
    like dies {
        $ident->verify(
            pubkey     => 'a' x 64,
            on_success => sub {},
            on_failure => sub {},
        )
    }, qr/identifier required/i, 'missing identifier';
};

subtest 'verify croaks without pubkey' => sub {
    my $ident = Net::Nostr::Identifier->new;
    like dies {
        $ident->verify(
            identifier => 'bob@example.com',
            on_success => sub {},
            on_failure => sub {},
        )
    }, qr/pubkey required/i, 'missing pubkey';
};

subtest 'verify croaks without on_success' => sub {
    my $ident = Net::Nostr::Identifier->new;
    like dies {
        $ident->verify(
            identifier => 'bob@example.com',
            pubkey     => 'a' x 64,
            on_failure => sub {},
        )
    }, qr/on_success/i, 'missing on_success';
};

subtest 'verify croaks without on_failure' => sub {
    my $ident = Net::Nostr::Identifier->new;
    like dies {
        $ident->verify(
            identifier => 'bob@example.com',
            pubkey     => 'a' x 64,
            on_success => sub {},
        )
    }, qr/on_failure/i, 'missing on_failure';
};

###############################################################################
# lookup required arguments
###############################################################################

subtest 'lookup croaks without identifier' => sub {
    my $ident = Net::Nostr::Identifier->new;
    like dies {
        $ident->lookup(
            on_success => sub {},
            on_failure => sub {},
        )
    }, qr/identifier required/i, 'missing identifier';
};

subtest 'lookup croaks without on_success' => sub {
    my $ident = Net::Nostr::Identifier->new;
    like dies {
        $ident->lookup(
            identifier => 'bob@example.com',
            on_failure => sub {},
        )
    }, qr/on_success/i, 'missing on_success';
};

subtest 'lookup croaks without on_failure' => sub {
    my $ident = Net::Nostr::Identifier->new;
    like dies {
        $ident->lookup(
            identifier => 'bob@example.com',
            on_success => sub {},
        )
    }, qr/on_failure/i, 'missing on_failure';
};

###############################################################################
# callback type validation
###############################################################################

subtest 'verify croaks if on_success is not a code ref' => sub {
    my $ident = Net::Nostr::Identifier->new;
    like dies {
        $ident->verify(
            identifier => 'bob@example.com',
            pubkey     => 'a' x 64,
            on_success => 'not a sub',
            on_failure => sub {},
        )
    }, qr/on_success.*code/i, 'string on_success rejected';
    like dies {
        $ident->verify(
            identifier => 'bob@example.com',
            pubkey     => 'a' x 64,
            on_success => [1, 2],
            on_failure => sub {},
        )
    }, qr/on_success.*code/i, 'arrayref on_success rejected';
};

subtest 'verify croaks if on_failure is not a code ref' => sub {
    my $ident = Net::Nostr::Identifier->new;
    like dies {
        $ident->verify(
            identifier => 'bob@example.com',
            pubkey     => 'a' x 64,
            on_success => sub {},
            on_failure => 'not a sub',
        )
    }, qr/on_failure.*code/i, 'string on_failure rejected';
};

subtest 'lookup croaks if on_success is not a code ref' => sub {
    my $ident = Net::Nostr::Identifier->new;
    like dies {
        $ident->lookup(
            identifier => 'bob@example.com',
            on_success => { hash => 1 },
            on_failure => sub {},
        )
    }, qr/on_success.*code/i, 'hashref on_success rejected';
};

subtest 'lookup croaks if on_failure is not a code ref' => sub {
    my $ident = Net::Nostr::Identifier->new;
    like dies {
        $ident->lookup(
            identifier => 'bob@example.com',
            on_success => sub {},
            on_failure => 42,
        )
    }, qr/on_failure.*code/i, 'numeric on_failure rejected';
};

###############################################################################
# parse: domain validation
###############################################################################

subtest 'parse rejects domain with whitespace' => sub {
    like dies { Net::Nostr::Identifier->parse('bob@ example.com') },
        qr/invalid.*domain/i, 'space in domain rejected';
    like dies { Net::Nostr::Identifier->parse("bob\@example\t.com") },
        qr/invalid.*domain/i, 'tab in domain rejected';
    like dies { Net::Nostr::Identifier->parse("bob\@example\n.com") },
        qr/invalid.*domain/i, 'newline in domain rejected';
};

subtest 'parse rejects domain with URL-unsafe characters' => sub {
    like dies { Net::Nostr::Identifier->parse('bob@example.com/path') },
        qr/invalid.*domain/i, 'slash in domain rejected';
    like dies { Net::Nostr::Identifier->parse('bob@example.com?query') },
        qr/invalid.*domain/i, 'question mark in domain rejected';
    like dies { Net::Nostr::Identifier->parse('bob@example.com#frag') },
        qr/invalid.*domain/i, 'hash in domain rejected';
};

subtest 'parse rejects domain with colon (port)' => sub {
    like dies { Net::Nostr::Identifier->parse('bob@example.com:8080') },
        qr/invalid.*domain/i, 'colon in domain rejected';
};

subtest 'parse rejects bracketed IPv6' => sub {
    like dies { Net::Nostr::Identifier->parse('bob@[::1]') },
        qr/invalid.*domain/i, 'bracketed IPv6 rejected';
};

subtest 'parse rejects domain with control characters' => sub {
    like dies { Net::Nostr::Identifier->parse("bob\@example\x00.com") },
        qr/invalid.*domain/i, 'null byte in domain rejected';
    like dies { Net::Nostr::Identifier->parse("bob\@example\x7f.com") },
        qr/invalid.*domain/i, 'DEL in domain rejected';
};

subtest 'parse accepts valid domains' => sub {
    my ($l, $d) = Net::Nostr::Identifier->parse('bob@example.com');
    is $d, 'example.com', 'simple domain';

    ($l, $d) = Net::Nostr::Identifier->parse('bob@sub.example.com');
    is $d, 'sub.example.com', 'subdomain';

    ($l, $d) = Net::Nostr::Identifier->parse('bob@example.co.uk');
    is $d, 'example.co.uk', 'multi-label TLD';

    ($l, $d) = Net::Nostr::Identifier->parse('bob@123.456.789.0');
    is $d, '123.456.789.0', 'numeric/IP-like domain';

    ($l, $d) = Net::Nostr::Identifier->parse('bob@my-relay.example.com');
    is $d, 'my-relay.example.com', 'hyphenated domain';
};

###############################################################################
# new() POD example
###############################################################################

subtest 'new() POD example' => sub {
    my $ident = Net::Nostr::Identifier->new(
        base_url => 'http://localhost:9999',
    );
    is $ident->base_url, 'http://localhost:9999';
};

subtest 'new() rejects unknown arguments' => sub {
    like(
        dies { Net::Nostr::Identifier->new(bogus => 'value') },
        qr/unknown.+bogus/i,
        'unknown argument rejected'
    );
};

###############################################################################
# parse: local-part validation
###############################################################################

subtest 'parse: rejects missing @' => sub {
    like dies { Net::Nostr::Identifier->parse('bobexample.com') },
        qr/missing.*\@/i, 'no @ rejected';
};

subtest 'parse: rejects multiple @' => sub {
    like dies { Net::Nostr::Identifier->parse('bob@relay@example.com') },
        qr/multiple.*\@/i, 'multiple @ rejected';
};

subtest 'parse: rejects empty local-part' => sub {
    like dies { Net::Nostr::Identifier->parse('@example.com') },
        qr/empty local/i, 'empty local-part rejected';
};

subtest 'parse: rejects empty domain' => sub {
    like dies { Net::Nostr::Identifier->parse('bob@') },
        qr/empty domain/i, 'empty domain rejected';
};

subtest 'parse: rejects uppercase local-part' => sub {
    like dies { Net::Nostr::Identifier->parse('Bob@example.com') },
        qr/invalid.*local/i, 'uppercase local-part rejected';
};

subtest 'parse: rejects special chars in local-part' => sub {
    like dies { Net::Nostr::Identifier->parse('bob!@example.com') },
        qr/invalid.*local/i, '! in local-part rejected';
    like dies { Net::Nostr::Identifier->parse('bob @example.com') },
        qr/invalid.*local/i, 'space in local-part rejected';
};

subtest 'parse: accepts valid local-parts' => sub {
    my ($l, $d) = Net::Nostr::Identifier->parse('alice@example.com');
    is $l, 'alice', 'simple name';
    ($l, $d) = Net::Nostr::Identifier->parse('_@example.com');
    is $l, '_', 'underscore (root identifier)';
    ($l, $d) = Net::Nostr::Identifier->parse('bob-smith@example.com');
    is $l, 'bob-smith', 'hyphenated';
    ($l, $d) = Net::Nostr::Identifier->parse('user.name@example.com');
    is $l, 'user.name', 'dotted';
    ($l, $d) = Net::Nostr::Identifier->parse('user123@example.com');
    is $l, 'user123', 'with digits';
};

###############################################################################
# url: positive tests
###############################################################################

subtest 'url: returns well-known URL' => sub {
    is(Net::Nostr::Identifier->url('alice@example.com'),
        'https://example.com/.well-known/nostr.json?name=alice',
        'standard URL');
    is(Net::Nostr::Identifier->url('_@relay.example.com'),
        'https://relay.example.com/.well-known/nostr.json?name=_',
        'root identifier URL');
};

###############################################################################
# display_name
###############################################################################

subtest 'display_name: root identifier shows domain only' => sub {
    is(Net::Nostr::Identifier->display_name('_@example.com'),
        'example.com', 'root shows domain');
};

subtest 'display_name: non-root shows full identifier' => sub {
    is(Net::Nostr::Identifier->display_name('alice@example.com'),
        'alice@example.com', 'non-root shows full');
};

###############################################################################
# verify_response
###############################################################################

my $test_pk  = 'ab' x 32;
my $other_pk = 'cd' x 32;

subtest 'verify_response: returns 1 on match' => sub {
    my $response = { names => { alice => $test_pk } };
    is(Net::Nostr::Identifier->verify_response($response, 'alice', $test_pk),
        1, 'matching pubkey returns 1');
};

subtest 'verify_response: returns 0 on pubkey mismatch' => sub {
    my $response = { names => { alice => $other_pk } };
    is(Net::Nostr::Identifier->verify_response($response, 'alice', $test_pk),
        0, 'different pubkey returns 0');
};

subtest 'verify_response: returns 0 when name not found' => sub {
    my $response = { names => { bob => $test_pk } };
    is(Net::Nostr::Identifier->verify_response($response, 'alice', $test_pk),
        0, 'missing name returns 0');
};

subtest 'verify_response: returns 0 for non-HASH response' => sub {
    is(Net::Nostr::Identifier->verify_response('string', 'alice', $test_pk),
        0, 'string response');
    is(Net::Nostr::Identifier->verify_response(undef, 'alice', $test_pk),
        0, 'undef response');
    is(Net::Nostr::Identifier->verify_response([], 'alice', $test_pk),
        0, 'arrayref response');
};

subtest 'verify_response: returns 0 when names is not a HASH' => sub {
    is(Net::Nostr::Identifier->verify_response({ names => 'bad' }, 'alice', $test_pk),
        0, 'string names');
    is(Net::Nostr::Identifier->verify_response({ names => [] }, 'alice', $test_pk),
        0, 'arrayref names');
    is(Net::Nostr::Identifier->verify_response({}, 'alice', $test_pk),
        0, 'missing names key');
};

subtest 'verify_response: rejects invalid hex pubkey in response' => sub {
    my $response = { names => { alice => 'ZZZZ' } };
    is(Net::Nostr::Identifier->verify_response($response, 'alice', 'ZZZZ'),
        0, 'non-hex rejected');
    $response = { names => { alice => 'AB' x 32 } };
    is(Net::Nostr::Identifier->verify_response($response, 'alice', 'AB' x 32),
        0, 'uppercase hex rejected');
};

###############################################################################
# extract_relays
###############################################################################

subtest 'extract_relays: returns relay list' => sub {
    my $response = {
        relays => {
            $test_pk => ['wss://relay1.example.com', 'wss://relay2.example.com'],
        },
    };
    is(Net::Nostr::Identifier->extract_relays($response, $test_pk),
        ['wss://relay1.example.com', 'wss://relay2.example.com'],
        'relays extracted');
};

subtest 'extract_relays: returns [] when no relays key' => sub {
    is(Net::Nostr::Identifier->extract_relays({}, $test_pk),
        [], 'missing relays key');
};

subtest 'extract_relays: returns [] when relays not HASH' => sub {
    is(Net::Nostr::Identifier->extract_relays({ relays => 'bad' }, $test_pk),
        [], 'string relays');
};

subtest 'extract_relays: returns [] when pubkey not in relays' => sub {
    is(Net::Nostr::Identifier->extract_relays({ relays => { $other_pk => [] } }, $test_pk),
        [], 'different pubkey');
};

subtest 'extract_relays: returns [] when relay list not ARRAY' => sub {
    is(Net::Nostr::Identifier->extract_relays({ relays => { $test_pk => 'bad' } }, $test_pk),
        [], 'string instead of array');
};

subtest 'extract_relays: returns [] for non-HASH response' => sub {
    is(Net::Nostr::Identifier->extract_relays(undef, $test_pk), [], 'undef');
    is(Net::Nostr::Identifier->extract_relays([], $test_pk), [], 'arrayref');
};

done_testing;
