use strict;
use Test::More 0.98;

use_ok $_ for qw(
    SVG::Fill
);

my $file = SVG::Fill->new( "images/base.svg" );

isa_ok( $file, 'SVG::Fill' );

my $result1 = $file->font_fix; 

$file->save("output_font.svg");

done_testing;

