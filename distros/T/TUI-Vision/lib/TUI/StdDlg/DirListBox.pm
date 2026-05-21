package TUI::StdDlg::DirListBox;
# ABSTRACT: TListBox subclass providing directory listing for TChDirDialog

use 5.010;
use strict;
use warnings;
use utf8;

our $VERSION = '2.000001';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';

our @EXPORT = qw(
  TDirListBox
  new_TDirListBox
);

use TUI::toolkit;
use TUI::toolkit::Types qw(
  Maybe
  :types
);

use TUI::Const qw( EOS );
use TUI::Drivers::Const qw( evBroadcast );
use TUI::Dialogs::ListBox;
use TUI::StdDlg::Const qw(
  cmChangeDir
  FA_DIREC
);
use TUI::StdDlg::Dos;
use TUI::StdDlg::Dir qw(
  findfirst
  findnext
  getdisk
);
use TUI::StdDlg::DirEntry;
use TUI::StdDlg::DirCollection;
use TUI::StdDlg::Util qw( driveValid );
use TUI::Views::Const qw( sfFocused );
use TUI::Views::Util qw( message );

sub TDirListBox() { __PACKAGE__ }
sub name() { 'TDirListBox' }
sub new_TDirListBox { __PACKAGE__->from( @_ ) }

extends TListBox;

# declare global variables
our $pathDir   = "\xC0\xC4\xC2";    # cp437: "└─┬";
our $firstDir  = "\xC0\xC2\xC4";    # cp437:   "└┬─";
our $middleDir = " \xC3\xC4";       # cp437:   " ├─";
our $lastDir   = " \xC0\xC4";       # cp437:   " └─";
our $drives    = "Drives";
our $graphics  = "\xC0\xC3\xC4";    # cp437: "└├─";

# private attributes
has dir => ( is => 'bare', default => EOS );
has cur => ( is => 'bare', default => 0 );

# private methods
my (
  $showDrives,
  $showDirs,
);

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
    numCols    => 1,
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

sub getText {    # void (\$text, $item, $maxChars)
  state $sig = signature(
    method => Object,
    pos    => [ScalarRef, Int, Int],
  );
  my ( $self, $text, $item, $maxChars ) = $sig->( @_ );
  $$text = $self->list()->at( $item )->text();
  substr( $$text, $maxChars ) = EOS if length $$text > $maxChars;
  return;
}

sub isSelected {    # $bool ($item)
  state $sig = signature(
    method => Object,
    pos    => [PositiveOrZeroInt],
  );
  my ( $self, $item ) = $sig->( @_ );
  return $item == $self->{cur};
}

sub selectItem {    # void ($item)
  state $sig = signature(
    method => Object,
    pos    => [PositiveOrZeroInt],
  );
  my ( $self, $item ) = $sig->( @_ );
  message( $self->{owner}, evBroadcast, cmChangeDir, 
    $self->list()->at( $item ) );
  return;
}

sub newDirectory {    # void ($str)
  state $sig = signature(
    method => Object,
    pos    => [Str],
  );
  my ( $self, $str ) = $sig->( @_ );
  $self->{dir} = $str;
  my $dirs = TDirCollection->new( limit => 5, delta => 5 );
  $dirs->insert( TDirEntry->new(
    displayText => $drives, directory => $drives )
  );
  if ( $self->{dir} eq $drives ) {
    $self->$showDrives( $dirs );
  } 
  else {
    $self->$showDirs( $dirs );
  }
  $self->newList( $dirs );
  $self->focusItem( $self->{cur} );
  return;
}

sub setState {    # void ($aState, $enable)
  state $sig = signature(
    method => Object,
    pos    => [PositiveOrZeroInt, Bool],
  );
  my ( $self, $aState, $enable ) = $sig->( @_ );

  $self->SUPER::setState( $aState, $enable );
  if ( $aState & sfFocused ) {
    message( $self->{owner}, evBroadcast, cmChangeDir, 
      $self->list()->at( $self->{cur} ) );
  }
  return;
}

sub list {    # $dirCollection ()
  goto &TUI::Dialogs::ListBox::list;
}

$showDrives = sub {    # void ($dirs)
  my ( $self, $dirs ) = @_;
  assert ( @_ == 2 );
  assert ( is_Object $self );
  assert ( is_Object $dirs );

  my $isFirst = true;
  my $oldc    = "0:\\";
  for my $c ( 'A' .. 'Z' ) {
    if ( $c lt 'C' || driveValid( $c ) ) {
      if ( substr( $oldc, 0, 1 ) ne '0' ) {
        my $s;
        if ( $isFirst ) {
          $s = $firstDir . substr( $oldc, 0, 1 );
          $isFirst = false;
        }
        else {
          $s = $middleDir . substr( $oldc, 0, 1 );
        }
        $dirs->insert(
          TDirEntry->new( displayText => $s, directory => $oldc )
        );
      }
      if ( ord( $c ) == getdisk() + ord( 'A' ) ) {
        $self->{cur} = $dirs->getCount();
      }
      substr( $oldc, 0, 1 ) = $c;
    } #/ if ( $c lt 'C' || driveValid...)
  } #/ for my $c ( 'A' .. 'Z' )

  if ( substr( $oldc, 0, 1 ) ne '0' ) {
    my $s = $lastDir . substr( $oldc, 0, 1 );
    $dirs->insert( TDirEntry->new( displayText => $s, directory => $oldc ) );
  }
  return;
};

