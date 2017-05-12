package Net::Works::Network;

use strict;
use warnings;

our $VERSION = '0.22';

use Carp qw( confess );
use List::AllUtils qw( any );
use Math::Int128 qw( uint128 );
use Net::Works::Address;
use Net::Works::Types qw( IPInt PrefixLength NetWorksAddress Str );
use Net::Works::Util
    qw( _integer_address_to_string _string_address_to_integer );
use Scalar::Util qw( blessed );
use Socket 1.99 qw( inet_pton AF_INET AF_INET6 );

use integer;

# Using this currently breaks overloading - see
# https://rt.cpan.org/Ticket/Display.html?id=50938
#
#use namespace::autoclean;

use overload (
    q{""} => '_overloaded_as_string',
    '<=>' => '_compare_overload',
    'cmp' => '_compare_overload',
);

use Moo;

with 'Net::Works::Role::IP';

has first => (
    is       => 'ro',
    isa      => NetWorksAddress,
    init_arg => undef,
    lazy     => 1,
    builder  => '_build_first',
);

has last => (
    is       => 'ro',
    isa      => NetWorksAddress,
    init_arg => undef,
    lazy     => 1,
    builder  => '_build_last',
);

has prefix_length => (
    is       => 'ro',
    isa      => PrefixLength,
    required => 1,
);

has _address_string => (
    is       => 'ro',
    isa      => Str,
    init_arg => undef,
    lazy     => 1,
    builder  => '_build_address_string',
);

has _subnet_integer => (
    is       => 'ro',
    isa      => IPInt,
    init_arg => undef,
    lazy     => 1,
    builder  => '_build_subnet_integer',
);

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;

    my $p = $class->$orig(@_);
    $p->{prefix_length} = delete $p->{mask_length}
        if exists $p->{mask_length};

    return $p;
};

sub mask_length { $_[0]->prefix_length() }

sub BUILD {
    my $self = shift;

    $self->_validate_ip_integer();

    my $max = $self->bits();
    if ( $self->prefix_length() > $max ) {
        confess $self->prefix_length()
            . ' is not a valid IP network prefix length';
    }

    return;
}

sub new_from_string {
    my $class = shift;
    my %p     = @_;

    die 'undef is not a valid IP network' unless defined $p{string};

    my ( $address, $prefix_length ) = split /\//, $p{string}, 2;

    my $version
        = $p{version} ? $p{version}
        : inet_pton( AF_INET6, $address ) ? 6
        :                                   4;

    if ( $version == 6 && inet_pton( AF_INET, $address ) ) {
        $prefix_length += 96;
        $address = '::' . $address;
    }

    my $integer = _string_address_to_integer( $address, $version );

    confess "$p{string} is not a valid IP network"
        unless defined $integer;

    return $class->new(
        _integer      => $integer,
        prefix_length => $prefix_length,
        version       => $version,
    );
}

sub new_from_integer {
    my $class = shift;
    my %p     = @_;

    my $integer = delete $p{integer};
    my $version = delete $p{version};

    $version ||= ref $integer ? 6 : 4;

    return $class->new(
        _integer => $integer,
        version  => $version,
        %p,
    );
}

sub _build_address_string {
    _integer_address_to_string( $_[0]->first_as_integer );
}

sub _build_subnet_integer {
    my $self = shift;

    return $self->_prefix_length_to_mask( $self->prefix_length() );
}

sub _prefix_length_to_mask {
    my $self          = shift;
    my $prefix_length = shift;

    # We need to special case 0 because left shifting a 128-bit integer by 128
    # bits does not produce 0.
    return $self->prefix_length() == 0
        ? 0
        : $self->_max()
        & ( $self->_max() << ( $self->bits - $prefix_length ) );
}

sub max_prefix_length {
    my $self = shift;

    my $base = $self->first()->as_integer();

    my $prefix_length = $self->prefix_length();

    my $bits = $self->bits;
    while ($prefix_length) {
        my $mask = $self->_prefix_length_to_mask($prefix_length);

        last if ( $base & $mask ) != $base;

        $prefix_length--;
    }

    return $prefix_length + 1;
}

sub max_mask_length { $_[0]->max_prefix_length() }

sub iterator {
    my $self = shift;

    my $version    = $self->version();
    my $current_ip = $self->first()->as_integer();
    my $last_ip    = $self->last()->as_integer();

    return sub {
        return if $current_ip > $last_ip;

        Net::Works::Address->new_from_integer(
            integer => $current_ip++,
            version => $version,
        );
    };
}

sub as_string {
    my $self = shift;

    return join '/', lc $self->_address_string(), $self->prefix_length();
}

sub _build_first {
    my $self = shift;

    my $int = $self->first_as_integer;

    return Net::Works::Address->new_from_integer(
        integer => $int,
        version => $self->version(),
    );
}

