use strict;
use warnings;

use Test::More;
use Test::Exception;

# Mocking 'THardwareInfo', 'TMouse', and 'TScreen' for testing purposes
BEGIN {
  package TUI::Drivers::HardwareInfo;
  use Exporter 'import';
  our @EXPORT = qw( THardwareInfo );
  sub THardwareInfo (){ __PACKAGE__ }
  sub clearPendingEvent { }
  my $state;
  sub getMouseEvent {
    my ( $class, $event ) = @_;
    $state++;
    if ( $state == 1 ) {
      $event->{buttons}  = 0;
      $event->{where}{x} = 10;
      $event->{where}{y} = 10;
      return 1;
    } 
    elsif ( $state == 2 ) {
      $event->{buttons}  = 1;
      $event->{where}{x} = 10;
      $event->{where}{y} = 10;
      return 1;
    } 
    elsif ( $state == 3 ) {
      $event->{buttons}  = 0;
      $event->{where}{x} = 10;
      $event->{where}{y} = 10;
      return 1;
    } 
    elsif ( $state == 4 ) {
      $event->{buttons}  = 1;
      $event->{where}{x} = 20;
      $event->{where}{y} = 20;
      return 1;
    }
    elsif ( $state == 5 ) {
      $event->{buttons}  = 1;
      $event->{where}{x} = 25;
      $event->{where}{y} = 25;
      return 1;
    }
    return 0;
  } #/ sub getMouseEvent
  sub getTickCount { return 100; }
  $INC{"TUI/Drivers/HardwareInfo.pm"} = 1;
} #/ BEGIN

BEGIN {
  package TUI::Drivers::Mouse;
  use Exporter 'import';
  our @EXPORT = qw( TMouse );
  sub TMouse () { __PACKAGE__ }
  sub present   { return 1; }
  sub resume    { }
  sub suspend   { }
  sub getEvent  { }
  sub setRange  { }
  $INC{"TUI/Drivers/Mouse.pm"} = 1;
} #/ BEGIN

BEGIN {
  package TUI::Drivers::Screen;
  use Exporter 'import';
  our @EXPORT = qw( TScreen );
  sub TScreen ()   { __PACKAGE__ }
  our $screenWidth = 80;
  our $screenHeight = 25;
  TScreen->{screenWidth} = $screenWidth;
  TScreen->{screenHeight} = $screenHeight;
  $INC{"TUI/Drivers/Screen.pm"} = 1;
} #/ BEGIN

BEGIN {
  use_ok 'TUI::Drivers::Const', qw( :evXXXX );
  use_ok 'TUI::Drivers::Event';
  use_ok 'TUI::Drivers::EventQueue';
}

use_ok 'MouseEventType';

# Test object creation and resume method
my $event_queue = TEventQueue();
ok( $event_queue, 'TEventQueue exists' );

# Test resume method
can_ok( $event_queue, 'resume' );
lives_ok { $event_queue->resume() } 'resume method works correctly';

# Test suspend method
can_ok( $event_queue, 'suspend' );
lives_ok { $event_queue->suspend() } 'suspend method works correctly';

# Test getMouseEvent method
can_ok( $event_queue, 'getMouseEvent' );
my $event = TEvent->new();

$event_queue->getMouseEvent( $event );
is( $event->{what}, evNothing, 'TEvent initialized correctly' );

# Test mouse event handling
$event_queue->getMouseEvent( $event = TEvent->new() );
is( $event->{what}, evMouseAuto, 'Mouse auto event handled correctly' );

$event_queue->getMouseEvent( $event = TEvent->new() );
is( $event->{what}, evMouseUp, 'Mouse up event handled correctly' );

$event_queue->getMouseEvent( $event = TEvent->new() );
is( $event->{what}, evMouseDown, 'Mouse down event handled correctly' );

$event_queue->getMouseEvent( $event = TEvent->new() );
is( $event->{what}, evMouseMove, 'Mouse move event handled correctly' );

# Test some global variables
is(
  $TUI::Drivers::EventQueue::doubleDelay,
  8,
  'TEventQueue->{doubleDelay} is set correctly'
);
isa_ok( $TUI::Drivers::EventQueue::lastMouse, 'MouseEventType' );

done_testing();
