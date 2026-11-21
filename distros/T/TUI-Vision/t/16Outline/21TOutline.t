use strict;
use warnings;

use Test::More;

BEGIN {
  use_ok 'TUI::toolkit';
  use_ok 'TUI::Objects';
  use_ok 'TUI::Outline';
}

my $grandchild = new_TNode( 'Grandchild' );
my $second     = new_TNode( 'Second', undef, undef, false );
my $first      = new_TNode( 'First', $grandchild, $second, false );
my $root       = new_TNode( 'Root', $first, undef, true );

my $outline = new_TOutline(
  TRect->new( ax => 0, ay => 0, bx => 20, by => 10 ),
  undef,
  undef,
  $root,
);

is $outline->getRoot, $root, 'getRoot returns the root node';
is $outline->getText( $root ), 'Root', 'getText returns the node text';
is $outline->getNumChildren( $root ), 2, 'getNumChildren counts siblings';
is $outline->getNumChildren( $second ), 0, 'leaf has no children';
is $outline->getChild( $root, 0 ), $first, 'getChild(0) is first sibling';
is $outline->getChild( $root, 1 ), $second, 'getChild(1) is second sibling';
is $outline->getChild( $root, 2 ), undef, 'getChild beyond end is undef';
ok $outline->hasChildren( $root ), 'hasChildren is true for a parent';
ok !$outline->hasChildren( $second ), 'hasChildren is false for a leaf';

ok $outline->isExpanded( $root ), 'root is expanded initially';
$outline->adjust( $root, false );
ok !$outline->isExpanded( $root ), 'adjust collapses the node';
$outline->adjust( $root, true );
ok $outline->isExpanded( $root ), 'adjust expands the node again';

my $empty = new_TOutline(
  TRect->new( ax => 0, ay => 0, bx => 20, by => 10 ),
  undef,
  undef,
  undef,
);
is $empty->getRoot, undef, 'empty outline has no root';

done_testing();
