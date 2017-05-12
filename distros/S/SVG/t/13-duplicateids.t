use strict;
use warnings;

use Test::More tests => 2;
use SVG;

# test: duplicate ids, -raiseerror

my $svga           = SVG->new();
my $dupnotdetected = eval {
    $svga->group( id => 'the_group' );
    $svga->group( id => 'the_group' );
    1;
};

ok( !$dupnotdetected, "raiseerror" );

my $svgb = SVG->new( -raiseerror => 0, -printerror => 0 );
$svgb->group( id => 'the_group' );
$svgb->group( id => 'the_group' );
my $xml = $svgb->render();
like( $xml, qr/errors=/,
    "raiseerror and printerror attribute in constructor" );

