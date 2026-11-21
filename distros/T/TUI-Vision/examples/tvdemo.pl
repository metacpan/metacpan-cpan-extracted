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
use 5.010;

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
use TUI::Help;
use FindBin qw( $Bin );

use TUI::toolkit;
use Storable qw( store_fd retrieve_fd );

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

use constant HELP_FILENAME => "$FindBin::Bin/demohelp.txt";
use constant DESKTOP_FILENAME => "$FindBin::Bin/TVDEMO.DST";

has heap  => ( is => 'bare' );    # Heap view
has clock => ( is => 'bare' );    # Clock view

#
# Constructor for the application.  Command line parameters are interpreted
#   as file names and opened.  Wildcards are accepted and put up a dialog
#   box with the appropriate search path.
#

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

  # DOS shell is only supported on Win32.
  $self->disableCommand( cmDOS_Cmd )
    unless THardwareInfo->isa( 'TUI::Drivers::HardwareInfo::Win32' );

  my $r = $self->getExtent();     # Create the clock view.
  $r->{a}{x} = $r->{b}{x} - 9;
  $r->{b}{y} = $r->{a}{y} + 1;
  $self->{clock} = new_TClockView( $r );
  $self->{clock}{growMode} = gfGrowLoX | gfGrowHiX;
  $self->insert( $self->{clock} );

  $r = $self->getExtent();        # Create the heap view.
  $r->{a}{x} = $r->{b}{x} - 13;
  $r->{a}{y} = $r->{b}{y} - 1;
  $self->{heap} = new_THeapView( $r );
  $self->{heap}{growMode} = gfGrowAll;
  $self->insert( $self->{heap} );

  my $argc = $args->{argc};
  my @argv = @{ $args->{argv} };
  shift @argv;                    # skip argv[0].

  while ( --$argc > 0 ) {         # Display files specified on command line.
    my $fileSpec = shift @argv;
    my $len      = length $fileSpec;

    if ( substr( $fileSpec, $len - 1, 1 ) eq '\\' ) {
      $fileSpec .= '*.*';
    }
    if ( index( $fileSpec, '*' ) >= 0 || index( $fileSpec, '?' ) >= 0 ) {
      $self->openFile( $fileSpec );
    }
    else {
      my $w = $self->validView( new_TFileWindow( $fileSpec ) );
      $deskTop->insert( $w ) if $w;
    }
  }

  return;
}

#
# DemoApp::getEvent()
#  Event loop to check for context help request
#

