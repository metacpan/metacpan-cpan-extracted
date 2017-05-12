package Net::CIDR::Set;

use warnings;
use strict;
use Carp qw( croak confess );
use Net::CIDR::Set::IPv4;
use Net::CIDR::Set::IPv6;

use overload '""' => 'as_string';

our $VERSION = '0.13';

=head1 NAME

Net::CIDR::Set - Manipulate sets of IP addresses

=head1 VERSION

This document describes Net::CIDR::Set version 0.13

=head1 SYNOPSIS

  use Net::CIDR::Set;

  my $priv = Net::CIDR::Set->new( '10.0.0.0/8', '172.16.0.0/12',
    '192.168.0.0/16' );
  for my $ip ( @addr ) {
    if ( $priv->contains( $ip ) ) {
      print "$ip is private\n";
    }
  }

=head1 DESCRIPTION

C<Net::CIDR::Set> represents sets of IP addresses and allows standard
set operations (union, intersection, membership test etc) to be
performed on them.

In spite of the name it can work with sets consisting of arbitrary
ranges of IP addresses - not just CIDR blocks.

Both IPv4 and IPv6 addresses are handled - but they may not be mixed in
the same set. You may explicitly set the personality of a set:

  my $ip4set = Net::CIDR::Set->new({ type => 'ipv4 }, '10.0.0.0/8');

Normally this isn't necessary - the set will guess its personality from
the first data that is added to it.

=head1 INTERFACE

=head2 C<< new >>

Create a new Net::CIDR::Set. All arguments are optional. May be passed a
list of list of IP addresses or ranges which, if present, will be
passed to C<add>.

The first argument may be a hash reference which will be inspected for
named options. Currently the only option that may be passed is C<type>
which should be 'ipv4', 'ipv6' or the name of a coder class. See
L<Net::CIDR::Set::IPv4> and L<Net::CIDR::Set::IPv6> for examples of
coder classes.

=cut

{
  my %type_map = (
    ipv4 => 'Net::CIDR::Set::IPv4',
    ipv6 => 'Net::CIDR::Set::IPv6',
  );

  sub new {
    my $self  = shift;
    my $class = ref $self || $self;
    my $set   = bless { ranges => [] }, $class;
    my $opt   = 'HASH' eq ref $_[0] ? shift : {};
    if ( defined( my $type = delete $opt->{type} ) ) {
      my $coder_class = $type_map{$type} || $type;
      $set->{coder} = $coder_class->new;
    }
    elsif ( ref $self ) {
      $set->{coder} = $self->{coder};
    }
    my @unk = keys %$opt;
    croak "Unknown options: ", _and( sort @unk ) if @unk;
    $set->add( @_ ) if @_;
    return $set;
  }
}

# Return the index of the first element >= the supplied value. If the
# supplied value is larger than any element in the list the returned
# value will be equal to the size of the list.
sub _find_pos {
  my $self = shift;
  my $val  = shift;
  my $low  = shift || 0;

  my $high = scalar( @{ $self->{ranges} } );

  while ( $low < $high ) {
    my $mid = int( ( $low + $high ) / 2 );
    my $cmp = $val cmp $self->{ranges}[$mid];
    if ( $cmp < 0 ) {
      $high = $mid;
    }
    elsif ( $cmp > 0 ) {
      $low = $mid + 1;
    }
    else {
      return $mid;
    }
  }

  return $low;
}

sub _inc {
  my @b = reverse unpack 'C*', shift;
  for ( @b ) {
    last unless ++$_ == 256;
    $_ = 0;
  }
  return pack 'C*', reverse @b;
}

sub _dec {
  my @b = reverse unpack 'C*', shift;
  for ( @b ) {
    last unless $_-- == 0;
    $_ = 255;
  }
  return pack 'C*', reverse @b;
}

sub _guess_coder {
  my ( $self, $ip ) = @_;
  for my $class ( qw( Net::CIDR::Set::IPv4 Net::CIDR::Set::IPv6 ) ) {
    my $coder = $class->new;
    my @rep = eval { $coder->encode( $ip ) };
    return $coder unless $@;
  }
  croak "Can't decode $ip as an IPv4 or IPv6 address";
}

sub _encode {
  my ( $self, $ip ) = @_;
  my $cdr = $self->{coder} ||= $self->_guess_coder( $ip );
  return $cdr->encode( $ip );
}

{
  for my $dele ( qw( _decode _nbits ) ) {
    no strict 'refs';
    ( my $meth = $dele ) =~ s/^_//;
    *{$dele} = sub {
      my $self = shift;
      my $cdr = $self->{coder} || croak "Don't know how to $meth yet";
      return $cdr->$meth( @_ );
    };
  }
}

sub _conjunction {
  my ( $conj, @list ) = @_;
  my $last = pop @list;
  return join " $conj ", join( ', ', @list ), $last;
}

sub _and { _conjunction( 'and', @_ ) }

sub _check_and_coerce {
  my ( $self, @others ) = @_;

  my %class = map {
    eval { ( defined $_ && $_->nbits || '' ) => $_ }
  } map { $_->{coder} } grep { defined } $self, @others;

  my @found = sort grep $_, keys %class;

  croak "Can't mix ", _and( @found ), " bit addresses"
   if @found > 1;

  $self->{coder} ||= $class{ $found[0] };
  return $self;
}

=head2 C<< invert >>

Invert (negate, complement) a set in-place.

  my $set = Net::CIDR::Set->new;
  $set->invert;

=cut

sub invert {
  my $self = shift;

  my @pad = ( 0 ) x ( $self->_nbits / 8 );
  my ( $min, $max ) = map { pack 'C*', $_, @pad } 0, 1;

  if ( $self->is_empty ) {
    $self->{ranges} = [ $min, $max ];
    return;
  }

  if ( $self->{ranges}[0] eq $min ) {
    shift @{ $self->{ranges} };
  }
  else {
    unshift @{ $self->{ranges} }, $min;
  }

  if ( $self->{ranges}[-1] eq $max ) {
    pop @{ $self->{ranges} };
  }
  else {
    push @{ $self->{ranges} }, $max;
  }
}

=head2 C<< copy >>

Make a deep copy of a set.

  my $set2 = $set->copy;

=cut

sub copy {
  my $self = shift;
  my $copy = $self->new;
  @{ $copy->{ranges} } = @{ $self->{ranges} };
  return $copy;
}

sub _add_range {
  my ( $self, $from, $to ) = @_;
  my $fpos = $self->_find_pos( $from );
  my $tpos = $self->_find_pos( _inc( $to ), $fpos );

  $from = $self->{ranges}[ --$fpos ] if ( $fpos & 1 );
  $to   = $self->{ranges}[ $tpos++ ] if ( $tpos & 1 );

  splice @{ $self->{ranges} }, $fpos, $tpos - $fpos, ( $from, $to );
}

=head2 C<< add >>

Add a number of addresses or ranges to a set.

  $set->add(
    '10.0.0.0/8', 
    '192.168.0.32-192.168.0.63', 
    '127.0.0.1'
  );

It is legal to add ranges that overlap with each other and/or with the
ranges already in the set. Overlapping ranges are merged.

=cut

sub add {
  my ( $self, @addr ) = @_;
  for my $ip ( map { split /\s*,\s*/ } @addr ) {
    my ( $lo, $hi ) = $self->_encode( $ip )
     or croak "Can't decode $ip";
    $self->_add_range( $lo, $hi );
  }
}

=head2 C<< remove >>

Remove a number of addresses or ranges from a set.

  $set->remove(
    '8.8.0.0/16',
    '158.152.1.58'
  );

There is no requirement that the addresses being removed be members
of the set.

=cut

sub remove {
  my $self = shift;

  $self->invert;
  $self->add( @_ );
  $self->invert;
}

=head2 C<< merge >>

Merge the contents of other sets into this set.

  $set = Net::CIDR::Set->new;
  $set->merge($s1, $s2);

=cut

sub merge {
  my $self = shift;
  $self->_check_and_coerce( @_ );

  # TODO: This isn't very efficient - and merge gets called from all
  # sorts of other places.
  for my $other ( @_ ) {
    my $iter = $other->_iterate_runs;
    while ( my ( $from, $to ) = $iter->() ) {
      $self->_add_range( $from, $to );
    }
  }
}

=head2 C<< contains >>

A synonmym for C<contains_all>.

=head2 C<< contains_all >>

Return true if the set contains all of the supplied addresses.
Given this set:

  my $set = Net::CIDR::Set->new('244.188.12.0/8');

this condition is true:

  if ( $set->contains_all('244.188.12.128/3') ) {
    # ...
  }

while this condition is false:

  if ( $set->contains_all('244.188.12.0/12') ) {
    # ...
  }

=cut

*contains = *contains_all;

sub contains_all {
  my $self  = shift;
  my $class = ref $self;
  return $class->new( @_ )->subset( $self );
}

=head2 C<< contains_any >>

Return true if there is any overlap between the supplied
addresses/ranges and the contents of the set.

=cut

sub contains_any {
  my $self  = shift;
  my $class = ref $self;
  return !$class->new( @_ )->intersection( $self )->is_empty;
}

sub _iterate_runs {
  my $self = shift;

  my $pos   = 0;
  my $limit = scalar( @{ $self->{ranges} } );

  return sub {
    return if $pos >= $limit;
    my @r = @{ $self->{ranges} }[ $pos, $pos + 1 ];
    $pos += 2;
    return @r;
  };
}

sub compliment {
  croak "That's very kind of you - but I expect you meant complement";
}

=head2 C<< complement >>

Return a new set that is the complement of this set.

  my $inv = $set->complement;

=cut

sub complement {
  my $new = shift->copy;
  # TODO: What if it's empty?
  $new->invert;
  return $new;
}

=head2 C<< union >>

Return a new set that is the union of a number of sets. This is
equivalent to a logical OR between sets.

  my $everything = $east->union($west);

=cut

sub union {
  my $new = shift->copy;
  $new->merge( @_ );
  return $new;
}

=head2 C<< intersection >>

Return a new set that is the intersection of a number of sets. This is
equivalent to a logical AND between sets.

  my $overlap = $north->intersection($south);

=cut

sub intersection {
  my $self  = shift;
  my $class = ref $self;
  my $new   = $class->new;
  $new->merge( map { $_->complement } $self, @_ );
  $new->invert;
  return $new;
}

=head2 C<< xor >>

Return a new set that is the exclusive-or of existing sets.

  my $xset = $this->xor($that);

The resulting set will contain all addresses that are members of one set
but not the other.

=cut

sub xor {
  my $self = shift;
  return $self->union( @_ )
   ->intersection( $self->intersection( @_ )->complement );
}

=head2 C<< diff >>

Return a new set containing all the addresses that are present in this
set but not another.

  my $diff = $this->diff($that);

=cut

sub diff {
  my $self  = shift;
  my $other = shift;
  return $self->intersection( $other->union( @_ )->complement );
}

=head2 C<< is_empty >>

Return a true value if the set is empty.

  if ( $set->is_empty ) {
    print "Nothing there!\n";
  }

=cut

sub is_empty {
  my $self = shift;
  return @{ $self->{ranges} } == 0;
}

=head2 C<< superset >>

Return true if this set is a superset of the supplied set.

=cut

sub superset {
  my $other = pop;
  return $other->subset( reverse( @_ ) );
}

=head2 C<< subset >>

Return true if this set is a subset of the supplied set.

=cut

sub subset {
  my $self = shift;
  my $other = shift || croak "I need two sets to compare";
  return $self->equals( $self->intersection( $other ) );
}

=head2 C<< equals >>

Return true if this set is identical to another set.

  if ( $set->equals($foo) ) {
    print "We have the same addresses.\n";
  }

=cut

sub equals {
  return unless @_;

  # Array of array refs
  my @edges = map { $_->{ranges} } @_;
  my $medge = scalar( @edges ) - 1;

  POS: for ( my $pos = 0;; $pos++ ) {
    my $v = $edges[0]->[$pos];
    if ( defined( $v ) ) {
      for ( @edges[ 1 .. $medge ] ) {
        my $vv = $_->[$pos];
        return unless defined( $vv ) && $vv eq $v;
      }
    }
    else {
      for ( @edges[ 1 .. $medge ] ) {
        return if defined $_->[$pos];
      }
    }

    last POS unless defined( $v );
  }

  return 1;
}

=head1 Retrieving Set Contents

The following methods allow the contents of a set to be retrieved in
various representations. Each of the following methods accepts an
optional numeric argument that controls the formatting of the returned
addresses. It may take one of the following values:

=over

=item C<0>

Format each range of addresses as compactly as possible. If the range
contains only a single address format it as such. If it can be
represented as a single CIDR block use CIDR representation (<ip>/<mask>)
otherwise format it as an arbitrary range (<start>-<end>).

=item C<1>

Always format as either a CIDR block or an arbitrary range even if the
range is just a single address.

=item C<2>

Always use arbitrary range format (<start>-<end>) even if the range is a
single address or a legal CIDR block.

=back

Here's an example of the different formatting options:

  my $set = Net::CIDR::Set->new( '127.0.0.1', '192.168.37.0/24',
    '10.0.0.11-10.0.0.17' );

  for my $fmt ( 0 .. 2 ) {
    print "Using format $fmt:\n";
    print "  $_\n" for $set->as_range_array( $fmt );
  }

And here's the output from that code:

  Using format 0:
    10.0.0.11-10.0.0.17
    127.0.0.1
    192.168.37.0/24
  Using format 1:
    10.0.0.11-10.0.0.17
    127.0.0.1/32
    192.168.37.0/24
  Using format 2:
    10.0.0.11-10.0.0.17
    127.0.0.1-127.0.0.1
    192.168.37.0-192.168.37.255

Note that this option never affects the addresses that are returned;
only how they are formatted.

For most purposes the formatting argument can be omitted; it's default
value is C<0> which provides the most general formatting.

=head2 C<< iterate_addresses >>

Return an iterator (a closure) that will return each of the addresses in
the set in ascending order. This code

  my $set = Net::CIDR::Set->new('192.168.37.0/24');
  my $iter = $set->iterate_addresses;
  while ( my $ip = $iter->() ) {
    print "Got $ip\n";
  }

outputs 256 distinct addresses from 192.168.37.0 to 192.168.27.255.

=cut

sub iterate_addresses {
  my ( $self, @args ) = @_;
  my $iter = $self->_iterate_runs;
  my @r    = ();
  return sub {
    while ( 1 ) {
      @r = $iter->() or return unless @r;
      return $self->_decode( ( my $last, $r[0] )
        = ( $r[0], _inc( $r[0] ) ), @args )
       unless $r[0] eq $r[1];
      @r = ();
    }
  };
}

=head2 C<< iterate_cidr >>

Return an iterator (a closure) that will return each of the CIDR blocks
in the set in ascending order. This code

  my $set = Net::CIDR::Set->new('192.168.37.9-192.168.37.134');
  my $iter = $set->iterate_cidr;
  while ( my $cidr = $iter->() ) {
    print "Got $cidr\n";
  }

outputs

  Got 192.168.37.9
  Got 192.168.37.10/31
  Got 192.168.37.12/30
  Got 192.168.37.16/28
  Got 192.168.37.32/27
  Got 192.168.37.64/26
  Got 192.168.37.128/30
  Got 192.168.37.132/31
  Got 192.168.37.134

This is the most compact CIDR representation of the set because its
limits don't fall on convenient CIDR boundaries.

=cut

sub iterate_cidr {
  my ( $self, @args ) = @_;
  my $iter = $self->_iterate_runs;
  my $size = $self->_nbits;
  my @r    = ();
  return sub {
    while ( 1 ) {
      @r = $iter->() or return unless @r;
      unless ( $r[0] eq $r[1] ) {
        ( my $bits = unpack 'B*', $r[0] ) =~ /(0*)$/;
        my $pad = length $1;
        $pad = $size if $pad > $size;
        while ( 1 ) {
          my $next = _inc( $r[0] | pack 'B*',
            ( '0' x ( length( $bits ) - $pad ) ) . ( '1' x $pad ) );
          return $self->_decode( ( my $last, $r[0] ) = ( $r[0], $next ),
            @args )
           if $next le $r[1];
          $pad--;
        }
      }
      @r = ();
    }
  };
}

=head2 C<< iterate_ranges >>

Return an iterator (a closure) that will return each of the ranges
in the set in ascending order. This code

  my $set = Net::CIDR::Set->new(
    '192.168.37.9-192.168.37.134',
    '127.0.0.1',
    '10.0.0.0/8' 
  );
  my $iter = $set->iterate_ranges;
  while ( my $range = $iter->() ) {
    print "Got $range\n";
  }

outputs

  Got 10.0.0.0/8
  Got 127.0.0.1
  Got 192.168.37.9-192.168.37.134

=cut

sub iterate_ranges {
  my ( $self, @args ) = @_;
  my $iter = $self->_iterate_runs;
  return sub {
    return unless my @r = $iter->();
    return $self->_decode( @r, @args );
  };
}

=head2 C<< as_array >>

Convenience method that gathers all of the output from one of the
iterators above into an array.

  my @ranges = $set->as_array( $set->iterate_ranges );

Normally you will use one of C<as_address_array>, C<as_cidr_array> or
C<as_range_array> instead.

=cut

sub as_array {
  my ( $self, $iter ) = @_;
  my @addr = ();
  while ( my $addr = $iter->() ) {
    push @addr, $addr;
  }
  return @addr;
}

=head2 C<< as_address_array >>

Return an array containing all of the distinct addresses in a set. Note
that this may very easily create a very large array. At the time of
writing it is, for example, unlikely that you have enough memory for an
array containing all of the possible IPv6 addresses...

=cut

sub as_address_array {
  my $self = shift;
  return $self->as_array( $self->iterate_addresses( @_ ) );
}

=head2 C<< as_cidr_array >>

Return an array containing all of the distinct CIDR blocks in a set.

=cut

sub as_cidr_array {
  my $self = shift;
  return $self->as_array( $self->iterate_cidr( @_ ) );
}

=head2 C<< as_range_array >>

Return an array containing all of the ranges in a set.

=cut

sub as_range_array {
  my $self = shift;
  return $self->as_array( $self->iterate_ranges( @_ ) );
}

=head2 C<< as_string >>

Return a compact string representation of a set.

=cut

sub as_string { join ', ', shift->as_range_array( @_ ) }

1;

__END__

=head1 AUTHOR

Andy Armstrong  C<< <andy.armstrong@messagesystems.com> >>

=head1 CREDITS

The encode and decode routines were stolen en masse from Douglas
Wilson's L<Net::CIDR::Lite>.

=head1 LICENCE AND COPYRIGHT

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

Copyright (c) 2009, Message Systems, Inc.
All rights reserved.

Redistribution and use in source and binary forms, with or
without modification, are permitted provided that the following
conditions are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in
      the documentation and/or other materials provided with the
      distribution.
    * Neither the name Message Systems, Inc. nor the names of its
      contributors may be used to endorse or promote products derived
      from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER
OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
