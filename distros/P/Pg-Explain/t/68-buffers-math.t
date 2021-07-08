#!perl

use strict;
use Test::More;
use Test::Deep;
use autodie;
use Pg::Explain;

plan 'tests' => 4;

my $explain = Pg::Explain->new(
    'source' => q{
Limit  (cost=44.74..44.74 rows=1 width=9) (actual time=0.321..0.322 rows=1 loops=1)
  Buffers: shared hit=13 read=21
  I/O Timings: read=0.081
  ->  Sort  (cost=44.74..44.76 rows=6 width=9) (actual time=0.321..0.321 rows=1 loops=1)
        Sort Key: (count(*)) DESC
        Sort Method: top-N heapsort  Memory: 25kB
        Buffers: shared hit=13 read=21
        I/O Timings: read=0.081
        ->  HashAggregate  (cost=44.65..44.71 rows=6 width=9) (actual time=0.297..0.298 rows=6 loops=1)
              Group Key: relkind
              Batches: 1  Memory Usage: 24kB
              Buffers: shared hit=10 read=21
              I/O Timings: read=0.081
              ->  Seq Scan on pg_class  (cost=0.00..40.10 rows=910 width=1) (actual time=0.002..0.144 rows=911 loops=1)
                    Buffers: shared hit=10 read=21
                    I/O Timings: read=0.081
Planning:
  Buffers: shared hit=73 read=20
  I/O Timings: read=0.095
Planning Time: 0.309 ms
Execution Time: 0.431 ms
}
);

ok( $explain->total_buffers, 'Top level buffers exist' );
cmp_deeply(
    $explain->total_buffers->get_struct,
    {
        'shared'  => { 'hit'  => 86, 'read' => 41, },
        'timings' => { 'read' => 0.176 }
    }
);
ok( !$explain->top_node->total_exclusive_buffers, 'Top level node does not have exclusive buffers' );
cmp_deeply(
    $explain->top_node->sub_nodes->[ 0 ]->total_exclusive_buffers->get_struct,
    { 'shared' => { 'hit' => 3, } },
    'Correct exclusive buffers for sort',
);

exit;
