use strict;
use warnings;

use Test::More;
use Test::Exception;

BEGIN {
  use_ok 'TUI::Objects::Rect';
  use_ok 'TUI::Drivers::Const', qw( :evXXXX );
  use_ok 'TUI::Drivers::Event';
  use_ok 'TUI::Views::Palette';
  use_ok 'TUI::Views::ScrollBar';
  use_ok 'TUI::Views::DrawBuffer';
  use_ok 'TUI::Views::Const', qw(
    cmScrollBarChanged
    :sfXXXX
  );
  use_ok 'TUI::Views::ListViewer';
} #/ BEGIN

# ScrollBars
my $hBar = TScrollBar->new(
  bounds => TRect->new( ax => 0, ay => 0, bx => 10, by => 1 ) );
my $vBar = TScrollBar->new(
  bounds => TRect->new( ax => 0, ay => 0, bx => 1, by => 10 ) );

# Test object creation
my $list;
subtest 'Object creation' => sub {
  my $bounds = TRect->new( ax => 0, ay => 0, bx => 20, by => 10 );

  lives_ok {
    $list = new_TListViewer( $bounds, 1, $hBar, $vBar );
  } 'TListViewer object created';

  isa_ok( $list, TListViewer );
}; #/ 'Object creation' => sub

# Test getPalette
subtest 'getPalette' => sub {
  can_ok( $list, 'getPalette' );
  my $palette;
  lives_ok { $palette = $list->getPalette() } 'getPalette executed';
  isa_ok( $palette, TPalette );
};

# Test changeBounds
subtest 'changeBounds' => sub {
  my $new_bounds = TRect->new( ax => 0, ay => 0, bx => 30, by => 15 );
  can_ok( $list, 'changeBounds' );
  lives_ok { $list->changeBounds( $new_bounds ) } 'changeBounds executed';
};

# Test draw
subtest 'draw' => sub {
  can_ok( $list, 'draw' );
  lives_ok { $list->draw } 'draw executed';
};

# Test focusItem / focusItemNum
subtest 'focusItem / focusItemNum' => sub {
  can_ok( $list, 'focusItem' );
  can_ok( $list, 'focusItemNum' );

  lives_ok { $list->focusItem( 0 ) } 'focusItem(0) executed';
  lives_ok { $list->focusItemNum( 1 ) } 'focusItemNum(1) executed';
};

# Test setRange
subtest 'setRange' => sub {
  can_ok( $list, 'setRange' );
  lives_ok { $list->setRange( 10 ) } 'setRange(10) executed';
};

# Test handleEvent (cmScrollBarChanged Broadcast)
subtest 'handleEvent (broadcast cmScrollBarChanged)' => sub {
  can_ok( $list, 'handleEvent' );

  my $event = TEvent->new(
    what    => evBroadcast,
    message => {
      command => cmScrollBarChanged,
      infoPtr => $vBar,
    },
  );

  lives_ok { $list->handleEvent( $event ) } 'handleEvent executed (vBar)';

  # second event for hScrollBar, just to exercise the other branch
  $event = TEvent->new(
    what    => evBroadcast,
    message => {
      command => cmScrollBarChanged,
      infoPtr => $hBar,
    },
  );

  lives_ok { $list->handleEvent( $event ) } 'handleEvent executed (hBar)';
}; #/ 'handleEvent (broadcast cmScrollBarChanged)' => sub

# Test setState
subtest 'setState' => sub {
  can_ok( $list, 'setState' );
  lives_ok {
    $list->setState( sfActive | sfVisible | sfSelected, 1 );
  } 'setState executed';
};

# Test shutDown
subtest 'shutDown' => sub {
  can_ok( $list, 'shutDown' );
  lives_ok { $list->shutDown() } 'shutDown executed';

  ok( !defined $list->{hScrollBar}, 'hScrollBar cleared' );
  ok( !defined $list->{vScrollBar}, 'vScrollBar cleared' );
};

done_testing();
