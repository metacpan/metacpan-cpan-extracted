#!perl

use strict;
use warnings;
use Test::Exception;
use Test::More 0.98;

use TableData::Test::Dynamic;

my $t = TableData::Test::Dynamic->new(num_rows=>3);

is($t->get_column_count, 1);
is_deeply([$t->get_column_names], [qw/i/]);
$t->reset_row_iterator;
diag "index: " . $t->get_row_iterator_index;
is_deeply($t->get_row_arrayref, [1]);
diag "index: " . $t->get_row_iterator_index;
is_deeply($t->get_row_hashref , {i=>2});
diag "index: " . $t->get_row_iterator_index;
is_deeply($t->get_row_arrayref, [3]);
diag "index: " . $t->get_row_iterator_index;
$t->reset_row_iterator;
diag "index: " . $t->get_row_iterator_index;
is_deeply($t->get_row_hashref , {i=>1});
is($t->get_row_count, 3);

done_testing;
