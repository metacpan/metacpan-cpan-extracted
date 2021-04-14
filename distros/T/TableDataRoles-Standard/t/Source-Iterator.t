#!perl

use strict;
use warnings;
use Test::Exception;
use Test::More 0.98;

use TableData::Test::Source::Iterator;

my $t = TableData::Test::Source::Iterator->new(num_rows=>3);

is($t->get_column_count, 1);
is_deeply([$t->get_column_names], [qw/i/]);
$t->reset_row_iterator;
is_deeply($t->get_row_arrayref, [1]);
is_deeply($t->get_row_hashref , {i=>2});
is_deeply($t->get_row_arrayref, [3]);
$t->reset_row_iterator;
is_deeply($t->get_row_hashref , {i=>1});
is($t->get_row_count, 3);

done_testing;
