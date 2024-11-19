package STIX::Opinion;

use 5.010001;
use strict;
use warnings;
use utf8;

use STIX::Common::Enum;
use STIX::Common::List;
use Types::Standard qw(Str InstanceOf Enum);
use Types::TypeTiny qw(ArrayLike);

use Moo;
use namespace::autoclean;

extends 'STIX::Common::Properties';

use constant SCHEMA =>
    'http://raw.githubusercontent.com/oasis-open/cti-stix2-json-schemas/stix2.1/schemas/sdos/opinion.json';

use constant PROPERTIES => (
    qw(type spec_version id created modified),
    qw(created_by_ref revoked labels confidence lang external_references object_marking_refs granular_markings extensions),
    qw(explanation authors opinion object_refs)
);

use constant STIX_OBJECT      => 'SDO';
use constant STIX_OBJECT_TYPE => 'opinion';

has authors => (is => 'rw', isa => ArrayLike [Str], default => sub { STIX::Common::List->new });
has opinion => (is => 'rw', isa => Enum [STIX::Common::Enum->OPINION()], required => 1);
has object_refs => (
    is       => 'rw',
    isa      => ArrayLike [InstanceOf ['STIX::Object', 'STIX::Common::Identifier']],
    required => 1,
    default  => sub { [] }
);

1;

=encoding utf-8

=head1 NAME

STIX::Opinion - STIX Domain Object (SDO) - Opinion

=head1 SYNOPSIS

    use STIX::Opinion;

    my $opinion = STIX::Opinion->new();


=head1 DESCRIPTION

An Opinion is an assessment of the correctness of the information in a STIX
Object produced by a different entity and captures the level of agreement
or disagreement using a fixed scale.


=head2 METHODS

L<STIX::Opinion> inherits all methods from L<STIX::Common::Properties>
and implements the following new ones.

=over

=item STIX::Opinion->new(%properties)

Create a new instance of L<STIX::Opinion>.

=item $opinion->authors

The name of the author(s) of this opinion (e.g., the analyst(s) that
created it).

=item $opinion->explanation

An explanation of why the producer has this Opinion.

=item $opinion->id

=item $opinion->object_refs

The STIX Objects (SDOs and SROs) that the opinion is being applied to.

=item $opinion->opinion

The opinion that the producer has about about all of the STIX Object(s)
listed in the object_refs property.

=item $opinion->type

The type of this object, which MUST be the literal C<opinion>.

=back


=head2 HELPERS

=over

=item $opinion->TO_JSON

Encode the object in JSON.

=item $opinion->to_hash

Return the object HASH.

=item $opinion->to_string

Encode the object in JSON.

=item $opinion->validate

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
