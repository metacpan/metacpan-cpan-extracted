package STIX::Observable::Type::X509V3Extensions;

use 5.010001;
use strict;
use warnings;
use utf8;

use Moo;
use Types::Standard qw(Str InstanceOf);
use namespace::autoclean;

extends 'STIX::Object';

use constant SCHEMA =>
    'http://raw.githubusercontent.com/oasis-open/cti-stix2-json-schemas/stix2.1/schemas/observables/x509-certificate.json#/definitions/x509-v3-extensions-type';

use constant PROPERTIES => (qw(
    basic_constraints name_constraints policy_constraints key_usage extended_key_usage subject_key_identifier
    authority_key_identifier subject_alternative_name issuer_alternative_name subject_directory_attributes
    crl_distribution_points inhibit_any_policy private_key_usage_period_not_before
    private_key_usage_period_not_after certificate_policies policy_mappings
));

has basic_constraints            => (is => 'rw', isa => Str);
has name_constraints             => (is => 'rw', isa => Str);
has policy_constraints           => (is => 'rw', isa => Str);
has key_usage                    => (is => 'rw', isa => Str);
has extended_key_usage           => (is => 'rw', isa => Str);
has subject_key_identifier       => (is => 'rw', isa => Str);
has authority_key_identifier     => (is => 'rw', isa => Str);
has subject_alternative_name     => (is => 'rw', isa => Str);
has issuer_alternative_name      => (is => 'rw', isa => Str);
has subject_directory_attributes => (is => 'rw', isa => Str);
has crl_distribution_points      => (is => 'rw', isa => Str);
has inhibit_any_policy           => (is => 'rw', isa => Str);

has private_key_usage_period_not_before => (
    is     => 'rw',
    isa    => InstanceOf ['STIX::Common::Timestamp'],
    coerce => sub { ref($_[0]) ? $_[0] : STIX::Common::Timestamp->new($_[0]) },
);

has private_key_usage_period_not_after => (
    is     => 'rw',
    isa    => InstanceOf ['STIX::Common::Timestamp'],
    coerce => sub { ref($_[0]) ? $_[0] : STIX::Common::Timestamp->new($_[0]) },
);

has certificate_policies => (is => 'rw', isa => Str);
has policy_mappings      => (is => 'rw', isa => Str);

1;

=encoding utf-8

=head1 NAME

STIX::Observable::Type::X509V3Extensions - STIX Cyber-observable Object (SCO) - X.509 v3 Extensions Type

=head1 SYNOPSIS

    use STIX::Observable::Type::X509V3Extensions;

    my $x509_v3_extensions_type = STIX::Observable::Type::X509V3Extensions->new();


=head1 DESCRIPTION

Specifies any standard X.509 v3 extensions that may be used in the certificate.


=head2 METHODS

L<STIX::Observable::Type::X509V3Extensions> inherits all methods from L<STIX::Object>
and implements the following new ones.

=over

=item STIX::Observable::Type::X509V3Extensions->new(%properties)

Create a new instance of L<STIX::Observable::Type::X509V3Extensions>.

=item $x509_v3_extensions_type->authority_key_identifier

Specifies the identifier that provides a means of identifying the public
key corresponding to the private key used to sign a certificate.

=item $x509_v3_extensions_type->basic_constraints

Specifies a multi-valued extension which indicates whether a certificate is
a CA certificate.

=item $x509_v3_extensions_type->certificate_policies

Specifies a sequence of one or more policy information terms, each of which
consists of an object identifier (OID) and optional qualifiers.

=item $x509_v3_extensions_type->crl_distribution_points

Specifies how CRL information is obtained.

=item $x509_v3_extensions_type->extended_key_usage

Specifies a list of usages indicating purposes for which the certificate
public key can be used for.

=item $x509_v3_extensions_type->inhibit_any_policy

Specifies the number of additional certificates that may appear in the path
before anyPolicy is no longer permitted.

=item $x509_v3_extensions_type->issuer_alternative_name

Specifies the additional identities to be bound to the issuer of the
certificate.

=item $x509_v3_extensions_type->key_usage

Specifies a multi-valued extension consisting of a list of names of the
permitted key usages.

=item $x509_v3_extensions_type->name_constraints

Specifies a namespace within which all subject names in subsequent
certificates in a certification path MUST be located.

=item $x509_v3_extensions_type->policy_constraints

Specifies any constraints on path validation for certificates issued to
CAs.

=item $x509_v3_extensions_type->policy_mappings

Specifies one or more pairs of OIDs; each pair includes an
issuerDomainPolicy and a subjectDomainPolicy

=item $x509_v3_extensions_type->private_key_usage_period_not_after

Specifies the date on which the validity period ends for the private key,
if it is different from the validity period of the certificate.

=item $x509_v3_extensions_type->private_key_usage_period_not_before

Specifies the date on which the validity period begins for the private key,
if it is different from the validity period of the certificate.

=item $x509_v3_extensions_type->subject_alternative_name

Specifies the additional identities to be bound to the subject of the
certificate.

=item $x509_v3_extensions_type->subject_directory_attributes

Specifies the identification attributes (e.g., nationality) of the subject.

=item $x509_v3_extensions_type->subject_key_identifier

Specifies the identifier that provides a means of identifying certificates
that contain a particular public key.

=back


=head2 HELPERS

=over

=item $x509_v3_extensions_type->TO_JSON

Encode the object in JSON.

=item $x509_v3_extensions_type->to_hash

Return the object HASH.

=item $x509_v3_extensions_type->to_string

Encode the object in JSON.

=item $x509_v3_extensions_type->validate

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
