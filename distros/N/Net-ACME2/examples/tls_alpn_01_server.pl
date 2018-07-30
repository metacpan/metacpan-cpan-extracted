#!/usr/bin/env perl

use strict;
use warnings;
use autodie;

# This script demonstrates the server workflow for tls-alpn-01.
# This is what ACME clients will need to set up to complete a
# tls-alpn-01 challenge.
#
# See tls_alpn_01_server.pl for a corresponding client implementation.

use IO::Socket::SSL;
use IO::Socket::SSL::Utils;

use Net::ACME2::Challenge::tls_alpn_01;

die 'No ALPN support in Net::SSLeay!' if !Net::SSLeay->can('CTX_set_alpn_protos');

# This sample certificate is for “example.com”.
my $cert = <<END;
-----BEGIN CERTIFICATE-----
MIIBbDCCAROgAwIBAgIBADAKBggqhkjOPQQDAjAWMRQwEgYDVQQDDAtleGFtcGxlLmNvbTAiGA8y
MDE4MDYxNjIyNDQzNloYDzIwMTgwNjIwMjI0NDM2WjAWMRQwEgYDVQQDDAtleGFtcGxlLmNvbTBZ
MBMGByqGSM49AgEGCCqGSM49AwEHA0IABMz7vfcn+luxABJVCbTwaiodfgHtMpKOKOO2JB/PH870
Nuv3zYtxaTV5qJgv+zeDPLnOh2Iha7zY+aitiTInMt+jTjBMMBYGA1UdEQQPMA2CC2V4YW1wbGUu
Y29tMDIGCSsGAQUFBwEeAQEB/wQiBCD62VSO3yQctnxsRD5HODf+rESG3LA/1r87NtogRts92zAK
BggqhkjOPQQDAgNHADBEAiBaT2YvK5XPp2gROihwkogKyYhIi/7j0sxq8tMJinoEsAIgXTYzuEcl
t57FEFwZ0kzWqRurHOOqoUg26gW495mhSNU=
-----END CERTIFICATE-----
END

my $server = IO::Socket::SSL->new(
    LocalAddr => '0.0.0.0',
    LocalPort => 443,
    Listen => 1,
    SSL_cert => IO::Socket::SSL::Utils::PEM_string2cert($cert),
    SSL_key => IO::Socket::SSL::Utils::PEM_string2key( Net::ACME2::Challenge::tls_alpn_01::KEY() ),
    SSL_alpn_protocols => [ 'acme-tls/1' ],
);

die "Failed to instantiate SSL server: $! ($@)" if !$server;

while ( $server->accept() ) {
    last if !fork();
}

close $server;

1;
