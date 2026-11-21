use strict;
use warnings;

use Test::More;

BEGIN {
  use_ok 'TUI::Objects::Rect';
  use_ok 'TUI::Outline::Const';
  use_ok 'TUI::Outline::Node';
  use_ok 'TUI::Outline::OutlineViewer';
  use_ok 'TUI::Outline::Outline';
  use_ok 'TUI::Outline';
}

isa_ok( TNode->new( text => '' ), TNode() );
isa_ok( TOutlineViewer->new(
  bounds     => TRect->new( ax => 0, ay => 0, bx => 10, by => 5 ),
  hScrollBar => undef,
  vScrollBar => undef,
), TOutlineViewer() );
isa_ok( TOutline->new(
  bounds     => TRect->new( ax => 0, ay => 0, bx => 10, by => 5 ),
  hScrollBar => undef,
  vScrollBar => undef,
  root       => TNode->new( text => 'Root' ),
), TOutline() );

done_testing();
