#---------------------------------------------------------#
#                                                         #
#   Turbo Vision TVDIR source file                        #
#                                                         #
#---------------------------------------------------------#
#
#      Turbo Vision - Version 2.0 (Perl Edition)
#
#      Copyright (c) 1994 by Borland International
#      All Rights Reserved.
#
#
package TVDir;
use 5.010;

use TUI::Objects;
use TUI::Menus;
use TUI::Drivers;
use TUI::App;
use TUI::Views;
use TUI::Dialogs;
use TUI::MsgBox;

use TUI::toolkit;

sub ::new_TVDirApp { __PACKAGE__->new( drive => shift ) }

extends TApplication;

use constant {
  cmDirTree => 100,
  cmAbout   => 101,
};

has drive => ( is => 'bare' );

sub BUILDARGS {
  my ( $class, %args ) = ( shift, @_ );
  return {
    %{ $class->SUPER::BUILDARGS() },
    drive  => $args{drive} // '.',
    bounds => new_TRect( 0, 0, 80, 25 ),
  };
}

sub BUILD {
  my ( $self, $args ) = @_;
  $self->openDirWindow( $self->{drive} );
  return;
}

sub openDirWindow {
  my ( $self, $drive ) = @_;
  $self->insertWindow(
    TVDir::DirWindow->new(
      bounds => new_TRect( 1, 1, 76, 21 ),
      title  => $drive,
      number => wnNoNumber,
      drive  => $drive,
    )
  );
  return;
}

sub handleEvent {
  my ( $self, $event ) = @_;
  $self->SUPER::handleEvent( $event );

  if ( $event->{what} == evCommand ) {
    SWITCH: for ( $event->{message}{command} ) {

      cmAbout == $_ and do {
        $self->aboutBox();
        last;
      };

      cmDirTree == $_ and do {
        $self->openDirWindow( $self->{drive} );
        last;
      };

      DEFAULT: {
        return;
      }
    } #/ SWITCH: for ( $event->{message}...)
    $self->clearEvent( $event );
  } #/ if ( $event->{what} ==...)
  return;
} #/ sub handleEvent

sub initStatusLine {
  my ( $self, $r ) = @_;
  $r->{a}{y} = $r->{b}{y} - 1;
  return new_TStatusLine( $r,
    new_TStatusDef( 0, 0xFFFF ) +
      new_TStatusItem( "~Alt-X~ Exit", kbAltX, cmQuit ) +
      new_TStatusItem( '', kbF10, cmMenu ),
  );
}

sub initMenuBar {
  my ( $self, $r ) = @_;
  $r->{b}{y} = $r->{a}{y} + 1;
  my $sub1 = new_TSubMenu( "~\360~", kbAltSpace ) +
    new_TMenuItem( "~A~bout...", cmAbout, kbAltA );
  my $sub2 = new_TSubMenu( "~F~ile", kbAltF ) +
    new_TMenuItem( "~N~ew Window...", cmDirTree, kbAltN ) +
    newLine() +
    new_TMenuItem( "E~x~it", cmQuit, kbAltX, hcNoContext, "Alt-X" );
  return new_TMenuBar( $r, $sub1 + $sub2 );
}

sub aboutBox {
  my ( $self ) = @_;
  my $d = new_TDialog( new_TRect( 0, 0, 39, 13 ), "About" );
  $d->{options} |= ofCentered;

  $d->insert( new_TStaticText( new_TRect( 9, 2, 30, 9 ),
    "\003Outline Viewer Demo\n\n" .
    "\003Perl Port Version\n\n" .
    "\003Copyright (c) 1994\n\n" .
    "\003Borland International" ) );
  $d->insert( new_TButton( new_TRect( 14, 10, 26, 12 ), " OK", cmOK,
    bfDefault ) );

  $self->executeDialog( $d );
  return;
}

#
# Message window shown while the directory tree is scanned.
#

package TVDir::QuickMessage;
use 5.010;

use TUI::Objects;
use TUI::Views;
use TUI::Dialogs;

use TUI::toolkit;

extends TWindow;

has drive => ( is => 'bare' );
has dir   => ( is => 'bare' );

sub BUILDARGS {
  my ( $class, %args ) = ( shift, @_ );
  my $base = $class->SUPER::BUILDARGS(
    bounds => new_TRect( 15, 8, 65, 19 ),
    title  => "Please Wait...",
    number => wnNoNumber,
  );
  return { %$base, drive => $args{drive} };
}

