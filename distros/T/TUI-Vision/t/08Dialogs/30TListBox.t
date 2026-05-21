use strict;
use warnings;

use Test::More;
use Test::Exception;

BEGIN {
  use_ok 'TUI::Const', qw( EOS );
  use_ok 'TUI::Objects::Rect';
  use_ok 'TUI::Views::ScrollBar';
  use_ok 'TUI::Dialogs::ListBox';
  use_ok 'TUI::Objects::Collection';
}

sub make_collection {
  my @items = @_;

  my $col = TCollection->new(
    limit => scalar( @items ) || 1,
    delta => 5,
  );

  my $idx = 0;
  for my $it ( @items ) {
    $col->atInsert( $idx++, $it );
  }

  return $col;
} #/ sub make_collection

my $vBar = TScrollBar->new(
  bounds => TRect->new( ax => 0, ay => 0, bx => 1, by => 10 ) );

# Test Object
my $listbox;
subtest 'Object creation' => sub {
  my $bounds = TRect->new( ax => 0, ay => 0, bx => 20, by => 10 );

  lives_ok {
    $listbox = new_TListBox( $bounds, 1, $vBar );
  } 'TListBox object created';

  isa_ok( $listbox, 'TUI::Dialogs::ListBox' );
  ok( !defined $listbox->list, 'list() is undef after creation' );
}; #/ 'Object creation' => sub

# Test dataSize
subtest 'dataSize' => sub {
  can_ok( $listbox, 'dataSize' );
  my $size;
  lives_ok { $size = $listbox->dataSize() } 'dataSize executed';
  is( $size, 2, 'dataSize returns 2 (items, selection)' );
};

# Test newList + list
subtest 'newList / list' => sub {
  can_ok( $listbox, 'newList' );
  can_ok( $listbox, 'list' );

  my $items = make_collection( 'one', 'two', 'three' );

  lives_ok { $listbox->newList( $items ) } 'newList executed';

  my $current = $listbox->list;
  isa_ok( $current, TCollection );
  is( $current, $items, 'items collection stored in listbox' );
}; #/ 'newList / list' => sub

# Test getText
subtest 'getText' => sub {
  can_ok( $listbox, 'getText' );

  my $items = make_collection( 'one', 'second', 'three' );
  $listbox->newList( $items );

  my $text;

  lives_ok {
    $listbox->getText( \$text, 1, 3 );    # item "second"
  } 'getText executed';

  is( $text, 'sec', 'getText returns truncated item text' );

  # now test behaviour when there are no items (items == 0)
  my $empty_listbox;
  lives_ok {
    my $bounds = TRect->new( ax => 0, ay => 0, bx => 20, by => 5 );
    $empty_listbox = new_TListBox( $bounds, 1, $vBar );
  } 'empty TListBox created';

  my $t;
  lives_ok { $empty_listbox->getText( \$t, 0, 5 ) }
    'getText executed on empty listbox';
  is( $t, EOS, 'getText uses EOS when there are no items' );
}; #/ 'getText' => sub

# Test getData
subtest 'getData' => sub {
  can_ok( $listbox, 'getData' );

  # focus 2nd item
  $listbox->focusItem( 1 );

  my $data = TListBoxRec->new();
  lives_ok { $listbox->getData( $data ) } 'getData executed';
  isa_ok( $data, 'TListBoxRec' );

  my ( $items, $selection ) = @$data;
  isa_ok( $items, TCollection, 'record[0] is a TCollection' );
  ok( defined $selection, 'record[1] selection index is defined' );
  is( $selection, 1, 'selection index matches focused item' );
}; #/ 'getData' => sub

# Test setData
subtest 'setData' => sub {
  can_ok( $listbox, 'setData' );

  # prepare new record: new collection and a selection index
  my $items = make_collection( 'alpha', 'beta', 'gamma', 'delta' );
  my @rec   = ( $items, 2 );    # selection = index 2 ("gamma")

  lives_ok { $listbox->setData( \@rec ) } 'setData executed';

  # verify that items and focused selection were updated
  my @after;
  $listbox->getData( \@after );

  is( $after[0], $items, 'items in listbox updated from record' );
  is( $after[1], 2,      'selection in listbox updated from record' );

  # verify getText now returns the new item
  my $text;
  $listbox->getText( \$text, $after[1], 10 );
  is( $text, 'gamma', 'getText reflects new item list and selection' );
}; #/ 'setData' => sub

done_testing();
