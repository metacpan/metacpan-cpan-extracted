#!/usr/bin/perl

# Unit tests for Net::Nostr::Blossom
# Tests every code example in the POD

use strictures 2;

use Test2::V0 -no_srand => 1;
use Digest::SHA qw(sha256_hex);

use Net::Nostr::Blossom;
use Net::Nostr::Event;

my $pubkey = '781208004e09102d7da3b7345e64fd193cd1bc3fce8fdae6008d77f9cabcd036';

###############################################################################
# SYNOPSIS examples
###############################################################################

subtest 'SYNOPSIS: build a server list' => sub {
    my $bl = Net::Nostr::Blossom->new;
    $bl->add('https://blossom.self.hosted');
    $bl->add('https://cdn.blossom.cloud');
    is($bl->count, 2, 'two servers');
};

subtest 'SYNOPSIS: create event for publishing' => sub {
    my $bl = Net::Nostr::Blossom->new;
    $bl->add('https://blossom.self.hosted');
    $bl->add('https://cdn.blossom.cloud');

    my $event = $bl->to_event(pubkey => $pubkey);
    is($event->kind, 10063, 'kind 10063');
};

subtest 'SYNOPSIS: parse from event' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey  => $pubkey, kind => 10063, content => '',
        tags    => [
            ['server', 'https://blossom.self.hosted'],
            ['server', 'https://cdn.blossom.cloud'],
        ],
    );
    my $bl = Net::Nostr::Blossom->from_event($event);
    for my $url ($bl->servers) {
        ok(defined $url, "server url defined: $url");
    }
};

subtest 'SYNOPSIS: extract hash from URL' => sub {
    my $hash = 'a' x 64;
    my ($h, $ext) = Net::Nostr::Blossom->extract_hash(
        "https://old-server.com/$hash.png"
    );
    is($h, $hash, 'hash extracted');
    is($ext, 'png', 'extension extracted');
};

subtest 'SYNOPSIS: resolve alternative URLs' => sub {
    my $hash = 'a' x 64;
    my @urls = Net::Nostr::Blossom->resolve_urls(
        "https://dead-server.com/$hash.png",
        ['https://blossom.self.hosted', 'https://cdn.blossom.cloud'],
    );
    is(scalar @urls, 2, 'two alternative URLs');
};

subtest 'SYNOPSIS: verify downloaded content' => sub {
    my $data = 'file contents';
    my $expected_hash = sha256_hex($data);
    ok(Net::Nostr::Blossom->verify_sha256($data, $expected_hash), 'hash matches');
};

###############################################################################
# from_event POD example
###############################################################################

subtest 'from_event: POD example' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $pubkey, kind => 10063, content => '',
        tags => [['server', 'https://blossom.example.com']],
    );
    my $bl = Net::Nostr::Blossom->from_event($event);
    is($bl->count, 1, 'one server');
};

###############################################################################
# add POD example: chaining
###############################################################################

subtest 'add: chaining' => sub {
    my $bl = Net::Nostr::Blossom->new;
    $bl->add('https://server1.com')
       ->add('https://server2.com');
    is($bl->count, 2, 'chained adds');
};

###############################################################################
# contains POD example
###############################################################################

subtest 'contains: POD example' => sub {
    my $bl = Net::Nostr::Blossom->new;
    $bl->add('https://blossom.example.com');
    ok($bl->contains('https://blossom.example.com'), 'present');
    ok(!$bl->contains('https://other.com'), 'absent');
};

###############################################################################
# resolve_urls POD example
###############################################################################

subtest 'resolve_urls: POD example' => sub {
    my $hash = 'b' x 64;
    my @urls = Net::Nostr::Blossom->resolve_urls(
        "https://unavailable.com/$hash.jpg",
        ['https://blossom.self.hosted', 'https://cdn.blossom.cloud'],
    );
    is($urls[0], "https://blossom.self.hosted/$hash.jpg", 'first alt URL');
    is($urls[1], "https://cdn.blossom.cloud/$hash.jpg", 'second alt URL');
};

###############################################################################
# verify_sha256 POD example
###############################################################################

subtest 'verify_sha256: POD example' => sub {
    my $data = 'file contents';
    my $hash = sha256_hex($data);
    ok(Net::Nostr::Blossom->verify_sha256($data, $hash), 'valid');
    ok(!Net::Nostr::Blossom->verify_sha256('tampered', $hash), 'tampered');
};

subtest 'new() rejects unknown arguments' => sub {
    like(
        dies { Net::Nostr::Blossom->new(bogus => 'value') },
        qr/unknown.+bogus/i,
        'unknown argument rejected'
    );
};

done_testing;
