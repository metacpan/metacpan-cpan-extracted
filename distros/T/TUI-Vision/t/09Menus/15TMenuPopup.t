use strict;
use warnings;

use Test::More;

BEGIN {
  use_ok 'TUI::Drivers::Event';
  use_ok 'TUI::Drivers::Util', qw( getAltCode getCtrlCode );
  use_ok 'TUI::Menus';
  use_ok 'TUI::Objects::Rect';
  use_ok 'TUI::Drivers::Const', qw( evKeyDown evNothing );
}

BEGIN {
  package MyMenuPopup;
  use TUI::toolkit;
  extends 'TUI::Menus::MenuPopup';
  our @commands;
  sub putEvent {
    push @commands, $_[1]{message}{command};
    return;
  }
  $INC{"MyMenuPopup.pm"} = 1;
}

my $menu = new_TMenu( new_TMenuItem( '~A~ction', 300, 0 ) );
my $popup = MyMenuPopup->new(
  bounds => TRect->new( ax => 0, ay => 0, bx => 20, by => 5 ),
  menu   => $menu,
);

isa_ok( $popup, TMenuPopup );

my $event = TEvent->new();
$event->{what} = evKeyDown;
$event->{keyDown}{keyCode} = getCtrlCode( 'A' );
$popup->handleEvent( $event );
is_deeply( 
  \@MyMenuPopup::commands, 
  [ 300 ], 
  'Ctrl mnemonic dispatches its command'
);
is( $event->{what}, evNothing, 'Ctrl mnemonic is consumed' );

$event = TEvent->new();
$event->{what} = evKeyDown;
$event->{keyDown}{keyCode} = getAltCode( 'Z' );
$popup->handleEvent( $event );
is( 
  scalar @MyMenuPopup::commands, 
  1, 
  'unmatched Alt key does not dispatch a command'
);
is( $event->{what}, evNothing, 'unmatched Alt key is consumed' );

done_testing();
