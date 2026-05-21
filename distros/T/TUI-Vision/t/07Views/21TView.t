use strict;
use warnings;

use Test::More;

BEGIN {
  use_ok 'TUI::Const', qw( INT_MAX );
  use_ok 'TUI::Objects::Point';
  use_ok 'TUI::Objects::Rect';
  use_ok 'TUI::Drivers::Const', qw( :evXXXX );
  use_ok 'TUI::Drivers::Event';
  use_ok 'TUI::Views::Const', qw( 
    :dmXXXX
    :gfXXXX
    :hcXXXX
    :sfXXXX
  );
  use_ok 'TUI::Views::View';
}

my $bounds = TRect->new( ax => 0, ay => 0, bx => 10, by => 10 );
isa_ok( $bounds, TRect );

# Test the creation of a new TView object
subtest 'new object creation' => sub {
  my $view = TView->new( bounds => $bounds );
  isa_ok( $view,           TView );
  isa_ok( $view->{size},   TPoint );
  isa_ok( $view->{origin}, TPoint );
  isa_ok( $view->{cursor}, TPoint );
  is( $view->{state},    sfVisible,   'state is set correctly' );
  is( $view->{growMode}, 0,           'growMode is set correctly' );
  is( $view->{dragMode}, dmLimitLoY,  'dragMode is set correctly' );
  is( $view->{helpCtx},  hcNoContext, 'helpCtx is set correctly' );
  is(
    $view->{eventMask},
    evMouseDown | evKeyDown | evCommand,
    'eventMask is set correctly'
  );
}; #/ 'new object creation' => sub

# Test the sizeLimits method
subtest 'sizeLimits method' => sub {
  my $view = TView->new( bounds => TRect->new() );
  my $min  = TPoint->new();
  my $max  = TPoint->new();
  isa_ok( $view, TView );
  $view->sizeLimits( $min, $max );
  is( $min->{x}, 0,       'min.x is set correctly' );
  is( $min->{y}, 0,       'min.y is set correctly' );
  is( $max->{x}, INT_MAX, 'max.x is set correctly' );
  is( $max->{y}, INT_MAX, 'max.y is set correctly' );
}; #/ 'sizeLimits method' => sub

# Test the getBounds method
subtest 'getBounds method' => sub {
  my $view = TView->new( bounds => $bounds );
  my $rect = $view->getBounds();
  isa_ok( $rect, TRect );
  is( $rect->{a}{x}, 0,  'rect.a.x is set correctly' );
  is( $rect->{a}{y}, 0,  'rect.a.y is set correctly' );
  is( $rect->{b}{x}, 10, 'rect.b.x is set correctly' );
  is( $rect->{b}{y}, 10, 'rect.b.y is set correctly' );
}; #/ 'getBounds method' => sub

# Test the getExtent method
subtest 'getExtent method' => sub {
  my $view = TView->new( bounds => $bounds );
  my $rect = $view->getExtent();
  isa_ok( $rect, TRect );
  is( $rect->{a}{x}, 0,  'rect.a.x is set correctly' );
  is( $rect->{a}{y}, 0,  'rect.a.y is set correctly' );
  is( $rect->{b}{x}, 10, 'rect.b.x is set correctly' );
  is( $rect->{b}{y}, 10, 'rect.b.y is set correctly' );
}; #/ 'getExtent method' => sub

# Test the getClipRect method
subtest 'getClipRect method' => sub {
  my $view = TView->new( bounds => $bounds );
  my $clip = $view->getClipRect();
  isa_ok( $clip, TRect );
  is( $clip->{a}{x}, 0,  'clip.a.x is set correctly' );
  is( $clip->{a}{y}, 0,  'clip.a.y is set correctly' );
  is( $clip->{b}{x}, 10, 'clip.b.x is set correctly' );
  is( $clip->{b}{y}, 10, 'clip.b.y is set correctly' );
}; #/ 'getClipRect method' => sub

# Test the mouseInView method
subtest 'mouseInView method' => sub {
  my $view  = TView->new( bounds => $bounds );
  my $mouse = TPoint->new( x => 5, y => 5 );
  ok( $view->mouseInView( $mouse ), 'mouse is in view' );
  $mouse = TPoint->new( x => 15, y => 15 );
  ok( !$view->mouseInView( $mouse ), 'mouse is not in view' );
};

# Test the containsMouse method
subtest 'containsMouse method' => sub {
  my $view  = TView->new( bounds => $bounds );
  my $event = TEvent->new( what => evMouse,
    mouse => { where => TPoint->new( x => 5, y => 5 ) } );
  ok( $view->containsMouse( $event ), 'mouse is contained in view' );
  $event = TEvent->new( what => evMouse,
    mouse => { where => TPoint->new( x => 15, y => 15 ) } );
  ok( !$view->containsMouse( $event ), 'mouse is not contained in view' );
}; #/ 'containsMouse method' => sub

