package STIX::Infrastructure;

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
    'http://raw.githubusercontent.com/oasis-open/cti-stix2-json-schemas/stix2.1/schemas/sdos/infrastructure.json';

use constant PROPERTIES => (
    qw(type spec_version id created modified),
    qw(created_by_ref revoked labels confidence lang external_references object_marking_refs granular_markings extensions),
    qw(name description infrastructure_types aliases kill_chain_phases first_seen last_seen)
);

use constant STIX_OBJECT      => 'SDO';
use constant STIX_OBJECT_TYPE => 'infrastructure';

has name => (is => 'rw', required => 1, isa => Str);
has description => (is => 'rw', isa => Str);

has infrastructure_types => (
    is      => 'rw',
    isa     => ArrayLike [Enum [STIX::Common::OpenVocabulary->INFRASTRUCTURE_TYPE()]],
    default => sub { STIX::Common::List->new }
);

has aliases => (is => 'rw', isa => ArrayLike [Str], default => sub { STIX::Common::List->new });
has kill_chain_phases =>
    (is => 'rw', isa => ArrayLike [InstanceOf ['STIX::KillChainPhase']], default => sub { STIX::Common::List->new });

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

1;

=encoding utf-8

=head1 NAME

STIX::Infrastructure - STIX Domain Object (SDO) - Infrastructure

=head1 SYNOPSIS

    use STIX::Infrastructure;

    my $infrastructure = STIX::Infrastructure->new();


=head1 DESCRIPTION

Infrastructure objects describe systems, software services, and associated
physical or virtual resources.


=head2 METHODS

L<STIX::Infrastructure> inherits all methods from L<STIX::Common::Properties>
and implements the following new ones.

=over

=item STIX::Infrastructure->new(%properties)

Create a new instance of L<STIX::Infrastructure>.

=item $infrastructure->aliases

Alternative names used to identify this Infrastructure.

=item $infrastructure->description

A description that provides more details and context about this
Infrastructure potentially including its purpose and its key
characteristics.

=item $infrastructure->first_seen

The time that this infrastructure was first seen performing malicious
activities.

=item $infrastructure->id

=item $infrastructure->infrastructure_types

This field is an Open Vocabulary that specifies the type of infrastructure.
(See C<INFRASTRUCTURE_TYPE> in L<STIX::Common::OpenVocabulary>)

=item $infrastructure->kill_chain_phases

The list of kill chain phases for which this infrastructure is used.

=item $infrastructure->last_seen

The time that this infrastructure was last seen performing malicious
activities.

=item $infrastructure->name

The name used to identify the Infrastructure.

=item $infrastructure->type

The type of this object, which MUST be the literal C<infrastructure>.

=back


=head2 HELPERS

=over

=item $infrastructure->TO_JSON

Encode the object in JSON.

=item $infrastructure->to_hash

Return the object HASH.

=item $infrastructure->to_string

Encode the object in JSON.

=item $infrastructure->validate

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