sub first_as_integer { $_[0]->_integer() & $_[0]->_subnet_integer() }

sub _build_last {
    my $self = shift;

    my $int = $self->last_as_integer;

    return Net::Works::Address->new_from_integer(
        integer => $int,
        version => $self->version(),
    );
}

sub last_as_integer {
    my $self = shift;

    return $self->_integer() | ( $self->_max() & ~$self->_subnet_integer() );
}

sub contains {
    my $self  = shift;
    my $thing = shift;

    my $first_integer;
    my $last_integer;
    if ( $thing->isa('Net::Works::Address') ) {
        $first_integer = $last_integer = $thing->as_integer();
    }
    elsif ( $thing->isa('Net::Works::Network') ) {
        $first_integer = $thing->first_as_integer();
        $last_integer  = $thing->last_as_integer();
    }
    else {
        confess
            "$thing is not a Net::Works::Address or Net::Works::Network object";
    }

    return $first_integer >= $self->first_as_integer()
        && $last_integer <= $self->last_as_integer();
}

## no critic (Subroutines::ProhibitBuiltinHomonyms)
sub split {
    my $self = shift;

    return () if $self->prefix_length() == $self->bits();

    my $first_int = $self->first_as_integer();
    my $last_int  = $self->last_as_integer();

    return (
        Net::Works::Network->new_from_integer(
            integer       => $first_int,
            prefix_length => $self->prefix_length() + 1,
        ),
        Net::Works::Network->new_from_integer(
            integer => ( $first_int + ( ( $last_int - $first_int ) / 2 ) )
                + 1,
            prefix_length => $self->prefix_length() + 1,
        )
    );
}
## use critic

sub is_single_address {
    my $self = shift;

    return ( $self->version == 4 && $self->prefix_length == 32 )
        || ( $self->version == 6 && $self->prefix_length == 128 );
}

sub range_as_subnets {
    my $class    = shift;
    my $first_ip = shift;
    my $last_ip  = shift;
    my $version  = shift || ( any { /:/ } $first_ip, $last_ip ) ? 6 : 4;

    $first_ip = Net::Works::Address->new_from_string(
        string  => $first_ip,
        version => $version,
    ) unless ref $first_ip;

    $last_ip = Net::Works::Address->new_from_string(
        string  => $last_ip,
        version => $version,
    ) unless ref $last_ip;

    my @ranges = $class->_remove_reserved_subnets_from_range(
        $first_ip->as_integer(),
        $last_ip->as_integer(),
        $version
    );

    my @subnets;
    for my $range (@ranges) {
        push @subnets, $class->_split_one_range( @{$range}, $version );
    }

    return @subnets;
}

{
    my @reserved_4 = qw(
        0.0.0.0/8
        10.0.0.0/8
        100.64.0.0/10
        127.0.0.0/8
        169.254.0.0/16
        172.16.0.0/12
        192.0.0.0/29
        192.0.2.0/24
        192.88.99.0/24
        192.168.0.0/16
        198.18.0.0/15
        198.51.100.0/24
        203.0.113.0/24
        224.0.0.0/4
        240.0.0.0/4
    );

    # ::/128 and ::1/128 are reserved under IPv6 but these are already covered
    # under 0.0.0.0/8
    my @reserved_6 = (
        @reserved_4, qw(
            100::/64
            2001::/23
            2001:db8::/32
            fc00::/7
            fe80::/10
            ff00::/8
            )
    );

    my %reserved_networks = (
        4 => [
            map { [ $_->first()->as_integer(), $_->last()->as_integer() ] }
                sort { $a->first <=> $b->first }
                map {
                Net::Works::Network->new_from_string(
                    string  => $_,
                    version => 4
                    )
                } @reserved_4,
        ],
        6 => [
            map { [ $_->first()->as_integer(), $_->last()->as_integer() ] }
                sort { $a->first <=> $b->first }
                map {
                Net::Works::Network->new_from_string(
                    string  => $_,
                    version => 6
                    )
                } @reserved_6,
        ],
    );

    sub _remove_reserved_subnets_from_range {
        my $class    = shift;
        my $first_ip = shift;
        my $last_ip  = shift;
        my $version  = shift;

        my @ranges;
        my $add_remaining = 1;

        for my $pn ( @{ $reserved_networks{$version} } ) {
            my $reserved_first = $pn->[0];
            my $reserved_last  = $pn->[1];

            next if ( $reserved_last <= $first_ip );
            last if ( $last_ip < $reserved_first );

            push @ranges, [ $first_ip, $reserved_first - 1 ]
                if $first_ip < $reserved_first;

            if ( $last_ip <= $reserved_last ) {
                $add_remaining = 0;
                last;
            }

            $first_ip = $reserved_last + 1;
        }

        push @ranges, [ $first_ip, $last_ip ] if $add_remaining;

        return @ranges;
    }
}

