package STIX::Observable::X509Certificate;

use 5.010001;
use strict;
use warnings;
use utf8;

use Types::Standard qw(Str Int InstanceOf Bool);

use Moo;
use namespace::autoclean;

extends 'STIX::Observable';

use constant SCHEMA =>
    'http://raw.githubusercontent.com/oasis-open/cti-stix2-json-schemas/stix2.1/schemas/observables/x509-certificate.json';

use constant PROPERTIES => (
    qw(type id),
    qw(spec_version object_marking_refs granular_markings defanged extensions),
    qw(is_self_signed hashes version serial_number signature_algorithm issuer validity_not_before validity_not_after subject subject_public_key_algorithm subject_public_key_modulus subject_public_key_exponent x509_v3_extensions),
);

use constant STIX_OBJECT      => 'SCO';
use constant STIX_OBJECT_TYPE => 'x509-certificate';

has is_self_signed      => (is => 'rw', isa => Bool);
has hashes              => (is => 'rw', isa => InstanceOf ['STIX::Common::Hashes']);
has version             => (is => 'rw', isa => Str);
has serial_number       => (is => 'rw', isa => Str);
has signature_algorithm => (is => 'rw', isa => Str);
has issuer              => (is => 'rw', isa => Str);

has validity_not_before => (
    is     => 'rw',
    isa    => InstanceOf ['STIX::Common::Timestamp'],
    coerce => sub { ref($_[0]) ? $_[0] : STIX::Common::Timestamp->new($_[0]) },
);

has validity_not_after => (
    is     => 'rw',
    isa    => InstanceOf ['STIX::Common::Timestamp'],
    coerce => sub { ref($_[0]) ? $_[0] : STIX::Common::Timestamp->new($_[0]) },
);

has subject                      => (is => 'rw', isa => Str);
has subject_public_key_algorithm => (is => 'rw', isa => Str);
has subject_public_key_modulus   => (is => 'rw', isa => Str);
has subject_public_key_exponent  => (is => 'rw', isa => Int);
has x509_v3_extensions           => (is => 'rw', isa => InstanceOf ['STIX::Observable::Type::X509V3Extensions']);

1;

=encoding utf-8

=head1 NAME

STIX::Observable::X509Certificate - STIX Cyber-observable Object (SCO) - X.509 Certificate

=head1 SYNOPSIS

    use STIX::Observable::X509Certificate;

    my $x509_certificate = STIX::Observable::X509Certificate->new();


=head1 DESCRIPTION

The X509 Certificate Object represents the properties of an X.509
certificate.


=head2 METHODS

L<STIX::Observable::X509Certificate> inherits all methods from L<STIX::Observable>
and implements the following new ones.

=over

=item STIX::Observable::X509Certificate->new(%properties)

Create a new instance of L<STIX::Observable::X509Certificate>.

=item $x509_certificate->hashes

Specifies any hashes that were calculated for the entire contents of the
certificate.

=item $x509_certificate->id

=item $x509_certificate->is_self_signed

Specifies whether the certificate is self-signed, i.e., whether it is
signed by the same entity whose identity it certifies.

=item $x509_certificate->issuer

Specifies the name of the Certificate Authority that issued the
certificate.

=item $x509_certificate->serial_number

Specifies the unique identifier for the certificate, as issued by a
specific Certificate Authority.

=item $x509_certificate->signature_algorithm

Specifies the name of the algorithm used to sign the certificate.

=item $x509_certificate->subject

Specifies the name of the entity associated with the public key stored in
the subject public key field of the certificate.

=item $x509_certificate->subject_public_key_algorithm

Specifies the name of the algorithm with which to encrypt data being sent
to the subject.

=item $x509_certificate->subject_public_key_exponent

Specifies the exponent portion of the subject’s public RSA key, as an
integer.

=item $x509_certificate->subject_public_key_modulus

Specifies the modulus portion of the subject’s public RSA key.

=item $x509_certificate->type

The value of this property MUST be C<x509-certificate>.

=item $x509_certificate->validity_not_after

Specifies the date on which the certificate validity period ends.

=item $x509_certificate->validity_not_before

Specifies the date on which the certificate validity period begins.

=item $x509_certificate->version

Specifies the version of the encoded certificate.

=item $x509_certificate->x509_v3_extensions

Specifies any standard X.509 v3 extensions that may be used in the
certificate.

=back


=head2 HELPERS

=over

=item $x509_certificate->TO_JSON

Encode the object in JSON.

=item $x509_certificate->to_hash

Return the object HASH.

=item $x509_certificate->to_string

Encode the object in JSON.

=item $x509_certificate->validate

Validate the object using JSON Schema
(see L<STIX::Schema>).

=back


=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/giterlizzi/perl-STIX/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/giterlizzi/perl-STIX>

    git clone https://github.com/giterlizzi/perl-STIX.git


=head1 AUTHOR

=over 4

=item * Giuseppe Di Terlizzi <gdt@cpan.org>

=back


=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2024 by Giuseppe Di Terlizzi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
