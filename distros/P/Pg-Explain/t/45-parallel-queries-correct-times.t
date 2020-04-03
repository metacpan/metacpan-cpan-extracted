#!perl

use Test::More;
use Test::Deep;
use Test::Exception;
use File::Basename;
use autodie;
use FindBin;

plan 'tests' => 16;

use Pg::Explain;

my $plan = join '', <DATA>;

my $explain = Pg::Explain->new( 'source' => $plan );
isa_ok( $explain, 'Pg::Explain' );
$explain->parse_source();

isa_ok( $explain->top_node, 'Pg::Explain::Node' );

# Extract nodes
my $gather_merge            = $explain->top_node->sub_nodes->[ 0 ];
my $partial_group_aggregate = $gather_merge->sub_nodes->[ 0 ];
my $sort                    = $partial_group_aggregate->sub_nodes->[ 0 ];
my $nested_loop             = $sort->sub_nodes->[ 0 ];
my $parallel_seq_scan       = $nested_loop->sub_nodes->[ 0 ];
my $index_scan              = $nested_loop->sub_nodes->[ 1 ];

# Check if node types are OK.
is( $explain->top_node->type,       'Finalize GroupAggregate', 'Correct type - top_node' );
is( $gather_merge->type,            'Gather Merge',            'Correct type - gather_merge' );
is( $partial_group_aggregate->type, 'Partial GroupAggregate',  'Correct type - partial_group_aggregate' );
is( $sort->type,                    'Sort',                    'Correct type - sort' );
is( $nested_loop->type,             'Nested Loop',             'Correct type - nested_loop' );
is( $parallel_seq_scan->type,       'Parallel Seq Scan',       'Correct type - parallel_seq_scan' );
is( $index_scan->type,              'Index Scan',              'Correct type - index_scan' );

# Check if inclusive time is correct
ok( abs( $explain->top_node->total_inclusive_time - 5107.82 ) < 0.001,        'Correct inclusive time - top_node' );
ok( abs( $gather_merge->total_inclusive_time - 5138.677 ) < 0.001,            'Correct inclusive time - gather_merge' );
ok( abs( $partial_group_aggregate->total_inclusive_time - 4976.492 ) < 0.001, 'Correct inclusive time - partial_group_aggregate' );
ok( abs( $sort->total_inclusive_time - 3875.541 ) < 0.001,                    'Correct inclusive time - sort' );
ok( abs( $nested_loop->total_inclusive_time - 3844.976 ) < 0.001,             'Correct inclusive time - nested_loop' );
ok( abs( $parallel_seq_scan->total_inclusive_time - 70.668 ) < 0.001,         'Correct inclusive time - parallel_seq_scan' );
ok( abs( $index_scan->total_inclusive_time - 2946.955 ) < 0.001,              'Correct inclusive time - index_scan' );

exit;

__DATA__
Finalize GroupAggregate  (cost=4017774.18..8151644.98 rows=2 width=10) (actual time=5107.816..5107.820 rows=2 loops=1)
  Group Key: s.legcode
  Buffers: shared hit=503583
  ->  Gather Merge  (cost=4017774.18..8151644.92 rows=8 width=10) (actual time=5011.219..5138.677 rows=10 loops=1)
        Workers Planned: 4
        Workers Launched: 4
        Buffers: shared hit=2442311
        ->  Partial GroupAggregate  (cost=4016774.13..8150643.91 rows=2 width=10) (actual time=4880.459..4976.492 rows=2 loops=5)
              Group Key: s.legcode
              Buffers: shared hit=2442311
              ->  Sort  (cost=4016774.13..4017183.30 rows=163669 width=1497) (actual time=3869.839..3875.541 rows=14610 loops=5)
                    Sort Key: s.legcode
                    Sort Method: quicksort  Memory: 15442kB
                    Worker 0:  Sort Method: quicksort  Memory: 16413kB
                    Worker 1:  Sort Method: quicksort  Memory: 16115kB
                    Worker 2:  Sort Method: quicksort  Memory: 16409kB
                    Worker 3:  Sort Method: quicksort  Memory: 16131kB
                    Buffers: shared hit=2442235
                    ->  Nested Loop  (cost=0.15..3940015.60 rows=163669 width=1497) (actual time=1060.468..3844.976 rows=14610 loops=5)
                          Buffers: shared hit=2442203
                          ->  Parallel Seq Scan on cari03streams s  (cost=0.00..78377.70 rows=153370 width=536) (actual time=0.028..70.668 rows=122790 loops=5)
                                Buffers: shared hit=76844
                          ->  Index Scan using congdistrictsdicesimple50_2014_the_geom_gist on congdistrictsdicesimple50_2014 lp  (cost=0.15..25.17 rows=1 width=961) (actual time=0.023..0.024 rows=0 loops=613949)
                                Index Cond: (the_geom && s.the_geom)
                                Filter: ((district = '02'::text) AND st_intersects(s.the_geom, the_geom))
                                Rows Removed by Filter: 1
                                Buffers: shared hit=2343939
Planning Time: 2.567 ms
JIT:
  Functions: 68
  Options: Inlining true, Optimization true, Expressions true, Deforming true
  Timing: Generation 24.947 ms, Inlining 634.484 ms, Optimization 2063.643 ms, Emission 700.285 ms, Total 3423.359 ms
Execution Time: 5145.232 ms
