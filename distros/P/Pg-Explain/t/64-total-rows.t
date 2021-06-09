#!perl

use strict;
use Test::More;
use Test::Exception;
use autodie;
use Pg::Explain;

plan 'tests' => 6;

my $plan = 'CTE Scan on ancestry  (cost=11081612.90..11086588.90 rows=248800 width=164) (actual time=7.166..57168.800 rows=14748383 loops=1)
  CTE ancestry
    ->  Recursive Union  (cost=1000.00..11081612.90 rows=248800 width=164) (actual time=7.165..51769.441 rows=14748383 loops=1)
          ->  Gather  (cost=1000.00..1004532.27 rows=50 width=164) (actual time=7.163..15153.003 rows=687685 loops=1)
                Workers Planned: 7
                Workers Launched: 7
                ->  Parallel Seq Scan on tmp_prd_smmry_prod_rel p2  (cost=0.00..1003527.27 rows=7 width=164) (actual time=3.380..15354.112 rows=85961 loops=8)
                      Filter: ((prnt_prod_id IS NULL) AND (sira = 1))
                      Rows Removed by Filter: 2890598
          ->  Hash Join  (cost=1016.25..1007210.46 rows=24875 width=164) (actual time=1885.917..6592.982 rows=2812140 loops=5)
                Hash Cond: (p.prnt_prod_id = c.prod_id)
                ->  Gather  (cost=1000.00..1006236.53 rows=9950 width=64) (actual time=0.108..1664.378 rows=14304681 loops=5)
                      Workers Planned: 7
                      Workers Launched: 7
                      ->  Parallel Seq Scan on tmp_prd_smmry_prod_rel p  (cost=0.00..1004241.53 rows=1421 width=64) (actual time=0.005..731.773 rows=1788085 loops=40)
                            Filter: ((level <> 1) AND (sira = 1))
                            Rows Removed by Filter: 1188473
                ->  Hash  (cost=10.00..10.00 rows=500 width=132) (actual time=1251.513..1251.513 rows=2949677 loops=5)
                      Buckets: 2048 (originally 1024)  Batches: 1 (originally 1)  Memory Usage: 132kB
                      ->  WorkTable Scan on ancestry c  (cost=0.00..10.00 rows=500 width=132) (actual time=0.012..429.565 rows=2949677 loops=5)';

my $explain = Pg::Explain->new( 'source' => $plan );
lives_ok( sub { $explain->parse_source(); }, 'Parsing lives' );
my @ws_node  = grep { $_->type eq 'WorkTable Scan' } $explain->top_node->all_recursive_subnodes;
my @pss_node = grep { $_->type eq 'Parallel Seq Scan' && $_->actual_loops == 40 } $explain->top_node->all_recursive_subnodes;

is( 1, scalar @ws_node,  "Single WorkTable Scan found" );
is( 1, scalar @pss_node, "Single Parallel Seq Scan found" );

my $ws  = shift @ws_node;
my $pss = shift @pss_node;
is( $ws->actual_rows * $ws->actual_loops, $ws->total_rows,                "Correct number of total rows from WorkTable Scan" );
is( $pss->actual_rows * $pss->workers,    $pss->total_rows,               "Correct number of total rows from Parallel Seq Scan" );
is( $explain->top_node->actual_rows,      $explain->top_node->total_rows, "Correct number of total rows fot top node" );

exit;
