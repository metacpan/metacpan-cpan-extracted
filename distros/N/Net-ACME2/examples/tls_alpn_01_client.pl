#!/usr/bin/env perl

use strict;
use warnings;
use autodie;

# This script imitates the ACME server’s validation process.
# It’s useful for testing your challenge setup independently of the
# actual ACME validation.
#
# See tls_alpn_01_server.pl for a corresponding server implementation.

use constant {
    _DOMAIN => 'example.com',
};

use Crypt::OpenSSL::X509;
use IO::Socket::SSL;

use Crypt::Perl::X509::Extension::acmeValidation_v1;

die 'No ALPN support in Net::SSLeay!' if !Net::SSLeay->can('CTX_set_alpn_protos');

my $client = IO::Socket::SSL->new(
    PeerAddr => '127.0.0.1',
    PeerPort => '443',
    ReuseAddr => 1,
    SSL_alpn_protocols => [ 'acme-tls/1' ],
    SSL_hostname => _DOMAIN(),
    SSL_verify_callback => sub {
        my ($ossl_o, $cert_store, $attrs_str, $errs_str, $cert_addr) = @_;

        my $pem = Net::SSLeay::PEM_get_string_X509($cert_addr);

        my $x509 = Crypt::OpenSSL::X509->new_from_string($pem, Crypt::OpenSSL::X509::FORMAT_PEM());
        my $exts_hr = $x509->extensions_by_oid();

        my $extn_obj = $exts_hr->{ Crypt::Perl::X509::Extension::acmeValidation_v1::OID() };
        die "No acmeValidation-v1 extension!" if !$extn_obj;

        if (!$extn_obj->critical()) {
            die "acmeValidation-v1 is not marked critical!";
        }

        my $val = pack 'H*', substr( $extn_obj->value(), 1 );

        print "This certificate’s acmeValidation-v1 extension has this value:$/$/";
        printf "\t%v.02x$/$/", $val;

        return 1;
    },
);

die "SSL client failure: $! ($@)\n" if !$client;
