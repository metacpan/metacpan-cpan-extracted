=pod

=head1 NAME

Folder Selection Dialog. The TChDirDialog.

=head1 SEE ALSO

L<Lazarus-FreeVision-Tutorial|https://github.com/sechshelme/Lazarus-FreeVision-Tutorial/tree/master/15_-_Fertige_Dialoge/25_-_Ordner_wechseln>

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
  use_ok 'TUI::StdDlg';
  use_ok 'TUI::MsgBox';
  use_ok 'TUI::toolkit';
}

BEGIN {
  package TMyApp;

  use TUI::App;        # TApplication
  use TUI::Objects;    # Window section (TRect)
  use TUI::Drivers;    # Hotkey
  use TUI::Views;      # Event (cmQuit)
  use TUI::Menus;      # Status line and menu
  use TUI::StdDlg;     # Builtin Dialogs
  use TUI::MsgBox;
  use TUI::toolkit;

  use constant {
    cmChdir => 1001,
    cmAbout => 1010,
  };

  extends TApplication;

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
          new_TStatusItem( '~F1~ Help', kbF1, cmHelp )
      );
  }

  sub initMenuBar {
    my ( $class, $r ) = @_;
    $r->{b}{y} = $r->{a}{y} + 1;
    return
      new_TMenuBar( $r, 
        new_TSubMenu( '~F~ile', hcNoContext ) + 
          new_TMenuItem( '~C~hange folder...', cmChdir, kbF7, hcNoContext, 'F7' ) +
          newLine +
          new_TMenuItem( 'E~x~it', cmQuit, kbAltX, hcNoContext, 'Alt-X' ) +
        new_TSubMenu( '~H~elp', hcNoContext ) + 
          new_TMenuItem( '~A~bout', cmAbout, hcNoContext )
      );
  }

  # The Change Folder Dialog
  sub handleEvent {
    my ( $self, $event ) = @_;

    $self->SUPER::handleEvent( $event );

    if ( $event->{what} == evCommand ) {
      SWITCH: for ( $event->{message}{command} ) {
        cmChdir == $_ and do {
          my $chDirDialog = TChDirDialog->new(
            options   => fdOpenButton,
            histId    => 1,
          );
          if ( $application->executeDialog( $chDirDialog, undef ) != cmCancel) {
            messageBox( 'The folder has been changed', mfOKButton );
          }
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
