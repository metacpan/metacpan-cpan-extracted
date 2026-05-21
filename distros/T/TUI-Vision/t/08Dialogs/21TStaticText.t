use strict;
use warnings;

use Test::More;
use Test::Exception;

BEGIN {
  use_ok 'TUI::Objects::Rect';
  use_ok 'TUI::Views::Const', qw( gfFixed );
  use_ok 'TUI::Views::DrawBuffer';
  use_ok 'TUI::Views::Palette';
  use_ok 'TUI::Views::View';
  use_ok 'TUI::Dialogs::StaticText';
  require_ok 'TUI::toolkit';
}

# Mock class to intercept writeLine calls
BEGIN {
  package MyStaticText;
  use TUI::toolkit;
  extends 'TUI::Dialogs::StaticText';
  our @WRITE_LINES;
  sub writeLine {
    shift;
    push @WRITE_LINES, [@_];
    ::pass( 'writeLine called' );
  }
  $INC{"MyStaticText.pm"} = 1;
}

use_ok 'MyStaticText';

my (
  $bounds,
  $stext,
);

# Object creation / BUILDARGS / BUILD
subtest 'Object creation' => sub {
  $bounds = TRect->new( ax => 0, ay => 0, bx => 20, by => 3 );
  isa_ok( $bounds, TRect, 'Bounds is a TRect object' );

  lives_ok {
    $stext = MyStaticText->new(
      bounds => $bounds,
      text   => 'Test static text',
    );
  } 'Constructor lives with valid text';
  isa_ok( $stext, TStaticText, 'Created object is correct class' );
  ok( $stext->{growMode} & gfFixed, 'growMode has gfFixed bit set' );
}; #/ 'Object creation' => sub

# BUILDARGS validation (basic)
subtest 'BUILDARGS validation' => sub {
  my $obj;
  lives_ok { $obj = MyStaticText->new( bounds => $bounds, text => 'Text' ) }
    'Constructor lives with valid parameters';
  isa_ok( $obj, TStaticText, 'Object created successfully' );

  dies_ok { MyStaticText->new( bounds => $bounds ) } 
    'Constructor dies when no text';
  dies_ok { MyStaticText->new( bounds => $bounds, text => undef ) } 
    'Constructor dies when text is undef';
  dies_ok { MyStaticText->new( bounds => $bounds, text => ['ref'] ) } 
    'Constructor dies when text is a reference';
}; #/ 'BUILDARGS validation' => sub

# Factory constructor from()
subtest 'Factory constructor' => sub {
  my $obj;
  lives_ok { $obj = new_TStaticText( $bounds, 'Text' ) }
    'new_TStaticText lives';
  isa_ok( $obj, TStaticText, 'constructor returns correct class' );
  is( $obj->text, 'Text', 'text attribute set by constructor' );
}; #/ 'Factory constructor' => sub

# getPalette
subtest 'getPalette' => sub {
  my $palette;
  lives_ok { $palette = $stext->getPalette() } 'getPalette lives';
  ok( $palette, 'Palette returned' );
  isa_ok( $palette, TPalette, 'Palette is a TPalette object' );

  my $palette2 = $stext->getPalette();
  isnt( $palette, $palette2, 'getPalette returns a clone each time' );
};

# getText behavior
subtest 'getText' => sub {
  my $obj = MyStaticText->from( $bounds, 'Short text' );

  my $s;
  lives_ok { $obj->getText( \$s ) } 'getText lives for normal text';
  is( $s, 'Short text', 'getText returns stored text' );

  # When internal text is undef, getText should return empty string
  $obj->{text} = undef;
  $s = 'preset';
  lives_ok { $obj->getText( \$s ) } 'getText lives when internal text is undef';
  is( $s, '', 'getText returns empty string for undef internal text' );

  # Long text should be truncated to 255 chars
  my $long = 'x' x 300;
  $obj->{text} = $long;
  $s = '';
  lives_ok { $obj->getText( \$s ) } 'getText lives for long text';
  is( length( $s ), 255, 'getText truncates text to 255 characters' );
}; #/ 'getText' => sub

# DEMOLISH
subtest 'DEMOLISH' => sub {
  my $obj = MyStaticText->from( $bounds, 'To be cleared' );
  ok( defined $obj->{text}, 'text is initially defined' );

  lives_ok { $obj->DEMOLISH( 0 ) } 'DEMOLISH lives';
  is( $obj->{text}, undef, 'text is cleared in DEMOLISH()' );
};

# draw()
subtest 'draw' => sub {
  @MyStaticText::WRITE_LINES = ();

  my $obj = MyStaticText->from(
    $bounds,
    "Line1\n\003Centered line\nWrapped line content"
  );

  lives_ok { $obj->draw() } 'draw() executes without error';
  ok( @MyStaticText::WRITE_LINES, 'draw() called writeLine at least once' );
}; #/ 'draw' => sub

done_testing();
