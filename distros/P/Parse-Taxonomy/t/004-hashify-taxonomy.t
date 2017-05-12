# perl
# t/004-hashify-taxonomy.t
use strict;
use warnings;
use Carp;
use utf8;

use lib ('./lib');
use Parse::Taxonomy::MaterializedPath;
use Test::More tests => 19;

my ($obj, $source, $expect, $hashified);

{
    $source = "./t/data/beta.csv";
    $obj = Parse::Taxonomy::MaterializedPath->new( {
        file    => $source,
    } );
    ok(defined $obj, "'new()' returned defined value");
    isa_ok($obj, 'Parse::Taxonomy::MaterializedPath');

    local $@;
    eval {
        $hashified = $obj->hashify(
            key_delim => q{ - },
        );
    };
    like($@, qr/^Argument to 'hashify\(\)' must be hashref/,
        "'hashify()' died to lack of hashref as argument; was just a key-value pair");

    local $@;
    eval {
        $hashified = $obj->hashify( [
            key_delim => q{ - },
        ] );
    };
    like($@, qr/^Argument to 'hashify\(\)' must be hashref/,
        "'hashify()' died to lack of hashref as argument; was arrayref");
}

{
    $source = "./t/data/beta.csv";
    $obj = Parse::Taxonomy::MaterializedPath->new( {
        file    => $source,
    } );
    ok(defined $obj, "'new()' returned defined value");
    isa_ok($obj, 'Parse::Taxonomy::MaterializedPath');

    $expect = {
        "|Alpha" => {
                    currency_code => "USD",
                    is_actionable => 0,
                    path => "|Alpha",
                    retail_price => "",
                    vertical => "Auto",
                    wholesale_price => "",
                  },
        "|Alpha|Epsilon" => {
                    currency_code => "USD",
                    is_actionable => 0,
                    path => "|Alpha|Epsilon",
                    retail_price => "",
                    vertical => "Auto",
                    wholesale_price => "",
                  },
        "|Alpha|Epsilon|Kappa" => {
                    currency_code => "USD",
                    is_actionable => 1,
                    path => "|Alpha|Epsilon|Kappa",
                    retail_price => "0.60",
                    vertical => "Auto",
                    wholesale_price => "0.50",
                  },
        "|Alpha|Zeta" => {
                    currency_code => "USD",
                    is_actionable => 0,
                    path => "|Alpha|Zeta",
                    retail_price => "",
                    vertical => "Auto",
                    wholesale_price => "",
                  },
        "|Alpha|Zeta|Lambda" => {
                    currency_code => "USD",
                    is_actionable => 1,
                    path => "|Alpha|Zeta|Lambda",
                    retail_price => "0.50",
                    vertical => "Auto",
                    wholesale_price => "0.40",
                  },
        "|Alpha|Zeta|Mu" => {
                    currency_code => "USD",
                    is_actionable => 0,
                    path => "|Alpha|Zeta|Mu",
                    retail_price => "0.50",
                    vertical => "Auto",
                    wholesale_price => "0.40",
                  },
        "|Beta" => {
                    currency_code => "JPY",
                    is_actionable => 0,
                    path => "|Beta",
                    retail_price => "",
                    vertical => "Electronics",
                    wholesale_price => "",
                  },
        "|Beta|Eta" => {
                    currency_code => "JPY",
                    is_actionable => 1,
                    path => "|Beta|Eta",
                    retail_price => 0.45,
                    vertical => "Electronics",
                    wholesale_price => 0.35,
                  },
        "|Beta|Theta" => {
                    currency_code => "JPY",
                    is_actionable => 1,
                    path => "|Beta|Theta",
                    retail_price => 0.45,
                    vertical => "Electronics",
                    wholesale_price => 0.35,
                  },
        "|Gamma" => {
                    currency_code => "EUR",
                    is_actionable => 0,
                    path => "|Gamma",
                    retail_price => "",
                    vertical => "Travel",
                    wholesale_price => "",
                  },
        "|Gamma|Iota" => {
                    currency_code => "EUR",
                    is_actionable => 0,
                    path => "|Gamma|Iota",
                    retail_price => "",
                    vertical => "Travel",
                    wholesale_price => "",
                  },
        "|Gamma|Iota|Nu" => {
                    currency_code => "EUR",
                    is_actionable => 1,
                    path => "|Gamma|Iota|Nu",
                    retail_price => 0.75,
                    vertical => "Travel",
                    wholesale_price => "0.60",
                  },
        "|Delta" => {
                    currency_code => "USD",
                    is_actionable => 1,
                    path => "|Delta",
                    retail_price => "0.30",
                    vertical => "Life Insurance",
                    wholesale_price => 0.25,
                  },
    };
    $hashified = $obj->hashify();
    is_deeply($hashified, $expect, "Got expected hashified taxonomy (no args)");

    $expect = {
        "Alpha" => {
                    currency_code => "USD",
                    is_actionable => 0,
                    path => "|Alpha",
                    retail_price => "",
                    vertical => "Auto",
                    wholesale_price => "",
                  },
        "Alpha|Epsilon" => {
                    currency_code => "USD",
                    is_actionable => 0,
                    path => "|Alpha|Epsilon",
                    retail_price => "",
                    vertical => "Auto",
                    wholesale_price => "",
                  },
        "Alpha|Epsilon|Kappa" => {
                    currency_code => "USD",
                    is_actionable => 1,
                    path => "|Alpha|Epsilon|Kappa",
                    retail_price => "0.60",
                    vertical => "Auto",
                    wholesale_price => "0.50",
                  },
        "Alpha|Zeta" => {
                    currency_code => "USD",
                    is_actionable => 0,
                    path => "|Alpha|Zeta",
                    retail_price => "",
                    vertical => "Auto",
                    wholesale_price => "",
                  },
        "Alpha|Zeta|Lambda" => {
                    currency_code => "USD",
                    is_actionable => 1,
                    path => "|Alpha|Zeta|Lambda",
                    retail_price => "0.50",
                    vertical => "Auto",
                    wholesale_price => "0.40",
                  },
        "Alpha|Zeta|Mu" => {
                    currency_code => "USD",
                    is_actionable => 0,
                    path => "|Alpha|Zeta|Mu",
                    retail_price => "0.50",
                    vertical => "Auto",
                    wholesale_price => "0.40",
                  },
        "Beta" => {
                    currency_code => "JPY",
                    is_actionable => 0,
                    path => "|Beta",
                    retail_price => "",
                    vertical => "Electronics",
                    wholesale_price => "",
                  },
        "Beta|Eta" => {
                    currency_code => "JPY",
                    is_actionable => 1,
                    path => "|Beta|Eta",
                    retail_price => 0.45,
                    vertical => "Electronics",
                    wholesale_price => 0.35,
                  },
        "Beta|Theta" => {
                    currency_code => "JPY",
                    is_actionable => 1,
                    path => "|Beta|Theta",
                    retail_price => 0.45,
                    vertical => "Electronics",
                    wholesale_price => 0.35,
                  },
        "Gamma" => {
                    currency_code => "EUR",
                    is_actionable => 0,
                    path => "|Gamma",
                    retail_price => "",
                    vertical => "Travel",
                    wholesale_price => "",
                  },
        "Gamma|Iota" => {
                    currency_code => "EUR",
                    is_actionable => 0,
                    path => "|Gamma|Iota",
                    retail_price => "",
                    vertical => "Travel",
                    wholesale_price => "",
                  },
        "Gamma|Iota|Nu" => {
                    currency_code => "EUR",
                    is_actionable => 1,
                    path => "|Gamma|Iota|Nu",
                    retail_price => 0.75,
                    vertical => "Travel",
                    wholesale_price => "0.60",
                  },
        "Delta" => {
                    currency_code => "USD",
                    is_actionable => 1,
                    path => "|Delta",
                    retail_price => "0.30",
                    vertical => "Life Insurance",
                    wholesale_price => 0.25,
                  },
    };
    $hashified = $obj->hashify( {
        remove_leading_path_col_sep => 1,
    } );
    is_deeply($hashified, $expect,
        "Got expected hashified taxonomy (remove_leading_path_col_sep)");

    $expect = {
        "/Alpha" => {
                    currency_code => "USD",
                    is_actionable => 0,
                    path => "|Alpha",
                    retail_price => "",
                    vertical => "Auto",
                    wholesale_price => "",
                  },
        "/Alpha/Epsilon" => {
                    currency_code => "USD",
                    is_actionable => 0,
                    path => "|Alpha|Epsilon",
                    retail_price => "",
                    vertical => "Auto",
                    wholesale_price => "",
                  },
        "/Alpha/Epsilon/Kappa" => {
                    currency_code => "USD",
                    is_actionable => 1,
                    path => "|Alpha|Epsilon|Kappa",
                    retail_price => "0.60",
                    vertical => "Auto",
                    wholesale_price => "0.50",
                  },
        "/Alpha/Zeta" => {
                    currency_code => "USD",
                    is_actionable => 0,
                    path => "|Alpha|Zeta",
                    retail_price => "",
                    vertical => "Auto",
                    wholesale_price => "",
                  },
        "/Alpha/Zeta/Lambda" => {
                    currency_code => "USD",
                    is_actionable => 1,
                    path => "|Alpha|Zeta|Lambda",
                    retail_price => "0.50",
                    vertical => "Auto",
                    wholesale_price => "0.40",
                  },
        "/Alpha/Zeta/Mu" => {
                    currency_code => "USD",
                    is_actionable => 0,
                    path => "|Alpha|Zeta|Mu",
                    retail_price => "0.50",
                    vertical => "Auto",
                    wholesale_price => "0.40",
                  },
        "/Beta" => {
                    currency_code => "JPY",
                    is_actionable => 0,
                    path => "|Beta",
                    retail_price => "",
                    vertical => "Electronics",
                    wholesale_price => "",
                  },
        "/Beta/Eta" => {
                    currency_code => "JPY",
                    is_actionable => 1,
                    path => "|Beta|Eta",
                    retail_price => 0.45,
                    vertical => "Electronics",
                    wholesale_price => 0.35,
                  },
        "/Beta/Theta" => {
                    currency_code => "JPY",
                    is_actionable => 1,
                    path => "|Beta|Theta",
                    retail_price => 0.45,
                    vertical => "Electronics",
                    wholesale_price => 0.35,
                  },
        "/Gamma" => {
                    currency_code => "EUR",
                    is_actionable => 0,
                    path => "|Gamma",
                    retail_price => "",
                    vertical => "Travel",
                    wholesale_price => "",
                  },
        "/Gamma/Iota" => {
                    currency_code => "EUR",
                    is_actionable => 0,
                    path => "|Gamma|Iota",
                    retail_price => "",
                    vertical => "Travel",
                    wholesale_price => "",
                  },
        "/Gamma/Iota/Nu" => {
                    currency_code => "EUR",
                    is_actionable => 1,
                    path => "|Gamma|Iota|Nu",
                    retail_price => 0.75,
                    vertical => "Travel",
                    wholesale_price => "0.60",
                  },
        "/Delta" => {
                    currency_code => "USD",
                    is_actionable => 1,
                    path => "|Delta",
                    retail_price => "0.30",
                    vertical => "Life Insurance",
                    wholesale_price => 0.25,
                  },
    };
    $hashified = $obj->hashify( {
        key_delim => '/',
    } );
    is_deeply($hashified, $expect, "Got expected hashified taxonomy (key_delim)");

    $expect = {
        "Alpha" => {
                    currency_code => "USD",
                    is_actionable => 0,
                    path => "|Alpha",
                    retail_price => "",
                    vertical => "Auto",
                    wholesale_price => "",
                  },
        "Alpha - Epsilon" => {
                    currency_code => "USD",
                    is_actionable => 0,
                    path => "|Alpha|Epsilon",
                    retail_price => "",
                    vertical => "Auto",
                    wholesale_price => "",
                  },
        "Alpha - Epsilon - Kappa" => {
                    currency_code => "USD",
                    is_actionable => 1,
                    path => "|Alpha|Epsilon|Kappa",
                    retail_price => "0.60",
                    vertical => "Auto",
                    wholesale_price => "0.50",
                  },
        "Alpha - Zeta" => {
                    currency_code => "USD",
                    is_actionable => 0,
                    path => "|Alpha|Zeta",
                    retail_price => "",
                    vertical => "Auto",
                    wholesale_price => "",
                  },
        "Alpha - Zeta - Lambda" => {
                    currency_code => "USD",
                    is_actionable => 1,
                    path => "|Alpha|Zeta|Lambda",
                    retail_price => "0.50",
                    vertical => "Auto",
                    wholesale_price => "0.40",
                  },
        "Alpha - Zeta - Mu" => {
                    currency_code => "USD",
                    is_actionable => 0,
                    path => "|Alpha|Zeta|Mu",
                    retail_price => "0.50",
                    vertical => "Auto",
                    wholesale_price => "0.40",
                  },
        "Beta" => {
                    currency_code => "JPY",
                    is_actionable => 0,
                    path => "|Beta",
                    retail_price => "",
                    vertical => "Electronics",
                    wholesale_price => "",
                  },
        "Beta - Eta" => {
                    currency_code => "JPY",
                    is_actionable => 1,
                    path => "|Beta|Eta",
                    retail_price => 0.45,
                    vertical => "Electronics",
                    wholesale_price => 0.35,
                  },
        "Beta - Theta" => {
                    currency_code => "JPY",
                    is_actionable => 1,
                    path => "|Beta|Theta",
                    retail_price => 0.45,
                    vertical => "Electronics",
                    wholesale_price => 0.35,
                  },
        "Gamma" => {
                    currency_code => "EUR",
                    is_actionable => 0,
                    path => "|Gamma",
                    retail_price => "",
                    vertical => "Travel",
                    wholesale_price => "",
                  },
        "Gamma - Iota" => {
                    currency_code => "EUR",
                    is_actionable => 0,
                    path => "|Gamma|Iota",
                    retail_price => "",
                    vertical => "Travel",
                    wholesale_price => "",
                  },
        "Gamma - Iota - Nu" => {
                    currency_code => "EUR",
                    is_actionable => 1,
                    path => "|Gamma|Iota|Nu",
                    retail_price => 0.75,
                    vertical => "Travel",
                    wholesale_price => "0.60",
                  },
        "Delta" => {
                    currency_code => "USD",
                    is_actionable => 1,
                    path => "|Delta",
                    retail_price => "0.30",
                    vertical => "Life Insurance",
                    wholesale_price => 0.25,
                  },
    };
    $hashified = $obj->hashify( {
        remove_leading_path_col_sep => 1,
        key_delim => q{ - },
    } );
    is_deeply($hashified, $expect,
        "Got expected taxonomy (remove_leading_path_col_sep and key_delim)");

    $expect = {
        "All Suppliers|Alpha" => {
                    currency_code => "USD",
                    is_actionable => 0,
                    path => "|Alpha",
                    retail_price => "",
                    vertical => "Auto",
                    wholesale_price => "",
                  },
        "All Suppliers|Alpha|Epsilon" => {
                    currency_code => "USD",
                    is_actionable => 0,
                    path => "|Alpha|Epsilon",
                    retail_price => "",
                    vertical => "Auto",
                    wholesale_price => "",
                  },
        "All Suppliers|Alpha|Epsilon|Kappa" => {
                    currency_code => "USD",
                    is_actionable => 1,
                    path => "|Alpha|Epsilon|Kappa",
                    retail_price => "0.60",
                    vertical => "Auto",
                    wholesale_price => "0.50",
                  },
        "All Suppliers|Alpha|Zeta" => {
                    currency_code => "USD",
                    is_actionable => 0,
                    path => "|Alpha|Zeta",
                    retail_price => "",
                    vertical => "Auto",
                    wholesale_price => "",
                  },
        "All Suppliers|Alpha|Zeta|Lambda" => {
                    currency_code => "USD",
                    is_actionable => 1,
                    path => "|Alpha|Zeta|Lambda",
                    retail_price => "0.50",
                    vertical => "Auto",
                    wholesale_price => "0.40",
                  },
        "All Suppliers|Alpha|Zeta|Mu" => {
                    currency_code => "USD",
                    is_actionable => 0,
                    path => "|Alpha|Zeta|Mu",
                    retail_price => "0.50",
                    vertical => "Auto",
                    wholesale_price => "0.40",
                  },
        "All Suppliers|Beta" => {
                    currency_code => "JPY",
                    is_actionable => 0,
                    path => "|Beta",
                    retail_price => "",
                    vertical => "Electronics",
                    wholesale_price => "",
                  },
        "All Suppliers|Beta|Eta" => {
                    currency_code => "JPY",
                    is_actionable => 1,
                    path => "|Beta|Eta",
                    retail_price => 0.45,
                    vertical => "Electronics",
                    wholesale_price => 0.35,
                  },
        "All Suppliers|Beta|Theta" => {
                    currency_code => "JPY",
                    is_actionable => 1,
                    path => "|Beta|Theta",
                    retail_price => 0.45,
                    vertical => "Electronics",
                    wholesale_price => 0.35,
                  },
        "All Suppliers|Gamma" => {
                    currency_code => "EUR",
                    is_actionable => 0,
                    path => "|Gamma",
                    retail_price => "",
                    vertical => "Travel",
                    wholesale_price => "",
                  },
        "All Suppliers|Gamma|Iota" => {
                    currency_code => "EUR",
                    is_actionable => 0,
                    path => "|Gamma|Iota",
                    retail_price => "",
                    vertical => "Travel",
                    wholesale_price => "",
                  },
        "All Suppliers|Gamma|Iota|Nu" => {
                    currency_code => "EUR",
                    is_actionable => 1,
                    path => "|Gamma|Iota|Nu",
                    retail_price => 0.75,
                    vertical => "Travel",
                    wholesale_price => "0.60",
                  },
        "All Suppliers|Delta" => {
                    currency_code => "USD",
                    is_actionable => 1,
                    path => "|Delta",
                    retail_price => "0.30",
                    vertical => "Life Insurance",
                    wholesale_price => 0.25,
                  },
    };
    $hashified = $obj->hashify( {
        root_str => 'All Suppliers',
    } );
    is_deeply($hashified, $expect,
        "Got expected taxonomy (root_str)");

    $expect = {
        "All Suppliers - Alpha" => {
                    currency_code => "USD",
                    is_actionable => 0,
                    path => "|Alpha",
                    retail_price => "",
                    vertical => "Auto",
                    wholesale_price => "",
                  },
        "All Suppliers - Alpha - Epsilon" => {
                    currency_code => "USD",
                    is_actionable => 0,
                    path => "|Alpha|Epsilon",
                    retail_price => "",
                    vertical => "Auto",
                    wholesale_price => "",
                  },
        "All Suppliers - Alpha - Epsilon - Kappa" => {
                    currency_code => "USD",
                    is_actionable => 1,
                    path => "|Alpha|Epsilon|Kappa",
                    retail_price => "0.60",
                    vertical => "Auto",
                    wholesale_price => "0.50",
                  },
        "All Suppliers - Alpha - Zeta" => {
                    currency_code => "USD",
                    is_actionable => 0,
                    path => "|Alpha|Zeta",
                    retail_price => "",
                    vertical => "Auto",
                    wholesale_price => "",
                  },
        "All Suppliers - Alpha - Zeta - Lambda" => {
                    currency_code => "USD",
                    is_actionable => 1,
                    path => "|Alpha|Zeta|Lambda",
                    retail_price => "0.50",
                    vertical => "Auto",
                    wholesale_price => "0.40",
                  },
        "All Suppliers - Alpha - Zeta - Mu" => {
                    currency_code => "USD",
                    is_actionable => 0,
                    path => "|Alpha|Zeta|Mu",
                    retail_price => "0.50",
                    vertical => "Auto",
                    wholesale_price => "0.40",
                  },
        "All Suppliers - Beta" => {
                    currency_code => "JPY",
                    is_actionable => 0,
                    path => "|Beta",
                    retail_price => "",
                    vertical => "Electronics",
                    wholesale_price => "",
                  },
        "All Suppliers - Beta - Eta" => {
                    currency_code => "JPY",
                    is_actionable => 1,
                    path => "|Beta|Eta",
                    retail_price => 0.45,
                    vertical => "Electronics",
                    wholesale_price => 0.35,
                  },
        "All Suppliers - Beta - Theta" => {
                    currency_code => "JPY",
                    is_actionable => 1,
                    path => "|Beta|Theta",
                    retail_price => 0.45,
                    vertical => "Electronics",
                    wholesale_price => 0.35,
                  },
        "All Suppliers - Gamma" => {
                    currency_code => "EUR",
                    is_actionable => 0,
                    path => "|Gamma",
                    retail_price => "",
                    vertical => "Travel",
                    wholesale_price => "",
                  },
        "All Suppliers - Gamma - Iota" => {
                    currency_code => "EUR",
                    is_actionable => 0,
                    path => "|Gamma|Iota",
                    retail_price => "",
                    vertical => "Travel",
                    wholesale_price => "",
                  },
        "All Suppliers - Gamma - Iota - Nu" => {
                    currency_code => "EUR",
                    is_actionable => 1,
                    path => "|Gamma|Iota|Nu",
                    retail_price => 0.75,
                    vertical => "Travel",
                    wholesale_price => "0.60",
                  },
        "All Suppliers - Delta" => {
                    currency_code => "USD",
                    is_actionable => 1,
                    path => "|Delta",
                    retail_price => "0.30",
                    vertical => "Life Insurance",
                    wholesale_price => 0.25,
                  },
    };
    $hashified = $obj->hashify( {
        key_delim => ' - ',
        root_str => 'All Suppliers',
    } );
    is_deeply($hashified, $expect, "Got expected taxonomy (key_delim and root_str)");

    note("'components' interface");
    $obj = Parse::Taxonomy::MaterializedPath->new( {
#        file    => $source,
        components => {
            fields          => ["path","vertical","currency_code","wholesale_price","retail_price","is_actionable"],
            data_records    => [
              ["|Alpha","Auto","USD","","","0"],
              ["|Alpha|Epsilon","Auto","USD","","","0"],
              ["|Alpha|Epsilon|Kappa","Auto","USD","0.50","0.60","1"],
              ["|Alpha|Zeta","Auto","USD","","","0"],
              ["|Alpha|Zeta|Lambda","Auto","USD","0.40","0.50","1"],
              ["|Alpha|Zeta|Mu","Auto","USD","0.40","0.50","0"],
              ["|Beta","Electronics","JPY","","","0"],
              ["|Beta|Eta","Electronics","JPY","0.35","0.45","1"],
              ["|Beta|Theta","Electronics","JPY","0.35","0.45","1"],
              ["|Gamma","Travel","EUR","","","0"],
              ["|Gamma|Iota","Travel","EUR","","","0"],
              ["|Gamma|Iota|Nu","Travel","EUR","0.60","0.75","1"],
              ["|Delta","Life Insurance","USD","0.25","0.30","1"],
            ],
        },
    } );
    ok(defined $obj, "'new()' returned defined value");
    isa_ok($obj, 'Parse::Taxonomy::MaterializedPath');

    $hashified = $obj->hashify( {
        key_delim => ' - ',
        root_str => 'All Suppliers',
    } );
    is_deeply($hashified, $expect, "Got expected taxonomy (key_delim and root_str)");
}

