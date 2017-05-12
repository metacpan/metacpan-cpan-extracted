use strict;
use warnings;

use Test::More tests => 4;
use SVG;

# test: getFirstChild, getLastChild, getParent, getChildren

my $svg    = SVG->new;
my $parent = $svg->group();
my $child1 = $parent->text->cdata("I am the first child");
my $child2 = $parent->text->cdata("I am the second child");

ok( $child1->hasSiblings(), "hasSiblings" );
is( $child1->getNextSibling(),     $child2, "getNextSibling" );
is( $child2->getPreviousSibling(), $child1, "getPreviousSibling" );

$child2->insertSiblingAfter($child1);
is( $child2->getNextSibling(), $child1, "insertSiblingAfter" );
