#!perl

use Test::More;
use Test::Deep;
use Test::Exception;
use autodie;
plan 'tests' => 6;

use Pg::Explain;

my $plan_source = q{
                                                   QUERY PLAN
─────────────────────────────────────────────────────────────────────────────────────────────────────────────────
 Nested Loop  (cost=0.00..12.97 rows=4 width=16) (actual time=0.017..0.025 rows=1.00 loops=1)
   Buffers: shared hit=4
   ->  Function Scan on unnest w  (cost=0.00..0.04 rows=4 width=12) (actual time=0.006..0.007 rows=4.00 loops=1)
   ->  Limit  (cost=0.00..3.22 rows=1 width=4) (actual time=0.003..0.004 rows=0.25 loops=4)
         Buffers: shared hit=4
         ->  Seq Scan on data  (cost=0.00..41.88 rows=13 width=4) (actual time=0.003..0.003 rows=0.25 loops=4)
               Filter: (v = w.q)
               Rows Removed by Filter: 6
               Buffers: shared hit=4
 Planning:
   Buffers: shared hit=4
 Planning Time: 0.142 ms
 Execution Time: 0.044 ms
(13 rows)
};

my $explain = Pg::Explain->new( 'source' => $plan_source );
$explain->parse_source;
isa_ok( $explain->top_node, 'Pg::Explain::Node' );

my $seq_scan = $explain->top_node->sub_nodes->[ 1 ]->sub_nodes->[ 0 ];
is( $seq_scan->type,        'Seq Scan', 'Seq scan is really seq scan' );
is( $seq_scan->actual_rows, 0.25,       '0.25 rows returned' );
is( $seq_scan->total_rows,  1,          '1 total row!' );

my $retext = $explain->as_text;
ok( $retext =~ m{Seq Scan on data[^\n]*rows=0\.25 loops=4}, 'Regenerated text shows proper number of rows (0.25)' );

$explain->anonymize;
my $anonymized = $explain->as_text;
ok( $anonymized =~ m{Seq Scan on [^\n]*rows=0\.25 loops=4}, 'Regenerated text shows proper number of rows (0.25)' );

exit;
