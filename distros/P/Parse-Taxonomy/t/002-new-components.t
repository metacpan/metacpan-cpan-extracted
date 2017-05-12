# perl
# t/002-new-components.t - Tests of constructor's 'components' interface
use strict;
use warnings;
use Carp;
use utf8;

use lib ('./lib');
use Parse::Taxonomy::MaterializedPath;
use Test::More tests => 37;
use Scalar::Util qw( reftype );

my ($obj, $source, $fields, $data_records);

note("'components' interface to 'new()'");
$fields = ["path", "nationality", "gender", "age", "income", "id_no"];
$data_records = [
    ["|Alpha", "", "", "", "", ""],
    ["|Alpha|Epsilon", "", "", "", "", ""],
    ["|Alpha|Epsilon|Kappa", "", "", "", "", ""],
    ["|Alpha|Zeta", "", "", "", "", ""],
    ["|Alpha|Zeta|Lambda", "", "", "", "", ""],
    ["|Alpha|Zeta|Mu", "", "", "", "", ""],
    ["|Beta", "", "", "", "", ""],
    ["|Beta|Eta", "", "", "", "", ""],
    ["|Beta|Theta", "", "", "", "", ""],
    ["|Gamma", "", "", "", "", ""],
    ["|Gamma|Iota", "", "", "", "", ""],
    ["|Gamma|Iota|Nu", "", "", "", "", ""],
    ["|Delta", "", "", "", "", ""],
];

{
    local $@;
    $source = "./t/data/alpha.csv";
    eval {
        $obj = Parse::Taxonomy::MaterializedPath->new( {
            file        => $source,
            components  => {
                fields          => $fields,
                data_records    => $data_records,
            }
        } );
    };
    like($@,
        qr/Argument to 'new\(\)' must have either 'file' or 'components' element but not both/,
        "'new()' failed: cannot supply both 'file' and 'components' elements in arguments");
}

{
    local $@;
    eval {
        $obj = Parse::Taxonomy::MaterializedPath->new( {
            components  => [
                fields          => $fields,
                data_records    => $data_records,
            ]
        } );
    };
    like($@,
        qr/Value of 'components' element must be hashref/,
        "'new()' failed: value of 'components' element must be hash ref");
}

{
    local $@;
    eval {
        $obj = Parse::Taxonomy::MaterializedPath->new( {
            components  => 'foo',
        } );
    };
    like($@,
        qr/Value of 'components' element must be hashref/,
        "'new()' failed: value of 'components' element must be hash ref");
}

{
    local $@;
    eval {
        $obj = Parse::Taxonomy::MaterializedPath->new( {
            components  => {
                data_records    => $data_records,
            }
        } );
    };
    like($@, qr/Value of 'components' element must have 'fields' key-value pair/,
        "'new()' failed: 'components' element lacked 'fields' element");
}

{
    local $@;
    eval {
        $obj = Parse::Taxonomy::MaterializedPath->new( {
            components  => {
                fields    => $fields,
            }
        } );
    };
    like($@, qr/Value of 'components' element must have 'data_records' key-value pair/,
        "'new()' failed: 'components' element lacked 'data_records' element");
}

{
    local $@;
    eval {
        $obj = Parse::Taxonomy::MaterializedPath->new( {
            components  => {
                fields          => 'foo',
                data_records    => $data_records,
            }
        } );
    };
    like($@,
        qr/Value of 'fields' element must be arrayref/,
        "'new()' failed: value of 'fields' element must be array ref");
}

{
    local $@;
    eval {
        $obj = Parse::Taxonomy::MaterializedPath->new( {
            components  => {
                fields          => { hash => ref},
                data_records    => $data_records,
            }
        } );
    };
    like($@,
        qr/Value of 'fields' element must be arrayref/,
        "'new()' failed: value of 'fields' element must be array ref");
}

{
    local $@;
    eval {
        $obj = Parse::Taxonomy::MaterializedPath->new( {
            components  => {
                fields          => $fields,
                data_records    => { my => $data_records },
            }
        } );
    };
    like($@,
        qr/Value of 'data_records' element must be arrayref/,
        "'new()' failed: value of 'data_records' element must be array ref");
}

{
    local $@;
    eval {
        $obj = Parse::Taxonomy::MaterializedPath->new( {
            components  => {
                fields          => $fields,
                data_records    => [
                    [",Alpha", "", "", "", "", ""],
                    'foo'
                ],
            }
        } );
    };
    like($@,
        qr/Each element in 'data_records' array must be arrayref/,
        "'new()' failed: element in array 'data_records' element must be array ref");
}

