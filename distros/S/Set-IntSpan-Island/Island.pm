
=pod

=head1 NAME

Set::IntSpan::Island - extension for Set::IntSpan to handle islands, holes and covers

=head1 SYNOPSIS

  use Set::IntSpan::Island;

  # inherits normal behaviour from Set::IntSpan
  $set = Set::IntSpan::Island->new( $set_spec );
  # special pair input creates a span a-b
  $set = Set::IntSpan::Island->new( $a,$b );

  # equivalent to $set->cardinality($another_set)->size;
  if ($set->overlap( $another_set )) { ... }

  # distance between spans is negative if spans overlap, positive if not
  $distance = $set->distance( $another_set );

  # remove islands whose size is smaller than $minsize
  $new_set = $set->excise( $minsize );

  # remove islands whose size is found in the set $sizes_set,
  $new_set = $set->excise( $sizes_set );
  # all islands sized <= 10 removed
  $new_set = $set->excise( Set::IntSpan( "(-10" ) );
  # all islands sized >= 10 removed
  $new_set = $set->excise( Set::IntSpan( "10-)" ) );
  # all islands of size between 2-5 removed
  $new_set = $set->excise( Set::IntSpan( "2-5" ) );

  # remove islands larger than $maxlength
  $set = $set->excise_large( $minlength );

  # fill holes up to $maxsize
  $set = $set->fill( $maxsize );

  # fill holes whose size is found in the set $sizes_set
  $set = $set->fill( $sizes_set);
  # all holes sizes <= 10 filled
  $set = $set->fill( Set::IntSpan( "(-10" ) );
  # all holes sizes >= 10 filled
  $set = $set->fill( Set::IntSpan( "10-)" ) );
  # all holes sizes 2-5 filled
  $set = $set->fill( Set::IntSpan( "2-5" ) );

  # return a set composed of islands of $set that overlap $another_set
  $set = $set->find_island( $another_set );

  # return a set composed of the nearest non-overlapping island(s) to $another_set
  $set = $set->nearest_island( $another_set );

  # construct a list of covers by exhaustively intersecting all sets
  @covers = Set::IntSpan::Island->extract_covers( { id1=>$set1, id2=>set2, ... } );
  for $cover (@covers) {
    ($coverset,@ids) = ($cover->[0], @{$cover->[1]});
    print "cover",$coverset->run_list,"contains sets",join(",",@ids);
  }

=head1 DESCRIPTION

This module extends the C<Set::IntSpan> module by Steve McDougall. It
implementing methods that are specific to islands, holes and
covers. C<Set::IntSpan::Island> inherits from Set::IntSpan.

=head2 Terminology

An integer set, as represented by C<Set::IntSpan>, is a collection of
islands (or spans) on the number line

  ...-----xxxx----xxxxxxxx---xxxxxxxx---xx---x----....

Holes are regions not in the set that fall between adjacent spans. For
example, the integer set above is composed of 5 islands and 4
holes. The two infinite regions on either side of the set are not
counted as holes within the context of this module.

=head1 METHODS

=cut

package Set::IntSpan::Island;

use 5;
use strict;
use warnings FATAL=>"all";

use parent qw(Exporter);
use parent qw(Set::IntSpan);

our @EXPORT    = qw();
our @EXPORT_OK = qw();

use Set::IntSpan 1.13;
use Carp;

our $VERSION = '0.10';

=pod

=head2 $set = Set::IntSpan::Island->new( $set_spec )

Constructs a set using the set specification as supported by C<Set::IntSpan>.

=head2 $set = Set::IntSpan::Island->new( $a, $b )

Extension to C<Set::IntSpan> C<new> method, this double-argument
version creates a set formed by the range a-b. This is equivalent to

  $set = Set::IntSpan::Island->new("$a-$b")

but permits initialization from a list instead of a string. The
arguments $a and $b are expected to be integers - any decimal
component will be truncated.

  new(1.2,2.9) equivalent to new(1,2)

