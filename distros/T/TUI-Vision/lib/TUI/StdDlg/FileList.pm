package TUI::StdDlg::FileList;
# ABSTRACT: TListBox subclass for file lists in TFileList

use 5.010;
use strict;
use warnings;

our $VERSION = '2.000001';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';

our @EXPORT = qw(
  TFileList
  new_TFileList
);

use TUI::toolkit;
use TUI::toolkit::Types qw(
  Maybe
  is_Object
  :types
);

use TUI::Const qw( EOS );
use TUI::Drivers::Const qw(
  evBroadcast
  kbShift
);
use TUI::MsgBox::Const qw(
  mfOKButton
  mfWarning
);
use TUI::MsgBox::MsgBoxText qw( messageBox );
use TUI::Objects::Const qw( maxCollectionSize );
use TUI::StdDlg::Const qw(
  cmFileDoubleClicked
  cmFileFocused
  :FA_
);
use TUI::StdDlg::FileCollection;
use TUI::StdDlg::SortedListBox;
use TUI::StdDlg::Dir qw(
  findfirst
  findnext
  fnmerge
  fnsplit
);
use TUI::StdDlg::Util qw( fexpand );
use TUI::Views::Util qw( message );

sub TFileList() { __PACKAGE__ }
sub name() { 'TFileList' }
sub new_TFileList { __PACKAGE__->from( @_ ) }

extends TSortedListBox;

# declare global variables
our $tooManyFiles = "Too many files.";

sub BUILDARGS {    # \%args (%args)
  state $sig = signature(
    method => 1,
    named  => [
      bounds     => Object,
      vScrollBar => Maybe[Object], { alias => 'aScrollBar' },
    ],
    caller_level => +1,
  );
  my ( $class, $args ) = $sig->( @_ );
  local $Carp::CarpLevel = $Carp::CarpLevel + 1;
  return $class->SUPER::BUILDARGS(
    bounds     => $args->{bounds},
    numCols    => 2,
    vScrollBar => $args->{vScrollBar},
  );
}

sub from {    # $obj ($bounds, $aVScrollBar|undef)
  state $sig = signature(
    method => 1,
    pos    => [Object, Maybe[Object]],
  );
  my ( $class, @args ) = $sig->( @_ );
  return $class->new( bounds => $args[0], vScrollBar => $args[2] );
}

sub DEMOLISH {    # void ($in_global_destruction)
  my ( $self, $in_global_destruction ) = @_;
  assert ( @_ == 2 );
  assert ( is_Object $self );
  alias: for my $list ( $self->{items} ) {
  $self->destroy( $list );
  return;
  } #/ alias: 
}

sub focusItem {    # void ($item)
  state $sig = signature(
    method => Object,
    pos    => [PositiveOrZeroInt],
  );
  my ( $self, $item ) = $sig->( @_ );
  $self->SUPER::focusItem( $item );
  message( $self->{owner}, evBroadcast, cmFileFocused, 
    $self->list()->at( $item ) );
  return;
}

sub selectItem {    # void ($item)
  state $sig = signature(
    method => Object,
    pos    => [PositiveOrZeroInt],
  );
  my ( $self, $item ) = $sig->( @_ );
  message( $self->{owner}, evBroadcast, cmFileDoubleClicked, 
    $self->list()->at( $item ) );
  return;
}

sub getText {    # void (\$dest, $item, $maxChars)
  state $sig = signature(
    method => Object,
    pos    => [ScalarRef, Int, Int],
  );
  my ( $self, $dest, $item, $maxChars ) = $sig->( @_ );
  my $f = $self->list()->at( $item );
  assert ( is_Object $f );
  $$dest = substr( $f->name(), 0, $maxChars );
  $$dest .= "\\"
    if $f->attr() & FA_DIREC;
  return;
}

sub newList {    # void ($aList)
  goto &TUI::StdDlg::SortedListBox::newList;
}

@DirSearchRec::ISA = ( 'TSearchRec' );

sub DirSearchRec::readFf_blk {    # void ($f)
  my ( $self, $f ) = @_;
  assert ( @_ == 2 );
  assert ( is_Object $self );
  assert ( is_Object $f );
  $self->attr( $f->ff_attrib );
  $self->time( ( $f->ff_fdate() << 16 ) | $f->ff_ftime );
  $self->size( $f->ff_fsize );
  $self->name( $f->ff_name );
}

