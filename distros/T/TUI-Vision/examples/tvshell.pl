package TShell;
use TUI::App;
use TUI::Views;
use TUI::Drivers;
use TUI::Menus;
use TUI::toolkit;

extends TApplication;

use constant cmRunProgram => 1000;

# Purpose: Defines the pulldown menus used in Shell
sub initMenuBar {
  my ( $class, $bounds ) = @_;
  $bounds->{b}{y} = $bounds->{a}{y} + 1;
  return new_TMenuBar( $bounds,
    new_TSubMenu( '~R~un', 0 ) +
      new_TMenuItem( '~R~un', cmRunProgram, 0, hcNoContext )
  );
}

# Purpose: Defines the status line that is displayed in the bottom line of 
# the screen within TShell
sub initStatusLine {
  my ( $class, $bounds ) = @_;
  $bounds->{a}{y} = $bounds->{b}{y} - 1;
  return new_TStatusLine( $bounds,
    new_TStatusDef( 0, 0xFFFF ) +
      new_TStatusItem( '',             kbF10,  cmMenu ) +
      new_TStatusItem( '~Alt-X~ Exit', kbAltX, cmQuit ) +
      new_TStatusItem( '~F2~ Copy',    kbF2,   cmCopy ) +
      new_TStatusItem( '~F3~ Close',   kbF3,   cmClose )
  );
}

package main;

# Create an instance of the TShell object
my $shell = TShell->new();
$shell->run();
