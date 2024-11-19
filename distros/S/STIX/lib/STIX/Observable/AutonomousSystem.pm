package STIX::Observable::AutonomousSystem;

use 5.010001;
use strict;
use warnings;
use utf8;

use Types::Standard qw(Str Int);

use Moo;
use namespace::autoclean;

extends 'STIX::Observable';

use constant SCHEMA =>
    'http://raw.githubusercontent.com/oasis-open/cti-stix2-json-schemas/stix2.1/schemas/observables/autonomous-system.json';

use constant PROPERTIES =>
    (qw(type id), qw(spec_version object_marking_refs granular_markings defanged extensions), qw(number name rir),);

use constant STIX_OBJECT      => 'SCO';
use constant STIX_OBJECT_TYPE => 'autonomous-system';

has number => (is => 'rw', required => 1, isa => Int);
has name   => (is => 'rw', isa      => Str);
has rir    => (is => 'rw', isa      => Str);

1;

=encoding utf-8

=head1 NAME

STIX::Observable::AutonomousSystem - STIX Cyber-observable Object (SCO) - Autonomous System

=head1 SYNOPSIS

    use STIX::Observable::AutonomousSystem;

    my $autonomous_system = STIX::Observable::AutonomousSystem->new();


=head1 DESCRIPTION

The AS object represents the properties of an Autonomous Systems (AS).


=head2 METHODS

L<STIX::Observable::AutonomousSystem> inherits all methods from L<STIX::Observable>
and implements the following new ones.

=over

=item STIX::Observable::AutonomousSystem->new(%properties)

Create a new instance of L<STIX::Observable::AutonomousSystem>.

=item $autonomous_system->id

=item $autonomous_system->name

Specifies the name of the AS.

=item $autonomous_system->number

Specifies the number assigned to the AS. Such assignments are typically
performed by a Regional Internet Registries (RIR).

=item $autonomous_system->rir

Specifies the name of the Regional Internet Registry (RIR) that assigned
the number to the AS.

=item $autonomous_system->type

The value of this property MUST be C<autonomous-system>.

=back


=head2 HELPERS

=over

=item $autonomous_system->TO_JSON

Encode the object in JSON.

=item $autonomous_system->to_hash

Return the object HASH.

=item $autonomous_system->to_string

Encode the object in JSON.

=item $autonomous_system->validate

Validate the object using JSON Schema
(see L<STIX::Schema>).

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
