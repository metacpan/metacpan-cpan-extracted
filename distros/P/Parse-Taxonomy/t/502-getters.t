# perl
# t/502-getters.t - Tests of methods which get data out of object
use strict;
use warnings;
use Carp;
use utf8;

use lib ('./lib');
use Parse::Taxonomy::AdjacentList;
use Test::More qw(no_plan); # tests => 12;

my ($obj, $source, $expect);
my ($exp_fields, $exp_data_records);

{
    $source = "./t/data/delta.csv";
    note($source);
    $obj = Parse::Taxonomy::AdjacentList->new( {
        file    => $source,
    } );
    ok(defined $obj, "new() returned defined value");
    isa_ok($obj, 'Parse::Taxonomy::AdjacentList');

    $exp_fields = ["id","parent_id","name","vertical","currency_code","wholesale_price","retail_price","is_actionable"];
    is_deeply($obj->fields, $exp_fields, "Got expected columns");
    $exp_data_records = [
        [1, "", "Alpha", "Auto", "USD", "", "", 0],
        [3, 1, "Epsilon", "Auto", "USD", "", "", 0],
        [4, 3, "Kappa", "Auto", "USD", "0.50", "0.60", 1],
        [5, 1, "Zeta", "Auto", "USD", "", "", 0],
        [6, 5, "Lambda", "Auto", "USD", "0.40", "0.50", 1],
        [7, 5, "Mu", "Auto", "USD", "0.40", "0.50", 0],
        [2, "", "Beta", "Electronics", "JPY", "", "", 0],
        [8, 2, "Eta", "Electronics", "JPY", 0.35, 0.45, 1],
        [9, 2, "Theta", "Electronics", "JPY", 0.35, 0.45, 1],
        [10, "", "Gamma", "Travel", "EUR", "", "", 0],
        [11, 10, "Iota", "Travel", "EUR", "", "", 0],
        [12, 11, "Nu", "Travel", "EUR", "0.60", 0.75, 1],
        [13, "", "Delta", "Life Insurance", "USD", 0.25, "0.30", 1],
    ];
    is_deeply($obj->data_records, $exp_data_records, "Got expected data records");

    $expect = [
        $exp_fields,
        @{$exp_data_records},
    ];
    is_deeply($obj->fields_and_data_records, $expect, "Got expected fields and data records");

    $expect = 4;
    is($obj->get_field_position('currency_code'), $expect,
        "'income' found in position $expect as expected");
    local $@;
    my $bad_field = 'foo';
    eval { $obj->get_field_position($bad_field); };
    like($@, qr/'$bad_field' not a field in this taxonomy/,
        "get_field_position() threw exception due to non-existent field");

    $expect = 0;
    is($obj->id_col_idx, $expect, "Got expected index of 'id' column");
    $expect = 'id';
    is($obj->id_col, $expect, "Got expected name of 'id' column");
    $expect = 1;
    is($obj->parent_id_col_idx, $expect, "Got expected index of 'parent_id' column");
    $expect = 'parent_id';
    is($obj->parent_id_col, $expect, "Got expected name of 'parent_id' column");
    $expect = 2;
    is($obj->leaf_col_idx, $expect, "Got expected index of 'leaf' column");
    $expect = 'name';
    is($obj->leaf_col, $expect, "Got expected name of 'leaf' column");
}

{
    $source = "./t/data/zeta.csv";
    note($source);
    $obj = Parse::Taxonomy::AdjacentList->new( {
        file                => $source,
        id_col              => 'my_id',
        parent_id_col       => 'my_parent_id',
        leaf_col            => 'my_name',
    } );
    ok(defined $obj, "new() returned defined value");
    isa_ok($obj, 'Parse::Taxonomy::AdjacentList');

    $exp_fields = ["my_id","my_parent_id","my_name","vertical","currency_code","wholesale_price","retail_price","is_actionable"];
    is_deeply($obj->fields, $exp_fields, "Got expected columns");
    $exp_data_records = [
        [1, "", "Alpha", "Auto", "USD", "", "", 0],
        [3, 1, "Epsilon", "Auto", "USD", "", "", 0],
        [4, 3, "Kappa", "Auto", "USD", "0.50", "0.60", 1],
        [5, 1, "Zeta", "Auto", "USD", "", "", 0],
        [6, 5, "Lambda", "Auto", "USD", "0.40", "0.50", 1],
        [7, 5, "Mu", "Auto", "USD", "0.40", "0.50", 0],
        [2, "", "Beta", "Electronics", "JPY", "", "", 0],
        [8, 2, "Eta", "Electronics", "JPY", 0.35, 0.45, 1],
        [9, 2, "Theta", "Electronics", "JPY", 0.35, 0.45, 1],
        [10, "", "Gamma", "Travel", "EUR", "", "", 0],
        [11, 10, "Iota", "Travel", "EUR", "", "", 0],
        [12, 11, "Nu", "Travel", "EUR", "0.60", 0.75, 1],
        [13, "", "Delta", "Life Insurance", "USD", 0.25, "0.30", 1],
    ];
    is_deeply($obj->data_records, $exp_data_records, "Got expected data records");
    $expect = [
        $exp_fields,
        @{$exp_data_records},
    ];
    is_deeply($obj->fields_and_data_records, $expect, "Got expected fields and data records");

    $expect = 0;
    is($obj->id_col_idx, $expect, "Got expected index of 'id' column");
    $expect = 'my_id';
    is($obj->id_col, $expect, "Got expected name of 'id' column");
    $expect = 1;
    is($obj->parent_id_col_idx, $expect, "Got expected index of 'parent_id' column");
    $expect = 'my_parent_id';
    is($obj->parent_id_col, $expect, "Got expected name of 'parent_id' column");
    $expect = 2;
    is($obj->leaf_col_idx, $expect, "Got expected index of 'leaf' column");
    $expect = 'my_name';
    is($obj->leaf_col, $expect, "Got expected name of 'leaf' column");
}

