use strict;
use warnings;

use Test::More;
use Storable qw( freeze thaw );

BEGIN {
  use_ok 'TUI::Objects::Point';
  use_ok 'TUI::Objects::Rect';
  use_ok 'TUI::Views::Const', qw( :sfXXXX normalSelect );
  use_ok 'TUI::Views::View';
  use_ok 'TUI::Views::Group';
  use_ok 'TUI::Views::Frame';
  use_ok 'TUI::Views::Window';
  use_ok 'TUI::Views::Scroller';
  use_ok 'TUI::Views::ScrollBar';
  use_ok 'TUI::Views::ListViewer';
}

subtest 'TView Storable roundtrip' => sub {
  my $view = TUI::Views::View->new(
    bounds => TRect->new( ax => 3, ay => 4, bx => 23, by => 14 ) );
  $view->{cursor}   = TPoint->new( x => 5, y => 6 );
  $view->{growMode} = 7;
  $view->{dragMode} = 8;
  $view->{helpCtx}  = 9;
  $view->{state} =
    sfVisible | sfShadow | sfActive | sfSelected | sfFocused | sfExposed;
  $view->{options}   = 10;
  $view->{eventMask} = 11;
  $view->owner( TUI::Views::View->new( bounds => TRect->new() ) );
  $view->next( TUI::Views::View->new( bounds => TRect->new() ) );

  my $restored = thaw( freeze( $view ) );
  isa_ok( $restored, 'TUI::Views::View' );
  is_deeply( $restored->{origin}, { x => 3,  y => 4  }, 'preserves origin' );
  is_deeply( $restored->{size},   { x => 20, y => 10 }, 'preserves size' );
  is_deeply( $restored->{cursor}, { x => 5,  y => 6  }, 'preserves cursor' );
  is( $restored->{growMode}, 7, 'preserves growMode' );
  is( $restored->{dragMode}, 8, 'preserves dragMode' );
  is( $restored->{helpCtx},  9, 'preserves helpCtx' );
  is( $restored->{state}, sfVisible | sfShadow, 'omits transient state flags' );
  is(
    $view->{state},
    sfVisible | sfShadow | sfActive | sfSelected | sfFocused | sfExposed,
    'does not change the original state'
  );
  is( $restored->{options},   10,    'preserves options' );
  is( $restored->{eventMask}, 11,    'preserves eventMask' );
  is( $restored->{owner},     undef, 'clears owner' );
  is( $restored->{next},      undef, 'clears next' );
}; #/ 'TView Storable roundtrip' => sub

subtest 'TScroller Storable roundtrip' => sub {
  my $hBar = TScrollBar->new(
    bounds => TRect->new( ax => 0, ay => 0, bx => 10, by => 1 ) );
  my $vBar = TScrollBar->new(
    bounds => TRect->new( ax => 0, ay => 0, bx => 1, by => 10 ) );
  $hBar->{value} = 7;
  $vBar->{value} = 8;
  my $scroller = TScroller->new(
    bounds     => TRect->new( ax => 3, ay => 4, bx => 23, by => 14 ),
    hScrollBar => $hBar,
    vScrollBar => $vBar,
  );
  $scroller->{delta}    = TPoint->new( x => 5, y => 6 );
  $scroller->{limit}    = TPoint->new( x => 100, y => 50 );
  $scroller->{drawLock} = 2;
  $scroller->{drawFlag} = 1;
  my $restored = thaw( freeze( $scroller ) );

  isa_ok( $restored, TScroller );
  is_deeply( $restored->{origin}, { x => 3,  y => 4  }, 'preserves origin' );
  is_deeply( $restored->{size},   { x => 20, y => 10 }, 'preserves size' );
  isa_ok( $restored->{hScrollBar}, TScrollBar );
  isa_ok( $restored->{vScrollBar}, TScrollBar );
  is( $restored->{hScrollBar}{value}, 7, 'preserves horizontal scrollbar' );
  is( $restored->{vScrollBar}{value}, 8, 'preserves vertical scrollbar' );
  is_deeply( $restored->{delta}, { x => 5,   y => 6  }, 'preserves delta' );
  is_deeply( $restored->{limit}, { x => 100, y => 50 }, 'preserves limit' );
  is( $restored->{drawLock}, 0, 'resets drawLock' );
  ok( !$restored->{drawFlag}, 'resets drawFlag' );
}; #/ 'TScroller Storable roundtrip' => sub