sub _split_one_range {
    my $class    = shift;
    my $first_ip = shift;
    my $last_ip  = shift;
    my $version  = shift;

    my @subnets;
    while ( $first_ip <= $last_ip ) {
        my $max_network = _max_subnet( $first_ip, $last_ip, $version );

        push @subnets, $max_network;

        $first_ip = $max_network->last_as_integer + 1;
    }

    return @subnets;
}

sub _max_subnet {
    my $ip      = shift;
    my $maxip   = shift;
    my $version = shift;

    my $prefix_length = $version == 6 ? 128 : 32;

    my $v = $ip;
    my $reverse_mask = $version == 6 ? uint128(1) : 1;

    while (( $v & 1 ) == 0
        && $prefix_length > 0
        && ( $ip | $reverse_mask ) <= $maxip ) {

        $prefix_length--;
        $v = $v >> 1;

        $reverse_mask = ( $reverse_mask << 1 ) | 1;
    }

    return Net::Works::Network->new_from_integer(
        integer       => $ip,
        prefix_length => $prefix_length,
        version       => $version,
    );
}

sub _compare_overload {
    my $self  = shift;
    my $other = shift;

    confess 'Cannot compare unless both objects are '
        . __PACKAGE__
        . ' objects'
        unless blessed $self
        && blessed $other
        && eval { $self->isa(__PACKAGE__) && $other->isa(__PACKAGE__) };

    my $cmp = (
               $self->first() <=> $other->first()
            or $self->prefix_length() <=> $other->prefix_length()
    );

    return shift() ? $cmp * -1 : $cmp;
}

__PACKAGE__->meta()->make_immutable();

1;

# ABSTRACT: An object representing a single IP address (4 or 6) subnet

__END__

=pod

=head1 NAME

Net::Works::Network - An object representing a single IP address (4 or 6) subnet

=head1 VERSION

version 0.22

=head1 SYNOPSIS

  use Net::Works::Network;

  my $network = Net::Works::Network->new_from_string( string => '192.0.2.0/24' );
  print $network->as_string();          # 192.0.2.0/24
  print $network->prefix_length();        # 24
  print $network->bits();               # 32
  print $network->version();            # 4

  my $first_address = $network->first();
  print $first_address->as_string();    # 192.0.2.0

  my $last_address = $network->last();
  print $last_address->as_string();     # 192.0.2.255

  my $iterator = $network->iterator();
  while ( my $ip = $iterator->() ) { print $ip . "\n"; }

  my $network_32 = Net::Works::Network->new_from_string( string => '192.0.2.4/32' );
  print $network_32->max_prefix_length(); # 30

  # All methods work with IPv4 and IPv6 subnets
  my $ipv6_network = Net::Works::Network->new_from_string( string => '2001:db8::/48' );

  my @subnets = Net::Works::Network->range_as_subnets( '192.0.2.1', '192.0.2.32' );
  print $_->as_string, "\n" for @subnets;
  # 192.0.2.1/32
  # 192.0.2.2/31
  # 192.0.2.4/30
  # 192.0.2.8/29
  # 192.0.2.16/28
  # 192.0.2.32/32

=head1 DESCRIPTION

Objects of this class represent an IP address network. It can handle both IPv4
and IPv6 subnets. It provides various methods for getting information about
the subnet.

For IPv6, it uses 128-bit integers (via Math::Int128) to represent the
numeric value of an address as needed.

=head1 METHODS

This class provides the following methods:

=head2 Net::Works::Network->new_from_string( ... )

This method takes a C<string> parameter and an optional C<version>
parameter. The C<string> parameter should be a string representation of an IP
address subnet, e.g., "192.0.2.0/24".

    my $network = Net::Works::Network->new_from_string(
        string => '192.0.2.0/24'
    );
    print $network->as_string; # 192.0.2.0/24

The C<version> parameter should be either C<4> or C<6>, but you don't really
need this unless you're trying to force a dotted quad to be interpreted as an
IPv6 network or to a force an IPv6 address colon-separated hex number to be
interpreted as an IPv4 network.

If you pass an IPv4 network but specify the version as C<6> then we will add
96 to the netmask.

    my $network = Net::Works::Network->new_from_string(
        string  => '192.0.2.0/24',
        version => 6,
    );
    print $network->as_string; # ::192.0.2.0/120

=head2 Net::Works::Network->new_from_integer( ... )

This method takes an C<integer> parameter, C<prefix_length> parameter, and
an optional C<version> parameter. The C<integer> parameter should be an
integer representation of an IP within the subnet. The C<prefix_length>
parameter should be an integer between 0 and 32 for IPv4 or 0 and 128 for
IPv6. The C<version> parameter should be either C<4> or C<6>.

