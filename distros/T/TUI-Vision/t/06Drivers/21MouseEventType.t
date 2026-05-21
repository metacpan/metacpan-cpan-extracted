use strict;
use warnings;

use Test::More;

BEGIN {
  use_ok 'TUI::Objects::Point';
  use_ok 'TUI::Drivers::Event';
}

use_ok 'MouseEventType';

# Test 1: Initialization of the structure
my $event = MouseEventType->new();
isa_ok( $event, 'MouseEventType', 'MouseEventType object created' );

# Test the creation of a new MouseEventType object with hash reference for 'where'
subtest 'new object creation with hash reference for where' => sub {
  my $event = MouseEventType->new(
    where           => { x => 5, y => 10 },
    eventFlags      => 1,
    controlKeyState => 2,
    buttons         => 3
  );
  isa_ok( $event,          'MouseEventType' );
  isa_ok( $event->{where}, TPoint );
  is( $event->{where}->{x},      5,  'where.x is set correctly' );
  is( $event->{where}->{y},      10, 'where.y is set correctly' );
  is( $event->{eventFlags},      1,  'eventFlags is set correctly' );
  is( $event->{controlKeyState}, 2,  'controlKeyState is set correctly' );
  is( $event->{buttons},         3,  'buttons is set correctly' );
}; #/ 'new object creation with hash reference for where' => sub

# Test the creation of a new MouseEventType object with array reference for 'where'
subtest 'new object creation with array reference for where' => sub {
  my $event = MouseEventType->new(
    where           => [ 5, 10 ],
    eventFlags      => 1,
    controlKeyState => 2,
    buttons         => 3
  );
  isa_ok( $event,          'MouseEventType' );
  isa_ok( $event->{where}, TPoint );
  is( $event->{where}->{x},      5,  'where.x is set correctly' );
  is( $event->{where}->{y},      10, 'where.y is set correctly' );
  is( $event->{eventFlags},      1,  'eventFlags is set correctly' );
  is( $event->{controlKeyState}, 2,  'controlKeyState is set correctly' );
  is( $event->{buttons},         3,  'buttons is set correctly' );
}; #/ 'new object creation with array reference for where' => sub

# Test the creation of a new MouseEventType object with default values
subtest 'new object creation with default values' => sub {
  my $event = MouseEventType->new();
  isa_ok( $event,          'MouseEventType' );
  isa_ok( $event->{where}, TPoint );
  is( $event->{where}->{x},      0, 'where.x is set to default value' );
  is( $event->{where}->{y},      0, 'where.y is set to default value' );
  is( $event->{eventFlags},      0, 'eventFlags is set to default value' );
  is( $event->{controlKeyState}, 0, 'controlKeyState is set to default value' );
  is( $event->{buttons},         0, 'buttons is set to default value' );
}; #/ 'new object creation with default values' => sub

# Test the clone method
subtest 'clone method' => sub {
  my $event = MouseEventType->new(
    where           => { x => 5, y => 10 },
    eventFlags      => 1,
    controlKeyState => 2,
    buttons         => 3
  );
  my $clone = $event->clone();
  isa_ok( $clone,          'MouseEventType' );
  isa_ok( $clone->{where}, TPoint );
  is( $clone->{where}->{x},      5,  'where.x is cloned correctly' );
  is( $clone->{where}->{y},      10, 'where.y is cloned correctly' );
  is( $clone->{eventFlags},      1,  'eventFlags is cloned correctly' );
  is( $clone->{controlKeyState}, 2,  'controlKeyState is cloned correctly' );
  is( $clone->{buttons},         3,  'buttons is cloned correctly' );
  isnt( $event, $clone, 'clone is a different object' );
  is_deeply( $event, $clone, 'clone has the same data as the original' );
}; #/ 'clone method' => sub

# Test 2: Setting and retrieving the x and y coordinates
$event->{where}->{x} = 100;
$event->{where}->{y} = 200;
is( $event->{where}->{x}, 100, 'x coordinate set correctly' );
is( $event->{where}->{y}, 200, 'y coordinate set correctly' );

# Test 3: Setting and retrieving the eventFlags
$event->{eventFlags} = 1;
is( $event->{eventFlags}, 1, 'eventFlags set correctly' );

# Test 4: Setting and retrieving the controlKeyState and buttons
$event->{controlKeyState} = 2;
$event->{buttons} = 3;
is( $event->{controlKeyState}, 2, 'controlKeyState set correctly' );
is( $event->{buttons},         3, 'buttons set correctly' );

done_testing();
