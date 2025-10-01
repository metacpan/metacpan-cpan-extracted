package SBOM::CycloneDX::Enum;

use 5.010001;
use strict;
use warnings;
use utf8;

require SBOM::CycloneDX::Schema;
require SBOM::CycloneDX::Util;

use Cpanel::JSON::XS qw(decode_json);

state @LICENSES;

unless (@LICENSES) {
    my $spdx_json_schema_file = SBOM::CycloneDX::Schema::schema_file('spdx.schema.json');
    my $spdx_json_schema      = decode_json(SBOM::CycloneDX::Util::file_read($spdx_json_schema_file));
    @LICENSES = @{$spdx_json_schema->{enum}};
}

use constant SPDX_LICENSES => \@LICENSES;

use constant COMPONENT_TYPES => (qw[
    application
    framework
    library
    container
    platform
    operating-system
    device
    device-driver
    firmware
    file
    machine-learning-model
    data
    cryptographic-asset
]);

use constant EXTERNAL_REFERENCE_TYPES => (qw[
    vcs
    issue-tracker
    website
    advisories
    bom
    mailing-list
    social
    chat
    documentation
    support
    source-distribution
    distribution
    distribution-intake
    license
    build-meta
    build-system
    release-notes
    security-contact
    model-card
    log
    configuration
    evidence
    formulation
    attestation
    threat-model
    adversary-model
    risk-assessment
    vulnerability-assertion
    exploitability-statement
    pentest-report
    static-analysis-report
    dynamic-analysis-report
    runtime-analysis-report
    component-analysis-report
    maturity-report
    certification-report
    codified-infrastructure
    quality-metrics
    poam
    electronic-signature
    digital-signature
    rfc-9116
    other
]);

use constant HASH_ALGORITHMS => (qw[
    MD5
    SHA-1
    SHA-256
    SHA-384
    SHA-512
    SHA3-256
    SHA3-384
    SHA3-512
    BLAKE2b-256
    BLAKE2b-384
    BLAKE2b-512
    BLAKE3
]);

use constant LIFECYCLE_PHASE => (qw[
    design
    pre-build
    build
    post-build
    operations
    discovery
    decommission
]);

use constant LICENSE_TYPES => (qw[
    academic
    appliance
    client-access
    concurrent-user
    core-points
    custom-metric
    device
    evaluation
    named-user
    node-locked
    oem
    perpetual
    processor-points
    subscription
    user
    other
]);

use constant CRYPTO_PRIMITIVES => (qw[
    drbg
    mac
    block-cipher
    stream-cipher
    signature
    hash
    pke
    xof
    kdf
    key-agree
    kem
    ae
    combiner
    other
    unknown
]);

use constant CRYPTO_IMPLEMENTATION_PLATFORMS => (qw[
    generic
    x86_32
    x86_64
    armv7-a
    armv7-m
    armv8-a
    armv8-m
    armv9-a
    armv9-m
    s390x
    ppc64
    ppc64le
    other
    unknown
]);

use constant CRYPTO_CERTIFICATION_LEVELS => (qw[
    none
    fips140-1-l1
    fips140-1-l2
    fips140-1-l3
    fips140-1-l4
    fips140-2-l1
    fips140-2-l2
    fips140-2-l3
    fips140-2-l4
    fips140-3-l1
    fips140-3-l2
    fips140-3-l3
    fips140-3-l4
    cc-eal1 cc-eal1+
    cc-eal2 cc-eal2+
    cc-eal3 cc-eal3+
    cc-eal4 cc-eal4+
    cc-eal5 cc-eal5+
    cc-eal6 cc-eal6+
    cc-eal7 cc-eal7+
    other
    unknown
]);

use constant CRYPTO_MODES => (qw[
    cbc
    ecb
    ccm
    gcm
    cfb
    ofb
    ctr
    other
    unknown
]);

use constant CRYPTO_PADDINGS => (qw[
    pkcs5
    pkcs7
    pkcs1v15
    oaep
    raw
    other
    unknown
]);

use constant CRYPTO_FUNCTIONS => (qw[
    generate
    keygen
    encrypt
    decrypt
    digest
    tag
    keyderive
    sign
    verify
    encapsulate
    decapsulate
    other
    unknown
]);

use constant RELATED_CRYPTO_MATERIAL_TYPES => (qw[
    private-key
    public-key
    secret-key
    key
    ciphertext
    signature
    digest
    initialization-vector
    nonce
    seed
    salt
    shared-secret
    tag
    additional-data
    password
    credential
    token
    other
    unknown
]);

use constant RELATED_CRYPTO_MATERIAL_STATES => (qw[
    pre-activation
    active
    suspended
    deactivated
    compromised
    destroyed
]);

use constant PROTOCOL_PROPERTIES_TYPES => (qw[
    tls
    ssh
    ipsec
    ike
    sstp
    wpa
    other
    unknown
]);


1;

=encoding utf-8

=head1 NAME

SBOM::CycloneDX::Enum - Enumeration

=head1 SYNOPSIS

    foreach (@{SBOM::CycloneDX::ENUM->SPDX_LICENSES}) {
        say $_;
    }


=head1 DESCRIPTION

L<SBOM::CycloneDX::Enum> is internal class used by L<SBOM::CycloneDX>.


=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/giterlizzi/perl-SBOM-CycloneDX/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/giterlizzi/perl-SBOM-CycloneDX>

    git clone https://github.com/giterlizzi/perl-SBOM-CycloneDX.git


=head1 AUTHOR

=over 4

=item * Giuseppe Di Terlizzi <gdt@cpan.org>

=back


=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2025 by Giuseppe Di Terlizzi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
