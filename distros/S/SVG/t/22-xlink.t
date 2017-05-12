use strict;
use warnings;

use Test::More tests => 2;
use SVG;

# test: style

my $svg  = SVG->new;
my $defs = $svg->defs();

my $out = $svg->xmlify();

like(
    $out,
    qr{xmlns:xlink="http://www.w3.org/1999/xlink"},
    "xlink definition in svg - part 1"
);
like(
    $out,
    qr{xmlns="http://www.w3.org/2000/svg"},
    "xlink definition in svg - part 2"
);
