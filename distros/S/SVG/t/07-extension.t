use strict;
use warnings;

use Test::More tests => 1;
use SVG;

my $svg = SVG->new( -extension => q{<!ENTITY % myentity "myvalue">} );
$svg->group->text->cdata("Extensions");
my $xml = $svg->render;

like(
    $xml,
    qr/[\n<!ENTITY % myentity "myvalue">\n]>/,
    "ENTITY myentity myvalue"
);
