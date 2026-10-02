use strict;
use warnings;

use Test::More;
use Test::Exception;

BEGIN {
  use_ok 'TUI::Objects::Rect';
  use_ok 'TUI::Drivers::Const', qw( evBroadcast );
  use_ok 'TUI::Drivers::Event';
  use_ok 'TUI::ColorSel::Const', qw( cmSaveColorIndex );
  use_ok 'TUI::ColorSel::ColorGroup';
  use_ok 'TUI::ColorSel::ColorGroupList';
  use_ok 'TUI::ColorSel::ColorItem';
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

my $groups = make_groups();
my $bounds = TRect->new( ax => 0, ay => 0, bx => 10, by => 20 );
my $vBar = TScrollBar->new( bounds => $bounds );

my $list;
subtest 'Object creation' => sub {
  lives_ok {
    $list = TColorGroupList->new(
      bounds    => $bounds,
      scrollBar => $vBar,
      groups    => $groups,
    );
  } 'object created';
  isa_ok( $list, TColorGroupList );
  is( $list->{range}, 3, 'range equals number of groups' );

  my $obj;
  lives_ok {
    $obj = new_TColorGroupList( $bounds, $vBar, $groups );
  } 'factory constructor executed';
  isa_ok( $obj, TColorGroupList );
};

subtest 'getText' => sub {
  can_ok( $list, 'getText' );

  my $text = '';
  lives_ok { $list->getText( \$text, 0, 20 ) } 'group 0';
  is( $text, 'Desktop', 'first group text' );

  lives_ok { $list->getText( \$text, 1, 20 ) } 'group 1';
  is( $text, 'Dialogs', 'second group text' );

  lives_ok { $list->getText( \$text, 2, 20 ) } 'group 2';
  is( $text, 'Menus', 'third group text' );

  lives_ok { $list->getText( \$text, 1, 4 ) } 'truncation';
  is( $text, 'Dial', 'text truncated' );

  lives_ok { $list->getText( \$text, 0, 0 ) } 'zero chars';
  is( $text, '', 'empty result for maxChars = 0' );
};

subtest 'getGroup/getNumGroups' => sub {
  can_ok( $list, 'getGroup' );
  can_ok( $list, 'getNumGroups' );

  my $g;
  lives_ok { $g = $list->getGroup( 0 ) } 'getGroup(0)';
  is( $g->{name}, 'Desktop', 'first group' );

  lives_ok { $g = $list->getGroup( 1 ) } 'getGroup(1)';
  is( $g->{name}, 'Dialogs', 'second group' );

  lives_ok { $g = $list->getGroup( 2 ) } 'getGroup(2)';
  is( $g->{name}, 'Menus', 'third group' );

  ok( !defined $list->getGroup(3), 'out of range returns undef' );

  my $n;
  lives_ok { $n = $list->getNumGroups() } 'getNumGroups executed';
  is( $n, 3, 'three groups' );
};

subtest 'getGroupIndex/setGroupIndex' => sub {
  can_ok( $list, 'getGroupIndex' );
  can_ok( $list, 'setGroupIndex' );

  lives_ok { $list->setGroupIndex( 0, 2 ) } 'setGroupIndex(0,2)';
  is( $list->getGroupIndex(0), 2, 'index updated');

  lives_ok { $list->setGroupIndex( 2, 1 ) } 'setGroupIndex(2,1)';
  is( $list->getGroupIndex(2), 1, 'third group updated');

  lives_ok { $list->setGroupIndex( 99, 7 ) } 'invalid group ignored';
  is( $list->getGroupIndex(99), 0, 'invalid group still returns 0');
};

subtest 'handleEvent handles cmSaveColorIndex' => sub {
  $list->{focused} = 1;
  $groups->{next}{index} = 0;

  my $event = TEvent->new(
    what    => evBroadcast,
    message => {
      command  => cmSaveColorIndex,
      infoByte => 2,
    },
  );

  lives_ok { $list->handleEvent( $event ) }
    'handleEvent processes cmSaveColorIndex broadcast';
  is(
    $groups->{next}{index},
    2,
    'saved item index is stored in focused group',
  );
};

done_testing();
