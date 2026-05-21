use strict;
use warnings;

use Test::More;
use Test::Exception;

BEGIN {
  use_ok 'TUI::Objects::Rect';
  use_ok 'TUI::Dialogs::HistoryViewer';
  use_ok 'TUI::Dialogs::HistoryViewer::HistList', qw( /\S+/ );
  use_ok 'TUI::Dialogs::HistoryWindow';
  use_ok 'TUI::Drivers::Event';
  use_ok 'TUI::Views::Const', qw( wfClose );
  use_ok 'TUI::Views::ScrollBar';
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

# Test object creation via new_THistoryWindow
my $win;
subtest 'Object creation' => sub {
  my $bounds = TRect->new( ax => 0, ay => 0, bx => 40, by => 10 );

  lives_ok {
    $win = new_THistoryWindow( $bounds, 10 );
  } 'THistoryWindow object created';

  isa_ok( $win, THistoryWindow );

  # Flags should be set to wfClose by BUILD
  ok( ( $win->{flags} & wfClose ), 'wfClose flag is set' );

  # Viewer should be created and inserted
  ok( defined $win->{viewer}, 'viewer attribute is defined' );
  isa_ok( $win->{viewer}, THistoryViewer, 'viewer is a THistoryViewer' );
};

# Test getPalette
subtest 'getPalette' => sub {
  can_ok( $win, 'getPalette' );
  my $palette;
  lives_ok { $palette = $win->getPalette() } 'getPalette executed';
  ok( ref $palette, 'getPalette returns a valid value' );
};

# Test getSelection (delegates to viewer->getText on focused item)
subtest 'getSelection' => sub {
  can_ok( $win, 'getSelection' );

  # Ensure viewer has a focused item: index 1 -> "second entry"
  $win->{viewer}{focused} = 1;

  my $selection = '';
  lives_ok { $win->getSelection( \$selection ) } 'getSelection executed';
  is( $selection, 'second entry', 'getSelection returns focused history entry' );
};

# Test initViewer (explicit call)
subtest 'initViewer' => sub {
  can_ok( THistoryWindow, 'initViewer' );

  my $r = TRect->new( ax => 0, ay => 0, bx => 40, by => 10 );
  my $viewer;

  lives_ok {
    # we will use historyId 10 in our tests ('first entry', 'second entry')
    $viewer = THistoryWindow->initViewer( $r, $win, 10 );
  } 'initViewer executed';

  isa_ok( $viewer, THistoryViewer, 'initViewer returns THistoryViewer' );
};

done_testing();
