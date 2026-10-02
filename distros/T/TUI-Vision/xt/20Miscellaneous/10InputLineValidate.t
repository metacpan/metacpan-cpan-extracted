=pod

=head1 NAME

This example demonstrates a data validation rule for TInputLine. For the first 
line, only a number between 0 and 99 is allowed. For the second line, the input 
must be a day of the week (Monday–Friday). 

A ListBox would be more suitable for the second case, but we using TInputLine 
here to demonstrate how it works.

=head1 SEE ALSO

L<Lazarus-FreeVision-Tutorial|https://github.com/sechshelme/Lazarus-FreeVision-Tutorial/tree/master/20_-_Diverses/10_-_InputLine_Validate>

=cut

use strict;
use warnings;

use Test::More;
use Test::Exception;

use constant ManualTestsEnabled => exists($ENV{MANUAL_TESTS})
                                && !$ENV{AUTOMATED_TESTING}
                                && !$ENV{NONINTERACTIVE_TESTING};

BEGIN {
  use_ok 'TUI::App';
  use_ok 'TUI::Objects';
  use_ok 'TUI::Drivers';
  use_ok 'TUI::Views';
  use_ok 'TUI::Menus';
  use_ok 'TUI::Dialogs';
  use_ok 'TUI::Validate';
  use_ok 'TUI::toolkit';
}

BEGIN {
  package TMyApp;

  #
  # For dialogs, you still need to add the C<TUI::Dialogs> unit.
  #
  use TUI::App;        # TApplication
  use TUI::Objects;    # Window section (TRect)
  use TUI::Drivers;    # Hotkey
  use TUI::Views;      # Event (cmQuit)
  use TUI::Menus;      # Status line and menu
  use TUI::Dialogs;    # Dialogs
  use TUI::MsgBox;     # Message box for feedback
  use TUI::Validate;   # Validation framework
  use TUI::toolkit;

  use constant {
    cmOption => 1001,
  };

  extends TApplication;

  sub initStatusLine;    # Status line
  sub initMenuBar;       # Menu
  sub handleEvent;       # Event handler
  sub outOfMemory;       # Out of memory handler
  sub myDialog;          # Create and show the dialog

  # We want to use a console resolution like MS DOS.
  sub BUILDARGS {
    my $args = shift->SUPER::BUILDARGS( @_ ) || return;
    $args->{bounds} = new_TRect( 0, 0, 80, 25 );
    return $args;
  }

  sub initStatusLine {
    my ( $class, $r ) = @_;
    $r->{a}{y} = $r->{b}{y} - 1;
    return 
      new_TStatusLine( $r,
        new_TStatusDef( 0, 0xFFFF ) +
          new_TStatusItem( '~Alt+X~ Exit', kbAltX, cmQuit ) +
          new_TStatusItem( '~F10~ Menu', kbF10, cmMenu ) +
          new_TStatusItem( '~F4~ Validate Demo...',  kbF4,  cmOption )
      );
  }

  sub initMenuBar {
    my ( $class, $r ) = @_;
    $r->{b}{y} = $r->{a}{y} + 1;
    return
      new_TMenuBar( $r,
        new_TSubMenu( '~F~ile', hcNoContext ) + 
          new_TMenuItem( 'E~x~it', cmQuit, kbAltX, hcNoContext, 'Alt-X' ) +
        new_TSubMenu( '~O~ption', hcNoContext ) + 
          new_TMenuItem( '~V~alidate Demo...', cmOption, kbAltF4, hcNoContext, 
            'Alt-F4' )
      );
  }

  sub handleEvent {
    my ( $self, $event ) = @_;
    $self->SUPER::handleEvent( $event );

    if ( $event->{what} == evCommand ) {
      SWITCH: for ( $event->{message}{command} ) {
        cmOption == $_ and do {
          $self->myDialog();    # Open the validation dialog.
          last;
        };
        DEFAULT: {
          return;
        }
      }
    }
    $self->clearEvent( $event );
    return;
  }

  sub outOfMemory {
    my $self = shift;
    messageBox(  mfOKButton | mfError, 'Out of memory!' );
    return;
  }

  #
  # A dialog box with B<TInputLine> that undergoes a validation check.
  # When you click C<OK>, a validation check is performed.
  # If you click C<Cancel>, no validation check is performed.
  #
  sub myDialog {
    my $self = shift;

    # Weekdays allowed in the input line
    my @weekDays = qw(
      Monday
      Tuesday
      Wednesday
      Thursday
      Friday
      Saturday
      Sunday
    );

    my ( $r, $i, $inputLine, $strings );

    # Dialog itself
    $r = new_TRect( 0, 0, 42, 11 );
    $r->move( 23, 3 );
    my $dlg = new_TDialog( $r, 'Parameter' );

    #
    # InputLine with range validation 0-99
    #
    $r->assign( 25, 2, 36, 3 );
    $inputLine = new_TInputLine( $r, 6 );

    # Range validator 0-99
    $inputLine->setValidator( new_TRangeValidator( 0, 99 ) );
    $dlg->insert( $inputLine );
    $r->assign( 2, 2, 22, 3 );
    $dlg->insert( new_TLabel( $r, '~R~ange: 0-99', $inputLine ) );

    # Create Weekdays string collection
    $strings = new_TStringCollection( 10, 2 );

    #
    # Weekdays
    #
    # Fill collection with weekdays
    for my $day ( @weekDays ) {
      $strings->insert( $day );
    }
    $r->assign( 25, 4, 36, 5 );
    $inputLine = new_TInputLine( $r, 10 );

    # Lookup validator using string collection
    $inputLine->setValidator( new_TStringLookupValidator( $strings ) );
    $dlg->insert( $inputLine );
    $r->assign( 2, 4, 22, 5 );
    $dlg->insert( new_TLabel( $r, '~W~eekdays:', $inputLine ) );

    #
    # OK button
    #
    $r->assign( 7, 8, 19, 10 );
    $dlg->insert( new_TButton( $r, '~O~K', cmOK, bfDefault ) );

    #
    # Cancel button
    #
    $r->assign( 24, 8, 36, 10 );
    $dlg->insert( new_TButton( $r, '~C~ancel', cmCancel, bfNormal ) );

    $self->executeDialog( $dlg, undef );

    return;
  } #/ sub myDialog

  $INC{"TMyApp.pm"} = 1;
}

use_ok 'TMyApp';
SKIP: {
  skip 'Manual test not enabled', 3 unless ManualTestsEnabled();
  my $myApp;
  lives_ok { $myApp = new_ok( 'TMyApp' ) or die } 'init';
  lives_ok { $myApp->run()                      } 'run';
  lives_ok { undef $myApp                       } 'done';
}

done_testing;
