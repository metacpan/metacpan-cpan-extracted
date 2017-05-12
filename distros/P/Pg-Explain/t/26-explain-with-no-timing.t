#!perl

use Test::More;
use Test::Deep;
use Test::Exception;
use Data::Dumper;
use autodie;

use Pg::Explain;

my @plans = (

q{
Aggregate  (cost=22.21..22.22 rows=1 width=0) (actual rows=1 loops=1)
    ->  Hash Join  (cost=5.75..21.93 rows=111 width=0) (actual rows=113 loops=1)
        Hash Cond: (pg_class.oid = pg_index.indrelid)
        ->  Index Only Scan using pg_class_oid_index on pg_class  (cost=0.15..12.86 rows=314 width=4) (actual rows=319 loops=1)
                Heap Fetches: 130
        ->  Hash  (cost=4.22..4.22 rows=111 width=4) (actual rows=113 loops=1)
                Buckets: 1024  Batches: 1  Memory Usage: 12kB
                ->  Seq Scan on pg_index  (cost=0.00..4.22 rows=111 width=4) (actual rows=113 loops=1)
                    Filter: indisunique
                    Rows Removed by Filter: 11
},

q{
 Result  (cost=1.06..17.20 rows=314 width=201) (actual rows=0 loops=1)
   One-Time Filter: ($0 > 1000)
   InitPlan 1 (returns $0)
     ->  Aggregate  (cost=1.05..1.06 rows=1 width=0) (actual rows=1 loops=1)
           ->  Seq Scan on pg_language  (cost=0.00..1.04 rows=4 width=0) (actual rows=319 loops=1)
   ->  Seq Scan on pg_class  (cost=0.00..16.14 rows=314 width=201) (never executed)
}
);

plan 'tests' => 4 * scalar @plans;

for my $plan_source ( @plans ) {

    my $explain = Pg::Explain->new( 'source' => $plan_source );
    isa_ok( $explain,           'Pg::Explain' );
    isa_ok( $explain->top_node, 'Pg::Explain::Node' );

    my $textual = $explain->as_text();
    ok( $textual =~ m{\(actual rows=319 loops=1\)}, "Got actual data without timing" );
    if ( $plan_source =~ m{never executed} ) {
        ok( $textual =~ m{never executed}, "Plan is never executed" );
    } else {
        ok(1, 'placeholder test, to keep calculation of number of tests simple');
    }

}

exit;