{
    note("'components' interface");
    $exp_fields = ["id","parent_id","name","vertical","currency_code","wholesale_price","retail_price","is_actionable"];
    $exp_data_records    = [
        ["1","","Alpha","Auto","USD","","","0"],
        ["3","1","Epsilon","Auto","USD","","","0"],
        ["4","3","Kappa","Auto","USD","0.50","0.60","1"],
        ["5","1","Zeta","Auto","USD","","","0"],
        ["6","5","Lambda","Auto","USD","0.40","0.50","1"],
        ["7","5","Mu","Auto","USD","0.40","0.50","0"],
        ["2","","Beta","Electronics","JPY","","","0"],
        ["8","2","Eta","Electronics","JPY","0.35","0.45","1"],
        ["9","2","Theta","Electronics","JPY","0.35","0.45","1"],
        ["10","","Gamma","Travel","EUR","","","0"],
        ["11","10","Iota","Travel","EUR","","","0"],
        ["12","11","Nu","Travel","EUR","0.60","0.75","1"],
        ["13","","Delta","Life Insurance","USD","0.25","0.30","1"],
    ];
    $obj = Parse::Taxonomy::AdjacentList->new( {
        components => {
            fields => $exp_fields,
            data_records => $exp_data_records,
        },
    } );
    ok(defined $obj, "new() returned defined value");
    isa_ok($obj, 'Parse::Taxonomy::AdjacentList');

    is_deeply($obj->fields, $exp_fields, "Got expected columns");
    is_deeply($obj->data_records, $exp_data_records, "Got expected data records");
    $expect = [
        $exp_fields,
        @{$exp_data_records},
    ];
    is_deeply($obj->fields_and_data_records, $expect, "Got expected fields and data records");

    $expect = 0;
    is($obj->id_col_idx, $expect, "Got expected index of 'id' column");
    $expect = 'id';
    is($obj->id_col, $expect, "Got expected name of 'id' column");
    $expect = 1;
    is($obj->parent_id_col_idx, $expect, "Got expected index of 'parent_id' column");
    $expect = 'parent_id';
    is($obj->parent_id_col, $expect, "Got expected name of 'parent_id' column");
    $expect = 2;
    is($obj->leaf_col_idx, $expect, "Got expected index of 'leaf' column");
    $expect = 'name';
    is($obj->leaf_col, $expect, "Got expected name of 'leaf' column");
}

{
    note("'components' interface; user-supplied column names");
    $exp_fields = ["my_id","my_parent_id","my_name","vertical","currency_code","wholesale_price","retail_price","is_actionable"];
    $exp_data_records = [
        ["1","","Alpha","Auto","USD","","","0"],
        ["3","1","Epsilon","Auto","USD","","","0"],
        ["4","3","Kappa","Auto","USD","0.50","0.60","1"],
        ["5","1","Zeta","Auto","USD","","","0"],
        ["6","5","Lambda","Auto","USD","0.40","0.50","1"],
        ["7","5","Mu","Auto","USD","0.40","0.50","0"],
        ["2","","Beta","Electronics","JPY","","","0"],
        ["8","2","Eta","Electronics","JPY","0.35","0.45","1"],
        ["9","2","Theta","Electronics","JPY","0.35","0.45","1"],
        ["10","","Gamma","Travel","EUR","","","0"],
        ["11","10","Iota","Travel","EUR","","","0"],
        ["12","11","Nu","Travel","EUR","0.60","0.75","1"],
        ["13","","Delta","Life Insurance","USD","0.25","0.30","1"],
    ];
    $obj = Parse::Taxonomy::AdjacentList->new( {
        components => {
            fields => $exp_fields,
            data_records => $exp_data_records,
        },
        id_col              => 'my_id',
        parent_id_col       => 'my_parent_id',
        leaf_col            => 'my_name',
    } );
    ok(defined $obj, "new() returned defined value");
    isa_ok($obj, 'Parse::Taxonomy::AdjacentList');

    is_deeply($obj->fields, $exp_fields, "Got expected columns");
    is_deeply($obj->data_records, $exp_data_records, "Got expected data records");
    $expect = [
        $exp_fields,
        @{$exp_data_records},
    ];
    is_deeply($obj->fields_and_data_records, $expect, "Got expected fields and data records");

    $expect = 0;
    is($obj->id_col_idx, $expect, "Got expected index of 'id' column");
    $expect = 'my_id';
    is($obj->id_col, $expect, "Got expected name of 'id' column");
    $expect = 1;
    is($obj->parent_id_col_idx, $expect, "Got expected index of 'parent_id' column");
    $expect = 'my_parent_id';
    is($obj->parent_id_col, $expect, "Got expected name of 'parent_id' column");
    $expect = 2;
    is($obj->leaf_col_idx, $expect, "Got expected index of 'leaf' column");
    $expect = 'my_name';
    is($obj->leaf_col, $expect, "Got expected name of 'leaf' column");
}