{
    local $@;
    eval {
        $obj = Parse::Taxonomy::MaterializedPath->new( {
            components  => {
                fields          => $fields,
                data_records    => [
                    [",Alpha", "", "", "", "", ""],
                    { foo => 'bar' },
                ],
            }
        } );
    };
    like($@,
        qr/Each element in 'data_records' array must be arrayref/,
        "'new()' failed: element in array 'data_records' element must be array ref");
}

{
    local $@;
    eval {
        $obj = Parse::Taxonomy::MaterializedPath->new( {
            components  => {
                fields          => $fields,
                data_records    => $data_records,
            },
            path_col_idx    => 6,
        } );
    };
    like($@, qr/Argument to 'path_col_idx' exceeds index of last field in 'fields' array ref/,
        "'new()' died due to 'path_col_idx' higher than last index in 'fields' arrayref");
}

{
    local $@;
    my $dupe_field = 'gender';
    eval {
        $obj = Parse::Taxonomy::MaterializedPath->new( {
            components  => {
                fields        => [ "path","nationality",$dupe_field,"age",$dupe_field,"id_no" ],
                data_records  => $data_records,
            },
        } );
    };
    like($@, qr/^Duplicate field '$dupe_field' observed in 'fields' array ref/,
        "'new()' died due to duplicate column name in 'fields' array ref");
}

{
    local $@;
    eval {
        $obj = Parse::Taxonomy::MaterializedPath->new( {
            components => {
                fields        => [ "path","lft","rgh","id","parent_id","name" ],
                data_records  => $data_records,
            }
        } );
    };
    for my $reserved ( qw| id parent_id name lft rgh | ) {
        like($@, qr/^Bad column names: <.*\b$reserved\b.*>/,
            "'new()' died due to column named with reserved term '$reserved'");
    }
}

{
    local $@;
    eval {
        $obj = Parse::Taxonomy::MaterializedPath->new( {
            components  => {
                fields        => $fields,
                data_records  => [
                   ["|Alpha","","","","",""],
                   ["|Alpha|Epsilon","","","","",""],
                   ["Alpha|Epsilon|Kappa","","","","",""],
                   ["|Alpha|Zeta","","","","",""],
                   ["|Alpha|Zeta|Lambda","","","","",""],
                   ["|Alpha|Zeta|Mu","","","","",""],
                   ["|Beta","","","","",""],
                   ["|Beta|Eta","","","","",""],
                   ["Beta|Theta","","","","",""],
                   ["|Gamma","","","","",""],
                   ["Gamma|Iota","","","","",""],
                   ["|Gamma|Iota|Nu","","","","",""],
                   ["|Delta","","","","",""],
                ],
            },
        } );
    };
    like($@, qr/The value of the column designated as path must start with the path column separator/s,
        "'new()' died due to path(s) not starting with path column separator");
    like($@, qr/Alpha|Epsilon|Kappa/s,
        "Path not starting with path column separator identified");
    like($@, qr/Beta|Theta/s,
        "Path not starting with path column separator identified");
    like($@, qr/Gamma|Iota/s,
        "Path not starting with path column separator identified");
}

{
    local $@;
    eval {
        $obj = Parse::Taxonomy::MaterializedPath->new( {
            components  => {
                fields        => $fields,
                data_records  => [
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
                   ["|Alpha|Epsilon|Kappa","","","","",""],
                   ["|Gamma|Iota","","","","",""],
                   ["|Alpha|Epsilon|Kappa","","","","",""],
                ],
            },
        } );
    };
    like($@, qr/^No duplicate entries are permitted in column designated as path/s,
        "'new()' died due to duplicate values in column designated as 'path'");
    like($@, qr/\|Alpha\|Epsilon\|Kappa/s,
        "Duplicate path identified");
    like($@, qr/\|Gamma\|Iota/s,
        "Duplicate path identified");
}

