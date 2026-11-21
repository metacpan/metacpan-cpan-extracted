use strict;
use warnings;

use Test::More;
use TUI::Editors::Indicator;
use TUI::Objects::Point;
use TUI::Objects::Rect;
use TUI::Views::Const qw( sfDragging );

{
  package MyIndicator;
  use TUI::toolkit;
  extends 'TUI::Editors::Indicator';
  our @buffers;
  sub writeBuf { 
    my ( $self, undef, undef, undef, undef, $b ) = @_; 
    push @buffers, $b
  }
  $INC{"MyIndicator.pm"} = 1;
}

my $view;
subtest 'TIndicator->new()' => sub {
  require_ok( 'MyIndicator' );
  $view = MyIndicator->new( 
    bounds => TRect->new( ax => 0, ay => 0, bx => 12, by => 1 )
  );
  isa_ok( $view, 'TUI::Editors::Indicator' );
};

sub drawn_text {
  my ( $view, $from, $to ) = @_;
  @MyIndicator::buffers = ();
  $view->draw();
  my $buf = $MyIndicator::buffers[-1];
  return join '', map { $buf->[$_]->character()->getText() } $from .. $to;
}

subtest 'draw() renders the cursor position right-aligned' => sub {
  $view->setValue( TPoint->new( x => 4, y => 9 ), !!0 );
  is( drawn_text( $view, 6, 9 ), '10:5', 'line:column is one-based' );
};

subtest 'draw() shows the modified marker' => sub {
  $view->setValue( TPoint->new( x => 0, y => 0 ), !!1 );
  @MyIndicator::buffers = ();
  $view->draw();
  is( $MyIndicator::buffers[-1][0]->character()->getText(), chr( 15 ),
    'marker replaces the leading frame glyph' );
};

subtest 'draw() uses the drag frame glyph only while dragging' => sub {
  $view->setValue( TPoint->new( x => 0, y => 0 ), !!0 );
  @MyIndicator::buffers = ();
  $view->draw();
  is( $MyIndicator::buffers[-1][0]->character()->getText(), "\xCD",
    'idle frame uses the double line glyph' );

  $view->setState( sfDragging, 1 );
  @MyIndicator::buffers = ();
  $view->draw();
  is( $MyIndicator::buffers[-1][0]->character()->getText(), "\xC4",
    'dragging frame uses the single line glyph' );
};

done_testing();
