package SkewHeap::PP;
# ABSTRACT: a fast and flexible heap structure
$SkewHeap::PP::VERSION = '0.02';

#-------------------------------------------------------------------------------
# Boilerplate
#-------------------------------------------------------------------------------
use strict;
use warnings;

#-------------------------------------------------------------------------------
# Node array index constants
#-------------------------------------------------------------------------------
my $KEY   = 0;
my $LEFT  = 1;
my $RIGHT = 2;

#-------------------------------------------------------------------------------
# Skew heap array index constants
#-------------------------------------------------------------------------------
my $CMP  = 0;
my $SIZE = 1;
my $ROOT = 2;

#-------------------------------------------------------------------------------
# Exports
#-------------------------------------------------------------------------------
use parent 'Exporter';
our @EXPORT = qw(
  skew
  skew_count
  skew_is_empty
  skew_peek
  skew_put
  skew_take
  skew_merge
  skew_merge_safe
  skew_explain
);

#-------------------------------------------------------------------------------
# Common interface
#-------------------------------------------------------------------------------
sub skew (&)          { [ $_[0], 0, undef ] }
sub skew_count ($)    { $_[0][$SIZE] }
sub skew_is_empty ($) { $_[0][$SIZE] == 0 }

sub clone_node {
  my $node = shift;
  return unless defined $node;

  return [
    $node->[$KEY],
    clone_node($node->[$LEFT]),
    clone_node($node->[$RIGHT]),
  ];
}

sub merge_nodes_safe {
  my ($cmp, $a, $b) = @_;

  return clone_node($a) unless defined $b;
  return clone_node($b) unless defined $a;

  ($a, $b) = ($b, $a)
    if $cmp->($a->[$KEY], $b->[$KEY]) > 0;

  return [
    $a->[$KEY],
    merge_nodes_safe($cmp, $b, $a->[$RIGHT]),
    clone_node($a->[$LEFT]),
  ];
}

sub merge_nodes {
  my ($cmp, $a, $b) = @_;

  return $a unless defined $b;
  return $b unless defined $a;

  ($a, $b) = ($b, $a)
    if $cmp->($a->[$KEY], $b->[$KEY]) > 0;

  my $tmp      = $a->[$RIGHT];
  $a->[$RIGHT] = $a->[$LEFT];
  $a->[$LEFT]  = merge_nodes($cmp, $b, $tmp);

  return $a;
}

sub skew_peek {
  my $skew = shift;
  return if skew_is_empty($skew);
  return $skew->[$ROOT][$KEY];
}

sub skew_take {
  my ($skew, $want) = @_;
  my @taken;

  while (($want || 1) > @taken && $skew->[$SIZE] > 0) {
    push @taken, $skew->[$ROOT][$KEY];

    $skew->[$ROOT] = merge_nodes(
      $skew->[$CMP],
      $skew->[$ROOT][$LEFT],
      $skew->[$ROOT][$RIGHT],
    );

    --$skew->[$SIZE];
  }

  return defined($want) ? @taken : $taken[0];
}

sub skew_put {
  my $skew = shift;

  for (@_) {
    $skew->[$ROOT] = merge_nodes(
      $skew->[$CMP],
      $skew->[$ROOT],
      [$_, undef, undef],
    );

    ++$skew->[$SIZE];
  }

  return $skew->[$SIZE];
}

sub skew_merge {
  my $skew = shift;

  for (@_) {
    $skew->[$ROOT] = merge_nodes(
      $skew->[$CMP],
      $skew->[$ROOT],
      $_->[$ROOT],
    );

    $skew->[$SIZE] += $_->[$SIZE];
    $_->[$ROOT] = undef;
    $_->[$SIZE] = 0;
  }

  return $skew;
}

sub skew_merge_safe {
  my $skew = [ $_[0][$CMP], 0, undef ];

  for (@_) {
    $skew->[$ROOT] = merge_nodes_non_destructive(
      $skew->[$CMP],
      $skew->[$ROOT],
      $_->[$ROOT],
    );

    $skew->[$SIZE] += $_->[$SIZE];
  }

  return $skew;
}

sub node_explain {
  my $node = shift;
  my $indent_size = shift || 0;

  my $indent = '   ' x $indent_size;
  print $indent.'- Node: '.$node->[$KEY]."\n";

  if ($node->[$LEFT]) {
    node_explain($node->[$LEFT], $indent_size + 1);
  }

  if ($node->[$RIGHT]) {
    node_explain($node->[$RIGHT], $indent_size + 1);
  }
}

