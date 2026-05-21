package TUI::StdDlg::FileCollection;
# ABSTRACT: Sorted collection of file and directory search entries

use 5.010;
use strict;
use warnings;

our $VERSION = '2.000001';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';
our @EXPORT = qw(
  TFileCollection
  new_TFileCollection
);

use Class::Struct;
use TUI::toolkit;
use TUI::toolkit::Types qw(
  is_Object
  :types
);

use TUI::Objects::SortedCollection;
use TUI::StdDlg::Const qw( FA_DIREC );

struct TSearchRec => [
  attr => '$',
  time => '$',
  size => '$',
  name => '$',
];

sub TFileCollection() { __PACKAGE__ }
sub name() { 'TFileCollection' };
sub new_TFileCollection { __PACKAGE__->from(@_) }

extends TSortedCollection;

# predeclare private methods
my (
  $getName,
  $attr,
);

sub BUILDARGS {    # \%args (|%args)
  state $sig = signature(
    method => 1,
    named => [
      limit => Int, { alias => 'aLimit' },
      delta => Int, { alias => 'aDelta' },
    ],
    caller_level => +1,
  );
  my ( $class, $args ) = $sig->( @_ );
  return { %$args };
}

sub from {    # $obj ($aLimit, $aDelta)
  state $sig = signature(
    method => 1,
    pos => [Int, Int],
  );
  my ( $class, @args ) = $sig->( @_ );
  return $class->new( limit => $args[0], delta => $args[1] );
}

$getName = sub {    # $name ($k)
  assert ( @_ == 1 );
  assert ( is_Object $_[0] );
  goto &TSearchRec::name;
};

$attr = sub {    # $attr ($k)
  assert ( @_ == 1 );
  assert ( is_Object $_[0] );
  goto &TSearchRec::attr;
};

sub compare {    # $cmp ($key1, $key2)
  state $sig = signature(
    method => Object,
    pos    => [ArrayLike, ArrayLike],
  );
  my ( $self, $key1, $key2 ) = $sig->( @_ );
  return 0
    if ( $key1->$getName() cmp $key2->$getName() ) == 0;

  return 1
    if ( $key1->$getName() cmp ".." ) == 0;
  return -1
    if ( $key2->$getName() cmp ".." ) == 0;

  return 1
    if ( $key1->$attr() & FA_DIREC ) != 0
    && ( $key2->$attr() & FA_DIREC ) == 0;
  return -1
    if ( $key2->$attr() & FA_DIREC ) != 0
    && ( $key1->$attr() & FA_DIREC ) == 0;

  return $key1->$getName() cmp $key2->$getName();
} #/ sub compare

1

__END__

=pod

=head1 NAME

TUI::StdDlg::FileCollection - sorted collection of file system entries

=head1 HIERARCHY

  TObject
    TCollection
      TSortedCollection
        TFileCollection

=head1 SYNOPSIS

  use TUI::StdDlg;

  my $files = new_TFileCollection(
    50,   # limit
    10    # delta
  );

=head1 DESCRIPTION

C<TFileCollection> implements a sorted collection used by standard
TUI::Vision dialogs to manage file and directory search results.

The collection stores file system entries and maintains them in sorted order
according to a comparison strategy defined by the class. It is primarily used
internally by file selection and directory browsing dialogs.

This class derives from C<TSortedCollection> and specializes the comparison
logic for file-related data.

=head1 STRUCTURES

=head2 TSearchRec

Represents a file search record.

This structure stores metadata for a file system entry and is populated
during directory and file searches performed by file collections.

The structure contains the following fields:

=over

=item attr

Attribute flags associated with the file entry (I<Int>).

=item time

Timestamp of the file entry (I<Int>).

=item size

Size of the file in bytes (I<Int>).

=item name

Name of the file entry (I<Str>).

=back

=head1 CONSTRUCTOR

=head2 new

  my $collection = TUI::StdDlg::FileCollection->new(
    limit => $limit,
    delta => $delta
  );

Creates a new file collection.

=over

=item limit

Initial capacity of the collection (I<Int>).

=item delta

Growth increment used when the collection exceeds its current capacity
(I<Int>).

=back

=head2 new_TFileCollection

  my $collection = new_TFileCollection($limit | undef, $delta | undef);

Factory-style constructor using positional arguments.

=head1 METHODS

=head2 compare

  my $cmp = $collection->compare($key1, $key2);

Compares two file collection keys.

This method defines the sort order of the collection and is invoked internally
by the base sorted collection logic. It returns a negative, zero, or positive
value depending on the ordering of the supplied keys.

=head1 USAGE NOTES

C<TFileCollection> is typically not used directly by application code.

Instances of this class are created and managed by standard dialog components
such as file selection dialogs. Application code interacts with the dialog
rather than the underlying collection.

=head1 SEE ALSO

L<TUI::StdDlg::FileDialog>,
L<TUI::Objects::SortedCollection>,
L<TUI::StdDlg::Const>

=head1 AUTHORS

=over

=item * Borland International (original Turbo Vision design)

=item * J. Schneider <brickpool@cpan.org> (Perl implementation and maintenance)

=back

=head1 COPYRIGHT AND LICENSE

Copyright (c) 1990-1994, 1997 by Borland International

Copyright (c) 2026 the L</AUTHORS> as listed above.

This software is licensed under the MIT license (see the LICENSE file, which is
part of the distribution).

=cut