=cut 

sub new {
  my ($this, @args) = @_;
  my $class = ref($this) || $this;
  my $self;
  if(@args <= 1) {
    # relegate to parent
    $self = $class->SUPER::new(@args);
  } elsif (@args==2) {
    # treat as request to create span x-y
    my ($x,$y) = map {int($_)} @args;
    if($x == $y) {
      $self = $class->SUPER::new($x);
    } else {
      $self = $class->SUPER::new("$x-$y");
    }
  } else {
    confess "Set::IntSpan::Island: cannot create object using more than two integers [@args]"; 
  }
  return $self;
}

=pod

=head2 $set_copy = $set->clone()

Creates a copy of C<$set>. Also accessible using C<$set->duplicate()>;

=head2 $set_copy = $set->duplicate()

Same as C<clone()>.

=cut

sub duplicate {
  my $self = shift;
  return $self->new($self->run_list);
}

sub clone {
  my $self = shift;
  return $self->new($self->run_list);
}

=pod

=head2 $olap = $set->overlap( $another_set );

Returns the size of intersection of two sets. Equivalent to

  $set->intersect( $another_set )->size;

The returned value is either 0 (if the sets do not overlap) or positive (if they do).

=cut

sub overlap {
  my ($self,$set) = @_;
  return $self->intersect($set)->size;
}

=pod

=head2 $d = $set->distance( $another_set )

Returns the distance between sets, measured as follows. If the sets
overlap, then the distance is negative and given by

  $d = -$set->overlap( $another_set )

If the sets abut, C<$d> is 1. Here $d can be interpreted as the
difference between the closest edges of the two sets.

The above generalizes to 1+size(hole) if the sets do not overlap and
are composed of multiple islands. The hole used is the one between two
closest islands of the sets.
  
Returns C<undef> if C<$another_set> is not defined, or either C<$set>
or C<$another_set> is empty.

Here are some examples of how the distance is calculated.

   A ----xxxx---xxx-----xx--
   B ------xxx------xx--x---
           !!           !    d=-3

   A ----xxxx---xxx-----xx--
   B ----xxxx---xxx---------
         !!!!   !!!          d=-7

   A ----xxxx---xxx-----xx--
   B --------------x--------
                  ><         d=1

   A ----xxxx---xxx-----xx--
   B ---------------x-------
                  > <        d=2

   A ----xxxx---xxx-----xx--
   B ---------------xx------
                  > <        d=2

   A ----xxxx---xxx-----xx--
   B ---------------xxxx----
                       ><    d=1

=cut

sub distance {
  my ($set1,$set2) = @_;
  return undef unless $set1 && $set2;
  return undef unless $set1->cardinality && $set2->cardinality;
  my $overlap = $set1->overlap($set2);
  if($overlap) {
    return -$overlap;
  } else {
    my $min_d;
    for my $span1 ($set1->sets) {
      for my $span2 ($set2->sets) {
	my $d1 = abs($span1->min - $span2->max);
	my $d2 = abs($span1->max - $span2->min);
	my $d  = $d1 < $d2 ? $d1 : $d2;
	if(! defined $min_d || $d < $min_d) {
	  $min_d = $d;
	}
      }
    }
    return $min_d;
  }
}

=head2 $d = $set->sets()

Returns all spans in $set as C<Set::IntSpan::Island> objects. This method overrides the C<sets> method in C<Set::IntSpan> in order to return sets as Set::IntSpan::Island objects.

=cut

sub sets {
  my $set = shift;
  return map { $set->new($_->run_list) } $set->SUPER::sets();
}

=head2 $new_set = $set->excise( $minlength | $size_set )

Removes all islands smaller than C<$minlength>. If C<$minlength> < 1
then no elements are removed and a copy of the set is returned. Since
only islands smaller than C<$minlength> are removed, the smallest
useful value for C<$minlength> is 2.

