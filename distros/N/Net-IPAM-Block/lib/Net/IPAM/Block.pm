package Net::IPAM::Block;

use 5.10.0;
use strict;
use warnings;

use overload
  '""'     => sub { shift->to_string },
  fallback => 1;

use Carp qw(croak);
use List::Util qw(any all);
use Scalar::Util qw(blessed);

use Net::IPAM::IP qw(incr_n);

use Exporter 'import';
our @EXPORT_OK = qw(aggregate);

=head1 NAME

Net::IPAM::Block - A library for reading, formatting, sorting and converting IP-blocks.

=cut

our $VERSION = '1.03';

our $MaxCIDRSplit = 1 << 20;

=head1 SYNOPSIS

  use Net::IPAM::Block;

  # parse and normalize
  my $cidr  = Net::IPAM::Block->new('10.0.0.0/24')       // die 'wrong format,';
  my $range = Net::IPAM::Block->new('fe80::2-fe80::e')   // die 'wrong format,';
  my $host  = Net::IPAM::Block->new('2001:db8::1')       // die 'wrong format,';

=head1 DESCRIPTION

A block is an IP-network or IP-range, e.g.

 192.168.0.1/24              # network, with CIDR mask
 ::1/128                     # network, with CIDR mask
 10.0.0.3-10.0.17.134        # range
 2001:db8::1-2001:db8::f6    # range

The parsed block is represented as an object with:

 base
 last
 mask    # if block is a CIDR, otherwise undef

This representation is fast sortable without conversions to/from the different IP versions.

=head1 METHODS

=head2 new

  $b = Net::IPAM::Block->new('fe80::/10');

new() parses the input as CIDR, range or address (or IP object, see below) and returns the Net::IPAM::Block object.

Example for valid input strings:

 2001:db8:dead::/38
 10.0.0.0/8

 2001:db8::1-2001:db8::ff00:35
 192.168.2.3-192.168.7.255

If a begin-end range can be represented as a CIDR, new() calculates the netmask and returns the range as CIDR block with a proper mask.

