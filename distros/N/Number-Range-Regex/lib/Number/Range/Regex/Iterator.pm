# Number::Range::Regex::Iterator
#
# Copyright 2012 Brian Szymanski.  All rights reserved.  This module is
# free software; you can redistribute it and/or modify it under the same
# terms as Perl itself.

package Number::Range::Regex::Iterator;

use strict;
use vars qw ( @ISA @EXPORT @EXPORT_OK $VERSION );
eval { require warnings; }; #it's ok if we can't load warnings

require Exporter;
use base 'Exporter';
@ISA    = qw( Exporter );

$VERSION = '0.32';

use overload bool => \&in_range,
             '""' => sub { return $_[0] };

# fields in %$self:
# ranges           : arrayref of the subranges involved
# out_of_range     : whether the iterator's current state is
#                        out of range (advanced beyond the last
#                        element or before the first one) or not.
#                        if true, will be either "underflow" or
#                        "overflow" accordingly
# number           : the number currently pointed to
# rangenum         : which subrange is the number in?
# rangepos_left    : the offset between number and the leftmost
#                        element of this subrange
# rangepos_right   : the offset between number and the rightmost
#                        element of this subrange

sub new {
  my ($class, $range) = @_;

  my $self = bless { range => $range }, $class;

  if(!$range->isa('Number::Range::Regex::Range')) {
    die "unknown arg: $range, usage: Iterator->new( \$range )";
  }
  if($range->is_empty) {
    die "can't iterate over an empty range";
  } elsif($range->isa('Number::Range::Regex::CompoundRange')) {
    $self->{ranges} = $range->{ranges};
  } else { #SimpleRange
    $self->{ranges} = [ $range ];
  }

  $self->first()  if  $self->{ranges}->[0]->has_lower_bound;

  return $self;
}

sub size {
  my ($self) = @_;
  return undef          if  !$self->{ranges}->[0]->has_lower_bound;
  return undef          if  !$self->{ranges}->[-1]->has_upper_bound;
  return $self->{size}  if  defined $self->{size};
  foreach my $sr ( @{$self->{ranges}} ) {
    $self->{size} += $sr->{max} - $sr->{min} + 1;
  }
  return $self->{size};
}

sub seek {
  my ($self, $number) = @_;
  my $n;
  for($n = 0 ; $n < @{$self->{ranges}}; $n++ ) {
    my $sr = $self->{ranges}->[$n];
    if($sr->contains($number)) {
      $self->{number}       = $number;
      $self->{rangenum}     = $n;
      $self->{out_of_range} = 0;
      if($sr->has_lower_bound) {
        $self->{rangepos_left}  = $number - $sr->{min};
      }
      if($sr->has_upper_bound) {
        $self->{rangepos_right} = $sr->{max} - $number;
      }
      last;
    }
  }
  if($n == @{$self->{ranges}}) {
    die "can't seek() - range '".$self->{range}->to_string."' does not contain '$number'";
  }
  return $self;
}

sub first {
  my ($self) = @_;
  my $first_r = $self->{ranges}->[0];
  die "can't first() an iterator with no lower bound"  unless  $first_r->has_lower_bound;
  $self->{number}         = $first_r->{min};
  $self->{rangenum}       = 0;
  if($first_r->has_lower_bound) {
    $self->{rangepos_left}  = 0;
    if($first_r->has_upper_bound) {
      $self->{rangepos_right} = $first_r->{max} - $first_r->{min};
    }
  }
  $self->{out_of_range} = 0;
  return $self;
}

sub last {
  my ($self) = @_;
  my $last_r = $self->{ranges}->[-1];
  die "can't last() an iterator with no upper bound"  unless  $last_r->has_upper_bound;
  $self->{number}       = $last_r->{max};
  $self->{rangenum}     = $#{$self->{ranges}};
  if($last_r->has_upper_bound) {
    $self->{rangepos_right} = 0;
    if($last_r->has_lower_bound) {
      $self->{rangepos_left} = $last_r->{max} - $last_r->{min};
    }
  }
  $self->{out_of_range} = 0;
  return $self;
}

sub fetch {
  my ($self) = @_;
  die "can't fetch() an iterator before positioning it using first/last/seek"  if  !defined $self->{number};
  die "can't fetch() an out of range ($self->{out_of_range}) iterator"  if  $self->{out_of_range};
  return $self->{number};
}

