package SBOM::CycloneDX::CryptoProperties::AlgorithmProperties;

use 5.010001;
use strict;
use warnings;
use utf8;

use SBOM::CycloneDX::List;
use SBOM::CycloneDX::Enum;

use Types::Standard qw(Str Enum Num);
use Types::TypeTiny qw(ArrayLike);

use Moo;
use namespace::autoclean;

extends 'SBOM::CycloneDX::Base';

has primitive                => (is => 'rw', isa => Enum [SBOM::CycloneDX::Enum->CRYPTO_PRIMITIVES()]);
has parameter_set_identifier => (is => 'rw', isa => Str);
has curve                    => (is => 'rw', isa => Str);
has execution_environment    => (is => 'rw', isa => Str);
has implementation_platform  => (is => 'rw', isa => Enum [SBOM::CycloneDX::Enum->CRYPTO_IMPLEMENTATION_PLATFORMS()]);

has certification_level => (
    is      => 'rw',
    isa     => ArrayLike [Enum [SBOM::CycloneDX::Enum->CRYPTO_CERTIFICATION_LEVELS()]],
    default => sub { SBOM::CycloneDX::List->new }
);

has mode    => (is => 'rw', isa => Enum [SBOM::CycloneDX::Enum->CRYPTO_MODES()]);
has padding => (is => 'rw', isa => Enum [SBOM::CycloneDX::Enum->CRYPTO_PADDINGS()]);

has crypto_functions => (
    is      => 'rw',
    isa     => ArrayLike [Enum [SBOM::CycloneDX::Enum->CRYPTO_FUNCTIONS()]],
    default => sub { SBOM::CycloneDX::List->new }
);

has classical_security_level    => (is => 'rw', isa => Num);
has nist_quantum_security_level => (is => 'rw', isa => Num);

sub TO_JSON {

    my $self = shift;

    my $json = {};

    $json->{primitive}                = $self->primitive                   if $self->primitive;
    $json->{parameterSetIdentifier}   = $self->parameter_set_identifier    if $self->parameter_set_identifier;
    $json->{curve}                    = $self->curve                       if $self->curve;
    $json->{executionEnvironment}     = $self->execution_environment       if $self->execution_environment;
    $json->{implementationPlatform}   = $self->implementation_platform     if $self->implementation_platform;
    $json->{certificationLevel}       = $self->certification_level         if @{$self->certification_level};
    $json->{mode}                     = $self->mode                        if $self->mode;
    $json->{padding}                  = $self->padding                     if $self->padding;
    $json->{cryptoFunctions}          = $self->crypto_functions            if @{$self->crypto_functions};
    $json->{classicalSecurityLevel}   = $self->classical_security_level    if $self->classical_security_level;
    $json->{nistQuantumSecurityLevel} = $self->nist_quantum_security_level if $self->nist_quantum_security_level;

    return $json;

}

1;

=encoding utf-8

=head1 NAME

SBOM::CycloneDX::CryptoProperties::AlgorithmProperties - Additional properties
specific to a cryptographic algorithm.

=head1 SYNOPSIS

    SBOM::CycloneDX::CryptoProperties::AlgorithmProperties->new();


=head1 DESCRIPTION

L<SBOM::CycloneDX::CryptoProperties::AlgorithmProperties> specifies additional
properties specific to a cryptographic algorithm.

=head2 METHODS

L<SBOM::CycloneDX::CryptoProperties::AlgorithmProperties> inherits all methods from L<SBOM::CycloneDX::Base>
and implements the following new ones.

=over

=item SBOM::CycloneDX::CryptoProperties::AlgorithmProperties->new( %PARAMS )

Properties:

=over

=item C<certification_level>, The certification that the implementation of
the cryptographic algorithm has received, if any. Certifications include
revisions and levels of FIPS 140 or Common Criteria of different Extended
Assurance Levels (CC-EAL).

=item C<classical_security_level>, The classical security level that a
cryptographic algorithm provides (in bits).

=item C<crypto_functions>, The cryptographic functions implemented by the
cryptographic algorithm.

=item C<curve>, The specific underlying Elliptic Curve (EC) definition
employed which is an indicator of the level of security strength,
performance and complexity. Absent an authoritative source of curve names,
CycloneDX recommends using curve names as defined at
L<https://neuromancer.sk/std/>, the source of
which can be found at L<https://github.com/J08nY/std-curves>.

=item C<execution_environment>, The target and execution environment in
which the algorithm is implemented in.

=item C<implementation_platform>, The target platform for which the
algorithm is implemented. The implementation can be 'generic', running on
any platform or for a specific platform.

=item C<mode>, The mode of operation in which the cryptographic algorithm
(block cipher) is used.

=item C<nist_quantum_security_level>, The NIST security strength category
as defined in
L<https://csrc.nist.gov/projects/post-quantum-cryptography/post-quantum-crypt
ography-standardization/evaluation-criteria/security-(evaluation-criteria)>.
A value of 0 indicates that none of the categories are met.

=item C<padding>, The padding scheme that is used for the cryptographic
algorithm.

=item C<parameter_set_identifier>, An identifier for the parameter set of
the cryptographic algorithm. Examples: in AES128, '128' identifies the key
length in bits, in SHA256, '256' identifies the digest length, '128' in
SHAKE128 identifies its maximum security level in bits, and 'SHA2-128s'
identifies a parameter set used in SLH-DSA (FIPS205).

=item C<primitive>, Cryptographic building blocks used in higher-level
cryptographic systems and protocols. Primitives represent different
cryptographic routines: deterministic random bit generators (drbg, e.g.
CTR_DRBG from NIST SP800-90A-r1), message authentication codes (mac, e.g.
HMAC-SHA-256), blockciphers (e.g. AES), streamciphers (e.g. Salsa20),
signatures (e.g. ECDSA), hash functions (e.g. SHA-256), public-key
encryption schemes (pke, e.g. RSA), extended output functions (xof, e.g.
SHAKE256), key derivation functions (e.g. pbkdf2), key agreement algorithms
(e.g. ECDH), key encapsulation mechanisms (e.g. ML-KEM), authenticated
encryption (ae, e.g. AES-GCM) and the combination of multiple algorithms
(combiner, e.g. SP800-56Cr2).

=back

=item $algorithm_properties->certification_level

=item $algorithm_properties->classical_security_level

=item $algorithm_properties->crypto_functions

=item $algorithm_properties->curve

=item $algorithm_properties->execution_environment

=item $algorithm_properties->implementation_platform

=item $algorithm_properties->mode

=item $algorithm_properties->nist_quantum_security_level

=item $algorithm_properties->padding

=item $algorithm_properties->parameter_set_identifier

=item $algorithm_properties->primitive

=back

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
