use strict;
use warnings;

use Test::More;

BEGIN {
  use_ok 'TUI::Dialogs::HistoryViewer::HistList', qw(
    historyCount
    historyAdd
    historyStr
    clearHistory
    initHistory
    doneHistory
  );
}

# import global vars
use vars qw( 
  $historyBlock
  $historySize
  $historyUsed
);
{
  *historyBlock = \$TUI::Dialogs::HistoryViewer::HistList::historyBlock;
  *historySize  = \$TUI::Dialogs::HistoryViewer::HistList::historySize;
  *historyUsed  = \$TUI::Dialogs::HistoryViewer::HistList::historyUsed;
}

# Initialize history
initHistory();

# Test case for adding a history item
historyAdd( 1, 'First entry' );
is_deeply( $historyBlock,
  [ { id => 1, str => 'First entry' } ], 'First entry added to history' );

# Test case for counting history items
is( historyCount( 1 ), 1, 'Count of history items with id 1 is 1' );

# Test case for retrieving a history string
is( historyStr( 1, 0 ), 'First entry',
  'Retrieved history string for id 1 at index 0' );

# Test case for adding a duplicate history item
historyAdd( 1, 'First entry' );
is( historyCount( 1 ), 1, 'Duplicate entry not added to history' );

# Test case for adding a new history item
historyAdd( 1, 'Second entry' );
is_deeply( $historyBlock,
  [ { id => 1, str => 'First entry' }, { id => 1, str => 'Second entry' } ],
  'Second entry added to history' );

# Test case for counting history items after adding a new item
is( historyCount( 1 ), 2, 'Count of history items with id 1 is 2' );

# Test case for retrieving a history string at a different index
is( historyStr( 1, 1 ), 'Second entry',
  'Retrieved history string for id 1 at index 1' );

# Test case for clearing history
clearHistory();
is_deeply( $historyBlock, [],
  'History cleared' );

# Set a small history size for testing
$historySize = 10;

# Add entries to fill up the history size
historyAdd( 1, '12345' );
historyAdd( 1, '67890' );
is_deeply( $historyBlock,
  [ { id => 1, str => '12345' }, { id => 1, str => '67890' } ],
  'Entries added to history' );

# Add an entry that exceeds the history size
historyAdd( 1, 'abcdef' );
is_deeply( $historyBlock,
  [ { id => 1, str => '67890' }, { id => 1, str => 'abcdef' } ],
  'Oldest entry removed and new entry added to history' );

# Test case for counting history items
is( historyCount( 1 ), 2, 'Count of history items with id 1 is 2' );

# Test case for retrieving a history string
is( historyStr( 1, 0 ), '67890',
  'Retrieved history string for id 1 at index 0' );
is( historyStr( 1, 1 ), 'abcdef',
  'Retrieved history string for id 1 at index 1' );

# Test case for doneHistory
doneHistory();
is( $historyBlock, undef,
  'History block set to undef' );
is( $historyUsed, 0, 'History used set to 0' );

done_testing();
