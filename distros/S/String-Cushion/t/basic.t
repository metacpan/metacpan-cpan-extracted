use strict;
use Test::More;
use String::Cushion;

is cushion(0, "thing"), 'thing', 'Nothing empty';
is cushion(0, 0, "\nthing"), 'thing', 'Empty leading line';
is cushion(0, "\n \nthing"), 'thing', 'Empty leading lines, with space';
is cushion(0, "thing\n"), 'thing', 'Empty trailing line';
is cushion(0, "thing\n \n"), 'thing', 'Empty trailing lines, with space';

is cushion(1, "thing"), "\nthing\n", 'cushion 1. Plain string.';
is cushion(0, 1, "thing"), "thing\n", 'cushion 0,1. Trailing new line.';
is cushion(2, 3, "\n thing \n other"), "\n\n thing \n other\n\n\n", 'cushion 2, 3. Leading new line';
done_testing;
