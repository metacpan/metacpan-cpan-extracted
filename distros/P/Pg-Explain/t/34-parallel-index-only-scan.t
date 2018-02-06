#!perl

use Test::More;
use Test::Deep;
use Test::Exception;
use Data::Dumper;
use autodie;

use Pg::Explain;

plan 'tests' => 8;

my $explain = Pg::Explain->new(
    'source' => q{
Finalize Aggregate  (cost=23067.12..23067.13 rows=1 width=8) (actual time=85.738..85.738 rows=1 loops=1)
   ->  Gather  (cost=23066.90..23067.11 rows=2 width=8) (actual time=85.720..85.734 rows=3 loops=1)
         Workers Planned: 2
         Workers Launched: 2
         ->  Partial Aggregate  (cost=22066.90..22066.91 rows=1 width=8) (actual time=81.301..81.301 rows=1 loops=3)
               ->  Parallel Index Only Scan using ix_time_performance_dayofweek_btree on time_performance  (cost=0.42..20982.16 rows=433897 width=0) (actual time=0.046..48.860 rows=347145 loops=3)
                     Heap Fetches: 0
 Planning time: 0.113 ms
 Execution time: 87.672 ms
(9 rows)
    }
);
isa_ok( $explain,           'Pg::Explain' );
isa_ok( $explain->top_node, 'Pg::Explain::Node' );

is( $explain->top_node->type                                     , 'Finalize Aggregate' , 'Properly extracted top node type' );
is( $explain->top_node->sub_nodes->[ 0 ]->type                   , 'Gather'             , 'Properly extracted subnode-1' );
is( $explain->top_node->sub_nodes->[ 0 ]->sub_nodes->[ 0 ]->type , 'Partial Aggregate'  , 'Properly extracted subnode-1' );

my $parallel = $explain->top_node->sub_nodes->[ 0 ]->sub_nodes->[ 0 ]->sub_nodes->[ 0 ];

is( $parallel->type,                      'Parallel Index Only Scan',            'Properly parallel node' );
is( $parallel->scan_on->{ 'index_name' }, 'ix_time_performance_dayofweek_btree', 'Properly extracted index used for parallel node' );
is( $parallel->scan_on->{ 'table_name' }, 'time_performance',                    'Properly extracted table used for parallel node' );

exit;