sub BUILD {
  my ( $self, $args ) = @_;
  $self->{flags}   = 0;
  $self->{options} |= ofCentered;
  $self->{palette} = wpGrayWindow;

  $self->insert( new_TStaticText( new_TRect( 2, 2, 48, 3 ),
    "Scanning Drive '$self->{drive}'\n" ) );
  $self->{dir} = new_TParamText( new_TRect( 2, 3, 48, 9 ) );
  $self->insert( $self->{dir} );
  return;
}

sub setCurrentDir {
  my ( $self, $dir ) = @_;
  $self->{dir}->setText( '%s', $dir );
  return;
}

#
# Outline that reports focus changes to its owner window.
#

package TVDir::DirOutline;
use 5.010;

use TUI::Objects;
use TUI::Drivers;
use TUI::Views;
use TUI::Outline;

use TUI::toolkit;

use constant cmNewDirFocused => 102;

extends TOutline;

sub focused {
  my ( $self, $i ) = @_;
  $self->SUPER::focused( $i );
  message( $self->{owner}, evCommand, cmNewDirFocused, 0 );
  return;
}

sub getParent {
  my ( $self, $child ) = @_;
  return $self->firstThat( sub {
    my ( $viewer, $cur ) = @_;
    for ( my $c = $cur->childList; $c; $c = $c->next ) {
      return true if $c == $child;
    }
    return false;
  } );
}

sub getCurrentPath {
  my ( $self ) = @_;
  my $root    = $self->getRoot();
  my $current = $self->getNode( $self->foc );
  my $sep     = '\\';
  my $temp    = '';

  while ( $current && $current != $root ) {
    $temp    = $current->text . $sep . $temp;
    $current = $self->getParent( $current );
  }

  my $path = $root->text;
  $path .= $sep unless $path =~ /[\\\/]\z/;
  return $path . $temp;
}

#
# Panel that lists the files of the directory selected in the outline.
#

package TVDir::FilePane;
use 5.010;

use TUI::Objects;
use TUI::Views;
use TUI::Dialogs;
use TUI::StdDlg;

use TUI::toolkit;

extends TScroller;

has files     => ( is => 'bare', default => sub { [] } );
has fileCount => ( is => 'bare', default => 0 );

sub newDir {
  my ( $self, $dir ) = @_;
  $dir =~ s/[\\\/]\z//;

  my @files;
  my $rec = find_t->new;
  my $ok  = _dos_findfirst( "$dir\\*.*",
    FA_ARCH | FA_RDONLY | FA_HIDDEN | FA_SYSTEM | FA_DIREC, $rec );
  while ( $ok == 0 ) {
    push @files, $self->formatFileRow( $rec ) unless $rec->name =~ /^\./;
    $ok = _dos_findnext( $rec );
  }

  $self->{files}     = \@files;
  $self->{fileCount} = scalar @files;
  if ( !$self->{fileCount} ) {
    $self->setLimit( 1, 1 );
  }
  else {
    $self->setLimit( length( $files[0] ) + 2, $self->{fileCount} );
  }
  $self->drawView();
  return;
}

sub formatFileRow {
  my ( $self, $rec ) = @_;
  my $attr = $rec->attrib;
  my $d    = $rec->wr_date;
  my $t    = $rec->wr_time;
  return sprintf( "%-18s  %8d %2d-%02d-%02d  %2d:%02d  %s",
    substr( $rec->name, 0, 18 ),
    $rec->size,
    ( $d & 0x01E0 ) >> 5, $d & 0x1F, ( ( $d >> 9 ) + 1980 ) % 100,
    ( $t & 0xF800 ) >> 11, ( $t & 0x07E0 ) >> 5,
    join( '',
      ( $attr & FA_ARCH   ) ? 'a' : "\xFA",
      ( $attr & FA_RDONLY ) ? 'r' : "\xFA",
      ( $attr & FA_SYSTEM ) ? 's' : "\xFA",
      ( $attr & FA_HIDDEN ) ? 'h' : "\xFA",
    ),
  );
}

sub draw {
  my ( $self ) = @_;
  my $color = $self->getColor( 0x0101 );
  my $files = $self->{files};
  my $count = $self->{fileCount};
  my $size  = $self->{size};
  my $delta = $self->{delta};

  for my $i ( 0 .. $size->{y} - 1 ) {
    my $dBuf = TDrawBuffer->new();
    $dBuf->moveChar( 0, ' ', $color, $size->{x} );
    my $n = $i + $delta->{y};
    if ( !$count ) {
      $dBuf->moveStr( 2, '<no files>', $color ) if $i == 0;
    }
    elsif ( $n < $count ) {
      $dBuf->moveStr( 2, substr( $files->[$n], $delta->{x} ), $color );
    }
    $self->writeLine( 0, $i, $size->{x}, 1, $dBuf );
  }
  return;
}

