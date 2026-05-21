=pod

=head1 NAME

A dialog box for opening and saving files. The TFileDialog.

=head1 SEE ALSO

L<Lazarus-FreeVision-Tutorial|https://github.com/sechshelme/Lazarus-FreeVision-Tutorial/tree/master/15_-_Fertige_Dialoge/20_-_Datei_Dialoge>

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
    cmFileOpen => 1001,
    cmFileSave => 1002,
    cmFileHelp => 1003,
    cmAbout    => 1010,
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
          new_TMenuItem( '~O~pen...', cmFileOpen, kbF3, hcNoContext, 'F3' ) +
          new_TMenuItem( '~S~ave as...', cmFileSave, hcNoContext ) +
          new_TMenuItem( 'Add. ~B~uttons...', cmFileHelp, hcNoContext ) +
          newLine +
          new_TMenuItem( 'E~x~it', cmQuit, kbAltX, hcNoContext, 'Alt-X' ) +
        new_TSubMenu( '~H~elp', hcNoContext ) + 
          new_TMenuItem( '~A~bout', cmAbout, hcNoContext )
      );
  }

  # Various File Dialogs
  sub handleEvent {
    my ( $self, $event ) = @_;

    $self->SUPER::handleEvent( $event );

    if ( $event->{what} == evCommand ) {
      SWITCH: for ( $event->{message}{command} ) {
        cmFileOpen == $_ and do {
          my @fileName = qw( *.* );
          my $fileDialog = TFileDialog->new(
            wildCard  => $fileName[0],
            title     => 'Open File',
            inputName => '~F~ile Name',
            options   => fdOpenButton,
            histId    => 1,
          );
          if ( $application->executeDialog( $fileDialog, \@fileName ) 
            != cmCancel
          ) {
            messageBox( "'$fileName[0]' was entered", mfOKButton );
          }
          last;
        };
        cmFileSave == $_ and do {
          my @fileName = qw( *.* );
          my $fileDialog = TFileDialog->new(
            wildCard  => $fileName[0],
            title     => 'Save File',
            inputName => '~F~ile Name',
            options   => fdOKButton,
            histId    => 1,
          );
          if ( $application->executeDialog( $fileDialog, \@fileName ) 
            != cmCancel
          ) {
            messageBox( "'$fileName[0]' was entered", mfOKButton );
          }
          last;
        };
        cmFileHelp == $_ and do {
          my @fileName = qw( *.* );
          my $fileDialog = TFileDialog->new(
            wildCard  => $fileName[0],
            title     => 'Open File',
            inputName => '~F~ile Name',
            options   => fdOKButton
                       | fdOpenButton
                       | fdHelpButton,
            histId    => 1,
          );
          if ( $application->executeDialog( $fileDialog, \@fileName ) 
            != cmCancel
          ) {
            messageBox( "'$fileName[0]' was entered", mfOKButton );
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
