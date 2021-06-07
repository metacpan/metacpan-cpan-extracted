#!perl

use 5.010001;
use strict;
use warnings;
use Test::Exception;
use Test::More 0.98;

use TableData::Test::Spec::Basic;

my $table = TableData::Test::Spec::Basic->new;

subtest "has_next_item, has_next_row, get_next_item, get_next_row_arrayref, get_next_row_hashref, reset_iterator" => sub {
    #$table->reset_iterator;
    ok($table->has_next_item);
    is_deeply($table->get_next_item, [1,2]);
    ok($table->has_next_row);
    is_deeply($table->get_next_row_arrayref, [3,4]);
    ok($table->has_next_row);
    is_deeply($table->get_next_row_hashref, {a=>"5 2",b=>"6,2"});
    ok(!$table->has_next_row);
    dies_ok { $table->get_next_row_hashref };
    $table->reset_iterator;
    is_deeply($table->get_next_row_arrayref, [1,2]);
};

subtest "get_row_count, get_iterator_pos" => sub {
    $table->reset_iterator;
    is($table->get_iterator_pos, 0);
    is($table->get_row_count, 3);
};

subtest "get_all_items, get_all_rows_arrayref" => sub {
    is_deeply([$table->get_all_items], [
        [1,2],
        [3,4],
        ["5 2","6,2"],
    ]);
    is_deeply([$table->get_all_rows_arrayref], [
        [1,2],
        [3,4],
        ["5 2","6,2"],
    ]);
};

subtest get_all_rows_hashref => sub {
    is_deeply([$table->get_all_rows_hashref], [
        {a=>1,b=>2},
        {a=>3,b=>4},
        {a=>"5 2",b=>"6,2"},
    ]);
};

subtest "each_item, each_row_arrayref" => sub {
    my $row;
    $table->each_item(sub { $row //= $_[0] });
    is_deeply($row, [1,2]);
    undef $row;
    $table->each_row_arrayref(sub { $row //= $_[0] });
    is_deeply($row, [1,2]);
};

subtest each_row_hashref => sub {
    my $row;
    $table->each_row_hashref(sub { $row //= $_[0] });
    is_deeply($row, {a=>1,b=>2});
};

subtest get_column_count => sub {
    is($table->get_column_count, 2);
};

subtest get_column_names => sub {
    is_deeply(scalar($table->get_column_names), ["a","b"]);
    is_deeply([@{ $table->get_column_names }], ["a","b"]);
};

done_testing;