#
# Window holding the directory outline and the file pane.
#

package TVDir::DirWindow;
use 5.010;

use TUI::Objects;
use TUI::Views;
use TUI::Drivers;
use TUI::Dialogs;
use TUI::Outline;
use TUI::App;
use TUI::StdDlg;

use TUI::toolkit;

use constant cmNewDirFocused => 102;

extends TWindow;

has drive    => ( is => 'bare' );
has outline  => ( is => 'bare' );
has filePane => ( is => 'bare' );

sub BUILDARGS {
  my ( $class, %args ) = ( shift, @_ );
  my $base = $class->SUPER::BUILDARGS(
    bounds => $args{bounds},
    title  => $args{title},
    number => $args{number},
  );
  return { %$base, drive => $args{drive} };
}

sub BUILD {
  my ( $self, $args ) = @_;
  my $drive = $self->{drive};

  my $vsb = new_TScrollBar( new_TRect( 74, 1, 75, 15 ) );
  my $hsb = new_TScrollBar( new_TRect( 22, 15, 73, 16 ) );
  my $fp  = TVDir::FilePane->new(
    bounds     => new_TRect( 21, 1, 74, 15 ),
    hScrollBar => $hsb,
    vScrollBar => $vsb,
  );
  $fp->{options}  |= ofFramed;
  $fp->{growMode}  = gfGrowHiY | gfGrowHiX | gfFixed;
  $self->insert( $hsb );
  $self->insert( $vsb );
  $self->insert( $fp );

  $vsb = new_TScrollBar( new_TRect( 20, 1, 21, 19 ) );
  $hsb = new_TScrollBar( new_TRect( 2, 19, 19, 20 ) );

  my $qm = TVDir::QuickMessage->new( drive => $drive );
  $deskTop->insert( $qm );
  my $root = new_TNode( $drive, $self->getDirList( $drive, $qm ),
    undef, true );
  $deskTop->remove( $qm );

  my $ol = TVDir::DirOutline->new(
    bounds     => new_TRect( 1, 1, 20, 19 ),
    hScrollBar => $hsb,
    vScrollBar => $vsb,
    root       => $root,
  );
  $ol->{options}  |= ofFramed;
  $ol->{growMode}  = gfGrowHiY | gfFixed;
  $vsb->{growMode} = gfGrowHiY;
  $hsb->{growMode} = gfGrowHiY | gfGrowLoY;
  $self->insert( $hsb );
  $self->insert( $vsb );
  $self->insert( $ol );

  $fp->newDir( $ol->getCurrentPath() );
  $self->{outline}  = $ol;
  $self->{filePane} = $fp;
  return;
}

sub getDirList {
  my ( $self, $path, $qm ) = @_;
  my ( $head, $tail );
  my $rec = find_t->new;
  my $ok  = _dos_findfirst( "$path\\*.*", FA_DIREC, $rec );

  while ( $ok == 0 ) {
    my $name = $rec->name;
    if ( ( $rec->attrib & FA_DIREC ) && $name !~ /^\./ ) {
      my $sub = "$path\\$name";
      $qm->setCurrentDir( $sub );
      my $node = new_TNode( $name, $self->getDirList( $sub, $qm ),
        undef, false );
      if ( $tail ) { $tail->next( $node ) } else { $head = $node }
      $tail = $node;
    }
    $ok = _dos_findnext( $rec );
  }
  return $head;
}

sub handleEvent {
  my ( $self, $event ) = @_;
  if ( $event->{what} == evCommand
    && $event->{message}{command} == cmNewDirFocused
  ) {
    my $path = $self->{outline}->getCurrentPath();
    $self->{filePane}->newDir( $path );
    $self->title( $path );
    $self->clearEvent( $event );
    $self->frame->drawView();
  }
  $self->SUPER::handleEvent( $event );
  return;
}

sub sizeLimits {
  my ( $self, $min, $max ) = @_;
  $min->{x} = 40;
  $min->{y} = 10;
  $max->{x} = $self->owner->{size}{x};
  $max->{y} = $self->owner->{size}{y};
  return;
}

package main;

sub main {
  my ( $argc, $argv ) = @_;
  my $app = new_TVDirApp( $argc == 2 ? $argv->[1] : '.' );
  $app->run();
  $app = undef;
  return 0;
}

exit main( @ARGV + 1, [ $0, @ARGV ] );

