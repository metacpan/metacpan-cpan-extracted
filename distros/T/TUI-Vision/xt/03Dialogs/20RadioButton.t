=pod

=head1 NAME

Add radio buttons to the dialog.

=head1 SEE ALSO

L<Lazarus-FreeVision-Tutorial|https://github.com/sechshelme/Lazarus-FreeVision-Tutorial/tree/master/03_-_Dialoge/10_-_Button>

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

  use TUI::App;        # TApplication
  use TUI::Objects;    # Window section (TRect)
  use TUI::Drivers;    # Hotkey
  use TUI::Views;      # Event (cmQuit)
  use TUI::Menus;      # Status line and menu
  use TUI::Dialogs;    # Dialogs
  use TUI::toolkit;

  use constant {
    cmAbout => 1001,    # Display About
    cmList  => 1002,    # File list
    cmPara  => 1003,    # Parameters
  };
  
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
          new_TStatusItem( '~F1~ Help', kbF1, cmHelp )
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
          $self->myParameter();
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

  # Add RadioButton to the dialog; this works almost the same as with 
  # checkboxes.
  sub myParameter {
    my $self = shift;
    my $r    = new_TRect( 0, 0, 35, 15 );
    $r->move( 23, 3 );
    my $dlg = new_TDialog( $r, 'Parameter' );
    WITH: for ( $dlg ) {
      # CheckBoxes
      $r->assign( 2, 3, 18, 7 );
      my $view = new_TCheckBoxes($r,
        new_TSItem('~F~ile',
        new_TSItem('~L~ine',
        new_TSItem('D~a~te',
        new_TSItem('~T~ime',
        undef))))
      );
      $_->insert( $view );

      # RadioButtons
      $r->assign( 21, 3, 33, 6 );
      $view = new_TRadioButtons($r,
        new_TSItem('~B~ig',
        new_TSItem('~M~ediun',
        new_TSItem('~S~mall',
        undef)))
      );
      $_->insert( $view );

      # Ok-Button
      $r->assign( 7, 12, 17, 14 );
      $_->insert( new_TButton( $r, '~O~K', cmOK, bfDefault ) );

      # Close-Button
      $r->move( 12, 0 );
      $_->insert( new_TButton( $r, '~C~ancel', cmCancel, bfNormal ) );
    }
    my $dummy = $deskTop->execView( $dlg );      # Open dialog modal
    # Dialog and memory are automatically released.
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
