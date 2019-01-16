#!perl

use 5.010;
use strict;
use warnings;

use TableData::Object qw(table);
use Test::Exception;
use Test::More 0.98;

my $td = table([[1,2],[5,6],[3,4]]);
ok($td->isa("TableData::Object::aoaos"), "isa");

is_deeply($td->cols_by_name, {column0=>0, column1=>1}, "cols_by_name");
is_deeply($td->cols_by_idx, ['column0','column1'], "cols_by_idx");
is($td->row_count, 3, "row_count");
is($td->col_count, 2, "col_count");

my $tds = table([[1,2],[5,6],[3,4]],
                {fields=>{satu=>{schema=>"int",pos=>0},
                          dua=>{schema=>"float",pos=>1}}});
subtest "with spec" => sub {
    is_deeply($tds->cols_by_name, {satu=>0, dua=>1}, "cols_by_name");
    is_deeply($tds->cols_by_idx, ['satu','dua'], "cols_by_idx");
};

subtest col_exists => sub {
    ok( $td->col_exists("column0"));
    ok( $td->col_exists("column1"));
    ok(!$td->col_exists("column2"));
};

subtest col_name => sub {
    is_deeply($td->col_name(0), "column0");
    is_deeply($td->col_name("column1"), "column1");
    is_deeply($td->col_name("column2"), undef);
};

subtest col_idx => sub {
    is_deeply($td->col_idx(0), 0);
    is_deeply($td->col_idx("column1"), 1);
    is_deeply($td->col_idx("column2"), undef);
};

subtest rows_as_aoaos => sub {
    is_deeply($td->rows_as_aoaos, [[1,2],[5,6],[3,4]]);
};

subtest rows_as_aohos => sub {
    is_deeply($td->rows_as_aohos, [{column0=>1,column1=>2},{column0=>5,column1=>6},{column0=>3,column1=>4}]);
};

subtest select => sub {
    my $td2;

    dies_ok { $td->select_as_aoaos(["foo"]) } "unknown column -> dies";

    $td2 = $td->select_as_aoaos();
    is_deeply($td2->rows_as_aoaos, [[1,2],[5,6],[3,4]]);

    $td2 = $td->select_as_aoaos(["*"]);
    is_deeply($td2->rows_as_aoaos, [[1,2],[5,6],[3,4]]);

    $td2 = $td->select_as_aoaos(["column1","column0","column1"]);
    is_deeply($td2->rows_as_aoaos, [[2,1,2],[6,5,6],[4,3,4]]);

    $td2 = $td->select_as_aohos(["column1","column0","column1"]);
    is_deeply($td2->rows_as_aohos, [{column1=>2, column0=>1, column1_2=>2},{column1=>6, column0=>5, column1_2=>6},{column1=>4, column0=>3, column1_2=>4}]);

    # filter, exclude & sort
    dies_ok { $td->select_as_aoaos([], undef, ["foo"]) } "unknown sort column -> dies";
    $td2 = $td->select_as_aoaos(["column1","column0"],
                                ["column0"],
                                sub { my ($td, $row) = @_; $row->{column0} > 1 },
                                ["-column1"]);
    is_deeply($td2->rows_as_aoaos, [[6],[4]]);
};

subtest uniq_col_names => sub {
    is_deeply([TableData::Object::aoaos->new([])->uniq_col_names], []);
    is_deeply([table([
        [1,1,undef],
        [2,2,undef,3],
        [2,3,undef,4],
    ])->uniq_col_names], ["column1"]);
};

subtest const_col_names => sub {
    is_deeply([TableData::Object::aoaos->new([])->const_col_names], []);
    is_deeply([table([
        [1,2,undef],
        [2,2,undef,3],
        [2,2,undef,3],
    ])->const_col_names], ["column1","column2"]);
};

subtest del_col => sub {
    my $td = table(
        [[1,2,3], [4,5,6], [7,8,9]],
        {
            fields => {
                column0 => {pos=>0},
                column1 => {pos=>1},
                column2 => {pos=>2},
            },
        },
    );

    is_deeply($td->del_col('foo'), undef);

    is_deeply($td->del_col('column0'), 'column0');
    is_deeply($td->cols_by_name, {column1=>0, column2=>1});
    is_deeply($td->cols_by_idx, ['column1','column2']);
    is_deeply($td->{spec}{fields}, {column1=>{pos=>0}, column2=>{pos=>1}});
    is_deeply($td->{data}, [[2,3], [5,6], [8,9]]);

    is_deeply($td->del_col(1), 'column2');
    is_deeply($td->cols_by_name, {column1=>0});
    is_deeply($td->cols_by_idx, ['column1']);
    is_deeply($td->{spec}{fields}, {column1=>{pos=>0}});
    is_deeply($td->{data}, [[2], [5], [8]]);

    is_deeply($td->del_col(0), 'column1');
    is_deeply($td->cols_by_name, {});
    is_deeply($td->cols_by_idx, []);
    is_deeply($td->{spec}{fields}, {});
    is_deeply($td->{data}, [[], [], []]);
};

