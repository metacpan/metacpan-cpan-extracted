use strict;
use Test::More 0.98;

use_ok $_ for qw(
    SVG::Fill
);

my $file = SVG::Fill->new( "images/base.svg" );

isa_ok( $file, 'SVG::Fill' );

$file->fill_image("#MyImage","images/sample.png");
$file->save('output_png.svg');

$file->fill_image("#MyImage","images/sample.gif");
$file->save('output_gif.svg');

$file->fill_image("#MyImage","images/sample.svg");
$file->save('output_svg.svg');

$file->fill_image("#MyImage","images/sample.jpg");
$file->save('output_jpg.svg');

done_testing;