subtest 'TGroup Storable roundtrip' => sub {
  my $group = TGroup->new(
    bounds => TRect->new( ax => 3, ay => 4, bx => 23, by => 14 ) );
  my $view1 = TView->new(
    bounds => TRect->new( ax => 1, ay => 2, bx => 11, by => 7 ) );
  my $view2 = TView->new(
    bounds => TRect->new( ax => 5, ay => 6, bx => 15, by => 11 ) );
  $group->insert( $view1 );
  $group->insert( $view2 );
  $group->setCurrent( $group->last, normalSelect );

  my $restored = thaw( freeze( $group ) );
  isa_ok( $restored, TGroup );
  is_deeply( $restored->{origin}, { x => 3,  y => 4  }, 'preserves origin' );
  is_deeply( $restored->{size},   { x => 20, y => 10 }, 'preserves size' );
  my $first = $restored->first;
  my $last  = $restored->last;
  isnt( $first, $last, 'restores both subviews' );
  is_deeply( $first->{origin}, { x => 5, y => 6 }, 'preserves first subview' );
  is_deeply( $last->{origin},  { x => 1, y => 2 }, 'preserves last subview' );
  is( $first->owner, $restored, 'restores first subview owner' );
  is( $last->owner,  $restored, 'restores last subview owner' );
  is( $restored->current, $last, 'preserves current subview' );
}; #/ 'TGroup Storable roundtrip' => sub

subtest 'TWindow Storable roundtrip' => sub {
  my $window = TWindow->new(
    bounds => TRect->new( ax => 3, ay => 4, bx => 23, by => 14 ),
    title  => 'Window test',
    number => 2,
  );
  $window->{flags}    = 17;
  $window->{zoomRect} = TRect->new( ax => 1, ay => 2, bx => 21, by => 12 );
  $window->{palette}  = 3;

  my $restored = thaw( freeze( $window ) );
  isa_ok( $restored, TWindow );
  is( $restored->{flags}, 17, 'preserves flags' );
  is_deeply(
    $restored->{zoomRect}{a},
    { x => 1, y => 2 },
    'preserves zoomRect origin'
  );
  is_deeply(
    $restored->{zoomRect}{b},
    { x => 21, y => 12 },
    'preserves zoomRect size'
  );
  is( $restored->{number}, 2, 'preserves number' );
  is( $restored->{palette}, 3, 'preserves palette' );
  is( $restored->{title}, 'Window test', 'preserves title' );
  isa_ok( $restored->{frame}, TFrame() );
  my $subview = $restored->first;
  is( $subview, $restored->{frame} );
  is_deeply( $restored->{frame}{origin}, $window->{frame}{origin},
    'preserves frame origin' );
  is_deeply( $subview->{origin}, $window->{frame}{origin},
    'preserves frame subview origin' );
  is_deeply( $restored->{frame}{size}, $window->{frame}{size},
    'preserves frame size' );
  is_deeply( $subview->{size}, $window->{frame}{size},
    'preserves frame subview size' );
}; #/ 'TWindow Storable roundtrip' => sub

subtest 'TListViewer Storable roundtrip' => sub {
  my $listViewer = TListViewer->new(
    bounds     => TRect->new( ax => 3, ay => 4, bx => 23, by => 14 ),
    numCols    => 2,
    hScrollBar => undef,
    vScrollBar => undef,
  );
  $listViewer->{topItem} = 4;
  $listViewer->{focused} = 5;
  $listViewer->{range}   = 20;

  my $restored = thaw( freeze( $listViewer ) );
  isa_ok( $restored, TListViewer );
  is_deeply( $restored->{origin}, { x => 3,  y => 4  }, 'preserves origin' );
  is_deeply( $restored->{size},   { x => 20, y => 10 }, 'preserves size' );
  is( $restored->{numCols}, 2,  'preserves numCols' );
  is( $restored->{topItem}, 4,  'preserves topItem' );
  is( $restored->{focused}, 5,  'preserves focused item' );
  is( $restored->{range},   20, 'preserves range' );
}; #/ 'TListViewer Storable roundtrip' => sub

done_testing();
