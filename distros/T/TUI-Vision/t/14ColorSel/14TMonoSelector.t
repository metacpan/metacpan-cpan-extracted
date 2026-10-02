use strict;
use warnings;

use Test::More;
use Test::Exception;

BEGIN {
  use_ok 'TUI::Objects::Rect';
  use_ok 'TUI::Objects::StringCollection';
  use_ok 'TUI::Drivers::Const', qw( evBroadcast );
  use_ok 'TUI::Drivers::Event';
  use_ok 'TUI::ColorSel::Const', qw( cmColorSet );
  use_ok 'TUI::ColorSel::MonoSelector';
}

# Mock class for testing purposes
{
  package MyMonoSelector;
  use TUI::toolkit;
  extends 'TUI::ColorSel::MonoSelector';
  sub drawView { ::pass 'drawView()' }
  $INC{'MyMonoSelector.pm'} = 1;
}

my ( $bounds, $sel );

subtest 'Object creation' => sub {
  require_ok 'MyMonoSelector';
  $bounds = TRect->new( ax => 0, ay => 0, bx => 20, by => 5 );

  lives_ok {
    $sel = MyMonoSelector->new( bounds => $bounds );
  } 'constructor does not die';
  isa_ok( $sel, TMonoSelector );
};

subtest 'Initial state' => sub {
  ok( exists $sel->{value}, 'value exists' );
  is( $sel->{value}, 0, 'initial value is 0' );
  ok( defined $sel->{strings}, 'strings list created' );
  can_ok( $sel->{strings}, 'getCount' );
  is ( $sel->{strings}->getCount(), 4, 'strings list has 4 items' );
};

subtest 'draw()' => sub {
  can_ok( $sel, 'draw' );
  lives_ok { $sel->draw() } 'draw() does not die';
};

subtest 'mark()' => sub {
  $sel->{value} = 0x07;
  ok( $sel->mark(0), 'Normal is selected' );
  ok( !$sel->mark(1), 'Highlight is not selected' );
};

subtest 'press()' => sub {
  lives_ok { $sel->press(1) } 'press() does not die';
  is( $sel->{value}, 0x0f, 'Highlight attribute selected' );
  ok( $sel->mark(1), 'Highlight is marked' );
};

subtest 'movedTo()' => sub {
  lives_ok { $sel->movedTo(3) } 'movedTo() does not die';
  is( $sel->{value}, 0x70, 'Inverse attribute selected' );
  ok( $sel->mark(3), 'Inverse is marked' );
};

subtest 'handleEvent(cmColorSet)' => sub {
  my $event = TEvent->new(
    what => evBroadcast,
    message => {
      command  => cmColorSet,
      infoByte => 0x0f,
    },
  );
  lives_ok { $sel->handleEvent( $event ) } 'handleEvent() does not die';
  is( $sel->{value}, 0x0f, 'value updated from broadcast' );
};

done_testing();