If passed a set C<$size_set>, removes all islands whose size is found
in C<$size_set>. This extended functionality allows you to pass in
arbitrary size cutoffs. For example, to remove islands of size <=10

  $new_set = $set->excise( Set::IntSpan->( "(-10" ) )

or to remove islands of size 2-10

  $new_set = $set->excise( Set::IntSpan->( "2-10" ) )

Since size of an island must be non-zero and positive, any negative
elements in the size set will be ignored. The two are therefore equivalent

  $new_set = $set->excise( Set::IntSpan->( "2-10" ) )
  $new_set = $set->excise( Set::IntSpan->( "(--1,2-10" ) )

Using a size set allows you to excise islands larger than a certain
size. For example, to remove all islands 10 or bigger,

  $new_set = $set->excise( Set::IntSpan->( "10-)" ) )

Regardless of input, if all islands are excised (i.e. all elements
from $set are removed), this function will return an empty set.

Contrast C<excise()> to C<keep()>. Use C<excise()> when you have a set of
island sizes you want to remove. Use C<keep()> when you have a set of
island sizes you want to keep. In other words, these are equivalent:

  $set->excise( $size_set )
  $set->keep( $size_set->complement )

Strictly speaking, you can pass in any object as a size limiter, as
long as it implements a C<member()> function which returns 1 if the
size is in the cutoff set and 0 otherwise.

  $filter = Some::Other::Module->new();
  # set $filter parameters according to Some::Other::Module API...
  ...
  # $filter must implement "member" function
  $filter->can("member")
  if($filter->member(10)) {
    print "islands of size 10 will be removed";
  } else {
    print "islands of size 10 will be kept";
  }
  $set->excise($filter);

=cut

sub excise {
  my ($self,$length) = @_;
  if(! ref($length) ) {
    my $set = $self->new();
    map { $set = $set->union($_) } grep($_->size >= $length, $self->sets);
    return $set;
  } elsif ($length->can("member")) {
    my $set = $self->new();
    map { $set = $set->union($_) } grep(! $length->member($_->size), $self->sets);
    return $set;
  } else {
    confess "excise() does not accept a length cutoff of the type you used",ref($length);
  }
}

=head2 $new_set = $set->keep( $maxlength | $size_set )

If passed an integer C<$maxlength>, removes all islands larger than
C<$maxlength>. 

If passed a set C<$size_set>, removes all islands whose size is not found
in C<$size_set>. For example, to keep all islands sized 10 or larger,

  $new_set = $set->keep( Set::IntSpan->( "10-)" ) )

or keep all islands sized 2-10

  $new_set = $set->excise( Set::IntSpan->( "2-10" ) )

Returns an empty set if no islands are kept.

Since size of an island must be non-zero and positive, any negative
elements in the size set will be ignored. The two are therefore equivalent

  $new_set = $set->keep( Set::IntSpan->( "2-10" ) )
  $new_set = $set->keep( Set::IntSpan->( "(--1,2-10" ) )

Contrast C<keep()> to C<excise()>. Use C<keep()> when you have a set of island
sizes you want to keep. Use C<excise()> when you have a set of island
sizes you want to remove. In other words, these are equivalent:

  $set->keep( $size_set )
  $set->excise( $size_set->complement )

Strictly speaking, you can pass in any object as a size limiter, as
long as it implements a C<member()> function which returns 1 if the
size is in the cutoff set and 0 otherwise. See the description of C<excise()> for details.

=cut

sub keep {
  my ($self,$length) = @_;
  my $set = $self->new();
  if(! ref($length) ) {
    map { $set = $set->union($_) } grep($_->size <= $length, $self->sets);
  } elsif ($length->can("member")) {
    map { $set = $set->union($_) } grep($length->member($_->size), $self->sets);
  } else {
    confess "keep() does not accept a length cutoff of the type you used",ref($length);
  }
  return $set;
}

=head2 $set = $set->fill( $maxsize | $size_set )

