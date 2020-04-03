#!perl

use Test::More;
use Test::Deep;
use Test::Exception;
use autodie;

use Pg::Explain;

plan 'tests' => 10;

my $explain = Pg::Explain->new(
    'source' => q{
 Finalize GroupAggregate  (cost=158141.99..158145.24 rows=100 width=12) (actual time=770.753..770.766 rows=10 loops=1)
   Group Key: c_100
   ->  Sort  (cost=158141.99..158142.74 rows=300 width=12) (actual time=770.747..770.751 rows=40 loops=1)
         Sort Key: c_100
         Sort Method: quicksort  Memory: 27kB
         ->  Gather  (cost=158098.64..158129.64 rows=300 width=12) (actual time=769.859..770.724 rows=40 loops=1)
               Workers Planned: 3
               Workers Launched: 3
               ->  Partial HashAggregate  (cost=157098.64..157099.64 rows=100 width=12) (actual time=765.184..765.188 rows=10 loops=4)
                     Group Key: c_100
                     ->  Parallel Bitmap Heap Scan on p1  (cost=37639.11..153855.63 rows=648602 width=4) (actual time=242.999..600.416 rows=500000 loops=4)
                           Recheck Cond: (c_100 < 10)
                           Heap Blocks: exact=31663
                           ->  Bitmap Index Scan on idx_p1  (cost=0.00..37136.44 rows=2010667 width=0) (actual time=213.409..213.409 rows=2000000 loops=1)
                                 Index Cond: (c_100 < 10)
    }
);
isa_ok( $explain,           'Pg::Explain' );
isa_ok( $explain->top_node, 'Pg::Explain::Node' );

is( $explain->top_node->type,                                                       'Finalize GroupAggregate', 'Properly extracted top node type' );
is( $explain->top_node->sub_nodes->[ 0 ]->type,                                     'Sort',                    'Properly extracted subnode-1' );
is( $explain->top_node->sub_nodes->[ 0 ]->sub_nodes->[ 0 ]->type,                   'Gather',                  'Properly extracted subnode-2' );
is( $explain->top_node->sub_nodes->[ 0 ]->sub_nodes->[ 0 ]->sub_nodes->[ 0 ]->type, 'Partial HashAggregate',   'Properly extracted subnode-3' );
my $pha = $explain->top_node->sub_nodes->[ 0 ]->sub_nodes->[ 0 ]->sub_nodes->[ 0 ];
is( $pha->total_inclusive_time, 765.188,           "Inclusive time is calculated properly for parallel nodes" );
is( $pha->total_exclusive_time, 765.188 - 600.416, "Exclusive time is calculated properly for parallel nodes" );

lives_ok(
    sub {
        $explain->anonymize();
    },
    'Anonymization works',
);

ok( $explain->as_text !~ /p1/, 'anonymize() hides table names' );

exit;