{
    local $@;
    eval {
        $obj = Parse::Taxonomy::MaterializedPath->new( {
            components  => {
                fields        => $fields,
                data_records  => [
                  ["|Alpha","","","","","","foo"],
                  ["|Alpha|Epsilon","","","","bar"],
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
    };
    like($@, qr/^Header row has \d+ records.  The following records had different counts:/s,
        "'new()' died due to wrong number of columns in one or more rows");
    like($@, qr/\|Alpha:\s+7/s, "Identified record with too many columns");
    like($@, qr/\|Alpha\|Epsilon:\s+5/s, "Identified record with too few columns");
}

{
    local $@;
    eval {
        $obj = Parse::Taxonomy::MaterializedPath->new( {
            components  => {
                fields        => $fields,
                data_records  => [
                  ["|Alpha","","","","",""],
                  ["|Alpha|Epsilon|Kappa","","","","",""],
                  ["|Alpha|Zeta","","","","",""],
                  ["|Alpha|Zeta|Lambda","","","","",""],
                  ["|Alpha|Zeta|Mu","","","","",""],
                  ["|Beta","","","","",""],
                  ["|Beta|Eta","","","","",""],
                  ["|Beta|Theta","","","","",""],
                  ["|Gamma","","","","",""],
                  ["|Gamma|Iota|Nu","","","","",""],
                  ["|Delta","","","","",""],
                ],
            },
        } );
    };
    like($@, qr/^Each node in the taxonomy must have a parent/s,
        "'new()' died due to entries in column designated as 'path' lacking parents");
    like($@, qr/\|Alpha\|Epsilon\|Kappa:\s+\|Alpha\|Epsilon/s,
        "Path lacking parent identified");
    like($@, qr/\|Gamma\|Iota\|Nu:\s+\|Gamma\|Iota/s,
        "Duplicate path identified");
}

{
    $obj = Parse::Taxonomy::MaterializedPath->new( {
        components  => {
            fields          => $fields,
            data_records    => $data_records,
        }
    } );
    ok(defined $obj, "'new()' returned defined value");
    isa_ok($obj, 'Parse::Taxonomy::MaterializedPath');

    # For testing purposes, create a hash where each element is keyed on the
    # materialized_path of a row in $obj->data_records() and where the value
    # is an array of the non-path elements in each such row.  Example:
    # {
    #   "|alpha"             => [1, 0],
    #   "|alpha|able"        => [1, 0],
    #   "|alpha|able|Agnes"  => [1, 1],
    #   # ...
    #   "|beta"              => [1, 0],
    #   "|beta|able"         => [1, 0],
    # }

    my %ver;
    for my $row (@{$obj->data_records()}) {
        $ver{$row->[0]} = [ @{$row}[1 .. $#{$row}] ];
    }

    my $scrambled_data_records = [
        ["|Alpha", "", "", "", "", ""],
        ["|Beta|Eta", "", "", "", "", ""],
        ["|Alpha|Epsilon|Kappa", "", "", "", "", ""],
        ["|Delta", "", "", "", "", ""],
        ["|Alpha|Zeta|Lambda", "", "", "", "", ""],
        ["|Alpha|Zeta|Mu", "", "", "", "", ""],
        ["|Beta", "", "", "", "", ""],
        ["|Alpha|Zeta", "", "", "", "", ""],
        ["|Alpha|Epsilon", "", "", "", "", ""],
        ["|Beta|Theta", "", "", "", "", ""],
        ["|Gamma|Iota", "", "", "", "", ""],
        ["|Gamma", "", "", "", "", ""],
        ["|Gamma|Iota|Nu", "", "", "", "", ""],
    ];
    my $second_obj = Parse::Taxonomy::MaterializedPath->new( {
        components  => {
            fields          => $fields,
            data_records    => $scrambled_data_records,
        }
    } );
    ok(defined $second_obj, "'new()' returned defined value");
    isa_ok($second_obj, 'Parse::Taxonomy::MaterializedPath');

    my %rev;
    for my $row (@{$second_obj->data_records()}) {
        $rev{$row->[0]} = [ @{$row}[1 .. $#{$row}] ];
    }
    is_deeply(\%rev, \%rev,
        "Scrambling data_records in input made no difference to taxonomy");
}

{
    my $fields = ["id_no", "path", "nationality", "gender", "age", "income"];
    my $data_records = [
        ["",",Alpha", "", "", "", ""],
        ["",",Alpha,Epsilon", "", "", "", ""],
        ["",",Alpha,Epsilon,Kappa", "", "", "", ""],
        ["",",Alpha,Zeta", "", "", "", ""],
        ["",",Alpha,Zeta,Lambda", "", "", "", ""],
        ["",",Alpha,Zeta,Mu", "", "", "", ""],
        ["",",Beta", "", "", "", ""],
        ["",",Beta,Eta", "", "", "", ""],
        ["",",Beta,Theta", "", "", "", ""],
        ["",",Gamma", "", "", "", ""],
        ["",",Gamma,Iota", "", "", "", ""],
        ["",",Gamma,Iota,Nu", "", "", "", ""],
        ["",",Delta", "", "", "", ""],
    ];
    my $obj = Parse::Taxonomy::MaterializedPath->new( {
        components  => {
            fields          => $fields,
            data_records    => $data_records,
        },
        path_col_idx => 1,
        path_col_sep => ',',
    } );
    ok(defined $obj, "'new()' returned defined value");
    isa_ok($obj, 'Parse::Taxonomy::MaterializedPath');
}

