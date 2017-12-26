#!perl -T

use strict;
use warnings FATAL => 'all';

use Struct::Diff qw(diff list_diff);
use Test::More tests => 8;

use lib "t";
use _common qw(sdump);

my ($frst, $scnd, @list, $frozen);

### arrays ###
$frst = [0, [1]];
$scnd = [0, [0]];
@list = list_diff(diff($frst, $scnd, noU => 1));
is_deeply(
    \@list,
    [
        [[1],[0]],
            \{N => 0,O => 1}
    ],
    "provided index must be picked for path, when common items omitted"
) or diag sdump \@list;

### keys sort ###
$frst = { '0' => 0,  '1' => 1, '02' => 2 };
$scnd = { '0' => '', '1' => 1, '02' => 2 };

@list = list_diff(diff($frst, $scnd), sort => 1);
is_deeply(
    \@list,
    [
        [{K => ['0']}],
            \{N => '',O => 0},
        [{K => ['02']}],
            \{U => 2},
        [{K => ['1']}],
            \{U => 1}
    ],
    "lexical keys sort"
) or diag sdump \@list;

@list = list_diff(diff($frst, $scnd), sort => sub { sort { $b <=> $a } @_ });
is_deeply(
    \@list,
    [
        [{K => ['02']}],
            \{U => 2},
        [{K => [1]}],
            \{U => 1},
        [{K => [0]}],
            \{N => '',O => 0}
        ],
    "numeric keys sort (desc)"
) or diag sdump \@list;

### mixed structures ###
$frst = { 'a' => [ { 'aa' => { 'aaa' => [ 7, 4 ]}}, 8 ]};
$scnd = { 'a' => [ { 'aa' => { 'aaa' => [ 7, 3 ]}}, 8 ]};

@list = list_diff(diff($frst, $frst));
is_deeply(
    \@list,
    [
        [],
            \{U => {a => [{aa => {aaa => [7,4]}},8]}}
    ],
    "MIXED: unchanged"
) or diag sdump \@list;

my $d = diff($frst, $scnd);
@list = list_diff($d);
is_deeply(
    \@list,
    [
        [{K => ['a']},[0],{K => ['aa']},{K => ['aaa']},[0]],
            \{U => 7},
        [{K => ['a']},[0],{K => ['aa']},{K => ['aaa']},[1]],
            \{N => 3,O => 4},
        [{K => ['a']},[1]],
            \{U => 8}
    ],
    "MIXED: complex"
) or diag sdump \@list;

### depth ###
@list = list_diff(diff($frst, $scnd), depth => 0);
is_deeply(
    \@list,
    [
        [{K => ['a']},[0],{K => ['aa']},{K => ['aaa']},[0]],
            \{U => 7},
        [{K => ['a']},[0],{K => ['aa']},{K => ['aaa']},[1]],
            \{N => 3,O => 4},
        [{K => ['a']},[1]],
            \{U => 8}
    ],
    "depth 0 (full list)"
) or diag sdump \@list;

@list = list_diff(diff($frst, $scnd), depth => 1);
is_deeply(
    \@list,
    [
        [{K => ['a']}],
            \{D => [{D => {aa => {D => {aaa => {D => [{U => 7},{N => 3,O => 4}]}}}}},{U => 8}]}
    ],
    "depth 1"
) or diag sdump \@list;

@list = list_diff(diff($frst, $scnd), depth => 2);
is_deeply(
    \@list,
    [
        [{K => ['a']},[0]],
            \{D => {aa => {D => {aaa => {D => [{U => 7},{N => 3,O => 4}]}}}}},
        [{K => ['a']},[1]],
            \{U => 8}
    ],
    "depth 2"
) or diag sdump \@list;
