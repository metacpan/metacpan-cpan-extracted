#line 1
#
# Tie/IxHash.pm
#
# Indexed hash implementation for Perl
#
# See below for documentation.
#

require 5.003;

package Tie::IxHash;
use integer;
require Tie::Hash;
@ISA = qw(Tie::Hash);

$VERSION = $VERSION = '1.21';

#
# standard tie functions
#

sub TIEHASH {
  my($c) = shift;
  my($s) = [];
  $s->[0] = {};   # hashkey index
  $s->[1] = [];   # array of keys
  $s->[2] = [];   # array of data
  $s->[3] = 0;    # iter count

  bless $s, $c;

  $s->Push(@_) if @_;

  return $s;
}

#sub DESTROY {}           # costly if there's nothing to do

sub FETCH {
  my($s, $k) = (shift, shift);
  return exists( $s->[0]{$k} ) ? $s->[2][ $s->[0]{$k} ] : undef;
}

sub STORE {
  my($s, $k, $v) = (shift, shift, shift);
  
  if (exists $s->[0]{$k}) {
    my($i) = $s->[0]{$k};
    $s->[1][$i] = $k;
    $s->[2][$i] = $v;
    $s->[0]{$k} = $i;
  }
  else {
    push(@{$s->[1]}, $k);
    push(@{$s->[2]}, $v);
    $s->[0]{$k} = $#{$s->[1]};
  }
}

sub DELETE {
  my($s, $k) = (shift, shift);

  if (exists $s->[0]{$k}) {
    my($i) = $s->[0]{$k};
    for ($i+1..$#{$s->[1]}) {    # reset higher elt indexes
      $s->[0]{$s->[1][$_]}--;    # timeconsuming, is there is better way?
    }
    delete $s->[0]{$k};
    splice @{$s->[1]}, $i, 1;
    return (splice(@{$s->[2]}, $i, 1))[0];
  }
  return undef;
}

sub EXISTS {
  exists $_[0]->[0]{ $_[1] };
}

sub FIRSTKEY {
  $_[0][3] = 0;
  &NEXTKEY;
}

