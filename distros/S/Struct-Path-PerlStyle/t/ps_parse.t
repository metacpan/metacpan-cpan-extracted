#!perl -T

use strict;
use warnings;
use Struct::Path::PerlStyle qw(ps_parse);
use Test::More tests => 36;

### EXCEPTIONS ###

eval { ps_parse(undef) };
like($@, qr/^Undefined path passed/);

eval { ps_parse({}) };
like($@, qr/^Failed to parse passed path 'HASH\(/);

eval { ps_parse('{a},{b}') };
like($@, qr/^Unsupported thing ',' in the path, step #1 /, "garbage between path elements");

eval { ps_parse('{a} []') };
like($@, qr/^Unsupported thing ' ' in the path, step #1 /, "space between path elements");

eval { ps_parse('[0}') };
like($@, qr/^Unsupported thing '\[0' in the path, step #0 /, "unmatched brackets");

eval { ps_parse('{a') };
like($@, qr/^Unsupported thing '\{a' in the path, step #0 /, "unclosed curly brackets");

eval { ps_parse('[0') };
like($@, qr/^Unsupported thing '\[0' in the path, step #0 /, "unclosed square brackets");

eval { ps_parse('(0)') };
like($@, qr/^Unsupported thing '0' as hook, step #0 /, "parenthesis in the path");

eval { ps_parse('[[0]]') };
like($@, qr/^Unsupported thing '\[0\]' for array index, step #0 /, "garbage: nested steps");

eval { ps_parse('[0-2]') };
like($@, qr/^Unsupported thing '-' for array index, step #0 /, "garbage in index definition");

eval { ps_parse('[..3]') };
like($@, qr/^Range start undefided, step #0 /, "range with one boundary");

eval { ps_parse('[4..]') };
like($@, qr/^Unfinished range secified, step #0 /, "range with one boundary2");

eval { ps_parse('[3.1415]') };
like($@, qr/^Incorrect array index '3.1415', step #0 /, "floating point array indexes");

eval { ps_parse('{a}{b+c}') };
like($@, qr/^Unsupported thing '\+' for hash key, step #1 /, "garbage in hash keys definition");

eval { ps_parse('{/a//}') };
like($@, qr|^Unsupported thing '/' for hash key, step #0 |, "regexp and one more slash");

### EMPTY PATH ###

is_deeply(
    ps_parse(''),
    [],
    "empty string - empty path"
);

### HASHES ###

is_deeply(
    ps_parse('{0}{01}{"2"}{3.14,"3.1415",1e-05}'),
    [{keys => [0]},{keys => ["01"]},{keys => [2]},{keys => [3.14,3.1415,1e-05 + 0]}],
    "numbers as hash keys"
);

is_deeply(
    ps_parse('{a}{b}{c}'),
    [{keys => ['a']},{keys => ['b']},{keys => ['c']}],
    "plain hash path"
);

is_deeply(
    ps_parse('{ c,a, b}{e  ,d }'),
    [{keys => ['c','a','b']},{keys => ['e','d']}],
    "hash path with slices and whitespace garbage"
);

is_deeply(
    ps_parse('{}{}{}'),
    [{},{},{}],
    "empty hash path"
);

is_deeply(
    ps_parse('{a b}{e d}'),
    [{keys => ['a','b']},{keys => ['e','d']}],
    "spaces as delimiters"
);

is_deeply(
    ps_parse("{'a', 'b'}{' c d'}"),
    [{keys => ['a','b']},{keys => [' c d']}],
    "quotes"
);

is_deeply(
    ps_parse('{"a", "b"}{" c d"}'),
    [{keys => ['a','b']},{keys => [' c d']}],
    "double quotes"
);

is_deeply(
    ps_parse("{'q\\'str\\'\\'','qq\"str\"'}"),
    [{keys => ["q'str''",'qq"str"']}],
    "escaped quotes"
);

is_deeply(
    ps_parse('{"q\"str\"\"","qq\'str\'"}'),
    [{keys => ['q"str""',"qq'str'"]}],
    "escaped quotes 2"
);

is_deeply(
    ps_parse('{"a", "b"}{/^abc[d..g]/}'),
    [{keys => ['a','b']},{regs => [qr/^abc[d..g]/]}],
    "regexp match"
);

is_deeply(
    ps_parse('{"a", "b"}{/^abc[d..g]/ mixed with,regular keys}'),
    [{keys => ['a','b']},{regs => [qr/^abc[d..g]/], keys => ['mixed','with','regular','keys']}],
    "regexp match mixed with regular keys"
);

is_deeply(
    ps_parse('{"a", "b"}{/^abc[d..g]/,/another/}'),
    [{keys => ['a','b']},{regs => [qr/^abc[d..g]/,qr/another/]}],
    "more than one regexp"
);

# unquoted utf8 for hash key doesn't supported yet =(
# https://github.com/adamkennedy/PPI/issues/168#issuecomment-180506979
eval { ps_parse('{кириллица}'), };
like($@, qr/Failed to parse passed path/, "can't parse unquoted utf8 hash keys");

# quoted - ok
is_deeply(
    ps_parse('{"кириллица"}'),
    [{keys => ['кириллица']}],
    "utf8 strings"
);

### ARRAYS ###

is_deeply(
    ps_parse('[2][5][0]'),
    [[2],[5],[0]],
    "array path with slices"
);

is_deeply(
    ps_parse('[ 0,2][7,5 , 2]'),
    [[0,2],[7,5,2]],
    "array path with slices and whitespace garbage"
);

is_deeply(
    ps_parse('[0..3][8..5]'),
    [[0..3],[reverse 5..8]],
    "perl doesn't support backward ranges, Struct::Path::PerlStyle does =)"
);

is_deeply(
    ps_parse('[][][]'),
    [[],[],[]],
    "empty array path"
);

is_deeply(
    ps_parse('[0.0][1][2.0]'),
    [[0],[1],[2]],
    "float point indexes with zero after dot is allowed"
);

is_deeply(
    ps_parse('[0][-1][-2]'),
    [[0],[-1],[-2]],
    "negative indexes"
);
