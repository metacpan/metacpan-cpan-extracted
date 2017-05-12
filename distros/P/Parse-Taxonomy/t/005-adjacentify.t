# perl
# t/005-adjacentify.t
use strict;
use warnings;
use Carp;
use utf8;

use lib ('./lib');
use Parse::Taxonomy::MaterializedPath;
use Parse::Taxonomy::AdjacentList;
use Test::More tests => 53;
use List::Util qw( min );
use Cwd;
use File::Temp qw/ tempdir /;

my ($obj, $source, $expect, $adjacentified);

{
    $source = "./t/data/beta.csv";
    $obj = Parse::Taxonomy::MaterializedPath->new( {
        file    => $source,
    } );
    ok(defined $obj, "'new()' returned defined value");
    isa_ok($obj, 'Parse::Taxonomy::MaterializedPath');

    local $@;
    eval {
        $adjacentified = $obj->adjacentify(
            serial => 500,
        );
    };
    like($@, qr/^Argument to 'adjacentify\(\)' must be hashref/,
        "'adjacentify()' died to lack of hashref as argument; was just a key-value pair");

    local $@;
    eval {
        $adjacentified = $obj->adjacentify( [
            serial => 500,
        ] );
    };
    like($@, qr/^Argument to 'adjacentify\(\)' must be hashref/,
        "'adjacentify()' died to lack of hashref as argument; was arrayref");

    local $@;
    eval {
        $adjacentified = $obj->adjacentify( {
            serial => 'foo',
        } );
    };
    like($@, qr/^Element 'serial' in argument to 'adjacentify\(\)' must be integer/,
        "Element 'serial' in hashref argument for 'adjacentify()' must be integer");

    local $@;
    eval {
        $adjacentified = $obj->adjacentify( {
            floor => 'foo',
        } );
    };
    like($@, qr/^Element 'floor' in argument to 'adjacentify\(\)' must be integer/,
        "Element 'floor' in hashref argument for 'adjacentify()' must be integer");
}

{
    $source = "./t/data/beta.csv";
    $obj = Parse::Taxonomy::MaterializedPath->new( {
        file    => $source,
    } );
    ok(defined $obj, "'new()' returned defined value");
    isa_ok($obj, 'Parse::Taxonomy::MaterializedPath');

    note("adjacentify()");
    $adjacentified = $obj->adjacentify();
    ok($adjacentified, "'adjacentify() returned true value");
    my @ids_seen = map { $_->{id} } @{$adjacentified};
    is(min(@ids_seen), 1,
        "Lowest 'id' value is 1, as serial defaults to 0");

    note("write_adjacentified_to_csv()");
    my $csv_file;

    {
        local $@;
        eval { $csv_file = $obj->write_adjacentified_to_csv(); };
        like($@, qr/write_adjacentified_to_csv\(\) must be supplied with hashref/,
            "write_adjacentified_to_csv() failed due to lack of argument");
    }

    {
        local $@;
        eval {
            $csv_file = $obj->write_adjacentified_to_csv(
                adjacentified => $adjacentified,
            );
        };
        like($@, qr/Argument to 'adjacentify\(\)' must be hashref/,
            "write_adjacentified_to_csv() failed due to non-hashref argument");
    }

    {
        local $@;
        eval {
            $csv_file = $obj->write_adjacentified_to_csv( [
                adjacentified => $adjacentified,
            ] );
        };
        like($@, qr/Argument to 'adjacentify\(\)' must be hashref/,
            "write_adjacentified_to_csv() failed due to non-hashref argument");
    }

    {
        local $@;
        eval {
            $csv_file = $obj->write_adjacentified_to_csv( {
                adjacentified => 'not an array reference',
            } );
        };
        like($@, qr/Argument 'adjacentified' must be array reference/,
            "write_adjacentified_to_csv() failed due to non-reference value for 'adjacentified'");
    }

    {
        local $@;
        eval {
            $csv_file = $obj->write_adjacentified_to_csv( {
                adjacentified => {},
            } );
        };
        like($@, qr/Argument 'adjacentified' must be array reference/,
            "write_adjacentified_to_csv() failed due to non-arrayref value for 'adjacentified'");
    }

    {
        local $@;
        eval {
            $csv_file = $obj->write_adjacentified_to_csv( { sep_char => '|' } );
        };
        like($@, qr/Argument to 'adjacentify\(\)' must have 'adjacentified' element/,
            "write_adjacentified_to_csv() failed due to lack of 'adjacentified' element");
    }

    $csv_file = $obj->write_adjacentified_to_csv( {
       adjacentified => $adjacentified,
       csvfile => './t/data/taxonomy_out.csv',
    } );
    ok($csv_file, "write_adjacentified_to_csv() returned '$csv_file'");
    ok((-f $csv_file), "'$csv_file' is plain-text file");
    ok((-r $csv_file), "'$csv_file' is readable");
}

