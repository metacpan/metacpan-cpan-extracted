#!perl

use strict;
use warnings;
use Test::Exception;
use Test::More 0.98;

use TableData::Munge::Filter;

my $t1 = TableData::Munge::Filter->new(
    tabledata => 'Sample::DeNiro',
    filter => sub { my $row=shift; $row->[0] <= 1979 },
);
is($t1->get_column_count, 3);
is_deeply([$t1->get_column_names], [qw/Year Score Title/]);
$t1->reset_iterator;
is_deeply($t1->get_next_item, [1968,86,"Greetings"]);
is_deeply($t1->get_next_row_hashref , {Year=>1970,Score=>17,Title=>"Bloody Mama"});
$t1->reset_iterator;
is_deeply($t1->get_next_row_hashref , {Year=>1968,Score=>86,Title=>"Greetings"});
is($t1->get_row_count, 12);

undef $t1;

my $t2 = TableData::Munge::Filter->new(
    tabledata => 'Sample::DeNiro',
    filter_hashref => sub { my $row=shift; $row->{Score} >= 95 },
);
is($t2->get_column_count, 3);
is_deeply([$t2->get_column_names], [qw/Year Score Title/]);
$t2->reset_iterator;
is_deeply($t2->get_next_item, [1973,98,"Mean Streets"]);
is_deeply($t2->get_next_row_hashref , {Year=>1974,Score=>97,Title=>"The Godfather,Part II"});
$t2->reset_iterator;
is_deeply($t2->get_next_row_hashref , {Year=>1973,Score=>98,Title=>"Mean Streets"});
is($t2->get_row_count, 9);

done_testing;
