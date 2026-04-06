#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::FailWarnings;

use Net::ACME2::Authorization ();

# --- Known challenge types are returned as their specific subclass ---

my $authz_known = Net::ACME2::Authorization->new(
    status     => 'pending',
    identifier => { type => 'dns', value => 'example.com' },
    challenges => [
        {
            type   => 'http-01',
            token  => 'abc123',
            status => 'pending',
            url    => 'https://example.com/acme/chall/http01',
        },
        {
            type   => 'dns-01',
            token  => 'def456',
            status => 'pending',
            url    => 'https://example.com/acme/chall/dns01',
        },
    ],
);

my @known_challenges = $authz_known->challenges();

is( scalar @known_challenges, 2, 'known types: both challenges returned' );
isa_ok( $known_challenges[0], 'Net::ACME2::Challenge::http_01' );
isa_ok( $known_challenges[1], 'Net::ACME2::Challenge::dns_01' );

# --- Unknown challenge types are returned as base Challenge objects ---

my $authz_unknown = Net::ACME2::Authorization->new(
    status     => 'pending',
    identifier => { type => 'dns', value => 'example.com' },
    challenges => [
        {
            type   => 'foo-bar-01',
            token  => 'unknown_token',
            status => 'pending',
            url    => 'https://example.com/acme/chall/foobar01',
        },
        {
            type   => 'http-01',
            token  => 'known_token',
            status => 'pending',
            url    => 'https://example.com/acme/chall/http01',
        },
    ],
);

my @mixed_challenges = $authz_unknown->challenges();

is( scalar @mixed_challenges, 2, 'mixed types: both challenges returned' );

# The unknown type should be a base Challenge, not a specific subclass.
isa_ok( $mixed_challenges[0], 'Net::ACME2::Challenge' );
ok(
    !$mixed_challenges[0]->isa('Net::ACME2::Challenge::http_01'),
    'unknown challenge is not a http_01 instance',
);

# Verify accessors work on the generic challenge.
is( $mixed_challenges[0]->type(),   'foo-bar-01',    'generic challenge type()' );
is( $mixed_challenges[0]->token(),  'unknown_token',  'generic challenge token()' );
is( $mixed_challenges[0]->status(), 'pending',        'generic challenge status()' );
is( $mixed_challenges[0]->url(),    'https://example.com/acme/chall/foobar01', 'generic challenge url()' );

# The known type should still be its specific subclass.
isa_ok( $mixed_challenges[1], 'Net::ACME2::Challenge::http_01' );

# --- dns-account-01 is returned as its specific subclass ---

my $authz_dns_acct = Net::ACME2::Authorization->new(
    status     => 'pending',
    identifier => { type => 'dns', value => 'example.com' },
    challenges => [
        {
            type   => 'dns-account-01',
            token  => 'acct_token',
            status => 'pending',
            url    => 'https://example.com/acme/chall/dnsacct01',
        },
    ],
);

my @dns_acct_challenges = $authz_dns_acct->challenges();

is( scalar @dns_acct_challenges, 1, 'dns-account-01: challenge returned' );
isa_ok( $dns_acct_challenges[0], 'Net::ACME2::Challenge::dns_account_01' );
is( $dns_acct_challenges[0]->type(), 'dns-account-01', 'dns-account-01 type()' );

done_testing();
