use strict;
use warnings;

use Test::More;
use Test::Exception;

BEGIN {
  use_ok 'TUI::Objects::Point';
  use_ok 'TUI::Objects::Rect';
  use_ok 'TUI::Drivers::Const', qw( evMessage );
  use_ok 'TUI::Drivers::Event';
  use_ok 'TUI::Views::Const', qw(
    cmClose
    sbVertical
    sfActive
  );
  use_ok 'TUI::Views::Palette';
  use_ok 'TUI::Views::ScrollBar';
  use_ok 'TUI::Views::Window';
}

my (
  $bounds,
  $window,
);

# Test case for the constructor
subtest 'Test object creations' => sub {
  $bounds = TRect->new( ax => 0, ay => 0, bx => 10, by => 10 );
  $window = TWindow->new( 
    bounds => $bounds, title => "Test Window", number => 1
  );
  isa_ok( $window, TWindow, 'TWindow object created' );
};

# Test case for the close method
subtest 'close' => sub {
  my $window = TWindow->new( 
    bounds => $bounds, title => "Title", number => 2
  );
  can_ok( $window, 'close' );
  lives_ok { $window->close() } 'TWindow close method executed';
  ok ( !$window, 'TWindow is undefined' );
};

# Test case for the shutDown method
subtest 'shutDown' => sub {
  my $window = TWindow->new(
    bounds => $bounds, title => "Title", number => 3
  );
  can_ok( $window, 'shutDown' );
  lives_ok { $window->shutDown() } 'TWindow shutDown method executed';
};

# Test case for the getPalette method
subtest 'getPalette' => sub {
  can_ok( $window, 'getPalette' );
  my $palette = $window->getPalette();
  isa_ok( $palette, TPalette, 'Palette object returned' );
};

# Test case for the getTitle method
subtest 'getTitle' => sub {
  can_ok( $window, 'getTitle' );
  my $title = $window->getTitle( 10 );
  is( $title, "Test Window", 'Title returned correctly' );
};

# Test case for the handleEvent method
subtest 'handleEvent' => sub {
  my $window = TWindow->new( 
    bounds => $bounds, title => "Title", number => 2
  );
  my $event = TEvent->new( what => evMessage,
    message => { command => cmClose, infoPtr => $window }
  );
  can_ok( $window, 'handleEvent' );
  lives_ok { $window->handleEvent( $event ) }
    'TWindow handleEvent method executed';
};

# Test case for the setState method
subtest 'setState' => sub {
  can_ok( $window, 'setState' );
  lives_ok { $window->setState( sfActive, 1 ) }
    'TWindow setState method executed';
};

# Test case for the standardScrollBar method
subtest 'standardScrollBar' => sub {
  can_ok( $window, 'standardScrollBar' );
  my $scrollBar = $window->standardScrollBar( sbVertical );
  isa_ok( $scrollBar, TScrollBar, 'Standard scroll bar created' );
};

# Test case for the sizeLimits method
subtest 'sizeLimits' => sub {
  can_ok( $window, 'sizeLimits' );
  my ( $min, $max ) = ( TPoint->new(), TPoint->new() );
  lives_ok { $window->sizeLimits( $min, $max ) }
    'TWindow sizeLimits method executed';
};

# Test case for the zoom method
subtest 'zoom' => sub {
  can_ok( $window, 'zoom' );
  lives_ok { $window->zoom() }
    'TWindow zoom method executed';
};

done_testing();
