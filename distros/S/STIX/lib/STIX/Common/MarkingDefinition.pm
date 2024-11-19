package STIX::Common::MarkingDefinition;

use 5.010001;
use strict;
use warnings;
use utf8;

use Types::Standard qw(Str HashRef);

use Moo;
use namespace::autoclean;

extends 'STIX::Common::Properties';

use constant SCHEMA =>
    'http://raw.githubusercontent.com/oasis-open/cti-stix2-json-schemas/stix2.1/schemas/common/marking-definition.json';

use constant PROPERTIES => (
    qw(type spec_version id created),
    qw(created_by_ref external_references object_marking_refs granular_markings extensions),
    qw(name definition_type definition)
);

use constant STIX_OBJECT      => 'SMO';
use constant STIX_OBJECT_TYPE => 'marking-definition';

has name            => (is => 'rw', isa => Str);
has definition_type => (is => 'rw', isa => Str);
has definition      => (is => 'rw');


1;

=encoding utf-8

=head1 NAME

STIX::Common::MarkingDefinition - STIX Marking Definition

=head1 SYNOPSIS

    use STIX::Common::MarkingDefinition;

    my $marking_definition = STIX::Common::MarkingDefinition->new();


=head1 DESCRIPTION

The marking-definition object represents a specific marking.


=head2 METHODS

L<STIX::Common::MarkingDefinition> inherits all methods from L<STIX::Object>
and implements the following new ones.

=over

=item STIX::Common::MarkingDefinition->new(%properties)

Create a new instance of L<STIX::Common::MarkingDefinition>.

=item $marking_definition->created

The created property represents the time at which the first version of this
Marking Definition object was created.

=item $marking_definition->created_by_ref

The created_by_ref property specifies the ID of the identity object that
describes the entity that created this Marking Definition.

=item $marking_definition->extensions

Specifies any extensions of the object, as a dictionary.

=item $marking_definition->external_references

A list of external references which refers to non-STIX information.

=item $marking_definition->granular_markings

The granular_markings property specifies a list of granular markings
applied to this object.

=item $marking_definition->name

A name used to identify the Marking Definition.

=item $marking_definition->object_marking_refs

The object_marking_refs property specifies a list of IDs of
marking-definition objects that apply to this Marking Definition.

=item $marking_definition->spec_version

The version of the STIX specification used to represent this object.

=item $marking_definition->type

The type of this object, which MUST be the literal C<marking-definition>.

=item $marking_definition->definition

The definition property contains the marking object itself.

=item $marking_definition->definition_type

The definition_type property identifies the type of Marking Definition.

=back


=head2 HELPERS

=over

=item $marking_definition->TO_JSON

Helper for JSON encoders.

=item $marking_definition->to_hash

Return the object HASH.

=item $marking_definition->to_string

Encode the object in JSON.

=item $marking_definition->validate

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

