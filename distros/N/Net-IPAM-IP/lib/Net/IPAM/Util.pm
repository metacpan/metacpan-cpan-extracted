package Net::IPAM::Util;

use 5.10.0;
use strict;
use warnings;
use utf8;

use Carp   ();
use Socket ();

use Exporter 'import';
our @EXPORT_OK = qw(incr_n decr_n inet_ntop_pp inet_pton_pp);

=head1 NAME

Net::IPAM::Util - A selection of general utility subroutines for Net::IPAM

=head1 SYNOPSIS

  use Net::IPAM::Util qw(incr_n inet_ntop_pp inet_pton_pp);

  $n = incr_n("\x0a\x00\x00\x01");                                 # 10.0.0.2
  $n = incr_n( pack( 'n8', 0x2001, 0xdb8, 0, 0, 0, 0, 0, 1 ) );    # 2001:db8::2

  $n = decr_n("\x0a\x00\x00\x01");                                 # 10.0.0.0
  $n = decr_n( pack( 'n8', 0x2001, 0xdb8, 0, 0, 0, 0, 0, 1 ) );    # 2001:db8::

  $n = inet_pton_pp( AF_INET6, '2001:db8::fe1' );
  say inet_ntop_pp( AF_INET, "\x0a\x00\x00\x01" );                 # 10.0.0.1

=cut

=head1 FUNCTIONS

=head2 $address_plusplus = incr_n( $address )

Increment a packed IPv4 or IPv6 address in network byte order. Returns undef on overflow.

This increment function is needed in L<Net::IPAM::IP> and L<Net::IPAM::Block> for transparent handling
of IPv4 and IPv6 addresses and blocks.

No need for L<Math::BigInt>, this pure perl algorithm works for all uint_n in network byte order,
where n is a multiple of 32: uint_32, uint_64, uint_96, uint_128, ...

=cut

sub incr_n {
  my $n = shift // Carp::croak("missing argument");

  # split in individual 32 bit unsigned ints in network byte order
  my @N = unpack( 'N*', $n );

  # start at least significant N
  my $i = $#N;

  # carry?
  while ( $N[$i] == 0xffff_ffff ) {

    # OVERFLOW, it's already the most significant N
    return if $i == 0;

    # set this N to zero: 0xffff_ffff + 1 = 0x0000_0000 + carry
    $N[$i] = 0;

    # carry on to next more significant N
    $i--;
  }

  # incr this N
  $N[$i]++;

  # pack again the individual 32 bit integers in network byte order to one byte string
  return pack( 'N*', @N );
}

=head2 $address_minusminus = decr_n( $address )

Decrement a packed IPv4 or IPv6 address in network byte order. Returns undef on underflow.

This decrement function is needed in L<Net::IPAM::IP> and L<Net::IPAM::Block> for transparent handling
of IPv4 and IPv6 addresses and blocks.

No need for L<Math::BigInt>, this pure perl algorithm works for all uint_n in network byte order,
where n is a multiple of 32: uint_32, uint_64, uint_96, uint_128, ...

=cut

sub decr_n {
  my $n = shift // Carp::croak("missing argument");

  # split in individual 32 bit unsigned ints in network byte order
  my @N = unpack( 'N*', $n );

  # start at least significant N
  my $i = $#N;

  # carry?
  while ( $N[$i] == 0 ) {

    # UNDERFLOW, it's already the most significant N
    return if $i == 0;

    # set this N to ffff_ffff: 0 - 1 = 0xffff_ffff + carry
    $N[$i] = 0xffff_ffff;

    # carry on to next more significant N
    $i--;
  }

  # decr this N
  $N[$i]--;

  # pack again the individual 32 bit integers in network byte order to one byte string
  return pack( 'N*', @N );
}

=head2 $string = inet_ntop_pp( $family, $address )

A pure perl implementation for (buggy) Socket::inet_ntop.

Takes an address family (C<AF_INET> or C<AF_INET6>) and
a packed binary address structure and translates it
into a human-readable textual representation of the address.

=cut

sub inet_ntop_pp {

  # modify @_ = (AF_INETx, $ip) => @_ = ($ip)
  my $v = shift;
  goto &_inet_ntop_v4_pp if $v == Socket::AF_INET;
  goto &_inet_ntop_v6_pp;
}

=head2 $address = inet_pton_pp( $family, $string )

A pure perl implementation for (buggy) Socket::inet_pton.