If passed an integer C<$maxsize>, fills in all holes in $set smaller than C<$maxsize>.

If passed a set C<$size_set>, fills in all holes whose size appears in C<$size_set>.

Strictly speaking, you can pass in any object as a size limiter, as
long as it implements a C<member()> function which returns 1 if the
size is in the cutoff set and 0 otherwise. See the description of C<excise()> for details.

=cut

sub fill {
  my ($self,$length) = @_;
  my $set = $self->duplicate();
  if(! ref($length)) {
    for my $hole ( $set->holes->sets ) {
      if($hole->size <= $length) {
	$set = $set->union($hole);
      }
    }
  } elsif ($length->can("member")) {
    for my $hole ( $set->holes->sets ) {
      if($length->member($hole->size)) {
	$set = $set->union($hole);
      }
    }
  } else {
    confess "fill() does not accept a length cutoff of the type you used",ref($length);
  }
  return $set;
}

=head2 $island_set = $set->find_islands( $integer | $another_set )

Returns a set composed of islands from $set that overlap with C<$integer> or C<$another_set>.

If an integer is passed and C<$integer> is not in C<$set>, an empty set is returned.

If a set is passed and C<$set> and C<$another_set> have an empty intersection, an empty set is returned. 

           set ----xxxx---xxx-----xx--
   another_set ------------x----------
    island_set -----------xxx---------

           set ----xxxx---xxx-----xx--
   another_set ------------xxxxx------
    island_set -----------xxx---------

           set ----xxxx---xxx-----xx--
   another_set ------------xxxxx---xx-
    island_set -----------xxx-----xx--

Contrast this to nearest_island() which returns the closest island(s) that
do not overlap with C<$integer> or C<$another_set>.

=cut

sub find_islands {
  my ($self,$anchor) = @_;
  return $self->new() if ! $anchor;
  if(! ref($anchor)) {
    for my $set ($self->sets) {
      return $set if $set->member($anchor);
    }
    return $self->new();
  } elsif ($anchor->can("intersect")) {
    my $islands = $self->new;
    return $islands if ! $self->overlap($anchor);
    for my $set ($self->sets) {
      $islands->U($set) if $set->overlap($anchor);
    }
    return $islands;
  } else {
    confess "find_islands does not accept an argument of the type you used",ref($anchor);
  }
}

=pod 

=head2 $island_set = $set->nearest_island( $integer | $another_set)

Returns the island(s) in C<$set> closest (but not overlapping) to
C<$integer> or C<$another_set>. If C<$integer> or C<$another_set> lie
exactly between two islands, then the returned set contains these two
islands.

If no non-overlapping islands in $set are found, an empty set is returned.

           set ----xxxx---xxx-----xx--
   another_set ------------x----------
    island_set ----xxxx---------------

           set ----xxxx---xxx-----xx--
   another_set ------------xxxxx------
    island_set -------------------xx--

           set ----xxxx---xxx-----xx--
   another_set ----------xxxxxxx------
    island_set ----xxxx-----------xx--

If $another_set contains multiple islands, such as below, $island_set
may also contain multiple islands.

           set ----xxxx---xxx-----xx--
   another_set ---x----xxx------------
    island_set ----xxxx---xxx---------

Contrast this to C<find_islands()> which returns the island(s) that
overlap with C<$integer> or C<$another_set>.

=cut

sub nearest_island {
  my ($self,$anchor) = @_;
  if(! ref($anchor)) {
    $anchor = $self->new($anchor);
  } elsif ($anchor->can("sets")) {
    # same type of object
  } else {
    confess "nearest_island does not accept an argument of the type you used",ref($anchor);
  }
  my $island = $self->new();
  my $min_d;
  for my $s ($self->sets) {
    for my $ss ($anchor->sets) {
      next if $s->overlap($ss);
      my $d = $s->distance($ss);
      if(! defined $min_d || $d <= $min_d) {
	if(defined $min_d && $d == $min_d) {
	  $island = $island->union($s);
	} else {
	  $min_d = $d;
	  $island = $s;
	}
      }
    }
  }
  return $island;
}

