use strict;
use warnings;

use Test::More;
use Storable qw( freeze thaw );

BEGIN {
  use_ok 'TUI::Objects::Rect';
  use_ok 'TUI::Views::Const', qw( sfCursorVis );
  use_ok 'TUI::Views::Const', qw( sfDisabled );
  use_ok 'TUI::Dialogs::InputLine';
  use_ok 'TUI::Dialogs::Dialog';
  use_ok 'TUI::Dialogs::StaticText';
  use_ok 'TUI::Dialogs::ParamText';
  use_ok 'TUI::Dialogs::Label';
  use_ok 'TUI::Dialogs::History';
  use_ok 'TUI::Dialogs::Button';
  use_ok 'TUI::Dialogs::Cluster';
  use_ok 'TUI::Dialogs::StrItem';
  use_ok 'TUI::Dialogs::MultiCheckBoxes';
  use_ok 'TUI::Dialogs::ListBox';
  use_ok 'TUI::Objects::StringCollection';
  use_ok 'TUI::Validate::FilterValidator';
}

subtest 'TInputLine Storable roundtrip' => sub {
  my $inputLine = TInputLine->new(
    bounds    => TRect->new( ax => 3, ay => 4, bx => 23, by => 5 ),
    maxLen    => 20,
    validator => TFilterValidator->new( validChars => 'A-Za-z0-9' ),
  );
  $inputLine->{data}      = 'Ab12';
  $inputLine->{curPos}    = 3;
  $inputLine->{firstPos}  = 1;
  $inputLine->{selStart}  = 1;
  $inputLine->{selEnd}    = 3;
  $inputLine->{oldData}   = 'discard me';
  $inputLine->{state}    &= ~sfCursorVis;

  my $restored = thaw( freeze( $inputLine ) );
  isa_ok( $restored, TInputLine );
  is_deeply( $restored->{origin}, { x => 3, y => 4 }, 'preserves origin' );
  is_deeply( $restored->{size},   { x => 20, y => 1 }, 'preserves size' );
  is( $restored->{maxLen},   20, 'preserves maximum length' );
  is( $restored->{curPos},   3,  'preserves cursor position' );
  is( $restored->{firstPos}, 1,  'preserves first visible position' );
  is( $restored->{selStart}, 1,  'preserves selection start' );
  is( $restored->{selEnd},   3,  'preserves selection end' );
  is( $restored->{data},     'Ab12', 'preserves input data' );
  is( $restored->{oldData},  '', 'resets old input data' );
  ok( $restored->{state} & sfCursorVis, 'sets cursor visibility' );
  isa_ok( $restored->{validator}, TFilterValidator );
  is( $restored->{validator}{validChars}, 'A-Za-z0-9',
    'preserves validator configuration' );
  ok( $restored->{validator}->isValid( $restored->{data} ),
    'restored validator accepts input data' );
}; #/ 'TInputLine Storable roundtrip' => sub

subtest 'TButton Storable roundtrip' => sub {
  my $button = TButton->new(
    bounds  => TRect->new( ax => 3, ay => 4, bx => 13, by => 6 ),
    title   => 'Apply',
    command => 300,
    flags   => 0,
  );
  $button->{amDefault} = 1;
  $button->{state} |= sfDisabled;

  my $restored = thaw( freeze( $button ) );
  isa_ok( $restored, TButton );
  is( $restored->{title}, 'Apply', 'preserves title' );
  is( $restored->{command}, 300, 'preserves command' );
  is( $restored->{flags}, 0, 'preserves flags' );
  ok( $restored->{amDefault}, 'preserves amDefault' );
  ok( 
    ( $restored->{state} & sfDisabled ) == 0,
    'recalculates disabled state from command'
  );
}; #/ 'TButton Storable roundtrip' => sub

