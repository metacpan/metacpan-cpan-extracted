#!perl

use Test::More;
use Test::Deep;
use Test::Exception;
use Data::Dumper;
use autodie;

use Pg::Explain;

my @plans = (

q{                                                    QUERY PLAN                                                
----------------------------------------------------------------------------------------------------------
 Update on test  (cost=0.00..40.00 rows=2400 width=10) (actual time=0.041..0.041 rows=0 loops=1)
   ->  Seq Scan on test  (cost=0.00..40.00 rows=2400 width=10) (actual time=0.008..0.010 rows=10 loops=1)
 Total runtime: 0.074 ms
(3 rows)},

q{                                                        QUERY PLAN                                                         
---------------------------------------------------------------------------------------------------------------------------
 Insert on test  (cost=0.00..10.00 rows=1000 width=4) (actual time=0.083..0.083 rows=0 loops=1)
   ->  Function Scan on generate_series i  (cost=0.00..10.00 rows=1000 width=4) (actual time=0.019..0.021 rows=10 loops=1)
 Total runtime: 0.118 ms
(3 rows)},

q{                                               QUERY PLAN                                                
---------------------------------------------------------------------------------------------------------
 Delete on test  (cost=0.00..34.00 rows=2400 width=6) (actual time=0.041..0.041 rows=0 loops=1)
   ->  Seq Scan on test  (cost=0.00..34.00 rows=2400 width=6) (actual time=0.011..0.015 rows=20 loops=1)
 Total runtime: 0.062 ms
(3 rows)},

);

plan 'tests' => 5 * scalar @plans;

for my $plan_source ( @plans ) {

    my $explain = Pg::Explain->new( 'source' => $plan_source );
    isa_ok( $explain,           'Pg::Explain' );
    isa_ok( $explain->top_node, 'Pg::Explain::Node' );
    lives_ok(
        sub {
            $explain->anonymize();
        },
        'Anonymization works',
    );

    my $textual = $explain->as_text();

    ok( $textual !~ /test/, 'anonymize() hides names of modified table(s) (passwd)' );
    ok( $textual !~ /generate_series/, 'anonymize() hides name of function in function scan' );

}

exit;