{
    $source = "./t/data/beta.csv";
    $obj = Parse::Taxonomy::MaterializedPath->new( {
        file    => $source,
    } );
    ok(defined $obj, "'new()' returned defined value");
    isa_ok($obj, 'Parse::Taxonomy::MaterializedPath');

    note("adjacentify()");
    my $serial = 500;
    $adjacentified = $obj->adjacentify( { serial => $serial } );
    ok($adjacentified, "'adjacentify() returned true value");
    my @ids_seen = map { $_->{id} } @{$adjacentified};
    my $expect = $serial + 1;
    is(min(@ids_seen), $expect,
        "Lowest 'id' value is $expect, as serial was set to $serial");

    note("write_adjacentified_to_csv(); assign to 'eol'");
    my $csv_file;
    $csv_file = $obj->write_adjacentified_to_csv( {
       adjacentified => $adjacentified,
       csvfile => './t/data/taxonomy_out1.csv',
       sep_char => '|',
       eol => "\r\n",
    } );
    open my $IN, '<', $csv_file or croak "Unable to open $csv_file for reading";
    my $line = <$IN>;
    close $IN or croak "Unable to close $csv_file after reading";
    my $line_ending;
    ($line_ending) = $line =~ m/(\015\012)$/;
    is($line_ending, "\r\n", "Wrote DOS line endings to output file");

    {
        my $cwd = cwd();
        my $tdir = tempdir(CLEANUP => 1);
        chdir $tdir or croak "Unable to change to $tdir";
        $csv_file = $obj->write_adjacentified_to_csv( {
            adjacentified => $adjacentified,
        } );
        ok(-f "$tdir/taxonomy_out.csv", "Wrote CSV file in current directory");
        chdir $cwd or croak "Unable to change back to $cwd";
    }

}

{
    note("adjacentify() with 'serial' and/or 'floor'");

    $source = "./t/data/beta.csv";
    $obj = Parse::Taxonomy::MaterializedPath->new( {
        file    => $source,
    } );
    ok(defined $obj, "'new()' returned defined value");
    isa_ok($obj, 'Parse::Taxonomy::MaterializedPath');

    my ($floor, $serial, @ids_seen, $expect);

    $floor = 500;
    $adjacentified = $obj->adjacentify( { floor => $floor } );
    ok($adjacentified, "'adjacentify() returned true value");
    @ids_seen = map { $_->{id} } @{$adjacentified};
    $expect = $floor + 1;
    is(min(@ids_seen), $expect,
        "Lowest 'id' value is $expect, as floor was set to $floor");

    $serial = 300;
    $adjacentified = $obj->adjacentify( { serial => $serial } );
    ok($adjacentified, "'adjacentify() returned true value");
    @ids_seen = map { $_->{id} } @{$adjacentified};
    $expect = $serial + 1;
    is(min(@ids_seen), $expect,
        "Lowest 'id' value is $expect, as serial was set to $serial");

    $serial = 1300;
    $adjacentified = $obj->adjacentify( {
        serial  => $serial,
        floor   => $floor,
    } );
    ok($adjacentified, "'adjacentify() returned true value");
    @ids_seen = map { $_->{id} } @{$adjacentified};
    $expect = $serial + 1;
    is(min(@ids_seen), $expect,
        "Lowest 'id' value is $expect, as 'serial' takes precedence over 'floor'");
}

