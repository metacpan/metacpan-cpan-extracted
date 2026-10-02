#---------------------------------------------------------#
#                                                         #
#   Turbo Vision TVDEMO source file                       #
#                                                         #
#---------------------------------------------------------#
#
#      Turbo Vision - Version 2.0 (Perl Edition)
#
#      Copyright (c) 1994 by Borland International
#      All Rights Reserved.
#
#
package TVDemo;

use TUI::Objects;
use TUI::Menus;
use TUI::Drivers;
use TUI::App;
use TUI::Views;
use TUI::Dialogs;
use TUI::Gadgets;
use TUI::ColorSel;
use TUI::StdDlg;
use TUI::MsgBox;

use TUI::toolkit;

sub ::new_TVDemo { __PACKAGE__->new( argc => shift, argv => shift ) }

extends TApplication;

# Constants for TVDemo events
use constant {
  cmAboutCmd     => 100,
  cmPuzzleCmd    => 101,
  cmCalendarCmd  => 102,
  cmAsciiCmd     => 103,
  cmCalcCmd      => 104,
  cmOpenCmd      => 105,
  cmChDirCmd     => 106,
  cmDOS_Cmd      => 107,
  cmMouseCmd     => 108,
  cmColorCmd     => 109,
  cmSaveCmd      => 110,
  cmRestoreCmd   => 111,
  cmEventViewCmd => 112,
  cmVideoMode    => 2002,
};

# Constants for TVDemo help
use constant {
  hcAsciiTable      => 6,
  hcCalculator      => 4,
  hcCalendar        => 5,
  hcCancelBtn       => 35,
  hcFCChDirDBox     => 37,
  hcFChangeDir      => 15,
  hcFDosShell       => 16,
  hcFExit           => 17,
  hcFOFileOpenDBox  => 31,
  hcFOFiles         => 33,
  hcFOName          => 32,
  hcFOOpenBtn       => 34,
  hcFOpen           => 14,
  hcFile            => 13,
  hcNocontext       => 0,
  hcOCColorsDBox    => 39,
  hcOColors         => 28,
  hcOMMouseDBox     => 38,
  hcOMouse          => 27,
  hcORestoreDesktop => 30,
  hcOSaveDesktop    => 29,
  hcOpenBtn         => 36,
  hcOptions         => 26,
  hcPuzzle          => 3,
  hcSAbout          => 8,
  hcSAsciiTable     => 11,
  hcSCalculator     => 12,
  hcSCalendar       => 10,
  hcSPuzzle         => 9,
  hcSystem          => 7,
  hcViewer          => 2,
  hcWCascade        => 22,
  hcWClose          => 25,
  hcWNext           => 23,
  hcWPrevious       => 24,
  hcWSizeMove       => 19,
  hcWTile           => 21,
  hcWZoom           => 20,
  hcWindows         => 18,
};

has heap  => ( is => 'bare' );    # Heap view
has clock => ( is => 'bare' );    # Clock view

#
# Constructor for the application.  Command line parameters are interpreted
#   as file names and opened.  Wildcards are accepted and put up a dialog
#   box with the appropriate search path.
#

sub BUILDARGS {
  return {
    %{ shift->SUPER::BUILDARGS() },
    argc   => $_{argc} || 0,
    argv   => $_{argv} || [],
    bounds => new_TRect( 0, 0, 80, 25 ),
  };
}

sub BUILD {
  my $self = shift;

  my $r = $self->getExtent();    # Create the clock view.
  $r->{a}{x} = $r->{b}{x} - 9;
  $r->{b}{y} = $r->{a}{y} + 1;
  $self->{clock} = new_TClockView( $r );
  $self->{clock}{growMode} = gfGrowLoX | gfGrowHiX;
  $self->insert( $self->{clock} );

  $r = $self->getExtent();    # Create the heap view.
  $r->{a}{x} = $r->{b}{x} - 13;
  $r->{a}{y} = $r->{b}{y} - 1;
  $self->{heap} = new_THeapView( $r );
  $self->{heap}{growMode} = gfGrowAll;
  $self->insert( $self->{heap} );

  return;
}

