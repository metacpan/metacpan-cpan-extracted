#!/usr/env/bin perl

use Test2::V0;
use TCOD;

is [ TCOD::Line::bresenham( 0, 0, 10, 4 ) ], [
    [  0, 0 ],
    [  1, 0 ],
    [  2, 1 ],
    [  3, 1 ],
    [  4, 2 ],
    [  5, 2 ],
    [  6, 2 ],
    [  7, 3 ],
    [  8, 3 ],
    [  9, 4 ],
    [ 10, 4 ],
] => 'Calculated line with no callback';

my @points;
is [ TCOD::Line::bresenham( 0, 0, 10, 4, sub { push @points, [ @_ ] } ) ],
    [ ] => 'Using a callback returns empty list';

is \@points => [
    [  0, 0 ],
    [  1, 0 ],
    [  2, 1 ],
    [  3, 1 ],
    [  4, 2 ],
    [  5, 2 ],
    [  6, 2 ],
    [  7, 3 ],
    [  8, 3 ],
    [  9, 4 ],
    [ 10, 4 ],
] => 'Calculated line with callback';

done_testing;
