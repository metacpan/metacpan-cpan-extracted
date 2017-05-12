#!/usr/bin/perl

package Net::SixXS::Data::Tunnel;

use v5.010;
use strict;
use warnings;

use version; our $VERSION = version->declare("v0.1.1");

use Moose;
use MooseX::Role::JSONObject::Meta::Trait;

with 'MooseX::Role::JSONObject';

has id => (
	is => 'ro',
	isa => 'Str',
	required => 1,
	traits => ['JSONAttribute'],
	json_attr => 'TunnelId',
);

has password => (
	is => 'ro',
	isa => 'Str',
	required => 1,
	traits => ['JSONAttribute'],
	json_attr => 'Password',
);

has type => (
	is => 'ro',
	isa => 'Str',
	required => 1,
	traits => ['JSONAttribute'],
	json_attr => 'Type',
);

has mtu => (
	is => 'ro',
	isa => 'Int',
	required => 1,
	traits => ['JSONAttribute'],
	json_attr => 'Tunnel MTU',
);

has ipv6_local => (
	is => 'ro',
	isa => 'Str',
	required => 1,
	traits => ['JSONAttribute'],
	json_attr => 'IPv6 Endpoint',
);

has ipv6_pop => (
	is => 'ro',
	isa => 'Str',
	required => 1,
	traits => ['JSONAttribute'],
	json_attr => 'IPv6 POP',
);

has ipv4_local => (
	is => 'ro',
	isa => 'Str',
	required => 1,
	traits => ['JSONAttribute'],
	json_attr => 'IPv4 Endpoint',
);

has ipv4_pop => (
	is => 'ro',
	isa => 'Str',
	required => 1,
	traits => ['JSONAttribute'],
	json_attr => 'IPv4 POP',
);

has admin_state => (
	is => 'ro',
	isa => 'Str',
	required => 0,
	traits => ['JSONAttribute'],
	json_attr => 'AdminState',
);

has user_state => (
	is => 'ro',
	isa => 'Str',
	required => 0,
	traits => ['JSONAttribute'],
	json_attr => 'UserState',
);

has heartbeat => (
	is => 'ro',
	isa => 'Int',
	required => 0,
	traits => ['JSONAttribute'],
	json_attr => 'Heartbeat_Interval',
);

has ipv6_prefixlen => (
	is => 'ro',
	isa => 'Int',
	required => 0,
	traits => ['JSONAttribute'],
	json_attr => 'IPv6 PrefixLength',
);

has pop_id => (
	is => 'ro',
	isa => 'Str',
	required => 0,
	traits => ['JSONAttribute'],
	json_attr => 'POP Id',
);

has name => (
	is => 'ro',
	isa => 'Str',
	required => 0,
	traits => ['JSONAttribute'],
	json_attr => 'Tunnel Name',
);

sub to_text_lines($)
{
	my ($self) = @_;
	my $h = $self->to_json();

	return [map "\t$_:\t$h->{$_}", sort keys %{$h}];
}

sub to_text($)
{
	my ($self) = @_;

	return $self->id."\n".
	    join("\n", @{$self->to_text_lines})."\n";
}

no Moose;
1;

__END__


=encoding utf-8

=head1 NAME

Net::SixXS::Data::Tunnel - configuration data about a SixXS TIC tunnel

=head1 SYNOPSIS

  use Net::SixXS::Data::Tunnel;

  my $tun = Net::SixXS::Data::Tunnel->new(id => 'T00001', password => 'pass',
      type => 'ayiya', mtu => '1280',
      ipv6_local => '2001:0200:0:22::2', ipv6_pop => '2001:0200:0:22::1',
      ipv4_local => 'ayiya', ipv4_pop => '10.0.2.15');

  say for $tun->to_text_lines;
  # ...or...
  say $tun->to_text;

=head1 DESCRIPTION

The C<Net::SixXS::Data::Tunnel> class encapsulates information about
a SixXS IPv6-over-IPv4 tunnel as supplied by a TIC server.  Its data
members correspond to the fields in a TIC tunnel's description as
used by e.g. the SixXS AICCU client tool.

=head1 ATTRIBUTES

The C<Net::SixXS::Data::Tunnel> class has the following attributes with
the corresponding full-text fields in the TIC protocol response:

=over 4

=item C<id>

C<TunnelId> - the short text identifier of the tunnel, e.g. "T22928".

=item C<password>

C<Password> - the text string to be hashed and used as the authentication
token in the AYIYA protocol packets.

=item C<type>

C<Type> - the short text identifier of the tunnel type, e.g. "ayiya".

=item C<mtu>

C<Tunnel MTU> - the network Maximum Transfer Unit for the tunnel.

=item C<ipv6_local>

C<IPv6 Endpoint> - the IPv6 address of the local tunnel endpoint.

=item C<ipv6_pop>

C<IPv6 POP> - the IPv6 address of the server's endpoint of the tunnel.

=item C<ipv4_local>

C<IPv4 Endpoint> - usually the string "ayiya", but sometimes an IPv4
address to be used as the local external tunnel endpoint.

=item C<ipv4_pop>

C<IPv4 POP> - an IPv4 address to connect to as the server's endpoint of
the tunnel.

=back

=head1 METHODS

The C<Net::SixXS::Data::Tunnel> class contains the following methods for
creating objects and examining the objects' data:

=over 4

=item B<from_json (hashref)>

Inherited from L<MooseX::Role::JSONObject>.

Create a C<Net::SixXS::Data::Tunnel> object with attributes specified as
the full-text descriptions in the TIC protocol, e.g. C<IPv4 Endpoint> for
C<ipv4_local>.

=item B<to_json ()>

Inherited from L<MooseX::Role::JSONObject>.

Store the data of a C<Net::SixXS::Data::Tunnel> object into a hash with
the full-text descriptions in the TIC protocols as key names.

=item B<to_text_lines ()>

Return a reference to an array of text strings, each one representing
a single attribute's TIC full-text name and value.

=item B<to_text ()>

Return a string representing a text description of the tunnel: a line
containing the tunnel identifier, then lines corresponding to each of
the array elements from the C<to_text_lines()> method.

=back

=head1 SEE ALSO

The TIC client class: L<Net::SixXS::TIC::Client>

The TIC server class: L<Net::SixXS::TIC::Server>

=head1 LICENSE

Copyright (C) 2015  Peter Pentchev E<lt>roam@ringlet.netE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Peter Pentchev E<lt>roam@ringlet.netE<gt>

=cut
