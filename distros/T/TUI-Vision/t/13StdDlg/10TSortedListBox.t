use strict;
use warnings;

use Test::More;
use Test::Exception;

BEGIN {
  use_ok 'TUI::Objects::Rect';
  use_ok 'TUI::Objects::StringCollection';
  use_ok 'TUI::Drivers::Const', qw( :evXXXX kbBack );
  use_ok 'TUI::Drivers::Event';
  use_ok 'TUI::StdDlg::SortedListBox';
  use_ok 'TUI::Views::Const', qw( cmReleasedFocus );
}

my ( $listBox, $event );

# Constructor test
subtest 'Object creation' => sub {
  my $bounds = TRect->new( ax => 0, ay => 0, bx => 20, by => 10 );

  lives_ok {
    $listBox = TSortedListBox->new(
      bounds     => $bounds,
      numCols    => 1,
      vScrollBar => undef,
    );
  } 'Constructor lives';
  isa_ok( $listBox, TSortedListBox );

  is( $listBox->{searchPos},  -1, 'searchPos default value' );
  is( $listBox->{shiftState},  0, 'shiftState default value' );
}; #/ 'Object creation' => sub

# newList() test
subtest 'newList()' => sub {
  my $coll = new_TStringCollection( 5, 5 );
  $coll->insert( $_ ) for qw( apple banana carrot );

  lives_ok { $listBox->newList( $coll ) } 'newList() lives';

  ok( $listBox->list, 'list() returns collection' );
  is( $listBox->{searchPos}, -1, 'newList resets searchPos' );

  # range comes from superclass ListBox implementation
  ok( $listBox->{range} >= 0, 'range is set' );
}; #/ 'newList()' => sub

# getKey() test
subtest 'getKey()' => sub {
  is( $listBox->getKey( 'abc' ), 'abc', 'getKey returns same string' );
};

# Basic handleEvent: no key effect
subtest 'handleEvent basic' => sub {
  my $coll = new_TStringCollection( 5, 5 );
  $coll->insert( $_ ) for qw( apple banana carrot );

  $listBox->{focused} = 0;
  $listBox->{range}   = 3;
  $listBox->{items}   = $coll;

  $event = TEvent->new(
    what    => evKeyDown,
    keyDown => { charScan => CharScanType->new( charCode => 0 ) },
  );

  lives_ok { $listBox->handleEvent( $event ) } 'handleEvent lives with empty char';
  is( $listBox->{searchPos}, -1, 'searchPos unchanged with charCode=0' );
}; #/ 'handleEvent basic' => sub

# Focus change resets searchPos
subtest 'handleEvent focus change' => sub {
  $listBox->{searchPos} = 5;
  $listBox->{focused} = 1;

  $event = TEvent->new(
    what    => evBroadcast,
    message => { command => cmReleasedFocus },
  );

  lives_ok { $listBox->handleEvent( $event ) } 'focus-release lives';
  is( $listBox->{searchPos}, -1, 'searchPos reset after focus change' );
}; #/ 'handleEvent focus change' => sub

done_testing();