#
# DemoApp::getEvent()
#  Event loop to check for context help request
#

my $helpInUse = 0;
sub getEvent {    # void ($event)
  my $self = shift;
  alias: for my $event ( shift ) {

  $self->SUPER::getEvent( $event );
  $self->printEvent( $event );

  SWITCH: for ( $event->{what} ) {
    case: evCommand == $_ and do {
    q[*
      if ( $event->{message}{command} == cmHelp && !$helpInUse ) {
        $helpInUse = 1;

        # Try to open help file
        my $helpStrm;
        if ( open $helpStrm, '<:raw', HELP_FILENAME ) {
          my $hFile = THelpFile->new( $helpStrm );
          my $w     = THelpWindow->new( $hFile, $self->getHelpCtx() );

          if ( $self->validView( $w ) ) {
            $self->execView( $w );
            $self->destroy( $w );
          }

          $self->clearEvent( $event );
        } #/ if ( open $helpStrm, '<:raw'...)
        else {
          $self->messageBox( "Could not open help file", mfError | mfOKButton );
        }

        $helpInUse = 0;
      } #/ if ( $event->{message}...)
      elsif ( $event->{message}{command} == cmVideoMode ) {
    q*] if 0;
      if ( $event->{message}{command} == cmVideoMode ) {
        $self->setScreenMode( $TUI::Drivers::Screen::screenMode ^ 1 );
      }
      last;
    };
    case: evMouseDown == $_ and do {
      if ( $event->{mouse}{buttons} == mbRightButton ) {
        $event->{what} = evNothing;
      }
      last;
    }
  } #/ SWITCH: for ( $event->{what} )
  return;
  } #/ alias: for my $event
} #/ sub getEvent

#
# Create statusline.
#

sub initStatusLine {
  my ( $class, $r ) = @_;
  $r->{a}{y} = $r->{b}{y} - 1;

  return new_TStatusLine( $r,
    new_TStatusDef( 0, 50 ) +
      new_TStatusItem( "~F1~ Help", kbF1,  cmHelp ) +
      new_TStatusItem( "~Alt-X~ Exit", kbAltX, cmQuit ) +
      new_TStatusItem( '', kbShiftDel, cmCut ) +
      new_TStatusItem( '', kbCtrlIns, cmCopy ) +
      new_TStatusItem( '', kbShiftIns, cmPaste ) +
      new_TStatusItem( '', kbAltF3, cmClose ) +
      new_TStatusItem( '', kbF10, cmMenu ) +
      new_TStatusItem( '', kbF5, cmZoom ) +
      new_TStatusItem( '', kbCtrlF5, cmResize ) +
    new_TStatusDef( 0, 50 ) +
      new_TStatusItem( "Howdy", kbF1,  cmHelp )
  );
}

#
# Tile function
#

sub tile {
  $deskTop->tile( $deskTop->getExtent() );
  return;
}

#
# DemoApp::handleEvent()
#  Event loop to distribute the work.
#

sub handleEvent {
  my ( $self, $event ) = @_;
  $self->SUPER::handleEvent( $event );

  if ( $event->{what} == evCommand ) {
    SWITCH: for ( $event->{message}{command} ) {

      cmAboutCmd == $_ and do {        #  About Dialog Box
        $self->aboutDlgBox();
        last;
      };

      cmEventViewCmd == $_ and do {    #  Open Event Viewer
        $self->eventViewer();
        last;
      };

      cmOpenCmd == $_ and do {         #  View a file
        $self->openFile("*.*");
        last;
      };

      cmChDirCmd == $_ and do {        #  Change directory
        $self->changeDir();
        last;
      };

      cmTile == $_ and do {            #  Tile current file windows
        $self->tile();
        last;
      };

      cmCascade == $_ and do {         #  Cascade current file windows
        $self->cascade();
        last;
      };

      cmMouseCmd == $_ and do {        #  Mouse control dialog box
        $self->mouse();
        last;
      };

      cmColorCmd == $_ and do {        #  Color control dialog box
        $self->colors();
        last;
      };

      DEFAULT: {                       #  Unknown command
        return;
      }
    } #/ SWITCH: for ( $event->{message}...)
    $self->clearEvent( $event );
  } #/ if ( $event->{what} ==...)
  return;
} #/ sub handleEvent

#
# About Box function()
#

sub aboutDlgBox {
  my ( $self ) = @_;
  my $aboutBox = new_TDialog( new_TRect( 0, 0, 39, 13 ), "About" );

  $aboutBox->insert(
    new_TStaticText(
      new_TRect( 9, 2, 30, 9 ),
        "\003Turbo Vision Demo\n\n" .        # These strings will be
        "\003C++ Perl Port Version\n\n" .    # concatenated by the compiler.
        "\003Copyright (c) 1994\n\n" .       # The \003 centers the line.
        "\003Borland International"
    )
  );

  $aboutBox->insert(
    new_TButton( new_TRect( 14, 10, 26, 12 ), " OK", cmOK, bfDefault ) );

  $aboutBox->{options} |= ofCentered;

  $self->executeDialog( $aboutBox );
  return;
} #/ sub aboutDlgBox

#
# Cascade function
#

sub cascade {
  $deskTop->cascade( $deskTop->getExtent() );
  return;
}

#
# Change Directory function
#

sub changeDir {
  my ( $self ) = @_;
  my $d = $self->validView( new_TChDirDialog( 0, hlChangeDir ) );
  if ( $d ) {
    $d->helpCtx( hcFCChDirDBox );
    $deskTop->execView( $d );
    $self->destroy( $d );
  }
  return;
}

#
# Color Control Dialog Box function
#

my $palette;
sub getPalette {
  $palette->[$TUI::App::Program::appPalette] //= $_[0]->SUPER::getPalette();
  return $palette->[$TUI::App::Program::appPalette];
}
sub setPalette {
  $palette->[$TUI::App::Program::appPalette] = $_[1]->clone();
  return;
}

sub colors {
  my ( $self ) = @_;
  my $group1 =
    new_TColorGroup( "Desktop" ) +
      new_TColorItem( "Color",             1 )+

    new_TColorGroup( "Menus") +
      new_TColorItem( "Normal",            2 )+
      new_TColorItem( "Disabled",          3 )+
      new_TColorItem( "Shortcut",          4 )+
      new_TColorItem( "Selected",          5 )+
      new_TColorItem( "Selected disabled", 6 )+
      new_TColorItem( "Shortcut selected", 7
    );

  my $group2 =
    new_TColorGroup( "Dialogs/Calc") +
      new_TColorItem( "Frame/background",  33 )+
      new_TColorItem( "Frame icons",       34 )+
      new_TColorItem( "Scroll bar page",   35 )+
      new_TColorItem( "Scroll bar icons",  36 )+
      new_TColorItem( "Static text",       37 )+

      new_TColorItem( "Label normal",      38 )+
      new_TColorItem( "Label selected",    39 )+
      new_TColorItem( "Label shortcut",    40
    );

  my $item_coll1 =
    new_TColorItem( "Button normal",     41 )+
    new_TColorItem( "Button default",    42 )+
    new_TColorItem( "Button selected",   43 )+
    new_TColorItem( "Button disabled",   44 )+
    new_TColorItem( "Button shortcut",   45 )+
    new_TColorItem( "Button shadow",     46 )+
    new_TColorItem( "Cluster normal",    47 )+
    new_TColorItem( "Cluster selected",  48 )+
    new_TColorItem( "Cluster shortcut",  49
  );

  my $item_coll2 =
    new_TColorItem( "Input normal",      50 )+
    new_TColorItem( "Input selected",    51 )+
    new_TColorItem( "Input arrow",       52 )+

    new_TColorItem( "History button",    53 )+
    new_TColorItem( "History sides",     54 )+
    new_TColorItem( "History bar page",  55 )+
    new_TColorItem( "History bar icons", 56 )+

    new_TColorItem( "List normal",       57 )+
    new_TColorItem( "List focused",      58 )+
    new_TColorItem( "List selected",     59 )+
    new_TColorItem( "List divider",      60 )+

    new_TColorItem( "Information pane",  61
  );

  $group2 = $group2 + $item_coll1 + $item_coll2;

  my $group3 =
    new_TColorGroup( "Viewer") +
      new_TColorItem( "Frame passive",      8 )+
      new_TColorItem( "Frame active",       9 )+
      new_TColorItem( "Frame icons",       10 )+
      new_TColorItem( "Scroll bar page",   11 )+
      new_TColorItem( "Scroll bar icons",  12 )+
      new_TColorItem( "Text",              13 )+
    new_TColorGroup( "Puzzle" )+
      new_TColorItem( "Frame passive",      8 )+
      new_TColorItem( "Frame active",       9 )+
      new_TColorItem( "Frame icons",       10 )+
      new_TColorItem( "Scroll bar page",   11 )+
      new_TColorItem( "Scroll bar icons",  12 )+
      new_TColorItem( "Normal text",       13 )+
      new_TColorItem( "Highlighted text",  14
    );


  my $group4 =
    new_TColorGroup( "Calendar") +
      new_TColorItem( "Frame passive",     16 )+
      new_TColorItem( "Frame active",      17 )+
      new_TColorItem( "Frame icons",       18 )+
      new_TColorItem( "Scroll bar page",   19 )+
      new_TColorItem( "Scroll bar icons",  20 )+
      new_TColorItem( "Normal text",       21 )+
      new_TColorItem( "Current day",       22 )+

    new_TColorGroup( "Ascii table") +
      new_TColorItem( "Frame passive",     24 )+
      new_TColorItem( "Frame active",      25 )+
      new_TColorItem( "Frame icons",       26 )+
      new_TColorItem( "Scroll bar page",   27 )+
      new_TColorItem( "Scroll bar icons",  28 )+
      new_TColorItem( "Text",              29
    );


  my $group5 = $group1 + $group2 + $group3 + $group4;

  my $c = new_TColorDialog( undef, $group5 );

  if ( $self->validView( $c ) ) {
    $c->helpCtx( hcOCColorsDBox );    # set context help constant
    $c->setData( [ $self->getPalette() ] );
    if ( $deskTop->execView( $c ) != cmCancel ) {
      $self->setPalette( $c->pal );
      $self->setScreenMode( $TUI::Drivers::Screen::screenMode );
    }
    $self->destroy( $c );
  }
  return;
}

#
# Mouse Control Dialog Box function
#

sub mouse {
  my ( $self ) = @_;
  my $mouseCage = $self->validView( new_TMouseDialog() );

  if ( $mouseCage ) {
    $mouseCage->helpCtx( hcOMMouseDBox );
    $mouseCage->setData( [$TUI::Drivers::EventQueue::mouseReverse] );
    if ( $deskTop->execView( $mouseCage ) != cmCancel ) {
      $mouseCage->getData( my $data = [] );
      $TUI::Drivers::EventQueue::mouseReverse = $data->[0];
    }
  }
  $self->destroy( $mouseCage );
  return;
}

#
# "Out of Memory" function ( called by validView() )
#

sub outOfMemory {
  messageBox( "Not enough memory available to complete operation.",
    mfError | mfOKButton );
  return;
}

#
# File Viewer function
#

sub openFile {
  my ( $self, $fileSpec ) = @_;
  my $d = $self->validView(
    new_TFileDialog( $fileSpec, "Open a File", "~N~ame", fdOpenButton, 100 ) );
  if ( $d && $deskTop->execView( $d ) != cmCancel ) {
    my $fileName;
    $d->getFileName( $fileName );
    $d->helpCtx( hcFOFileOpenDBox );
    my $w = $self->validView( new_TFileWindow( $fileName ) );
    $deskTop->insert( $w )
      if $w;
  }
  $self->destroy( $d );
  return;
}

#
# Event Viewer function
#

sub eventViewer {
  my ( $self ) = @_;
  my $viewer = message( $deskTop, evBroadcast, cmFndEventView, 0 );
  if ( $viewer ) {
    $viewer->toggle();
  }
  else {
    $deskTop->insert(
      new_TEventViewer( $deskTop->getExtent(), 0x0F00 ) );
  }
  return;
}

sub printEvent {
  my ( $self, $event ) = @_;
  my $viewer = message( $deskTop, evBroadcast, cmFndEventView, 0 );
  if ( $viewer ) {
    $viewer->print( $event );
  }
  return;
}

#
# isTileable() function ( checks a view on desktop is tileable or not )
#

my $isTileable = sub {
  return shift->options & ofTileable != 0;
};

#
# idle() function ( updates heap and clock views for this program. )
#

sub idle {
  my $self = shift;
  $self->SUPER::idle();
  $self->{clock}->update();
  $self->{heap}->update();
  if ( $deskTop->firstThat( $isTileable, 0 ) ) {
    $self->enableCommand( cmTile );
    $self->enableCommand( cmCascade );
  }
  else {
    $self->disableCommand( cmTile );
    $self->disableCommand( cmCascade );
  }
  return;
}

#
# Menubar initialization.
#

sub initMenuBar {
  my ( $class, $r ) = @_;
  
  my $sub1 = 
    new_TSubMenu( "~\360~", 0, hcSystem ) +
      new_TMenuItem( "~V~ideo mode", cmVideoMode, kbNoKey, hcNoContext, "" ) +
      newLine() +
      new_TMenuItem( "~A~bout...", cmAboutCmd, kbNoKey, hcSAbout ) +
      newLine() +
      new_TMenuItem( "~E~vent Viewer", cmEventViewCmd, kbAlt0, hcNoContext, 
        "Alt-0" );

  my $sub2 =
    new_TSubMenu( "~F~ile", 0, hcFile ) +
      new_TMenuItem( "~O~pen...", cmOpenCmd, kbF3, hcFOpen, "F3" ) +
      new_TMenuItem( "~C~hange Dir...", cmChDirCmd, kbNoKey, hcFChangeDir ) +
      newLine() +
      new_TMenuItem( "E~x~it", cmQuit, kbAltX, hcFExit, "Alt-X" );

  my $sub3 =
    new_TSubMenu( "~W~indows", 0, hcWindows ) +
      new_TMenuItem( "~R~esize/move", cmResize, kbCtrlF5, hcWSizeMove, 
        "Ctrl-F5" ) +
      new_TMenuItem( "~Z~oom", cmZoom, kbF5, hcWZoom, "F5" ) +
      new_TMenuItem( "~N~ext", cmNext, kbF6, hcWNext, "F6" ) +
      new_TMenuItem( "~C~lose", cmClose, kbAltF3, hcWClose, "Alt-F3" ) +
      new_TMenuItem( "~T~ile", cmTile, kbNoKey, hcWTile ) +
      new_TMenuItem( "C~a~scade", cmCascade, kbNoKey, hcWCascade );

  my $sub4 =
    new_TSubMenu( "~O~ptions", 0, hcOptions ) +
      new_TMenuItem( "~M~ouse...", cmMouseCmd, kbNoKey, hcOMouse ) +
      new_TMenuItem( "~C~olors...", cmColorCmd, kbNoKey, hcOColors );

  $r->{b}{y} = $r->{a}{y} + 1;
  return new_TMenuBar( $r, $sub1 + $sub2 + $sub3 + $sub4 );
}

package main; 

#
# main: create an application object.  Constructor takes care of all
#   initialization.  Calling run() from TProgram makes it tick and
#   the destructor will destroy the world.
#
#   File names can be specified on the command line for automatic
#   opening.
#

sub main {
  my ( $argc, $argv ) = @_;
  my $demoProgram = new_TVDemo( $argc, $argv );

  $demoProgram->run();
  
  $demoProgram = undef;
  return 0;
}

exit main( scalar @ARGV, \@ARGV );
