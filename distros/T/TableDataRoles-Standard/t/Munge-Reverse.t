#!perl

use strict;
use warnings;
use Test::Exception;
use Test::More 0.98;

use TableData::Munge::Reverse;

my $t = TableData::Munge::Reverse->new(tabledata => "Sample::DeNiro");

is($t->get_column_count, 3);
is_deeply([$t->get_column_names], [qw/Year Score Title/]);
$t->reset_iterator;
is_deeply($t->get_next_item, [2023,73,"Ezra"]);
is_deeply($t->get_next_row_hashref , {Year=>2023,Score=>37,Title=>"About My Father"});
$t->reset_iterator;
is_deeply($t->get_next_row_hashref , {Year=>2023,Score=>73,Title=>"Ezra"});
is($t->get_row_count, 99);

done_testing;
