package STIX::AttackPattern;

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
    'http://raw.githubusercontent.com/oasis-open/cti-stix2-json-schemas/stix2.1/schemas/sdos/attack-pattern.json';

use constant PROPERTIES => (
    qw(type spec_version id created modified),
    qw(created_by_ref revoked labels confidence lang external_references object_marking_refs granular_markings extensions),
    qw(name description aliases kill_chain_phases)
);

use constant STIX_OBJECT      => 'SDO';
use constant STIX_OBJECT_TYPE => 'attack-pattern';

has name        => (is => 'rw', isa => Str, required => 1);
has description => (is => 'rw', isa => Str);
has aliases     => (is => 'rw', isa => ArrayLike [Str], default => sub { STIX::Common::List->new });

has kill_chain_phases => (
    is      => 'rw',
    isa     => ArrayLike [InstanceOf ['STIX::Common::KillChainPhase']],
    default => sub { STIX::Common::List->new }
);

1;


=encoding utf-8

=head1 NAME

STIX::AttackPattern - STIX Domain Object (SDO) - Attack-pattern

=head1 SYNOPSIS

    use STIX::AttackPattern;

    my $attack_pattern = STIX::AttackPattern->new();


=head1 DESCRIPTION

Attack Patterns are a type of TTP that describe ways that adversaries
attempt to compromise targets. 


=head2 METHODS

L<STIX::AttackPattern> inherits all methods from L<STIX::Common::Properties>
and implements the following new ones.

=over

=item STIX::AttackPattern->new(%properties)

Create a new instance of L<STIX::AttackPattern>.

=item $attack_pattern->aliases

Alternative names used to identify this Attack Pattern.

=item $attack_pattern->description

A description that provides more details and context about the Attack
Pattern, potentially including its purpose and its key characteristics.

=item $attack_pattern->id

=item $attack_pattern->kill_chain_phases

The list of kill chain phases for which this attack pattern is used.

=item $attack_pattern->name

The name used to identify the Attack Pattern.

=item $attack_pattern->type

The type of this object, which MUST be the literal C<attack-pattern>.

=back


=head2 HELPERS

=over

=item $attack_pattern->TO_JSON

Encode the object in JSON.

=item $attack_pattern->to_hash

Return the object HASH.

=item $attack_pattern->to_string

Encode the object in JSON.

=item $attack_pattern->validate

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