#---------------------------------------------------------#

use Getopt::Long qw(GetOptions);
use Pod::Usage qw(pod2usage);

# Command line options handling for help and manual pages
BEGIN {
  my ( $help, $man );
  GetOptions(
    'help|?' => \$help,
    'man'    => \$man,
  ) or pod2usage( -verbose => 0, -exitval => 2 );
  pod2usage( -verbose => 0, -exitval => 0 ) if $help;
  pod2usage( -verbose => 2, -exitval => 0 ) if $man;
}

__END__

=pod

=head1 NAME

tvdir.pl - Turbo Vision directory outline demonstration

=head1 SYNOPSIS

  tvdir.pl [options] [drive]

  Options:
    -?, --help    Show brief usage information
        --man     Show the complete manual

=head1 DESCRIPTION

C<tvdir.pl> is a Perl port of the I<Turbo Vision> 2.0 TVDIR example
application.

It demonstrates the L<TOutline|TUI::Outline::Outline> control by displaying
a directory tree together with the files contained in the currently
selected directory.

The directory tree is shown in the left pane.  Moving the focus to a
different directory updates the file pane on the right and changes the
window title to the selected path.

An optional drive or directory may be specified on the command line.
If none is specified, the current directory is used.

=head1 DIRECTORY VIEW

The directory window consists of two coordinated views.

The left pane contains an outline representing the directory hierarchy.
Directories can be expanded, collapsed, and selected using the normal
L<TOutline|TUI::Outline::Outline> controls.

The right pane displays the files in the currently focused directory,
including file size, modification date and time, and DOS file
attributes.

Selecting another directory in the outline automatically refreshes the
file pane.

=head1 DIRECTORY SCANNING

The directory hierarchy is scanned when a directory window is created.

While the tree is being built, a temporary C<Please Wait...> window
shows the directory currently being scanned.

The resulting hierarchy is represented by L<TNode|TUI::Outline::Node> objects
and used as the root structure of the L<TOutline|TUI::Outline::Outline>
control.

=head1 FILE INFORMATION

The file pane displays one row for each file in the selected directory.

Each row contains:

=over 4

=item *

The file name.

=item *

The file size.

=item *

The modification date.

=item *

The modification time.

=item *

DOS archive, read-only, system, and hidden attributes.

=back

=head1 USER INTERFACE

=head2 File menu

C<New Window...> opens another directory window for the configured
drive or directory.

C<Exit> terminates the application.

=head2 System menu

C<About...> displays information about the TVDIR demonstration.

=head1 KEYBOARD SHORTCUTS

=over 4

=item C<Alt-N>

Open another directory window.

=item C<Alt-A>

Open the About dialog.

=item C<F10>

Activate the menu bar.

=item C<Alt-X>

Exit the application.

=back

=head1 DEMONSTRATED FEATURES

This example demonstrates:

=over 4

=item *

Displaying hierarchical data with
L<TOutline|TUI::Outline::Outline> and L<TNode|TUI::Outline::Node>.

=item *

Building a directory hierarchy recursively.

=item *

Using scroll bars with an outline and a custom scrolling view.

=item *

Synchronizing two views through command events.

=item *

Updating a file list when the focused outline node changes.

=item *

Drawing formatted file information with
L<TDrawBuffer|TUI::Views::DrawBuffer>.

=item *

Displaying a temporary progress window while constructing a view.

=item *

Creating and managing multiple directory windows.

=item *

Applying minimum and maximum size limits to a resizable window.

=back

=head1 ORIGINAL SOURCE

This program is a Perl port of C<TVDIR.CPP>, the TVDIR demonstration
supplied with Borland I<Turbo Vision> 2.0 for C++.

The original example demonstrates the
L<TOutline|TUI::Outline::Outline> control by presenting a directory tree
alongside a view of the files in the selected directory.

The Perl port preserves the structure and observable behavior of the
original example while adapting directory access, object construction,
and view management to the L<TUI::Vision> API.

=head1 SEE ALSO

L<TUI::App>,
L<TUI::Dialogs>,
L<TUI::Menus>,
L<TUI::Objects>,
L<TUI::Outline>,
L<TUI::StdDlg>,
L<TUI::Views>

=head1 COPYRIGHT

The original TVDIR.CPP example contains the following copyright notice:

  Turbo Vision - Version 2.0

  Copyright (c) 1994 by Borland International
  All Rights Reserved.

This Perl version is a port of the original example for L<TUI::Vision>.

See the L<TUI::Vision> distribution for copyright and licensing
information relating to the Perl implementation.

=cut
