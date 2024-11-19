package STIX::Location;

use 5.010001;
use strict;
use warnings;
use utf8;

use STIX::Common::OpenVocabulary;
use Types::Standard qw(Str Num Enum);

use Moo;
use namespace::autoclean;

extends 'STIX::Common::Properties';

use constant SCHEMA =>
    'http://raw.githubusercontent.com/oasis-open/cti-stix2-json-schemas/stix2.1/schemas/sdos/location.json';

use constant PROPERTIES => (
    qw(type spec_version id created modified),
    qw(created_by_ref revoked labels confidence lang external_references object_marking_refs granular_markings extensions),
    qw(name description latitude longitude precision region country administrative_area city street_address postal_code)
);

use constant STIX_OBJECT      => 'SDO';
use constant STIX_OBJECT_TYPE => 'location';

has name                => (is => 'rw', isa => Str);
has description         => (is => 'rw', isa => Str);
has latitude            => (is => 'rw', isa => Num);
has longitude           => (is => 'rw', isa => Num);
has precision           => (is => 'rw', isa => Num);
has region              => (is => 'rw', isa => Enum [STIX::Common::OpenVocabulary->REGION()]);
has country             => (is => 'rw', isa => Str);
has administrative_area => (is => 'rw', isa => Str);
has city                => (is => 'rw', isa => Str);
has street_address      => (is => 'rw', isa => Str);
has postal_code         => (is => 'rw', isa => Str);

1;


=encoding utf-8

=head1 NAME

STIX::Location - STIX Domain Object (SDO) - Location

=head1 SYNOPSIS

    use STIX::Location;

    my $location = STIX::Location->new();


=head1 DESCRIPTION

A Location represents a geographic location. The location may be described
as any, some or all of the following: region (e.g., North America), civic
address (e.g. New York, US), latitude and longitude.


=head2 METHODS

L<STIX::Location> inherits all methods from L<STIX::Common::Properties>
and implements the following new ones.

=over

=item STIX::Location->new(%properties)

Create a new instance of L<STIX::Location>.

=item $location->administrative_area

The state, province, or other sub-national administrative area that this
Location describes.

=item $location->city

The city that this Location describes.

=item $location->country

The country that this Location describes.

=item $location->description

A textual description of the Location.

=item $location->id

=item $location->latitude

The latitude of the Location in decimal degrees.

=item $location->longitude

The longitude of the Location in decimal degrees.

=item $location->name

A name used to identify the Location.

=item $location->postal_code

The postal code for this Location.

=item $location->precision

Defines the precision of the coordinates specified by the latitude and
longitude properties, measured in meters.

=item $location->region

The region that this Location describes. (See C<REGION> in L<STIX::Common::Enum>)

=item $location->street_address

The street address that this Location describes.

=item $location->type

The type of this object, which MUST be the literal C<location>.

=back


=head2 HELPERS

=over

=item $location->TO_JSON

Encode the object in JSON.

=item $location->to_hash

Return the object HASH.

=item $location->to_string

Encode the object in JSON.

=item $location->validate

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
