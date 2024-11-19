package STIX::Observable::NetworkTraffic;

use 5.010001;
use strict;
use warnings;
use utf8;

use STIX::Common::List;
use Types::Standard qw(Str Bool HashRef Int InstanceOf);
use Types::TypeTiny qw(ArrayLike);

use Moo;
use namespace::autoclean;

extends 'STIX::Observable';

use constant SCHEMA =>
    'http://raw.githubusercontent.com/oasis-open/cti-stix2-json-schemas/stix2.1/schemas/observables/network-traffic.json';

use constant PROPERTIES => (
    qw(type id),
    qw(spec_version object_marking_refs granular_markings defanged extensions),
    qw(start end is_active src_ref dst_ref src_port dst_port protocols src_byte_count dst_byte_count src_packets dst_packets ipfix src_payload_ref dst_payload_ref encapsulates_refs encapsulated_by_ref),
);

use constant STIX_OBJECT      => 'SCO';
use constant STIX_OBJECT_TYPE => 'network-traffic';

has start => (
    is     => 'rw',
    isa    => InstanceOf ['STIX::Common::Timestamp'],
    coerce => sub { ref($_[0]) ? $_[0] : STIX::Common::Timestamp->new($_[0]) },
);

has end => (
    is     => 'rw',
    isa    => InstanceOf ['STIX::Common::Timestamp'],
    coerce => sub { ref($_[0]) ? $_[0] : STIX::Common::Timestamp->new($_[0]) },
);

has is_active => (is => 'rw', isa => Bool);

has src_ref => (
    is  => 'rw',
    isa => InstanceOf [
        'STIX::Observable::IPv4Addr', 'STIX::Observable::IPv6Addr',
        'STIX::Observable::MACAddr',  'STIX::Observable::DomainName',
        'STIX::Common::Identifier'
    ]
);

has dst_ref => (
    is  => 'rw',
    isa => InstanceOf [
        'STIX::Observable::IPv4Addr', 'STIX::Observable::IPv6Addr',
        'STIX::Observable::MACAddr',  'STIX::Observable::DomainName',
        'STIX::Common::Identifier'
    ]
);

has src_port        => (is => 'rw', isa => Int);
has dst_port        => (is => 'rw', isa => Int);
has protocols       => (is => 'rw', isa => ArrayLike [Str], default => sub { STIX::Common::List->new });
has src_byte_count  => (is => 'rw', isa => Int);
has dst_byte_count  => (is => 'rw', isa => Int);
has src_packets     => (is => 'rw', isa => Int);
has dst_packets     => (is => 'rw', isa => Int);
has ipfix           => (is => 'rw', isa => HashRef);
has src_payload_ref => (is => 'rw', isa => InstanceOf ['STIX::Observable::Artifact', 'STIX::Common::Identifier']);
has dst_payload_ref => (is => 'rw', isa => InstanceOf ['STIX::Observable::Artifact', 'STIX::Common::Identifier']);

has encapsulates_refs => (
    is      => 'rw',
    isa     => ArrayLike [InstanceOf ['STIX::Observable::NetworkTraffic', 'STIX::Common::Identifier']],
    default => sub { STIX::Common::List->new }
);

has encapsulated_by_ref =>
    (is => 'rw', isa => InstanceOf ['STIX::Observable::NetworkTraffic', 'STIX::Common::Identifier']);

1;

=encoding utf-8

=head1 NAME

STIX::Observable::NetworkTraffic - STIX Cyber-observable Object (SCO) - Network Traffic

=head1 SYNOPSIS

    use STIX::Observable::NetworkTraffic;

    my $network_traffic = STIX::Observable::NetworkTraffic->new();


=head1 DESCRIPTION

The Network Traffic Object represents arbitrary network traffic that
originates from a source and is addressed to a destination.


=head2 METHODS

L<STIX::Observable::NetworkTraffic> inherits all methods from L<STIX::Observable>
and implements the following new ones.

=over

=item STIX::Observable::NetworkTraffic->new(%properties)

Create a new instance of L<STIX::Observable::NetworkTraffic>.

=item $network_traffic->dst_byte_count

Specifies the number of bytes sent from the destination to the source.

=item $network_traffic->dst_packets

Specifies the number of packets sent destination to the source.

=item $network_traffic->dst_payload_ref

Specifies the bytes sent from the source to the destination.

=item $network_traffic->dst_port

Specifies the destination port used in the network traffic, as an integer.
The port value MUST be in the range of 0 - 65535.

=item $network_traffic->dst_ref

Specifies the destination of the network traffic, as a reference to an
Observable Object.

=item $network_traffic->encapsulated_by_ref

Links to another network-traffic object which encapsulates this object.

=item $network_traffic->encapsulates_refs

Links to other network-traffic objects encapsulated by a network-traffic.

=item $network_traffic->end

Specifies the date/time the network traffic ended, if known.

=item $network_traffic->extensions

The Network Traffic Object defines the following extensions. In addition to
these, producers MAY create their own. Extensions: http-ext, tcp-ext,
icmp-ext, socket-ext

=item $network_traffic->id

=item $network_traffic->ipfix

Specifies any IP Flow Information Export (IPFIX) data for the traffic.

=item $network_traffic->protocols

Specifies the protocols observed in the network traffic, along with their
corresponding state.

=item $network_traffic->src_byte_count

Specifies the number of bytes sent from the source to the destination.

=item $network_traffic->src_packets

Specifies the number of packets sent from the source to the destination.

=item $network_traffic->src_payload_ref

Specifies the bytes sent from the source to the destination.

=item $network_traffic->src_port

Specifies the source port used in the network traffic, as an integer. The
port value MUST be in the range of 0 - 65535.

=item $network_traffic->src_ref

Specifies the source of the network traffic, as a reference to an
Observable Object.

=item $network_traffic->start

Specifies the date/time the network traffic was initiated, if known.

=item $network_traffic->type

The value of this property MUST be C<network-traffic>.

=back


=head2 HELPERS

=over

=item $network_traffic->TO_JSON

Encode the object in JSON.

=item $network_traffic->to_hash

Return the object HASH.

=item $network_traffic->to_string

Encode the object in JSON.

=item $network_traffic->validate

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
