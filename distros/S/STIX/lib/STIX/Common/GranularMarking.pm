package STIX::Common::GranularMarking;

use 5.010001;
use strict;
use warnings;
use utf8;

use STIX::Common::List;
use Types::Standard qw(InstanceOf Str);
use Types::TypeTiny qw(ArrayLike);

use Moo;
use namespace::autoclean;

extends 'STIX::Object';

use constant SCHEMA =>
    'http://raw.githubusercontent.com/oasis-open/cti-stix2-json-schemas/stix2.1/schemas/common/granular-marking.json';

use constant PROPERTIES => qw(lang marking_ref selectors);

has lang        => (is => 'rw', isa      => Str);
has marking_ref => (is => 'rw', isa      => InstanceOf ['STIX::Common::MarkingDefinition']);
has selectors   => (is => 'rw', required => 1, isa => ArrayLike [Str], default => sub { STIX::Common::List->new });

1;

=encoding utf-8

=head1 NAME

STIX::Common::GranularMarking - STIX Granular Marking

=head1 SYNOPSIS

    use STIX::Common::GranularMarking;

    my $granular_marking = STIX::Common::GranularMarking->new();


=head1 DESCRIPTION

The C<granular-marking> type defines how the list of marking-definition
objects referenced by the marking_refs property to apply to a set of
content identified by the list of selectors in the selectors property.


=head2 METHODS

L<STIX::Common::GranularMarking> inherits all methods from L<STIX::Object>
and implements the following new ones.

=over

=item STIX::Common::GranularMarking->new(%properties)

Create a new instance of L<STIX::Common::GranularMarking>.

=item $granular_marking->lang

Identifies the language of the text identified by this marking.

=item $granular_marking->marking_ref

The C<marking_ref> property specifies the ID of the marking-definition object
that describes the marking.

=item $granular_marking->selectors

A list of selectors for content contained within the STIX object in which
this property appears.

=back


=head2 HELPERS

=over

=item $granular_marking->TO_JSON

Helper for JSON encoders.

=item $granular_marking->to_hash

Return the object HASH.

=item $granular_marking->to_string

Encode the object in JSON.

=item $granular_marking->validate

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
