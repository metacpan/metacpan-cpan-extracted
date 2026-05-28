#!/usr/bin/env perl
# Parity tests for SignalWire::Utils::UrlValidator::validate_url. Mirrors
# signalwire-python tests/unit/utils/test_url_validator.py. The DNS
# resolver is stubbed via $SignalWire::Utils::UrlValidator::_RESOLVER so
# the suite stays hermetic.

use strict;
use warnings;

use Test::More;
use SignalWire::Utils::UrlValidator;

my $V = 'SignalWire::Utils::UrlValidator';

sub stub_resolver {
    my ($ip) = @_;
    $SignalWire::Utils::UrlValidator::_RESOLVER = sub { [$ip] };
}

sub stub_failed {
    $SignalWire::Utils::UrlValidator::_RESOLVER = sub { undef };
}

sub reset_state {
    $SignalWire::Utils::UrlValidator::_RESOLVER = undef;
    delete $ENV{SWML_ALLOW_PRIVATE_URLS};
}

# --- Scheme -----------------------------------------------------------

subtest 'scheme http allowed' => sub {
    reset_state();
    stub_resolver('1.2.3.4');
    ok($V->can('validate_url'), 'function exists');
    ok(SignalWire::Utils::UrlValidator::validate_url('http://example.com'), 'http allowed for public IP');
};

subtest 'scheme https allowed' => sub {
    reset_state();
    stub_resolver('1.2.3.4');
    ok(SignalWire::Utils::UrlValidator::validate_url('https://example.com'), 'https allowed');
};

subtest 'scheme ftp rejected' => sub {
    reset_state();
    ok(!SignalWire::Utils::UrlValidator::validate_url('ftp://example.com'), 'ftp rejected');
};

subtest 'scheme file rejected' => sub {
    reset_state();
    ok(!SignalWire::Utils::UrlValidator::validate_url('file:///etc/passwd'), 'file rejected');
};

subtest 'scheme javascript rejected' => sub {
    reset_state();
    ok(!SignalWire::Utils::UrlValidator::validate_url('javascript:alert(1)'), 'javascript rejected');
};

# --- Hostname ---------------------------------------------------------

subtest 'no hostname rejected' => sub {
    reset_state();
    ok(!SignalWire::Utils::UrlValidator::validate_url('http://'), 'empty hostname rejected');
};

subtest 'unresolvable hostname rejected' => sub {
    reset_state();
    stub_failed();
    ok(!SignalWire::Utils::UrlValidator::validate_url('http://nonexistent.invalid'),
        'unresolvable hostname rejected');
};

# --- Blocked ranges --------------------------------------------------

subtest 'loopback ipv4 rejected' => sub {
    reset_state();
    stub_resolver('127.0.0.1');
    ok(!SignalWire::Utils::UrlValidator::validate_url('http://localhost'), '127.0.0.1 rejected');
};

subtest 'rfc1918 10/8 rejected' => sub {
    reset_state();
    stub_resolver('10.0.0.5');
    ok(!SignalWire::Utils::UrlValidator::validate_url('http://internal'), '10/8 rejected');
};

subtest 'rfc1918 192.168/16 rejected' => sub {
    reset_state();
    stub_resolver('192.168.1.1');
    ok(!SignalWire::Utils::UrlValidator::validate_url('http://router'), '192.168/16 rejected');
};

subtest 'rfc1918 172.16/12 rejected' => sub {
    reset_state();
    stub_resolver('172.16.0.1');
    ok(!SignalWire::Utils::UrlValidator::validate_url('http://corp'), '172.16/12 rejected');
};

subtest 'link-local cloud-metadata rejected' => sub {
    reset_state();
    stub_resolver('169.254.169.254');
    ok(!SignalWire::Utils::UrlValidator::validate_url('http://metadata'), '169.254 rejected');
};

subtest '0.0.0.0/8 rejected' => sub {
    reset_state();
    stub_resolver('0.0.0.0');
    ok(!SignalWire::Utils::UrlValidator::validate_url('http://void'), '0.0.0.0/8 rejected');
};

subtest 'IPv6 loopback rejected' => sub {
    reset_state();
    stub_resolver('::1');
    ok(!SignalWire::Utils::UrlValidator::validate_url('http://[::1]'), '::1 rejected');
};

subtest 'IPv6 link-local rejected' => sub {
    reset_state();
    stub_resolver('fe80::1');
    ok(!SignalWire::Utils::UrlValidator::validate_url('http://link-local'), 'fe80::/10 rejected');
};

subtest 'IPv6 private rejected' => sub {
    reset_state();
    stub_resolver('fc00::1');
    ok(!SignalWire::Utils::UrlValidator::validate_url('http://ipv6-private'), 'fc00::/7 rejected');
};

subtest 'public IP allowed' => sub {
    reset_state();
    stub_resolver('8.8.8.8');
    ok(SignalWire::Utils::UrlValidator::validate_url('http://dns.google'), '8.8.8.8 allowed');
};

# --- allow_private bypass -------------------------------------------

subtest 'allow_private param bypasses check' => sub {
    reset_state();
    # No resolver stub: bypass short-circuits BEFORE DNS.
    ok(SignalWire::Utils::UrlValidator::validate_url('http://10.0.0.5', 1), 'allow_private bypasses');
};

subtest 'env var bypasses check' => sub {
    reset_state();
    $ENV{SWML_ALLOW_PRIVATE_URLS} = 'true';
    ok(SignalWire::Utils::UrlValidator::validate_url('http://10.0.0.5'), 'env var true bypasses');
};

subtest 'env var YES bypasses check' => sub {
    reset_state();
    $ENV{SWML_ALLOW_PRIVATE_URLS} = 'YES';
    ok(SignalWire::Utils::UrlValidator::validate_url('http://10.0.0.5'), 'env var YES bypasses (case-insensitive)');
};

subtest 'env var 1 bypasses check' => sub {
    reset_state();
    $ENV{SWML_ALLOW_PRIVATE_URLS} = '1';
    ok(SignalWire::Utils::UrlValidator::validate_url('http://10.0.0.5'), 'env var 1 bypasses');
};

subtest 'env var false does not bypass' => sub {
    reset_state();
    $ENV{SWML_ALLOW_PRIVATE_URLS} = 'false';
    stub_resolver('10.0.0.5');
    ok(!SignalWire::Utils::UrlValidator::validate_url('http://internal'), 'env var false does not bypass');
};

subtest 'blocked networks list has all nine' => sub {
    is(scalar @SignalWire::Utils::UrlValidator::BLOCKED_NETWORKS, 9,
        'all 9 SSRF block ranges present');
};

reset_state();
done_testing();
