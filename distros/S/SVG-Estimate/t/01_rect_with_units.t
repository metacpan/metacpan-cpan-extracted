use strict;
use Test::More;
use Test::Exception;
use Image::SVG::Transform;
use lib 'lib', '../lib';

use_ok 'SVG::Estimate::Rect';
my $transform = Image::SVG::Transform->new();
dies_ok {
    my $rect = SVG::Estimate::Rect->new(
        start_point => [10,30],
        x           => 0,
        y           => 310,
        width       => '100%',
        height      => '50%',
        transformer => $transform,
    );
} 'rejected percentages in width/height';

dies_ok {
    my $rect = SVG::Estimate::Rect->new(
        start_point => [10,30],
        x           => 0,
        y           => 310,
        width       => '100 in',
        height      => '50 em',
        transformer => $transform,
    );
} 'rejected in/em in width/height';

done_testing();
