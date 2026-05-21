=pod

=head1 NAME

Add a menu.

=head1 SEE ALSO

L<Lazarus-FreeVision-Tutorial|https://github.com/sechshelme/Lazarus-FreeVision-Tutorial/tree/master/02_-_Statuszeile_und_Menu/10_-_Menu>

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
  use_ok 'TUI::Views';
  use_ok 'TUI::Drivers';
  use_ok 'TUI::Objects';
  use_ok 'TUI::Menus';
  use_ok 'TUI::toolkit';
}

BEGIN {
  package TMyApp;

  # The same modules are used for the menu as for the status line.
  use TUI::App;      # TApplication
  use TUI::Views;    # Event (cmQuit)
  use TUI::Drivers;  # Hotkey
  use TUI::Objects;  # Window section (TRect)
  use TUI::Menus;    # Status line and menu
  use TUI::toolkit;

  extends TApplication;

  # We want to use a console resolution like MS DOS.
  sub BUILDARGS {
    my $args = shift->SUPER::BUILDARGS( @_ ) || return;
    $args->{bounds} = new_TRect( 0, 0, 80, 25 );
    return $args;
  }

  # For a menu, you must overwrite initMenuBar.
  sub initMenuBar {
    my ( $class, $r ) = @_;
    $r->{b}{y} = $r->{a}{y} + 1;
    return
      new_TMenuBar( $r, 
        new_TSubMenu( '~F~ile', hcNoContext ) + 
          new_TMenuItem( 'E~x~it', cmQuit, kbAltX, hcNoContext, 'Alt-X' )
      );
  }

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