subtest rename_col => sub {
    my $td = table(
        [[1,2,3], [4,5,6], [7,8,9]],
        {
            fields => {
                column0 => {pos=>0},
                column1 => {pos=>1},
                column2 => {pos=>2},
            },
        },
    );

    dies_ok { $td->rename_col('foo', 'bar') }
        "rename unknown column -> dies";

    dies_ok { $td->rename_col('column0', '12') }
        "new column name must not be a number";

    lives_ok { $td->rename_col('column0', 'column0') }
        "rename column to itself -> no-op";

    $td->rename_col('column0', 'column9');
    is_deeply($td->cols_by_name, {column9=>0, column1=>1, column2=>2});
    is_deeply($td->cols_by_idx, ['column9', 'column1','column2']);
    is_deeply($td->{spec}{fields}, {column9=>{pos=>0}, column1=>{pos=>1}, column2=>{pos=>2}});
    is_deeply($td->{data}, [[1,2,3], [4,5,6], [7,8,9]]);
};

subtest switch_cols => sub {
    my $td = table(
        [[1,2,3], [4,5,6], [7,8,9]],
        {
            fields => {
                column0 => {pos=>0},
                column1 => {pos=>1},
                column2 => {pos=>2},
            },
        },
    );

    dies_ok { $td->switch_cols('foo', 'column1') }
        "switch unknown column 1 -> dies";
    dies_ok { $td->switch_cols('column1', 'foo') }
        "switch unknown column 2 -> dies";

    lives_ok { $td->switch_cols('column0', '0') }
        "switch the same column -> no-op";

    $td->switch_cols('column0', 'column2');
    is_deeply($td->cols_by_name, {column2=>0, column1=>1, column0=>2});
    is_deeply($td->cols_by_idx, ['column2', 'column1','column0']);
    is_deeply($td->{spec}{fields}, {column2=>{pos=>0}, column1=>{pos=>1}, column0=>{pos=>2}});
    is_deeply($td->{data}, [[1,2,3], [4,5,6], [7,8,9]]);
};

subtest add_col => sub {
    my $td = table(
        [[1,2,3], [4,5,6], [7,8,9]],
        {
            fields => {
                column0 => {pos=>0},
                column1 => {pos=>1},
                column2 => {pos=>2},
            },
        },
    );
    dies_ok { $td->add_col('foo', -1) }
        "idx < 0 -> dies";
    dies_ok { $td->add_col('foo', 4) }
        "idx > row count -> dies";
    dies_ok { $td->add_col('column0') }
        "add existing column -> dies";

    $td->add_col('foo', 1);
    is_deeply($td->{cols_by_idx} , ["column0", "foo", "column1", "column2"]);
    is_deeply($td->{cols_by_name}, {column0=>0, foo=>1, column1=>2, column2=>3});
    is_deeply($td->{spec}, {
        fields => {
            column0 => {pos=>0},
            foo     => {pos=>1},
            column1 => {pos=>2},
            column2 => {pos=>3},
        },
    });
    is_deeply($td->{data}[0], [1,undef,2,3]);

    $td->add_col('bar');
    is_deeply($td->{cols_by_idx} , ["column0", "foo", "column1", "column2", "bar"]);
    is_deeply($td->{cols_by_name}, {column0=>0, foo=>1, column1=>2, column2=>3, bar=>4});
    is_deeply($td->{data}[1], [4,undef,5,6,undef]);
};

subtest set_col_val => sub {
    my $td = table([[1,2,3],[4,5,6]]);
    dies_ok { $td->set_col_val('foo', sub { 1 }) } "unknown column -> dies";

    $td->set_col_val('column1', sub { my %args = @_; $args{value}*2 });
    is_deeply($td->{data}[0], [1,4,3]);
    is_deeply($td->{data}[1], [4,10,6]);
};

DONE_TESTING:
done_testing;
