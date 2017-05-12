use strict;
use warnings;

use Test::More tests => 4;
use SVG;

# test: getElementTypes, getElementsByType, getElementType, getElementsByType, getElementTypes

my $svg    = SVG->new;
my $parent = $svg->group();
my $child1 = $parent->text->cdata("I am the first child");
my $child2 = $parent->text->cdata("I am the second child");

is( $child1->getElementType(), "text", "getElementType" );

is( scalar( @{ $svg->getElementsByType("g") } ),
    1, "getElementsByType test 1" );
is( scalar( @{ $svg->getElementsByType("text") } ),
    2, "getElementsByType test 2" );
is( scalar( @{ $svg->getElementTypes() } ), 3, "getElementTypes" );