sub getEvent {    # void ($event)
  my $self = shift;
  alias: for my $event ( shift ) {
  state $helpInUse = false;

  $self->SUPER::getEvent( $event );
  $self->printEvent( $event );

  SWITCH: for ( $event->{what} ) {
    case: evCommand == $_ and do {
      if ( $event->{message}{command} == cmHelp && !$helpInUse ) {
        $helpInUse = true;
        my $helpStrm;
        if ( open $helpStrm, '<:raw', HELP_FILENAME ) {
          my $hFile = THelpFile->new( stream => $helpStrm );
          my $w = THelpWindow->new(
            hFile   => $hFile,
            context => $self->getHelpCtx(),
          );
          if ( $self->validView( $w ) ) {
            $self->execView( $w );
            $self->destroy( $w );
          }
          $self->clearEvent( $event );
        }
        else {
          messageBox( "Could not open help file", mfError | mfOKButton );
        }
        $helpInUse = false;
      } #/ if ( $event->{message}...)
      elsif ( $event->{message}{command} == cmVideoMode ) {
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
# Puzzle function
#

sub puzzle {
  my ( $self ) = @_;
  my $win = $self->validView( new_TPuzzleWindow() );
  if ( $win ) {
    $win->helpCtx( hcPuzzle );
    $deskTop->insert( $win );
  }
  return;
}

#
# retrieveDesktop() function ( restores the previously stored Desktop )
#

sub retrieveDesktop {    # void ()
  my ( $self ) = @_;

  unless ( -e DESKTOP_FILENAME ) {
    messageBox( 'Could not find desktop file', mfOKButton | mfError );
    return;
  }
  my $f;
  unless ( open $f, '<:raw', DESKTOP_FILENAME ) {
    messageBox( 'Could not open desktop file', mfOKButton | mfError );
    return;
  }
  my $ok = eval {
    my $stream = retrieve_fd( $f );
    $self->loadDesktop( $stream );
    1;
  };
  close $f;
  unless ( $ok ) {
    messageBox( 'Error reading desktop file', mfOKButton | mfError );
  }
  return;
}

#
# saveDesktop() function ( saves the DeskTop by calling storeDesktop function )
#

sub saveDesktop {    # void ()
  my ( $self ) = @_;

  my $f;
  unless ( open $f, '>:raw', DESKTOP_FILENAME ) {
    return;
  }
  my $stream = new_TStream();
  my $ok = eval {
    $self->storeDesktop( $stream );
    store_fd( $stream, $f );
    1;
  };
  close $f;
  unless ( $ok ) {
    messageBox( "Could not create " . DESKTOP_FILENAME . ".", 
      mfOKButton | mfError );
    unlink DESKTOP_FILENAME;
  }
  return;
}

#
# writeView() function ( writes a view object to a resource file )
#

my $writeView = sub {    # void ($p, $strm)
  my ( $p, $s ) = @_;
  my $last = $deskTop->last;
  $s->put( $p )
    if $p != $last;
  return;
};

#
# storeDesktop() function ( stores the Desktop in a resource file )
#

sub storeDesktop {    # void ($s)
  my ( $self, $s ) = @_;
  $deskTop->forEach( $writeView, $s );
  $s->put( undef );
  return;
}

#
# Tile function
#

sub tile {
  $deskTop->tile( $deskTop->getExtent() );
  return;
}

#
# DOS Shell Command.
#

sub shell {
  my ( $self ) = @_;
  return unless 
    THardwareInfo->isa( 'TUI::Drivers::HardwareInfo::Win32' );
  $self->suspend();
  print "Type EXIT to return...\n";
  system( $ENV{COMSPEC} );
  $self->resume();
  $self->redraw();
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

      cmCalendarCmd == $_ and do {     #  Calendar Window
        $self->calendar();
        last;
      };

      cmAsciiCmd == $_ and do {        #  Ascii Table
        $self->asciiTable();
        last;
      };

      cmCalcCmd == $_ and do {         #  Calculator
        $self->calculator();
        last;
      };

      cmPuzzleCmd == $_ and do {       #  Puzzle
        $self->puzzle();
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

      cmDOS_Cmd == $_ and do {         #  DOS shell
        $self->shell();
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

      cmSaveCmd == $_ and do {         #  Save current desktop
        $self->saveDesktop();
        last;
      };

      cmRestoreCmd == $_ and do {      #  Restore saved desktop
        $self->retrieveDesktop();
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
        "\003Turbo Vision Demo\n\n" .     # These strings will be
        "\003Perl Port Version\n\n" .     # concatenated by the compiler.
        "\003Copyright (c) 1994\n\n" .    # The \003 centers the line.
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
# Ascii Chart function()
#

sub asciiTable {
  my ( $self ) = @_;
  my $chart = $self->validView( new_TAsciiChart() );
  if ( $chart ) {
    $chart->helpCtx( hcAsciiTable );
    $deskTop->insert( $chart );
  }
  return;
}

#
# Calculator function
#

sub calculator {
  my ( $self ) = @_;
  my $calc = $self->validView( new_TCalculator() );
  if ( $calc ) {
    $calc->helpCtx( hcCalculator );
    $deskTop->insert( $calc );
  }
  return;
}

#
# Calendar function
#

sub calendar {
  my ( $self ) = @_;
  my $cal = $self->validView( new_TCalendarWindow() );
  if ( $cal ) {
    $cal->helpCtx( hcCalendar );
    $deskTop->insert( $cal );
  }
  return;
}

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
# "Out of Memory" function ( called by validView() )
#

sub outOfMemory {
  messageBox( "Not enough memory available to complete operation.",
    mfError | mfOKButton );
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

my $isTileable = sub {    # $bool ($p, $p1)
  my ( $p, $p1 ) = @_;
  return ( $p->options & ofTileable ) != 0;
};

#
# idle() function ( updates heap and clock views for this program. )
#

sub idle {
  my $self = shift;
  $self->SUPER::idle();
  $self->{clock}->update();
  $self->{heap}->update();
  if ( $deskTop->firstThat( $isTileable, undef ) ) {
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
# closeView() function
#

my $closeView = sub {    # $void ($p, $p1)
  my ( $p, $p1 ) = @_;
  message( $p, evCommand, cmClose, $p1 );
  return;
};

#
# loadDesktop() function 
#

sub loadDesktop {    # void ($s)
  my ( $self, $s ) = @_;
  my $p;
  if ( $deskTop->valid( cmClose ) ) {
    $deskTop->forEach( $closeView, undef );    # Clear the desktop
    do {
      $p = $s->get();
      $deskTop->insertBefore( $self->validView( $p ), $deskTop->last );
    } while ( $p );
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
      new_TMenuItem( "~P~uzzle", cmPuzzleCmd, kbNoKey, hcSPuzzle ) +
      new_TMenuItem( "Ca~l~endar", cmCalendarCmd, kbNoKey, hcSCalendar ) +
      new_TMenuItem( "Ascii ~T~able", cmAsciiCmd, kbNoKey, hcSAsciiTable ) +
      new_TMenuItem( "~C~alculator", cmCalcCmd, kbNoKey, hcCalculator ) +
      new_TMenuItem( "~E~vent Viewer", cmEventViewCmd, kbAlt0, hcNoContext, 
        "Alt-0" );

  my $sub2 =
    new_TSubMenu( "~F~ile", 0, hcFile ) +
      new_TMenuItem( "~O~pen...", cmOpenCmd, kbF3, hcFOpen, "F3" ) +
      new_TMenuItem( "~C~hange Dir...", cmChDirCmd, kbNoKey, hcFChangeDir ) +
      newLine() +
      new_TMenuItem( "~D~OS Shell", cmDOS_Cmd, kbNoKey, hcFDosShell ) +
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
      new_TMenuItem( "~C~olors...", cmColorCmd, kbNoKey, hcOColors ) +
      new_TMenuItem( "~S~ave desktop", cmSaveCmd, kbNoKey, hcOSaveDesktop ) +
      new_TMenuItem( "~R~etrieve desktop", cmRestoreCmd, kbNoKey, 
        hcORestoreDesktop );

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

tvdemo.pl - Turbo Vision 2.0 demonstration application

=head1 SYNOPSIS

  tvdemo.pl [options] [file ...]

  Options:
    -?, --help    Show brief usage information
        --man     Show the complete manual

=head1 DESCRIPTION

C<tvdemo.pl> is a Perl port of the TVDEMO application supplied with
Borland I<Turbo Vision> 2.0 for C++.

TVDEMO is a comprehensive demonstration of the I<Turbo Vision> application
framework.  Rather than concentrating on a single control, it combines
menus, windows, dialogs, gadgets, event handling, context-sensitive
help, file viewing, desktop management, color and mouse configuration,
and several small demonstration applications in one program.

The Perl version follows the structure and behavior of the original
application while using the corresponding L<TUI::Vision> classes and
runtime facilities.

One or more file names may be specified on the command line.  Files are
opened automatically in viewer windows when the application starts.
File specifications containing wildcards open the file-selection
dialog.

=head1 USER INTERFACE

The application provides four main menus: System, File, Windows, and
Options.

The menu commands exercise different parts of the I<Turbo Vision>
framework and are also intended as examples of how application commands
are dispatched from C<handleEvent()>.

=head2 System menu

The System menu contains the demonstration programs and general
application commands.

=over 4

=item C<Video mode>

Changes the active screen mode.

=item C<About...>

Displays information about the I<Turbo Vision> demonstration.

=item C<Puzzle>

Opens the sliding puzzle demonstration.

=item C<Calendar>

Opens the interactive calendar window.

=item C<Ascii Table>

Opens an ASCII character table.

=item C<Calculator>

Opens the calculator demonstration.

=item C<Event Viewer>

Opens or toggles the event viewer.  The event viewer displays events
received by the application and can be used to observe I<Turbo Vision>'s
event-driven operation.

=back

=head2 File menu

=over 4

=item C<Open...>

Displays a file dialog and opens the selected file in a viewer window.

=item C<Change Dir...>

Displays the standard change-directory dialog.

=item C<DOS Shell>

Temporarily suspends the TUI, starts the system command processor, and
restores and redraws the application after the command processor exits.

This operation is available only when the Win32 backend is active.

=item C<Exit>

Terminates the application.

=back

=head2 Windows menu

The Windows menu operates on windows currently present on the desktop.

=over 4

=item C<Resize/move>

Allows the selected window to be resized or moved.

=item C<Zoom>

Toggles the selected window between its normal and zoomed sizes.

=item C<Next>

Selects the next window.

=item C<Close>

Closes the selected window.

=item C<Tile>

Arranges tileable windows so that they share the available desktop
area.

=item C<Cascade>

Arranges the current windows in a cascading layout.

=back

The Tile and Cascade commands are enabled only when the desktop
contains a tileable view.

=head2 Options menu

=over 4

=item C<Mouse...>

Displays the mouse configuration dialog.  Changes made in the dialog
are applied to the event queue.

=item C<Colors...>

Displays the I<Turbo Vision> color dialog.

The dialog exposes the palette entries used by the desktop, menus,
dialogs, viewer, puzzle, calendar, and ASCII table.  Accepted changes
are applied to the application palette and the screen is redrawn using
the new colors.

=item C<Save desktop>

Stores the views currently present on the desktop in C<TVDEMO.DST>.

=item C<Retrieve desktop>

Restores a previously saved desktop from C<TVDEMO.DST>.

=back

=head1 COMMAND LINE FILES

Files specified after the options are opened automatically when TVDEMO
starts.

For example:

  tvdemo.pl README.txt

Multiple file names may be specified:

  tvdemo.pl README.txt Changes.txt

File specifications containing C<*> or C<?> are passed to the Open File
dialog so that a matching file can be selected interactively.

A specification ending in a directory separator is completed with
C<*.*> before the file dialog is opened.

=head1 CONTEXT-SENSITIVE HELP

Press C<F1> to request help for the currently active view or command.

Each relevant menu item, dialog, and demonstration window has a help
context.  TVDEMO obtains the current help context and opens a
L<THelpWindow|TUI::Help::HelpWindow> at the corresponding topic.

The Perl port reads its help topics from:

  demohelp.txt

This differs from the original C++ demonstration, where the help source
was processed by the I<Turbo Vision> Help Compiler.  The difference is in
the help-file representation rather than in TVDEMO's context-sensitive
help model.

The handling and format of help files are described by
L<THelpFile|TUI::Help::HelpFile>.

=head1 DEMONSTRATION WINDOWS

=head2 Puzzle

The Puzzle window demonstrates a small interactive application inside a
I<Turbo Vision> window.  It has its own help context and participates in
normal desktop window management.

=head2 Calendar

The Calendar window displays an interactive monthly calendar.  The
current date is initialized from the system date.

=head2 ASCII Table

The ASCII Table demonstrates a custom selectable view and coordinated
display of character information.

=head2 Calculator

The Calculator demonstrates a complete dialog-like application with its
own input and display handling.

=head2 File Viewer

Files are displayed using L<TFileWindow|TUI::Gadgets::FileWindow>.
File windows participate in the normal desktop operations and may
therefore be moved, resized, zoomed, closed, tiled, and cascaded.

=head2 Event Viewer

The Event Viewer exposes the application's event stream.

While it is active, events received through C<getEvent()> are sent to
the viewer.  Selecting the Event Viewer command again toggles whether
the existing viewer is actively recording events.

=head1 DESKTOP PERSISTENCE

TVDEMO demonstrates persistence of an application's desktop.

C<Save desktop> stores the views on the desktop in:

  TVDEMO.DST

C<Retrieve desktop> closes the current desktop views and recreates the
views stored in that file.

Only the desktop views are persisted.  Application-level views such as
the menu bar, clock, and heap display remain part of the running
application.

This demonstrates the I<Turbo Vision> concept of streamable views while
using the persistence mechanism provided by the Perl implementation.

=head1 APPLICATION GADGETS

TVDEMO places two continuously updated gadgets in the application
frame.

=head2 Clock

The clock displays the current time and is refreshed while the
application is idle.

=head2 Heap display

The heap gadget displays runtime memory information and is also
refreshed while the application is idle.

The original I<Turbo Vision> demonstration supplied both gadgets as part
of its example code.

=head1 EVENT PROCESSING

TVDEMO demonstrates several layers of I<Turbo Vision> event processing.

C<getEvent()> receives events from the underlying application framework.
It additionally handles context-sensitive help, the video-mode command,
and application event monitoring.

C<handleEvent()> dispatches application-specific commands such as
opening demonstration windows, executing file operations, changing
options, and saving or restoring the desktop.

The application also uses command and broadcast events to communicate
between views, including the Event Viewer.

This separation illustrates the central I<Turbo Vision> model in which
input, commands, view communication, and application actions are
represented through L<TEvent|TUI::Drivers::Event> objects.

=head1 IDLE PROCESSING

The application overrides its idle processing to update the clock and
heap gadgets.

It also examines the desktop and enables or disables the Tile and
Cascade commands depending on whether tileable views are currently
available.

This demonstrates that command availability in I<Turbo Vision> can reflect
the current state of the user interface rather than being fixed when
the menus are constructed.

=head1 KEYBOARD SHORTCUTS

=over 4

=item C<F1>

Open context-sensitive help.

=item C<F3>

Open a file.

=item C<F5>

Zoom or restore the selected window.

=item C<F6>

Select the next window.

=item C<F10>

Activate the menu bar.

=item C<Ctrl-F5>

Resize or move the selected window.

=item C<Alt-F3>

Close the selected window.

=item C<Alt-0>

Open or toggle the Event Viewer.

=item C<Alt-X>

Exit the application.

=item C<Shift-Delete>

Cut selected text where supported by the active view.

=item C<Ctrl-Insert>

Copy selected text where supported by the active view.

=item C<Shift-Insert>

Paste text where supported by the active view.

=back

=head1 DEMONSTRATED FEATURES

TVDEMO brings together a broad selection of I<Turbo Vision> facilities:

=over 4

=item *

Application initialization and the
L<TApplication|TUI::App::Application> event loop.

=item *

Menus, status lines, commands, and keyboard shortcuts.

=item *

Multiple independent and modal windows.

=item *

Standard dialogs for files and directories.

=item *

Context-sensitive help and help contexts.

=item *

Custom views and application-specific window classes.

=item *

Event handling, command events, and broadcast events.

=item *

Dynamic command enabling and disabling.

=item *

File viewing and command-line file opening.

=item *

Window management, including resize, zoom, tile, and cascade.

=item *

Application palettes and interactive color configuration.

=item *

Mouse configuration.

=item *

Continuous idle-time gadgets.

=item *

Observation of the application event stream.

=item *

Serialization and restoration of desktop views.

=item *

Suspending and resuming the application around an external command
processor.

=back

=head1 ORIGINAL SOURCE

This program is a Perl port of the TVDEMO demonstration supplied with
Borland I<Turbo Vision> 2.0 for C++.

The original demonstration is implemented by a collection of source
files centered around:

  TVDEMO.H
  TVDEMO1.CPP
  TVDEMO2.CPP
  TVDEMO3.CPP

Additional source files implement the individual demonstrations and
supporting views, including the puzzle, calendar, ASCII table,
calculator, file viewer, event viewer, application gadgets, and mouse
dialog.

TVDEMO was designed as an integrated demonstration of the I<Turbo Vision>
framework rather than as an example of a single class.  The application
shows how independent I<Turbo Vision> components cooperate through the
desktop, event system, command system, palettes, streams, and help
contexts.

The Perl port preserves the structure and observable behavior of the
original demonstration while expressing it through L<TUI::Vision>.

=head1 PORTING NOTES

The principal intentional difference concerns the help data.

The original I<Turbo Vision> example used help data prepared by the
I<Turbo Vision> Help Compiler.  The L<TUI::Vision> port uses
C<demohelp.txt> directly through L<THelpFile|TUI::Help::HelpFile>.  The
application-level context handling
remains equivalent: help contexts select topics which are displayed in
a L<THelpWindow|TUI::Help::HelpWindow>.

Desktop persistence is implemented using the L<TUI::Vision> stream
representation and Perl persistence facilities while preserving
TVDEMO's original Save Desktop and Retrieve Desktop operations.

The DOS Shell command is exposed only by the Win32 backend, where the
system command processor is obtained from C<COMSPEC>.

=head1 FILES

=over 4

=item C<demohelp.txt>

Context-sensitive help data used by L<THelpFile|TUI::Help::HelpFile>.

=item C<TVDEMO.DST>

Desktop state written by C<Save desktop> and read by
C<Retrieve desktop>.

=back

Both files are located relative to the TVDEMO program.

=head1 SEE ALSO

L<TUI::Vision>,
L<TUI::App>,
L<TUI::ColorSel>,
L<TUI::Dialogs>,
L<TUI::Gadgets>,
L<TUI::Help>,
L<TUI::Menus>,
L<TUI::MsgBox>,
L<TUI::StdDlg>,
L<TUI::Views>

=head1 COPYRIGHT

The original TVDEMO sources contain the following copyright notice:

  Turbo Vision - Version 2.0

  Copyright (c) 1994 by Borland International
  All Rights Reserved.

This Perl version is a port of the original demonstration for
L<TUI::Vision>.

See the L<TUI::Vision> distribution for copyright and licensing
information relating to the Perl implementation.

=cut