sub next {
  my ($self) = @_;
  die "can't next() an iterator before positioning it using first/last/seek"  if  !defined $self->{number};
  die "can't next() an out of range ($self->{out_of_range}) iterator"  if  $self->{out_of_range};

#_dbg($self, "pre-next:  ");
  my $this_r = $self->{ranges}->[ $self->{rangenum} ];
  if( $this_r->has_upper_bound ? $self->{number} < $this_r->{max} : 1 ) {
    $self->{rangepos_left}++   if  defined $self->{rangepos_left};
    $self->{rangepos_right}--  if  defined $self->{rangepos_right};
    $self->{number}++;
  } else {
    $self->{rangenum}++;
    if($self->{rangenum} == @{$self->{ranges}}) {
      $self->{out_of_range} = 'overflow';
      return $self;
    }
    my $new_r = $self->{ranges}->[ $self->{rangenum} ];
    $self->{rangepos_left} = 0;
    if($new_r->has_upper_bound) { #min must be defined - this is the next one up
      $self->{rangepos_right} = $new_r->{max} - $new_r->{min};
    }
    $self->{number} = $new_r->{min};
  }
#_dbg($self, "post-next: ");
  return $self;
}

sub prev {
  my ($self) = @_;
  die "can't prev() an iterator before positioning it using first/last/seek"  if  !defined $self->{number};
  die "can't prev() an out of range ($self->{out_of_range}) iterator"  if  $self->{out_of_range};

#_dbg($self, "pre-prev:  ");
  my $this_r = $self->{ranges}->[ $self->{rangenum} ];
  if( $this_r->has_lower_bound ? $self->{number} > $this_r->{min} : 1 ) {
    $self->{rangepos_left}--   if  defined $self->{rangepos_left};
    $self->{rangepos_right}++  if  defined $self->{rangepos_right};
    $self->{number}--;
  } else {
    $self->{rangenum}--;
    if($self->{rangenum} == -1) {
      $self->{out_of_range} = 'underflow';
      return $self;
    }
    my $new_r = $self->{ranges}->[ $self->{rangenum} ];
    $self->{rangepos_left} = $new_r->{max} - $new_r->{min};
    $self->{rangepos_right} = 0;
    $self->{number} = $new_r->{max};
  }
#_dbg($self, "post-prev: ");
  return $self;
}

sub in_range {
  my ($self) = @_;
  return ! $self->{out_of_range};
}

sub _dbg {
  my ($self, $ident) = @_;
  my $str = $ident;
  for my $key ( qw ( number rangenum rangepos_left rangepos_right ) ) {
    my $val = $self->{$key};
    $val = "[undef]" unless defined $val;
    $str .= " $key: $val,";
  }
  $str =~ s/,$//;
  warn "$str\n";
}

1;

__END__

=head1 NAME

Number::Range::Regex::Iterator - create iterators for Number::Range::Regex
objects

=head1 SYNOPSIS

  use Number::Range::Regex;
  my $it = rangespec( '-5..-3,3..5' )->iterator();

  $it->first();
  do {
    do_something_with_value( $it->fetch );
  } while ($it->next);

  $it->last();
  do {
    do_something_with_value( $it->fetch );
  } while ($it->prev);


=head1 METHODS

=over

=item new

  $it = Number:Range::Regex::Iterator->new( $range );

given a range, return an iterator that returns its members.
note that this is identical to the more compact, usual form:

  $range->iterator()

=item fetch

return the integer currently pointed to by the iterator.

=item first

  $range->first();

set the iterator to point at its lowest value. first() will throw
an error if called on a range with no lower bound, for example:

  range( undef, $n )->iterator->first;

=item last

  $range->last();

set the iterator to point at its greatest value. last() will throw
an error if called on a range with no upper bound, for example:

  rangespec( '3..inf' )->iterator->first;

=item next

point to the next greatest integer that is part of $range.
often this value will be one greater, but in the case of
compound ranges, it will not always. consider:

  my $it = range( '4,22..37' )->iterator;
  $it->first; # $it->fetch == 4
  $it->next;  # $it->fetch == 22

=item prev

  $range->prev()

point to the next smallest integer that is part of $range.
often this value will be one smaller, but not always:

  my $it = range( '22..37,44' )->iterator;
  $it->last; # $it->fetch == 44
  $it->prev; # $it->fetch == 37

=item seek

  $range->iterator->seek( $n );

set the iterator to point to the value $n in $range. that is:

  $it->seek( $n )->fetch == $n

if $n is not member of $range, seek() throws an error.

=item size

  $range->size();

Returns the size of the iterator. If the iterator is unbounded,
returns undef.

=item in_range

  $range->in_range();

returns a boolean value indicating whether $range has been
set to a valid position with any of the methods first, last,
seek, prev, and next. returns false in e.g. the following
circumstances:
  $range->last->next;
  $range->first->prev;
  range( '3..4' )->first->next->next;
  range( '3..4' )->last->prev->prev;

=back

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests through the
web interface at L<http://rt.cpan.org>.

=head1 AUTHOR

Brian Szymanski  B<< <ski-cpan@allafrica.com> >> -- be sure to put
Number::Range::Regex in the subject line if you want me to read
your message.


=head1 SEE ALSO

Number::Range::Regex

=cut

