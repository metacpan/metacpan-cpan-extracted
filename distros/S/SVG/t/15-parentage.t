use strict;
use warnings;

use Test::More tests => 18;
use SVG;

# test: getFirstChild, getLastChild, getParent, getChildren

my $svg    = SVG->new;
my $parent = $svg->group();
my $child1 = $parent->text->cdata("I am the first child");
my $child2 = $parent->text->cdata("I am the second child");
my $child3 = $parent->text->cdata("I am the third child");

is( $parent->getFirstChild(), $child1, "getFirstChild" );
is( $child1->getParent(),     $parent, "getParent 1" );
is( $parent->getLastChild(),  $child3, "getLastChild" );
is( $child2->getParent(),     $parent, "getParent 2" );
ok( $parent->hasChildren(), "hasChildren" );

my @children = $parent->getChildren();
is( scalar(@children), 3,       "correct number of children" );
is( $children[0],      $child1, "getChildren 1" );
is( $children[1],      $child2, "getChildren 2" );
is( $children[2],      $child3, "getChildren 3" );

is( $parent->removeChild($child1),    $child1, 'removeChild1' );
is( $parent->removeChild($child3),    $child3, 'removeChild3' );
is( $parent->removeChild($child2),    $child2, 'removeChild2' );
is( $parent->removeChild($child1),    0,       'no such child' );
is( $parent->findChildIndex($child1), -1,      'child1 is gone' );

is( $parent->insertAtIndex( $child1, 0 ), 1 );
is( $parent->findChildIndex($child1), 0,  'child1 is back' );
is( $parent->removeAtIndex(0),        $child1 );
is( $parent->findChildIndex($child1), -1, 'child1 is gone again' );

