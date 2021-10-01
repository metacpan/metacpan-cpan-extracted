#!perl

use strict;
use warnings;
use Test::Exception;
use Test::More 0.98;

use TableData::Test::Source::AOA;

my $t = TableData::Test::Source::AOA->new(column_names=>[qw/i j/], aoa => [[1,2], [3,4]]);

is($t->get_column_count, 2);
is_deeply([$t->get_column_names], [qw/i j/]);
$t->reset_iterator;
is_deeply($t->get_next_item, [1,2]);
is_deeply($t->get_next_row_hashref , {i=>3,j=>4});
$t->reset_iterator;
is_deeply($t->get_next_row_hashref , {i=>1,j=>2});
is($t->get_row_count, 2);

done_testing;
