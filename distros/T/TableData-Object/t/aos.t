#!perl

use 5.010;
use strict;
use warnings;

use TableData::Object qw(table);
use Test::Exception;
use Test::More 0.98;

my $td = table([1,4,2,10]);
ok($td->isa("TableData::Object::aos"), "isa");

is_deeply($td->cols_by_name, {elem=>0}, "cols_by_name");
is_deeply($td->cols_by_idx, ['elem'], "cols_by_idx");
is($td->row_count, 4, "row_count");
is($td->col_count, 1, "col_count");

subtest col_exists => sub {
    ok( $td->col_exists("elem"));
    ok(!$td->col_exists("value"));
};

subtest col_name => sub {
    is_deeply($td->col_name(0), "elem");
    is_deeply($td->col_name("value"), undef);
};

subtest col_idx => sub {
    is_deeply($td->col_idx(0), 0);
    is_deeply($td->col_idx("elem"), 0);
    is_deeply($td->col_idx("value"), undef);
};

subtest col_content => sub {
    is_deeply($td->col_content(0), [1,4,2,10]);
    is_deeply($td->col_content('elem'), [1,4,2,10]);
    is_deeply($td->col_content(1), undef);
    is_deeply($td->col_content('foo'), undef);
};

subtest row => sub {
    is_deeply($td->row(0), 1);
    is_deeply($td->row(1), 4);
    is_deeply($td->row(2), 2);
    is_deeply($td->row(3), 10);
    is_deeply($td->row(4), undef);
};

subtest row_as_aos => sub {
    is_deeply($td->row_as_aos(0), [1]);
    is_deeply($td->row_as_aos(1), [4]);
    is_deeply($td->row_as_aos(2), [2]);
    is_deeply($td->row_as_aos(3), [10]);
    is_deeply($td->row_as_aos(4), undef);
};

subtest row_as_hos => sub {
    is_deeply($td->row_as_hos(0), {elem=>1});
    is_deeply($td->row_as_hos(1), {elem=>4});
    is_deeply($td->row_as_hos(2), {elem=>2});
    is_deeply($td->row_as_hos(3), {elem=>10});
    is_deeply($td->row_as_hos(4), undef);
};

subtest rows => sub {
    is_deeply($td->rows, [1,4,2,10]);
};

subtest rows_as_aoaos => sub {
    is_deeply($td->rows_as_aoaos, [[1],[4],[2],[10]]);
};

subtest rows_as_aohos => sub {
    is_deeply($td->rows_as_aohos, [{elem=>1},{elem=>4},{elem=>2},{elem=>10}]);
};

subtest select => sub {
    my $td2;

    dies_ok { $td->select_as_aoaos(["foo"]) } "unknown column -> dies";

    $td2 = $td->select_as_aoaos();
    is_deeply($td2->rows_as_aoaos, [[1],[4],[2],[10]]);

    $td2 = $td->select_as_aoaos(['*']);
    is_deeply($td2->rows_as_aoaos, [[1],[4],[2],[10]]);

    $td2 = $td->select_as_aoaos(["elem", "elem"]);
    is_deeply($td2->rows_as_aoaos, [[1,1],[4,4],[2,2],[10,10]]);

    $td2 = $td->select_as_aohos(["elem", "elem"]);
    is_deeply($td2->rows_as_aohos, [{elem=>1,elem_2=>1},{elem=>4,elem_2=>4},{elem=>2,elem_2=>2},{elem=>10,elem_2=>10}]);

    # filter, exclude & sort
    dies_ok { $td->select_as_aoaos([], undef, ["foo"]) } "unknown sort column -> dies";
    $td2 = $td->select_as_aoaos(["elem"],
                                undef,
                                sub { my ($td, $row) = @_; $row->{elem} % 2 == 0 },
                                ["-elem"]);
    is_deeply($td2->rows_as_aoaos, [[10],[4],[2]]);
};

subtest uniq_col_names => sub {
    is_deeply([TableData::Object::aos->new([])->uniq_col_names], ['elem']);
    is_deeply([table([1])->uniq_col_names], ['elem']);
    is_deeply([table([undef])->const_col_names], ['elem'], 'undef');

    is_deeply([table([1,2])->uniq_col_names], ['elem']);
    is_deeply([table([1,undef])->uniq_col_names], [], 'has undef');
    is_deeply([table([1,1])->uniq_col_names], [], 'has duplicate values');
};

subtest const_col_names => sub {
    is_deeply([TableData::Object::aos->new([])->const_col_names], ['elem']);
    is_deeply([table([1])->const_col_names], ['elem']);
    is_deeply([table([undef])->const_col_names], ['elem'], 'undef');

    is_deeply([table([1,1])->const_col_names], ['elem']);
    is_deeply([table([1,undef])->const_col_names], [], 'has different values 1');
    is_deeply([table([1,2])->const_col_names], [], 'has different values 2');
};

subtest del_col => sub {
    my $td = table([1]);
    dies_ok { $td->del_col('elem') };
    dies_ok { $td->del_col(0) };
};

subtest rename_col => sub {
    my $td = table([1]);
    dies_ok { $td->rename_col('elem','elem') };
    dies_ok { $td->rename_col(0,0) };
};

subtest switch_cols => sub {
    my $td = table([1]);
    dies_ok { $td->switch_cols('elem', 'elem') };
};

subtest set_col_val => sub {
    my $td = table([1,2,3]);
    dies_ok { $td->set_col_val('foo', sub { 1 }) } "unknown column -> dies";

    $td->set_col_val('elem', sub { my %args = @_; $args{value}*2 });
    is_deeply($td->{data}, [2,4,6]);
};

DONE_TESTING:
done_testing;
