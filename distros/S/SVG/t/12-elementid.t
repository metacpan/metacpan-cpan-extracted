use strict;
use warnings;

use Test::More tests => 2;
use SVG;

my $svg   = SVG->new();
my $group = $svg->group( id => 'the_group' );

is( $group->getElementID(),            "the_group", "getElementID" );
is( $svg->getElementByID("the_group"), $group,      "getElementByID" );
