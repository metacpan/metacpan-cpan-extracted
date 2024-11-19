package STIX::Observable::MACAddr;

use 5.010001;
use strict;
use warnings;
use utf8;

use Types::Standard qw(StrMatch);

use Moo;
use namespace::autoclean;

extends 'STIX::Observable';

use constant SCHEMA =>
    'http://raw.githubusercontent.com/oasis-open/cti-stix2-json-schemas/stix2.1/schemas/observables/mac-addr.json';

use constant PROPERTIES =>
    (qw(type id), qw(spec_version object_marking_refs granular_markings defanged extensions), qw(value));

use constant STIX_OBJECT      => 'SCO';
use constant STIX_OBJECT_TYPE => 'mac-addr';

has value => (is => 'rw', isa => StrMatch [qr/^([0-9a-f]{2}[:]){5}([0-9a-f]{2})$/], required => 1);

1;

=encoding utf-8

=head1 NAME

STIX::Observable::MACAddr - STIX Cyber-observable Object (SCO) - Media Access Control (MAC) Address

=head1 SYNOPSIS

    use STIX::Observable::MACAddr;

    my $mac_addr = STIX::Observable::MACAddr->new();


=head1 DESCRIPTION

The MAC Address Object represents a single Media Access Control (MAC)
address.


=head2 METHODS

L<STIX::Observable::MACAddr> inherits all methods from L<STIX::Observable>
and implements the following new ones.

=over

=item STIX::Observable::MACAddr->new(%properties)

Create a new instance of L<STIX::Observable::MACAddr>.

=item $mac_addr->id

=item $mac_addr->type

The value of this property MUST be C<mac-addr>.

=item $mac_addr->value

Specifies one or more mac addresses expressed using CIDR notation.

=back


=head2 HELPERS

=over

=item $mac_addr->TO_JSON

Encode the object in JSON.

=item $mac_addr->to_hash

Return the object HASH.

=item $mac_addr->to_string

Encode the object in JSON.

=item $mac_addr->validate

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
