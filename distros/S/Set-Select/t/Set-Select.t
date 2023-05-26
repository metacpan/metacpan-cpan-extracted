#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
BEGIN { use_ok('Set::Select') };

# useful cases

my $sets = Set::Select->new(
	[1, 3, 5, 7],
	[2, 3, 6, 7],
	[4, 5, 6, 7]
);

for (
    ['100',         [1],             'only in the first set'],
    ['101',         [5],             'in the first and third sets'],
    ['111',         [7],             'in all three sets, i.e. intersection'],
    ['10.',         [1,5],           'in the first but not in the second sets, don\'t care about the 3rd'],
    ['...',         [1,2,3,4,5,6,7], 'in any of the sets, i.e. union'],
    ['100|010|001', [1,2,4],         'in exactly one of the sets'],
    ['.+',          [1,2,3,4,5,6,7], 'union of all, shorter syntax'],
    ['1+',          [7],             'intersection of all, shorter syntax'],
) {
	my $res = $sets->select($_->[0]);
	my $sorted = [sort @$res];
	is_deeply $sorted, $_->[1], $_->[2];
} 

my $all_subsets = {
	'100' => [1],
	'010' => [2],
	'110' => [3],
	'001' => [4],
	'101' => [5],
	'011' => [6],
	'111' => [7],
};

is_deeply $sets->all_subsets, $all_subsets, 'all subsets ok';

# degenerate cases

$sets = Set::Select->new();

for (
    ['1',         [],             'empty set'],
    ['0',         [],             'empty set'],
    ['.+',        [],             'empty set'],
) {
	my $res = $sets->select($_->[0]);
	my $sorted = [sort @$res];
	is_deeply $sorted, $_->[1], $_->[2];
} 

is_deeply $sets->all_subsets, {}, 'all subsets ok';

$sets = Set::Select->new(["a"]);

for (
    ['1',         ["a"],          'one set'],
    ['0',         [],             'empty set'],
    ['.+',        ["a"],          'one set'],
) {
	my $res = $sets->select($_->[0]);
	my $sorted = [sort @$res];
	is_deeply $sorted, $_->[1], $_->[2];
} 

is_deeply $sets->all_subsets, {'1' => ['a']}, 'all subsets ok';


$sets = Set::Select->new(["a"], ["a"], ["a"]);

for (
    ['111',         ["a"],          'intersection'],
    ['001',         [],             'empty set'],
    ['...',         ["a"],          'union'],
) {
	my $res = $sets->select($_->[0]);
	my $sorted = [sort @$res];
	is_deeply $sorted, $_->[1], $_->[2];
} 

is_deeply $sets->all_subsets, {'111' => ['a']}, 'all subsets ok';

# many sets
my @x;
for my $i (0..50) {
	push @x, [$i .. $i+50];
}
$sets = Set::Select->new(@x);

for (
    ['1+',         [50],          'intersection'],
    ['.+',         [0..100],             'union'],
) {
	my $res = $sets->select($_->[0]);
	my $sorted = [sort {$a <=> $b} @$res];
	is_deeply $sorted, $_->[1], $_->[2];
} 

done_testing();
