=pod

=head1 NAME

Processing events, the status bar, and the menu.

=head1 SEE ALSO

L<Lazarus-FreeVision-Tutorial|https://github.com/sechshelme/Lazarus-FreeVision-Tutorial/tree/master/03_-_Dialoge/05_-_Erster_Dialog>

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
  use TUI::toolkit;

  #
  # Another command for calling up the dialog box.
  #
  use constant {
    cmAbout => 1001,    # Display About
    cmList  => 1002,    # File list
    cmPara  => 1003,    # Parameters
  };

  # New features are also coming to this class.
  # Here is a dialog box for entering parameters.
  extends TApplication;

  sub initStatusLine;    # Status line
  sub initMenuBar;       # Menu
  sub handleEvent;       # Event handler
  sub myParameter;       # new function for a dialog.

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
          new_TStatusItem( '~F1~ Help',  kbF1,  cmHelp )
      );
  }

  # The menu is expanded to include parameters and close.
  sub initMenuBar {
    my ( $class, $r ) = @_;
    $r->{b}{y} = $r->{a}{y} + 1;
    return
      new_TMenuBar( $r,
        new_TSubMenu( '~F~ile', hcNoContext ) + 
          new_TMenuItem( '~L~ist', cmList, kbF2, hcNoContext, 'F2' ) +
          new_TMenuItem( '~P~arameter', cmPara, hcNoContext ) +
          newLine +
          new_TMenuItem( '~C~lose', cmClose, kbAltF3, hcNoContext, 'Alt-F3' ) +
          newLine +
          new_TMenuItem( 'E~x~it', cmQuit, kbAltX, hcNoContext, 'Alt-X' ) +
        new_TSubMenu( '~H~elp', hcNoContext ) + 
          new_TMenuItem( '~A~bout', cmAbout, hcNoContext )
      );
  }

  # Here, the command C<cmPara> opens a dialog box.
  sub handleEvent {
    my ( $self, $event ) = @_;
    $self->SUPER::handleEvent( $event );

    if ( $event->{what} == evCommand ) {
      SWITCH: for ( $event->{message}{command} ) {
        cmAbout == $_ and do {
          last;
        };
        cmList == $_ and do {
          last;
        };
        cmPara == $_ and do {
          $self->myParameter();    # Open the parameter dialog.
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

  # Building an empty dialog box.
  # Here too, B<TRect> is used for the size.
  # This is used for all components, regardless of whether they are buttons, 
  # etc.
  sub myParameter {
    my $self = shift;
    my $r    = new_TRect( 0, 0, 35, 15 );        # Size of the dialog.
    $r->move( 23, 3 );                           # Position of the dialog.
    my $dlg = new_TDialog( $r, 'Parameter' );    # Create dialog.
    $deskTop->insert( $dlg );                    # Assign dialog to app.
    return;
  }

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
