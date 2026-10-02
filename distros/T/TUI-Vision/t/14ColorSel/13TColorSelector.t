use strict;
use warnings;

use Test::More;
use Test::Exception;

BEGIN {
  use_ok 'TUI::Objects::Rect';
  use_ok 'TUI::Drivers::Const', qw(
    :evXXXX 
    kbLeft
    kbRight
    kbUp
    kbDown 
  );
  use_ok 'TUI::Drivers::Event';
  use_ok 'TUI::ColorSel::Const', qw(
    cmColorSet
    csForeground
    csBackground 
  );
  use_ok 'TUI::ColorSel::ColorSelector';
}

{
  package MyColorSelector;

  use TUI::toolkit;
  extends 'TUI::ColorSel::ColorSelector';

  sub drawView  { ::pass 'drawView()' }
  sub writeLine { ::pass 'writeLine()' }

  $INC{'MyColorSelector.pm'} = 1;
}

my $view;
subtest 'TColorSelector->new()' => sub {
 require_ok 'MyColorSelector';

  $view = MyColorSelector->new(
    bounds  => TRect->new(),
    selType => csForeground,
  );

  isa_ok( $view, TColorSelector );
  is( $view->{color}, 0, 'initial color' );
  is( $view->{selType}, csForeground, 'selection type' );
};

subtest 'draw()' => sub {
  can_ok( $view, 'draw' );
  lives_ok { $view->draw() } 'draw() does not die';
};

subtest 'broadcast cmColorSet foreground' => sub {
  my $event = TEvent->new(
    what    => evBroadcast,
    message => {
      command  => cmColorSet,
      infoByte => 0x3A,
    },
  );

  lives_ok { $view->handleEvent( $event ) };
  is( $view->{color}, 0x0A, 'foreground nibble selected' );
};

subtest 'broadcast cmColorSet background' => sub {
  my $bg = MyColorSelector->new(
    bounds  => TRect->new(),
    selType => csBackground,
  );
  my $event = TEvent->new(
    what    => evBroadcast,
    message => {
      command  => cmColorSet,
      infoByte => 0x3A,
    },
  );

  lives_ok { $bg->handleEvent( $event ) };
  is( $bg->{color}, 0x03, 'background nibble selected' );
};

subtest 'keyboard left wraps' => sub {
  $view->{color} = 0;
  my $event = TEvent->new(
    what    => evKeyDown,
    keyDown => {
      keyCode => kbLeft,
    },
  );

  lives_ok { $view->handleEvent( $event ) };
  is( $view->{color}, 15, 'left wraps to last color' );
};

subtest 'keyboard right wraps' => sub {
  $view->{color} = 15;
  my $event = TEvent->new(
    what    => evKeyDown,
    keyDown => {
      keyCode => kbRight,
    },
  );

  lives_ok { $view->handleEvent( $event ) };
  is( $view->{color}, 0, 'right wraps to first color' );
};

subtest 'keyboard up wraps' => sub {
  $view->{color} = 0;
  my $event = TEvent->new(
    what    => evKeyDown,
    keyDown => {
      keyCode => kbUp,
    },
  );

  lives_ok { $view->handleEvent( $event ) };
  is( $view->{color}, 15, 'up wraps' );
};

subtest 'keyboard down wraps' => sub {
  $view->{color} = 15;
  my $event = TEvent->new(
    what    => evKeyDown,
    keyDown => {
      keyCode => kbDown,
    },
  );

  lives_ok { $view->handleEvent( $event ) };
  is( $view->{color}, 0, 'down wraps' );
};

done_testing();
