use strict;
use warnings;

use Test::More;
use Test::Exception;

BEGIN {
  use_ok 'TUI::Objects::Rect';
  use_ok 'TUI::Dialogs::Const', qw( cmRecordHistory );
  use_ok 'TUI::Dialogs::History';
  use_ok 'TUI::Dialogs::HistoryViewer::HistList', qw( /\S+/ );
  use_ok 'TUI::Dialogs::InputLine';
  use_ok 'TUI::Drivers::Const', qw( :evXXXX );
  use_ok 'TUI::Drivers::Event';
  use_ok 'TUI::Views::Const', qw(
    cmReleasedFocus
    ofPostProcess
  );
}

# Initialize and cleanup history list for deterministic tests
INIT { initHistory() }
END  { doneHistory() }

# Object creation
my $hist;
subtest 'Object creation' => sub {
  my $bounds = TRect->new( ax => 0, ay => 0, bx => 5, by => 1 );
  my $link   = TInputLine->new( bounds => $bounds, maxLen => 20 );

  lives_ok {
    $hist = THistory->new(
      bounds    => $bounds,
      link      => $link,
      historyId => 10,
    );
  } 'THistory object created';

  isa_ok( $hist, THistory );
  is( $hist->{link}, $link, 'link attribute set correctly' );
  is( $hist->{historyId}, 10, 'historyId attribute set correctly' );

  # BUILD should have set options and eventMask
  ok( ( $hist->{options} & ofPostProcess ), 'options set to ofPostProcess' );
  ok( ( $hist->{eventMask} & evBroadcast ), 'eventMask set to evBroadcast' );
}; #/ 'Object creation' => sub

# Test draw()
subtest 'draw' => sub {
  can_ok( $hist, 'draw' );
  lives_ok { $hist->draw } 'draw executed without error';
};

# Test getPalette()
subtest 'getPalette' => sub {
  can_ok( $hist, 'getPalette' );
  my $palette;
  lives_ok { $palette = $hist->getPalette() } 'getPalette executed';
  ok( ref $palette, 'getPalette returns a valid value' );
};

# Test recordHistory()
subtest 'recordHistory' => sub {
  can_ok( $hist, 'recordHistory' );

  my $initial_count = historyCount( 10 );

  lives_ok {
    $hist->recordHistory( 'test entry' );
  } 'recordHistory executed';

  my $new_count = historyCount( 10 );
  ok(
    $new_count == $initial_count + 1,
    'historyCount increased by 1 after recordHistory'
  );

  my $last_index = $new_count - 1;
  my $last_value = historyStr( 10, $last_index );
  is( $last_value, 'test entry', 'last history entry matches recorded string' );
}; #/ 'recordHistory' => sub

# Test handleEvent() broadcast: cmRecordHistory and cmReleasedFocus
subtest 'handleEvent broadcast events' => sub {
  can_ok( $hist, 'handleEvent' );

  # Prepare link data
  $hist->{link}{data} = 'broadcast entry';

  # 1) cmRecordHistory broadcast
  my $event_record = TEvent->new(
    what    => evBroadcast,
    message => {
      command => cmRecordHistory,
    },
  );

  my $count_before = historyCount( 10 );
  lives_ok { $hist->handleEvent( $event_record ) }
    'handleEvent executed for cmRecordHistory broadcast';

  my $count_after = historyCount( 10 );
  ok(
    $count_after == $count_before + 1,
    'cmRecordHistory added one history entry'
  );

  my $idx = $count_after - 1;
  my $val = historyStr( 10, $idx );
  is(
    $val,
    'broadcast entry',
    'cmRecordHistory stored current link data'
  );

  # 2) cmReleasedFocus broadcast with infoPtr == link
  $hist->{link}{data} = 'released focus entry';

  my $event_release = TEvent->new(
    what    => evBroadcast,
    message => {
      command => cmReleasedFocus,
      infoPtr => $hist->{link},
    },
  );

  $count_before = historyCount( 10 );
  lives_ok { $hist->handleEvent( $event_release ) }
    'handleEvent executed for cmReleasedFocus broadcast';

  $count_after = historyCount( 10 );
  ok(
    $count_after == $count_before + 1,
    'cmReleasedFocus added one history entry'
  );

  $idx = $count_after - 1;
  $val = historyStr( 10, $idx );
  is(
    $val,
    'released focus entry',
    'cmReleasedFocus stored current link data'
  );
}; #/ 'handleEvent broadcast events' => sub

# Test shutDown()
subtest 'shutDown' => sub {
  can_ok( $hist, 'shutDown' );
  lives_ok { $hist->shutDown() } 'shutDown executed';
  ok( !defined $hist->{link}, 'link cleared on shutDown' );
};

done_testing();
