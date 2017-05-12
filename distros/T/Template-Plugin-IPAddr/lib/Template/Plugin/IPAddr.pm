package Template::Plugin::IPAddr;
# ABSTRACT: Template::Toolkit plugin handling IP-addresses
$Template::Plugin::IPAddr::VERSION = '0.03';
use strict;
use warnings;
use base 'Template::Plugin';

use NetAddr::IP qw{ :lower };
use Scalar::Util qw{ blessed };

use overload '""' => sub { shift->cidr };

sub new {
  my ($class, $context, $arg) = @_;
  # When used as [% USE IPAddr %] or [% USE IPAddr(addr) %]
  # $context is a Template::Context object, and $arg is filled
  # with the arguments to IPAddr (undef resp. addr here).
  # When used as [% ip = NetAddr.new(addr) %], $context contain
  # the addr.
  my $addr = blessed $context ? $arg : $context;
  return bless { _cidr => NetAddr::IP->new($addr) }, ref $class || $class;
}

sub addr { return _compact(shift->{_cidr}) }

sub addr_cidr {
  my $self = shift;
  return $self->addr . '/' . $self->{_cidr}->masklen;
}

sub cidr {
  my $self = shift;

  # we can't use the cidr method because we want network/prefix,
  # and cidr returns addr/prefix.
  #
  # return an ipv6 address in compact format (with '::').
  return $self->network . '/' . $self->{_cidr}->masklen;
}

sub first    { return _compact(shift->{_cidr}->first) }
sub last     { return _compact(shift->{_cidr}->last) }
sub netmask  { return shift->{_cidr}->mask }
sub network  { return _compact(shift->{_cidr}->network) }
sub wildcard { return scalar shift->{_cidr}->wildcard }

# This sub takes an NetAddr::IP object and returns
# the address in short notation if IPv6, or the
# address as is if IPv4.
sub _compact {
  my $ip = shift;
  return $ip->addr =~ /:/ ? $ip->short : $ip->addr;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Template::Plugin::IPAddr - Template::Toolkit plugin handling IP-addresses

=head1 VERSION

version 0.03

=head1 SYNOPSIS

  # Create IPAddr object via USE directive...
  [% USE IPAddr %]
  [% USE IPAddr(prefix) %]

  # ...or via new
  [% ip = IPAddr.new(prefix) %]

  # Methods that return the different parts of the prefix
  [% IPAddr.addr %]
  [% IPAddr.addr_cidr %]
  [% IPAddr.cidr %]
  [% IPAddr.network %]
  [% IPAddr.netmask %]
  [% IPAddr.wildcard %]

  # Methods for retrieving usable IP-adresses from a prefix
  [% IPAddr.first %]
  [% IPAddr.last %]

=head1 DESCRIPTION

This module implements an C<IPAddr> class for handling IPv4 and IPv6-address
in an object-orientated way.
The module is based on L<NetAddr::IP> and works on IPv4 as well as
IPv6-addresses.

You can create a C<IPAddr> object via the C<USE> directive, adding any initial
prefix as an argument.

  [% USE IPAddr %]
  [% USE IPAddr(prefix) %]

Once you've got a C<IPAddr> object, you can use it as a prototype to create
other C<IPAddr> objects with the new() method.

  [% USE IPAddr %]
  [% ip = IPAddr.new(prefix) %]

After creating an C<IPaddr> object, you can use the supplied methods for
retrieving properties of the prefix.

  [% USE IPAddr('10.0.0.0/24') %]
  [% IPAddr.netmask %]   # 255.255.255.0
  [% IPAddr.first %]     # 10.0.0.1
  [% IPAddr.last %]      # 10.0.0.254

=head1 METHODS

=head2 new

Creates a new IPAddr object using an initial value passed as a positional
parameter. Any string which is accepted by L<< NetAddr::IP->new >> can be
used as a parameter.

  [% USE IPAddr %]
  [% USE IPAddr(prefix) %]
  [% ip = IPAddr.new(prefix) %]

Examples of (recommended) formats of initial parameters that can be used:

  # IPv4
  n.n.n.n             # Host address
  n.n.n.n/m           # CIDR notation
  n.n.n.n/m.m.m.m     # address + netmask

  # IPv6
  x:x:x:x:x:x:x:x     # Host address
  x:x:x:x:x:x:x:x/m   # CIDR notation
  ::n.n.n.n           # IPv4-compatible IPv6 address

When used as C<[% USE IPAddr %]> the prefix assigned internally is C<0.0.0.0/0>

=head2 addr

Returns the address part of the prefix as written in the initial value.

  [% USE IPAddr('10.1.1.1/24') %]
  [% IPAddr.addr %]  # 10.1.1.1

  [% USE IPAddr('2001:DB8::DEAD:BEEF') %]
  [% IPAddr.addr %]  # 2001:db8::dead:beef

=head2 addr_cidr

Returns the I<address> in CIDR notation, i.e. as C<address/prefixlen>.

  [% USE IPAddr('10.1.1.1/255.255.255.0') %]
  [% IPAddr.addr_cidr %]   # 10.1.1.1/24

  [% USE IPAddr('2001:db8:a:b:c:d:e:f/48') %]
  [% IPAddr.addr_cidr %]  # 2001:db8:a:b:c:d:e:f/48

=head2 cidr

Returns the I<prefix> in CIDR notation, i.e. as C<network/prefixlen>.

  [% USE IPAddr('10.1.1.1/255.255.255.0') %]
  [% IPAddr.cidr %]   # 10.1.1.0/24

  [% USE IPAddr('2001:db8:a:b:c:d:e:f/48') %]
  [% IPAddr.cidr %]  # 2001:db8:a::/48

Note that differs from the C<cidr> method in L<NetAddr::IP> (which
returns C<address/prefixlen>). You can retrieve an address on that
format by using the L</addr_cidr> method.

=head2 first

Returns the first usable IP-address within the prefix.

  [% USE IPAddr('10.0.0.0/16') %]
  [% IPAddr.first %]   # 10.0.0.1

=head2 last

Returns the last usable IP-address within the prefix.

  [% USE IPAddr('10.0.0.0/16') %]
  [% IPAddr.last %]   # 10.0.255.254

=head2 network

Returns the network part of the prefix.

  [% USE IPAddr('10.1.1.1/24') %]
  [% IPAddr.network %]   # 10.1.1.0

  [% USE IPAddr('2001:db8:a:b:c:d:e:f/48') %]
  [% IPAddr.network %]  # 2001:db8:a::

=head2 netmask

Returns the netmask part of the prefix.

  [% USE IPAddr('10.1.1.1/24') %]
  [% IPAddr.netmask %]   # 255.255.255.0

=head2 wildcard

Returns the netmask of the prefix in wildcard format (the netmask
with all bits inverted).

  [% USE IPAddr('10.1.1.1/24') %]
  [% IPAddr.wildcard %]   # 0.0.0.255

=head1 NOTES

Please note the subtle, but important, difference between C<addr_cidr>
and C<cidr> (see L</cidr> for an explanation).

Not all methods are applicable in a IPv6 context. For example there
are no notation of L<netmask> or L<wildcard> in IPv6, and the L<first>
and L<last> returns values of no use.

When using IPv6 mapped IPv4 addresses, the "dot notation" is lost
in the process. For example:

  [% USE IPAddr('::192.0.2.1') %]

then

  [% IPAddr.addr %]

will print C<::c000:201>.

=head1 SEE ALSO

L<Template>,
L<Template::Manual::Config/PLUGINS>,
L<NetAddr::IP>

=head1 AUTHOR

Per Carlson <pelle@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Per Carlson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
