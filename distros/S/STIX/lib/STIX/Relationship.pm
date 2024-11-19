package STIX::Relationship;

use 5.010001;
use strict;
use warnings;
use utf8;

use STIX::Common::List;
use Types::Standard qw(Str InstanceOf);
use Types::TypeTiny qw(ArrayLike);

use Moo;
use namespace::autoclean;

extends 'STIX::Common::Properties';

use constant SCHEMA =>
    'http://raw.githubusercontent.com/oasis-open/cti-stix2-json-schemas/stix2.1/schemas/sros/relationship.json';

use constant PROPERTIES => (
    qw(type spec_version id created modified),
    qw(created_by_ref revoked labels confidence lang external_references object_marking_refs granular_markings extensions),
    qw(relationship_type description source_ref target_ref start_time stop_time)
);

use constant STIX_OBJECT      => 'SRO';
use constant STIX_OBJECT_TYPE => 'relationship';

around BUILDARGS => sub {

    my ($orig, $class, @args) = @_;

    return {source_ref => $args[0], relationship_type => $args[1], target_ref => $args[2]}
        if @args == 3 && !ref $args[1];

    return $class->$orig(@args);

};


has relationship_type => (is => 'rw', required => 1);
has description       => (is => 'rw', isa      => Str);
has source_ref        => (is => 'rw', required => 1, isa => InstanceOf ['STIX::Common::Identifier', 'STIX::Object']);
has target_ref        => (is => 'rw', required => 1, isa => InstanceOf ['STIX::Common::Identifier', 'STIX::Object']);

has start_time => (
    is     => 'rw',
    isa    => InstanceOf ['STIX::Common::Timestamp'],
    coerce => sub { ref($_[0]) ? $_[0] : STIX::Common::Timestamp->new($_[0]) },
);

has stop_time => (
    is     => 'rw',
    isa    => InstanceOf ['STIX::Common::Timestamp'],
    coerce => sub { ref($_[0]) ? $_[0] : STIX::Common::Timestamp->new($_[0]) },
);

1;

=encoding utf-8

=head1 NAME

STIX::Relationship - STIX Relationship Object (SRO) - Relationship

=head1 SYNOPSIS

    use STIX::Relationship;

    my $relationship = STIX::Relationship->new();


=head1 DESCRIPTION

The Relationship object is used to link together two SDOs in order to
describe how they are related to each other.


=head2 METHODS

L<STIX::Relationship> inherits all methods from L<STIX::Common::Properties>
and implements the following new ones.

=over

=item STIX::Relationship->new(%properties)

Create a new instance of L<STIX::Relationship>.

=item $relationship->description

A description that helps provide context about the relationship.

=item $relationship->id

=item $relationship->relationship_type

The name used to identify the type of relationship.

=item $relationship->source_ref

The ID of the source (from) object.

=item $relationship->start_time

This optional timestamp represents the earliest time at which the
Relationship between the objects exists. If this property is a future
timestamp, at the time the updated property is defined, then this
represents an estimate by the producer of the intelligence of the earliest
time at which relationship will be asserted to be true.

=item $relationship->stop_time

The latest time at which the Relationship between the objects exists. If
this property is a future timestamp, at the time the updated property is
defined, then this represents an estimate by the producer of the
intelligence of the latest time at which relationship will be asserted to
be true.

=item $relationship->target_ref

The ID of the target (to) object.

=item $relationship->type

The type of this object, which MUST be the literal C<relationship>.

=back


=head2 HELPERS

=over

=item $relationship->TO_JSON

Encode the object in JSON.

=item $relationship->to_hash

Return the object HASH.

=item $relationship->to_string

Encode the object in JSON.

=item $relationship->validate

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
