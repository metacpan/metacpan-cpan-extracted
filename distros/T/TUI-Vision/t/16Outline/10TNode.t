use strict;
use warnings;

use Test::More;

BEGIN {
  use_ok 'TUI::Outline';
}

subtest 'Named constructor and defaults' => sub {
  my $node = TNode->new( text => 'Root' );

  isa_ok( $node, TNode, 'node is a TNode' );
  is( $node->text, 'Root', 'text is set' );
  ok( !defined $node->next, 'next defaults to undef' );
  ok( !defined $node->childList, 'childList defaults to undef' );
  ok( $node->expanded, 'expanded defaults to true' );
};

subtest 'Positional factory mirrors C++ constructor' => sub {
  my $solo  = new_TNode( 'Solo' );
  my $child = new_TNode( 'Child' );
  my $root  = new_TNode( 'Root', $child, undef, 0 );
  my $sib   = new_TNode( 'Sibling', undef, $root );

  ok( $solo->expanded, 'expanded defaults to true for one argument' );
  ok( !defined $solo->childList, 'childList defaults to undef' );
  is( $root->childList, $child, 'childList is the child node' );
  ok( !$root->expanded, 'initialState is applied' );
  is( $sib->next, $root, 'next is the sibling node' );
  ok( $sib->expanded, 'expanded defaults to true when omitted' );
};

subtest 'Tree linking and modification' => sub {
  my $c2 = TNode->new( text => 'second' );
  my $c1 = TNode->new( text => 'first', next => $c2 );
  my $root = TNode->new( text => 'root', childList => $c1 );

  is( $root->childList->text, 'first', 'child list is traversable' );
  is( $root->childList->next, $c2, 'siblings are linked via next' );

  $root->expanded( 0 );
  ok( !$root->expanded, 'expanded can be changed' );
};

done_testing();
