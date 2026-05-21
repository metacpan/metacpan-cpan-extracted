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

use TUI::toolkit;

sub ::new_TEditorApp { __PACKAGE__->new( argc => shift, argv => shift ) }

extends TApplication;

use constant cmChangeDrct => 102;

# TODO: full TEditor support
{
  use constant cmFind => 82;
  use constant edFind => 7;
  use constant {
    efCaseSensitive   => 0x0001,
    efWholeWordsOnly  => 0x0002,
    efDoReplace       => 0x0010,
  };
  use vars qw(
    $editorDialog
    $findStr
    $editorFlags
  );
  $findStr = "";
  $editorFlags = 0;
  use Class::Struct TFindDialogRec => [
    find    => '$',
    options => '$',
  ];
}

sub BUILDARGS {
  return {
    %{ shift->SUPER::BUILDARGS() },
    argc   => $_{argc} || 0,
    argv   => $_{argv} || [],
    bounds => new_TRect( 0, 0, 80, 25 ),
  };
}

sub BUILD {
  $editorDialog = \&doEditDialog;
  return;
}

sub handleEvent {
  my ( $self, $event ) = @_;
  $self->SUPER::handleEvent( $event );

  if ( $event->{what} == evCommand ) {
    SWITCH: for ( $event->{message}{command} ) {

      cmFind == $_ and do {    # sub find
        my $findRec = TFindDialogRec->new(
          find    => $findStr, 
          options => $editorFlags,
        );
        if ( $editorDialog->( edFind, $findRec ) != cmCancel ) {
          $findStr = $findRec->find;
          $editorFlags = $findRec->options & ~efDoReplace;
          # doSearchReplace()
        }
        last;
      };

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

sub initMenuBar {
  my ( $class, $r ) = @_;
  
  my $sub3 = new_TSubMenu( "~S~earch", kbAltS ) +
    new_TMenuItem( "~F~ind...", cmFind, kbNoKey );

  $r->{b}{y} = $r->{a}{y} + 1;
  return new_TMenuBar( $r, $sub3 );
}

sub initStatusLine {
  my ( $class, $r ) = @_;
  $r->{a}{y} = $r->{b}{y} - 1;
  return new_TStatusLine( $r,
    new_TStatusDef( 0, 0xFFFF ) +
      new_TStatusItem( "~Alt-X~ Exit", kbAltX, cmQuit ) +
      new_TStatusItem( "~Ctrl-W~ Close", kbAltF3, cmClose ) +
      new_TStatusItem( "~F10~ Menu", kbF10, cmMenu ) +
      new_TStatusItem( '', kbShiftDel, cmCut ) +
      new_TStatusItem( '', kbCtrlIns, cmCopy ) +
      new_TStatusItem( '', kbShiftIns, cmPaste ) +
      new_TStatusItem( '', kbCtrlF5, cmResize )
  );
}

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

sub doEditDialog {
  my ( $dialog, $arg ) = @_;
  SWITCH: for ( $dialog ) {

    edFind == $_ and do {
      return $application->executeDialog( createFindDialog(), $arg );
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

exit main( scalar @ARGV, \@ARGV );
