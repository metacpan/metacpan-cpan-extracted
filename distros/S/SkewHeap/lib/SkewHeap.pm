package SkewHeap;

our $XS_VERSION = our $VERSION = '0.05';
$VERSION =~ tr/_//;

use strict;
use warnings;

require XSLoader;
XSLoader::load('SkewHeap', $XS_VERSION);

use Carp;
use Exporter;

use parent 'Exporter';

our @EXPORT = qw(skewheap);

=head1 NAME

SkewHeap - A fast and flexible heap structure

=head1 SYNOPSIS

  use SkewHeap;

  my $heap = skewheap{ $a <=> $b };
  $heap->put(42);
  $heap->put(35);
  $heap->put(200, 62);

  $heap->top;  # 35
  $heap->size; # 4

  $heap->take; # 35
  $heap->take; # 42
  $heap->take; # 62
  $heap->take; # 200

  my $merged_heap = $heap->merge($other_skewheap);

=head1 DESCRIPTION

A skew heap is a memory efficient, self-adjusting heap (or priority queue) with
an amortized performance of O(log n) (or better). C<SkewHeap> is implemented in
C<C>/C<XS>.

The key feature of a skew heap is the ability to quickly and efficiently merge
two heaps together.

=head1 METHODS

=head2 skewheap

Creates a new C<SkewHeap> which will be sorted in ascending order using the
comparison subroutine passed in. This sub has the same semantics as Perl's
C<sort>, returning -1 if C<$a E<lt> $b>, 1 if C<$a E<gt> $b>, or 0 if
C<$a == $b>.

=head2 size

Returns the number of elements in the heap.

=head2 top

Returns the next element which would be returned by L</take> without removing
it from the heap.

=head2 put

Inserts one or more new elements into the heap.

=head2 take

Removes and returns the next element from the heap.

=head2 merge

Non-destructively merges two heaps into a new heap. Returns the new heap.

=head1 AUTHOR

Jeff Ober <sysread@fastmail.fm>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Jeff Ober. This is free software; you
can redistribute it and/or modify it under the same terms as the Perl 5
programming language system itself.

=cut

1;
