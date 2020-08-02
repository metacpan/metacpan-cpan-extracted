package Net::IPAM::Block::Private;

use 5.10.0;
use strict;
use warnings;
use utf8;

use Carp          ();
use Scalar::Util  ();
use Net::IPAM::IP ();

=head1 NAME

Net::IPAM::Block::Private - Just private functions for Net::IPAM::Block

=head1 DESCRIPTION

Don't pollute the B<< namespace >> of Net::IPAM::Block

=cut

# only masks without a gap, representable as CIDR, are allowed
#
# 11111111_11111111_11111111_11111111
# 11111111_11111111_11111111_11111110
# 11111111_11111111_11111111_11111100
# ...
# 11100000_00000000_00000000_00000000
# 11000000_00000000_00000000_00000000
# 10000000_00000000_00000000_00000000
my %valid_masks = map { pack( 'N', ( 0xffff_ffff >> $_ ) << $_ ) => $_ } 0 .. 31;

# 00000000_00000000_00000000_00000000
# extra treatment for 32bit, still support 32 bit perl, thanks to the smoke testers!
$valid_masks{ pack( 'N', 0x0000_0000 ) } = 32;

# 1.2.3.4/255.0.0.0  => {base: 1.0.0.0, last: 1.255.255.255, mask: 255.0.0.0}
# 1.2.3.4/24         => {base: 1.2.3.0, last: 1.2.3.255,     mask: 255.255.255.0}
# fe80::1/124 =>        {base: fe80::,  last: fe80::f,       mask: ffff:ffff:ffff:ffff:ffff:ffff:ffff:fff0}
sub _fromMask {
  my ( $self, $addr, $idx ) = @_;

  # split input in prefix and suffix:
  #   10.0.0.0/255.0.0.0 => 10.0.0.0, 255.0.0.0
  #   10.0.0.0/8         => 10.0.0.0, 8
  #   fe80::1/124        => fe80::1,  124
  #
  my $prefix_str = substr( $addr, 0, $idx );
  my $suffix_str = substr( $addr, $idx + 1 );

  my $prefix = Net::IPAM::IP->new($prefix_str) // return;

  my ( $mask, $mask_n );
  if ( index( $suffix_str, '.' ) >= 0 ) {
    $mask   = Net::IPAM::IP->new($suffix_str) // return;
    $mask_n = $mask->bytes;
    return unless exists $valid_masks{$mask_n};
  }
  else {
    my $bits = 32;
    $bits = 128 if $prefix->version == 6;

    return unless $suffix_str =~ m/^\d+$/;    # pos integer
    return if $suffix_str > $bits;

    $mask_n = _make_mask_n( $suffix_str, $bits );
    $mask   = Net::IPAM::IP->new_from_bytes($mask_n);
  }

  my $base_n = _make_base_n( $prefix->bytes, $mask_n );
  my $last_n = _make_last_n( $prefix->bytes, $mask_n );

  $self->{base} = Net::IPAM::IP->new_from_bytes($base_n);
  $self->{last} = Net::IPAM::IP->new_from_bytes($last_n);
  $self->{mask} = $mask;

  return $self;
}

# 1.2.3.4-1.2.3.17  => {base: 1.2.3.4, last: 1.2.3.17, mask: undef}
# fe80::-fe80::ffff => {base: fe80::, last: fe80::ffff, mask: ffff:ffff:ffff:ffff:ffff:ffff:ffff::}
sub _fromRange {
  my ( $self, $addr, $idx ) = @_;

  # split range in base and last 10.0.0.1-10.0.0.3 => 10.0.0.1, 10.0.0.3
  my $base_str = substr( $addr, 0, $idx );
  my $last_str = substr( $addr, $idx + 1 );

  my $base_ip = Net::IPAM::IP->new($base_str) // return;
  my $last_ip = Net::IPAM::IP->new($last_str) // return;

  # version base != version last
  my $version = $base_ip->version;
  return if $version != $last_ip->version;

  # base > last?
  return if $base_ip->cmp($last_ip) > 0;

  $self->{base} = $base_ip;
  $self->{last} = $last_ip;
  $self->{mask} = _get_mask_ip( $base_ip, $last_ip );

  return $self;
}

# 1.2.3.4 => {base: 1.2.3.4, last: 1.2.3.4, mask: 255.255.255.255}
# fe80::1 => {base: fe80::1, last: fe80::1, mask: ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff}
sub _fromAddr {
  my ( $self, $addr ) = @_;

  my $base = Net::IPAM::IP->new($addr) // return;
  my $bits = 32;
  $bits = 128 if $base->version == 6;

  my $mask_n = _make_mask_n( $bits, $bits );

  $self->{base} = $base;
  $self->{last} = Net::IPAM::IP->new_from_bytes( $base->bytes );
  $self->{mask} = Net::IPAM::IP->new_from_bytes($mask_n);

  return $self;
}