{
    note("Non-siblings can have same name");
    $source = "./t/data/non_sibling_same_name.csv";
    note($source);
    $obj = Parse::Taxonomy::MaterializedPath->new( {
        file                => $source,
    } );
    ok(defined $obj, "new() returned defined value");
    isa_ok($obj, 'Parse::Taxonomy::MaterializedPath');

    note("adjacentify()");
    my $serial = 420;
    $adjacentified = $obj->adjacentify( { serial => $serial } );
    ok($adjacentified, "'adjacentify() returned true value");
    my @ids_seen = map { $_->{id} } @{$adjacentified};
    my $expect = $serial + 1;
    is(min(@ids_seen), $expect,
        "Lowest 'id' value is $expect, as serial was set to $serial");

    note("write_adjacentified_to_csv()");
    my $csv_file;
    $csv_file = $obj->write_adjacentified_to_csv( {
       adjacentified => $adjacentified,
       csvfile => './t/data/taxonomy_out2.csv',
       sep_char => '|',
    } );

}

{
    my $csv_file;

    # A small taxonomy-by-materialized-path
    $source = "./t/data/iota.csv";
    note($source);
    $obj = Parse::Taxonomy::MaterializedPath->new( {
        file => $source,
    } );
    ok(defined $obj, "new() returned defined value");
    isa_ok($obj, 'Parse::Taxonomy::MaterializedPath');

    note("adjacentify()");
    $adjacentified = $obj->adjacentify();
    ok($adjacentified, "'adjacentify() returned true value");

    note("write_adjacentified_to_csv()");
    $csv_file = $obj->write_adjacentified_to_csv( {
       adjacentified => $adjacentified,
       csvfile => './t/data/taxonomy_out3.csv',
    } );

    # Another small taxonomy-by-materialized-path
    $source = "./t/data/kappa.csv";
    note($source);
    $obj = Parse::Taxonomy::MaterializedPath->new( {
        file => $source,
    } );
    ok(defined $obj, "new() returned defined value");
    isa_ok($obj, 'Parse::Taxonomy::MaterializedPath');

    note("adjacentify()");
    $adjacentified = $obj->adjacentify();
    ok($adjacentified, "'adjacentify() returned true value");

    note("write_adjacentified_to_csv()");
    $csv_file = $obj->write_adjacentified_to_csv( {
       adjacentified => $adjacentified,
       csvfile => './t/data/taxonomy_out4.csv',
    } );

}

