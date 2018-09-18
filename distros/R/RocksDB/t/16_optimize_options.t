use strict;
use warnings;

use Test::More;
use RocksDB;
use File::Temp;

my %optimize_options = (
    IncreaseParallelism => undef,
    OptimizeForPointLookup => 16,
    # requires Snappy
    # OptimizeLevelStyleCompaction => undef,
    OptimizeUniversalStyleCompaction => undef,
    PrepareForBulkLoad => undef,
);
for my $opt (sort keys %optimize_options) {
    my $name = File::Temp::tmpnam;
    my $db = RocksDB->new($name, {
        $opt => $optimize_options{$opt},
        create_if_missing => 1,
    });
    ok $db, $opt;
    undef $db;
    RocksDB->destroy_db($name);
}

done_testing;
