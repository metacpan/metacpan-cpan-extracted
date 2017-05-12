use strict;
use Test::More;
use Image::SVG::Transform;
use Test::Exception;
use lib 'lib', '../lib';

use_ok 'SVG::Estimate::Circle';

my $transform = Image::SVG::Transform->new();
dies_ok {
    my $circle = SVG::Estimate::Circle->new(
        cx          => 2,
        cy          => 2,
        r           => '100%',
        start_point => [0,0],
        transformer => $transform,
    );
} 'circle rejects rx with percentage';

dies_ok {
    my $circle = SVG::Estimate::Circle->new(
        cx          => 2,
        cy          => 2,
        r           => '100 in',
        start_point => [0,0],
        transformer => $transform,
    );
} 'circle rejects rx with units';

done_testing();