{
    note("Test same second- and third-level leaf fields");
    my @input_columns = ( qw| path letter_vendor_id is_actionable | );
    my @data_records = (
      ["|alpha", 1, 0],
      ["|alpha|able", 1, 0],
      ["|alpha|able|Agnes", 1, 1],
      ["|alpha|able|Agnew", 1, 1],
      ["|alpha|baker", 1, 0],
      ["|alpha|baker|Agnes", 1, 1],
      ["|alpha|baker|Agnew", 1, 1],
      ["|beta", 1, 0],
      ["|beta|able", 1, 0],
      ["|beta|able|Agnes", 1, 1],
      ["|beta|able|Agnew", 1, 1],
      ["|beta|baker", 1, 0],
      ["|beta|baker|Agnes", 1, 1],
      ["|beta|baker|Agnew", 1, 1],
    );
    note("Create MaterializedPath taxonomy from components");
    my $obj = Parse::Taxonomy::MaterializedPath->new( {
        components  => {
            fields          => \@input_columns,
            data_records    => \@data_records,
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

    my $adjacentified = $obj->adjacentify();
    ok($adjacentified, "'adjacentify() returned true value");
    my $csv_file = $obj->write_adjacentified_to_csv( {
       adjacentified => $adjacentified,
       csvfile => './t/data/taxonomy_out5.csv',
    } );


    note("Create AdjacentList object starting from file just now created");
    my $objal = Parse::Taxonomy::AdjacentList->new( {
        file            => $csv_file,
        id_col          => 'id',
        parent_id_col   => 'parent_id',
    } );
    ok(defined $objal, "AdjacentList constructor returned defined value");

    # pathify the data in the AdjacentList object, then use the result
    # to create a hash of arrays with same structure as %ver above.
    my $pathified = $objal->pathify();
    my %rev;
    for my $el (@{$pathified}[1 .. $#{$pathified}]) {
        my $path_as_string = join('|' => @{$el->[0]});
        $rev{$path_as_string} = [ @{$el}[1 .. $#{$el}] ];
    }

    is_deeply(\%ver, \%rev,
        "Successful round trip:  materialized path to adjacent list and back again");
}

{
    note("Test same second- and third- and fourth- level leaf fields");
    my @input_columns = ( qw| path letter_vendor_id is_actionable | );
    my @data_records = (
      ["|alpha", 1, 0],
      ["|alpha|able", 1, 0],
      ["|alpha|able|Agnes", 1, 0],
      ["|alpha|able|Agnes|Calvin", 1, 1],
      ["|alpha|able|Agnes|Camron", 1, 1],
      ["|alpha|able|Agnew", 1, 0],
      ["|alpha|able|Agnew|Calvin", 1, 1],
      ["|alpha|able|Agnew|Camron", 1, 1],
      ["|alpha|baker", 1, 0],
      ["|alpha|baker|Agnes", 1, 0],
      ["|alpha|baker|Agnes|Calvin", 1, 1],
      ["|alpha|baker|Agnes|Camron", 1, 1],
      ["|alpha|baker|Agnew", 1, 0],
      ["|alpha|baker|Agnew|Calvin", 1, 1],
      ["|alpha|baker|Agnew|Camron", 1, 1],
      ["|beta", 1, 0],
      ["|beta|able", 1, 0],
      ["|beta|able|Agnes", 1, 0],
      ["|beta|able|Agnes|Calvin", 1, 1],
      ["|beta|able|Agnes|Camron", 1, 1],
      ["|beta|able|Agnew", 1, 0],
      ["|beta|able|Agnew|Calvin", 1, 1],
      ["|beta|able|Agnew|Camron", 1, 1],
      ["|beta|baker", 1, 0],
      ["|beta|baker|Agnes", 1, 0],
      ["|beta|baker|Agnes|Calvin", 1, 1],
      ["|beta|baker|Agnes|Camron", 1, 1],
      ["|beta|baker|Agnew", 1, 0],
      ["|beta|baker|Agnew|Calvin", 1, 1],
      ["|beta|baker|Agnew|Camron", 1, 1],
    );
    note("Create MaterializedPath taxonomy from components");
    my $obj = Parse::Taxonomy::MaterializedPath->new( {
        components  => {
            fields          => \@input_columns,
            data_records    => \@data_records,
        }
    } );
    ok(defined $obj, "'new()' returned defined value");
    isa_ok($obj, 'Parse::Taxonomy::MaterializedPath');

    my %ver;
    for my $row (@{$obj->data_records()}) {
        $ver{$row->[0]} = [ @{$row}[1 .. $#{$row}] ];
    }

    my $adjacentified = $obj->adjacentify();
    ok($adjacentified, "'adjacentify() returned true value");
    my $csv_file = $obj->write_adjacentified_to_csv( {
       adjacentified => $adjacentified,
       csvfile => './t/data/taxonomy_out5.csv',
    } );

    note("Create AdjacentList object starting from file just now created");
    my $objal = Parse::Taxonomy::AdjacentList->new( {
        file            => $csv_file,
        id_col          => 'id',
        parent_id_col   => 'parent_id',
    } );
    ok(defined $objal, "AdjacentList constructor returned defined value");

    my $pathified = $objal->pathify();
    my %rev;
    for my $el (@{$pathified}[1 .. $#{$pathified}]) {
        my $path_as_string = join('|' => @{$el->[0]});
        $rev{$path_as_string} = [ @{$el}[1 .. $#{$el}] ];
    }

    is_deeply(\%ver, \%rev, "Another successful round trip");
}
