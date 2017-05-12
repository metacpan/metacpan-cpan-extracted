use strict;
use warnings;

use Test::More;
use RocksDB;
use File::Temp;

my %optimize_options = (
    IncreaseParallelism => undef,
    PrepareForBulkLoad => undef,
    OptimizeForPointLookup => 16,
    OptimizeLevelStyleCompaction => undef,
    OptimizeUniversalStyleCompaction => undef,
);
for my $opt (keys %optimize_options) {
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
