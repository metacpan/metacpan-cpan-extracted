#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use Crypt::Format;
use Digest::SHA;

use Net::ACME2::LetsEncrypt;
use Net::ACME2::Challenge::tls_alpn_01;

my $acct_key = <<END;
-----BEGIN EC PRIVATE KEY-----
MHcCAQEEIHBOiMfg60yZ+A+UTrjNMe+RfcQEG3UsmmWpVC5q4czuoAoGCCqGSM49
AwEHoUQDQgAEhTlS9jCZzPmQPkonJm27t7uhdfJeK2G+MnRHjhQPxGXQD5/xeLjg
TvxmFz90oI8SVqB1KaL7CHrAwkm706Msiw==
-----END EC PRIVATE KEY-----
END

my $acme = Net::ACME2::LetsEncrypt->new( key => $acct_key );

my $challenge = Net::ACME2::Challenge::tls_alpn_01->new(
    token => 'VCCuUSPQ3FZnOP5GIOlYym2_Jd5cxZ1o_3MoKQ0bCO0',
);

my $key_authz = $acme->make_key_authorization($challenge);
my $authz_sha = Digest::SHA::sha256($key_authz);

my $pem = $challenge->create_certificate( $acme, 'example.com' );

my $der = Crypt::Format::pem2der($pem);

like( $der, qr<example\.com>, 'domain is in the certificate' );
like( $der, qr<\Q$authz_sha\E>, 'key authz SHA-256 is in the certificate' );

done_testing();