sub readDirectory {    # void (|$dir, $wildCard)
  state $sig = signature(
    method => Object,
    pos => [
      Str, 
      Str, { default => '' },
    ],
  );
  my ( $self, @args ) = $sig->( @_ );
  my $aWildCard = join '' => @args;

  my $s = ffblk->new();
  my $path = $aWildCard;
  fexpand( $path );
  my ( $drive, $dir, $file, $ext );
  fnsplit( $path, $drive, $dir, $file, $ext );

  my $fileList = TFileCollection->new( limit => 5, delta => 5 );

  my $res = findfirst( $aWildCard, $s, FA_RDONLY | FA_ARCH );
  for ( ; $res == 0; $res = findnext( $s ) ) {
    next if $s->ff_attrib() & FA_DIREC;
    last if $fileList->getCount() >= maxCollectionSize;

    my $p = DirSearchRec->new();
    $p->readFf_blk( $s );
    $fileList->insert( $p );
  }

  fnmerge( $path, $drive, $dir, "*", ".*" );

  $res = findfirst( $path, $s, FA_DIREC );
  for ( ; $res == 0; $res = findnext( $s ) ) {
    next unless $s->ff_attrib() & FA_DIREC;
    next if substr( $s->ff_name, 0, 1 ) eq '.';
    last if $fileList->getCount() >= maxCollectionSize;

    my $p = DirSearchRec->new();
    $p->readFf_blk( $s );
    $fileList->insert( $p );
  }

  if ( length $dir > 1 ) {
    my $p = DirSearchRec->new();
    if ( findfirst( $path, $s, FA_DIREC ) == 0
      && findnext( $s ) == 0
      && $s->ff_name eq '..'
    ) {
      $p->readFf_blk( $s );
    }
    else {
      $p->name( '..' );
      $p->size( 0 );
      $p->time( 0x210000 );
      $p->attr( FA_DIREC );
    }
    $fileList->insert( $p );
  } #/ if ( length( $dir ) > ...)

  if ( $fileList->getCount() >= maxCollectionSize ) {
    messageBox( $tooManyFiles, mfOKButton | mfWarning );
  }
  $self->newList( $fileList );
  if ( $self->list()->getCount() > 0 ) {
    message( $self->{owner}, evBroadcast, cmFileFocused, 
      $self->list()->at( 0 ) );
  }
  else {
    state $noFile = DirSearchRec->new();
    message( $self->{owner}, evBroadcast, cmFileFocused, $noFile );
  }
  return;
}

sub dataSize {    # $size ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  $sig->( @_ );
  return 0;
}

sub getData {    # void (\@rec)
  state $sig = signature(
    method => Object,
    pos    => [ArrayLike],
  );
  $sig->( @_ );
  return;
}

sub setData {    # void (\@rec)
  state $sig = signature(
    method => Object,
    pos    => [ArrayLike],
  );
  $sig->( @_ );
  return;
}

sub list {    # $fileCollection ()
  goto &TUI::StdDlg::SortedListBox::list;
}

sub getKey {    # $key ($s)
  state $sig = signature(
    method => Object,
    pos    => [Str],
  );
  my ( $self, $s ) = $sig->( @_ );
  state $sR = TSearchRec->new();
  if ( ( $self->{shiftState} & kbShift ) || $s eq '.' ) {
    $sR->attr( FA_DIREC );
  }
  else {
    $sR->attr( 0 );
  }
  $sR->name( uc $s );
  return $sR;
}

1

__END__

=pod

=head1 NAME

TUI::StdDlg::FileList - list box view for file and directory entries

=head1 HIERARCHY

  TObject
    TView
      TGroup
        TListBox
          TSortedListBox
            TFileList

=head1 SYNOPSIS

  use TUI::StdDlg;

  my $list = new_TFileList(
    $bounds,
    $scrollBar
  );

=head1 DESCRIPTION

C<TFileList> implements a specialized list box used by standard
TUI::Vision file dialogs to display directory contents.

The list presents files and directories obtained from a C<TFileCollection>
instance and supports keyboard and mouse navigation, selection, and activation
of entries.

This class extends C<TListBox> with file-specific behavior and integrates
tightly with other standard dialog components.

C<TFileList> is typically managed by C<TFileDialog> and not used
directly by application code.

The list view relies on C<TFileCollection> for sorting and filtering file
entries and reflects changes immediately when a new collection is assigned.

This class extends the generic list box behavior with file-specific logic such
as directory scanning, filename display formatting, and hotkey extraction.

=head1 VARIABLES

The following global variable defines the error message used by C<TFileList>.

=head2 $tooManyFiles

Message text displayed when the number of files exceeds the supported limit.

=head1 CONSTRUCTOR

=head2 new

  my $list = TFileList->new(
    bounds     => $bounds,
    vScrollBar => $scrollBar | undef
  );

Creates a new file list view.

=over

=item bounds

Bounding rectangle defining the position and size of the list box (I<TRect>).

=item vScrollBar

Optional vertical scroll bar associated with the list box (I<TScrollBar>).

=back

=head2 new_TFileList

  my $list = new_TFileList($bounds, $scrollBar | undef);

Factory-style constructor using positional arguments.

=head1 METHODS

=head2 dataSize

  my $size = $list->dataSize();

Returns the number of scalar values transferred via C<getData> and C<setData>.

For file lists, this value is always C<1>.

=head2 focusItem

  $list->focusItem($index);

Moves the focus to the specified item index.

=head2 getData

  $list->getData(\@record);

Stores the current selection state into the supplied record.

=head2 getKey

  my $key = $list->getKey($string);

Extracts and returns the hotkey associated with a file list entry.

=head2 getText

  $list->getText(\$dest, $item, $maxChars);

Retrieves the display text for the specified list item.

=head2 list

  my $collection = $list->list();

Returns the C<TFileCollection> currently backing the list.

=head2 newList

  $list->newList($collection);

Assigns a new file collection to the list and refreshes its contents.

=head2 readDirectory

  $list->readDirectory($dir | undef, $wildCard | undef);

Reads the contents of the specified directory and populates the file list.

If no directory is specified, the current working directory is used.

=head2 selectItem

  $list->selectItem($index);

Selects the specified item index.

=head2 setData

  $list->setData(\@record);

Restores the selection state from external input.

=head1 SEE ALSO

L<TUI::StdDlg::FileDialog>,
L<TUI::StdDlg::FileCollection>,
L<TUI::Views::ListBox>,
L<TUI::Views::ScrollBar>

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

