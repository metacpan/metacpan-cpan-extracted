#!perl

# x509-to-cbom.pl - Convert the provided certificate in CBOM format

# (C) 2026, Giuseppe Di Terlizzi <giuseppe.diterlizzi@gmail.com>
# License MIT

use strict;
use warnings;
use utf8;
use v5.16;

use SBOM::CycloneDX;
use SBOM::CycloneDX::Component;
use SBOM::CycloneDX::CryptoProperties::CertificateExtension;
use SBOM::CycloneDX::CryptoProperties::CertificateProperties;
use SBOM::CycloneDX::CryptoProperties::RelatedCryptographicAsset;
use SBOM::CycloneDX::CryptoProperties;
use SBOM::CycloneDX::Enum;
use SBOM::CycloneDX::Tool;
use SBOM::CycloneDX::Util qw(cyclonedx_tool);

use Carp;
use Crypt::OpenSSL::X509;
use File::Basename;
use Time::Piece;


my $path = shift;

unless (defined $path) {
    say "Usage: $0 PATH of certificate (crt, cer, pem)\n";
    exit 1;
}

unless (-e $path) {
    say "Certificate file not found\n";
    exit 2;
}

my ($filename, $dirs, $suffix) = fileparse($path, qw[.crt .cer .pem]);

$suffix =~ s/^\.//;

my $bom  = SBOM::CycloneDX->new(spec_version => 1.7);
my $x509 = eval { Crypt::OpenSSL::X509->new_from_file($path) };

if ($@) {
    say "[ERROR] $@\n";
    exit 3;
}

my $root_component = SBOM::CycloneDX::Component->new(type => 'application', name => 'my application', version => '1.0');
my $this_tool      = SBOM::CycloneDX::Tool->new(name => $0, version => '1.0');

my $metadata = $bom->metadata;

$metadata->component($root_component);

$metadata->tools->add(cyclonedx_tool);
$metadata->tools->add($this_tool);

my $fingerprint = $x509->fingerprint_sha256;
$fingerprint =~ s/://g;

my $public_key_component = SBOM::CycloneDX::Component->new(
    type              => 'cryptographic-asset',
    name              => 'Certificate-Public-Key',
    bom_ref           => 'publicKey',
    crypto_properties => SBOM::CycloneDX::CryptoProperties->new(
        asset_type                         => 'related-crypto-material',
        related_crypto_material_properties => SBOM::CycloneDX::CryptoProperties::RelatedCryptoMaterialProperties->new(
            type   => 'public-key',
            format => 'PEM',
            size   => $x509->bit_length,
            value  => $x509->pubkey,
        )
    )
);

my @cert_extensions = ();

my $x509_extensions = $x509->extensions_by_name();

foreach my $extension_name (sort keys %{$x509_extensions}) {

    my $extension       = $x509_extensions->{$extension_name};
    my $extension_value = $extension->as_string;

    next unless $extension_value;

    my $bom_certificate_extension = SBOM::CycloneDX::CryptoProperties::CertificateExtension->new(
        common_extension_name  => $extension_name,
        common_extension_value => $extension_value
    );

    unless (grep { $extension_name eq $_ } SBOM::CycloneDX::Enum->COMMON_EXTENSION_NAMES()) {
        $bom_certificate_extension = SBOM::CycloneDX::CryptoProperties::CertificateExtension->new(
            custom_extension_name  => $extension_name,
            custom_extension_value => $extension_value
        );
    }

    push @cert_extensions, $bom_certificate_extension;

}

my $cert_component = SBOM::CycloneDX::Component->new(
    type              => 'cryptographic-asset',
    name              => $filename,
    bom_ref           => $filename,
    crypto_properties => SBOM::CycloneDX::CryptoProperties->new(
        oid                    => '2.5.4.3',
        asset_type             => 'certificate',
        certificate_properties => SBOM::CycloneDX::CryptoProperties::CertificateProperties->new(
            serial_number                => $x509->serial,
            subject_name                 => $x509->subject_name->as_string,
            issuer_name                  => $x509->issuer_name->as_string,
            certificate_format           => 'X.509',
            certificate_extension        => $suffix,
            not_valid_before             => Time::Piece->strptime($x509->notBefore(), '%b %d %H:%M:%S %Y %Z')->datetime,
            not_valid_after              => Time::Piece->strptime($x509->notAfter(),  '%b %d %H:%M:%S %Y %Z')->datetime,
            fingerprint                  => SBOM::CycloneDX::Hash->new(alg => 'SHA-256', content => $fingerprint),
            certificate_extensions       => \@cert_extensions,
            related_cryptographic_assets => [
                SBOM::CycloneDX::CryptoProperties::RelatedCryptographicAsset->new(
                    type => 'publicKey',
                    ref  => $public_key_component->bom_ref
                )
            ],
        )
    ),
);

$bom->components->add($cert_component);
$bom->components->add($public_key_component);

my @errors = $bom->validate;

say STDERR "[VALIDATION] $_" for @errors;

say $bom;