sub skew_explain {
  my $skew = shift;
  my $n = skew_count($skew);
  print "SkewHeap<size=$n>\n";
  node_explain($skew->[$ROOT], 1);
}

#-------------------------------------------------------------------------------
# Object inteface
#-------------------------------------------------------------------------------
sub count    { goto \&skew_count    }
sub is_empty { goto \&skew_is_empty }
sub peek     { goto \&skew_peek     }
sub put      { goto \&skew_put      }
sub take     { goto \&skew_take     }
sub merge    { goto \&skew_merge    }
sub explain  { goto \&skew_explain  }

sub new {
  my ($class, $cmp) = @_;
  bless(skew(\&$cmp), $class);
}

sub merge_safe {
  my $self = shift;
  my $new = skew_merge_safe($self->[$CMP], @_);
  bless($new, ref($self));
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SkewHeap::PP - a fast and flexible heap structure

=head1 VERSION

version 0.02

=head1 SYNOPSIS

  use SkewHeap::PP;

  my $s = skew{ $_[0] <=> $_[1] };

  # Add items one at a time
  for (@items) {
    skew_put($s, $_);
  }

  # Or as a batch
  skew_put($s, @items);

  # Take individual items
  my @taken;
  until (skew_is_empty($s)) {
    say "Taking: " . skew_peek($s);

    push @taken, skew_take($s);

    say "Left in queue: " . skew_count($s);
  }

  # Or take a batch
  my @take_ten = skew_take($s, 10);

  # Destructively merge two heaps
  skew_merge($s, $another_skew_heap);

  # Non-destructively merge heaps
  my $new_heap = skew_merge($a, $b, $c);

=head1 DESCRIPTION

A skew heap is a memory efficient, self-adjusting heap with an amortized
performance of O(log n) or better. C<SkewHeap:PP> is implemented in pure perl,
yet performs comparably to L<SkewHeap>.

The key feature of a skew heap is the ability to quickly and efficiently merge
two heaps together.

=head2 skew

Creates a new skew heap. Requires a single argument, a code block that knows how
to prioritize the values to be stored in the heap.

  my $heap = skew{ $_[0] <=> $_[1] };

=head2 skew_count

Returns the number of elements in the heap.

=head2 skew_is_empty

Returns true if the heap is empty.

=head2 skew_peek

Returns the top element in the heap without removing it from the heap.

=head2 skew_take

Removes and returns the top element from the heap.

  my $item = skew_take($heap);

Optionally, multiple elements may be returned from the heap by passing the
desired number of elements, in which case a list is returned, rather than a
single, scalar element. If there are fewer elements available than requested,
as many as a immediately available are returned.

  # Get 10 elements
  my @items = skew_take($heap, 10);

=head2 skew_put

Adds one or more items to the heap.

  skew_put($s, 42);
  skew_put($s, 42, 6, 8);

=head2 skew_merge

Merges any number of heaps into the first argument I<destructively>. After
merging, the first heap passed in will contain all of the items in the heaps
passed in subsequent arguments. After merging, the subsequent heaps will be
empty. The comparison function used for ordering is that of the first heap
passed in. The return value is the first heap into which the other heaps were
merged.

  skew_merge($x, $y, $z); # $x contains all elements of $x, $y, and $z;
                          # $y and $z are now empty.

=head2 skew_merge_safe

Non-destructively merges any number of heaps into a new heap whose comparison
function will be that of the first heap in the list to merge. Returns a new
heap containing all of the items in each of the other heaps. The other heaps'
contents will remain intact.

=head2 skew_explain

Prints out a representation of the internal tree structure for debugging.

=head1 OBJECT INTERFACE

An object interface is provided that maps directly to the similarly named
C<skew_*> routines.

=over

=item new - SEE L</skew>

=item count - SEE L</skew_count>

=item is_empty - SEE L</skew_is_empty>

=item peek - SEE L</skew_peek>

=item take - SEE L</skew_take>

=item put - SEE L</skew_put>

=item merge - SEE L</skew_merge>

=item merge_safe - SEE L</skew_merge_safe>

=item explain = SEE L</skew_explain>

=back

=head1 SEE ALSO

=over

=item L<SkewHeap>

Written in XS and roughly 2x faster.

=item L<https://en.wikipedia.org/wiki/Skew_heap>

=back

=head1 AUTHOR

Jeff Ober <sysread@fastmail.fm>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Jeff Ober.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
