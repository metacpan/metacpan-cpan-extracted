#!perl

use strict;
use Test::More;
use Pg::Explain;

plan 'tests' => 2;

my $explain = Pg::Explain->new(
    'source' => q{
Nested Loop  (cost=13933.75..15207.83 rows=309660 width=107) (actual time=1120.279..3571.712 rows=619321 loops=1)
  Buffers: shared hit=3100692 read=16753 dirtied=7127 written=8846, temp written=1814
  I/O Timings: read=32.874 write=32.324
  ->  HashAggregate  (cost=13933.33..13935.33 rows=200 width=40) (actual time=1120.259..1286.190 rows=619321 loops=1)
        Group Key: expired.id
        Buffers: shared hit=626204 read=10497 dirtied=7127 written=5157, temp written=1814
        I/O Timings: read=18.153 write=17.407
        ->  CTE Scan on expired  (cost=0.00..12385.18 rows=619259 width=40) (actual time=0.048..940.090 rows=619321 loops=1)
              Buffers: shared hit=626204 read=10497 dirtied=7127 written=5157, temp written=1814
              I/O Timings: read=18.153 write=17.407
  ->  Index Scan using reservation_pk on reservation  (cost=0.42..6.35 rows=1 width=75) (actual time=0.003..0.003 rows=1 loops=619321)
        Index Cond: (id = expired.id)
        Buffers: shared hit=2474488 read=6256 written=3689
        I/O Timings: read=14.721 write=14.917
}
);

ok( $explain->total_buffers, 'Top level buffers exist' );
is( $explain->top_node->total_exclusive_buffers, undef, 'Correct 0 exclusive buffers for top node' );

exit;