subtest 'TCluster Storable roundtrip' => sub {
  my $strings = TSItem->new( value => 'alpha',
        next => TSItem->new( value => 'bravo',
        next => TSItem->new( value => 'charlie', 
        next => undef )));

  my $cluster = TCluster->new(
    bounds  => TRect->new( ax => 3, ay => 4, bx => 23, by => 10 ),
    strings => $strings,
  );

  $cluster->{value} = 2;
  $cluster->{sel}   = 1;
  $cluster->setButtonState( 1 << 1, 0 );

  my $restored = thaw( freeze( $cluster ) );
  isa_ok( $restored, TCluster );

  is_deeply( $restored->{origin}, { x => 3, y => 4 }, 'preserves origin' );
  is_deeply( $restored->{size},   { x => 20, y => 6 }, 'preserves size' );

  is( $restored->{value}, 2, 'preserves value' );
  is( $restored->{sel},   1, 'preserves selection' );
  is( $restored->{enableMask}, 0xffff_fffd, 'preserves enable mask' );

  is( $restored->{strings}->getCount(), 3, 'preserves string count' );
  is( $restored->{strings}->at( 0 ), 'alpha', 'preserves first string' );
  is( $restored->{strings}->at( 1 ), 'bravo', 'preserves second string' );
  is( $restored->{strings}->at( 2 ), 'charlie', 'preserves third string' );

  ok(  $restored->buttonState( 0 ), 'keeps first item enabled' );
  ok( !$restored->buttonState( 1 ), 'keeps second item disabled' );
  ok(  $restored->buttonState( 2 ), 'keeps third item enabled' );

  is_deeply(
    $restored->{cursor},
    { x => 2, y => 0 },
    'resets cursor position'
  );

  ok( $restored->{state} & sfCursorVis, 'shows cursor after reading' );
}; #/ 'TCluster Storable roundtrip' => sub

subtest 'TMultiCheckBoxes Storable roundtrip' => sub {
  my $strings = TSItem->new( value => 'alpha',
        next => TSItem->new( value => 'bravo',
        next => TSItem->new( value => 'charlie',
        next => undef )));
  my $multiCheckBoxes = TMultiCheckBoxes->new(
    bounds   => TRect->new( ax => 3, ay => 4, bx => 23, by => 10 ),
    strings  => $strings,
    selRange => 3,
    flags    => 0x0203,
    states   => ' -+',
  );
  $multiCheckBoxes->{value} = 2 | ( 1 << 2 );
  $multiCheckBoxes->{sel}   = 1;

  my $restored = thaw( freeze( $multiCheckBoxes ) );
  isa_ok( $restored, TMultiCheckBoxes );
  is( $restored->{selRange}, 3, 'preserves selection range' );
  is( $restored->{flags}, 0x0203, 'preserves flags' );
  is( $restored->{states}, ' -+', 'preserves state markers' );
  is( $restored->{value}, 2 | ( 1 << 2 ), 'preserves inherited value' );
  is( $restored->{sel}, 1, 'preserves inherited selection' );
  is( $restored->multiMark( 0 ), 2, 'restores first item state' );
  is( $restored->multiMark( 1 ), 1, 'restores second item state' );
}; #/ 'TMultiCheckBoxes Storable roundtrip' => sub

subtest 'TListBox Storable roundtrip' => sub {
  my $items = TStringCollection->new( limit => 3, delta => 0 );
  $items->atInsert( 0, 'alpha' );
  $items->atInsert( 1, 'bravo' );
  $items->atInsert( 2, 'charlie' );
  my $listBox = TListBox->new(
    bounds  => TRect->new( ax => 3, ay => 4, bx => 23, by => 10 ),
    numCols => 1,
    vScrollBar => undef,
  );
  $listBox->newList( $items );
  $listBox->focusItem( 1 );

  my $restored = thaw( freeze( $listBox ) );
  isa_ok( $restored, TListBox );
  is_deeply( $restored->{origin}, { x => 3, y => 4 }, 'preserves origin' );
  is_deeply( $restored->{size},   { x => 20, y => 6 }, 'preserves size' );
  is( $restored->{numCols}, 1, 'preserves number of columns' );
  is( $restored->{range}, 3, 'preserves range' );
  is( $restored->{focused}, 1, 'preserves focused item' );
  isa_ok( $restored->{items}, TStringCollection );
  is( $restored->{items}->getCount(), 3, 'preserves item count' );
  is( $restored->{items}->at( 0 ), 'alpha', 'preserves first item' );
  is( $restored->{items}->at( 1 ), 'bravo', 'preserves second item' );
  is( $restored->{items}->at( 2 ), 'charlie', 'preserves third item' );
}; #/ 'TListBox Storable roundtrip' => sub

