package STIX::Incident;

use 5.010001;
use strict;
use warnings;
use utf8;

use Types::Standard qw(Str);

use Moo;
use namespace::autoclean;

extends 'STIX::Common::Properties';

use constant SCHEMA =>
    'http://raw.githubusercontent.com/oasis-open/cti-stix2-json-schemas/stix2.1/schemas/sdos/incident.json';

use constant PROPERTIES => (
    qw(type spec_version id created modified),
    qw(created_by_ref revoked labels confidence lang external_references object_marking_refs granular_markings extensions),
    qw(name description)
);

use constant STIX_OBJECT      => 'SDO';
use constant STIX_OBJECT_TYPE => 'incident';

has name => (is => 'rw', isa => Str, required => 1);
has description => (is => 'rw', isa => Str);

1;


=encoding utf-8

=head1 NAME

STIX::Incident - STIX Domain Object (SDO) - Incident

=head1 SYNOPSIS

    use STIX::Incident;

    my $incident = STIX::Incident->new();


=head1 DESCRIPTION

The Incident object in STIX 2.1 is a stub, to be expanded in future STIX 2
releases.


=head2 METHODS

L<STIX::Incident> inherits all methods from L<STIX::Common::Properties>
and implements the following new ones.

=over

=item STIX::Incident->new(%properties)

Create a new instance of L<STIX::Incident>.

=item $incident->description

A description that provides more details and context about the Incident.

=item $incident->id

=item $incident->name

The name used to identify the Incident.

=item $incident->type

The type of this object, which MUST be the literal C<incident>.

=back


=head2 HELPERS

=over

=item $incident->TO_JSON

Encode the object in JSON.

=item $incident->to_hash

Return the object HASH.

=item $incident->to_string

Encode the object in JSON.

=item $incident->validate

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
