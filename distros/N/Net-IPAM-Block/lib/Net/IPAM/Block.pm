package Net::IPAM::Block;

our $VERSION = '2.03';

use 5.10.0;
use strict;
use warnings;
use utf8;

use Carp                      ();
use List::Util                ();
use Net::IPAM::IP             ();
use Net::IPAM::Util           ();
use Net::IPAM::Block::Private ();

use Exporter 'import';
our @EXPORT_OK = qw(aggregate);

=head1 NAME

Net::IPAM::Block - A library for reading, formatting, sorting and converting IP-blocks.

=cut

our $MaxCIDRSplit = 1 << 20;

=head1 SYNOPSIS

  use Net::IPAM::Block;

  # parse and normalize
  $cidr  = Net::IPAM::Block->new('10.0.0.0/255.0.0.0') // die 'wrong format,';
  $cidr  = Net::IPAM::Block->new('10.0.0.0/8')         // die 'wrong format,';
  $range = Net::IPAM::Block->new('fe80::2-fe80::e')    // die 'wrong format,';
  $host  = Net::IPAM::Block->new('2001:db8::1')        // die 'wrong format,';

=head1 DESCRIPTION

A block is an IP-network or IP-range, e.g.

 192.168.0.1/255.255.255.0   # network, with IP mask
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
 10.0.0.0/255.0.0.0

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
  my $self  = bless( {}, $_[0] );
  my $input = $_[1] // Carp::croak 'missing argument';

  return Net::IPAM::Block::Private::_fromIP( $self, $input ) if ref $input;

  # handle mask: 2001:db8::/32, 10.0.0.0/8, 10.0.0.0/255.0.0.0
  my $idx = index( $input, '/' );
  return Net::IPAM::Block::Private::_fromMask( $self, $input, $idx )
    if $idx >= 0;

  # handle range: 192.168.1.17-192.168.1.35
  $idx = index( $input, '-' );
  return Net::IPAM::Block::Private::_fromRange( $self, $input, $idx )
    if $idx >= 0;

  # handle address: fe80::1
  return Net::IPAM::Block::Private::_fromAddr( $self, $input );
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

Stringification is overloaded with L</"to_string">

  my $b = Net::IPAM::Block->new('fe80::/10');
  say $b;                                      # fe80::/10

=cut

