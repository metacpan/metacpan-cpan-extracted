#!perl

use strict;
use warnings;
use v5.10;

use FindBin '$RealBin';
use lib "$RealBin/lib";

use Test::More;
use Test::CycloneDX qw(bom_1_6 bom_test_data);

use URI::PackageURL;

use SBOM::CycloneDX::License;
use SBOM::CycloneDX::Hash;

my $bom_test_data = bom_test_data(__FILE__);

my $bom = bom_1_6();

my $purl = URI::PackageURL->new(
    type       => 'maven',
    namespace  => 'com.acme',
    name       => 'tomcat-catalina',
    version    => '9.0.14',
    qualifiers => {packaging => 'jar'}
);

my $component = SBOM::CycloneDX::Component->new(
    type        => 'application',
    publisher   => 'Acme Inc',
    group       => $purl->namespace,
    name        => $purl->name,
    version     => $purl->version,
    description => 'Modified version of Apache Catalina',
    scope       => 'required',
    hashes      => [
        SBOM::CycloneDX::Hash->new(alg => 'MD5',   content => '3942447fac867ae5cdb3229b658f4d48'),
        SBOM::CycloneDX::Hash->new(alg => 'SHA-1', content => 'e6b1000b94e835ffd37f4c6dcbdad43f4b48a02a'),
        SBOM::CycloneDX::Hash->new(
            alg     => 'SHA-256',
            content => 'f498a8ff2dd007e29c2074f5e4b01a9a01775c3ff3aeaf6906ea503bc5791b7b'
        ),
        SBOM::CycloneDX::Hash->new(
            alg     => 'SHA-512',
            content =>
                'e8f33e424f3f4ed6db76a482fde1a5298970e442c531729119e37991884bdffab4f9426b7ee11fccd074eeda0634d71697d6f88a460dce0ac8d627a29f7d1282'
        )
    ],
    licenses =>
        [SBOM::CycloneDX::License->new(id => 'Apache-2.0', acknowledgement => 'declared', bom_ref => 'my-license')],
    purl => $purl
);

$bom->components->add($component);


diag 'CycloneDX 1.6 - Valid License ID', "\n", "$bom";

isnt "$bom", '';

is $bom->spec_version, 1.6;

my @errors = $bom->validate;

diag $_ for @errors;

is scalar @errors, 0;

is_deeply $bom->to_hash, $bom_test_data;

done_testing();
