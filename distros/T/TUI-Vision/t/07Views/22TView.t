use strict;
use warnings;

use Test::More;
use Test::Exception;

BEGIN {
  use_ok 'TUI::Objects::Rect';
  use_ok 'TUI::Drivers::Event';
  use_ok 'TUI::Views::Const', qw( :sfXXXX );
  use_ok 'TUI::Views::View';
}

BEGIN {
  package MyOwner;
  use TUI::Objects::Rect;
  use TUI::toolkit;
  extends 'TUI::Views::View';
  has last => ( is => 'rw' );
  has clip => ( is => 'rw', default => sub { TRect->new() } );

  sub drawSubViews { }
  $INC{"MyOwner.pm"} = 1;
}

use_ok 'MyOwner';

my $bounds = TRect->new( ax => 0, ay => 0, bx => 10, by => 10 );
isa_ok( $bounds, TRect );

my $owner = MyOwner->new( bounds => $bounds );
isa_ok( $owner, 'MyOwner' );

# Test the hide method
subtest 'hide method' => sub {
  my $view = TView->new( bounds => $bounds );
  $view->hide();
  ok( !( $view->{state} & sfVisible ), 'state is set correctly after hide' );
};

# Test the show method
subtest 'show method' => sub {
  my $view = TView->new( bounds => $bounds );
  $view->{state} &= ~sfVisible;
  $view->show();
  ok( $view->{state} & sfVisible, 'state is set correctly after show' );
};

# Test the draw method
subtest 'draw method' => sub {
  my $view = TView->new( bounds => $bounds );
  lives_ok { $view->draw() } 'draw method executed without errors';
};

# Test the drawView method
subtest 'drawView method' => sub {
  my $view = TView->new( bounds => $bounds );
  lives_ok { $view->drawView() } 'drawView method executed without errors';
};

# Test the exposed method
subtest 'exposed method' => sub {
  my $view = TView->new( bounds => $bounds );
  $view->{state} |= sfExposed;
  ok( $view->exposed(), 'exposed method returns true' );
};

# Test the focus method
subtest 'focus method' => sub {
  my $view = TView->new( bounds => $bounds );
  ok( $view->focus(), 'focus method returns true' );
};

# Test the hideCursor method
subtest 'hideCursor method' => sub {
  my $view = TView->new( bounds => $bounds );
  $view->hideCursor();
  ok( !( $view->{state} & sfCursorVis ),
    'state is set correctly after hideCursor' );
};

# Test the drawUnderRect method
subtest 'drawUnderRect method' => sub {
  my $view     = TView->new( bounds => $bounds );
  my $r        = TRect->new( ax => 0, ay => 0, bx => 5, by => 5 );
  my $lastView = TView->new( bounds => $bounds );
  $view->owner( $owner );
  lives_ok { $view->drawUnderRect( $r, $lastView ) }
    'drawUnderRect method executed without errors';
};

# Test the drawHide method
subtest 'drawHide method' => sub {
  my $view     = TView->new( bounds => $bounds );
  my $lastView = TView->new( bounds => $bounds );
  $view->owner( $owner );
  lives_ok { $view->drawHide( $lastView ) }
    'drawHide method executed without errors';
};

# Test the drawUnderView method
subtest 'drawUnderView method' => sub {
  my $view     = TView->new( bounds => $bounds );
  my $lastView = TView->new( bounds => $bounds );
  $view->owner( $owner );
  lives_ok { $view->drawUnderView( !!1, $lastView ) }
    'drawUnderView method executed without errors';
};

# Test the drawShow method
subtest 'drawShow method' => sub {
  my $view     = TView->new( bounds => $bounds );
  my $lastView = TView->new( bounds => $bounds );
  $view->owner( $owner );
  lives_ok { $view->drawShow( $lastView ) }
    'drawShow method executed without errors';
};

done_testing();
