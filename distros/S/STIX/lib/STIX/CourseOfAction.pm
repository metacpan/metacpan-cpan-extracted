package STIX::CourseOfAction;

use 5.010001;
use strict;
use warnings;
use utf8;

use Types::Standard qw(Str);

use Moo;
use namespace::autoclean;

extends 'STIX::Common::Properties';

use constant SCHEMA =>
    'http://raw.githubusercontent.com/oasis-open/cti-stix2-json-schemas/stix2.1/schemas/sdos/course-of-action.json';

use constant PROPERTIES => (
    qw(type spec_version id created modified),
    qw(created_by_ref revoked labels confidence lang external_references object_marking_refs granular_markings extensions),
    qw(name description action)
);

use constant STIX_OBJECT      => 'SDO';
use constant STIX_OBJECT_TYPE => 'course-of-action';

has name        => (is => 'rw', isa => Str, required => 1);
has description => (is => 'rw', isa => Str);
has action      => (is => 'ro', isa => sub { Carp::croak 'RESERVED' });

1;


=encoding utf-8

=head1 NAME

STIX::CourseOfAction - STIX Domain Object (SDO) - Course of Action

=head1 SYNOPSIS

    use STIX::CourseOfAction;

    my $course_of_action = STIX::CourseOfAction->new();


=head1 DESCRIPTION

A Course of Action is an action taken either to prevent an attack or to
respond to an attack that is in progress. 


=head2 METHODS

L<STIX::CourseOfAction> inherits all methods from L<STIX::Common::Properties>
and implements the following new ones.

=over

=item STIX::CourseOfAction->new(%properties)

Create a new instance of L<STIX::CourseOfAction>.

=item $course_of_action->description

A description that provides more details and context about this object,
potentially including its purpose and its key characteristics.

=item $course_of_action->action

=item $course_of_action->id

=item $course_of_action->name

The name used to identify the Course of Action.

=item $course_of_action->type

The type of this object, which MUST be the literal C<course-of-action>.

=back


=head2 HELPERS

=over

=item $course_of_action->TO_JSON

Encode the object in JSON.

=item $course_of_action->to_hash

Return the object HASH.

=item $course_of_action->to_string

Encode the object in JSON.

=item $course_of_action->validate

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