=pod

=head2 $num_islands = $set->num_islands()

Returns the number of islands in the set. If the set is empty, 0 is returned.

=cut 

sub num_islands {
  my $self = shift;
  return scalar $self->spans;
}

=head2 $island = $set->at_island( $island_index )

Returns the island indexed by $island_index. Islands are
0-indexed. For a set with N islands, the first island (ordered
left-to-right) has index 0 and the last island has index N-1.

If $island_index is negative, counting is done back from the last
island.

If $island_index is beyond the last island, undef is returned.

=cut

sub at_island {
  my ($self,$n) = @_;
  my @islands = $self->sets;
  return defined $n && defined $islands[$n] ? $islands[$n] : undef;
}

=pod

=head2 $island = $set->first_island()

Returns the first island of the set. As a side-effect, sets the
iterator to the first island.

If the set is empty, returns undef.

=cut

sub first_island {
  my $self = shift;
  if($self->cardinality) {
    $self->{iterator} = 0;
    return $self->at_island( $self->{iterator} );
  } else {
    $self->{iterator} = undef;
    return undef;
  }
}

=pod

=head2 $island = $set->last_island()

Returns the last island of the set. As a side-effect, sets the
iterator to the last island.

If the set is empty, returns undef.

=cut

sub last_island {
  my $self = shift;
  if($self->cardinality) {
    $self->{iterator} = $self->num_islands - 1;
    return $self->at_island( $self->{iterator} );
  } else {
    $self->{iterator} = undef;
    return undef;
  }
}

=pod

=head2 $island = $set->next_island()

Advances the iterator forward by one island, and returns the next
island. If the iterator is undefined, the first island is returned.

Returns undef if the set is empty or if no more islands are available.

=cut

sub next_island {
  my $self = shift;

  if($self->cardinality) {
    $self->{iterator} = defined $self->{iterator} ? ++$self->{iterator} : 0;
    my $next = $self->at_island( $self->{iterator} );
    if($next) {
      return $next;
    } else {
      $self->{iterator} = undef;
      return undef;
    }
  } else {
    $self->{iterator} = undef;
    return undef;
  }
}

=pod

=head2 $island = $set->prev_island()

Reverses the iterator backward by one island, and returns the previous
island. If the iterator is undefined, the last island is returned.

Returns undef if the set is empty or if no more islands are available.

=cut

sub prev_island {
  my $self = shift;
  if($self->cardinality) {
    $self->{iterator} = defined $self->{iterator} ? --$self->{iterator} : $self->num_islands - 1;
    if($self->{iterator} >= 0) {
      return $self->at_island( $self->{iterator} );
    } else {
      $self->{iterator} = undef;
      return undef;
    }
  } else {
    $self->{iterator} = undef;
    return undef;
  }
}

=pod

=head2 $island = $set->current_island()

Returns the island at the current iterator position.

Returns undef if the set is empty or if the iterator is not defined.

=cut

sub current_island {
  my $self = shift;
  return $self->at_island( $self->{iterator} );
}

=pod

=head2 $cover_data = Set::IntSpan::Island->extract_covers( $set_hash_ref )

Given a C<$set_hash> reference

  { id1=>$set1, id2=>$set2, ..., idn=>$setn}

where C<$setj> is a finite C<Set::IntSpan::Island> object and C<idN>
is a unique key, C<extract_covers> performs an exhaustive intersection
of all sets and returns a list of all covers and set memberships. For
example, given the id/runlist combination 

  a 10-15 
  b 12 
  c 14-20 
  d 25

The covers are

  10-11 a
  12    a b
  13    a
  14-15 a c
  16-20 c
  21-24 -
  25    d

