# perl
use strict;
use warnings;
use 5.10.1;
use Carp;
use Cwd;
use Parse::Taxonomy::MaterializedPath;
use Parse::Taxonomy::AdjacentList;
use Data::Dump;

# This program holds the examples used in my Nov 17 2015 presentation to 
# New York Perlmongers, I<A Taste of Taxonomies>.

my $cwd = cwd();
my $auto_taxonomy = "$cwd/examples/data/automobiles_taxonomy.csv";
croak "Could not locate $auto_taxonomy for testing" unless (-f $auto_taxonomy);

my $obj = Parse::Taxonomy::MaterializedPath->new( {
    file => $auto_taxonomy,
} );
croak "Invalid taxonomy" unless defined($obj);

my $hashified = $obj->hashify();
#Data::Dump::pp($hashified);

my $adjacentified = $obj->adjacentify();
my $csv_out = "$cwd/examples/data/auto_adjacent.csv";
#Data::Dump::pp($adjacentified);
$obj->write_adjacentified_to_csv( {
    adjacentified => $adjacentified,
    csvfile => $csv_out,
} );

my $alobj = Parse::Taxonomy::AdjacentList->new( {
    file => $csv_out,
} );
croak "Invalid taxonomy" unless defined($alobj);

my $pathified = $alobj->pathify();
#Data::Dump::pp($pathified);
my $csv_out_path = "$cwd/examples/data/auto_pathified.csv";
$alobj->write_pathified_to_csv( {
    pathified => $pathified,
    csvfile => $csv_out_path,
} );
