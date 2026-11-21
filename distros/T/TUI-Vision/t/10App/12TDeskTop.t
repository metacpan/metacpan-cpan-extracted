use strict;
use warnings;

use Test::More;
use Test::Exception;

BEGIN {
  use_ok 'TUI::Drivers::Const', qw( evCommand evNothing );
  use_ok 'TUI::Drivers::Event';
  use_ok 'TUI::Objects::Rect';
  use_ok 'TUI::App::Background';
  use_ok 'TUI::App::DeskTop';
  use_ok 'TUI::Views::Const', qw( :cmXXXX );
}

# Test object creation
my $desktop = TDeskTop->new( bounds => TRect->new() );
isa_ok( $desktop, TDeskTop, 'Object is of class TDeskTop' );

# Test background field
isa_ok( $desktop->{background}, TBackground, 'Object is of class TBackground' );

# Test cascade method
can_ok( $desktop, 'cascade' );
lives_ok { $desktop->cascade( TRect->new() ) }
  'cascade works correctly';

# Test handleEvent method
can_ok( $desktop, 'handleEvent' );
my $event = TEvent->new();
lives_ok { $desktop->handleEvent( $event ) }
  'handleEvent works correctly';

# cmNext is handled and the event is cleared afterwards
my $nextEvent = TEvent->new(
  what    => evCommand,
  message => { command => cmNext },
);
lives_ok { $desktop->handleEvent( $nextEvent ) }
  'handleEvent handles cmNext';
is( $nextEvent->{what}, evNothing, 'handleEvent clears the cmNext event' );

# Test initBackground method
can_ok( $desktop, 'initBackground' );
my $background = TDeskTop->initBackground( TRect->new() );
isa_ok( $background, TBackground,
  'initBackground returns a TBackground object' );

# Test tile method
can_ok( $desktop, 'tile' );
lives_ok { $desktop->tile( TRect->new() ) }
  'tile works correctly';

# Test tileError method
can_ok( $desktop, 'tileError' );
lives_ok { $desktop->tileError() }
   'tileError works correctly';

# Test shutDown method
can_ok( $desktop, 'shutDown' );
lives_ok { $desktop->shutDown() }
  'shutDown works correctly';

done_testing();
