use strict;
use warnings;

use Storable qw( freeze thaw );
use Test::More;

BEGIN {
  use_ok 'TUI::Objects::Rect';
  use_ok 'TUI::Objects::Point';
  use_ok 'TUI::Editors::Indicator';
  use_ok 'TUI::Editors::Editor';
  use_ok 'TUI::Editors::FileEditor';
  use_ok 'TUI::Editors::EditWindow';
}

subtest 'TIndicator Storable roundtrip' => sub {
  my $indicator = TIndicator->new(
    bounds => TRect->new( ax => 0, ay => 23, bx => 40, by => 24 ),
  );
  $indicator->setValue( TPoint->new( x => 4, y => 2 ), !!1 );

  my $restored = thaw( freeze( $indicator ) );
  isa_ok( $restored, TIndicator );
  is_deeply( $restored->{origin}, { x => 0, y => 23 }, 'preserves origin' );
  is_deeply( $restored->{size},   { x => 40, y => 1 }, 'preserves size' );
  is( $restored->{growMode}, $indicator->{growMode}, 'preserves grow mode' );

  # as in Turbo Vision, cursor location and modified flag are not streamed
  is( $restored->{location}{x}, 0, 'does not stream cursor column' );
  is( $restored->{location}{y}, 0, 'does not stream cursor row' );
  ok( !$restored->{modified}, 'does not stream modified state' );
}; #/ 'TIndicator Storable roundtrip' => sub

subtest 'TEditor Storable roundtrip' => sub {
  my $indicator = TIndicator->new(
    bounds => TRect->new( ax => 0, ay => 23, bx => 40, by => 24 ),
  );
  my $editor = TEditor->new(
    bounds     => TRect->new( ax => 0, ay => 0, bx => 60, by => 20 ),
    hScrollBar => undef,
    vScrollBar => undef,
    indicator  => $indicator,
    bufSize    => 4096,
  );
  $editor->canUndo( !!0 );
  $editor->insertText( "abc\ndef", 7, !!0 );

  my $restored = thaw( freeze( $editor ) );
  isa_ok( $restored, TEditor );
  is_deeply( $restored->{size}, { x => 60, y => 20 }, 'preserves size' );
  isa_ok( $restored->{indicator}, TIndicator );
  is( $restored->{bufSize}, 4096, 'preserves buffer size' );
  ok( !$restored->{canUndo}, 'preserves canUndo' );
  ok( $restored->{isValid}, 'restored editor is valid' );

  # as in Turbo Vision, the text and cursor are not streamed
  is( $restored->{buffer}, '', 'does not stream the buffer text' );
  is( $restored->{curPtr}, 0, 'does not stream the cursor' );
}; #/ 'TEditor Storable roundtrip' => sub

subtest 'TFileEditor Storable roundtrip' => sub {
  my $editor = TFileEditor->new(
    bounds     => TRect->new( ax => 0, ay => 0, bx => 60, by => 20 ),
    hScrollBar => undef,
    vScrollBar => undef,
    indicator  => undef,
    fileName   => '',
  );
  $editor->{fileName} = 'notes.txt';

  my $restored = thaw( freeze( $editor ) );
  isa_ok( $restored, TFileEditor );
  is( $restored->{fileName}, 'notes.txt', 'preserves the file name' );
  is( $restored->{buffer}, '', 'does not stream the buffer text' );
}; #/ 'TFileEditor Storable roundtrip' => sub

subtest 'TEditWindow Storable roundtrip' => sub {
  my $win = TEditWindow->new(
    bounds   => TRect->new( ax => 0, ay => 0, bx => 40, by => 12 ),
    fileName => 'notes.txt',
    number   => 1,
  );

  my $restored = thaw( freeze( $win ) );
  isa_ok( $restored, TEditWindow );
  isa_ok( $restored->{editor}, TFileEditor );
  like( $restored->{editor}{fileName}, qr/notes\.txt\z/,
    'preserves the file name' );
}; #/ 'TEditWindow Storable roundtrip' => sub

done_testing();
