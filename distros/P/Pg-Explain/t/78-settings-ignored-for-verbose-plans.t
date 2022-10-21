#!perl

use Test::More;
use Test::Deep;
use autodie;

use Pg::Explain;

my $plan = q{
Aggregate  (cost=15.36..15.37 rows=1 width=8) (actual time=1.037..1.043 rows=1 loops=1)
  Output: count(*)
  ->  Index Only Scan using pg_class_tblspc_relfilenode_index on pg_catalog.pg_class  (cost=0.15..14.33 rows=412 width=0) (actual time=0.019..0.523 rows=412 loops=1)
        Output: reltablespace, relfilenode
        Heap Fetches: 0
Settings: work_mem = '1GB'
Query Identifier: -1333237548973193890
Planning Time: 0.312 ms
Execution Time: 1.115 ms
};

plan 'tests' => 1;

my $explain = Pg::Explain->new( 'source' => $plan );
$explain->parse_source;

cmp_deeply(
    $explain->settings,
    {
        'work_mem' => '1GB',
    },
    "Proper settings in $source_file"
);

exit;
