package STIX::Sighting;

use 5.010001;
use strict;
use warnings;
use utf8;

use STIX::Common::List;
use Types::Standard qw(Bool Int Str InstanceOf);
use Types::TypeTiny qw(ArrayLike);

use Moo;
use namespace::autoclean;

extends 'STIX::Common::Properties';

use constant SCHEMA =>
    'http://raw.githubusercontent.com/oasis-open/cti-stix2-json-schemas/stix2.1/schemas/sros/sighting.json';

use constant PROPERTIES => (
    qw(type spec_version id created modified),
    qw(created_by_ref revoked labels confidence lang external_references object_marking_refs granular_markings extensions),
    qw(description first_seen last_seen count sighting_of_ref observed_data_refs where_sighted_refs summary)
);

use constant STIX_OBJECT      => 'SRO';
use constant STIX_OBJECT_TYPE => 'sighting';

has description => (is => 'rw');

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

has count => (is => 'rw', isa => Int);

has sighting_of_ref => (is => 'rw', isa => InstanceOf ['STIX::Common::Identifier', 'STIX::Object'], required => 1);

has observed_data_refs => (
    is      => 'rw',
    isa     => ArrayLike [InstanceOf ['STIX::Observable', 'STIX::Common::Identifier']],
    default => sub { STIX::Common::List->new }
);

# TODO A list of ID references to the Identity or Location objects describing the entities or types of entities that saw the sighting.
has where_sighted_refs => (
    is      => 'rw',
    isa     => ArrayLike [InstanceOf ['STIX::Object', 'STIX::Common::Identifier']],
    default => sub { STIX::Common::List->new }
);

has summary => (is => 'rw', isa => Bool, coerce => 1);

1;

=encoding utf-8

=head1 NAME

STIX::Sighting - STIX Relationship Object (SRO) - Sighting

=head1 SYNOPSIS

    use STIX::Sighting;

    my $sighting = STIX::Sighting->new();


=head1 DESCRIPTION

A Sighting denotes the belief that something in CTI (e.g., an indicator,
malware, tool, threat actor, etc.) was seen.


=head2 METHODS

L<STIX::Sighting> inherits all methods from L<STIX::Common::Properties>
and implements the following new ones.

=over

=item STIX::Sighting->new(%properties)

Create a new instance of L<STIX::Sighting>.

=item $sighting->count

This is an integer between 0 and 999,999,999 inclusive and represents the
number of times the object was sighted.

=item $sighting->description

A description that provides more details and context about the Sighting.

=item $sighting->first_seen

The beginning of the time window during which the SDO referenced by the
sighting_of_ref property was sighted.

=item $sighting->id

=item $sighting->last_seen

The end of the time window during which the SDO referenced by the
sighting_of_ref property was sighted.

=item $sighting->observed_data_refs

A list of ID references to the Observed Data objects that contain the raw
cyber data for this Sighting.

=item $sighting->sighting_of_ref

An ID reference to the object that has been sighted.

=item $sighting->summary

The summary property indicates whether the Sighting should be considered
summary data. 

=item $sighting->type

The type of this object, which MUST be the literal C<sighting>.

=item $sighting->where_sighted_refs

A list of ID references to the Identity or Location objects describing the
entities or types of entities that saw the sighting.

=back


=head2 HELPERS

=over

=item $sighting->TO_JSON

Encode the object in JSON.

=item $sighting->to_hash

Return the object HASH.

=item $sighting->to_string

Encode the object in JSON.

=item $sighting->validate

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
