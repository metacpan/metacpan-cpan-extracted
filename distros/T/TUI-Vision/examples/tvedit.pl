#---------------------------------------------------------#
#                                                         #
#   Turbo Vision TVEDIT Source File                       #
#                                                         #
#---------------------------------------------------------#
#
#      Turbo Vision - Version 2.0 (Perl Edition)
#
#      Copyright (c) 1994 by Borland International
#      All Rights Reserved.
#
#
package TEditorApp;

use TUI::Objects;
use TUI::Menus;
use TUI::Drivers;
use TUI::App;
use TUI::Views;
use TUI::Dialogs;
use TUI::MsgBox;
use TUI::StdDlg;
use TUI::Editors;

use TUI::toolkit;

sub ::new_TEditorApp { __PACKAGE__->new( argc => shift, argv => shift ) }

extends TApplication;

use constant cmChangeDrct => 102;

sub BUILDARGS {
  my ( $class, %args ) = ( shift, @_ );
  return {
    %{ $class->SUPER::BUILDARGS() },
    argc   => $args{argc} // 0,
    argv   => $args{argv} // [],
    bounds => new_TRect( 0, 0, 80, 25 ),
  };
}

sub BUILD {
  my ( $self, $args ) = @_;

  my $ts = new_TCommandSet();
  $ts->enableCmd( $_ ) for (
    cmSave, 
    cmSaveAs, 
    cmCut, 
    cmCopy, 
    cmPaste, 
    cmClear, 
    cmUndo,
    cmFind, 
    cmReplace, 
    cmSearchAgain,
  );
  $self->disableCommands( $ts );

  $TUI::Editors::Editor::editorDialog = \&doEditDialog;

  my $argv = $args->{argv};
  my $argc = $args->{argc};
  while (--$argc > 0) {                           # Open files specified
    $self->openEditor( $argv->[$argc], true );    # on command line.
  }
  $deskTop->cascade( $deskTop->getExtent() );

  # Create a hidden clipboard editor window for internal use
  my $clipWindow = new_TEditWindow( $deskTop->getExtent(), undef, wnNoNumber );
  $clipWindow->hide();
  $deskTop->insert( $clipWindow );
  $TUI::Editors::Editor::clipboard = $clipWindow->{editor};

  return;
}

sub openEditor {
  my ( $self, $fileName, $visible ) = @_;
  my $r = $deskTop->getExtent();
  my $p = $self->validView( new_TEditWindow( $r, $fileName, wnNoNumber ) );
  if ( $p ) {
    $p->hide() if !$visible;
    $deskTop->insert( $p );
  }
  return $p;
}

sub fileOpen {
  my ( $self ) = @_;
  my @fileName = ('*.*');
  if ( $self->executeDialog(
    new_TFileDialog( '*.*', 'Open file', '~N~ame', fdOpenButton, 100 ),
    \@fileName,
  ) != cmCancel ) {
    $self->openEditor( $fileName[0], true );
  }
  return;
}

sub fileNew {
  my ( $self ) = @_;
  $self->openEditor( undef, true );
  return;
}

sub changeDir {
  my ( $self ) = @_;
  $self->executeDialog( new_TChDirDialog( cdNormal, 0 ), undef );
  return;
}