$showDirs = sub {    # void ($dirs)
  my ( $self, $dirs ) = @_;
  assert ( @_ == 2 );
  assert ( is_Object $self );
  assert ( is_Object $dirs );

  state $indentSize = 2;
  my $indent = $indentSize;

  my $org = $pathDir;
  my $curDir = $self->{dir};

  # Show root directory.
  my $pos = index( $curDir, '\\' );
  return if $pos < 0;
  my $root = substr( $curDir, 0, $pos + 1 );
  $dirs->insert( TDirEntry->new(
    displayText => $org . $root,
    directory   => $root,
  ));
  $curDir = substr( $curDir, $pos + 1 );

  # Show directories up to the current one.
  my $partial = $root;
  while ( ( my $pos = index( $curDir, '\\' ) ) != -1 ) {
    my $name = substr( $curDir, 0, $pos );
    my $entryDir = $partial . $name;
    $dirs->insert( TDirEntry->new(
      displayText => ( ' ' x $indent ) . $org . $name,
      directory   => $entryDir,
    ));
    $partial .= $name . '\\';
    $curDir = substr( $curDir, $pos + 1 );
    $indent += $indentSize;
  }

  $self->{cur} = $dirs->getCount() - 1;

  # Show subdirectories.
  my $basePath = $self->{dir};
  if ( substr( $basePath, -1, 1 ) ne '\\' ) {
    $basePath =~ s/\\[^\\]*$//;
    $basePath .= '\\';
  }
  my $path = $basePath . '*.*';

  my $isFirst = true;
  my $ff      = ffblk->new();
  my $res     = findfirst( $path, $ff, FA_DIREC );
  while ( $res == 0 ) {
    if ( ( $ff->ff_attrib() & FA_DIREC )
      && substr( $ff->ff_name, 0, 1 ) ne '.' )
    {
      if ( $isFirst ) {
        $org     = $firstDir;
        $isFirst = false;
      }
      else {
        $org = $middleDir;
      }
      my $name = $ff->ff_name;
      $path = $basePath . $name;
      $dirs->insert( TDirEntry->new(
        displayText => ( ' ' x $indent ) . $org . $name,
        directory   => $path,
      ));
    }
    $res = findnext( $ff );
  } #/ while ( $res == 0 )

  alias: for my $p ( $dirs->at( $dirs->getCount() - 1 )->{displayText} ) {
  my @graphics = split //, $graphics;
  my $i = index( $p, $graphics[0] );
  if ( $i < 0 ) {
    $i = index( $p, $graphics[1] );
    if ( $i >= 0 ) {
      substr( $p, $i, 1 ) = $graphics[0];
    }
  }
  else {
    substr( $p, $i + 1, 1 ) = $graphics[2];
    substr( $p, $i + 2, 1 ) = $graphics[2];
  }
  return;
  } #/ alias:
};

1

__END__

=pod

=head1 NAME

TUI::StdDlg::DirListBox - list box view for directory entries

=head1 HIERARCHY

  TObject
    TView
      TGroup
        TListBox
          TDirListBox

=head1 SYNOPSIS

  use TUI::StdDlg;

  my $list = new_TDirListBox(
    $bounds,
    $scrollBar
  );

=head1 DESCRIPTION

C<TDirListBox> implements a specialized list box used by standard TUI::Vision
dialogs to display and navigate directory entries.

The list box presents directory items backed by a C<TDirCollection> and
operates on directory entry records of type C<TDirEntry>. It supports keyboard
and mouse navigation, selection, and directory changes.

This view is primarily used by C<TChDirDialog>.

=head1 VARIABLES

The following global variables define the visual layout and labels used
by C<TDirListBox>.

=head2 $pathDir

Defines the character sequence used to display the path directory prefix.
The default value uses CP437 line-drawing characters.

=head2 $firstDir

Defines the characters used to display the first directory entry
in a directory tree (CP437).

=head2 $middleDir

Defines the characters used for intermediate directory entries
in the directory tree (CP437).

=head2 $lastDir

Defines the characters used for the last directory entry
in the directory tree (CP437).

=head2 $drives

Label text used for the drives list.

=head2 $graphics

Defines additional line-drawing characters used for directory tree
rendering (CP437).

=head1 CONSTRUCTOR

=head2 new

  my $list = TDirListBox->new(
    bounds     => $bounds,
    vScrollBar => $scrollBar | undef
  );

Creates a new directory list box.

=over

=item bounds

Bounding rectangle defining the position and size of the list box (I<TRect>).

=item vScrollBar

Optional vertical scroll bar associated with the list box (I<TScrollBar>).

=back

=head2 new_TDirListBox

  my $list = new_TDirListBox($bounds, $scrollBar | undef);

Factory-style constructor using positional arguments.

=head1 METHODS

The following methods operate on directory entry objects (C<TDirEntry>).

=head2 getText

  $list->getText(\$text, $item, $maxChars);

Retrieves the display text for the specified directory entry.

=head2 isSelected

  my $bool = $list->isSelected($item);

Returns true if the specified directory entry is currently selected.

=head2 list

  my $collection = $list->list();

Returns the directory collection backing this list box
(C<TDirCollection>).

=head2 newDirectory

  $list->newDirectory($path);

Updates the list box to display the contents of the specified directory.

=head2 selectItem

  $list->selectItem($item);

Selects the specified directory entry.

=head2 setState

  $list->setState($state, $enable);

Updates the list box state and refreshes the display if necessary.

=head1 SEE ALSO

L<TUI::StdDlg::ChDirDialog>,
L<TUI::StdDlg::DirCollection>,
L<TUI::StdDlg::DirEntry>,
L<TUI::Views::ListBox>

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

