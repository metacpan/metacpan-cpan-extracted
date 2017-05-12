# perl
# t/002-getters.t - Tests of methods which get data out of object
use strict;
use warnings;
use Carp;
use utf8;

use lib ('./lib');
use Parse::Taxonomy::MaterializedPath;
use Test::More tests => 93;

my ($obj, $source, $expect);

{
    $source = "./t/data/alpha.csv";
    note($source);
    $obj = Parse::Taxonomy::MaterializedPath->new( {
        file    => $source,
    } );
    ok(defined $obj, "'new()' returned defined value");
    isa_ok($obj, 'Parse::Taxonomy::MaterializedPath');

    $expect = [ "path","nationality","gender","age","income","id_no" ];
    my $fields = $obj->fields;
    is(ref($fields), 'ARRAY', "'fields' method returned an arrayref");
    is_deeply($fields, $expect, "Got expected arrayref of columns");

    $expect = 0;
    my $path_col_idx = $obj->path_col_idx;
    is($path_col_idx, $expect, "Column with index '$expect' is path column");

    $expect = 'path';
    my $path_col = $obj->path_col;
    is($path_col, $expect, "Path column is named '$expect'");

    $expect = '|';
    my $path_col_sep = $obj->path_col_sep;
    is($path_col_sep, $expect, "Path column separator is '$expect'");

    my $data_records = $obj->data_records;
    is(ref($data_records), "ARRAY", "data_records() returned arrayref");
    my $is_array_ref = 1;
    for my $row (@{$data_records}) {
        if (ref($row) ne 'ARRAY') {
            $is_array_ref = 0;
            last;
        }
    }
    ok($is_array_ref, "Each row returned by data_records() is an array ref");
    my $path_record_well_formed = 1;
    for my $row (@{$data_records}) {
        my $path_component_count = grep { m/\Q$path_col_sep\E/ } $row->[$path_col_idx];
        if (! $path_component_count) {
            $path_record_well_formed = 0;
            last;
        }
    }
    ok($path_record_well_formed,
        "The path record in each row has expected path column separator ('$path_col_sep')");

    my $fields_and_data_records = $obj->fields_and_data_records();
    is_deeply($fields_and_data_records->[0], $fields,
        "First row in output of fields_and_data_records() appears to be taxonomy header");
    $is_array_ref = 1;
    for my $row (@{$fields_and_data_records}[1..$#{$fields_and_data_records}]) {
        if (ref($row) ne 'ARRAY') {
            $is_array_ref = 0;
            last;
        }
    }
    ok($is_array_ref, "Each data row returned by fields_and_data_records() is an array ref");
    $path_record_well_formed = 1;
    for my $row (@{$fields_and_data_records}[1..$#{$fields_and_data_records}]) {
        my $path_component_count = grep { m/\Q$path_col_sep\E/ } $row->[$path_col_idx];
        if (! $path_component_count) {
            $path_record_well_formed = 0;
            last;
        }
    }
    ok($path_record_well_formed,
        "The path record in each data row has expected path column separator ('$path_col_sep')");

    my $data_records_path_components = $obj->data_records_path_components;
    is(ref($data_records_path_components), "ARRAY", "data_records_path_components() returned arrayref");
    $is_array_ref = 1;
    for my $row (@{$data_records_path_components}) {
        if (ref($row) ne 'ARRAY') {
            $is_array_ref = 0;
            last;
        }
    }
    ok($is_array_ref, "Each row returned by data_records_path_components() is an array ref");
    $is_array_ref = 1;
    for my $row (@{$data_records_path_components}) {
        if (ref($data_records_path_components->[$obj->{path_col_idx}]) ne 'ARRAY') {
            $is_array_ref = 0;
            last;
        }
    }
    ok($is_array_ref,
        "Path column in each row returned by data_records_path_components() is now an array ref");

    my $fields_and_data_records_path_components = $obj->fields_and_data_records_path_components();
    is(ref($fields_and_data_records_path_components), "ARRAY",
        "fields_and_data_records_path_components() returned arrayref");
    is_deeply($fields_and_data_records_path_components->[0], $fields,
        "First row in output of fields_and_data_records_path_components() appears to be taxonomy header");
    $is_array_ref = 1;
    for my $row (@{$fields_and_data_records_path_components}[1..$#{$fields_and_data_records_path_components}]) {
        if (ref($row) ne 'ARRAY') {
            $is_array_ref = 0;
            last;
        }
    }
    ok($is_array_ref, "Each data row returned by fields_and_data_records_path_components() is an array ref");
    $is_array_ref = 1;
    for my $row (@{$fields_and_data_records_path_components}) {
        if (ref($fields_and_data_records_path_components->[$obj->{path_col_idx}]) ne 'ARRAY') {
            $is_array_ref = 0;
            last;
        }
    }
    ok($is_array_ref,
        "Path column in each row returned by fields_and_data_records_path_components() is now an array ref");

    {
        my ($descendant_counts, $expect);
        my $gen_count = 1;
        {
            local $@;
            eval {
                $descendant_counts =
                    $obj->descendant_counts( generations => $gen_count );
            };
            like($@, qr/^Argument to 'descendant_counts\(\)' must be hashref/,
                "'descendant_counts()' died to lack of hashref as argument; was just a key-value pair");
        }

        {
            local $@;
            eval {
                $descendant_counts =
                    $obj->descendant_counts( [ generations => $gen_count ] );
            };
            like($@, qr/^Argument to 'descendant_counts\(\)' must be hashref/,
                "'descendant_counts()' died to lack of hashref as argument; was arrayref");
        }

        {
            local $@;
            eval {
                $descendant_counts =
                    $obj->descendant_counts( { generations => 'foo' } );
            };
            like($@, qr/^Value for 'generations' element passed to descendant_counts\(\) must be integer > 0/,
                "'descendant_counts()' died to non-integer argument");
        }

        {
            local $@;
            eval {
                $descendant_counts =
                    $obj->descendant_counts( { generations => 0 } );
            };
            like($@, qr/^Value for 'generations' element passed to descendant_counts\(\) must be integer > 0/,
                "'descendant_counts()' died to argument 0");
        }

        $expect = {
          "|Alpha"               => 2,
          "|Alpha|Epsilon"       => 1,
          "|Alpha|Epsilon|Kappa" => 0,
          "|Alpha|Zeta"          => 2,
          "|Alpha|Zeta|Lambda"   => 0,
          "|Alpha|Zeta|Mu"       => 0,
          "|Beta"                => 2,
          "|Beta|Eta"            => 0,
          "|Beta|Theta"          => 0,
          "|Delta"               => 0,
          "|Gamma"               => 1,
          "|Gamma|Iota"          => 1,
          "|Gamma|Iota|Nu"       => 0,
        };
        $descendant_counts = $obj->descendant_counts( { generations => $gen_count } );
        is_deeply($descendant_counts, $expect,
            "Got expected descendant count for each node limited to $gen_count generation(s)");

        $expect = {
          "|Alpha"               => 5,
          "|Alpha|Epsilon"       => 1,
          "|Alpha|Epsilon|Kappa" => 0,
          "|Alpha|Zeta"          => 2,
          "|Alpha|Zeta|Lambda"   => 0,
          "|Alpha|Zeta|Mu"       => 0,
          "|Beta"                => 2,
          "|Beta|Eta"            => 0,
          "|Beta|Theta"          => 0,
          "|Delta"               => 0,
          "|Gamma"               => 2,
          "|Gamma|Iota"          => 1,
          "|Gamma|Iota|Nu"       => 0,
        };
        $descendant_counts = $obj->descendant_counts();
        is_deeply($descendant_counts, $expect, "Got expected descendant count for each node");
    }

    {
        my ($n, $node_descendant_count);

        local $@;
        $n = 'foo';
        eval { $node_descendant_count = $obj->get_descendant_count($n); };
        like($@, qr/Node '$n' not found/,
            "Argument '$n' to 'get_descendant_count' is not a node");
        local $@;

        $n = '|Gamma';
        $expect = 2;
        $node_descendant_count = $obj->get_descendant_count($n);
        is($node_descendant_count, $expect, "Node with $expect descendants found");

        $n = '|Gamma|Iota|Nu';
        $expect = 0;
        $node_descendant_count = $obj->get_descendant_count($n);
        is($node_descendant_count, $expect, "Node with $expect descendants -- leaf node -- found");
    }

    {
        $expect = 4;
        is($obj->get_field_position('income'), $expect,
            "'income' found in position $expect as expected");
        local $@;
        my $bad_field = 'foo';
        eval { $obj->get_field_position($bad_field); };
        like($@, qr/'$bad_field' not a field in this taxonomy/,
            "get_field_position() threw exception due to non-existent field");
    }

} 

{
    $source = "./t/data/alt_path_col_sep.csv";
    note($source);
    $obj = Parse::Taxonomy::MaterializedPath->new( {
        file            => $source,
        path_col_sep    => ',',
    } );
    ok(defined $obj, "'new()' returned defined value");
    isa_ok($obj, 'Parse::Taxonomy::MaterializedPath');

    $expect = [ "path","nationality","gender","age","income","id_no" ];
    my $fields = $obj->fields;
    is(ref($fields), 'ARRAY', "'fields' method returned an arrayref");
    is_deeply($fields, $expect, "Got expected arrayref of columns");

    $expect = 0;
    my $path_col_idx = $obj->path_col_idx;
    is($path_col_idx, $expect, "Column with index '$expect' is path column");

    $expect = 'path';
    my $path_col = $obj->path_col;
    is($path_col, $expect, "Path column is named '$expect'");

    $expect = ',';
    my $path_col_sep = $obj->path_col_sep;
    is($path_col_sep, $expect, "Path column separator is '$expect'");
}

{
    note("'components' interface");
    $obj = Parse::Taxonomy::MaterializedPath->new( {
        components => {
            fields          => ["path","nationality","gender","age","income","id_no"],
            data_records    => [
              ["|Alpha","","","","",""],
              ["|Alpha|Epsilon","","","","",""],
              ["|Alpha|Epsilon|Kappa","","","","",""],
              ["|Alpha|Zeta","","","","",""],
              ["|Alpha|Zeta|Lambda","","","","",""],
              ["|Alpha|Zeta|Mu","","","","",""],
              ["|Beta","","","","",""],
              ["|Beta|Eta","","","","",""],
              ["|Beta|Theta","","","","",""],
              ["|Gamma","","","","",""],
              ["|Gamma|Iota","","","","",""],
              ["|Gamma|Iota|Nu","","","","",""],
              ["|Delta","","","","",""],
            ],
        },
    } );
    ok(defined $obj, "'new()' returned defined value");
    isa_ok($obj, 'Parse::Taxonomy::MaterializedPath');

    $expect = [ "path","nationality","gender","age","income","id_no" ];
    my $fields = $obj->fields;
    is(ref($fields), 'ARRAY', "'fields' method returned an arrayref");
    is_deeply($fields, $expect, "Got expected arrayref of columns");

    $expect = 0;
    my $path_col_idx = $obj->path_col_idx;
    is($path_col_idx, $expect, "Column with index '$expect' is path column");

    $expect = 'path';
    my $path_col = $obj->path_col;
    is($path_col, $expect, "Path column is named '$expect'");

    $expect = '|';
    my $path_col_sep = $obj->path_col_sep;
    is($path_col_sep, $expect, "Path column separator is '$expect'");

    my $data_records = $obj->data_records;
    is(ref($data_records), "ARRAY", "data_records() returned arrayref");
    my $is_array_ref = 1;
    for my $row (@{$data_records}) {
        if (ref($row) ne 'ARRAY') {
            $is_array_ref = 0;
            last;
        }
    }
    ok($is_array_ref, "Each row returned by data_records() is an array ref");
    my $path_record_well_formed = 1;
    for my $row (@{$data_records}) {
        my $path_component_count = grep { m/\Q$path_col_sep\E/ } $row->[$path_col_idx];
        if (! $path_component_count) {
            $path_record_well_formed = 0;
            last;
        }
    }
    ok($path_record_well_formed,
        "The path record in each row has expected path column separator ('$path_col_sep')");

    my $fields_and_data_records = $obj->fields_and_data_records();
    is_deeply($fields_and_data_records->[0], $fields,
        "First row in output of fields_and_data_records() appears to be taxonomy header");
    $is_array_ref = 1;
    for my $row (@{$fields_and_data_records}[1..$#{$fields_and_data_records}]) {
        if (ref($row) ne 'ARRAY') {
            $is_array_ref = 0;
            last;
        }
    }
    ok($is_array_ref, "Each data row returned by fields_and_data_records() is an array ref");
    $path_record_well_formed = 1;
    for my $row (@{$fields_and_data_records}[1..$#{$fields_and_data_records}]) {
        my $path_component_count = grep { m/\Q$path_col_sep\E/ } $row->[$path_col_idx];
        if (! $path_component_count) {
            $path_record_well_formed = 0;
            last;
        }
    }
    ok($path_record_well_formed,
        "The path record in each data row has expected path column separator ('$path_col_sep')");

    my $data_records_path_components = $obj->data_records_path_components;
    is(ref($data_records_path_components), "ARRAY", "data_records_path_components() returned arrayref");
    $is_array_ref = 1;
    for my $row (@{$data_records_path_components}) {
        if (ref($row) ne 'ARRAY') {
            $is_array_ref = 0;
            last;
        }
    }
    ok($is_array_ref, "Each row returned by data_records_path_components() is an array ref");
    $is_array_ref = 1;
    for my $row (@{$data_records_path_components}) {
        if (ref($data_records_path_components->[$obj->{path_col_idx}]) ne 'ARRAY') {
            $is_array_ref = 0;
            last;
        }
    }
    ok($is_array_ref,
        "Path column in each row returned by data_records_path_components() is now an array ref");

    my $fields_and_data_records_path_components = $obj->fields_and_data_records_path_components();
    is(ref($fields_and_data_records_path_components), "ARRAY",
        "fields_and_data_records_path_components() returned arrayref");
    is_deeply($fields_and_data_records_path_components->[0], $fields,
        "First row in output of fields_and_data_records_path_components() appears to be taxonomy header");
    $is_array_ref = 1;
    for my $row (@{$fields_and_data_records_path_components}[1..$#{$fields_and_data_records_path_components}]) {
        if (ref($row) ne 'ARRAY') {
            $is_array_ref = 0;
            last;
        }
    }
    ok($is_array_ref, "Each data row returned by fields_and_data_records_path_components() is an array ref");
    $is_array_ref = 1;
    for my $row (@{$fields_and_data_records_path_components}) {
        if (ref($fields_and_data_records_path_components->[$obj->{path_col_idx}]) ne 'ARRAY') {
            $is_array_ref = 0;
            last;
        }
    }
    ok($is_array_ref,
        "Path column in each row returned by fields_and_data_records_path_components() is now an array ref");

    $expect = {
      "|Alpha"               => 5,
      "|Alpha|Epsilon"       => 1,
      "|Alpha|Epsilon|Kappa" => 0,
      "|Alpha|Zeta"          => 2,
      "|Alpha|Zeta|Lambda"   => 0,
      "|Alpha|Zeta|Mu"       => 0,
      "|Beta"                => 2,
      "|Beta|Eta"            => 0,
      "|Beta|Theta"          => 0,
      "|Delta"               => 0,
      "|Gamma"               => 2,
      "|Gamma|Iota"          => 1,
      "|Gamma|Iota|Nu"       => 0,
    };
    my $descendant_counts = $obj->descendant_counts();
    is_deeply($descendant_counts, $expect, "Got expected descendant count for each node");

    {
        my ($n, $node_descendant_count);

        local $@;
        $n = 'foo';
        eval { $node_descendant_count = $obj->get_descendant_count($n); };
        like($@, qr/Node '$n' not found/,
            "Argument '$n' to 'get_descendant_count' is not a node");
        local $@;

        $n = '|Gamma';
        $expect = 2;
        $node_descendant_count = $obj->get_descendant_count($n);
        is($node_descendant_count, $expect, "Node with $expect descendants found");

        $n = '|Gamma|Iota|Nu';
        $expect = 0;
        $node_descendant_count = $obj->get_descendant_count($n);
        is($node_descendant_count, $expect, "Node with $expect descendants -- leaf node -- found");
    }
} 

{
    note("'components' interface; alternate path_col_sep");
    $obj = Parse::Taxonomy::MaterializedPath->new( {
        components => {
            fields          => ["path","nationality","gender","age","income","id_no"],
            data_records    => [
              [",Alpha","","","","",""],
              [",Alpha,Epsilon","","","","",""],
              [",Alpha,Epsilon,Kappa","","","","",""],
              [",Alpha,Zeta","","","","",""],
              [",Alpha,Zeta,Lambda","","","","",""],
              [",Alpha,Zeta,Mu","","","","",""],
              [",Beta","","","","",""],
              [",Beta,Eta","","","","",""],
              [",Beta,Theta","","","","",""],
              [",Gamma","","","","",""],
              [",Gamma,Iota","","","","",""],
              [",Gamma,Iota,Nu","","","","",""],
              [",Delta","","","","",""],
            ],
        },
        path_col_sep    => ',',
    } );
    ok(defined $obj, "'new()' returned defined value");
    isa_ok($obj, 'Parse::Taxonomy::MaterializedPath');

    $expect = [ "path","nationality","gender","age","income","id_no" ];
    my $fields = $obj->fields;
    is(ref($fields), 'ARRAY', "'fields' method returned an arrayref");
    is_deeply($fields, $expect, "Got expected arrayref of columns");

    $expect = 0;
    my $path_col_idx = $obj->path_col_idx;
    is($path_col_idx, $expect, "Column with index '$expect' is path column");

    $expect = 'path';
    my $path_col = $obj->path_col;
    is($path_col, $expect, "Path column is named '$expect'");

    $expect = ',';
    my $path_col_sep = $obj->path_col_sep;
    is($path_col_sep, $expect, "Path column separator is '$expect'");
}

{
    note("Test free-standing get_descendant_count()");
    my ($obj, $source, $expect);

    $source = "./t/data/alpha.csv";
    note($source);
    $obj = Parse::Taxonomy::MaterializedPath->new( {
        file    => $source,
    } );
    ok(defined $obj, "'new()' returned defined value");
    isa_ok($obj, 'Parse::Taxonomy::MaterializedPath');

    my ($n, $node_descendant_count);

    {
        local $@;
        $n = 'foo';
        eval { $node_descendant_count = $obj->get_descendant_count($n); };
        like($@, qr/Node '$n' not found/,
            "Argument '$n' to 'get_descendant_count' is not a node");
    }

    $n = '|Gamma';
    $expect = 2;
    $node_descendant_count = $obj->get_descendant_count($n);
    is($node_descendant_count, $expect, "Node with $expect descendants found");

    $n = '|Gamma|Iota|Nu';
    $expect = 0;
    $node_descendant_count = $obj->get_descendant_count($n);
    is($node_descendant_count, $expect, "Node with $expect descendants -- leaf node -- found");

    {
        local $@;
        eval {
            $node_descendant_count =
                $obj->get_descendant_count($n, generations => 1 );
        };
        like($@, qr/^Second argument to 'get_descendant_count\(\)' must be hashref/,
            "'get_descendant_count()' died to lack of hashref as second argument; was just a key-value pair");
    }

    {
        local $@;
        eval {
            $node_descendant_count =
                $obj->get_descendant_count($n, [ generations => 1 ] );
        };
        like($@, qr/^Second argument to 'get_descendant_count\(\)' must be hashref/,
            "'get_descendant_count()' died to lack of hashref as second argument; was arrayref");
    }

    {
        local $@;
        eval {
            $node_descendant_count =
                $obj->get_descendant_count($n, { generations => 'foo' } );
        };
        like($@, qr/^Value for 'generations' element passed to second argument to get_descendant_count\(\) must be integer > 0/,
            "'get_descendant_count()' died to non-integer as value in second argument");
    }

    {
        local $@;
        eval {
            $node_descendant_count =
                $obj->get_descendant_count($n, { generations => 0 } );
        };
        like($@, qr/^Value for 'generations' element passed to second argument to get_descendant_count\(\) must be integer > 0/,
            "'get_descendant_count()' died to 0 as value in second argument");
    }

    my $gen_count = 1;

    $n = '|Alpha';
    $expect = 2;
    $node_descendant_count = $obj->get_descendant_count($n, { generations => $gen_count } );
    is($node_descendant_count, $expect, "Node '$n', limited to $gen_count generation(s):  $expect descendants found");

    $n = '|Alpha|Epsilon';
    $expect = 1;
    $node_descendant_count = $obj->get_descendant_count($n, { generations => $gen_count } );
    is($node_descendant_count, $expect, "Node '$n', limited to $gen_count generation(s):  $expect descendants found");

    $n = '|Alpha|Epsilon|Kappa';
    $expect = 0;
    $node_descendant_count = $obj->get_descendant_count($n, { generations => $gen_count } );
    is($node_descendant_count, $expect, "Node '$n', limited to $gen_count generation(s):  $expect descendants found");

    $n = '|Beta';
    $expect = 2;
    $node_descendant_count = $obj->get_descendant_count($n, { generations => $gen_count } );
    is($node_descendant_count, $expect, "Node '$n', limited to $gen_count generation(s):  $expect descendants found");

    $n = '|Beta|Eta';
    $expect = 0;
    $node_descendant_count = $obj->get_descendant_count($n, { generations => $gen_count } );
    is($node_descendant_count, $expect, "Node '$n', limited to $gen_count generation(s):  $expect descendants found");

    $n = '|Beta|Theta';
    $expect = 0;
    $node_descendant_count = $obj->get_descendant_count($n, { generations => $gen_count } );
    is($node_descendant_count, $expect, "Node '$n', limited to $gen_count generation(s):  $expect descendants found");

    $n = '|Delta';
    $expect = 0;
    $node_descendant_count = $obj->get_descendant_count($n, { generations => $gen_count } );
    is($node_descendant_count, $expect, "Node '$n', limited to $gen_count generation(s):  $expect descendants found");
}

{
    note("Test a file with more segments in path");
    $source = "./t/data/gamma.csv";
    note($source);
    $obj = Parse::Taxonomy::MaterializedPath->new( {
        file    => $source,
    } );
    ok(defined $obj, "'new()' returned defined value");
    isa_ok($obj, 'Parse::Taxonomy::MaterializedPath');

    my ($n, $gen_count, $expect, $node_descendant_count);

    $n = '|Omicron';
    $expect = 5;
    $node_descendant_count = $obj->get_descendant_count($n);
    is($node_descendant_count, $expect, "Node '$n': $expect descendants found");

    $gen_count = 1;
    $expect = 1;
    $node_descendant_count = $obj->get_descendant_count($n, { generations => $gen_count } );
    is($node_descendant_count, $expect, "Node '$n', limited to $gen_count generation(s): $expect descendants found");

    $gen_count = 3;
    $expect = 4;
    $node_descendant_count = $obj->get_descendant_count($n, { generations => $gen_count } );
    is($node_descendant_count, $expect, "Node '$n', limited to $gen_count generation(s): $expect descendants found");

    $gen_count = 4;
    $expect = 5;
    $node_descendant_count = $obj->get_descendant_count($n, { generations => $gen_count } );
    is($node_descendant_count, $expect, "Node '$n', limited to $gen_count generation(s): $expect descendants found");

    $n = '|Omicron|Pi|Rho';
    $expect = 3;
    $node_descendant_count = $obj->get_descendant_count($n);
    is($node_descendant_count, $expect, "Node '$n': $expect descendants found");

    $gen_count = 1;
    $expect = 2;
    $node_descendant_count = $obj->get_descendant_count($n, { generations => $gen_count } );
    is($node_descendant_count, $expect, "Node '$n', limited to $gen_count generation(s): $expect descendants found");

}