subtest 'TStaticText Storable roundtrip' => sub {
  my $staticText = TStaticText->new(
    bounds => TRect->new( ax => 3, ay => 4, bx => 23, by => 7 ),
    text   => "First line\nSecond line",
  );

  my $restored = thaw( freeze( $staticText ) );
  isa_ok( $restored, TStaticText );
  is_deeply( $restored->{origin}, { x => 3, y => 4 }, 'preserves origin' );
  is_deeply( $restored->{size},   { x => 20, y => 3 }, 'preserves size' );
  is( $restored->{text}, "First line\nSecond line", 'preserves text' );
}; #/ 'TStaticText Storable roundtrip' => sub

subtest 'TParamText Storable roundtrip' => sub {
  my $paramText = TParamText->new(
    bounds => TRect->new( ax => 3, ay => 4, bx => 23, by => 7 ),
  );
  $paramText->setText( 'Count: %d (%s)', 42, 'items' );

  my $restored = thaw( freeze( $paramText ) );
  isa_ok( $restored, TParamText );
  is_deeply( $restored->{origin}, { x => 3, y => 4 }, 'preserves origin' );
  is_deeply( $restored->{size},   { x => 20, y => 3 }, 'preserves size' );
  is( $restored->{str}, 'Count: 42 (items)', 'preserves formatted text' );
  my $text;
  $restored->getText( \$text );
  is( $text, 'Count: 42 (items)', 'restores displayed text' );
}; #/ 'TParamText Storable roundtrip' => sub

subtest 'TLabel Storable roundtrip' => sub {
  my $link = TInputLine->new(
    bounds => TRect->new( ax => 10, ay => 4, bx => 20, by => 5 ),
    maxLen => 10,
  );
  my $label = TLabel->new(
    bounds => TRect->new( ax => 3, ay => 4, bx => 9, by => 5 ),
    text   => '~N~ame:',
    link   => $link,
  );
  $label->{light} = 1;

  my $restored = thaw( freeze( $label ) );
  isa_ok( $restored, TLabel );
  is_deeply( $restored->{origin}, { x => 3, y => 4 }, 'preserves origin' );
  is_deeply( $restored->{size},   { x => 6, y => 1 }, 'preserves size' );
  is( $restored->{text}, '~N~ame:', 'preserves label text' );
  isa_ok( $restored->{link}, TInputLine );
  is( $restored->{link}{maxLen}, 10, 'restores linked control' );
  ok( !$restored->{light}, 'resets light state' );
}; #/ 'TLabel Storable roundtrip' => sub

subtest 'THistory Storable roundtrip' => sub {
  my $link = TInputLine->new(
    bounds => TRect->new( ax => 10, ay => 4, bx => 30, by => 5 ),
    maxLen => 20,
  );
  my $history = THistory->new(
    bounds    => TRect->new( ax => 3, ay => 4, bx => 5, by => 5 ),
    link      => $link,
    historyId => 7,
  );

  my $restored = thaw( freeze( $history ) );
  isa_ok( $restored, THistory );
  is_deeply( $restored->{origin}, { x => 3, y => 4 }, 'preserves origin' );
  is_deeply( $restored->{size},   { x => 2, y => 1 }, 'preserves size' );
  is( $restored->{historyId}, 7, 'preserves history ID' );
  isa_ok( $restored->{link}, TInputLine );
  is( $restored->{link}{maxLen}, 20, 'restores linked input line' );
}; #/ 'THistory Storable roundtrip' => sub

subtest 'TDialog Storable roundtrip' => sub {
  my $dialog = TDialog->new(
    bounds => TRect->new( ax => 3, ay => 4, bx => 23, by => 14 ),
    title  => 'Dialog test',
  );
  $dialog->{flags} = 7;

  my $restored = thaw( freeze( $dialog ) );
  isa_ok( $restored, TDialog );
  is_deeply( $restored->{origin}, { x => 3, y => 4 }, 'preserves origin' );
  is_deeply( $restored->{size},   { x => 20, y => 10 }, 'preserves size' );
  is( $restored->{title}, 'Dialog test', 'preserves inherited window title' );
  is( $restored->{flags}, 7, 'preserves inherited window flags' );
}; #/ 'TDialog Storable roundtrip' => sub

done_testing();
