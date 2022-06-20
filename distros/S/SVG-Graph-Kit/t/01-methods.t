#!perl
use strict;
use warnings;

use Test::More;
use Test::Exception;

use_ok 'SVG::Graph::Kit';

my $data = [ [ 1,  2,  0 ],
             [ 3,  5,  1 ],
             [ 4,  7,  2 ],
             [ 5, 11,  3 ],
             [ 6, 13,  5 ],
             [ 7, 17,  8 ],
             [ 8, 19, 13 ],
             [ 9, 23, 21 ],
             [10, 29, 34 ] ];

my $g = new_ok 'SVG::Graph::Kit' => [ data => $data ];

lives_ok { $g->draw } 'draw lives';

done_testing();