sub to_string {
  my $self = shift;
  if ( defined $self->{mask} ) {
    return $self->{base}->to_string . '/' . Net::IPAM::Block::Private::_leading_ones( $self->{mask}->bytes );
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
  my $ones = Net::IPAM::Block::Private::_leading_ones( $self->{mask}->bytes );

  # can't split, ones == maxbits (32 or 128)
  return if $ones == $bits;

  # make next mask, e.g. /19 -> /20
  # 11111111_11111111_1110000_0000
  # 11111111_11111111_1111000_0000
  my $next_mask_n = Net::IPAM::Block::Private::_make_mask_n( $ones + 1, $bits );

  # get original base_n from block
  my $base_n = $self->{base}->bytes;

  # make new base and last with new mask
  my $base1_n = Net::IPAM::Block::Private::_make_base_n( $base_n, $next_mask_n );
  my $last1_n = Net::IPAM::Block::Private::_make_last_n( $base_n, $next_mask_n );

  # make next base by incrementing last
  my $base2_n = Net::IPAM::Util::incr_n($last1_n);
  my $last2_n = Net::IPAM::Block::Private::_make_last_n( $base2_n, $next_mask_n );

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
    my $bitlen = Net::IPAM::Block::Private::_bitlen( $cursor_n, $end_n, $bits );

    my $mask_n  = Net::IPAM::Block::Private::_make_mask_n( $bits - $bitlen, $bits );
    my $start_n = Net::IPAM::Block::Private::_make_base_n( $cursor_n, $mask_n );
    my $last_n  = Net::IPAM::Block::Private::_make_last_n( $cursor_n, $mask_n );

    #  find matching bitlen/mask at $cursor position
    while ( $bitlen > 0 ) {

      #  bitlen is ok, if start is still EQUAL to cursor AND last is still <= end
      if ( ( $start_n cmp $cursor_n ) == 0 && ( $last_n cmp $end_n ) <= 0 ) {
        last;
      }

      # nope, no success, reduce bitlen and try again
      $bitlen--;

      $mask_n  = Net::IPAM::Block::Private::_make_mask_n( $bits - $bitlen, $bits );
      $start_n = Net::IPAM::Block::Private::_make_base_n( $cursor_n, $mask_n );
      $last_n  = Net::IPAM::Block::Private::_make_last_n( $cursor_n, $mask_n );
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
    $cursor_n = Net::IPAM::Util::incr_n($last_n) // die 'OVERFLOW: logic error,';
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

=head2 bitlen

C<< bitlen >> returns the minimum number of bits to represent a range from base to last

  $n = $b->bitlen

obvious for CIDR blocks:

  $b = Net::IPAM::Block->new('10.0.0.0/24')
  say $b->bitlen;     # 32 - 24 = 8 bit

  $b = Net::IPAM::Block->new('::/0');
  say $b->bitlen;     # 128 - 0 = 128 bit

  
not so obvious for ranges:

  $b = Net::IPAM::Block->new('2001:db8::affe-2001:db8::cafe');
  say $b->bitlen;     # 15 bit (at least)

=cut

sub bitlen {
  my $self = shift;
  my $bits = 32;
  $bits = 128 if $self->version == 6;

  return Net::IPAM::Block::Private::_bitlen( $self->{base}->bytes, $self->{last}->bytes, $bits );
}

=head2 iter

C<< iter >> returns the next IP in block, starting with base and stopping at last. Returns undef after last.

  $b = Net::IPAM::Block->new('2001:db8::affe-2001:db8::cafe');
  while ( my $ip = $b->iter ) {
    say $ip;
  }

  OUTPUT:

  2001:db8::affe
  2001:db8::afff
  2001:db8::b000
  2001:db8::b001
  ...
  2001:db8::cafb
  2001:db8::cafc
  2001:db8::cafd
  2001:db8::cafe

=cut

sub iter {
  my $self = shift;

  # init
  unless ( defined $self->{iter} ) {

    # initialize state
    return $self->{iter} = $self->{base};
  }

  #next
  if ( $self->{iter}->cmp( $self->{last} ) < 0 ) {
    return $self->{iter} = $self->{iter}->incr;
  }

  # over
  return;
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
    return Net::IPAM::Block::Private::_contains_ip(@_)
      if $_[1]->isa('Net::IPAM::IP');
    return Net::IPAM::Block::Private::_contains_block(@_)
      if $_[1]->isa('Net::IPAM::Block');
  }
  Carp::croak 'wrong argument,';
}

=head2 diff

  @diff = $outer->diff(@inner)

Returns all blocks in outer block, minus the inner blocks.

  my $outer = Net::IPAM::Block->new("192.168.2.0/24");
  my @inner = (
    Net::IPAM::Block->new("192.168.2.0/26"),
    Net::IPAM::Block->new("192.168.2.240-192.168.2.249"),
  );

  my @diff = $outer->diff(@inner);

  # diff: [192.168.2.64-192.168.2.239, 192.168.2.250-192.168.2.255]

=cut

sub diff {
  my $outer = shift;

  # sieve inner blocks
  my @sieved;
  foreach my $inner (@_) {

    # skip disjunct blocks
    next if $outer->is_disjunct_with($inner);

    # nothing left, outer is equal to any inner
    return wantarray ? () : [] if $inner->cmp($outer) == 0;

    # nothing left, outer is contained in any inner
    return wantarray ? () : [] if $inner->contains($outer);

    push @sieved, $inner;
  }

  # sort remaining inner blocks
  @sieved = sort { $a->cmp($b) } @sieved;

  # sieve subsets from sorted blocks
  @sieved = Net::IPAM::Block::Private::_sieve(@sieved);

  # collect diff blocks
  my @diff;

  # inner diffs
  my $cursor = $outer->base;
  foreach my $inner (@sieved) {

    if ( $cursor->cmp( $inner->base ) < 0 ) {
      my $base_ip = $cursor;
      my $last_ip = $inner->base->decr;

      # make new block
      my $block = bless( {}, ref $outer );
      $block->{base} = $base_ip;
      $block->{last} = $last_ip;
      $block->{mask} = Net::IPAM::Block::Private::_get_mask_ip( $base_ip, $last_ip );

      push @diff, $block;

      $cursor = $inner->last->incr;
      next;
    }

    $cursor = $inner->last->incr;
    next;
  }

  # last diff
  if ( $cursor->cmp( $outer->last ) <= 0 ) {
    my $base_ip = $cursor;
    my $last_ip = $outer->last;

    # make new block
    my $block = bless( {}, ref $outer );
    $block->{base} = $base_ip;
    $block->{last} = $last_ip;
    $block->{mask} = Net::IPAM::Block::Private::_get_mask_ip( $base_ip, $last_ip );

    push @diff, $block;
  }

  return wantarray ? @diff : [@diff];
}

=head2 find_free_cidrs

  DEPRECATED: find_free_cidrs() is deprecated in favor of diff(), maybe followed by to_cidrs()

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
  Carp::carp('DEPRECATED: find_free_cidrs() is deprecated in favor of diff(), maybe followed by to_cidrs()');

  my ( $outer, @inner ) = @_;

  my @purged;

  # purge inner blocks
  foreach my $inner (@inner) {

    # no free cidrs
    if ( $inner->cmp($outer) == 0 or $inner->contains($outer) ) {
      return wantarray ? () : [];
    }
    next if $outer->is_disjunct_with($inner);

    push @purged, $inner;
  }

  # sort inner blocks
  my @sorted = sort { $a->cmp($b) } @purged;

  # purge equals and containments in inner blcoks
  undef @purged;
  my $i = 0;
  while ( $i <= $#sorted ) {
    push @purged, $sorted[$i];
    my $j = $i + 1;
    while ( $j <= $#sorted ) {

      # purge equal
      if ( $sorted[$i]->cmp( $sorted[$j] ) == 0 ) {
        $j++;
        next;
      }

      # purge containments
      if ( $sorted[$i]->contains( $sorted[$j] ) ) {
        $j++;
        next;
      }
      last;
    }
    $i = $j;
  }

  # collect free blocks
  my @free;

  my $cursor = $outer->base;
  foreach my $inner (@purged) {

    if ( $cursor->cmp( $inner->base ) < 0 ) {
      my $base_ip = $cursor;
      my $last_ip = $inner->base->decr;

      # make new block
      my $block = bless( {}, ref $outer );
      $block->{base} = $base_ip;
      $block->{last} = $last_ip;
      $block->{mask} = Net::IPAM::Block::Private::_get_mask_ip( $base_ip, $last_ip );

      push @free, $block->to_cidrs;

      $cursor = $inner->last->incr;
      next;
    }

    $cursor = $inner->last->incr;
    next;
  }

  if ( $cursor->cmp( $outer->last ) < 0 ) {
    my $base_ip = $cursor;
    my $last_ip = $outer->last;

    # make new cidr block
    # watch out inheritende
    my $block = bless( {}, ref $outer );
    $block->{base} = $base_ip;
    $block->{last} = $last_ip;
    $block->{mask} = Net::IPAM::Block::Private::_get_mask_ip( $base_ip, $last_ip );

    push @free, $block->to_cidrs;
  }

  return wantarray ? @free : [@free];
}

=head1 FUNCTIONS

=head2 aggregate

  @agg = aggregate(@blocks)

Returns the minimal number of blocks spanning the range of input blocks.

If CIDRs are required, use the following idiom:

  @cidrs = map { $_->to_cidrs } aggregate(@blocks);

=cut

sub aggregate {
  my @result;

  # sort blocks => sieve subsets
  my @sieved = Net::IPAM::Block::Private::_sieve( sort { $a->cmp($b) } @_ );

  my $i = 0;
  while ( $i < @sieved ) {
    my $this = $sieved[$i];
    my $last_changed;
    my $j;
    for ( $j = $i + 1 ; $j < @sieved ; $j++ ) {

      # can't agg different IP versions
      last if $this->version != $sieved[$j]->version;

      # if this.last++ >= next.base, add blocks
      # no overflow in incr possible, next block is still behind this block
      if ( $this->{last}->incr->cmp( $sieved[$j]->{base} ) >= 0 ) {
        $this->{last} = $sieved[$j]->{last};
        $last_changed++;
        next;
      }

      last;
    }
    $i = $j;

    # this.last may have changed, calculate new mask
    $this->{mask} = Net::IPAM::Block::Private::_get_mask_ip( $this->{base}, $this->{last} ) if $last_changed;

    push @result, $this;
  }

  return wantarray ? @result : [@result];
}

=head1 OPERATORS

L<Net::IPAM::Block> overloads the following operators.

=head2 bool

  my $bool = !!$block;

Always true.

=head2 stringify

  my $str = "$block";

Alias for L</"to_string">.

=cut

use overload
  '""'     => sub { shift->to_string },
  bool     => sub { 1 },
  fallback => 1;

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

# vim: ts=2 sw=2 sts=2 background=dark