# 1.2.3.4 => {base: 1.2.3.4, last: 1.2.3.4, mask: 255.255.255.255}
# fe80::1 => {base: fe80::1, last: fe80::1, mask: ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff}
sub _fromIP {
  my ( $self, $base ) = @_;

  return unless Scalar::Util::blessed($base) && $base->isa('Net::IPAM::IP');

  my $bits = 32;
  $bits = 128 if $base->version == 6;

  my $mask_n = _make_mask_n( $bits, $bits );

  $self->{base} = $base;
  $self->{last} = Net::IPAM::IP->new_from_bytes( $base->bytes );
  $self->{mask} = Net::IPAM::IP->new_from_bytes($mask_n);

  return $self;
}

# a.base <= b && a.last >= b
sub _contains_ip {
  return $_[0]->{base}->cmp( $_[1] ) <= 0 && $_[0]->{last}->cmp( $_[1] ) >= 0;
}

sub _contains_block {

  # a == b, return false
  return 0 if $_[0]->cmp( $_[1] ) == 0;

  # a.base <= b.base && a.last >= b.last
  return $_[0]->{base}->cmp( $_[1]->{base} ) <= 0 && $_[0]->{last}->cmp( $_[1]->{last} ) >= 0;
}

# count leading ones:
# 0xffff_ff80 => 25
# 0xffff_ffff_ffff_ff00_0000_0000_0000_0000 => 56
#
sub _leading_ones {
  my $n    = shift or die 'missing arg,';
  my $ones = 0;

  # step bytewise through $n from left to right
  for my $i ( 0 .. length($n) - 1 ) {
    my $byte = vec( $n, $i, 8 );

    # count bytes
    if ( $byte == 0xff ) {
      $ones += 8;
      next;
    }

    # count bits
    while ( ( $byte & 0b1000_0000 ) != 0 ) {
      $ones++;
      $byte = $byte << 1;
    }
    last;
  }

  return $ones;
}

# makes base address from address and netmask:
sub _make_base_n {
  my ( $addr_n, $mask_n ) = @_;
  return $addr_n & $mask_n;
}

# makes last address from address and netmask:
#
# last = base | hostMask
#
# Example:
#   ~netMask(255.0.0.0) = hostMask(0.255.255.255)
#
#   ~0xff_00_00_00  = 0x00_ff_ff_ff
#  -----------------------------------------------
#
#    0x7f_00_00_00 base
#  | 0x00_ff_ff_ff hostMask
#  ----------------------
#    0x7f_ff_ff_ff last
#
sub _make_last_n {
  my ( $addr_n, $mask_n ) = @_;
  return $addr_n | ~$mask_n;
}

# make CIDR mask from bits:
# (24, 32)  => 0xffff_ff00
# (56, 128) => 0xffff_ffff_ffff_ff00_0000_0000_0000_0000
#
sub _make_mask_n {
  my ( $ones, $bits ) = @_;
  my $zeros = $bits - $ones;

  return pack( "B$bits", '1' x $ones . '0' x $zeros );
}

# _bitlen returns the minimum number of bits to represent a range from base_n to last_n
#
# 10.0.0.0  = base_n  = 00001010_00000000_00000000_00000000
# 10.0.0.17 = last_n  = 00001010_00000000_00000000_00010001
# ---------------------------------------------------------
#                   ^ = 00000000_00000000_00000000_00010001 XOR FOR LEADING ZEROS
#                   ~ = 11111111_11111111_11111111_11101110 COMPLEMENT FOR LEADING ONES
#                                                     ^^^^^ BITLEN = BITS - LEADING ONES
sub _bitlen {
  my ( $base_n, $last_n, $bits ) = @_;
  return $bits - _leading_ones( ~( $base_n ^ $last_n ) );
}

# try to _get_mask from base_ip and last_ip, returns undef if base-last is no CIDR
sub _get_mask_ip {
  my ( $base_ip, $last_ip ) = @_;

  # version base != version last
  my $version = $base_ip->version;
  Carp::croak 'version mismatch,' if $version != $last_ip->version;

  # base > last?
  Carp::croak 'base > last,' if $base_ip->cmp($last_ip) > 0;

  my $bits = 32;
  $bits = 128 if $version == 6;

  my $base_n = $base_ip->bytes;
  my $last_n = $last_ip->bytes;

  # get outer mask for range
  my $bitlen = _bitlen( $base_n, $last_n, $bits );
  my $mask_n = _make_mask_n( $bits - $bitlen, $bits );

  # is range a real CIDR?
  if ( ( $base_n eq _make_base_n( $base_n, $mask_n ) )
    && ( $last_n eq _make_last_n( $last_n, $mask_n ) ) )
  {
    return Net::IPAM::IP->new_from_bytes($mask_n);
  }

  return;
}

# input:  sorted blocks
# output: remaining blocks after sieving dups and subsets
sub _sieve (@) {
  my @result;

  my $i = 0;
  while ( $i < @_ ) {

    my $j;
    for ( $j = $i + 1 ; $j < @_ ; $j++ ) {

      # skip over dups
      next if $_[$i]->cmp( $_[$j] ) == 0;

      # skip over subsets
      next if _contains_block( $_[$i], $_[$j] );

      # stop skipping
      last;
    }

    # keep $i
    push @result, $_[$i];

    # push $i forward to last $j
    $i = $j;
  }

  return @result;
}

=head1 AUTHOR

Karl Gaissmaier, C<< <karl.gaissmaier(at)uni-ulm.de> >>

=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2020 by Karl Gaissmaier.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

1;
