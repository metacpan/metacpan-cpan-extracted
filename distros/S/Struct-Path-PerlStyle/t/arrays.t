#!perl -T

use strict;
use warnings;

use Test::More tests => 22;
use Struct::Path::PerlStyle qw(str2path path2str);

use lib 't';
use _common qw(roundtrip);

### ARRAYS ###

eval { str2path('[[0]]') };
like($@, qr/^Incorrect array index '\[0\]', step #0 /, "garbage: nested steps");

eval { str2path('[0-2]') };
like($@, qr/^Incorrect array index '0-2', step #0 /, "garbage in index definition");

eval { str2path('[..3]') };
like($@, qr/^Incorrect array index '\.\.3', step #0 /, "range with one boundary");

eval { str2path('[4..]') };
like($@, qr/^Incorrect array index '4\.\.', step #0 /, "range with one boundary2");

eval { str2path('[3.1415]') };
like($@, qr/^Incorrect array index '3.1415', step #0 /, "floating point array indexes");

eval { str2path('[,0]') };
like($@, qr/^Incorrect array index '', step #0 /, "leading separator");

eval { str2path('[1,]') };
like($@, qr/^Incorrect array index '', step #0 /, "trailing separator");

eval { path2str([[undef]]) };
like($@, qr/^Incorrect array index 'undef', step #0 /, "garbage: undef as index");

eval { path2str([["a"]]) };
like($@, qr/^Incorrect array index 'a', step #0 /, "garbage: non-number as index");

eval { path2str([[0.3]]) };
like($@, qr/^Incorrect array index '0\.3', step #0 /, "garbage: float as index");

roundtrip (
    [[2],[5],[0]],
    '[2][5][0]',
    "explicit array path"
);

roundtrip (
    [[2],[],[0]],
    '[2][][0]',
    "implicit array path"
);

roundtrip (
    [[-2],[-5],[0]],
    '[-2][-5][0]',
    "negative indexes"
);

is_deeply(
    str2path('[0.0][1][2.0]'),
    [[0],[1],[2]],
    "float point indexes with zero after dot is allowed"
);

roundtrip (
    [[0,2],[7,5,2]],
    '[0,2][7,5,2]',
    "array path with slices"
);

roundtrip (
    [[0,0,0]],
    '[0,0,0]',
    "repeated indexes"
);

roundtrip (
    [[0,1],[2,3,4],[4,3,2],[1,0]],
    '[0,1][2..4][4..2][1,0]',
    "small ranges"
);

roundtrip (
    [[0,1,2],[6,7,8,10]],
    '[0..2][6..8,10]',
    "ascending ranges"
);

roundtrip (
    [[2,1,0],[10,8,7,6]],
    '[2..0][10,8..6]',
    "descending ranges"
);

roundtrip (
    [[-2,-1,0,1,2,1,0,-1,-2]],
    '[-2..2,1..-2]',
    "bidirectional ranges (asc-desc)"
);

roundtrip (
    [[3,2,1,2,3]],
    '[3..1,2,3]',
    "bidirectional ranges (desc-asc)"
);

roundtrip (
    [[0..3],[reverse 5..8]],
    '[0..3][8..5]',
    'backward ranges'
);
