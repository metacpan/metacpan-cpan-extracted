#!perl

use strict;
use warnings;
use Test::Exception;
use Test::More 0.98;

use Tables::Test::Dynamic;

my $t = Tables::Test::Dynamic->new(num_rows=>3);
is($t->as_csv, <<_);
i
1
2
3
_

is($t->get_column_count, 1);
is_deeply([$t->get_column_names], [qw/i/]);
$t->reset_iterator;
is_deeply($t->get_row_arrayref, [qw/1/]);
is_deeply($t->get_row_hashref , {i=>2});
is_deeply($t->get_row_arrayref, [3]);
$t->reset_iterator;
is_deeply($t->get_row_hashref , {i=>1});
is($t->get_row_count, 3);

done_testing;
