package STIX::ObservedData;

use 5.010001;
use strict;
use warnings;
use utf8;

use STIX::Common::List;
use Types::Standard qw(Str InstanceOf Int);
use Types::TypeTiny qw(ArrayLike);

use Moo;
use namespace::autoclean;

extends 'STIX::Common::Properties';

use constant SCHEMA =>
    'http://raw.githubusercontent.com/oasis-open/cti-stix2-json-schemas/stix2.1/schemas/sdos/observed-data.json';

use constant PROPERTIES => (
    qw(type spec_version id created modified),
    qw(created_by_ref revoked labels confidence lang external_references object_marking_refs granular_markings extensions),
    qw(first_observed last_observed number_observed objects object_refs)
);

use constant STIX_OBJECT      => 'SDO';
use constant STIX_OBJECT_TYPE => 'observed-data';

has first_observed => (
    is       => 'rw',
    required => 1,
    isa      => InstanceOf ['STIX::Common::Timestamp'],
    coerce   => sub { ref($_[0]) ? $_[0] : STIX::Common::Timestamp->new($_[0]) },
);

has last_observed => (
    is       => 'rw',
    required => 1,
    default  => sub { $_[0]->{first_observed} },
    isa      => InstanceOf ['STIX::Common::Timestamp'],
    coerce   => sub { ref($_[0]) ? $_[0] : STIX::Common::Timestamp->new($_[0]) },
);

has number_observed => (is => 'rw', isa => Int, required => 1);
has objects => (is => 'rw', isa => ArrayLike [Str], default => sub { STIX::Common::List->new });

has object_refs => (
    is  => 'rw',
    isa =>
        ArrayLike [InstanceOf ['STIX::Observable', 'STIX::Relationship', 'STIX::Sighting', 'STIX::Common::Identifier']],
    default => sub { STIX::Common::List->new }
);

1;

=encoding utf-8

=head1 NAME

STIX::ObservedData - STIX Domain Object (SDO) - Observed Data

=head1 SYNOPSIS

    use STIX::ObservedData;

    my $observed_data = STIX::ObservedData->new();


=head1 DESCRIPTION

Observed data conveys information that was observed on systems and
networks, such as log data or network traffic, using the Cyber Observable
specification.


=head2 METHODS

L<STIX::ObservedData> inherits all methods from L<STIX::Common::Properties>
and implements the following new ones.

=over

=item STIX::ObservedData->new(%properties)

Create a new instance of L<STIX::ObservedData>.

=item $observed_data->first_observed

The beginning of the time window that the data was observed during.

=item $observed_data->id

=item $observed_data->last_observed

The end of the time window that the data was observed during.

=item $observed_data->number_observed

The number of times the data represented in the objects property was
observed. This MUST be an integer between 1 and 999,999,999 inclusive.

=item $observed_data->object_refs

A list of SCOs and SROs representing the observation.

=item $observed_data->objects

A dictionary of Cyber Observable Objects that describes the single 'fact'
that was observed.

=item $observed_data->type

The type of this object, which MUST be the literal C<observed-data>.

=back


=head2 HELPERS

=over

=item $observed_data->TO_JSON

Encode the object in JSON.

=item $observed_data->to_hash

Return the object HASH.

=item $observed_data->to_string

Encode the object in JSON.

=item $observed_data->validate

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
