#!perl -T

use strict;
use warnings;

use Test::More tests => 18;
use Struct::Path::PerlStyle qw(ps_parse ps_serialize);

use lib 't';
use _common qw(roundtrip);

### ARRAYS ###

eval { ps_parse('[[0]]') };
like($@, qr/^Unsupported thing '\[0\]' for array index, step #0 /, "garbage: nested steps");

eval { ps_parse('[0-2]') };
like($@, qr/^Unsupported thing '-' for array index, step #0 /, "garbage in index definition");

eval { ps_parse('[..3]') };
like($@, qr/^Range start absent, step #0 /, "range with one boundary");

eval { ps_parse('[4..]') };
like($@, qr/^Unfinished range secified, step #0 /, "range with one boundary2");

eval { ps_parse('[3.1415]') };
like($@, qr/^Incorrect array index '3.1415', step #0 /, "floating point array indexes");

eval { ps_serialize([[undef]]) };
like($@, qr/^Incorrect array index 'undef', step #0 /, "garbage: undef as index");

eval { ps_serialize([["a"]]) };
like($@, qr/^Incorrect array index 'a', step #0 /, "garbage: non-number as index");

eval { ps_serialize([[0.3]]) };
like($@, qr/^Incorrect array index '0.3', step #0 /, "garbage: float as index");

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
    ps_parse('[0.0][1][2.0]'),
    [[0],[1],[2]],
    "float point indexes with zero after dot is allowed"
);

roundtrip (
    [[0,2],[7,5,2]],
    '[0,2][7,5,2]',
    "array path with slices"
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
    '[3..1,2..3]',
    "bidirectional ranges (desc-asc)"
);

roundtrip (
    [[0..3],[reverse 5..8]],
    '[0..3][8..5]',
    'backward ranges'
);
