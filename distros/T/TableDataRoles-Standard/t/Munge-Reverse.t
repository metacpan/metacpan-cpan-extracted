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
is_deeply($t->get_next_item, [2016,11,"Dirty Grandpa"]);
is_deeply($t->get_next_row_hashref , {Year=>2015,Score=>61,Title=>"The Intern"});
$t->reset_iterator;
is_deeply($t->get_next_row_hashref , {Year=>2016,Score=>11,Title=>"Dirty Grandpa"});
is($t->get_row_count, 87);

done_testing;
