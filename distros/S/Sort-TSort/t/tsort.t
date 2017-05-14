use strict;
use warnings;
use utf8;
use open ':std' => ':utf8';

use Test::More;
use Test::Exception;

use Sort::TSort qw/tsort/;

my %test_cases = (
    valid => [
        {
            data => [
            ],
        },
        {
            data => [
                [1, 2],
                [1, 3],
                [1, 4],
            ],
        },
        {
            data => [
                [1, 2],
                [2, 3], 
                [1, 4],
                [1, 5],
                [4, 5],
                [3, 4],
            ],
        },
        {
            data => [
                ['aa', 'bb'],
                ['cc', 'dd'],
            ],
        },
        {
            data => [
                [ 'a', 'b' ],
                [ 'a', 'c' ],
                [ 'c', 'x' ],
                [ 'b', 'x' ],
                [ 'x', 'y' ],
                [ 'y', 'z' ],
            ],
        },
        {
            data => [
                [ 'арбуз', 'белка' ],
                [ 'арбуз', 'вагон' ],
                [ 'вагон', 'хамелеон' ],
                [ 'белка', 'хамелеон' ],
                [ 'хамелеон', 'юрта' ],
                [ 'юрта', 'янтарь' ],
            ],
        },
    ],

    invalid => [
        {
            name => 'not an arrref',
            data => [
                {},
            ],
        },
        {
            name => '3 elements in a row',
            data => [
                [1, 2, 3],
                [1, 2],
                [2, 3],
            ],
        },
        {
            name => '1 elements in a row',
            data => [
                [1, 2],
                [1],
                [2, 3],
            ],
        },
        {
            name => '1 elements in a row x2',
            data => [
                [1, 2],
                [1],
                [4],
                [2, 3],
            ],
        },
        {
            name => '5 elements in a row',
            data => [
                [1, 2],
                [2, 3],
                [1, 2, 3, 4, 5],
            ],
        },
        {
            name => '6 elements in a row',
            data => [
                [1, 2, 3, 4, 5, 6],
                [2, 3],
                [4, 5],
            ],
        },
        {
            name => 'a 2-loop',
            data => [
                [1, 2],
                [2, 1],
            ],
        },
        {
            name => 'a 2-loop + some other edges',
            data => [
                [1, 4],
                [1, 2],
                [2, 3],
                [2, 1],
                [4, 5],
            ],
        },
        {
            name => 'a 3-loop',
            data => [
                [1, 2],
                [2, 3],
                [3, 1],
            ],
        },
        {
            name => 'a 3-loop + some other edges',
            data => [
                [1, 2],
                [1, 4],
                [2, 3],
                [3, 1],
                [2, 3],
                [4, 5],
            ],
        },
    ],
);


for my $tc ( @{$test_cases{valid}} ){
    my $sorted = tsort($tc->{data});
    my %index = map { $sorted->[$_] => $_ } ( 0 .. scalar @$sorted - 1);
    my @partial_order = map { @$_ } @{$tc->{data}};

    while (@partial_order > 0){
        my $less = shift @partial_order;
        my $greater = shift @partial_order;
        ok(exists $index{$less});
        ok(exists $index{$greater});
        ok( $index{$less} < $index{$greater}, "$less < $greater" );
    }
}

for my $tc ( @{$test_cases{invalid}} ){
    dies_ok {tsort($tc->{data}) } $tc->{name};
}

done_testing();

