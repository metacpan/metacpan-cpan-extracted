use strict;
use warnings;

use Test::More;
use Test::Exception;

BEGIN {
  use_ok 'TUI::Objects::Point';
  use_ok 'TUI::Objects::Rect';
  use_ok 'TUI::Drivers::Const', qw( evMouseDown );
  use_ok 'TUI::Drivers::Event';
  use_ok 'TUI::Views::Const', qw( sfVisible );
  use_ok 'TUI::Views::Palette';
  use_ok 'TUI::Views::View';
}

BEGIN {
  package MyOwner;
  use TUI::toolkit;
  extends 'TUI::Views::View';
  my $toggle = 1;
  sub getEvent { 
    $toggle = 1 - $toggle; 
    $_[1]->{what} = 1 << 4 * $toggle; # $toogle ? evMouseDown : evKeyDown
  }
  $INC{"MyOwner.pm"} = 1;
}

use_ok 'MyOwner';

my $bounds = TRect->new( ax => 0, ay => 0, bx => 10, by => 10 );
isa_ok( $bounds, TRect );

my $owner = MyOwner->new( bounds => $bounds );
isa_ok( $owner, 'MyOwner' );

# Test the getPalette method
subtest 'getPalette method' => sub {
  my $view    = TView->new( bounds => $bounds );
  my $palette = $view->getPalette();
  isa_ok( $palette, TPalette, 'getPalette method returns a TPalette object' );
};

# Test the mapColor method
subtest 'mapColor method' => sub {
  my $view = TView->new( bounds => $bounds );
  is( $view->mapColor( 2 ), 2, 'mapColor method returns correct color' );
};

# Test the getColor method
subtest 'getColor method' => sub {
  my $view = TView->new( bounds => $bounds );
  is( 
    $view->getColor( 0x100 ), 
    ( 0x100 | $TUI::Views::View::errorAttr ),
    'getColor method returns correct color'
  );
};

# Test the getState method
subtest 'getState method' => sub {
  my $view = TView->new( bounds => $bounds );
  ok( $view->getState( sfVisible ), 'getState method returns true' );
};

# Test the select method
subtest 'select method' => sub {
  my $view = TView->new( bounds => $bounds );
  lives_ok { $view->select() }
    'select method executed without errors';
};

# Test the setState method
subtest 'setState method' => sub {
  my $view = TView->new( bounds => $bounds );
  $view->setState( sfVisible, 1 );
  ok( $view->{state} & sfVisible, 'state is set correctly after setState' );
};

# Test the keyEvent method
subtest 'keyEvent method' => sub {
  my $view  = TView->new( bounds => $bounds );
  my $event = TEvent->new();
  $view->owner( $owner );
  lives_ok { $view->keyEvent( $event ) }
    'keyEvent method executed without errors';
};

# Test the mouseEvent method
subtest 'mouseEvent method' => sub {
  my $view  = TView->new( bounds => $bounds );
  my $event = TEvent->new();
  $view->owner( $owner );
  ok( $view->mouseEvent( $event, evMouseDown ),
    'mouseEvent method returns true' );
};

# Test the makeGlobal method
subtest 'makeGlobal method' => sub {
  my $view   = TView->new( bounds => $bounds );
  my $point  = TPoint->new( x => 5, y => 10 );
  my $global = $view->makeGlobal( $point );
  isa_ok( $global, TPoint, 'makeGlobal method returns a TPoint object' );
  is( $global->{x}, 5,  'global.x is set correctly' );
  is( $global->{y}, 10, 'global.y is set correctly' );
};

# Test the makeLocal method
subtest 'makeLocal method' => sub {
  my $view  = TView->new( bounds => $bounds );
  my $point = TPoint->new( x => 5, y => 10 );
  my $local = $view->makeLocal( $point );
  isa_ok( $local, TPoint, 'makeLocal method returns a TPoint object' );
  is( $local->{x}, 5,  'local.x is set correctly' );
  is( $local->{y}, 10, 'local.y is set correctly' );
};

done_testing();
