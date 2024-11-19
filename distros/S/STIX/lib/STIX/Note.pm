package STIX::Note;

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
    'http://raw.githubusercontent.com/oasis-open/cti-stix2-json-schemas/stix2.1/schemas/sdos/note.json';

use constant PROPERTIES => (
    qw(type spec_version id created modified),
    qw(created_by_ref revoked labels confidence lang external_references object_marking_refs granular_markings extensions),
    qw(abstract content authors object_refs)
);

use constant STIX_OBJECT      => 'SDO';
use constant STIX_OBJECT_TYPE => 'note';

has abstract => (is => 'rw', isa => Str);
has content  => (is => 'rw', isa => Str, required => 1);
has authors  => (is => 'rw', isa => ArrayLike [Str], default => sub { STIX::Common::List->new });
has object_refs => (
    is       => 'rw',
    isa      => ArrayLike [InstanceOf ['STIX::Object', 'STIX::Common::Identifier']],
    required => 1,
    default  => sub { [] }
);

1;

=encoding utf-8

=head1 NAME

STIX::Note - STIX Domain Object (SDO) - Note

=head1 SYNOPSIS

    use STIX::Note;

    my $note = STIX::Note->new();


=head1 DESCRIPTION

A Note is a comment or note containing informative text to help explain the
context of one or more STIX Objects (SDOs or SROs) or to provide additional
analysis that is not contained in the original object.


=head2 METHODS

L<STIX::Note> inherits all methods from L<STIX::Common::Properties>
and implements the following new ones.

=over

=item STIX::Note->new(%properties)

Create a new instance of L<STIX::Note>.

=item $note->abstract

A brief summary of the note.

=item $note->authors

The name of the author(s) of this note (e.g., the analyst(s) that created
it).

=item $note->content

The content of the note.

=item $note->id

=item $note->object_refs

The STIX Objects (SDOs and SROs) that the note is being applied to.

=item $note->type

The type of this object, which MUST be the literal C<note>.

=back


=head2 HELPERS

=over

=item $note->TO_JSON

Encode the object in JSON.

=item $note->to_hash

Return the object HASH.

=item $note->to_string

Encode the object in JSON.

=item $note->validate

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
