use strict;
use warnings;

use Test::More;

BEGIN {
  use_ok 'TUI::Objects::Rect';
  use_ok 'TUI::Objects::Point';
  use_ok 'TUI::Drivers::Const', qw(
    evKeyboard
    evMouseDown
    kbDown
    kbUp
  );
  use_ok 'TUI::Drivers::Event';
  use_ok 'TUI::Gadgets::CalendarView';
  use_ok 'TUI::Gadgets::CalendarWindow';
  use_ok 'TUI::Views::Const', qw( ofSelectable sfSelected wfGrow wfZoom );
}

sub key_event {
  my ( $code ) = @_;
  return TEvent->new(
    what    => evKeyboard,
    keyDown => { keyCode => $code },
  );
}

sub mouse_event {
  my ( $x, $y ) = @_;
  return TEvent->new(
    what  => evMouseDown,
    mouse => { where => TPoint->new( x => $x, y => $y ) },
  );
}

my $calendar;

subtest 'constructor' => sub {
  my @now = localtime;
  $calendar = TCalendarView->new( 
    bounds => TRect->new( ax => 0, ay => 0, bx => 22, by => 9 )
  );
  isa_ok( $calendar, TCalendarView );
  $calendar->{state} |= sfSelected;
  ok( $calendar->{options} & ofSelectable, 'selectable' );
  is( $calendar->{curYear}, $now[5] + 1900, 'current year' );
  is( $calendar->{curMonth}, $now[4] + 1, 'current month' );
  is( $calendar->{curDay}, $now[3], 'current day' );
  is(
    $calendar->{month}, 
    $calendar->{curMonth}, 
    'starts with the current month' 
  );
};

subtest 'plus and minus change the month' => sub {
  $calendar->{month} = 5;
  $calendar->{year}  = 2030;

  $calendar->handleEvent( key_event( ord '+' ) );
  is_deeply(
    [ $calendar->{year}, $calendar->{month} ], 
    [ 2030, 6 ], 
    '+ advances'
  );
  $calendar->handleEvent( key_event( ord '-' ) );
  $calendar->handleEvent( key_event( ord '-' ) );
  is_deeply(
    [ $calendar->{year}, $calendar->{month} ],
    [ 2030, 4 ],
    '- goes back'
  );
};

subtest 'cursor keys change the month' => sub {
  $calendar->{month} = 5;
  $calendar->{year}  = 2030;

  $calendar->handleEvent( key_event( kbDown ) );
  is( $calendar->{month}, 6, 'kbDown advances' );

  $calendar->handleEvent( key_event( kbUp ) );
  $calendar->handleEvent( key_event( kbUp ) );
  is( $calendar->{month}, 4, 'kbUp goes back' );
};

subtest 'month wraps into the adjacent year' => sub {
  $calendar->{month} = 12;
  $calendar->{year}  = 2030;
  $calendar->handleEvent( key_event( ord '+' ) );
  is_deeply( [ $calendar->{year}, $calendar->{month} ], [ 2031, 1 ],
    'December advances to January of the next year' );

  $calendar->handleEvent( key_event( ord '-' ) );
  is_deeply( [ $calendar->{year}, $calendar->{month} ], [ 2030, 12 ],
    'January goes back to December of the previous year' );
};

subtest 'other keys and unselected views do not change the month' => sub {
  $calendar->{month} = 5;
  $calendar->handleEvent( key_event( ord 'x' ) );
  is( $calendar->{month}, 5, 'other keys are ignored' );

  $calendar->{state} &= ~sfSelected;
  $calendar->handleEvent( key_event( ord '+' ) );
  is( $calendar->{month}, 5, 'unselected view ignores keys' );
  $calendar->{state} |= sfSelected;
};

subtest 'mouse clicks on the header arrows change the month' => sub {
  $calendar->{month} = 5;
  $calendar->{year}  = 2030;

  $calendar->handleEvent( mouse_event( 15, 0 ) );
  is( $calendar->{month}, 6, 'click at x=15 advances' );

  $calendar->handleEvent( mouse_event( 18, 0 ) );
  is( $calendar->{month}, 5, 'click at x=18 goes back' );

  $calendar->handleEvent( mouse_event( 16, 0 ) );
  is( $calendar->{month}, 5, 'click elsewhere is ignored' );
};

subtest 'TCalendarWindow contains a calendar view' => sub {
  my $window = TCalendarWindow->new();
  isa_ok( $window, TCalendarWindow );
  ok( !( $window->{flags} & ( wfGrow | wfZoom ) ), 'not growable or zoomable' );
  my $view = $window->firstThat( sub { $_[0]->isa( TCalendarView ) } );
  isa_ok( $view, TCalendarView );
};

done_testing();
