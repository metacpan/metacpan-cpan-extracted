use strict;
use warnings;

use Test::More tests => 2;
use SVG qw(star planet moon);

my $svg = SVG->new;

$svg->star( id => "Sol" )->planet( id => "Jupiter" )
    ->moon( id => "Ganymede" );
like $svg->xmlify,
    qr{<star id="Sol">\s+<planet id="Jupiter">\s+<moon id="Ganymede" />\s+</planet>\s+</star>},
    'stars and planets';
ok( !eval { $svg->asteroid( id => "Ceres" ); }, "undefined custom tag" );

