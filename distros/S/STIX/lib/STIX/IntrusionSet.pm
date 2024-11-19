package STIX::IntrusionSet;

use 5.010001;
use strict;
use warnings;
use utf8;

use STIX::Common::List;
use STIX::Common::OpenVocabulary;
use Types::Standard qw(Str Enum InstanceOf);
use Types::TypeTiny qw(ArrayLike);

use Moo;
use namespace::autoclean;

extends 'STIX::Common::Properties';

use constant SCHEMA =>
    'http://raw.githubusercontent.com/oasis-open/cti-stix2-json-schemas/stix2.1/schemas/sdos/intrusion-set.json';

use constant PROPERTIES => (
    qw(type spec_version id created modified),
    qw(created_by_ref revoked labels confidence lang external_references object_marking_refs granular_markings extensions),
    qw(name description aliases first_seen last_seen goals resource_level primary_motivation secondary_motivations)
);

use constant STIX_OBJECT      => 'SDO';
use constant STIX_OBJECT_TYPE => 'intrusion-set';

has name        => (is => 'rw', isa => Str, required => 1);
has description => (is => 'rw', isa => Str);
has aliases     => (is => 'rw', isa => ArrayLike [Str], default => sub { STIX::Common::List->new });

has first_seen => (
    is     => 'rw',
    isa    => InstanceOf ['STIX::Common::Timestamp'],
    coerce => sub { ref($_[0]) ? $_[0] : STIX::Common::Timestamp->new($_[0]) },
);

has last_seen => (
    is     => 'rw',
    isa    => InstanceOf ['STIX::Common::Timestamp'],
    coerce => sub { ref($_[0]) ? $_[0] : STIX::Common::Timestamp->new($_[0]) },
);

has goals              => (is => 'rw', isa => ArrayLike [Str], default => sub { STIX::Common::List->new });
has resource_level     => (is => 'rw', isa => Enum [STIX::Common::OpenVocabulary->ATTACK_RESOURCE_LEVEL()]);
has primary_motivation => (is => 'rw', isa => Enum [STIX::Common::OpenVocabulary->ATTACK_MOTIVATION()]);

has secondary_motivations => (
    is      => 'rw',
    isa     => ArrayLike [Enum [STIX::Common::OpenVocabulary->ATTACK_MOTIVATION()]],
    default => sub { STIX::Common::List->new }
);

1;

=encoding utf-8

=head1 NAME

STIX::IntrusionSet - STIX Domain Object (SDO) - Intrusion-set

=head1 SYNOPSIS

    use STIX::IntrusionSet;

    my $intrusion_set = STIX::IntrusionSet->new();


=head1 DESCRIPTION

An Intrusion Set is a grouped set of adversary behavior and resources with
common properties that is believed to be orchestrated by a single
organization.


=head2 METHODS

L<STIX::IntrusionSet> inherits all methods from L<STIX::Common::Properties>
and implements the following new ones.

=over

=item STIX::IntrusionSet->new(%properties)

Create a new instance of L<STIX::IntrusionSet>.

=item $intrusion_set->aliases

Alternative names used to identify this Intrusion Set.

=item $intrusion_set->description

Provides more context and details about the Intrusion Set object.

=item $intrusion_set->first_seen

The time that this Intrusion Set was first seen.

=item $intrusion_set->goals

The high level goals of this Intrusion Set, namely, what are they trying to
do.

=item $intrusion_set->id

=item $intrusion_set->last_seen

The time that this Intrusion Set was last seen.

=item $intrusion_set->name

The name used to identify the Intrusion Set.

=item $intrusion_set->primary_motivation

The primary reason, motivation, or purpose behind this Intrusion Set.
(See C<ATTACK_MOTIVATION> in L<STIX::Common::OpenVocabulary>)

=item $intrusion_set->resource_level

This defines the organizational level at which this Intrusion Set typically
works.
(See C<ATTACK_RESOURCE_LEVEL> in L<STIX::Common::OpenVocabulary>)

=item $intrusion_set->secondary_motivations

The secondary reasons, motivations, or purposes behind this Intrusion Set.
(See C<ATTACK_MOTIVATION> in L<STIX::Common::OpenVocabulary>)

=item $intrusion_set->type

The type of this object, which MUST be the literal C<intrusion-set>.

=back


=head2 HELPERS

=over

=item $intrusion_set->TO_JSON

Encode the object in JSON.

=item $intrusion_set->to_hash

Return the object HASH.

=item $intrusion_set->to_string

Encode the object in JSON.

=item $intrusion_set->validate

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
