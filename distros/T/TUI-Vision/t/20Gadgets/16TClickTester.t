use strict;
use warnings;

use Test::More;
use Test::Exception;

BEGIN {
  use_ok 'TUI::Objects::Rect';
  use_ok 'TUI::Drivers::Const', qw(
    evMouseDown
    meDoubleClick
  );
  use_ok 'TUI::Drivers::Event';
  use_ok 'TUI::Gadgets::Const', qw( cpMousePalette );
  use_ok 'TUI::Gadgets::ClickTester';
  use_ok 'TUI::Views::Palette';
}

my $obj;
subtest 'constructor' => sub {
  $obj = TClickTester->new(
    bounds => TRect->new( ax => 0, ay => 0, bx => 10, by => 1 ),
    text => 'Click me'
  );
  isa_ok( $obj, TClickTester );
  ok( !$obj->{clicked}, 'initially not clicked' );
};

subtest 'getPalette' => sub {
  my $p = $obj->getPalette();
  isa_ok( $p, TPalette );
  is( $p->[0], length( cpMousePalette() ), 'cpMousePalette length matched' );
};

subtest 'double click toggles state' => sub {
  my $event = TEvent->new(
    what  => evMouseDown,
    mouse => {
      eventFlags => meDoubleClick,
    },
  );

  ok( !$obj->{clicked}, 'initial state' );
  $obj->handleEvent( $event );
  ok( $obj->{clicked}, 'double click' );
};

done_testing();
