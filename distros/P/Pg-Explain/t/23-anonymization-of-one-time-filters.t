#!perl

use Test::More;
use Test::Deep;
use Test::Exception;
use Data::Dumper;
use autodie;

use Pg::Explain;

my @plans = (

q{                                                        QUERY PLAN                                                                                                                                                                                                                
---------------------------------------------------------------------------------------------------------------------------                                                                                                                                                       
 Function Scan on generate_series whatever  (cost=0.00..22.50 rows=1000 width=4) (actual time=0.016..0.017 rows=2 loops=1)                                                                                                                                                        
   SubPlan 1
     ->  Result  (cost=0.00..0.01 rows=1 width=0) (actual time=0.002..0.002 rows=0 loops=2)
           One-Time Filter: (whatever.whatever > whatever.whatever)
 Total runtime: 0.037 ms
(5 rows)},

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

    ok( $textual !~ /generate_series/, 'anonymize() hides name of function in function scan' );
    ok( $textual !~ /whatever/, 'anonymize() hides name of column in one-time filters' );

}

exit;
