#!perl

use strict;
use Test::More;
use Test::Exception;
use autodie;
use Pg::Explain;

plan 'tests' => 13;

my $plan = 'Nested Loop Left Join  (cost=11028.05..12403.74 rows=1 width=60) (actual time=36.724..78735.090 rows=22416 loops=1)
  Join Filter: ((multileg_date.segmentname = a.segmentname) AND (multileg_date.flightnumber = a.flightnumber))
  Rows Removed by Join Filter: 7054873
  Filter: (CASE WHEN ((multileg_date.date_interval IS NOT NULL) AND (flights_legs_2.segmentname = multileg_date.segmentname_parent)) THEN (a.departuredate + multileg_date.date_interval) ELSE a.departuredate END = flights_legs_2.departuredate)
  Rows Removed by Filter: 7412665
  CTE flights_legs_2
    ->  Nested Loop  (cost=1000.43..11016.27 rows=1 width=154) (actual time=29.302..233.664 rows=10687 loops=1)
          ->  Gather  (cost=1000.00..11007.81 rows=1 width=98) (actual time=29.264..98.162 rows=10687 loops=1)
                Workers Planned: 2
                Workers Launched: 2
                ->  Parallel Seq Scan on flt_fcst flt_fcst_a_1  (cost=0.00..10007.71 rows=1 width=98) (actual time=19.024..53.097 rows=3562 loops=3)
                      Filter: (legs >= 2)
                      Rows Removed by Filter: 150856
          ->  Index Scan using flights_segmentname_departuredate_flightnumber_cabin_uindex on flights  (cost=0.43..8.45 rows=1 width=56) (actual time=0.011..0.011 rows=1 loops=10687)
                Index Cond: ((segmentname = flt_fcst_a_1.leg_od) AND (departuredate = flt_fcst_a_1.flt_dep_date_locl) AND (flightnumber = flt_fcst_a_1.oprg_flt_no) AND (cabin = flt_fcst_a_1.cmpt_code))
  ->  Nested Loop  (cost=11.78..1357.00 rows=1 width=61) (actual time=29.736..65482.722 rows=7435081 loops=1)
        Join Filter: ((""left""(flights_legs_2.segmentname, 3) = ""left""(a.segmentname, 3)) OR (""right""(flights_legs_2.segmentname, 3) = ""right""(a.segmentname, 3)) OR (flights_legs_2.legs = 3))
        Rows Removed by Join Filter: 642015
        ->  Nested Loop  (cost=11.36..1281.15 rows=97 width=127) (actual time=29.709..12840.519 rows=8077096 loops=1)
              ->  CTE Scan on flights_legs_2  (cost=0.00..0.02 rows=1 width=108) (actual time=29.308..261.747 rows=10687 loops=1)
              ->  Bitmap Heap Scan on flt_fcst flt_fcst_a  (cost=11.36..1280.16 rows=97 width=19) (actual time=0.214..1.100 rows=756 loops=10687)
                    Recheck Cond: (oprg_flt_no = flights_legs_2.flightnumber)
                    Filter: ((legs = 1) AND (flights_legs_2.cabin = cmpt_code))
                    Rows Removed by Filter: 2279
                    Heap Blocks: exact=4094493
                    ->  Bitmap Index Scan on flt_fcst_oprg_flt_no  (cost=0.00..11.33 rows=388 width=0) (actual time=0.175..0.175 rows=3035 loops=10687)
                          Index Cond: (oprg_flt_no = flights_legs_2.flightnumber)
        ->  Index Scan using flights_segmentname_departuredate_flightnumber_cabin_uindex on flights a  (cost=0.43..0.75 rows=1 width=23) (actual time=0.006..0.006 rows=1 loops=8077096)
              Index Cond: ((segmentname = flt_fcst_a.leg_od) AND (departuredate = flt_fcst_a.flt_dep_date_locl) AND (flightnumber = flt_fcst_a.oprg_flt_no) AND (cabin = flt_fcst_a.cmpt_code))
  ->  Seq Scan on multileg_date  (cost=0.00..16.30 rows=630 width=100) (actual time=0.000..0.000 rows=1 loops=7435081)
Planning time: 2.435 ms
Execution time: 78739.395 ms
';

my $explain = Pg::Explain->new( 'source' => $plan );
lives_ok( sub { $explain->parse_source(); }, 'Parsing lives' );

# Node with 1 worker, 1 loop, and some rows removed
my $node = $explain->top_node;
is( $node->type,               'Nested Loop Left Join', '(node1) correct type' );
is( $node->workers,            1,                       '(node1) workers == 1' );
is( $node->actual_loops,       1,                       '(node1) loops == 1' );
is( $node->total_rows_removed, 14467538,                '(node1) correct number of removed rows' );

# Node with 2+ workers, and some rows removed
my @nodes = grep { $_->type eq 'Parallel Seq Scan' } $explain->top_node->all_recursive_subnodes;
is( scalar @nodes, 1, '(node2) found one node' );
$node = shift @nodes;
is( $node->workers,            3,      '(node2) workers == 3' );
is( $node->actual_loops,       3,      '(node2) loops == 3' );
is( $node->total_rows_removed, 452568, '(node2) correct number of removed rows' );

# Node with 1 worker, 2+ loops, and some rows removed
my @nodes = grep { $_->type eq 'Bitmap Heap Scan' } $explain->top_node->all_recursive_subnodes;
is( scalar @nodes, 1, '(node3) found one node' );
$node = shift @nodes;
is( $node->workers,            1,        '(node3) workers == 3' );
is( $node->actual_loops,       10687,    '(node3) loops == 3' );
is( $node->total_rows_removed, 24355673, '(node3) correct number of removed rows' );

exit;
