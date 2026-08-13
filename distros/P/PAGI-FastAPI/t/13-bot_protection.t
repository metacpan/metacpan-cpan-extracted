#!/usr/bin/env perl

use v5.38;
use Test::More;
use experimental 'class';

use PAGI::FastAPI::BotProtection::ProofOfWork;
use PAGI::FastAPI::Middleware::BotProtection;
use Digest::SHA qw(sha256_hex);

use Future;
use Future::AsyncAwait;

class MockContext {
    field $headers_in  :param = {};
    field $client_ip   :param = '127.0.0.1';
    field $headers_out = {};
    field $status_code = 200;

    method scope () {
        return { client => [ $client_ip, 12345 ] };
    }

    method header ($name) {
        return $headers_in->{lc($name)};
    }

    method set_header ($name, $val) {
        $headers_out->{lc($name)} = $val;
    }

    method status ($code = undef) {
        if (defined $code) {
            $status_code = $code;
        }
        return $status_code;
    }

    method get_headers_out () { return $headers_out }
}

subtest 'ProofOfWork Engine - Challenge Creation & Verification' => sub {
    my $secret = 'test_secret_key';
    my $pow    = PAGI::FastAPI::BotProtection::ProofOfWork->new(
        difficulty => 2,
        secret     => $secret,
        ttl        => 60,
    );

    my $ip        = '10.0.0.1';
    my $ch_data   = $pow->create_challenge($ip);
    my $challenge = $ch_data->{challenge};

    ok($challenge, 'Challenge token created');
    is($ch_data->{difficulty}, 2, 'Difficulty parameter correctly set in output');

    my $nonce  = 0;
    my $target = '00';
    while (1) {
        my $hash = sha256_hex("${challenge}:${nonce}");
        last if index($hash, $target) == 0;
        $nonce++;
    }

    ok($pow->verify($challenge, $nonce, $ip), 'Valid PoW solution successfully verified');
    ok(!$pow->verify($challenge, $nonce + 999999, $ip), 'Invalid nonce fails verification');
    ok(!$pow->verify($challenge, $nonce, '192.168.1.1'), 'Solution fails if IP address does not match');

    my $tampered = $challenge;
    $tampered =~ s/10\.0\.0\.1/10.0.0.2/;
    ok(!$pow->verify($tampered, $nonce, $ip), 'Tampered challenge fails HMAC verification');
};

subtest 'ProofOfWork Engine - Expiration' => sub {
    my $pow = PAGI::FastAPI::BotProtection::ProofOfWork->new(
        difficulty => 1,
        secret     => 'test_secret',
        ttl        => -10,
    );

    my $ip      = '10.0.0.1';
    my $ch_data = $pow->create_challenge($ip);

    ok(!$pow->verify($ch_data->{challenge}, 1, $ip), 'Expired challenge is rejected');
};

subtest 'Middleware - Unauthenticated Request Blocked (HTTP 401)' => sub {
    my $middleware = PAGI::FastAPI::Middleware::BotProtection->new(
        difficulty => 2,
        secret     => 'middleware_secret',
    );

    my $c    = MockContext->new( client_ip => '172.16.0.1' );
    my $next = sub ($ctx) { return { status => 'ok' } };
    my $res  = $middleware->handle($c, $next)->get;

    is($c->status(), 401, 'Response status is 401 Unauthorized');
    is($res->{detail}, 'Bot Protection Triggered', 'Bot mitigation detail present in response');

    my $headers = $c->get_headers_out();
    ok($headers->{'x-bot-challenge'}, 'x-bot-challenge response header set');
    is($headers->{'x-bot-difficulty'}, 2, 'x-bot-difficulty response header set to 2');
};

subtest 'Middleware - Valid PoW Solved Request Allowed' => sub {
    my $secret     = 'middleware_secret';
    my $difficulty = 2;
    my $ip         = '172.16.0.1';

    my $pow = PAGI::FastAPI::BotProtection::ProofOfWork->new(
        difficulty => $difficulty,
        secret     => $secret,
    );

    my $ch_data   = $pow->create_challenge($ip);
    my $challenge = $ch_data->{challenge};
    my $nonce     = 0;
    while (1) {
        my $hash = sha256_hex("${challenge}:${nonce}");
        last if index($hash, '00') == 0;
        $nonce++;
    }

    my $middleware = PAGI::FastAPI::Middleware::BotProtection->new(
        difficulty => $difficulty,
        secret     => $secret,
    );

    my $c = MockContext->new(
        client_ip  => $ip,
        headers_in => {
            'x-bot-challenge' => $challenge,
            'x-bot-nonce'     => $nonce,
        },
    );

    my $next = async sub ($ctx) { return { detail => 'Success Access Granted' } };
    my $res  = $middleware->handle($c, $next)->get;

    is($c->status(), 200, 'Response status is 200 OK');
    is($res->{detail}, 'Success Access Granted', 'Request passed through successfully to route');
};

done_testing;