Note that if you are passing an IPv4 address that you want treated as an IPv6
address you need to manually add 96 to the C<prefix_length> yourself.

=head2 $network->as_string()

Returns a string representation of the network like "192.0.2.0/24" or
"2001:db8::/48". The IP address in the string is the first address
within the subnet.

=head2 $network->version()

Returns a 4 or 6 to indicate whether this is an IPv4 or IPv6 network.

=head2 $network->prefix_length()

Returns the length of the netmask as an integer.

=head2 $network->bits()

Returns the number of bit of an address in the network, which is either 32
(IPv4) or 128 (IPv6).

=head2 $network->max_prefix_length()

This returns the maximum possible numeric subnet that this network could fit
in. In other words, the 192.0.2.0/28 subnet could be part of the 192.0.2.0/23
subnet, so this returns 23.

=head2 $network->first()

Returns the first IP in the network as an L<Net::Works::Address> object.

=head2 $network->first_as_integer()

Returns the first IP in the network as an integer. This may be a
L<Math::Int128> object.

=head2 $network->last()

Returns the last IP in the network as an L<Net::Works::Address> object.

=head2 $network->last_as_integer()

Returns the last IP in the network as an integer. This may be a
L<Math::Int128> object.

=head2 $network->is_single_address()

Returns true if the network contains just a single address (/32 in IPv4 or
/128 in IPv6).

=head2 $network->iterator()

This returns an anonymous sub that returns one IP address in the range each
time it's called.

For single address subnets (/32 or /128), this returns a single address.

When it has exhausted all the addresses in the network, it returns C<undef>

=head2 $network->contains($address_or_network)

This method accepts a single L<Net::Works::Address> or L<Net::Works::Network>
object. It returns true if the given address or network is contained by the
network it is called on. Note that a network always contains itself.

=head2 $network->split()

This returns a list of two new network objects representing the original
network split into two halves. For example, splitting C<192.0.2.0/24> returns
C<192.0.2.0/25> and C<192.0.2.128/25>.

If the original networks is a single address network (a /32 in IPv4 or /128 in
IPv6) then this method returns an empty list.

=head2 Net::Works::Network->range_as_subnets( $first_address, $last_address, $version )

Given two IP addresses as strings, this method breaks the range up into the
largest subnets that include all the IP addresses in the range (including the
two passed to this method).

This method also excludes any reserved subnets such as the
L<RFC1918|http://tools.ietf.org/html/rfc1918> IPv4 private address space,
L<RFC5735|http://tools.ietf.org/html/rfc5735> IPv4 special-use address space and
L<RFC5156|http://tools.ietf.org/html/rfc5156> IPv6 special-use address space.

An overview can be found at the IANA
L<IPv4|http://www.iana.org/assignments/iana-ipv4-special-registry/iana-ipv4-special-registry.xhtml>
and
L<IPv6|http://www.iana.org/assignments/iana-ipv6-special-registry/iana-ipv6-special-registry.xhtml>
special-purpose address registries.

The networks currently treated as reserved are:

    0.0.0.0/8
    10.0.0.0/8
    100.64.0.0/10
    127.0.0.0/8
    169.254.0.0/16
    172.16.0.0/12
    192.0.0.0/29
    192.0.2.0/24
    192.88.99.0/24
    192.168.0.0/16
    198.18.0.0/15
    198.51.100.0/24
    203.0.113.0/24
    224.0.0.0/4
    240.0.0.0/4

    100::/64
    2001::/23
    2001:db8::/32
    fc00::/7
    fe80::/10
    ff00::/8

This method works with both IPv4 and IPv6 addresses. You can pass an explicit
version as the final argument. If you don't, we check whether either address
contains a colon (:). If either of them does, we assume you want IPv6 subnets.

When given an IPv6 range that includes the first 32 bits of addresses (the
IPv4 space), both IPv4 I<and> IPv6 reserved networks are removed from the
range.

=head1 OVERLOADING

This class overloads comparison, allowing you to compare two objects and to
sort them (either as numbers or strings). Objects are compared based on the
first IP address in their networks, and then by prefix length if they have the
same starting address.

It also overloads stringification to call the C<< $network->as_string() >>
method.

=head1 DEPRECATED METHODS AND ATTRIBUTES

Prior to version 0.17, this package referred to the prefix length as mask
length. The C<mask_length()> and C<max_mask_length()> methods are deprecated,
and will probably start warning in a future release. In addition, passing a
C<mask_length> key to the C<new_from_integer()> constructor has been replaced
by C<prefix_length>. The old key will continue to work for now but may start
warning in a future release.

=head1 AUTHORS

=over 4

=item *

Dave Rolsky <autarch@urth.org>

=item *

Greg Oschwald <oschwald@cpan.org>

=item *

Olaf Alders <oalders@wundercounter.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by MaxMind, Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