{
    note("Example of local validation");
    my $obj = Parse::Taxonomy::MaterializedPath->new( {
        file    => 't/data/iota.csv',
    } );
    my $hashified       = $obj->hashify();
    my $descendant_counts    = $obj->descendant_counts();
    my @non_actionable_leaf_nodes = ();
    for my $node (keys %{$hashified}) {
        if (
            ($descendant_counts->{$node} == 0) &&
            (! $hashified->{$node}->{is_actionable})
        ) {
            push @non_actionable_leaf_nodes, $node;
        }
    }
    ok(scalar(@non_actionable_leaf_nodes),
        "leaf nodes which are non-actionable were identified");

    my %non_actionable_leaf_nodes =
        map { $_ => {
            descendant_count => $descendant_counts->{$_},
            is_actionable => $hashified->{$_}->{is_actionable},
        } }
        grep {
            ($descendant_counts->{$_} == 0) &&
            (! $hashified->{$_}->{is_actionable})
        }
        keys %{$hashified};
    ok(scalar(keys %non_actionable_leaf_nodes),
        "leaf nodes which are non-actionable were identified");
}

{
    note("Example of local validation");
    my $obj = Parse::Taxonomy::MaterializedPath->new( {
        file    => 't/data/iota.csv',
    } );
    my $hashified           = $obj->hashify();
    my $descendant_counts   = $obj->descendant_counts();
    my @non_actionable_leaf_nodes = ();
    for my $node (keys %{$hashified}) {
        if (
            ($descendant_counts->{$node} == 0) &&
            (! $hashified->{$node}->{is_actionable})
        ) {
            push @non_actionable_leaf_nodes, $node;
        }
    }
    ok(scalar(@non_actionable_leaf_nodes),
        "leaf nodes which are non-actionable were identified");

    my %non_actionable_leaf_nodes =
        map { $_ => {
            descendant_count    => $descendant_counts->{$_},
            is_actionable       => $hashified->{$_}->{is_actionable},
        } }
        grep {
            ($descendant_counts->{$_} == 0) &&
            (! $hashified->{$_}->{is_actionable})
        }
        keys %{$hashified};
    ok(scalar(keys %non_actionable_leaf_nodes),
        "leaf nodes which are non-actionable were identified");
}
