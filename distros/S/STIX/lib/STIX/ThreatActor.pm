package STIX::ThreatActor;

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
    'http://raw.githubusercontent.com/oasis-open/cti-stix2-json-schemas/stix2.1/schemas/sdos/threat-actor.json';

use constant PROPERTIES => (
    qw(type spec_version id created modified),
    qw(created_by_ref revoked labels confidence lang external_references object_marking_refs granular_markings extensions),
    qw(name description threat_actor_types aliases first_seen last_seen roles goals sophistication resource_level primary_motivation secondary_motivations personal_motivations)
);

use constant STIX_OBJECT      => 'SDO';
use constant STIX_OBJECT_TYPE => 'threat-actor';

has name => (is => 'rw', isa => Str, required => 1);
has description => (is => 'rw', isa => Str);

has threat_actor_types => (
    is      => 'rw',
    isa     => ArrayLike [Enum [STIX::Common::OpenVocabulary->THREAT_ACTOR_TYPE()]],
    default => sub { STIX::Common::List->new }
);

has aliases => (is => 'rw', isa => ArrayLike [Str], default => sub { STIX::Common::List->new });

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

has roles => (
    is      => 'rw',
    isa     => ArrayLike [Enum [STIX::Common::OpenVocabulary->THREAT_ACTOR_ROLE()]],
    default => sub { STIX::Common::List->new }
);

has goals              => (is => 'rw', isa => ArrayLike [Str], default => sub { STIX::Common::List->new });
has sophistication     => (is => 'rw', isa => Enum [STIX::Common::OpenVocabulary->THREAT_ACTOR_SOPHISTICATION()]);
has resource_level     => (is => 'rw', isa => Enum [STIX::Common::OpenVocabulary->ATTACK_RESOURCE_LEVEL()]);
has primary_motivation => (is => 'rw', isa => Enum [STIX::Common::OpenVocabulary->ATTACK_MOTIVATION()]);

has secondary_motivations => (
    is      => 'rw',
    isa     => ArrayLike [Enum [STIX::Common::OpenVocabulary->ATTACK_MOTIVATION()]],
    default => sub { STIX::Common::List->new }
);

has personal_motivations => (
    is      => 'rw',
    isa     => ArrayLike [Enum [STIX::Common::OpenVocabulary->ATTACK_MOTIVATION()]],
    default => sub { STIX::Common::List->new }
);

1;

=encoding utf-8

=head1 NAME

STIX::ThreatActor - STIX Domain Object (SDO) - Threat Actor

=head1 SYNOPSIS

    use STIX::ThreatActor;

    my $threat_actor = STIX::ThreatActor->new();


=head1 DESCRIPTION

Threat Actors are actual individuals, groups, or organizations believed to
be operating with malicious intent.


=head2 METHODS

L<STIX::ThreatActor> inherits all methods from L<STIX::Common::Properties>
and implements the following new ones.

=over

=item STIX::ThreatActor->new(%properties)

Create a new instance of L<STIX::ThreatActor>.

=item $threat_actor->aliases

A list of other names that this Threat Actor is believed to use.

=item $threat_actor->description

A description that provides more details and context about the Threat
Actor.

=item $threat_actor->first_seen

The time that this Threat Actor was first seen.

=item $threat_actor->goals

The high level goals of this Threat Actor, namely, what are they trying to
do.

=item $threat_actor->id

=item $threat_actor->last_seen

The time that this Threat Actor was last seen.

=item $threat_actor->name

A name used to identify this Threat Actor or Threat Actor group.

=item $threat_actor->personal_motivations

The personal reasons, motivations, or purposes of the Threat Actor
regardless of organizational goals. (See C<ATTACK_MOTIVATION> in
L<STIX::Common::OpenVocabulary>)

=item $threat_actor->primary_motivation

The primary reason, motivation, or purpose behind this Threat Actor. (See
C<ATTACK_MOTIVATION> in L<STIX::Common::OpenVocabulary>)

=item $threat_actor->resource_level

This defines the organizational level at which this Threat Actor typically
works. (See C<ATTACK_RESOURCE_LEVEL> in L<STIX::Common::OpenVocabulary>)

=item $threat_actor->roles

This is a list of roles the Threat Actor plays. (See C<THREAT_ACTOR_ROLE>
in L<STIX::Common::OpenVocabulary>)

=item $threat_actor->secondary_motivations

The secondary reasons, motivations, or purposes behind this Threat Actor.
(See C<ATTACK_MOTIVATION> in L<STIX::Common::OpenVocabulary>)

=item $threat_actor->sophistication

The skill, specific knowledge, special training, or expertise a Threat
Actor must have to perform the attack. (See C<THREAT_ACTOR_SOPHISTICATION>
in L<STIX::Common::OpenVocabulary>)

=item $threat_actor->threat_actor_types

This field specifies the type of threat actor. (See C<THREAT_ACTOR_TYPE> in
L<STIX::Common::OpenVocabulary>)

=item $threat_actor->type

The type of this object, which MUST be the literal C<threat-actor>.

=back


=head2 HELPERS

=over

=item $threat_actor->TO_JSON

Encode the object in JSON.

=item $threat_actor->to_hash

Return the object HASH.

=item $threat_actor->to_string

Encode the object in JSON.

=item $threat_actor->validate

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

