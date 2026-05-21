use strict;
use warnings;

use Test::More;
use Test::Exception;

BEGIN {
  use_ok 'TUI::Objects::Rect';
  use_ok 'TUI::Drivers::Const', qw(
    evKeyDown
    kbLeft
  );
  use_ok 'TUI::Drivers::Event';
  use_ok 'TUI::Views::Palette';
  use_ok 'TUI::Views::Group';
  use_ok 'TUI::Views::ScrollBar';
}

# Mocking TWindow for testing purposes
BEGIN {
  package MyWindow;
  use TUI::toolkit;
  extends 'TUI::Views::Group';
  has flags  => ( is => 'rw', default => sub { 0 } );
  has number => ( is => 'rw', default => sub { 0 } );
  sub getTitle { 'title' }
  $INC{"MyWindow.pm"} = 1;
}

use_ok 'MyWindow';

my (
  $bounds,
  $scrollBar,
  $owner,
);

# Test case for the constructor
subtest 'Test object creations' => sub {
  $bounds = TRect->new( ax => 0, ay => 0, bx => 10, by => 1 );
  isa_ok( $bounds, TRect, 'Object is of class TRect' );
  $scrollBar = TScrollBar->new( bounds => $bounds );
  isa_ok( $scrollBar, TScrollBar, 'TScrollBar object created' );
};

# Test case for the draw method
subtest 'draw' => sub {
  my $r  = TRect->new( ax => 0, ay => 0, bx => 20, by => 20 );
  $owner = MyWindow->new( bounds => $r );
  $owner->insertView( $scrollBar, undef );
  can_ok( $scrollBar, 'draw' );
  lives_ok { $scrollBar->draw() } 'TScrollBar draw method executed';
};

# Test case for the drawPos method
subtest 'drawPos' => sub {
  can_ok( $scrollBar, 'drawPos' );
  lives_ok { $scrollBar->drawPos( 5 ) } 'TScrollBar drawPos method executed';
};

# Test case for the getPalette method
subtest 'getPalette' => sub {
  can_ok( $scrollBar, 'getPalette' );
  my $palette = $scrollBar->getPalette();
  isa_ok( $palette, TPalette, 'Palette object returned' );
};

# Test case for the getPos method
subtest 'getPos' => sub {
  can_ok( $scrollBar, 'getPos' );
  my $pos;
  lives_ok { $pos = $scrollBar->getPos() } 'TScrollBar drawPos method executed';
  ok( defined $pos, 'Position returned' );
};

# Test case for the getSize method
subtest 'getSize' => sub {
  can_ok( $scrollBar, 'getSize' );
  my $size;
  lives_ok { $size = $scrollBar->getSize() }
    'TScrollBar getSize method executed';
  ok( defined $size, 'Size returned' );
};

# Test case for the handleEvent method
subtest 'handleEvent' => sub {
  my $event = TEvent->new( what => evKeyDown,
    keyDown => { keyCode => kbLeft }
  );
  can_ok( $scrollBar, 'handleEvent' );
  lives_ok { $scrollBar->handleEvent( $event ) } 
    'TScrollBar handleEvent method executed';
};

# Test case for the setParams method
subtest 'setParams' => sub {
  can_ok( $scrollBar, 'setParams' );
  lives_ok { $scrollBar->setParams( 5, 0, 10, 1, 1 ) }
    'TScrollBar setParams method executed';
};

# Test case for the setRange method
subtest 'setRange' => sub {
  can_ok( $scrollBar, 'setRange' );
  lives_ok { $scrollBar->setRange( 0, 10 ) }
    'TScrollBar setRange method executed';
};

# Test case for the setValue method
subtest 'setValue' => sub {
  can_ok( $scrollBar, 'setValue' );
  lives_ok { $scrollBar->setValue( 5 ) }
    'TScrollBar setValue method executed';
};

done_testing();
