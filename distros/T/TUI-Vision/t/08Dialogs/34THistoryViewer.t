use strict;
use warnings;

use Test::More;
use Test::Exception;

BEGIN {
  use_ok 'TUI::Const', qw( EOS );
  use_ok 'TUI::Objects::Rect';
  use_ok 'TUI::Dialogs::HistoryViewer';
  use_ok 'TUI::Dialogs::HistoryViewer::HistList', qw( /\S+/ );
  use_ok 'TUI::Drivers::Const', qw(
    :evXXXX
    kbEnter
    kbEsc
    meDoubleClick
  );
  use_ok 'TUI::Drivers::Event';
  use_ok 'TUI::Views::ScrollBar';
  use_ok 'TUI::Views::Const', qw(
    cmOK
    cmCancel
  );
}

# Initialize the history list for deterministic tests
INIT {
  initHistory();
  historyAdd( 10, 'first entry' );
  historyAdd( 10, 'second entry' );
  historyAdd( 20, 'third' );
} 
END {
  doneHistory();
}

# ScrollBars for the THistoryViewer test
my $hBar = TScrollBar->new(
  bounds => TRect->new( ax => 0, ay => 0, bx => 10, by => 1 ) );
my $vBar = TScrollBar->new(
  bounds => TRect->new( ax => 0, ay => 0, bx => 1, by => 10 ) );

# Test object creation via THistoryViewer->new()
my $viewer;
subtest 'Object creation' => sub {
  my $bounds = TRect->new( ax => 0, ay => 0, bx => 20, by => 10 );

  lives_ok {
    $viewer = THistoryViewer->new(
      bounds     => $bounds,
      hScrollBar => $hBar,
      vScrollBar => $vBar,
      historyId  => 10,
    );
  } 'THistoryViewer object created';

  isa_ok( $viewer, THistoryViewer );
}; #/ 'Object creation' => sub

# Test getPalette (THistoryViewer-specific palette)
subtest 'getPalette' => sub {
  can_ok( $viewer, 'getPalette' );
  my $palette;
  lives_ok { $palette = $viewer->getPalette() } 'getPalette executed';
  ok( ref $palette, 'getPalette returns a valid value' );
};

# Test historyWidth() against overridden history
subtest 'historyWidth' => sub {
  can_ok( $viewer, 'historyWidth' );
  my $width;
  lives_ok { $width = $viewer->historyWidth() } 'historyWidth executed';

  # Our test history: 'first entry' (11), 'second entry' (12), 'third' (5)
  is( $width, 12, 'historyWidth returns maximum length of history strings' );
};

# Test getText()
subtest 'getText' => sub {
  can_ok( $viewer, 'getText' );

  # Case 1: full string fits
  my $dest1 = '';
  lives_ok { $viewer->getText( \$dest1, 0, 20 ) } 'getText(0,20) executed';
  is(
    $dest1, 
    'first entry', 
    'getText returns full string when within maxChars'
  );

  # Case 2: truncated string
  my $dest2 = '';
  lives_ok { $viewer->getText( \$dest2, 1, 6 ) } 'getText(1,6) executed';
  is( $dest2, 'second', 'getText truncates string correctly' );

  # Case 3: empty string via unknown historyId -> EOS
  my $dest3 = 'will be overwritten';
  $viewer->{historyId} = 999;    # no entries in our override
  lives_ok { $viewer->getText( \$dest3, 0, 10 ) }
    'getText with empty history executed';
  is( $dest3, EOS, 'getText uses EOS when historyStr is empty' );
}; #/ 'getText' => sub

# Test handleEvent() logic for OK/Cancel paths
subtest 'handleEvent OK/Cancel paths' => sub {
  can_ok( $viewer, 'handleEvent' );

  # Double-click mouse event -> cmOK path
  my $ev_mouse = TEvent->new(
    what  => evMouseDown,
    mouse => { eventFlags => meDoubleClick },
  );
  lives_ok { $viewer->handleEvent( $ev_mouse ) }
    'handleEvent executed for mouse double-click';

  # Enter key -> cmOK path
  my $ev_enter = TEvent->new(
    what    => evKeyDown,
    keyDown => { keyCode => kbEnter },
  );
  lives_ok { $viewer->handleEvent( $ev_enter ) }
    'handleEvent executed for Enter key';

  # Esc key -> cmCancel path
  my $ev_esc = TEvent->new(
    what    => evKeyDown,
    keyDown => { keyCode => kbEsc },
  );
  lives_ok { $viewer->handleEvent( $ev_esc ) }
    'handleEvent executed for Esc key';

  # cmCancel command -> cmCancel path
  my $ev_cancel = TEvent->new(
    what    => evCommand,
    message => { command => cmCancel },
  );
  lives_ok { $viewer->handleEvent( $ev_cancel ) }
    'handleEvent executed for cmCancel command';
}; #/ 'handleEvent OK/Cancel paths' => sub

done_testing();