sub NEXTKEY {
  return $_[0][1][$_[0][3]++] if ($_[0][3] <= $#{$_[0][1]});
  return undef;
}



#
#
# class functions that provide additional capabilities
#
#

sub new { TIEHASH(@_) }

#
# add pairs to end of indexed hash
# note that if a supplied key exists, it will not be reordered
#
sub Push {
  my($s) = shift;
  while (@_) {
    $s->STORE(shift, shift);
  }
  return scalar(@{$s->[1]});
}

sub Push2 {
  my($s) = shift;
  $s->Splice($#{$s->[1]}+1, 0, @_);
  return scalar(@{$s->[1]});
}

#
# pop last k-v pair
#
sub Pop {
  my($s) = shift;
  my($k, $v, $i);
  $k = pop(@{$s->[1]});
  $v = pop(@{$s->[2]});
  if (defined $k) {
    delete $s->[0]{$k};
    return ($k, $v);
  }
  return undef;
}

sub Pop2 {
  return $_[0]->Splice(-1);
}

#
# shift
#
sub Shift {
  my($s) = shift;
  my($k, $v, $i);
  $k = shift(@{$s->[1]});
  $v = shift(@{$s->[2]});
  if (defined $k) {
    delete $s->[0]{$k};
    for (keys %{$s->[0]}) {
      $s->[0]{$_}--;
    }
    return ($k, $v);
  }
  return undef;
}

sub Shift2 {
  return $_[0]->Splice(0, 1);
}

#
# unshift
# if a supplied key exists, it will not be reordered
#
sub Unshift {
  my($s) = shift;
  my($k, $v, @k, @v, $len, $i);

  while (@_) {
    ($k, $v) = (shift, shift);
    if (exists $s->[0]{$k}) {
      $i = $s->[0]{$k};
      $s->[1][$i] = $k;
      $s->[2][$i] = $v;
      $s->[0]{$k} = $i;
    }
    else {
      push(@k, $k);
      push(@v, $v);
      $len++;
    }
  }
  if (defined $len) {
    for (keys %{$s->[0]}) {
      $s->[0]{$_} += $len;
    }
    $i = 0;
    for (@k) {
      $s->[0]{$_} = $i++;
    }
    unshift(@{$s->[1]}, @k);
    return unshift(@{$s->[2]}, @v);
  }
  return scalar(@{$s->[1]});
}

sub Unshift2 {
  my($s) = shift;
  $s->Splice(0,0,@_);
  return scalar(@{$s->[1]});
}

#
# splice 
#
# any existing hash key order is preserved. the value is replaced for
# such keys, and the new keys are spliced in the regular fashion.
#
# supports -ve offsets but only +ve lengths
#
# always assumes a 0 start offset
#
sub Splice {
  my($s, $start, $len) = (shift, shift, shift);
  my($k, $v, @k, @v, @r, $i, $siz);
  my($end);                   # inclusive

  # XXX  inline this 
  ($start, $end, $len) = $s->_lrange($start, $len);

  if (defined $start) {
    if ($len > 0) {
      my(@k) = splice(@{$s->[1]}, $start, $len);
      my(@v) = splice(@{$s->[2]}, $start, $len);
      while (@k) {
        $k = shift(@k);
        delete $s->[0]{$k};
        push(@r, $k, shift(@v));
      }
      for ($start..$#{$s->[1]}) {
        $s->[0]{$s->[1][$_]} -= $len;
      }
    }
    while (@_) {
      ($k, $v) = (shift, shift);
      if (exists $s->[0]{$k}) {
        #      $s->STORE($k, $v);
        $i = $s->[0]{$k};
        $s->[1][$i] = $k;
        $s->[2][$i] = $v;
        $s->[0]{$k} = $i;
      }
      else {
        push(@k, $k);
        push(@v, $v);
        $siz++;
      }
    }
    if (defined $siz) {
      for ($start..$#{$s->[1]}) {
        $s->[0]{$s->[1][$_]} += $siz;
      }
      $i = $start;
      for (@k) {
        $s->[0]{$_} = $i++;
      }
      splice(@{$s->[1]}, $start, 0, @k);
      splice(@{$s->[2]}, $start, 0, @v);
    }
  }
  return @r;
}

#
# delete elements specified by key
# other elements higher than the one deleted "slide" down 
#
sub Delete {
  my($s) = shift;

  for (@_) {
    #
    # XXX potential optimization: could do $s->DELETE only if $#_ < 4.
    #     otherwise, should reset all the hash indices in one loop
    #
    $s->DELETE($_);
  }
}

#
# replace hash element at specified index
#
# if the optional key is not supplied the value at index will simply be 
# replaced without affecting the order.
#
# if an element with the supplied key already exists, it will be deleted first.
#
# returns the key of replaced value if it succeeds.
#
sub Replace {
  my($s) = shift;
  my($i, $v, $k) = (shift, shift, shift);
  if (defined $i and $i <= $#{$s->[1]} and $i >= 0) {
    if (defined $k) {
      delete $s->[0]{ $s->[1][$i] };
      $s->DELETE($k) ; #if exists $s->[0]{$k};
      $s->[1][$i] = $k;
      $s->[2][$i] = $v;
      $s->[0]{$k} = $i;
      return $k;
    }
    else {
      $s->[2][$i] = $v;
      return $s->[1][$i];
    }
  }
  return undef;
}

#
# Given an $start and $len, returns a legal start and end (where start <= end)
# for the current hash. 
# Legal range is defined as 0 to $#s+1
# $len defaults to number of elts upto end of list
#
#          0   1   2   ...
#          | X | X | X ... X | X | X |
#                           -2  -1       (no -0 alas)
# X's above are the elements 
#
sub _lrange {
  my($s) = shift;
  my($offset, $len) = @_;
  my($start, $end);         # both inclusive
  my($size) = $#{$s->[1]}+1;

  return undef unless defined $offset;
  if($offset < 0) {
    $start = $offset + $size;
    $start = 0 if $start < 0;
  }
  else {
    ($offset > $size) ? ($start = $size) : ($start = $offset);
  }

  if (defined $len) {
    $len = -$len if $len < 0;
    $len = $size - $start if $len > $size - $start;
  }
  else {
    $len = $size - $start;
  }
  $end = $start + $len - 1;

  return ($start, $end, $len);
}

#
# Return keys at supplied indices
# Returns all keys if no args.
#
sub Keys   { 
  my($s) = shift;
  return ( @_ == 1
	 ? $s->[1][$_[0]]
	 : ( @_
	   ? @{$s->[1]}[@_]
	   : @{$s->[1]} ) );
}

#
# Returns values at supplied indices
# Returns all values if no args.
#
sub Values {
  my($s) = shift;
  return ( @_ == 1
	 ? $s->[2][$_[0]]
	 : ( @_
	   ? @{$s->[2]}[@_]
	   : @{$s->[2]} ) );
}

#
# get indices of specified hash keys
#
sub Indices { 
  my($s) = shift;
  return ( @_ == 1 ? $s->[0]{$_[0]} : @{$s->[0]}{@_} );
}

#
# number of k-v pairs in the ixhash
# note that this does not equal the highest index
# owing to preextended arrays
#
sub Length {
 return scalar @{$_[0]->[1]};
}

#
# Reorder the hash in the supplied key order
#
# warning: any unsupplied keys will be lost from the hash
# any supplied keys that dont exist in the hash will be ignored
#
sub Reorder {
  my($s) = shift;
  my(@k, @v, %x, $i);
  return unless @_;

  $i = 0;
  for (@_) {
    if (exists $s->[0]{$_}) {
      push(@k, $_);
      push(@v, $s->[2][ $s->[0]{$_} ] );
      $x{$_} = $i++;
    }
  }
  $s->[1] = \@k;
  $s->[2] = \@v;
  $s->[0] = \%x;
  return $s;
}

sub SortByKey {
  my($s) = shift;
  $s->Reorder(sort $s->Keys);
}

sub SortByValue {
  my($s) = shift;
  $s->Reorder(sort { $s->FETCH($a) cmp $s->FETCH($b) } $s->Keys)
}

1;
__END__

#line 630
