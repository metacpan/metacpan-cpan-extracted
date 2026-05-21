=pod

=head1 NAME

Display and close windows via the menu.

=head1 SEE ALSO

L<Lazarus-FreeVision-Tutorial|https://github.com/sechshelme/Lazarus-FreeVision-Tutorial/tree/master/11_-_Fenster/05_-_Fenster_neu_und_schliessen>

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
  use_ok 'TUI::toolkit';
}

BEGIN {
  package TMyApp;

  use TUI::App;        # TApplication
  use TUI::Objects;    # Window section (TRect)
  use TUI::Drivers;    # Hotkey
  use TUI::Views;      # Event (cmQuit)
  use TUI::Menus;      # Status line and menu
  use TUI::toolkit;

  # New constants for commands.
  # handleEvent has also been added.
  use constant {
    cmNewWin => 1001,
  };

  extends TApplication;

  # We want to use a console resolution like MS DOS.
  sub BUILDARGS {
    my $args = shift->SUPER::BUILDARGS( @_ ) || return;
    $args->{bounds} = new_TRect( 0, 0, 80, 25 );
    return $args;
  }

  # The menu has been expanded to include B<New> and B<Close>.
  sub initMenuBar {
    my ( $class, $r ) = @_;
    $r->{b}{y} = $r->{a}{y} + 1;
    return
      new_TMenuBar( $r, 
        new_TSubMenu( '~F~ile', hcNoContext ) + 
          new_TMenuItem( '~N~ew', cmNewWin, kbF4, hcNoContext, 'F4' ) +
          new_TMenuItem( '~C~lose', cmClose, kbAltF3, hcNoContext, 'Alt-F3' ) +
          newLine +
          new_TMenuItem( 'E~x~it', cmQuit, kbAltX, hcNoContext, 'Alt-X' )
      );
  }

  sub outOfMemory {
    # messageBox('Insufficient RAM!', undef, mfError + mfOkButton);
    return;
  }

  # Create new window. A window are not usually opened modally, as you usually 
  # want to open several of them.
  sub newWindows {
    my $self = shift;
    use feature 'state';
    state $winCounter = 0;
    my $r    = new_TRect( 0, 0, 60, 20 );
    my $win  = new_TWindow( $r, 'Window', ++$winCounter );
    # If there is insufficient memory for a new window, then count backdown -1.
    if ( $self->validView( $win ) ) {
      $deskTop->insert( $win );
    }
    else {
      $winCounter--;
    }
    return;
  }

  # You have to process C<cmNewWin> yourself. C<cmClose> for closing the window 
  # runs automatically in the background.
  sub handleEvent {
    my ( $self, $event ) = @_;
    $self->SUPER::handleEvent( $event );
    if ( $event->{what} == evCommand ) {
      SWITCH: for ( $event->{message}{command} ) {
        cmNewWin == $_ and do {
          $self->newWindows();    # Create window.
          last;
        };
        DEFAULT: {
          return;
        }
      }
    }
    $self->clearEvent( $event );
    return;
  } #/ sub handleEvent

  $INC{"TMyApp.pm"} = 1;
}

use_ok 'TMyApp';
SKIP: {
  skip 'Manual test not enabled', 2 unless ManualTestsEnabled();
  my $myApp = TMyApp->new();
  isa_ok( $myApp, TApplication );
  lives_ok { $myApp->run() } 'TMyApp object executed successfully';
}

done_testing;
