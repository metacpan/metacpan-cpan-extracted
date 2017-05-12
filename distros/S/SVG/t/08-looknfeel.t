use strict;
use warnings;

use Test::More tests => 2;
use SVG ( -indent => '*', -elsep => '|', -nocredits => 1 );

# test: -indent -elsep -nocredits

my $svg = SVG->new();
$svg->group->text->cdata("Look and Feel");

my $xml = $svg->render();

like( $xml, qr/\n|\|/, "correct element separation" );
like( $xml, qr/\*\*/,  "correct indent string" );

