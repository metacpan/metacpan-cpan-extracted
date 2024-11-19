package STIX::Marking::TLP::Green;

use 5.010001;
use strict;
use warnings;
use utf8;

use STIX::Common::Timestamp;

use Moo;
extends 'STIX::Common::MarkingDefinition';

use constant MARKING_TYPE => 'tlp';

use constant SCHEMA =>
    'https://raw.githubusercontent.com/oasis-open/cti-stix2-json-schemas/stix2.1/schemas/common/marking-definition.json#/definitions/tlp_green';

has +id              => (is => 'ro', default => 'marking-definition--34098fce-860f-48ae-8e50-ebd3cc5e41da');
has +created         => (is => 'ro', default => sub { STIX::Common::Timestamp->new('2017-01-20T00:00:00') });
has +name            => (is => 'ro', default => 'TLP:GREEN');
has +definition_type => (is => 'ro', default => 'tlp');
has +definition      => (is => 'ro', default => sub { {tlp => 'green'} });

1;

=encoding utf-8

=head1 NAME

STIX::Marking::TLP::Green - STIX TLP:GREEN Statement marking

=head1 SYNOPSIS

    use STIX::Marking::TLP::Green;

    my $tlp = STIX::Marking::TLP::Green->new();


=head1 DESCRIPTION

The marking-definition object representing Traffic Light Protocol (TLP)
Green.


=head2 METHODS

L<STIX::Marking::TLP::Green> inherits all methods from L<STIX::Object>
and implements the following new ones.

=over

=item STIX::Marking::TLP::Green->new(%properties)

Create a new instance of L<STIX::Marking::TLP::Green>.

=item $tlp->created

=item $tlp->definition

=item $tlp->definition_type

=item $tlp->id

=item $tlp->name

=back


=head2 HELPERS

=over

=item $tlp->TO_JSON

Helper for JSON encoders.

=item $tlp->to_hash

Return the object HASH.

=item $tlp->to_string

Encode the object in JSON.

=item $tlp->validate

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
