package STIX::Observable::IPv6Addr;

use 5.010001;
use strict;
use warnings;
use utf8;

use STIX::Common::List;
use Types::Standard qw(Str InstanceOf);
use Types::TypeTiny qw(ArrayLike);

use Moo;
use namespace::autoclean;

extends 'STIX::Observable';

use constant SCHEMA =>
    'http://raw.githubusercontent.com/oasis-open/cti-stix2-json-schemas/stix2.1/schemas/observables/ipv6-addr.json';

use constant PROPERTIES => (
    qw(type id),
    qw(spec_version object_marking_refs granular_markings defanged extensions),
    qw(value resolves_to_refs belongs_to_refs)
);

use constant STIX_OBJECT      => 'SCO';
use constant STIX_OBJECT_TYPE => 'ipv6-addr';

has value => (is => 'rw', isa => Str, required => 1);

has resolves_to_refs => (
    is      => 'rw',
    isa     => ArrayLike [InstanceOf ['STIX::Observable::MACAddr']],
    default => sub { STIX::Common::List->new }
);

has belongs_to_refs => (
    is      => 'rw',
    isa     => ArrayLike [InstanceOf ['STIX::Observable::AutonomousSystem']],
    default => sub { STIX::Common::List->new }
);

1;

=encoding utf-8

=head1 NAME

STIX::Observable::IPv6Addr - STIX Cyber-observable Object (SCO) - IPv6 Address

=head1 SYNOPSIS

    use STIX::Observable::IPv6Addr;

    my $ipv6_addr = STIX::Observable::IPv6Addr->new();


=head1 DESCRIPTION

The IPv6 Address Object represents one or more IPv6 addresses expressed
using CIDR notation.


=head2 METHODS

L<STIX::Observable::IPv6Addr> inherits all methods from L<STIX::Observable>
and implements the following new ones.

=over

=item STIX::Observable::IPv6Addr->new(%properties)

Create a new instance of L<STIX::Observable::IPv6Addr>.

=item $ipv6_addr->belongs_to_refs

Specifies a reference to one or more autonomous systems (AS) that the IPv6
address belongs to.

=item $ipv6_addr->id

=item $ipv6_addr->resolves_to_refs

Specifies a list of references to one or more Layer 2 Media Access Control
(MAC) addresses that the IPv6 address resolves to.

=item $ipv6_addr->type

The value of this property MUST be C<ipv6-addr>.

=item $ipv6_addr->value

Specifies one or more IPv6 addresses expressed using CIDR notation.

=back


=head2 HELPERS

=over

=item $ipv6_addr->TO_JSON

Encode the object in JSON.

=item $ipv6_addr->to_hash

Return the object HASH.

=item $ipv6_addr->to_string

Encode the object in JSON.

=item $ipv6_addr->validate

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
