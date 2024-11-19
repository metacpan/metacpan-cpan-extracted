package STIX::Identity;

use 5.010001;
use strict;
use warnings;
use utf8;

use STIX::Common::List;
use STIX::Common::OpenVocabulary;
use Types::Standard qw(Str Enum);
use Types::TypeTiny qw(ArrayLike);

use Moo;
use namespace::autoclean;

extends 'STIX::Common::Properties';

use constant SCHEMA =>
    'http://raw.githubusercontent.com/oasis-open/cti-stix2-json-schemas/stix2.1/schemas/sdos/identity.json';

use constant PROPERTIES => (
    qw(type spec_version id created modified),
    qw(created_by_ref revoked labels confidence lang external_references object_marking_refs granular_markings extensions),
    qw(name description roles identity_class sectors contact_information)
);

use constant STIX_OBJECT      => 'SDO';
use constant STIX_OBJECT_TYPE => 'identity';

has name           => (is => 'rw', isa => Str, required => 1);
has description    => (is => 'rw', isa => Str);
has roles          => (is => 'rw', isa => ArrayLike [Str], default => sub { STIX::Common::List->new });
has identity_class => (is => 'rw', isa => Enum [STIX::Common::OpenVocabulary->IDENTITY_CLASS()]);

has sectors => (
    is      => 'rw',
    isa     => ArrayLike [Enum [STIX::Common::OpenVocabulary->INDUSTRY_SECTOR()]],
    default => sub { STIX::Common::List->new }
);

has contact_information => (is => 'rw', isa => Str);

1;

=encoding utf-8

=head1 NAME

STIX::Identity - STIX Domain Object (SDO) - Identity

=head1 SYNOPSIS

    use STIX::Identity;

    my $identity = STIX::Identity->new();


=head1 DESCRIPTION

Identities can represent actual individuals, organizations, or groups
(e.g., ACME, Inc.) as well as classes of individuals, organizations, or
groups.


=head2 METHODS

L<STIX::Identity> inherits all methods from L<STIX::Common::Properties>
and implements the following new ones.

=over

=item STIX::Identity->new(%properties)

Create a new instance of L<STIX::Identity>.

=item $identity->contact_information

The contact information (e-mail, phone number, etc.) for this Identity.

=item $identity->description

A description that provides more details and context about the Identity.

=item $identity->id

=item $identity->identity_class

The type of entity that this Identity describes, e.g., an individual or
organization. C<IDENTITY_CLASS> (L<STIX::Common::OpenVocabulary>)

=item $identity->name

The name of this Identity.

=item $identity->roles

The list of roles that this Identity performs (e.g., CEO, Domain
Administrators, Doctors, Hospital, or Retailer). No open vocabulary is yet
defined for this property.

=item $identity->sectors

The list of sectors that this Identity belongs to. C<INDUSTRY_SECTOR>
(L<STIX::Common::OpenVocabulary>)

=item $identity->type

The type of this object, which MUST be the literal C<identity>.

=back


=head2 HELPERS

=over

=item $identity->TO_JSON

Encode the object in JSON.

=item $identity->to_hash

Return the object HASH.

=item $identity->to_string

Encode the object in JSON.

=item $identity->validate

Validate the object using JSON Schema (see L<STIX::Schema>).

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
