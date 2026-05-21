package TUI::Objects::SortedCollection;
# ABSTRACT: sorted collection base class

use strict;
use warnings;

our $VERSION = '2.000001';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';
our @EXPORT = qw(
  TSortedCollection
  new_TSortedCollection
);

use TUI::Objects::NSSortedCollection;
use TUI::toolkit;

sub TSortedCollection() { __PACKAGE__ }
sub name() { 'TSortedCollection' };
sub new_TSortedCollection { __PACKAGE__->from(@_) }

extends TNSSortedCollection;

sub compare {    # $cmp ($key1, $key2)
  return 0;
}

1

__END__

=pod

=head1 NAME

TUI::Objects::SortedCollection - sorted collection base class

=head1 HIERARCHY

  TObject
    TCollection
      TSortedCollection
        TStringCollection

=head1 SYNOPSIS

  package MySortedCollection;
  use Moo;
  use TUI::Objects;
  extends TSortedCollection;

  sub keyOf {
    my ( $self, $item ) = @_;
    return $item->{name};
  }

  sub compare {
    my ( $self, $key1, $key2 ) = @_;
    return lc($key1) cmp lc($key2);
  }

  package main;

  my $coll = MySortedCollection->new(
    limit => 10,
    delta => 5
  );

  $coll->insert({ name => 'Gamma' });
  $coll->insert({ name => 'alpha' });
  $coll->insert({ name => 'Beta'  });

  # Sorted automatically via keyOf + compare.
  my $second = $coll->at(1);   # { name => 'Beta' }

  my $index;
  my $found = $coll->search('beta', \$index);
  my $pos   = $coll->indexOf($second);

=head1 DESCRIPTION

C<TSortedCollection> implements a collection that automatically maintains its
elements in sorted order. Items inserted into the collection are placed at the
appropriate position based on a comparison function supplied by derived
classes.

The class itself does not define how items are compared or which part of an
item constitutes the sort key. Subclasses must override C<keyOf> to extract a
key from an item and C<compare> to define the ordering of those keys.

Duplicate handling is configurable via the C<duplicates> attribute. By default,
items with identical keys are rejected. When duplicates are enabled, items with
equal keys are inserted adjacent to existing entries.

C<TSortedCollection> is typically used as a base class for domain-specific
collections such as string collections.

=head2 Commonly Used Features

Typical usage follows a short cycle: create the collection, insert items, and
use C<search> or C<indexOf> for lookup. For subclasses, the practical
requirements are to implement C<keyOf> and C<compare>; duplicate handling is
then adjusted as needed through C<duplicates>.

=head1 ATTRIBUTES

=over

=item duplicates

Boolean flag controlling whether duplicate keys are permitted.  
If false (the default), duplicate items are rejected. If true, duplicate items
are inserted next to existing items with the same key.

=back

=head1 CONSTRUCTOR

=head2 new

  my $coll = TSortedCollection->new(
    limit => $limit,
    delta => $delta
  );

Creates a new sorted collection with the specified initial capacity and growth
policy.

=over

=item limit

Initial capacity of the collection (I<Int>).

=item delta

Growth increment of the collection (I<Int>).  
A value of zero disables automatic growth.

=back

=head2 new_TSortedCollection

  my $coll = new_TSortedCollection($limit, $delta);

Factory-style constructor using positional arguments.

This constructor is equivalent to calling C<new> with named parameters and is
provided for compatibility with traditional Turbo Vision construction patterns.

=head1 METHODS

=head2 compare

  my $cmp = $coll->compare($key1, $key2);

Compares two keys and returns an integer indicating their relative order.

The return value follows the standard convention:

=over 4

=item *

negative value if C<$key1> is less than C<$key2>

=item *

zero if both keys are equal

=item *

positive value if C<$key1> is greater than C<$key2>

=back

Subclasses must override this method.

=head2 indexOf

  my $index = $coll->indexOf($item | undef);

Returns the index of the specified item, or C<-1> if the item is not present in
the collection.

=head2 insert

  my $index = $coll->insert($item | undef);

Inserts an item into the collection at the position determined by its sort key.

If an item with an identical key already exists, the behavior depends on the
value of the C<duplicates> attribute.

=head2 keyOf

  my $key = $coll->keyOf($item | undef);

Returns the sort key associated with the specified item.

Subclasses must override this method.

=head2 search

  my $found = $coll->search($key | undef, \$index);

Searches for an item with the specified key.

Returns true if the key is found. If found, C<$index> contains the position of
the matching item. Otherwise, C<$index> indicates the position where such an
item would be inserted.

=head1 AUTHORS

=over

=item * Borland International (original Turbo Vision design)

=item * J. Schneider <brickpool@cpan.org> (Perl implementation and maintenance)

=back

=head1 COPYRIGHT AND LICENSE

Copyright (c) 1990-1994, 1997 by Borland International

Copyright (c) 2024-2026 the L</AUTHORS> as listed above.

This software is licensed under the MIT license (see the LICENSE file, which is
part of the distribution).

=cut
