#!/usr/bin/env perl

use v5.38;
use Test::More;
use Digest::SHA qw(sha256_hex);

use PAGI::FastAPI::BotProtection::ProofOfWork;

subtest 'IPv6 clients can complete and verify a challenge' => sub {
    my $engine = PAGI::FastAPI::BotProtection::ProofOfWork->new(
        secret     => 'test-secret',
        difficulty => 1,
        ttl        => 60,
    );

    for my $ip (qw(::1 2001:db8::1 fe80::abcd)) {
        my $challenge = $engine->create_challenge($ip);

        # Brute-force a valid nonce for the (low) test difficulty.
        my ($nonce, $found);
        for my $n (0 .. 5000) {
            my $hash = sha256_hex("$challenge->{challenge}:$n");
            if ($hash =~ /^0/) { $nonce = $n; $found = 1; last }
        }
        ok $found, "found a valid PoW nonce for client_ip=$ip";

        ok $engine->verify($challenge->{challenge}, $nonce, $ip),
            "verify() succeeds for IPv6 client_ip=$ip";
    }
};

subtest 'a challenge minted for one client_ip is rejected for another' => sub {
    my $engine = PAGI::FastAPI::BotProtection::ProofOfWork->new(
        secret     => 'test-secret',
        difficulty => 1,
        ttl        => 60,
    );

    my $challenge = $engine->create_challenge('::1');
    ok !$engine->verify($challenge->{challenge}, '0', '::2'),
        'verify() fails when client_ip does not match the challenge';
};

subtest 'difficulty of 0 is a legal (trivial) configuration, not silently rejected' => sub {
    my $engine = PAGI::FastAPI::BotProtection::ProofOfWork->new(
        secret     => 'test-secret',
        difficulty => 0,
        ttl        => 60,
    );

    my $challenge = $engine->create_challenge('192.168.1.1');
    ok $engine->verify($challenge->{challenge}, 'any-nonce-at-all', '192.168.1.1'),
        'a difficulty=0 challenge verifies with any nonce, rather than failing outright';
};

done_testing;