Takes an address family (C<AF_INET> or C<AF_INET6>) and a string
containing a textual representation of an address in that family and
translates that to an packed binary address structure.

=cut

sub inet_pton_pp {

  # modify @_ = (AF_INETx, $ip) => @_ = ($ip)
  my $v = shift;
  goto &_inet_pton_v4_pp if $v == Socket::AF_INET;
  goto &_inet_pton_v6_pp;
}

# easy peasy
sub _inet_ntop_v4_pp {
  return if length( $_[0] ) != 4;
  return join( '.', unpack( 'C4', $_[0] ) );
}

# (1) Hexadecimal digits are expressed as lower-case letters.
#     For example, 2001:db8::1 is preferred over 2001:DB8::1.
#
# (2) Leading zeros in each 16-bit field are suppressed.
#     For example, 2001:0db8::0001 is rendered as 2001:db8::1,
#     though any all-zero field that is explicitly presented is rendered as 0.
#
# (3) Representations are shortened as much as possible.
#     The longest sequence of consecutive all-zero fields is replaced with double-colon.
#     If there are multiple longest runs of all-zero fields, then it is the leftmost that is compressed.
#     E.g., 2001:db8:0:0:1:0:0:1 is rendered as 2001:db8::1:0:0:1 rather than as 2001:db8:0:0:1::1.
#
# (4) "::" is not used to shorten just a single 0 field.
#     For example, 2001:db8:0:0:0:0:2:1 is shortened to 2001:db8::2:1,
#     but 2001:db8:0000:1:1:1:1:1 is rendered as 2001:db8:0:1:1:1:1:1.
#
sub _inet_ntop_v6_pp {
  my $n = shift;
  return if length($n) != 16;

  # expand binary to hex, lower case, rule (1), leading zeroes squashed
  # add : at left and right for symmetric squashing algo, see below
  # :2001:db8:85a3:0:0:8a2e:370:7334:
  my $ip = sprintf( ':%x:%x:%x:%x:%x:%x:%x:%x:', unpack( 'n8', $n ) );

  # rule (3,4) # squash the longest sequence of consecutive all-zero fields
  # e.g. :0:0: (?!not followed) :0\1
  $ip =~ s/(:0[:0]+:) (?! .+ :0\1)/::/x;

  $ip =~ s/^:// unless $ip =~ /^::/;    # trim additional left
  $ip =~ s/:$// unless $ip =~ /::$/;    # trim additional right
  return $ip;
}

sub _inet_pton_v4_pp {

  # 'C' may overflow for values > 255, check below
  no warnings qw(pack numeric);
  my $n = pack( 'C4', split( /\./, $_[0] ) );

  # unpack(pack...) must be idempotent
  # check for overflow errors or leading zeroes
  return unless $_[0] eq join( '.', unpack( 'C4', $n ) );

  return $n;
}

sub _inet_pton_v6_pp {
  my $ip = shift;

  return if $ip =~ m/[^a-fA-F0-9:]/;
  return if $ip =~ m/:::/;

  # starts with just one colon: :cafe...
  return if $ip =~ m/^:[^:]/;

  # ends with just one colon: ..:cafe:affe:
  return if $ip =~ m/[^:]:$/;

  my $col_count     = $ip =~ tr/://;
  my $dbl_col_count = $ip =~ s/::/::/g;

  return if $col_count > 7;
  return if $dbl_col_count > 1;
  return if $dbl_col_count == 0 && $col_count != 7;

  # normalize for splitting, prepend or append 0
  $ip =~ s/^:: /0::/x;
  $ip =~ s/ ::$/::0/x;

  # expand ::
  my $expand_dbl_col = ':0' x ( 8 - $col_count ) . ':';
  $ip =~ s/::/$expand_dbl_col/;

  my @hextets = split( /:/, $ip );
  return if grep { length > 4 } @hextets;

  my $n = pack( 'n8', map { hex } @hextets );
  return $n;
}

=head1 AUTHOR

Karl Gaissmaier, C<< <karl.gaissmaier(at)uni-ulm.de> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-net-ipam-util at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-IPAM-Util>.
I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::IPAM::Util

You can also look for information at:

=over 4

=item * on github

TODO

=back

=head1 SEE ALSO

L<Net::IPAM::IP>
L<Net::IPAM::Block>
L<Net::IPAM::Tree>

=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2020 by Karl Gaissmaier.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

1;    # End of Net::IPAM::Util
