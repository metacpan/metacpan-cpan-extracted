use strict;
use warnings;

use Test::More;
use Test::Exception;

BEGIN {
  use_ok 'TUI::Objects::Rect';
  use_ok 'TUI::Views::Const', qw( :sfXXXX  );
  use_ok 'TUI::Views::View';
}

my $bounds = TRect->new( ax => 0, ay => 0, bx => 10, by => 10 );
isa_ok( $bounds, TRect );

# Test the dataSize method
subtest 'dataSize method' => sub {
  my $view = TView->new( bounds => $bounds );
  is( $view->dataSize(), 0, 'dataSize method returns 0' );
};

# Test the getData method
subtest 'getData method' => sub {
  my $view = TView->new( bounds => $bounds );
  my $rec = [];
  lives_ok { $view->getData( $rec ) } 'getData method executed without errors';
};

# Test the setData method
subtest 'setData method' => sub {
  my $view = TView->new( bounds => $bounds );
  my $rec = [];
  lives_ok { $view->setData( $rec ) } 'setData method executed without errors';
};

# Test the awaken method
subtest 'awaken method' => sub {
  my $view = TView->new( bounds => $bounds );
  lives_ok { $view->awaken() } 'awaken method executed without errors';
};

# Test the blockCursor method
subtest 'blockCursor method' => sub {
  my $view = TView->new( bounds => $bounds );
  $view->blockCursor();
  ok(
    $view->{state} & sfCursorIns,
    'state is set correctly after blockCursor'
  );
};

# Test the normalCursor method
subtest 'normalCursor method' => sub {
  my $view = TView->new( bounds => $bounds );
  $view->normalCursor();
  ok(
    !( $view->{state} & sfCursorIns ),
    'state is set correctly after normalCursor'
  );
};

# Test the resetCursor method
subtest 'resetCursor method' => sub {
  my $view = TView->new( bounds => $bounds );
  lives_ok { $view->resetCursor() }
   'resetCursor method executed without errors';
};

# Test the setCursor method
subtest 'setCursor method' => sub {
  my $view = TView->new( bounds => $bounds );
  $view->setCursor( 5, 10 );
  is( $view->{cursor}{x}, 5,  'cursor.x is set correctly' );
  is( $view->{cursor}{y}, 10, 'cursor.y is set correctly' );
};

# Test the showCursor method
subtest 'showCursor method' => sub {
  my $view = TView->new( bounds => $bounds );
  $view->showCursor();
  ok( 
    $view->{state} & sfCursorVis, 
    'state is set correctly after showCursor' 
  );
};

# Test the drawCursor method
subtest 'drawCursor method' => sub {
  my $view = TView->new( bounds => $bounds );
  $view->{state} |= sfFocused;
  lives_ok { $view->drawCursor() }
    'drawCursor method executed without errors';
};

done_testing();
