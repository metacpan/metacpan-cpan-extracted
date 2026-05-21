package TUI::Objects::Collection;
# ABSTRACT: TCollection provides a mechanism for managing any data collection.

use strict;
use warnings;

our $VERSION = '2.000001';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';
our @EXPORT = qw(
  TCollection
  new_TCollection
);

use TUI::Objects::NSCollection;
use TUI::toolkit;

sub TCollection() { __PACKAGE__ }
sub name() { 'TCollection' };
sub new_TCollection { __PACKAGE__->from(@_) }

extends TNSCollection;

1

__END__

=pod

=head1 NAME

TUI::Objects::Collection - dynamic container for managing collections of items

=head1 HIERARCHY

  TObject
    TNSCollection
      TCollection
        TStringCollection

=head1 SYNOPSIS

  use TUI::Objects;

  my $col = TCollection->new(
    limit => 10,
    delta => 5
  );

  $col->insert('alpha');
  $col->insert('beta');
  $col->atInsert(1, 'between');

  my $idx = $col->indexOf('beta');
  my $first = $col->at(0);

  my $found = $col->firstThat(
    sub { index($_, 'bet') == 0 },
    undef
  );

  $col->forEach(sub {
    my $item = $_;
    # ... process each item
  }, undef);

=head1 DESCRIPTION

C<TCollection> provides a dynamically sizable container for storing and
accessing arbitrary items. It behaves similarly to a resizable array and is
used throughout the TUI::Vision framework as the base class for specialized
collection types.

The collection automatically grows when its capacity is exceeded. Growth
behavior is controlled by the C<limit> and C<delta> attributes.

Several specialized collections derive from C<TCollection>, including sorted
collections, string collections, and resource collections.

C<TNSCollection> represents the non-storable base variant used internally,
while C<TCollection> provides the public, reusable collection interface.

=head2 Commonly Used Features

C<TCollection> is both a base class and a practical general-purpose container
for application code. In day-to-day usage, the most common operations are
construction with C<limit>/C<delta>, insertion with C<insert()> or
C<atInsert()>, random access with C<at()>, replacement with C<atPut()>, and
removal with C<remove()>, C<atRemove()>, or C<atFree()>.

Search and traversal are typically done with C<indexOf()>, C<firstThat()>,
C<lastThat()>, and C<forEach()>. For lifecycle and cleanup, C<removeAll()>,
C<freeAll()>, and C<pack()> are frequently used to reset state or compact the
collection.

Specialized containers like C<TStringCollection> and C<TSortedCollection>
build on this behavior, so understanding C<TCollection> methods is directly
useful even when working with derived classes.

=head1 CONSTRUCTOR

=head2 new

  my $collection = TCollection->new(
    limit => $limit,
    delta => $delta
  );

Creates a new collection.

=over

=item limit

Initial capacity of the collection.

=item delta

Growth increment used when the collection exceeds its current capacity.

=back

=head2 new_TCollection

  my $collection = new_TCollection($limit | undef, $delta | undef);

Factory-style constructor using positional arguments.

=head1 ATTRIBUTES

The following attributes represent the internal state of the collection.

=over

=item items

Array reference holding the items in the collection.

=item count

Current number of items stored in the collection.

=item limit

The current capacity of the collection. When the number of elements reaches
this value, the collection grows according to C<delta>.

=item delta

Growth increment used when the collection needs to expand. Increasing the
limit by larger deltas reduces the frequency of reallocations.

=item shouldDelete

Boolean flag indicating whether items should be freed when removed from the
collection.

=back

=head1 METHODS

=head2 at

  my $item = $collection->at($index);

Returns the item at the specified index.

=head2 atFree

  $collection->atFree($index);

Removes the item at the specified index and frees it.

=head2 atInsert

  $collection->atInsert($index, $item | undef);

Inserts an item at the specified index, shifting subsequent items.

=head2 atPut

  $collection->atPut($index, $item | undef);

Replaces the item at the specified index.

=head2 atRemove

  $collection->atRemove($index);

Removes the item at the specified index without freeing it.

=head2 dataSize

  my $size = $collection->dataSize();

Returns the number of scalar values transferred via C<getData> and C<setData>.

For collections, this value is always C<1>.

=head2 error

  $collection->error($code, $info);

Handles collection errors.

All bounds and consistency checks in collection methods route errors through
this method. Subclasses may override C<error> to implement custom error
handling instead of terminating execution.

=head2 firstThat

  my $item = $collection->firstThat(\&test, $arg | undef);

Returns the first item (scanning forward) for which the test function returns
true.

=head2 forEach

  $collection->forEach(\&action, $arg | undef);

Invokes the action for each item in the collection.

=head2 free

  $collection->free($item);

Removes the specified item from the collection and frees it.

=head2 freeAll

  $collection->freeAll();

Frees all items in the collection and clears it.

=head2 freeItem

  $collection->freeItem($item);

Frees a single item. This method may be overridden by subclasses to customize
item disposal.

=head2 indexOf

  my $index = $collection->indexOf($item | undef);

Returns the index of the specified item, or C<-1> if not found.

=head2 insert

  my $index = $collection->insert($item | undef);

Inserts an item at the end of the collection and returns its index.

=head2 lastThat

  my $item = $collection->lastThat(\&test, $arg | undef);

Returns the last matching item by scanning the collection in reverse order.

=head2 pack

  $collection->pack();

Removes undefined gaps from the collection.

=head2 remove

  $collection->remove($item);

Removes the specified item from the collection without freeing it.

=head2 removeAll

  $collection->removeAll();

Removes all items from the collection without freeing them.

=head2 setLimit

  $collection->setLimit($limit);

Sets a new capacity limit for the collection and reallocates internal storage
as needed.

=head2 shutDown

  $collection->shutDown();

Performs shutdown processing for the collection.

=head1 SEE ALSO

L<TUI::Objects::SortedCollection>,
L<TUI::Objects::StringCollection>,
L<TUI::Objects::Object>

=head1 AUTHORS

=over

=item * Borland International (original Turbo Vision design)

=item * J. Schneider <brickpool@cpan.org> (Perl implementation and maintenance)

=back

=head1 COPYRIGHT AND LICENSE

Copyright (c) 1990-1994, 1997 by Borland International

Copyright (c) 2021-2026 the L</AUTHORS> as listed above.

This software is licensed under the MIT license (see the LICENSE file, which is
part of the distribution).

=cut
