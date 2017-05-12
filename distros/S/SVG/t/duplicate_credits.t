use strict;
use warnings;

use Test::More tests => 1;

use SVG;

my $svg = SVG->new;

$svg->xmlify;

unlike $svg->xmlify => qr/Generated.*Generated/s,
    "don't add the author credits more than once";

