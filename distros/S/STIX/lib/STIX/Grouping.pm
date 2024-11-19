package STIX::Grouping;

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
    'http://raw.githubusercontent.com/oasis-open/cti-stix2-json-schemas/stix2.1/schemas/sdos/grouping.json';

use constant PROPERTIES => (
    qw(type spec_version id created modified),
    qw(created_by_ref revoked labels confidence lang external_references object_marking_refs granular_markings extensions),
    qw(name description context object_refs)
);

use constant STIX_OBJECT      => 'SDO';
use constant STIX_OBJECT_TYPE => 'grouping';

has name        => (is => 'rw', required => 1, isa => Str);
has description => (is => 'rw', isa      => Str);
has context     => (is => 'rw', required => 1, isa => Enum [STIX::Common::OpenVocabulary->GROUPING_CONTEXT()]);
has object_refs => (
    is       => 'rw',
    required => 1,
    isa      => ArrayLike [InstanceOf ['STIX::Object', 'STIX::Common::Identifier']],
    default  => sub { [] }
);

1;


=encoding utf-8

=head1 NAME

STIX::Grouping - STIX Domain Object (SDO) - Grouping

=head1 SYNOPSIS

    use STIX::Grouping;

    my $grouping = STIX::Grouping->new();


=head1 DESCRIPTION

A Grouping object explicitly asserts that the referenced STIX Objects have
a shared content.


=head2 METHODS

L<STIX::Grouping> inherits all methods from L<STIX::Common::Properties>
and implements the following new ones.

=over

=item STIX::Grouping->new(%properties)

Create a new instance of L<STIX::Grouping>.

=item $grouping->context

A short description of the particular context shared by the content
referenced by the Grouping.

=item $grouping->description

A description which provides more details and context about the Grouping,
potentially including the purpose and key characteristics.

=item $grouping->id

=item $grouping->name

A name used to identify the Grouping.

=item $grouping->object_refs

The STIX Objects (SDOs and SROs) that  are referred to by this Grouping.

=item $grouping->type

The type of this object, which MUST be the literal C<grouping>.

=back


=head2 HELPERS

=over

=item $grouping->TO_JSON

Encode the object in JSON.

=item $grouping->to_hash

Return the object HASH.

=item $grouping->to_string

Encode the object in JSON.

=item $grouping->validate

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
