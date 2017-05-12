#!perl

use Test::More;
use Test::Deep;
use Data::Dumper;
use autodie;

use Pg::Explain;

plan 'tests' => 1;

my $plan = q{
                                                   QUERY PLAN
----------------------------------------------------------------------------------------------------------------
 Seq Scan on folders a  (cost=0.00..1666.42 rows=5346 width=16) (actual time=0.225..4004.334 rows=5356 loops=1)
   SubPlan 1
     ->  Result  (cost=0.00..0.26 rows=1 width=0) (actual time=0.744..0.745 rows=1 loops=5356)
 Total runtime: 4005.536 ms
(4 rows)
};

my $explain = Pg::Explain->new( 'source' => $plan );

my $top = $explain->top_node;

ok(
    abs( $top->total_exclusive_time - 14.114 ) < 0.001,
    'Total exclusive time (14.114) does exclude subnodes'
);

