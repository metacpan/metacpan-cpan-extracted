package Protocol::TLS::Utils;
use strict;
use warnings;
use Carp;
use MIME::Base64;
use Exporter qw(import);
our @EXPORT_OK = qw(load_cert load_priv_key);

sub load_cert {
    my ($file) = @_;
    croak "specify cert_file path" unless defined $file;

    local $/;
    open my $fh, '<', $file or croak "opening cert_file error: $!";

    # TODO: multiple certs
    my ($cert) = (
        <$fh> =~ /^-----BEGIN\x20CERTIFICATE-----\r?\n
          (.+?\r?\n)
          -----END\x20CERTIFICATE-----\r?\n/msx
    );
    close $fh;
    croak "Certificate must be in PEM format" unless $cert;
    decode_base64($cert);
}

sub load_priv_key {
    my ($file) = @_;
    croak "specify key_file path" unless defined $file;

    local $/;
    open my $fh, '<', $file or croak "opening key_file error: $!";
    my ($key) = (
        <$fh> =~ /^-----BEGIN\x20(?:RSA\x20)?PRIVATE\x20KEY-----\r?\n
          (.+?\r?\n)
          -----END\x20(?:RSA\x20)?PRIVATE\x20KEY-----\r?\n/msx
    );
    close $fh;
    croak "Private key must be in PEM format" unless $key;
    decode_base64($key);
}

1
