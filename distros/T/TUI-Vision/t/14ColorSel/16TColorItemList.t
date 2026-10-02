use strict;
use warnings;

use Test::More;
use Test::Exception;

BEGIN {
  use_ok 'TUI::Objects::Rect';
  use_ok 'TUI::Drivers::Const', qw( evBroadcast );
  use_ok 'TUI::Drivers::Event';
  use_ok 'TUI::ColorSel::Const', qw(
    cmNewColorItem
    cmSaveColorIndex
  );
  use_ok 'TUI::ColorSel::ColorGroup';
  use_ok 'TUI::ColorSel::ColorItem';
  use_ok 'TUI::ColorSel::ColorItemList';
  use_ok 'TUI::Views::ScrollBar';
}

sub make_items {
  my @names = @_;
  my ( $first, $prev );
  my $index = 0;
  for my $name ( @names ) {
    my $item = TColorItem->new(
      name  => $name,
      index => ++$index,
      next  => undef,
    );
    if ( defined $prev ) {
      $prev->{next} = $item;
    }
    else {
      $first = $item;
    }
    $prev = $item;
  }
  return $first;
}

sub make_groups {
  my $g3 = TColorGroup->new(
    name  => 'Menus',
    items => make_items( 'Normal', 'Selected' ),
    next  => undef,
  );
  my $g2 = TColorGroup->new(
    name  => 'Dialogs',
    items => make_items( 'Frame', 'Title', 'Button' ),
    next  => $g3,
  );
  my $g1 = TColorGroup->new(
    name  => 'Desktop',
    items => make_items( 'Background', 'Text' ),
    next  => $g2,
  );
  return $g1;
}

my $bounds = TRect->new( ax => 0, ay => 0, bx => 10, by => 20 );
my $vBar = TScrollBar->new( bounds => $bounds );

my $list;
subtest 'Object creation' => sub {
  my $items = make_items( 'Background', 'Text', 'Frame' );
  lives_ok {
    $list = TColorItemList->new(
      bounds    => $bounds,
      scrollBar => $vBar,
      items     => $items,
    );
  } 'object created';

  isa_ok( $list, TColorItemList );
  is( $list->{range}, 3, 'range equals number of items' );
  ok( $list->{eventMask} & evBroadcast, 'evBroadcast added to event mask' );

  my $obj;
  lives_ok { $obj = new_TColorItemList( $bounds, $vBar, $items ) } 
    'factory constructor executed';
  isa_ok( $obj, TColorItemList );
};

subtest 'getText' => sub {
  can_ok( $list, 'getText' );

  my $text = '';
  lives_ok { $list->getText( \$text, 0, 20 ) } 'item 0';
  is( $text, 'Background', 'first item text' );

  lives_ok { $list->getText( \$text, 1, 20 ) } 'item 1';
  is( $text, 'Text', 'second item text' );

  lives_ok { $list->getText( \$text, 2, 20 ) } 'item 2';
  is( $text, 'Frame', 'third item text' );

  lives_ok { $list->getText( \$text, 0, 4 ) } 'truncation';
  is( $text, 'Back', 'text truncated' );

  lives_ok { $list->getText( \$text, 0, 0 ) } 'zero chars';
  is( $text, '', 'empty result for maxChars = 0' );
};

subtest 'handleEvent handles cmNewColorItem' => sub {
  my $groups = make_groups();
  my $event = TEvent->new(
    what    => evBroadcast,
    message => {
      command => cmNewColorItem,
      infoPtr => $groups,
    },
  );

  lives_ok { $list->handleEvent( $event ) }
    'handleEvent processes cmNewColorItem';
  is( $list->{range}, 2, 'range updated from group item count' );
  is( $list->{focused}, 0, 'group index selected' );

  my $text = '';
  lives_ok { $list->getText( \$text, 0, 20 ) } 'first group item text';
  is( $text, 'Background', 'item list replaced with group items' );
  lives_ok { $list->getText( \$text, 1, 20 ) } 'second group item text';
  is( $text, 'Text', 'second item available' );
};

done_testing();
