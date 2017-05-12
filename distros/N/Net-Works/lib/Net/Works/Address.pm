package Net::Works::Address;

use strict;
use warnings;

our $VERSION = '0.22';

use Carp qw( confess );
use Math::Int128 0.06 qw( uint128 uint128_to_hex uint128_to_number );
use Net::Works::Types qw( PackedBinary Str );
use Net::Works::Util qw(
    _integer_address_to_binary
    _integer_address_to_string
    _string_address_to_integer
    _validate_ip_string
);
use Scalar::Util qw( blessed );
use Socket 1.99 qw( AF_INET AF_INET6 inet_pton inet_ntop );

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

has _binary => (
    is      => 'ro',
    reader  => 'as_binary',
    isa     => PackedBinary,
    lazy    => 1,
    builder => '_build_binary',
);

has _string => (
    is      => 'ro',
    reader  => 'as_string',
    isa     => Str,
    lazy    => 1,
    builder => '_build_string',
);

sub BUILD {
    my $self = shift;

    $self->_validate_ip_integer();

    return;
}

sub new_from_string {
    my $class = shift;
    my %p     = @_;

    my $str     = delete $p{string};
    my $version = delete $p{version};

    if ( defined $str && inet_pton( AF_INET, $str ) ) {
        $version ||= 4;
        $str = '::' . $str if $version == 6;
    }
    else {
        $version ||= 6;
        _validate_ip_string( $str, $version );
    }

    return $class->new(
        _integer => _string_address_to_integer( $str, $version ),
        version  => $version,
        %p,
    );
}

sub new_from_integer {
    my $class = shift;
    my %p     = @_;

    my $int     = delete $p{integer};
    my $version = delete $p{version};
    $version ||= ref $int ? 6 : 4;

    return $class->new(
        _integer => $int,
        version  => $version,
        %p,
    );
}

sub _build_string {
    my $self = shift;

    return _integer_address_to_string( $self->_integer() );
}

sub _build_binary { _integer_address_to_binary( $_[0]->as_integer() ) }

sub as_integer { $_[0]->_integer() }

sub as_ipv4_string {
    my $self = shift;

    return $self->as_string() if $self->version() == 4;

    confess
        'Cannot represent IP address larger than 2**32-1 as an IPv4 string'
        if $self->as_integer() >= 2**32;

    return __PACKAGE__->new_from_integer(
        integer => $self->as_integer(),
        version => 4,
    )->as_string();
}

sub as_bit_string {
    my $self = shift;

    if ( $self->version == 6 ) {
        my $hex = uint128_to_hex( $self->as_integer() );
        my @ha  = $hex =~ /.{8}/g;
        return join q{}, map { sprintf( '%032b', hex($_) ) } @ha;
    }
    else {
        return sprintf( '%032b', $self->as_integer() );
    }
}

sub prefix_length { $_[0]->bits() }

sub mask_length { $_[0]->prefix_length() }

sub next_ip {
    my $self = shift;

    confess "$self is the last address in its range"
        if $self->as_integer() == $self->_max;

    return __PACKAGE__->new_from_integer(
        integer => $self->as_integer() + 1,
        version => $self->version(),
    );
}

sub previous_ip {
    my $self = shift;

    confess "$self is the first address in its range"
        if $self->as_integer() == 0;

    return __PACKAGE__->new_from_integer(
        integer => $self->as_integer() - 1,
        version => $self->version(),
    );
}

sub _compare_overload {
    my $self  = shift;
    my $other = shift;
    my $flip  = shift() ? -1 : 1;

    confess 'Cannot compare unless both objects are '
        . __PACKAGE__
        . ' objects'
        unless blessed $self
        && blessed $other
        && eval { $self->isa(__PACKAGE__) && $other->isa(__PACKAGE__) };

    return $flip * ( $self->as_integer() <=> $other->as_integer() );
}

__PACKAGE__->meta()->make_immutable();

1;

# ABSTRACT: An object representing a single IP (4 or 6) address

