#!perl

use Test::More;
use Test::Deep;
use autodie;

use Pg::Explain;

plan 'tests' => 8;

my $explain = Pg::Explain->new(
    'source' => q{
Limit  (cost=1000.94..61706.58 rows=10 width=69) (actual time=2000.444..2000.447 rows=10 loops=1)
  ->  Gather Merge  (cost=1000.94..595916.19 rows=98 width=69) (actual time=2000.443..2000.445 rows=10 loops=1)
        Workers Planned: 5
        Workers Launched: 5
        ->  Nested Loop Left Join  (cost=0.86..594904.31 rows=20 width=69) (actual time=1972.282..1987.046 rows=10 loops=6)
              Filter: ((base_video.channel_id = 20967) OR (base_video_keywords.keywords_id = 137204))
              Rows Removed by Filter: 776866
              ->  Parallel Index Scan Backward using base_video_pkey on base_video  (cost=0.43..219239.67 rows=456295 width=73) (actual time=0.160..344.535 rows=380246 loops=6)
              ->  Index Scan using base_video_keywords_video_id_52f035d6 on base_video_keywords  (cost=0.43..0.66 rows=11 width=8) (actual time=0.003..0.004 rows=2 loops=2281476)
                    Index Cond: (base_video.id = video_id)
Planning time: 0.621 ms
Execution time: 2003.022 ms
    }
);
isa_ok( $explain,           'Pg::Explain' );
isa_ok( $explain->top_node, 'Pg::Explain::Node' );

is( $explain->top_node->type,                                     'Limit',                 'Properly extracted top node type' );
is( $explain->top_node->sub_nodes->[ 0 ]->type,                   'Gather Merge',          'Properly extracted subnode-1' );
is( $explain->top_node->sub_nodes->[ 0 ]->sub_nodes->[ 0 ]->type, 'Nested Loop Left Join', 'Properly extracted subnode-2' );

my $parallel = $explain->top_node->sub_nodes->[ 0 ]->sub_nodes->[ 0 ]->sub_nodes->[ 0 ];

is( $parallel->type,                      'Parallel Index Scan Backward', 'Properly parallel node' );
is( $parallel->scan_on->{ 'index_name' }, 'base_video_pkey',              'Properly extracted index used for parallel node' );
is( $parallel->scan_on->{ 'table_name' }, 'base_video',                   'Properly extracted table used for parallel node' );

exit;
