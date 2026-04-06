#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::FailWarnings;
use Test::Exception;

use Digest::SHA  ();
use MIME::Base64 ();

use Net::ACME2::LetsEncrypt ();
use Net::ACME2::Challenge::dns_01 ();

# Same key used in tls_alpn_01 tests.
my $acct_key = <<END;
-----BEGIN EC PRIVATE KEY-----
MHcCAQEEIHBOiMfg60yZ+A+UTrjNMe+RfcQEG3UsmmWpVC5q4czuoAoGCCqGSM49
AwEHoUQDQgAEhTlS9jCZzPmQPkonJm27t7uhdfJeK2G+MnRHjhQPxGXQD5/xeLjg
TvxmFz90oI8SVqB1KaL7CHrAwkm706Msiw==
-----END EC PRIVATE KEY-----
END

my $acme = Net::ACME2::LetsEncrypt->new( key => $acct_key );

my $challenge = Net::ACME2::Challenge::dns_01->new(
    token  => 'evaGxfADs6pSRb2LAv9IZf17Dt3juxGJ-PCt92wr-oA',
    type   => 'dns-01',
    status => 'pending',
    url    => 'https://example.com/acme/chall/dns01',
);

# get_record_name() is a constant per ACME spec.
is(
    $challenge->get_record_name(),
    '_acme-challenge',
    'get_record_name() returns the ACME-specified label',
);

# get_record_value() requires an ACME instance.
dies_ok(
    sub { $challenge->get_record_value() },
    'get_record_value() dies without ACME instance',
);

# Compute expected value manually: base64url(sha256(key_authorization)).
my $key_authz = $acme->make_key_authorization($challenge);
my $expected  = MIME::Base64::encode_base64url( Digest::SHA::sha256($key_authz) );

is(
    $challenge->get_record_value($acme),
    $expected,
    'get_record_value() returns base64url-encoded SHA-256 of key authorization',
);

# Verify the value looks like a base64url string (no padding, no +/).
like(
    $challenge->get_record_value($acme),
    qr/\A[A-Za-z0-9_-]+\z/,
    'get_record_value() output is valid base64url (no padding or special chars)',
);

done_testing();