__END__

=pod

=head1 NAME

Net::Works::Address - An object representing a single IP (4 or 6) address

=head1 VERSION

version 0.22

=head1 SYNOPSIS

  use Net::Works::Address;

  my $ip = Net::Works::Address->new_from_string( string => '192.0.2.1' );
  print $ip->as_string();     # 192.0.2.1
  print $ip->as_integer();    # 3221225985
  print $ip->as_binary();     # 4-byte packed form of the address
  print $ip->as_bit_string(); # 11000000000000000000001000000001
  print $ip->version();       # 4
  print $ip->prefix_length();   # 32

  my $next = $ip->next_ip();     # 192.0.2.2
  my $prev = $ip->previous_ip(); # 192.0.2.0

  if ( $next > $ip ) { print $ip->as_string(); }

  my @sorted = sort $next, $prev, $ip;

  my $ipv6 = Net::Works::Address->new_from_string( string => '2001:db8::1234' );
  print $ipv6->as_integer(); # 42540766411282592856903984951653831220

  my $ip_from_int = Net::Works::Address->new_from_integer(
      integer => "42540766411282592856903984951653831220"
  );

=head1 DESCRIPTION

Objects of this class represent a single IP address. It can handle both IPv4
and IPv6 addresses. It provides various methods for getting information about
the address, and also overloads the objects so that addresses can be compared
as integers.

For IPv6, it uses 128-bit integers (via Math::Int128) to represent the
numeric value of an address.

=head1 METHODS

This class provides the following methods:

=head2 Net::Works::Address->new_from_string( ... )

This method takes a C<string> parameter and an optional C<version>
parameter. The C<string> parameter should be a string representation of an IP
address.

The C<version> parameter should be either C<4> or C<6>, but you don't really need
this unless you're trying to force a dotted quad to be interpreted as an IPv6
address or to a force an IPv6 address colon-separated hex number to be
interpreted as an IPv4 address.

=head2 Net::Works::Address->new_from_integer( ... )

This method takes a C<integer> parameter and an optional C<version>
parameter. The C<integer> parameter should be an integer representation of an
IP address.

The C<version> parameter should be either C<4> or C<6>. Unlike with strings,
you'll need to set the version explicitly to get an IPv6 address.

=head2 $ip->as_string()

Returns a string representation of the address in the same format as
inet_ntop, e.g., "192.0.2.1", "::192.0.2.1", or "2001:db8::1234".

=head2 $ip->as_integer()

Returns the address as an integer. For IPv6 addresses, this is returned as a
L<Math::Int128> object, regardless of the value.

=head2 $ip->as_binary()

Returns the packed binary form of the address (4 or 16 bytes).

=head2 $ip->as_bit_string()

Returns the address as a string of 1's and 0's, like
"00000000000000000000000000010000".

=head2 $ip->as_ipv4_string()

This returns a dotted quad representation of an address, even if it's an IPv6
address. However, this will die if the address is greater than the max value
of an IPv4 address (2**32 - 1). It's primarily useful for debugging.

=head2 $ip->version()

Returns a 4 or 6 to indicate whether this is an IPv4 or IPv6 address.

=head2 $ip->prefix_length()

Returns the prefix length for the IP address, which is either 32 (IPv4) or 128
(IPv6).

=head2 $ip->bits()

An alias for C<< $ip->prefix_length() >>. This helps make addresses & network
objects interchangeable in some cases.

=head2 $ip->next_ip()

Returns the numerically next IP, regardless of whether or not it's in the same
subnet as the current IP.

This will throw an error if the current IP address it the last address in its
IP range.

=head2 $ip->previous_ip()

Returns the numerically previous IP, regardless of whether or not it's in the
same subnet as the current IP.

This will throw an error if the current IP address it the first address in
its IP range (address 0).

=head1 OVERLOADING

This class overloads comparison, allowing you to compare two objects and to
sort them (either as numbers or strings).

It also overloads stringification to call the C<< $ip->as_string() >> method.

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
