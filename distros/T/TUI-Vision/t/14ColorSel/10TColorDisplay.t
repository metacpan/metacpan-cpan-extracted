use strict;
use warnings;

use Test::More;
use Test::Exception;

BEGIN {
  use_ok 'TUI::Objects::Rect';
  use_ok 'TUI::Drivers::Const', qw( evBroadcast );
  use_ok 'TUI::Drivers::Event';
  use_ok 'TUI::Drivers::ColorAttr';
  use_ok 'TUI::ColorSel::Const', qw( :cmXXXX );
  use_ok 'TUI::ColorSel::ColorDisplay';
}

{
  package MyColorDisplay;

  use TUI::toolkit;
  extends 'TUI::ColorSel::ColorDisplay';

  sub drawView  { ::pass 'drawView()' }
  sub writeLine { ::pass 'writeLine()' }

  $INC{'MyColorDisplay.pm'} = 1;
}

my $view;
subtest 'TColorDisplay->new()' => sub {
  require_ok 'MyColorDisplay';
  $view = MyColorDisplay->new(
    bounds => TRect->new(),
    text   => 'Color'
  );
  isa_ok( $view, TColorDisplay );
  is( $view->{text}, 'Color', 'text initialized' );
  is( ref $view->{color}, 'SCALAR', 'color initialized as a scalar reference' );
};

subtest 'draw()' => sub {
  can_ok( $view, 'draw' );
  lives_ok { $view->draw() } 'draw() does not die';
};

subtest 'setColor()' => sub {
  can_ok( $view, 'setColor' );
  my $color = 0x1E;
  lives_ok { $view->setColor( \$color ) } 'setColor() does not die';
  is( ${ $view->{color} }, 0x1E, 'color reference updated' );
};

subtest 'handleEvent() foreground' => sub {
  can_ok( $view, 'handleEvent' );
  my $color = 0x17;
  $view->setColor( \$color );
  my $event = TEvent->new(
    what    => evBroadcast,
    message => {
      command  => cmColorForegroundChanged,
      infoByte => 0x0A,
    },
  );
  lives_ok { $view->handleEvent( $event ) } 'foreground event does not die';
  is( $color, 0x1A, 'foreground changed in the referenced scalar' );
};

subtest 'handleEvent() background' => sub {
  my $color = 0x17;
  $view->setColor( \$color );
  my $event = TEvent->new(
    what    => evBroadcast,
    message => {
      command  => cmColorBackgroundChanged,
      infoByte => 0x03,
    },
  );
  lives_ok { $view->handleEvent( $event ) } 'background event does not die';
  is( $color, 0x37, 'background changed in the referenced scalar' );
};

done_testing();
