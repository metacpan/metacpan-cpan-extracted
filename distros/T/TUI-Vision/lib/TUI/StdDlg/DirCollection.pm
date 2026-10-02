package TUI::StdDlg::DirCollection;
# ABSTRACT: A collection of directory entries

use 5.010;
use strict;
use warnings;

our $VERSION = '2.000002';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';
our @EXPORT = qw(
  TDirCollection
  new_TDirCollection
);

use TUI::toolkit;

use TUI::Objects::NSCollection;
use TUI::Objects::Collection;

sub TDirCollection() { __PACKAGE__ }
sub name() { 'TDirCollection' };
sub new_TDirCollection { __PACKAGE__->from(@_) }

extends TCollection;

sub at {    # $dirEntry|undef ($index)
  goto &TUI::Objects::NSCollection::at;
}

sub indexOf {    # $index ($item|undef)
  goto &TUI::Objects::NSCollection::indexOf;
}

sub remove {    # void ($item)
  goto &TUI::Objects::NSCollection::remove;
}

sub free {    # void ($item)
  goto &TUI::Objects::NSCollection::free;
}

sub atInsert {    # void ($index, $item|undef)
  goto &TUI::Objects::NSCollection::atInsert;
}

sub atPut {    # void ($index, $item|undef)
  goto &TUI::Objects::NSCollection::atInsert;
}

sub insert {    # $index ($item|undef)
  goto &TUI::Objects::NSCollection::insert;
}

sub firstThat {    # $dirEntry|undef (\&Test, $arg|undef)
  goto &TUI::Objects::NSCollection::firstThat;
}

sub lastThat {    # $dirEntry|undef (\&Test, $arg|undef)
  goto &TUI::Objects::NSCollection::lastThat;
}

1

__END__

=pod

=head1 NAME

TUI::StdDlg::DirCollection - collection of directory entries

=head1 HIERARCHY

  TObject
    TNSCollection
      TCollection
        TDirCollection

=head1 SYNOPSIS

  use TUI::StdDlg;

  my $dirs = new_TDirCollection(50, 10);

=head1 DESCRIPTION

C<TDirCollection> is a collection used by the standard dialog subsystem to
store directory entries. It is a typed collection in the sense that the items
handled by its public operations are directory entry objects 
(L<TDirEntry|TUI::StdDlg::DirEntry>).

Capacity management follows the standard collection model: the collection is
created with an initial capacity and grows when needed.

=head1 CONSTRUCTOR

=head2 new

  my $dirs = TDirCollection->new(
    limit => $limit,
    delta => $delta
  );

Creates a new directory collection.

=over

=item limit

Initial capacity of the collection (I<Int>).

=item delta

Growth increment used when the collection exceeds its current capacity (I<Int>).

=back

=head2 new_TDirCollection

  my $dirs = new_TDirCollection($limit, $delta);

Factory-style constructor using positional arguments.

=head1 METHODS

The following methods operate on directory entry objects 
(L<TDirEntry|TUI::StdDlg::DirEntry>) rather than generic items.

=head2 at

  my $entry | undef = $dirs->at($index);

Returns the L<TDirEntry|TUI::StdDlg::DirEntry> at the specified index.

=head2 atInsert

  $dirs->atInsert($index, $entry | undef);

Inserts a L<TDirEntry|TUI::StdDlg::DirEntry> at the specified index.

=head2 atPut

  $dirs->atPut($index, $entry | undef);

Replaces the L<TDirEntry|TUI::StdDlg::DirEntry> at the specified index.

=head2 firstThat

  my $entry | undef = $dirs->firstThat(\&test, $arg | undef);

Returns the first L<TDirEntry|TUI::StdDlg::DirEntry> for which the test 
function returns true.

=head2 lastThat

  my $entry | undef = $dirs->lastThat(\&test, $arg | undef);

Returns the last matching L<TDirEntry|TUI::StdDlg::DirEntry> by scanning the 
collection in reverse.

=head2 free

  $dirs->free($entry);

Removes the specified L<TDirEntry|TUI::StdDlg::DirEntry> from the collection 
and frees it.

=head2 indexOf

  my $index = $dirs->indexOf($entry | undef);

Returns the index of the specified L<TDirEntry|TUI::StdDlg::DirEntry>, or C<-1> 
if not found.

=head2 insert

  my $index = $dirs->insert($entry | undef);

Inserts a L<TDirEntry|TUI::StdDlg::DirEntry> into the collection and returns 
its index.

=head2 remove

  $dirs->remove($entry);

Removes the specified L<TDirEntry|TUI::StdDlg::DirEntry> from the collection 
without freeing it.

=head1 SEE ALSO

L<TDirListBox|TUI::StdDlg::DirListBox>,
L<TChDirDialog|TUI::StdDlg::ChDirDialog>,
L<TCollection|TUI::Objects::Collection>

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