# Test the locate method
subtest 'locate method' => sub {
  my $view       = TView->new( bounds => $bounds );
  my $new_bounds = TRect->new( ax => 5, ay => 5, bx => 15, by => 15 );
  $view->locate( $new_bounds );
  my $rect = $view->getBounds();
  is( $rect->{a}{x}, 5,  'rect.a.x is set correctly after locate' );
  is( $rect->{a}{y}, 5,  'rect.a.y is set correctly after locate' );
  is( $rect->{b}{x}, 15, 'rect.b.x is set correctly after locate' );
  is( $rect->{b}{y}, 15, 'rect.b.y is set correctly after locate' );
}; #/ 'locate method' => sub

# Test the calcBounds method
subtest 'calcBounds method' => sub {
  my $view  = TView->new( bounds => $bounds );
  my $new_bounds = TRect->new( ax => 0, ay => 0, bx => 20, by => 20 );
  my $owner = TView->new( bounds => $new_bounds );
  $view->owner( $owner );
  $view->{growMode} = gfGrowAll;
  my $delta = TPoint->new( x => 5, y => 5 );
  $view->calcBounds( $new_bounds, $delta );
  is( $new_bounds->{b}{x}, 15, 'bounds.b.x is set correctly after calcBounds' );
  is( $new_bounds->{b}{y}, 15, 'bounds.b.y is set correctly after calcBounds' );
};

# Test the changeBounds method
subtest 'changeBounds method' => sub {
  my $view       = TView->new( bounds => $bounds );
  my $new_bounds = TRect->new( ax => 5, ay => 5, bx => 15, by => 15 );
  $view->changeBounds( $new_bounds );
  my $rect = $view->getBounds();
  is( $rect->{a}{x}, 5,  'rect.a.x is set correctly after changeBounds' );
  is( $rect->{a}{y}, 5,  'rect.a.y is set correctly after changeBounds' );
  is( $rect->{b}{x}, 15, 'rect.b.x is set correctly after changeBounds' );
  is( $rect->{b}{y}, 15, 'rect.b.y is set correctly after changeBounds' );
}; #/ 'changeBounds method' => sub

# Test the growTo method
subtest 'growTo method' => sub {
  my $view = TView->new( bounds => $bounds );
  $view->growTo( 15, 15 );
  my $rect = $view->getBounds();
  is( $rect->{b}{x}, 15, 'rect.b.x is set correctly after growTo' );
  is( $rect->{b}{y}, 15, 'rect.b.y is set correctly after growTo' );
};

# Test the moveTo method
subtest 'moveTo method' => sub {
  my $view = TView->new( bounds => $bounds );
  $view->moveTo( 5, 5 );
  my $rect = $view->getBounds();
  is( $rect->{a}{x}, 5,  'rect.a.x is set correctly after moveTo' );
  is( $rect->{a}{y}, 5,  'rect.a.y is set correctly after moveTo' );
  is( $rect->{b}{x}, 15, 'rect.b.x is set correctly after moveTo' );
  is( $rect->{b}{y}, 15, 'rect.b.y is set correctly after moveTo' );
}; #/ 'moveTo method' => sub

# Test the setBounds method
subtest 'setBounds method' => sub {
  my $view       = TView->new( bounds => $bounds );
  my $new_bounds = TRect->new( ax => 5, ay => 5, bx => 15, by => 15 );
  isa_ok( $new_bounds, TRect );
  $view->setBounds( $new_bounds );
  my $rect = $view->getBounds();
  is( $rect->{a}{x}, 5,  'rect.a.x is set correctly after setBounds' );
  is( $rect->{a}{y}, 5,  'rect.a.y is set correctly after setBounds' );
  is( $rect->{b}{x}, 15, 'rect.b.x is set correctly after setBounds' );
  is( $rect->{b}{y}, 15, 'rect.b.y is set correctly after setBounds' );
}; #/ 'setBounds method' => sub

# Test the getHelpCtx method
subtest 'getHelpCtx method' => sub {
  my $view = TView->new( bounds => $bounds );
  is( $view->getHelpCtx(), hcNoContext, 'helpCtx is set correctly' );
  $view->{state} |= sfDragging;
  is( $view->getHelpCtx(), hcDragging,
    'helpCtx is set correctly when dragging' );
};

# Test the valid method
subtest 'valid method' => sub {
  my $view = TView->new( bounds => $bounds );
  ok( $view->valid( 0 ), 'valid method returns true' );
};

done_testing();
