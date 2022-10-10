use strict;
use warnings;

use Tags::HTML::Pager::Utils qw(compute_index_values);
use Test::More 'tests' => 9;
use Test::NoWarnings;

# Test.
my $items = 0;
my $actual_page = undef;
my $items_on_page = 24;
my ($begin_index, $end_index) = compute_index_values($items, $actual_page, $items_on_page);
is($begin_index, undef, 'Begin index = undef (0 items, actual page = undef, 24 images on page).');
is($end_index, undef, 'End index = undef (0 items, actual page = undef, 24 images on page).');

# Test.
$items = 1;
$actual_page = 1;
$items_on_page = 24;
($begin_index, $end_index) = compute_index_values($items, $actual_page, $items_on_page);
is($begin_index, 0, 'Begin index = 0 (1 items, actual page = 1, 24 images on page).');
is($end_index, 0, 'End index = 0 (1 items, actual page = 1, 24 images on page)');

# Test.
$items = 10;
$actual_page = 1;
$items_on_page = 1;
($begin_index, $end_index) = compute_index_values($items, $actual_page, $items_on_page);
is($begin_index, 0, 'Begin index = 0 (10 items, actual page = 1, 1 images on page).');
is($end_index, 0, 'End index = 0 (10 items, actual page = 1, 1 images on page)');

# Test.
$items = 55;
$actual_page = 2;
$items_on_page = 10;
($begin_index, $end_index) = compute_index_values($items, $actual_page, $items_on_page);
is($begin_index, 10, 'Begin index = 10 (55 items, actual page = 2, 10 images on page).');
is($end_index, 19, 'End index = 19 (55 items, actual page = 2, 10 images on page)');
