use strict;
use Test::More;
use Image::SVG::Transform;
use Test::Exception;
use lib 'lib', '../lib';

use_ok 'SVG::Estimate::Ellipse';

my $transform = Image::SVG::Transform->new();
dies_ok {
    my $ellipse = SVG::Estimate::Ellipse->new(
        cx          => 3,
        cy          => 3,
        rx          => '10 pt',
        ry          => 5,
        start_point => [0,0],
        transformer => $transform,
    );
} 'ellipse rejects units on rx';

dies_ok {
    my $ellipse = SVG::Estimate::Ellipse->new(
        cx          => 3,
        cy          => 3,
        rx          => 10,
        ry          => '5 mm',
        start_point => [0,0],
        transformer => $transform,
    );
} 'ellipse rejects units on ry';

done_testing();
