use strict;
use warnings;

use Test::More tests => 5;

use_ok( 'SVG', "Use SVG" );

# I am not sure why were these tests incluced,
# but maybe there was a related bug?
use_ok( 'SVG', "call SVG twice without warnings" );
use_ok( 'SVG', "call SVG three times without warnings" );
use_ok( 'SVG', "call SVG ; do not blow it away without warnings" );

my $svg = SVG->new;
isa_ok $svg, 'SVG';