Plain IP addresses as input strings or objects are converted to /32 or /128 CIDRs.

  0.0.0.0                       => 0.0.0.0/32
  ::ffff:127.0.0.1              => 127.0.0.1/32
  ::                            => ::/128
  Net::IPAM::IP->new('1.2.3.4') => 1.2.3.4/32


  $range = Net::IPAM::Block->new('10.2.0.17-10.3.67.255') // die 'wrong block format,';
  $range = Net::IPAM::Block->new('fe80::-fe80::1234')     // die 'wrong block format,';

  $cidr_24  = Net::IPAM::Block->new('10.0.0.0/24') // die 'wrong block format,';
  $cidr_32  = Net::IPAM::Block->new('192.168.0.1') // die 'wrong block format,';
  $cidr_128 = Net::IPAM::Block->new('2001:db8::1') // die 'wrong block format,';

  $cidr_128 = Net::IPAM::Block->new( Net::IPAM::IP->new('2001:db8::1') // die 'wrong IP format,' );

Returns undef on illegal input.

=cut

sub new {
  croak 'wrong method call' unless defined $_[1];

  my $self  = bless( {}, $_[0] );
  my $input = $_[1];

  return $self->_fromIP($input) if blessed($input) && $input->isa('Net::IPAM::IP');

  # handle CIDR: 2001:db8::/32
  my $idx = index( $input, '/' );
  return $self->_fromCIDR( $input, $idx ) if $idx >= 0;

  # handle range: 192.168.1.17-192.168.1.35
  $idx = index( $input, '-' );
  return $self->_fromRange( $input, $idx ) if $idx >= 0;

  # handle address: fe80::1
  return $self->_fromAddr($input);
}

# 1.2.3.4/24  => {base: 1.2.3.0, last: 1.2.3.255, mask: 255.255.255.0}
# fe80::1/124 => {base: fe80::,  last: fe80::f,   mask: ffff:ffff:ffff:ffff:ffff:ffff:ffff:fff0}
sub _fromCIDR {
  my ( $self, $addr, $idx ) = @_;

  # split CIDR in prefix and ones: 10.0.0.0/8 => 10.0.0.0, 8
  my $prefix_str = substr( $addr, 0, $idx );
  my $ones       = substr( $addr, $idx + 1 );

  my $prefix = Net::IPAM::IP->new($prefix_str) // return;
  my $bits   = 32;
  $bits = 128 if $prefix->version == 6;

  return unless $ones =~ m/^\d+$/;    # pos integer
  return if $ones > $bits;

  my $mask_n = _make_mask_n( $ones, $bits );
  my $base_n = _make_base_n( $prefix->bytes, $mask_n );
  my $last_n = _make_last_n( $prefix->bytes, $mask_n );

  $self->{base} = Net::IPAM::IP->new_from_bytes($base_n);
  $self->{last} = Net::IPAM::IP->new_from_bytes($last_n);
  $self->{mask} = Net::IPAM::IP->new_from_bytes($mask_n);

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
  $self->{last} = $base->clone;
  $self->{mask} = Net::IPAM::IP->new_from_bytes($mask_n);

  return $self;
}

# 1.2.3.4 => {base: 1.2.3.4, last: 1.2.3.4, mask: 255.255.255.255}
# fe80::1 => {base: fe80::1, last: fe80::1, mask: ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff}
sub _fromIP {
  my ( $self, $base ) = @_;

  my $bits = 32;
  $bits = 128 if $base->version == 6;

  my $mask_n = _make_mask_n( $bits, $bits );

  $self->{base} = $base;
  $self->{last} = $base->clone;
  $self->{mask} = Net::IPAM::IP->new_from_bytes($mask_n);

  return $self;
}

=head2 version

  $v = $b->version

Returns 4 or 6.

=cut

# just return the version from the base IP
sub version {
  return $_[0]->{base}->version;
}

=head2 to_string

Returns the block in canonical form.

  say Net::IPAM::Block->new('fe80::aa/10')->to_string;        # fe80::/10
  say Net::IPAM::Block->new('1.2.3.4-1.2.3.36')->to_string;   # 1.2.3.4-1.2.3.36
  say Net::IPAM::Block->new('127.0.0.1')->to_string;          # 127.0.0.1/32

Stringification is overloaded with C<to_string>

  my $b = Net::IPAM::Block->new('fe80::/10');
  say $b;                                      # fe80::/10

=cut

sub to_string {
  my $self = shift;
  if ( defined $self->{mask} ) {
    return $self->{base}->to_string . '/' . _leading_ones( $self->{mask}->bytes );
  }
  else {
    return $self->{base}->to_string . '-' . $self->{last}->to_string;
  }
}

=head2 is_cidr

  $b->is_cidr

Returns true if the block is a CIDR.

  Net::IPAM::Block->new('fe80::aa/10')->is_cidr        # true
  Net::IPAM::Block->new('1.2.3.1-1.2.3.2')->is_cidr    # false

=cut

sub is_cidr {
  return 1 if defined $_[0]->{mask};
  return;
}

=head2 cidrsplit

  @cidrs = $b->cidrsplit

Returns the next 2 cidrs splitted from block.

  Net::IPAM::Block->new('0.0.0.0/7')->cidrsplit    # 0.0.0.0/8  1.0.0.0/8
  Net::IPAM::Block->new('fe80::/12')->cidrsplit    # fe80::/13  fe88::/13

Returns undef if cidr mask is at maximum or if block is no CIDR.

=cut 

sub cidrsplit {
  my $self = shift;

  # return undef if mask is not defined (block is no CIDR)
  return unless defined $self->{mask};

  my $bits = 32;
  $bits = 128 if $self->version == 6;

  # get the ones in mask: 11111111_11111111_1110000_0000 => 19
  my $ones = _leading_ones( $self->{mask}->bytes );

  # can't split, ones == maxbits (32 or 128)
  return if $ones == $bits;

  # make next mask, e.g. /19 -> /20
  # 11111111_11111111_1110000_0000
  # 11111111_11111111_1111000_0000
  my $next_mask_n = _make_mask_n( $ones + 1, $bits );

  # get original base_n from block
  my $base_n = $self->{base}->bytes;

  # make new base and last with new mask
  my $base1_n = _make_base_n( $base_n, $next_mask_n );
  my $last1_n = _make_last_n( $base_n, $next_mask_n );

  # make next base by incrementing last
  my $base2_n = incr_n($last1_n);
  my $last2_n = _make_last_n( $base2_n, $next_mask_n );

  # make new cidr blocks
  my $cidr1 = bless( {}, ref $self );
  my $cidr2 = bless( {}, ref $self );

  $cidr1->{mask} = $cidr2->{mask} = Net::IPAM::IP->new_from_bytes($next_mask_n);

  $cidr1->{base} = Net::IPAM::IP->new_from_bytes($base1_n);
  $cidr1->{last} = Net::IPAM::IP->new_from_bytes($last1_n);

  $cidr2->{base} = Net::IPAM::IP->new_from_bytes($base2_n);
  $cidr2->{last} = Net::IPAM::IP->new_from_bytes($last2_n);

  return wantarray ? ( $cidr1, $cidr2 ) : [ $cidr1, $cidr2 ];
}

=head2 to_cidrs

  @cidrs = $b->to_cidrs

Returns a list of Net::IPAM::Block objects as true CIDRs, representing the range.

  Net::IPAM::Block->new('17.0.0.1-17.0.0.2')->to_cidrs  # 17.0.0.1/32 17.0.0.2/32
  Net::IPAM::Block->new('fe80::aa-fe80::ac')->to_cidrs  # fe80::aa/127 fe80::ac/128
  Net::IPAM::Block->new('1.2.3.0-1.2.3.101')->to_cidrs  # 1.2.3.0/26 1.2.3.64/27 1.2.3.96/30 1.2.3.100/31

If the range is a CIDR, just returns the CIDR:

  Net::IPAM::Block->new('10.0.0.0/8')->to_cidrs         # 10.0.0.0/8
  Net::IPAM::Block->new('::1')->to_cidrs                # ::1/128

=cut 

sub to_cidrs {
  my $self = shift;

  # return $self if mask is defined (block is a true CIDR)
  if ( defined $self->{mask} ) {
    return wantarray ? ($self) : [$self];
  }

  my @result;

  my $bits = 32;
  $bits = 128 if $self->version == 6;

  # start values
  # from here on work with byte strings (foo_n) in network-byte-order
  my $cursor_n = $self->{base}->bytes;
  my $end_n    = $self->{last}->bytes;

  #  stop condition, last == end, see below
  while () {

    # try
    # make outer-mask and with this mask make new start and last
    my $bitlen = _bitlen( $cursor_n, $end_n, $bits );

    my $mask_n  = _make_mask_n( $bits - $bitlen, $bits );
    my $start_n = _make_base_n( $cursor_n, $mask_n );
    my $last_n  = _make_last_n( $cursor_n, $mask_n );

    #  find matching bitlen/mask at $cursor position
    while ( $bitlen > 0 ) {

      #  bitlen is ok, if start is still EQUAL to cursor AND last is still <= end
      if ( ( $start_n cmp $cursor_n ) == 0 && ( $last_n cmp $end_n ) <= 0 ) {
        last;
      }

      # nope, no success, reduce bitlen and try again
      $bitlen--;

      $mask_n  = _make_mask_n( $bits - $bitlen, $bits );
      $start_n = _make_base_n( $cursor_n, $mask_n );
      $last_n  = _make_last_n( $cursor_n, $mask_n );
    }

    # make new cidr block
    my $cidr = bless( {}, ref $self );
    $cidr->{base} = Net::IPAM::IP->new_from_bytes($start_n);
    $cidr->{last} = Net::IPAM::IP->new_from_bytes($last_n);
    $cidr->{mask} = Net::IPAM::IP->new_from_bytes($mask_n);

    push @result, $cidr;

    # ready? last == end
    if ( ( $last_n cmp $end_n ) == 0 ) {
      last;
    }

    #  move the $cursor one behind last
    $cursor_n = incr_n($last_n) // die 'OVERFLOW: logic error,';
  }

  return wantarray ? @result : [@result];
}

=head2 base

  $ip = $b->base

Returns the base IP, as Net::IPAM::IP object.

  $b = Net::IPAM::Block->new('fe80::ffff/10');
  say $b->base;  # fe80::/10

=cut

# just return the base slot
sub base {
  return $_[0]->{base};
}

=head2 last

  $ip = $b->last

Returns the last IP, as Net::IPAM::IP object.

  $b = Net::IPAM::Block->new('10.0.0.0/30')
  say $b->last;  # 10.0.0.3

=cut

# just return the last slot
sub last {
  return $_[0]->{last};
}

=head2 mask

  $ip = $b->mask

Returns the netmask as Net::IPAM::IP object.

  $b = Net::IPAM::Block->new('10.0.0.0/24')
  say $b->mask if defined $b->mask;  # 255.255.255.0

The mask is only defined for real CIDR blocks.

Example:

  1.2.3.4            => mask is /32  = 255.255.255.255
  ::1                => mask is /128 = ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff

  10.0.0.0-10.0.0.15 => mask is /28  = 255.255.255.240
  ::-::f             => mask is /124 = ffff:ffff:ffff:ffff:ffff:ffff:ffff:fff0

  10.0.0.0/24        => mask is /24  = 255.255.255.0
  fe80::/10          => mask is /10  = ffc0:0000:0000:0000:0000:0000:0000:0000

  10.0.0.0-10.0.0.13 => mask is undef
  ::-::5             => mask is undef

=cut

# just return the mask slot
sub mask {
  return $_[0]->{mask};
}

=head2 hostmask

  $ip = $b->hostmask

Returns the hostmask as Net::IPAM::IP object.

  $b = Net::IPAM::Block->new('10.0.0.0/24')
  say $b->mask;      # 255.255.255.0
  say $b->hostmask;  # 0.0.0.255

  $b = Net::IPAM::Block->new('fe80::/10')
  say $b->mask;      # ffc0::
  say $b->hostmask;  #   3f:ffff:ffff:ffff:ffff:ffff:ffff:ffff

The hostmask is only defined for real CIDR blocks.

=cut

sub hostmask {
  my $mask = $_[0]->{mask} // return;
  return Net::IPAM::IP->new_from_bytes( ~( $mask->bytes ) );
}

=head2 cmp

  $a->cmp($b)

Compares two IP blocks:

  print $this->cmp($other);
  @sorted_blocks = sort { $a->cmp($b) } @unsorted_blocks;

cmp() returns -1, 0, +1:

   0 if $a == $b,

  -1 if $a is v4 and $b is v6
  +1 if $a is v6 and $b is v4

  -1 if $a->base < $b->base
  +1 if $a->base > $b->base

  -1 if $a->base == $b->base and $a->last > $b->last # $a is super-set of $b
  +1 if $a->base == $b->base and $a->last < $b->last # $a is sub-set of $b

=cut

sub cmp {
  croak "wrong or missing arg" unless ref $_[1] && $_[1]->isa(__PACKAGE__);

  return -1 if $_[0]->{base}->cmp( $_[1]->{base} ) < 0;
  return 1  if $_[0]->{base}->cmp( $_[1]->{base} ) > 0;

  # base is equal, test for superset/subset
  return -1 if $_[0]->{last}->cmp( $_[1]->{last} ) > 0;
  return 1  if $_[0]->{last}->cmp( $_[1]->{last} ) < 0;

  # base and last are also equal
  return 0;
}

=head2 is_disjunct_with

  $a->is_disjunct_with($b)

Returns true if the blocks are disjunct

  a       |----------|
  b |---|

  a |------|
  b          |---|

  print "a and b are disjunct" if $a->is_disjunct_with($b)

=cut

sub is_disjunct_with {
  croak "wrong or missing arg" unless ref $_[1] && $_[1]->isa(__PACKAGE__);

  #  a       |----------|
  #  b |---|
  return 1 if $_[0]->{base}->cmp( $_[1]->{last} ) == 1;

  #  a |---|
  #  b       |----------|
  return 1 if $_[0]->{last}->cmp( $_[1]->{base} ) == -1;

  return;
}

=head2 overlaps_with

  $a->overlaps_with($b)

Returns true if the blocks overlap.

  a    |-------|
  b |------|
  
  a |------|
  b    |-------|
  
  a |----|
  b      |---------|
  
  a      |---------|
  b |----|

=cut

sub overlaps_with {
  croak "wrong or missing arg" unless ref $_[1] && $_[1]->isa(__PACKAGE__);

  # false if a == b
  return if $_[0]->cmp( $_[1] ) == 0;

  # false if a contains b or vice versa
  return if $_[0]->contains( $_[1] ) || $_[1]->contains( $_[0] );

  # false if a is_disjunct_with b
  return if $_[0]->is_disjunct_with( $_[1] );

  return 1;
}

=head2 contains

  $a->contains($b)

Returns true if block a contains block b. a and b may NOT coincide.

  if ( $a->contains($b) ) {
    print "block a contains block b\n";
  }

  a |-----------------| |-----------------| |-----------------|
  b   |------------|    |------------|           |------------|

The argument may also be a Net::IPAM::IP address object.

  if ( $a->contains($ip) ) {
    print "block a contains ip\n";
  }

=cut

# polymorphic: arg may be block or ip
sub contains {
  if ( ref $_[1] ) {
    return _contains_ip(@_)    if $_[1]->isa('Net::IPAM::IP');
    return _contains_block(@_) if $_[1]->isa('Net::IPAM::Block');
  }
  croak 'wrong argument,';
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

=head2 find_free_cidrs

  @free = $outer->find_free_cidrs(@inner)

Returns all free cidrs within given block, minus the inner blocks.

  my $outer = Net::IPAM::Block->new("192.168.2.0/24");
  my @inner = (
  	Net::IPAM::Block->new("192.168.2.0/26"),
  	Net::IPAM::Block->new("192.168.2.240-192.168.2.249"),
  );

  my @free = $outer->find_free_cidrs(@inner);

  # outer: 192.168.2.0/24 - inner: [192.168.2.0/26 192.168.2.240-192.168.2.249]
  # free: [192.168.2.64/26 192.168.2.128/26 192.168.2.192/27 192.168.2.224/28 192.168.2.250/31 192.168.2.252/30]

=cut

sub find_free_cidrs {
  my $outer = shift;
  my @inner = @_;

  return $outer unless scalar @inner;

  # collect free blocks
  my @free;

  # start with outer block, split them to find free cidrs
  my @candidates = ($outer->to_cidrs);

  while (@candidates) {
    my $this = shift @candidates;

    # mark it as free, if this block is disjunct with ALL inner blocks
    if ( all { $this->is_disjunct_with($_) } @inner ) {
      push @free, $this;
      next;
    }

    # skip if this block is already contained in ANY inner block or equal with
    if ( any { $_->contains($this) || $_->cmp($this) == 0 } @inner ) {
      next;
    }

    # still too big, split one bit (two halfs), maybe a smaller CIDR is free
    push @candidates, $this->cidrsplit;

    # limit cpu and memory
    croak("too many CIDRs generated,") if @candidates > $MaxCIDRSplit;
  }

  @free = sort { $a->cmp($b) } @free;

  return wantarray ? @free : [@free];
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
  croak 'version mismatch,' if $version != $last_ip->version;

  # base > last?
  croak 'base > last,' if $base_ip->cmp($last_ip) > 0;

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

=head1 FUNCTIONS

=head2 aggregate

  @cidrs = aggregate(@blocks)

Returns the minimal number of CIDRs spanning the range of input blocks.

=cut

# algo:
# - make CIDRs from blocks
# - sort he CIDRs
# - remove duplicates
# - remove subsets
# - pack adjacent CIDRs together
# - make again CIDRs from the packed blocks
# - return CIDRs
sub aggregate {

  # make cidrs from blocks
  my @cidrs;
  foreach my $block (@_) {
    push @cidrs, $block->to_cidrs;
  }

  # sort them !!!
  @cidrs = sort { $a->cmp($b) } @cidrs;

  # pack adjacent blocks together
  # 10.0.0.1-10.0.0.17, 10.0.0.18-10.0.0.255 => 10.0.0.1-10.0.0.255
  # fe80::3-fe80::7, fe80::8-fe80::f         => fe80::3-fe80::f
  #
  my @packed;
  my $i = 0;
  while ( $i <= $#cidrs ) {
    my $this = $cidrs[$i];

    my $j;
    for ( $j = $i + 1 ; $j <= $#cidrs ; $j++ ) {
      my $next = $cidrs[$j];

      # skip subsets and duplicates, @cidrs must be sorted !!!
      next if $this->cmp($next) == 0;
      next if $this->contains($next);

      # can't pack different IP versions
      last if $this->version != $next->version;

      # if this.last++ == next.base, add ranges
      # no overflow in incr possible, next range is still behind this range
      if ( $this->{last}->incr->cmp( $next->{base} ) == 0 ) {
        $this->{last} = $next->{last};
        next;
      }
      last;
    }
    $i = $j;

    # last has changed, calculate new mask, returns undef if no CIDR
    $this->{mask} = _get_mask_ip( $this->{base}, $this->{last} );

    push @packed, $this;
  }

  # last step: expand packed blocks (maybe now again ranges) to real CIDRs
  undef @cidrs;
  foreach my $range (@packed) {
    push @cidrs, $range->to_cidrs;
  }

  return wantarray ? @cidrs : [@cidrs];
}

=head1 AUTHOR

Karl Gaissmaier, C<< <karl.gaissmaier(at)uni-ulm.de> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-net-ipam-block at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-IPAM-Block>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::IPAM::Block


You can also look for information at:

=over 4

=item * on github

TODO

=back

=head1 SEE ALSO

L<Net::IPAM::IP>
L<Net::IPAM::Tree>

=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2020 by Karl Gaissmaier.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.


=cut

1;    # End of Net::IPAM::Block