sub handleEvent {
  my ( $self, $event ) = @_;
  $self->SUPER::handleEvent( $event );

  if ( $event->{what} == evCommand ) {
    SWITCH: for ( $event->{message}{command} ) {

      cmOpen == $_ and do {
        $self->fileOpen();
        last;
      };

      cmNew == $_ and do {
        $self->fileNew();
        last;
      };

      cmChangeDrct == $_ and do {
        $self->changeDir();
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

sub createFindDialog {
  my $d = new_TDialog( new_TRect( 0, 0, 38, 12 ), "Find" );

  $d->{options} |= ofCentered;

  my $control = new_TInputLine( new_TRect( 3, 3, 32, 4 ), 80 );
  $d->insert( $control );
  $d->insert(
    new_TLabel( new_TRect( 2, 2, 15, 3 ), "~T~ext to find", $control ) );
  $d->insert(
    new_THistory( new_TRect( 32, 3, 35, 4 ), $control, 10 ) );

  $d->insert( new_TCheckBoxes( new_TRect( 3, 5, 35, 7 ),
    new_TSItem( "~C~ase sensitive",
    new_TSItem( "~W~hole words only", undef ))));

  $d->insert(
    new_TButton( new_TRect( 14, 9, 24, 11 ), "O~K~", cmOK, bfDefault ) );
  $d->insert(
    new_TButton( new_TRect( 26, 9, 36, 11 ), "Cancel", cmCancel, bfNormal ) );

  $d->selectNext( !!0 );
  return $d;
}

sub createReplaceDialog {
  my $d = new_TDialog( new_TRect( 0, 0, 40, 16 ), "Replace" );

  $d->{options} |= ofCentered;

  my $control = new_TInputLine( new_TRect( 3, 3, 34, 4 ), 80 );
  $d->insert( $control );
  $d->insert(
    new_TLabel( new_TRect( 2, 2, 15, 3 ), "~T~ext to find", $control ) );
  $d->insert( new_THistory( new_TRect( 34, 3, 37, 4 ), $control, 10 ) );

  $control = new_TInputLine( new_TRect( 3, 6, 34, 7 ), 80 );
  $d->insert( $control );
  $d->insert(
    new_TLabel( new_TRect( 2, 5, 12, 6 ), "~N~ew text", $control ) );
  $d->insert( new_THistory( new_TRect( 34, 6, 37, 7 ), $control, 11 ) );

  $d->insert( new_TCheckBoxes( new_TRect( 3, 8, 37, 12 ),
    new_TSItem( "~C~ase sensitive",
    new_TSItem( "~W~hole words only",
    new_TSItem( "~P~rompt on replace",
    new_TSItem( "~R~eplace all", undef ))))));

  $d->insert(
    new_TButton( new_TRect( 17, 13, 27, 15 ), "O~K~", cmOK, bfDefault ) );
  $d->insert( new_TButton( new_TRect( 28, 13, 38, 15 ),
    "Cancel", cmCancel, bfNormal ) );

  $d->selectNext( false );
  return $d;
}

sub initMenuBar {
  my ( $class, $r ) = @_;
  
  my $sub1 =
    new_TSubMenu( "~F~ile", kbAltF ) +
      new_TMenuItem( "~O~pen", cmOpen, kbF3, hcNoContext, "F3" ) +
      new_TMenuItem( "~N~ew", cmNew, kbCtrlN, hcNoContext, "Ctrl-N" ) +
      new_TMenuItem( "~S~ave", cmSave, kbF2, hcNoContext, "F2" ) +
      new_TMenuItem( "S~a~ve as...", cmSaveAs, kbNoKey ) +
      newLine() +
      new_TMenuItem( "~C~hange dir...", cmChangeDrct, kbNoKey ) +
      new_TMenuItem( "E~x~it", cmQuit, kbCtrlQ, hcNoContext, "Ctrl-Q" );

  my $sub2 =
    new_TSubMenu( "~E~dit", kbAltE ) +
      new_TMenuItem( "~U~ndo", cmUndo, kbCtrlU, hcNoContext, "Ctrl-U" ) +
      newLine() +
      new_TMenuItem( "Cu~t~", cmCut, kbShiftDel, hcNoContext, "Shift-Del" ) +
      new_TMenuItem( "~C~opy", cmCopy, kbCtrlIns, hcNoContext, "Ctrl-Ins" ) +
      new_TMenuItem( "~P~aste", cmPaste, kbShiftIns, hcNoContext,
        "Shift-Ins" ) +
      newLine() +
      new_TMenuItem( "~C~lear", cmClear, kbCtrlDel, hcNoContext, "Ctrl-Del" );

  my $sub3 =
    new_TSubMenu( "~S~earch", kbAltS ) +
      new_TMenuItem( "~F~ind...", cmFind, kbNoKey ) +
      new_TMenuItem( "~R~eplace...", cmReplace, kbNoKey ) +
      new_TMenuItem( "~S~earch again", cmSearchAgain, kbNoKey );

  my $sub4 =
    new_TSubMenu( "~W~indows", kbAltW ) +
      new_TMenuItem( "~S~ize/move", cmResize, kbCtrlF5, hcNoContext,
        "Ctrl-F5" ) +
      new_TMenuItem( "~Z~oom", cmZoom, kbF5, hcNoContext, "F5" ) +
      new_TMenuItem( "~N~ext", cmNext, kbF6, hcNoContext, "F6" ) +
      new_TMenuItem( "~P~revious", cmPrev, kbShiftF6, hcNoContext,
        "Shift-F6" ) +
      new_TMenuItem( "~C~lose", cmClose, kbCtrlW, hcNoContext, "Ctrl+W" );

  $r->{b}{y} = $r->{a}{y} + 1;
  return new_TMenuBar( $r, $sub1 + $sub2 + $sub3 + $sub4 );
}

sub initStatusLine {
  my ( $class, $r ) = @_;
  $r->{a}{y} = $r->{b}{y} - 1;
  return new_TStatusLine( $r,
    new_TStatusDef( 0, 0xFFFF ) +
      new_TStatusItem( '', kbAltX, cmQuit ) +
      new_TStatusItem( "~F2~ Save", kbF2, cmSave ) +
      new_TStatusItem( "~F3~ Open", kbF3, cmOpen ) +
      new_TStatusItem( "~Ctrl-W~ Close", kbAltF3, cmClose ) +
      new_TStatusItem( "~F5~ Zoom", kbF5, cmZoom ) +
      new_TStatusItem( "~F6~ Next", kbF6, cmNext ) +
      new_TStatusItem( "~F10~ Menu", kbF10, cmMenu ) +
      new_TStatusItem( '', kbShiftDel, cmCut ) +
      new_TStatusItem( '', kbCtrlIns, cmCopy ) +
      new_TStatusItem( '', kbShiftIns, cmPaste ) +
      new_TStatusItem( '', kbCtrlF5, cmResize )
  );
}

sub outOfMemory {
  messageBox( "Not enough memory for this operation.", mfError | mfOKButton );
  return;
}

sub doEditDialog {
  my ( $dialog, $arg ) = @_;
  SWITCH: for ( $dialog ) {

    edOutOfMemory == $_ and do {
      return messageBox( "Not enough memory for this operation",
        mfError | mfOKButton );
    };

    edReadError == $_ and do {
      return messageBox( "Error reading file $arg.", mfError | mfOKButton );
    };

    edWriteError == $_ and do {
      return messageBox( "Error writing file $arg.", mfError | mfOKButton );
    };

    edCreateError == $_ and do {
      return messageBox( "Error creating file $arg.", mfError | mfOKButton );
    };

    edSaveModify == $_ and do {
      return messageBox( "$arg has been modified. Save?",
        mfInformation | mfYesNoCancel );
    };

    edSaveUntitled == $_ and do {
      return messageBox( "Save untitled file?",
        mfInformation | mfYesNoCancel );
    };

    edSaveAs == $_ and do {
      my @fileName = ( $_[1] );
      my $res = $application->executeDialog(
        new_TFileDialog( '*.*', 'Save file as', '~N~ame', fdOKButton, 101 ),
        \@fileName,
      );
      $_[1] = shift @fileName if $res != cmCancel;
      return $res;
    };

    edFind == $_ and do {
      return $application->executeDialog( createFindDialog(), $arg );
    };

    edSearchFailed == $_ and do {
      return messageBox( "Search string not found.", mfError | mfOKButton );
    };

    edReplace == $_ and do {
      return $application->executeDialog( createReplaceDialog(), $arg );
    };

    edReplacePrompt == $_ and do {
      # Avoid placing the dialog on the same line as the cursor
      my $r = new_TRect( 0, 1, 40, 8 );
      $r->move( int( ( $deskTop->{size}{x} - $r->{b}{x} ) / 2 ), 0 );
      my $t = $deskTop->makeGlobal( $r->{b} );
      $t->{y}++;
      my $pt = $arg;
      if ( $pt->{y} <= $t->{y} ) {
        $r->move( 0, $deskTop->{size}{y} - $r->{b}{y} - 2 );
      }
      return messageBoxRect( $r, "Replace this occurence?",
        mfYesNoCancel | mfInformation );
    };

  }
  return cmCancel;
}

package main; 

sub main {
  my ( $argc, $argv ) = @_;
  my $editorApp = new_TEditorApp( $argc, $argv );
  $editorApp->run();
  $editorApp->shutDown();
  return 0;
}

exit main( @ARGV+1, [ $0, @ARGV ] );

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

tvedit.pl - Turbo Vision text editor demonstration

=head1 SYNOPSIS

  tvedit.pl [options] [file ...]

  Options:
    -?, --help    Show brief usage information
        --man     Show the complete manual

=head1 DESCRIPTION

C<tvedit.pl> is a Perl port of the I<Turbo Vision> 2.0 TVEDIT example
application.

It demonstrates how the I<Turbo Vision> editor classes can be combined
into a complete multiple-window text editor.  The application supports
creating, opening, editing, and saving text files, clipboard operations,
undo, search and replace, and management of multiple editor windows.

One or more files may be specified on the command line.  Each file is
opened in a separate editor window when the application starts.  If no
file is specified, the application starts with an empty desktop and a
new document can be created from the File menu.

=head1 USER INTERFACE

=head2 File menu

The File menu provides commands for creating a new document, opening an
existing file, saving the current document, saving under a different
name, changing the current directory, and exiting the application.

=head2 Edit menu

The Edit menu provides undo, cut, copy, paste, and clear operations.

A hidden editor window is used as the shared clipboard for editor
windows within the application.

=head2 Search menu

The Search menu provides find, replace, and search-again operations.

The Find dialog supports case-sensitive searches and matching whole
words.  The Replace dialog additionally supports prompting before each
replacement and replacing all occurrences.

=head2 Windows menu

The Windows menu provides commands for resizing, moving, zooming,
selecting, and closing editor windows.

=head1 KEYBOARD SHORTCUTS

=over 4

=item C<F2>

Save the current document.

=item C<F3>

Open a file.

=item C<Ctrl-N>

Create a new document.

=item C<Ctrl-Q>

Exit the application.

=item C<Ctrl-W>

Close the current editor window.

=item C<F5>

Zoom or restore the current editor window.

=item C<F6>

Select the next window.

=item C<Shift-F6>

Select the previous window.

=item C<F10>

Activate the menu bar.

=item C<Ctrl-U>

Undo the last editing operation.

=item C<Shift-Delete>

Cut the selected text.

=item C<Ctrl-Insert>

Copy the selected text.

=item C<Shift-Insert>

Paste text from the clipboard.

=item C<Ctrl-Delete>

Delete the selected text.

=item C<Ctrl-F5>

Resize or move the current window.

=back

=head1 DEMONSTRATED FEATURES

This example demonstrates:

=over 4

=item *

Creating a multiple-document editor application derived from
L<TApplication|TUI::App::Application>.

=item *

Opening editor windows for files specified on the command line.

=item *

Creating new documents and opening existing files through standard
file dialogs.

=item *

Using L<TEditWindow|TUI::Editors::EditWindow> for file-backed editor
windows.

=item *

Providing a shared clipboard through a hidden editor window.

=item *

Connecting editor commands to menu and status-line items.

=item *

Implementing find and replace dialogs with input histories and search
options.

=item *

Handling editor requests for file errors, save confirmation, search
failure, and replacement confirmation.

=item *

Cascading multiple editor windows on the desktop.

=item *

Reporting memory allocation failures through a message box.

=back

=head1 ORIGINAL SOURCE

This program is a Perl port of the TVEDIT demonstration supplied with
Borland I<Turbo Vision> 2.0 for C++.

The original application is divided into the following source files:

  TVEDIT.H
  TVEDIT1.CPP
  TVEDIT2.CPP
  TVEDIT3.CPP

The C++ example demonstrates the construction of a complete text editor
using L<TApplication|TUI::App::Application>,
L<TEditWindow|TUI::Editors::EditWindow>,
L<TEditor|TUI::Editors::Editor>, standard file
dialogs, menus, status lines, and application-specific dialog handling.

The Perl port preserves the structure and observable behavior of the
original example while expressing it through the L<TUI::Vision> API.

=head1 SEE ALSO

L<TUI::App>,
L<TUI::Dialogs>,
L<TUI::Editors>,
L<TUI::Menus>,
L<TUI::MsgBox>,
L<TUI::StdDlg>,
L<TUI::Views>

=head1 COPYRIGHT

The original TVEDIT example contains the following copyright notice:

  Turbo Vision - Version 2.0

  Copyright (c) 1994 by Borland International
  All Rights Reserved.

This Perl version is a port of the original example for L<TUI::Vision>.

See the L<TUI::Vision> distribution for copyright and licensing
information relating to the Perl implementation.

=cut