The cover data is returned as an array reference and its structure is

  [ [ $cover_set1, [ id11, id12, id13, ... ] ],
    [ $cover_set2, [ id21, id22, id23, ... ] ],
    ...
  ]

If a cover contains no elements, then its entry is

  [ $cover_set, [ ] ]

=cut

sub extract_covers {
  my ($self,$sets) = @_;

  if(! $sets || ref($sets) ne "HASH") {
    return [];
  }

  # decompose all input sets into spans
  my @sets;
  for my $id (keys %$sets) {
    confess "value in hash is not a set object" unless $sets->{$id}->can("sets");
    for my $span ($sets->{$id}->sets) {
      push @sets,[$id,$span];
    }
  }
  # order the spans by increasing min and increasing max
  @sets = sort {$a->[1]->min <=> $b->[1]->min || $a->[1]->max <=> $b->[1]->max} @sets;
  # register integers at which cover set membership may change - these are the
  # integers at set boundaries
  my %edges;
  for my $set (@sets) {
    map {$edges{$_}++} ( map { ($_->[1]->min-1,$_->[1]->min,$_->[1]->max,$_->[1]->max+1) } $set );
  }
  my @edges = sort {$a <=> $b} keys %edges;
  # first and last edge are not part of any set (min(leftmost)-1, max(rightmost)+1) - remove them
  splice(@edges,0,1);
  splice(@edges,-1,1);
  my $i = 0;
  my $j_low = 0;
  my $covers;
  #print "edges ",join(" ",@edges),"\n";
  while($i < @edges) {
    my $edge      = $edges[$i];
    my $edge_next = $edges[$i+1];
    my $cover;
    if(! defined $edge_next || $edge + 1 == $edge_next) {
      $cover = $self->new($edge);
      $i++;
    } else {
      $cover = $self->new($edge,$edge_next);
      $i += 2;
    }
    #printf("cover %3d %3d    j_low %d\n",$cover->min,$cover->max,$j_low);
    my $found;
    my $j_low_incr = 0;
    push @$covers, [ $cover , []];
    for my $j ($j_low..@sets-1) {
      my ($id,$set) = @{$sets[$j]};
      my $ol  = $set->overlap($cover);
      if($ol) {
	$found = 1;
	#print "      ",$sets[$j][0]," ",$set->run_list,"\n" if $ol;
	push @{$covers->[-1][1]}, $id;
      } else {
	if($found) {
	  last if $set->min > $cover->max;
	} else {
	  $j_low_incr++;
	}
      }
    }
    if(@$covers > 1 &&
       join("",@{$covers->[-1][1]}) eq join("",@{$covers->[-2][1]})) {
      $covers->[-2][0] = $covers->[-2][0]->union ($covers->[-1][0]);
      splice(@$covers,-1,1);
    }
    $j_low += $j_low_incr if $found;
  }
  return $covers;
}

1;

__END__

=head1 AUTHOR

Martin Krzywinski <martink@bcgsc.ca>

=head1 ACKNOWLEDGMENTS

=item * Steve McDougall <swmcd@theworld.com> (C<Set::IntSpan>)

=item * Adam Janin (testing)

=head1 HISTORY

=over

=item v0.10 3 Mar 2010

Now inherits from Set::IntSpan vis C<parent> pragma.

Added clone() as an alias to duplicate().

On error, now C<confess> is used instead of C<croak>.

Expanded testing, now with Test::More.

Minor style adjustments in documentation.

=item v0.05 22 Sep 2008

Minor cosmetic fixes.

=item v0.04 17 Sep 2008

Modified excise(), distance() and fill(). Added keep().

=item v0.03 10 April 2007

More comprehensive extract_cover testing after bug in v0.01 was reported.

=item v0.02 12 Mar 2007

Added island iterator.

=item v0.01 5 Mar 2007

Release.

=back

=head1 SEE ALSO

C<Set::IntSpan> by Steven McDougall

=head1 COPYRIGHT

Copyright (c) 2007 by Martin Krzywinski. This module is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
