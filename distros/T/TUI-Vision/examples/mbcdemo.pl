#---------------------------------------------------------#
#                                                         #
#    Turbo Vision MultiCheckBoxes Demo Source File        #
#                                                         #
#---------------------------------------------------------#
#
#      Turbo Vision - Version 2.0 (Perl Edition)
#
#      Demonstrates the TMultiCheckBoxes control.
#
#
package TMCBDemo;

use strict;
use warnings;

use TUI::Objects;
use TUI::Menus;
use TUI::Drivers;
use TUI::App;
use TUI::Views;
use TUI::Dialogs;
use TUI::MsgBox;

use TUI::toolkit;

sub ::new_TMCBDemo { __PACKAGE__->new() }

extends TApplication;

use constant {
  cmDemoMCB => 1000,
};

sub BUILDARGS {
  return {
    %{ shift->SUPER::BUILDARGS() },
    bounds => new_TRect( 0, 0, 80, 25 ),
  };
}

#
# Demo dialog showing the TMultiCheckBoxes control       
#
sub showMultiCheckBoxDemo {
  my ( $self ) = @_;

  # Build a HashRef chain (3 entries)
  # First -> Second -> Third -> undef
  my $items =  { value => 'Low',  next 
            => { value => 'Med',  next 
            => { value => 'High', next 
            => undef }}};

  # Create a dialog
  my $d = new_TDialog(
    new_TRect( 10, 4, 50, 18 ),
    "MultiCheckBoxes Demo"
  );

  # Insert a MultiCheckBoxes control
  my $mcb = TMultiCheckBoxes->new(
    bounds   => new_TRect( 3, 2, 30, 5 ),
    strings  => $items,
    selRange => 3,         # three states: "-", "+", "*"
    flags    => 0x0203,    # mask=0x03, shift=2 bits per item
    states   => "-+*",     # state characters
  );

  $d->insert( $mcb );

  # Buttons
  $d->insert( new_TButton( 
    new_TRect( 10, 8, 22, 10 ), "~O~k", cmOK, bfDefault ) );
  $d->insert( new_TButton( 
    new_TRect( 10, 10, 22, 12 ), "~C~ancel", cmCancel, bfNormal ) );

  # Show dialog
  my $res = $self->executeDialog( $d );

  # Retrieve final state (value bitfield)
  if ( $res == cmOK ) {
    my $result = $mcb->{value};
    my $msg    = sprintf "Final bitfield value: 0b%08b", $result;
    messageBox( $msg, mfInformation | mfOKButton );
  }

  $self->destroy( $d );
  return;
} #/ sub showMultiCheckBoxDemo

#
# Event handler                                          
#
sub handleEvent {
  my ( $self, $event ) = @_;
  $self->SUPER::handleEvent( $event );

  if ( $event->{what} == evCommand ) {
    SWITCH: for ( $event->{message}{command} ) {

      cmDemoMCB == $_ and do {
        $self->showMultiCheckBoxDemo();
        $self->clearEvent( $event );
        last;
      };

      DEFAULT: { last }
    } #/ SWITCH: for ( $event->{message}...)
  } #/ if ( $event->{what} ==...)
  return;
} #/ sub handleEvent

#
# Menu bar                                               
#
sub initMenuBar {
  my ( $class, $r ) = @_;
  $r->{b}{y} = $r->{a}{y} + 1;

  return new_TMenuBar(
    $r,
    new_TSubMenu( "~D~emo", kbAltD ) +
      new_TMenuItem( "~M~ultiCheck Demo...", cmDemoMCB, kbAltM ) +
      newLine() +
      new_TMenuItem( "E~x~it", cmQuit, cmQuit, hcNoContext, "Alt-X" )
  );
} #/ sub initMenuBar

#
# Status line                                            
#
sub initStatusLine {
  my ( $class, $r ) = @_;
  $r->{a}{y} = $r->{b}{y} - 1;

  return new_TStatusLine(
    $r,
    new_TStatusDef( 0, 0xFFFF ) +
      new_TStatusItem( "~Alt-X~ Exit", kbAltX, cmQuit ) +
      new_TStatusItem( "",             kbF10,  cmMenu )
  );
} #/ sub initStatusLine

#
# Main entry point                                       
#
package main;

sub main {
  my $app = new_TMCBDemo();
  $app->run();
  return 0;
}

exit main();
